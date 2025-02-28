# .zshrc for Uthpalas-Macbook-Pro
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# Path to your oh-my-zsh installation.
export ZSH="/Users/uthpala/.oh-my-zsh"

ZSH_THEME="honukai"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions fzf) # copydir dirhistory macos)
DISABLE_UNTRACKED_FILES_DIRTY="false"

## Plugin settings

# zsh-autosuggestions
bindkey '`' autosuggest-accept
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

source $ZSH/oh-my-zsh.sh
add-zsh-hook precmd virtenv_indicator

# Memory
ulimit -s hard

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
  [[ -r "$file" ]] && source "$file"
done
unset file

# Compiler setting
intel(){
    # Sourcing intel oneAPI system
    source /opt/intel/oneapi/setvars.sh  > /dev/null

    # Scalapack
    export DYLD_LIBRARY_PATH="/Users/uthpala/lib/INTEL/scalapack-2.2.0/:$DYLD_LIBRARY_PATH"

    # OpenMPI (compiled with intel)
    export PATH="/Users/uthpala/lib/INTEL/openmpi-5.0.3/build/bin/:$PATH"
    export DYLD_LIBRARY_PATH="/Users/uthpala/lib/INTEL/openmpi-5.0.3/build/lib/:$DYLD_LIBRARY_PATH"
    export OMPI_CC="icc"
    export OMPI_CXX="icpc"
    export OMPI_FC="ifort"
}

gnu(){
    # Scalapack
    export DYLD_LIBRARY_PATH="/Users/uthpala/lib/GNU/scalapack-2.2.0/:$DYLD_LIBRARY_PATH"

    # OpenMPI (GNU)
    export PATH="/Users/uthpala/lib/GNU/openmpi-5.0.3/build/bin/:$PATH"
    export DYLD_LIBRARY_PATH="/Users/uthpala/lib/GNU/openmpi-5.0.3/build/lib/:$DYLD_LIBRARY_PATH"
    export OMPI_CC="gcc"
    export OMPI_CXX="g++"
    export OMPI_FC="gfortran"
}
# default
intel

export CC="mpicc"
export CXX="mpicxx"
export FC="mpif90"

# PYTHON
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/uthpala/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/uthpala/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/uthpala/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/uthpala/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Display Python environment
export VIRTUAL_ENV_DISABLE_PROMPT=yes

function virtenv_indicator {
    if [[ -z $CONDA_DEFAULT_ENV ]] then
        psvar[1]=''
    else
        psvar[1]=${CONDA_DEFAULT_ENV##*/}
    fi
}

# conda environment
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

# tmux
export TMUX_DEVICE_NAME=MBP
tm(){
    if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
        tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
    fi
}

#FZF
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

#------------------------------------------- FUNCTIONS -------------------------------------------

cd() {
  if [[ ${#1} == 0 ]]; then
    builtin cd
  elif [ -d "${1}" ]; then
    builtin cd "${1}"
  elif [[ -f "${1}" || -L "${1}" ]]; then
    path=$(getTrueName "$1")
    builtin cd "$path"
  else
    builtin cd "${1}"
  fi
}

if expr "$(ps -o comm= $PPID)" : '^sshd:' > /dev/null; then
  caffeinate -s $SHELL --login
  exit $?
fi

# extract, mkcdr and archive creattion were taken from
# https://gist.github.com/JakubTesarek/8840983
# Easy extract
extract () {
    if [[ -f $1 ]] ; then
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

# mounting all HPC locations
mount_all(){
    mount_spruce;
    mount_thorny;
    mount_whitehall;
    mount_desktop;
    mount_desktop2;
    #mount_romeronas;
    mount_bridges2;
}

# unmounting all HPC locations
umount_all(){
    umount -f /Users/uthpala/HPC/bridges2/home
    umount -f /Users/uthpala/HPC/desktop/home
    umount -f /Users/uthpala/HPC/desktop2/home
    umount -f /Users/uthpala/HPC/spruce/home
    umount -f /Users/uthpala/HPC/stampede2/home
    umount -f /Users/uthpala/HPC/thorny/home
    umount -f /Users/uthpala/HPC/whitehall/home
    umount -f /Users/uthpala/HPC/romeronas/home
    umount -f /Users/uthpala/HPC/timewarp2/home
    umount -f /Users/uthpala/HPC/frontera/home
}

# find-in-file - usage: fif <searchTerm> <directory>
fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  if [ -z "$2" ]; then directory="./"; else directory="$2"; fi
  rg --files-with-matches --no-messages --smart-case --follow --hidden -g '!{node_modules,.git}' "$1" "$directory"\
      | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow'\
      --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# dump db
# Usage: dump_db <database_name>
dump_db(){
   mysqldump -u uthpala -puthpala1234 $1 > "$1"-`date +%F`.sql
}

# update materials database
# Usage: update_db <db_name> <file.sql>
update_db(){
   #sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' $2
   mariadb -u uthpala -puthpala1234 -Bse "DROP DATABASE IF EXISTS $1;CREATE DATABASE $1;"
   mariadb -u uthpala -puthpala1234 $1 < $2
}

#------------------------------------------- PATHS -------------------------------------------

# Matplotlib
export PYTHONPATH="/Users/uthpala/Dropbox/git/dotfiles/matplotlib/:$PYTHONPATH"
export MPLCONFIGDIR="/Users/uthpala/Dropbox/git/dotfiles/matplotlib/"

# Add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
# PATH=/usr/local/bin/:$PATH
# PATH=$HOME/bin:$PATH
# export PATH="/usr/local/sbin:$PATH"

# System library
export DYLD_LIBRARY_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/:$DYLD_LIBRARY_PATH"

# GSL
export DYLD_LIBRARY_PATH="/usr/local/Cellar/gsl/2.7.1/lib/:$DYLD_LIBRARY_PATH$"

# Remove .pyc files
export PYTHONDONTWRITEBYTECODE=1

# DMFTwDFT
export PATH="/Users/uthpala/Dropbox/git/DMFTwDFT/bin/:$PATH"
export PATH="/Users/uthpala/Dropbox/git/DMFTwDFT/scripts/:$PATH"
export PYTHONPATH="/Users/uthpala/Dropbox/git/DMFTwDFT/bin/:$PYTHONPATH"

# adding wannier and vasp directories
export DYLD_LIBRARY_PATH="/Users/uthpala/apps/wannier90/wannier90-3.1.0/:$DYLD_LIBRARY_PATH"
export PATH="/Users/uthpala/apps/wannier90/wannier90-3.1.0/:$PATH"
export PATH="/Users/uthpala/apps/VASP/vasp.5.4.4/bin/:$PATH"

# Siesta
export PATH="/Users/uthpala/apps/siesta/siesta-4.1-b3/Obj/:$PATH"

# nbopen
export PATH="/Users/uthpala/nbopen/nbopen/:$PATH"

# p4vasp
export PATH="/Users/uthpala/apps/p4vasp/bin/:$PATH"

# dotfiles
export PATH="/Users/uthpala/Dropbox/git/dotfiles/:$PATH"

# MatSciScripts
export PATH="/Users/uthpala/Dropbox/git/MatSciScripts/:$PATH"

# sod
export PATH="/Users/uthpala/apps/sod/bin/:$PATH"

# openssl
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PATH="/usr/local/opt/openssl/bin:$PATH"

# For pkg-config to find openssl you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

# texlive
export PATH="/usr/local/texlive/2022/bin/universal-darwin/:$PATH"

# pandoc-templates
export PATH="/Users/uthpala/Dropbox/git/pandoc-templates/scripts/:$PATH"

# Perl warning fix
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Julia
export PATH="/Users/uthpala/.juliaup/bin/:$PATH"

# Lobster
export PATH="/Users/uthpala/apps/lobster-4.1.0/OSX/:$PATH"

# VMD
export PLUGINDIR="/Users/uthpala/apps/vmd-1.9.3.src/plugins/"

# Jmol
export PATH="/Users/uthpala/apps/jmol-14.30.2/:$PATH"

# eos
#export PATH="/Users/uthpala/eos/eos_au/:$PATH"
export PATH="/Users/uthpala/apps/eos/eos/:$PATH"

# libxml
export PATH="/usr/local/opt/libxml2/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/libxml2/lib"
export CPPFLAGS="-I/usr/local/opt/libxml2/include"
export PKG_CONFIG_PATH="/usr/local/opt/libxml2/lib/pkgconfig"

# hdf5
export PATH="/usr/local/opt/hdf5-parallel/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/hdf5-parallel/lib"
export CPPFLAGS="-I/usr/local/opt/hdf5-parallel/include"

# Abinit pseudopotentials
export NC_PBEsol="/Users/uthpala/apps/abinit/pseudo-dojo/nc-fr-04_pbesol_standard_psp8/"
export PAWPBE="/Users/uthpala/apps/abinit/pseudo-dojo/paw_pbe_standard/"
export PAWLDA="/Users/uthpala/apps/abinit/pseudo-dojo/paw_pw_standard/"

# NEBgen
export PATH="/Users/uthpala/Dropbox/git/NEBgen/:$PATH"

# VTST
export PATH="/Users/uthpala/apps/VTST/vtstscripts-978/:$PATH"

# xcrysden
export PATH="/Users/uthpala/apps/xcrysden-1.6.2/:$PATH"

#nciplot
export PATH="/Users/uthpala/apps/nciplot/src_nciplot_4.0/:$PATH"
export NCIPLOT_HOME=/Users/uthpala/apps/nciplot/

# rsync
export PATH="/usr/local/Cellar/rsync/3.2.3/bin/:$PATH"

# tsase
export PYTHONPATH=$HOME/tsase:$PYTHONPATH
export PATH=$HOME/tsase/bin:$PATH

# FHI-aims
export PATH="/Users/uthpala/apps/FHIaims/FHIaims/bin/:$PATH"
export PATH="/Users/uthpala/apps/FHIaims/FHIaims/utilities/:$PATH"
export SPECIES_DEFAULTS="/Users/uthpala/apps/FHIaims/FHIaims/species_defaults/"
export AIMS_SPECIES_DEFAULTS="/Users/uthpala/apps/FHIaims/FHIaims/species_defaults/"

# nodejs
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Scripts directory
export PATH="/Users/uthpala/Library/CloudStorage/Dropbox/docs/Jobs/Scripts/:$PATH"
export PYTHONPATH="/Users/uthpala/Library/CloudStorage/Dropbox/docs/Jobs/Scripts/:$PYTHONPATH"

# Ruby
source /usr/local/opt/chruby/share/chruby/chruby.sh
source /usr/local/opt/chruby/share/chruby/auto.sh
chruby ruby-3.1.3

# mysql-client
# export PATH="/usr/local/opt/mysql-client/bin:$PATH"
# export DYLD_LIBRARY_PATH="/usr/local/opt/mysql-client/lib:$DYLD_LIBRARY_PATH"
# export LDFLAGS="-L/usr/local/opt/mysql-client/lib"
# export CPPFLAGS="-I/usr/local/opt/mysql-client/include"

# atomate2
export ATOMATE2_CONFIG_FILE="/Users/uthpala/atomate-workflows/config/atomate2.yaml"
export JOBFLOW_CONFIG_FILE="/Users/uthpala/atomate-workflows/config/jobflow.yaml"
export AIMS_SPECIES_DIR="/Users/uthpala/apps/FHIaims/FHIaims/species_defaults/defaults_2020/"

# mushroom
export PATH="/Users/uthpala/apps/mushroom/scripts/:$PATH"
export PYTHONPATH="/Users/uthpala/apps/mushroom/:$PYTHONPATH"

#------------------------------------------- ALIASES -------------------------------------------

# sudo alias
alias sudo='sudo '

# WVU Connections
# logging through ssh.wvu.edu

alias wvu="ssh -tY ukh0001@ssh.wvu.edu '~/bin/tmux -CC new -A -s main '"
alias sprucetmux="ssh -tY ukh0001@spruce.hpc.wvu.edu 'tmux -CC new -A -s spruce '"
alias spruce="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@spruce.hpc.wvu.edu'"
#alias thorny="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@tf.hpc.wvu.edu'"
alias thorny="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@trcis001.hpc.wvu.edu'"
alias whitehall="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.76'"
alias whitehall2="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.75'"
alias whitehall3="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.77'"
alias desktop="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y uthpala@157.182.27.178'"
alias desktop2="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y uthpala@157.182.28.27'"
alias romeronas="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@romeronas.wvu-ad.wvu.edu'"

# Mounting HPC drives without ssh options
alias mount_spruce="umount ~/HPC/spruce/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@spruce.hpc.wvu.edu: ~/HPC/spruce/home"
alias mount_thorny="umount ~/HPC/thorny/home; sshfs trcis001.hpc.wvu.edu: ~/HPC/thorny/home/ -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop="umount ~/HPC/desktop/home; sshfs uthpala@157.182.27.178: ~/HPC/desktop/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop2="umount ~/HPC/desktop2/home; sshfs uthpala@157.182.28.27: ~/HPC/desktop2/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_whitehall="umount ~/HPC/whitehall/home; sshfs ukh0001@157.182.3.76: ~/HPC/whitehall/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_romeronas="umount ~/HPC/romeronas/home; sshfs ukh0001@romeronas.wvu-ad.wvu.edu: ~/HPC/romeronas/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"

# Other ssh connections
alias bridges2="ssh -Y uthpala@br012.bridges2.psc.edu"
# alias stampede2="ssh -Y uthpala@login1.stampede2.tacc.utexas.edu"
alias stampede2="ssh -Y uthpala@stampede2.tacc.utexas.edu"
alias timewarp2='ssh -Y ukh@timewarp-02.egr.duke.edu'
alias perlmutter="ssh -Y uthpala@perlmutter-p1.nersc.gov"
#alias frontera="ssh -Y uthpala@frontera.tacc.utexas.edu"
alias frontera="ssh -Y uthpala@login1.frontera.tacc.utexas.edu"
alias materials="ssh -Y ukh@materials.hybrid3.duke.edu"
# alias dcc="ssh -Y ukh@dcc-login.oit.duke.edu"
alias dcc="ssh -Y ukh@dcc-login-01.oit.duke.edu"

# Mounting drives
alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
alias mount_timewarp2="umount ~/HPC/timewarp2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh@timewarp-02.egr.duke.edu: ~/HPC/timewarp2/home"
alias mount_perlmutter="umount ~/HPC/perlmutter/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@perlmutter-p1.nersc.gov: ~/HPC/perlmutter/home"
alias mount_frontera="umount ~/HPC/frontera/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@frontera.tacc.utexas.edu: ~/HPC/frontera/home"
alias mount_dcc="umount ~/HPC/dcc/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh@dcc-login.oit.duke.edu: ~/HPC/dcc/home"

# git repos
alias dotrebase='cd /Users/uthpala/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd /Users/uthpala/dotfiles && git add . && git commit -m "Update from mac" && git push || true && cd -'
alias dotpull='cd /Users/uthpala/dotfiles && git pull || true && cd -'

# Generate files
alias makeINCAR="cp /Users/uthpala/Dropbox/git/MatSciScripts/INCAR ."
alias makeKPOINTS="cp /Users/uthpala/Dropbox/git/MatSciScripts/KPOINTS ."
alias makereport="cp /Users/uthpala/Dropbox/git/dotfiles/templates/report.tex ."

# Other system aliases
alias cleantmux='tmux kill-session -a'
alias brewup='brew update; brew upgrade; brew cleanup; brew doctor'
alias sed="gsed"
alias cpr="rsync -ah --info=progress2"
alias ctags="`brew --prefix`/bin/ctags"
alias createbib="ln /Users/uthpala/Dropbox/references-zotero.bib"

# docker
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"

# mariadb
alias db="mariadb -u uthpala -p'uthpala1234'"

# delete all .DS_Store files
alias cleands="find . -name ".DS_Store" -type f -delete"

# cleanup cache
alias cleanup="rm -rf ~/Library/Caches/ ~/Library/Logs /Library/Caches/ /System/Library/Caches/ /Library/Logs/"
