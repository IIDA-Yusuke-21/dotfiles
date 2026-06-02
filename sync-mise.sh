#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_MISE_CONFIG_PATH="$DOTFILES_DIR/.config/mise/global-config.toml"
MISE_CONFIG_PATH="$HOME/.config/mise/config.toml"

usage() {
  cat <<'EOF'
Usage: ./sync-mise.sh

Link the repository-managed mise config into $HOME and install newly added tools.
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

link_mise_config() {
  local dst_dir

  dst_dir="$(dirname "$MISE_CONFIG_PATH")"
  mkdir -p "$dst_dir"

  if [ -L "$MISE_CONFIG_PATH" ] && [ "$(readlink "$MISE_CONFIG_PATH")" = "$DOTFILES_MISE_CONFIG_PATH" ]; then
    printf 'Already linked: %s -> %s\n' "$MISE_CONFIG_PATH" "$DOTFILES_MISE_CONFIG_PATH"
    return
  fi

  if [ -e "$MISE_CONFIG_PATH" ] || [ -L "$MISE_CONFIG_PATH" ]; then
    die "existing path is not managed by this repository: $MISE_CONFIG_PATH"
  fi

  ln -s "$DOTFILES_MISE_CONFIG_PATH" "$MISE_CONFIG_PATH"
  printf 'Linked: %s -> %s\n' "$MISE_CONFIG_PATH" "$DOTFILES_MISE_CONFIG_PATH"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

[ -f "$DOTFILES_MISE_CONFIG_PATH" ] || die "managed mise config not found: $DOTFILES_MISE_CONFIG_PATH"

link_mise_config
"$DOTFILES_DIR/script/setup-mise.sh"
