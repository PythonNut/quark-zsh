local -A ZINIT
ZINIT[HOME_DIR]=$ZDOTDIR/zinit

ZINIT[BIN_DIR]=${ZINIT[HOME_DIR]}/bin
ZINIT[PLUGIN_DIR]=${ZINIT[HOME_DIR]}/plugins
ZINIT[COMPLETIONS_DIR]=${ZINIT[HOME_DIR]}/completions
ZINIT[SNIPPETS_DIR]=${ZINIT[HOME_DIR]}/snippets
ZPFX=${ZINIT[HOME_DIR]}/polaris

# Check if zplug is installed
if [[ ! -d ${ZINIT[HOME_DIR]} ]]; then
  mkdir ${ZINIT[HOME_DIR]}
  git clone --depth 10 https://github.com/zdharma/zinit.git ${ZINIT[HOME_DIR]}/bin
  chmod og-x ${ZINIT[HOME_DIR]}
fi

source ${ZINIT[HOME_DIR]}/bin/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

zinit light hlissner/zsh-autopair

zinit ice atload'[[ -f  ${FAST_WORK_DIR}/current_theme.zsh ]] || fast-theme $ZDOTDIR/fsh/custom.ini'
zinit light zdharma/fast-syntax-highlighting

zinit ice blockf
zinit light zsh-users/zsh-completions
zinit ice as"completion"
zinit light esc/conda-zsh-completion
autoload _conda
compdef _conda conda

zinit light yonchu/zsh-vcs-prompt

zinit ice atclone"dircolors -b dircolors.ansi-universal | sed 's/di=36/di=1;30/' > c.zsh" atpull'%atclone' pick'c.zsh'
zinit light seebi/dircolors-solarized

zinit ice as'command'
zinit light clvv/fasd

zinit light zsh-users/zsh-history-substring-search

zinit light zsh-users/zaw
zinit light yonchu/zaw-src-git-log
zinit light yonchu/zaw-src-git-show-branch

zinit ice pick'git-escape-magic'
zinit light knu/zsh-git-escape-magic

zinit ice pick'async.zsh'
zinit light mafredri/zsh-async
zinit ice atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions
zinit light marlonrichert/zsh-autocomplete
zinit light willghatch/zsh-hooks
