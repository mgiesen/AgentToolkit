#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VENV_PYTHON="$REPO_ROOT/.venv/bin/python3"

if [[ ! -f "$VENV_PYTHON" ]]; then
    echo "Fehler: Venv nicht gefunden. Erstellen:" >&2
    echo "  cd $REPO_ROOT && python3 -m venv .venv" >&2
    echo "Skill-Abhaengigkeiten siehe install.yaml im Skill-Ordner." >&2
    exit 1
fi

exec "$VENV_PYTHON" "$SCRIPT_DIR/chart.py" "$@"
