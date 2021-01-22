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
export TMUX_DEVICE_NAME=macbook-pro
#if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
#   #tmux attach -t default || tmux new -s default
#   #(cd $(PWD); tmux attach-session -t macbook-pro -c $(PWD)  ) || (cd $(PWD);tmux new -s macbook-pro -c $(PWD)  )
#   exec tmux
#fi

# Sourcing intel compilers
source /opt/intel/bin/compilervars.sh intel64
source /opt/intel/mkl/bin/mklvars.sh intel64

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

#eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"

# killtmux(){
#     for arg
#     do tmux kill-session -t "macbook-pro $arg"
#     done
# }

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
export PATH="/opt/intel/bin/:$PATH"

# adding wannier and vasp directories
export PATH="/Users/uthpala/lib/wannier90/wannier90-2.1.0/:$PATH"
export PATH="/Users/uthpala/VASP/vasp.5.4.4/bin/:$PATH"
export WANNIER_DIR="/Users/uthpala/lib/wannier90/wannier90-1.2/"

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

#alias stampede2="ssh -XY  uthpala@stampede2.tacc.xsede.org"
alias stampede2="ssh -XY  uthpala@login1.stampede2.tacc.utexas.edu"

# Cori
alias cori="ssh -XY train61@cori.nersc.gov"

alias cleantmux='tmux kill-session -a'
alias brewup='brew update; brew upgrade; brew prune; brew cleanup; brew doctor'
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from mac" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
#alias tmux="tmux -CC new -A -s main"
alias tmux="(cd $(PWD); tmux attach-session -t macbook-pro -c $(PWD)  ) || (cd $(PWD);tmux new -s macbook-pro -c $(PWD))"

alias makeINCAR="cp ~/Dropbox/git/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/Dropbox/git/MatSciScripts/KPOINTS ."
