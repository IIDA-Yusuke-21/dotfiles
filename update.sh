#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=script/lib.sh
. "$DOTFILES_DIR/script/lib.sh"

BUMP=0
PRUNE=0

usage() {
  cat <<'EOF'
Usage: ./update.sh [--bump] [--prune]

Sync the mise configuration, update mise itself, and upgrade managed tools.

Every tool in .config/mise/global-config.toml is pinned to an exact version, so
a plain "mise upgrade" has nothing to do. Use --bump to move the pins forward;
the new versions show up as a diff you can review and commit.

Options:
  --bump       Upgrade tools to the latest available versions and rewrite the
               pinned versions in .config/mise/global-config.toml.
  --prune      Delete installed tool versions that no config references any
               more. Without this flag they are only reported.
  -h, --help   Show this help.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --bump)
      BUMP=1
      ;;
    --prune)
      PRUNE=1
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

self_update_mise() {
  info "Self updating mise..."

  # Distro packages of mise disable self-update so that the package manager
  # stays in charge; that is not a reason to abort the rest of the update.
  if ! "$MISE_BIN" self-update --yes; then
    warn "mise self-update failed; mise may be managed by a package manager. Continuing."
  fi
}

upgrade_tools() {
  if [ "$BUMP" -eq 1 ]; then
    info "Upgrading tools and bumping the pinned versions..."
    "$MISE_BIN" upgrade --bump
    info "Review the new pins with:"
    info "  git -C $DOTFILES_DIR diff .config/mise/global-config.toml"
    return
  fi

  info "Upgrading tools within their pinned versions..."
  "$MISE_BIN" upgrade
  info "Versions are pinned exactly, so nothing moves unless you pass --bump."
}

prune_tools() {
  if [ "$PRUNE" -eq 1 ]; then
    info "Pruning unused tool versions..."
    "$MISE_BIN" prune
    return
  fi

  # --dry-run-code exits non-zero when there is something to prune.
  if "$MISE_BIN" prune --dry-run-code >/dev/null 2>&1; then
    info "No unused tool versions installed."
    return
  fi

  info "Unused tool versions are installed:"
  "$MISE_BIN" ls --prunable || true
  info "Remove them with: ./update.sh --prune"
}

check_tmux_submodule() {
  local tmux_dir="$DOTFILES_DIR/.tmux"
  local current
  local latest
  local behind

  has git || return 0

  if [ ! -e "$tmux_dir/.git" ]; then
    info "oh-my-tmux submodule is not initialized; skipping check."
    return 0
  fi

  info "Checking oh-my-tmux submodule..."

  if ! git -C "$tmux_dir" fetch --quiet origin 2>/dev/null; then
    warn "Could not reach the oh-my-tmux remote; skipping check."
    return 0
  fi

  current="$(git -C "$tmux_dir" rev-parse HEAD)"
  latest="$(git -C "$tmux_dir" rev-parse FETCH_HEAD)"

  if [ "$current" = "$latest" ]; then
    info "oh-my-tmux is up to date."
    return 0
  fi

  behind="$(git -C "$tmux_dir" rev-list --count "$current..$latest" 2>/dev/null || printf '?')"
  info "oh-my-tmux has updates available ($behind commit(s) behind)."
  info "  .tmux.conf.local is a fork of the upstream template, so check what"
  info "  changed upstream before updating:"
  info "    git -C $DOTFILES_DIR submodule update --remote .tmux"
}

info "Syncing mise configuration..."
"$DOTFILES_DIR/sync-mise.sh"

MISE_BIN="$(resolve_mise)" || die "mise is not installed. Please run ./init.sh first."

self_update_mise
upgrade_tools
prune_tools
check_tmux_submodule

info "Update complete!"
