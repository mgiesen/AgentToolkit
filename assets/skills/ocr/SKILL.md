---
name: ocr
description: Extrahiert Text aus Bildern und gescannten PDFs. Nutzt Apple Vision (macOS) mit Tesseract-Fallback (Windows/Linux).
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
