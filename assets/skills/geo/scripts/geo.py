#!/usr/bin/env python3
"""Geo Skill – Ortsbasierte Berechnungen.

API-Strategie (Qualität vor Kosten):
  - Routing/Matrix/Match/Trip: OSRM (kostenlos, kein Key) → Google Fallback
  - Geocoding/Reverse:         Nominatim (kostenlos)      → Google Fallback
  - Elevation:                 Open-Elevation (kostenlos) → Google Fallback
  - Places:                    Google Places (kein Free-Equivalent)
  - ÖPNV:                      Google Directions transit  (kein Free-Equivalent)
  - Live-Verkehr:              Google Directions          (kein Free-Equivalent)
"""

import argparse
import json
import os
import re
import sys
import time
from pathlib import Path

import requests
from dotenv import load_dotenv

REPO_ROOT = Path(__file__).resolve().parents[4]
load_dotenv(REPO_ROOT / ".env")

API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY")

# OSRM public demo server – für Produktion self-host empfohlen
OSRM_BASE = os.environ.get("OSRM_BASE_URL", "https://router.project-osrm.org")
# Nominatim – User-Agent Pflicht
NOMINATIM_BASE = "https://nominatim.openstreetmap.org"
NOMINATIM_UA = "AgentBox-GeoSkill/1.0"
# Open-Elevation
OPEN_ELEVATION_BASE = "https://api.open-elevation.com/api/v1"

GOOGLE_REQUIRES_KEY = (
    "Google API benötigt GOOGLE_MAPS_API_KEY in .env"
)


def _google_available():
    return bool(API_KEY)


def _require_google():
    if not _google_available():
        print(json.dumps({"error": GOOGLE_REQUIRES_KEY}))
        sys.exit(1)
    import googlemaps
    return googlemaps.Client(key=API_KEY)


def _nominatim_geocode(address):
    """Geocoding via Nominatim. Gibt (lat, lng, formatted) zurück oder None."""
    r = requests.get(
        f"{NOMINATIM_BASE}/search",
        params={"q": address, "format": "jsonv2", "limit": 1, "addressdetails": 1},
        headers={"User-Agent": NOMINATIM_UA},
        timeout=10,
    )
    r.raise_for_status()
    results = r.json()
    if not results:
        return None
    res = results[0]
    return float(res["lat"]), float(res["lon"]), res.get("display_name", address)


def _osrm_coords(addresses):
    """Geocodiert Liste von Adressen oder 'lat,lng'-Strings via Nominatim → OSRM-Format."""
    coords = []
    for addr in addresses:
        # Falls bereits "lat,lng" Format
        parts = addr.split(",")
        if len(parts) == 2:
            try:
                lat, lng = float(parts[0]), float(parts[1])
                coords.append((lng, lat))
                continue
            except ValueError:
                pass
        result = _nominatim_geocode(addr)
        if not result:
            print(json.dumps({"error": f"Adresse nicht gefunden: {addr}"}))
            sys.exit(1)
        lat, lng, _ = result
        time.sleep(1)  # Nominatim Rate-Limit: 1 req/s
        coords.append((lng, lat))
    return coords


def _osrm_coord_str(coords):
    return ";".join(f"{lng},{lat}" for lng, lat in coords)


# ─── distance ────────────────────────────────────────────────────────────────

def cmd_distance(args):
    """Distanz/Dauer: OSRM für driving/walking/cycling, Google für transit/traffic."""
    mode = args.mode

    if mode == "transit":
        # ÖPNV nur via Google
        gmaps = _require_google()
        result = gmaps.distance_matrix(
            origins=[args.origin], destinations=[args.destination],
            mode="transit", language="de",
        )
        el = result["rows"][0]["elements"][0]
        if el["status"] != "OK":
            print(json.dumps({"error": f"Keine Route: {el['status']}"}))
            sys.exit(1)
        print(json.dumps({
            "origin": args.origin, "destination": args.destination, "mode": mode,
            "distance_km": round(el["distance"]["value"] / 1000, 1),
            "duration_min": round(el["duration"]["value"] / 60),
            "provider": "google",
        }, ensure_ascii=False))
        return

    # OSRM profile mapping
    osrm_profile = {"driving": "driving", "walking": "foot", "bicycling": "bike"}.get(mode, "driving")

    try:
        coords = _osrm_coords([args.origin, args.destination])
        coord_str = _osrm_coord_str(coords)
        r = requests.get(
            f"{OSRM_BASE}/route/v1/{osrm_profile}/{coord_str}",
            params={"overview": "false"},
            timeout=15,
        )
        r.raise_for_status()
        data = r.json()
        if data.get("code") != "Ok":
            raise ValueError(data.get("message", "OSRM Fehler"))
        route = data["routes"][0]
        print(json.dumps({
            "origin": args.origin, "destination": args.destination, "mode": mode,
            "distance_km": round(route["distance"] / 1000, 1),
            "duration_min": round(route["duration"] / 60),
            "provider": "osrm+nominatim",
        }, ensure_ascii=False))
    except Exception as e:
        if not _google_available():
            print(json.dumps({"error": f"OSRM fehlgeschlagen und kein Google API Key: {e}"}))
            sys.exit(1)
        # Google Fallback
        gmaps = _require_google()
        gmode = {"driving": "driving", "walking": "walking", "bicycling": "bicycling"}.get(mode, "driving")
        result = gmaps.distance_matrix(
            origins=[args.origin], destinations=[args.destination],
            mode=gmode, language="de",
        )
        el = result["rows"][0]["elements"][0]
        if el["status"] != "OK":
            print(json.dumps({"error": f"Keine Route: {el['status']}"}))
            sys.exit(1)
        print(json.dumps({
            "origin": args.origin, "destination": args.destination, "mode": mode,
            "distance_km": round(el["distance"]["value"] / 1000, 1),
            "duration_min": round(el["duration"]["value"] / 60),
            "provider": "google (fallback)",
        }, ensure_ascii=False))


# ─── geocode ─────────────────────────────────────────────────────────────────

def cmd_geocode(args):
    """Geocoding: Nominatim → Google Fallback."""
    result = _nominatim_geocode(args.address)
    if result:
        lat, lng, formatted = result
        print(json.dumps({
            "address": args.address,
            "formatted_address": formatted,
            "lat": round(lat, 6), "lng": round(lng, 6),
            "provider": "nominatim",
        }, ensure_ascii=False))
        return

    if not _google_available():
        print(json.dumps({"error": f"Keine Ergebnisse für: {args.address}"}))
        sys.exit(1)

    gmaps = _require_google()
    results = gmaps.geocode(args.address, language="de")
    if not results:
        print(json.dumps({"error": f"Keine Ergebnisse für: {args.address}"}))
        sys.exit(1)
    loc = results[0]["geometry"]["location"]
    print(json.dumps({
        "address": args.address,
        "formatted_address": results[0]["formatted_address"],
        "lat": round(loc["lat"], 6), "lng": round(loc["lng"], 6),
        "provider": "google (fallback)",
    }, ensure_ascii=False))


# ─── reverse ─────────────────────────────────────────────────────────────────

def cmd_reverse(args):
    """Reverse Geocoding: Nominatim → Google Fallback."""
    r = requests.get(
        f"{NOMINATIM_BASE}/reverse",
        params={"lat": args.lat, "lon": args.lng, "format": "jsonv2"},
        headers={"User-Agent": NOMINATIM_UA},
        timeout=10,
    )
    if r.status_code == 200:
        data = r.json()
        if "display_name" in data:
            addr = data.get("address", {})
            print(json.dumps({
                "lat": args.lat, "lng": args.lng,
                "formatted_address": data["display_name"],
                "components": addr,
                "provider": "nominatim",
            }, ensure_ascii=False))
            return

    if not _google_available():
        print(json.dumps({"error": f"Keine Adresse für: {args.lat}, {args.lng}"}))
        sys.exit(1)

    gmaps = _require_google()
    results = gmaps.reverse_geocode((args.lat, args.lng), language="de")
    if not results:
        print(json.dumps({"error": f"Keine Adresse für: {args.lat}, {args.lng}"}))
        sys.exit(1)
    components = {c["types"][0]: c["long_name"] for c in results[0]["address_components"] if c["types"]}
    print(json.dumps({
        "lat": args.lat, "lng": args.lng,
        "formatted_address": results[0]["formatted_address"],
        "components": components,
        "provider": "google (fallback)",
    }, ensure_ascii=False))


# ─── places ──────────────────────────────────────────────────────────────────

def cmd_places(args):
    """POI-Suche: nur via Google Places API."""
    gmaps = _require_google()
    geo = gmaps.geocode(args.near, language="de")
    if not geo:
        print(json.dumps({"error": f"Bezugsort nicht gefunden: {args.near}"}))
        sys.exit(1)
    center = geo[0]["geometry"]["location"]
    results = gmaps.places(
        query=args.query, location=(center["lat"], center["lng"]),
        radius=args.radius, language="de",
    )
    places = []
    for p in results.get("results", [])[:args.limit]:
        loc = p["geometry"]["location"]
        places.append({
            "name": p.get("name", ""), "address": p.get("formatted_address", ""),
            "rating": p.get("rating"),
            "lat": round(loc["lat"], 6), "lng": round(loc["lng"], 6),
        })
    print(json.dumps(places, ensure_ascii=False, indent=2))


# ─── directions ──────────────────────────────────────────────────────────────

def cmd_directions(args):
    """Turn-by-turn Routing: OSRM (+ GeoJSON) → Google Fallback."""
    mode = args.mode

    if mode == "transit":
        _cmd_directions_google(args)
        return

    osrm_profile = {"driving": "driving", "walking": "foot", "bicycling": "bike"}.get(mode, "driving")

    try:
        all_points = [args.origin]
        if args.waypoints:
            all_points += [w.strip() for w in args.waypoints.split(",")]
        all_points.append(args.destination)

        coords = _osrm_coords(all_points)
        coord_str = _osrm_coord_str(coords)

        params = {"steps": "true", "overview": "full", "annotations": "true"}
        if args.geojson:
            params["geometries"] = "geojson"

        r = requests.get(
            f"{OSRM_BASE}/route/v1/{osrm_profile}/{coord_str}",
            params=params,
            timeout=20,
        )
        r.raise_for_status()
        data = r.json()
        if data.get("code") != "Ok":
            raise ValueError(data.get("message", "OSRM Fehler"))

        route = data["routes"][0]
        legs = route["legs"]
        steps = []
        for leg in legs:
            for step in leg.get("steps", []):
                steps.append({
                    "instruction": step.get("name", ""),
                    "maneuver": step.get("maneuver", {}).get("type", ""),
                    "modifier": step.get("maneuver", {}).get("modifier", ""),
                    "distance_km": round(step["distance"] / 1000, 2),
                    "duration_min": round(step["duration"] / 60, 1),
                    "mode": step.get("mode", mode),
                })

        out = {
            "origin": args.origin,
            "destination": args.destination,
            "distance_km": round(route["distance"] / 1000, 1),
            "duration_min": round(route["duration"] / 60),
            "steps": steps,
            "provider": "osrm+nominatim",
        }
        if args.geojson and "geometry" in route:
            out["geometry"] = route["geometry"]

        print(json.dumps(out, ensure_ascii=False, indent=2))

    except Exception as e:
        if not _google_available():
            print(json.dumps({"error": f"OSRM fehlgeschlagen und kein Google API Key: {e}"}))
            sys.exit(1)
        _cmd_directions_google(args)


def _cmd_directions_google(args):
    gmaps = _require_google()
    waypoints = [w.strip() for w in args.waypoints.split(",")] if args.waypoints else None
    result = gmaps.directions(
        origin=args.origin, destination=args.destination,
        waypoints=waypoints, mode=args.mode, language="de",
    )
    if not result:
        print(json.dumps({"error": "Keine Route gefunden."}))
        sys.exit(1)
    route = result[0]
    legs = route["legs"]
    total_km = sum(leg["distance"]["value"] for leg in legs) / 1000
    total_min = sum(leg["duration"]["value"] for leg in legs) / 60
    steps = []
    for leg in legs:
        for step in leg["steps"]:
            instruction = re.sub(r"<[^>]+>", "", step["html_instructions"])
            steps.append({
                "instruction": instruction,
                "distance_km": round(step["distance"]["value"] / 1000, 1),
                "duration_min": round(step["duration"]["value"] / 60),
            })
    out = {
        "summary": route.get("summary", ""),
        "origin": args.origin, "destination": args.destination,
        "distance_km": round(total_km, 1), "duration_min": round(total_min),
        "steps": steps,
        "provider": "google",
    }
    if args.geojson:
        # Google liefert encoded polyline, dekodieren für GeoJSON-ähnliches Format
        try:
            import googlemaps.convert as gc
            points = gc.decode_polyline(route["overview_polyline"]["points"])
            out["geometry"] = {
                "type": "LineString",
                "coordinates": [[p["lng"], p["lat"]] for p in points],
            }
        except Exception:
            pass
    print(json.dumps(out, ensure_ascii=False, indent=2))


# ─── matrix ──────────────────────────────────────────────────────────────────

def cmd_matrix(args):
    """Distance Matrix (n×m): OSRM table service → Google Fallback."""
    origins = [o.strip() for o in args.origins.split("|")]
    destinations = [d.strip() for d in args.destinations.split("|")]
    mode = args.mode

    if mode == "transit":
        _cmd_matrix_google(origins, destinations, mode)
        return

    osrm_profile = {"driving": "driving", "walking": "foot", "bicycling": "bike"}.get(mode, "driving")

    try:
        all_places = origins + destinations
        coords = _osrm_coords(all_places)
        coord_str = _osrm_coord_str(coords)

        n_orig = len(origins)
        sources = ";".join(str(i) for i in range(n_orig))
        dests = ";".join(str(i) for i in range(n_orig, n_orig + len(destinations)))

        r = requests.get(
            f"{OSRM_BASE}/table/v1/{osrm_profile}/{coord_str}",
            params={"sources": sources, "destinations": dests},
            timeout=20,
        )
        r.raise_for_status()
        data = r.json()
        if data.get("code") != "Ok":
            raise ValueError(data.get("message", "OSRM Fehler"))

        matrix = []
        for i, orig in enumerate(origins):
            row = []
            for j, dest in enumerate(destinations):
                dur_sec = data["durations"][i][j]
                row.append({
                    "origin": orig, "destination": dest,
                    "duration_min": round(dur_sec / 60) if dur_sec is not None else None,
                })
            matrix.append(row)

        print(json.dumps({"matrix": matrix, "provider": "osrm+nominatim"}, ensure_ascii=False, indent=2))

    except Exception as e:
        if not _google_available():
            print(json.dumps({"error": f"OSRM fehlgeschlagen und kein Google API Key: {e}"}))
            sys.exit(1)
        _cmd_matrix_google(origins, destinations, mode)


def _cmd_matrix_google(origins, destinations, mode):
    gmaps = _require_google()
    gmode = {"driving": "driving", "walking": "walking", "bicycling": "bicycling", "transit": "transit"}.get(mode, "driving")
    result = gmaps.distance_matrix(origins=origins, destinations=destinations, mode=gmode, language="de")
    matrix = []
    for i, row in enumerate(result["rows"]):
        for j, el in enumerate(row["elements"]):
            entry = {"origin": origins[i], "destination": destinations[j]}
            if el["status"] == "OK":
                entry["distance_km"] = round(el["distance"]["value"] / 1000, 1)
                entry["duration_min"] = round(el["duration"]["value"] / 60)
            else:
                entry["error"] = el["status"]
            matrix.append(entry)
    print(json.dumps({"matrix": matrix, "provider": "google"}, ensure_ascii=False, indent=2))


# ─── elevation ───────────────────────────────────────────────────────────────

def cmd_elevation(args):
    """Höhenprofil: Open-Elevation → Google Fallback."""
    locations = [{"latitude": float(p.split(",")[0]), "longitude": float(p.split(",")[1])}
                 for p in args.locations.split("|")]

    try:
        r = requests.post(
            f"{OPEN_ELEVATION_BASE}/lookup",
            json={"locations": locations},
            timeout=15,
        )
        r.raise_for_status()
        data = r.json()
        results = [
            {"lat": loc["latitude"], "lng": loc["longitude"], "elevation_m": round(res["elevation"], 1)}
            for loc, res in zip(locations, data["results"])
        ]
        print(json.dumps({"elevations": results, "provider": "open-elevation"}, ensure_ascii=False, indent=2))

    except Exception as e:
        if not _google_available():
            print(json.dumps({"error": f"Open-Elevation fehlgeschlagen und kein Google API Key: {e}"}))
            sys.exit(1)
        gmaps = _require_google()
        locs = [(loc["latitude"], loc["longitude"]) for loc in locations]
        results_g = gmaps.elevation(locs)
        results = [
            {"lat": round(r["location"]["lat"], 6), "lng": round(r["location"]["lng"], 6),
             "elevation_m": round(r["elevation"], 1), "resolution_m": round(r["resolution"], 1)}
            for r in results_g
        ]
        print(json.dumps({"elevations": results, "provider": "google (fallback)"}, ensure_ascii=False, indent=2))


# ─── match ───────────────────────────────────────────────────────────────────

def cmd_match(args):
    """Map Matching: GPS-Traces auf Straßennetz einpassen via OSRM."""
    # Input: "lat,lng;lat,lng;..." oder Datei
    if args.coords.startswith("@"):
        path = args.coords[1:]
        raw = Path(path).read_text().strip()
    else:
        raw = args.coords

    points = [p.strip() for p in raw.split(";") if p.strip()]
    osrm_coords = []
    for p in points:
        parts = p.split(",")
        lat, lng = float(parts[0]), float(parts[1])
        osrm_coords.append((lng, lat))

    coord_str = _osrm_coord_str(osrm_coords)
    osrm_profile = {"driving": "driving", "walking": "foot", "bicycling": "bike"}.get(args.mode, "driving")

    params = {"overview": "full", "steps": "false"}
    if args.geojson:
        params["geometries"] = "geojson"
    if args.timestamps:
        params["timestamps"] = args.timestamps

    r = requests.get(
        f"{OSRM_BASE}/match/v1/{osrm_profile}/{coord_str}",
        params=params,
        timeout=20,
    )
    r.raise_for_status()
    data = r.json()
    if data.get("code") != "Ok":
        print(json.dumps({"error": data.get("message", "Map Matching fehlgeschlagen")}))
        sys.exit(1)

    matchings = []
    for m in data.get("matchings", []):
        entry = {
            "confidence": m.get("confidence"),
            "distance_km": round(m["distance"] / 1000, 2),
            "duration_min": round(m["duration"] / 60, 1),
        }
        if args.geojson and "geometry" in m:
            entry["geometry"] = m["geometry"]
        matchings.append(entry)

    tracepoints = [
        {"original_index": i, "snapped": tp["location"] if tp else None}
        for i, tp in enumerate(data.get("tracepoints", []))
    ]

    print(json.dumps({
        "matchings": matchings,
        "tracepoints": tracepoints,
        "provider": "osrm",
    }, ensure_ascii=False, indent=2))


# ─── trip ────────────────────────────────────────────────────────────────────

def cmd_trip(args):
    """TSP / Rundtouren-Optimierung via OSRM trip service."""
    stops = [s.strip() for s in args.stops.split("|")]
    osrm_profile = {"driving": "driving", "walking": "foot", "bicycling": "bike"}.get(args.mode, "driving")

    coords = _osrm_coords(stops)
    coord_str = _osrm_coord_str(coords)

    params = {"overview": "false", "steps": "false", "roundtrip": str(args.roundtrip).lower()}
    r = requests.get(
        f"{OSRM_BASE}/trip/v1/{osrm_profile}/{coord_str}",
        params=params,
        timeout=20,
    )
    r.raise_for_status()
    data = r.json()
    if data.get("code") != "Ok":
        print(json.dumps({"error": data.get("message", "Trip fehlgeschlagen")}))
        sys.exit(1)

    # Reihenfolge der Waypoints aus tracepoints rekonstruieren
    waypoints = data.get("waypoints", [])
    ordered = sorted(waypoints, key=lambda w: (w.get("trips_index", 0), w.get("waypoint_index", 0)))
    order = [stops[w["waypoint_index"] % len(stops)] if w.get("waypoint_index") is not None else "?" for w in ordered]

    trips = []
    for t in data.get("trips", []):
        trips.append({
            "distance_km": round(t["distance"] / 1000, 1),
            "duration_min": round(t["duration"] / 60),
        })

    print(json.dumps({
        "optimized_order": order,
        "trips": trips,
        "note": "TSP-Heuristik (farthest-insertion), nicht garantiert optimal",
        "provider": "osrm",
    }, ensure_ascii=False, indent=2))


# ─── main ─────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Geo Skill CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    # distance
    p = sub.add_parser("distance")
    p.add_argument("origin")
    p.add_argument("destination")
    p.add_argument("--mode", default="driving", choices=["driving", "transit", "walking", "bicycling"])

    # geocode
    p = sub.add_parser("geocode")
    p.add_argument("address")

    # reverse
    p = sub.add_parser("reverse")
    p.add_argument("lat", type=float)
    p.add_argument("lng", type=float)

    # places
    p = sub.add_parser("places")
    p.add_argument("query")
    p.add_argument("--near", required=True)
    p.add_argument("--radius", type=int, default=5000)
    p.add_argument("--limit", type=int, default=10)

    # directions
    p = sub.add_parser("directions")
    p.add_argument("origin")
    p.add_argument("destination")
    p.add_argument("--waypoints")
    p.add_argument("--mode", default="driving", choices=["driving", "transit", "walking", "bicycling"])
    p.add_argument("--geojson", action="store_true", help="Routen-Geometrie als GeoJSON zurückgeben")

    # matrix (NEU)
    p = sub.add_parser("matrix")
    p.add_argument("origins", help="Adressen getrennt mit '|'")
    p.add_argument("destinations", help="Adressen getrennt mit '|'")
    p.add_argument("--mode", default="driving", choices=["driving", "transit", "walking", "bicycling"])

    # elevation (NEU)
    p = sub.add_parser("elevation")
    p.add_argument("locations", help="'lat,lng' Punkte getrennt mit '|'")

    # match (NEU)
    p = sub.add_parser("match")
    p.add_argument("coords", help="GPS-Punkte als 'lat,lng;lat,lng;...' oder @datei.txt")
    p.add_argument("--mode", default="driving", choices=["driving", "walking", "bicycling"])
    p.add_argument("--timestamps", help="Unix-Timestamps mit ';' getrennt (optional)")
    p.add_argument("--geojson", action="store_true")

    # trip (NEU)
    p = sub.add_parser("trip")
    p.add_argument("stops", help="Adressen getrennt mit '|'")
    p.add_argument("--mode", default="driving", choices=["driving", "walking", "bicycling"])
    p.add_argument("--roundtrip", action="store_true", default=True)

    args = parser.parse_args()
    {
        "distance": cmd_distance,
        "geocode": cmd_geocode,
        "reverse": cmd_reverse,
        "places": cmd_places,
        "directions": cmd_directions,
        "matrix": cmd_matrix,
        "elevation": cmd_elevation,
        "match": cmd_match,
        "trip": cmd_trip,
    }[args.command](args)


if __name__ == "__main__":
    main()
