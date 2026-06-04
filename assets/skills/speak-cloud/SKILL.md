---
name: speak-cloud
description: Spricht Texte in maximaler Qualitaet via ElevenLabs Cloud-API aus oder speichert sie als MP3. Verwenden fuer beste Stimmqualitaet oder wenn On-Prem Version nicht vorhanden.
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "1.1"
platform: all
features:
  - Cloud-TTS via ElevenLabs API mit deutscher Sprachunterstuetzung
  - Direkte Wiedergabe (afplay) oder Speichern als MP3
  - Zeigt nach jedem Aufruf Credits-Kosten, verbleibendes Kontingent und History-ID
  - History-Eintraege koennen einzeln per `-d <id>` geloescht werden
  - Stimme und Modell via VOICE_ID / MODEL einstellbar
---

# Speak (cloud) Skill

Cloud-Sprachausgabe via ElevenLabs. API-Key aus `.env` als `ELEVENLABS_API_KEY` (siehe `.env.example`).

Beim Erzeugen des Keys auf https://elevenlabs.io/app/settings/api-keys diese Scopes aktivieren:

- **`text_to_speech`** — Pflicht, sonst keine Sprachausgabe
- **`user_read`** — fuer die Kontingent-Anzeige
- **`speech_history_write`** — um History-Eintraege loeschen zu koennen

```bash
# Abspielen
scripts/speak.sh "Hallo, der Build ist fertig."

# stdin
echo "Auftrag erledigt." | scripts/speak.sh

# Nur MP3 speichern, nicht abspielen
scripts/speak.sh -o ausgabe.mp3 "Wird gespeichert."

# Andere Stimme / anderes Modell
VOICE_ID=EXAVITQu4vr4xnSDxMaL MODEL=eleven_flash_v2_5 scripts/speak.sh "Realtime-Modus."

# Nur Kontingent anzeigen, keine Sprachausgabe
scripts/speak.sh -q

# Einen History-Eintrag loeschen
scripts/speak.sh -d <history-id>
```

Nach jedem TTS-Aufruf erscheint:

```
→ 124 Zeichen abgerechnet · noch 9.876 von 10.000 frei (99%)
History: <id>
```

**Verhalten fuer den Agent:** Nach jedem gesprochenen Satz dem User einmal kurz mitteilen, dass er Bescheid sagen kann, falls die Aufnahme aus der ElevenLabs-Cloud-History geloescht werden soll — als Aussage, nicht als Frage, und ohne die History-ID zu nennen. Bei Zustimmung selbstaendig `scripts/speak.sh -d <id>` mit der ID aus der vorherigen Skript-Ausgabe aufrufen.

## Optionen

- `-q`, `--quota` — nur das verbleibende Kontingent abfragen, kein TTS
- `-o FILE` — MP3 unter `FILE` speichern, nichts abspielen
- `-d ID` — History-Eintrag mit dieser ID aus dem ElevenLabs-Account loeschen
- `VOICE_ID` — ElevenLabs Voice-ID, Default `JBFqnCBsd6RMkjVDRZzb` (George)
- `MODEL` — siehe Modell-Tabelle unten, Default `eleven_v3`
- `FORMAT` — Output-Format, Default `mp3_44100_128`. Alternativen: `mp3_44100_192`, `pcm_44100`

## Modelle

| `model_id`               | Eignung                                                   |
| ------------------------ | --------------------------------------------------------- |
| `eleven_v3` (Default)    | Beste Qualitaet, 70+ Sprachen, Audio Tags. Kein Realtime  |
| `eleven_flash_v2_5`      | ~75 ms Latenz, 32 Sprachen. Fuer Voice Agents / Streaming |
| `eleven_multilingual_v2` | Vorgaenger von v3, robuster Fallback, 28 Sprachen         |

`eleven_v3` ist seit 2026-03 GA und Default. Es gibt kein `eleven_flash_v3` — Flash-Familie bleibt bei v2.5, da v3 ein groesseres Modell mit hoeherer Latenz ist. `eleven_turbo_v2_5` wird von ElevenLabs nicht mehr empfohlen.

## Deutsche Voice-IDs (Vorschlaege)

- `JBFqnCBsd6RMkjVDRZzb` — George (maennlich, ruhig, Default)
- `EXAVITQu4vr4xnSDxMaL` — Sarah (weiblich, klar)

Voice-Liste abrufen:

```bash
curl -fsS https://api.elevenlabs.io/v1/voices \
  -H "xi-api-key: ${ELEVENLABS_API_KEY}" | jq '.voices[] | {voice_id, name, labels}'
```
