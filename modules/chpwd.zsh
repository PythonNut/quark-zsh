function quark-chpwd-smart-async-worker {
  emulate -LR zsh
  TRAPTERM () {
    kill -INT $$
  }

  local chpwd_minify_full_str="$(quark-minify-path-full $1)"
  local chpwd_minify_smart_str="$(quark-minify-path-smart $chpwd_minify_full_str)"

  typeset -p chpwd_minify_full_str
  typeset -p chpwd_minify_smart_str
}

function quark-chpwd-smart-callback {
  emulate -LR zsh -o prompt_subst -o transient_rprompt
  # Clear the timeout entry
  local -i sched_id
  sched_id=${zsh_scheduled_events[(i)*:*:quark-prompt-async-smart-timeout]}
  sched -$sched_id &> /dev/null

  {
    disable -r typeset
    # force variables to go up scope
    typeset() { builtin typeset -g "$@"; }
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
  async_process_results quark_chpwd_smart_worker quark-chpwd-smart-callback
}

function quark-chpwd-smart-worker-setup {
  async_start_worker quark_chpwd_smart_worker -u
  async_register_callback quark_chpwd_smart_worker quark-chpwd-smart-callback
}

function quark-chpwd-smart-worker-cleanup {
  async_stop_worker quark_chpwd_smart_worker
}

function quark-chpwd-smart-worker-reset {
  quark-chpwd-smart-worker-cleanup
  quark-chpwd-smart-worker-setup
}


function quark-prompt-async-smart-timeout {
  echo chpwd smart compressor timed out! >> $ZDOTDIR/startup.log
  quark-chpwd-smart-worker-reset
}

function quark-prompt-async-start-smart {
  async_job quark_chpwd_smart_worker quark-chpwd-smart-async-worker ${${:-.}:A}

  # sched +1 quark-chpwd-smart-worker-check
  # sched +2 quark-chpwd-smart-worker-check
  # sched +9 quark-chpwd-smart-worker-check

  sched +10 quark-prompt-async-smart-timeout
}


function quark-chpwd-fasd-async-worker {
  emulate -LR zsh
  TRAPTERM () {
    kill -INT $$
  }

  local chpwd_minify_fasd_str="$(quark-minify-path-fasd $1)"

  typeset -p chpwd_minify_fasd_str
}

function quark-chpwd-fasd-callback {
  emulate -LR zsh -o prompt_subst -o transient_rprompt

  # Clear the timeout entry
  local -i sched_id
  sched_id=${zsh_scheduled_events[(i)*:*:quark-prompt-async-fasd-timeout]}
  sched -$sched_id &> /dev/null

  {
    disable -r typeset
    # force variables to go up scope
    typeset() { builtin typeset -g "$@"; }
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
  async_process_results quark_chpwd_fasd_worker quark-chpwd-fasd-callback
}

function quark-chpwd-fasd-worker-setup {
  async_start_worker quark_chpwd_fasd_worker -u
  async_register_callback quark_chpwd_fasd_worker quark-chpwd-fasd-callback
}

function quark-chpwd-fasd-worker-cleanup {
  async_stop_worker quark_chpwd_fasd_worker
}

function quark-chpwd-fasd-worker-reset {
  quark-chpwd-fasd-worker-cleanup
  quark-chpwd-fasd-worker-setup
}

quark-chpwd-fasd-worker-setup

function quark-prompt-async-fasd-timeout {
  echo chpwd fasd compressor timed out! >> $ZDOTDIR/startup.log
  quark-chpwd-fasd-worker-reset
}

function quark-prompt-async-start-fasd {
  async_job quark_chpwd_fasd_worker quark-chpwd-fasd-async-worker ${${:-.}:A}

  # sched +1 quark-chpwd-fasd-worker-check
  # sched +2 quark-chpwd-fasd-worker-check
  # sched +9 quark-chpwd-fasd-worker-check

  sched +10 quark-prompt-async-fasd-timeout
}

function quark-prompt-async-compress {
  emulate -LR zsh -o prompt_subst -o transient_rprompt
  # check if we're running under Midnight Commander
  if (( $degraded_terminal[decorations] == 1 )); then
    chpwd_minify_smart_str=${${:-.}:A:t}
    zle && zle reset-prompt
  else
    chpwd_minify_fasd_str=""
    chpwd_minify_fast_str="$(quark-minify-path .)"
    chpwd_minify_smart_str="$(quark-minify-path-smart $chpwd_minify_fast_str)"
    quark-prompt-async-start-smart
    quark-prompt-async-start-fasd
  fi
}

quark-chpwd-smart-worker-setup

quark-prompt-async-compress
add-zsh-hook chpwd quark-prompt-async-compress
