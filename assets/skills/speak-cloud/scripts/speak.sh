#!/usr/bin/env bash
# Spricht Text via ElevenLabs Cloud-API aus.
#   ./speak.sh "Hallo Welt"
#   echo "Hi" | ./speak.sh
#   VOICE_ID=... MODEL=... ./speak.sh "..."
#   ./speak.sh -o out.mp3 "nur speichern"
#   ./speak.sh -q                       # nur Kontingent anzeigen
#   ./speak.sh -d <history-id>          # einen History-Eintrag loeschen

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

[[ -f "$REPO_ROOT/.env" ]] && { set -a; source "$REPO_ROOT/.env"; set +a; }

: "${ELEVENLABS_API_KEY:?ELEVENLABS_API_KEY nicht gesetzt. Siehe .env.example}"

VOICE_ID="${VOICE_ID:-JBFqnCBsd6RMkjVDRZzb}"
MODEL="${MODEL:-eleven_v3}"
FORMAT="${FORMAT:-mp3_44100_128}"
OUT=""
QUOTA_ONLY=0
DELETE_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -q|--quota) QUOTA_ONLY=1; shift ;;
    -o|--output) OUT="$2"; shift 2 ;;
    -d|--delete) DELETE_ID="$2"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

format_quota() {
  local body code
  body="$(mktemp -t eleven_sub).json"
  code="$(curl -sS -o "$body" -w "%{http_code}" \
    https://api.elevenlabs.io/v1/user/subscription \
    -H "xi-api-key: ${ELEVENLABS_API_KEY}" 2>/dev/null || echo "000")"
  if [[ "$code" == "200" ]]; then
    python3 - "$body" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
used, limit = d["character_count"], d["character_limit"]
remaining = limit - used
pct = round(remaining / limit * 100) if limit else 0
fmt = lambda n: f"{n:,}".replace(",", ".")
print(f"noch {fmt(remaining)} von {fmt(limit)} frei ({pct}%)")
PY
    rm -f "$body"
    return 0
  fi
  rm -f "$body"
  return 1
}

# Loescht einen History-Eintrag mit kurzem Retry (History erscheint zeitverzoegert).
delete_history_item() {
  local id="$1" code
  local try
  for try in 1 2; do
    code="$(curl -sS -o /dev/null -w "%{http_code}" -X DELETE \
      "https://api.elevenlabs.io/v1/history/${id}" \
      -H "xi-api-key: ${ELEVENLABS_API_KEY}" 2>/dev/null || echo "000")"
    case "$code" in
      200|204) return 0 ;;
      404) sleep 2 ;;
      *) echo "Loeschen fehlgeschlagen (HTTP ${code})" >&2; return 1 ;;
    esac
  done
  echo "Loeschen fehlgeschlagen — History-Eintrag nicht gefunden" >&2
  return 1
}

if [[ $QUOTA_ONLY -eq 1 ]]; then
  if line="$(format_quota)"; then
    echo "Kontingent: $line"
  else
    echo "Kontingent nicht abrufbar — API-Key braucht 'user_read' Scope" >&2
    exit 1
  fi
  exit 0
fi

if [[ -n "$DELETE_ID" ]]; then
  if delete_history_item "$DELETE_ID"; then
    echo "✓ History-Eintrag ${DELETE_ID} geloescht"
  else
    exit 1
  fi
  exit 0
fi

if [[ $# -gt 0 ]]; then
  TEXT="$*"
else
  TEXT="$(cat)"
fi

PLAY=1
if [[ -n "$OUT" ]]; then
  PLAY=0
  mkdir -p "$(dirname "$OUT")"
else
  OUT="$(mktemp -t speak).mp3"
fi

HDR="$(mktemp -t eleven_hdr).txt"
BODY="$(python3 -c 'import json,sys; print(json.dumps({"text":sys.argv[1],"model_id":sys.argv[2]}))' "$TEXT" "$MODEL")"

curl -fsS -D "$HDR" -X POST \
  "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}?output_format=${FORMAT}&enable_logging=false" \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$BODY" \
  -o "$OUT"

COST="$(awk 'tolower($1)=="character-cost:"{print $2}' "$HDR" | tr -d '\r')"
HIST_ID="$(awk 'tolower($1)=="history-item-id:"{print $2}' "$HDR" | tr -d '\r')"
rm -f "$HDR"

if line="$(format_quota)"; then
  echo "→ ${COST:-?} Zeichen abgerechnet · $line" >&2
else
  echo "→ ${COST:-?} Zeichen abgerechnet (Kontingent nicht abrufbar — API-Key braucht 'user_read' Scope)" >&2
fi
[[ -n "$HIST_ID" ]] && echo "History: ${HIST_ID}" >&2

if [[ $PLAY -eq 1 ]]; then
  afplay "$OUT"
  rm -f "$OUT"
else
  echo "$OUT"
fi
