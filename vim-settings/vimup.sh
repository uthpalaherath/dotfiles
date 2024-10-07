#!/bin/bash
# This script updates my vim configuration.

# Update from upstream
cd ~/.vim_runtime
git reset --hard
git clean -d --force
git pull --rebase

# Update built-in plugins
printf "Updating built-in plugins...\n"
python update_plugins.py

# External plugins
vim +PlugUpdate +qall
