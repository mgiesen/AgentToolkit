# Agentic Collection

Persoenliche Werkzeugsammlung fuer CLI-basierte AI Agents.

`agents/` enthaelt die proprietaeren Strukturen fuer die gaengigen Agentensysteme (Claude Code, Codex, OpenCode). Jeder Agent-Ordner wird direkt als Arbeitsverzeichnis gestartet und enthaelt die tool-spezifischen Konfigurationen. Portable Assets wie Skills werden per Symlink aus `assets/` eingebunden, um Redundanz zu vermeiden.

## Skills

| Skill             | Faehigkeiten                                              | Dependencies                           | Voraussetzungen        |
| ----------------- | --------------------------------------------------------- | -------------------------------------- | ---------------------- |
| **geo**           | Entfernungen, Fahrzeiten, Geocoding, POI-Suche, Routing   | Google Maps API (pip, via .venv)       | API-Key in `.env`      |
| **ocr**           | Texterkennung aus Bildern und gescannten PDFs             | Apple Vision (macOS), Tesseract (brew) | –                      |
| **pdf**           | Merge, Split, Compress, Encrypt/Decrypt, Seitenextraktion | cpdf, qpdf, Ghostscript (brew)         | –                      |
| **image**         | Download, Konvertierung, Resize, Crop, Rotate, Optimize   | ImageMagick (brew)                     | –                      |
| **crawl4ai**      | Web-Scraping, Markdown-Extraktion aus Webseiten           | crawl4ai (pipx)                        | –                      |
| **youtube-dlp**   | Metadaten, Transkripte, Untertitel, Suchergebnisse        | yt-dlp (brew)                          | –                      |
| **github**        | GitHub-Repos, Issues, PRs, Actions lesen                  | gh CLI (brew)                          | Schreibend nur mit Freigabe |
| **image-gen**     | KI-Bildgenerierung aus Textprompts (Nano Banana)          | Google Gemini API (curl)               | API-Key in `.env`      |
| **qr-code**       | QR-Codes erzeugen (PNG, SVG, Terminal)                    | qrencode (brew)                        | –                      |
| **folder-picker** | Interaktive Ordnerauswahl per Finder-Dialog               | osascript (macOS built-in)             | Nur macOS              |


## Struktur

```
assets/                     Portable Assets (Skills, kuenftig weitere)
  skills/                   SKILL.md-Standard, von allen Agents nutzbar
agents/                     Proprietaere Agent-Konfigurationen
  Claude Code/              CLAUDE.md, .claude/ (agents, commands, hooks)
  Codex/                    AGENTS.md, .codex/ (agents, config)
  OpenCode/                 (geplant)
update-agents.sh            Symlinks aus assets/ in alle Agent-Ordner erstellen
.env                        API-Keys (gitignored)
.env.example                Dokumentiert benoetigte Keys
```

## Setup

```bash
git clone <repo> && cd Agentic-Collection
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
./update-agents.sh        # Skill-Symlinks erstellen
cp .env.example .env      # API-Keys eintragen
```

Danach in den gewuenschten Agent-Ordner wechseln und starten:

```bash
cd agents/Claude\ Code && claude
```

## API Keys

Zentral in `.env` im Repo-Root. Skills laden diese automatisch. Neue Keys in `.env.example` dokumentieren.
