#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=script/lib.sh
. "$DOTFILES_DIR/script/lib.sh"

case "$(uname -r)" in
  *[Mm]icrosoft*) ;;
  *)
    info "Skipping Windows IME helper outside WSL"
    exit 0
    ;;
esac

MISE_BIN="$(resolve_mise)" || die "mise is required to build the Windows IME helper"
IME_OFF_BUILD_DIR="$(mktemp -d)"
IME_OFF_INSTALL_PATH="$HOME/.local/bin/ime-off.exe"

cleanup() {
  rm -rf "$IME_OFF_BUILD_DIR"
}
trap cleanup EXIT

info "Building Windows IME helper"
(
  cd "$DOTFILES_DIR/script/ime-off"
  env \
    GOOS=windows \
    GOARCH=amd64 \
    CGO_ENABLED=0 \
    GOCACHE="$IME_OFF_BUILD_DIR/cache" \
    "$MISE_BIN" x -- go build \
      -buildvcs=false \
      -trimpath \
      -ldflags="-s -w -H=windowsgui" \
      -o "$IME_OFF_BUILD_DIR/ime-off.exe" \
      .
)

mkdir -p "$(dirname "$IME_OFF_INSTALL_PATH")"
install -m 0755 "$IME_OFF_BUILD_DIR/ime-off.exe" "$IME_OFF_INSTALL_PATH"
info "Installed Windows IME helper: $IME_OFF_INSTALL_PATH"
