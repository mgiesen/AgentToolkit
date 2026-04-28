#!/usr/bin/env python3
"""Geo Skill – Ortsbasierte Berechnungen via Google Maps Platform."""

import argparse
import json
import os
import re
import sys
from pathlib import Path

from dotenv import load_dotenv
import googlemaps

REPO_ROOT = Path(__file__).resolve().parents[3]
load_dotenv(REPO_ROOT / ".env")

API_KEY = os.environ.get("GOOGLE_MAPS_API_KEY")
if not API_KEY:
    print(json.dumps({"error": "GOOGLE_MAPS_API_KEY nicht gesetzt. Siehe .env.example im Repo-Root."}))
    sys.exit(1)

gmaps = googlemaps.Client(key=API_KEY)


def cmd_distance(args):
    result = gmaps.distance_matrix(
        origins=[args.origin], destinations=[args.destination],
        mode=args.mode, language="de",
    )
    el = result["rows"][0]["elements"][0]
    if el["status"] != "OK":
        print(json.dumps({"error": f"Keine Route gefunden: {el['status']}"}))
        sys.exit(1)
    print(json.dumps({
        "origin": args.origin, "destination": args.destination, "mode": args.mode,
        "distance_km": round(el["distance"]["value"] / 1000, 1),
        "duration_min": round(el["duration"]["value"] / 60),
    }, ensure_ascii=False))


def cmd_geocode(args):
    results = gmaps.geocode(args.address, language="de")
    if not results:
        print(json.dumps({"error": f"Keine Ergebnisse fuer: {args.address}"}))
        sys.exit(1)
    loc = results[0]["geometry"]["location"]
    print(json.dumps({
        "address": args.address,
        "formatted_address": results[0]["formatted_address"],
        "lat": round(loc["lat"], 6), "lng": round(loc["lng"], 6),
    }, ensure_ascii=False))


def cmd_reverse(args):
    results = gmaps.reverse_geocode((args.lat, args.lng), language="de")
    if not results:
        print(json.dumps({"error": f"Keine Adresse fuer: {args.lat}, {args.lng}"}))
        sys.exit(1)
    components = {c["types"][0]: c["long_name"] for c in results[0]["address_components"] if c["types"]}
    print(json.dumps({
        "lat": args.lat, "lng": args.lng,
        "formatted_address": results[0]["formatted_address"],
        "components": components,
    }, ensure_ascii=False))


def cmd_places(args):
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


def cmd_directions(args):
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
    print(json.dumps({
        "summary": route.get("summary", ""),
        "origin": args.origin, "destination": args.destination,
        "distance_km": round(total_km, 1), "duration_min": round(total_min),
        "steps": steps,
    }, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Geo Skill – Google Maps CLI")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("distance")
    p.add_argument("origin")
    p.add_argument("destination")
    p.add_argument("--mode", default="driving", choices=["driving", "transit", "walking", "bicycling"])

    p = sub.add_parser("geocode")
    p.add_argument("address")

    p = sub.add_parser("reverse")
    p.add_argument("lat", type=float)
    p.add_argument("lng", type=float)

    p = sub.add_parser("places")
    p.add_argument("query")
    p.add_argument("--near", required=True)
    p.add_argument("--radius", type=int, default=5000)
    p.add_argument("--limit", type=int, default=10)

    p = sub.add_parser("directions")
    p.add_argument("origin")
    p.add_argument("destination")
    p.add_argument("--waypoints")
    p.add_argument("--mode", default="driving", choices=["driving", "transit", "walking", "bicycling"])

    args = parser.parse_args()
    {"distance": cmd_distance, "geocode": cmd_geocode, "reverse": cmd_reverse,
     "places": cmd_places, "directions": cmd_directions}[args.command](args)


if __name__ == "__main__":
    main()
