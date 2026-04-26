---
name: tavily
description: "Quellenfindung und Deep Research, wenn noch keine belastbaren Quellen bekannt sind und breite aktuelle Recherche noetig ist. Gut fuer Markt-, Vendor-, Tool-, Company-, Wettbewerbs-, Trend- und News-Recherche sowie Synthese mit Zitaten. Fuer bekannte URLs Webtools und für Crawling crawl4ai nutzen."
---

# Tavily Skill

Fokus: breite Recherche vor der Quellenlage. Nicht als Crawler verwenden.

Voraussetzung: `TAVILY_API_KEY` in `.env`. Der Wrapper nutzt `.venv/bin/tvly`.

## Einsatz

- `search`: erste Quellenliste, aktuelle Treffer, News, Trends, Vendor-/Tool-Findung.
- `research`: Synthese ueber viele Quellen mit Zitaten.

Modellwahl: `mini` fuer fokussierte Fragen, `pro` fuer breite Markt-, Wettbewerbs- und Strategiefragen.

## Nicht Nutzen

- Bekannte URL, Website-Crawl, Doku-Mirror, RAG-Ingestion: `crawl4ai` oder lokale Tools.
- GitHub: `github`.
- YouTube: `youtube-dlp`.
- PDF, OCR, Bild, Geo, Codebase: jeweiliger Spezialskill oder lokales Tool.

Nach Tavily-Treffern moeglichst mit Primaerquellen weiterarbeiten.

## Commands

```bash
scripts/tavily.sh status
scripts/tavily.sh search "AI coding agents enterprise adoption 2026" --depth advanced --max-results 10
scripts/tavily.sh research "Compare current AI coding assistants for small engineering teams" --model mini --citation-format numbered
scripts/tavily.sh research "Market landscape for on-prem AI coding assistants in regulated industries" --model pro --citation-format numbered
```

Der Wrapper gibt fuer `search`, `research` und `research-poll` standardmaessig JSON aus. Fuer lesbare CLI-Ausgabe `--human` setzen.
