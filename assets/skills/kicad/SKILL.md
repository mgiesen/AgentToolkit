---
name: kicad
description: Reviewt KiCad-Designs (.kicad_sch / .kicad_pcb) anhand von Netzliste und BOM und erzeugt Schaltplan-, PCB- und 3D-Exporte.
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "1.0"
platform: all
features:
  - Design Review anhand von Netzliste + BOM
  - Schaltplan und 3D-Renders als PDF/PNG exportieren
  - Konsolidiertes Full-Export-PDF für Dokumentation
---

# KiCad Skill

**Kernregel:** Nie `.kicad_sch` oder `.kicad_pcb` als rohe S-Expression manuell parsen. Stattdessen die Skripte unter `scripts/` nutzen — sie kapseln `kicad-cli` und produzieren entweder strukturierte Review-Daten oder fertige Exporte.

## Design Review

**Netzliste + BOM kombiniert** liefern deutlich bessere Einblicke als einzelne Betrachtung, weil Quer-Bezüge möglich werden (z.B. "an Netz X hängt Bauteil Y vom Wert Z mit Footprint F").

```bash
REVIEW=$(mktemp -d -t kicad-review)
scripts/review.sh full <projekt>.kicad_sch "$REVIEW"
# Liefert: $REVIEW/netlist.net (Pin-zu-Netz) + $REVIEW/bom.csv (Bauteile)

# Beispiel-Abfragen
grep -A12 'name "/SPI_MOSI"' "$REVIEW/netlist.net"
column -t -s, "$REVIEW/bom.csv"

rm -rf "$REVIEW"   # am Task-Ende verbindlich
```

Einzelne Sub-Modi falls nur eins gebraucht wird: `scripts/review.sh netlist <sch> <out>` oder `scripts/review.sh bom <sch> <out>`.

## Export

| Modus                                    | Aufruf                                         | Output                                                                                       |
| ---------------------------------------- | ---------------------------------------------- | -------------------------------------------------------------------------------------------- |
| Schaltplan allein                        | `scripts/export.sh schematic <sch> <out>.pdf`  | 1 PDF                                                                                        |
| 3D-Renders einzeln                       | `scripts/export.sh renders <pcb> <out-dir>`    | 4 PNGs (top, bottom, top iso, bottom iso)                                                    |
| Full Export (Default für Design-Reviews) | `scripts/export.sh full <sch> <pcb> <out>.pdf` | 1 PDF; Schaltplan-Format gibt die Seitengröße vor, alle anderen Seiten skalieren sich darauf |

**Iso-Render-Rotation** in `export.sh` als `ROT_TOP_ISO="-30,0,25"` / `ROT_BOTTOM_ISO="-30,0,-25"` gesetzt. Wenn der Anwender andere Perspektive bevorzugt: X = Tilt von oben, Z-Vorzeichen wechselt die zum User zeigende Ecke. Im Skriptkopf anpassen.
