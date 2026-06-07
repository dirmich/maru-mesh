#!/bin/sh
# MaruMesh client installer for Linux/macOS.

set -eu

CONTROL_URL="${CONTROL_URL:-https://marumesh.lab.highmaru.com}"
GITHUB_RELEASE_BASE="${GITHUB_RELEASE_BASE:-https://github.com/dirmich/maru-mesh/releases/latest/download}"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"

os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(uname -m)"

case "$arch" in
  x86_64|amd64) arch="amd64" ;;
  arm64|aarch64) arch="arm64" ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

case "$os" in
  linux|darwin) ;;
  *) echo "Unsupported OS: $os" >&2; exit 1 ;;
esac

asset="marumesh-${os}-${arch}"
url="${GITHUB_RELEASE_BASE}/${asset}"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

echo "Downloading ${url}"
if command -v curl >/dev/null 2>&1; then
  curl -fL "$url" -o "$tmp"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$tmp" "$url"
else
  echo "curl or wget is required" >&2
  exit 1
fi

chmod +x "$tmp"
if mkdir -p "$INSTALL_DIR" 2>/dev/null && install -m 0755 "$tmp" "$INSTALL_DIR/marumesh" 2>/dev/null; then
  :
elif [ "$(id -u)" -eq 0 ]; then
  echo "Failed to install to $INSTALL_DIR" >&2
  exit 1
else
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Permission denied for $INSTALL_DIR and sudo is not available" >&2
    exit 1
  fi
  sudo mkdir -p "$INSTALL_DIR"
  sudo install -m 0755 "$tmp" "$INSTALL_DIR/marumesh"
fi

echo "Installed: $INSTALL_DIR/marumesh"
echo "Control plane: $CONTROL_URL"
echo "Next: marumesh up"
