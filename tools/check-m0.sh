#!/usr/bin/env bash
set -euo pipefail

echo "== T-Dash M0 environment check =="

echo
echo "-- Static prototype --"
test -f app/index.html
test -f app/main.js
test -f app/styles.css
node --check app/main.js
echo "PWA prototype files: OK"

echo
echo "-- Docs --"
test -f README.md
test -f docs/05-App开发执行规划.md
test -f docs/06-数据模型与接口草案.md
echo "Planning docs: OK"

echo
echo "-- Flutter toolchain --"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOCAL_FLUTTER="$PROJECT_ROOT/.toolchains/flutter/bin/flutter"
LOCAL_ANDROID_SDK="$PROJECT_ROOT/.toolchains/android-sdk"
LOCAL_JDK="$PROJECT_ROOT/.toolchains/jdk"
LOCAL_CHROME="$PROJECT_ROOT/.toolchains/chrome/chrome-linux64/chrome"
WINDOWS_CHROME="/mnt/c/Program Files/Google/Chrome/Application/chrome.exe"

export TMPDIR="${TMPDIR:-/tmp}"
export TMP="${TMP:-/tmp}"
export TEMP="${TEMP:-/tmp}"
export HOME="$PROJECT_ROOT/.toolchains/home"
export XDG_CONFIG_HOME="$PROJECT_ROOT/.toolchains/home/.config"
export PUB_CACHE="$PROJECT_ROOT/.toolchains/pub-cache"
export ANDROID_HOME="$LOCAL_ANDROID_SDK"
export ANDROID_SDK_ROOT="$LOCAL_ANDROID_SDK"
export JAVA_TOOL_OPTIONS="-Duser.home=/tmp/tdash-home ${JAVA_TOOL_OPTIONS:-}"
export PATH="$PROJECT_ROOT/tools/bin:$PROJECT_ROOT/.toolchains/flutter/bin:$LOCAL_ANDROID_SDK/cmdline-tools/latest/bin:$LOCAL_ANDROID_SDK/platform-tools:$PATH"

if [ -d "$LOCAL_JDK" ]; then
  export JAVA_HOME="$LOCAL_JDK"
  export PATH="$LOCAL_JDK/bin:$PATH"
fi

if [ -x "$LOCAL_CHROME" ]; then
  export CHROME_EXECUTABLE="$LOCAL_CHROME"
elif [ -x "$WINDOWS_CHROME" ]; then
  export CHROME_EXECUTABLE="$WINDOWS_CHROME"
fi

if [ -z "${HTTP_PROXY:-}" ]; then unset HTTP_PROXY; fi
if [ -z "${HTTPS_PROXY:-}" ]; then unset HTTPS_PROXY; fi
if [ -z "${NO_PROXY:-}" ]; then unset NO_PROXY; fi

mkdir -p "$HOME" "$XDG_CONFIG_HOME" "$PUB_CACHE" /tmp/tdash-home/.android/cache

if [ -x "$LOCAL_FLUTTER" ]; then
  FLUTTER="$LOCAL_FLUTTER"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER="$(command -v flutter)"
else
  echo "flutter: MISSING"
  echo "Install Flutter or add .toolchains/flutter/bin to PATH, then rerun this script."
  exit 1
fi

"$FLUTTER" config --android-sdk "$LOCAL_ANDROID_SDK" >/dev/null
"$FLUTTER" --version
"$FLUTTER" doctor

echo
echo "-- Flutter project --"
test -f "$PROJECT_ROOT/t_dash/pubspec.yaml"
(
  cd "$PROJECT_ROOT/t_dash"
  "$FLUTTER" analyze
  "$FLUTTER" test
)
