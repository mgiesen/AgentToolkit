// Report Template — Professionelle Berichte und Dokumentationen
// Fonts: Avenir Next (Body/Headings), Menlo (Code)

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
  margin: (x: 2.5cm, y: 2.5cm),
  paper: "a4",
  lang: "de",
  region: "DE",
  font: none,
  fontsize: 11pt,
  mathfont: none,
  codefont: none,
  linestretch: 1.5,
  sectionnumbering: none,
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
  let body-font = if font != none { font } else { ("Avenir Next",) }
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
        v(-4pt)
        line(length: 100%, stroke: 0.4pt + rgb("#e0e0e0"))
      }
    },
    footer: context {
      set text(size: 8.5pt, fill: mid-gray, font: body-font)
      line(length: 100%, stroke: 0.4pt + rgb("#e0e0e0"))
      v(4pt)
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

  // Headings
  show heading.where(level: 1): it => {
    v(1.2em)
    block(below: 0.8em)[
      #set text(size: 1.5em, weight: "bold", fill: primary-color)
      #it.body
      #v(-0.3em)
      #line(length: 100%, stroke: 2pt + accent-color)
    ]
  }

  show heading.where(level: 2): it => {
    v(0.8em)
    block(below: 0.6em)[
      #set text(size: 1.2em, weight: "semibold", fill: accent-color)
      #it.body
    ]
  }

  show heading.where(level: 3): it => {
    v(0.6em)
    block(below: 0.4em)[
      #set text(size: 1.05em, weight: "medium", fill: primary-color)
      #it.body
    ]
  }

  if sectionnumbering != none {
    set heading(numbering: sectionnumbering)
  }

  // Links
  show link: it => {
    let color = if linkcolor != none { rgb(linkcolor) } else { accent-color }
    set text(fill: color)
    underline(offset: 2pt, stroke: 0.5pt + color, it)
  }

  // Code blocks
  show raw.where(block: true): it => {
    block(
      width: 100%,
      fill: light-gray,
      inset: (x: 14pt, y: 10pt),
      radius: 4pt,
      stroke: 0.5pt + rgb("#e0e0e0"),
    )[
      #set text(font: mono-font, size: 0.88em)
      #set par(leading: 0.6em)
      #it
    ]
  }

  show raw.where(block: false): it => {
    box(
      fill: light-gray,
      inset: (x: 4pt, y: 2pt),
      radius: 2pt,
    )[#set text(font: mono-font, size: 0.88em); #it]
  }

  // Tables
  show figure.where(kind: table): set figure.caption(position: top)
  set table(
    inset: 8pt,
    stroke: (x: none, y: 0.5pt + rgb("#e0e0e0")),
  )
  show table.cell.where(y: 0): it => {
    set text(weight: "semibold", fill: white)
    table.cell(fill: accent-color, it)
  }

  // Blockquotes
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

  // Horizontal rules (pandoc erzeugt diese als custom horizontalrule-Variable)
  let horizontalrule = {
    v(0.5em)
    line(length: 100%, stroke: 0.5pt + rgb("#e0e0e0"))
    v(0.5em)
  }

  // --- Title Page ---
  if title != none {
    v(3cm)
    block[
      #set text(size: 2.2em, weight: "bold", fill: primary-color)
      #title
    ]
    if subtitle != none {
      v(0.3cm)
      block[
        #set text(size: 1.3em, weight: "regular", fill: accent-color)
        #subtitle
      ]
    }
    v(0.6cm)
    line(length: 40%, stroke: 2.5pt + accent-color)
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
        }
        #set text(size: 0.95em)
        #abstract
      ]
    }

    pagebreak()
  }

  // --- Body ---
  set page(columns: cols)
  doc
}
