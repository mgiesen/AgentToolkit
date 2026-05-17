[← Zurück zur README](../README.md)

# Skills

| Skill | Version | Plattform | Features | Abhängigkeiten | API-Key | Startup-Tokens |
| --- | --- | --- | --- | --- | --- | --- |
| **apple-notes-write-only** | 1.0 | macOS | • Neue Apple Note mit HTML-formatiertem Body erstellen<br>• Notizen mit Bullet-Listen, nummerierten Listen und Tabellen anlegen<br>• Hyperlinks und fett/kursiven Text in Notizen einbetten<br>• Notizen in beliebige Ordner (Accounts) schreiben | — | — | 36 |
| **apple-reminders-write-only** | 1.0 | macOS | • Neue Erinnerung mit Titel, Notiztext und Fälligkeitsdatum erstellen<br>• Priorität (hoch/mittel/niedrig) und Ziel-Liste festlegen<br>• ISO-Datetime als Fälligkeitszeitpunkt übergeben (2026-04-28T14:00)<br>• URLs im Notiztext werden automatisch klickbar dargestellt | — | — | 37 |
| **chart** | 1.0 | Alle | • Linien-, Balken- und Kreisdiagramme aus JSON-Daten als SVG oder PNG erzeugen<br>• Mehrere Datenreihen in einem Diagramm darstellen<br>• Farbthemen wählen (academic, vibrant, mono, dark)<br>• Achsenbeschriftungen, Titel, Breite und Höhe konfigurieren<br>• Eigene Hex-Farben per --colors überschreiben | `📦 matplotlib` | — | 51 |
| **crawl4ai** | 0.7 | Alle | • Einzelne oder mehrere URLs crawlen und als Markdown extrahieren<br>• Strukturierte Daten mit JSON-Schema aus Websites extrahieren (LLM-frei)<br>• JavaScript-lastige Seiten mit Browser-Rendering crawlen<br>• Mehrere URLs parallel crawlen und als Datenpipeline verarbeiten<br>• Automatisches Schema aus einer Beispiel-URL generieren | `📦 crawl4ai` | — | 66 |
| **folder-picker** | 1.0 | Alle | • Nativen Ordner-Auswahldialog öffnen (macOS Finder, Windows PowerShell, Linux zenity)<br>• Absoluten Pfad des gewählten Ordners zurückgeben<br>• Abbruch durch den User erkennen und erneut nachfragen<br>• Optionalen Prompt-Text für den Dialog übergeben | `⚙️ zenity` | — | 50 |
| **geo** | 2.0 | Alle | • Fahrdistanz und -dauer zwischen zwei Orten (Auto, Fahrrad, zu Fuß)<br>• ÖPNV-Routing mit Umstiegszeiten<br>• Turn-by-turn Navigation mit Wegpunkten<br>• Routen-Geometrie als GeoJSON<br>• Distance Matrix (n Starts × m Ziele)<br>• Adresse in Koordinaten umwandeln (Geocoding)<br>• Koordinaten in Adresse umwandeln (Reverse Geocoding)<br>• POI-Suche in einem Radius um einen Ort<br>• Höhenprofil für beliebige Koordinaten<br>• GPS-Trace auf Straßennetz einpassen (Map Matching)<br>• Optimale Rundtour über mehrere Stops (TSP) | `📦 googlemaps`<br>`📦 requests`<br>`📦 python-dotenv` | `GOOGLE_MAPS_API_KEY` *(optional)* | 109 |
| **github** | 1.0 | Alle | • Repos, Issues und Pull Requests eines GitHub-Projekts lesen<br>• PR-Diffs und CI-Run-Status abfragen<br>• Code und Dateiinhalte direkt über die GitHub API abrufen<br>• Repos und Code über GitHub Search durchsuchen<br>• Schreibende Operationen (Kommentare, Labels, Merges) nur nach expliziter Freigabe | `⚙️ gh` | — | 69 |
| **gitlab** | 1.0 | Alle | • Repos, Issues und Merge Requests eines GitLab-Projekts lesen<br>• MR-Diffs und CI-Pipeline-Status abfragen (inkl. Job-Logs streamen)<br>• Code und Dateiinhalte direkt über die GitLab API abrufen<br>• Repos und Code über GitLab Search durchsuchen<br>• Self-hosted GitLab-Instanzen über GITLAB_HOST oder volle URLs ansprechen<br>• Schreibende Operationen (Kommentare, Labels, Merges) nur nach expliziter Freigabe | `⚙️ glab` | `GITLAB_TOKEN` *(optional)* | 82 |
| **handelsregister** | 1.0 | Alle | • Unternehmen im deutschen Handelsregister nach Name, Ort oder Registernummer suchen<br>• Registerauszüge als PDF (aktuell, chronologisch, historisch) abrufen<br>• Strukturierte Unternehmensdaten mit Geschäftsführern, Stammkapital und Prokura auslesen<br>• Nach Rechtsform, Bundesland, Registergericht und PLZ-Bereich filtern | `📦 requests`<br>`📦 beautifulsoup4` | — | 95 |
| **iconify** | 1.0 | Alle | • Icons aus 200k+ Iconify-Icons suchen (Lucide, Tabler, Phosphor, Material Design)<br>• Konkretes SVG-Icon per ID (z.B. lucide:gauge) herunterladen<br>• Nach Farbpalette (mono/color/any) und Icon-Set filtern<br>• Top-Treffer suchen und direkt als SVG-Datei speichern | `📦 requests` | — | 79 |
| **image** | 1.3 | Alle | • Bilder von URLs herunterladen und in ein anderes Format konvertieren<br>• Bilder skalieren (Pixel oder Prozent) und zuschneiden<br>• SVG zu PNG mit konfigurierbarem DPI konvertieren<br>• Dateigröße ohne sichtbaren Qualitätsverlust optimieren<br>• Metadaten (Format, Dimensionen, Dateigröße, Farbraum) auslesen<br>• Mehrere Bilder zu Collagen oder NxM-Grids zusammenbauen (Reihe, Spalte, Raster) mit konfigurierbarem Hintergrund und Abstand | `⚙️ magick`<br>`📦 Pillow` | — | 103 |
| **image-gen** | 1.0 | Alle | • KI-Bilder aus Textprompts via Google Gemini generieren<br>• Zwischen zwei Qualitätsstufen wählen (hochwertig ~$0.13 oder schnell ~$0.07)<br>• Aspect Ratio (1:1, 16:9, 9:16, 4:3, 3:2) und Auflösung festlegen<br>• Prompts mit Motiv, Komposition, Stil und Atmosphäre formulieren | — | `GEMINI_IMAGE_GEN_API_KEY` | 24 |
| **ocr** | 1.0 | Alle | • Text aus Bildern (PNG, JPG, TIFF, BMP) extrahieren — auf macOS via Apple Vision hardwarebeschleunigt<br>• Gescannte PDFs in durchsuchbaren Text umwandeln<br>• Mehrere Sprachen gleichzeitig erkennen (z.B. de+en)<br>• Bilder in durchsuchbare PDFs konvertieren | `⚙️ tesseract` | — | 36 |
| **pandoc** | 1.0 | Alle | • Markdown zu PDF mit professionellen Typst-Templates konvertieren<br>• Markdown zu Word (.docx), PowerPoint (.pptx) oder EPUB konvertieren<br>• HTML-Ausgabe mit eingebetteten Ressourcen erzeugen<br>• Inhaltsverzeichnis, Abschnittsnummerierung und Syntax-Highlighting konfigurieren<br>• Word-Dokumente zurück zu Markdown extrahieren | `⚙️ pandoc`<br>`⚙️ typst` | — | 63 |
| **pdf** | 1.0 | Alle | • Mehrere PDFs zu einem Dokument zusammenführen<br>• PDF nach Seitenbereich aufteilen oder bestimmte Seiten extrahieren<br>• Dateigröße mit einstellbarer Qualitätsstufe komprimieren (screen/ebook/printer/prepress)<br>• PDF mit Passwort verschlüsseln oder Passwortschutz entfernen<br>• Metadaten und Seitenanzahl eines PDFs auslesen | `⚙️ cpdf`<br>`⚙️ qpdf`<br>`⚙️ gs` | — | 42 |
| **qr-code** | 1.0 | Alle | • QR-Code aus URL oder beliebigem Text als PNG oder SVG exportieren<br>• QR-Code direkt im Terminal als UTF8-Grafik anzeigen<br>• Modulgröße und Fehlerkorrekturlevel (L/M/Q/H) einstellen | `⚙️ qrencode` | — | 48 |
| **ssh** | 1.0 | Alle | • SSH-Verbindung zu entfernten Hosts über ~/.ssh/config herstellen<br>• Software installieren, Dienste konfigurieren und Logs auf Remote-Systemen prüfen<br>• Lesende Befehle direkt ausführen, schreibende Befehle mit Rückfrage absichern<br>• Dateien auf Remote-Systemen bearbeiten<br>• Neuen Host interaktiv per setup-Skript einrichten | — | — | 43 |
| **tavily** | 1.0 | Alle | • Breite Web-Recherche mit Quellensynthese und nummerierten Zitaten<br>• Aktuelle News, Trends und Vendor-Listen zu einem Thema abrufen<br>• Markt- und Wettbewerbsanalysen für strategische Fragen<br>• Gezielte Nachschlag-Suche nach einem Research-Report | `📦 tavily-cli` | `TAVILY_API_KEY` | 88 |
| **youtube-dlp** | 1.0 | Alle | • Video-Metadaten (Titel, Kanal, Datum, Beschreibung) ohne Download abrufen<br>• Transkripte aus manuellen oder automatischen Untertiteln extrahieren (de/en/…)<br>• YouTube-Suchergebnisse und Playlist-Inhalte als strukturierte Quellenliste abrufen<br>• Audio (m4a/mp3) oder Video (mp4) nur bei explizitem Download-Auftrag speichern | `⚙️ yt-dlp`<br>`⚙️ ffmpeg` | — | 107 |

_Gesamt-Kontextgröße aller Skills beim Start: **1,228 Tokens**_







## Binaries

| Binary | Skill(s) |
| --- | --- |
| `cpdf` | pdf |
| `ffmpeg` | youtube-dlp |
| `gh` | github |
| `glab` | gitlab |
| `gs` | pdf |
| `magick` | image |
| `pandoc` | pandoc |
| `qpdf` | pdf |
| `qrencode` | qr-code |
| `tesseract` | ocr |
| `typst` | pandoc |
| `yt-dlp` | youtube-dlp |
| `zenity` | folder-picker |

