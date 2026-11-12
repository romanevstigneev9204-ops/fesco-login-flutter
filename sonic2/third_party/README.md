# Зависимости для Windows-сборки

Скачайте [SDL2-devel-*-mingw.tar.gz](https://github.com/libsdl-org/SDL/releases) и распакуйте сюда. `build.sh` ищет каталог `SDL2-*/x86_64-w64-mingw32`.

Альтернатива: свой префикс в `third_party/mingw` (include, lib, bin).

Архивы в git не коммитятся; `SDL2.dll` копируется в `build/` при сборке exe.
