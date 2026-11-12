unit uTypes;

{$mode objfpc}{$H+}
{$codepage UTF8}

interface

uses
  SysUtils;

const
  BoardWidth  = 10;
  BoardHeight = 20;
  PieceCellCount = 4;

const
  SprintGoalLines = 40;
  UltraTimeLimitMs = 2 * 60 * 1000; { 2:00 Blitz }

type
  { Cell value: 0 = empty, Ord(TPieceKind)+1 when locked }
  TCellValue = 0..7;

  TBoardCells = array[0..BoardWidth - 1, 0..BoardHeight - 1] of TCellValue;

  TPieceKind = (pkI, pkJ, pkL, pkO, pkS, pkT, pkZ);

  TRotation = 0..3;

  TGameMode = (gmMarathon, gmSprint40, gmUltra);

  { Why the run stopped. frNone while still playing. }
  TFinishReason = (frNone, frTopOut, frGoalReached, frTimeUp);

  TPoint = record
    X, Y: Integer;
  end;

  TCellOffsets = array[0..PieceCellCount - 1] of TPoint;

  TActivePiece = record
    Kind: TPieceKind;
    Rotation: TRotation;
    X, Y: Integer; { origin of the 4x4 local grid on the board }
  end;

function GameModeName(Mode: TGameMode): string;
function FormatRaceTime(Ms: Integer): string;

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

function GameModeName(Mode: TGameMode): string;
begin
  case Mode of
    gmMarathon: Result := 'Марафон';
    gmSprint40: Result := 'Спринт 40 линий';
    gmUltra: Result := 'Ультра 2:00';
  else
    Result := 'Неизвестно';
  end;
end;

function FormatRaceTime(Ms: Integer): string;
var
  TotalSec, Min, Sec, Centi: Integer;
begin
  if Ms < 0 then
    Ms := 0;
  TotalSec := Ms div 1000;
  Min := TotalSec div 60;
  Sec := TotalSec mod 60;
  Centi := (Ms mod 1000) div 10;
  Result := Format('%.2d:%.2d.%.2d', [Min, Sec, Centi]);
end;

end.
