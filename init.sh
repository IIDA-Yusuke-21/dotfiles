#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_MISE=1

usage() {
  cat <<'EOF'
Usage: ./init.sh [--links-only]

Install dotfile symlinks, configure bash, and set up development tools with mise.

Options:
  --links-only   Only install symlinks; skip bash and mise setup.
  -h, --help     Show this help.
EOF
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

link_file() {
  local src="$1"
  local dst="$2"
  local dst_dir

  dst_dir="$(dirname "$dst")"
  mkdir -p "$dst_dir"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    printf 'Already linked: %s -> %s\n' "$dst" "$src"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    printf 'Skip existing path: %s\n' "$dst" >&2
    return
  fi

  ln -s "$src" "$dst"
  printf 'Linked: %s -> %s\n' "$dst" "$src"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --links-only)
      RUN_MISE=0
      ;;
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

"$DOTFILES_DIR/script/setup-tmux.sh"
link_file "$DOTFILES_DIR/.bashrc" "$HOME/.config/dotfiles/bashrc"
link_file "$DOTFILES_DIR/.nanorc" "$HOME/.nanorc"
link_file "$DOTFILES_DIR/.config/mise/global-config.toml" "$HOME/.config/mise/config.toml"

if [ "$RUN_MISE" -eq 1 ]; then
  "$DOTFILES_DIR/script/setup-mise.sh"
  "$DOTFILES_DIR/script/setup-bashrc.sh"
fi
