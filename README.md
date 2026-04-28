# Agentic Collection

Agentenübergreifende Toolsammlung für CLI-basierte AI Agents.

Skills, Agenten und Workflows werden zentral in diesem Repository entwickelt und versioniert. Ein Installer verlinkt sie per Symlink in die jeweiligen Agent-Verzeichnisse, sodass alle Tools eine gemeinsame Quelle, eine gemeinsame Python-Venv und eine zentrale `.env` für API-Keys nutzen. Änderungen wirken sofort, ohne erneute Installation.

## Skills

| Skill                          | 💰  | macOS                                | Linux                   | Windows                 | API-Key                    |
| ------------------------------ | --- | ------------------------------------ | ----------------------- | ----------------------- | -------------------------- |
| **geo**                        | 💰  | `googlemaps` (pip)                   | ❌                      | ❌                      | `GOOGLE_MAPS_API_KEY`      |
| **ocr**                        |     | `tesseract` (brew)                   | ❌                      | ❌                      | –                          |
| **pdf**                        |     | `cpdf`, `qpdf`, `ghostscript` (brew) | ❌                      | ❌                      | –                          |
| **image**                      |     | `imagemagick` (brew)                 | ❌                      | ❌                      | –                          |
| **image-gen**                  | 💰  | –                                    | ❌                      | ❌                      | `GEMINI_IMAGE_GEN_API_KEY` |
| **crawl4ai**                   |     | `crawl4ai` (pip)                     | `crawl4ai` (pip)        | `crawl4ai` (pip)        | –                          |
| **tavily**                     | 💰  | `tavily-cli` (pip)                   | ❌                      | ❌                      | `TAVILY_API_KEY`           |
| **youtube-dlp**                |     | `yt-dlp` (brew)                      | ❌                      | ❌                      | –                          |
| **github**                     |     | `gh` (brew)                          | ❌                      | ❌                      | –                          |
| **iconify**                    |     | –                                    | –                       | –                       | –                          |
| **qr-code**                    |     | `qrencode` (brew)                    | ❌                      | ❌                      | –                          |
| **handelsregister**            |     | `handelsregister` (pip)              | `handelsregister` (pip) | `handelsregister` (pip) | –                          |
| **pandoc**                     |     | `pandoc`, `typst` (brew)             | ❌                      | ❌                      | –                          |
| **folder-picker**              |     | –                                    | ❌                      | ❌                      | –                          |
| **apple-notes-write-only**     |     | –                                    | ❌                      | ❌                      | –                          |
| **apple-reminders-write-only** |     | –                                    | ❌                      | ❌                      | –                          |

## Agenten

| Agent             | Beschreibung                                                                                       |
| ----------------- | -------------------------------------------------------------------------------------------------- |
| **deep-research** | Mehrstufige Tiefenrecherche mit Quellenanalyse, Wissenslücken-Tracking und strukturierter Synthese |

## Permissions

Der Installer verteilt Berechtigungsregeln aus `permissions/rules.json` in die Config-Dateien der Agents, damit häufig genutzte Befehle (Skill-Scripts, lokale CLI-Tools, `gh`-Leseoperationen) nicht jedes Mal manuell bestätigt werden müssen.

| Agent       | Ziel-Config                         | Format                                     |
| ----------- | ----------------------------------- | ------------------------------------------ |
| Claude Code | `~/.claude/settings.json`           | `Bash(pattern)` in `allow[]`               |
| Codex       | `~/.codex/rules/agentic.rules`      | Starlark `prefix_rule()`                   |
| Gemini CLI  | `~/.gemini/settings.json`           | `run_shell_command()` in `tools.allowed[]` |
| OpenCode    | `~/.config/opencode/.opencode.json` | Pattern in `permission.bash{}`             |

## Dependencies

Der Installer (`install.sh`) richtet die `.venv` ein und installiert alle Python-Pakete (pip) automatisch. Homebrew-Tools und API-Keys müssen manuell eingerichtet werden. `./install.sh --check` zeigt den aktuellen Status aller Abhängigkeiten an.

API-Keys werden zentral in `.env` im Repo-Root gepflegt (siehe `.env.example`):

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

Der Installer richtet die Venv ein, installiert Python-Dependencies und erstellt Symlinks in die globalen Agent-Verzeichnisse. Aenderungen an Skills wirken sofort.

Nach der Installation: fehlende Homebrew-Tools installieren und API-Keys in `.env` eintragen.
