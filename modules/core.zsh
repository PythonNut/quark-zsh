autoload -Uz zargs               # a more integrated xargs
autoload -Uz zmv                 # concise file renaming/moving
autoload -Uz zed                 # edit files right in the shell
autoload -Uz zsh/mathfunc        # common mathematical functions
autoload -Uz zcalc               # a calculator right in the shell
autoload -Uz zkbd                # automatic keybinding detection
autoload -Uz zsh-mime-setup      # automatic MIME type suffixes
autoload -Uz colors              # collor utility functions
autoload -Uz vcs_info            # integrate with version control
autoload -Uz copy-earlier-word   # navigate backwards with C-. C-,
autoload -Uz url-quote-magic     # automatically%20escape%20characters
autoload -Uz add-zsh-hook        # a more modular way to hook
autoload -Uz is-at-least         # enable graceful regression
autoload -Uz throw               # throw exceptions
autoload -Uz catch               # catch exceptions

zmodload zsh/complist            # ensure complist is loaded
zmodload zsh/sched               # delayed execution in zsh
zmodload zsh/mathfunc            # mathematical functions in zsh
zmodload zsh/terminfo            # terminal parameters from terminfo
zmodload zsh/complist            # various completion functions
zmodload zsh/mapfile             # read files directly
zmodload zsh/datetime            # date and time helpers
zmodload -F zsh/stat b:zstat     # get stat info natively

function quark-log {
  echo $EPOCHREALTIME $@ >> $ZDOTDIR/startup.log
}

function quark-error {
    quark-log "[ERROR]" $@
}
function quark-info {
    quark-log "[INFO]" $@
}
function quark-warn {
    quark-log "[WARN]" $@
}
function quark-debug {
    quark-log "[DEBUG]" $@
}
function quark-error {
    quark-log "[ERROR]" $@
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
  # This also resets $SECONDS to 0, locally
  local -F SECONDS
  shift
  (eval $@) &
  # TODO: /proc probably isn't portable
  zstat -A stat_reply '+mtime' /proc/$!

  local PID=$! MTIME=${stat_reply[1]}
  while true; do
    sleep 0.001
    if [[ ! -d /proc/$PID ]]; then
        break
    fi
    zstat -A stat_reply '+mtime' /proc/$PID
    if [[ ${stat_reply[1]} != $MTIME ]]; then
        break
    fi
    if (( $SECONDS > $time_limit )); then
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

function quark-detect-sudo-type {
  emulate -LR zsh
  if sudo -n true &> /dev/null; then
      REPLY=passwordless
  elif [[ $(sudo -vS < /dev/null 2>&1) == (*password*|*askpass*) ]]; then
      REPLY=passworded
  else
      REPLY=none
  fi
}

function quark-switch-focus-by-name {
  if ! (( $+commands[wmctrl] && $+commands[pgrep] )); then
      return
  fi

  local -a pids=($(pgrep $1))
  local -a windows=("${(f)$(wmctrl -lp)}")
  local -a line
  local window_id

  if (( ${#pids} == 0)); then
      return
  fi

  for window in $windows; do
    line=(${(s/ /)window})
    if (( ${pids[(I)${line[3]}]} )); then
        window_id=${line[1]}
        break
    fi
  done

  if [[ -z $window_id ]]; then
      return
  fi

  wmctrl -ia $window_id
}
