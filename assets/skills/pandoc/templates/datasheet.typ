// Datasheet Template — Technische Datenblätter
// Schwarz/Weiss, Tabellen mit vollständigem Gitterrahmen, linksbündig
// Saubere Seitenumbrüche bei Tabellen mit wiederholtem Header
// Fonts: Helvetica Neue (Body/Headings), Menlo (Code/BMK)

#let conf(
  title: none,
  subtitle: none,
  authors: (),
  keywords: (),
  date: none,
  abstract-title: none,
  abstract: none,
  thanks: none,
  cols: 1,
  margin: (top: 1.8cm, bottom: 1.6cm, x: 1.8cm),
  paper: "a4",
  flipped: true,
  lang: "de",
  region: "DE",
  font: none,
  fontsize: 9.5pt,
  mathfont: none,
  codefont: none,
  linestretch: 1.25,
  sectionnumbering: "1.1",
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  pagenumbering: "1 / 1",
  doc,
) = {
  let ink = rgb("#000000")
  let header-fill = rgb("#dcdcdc")
  let zebra-fill = rgb("#f4f4f4")
  let mid-gray = rgb("#505050")
  let body-font = if font != none { font } else { ("Helvetica Neue", "Helvetica", "Arial") }
  let mono-font = if codefont != none { codefont } else { ("Menlo", "Consolas", "Courier New") }
  let border-stroke = 0.6pt + ink

  set page(
    paper: paper,
    flipped: flipped,
    margin: margin,
    numbering: pagenumbering,
    header: context {
      set text(size: 8pt, fill: ink, font: body-font)
      grid(
        columns: (1fr, auto),
        align: (left, right),
        if title != none { strong(title) } else { [] },
        if date != none { date } else { [] },
      )
      v(2pt)
      line(length: 100%, stroke: border-stroke)
    },
    footer: context {
      set text(size: 8pt, fill: ink, font: body-font)
      align(right, counter(page).display("1 / 1", both: true))
    },
  )

  set text(
    font: body-font,
    size: fontsize,
    fill: ink,
    lang: lang,
    region: region,
    hyphenate: true,
  )

  set par(justify: false, leading: linestretch * 0.5em, linebreaks: "optimized")

  // Überschriften — sachlich, schwarz, mit Rahmen-Akzent
  if sectionnumbering != none {
    set heading(numbering: sectionnumbering)
  }

  // Überschriften an folgendes Element binden (sticky), damit kein
  // Seitenumbruch zwischen Heading und nachfolgendem Inhalt entsteht.
  show heading.where(level: 1): it => {
    pagebreak(weak: true)
    v(0.4em)
    block(width: 100%, below: 0.8em, above: 0em, sticky: true)[
      #set text(size: 1.35em, weight: "bold", fill: ink)
      #it
    ]
  }

  show heading.where(level: 2): it => {
    v(0.8em)
    block(width: 100%, below: 0.5em, sticky: true)[
      #set text(size: 1.1em, weight: "bold", fill: ink)
      #it
    ]
  }

  show heading.where(level: 3): it => {
    v(0.5em)
    block(below: 0.3em, sticky: true)[
      #set text(size: 1.0em, weight: "bold", fill: ink)
      #it
    ]
  }

  show heading.where(level: 4): it => {
    v(0.3em)
    block(below: 0.2em, sticky: true)[
      #set text(size: 0.95em, weight: "bold", style: "italic", fill: ink)
      #it
    ]
  }


  // Links — schwarz, unterstrichen (technisch, keine Farbe)
  show link: it => {
    underline(offset: 2pt, stroke: 0.4pt + ink, it)
  }

  // Inline-Code (BMK-Referenzen) — Monospace, dezent, umbruchfreundlich
  show raw.where(block: false): it => {
    set text(font: mono-font, size: 0.85em)
    it
  }

  // Code-Blöcke
  show raw.where(block: true): it => {
    block(
      width: 100%,
      fill: rgb("#f4f4f4"),
      inset: (x: 10pt, y: 8pt),
      radius: 0pt,
      stroke: border-stroke,
    )[
      #set text(font: mono-font, size: 0.85em)
      #set par(leading: 0.5em, justify: false)
      #it
    ]
  }

  // ---- Tabellen: Datenblatt-Stil ----
  // Vollständiges schwarzes Gitter, linksbündig, oben ausgerichtet,
  // grauer Header der bei Seitenumbruch wiederholt wird, Zebra-Streifen
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: table): set block(breakable: true)

  set table(
    inset: (x: 4pt, y: 3pt),
    stroke: border-stroke,
    fill: (_, y) => if y == 0 { header-fill } else if calc.odd(y) { zebra-fill } else { white },
  )

  // Tabellen einfach passthrough lassen; Spaltenbreiten werden vor der
  // typst-Kompilierung im Pandoc-Output (Prozentangaben) normalisiert.

  // Tabellen kompakter rendern — kleinere Schrift, knapper Zeilenabstand,
  // Hyphenation aktiv für saubere Umbrüche bei engen Spalten
  show table: set text(size: 8pt, hyphenate: true)
  show table: set par(leading: 0.35em, justify: false, linebreaks: "simple")

  // Pandoc erzeugt nach table.header() eine zusätzliche table.hline — entfernen,
  // damit keine doppelten Linien entstehen. Der Standard-Stroke der Tabelle
  // erzeugt bereits den vollen Rahmen.
  show table.hline: none
  show table.vline: none

  // Pandoc wickelt Tabellen in align(center)[...] — Zellinhalte linksbündig
  show table.cell: it => {
    set align(left + top)
    set text(hyphenate: true)
    it
  }
  show table.cell.where(y: 0): it => {
    set align(left + horizon)
    set text(weight: "bold", fill: ink, hyphenate: true)
    it
  }

  // Tabellen sollen bei Seitenumbruch den Header wiederholen.
  // Pandoc gibt Tabellen mit table.header() aus — Typst wiederholt diesen
  // standardmässig bei Seitenumbruch innerhalb einer breakable figure.

  // Listen — kompakt
  set list(indent: 0.6em, body-indent: 0.4em, marker: ([▪], [•], [◦]))
  set enum(indent: 0.6em, body-indent: 0.4em)

  // Horizontale Trennlinien
  let horizontalrule = {
    v(0.4em)
    line(length: 100%, stroke: border-stroke)
    v(0.4em)
  }

  // Blockzitate / Hinweise
  show quote: it => {
    block(
      width: 100%,
      inset: (x: 10pt, y: 6pt),
      stroke: (left: 2pt + ink),
      fill: rgb("#f7f7f7"),
    )[
      #set text(style: "italic")
      #it.body
    ]
  }

  // ---- Body ----
  // Kein Deckblatt — direkt mit Inhalt starten.
  set page(columns: cols)
  doc
}
