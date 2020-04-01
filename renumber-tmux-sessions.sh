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

sessions=$(tmux ls | cut -f1 -d':' | cut -f2 -d ' ' | sort -n)
new=1
for old in $sessions
do
  tmux rename -t $old "${TMUX_DEVICE_NAME} ${new}"
  tmux rename -t "${TMUX_DEVICE_NAME} ${old}" "${TMUX_DEVICE_NAME} ${new}"
  ((new++))
done

#kill detached sessions
#tmux list-sessions | grep -v attached | cut -d: -f1 |  xargs -t -n1 tmux kill-session -t


