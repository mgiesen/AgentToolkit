#!/usr/bin/env python3
"""Oeffnet einen nativen macOS Finder-Dialog und gibt den gewaehlten Ordner-Pfad aus."""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

DEFAULT_PROMPT = "Bitte Ordner waehlen"


def pick_folder(prompt: str) -> Path | None:
    safe_prompt = prompt.replace('"', '\\"')
    script = f'POSIX path of (choose folder with prompt "{safe_prompt}")'
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        print(
            "Fehler: osascript nicht verfuegbar. Dieser Skill unterstuetzt nur macOS.",
            file=sys.stderr,
        )
        return None

    if result.returncode != 0:
        return None

    path_str = result.stdout.strip()
    if not path_str:
        return None

    return Path(path_str.rstrip("/"))


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Oeffnet einen Finder-Dialog und gibt den gewaehlten Ordner aus.",
    )
    parser.add_argument(
        "--prompt",
        default=DEFAULT_PROMPT,
        help=f"Text im Dialog-Titel (Default: {DEFAULT_PROMPT!r})",
    )
    args = parser.parse_args()

    print(f">> {args.prompt} — bitte im geoeffneten Finder-Dialog auswaehlen.", file=sys.stderr)

    folder = pick_folder(args.prompt)
    if folder is None:
        print("Fehler: Kein Ordner gewaehlt (Abbruch durch Benutzer).", file=sys.stderr)
        return 1

    if not folder.is_dir():
        print(f"Fehler: Pfad ist kein gueltiger Ordner: {folder}", file=sys.stderr)
        return 2

    print(f"PATH={folder}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
