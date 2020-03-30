#set stty off
if [[ -t 0 && $- = *i* ]]
  then
  stty -ixon
fi

###### tmux ############
export TMUX_DEVICE_NAME=macbook-pro
#if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then 
#   #tmux attach -t default || tmux new -s default 
#   #(cd $(PWD); tmux attach-session -t macbook-pro -c $(PWD)  ) || (cd $(PWD);tmux new -s macbook-pro -c $(PWD)  )
#   exec tmux
#fi

#########################

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
ulimit -s hard
##################################################################ENVIRONMENTAL VARIABLES #############################################

# Add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
PATH=/usr/local/bin/:$PATH
PATH=$HOME/bin:$PATH

#adding intel compilers
source /opt/intel/bin/compilervars.sh intel64
source /opt/intel/mkl/bin/mklvars.sh intel64
export PATH="/opt/intel/bin/:$PATH"

#adding wannier and vasp directories
#export PATH="/Users/uthpala/lib/wannier90/wannier90-1.2/:$PATH"
export PATH="/Users/uthpala/lib/wannier90/wannier90-2.1.0/:$PATH"
export PATH="/Users/uthpala/VASP/vasp.5.4.4/bin/:$PATH"
export WANNIER_DIR="/Users/uthpala/lib/wannier90/wannier90-1.2/"

#PyChemia
export PYTHONPATH=$HOME/PyChemia:$PYTHONPATH

#Siesta
export PATH="/Users/uthpala/siesta/siesta-4.1-b3/Obj/:$PATH"
export PATH="/Users/uthpala/siesta/siestaw/Obj/:$PATH"

#nbopen
export PATH="/Users/uthpala/nbopen/nbopen/:$PATH"

#p4vasp
export PATH="/Users/uthpala/p4vasp/bin/:$PATH"

#pythonpath
#export PYTHONPATH=~/.local/lib
#export PYTH=~/.local/bin:$PATH

#CC
export CC="clang"
export CXX="clang++"
#export FC="gfortran-9"
#export CPP="/usr/local/bin/cpp"

#XCrySDen
export XCRYSDEN_TOPDIR=/opt/local/share/xcrysden-1.5.60
export XCRYSDEN_SCRATCH=/tmp
export PATH="/opt/local/share/xcrysden-1.5.60/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"

# matsciscripts
export PATH="~/Dropbox/git/MatSciScripts:$PATH"

#sod
export PATH="/Users/uthpala/sod/bin/:$PATH"

#openssl
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PATH="/usr/local/opt/openssl/bin:$PATH"

#For pkg-config to find openssl you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

#qmcpack
export PATH="/Users/uthpala/qmcpack-3.8.0/build/bin/:$PATH"

###Anaconda environment ###########
export PATH="/anaconda2/bin:$PATH"
export PATH="/anaconda3/bin:$PATH"

#DMFTwDFT
export DMFT_ROOT="/Users/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/"
export PYTHONPATH="/Users/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PYTHONPATH"
export PATH="/Users/uthpala/Dropbox/Research/Projects/DMFTwDFT/bin/:$PATH"

#EDMFT
export WIEN_DMFT_ROOT=$HOME/EDMFT/bin/  
export PYTHONPATH=$PYTHONPATH:$WIEN_DMFT_ROOT  
#export WIENROOT=$HOME/wien2k
export SCRATCH="." 
export EDITOR="vim"
export PATH=$WIENROOT:$WIEN_DMFT_ROOT:$PATH 

#texlive
export PATH="/usr/local/texlive/2019/bin/x86_64-darwin/:$PATH"

# pandoc-templates
export PATH="/Users/uthpala/Dropbox/pandoc-templates/:$PATH"

############################################################################################################################


# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
  [ -r "$file" ] && source "$file"
done
unset file

#aliases
alias spruce='ssh -XYC ukh0001@spruce.hpc.wvu.edu'
alias brewup='brew update; brew upgrade; brew prune; brew cleanup; brew doctor'
alias bridges='ssh -XYC uthpala@bridges.psc.xsede.org'
alias stampede='ssh -XYC uthpala@stampede2.tacc.xsede.org'
alias cleantmux='tmux kill-session -a'

killtmux(){
    for arg
    do tmux kill-session -t "macbook-pro $arg"
    done
}


test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"


#llvm
export PATH="/usr/local/opt/llvm/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/llvm/lib/:$LDFLAGS"
export CPPFLAGS="-I/usr/local/opt/llvm/include/:$CPPFLAGS"
export LDFLAGS="-L/usr/local/opt/llvm/lib -Wl,-rpath,/usr/local/opt/llvm/lib/:$LDFLAGS"
