#!/bin/bash
set -euo pipefail

# Erstellt Skill-Symlinks fuer alle konfigurierten AI-Tools.
# Ausfuehren nach dem Klonen oder nach Hinzufuegen neuer Skills.

TOOLS=("agents/Claude Code/.claude" "agents/Codex/.codex" "agents/OpenCode/.opencode")

for tool in "${TOOLS[@]}"; do
    mkdir -p "$tool/skills"
    for skill in assets/skills/*/; do
        name=$(basename "$skill")
        target="../../../../assets/skills/$name"
        link="$tool/skills/$name"
        if [ ! -L "$link" ]; then
            ln -s "$target" "$link"
            echo "  $link → $target"
        fi
    done
done


echo "Done."
