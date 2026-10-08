#!/usr/bin/env python3
"""Turns a too-bright generated photo into a 3 a.m. phone shot: crushes the
exposure, cools and desaturates it, and adds the luminance noise a phone sensor
makes in the dark.   python3 tools/night_grade.py in.jpg [out.jpg] [exposure]"""
import sys
import numpy as np
from PIL import Image

src = sys.argv[1]
out = sys.argv[2] if len(sys.argv) > 2 else src
exposure = float(sys.argv[3]) if len(sys.argv) > 3 else 0.28
im = np.asarray(Image.open(src).convert("RGB"), np.float32) / 255.0
lum = im @ np.array([0.299, 0.587, 0.114], np.float32)
im = im * 0.35 + lum[..., None] * 0.65                 # desaturate
im = im * np.array([0.9, 0.95, 1.08], np.float32)     # cool cast
im = np.clip(im, 0, 1) ** 1.6 * exposure * 2.2        # crush shadows, darken
rng = np.random.default_rng(3)
im += rng.normal(0, 0.022, im.shape[:2])[..., None] + rng.normal(0, 0.008, im.shape)
Image.fromarray((np.clip(im, 0, 1) * 255).astype(np.uint8)).save(out, quality=88)
print(out)
