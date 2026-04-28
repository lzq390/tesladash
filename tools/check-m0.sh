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

export TMPDIR="${TMPDIR:-/tmp}"
export TMP="${TMP:-/tmp}"
export TEMP="${TEMP:-/tmp}"
export HOME="$PROJECT_ROOT/.toolchains/home"
export XDG_CONFIG_HOME="$PROJECT_ROOT/.toolchains/home/.config"
export PUB_CACHE="$PROJECT_ROOT/.toolchains/pub-cache"
export PATH="$PROJECT_ROOT/tools/bin:$PROJECT_ROOT/.toolchains/flutter/bin:$PATH"

if [ -x "$LOCAL_FLUTTER" ]; then
  FLUTTER="$LOCAL_FLUTTER"
elif command -v flutter >/dev/null 2>&1; then
  FLUTTER="$(command -v flutter)"
else
  echo "flutter: MISSING"
  echo "Install Flutter or add .toolchains/flutter/bin to PATH, then rerun this script."
  exit 1
fi

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
