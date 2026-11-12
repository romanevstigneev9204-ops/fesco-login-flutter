unit uMainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  LCLType, uTypes, uPieces, uGame, uScores;

type
  TAppPhase = (apMenu, apCountdown, apPlaying);

  { TMainForm }

  TMainForm = class(TForm)
    PanelMenu: TPanel;
    PanelPlay: TPanel;
    PaintBoard: TPaintBox;
    PaintNext: TPaintBox;
    PanelSide: TPanel;
    LblTitle: TLabel;
    LblMode: TLabel;
    LblStat1Caption: TLabel;
    LblStat1: TLabel;
    LblStat2Caption: TLabel;
    LblStat2: TLabel;
    LblStat3Caption: TLabel;
    LblStat3: TLabel;
    LblNextCaption: TLabel;
    LblStatus: TLabel;
    LblHelp: TLabel;
    LblCountdown: TLabel;
    LblMenuTitle: TLabel;
    LblMenuHint: TLabel;
    LblMenuFooter: TLabel;
    LblPbMarathon: TLabel;
    LblPbSprint: TLabel;
    LblPbUltra: TLabel;
    BtnMarathon: TButton;
    BtnSprint: TButton;
    BtnUltra: TButton;
    TimerGame: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PaintBoardPaint(Sender: TObject);
    procedure PaintNextPaint(Sender: TObject);
    procedure TimerGameTimer(Sender: TObject);
    procedure BtnMarathonClick(Sender: TObject);
    procedure BtnSprintClick(Sender: TObject);
    procedure BtnUltraClick(Sender: TObject);
  private
    FGame: TGame;
    FCellSize: Integer;
    FPhase: TAppPhase;
    FSelectedMode: TGameMode;
    FMenuIndex: Integer;
    FCountdownLeft: Integer;
    FCountdownAccMs: Integer;
    FPbReported: Boolean;
    FLastPbImproved: Boolean;
    procedure ShowMenu;
    procedure StartMode(AMode: TGameMode);
    procedure BeginCountdown;
    procedure BeginPlaying;
    procedure ReturnToMenu;
    procedure RestartSameMode;
    procedure UpdateHud;
    procedure RefreshMenuPb;
    procedure HighlightMenuSelection;
    procedure DrawCell(ACanvas: TCanvas; X, Y, Size: Integer; Cell: TCellValue);
    function ColorForCell(Cell: TCellValue): TColor;
    procedure HandleFinishedRun;
    function StatusText: string;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

const
  BoardCellPx = 28;
  NextCellPx = 22;
  CountdownStepMs = 1000;

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
  FPhase := apMenu;
  FMenuIndex := 0;
  FSelectedMode := gmMarathon;
  FPbReported := False;
  FLastPbImproved := False;
  KeyPreview := True;
  TimerGame.Interval := 16;
  TimerGame.Enabled := True;
  ShowMenu;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  TimerGame.Enabled := False;
  FreeAndNil(FGame);
end;

procedure TMainForm.RefreshMenuPb;
var
  B: TPersonalBests;
begin
  B := LoadPersonalBests;
  if B.MarathonScore > 0 then
    LblPbMarathon.Caption := Format('Marathon PB: %d', [B.MarathonScore])
  else
    LblPbMarathon.Caption := 'Marathon PB: —';
  if B.Sprint40Ms > 0 then
    LblPbSprint.Caption := 'Sprint PB: ' + FormatRaceTime(B.Sprint40Ms)
  else
    LblPbSprint.Caption := 'Sprint PB: —';
  if B.UltraScore > 0 then
    LblPbUltra.Caption := Format('Ultra PB: %d', [B.UltraScore])
  else
    LblPbUltra.Caption := 'Ultra PB: —';
end;

procedure TMainForm.HighlightMenuSelection;
begin
  BtnMarathon.Font.Style := [];
  BtnSprint.Font.Style := [];
  BtnUltra.Font.Style := [];
  case FMenuIndex of
    0: BtnMarathon.Font.Style := [fsBold];
    1: BtnSprint.Font.Style := [fsBold];
    2: BtnUltra.Font.Style := [fsBold];
  end;
end;

procedure TMainForm.ShowMenu;
begin
  FPhase := apMenu;
  PanelMenu.Visible := True;
  PanelPlay.Visible := False;
  LblCountdown.Visible := False;
  RefreshMenuPb;
  HighlightMenuSelection;
  Caption := 'Tetris';
end;

procedure TMainForm.StartMode(AMode: TGameMode);
begin
  FSelectedMode := AMode;
  FGame.NewGame(AMode);
  FPbReported := False;
  FLastPbImproved := False;
  PanelMenu.Visible := False;
  PanelPlay.Visible := True;
  LblMode.Caption := GameModeName(AMode);
  Caption := 'Tetris — ' + GameModeName(AMode);
  BeginCountdown;
  UpdateHud;
  PaintBoard.Invalidate;
  PaintNext.Invalidate;
end;

procedure TMainForm.BeginCountdown;
begin
  FPhase := apCountdown;
  FCountdownLeft := 3;
  FCountdownAccMs := 0;
  FGame.TogglePause; { pause until countdown ends }
  LblCountdown.Caption := '3';
  LblCountdown.Visible := True;
  LblStatus.Caption := 'Get ready';
end;

procedure TMainForm.BeginPlaying;
begin
  FPhase := apPlaying;
  LblCountdown.Visible := False;
  if FGame.Paused then
    FGame.TogglePause;
  LblStatus.Caption := '';
end;

procedure TMainForm.ReturnToMenu;
begin
  ShowMenu;
end;

procedure TMainForm.RestartSameMode;
begin
  StartMode(FSelectedMode);
end;

procedure TMainForm.BtnMarathonClick(Sender: TObject);
begin
  FMenuIndex := 0;
  StartMode(gmMarathon);
end;

procedure TMainForm.BtnSprintClick(Sender: TObject);
begin
  FMenuIndex := 1;
  StartMode(gmSprint40);
end;

procedure TMainForm.BtnUltraClick(Sender: TObject);
begin
  FMenuIndex := 2;
  StartMode(gmUltra);
end;

procedure TMainForm.HandleFinishedRun;
var
  Bests: TPersonalBests;
begin
  if FPbReported or (FGame = nil) or (not FGame.GameOver) then
    Exit;
  FPbReported := True;
  FLastPbImproved := TryUpdatePersonalBest(
    FGame.Mode, FGame.ElapsedMs, FGame.Score, FGame.FinishReason, Bests);
end;

function TMainForm.StatusText: string;
begin
  Result := '';
  if FPhase = apCountdown then
  begin
    Result := 'Get ready';
    Exit;
  end;
  if FGame = nil then
    Exit;
  if FGame.GameOver then
  begin
    case FGame.FinishReason of
      frGoalReached:
        Result := 'CLEAR! ' + FormatRaceTime(FGame.ElapsedMs);
      frTimeUp:
        Result := 'TIME UP' + LineEnding + 'Score ' + IntToStr(FGame.Score);
      frTopOut:
        Result := 'TOP OUT';
    else
      Result := 'GAME OVER';
    end;
    if FLastPbImproved then
      Result := Result + LineEnding + 'NEW PB!';
    Result := Result + LineEnding + 'R retry · Esc menu';
  end
  else if FGame.Paused then
    Result := 'PAUSED' + LineEnding + 'Esc menu';
end;

procedure TMainForm.UpdateHud;
begin
  if FGame = nil then
    Exit;

  LblMode.Caption := GameModeName(FGame.Mode);

  case FGame.Mode of
    gmSprint40:
      begin
        LblStat1Caption.Caption := 'TIME';
        LblStat1.Caption := FormatRaceTime(FGame.ElapsedMs);
        LblStat2Caption.Caption := 'LEFT';
        LblStat2.Caption := IntToStr(FGame.LinesRemaining);
        LblStat3Caption.Caption := 'LINES';
        LblStat3.Caption := Format('%d / %d', [FGame.Lines, SprintGoalLines]);
      end;
    gmUltra:
      begin
        LblStat1Caption.Caption := 'SCORE';
        LblStat1.Caption := IntToStr(FGame.Score);
        LblStat2Caption.Caption := 'LEFT';
        LblStat2.Caption := FormatRaceTime(FGame.TimeRemainingMs);
        LblStat3Caption.Caption := 'LINES';
        LblStat3.Caption := IntToStr(FGame.Lines);
      end;
  else
    begin
      LblStat1Caption.Caption := 'SCORE';
      LblStat1.Caption := IntToStr(FGame.Score);
      LblStat2Caption.Caption := 'LEVEL';
      LblStat2.Caption := IntToStr(FGame.Level);
      LblStat3Caption.Caption := 'LINES';
      LblStat3.Caption := IntToStr(FGame.Lines);
    end;
  end;

  if FGame.GameOver then
    HandleFinishedRun;
  LblStatus.Caption := StatusText;
end;

procedure TMainForm.TimerGameTimer(Sender: TObject);
var
  Dt: Integer;
begin
  if FGame = nil then
    Exit;

  Dt := TimerGame.Interval;
  if Dt <= 0 then
    Dt := 16;

  case FPhase of
    apMenu:
      Exit;
    apCountdown:
      begin
        Inc(FCountdownAccMs, Dt);
        if FCountdownAccMs >= CountdownStepMs then
        begin
          Dec(FCountdownAccMs, CountdownStepMs);
          Dec(FCountdownLeft);
          if FCountdownLeft > 0 then
            LblCountdown.Caption := IntToStr(FCountdownLeft)
          else if FCountdownLeft = 0 then
            LblCountdown.Caption := 'GO'
          else
            BeginPlaying;
        end;
        PaintBoard.Invalidate;
      end;
    apPlaying:
      begin
        FGame.AdvanceTime(Dt);
        FGame.Tick;
        UpdateHud;
        PaintBoard.Invalidate;
        PaintNext.Invalidate;
      end;
  end;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case FPhase of
    apMenu:
      begin
        case Key of
          VK_UP:
            begin
              if FMenuIndex > 0 then
                Dec(FMenuIndex)
              else
                FMenuIndex := 2;
              HighlightMenuSelection;
              Key := 0;
            end;
          VK_DOWN:
            begin
              if FMenuIndex < 2 then
                Inc(FMenuIndex)
              else
                FMenuIndex := 0;
              HighlightMenuSelection;
              Key := 0;
            end;
          VK_RETURN, VK_SPACE:
            begin
              case FMenuIndex of
                0: StartMode(gmMarathon);
                1: StartMode(gmSprint40);
                2: StartMode(gmUltra);
              end;
              Key := 0;
            end;
          Ord('1'):
            begin
              StartMode(gmMarathon);
              Key := 0;
            end;
          Ord('2'):
            begin
              StartMode(gmSprint40);
              Key := 0;
            end;
          Ord('3'):
            begin
              StartMode(gmUltra);
              Key := 0;
            end;
          VK_ESCAPE:
            begin
              Close;
              Key := 0;
            end;
        end;
      end;

    apCountdown:
      begin
        if Key = VK_ESCAPE then
        begin
          ReturnToMenu;
          Key := 0;
        end;
      end;

    apPlaying:
      begin
        if FGame = nil then
          Exit;

        case Key of
          VK_ESCAPE:
            begin
              ReturnToMenu;
              Key := 0;
            end;
          VK_LEFT:
            begin
              if not FGame.GameOver then
                FGame.MoveLeft;
              Key := 0;
            end;
          VK_RIGHT:
            begin
              if not FGame.GameOver then
                FGame.MoveRight;
              Key := 0;
            end;
          VK_DOWN:
            begin
              if not FGame.GameOver then
                FGame.SoftDrop;
              Key := 0;
            end;
          VK_UP, Ord('X'), Ord('x'):
            begin
              if not FGame.GameOver then
                FGame.RotateCW;
              Key := 0;
            end;
          VK_SPACE:
            begin
              if not FGame.GameOver then
                FGame.HardDrop;
              Key := 0;
            end;
          Ord('P'), Ord('p'):
            begin
              if not FGame.GameOver then
                FGame.TogglePause;
              Key := 0;
            end;
          Ord('R'), Ord('r'), VK_RETURN:
            begin
              if FGame.GameOver then
                RestartSameMode;
              Key := 0;
            end;
          Ord('M'), Ord('m'):
            begin
              if FGame.GameOver then
                ReturnToMenu;
              Key := 0;
            end;
        else
          Exit;
        end;

        UpdateHud;
        PaintBoard.Invalidate;
        PaintNext.Invalidate;
      end;
  end;
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

  if FGame.HasCurrent and (not FGame.GameOver) and (FPhase <> apCountdown) then
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
