# ============
# Auto handler
# ============
typeset -a _preAlias

function quark-accept-line() {
  emulate -LR zsh -o prompt_subst -o transient_rprompt -o extended_glob
  local cmd i

  if [[ $BUFFER == "." ]]; then
    BUFFER="exec $SHELL"
    zle .accept-line
  fi

  if [[ $BUFFER == [[:space:]]##* ||  $CONTEXT == "cont" ]]; then
    zle .accept-line
    return 0

  # if buffer is empty, clear instead
  # otherwise pass through
  elif [[ -z $BUFFER ]]; then
    zle clear-screen
    zle-line-init
    return 0
  fi

  # remove black completion "suggestions"
  for i in $region_highlight; do
    if [[ $param == (#b)[^0-9]##(<->)[^0-9]##(<->)(*) ]]; then
      i=("$match")
      if [[ $i[3] == *black* ]] && (($i[2] - $i[1] > 0 && $i[1] > 1)); then
        BUFFER=$BUFFER[1,$i[1]]$BUFFER[$i[2],$(($#BUFFER - 1))]
      fi
    fi
  done

  # expand all aliases on return
  if [[ $#RBUFFER == 0 ]]; then
    quark-expand-alias no_space
  fi
  
  # ignore prefix commands
  if [[ $cmd[1] == (nocorrect|noglob|exec|command|builtin|-) ]]; then
    cmd=($cmd[2,${#cmd}])
  fi

  unset i
  
  # split by command separation delimiters
  cmd=(${(s/;/)BUFFER})
  for token in $cmd; do
    # process the command, strip whitespace
    quark-parser ${=${token##[[:space:]]#}%%[[:space:]]#}
  done

  zle .accept-line
}

zle -N accept-line quark-accept-line
integer command_not_found=1

function quark-parser() {
  emulate -LR zsh -o extended_glob -o null_glob -o ksh_glob
  if [[ $(type -- ${1#\\}) == (*not*) ]]; then
    # skip assignments
    if [[ $1 == (*=*) ]]; then
      return 0
    
    elif [[ -d ${1/(#s)\~/$HOME} ]]; then
      alias "$1"="cd $1"
      _preAlias+=($1)

    # it's a file forward to g
    elif [[ -f "$1" && $(type $1) == (*not*) ]]; then
      if [[ $BUFFER == ([[:space:]]#${=@}[[:space:]]#) ]]; then
        BUFFER="g $@"
      else
        alias $1="g $1" && command_not_found=0
        _preAlias+=("$1")
      fi

    # try to evaluate it as a glob, and list files
    elif [[ $1 == *[\(\)\[\]/*-+%^]* ]]; then
      if [[ -o glob_dots ]]; then
        alias "$1"="unsetopt globdots;LC_COLLATE='C.UTF-8' zargs $1 -- ls --color=always -dhx --group-directories-first;setopt globdots"
      else
        alias "$1"="LC_COLLATE='C.UTF-8' zargs $1 -- ls --color=always -dhx --group-directories-first"
      fi
      if [[ $1 == "**" ]]; then
        # ** renders single level recursive summary
        alias "$1"="LC_COLLATE='C.UTF-8' zargs $1 -- ls --color=always -h"
      fi
      _preAlias+=($1)

    # last resort, forward to teleport handler
    elif [[ -n $(fasd -d -- ${=@} 2> /dev/null) ]]; then
      if [[ $BUFFER == ([[:space:]]#${=@}[[:space:]]#) ]]; then
        BUFFER="g $@"
      else
        alias $1="g $1"
        _preAlias+=($1)
      fi
    else
    fi
  fi
}


function quark-cleanup-prealiases() {
  emulate -LR zsh

  unalias ${(j: :)_preAlias} &> /dev/null
  _preAlias=( )
}

add-zsh-hook preexec quark-cleanup-prealiases

function command_not_found_handler() {
  # only error out if the tokenizer failed
  if [[ $command_not_found == 1 ]]; then
    echo "zsh: command not found:" $1
  fi
  command_not_found=1
}
