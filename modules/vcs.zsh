# ======================
# Version Control System
# ======================

zstyle ':vcs_info:*' enable git svn cvs hg bzr
zstyle ':vcs_info:*' check-for-changes true

ZSH_VCS_PROMPT_ENABLE_CACHING='false'
ZSH_VCS_PROMPT_USING_PYTHON='true'
ZSH_VCS_PROMPT_MERGE_BRANCH=

if (( $degraded_terminal[unicode] != 1 )); then
  ZSH_VCS_PROMPT_AHEAD_SIGIL='↑'
  ZSH_VCS_PROMPT_BEHIND_SIGIL='↓'
  ZSH_VCS_PROMPT_STAGED_SIGIL='●'
  ZSH_VCS_PROMPT_CONFLICTS_SIGIL='✖'
  ZSH_VCS_PROMPT_UNSTAGED_SIGIL='✚'
  ZSH_VCS_PROMPT_UNTRACKED_SIGIL='…'
  ZSH_VCS_PROMPT_STASHED_SIGIL='⚑'
  ZSH_VCS_PROMPT_CLEAN_SIGIL='✔'
else
  ZSH_VCS_PROMPT_AHEAD_SIGIL='>'
  ZSH_VCS_PROMPT_BEHIND_SIGIL='<'
  ZSH_VCS_PROMPT_STAGED_SIGIL='*'
  ZSH_VCS_PROMPT_CONFLICTS_SIGIL='x'
  ZSH_VCS_PROMPT_UNSTAGED_SIGIL='+'
  ZSH_VCS_PROMPT_UNTRACKED_SIGIL='.'
  ZSH_VCS_PROMPT_STASHED_SIGIL='#'
  ZSH_VCS_PROMPT_CLEAN_SIGIL='-'
fi

ZSH_VCS_PROMPT_GIT_FORMATS='%{%B%F{red}%}#b%{%f%b%}'     # Branch name
ZSH_VCS_PROMPT_GIT_FORMATS+='#c#d '                      # Ahead and Behind
ZSH_VCS_PROMPT_GIT_FORMATS+='%{%F{blue}%}#e%{%f%b%}'     # Staged
ZSH_VCS_PROMPT_GIT_FORMATS+='%{%F{red}%}#f%{%f%b%}'      # Conflicts
ZSH_VCS_PROMPT_GIT_FORMATS+='%{%F{yellow}%}#g%{%f%b%}'   # Unstaged
ZSH_VCS_PROMPT_GIT_FORMATS+='#h'                         # Untracked
ZSH_VCS_PROMPT_GIT_FORMATS+='%{%F{cyan}%}#i%{%f%b%}'     # Stashed
ZSH_VCS_PROMPT_GIT_FORMATS+='%{%F{green}%}#j%{%f%b%}'    # Clean

ZSH_VCS_PROMPT_GIT_ACTION_FORMATS='%{%B%F{yellow}%}#s%{%f%b%} ' # VCS name
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='%{%B%F{red}%}#b%{%f%b%}'    # Branch name
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+=':%{%B%F{red}%}#a%{%f%b%}'   # Action
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='#c#d '                      # Ahead and Behind
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='%{%F{blue}%}#e%{%f%}'       # Staged
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='%{%F{red}%}#f%{%f%}'        # Conflicts
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='%{%F{yellow}%}#g%{%f%}'     # Unstaged
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='#h'                         # Untracked
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='%{%F{cyan}%}#i%{%f%}'       # Stashed
ZSH_VCS_PROMPT_GIT_ACTION_FORMATS+='%{%F{green}%}#j%{%f%}'      # Clean

## Other VCS without Action.
ZSH_VCS_PROMPT_VCS_FORMATS='%{%B%F{yellow}%}#s%{%f%b%} ' # VCS name
ZSH_VCS_PROMPT_VCS_FORMATS+='%{%B%F{red}%}#b%{%f%b%}'    # Branch name

## Other VCS with Action.
ZSH_VCS_PROMPT_VCS_ACTION_FORMATS='%{%B%F{yellow}%}#s%{%f%b%} '  # VCS name
ZSH_VCS_PROMPT_VCS_ACTION_FORMATS+='%{%B%F{red}%}#b%{%f%b%} '    # Branch name
ZSH_VCS_PROMPT_VCS_ACTION_FORMATS+='%{%B%F{red}%}#a%{%f%b%}'     # Action

# zstyle ':vcs_info:*+*:*' debug true
zstyle ':vcs_info:(svn|csv|hg)*' formats "%B%F{yellow}%s%%b%f %b %u%c"
zstyle ':vcs_info:(svn|csv|hg)*' branchformat "%B%F{red}%b(%r)%%b%f"
zstyle ':vcs_info:svn*+set-message:*' hooks svn-untracked
zstyle ':vcs_info:hg*+set-message:*' hooks hg-untracked

ZSH_VCS_PROMPT_VCS_FORMATS="#s"


# Add missing functionality to the vcs prompt
function +vi-svn-untracked {
  emulate -LR zsh -o prompt_subst -o transient_rprompt
  if ! hash svn; then
    return 0;
  fi
  if command svn info &> /dev/null; then
    local svn_status=${(F)$(command svn status)}

    local modified_count=${#${(F)$(echo $svn_status | \grep '^[MDA!]')}}
    if (( $modified_count != 0 )); then
      modified_count=$ZSH_VCS_PROMPT_UNSTAGED_SIGIL${#${(f)modified_count}}
      hook_com[unstaged]+="%b%F{yellow}$modified_count%f"
    fi

    local unstaged_count=${#${(f)${(F)$(echo $svn_status | \grep '^?')}}}
    if (( $unstaged_count != 0 )); then
      unstaged_count=$ZSH_VCS_PROMPT_UNTRACKED_SIGIL$unstaged_count
      hook_com[unstaged]+="%f%b$unstaged_count%f"
    fi

    if [[ ! -n $hook_com[unstaged] ]]; then
      hook_com[unstaged]="%F{green}$ZSH_VCS_PROMPT_CLEAN_SIGIL%f"
    fi
  fi
}

function +vi-hg-untracked {
  emulate -LR zsh -o prompt_subst -o transient_rprompt
  if ! hash hg; then
    return 0;
  fi
  if command hg id &> /dev/null; then
    local hg_status=${(F)$(command hg status)}

    local modified_count=${#${(F)$(echo $hg_status | \grep '^[MDA!]')}}
    if (( $modified_count != 0 )); then
      modified_count=$ZSH_VCS_PROMPT_UNSTAGED_SIGIL${#${(f)modified_count}}
      hook_com[unstaged]+="%b%F{yellow}$modified_count%f"
    fi

    local unstaged_count=${#${(f)${(F)$(echo $hg_status | \grep '^?')}}}
    if (( $unstaged_count != 0 )); then
      unstaged_count=$ZSH_VCS_PROMPT_UNTRACKED_SIGIL$unstaged_count
      hook_com[unstaged]+="%f%b$unstaged_count%f"
    fi

    if [[ ! -n $hook_com[unstaged] ]]; then
      hook_com[unstaged]="%F{green}$ZSH_VCS_PROMPT_CLEAN_SIGIL%f"
    fi
  fi
}

function quark-vcs-get-root-dir {
  case $1 in
    (git)
      git rev-parse --show-toplevel;;
    (hg)
      hg root;;
    (svn)
      if [[ -d ".svn" ]]; then
        if [[ -d "../.svn" ]]; then
          # case 2: SVN < 1.7, any directory
          local parent=""
          local grandparent="."

          while [[ -d "$grandparent/.svn" ]]; do
              parent=$grandparent
              grandparent="$parent/.."
          done

          echo ${parent:A}
        else
          # case 2: SVN >= 1.7, root directory
          echo ${${:-.}:A}
        fi
      else
        # case 3: SVN >= 1.7, non root directory
        local parent="."
        while [[ ! -d "$parent/.svn" ]]; do
            parent+="/.."
        done

        echo ${parent:A}
      fi;;
    (bzr)
      bzr root;;
    (cvs)
      echo $CVSROOT;;
    (*)
      echo $PWD;;
  esac
}

function quark-vcs-worker {
  local vcs_super_info
  local vcs_root_dir
  local -a vcs_super_raw_data

  function TRAPTERM {
    kill -INT $$
  }

  builtin cd $1
  vcs_current_pwd=$1
  vcs_super_info="$(vcs_super_info)"
  vcs_super_raw_data=($(vcs_super_info_raw_data))
  vcs_root_dir=${$(quark-vcs-get-root-dir $vcs_super_raw_data[2])%/}

  typeset -p vcs_current_pwd
  typeset -p vcs_super_info
  typeset -p vcs_super_raw_data
  typeset -p vcs_root_dir
}

function quark-vcs-worker-callback {
  local current_pwd=${${:-.}:A}
  local vcs_super_info
  local vcs_super_raw_data
  local vcs_root_dir

  quark-sched-remove quark-vcs-worker-timeout

  typeset -g vcs_last_root

  eval $3

  typeset -g vcs_info_msg_0_
  typeset -g vcs_raw_data
  vcs_info_msg_0_=$vcs_super_info
  vcs_raw_data=($vcs_super_raw_data)

  zle && zle reset-prompt

  # if we're in a vcs, start an inotify process
  if [[ $current_pwd/ != $vcs_last_root/* ]]; then
    quark-vcs-start
  fi

  vcs_last_root=$vcs_root_dir
}

function quark-vcs-worker-check {
  quark-with-protected-return-code \
      async_process_results quark_vcs_worker quark-vcs-worker-callback
}

function quark-vcs-worker-setup {
  async_start_worker quark_vcs_worker -u
  async_register_callback quark_vcs_worker quark-vcs-worker-callback
}

function quark-vcs-worker-cleanup {
  async_stop_worker quark_vcs_worker
}

function quark-vcs-worker-reset {
  async_flush_jobs quark_vcs_worker
}

quark-vcs-worker-setup


function quark-vcs-worker-timeout {
  quark-error vcs status timed out!
  quark-vcs-worker-reset
}

function quark-vcs-start {
  async_job quark_vcs_worker quark-vcs-worker ${${:-.}:A}

  sched +1 quark-vcs-worker-check
  sched +9 quark-vcs-worker-check

  sched +10 quark-vcs-worker-timeout
}

add-zsh-hook precmd quark-vcs-start
