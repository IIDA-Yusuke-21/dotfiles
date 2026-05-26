#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOTFILES_MISE_CONFIG_PATH="$DOTFILES_DIR/.config/mise/config.global.toml"
MISE_CONFIG_PATH="$HOME/.config/mise/config.toml"

info() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

has() {
  command -v "$1" >/dev/null 2>&1
}

resolve_mise() {
  if has mise; then
    command -v mise
    return
  fi

  if [ -x "$HOME/.local/bin/mise" ]; then
    printf '%s\n' "$HOME/.local/bin/mise"
    return
  fi

  if [ -x "$HOME/.mise/bin/mise" ]; then
    printf '%s\n' "$HOME/.mise/bin/mise"
    return
  fi

  return 1
}

install_mise() {
  if MISE_BIN="$(resolve_mise)"; then
    info "mise is already installed: $MISE_BIN"
    return
  fi

  has curl || die "curl is required to install mise"

  info "Installing mise"
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$HOME/.mise/bin:$PATH"
  hash -r || true

  MISE_BIN="$(resolve_mise)" || die "mise was installed, but is not available"
}

install_mise

if [ -e "$MISE_CONFIG_PATH" ] || [ -L "$MISE_CONFIG_PATH" ]; then
  info "Trusting mise config"
  "$MISE_BIN" trust "$MISE_CONFIG_PATH" >/dev/null
fi

info "Installing tools from mise config"
"$MISE_BIN" install

info "mise development environment is ready"
info "Config: $DOTFILES_MISE_CONFIG_PATH"
