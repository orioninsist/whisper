#!/usr/bin/env python3
"""Two-speaker dialogue parser."""

import re
import sys
from pathlib import Path

SPEAKER = re.compile(r"^([A-Za-z][A-Za-z0-9 _'-]{0,39}):\s*(.+)$")
SKIP = {"situation", "dialogue", "title", "context", "note"}
VOICES = ("female", "male")


def parse(text):
    speakers = {}
    lines = []

    for number, raw in enumerate(text.splitlines(), 1):
        match = SPEAKER.fullmatch(raw.strip())
        if not match:
            continue

        name, speech = match.groups()
        name = name.strip()
        key = name.casefold()

        if key in SKIP or key.startswith("dialogue "):
            continue

        if key not in speakers:
            if len(speakers) >= 2:
                raise ValueError(
                    f"Satir {number}: Ikiden fazla konusmaci: {name}"
                )
            speakers[key] = (name, VOICES[len(speakers)])

        lines.append((speakers[key][0], speakers[key][1], speech))

    if not lines:
        raise ValueError("Gecerli diyalog satiri bulunamadi.")

    return lines


def main():
    if len(sys.argv) != 2:
        raise ValueError("Kullanim: dialogue-parser.candidate.py dosya.txt")

    source = Path(sys.argv[1])
    if not source.is_file():
        raise ValueError("Metin dosyasi bulunamadi.")

    for name, voice, speech in parse(source.read_text(encoding="utf-8")):
        print(f"{name} [{voice}]: {speech}")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, UnicodeError) as error:
        print(f"HATA: {error}", file=sys.stderr)
        sys.exit(1)
