// Minimal Template — Saubere Dokumente ohne Titelseite
// Fonts: Charter (Body), Menlo (Code)

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
  let text-color = rgb("#222222")
  let accent-color = rgb("#4a6fa5")
  let body-font = if font != none { font } else { ("Charter",) }
  let mono-font = if codefont != none { codefont } else { ("Menlo",) }

  set page(
    paper: paper,
    margin: margin,
    numbering: pagenumbering,
    footer: context {
      set text(size: 8pt, fill: rgb("#aaa"), font: body-font)
      align(center, counter(page).display("— 1 —"))
    },
  )

  set text(
    font: body-font,
    size: fontsize,
    fill: text-color,
    lang: lang,
    region: region,
  )

  set par(justify: true, leading: linestretch * 0.65em)

  // Headings
  show heading.where(level: 1): it => {
    v(1em)
    block(below: 0.6em)[
      #set text(size: 1.4em, weight: "bold", fill: text-color)
      #it.body
    ]
  }

  show heading.where(level: 2): it => {
    v(0.7em)
    block(below: 0.4em)[
      #set text(size: 1.15em, weight: "bold", fill: rgb("#444"))
      #it.body
    ]
  }

  show heading.where(level: 3): it => {
    v(0.5em)
    block(below: 0.3em)[
      #set text(size: 1.05em, weight: "medium", fill: rgb("#555"))
      #it.body
    ]
  }

  if sectionnumbering != none {
    set heading(numbering: sectionnumbering)
  }

  // Links
  show link: it => {
    set text(fill: accent-color)
    underline(offset: 2pt, stroke: 0.5pt + accent-color, it)
  }

  // Code blocks
  show raw.where(block: true): it => {
    block(
      width: 100%,
      fill: rgb("#f7f7f7"),
      inset: (x: 12pt, y: 10pt),
      radius: 3pt,
      stroke: 0.4pt + rgb("#e5e5e5"),
    )[
      #set text(font: mono-font, size: 0.88em)
      #set par(leading: 0.55em)
      #it
    ]
  }

  show raw.where(block: false): it => {
    box(
      fill: rgb("#f0f0f0"),
      inset: (x: 3pt, y: 1.5pt),
      radius: 2pt,
    )[#set text(font: mono-font, size: 0.88em); #it]
  }

  // Tables
  set table(
    inset: 8pt,
    stroke: (x: none, y: 0.4pt + rgb("#ddd")),
  )
  show table.cell.where(y: 0): set text(weight: "bold")

  // Blockquotes
  show quote: it => {
    block(
      width: 100%,
      inset: (left: 14pt, y: 6pt),
      stroke: (left: 2.5pt + rgb("#ddd")),
    )[
      #set text(style: "italic", fill: rgb("#555"))
      #it.body
    ]
  }

  // --- Inline Title (kein Pagebreak) ---
  if title != none {
    block(below: 0.3em)[
      #set text(size: 1.8em, weight: "bold", fill: text-color)
      #title
    ]
    if subtitle != none {
      block(below: 0.3em)[
        #set text(size: 1.1em, fill: rgb("#666"))
        #subtitle
      ]
    }
    if authors.len() > 0 or date != none {
      v(0.2em)
      set text(size: 0.9em, fill: rgb("#888"))
      let parts = ()
      for author in authors {
        if type(author) == dictionary { parts.push(author.at("name", default: "")) } else { parts.push(if type(author) == str { author } else { [#author] }) }
      }
      if date != none { parts.push(if type(date) == str { date } else { [#date] }) }
      parts.join(" · ")
    }
    v(0.4em)
    line(length: 100%, stroke: 0.5pt + rgb("#ddd"))
    v(0.6em)
  }

  // --- Body ---
  set page(columns: cols)
  doc
}
