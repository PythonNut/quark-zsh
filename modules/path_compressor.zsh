# ================
# path compressors
# ================

# Reduce path to shortest prefixes. Heavily Optimized
function quark-minify-path {
  zparseopts -D -E r=USE_REPLY
  emulate -LR zsh -o glob_dots -o extended_glob
  local full_path="/" ppath cur_path dir glob
  local -a revise
  local -i matches col

  for token in ${(s:/:)${1:A}/${HOME:A}/\~}; do
    cur_path=${full_path:s/\~/$HOME/}
    col=1
    glob="${token[0,1]}"
    cur_path=($cur_path/*(/))
    # prune the single dir case
    if [[ $#cur_path == 1 ]]; then
      ppath+="/"
      full_path=${full_path%%(/##)}/$token
      continue
    fi
    while; do
      matches=0
      revise=()
      for fulldir in $cur_path; do
        dir=${${fulldir%%/}##*/}
        if (( ${#dir##(#l)($glob)} < $#dir )); then
          ((matches++))
          revise+=$fulldir
          if (( matches > 1 )); then
            break
          fi
        fi
      done
      if (( $matches > 1 )); then
        glob=${token[0,$((col++))]}
        if (( $col -1 > $#token )); then
          break
        fi
      else
        break
      fi
      cur_path=($revise)
    done
    ppath+="/$glob"
    full_path=${full_path%%(/##)}
    full_path+="/$token"
  done

  local return="${${ppath:s/\/\~/\~/}:-/}"
  quark-return "$USE_REPLY" "$return"
}

typeset -A quark_minify_path_cache
QUARK_MINIFY_PATH_CACHE_FILE=$ZDOTDIR/.minify-path.cache

# take every possible branch on the file system into account
function quark-minify-path-full {
  zparseopts -D -E d=DEBUG r=USE_REPLY
  emulate -LR zsh -o extended_glob -o null_glob -o glob_dots
  local glob temp_glob result official_result seg limit
  fullpath=${${1:A}/${HOME:A}/\~}
  glob=("${(@s:/:)fullpath}")

  local -i index=$(($#glob)) k

  temp_glob=("${(s/ /)glob//(#m)?/$MATCH*}")
  temp_glob="(#l)"${${(j:/:)temp_glob}/\~\*/$HOME}(/oN)
  official_result=(${~temp_glob})

  # set glob short circuit level
  limit="(/oNY$(( ${#official_result} + 1 )))"

  # open the cache file
  if [[ ! -f $QUARK_MINIFY_PATH_CACHE_FILE ]]; then
    touch $QUARK_MINIFY_PATH_CACHE_FILE
    quark_minify_path_cache=()
  else
    source $QUARK_MINIFY_PATH_CACHE_FILE
  fi

  local test_glob=("${(@)glob}")
  local test_path=${(@j:/:)test_glob}
  if (( ${+quark_minify_path_cache[$test_path]} )); then
    # verify the cache hit:
    local -a cache_glob=("${(@s:/:)quark_minify_path_cache[$test_path]}")
    temp_glob=("${(s/ /)cache_glob//(#m)?/$MATCH*}")
    temp_glob="(#l)"${${(j:/:)temp_glob}/\~\*/$HOME}$limit
    if [[ -n $DEBUG ]]; then
      echo Testing cached: ${(j:/:)cache_glob} → $temp_glob
    fi
    result=($(quark-with-timeout 0.3 "setopt glob_dots extended_glob; echo $temp_glob"))
    if [[ -n $DEBUG ]]; then
        echo cache result: $result
    fi
    if [[ $result == $official_result ]]; then
      glob=("${(@)cache_glob}")
    fi
  fi


  while ((index >= 1)); do
    if [[ ${glob[$index]} == "~" ]]; then
      break
    fi
    k=${#glob[$index]}
    old_glob=${glob[$index]}
    while true; do
      seg=$glob[$index]
      temp_glob=("${(s/ /)glob//(#m)?/$MATCH*}")
      temp_glob="(#l)"${${(j:/:)temp_glob}/\~\*/$HOME}
      temp_glob+=$limit
      result=($(quark-with-timeout 0.3 "setopt glob_dots extended_glob; echo $temp_glob"))
      if [[ $result != $official_result ]]; then
        glob[$index]=$old_glob
        seg=$old_glob
      else
        # if we succeeded, try smart casing
        if [[ ${${glob[$index]}[$k]} == [[:upper:]] ]]; then
          old_glob=$glob[$index]

          temp_glob=$old_glob
          temp_glob[$k]=${temp_glob[$k]:l}
          glob[$index]=$temp_glob
          continue
        fi
      fi

      if (( $k == 0 )); then
        break
      fi

      old_glob=${glob[$index]}
      glob[$index]=$seg[0,$(($k-1))]$seg[$(($k+1)),-1]
      ((k--))
      if [[ -n $DEBUG ]]; then
         echo ${(j:/:)glob}
      fi
    done
    ((index--))
  done

  local return=${(j:/:)glob}
  quark_minify_path_cache[$fullpath]=$return
  typeset -p quark_minify_path_cache > $QUARK_MINIFY_PATH_CACHE_FILE

  quark-return "$USE_REPLY" "$return"
}

# collapse empty runs too
function quark-minify-path-smart {
  zparseopts -D -E d=DEBUG r=USE_REPLY
  emulate -LR zsh -o brace_ccl -o extended_glob

  local return=${${1//(#m)\/\/##/%U${#MATCH}%u}//(#m)\/[^0-9]/%U${MATCH#/}%u}
  quark-return "$USE_REPLY" "$return"
}

# find shortest unique fasd prefix. Heavily optimized
function quark-minify-path-fasd {
  zparseopts -D -E a=ALL r=USE_REPLY
  emulate -LR zsh -o extended_glob
  if ! (( $+commands[fasd] )); then
    quark-return "$USE_REPLY" ""
    return
  fi

  1=${${1:A}%/}
  if [[ $1 == ${${:-~}:A} ]]; then
    quark-return "$USE_REPLY" ""
    return
  fi


  local dirs=("${(@f)$(fasd -l)}")
  if ! (( ${+dirs[(r)$1]} )); then
    quark-return "$USE_REPLY" ""
    return 1
  fi

  local index=${${${dirs[$((${dirs[(i)$1]}+1)),-1]}%/}##*/}
  local minimal_path=$1:t i
  for ((i=0; i<=$#minimal_path+1; i++)); do
    for ((k=1; k<=$#minimal_path-$i; k++)); do
      test=${minimal_path[$k,$(($k+$i))]}
      if [[ -z ${index[(r)*$test*]} ]]; then
        if [[ $(type $test) == *not* || -n $ALL ]]; then
          quark-return "$USE_REPLY" "$test"
          return
        fi
      fi
    done
  done

  index=(${${dirs[$((${dirs[(i)$1]}+1)),-1]}%/})
  minimal_path=${1//\//\ }
  for i in {1..$#minimal_path}; do
    local temp=$minimal_path[$i]
    minimal_path[$i]=" "
    if [[ -n "$index[(r)*${minimal_path// ##/*}*]" ]]; then
      minimal_path[$i]=$temp
    fi
  done

  local return="${${${minimal_path// ##/ }%%[[:space:]]#}##[[:space:]]#}"
  quark-return "$USE_REPLY" "$return"
}
