# AgentBox

Agentenübergreifende Toolsammlung für CLI-basierte AI Agents.

Skills, Agenten und Workflows werden zentral in diesem Repository entwickelt und versioniert. Ein Installer verlinkt sie per Symlink in die jeweiligen Agent-Verzeichnisse, sodass alle Tools eine gemeinsame Quelle, eine gemeinsame Python-Venv und eine zentrale `.env` für API-Keys nutzen. Änderungen wirken sofort, ohne erneute Installation.

## Skills

| Skill                          | Version | Features                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Abhängigkeiten                                                        | API-Key               | Startup-Tokens |
| ------------------------------ | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------- | --------------------- | -------------- |
| **apple-notes-write-only**     | 1.0     | • Neue Apple Note mit HTML-formatiertem Body erstellen<br>• Notizen mit Bullet-Listen, nummerierten Listen und Tabellen anlegen<br>• Hyperlinks und fett/kursiven Text in Notizen einbetten<br>• Notizen in beliebige Ordner (Accounts) schreiben                                                                                                                                                                                                                                                                                            | `🖥️ macOS`<br>`Notes`                                                 | —                     | 36             |
| **apple-reminders-write-only** | 1.0     | • Neue Erinnerung mit Titel, Notiztext und Fälligkeitsdatum erstellen<br>• Priorität (hoch/mittel/niedrig) und Ziel-Liste festlegen<br>• ISO-Datetime als Fälligkeitszeitpunkt übergeben (2026-04-28T14:00)<br>• URLs im Notiztext werden automatisch klickbar dargestellt                                                                                                                                                                                                                                                                   | `🖥️ macOS`<br>`Reminders`                                             | —                     | 37             |
| **chart**                      | 1.0     | • Linien-, Balken- und Kreisdiagramme aus JSON-Daten als SVG oder PNG erzeugen<br>• Mehrere Datenreihen in einem Diagramm darstellen<br>• Farbthemen wählen (academic, vibrant, mono, dark)<br>• Achsenbeschriftungen, Titel, Breite und Höhe konfigurieren<br>• Eigene Hex-Farben per --colors überschreiben                                                                                                                                                                                                                                | `⚙️ python`<br>`📦 matplotlib`                                        | —                     | 51             |
| **crawl4ai**                   | 0.7     | • Einzelne oder mehrere URLs crawlen und als Markdown extrahieren<br>• Strukturierte Daten mit JSON-Schema aus Websites extrahieren (LLM-frei)<br>• JavaScript-lastige Seiten mit Browser-Rendering crawlen<br>• Mehrere URLs parallel crawlen und als Datenpipeline verarbeiten<br>• Automatisches Schema aus einer Beispiel-URL generieren                                                                                                                                                                                                 | `⚙️ python`<br>`📦 crawl4ai`                                          | —                     | 66             |
| **folder-picker**              | 1.0     | • Nativen Ordner-Auswahldialog öffnen (macOS Finder, Windows PowerShell, Linux zenity)<br>• Absoluten Pfad des gewählten Ordners zurückgeben<br>• Abbruch durch den User erkennen und erneut nachfragen<br>• Optionalen Prompt-Text für den Dialog übergeben                                                                                                                                                                                                                                                                                 | `⚙️ python`<br>`⚙️ zenity`                                            | —                     | 50             |
| **geo**                        | 2.0     | • Fahrdistanz und -dauer zwischen zwei Orten (Auto, Fahrrad, zu Fuß)<br>• ÖPNV-Routing mit Umstiegszeiten<br>• Turn-by-turn Navigation mit Wegpunkten<br>• Routen-Geometrie als GeoJSON<br>• Distance Matrix (n Starts × m Ziele)<br>• Adresse in Koordinaten umwandeln (Geocoding)<br>• Koordinaten in Adresse umwandeln (Reverse Geocoding)<br>• POI-Suche in einem Radius um einen Ort<br>• Höhenprofil für beliebige Koordinaten<br>• GPS-Trace auf Straßennetz einpassen (Map Matching)<br>• Optimale Rundtour über mehrere Stops (TSP) | `⚙️ python`<br>`📦 googlemaps`<br>`📦 requests`<br>`📦 python-dotenv` | `GOOGLE_MAPS_API_KEY` | 109            |
| **github**                     | 1.0     | • Repos, Issues und Pull Requests eines GitHub-Projekts lesen<br>• PR-Diffs und CI-Run-Status abfragen<br>• Code und Dateiinhalte direkt über die GitHub API abrufen<br>• Repos und Code über GitHub Search durchsuchen<br>• Schreibende Operationen (Kommentare, Labels, Merges) nur nach expliziter Freigabe                                                                                                                                                                                                                               | `⚙️ gh`                                                               | —                     | 69             |
| **handelsregister**            | 1.0     | • Unternehmen im deutschen Handelsregister nach Name, Ort oder Registernummer suchen<br>• Registerauszüge als PDF (aktuell, chronologisch, historisch) abrufen<br>• Strukturierte Unternehmensdaten mit Geschäftsführern, Stammkapital und Prokura auslesen<br>• Nach Rechtsform, Bundesland, Registergericht und PLZ-Bereich filtern                                                                                                                                                                                                        | —                                                                     | —                     | 95             |
| **iconify**                    | 1.0     | • Icons aus 200k+ Iconify-Icons suchen (Lucide, Tabler, Phosphor, Material Design)<br>• Konkretes SVG-Icon per ID (z.B. lucide:gauge) herunterladen<br>• Nach Farbpalette (mono/color/any) und Icon-Set filtern<br>• Top-Treffer suchen und direkt als SVG-Datei speichern                                                                                                                                                                                                                                                                   | —                                                                     | —                     | 79             |
| **image**                      | 1.0     | • Bilder von URLs herunterladen und in ein anderes Format konvertieren<br>• Bilder skalieren (Pixel oder Prozent) und zuschneiden<br>• SVG zu PNG mit konfigurierbarem DPI konvertieren<br>• Dateigröße ohne sichtbaren Qualitätsverlust optimieren<br>• Metadaten (Format, Dimensionen, Dateigröße, Farbraum) auslesen                                                                                                                                                                                                                      | `⚙️ imagemagick`<br>`⚙️ python`<br>`📦 Pillow`                        | —                     | 53             |
| **image-gen**                  | 1.0     | • KI-Bilder aus Textprompts via Google Gemini generieren<br>• Zwischen zwei Qualitätsstufen wählen (hochwertig ~$0.13 oder schnell ~$0.07)<br>• Aspect Ratio (1:1, 16:9, 9:16, 4:3, 3:2) und Auflösung festlegen<br>• Prompts mit Motiv, Komposition, Stil und Atmosphäre formulieren                                                                                                                                                                                                                                                        | —                                                                     | `GEMINI_API_KEY`      | 24             |
| **ocr**                        | 1.0     | • Text aus Bildern (PNG, JPG, TIFF, BMP) extrahieren — auf macOS via Apple Vision hardwarebeschleunigt<br>• Gescannte PDFs in durchsuchbaren Text umwandeln<br>• Mehrere Sprachen gleichzeitig erkennen (z.B. de+en)<br>• Bilder in durchsuchbare PDFs konvertieren                                                                                                                                                                                                                                                                          | `⚙️ tesseract`                                                        | —                     | 36             |
| **pandoc**                     | 1.0     | • Markdown zu PDF mit professionellen Typst-Templates konvertieren<br>• Markdown zu Word (.docx), PowerPoint (.pptx) oder EPUB konvertieren<br>• HTML-Ausgabe mit eingebetteten Ressourcen erzeugen<br>• Inhaltsverzeichnis, Abschnittsnummerierung und Syntax-Highlighting konfigurieren<br>• Word-Dokumente zurück zu Markdown extrahieren                                                                                                                                                                                                 | `⚙️ pandoc`<br>`⚙️ typst`                                             | —                     | 63             |
| **pdf**                        | 1.0     | • Mehrere PDFs zu einem Dokument zusammenführen<br>• PDF nach Seitenbereich aufteilen oder bestimmte Seiten extrahieren<br>• Dateigröße mit einstellbarer Qualitätsstufe komprimieren (screen/ebook/printer/prepress)<br>• PDF mit Passwort verschlüsseln oder Passwortschutz entfernen<br>• Metadaten und Seitenanzahl eines PDFs auslesen                                                                                                                                                                                                  | `⚙️ cpdf`<br>`⚙️ qpdf`<br>`⚙️ ghostscript`                            | —                     | 42             |
| **qr-code**                    | 1.0     | • QR-Code aus URL oder beliebigem Text als PNG oder SVG exportieren<br>• QR-Code direkt im Terminal als UTF8-Grafik anzeigen<br>• Modulgröße und Fehlerkorrekturlevel (L/M/Q/H) einstellen                                                                                                                                                                                                                                                                                                                                                   | `⚙️ qrencode`                                                         | —                     | 48             |
| **ssh**                        | 1.0     | • SSH-Verbindung zu entfernten Hosts über ~/.ssh/config herstellen<br>• Software installieren, Dienste konfigurieren und Logs auf Remote-Systemen prüfen<br>• Lesende Befehle direkt ausführen, schreibende Befehle mit Rückfrage absichern<br>• Dateien auf Remote-Systemen bearbeiten<br>• Neuen Host interaktiv per setup-Skript einrichten                                                                                                                                                                                               | —                                                                     | —                     | 43             |
| **tavily**                     | 1.0     | • Breite Web-Recherche mit Quellensynthese und nummerierten Zitaten<br>• Aktuelle News, Trends und Vendor-Listen zu einem Thema abrufen<br>• Markt- und Wettbewerbsanalysen für strategische Fragen<br>• Gezielte Nachschlag-Suche nach einem Research-Report                                                                                                                                                                                                                                                                                | —                                                                     | `TAVILY_API_KEY`      | 88             |
| **youtube-dlp**                | 1.0     | • Video-Metadaten (Titel, Kanal, Datum, Beschreibung) ohne Download abrufen<br>• Transkripte aus manuellen oder automatischen Untertiteln extrahieren (de/en/…)<br>• YouTube-Suchergebnisse und Playlist-Inhalte als strukturierte Quellenliste abrufen<br>• Audio (m4a/mp3) oder Video (mp4) nur bei explizitem Download-Auftrag speichern                                                                                                                                                                                                  | `⚙️ yt-dlp`<br>`⚙️ ffmpeg`                                            | —                     | 107            |

_Gesamt-Kontextgröße aller Skills beim Start: **1,096 Tokens**_

## Binaries

| Binary        | Skill(s)                                                     |
| ------------- | ------------------------------------------------------------ |
| `cpdf`        | pdf                                                          |
| `ffmpeg`      | youtube-dlp                                                  |
| `gh`          | github                                                       |
| `ghostscript` | pdf                                                          |
| `imagemagick` | image                                                        |
| `pandoc`      | pandoc                                                       |
| `python`      | • chart<br>• crawl4ai<br>• folder-picker<br>• geo<br>• image |
| `qpdf`        | pdf                                                          |
| `qrencode`    | qr-code                                                      |
| `tesseract`   | ocr                                                          |
| `typst`       | pandoc                                                       |
| `yt-dlp`      | youtube-dlp                                                  |
| `zenity`      | folder-picker                                                |

## Agenten

| Agent             | Beschreibung                                                                                         |
| ----------------- | ---------------------------------------------------------------------------------------------------- |
| **deep-research** | Mehrstufige Tiefenrecherche mit Quellenanalyse, Wissenslücken-Tracking und strukturierter Synthese   |
| **report-writer** | Strukturiert Rechercheergebnisse in wissenschaftlich konsistente Berichte und erzeugt PDF via pandoc |

## Permissions

Der Installer verteilt Berechtigungsregeln aus `assets/permissions/rules.json` in die Config-Dateien der Agents, damit häufig genutzte Befehle (Skill-Scripts, lokale CLI-Tools, `gh`-Leseoperationen) nicht jedes Mal manuell bestätigt werden müssen.

| Agent       | Ziel-Config                         | Format                                     |
| ----------- | ----------------------------------- | ------------------------------------------ |
| Claude Code | `~/.claude/settings.json`           | `Bash(pattern)` in `allow[]`               |
| Codex       | `~/.codex/rules/agentic.rules`      | Starlark `prefix_rule()`                   |
| Gemini CLI  | `~/.gemini/settings.json`           | `run_shell_command()` in `tools.allowed[]` |
| OpenCode    | `~/.config/opencode/.opencode.json` | Pattern in `permission.bash{}`             |

## Installation

```bash
git clone https://github.com/mgiesen/AgentBox.git && cd AgentBox
./scripts/install.sh              # Interaktiver Installer (TUI)
```

Oder direkt:

```bash
./scripts/install.sh --all        # Alle Skills für alle Agents installieren
./scripts/install.sh --status     # Installationsstatus anzeigen
./scripts/install.sh --uninstall  # Alle Skills deinstallieren
./scripts/install.sh --check      # Dependencies prüfen und installieren (Venv, Brew)
```

Der Installer richtet die Venv ein, installiert Python- und Brew-Dependencies und erstellt Symlinks in die globalen Agent-Verzeichnisse. Änderungen an Skills wirken sofort.

Nach der Installation: API-Keys in `.env` eintragen.

## Roadmap: Sandbox-Modus (Docker)

Das Repo soll langfristig zwei Nutzungsmodi bieten:

| Modus                 | Zielgruppe                         | Setup                                                                                   |
| --------------------- | ---------------------------------- | --------------------------------------------------------------------------------------- |
| **Host-Installation** | Erfahrene Entwickler               | `install.sh` verlinkt Skills/Agents per Symlink in die lokalen Agent-Verzeichnisse      |
| **Sandbox (Docker)**  | Einsteiger, Unternehmensumgebungen | Vorkonfiguriertes Docker-Image mit allen Agents, Skills und Dependencies out of the box |

### Idee

Ein Docker-Image, das alle vier Agentensysteme (Claude Code, Codex, Gemini CLI, OpenCode) inklusive Skills, Agents und Dependencies vorinstalliert enthält. User pullen das Image, hinterlegen ihre API-Keys/Credentials und können direkt loslegen — ohne lokale Installation.

### Sicherheitskonzept

- Der Container läuft unprivilegiert
- Ein einzelner Ordner (z.B. `workspace/`) wird als Volume gemountet und ist der einzige beschreibbare Ort — Arbeitsverzeichnis für Input und Output
- Der Agent hat keinen Zugriff auf das Host-Filesystem, SSH-Keys, Browser-Credentials oder andere Repos
- Netzwerk-Egress wird auf die benötigten API-Endpunkte beschränkt
- Selbst bei Prompt Injection oder Fehlbedienung kann der Agent nicht über den gemounteten Ordner hinaus operieren — die Isolation wird auf OS-Ebene erzwungen

### Distribution

Das Image wird über die GitHub Container Registry bereitgestellt. Angedachter Workflow:

```bash
docker pull ghcr.io/mgiesen/agentbox:latest
docker run --read-only --tmpfs /tmp -v ./dir:/workspace -it agentbox
```

### Offene Punkte

- Hosting der API-Keys: Docker Secrets, `.env`-Mount oder interaktive Eingabe beim Start
- Ein Image für alle Agents vs. ein Base-Image mit Agent-spezifischen Varianten
- Kennzeichnung von Skills, die im Container nicht verfügbar sind (z.B. Apple Notes, Folder Picker)
- Egress-Whitelist für erlaubte API-Endpunkte
