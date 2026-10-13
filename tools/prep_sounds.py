#!/usr/bin/env python3
"""Turn recorded sounds into the game's assets/sound/*.ogg.

    python3 tools/prep_sounds.py <recipes.json> <synth_wav_dir> <sources_dir> [names...]

Every recording replaces a synthesised sound of the same name
(scripts/core/sound_synth.gd), so the mix the game was tuned with stays:
each file is brought to the loudness of the synthesised one it replaces
(<synth_wav_dir>/<name>.wav, written by tools/dump_synth.gd).

recipes.json: {"<name>": {"src": [paths under sources_dir], "loop": false, "seconds": 0,
                           "seq": [delays], "gain": 0, "rate": 1.0}}
  src      one file, or several -> <name>_0.ogg, <name>_1.ogg ... (the game
           picks one at random each time, with a little pitch change)
  loop     ambience: cut to `seconds` and crossfaded so the end flows into
           the start
  seq      one-shot built from the first src repeated at these delays
           (three knocks)
  gain     dB on top of the match (when the recording should sit louder or
           quieter than the old sound)
Needs ffmpeg (libvorbis).
"""
import array
import json
import math
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "assets", "sound")
RATE = 44100


def ff(*args: str) -> str:
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-y", *args],
                       capture_output=True, text=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr[-800:])
    return r.stderr


def loudness(path: str) -> float:
    """How loud a sound is, in a way that works for a 0.1 s footstep as
    well as a rain loop: the loudest 50 ms (RMS, dBFS)."""
    r = subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-i", path, "-ac", "1", "-ar", "22050",
                        "-f", "s16le", "-"], capture_output=True)
    pcm = array.array("h", r.stdout[: len(r.stdout) // 2 * 2])
    win = 1102
    best = 0.0
    for i in range(0, max(1, len(pcm) - win + 1), win // 2):
        chunk = pcm[i:i + win]
        if not chunk:
            break
        ms = sum(v * v for v in chunk) / len(chunk)
        best = max(best, ms)
    return 10.0 * math.log10(best / (32768.0 ** 2)) if best > 0 else -90.0


def duration(path: str) -> float:
    err = ff("-i", path, "-f", "null", "-")
    m = re.findall(r"time=(\d+):(\d+):([\d.]+)", err)
    h, mi, s = m[-1]
    return int(h) * 3600 + int(mi) * 60 + float(s)


def mono(src: str, dst: str, trim: bool) -> None:
    af = "aformat=channel_layouts=mono,aresample=%d" % RATE
    if trim:
        # cut the silence before and after a one-shot
        af += (",silenceremove=start_periods=1:start_threshold=-55dB"
               ",areverse,silenceremove=start_periods=1:start_threshold=-55dB,areverse"
               # 5 ms fades at both ends: no click
               ",afade=t=in:d=0.005,areverse,afade=t=in:d=0.005,areverse")
    ff("-i", src, "-af", af, "-c:a", "pcm_s16le", dst)


def make_loop(src: str, dst: str, seconds: float, tmp: str) -> None:
    """Take `seconds` (+ 2 s) and fold the extra 2 s over the start, so the
    end runs into the beginning without a click or a gap."""
    x = 2.0
    whole = os.path.join(tmp, "whole.wav")
    mono(src, whole, False)
    total = duration(whole)
    seconds = min(seconds or total - x, total - x)
    body = os.path.join(tmp, "body.wav")
    tail = os.path.join(tmp, "tail.wav")
    ff("-i", whole, "-af", "atrim=%f:%f,asetpts=N/SR/TB" % (x, x + seconds), body)
    ff("-i", whole, "-af", "atrim=%f:%f,asetpts=N/SR/TB,afade=t=out:d=%f" % (x + seconds, x + seconds + x, x), tail)
    # body with its first 2 s faded in, plus the tail (fading out) mixed over them
    ff("-i", body, "-i", tail, "-filter_complex",
       "[0]afade=t=in:d=%f[a];[a][1]amix=inputs=2:duration=first:normalize=0" % x, dst)


def build(name: str, rec: dict, synth_dir: str, root: str) -> list:
    srcs = rec["src"] if isinstance(rec["src"], list) else [rec["src"]]
    srcs = [os.path.join(root, s) for s in srcs]
    ref = os.path.join(synth_dir, name + ".wav")
    target = loudness(ref) if os.path.exists(ref) else -20.0
    target += float(rec.get("gain", 0.0))
    outs = []
    for k, src in enumerate(srcs):
        with tempfile.TemporaryDirectory() as tmp:
            clean = os.path.join(tmp, "clean.wav")
            if rec.get("loop"):
                make_loop(src, clean, float(rec.get("seconds", 0)), tmp)
            elif rec.get("seq"):
                one = os.path.join(tmp, "one.wav")
                mono(src, one, True)
                delays = rec["seq"]
                ins, parts = [], []
                for i, d in enumerate(delays):
                    ins += ["-i", one]
                    parts.append("[%d]adelay=%d[d%d]" % (i, int(d * 1000), i))
                mix = ";".join(parts) + ";" + "".join("[d%d]" % i for i in range(len(delays))) + \
                    "amix=inputs=%d:normalize=0" % len(delays)
                ff(*ins, "-filter_complex", mix, clean)
            else:
                mono(src, clean, True)
            if rec.get("rate", 1.0) != 1.0:
                r = float(rec["rate"])
                shifted = os.path.join(tmp, "rate.wav")
                ff("-i", clean, "-af", "asetrate=%d,aresample=%d" % (int(RATE * r), RATE), shifted)
                clean = shifted
            have = loudness(clean)
            gain = max(-40.0, min(30.0, target - have))
            # bring it to the old sound's loudness, never past -1 dBFS peaks
            name_k = name if len(srcs) == 1 else "%s_%d" % (name, k)
            dst = os.path.join(OUT, name_k + ".ogg")
            ff("-i", clean, "-af", "volume=%.2fdB,alimiter=limit=0.89:level=false" % gain,
               "-c:a", "libvorbis", "-q:a", "5", dst)
            outs.append((name_k, round(target, 1), round(have, 1), round(gain, 1), round(duration(dst), 2)))
    return outs


def main() -> None:
    recipes = json.load(open(sys.argv[1], encoding="utf-8"))
    synth_dir = sys.argv[2]
    root = sys.argv[3]
    os.makedirs(OUT, exist_ok=True)
    only = sys.argv[4:]
    for name, rec in recipes.items():
        if name.startswith("_") or (only and name not in only):
            continue
        # a re-run replaces every old variant of the sound
        for f in os.listdir(OUT):
            if re.fullmatch(r"%s(_\d+)?\.ogg" % re.escape(name), f):
                os.remove(os.path.join(OUT, f))
        for o in build(name, rec, synth_dir, root):
            print("%-16s target %6.1f  had %6.1f  gain %+5.1f  %5.2fs" % o)


if __name__ == "__main__":
    main()
