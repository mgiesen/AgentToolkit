# AgentToolkit

Die KI-Landschaft entwickelt sich rasend schnell: Fähigkeiten, Verfügbarkeit, Kosten und Modellqualität verschieben sich laufend zwischen den großen Anbietern. Für meine eigene Arbeit hat es sich deshalb als zweckmäßig erwiesen, je nach Aufgabe und Lage zwischen OpenAI, Google, Anthropic und anderen Modellanbietern wechseln zu können. Auch bei temporärer Downtime eines Dienstes ist es praktisch, nicht am jeweiligen Agent-Setup festzuhängen, sondern einfach den Anbieter oder das Werkzeug zu wechseln.

Das funktioniert nur gut, wenn das eigene Setup möglichst agnostisch aufgebaut ist. AgentToolkit ist meine Distributionslösung für eigene Skills: einmal gepflegt, aber in mehreren Agent-Umgebungen nutzbar. Dadurch kann ich nahtlos zwischen Claude Code, Codex, Gemini CLI und OpenCode wechseln, ohne dieselben Fähigkeiten mehrfach zu kopieren oder auseinanderlaufen zu lassen. Mit OpenCode kommt zusätzlich eine unabhängige Lösung hinzu, die sowohl mit lokalen Modellen als auch mit Cloud-Anbietern betrieben werden kann.

| Ebene   | Aufgabe                                                                           | Quelle im Repo     |
| ------- | ---------------------------------------------------------------------------------- | ------------------- |
| Skills  | Wiederverwendbare Fähigkeiten mit Anleitung, Skripten und Abhängigkeitsdefinition | `assets/skills/*`   |
| Runtime | Gemeinsame `.env` und gemeinsame Python-Umgebung `.venv` im Repo-Root             | `.env`, `.venv`     |

## Grundidee

Technisch ist AgentToolkit ein verwaltetes Verzeichnislayout mit Installer. Die Skills liegen unter `assets/skills/`. Der Installer nimmt diese Struktur und bindet sie in die Skill-Verzeichnisse der ausgewählten Agent-Systeme ein.

Ein Skill ist ein eigener Ordner mit einer `SKILL.md` als Einstiegspunkt. Darin stehen Beschreibung, Plattformangaben und Arbeitsanweisung. Alles, was zur Ausführung dazugehört, bleibt daneben im selben Skill-Ordner: Skripte, Referenzen, Vorlagen, Tests oder weitere Hilfsdateien.

Wenn ein Skill Abhängigkeiten braucht, beschreibt er sie in seiner `install.yaml`. Dort steht zum Beispiel, welche Python-Pakete, System-Binaries, API-Keys oder Nachinstallationsschritte nötig sind. Python-Pakete werden in die gemeinsame `.venv` im Repo-Root installiert, damit nicht jedes Agent-Frontend eine eigene Umgebung pflegen muss.

Verteilt wird per Symlink statt per Kopie. Änderungen an einem Skill werden dadurch im Repo vorgenommen und sind anschließend in den angebundenen Agent-Umgebungen verfügbar.

## Enthaltene Fähigkeiten

- [Skills](docs/skills.md) — [`assets/skills/`](assets/skills/)

## Unterstützte Agents

Der Installer kennt aktuell diese Zielsysteme:

| Agent       | Skills                |
| ----------- | ---------------------- |
| Claude Code | `~/.claude/skills`     |
| Codex       | `~/.codex/skills`      |
| Gemini CLI  | `~/.gemini/skills`     |
| OpenCode    | `~/.opencode/skills`   |

## Installation

Voraussetzung ist Python 3.9 oder neuer. Unter Windows müssen Symlinks erlaubt sein, entweder über den Developer Mode oder durch ein Terminal mit Admin-Rechten.

```bash
git clone https://github.com/mgiesen/AgentToolkit.git
cd AgentToolkit
python3 scripts/install.py
```

Ohne Flags öffnet der Installer ein interaktives Menü. Dort wählst du, ob Skills installiert oder entfernt werden sollen und für welche Agent-Systeme das gelten soll.

Für nicht-interaktive Nutzung:

```bash
python3 scripts/install.py --all        # alles für alle unterstützten Agents installieren
python3 scripts/install.py --status     # Installationsstatus anzeigen
python3 scripts/install.py --uninstall  # verwaltete Symlinks entfernen
```

Nach der Installation trägst du benötigte API-Keys in `.env` ein. Eine Vorlage liegt in [.env.example](.env.example).

## Was der Installer konkret macht

Bei einer Installation werden Skill-Ordner aus `assets/skills/` in die Skill-Verzeichnisse der ausgewählten Agents verlinkt.

Permission- oder Allowlist-Regeln berührt der Installer bewusst nicht. Freigaben für Shell-Befehle, Tools oder Pfade bleiben Sache der jeweiligen Agent-Konfiguration.

## Nutzung im Alltag

Nach der Installation musst du Skills normalerweise nicht manuell starten. Die Agents erkennen anhand der Beschreibung in der jeweiligen `SKILL.md`, wann ein Skill zur Aufgabe passt, und nutzen ihn automatisch.

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

Diese Variante ist praktisch zum schnellen Ausprobieren, ersetzt aber nicht das vollständige AgentToolkit-Setup. Das `skills`-CLI nutzt nicht den Installer dieses Repos, nicht die gemeinsame `.venv` und nicht die zentrale `.env`. Für produktive lokale Agent-Setups ist `python3 scripts/install.py` daher der empfohlene Weg.

## Wartung und Weiterentwicklung

Neue oder geänderte Skills gehören unter `assets/skills/<name>/`. Die zentrale Beschreibung steht in `SKILL.md`; Abhängigkeiten gehören in `install.yaml`; ausführbare Hilfen liegen idealerweise in `scripts/`.

Nach Änderungen an Skills sollte die Übersichtsseite neu erzeugt werden:

```bash
python3 scripts/generate_skills_overview.py
```
