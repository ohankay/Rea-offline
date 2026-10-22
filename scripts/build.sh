#!/usr/bin/env bash
# Builds a self-contained, offline-installable REA bundle for the host platform.
#
#   scripts/build.sh [--rea-version 6.7.0] [--node-version 24] [--with-ghidra] [--out dist]
#
# Run it on the platform you are packaging for (linux-x64, linux-arm64,
# darwin-arm64, darwin-x64, win-x64); native dependencies such as frida and
# node-pty are fetched as prebuilt binaries for the machine running the build.
# Needs internet only while building. The resulting archive needs none.
set -euo pipefail

REA_VERSION="6.7.0"
NODE_MAJOR="24"
WITH_GHIDRA=false
GHIDRA_VERSION="12.1.4"
JDK_MAJOR="21"
OUT_DIR="dist"

while (($# > 0)); do
  case "$1" in
    --rea-version) REA_VERSION="$2"; shift 2 ;;
    --node-version) NODE_MAJOR="$2"; shift 2 ;;
    --with-ghidra) WITH_GHIDRA=true; shift ;;
    --ghidra-version) GHIDRA_VERSION="$2"; shift 2 ;;
    --out) OUT_DIR="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$OUT_DIR"
OUT_DIR="$(cd "$OUT_DIR" && pwd)"

case "$(uname -s)" in
  Linux) os=linux; node_os=linux; jdk_os=linux ;;
  Darwin) os=darwin; node_os=darwin; jdk_os=mac ;;
  MINGW*|MSYS*|CYGWIN*) os=win; node_os=win; jdk_os=windows ;;
  *) echo "unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac
case "$(uname -m)" in
  x86_64|amd64) arch=x64; jdk_arch=x64 ;;
  arm64|aarch64) arch=arm64; jdk_arch=aarch64 ;;
  *) echo "unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac

platform="$os-$arch"
variant=""
$WITH_GHIDRA && variant="-ghidra"
name="rea-offline-${REA_VERSION}-${platform}${variant}"
work="$(mktemp -d)"
root="$work/$name"
mkdir -p "$root/app" "$root/bin"
echo "==> building $name"

fetch() { curl -fsSL --retry 4 --retry-delay 2 -o "$2" "$1"; }

# 1) Node.js runtime: newest release of the requested major line.
node_version="$(curl -fsSL https://nodejs.org/dist/index.json \
  | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const m=process.argv[1];const r=JSON.parse(s).find(x=>x.version.startsWith("v"+m+"."));console.log(r.version)})' "$NODE_MAJOR")"
echo "==> Node.js $node_version"
if [[ $os == win ]]; then
  fetch "https://nodejs.org/dist/$node_version/node-$node_version-win-$arch.zip" "$work/node.zip"
  unzip -q "$work/node.zip" -d "$work"
  mv "$work/node-$node_version-win-$arch" "$root/node"
  rm -rf "$root/node/node_modules/corepack" "$root/node/corepack"*
else
  fetch "https://nodejs.org/dist/$node_version/node-$node_version-$node_os-$arch.tar.gz" "$work/node.tgz"
  tar -xzf "$work/node.tgz" -C "$work"
  mv "$work/node-$node_version-$node_os-$arch" "$root/node"
  rm -rf "$root/node/include" "$root/node/share"
fi

# 2) REA and its production dependencies (prebuilt native modules included).
echo "==> rea-agents@$REA_VERSION"
printf '{"name":"rea-offline","private":true}\n' > "$root/app/package.json"
(cd "$root/app" && npm install --omit=dev --no-audit --no-fund --no-update-notifier "rea-agents@$REA_VERSION")
rm -f "$root/app/package-lock.json"

# 3) Optional analysis backend: Ghidra plus a matching JDK.
if $WITH_GHIDRA; then
  echo "==> Ghidra $GHIDRA_VERSION + JDK $JDK_MAJOR"
  auth=()
  [[ -n "${GITHUB_TOKEN:-}" ]] && auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
  ghidra_url="$(curl -fsSL "${auth[@]}" \
    "https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/tags/Ghidra_${GHIDRA_VERSION}_build" \
    | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{console.log(JSON.parse(s).assets.find(a=>a.name.endsWith(".zip")).browser_download_url)})')"
  fetch "$ghidra_url" "$work/ghidra.zip"
  unzip -q "$work/ghidra.zip" -d "$work/ghidra-x"
  mv "$work/ghidra-x"/ghidra_* "$root/ghidra"
  jdk_url="https://api.adoptium.net/v3/binary/latest/$JDK_MAJOR/ga/$jdk_os/$jdk_arch/jdk/hotspot/normal/eclipse"
  mkdir -p "$work/jdk-x"
  if [[ $os == win ]]; then
    fetch "$jdk_url" "$work/jdk.zip"; unzip -q "$work/jdk.zip" -d "$work/jdk-x"
  else
    fetch "$jdk_url" "$work/jdk.tgz"; tar -xzf "$work/jdk.tgz" -C "$work/jdk-x"
  fi
  jdk_dir="$(ls -d "$work"/jdk-x/*/ | head -1)"
  if [[ $os == darwin ]]; then jdk_dir="$jdk_dir/Contents/Home"; fi
  mv "$jdk_dir" "$root/jdk"

  # Official Ghidra zips lack native binaries for some hosts (e.g. linux_arm_64);
  # build them with Ghidra's own Gradle wrapper so the decompiler is present.
  case "$os-$arch" in
    linux-x64) natives=linux_x86_64 ;; linux-arm64) natives=linux_arm_64 ;;
    darwin-x64) natives=mac_x86_64 ;; darwin-arm64) natives=mac_arm_64 ;;
    win-x64) natives=win_x86_64 ;;
  esac
  if [[ ! -e "$root/ghidra/Ghidra/Features/Decompiler/os/$natives/decompile" \
     && ! -e "$root/ghidra/Ghidra/Features/Decompiler/os/$natives/decompile.exe" ]]; then
    echo "==> building Ghidra natives for $natives"
    gradle_cmd=gradle
    [[ -x "$root/ghidra/support/gradle/gradlew" ]] && gradle_cmd=./gradlew
    (cd "$root/ghidra/support/gradle" && JAVA_HOME="$root/jdk" $gradle_cmd --no-daemon buildNatives)
    rm -rf "$root/ghidra/support/gradle/.gradle"
    # REA accepts both os/<platform> and build/os/<platform> decompiler locations.
    ls "$root/ghidra/Ghidra/Features/Decompiler/os/$natives/decompile" \
       "$root/ghidra/Ghidra/Features/Decompiler/build/os/$natives/decompile" 2>/dev/null | grep -q .
  fi
fi

# 4) Launchers, installers and docs.
if [[ $os == win ]]; then
  cp "$REPO_ROOT/templates/rea.cmd" "$root/bin/rea.cmd"
  cp "$REPO_ROOT/templates/install.cmd" "$REPO_ROOT/templates/install.ps1" \
     "$REPO_ROOT/templates/uninstall.ps1" "$root/"
else
  cp "$REPO_ROOT/templates/rea.sh" "$root/bin/rea"
  cp "$REPO_ROOT/templates/install.sh" "$REPO_ROOT/templates/uninstall.sh" "$root/"
  chmod +x "$root/bin/rea" "$root/install.sh" "$root/uninstall.sh"
fi
cp "$REPO_ROOT/templates/KURULUM.txt" "$root/"
cp "$REPO_ROOT/LICENSE.rea" "$root/LICENSE.rea.txt"
printf 'rea-agents %s\nnode %s\nplatform %s\nghidra %s\nbuilt %s\n' \
  "$REA_VERSION" "$node_version" "$platform" \
  "$($WITH_GHIDRA && echo "$GHIDRA_VERSION" || echo none)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$root/VERSION.txt"

# 5) Smoke test straight from the bundle before archiving.
if [[ $os == win ]]; then
  "$root/node/node.exe" "$root/app/node_modules/rea-agents/scripts/rea.mjs" --version
else
  "$root/bin/rea" --version
fi

# 6) Archive (+ checksum).
cd "$work"
if [[ $os == win ]]; then
  archive="$name.zip"
  7z a -tzip -mx=7 -bso0 "$OUT_DIR/$archive" "$name"
else
  archive="$name.tar.gz"
  tar -czf "$OUT_DIR/$archive" "$name"
fi
cd "$OUT_DIR"
if command -v sha256sum >/dev/null; then sha256sum "$archive" > "$archive.sha256"
else shasum -a 256 "$archive" > "$archive.sha256"; fi
ls -lh "$OUT_DIR/$archive"
rm -rf "$work"
