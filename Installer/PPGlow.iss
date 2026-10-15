; PPGlow Components - Setup (Inno Setup 6)
;
; Quelltext-Installer: kopiert Quellen und Paketprojekte und baut die Pakete
; auf dem Zielrechner mit dem dort installierten Delphi (Build\install.ps1).
; Fertige BPLs liefert das Setup nicht aus: sie passen nur zu genau einer
; Delphi-Version, und auf den Build-Rechnern der CI gibt es kein Delphi.
;
; Bauen (CI: .github\workflows\installer.yml):
;   powershell -File Installer\stage.ps1 -Out stage
;   ISCC.exe /DAppVersion=1.0.0 /DVersionInfo=1.0.0.0 Installer\PPGlow.iss
; Ergebnis: out\PPGlow-Setup-<AppVersion>.exe

#define AppName "PPGlow Components"
#ifndef AppVersion
  #define AppVersion "0.0.0-dev"
#endif
#ifndef VersionInfo
  #define VersionInfo "0.0.0.0"
#endif
#ifndef StageDir
  #define StageDir "..\stage"
#endif
#ifndef OutDir
  #define OutDir "..\out"
#endif

[Setup]
AppId={{6F1E3C2A-8B4D-4E71-9A55-2C7D0B9E4F13}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=PPGlow
AppPublisherURL=https://github.com/philip1302/ppglow
AppSupportURL=https://github.com/philip1302/ppglow/issues
AppUpdatesURL=https://github.com/philip1302/ppglow/releases
VersionInfoVersion={#VersionInfo}
VersionInfoProductVersion={#VersionInfo}
DefaultDirName={localappdata}\PPGlow
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir={#OutDir}
OutputBaseFilename=PPGlow-Setup-{#AppVersion}
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
InfoBeforeFile=LIESMICH.txt
UninstallDisplayName={#AppName} {#AppVersion}
SetupLogging=yes
CloseApplications=no
UsedUserAreasWarning=no

[Languages]
Name: "de"; MessagesFile: "compiler:Languages\German.isl"

[Messages]
de.FinishedLabel=Die Komponenten sind installiert.%n%nRAD Studio starten und ein VCL-Formular im Designer öffnen: die Palette zeigt "PPGlow" und "PPGlow DB".%n%nProtokolle: Ordner Logs im Installationsordner.

[Types]
Name: "full"; Description: "Alle gefundenen Delphi-Versionen"
Name: "custom"; Description: "Auswahl"; Flags: iscustom

[Components]
Name: "d11"; Description: "Delphi 11 Alexandria (BDS 22.0)"; Types: full custom; Check: BdsInstalled('22.0')
Name: "d13"; Description: "Delphi 13 Florence (BDS 37.0)"; Types: full custom; Check: BdsInstalled('37.0')

[Tasks]
Name: "db"; Description: "Datensensitive Komponenten (Palette ""PPGlow DB"")"
Name: "win64"; Description: "Zusätzlich Win64-Pakete bauen (für 64-Bit-Anwendungen)"

[InstallDelete]
; Alte Quelltexte entfernen, damit nach einem Update keine verwaisten Units liegen bleiben
Type: filesandordirs; Name: "{app}\Source"
Type: filesandordirs; Name: "{app}\Packages"

[Files]
Source: "{#StageDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[UninstallDelete]
; Build-Ausgaben (vom Setup gebaut, nicht kopiert)
Type: filesandordirs; Name: "{app}\Lib"
Type: filesandordirs; Name: "{app}\Packages"
Type: filesandordirs; Name: "{app}\Logs"

[Code]
const
  SetupKey = 'Software\PPGlow\Setup';

var
  Failed: String;

function BdsInstalled(Ver: String): Boolean;
begin
  Result := RegKeyExists(HKEY_CURRENT_USER, 'Software\Embarcadero\BDS\' + Ver);
end;

function VersionName(Ver: String): String;
begin
  if Ver = '22.0' then
    Result := 'Delphi 11 Alexandria'
  else if Ver = '37.0' then
    Result := 'Delphi 13 Florence'
  else
    Result := 'BDS ' + Ver;
end;

function PowerShellExe: String;
begin
  Result := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
end;

function IdeRunning: Boolean;
var
  Code: Integer;
begin
  Result := Exec(PowerShellExe,
    '-NoProfile -NonInteractive -Command "if (Get-Process bds -ErrorAction SilentlyContinue) { exit 3 } else { exit 0 }"',
    '', SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 3);
end;

// Wartet, bis keine RAD-Studio-Instanz mehr laeuft; False = Anwender bricht ab
function WaitForIdeClosed: Boolean;
begin
  Result := True;
  while IdeRunning do
    if MsgBox('RAD Studio läuft noch.' + #13#10#13#10 +
      'Bitte alle RAD-Studio-Fenster schließen (die IDE überschreibt die Registry beim Beenden) ' +
      'und dann "Wiederholen" wählen.', mbError, MB_RETRYCANCEL) = IDCANCEL then
    begin
      Result := False;
      Exit;
    end;
end;

function InitializeSetup: Boolean;
begin
  Result := BdsInstalled('22.0') or BdsInstalled('37.0');
  if not Result then
    MsgBox('Es wurde kein unterstütztes RAD Studio gefunden (Delphi 11 Alexandria oder Delphi 13 Florence).' + #13#10#13#10 +
      'PPGlow wird bei der Installation mit Ihrem Delphi gebaut; ohne Delphi ist keine Installation möglich.',
      mbCriticalError, MB_OK);
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if (CurPageID = wpSelectComponents) and not (WizardIsComponentSelected('d11') or WizardIsComponentSelected('d13')) then
  begin
    MsgBox('Bitte mindestens eine Delphi-Version auswählen.', mbError, MB_OK);
    Result := False;
  end
  else if CurPageID = wpReady then
    Result := WaitForIdeClosed;
end;

// Protokolldatei: Installation im Installationsordner, Deinstallation im
// Temp-Ordner (Logs wird beim Deinstallieren geloescht)
function LogFileName(Ver: String; Uninstall: Boolean): String;
begin
  if Uninstall then
    Result := AddBackslash(GetTempDir) + 'PPGlow-uninstall-' + Ver + '.log'
  else
    Result := ExpandConstant('{app}\Logs\install-') + Ver + '.log';
end;

// Ruft Installer\run-install.ps1 auf (baut und registriert bzw. entfernt)
function RunInstall(Ver: String; Uninstall: Boolean): Boolean;
var
  Params, Platforms: String;
  Code: Integer;
begin
  Params := '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\Installer\run-install.ps1') +
    '" -Version ' + Ver + ' -LogFile "' + LogFileName(Ver, Uninstall) + '"';
  if Uninstall then
    Params := Params + ' -Uninstall'
  else
  begin
    Platforms := 'Win32';
    if WizardIsTaskSelected('win64') then
      Platforms := 'Win32,Win64';
    Params := Params + ' -Platforms ' + Platforms;
    if not WizardIsTaskSelected('db') then
      Params := Params + ' -NoDB';
  end;
  Log(Format('PPGlow: %s %s', [PowerShellExe, Params]));
  Result := Exec(PowerShellExe, Params, ExpandConstant('{app}'), SW_SHOWNORMAL, ewWaitUntilTerminated, Code) and (Code = 0);
  Log(Format('PPGlow: Exit-Code %d', [Code]));
end;

// Liste "22.0;37.0" um Ver ergaenzen (ohne Doppelte)
function AddVersion(List, Ver: String): String;
begin
  Result := List;
  if Pos(';' + Ver + ';', ';' + List + ';') = 0 then
  begin
    if Result <> '' then
      Result := Result + ';';
    Result := Result + Ver;
  end;
end;

procedure InstallVersion(Ver: String);
var
  Done: String;
begin
  WizardForm.StatusLabel.Caption := 'Baue und registriere PPGlow für ' + VersionName(Ver) +
    ' (dauert einige Minuten, Fortschritt im PowerShell-Fenster) ...';
  WizardForm.Refresh;
  if RunInstall(Ver, False) then
  begin
    if not RegQueryStringValue(HKEY_CURRENT_USER, SetupKey, 'Versions', Done) then
      Done := '';
    RegWriteStringValue(HKEY_CURRENT_USER, SetupKey, 'Versions', AddVersion(Done, Ver));
  end
  else
    Failed := Failed + #13#10 + '- ' + VersionName(Ver) + ': ' + LogFileName(Ver, False);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep <> ssPostInstall then
    Exit;
  Failed := '';
  if WizardIsComponentSelected('d11') then
    InstallVersion('22.0');
  if WizardIsComponentSelected('d13') then
    InstallVersion('37.0');
  if Failed <> '' then
    MsgBox('Bauen bzw. Registrieren ist fehlgeschlagen für:' + Failed + #13#10#13#10 +
      'Die Quelltexte sind installiert. Details stehen im Protokoll; ' +
      'nach einer Korrektur das Setup erneut ausführen.', mbError, MB_OK);
end;

function InitializeUninstall: Boolean;
begin
  Result := WaitForIdeClosed;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  List, Ver: String;
  P: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    if not RegQueryStringValue(HKEY_CURRENT_USER, SetupKey, 'Versions', List) then
      List := '';
    while List <> '' do
    begin
      P := Pos(';', List);
      if P > 0 then
      begin
        Ver := Copy(List, 1, P - 1);
        Delete(List, 1, P);
      end
      else
      begin
        Ver := List;
        List := '';
      end;
      if (Ver <> '') and BdsInstalled(Ver) and not RunInstall(Ver, True) then
        MsgBox('PPGlow konnte nicht vollständig aus ' + VersionName(Ver) + ' ausgetragen werden.' + #13#10 +
          'Protokoll: ' + LogFileName(Ver, True), mbError, MB_OK);
    end;
  end
  else if CurUninstallStep = usPostUninstall then
    RegDeleteKeyIncludingSubkeys(HKEY_CURRENT_USER, SetupKey);
end;
