if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
	source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

unsetopt BEEP
unsetopt LIST_BEEP

export PATH="$HOME/.local/bin:$PATH"

bindkey "^[[1;5D" backward-word        # Ctrl+Left
bindkey "^[[1;5C" forward-word         # Ctrl+Right
bindkey "^H"      backward-kill-word   # Ctrl+Backspace
bindkey "^[[3;5~" kill-word            # Ctrl+Delete

function _shift-select-start() { ((REGION_ACTIVE)) || zle set-mark-command }
function _shift-select-end()   { REGION_ACTIVE=1 }

function shift-select-left()       { _shift-select-start; zle backward-char;         _shift-select-end }
function shift-select-right()      { _shift-select-start; zle forward-char;          _shift-select-end }
function shift-select-up()         { _shift-select-start; zle up-line-or-history;    _shift-select-end }
function shift-select-down()       { _shift-select-start; zle down-line-or-history;  _shift-select-end }
function shift-select-home()       { _shift-select-start; zle beginning-of-line;     _shift-select-end }
function shift-select-end-key()    { _shift-select-start; zle end-of-line;           _shift-select-end }
function shift-select-word-left()  { _shift-select-start; zle backward-word;         _shift-select-end }
function shift-select-word-right() { _shift-select-start; zle forward-word;          _shift-select-end }
for _w in shift-select-{left,right,up,down,home,end-key,word-left,word-right}; do
    zle -N "$_w"
done
unset _w

function _self-insert-replacing() {
    if ((REGION_ACTIVE)); then zle kill-region; fi
    zle .self-insert
}
zle -N self-insert _self-insert-replacing

function _backward-delete-or-region() {
    if ((REGION_ACTIVE)); then zle kill-region
    else                       zle .backward-delete-char; fi
}
zle -N backward-delete-char _backward-delete-or-region

bindkey "^[[1;2D" shift-select-left         # Shift+Left
bindkey "^[[1;2C" shift-select-right        # Shift+Right
bindkey "^[[1;2A" shift-select-up           # Shift+Up
bindkey "^[[1;2B" shift-select-down         # Shift+Down
bindkey "^[[1;2H" shift-select-home         # Shift+Home
bindkey "^[[1;2F" shift-select-end-key      # Shift+End
bindkey "^[[1;6D" shift-select-word-left    # Shift+Ctrl+Left
bindkey "^[[1;6C" shift-select-word-right   # Shift+Ctrl+Right

[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh   ]] && source /usr/share/fzf/completion.zsh

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

command -v atuin  >/dev/null 2>&1 && eval "$(atuin init zsh --disable-up-arrow)"
bindkey "^[[1;5A" atuin-up-search

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Tint
ZSH_AUTOSUGGEST_HIGHLIGT_STYULE="fg=#a5adce"

# Powerlevel10k
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme

[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh



# DIR
typeset -g POWERLEVEL9K_DIR_FOREGROUND='#818cf8'
typeset -g POWERLEVEL9K_DIR_SHORTENED_FOREGROUND='#a5adce'
typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGORUND='#5eead4'
typeset -g POWERLEVEL9K_DIR_NOT_WRITABLE_FOREGROUND='#f87171'
typeset -g POWERLEVEL9K_DIR_NON_EXISTENT_FOREGROUND='#f87171'

# VCS
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND='#5eead4'
typeset -g POWERLEVEL9K_VCS_UNTRACKED_FOREGROUND='#5eead4'
typeset -g POWERLEVEL9K_VCS_MODIFIED_FOREGROUND='#818cf8'

# Status
typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND='#5eead4'
typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND='#5eead4'
typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND='#f87171'
typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND='#f87171'
typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND='#f87171'
p10k reload 2>/dev/null

# Syntax Highlighting

typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[default]='fg=#c6d0f5'                 
ZSH_HIGHLIGHT_STYLES[command]='fg=#5eead4'                 
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#5eead4'               
ZSH_HIGHLIGHT_STYLES[function]='fg=#5eead4'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#5eead4'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f87171'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#818cf8'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#818cf8'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#818cf8'
ZSH_HIGHLIGHT_STYLES[command-substitution]='fg=#5eead4'
ZSH_HIGHLIGHT_STYLES[path]='fg=#c6d0f5,underline'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#a5adce'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#a5adce'
ZSH_HIGHLIGHT_STYLES[comment]='fg=#a5adce'

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
