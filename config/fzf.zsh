# Custom copy/adjustment to /usr/share/fzf/key-bindings.zsh.
#
# TODO:
#  - make ignore patterns for `find` configurable?! (to ignore e.g. pyc files)
#    (without having to override FZF_CTRL_T_COMMAND altogether)
#
# Auto-completion
# ---------------
# Prefer version from distro (Arch, more often updated).
if [[ -f /usr/share/zsh/site-functions/_fzf ]]; then
  source /usr/share/zsh/site-functions/_fzf
else
  source ~/.dotfiles/lib/fzf/shell/completion.zsh
fi

# Key bindings
# ------------
if [[ $- == *i* ]]; then

# CTRL-T - Paste the selected file path(s) into the command line
__fsel() {
  local cmd="${FZF_CTRL_T_COMMAND:-"command find -L . \\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune \
    -o -type f -print \
    -o -type d -print \
    -o -type l -print 2> /dev/null | sed 1d | cut -b3-"}"
  setopt localoptions pipefail
  eval "$cmd | $(__fzfcmd) -m $FZF_CTRL_T_OPTS" | while read item; do
    echo -n "${(q)item} "
  done
  local ret=$?
  echo
  return $ret
}

__fzfcmd() {
  [ ${FZF_TMUX:-1} -eq 1 ] && echo "fzf-tmux -d${FZF_TMUX_HEIGHT:-40%}" || echo "fzf"
}

fzf-file-widget() {
  LBUFFER="${LBUFFER}$(__fsel)"
  local ret=$?
  zle redisplay
  return $ret
}
zle     -N   fzf-file-widget
bindkey '^T' fzf-file-widget

fzf-file-widget-with-accept() {
  zle fzf-file-widget
  if [[ "$?" == 0 ]] && (( $#BUFFER )); then
    zle accept-line
  fi
}
zle     -N   fzf-file-widget-with-accept
bindkey '\e^T' fzf-file-widget-with-accept


# ALT-i - insert file/dir from fasd.
fzf-fasd-widget() {
  FZF_CTRL_T_COMMAND='fasd -Rfla' LBUFFER="${LBUFFER}$(__fsel)"
  zle redisplay
}
zle     -N   fzf-fasd-widget
bindkey '\ei' fzf-fasd-widget


# ALT-C - cd into the selected directory
fzf-cd-widget() {
  local cmd="${FZF_ALT_C_COMMAND:-"command find -L . \\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune \
    -o -type d -print 2> /dev/null | sed 1d | cut -b3-"}"
  setopt localoptions pipefail
  cd "${$(eval "$cmd | $(__fzfcmd) +m $FZF_ALT_C_OPTS"):-.}"
  local ret=$?
  zle reset-prompt
  return $ret
}
zle     -N    fzf-cd-widget
bindkey '\ec' fzf-cd-widget

# CTRL-R - Paste the selected command from history into the command line
fzf-history-widget() {
  local selected num
  setopt localoptions noglobsubst pipefail
  selected=( $(fc -l 1 | eval "$(__fzfcmd) +s --tac +m -n2..,.. --tiebreak=index --toggle-sort=ctrl-r $FZF_CTRL_R_OPTS -q ${(q)LBUFFER}") )
  local ret=$?
  if [ -n "$selected" ]; then
    num=$selected[1]
    if [ -n "$num" ]; then
      zle vi-fetch-history -n $num
    fi
  fi
  zle redisplay
  return $ret
}
zle     -N   fzf-history-widget
[[ -n $terminfo[kf3] ]] && bindkey $terminfo[kf3] fzf-history-widget

fi
