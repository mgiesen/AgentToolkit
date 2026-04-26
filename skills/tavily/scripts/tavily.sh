#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: tavily.sh <command> [args]

Commands:
  status                         Show Tavily CLI auth status
  auth                           Check authentication details
  search <query> [options]       Discover sources and current web results
  research <query> [options]     Run Tavily Deep Research
  research-status <request_id>   Check async research status
  research-poll <request_id>     Poll async research until completion

Intentionally unsupported here:
  extract, map, crawl            Use crawl4ai or local tools for known URLs/sites

Defaults:
  search/research/research-poll add --json unless --json, --human, or --stream is passed.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TVLY="$REPO_ROOT/.venv/bin/tvly"
ENV_FILE="$REPO_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
fi

if [[ "${TAVILY_API_KEY-}" == "" ]]; then
    unset TAVILY_API_KEY
fi

if [[ ! -x "$TVLY" ]]; then
    echo "Fehler: Tavily CLI nicht in der Repo-Venv gefunden." >&2
    echo "Ausfuehren: cd $REPO_ROOT && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt" >&2
    exit 1
fi

json_default_args() {
    local saw_json=0
    local human=0
    local stream=0
    ARGS=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json)
                saw_json=1
                ARGS+=("$1")
                shift
                ;;
            --human)
                human=1
                shift
                ;;
            --stream)
                stream=1
                ARGS+=("$1")
                shift
                ;;
            *)
                ARGS+=("$1")
                shift
                ;;
        esac
    done

    if [[ "$saw_json" -eq 0 && "$human" -eq 0 && "$stream" -eq 0 ]]; then
        ARGS+=(--json)
    fi
}

cmd="${1:-}"
if [[ -z "$cmd" ]]; then
    usage
    exit 2
fi
shift

case "$cmd" in
    status)
        exec "$TVLY" --status
        ;;
    auth)
        exec "$TVLY" auth
        ;;
    search)
        [[ $# -eq 0 ]] && usage && exit 2
        json_default_args "$@"
        exec "$TVLY" search "${ARGS[@]}"
        ;;
    research)
        [[ $# -eq 0 ]] && usage && exit 2
        json_default_args "$@"
        exec "$TVLY" research run "${ARGS[@]}"
        ;;
    research-status)
        [[ $# -eq 0 ]] && usage && exit 2
        exec "$TVLY" research status "$@"
        ;;
    research-poll)
        [[ $# -eq 0 ]] && usage && exit 2
        json_default_args "$@"
        exec "$TVLY" research poll "${ARGS[@]}"
        ;;
    extract|map|crawl)
        echo "Fehler: '$cmd' ist in diesem Skill absichtlich deaktiviert." >&2
        echo "Nutze fuer bekannte URLs, Site-Strukturen und Crawling crawl4ai oder lokale Tools." >&2
        exit 2
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        echo "Fehler: Unbekannter Befehl: $cmd" >&2
        usage >&2
        exit 2
        ;;
esac
