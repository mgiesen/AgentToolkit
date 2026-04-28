---
name: geo
description: Berechnet Fahrstrecken, Fahrzeiten, geocodiert Adressen, sucht Orte und erstellt Routen via Google Maps API.
---

# Geo Skill

Ortsbasierte Berechnungen ueber die Google Maps REST API. API-Key wird aus `.env` im Repo-Root geladen.

## Subcommands

### distance

```bash
scripts/geo.sh distance "Krefeld" "Muenchen"
scripts/geo.sh distance "Krefeld" "Muenchen" --mode transit
```

Modes: `driving` (Default), `transit`, `bicycling`, `walking`

### geocode

```bash
scripts/geo.sh geocode "Anthropic, San Francisco"
```

### reverse

```bash
scripts/geo.sh reverse 51.3388 6.5853
```

### places

```bash
scripts/geo.sh places "Coworking" --near "Duesseldorf" --radius 5000
```

### directions

```bash
scripts/geo.sh directions "Krefeld" "Muenchen"
scripts/geo.sh directions "Krefeld" "Muenchen" --waypoints "Frankfurt,Stuttgart"
```

Alle Ausgaben als JSON.
