#!/usr/bin/env bash
# Liest Text vor (Piper TTS, Deutsch) und gibt ihn ueber die Lautsprecher aus.
#   ./speak.sh "Hallo Welt"
#   echo "Hi" | ./speak.sh
#   SPEED=0.85 ./speak.sh "schneller"
#   ./speak.sh -o pfad.wav "nur speichern"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
VOICES_DIR="${PIPER_VOICES_DIR:-$HOME/.cache/piper-voices}"
MODEL="$VOICES_DIR/de_DE-thorsten-high.onnx"

SPEED="${SPEED:-1.0}"
OUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -o|--output) OUT="$2"; shift 2 ;;
    --) shift; break ;;
    *) break ;;
  esac
done

if [[ ! -f "$MODEL" ]]; then
  echo "Voice fehlt: $MODEL" >&2
  echo "Hinweis: $SCRIPT_DIR/fetch-voices.sh ausfuehren." >&2
  exit 1
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
  OUT="$(mktemp -t speak).wav"
fi

echo "$TEXT" | "$REPO_ROOT/.venv/bin/python" -m piper -m "$MODEL" --length-scale "$SPEED" -f "$OUT" 2>/dev/null

if [[ $PLAY -eq 1 ]]; then
  afplay "$OUT"
  rm -f "$OUT"
else
  echo "$OUT"
fi
