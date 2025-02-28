#!/usr/bin/env python

""" Pandoc markdown to PDF converter.

This script converts markdown files to PDF files using Pandoc.
For use within Obsidian.

Execute in directory with markdown files to be converted.

Author: Uthpala Herath

"""

from pathlib import Path
import os
import shutil
import sys
import subprocess
import glob


def run_pdflatex(dirname, filename):
    """Run pdflatex."""

    os.chdir(dirname)
    try:
        command = ["xelatex", filename + ".tex"]
        subprocess.run(command, check=True, shell=False)
        print("Pdflatex complete.")

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while converting: {e}")


def run_bibtex(dirname, filename):
    """Run bibtex."""
    try:

        os.chdir(dirname)
        command = ["bibtex", filename + ".aux"]
        subprocess.run(command, check=True)
        print("Bibtex complete.")

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while converting: {e}")


def make_pdf(args):
    """Convert markdown to PDF."""

    infile = os.path.abspath(os.path.join(args[1], args[2]))
    dirname = os.path.dirname(infile)
    filename_noext = Path(os.path.basename(infile)).stem

    bibfile = "/Users/uthpala/Dropbox/references-zotero.bib, references.bib"
    template = "/Users/uthpala/Dropbox/git/dotfiles/latex/custom.latex"

    # Constructing the pandoc command with filters and options
    try:
        os.chdir(dirname)

        command = [
            "pandoc",
            "--number-sections",
            "--filter=/Users/uthpala/miniconda3/envs/py3/bin/pandoc-xnos",
            "--filter=pandoc-crossref",
            "-M cref=true",
            "-M xnos-cleveref=true",
            "-M xnos-capitalise=true",
            "-M codeBlockCaptions=true",
            "--listings",
            "--natbib",
            "--bibliography=" + bibfile,
            "--template=" + template,
            "-V colorlinks=true",
            "-V linkcolor=blue",
            "-V urlcolor=magenta",
            "-V toccolor=gray",
            "-s",
            filename_noext + ".md",
            "-o",
            filename_noext + ".tex",
        ]
        subprocess.run(command, check=True)
        print("Pandoc complete.")

    except subprocess.CalledProcessError as e:
        print(f"An error occurred while converting: {e}")

    # First run of pdflatex
    run_pdflatex(dirname, filename_noext)

    # bibtex run
    run_bibtex(dirname, filename_noext)

    # Second run of pdflatex
    run_pdflatex(dirname, filename_noext)

    # Third run of pdflatex
    run_pdflatex(dirname, filename_noext)

    # cleanup
    cleanlist = ["*.tex", "*.aux", "*.bbl", "*.blg", "*.log", "*.out", "*.bib"]
    if os.path.exists("references.bib"):
        shutil.move("references.bib", "references.tmp")
    for cl in cleanlist:
        for f in glob.glob(cl):
            os.remove(f)
    if os.path.exists("references.tmp"):
        shutil.move("references.tmp", "references.bib")

    return


if __name__ == "__main__":
    make_pdf(sys.argv)
