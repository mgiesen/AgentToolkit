---
name: chart
description: Diagramme und Charts erzeugen (Linie, Balken, Kreis) als SVG oder PNG. Verwenden wenn Daten visualisiert, Statistiken dargestellt oder Vergleiche grafisch aufbereitet werden sollen.
---

# Chart Skill

Erzeugt Diagramme aus JSON-Daten als SVG oder PNG via matplotlib. Konfigurierbare Farbthemen (academic, vibrant, mono, dark).

## Diagrammtypen

- **line**: Zeitreihen, Trends, Entwicklungen
- **bar**: Vergleiche zwischen Kategorien, Rankings
- **pie**: Anteile an einem Ganzen (nur bei 2-6 Segmenten)

## Grundaufruf

```bash
scripts/chart.sh <type> --data <json> --output <pfad> [optionen]
```

## Beispiele

```bash
# Liniendiagramm
scripts/chart.sh line \
  --data '{"labels":["Q1","Q2","Q3","Q4"],"values":[12,19,8,15],"ylabel":"Anzahl"}' \
  --title "Trend" --output chart.svg

# Balkendiagramm
scripts/chart.sh bar \
  --data '{"labels":["A","B","C"],"values":[30,50,20]}' \
  --title "Vergleich" --output chart.svg

# Kreisdiagramm
scripts/chart.sh pie \
  --data '{"labels":["X","Y","Z"],"values":[45,35,20]}' \
  --title "Verteilung" --output chart.png

# Mehrere Datenreihen
scripts/chart.sh line \
  --data '{"labels":["2022","2023","2024"],"series":[{"name":"A","values":[10,15,20]},{"name":"B","values":[5,12,18]}]}' \
  --title "Vergleich" --output chart.svg
```

## Themes

Ueber `--theme` wird das Farbschema gewaehlt:

| Theme        | Einsatz                                            | Farben                      |
| ------------ | -------------------------------------------------- | --------------------------- |
| **academic** | Wissenschaftliche Reports, Papers                  | Gedaempft, druckfreundlich  |
| **vibrant**  | READMEs, Praesentationen, Marketing                | Kraeftig, modern            |
| **mono**     | Technische Doku, minimalistisch                    | Graustufen                  |
| **dark**     | Darkmode-Dokumente, Slides mit dunklem Hintergrund | Leuchtend auf dunklem Grund |

```bash
# Vibrant fuer ein README
scripts/chart.sh bar \
  --data '{"labels":["Feature A","Feature B"],"values":[85,92]}' \
  --theme vibrant --output chart.svg

# Academic fuer einen Report
scripts/chart.sh line \
  --data '{"labels":["Jan","Feb","Mär"],"values":[10,15,12]}' \
  --theme academic --output chart.svg
```

## Eigene Farben

Mit `--colors` koennen die Theme-Farben ueberschrieben werden:

```bash
scripts/chart.sh bar \
  --data '{"labels":["A","B","C"],"values":[30,50,20]}' \
  --colors "#ff6b6b,#4ecdc4,#45b7d1" --output chart.svg
```

## Optionen

| Option     | Beschreibung                                           |
| ---------- | ------------------------------------------------------ |
| `--theme`  | Farbthema: academic, vibrant, mono, dark               |
| `--colors` | Eigene Hex-Farben (kommagetrennt, ueberschreibt Theme) |
| `--title`  | Diagrammtitel                                          |
| `--width`  | Breite in Zoll (default: 6)                            |
| `--height` | Hoehe in Zoll (default: 3.5)                           |
| `--output` | Ausgabepfad (.svg oder .png)                           |

## Datenformat

JSON mit `labels` und `values` (einfach) oder `series` (mehrere Reihen):

```json
{ "labels": ["A", "B", "C"], "values": [10, 20, 30] }
```

```json
{
	"labels": ["2022", "2023", "2024"],
	"series": [
		{ "name": "Produkt A", "values": [10, 15, 20] },
		{ "name": "Produkt B", "values": [5, 12, 18] }
	],
	"xlabel": "Jahr",
	"ylabel": "Umsatz (Mio)"
}
```

Daten koennen als JSON-String oder als Pfad zu einer JSON-Datei uebergeben werden.
