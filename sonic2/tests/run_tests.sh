#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CC="${CC:-cc}"
CFLAGS="-std=c11 -Wall -Wextra -Werror -I${ROOT}/src"
OUT="${ROOT}/build/test_player"
mkdir -p "${ROOT}/build"
${CC} ${CFLAGS} -o "${OUT}" "${ROOT}/tests/test_player.c" "${ROOT}/src/player.c"
"${OUT}"
