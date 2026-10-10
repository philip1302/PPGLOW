unit ExFileEditBackup;

// Praxisbeispiel 2 zu TPPGFileEdit (Demo-Seite "Eingabe > TPPGFileEdit"):
// Einstellungen einer Datensicherung mit Zielordner (Kind = fkFolder) und
// Dateiname (Kind = fkSaveFile). Zeigt DefaultExt, Filter, AcceptDrop,
// OnBeforeDialog (Dialog vorbereiten oder abbrechen) und OnAfterDialog
// (gewaehlten Namen aufteilen und ergaenzen).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.FileEdit;

type
  /// Einstellungen der Datensicherung: in welchen Ordner, unter welchem Namen.
  TBackupSettings = class(TComponent)
  private
    FFolder: TPPGFileEdit;
    FFile: TPPGFileEdit;
    FTarget: TPPGLabel;
    procedure NewPrompt(AParent: TWinControl; Y: Integer; const ACaption: string;
      AFocus: TWinControl);
    procedure PathChange(Sender: TObject);
    procedure FileBeforeDialog(Sender: TObject; var Allow: Boolean);
    procedure FileAfterDialog(Sender: TObject; var FileName: string;
      var Accept: Boolean);
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    /// Vollstaendiger Pfad der Sicherung; '' = noch unvollstaendig.
    function TargetPath: string;
    property FolderEdit: TPPGFileEdit read FFolder;
    property FileEdit: TPPGFileEdit read FFile;
    property TargetLabel: TPPGLabel read FTarget;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
procedure TBackupSettings.NewPrompt(AParent: TWinControl; Y: Integer;
  const ACaption: string; AFocus: TWinControl);
var
  Prompt: TPPGLabel;
begin
  Prompt := TPPGLabel.Create(Self);
  Prompt.Parent := AParent;
  Prompt.SetBounds(16, Y, 414, 20);
  Prompt.Caption := ACaption;
  Prompt.FocusControl := AFocus;
end;

constructor TBackupSettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  // Zielordner: Knopf oeffnet die Ordnerauswahl, Ordner lassen sich ablegen
  FFolder := TPPGFileEdit.Create(Self);
  FFolder.Parent := AParent;
  FFolder.SetBounds(16, 40, 414, 32);
  FFolder.StyleManager := AStyles;
  FFolder.Kind := fkFolder;
  FFolder.DialogTitle := 'Zielordner der Sicherung';
  FFolder.TextHint := 'Ordner angeben oder hierher ziehen';
  FFolder.MustExist := True;
  FFolder.OnChange := PathChange;
  NewPrompt(AParent, 16, '&Zielordner:', FFolder);

  // Dateiname: Speichern-Dialog, Endung .zip wird ergaenzt
  FFile := TPPGFileEdit.Create(Self);
  FFile.Parent := AParent;
  FFile.SetBounds(16, 112, 414, 32);
  FFile.StyleManager := AStyles;
  FFile.Kind := fkSaveFile;
  FFile.Filter := 'ZIP-Archiv (*.zip)|*.zip';
  FFile.DefaultExt := 'zip';
  FFile.DialogTitle := 'Sicherung speichern unter';
  FFile.TextHint := 'z. B. Kunden-2026.zip';
  FFile.AcceptDrop := False;  // ein Zielname wird nicht abgelegt
  FFile.OnChange := PathChange;
  FFile.OnBeforeDialog := FileBeforeDialog;
  FFile.OnAfterDialog := FileAfterDialog;
  NewPrompt(AParent, 88, '&Dateiname:', FFile);

  FTarget := TPPGLabel.Create(Self);
  FTarget.Parent := AParent;
  FTarget.AutoSize := False;
  FTarget.WordWrap := True;
  FTarget.SetBounds(16, 160, 414, 40);
  PathChange(nil);
end;

function TBackupSettings.TargetPath: string;
begin
  if (Trim(FFolder.Text) = '') or (Trim(FFile.Text) = '') then
    Result := ''
  else
    Result := IncludeTrailingPathDelimiter(Trim(FFolder.Text)) + Trim(FFile.Text);
end;

procedure TBackupSettings.PathChange(Sender: TObject);
begin
  if TargetPath = '' then
    FTarget.Caption := 'Bitte Zielordner und Dateinamen angeben.'
  else
    FTarget.Caption := 'Sicherung nach: ' + TargetPath;
end;

procedure TBackupSettings.FileBeforeDialog(Sender: TObject; var Allow: Boolean);
begin
  // Ohne Zielordner hat der Dialog keinen sinnvollen Start: abbrechen
  Allow := Trim(FFolder.Text) <> '';
  if Allow then
    FFile.InitialDir := Trim(FFolder.Text)
  else
    FTarget.Caption := 'Bitte zuerst den Zielordner angeben.';
end;

procedure TBackupSettings.FileAfterDialog(Sender: TObject; var FileName: string;
  var Accept: Boolean);
begin
  // Der Dialog liefert den ganzen Pfad: Ordner ins obere Feld, unten nur
  // der Name (mit Endung)
  if ExtractFileExt(FileName) = '' then
    FileName := FileName + '.zip';
  if ExtractFileDir(FileName) <> '' then
    FFolder.Text := ExtractFileDir(FileName);
  FileName := ExtractFileName(FileName);
end;
// EXAMPLE-END

end.
