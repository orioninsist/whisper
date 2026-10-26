#!/usr/bin/env python3
"""Offline two-speaker Kokoro dialogue synthesis."""

import argparse
import re
import sys
import wave

import numpy as np
from kokoro import KModel, KPipeline

SPEAKER = re.compile(r"^([A-Za-z][A-Za-z0-9 _'-]{0,39}):\s*(.+)$")
SKIP = {"situation", "dialogue", "title", "context", "note"}

VOICES = (
    "/models/voices/af_heart.pt",
    "/models/voices/am_michael.pt",
)

RATE = 24000
PAUSE = np.zeros(int(RATE * 0.4), dtype=np.float32)


def parse_dialogue(text):
    speakers = {}
    turns = []

    for number, raw in enumerate(text.splitlines(), 1):
        match = SPEAKER.fullmatch(raw.strip())

        if not match:
            continue

        name, speech = match.groups()
        key = name.strip().casefold()

        if key in SKIP or key.startswith("dialogue "):
            continue

        if key not in speakers:
            if len(speakers) >= 2:
                raise ValueError(
                    f"Satir {number}: Ikiden fazla konusmaci."
                )
            speakers[key] = len(speakers)

        turns.append((name, speakers[key], speech))

    if not turns:
        raise ValueError("Gecerli diyalog bulunamadi.")

    return turns


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    with open(args.input, encoding="utf-8") as source:
        turns = parse_dialogue(source.read())

    model = KModel(
        config="/models/config.json",
        model="/models/kokoro-v1_0.pth",
    ).to("cpu").eval()

    pipeline = KPipeline(
        lang_code="a",
        repo_id="hexgrad/Kokoro-82M",
        model=model,
        device="cpu",
    )

    segments = []

    for index, (name, voice, speech) in enumerate(turns, 1):
        print(f"{index}/{len(turns)}: {name}", flush=True)

        chunks = []

        for _, _, audio in pipeline(
            speech,
            voice=VOICES[voice],
            speed=1.0,
        ):
            chunks.append(np.asarray(audio, dtype=np.float32))

        if not chunks:
            raise RuntimeError(
                f"Ses uretilemedi: konusma {index}"
            )

        if segments:
            segments.append(PAUSE)

        segments.extend(chunks)

    samples = np.concatenate(segments)
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype("<i2")

    with open(args.output, "xb") as output:
        with wave.open(output, "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(RATE)
            wav.writeframes(pcm.tobytes())

    print(f"Ses dosyasi: {args.output}")
    print(f"Sure: {len(samples) / RATE:.2f} saniye")


if __name__ == "__main__":
    try:
        main()
    except (Exception, KeyboardInterrupt) as error:
        print(f"HATA: {error}", file=sys.stderr)
        sys.exit(1)
