# AgentToolkit

AgentToolkit ist eine zentrale Werkbank für CLI-basierte AI Agents. Das Repository bündelt Skills, Subagenten, gemeinsame Arbeitsregeln, Permission-Regeln und Runtime-Konventionen an einer Stelle und verteilt sie in die Konfigurationsverzeichnisse der unterstützten Agent-Systeme.

Der praktische Nutzen: Fähigkeiten werden nicht pro Agent kopiert und auseinanderentwickelt, sondern einmal gepflegt und per Symlink eingebunden. Änderungen an einem Skill, einem Subagenten oder einer Regel wirken dadurch sofort in Claude Code, Codex, Gemini CLI und OpenCode.

## Was dieses Repo löst

Viele lokale Agent-Setups wachsen organisch: ein Skript hier, eine Prompt-Regel dort, mehrere virtuelle Python-Umgebungen, verstreute API-Keys und leicht abweichende Versionen derselben Tools. AgentToolkit ordnet diese Teile in ein nachvollziehbares Modell:

| Ebene        | Aufgabe                                                                                     | Quelle im Repo                  |
| ------------ | ------------------------------------------------------------------------------------------- | ------------------------------- |
| Skills       | Wiederverwendbare Fähigkeiten mit Anleitung, Skripten und Abhängigkeitsdefinition           | `assets/skills/*`               |
| Subagenten   | Spezialisierte Agent-Rollen für delegierbare Aufgaben                                       | `assets/agents/*.md`            |
| Instructions | Gemeinsame Grundregeln für Sprache, Skill-Nutzung, Plattformprüfung und Dependency-Handling | `assets/instructions/AGENTS.md` |
| Permissions  | Vorab erlaubte, eng begrenzte Shell-Befehle für häufige Tool-Aufrufe                        | `assets/permissions/rules.json` |
| Runtime      | Gemeinsame `.env` und gemeinsame Python-Umgebung `.venv` im Repo-Root                       | `.env`, `.venv`                 |

## Grundidee

Ein Skill ist hier nicht nur ein Prompt-Snippet. Ein Skill besteht aus einer `SKILL.md` mit Frontmatter, Plattformangaben und Arbeitsanweisung. Optional kommen `scripts/`, `references/`, `templates/`, Tests und eine `install.yaml` hinzu.

Die `install.yaml` beschreibt, was ein Skill zur Laufzeit braucht: Python-Pakete, System-Binaries, API-Keys oder Post-Install-Schritte. Die globalen Instructions sagen den Agents, wie sie diese Datei auswerten sollen. Python-Abhängigkeiten werden dabei immer in der gemeinsamen `.venv` installiert, nicht ins System-Python.

Der Installer kopiert diese Inhalte nicht, sondern legt Symlinks an. Das ist bewusst so: Das Repository bleibt die einzige Quelle der Wahrheit.

## Enthaltene Fähigkeiten

Das Toolkit enthält Skills für unter anderem:

- Dokumente und PDFs: `pandoc`, `pdf`, `ocr`
- Bilder, Diagramme und QR-Codes: `image`, `image-gen`, `chart`, `qr-code`, `iconify`
- Recherche und Web-Daten: `crawl4ai`, `tavily`, `youtube-dlp`, `github`, `gitlab`, `handelsregister`
- Lokale und externe Arbeitsumgebungen: `ssh`, `folder-picker`
- Apple-Integration: `apple-notes-write-only`, `apple-reminders-write-only`
- Routing und Orte: `geo`

Die vollständige, generierte Übersicht mit Plattformen, Features, Abhängigkeiten, API-Keys und Startup-Token steht in [docs/skills.md](docs/skills.md).

Zusätzlich enthält das Repo zwei Subagenten:

- `deep-research` für mehrstufige Recherche mit Quellenanalyse und Synthese
- `report-writer` für wissenschaftlich strukturierte Berichte mit PDF-Erzeugung

Details stehen in [docs/agents.md](docs/agents.md).

## Unterstützte Agents

Der Installer kennt aktuell diese Zielsysteme:

| Agent       | Skills               | Subagenten           | Instructions                   |
| ----------- | -------------------- | -------------------- | ------------------------------ |
| Claude Code | `~/.claude/skills`   | `~/.claude/agents`   | `~/.claude/CLAUDE.md`          |
| Codex       | `~/.codex/skills`    | `~/.codex/agents`    | `~/.codex/AGENTS.md`           |
| Gemini CLI  | `~/.gemini/skills`   | `~/.gemini/agents`   | `~/.gemini/GEMINI.md`          |
| OpenCode    | `~/.opencode/skills` | `~/.opencode/agents` | `~/.config/opencode/AGENTS.md` |

Die Instructions werden als verwaltete Datei geschrieben. Sie enthalten einen Marker und das beim Installieren erkannte Betriebssystem (`macos`, `linux` oder `windows`). Eigene, nicht von AgentToolkit verwaltete Instruction-Dateien werden nicht überschrieben.

## Installation

Voraussetzung ist Python 3.9 oder neuer. Unter Windows müssen Symlinks erlaubt sein, entweder über den Developer Mode oder durch ein Terminal mit Admin-Rechten.

```bash
git clone https://github.com/mgiesen/AgentToolkit.git
cd AgentToolkit
python3 scripts/install.py
```

Ohne Flags öffnet der Installer ein interaktives Menü. Dort wählst du, ob Skills, Subagenten, Instructions und Permissions installiert oder entfernt werden sollen und für welche Agent-Systeme das gelten soll.

Für nicht-interaktive Nutzung:

```bash
python3 scripts/install.py --all        # alles für alle unterstützten Agents installieren
python3 scripts/install.py --status     # Installationsstatus anzeigen
python3 scripts/install.py --uninstall  # verwaltete Symlinks und Dateien entfernen
```

Nach der Installation trägst du benötigte API-Keys in `.env` ein. Eine Vorlage liegt in [.env.example](.env.example).

## Was der Installer konkret macht

Bei einer Installation passieren vier Dinge:

1. Skill-Ordner aus `assets/skills/` werden in die Skill-Verzeichnisse der ausgewählten Agents verlinkt.
2. Subagent-Dateien aus `assets/agents/` werden in die Agent-Verzeichnisse verlinkt.
3. Die gemeinsamen Instructions werden mit eingetragenem OS in die passende globale Agent-Datei geschrieben.
4. Permission-Regeln aus `assets/permissions/rules.json` werden in die Konfigurationen der Agents übertragen.

Die Permission-Regeln erlauben nur bekannte Tool-Aufrufe, zum Beispiel Skill-Skripte, lokale Dokument- und Bildwerkzeuge sowie lesende `gh`-Operationen. Schreibende oder riskante Aktionen bleiben weiterhin zustimmungspflichtig, sofern der jeweilige Agent das so erzwingt.

Die Regeln werden agent-spezifisch in unterschiedlichen Formaten gespeichert:

| Agent       | Ziel-Config                         | Format                                            |
| ----------- | ----------------------------------- | ------------------------------------------------- |
| Claude Code | `~/.claude/settings.json`           | `permissions.allow[]` mit `Bash(pattern)`         |
| Codex       | `~/.codex/rules/agentic.rules`      | Starlark-`prefix_rule()`                          |
| Gemini CLI  | `~/.gemini/settings.json`           | `tools.allowed[]` mit `run_shell_command(prefix)` |
| OpenCode    | `~/.config/opencode/.opencode.json` | `permission.bash{}` mit Pattern → `allow`         |

## Nutzung im Alltag

Nach der Installation musst du Skills normalerweise nicht manuell starten. Die globalen Instructions weisen den Agent an, passende Skills bevorzugt zu verwenden, wenn deine Aufgabe zur Skill-Beschreibung passt.

Beispiele:

- Eine PDF zusammenführen oder komprimieren → `pdf`
- Text aus einem Scan extrahieren → `ocr`
- Einen wissenschaftlichen Bericht aus Markdown bauen → `pandoc`
- GitHub-Issues oder PRs analysieren → `github`
- Eine Website strukturiert crawlen → `crawl4ai`
- Ein Diagramm als SVG oder PNG erzeugen → `chart`

Wenn einem Skill ein Tool fehlt, liest der Agent die jeweilige `install.yaml`. Python-Pakete darf er direkt in `.venv` installieren. System-Binaries wie `pandoc`, `qpdf`, `magick` oder `qrencode` erfordern je nach Agent und Plattform eine Rückfrage oder eine passende Freigabe.

## Einzelne Skills via `skills` CLI

Einzelne Skills lassen sich auch ohne vollständiges Klonen dieses Repos über das [Vercel-`skills`-CLI](https://skills.sh) installieren:

```bash
npx skills add mgiesen/AgentToolkit --skill <name>
npx skills add mgiesen/AgentToolkit
```

Der Skill-Name entspricht dem `name:`-Feld in der jeweiligen `SKILL.md`, zum Beispiel `chart`, `pandoc` oder `crawl4ai`.

Diese Variante ist praktisch zum schnellen Ausprobieren, ersetzt aber nicht das vollständige AgentToolkit-Setup. Das `skills`-CLI nutzt nicht den Installer dieses Repos, nicht die gemeinsame `.venv`, nicht die zentrale `.env` und nicht automatisch die hier definierten globalen Instructions. Für produktive lokale Agent-Setups ist `python3 scripts/install.py` daher der empfohlene Weg.

## Wartung und Weiterentwicklung

Neue oder geänderte Skills gehören unter `assets/skills/<name>/`. Die zentrale Beschreibung steht in `SKILL.md`; Abhängigkeiten gehören in `install.yaml`; ausführbare Hilfen liegen idealerweise in `scripts/`.

Nach Änderungen an Skills oder Agents sollten die Übersichtsseiten neu erzeugt werden:

```bash
python3 scripts/generate_skills_overview.py
python3 scripts/generate_agents_overview.py
```

Wenn sich die globalen Instructions ändern, wird nicht direkt in den Agent-Konfigurationsdateien editiert. Stattdessen wird `assets/instructions/AGENTS.md` angepasst und anschließend der Installer erneut ausgeführt.
