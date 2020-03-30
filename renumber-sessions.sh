#!/usr/bin/env bash

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


