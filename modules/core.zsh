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
