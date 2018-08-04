# ========================================
# Title + Path compression + chpwd handler
# ========================================

function quark-chpwd-async-worker () {
  emulate -LR zsh
  TRAPTERM () {
    kill -INT $$
  }

  local chpwd_minify_fasd_str="$(quark-minify-path-fasd $1)"
  local chpwd_minify_full_str="$(quark-minify-path-full $1)"
  local chpwd_minify_smart_str="$(quark-minify-path-smart $chpwd_minify_full_str)"

  typeset -p chpwd_minify_smart_str
  typeset -p chpwd_minify_fasd_str
}

function quark-chpwd-callback {
  emulate -LR zsh -o prompt_subst -o transient_rprompt

  # Clear the timeout entry
  local -i sched_id
  sched_id=${zsh_scheduled_events[(i)*:*:quark-prompt-async-timeout]}
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

  zle && zle reset-prompt
  title_async_compress
}

function quark-chpwd-worker-setup {
  async_start_worker chpwd_worker -u
  async_register_callback chpwd_worker quark-chpwd-callback
}

function quark-chpwd-worker-cleanup {
  async_flush_jobs chpwd_worker
  async_stop_worker chpwd_worker
}

function quark-chpwd-worker-reset {
  quark-chpwd-worker-cleanup
  quark-chpwd-worker-setup
}
quark-chpwd-worker-setup

function quark-prompt-async-timeout {
  echo chpwd compressor timed out! >> $ZDOTDIR/startup.log
  quark-chpwd-worker-reset
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
    async_job chpwd_worker quark-chpwd-async-worker ${${:-.}:A}
    sched +10 quark-prompt-async-timeout
  fi
}

quark-prompt-async-compress
add-zsh-hook chpwd quark-prompt-async-compress
