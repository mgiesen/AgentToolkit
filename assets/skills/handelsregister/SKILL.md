---
name: handelsregister
version: "1.0"
description: Durchsucht das deutsche Handelsregister und ruft Registerauszuege als PDF ab. Liefert Firma, Sitz, Geschaeftszweck, Stammkapital, Geschaeftsfuehrer, Prokura, Vertretungsregelung, Rechtsform, Satzungsaenderungen, Kapitalentwicklung, Verschmelzungen und komplette Unternehmenshistorie.
requires: {}
features:
  - Unternehmen im deutschen Handelsregister nach Name, Ort oder Registernummer suchen
  - Registerauszüge als PDF (aktuell, chronologisch, historisch) abrufen
  - Strukturierte Unternehmensdaten mit Geschäftsführern, Stammkapital und Prokura auslesen
  - Nach Rechtsform, Bundesland, Registergericht und PLZ-Bereich filtern
---

# Handelsregister Skill

Abfrage des oeffentlichen deutschen Handelsregisters (handelsregister.de). Liefert Registerdaten zu Unternehmen: Name, Registergericht, Registernummer, Bundesland, Status und Namenshistorie. Kann ausserdem Dokumente (SI-XML, PDF-Abdrucke) abrufen.

Keine API-Keys erforderlich. Ergebnisse werden lokal gecacht.

## Wichtig

- Maximal 60 Abfragen pro Stunde (Nutzungsbedingungen des Portals).
- Keine parallelen Abfragen starten.

## Commands

### search

Unternehmenssuche mit optionalen Filtern. Ausgabe ist immer JSON.

```bash
# Einfache Suche
scripts/handelsregister.sh search "Deutsche Bahn"

# Suchmodi
scripts/handelsregister.sh search "Siemens" --mode exact
scripts/handelsregister.sh search "Gasag" --mode min

# Erweiterte Filter
scripts/handelsregister.sh search "BMW" --state Bayern
scripts/handelsregister.sh search "GmbH" --register HRB --city Berlin
scripts/handelsregister.sh search "" --register HRB --register-number 12345 --court M1202
scripts/handelsregister.sh search "Logistik" --zip-code "10*" --legal-form 8

# Cache umgehen
scripts/handelsregister.sh search "BMW" --force
```

**Suchmodi:** `all` (alle Begriffe enthalten, Default), `min` (mindestens ein Begriff), `exact` (exakter Firmenname).

**Filter:** `--register` (HRA/HRB/GnR/PR/VR), `--register-number`, `--court` (Gerichtscode), `--legal-form` (Rechtsform-Code), `--state` (Bundesland), `--city`, `--zip-code`.

### document

Dokumente fuer einen konkreten Registereintrag abrufen. Benoetigt Registerart, Registernummer und Gerichtscode (aus den Suchergebnissen).

```bash
# Strukturierte Inhalte als XML (Default)
scripts/handelsregister.sh document HRB 12345 M1202

# Aktueller Abdruck als PDF
scripts/handelsregister.sh document HRB 12345 M1202 --type AD

# Chronologischer Abdruck als PDF
scripts/handelsregister.sh document HRB 12345 M1202 --type CD

# Historischer Abdruck als PDF
scripts/handelsregister.sh document HRB 12345 M1202 --type HD

# PDF in bestimmtes Verzeichnis speichern
scripts/handelsregister.sh document HRB 12345 M1202 --type AD --output /tmp/hr_docs
```

**Dokumenttypen:** `SI` (Strukturierte Inhalte, XML), `AD` (Aktueller Abdruck, PDF), `CD` (Chronologischer Abdruck, PDF), `HD` (Historischer Abdruck, PDF).

Bei SI wird der XML-Inhalt auf stdout ausgegeben. Bei PDF-Typen wird die Datei gespeichert und der Pfad als JSON zurueckgegeben. PDFs koennen anschliessend mit dem pdf- oder crawl4ai-Skill gelesen werden.

### list

Stammdaten des Registerportals auflisten.

```bash
# Alle Registerarten
scripts/handelsregister.sh list registers

# Alle Registergerichte mit Codes
scripts/handelsregister.sh list courts

# Alle Rechtsformen mit Codes
scripts/handelsregister.sh list types
```

Ausgabe ist immer JSON. Die Codes aus `courts` und `types` koennen als Filter in der Suche verwendet werden.
