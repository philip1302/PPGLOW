unit PPG.TestDesktop;

{ Werkzeug fuer Testlauf, Benchmark und Demo (nicht Teil der Suite):
  Schalter /hidden startet das Programm auf einem eigenen Windows-Desktop
  ("PPGlowTest-<Prozess-Id>", je Lauf ein eigener) neu. Dort ist fuer Windows alles sichtbar (Fokus,
  IsWindowVisible, Popups, Toasts), auf dem Bildschirm des Anwenders erscheint
  aber nichts, und seine Maus stoert die Tests nicht. Ausgabe (stdout/stderr)
  und Exit-Code kommen beim Aufrufer an.

  Aufruf ganz am Anfang des Hauptprogramms, vor Application.Initialize:
    if PPGRunOnHiddenDesktop then
      Exit; }

interface

/// True: Das Programm lief auf dem Testdesktop und ist fertig (ExitCode ist
/// gesetzt), der Aufrufer beendet sich sofort. False: normal weitermachen
/// (ohne /hidden oder schon auf dem Testdesktop).
function PPGRunOnHiddenDesktop: Boolean;

/// Laeuft der Prozess auf dem Testdesktop (gestartet mit /hidden)?
function PPGOnHiddenDesktop: Boolean;

implementation

uses
  Winapi.Windows, System.SysUtils;

const
  TestDesktopName = 'PPGlowTest';
  SwitchHidden = 'hidden';
  SwitchOnDesktop = 'ondesktop';

function PPGOnHiddenDesktop: Boolean;
begin
  Result := FindCmdLineSwitch(SwitchOnDesktop, ['/', '-'], True);
end;

function QuoteArg(const S: string): string;
begin
  if (S = '') or (Pos(' ', S) > 0) or (Pos(#9, S) > 0) then
    Result := '"' + S + '"'
  else
    Result := S;
end;

/// Eigene Befehlszeile ohne /hidden, dafuer mit /ondesktop.
function ChildCommandLine: string;
var
  I: Integer;
  P: string;
begin
  Result := QuoteArg(ParamStr(0));
  for I := 1 to ParamCount do
  begin
    P := ParamStr(I);
    if SameText(P, '/' + SwitchHidden) or SameText(P, '-' + SwitchHidden) then
      Continue;
    Result := Result + ' ' + QuoteArg(P);
  end;
  Result := Result + ' /' + SwitchOnDesktop;
end;

/// Standard-Handle vererbbar machen; 0, wenn es keins gibt (GUI-Programm).
function InheritableStdHandle(Which: DWORD): THandle;
begin
  Result := GetStdHandle(Which);
  if (Result = INVALID_HANDLE_VALUE) or (Result = 0) then
    Result := 0
  else
    SetHandleInformation(Result, HANDLE_FLAG_INHERIT, HANDLE_FLAG_INHERIT);
end;

function PPGRunOnHiddenDesktop: Boolean;
var
  Desk: HDESK;
  SI: TStartupInfo;
  PI: TProcessInformation;
  Cmd, DeskPath, DeskName: string;
  Code: DWORD;
  HIn, HOut, HErr: THandle;
begin
  Result := False;
  if PPGOnHiddenDesktop or not FindCmdLineSwitch(SwitchHidden, ['/', '-'], True) then
    Exit;
  // Eigener Desktop je Lauf: parallele Laeufe (z. B. mehrere Agenten) teilen
  // sich sonst Fokus, Vordergrund und Popups
  DeskName := TestDesktopName + '-' + IntToStr(GetCurrentProcessId);
  Desk := CreateDesktop(PChar(DeskName), nil, nil, 0, GENERIC_ALL, nil);
  if Desk = 0 then
    RaiseLastOSError;
  try
    FillChar(SI, SizeOf(SI), 0);
    SI.cb := SizeOf(SI);
    DeskPath := 'WinSta0\' + DeskName;
    SI.lpDesktop := PChar(DeskPath);
    HIn := InheritableStdHandle(STD_INPUT_HANDLE);
    HOut := InheritableStdHandle(STD_OUTPUT_HANDLE);
    HErr := InheritableStdHandle(STD_ERROR_HANDLE);
    if (HOut <> 0) or (HErr <> 0) then
    begin
      SI.dwFlags := STARTF_USESTDHANDLES;
      SI.hStdInput := HIn;
      SI.hStdOutput := HOut;
      SI.hStdError := HErr;
    end;
    Cmd := ChildCommandLine;
    UniqueString(Cmd); // CreateProcessW darf den Puffer beschreiben
    FillChar(PI, SizeOf(PI), 0);
    if not CreateProcess(nil, PChar(Cmd), nil, nil, True, 0, nil, nil, SI, PI) then
      RaiseLastOSError;
    try
      WaitForSingleObject(PI.hProcess, INFINITE);
      if not GetExitCodeProcess(PI.hProcess, Code) then
        Code := DWORD(-1);
      ExitCode := Integer(Code);
    finally
      CloseHandle(PI.hThread);
      CloseHandle(PI.hProcess);
    end;
  finally
    CloseDesktop(Desk);
  end;
  Result := True;
end;

end.
