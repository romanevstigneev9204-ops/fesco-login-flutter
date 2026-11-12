# Tetris (Object Pascal / Lazarus LCL)

Playable Tetris: pure Free Pascal engine + Lazarus LCL window.

Modes: **Marathon**, **40-Line Sprint**, **Ultra 2:00** — pick on the launch menu.

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

## Modes

| Mode | Goal | HUD | Personal best |
|------|------|-----|---------------|
| Marathon | Survive (top-out ends) | Score / Level / Lines | Highest score |
| 40-Line Sprint | Clear 40 lines | Elapsed time / lines left / lines | Fastest time |
| Ultra 2:00 | Score in 2 minutes | Score / time left / lines | Highest score |

Sprint and Ultra start with a **3-2-1-GO** countdown. Esc returns to the mode menu (also after game over).

Local PB file: `tetris-scores.ini` under the user config dir (`GetAppConfigDir`), e.g. `~/.config/tetris/tetris-scores.ini` on Linux.

## Controls

| Key | Action |
|-----|--------|
| ↑↓ / 1–3 / click | Menu: select / start mode |
| Enter / Space | Menu: confirm |
| ← → | Move |
| ↓ | Soft drop |
| ↑ or X | Rotate CW |
| Space | Hard drop |
| P | Pause |
| Esc | Back to menu (quit from menu) |
| R / Enter | Retry same mode after finish |

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
