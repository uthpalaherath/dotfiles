# .bashrc for timewarp (timewarp-02.egr.duke.edu)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

#set stty off
if [[ -t 0 && $- = *i* ]]
then
   stty -ixon
fi

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

# Memory
ulimit -s unlimited

# Reverse search history
if [[ $- == *i* ]]; then
    export HISTIGNORE="pwd:ls:cd"
    shopt -s histappend
    HISTCONTROL=ignoreboth:erasedups
    export PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi

# Starship prompt
_starship=$(command -v starship 2>/dev/null || { [ -x ~/.local/bin/starship ] && echo ~/.local/bin/starship; })
if [[ $- == *i* ]] && [ -n "$_starship" ]; then
    [ -f ~/dotfiles/configs/starship.toml ] && export STARSHIP_CONFIG=~/dotfiles/configs/starship.toml
    eval "$("$_starship" init bash)"
fi
unset _starship

# Color folders
export LS_OPTIONS='--color=auto'
eval "$(dircolors -b)"
alias ls='ls $LS_OPTIONS'
alias grep='grep --color=auto'

# OpenMP and MPI
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export MKL_DYNAMIC=FALSE
export I_MPI_PMI_LIBRARY=/usr/lib/x86_64-linux-gnu/libpmi.so.0
export LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LIBRARY_PATH

# ripgrep defaults
[ -f ~/dotfiles/configs/ripgreprc ] && export RIPGREP_CONFIG_PATH=~/dotfiles/configs/ripgreprc

#FZF
[ -f ~/.fzf.bash ] && source ~/.fzf.bash
export FZF_DEFAULT_COMMAND='rg --files --follow --type-not sql'
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

export MAMBA_CHANGEPS1=false
# >>> mamba initialize >>>
# !! Contents within this block are managed by 'mamba shell init' !!
export MAMBA_EXE='/zpool-00/space/home/ukh/miniforge3/bin/mamba';
export MAMBA_ROOT_PREFIX='/zpool-00/space/home/ukh/miniforge3';
__mamba_setup="$("$MAMBA_EXE" shell hook --shell bash --root-prefix "$MAMBA_ROOT_PREFIX" 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__mamba_setup"
else
    alias mamba="$MAMBA_EXE"  # Fallback on help from mamba activate
fi
unset __mamba_setup
mamba activate base
# <<< mamba initialize <<<
export UV_CACHE_DIR=/work/${USER}/tmp

# HuggingFace
export HF_HOME="${HOME}/.huggingface"
export FLASHINFER_WORKSPACE_BASE="/${HOME}"
export VLLM_CACHE_ROOT="/${HOME}/.cache/vllm"

# Ollama
export OLLAMA_MODELS="/${HOME}/.ollama/models"

# GNUTERM
export GNUTERM=x11

# Apptainer
export APPTAINER_CACHEDIR=/${HOME}/tmp
export APPTAINER_TMPDIR=/${HOME}/tmp

#------------------------------------------- ALIASES -------------------------------------------

alias q='squeue -u ukh --format="%.18i %.9P %35j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact="salloc --nodes 1 --ntasks-per-node=20 --qos interactive --time 04:00:00"

alias makejob="cp ~/dotfiles/locations/timewarp/jobscript.sh ."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"
alias tkill="tmux kill-session"
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"
alias f='vim "$(fzf)"'

#------------------------------------------- MODULES -------------------------------------------

module load git-2.37.3

intel(){
    if command -v module &> /dev/null
    then
        module load compiler/latest
        module load mkl/latest
        module load mpi/latest
        source /Space/globalspace/intel-2023.0/setvars.sh --force > /dev/null
        export LD_LIBRARY_PATH="/opt/intel/lib/intel64/:$LD_LIBRARY_PATH"

        # compilers
        export CC="mpiicc"
        export CXX="mpiicpc"
        export FC="mpiifort"
        export MPICC="mpiicc"
        export MPIFC="mpiifort"
    fi
}

intel18(){
    module load intel-compilers-2018.4
    source /opt/intel/bin/compilervars.sh intel64
}

intel2024(){
    source /home/ukh/intel/intel-2024/oneapi/setvars.sh --force > /dev/null
    export LD_LIBRARY_PATH="/home/ukh/intel/intel-2024/oneapi/2024.1/lib/:$LD_LIBRARY_PATH"

    # compilers
    export CC="mpiicx"
    export CXX="mpiicpx"
    export FC="mpiifx"
    export MPICC="mpiicx"
    export MPIFC="mpiifx"
}

intel2025(){
    source /home/ukh/intel/intel-2025/oneapi/setvars.sh --force > /dev/null
    export LD_LIBRARY_PATH="/home/ukh/intel/oneapi/2025.0/lib/:$LD_LIBRARY_PATH"

    # compilers
    export CC="mpiicx"
    export CXX="mpiicpx"
    export FC="mpiifx"
    export MPICC="mpiicx"
    export MPIFC="mpiifx"
}


gnu(){
    # module load gcc-7.5
    # module load gcc-8.2
    module load gcc-12.2.0
    # export PATH="/home/ukh/lib/openmpi-4.1.5/build/bin/:$PATH$"
    # export LD_LIBRARY_PATH="/home/ukh/lib/openmpi-4.1.5/build/lib/:$LD_LIBRARY_PATH"

    export PATH="/home/ukh/lib/mpich-3.2.1/build/bin/:$PATH"
    export LD_LIBRARY_PATH="/home/ukh/lib/mpich-3.2.1/build/lib/:$LD_LIBRARY_PATH"
    export MPI_ROOT="/home/ukh/lib/mpich-3.2.1/build/"

    # compilers
    export CC="mpicc"
    export CXX="mpicxx"
    export FC="mpif90"
    export MPICC="mpicc"
    export MPIFC="mpif90"
}

# default
intel

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

# rgf: fuzzy-search inside files, open the match in vim
rgf() {
  local sel
  sel=$(rg --line-number --no-heading --color=always "${1:-}" |
        fzf --ansi --delimiter : --preview 'bat --color=always --style=numbers --highlight-line {2} {1}' --preview-window '+{2}/2') || return
  vim "+$(cut -d: -f2 <<< "$sel")" "${sel%%:*}"
}

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

# FHI-aims
export PATH="/home/ukh/local/FHIaims/bin/:$PATH"
export PATH="/home/ukh/local/FHIaims/utilities/:$PATH"

# MatSciScripts
export PATH="/home/ukh/MatSciScripts/:$PATH"

# dotfiles
export PATH="/home/ukh/dotfiles/:$PATH"

# gsl
export LD_LIBRARY_PATH="/jet/home/uthpala/lib/gsl-2.6/build/lib/:$LD_LIBRARY_PATH"

# ctags
export PATH="/home/ukh/local/ctags-5.8/build/bin/:$PATH"

# go
export PATH="/home/ukh/local/go/bin/:$PATH"

# node
export PATH="/home/ukh/local/node-v21.7.3-linux-x64/bin/:$PATH"
export LD_LIBRARY_PATH="/home/ukh/local/node-v21.7.3-linux-x64/lib/:$LD_LIBRARY_PATH"

# libtool
export PATH="/home/ukh/local/libtool-2.4.6/build/bin/:$PATH"
export LD_LIBRARY_PATH="/home/ukh/local/libtool-2.4.6/build/lib:$LD_LIBRARY_PATH"

# globus
export PATH="/home/ukh/local/globusconnectpersonal-3.2.0/:$PATH"

# scalapack
export LD_LIBRARY_PATH="/home/ukh/lib/scalapack-2.2.0/:$LD_LIBRARY_PATH"

# atomate2
export ATOMATE2_CONFIG_FILE="/home/ukh/.config/atomate2/atomate2.yaml"
export AIMS_SPECIES_DIR="/home/ukh/local/FHIaims/species_defaults/defaults_2020/"

#------------------------------------------- TMUX -------------------------------------------

export TMUX_DEVICE_NAME=timewarp
if [[ $- == *i* && -t 0 && -z $TMUX ]]; then
    tmux new -A -s $TMUX_DEVICE_NAME
fi
