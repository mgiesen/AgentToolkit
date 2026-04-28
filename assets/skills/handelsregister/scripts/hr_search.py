#!/usr/bin/env python3
"""Handelsregister Skill – Suche, Dokumentenabruf und Stammdaten.

Eigenstaendiges Skript ohne externe Handelsregister-Packages.
Nutzt nur requests + BeautifulSoup fuer direkte HTTP-Kommunikation
mit dem gemeinsamen Registerportal der Laender (handelsregister.de).
"""

import argparse
import hashlib
import json
import pathlib
import re
import sys
import tempfile
import time

import requests
from bs4 import BeautifulSoup

# ---------------------------------------------------------------------------
# Konstanten
# ---------------------------------------------------------------------------

BASE_URL = "https://www.handelsregister.de"
SEARCH_PATH = "/rp_web/erweitertesuche/welcome.xhtml"

REGISTERS = {
    "HRA": "Handelsregister Abteilung A",
    "HRB": "Handelsregister Abteilung B",
    "GnR": "Genossenschaftsregister",
    "PR": "Partnerschaftsregister",
    "VR": "Vereinsregister",
    "GsR": "Gesellschaftsregister",
}

STATES = [
    "Baden-Württemberg",
    "Bayern",
    "Berlin",
    "Brandenburg",
    "Bremen",
    "Hamburg",
    "Hessen",
    "Mecklenburg-Vorpommern",
    "Niedersachsen",
    "Nordrhein-Westfalen",
    "Rheinland-Pfalz",
    "Saarland",
    "Sachsen-Anhalt",
    "Sachsen",
    "Schleswig-Holstein",
    "Thüringen",
]

# Mapping: Bundesland-Name -> Form-Feldname (Kuerzel)
STATE_FIELD = {
    "Baden-Württemberg": "form:bundeslandBW_input",
    "Bayern": "form:bundeslandBY_input",
    "Berlin": "form:bundeslandBE_input",
    "Brandenburg": "form:bundeslandBR_input",
    "Bremen": "form:bundeslandHB_input",
    "Hamburg": "form:bundeslandHH_input",
    "Hessen": "form:bundeslandHE_input",
    "Mecklenburg-Vorpommern": "form:bundeslandMV_input",
    "Niedersachsen": "form:bundeslandNI_input",
    "Nordrhein-Westfalen": "form:bundeslandNW_input",
    "Rheinland-Pfalz": "form:bundeslandRP_input",
    "Saarland": "form:bundeslandSL_input",
    "Sachsen": "form:bundeslandSN_input",
    "Sachsen-Anhalt": "form:bundeslandST_input",
    "Schleswig-Holstein": "form:bundeslandSH_input",
    "Thüringen": "form:bundeslandTH_input",
}

DOCUMENT_TYPES = {
    "SI": "Strukturierte Inhalte (XML)",
    "AD": "Aktueller Abdruck (PDF)",
    "CD": "Chronologischer Abdruck (PDF)",
    "HD": "Historischer Abdruck (PDF)",
    "DK": "Dokumente / eingereichte Unterlagen",
    "UT": "Unternehmensträger",
    "VÖ": "Veröffentlichungen / Bekanntmachungen",
}

CACHE_DIR = pathlib.Path(tempfile.gettempdir()) / "handelsregister_cache"

# ---------------------------------------------------------------------------
# HTTP Session mit Retry
# ---------------------------------------------------------------------------


class HRSession(requests.Session):
    """Session die URLs relativ zu handelsregister.de aufloest und Retries hat."""

    def request(self, method, path, **kwargs):
        if path.startswith("/"):
            url = BASE_URL + path
        else:
            url = path
        kwargs.setdefault("timeout", 15)
        retries = 2
        while True:
            try:
                r = super().request(method, url, **kwargs)
                r.raise_for_status()
                return r
            except requests.exceptions.ConnectionError:
                if retries > 0:
                    retries -= 1
                    time.sleep(1)
                else:
                    raise


# ---------------------------------------------------------------------------
# Kontext & Parsing
# ---------------------------------------------------------------------------


def _get_context(session):
    """Laedt die erweiterte Suchseite und extrahiert ViewState + Stammdaten."""
    r = session.get(SEARCH_PATH)
    soup = BeautifulSoup(r.content, "html.parser")
    return {
        "view_state": soup.select_one('input[name="javax.faces.ViewState"]')["value"],
        "courts": {
            opt["value"]: opt.text.strip()
            for opt in soup.select(r"#form\:registergericht_input option")
            if opt["value"]
        },
        "rev_courts": {
            opt.text.strip(): opt["value"]
            for opt in soup.select(r"#form\:registergericht_input option")
            if opt["value"]
        },
        "types": {
            opt["value"]: opt.text.strip()
            for opt in soup.select(r"#form\:rechtsform_input option")
            if opt["value"]
        },
    }


def _parse_doc_fields(item):
    """Extrahiert alle verfuegbaren Dokument-Links aus einem Suchergebnis.

    Dokument-Links im Registerportal haben zwei Varianten:
    - Download-Links (AD/CD/HD/SI): nutzen PrimeFaces.monitorDownload, Typ steht im Linktext
    - Navigations-Links (DK/UT/VÖ): nutzen property='Global.Dokumentart.XX', Typ steht im Linktext

    Returns: Dict {doc_type: field_id}
    """
    doc_fields = {}
    for el in item.select("a[onclick*='ergebnissForm:selectedSuchErgebnisFormTable']"):
        text = el.text.strip()
        if text not in DOCUMENT_TYPES:
            continue
        field_id = el.get("id", "")
        if field_id:
            doc_fields[text] = field_id
    return doc_fields


def _parse_register_id(text, ctx):
    """Parst Registergericht + Registerart + Nummer aus dem Ergebnistext."""
    parts = text.strip().split()
    for i in range(len(parts) - 2, 0, -1):
        reg = parts[i]
        if reg in REGISTERS:
            tail = parts[i + 1 :]
            if "früher" in tail:
                tail = tail[: tail.index("früher")]
            court_name = " ".join(parts[1:i])
            court_code = ctx["rev_courts"].get(court_name, "")
            return {
                "court_code": court_code,
                "court_name": court_name,
                "register_type": reg,
                "register_number": " ".join(tail),
            }
    return {"court_code": "", "court_name": "", "register_type": "", "register_number": ""}


def _parse_search_item(item, ctx):
    """Parst ein einzelnes Suchergebnis aus dem HTML."""
    title_el = item.select_one(".marginLeft20")
    bold_el = item.select_one(".fontWeightBold")

    title = title_el.text.strip() if title_el else ""
    reg_info = _parse_register_id(bold_el.text, ctx) if bold_el else {}

    # Status aus der letzten Tabellenzelle
    cells = item.select("td")
    status = ""
    if len(cells) >= 5:
        status = cells[4].text.strip() if len(cells) > 4 else ""

    # Namenshistorie
    history = []
    hist_cells = cells[8:] if len(cells) > 8 else []
    for i in range(0, len(hist_cells) - 1, 3):
        name_text = hist_cells[i].text.strip()
        loc_text = hist_cells[i + 1].text.strip() if i + 1 < len(hist_cells) else ""
        if "Niederlassungen" in name_text or "Branches" in name_text:
            break
        if name_text:
            history.append({"name": name_text, "location": loc_text})

    # Verfuegbare Dokument-Felder ermitteln
    available_docs = _parse_doc_fields(item)

    return {
        "name": title,
        **reg_info,
        "status": status,
        "history": history,
        "available_documents": list(available_docs.keys()),
        "_doc_fields": available_docs,
    }


# ---------------------------------------------------------------------------
# Kernfunktionen
# ---------------------------------------------------------------------------


def _do_search(session, query):
    """Fuehrt die Suche durch und gibt geparste Ergebnisse + Metadaten zurueck."""
    ctx = _get_context(session)
    r = session.post(
        SEARCH_PATH,
        data={
            "form": "form",
            "form:btnSuche": "",
            "javax.faces.ViewState": ctx["view_state"],
            "form:schlagwortOptionen": 1,
            "form:ergebnisseProSeite_input": 100,
            **query,
        },
    )
    soup = BeautifulSoup(r.content, "html.parser")
    action = soup.select_one("[action]")
    view_state = soup.select_one('input[name="javax.faces.ViewState"]')

    items = [_parse_search_item(item, ctx) for item in soup.select("[data-ri]")]

    return {
        "action": action["action"] if action else "",
        "view_state": view_state["value"] if view_state else "",
        "truncated": bool(soup.select_one(r"#ergebnissForm\:ergebnisseAnzahl_label")),
        "items": items,
    }


def _build_search_query(
    keywords="",
    mode="all",
    register="",
    register_number="",
    court="",
    legal_form="",
    state="",
    city="",
    zip_code="",
):
    """Baut die Form-Daten fuer die erweiterte Suche."""
    mode_map = {"all": 1, "min": 2, "exact": 3}
    query = {
        "form:schlagwoerter": keywords,
        "form:schlagwortOptionen": mode_map.get(mode, 1),
        "form:registerArt_input": register,
        "form:registerNummer": register_number,
        "form:registergericht_input": court,
        "form:rechtsform_input": legal_form,
        "form:niederlassung": city,
        "form:postleitzahl": zip_code,
    }
    if state and state in STATE_FIELD:
        query[STATE_FIELD[state]] = "on"
    return query


def _cache_key(prefix, **kwargs):
    """Erzeugt einen deterministischen Cache-Dateinamen."""
    raw = json.dumps(kwargs, sort_keys=True)
    h = hashlib.sha256(raw.encode()).hexdigest()[:16]
    return CACHE_DIR / f"{prefix}_{h}.json"


# ---------------------------------------------------------------------------
# Oeffentliche API
# ---------------------------------------------------------------------------


def search_companies(
    keywords="",
    mode="all",
    register="",
    register_number="",
    court="",
    legal_form="",
    state="",
    city="",
    zip_code="",
    force=False,
):
    """Sucht Unternehmen im Handelsregister. Gibt Liste von Dicts zurueck."""
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = _cache_key(
        "search",
        keywords=keywords,
        mode=mode,
        register=register,
        register_number=register_number,
        court=court,
        legal_form=legal_form,
        state=state,
        city=city,
        zip_code=zip_code,
    )

    if not force and cache_file.exists():
        with open(cache_file) as f:
            return json.load(f)

    query = _build_search_query(
        keywords=keywords,
        mode=mode,
        register=register,
        register_number=register_number,
        court=court,
        legal_form=legal_form,
        state=state,
        city=city,
        zip_code=zip_code,
    )

    with HRSession() as session:
        data = _do_search(session, query)

    # _doc_fields nicht in den Cache / Output schreiben
    results = []
    for item in data["items"]:
        clean = {k: v for k, v in item.items() if not k.startswith("_")}
        results.append(clean)

    cache_file.write_text(json.dumps(results, ensure_ascii=False, indent=2))
    return results


def get_document(register, register_number, court, doc_type="SI", output_dir=None, force=False):
    """Ruft ein Dokument (SI/AD/CD/HD) fuer einen konkreten Registereintrag ab.

    Args:
        register: Registerart (HRA, HRB, GnR, PR, VR)
        register_number: Registernummer
        court: Registergerichtscode (z.B. M1202)
        doc_type: SI (XML), AD/CD/HD (PDF)
        output_dir: Verzeichnis fuer PDF-Dateien (Default: aktuelles Verzeichnis)
        force: Cache umgehen

    Returns:
        Bei SI: XML-String
        Bei AD/CD/HD: Pfad zur gespeicherten PDF-Datei
    """
    if doc_type not in DOCUMENT_TYPES:
        raise ValueError(f"Unbekannter Dokumenttyp: {doc_type}. Verfuegbar: {list(DOCUMENT_TYPES.keys())}")

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = _cache_key(
        f"doc_{doc_type}",
        register=register,
        register_number=register_number,
        court=court,
    )

    # SI aus Cache
    if doc_type == "SI" and not force and cache_file.exists():
        return cache_file.read_text()

    with HRSession() as session:
        # Suche nach dem konkreten Eintrag
        data = _do_search(
            session,
            {
                "form:schlagwoerter": "",
                "form:schlagwortOptionen": 1,
                "form:registerArt_input": register,
                "form:registerNummer": register_number,
                "form:registergericht_input": court,
                "form:rechtsform_input": "",
            },
        )

        if not data["items"]:
            raise RuntimeError(
                f"Kein Eintrag gefunden fuer {register} {register_number} bei Gericht {court}"
            )

        # Dokument-Feld suchen
        item = data["items"][0]
        field_id = item.get("_doc_fields", {}).get(doc_type)
        if not field_id:
            available = item.get("available_documents", [])
            raise RuntimeError(
                f"Dokumenttyp {doc_type} nicht verfuegbar. Verfuegbar: {available}"
            )

        # Dokument abrufen – zwei Varianten:
        # Download-Links (AD/CD/HD/SI): einfacher Submit mit field_id
        # Navigations-Links (DK/UT/VÖ): Submit mit property-Parameter
        if doc_type in ("AD", "CD", "HD", "SI"):
            post_data = {
                "ergebnissForm": "ergebnissForm",
                "javax.faces.ViewState": data["view_state"],
                field_id: field_id,
            }
        else:
            post_data = {
                "ergebnissForm": "ergebnissForm",
                "javax.faces.ViewState": data["view_state"],
                "property": f"Global.Dokumentart.{doc_type}",
                "property2": "",
                field_id: field_id,
            }

        r = session.post(data["action"], data=post_data)

        if doc_type == "SI":
            # XML-Antwort
            content = r.text
            cache_file.write_text(content)
            return content
        else:
            # PDF-Antwort
            if output_dir:
                out_path = pathlib.Path(output_dir)
            else:
                out_path = pathlib.Path.cwd()
            out_path.mkdir(parents=True, exist_ok=True)

            filename = f"{register}_{register_number}_{court}_{doc_type}.pdf".replace(" ", "_")
            pdf_path = out_path / filename
            pdf_path.write_bytes(r.content)
            return str(pdf_path)


def list_data(key):
    """Gibt Stammdaten zurueck: registers, courts oder types."""
    if key == "registers":
        return REGISTERS

    with HRSession() as session:
        ctx = _get_context(session)

    if key == "courts":
        return ctx["courts"]
    elif key == "types":
        return ctx["types"]
    else:
        raise ValueError(f"Unbekannter Schluessel: {key}. Verfuegbar: registers, courts, types")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def cmd_search(args):
    results = search_companies(
        keywords=args.query,
        mode=args.mode,
        register=args.register or "",
        register_number=args.register_number or "",
        court=args.court or "",
        legal_form=args.legal_form or "",
        state=args.state or "",
        city=args.city or "",
        zip_code=args.zip_code or "",
        force=args.force,
    )
    output = {
        "query": args.query,
        "mode": args.mode,
        "count": len(results),
        "results": results,
    }
    print(json.dumps(output, ensure_ascii=False, indent=2))


def cmd_document(args):
    try:
        result = get_document(
            register=args.register,
            register_number=args.register_number,
            court=args.court,
            doc_type=args.type,
            output_dir=args.output,
            force=args.force,
        )
        if args.type == "SI":
            print(result)
        else:
            print(json.dumps({"file": result}, ensure_ascii=False))
    except RuntimeError as e:
        print(json.dumps({"error": str(e)}, ensure_ascii=False))
        sys.exit(1)


def cmd_list(args):
    data = list_data(args.key)
    print(json.dumps(data, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(description="Handelsregister Skill")
    sub = parser.add_subparsers(dest="command", required=True)

    # -- search --
    p_search = sub.add_parser("search", help="Unternehmenssuche")
    p_search.add_argument("query", help="Suchbegriff (Firmenname)")
    p_search.add_argument(
        "--mode", default="all", choices=["all", "min", "exact"],
        help="Suchmodus: all (Default), min, exact",
    )
    p_search.add_argument("--register", choices=list(REGISTERS.keys()), help="Registerart filtern")
    p_search.add_argument("--register-number", help="Registernummer")
    p_search.add_argument("--court", help="Registergerichtscode (z.B. M1202)")
    p_search.add_argument("--legal-form", help="Rechtsform-Code")
    p_search.add_argument("--state", choices=STATES, help="Bundesland filtern")
    p_search.add_argument("--city", help="Ort filtern")
    p_search.add_argument("--zip-code", help="PLZ filtern")
    p_search.add_argument("--force", action="store_true", help="Cache umgehen")

    # -- document --
    p_doc = sub.add_parser("document", help="Dokument abrufen (SI/AD/CD/HD)")
    p_doc.add_argument("register", choices=list(REGISTERS.keys()), help="Registerart")
    p_doc.add_argument("register_number", help="Registernummer")
    p_doc.add_argument("court", help="Registergerichtscode")
    p_doc.add_argument(
        "--type", default="SI", choices=list(DOCUMENT_TYPES.keys()),
        help="Dokumenttyp: SI (XML), AD/CD/HD (PDF). Default: SI",
    )
    p_doc.add_argument("--output", help="Ausgabeverzeichnis fuer PDFs")
    p_doc.add_argument("--force", action="store_true", help="Cache umgehen")

    # -- list --
    p_list = sub.add_parser("list", help="Stammdaten auflisten")
    p_list.add_argument(
        "key", choices=["registers", "courts", "types"],
        help="registers=Registerarten, courts=Gerichte, types=Rechtsformen",
    )

    args = parser.parse_args()
    cmd_map = {"search": cmd_search, "document": cmd_document, "list": cmd_list}
    cmd_map[args.command](args)


if __name__ == "__main__":
    main()
