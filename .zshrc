#!/bin/zsh

# disable traps until we define them later
TRAPUSR1(){ echo "USR1 called before init!" }
TRAPUSR2(){ echo "USR2 called before init!" }

export ZDOTDIR=~/.zsh.d
if [[ ! -d $ZDOTDIR ]]; then
    mkdir -p $ZDOTDIR
fi

ZPROFILE=$ZDOTDIR/.zprofile

if [[ -f $ZPROFILE ]]; then
    source $ZPROFILE
fi

zstyle :compinstall filename '~/.zshrc'
skip_global_compinit=1
fpath=($ZDOTDIR/completers $fpath)
autoload -Uz compinit && compinit -d $ZDOTDIR/zcompdump
echo -n > $ZDOTDIR/startup.log

source $ZDOTDIR/modules/core.zsh
source $ZDOTDIR/modules/env.zsh
source $ZDOTDIR/modules/zinit.zsh
source $ZDOTDIR/modules/fasd.zsh

if [[ -f $ZDOTDIR/local/early.zsh ]]; then
  source $ZDOTDIR/local/early.zsh
fi

# If not running interactively, try to be as straightforward as
# possible.
if [[ $- != *i* || ! -t 0 ]]; then
    emulate -LR sh
    PS1="$ "
    return
fi

source $ZDOTDIR/modules/options.zsh
source $ZDOTDIR/modules/zshctl.zsh
source $ZDOTDIR/modules/autocomplete.zsh
source $ZDOTDIR/modules/term.zsh
source $ZDOTDIR/modules/aliases.zsh
source $ZDOTDIR/modules/vim.zsh
source $ZDOTDIR/modules/history_search.zsh
source $ZDOTDIR/modules/path_compressor.zsh
source $ZDOTDIR/modules/smart_completion.zsh
source $ZDOTDIR/modules/intel.zsh
source $ZDOTDIR/modules/zstyle.zsh
source $ZDOTDIR/modules/vcs.zsh
source $ZDOTDIR/modules/prompt.zsh
source $ZDOTDIR/modules/g.zsh
source $ZDOTDIR/modules/parser.zsh
source $ZDOTDIR/modules/chpwd.zsh
source $ZDOTDIR/modules/title.zsh
source $ZDOTDIR/modules/bindings.zsh
source $ZDOTDIR/modules/functions.zsh

# and source host specific files
for file in $ZDOTDIR/local/*.zsh(nN); do
  if [[ ${file:t:r} != "early" ]]; then
      source $file
  fi
done
