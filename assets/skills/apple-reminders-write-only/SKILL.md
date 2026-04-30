---
name: apple-reminders-write-only
version: "1.0"
description: Erstellt neue Apple Erinnerungen. Nur schreibend, kein Lesen/Loeschen/Auflisten. Nur macOS.
requires:
  platform: macOS
  app: [Reminders]
features:
  - Neue Erinnerung mit Titel, Notiztext und Fälligkeitsdatum erstellen
  - Priorität (hoch/mittel/niedrig) und Ziel-Liste festlegen
  - ISO-Datetime als Fälligkeitszeitpunkt übergeben (2026-04-28T14:00)
  - URLs im Notiztext werden automatisch klickbar dargestellt
---

Neue Erinnerung erstellen:

```
scripts/apple-reminders.sh "Titel"
scripts/apple-reminders.sh "Titel" --body "Notiz mit Details" --due "2026-04-28T14:00" --priority 1 --list "Projekte"
```

## Optionen

- `--body <text>` – Notiztext (URLs werden klickbar dargestellt)
- `--due <ISO-datetime>` – Faelligkeitsdatum (z.B. `2026-04-28T14:00`)
- `--priority <1-9>` – 1-4 hoch, 5 mittel, 6-9 niedrig, 0 keine
