---
name: folder-picker
description: Oeffnet einen nativen Ordner-Dialog zur interaktiven Ordnerauswahl und gibt den Pfad zurueck. Unterstuetzt macOS (Finder), Windows (PowerShell) und Linux (zenity).
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "1.0"
platform: all
features:
  - Nativen Ordner-Auswahldialog öffnen (macOS Finder, Windows PowerShell, Linux zenity)
  - Absoluten Pfad des gewählten Ordners zurückgeben
  - Abbruch durch den User erkennen und erneut nachfragen
  - Optionalen Prompt-Text für den Dialog übergeben
---

# folder-picker

Interaktive Ordnerauswahl per nativem Dialog (macOS: Finder, Windows: PowerShell, Linux: zenity). Nutzen wenn ein Zielordner vom Anwender benoetigt wird und nicht aus dem Kontext bekannt ist.

```bash
python3 scripts/pick_folder.py [--prompt "Bitte Ordner waehlen"]
```

## Output

- **stdout:** `PATH=<absoluter Pfad>` (bei Erfolg)
- **exit 0:** Ordner gewaehlt
- **exit 1:** Benutzer hat abgebrochen
- **exit 2:** Pfad ungueltig oder OS nicht unterstuetzt

## Nutzungsregeln

1. Pruefe zuerst ob der Ordner bereits aus dem Kontext bekannt ist – wenn ja, nicht erneut fragen
2. Kuendige dem Anwender im Chat an, dass ein Dialog erscheint
3. Parse `PATH=...` aus stdout und merke den Pfad fuer die Session
4. Bei Abbruch: nachfragen ob erneut oder manuell eingeben
