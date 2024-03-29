# ==================
# unified key system
# ==================

autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

git-escape-magic

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

function quark-echotc {
  TERM=$QUARK_OLD_TERM echotc $@ 2> /dev/null
}

function quark-echoti {
  TERM=$QUARK_OLD_TERM echoti $@ 2> /dev/null
}

function quark-protect-state-zle-line-init {
  quark-echoti smkx

  # TODO: This may cause issues on terminals that don't support mouse.
  # In the future we will have to blacklist terminals that don't work.
  printf '\e[?1000l'
}

hooks-add-hook zle_line_init_hook quark-protect-state-zle-line-init

function quark-prepare-state-zle-line-finish {
  quark-echoti rmkx
}

hooks-add-hook zle_line_finish_hook quark-prepare-state-zle-line-finish

QUARK_ZKBD_FILE=${ZDOTDIR:-$HOME}/.zkbd/${QUARK_OLD_TERM}-${VENDOR}-${OSTYPE}

function quark-zshctl-zkbd-init {
  TERM=$QUARK_OLD_TERM zkbd
  echo "Keys generated ... exiting"
  mv ${ZDOTDIR:-$HOME}/.zkbd/${TERM}-:0 $QUARK_ZKBD_FILE
  source $QUARK_ZKBD_FILE
}

typeset -A key

if [[ -s $QUARK_ZKBD_FILE ]]; then
  source $QUARK_ZKBD_FILE
fi

# N.B. These values come from TERM, not QUARK_OLD_TERM
: ${key[Home]:=${terminfo[khome]}}
: ${key[End]:=${terminfo[kend]}}
: ${key[Insert]:=${terminfo[kich1]}}
: ${key[Delete]:=${terminfo[kdch1]}}
: ${key[Up]:=${terminfo[kcuu1]}}
: ${key[Down]:=${terminfo[kcud1]}}
: ${key[PageUp]:=${terminfo[kpp]}}
: ${key[PageDown]:=${terminfo[knp]}}
: ${key[BackTab]:=${terminfo[kcbt]}}

# let the terminal take care of these
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}

[[ -n ${key[Backspace]} ]] && global_bindkey "${key[Backspace]}" backward-delete-char
[[ -n ${key[Insert]}    ]] && global_bindkey "${key[Insert]}"    overwrite-mode
[[ -n ${key[Home]}      ]] && global_bindkey "${key[Home]}"      beginning-of-line
[[ -n ${key[PageUp]}    ]] && global_bindkey "${key[PageUp]}"    up-line-or-history
[[ -n ${key[Delete]}    ]] && global_bindkey "${key[Delete]}"    delete-char
[[ -n ${key[End]}       ]] && global_bindkey "${key[End]}"       end-of-line
[[ -n ${key[PageDown]}  ]] && global_bindkey "${key[PageDown]}"  down-line-or-history
[[ -n ${key[Up]}        ]] && global_bindkey "${key[Up]}"        up-line-or-search
[[ -n ${key[Down]}      ]] && global_bindkey "${key[Down]}"      down-line-or-search

# Weird M-arrow and C-arrow codes
bindkey "^[[1;3C" forward-word
bindkey "^[[1;3D" backward-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

quark_osc133_prompt_executing=''

function quark-osc133-prompt-precmd() {
  local ret="$?"
  if [[ $quark_osc133_prompt_executing != 0 ]]; then
    _PROMPT_SAVE_PS1="$PS1"
      _PROMPT_SAVE_PS2="$PS2"
      PS1=$'%{\e]133;P;k=i\a%}'$PS1$'%{\e]133;B\a\e]122;> \a%}'
      PS2=$'%{\e]133;P;k=s\a%}'$PS2$'%{\e]133;B\a%}'
  fi
  if [[ -n quark_osc133_prompt_executing ]]; then
    printf "\033]133;D;%s;aid=%s\007" "$ret" "$$"
  fi
  printf "\033]133;A;cl=m;aid=%s\007" "$$"
  quark_osc133_prompt_executing=0
}

function quark-osc133-prompt-preexec {
  PS1="$_PROMPT_SAVE_PS1"
  PS2="$_PROMPT_SAVE_PS2"
  printf "\033]133;C;\007"
  quark_osc133_prompt_executing=1
}


function quark-osc7-chpwd {
  printf '\e]7;file://%s%s\e\\' "$HOSTNAME" "$(_urlencode "$PWD")"
}

if [[ $TERM_PROGRAM == "WezTerm" ]]; then
  add-zsh-hook preexec quark-osc133-prompt-preexec
  add-zsh-hook precmd quark-osc133-prompt-precmd
  add-zsh-hook chpwd quark-osc7-chpwd
fi
