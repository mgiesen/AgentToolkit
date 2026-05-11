---
name: geo
description: Berechnet Fahrstrecken, Fahrzeiten, geocodiert Adressen, sucht Orte, erstellt Routen, berechnet Höhenprofile, löst Rundtouren (TSP) und passt GPS-Traces auf Straßen ein. Nutzt kostenlose APIs (OSRM, Nominatim, Open-Elevation) mit automatischem Google Maps Fallback. Google API Key nur für ÖPNV, Places und Live-Verkehr zwingend erforderlich.
source:
  repo: https://github.com/mgiesen/AgentToolkit
  version: "2.0"
platform: all
features:
  - Fahrdistanz und -dauer zwischen zwei Orten (Auto, Fahrrad, zu Fuß)
  - ÖPNV-Routing mit Umstiegszeiten
  - Turn-by-turn Navigation mit Wegpunkten
  - Routen-Geometrie als GeoJSON
  - Distance Matrix (n Starts × m Ziele)
  - Adresse in Koordinaten umwandeln (Geocoding)
  - Koordinaten in Adresse umwandeln (Reverse Geocoding)
  - POI-Suche in einem Radius um einen Ort
  - Höhenprofil für beliebige Koordinaten
  - GPS-Trace auf Straßennetz einpassen (Map Matching)
  - Optimale Rundtour über mehrere Stops (TSP)
---

# Geo Skill

## API-Strategie

| Feature             | Primär (kostenlos) | Fallback (Google Key)  |
| ------------------- | ------------------ | ---------------------- |
| Routing, Distanz    | OSRM               | Google Directions      |
| Geocoding / Reverse | Nominatim          | Google Geocoding       |
| Distance Matrix     | OSRM table         | Google Distance Matrix |
| Elevation           | Open-Elevation     | Google Elevation       |
| Map Matching        | OSRM match         | –                      |
| TSP / Rundtouren    | OSRM trip          | –                      |
| ÖPNV-Routing        | –                  | **Google (Pflicht)**   |
| Places / POI        | –                  | **Google (Pflicht)**   |
| Live-Verkehr        | –                  | **Google (Pflicht)**   |

API-Key in `.env`: `GOOGLE_MAPS_API_KEY` (optional, außer ÖPNV/Places).  
Optionaler Custom OSRM-Server: `OSRM_BASE_URL` in `.env`.

## Subcommands

```bash
# Distanz & Dauer
scripts/geo.sh distance "Krefeld" "München"
scripts/geo.sh distance "Krefeld" "München" --mode transit   # Google Pflicht

# Geocoding
scripts/geo.sh geocode "Anthropic, San Francisco"
scripts/geo.sh reverse 51.3388 6.5853

# POI-Suche (Google Pflicht)
scripts/geo.sh places "Coworking" --near "Düsseldorf" --radius 5000

# Turn-by-turn Routing
scripts/geo.sh directions "Krefeld" "München"
scripts/geo.sh directions "Krefeld" "München" --waypoints "Frankfurt,Stuttgart"
scripts/geo.sh directions "Krefeld" "München" --geojson      # + Routen-Geometrie

# Distance Matrix n×m (Adressen mit '|' trennen)
scripts/geo.sh matrix "Krefeld|Köln" "München|Berlin"

# Höhenprofil (Punkte mit '|' trennen, Format: lat,lng)
scripts/geo.sh elevation "51.33,6.58|48.13,11.58"

# Map Matching – GPS-Trace auf Straßennetz einpassen
scripts/geo.sh match "51.33,6.58;51.34,6.59;51.35,6.60"
scripts/geo.sh match @trace.txt --geojson

# TSP / Rundtouren-Optimierung (Stops mit '|' trennen)
scripts/geo.sh trip "Krefeld|Köln|Düsseldorf|Essen"
```

Alle Ausgaben als JSON. Jede Antwort enthält `"provider"` zur Nachvollziehbarkeit.
