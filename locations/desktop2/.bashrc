#set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi 

export TMUX_DEVICE_NAME=desktop2
############ tmux ###############
# if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
#  # (cd $PWD; tmux attach-session -t desktop -c $PWD  ) || (cd $PWD; tmux new -s desktop -c $PWD  )
#  exec tmux
# fi

#################################

#aliases
alias spruce='ssh -X ukh0001@spruce.hpc.wvu.edu'
alias bridges='ssh -XYC uthpala@bridges.psc.xsede.org'
alias stampede='ssh -XYC uthpala@stampede2.tacc.xsede.org'
alias whitehall="ssh -XC ukh0001@157.182.3.76"
alias cleantmux="tmux kill-session -a"

killtmux(){
    for arg
    do tmux kill-session -t "desktop2 $arg"
    done
}


#sourcing intel compilers
source /opt/intel/bin/compilervars.sh intel64
source /opt/intel/mkl/bin/mklvars.sh intel64

#set MPI
export I_MPI_SHM_LMT=shm

#vasp
export PATH="/home/uthpala/VASP/vasp.5.4.4/bin/:$PATH"

#anaconda
export PATH="/home/uthpala/anaconda2/bin/:$PATH"
export PATH="/home/uthpala/anaconda3/bin/:$PATH"

#Library path
export LD_LIBRARY_PATH="/usr/local/lib/:$LD_LIBRARY_PATH"

#scripts
export PATH="~/dotfiles/:$PATH"


#DMFT
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PATH"
#export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/:$PYTHONPATH"
#export DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/"
#export PATH="/home/uthpala/VASP/vasp_dmft/bin/:$PATH"
#export WIEN_DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/bin/"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/bands/:$PATH"
#export PATH="/home/uthpala/Dropbox/Research/Projects/DMFT/codes/vaspDMFT/post_processing/ancont_PM/:$PATH"

#DMFTwDFT
export PATH="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/home/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/"
export PATH="/home/uthpala/VASP/vasp.5.4.4_dmft/bin/:$PATH"


#wannier90
export PATH="/home/uthpala/wannier90/wannier90-1.2/:$PATH"
#export PATH="/home/uthpala/wannier90/wannier90-3.0.0/:$PATH"

#Vesta
export PATH="/home/uthpala/VESTA/:$PATH"

#globus
export PATH="/home/uthpala/globusconnectpersonal/:$PATH"

#siesta
export PATH="/home/uthpala/siesta/siesta-4.1-b4/Obj/:$PATH"
export PATH="/home/uthpala/siesta/siesta-lowdin/Obj/:$PATH"

#NETCDF
export NETCDF_ROOT="/opt/netcdf/"
export LD_LIBRARY_PATH="/opt/netcdf/lib/:$LD_LIBRARY_PATH"

#EDMFT
#export WIEN_DMFT_ROOT=$HOME/EDMFT/bin  
export PYTHONPATH=$PYTHONPATH:$WIEN_DMFT_ROOT  
#export WIENROOT=$HOME/wien2k
export SCRATCH="." 
export EDITOR="vim"
export PATH=$WIENROOT:$WIEN_DMFT_ROOT:$PATH 

#elk
export PATH="/home/uthpala/elk/elk-6.3.2/src/:$PATH"
export PATH="/home/uthpala/elk/elk-6.3.2/src/spacegroup/:$PATH"

# go
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

##### SYSTEM ##############


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

ulimit -s unlimited
source ~/.bash_prompt
# Install Ruby Gems to ~/gems
export GEM_HOME="$HOME/gems"
export PATH="$HOME/gems/bin:$PATH"

