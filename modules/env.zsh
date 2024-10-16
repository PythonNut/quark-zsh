# ===========
# Environment
# ===========

export EDITOR="$ZDOTDIR/bin/editor-dispatch.zsh"
export VISUAL=$EDITOR

export SAGE_STARTUP_FILE=~/.sage/init.sage
export PATH

typeset -TU LD_LIBRARY_PATH ld_library_path
typeset -TU PERL5LIB        perl5lib

typeset -U path
typeset -U manpath
typeset -U fpath 
typeset -U cdpath

path+=(
  $ZPLUG_HOME/repos/zplug/zplug/bin
  $ZPLUG_HOME/bin
  /usr/local/bin
  /sbin
  /usr/sbin
  /usr/local/sbin
  ~/bin
  ~/usr/bin
  ~/.local/bin
  ~/.cargo/bin
)

if [[ $OSTYPE = darwin* ]]; then
  path+=(/Library/TeX/texbin/)
fi

path=( ${(u)^path:A}(N-/) )

# =================
# Terminal handling
# =================

# Indicates terminal does not support colors/decorations/unicode
typeset -A degraded_terminal

degraded_terminal=(
  colors       0
  colors256    0
  decorations  0
  unicode      0
  rprompt      0
  title        0
  display_host 0
)

QUARK_OLD_TERM=$TERM
case $QUARK_OLD_TERM in
  (linux|vt100)
    degraded_terminal[colors256]=1
    degraded_terminal[unicode]=1
    ;;

  (screen)
    # check for lack of 256color support
    if [[ $TTY == /dev/tty*  ]]; then
      export TERM='screen'
    else
      export TERM='screen-256color'
    fi
    ;;

  (tmux)
    # check for lack of 256color support
    if [[ $TTY == /dev/tty*  ]]; then
      export TERM='tmux'
    else
      export TERM='tmux-256color'
    fi
    ;;

  (eterm*)
    degraded_terminal[unicode]=1
    degraded_terminal[title]=1
    ;;

  (xterm-256color|tmux-256color|screen-256color)
    ;;

  (*)
    if [[ -f /usr/share/terminfo/x/xterm-256color ]]; then
      export TERM=xterm-256color
    elif [[ -f /lib/terminfo/x/xterm-256color ]]; then
      export TERM=xterm-256color
    elif [[ -f /usr/share/misc/termcap ]]; then
      if [[ $mapfile[/usr/share/misc/termcap] == *xterm-256color* ]]; then
        export TERM=xterm-256color
      fi
    fi
    ;;
esac

if [[ -n ${MC_TMPDIR+1} ]]; then
  degraded_terminal[rprompt]=1
  degraded_terminal[decorations]=1
  degraded_terminal[title]=1
fi

if [[ -f /proc/$PPID/cmdline ]]; then
  read _ZSH_PARENT_CMDLINE < /proc/$PPID/cmdline
fi

if [[ -f /proc/sys/kernel/osrelease ]]; then
  read _ZSH_OSRELEASE < /proc/sys/kernel/osrelease
fi

# WSL 1
if [[ $_ZSH_OSRELEASE == *Microsoft* && -z $DISPLAY ]]; then
  degraded_terminal[unicode]=1
  setopt nobgnice
fi

# WSL 2
if [[ $_ZSH_OSRELEASE == *microsoft* ]]; then
  degraded_terminal[unicode]=1
fi

if [[ $INSIDE_EMACS == vterm ]]; then
  degraded_terminal[unicode]=1
fi

if [[ -n $TMUX && -n $SSH_CLIENT ]]; then
  degraded_terminal[display_host]=1
elif [[ $_ZSH_PARENT_CMDLINE == (sshd*|*/sshd|mosh-server*) ]]; then
  degraded_terminal[display_host]=1
fi

# Only start tmux if PWD wasn't overridden
if [[ ${PWD:A} == (${${:-~}:A}|/) ]]; then
  # And if the current session is remote
  if [[ $degraded_terminal[display_host] == 1 ]]; then
    # And if tmux is installed, but not currently running
    if (( $+commands[tmux] )) && [[ -z $TMUX ]]; then
      exec tmux new -As0
    fi
  fi
fi

if [[ $LANG != *UTF-8* ]]; then
  degraded_terminal[unicode]=1
fi

colors

