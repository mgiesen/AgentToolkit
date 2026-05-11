---
name: gitlab
version: "1.0"
description: GitLab-Repos, Issues, Merge Requests und CI-Pipelines lesen via glab CLI. IMMER verwenden wenn eine GitLab-URL (gitlab.com/* oder self-hosted) vorkommt oder GitLab-Inhalte abgefragt werden — nie WebFetch fuer GitLab nutzen. Schreibende Operationen nur mit expliziter Einzelfreigabe.
requires:
  bin: [glab]
  key:
    - name: GITLAB_TOKEN
      url: https://gitlab.com/-/user_settings/personal_access_tokens
features:
  - Repos, Issues und Merge Requests eines GitLab-Projekts lesen
  - MR-Diffs und CI-Pipeline-Status abfragen (inkl. Job-Logs streamen)
  - Code und Dateiinhalte direkt über die GitLab API abrufen
  - Repos und Code über GitLab Search durchsuchen
  - Self-hosted GitLab-Instanzen über GITLAB_HOST oder volle URLs ansprechen
  - Schreibende Operationen (Kommentare, Labels, Merges) nur nach expliziter Freigabe
---

# GitLab Skill

Nutze `glab` fuer alle GitLab-Remote-Operationen. Fuer lokale Repos stattdessen `git` verwenden.

GitLab-Begriffe beachten: **Merge Request (MR)** statt Pull Request, **Pipeline** statt Action.

## Authentifizierung

`GITLAB_TOKEN` (und optional `GITLAB_HOST` fuer self-hosted Instanzen) in der Repo-`.env`. Token-Scopes: mindestens `read_api` und `read_repository`; fuer Schreibzugriff zusaetzlich `api` oder `write_repository`.

Den `glab`-Aufruf **immer ueber den Wrapper** machen, damit die `.env` geladen wird:

```bash
./assets/skills/gitlab/scripts/glab.sh <subcommand> ...
```

Das System-`glab` direkt aufzurufen, wuerde die `.env` ignorieren.

## Repo-URL aus dem Kontext ziehen

Bevor ein `glab`-Befehl ausgefuehrt wird, das Ziel-Repo bestimmen:

1. Wenn der Anwender eine GitLab-URL genannt hat → daraus `group/[subgroup/]repo` extrahieren und (bei self-hosted) den Host an `GITLAB_HOST` setzen oder die volle URL als `-R`-Argument uebergeben.
2. Sonst pruefen, ob das aktuelle Arbeitsverzeichnis ein Git-Repo mit GitLab-Remote ist (`git remote get-url origin`). Dann `-R` weglassen — `glab` leitet das Projekt automatisch ab.
3. Wenn weder Punkt 1 noch 2 zutrifft → **explizit beim Anwender nachfragen**, welches Repo gemeint ist. Niemals raten.

## Self-hosted Instanzen

```bash
# Variante A: per Env (einmalig in .env setzen)
GITLAB_HOST=https://gitlab.example.com

# Variante B: pro Befehl per voller URL
./assets/skills/gitlab/scripts/glab.sh repo view https://gitlab.example.com/group/sub/repo
```

## Leseoperationen (jederzeit erlaubt)

```bash
GLAB=./assets/skills/gitlab/scripts/glab.sh

$GLAB repo view group/repo
$GLAB repo view group/repo --output json
$GLAB issue list -R group/repo
$GLAB issue view 123 -R group/repo
$GLAB mr list -R group/repo
$GLAB mr view 123 -R group/repo
$GLAB mr diff 123 -R group/repo
$GLAB repo search -s "query"
$GLAB api "projects/:fullpath/search?scope=blobs&search=query"
$GLAB api "projects/:fullpath/repository/files/PATH%2Fto%2Ffile/raw?ref=main"
$GLAB ci list -R group/repo
$GLAB ci view <pipeline-id> -R group/repo
$GLAB ci trace <job-id> -R group/repo
```

Hinweise:
- Pfade in `glab api .../files/...` muessen URL-encoded sein (`/` → `%2F`).
- `:fullpath` ist ein glab-Placeholder fuer das aktuelle Repo; alternativ vollen Pfad einsetzen.
- JSON-Felder mit `jq` filtern — `glab` hat keinen `--json field1,field2`-Picker wie `gh`.

## Schreiboperationen (Einzelfreigabe erforderlich)

Vor jeder schreibenden Aktion explizit beim Anwender nachfragen. Nie eigenmaechtig ausfuehren.
