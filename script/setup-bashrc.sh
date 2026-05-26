#!/usr/bin/env bash
set -euo pipefail

BASHRC_PATH="${BASHRC_PATH:-$HOME/.bashrc}"

info() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

append_block() {
  local begin_marker="$1"
  local end_marker="$2"
  local content="$3"

  mkdir -p "$(dirname "$BASHRC_PATH")"

  if [ -e "$BASHRC_PATH" ] && [ ! -f "$BASHRC_PATH" ]; then
    die "not a regular file: $BASHRC_PATH"
  fi

  if [ -f "$BASHRC_PATH" ] && grep -Fq "$begin_marker" "$BASHRC_PATH"; then
    info "Already configured: $BASHRC_PATH"
    return
  fi

  {
    printf '\n%s\n' "$begin_marker"
    printf '%s\n' "$content"
    printf '%s\n' "$end_marker"
  } >> "$BASHRC_PATH"

  info "Configured: $BASHRC_PATH"
}

setup_mise_fzf() {
  append_block \
    '# >>> dotfiles mise/fzf >>>' \
    '# <<< dotfiles mise/fzf <<<' \
    'if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
elif [ -x "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash)"
elif [ -x "$HOME/.mise/bin/mise" ]; then
  eval "$("$HOME/.mise/bin/mise" activate bash)"
fi

if command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --bash)"
fi'
}

setup_mise_fzf
