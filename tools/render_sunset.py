#!/usr/bin/env python3
"""Renders the phone wallpaper (IMG_2207, "Praia da Salgueira", 27/09/2026 19:41)
as a photographic image instead of flat shapes: atmospheric sky, clouds lit from
below, sun bloom, glitter path on the sea, wet sand, phone-camera grain.

  python3 tools/render_sunset.py            -> art/photos/IMG_2207.jpg (+ __watcher variant)

Needs numpy + Pillow. The "watcher" variant adds the small figure standing in the
water (same spot as the photo's hotspot in data/photos.json).
"""
import os
import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "art", "photos")
W, H = 1536, 2048
HORIZON = 0.615
SUN = (0.47, 0.585)          # partly above the horizon
rng = np.random.default_rng(2207)


def noise(scale_x, scale_y, octaves=5, seed=0):
    """Fractal value noise in [0,1], shape (H, W)."""
    r = np.random.default_rng(seed)
    acc = np.zeros((H, W), np.float32)
    amp, tot = 1.0, 0.0
    sx, sy = scale_x, scale_y
    for _ in range(octaves):
        small = r.random((max(2, int(sy)), max(2, int(sx)))).astype(np.float32)
        img = Image.fromarray((small * 255).astype(np.uint8)).resize((W, H), Image.BICUBIC)
        acc += amp * (np.asarray(img, np.float32) / 255.0)
        tot += amp
        amp *= 0.5
        sx *= 2.0
        sy *= 2.0
    return acc / tot


def lerp_colors(t, stops):
    """Piecewise-linear colour ramp; stops = [(pos, (r,g,b)), ...]."""
    t = np.clip(t, 0, 1)
    out = np.zeros(t.shape + (3,), np.float32)
    for (p0, c0), (p1, c1) in zip(stops[:-1], stops[1:]):
        m = (t >= p0) & (t <= p1)
        k = ((t - p0) / max(p1 - p0, 1e-6))[..., None]
        out[m] = (np.array(c0) * (1 - k) + np.array(c1) * k)[m]
    return out


def hexc(h):
    return tuple(int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5))


def render(watcher=False):
    y, x = np.mgrid[0:H, 0:W].astype(np.float32)
    u, v = x / W, y / H
    sx, sy = SUN
    dx = (u - sx) * (W / H)
    dist = np.sqrt(dx ** 2 + (v - sy) ** 2)

    # ---------------------------------------------------------------- sky
    t = v / HORIZON
    sky = lerp_colors(t, [(0.0, hexc("#141833")), (0.35, hexc("#3a3260")), (0.62, hexc("#8a4f6e")),
                          (0.82, hexc("#d9784f")), (0.95, hexc("#f4ad62")), (1.0, hexc("#ffd394"))])
    warm = np.exp(-(dist / 0.35) ** 2)[..., None]
    sky = sky * (1 - 0.35 * warm) + np.array(hexc("#ffb36b")) * 0.35 * warm
    # clouds: long thin horizontal streaks, lit from below near the horizon
    cn = noise(3, 26, 6, seed=11)
    band = np.clip((cn - 0.5) * 5.0, 0, 1) * (v < HORIZON - 0.02) * (v > 0.22)
    band *= np.clip(1.0 - np.abs(v - 0.47) / 0.25, 0, 1)
    lit = lerp_colors(np.clip((v - 0.25) / (HORIZON - 0.25), 0, 1),
                      [(0.0, hexc("#4a3a5e")), (0.6, hexc("#c86a63")), (1.0, hexc("#ffb878"))])
    sky = sky * (1 - 0.85 * band[..., None]) + lit * 0.85 * band[..., None]
    # sun disc + bloom
    disc = np.clip(1.0 - (dist - 0.028) / 0.004, 0, 1)
    bloom = np.exp(-(dist / 0.06) ** 2) * 0.8 + np.exp(-(dist / 0.18) ** 2) * 0.35
    sky = sky + np.array(hexc("#fff1cf")) * disc[..., None] + np.array(hexc("#ffd08a")) * bloom[..., None]

    img = sky

    # ---------------------------------------------------------------- sea
    sea_mask = (v >= HORIZON).astype(np.float32)
    depth = np.clip((v - HORIZON) / (0.82 - HORIZON), 0, 1)
    sea = lerp_colors(depth, [(0.0, hexc("#b9705e")), (0.15, hexc("#6b3f55")), (0.6, hexc("#2c2440")), (1.0, hexc("#1d1a2c"))])
    # waves: horizontal ripples, thinner near the horizon (perspective)
    ripple = noise(6, 140, 5, seed=21)
    ripple2 = noise(18, 300, 4, seed=22)
    rip = (ripple * 0.6 + ripple2 * 0.4)
    # glitter path under the sun, widening toward the viewer
    width = 0.03 + depth * 0.22
    path = np.exp(-((u - sx) / width) ** 2)
    glint = np.clip((rip - 0.55) * 5.0, 0, 1) * path * (1.0 - depth * 0.35)
    sea = sea * (0.85 + 0.3 * rip[..., None]) + np.array(hexc("#ffd394")) * glint[..., None] * 1.3
    sea += np.array(hexc("#ffb56e")) * (np.exp(-((v - HORIZON) / 0.01) ** 2) * 0.35 * np.exp(-((u - sx) / 0.35) ** 2))[..., None]
    img = img * (1 - sea_mask[..., None]) + sea * sea_mask[..., None]

    # ---------------------------------------------------------------- shore
    def smooth(e0, e1, val):
        k = np.clip((val - e0) / (e1 - e0), 0, 1)
        return k * k * (3 - 2 * k)
    # the waterline wanders gently across the frame
    wave_x = np.sin(u * 9.0 + 1.3) * 0.006 + np.sin(u * 23.0) * 0.003
    wave_x += (noise(6, 1, 3, seed=31)[0][None, :] - 0.5) * 0.012
    shore_y = 0.80 + wave_x
    on_shore = smooth(shore_y - 0.004, shore_y + 0.006, v)
    # foam: a thin bright lace just at the waterline, broken by noise
    lace = noise(28, 320, 3, seed=32)
    foam = np.exp(-((v - shore_y) / 0.0035) ** 2) * smooth(0.4, 0.7, lace)
    foam += np.exp(-((v - (shore_y - 0.012)) / 0.002) ** 2) * smooth(0.55, 0.8, lace) * 0.4
    # sand: wet (dark, reflective) to dry, with wind ripples
    ripples = noise(40, 220, 3, seed=42)
    sand_t = np.clip((v - shore_y) / (1.0 - 0.8), 0, 1)
    dry = lerp_colors(sand_t, [(0.0, hexc("#6f5754")), (0.5, hexc("#4d3c3f")), (1.0, hexc("#2b2328"))])
    dry = dry * (0.9 + 0.18 * ripples[..., None] + 0.06 * noise(500, 600, 1, seed=41)[..., None])
    mirror_v = np.clip(2 * shore_y - v, 0.3, HORIZON - 0.001)
    mirror = lerp_colors(mirror_v / HORIZON, [(0.0, hexc("#3a3260")), (0.8, hexc("#c06a55")), (1.0, hexc("#f2a862"))])
    wetness = 1.0 - smooth(shore_y + 0.01, shore_y + 0.09, v)
    wet = dry * 0.6 + mirror * 0.5 * np.exp(-((u - sx) / 0.4) ** 2)[..., None] + mirror * 0.12
    shore = wet * wetness[..., None] + dry * (1 - wetness[..., None])
    img = img * (1 - on_shore[..., None]) + shore * on_shore[..., None]
    img += np.array(hexc("#f6e0cc"))[None, None, :] * (np.clip(foam, 0, 1) * 0.55)[..., None]

    # ---------------------------------------------------------------- the watcher
    if watcher:
        from PIL import ImageDraw
        fx, fy, fh = 0.712, 0.672, 0.048   # waterline at the knees, height (fraction of H)
        S = 8   # supersampling
        cw, ch = int(fh * H * 0.7) * S, int(fh * H * 1.15) * S
        sil = Image.new("L", (cw, ch), 0)
        d = ImageDraw.Draw(sil)
        cx = cw / 2
        unit = ch / 1.15
        top = ch - unit
        def P(px, py):
            return (cx + px * unit, top + py * unit)
        # a person standing still, slightly turned, arms close to the body, long coat
        d.ellipse([P(-0.07, 0.0), P(0.068, 0.165)], fill=255)                                   # head
        d.polygon([P(-0.04, 0.14), P(0.04, 0.14), P(0.05, 0.215), P(-0.05, 0.215)], fill=255)   # neck
        d.polygon([P(-0.2, 0.25), P(-0.12, 0.205), P(0.12, 0.205), P(0.205, 0.255),            # shoulders
                   P(0.215, 0.42), P(0.2, 0.6), P(0.165, 0.64),                                 # right arm down
                   P(0.16, 0.8), P(0.13, 1.0), P(-0.13, 1.0), P(-0.165, 0.8),                   # coat to the water
                   P(-0.17, 0.64), P(-0.205, 0.6), P(-0.22, 0.42)], fill=255)                   # left arm
        sil = sil.resize((cw // S, ch // S), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.1))
        m = np.zeros((H, W), np.float32)
        x0 = int(fx * W - sil.width / 2)
        y0 = int(fy * H - sil.height)
        m[y0:y0 + sil.height, x0:x0 + sil.width] = np.asarray(sil, np.float32) / 255.0
        dark = np.array(hexc("#0e0b13"))
        img = img * (1 - m[..., None] * 0.93) + dark * m[..., None] * 0.93
        # broken reflection on the water below
        rm = np.zeros((H, W), np.float32)
        flipped = np.flipud(np.asarray(sil, np.float32) / 255.0)[: sil.height // 2]
        rm[y0 + sil.height:y0 + sil.height + flipped.shape[0], x0:x0 + sil.width] = flipped
        rm *= np.clip((rip - 0.4) * 2.5, 0, 1)
        img = img * (1 - rm[..., None] * 0.45)

    # ---------------------------------------------------------------- camera
    vig = 1.0 - 0.35 * (((u - 0.5) * 1.1) ** 2 + ((v - 0.5) * 1.0) ** 2) * 2.0
    img *= np.clip(vig, 0.55, 1.0)[..., None]
    img += rng.normal(0, 0.018, img.shape).astype(np.float32)
    # soft highlight roll-off with a warm white point (a phone camera never
    # clips the sun to neutral white)
    white = np.array([1.0, 0.93, 0.76], np.float32)
    knee = 0.72
    over = np.clip(img - knee, 0, None)
    img = np.where(img > knee, knee + (white - knee) * (1 - np.exp(-over / np.maximum(white - knee, 1e-3) * 1.4)), img)
    img = np.clip(img, 0, 1) ** 0.95
    out = Image.fromarray((img * 255).astype(np.uint8))
    out = out.filter(ImageFilter.UnsharpMask(radius=1.2, percent=40, threshold=2))
    return out


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    render(False).save(os.path.join(OUT, "IMG_2207.jpg"), quality=90, optimize=True)
    render(True).save(os.path.join(OUT, "IMG_2207__watcher.jpg"), quality=90, optimize=True)
    print("ok")
