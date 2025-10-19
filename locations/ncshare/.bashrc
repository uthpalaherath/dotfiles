# .bashrc for ncshare (login.ncshare.org)
# -Uthpala Herath

# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
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

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

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
source ~/.bash_prompt

# tmux
export TMUX_DEVICE_NAME=ncshare
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
    tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
fi

# Memory
ulimit -s unlimited

# Reverse search history
export HISTIGNORE="pwd:ls:cd"

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE
# export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so.0
# export I_MPI_PMI_LIBRARY=/usr/lib/x86_64-linux-gnu/libpmi.so.0

#FZF
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
export EDITOR="vim"

#------------------------------------------- ALIASES -------------------------------------------

alias q='squeue -u uherathmudiyanselage1 --format="%.18i %.9P %35j %.8u %.2t %.10M %.6D %R"'
alias interact="salloc --nodes 1 --ntasks-per-node=20 --qos interactive --time 04:00:00"
#alias sac="sacct --format="JobID,JobName%-30,State,User""
#alias sac="sacct -S $(date +%Y-%m-01) -E now -X --format="JobID,JobName%-30,State,WorkDir%-150""
alias sac="sacct -X --format="JobID,JobName%-30,State,nodelist%-30,WorkDir%-150""

alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from timewarp" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makejob="cp ~/dotfiles/locations/ncshare/jobscript.sh ."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"
alias f='vim "$(fzf)"'
alias scratch="cd /work/uherathmudiyanselage1"
alias globus="globusconnectpersonal -start -restrict-paths /hpc/home/uherathmudiyanselage1,/work/uherathmudiyanselage1 &"

#------------------------------------------- MODULES -------------------------------------------

# Compiler
source /hpc/home/uherathmudiyanselage1/intel/oneapi/setvars.sh --force > /dev/null

#------------------------------------------- FUNCTIONS -------------------------------------------

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/hpc/home/uherathmudiyanselage1/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/hpc/home/uherathmudiyanselage1/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/hpc/home/uherathmudiyanselage1/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/hpc/home/uherathmudiyanselage1/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

py2(){
   for i in $(seq ${CONDA_SHLVL}); do
       conda deactivate
   done
   conda activate py2
}
py3(){
   for i in $(seq ${CONDA_SHLVL}); do
       conda deactivate
   done
   conda activate py3
}
#default
py3

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

# Get job info from job-id
jobinfo(){
   scontrol show jobid -dd $1
}

# find-in-file - usage: fif <searchTerm> <directory>
fif() {
 if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
 if [ -z "$2" ]; then directory="./"; else directory="$2"; fi
 rg --files-with-matches --no-messages --smart-case --follow --hidden -g '!{node_modules,.git}' "$1"    "$directory"\
     | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow'\
     --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# colored cat
# function pygmentize_cat {
#   for arg in "$@"; do
#     pygmentize -g "${arg}" 2> /dev/null || /bin/cat "${arg}"
#   done
# }
# command -v pygmentize > /dev/null && alias cat=pygmentize_cat

#------------------------------------------- PATHS -------------------------------------------

export PATH="/hpc/home/uherathmudiyanselage1/dotfiles/:$PATH"
export PATH="/hpc/home/uherathmudiyanselage1/MatSciScripts/:$PATH"

# globus
export PATH="/hpc/home/uherathmudiyanselage1/local/globusconnectpersonal-3.2.6/:$PATH"

# ripgrep
export PATH="/hpc/home/uherathmudiyanselage1/local/ripgrep-14.1.1-x86_64-unknown-linux-musl/:$PATH"

# bat
export PATH="/hpc/home/uherathmudiyanselage1/local/bat:$PATH"

# FHI-aims
export PATH="/hpc/home/uherathmudiyanselage1/local/FHIaims/bin/:$PATH"
export PATH="/hpc/home/uherathmudiyanselage1/local/FHIaims/utilities/:$PATH"

# cmake
export PATH="/hpc/home/uherathmudiyanselage1/local/cmake-4.0.1/build/bin/:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
