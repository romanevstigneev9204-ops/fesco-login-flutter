program harness;

{$mode objfpc}{$H+}

{ Console harness for the Tetris engine — no GUI.
  Build:  fpc -FUtetris -FEtetris/tests tetris/tests/harness.lpr
  Or from tetris/: see README. }

uses
  SysUtils, uTypes, uPieces, uBoard, uGame;

var
  Failed: Integer;

procedure Check(Cond: Boolean; const Msg: string);
begin
  if Cond then
    WriteLn('[PASS] ', Msg)
  else
  begin
    WriteLn('[FAIL] ', Msg);
    Inc(Failed);
  end;
end;

procedure FillRow(var Board: TBoardCells; Y: Integer; Value: TCellValue);
var
  X: Integer;
begin
  for X := 0 to BoardWidth - 1 do
    Board[X, Y] := Value;
end;

procedure TestBoardClear;
var
  Board: TBoardCells;
  N: Integer;
begin
  WriteLn('--- Board / line clear ---');
  ClearBoard(Board);
  FillRow(Board, BoardHeight - 1, 1);
  FillRow(Board, BoardHeight - 2, 1);
  Board[0, BoardHeight - 3] := 2;
  N := ClearFullLines(Board);
  Check(N = 2, 'clears two full bottom rows');
  Check(Board[0, BoardHeight - 1] = 2, 'orphan cell drops to bottom');
  Check(Board[1, BoardHeight - 1] = 0, 'rest of bottom row empty');
end;

procedure TestPieceSpawnAndMove;
var
  G: TGame;
  X0: Integer;
begin
  WriteLn('--- Spawn / move ---');
  G := TGame.Create;
  try
    G.SetNextSequence([pkT, pkI, pkO, pkJ, pkL, pkS, pkZ]);
    G.NewGame;
    Check(not G.GameOver, 'new game not over');
    Check(G.HasCurrent, 'has current piece');
    Check(G.Current.Kind = pkT, 'first piece is T from sequence');
    Check(G.NextPiece = pkI, 'next is I');
    X0 := G.Current.X;
    G.MoveLeft;
    Check(G.Current.X = X0 - 1, 'move left');
    G.MoveRight;
    G.MoveRight;
    Check(G.Current.X = X0 + 1, 'move right past start');
  finally
    G.Free;
  end;
end;

procedure TestRotateWallKick;
var
  G: TGame;
  R0: TRotation;
  I: Integer;
begin
  WriteLn('--- Rotate / wall-kick ---');
  G := TGame.Create;
  try
    G.SetNextSequence([pkT, pkI, pkO, pkJ, pkL, pkS, pkZ]);
    G.NewGame;
    R0 := G.Current.Rotation;
    G.RotateCW;
    Check(G.Current.Rotation = (R0 + 1) mod 4, 'rotate CW changes rotation');
  finally
    G.Free;
  end;

  G := TGame.Create;
  try
    G.SetNextSequence([pkT, pkI, pkO, pkJ, pkL, pkS, pkZ]);
    G.NewGame;
    for I := 1 to 5 do
      G.MoveLeft;
    G.RotateCW;
    Check(G.HasCurrent and PieceFits(G.Board, G.Current),
      'rotate near left wall still fits (wall-kick)');
  finally
    G.Free;
  end;
end;

procedure TestSoftHardDropAndScore;
var
  G: TGame;
  ScoreBefore: Integer;
begin
  WriteLn('--- Soft / hard drop ---');
  G := TGame.Create;
  try
    G.SetNextSequence([pkO, pkI, pkT, pkJ, pkL, pkS, pkZ]);
    G.NewGame;
    ScoreBefore := G.Score;
    G.SoftDrop;
    Check(G.Score = ScoreBefore + 1, 'soft drop awards 1 point');
    Check(G.Current.Y > 0, 'soft drop moved down');
    ScoreBefore := G.Score;
    G.HardDrop;
    Check(G.Score > ScoreBefore, 'hard drop awards points');
    Check(G.Current.Kind = pkI, 'after lock, next (I) becomes current');
  finally
    G.Free;
  end;
end;

procedure TestLineClearViaGame;
var
  G: TGame;
begin
  WriteLn('--- Score table / pause ---');
  Check(LineClearPoints(1, 1) = 100, '1-line score @ L1');
  Check(LineClearPoints(4, 2) = 1600, 'tetris score @ L2');

  G := TGame.Create;
  try
    G.SetNextSequence([pkI, pkO, pkT, pkJ, pkL, pkS, pkZ]);
    G.NewGame;
    Check(G.Lines = 0, 'lines start at 0');
    G.TogglePause;
    Check(G.Paused, 'paused');
    G.Tick;
    Check(G.Current.Y = 0, 'tick ignored while paused');
    G.TogglePause;
    Check(not G.Paused, 'unpaused');
  finally
    G.Free;
  end;
end;

procedure TestGravityLock;
var
  G: TGame;
  Y: Integer;
  I: Integer;
begin
  WriteLn('--- Gravity tick lock ---');
  G := TGame.Create;
  try
    G.SetNextSequence([pkO, pkT, pkI, pkJ, pkL, pkS, pkZ]);
    G.NewGame;
    Y := G.Current.Y;
    { Force many ticks until piece moves or locks }
    for I := 1 to 60 do
      G.Tick;
    Check(G.Current.Y > Y, 'gravity moved piece down');
  finally
    G.Free;
  end;
end;

procedure TestGameOver;
var
  G: TGame;
  Board: TBoardCells;
  X, Y: Integer;
  Piece: TActivePiece;
begin
  WriteLn('--- Game over / board fill helper ---');
  { Prove PieceFits fails when board is full at spawn }
  ClearBoard(Board);
  for X := 0 to BoardWidth - 1 do
    for Y := 0 to 3 do
      Board[X, Y] := 1;
  Piece.Kind := pkT;
  Piece.Rotation := 0;
  Piece.X := 3;
  Piece.Y := 0;
  Check(not PieceFits(Board, Piece), 'spawn blocked when top filled');

  G := TGame.Create;
  try
    G.SetNextSequence([pkT, pkI, pkO, pkJ, pkL, pkS, pkZ]);
    G.NewGame;
    Check(not G.GameOver, 'fresh game playable');
    G.NewGame;
    Check(not G.GameOver, 'NewGame resets');
  finally
    G.Free;
  end;
end;

procedure TestModesAndTimer;
var
  G: TGame;
begin
  WriteLn('--- Modes / Sprint / Ultra ---');
  Check(FormatRaceTime(65032) = '01:05.03', 'FormatRaceTime 1:05.03');
  Check(GameModeName(gmSprint40) = '40-Line Sprint', 'Sprint mode name');

  G := TGame.Create;
  try
    G.SetNextSequence([pkT, pkI, pkO, pkJ, pkL, pkS, pkZ]);
    G.NewGame(gmSprint40);
    Check(G.Mode = gmSprint40, 'Sprint mode set');
    Check(G.LinesRemaining = SprintGoalLines, 'Sprint starts with 40 left');
    Check(G.ElapsedMs = 0, 'Sprint timer starts at 0');
    G.AdvanceTime(1500);
    Check(G.ElapsedMs = 1500, 'AdvanceTime accumulates');
    G.TogglePause;
    G.AdvanceTime(500);
    Check(G.ElapsedMs = 1500, 'AdvanceTime ignored while paused');
    G.TogglePause;
  finally
    G.Free;
  end;

  G := TGame.Create;
  try
    G.SetNextSequence([pkO, pkI, pkT, pkJ, pkL, pkS, pkZ]);
    G.NewGame(gmUltra);
    Check(G.Mode = gmUltra, 'Ultra mode set');
    Check(G.TimeRemainingMs = UltraTimeLimitMs, 'Ultra full time left');
    G.AdvanceTime(UltraTimeLimitMs);
    Check(G.GameOver, 'Ultra ends at 2:00');
    Check(G.FinishReason = frTimeUp, 'Ultra finish is time up');
    Check(G.ElapsedMs = UltraTimeLimitMs, 'Ultra clamps elapsed');
  finally
    G.Free;
  end;
end;

procedure TestFullLineIntegration;
var
  Board: TBoardCells;
  Piece: TActivePiece;
  Cleared: Integer;
  Cells: TCellOffsets;
  I: Integer;
begin
  WriteLn('--- Lock I clears a prepared row ---');
  ClearBoard(Board);
  { Leave columns 3..6 empty on bottom; fill the rest }
  for I := 0 to BoardWidth - 1 do
    if (I < 3) or (I > 6) then
      Board[I, BoardHeight - 1] := PieceKindToCell(pkJ);

  Piece.Kind := pkI;
  Piece.Rotation := 0; { horizontal on local row Y=1 }
  Piece.X := 3;
  Piece.Y := BoardHeight - 2; { local Y=1 -> board Y=19 }
  Check(PieceFits(Board, Piece), 'horizontal I fits in bottom gap');
  LockPiece(Board, Piece);
  Cleared := ClearFullLines(Board);
  Check(Cleared = 1, 'locking I clears one line');
  Check(Board[0, BoardHeight - 1] = 0, 'bottom empty after clear');
end;

begin
  Failed := 0;
  WriteLn('Tetris engine harness');
  WriteLn('=====================');
  TestBoardClear;
  TestPieceSpawnAndMove;
  TestRotateWallKick;
  TestSoftHardDropAndScore;
  TestLineClearViaGame;
  TestGravityLock;
  TestGameOver;
  TestModesAndTimer;
  TestFullLineIntegration;
  WriteLn;
  if Failed = 0 then
  begin
    WriteLn('All checks passed.');
    Halt(0);
  end
  else
  begin
    WriteLn(Failed, ' check(s) failed.');
    Halt(1);
  end;
end.
