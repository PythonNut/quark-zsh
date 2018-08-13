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
