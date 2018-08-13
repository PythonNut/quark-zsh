typeset -F SECONDS

function quark-error {
  echo error: $@ >> $ZDOTDIR/startup.log
}

function quark-with-protected-return-code {
  local return=$?
  "$@"
  return $return
}

function quark-sched-remove {
  local sched_id
  while true; do
    sched_id=${zsh_scheduled_events[(I)*:*:$1]}
    (( $sched_id )) || break
    sched -$sched_id &> /dev/null
  done
}

function quark-eval-overriding-globals {
  {
    disable -r typeset
    # force variables to go up scope
    function typeset {
      builtin typeset -g "$@"
    }
    eval $@
  } always {
    unset -f typeset 2>/dev/null
    enable -r typeset
  }
}

function quark-with-timeout {
  emulate -LR zsh -o no_monitor
  (eval $2) &
  local PID=$! START_TIME=$SECONDS MTIME=$(zstat '+mtime' /proc/$!)
  while true; do
    sleep 0.001
    # TODO: This probably isn't portable
    if [[ ! -d /proc/$PID || $(zstat '+mtime' /proc/$PID) != $MTIME ]]; then
        break
    fi
    if (( $SECONDS - $START_TIME > $1 )); then
        {
          kill $PID
          wait $PID
        } 2> /dev/null
        break
    fi
  done
}

function quark-return {
  local USE_REPLY=$1
  shift
  if [[ -n $USE_REPLY ]]; then
      REPLY="$@"
  else
      echo $@
  fi
}

quark-strlen () {
  local string="$@"
  local escape='%{*%}'
  local zero='%([BSUbfksu]|([FB]|){*})'
  local plain=${(S)${(S)string//$~escape/}//$~zero}
  local subbed=${(%%)plain}
  echo $#subbed
}
