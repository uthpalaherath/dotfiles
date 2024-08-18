#!/usr/bin/env python

""" Markdown file converter for Jekyll web pages

This script reformats markdown files to prepare them to
be hosted in my website.

Execute in directory with markdown files to be converted.

Author: Uthpala Herath

"""

import argparse
import fileinput
from pathlib import Path
import os
import shutil


def make_web(args):
    """Renames image paths and copies files to destination."""

    file_dest_dir = args.dest + "_posts/"
    img_dest_dir = args.dest + "/images/" + Path(args.infile).stem
    file_name = file_dest_dir + args.infile
    source_str = "attachments/"
    target_str = "/images/"

    # Copy file to destination
    shutil.copyfile(args.infile, file_name)

    # renaming the image directory path from images to /images
    with fileinput.FileInput(
        file_name,
        inplace=True,
    ) as file:
        for line in file:
            print(line.replace(source_str, target_str), end="")
    file.close()

    # Copy image directory to destination
    src_dir = source_str + Path(args.infile).stem
    shutil.copytree(src_dir, img_dest_dir)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="This script reformats markdown files for web hosting."
    )
    parser.add_argument("infile", type=str, default=None, help="Input markdown file.")
    parser.add_argument(
        "-dest",
        type=str,
        default="/Users/uthpala/Dropbox/git/uthpalaherath.github.io/",
        help="root directory of website",
    )
    args = parser.parse_args()
    make_web(args)
