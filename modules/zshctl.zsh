QUARK_OPTIONS_FILE=${ZDOTDIR}/data/options.zsh

typeset -a quark_option_list
typeset -A quark_options
typeset -A quark_option_handlers

function zshctl () {
  emulate -LR zsh
  local key value
  if [[ -z $1 ]]; then
     typeset -p quark_options
     return
  fi

  case "$1" in
    (unset)
      shift
      key=$1
      if ! (( ${quark_option_list[(I)$key]} )); then
         echo "Unrecognized key \"${1}\"."
         return
      fi

      quark_options[$key]=
      zshctl save
      echo "$key unset"
      ;;

    (set)
      shift
      key=$1
      if ! (( ${quark_option_list[(I)$key]} )); then
         echo "Unrecognized key \"${1}\"."
         return
      fi

      if [[ -z $2 ]]; then
         value=1
      else
          value=$2
      fi

      quark_options[$key]=$value
      echo "$key ← ${quark_options[$key]}"
      zshctl save
      ;;

    (get|show)
      shift
      key=$1
      if ! (( ${quark_option_list[(I)$key]} )); then
         echo "Unrecognized key \"${1}\"."
         return
      fi

      echo "$key → ${quark_options[$key]}"
      ;;

    (save)
      local quark_data_dir=${QUARK_OPTIONS_FILE%/*}
      if [[ ! -d $quark_data_dir ]]; then
         mkdir -p $quark_data_dir
      fi

      touch $QUARK_OPTIONS_FILE

      typeset -p quark_options > $QUARK_OPTIONS_FILE
      ;;

    (load)
      if [[ -f $QUARK_OPTIONS_FILE ]]; then
         source $QUARK_OPTIONS_FILE
      fi
      ;;

    (*)
      echo "Unrecognized subcommand \"${1}\"."
      return 1
      ;;
  esac
}

zshctl load
