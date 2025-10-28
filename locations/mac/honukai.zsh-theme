# Based on the great ys theme (http://ysmood.org/wp/2013/03/my-ys-terminal-theme/)
# Modified by Uthpala Herath
# -----------------------
setopt prompt_subst

function box_name {
  [ -f ~/.box-name ] && cat ~/.box-name || echo $HOST
}

# 256-color mappings
MAGENTA="%F{125}"
ORANGE="%F{166}"
GREEN="%F{64}"
RED="%F{160}"
PURPLE="%F{61}"
WHITE="%F{244}"
RESET="%f%k"

# VCS decorations
YS_VCS_PROMPT_PREFIX1=" %{$WHITE%}on%{$RESET%} "
YS_VCS_PROMPT_PREFIX2=":%{$ORANGE%}"
YS_VCS_PROMPT_SUFFIX="%{$RESET%}"
YS_VCS_PROMPT_DIRTY=" %{$RED%}✖︎%{$RESET%}"
YS_VCS_PROMPT_CLEAN=" %{$GREEN%}●%{$RESET%}"

ZSH_THEME_GIT_PROMPT_PREFIX="${YS_VCS_PROMPT_PREFIX1}git${YS_VCS_PROMPT_PREFIX2}%{$PURPLE%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="${YS_VCS_PROMPT_SUFFIX}%{$RESET%}"
ZSH_THEME_GIT_PROMPT_DIRTY="${YS_VCS_PROMPT_DIRTY}"
ZSH_THEME_GIT_PROMPT_CLEAN="${YS_VCS_PROMPT_CLEAN}"

ys_hg_prompt_info() {
  if [ -d '.hg' ]; then
    echo -n "${YS_VCS_PROMPT_PREFIX1}hg${YS_VCS_PROMPT_PREFIX2}"
    echo -n "$(hg branch 2>/dev/null)"
    if [ -n "$(hg status 2>/dev/null)" ]; then
      echo -n "$YS_VCS_PROMPT_DIRTY"
    else
      echo -n "$YS_VCS_PROMPT_CLEAN"
    fi
    echo -n "$YS_VCS_PROMPT_SUFFIX"
  fi
}

precmd() { print }

# Main prompt
PROMPT=$'%{$MAGENTA%}%n %{$WHITE%}at %{$ORANGE%}$(box_name) %{$WHITE%}in %{$GREEN%}%~%{$RESET%}${$(ys_hg_prompt_info)}${$(git_prompt_info)}\n%{$WHITE%}$ %{$RESET%}'

# Root variant
if [[ "$USER" == "root" ]]; then
  PROMPT=$'%{$MAGENTA%}#%{$RESET%} %{$ORANGE%}%n%{$RESET%} %{$WHITE%}at %{$ORANGE%}$(box_name) %{$WHITE%}in %{$GREEN%}%~%{$RESET%}${$(ys_hg_prompt_info)}${$(git_prompt_info)}\n%{$WHITE%}→ %{$RESET%}'
fi
