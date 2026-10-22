#!/bin/sh
set -eu
PREFIX="${PREFIX:-$HOME/.local/share/rea-offline}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
rm -f "$BIN_DIR/rea"
rm -rf "$PREFIX"
echo "REA kaldirildi / removed."
