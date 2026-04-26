---
name: crawl4ai
description: Web-Scraping und Markdown-Extraktion aus Webseiten via crwl CLI.
---

# crawl4ai

Webseiten crawlen und als sauberes, LLM-optimiertes Markdown extrahieren.

```bash
scripts/crawl4ai.sh markdown "https://example.com"
scripts/crawl4ai.sh markdown "https://example.com" --fit
scripts/crawl4ai.sh crawl "https://docs.example.com" --max-pages 10
scripts/crawl4ai.sh screenshot "https://example.com" --output screenshot.png
```
