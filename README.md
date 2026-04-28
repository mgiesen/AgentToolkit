# Agentic Collection

Persönliche Toolsammlung für CLI-basierte AI Agents (Claude Code, Codex, Gemini CLI, OpenCode).

Assets werden hier entwickelt und versioniert. Der Installer verlinkt sie global in die Agent-Verzeichnisse, sodass sie in jedem Projekt verfügbar sind.

## Skills

| Skill                      | 💰  | Kompatibilität | Fähigkeiten                                               | Typischer Prompt                                                     |
| -------------------------- | --- | -------------- | --------------------------------------------------------- | -------------------------------------------------------------------- |
| **geo**                    | ✓   | W M L          | Entfernungen, Fahrzeiten, Geocoding, POI-Suche, Routing   | „Wie weit ist es von Krefeld nach München mit dem Auto?"             |
| **ocr**                    |     | W M L          | Texterkennung aus Bildern und gescannten PDFs             | „Extrahiere den Text aus diesem gescannten Dokument."                |
| **pdf**                    |     | W M L          | Merge, Split, Compress, Encrypt/Decrypt, Seitenextraktion | „Fasse diese drei PDFs zu einer Datei zusammen."                     |
| **image**                  |     | W M L          | Download, Konvertierung, Resize, Crop, Rotate, Optimize   | „Konvertiere alle PNGs im Ordner nach WebP und reduziere auf 800px." |
| **image-gen**              | ✓   | W M L          | KI-Bildgenerierung aus Textprompts (Nano Banana)          | „Generiere ein Bild von einer Katze auf einem Skateboard."           |
| **crawl4ai**               |     | W M L          | Web-Scraping, Markdown-Extraktion, strukturierte Daten    | „Extrahiere alle Produktpreise von dieser Webseite als JSON."        |
| **tavily**                 | ✓   | W M L          | Breite Quellenfindung und Deep Research mit Zitaten       | „Recherchiere den aktuellen Stand von AI Coding Agents mit Quellen." |
| **youtube-dlp**            |     | W M L          | Metadaten, Transkripte, Untertitel, Suchergebnisse        | „Hole mir das Transkript von diesem YouTube-Video."                  |
| **github**                 |     | W M L          | GitHub-Repos, Issues, PRs, Actions lesen                  | „Zeig mir die offenen Issues von diesem Repo."                       |
| **iconify**                |     | W M L          | SVG-Icons aus Iconify suchen, ranken und herunterladen    | „Finde passende SVG-Icons für diese Toolbar."                        |
| **qr-code**                |     | W M L          | QR-Codes erzeugen (PNG, SVG, Terminal)                    | „Erstelle einen QR-Code für diese URL als PNG."                      |
| **handelsregister**        |     | W M L          | Unternehmenssuche im deutschen Handelsregister            | „Suche die Handelsregisterdaten der Siemens AG."                     |
| **pandoc**                 |     | W M L          | Dokumente erstellen und konvertieren (PDF, Word, PPTX, EPUB, HTML) mit professionellen Vorlagen | „Erstelle aus diesem Markdown ein PDF im Report-Layout."             |
| **folder-picker**          |     | M              | Interaktive Ordnerauswahl per Finder-Dialog               | „Lass mich einen Zielordner im Finder auswählen."                    |
| **apple-notes-write-only** |     | M              | Neue Apple Notes erstellen (kein Lesen/Löschen)           | „Erstelle eine Notiz mit dem Titel Einkaufsliste."                   |
| **apple-reminders-write-only** | | M              | Neue Apple Erinnerungen erstellen (kein Lesen/Löschen)    | „Erinnere mich morgen um 14 Uhr an den Zahnarzt."                    |

> **W** = Windows · **M** = macOS · **L** = Linux

## Permissions

Der Installer verteilt Berechtigungsregeln aus `permissions/rules.json` in die Config-Dateien der Agents, damit häufig genutzte Befehle (Skill-Scripts, lokale CLI-Tools, `gh`-Leseoperationen) nicht jedes Mal manuell bestätigt werden müssen.

| Agent       | Ziel-Config                         | Format                                     |
| ----------- | ----------------------------------- | ------------------------------------------ |
| Claude Code | `~/.claude/settings.json`           | `Bash(pattern)` in `allow[]`               |
| Codex       | `~/.codex/rules/agentic.rules`      | Starlark `prefix_rule()`                   |
| Gemini CLI  | `~/.gemini/settings.json`           | `run_shell_command()` in `tools.allowed[]` |
| OpenCode    | `~/.config/opencode/.opencode.json` | Pattern in `permission.bash{}`             |

Permissions können im Installer unabhängig von Skills verwaltet werden (Menüpunkte 3 + 4).

## Systemvoraussetzungen

| Voraussetzung | Zweck                                                                                                  | Prüfung             |
| ------------- | ------------------------------------------------------------------------------------------------------ | ------------------- |
| **macOS**     | Mehrere Skills nutzen macOS-APIs (Apple Vision, osascript). CLI Tools werden via Homebrew installiert. | `uname` → Darwin    |
| **Python 3**  | Venv für alle Python-basierten Skills.                                                                 | `python3 --version` |
| **Homebrew**  | Installiert CLI-Abhängigkeiten (siehe unten).                                                          | `brew --version`    |
| **Git**       | Repo klonen, pip-Pakete von GitHub installieren.                                                       | `git --version`     |

## Dependencies pro Skill

Der Installer (`install.sh`) richtet die `.venv` ein und installiert alle Python-Pakete automatisch. Homebrew-Tools und API-Keys müssen manuell eingerichtet werden.

`./install.sh --check` zeigt den aktuellen Status aller Abhängigkeiten an.

| Skill                      | Automatisch via .venv     | Manuell via Homebrew                 | API-Key in `.env`          |
| -------------------------- | ------------------------- | ------------------------------------ | -------------------------- |
| **geo**                    | googlemaps, python-dotenv | –                                    | `GOOGLE_MAPS_API_KEY`      |
| **ocr**                    | –                         | `brew install tesseract`             | –                          |
| **pdf**                    | –                         | `brew install cpdf qpdf ghostscript` | –                          |
| **image**                  | –                         | `brew install imagemagick`           | –                          |
| **image-gen**              | –                         | –                                    | `GEMINI_IMAGE_GEN_API_KEY` |
| **crawl4ai**               | crawl4ai                  | `pipx install crawl4ai`              | –                          |
| **tavily**                 | tavily-cli                | –                                    | `TAVILY_API_KEY`           |
| **youtube-dlp**            | –                         | `brew install yt-dlp`                | –                          |
| **github**                 | –                         | `brew install gh`                    | –                          |
| **iconify**                | –                         | –                                    | –                          |
| **pandoc**                 | –                         | `brew install pandoc typst`          | –                          |
| **qr-code**                | –                         | `brew install qrencode`              | –                          |
| **handelsregister**        | handelsregister           | –                                    | –                          |
| **folder-picker**          | –                         | – (macOS built-in)                   | –                          |
| **apple-notes-write-only** | –                         | – (macOS built-in)                   | –                          |
| **apple-reminders-write-only** | –                     | – (macOS built-in)                   | –                          |

### API-Keys

Skills mit externen APIs benötigen Keys in `.env` im Repo-Root (siehe `.env.example`):

| Key                        | Skill     | Bezugsquelle                                                              |
| -------------------------- | --------- | ------------------------------------------------------------------------- |
| `GOOGLE_MAPS_API_KEY`      | geo       | [Google Cloud Console](https://console.cloud.google.com/apis/credentials) |
| `GEMINI_IMAGE_GEN_API_KEY` | image-gen | [Google AI Studio](https://aistudio.google.com/apikey)                    |
| `TAVILY_API_KEY`           | tavily    | [Tavily Dashboard](https://app.tavily.com)                                |

## Installation

```bash
git clone https://github.com/mgiesen/Agentic-Collection.git && cd Agentic-Collection
./install.sh              # Interaktiver Installer (TUI)
```

Oder direkt:

```bash
./install.sh --all        # Alle Skills für alle Agents installieren
./install.sh --status     # Installationsstatus anzeigen
./install.sh --uninstall  # Alle Skills deinstallieren
./install.sh --check      # Dependencies prüfen (Venv, CLI Tools)
```

Der Installer richtet die Venv ein, installiert Python-Dependencies und erstellt Symlinks in die globalen Agent-Verzeichnisse. Änderungen an Skills wirken sofort.

Nach der Installation: fehlende Homebrew-Tools installieren und API-Keys in `.env` eintragen.
