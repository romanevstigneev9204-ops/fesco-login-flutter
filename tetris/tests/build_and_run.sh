#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/tetris/tests/bin"
mkdir -p "$OUT"
fpc -Fu"$ROOT/tetris" -FE"$OUT" -otetris_harness "$ROOT/tetris/tests/harness.lpr"
"$OUT/tetris_harness"
