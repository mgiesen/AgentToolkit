#!/usr/bin/env bash
# Laedt die deutsche Standardstimme nach ~/.cache/piper-voices/.
# Idempotent: vorhandene Datei wird nicht erneut geladen.

set -euo pipefail

DEST="${PIPER_VOICES_DIR:-$HOME/.cache/piper-voices}"
BASE="https://huggingface.co/rhasspy/piper-voices/resolve/main/de/de_DE/thorsten/high"

mkdir -p "$DEST"

fetch() {
  local file="$1"
  if [[ -f "$DEST/$file" ]]; then
    echo "✓ $file (vorhanden)"
    return
  fi
  echo "↓ $file"
  curl -fsSL "$BASE/$file" -o "$DEST/$file"
}

fetch "de_DE-thorsten-high.onnx"
fetch "de_DE-thorsten-high.onnx.json"

echo "Voice in: $DEST"
