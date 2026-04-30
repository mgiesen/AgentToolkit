---
name: tavily
version: "1.0"
description: Optionale Paid-Recherche via Tavily fuer breite Quellenfindung und Deep Research. Nur verwenden, wenn der User Tavily/Deep Research wuenscht oder wenn kostenlose Webtools/crawl4ai nicht reichen und API-Kosten vertretbar sind. Gut fuer Markt-, Vendor-, Tool-, Company-, Wettbewerbs-, Trend- und News-Recherche mit Zitaten.
requires:
  key:
    - name: TAVILY_API_KEY
      url: https://app.tavily.com
features:
  - Breite Web-Recherche mit Quellensynthese und nummerierten Zitaten
  - Aktuelle News, Trends und Vendor-Listen zu einem Thema abrufen
  - Markt- und Wettbewerbsanalysen für strategische Fragen
  - Gezielte Nachschlag-Suche nach einem Research-Report
---

# Tavily Skill

Fokus: kostenpflichtige breite Recherche vor der Quellenlage. Nicht als Default-Websuche oder Crawler verwenden.

Voraussetzung: `TAVILY_API_KEY` in `.env`. Der Wrapper nutzt `.venv/bin/tvly`.

## Einsatz

- Tavily ist eine Paid-Option. Bei Unsicherheit erst kostenlose Webtools oder `crawl4ai` nutzen oder den User fragen.
- `search`: erste Quellenliste, aktuelle Treffer, News, Trends, Vendor-/Tool-Findung.
- `research`: Synthese ueber viele Quellen mit Zitaten.

Modellwahl: `mini` fuer fokussierte Fragen, `pro` fuer breite Markt-, Wettbewerbs- und Strategiefragen.

## Workflow

- Wenn Tavily bewusst eingesetzt wird: breite Recherche mit `research` starten.
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
