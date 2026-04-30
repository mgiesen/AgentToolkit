---
name: apple-notes-write-only
version: "1.0"
description: Erstellt neue Apple Notes mit Formatierung. Nur schreibend, kein Lesen/Loeschen/Auflisten. Nur macOS.
requires:
  platform: macOS
  app: [Notes]
features:
  - Neue Apple Note mit HTML-formatiertem Body erstellen
  - Notizen mit Bullet-Listen, nummerierten Listen und Tabellen anlegen
  - Hyperlinks und fett/kursiven Text in Notizen einbetten
  - Notizen in beliebige Ordner (Accounts) schreiben
---

Neue Notiz erstellen:

```
scripts/apple-notes.sh "Titel" "HTML-Body"
```

## Unterstuetzte Formatierung im Body

**Text:** `<b>` `<i>` `<u>` `<s>` `<tt>` (Proportional/Code) `<a href="...">` `<br>`

**Listen:** `<ul><li>` (Bullets) `<ol><li>` (Nummeriert)

**Tabelle:** `<table><tr><th>Kopf</th></tr><tr><td>Wert</td></tr></table>`

## Einschraenkungen

- Keine Checklisten zum Abhaken
- Keine Dateianhänge
- **Ueberschriften:** Die AppleScript-API von Apple Notes konvertiert `<h1>`-`<h3>` beim Schreiben zu `font-size` Spans statt nativer Titel/Ueberschrift-Stile. Das ist eine Limitierung der API, keine Loesung bekannt (Stand April 2026, auch von Dritttools wie `memo` bestaetigt).
