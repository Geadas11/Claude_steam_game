#!/usr/bin/env python3
"""Higgsfield example: one 5 s, 720p, 16:9 clip with Seedance 2.5 (text-to-video).

Credentials are read at runtime from .env.local at the repository root
(HF_KEY="key-id:key-secret"); that file is git-ignored and its value is never
printed. This makes a billable generation request.

  pip install -r tools/higgsfield/requirements.txt
  python3 tools/higgsfield/main.py
"""
import os
import sys

from dotenv import load_dotenv

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
load_dotenv(os.path.join(ROOT, ".env.local"))

import higgsfield_client  # noqa: E402  (reads HF_KEY from the environment)

MODEL = "bytedance/seedance-2.5/text-to-video"
ARGS = {
    "prompt": "A cinematic scene at sunset",
    "duration": 5,
    "resolution": "720p",
    "aspect_ratio": "16:9",
}

BAD = (higgsfield_client.Failed, higgsfield_client.NSFW, higgsfield_client.Cancelled)


def video_url(result: dict) -> str:
    """The output's video URL, whichever of the SDK's result shapes it uses."""
    video = result.get("video")
    if isinstance(video, dict) and video.get("url"):
        return video["url"]
    for key in ("videos", "outputs"):
        items = result.get(key) or []
        if items and isinstance(items[0], dict) and items[0].get("url"):
            return items[0]["url"]
    return ""


def main() -> int:
    if not os.getenv("HF_KEY") and not (os.getenv("HF_API_KEY") and os.getenv("HF_API_SECRET")):
        print("Missing credentials: add HF_KEY=key-id:key-secret to .env.local", file=sys.stderr)
        return 2
    last = {"status": None}

    def on_update(status):
        last["status"] = status
        print("status:", type(status).__name__)

    try:
        result = higgsfield_client.subscribe(
            MODEL,
            arguments=ARGS,
            on_enqueue=lambda rid: print("request:", rid),
            on_queue_update=on_update,
        )
    except Exception as e:  # network, auth, credits, validation
        print("Request failed: %s: %s" % (type(e).__name__, e), file=sys.stderr)
        return 1

    status = str(result.get("status", "")).lower()
    if isinstance(last["status"], BAD) or status in ("failed", "nsfw", "canceled", "cancelled"):
        reason = {"nsfw": "moderated (NSFW)", "canceled": "canceled", "cancelled": "canceled"}.get(status, "failed")
        print("Generation %s: %s" % (reason, result), file=sys.stderr)
        return 1
    url = video_url(result)
    if not url:
        print("Finished without a video URL: %s" % result, file=sys.stderr)
        return 1
    print(url)
    return 0


if __name__ == "__main__":
    sys.exit(main())
