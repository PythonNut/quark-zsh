integer quark_title_manual

quark_title_start=
quark_title_finish=

# determine the terminals escapes
case "$QUARK_OLD_TERM" in
  (xterm*)
    quark_title_start='\e]0;'
    quark_title_finish='\a';;
  (aixterm|dtterm|putty|rxvt)
    quark_title_start='\033]0;'
    quark_title_finish='\007';;
  (cygwin)
    quark_title_start='\033];'
    quark_title_finish='\007';;
  (konsole)
    quark_title_start='\033]30;'
    quark_title_finish='\007';;
  (screen*)
    ;;
    # quark_title_start='\033]2;'
    # quark_title_finish='\033\';;
  (*)
    quark_title_start=$terminfo[tsl]
    quark_title_finish=$terminfo[fsl]
esac

# set the title
function quark-set-title() {
  emulate -LR zsh

  if (( $degraded_terminal[title] == 1 )); then
    return 0
  fi

  if [[ -z "${quark_title_start}" ]]; then
    degraded_terminal[title]=1
    return 0
  fi

  print -Pn "${(%)quark_title_start}${(q)*}${(%)quark_title_finish}"
}

# if title set manually, don't set automatically
function settitle() {
  emulate -LR zsh
  quark_title_manual=1
  quark-set-title $1
  if [[ ! -n $1 ]]; then
    quark_title_manual=0
    quark-set-title
  fi
}

function quark-title-extract-command {
  local cur_command host root
  if (( $degraded_terminal[display_host] == 1 )); then
    host="${HOST%%.*} "
  fi

  # strip off environment variables
  1=${1##([^[:ident:]]##=[[:graph:]]#[[:space:]]#)#}

  if [[ $1 == *sudo* ]]; then
    cur_command=\!${${1##[[:space:]]#sudo[[:space:]]#}%%[[:space:]]*}
  elif [[ $1 == [[:space:]]#(noglob|nocorrect|time|builtin|command|exec)* ]]; then
    cur_command=${${1##[[:space:]]#[^[:space:]]#[[:space:]]#}%%[[:space:]]*}
  else
    cur_command=${${1##[[:space:]]#}%%[[:space:]]*}
  fi

  # strip off leading punctuation (like alias escapes)
  cur_command=${cur_command##[[:punct:]]#}

  if (( $UID == 0 )); then
    root=" !"
  fi
  REPLY=${root}${cur_command}
}

function quark-title-sync () {
  if (( $degraded_terminal[title] != 1 && $quark_title_manual == 0 )); then
    local command
    if (( $degraded_terminal[display_host] == 1 )) && [[ ! -n $TMUX ]] ; then
      host="${HOST%%.*} "
    fi
    if [[ -n $1 ]]; then
      quark-title-extract-command $1
      command=$REPLY
    fi
    quark-set-title "${host}${quark_chpwd_minify_full_str#\~/}${quark_chpwd_minify_fasd_str:+→$quark_chpwd_minify_fasd_str}${root}${command:+ ${command}}"
  fi
}

# Since TMUX can show the currently running command
if [[ -z $TMUX ]]; then
  add-zsh-hook preexec quark-title-sync
fi

add-zsh-hook precmd quark-title-sync
quark-title-sync
