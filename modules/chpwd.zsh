function quark-chpwd-smart-worker {
  emulate -LR zsh
  function TRAPTERM {
    kill -INT $$
  }

  local chpwd_minify_full_str="$(quark-minify-path-full $1)"
  local chpwd_minify_smart_str="$(quark-minify-path-smart $chpwd_minify_full_str)"

  typeset -p chpwd_minify_full_str
  typeset -p chpwd_minify_smart_str
}

function quark-chpwd-smart-worker-callback {
  emulate -LR zsh -o prompt_subst -o transient_rprompt
  # Clear the timeout entry
  local -i sched_id
  sched_id=${zsh_scheduled_events[(i)*:*:quark-chpwd-smart-worker-timeout]}
  sched -$sched_id &> /dev/null

  {
    disable -r typeset
    # force variables to go up scope
    function typeset {
      builtin typeset -g "$@"
    }
    eval $3
  } always {
    unset -f typeset 2>/dev/null
    enable -r typeset
  }

  float -g quark_chpwd_smart_duration=$4
  zle && zle reset-prompt
  title_async_compress
}

function quark-chpwd-smart-worker-check {
  async_process_results quark_chpwd_smart_worker quark-chpwd-smart-worker-callback
}

function quark-chpwd-smart-worker-setup {
  async_start_worker quark_chpwd_smart_worker -u
  async_register_callback quark_chpwd_smart_worker quark-chpwd-smart-worker-callback
}

function quark-chpwd-smart-worker-cleanup {
  async_stop_worker quark_chpwd_smart_worker
}

function quark-chpwd-smart-worker-reset {
  quark-chpwd-smart-worker-cleanup
  quark-chpwd-smart-worker-setup
}


function quark-chpwd-smart-worker-timeout {
  echo chpwd smart compressor timed out! >> $ZDOTDIR/startup.log
  quark-chpwd-smart-worker-reset
}

function quark-chpwd-smart-start {
  async_job quark_chpwd_smart_worker quark-chpwd-smart-worker ${${:-.}:A}

  # sched +1 quark-chpwd-smart-worker-check
  # sched +2 quark-chpwd-smart-worker-check
  sched +9 quark-chpwd-smart-worker-check

  sched +10 quark-chpwd-smart-worker-timeout
}

function quark-chpwd-fasd-worker {
  emulate -LR zsh
  function TRAPTERM {
    kill -INT $$
  }

  local chpwd_minify_fasd_str="$(quark-minify-path-fasd $1)"

  typeset -p chpwd_minify_fasd_str
}

function quark-chpwd-fasd-worker-callback {
  emulate -LR zsh -o prompt_subst -o transient_rprompt

  # Clear the timeout entry
  local -i sched_id
  sched_id=${zsh_scheduled_events[(i)*:*:quark-chpwd-fasd-worker-timeout]}
  sched -$sched_id &> /dev/null

  {
    disable -r typeset
    # force variables to go up scope
    function typeset {
      builtin typeset -g "$@"
    }
    eval $3
  } always {
    unset -f typeset 2>/dev/null
    enable -r typeset
  }

  float -g quark_chpwd_fasd_duration=$4
  zle && zle reset-prompt
  title_async_compress
}

function quark-chpwd-fasd-worker-check {
  async_process_results quark_chpwd_fasd_worker quark-chpwd-fasd-worker-callback
}

function quark-chpwd-fasd-worker-setup {
  async_start_worker quark_chpwd_fasd_worker -u
  async_register_callback quark_chpwd_fasd_worker quark-chpwd-fasd-worker-callback
}

function quark-chpwd-fasd-worker-cleanup {
  async_stop_worker quark_chpwd_fasd_worker
}

function quark-chpwd-fasd-worker-reset {
  quark-chpwd-fasd-worker-cleanup
  quark-chpwd-fasd-worker-setup
}

quark-chpwd-fasd-worker-setup

function quark-chpwd-fasd-worker-timeout {
  echo chpwd fasd compressor timed out! >> $ZDOTDIR/startup.log
  quark-chpwd-fasd-worker-reset
}

function quark-chpwd-fasd-start {
  async_job quark_chpwd_fasd_worker quark-chpwd-fasd-worker ${${:-.}:A}

  # sched +1 quark-chpwd-fasd-worker-check
  # sched +2 quark-chpwd-fasd-worker-check
  sched +9 quark-chpwd-fasd-worker-check

  sched +10 quark-chpwd-fasd-worker-timeout
}

function quark-chpwd-async-start {
  emulate -LR zsh -o prompt_subst -o transient_rprompt
  # check if we're running under Midnight Commander
  if (( $degraded_terminal[decorations] == 1 )); then
    chpwd_minify_smart_str=${${:-.}:A:t}
    zle && zle reset-prompt
  else
    chpwd_minify_fasd_str=""
    chpwd_minify_fast_str="$(quark-minify-path .)"
    chpwd_minify_smart_str="$(quark-minify-path-smart $chpwd_minify_fast_str)"
    quark-chpwd-smart-start
    quark-chpwd-fasd-start
  fi
}

quark-chpwd-smart-worker-setup

quark-chpwd-async-start
add-zsh-hook chpwd quark-chpwd-async-start
