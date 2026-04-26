# Agentic Collection

Persoenliche Toolsammlung fuer CLI-basierte AI Agents (Claude Code, Codex, Gemini CLI, OpenCode).

Assets werden hier entwickelt und versioniert. Der Installer verlinkt sie global in die Agent-Verzeichnisse, sodass sie in jedem Projekt verfuegbar sind.

## Skills

| Skill             | Faehigkeiten                                              | Dependencies                           | Voraussetzungen        |
| ----------------- | --------------------------------------------------------- | -------------------------------------- | ---------------------- |
| **geo**           | Entfernungen, Fahrzeiten, Geocoding, POI-Suche, Routing   | Google Maps API (pip, via .venv)       | API-Key in `.env`      |
| **ocr**           | Texterkennung aus Bildern und gescannten PDFs             | Apple Vision (macOS), Tesseract (brew) | –                      |
| **pdf**           | Merge, Split, Compress, Encrypt/Decrypt, Seitenextraktion | cpdf, qpdf, Ghostscript (brew)         | –                      |
| **image**         | Download, Konvertierung, Resize, Crop, Rotate, Optimize   | ImageMagick (brew)                     | –                      |
| **image-gen**     | KI-Bildgenerierung aus Textprompts (Nano Banana)          | Google Gemini API (curl)               | API-Key in `.env`      |
| **crawl4ai**      | Web-Scraping, Markdown-Extraktion, strukturierte Daten    | crawl4ai (pipx + .venv)               | –                      |
| **youtube-dlp**   | Metadaten, Transkripte, Untertitel, Suchergebnisse        | yt-dlp (brew)                          | –                      |
| **github**        | GitHub-Repos, Issues, PRs, Actions lesen                  | gh CLI (brew)                          | Schreibend nur mit Freigabe |
| **qr-code**       | QR-Codes erzeugen (PNG, SVG, Terminal)                    | qrencode (brew)                        | –                      |
| **folder-picker** | Interaktive Ordnerauswahl per Finder-Dialog               | osascript (macOS built-in)             | Nur macOS              |

## Installation

```bash
git clone https://github.com/mgiesen/Agentic-Collection.git && cd Agentic-Collection
./install.sh              # Interaktiver Installer (TUI)
```

Oder direkt:

```bash
./install.sh --all        # Alle Skills fuer alle Agents installieren
./install.sh --status     # Installationsstatus anzeigen
./install.sh --uninstall  # Alle Skills deinstallieren
./install.sh --check      # Dependencies pruefen (Venv, CLI Tools)
```

Der Installer richtet die Venv ein, installiert Python-Dependencies und erstellt Symlinks in die globalen Agent-Verzeichnisse. Aenderungen an Skills wirken sofort.

Nach der Installation: API-Keys in `.env` eintragen (siehe `.env.example`).

## API Keys

Zentral in `.env` im Repo-Root. Skills laden diese automatisch. Benoetigte Keys siehe `.env.example`.
