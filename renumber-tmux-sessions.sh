#!/usr/bin/env bash
#
# This script automatically renames and renumbers tmux sessions.
# Set $TMUX_DEVICE_NAME in your .bashrc.
# Then add the following lines to your .tmux.conf.
#
# set-hook -g session-created "run <path>/renumber-tmux-sessions.sh"
# set-hook -g session-closed  "run <path>/renumber-tmux-sessions.sh"
#
# - Uthpala Herath

#kill detached sessions
tmux list-sessions | grep -E -v '\(attached\)$' | while IFS='\n' read line; do
    tmux kill-session -t "${line%%:*}"
done

 # renumbering sessions
new=0
sessions=$(tmux ls | cut -f1 -d':' | cut -f2 -d ' ' | sort -n)
for old in $sessions
do
    tmux rename -t $old "${TMUX_DEVICE_NAME}-${new}"
    ((new++))
done
