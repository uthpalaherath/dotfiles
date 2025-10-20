#!/usr/bin/env python

""" Pandoc markdown to PDF converter.

This script converts markdown files to PDF files using Pandoc.
For use within Obsidian. Execute in directory with markdown files to be converted.

Lua filters borrowed from https://github.com/zcysxy/obsidian-pandoc-filters.

Author: Uthpala Herath
"""

from pathlib import Path
import os
import shutil
import sys
import subprocess
import re

# =========================
# ---- USER SETTINGS ------
# =========================

# Location of Lua filters
OBSIDIAN_FILTERS_ROOT = Path("/Users/ukh/Library/CloudStorage/Dropbox/git/dotfiles/obsidian/filters")

# LaTeX template (preamble included)
LATEX_TEMPLATE = Path("/Users/ukh/Library/CloudStorage/Dropbox/git/dotfiles/latex/custom.latex")

# Primary Zotero bibliography
MAIN_BIB = Path("/Users/ukh/Library/CloudStorage/Dropbox/references-zotero.bib")

# If True: use citeproc (no bibtex). If False: use natbib + bibtex multi-pass.
USE_CITEPROC = False

# Optional: if mermaid-filter is available
ENABLE_MERMAID = False
MERMAID_FILTER = "mermaid-filter"

# PDF engine for manual LaTeX runs
PDF_ENGINE = "xelatex"

# =========================
# ---- INTERNALS ----------
# =========================


def run(cmd, cwd=None):
    """Run a subprocess command."""
    subprocess.run(cmd, check=True, cwd=cwd)


def run_pdflatex(workdir: Path, basename: str):
    """Run LaTeX engine."""
    run([PDF_ENGINE, f"{basename}.tex"], cwd=workdir)
    print(f"{PDF_ENGINE} complete.")


def run_bibtex(workdir: Path, basename: str):
    """Run bibtex."""
    run(["bibtex", f"{basename}.aux"], cwd=workdir)
    print("bibtex complete.")


def make_pdf(argv):
    if len(argv) < 3:
        print("Usage: make_pdf.py <note_dir> <note_filename.md>")
        sys.exit(1)

    in_dir = Path(argv[1]).resolve()
    in_md = Path(argv[2])
    infile = (in_dir / in_md).resolve()

    if not infile.exists():
        print(f"[ERROR] Markdown file not found: {infile}")
        sys.exit(1)

    workdir = infile.parent

    raw_basename = infile.stem

    # replace whitespace with underscore, drop any other non-word / non - characters
    basename = re.sub(r"[^\w\-]", "_", raw_basename).strip("_")
    if not basename:
        basename = "pandoc_output"

    # Lua filters
    lua_filters_ordered = [
        "image.lua",
        "image_path.lua",
        "codeblock.lua",
        "math.lua",
        "callout.lua",
        "link.lua",
        "div.lua",
        "preamble.lua",
        "highlight.lua",
    ]

    # pandoc command
    pandoc_cmd = [
        "pandoc",
        "--standalone",
        "--number-sections",
        "-f",
        "markdown+tex_math_single_backslash+wikilinks_title_after_pipe+mark+autolink_bare_uris+pipe_tables",
        "--syntax-highlighting=idiomatic",
        "-s",
        str(infile),
        "-o",
        f"{basename}.tex",
        "--template",
        str(LATEX_TEMPLATE),
        "-V",
        "colorlinks=true",
        "-V",
        "linkcolor=blue",
        "-V",
        "urlcolor=magenta",
        "-V",
        "toccolor=gray",
    ]

    # ---- Collect bibliography files ----
    # Always include MAIN_BIB, plus any *.bib in the working directory.
    bib_files = [str(MAIN_BIB)]

    local_bibs = sorted(p for p in workdir.glob("*.bib") if p.is_file())

    main_bib_resolved = MAIN_BIB.resolve()
    for bf in local_bibs:
        try:
            if bf.resolve() != main_bib_resolved:
                # Use a clean relative path (or just filename) for local bibs
                bib_files.append(bf.name)  # equivalent to os.path.relpath(bf, workdir)
        except FileNotFoundError:
            # Skip broken symlinks gracefully
            continue

    # Add bibliographies to pandoc command
    for bf in bib_files:
        pandoc_cmd.extend(["--bibliography", bf])

    # Add Lua filters
    for lf in lua_filters_ordered:
        pandoc_cmd.extend(["--lua-filter", str(OBSIDIAN_FILTERS_ROOT / lf)])

    # mermaid (optional)
    if ENABLE_MERMAID:
        pandoc_cmd.extend(["--lua-filter", MERMAID_FILTER])

    # Crossref comes AFTER lua filters
    pandoc_cmd.extend(
        [
            "--filter",
            "pandoc-crossref",
            "-M",
            "cref=true",
            "-M",
            "codeBlockCaptions=true",
            "-M",
            "linkReferences=true",
            "-M",
            "autoSectionLabels=true",
        ]
    )

    # Citations
    if USE_CITEPROC:
        pandoc_cmd.append("--citeproc")
    else:
        pandoc_cmd.append("--natbib")

    # --- Run pandoc to produce .tex ---
    try:
        print("Running pandoc…")
        run(pandoc_cmd, cwd=workdir)
        print("Pandoc complete.")
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] Pandoc failed: {e}")
        sys.exit(1)

    # --- Build PDF via LaTeX passes ---
    try:
        if USE_CITEPROC:
            # citeproc embeds bibliography; no bibtex needed
            run_pdflatex(workdir, basename)
            run_pdflatex(workdir, basename)
        else:
            # natbib flow with bibtex
            run_pdflatex(workdir, basename)
            run_bibtex(workdir, basename)
            run_pdflatex(workdir, basename)
            run_pdflatex(workdir, basename)
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] LaTeX toolchain failed: {e}")
        sys.exit(1)

    # --- Cleanup ---
    try:
        # Remove system generated .bib (basename.bib)
        for bib in workdir.glob("*.bib"):
            try:
                txt = bib.read_text(errors="ignore")
                lines = [ln.strip() for ln in txt.splitlines() if ln.strip()]
                if lines and all(ln.startswith("@CONTROL") for ln in lines):
                    bib.unlink()
                    print(f"Removed transient control bib: {bib.name}")
            except Exception:
                pass

        # Remove typical LaTeX/Pandoc build artifacts
        for pattern in [
            "*.aux",
            "*.bbl",
            "*.blg",
            "*.log",
            "*.out",
            "*.bcf",
            "*.run.xml",
            "*.toc",
            "*.lot",
            "*.lof",
            "*.tex",
        ]:
            for f in workdir.glob(pattern):
                try:
                    f.unlink()
                except Exception:
                    pass

    except Exception as e:
        print(f"[WARN] Cleanup encountered an issue: {e}")

    print("Done.")


if __name__ == "__main__":
    make_pdf(sys.argv)
