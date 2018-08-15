export ZPLG_HOME=$ZDOTDIR/.zplugin
# Check if zplug is installed
if [[ ! -d $ZPLG_HOME ]]; then
  mkdir $ZPLG_HOME
  git clone --depth 10 https://github.com/zdharma/zplugin.git $ZPLG_HOME/bin
  chmod og-x $ZPLG_HOME
fi

source $ZPLG_HOME/bin/zplugin.zsh
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin

zplugin ice atload'[[ -f  ${FAST_WORK_DIR}/current_theme.zsh ]] || fast-theme $ZDOTDIR/fsh/custom.ini'
zplugin light zdharma/fast-syntax-highlighting

zplugin ice blockf
zplugin light zsh-users/zsh-completions

zplugin light yonchu/zsh-vcs-prompt

zplugin ice atclone"dircolors -b dircolors.ansi-universal | sed 's/di=36/di=1;30/' > c.zsh" atpull'%atclone' pick'c.zsh'
zplugin light seebi/dircolors-solarized

zplugin ice as'command'
zplugin light clvv/fasd

zplugin light zsh-users/zsh-history-substring-search

zplugin light zsh-users/zaw
zplugin light yonchu/zaw-src-git-log
zplugin light yonchu/zaw-src-git-show-branch

zplugin ice pick'git-escape-magic'
zplugin light knu/zsh-git-escape-magic

zplugin light PythonNut/auto-fu.zsh

zplugin ice pick'async.zsh'
zplugin light mafredri/zsh-async
zplugin ice wait'0' atload'_zsh_autosuggest_start' lucid
zplugin light PythonNut/zsh-autosuggestions
zplugin light willghatch/zsh-hooks
