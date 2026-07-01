#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

info "Syncing mise configuration..."
"$DOTFILES_DIR/sync-mise.sh"

MISE_BIN="$(resolve_mise)" || die "mise is not installed. Please run ./init.sh first."

info "Self updating mise..."
"$MISE_BIN" self-update

info "Upgrading mise-managed tools..."
"$MISE_BIN" upgrade

info "Update complete!"
