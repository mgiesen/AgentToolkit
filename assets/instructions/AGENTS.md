## Sprache

Deutsch. Echte UTF-8-Umlaute (ä, ö, ü, Ä, Ö, Ü, ß), keine ae/oe/ue/ss-Substitution außer wenn technisch zwingend.

## Skills und Subagenten

**Bevorzugt verwenden**, wenn die Aufgabe zur Skill- oder Subagent-Beschreibung passt. Sie sind getestet und konsistent über alle Agent-Systeme hinweg.

## System

**Aktuelles OS:** `{{OS}}` _(wird vom Installer eingetragen: `macos` | `linux` | `windows`)_

### Plattform-Check

Lies das `platform:`-Feld aus der `SKILL.md`-Frontmatter. Werte: `all` (überall) oder eine OS-Liste wie `[macOS]`, `[macOS, linux]`. Ist das aktuelle OS nicht enthalten → abbrechen und User informieren.

### Fehlende Abhängigkeit

Bei Fehler durch fehlendes Tool oder Package: `install.yaml` neben der `SKILL.md` lesen.

- `pip:` → `<Repo-Root>/.venv/bin/pip install <name>` (ohne Rückfrage)
- `bin:` → Aus `install:` den Manager passend zum OS wählen (z.B. `brew` / `apt` / `dnf` / `pacman` / `winget` / `choco` / `scoop`), einmal beim User rückfragen, dann installieren. Bei `manual:` die URL zeigen, einfach nötige User Aktion erklären und abbrechen.
- `env:` → Fehlt ein `required: true`-Key in `.env`: die `url` zeigen und abbrechen.
- `post_install:` → Nach `pip`/`bin`-Installation jeden Befehl in dieser Liste der Reihe nach ausführen (z.B. `.venv/bin/crawl4ai-setup` für Playwright-Browser).

Nach erfolgreichem Install den Skill-Aufruf wiederholen.

### Python und venv

Python-Skills laufen **ausschließlich** über die gemeinsame `.venv` im Repo-Root — niemals System-Python oder System-pip.
