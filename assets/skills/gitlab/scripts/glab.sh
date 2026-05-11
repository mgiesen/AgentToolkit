#!/usr/bin/env bash
# Wrapper fuer glab: laedt GITLAB_TOKEN und GITLAB_HOST aus der Repo-.env
# und ruft anschliessend das System-glab mit den uebergebenen Argumenten auf.
set -euo pipefail

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
ENV_FILE="$REPO_ROOT/.env"

if [[ -f "$ENV_FILE" ]]; then
    set -a
    # shellcheck source=/dev/null
    source "$ENV_FILE"
    set +a
fi

# Leere Werte aus der .env nicht als gesetzt durchreichen.
if [[ "${GITLAB_TOKEN-}" == "" ]]; then
    unset GITLAB_TOKEN
fi
if [[ "${GITLAB_HOST-}" == "" ]]; then
    unset GITLAB_HOST
fi

if ! command -v glab >/dev/null 2>&1; then
    echo "Fehler: glab CLI nicht gefunden. Installation: brew install glab" >&2
    exit 127
fi

if [[ -z "${GITLAB_TOKEN-}" ]]; then
    echo "Hinweis: GITLAB_TOKEN ist nicht in $ENV_FILE gesetzt." >&2
    echo "         Lese-Operationen auf oeffentliche Repos funktionieren teils ohne Token," >&2
    echo "         alles Weitere benoetigt einen Personal Access Token." >&2
fi

exec glab "$@"
