#!/bin/sh
# REA offline launcher: runs REA with the Node.js (and optional Ghidra/JDK)
# shipped inside this bundle. Nothing is downloaded at runtime.
self="$0"
while [ -L "$self" ]; do
  link=$(readlink "$self")
  case "$link" in /*) self="$link" ;; *) self="$(dirname "$self")/$link" ;; esac
done
ROOT=$(cd "$(dirname "$self")/.." && pwd)
PATH="$ROOT/node/bin:$PATH"
# The bundled Ghidra/JDK always win over whatever the host has configured, so a
# stale JAVA_HOME cannot break analysis. Set REA_USE_SYSTEM_TOOLS=1 to opt out.
if [ -z "${REA_USE_SYSTEM_TOOLS:-}" ]; then
  if [ -d "$ROOT/ghidra" ]; then
    GHIDRA_INSTALL_DIR="$ROOT/ghidra"; export GHIDRA_INSTALL_DIR
  fi
  if [ -d "$ROOT/jdk" ]; then
    JAVA_HOME="$ROOT/jdk"; PATH="$JAVA_HOME/bin:$PATH"; export JAVA_HOME
  fi
fi
export PATH
NO_UPDATE_NOTIFIER=1; export NO_UPDATE_NOTIFIER
exec "$ROOT/node/bin/node" "$ROOT/app/node_modules/rea-agents/scripts/rea.mjs" "$@"
