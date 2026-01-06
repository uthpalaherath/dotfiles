# .zshrc for Uthpalas-Macbook-Pro
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# Path to your oh-my-zsh installation.
export ZSH="/Users/ukh/.oh-my-zsh"

ZSH_THEME="honukai"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions fzf zsh-syntax-highlighting web-search) # copydir dirhistory macos)
DISABLE_UNTRACKED_FILES_DIRTY="false"

# zsh-autosuggestions
bindkey '`' autosuggest-accept
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

# Set up fzf key bindings and fuzzy completion
eval "$(fzf --zsh)"

source $ZSH/oh-my-zsh.sh

# Memory
ulimit -s hard

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
  [[ -r "$file" ]] && source "$file"
done
unset file

# MPI variables
export CC="mpicc"
export CXX="mpicxx"
export FC="mpif90"

# PYTHON
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/ukh/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/ukh/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/ukh/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/ukh/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Remove .pyc files
export PYTHONDONTWRITEBYTECODE=1

# tmux
export TMUX_DEVICE_NAME=MBP
tm(){
    if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
        tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
    fi
}
tm

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

# Perl warning fix
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

#------------------------------------------- FUNCTIONS -------------------------------------------

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

# dump db
# Usage: dump_db <database_name>
dump_db(){
   mysqldump -u uthpala -puthpala1234 $1 > "$1"-`date +%F`.sql
}

# update database
# Usage: update_db <db_name> <file.sql>
update_db(){
   #sed -i 's/utf8mb4_0900_ai_ci/utf8mb4_unicode_ci/g' $2
   mariadb -u uthpala -puthpala1234 -Bse "DROP DATABASE IF EXISTS $1;CREATE DATABASE $1;"
   mariadb -u uthpala -puthpala1234 $1 < $2
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

# local bin
export PATH="$HOME/.local/bin:$PATH"

# dotfiles
export PATH="/Users/ukh/git/dotfiles/:$PATH"

# MatSciScripts
export PATH="/Users/ukh/git/MatSciScripts/:$PATH"

# Matplotlib
export PYTHONPATH="/Users/ukh/git/dotfiles/matplotlib/:$PYTHONPATH"
export MPLCONFIGDIR="/Users/ukh/git/dotfiles/matplotlib/"

# System library
export DYLD_LIBRARY_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/:$DYLD_LIBRARY_PATH"

# FHI-aims
export PATH="/Users/ukh/apps/FHIaims/bin/:$PATH"
export PATH="/Users/ukh/apps/FHIaims/utilities/:$PATH"
export SPECIES_DEFAULTS="/Users/ukh/apps/FHIaims/species_defaults/"
export AIMS_SPECIES_DEFAULTS="/Users/ukh/apps/FHIaims/species_defaults/"

# nodejs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# ruby
source /opt/homebrew/opt/chruby/share/chruby/chruby.sh
source /opt/homebrew/opt/chruby/share/chruby/auto.sh
chruby ruby-3.4.1

# siesta
export PATH="/Users/ukh/apps/siesta-5.4.2/build/bin/:$PATH"

#------------------------------------------- ALIASES -------------------------------------------

alias sudo='sudo '

# asciinema
alias rec='asciinema rec'
alias play='asciinema play'
alias astream='asciinema stream -r'
alias asession='asciinema session -r'

# WVU Connections
# logging through ssh.wvu.edu

alias wvu="ssh -tY ukh0001@ssh.wvu.edu '~/bin/tmux -CC new -A -s main '"
alias sprucetmux="ssh -tY ukh0001@spruce.hpc.wvu.edu 'tmux -CC new -A -s spruce '"
alias spruce="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@spruce.hpc.wvu.edu'"
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
alias stampede2="ssh -Y uthpala@stampede2.tacc.utexas.edu"
alias timewarp2='ssh -Y ukh@timewarp-02.egr.duke.edu'
alias perlmutter="ssh -Y uthpala@perlmutter-p1.nersc.gov"
alias frontera="ssh -Y uthpala@frontera.tacc.utexas.edu"
alias hybrid3="ssh -Y ukh@vwb3-web-06.egr.duke.edu" #alias: materials.hybrid3.duke.edu
alias muchasdb="ssh -Y ukh@vwb3-web-04.egr.duke.edu" #alias: materials.hybrid3.duke.edu
alias dcca="ssh -Y ukh@dcc-login.oit.duke.edu"
alias dcc="ssh -Y ukh@dcc-login-01.oit.duke.edu"
alias dccshed="ssh -Y dcc-sched-01.rc.duke.edu"
alias ncshare="ssh -Y uherathmudiyanselage1@login.ncshare.org"

# Mounting drives
alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
alias mount_timewarp2="umount ~/HPC/timewarp2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh@timewarp-02.egr.duke.edu: ~/HPC/timewarp2/home"
alias mount_perlmutter="umount ~/HPC/perlmutter/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@perlmutter-p1.nersc.gov: ~/HPC/perlmutter/home"
alias mount_frontera="umount ~/HPC/frontera/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@frontera.tacc.utexas.edu: ~/HPC/frontera/home"
alias mount_dcc="umount ~/HPC/dcc/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh@dcc-login.oit.duke.edu: ~/HPC/dcc/home"
alias mount_muchasdb="umount ~/HPC/muchasdb/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh@vwb3-web-03.egr.duke.edu: ~/HPC/muchasdb/home"
alias mount_ncshare="umount ~/HPC/ncshare/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uherathmudiyanselage1@login.ncshare.org: ~/HPC/ncshare/home"

# git repos
alias dotrebase='cd /Users/ukh/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd /Users/ukh/dotfiles && git add . && git commit -m "Update from mac" && git push || true && cd -'
alias dotpull='cd /Users/ukh/dotfiles && git pull || true && cd -'

# Generate files
alias makeINCAR="cp /Users/ukh/git/MatSciScripts/INCAR ."
alias makeKPOINTS="cp /Users/ukh/git/MatSciScripts/KPOINTS ."
alias makereport="cp /Users/ukh/git/dotfiles/templates/report.tex ."

# Other system aliases
alias cleantmux='tmux kill-session -a'
alias brewup='brew update; brew upgrade; brew cleanup; brew doctor'
alias sed="gsed"
alias cpr="rsync -ah --info=progress2"
alias ctags="`brew --prefix`/bin/ctags"
alias createbib="ln /Users/ukh/Dropbox/references-zotero.bib"

# docker
alias cleandocker="docker image prune -a -f && docker volume prune -f"
alias cleandockerall="docker system prune -a -f"

# mariadb
alias db="mariadb -u uthpala -p'uthpala1234'"

# delete all .DS_Store files
alias cleands="find . -name ".DS_Store" -type f -delete"

# cleanup cache
alias cleanup="rm -rf ~/Library/Caches/ ~/Library/Logs /Library/Caches/ /System/Library/Caches/ /Library/Logs/"
#source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# box folder
alias box="cd /Users/ukh/Library/CloudStorage/Box-Box"
