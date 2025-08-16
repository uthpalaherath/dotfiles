#!/usr/bin/env python

""" Markdown file converter for Jekyll web pages

This script reformats markdown files to prepare them to
be hosted in my website.

Execute in directory with markdown files to be converted.

Author: Uthpala Herath

"""

import fileinput
from pathlib import Path
import os
import shutil
import sys


def make_web(args):
    """Renames image paths and copies files to destination."""

    # Set the root directory of the website
    webroot = "/Users/uthpala/Dropbox/git/uthpalaherath.github.io"

    # Set directory names (relative to webroot)
    posts = "_posts"
    images = "assets/media"

    # Source of the image directory (relative to Markdown file)
    source_str = "attachments"

    abs_file_path = os.path.abspath(os.path.join(args[1], args[2]))
    file_dest_dir = os.path.join(webroot, posts)
    img_dest_dir = os.path.join(webroot, images, Path(os.path.basename(args[2])).stem)
    file_name = os.path.join(file_dest_dir, os.path.basename(args[2]))

    # Copy Markdown file to destination
    shutil.copyfile(abs_file_path, file_name)

    # renaming the image directory path
    web_source_str = "(" + source_str
    web_image_str = "(" + os.sep + images
    with fileinput.FileInput(
        file_name,
        inplace=True,
    ) as file:
        for line in file:
            print(line.replace(web_source_str, web_image_str), end="")
    file.close()

    # Copy image directory to destination
    src_dir = os.path.join(
        os.path.dirname(abs_file_path), source_str, Path(os.path.basename(args[2])).stem
    )
    shutil.copytree(src_dir, img_dest_dir, dirs_exist_ok=True)

    return


if __name__ == "__main__":
    make_web(sys.argv)
