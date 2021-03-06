# .bash_profile for Uthpalas-Macbook-Pro
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# Set stty off
if [[ -t 0 && $- = *i* ]]
  then
  stty -ixon
fi

# Memory
ulimit -s hard

# tmux
# export TMUX_DEVICE_NAME=macbook-pro
# if command -v tmux &> /dev/null && [ -t 0  ] && [[ -z $TMUX  ]] && [[ $- = *i*  ]]; then
#     tmux new-session -t macbook-pro || tmux new -s macbook-pro
# fi

# Sourcing intel oneAPI system
source /opt/intel/oneapi/setvars.sh  > /dev/null

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && source "$file"
done
unset file

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"

# Color folders
export CLICOLOR=1
export LSCOLORS=ExFxCxDxBxegedabagacad

# Remove warnings
export BASH_SILENCE_DEPRECATION_WARNING=1

# PYTHON
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/uthpala/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/uthpala/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/uthpala/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/uthpala/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# Anaconda environment
py2(){
    conda activate py2
}
py3(){
    conda activate py3
}
#default
py3



#------------------------------------------- FUNCTIONS -------------------------------------------

function cd {
  if [ ${#1} == 0 ]; then
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

function umount_all {
    umount ~/HPC/bridges/home
    umount ~/HPC/desktop/home
    umount ~/HPC/desktop2/home
    umount ~/HPC/spruce/home
    umount ~/HPC/stampede2/home
    umount ~/HPC/thorny/home
    umount ~/HPC/whitehall/home
}

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
# Creates directory then moves into it
function mkcdr {
  mkdir -p -v $1
cd $1
}
# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }


#------------------------------------------- PATHS -------------------------------------------

# Add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
PATH=/usr/local/bin/:$PATH
PATH=$HOME/bin:$PATH

# System library
export DYLD_LIBRARY_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/:$DYLD_LIBRARY_PATH"

# Compilers
# export CC="clang"
# export CXX="clang++"
# # export CC="gcc-10"
# export CXX="g++-10"

# Remove .pyc files
export PYTHONDONTWRITEBYTECODE=1

# Intel compilers
# export PATH="/opt/intel/bin/:$PATH"

# adding wannier and vasp directories
export PATH="/Users/uthpala/wannier90/wannier90-3.1.0/:$PATH"
export PATH="/Users/uthpala/VASP/vasp.5.4.4/bin/:$PATH"

# Siesta
export PATH="/Users/uthpala/siesta/siesta-4.1-b3/Obj/:$PATH"

# nbopen
export PATH="/Users/uthpala/nbopen/nbopen/:$PATH"

# p4vasp
export PATH="/Users/uthpala/p4vasp/bin/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# MatSciScripts
export PATH="~/Dropbox/git/MatSciScripts:$PATH"

# sod
export PATH="/Users/uthpala/sod/bin/:$PATH"

# openssl
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PATH="/usr/local/opt/openssl/bin:$PATH"

# For pkg-config to find openssl you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

# DMFTwDFT
export PYTHONPATH="/Users/uthpala/projects/DMFTwDFT/bin/:$PYTHONPATH"
export PATH="/Users/uthpala/projects/DMFTwDFT/bin/:$PATH"

# texlive
export PATH="/usr/local/texlive/2020/bin/x86_64-darwin/:$PATH"

# pandoc-templates
export PATH="/Users/uthpala/Dropbox/git/pandoc-templates/scripts/:$PATH"


# Perl warning fix
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Julia
export PATH="/Applications/Julia-1.5.app/Contents/Resources/julia/bin/:$PATH"

# Lobster
export PATH="/Users/uthpala/lobster/OSX/:$PATH"

# VMD
export PLUGINDIR="/Users/uthpala/vmd-1.9.3.src/plugins/"

# Jmol
export PATH="/Users/uthpala/jmol-14.30.2/:$PATH"

# eos
#export PATH="/Users/uthpala/eos/eos_au/:$PATH"
export PATH="/Users/uthpala/eos/eos/:$PATH"

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
export PBESOL="/Users/uthpala/abinit/pseudo-dojo/nc-fr-04_pbesol_standard_psp8/"
export PAWPBE="/Users/uthpala/abinit/pseudo-dojo/paw_pbe_standard/"
export PAWLDA="/Users/uthpala/abinit/pseudo-dojo/paw_pw_standard/"

# NEBgen
export PATH="/Users/uthpala/Dropbox/git/NEBgen/:$PATH"

# VTST
export PATH="/Users/uthpala//VTST/vtstscripts-957/:$PATH"

#------------------------------------------- ALIASES -------------------------------------------

alias wvu="ssh -tXY ukh0001@ssh.wvu.edu '~/bin/tmux -CC new -A -s main '"
alias sprucetmux="ssh -tXY ukh0001@spruce.hpc.wvu.edu 'tmux -CC new -A -s spruce '"

# logging through ssh.wvu.edu
alias spruce="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY ukh0001@spruce.hpc.wvu.edu'"
alias thorny="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY ukh0001@tf.hpc.wvu.edu'"
alias whitehall="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY ukh0001@157.182.3.76'"
alias whitehall2="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY ukh0001@157.182.3.75'"
alias desktop="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY uthpala@157.182.27.178'"
alias desktop2="ssh -tXY ukh0001@ssh.wvu.edu 'ssh -XY uthpala@157.182.28.27'"

# logging through spruce
# alias spruce="ssh -xy ukh0001@spruce.hpc.wvu.edu"
# alias thorny="ssh -tXY ukh0001@spruce.hpc.wvu.edu 'ssh -XY ukh0001@tf.hpc.wvu.edu'"
# alias whitehall="ssh -tXY ukh0001@spruce.hpc.wvu.edu 'ssh -XY ukh0001@157.182.3.76'"
# alias whitehall2="ssh -tXY ukh0001@spruce.hpc.wvu.edu 'ssh -XY ukh0001@157.182.3.75'"
# alias desktop="ssh -tXY ukh0001@spruce.hpc.wvu.edu 'ssh -tXY ukh0001@157.182.3.76 ssh -XY uthpala@157.182.27.178'"
# alias desktop2="ssh -tXY ukh0001@spruce.hpc.wvu.edu 'ssh -tXY ukh0001@157.182.3.76 ssh -XY uthpala@157.182.28.27'"


#alias bridges="ssh -XY  uthpala@bridges.psc.xsede.org"
alias bridges="ssh -tXY  uthpala@bridges.psc.xsede.org 'ssh -XY br005.pvt.bridges.psc.edu'"
alias bridges2="ssh -XY  uthpala@bridges2.psc.xsede.org"

#alias stampede2="ssh -XY  uthpala@stampede2.tacc.xsede.org"
alias stampede2="ssh -XY  uthpala@login1.stampede2.tacc.utexas.edu"

# Cori
alias cori="ssh -XY train61@cori.nersc.gov"

alias cleantmux='tmux kill-session -a'
alias brewup='brew update; brew upgrade; brew prune; brew cleanup; brew doctor'
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from mac" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/Dropbox/git/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/Dropbox/git/MatSciScripts/KPOINTS ."

alias sed="gsed"

# Mounting HPC drives
alias mount_bridges="sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges.psc.xsede.org:/home/uthpala ~/HPC/bridges/home"
alias mount_stampede2="sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
alias mount_spruce="sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@spruce.hpc.wvu.edu: ~/HPC/spruce/home"
alias mount_thorny="sshfs ukh0001@tf.hpc.wvu.edu: ~/HPC/thorny/home/ -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop="sshfs uthpala@157.182.27.178: ~/HPC/desktop/home -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop2="sshfs uthpala@157.182.28.27: ~/HPC/desktop2/home -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_whitehall="sshfs ukh0001@157.182.3.76: ~/HPC/whitehall/home -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
