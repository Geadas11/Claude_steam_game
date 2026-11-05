#!/usr/bin/env python3
"""Compose the phone's ringtones from one recorded kalimba note.

    python3 tools/make_ringtone.py <kalimba_C4.flac> <out_dir>

The note (Kalimba C1, dvdfu, Freesound 536551, CC0) is re-pitched to play an
original melody, so the ringtone is a real instrument, like the marimba
tones of real phones. Writes ring.wav and ring_wrong.wav, each exactly one
loop long (the game loops them while the phone rings):

  ring        the phone's own ringtone
  ring_wrong  the same tune, slower, a few notes bent flat and every note
              doubled slightly out of tune (unknown numbers, Ines, ECO)
"""
import subprocess
import sys

import numpy as np

RATE = 44100
C4 = 261.63
LOOP = 3.2           # seconds per ring cycle (tune + silence)
STEP = 0.16          # one eighth note

# (start in eighths, semitones above C4, velocity)
TUNE = [
    (0, 16, 1.0), (1, 19, 0.8), (2, 23, 0.85), (3, 28, 0.9),
    (4, 26, 0.85), (5, 23, 0.75), (6, 19, 0.8), (7, 23, 0.85),
    (8, 21, 0.9), (9, 19, 0.75), (10, 16, 0.9),
]
BASS = [(0, 4, 0.45), (8, 9, 0.4)]   # warmth under the tune, an octave below


def load(path: str) -> np.ndarray:
    r = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-ac", "1", "-ar", str(RATE), "-f", "f32le", "-"],
                       capture_output=True, check=True)
    x = np.frombuffer(r.stdout, dtype=np.float32).astype(np.float64)
    # start at the attack
    on = int(np.argmax(np.abs(x) > 0.02 * np.abs(x).max()))
    return x[on:] / np.abs(x).max()


def pitched(x: np.ndarray, ratio: float) -> np.ndarray:
    n = int(len(x) / ratio)
    t = np.arange(n) * ratio
    return np.interp(t, np.arange(len(x)), x)


def render(src: np.ndarray, notes, tempo: float, bend: dict, detune: float) -> np.ndarray:
    out = np.zeros(int(LOOP * tempo * RATE) + RATE * 4)
    for k, (beat, semi, vel) in enumerate(notes):
        semi = semi + bend.get(k, 0.0)
        voices = [0.0] if detune == 0 else [-detune, detune]
        for cents in voices:
            ratio = 2 ** ((semi + cents / 100.0) / 12.0)
            s = pitched(src, ratio) * vel / len(voices)
            # let notes ring, but not forever: a gentle damp after 1.4 s
            env = np.ones(len(s))
            d = int(1.4 * RATE)
            if len(s) > d:
                env[d:] = np.exp(-np.arange(len(s) - d) / (0.25 * RATE))
            i = int(beat * STEP * tempo * RATE)
            out[i:i + len(s)] += s * env
    return out


def room(x: np.ndarray) -> np.ndarray:
    """A small, soft room: a few early echoes and a short diffuse tail."""
    rng = np.random.default_rng(7)
    n = int(0.6 * RATE)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (0.12 * RATE)) * 0.05
    ir[0] = 1.0
    for ms, g in [(11, 0.22), (17, 0.16), (29, 0.1)]:
        ir[int(ms * RATE / 1000)] += g
    return np.convolve(x, ir)[:len(x)]


def fold(x: np.ndarray, length: float) -> np.ndarray:
    """Wrap whatever rings past the loop end over its start (seamless loop)."""
    n = int(length * RATE)
    y = x[:n].copy()
    tail = x[n:]
    y[:min(n, len(tail))] += tail[:n]
    return y


def write(path: str, x: np.ndarray) -> None:
    x = x / np.abs(x).max() * 0.89
    pcm = (x * 32767).astype(np.int16).tobytes()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-f", "s16le", "-ar", str(RATE), "-ac", "1", "-i", "-", path],
                   input=pcm, check=True)


def main() -> None:
    src = load(sys.argv[1])
    out = sys.argv[2]
    tune = render(src, TUNE, 1.0, {}, 0.0) + render(src, BASS, 1.0, {}, 0.0) * 0.6
    write(out + "/ring.wav", fold(room(tune), LOOP))
    # the wrong one: 15% slower, the 4th and 9th notes bent flat, two voices
    # 22 cents apart (a beating, sour shimmer)
    bend = {3: -1.0, 8: -0.6, 10: -0.3}
    wrong = render(src, TUNE, 1.15, bend, 11.0) + render(src, BASS, 1.15, {1: -1.0}, 11.0) * 0.6
    write(out + "/ring_wrong.wav", fold(room(wrong), LOOP * 1.15))


if __name__ == "__main__":
    main()
