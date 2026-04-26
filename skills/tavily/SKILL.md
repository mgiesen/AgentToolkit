---
name: tavily
description: "Quellenfindung und Deep Research fuer breite aktuelle Recherche ohne bekannte Quellen. Verwenden fuer Markt-, Vendor-, Tool-, Company-, Wettbewerbs-, Trend- und News-Recherche mit Zitaten. Fuer bekannte URLs, Webtools und Crawling crawl4ai nutzen."
---

# Tavily Skill

Fokus: breite Recherche vor der Quellenlage. Nicht als Crawler verwenden.

Voraussetzung: `TAVILY_API_KEY` in `.env`. Der Wrapper nutzt `.venv/bin/tvly`.

## Einsatz

- `search`: erste Quellenliste, aktuelle Treffer, News, Trends, Vendor-/Tool-Findung.
- `research`: Synthese ueber viele Quellen mit Zitaten.

Modellwahl: `mini` fuer fokussierte Fragen, `pro` fuer breite Markt-, Wettbewerbs- und Strategiefragen.

## Workflow

- Breite Recherche: immer mit `research` starten.
- Firmen/Regionen, Maerkte, Vendor-Listen, Vergleiche: `research --model pro`.
- Research kann 2 - 15 Minuten dauern. Warten oder als Background-Task laufen lassen.
- Keine parallelen `search`-Aufrufe zum selben Thema, solange `research` laeuft.
- `search --compact` nur fuer gezielte Nachschlaege nach dem Research-Report.

## Commands

```bash
scripts/tavily.sh status
scripts/tavily.sh search "AI coding agents enterprise adoption 2026" --compact --depth advanced --max-results 10
scripts/tavily.sh research "Compare current AI coding assistants for small engineering teams" --model mini --citation-format numbered
scripts/tavily.sh research "Market landscape for on-prem AI coding assistants in regulated industries" --model pro --citation-format numbered
```

Default ist JSON. Fuer Token sparen bei Suche `--compact`. `--human` nur nutzen, wenn der User den Rohbericht direkt lesen soll.
