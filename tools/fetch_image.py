#!/usr/bin/env python3
"""Downloads a generated image (e.g. from OpenArt) and stores it as a game photo
or a character reference: re-encoded as a phone-like JPEG, metadata stripped.

  python3 tools/fetch_image.py <url> art/refs/daniel.jpg
  python3 tools/fetch_image.py <url> art/photos/IMG_2101.jpg
"""
import io, sys, urllib.request
from PIL import Image

url, out = sys.argv[1], sys.argv[2]
max_side = int(sys.argv[3]) if len(sys.argv) > 3 else 2048
with urllib.request.urlopen(url, timeout=120) as r:
    im = Image.open(io.BytesIO(r.read())).convert("RGB")
im.thumbnail((max_side, max_side), Image.LANCZOS)
im.save(out, "JPEG", quality=88, optimize=True)
print(out, im.size)
