#!/usr/bin/env bash
set -euo pipefail

BASHRC_PATH="${BASHRC_PATH:-$HOME/.bashrc}"
DOTFILES_BASHRC_PATH="${DOTFILES_BASHRC_PATH:-$HOME/.config/dotfiles/bashrc}"

info() {
  printf '==> %s\n' "$*"
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

prepare_bashrc_path() {
  mkdir -p "$(dirname "$BASHRC_PATH")"

  if [ -e "$BASHRC_PATH" ] && [ ! -f "$BASHRC_PATH" ]; then
    die "not a regular file: $BASHRC_PATH"
  fi
}

extract_block() {
  local begin_marker="$1"
  local end_marker="$2"
  # The awk program is passed verbatim; $0 belongs to awk, not to the shell.
  # shellcheck disable=SC2016
  local awk_script='
    $0 == begin_marker {
      in_block = 1
    }
    in_block {
      print
    }
    $0 == end_marker && in_block {
      exit
    }
  '

  [ -f "$BASHRC_PATH" ] || return 1
  grep -Fq "$begin_marker" "$BASHRC_PATH" || return 1
  awk \
    -v begin_marker="$begin_marker" \
    -v end_marker="$end_marker" \
    "$awk_script" \
    "$BASHRC_PATH"
}

remove_block() {
  local begin_marker="$1"
  local end_marker="$2"
  local tmp_file

  [ -f "$BASHRC_PATH" ] || return 0
  grep -Fq "$begin_marker" "$BASHRC_PATH" || return 0

  tmp_file="$(mktemp)"
  awk \
    -v begin_marker="$begin_marker" \
    -v end_marker="$end_marker" \
    '
      $0 == begin_marker {
        in_block = 1
        next
      }
      $0 == end_marker && in_block {
        in_block = 0
        next
      }
      !in_block {
        print
      }
    ' \
    "$BASHRC_PATH" > "$tmp_file"
  mv "$tmp_file" "$BASHRC_PATH"
}

ensure_block() {
  local begin_marker="$1"
  local end_marker="$2"
  local content="$3"
  local expected
  local existing

  prepare_bashrc_path
  expected="$(printf '%s\n%s\n%s' "$begin_marker" "$content" "$end_marker")"
  existing="$(extract_block "$begin_marker" "$end_marker" || true)"

  if [ "$existing" = "$expected" ]; then
    info "Already configured: $BASHRC_PATH"
    return
  fi

  remove_block "$begin_marker" "$end_marker"

  {
    printf '\n%s\n' "$begin_marker"
    printf '%s\n' "$content"
    printf '%s\n' "$end_marker"
  } >> "$BASHRC_PATH"

  info "Configured: $BASHRC_PATH"
}

setup_dotfiles_bashrc() {
  [ -f "$DOTFILES_BASHRC_PATH" ] || die "managed bashrc not found: $DOTFILES_BASHRC_PATH"

  # $HOME must stay literal: it is written into ~/.bashrc and expanded when
  # that file is sourced, not now.
  # shellcheck disable=SC2016
  ensure_block \
    '# >>> dotfiles bashrc >>>' \
    '# <<< dotfiles bashrc <<<' \
    'if [ -f "$HOME/.config/dotfiles/bashrc" ]; then
  . "$HOME/.config/dotfiles/bashrc"
fi'
}

setup_history_sync() {
  ensure_block \
    '# >>> dotfiles history sync >>>' \
    '# <<< dotfiles history sync <<<' \
    'if declare -F __enable_history_sync >/dev/null; then
  __enable_history_sync
fi'
}

setup_dotfiles_bashrc
setup_history_sync
