---
name: github
description: GitHub-Repos, Issues, PRs und Actions lesen via gh CLI. IMMER verwenden wenn eine GitHub-URL (github.com/*) vorkommt oder GitHub-Inhalte abgefragt werden — nie WebFetch fuer GitHub nutzen. Schreibende Operationen nur mit expliziter Einzelfreigabe.
---

# GitHub Skill

Nutze `gh` fuer alle GitHub-Remote-Operationen. Fuer lokale Repos stattdessen `git` verwenden.

## Leseoperationen (jederzeit erlaubt)

```bash
gh repo view owner/repo
gh repo view owner/repo --json name,description,url
gh issue list -R owner/repo
gh issue view 123 -R owner/repo
gh pr list -R owner/repo
gh pr view 123 -R owner/repo
gh pr diff 123 -R owner/repo
gh search repos "query"
gh search code "query" -R owner/repo
gh api repos/owner/repo/contents/path
gh run list -R owner/repo
```

## Schreiboperationen (Einzelfreigabe erforderlich)

Vor jeder schreibenden Aktion explizit beim Anwender nachfragen. Nie eigenmaechtig ausfuehren.
