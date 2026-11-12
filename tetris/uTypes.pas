unit uTypes;

{$mode objfpc}{$H+}

interface

const
  BoardWidth  = 10;
  BoardHeight = 20;
  PieceCellCount = 4;

type
  { Cell value: 0 = empty, Ord(TPieceKind)+1 when locked }
  TCellValue = 0..7;

  TBoardCells = array[0..BoardWidth - 1, 0..BoardHeight - 1] of TCellValue;

  TPieceKind = (pkI, pkJ, pkL, pkO, pkS, pkT, pkZ);

  TRotation = 0..3;

  TPoint = record
    X, Y: Integer;
  end;

  TCellOffsets = array[0..PieceCellCount - 1] of TPoint;

  TActivePiece = record
    Kind: TPieceKind;
    Rotation: TRotation;
    X, Y: Integer; { origin of the 4x4 local grid on the board }
  end;

function PieceKindToCell(Kind: TPieceKind): TCellValue;
function CellToPieceKind(Cell: TCellValue): TPieceKind;

implementation

function PieceKindToCell(Kind: TPieceKind): TCellValue;
begin
  Result := Ord(Kind) + 1;
end;

function CellToPieceKind(Cell: TCellValue): TPieceKind;
begin
  Result := TPieceKind(Cell - 1);
end;

end.
