# Based on the great ys theme (http://ysmood.org/wp/2013/03/my-ys-terminal-theme/)

# Machine name.
function box_name {
    [ -f ~/.box-name ] && cat ~/.box-name || echo $HOST
}

# Directory info.
local current_dir='${PWD/#$HOME/~}'

# VCS
YS_VCS_PROMPT_PREFIX1=" %{$fg_bold[grey]%}on%{$reset_color%} "
YS_VCS_PROMPT_PREFIX2=":%{$fg[cyan]%}"
YS_VCS_PROMPT_SUFFIX="%{$reset_color%}"
YS_VCS_PROMPT_DIRTY=" %{$fg[red]%}✖︎"
YS_VCS_PROMPT_CLEAN=" %{$fg[green]%}•"

# Git info.
local git_info='$(git_prompt_info)'
ZSH_THEME_GIT_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}git${YS_VCS_PROMPT_PREFIX2}"
ZSH_THEME_GIT_PROMPT_SUFFIX="$YS_VCS_PROMPT_SUFFIX"
ZSH_THEME_GIT_PROMPT_DIRTY="$YS_VCS_PROMPT_DIRTY"
ZSH_THEME_GIT_PROMPT_CLEAN="$YS_VCS_PROMPT_CLEAN"

# HG info
local hg_info='$(ys_hg_prompt_info)'
ys_hg_prompt_info() {
	# make sure this is a hg dir
	if [ -d '.hg' ]; then
		echo -n "${YS_VCS_PROMPT_PREFIX1}hg${YS_VCS_PROMPT_PREFIX2}"
		echo -n $(hg branch 2>/dev/null)
		if [ -n "$(hg status 2>/dev/null)" ]; then
			echo -n "$YS_VCS_PROMPT_DIRTY"
		else
			echo -n "$YS_VCS_PROMPT_CLEAN"
		fi
		echo -n "$YS_VCS_PROMPT_SUFFIX"
	fi
}

# Prompt format: \n # USER at MACHINE in DIRECTORY on git:BRANCH STATE [TIME] \n $
PROMPT='
# %{$fg_bold[grey]%}[%{$reset_color%}%{$fg_bold[${host_color}]%}%n@%m%{$reset_color%}%{$fg_bold[grey]%}]%{$reset_color%} %{$fg_bold[blue]%}%10c%{$reset_color%} $(git_prompt_info) $(git_remote_status)
# %{$fg_bold[cyan]%}❯%{$reset_color%} '
PROMPT="
%(1V.(%1v) .)%{$terminfo[bold]$fg[magenta]%}#%{$reset_color%} \
%{$fg[magenta]%}%n \
%{$fg_bold[grey]%}at \
%{$FG[172]%}$(box_name) \
%{$fg_bold[grey]%}in \
%{$terminfo[bold]$fg[green]%}${current_dir}%{$reset_color%}\
${hg_info}\
${git_info} \
%[%*]
%{$terminfo[bold]$fg[white]%}> %{$reset_color%}"

if [[ "$USER" == "root" ]]; then
PROMPT="
%(1V.(%1v) .)%{$terminfo[bold]$fg[magenta]%}#%{$reset_color%} \
%{$bg[yellow]%}%{$fg[cyan]%}%n%{$reset_color%} \
%{$fg_bold[grey]%}at \
%{$FG[172]%}$(box_name) \
%{$fg_bold[grey]%}in \
%{$terminfo[bold]$fg[magenta]%}${current_dir}%{$reset_color%}\
${hg_info}\
${git_info} \
%[%*]
%{$terminfo[bold]$fg[red]%}> %{$reset_color%}"
fi
