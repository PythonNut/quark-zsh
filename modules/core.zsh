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
zmodload zsh/parameter           # internal hash tables as parameters
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
  local -F start_time=$EPOCHREALTIME
  shift
  (eval $@) &
  # TODO: /proc probably isn't portable
  zstat -A stat_reply '+mtime' /proc/$!

  local pid=$! mtime=${stat_reply[1]}
  while true; do
    sleep 0.001
    if [[ ! -d /proc/$pid ]]; then
        break
    fi
    # Note: this can fail b/c of a race condition with the previous
    # check, however we'll loop exactly once more, so it's ok.
    zstat -A stat_reply '+mtime' /proc/$pid 2> /dev/null
    if [[ ${stat_reply[1]} != $mtime ]]; then
        break
    fi
    if (( $EPOCHREALTIME - $start_time > $time_limit )); then
        {
          kill $pid
          wait $pid
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

typeset -a quark_md5_rotate_amounts=(
    7 12 17 22 7 12 17 22 7 12 17 22 7 12 17 22
    5  9 14 20 5  9 14 20 5  9 14 20 5  9 14 20
    4 11 16 23 4 11 16 23 4 11 16 23 4 11 16 23
    6 10 15 21 6 10 15 21 6 10 15 21 6 10 15 21
)

typeset -a quark_md5_constants=(
    3614090360 3905402710  606105819 3250441966 4118548399
    1200080426 2821735955 4249261313 1770035416 2336552879
    4294925233 2304563134 1804603682 4254626195 2792965006
    1236535329 4129170786 3225465664  643717713 3921069994
    3593408605   38016083 3634488961 3889429448  568446438
    3275163606 4107603335 1163531501 2850285829 4243563512
    1735328473 2368359562 4294588738 2272392833 1839030562
    4259657740 2763975236 1272893353 4139469664 3200236656
     681279174 3936430074 3572445317   76029189 3654602809
    3873151461  530742520 3299628645 4096336452 1126891415
    2878612391 4237533241 1700485571 2399980690 4293915773
    2240044497 1873313359 4264355552 2734768916 1309151649
    4149444226 3174756917  718787259 3951481745
)

function quark_md5_int_to_bytes_little_endian {
  local buf
  local -i bytes index
  (( bytes = 2*$2 ))
  printf -v buf "%0${bytes}x" $1
  reply=()
  for ((index=$bytes; index > 0; index-=2)); do
    reply+=($(( 16#${buf[$index-1, $index]} )))
  done
}

function quark_md5 {
  local -a message chunk
  if [[ -n $1 ]]; then
      printf -v message '%d' ${(l:2::\':)${(s::)1}}
  fi
  message+=(128 ${(s::)${(l:$(( 63 - ($#message + 8)%64 ))::0:)}})
  quark_md5_int_to_bytes_little_endian $(( 8*$#1 )) 8
  message+=($reply)

  local -i h1=1732584193 h2=4023233417 h3=2562383102 h4=271733878
  local -i chunk_ofst a b c d i f g amount to_rotate
  for ((chunk_ofst=1; chunk_ofst<=$#message; chunk_ofst+=64)); do
    (( a=$h1, b=$h2, c=$h3, d=$h4 ))
    chunk=(${message[$chunk_ofst,$chunk_ofst+63]})
    for ((i=0; $i<64; ++i)); do
      case $(( $i/16 )) in
          (0) (( f = ($b & $c) | (~$b & $d), g=$i )) ;;
          (1) (( f = ($d & $b) | (~$d & $c), g = (5*$i + 1)%16 )) ;;
          (2) (( f = $b ^ $c ^ $d, g = (3*$i + 5)%16 )) ;;
          (3) (( f = $c ^ ($b | ~$d), g = (7*$i)%16 )) ;;
      esac
      ((
          to_rotate = ($a + $f + $quark_md5_constants[$i+1] \
                          + ${chunk[4*$g+1]} \
                          + 256*${chunk[4*$g+2]} \
                          + 65536*${chunk[4*$g+3]} \
                          + 16777216*${chunk[4*$g+4]}) & 0xffffffff,
          amount=$quark_md5_rotate_amounts[$i+1]
      ))
      ((
          a = $d, d = $c, c = $b, \
          b = ((b + ((($to_rotate << $amount) | ($to_rotate >> (32 - $amount))) \
                     & 0xffffffff)) \
               & 0xffffffff)
      ))
    done
    ((
        h1 += $a, h1 &= 0xffffffff,
        h2 += $b, h2 &= 0xffffffff,
        h3 += $c, h3 &= 0xffffffff,
        h4 += $d, h4 &= 0xffffffff
    ))
  done

  local result=""
  for piece in $h1 $h2 $h3 $h4; do
    quark_md5_int_to_bytes_little_endian $piece 4
    local -a buf
    printf -v buf '%02x' $reply
    result+=${(j::)buf}
  done

  REPLY=$result
}

function quark-async-renice {
  setopt localoptions noshwordsplit

  if (( $+commands[renice] )); then
      command renice -n 20 -p $$
  fi

  if (( $+commands[ionice] )); then
      command ionice -c 3 -p $$
  fi

  if (( $+commands[schedtool] )); then
      command schedtool -B $$
  fi
}

quark-urlencode() {
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:$i:1}"
    case $c in
        (%) printf '%%%02X' "'$c" ;;
        (*) printf "%s" "$c" ;;
   esac
 done
}
