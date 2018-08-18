integer chpwd_title_manual

# set the title
function quark-set-title() {
  emulate -LR zsh

  if (( $degraded_terminal[title] == 1 )); then
    return 0
  fi
  
  local titlestart titlefinish

  # determine the terminals escapes
  case "$QUARK_OLD_TERM" in
    (xterm*)
      titlestart='\e]0;'
      titlefinish='\a';;
    (aixterm|dtterm|putty|rxvt)
      titlestart='\033]0;'
      titlefinish='\007';;
    (cygwin)
      titlestart='\033];'
      titlefinish='\007';;
    (konsole)
      titlestart='\033]30;'
      titlefinish='\007';;
    (screen*)
      titlestart='\033]2;'
      titlefinish='\033\';;
    (*)
      titlestart=$terminfo[tsl]
      titlefinish=$terminfo[fsl]
  esac

  if [[ -z "${titlestart}" ]]; then
    degraded_terminal[title]=1
    return 0
  fi

  print -Pn "${(%)titlestart}${(q)*}${(%)titlefinish}"
}

# if title set manually, dont set automatically
function settitle() {
  emulate -LR zsh
  chpwd_title_manual=1
  quark-set-title $1
  if [[ ! -n $1 ]]; then
    chpwd_title_manual=0
    quark-set-title
  fi
}

function title_async_compress_command () {
  if (( $degraded_terminal[title] != 1 && $chpwd_title_manual == 0 )); then
    local cur_command host="" root=" "
    if [[ -n $TMUX ]]; then
      # Since TMUX can show the currently running command
      return 0
    fi

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

    quark-set-title "${host}${quark_chpwd_minify_full_str}${quark_chpwd_minify_fasd_str:+→$quark_chpwd_minify_fasd_str}${root}${cur_command}"
  fi
}

add-zsh-hook preexec title_async_compress_command

function title_async_compress () {
  if (( $degraded_terminal[title] != 1 && $chpwd_title_manual == 0 )); then
    local host="" root=""

    if (( $degraded_terminal[display_host] == 1 )) && [[ ! -n $TMUX ]] ; then
      host="${HOST%%.*} "
    fi

    if (( $UID == 0 )); then
      root=" !"
    fi
    quark-set-title "${host}${quark_chpwd_minify_full_str}${quark_chpwd_minify_fasd_str:+→$quark_chpwd_minify_fasd_str}${root}"
  fi
}

add-zsh-hook precmd title_async_compress
title_async_compress
