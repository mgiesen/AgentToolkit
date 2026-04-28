#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────
# Apple Reminders – Write-Only Skill (JXA)
# Erstellt neue Erinnerungen. Kein Lesen, kein Loeschen, kein Auflisten.
# Nutzt JXA statt AppleScript wegen Stabilitaetsproblemen mit due date.
# ──────────────────────────────────────────────────────────────

[[ $# -lt 1 ]] && { echo "Usage: apple-reminders.sh <title> [--body <text>] [--due <ISO-datetime>] [--priority <1-9>] [--list <name>]"; exit 1; }

TITLE="$1"; shift
BODY=""
DUE=""
PRIORITY="0"
LIST=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --body)     BODY="$2"; shift 2 ;;
        --due)      DUE="$2"; shift 2 ;;
        --priority) PRIORITY="$2"; shift 2 ;;
        --list)     LIST="$2"; shift 2 ;;
        *)          echo "Unbekannte Option: $1"; exit 1 ;;
    esac
done

# Escape for JS strings
escape_js() { printf '%s' "$1" | sed "s/'/\\\\'/g" | sed 's/\\/\\\\/g'; }

T=$(escape_js "$TITLE")
B=$(escape_js "$BODY")

JS_DUE="null"
[[ -n "$DUE" ]] && JS_DUE="new Date('${DUE}')"

JS_LIST="app.defaultList()"
[[ -n "$LIST" ]] && JS_LIST="app.lists.whose({name: '$(escape_js "$LIST")'})[0]"

osascript -l JavaScript << JSEOF
const app = Application("Reminders");
const list = ${JS_LIST};
const props = {name: '${T}', priority: ${PRIORITY}};
if ('${B}') props.body = '${B}';
const due = ${JS_DUE};
if (due) props.dueDate = due;
const r = app.Reminder(props);
list.reminders.push(r);
r.name();
JSEOF

echo "Erinnerung '$TITLE' erstellt."
