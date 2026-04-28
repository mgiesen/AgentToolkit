#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a; source "$REPO_ROOT/.env"; set +a
fi

: "${GEMINI_IMAGE_GEN_API_KEY:?GEMINI_IMAGE_GEN_API_KEY nicht gesetzt. Siehe .env.example}"

prompt="" output="" ratio="1:1" res="1k" mode=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) output="$2"; shift 2 ;;
        -a|--aspect-ratio) ratio="$2"; shift 2 ;;
        -r|--resolution) res="$2"; shift 2 ;;
        -m|--model) mode="$2"; shift 2 ;;
        *) prompt="$1"; shift ;;
    esac
done
[[ -z "$prompt" || -z "$output" || -z "$mode" ]] && { echo "Usage: image-gen.sh <prompt> -o FILE -m hochwertig|schnell [-a RATIO] [-r RES]" >&2; exit 1; }

case "$mode" in
    hochwertig) model="gemini-3-pro-image-preview" ;;
    schnell)    model="gemini-3.1-flash-image-preview" ;;
    *)          echo "ERR: -m muss 'hochwertig' oder 'schnell' sein" >&2; exit 1 ;;
esac

mkdir -p "$(dirname "$output")"

python3 - "$prompt" "$ratio" "$res" "$output" "$GEMINI_IMAGE_GEN_API_KEY" "$model" <<'PY'
import json, base64, sys, urllib.request

prompt, ratio, res, output, key, model = sys.argv[1:7]
url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={key}"

payload = json.dumps({
    "contents": [{"parts": [{"text": f"{prompt}. Aspect ratio: {ratio}. Resolution: {res}"}]}],
    "generationConfig": {"responseModalities": ["image", "text"]},
}).encode()

try:
    resp = urllib.request.urlopen(
        urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"}),
        timeout=90
    )
    r = json.loads(resp.read())
except urllib.error.HTTPError as e:
    body = json.loads(e.read())
    print(f"ERR {e.code}: {body.get('error',{}).get('message','')[:120]}", file=sys.stderr)
    sys.exit(1)

usage = r.get("usageMetadata", {})
tok_in = usage.get("promptTokenCount", "?")
tok_out = usage.get("candidatesTokenCount", "?")

for part in r.get("candidates", [{}])[0].get("content", {}).get("parts", []):
    if "inlineData" in part:
        data = base64.b64decode(part["inlineData"]["data"])
        with open(output, "wb") as f:
            f.write(data)
        print(f"OK {output} | {len(data)//1024} KB | {model} | tokens: {tok_in} in, {tok_out} out")
        sys.exit(0)

print("ERR: Kein Bild in der Antwort", file=sys.stderr)
sys.exit(1)
PY
