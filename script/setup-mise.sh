#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/lib.sh
. "$DOTFILES_DIR/script/lib.sh"

DOTFILES_MISE_CONFIG_PATH="$DOTFILES_DIR/.config/mise/global-config.toml"
MISE_CONFIG_PATH="$HOME/.config/mise/config.toml"

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

info "Installing tools from global mise config"
"$MISE_BIN" install --cd "$HOME"

if "$MISE_BIN" which broot >/dev/null 2>&1; then
  info "Installing broot shell function"
  "$MISE_BIN" x -- broot --install
fi

info "mise development environment is ready"
info "Config: $DOTFILES_MISE_CONFIG_PATH"
