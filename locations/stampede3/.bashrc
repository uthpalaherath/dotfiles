# -*- shell-script -*-
# TACC startup script: ~/.bashrc version 2.1 -- 12/17/2013


# This file is NOT automatically sourced for login shells.
# Your ~/.profile can and should "source" this file.

# Note neither ~/.profile nor ~/.bashrc are sourced automatically by
# bash scripts. However, a script inherits the environment variables
# from its parent shell.  Both of these facts are standard bash
# behavior.
#
# In a parallel mpi job, this file (~/.bashrc) is sourced on every
# node so it is important that actions here not tax the file system.
# Each nodes' environment during an MPI job has ENVIRONMENT set to
# "BATCH" and the prompt variable PS1 empty.

#################################################################
# Optional Startup Script tracking. Normally DBG_ECHO does nothing
if [ -n "$SHELL_STARTUP_DEBUG" ]; then
  DBG_ECHO "${DBG_INDENT}~/.bashrc{"
fi

############
# SECTION 1
#
# There are three independent and safe ways to modify the standard
# module setup. Below are three ways from the simplest to hardest.
#   a) Use "module save"  (see "module help" for details).
#   b) Place module commands in ~/.modules
#   c) Place module commands in this file inside the if block below.
#
# Note that you should only do one of the above.  You do not want
# to override the inherited module environment by having module
# commands outside of the if block in section 2

# Also please set or modify any environment variables inside the if block
# below.  For example, modifying PATH or other path like variables
# (e.g LD_LIBRARY_PATH), the guard variable prevents your PATH from having
# duplicate directories on sub-shells.

if [ -z "$__BASHRC_SOURCED__" -a "$ENVIRONMENT" != BATCH ]; then
  export __BASHRC_SOURCED__=1

  ##################################################################
  # **** PLACE MODULE COMMANDS HERE and ONLY HERE.              ****
  ##################################################################

  # module load git

  ###################################################################
  # **** PLACE Environment Variables including PATH here.        ****
  ###################################################################

  # export PATH=$HOME/bin:$PATH

fi

########################
# SECTION 2
#
# Controling the prompt: Suppose you want stampede1(14)$  instead of
# login1.stampede(14)$
#
#if [ -n "$PS1" ]; then
#   myhost=$(hostname -f)              # get the full hostname
#   myhost=${myhost%.tacc.utexas.edu}  # remove .tacc.utexas.edu
#   first=${myhost%%.*}                # get the 1st name (e.g. login1)
#   SYSHOST=${myhost#*.}               # get the 2nd name (e.g. stampede)
#   first5=$(expr substr $first 1 5)   # get first 5 character from $first
#   if [ "$first5" = "login" ]; then
#     num=$(expr $first : '[^0-9]*\([0-9]*\)') # get the number
#     HOST=${SYSHOST}$num                      # HOST -> stampede1
#   else
#     # first is not login1 so take first letter of system name
#     L=$(expr substr $SYSHOST 1 1 | tr '[:lower:]' '[:upper:]')
#
#     #  If host is c521-101.stampeded then
#     HOST=$L$first      # HOST  -> Sc521-101
#   fi
#   PS1='$HOST(\#)\$ '   # Prompt either stampede1(14)$ or Sc521-101(14)$
#fi
#####################################################################
# **** Place any else below.                                     ****
#####################################################################

# alias m="more"
# alias bls='/bin/ls'   # handy alias for listing a large directory.

##########
# Umask
#
# If you are in a group that wishes to share files you can use
# "umask". to make your files be group readable.  Placing umask here
# is the only reliable place for bash and will insure that it is set
# in all types of bash shells.

# umask 022

###################################
# Optional Startup Script tracking

if [ -n "$SHELL_STARTUP_DEBUG" ]; then
  DBG_ECHO "${DBG_INDENT}}"
fi

## All commands below this block will NOT be executed on the compute nodes
## that are NOT running the slurm job script in a batch job
myhost=`hostname -s`
if [[ $myhost =~ c[0-9][0-9][0-9]-[0-9][0-9][0-9]  &&  -z $SLURMD_NODENAME ]] ; then
  return
fi

#------------------------------------------- INITIALIZATION -------------------------------------------


# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
	for rc in ~/.bashrc.d/*; do
		if [ -f "$rc" ]; then
			. "$rc"
		fi
	done
fi
unset rc

# Source for colorful terminal
if [[ $- == *i* ]] && [ -f ~/.bash_prompt ]; then
    source ~/.bash_prompt
fi

# Memory
ulimit -s unlimited

# Reverse search history
if [[ $- == *i* ]]; then
    export HISTIGNORE="pwd:ls:cd"
    shopt -s histappend
    HISTCONTROL=ignoreboth:erasedups
    export PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

# Bat theme
export BAT_THEME="TwoDark"

# OpenMP and MKL
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE

# PYTHON
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home1/05979/uthpala/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home1/05979/uthpala/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/home1/05979/uthpala/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/home1/05979/uthpala/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/home1/05979/uthpala/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/home1/05979/uthpala/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<

#FZF
if [[ $- == *i* ]]; then
    [ -f ~/.fzf.bash ] && source ~/.fzf.bash
    export FZF_DEFAULT_COMMAND='rg --files --type-not sql --smart-case --follow --hidden -g "!{node_modules,.git}" '
    export FZF_DEFAULT_OPTS="--preview 'bat --color=always --style=numbers {} 2>/dev/null || cat {} 2>/dev/null || tree -C {}'"
    export FZF_CTRL_R_OPTS="
     --preview 'echo {}' --preview-window 'hidden'
     --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
     --color header:italic
     --header 'Press CTRL-Y to copy command into clipboard'"
    export FZF_ALT_C_OPTS="
     --walker-skip .git,node_modules,target
     --preview 'tree -C {}'"
fi
export EDITOR="vim"

# Nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Cargo
. "$HOME/.cargo/env"

#------------------------------------------- ALIASES -------------------------------------------

alias q='squeue -u $USER --format="%.18i %.9P %35j %.8u %.2t %.10M %.6D %R"'
#alias sac="sacct --format="JobID,JobName%-30,State,User""
#alias sac="sacct -S $(date +%Y-%m-01) -E now -X --format="JobID,JobName%-30,State,WorkDir%-150""
alias sac="sacct -X --format="JobID,JobName%-30,State,nodelist%-30,WorkDir%-150""
alias makejob="cp ~/dotfiles/locations/stampede3/jobscript.sh ."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"
alias f='vim "$(fzf)"'
alias globus="globusconnectpersonal -start -restrict-paths $HOME,$WORK &"

#------------------------------------------- FUNCTIONS -------------------------------------------

# extract, mkcdr and archive creattion were taken from
# https://gist.github.com/JakubTesarek/8840983
# Easy extract
extract () {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xvjf $1    ;;
            *.tar.gz)    tar xvzf $1    ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       rar x $1       ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xvf $1     ;;
            *.tbz2)      tar xvjf $1    ;;
            *.tgz)       tar xvzf $1    ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "don't know how to extract '$1'..." ;;
        esac
    else
        echo "'$1' is not a valid file!"
    fi
}

# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

# yazi cd to directory and return default cursor
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp" || true
    echo -e -n "\x1b[6 q"
    [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
    rm -f -- "$tmp"
}

#------------------------------------------- PATHS -------------------------------------------

export PATH="$HOME/dotfiles/:$PATH"

#------------------------------------------- TMUX -------------------------------------------

export TMUX_DEVICE_NAME=stampede3
if [[ $- == *i* && -t 0 && -z $TMUX && $(hostname -s) == login* ]]; then
    tmux new -A -s $TMUX_DEVICE_NAME
fi
