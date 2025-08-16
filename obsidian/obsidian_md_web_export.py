#!/usr/bin/env python

""" Markdown file converter for Jekyll web pages

This script reformats markdown files to prepare them to
be hosted in my website.

Execute in directory with markdown files to be converted.

This version works with the "attachment-*" directory structure.

Author: Uthpala Herath

"""

import fileinput
from pathlib import Path
import os
import re
import shutil
import sys


def _extract_note_name(md_filename: str) -> str:
    """
    From 'My Note-20250816123456789.md' → 'My Note'.
    Falls back to stem if no trailing 17-digit timestamp is present.
    """
    base = os.path.basename(md_filename)
    m = re.match(r"^(?P<name>.+)-(?P<ts>\d{17})(?:\.[^.]+)?$", base)
    if m:
        return m.group("name")
    # Fallback: no timestamp pattern; just use stem
    return Path(base).stem


def make_web(args):
    """Renames image paths and copies files to destination."""

    # Set the root directory of the website
    webroot = "/Users/uthpala/Dropbox/git/uthpalaherath.github.io"

    # Set directory names (relative to webroot)
    posts = "_posts"
    images = "assets/media"  # published images root

    # --- Inputs ---
    # args[1] = directory of the source markdown
    # args[2] = markdown filename
    abs_file_path = os.path.abspath(os.path.join(args[1], args[2]))
    src_dir_of_md = os.path.dirname(abs_file_path)
    md_basename = os.path.basename(args[2])
    note_name = _extract_note_name(md_basename)

    # --- Destinations ---
    file_dest_dir = os.path.join(webroot, posts)
    os.makedirs(file_dest_dir, exist_ok=True)

    # Place images at /assets/media/<note_name>/...
    img_dest_dir = os.path.join(webroot, images, note_name)
    os.makedirs(os.path.join(webroot, images), exist_ok=True)

    file_dest_path = os.path.join(file_dest_dir, md_basename)

    # Copy Markdown file to destination
    shutil.copyfile(abs_file_path, file_dest_path)

    # --- Rewrite image links in the copied Markdown ---
    # Transform "(attachments-<note_name>" -> "(/assets/media/<note_name>"
    # Also handles optional leading "./" and preserves the rest of the path.
    web_image_prefix = "(" + os.sep + images + os.sep  # '(/assets/media/'
    pattern = re.compile(r"\((?:\./)?attachments-([^/)]+)")

    # The group \1 = <note_name> (can include spaces)
    # Result becomes '(/assets/media/<note_name>'
    def _repl(m):
        return web_image_prefix + m.group(1)

    with fileinput.FileInput(file_dest_path, inplace=True) as f:
        for line in f:
            print(pattern.sub(_repl, line), end="")

    # --- Copy attachment directory ---
    # From './attachments-<note_name>/' (next to the md) to '/assets/media/<note_name>/'
    src_attachments_dir = os.path.join(src_dir_of_md, f"attachments-{note_name}")
    if os.path.isdir(src_attachments_dir):
        shutil.copytree(src_attachments_dir, img_dest_dir, dirs_exist_ok=True)
    else:
        # Don’t crash if a note has no attachments
        print(
            f"[warn] attachments directory not found: {src_attachments_dir}",
            file=sys.stderr,
        )


if __name__ == "__main__":
    make_web(sys.argv)
