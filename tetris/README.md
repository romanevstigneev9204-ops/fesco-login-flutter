# Tetris engine (Object Pascal)

Pure Free Pascal game logic — no LCL/UI. Intended for a later Lazarus form that calls into `TGame`.

## Units

| Unit | Role |
|------|------|
| `uTypes.pas` | Board size, cell values, `TPieceKind`, `TActivePiece` |
| `uPieces.pas` | Shape tables, `GetPieceCells`, SRS-like wall kicks |
| `uBoard.pas` | Collision, lock, line clear |
| `uGame.pas` | `TGame` API for the UI |

## `TGame` contract (for UI agent)

```pascal
G := TGame.Create;
G.NewGame;
G.Tick;            // gravity frame (wire to TTimer)
G.MoveLeft / MoveRight;
G.SoftDrop;
G.HardDrop;
G.RotateCW;        // RotateCCW also available
G.TogglePause;
```

Readable state: `Board` (locked cells only), `Current` / `HasCurrent`, `NextPiece`, `Score`, `Level`, `Lines`, `Paused`, `GameOver`.

Paint the falling piece with `GetPieceCells(G.Current, Cells)` from `uPieces` — do not expect it inside `Board`.

Cell values: `0` empty, `1..7` = `Ord(TPieceKind)+1` (I J L O S T Z).

## Build / run harness

Requires Free Pascal (`fpc`).

```bash
cd /path/to/repo
mkdir -p tetris/tests/bin
fpc -FUtetris -FEtetris/tests/bin -otetris_harness tetris/tests/harness.lpr
./tetris/tests/bin/tetris_harness
```

Exit code `0` = all checks passed.
