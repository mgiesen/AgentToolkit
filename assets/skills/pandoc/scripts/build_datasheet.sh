#!/usr/bin/env bash
# Build-Pipeline fuer das Datenblatt-Template.
#
# Pandoc generiert Tabellen mit Spaltenbreiten basierend auf der Anzahl
# der `-` Zeichen unter den Pipe-Header in der Markdown-Quelle. Bei
# kurzen Headern (z. B. "Nr") werden die Spalten unbrauchbar schmal.
# Außerdem rendert Pandoc `---` als kurze horizontale Linie und alleine
# stehende `**Text**`-Zeilen ohne Block-Wrapper, was zu verwaisten
# Pseudo-Ueberschriften am Seitenende fuehrt.
#
# Diese Pipeline:
#   1. erzeugt eigenstaendigen Typst-Code via pandoc
#   2. normalisiert Spaltenbreiten, neutralisiert horizontalrule
#      und macht fettgedruckte Pseudo-Ueberschriften "sticky"
#   3. kompiliert mit typst zu PDF
#
# Usage:
#   build_datasheet.sh <input.md> <output.pdf> [template.typ]
#
# Default template: ~/.claude/skills/pandoc/templates/datasheet.typ

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: build_datasheet.sh <input.md> <output.pdf> [template.typ]" >&2
  exit 2
fi

INPUT="$1"
OUTPUT="$2"
TEMPLATE="${3:-$HOME/.claude/skills/pandoc/templates/datasheet.typ}"

if [[ ! -f "$INPUT" ]]; then
  echo "input not found: $INPUT" >&2
  exit 1
fi
if [[ ! -f "$TEMPLATE" ]]; then
  echo "template not found: $TEMPLATE" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NORMALIZE="$SCRIPT_DIR/normalize_table_columns.py"
FIX_MD="$SCRIPT_DIR/fix_markdown.py"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

FIXED_MD="$TMP_DIR/input_fixed.md"
RAW_TYP="$TMP_DIR/raw.typ"
NORM_TYP="$TMP_DIR/normalized.typ"

python3 "$FIX_MD" "$INPUT" "$FIXED_MD"

pandoc "$FIXED_MD" \
  --to typst \
  --standalone \
  -V template="$TEMPLATE" \
  -o "$RAW_TYP"

python3 "$NORMALIZE" "$RAW_TYP" "$NORM_TYP"

typst compile "$NORM_TYP" "$OUTPUT" --root /

echo "datasheet built: $OUTPUT"
