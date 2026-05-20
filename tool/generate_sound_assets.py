#!/usr/bin/env python3
"""Generate bundled CC0-safe Chaos sound effects.

The original project had zero-byte .mp3 placeholders. This script creates short,
playable synthetic sound effects with no third-party/copyrighted samples.
"""

from __future__ import annotations

import math
import random
import struct
import subprocess
import tempfile
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "sounds"
SR = 44_100


def clamp(x: float) -> float:
    return max(-1.0, min(1.0, x))


def env(t: float, dur: float, attack: float = 0.02, release: float = 0.08) -> float:
    if t < attack:
        return t / attack
    if t > dur - release:
        return max(0.0, (dur - t) / release)
    return 1.0


def sine(freq: float, t: float) -> float:
    return math.sin(2 * math.pi * freq * t)


def saw(freq: float, t: float) -> float:
    return 2.0 * ((freq * t) % 1.0) - 1.0


def write_mp3(name: str, dur: float, synth, gain: float = 0.85) -> None:
    target = OUT / name
    target.parent.mkdir(parents=True, exist_ok=True)
    samples = []
    random.seed(1337 + hash(name) % 10_000)
    n = int(SR * dur)
    for i in range(n):
        t = i / SR
        samples.append(clamp(synth(t, dur)) * gain)

    peak = max(0.001, max(abs(s) for s in samples))
    norm = min(0.98 / peak, 1.8)

    with tempfile.TemporaryDirectory() as td:
        wav_path = Path(td) / "sound.wav"
        with wave.open(str(wav_path), "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(SR)
            data = bytearray()
            for s in samples:
                data += struct.pack("<h", int(clamp(s * norm) * 32767))
            wf.writeframes(data)
        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-loglevel",
                "error",
                "-i",
                str(wav_path),
                "-codec:a",
                "libmp3lame",
                "-b:a",
                "128k",
                str(target),
            ],
            check=True,
        )
        print(f"wrote {target.relative_to(ROOT)}")


def bruh(t: float, dur: float) -> float:
    # Low comic vocal-ish fall using formant-style harmonics.
    f = 165 - 55 * (t / dur)
    wobble = 1 + 0.025 * sine(5, t)
    body = 0.65 * sine(f * wobble, t) + 0.25 * sine(f * 2.02, t) + 0.12 * sine(f * 3.1, t)
    return body * env(t, dur, 0.025, 0.16)


def oh_no(t: float, dur: float) -> float:
    # Two-note descending alert.
    split = dur * 0.46
    base = 520 if t < split else 390
    slide = -90 * ((t % split) / split)
    return (sine(base + slide, t) + 0.28 * sine((base + slide) * 2, t)) * env(t, dur, 0.01, 0.18)


def airhorn(t: float, dur: float) -> float:
    gate = 0.75 + 0.25 * (sine(11, t) > -0.2)
    f = 440 + 18 * sine(7, t)
    tone = 0.55 * saw(f, t) + 0.35 * saw(f * 1.5, t) + 0.12 * random.uniform(-1, 1)
    return tone * gate * env(t, dur, 0.008, 0.08)


def chicken(t: float, dur: float) -> float:
    bursts = 0.0
    for start in [0.05, 0.20, 0.34, 0.54, 0.68]:
        local = t - start
        if 0 <= local < 0.075:
            f = 1450 - 850 * local / 0.075
            bursts += (sine(f, t) + 0.35 * random.uniform(-1, 1)) * env(local, 0.075, 0.004, 0.035)
    return bursts


def goat(t: float, dur: float) -> float:
    f = 310 + 55 * sine(9.5, t) + 22 * sine(18, t)
    trem = 0.55 + 0.45 * abs(sine(13, t))
    return (0.75 * sine(f, t) + 0.28 * sine(f * 2.0, t) + 0.12 * random.uniform(-1, 1)) * trem * env(t, dur, 0.03, 0.18)


def cat(t: float, dur: float) -> float:
    f = 720 + 360 * math.sin(math.pi * min(t / dur, 1)) - 180 * (t / dur)
    return (sine(f, t) + 0.25 * sine(f * 2.1, t)) * env(t, dur, 0.018, 0.18)


def fart(t: float, dur: float) -> float:
    f = 65 + 20 * sine(18, t) + 12 * random.uniform(-1, 1)
    buzz = 0.58 * saw(max(25, f), t) + 0.30 * random.uniform(-1, 1)
    wobble = 0.62 + 0.38 * sine(23, t)
    return buzz * wobble * env(t, dur, 0.01, 0.22)


def snore(t: float, dur: float) -> float:
    cycle = (t % 1.1) / 1.1
    breath = math.sin(math.pi * cycle)
    low = sine(95 + 12 * sine(4, t), t) * 0.45
    noise = random.uniform(-1, 1) * 0.28
    return (low + noise) * breath * env(t, dur, 0.05, 0.35)


def burp(t: float, dur: float) -> float:
    f = 150 - 80 * (t / dur) + 12 * sine(14, t)
    bubble = 0.7 + 0.3 * (sine(18, t) > 0)
    return (0.62 * sine(max(45, f), t) + 0.25 * saw(max(45, f * 0.55), t)) * bubble * env(t, dur, 0.015, 0.2)


def main() -> None:
    write_mp3("memes/bruh.mp3", 0.95, bruh)
    write_mp3("memes/oh_no.mp3", 1.05, oh_no)
    write_mp3("memes/airhorn.mp3", 1.2, airhorn)
    write_mp3("animals/chicken.mp3", 0.85, chicken)
    write_mp3("animals/goat.mp3", 1.15, goat)
    write_mp3("animals/cat.mp3", 0.95, cat)
    write_mp3("human/fart.mp3", 0.9, fart)
    write_mp3("human/snore.mp3", 2.2, snore)
    write_mp3("human/burp.mp3", 0.9, burp)


if __name__ == "__main__":
    main()
