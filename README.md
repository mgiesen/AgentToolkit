# AgentBox

Agentenübergreifende Toolsammlung für CLI-basierte AI Agents.

Skills, Agenten und Workflows werden zentral in diesem Repository entwickelt und versioniert. Ein Installer verlinkt sie per Symlink in die jeweiligen Agent-Verzeichnisse, sodass alle Tools eine gemeinsame Quelle, eine gemeinsame Python-Venv und eine zentrale `.env` für API-Keys nutzen. Änderungen wirken sofort, ohne erneute Installation.

## Skills

| Skill                          | Abhängigkeiten                       | API-Key                    |
| ------------------------------ | ------------------------------------ | -------------------------- |
| **geo**                        | `googlemaps` (pip)                   | `GOOGLE_MAPS_API_KEY`      |
| **ocr**                        | `tesseract` (brew)                   |                            |
| **pdf**                        | `cpdf`, `qpdf`, `ghostscript` (brew) |                            |
| **image**                      | `imagemagick` (brew)                 |                            |
| **image-gen**                  |                                      | `GEMINI_IMAGE_GEN_API_KEY` |
| **crawl4ai**                   | `crawl4ai` (pip)                     |                            |
| **tavily**                     | `tavily-cli` (pip)                   | `TAVILY_API_KEY`           |
| **youtube-dlp**                | `yt-dlp` (brew)                      |                            |
| **github**                     | `gh` (brew)                          |                            |
| **chart**                      | `matplotlib` (pip)                   |                            |
| **iconify**                    |                                      |                            |
| **qr-code**                    | `qrencode` (brew)                    |                            |
| **handelsregister**            | `handelsregister` (pip)              |                            |
| **pandoc**                     | `pandoc`, `typst` (brew)             |                            |
| **folder-picker**              | OS built-in, Linux: `zenity`         |                            |
| **apple-notes-write-only**     | macOS built-in                       |                            |
| **apple-reminders-write-only** | macOS built-in                       |                            |

## Agenten

| Agent             | Beschreibung                                                                                         |
| ----------------- | ---------------------------------------------------------------------------------------------------- |
| **deep-research** | Mehrstufige Tiefenrecherche mit Quellenanalyse, Wissenslücken-Tracking und strukturierter Synthese   |
| **report-writer** | Strukturiert Rechercheergebnisse in wissenschaftlich konsistente Berichte und erzeugt PDF via pandoc |

## Permissions

Der Installer verteilt Berechtigungsregeln aus `assets/permissions/rules.json` in die Config-Dateien der Agents, damit häufig genutzte Befehle (Skill-Scripts, lokale CLI-Tools, `gh`-Leseoperationen) nicht jedes Mal manuell bestätigt werden müssen.

| Agent       | Ziel-Config                         | Format                                     |
| ----------- | ----------------------------------- | ------------------------------------------ |
| Claude Code | `~/.claude/settings.json`           | `Bash(pattern)` in `allow[]`               |
| Codex       | `~/.codex/rules/agentic.rules`      | Starlark `prefix_rule()`                   |
| Gemini CLI  | `~/.gemini/settings.json`           | `run_shell_command()` in `tools.allowed[]` |
| OpenCode    | `~/.config/opencode/.opencode.json` | Pattern in `permission.bash{}`             |

## Dependencies

Der Installer (`scripts/install.sh`) richtet die `.venv` ein, installiert alle Python-Pakete (pip) und Homebrew-Tools (via `Brewfile`) automatisch. Nur API-Keys müssen manuell eingetragen werden.

API-Keys werden zentral in `.env` im Repo-Root gepflegt (siehe `.env.example`):

| Key                        | Skill     | Bezugsquelle                                                              |
| -------------------------- | --------- | ------------------------------------------------------------------------- |
| `GOOGLE_MAPS_API_KEY`      | geo       | [Google Cloud Console](https://console.cloud.google.com/apis/credentials) |
| `GEMINI_IMAGE_GEN_API_KEY` | image-gen | [Google AI Studio](https://aistudio.google.com/apikey)                    |
| `TAVILY_API_KEY`           | tavily    | [Tavily Dashboard](https://app.tavily.com)                                |

## Installation

```bash
git clone https://github.com/mgiesen/AgentBox.git && cd AgentBox
./scripts/install.sh              # Interaktiver Installer (TUI)
```

Oder direkt:

```bash
./scripts/install.sh --all        # Alle Skills für alle Agents installieren
./scripts/install.sh --status     # Installationsstatus anzeigen
./scripts/install.sh --uninstall  # Alle Skills deinstallieren
./scripts/install.sh --check      # Dependencies prüfen und installieren (Venv, Brew)
```

Der Installer richtet die Venv ein, installiert Python- und Brew-Dependencies und erstellt Symlinks in die globalen Agent-Verzeichnisse. Änderungen an Skills wirken sofort.

Nach der Installation: API-Keys in `.env` eintragen.

## Roadmap: Sandbox-Modus (Docker)

Das Repo soll langfristig zwei Nutzungsmodi bieten:

| Modus                 | Zielgruppe                         | Setup                                                                                   |
| --------------------- | ---------------------------------- | --------------------------------------------------------------------------------------- |
| **Host-Installation** | Erfahrene Entwickler               | `install.sh` verlinkt Skills/Agents per Symlink in die lokalen Agent-Verzeichnisse      |
| **Sandbox (Docker)**  | Einsteiger, Unternehmensumgebungen | Vorkonfiguriertes Docker-Image mit allen Agents, Skills und Dependencies out of the box |

### Idee

Ein Docker-Image, das alle vier Agentensysteme (Claude Code, Codex, Gemini CLI, OpenCode) inklusive Skills, Agents und Dependencies vorinstalliert enthält. User pullen das Image, hinterlegen ihre API-Keys/Credentials und können direkt loslegen — ohne lokale Installation.

### Sicherheitskonzept

- Der Container läuft unprivilegiert
- Ein einzelner Ordner (z.B. `workspace/`) wird als Volume gemountet und ist der einzige beschreibbare Ort — Arbeitsverzeichnis für Input und Output
- Der Agent hat keinen Zugriff auf das Host-Filesystem, SSH-Keys, Browser-Credentials oder andere Repos
- Netzwerk-Egress wird auf die benötigten API-Endpunkte beschränkt
- Selbst bei Prompt Injection oder Fehlbedienung kann der Agent nicht über den gemounteten Ordner hinaus operieren — die Isolation wird auf OS-Ebene erzwungen

### Distribution

Das Image wird über die GitHub Container Registry bereitgestellt. Angedachter Workflow:

```bash
docker pull ghcr.io/mgiesen/agentbox:latest
docker run --read-only --tmpfs /tmp -v ./dir:/workspace -it agentbox
```

### Offene Punkte

- Hosting der API-Keys: Docker Secrets, `.env`-Mount oder interaktive Eingabe beim Start
- Ein Image für alle Agents vs. ein Base-Image mit Agent-spezifischen Varianten
- Kennzeichnung von Skills, die im Container nicht verfügbar sind (z.B. Apple Notes, Folder Picker)
- Egress-Whitelist für erlaubte API-Endpunkte
