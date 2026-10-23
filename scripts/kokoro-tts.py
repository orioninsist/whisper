#!/usr/bin/env python3
"""Offline Kokoro text-to-speech CLI."""

import argparse
import sys
import wave

import numpy as np
from kokoro import KModel, KPipeline


def main():
    parser = argparse.ArgumentParser(
        description="Yerel Kokoro metinden ses üretimi"
    )
    parser.add_argument("--text", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument(
        "--voice",
        choices=["female", "male"],
        default="female",
    )
    parser.add_argument("--speed", type=float, default=1.0)
    args = parser.parse_args()

    if not args.text.strip():
        parser.error("Metin bos olamaz.")

    if not 0.5 <= args.speed <= 2.0:
        parser.error("Hiz 0.5 ile 2.0 arasinda olmali.")

    voices = {
        "female": "/models/voices/af_heart.pt",
        "male": "/models/voices/am_michael.pt",
    }

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

    chunks = []

    for _, _, audio in pipeline(
        args.text,
        voice=voices[args.voice],
        speed=args.speed,
    ):
        chunks.append(np.asarray(audio, dtype=np.float32))

    if not chunks:
        raise RuntimeError("Kokoro ses uretemedi.")

    samples = np.concatenate(chunks)
    samples = np.clip(samples, -1.0, 1.0)
    pcm = (samples * 32767).astype("<i2")

    with open(args.output, "xb") as output_file:
        with wave.open(output_file, "wb") as wav:
            wav.setnchannels(1)
            wav.setsampwidth(2)
            wav.setframerate(24000)
            wav.writeframes(pcm.tobytes())

    print(f"Ses olusturuldu: {args.output}")
    print(f"Sure: {len(samples) / 24000:.2f} saniye")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"HATA: {error}", file=sys.stderr)
        sys.exit(1)
