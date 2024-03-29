# =================================
# FASD - all kinds of teleportation
# =================================

export _FASD_DATA=$ZDOTDIR/data/.fasd
export _FASD_SHIFT=(nocorrect noglob sudo busybox)
export _FASD_FUZZY=100
export _FASD_VIMINFO=~/.vim/.viminfo

function () {
  emulate -LR zsh -o equals
  local fasd_cache="$ZDOTDIR/fasd-init-cache"
  if [[ ! -s "$fasd_cache" ]]; then
    fasd --init zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp zsh-wcomp-install >| "$fasd_cache"
  fi

  source "$fasd_cache"
  source =fasd
  function _fasd_preexec() {
    (
        {
          { eval "fasd --proc $(fasd --sanitize $2)"; } >> "/dev/null" 2>&1
        } &!
    )
  }
}

_mydirstack() {
  local -a lines list
  for d in $dirstack; do
    lines+="$(($#lines+1)) -- $d"
    list+="$#lines"
  done
  _wanted -V directory-stack expl 'directory stack' \
          compadd "$@" -ld lines -S']/' -Q -a list
}

zsh_directory_name() {
  case $1 in
    (c) _mydirstack;;
    (n) case $2 in
          (<0-9>) reply=($dirstack[$2]);;
          (*) reply=($dirstack[(r)*$2*]);;
        esac;;
    (d) false;;
  esac
}
