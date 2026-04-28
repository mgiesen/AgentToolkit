#!/usr/bin/env python3
"""Oeffnet einen nativen Ordner-Dialog und gibt den gewaehlten Pfad aus. Unterstuetzt macOS, Windows und Linux."""

from __future__ import annotations

import argparse
import platform
import subprocess
import sys
from pathlib import Path

DEFAULT_PROMPT = "Bitte Ordner waehlen"


def pick_folder_macos(prompt: str) -> Path | None:
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
        print("Fehler: osascript nicht verfuegbar.", file=sys.stderr)
        return None

    if result.returncode != 0:
        return None

    path_str = result.stdout.strip()
    return Path(path_str.rstrip("/")) if path_str else None


def pick_folder_windows(prompt: str) -> Path | None:
    safe_prompt = prompt.replace("'", "''")
    script = (
        "Add-Type -AssemblyName System.Windows.Forms; "
        "$d = New-Object System.Windows.Forms.FolderBrowserDialog; "
        f"$d.Description = '{safe_prompt}'; "
        "if ($d.ShowDialog() -eq 'OK') { $d.SelectedPath } else { exit 1 }"
    )
    try:
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", script],
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        print("Fehler: PowerShell nicht verfuegbar.", file=sys.stderr)
        return None

    if result.returncode != 0:
        return None

    path_str = result.stdout.strip()
    return Path(path_str) if path_str else None


def pick_folder_linux(prompt: str) -> Path | None:
    try:
        result = subprocess.run(
            ["zenity", "--file-selection", "--directory", "--title", prompt],
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        print("Fehler: zenity nicht verfuegbar (apt install zenity).", file=sys.stderr)
        return None

    if result.returncode != 0:
        return None

    path_str = result.stdout.strip()
    return Path(path_str) if path_str else None


def pick_folder(prompt: str) -> Path | None:
    system = platform.system()
    if system == "Darwin":
        return pick_folder_macos(prompt)
    elif system == "Windows":
        return pick_folder_windows(prompt)
    elif system == "Linux":
        return pick_folder_linux(prompt)
    else:
        print(f"Fehler: Nicht unterstuetztes OS: {system}", file=sys.stderr)
        return None


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Oeffnet einen nativen Ordner-Dialog und gibt den gewaehlten Ordner aus.",
    )
    parser.add_argument(
        "--prompt",
        default=DEFAULT_PROMPT,
        help=f"Text im Dialog-Titel (Default: {DEFAULT_PROMPT!r})",
    )
    args = parser.parse_args()

    print(f">> {args.prompt} — bitte im geoeffneten Dialog auswaehlen.", file=sys.stderr)

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
