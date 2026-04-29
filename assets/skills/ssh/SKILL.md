---
name: ssh
description: Der User möchte via SSH etwas auf einem entfernten System tun — Software installieren, Dienste konfigurieren, Dateien bearbeiten, Logs prüfen oder Probleme beheben.
---

# SSH

## Verbindung

Lies `~/.ssh/config` und prüfe ob ein passender Host existiert. Falls nicht, starte das Setup im neuen Terminal:

```bash
osascript -e 'tell app "Terminal" to do script "<skill-pfad>/scripts/setup-host.sh"'
```

Ersetze `<skill-pfad>` mit dem absoluten Pfad dieses Skill-Ordners. Warte auf `/tmp/agentbox-ssh-setup.json` (prüfe alle 5s).

## Sicherheit

Zeige vor dem ersten SSH-Befehl im Gespräch:

> ⚠️ SSH-Befehle werden direkt auf dem entfernten System ausgeführt — ohne das Berechtigungssystem deines lokalen Agenten. Beachte das KI-Modelle Fehler machen können!

**Vor JEDEM SSH-Befehl ohne Ausnahme:**

1. Beschreibe in einem Satz auf Deutsch, was der Befehl bewirkt — in Alltagssprache, nicht als Bash-Befehl
2. Zeige den Befehl im Codeblock
3. Frage: „Soll ich das ausführen?"

## Befehlsregeln

- Das Terminal ist nicht für den User sichtbar und er kann selbst keine Eingaben machen. Du bist der Operator!
- `DEBIAN_FRONTEND=noninteractive` bei apt/dpkg
- `-y` / `--yes` bei Paketmanagern
- Keine interaktiven Programme (`nano`, `vi`, `top`)
- Dateibearbeitung via `sed`, `awk` oder `cat <<'EOF' > datei`
- Mehrzeilige Befehle via `ssh <alias> "bash -s" <<'EOF'`
