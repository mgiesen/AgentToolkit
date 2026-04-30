#!/usr/bin/env python3
"""
Generiert die Skills-Tabelle in README.md aus den Frontmatter-Daten aller SKILL.md-Dateien.
Ersetzt den Inhalt zwischen '## Skills' und der nächsten '## '-Überschrift (oder EOF).
"""

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("Fehler: PyYAML nicht installiert. `pip install pyyaml`", file=sys.stderr)
    sys.exit(1)

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
        parts.append(f"`{requires['platform']}`")
    if "app" in requires:
        for app in requires["app"]:
            parts.append(f"`{app}`")
    if "bin" in requires:
        for b in requires["bin"]:
            parts.append(f"`{b}`")
    if "pip" in requires:
        for p in requires["pip"]:
            parts.append(f"`{p}`")
    return ", ".join(parts) if parts else "—"


def format_keys(requires) -> str:
    if not requires or "key" not in requires:
        return "—"
    return ", ".join(f"`{k['name']}`" for k in requires["key"])


def format_features(features) -> str:
    if not features:
        return ""
    return "<br>".join(f"• {f}" for f in features)


def build_table(skills: list[dict]) -> str:
    header = "| Skill | Version | Features | Abhängigkeiten | API-Key |"
    separator = "|---|---|---|---|---|"
    rows = []
    for s in skills:
        name = f"**{s.get('name', '')}**"
        version = s.get("version", "—")
        features = format_features(s.get("features"))
        requires = format_requires(s.get("requires"))
        keys = format_keys(s.get("requires"))
        rows.append(f"| {name} | {version} | {features} | {requires} | {keys} |")
    return "\n".join([header, separator] + rows)


def update_readme(table: str):
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

    # Finde das Ende der Tabelle (nächste ##-Überschrift oder EOF)
    table_start = None
    table_end = None
    for i in range(section_start + 1, len(lines)):
        line = lines[i]
        if table_start is None and line.startswith("|"):
            table_start = i
        if table_start is not None and not line.startswith("|") and line.strip() != "":
            table_end = i
            break

    if table_start is None:
        # Keine Tabelle vorhanden — nach der Überschrift einfügen
        table_start = section_start + 2
        table_end = table_start

    if table_end is None:
        table_end = len(lines)

    new_lines = lines[:table_start] + [table + "\n"] + lines[table_end:]
    README.write_text("".join(new_lines), encoding="utf-8")
    print(f"README.md aktualisiert ({len(table.splitlines())} Zeilen Tabelle).")


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
            skills.append(fm)

    skills.sort(key=lambda s: s.get("name", ""))
    table = build_table(skills)
    update_readme(table)


if __name__ == "__main__":
    main()
