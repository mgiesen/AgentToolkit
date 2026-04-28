#!/usr/bin/env python3
"""Behebt typische Markdown-Formatierungsprobleme fuer sauberes PDF-Rendering.
Besonders relevant fuer KI-generiertes Markdown (fehlende Leerzeilen vor Listen)."""

import re
import sys
from pathlib import Path


def fix_markdown(content: str) -> str:
    lines = content.split("\n")
    fixed: list[str] = []

    for i, line in enumerate(lines):
        is_list = re.match(r"^(\s*)([-*+]|\d+\.)\s", line)

        if is_list and i > 0:
            prev = lines[i - 1]
            indent = len(is_list.group(1))

            if prev.strip() and not re.match(r"^(\s*)([-*+]|\d+\.)\s", prev):
                if indent == 0:
                    fixed.append("")

        fixed.append(line)

    return "\n".join(fixed)


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: fix_markdown.py <input.md> [output.md]", file=sys.stderr)
        return 1

    input_file = Path(sys.argv[1])
    output_file = Path(sys.argv[2]) if len(sys.argv) > 2 else input_file

    if not input_file.exists():
        print(f"Fehler: {input_file} nicht gefunden", file=sys.stderr)
        return 1

    content = input_file.read_text(encoding="utf-8")
    fixed = fix_markdown(content)
    output_file.write_text(fixed, encoding="utf-8")

    if content != fixed:
        print(f"Markdown korrigiert: {output_file}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
