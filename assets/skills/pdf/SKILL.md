---
name: pdf
description: PDF-Operationen – Merge, Split, Seiten extrahieren, komprimieren, verschluesseln, Metadaten lesen. Nutzt cpdf, qpdf und Ghostscript.
---

# PDF Skill

PDF-Manipulation ueber cpdf, qpdf und Ghostscript.

## Voraussetzungen

- `cpdf`, `qpdf`, `ghostscript` (via Homebrew)

## Subcommands

Alle Befehle ueber `scripts/pdf.sh <subcommand>`.

### merge

Mehrere PDFs zusammenfuehren.

```bash
scripts/pdf.sh merge a.pdf b.pdf c.pdf --output combined.pdf
```

### split

PDF in einzelne Seiten aufteilen.

```bash
scripts/pdf.sh split dokument.pdf --output-dir ./seiten/
```

### extract

Bestimmte Seiten extrahieren.

```bash
scripts/pdf.sh extract dokument.pdf --pages 1-3,7,12 --output auszug.pdf
```

### compress

PDF-Dateigroesse reduzieren.

```bash
scripts/pdf.sh compress gross.pdf --output klein.pdf
scripts/pdf.sh compress gross.pdf --output klein.pdf --quality screen
```

Quality-Stufen: `screen` (72dpi), `ebook` (150dpi), `printer` (300dpi), `prepress` (300dpi, Farberhalt).

### encrypt

PDF mit Passwort schuetzen.

```bash
scripts/pdf.sh encrypt dokument.pdf --password geheim --output geschuetzt.pdf
```

### decrypt

Passwortschutz entfernen.

```bash
scripts/pdf.sh decrypt geschuetzt.pdf --password geheim --output offen.pdf
```

### info

Metadaten und Seitenanzahl anzeigen.

```bash
scripts/pdf.sh info dokument.pdf
```
