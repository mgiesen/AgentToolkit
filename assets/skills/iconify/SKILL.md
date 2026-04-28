---
name: iconify
description: SVG-Icons suchen und herunterladen. Verwenden wenn Icons, Symbole oder Piktogramme fuer UI-Elemente, Navigationen, Toolbars, Buttons, Websites, Dokumente oder Apps benoetigt werden. Durchsucht Iconify (200k+ Icons aus Lucide, Tabler, Phosphor, Material Design u.a.).
---

# Iconify Skill

Verwende `scripts/iconify.py`, um Iconify-Icons tokenarm zu suchen und als SVG zu schreiben. Verwende ausschliesslich englische Suchbegriffe und visuelle UI-Metaphern wie `settings`, `gear`, `arrow left`, `shopping cart`, `triangle alert`, `file text`, `clipboard list`, `gauge`.

## Workflow

1. Erst suchen, wenn die Semantik nicht eindeutig ist:

```bash
python3 assets/skills/iconify/scripts/iconify.py search "gauge" --limit 8 --prefixes lucide,tabler,ph,mdi,carbon
```

2. Passenden Treffer lokal speichern:

```bash
python3 assets/skills/iconify/scripts/iconify.py download lucide:gauge --output assets/gauge.svg
```

3. Nur bei klarer Semantik direkt waehlen und speichern:

```bash
python3 assets/skills/iconify/scripts/iconify.py pick "calendar check" --output assets/calendar-check.svg --limit 12
```

## Commands

- `search QUERY`: kompakte Kandidaten mit Icon-ID, Score, Lizenz, Set und URL.
- `download PREFIX:NAME --output FILE`: konkretes SVG speichern.
- `pick QUERY --output FILE`: Top-Treffer suchen und speichern.
- `fetch QUERY`: Top-Treffer als rohes SVG ausgeben.
- `url PREFIX:NAME`: direkte SVG-URL ausgeben.
- `show PREFIX:NAME`: konkretes SVG ausgeben.

Wichtige Optionen: `--prefixes`, `--prefer`, `--palette mono|color|any`, `--limit`, `--json`, `--width`, `--height`, `--color`, `--box`. Default: monotone Icons bevorzugen; kein SVG in den Chat ausgeben, ausser der Nutzer fragt danach.

Python:

```python
from assets.skills.iconify.scripts.iconify import fetch_svg_icon
svg = fetch_svg_icon("shopping cart")
```

Details zur API stehen in `references/iconify-api.md`.
