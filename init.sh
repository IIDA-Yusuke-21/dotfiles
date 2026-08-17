#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=script/lib.sh
. "$DOTFILES_DIR/script/lib.sh"

RUN_MISE=1

usage() {
  cat <<'EOF'
Usage: ./init.sh [--links-only] [--force]

Install dotfile symlinks, configure bash, and set up development tools with mise.

Options:
  --links-only   Only install symlinks; skip bash and mise setup.
  --force        Back up existing unmanaged files to .backup/ and replace them,
                 instead of skipping them.
  -h, --help     Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --links-only)
      RUN_MISE=0
      ;;
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

# The helper scripts run as separate processes and need the same policy.
export DOTFILES_FORCE DOTFILES_BACKUP_DIR

status=0

# setup-tmux.sh reports its own skipped paths and exits non-zero for them, so
# record the failure instead of aborting the rest of the setup.
"$DOTFILES_DIR/script/setup-tmux.sh" || status=1

link_path "$DOTFILES_DIR/.bashrc" "$HOME/.config/dotfiles/bashrc"
link_path "$DOTFILES_DIR/.nanorc" "$HOME/.nanorc"
link_path "$DOTFILES_DIR/.config/mise/global-config.toml" "$HOME/.config/mise/config.toml"
link_path "$DOTFILES_DIR/.config/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link_path "$DOTFILES_DIR/.config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

if [ "$RUN_MISE" -eq 1 ]; then
  "$DOTFILES_DIR/script/setup-mise.sh"
  "$DOTFILES_DIR/script/setup-ime-off.sh"
  "$DOTFILES_DIR/script/setup-bashrc.sh"
fi

report_skipped "./init.sh" || status=1

exit "$status"
