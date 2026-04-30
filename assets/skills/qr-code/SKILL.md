---
name: qr-code
version: "1.0"
description: QR-Codes erzeugen, anzeigen oder exportieren (PNG, SVG, Terminal/UTF8). Wandelt URLs, Texte oder Daten in scannbare QR-Codes um. Nutzt qrencode.
requires:
  bin: [qrencode]
features:
  - QR-Code aus URL oder beliebigem Text als PNG oder SVG exportieren
  - QR-Code direkt im Terminal als UTF8-Grafik anzeigen
  - Modulgröße und Fehlerkorrekturlevel (L/M/Q/H) einstellen
---

# QR-Code Skill

```bash
# PNG (Standard)
qrencode -o qr.png "https://example.com"

# SVG
qrencode -t SVG -o qr.svg "https://example.com"

# Terminal-Vorschau
qrencode -t UTF8 "https://example.com"

# Groesse anpassen (Pixelgroesse pro Modul)
qrencode -o qr.png -s 10 "https://example.com"

# Fehlerkorrektur (L/M/Q/H, Default: L)
qrencode -o qr.png -l H "https://example.com"
```
