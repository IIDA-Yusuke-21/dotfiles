#!/usr/bin/env bash
# shellcheck shell=bash
#
# Shared helpers for the dotfiles setup scripts. Source this file; it is not
# meant to be executed on its own.
#
# Every script links files through link_path so that a single policy applies
# everywhere: an unmanaged file already sitting at the destination is left
# alone and recorded, unless DOTFILES_FORCE is 1, in which case it is moved
# into the backup directory first. Bash cannot export arrays, so each process
# tracks its own skips and calls report_skipped before exiting.

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DOTFILES_BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$DOTFILES_ROOT/.backup}"
DOTFILES_FORCE="${DOTFILES_FORCE:-0}"
DOTFILES_SKIPPED=()

info() {
  printf '==> %s\n' "$*"
}

warn() {
  printf 'WARNING: %s\n' "$*" >&2
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

has() {
  command -v "$1" >/dev/null 2>&1
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

next_backup_path() {
  local path="$1"
  local name
  local timestamp
  local candidate
  local suffix

  name="$(basename "$path")"
  timestamp="$(date +%Y%m%d-%H%M%S)"
  candidate="$DOTFILES_BACKUP_DIR/$name.$timestamp"
  suffix=1

  while [ -e "$candidate" ] || [ -L "$candidate" ]; do
    candidate="$DOTFILES_BACKUP_DIR/$name.$timestamp.$suffix"
    suffix=$((suffix + 1))
  done

  printf '%s\n' "$candidate"
}

backup_existing_path() {
  local path="$1"
  local backup_path

  mkdir -p "$DOTFILES_BACKUP_DIR"
  backup_path="$(next_backup_path "$path")"
  mv "$path" "$backup_path"
  info "Backed up: $path -> $backup_path"
}

# link_path SRC DST
#
# Creates DST as a symlink to SRC, honouring the shared existing-file policy
# described at the top of this file.
link_path() {
  local src="$1"
  local dst="$2"

  [ -e "$src" ] || die "source file not found: $src"
  mkdir -p "$(dirname "$dst")"

  if is_link_to "$dst" "$src"; then
    info "Already linked: $dst -> $src"
    return 0
  fi

  if [ -e "$dst" ] || [ -L "$dst" ]; then
    if [ "$DOTFILES_FORCE" -eq 1 ]; then
      backup_existing_path "$dst"
    else
      printf 'Skip existing path: %s\n' "$dst" >&2
      DOTFILES_SKIPPED+=("$dst")
      return 0
    fi
  fi

  ln -s "$src" "$dst"
  info "Linked: $dst -> $src"
}

# report_skipped [COMMAND]
#
# Lists every path link_path refused to overwrite and returns 1 so the caller
# can exit non-zero. Returns 0 when nothing was skipped. COMMAND is the command
# suggested in the hint, and defaults to the running script.
report_skipped() {
  local command="${1:-$0}"
  local path

  [ "${#DOTFILES_SKIPPED[@]}" -gt 0 ] || return 0

  {
    printf '\nWARNING: %d path(s) were not linked because something already exists there:\n' \
      "${#DOTFILES_SKIPPED[@]}"
    for path in "${DOTFILES_SKIPPED[@]}"; do
      printf '  %s\n' "$path"
    done
    printf 'Move or remove them, or re-run with --force to back them up and replace them:\n'
    printf '  %s --force\n' "$command"
  } >&2

  return 1
}

resolve_mise() {
  if has mise; then
    command -v mise
    return 0
  fi

  if [ -x "$HOME/.local/bin/mise" ]; then
    printf '%s\n' "$HOME/.local/bin/mise"
    return 0
  fi

  if [ -x "$HOME/.mise/bin/mise" ]; then
    printf '%s\n' "$HOME/.mise/bin/mise"
    return 0
  fi

  return 1
}
