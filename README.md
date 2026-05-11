# AgentToolkit

Agentenübergreifende Toolsammlung für CLI-basierte AI Agents.

Skills, Agenten und Workflows werden zentral in diesem Repository entwickelt und versioniert. Ein Installer verlinkt sie per Symlink in die jeweiligen Agent-Verzeichnisse, sodass alle Tools eine gemeinsame Quelle, eine gemeinsame Python-Venv und eine zentrale `.env` für API-Keys nutzen. Änderungen wirken sofort, ohne erneute Installation.

## Skills

18 Skills für Apple-Integration, Web-Recherche, Dokumentenkonvertierung, Bildverarbeitung, Geo-Routing und mehr. Vollständige Übersicht inkl. Features, Abhängigkeiten und benötigter Binaries: [docs/skills.md](docs/skills.md).

## Agenten

2 Subagenten für mehrstufige Recherche und wissenschaftliche Berichtserstellung. Details: [docs/agents.md](docs/agents.md).

## Permissions

Der Installer verteilt Berechtigungsregeln aus `assets/permissions/rules.json` in die Config-Dateien der Agents, damit häufig genutzte Befehle (Skill-Scripts, lokale CLI-Tools, `gh`-Leseoperationen) nicht jedes Mal manuell bestätigt werden müssen.

| Agent       | Ziel-Config                         | Format                                     |
| ----------- | ----------------------------------- | ------------------------------------------ |
| Claude Code | `~/.claude/settings.json`           | `Bash(pattern)` in `allow[]`               |
| Codex       | `~/.codex/rules/agentic.rules`      | Starlark `prefix_rule()`                   |
| Gemini CLI  | `~/.gemini/settings.json`           | `run_shell_command()` in `tools.allowed[]` |
| OpenCode    | `~/.config/opencode/.opencode.json` | Pattern in `permission.bash{}`             |

## Installation

```bash
git clone https://github.com/mgiesen/AgentToolkit.git && cd AgentToolkit
python3 scripts/install.py              # Interaktiver Installer (TUI)
```

Oder direkt:

```bash
python3 scripts/install.py --all        # Alles für alle Agents installieren
python3 scripts/install.py --status     # Installationsstatus anzeigen
python3 scripts/install.py --uninstall  # Alles deinstallieren
```

Cross-Platform: läuft auf macOS, Linux und Windows (Windows benötigt Developer-Mode oder Admin-Rechte für Symlinks). Der Installer setzt Symlinks für Skills und Agents, schreibt die Instructions-Datei mit eingetragenem OS in die Config-Verzeichnisse und verteilt die Permission-Regeln. Skill-Abhängigkeiten (Python-Packages, System-Binaries, API-Keys) installiert der Agent bei Bedarf zur Laufzeit auf Basis der `install.yaml` neben jedem Skill.

Nach der Installation: API-Keys in `.env` eintragen.

## Roadmap: Sandbox-Modus (Docker)

Das Repo soll langfristig zwei Nutzungsmodi bieten:

| Modus                 | Zielgruppe                         | Setup                                                                                   |
| --------------------- | ---------------------------------- | --------------------------------------------------------------------------------------- |
| **Host-Installation** | Erfahrene Entwickler               | `install.py` verlinkt Skills/Agents per Symlink in die lokalen Agent-Verzeichnisse      |
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
docker pull ghcr.io/mgiesen/agenttoolkit:latest
docker run --read-only --tmpfs /tmp -v ./dir:/workspace -it agenttoolkit
```

### Offene Punkte

- Hosting der API-Keys: Docker Secrets, `.env`-Mount oder interaktive Eingabe beim Start
- Ein Image für alle Agents vs. ein Base-Image mit Agent-spezifischen Varianten
- Kennzeichnung von Skills, die im Container nicht verfügbar sind (z.B. Apple Notes, Folder Picker)
- Egress-Whitelist für erlaubte API-Endpunkte
