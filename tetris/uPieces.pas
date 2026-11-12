unit uPieces;

{$mode objfpc}{$H+}

{ Tetromino shapes and SRS-like wall-kick offsets.
  Board Y grows downward; SRS kick Y (up-positive) is negated. }

interface

uses
  uTypes;

{ Absolute board cells occupied by an active piece. }
procedure GetPieceCells(const Piece: TActivePiece; out Cells: TCellOffsets);

{ Local 4x4 offsets for Kind at Rotation (origin top-left of spawn box). }
procedure GetLocalOffsets(Kind: TPieceKind; Rotation: TRotation; out Offsets: TCellOffsets);

{ Number of kick tests for rotating FromRot -> ToRot (always 5 for I/JLSTZ, 1 for O). }
function KickTestCount(Kind: TPieceKind): Integer;

{ Kick offset i (0-based) for clockwise or counter-clockwise rotation.
  Clockwise = True means FromRot -> (FromRot+1) mod 4. }
procedure GetKickOffset(Kind: TPieceKind; FromRot: TRotation; Clockwise: Boolean;
  TestIndex: Integer; out DX, DY: Integer);

implementation

type
  TLocalTable = array[TRotation, 0..PieceCellCount - 1] of TPoint;
  TKickRow = array[0..4] of TPoint;

{ --- Shape tables (standard guideline orientations, Y down) --- }

const
  { I: horizontal/vertical through center of 4x4 }
  ShapeI: TLocalTable = (
    ((X:0; Y:1), (X:1; Y:1), (X:2; Y:1), (X:3; Y:1)),
    ((X:2; Y:0), (X:2; Y:1), (X:2; Y:2), (X:2; Y:3)),
    ((X:0; Y:2), (X:1; Y:2), (X:2; Y:2), (X:3; Y:2)),
    ((X:1; Y:0), (X:1; Y:1), (X:1; Y:2), (X:1; Y:3))
  );

  ShapeJ: TLocalTable = (
    ((X:0; Y:0), (X:0; Y:1), (X:1; Y:1), (X:2; Y:1)),
    ((X:1; Y:0), (X:2; Y:0), (X:1; Y:1), (X:1; Y:2)),
    ((X:0; Y:1), (X:1; Y:1), (X:2; Y:1), (X:2; Y:2)),
    ((X:1; Y:0), (X:1; Y:1), (X:0; Y:2), (X:1; Y:2))
  );

  ShapeL: TLocalTable = (
    ((X:2; Y:0), (X:0; Y:1), (X:1; Y:1), (X:2; Y:1)),
    ((X:1; Y:0), (X:1; Y:1), (X:1; Y:2), (X:2; Y:2)),
    ((X:0; Y:1), (X:1; Y:1), (X:2; Y:1), (X:0; Y:2)),
    ((X:0; Y:0), (X:1; Y:0), (X:1; Y:1), (X:1; Y:2))
  );

  ShapeO: TLocalTable = (
    ((X:1; Y:0), (X:2; Y:0), (X:1; Y:1), (X:2; Y:1)),
    ((X:1; Y:0), (X:2; Y:0), (X:1; Y:1), (X:2; Y:1)),
    ((X:1; Y:0), (X:2; Y:0), (X:1; Y:1), (X:2; Y:1)),
    ((X:1; Y:0), (X:2; Y:0), (X:1; Y:1), (X:2; Y:1))
  );

  ShapeS: TLocalTable = (
    ((X:1; Y:0), (X:2; Y:0), (X:0; Y:1), (X:1; Y:1)),
    ((X:1; Y:0), (X:1; Y:1), (X:2; Y:1), (X:2; Y:2)),
    ((X:1; Y:1), (X:2; Y:1), (X:0; Y:2), (X:1; Y:2)),
    ((X:0; Y:0), (X:0; Y:1), (X:1; Y:1), (X:1; Y:2))
  );

  ShapeT: TLocalTable = (
    ((X:1; Y:0), (X:0; Y:1), (X:1; Y:1), (X:2; Y:1)),
    ((X:1; Y:0), (X:1; Y:1), (X:2; Y:1), (X:1; Y:2)),
    ((X:0; Y:1), (X:1; Y:1), (X:2; Y:1), (X:1; Y:2)),
    ((X:1; Y:0), (X:0; Y:1), (X:1; Y:1), (X:1; Y:2))
  );

  ShapeZ: TLocalTable = (
    ((X:0; Y:0), (X:1; Y:0), (X:1; Y:1), (X:2; Y:1)),
    ((X:2; Y:0), (X:1; Y:1), (X:2; Y:1), (X:1; Y:2)),
    ((X:0; Y:1), (X:1; Y:1), (X:1; Y:2), (X:2; Y:2)),
    ((X:1; Y:0), (X:0; Y:1), (X:1; Y:1), (X:0; Y:2))
  );

{ SRS kicks with Y flipped for downward board coords.
  Index = FromRot*2 + (0=CW, 1=CCW) is awkward; store by transition. }

  { JLSTZ: from rot R clockwise (R -> R+1) }
  KickJLSTZ_CW: array[TRotation] of TKickRow = (
    { 0->1 } ((X: 0; Y: 0), (X:-1; Y: 0), (X:-1; Y:-1), (X: 0; Y: 2), (X:-1; Y: 2)),
    { 1->2 } ((X: 0; Y: 0), (X: 1; Y: 0), (X: 1; Y: 1), (X: 0; Y:-2), (X: 1; Y:-2)),
    { 2->3 } ((X: 0; Y: 0), (X: 1; Y: 0), (X: 1; Y:-1), (X: 0; Y: 2), (X: 1; Y: 2)),
    { 3->0 } ((X: 0; Y: 0), (X:-1; Y: 0), (X:-1; Y: 1), (X: 0; Y:-2), (X:-1; Y:-2))
  );

  KickJLSTZ_CCW: array[TRotation] of TKickRow = (
    { 0->3 } ((X: 0; Y: 0), (X: 1; Y: 0), (X: 1; Y:-1), (X: 0; Y: 2), (X: 1; Y: 2)),
    { 1->0 } ((X: 0; Y: 0), (X: 1; Y: 0), (X: 1; Y: 1), (X: 0; Y:-2), (X: 1; Y:-2)),
    { 2->1 } ((X: 0; Y: 0), (X:-1; Y: 0), (X:-1; Y:-1), (X: 0; Y: 2), (X:-1; Y: 2)),
    { 3->2 } ((X: 0; Y: 0), (X:-1; Y: 0), (X:-1; Y: 1), (X: 0; Y:-2), (X:-1; Y:-2))
  );

  KickI_CW: array[TRotation] of TKickRow = (
    { 0->1 } ((X: 0; Y: 0), (X:-2; Y: 0), (X: 1; Y: 0), (X:-2; Y: 1), (X: 1; Y:-2)),
    { 1->2 } ((X: 0; Y: 0), (X:-1; Y: 0), (X: 2; Y: 0), (X:-1; Y:-2), (X: 2; Y: 1)),
    { 2->3 } ((X: 0; Y: 0), (X: 2; Y: 0), (X:-1; Y: 0), (X: 2; Y:-1), (X:-1; Y: 2)),
    { 3->0 } ((X: 0; Y: 0), (X: 1; Y: 0), (X:-2; Y: 0), (X: 1; Y: 2), (X:-2; Y:-1))
  );

  KickI_CCW: array[TRotation] of TKickRow = (
    { 0->3 } ((X: 0; Y: 0), (X:-1; Y: 0), (X: 2; Y: 0), (X:-1; Y:-2), (X: 2; Y: 1)),
    { 1->0 } ((X: 0; Y: 0), (X: 2; Y: 0), (X:-1; Y: 0), (X: 2; Y:-1), (X:-1; Y: 2)),
    { 2->1 } ((X: 0; Y: 0), (X: 1; Y: 0), (X:-2; Y: 0), (X: 1; Y: 2), (X:-2; Y:-1)),
    { 3->2 } ((X: 0; Y: 0), (X:-2; Y: 0), (X: 1; Y: 0), (X:-2; Y: 1), (X: 1; Y:-2))
  );

function ShapeTable(Kind: TPieceKind): TLocalTable;
begin
  case Kind of
    pkI: Result := ShapeI;
    pkJ: Result := ShapeJ;
    pkL: Result := ShapeL;
    pkO: Result := ShapeO;
    pkS: Result := ShapeS;
    pkT: Result := ShapeT;
  else
    Result := ShapeZ;
  end;
end;

procedure GetLocalOffsets(Kind: TPieceKind; Rotation: TRotation; out Offsets: TCellOffsets);
var
  Table: TLocalTable;
  I: Integer;
begin
  Table := ShapeTable(Kind);
  for I := 0 to PieceCellCount - 1 do
    Offsets[I] := Table[Rotation, I];
end;

procedure GetPieceCells(const Piece: TActivePiece; out Cells: TCellOffsets);
var
  Local: TCellOffsets;
  I: Integer;
begin
  GetLocalOffsets(Piece.Kind, Piece.Rotation, Local);
  for I := 0 to PieceCellCount - 1 do
  begin
    Cells[I].X := Piece.X + Local[I].X;
    Cells[I].Y := Piece.Y + Local[I].Y;
  end;
end;

function KickTestCount(Kind: TPieceKind): Integer;
begin
  if Kind = pkO then
    Result := 1
  else
    Result := 5;
end;

procedure GetKickOffset(Kind: TPieceKind; FromRot: TRotation; Clockwise: Boolean;
  TestIndex: Integer; out DX, DY: Integer);
var
  P: TPoint;
begin
  if Kind = pkO then
  begin
    DX := 0;
    DY := 0;
    Exit;
  end;

  if Kind = pkI then
  begin
    if Clockwise then
      P := KickI_CW[FromRot, TestIndex]
    else
      P := KickI_CCW[FromRot, TestIndex];
  end
  else
  begin
    if Clockwise then
      P := KickJLSTZ_CW[FromRot, TestIndex]
    else
      P := KickJLSTZ_CCW[FromRot, TestIndex];
  end;

  DX := P.X;
  DY := P.Y;
end;

end.
