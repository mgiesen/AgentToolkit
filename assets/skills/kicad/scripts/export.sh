#!/usr/bin/env bash
# KiCad-Export-Modi:
#   schematic <projekt>.kicad_sch <out>.pdf
#       → Schaltplan als PDF.
#
#   renders <projekt>.kicad_pcb <out-dir>
#       → Vier einzelne PNGs in den Ordner schreiben:
#         3d_top.png, 3d_bottom.png, 3d_top_iso.png, 3d_bottom_iso.png.
#
#   full <projekt>.kicad_sch <projekt>.kicad_pcb <out>.pdf
#       → Schaltplan + Top/Bottom-Iso-Render zu einem PDF (3 Seiten).
#         Plain Top/Down-Render bewusst weggelassen — der Iso-Blick
#         zeigt Layout und Bauteile in einem Bild. Die Schaltplan-Seite
#         gibt die Page-Größe vor; alle anderen Seiten skalieren sich
#         darauf (aspect-preservierend, mit Rand).
#
# Iso-Rotation (X=Tilt, Z-Vorzeichen wählt die zum User zeigende Ecke):
#   Top:    -30,0,25     Bottom: -30,0,-25
# Falls der Anwender eine andere Perspektive bevorzugt, hier anpassen.

set -euo pipefail

ROT_TOP_ISO="-30,0,25"
ROT_BOTTOM_ISO="-30,0,-25"
RENDER_OPTS=(--width 2400 --height 1600 --quality high)

usage() {
  sed -n '2,15p' "$0" >&2
  exit 2
}

render_schematic() {
  kicad-cli sch export pdf --no-background-color -o "$2" "$1" >/dev/null
}

render_3d() {
  local pcb=$1 dir=$2
  kicad-cli pcb render "${RENDER_OPTS[@]}" --side top \
    -o "$dir/3d_top.png" "$pcb" >/dev/null
  kicad-cli pcb render "${RENDER_OPTS[@]}" --side bottom \
    -o "$dir/3d_bottom.png" "$pcb" >/dev/null
  kicad-cli pcb render "${RENDER_OPTS[@]}" --side top --perspective --rotate "$ROT_TOP_ISO" \
    -o "$dir/3d_top_iso.png" "$pcb" >/dev/null
  kicad-cli pcb render "${RENDER_OPTS[@]}" --side bottom --perspective --rotate "$ROT_BOTTOM_ISO" \
    -o "$dir/3d_bottom_iso.png" "$pcb" >/dev/null
}

cmd=${1:-}; shift || usage

case "$cmd" in
  schematic)
    [ $# -eq 2 ] || usage
    render_schematic "$1" "$2"
    echo "$2"
    ;;

  renders)
    [ $# -eq 2 ] || usage
    mkdir -p "$2"
    render_3d "$1" "$2"
    echo "$2"
    ;;

  full)
    [ $# -eq 3 ] || usage
    TMP=$(mktemp -d -t kicad-export)
    trap 'rm -rf "$TMP"' EXIT

    render_schematic "$1" "$TMP/01_schematic.pdf"
    kicad-cli pcb render "${RENDER_OPTS[@]}" --side top --perspective --rotate "$ROT_TOP_ISO" \
      -o "$TMP/02_3d_top_iso.png" "$2" >/dev/null
    kicad-cli pcb render "${RENDER_OPTS[@]}" --side bottom --perspective --rotate "$ROT_BOTTOM_ISO" \
      -o "$TMP/03_3d_bottom_iso.png" "$2" >/dev/null

    for f in "$TMP"/0[2-3]_*.png; do
      magick "$f" "${f%.png}.pdf"
    done

    # Page-Größe aus Schaltplan via cpdf, dann mergen und scale-to-fit
    mediabox=$(cpdf -page-info -i "$TMP/01_schematic.pdf" | awk '/^MediaBox:/ {printf "%s %s", $4, $5; exit}')
    cpdf -merge "$TMP"/0?_*.pdf -o "$TMP/merged.pdf"
    cpdf -scale-to-fit "$mediabox" "$TMP/merged.pdf" -o "$3"
    echo "$3"
    ;;

  *) usage ;;
esac
