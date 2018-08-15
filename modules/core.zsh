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
  local stat_reply
  local -F time_limit=$1
  shift
  (eval $@) &
  # TODO: /proc probably isn't portable
  zstat -A stat_reply '+mtime' /proc/$!

  local PID=$! START_TIME=$SECONDS MTIME=${stat_reply[1]}
  while true; do
    sleep 0.001
    if [[ ! -d /proc/$PID ]]; then
        break
    fi
    zstat -A stat_reply '+mtime' /proc/$PID
    if [[ ${stat_reply[1]} != $MTIME ]]; then
        break
    fi
    if (( $SECONDS - $START_TIME > $time_limit )); then
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

function quark-strlen {
  local string="$@"
  local escape='%{*%}'
  local zero='%([BSUbfksu]|([FB]|){*})'
  local plain=${(S)${(S)string//$~escape/}//$~zero}
  local subbed=${(%%)plain}
  echo $#subbed
}
