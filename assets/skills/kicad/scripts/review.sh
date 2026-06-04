#!/usr/bin/env bash
# Review-Daten aus einem KiCad-Schaltplan extrahieren — Input für KI-Analyse.
#
# Modi:
#   netlist <projekt>.kicad_sch <out>.net
#       → Strukturierte Netzliste (kicadsexpr-Format).
#
#   bom <projekt>.kicad_sch <out>.csv
#       → Bauteilliste, gruppiert nach Value. Felder/Labels nicht
#         vorgegeben — kicad-cli nutzt die im Projekt definierten
#         Defaults bzw. Reference/Value/Footprint/Quantity/DNP.
#
#   full <projekt>.kicad_sch <out-dir>
#       → Beides in einem Verzeichnis: netlist.net + bom.csv.
#         Standard-Variante. Beide Dateien zusammen erlauben deutlich
#         bessere Antworten als eine einzelne (z.B. Bauteilkontext zu
#         einem Netz, Querverweise Pin ↔ Wert ↔ Footprint).

set -euo pipefail

usage() { sed -n '2,18p' "$0" >&2; exit 2; }

export_netlist() {
  kicad-cli sch export netlist --format kicadsexpr -o "$2" "$1" >/dev/null
}

export_bom() {
  kicad-cli sch export bom --group-by Value -o "$2" "$1" >/dev/null
}

cmd=${1:-}; shift || usage

case "$cmd" in
  netlist) [ $# -eq 2 ] || usage; export_netlist "$1" "$2"; echo "$2" ;;
  bom)     [ $# -eq 2 ] || usage; export_bom     "$1" "$2"; echo "$2" ;;
  full)
    [ $# -eq 2 ] || usage
    mkdir -p "$2"
    export_netlist "$1" "$2/netlist.net"
    export_bom     "$1" "$2/bom.csv"
    echo "$2"
    ;;
  *) usage ;;
esac
