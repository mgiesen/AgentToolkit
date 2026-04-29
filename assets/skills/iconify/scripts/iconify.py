#!/usr/bin/env python3
"""Token-efficient Iconify search and SVG download helper."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import urllib.parse
from pathlib import Path
from types import SimpleNamespace
from typing import Any

import requests

API_BASE = os.environ.get("ICONIFY_API_BASE", "https://api.iconify.design").rstrip("/")
DEFAULT_PREFER = ["lucide", "tabler", "ph", "heroicons", "radix-icons", "carbon", "mdi"]
DEFAULT_PREFIXES = ["lucide", "tabler", "ph", "mdi", "carbon"]
DEFAULT_TIMEOUT = float(os.environ.get("ICONIFY_TIMEOUT", "10"))
USER_AGENT = "AgentBox-Iconify/1.0"
SESSION = requests.Session()
SESSION.headers.update({"User-Agent": USER_AGENT})


class IconifyError(RuntimeError):
    """Raised for expected Iconify lookup and network errors."""


def die(message: str) -> None:
    raise IconifyError(message)


def split_csv(value: str | None) -> list[str]:
    if not value:
        return []
    return [item.strip() for item in value.split(",") if item.strip()]


def query_variants(query: str) -> list[str]:
    normalized = " ".join(query.strip().lower().split())
    variants = [normalized] if normalized else []
    terms = query_terms(normalized)
    for size in range(len(terms) - 1, 1, -1):
        for start in range(0, len(terms) - size + 1):
            phrase = " ".join(terms[start : start + size])
            if phrase and phrase not in variants:
                variants.append(phrase)
    for token in terms:
        if token and token not in variants:
            variants.append(token)
    return variants


def icon_parts(icon_id: str) -> tuple[str, str]:
    if ":" not in icon_id:
        die(f"icon must be PREFIX:NAME, got {icon_id!r}")
    prefix, name = icon_id.split(":", 1)
    if not prefix or not name:
        die(f"icon must be PREFIX:NAME, got {icon_id!r}")
    if not re.fullmatch(r"[a-z0-9-]+", prefix):
        die(f"invalid icon prefix: {prefix!r}")
    if not re.fullmatch(r"[a-z0-9-]+", name):
        die(f"invalid icon name: {name!r}")
    return prefix, name


def compact_params(params: dict[str, Any] | None = None) -> dict[str, str]:
    clean: dict[str, str] = {}
    for key, value in (params or {}).items():
        if value is None or value is False:
            continue
        clean[key] = "1" if value is True else str(value)
    return clean


def build_url(path: str, params: dict[str, Any] | None = None) -> str:
    url = f"{API_BASE}{path}"
    clean = compact_params(params)
    if clean:
        url = f"{url}?{urllib.parse.urlencode(clean)}"
    return url


def fetch_response(path: str, params: dict[str, Any] | None = None) -> requests.Response:
    url = f"{API_BASE}{path}"
    try:
        response = SESSION.get(url, params=compact_params(params), timeout=DEFAULT_TIMEOUT)
        response.raise_for_status()
        return response
    except requests.Timeout:
        die("Iconify API timeout")
    except requests.HTTPError as exc:
        body = exc.response.text[:300] if exc.response is not None else ""
        status = exc.response.status_code if exc.response is not None else "unknown"
        die(f"Iconify API returned HTTP {status} for {url}: {body}")
    except requests.RequestException as exc:
        die(f"could not reach Iconify API: {exc}")


def fetch_json(path: str, params: dict[str, Any]) -> dict[str, Any]:
    try:
        return fetch_response(path, params).json()
    except ValueError as exc:
        die(f"Iconify API returned invalid JSON for {path}: {exc}")


def fetch_svg_icon(query: str) -> str:
    """
    Return raw SVG for the best matching UI icon query.

    This importable helper mirrors the CLI `fetch` command and expects English
    Iconify search terms.
    """
    clean_query = " ".join(query.strip().lower().split())
    if not clean_query:
        return "No icon found: empty query."

    args = SimpleNamespace(
        query=clean_query,
        limit=1,
        prefixes=",".join(DEFAULT_PREFIXES),
        prefer=",".join(DEFAULT_PREFER),
        palette="mono",
        color=None,
        width=None,
        height=None,
        flip=None,
        rotate=None,
        box=False,
    )

    try:
        rows = search_icons(args)
        if not rows:
            return f"No icon found for '{clean_query}'. Try an English visual synonym."
        svg, _url = fetch_svg(str(rows[0]["id"]), args)
        return svg
    except IconifyError as exc:
        return f"Icon lookup failed: {exc}."


def query_terms(query: str) -> list[str]:
    return [term for term in re.split(r"[^a-z0-9]+", query.lower()) if term]


def name_tokens(prefix: str, name: str) -> set[str]:
    return {part for part in re.split(r"[^a-z0-9]+", f"{prefix} {name}") if part}


def score_icon(icon_id: str, query: str, index: int, prefer: list[str]) -> int:
    prefix, name = icon_parts(icon_id)
    terms = query_terms(query)
    tokens = name_tokens(prefix, name)
    haystack = f"{prefix}:{name}"
    name_flat = name.replace("-", "")
    query_flat = "".join(terms)

    score = max(0, 80 - index)
    if query_flat and query_flat == name_flat:
        score += 120
    if query_flat and query_flat in name_flat:
        score += 40
    if terms and all(term in tokens or term in name for term in terms):
        score += 60
    for term in terms:
        if term in tokens:
            score += 20
        elif term in name:
            score += 8
    if name in {"home", "search", "settings", "user", "calendar", "trash", "edit", "plus", "minus"}:
        score += 8
    if prefix in prefer:
        score += (len(prefer) - prefer.index(prefix)) * 6
    if any(word in haystack for word in ("outline", "regular", "linear", "line")):
        score += 4
    if any(word in haystack for word in ("deprecated", "old", "legacy")):
        score -= 30
    return score


def search_icons(args: argparse.Namespace) -> list[dict[str, Any]]:
    request_limit = min(999, max(32, args.limit * 5))
    data: dict[str, Any] = {}
    query = ""
    for candidate in query_variants(args.query):
        params: dict[str, Any] = {"query": candidate, "limit": request_limit}
        if args.prefixes:
            params["prefixes"] = args.prefixes
        data = fetch_json("/search", params)
        query = candidate
        if data.get("icons"):
            break
    icons = data.get("icons", [])
    collections = data.get("collections", {})
    prefer = split_csv(args.prefer) or DEFAULT_PREFER
    rows: list[dict[str, Any]] = []

    for index, icon_id in enumerate(icons):
        prefix, name = icon_parts(icon_id)
        info = collections.get(prefix, {})
        palette = bool(info.get("palette", False))
        if args.palette == "mono" and palette:
            continue
        if args.palette == "color" and not palette:
            continue
        license_info = info.get("license", {}) if isinstance(info.get("license", {}), dict) else {}
        rows.append(
            {
                "id": icon_id,
                "score": score_icon(icon_id, query, index, prefer),
                "collection": info.get("name", prefix),
                "license": license_info.get("spdx") or license_info.get("title") or "",
                "palette": "color" if palette else "mono",
                "url": svg_url(prefix, name, args),
            }
        )

    rows.sort(key=lambda row: (-int(row["score"]), str(row["id"])))
    return rows[: args.limit]


def svg_params(args: argparse.Namespace) -> dict[str, Any]:
    return {
        "color": args.color,
        "width": args.width,
        "height": args.height,
        "flip": args.flip,
        "rotate": args.rotate,
        "box": args.box,
    }


def svg_url(prefix: str, name: str, args: argparse.Namespace) -> str:
    safe_prefix = urllib.parse.quote(prefix)
    safe_name = urllib.parse.quote(name)
    return build_url(f"/{safe_prefix}/{safe_name}.svg", svg_params(args))


def fetch_svg(icon_id: str, args: argparse.Namespace) -> tuple[str, str]:
    prefix, name = icon_parts(icon_id)
    path = f"/{urllib.parse.quote(prefix)}/{urllib.parse.quote(name)}.svg"
    params = svg_params(args)
    url = build_url(path, params)
    svg = fetch_response(path, params).text
    if "<svg" not in svg[:200]:
        die(f"Iconify response did not look like SVG for {icon_id}")
    return svg, url


def write_svg(icon_id: str, output: str, args: argparse.Namespace) -> tuple[Path, str]:
    target = Path(output)
    if target.exists() and not args.force:
        die(f"output exists; pass --force to overwrite: {target}")
    svg, url = fetch_svg(icon_id, args)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(svg, encoding="utf-8")
    return target, url


def print_rows(rows: list[dict[str, Any]], as_json: bool) -> None:
    if as_json:
        print(json.dumps(rows, ensure_ascii=False, separators=(",", ":")))
        return
    for row in rows:
        print(
            f"{row['id']}\t{row['score']}\t{row['palette']}\t"
            f"{row['license']}\t{row['collection']}\t{row['url']}"
        )


def cmd_search(args: argparse.Namespace) -> None:
    rows = search_icons(args)
    if not rows:
        die("no matching icons found")
    print_rows(rows, args.json)


def cmd_pick(args: argparse.Namespace) -> None:
    rows = search_icons(args)
    if not rows:
        die("no matching icons found")
    chosen = rows[0]
    path, _url = write_svg(str(chosen["id"]), args.output, args)
    if args.json:
        print(json.dumps({"chosen": chosen, "output": str(path)}, ensure_ascii=False, separators=(",", ":")))
    else:
        print(f"chosen\t{chosen['id']}\t{chosen['score']}\t{chosen['license']}\t{path}")


def cmd_download(args: argparse.Namespace) -> None:
    path, url = write_svg(args.icon, args.output, args)
    if args.json:
        print(json.dumps({"icon": args.icon, "output": str(path), "url": url}, ensure_ascii=False, separators=(",", ":")))
    else:
        print(f"downloaded\t{args.icon}\t{path}")


def cmd_url(args: argparse.Namespace) -> None:
    prefix, name = icon_parts(args.icon)
    print(svg_url(prefix, name, args))


def cmd_show(args: argparse.Namespace) -> None:
    svg, _url = fetch_svg(args.icon, args)
    print(svg)


def cmd_fetch(args: argparse.Namespace) -> None:
    rows = search_icons(args)
    if not rows:
        die("no matching icons found")
    svg, _url = fetch_svg(str(rows[0]["id"]), args)
    print(svg)


def add_svg_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--width", help="SVG width, e.g. 24, 1em, auto, unset")
    parser.add_argument("--height", help="SVG height, e.g. 24, 1em, auto, unset")
    parser.add_argument("--color", help="hard-code color; omit to keep currentColor")
    parser.add_argument("--flip", choices=["horizontal", "vertical", "horizontal,vertical", "vertical,horizontal"])
    parser.add_argument("--rotate", help="90deg, 180deg, 270deg, or 1/2/3")
    parser.add_argument("--box", action="store_true", help="add full viewBox rectangle")


def add_search_options(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("query")
    parser.add_argument("--limit", type=int, default=10, help="number of compact results to print")
    parser.add_argument("--prefixes", help="comma-separated icon sets to restrict search")
    parser.add_argument("--prefer", help="comma-separated icon sets to boost in ranking")
    parser.add_argument("--palette", choices=["mono", "color", "any"], default="mono")
    parser.add_argument("--json", action="store_true", help="emit compact JSON")
    add_svg_options(parser)


def main() -> None:
    parser = argparse.ArgumentParser(description="Search and download SVGs from Iconify.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    search_parser = subparsers.add_parser("search", help="rank matching icons")
    add_search_options(search_parser)
    search_parser.set_defaults(func=cmd_search)

    pick_parser = subparsers.add_parser("pick", help="search, choose top result, and write SVG")
    add_search_options(pick_parser)
    pick_parser.add_argument("--output", required=True)
    pick_parser.add_argument("--force", action="store_true")
    pick_parser.set_defaults(func=cmd_pick)

    download_parser = subparsers.add_parser("download", help="download a known icon id")
    download_parser.add_argument("icon")
    download_parser.add_argument("--output", required=True)
    download_parser.add_argument("--force", action="store_true")
    download_parser.add_argument("--json", action="store_true")
    add_svg_options(download_parser)
    download_parser.set_defaults(func=cmd_download)

    url_parser = subparsers.add_parser("url", help="print direct SVG URL")
    url_parser.add_argument("icon")
    add_svg_options(url_parser)
    url_parser.set_defaults(func=cmd_url)

    show_parser = subparsers.add_parser("show", help="print SVG to stdout")
    show_parser.add_argument("icon")
    add_svg_options(show_parser)
    show_parser.set_defaults(func=cmd_show)

    fetch_parser = subparsers.add_parser("fetch", help="search top result and print SVG")
    add_search_options(fetch_parser)
    fetch_parser.set_defaults(func=cmd_fetch)

    args = parser.parse_args()
    try:
        if hasattr(args, "limit") and args.limit < 1:
            die("--limit must be >= 1")
        args.func(args)
    except IconifyError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
