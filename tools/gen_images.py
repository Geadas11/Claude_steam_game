#!/usr/bin/env python3
"""Generates the game's realistic photos with an image model: Higgsfield
(Seedream 4) or Google's Gemini API.

Keys are never stored in the repository:
  Higgsfield: HF_KEY="id:secret" or HF_KEY_FILE=<file>     (used when set)
  Gemini:     GEMINI_API_KEY or GEMINI_KEY_FILE=<file>
Force one with IMAGE_PROVIDER=higgsfield|gemini.

  python3 tools/gen_images.py ref daniel            # character reference portrait
  python3 tools/gen_images.py photo IMG_2101        # one game photo
  python3 tools/gen_images.py photo all             # every photo in tools/image_prompts.json

Character references live in art/refs/<id>.jpg and are sent along with every
photo in which that character appears, so faces stay the same across photos.
Output: art/photos/<ID>.jpg (2K, phone-camera look).
"""
import base64, json, os, sys, time, urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROMPTS = os.path.join(ROOT, "tools", "image_prompts.json")
REF_DIR = os.path.join(ROOT, "art", "refs")
OUT_DIR = os.path.join(ROOT, "art", "photos")
MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3-pro-image")
URL = "https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent" % MODEL

STYLE = ("Candid photograph taken with a mid-range Android phone camera. Natural, imperfect, "
         "slightly noisy in low light, realistic skin texture, no retouching, no studio lighting, "
         "no text overlays, no watermark, not illustrated, not CGI. Southern Portugal (Algarve), 2025-2026.")


def key():
    k = os.environ.get("GEMINI_API_KEY", "")
    if not k and os.environ.get("GEMINI_KEY_FILE"):
        k = open(os.environ["GEMINI_KEY_FILE"]).read().strip()
    if not k:
        sys.exit("Set GEMINI_API_KEY or GEMINI_KEY_FILE")
    return k


def provider():
    p = os.environ.get("IMAGE_PROVIDER", "")
    if p:
        return p
    return "higgsfield" if (os.environ.get("HF_KEY") or os.environ.get("HF_KEY_FILE")) else "gemini"


def generate(prompt, refs=(), aspect="4:3", size="2K", tries=3):
    if provider() == "higgsfield":
        return generate_hf(prompt, refs, aspect, size, tries)
    return generate_gemini(prompt, refs, aspect, size, tries)


# ------------------------------------------------------------------ Higgsfield
# Same protocol as the official SDK (pip higgsfield-client): POST the model's
# arguments to api.higgsfield.ai/<model>, poll the returned status_url, then
# download images[0].url. Reference images are uploaded first through a
# pre-signed URL. Model ids can be overridden if Higgsfield renames them.
HF_BASE = "https://api.higgsfield.ai"
# Model docs: https://dash.higgsfield.ai/models/<model id>/llms.txt
# Soul 2: realistic people, 1080p. Qwen Image 3 edit: 1-3 ordered reference
# images (character portraits, or the photo being edited), 2k.
HF_T2I = os.environ.get("HF_T2I_MODEL", "higgsfield-ai/soul/v2/standard")
HF_EDIT = os.environ.get("HF_EDIT_MODEL", "alibaba/qwen-image-3/edit")


def hf_key():
    k = os.environ.get("HF_KEY", "")
    if not k and os.environ.get("HF_KEY_FILE"):
        k = open(os.environ["HF_KEY_FILE"]).read().strip()
    if not k:
        sys.exit("Set HF_KEY or HF_KEY_FILE")
    return k


def hf_call(method, url, body=None):
    if not url.startswith("http"):
        url = HF_BASE + "/" + url.lstrip("/")
    req = urllib.request.Request(url, method=method, data=json.dumps(body).encode() if body is not None else None,
                                 headers={"Authorization": "Key " + hf_key(), "Content-Type": "application/json",
                                          "User-Agent": "aea-gen-images/1"})
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            return json.loads(resp.read() or b"{}")
    except urllib.error.HTTPError as e:
        raise RuntimeError("HTTP %d %s: %s" % (e.code, url.split("?")[0], e.read().decode()[:400]))


_hf_uploaded = {}


def hf_upload(path):
    if path in _hf_uploaded:
        return _hf_uploaded[path]
    r = hf_call("POST", "/files/generate-upload-url", {"content_type": "image/jpeg"})
    data = open(path, "rb").read()
    headers = r.get("upload_headers") or {"Content-Type": "image/jpeg"}
    req = urllib.request.Request(r["upload_url"], data=data, method="PUT", headers=headers)
    urllib.request.urlopen(req, timeout=120).read()
    _hf_uploaded[path] = r["public_url"]
    return r["public_url"]


def generate_hf(prompt, refs=(), aspect="4:3", size="2K", tries=3):
    if refs:
        model = HF_EDIT
        args = {"prompt": prompt, "image_urls": [hf_upload(r) for r in list(refs)[:3]],
                "resolution": "2k", "aspect_ratio": aspect,
                "negative_prompt": "illustration, cartoon, CGI, 3D render, text, watermark, plastic skin"}
    else:
        model = HF_T2I
        args = {"prompt": prompt, "resolution": "1080p", "aspect_ratio": aspect,
                "batch_size": 1, "enhance_prompt": False}
    for attempt in range(tries):
        try:
            sub = hf_call("POST", model, args)
            status_url = sub["status_url"]
            for _ in range(240):            # up to ~8 minutes
                time.sleep(2)
                st = hf_call("GET", status_url)
                if st.get("status") in ("completed", "failed", "nsfw", "canceled"):
                    break
            if st.get("status") != "completed":
                raise RuntimeError("request ended as %s: %s" % (st.get("status"), json.dumps(st)[:300]))
            url = st["images"][0]["url"]
            with urllib.request.urlopen(url, timeout=120) as resp:
                return resp.read()
        except (RuntimeError, urllib.error.URLError, KeyError) as e:
            if attempt + 1 < tries and "HTTP 4" not in str(e):
                time.sleep(8 * (attempt + 1))
                continue
            raise SystemExit("Higgsfield: %s" % e)


# ------------------------------------------------------------------ Gemini
def generate_gemini(prompt, refs=(), aspect="4:3", size="2K", tries=3):
    parts = []
    for r in refs:
        with open(r, "rb") as f:
            parts.append({"inline_data": {"mime_type": "image/jpeg", "data": base64.b64encode(f.read()).decode()}})
    parts.append({"text": prompt})
    body = {
        "contents": [{"parts": parts}],
        "generationConfig": {"responseModalities": ["IMAGE"], "imageConfig": {"aspectRatio": aspect, "imageSize": size}},
    }
    for attempt in range(tries):
        req = urllib.request.Request(URL, data=json.dumps(body).encode(), method="POST",
                                     headers={"Content-Type": "application/json", "x-goog-api-key": key()})
        try:
            with urllib.request.urlopen(req, timeout=240) as resp:
                data = json.loads(resp.read())
        except urllib.error.HTTPError as e:
            msg = e.read().decode()[:500]
            if e.code in (429, 500, 503) and attempt + 1 < tries:
                time.sleep(10 * (attempt + 1))
                continue
            raise SystemExit("HTTP %d: %s" % (e.code, msg))
        for cand in data.get("candidates", []):
            for p in cand.get("content", {}).get("parts", []):
                inline = p.get("inline_data") or p.get("inlineData")
                if inline:
                    return base64.b64decode(inline["data"])
        if attempt + 1 < tries:
            time.sleep(5)
            continue
        raise SystemExit("No image in response: %s" % json.dumps(data)[:600])


def to_jpeg(raw, path, max_side=2048, quality=88):
    """Re-encode as a phone-like JPEG (strips metadata, bounds the size)."""
    try:
        from PIL import Image
        import io
        im = Image.open(io.BytesIO(raw)).convert("RGB")
        im.thumbnail((max_side, max_side))
        im.save(path, "JPEG", quality=quality, optimize=True)
    except ImportError:
        open(path, "wb").write(raw)


def main():
    prompts = json.load(open(PROMPTS))
    kind, target = sys.argv[1], sys.argv[2]
    if kind == "ref":
        os.makedirs(REF_DIR, exist_ok=True)
        ids = list(prompts["characters"]) if target == "all" else [target]
        for cid in ids:
            c = prompts["characters"][cid]
            out = os.path.join(REF_DIR, cid + ".jpg")
            if os.path.exists(out) and target == "all":
                continue
            p = ("Reference portrait for a character: " + c["look"] + " Head and shoulders, facing the camera, "
                 "neutral expression, plain indoor background, soft window light. " + STYLE)
            to_jpeg(generate(p, aspect="3:4"), out, 1536)
            print("ref", cid, out)
    else:
        os.makedirs(OUT_DIR, exist_ok=True)
        ids = list(prompts["photos"]) if target == "all" else target.split(",")
        for pid in ids:
            ph = prompts["photos"][pid]
            out = os.path.join(OUT_DIR, pid + ".jpg")
            refs = [os.path.join(REF_DIR, c + ".jpg") for c in ph.get("people", [])]
            missing = [r for r in refs if not os.path.exists(r)]
            if missing:
                print("skip", pid, "missing refs", missing)
                continue
            style = ph.get("style", STYLE)
            if not (os.path.exists(out) and target == "all"):
                who = ""
                inputs = list(refs)
                if ph.get("based_on"):
                    base = os.path.join(OUT_DIR, ph["based_on"] + ".jpg")
                    if not os.path.exists(base):
                        print("skip", pid, "needs", ph["based_on"], "first")
                        continue
                    inputs = [base] + refs
                    who = "The first image is the photo to edit. "
                if ph.get("people"):
                    names = [prompts["characters"][c]["name"] for c in ph["people"]]
                    who += ("The people in this photo are exactly the people in the character reference images, in this order: "
                            + ", ".join(names) + ". Keep their faces, age and hair identical to the references. ")
                to_jpeg(generate(who + ph["prompt"] + " " + style, inputs, ph.get("aspect", "4:3")), out)
                print("photo", pid, out)
            # variants: edits of the finished photo (the image changes while the player looks)
            for vname, edit in ph.get("variants", {}).items():
                vout = os.path.join(OUT_DIR, "%s__%s.jpg" % (pid, vname))
                if os.path.exists(vout) and target == "all":
                    continue
                prompt = ("Edit this photo. Keep everything identical — framing, light, colours, noise, people — "
                          "and change only this: " + edit)
                to_jpeg(generate(prompt, [out], ph.get("aspect", "4:3")), vout)
                print("variant", pid, vname, vout)

if __name__ == "__main__":
    main()
