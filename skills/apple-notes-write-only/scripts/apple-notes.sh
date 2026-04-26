#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Apple Notes – Write-Only Skill
# Erstellt neue Notizen. Kein Lesen, kein Loeschen, kein Append.
# Body akzeptiert HTML fuer Formatierung.
# ──────────────────────────────────────────────────────────────

[[ $# -lt 2 ]] && { echo "Usage: apple-notes.sh <title> <body>"; exit 1; }

TITLE="$1"
BODY="$2"

# Escape backslashes and double quotes for AppleScript string
TITLE_ESC="${TITLE//\\/\\\\}"
TITLE_ESC="${TITLE_ESC//\"/\\\"}"
BODY_ESC="${BODY//\\/\\\\}"
BODY_ESC="${BODY_ESC//\"/\\\"}"

osascript <<EOF
tell application "Notes"
    make new note with properties {body:"<h1>${TITLE_ESC}</h1><br>${BODY_ESC}"}
end tell
EOF

echo "Notiz '$TITLE' erstellt."
