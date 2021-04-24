# .bashrc for thorny flat (thorny.hpc.wvu.edu)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

# Source global definitions
if [ -f /etc/bashrc ]; then
        . /etc/bashrc
fi

# purge
module purge

# Memory
ulimit -s unlimited

# Source for colorful terminal
source ~/.bash_prompt

# set stty off
if [[ -t 0 && $- = *i* ]]
then
    stty -ixon
fi 

PATH=$PATH:$HOME/.local/bin:$HOME/bin
export PATH

test -e "${HOME}/.iterm2_shell_integration.bash" && source "${HOME}/.iterm2_shell_integration.bash"


# tmux 
module load utils/tmux/3.1 #3.0a
export TMUX_DEVICE_NAME=thorny

# # renumbering sessions
# sessions=$(tmux ls | cut -f1 -d':' | cut -f2 -d ' ' | sort -n)
# new=0
# for old in $sessions
# do
#   tmux rename -t $old "${TMUX_DEVICE_NAME}-${new}"
#   ((new++))
# done

# # kill detached sessions
# tmux list-sessions | grep -E -v '\(attached\)$' | while IFS='\n' read line; do
#     tmux kill-session -t "${line%%:*}"
# done

# Create new tmux or attach to existing session 
if command -v tmux &> /dev/null && [ -t 0  ] && [ -z "$TMUX" ] && [[ $- = *i* ]]; then
    tmux new-session -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME 
fi

# if [ $(hostname | awk -F'.' '{print substr($1,1,5)}') == "trcis" ]; then
#     if command -v tmux &> /dev/null && [ -t 0  ] && [ -z "$TMUX" ] && [[ $- = *i* ]]; then
#         tmux new-session -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME 
#     fi
# fi

#------------------------------------------- MODULES -------------------------------------------

# python
py2(){
#module unload lang/python/intelpython_3.6.9
#module load lang/python/intelpython_2.7.16    
# module load lang/python/pypy2.7-v7.3.2-linux64
module unload lang/python/intelpython3_2020.2
#module unload lang/python/cpython_3.8.6_gcc93
module load lang/python/intelpython2_2019.5
}
py3(){
#module unload lang/python/intelpython_2.7.16
#module load lang/python/intelpython_3.6.9
# module unload lang/python/pypy2.7-v7.3.2-linux64
module unload lang/python/intelpython2_2019.5
#module load lang/python/cpython_3.8.6_gcc93
module load lang/python/intelpython3_2020.2

}
#default
py2

# compilers
module load lang/gcc/8.2.0
module load lang/intel/2018_u4
#module load lang/intel/2019_u5
#module load lang/intel/2018
module load dev/cmake/3.15.4


# libraries
# module load libs/fftw/3.3.8_intel18
# module load libs/hdf5/1.10.5_intel18 
# module load libs/netcdf/4.7.1_intel18
# module load libs/xmlf90/1.5.4_gcc82
# module load libs/libpsml/1.1.7_gcc82

# programs
#module load atomistic/abinit/9.2.2_intel19
#module load atomistic/abinit/8.10.3_intel18
#module load atomistic/elk/5.2.14_intel18
#module load atomistic/abinit/9.4.1_intel19


#module load parallel/openmpi/3.1.4_intel18

#------------------------------------------- PATHS -------------------------------------------

# vasp
export PATH="/users/ukh0001/local/VASP/vasp.5.4.4/bin:$PATH"

# abinit
export ABI_TESTS="/gpfs20/users/ukh0001/local/abinit/tests/"
export ABI_PSPDIR="/users/ukh0001/local/abinit/pseudos/"
export PAW_PBE="/gpfs20/users/ukh0001/local/abinit/pseudo-dojo/paw_pbe_standard"
export PAW_LDA="/gpfs20/users/ukh0001/local/abinit/pseudo-dojo/paw_pw_standard"
export NC_PBEsol="/users/ukh0001/local/abinit/pseudo-dojo/nc-fr-04_pbesol_standard_psp8/"

# dotfiles 
export PATH="/users/ukh0001/dotfiles/:$PATH"

# MatSciScripts
export PATH="/users/ukh0001/MatSciScripts/:$PATH"

# gsl library
export PATH="/usr/include/gsl:$PATH"
export LD_LIBRARY_PATH="/users/ukh0001/local/gsl/lib/:$LD_LIBRARY_PATH"

# libraries
export LD_LIBRARY_PATH="/users/ukh0001/lib/:$LD_LIBRARY_PATH"

# NETCDF libraries
export LD_LIBRARY_PATH="/users/ukh0001/local/netcdf-c-4.7.4/build/lib/:$LD_LIBRARY_PATH"

# DMFTwDFT
export PATH="/users/ukh0001/projects/DMFTwDFT/bin/:$PATH"
export PYTHONPATH="/users/ukh0001/projects/DMFTwDFT/bin/:$PYTHONPATH"
export DMFT_ROOT="/users/ukh0001/projects/DMFTwDFT/bin/"
export PATH="/users/ukh0001/projects/DMFTwDFT/scripts/:$PATH"

# DMFTwDFT_eb
# export PATH="/users/ukh0001/projects/DMFTwDFT_eb/bin/:$PATH"
# export PYTHONPATH="/users/ukh0001/projects/DMFTwDFT_eb/bin/:$PYTHONPATH"
# export DMFT_ROOT="/users/ukh0001/projects/DMFTwDFT_eb/bin/"
# export PATH="/users/ukh0001/projects/DMFTwDFT_eb/scripts/:$PATH"


# siesta
export PATH="/users/ukh0001/local/siesta/siesta-4.1-b4/Obj/:$PATH"
# export PATH="/users/ukh0001/local/siesta/siesta-dmft/Obj/:$PATH"
#export PATH="/users/ukh0001/local/siesta/siesta-dmft-bandwin/Obj/:$PATH"
#export PATH="/users/ukh0001/local/siesta/siesta-dmft-original/Obj/:$PATH"


# local bin
#export PATH=$HOME/.local/bin:$PATH

# wannier90
#export PATH="/users/ukh0001/local/wannier90/wannier90-1.2:$PATH"
#export WANNIER_DIR="/users/ukh0001/local/wannier90/wannier90-1.2/"
export PATH="/users/ukh0001/local/wannier90/wannier90-3.1.0/:$PATH"

# VTST scripts
export PATH="/users/ukh0001/local/VTST/vtstscripts-967/:$PATH"

# gnuplot
export PATH="/users/ukh0001/local/gnuplot-4.6.7/bin/bin/:$PATH"

# NEBgen
export PATH="/users/ukh0001/local/NEBgen/:$PATH"

# MCA parameters for OpenMPI
export OMPI_MCA_btl_openib_warn_no_device_params_found=0
export OMPI_MCA_orte_base_help_aggregate=0
export OMPI_MCA_mpi_show_handle_leaks=0

#------------------------------------------- ALIASES -------------------------------------------

alias q="qstat -u ukh0001"
alias qq="qstat -q"
alias qstatuswatch='watch -d "qstat -u ukh0001"'
alias scratch='cd /scratch/ukh0001'
alias cleantmux='tmux kill-session -a'
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from thorny" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
alias makejob="cp ~/dotfiles/locations/thorny/jobscript.sh ."
alias makeabinit="cp ~/MatSciScripts/{abinit.in,abinit.files} ."
alias detach="tmux detach-client -a"
alias tkill="tmux kill-session"


#------------------------------------------- FUNCTIONS -------------------------------------------

killtmux(){
 for arg
 do tmux kill-session -t "thorny $arg"
 done
}

standby(){
    if [ "$*" == "" ]; then
        arg=1
    else
        arg=$1
    fi
    qsub -I -l nodes=$arg:ppn=40,walltime=4:00:00 -q standby -d $PWD
}

debugger(){
    if [ "$*" == "" ]; then
        arg=1
    else
        arg=$1
    fi
    qsub -I -l nodes=$arg:ppn=40,walltime=1:00:00 -q debug -d $PWD
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





