#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/tests"
CC="${CC:-gcc}"
CFLAGS="-std=c11 -Wall -Wextra -Werror -I$ROOT/src"
$CC $CFLAGS -o test_level test_level.c ../src/world.c ../src/objects.c
./test_level
