#!/usr/bin/env python3
"""Markdown -> PDF via pandoc + typst.

Generischer Build-Helper. Erwartet, dass der Aufrufer den Template-Pfad
selbst mitbringt — der pandoc-Skill liefert keine eigenen Templates.

Pipeline:
  1. fix_markdown.py (Listen-Spacing, optional IEEE-Zitations-Linkung)
  2. pandoc --pdf-engine=typst mit -V template=<abs-path> + --root=/

Usage:
  build_pdf.py --input report.md --output report.pdf \\
    --template /abs/path/to/template.typ

  # ohne Template: pandoc-Default
  build_pdf.py --input report.md --output report.pdf

  # zusaetzliche pandoc-Variablen
  build_pdf.py --input r.md --output r.pdf \\
    --template tpl.typ -V mainfont="Helvetica Neue" -V toc=true
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
FIX_MARKDOWN = SCRIPT_DIR / "fix_markdown.py"
NOWIDTHS_LUA = SCRIPT_DIR / "nowidths.lua"
PANDOC_TYPST_TEMPLATE = SCRIPT_DIR / "pandoc-typst.template"


def require(binary: str) -> None:
    if shutil.which(binary) is None:
        sys.exit(f"FEHLT: {binary} nicht im PATH. install.yaml im pandoc-Skill konsultieren.")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--input", required=True, help="Markdown-Eingabedatei")
    parser.add_argument("--output", required=True, help="PDF-Ausgabedatei")
    parser.add_argument("--template", help="Absoluter Pfad zum Typst-Template (.typ). Optional.")
    parser.add_argument("-V", "--var", action="append", default=[],
                        help="Pandoc-Variable, mehrfach: -V key=value")
    parser.add_argument("--skip-fix", action="store_true",
                        help="fix_markdown.py-Vorverarbeitung ueberspringen")
    parser.add_argument("--keep-table-widths", action="store_true",
                        help="Pandoc-Spaltenbreiten in Tabellen NICHT entfernen "
                             "(Default: nowidths.lua-Filter aktiv, damit typst "
                             "die Spaltenbreiten selbst bestimmt)")
    args = parser.parse_args()

    require("pandoc")
    require("typst")

    input_path = Path(args.input).resolve()
    output_path = Path(args.output).resolve()
    if not input_path.is_file():
        sys.exit(f"Input nicht gefunden: {input_path}")
    output_path.parent.mkdir(parents=True, exist_ok=True)

    if args.template:
        template_path = Path(args.template).resolve()
        if not template_path.is_file():
            sys.exit(f"Template nicht gefunden: {template_path}")
    else:
        template_path = None

    with tempfile.TemporaryDirectory() as tmp:
        tmp_dir = Path(tmp)
        if args.skip_fix:
            fixed = input_path
        else:
            fixed = tmp_dir / "input_fixed.md"
            subprocess.run(
                [sys.executable, str(FIX_MARKDOWN), str(input_path), str(fixed)],
                check=True,
            )

        cmd: list[str] = [
            "pandoc", str(fixed),
            "-f", "markdown+autolink_bare_uris",
            "--pdf-engine=typst",
            "--pdf-engine-opt=--root=/",
            "--template", str(PANDOC_TYPST_TEMPLATE),
            "-o", str(output_path),
        ]
        if not args.keep_table_widths:
            cmd += ["--lua-filter", str(NOWIDTHS_LUA)]
        if template_path is not None:
            cmd += ["-V", f"template={template_path}"]
        for v in args.var:
            cmd += ["-V", v]

        subprocess.run(cmd, check=True)

    print(f"PDF erzeugt: {output_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
