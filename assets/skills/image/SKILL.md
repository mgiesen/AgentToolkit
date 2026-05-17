---
name: image
description: Bilder/Thumbnails bearbeiten und kombinieren, von URL herunterladen, Format konvertieren, skalieren, zuschneiden, drehen, optimieren/komprimieren, Metadaten auslesen, Collagen und Bild-Grids erzeugen (NxM-Raster mit konfigurierbarem Hintergrund und Abstand). Unterstuetzte Formate u.a. PNG, JPG, WebP, TIFF, GIF, BMP, SVG.
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "1.3"
platform: all
features:
  - Bilder von URLs herunterladen und in ein anderes Format konvertieren
  - Bilder skalieren (Pixel oder Prozent) und zuschneiden
  - SVG zu PNG mit konfigurierbarem DPI konvertieren
  - Dateigröße ohne sichtbaren Qualitätsverlust optimieren
  - Metadaten (Format, Dimensionen, Dateigröße, Farbraum) auslesen
  - Mehrere Bilder zu Collagen oder NxM-Grids zusammenbauen (Reihe, Spalte, Raster) mit konfigurierbarem Hintergrund und Abstand
---

# Image Skill

Bildverarbeitung und -komposition via ImageMagick und Pillow.

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

### collage

Mehrere Bilder zu einem Bild zusammenbauen — Reihe, Spalte oder NxM-Raster. Nutzt `magick montage`.

Das Seitenverhältnis der einzelnen Zellen wird über `--cell-size WxH` frei bestimmt — z.B. `1080x1080` für 1:1, `1600x900` für 16:9, `1200x1600` für 3:4 Portrait. Inputs mit abweichendem Aspect Ratio werden dabei (Default-Modus `cover`) proportional gecroppt, sodass die Zelle exakt im gewünschten Format erscheint. Ohne `--cell-size` wird das Format des ersten Bildes übernommen.

```bash
# 2x2 Grid: Bilder unterschiedlicher Seitenverhältnisse werden proportional gecroppt
# (cover-Modus, Default) — Zellgröße wird aus dem ersten Bild abgeleitet
scripts/image.sh collage a.jpg b.jpg c.jpg d.jpg --output grid.jpg --tile 2x2 --gap 20

# Quadratische Zellen 1:1 (z.B. für Instagram-Mosaik)
scripts/image.sh collage *.jpg --output square.jpg --tile 3x3 --cell-size 1080x1080

# 16:9-Zellen (Video-Thumbnail-Sheet)
scripts/image.sh collage frame*.png --output sheet.jpg --tile 4x3 --cell-size 1600x900 --gap 8

# Portrait-Zellen 3:4 mit dunklem Hintergrund
scripts/image.sh collage *.jpg --output portrait.jpg --tile 2x2 --cell-size 1200x1600 --background "#111"

# contain-Modus: Bilder werden vollständig sichtbar in die Zelle eingepasst, Padding via background
scripts/image.sh collage a.jpg b.jpg c.jpg --output contain.jpg --tile 3x1 --cell-size 600x600 --fit contain

# Bilder in Originalgrößen (kein Fitting) — sinnvoll wenn alle Inputs bereits gleich groß sind
scripts/image.sh collage a.jpg b.jpg c.jpg --output reihe.jpg --tile 3x1 --fit none

# Untereinander (Spalte) mit schwarzem Hintergrund
scripts/image.sh collage a.jpg b.jpg c.jpg --output spalte.jpg --tile 1x3 --gap 10 --background black
```

Flags:

- `--tile CxR` — Spalten × Reihen (Default: `Nx1`, alle Bilder in einer Reihe)
- `--cell-size WxH` — Zellgröße in Pixel (Default: bei `--fit cover/contain/stretch` aus dem ersten Bild abgeleitet, bei `--fit none` ignoriert)
- `--fit MODE` — wie Bilder in die Zelle eingepasst werden (Default: `cover`):
  - `cover` — proportional skalieren und mittig croppen, sodass die Zelle vollständig ausgefüllt wird (analog zu CSS `object-fit: cover`). Empfohlen für gleichmäßige Grids.
  - `contain` — proportional skalieren, sodass das Bild vollständig in die Zelle passt; ungenutzte Fläche bekommt `--background`.
  - `stretch` — Bild auf exakt `--cell-size` verzerren (kein Aspect-Ratio-Erhalt).
  - `none` — Originalgrößen behalten, keine Anpassung.
- `--gap N` — gleichmäßiger Abstand in Pixel — gilt sowohl zwischen den Bildern als auch am äußeren Rand (Default: `10`)
- `--background COLOR` — Hintergrundfarbe als Name oder Hex (Default: `white`, z.B. `#f5f5f5` oder `transparent`)
