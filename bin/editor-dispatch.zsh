#!/usr/bin/env zsh

if [[ $1 == "--async" ]]; then
  ASYNC=1
  shift
fi

source "${0%/*}/../modules/core.zsh"

if (( $+commands[emacs] )) && [[ -f ~/.emacs.d/README.md ]]; then
  if [[ -n $DISPLAY || $OSTYPE == 'darwin'* ]]; then
    if [[ -n $XDG_RUNTIME_DIR && -e $XDG_RUNTIME_DIR/emacs/server ||
          -z $XDG_RUNTIME_DIR && -e /run/user/$UID/emacs/server ||
          $OSTYPE == 'darwin'* && -e ${TMPDIR}emacs$UID/server ]] ; then
      if [[ -z ${@} ]]; then
        if [[ -z ASYNC || $(emacsclient -e "(frame-parameter (window-frame) 'outer-window-id)") == "nil" ]]; then
          emacsclient -c
        else
          if [[ -f ~/.emacs.d/modules/config-desktop.el ]]; then
            emacsclient -e "(my/activate-emacs)"
          else
            quark-switch-focus-by-name emacs
          fi
        fi
      else
        emacsclient -q -a emacs ${@} &
        if [[ -f ~/.emacs.d/modules/config-desktop.el ]]; then
          emacsclient -e "(my/activate-emacs)"
        else
          quark-switch-focus-by-name emacs
        fi
        if [[ -z $ASYNC ]]; then
           wait
        fi
      fi
    else
      emacs ${@}
    fi
  else
    emacs -nw ${@}
  fi
elif (( $+commands[nvim] )) && [[ -f ~/.config/nvim/README.md ]]; then
  nvim ${@}
elif (( $+commands[gvim] )); then
  gvim -v ${@}
elif (( $+commands[vim] )); then
  vim ${@}
elif (( $+commands[vi] )); then
  vi ${@}
elif (( $+commands[nano] )); then
  nano ${@}
fi
