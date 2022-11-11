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
plugins=(git zsh-autosuggestions) # copydir dirhistory macos)

## Plugin settings

# zsh-autosuggestions
bindkey '`' autosuggest-accept
CASE_SENSITIVE="true"
HYPHEN_INSENSITIVE="true"

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source $ZSH/oh-my-zsh.sh
add-zsh-hook precmd virtenv_indicator

# Memory
ulimit -s hard

# Sourcing intel oneAPI system
source /opt/intel/oneapi/setvars.sh  > /dev/null

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,exports,aliases,functions,extra}; do
  [[ -r "$file" ]] && source "$file"
done
unset file

# PYTHON
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/intel/oneapi/intelpython/latest/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/intel/oneapi/intelpython/latest/etc/profile.d/conda.sh" ]; then
        . "/opt/intel/oneapi/intelpython/latest/etc/profile.d/conda.sh"
    else
        export PATH="/opt/intel/oneapi/intelpython/latest/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# conda environment
py2(){
    conda deactivate
    conda activate py2
}
py3(){
    conda deactivate
    conda activate py3
}
#default
py3

# itermocil
# complete -W "$(itermocil --list)" itermocil

# Display Python environment
export VIRTUAL_ENV_DISABLE_PROMPT=yes

function virtenv_indicator {
    if [[ -z $CONDA_DEFAULT_ENV ]] then
        psvar[1]=''
    else
        psvar[1]=${CONDA_DEFAULT_ENV##*/}
    fi
}

# tmux
export TMUX_DEVICE_NAME=MBP
tm(){
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
 tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
fi
}


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
# Creates directory then moves into it
mkcdr() {
  mkdir -p -v $1
cd $1
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
    umount -f /Users/uthpala/HPC/timewarp/home
}

# Check if VASP relaxation is obtained for batch jobs when relaxed with
# Convergence.py and relax.dat is created.
relaxed(){
 if [[ "$*" == "" ]]; then
     arg="^[0-9]+$"
 else
     arg=$1
 fi

 rm -f unrelaxed_list.dat
 folder_list=$(ls | grep -E $arg)
 for i in $folder_list;
     do if [[ -f "${i}/relax.dat" ]]; then
            echo $i
        else
            printf "${i}\t" >> unrelaxed_list.dat
        fi
     done
}

# Clean VASP files in current directoy and subdirectories.
# For only current directory use cleanvasp.sh
# Add -delete flag to delete.
cleanvaspall(){
    find . \( \
        -name "CHGCAR*" -o \
        -name "OUTCAR*" -o \
        -name "CHG" -o \
        -name "DOSCAR" -o \
        -name "EIGENVAL" -o \
        -name "ENERGY" -o \
        -name "IBZKPT" -o \
        -name "OSZICAR*" -o \
        -name "PCDAT" -o \
        -name "REPORT" -o \
        -name "TIMEINFO" -o \
        -name "WAVECAR" -o \
        -name "XDATCAR" -o \
        -name "wannier90.wout" -o \
        -name "wannier90.amn" -o \
        -name "wannier90.mmn" -o \
        -name "wannier90.eig" -o \
        -name "wannier90.chk" -o \
        -name "wannier90.node*" -o \
        -name "PROCAR" -o \
        -name "*.o[0-9]*" -o \
        -name "vasprun.xml" -o \
        -name "relax.dat" -o \
        -name "CONTCAR*" \
    \) -type f $1
}

# Compiler setting
intel(){
# OpenMPI (compiled with intel)
export PATH="/Users/uthpala/lib/openmpi-4.1.4/bin/:$PATH"
export DYLD_LIBRARY_PATH="/Users/uthpala/lib/openmpi-4.1.4/lib/:$DYLD_LIBRARY_PATH"
export OMPI_CC="icc"
export OMPI_CXX="icpc"
export OMPI_FC="ifort"
}

gnu(){
# OpenMPI (GNU)
export PATH="/Users/uthpala/lib/openmpi-4.1.4-gnu/bin/:$PATH"
export DYLD_LIBRARY_PATH="/Users/uthpala/lib/openmpi-4.1.4-gnu/lib/:$DYLD_LIBRARY_PATH"
export OMPI_CC="gcc-11"
export OMPI_CXX="g++-11"
export OMPI_FC="gfortran-11"
}
# default
intel

export CC="mpicc"
export CXX="mpicxx"
export FC="mpif90"

#---------- Create jobscripts for HPC ------------

# spruce
makejob_spruce(){
queue=${1:-standby}
nodes=${2:-1}
ppn=${3:-16}
jobname=${4:-jobname}

case $queue in
  standby) walltime=4:00:00 ;;
  alromero) walltime=1000:00:00 ;;
  comm_mmem_day) walltime=24:00:00 ;;
  comm_mmem_week) walltime=168:00:00 ;;
  debug) walltime=00:15:00 ;;
  *) walltime=4:00:00 ;;
esac

echo "\
#!/bin/bash
#PBS -N $jobname
#PBS -q $queue
#PBS -l walltime=$walltime
#PBS -l nodes=$nodes:ppn=$ppn #,pvmem=6gb
#PBS -m ae
#PBS -M ukh0001@mix.wvu.edu
#PBS -j oe

source ~/.bashrc
ulimit -s unlimited

cd \$WORK_DIR/
" > jobscript.sh
}

# thorny
makejob_thorny(){
 queue=${1:-standby}
 nodes=${2:-1}
 ppn=${3:-40}
 jobname=${4:-jobname}

 case $queue in
     standby) walltime=4:00:00 ;;
     alromero) walltime=1000:00:00 ;;
     comm_small_day) walltime=24:00:00 ;;
     comm_small_week) walltime=168:00:00 ;;
     debug) walltime=1:00:00 ;;
     *) walltime=4:00:00 ;;
 esac

echo "\
#!/bin/bash
#PBS -N $jobname
#PBS -q $queue
#PBS -l walltime=$walltime
#PBS -l nodes=$nodes:ppn=$ppn #,pvmem=8gb
#PBS -m ae
#PBS -M ukh0001@mix.wvu.edu
#PBS -j oe

source ~/.bashrc
ulimit -s unlimited

cd \$WORK_DIR/
" > jobscript.sh
}

# bridges2
makejob_bridges2(){
 nodes=${1:-1}
 ppn=${2:-128}
 jobname=${3:-jobname}

echo "\
#!/bin/bash
#SBATCH --job-name=$jobname
#SBATCH -N $nodes
#SBATCH --ntasks-per-node=$ppn
#SBATCH -t 48:00:00
##SBATCH --mem=10GB
##SBATCH -p RM-shared

set -x
source ~/.bashrc
ulimit -s unlimited

cd \$WORK_DIR/
" > jobscript.sh
}

# selector
makejob(){
    case $1 in
        spruce) makejob_spruce $2 $3 $4 $5 ;;
        thorny) makejob_thorny $2 $3 $4 $5 ;;
        bridges2) makejob_bridges2 $2 $3 $4 ;;
        *) makejob_thorny $2 $3 $4 $5 ;;
    esac
}

#------------------------------------------- PATHS -------------------------------------------

# Matplotlib
export PYTHONPATH="/Users/uthpala/Dropbox/git/dotfiles/matplotlib/:$PYTHONPATH"
export MPLCONFIGDIR="/Users/uthpala/Dropbox/git/dotfiles/matplotlib/"

# projects directory
export PROJECTS="/Volumes/GoogleDrive/My Drive/research/projects/"

# Add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
PATH=/usr/local/bin/:$PATH
PATH=$HOME/bin:$PATH
export PATH="/usr/local/sbin:$PATH"

# System library
export DYLD_LIBRARY_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/:$DYLD_LIBRARY_PATH"

# Libraries
export DYLD_LIBRARY_PATH="/Users/uthpala/lib/:$DYLD_LIBRARY_PATH"

# GSL
export DYLD_LIBRARY_PATH="/usr/local/Cellar/gsl/2.7.1/lib/:$DYLD_LIBRARY_PATH$"

# Scalapack
#export DYLD_LIBRARY_PATH="/usr/local/Cellar/scalapack/2.1.0_3/lib/:$DYLD_LIBRARY_PATH"
export DYLD_LIBRARY_PATH="/Users/uthpala/lib/scalapack-2.2.0/:$DYLD_LIBRARY_PATH"

# Remove .pyc files
export PYTHONDONTWRITEBYTECODE=1

# DMFTwDFT
export PATH="/Users/uthpala/Dropbox/git/DMFTwDFT/bin/:$PATH"
export PATH="/Users/uthpala/Dropbox/git/DMFTwDFT/scripts/:$PATH"
export PYTHONPATH="/Users/uthpala/Dropbox/git/DMFTwDFT/bin/:$PYTHONPATH"

# adding wannier and vasp directories
export DYLD_LIBRARY_PATH="/Users/uthpala/wannier90/wannier90-3.1.0/:$DYLD_LIBRARY_PATH"
export PATH="/Users/uthpala/wannier90/wannier90-3.1.0/:$PATH"
export PATH="/Users/uthpala/VASP/vasp.5.4.4/bin/:$PATH"
#export PATH="/Users/uthpala/VASP/vasp.6.2.1/bin/:$PATH"

# Siesta
export PATH="/Users/uthpala/siesta/siesta-4.1-b3/Obj/:$PATH"

# nbopen
export PATH="/Users/uthpala/nbopen/nbopen/:$PATH"

# p4vasp
export PATH="/Users/uthpala/p4vasp/bin/:$PATH"

# dotfiles
export PATH="/Users/uthpala/dotfiles/:$PATH"

# MatSciScripts
export PATH="/Users/uthpala/Dropbox/git/MatSciScripts/:$PATH"

# sod
export PATH="/Users/uthpala/sod/bin/:$PATH"

# openssl
export LDFLAGS="-L/usr/local/opt/openssl/lib"
export CPPFLAGS="-I/usr/local/opt/openssl/include"
export PATH="/usr/local/opt/openssl/bin:$PATH"

# For pkg-config to find openssl you may need to set:
export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"

# texlive
export PATH="/usr/local/texlive/2021/bin/universal-darwin/:$PATH"

# pandoc-templates
export PATH="/Users/uthpala/Dropbox/git/pandoc-templates/scripts/:$PATH"

# Perl warning fix
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Julia
export PATH="/Applications/Julia-1.5.app/Contents/Resources/julia/bin/:$PATH"

# Lobster
export PATH="/Users/uthpala/lobster-4.1.0/OSX/:$PATH"

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
export NC_PBEsol="/Users/uthpala/abinit/pseudo-dojo/nc-fr-04_pbesol_standard_psp8/"
export PAWPBE="/Users/uthpala/abinit/pseudo-dojo/paw_pbe_standard/"
export PAWLDA="/Users/uthpala/abinit/pseudo-dojo/paw_pw_standard/"

# NEBgen
export PATH="/Users/uthpala/Dropbox/git/NEBgen/:$PATH"

# VTST
export PATH="/Users/uthpala/VTST/vtstscripts-978/:$PATH"

# xcrysden
export PATH="/Users/uthpala/xcrysden-1.6.2/:$PATH"

#nciplot
export PATH="/Users/uthpala/nciplot/src_nciplot_4.0/:$PATH"
export NCIPLOT_HOME=/Users/uthpala/nciplot/

# rsync
export PATH="/usr/local/Cellar/rsync/3.2.3/bin/:$PATH"

# tsase
export PYTHONPATH=$HOME/tsase:$PYTHONPATH
export PATH=$HOME/tsase/bin:$PATH

# FHI-aims
export PATH="/Users/uthpala/FHIaims_intel/bin/:$PATH"
export PATH="/Users/uthpala/FHIaims_intel/utilities/:$PATH"

# nodejs
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

#------------------------------------------- ALIASES -------------------------------------------

# WVU Connections
# logging through ssh.wvu.edu

alias spruce="ssh -Y ukh0001@spruce.hpc.wvu.edu"
alias thorny="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@tf.hpc.wvu.edu'"
alias whitehall="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.76'"
alias whitehall2="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.75'"
alias whitehall3="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.77'"
alias desktop="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y uthpala@157.182.27.178'"
alias desktop2="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y uthpala@157.182.28.27'"
alias romeronas="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@romeronas.wvu-ad.wvu.edu'"

# Mounting HPC drives without ssh options
alias mount_spruce="umount ~/HPC/spruce/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@spruce.hpc.wvu.edu: ~/HPC/spruce/home"
alias mount_thorny="umount ~/HPC/thorny/home; sshfs ukh0001@tf.hpc.wvu.edu: ~/HPC/thorny/home/ -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop="umount ~/HPC/desktop/home; sshfs uthpala@157.182.27.178: ~/HPC/desktop/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop2="umount ~/HPC/desktop2/home; sshfs uthpala@157.182.28.27: ~/HPC/desktop2/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_whitehall="umount ~/HPC/whitehall/home; sshfs ukh0001@157.182.3.76: ~/HPC/whitehall/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_romeronas="umount ~/HPC/romeronas/home; sshfs ukh0001@romeronas.wvu-ad.wvu.edu: ~/HPC/romeronas/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"

# Other ssh connections
alias wvu="ssh -tY ukh0001@ssh.wvu.edu '~/bin/tmux -CC new -A -s main '"
alias sprucetmux="ssh -tY ukh0001@spruce.hpc.wvu.edu 'tmux -CC new -A -s spruce '"
alias bridges2="ssh -Y uthpala@br012.bridges2.psc.edu"
alias stampede2="ssh -Y uthpala@login1.stampede2.tacc.utexas.edu"
alias cori="ssh -Y uthpala@cori.nersc.gov"
alias timewarp='ssh -Y ukh@timewarp.egr.duke.edu'
alias perlmutter="ssh -Y uthpala@perlmutter-p1.nersc.gov"

# Mounting drives
alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
alias mount_timewarp="umount ~/HPC/timewarp/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh@timewarp.egr.duke.edu: ~/HPC/timewarp/home"
alias mount_perlmutter="umount ~/HPC/perlmutter/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@perlmutter-p1.nersc.gov: ~/HPC/perlmutter/home"

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
