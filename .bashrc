if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash)"
elif [ -x "$HOME/.mise/bin/mise" ]; then
  eval "$("$HOME/.mise/bin/mise" activate bash)"
fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi

export EDITOR="vim"
export VISUAL="vim"

eval "$(zoxide init bash)"

export FZF_DEFAULT_OPTS='--preview "file --mime-type -b {} | grep -q ^image/ && chafa --size ${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES} {} || bat --color=always --style=header,grid --line-range :100 {}"'
