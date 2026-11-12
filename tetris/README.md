# Тетрис (Object Pascal / Lazarus LCL)

Играбельный тетрис: движок на Free Pascal + окно Lazarus LCL.

Режимы: **Марафон**, **Спринт 40 линий**, **Ультра 2:00** — выбор в стартовом меню.

## Quick start

Requires Free Pascal + Lazarus (`lazbuild`, LCL GTK2).

```bash
cd tetris && ./build_gui.sh && ./bin/tetris
```

Equivalent without the helper script:

```bash
cd tetris
lazbuild --build-mode=Default tetris.lpi
./bin/tetris
```

Binary: `tetris/bin/tetris`.

## Режимы

| Режим | Цель | HUD | Рекорд |
|------|------|-----|---------------|
| Марафон | Выжить (конец при переполнении) | Очки / Уровень / Линии | Лучший счёт |
| Спринт 40 линий | Сбросить 40 линий | Время / осталось / линии | Лучшее время |
| Ультра 2:00 | Набрать очки за 2 минуты | Очки / осталось / линии | Лучший счёт |

Перед стартом — обратный отсчёт **3-2-1-СТАРТ** по центру поля. Esc возвращает в меню режимов (также после окончания партии).

Файл рекордов: `tetris-scores.ini` в каталоге конфигурации пользователя (`GetAppConfigDir`), например `~/.config/tetris/tetris-scores.ini` на Linux.

## Управление

| Клавиша | Действие |
|-----|--------|
| ↑↓ / 1–3 / клик | Меню: выбор / старт режима |
| Enter / Пробел | Меню: подтвердить |
| ← → | Движение |
| ↓ | Мягкий сброс |
| ↑ или X | Поворот по часовой |
| Пробел | Жёсткий сброс |
| P | Пауза |
| Esc | В меню (из меню — выход) |
| R / Enter | Заново тот же режим после финиша |

## Layout

| Path | Role |
|------|------|
| `uTypes.pas` | Board size, modes, `FormatRaceTime` |
| `uPieces.pas` | Shape tables, wall kicks |
| `uBoard.pas` | Collision, lock, line clear |
| `uGame.pas` | `TGame` API (modes, timer, finish) |
| `uScores.pas` | Local personal-best INI |
| `uMainForm.pas` / `.lfm` | Menu, board, HUD, countdown |
| `tetris.lpi` / `tetris.lpr` | Lazarus GUI project |
| `build_gui.sh` | One-shot `lazbuild` wrapper |
| `tests/harness.lpr` | Console engine checks |

## `TGame` contract

```pascal
G := TGame.Create;
G.NewGame(gmSprint40);  // gmMarathon | gmSprint40 | gmUltra
G.AdvanceTime(16);      // wall-clock for Sprint/Ultra
G.Tick;                 // gravity frame
G.MoveLeft / MoveRight;
G.SoftDrop;
G.HardDrop;
G.RotateCW;             // RotateCCW also available
G.TogglePause;
```

Readable state: `Mode`, `Board`, `Current` / `HasCurrent`, `NextPiece`, `Score`, `Level`, `Lines`, `ElapsedMs`, `LinesRemaining`, `TimeRemainingMs`, `Paused`, `GameOver`, `FinishReason`.

Paint the falling piece with `GetPieceCells(G.Current, Cells)` from `uPieces` — it is not drawn into `Board`.

## Build / run harness

```bash
cd /path/to/repo
mkdir -p tetris/tests/bin
fpc -FUtetris -FEtetris/tests/bin -otetris_harness tetris/tests/harness.lpr
./tetris/tests/bin/tetris_harness
```

Or: `./tetris/tests/build_and_run.sh`

Exit code `0` = all checks passed.
