# Tetris (Object Pascal / Lazarus LCL)

Playable Tetris: pure Free Pascal engine + Lazarus LCL window.

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

## Controls

| Key | Action |
|-----|--------|
| ← → | Move |
| ↓ | Soft drop |
| ↑ or X | Rotate CW |
| Space | Hard drop |
| P | Pause |
| R / Enter | Restart after game over |

## Layout

| Path | Role |
|------|------|
| `uTypes.pas` | Board size, cell values, `TPieceKind`, `TActivePiece` |
| `uPieces.pas` | Shape tables, `GetPieceCells`, SRS-like wall kicks |
| `uBoard.pas` | Collision, lock, line clear |
| `uGame.pas` | `TGame` API |
| `uMainForm.pas` / `.lfm` | LCL form: board, next piece, HUD, timer, keys |
| `tetris.lpi` / `tetris.lpr` | Lazarus GUI project |
| `build_gui.sh` | One-shot `lazbuild` wrapper |
| `tests/harness.lpr` | Console engine checks |

## `TGame` contract

```pascal
G := TGame.Create;
G.NewGame;
G.Tick;            // gravity frame (wired to TTimer)
G.MoveLeft / MoveRight;
G.SoftDrop;
G.HardDrop;
G.RotateCW;        // RotateCCW also available
G.TogglePause;
```

Readable state: `Board` (locked cells only), `Current` / `HasCurrent`, `NextPiece`, `Score`, `Level`, `Lines`, `Paused`, `GameOver`.

Paint the falling piece with `GetPieceCells(G.Current, Cells)` from `uPieces` — it is not drawn into `Board`.

Cell values: `0` empty, `1..7` = `Ord(TPieceKind)+1` (I J L O S T Z).

## Build / run harness

```bash
cd /path/to/repo
mkdir -p tetris/tests/bin
fpc -FUtetris -FEtetris/tests/bin -otetris_harness tetris/tests/harness.lpr
./tetris/tests/bin/tetris_harness
```

Or: `./tetris/tests/build_and_run.sh`

Exit code `0` = all checks passed.
