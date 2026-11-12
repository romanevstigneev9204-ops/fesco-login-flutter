# Sonic 2 (неофициальный прототип)

Фанатская игра в духе *Sonic the Hedgehog 2*. **Sega не участвует** в разработке; это не продукт и не ассоциируется с Sega. Никаких ROM, спрайтов или музыки Sega — только свои ассеты и своя карта.

## Стек

- C11, SDL2
- Внутренний кадр 320×224, окно с целочисленным масштабом ×3
- Фиксированный шаг симуляции 1/60 с

## Сборка

```bash
cd sonic2
./build.sh
```

- Linux: `build/sonic2`
- Windows (кросс-компиляция): `build/sonic2.exe` через `x86_64-w64-mingw32-gcc`

Зависимости Linux: `gcc`, `libsdl2-dev`. Для Windows exe дополнительно `mingw-w64` и SDL2 для mingw (системные пакеты или каталог `third_party/mingw`).

Скриншоты кадров (без игрового цикла):

```bash
./build/sonic2 --shot
# → build/shot_title.ppm, build/shot_level.ppm
```

Исполняемые файлы в `build/` не коммитятся.

Спрайты и короткие звуки из `assets/` рисуются и проигрываются рантаймом (PNG через `third_party/stb_image.h`, WAV через SDL). Это своя графика, не файлы Sega.

## Модули

| Файл | Назначение |
|------|------------|
| `src/main.c`, `platform.c`, `render.c`, `input.c` | рантайм |
| `src/stubs/*` | заглушки, пока нет `player.c`, `world.c`, `objects.c` |
| `levels/`, `assets/` | уровень и картинки (отдельные задачи) |

Общие заголовки (`fixed.h`, `player.h`, …) — контракт из `docs/sonic2-plan.md`.

## Управление

Стрелки / WASD, прыжок — Space, Z или Enter. Escape — выход.
