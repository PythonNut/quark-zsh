# =============================
# AutoFU continuous completions
# =============================
zstyle ':autocomplete:list-choices:*' min-input 3
zstyle ':autocomplete:list-choices:*' max-lines 10
zstyle ':autocomplete:*' magic off
zstyle ':autocomplete:*' fuzzy-search off
zstyle ':autocomplete:tab:*' completion select
zstyle ':autocomplete:' recent-dirs off
zstyle ':autocomplete:' recent-files off
zstyle ':autocomplete:*:no-matches-yet' message '...'
zstyle ':autocomplete:*:no-matches-at-all' message "- no matches -"
zstyle ':autocomplete:*:too-many-matches' message '---'
zstyle ':autocomplete:*' key-binding off


{
  ZSH_AUTOSUGGEST_USE_ASYNC=true
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
  ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=80
  ZSH_AUTOSUGGEST_MANUAL_REBIND=true

  if (( $degraded_terminal[colors256] == 1 )); then
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=black,bold'
  fi

  ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(
    "expand-or-complete"
    "pcomplete"
    "copy-earlier-word"
  )
} &>> $ZDOTDIR/startup.log

function global_bindkey () {
  bindkey -M command $@
  bindkey -M emacs   $@
  bindkey -M main  $@
  bindkey      $@
}

global_bindkey "^Hk" describe-key-briefly
global_bindkey "^[ " autosuggest-accept

functions[.autocomplete.recent-dirs.precmd]=$functions[_autocomplete.no-op]

.autocomplete.key-binding.precmd() {
  emulate -L zsh
  add-zsh-hook -d precmd .autocomplete.key-binding.precmd

  bindkey -M menuselect $key[BackTab] reverse-menu-complete

  zstyle ':completion:*:(alias-expansions|requoted|unambiguous)' format \
         '%F{green}%d: %F{blue}%Bctrl-space%b'
  zstyle ':completion:*:history-lines' format \
         '%F{green}%d: %F{blue}%Bctrl-space%b%F{blue} to insert%f'
}
