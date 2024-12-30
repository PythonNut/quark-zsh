# ========================
# smart tab - really smart
# ========================

function pcomplete() {
  emulate -L zsh
  setopt function_argzero prompt_subst extended_glob
  setopt list_packed list_rows_first

  local -a show_completer
  local -a extra_verbose
  local -a verbose
  local -a completer
  local -a menu

  zstyle -a ':completion:*' show-completer show_completer
  zstyle -a ':completion:*' extra-verbose extra_verbose
  zstyle -a ':completion:*' verbose verbose
  zstyle -a ':completion:*' completer completer
  zstyle -a ':completion:*' menu menu

  setopt auto_list              # list if multiple matches
  setopt complete_in_word       # complete at cursor
  setopt menu_complete          # add first of multiple
  setopt auto_remove_slash      # remove extra slashes if needed
  setopt auto_param_slash       # completed directory ends in /
  setopt auto_param_keys        # smart insert spaces " "

  zstyle ':completion:*' show-completer true
  zstyle ':completion:*' extra-verbose true
  zstyle ':completion:*' verbose true
  zstyle ':completion:*' menu select interactive
  zstyle ':completion:*' completer \
    _oldlist \
    _expand \
    _complete \
    _match \
    _prefix

  local TMP_RBUFFER=$RBUFFER
  zle menu-expand-or-complete
  RBUFFER=$TMP_RBUFFER

  if [[ "$LBUFFER" = *' ' ]]; then
    zle .backward-delete-char
  fi

  zstyle ':completion:*' show-completer $show_completer
  zstyle ':completion:*' extra-verbose $extra_verbose
  zstyle ':completion:*' verbose $verbose
  zstyle ':completion:*' completer $completer
  zstyle ':completion:*' menu $menu

}

bindkey -M menuselect . self-insert

zle -N pcomplete

global_bindkey '^i' pcomplete
bindkey -M menuselect '^i' forward-char
bindkey -M menuselect '^[[Z' backward-char

function _magic-space () {
  emulate -LR zsh
  if [[ $LBUFFER[-1] != " "  ]]; then
    zle .magic-space
    if [[ $LBUFFER[-2] == " " ]]; then
      zle backward-delete-char
    fi
  else
    zle .magic-space
  fi
}

zle -N magic-space _magic-space
