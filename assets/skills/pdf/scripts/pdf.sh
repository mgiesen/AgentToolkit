#!/usr/bin/env bash
set -euo pipefail

# PDF Skill – cpdf/qpdf/ghostscript Wrapper

usage() {
    echo "Usage: pdf.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  merge <files...> --output OUT          PDFs zusammenfuehren"
    echo "  split <file> --output-dir DIR           In Einzelseiten aufteilen"
    echo "  extract <file> --pages P --output OUT   Seiten extrahieren"
    echo "  compress <file> --output OUT [--quality] Komprimieren"
    echo "  encrypt <file> --password PW --output OUT"
    echo "  decrypt <file> --password PW --output OUT"
    echo "  info <file>                             Metadaten anzeigen"
    exit 1
}

require_file() {
    [[ -f "$1" ]] || { echo "Fehler: Datei nicht gefunden: $1" >&2; exit 1; }
}

cmd_merge() {
    local output="" files=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) output="$2"; shift 2 ;;
            *) files+=("$1"); shift ;;
        esac
    done

    [[ ${#files[@]} -lt 2 ]] && { echo "Fehler: Mindestens 2 Dateien angeben" >&2; exit 1; }
    [[ -z "$output" ]] && { echo "Fehler: --output erforderlich" >&2; exit 1; }

    for f in "${files[@]}"; do require_file "$f"; done

    cpdf -merge "${files[@]}" -o "$output"
    echo "Erstellt: $output (${#files[@]} Dateien zusammengefuehrt)"
}

cmd_split() {
    local file="" output_dir=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output-dir) output_dir="$2"; shift 2 ;;
            *) file="$1"; shift ;;
        esac
    done

    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    require_file "$file"
    [[ -z "$output_dir" ]] && { echo "Fehler: --output-dir erforderlich" >&2; exit 1; }

    mkdir -p "$output_dir"
    local basename="${file##*/}"
    basename="${basename%.pdf}"

    local pages
    pages=$(cpdf -pages "$file")

    for ((i=1; i<=pages; i++)); do
        cpdf "$file" "$i" -o "${output_dir}/${basename}_$(printf '%03d' $i).pdf"
    done
    echo "Erstellt: $pages Seiten in $output_dir/"
}

cmd_extract() {
    local file="" pages="" output=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pages) pages="$2"; shift 2 ;;
            --output) output="$2"; shift 2 ;;
            *) file="$1"; shift ;;
        esac
    done

    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    require_file "$file"
    [[ -z "$pages" ]] && { echo "Fehler: --pages erforderlich" >&2; exit 1; }
    [[ -z "$output" ]] && { echo "Fehler: --output erforderlich" >&2; exit 1; }

    # Komma-Notation in cpdf-Ranges umwandeln: "1-3,7,12" → "1-3 AND 7 AND 12"
    local cpdf_range="${pages//,/ AND }"
    cpdf "$file" $cpdf_range -o "$output"
    echo "Erstellt: $output (Seiten: $pages)"
}

cmd_compress() {
    local file="" output="" quality="ebook"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) output="$2"; shift 2 ;;
            --quality) quality="$2"; shift 2 ;;
            *) file="$1"; shift ;;
        esac
    done

    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    require_file "$file"
    [[ -z "$output" ]] && { echo "Fehler: --output erforderlich" >&2; exit 1; }

    local size_before size_after
    size_before=$(stat -f%z "$file")

    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 \
       -dPDFSETTINGS="/$quality" -dNOPAUSE -dBATCH -dQUIET \
       -sOutputFile="$output" "$file"

    size_after=$(stat -f%z "$output")
    local pct=$((100 - (size_after * 100 / size_before)))
    echo "Erstellt: $output (${pct}% kleiner, Quality: $quality)"
}

cmd_encrypt() {
    local file="" password="" output=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --password) password="$2"; shift 2 ;;
            --output) output="$2"; shift 2 ;;
            *) file="$1"; shift ;;
        esac
    done

    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    require_file "$file"
    [[ -z "$password" ]] && { echo "Fehler: --password erforderlich" >&2; exit 1; }
    [[ -z "$output" ]] && { echo "Fehler: --output erforderlich" >&2; exit 1; }

    qpdf --encrypt "$password" "$password" 256 -- "$file" "$output"
    echo "Erstellt: $output (AES-256 verschluesselt)"
}

cmd_decrypt() {
    local file="" password="" output=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --password) password="$2"; shift 2 ;;
            --output) output="$2"; shift 2 ;;
            *) file="$1"; shift ;;
        esac
    done

    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    require_file "$file"
    [[ -z "$password" ]] && { echo "Fehler: --password erforderlich" >&2; exit 1; }
    [[ -z "$output" ]] && { echo "Fehler: --output erforderlich" >&2; exit 1; }

    qpdf --password="$password" --decrypt "$file" "$output"
    echo "Erstellt: $output (entschluesselt)"
}

cmd_info() {
    local file="$1"
    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    require_file "$file"

    echo "=== $file ==="
    echo "Seiten: $(cpdf -pages "$file")"
    echo ""
    cpdf -info "$file" 2>/dev/null || true
    echo ""
    echo "Dateigroesse: $(stat -f%z "$file" | awk '{printf "%.1f MB", $1/1048576}')"
}

[[ $# -lt 1 ]] && usage

command="$1"; shift
case "$command" in
    merge)      cmd_merge "$@" ;;
    split)      cmd_split "$@" ;;
    extract)    cmd_extract "$@" ;;
    compress)   cmd_compress "$@" ;;
    encrypt)    cmd_encrypt "$@" ;;
    decrypt)    cmd_decrypt "$@" ;;
    info)       cmd_info "$@" ;;
    *)          usage ;;
esac
