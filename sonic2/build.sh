#!/usr/bin/env bash
# Builds Linux binary and Windows sonic2.exe (mingw). Reports missing deps.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
mkdir -p build

missing=()
have_linux=0
have_win=0

if ! command -v gcc >/dev/null 2>&1; then
    missing+=("gcc")
else
    if pkg-config --exists sdl2 2>/dev/null; then
        have_linux=1
    else
        missing+=("libsdl2-dev (pkg-config sdl2)")
    fi
fi

if command -v x86_64-w64-mingw32-gcc >/dev/null 2>&1; then
    if [[ -f /usr/x86_64-w64-mingw32/lib/libSDL2.a ]] || \
       [[ -f /usr/x86_64-w64-mingw32/lib/libSDL2.dll.a ]]; then
        have_win=1
    elif [[ -d "$ROOT/third_party/mingw" ]]; then
        have_win=1
        export SONIC2_MINGW_PREFIX="$ROOT/third_party/mingw"
    else
      for _sdl in "$ROOT"/third_party/SDL2-*/x86_64-w64-mingw32; do
        if [[ -d "$_sdl" ]]; then
          have_win=1
          export SONIC2_MINGW_PREFIX="$_sdl"
          break
        fi
      done
    fi
    if (( ! have_win )); then
        missing+=("mingw SDL2 (unpack SDL2-devel mingw into sonic2/third_party or use third_party/mingw)")
    fi
else
    missing+=("x86_64-w64-mingw32-gcc (package mingw-w64)")
fi

if (( have_linux )); then
    echo "==> Linux: sonic2/build/sonic2"
    make linux
else
    echo "==> Linux: skipped"
fi

if (( have_win )); then
    echo "==> Windows: sonic2/build/sonic2.exe"
    make win
    if [[ -n "${SONIC2_MINGW_PREFIX:-}" && -f "$SONIC2_MINGW_PREFIX/bin/SDL2.dll" ]]; then
        cp -f "$SONIC2_MINGW_PREFIX/bin/SDL2.dll" "$ROOT/build/"
        echo "    (bundled build/SDL2.dll for double-click run)"
    fi
else
    echo "==> Windows: skipped"
fi

if ((${#missing[@]} > 0)); then
    echo ""
    echo "Missing for a full build:"
    for m in "${missing[@]}"; do
        echo "  - $m"
    done
    echo ""
    echo "Place a static/SDL2 bundle under sonic2/third_party/mingw for portable Windows exe."
fi

if [[ -x "$ROOT/build/sonic2" ]]; then
    echo "==> Screenshots (--shot)"
  (cd "$ROOT" && ./build/sonic2 --shot) || true
fi

exit 0
