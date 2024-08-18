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
import sys


def make_web(args):
    """Renames image paths and copies files to destination."""

    webroot = "/Users/uthpala/Dropbox/git/uthpalaherath.github.io/"

    abs_file_path = os.path.abspath(os.path.join(args[1], args[2]))

    file_dest_dir = webroot + "_posts/"
    img_dest_dir = webroot + "/images/" + Path(os.path.basename(args[2])).stem
    file_name = file_dest_dir + os.path.basename(args[2])
    source_str = "attachments/"
    target_str = "/images/"

    # Copy file to destination
    shutil.copyfile(abs_file_path, file_name)

    # renaming the image directory path from images to /images
    with fileinput.FileInput(
        file_name,
        inplace=True,
    ) as file:
        for line in file:
            print(line.replace(source_str, target_str), end="")
    file.close()

    # Copy image directory to destination
    src_dir = (
        os.path.dirname(abs_file_path)
        + "/attachments/"
        + Path(os.path.basename(args[2])).stem
    )
    print(src_dir)
    shutil.copytree(src_dir, img_dest_dir, dirs_exist_ok=True)


if __name__ == "__main__":
    make_web(sys.argv)
