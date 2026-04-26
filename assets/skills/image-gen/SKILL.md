---
name: image-gen
description: KI-Bildgenerierung aus Textprompts. Nur auf explizite Anfrage verwenden.
---

# Image Gen Skill

Erzeugt Bilder aus Textprompts via Google Gemini API.

**Vor jeder Generierung dem Anwender diese Auswahl stellen:**

> Welches Bildmodell soll verwendet werden?
> - **Hochwertig** – beste Qualitaet, ~$0.13 pro Bild
> - **Schnell** – gute Qualitaet, ~$0.07 pro Bild

```bash
scripts/image-gen.sh "Prompt" -o bild.png -m hochwertig
scripts/image-gen.sh "Prompt" -o bild.png -m schnell --aspect-ratio 16:9 --resolution 2k
```

## Optionen

- `-m` – `hochwertig` oder `schnell`. Pflichtangabe.
- `-a` – Aspect Ratio: `1:1`, `16:9`, `9:16`, `4:3`, `3:2` (Default: `1:1`)
- `-r` – Aufloesung: `512`, `1k` (Default), `2k`, `4k`

## Prompt-Anleitung

Gemini 3 versteht natuerliche Sprache – keine Keyword-Listen ("4K, masterpiece, trending on ArtStation") verwenden, die bringen nichts. Stattdessen beschreibende Saetze formulieren.

Aufbau: **Motiv + Handlung/Komposition + Ort/Umgebung + Stil/Licht + Atmosphaere**

Beispiel: `Create a dramatic portrait of an astronaut standing on a red sand dune at golden hour, wearing a weathered suit with reflective visor showing a desert horizon, cinematic lighting from the left, shallow depth of field.`
