#!/usr/bin/env bash
set -euo pipefail

# Wrapper: leitet an das angegebene Python-Script weiter, nutzt Repo-Venv

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VENV_PYTHON="$REPO_ROOT/.venv/bin/python3"

if [[ ! -f "$VENV_PYTHON" ]]; then
    echo "Fehler: Venv nicht gefunden. Ausfuehren:" >&2
    echo "  cd $REPO_ROOT && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt" >&2
    exit 1
fi

SCRIPT="$1"
shift
exec "$VENV_PYTHON" "$SCRIPT_DIR/$SCRIPT" "$@"
