#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=script/lib.sh
. "$DOTFILES_DIR/script/lib.sh"

DOTFILES_MISE_CONFIG_PATH="$DOTFILES_DIR/.config/mise/global-config.toml"
MISE_CONFIG_PATH="$HOME/.config/mise/config.toml"

usage() {
  cat <<'EOF'
Usage: ./sync-mise.sh [--force]

Link the repository-managed mise config into $HOME and install newly added tools.

Options:
  --force      Back up an existing unmanaged config to .backup/ and replace it,
               instead of skipping it.
  -h, --help   Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --force)
      DOTFILES_FORCE=1
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

export DOTFILES_FORCE DOTFILES_BACKUP_DIR

[ -f "$DOTFILES_MISE_CONFIG_PATH" ] || die "managed mise config not found: $DOTFILES_MISE_CONFIG_PATH"

link_path "$DOTFILES_MISE_CONFIG_PATH" "$MISE_CONFIG_PATH"

# Installing tools from an unmanaged config would pull in the wrong versions,
# so stop before setup-mise.sh when the link was not created.
report_skipped "./sync-mise.sh" || exit 1

"$DOTFILES_DIR/script/setup-mise.sh"
