#!/usr/bin/env python3
"""
Generiert die Agenten-Tabelle in docs/agents.md aus den Frontmatter-Daten
aller .md-Dateien in assets/agents/.

Ersetzt den Tabellen-Block unter '# Agenten'.
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
AGENTS_DIR = REPO_ROOT / "assets" / "agents"
AGENTS_DOC = REPO_ROOT / "docs" / "agents.md"


def parse_frontmatter(agent_md: Path) -> dict:
    content = agent_md.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return {}
    return yaml.safe_load(match.group(1)) or {}


def format_tools(tools) -> str:
    if not tools:
        return "—"
    if isinstance(tools, str):
        return f"`{tools}`"
    return ", ".join(f"`{t}`" for t in tools)


def build_table(agents: list[dict]) -> tuple[str, int]:
    header = "| Agent | Beschreibung | Tools | Startup-Tokens |"
    separator = "| --- | --- | --- | --- |"
    rows = []
    total_tokens = 0
    for a in agents:
        slug = a.get("_slug", "")
        name = f"**{slug}**"
        description = a.get("description", "")
        tools = format_tools(a.get("tools"))
        tokens = a.get("_tokens", 0)
        total_tokens += tokens
        rows.append(f"| {name} | {description} | {tools} | {tokens:,} |")
    table = "\n".join([header, separator] + rows)
    return table, total_tokens


def update_doc(table: str, total_tokens: int):
    if not AGENTS_DOC.exists():
        print(f"Fehler: {AGENTS_DOC} existiert nicht.", file=sys.stderr)
        sys.exit(1)

    content = AGENTS_DOC.read_text(encoding="utf-8")
    lines = content.splitlines(keepends=True)

    section_start = None
    for i, line in enumerate(lines):
        if line.strip() == "# Agenten":
            section_start = i
            break
    if section_start is None:
        print("Fehler: '# Agenten' nicht in docs/agents.md gefunden.", file=sys.stderr)
        sys.exit(1)

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

    token_note = f"_Gesamt-Kontextgröße aller Agenten beim Start: **{total_tokens:,} Tokens**_\n"
    agents_block = [table + "\n", "\n", token_note, "\n"]

    new_lines = lines[:block_start] + agents_block + lines[block_end:]
    AGENTS_DOC.write_text("".join(new_lines), encoding="utf-8")
    print(f"docs/agents.md aktualisiert — {total_tokens:,} Tokens gesamt ({ESTIMATOR}).")


def main():
    if not AGENTS_DIR.exists():
        print(f"Fehler: {AGENTS_DIR} existiert nicht.", file=sys.stderr)
        sys.exit(1)

    agents = []
    for md in sorted(AGENTS_DIR.glob("*.md")):
        fm = parse_frontmatter(md)
        if not fm:
            continue
        fm["_slug"] = md.stem
        fm["_tokens"] = count_tokens(f"- {fm.get('name', '')}: {fm.get('description', '')}")
        agents.append(fm)

    agents.sort(key=lambda a: a.get("_slug", ""))
    table, total_tokens = build_table(agents)
    update_doc(table, total_tokens)


if __name__ == "__main__":
    main()
