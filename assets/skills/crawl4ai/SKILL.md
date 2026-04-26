---
name: crawl4ai
description: Web-Scraping und Markdown-Extraktion aus Webseiten. Bevorzugt MCP-Server, CLI als Fallback.
---

# crawl4ai

Webseiten crawlen und als sauberes, LLM-optimiertes Markdown extrahieren.

## Bevorzugt: MCP-Server

Wenn der MCP-Server `crawl4ai` verfuegbar ist, nutze dessen Tools direkt (`crawl_webpage`, `crawl_website`, `extract_structured_data`, `save_as_markdown`). Kein Fallback-Script noetig.

## Fallback: CLI

Nur verwenden wenn der MCP-Server nicht verfuegbar ist.

```bash
scripts/crawl4ai.sh markdown "https://example.com"
scripts/crawl4ai.sh markdown "https://example.com" --fit
scripts/crawl4ai.sh crawl "https://docs.example.com" --max-pages 10
scripts/crawl4ai.sh screenshot "https://example.com" --output screenshot.png
```
