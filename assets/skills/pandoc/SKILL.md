---
name: pandoc
description: Dokumente konvertieren zwischen Markdown, PDF, Word, HTML, EPUB, PowerPoint u.v.m. via pandoc + typst. Agnostisches Werkzeug — bringt keine eigenen PDF-Templates mit; Templates kommen vom Aufrufer (Agent oder User).
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "2.0"
platform: all
features:
  - Markdown zu PDF konvertieren (typst-Engine, beliebiges Template als Pfad uebergeben)
  - Markdown zu Word (.docx), PowerPoint (.pptx), EPUB, HTML konvertieren
  - Word/PPTX zurueck zu Markdown extrahieren
  - Inhaltsverzeichnis, Abschnittsnummerierung und Syntax-Highlighting konfigurieren
  - KI-generiertes Markdown vorbereiten (Listen-Spacing, IEEE-Zitations-Linkung)
---

# Pandoc Skill

Universelle Dokumentkonvertierung via pandoc + typst. **Agnostisches Werkzeug** — dieser Skill liefert keine PDF-Templates. Wer ein gestyltes PDF braucht, bringt sein Typst-Template selbst mit (z.B. aus einem Subagenten-Ordner oder aus dem eigenen Projekt).

## Voraussetzungen

- `pandoc` (siehe `install.yaml`)
- `typst` (siehe `install.yaml`) — schnelle PDF-Engine, ersetzt LaTeX

Beide installierbar via `brew install pandoc typst` (macOS) bzw. den in `install.yaml` hinterlegten Paketmanagern.

## Markdown zu PDF

Empfohlener Weg: der gebuendelte Helper `scripts/build_pdf.py`. Er erledigt Markdown-Vorverarbeitung und ruft pandoc + typst mit den richtigen Flags auf.

```bash
# Mit eigenem Template:
.venv/bin/python3 ~/.claude/skills/pandoc/scripts/build_pdf.py \
  --input report.md \
  --output report.pdf \
  --template /abs/path/to/template.typ

# Ohne Template (pandoc/typst Default):
.venv/bin/python3 ~/.claude/skills/pandoc/scripts/build_pdf.py \
  --input report.md \
  --output report.pdf

# Zusaetzliche Variablen:
.venv/bin/python3 ~/.claude/skills/pandoc/scripts/build_pdf.py \
  --input report.md --output report.pdf \
  --template tpl.typ \
  -V mainfont="Helvetica Neue" -V toc=true -V "title=Mein Dokument"
```

Manueller Aufruf ohne Helper (gleichwertig):

```bash
# 1. Markdown vorverarbeiten (fehlende Leerzeilen vor Listen + IEEE-Zitate verlinken)
python3 ~/.claude/skills/pandoc/scripts/fix_markdown.py input.md /tmp/input_fixed.md

# 2. PDF erzeugen (--pdf-engine-opt=--root=/ noetig, damit typst absolute Pfade aufloest)
pandoc /tmp/input_fixed.md --pdf-engine=typst \
  -V template=/abs/path/to/template.typ \
  --pdf-engine-opt=--root=/ \
  -o output.pdf
```

### Templates

Templates sind **nicht** Teil dieses Skills. Wo sie herkommen:

- **Subagenten**: Bringen ihre eigenen Templates in ihrem Agent-Ordner mit (z.B. `assets/agents/report-writer/templates/research-report.typ`). Der Agent loest seinen Template-Pfad selbst auf und uebergibt ihn an `--template`.
- **Projekt-eigene Templates**: Liegen im jeweiligen Projekt, werden mit absolutem Pfad uebergeben.
- **Default**: Ohne `--template` nutzt pandoc/typst den eingebauten Default — minimalistisch, aber funktional.

### PDF-Optionen via YAML-Frontmatter

Typst-Templates lesen ueblicherweise YAML-Frontmatter-Variablen wie `title`, `subtitle`, `author`, `date`, `abstract`, `toc`. Das konkrete Set haengt vom Template ab.

Beispiel-Frontmatter:

```yaml
---
title: "Dokumenttitel"
subtitle: "Untertitel"
author: "Max Giesen"
date: "27. April 2026"
lang: de
papersize: a4
fontsize: 11pt
toc: true
toc-depth: 3
---
```

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

Pandoc erzeugt direkt Praesentationen. Ueberschriften strukturieren die Folien:

- `# Heading 1` → Abschnittstrenner-Folie
- `## Heading 2` → Neue Folie (Titel)
- Inhalt unter `##` → Folieninhalt (Bullets, Bilder, Tabellen)
- `---` → Manuelle Folientrennung

```bash
pandoc input.md -o output.pptx
pandoc input.md --reference-doc=template.pptx -o output.pptx  # Corporate Design
pandoc input.md --slide-level=2 -o output.pptx
```

## Markdown zu EPUB

```bash
pandoc input.md -o output.epub

# Mit Cover und Metadaten
pandoc input.md --epub-cover-image=cover.jpg \
  --metadata title="Buchtitel" --metadata author="Autor" \
  --toc --toc-depth=2 -o output.epub

# Mehrere Kapitel
pandoc kapitel1.md kapitel2.md kapitel3.md --toc -o buch.epub
```

## Markdown zu HTML

Immer `-f gfm` (GitHub Flavored Markdown) verwenden — sonst werden Listen ohne Leerzeile zu Fliesstext.

```bash
# Standalone mit eingebetteten Bildern/CSS
pandoc -f gfm -s --embed-resources --standalone input.md -o output.html

# Mit eigenem Styling
pandoc -f gfm -s -H styling.html input.md -o output.html
```

## Word zu Markdown

```bash
pandoc input.docx -o output.md
pandoc input.docx --track-changes=all -o output.md     # mit Aenderungen sichtbar
```

## Markdown vorbereiten — `fix_markdown.py`

KI-generiertes Markdown hat oft Probleme, die das PDF-Rendering brechen:

- **Fehlende Leerzeilen vor Listen** → Liste wird als Fliesstext gerendert
- **IEEE-Zitate `[1]` im Fliesstext** → unverlinkt, kein Sprung zum Quellenverzeichnis

`scripts/fix_markdown.py` behebt beides automatisch. Wenn das Dokument kein Quellenverzeichnis enthaelt, ist die Zitations-Logik ein No-op.

```bash
python3 ~/.claude/skills/pandoc/scripts/fix_markdown.py input.md output_fixed.md
```

`build_pdf.py` ruft diesen Schritt automatisch auf; mit `--skip-fix` lasst er sich abschalten.

## Format-Bezeichner

| Format     | Bezeichner                       |
| ---------- | -------------------------------- |
| Markdown   | `markdown`, `gfm`, `commonmark`  |
| Word       | `docx`                           |
| PDF        | `pdf` (via typst)                |
| PowerPoint | `pptx`                           |
| HTML       | `html`, `html5`                  |
| LaTeX      | `latex`                          |
| RST        | `rst`                            |
| EPUB       | `epub`                           |
| ODT        | `odt`                            |
| RTF        | `rtf`                            |

## Nuetzliche Optionen

| Option                    | Beschreibung                              |
| ------------------------- | ----------------------------------------- |
| `-s` / `--standalone`     | Eigenstaendiges Dokument mit Header/Footer |
| `--toc`                   | Inhaltsverzeichnis generieren             |
| `--toc-depth=N`           | TOC-Tiefe (Standard: 3)                  |
| `-V key=value`            | Template-Variable setzen                  |
| `--metadata key=value`    | Metadaten-Feld setzen                     |
| `--reference-doc=FILE`    | Styling-Vorlage (docx/odt/pptx)          |
| `--template=FILE`         | Pandoc-Template (nicht typst-Template)    |
| `--highlight-style=STYLE` | Syntax-Highlighting                       |
| `--number-sections`       | Abschnitts-Nummerierung                   |
| `-f FORMAT`               | Eingabeformat (falls nicht erkannt)       |
| `-t FORMAT`               | Ausgabeformat (falls nicht erkannt)       |

## Troubleshooting

### Listen/Zeilen laufen zusammen

`fix_markdown.py` vor der Konvertierung laufen lassen, fuer HTML zusaetzlich `-f gfm` setzen.

### `typst not found`

```bash
brew install typst         # macOS
apt install typst          # Debian/Ubuntu
winget install Typst.Typst # Windows
```

### Template wird nicht gefunden

`--pdf-engine-opt=--root=/` setzen, damit typst absolute Pfade aufloesen darf. `build_pdf.py` setzt das automatisch.
