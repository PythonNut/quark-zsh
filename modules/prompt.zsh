# ======
# Prompt
# ======

QUARK_SIGNAL_NAME=
typeset -A QUARK_ERROR_CODE_SIGNAL_MAP=(
    [129]=HUP
    [130]=INT
    [131]=QUIT
    [132]=ILL
    [134]=ABRT
    [136]=FPE
    [137]=KILL
    [139]=SEGV
    [141]=PIPE
    [143]=TERM

    # usual exit codes
    [-1]=FATAL
    [1]=WARN # Miscellaneous errors, such as "divide by zero"
    [2]=BUILTINMISUSE # misuse of shell builtins (pretty rare)
    [126]=CCANNOTINVOKE # cannot invoke requested command (ex : source script_with_syntax_error)
    [127]=CNOTFOUND # command not found (ex : source script_not_existing)

    # assuming we are on an x86 system here
    # this MIGHT get annoying since those are in a range of exit codes
    # programs sometimes use.... we'll see.
    [19]=STOP
    [20]=TSTP
    [21]=TTIN
    [22]=TTOU
)

if (( $degraded_terminal[unicode] != 1 )); then
  # a prompt that commits suicide when pasted
  QUARK_NBSP=$'\u00A0'
  function kill_prompt_on_paste () {
    PASTED=${(F)${${(f)PASTED}#*$QUARK_NBSP}}
  }
  zstyle :bracketed-paste-magic paste-init kill_prompt_on_paste

  QUARK_RETURN_CODE_ARROW='↪'
else
  QUARK_NBSP=$' '
  QUARK_RETURN_CODE_ARROW='→'
fi

QUARK_PROMPT_HOSTNAME=
QUARK_PROMPT_KEYMAP=

if (( $degraded_terminal[display_host] == 1 )); then
  if (( $degraded_terminal[colors256] != 1 )); then
    if (( $+commands[md5sum] )); then
      # hash hostname and generate one of 256 colors
      QUARK_PROMPT_HOSTNAME="%F{$((0x${$(echo ${HOST%%.*} |md5sum):1:2}))}"
    elif (( $+commands[md5] )); then
      QUARK_PROMPT_HOSTNAME="%F{$((0x${$(echo ${HOST%%.*} |md5):1:2}))}"
    fi
    if [[ -n $PROMPT_HOSTNAME_FULL ]]; then
      PROMPT_HOSTNAME+="@${HOST}%k%f"
    else
      PROMPT_HOSTNAME+="@${HOST:0:3}%k%f"
    fi
  fi
fi

function quark-compute-prompt {
  emulate -LR zsh -o prompt_subst -o transient_rprompt -o extended_glob
  local pure_ascii
  PS1=

  PS1+=$'%{%B%F{red}%}%(?..↪ %?${QUARK_ERROR_CODE_SIGNAL_MAP[${(%%)${:-%?}}]:+:${QUARK_ERROR_CODE_SIGNAL_MAP[${(%%)${:-%?}}]}}\n)%{%b%F{default}%}'

  # user (highlight root in red)
  if [[ -z $BORING_USERS[(R)$USER] ]]; then
    PS1+='%{%F{default}%}%B%{%(!.%F{red}.%F{black})%}%n'
  fi

  # reset decorations
  PS1+='%u%{%b%F{default}%}'

  PS1+="$QUARK_PROMPT_HOSTNAME "

  # show background jobs
  PS1+='%(1j.%{%B%F{yellow}%}%j&%{%F{default}%b%} .)'

  # compressed_path
  PS1+='$chpwd_minify_smart_str'

  # Add teleport shortcut
  PS1+='${${${PWD:A}/#%(${${:-~}:A}|\/)/}:+${${$(( $#chpwd_minify_fasd_str && $#chpwd_minify_fasd_str <= $#chpwd_minify_smart_str ))%0}:+→${chpwd_minify_fasd_str//(#m) ?/%U${MATCH# }%u}}}'

  if (( $degraded_terminal[rprompt] != 1 )); then
    # shell depth
    if [[ $_ZSH_PARENT_CMDLINE == [[:alpha:]]#sh* ]]; then
      PS1+=" <%L>"
    fi

    # vim normal/textobject mode indicator
    RPS1='${${PROMPT_KEYMAP/vicmd/%B%F{black\} [% N]% %b }/(afu|main)/}'
    RPS1=$RPS1'${vcs_info_msg_0_}'

  else
    RPS1=
    PS1+='${${${#vcs_info_msg_0_}%0}:+ ${vcs_info_msg_0_}}'
  fi

  # change the sigil color based on the return code and keymap
  PS1+='${${${${${QUARK_PROMPT_KEYMAP}:#vicmd}:-%{%F{magenta\}%\}}:#${QUARK_PROMPT_KEYMAP}}:-%{%(?.%F{green\}.%B%F{red\})%\}}'

  # compute the sigil
  if [[ -n $TMUX ]]; then
    if (( $degraded_terminal[unicode] != 1 )); then
      PS1+=" %(!.#.❯)"

    else
      PS1+=" %(!.#.$)"
    fi
  else
    PS1+=" %#"
  fi
  PS1+="%{%b%F{default}%}$QUARK_NBSP"
}


quark-compute-prompt
PS2='${(l:$(quark-strlen "${(e)PS1}"):: :)${:->$QUARK_NBSP}}'
RPS2='%^'

# intercept keymap selection
function zle-keymap-select () {
  emulate -LR zsh -o prompt_subst -o transient_rprompt -o extended_glob
  QUARK_PROMPT_KEYMAP=$KEYMAP
  zle reset-prompt
}
zle -N zle-keymap-select
