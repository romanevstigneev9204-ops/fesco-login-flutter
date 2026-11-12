#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CC="${CC:-cc}"
CFLAGS="-std=c11 -Wall -Wextra -Werror -I${ROOT}/src"
mkdir -p "${ROOT}/build"

OUT_PLAYER="${ROOT}/build/test_player"
${CC} ${CFLAGS} -o "${OUT_PLAYER}" "${ROOT}/tests/test_player.c" "${ROOT}/src/player.c"
"${OUT_PLAYER}"

OUT_BOSS="${ROOT}/build/test_boss"
${CC} ${CFLAGS} -o "${OUT_BOSS}" "${ROOT}/tests/test_boss.c" "${ROOT}/src/objects.c"
"${OUT_BOSS}"
