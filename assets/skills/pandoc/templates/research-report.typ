// Research Report Template — Wissenschaftliche Berichte und Rechercheergebnisse
// Font: Charter (Serif Body), Avenir Next (Headings), Menlo (Code)
// Konventionen: IEEE-Stil Quellenangaben [1], nummerierte Abbildungen/Tabellen/Gleichungen

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
  margin: (x: 2.2cm, y: 2.2cm),
  paper: "a4",
  lang: "de",
  region: "DE",
  font: none,
  fontsize: 11pt,
  mathfont: none,
  codefont: none,
  linestretch: 1.5,
  sectionnumbering: "1.1",
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  pagenumbering: "1",
  doc,
) = {
  let primary-color = rgb("#1a1a2e")
  let accent-color = rgb("#2d5f9a")
  let light-gray = rgb("#f5f5f7")
  let mid-gray = rgb("#86868b")
  let body-font = if font != none { font } else { ("Charter", "Libertinus Serif") }
  let heading-font = ("Avenir Next", "Libertinus Serif")
  let mono-font = if codefont != none { codefont } else { ("Menlo",) }

  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
    header: context {
      if counter(page).get().first() > 1 {
        set text(size: 8.5pt, fill: mid-gray, font: body-font)
        grid(
          columns: (1fr, 1fr),
          align: (left, right),
          if title != none { title } else { [] },
          if date != none { date } else { [] },
        )
      }
    },
    footer: context {
      set text(size: 8.5pt, fill: mid-gray, font: body-font)
      grid(
        columns: (1fr, 1fr),
        align: (left, right),
        if authors.len() > 0 {
          if type(authors.first()) == dictionary { authors.first().at("name", default: "") } else { authors.first() }
        } else { [] },
        counter(page).display("1 / 1", both: true),
      )
    },
  )

  set text(
    font: body-font,
    size: fontsize,
    fill: primary-color,
    lang: lang,
    region: region,
  )

  set par(justify: true, leading: linestretch * 0.65em)

  // Nummerierte Ueberschriften
  set heading(numbering: sectionnumbering)

  show heading.where(level: 1): it => {
    v(1.4em)
    block(below: 0.8em)[
      #set text(size: 1.4em, weight: "bold", fill: primary-color, font: heading-font)
      #it
    ]
  }

  show heading.where(level: 2): it => {
    v(1em)
    block(below: 0.6em)[
      #set text(size: 1.15em, weight: "semibold", fill: accent-color, font: heading-font)
      #it
    ]
  }

  show heading.where(level: 3): it => {
    v(0.6em)
    block(below: 0.4em)[
      #set text(size: 1.0em, weight: "medium", fill: primary-color, font: heading-font)
      #it
    ]
  }

  // Links
  show link: it => {
    let color = if linkcolor != none { rgb(linkcolor) } else { accent-color }
    set text(fill: color)
    underline(offset: 2pt, stroke: 0.5pt + color, it)
  }

  // Code
  show raw.where(block: true): it => {
    block(
      width: 100%,
      fill: light-gray,
      inset: (x: 14pt, y: 10pt),
      radius: 4pt,
      stroke: 0.5pt + rgb("#e0e0e0"),
    )[
      #set text(font: mono-font, size: 0.85em)
      #set par(leading: 0.6em)
      #it
    ]
  }

  show raw.where(block: false): it => {
    box(
      fill: light-gray,
      inset: (x: 4pt, y: 2pt),
      radius: 2pt,
    )[#set text(font: mono-font, size: 0.85em); #it]
  }

  // Abbildungen: Beschriftung unter der Abbildung, nummeriert
  set figure(numbering: "1")
  set figure.caption(separator: [ — ])
  show figure.caption: it => {
    set text(size: 0.9em, style: "italic", fill: rgb("#444"))
    it
  }

  // Tabellen: Beschriftung ueber der Tabelle
  show figure.where(kind: table): set figure.caption(position: top)
  set table(
    inset: 8pt,
    stroke: (x: none, y: 0.5pt + rgb("#e0e0e0")),
  )
  show table.hline: none
  show table.cell: set align(left)
  show table.cell.where(y: 0): set text(weight: "semibold", fill: primary-color)
  set table(fill: (_, y) => if y == 0 { rgb("#e8eef5") } else { none })

  // Gleichungen nummeriert
  set math.equation(numbering: "(1)")

  // Blockzitate (fuer Quellenangaben)
  show quote: it => {
    block(
      width: 100%,
      inset: (left: 16pt, y: 8pt),
      stroke: (left: 3pt + accent-color),
    )[
      #set text(style: "italic", fill: rgb("#555"))
      #it.body
    ]
  }

  // --- Titelseite ---
  if title != none {
    v(2cm)
    block[
      #set text(size: 2em, weight: "bold", fill: primary-color, font: heading-font)
      #title
    ]
    if subtitle != none {
      v(0.3cm)
      block[
        #set text(size: 1.2em, weight: "regular", fill: accent-color, font: heading-font)
        #subtitle
      ]
    }
    v(0.6cm)
    line(length: 30%, stroke: 2pt + accent-color)
    v(0.8cm)

    if authors.len() > 0 {
      for author in authors {
        block(below: 0.4em)[
          #set text(size: 1.05em)
          #if type(author) == dictionary {
            [#text(weight: "semibold")[#author.at("name", default: "")]
            #if author.at("affiliation", default: "") != "" [ — #author.affiliation]
            #if author.at("email", default: "") != "" [ · #text(fill: accent-color)[#author.email]]]
          } else {
            text(weight: "semibold")[#author]
          }
        ]
      }
    }

    if date != none {
      v(0.4cm)
      text(size: 1em, fill: mid-gray)[#date]
    }

    if abstract != none {
      v(1cm)
      block(
        width: 100%,
        inset: (x: 20pt, y: 14pt),
        fill: light-gray,
        radius: 4pt,
      )[
        #if abstract-title != none {
          text(weight: "semibold", size: 0.95em)[#abstract-title]
          parbreak()
        } else {
          text(weight: "semibold", size: 0.95em)[Zusammenfassung]
          parbreak()
        }
        #set text(size: 0.95em)
        #abstract
      ]
    }

    if keywords.len() > 0 {
      v(0.4cm)
      text(size: 0.9em, fill: mid-gray)[*Schlagwörter:* #keywords.join(", ")]
    }

    pagebreak()
  }

  // --- Body ---
  set page(columns: cols)
  doc
}
