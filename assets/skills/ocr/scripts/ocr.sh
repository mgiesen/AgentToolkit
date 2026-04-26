#!/usr/bin/env bash
set -euo pipefail

# OCR Skill
# macOS: Apple Vision Framework (swift, keine Abhaengigkeiten)
# Fallback: Tesseract (cross-platform)

usage() {
    echo "Usage: ocr.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  extract <file> [--lang LANG]              Text aus Bild/PDF extrahieren"
    echo "  to-pdf <file> --output OUT [--lang LANG]   Bild → durchsuchbare PDF (nur Tesseract)"
    exit 1
}

require_file() {
    [[ -f "$1" ]] || { echo "Fehler: Datei nicht gefunden: $1" >&2; exit 1; }
}

# macOS Vision OCR via Swift (kein externes Tool noetig)
vision_extract() {
    local file="$1" lang="${2:-de-DE}"

    swift - "$file" "$lang" <<'SWIFT'
import Vision
import Foundation
import CoreImage

let args = CommandLine.arguments
let filePath = args[1]
let lang = args[2]
let url = URL(fileURLWithPath: filePath)

guard let ciImage = CIImage(contentsOf: url) else {
    fputs("Fehler: Datei konnte nicht geladen werden: \(filePath)\n", stderr)
    exit(1)
}

let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.recognitionLanguages = lang.components(separatedBy: "+")
request.usesLanguageCorrection = true

try handler.perform([request])

let results = request.results ?? []
for observation in results {
    if let candidate = observation.topCandidates(1).first {
        print(candidate.string)
    }
}
SWIFT
}

# PDF-Seiten via Ghostscript in PNGs, dann Vision OCR
vision_extract_pdf() {
    local pdf="$1" lang="${2:-de-DE}"
    local tmpdir
    tmpdir=$(mktemp -d)
    trap "rm -rf '$tmpdir'" EXIT

    gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r300 -dTextAlphaBits=4 \
       -sOutputFile="${tmpdir}/page_%04d.png" "$pdf" >/dev/null 2>&1

    for img in "$tmpdir"/page_*.png; do
        [[ -f "$img" ]] && vision_extract "$img" "$lang"
    done
}

# Tesseract Fallback (Windows/Linux)
tesseract_extract() {
    local file="$1" lang="${2:-deu}"
    local ext
    ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')

    if [[ "$ext" == "pdf" ]]; then
        local tmpdir
        tmpdir=$(mktemp -d)
        trap "rm -rf '$tmpdir'" EXIT
        gs -dNOPAUSE -dBATCH -sDEVICE=png16m -r300 -dTextAlphaBits=4 \
           -sOutputFile="${tmpdir}/page_%04d.png" "$file" >/dev/null 2>&1
        for img in "$tmpdir"/page_*.png; do
            [[ -f "$img" ]] && tesseract "$img" stdout -l "$lang" --psm 6 2>/dev/null
        done
    else
        tesseract "$file" stdout -l "$lang" 2>/dev/null
    fi
}

# Sprach-Mapping: Vision (de-DE) vs Tesseract (deu)
to_vision_lang() {
    case "$1" in
        deu|de) echo "de-DE" ;;
        eng|en) echo "en-US" ;;
        fra|fr) echo "fr-FR" ;;
        spa|es) echo "es-ES" ;;
        ita|it) echo "it-IT" ;;
        *)      echo "$1" ;;
    esac
}

to_tesseract_lang() {
    case "$1" in
        de-DE|de) echo "deu" ;;
        en-US|en) echo "eng" ;;
        fr-FR|fr) echo "fra" ;;
        es-ES|es) echo "spa" ;;
        it-IT|it) echo "ita" ;;
        *)        echo "$1" ;;
    esac
}

cmd_extract() {
    local file="" lang=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --lang) lang="$2"; shift 2 ;;
            *) file="$1"; shift ;;
        esac
    done

    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    require_file "$file"

    local ext
    ext=$(echo "${file##*.}" | tr '[:upper:]' '[:lower:]')

    if [[ "$(uname)" == "Darwin" ]]; then
        lang=$(to_vision_lang "${lang:-de}")
        if [[ "$ext" == "pdf" ]]; then
            vision_extract_pdf "$file" "$lang"
        else
            vision_extract "$file" "$lang"
        fi
    else
        lang=$(to_tesseract_lang "${lang:-de}")
        tesseract_extract "$file" "$lang"
    fi
}

cmd_to_pdf() {
    local file="" output="" lang=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --output) output="$2"; shift 2 ;;
            --lang) lang="$2"; shift 2 ;;
            *) file="$1"; shift ;;
        esac
    done

    [[ -z "$file" ]] && { echo "Fehler: Keine Datei angegeben" >&2; exit 1; }
    [[ -z "$output" ]] && { echo "Fehler: --output erforderlich" >&2; exit 1; }
    require_file "$file"

    lang=$(to_tesseract_lang "${lang:-de}")
    local out_base="${output%.pdf}"
    tesseract "$file" "$out_base" -l "$lang" pdf 2>/dev/null
    echo "Erstellt: ${out_base}.pdf"
}

[[ $# -lt 1 ]] && usage

command="$1"; shift
case "$command" in
    extract)   cmd_extract "$@" ;;
    to-pdf)    cmd_to_pdf "$@" ;;
    *)         usage ;;
esac
