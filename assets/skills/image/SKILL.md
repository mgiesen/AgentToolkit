---
name: image
description: Bilder herunterladen, konvertieren, skalieren, zuschneiden, drehen und Metadaten lesen. Unterstuetzte Formate u.a. PNG, JPG, WebP, TIFF, GIF, BMP, SVG.
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "1.0"
platform: all
features:
  - Bilder von URLs herunterladen und in ein anderes Format konvertieren
  - Bilder skalieren (Pixel oder Prozent) und zuschneiden
  - SVG zu PNG mit konfigurierbarem DPI konvertieren
  - Dateigröße ohne sichtbaren Qualitätsverlust optimieren
  - Metadaten (Format, Dimensionen, Dateigröße, Farbraum) auslesen
---

# Image Skill

Bildverarbeitung via ImageMagick und Pillow.

## Subcommands

### download

Bild von URL herunterladen und im gewuenschten Format speichern.

```bash
scripts/image.sh download "https://example.com/photo.png" --output bild.webp
scripts/image.sh download "https://example.com/photo.png" --output bild.jpg --max-size 800 --quality 90
```

### convert

Format konvertieren.

```bash
scripts/image.sh convert input.png --output output.webp
scripts/image.sh convert input.jpg --output output.png
scripts/image.sh convert input.svg --output output.png --density 300
```

### resize

Groesse aendern (Pixel oder Prozent).

```bash
scripts/image.sh resize input.png --output klein.png --size 800x600
scripts/image.sh resize input.png --output halb.png --percent 50
```

### crop

Zuschneiden (BxH+X+Y oder Seitenverhaeltnis).

```bash
scripts/image.sh crop input.png --output cropped.png --geometry 400x300+100+50
scripts/image.sh crop input.png --output cropped.png --gravity center --size 1200x630
```

### rotate

Drehen.

```bash
scripts/image.sh rotate input.png --output gedreht.png --degrees 90
```

### optimize

Dateigroesse reduzieren ohne sichtbaren Qualitaetsverlust.

```bash
scripts/image.sh optimize input.png --output optimiert.png
scripts/image.sh optimize input.jpg --output optimiert.jpg --quality 85
```

### info

Metadaten anzeigen (Format, Dimensionen, Dateigroesse, Farbraum).

```bash
scripts/image.sh info bild.png
```
