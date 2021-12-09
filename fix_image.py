#!/usr/bin/env python

""" Markdown file converter for Jekyll web pages

This script reformats markdown files to prepare them to
be hosted in my website.

Author: Uthpala Herath

"""

import argparse
import fileinput
import os


def make_web(args):
    """Fixes image path names."""

    file_dest_dir = args.dest + "_posts/"
    file_name = file_dest_dir + args.infile

    # renaming the image directory path from images to /images
    if not args.undo:
        with fileinput.FileInput(
            file_name,
            inplace=True,
        ) as file:
            for line in file:
                print(line.replace("images/", "/images/"), end="")
        file.close()

    if args.undo:
        with fileinput.FileInput(
            file_name,
            inplace=True,
        ) as file:
            for line in file:
                print(line.replace("/images/", "images/"), end="")
        file.close()


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
    parser.add_argument(
        "-undo", help="Undo formatting image name for web hosting.", action="store_true"
    )
    args = parser.parse_args()
    make_web(args)
