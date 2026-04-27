// Letter Template — Geschaeftsbriefe und formelle Korrespondenz
// Fonts: Helvetica Neue (Body), Menlo (Code)

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
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.5cm, right: 2cm),
  paper: "a4",
  lang: "de",
  region: "DE",
  font: none,
  fontsize: 11pt,
  mathfont: none,
  codefont: none,
  linestretch: 1.4,
  sectionnumbering: none,
  linkcolor: none,
  citecolor: none,
  filecolor: none,
  pagenumbering: "1",
  doc,
) = {
  let text-color = rgb("#1a1a1a")
  let accent-color = rgb("#444444")
  let body-font = if font != none { font } else { ("Helvetica Neue",) }
  let mono-font = if codefont != none { codefont } else { ("Menlo",) }

  set page(
    paper: paper,
    margin: margin,
    numbering: none,
    footer: context {
      if counter(page).get().first() > 1 {
        set text(size: 8pt, fill: rgb("#999"))
        align(center, counter(page).display("1 / 1", both: true))
      }
    },
  )

  set text(
    font: body-font,
    size: fontsize,
    fill: text-color,
    lang: lang,
    region: region,
  )

  set par(justify: false, leading: linestretch * 0.65em)

  // Headings (selten in Briefen, aber fuer Struktur)
  show heading.where(level: 1): it => {
    v(0.5em)
    block(below: 0.5em)[
      #set text(size: 1.15em, weight: "bold")
      #it.body
    ]
  }

  show heading.where(level: 2): it => {
    v(0.4em)
    block(below: 0.3em)[
      #set text(size: 1.05em, weight: "semibold")
      #it.body
    ]
  }

  // Links
  show link: it => {
    set text(fill: rgb("#2d5f9a"))
    underline(offset: 2pt, stroke: 0.5pt + rgb("#2d5f9a"), it)
  }

  // Code
  show raw.where(block: true): it => {
    block(
      width: 100%,
      fill: rgb("#f8f8f8"),
      inset: (x: 12pt, y: 8pt),
      radius: 3pt,
    )[
      #set text(font: mono-font, size: 0.88em)
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
  set table(inset: 7pt, stroke: 0.4pt + rgb("#ddd"))

  // --- Letter Header ---

  // Absender
  if authors.len() > 0 {
    set text(size: 9.5pt, fill: accent-color)
    for author in authors {
      if type(author) == dictionary {
        if author.at("name", default: "") != "" { [#author.name] }
        if author.at("affiliation", default: "") != "" { [ · #author.affiliation] }
        if author.at("email", default: "") != "" { [ · #author.email] }
      } else {
        [#author]
      }
    }
    v(0.3cm)
    line(length: 100%, stroke: 0.4pt + rgb("#ddd"))
    v(0.5cm)
  }

  // Empfaenger (via title)
  if title != none {
    block(below: 0.6cm)[
      #set text(size: fontsize)
      #title
    ]
  }

  // Datum
  if date != none {
    v(0.3cm)
    align(right)[
      #set text(size: fontsize, fill: accent-color)
      #date
    ]
    v(0.5cm)
  }

  // Betreff (via subtitle)
  if subtitle != none {
    v(0.3cm)
    block(below: 0.8cm)[
      #set text(weight: "bold", size: fontsize)
      #subtitle
    ]
  }

  // --- Body ---
  doc
}
