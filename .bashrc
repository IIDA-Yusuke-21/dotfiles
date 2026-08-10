# shellcheck shell=bash

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

export EDITOR="nvim"
export VISUAL="nvim"

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi

# Preview images with chafa when it is available (chafa is not installable via
# mise, so treat it as an optional OS package), otherwise fall back to bat and
# finally to head so the preview never breaks on a bare machine.
# The $FZF_PREVIEW_* variables must stay unexpanded here: fzf substitutes them
# when it runs the preview command, not when this file is sourced.
# shellcheck disable=SC2016
export FZF_DEFAULT_OPTS='--preview "if file --mime-type -b {} | grep -q ^image/ && command -v chafa >/dev/null 2>&1; then chafa --size ${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES} {}; elif command -v bat >/dev/null 2>&1; then bat --color=always --style=header,grid --line-range :100 {}; else head -n 100 {}; fi"'
