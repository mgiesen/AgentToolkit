---
name: ssh
description: Der User möchte via SSH etwas auf einem entfernten System tun — Software installieren, Dienste konfigurieren, Dateien bearbeiten, Logs prüfen oder Probleme beheben.
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "1.0"
platform: all
features:
  - SSH-Verbindung zu entfernten Hosts über ~/.ssh/config herstellen
  - Software installieren, Dienste konfigurieren und Logs auf Remote-Systemen prüfen
  - Lesende Befehle direkt ausführen, schreibende Befehle mit Rückfrage absichern
  - Dateien auf Remote-Systemen bearbeiten
  - Neuen Host interaktiv per setup-Skript einrichten
---

# SSH

## Verbindung

Lies `~/.ssh/config` und prüfe ob ein passender Host existiert. Falls nicht, starte das Setup im neuen Terminal:

```bash
osascript -e 'tell app "Terminal" to do script "<skill-pfad>/scripts/setup-host.sh"'
```

Ersetze `<skill-pfad>` mit dem absoluten Pfad dieses Skill-Ordners. Warte auf `/tmp/agenttoolkit-ssh-setup.json` (prüfe alle 5s).

## Sicherheit

Zeige **einmal pro Gespräch** vor dem ersten SSH-Befehl:

> ⚠️ SSH-Befehle werden direkt auf dem entfernten System ausgeführt — ohne das Berechtigungssystem deines lokalen Agenten. Beachte das KI-Modelle Fehler machen können!

**Lesende Befehle direkt ausführen, ohne Rückfrage.** Dazu zählen u. a. `cat`, `head`, `tail`, `grep`, `awk`/`sed` ohne `-i`, `ls`, `find`, `stat`, `du`, `df`, `ps`, `top -n1`, `uptime`, `free`, `uname`, `hostname`, `dmesg`, `journalctl` (ohne Rotate), `ip`, `ss`, `ping`, `vcgencmd`, `systemctl status`, `git status/log/diff`. Auch `sudo` davor ist ok, solange das Tool selbst rein lesend ist.

**Bei verändernden Befehlen Rückfrage stellen** — vorher:

1. Einen Satz auf Deutsch in Alltagssprache, was der Befehl bewirkt
2. Den Befehl im Codeblock
3. Die Frage: „Soll ich das ausführen?"

Verändernd ist u. a.: Schreibumleitungen (`>`, `>>`, `tee`, `sed -i`, `cat <<EOF > …`), `rm`/`mv`/`cp` mit Ziel, `chmod`/`chown`, Paketmanager (`apt`, `dpkg`, `pip install`, `npm install`), `systemctl start/stop/restart/enable/disable`, `service …`, `kill`/`pkill`, `reboot`/`shutdown`, `mount`/`umount`/`mkfs`, Firewall-/Netzwerkkonfiguration, jedes neu kompilieren/installieren oder Verändern von Konfigdateien.

Im Zweifel — vor allem bei `sudo` mit unklarem Tool oder verketteten Pipelines, die schreiben können — lieber nachfragen.

## Befehlsregeln

- Das Terminal ist nicht für den User sichtbar und er kann selbst keine Eingaben machen. Du bist der Operator!
- `DEBIAN_FRONTEND=noninteractive` bei apt/dpkg
- `-y` / `--yes` bei Paketmanagern
- Keine interaktiven Programme (`nano`, `vi`, `top`)
- Dateibearbeitung via `sed`, `awk` oder `cat <<'EOF' > datei`
- Mehrzeilige Befehle via `ssh <alias> "bash -s" <<'EOF'`
