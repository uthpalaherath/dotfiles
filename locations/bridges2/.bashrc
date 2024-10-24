# .bashrc for bridges2 (bridges2.psc.xsede.org)
# -Uthpala Herath

#------------------------------------------- INITIALIZATION -------------------------------------------

module purge

#set stty off
 if [[ -t 0 && $- = *i* ]]
 then
   stty -ixon
 fi

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# Source for colorful terminal
source ~/.bash_prompt

# tmux
export PATH="/jet/home/uthpala/local/bin/:$PATH"
export TMUX_DEVICE_NAME=bridges2
if command -v tmux &> /dev/null && [ -t 0 ] && [[ -z $TMUX ]] && [[ $- = *i* ]]; then
	tmux attach -t $TMUX_DEVICE_NAME || tmux new -s $TMUX_DEVICE_NAME
    #tmux
fi

# Memory
ulimit -s unlimited

# Reverse search history
export HISTIGNORE="pwd:ls:cd"

# ENV
NUM_CORES=$SLURM_NTASKS
WORK_DIR=$SLURM_SUBMIT_DIR

#------------------------------------------- ALIASES -------------------------------------------

alias scratch="cd /ocean/projects/phy150003p/uthpala"
alias scratch2="cd /ocean/projects/che240001p/uthpala"
#alias q="squeue -u uthpala"
alias q='squeue -u uthpala --format="%.18i %.9P %30j %.8u %.2t %.10M %.6D %R"'
alias sac="sacct --format="JobID,JobName%30,State,User""
alias interact2="interact -N 1 -t 8:00:00"
#alias interact="interact -N 1 -t 8:00:00 --mem=2GB --ntasks-per-node=64"
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from bridges2" && git push && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'

alias makeINCAR="cp ~/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/MatSciScripts/KPOINTS ."
#alias makejob="cp ~/dotfiles/locations/bridges2/jobscript.sh ."
alias ..="cd .."
alias detach="tmux detach-client -a"
alias cpr="rsync -ah --info=progress2"

#------------------------------------------- MODULES -------------------------------------------

#Intel compilers
module load intel/2021.3.0
module load intelmpi/2021.3.0-intel2021.3.0
source /jet/packages/intel/oneapi/setvars.sh

# module load gcc/10.2.0
# module load intel/20.4
# module load hdf5/1.12.0-intel20.4
module load parallel-netcdf/1.12.1
module load allocations

#------------------------------------------- FUNCTIONS -------------------------------------------

#module load anaconda3/2020.11
module load anaconda3/2020.07
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/packages/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/packages/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/packages/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/packages/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

py2(){
conda deactivate
conda activate py2
# module unload anaconda3/2020.11
# module load anaconda2/2019.10
}
py3(){
conda deactivate
conda activate py3
# module unload anaconda2/2019.10
# module load anaconda3/2020.11
}
#default
py2

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
mkcdr() {
  mkdir -p -v $1
cd $1
}
# Creates an archive from given directory
mktar() { tar cvf  "${1%%/}.tar"     "${1%%/}/"; }
mktgz() { tar cvzf "${1%%/}.tar.gz"  "${1%%/}/"; }
mktbz() { tar cvjf "${1%%/}.tar.bz2" "${1%%/}/"; }

# Clean VASP files in current directoy and subdirectories.
# For only current directory use cleanvasp.sh
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

# Check if VASP relaxation is obtained for batch jobs when relaxed with
# Convergence.py and relax.dat is created.
relaxed (){
 if [ "$*" == "" ]; then
     arg="^[0-9]+$"
 else
     arg=$1
 fi

 rm -f unrelaxed_list.dat
 folder_list=$(ls | grep -E $arg)
 for i in $folder_list;
     do if [ -f $i/relax.dat ] ; then
            echo $i
        else
            printf "$i\t" >> unrelaxed_list.dat
        fi
     done
}

# bridges2
makejob(){
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

jobinfo(){
    scontrol show jobid -dd $1
}

#------------------------------------------- PATHS -------------------------------------------

# cmake
export PATH="/jet/home/uthpala/local/cmake-3.24.0/build/bin/:$PATH"

# aims
export PATH="/jet/home/uthpala/local/FHIaims/bin/:$PATH"

# MatSciScripts
export PATH="/jet/home/uthpala/MatSciScripts/:$PATH"

# dotfiles
export PATH="~/dotfiles/:$PATH"
export PYTHONPATH="/jet/home/uthpala/dotfiles/matplotlib/:$PYTHONPATH"
export MPLCONFIGDIR="/jet/home/uthpala/dotfiles/matplotlib/"



# abinit
export PATH="/jet/home/uthpala/local/abinit/abinit-8.10.3/build/bin/:$PATH"
#export PATH="/jet/home/uthpala/local/abinit/abinit-9.4.1/build/bin/:$PATH"
#export PATH="/jet/home/uthpala/local/abinit/abinit-9.2.2/build/bin/:$PATH"
export PAWLDA="/jet/home/uthpala/local/abinit/pseudo-dojo/paw_pw_standard"
export PAWPBE="/jet/home/uthpala/local/abinit/pseudo-dojo/paw_pbe_standard"

# wannier90
export PATH="/jet/home/uthpala/local/wannier90/wannier90-3.1.0/:$PATH"

# vasp
export PATH="/jet/home/uthpala/local/VASP/vasp.5.4.4/bin/:$PATH"

# # DMFTwDFT_eb
# export PATH="/jet/home/uthpala/projects/DMFTwDFT_eb/bin/:$PATH"
# export PATH="/jet/home/uthpala/projects/DMFTwDFT_eb/scripts/:$PATH"
# export PYTHONPATH="/jet/home/uthpala/projects/DMFTwDFT_eb/bin/:$PYTHONPATH"

# DMFTwDFT
export PATH="/jet/home/uthpala/projects/DMFTwDFT/bin/:$PATH"
export PATH="/jet/home/uthpala/projects/DMFTwDFT/scripts/:$PATH"
export PYTHONPATH="/jet/home/uthpala/projects/DMFTwDFT/bin/:$PYTHONPATH"

# compilers
export CC="mpiicc"
export CXX="mpiicpc"
export FC="mpiifort"
export MPICC="mpiicc"
export MPIFC="mpiifort"

# NEBgen
export PATH="~/local/NEBgen/:$PATH"

# VTST
export PATH="/jet/home/uthpala/local/VTST/vtstscripts-972/:$PATH"

# gsl
export LD_LIBRARY_PATH="/jet/home/uthpala/lib/gsl-2.6/build/lib/:$LD_LIBRARY_PATH"

# tsase
export PYTHONPATH=$HOME/tsase:$PYTHONPATH
export PATH=$HOME/tsase/bin:$PATH
