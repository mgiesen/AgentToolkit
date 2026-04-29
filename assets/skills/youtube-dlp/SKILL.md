---
name: youtube-dlp
description: "YouTube als Recherche- und Wissensquelle mit yt-dlp nutzen: Metadaten, Formate, Untertitel, automatische Transkripte, Suchergebnisse und Playlists ressourcenschonend abrufen. Verwenden, wenn Agenten Inhalte von YouTube analysieren, zitierfaehige Kontextdaten sammeln, Transkripte extrahieren oder nur explizit angeforderte Medien herunterladen sollen."
---

# YouTube-dlp Skill

YouTube-Inhalte ueber `yt-dlp` als lokale Ressource erschliessen. Standardmaessig zuerst Metadaten und Transkripte abrufen; Video- oder Audiodownloads nur ausfuehren, wenn der Nutzer das explizit verlangt oder die Rechte klar sind.

## Voraussetzungen

- `yt-dlp` via Homebrew, pip oder offizieller Binary
- Optional `ffmpeg` fuer Audio-Extraktion, Remuxing und Subtitle-Konvertierung
- Optional Browser-Cookies fuer loginpflichtige Inhalte

## Grundregel

Arbeite mit der leichtesten Quelle, die die Aufgabe loest:

1. `info` fuer Titel, Kanal, Datum, Dauer, Beschreibung und URL.
2. `subs` fuer verfuegbare Untertitelsprachen.
3. `transcript` fuer Textanalyse, Zusammenfassungen, Extraktion und Zitate.
4. `playlist` oder `search` fuer Quellenauswahl ohne Medien-Download.
5. `audio` oder `video` nur bei ausdruecklichem Download-Auftrag.

## Subcommands

Alle Befehle ueber `scripts/youtube-dlp.sh <subcommand>`.

### info

Metadaten eines Videos abrufen, ohne Medien zu laden.

```bash
scripts/youtube-dlp.sh info "https://www.youtube.com/watch?v=VIDEO_ID"
scripts/youtube-dlp.sh info "https://www.youtube.com/watch?v=VIDEO_ID" --json
```

### formats

Verfuegbare Audio-/Videoformate anzeigen.

```bash
scripts/youtube-dlp.sh formats "https://www.youtube.com/watch?v=VIDEO_ID"
```

### subs

Verfuegbare manuelle und automatische Untertitel anzeigen.

```bash
scripts/youtube-dlp.sh subs "https://www.youtube.com/watch?v=VIDEO_ID"
```

### transcript

Transkript aus Untertiteln extrahieren. Ohne Modus wird zuerst offizieller Untertitel versucht, danach automatische Untertitel.

```bash
scripts/youtube-dlp.sh transcript "https://www.youtube.com/watch?v=VIDEO_ID" --lang de --output transcript.txt
scripts/youtube-dlp.sh transcript "https://www.youtube.com/watch?v=VIDEO_ID" --lang en --auto --format srt --output transcript.srt
scripts/youtube-dlp.sh transcript "https://www.youtube.com/watch?v=VIDEO_ID" --lang "de,en" --format txt
```

### search

YouTube-Suchergebnisse flach als Quellenliste abrufen.

```bash
scripts/youtube-dlp.sh search "query terms" --limit 5
scripts/youtube-dlp.sh search "query terms" --limit 10 --json
```

### playlist

Playlist-Inhalte flach auslesen, ohne Videos herunterzuladen.

```bash
scripts/youtube-dlp.sh playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID" --limit 20
scripts/youtube-dlp.sh playlist "https://www.youtube.com/playlist?list=PLAYLIST_ID" --json
```

### thumbnail

Video-Thumbnail im Originalformat (meist webp) herunterladen.

```bash
scripts/youtube-dlp.sh thumbnail "https://www.youtube.com/watch?v=VIDEO_ID" --output thumb.webp
```

### audio

Audio nur herunterladen, wenn der Nutzer es explizit verlangt.

```bash
scripts/youtube-dlp.sh audio "https://www.youtube.com/watch?v=VIDEO_ID" --format m4a --output-dir ./downloads
scripts/youtube-dlp.sh audio "https://www.youtube.com/watch?v=VIDEO_ID" --format mp3
```

### video

Video nur herunterladen, wenn der Nutzer es explizit verlangt.

```bash
scripts/youtube-dlp.sh video "https://www.youtube.com/watch?v=VIDEO_ID" --preset mp4 --output-dir ./downloads
```

## Authentifizierung

Keine Tokens erforderlich. Bei loginpflichtigen, privaten oder altersbeschraenkten Videos Cookies lokal aus dem Browser nutzen:

```bash
scripts/youtube-dlp.sh transcript "URL" --cookies-from-browser safari
scripts/youtube-dlp.sh info "URL" --cookies-from-browser chrome
```

Cookies nie in Dateien persistieren, wenn es nicht noetig ist. Keine Passwoerter oder Tokens in Prompts, Logs oder Ausgaben schreiben.

## Recht und Sicherheit

Beachte YouTube-Nutzungsbedingungen und Urheberrecht. Fuer Agentenarbeit gilt:

- Transkripte fremder Videos bevorzugt nur zur privaten Analyse oder mit Erlaubnis verwenden.
- Keine fremden Transkripte, Audios oder Videos veroeffentlichen, weitergeben oder in Datensaetze aufnehmen, wenn Rechte nicht geklaert sind.
- Keine DRM-, Paywall- oder Zugangsbeschraenkungen umgehen.
- Quellen-URL, Titel, Kanal und Abrufdatum in Arbeitsergebnissen mitfuehren, wenn YouTube als Quelle genutzt wird.
