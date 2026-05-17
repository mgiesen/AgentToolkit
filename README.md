# AgentToolkit

Die KI-Landschaft entwickelt sich rasend schnell: Fähigkeiten, Verfügbarkeit, Kosten und Modellqualität verschieben sich laufend zwischen den großen Anbietern. Für meine eigene Arbeit hat es sich deshalb als zweckmäßig erwiesen, je nach Aufgabe und Lage zwischen OpenAI, Google, Anthropic und anderen Modellanbietern wechseln zu können. Auch bei temporärer Downtime eines Dienstes ist es praktisch, nicht am jeweiligen Agent-Setup festzuhängen, sondern einfach den Anbieter oder das Werkzeug zu wechseln.

Das funktioniert nur gut, wenn das eigene Setup möglichst agnostisch aufgebaut ist. AgentToolkit ist meine Distributionslösung für eigene Werkzeuge, Skills, Subagenten und gemeinsame Regeln: einmal gepflegt, aber in mehreren Agent-Umgebungen nutzbar. Dadurch kann ich nahtlos zwischen Claude Code, Codex, Gemini CLI und OpenCode wechseln, ohne dieselben Fähigkeiten mehrfach zu kopieren oder auseinanderlaufen zu lassen. Mit OpenCode kommt zusätzlich eine unabhängige Lösung hinzu, die sowohl mit lokalen Modellen als auch mit Cloud-Anbietern betrieben werden kann.

| Ebene        | Aufgabe                                                                                     | Quelle im Repo                  |
| ------------ | ------------------------------------------------------------------------------------------- | ------------------------------- |
| Skills       | Wiederverwendbare Fähigkeiten mit Anleitung, Skripten und Abhängigkeitsdefinition           | `assets/skills/*`               |
| Subagenten   | Spezialisierte Agent-Rollen für delegierbare Aufgaben                                       | `assets/agents/*.md`            |
| Instructions | Gemeinsame Grundregeln für Sprache, Skill-Nutzung, Plattformprüfung und Dependency-Handling | `assets/instructions/AGENTS.md` |
| Runtime      | Gemeinsame `.env` und gemeinsame Python-Umgebung `.venv` im Repo-Root                       | `.env`, `.venv`                 |

## Grundidee

Technisch ist AgentToolkit ein verwaltetes Verzeichnislayout mit Installer. Die Bausteine liegen unter `assets/`. Der Installer nimmt diese Struktur und bindet sie in die Konfigurationsordner der ausgewählten Agent-Systeme ein.

Ein Skill ist ein eigener Ordner mit einer `SKILL.md` als Einstiegspunkt. Darin stehen Beschreibung, Plattformangaben und Arbeitsanweisung. Alles, was zur Ausführung dazugehört, bleibt daneben im selben Skill-Ordner: Skripte, Referenzen, Vorlagen, Tests oder weitere Hilfsdateien.

Wenn ein Skill Abhängigkeiten braucht, beschreibt er sie in seiner `install.yaml`. Dort steht zum Beispiel, welche Python-Pakete, System-Binaries, API-Keys oder Nachinstallationsschritte nötig sind. Python-Pakete werden in die gemeinsame `.venv` im Repo-Root installiert, damit nicht jedes Agent-Frontend eine eigene Umgebung pflegen muss.

Verteilt wird per Symlink statt per Kopie. Änderungen an einem Skill, einem Subagenten oder den gemeinsamen Instructions werden dadurch im Repo vorgenommen und sind anschließend in den angebundenen Agent-Umgebungen verfügbar.

## Enthaltene Fähigkeiten

- [Skills](docs/skills.md) — [`assets/skills/`](assets/skills/)
- [Subagenten](docs/agents.md) — [`assets/agents/`](assets/agents/)
- [Instructions](#instructions) — [`assets/instructions/AGENTS.md`](assets/instructions/AGENTS.md)

### Instructions

Was die globale `AGENTS.md` dem Agent zusätzlich zu projektspezifischen Instructions vorgibt:

| Regel           | Wirkung                                                                               |
| --------------- | ------------------------------------------------------------------------------------- |
| Sprache         | Deutsch mit echten UTF-8-Umlauten (ä, ö, ü, ß), keine ASCII-Substitution.             |
| Skill-Vorrang   | Passende Skills und Subagenten nutzen, statt eigene Tools zu installieren.            |
| OS-Kontext      | Agent kennt das aktuelle OS (`macos` / `linux` / `windows`).                          |
| Plattform-Check | Skill nur ausführen, wenn das `platform:`-Feld der `SKILL.md` zum aktuellen OS passt. |
| Abhängigkeiten  | Bei fehlendem Tool die `install.yaml` des Skills lesen und befolgen.                  |
| Python-Umgebung | Python-Skills nur in die gemeinsame `.venv`, nie System-Python oder System-pip.       |

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

Ohne Flags öffnet der Installer ein interaktives Menü. Dort wählst du, ob Skills, Subagenten und Instructions installiert oder entfernt werden sollen und für welche Agent-Systeme das gelten soll.

Für nicht-interaktive Nutzung:

```bash
python3 scripts/install.py --all        # alles für alle unterstützten Agents installieren
python3 scripts/install.py --status     # Installationsstatus anzeigen
python3 scripts/install.py --uninstall  # verwaltete Symlinks und Dateien entfernen
```

Nach der Installation trägst du benötigte API-Keys in `.env` ein. Eine Vorlage liegt in [.env.example](.env.example).

## Was der Installer konkret macht

Bei einer Installation passieren drei Dinge:

1. Skill-Ordner aus `assets/skills/` werden in die Skill-Verzeichnisse der ausgewählten Agents verlinkt.
2. Subagent-Dateien aus `assets/agents/` werden in die Agent-Verzeichnisse verlinkt.
3. Die gemeinsamen Instructions werden mit eingetragenem OS in die passende globale Agent-Datei geschrieben.

Permission- oder Allowlist-Regeln berührt der Installer bewusst nicht. Freigaben für Shell-Befehle, Tools oder Pfade bleiben Sache der jeweiligen Agent-Konfiguration.

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
