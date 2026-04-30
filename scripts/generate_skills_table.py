#!/usr/bin/env python3
"""
Generiert die Skills-Tabelle in README.md aus den Frontmatter-Daten aller SKILL.md-Dateien.
Ersetzt den Inhalt zwischen '## Skills' und der nächsten '## '-Überschrift (oder EOF).

Enthält außerdem eine Token-Schätzung pro Skill (Volltext der SKILL.md),
sowie die Gesamtsumme unter der Tabelle.
"""

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Fehler: PyYAML nicht installiert. `pip install pyyaml`", file=sys.stderr)
    sys.exit(1)

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

REPO_ROOT = Path(__file__).parent.parent
SKILLS_DIR = REPO_ROOT / "assets" / "skills"
README = REPO_ROOT / "README.md"


def parse_frontmatter(skill_md: Path) -> dict:
    content = skill_md.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}
    return yaml.safe_load(match.group(1)) or {}


def format_requires(requires) -> str:
    if not requires:
        return "—"
    parts = []
    if "platform" in requires:
        parts.append(f"`🖥️ {requires['platform']}`")
    if "app" in requires:
        for app in requires["app"]:
            parts.append(f"`{app}`")
    if "bin" in requires:
        for b in requires["bin"]:
            parts.append(f"`⚙️ {b}`")
    if "pip" in requires:
        for p in requires["pip"]:
            parts.append(f"`📦 {p}`")
    return "<br>".join(parts) if parts else "—"


def format_keys(requires) -> str:
    if not requires or "key" not in requires:
        return "—"
    return ", ".join(f"`{k['name']}`" for k in requires["key"])


def format_features(features) -> str:
    if not features:
        return ""
    return "<br>".join(f"• {f}" for f in features)


def build_binaries_table(skills: list[dict]) -> str:
    """Erstellt eine Binaries-Tabelle aus den bin-Abhängigkeiten aller Skills."""
    from collections import defaultdict
    binary_to_skills: dict[str, list[str]] = defaultdict(list)
    for s in skills:
        requires = s.get("requires") or {}
        for b in requires.get("bin", []):
            binary_to_skills[b].append(s.get("name", ""))

    header = "| Binary | Skill(s) |"
    separator = "|---|---|"
    rows = []
    for binary in sorted(binary_to_skills):
        skill_list = binary_to_skills[binary]
        if len(skill_list) == 1:
            skills_cell = skill_list[0]
        else:
            skills_cell = "<br>".join(f"• {s}" for s in skill_list)
        rows.append(f"| `{binary}` | {skills_cell} |")

    return "\n".join([header, separator] + rows)


def build_table(skills: list[dict]) -> tuple[str, int]:
    """Gibt (tabelle, gesamt_tokens) zurück."""
    header = "| Skill | Version | Features | Abhängigkeiten | API-Key | Startup-Tokens |"
    separator = "|---|---|---|---|---|---|"
    rows = []
    total_tokens = 0

    for s in skills:
        name = f"**{s.get('name', '')}**"
        version = s.get("version", "—")
        features = format_features(s.get("features"))
        requires = format_requires(s.get("requires"))
        keys = format_keys(s.get("requires"))
        tokens = s.get("_tokens", 0)
        total_tokens += tokens
        rows.append(f"| {name} | {version} | {features} | {requires} | {keys} | {tokens:,} |")

    table = "\n".join([header, separator] + rows)
    return table, total_tokens


def update_readme(table: str, total_tokens: int, binaries_table: str):
    content = README.read_text(encoding="utf-8")
    lines = content.splitlines(keepends=True)

    # Finde '## Skills'
    section_start = None
    for i, line in enumerate(lines):
        if line.strip() == "## Skills":
            section_start = i
            break

    if section_start is None:
        print("Fehler: '## Skills' nicht in README.md gefunden.", file=sys.stderr)
        sys.exit(1)

    # Finde Start und Ende des zu ersetzenden Blocks (Tabelle + evtl. alter Token-Hinweis)
    block_start = None
    block_end = None
    for i in range(section_start + 1, len(lines)):
        line = lines[i]
        if block_start is None and line.startswith("|"):
            block_start = i
        if block_start is not None and not line.startswith("|") and line.strip() != "":
            block_end = i
            break

    if block_start is None:
        block_start = section_start + 2
        block_end = block_start

    if block_end is None:
        block_end = len(lines)

    # Überspringe direkt folgende Zeilen die zum alten Token-Hinweis gehören
    while block_end < len(lines) and lines[block_end].startswith("_"):
        block_end += 1

    token_note = f"_Gesamt-Kontextgröße aller Skills beim Start: **{total_tokens:,} Tokens**_\n"
    skills_block = [table + "\n", "\n", token_note, "\n"]

    # Finde '## Binaries' und ersetze dessen Tabelle
    binaries_start = None
    for i in range(block_end, len(lines)):
        if lines[i].strip() == "## Binaries":
            binaries_start = i
            break

    if binaries_start is not None:
        # Finde Tabellenblock unter ## Binaries
        bin_block_start = None
        bin_block_end = None
        for i in range(binaries_start + 1, len(lines)):
            line = lines[i]
            if bin_block_start is None and line.startswith("|"):
                bin_block_start = i
            if bin_block_start is not None and not line.startswith("|") and line.strip() != "":
                bin_block_end = i
                break
        if bin_block_start is None:
            bin_block_start = binaries_start + 2
            bin_block_end = bin_block_start
        if bin_block_end is None:
            bin_block_end = len(lines)

        new_lines = (
            lines[:block_start]
            + skills_block
            + lines[block_end:bin_block_start]
            + [binaries_table + "\n"]
            + lines[bin_block_end:]
        )
    else:
        new_lines = lines[:block_start] + skills_block + lines[block_end:]

    README.write_text("".join(new_lines), encoding="utf-8")
    print(f"README.md aktualisiert — {total_tokens:,} Tokens gesamt ({ESTIMATOR}).")


def main():
    skill_dirs = sorted(SKILLS_DIR.iterdir())
    skills = []
    for d in skill_dirs:
        skill_md = d / "SKILL.md"
        if not skill_md.exists():
            continue
        fm = parse_frontmatter(skill_md)
        if fm.get("name") == "how-to-build-a-skill":
            continue
        if fm:
            fm["_tokens"] = count_tokens(f"- {fm.get('name', '')}: {fm.get('description', '')}")
            skills.append(fm)

    skills.sort(key=lambda s: s.get("name", ""))
    table, total_tokens = build_table(skills)
    binaries_table = build_binaries_table(skills)
    update_readme(table, total_tokens, binaries_table)


if __name__ == "__main__":
    main()
