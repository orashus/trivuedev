#!/bin/sh
# trivuedev public installer
# Downloads a release binary from github.com/orashus/trivuedev and verifies checksums.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/orashus/trivuedev/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/orashus/trivuedev/main/install.sh | TRIVUEDEV_VERSION=v0.1.0 sh
#   TRIVUEDEV_INSTALL_DIR="$HOME/.local/bin" sh install.sh
#
# Inspect before running:
#   curl -fsSL https://raw.githubusercontent.com/orashus/trivuedev/main/install.sh -o install.sh
#   less install.sh
#   sh install.sh

set -eu

REPO="orashus/trivuedev"
BASE_URL="https://github.com/${REPO}/releases"
INSTALL_DIR="${TRIVUEDEV_INSTALL_DIR:-${HOME}/.local/bin}"
VERSION="${TRIVUEDEV_VERSION:-}"

say() {
  printf '%s\n' "$*"
}

err() {
  printf 'trivuedev install: %s\n' "$*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || err "required command not found: $1"
}

detect_os() {
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  case "$os" in
    linux) printf 'linux\n' ;;
    darwin) printf 'darwin\n' ;;
    *) err "unsupported OS: $os (supported: linux, darwin). For Windows use install.ps1." ;;
  esac
}

detect_arch() {
  arch="$(uname -m)"
  case "$arch" in
    x86_64|amd64) printf 'amd64\n' ;;
    aarch64|arm64) printf 'arm64\n' ;;
    *) err "unsupported architecture: $arch (supported: amd64, arm64)" ;;
  esac
}

latest_version() {
  need_cmd curl
  # Prefer the GitHub API; fall back to Releases "latest" redirect.
  if tag="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)" \
    && [ -n "$tag" ]; then
    printf '%s\n' "$tag"
    return 0
  fi
  loc="$(curl -fsSI -o /dev/null -w '%{url_effective}' "${BASE_URL}/latest")" || err "could not resolve latest release"
  tag="$(printf '%s\n' "$loc" | sed -n 's|.*/tag/\([^/]*\)$|\1|p')"
  [ -n "$tag" ] || err "could not resolve latest release tag"
  printf '%s\n' "$tag"
}

sha256_file() {
  file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$file" | awk '{print $1}'
  else
    err "need sha256sum or shasum to verify checksums"
  fi
}

verify_checksum() {
  archive="$1"
  checksums="$2"
  base="$(basename "$archive")"
  expected="$(awk -v f="$base" '$2 == f { print $1; exit }' "$checksums")"
  [ -n "$expected" ] || err "checksum entry not found for ${base}"
  actual="$(sha256_file "$archive")"
  [ "$actual" = "$expected" ] || err "checksum mismatch for ${base} (expected ${expected}, got ${actual})"
  say "Checksum OK for ${base}"
}

main() {
  need_cmd curl
  need_cmd tar
  need_cmd uname
  need_cmd mktemp
  need_cmd mkdir
  need_cmd mv
  need_cmd chmod

  OS="$(detect_os)"
  ARCH="$(detect_arch)"

  if [ -z "$VERSION" ]; then
    VERSION="$(latest_version)"
  fi

  case "$VERSION" in
    v*) ;;
    *) VERSION="v${VERSION}" ;;
  esac

  asset="trivuedev_${VERSION}_${OS}_${ARCH}.tar.gz"
  url="${BASE_URL}/download/${VERSION}/${asset}"
  sums_url="${BASE_URL}/download/${VERSION}/checksums.txt"

  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT INT TERM

  say "Installing trivuedev ${VERSION} (${OS}/${ARCH})"
  say "Download: ${url}"

  curl -fL --retry 3 --retry-delay 1 -o "${tmp}/${asset}" "$url" || err "download failed: ${url}"
  curl -fL --retry 3 --retry-delay 1 -o "${tmp}/checksums.txt" "$sums_url" || err "checksum download failed: ${sums_url}"

  verify_checksum "${tmp}/${asset}" "${tmp}/checksums.txt"

  tar -xzf "${tmp}/${asset}" -C "$tmp"
  bin_path="${tmp}/trivuedev_${VERSION}_${OS}_${ARCH}/trivuedev"
  [ -f "$bin_path" ] || err "archive did not contain trivuedev binary at expected path"

  mkdir -p "$INSTALL_DIR"
  dest="${INSTALL_DIR}/trivuedev"
  mv "$bin_path" "$dest"
  chmod 755 "$dest"

  say "Installed to ${dest}"
  if ! printf '%s\n' "$PATH" | tr ':' '\n' | grep -qx "$INSTALL_DIR"; then
    say ""
    say "Note: ${INSTALL_DIR} is not on your PATH."
    say "Add it, for example:"
    say "  export PATH=\"${INSTALL_DIR}:\$PATH\""
  fi

  say ""
  say "Try: trivuedev --help"
}

main "$@"
