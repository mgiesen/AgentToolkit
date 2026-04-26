#!/usr/bin/env bash
set -euo pipefail

# YouTube-dlp Skill Wrapper
# Fokus: Metadaten, Untertitel und Transkripte ressourcenschonend abrufen.

usage() {
    echo "Usage: youtube-dlp.sh <command> <url-or-query> [options]"
    echo ""
    echo "Commands:"
    echo "  info <url> [--json] [--cookies-from-browser BROWSER]"
    echo "  formats <url> [--cookies-from-browser BROWSER]"
    echo "  subs <url> [--cookies-from-browser BROWSER]"
    echo "  transcript <url> [--lang LANGS] [--official|--auto] [--format txt|srt|vtt] [--output FILE] [--cookies-from-browser BROWSER]"
    echo "  search <query> [--limit N] [--json]"
    echo "  playlist <url> [--limit N] [--json] [--cookies-from-browser BROWSER]"
    echo "  audio <url> [--format m4a|mp3|opus|wav] [--output-dir DIR] [--cookies-from-browser BROWSER]"
    echo "  video <url> [--preset mp4|mkv] [--output-dir DIR] [--cookies-from-browser BROWSER]"
    exit 1
}

require_yt_dlp() {
    if ! command -v yt-dlp >/dev/null 2>&1; then
        echo "Fehler: yt-dlp nicht installiert. macOS: brew install yt-dlp" >&2
        exit 1
    fi
}

require_ffmpeg() {
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "Fehler: ffmpeg ist fuer diese Operation erforderlich. macOS: brew install ffmpeg" >&2
        exit 1
    fi
}

add_cookies_arg() {
    local browser="$1"
    if [[ -n "$browser" ]]; then
        YTDLP_ARGS+=(--cookies-from-browser "$browser")
    fi
}

print_info_summary() {
    python3 -c '
import json, sys
data = json.load(sys.stdin)
if not isinstance(data, dict):
    sys.exit("Fehler: Unerwartete yt-dlp JSON-Ausgabe")
fields = [
    ("title", "Titel"),
    ("uploader", "Kanal"),
    ("channel_url", "Kanal-URL"),
    ("upload_date", "Upload"),
    ("duration_string", "Dauer"),
    ("view_count", "Views"),
    ("webpage_url", "URL"),
]
for key, label in fields:
    value = data.get(key)
    if value is not None:
        print(f"{label}: {value}")
description = (data.get("description") or "").strip()
if description:
    print("\nBeschreibung:")
    print(description[:4000])
'
}

print_flat_entries() {
    python3 -c '
import json, sys
data = json.load(sys.stdin)
if not isinstance(data, dict):
    sys.exit("Fehler: Unerwartete yt-dlp JSON-Ausgabe")
entries = data.get("entries") or []
for i, item in enumerate(entries, 1):
    if not item:
        continue
    title = item.get("title") or ""
    url = item.get("url") or item.get("webpage_url") or item.get("id") or ""
    if url and not str(url).startswith(("http://", "https://")):
        url = "https://www.youtube.com/watch?v=" + str(url)
    uploader = item.get("uploader") or item.get("channel") or ""
    duration = item.get("duration_string") or ""
    bits = [f"{i}. {title}"]
    meta = " | ".join(x for x in [uploader, duration] if x)
    if meta:
        bits.append(f"   {meta}")
    if url:
        bits.append(f"   {url}")
    print("\n".join(bits))
'
}

clean_subtitle_to_text() {
    local file="$1"
    python3 - "$file" <<'PY'
import html
import re
import sys

path = sys.argv[1]
last = None

with open(path, "r", encoding="utf-8", errors="replace") as f:
    for raw in f:
        line = raw.strip()
        if not line:
            continue
        if line in {"WEBVTT", "Kind: captions", "Kind: subtitles"}:
            continue
        if line.startswith(("Language:", "NOTE", "STYLE", "REGION")):
            continue
        if "-->" in line:
            continue
        if re.fullmatch(r"\d+", line):
            continue
        line = re.sub(r"<[^>]+>", "", line)
        line = re.sub(r"\{\\.*?\}", "", line)
        line = html.unescape(line).strip()
        if not line or line == last:
            continue
        print(line)
        last = line
PY
}

find_subtitle_file() {
    local dir="$1"
    find "$dir" -type f \( -name "*.vtt" -o -name "*.srt" -o -name "*.ass" -o -name "*.lrc" \) | sort | head -n 1
}

download_subtitle() {
    local url="$1" lang="$2" mode="$3" format="$4" tmpdir="$5" cookies_browser="$6"
    local args=(--skip-download --no-playlist --sub-langs "$lang" --paths "$tmpdir" -o "%(id)s.%(ext)s")

    if [[ "$mode" == "official" ]]; then
        args+=(--write-subs)
    else
        args+=(--write-auto-subs)
    fi

    if [[ "$format" == "srt" ]]; then
        args+=(--sub-format "srt/vtt/best" --convert-subs srt)
    elif [[ "$format" == "vtt" || "$format" == "txt" ]]; then
        args+=(--sub-format "vtt/srt/best")
    else
        args+=(--sub-format "$format")
    fi

    if [[ -n "$cookies_browser" ]]; then
        args+=(--cookies-from-browser "$cookies_browser")
    fi

    yt-dlp "${args[@]}" "$url" >/dev/null
}

cmd_info() {
    local url="" json_mode=0 cookies_browser=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) json_mode=1; shift ;;
            --cookies-from-browser) cookies_browser="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    [[ -z "$url" ]] && usage

    YTDLP_ARGS=(--skip-download --no-playlist --dump-single-json)
    add_cookies_arg "$cookies_browser"

    if [[ "$json_mode" -eq 1 ]]; then
        yt-dlp "${YTDLP_ARGS[@]}" "$url"
    else
        local info_json
        info_json=$(yt-dlp "${YTDLP_ARGS[@]}" "$url")
        printf '%s\n' "$info_json" | print_info_summary
    fi
}

cmd_formats() {
    local url="" cookies_browser=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cookies-from-browser) cookies_browser="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    [[ -z "$url" ]] && usage

    YTDLP_ARGS=(-F --no-playlist)
    add_cookies_arg "$cookies_browser"
    yt-dlp "${YTDLP_ARGS[@]}" "$url"
}

cmd_subs() {
    local url="" cookies_browser=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cookies-from-browser) cookies_browser="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    [[ -z "$url" ]] && usage

    YTDLP_ARGS=(--skip-download --list-subs --no-playlist)
    add_cookies_arg "$cookies_browser"
    yt-dlp "${YTDLP_ARGS[@]}" "$url"
}

cmd_transcript() {
    local url="" lang="de,en" mode="prefer-official" format="txt" output="" cookies_browser=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lang|--sub-langs) lang="$2"; shift 2 ;;
            --official) mode="official"; shift ;;
            --auto) mode="auto"; shift ;;
            --format) format="$2"; shift 2 ;;
            --output) output="$2"; shift 2 ;;
            --cookies-from-browser) cookies_browser="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    [[ -z "$url" ]] && usage
    [[ "$format" =~ ^(txt|srt|vtt)$ ]] || { echo "Fehler: --format muss txt, srt oder vtt sein" >&2; exit 1; }
    [[ "$format" == "txt" || "$format" == "vtt" ]] || require_ffmpeg

    local tmpdir subtitle
    tmpdir=$(mktemp -d)
    trap "rm -rf '$tmpdir'" EXIT

    if [[ "$mode" == "prefer-official" ]]; then
        if ! download_subtitle "$url" "$lang" "official" "$format" "$tmpdir" "$cookies_browser" 2>/dev/null; then
            true
        fi
        subtitle=$(find_subtitle_file "$tmpdir" || true)
        if [[ -z "$subtitle" ]]; then
            download_subtitle "$url" "$lang" "auto" "$format" "$tmpdir" "$cookies_browser"
            subtitle=$(find_subtitle_file "$tmpdir" || true)
        fi
    else
        download_subtitle "$url" "$lang" "$mode" "$format" "$tmpdir" "$cookies_browser"
        subtitle=$(find_subtitle_file "$tmpdir" || true)
    fi

    if [[ -z "$subtitle" ]]; then
        echo "Fehler: Keine Untertitel fuer Sprache(n) gefunden: $lang" >&2
        exit 1
    fi

    if [[ -z "$output" ]]; then
        if [[ "$format" == "txt" ]]; then
            clean_subtitle_to_text "$subtitle"
        else
            cat "$subtitle"
        fi
        return
    fi

    if [[ "$format" == "txt" ]]; then
        clean_subtitle_to_text "$subtitle" > "$output"
    else
        cp "$subtitle" "$output"
    fi
    echo "Erstellt: $output"
}

cmd_search() {
    local query="" limit=5 json_mode=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) limit="$2"; shift 2 ;;
            --json) json_mode=1; shift ;;
            *) query="$1"; shift ;;
        esac
    done
    [[ -z "$query" ]] && usage

    if [[ "$json_mode" -eq 1 ]]; then
        yt-dlp --skip-download --flat-playlist --dump-single-json "ytsearch${limit}:${query}"
    else
        local search_json
        search_json=$(yt-dlp --skip-download --flat-playlist --dump-single-json "ytsearch${limit}:${query}")
        printf '%s\n' "$search_json" | print_flat_entries
    fi
}

cmd_playlist() {
    local url="" limit="" json_mode=0 cookies_browser=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --limit) limit="$2"; shift 2 ;;
            --json) json_mode=1; shift ;;
            --cookies-from-browser) cookies_browser="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    [[ -z "$url" ]] && usage

    YTDLP_ARGS=(--skip-download --flat-playlist --dump-single-json)
    if [[ -n "$limit" ]]; then
        YTDLP_ARGS+=(--playlist-end "$limit")
    fi
    add_cookies_arg "$cookies_browser"

    if [[ "$json_mode" -eq 1 ]]; then
        yt-dlp "${YTDLP_ARGS[@]}" "$url"
    else
        local playlist_json
        playlist_json=$(yt-dlp "${YTDLP_ARGS[@]}" "$url")
        printf '%s\n' "$playlist_json" | print_flat_entries
    fi
}

cmd_audio() {
    local url="" audio_format="m4a" output_dir="." cookies_browser=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --format) audio_format="$2"; shift 2 ;;
            --output-dir) output_dir="$2"; shift 2 ;;
            --cookies-from-browser) cookies_browser="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    [[ -z "$url" ]] && usage
    require_ffmpeg

    YTDLP_ARGS=(-x --audio-format "$audio_format" -P "$output_dir" -o "%(title)s [%(id)s].%(ext)s" --no-playlist)
    add_cookies_arg "$cookies_browser"
    yt-dlp "${YTDLP_ARGS[@]}" "$url"
}

cmd_video() {
    local url="" preset="mp4" output_dir="." cookies_browser=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --preset) preset="$2"; shift 2 ;;
            --output-dir) output_dir="$2"; shift 2 ;;
            --cookies-from-browser) cookies_browser="$2"; shift 2 ;;
            *) url="$1"; shift ;;
        esac
    done
    [[ -z "$url" ]] && usage
    [[ "$preset" =~ ^(mp4|mkv)$ ]] || { echo "Fehler: --preset muss mp4 oder mkv sein" >&2; exit 1; }

    YTDLP_ARGS=(-t "$preset" -P "$output_dir" -o "%(title)s [%(id)s].%(ext)s" --no-playlist)
    add_cookies_arg "$cookies_browser"
    yt-dlp "${YTDLP_ARGS[@]}" "$url"
}

[[ $# -lt 1 ]] && usage
require_yt_dlp

command="$1"; shift
case "$command" in
    info)       cmd_info "$@" ;;
    formats)    cmd_formats "$@" ;;
    subs)       cmd_subs "$@" ;;
    transcript) cmd_transcript "$@" ;;
    search)     cmd_search "$@" ;;
    playlist)   cmd_playlist "$@" ;;
    audio)      cmd_audio "$@" ;;
    video)      cmd_video "$@" ;;
    *)          usage ;;
esac
