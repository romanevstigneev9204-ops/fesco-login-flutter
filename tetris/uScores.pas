unit uScores;

{$mode objfpc}{$H+}

{ Local personal-best storage (INI). Paths: user config dir, else next to EXE. }

interface

uses
  Classes, SysUtils, IniFiles, uTypes;

type
  TPersonalBests = record
    Sprint40Ms: Integer;   { best (lowest) finish time; 0 = none }
    UltraScore: Integer;   { best (highest) score; 0 = none }
    MarathonScore: Integer;
  end;

function ScoresFilePath: string;
function LoadPersonalBests: TPersonalBests;
procedure SavePersonalBests(const Bests: TPersonalBests);
{ Returns True if the run improved the stored PB (and was persisted). }
function TryUpdatePersonalBest(Mode: TGameMode; ElapsedMs, Score: Integer;
  Finished: TFinishReason; out Bests: TPersonalBests): Boolean;

implementation

function ScoresFilePath: string;
var
  Dir: string;
begin
  Dir := GetAppConfigDir(False);
  if Dir <> '' then
  begin
    ForceDirectories(Dir);
    Result := IncludeTrailingPathDelimiter(Dir) + 'tetris-scores.ini';
  end
  else
    Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) +
      'tetris-scores.ini';
end;

function LoadPersonalBests: TPersonalBests;
var
  Ini: TIniFile;
begin
  Result.Sprint40Ms := 0;
  Result.UltraScore := 0;
  Result.MarathonScore := 0;
  Ini := TIniFile.Create(ScoresFilePath);
  try
    Result.Sprint40Ms := Ini.ReadInteger('PersonalBest', 'Sprint40Ms', 0);
    Result.UltraScore := Ini.ReadInteger('PersonalBest', 'UltraScore', 0);
    Result.MarathonScore := Ini.ReadInteger('PersonalBest', 'MarathonScore', 0);
  finally
    Ini.Free;
  end;
end;

procedure SavePersonalBests(const Bests: TPersonalBests);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ScoresFilePath);
  try
    Ini.WriteInteger('PersonalBest', 'Sprint40Ms', Bests.Sprint40Ms);
    Ini.WriteInteger('PersonalBest', 'UltraScore', Bests.UltraScore);
    Ini.WriteInteger('PersonalBest', 'MarathonScore', Bests.MarathonScore);
  finally
    Ini.Free;
  end;
end;

function TryUpdatePersonalBest(Mode: TGameMode; ElapsedMs, Score: Integer;
  Finished: TFinishReason; out Bests: TPersonalBests): Boolean;
begin
  Result := False;
  Bests := LoadPersonalBests;
  case Mode of
    gmSprint40:
      begin
        if Finished <> frGoalReached then
          Exit;
        if (Bests.Sprint40Ms = 0) or (ElapsedMs < Bests.Sprint40Ms) then
        begin
          Bests.Sprint40Ms := ElapsedMs;
          Result := True;
        end;
      end;
    gmUltra:
      begin
        { Count completed Ultra (time up) or top-out score. }
        if not (Finished in [frTimeUp, frTopOut]) then
          Exit;
        if Score > Bests.UltraScore then
        begin
          Bests.UltraScore := Score;
          Result := True;
        end;
      end;
    gmMarathon:
      begin
        if Finished <> frTopOut then
          Exit;
        if Score > Bests.MarathonScore then
        begin
          Bests.MarathonScore := Score;
          Result := True;
        end;
      end;
  end;
  if Result then
    SavePersonalBests(Bests);
end;

end.
