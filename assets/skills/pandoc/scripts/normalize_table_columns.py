#!/usr/bin/env python3
"""Normalisiert Tabellen-Spaltenbreiten in pandoc-erzeugtem Typst-Code.

Pandoc generiert Spaltenbreiten basierend auf der Anzahl `-` Zeichen unter
dem Header in Pipe-Tabellen. Wenn ein Header sehr kurz ist (z. B. "Nr"
mit 2 Strichen), wird die Spalte unbrauchbar schmal (<2 %).

Dieses Skript:
  - Erzwingt eine Mindestbreite pro Spalte (default 7 %)
  - Re-normalisiert die Verhältnisse, sodass die Summe wieder 100 % ergibt
  - Konvertiert `columns: N` (Integer) in `columns: (1fr, 1fr, ...)` damit
    die Tabelle die volle Container-Breite einnimmt
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

PCT_PATTERN = re.compile(r"columns:\s*\(([^)]*)\)")
INT_PATTERN = re.compile(r"columns:\s*(\d+)\s*,")
HRULE_PATTERN = re.compile(r"^#let horizontalrule = .*$", re.MULTILINE)
# Eigenständige fettgedruckte Pseudo-Überschriften (z. B. "**Foo**" als
# eigene Markdown-Zeile) — werden in sticky-Blöcke gewickelt, damit sie
# am nachfolgenden Inhalt klebenbleiben (kein Seitenumbruch dazwischen).
STRONG_LINE_PATTERN = re.compile(
    r"(?m)^#strong\[([^\]\n]+)\]\s*$"
)


def normalize_percentages(values: list[float], min_pct: float = 7.0) -> list[float]:
    if not values:
        return values
    n = len(values)
    if min_pct * n >= 100:
        return [100.0 / n] * n

    fixed = [max(v, min_pct) for v in values]
    total = sum(fixed)
    if total <= 100.0:
        scale = 100.0 / total
        return [v * scale for v in fixed]

    excess = total - 100.0
    donors = [(i, v) for i, v in enumerate(fixed) if v > min_pct]
    donor_total = sum(v - min_pct for _, v in donors)
    if donor_total <= 0:
        return [100.0 / n] * n
    result = list(fixed)
    for i, v in donors:
        share = (v - min_pct) / donor_total
        result[i] = max(min_pct, v - excess * share)
    s = sum(result)
    return [r * 100 / s for r in result]


def replace_pct(match: re.Match[str]) -> str:
    inner = match.group(1)
    parts = [p.strip() for p in inner.split(",") if p.strip()]
    values: list[float] = []
    for p in parts:
        if p.endswith("%"):
            try:
                values.append(float(p[:-1]))
            except ValueError:
                return match.group(0)
        else:
            return match.group(0)
    normalized = normalize_percentages(values)
    rendered = ", ".join(f"{v:.2f}%" for v in normalized)
    return f"columns: ({rendered})"


def replace_int(match: re.Match[str]) -> str:
    n = int(match.group(1))
    if n <= 0:
        return match.group(0)
    pct = 100.0 / n
    rendered = ", ".join(f"{pct:.2f}%" for _ in range(n))
    return f"columns: ({rendered}),"


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: normalize_table_columns.py <in.typ> <out.typ>", file=sys.stderr)
        return 2
    src = Path(sys.argv[1]).read_text(encoding="utf-8")
    src = INT_PATTERN.sub(replace_int, src)
    src = PCT_PATTERN.sub(replace_pct, src)
    src = HRULE_PATTERN.sub("#let horizontalrule = []", src)
    src = STRONG_LINE_PATTERN.sub(
        r"#block(sticky: true)[#strong[\1]]", src
    )
    Path(sys.argv[2]).write_text(src, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
