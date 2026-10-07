#!/bin/sh
# Popup monitor for tmux (prefix T): btop, or htop where btop can't run
# Runs it where the current pane is working:
#   pane's foreground program is ssh      -> new ssh with the same options and destination
#   pane started an srun/salloc job here  -> overlapping step on the job's first node
#   otherwise                             -> this host

top='btop --version >/dev/null 2>&1 && exec btop || exec htop'

# ssh as the pane's foreground process-group leader (skips ssh spawned by git, ProxyJump, etc.)
tty=$(tmux display -p '#{pane_tty}')
ssh_args=$(ps -t "${tty#/dev/}" -o pid=,pgid=,tpgid=,args= 2>/dev/null |
  awk '$1 == $2 && $2 == $3 && $4 ~ /(^|\/)ssh$/ { $1 = $2 = $3 = $4 = ""; print; exit }')

if [ -n "$ssh_args" ]; then
  set -- $ssh_args
  opts=
  dest=
  while [ $# -gt 0 ]; do
    case $1 in
      -[BbcDEeFIiJLlmOoPpQRSWw]) opts="$opts $1 $2"; shift 2 ;;   # options that take a value
      -*) opts="$opts $1"; shift ;;
      *) dest=$1; break ;;                                          # anything after is the remote command
    esac
  done
  if [ -n "$dest" ]; then
    # interactive remote shell so PATH additions from .bashrc/.zshrc are loaded
    exec ssh -t $opts "$dest" "exec \"\$SHELL\" -ic '$top'"
  fi
fi

# srun/salloc started from this pane: Slurm records AllocNode:Sid, and a tmux pane's shell is its session leader
if command -v squeue >/dev/null 2>&1; then
  pp=$(tmux display -p '#{pane_pid}')
  h=$(hostname -s)
  job=$(squeue --me -h -t R -O JobID:20,AllocNodes:100,AllocSID:20 |
    while read -r j n s; do [ "$n" = "$h" ] && [ "$s" = "$pp" ] && { echo "$j"; break; }; done)
  if [ -n "$job" ]; then
    exec srun --jobid="$job" --overlap -N1 -n1 --pty sh -c "$top"
  fi
fi

exec sh -c "$top"
