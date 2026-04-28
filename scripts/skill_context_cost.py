#!/usr/bin/env python3
"""Schätzt die Token-Kosten der Skill-Injektionen beim Agent-Start.

Iteriert alle assets/skills/*/SKILL.md, extrahiert den YAML-Frontmatter
(name + description) und berechnet die ungefähre Token-Anzahl,
die beim initialen Laden in den System-Prompt fließt.

Nutzt tiktoken (cl100k_base) falls installiert, sonst eine
Heuristik (~1 Token pro 4 Zeichen).
"""

from __future__ import annotations

import sys
from pathlib import Path

SKILLS_DIR = Path(__file__).resolve().parent.parent / "assets" / "skills"

# ---------------------------------------------------------------------------
# Token-Schätzung
# ---------------------------------------------------------------------------

try:
    import tiktoken

    _enc = tiktoken.get_encoding("cl100k_base")

    def count_tokens(text: str) -> int:
        return len(_enc.encode(text))

    ESTIMATOR = "tiktoken (cl100k_base)"
except ImportError:
    def count_tokens(text: str) -> int:
        return max(1, len(text) // 4)

    ESTIMATOR = "Heuristik (~4 Zeichen/Token)"

# ---------------------------------------------------------------------------
# YAML-Frontmatter parsen
# ---------------------------------------------------------------------------

def parse_frontmatter(path: Path) -> dict[str, str]:
    """Extrahiert name und description aus dem YAML-Frontmatter."""
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}
    end = text.find("---", 3)
    if end == -1:
        return {}
    block = text[3:end].strip()
    result: dict[str, str] = {}
    for line in block.splitlines():
        if ":" in line:
            key, _, value = line.partition(":")
            result[key.strip()] = value.strip()
    return result

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    skill_dirs = sorted(SKILLS_DIR.iterdir()) if SKILLS_DIR.is_dir() else []
    if not skill_dirs:
        print(f"Keine Skills gefunden unter {SKILLS_DIR}", file=sys.stderr)
        sys.exit(1)

    rows: list[tuple[str, str, int, int]] = []
    listing_lines: list[str] = []

    for d in skill_dirs:
        skill_md = d / "SKILL.md"
        if not skill_md.is_file():
            continue
        fm = parse_frontmatter(skill_md)
        name = fm.get("name", d.name)
        desc = fm.get("description", "")

        # Das ist das Format, das als Listing im System-Prompt landet
        entry = f"- {name}: {desc}"
        listing_lines.append(entry)

        full_text = skill_md.read_text(encoding="utf-8")

        tokens_entry = count_tokens(entry)
        tokens_full = count_tokens(full_text)
        rows.append((name, desc[:60], tokens_entry, tokens_full))

    if not rows:
        print("Keine SKILL.md-Dateien gefunden.", file=sys.stderr)
        sys.exit(1)

    # Gesamtes Listing (so wie der Agent es sieht)
    full_listing = "\n".join(listing_lines)
    total_listing_tokens = count_tokens(full_listing)
    total_full_tokens = sum(r[3] for r in rows)

    # Ausgabe
    col_name = max(len(r[0]) for r in rows)
    col_desc = 60
    header_name = "Skill".ljust(col_name)
    header_listing = "Listing"
    header_full = "Volltext"

    print(f"Token-Schätzer: {ESTIMATOR}")
    print(f"Skills-Verzeichnis: {SKILLS_DIR}\n")
    print(f"{'─' * (col_name + col_desc + 30)}")
    print(f"  {header_name}  {'Beschreibung'.ljust(col_desc)}  {header_listing:>8}  {header_full:>8}")
    print(f"{'─' * (col_name + col_desc + 30)}")

    for name, desc, tok_listing, tok_full in rows:
        trunc = (desc[:57] + "...") if len(desc) >= 60 else desc
        print(f"  {name.ljust(col_name)}  {trunc.ljust(col_desc)}  {tok_listing:>8}  {tok_full:>8}")

    print(f"{'─' * (col_name + col_desc + 30)}")
    print(f"  {'GESAMT'.ljust(col_name)}  {''.ljust(col_desc)}  {total_listing_tokens:>8}  {total_full_tokens:>8}")
    print()
    print(f"  Listing = Name + Beschreibung pro Skill (System-Prompt beim Start)")
    print(f"  Volltext = gesamte SKILL.md (wird bei Skill-Aufruf nachgeladen)")


if __name__ == "__main__":
    main()
