---
name: pandoc
description: Dokumente erstellen und konvertieren (Markdown, Word, PDF, HTML, EPUB, PowerPoint u.v.m.) via pandoc + typst. Zwei PDF-Templates enthalten (Default fuer allgemeine Dokumente, Research Report fuer wissenschaftliche Berichte).
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "1.0"
platform: all
features:
  - Markdown zu PDF mit professionellen Typst-Templates konvertieren
  - Markdown zu Word (.docx), PowerPoint (.pptx) oder EPUB konvertieren
  - HTML-Ausgabe mit eingebetteten Ressourcen erzeugen
  - Inhaltsverzeichnis, Abschnittsnummerierung und Syntax-Highlighting konfigurieren
  - Word-Dokumente zurück zu Markdown extrahieren
---

# Pandoc Skill

Universelle Dokumentkonvertierung via pandoc + typst.

## Voraussetzungen

- `pandoc` (`brew install pandoc`)
- `typst` (`brew install typst`) — PDF-Engine

## PDF-Konvertierung: Pflicht-Ablauf

**Vor jeder PDF-Erzeugung** pruefen:

```bash
which typst || echo "FEHLT: brew install typst"
```

Wenn typst fehlt: Dem User mitteilen, dass `brew install typst` noetig ist. Nicht improvisieren, keine alternativen Tools versuchen.

## Templates

Im Skill-Ordner liegen fertige Typst-Templates unter `templates/`. Der Pfad zum Template-Ordner ist:

```
~/.claude/skills/pandoc/templates/
```

| Template            | Datei                 | Einsatz                                                   | Font                          |
| ------------------- | --------------------- | --------------------------------------------------------- | ----------------------------- |
| **Default**         | `default.typ`         | Berichte, Dokumentationen, Specs                          | Avenir Next + Menlo           |
| **Research Report** | `research-report.typ` | Wissenschaftliche Berichte, Rechercheergebnisse           | Charter + Avenir Next + Menlo |
| **Datasheet**       | `datasheet.typ`       | Technische Datenblaetter (Querformat, schwarze Tabellen) | Helvetica Neue + Menlo        |

## Markdown zu PDF

Immer mit Template und `--pdf-engine-opt=--root=/` (damit typst Dateien findet):

```bash
# 1. Markdown vorverarbeiten (fehlende Leerzeilen vor Listen korrigieren)
python3 scripts/fix_markdown.py input.md /tmp/input_fixed.md

# 2. PDF erzeugen
pandoc /tmp/input_fixed.md --pdf-engine=typst \
  -V template=~/.claude/skills/pandoc/templates/default.typ \
  --pdf-engine-opt=--root=/ \
  -o output.pdf
```

Der Preprocessing-Schritt ist besonders bei KI-generiertem Markdown wichtig, da Listen ohne Leerzeile nach Doppelpunkt sonst als Fliesstext gerendert werden.

### Datenblatt (datasheet.typ) — Sonderfall mit Pre-Processing

Das Datenblatt-Template darf **nicht** direkt mit `--pdf-engine=typst` gebaut werden. Pandoc erzeugt fuer Pipe-Tabellen Spaltenbreiten anhand der Strich-Anzahl (`---`), was bei kurzen Headern wie `Nr` zu unbrauchbar schmalen Spalten (<2 %) fuehrt. Ausserdem bleiben fettgedruckte Pseudo-Ueberschriften (`**Foo**` allein auf einer Zeile) ohne Block-Wrapper und werden am Seitenende verwaist abgehaengt.

Verwende daher das Wrapper-Skript:

```bash
~/.claude/skills/pandoc/scripts/build_datasheet.sh input.md output.pdf
```

Das Skript laeuft 3-stufig:

1. `fix_markdown.py` — fehlende Leerzeilen vor Listen ergaenzen
2. `pandoc --to typst --standalone` — Typst-Quellcode generieren
3. `normalize_table_columns.py` — Spalten auf min. 7 % normalisieren, `horizontalrule` neutralisieren, eigenstaendige `#strong[...]` als sticky-Bloecke wickeln
4. `typst compile` — finales PDF

Fuer Datenblaetter empfohlen: Querformat (vom Template gesetzt), Spalten linksbuendig mit schwarzem Vollgitter, Tabellenheader bei Seitenumbruch wiederholt, keine farbigen Akzente.

### PDF-Optionen via Frontmatter

Alle Templates unterstuetzen diese YAML-Frontmatter-Variablen:

```yaml
---
title: "Dokumenttitel"
subtitle: "Untertitel"
author: "Max Giesen"
date: "27. April 2026"
lang: de
papersize: a4
fontsize: 11pt
linestretch: 1.5
section-numbering: "1.1"
toc: true
toc-depth: 3
mainfont: "Helvetica Neue"
---
```

### Verfuegbare Fonts (auf diesem System installiert)

Sans-Serif: Avenir Next, Helvetica Neue, PT Sans, Futura, Gill Sans, Seravek, DIN
Serif: Charter, Palatino, New York, Baskerville, Cochin, Iowan Old Style, PT Serif, Libertinus Serif
Monospace: Menlo, Monaco, PT Mono, DejaVu Sans Mono, Courier New

## Markdown zu Word (.docx)

```bash
# Einfache Konvertierung
pandoc input.md -o output.docx

# Mit Inhaltsverzeichnis
pandoc input.md --toc -o output.docx

# Mit Referenz-Dokument (fuer Styling)
pandoc input.md --reference-doc=template.docx -o output.docx

# Standalone mit Metadaten
pandoc input.md -s --metadata title="Dokumenttitel" -o output.docx
```

## Markdown zu PowerPoint (.pptx)

Pandoc kann direkt Praesentationen erzeugen. Ueberschriften strukturieren die Folien:

- `# Heading 1` → Abschnittstrenner-Folie
- `## Heading 2` → Neue Folie (Titel)
- Inhalt unter `##` → Folieninhalt (Bullets, Bilder, Tabellen)
- `---` → Manuelle Folientrennung

```bash
# Einfache Praesentation
pandoc input.md -o output.pptx

# Mit Referenz-Dokument (fuer Corporate Design)
pandoc input.md --reference-doc=template.pptx -o output.pptx

# Slide-Level anpassen (Standard: 2)
pandoc input.md --slide-level=2 -o output.pptx
```

### Beispiel-Markdown fuer Praesentation

```markdown
---
title: "Quartalsbericht Q1"
author: "Max Giesen"
date: "2026-04-27"
---

# Ueberblick

## Kernzahlen

- Umsatz: +15%
- Neukunden: 342
- Churn Rate: 2.1%

## Roadmap

| Quartal | Fokus          |
|---------|----------------|
| Q2      | API v2 Launch  |
| Q3      | Mobile App     |

## Naechste Schritte

1. Team-Erweiterung
2. Infrastruktur-Upgrade
3. Kundenfeedback auswerten
```

## Markdown zu EPUB

```bash
# Standard
pandoc input.md -o output.epub

# Mit Cover-Bild und Metadaten
pandoc input.md --epub-cover-image=cover.jpg \
  --metadata title="Buchtitel" \
  --metadata author="Autor" \
  --toc --toc-depth=2 \
  -o output.epub

# Mehrere Kapitel-Dateien
pandoc kapitel1.md kapitel2.md kapitel3.md --toc -o buch.epub
```

## Markdown zu HTML

Immer `-f gfm` (GitHub Flavored Markdown) verwenden fuer korrekte Listen und Zeilenumbrueche.

```bash
# Empfohlen: GFM mit vollstaendigem Styling
pandoc -f gfm -s -H <(cat << 'STYLE'
<style>
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;max-width:800px;margin:0 auto;padding:2em;line-height:1.6}
h1{border-bottom:2px solid #333;padding-bottom:0.3em}
h2{border-bottom:1px solid #ccc;padding-bottom:0.2em;margin-top:1.5em}
h3{margin-top:1.2em}
ul,ol{margin:0.5em 0 0.5em 1.5em;padding-left:1em}
ul{list-style-type:disc}ol{list-style-type:decimal}
li{margin:0.3em 0}ul ul,ol ul{list-style-type:circle;margin:0.2em 0 0.2em 1em}
table{border-collapse:collapse;width:100%;margin:1em 0}
th,td{border:1px solid #ddd;padding:8px;text-align:left}
th{background-color:#f5f5f5}
code{background-color:#f4f4f4;padding:2px 6px;border-radius:3px}
pre{background-color:#f4f4f4;padding:1em;overflow-x:auto;border-radius:5px}
blockquote{border-left:4px solid #ddd;margin:1em 0;padding-left:1em;color:#666}
</style>
STYLE
) input.md -o output.html

# Self-contained (bettet Bilder/CSS ein)
pandoc -f gfm -s --embed-resources --standalone input.md -o output.html
```

## Word zu Markdown

```bash
pandoc input.docx -o output.md
pandoc input.docx --atx-headers -o output.md
```

## Google Docs Workflow

Markdown ueber den Umweg Word in Google Docs bringen:

```bash
# 1. In docx konvertieren
pandoc dokument.md -o dokument.docx

# 2. Auf Google Drive hochladen
# 3. Rechtsklick > Oeffnen mit > Google Docs
```

## Nuetzliche Optionen

| Option                   | Beschreibung                              |
| ------------------------ | ----------------------------------------- |
| `-s` / `--standalone`    | Eigenstaendiges Dokument mit Header/Footer |
| `--toc`                  | Inhaltsverzeichnis generieren             |
| `--toc-depth=N`          | TOC-Tiefe (Standard: 3)                  |
| `-V key=value`           | Template-Variable setzen                  |
| `--metadata key=value`   | Metadaten-Feld setzen                     |
| `--reference-doc=FILE`   | Styling-Vorlage (docx/odt/pptx)          |
| `--template=FILE`        | Benutzerdefiniertes Template              |
| `--highlight-style=STYLE`| Syntax-Highlighting (pygments, tango etc.)|
| `--number-sections`      | Abschnitts-Nummerierung                   |
| `-f FORMAT`              | Eingabeformat (falls nicht erkannt)       |
| `-t FORMAT`              | Ausgabeformat (falls nicht erkannt)       |

## Format-Bezeichner

| Format     | Bezeichner                          |
| ---------- | ----------------------------------- |
| Markdown   | `markdown`, `gfm`, `commonmark`    |
| Word       | `docx`                              |
| PDF        | `pdf` (via typst)                   |
| PowerPoint | `pptx`                              |
| HTML       | `html`, `html5`                     |
| LaTeX      | `latex`                             |
| RST        | `rst`                               |
| EPUB       | `epub`                              |
| ODT        | `odt`                               |
| RTF        | `rtf`                               |

## Troubleshooting

### Listen/Zeilen laufen zusammen (HTML)

```bash
# Immer -f gfm verwenden
pandoc -f gfm -s input.md -o output.html
```

### PDF-Generierung schlaegt fehl

**"typst not found":**

```bash
brew install typst
```

**Template nicht gefunden:**

Sicherstellen, dass `--pdf-engine-opt=--root=/` gesetzt ist, damit typst absolute Pfade aufloesen kann.

