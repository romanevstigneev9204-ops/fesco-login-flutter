unit uBoard;

{$mode objfpc}{$H+}

interface

uses
  uTypes, uPieces;

procedure ClearBoard(var Board: TBoardCells);

function CellEmpty(const Board: TBoardCells; X, Y: Integer): Boolean;

{ True if every cell of Piece is inside the board and empty. }
function PieceFits(const Board: TBoardCells; const Piece: TActivePiece): Boolean;

procedure LockPiece(var Board: TBoardCells; const Piece: TActivePiece);

{ Clears full rows; returns number of lines cleared (0..4). Board is compacted. }
function ClearFullLines(var Board: TBoardCells): Integer;

implementation

procedure ClearBoard(var Board: TBoardCells);
var
  X, Y: Integer;
begin
  for X := 0 to BoardWidth - 1 do
    for Y := 0 to BoardHeight - 1 do
      Board[X, Y] := 0;
end;

function CellEmpty(const Board: TBoardCells; X, Y: Integer): Boolean;
begin
  if (X < 0) or (X >= BoardWidth) or (Y < 0) or (Y >= BoardHeight) then
    Exit(False);
  Result := Board[X, Y] = 0;
end;

function PieceFits(const Board: TBoardCells; const Piece: TActivePiece): Boolean;
var
  Cells: TCellOffsets;
  I: Integer;
begin
  GetPieceCells(Piece, Cells);
  for I := 0 to PieceCellCount - 1 do
    if not CellEmpty(Board, Cells[I].X, Cells[I].Y) then
      Exit(False);
  Result := True;
end;

procedure LockPiece(var Board: TBoardCells; const Piece: TActivePiece);
var
  Cells: TCellOffsets;
  I: Integer;
  V: TCellValue;
begin
  GetPieceCells(Piece, Cells);
  V := PieceKindToCell(Piece.Kind);
  for I := 0 to PieceCellCount - 1 do
    if (Cells[I].X >= 0) and (Cells[I].X < BoardWidth) and
       (Cells[I].Y >= 0) and (Cells[I].Y < BoardHeight) then
      Board[Cells[I].X, Cells[I].Y] := V;
end;

function RowIsFull(const Board: TBoardCells; Y: Integer): Boolean;
var
  X: Integer;
begin
  for X := 0 to BoardWidth - 1 do
    if Board[X, Y] = 0 then
      Exit(False);
  Result := True;
end;

procedure CopyRow(var Board: TBoardCells; SrcY, DstY: Integer);
var
  X: Integer;
begin
  for X := 0 to BoardWidth - 1 do
    Board[X, DstY] := Board[X, SrcY];
end;

procedure ClearRow(var Board: TBoardCells; Y: Integer);
var
  X: Integer;
begin
  for X := 0 to BoardWidth - 1 do
    Board[X, Y] := 0;
end;

function ClearFullLines(var Board: TBoardCells): Integer;
var
  WriteY, ReadY: Integer;
begin
  Result := 0;
  WriteY := BoardHeight - 1;
  for ReadY := BoardHeight - 1 downto 0 do
  begin
    if RowIsFull(Board, ReadY) then
      Inc(Result)
    else
    begin
      if WriteY <> ReadY then
        CopyRow(Board, ReadY, WriteY);
      Dec(WriteY);
    end;
  end;
  while WriteY >= 0 do
  begin
    ClearRow(Board, WriteY);
    Dec(WriteY);
  end;
end;

end.
