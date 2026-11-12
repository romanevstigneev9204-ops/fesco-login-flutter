#!/usr/bin/env bash
# Build the Lazarus LCL Tetris GUI. Then run: ./bin/tetris
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
mkdir -p "$ROOT/bin" "$ROOT/lib"
lazbuild --build-mode=Default "$ROOT/tetris.lpi"
echo "Built: $ROOT/bin/tetris"
echo "Run:   $ROOT/bin/tetris"
