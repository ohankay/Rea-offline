#!/bin/sh
# Offline installer: copies this bundle to PREFIX and links `rea` into BIN_DIR.
#   ./install.sh                         -> ~/.local/share/rea-offline, ~/.local/bin/rea
#   sudo PREFIX=/opt/rea-offline BIN_DIR=/usr/local/bin ./install.sh
set -eu
SRC=$(cd "$(dirname "$0")" && pwd)
PREFIX="${PREFIX:-$HOME/.local/share/rea-offline}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

echo "REA kuruluyor / installing: $PREFIX"
if [ "$SRC" != "$PREFIX" ]; then
  rm -rf "$PREFIX"
  mkdir -p "$(dirname "$PREFIX")"
  cp -R "$SRC" "$PREFIX"
fi
# macOS: drop the download quarantine flag so Gatekeeper does not block node.
if [ "$(uname -s)" = Darwin ]; then
  xattr -dr com.apple.quarantine "$PREFIX" 2>/dev/null || true
fi
mkdir -p "$BIN_DIR"
ln -sf "$PREFIX/bin/rea" "$BIN_DIR/rea"

"$BIN_DIR/rea" --version >/dev/null
echo "Tamam / done: $("$BIN_DIR/rea" --version)"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo
     echo "Not: $BIN_DIR PATH'te degil. Su satiri ~/.bashrc veya ~/.zshrc dosyasina ekleyin:"
     echo "Note: $BIN_DIR is not on PATH. Add this to ~/.bashrc or ~/.zshrc:"
     echo "  export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac
echo
echo "Deneyin / try:  rea --help    |    rea doctor    |    rea mcp"
