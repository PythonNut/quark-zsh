QUARK_OPTIONS_FILE=~/Documents/quark-zsh/data/options.zsh

typeset -A quark_options
typeset -A quark_option_list
typeset -A quark_option_handlers

function zshctl () {
  emulate -LR zsh
  local key value
  case "$1" in
    (set)
      shift
      key=$1
      if (( ${+quark_option_handlers[$key]} != 1 )); then
         echo "Unrecognized key \"${1}\"."
         return 1
      fi

      value=$2
      quark_options[$key]=$value
      echo "$key ← ${quark_option_list[$key]}"
      zshctl save
      ;;
    (get|show)
      shift
      key=$1
      echo "$key → ${quark_options[$key]}"
      ;;
    (save)
      touch $QUARK_OPTIONS_FILE
      typeset -p quark_options > $QUARK_OPTIONS_FILE
      ;;
    (load)
      source $QUARK_OPTIONS_FILE
      ;;
    (*)
      echo "Unrecognized subcommand \"${1}\"."
      return 1
      ;;
  esac
}
