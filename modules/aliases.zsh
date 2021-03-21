# =======
# Aliases
# =======
typeset -A global_abbrevs command_abbrevs
typeset -a expand

expand=('mc')

function alias () {
  emulate -LR zsh
  zparseopts -D -E eg=EG ec=EC E=E
  if [[ -n $EG ]]; then
    for token in $@; do
      token=(${(s/=/)token})
      builtin alias -g $token
      global_abbrevs[$token[1]]=$token[2]
    done
  elif [[ -n $EC ]]; then
    for token in $@; do
      builtin alias $token
      token=(${(s/=/)token})
      command_abbrevs[$token[1]]=$token[2]
    done
  else
    if [[ -n $E ]]; then
      for token in $@; do
        if [[ $token == (*=*) ]]; then
          token=(${(s/=/)token})
          expand+="$token[1]"
        fi
      done
    fi
    builtin alias $@
  fi
}

# history supression aliases
alias -E clear=' clear'
alias -E pwd=' pwd'
alias -E exit=' exit'

# proxy aliases
BORING_FILES='*\~|*.elc|*.pyc|!*|_*|*.swp|*.zwc|*.zwc.old|*.synctex.gz'
if [[ $OSTYPE = (#i)((free|open|net)bsd)* ]]; then
    # in BSD, -G is the equivalent of --color
    alias -E lst=' \ls -G'
elif [[ $OSTYPE = darwin* ]]; then
  if (( $+commands[gls] )); then
    alias lsa='\gls --color --group-directories-first'
    alias -E lst=" lsa -I '"${BORING_FILES//\|/\' -I \'}"'"
  else
    alias -E lst=' \ls -G'
   fi
else
  alias lsa='\ls --color --group-directories-first'
  alias -E lst=" lsa -I '"${BORING_FILES//\|/\' -I \'}"'"
fi

if (( $+commands[gegrep] )); then
  alias -E egrep='\gegrep --line-buffered --color=auto'
else
  alias -E egrep='\egrep --line-buffered --color=auto'
fi

# cd aliases
alias -- -='cd -'
alias -- --='cd -2'
alias -- ---='cd -3'
alias -- ----='cd -4'
alias -- -----='cd -5'
alias -- ------='cd -6'
alias -- -------='cd -7'
alias -- --------='cd -8'
alias -- ---------='cd -9'

# ls aliases
if (( $+commands[exa] )); then
  alias exa="exa --group-directories-first -I \"${BORING_FILES}\""
  alias ls='exa -F'
  alias l='exa -FGl --git'
  alias ll='exa -FGla --git'
  alias lll='exa -Fla --git'
  alias lss='exa -FGlrs size'
  alias lsp='\ls'
else
  alias ls='lst -BFv'
  alias l='lst -lFBGhv'
  alias ll='lsa -lAFGhv'
  alias lss='lst -BFshv'
  alias lsp='\ls'
fi

# safety aliases
alias rm='\rm -iv'
alias cp='\cp -riv --reflink=auto'
alias mv='\mv -iv'
alias mkdir="\mkdir -vp"
alias ln="\ln -s"

# global aliases
alias -g G='|& egrep -i'
alias -g L='|& less -R'
alias -g Lr='|& less'
alias -g D='>&/dev/null'
alias -g W='|& wc'
alias -g Q='>&/dev/null&'

# regular aliases
alias su='su -'
alias watch='\watch -n 1'
alias emacs='\emacs -nw'
alias df='\df -h'
alias ping='\ping -c 10'
alias :q='exit'
alias exi='exit'
alias -E exit=' exit'
alias errcho='>&2 echo'

if (( $+commands[glocate] )); then
  alias locate='\glocate -ib'
else
  alias locate='\locate -ib'
fi

# suppression aliases
alias -E man='noglob \man'
alias -E find='noglob \find'

# sudo aliases
if (( $+commands[sudo] )); then
  function sudo {
    emulate -L zsh
    local precommands=()
    while [[ $1 == (nocorrect|noglob) ]]; do
      precommands+=$1
      shift
    done
    eval "$precommands command sudo ${(q)@}"
  }
fi

function quark-alias-create-please-command {
  emulate -LR zsh -o extended_glob
  quark-detect-sudo-type
  if [[ $REPLY == none ]]; then
    local cmdline="${history[$#history]##[[:space:]]#}"
    local -i alias_found
    local exp
    # We're going to need to intelligently substitute aliases
    # This uses recursive expansion, which keeps track of previously expanded
    # aliases to avoid infinite loops with cyclic aliases
    local -a expanded=()
    while true; do
      alias_found=0
      for als in ${(k)aliases}; do
        if [[ $cmdline = ${als}* ]] && ! (( ${+expanded[(r)$als]} )); then
          expanded+=${als#\\}
          exp=$aliases[$als]
          cmdline="${cmdline/#(#m)${als}[^[:IDENT:]]/$exp${MATCH##[[:IDENT:]]#}}"
          cmdline=${cmdline##[[:space:]]#}
          alias_found=1
          break
        fi
      done
      if (( alias_found == 0 )); then
        break
      fi
    done
    # Needless to say, the result is rarely pretty
    echo -E \\su -c \"$cmdline\"
  else
    echo -E sudo ${history[$#history]}
  fi
}

alias -ec please='quark-alias-create-please-command'

# yay/yaourt aliases
if (( $+commands[yay] )); then
  alias y='yay'
  alias yi='yay -S'
  alias yu='yay -Syu --noconfirm'
fi

if (( $+commands[paru] )); then
    alias pi='paru -S'
    alias pu='paru -Syu --noconfirm'
fi

# dnf aliases
if (( $+commands[dnf] )); then
  alias -E dnf='noglob \dnf'
fi

# vim aliases
if (( $+commands[gvim] )); then
  alias -E vim="gvim -v"
fi
if (( $+commands[vim] )); then
  alias -E vi="vim"
fi

# git aliases
if (( $+commands[git] )); then
  alias gs='git status -sb'
  alias gst='git status'

  alias gp="git pull --rebase"
  alias gpa="git pull --rebase --autostash"

  alias ga='git add'
  alias gau='git add -u'
  alias gaa='git add -A'

  alias gc='git commit -v'
  alias -ec gcm="echo -E git commit -v -m '{}'"
  alias gc!='git commit -v --amend'
  alias gca='git commit -v -a'
  alias -ec gcam="echo -E git commit -v -a -m '{}'"
  alias gca!='git commit -v -a --amend'

  alias gck='git checkout'
  alias -ec gfork='echo -E git checkout -b {} $(git rev-parse --abbrev-ref HEAD 2>/dev/null)'

  alias gb='git branch -vvv'
  alias gm='git merge'
  alias gma='git merge --autostash'
  alias gr='git rebase'
  alias gra='git rebase --autostash'

  alias gd='git diff'
  alias gdc='git diff --cached'

  alias gl='git log --oneline --graph --decorate'

  alias -eg .B='echo $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "N/A")'
fi

if (( $+commands[git-annex] )); then
  alias gxp='git annex proxy'
  alias gxa='git annex add'
  alias gxg='git annex get'
  alias gxs='git annex sync'
  alias gxd='git annex drop'
  alias gxc='git annex copy'
  alias gxm='git annex move'
fi

if (( $+commands[emacsclient] )); then
  alias emacsd="s emacs --daemon"
  alias emacsdk="emacsclient -e '(kill-emacs)'"j

  compdef _files e
  function e {
    $ZDOTDIR/bin/editor-dispatch.zsh --async ${@}
  }
fi

if (( $+commands[ranger] )); then
  alias f=". ranger"
fi

if (( $+commands[fasd] )); then
  alias sd='fasd -sid' # interactive directory selection
  alias sf='fasd -sif' # interactive file selection
  alias j='fasd -e cd -d' # cd, same functionality as j in autojump
fi

# ==============
# Expand aliases
# ==============

# expand aliases on space
function quark-expand-alias {
  emulate -LR zsh -o hist_subst_pattern -o extended_glob
  {
    # hack a local function scope using unfuction
    function quark-expand-alias-smart-space {

      if [[ $RBUFFER[1] != ' ' ]]; then
        zle magic-space
      else
        # we aren't at the end of the line so squeeze spaces
        
        zle forward-char
        while [[ $RBUFFER[1] == " " ]]; do
          zle forward-char
          zle backward-delete-char
        done
      fi
    }

    function quark-alias-smart-expand {
      zparseopts -D -E g=G
      local expansion="${@[2,-1]}"
      local delta=$(($#expansion - $expansion[(i){}] - 1))
      local -i i

      alias ${G:+-g} $1=${expansion/{}/}

      zle _expand_alias
      
      for ((i=0; i < $delta; i++)); do
        zle backward-char
      done
    }

    # skip inside quotes
    local -a match mbegin mend
    for param in $region_highlight; do
      if [[ $param == (#b)[^0-9]#(<->)[^0-9]##(<->)[[:space:]]#(*) ]]; then
        if (($match[2] - $match[1] > 0 && $match[1] > 1)); then
          if [[ $match[3] == ${FAST_HIGHLIGHT_STYLES[double-quoted-argument]} ||
                $match[3] == ${FAST_HIGHLIGHT_STYLES[single-quoted-argument]} ]]; then
            zle magic-space
            return
          fi
        fi
      fi
    done

    local -a cmd
    cmd=(${(@s/;/)LBUFFER:gs/[^\\[:IDENT:]]/;})
    if [[ -n "$command_abbrevs[$cmd[-1]]" && $#cmd == 1 ]]; then
      quark-alias-smart-expand $cmd[-1] "$(${=${(e)command_abbrevs[$cmd[-1]]}})"

    elif [[ -n "$global_abbrevs[$cmd[-1]]" ]]; then
      quark-alias-smart-expand -g $cmd[-1] "$(${=${(e)global_abbrevs[$cmd[-1]]}})"

    elif [[ "${(j: :)cmd}" == *\!* && -n "$aliases[$cmd[-1]]" ]]; then
      LBUFFER="$aliases[$cmd[-1]] "

    elif [[ "$+expand[(r)$cmd[-1]]" != 1 && "$cmd[-1]" != (\\|\"|\')* ]]; then
      zle _expand_alias
      if [[ $1 != no_space ]]; then
        quark-expand-alias-smart-space "$1"
      fi
    else
      if [[ $1 != no_space ]]; then
        quark-expand-alias-smart-space "$1"
      fi
    fi

  } always {
    unfunction "quark-expand-alias-smart-space" "quark-alias-smart-expand"
  }
}

zle -N quark-expand-alias

global_bindkey " " quark-expand-alias
global_bindkey "^ " magic-space
bindkey -M isearch " " magic-space

function quark-post-autocomplete () {
  global_bindkey " " quark-expand-alias
  add-zsh-hook -d precmd quark-post-autocomplete
}

add-zsh-hook precmd quark-post-autocomplete
