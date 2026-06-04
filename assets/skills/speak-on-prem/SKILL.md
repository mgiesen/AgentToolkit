---
name: speak-on-prem
description: Spricht Texte offline auf Deutsch lokal via Piper TTS aus dem Lautsprecher oder speichert sie als WAV. Verwenden wenn keine Internetverbindung, keine API-Kosten und ausreichend lokale Rechenleistung. Fuer max. Qualitaet oder schwache Hardware stattdessen speak-cloud.
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "2.0"
platform: [macOS]
features:
  - Lokale, offline Sprachausgabe auf Deutsch (Piper TTS, ONNX)
  - Direkte Wiedergabe ueber Lautsprecher (afplay) oder Speichern als WAV
  - Tempo regelbar via SPEED (kleiner = schneller)
  - Voice-Modell wird bei Bedarf nach ~/.cache/piper-voices/ geladen
---

# Speak (on-prem) Skill

Lokale deutsche Sprachausgabe via Piper TTS. Voice liegt unter `~/.cache/piper-voices/`.

```bash
# Abspielen
scripts/speak.sh "Hallo, der Build ist fertig."

# Tempo: <1.0 schneller, >1.0 langsamer
SPEED=0.85 scripts/speak.sh "Etwas schneller."

# stdin
echo "Auftrag erledigt." | scripts/speak.sh

# Nur WAV erzeugen, nicht abspielen
scripts/speak.sh -o ausgabe.wav "Wird gespeichert."
```

## Optionen

- `-o FILE` — WAV unter `FILE` speichern, nichts abspielen
- `SPEED` — Length-Scale, Default `1.0`. `0.85` etwas schneller, `1.2` langsamer

## Weitere Stimmen nachladen

Stimmen-Katalog: https://huggingface.co/rhasspy/piper-voices/tree/main/de/de_DE — `.onnx` + `.onnx.json` nach `~/.cache/piper-voices/` legen und Pfad in `scripts/speak.sh` anpassen.
