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
plugins=(git zsh-autosuggestions copydir dirhistory osx)

## Plugin settings
bindkey '`' autosuggest-accept

# FZF
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source $ZSH/oh-my-zsh.sh

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
complete -W "$(itermocil --list)" itermocil

# Display Python environment
export VIRTUAL_ENV_DISABLE_PROMPT=yes

function virtenv_indicator {
    if [[ -z $CONDA_DEFAULT_ENV ]] then
        psvar[1]=''
    else
        psvar[1]=${CONDA_DEFAULT_ENV##*/}
    fi
}

add-zsh-hook precmd virtenv_indicator

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


umount_all(){
    umount -f /Users/uthpala/HPC/bridges2/home
    umount -f /Users/uthpala/HPC/desktop/home
    umount -f /Users/uthpala/HPC/desktop2/home
    umount -f /Users/uthpala/HPC/spruce/home
    umount -f /Users/uthpala/HPC/stampede2/home
    umount -f /Users/uthpala/HPC/thorny/home
    umount -f /Users/uthpala/HPC/whitehall/home
    umount -f /Users/uthpala/HPC/romeronas/home
}

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

#------------------------------------------- PATHS -------------------------------------------

# projects directory
export PROJECTS="/Volumes/GoogleDrive/My Drive/research/projects/"

# Add Homebrew `/usr/local/bin` and User `~/bin` to the `$PATH`
PATH=/usr/local/bin/:$PATH
PATH=$HOME/bin:$PATH
export PATH="/usr/local/sbin:$PATH"

# System library
export DYLD_LIBRARY_PATH="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/lib/:$DYLD_LIBRARY_PATH"

# Remove .pyc files
export PYTHONDONTWRITEBYTECODE=1

# DMFTwDFT
export PATH="~/Dropbox/git/DMFTwDFT/bin/:$PATH"
export PATH="~/Dropbox/git/DMFTwDFT/scripts/:$PATH"
export PYTHONPATH="~/Dropbox/git/DMFTwDFT/bin/:$PYTHONPATH"

# adding wannier and vasp directories
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
export PATH="/Users/uthpala//VTST/vtstscripts-972/:$PATH"

# xcrysden
export PATH="/Users/uthpala/xcrysden-1.6.2/:$PATH"

#nciplot
export PATH="/Users/uthpala/nciplot/src_nciplot_4.0/:$PATH"
export NCIPLOT_HOME=/Users/uthpala/nciplot/

#------------------------------------------- ALIASES -------------------------------------------


home(){
# logging through ssh.wvu.edu
alias spruce="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@spruce.hpc.wvu.edu'"
alias thorny="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@tf.hpc.wvu.edu'"
alias whitehall="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.76'"
alias whitehall2="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@157.182.3.75'"
alias desktop="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y uthpala@157.182.27.178'"
alias desktop2="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y uthpala@157.182.28.27'"
alias romeronas="ssh -tY ukh0001@ssh.wvu.edu 'ssh -Y ukh0001@romeronas.wvu-ad.wvu.edu'"

# Mounting HPC drives without ssh options
alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
alias mount_spruce="umount ~/HPC/spruce/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@spruce.hpc.wvu.edu: ~/HPC/spruce/home"
alias mount_thorny="umount ~/HPC/thorny/home; sshfs ukh0001@tf.hpc.wvu.edu: ~/HPC/thorny/home/ -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop="umount ~/HPC/desktop/home; sshfs uthpala@157.182.27.178: ~/HPC/desktop/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_desktop2="umount ~/HPC/desktop2/home; sshfs uthpala@157.182.28.27: ~/HPC/desktop2/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_whitehall="umount ~/HPC/whitehall/home; sshfs ukh0001@157.182.3.76: ~/HPC/whitehall/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
alias mount_romeronas="umount ~/HPC/romeronas/home; sshfs ukh0001@romeronas.wvu-ad.wvu.edu: ~/HPC/romeronas/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"

# displayplacer
alias tilt='displayplacer "id:CF4E66DD-D7CF-37EA-2ED6-9978A8FF6618 origin:(0,0)" "id:C2097269-10CA-BCCD-27DB-89E19E08AB82 origin:(-480,-1080)" "id:07A349AF-E29A-3929-480A-9EC29E4735C0 origin:(1440,-1080) degree:90"'
alias untilt='displayplacer "id:CF4E66DD-D7CF-37EA-2ED6-9978A8FF6618 origin:(0,0)" "id:C2097269-10CA-BCCD-27DB-89E19E08AB82 origin:(-758,-1080)" "id:07A349AF-E29A-3929-480A-9EC29E4735C0 origin:(1168,-1080) degree:0"'

# Mounting HPC drives
#alias mount_bridges="umount ~/HPC/bridges/home; sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges.psc.xsede.org:/home/uthpala ~/HPC/bridges/home"
##alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
#alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
##alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
#alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
#alias mount_spruce="umount ~/HPC/spruce/home; sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@spruce.hpc.wvu.edu: ~/HPC/spruce/home"
#alias mount_thorny="umount ~/HPC/thorny/home; sshfs ukh0001@tf.hpc.wvu.edu: ~/HPC/thorny/home/ -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
#alias mount_desktop="umount ~/HPC/thorny/desktop; sshfs uthpala@157.182.27.178: ~/HPC/desktop/home -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
#alias mount_desktop2="umount ~/HPC/desktop2/home; sshfs uthpala@157.182.28.27: ~/HPC/desktop2/home -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
#alias mount_whitehall="umount ~/HPC/whitehall/home; sshfs ukh0001@157.182.3.76: ~/HPC/whitehall/home -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
#alias mount_romeronas="umount ~/HPC/romeronas/home; sshfs ukh0001@romeronas.wvu-ad.wvu.edu: ~/HPC/romeronas/home -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3,allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@ssh.wvu.edu ssh'"
}

work(){
# logging through LAN at work
alias spruce="source ~/.bash_profile; ssh -Y ukh0001@spruce.hpc.wvu.edu"
alias thorny="ssh -tY ukh0001@spruce.hpc.wvu.edu 'ssh -Y ukh0001@tf.hpc.wvu.edu'"
alias whitehall="ssh -Y ukh0001@157.182.3.76"
alias whitehall2="ssh -Y ukh0001@157.182.3.75"
alias desktop="ssh -tY ukh0001@157.182.3.76 'ssh -Y uthpala@157.182.27.178'"
alias desktop2="ssh -tY ukh0001@157.182.3.76 'ssh -Y uthpala@157.182.28.27'"
alias romeronas="ssh -tY ukh0001@157.182.3.76 'ssh -Y ukh0001@romeronas.wvu-ad.wvu.edu'"

# Mounting HPC drives without ssh options from LAN at work
alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
alias mount_spruce="umount ~/HPC/spruce/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@spruce.hpc.wvu.edu: ~/HPC/spruce/home"
alias mount_thorny="umount ~/HPC/thorny/home; sshfs ukh0001@tf.hpc.wvu.edu: ~/HPC/thorny/home/ -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@spruce.hpc.wvu.edu ssh'"
alias mount_desktop="umount ~/HPC/desktop/home; sshfs uthpala@157.182.27.178: ~/HPC/desktop/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@157.182.3.76 ssh'"
alias mount_desktop2="umount ~/HPC/desktop2/home; sshfs uthpala@157.182.28.27: ~/HPC/desktop2/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@157.182.3.76 ssh'"
alias mount_whitehall="umount ~/HPC/whitehall/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@157.182.3.76: ~/HPC/whitehall/home"
alias mount_romeronas="umount ~/HPC/romeronas/home; sshfs ukh0001@romeronas.wvu-ad.wvu.edu: ~/HPC/romeronas/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@157.182.3.76 ssh'"

# displayplacer
alias tilt='displayplacer "id:CF4E66DD-D7CF-37EA-2ED6-9978A8FF6618 res:1440x900 color_depth:4 scaling:on origin:(0,0) degree:0" "id:247A815E-9870-CE8E-7EDC-D015E567AFEE res:1920x1080 hz:60 color_depth:8 scaling:off origin:(-480,-1080) degree:0" "id:0B4ACE63-92C5-E254-1091-1F70FF062540 res:1080x1920 hz:60 color_depth:8 scaling:off origin:(1440,-1202) degree:90"'
alias untilt='displayplacer "id:CF4E66DD-D7CF-37EA-2ED6-9978A8FF6618 res:1440x900 color_depth:4 scaling:on origin:(0,0) degree:0" "id:247A815E-9870-CE8E-7EDC-D015E567AFEE res:1920x1080 hz:60 color_depth:8 scaling:off origin:(-991,-1080) degree:0" "id:0B4ACE63-92C5-E254-1091-1F70FF062540 res:1920x1080 hz:60 color_depth:8 scaling:off origin:(929,-1080) degree:0"'

}

work_wifi(){
# logging through spruce
alias spruce="ssh -Y ukh0001@spruce.hpc.wvu.edu"
alias thorny="ssh -tY ukh0001@spruce.hpc.wvu.edu 'ssh -Y ukh0001@tf.hpc.wvu.edu'"
alias whitehall="ssh -tY ukh0001@spruce.hpc.wvu.edu 'ssh -Y ukh0001@157.182.3.76'"
alias whitehall2="ssh -tY ukh0001@spruce.hpc.wvu.edu 'ssh -Y ukh0001@157.182.3.75'"
alias desktop="ssh -tY ukh0001@spruce.hpc.wvu.edu 'ssh -tY ukh0001@157.182.3.76 'ssh -Y uthpala@157.182.27.178''"
alias desktop2="ssh -tY ukh0001@spruce.hpc.wvu.edu 'ssh -tY ukh0001@157.182.3.76 'ssh -Y uthpala@157.182.28.27''"
alias romeronas="ssh -tY ukh0001@spruce.hpc.wvu.edu 'ssh -tY ukh0001@157.182.3.76 'ssh -Y ukh0001@romeronas.wvu-ad.wvu.edu''"

# Mounting HPC drives without ssh options through spruce
alias mount_bridges2="umount ~/HPC/bridges2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@data.bridges2.psc.edu: ~/HPC/bridges2/home"
alias mount_stampede2="umount ~/HPC/stampede2/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks uthpala@stampede2.tacc.utexas.edu: ~/HPC/stampede2/home"
alias mount_spruce="umount ~/HPC/spruce/home; sshfs -o allow_other,defer_permissions,auto_cache,follow_symlinks ukh0001@spruce.hpc.wvu.edu: ~/HPC/spruce/home"
alias mount_thorny="umount ~/HPC/thorny/home; sshfs ukh0001@tf.hpc.wvu.edu: ~/HPC/thorny/home/ -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@spruce.hpc.wvu.edu ssh'"
alias mount_desktop="umount ~/HPC/desktop/home; sshfs uthpala@157.182.27.178: ~/HPC/desktop/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@spruce.hpc.wvu.edu ssh -t ukh0001@157.182.3.76 ssh'"
alias mount_desktop2="umount ~/HPC/desktop2/home; sshfs uthpala@157.182.28.27: ~/HPC/desktop2/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@spruce.hpc.wvu.edu ssh -t ukh0001@157.182.3.76 ssh'"
alias mount_whitehall="umount ~/HPC/whitehall/home; sshfs ukh0001@157.182.3.76: ~/HPC/whitehall/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@spruce.hpc.wvu.edu ssh'"
alias mount_romeronas="umount ~/HPC/romeronas/home; sshfs ukh0001@romeronas.wvu-ad.wvu.edu: ~/HPC/romeronas/home -o allow_other,defer_permissions,auto_cache,follow_symlinks,ssh_command='ssh -t ukh0001@spruce.hpc.wvu.edu ssh -t ukh0001@157.182.3.76 ssh'"

# displayplacer
alias tilt='displayplacer "id:CF4E66DD-D7CF-37EA-2ED6-9978A8FF6618 res:1440x900 color_depth:4 scaling:on origin:(0,0) degree:0" "id:247A815E-9870-CE8E-7EDC-D015E567AFEE res:1920x1080 hz:60 color_depth:8 scaling:off origin:(-480,-1080) degree:0" "id:0B4ACE63-92C5-E254-1091-1F70FF062540 res:1080x1920 hz:60 color_depth:8 scaling:off origin:(1440,-1202) degree:90"'
alias untilt='displayplacer "id:CF4E66DD-D7CF-37EA-2ED6-9978A8FF6618 res:1440x900 color_depth:4 scaling:on origin:(0,0) degree:0" "id:247A815E-9870-CE8E-7EDC-D015E567AFEE res:1920x1080 hz:60 color_depth:8 scaling:off origin:(-991,-1080) degree:0" "id:0B4ACE63-92C5-E254-1091-1F70FF062540 res:1920x1080 hz:60 color_depth:8 scaling:off origin:(929,-1080) degree:0"'

}

# setting up working environment based on the network SSID
#WORK_ENV=$(/Sy*/L*/Priv*/Apple8*/V*/C*/R*/airport -I | awk '/ SSID:/ {print $2}')
WORK_ENV=$(/Sy*/L*/Priv*/Apple8*/V*/C*/R*/airport -I | awk '/ SSID:/ {print $1="";print $0}' | awk '{ gsub(/ /,""); print }')
if [[ $(hostname | awk -F '-' '{print $1}') == "ip" ]]; then
    work
else
    if [[ $WORK_ENV == "WVU.Encrypted" ]] || [[ $WORK_ENV == "eduroam" ]];  then
        work_wifi
    else
        home
    fi
fi

# mounting all HPC locations
mount_all(){
    mount_spruce;
    mount_thorny;
    mount_whitehall;
    mount_desktop;
    mount_desktop2;
    mount_romeronas;
    mount_bridges2;
}

# Other ssh connections
#alias bridges="ssh -XY  uthpala@bridges.psc.xsede.org"
#alias bridges="ssh -tY  uthpala@bridges.psc.xsede.org 'ssh -Y br005.pvt.bridges.psc.edu'"
#alias stampede2="ssh -XY  uthpala@stampede2.tacc.xsede.org"
alias wvu="ssh -tY ukh0001@ssh.wvu.edu '~/bin/tmux -CC new -A -s main '"
alias sprucetmux="ssh -tY ukh0001@spruce.hpc.wvu.edu 'tmux -CC new -A -s spruce '"
#alias bridges2="ssh -tY  uthpala@bridges2.psc.xsede.org 'ssh -Y uthpala@br011.bridges2.psc.edu'"
alias bridges2="ssh -Y  uthpala@br012.bridges2.psc.edu"
alias stampede2="ssh -Y  uthpala@login1.stampede2.tacc.utexas.edu"
alias cori="ssh -Y train61@cori.nersc.gov"

# git repos
alias cleantmux='tmux kill-session -a'
alias brewup='brew update; brew upgrade; brew cleanup; brew doctor'
alias dotrebase='cd ~/dotfiles && git pull --rebase || true && cd -'
alias dotpush='cd ~/dotfiles && git add . && git commit -m "Update from mac" && git push || true && cd -'
alias dotpull='cd ~/dotfiles && git pull || true && cd -'
alias makeINCAR="cp ~/Dropbox/git/MatSciScripts/INCAR ."
alias makeKPOINTS="cp ~/Dropbox/git/MatSciScripts/KPOINTS ."
alias sed="gsed"

# MPI
export I_MPI_CC="icc"
export I_MPI_CXX="icpc"
export I_MPI_FC="ifort"
export I_MPI_F90="ifort"
export I_MPI_F77="ifort"
