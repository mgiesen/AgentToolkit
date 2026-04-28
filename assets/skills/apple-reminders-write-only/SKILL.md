---
name: apple-reminders-write-only
description: Erstellt neue Apple Erinnerungen. Nur schreibend, kein Lesen/Loeschen/Auflisten. Nur macOS.
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
