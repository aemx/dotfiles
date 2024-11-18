# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

# Search engines
ZSH_WEB_SEARCH_ENGINES=(
  netid "https://my.engr.illinois.edu/usersearch/index.asp?search="
  atlas "https://uofi.atlassian.net/wiki/search?text="
)

# Add in snippets
zinit snippet OMZL::clipboard.zsh
zinit snippet OMZL::directories.zsh
zinit snippet OMZL::functions.zsh
zinit snippet OMZL::termsupport.zsh
zinit snippet OMZP::extract
zinit snippet OMZP::git
zinit snippet OMZP::gitignore
zinit snippet OMZP::tldr
zinit snippet OMZP::sudo
zinit snippet OMZP::web-search

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Mute beeps
unsetopt BEEP

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select

# Shell integrations
eval "$(fzf --zsh)"

# Functions
fpath=(~/.zshfx $fpath);
autoload -U $fpath[1]/*(.:t)

# Aliases: General
alias ls='ls --color=auto'
alias c='clear'
alias home='cd ~'
alias zshrc='code ~/.zshrc'
alias zshfx='code ~/.zshfx'

# Aliases: Websearch
alias yt='youtube'
alias wolfram='wolframalpha'

# Aliases: Package management
alias arch_update='sudo pacman -Syu'
alias pacin='sudo pacman -S'
alias pacun='sudo pacman -Rcns'
alias aurin='paru -S'
alias aurun='paru -Rcns'

# Aliases: Programs
alias py='"/c/Program Files/Python310/python.exe"'
alias pip="py -m pip"
alias pipin='py -m pip install'
alias pipun='py -m pip uninstall'
alias exiftool="~/util/exiftool/exiftool.exe"

# Aliases: Instant run
alias chatter="cd ~/code/sites/chatter && npm run dev"
alias dalle='for file in *; do mv "$file" "${file:0:26}.png"; done'
alias package='~/itg/package.sh'

# Aliases: NPM
alias npmi='npm install'
alias run='npm run'
alias dev='npm run dev'
alias deploy='npm run deploy'
alias redev='npm run redev'
alias update="ncu -i"
#alias rev="printf 'Build %04d\n' $(git rev-list --count main)"

# Aliases: RPL directories
alias rpl='cd ~/code/rpl'
alias www='cd ~/code/rpl/www'

# Init omp
eval "$(oh-my-posh init zsh --config ~/.config/oh-my-posh/theme.json)"