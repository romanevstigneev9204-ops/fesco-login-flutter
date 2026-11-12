unit uGame;

{$mode objfpc}{$H+}

{ Pure Object Pascal Tetris engine — no LCL.
  UI reads state and calls NewGame / Tick / AdvanceTime / movement / RotateCW /
  TogglePause. }

interface

uses
  uTypes, uPieces, uBoard;

type
  TGame = class
  private
    FBoard: TBoardCells;
    FCurrent: TActivePiece;
    FHasCurrent: Boolean;
    FNext: TPieceKind;
    FScore: Integer;
    FLevel: Integer;
    FLines: Integer;
    FPaused: Boolean;
    FGameOver: Boolean;
    FGravityCounter: Integer;
    FBag: array[0..6] of TPieceKind;
    FBagIndex: Integer;
    FBagCount: Integer;
    FRngSeeded: Boolean;
    FMode: TGameMode;
    FElapsedMs: Integer;
    FFinishReason: TFinishReason;

    procedure EnsureRng;
    procedure RefillBag;
    function PullFromBag: TPieceKind;
    function SpawnX(Kind: TPieceKind): Integer;
    function TrySpawn: Boolean;
    procedure LockAndContinue;
    function TryMove(DX, DY: Integer): Boolean;
    function TryRotate(Clockwise: Boolean): Boolean;
    function GravityFrames: Integer;
    procedure AddScoreForLines(Cleared: Integer);
    procedure UpdateLevel;
    procedure Finish(Reason: TFinishReason);
    procedure CheckSprintGoal;
  public
    constructor Create;
    destructor Destroy; override;

    procedure NewGame(AMode: TGameMode = gmMarathon);
    { Advance one frame of gravity. Call from UI timer (~16–50 ms). }
    procedure Tick;
    { Wall-clock for Sprint/Ultra. Ignored while paused / finished. }
    procedure AdvanceTime(DeltaMs: Integer);

    procedure MoveLeft;
    procedure MoveRight;
    procedure SoftDrop;
    procedure HardDrop;
    procedure RotateCW;
    procedure RotateCCW;
    procedure TogglePause;

    { Optional: deterministic bag for harness / tests. Call before NewGame. }
    procedure SetNextSequence(const Kinds: array of TPieceKind);

    function CellAt(X, Y: Integer): TCellValue;
    function LinesRemaining: Integer;
    function TimeRemainingMs: Integer;
    function IsPlaying: Boolean;

    { Board without the falling piece painted in. }
    property Board: TBoardCells read FBoard;
    property Current: TActivePiece read FCurrent;
    property HasCurrent: Boolean read FHasCurrent;
    property NextPiece: TPieceKind read FNext;
    property Score: Integer read FScore;
    property Level: Integer read FLevel;
    property Lines: Integer read FLines;
    property Paused: Boolean read FPaused;
    property GameOver: Boolean read FGameOver;
    property Mode: TGameMode read FMode;
    property ElapsedMs: Integer read FElapsedMs;
    property FinishReason: TFinishReason read FFinishReason;
  end;

{ Lines-cleared score multiplier for Level (guideline-ish). }
function LineClearPoints(Cleared, Level: Integer): Integer;

implementation

constructor TGame.Create;
begin
  inherited Create;
  FRngSeeded := False;
  FBagCount := 0;
  FBagIndex := 0;
  FHasCurrent := False;
  FMode := gmMarathon;
  FElapsedMs := 0;
  FFinishReason := frNone;
  ClearBoard(FBoard);
end;

destructor TGame.Destroy;
begin
  inherited Destroy;
end;

procedure TGame.EnsureRng;
begin
  if not FRngSeeded then
  begin
    Randomize;
    FRngSeeded := True;
  end;
end;

procedure TGame.RefillBag;
var
  I, J: Integer;
  Tmp: TPieceKind;
begin
  for I := 0 to 6 do
    FBag[I] := TPieceKind(I);
  for I := 6 downto 1 do
  begin
    J := Random(I + 1);
    Tmp := FBag[I];
    FBag[I] := FBag[J];
    FBag[J] := Tmp;
  end;
  FBagIndex := 0;
  FBagCount := 7;
end;

function TGame.PullFromBag: TPieceKind;
begin
  EnsureRng;
  if FBagIndex >= FBagCount then
    RefillBag;
  Result := FBag[FBagIndex];
  Inc(FBagIndex);
end;

function TGame.SpawnX(Kind: TPieceKind): Integer;
begin
  { Center a 4-wide piece box on a 10-wide board: X = 3 }
  Result := 3;
  if Kind = pkO then
    Result := 3;
end;

function TGame.TrySpawn: Boolean;
begin
  FCurrent.Kind := FNext;
  FCurrent.Rotation := 0;
  FCurrent.X := SpawnX(FCurrent.Kind);
  FCurrent.Y := 0;
  FNext := PullFromBag;
  FHasCurrent := PieceFits(FBoard, FCurrent);
  Result := FHasCurrent;
  if not Result then
    Finish(frTopOut);
  FGravityCounter := 0;
end;

procedure TGame.Finish(Reason: TFinishReason);
begin
  if FFinishReason <> frNone then
    Exit;
  FFinishReason := Reason;
  FGameOver := True;
  FPaused := False;
  FHasCurrent := False;
end;

procedure TGame.CheckSprintGoal;
begin
  if (FMode = gmSprint40) and (FLines >= SprintGoalLines) then
    Finish(frGoalReached);
end;

procedure TGame.NewGame(AMode: TGameMode);
begin
  EnsureRng;
  ClearBoard(FBoard);
  FMode := AMode;
  FScore := 0;
  FLevel := 1;
  FLines := 0;
  FPaused := False;
  FGameOver := False;
  FFinishReason := frNone;
  FElapsedMs := 0;
  FGravityCounter := 0;
  FHasCurrent := False;
  if FBagCount = 0 then
    RefillBag;
  FNext := PullFromBag;
  if not TrySpawn then
    Finish(frTopOut);
end;

procedure TGame.SetNextSequence(const Kinds: array of TPieceKind);
var
  I: Integer;
begin
  FBagCount := Length(Kinds);
  if FBagCount > Length(FBag) then
    FBagCount := Length(FBag);
  for I := 0 to FBagCount - 1 do
    FBag[I] := Kinds[I];
  FBagIndex := 0;
  FRngSeeded := True; { skip Randomize so sequence stays fixed }
end;

function LineClearPoints(Cleared, Level: Integer): Integer;
begin
  case Cleared of
    1: Result := 100 * Level;
    2: Result := 300 * Level;
    3: Result := 500 * Level;
    4: Result := 800 * Level;
  else
    Result := 0;
  end;
end;

procedure TGame.AddScoreForLines(Cleared: Integer);
begin
  Inc(FScore, LineClearPoints(Cleared, FLevel));
end;

procedure TGame.UpdateLevel;
begin
  { Level up every 10 lines; Level is at least 1 }
  FLevel := (FLines div 10) + 1;
end;

function TGame.GravityFrames: Integer;
begin
  { Rough guideline curve; UI Tick rate ~20–60 Hz }
  if FLevel <= 1 then
    Result := 48
  else if FLevel >= 15 then
    Result := 1
  else
    Result := 48 - (FLevel - 1) * 3;
  if Result < 1 then
    Result := 1;
end;

function TGame.TryMove(DX, DY: Integer): Boolean;
var
  Trial: TActivePiece;
begin
  Result := False;
  if FGameOver or FPaused or not FHasCurrent then
    Exit;
  Trial := FCurrent;
  Inc(Trial.X, DX);
  Inc(Trial.Y, DY);
  if PieceFits(FBoard, Trial) then
  begin
    FCurrent := Trial;
    Result := True;
  end;
end;

function TGame.TryRotate(Clockwise: Boolean): Boolean;
var
  Trial: TActivePiece;
  ToRot: TRotation;
  I, DX, DY, N: Integer;
begin
  Result := False;
  if FGameOver or FPaused or not FHasCurrent then
    Exit;
  if Clockwise then
    ToRot := (FCurrent.Rotation + 1) mod 4
  else
    ToRot := (FCurrent.Rotation + 3) mod 4;

  N := KickTestCount(FCurrent.Kind);
  for I := 0 to N - 1 do
  begin
    GetKickOffset(FCurrent.Kind, FCurrent.Rotation, Clockwise, I, DX, DY);
    Trial := FCurrent;
    Trial.Rotation := ToRot;
    Inc(Trial.X, DX);
    Inc(Trial.Y, DY);
    if PieceFits(FBoard, Trial) then
    begin
      FCurrent := Trial;
      Exit(True);
    end;
  end;
end;

procedure TGame.LockAndContinue;
var
  Cleared: Integer;
begin
  if not FHasCurrent then
    Exit;
  LockPiece(FBoard, FCurrent);
  FHasCurrent := False;
  Cleared := ClearFullLines(FBoard);
  if Cleared > 0 then
  begin
    Inc(FLines, Cleared);
    AddScoreForLines(Cleared);
    UpdateLevel;
    CheckSprintGoal;
    if FGameOver then
      Exit;
  end;
  if not TrySpawn then
    { Finish already called inside TrySpawn };
end;

procedure TGame.Tick;
begin
  if FGameOver or FPaused or not FHasCurrent then
    Exit;
  Inc(FGravityCounter);
  if FGravityCounter >= GravityFrames then
  begin
    FGravityCounter := 0;
    if not TryMove(0, 1) then
      LockAndContinue;
  end;
end;

procedure TGame.AdvanceTime(DeltaMs: Integer);
begin
  if FGameOver or FPaused or (DeltaMs <= 0) then
    Exit;
  Inc(FElapsedMs, DeltaMs);
  if (FMode = gmUltra) and (FElapsedMs >= UltraTimeLimitMs) then
  begin
    FElapsedMs := UltraTimeLimitMs;
    Finish(frTimeUp);
  end;
end;

procedure TGame.MoveLeft;
begin
  TryMove(-1, 0);
end;

procedure TGame.MoveRight;
begin
  TryMove(1, 0);
end;

procedure TGame.SoftDrop;
begin
  if FGameOver or FPaused or not FHasCurrent then
    Exit;
  if TryMove(0, 1) then
    Inc(FScore, 1)
  else
    LockAndContinue;
end;

procedure TGame.HardDrop;
var
  Dropped: Integer;
begin
  if FGameOver or FPaused or not FHasCurrent then
    Exit;
  Dropped := 0;
  while TryMove(0, 1) do
    Inc(Dropped);
  Inc(FScore, Dropped * 2);
  LockAndContinue;
end;

procedure TGame.RotateCW;
begin
  TryRotate(True);
end;

procedure TGame.RotateCCW;
begin
  TryRotate(False);
end;

procedure TGame.TogglePause;
begin
  if FGameOver then
    Exit;
  FPaused := not FPaused;
end;

function TGame.CellAt(X, Y: Integer): TCellValue;
begin
  if (X < 0) or (X >= BoardWidth) or (Y < 0) or (Y >= BoardHeight) then
    Exit(0);
  Result := FBoard[X, Y];
end;

function TGame.LinesRemaining: Integer;
begin
  if FMode <> gmSprint40 then
    Exit(0);
  Result := SprintGoalLines - FLines;
  if Result < 0 then
    Result := 0;
end;

function TGame.TimeRemainingMs: Integer;
begin
  if FMode <> gmUltra then
    Exit(0);
  Result := UltraTimeLimitMs - FElapsedMs;
  if Result < 0 then
    Result := 0;
end;

function TGame.IsPlaying: Boolean;
begin
  Result := (not FGameOver) and (not FPaused) and FHasCurrent;
end;

end.
