---
name: ocr
version: "1.0"
description: Extrahiert Text aus Bildern und gescannten PDFs. Nutzt Apple Vision (macOS) mit Tesseract-Fallback (Windows/Linux).
requires:
  bin: [tesseract]
features:
  - Text aus Bildern (PNG, JPG, TIFF, BMP) extrahieren — auf macOS via Apple Vision hardwarebeschleunigt
  - Gescannte PDFs in durchsuchbaren Text umwandeln
  - Mehrere Sprachen gleichzeitig erkennen (z.B. de+en)
  - Bilder in durchsuchbare PDFs konvertieren
---

# OCR Skill

Texterkennung aus Bildern (PNG, JPG, TIFF, BMP) und gescannten PDFs.

- **macOS**: Apple Vision Framework (hardwarebeschleunigt, keine Abhaengigkeiten)
- **Fallback**: Tesseract (cross-platform, `brew install tesseract`)

Unterstuetzte Sprachen: `de`, `en`, `fr`, `es`, `it` u.v.m. (30 via Vision, 163 via Tesseract).

## Subcommands

### extract

```bash
scripts/ocr.sh extract bild.png
scripts/ocr.sh extract scan.pdf --lang de
scripts/ocr.sh extract bild.png --lang de+en
```

### to-pdf

Bild via OCR in durchsuchbare PDF konvertieren (nutzt Tesseract).

```bash
scripts/ocr.sh to-pdf scan.png --lang de --output durchsuchbar.pdf
```
