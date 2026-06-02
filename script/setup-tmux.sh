#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$DOTFILES_DIR/.backup}"
TMUX_REPO_DIR="$DOTFILES_DIR/.tmux"
TMUX_CONF_SRC="$TMUX_REPO_DIR/.tmux.conf"
TMUX_CONF_LOCAL_SRC="$DOTFILES_DIR/.tmux.conf.local"
TMUX_CONF_DST="$HOME/.tmux.conf"
TMUX_CONF_LOCAL_DST="$HOME/.tmux.conf.local"

info() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

canonical_path() {
  readlink -f "$1"
}

is_link_to() {
  local dst="$1"
  local src="$2"

  [ -L "$dst" ] || return 1
  [ "$(canonical_path "$dst")" = "$(canonical_path "$src")" ]
}

is_oh_my_tmux_conf_link() {
  local dst="$1"
  local resolved

  [ -L "$dst" ] || return 1
  resolved="$(canonical_path "$dst")"
  [ "$(basename "$resolved")" = ".tmux.conf" ] || return 1
  [ "$(basename "$(dirname "$resolved")")" = ".tmux" ]
}

next_backup_path() {
  local path="$1"
  local name
  local timestamp
  local candidate
  local suffix

  name="$(basename "$path")"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  candidate="$BACKUP_DIR/$name.$timestamp"
  suffix=1

  while [ -e "$candidate" ] || [ -L "$candidate" ]; do
    candidate="$BACKUP_DIR/$name.$timestamp.$suffix"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate"
}

backup_existing_path() {
  local path="$1"
  local backup_path

  mkdir -p "$BACKUP_DIR"
  backup_path="$(next_backup_path "$path")"
  mv "$path" "$backup_path"
  info "Backed up: $path -> $backup_path"
}

link_path() {
  local src="$1"
  local dst="$2"

  [ -f "$src" ] || die "source file not found: $src"
  mkdir -p "$(dirname "$dst")"

  if is_link_to "$dst" "$src"; then
    info "Already linked: $dst -> $src"
    return
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    backup_existing_path "$dst"
  fi

  ln -s "$src" "$dst"
  info "Linked: $dst -> $src"
}

link_tmux_conf() {
  [ -f "$TMUX_CONF_SRC" ] || die "tmux submodule is not initialized: $TMUX_CONF_SRC"
  mkdir -p "$(dirname "$TMUX_CONF_DST")"

  if is_link_to "$TMUX_CONF_DST" "$TMUX_CONF_SRC"; then
    info "Already linked: $TMUX_CONF_DST -> $TMUX_CONF_SRC"
    return
  fi

  if [ -e "$TMUX_CONF_DST" ] || [ -L "$TMUX_CONF_DST" ]; then
    if is_oh_my_tmux_conf_link "$TMUX_CONF_DST"; then
      unlink "$TMUX_CONF_DST"
      info "Replaced existing Oh my tmux link without backup: $TMUX_CONF_DST"
    else
      backup_existing_path "$TMUX_CONF_DST"
    fi
  fi

  ln -s "$TMUX_CONF_SRC" "$TMUX_CONF_DST"
  info "Linked: $TMUX_CONF_DST -> $TMUX_CONF_SRC"
}

link_tmux_conf
link_path "$TMUX_CONF_LOCAL_SRC" "$TMUX_CONF_LOCAL_DST"
