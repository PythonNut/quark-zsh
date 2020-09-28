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

function .autocomplete.recent-dirs.precmd() { }

function .autocomplete.key-binding.precmd() {
  emulate -L zsh
  add-zsh-hook -d precmd .autocomplete.key-binding.precmd

  bindkey -M menuselect $key[BackTab] reverse-menu-complete

  zstyle ':completion:*:(alias-expansions|requoted|unambiguous)' format \
         '%F{green}%d: %F{blue}%Bctrl-space%b'
  zstyle ':completion:*:history-lines' format \
         '%F{green}%d: %F{blue}%Bctrl-space%b%F{blue} to insert%f'
}

.autocomplete.config.precmd() {
  emulate -L zsh -o noshortloops -o warncreateglobal -o extendedglob
  add-zsh-hook -d precmd .autocomplete.config.precmd

  zmodload -i zsh/zutil  # `zstyle` builtin

  # Remove incompatible styles.
  zstyle -d ':completion:*' format
  zstyle -d ':completion:*:descriptions' format
  zstyle -d ':completion:*' group-name
  zstyle -d ':completion:*:functions' ignored-patterns
  zstyle -d '*' single-ignored
  zstyle -d ':completion:*' special-dirs

  local -a completers=( _expand _complete:-fuzzy _correct _ignored )
  zstyle ':completion:*' completer _autocomplete.oldlist $completers[@]
  zstyle ':completion:list-expand:*' completer $completers[@]
  zstyle ':completion:expand-word:*' completer _autocomplete.oldlist _autocomplete.extras

  zstyle ':completion:*' prefix-needed false

  zstyle ':completion:*:complete:*' matcher-list 'l:|=**'
  zstyle -e ':completion:*:complete:*' ignored-patterns '
    reply=( "^(${(b)_autocomplete__head}(#i)${(b)_autocomplete__tail}*)" )
    if [[ -z "$_autocomplete__tail" ]]; then
      reply=( "${(b)_autocomplete__head}[^[:alnum:]]*" )
    elif [[ $_autocomplete__punct == . ]]; then
      reply=( "^(${(b)_autocomplete__head}*(#i)${(b)_autocomplete__tail}*)" )
    elif [[ -n "$_autocomplete__punct" && -z "$_autocomplete__alnum" ]]; then
      reply=( "^(${(b)_autocomplete__head}${(b)_autocomplete__punct}[[:alnum:]]*)" )
    fi'

  zstyle ':completion:*:complete-left:*' matcher-list '
    l:|=** m:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}'
  zstyle -e ':completion:*:complete-left:*' ignored-patterns '
    reply=( "${(b)_autocomplete__head}[^[:alnum:]]*" )
    if [[ -n $_autocomplete__punct ]]; then
      reply=( "${(b)_autocomplete__head}([^[:alnum:]]*~${(b)_autocomplete__tail}*)" )
    fi'

  zstyle ':completion:*:complete-fuzzy:*' matcher-list '
    r:|?=** m:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}'

  zstyle ':completion:*:complete(|-*):(-command-|cd|z):*' tag-order '! users' '-'
  zstyle ':completion:*:(approximate|correct):*' tag-order '! original' '-'
  zstyle ':completion:*:expand:*' tag-order '! all-expansions original' '-'

  zstyle ':completion:*:history-words' ignored-patterns ''
  zstyle ':completion:*:recent-(dirs|files)' ignored-patterns ''
  zstyle ':completion:*:(alias-expansions|history-words|requoted|unambiguous)' ignore-line current

  zstyle -e ':completion:*' glob 'reply=( "true" ) && _autocomplete.is_glob || reply=( "false" )'
  zstyle ':completion:*' expand prefix suffix
  zstyle ':completion:*' list-suffixes true
  zstyle ':completion:*' path-completion true

  zstyle ':completion:*' menu 'yes select=long-list'
  zstyle ':completion:expand-word:*' menu ''
  zstyle ':completion:list-choices:*' menu ''

  if zstyle -m ":autocomplete:tab:" completion 'insert'; then
    zstyle ':completion:*:complete(|-*):*' show-ambiguity '07'
  fi

  zstyle ':completion:history-search:*:history-lines' format ''

  if zstyle -t ':autocomplete:' groups 'always'; then
    zstyle ':completion:*:descriptions' format '%F{blue}%d:%f'
    zstyle ':completion:*' group-name ''
  fi

  zstyle ':completion:list-expand:*:descriptions' format '%F{blue}%d:%f'
  zstyle ':completion:list-expand:*' group-name ''

  zstyle ':completion:*:(alias-expansions|history-words|original|requoted|unambiguous)' \
         group-name ''
  zstyle ':completion:*:recent-(dirs|files)' group-name ''

  zstyle ':completion:*' list-dirs-first true
  zstyle ':completion:*:(directories|*-directories|directory-*)' group-name 'directories'
  zstyle ':completion:*' group-order 'history-words directories'

  zstyle ':completion:*:infos' format '%F{yellow}%d%f'
  zstyle ':completion:*:messages' format '%F{red}%d%f'
  zstyle ':completion:*:warnings' format '%F{yellow}%d%f'
  zstyle ':completion:*:errors' format '%F{red}%d%f'

  zstyle ':completion:*' auto-description '%F{yellow}%d%f'

  zstyle ':completion:*' add-space true
  zstyle ':completion:*' list-packed true
  zstyle ':completion:*' list-separator ''
  zstyle ':completion:*' use-cache true

  zstyle ':completion:list-expand:complete:*' matcher-list '
    l:|=** m:{[:lower:][:upper:]-_}={[:upper:][:lower:]_-}' '+r:|?=**'
  zstyle ':completion:list-expand:complete:*' ignored-patterns ''
  zstyle ':completion:list-expand:complete:*:recent-dirs' ignored-patterns '/'
  zstyle ':completion:list-expand:*' extra-verbose true
  zstyle ':completion:list-expand:*' list-separator '-'
  zstyle ':completion:list-expand:*' menu 'yes select'
}
