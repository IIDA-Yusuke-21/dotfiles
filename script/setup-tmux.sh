#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/lib.sh
. "$DOTFILES_DIR/script/lib.sh"

TMUX_REPO_DIR="$DOTFILES_DIR/.tmux"
TMUX_CONF_SRC="$TMUX_REPO_DIR/.tmux.conf"
TMUX_CONF_LOCAL_SRC="$DOTFILES_DIR/.tmux.conf.local"
TMUX_CONF_DST="$HOME/.tmux.conf"
TMUX_CONF_LOCAL_DST="$HOME/.tmux.conf.local"

is_oh_my_tmux_conf_link() {
  local dst="$1"
  local resolved

  [ -L "$dst" ] || return 1
  resolved="$(canonical_path "$dst")"
  [ "$(basename "$resolved")" = ".tmux.conf" ] || return 1
  [ "$(basename "$(dirname "$resolved")")" = ".tmux" ]
}

link_tmux_conf() {
  [ -f "$TMUX_CONF_SRC" ] || die "tmux submodule is not initialized: $TMUX_CONF_SRC"

  # A $HOME/.tmux.conf that already points at another Oh my tmux! checkout is
  # a copy of the same upstream file and holds no user data, so drop it up
  # front rather than making link_path back it up or skip it.
  if ! is_link_to "$TMUX_CONF_DST" "$TMUX_CONF_SRC" &&
    is_oh_my_tmux_conf_link "$TMUX_CONF_DST"; then
    unlink "$TMUX_CONF_DST"
    info "Replaced existing Oh my tmux link without backup: $TMUX_CONF_DST"
  fi

  link_path "$TMUX_CONF_SRC" "$TMUX_CONF_DST"
}

link_tmux_conf
link_path "$TMUX_CONF_LOCAL_SRC" "$TMUX_CONF_LOCAL_DST"

report_skipped "./init.sh"
