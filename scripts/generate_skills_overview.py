#!/usr/bin/env python3
"""
Generiert die Skills-Tabelle in docs/skills.md aus:
- SKILL.md-Frontmatter (name, version, description, platform, features)
- install.yaml (pip, bin, env, post_install) neben der SKILL.md

Ersetzt den Tabellen-Block unter '# Skills' sowie die Tabelle unter '## Binaries'.
Enthält außerdem eine Token-Schätzung pro Skill (name + description, wie beim Startup geladen).
"""

import re
import sys
from collections import defaultdict
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
SKILLS_DOC = REPO_ROOT / "docs" / "skills.md"


def parse_frontmatter(skill_md: Path) -> dict:
    content = skill_md.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}
    return yaml.safe_load(match.group(1)) or {}


def load_install(skill_dir: Path) -> dict:
    install_path = skill_dir / "install.yaml"
    if not install_path.exists():
        return {}
    try:
        return yaml.safe_load(install_path.read_text(encoding="utf-8")) or {}
    except yaml.YAMLError as e:
        print(f"Warnung: install.yaml fehlerhaft in {skill_dir.name}: {e}", file=sys.stderr)
        return {}


def format_platform(platform) -> str:
    if platform is None or platform == "all":
        return "Alle"
    if isinstance(platform, str):
        return platform
    return ", ".join(str(p) for p in platform)


def format_deps(install: dict) -> str:
    parts = []
    for b in install.get("bin", []) or []:
        name = b.get("name") if isinstance(b, dict) else b
        if name:
            parts.append(f"`⚙️ {name}`")
    for p in install.get("pip", []) or []:
        parts.append(f"`📦 {p}`")
    return "<br>".join(parts) if parts else "—"


def format_keys(install: dict) -> str:
    env = install.get("env", []) or []
    if not env:
        return "—"
    out = []
    for k in env:
        if not isinstance(k, dict):
            continue
        name = k.get("name")
        if not name:
            continue
        required = bool(k.get("required", False))
        suffix = "" if required else " *(optional)*"
        out.append(f"`{name}`{suffix}")
    return "<br>".join(out) if out else "—"


def format_features(features) -> str:
    if not features:
        return ""
    return "<br>".join(f"• {f}" for f in features)


def build_binaries_table(skills: list[dict]) -> str:
    binary_to_skills: dict[str, list[str]] = defaultdict(list)
    for s in skills:
        install = s.get("_install") or {}
        for b in install.get("bin", []) or []:
            name = b.get("name") if isinstance(b, dict) else b
            if name:
                binary_to_skills[name].append(s.get("name", ""))

    header = "| Binary | Skill(s) |"
    separator = "| --- | --- |"
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
    header = "| Skill | Version | Plattform | Features | Abhängigkeiten | API-Key | Startup-Tokens |"
    separator = "| --- | --- | --- | --- | --- | --- | --- |"
    rows = []
    total_tokens = 0

    for s in skills:
        name = f"**{s.get('name', '')}**"
        version = (s.get("source") or {}).get("version", "—")
        platform = format_platform(s.get("platform"))
        features = format_features(s.get("features"))
        install = s.get("_install") or {}
        deps = format_deps(install)
        keys = format_keys(install)
        tokens = s.get("_tokens", 0)
        total_tokens += tokens
        rows.append(
            f"| {name} | {version} | {platform} | {features} | {deps} | {keys} | {tokens:,} |"
        )

    table = "\n".join([header, separator] + rows)
    return table, total_tokens


def update_doc(table: str, total_tokens: int, binaries_table: str):
    if not SKILLS_DOC.exists():
        print(f"Fehler: {SKILLS_DOC} existiert nicht.", file=sys.stderr)
        sys.exit(1)

    content = SKILLS_DOC.read_text(encoding="utf-8")
    lines = content.splitlines(keepends=True)

    # Find '# Skills' (h1)
    section_start = None
    for i, line in enumerate(lines):
        if line.strip() == "# Skills":
            section_start = i
            break
    if section_start is None:
        print("Fehler: '# Skills' nicht in docs/skills.md gefunden.", file=sys.stderr)
        sys.exit(1)

    # Find Skills-Tabellen-Block + folgende Token-Zeile(n)
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

    while block_end < len(lines) and lines[block_end].startswith("_"):
        block_end += 1

    token_note = f"_Gesamt-Kontextgröße aller Skills beim Start: **{total_tokens:,} Tokens**_\n"
    skills_block = [table + "\n", "\n", token_note, "\n"]

    # Find '## Binaries' und ersetze dessen Tabelle
    binaries_start = None
    for i in range(block_end, len(lines)):
        if lines[i].strip() == "## Binaries":
            binaries_start = i
            break

    if binaries_start is not None:
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
            + [binaries_table + "\n", "\n"]
            + lines[bin_block_end:]
        )
    else:
        new_lines = lines[:block_start] + skills_block + lines[block_end:]

    SKILLS_DOC.write_text("".join(new_lines), encoding="utf-8")
    print(f"docs/skills.md aktualisiert — {total_tokens:,} Tokens gesamt ({ESTIMATOR}).")


def main():
    skill_dirs = sorted(SKILLS_DIR.iterdir())
    skills = []
    for d in skill_dirs:
        skill_md = d / "SKILL.md"
        if not skill_md.exists():
            continue
        fm = parse_frontmatter(skill_md)
        if not fm:
            continue
        if fm.get("name") == "how-to-build-a-skill":
            continue
        fm["_tokens"] = count_tokens(f"- {fm.get('name', '')}: {fm.get('description', '')}")
        fm["_install"] = load_install(d)
        skills.append(fm)

    skills.sort(key=lambda s: s.get("name", ""))
    table, total_tokens = build_table(skills)
    binaries_table = build_binaries_table(skills)
    update_doc(table, total_tokens, binaries_table)


if __name__ == "__main__":
    main()
