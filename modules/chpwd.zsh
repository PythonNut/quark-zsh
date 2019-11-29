function quark-chpwd-smart-worker {
  emulate -LR zsh

  quark-minify-path-full -r $1
  local quark_chpwd_minify_full_str=$REPLY

  quark-minify-path-smart -r $quark_chpwd_minify_full_str
  local quark_chpwd_minify_smart_str=$REPLY

  typeset -p quark_chpwd_minify_full_str
  typeset -p quark_chpwd_minify_smart_str
}

function quark-chpwd-smart-worker-callback {
  emulate -LR zsh -o prompt_subst -o transient_rprompt

  if [[ $5 == quark_chpwd_smart_worker:zle\ -F*returned\ error* ]]; then
    quark-chpwd-smart-worker-setup
    return
  fi

  quark-sched-remove quark-chpwd-smart-worker-timeout
  quark-sched-remove quark-chpwd-smart-worker-check

  quark-eval-overriding-globals $3

  float -g quark_chpwd_smart_duration=$4

  if (( $6 == 0 )); then
    zle && zle reset-prompt
  fi

  quark-title-sync
}

function quark-chpwd-smart-worker-check {
  quark-with-protected-return-code \
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
  async_flush_jobs quark_chpwd_smart_worker
}

function quark-chpwd-smart-worker-timeout {
  quark-error chpwd smart compressor timed out!
  quark-chpwd-smart-worker-reset
}

function quark-chpwd-smart-start {
  async_job quark_chpwd_smart_worker quark-chpwd-smart-worker ${${:-.}:A}

  sched +1 quark-chpwd-smart-worker-check
  # sched +2 quark-chpwd-smart-worker-check
  sched +9 quark-chpwd-smart-worker-check

  sched +10 quark-chpwd-smart-worker-timeout
}

function quark-chpwd-fasd-worker {
  emulate -LR zsh

  quark-minify-path-fasd -r $1
  local quark_chpwd_minify_fasd_str=$REPLY

  typeset -p quark_chpwd_minify_fasd_str
}

function quark-chpwd-fasd-worker-callback {
  emulate -LR zsh -o prompt_subst -o transient_rprompt

  if [[ $5 == quark_chpwd_fasd_worker:zle\ -F*returned\ error* ]]; then
    quark-chpwd-fasd-worker-setup
    return
  fi

  quark-sched-remove quark-chpwd-fasd-worker-timeout
  quark-sched-remove quark-chpwd-fasd-worker-check

  quark-eval-overriding-globals $3

  float -g quark_chpwd_fasd_duration=$4

  if (( $6 == 0 )); then
    zle && zle reset-prompt
  fi

  quark-title-sync
}

function quark-chpwd-fasd-worker-check {
  quark-with-protected-return-code \
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
  async_flush_jobs quark_chpwd_fasd_worker
}

quark-chpwd-fasd-worker-setup

function quark-chpwd-fasd-worker-timeout {
  quark-error chpwd fasd compressor timed out!
  quark-chpwd-fasd-worker-reset
}

function quark-chpwd-fasd-start {
  async_job quark_chpwd_fasd_worker quark-chpwd-fasd-worker ${${:-.}:A}

  sched +1 quark-chpwd-fasd-worker-check
  # sched +2 quark-chpwd-fasd-worker-check
  sched +9 quark-chpwd-fasd-worker-check

  sched +10 quark-chpwd-fasd-worker-timeout
}

function quark-chpwd-async-start {
  emulate -LR zsh -o prompt_subst -o transient_rprompt
  # check if we're running under Midnight Commander
  if (( $degraded_terminal[decorations] == 1 )); then
    quark_chpwd_minify_smart_str=${${:-.}:A:t}
    zle && zle reset-prompt
  else
    quark_chpwd_minify_fasd_str=""

    quark-minify-path -r .
    quark_chpwd_minify_fast_str=$REPLY
    quark_chpwd_minify_full_str=$quark_chpwd_minify_fast_str

    quark-minify-path-smart -r $quark_chpwd_minify_fast_str
    quark_chpwd_minify_smart_str=$REPLY

    quark-chpwd-smart-start
    quark-chpwd-fasd-start
  fi
}

quark-chpwd-smart-worker-setup

quark-chpwd-async-start
add-zsh-hook chpwd quark-chpwd-async-start
