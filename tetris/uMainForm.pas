unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLType, uTypes, uPieces, uGame;

type
  { TMainForm }

  TMainForm = class(TForm)
    PaintBoard: TPaintBox;
    PaintNext: TPaintBox;
    PanelSide: TPanel;
    LblTitle: TLabel;
    LblScoreCaption: TLabel;
    LblScore: TLabel;
    LblLevelCaption: TLabel;
    LblLevel: TLabel;
    LblLinesCaption: TLabel;
    LblLines: TLabel;
    LblNextCaption: TLabel;
    LblStatus: TLabel;
    LblHelp: TLabel;
    TimerGame: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PaintBoardPaint(Sender: TObject);
    procedure PaintNextPaint(Sender: TObject);
    procedure TimerGameTimer(Sender: TObject);
  private
    FGame: TGame;
    FCellSize: Integer;
    procedure UpdateHud;
    procedure DrawCell(ACanvas: TCanvas; X, Y, Size: Integer; Cell: TCellValue);
    function ColorForCell(Cell: TCellValue): TColor;
    procedure RestartGame;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

const
  BoardCellPx = 28;
  NextCellPx = 22;

function TMainForm.ColorForCell(Cell: TCellValue): TColor;
begin
  case Cell of
    1: Result := RGBToColor(0, 240, 240);   { I cyan }
    2: Result := RGBToColor(0, 0, 240);     { J blue }
    3: Result := RGBToColor(240, 160, 0);   { L orange }
    4: Result := RGBToColor(240, 240, 0);   { O yellow }
    5: Result := RGBToColor(0, 240, 0);     { S green }
    6: Result := RGBToColor(160, 0, 240);   { T purple }
    7: Result := RGBToColor(240, 0, 0);     { Z red }
  else
    Result := RGBToColor(28, 28, 36);
  end;
end;

procedure TMainForm.DrawCell(ACanvas: TCanvas; X, Y, Size: Integer; Cell: TCellValue);
var
  R: TRect;
  Fill: TColor;
begin
  R := Bounds(X, Y, Size - 1, Size - 1);
  Fill := ColorForCell(Cell);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := Fill;
  if Cell = 0 then
  begin
    ACanvas.Pen.Color := RGBToColor(45, 45, 55);
    ACanvas.Rectangle(R);
  end
  else
  begin
    ACanvas.Pen.Color := RGBToColor(20, 20, 24);
    ACanvas.Rectangle(R);
    { light edge }
    ACanvas.Pen.Color := RGBToColor(255, 255, 255);
    ACanvas.MoveTo(R.Left + 1, R.Bottom - 2);
    ACanvas.LineTo(R.Left + 1, R.Top + 1);
    ACanvas.LineTo(R.Right - 2, R.Top + 1);
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FCellSize := BoardCellPx;
  FGame := TGame.Create;
  FGame.NewGame;
  KeyPreview := True;
  TimerGame.Interval := 16;
  TimerGame.Enabled := True;
  UpdateHud;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TimerGame.Enabled := False;
  FreeAndNil(FGame);
end;

procedure TMainForm.RestartGame;
begin
  FGame.NewGame;
  UpdateHud;
  PaintBoard.Invalidate;
  PaintNext.Invalidate;
end;

procedure TMainForm.UpdateHud;
begin
  LblScore.Caption := IntToStr(FGame.Score);
  LblLevel.Caption := IntToStr(FGame.Level);
  LblLines.Caption := IntToStr(FGame.Lines);
  if FGame.GameOver then
    LblStatus.Caption := 'GAME OVER — R to restart'
  else if FGame.Paused then
    LblStatus.Caption := 'PAUSED'
  else
    LblStatus.Caption := '';
end;

procedure TMainForm.TimerGameTimer(Sender: TObject);
begin
  if FGame = nil then
    Exit;
  FGame.Tick;
  UpdateHud;
  PaintBoard.Invalidate;
  PaintNext.Invalidate;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if FGame = nil then
    Exit;

  case Key of
    VK_LEFT:
      begin
        FGame.MoveLeft;
        Key := 0;
      end;
    VK_RIGHT:
      begin
        FGame.MoveRight;
        Key := 0;
      end;
    VK_DOWN:
      begin
        FGame.SoftDrop;
        Key := 0;
      end;
    VK_UP, Ord('X'), Ord('x'):
      begin
        FGame.RotateCW;
        Key := 0;
      end;
    VK_SPACE:
      begin
        FGame.HardDrop;
        Key := 0;
      end;
    Ord('P'), Ord('p'):
      begin
        FGame.TogglePause;
        Key := 0;
      end;
    Ord('R'), Ord('r'), VK_RETURN:
      begin
        if FGame.GameOver then
          RestartGame;
        Key := 0;
      end;
  else
    Exit;
  end;

  UpdateHud;
  PaintBoard.Invalidate;
  PaintNext.Invalidate;
end;

procedure TMainForm.PaintBoardPaint(Sender: TObject);
var
  X, Y: Integer;
  Cell: TCellValue;
  Cells: TCellOffsets;
  I: Integer;
  OriginX, OriginY: Integer;
begin
  if FGame = nil then
    Exit;

  OriginX := 0;
  OriginY := 0;

  PaintBoard.Canvas.Brush.Color := RGBToColor(18, 18, 24);
  PaintBoard.Canvas.FillRect(PaintBoard.ClientRect);

  for Y := 0 to BoardHeight - 1 do
    for X := 0 to BoardWidth - 1 do
    begin
      Cell := FGame.CellAt(X, Y);
      DrawCell(PaintBoard.Canvas,
        OriginX + X * FCellSize,
        OriginY + Y * FCellSize,
        FCellSize, Cell);
    end;

  if FGame.HasCurrent and (not FGame.GameOver) then
  begin
    GetPieceCells(FGame.Current, Cells);
    Cell := PieceKindToCell(FGame.Current.Kind);
    for I := 0 to PieceCellCount - 1 do
    begin
      X := Cells[I].X;
      Y := Cells[I].Y;
      if (X >= 0) and (X < BoardWidth) and (Y >= 0) and (Y < BoardHeight) then
        DrawCell(PaintBoard.Canvas,
          OriginX + X * FCellSize,
          OriginY + Y * FCellSize,
          FCellSize, Cell);
    end;
  end;

  { border }
  PaintBoard.Canvas.Brush.Style := bsClear;
  PaintBoard.Canvas.Pen.Color := RGBToColor(90, 90, 110);
  PaintBoard.Canvas.Rectangle(0, 0, BoardWidth * FCellSize, BoardHeight * FCellSize);
end;

procedure TMainForm.PaintNextPaint(Sender: TObject);
var
  Preview: TActivePiece;
  Cells: TCellOffsets;
  I, MinX, MinY, MaxX, MaxY, W, H, Ox, Oy: Integer;
  Cell: TCellValue;
begin
  PaintNext.Canvas.Brush.Color := RGBToColor(18, 18, 24);
  PaintNext.Canvas.FillRect(PaintNext.ClientRect);

  if FGame = nil then
    Exit;

  Preview.Kind := FGame.NextPiece;
  Preview.Rotation := 0;
  Preview.X := 0;
  Preview.Y := 0;
  GetPieceCells(Preview, Cells);

  MinX := Cells[0].X;
  MinY := Cells[0].Y;
  MaxX := MinX;
  MaxY := MinY;
  for I := 1 to PieceCellCount - 1 do
  begin
    if Cells[I].X < MinX then MinX := Cells[I].X;
    if Cells[I].Y < MinY then MinY := Cells[I].Y;
    if Cells[I].X > MaxX then MaxX := Cells[I].X;
    if Cells[I].Y > MaxY then MaxY := Cells[I].Y;
  end;

  W := (MaxX - MinX + 1) * NextCellPx;
  H := (MaxY - MinY + 1) * NextCellPx;
  Ox := (PaintNext.Width - W) div 2;
  Oy := (PaintNext.Height - H) div 2;
  Cell := PieceKindToCell(Preview.Kind);

  for I := 0 to PieceCellCount - 1 do
    DrawCell(PaintNext.Canvas,
      Ox + (Cells[I].X - MinX) * NextCellPx,
      Oy + (Cells[I].Y - MinY) * NextCellPx,
      NextCellPx, Cell);
end;

end.
