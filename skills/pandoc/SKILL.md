---
name: pandoc
description: Dokumentkonvertierung zwischen Formaten (Markdown, Word, PDF, HTML, LaTeX, EPUB u.v.m.) via pandoc.
---

# Pandoc Skill

Universelle Dokumentkonvertierung via pandoc.

## Voraussetzungen

- `pandoc` (`brew install pandoc`)
- Fuer PDF-Ausgabe: LaTeX (`brew install --cask basictex` oder `brew install --cask mactex-no-gui`)

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

## Markdown zu PDF

Benoetigt LaTeX. Nach Installation: `eval "$(/usr/libexec/path_helper)"` oder neues Terminal.

```bash
# Standard (pdflatex)
pandoc input.md -o output.pdf

# Mit Inhaltsverzeichnis und Raendern
pandoc input.md -s --toc --toc-depth=2 -V geometry:margin=1in -o output.pdf

# xelatex (bessere Unicode-Unterstuetzung: Pfeile, Boxen, Emojis)
export PATH="/Library/TeX/texbin:$PATH"
pandoc input.md --pdf-engine=xelatex -V geometry:margin=1in -o output.pdf
```

PDF-Engine-Auswahl:

| Engine     | Einsatz                                     |
| ---------- | ------------------------------------------- |
| `pdflatex` | Standard, reiner ASCII-Inhalt               |
| `xelatex`  | Unicode-Zeichen (Pfeile, Boxzeichnung, Emojis) |
| `lualatex` | Komplexe Typografie, OpenType-Fonts         |

## Markdown zu HTML

Wichtig: Immer `-f gfm` (GitHub Flavored Markdown) verwenden fuer korrekte Listen und Zeilenumbrueche.

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

# Schnelle Version (minimales Styling)
pandoc -f gfm -s input.md -o output.html

# Self-contained (bettet Bilder/CSS ein)
pandoc -f gfm -s --embed-resources --standalone input.md -o output.html
```

Format-Optionen:

| Option                        | Einsatz                                        |
| ----------------------------- | ---------------------------------------------- |
| `-f gfm`                      | Standard – Listen, Zeilenumbrueche, Tabellen korrekt |
| `-f markdown+hard_line_breaks` | Alle Zeilenumbrueche werden zu `<br>`          |
| `-f commonmark`                | Strikte CommonMark-Konformitaet                |

## HTML fuer Print-to-PDF (ohne LaTeX)

Wenn kein LaTeX verfuegbar ist: HTML erstellen und im Browser als PDF drucken.

```bash
# Print-optimiertes CSS erstellen
cat > /tmp/print-style.css << 'EOF'
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
       max-width: 800px; margin: 0 auto; padding: 2em; line-height: 1.6; }
h1 { border-bottom: 2px solid #333; padding-bottom: 0.3em; }
h2 { border-bottom: 1px solid #ccc; padding-bottom: 0.2em; margin-top: 1.5em; }
h3 { margin-top: 1.2em; }
ul, ol { margin: 0.5em 0 0.5em 1.5em; padding-left: 1em; }
ul { list-style-type: disc; } ol { list-style-type: decimal; }
li { margin: 0.3em 0; }
ul ul, ol ul { list-style-type: circle; margin: 0.2em 0 0.2em 1em; }
table { border-collapse: collapse; width: 100%; margin: 1em 0; }
th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
th { background-color: #f5f5f5; }
code { background-color: #f4f4f4; padding: 2px 6px; border-radius: 3px; }
pre { background-color: #f4f4f4; padding: 1em; overflow-x: auto; border-radius: 5px; }
blockquote { border-left: 4px solid #ddd; margin: 1em 0; padding-left: 1em; color: #666; }
@media print { body { max-width: none; } }
EOF

# Konvertieren mit eingebetteten Styles (immer -f gfm)
pandoc -f gfm input.md -s --toc --toc-depth=2 -c /tmp/print-style.css --embed-resources --standalone -o output.html

# Oeffnen und als PDF drucken (Cmd+P > Als PDF sichern)
open output.html
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
| `--reference-doc=FILE`   | Styling-Vorlage (docx/odt)               |
| `--template=FILE`        | Benutzerdefiniertes Template              |
| `--highlight-style=STYLE`| Syntax-Highlighting (pygments, tango etc.)|
| `--number-sections`      | Abschnitts-Nummerierung                   |
| `-f FORMAT`              | Eingabeformat (falls nicht erkannt)       |
| `-t FORMAT`              | Ausgabeformat (falls nicht erkannt)       |

## Format-Bezeichner

| Format   | Bezeichner                          |
| -------- | ----------------------------------- |
| Markdown | `markdown`, `gfm`, `commonmark`    |
| Word     | `docx`                              |
| PDF      | `pdf`                               |
| HTML     | `html`, `html5`                     |
| LaTeX    | `latex`                             |
| RST      | `rst`                               |
| EPUB     | `epub`                              |
| ODT      | `odt`                               |
| RTF      | `rtf`                               |

## Troubleshooting

### Listen/Zeilen laufen zusammen (HTML)

Ursache: Standard-Markdown fasst aufeinanderfolgende Zeilen als einen Absatz zusammen.

```bash
# Immer -f gfm verwenden
pandoc -f gfm -s input.md -o output.html

# Oder harte Zeilenumbrueche erzwingen
pandoc -f markdown+hard_line_breaks -s input.md -o output.html
```

### PDF-Generierung schlaegt fehl

**"pdflatex not found"** – LaTeX installieren:

```bash
brew install --cask basictex    # Kleiner (~100MB)
brew install --cask mactex-no-gui  # Voll (~4GB)
eval "$(/usr/libexec/path_helper)"
```

**Unicode-Fehler** (Boxzeichnung, Pfeile, Emojis):

```bash
export PATH="/Library/TeX/texbin:$PATH"
pandoc input.md --pdf-engine=xelatex -o output.pdf
```

**Kein LaTeX verfuegbar** – HTML Print-to-PDF Workflow nutzen:

```bash
pandoc input.md -s --toc -o output.html
open output.html
# Dann Cmd+P > Als PDF sichern
```
