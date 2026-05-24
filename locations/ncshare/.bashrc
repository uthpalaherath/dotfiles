# .bashrc for ncshare (login.ncshare.org)
# -Uthpala Herath

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

# tmux
export TMUX_DEVICE_NAME=ncshare
host_short=$(hostname -s)
case "$host_short" in
  login-*) is_login=true ;;
  *)       is_login=false ;;
esac
if [[ "$is_login" == "true" ]] && command -v tmux >/dev/null && [ -t 0 ] && [[ -z "$TMUX" ]] && [[ $- == *i* ]]; then
    tmux attach -t "$TMUX_DEVICE_NAME" 2>/dev/null || tmux new -s "$TMUX_DEVICE_NAME"
fi

# Memory
ulimit -s unlimited

# Reverse search history
if [[ $- == *i* ]]; then
    export HISTIGNORE="pwd:ls:cd"
    shopt -s histappend
    HISTCONTROL=ignoreboth:erasedups
    #export PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"
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
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE

# PYTHON
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/hpc/home/uherathmudiyanselage1/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/hpc/home/uherathmudiyanselage1/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/hpc/home/uherathmudiyanselage1/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/hpc/home/uherathmudiyanselage1/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/hpc/home/uherathmudiyanselage1/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/hpc/home/uherathmudiyanselage1/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell zsh --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0  ]; then
        eval "$__mamba_setup"
    else
            alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
# <<< mamba initialize <<<
export UV_CACHE_DIR=/work/${USER}/tmp

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

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# rust
. "$HOME/.cargo/env"

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

# Matplotlib
export PYTHONPATH="/hpc/home/uherathmudiyanselage1/dotfiles/matplotlib/:$PYTHONPATH"
export MPLCONFIGDIR="/hpc/home/uherathmudiyanselage1/dotfiles/matplotlib/"

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

# yazi
export PATH="/hpc/home/uherathmudiyanselage1/local/yazi/target/release/:$PATH"

# opencode
export PATH=/hpc/home/uherathmudiyanselage1/.opencode/bin:$PATH

# vim
export PATH="/hpc/home/uherathmudiyanselage1/apps/vim/bin/:$PATH"
export VIM="/hpc/home/uherathmudiyanselage1/apps/vim/share/vim"
export VIMRUNTIME="/hpc/home/uherathmudiyanselage1/apps/vim/share/vim/vim92"
