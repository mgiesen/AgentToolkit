#!/usr/bin/env bash
set -euo pipefail

# crawl4ai CLI Wrapper

usage() {
    echo "Usage: crawl4ai.sh <command> <url> [options]"
    echo ""
    echo "Commands:"
    echo "  markdown <url> [--fit]           Seite als Markdown extrahieren"
    echo "  crawl <url> [--max-pages N]      Deep-Crawl (BFS)"
    echo "  screenshot <url> --output FILE   Screenshot erstellen"
    exit 1
}

check_deps() {
    if ! command -v crwl &>/dev/null; then
        echo "Fehler: crawl4ai nicht installiert. Ausfuehren:" >&2
        echo "  pip3 install crawl4ai && crawl4ai-setup" >&2
        exit 1
    fi
}

cmd_markdown() {
    local url="$1"; shift
    local format="markdown"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --fit) format="markdown-fit"; shift ;;
            *) shift ;;
        esac
    done

    crwl "$url" -o "$format"
}

cmd_crawl() {
    local url="$1"; shift
    local max_pages=10

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --max-pages) max_pages="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    crwl "$url" --deep-crawl bfs --max-pages "$max_pages" -o markdown-fit
}

cmd_screenshot() {
    local url="$1"; shift
    local output=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) output="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    [[ -z "$output" ]] && { echo "Fehler: --output erforderlich" >&2; exit 1; }

    crwl "$url" -o screenshot -v 2>/dev/null
    # crwl speichert Screenshot im aktuellen Verzeichnis
    local latest
    latest=$(ls -t *.png 2>/dev/null | head -1)
    if [[ -n "$latest" && "$latest" != "$output" ]]; then
        mv "$latest" "$output"
    fi
    echo "Erstellt: $output"
}

[[ $# -lt 2 ]] && usage
check_deps

command="$1"; shift
case "$command" in
    markdown)   cmd_markdown "$@" ;;
    crawl)      cmd_crawl "$@" ;;
    screenshot) cmd_screenshot "$@" ;;
    *)          usage ;;
esac
