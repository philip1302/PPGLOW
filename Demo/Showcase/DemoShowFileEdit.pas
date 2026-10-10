unit DemoShowFileEdit;

// Komponentenseite TPPGFileEdit (Gruppe "Eingabe"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// Dateifelds (Protokoll fuer OnBeforeDialog/OnAfterDialog, eigene
// Kategorien) und die beiden Praxisbeispiele (ExFileEditImport,
// ExFileEditBackup).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Controls.Field, PPG.FileEdit, DemoKit, DemoShowcase, ExFileEditImport, ExFileEditBackup;

type
  TDemoShowFileEditPage = class(TDemoComponentPage)
  private
    FImport: TCsvImportPanel;
    FBackup: TBackupSettings;
    procedure SubjectBeforeDialog(Sender: TObject; var Allow: Boolean);
    procedure SubjectAfterDialog(Sender: TObject; var FileName: string; var Accept: Boolean);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
    procedure BuildExamples; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Winapi.Windows, System.TypInfo, System.IOUtils;

function TDemoShowFileEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGFileEdit;
end;

procedure TDemoShowFileEditPage.SetupSubject(ASubject: TComponent);
var
  F: TPPGFileEdit;
begin
  inherited SetupSubject(ASubject);
  F := ASubject as TPPGFileEdit;
  // Breit genug fuer einen Pfad; Hinweis, was man tun kann
  F.Width := 360;
  F.TextHint := L('Datei w{ae}hlen (Knopf, F4) oder aus dem Explorer ziehen');
  // Eigene Signaturen protokolliert die Seite nicht automatisch
  F.OnBeforeDialog := SubjectBeforeDialog;
  F.OnAfterDialog := SubjectAfterDialog;
end;

procedure TDemoShowFileEditPage.SubjectBeforeDialog(Sender: TObject; var Allow: Boolean);
begin
  LogEvent('OnBeforeDialog', 'Allow = True (Dialog ' + L('{oe}ffnet') + ')');
end;

procedure TDemoShowFileEditPage.SubjectAfterDialog(Sender: TObject; var FileName: string;
  var Accept: Boolean);
begin
  LogEvent('OnAfterDialog', 'FileName = ' + FileName);
end;

procedure TDemoShowFileEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Kind') or SameText(AName, 'Filter') or SameText(AName, 'FilterIndex') or
    SameText(AName, 'InitialDir') or SameText(AName, 'DefaultExt') or
    SameText(AName, 'DialogTitle') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'MustExist') or SameText(AName, 'AcceptDrop') or
    SameText(AName, 'AutoComplete') or SameText(AName, 'ShowClearButton') or
    SameText(AName, 'MaxLength') or SameText(AName, 'UseSystemContextMenu') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'TextHintVisibleOnFocus') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'ValidationState') or SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if SameText(AName, 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowFileEditPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if (AName = 'OnChange') and (Subject is TPPGFileEdit) then
    Detail := 'Text = ' + TPPGFileEdit(Subject).Text
  else if (AName = 'OnExit') and (Subject is TPPGFileEdit) and TPPGFileEdit(Subject).MustExist then
    Detail := 'MustExist: ValidationState = ' +
      GetEnumName(TypeInfo(TPPGValidationState), Ord(TPPGFileEdit(Subject).ValidationState));
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowFileEditPage.BuildExamples;
begin
  AddExample('Praxis: CSV-Import', 'ExFileEditImport',
    'Kundendaten aus einer CSV-Datei importieren: <b>Kind = fkOpenFile</b> mit <b>Filter</b> '
    + 'und <b>DialogTitle</b>, <b>MustExist</b> (eine fehlende Datei wird beim Verlassen rot '
    + 'markiert) und <b>OnChange</b>, das "Importieren" erst mit einer vorhandenen Datei freigibt. '
    + '<b>OnAfterDialog</b> lehnt Dateien ab, die keine CSV- oder Textdatei sind. Probieren Sie: '
    + 'eine CSV-Datei aus dem Explorer ins Feld ziehen, einen falschen Pfad tippen und mit Tab '
    + 'weitergehen, mit dem Knopf (oder F4) den Dialog {oe}ffnen.');
  FImport := TCsvImportPanel.CreatePanel(Own, Examples[Examples.Count - 1].Live, DemoStyles);

  AddExample('Praxis: Datensicherung', 'ExFileEditBackup',
    'Einstellungen einer Sicherung: oben ein Ordner (<b>Kind = fkFolder</b>), unten der '
    + 'Dateiname (<b>Kind = fkSaveFile</b> mit <b>DefaultExt</b> und <b>AcceptDrop = False</b>). '
    + '<b>OnBeforeDialog</b> bricht ohne Zielordner ab und setzt sonst <b>InitialDir</b>; '
    + '<b>OnAfterDialog</b> verteilt den gew{ae}hlten Pfad auf beide Felder und erg{ae}nzt .zip. '
    + 'Probieren Sie: zuerst den Knopf am Dateinamen (nichts passiert), dann einen Ordner '
    + 'ablegen und erneut w{ae}hlen.');
  FBackup := TBackupSettings.CreateSettings(Own, Examples[Examples.Count - 1].Live, DemoStyles);
end;

procedure TDemoShowFileEditPage.SelfTest(Check: TDemoCheck);
var
  Dir, Csv, Missing, S: string;
  Lines: TStringList;
  Accept, Allow: Boolean;
  F: TPPGFileEdit;
begin
  inherited SelfTest(Check);
  Dir := TPath.Combine(TPath.GetTempPath, 'PPGDemoFileEdit');
  ForceDirectories(Dir);
  Csv := TPath.Combine(Dir, 'Kunden.csv');
  Missing := TPath.Combine(Dir, 'Fehlt.csv');
  Lines := TStringList.Create;
  try
    Lines.Add('Nr;Name;Ort');
    Lines.Add('1;Meier GmbH;Bonn');
    Lines.Add('2;Schulz KG;Ulm');
    Lines.Add('3;Huber AG;Graz');
    Lines.SaveToFile(Csv);
  finally
    Lines.Free;
  end;
  try
    // Buehne: OnChange erscheint im Protokoll, MustExist markiert fehlende Datei
    ResetSubject;
    F := TPPGFileEdit(Subject);
    F.Text := Csv;
    Check('TPPGFileEdit: Text setzen erscheint als OnChange im Ereignis-Protokoll',
      (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0));
    F.MustExist := True;
    F.Text := Missing;
    Check('TPPGFileEdit: MustExist meldet eine fehlende Datei als pvsError',
      (not F.ValidatePath) and (F.ValidationState = pvsError));
    ResetSubject;

    // Praxisbeispiel 1: CSV-Import
    FImport.Source.Text := '';
    Check('Beispiel CSV-Import: Importieren ohne Datei gesperrt', not FImport.ImportButton.Enabled);
    Check('Beispiel CSV-Import: Ablegen einer CSV-Datei wird angenommen',
      FImport.Source.DropPaths([Csv]) and SameText(FImport.Source.Text, Csv));
    Check('Beispiel CSV-Import: mit vorhandener Datei ist Importieren frei',
      FImport.ImportButton.Enabled and (FImport.Source.ValidationState = pvsNone));
    FImport.ImportButton.Click;
    Check('Beispiel CSV-Import: Importieren liest 3 Kunden (ohne Kopfzeile)',
      (FImport.ImportedRows = 3) and (Pos('3 Kunden', FImport.Status.Caption) > 0));
    S := TPath.Combine(Dir, 'Kunden.xlsx');
    Accept := True;
    FImport.Source.OnAfterDialog(FImport.Source, S, Accept);
    Check('Beispiel CSV-Import: OnAfterDialog lehnt eine Excel-Datei ab', not Accept);
    S := Csv;
    Accept := True;
    FImport.Source.OnAfterDialog(FImport.Source, S, Accept);
    Check('Beispiel CSV-Import: OnAfterDialog nimmt eine CSV-Datei an', Accept);
    FImport.Source.Text := Missing;
    Check('Beispiel CSV-Import: fehlende Datei sperrt Importieren und wird rot markiert',
      (not FImport.ImportButton.Enabled) and (not FImport.Source.ValidatePath) and
      (FImport.Source.ValidationState = pvsError) and (FImport.Source.ValidationHint <> ''));
    FImport.Source.Text := '';
    FImport.Source.ValidatePath;

    // Praxisbeispiel 2: Datensicherung
    FBackup.FolderEdit.Text := '';
    FBackup.FileEdit.Text := '';
    Allow := True;
    FBackup.FileEdit.OnBeforeDialog(FBackup.FileEdit, Allow);
    Check('Beispiel Datensicherung: ohne Zielordner bricht OnBeforeDialog den Dialog ab',
      (not Allow) and (FBackup.TargetPath = ''));
    Check('Beispiel Datensicherung: Ordnerfeld nimmt einen abgelegten Ordner an',
      FBackup.FolderEdit.DropPaths([Dir]) and SameText(FBackup.FolderEdit.Text, Dir) and
      (FBackup.FolderEdit.ValidationState = pvsNone));
    Allow := False;
    FBackup.FileEdit.OnBeforeDialog(FBackup.FileEdit, Allow);
    Check('Beispiel Datensicherung: mit Zielordner startet der Dialog dort (InitialDir)',
      Allow and SameText(FBackup.FileEdit.InitialDir, Dir));
    S := TPath.Combine(Dir, 'Kunden-2026');
    Accept := True;
    FBackup.FileEdit.OnAfterDialog(FBackup.FileEdit, S, Accept);
    FBackup.FileEdit.Text := S;
    Check('Beispiel Datensicherung: OnAfterDialog erg' + #$00E4 + 'nzt .zip und teilt Ordner und Namen',
      Accept and (S = 'Kunden-2026.zip') and SameText(FBackup.FolderEdit.Text, Dir) and
      SameText(FBackup.TargetPath, IncludeTrailingPathDelimiter(Dir) + 'Kunden-2026.zip') and
      (Pos('Kunden-2026.zip', FBackup.TargetLabel.Caption) > 0));
    FBackup.FolderEdit.Text := TPath.Combine(Dir, 'GibtEsNicht');
    Check('Beispiel Datensicherung: fehlender Zielordner wird mit MustExist rot markiert',
      (not FBackup.FolderEdit.ValidatePath) and (FBackup.FolderEdit.ValidationState = pvsError));
    Check('Beispiel Datensicherung: Dateinamen-Feld speichert mit DefaultExt zip und nimmt keine Dateien an (AcceptDrop = False)',
      (GetWindowLong(FBackup.FileEdit.Handle, GWL_EXSTYLE) and WS_EX_ACCEPTFILES = 0) and (FBackup.FileEdit.Kind = fkSaveFile) and
      (FBackup.FileEdit.DefaultExt = 'zip'));
    FBackup.FolderEdit.Text := '';
    FBackup.FolderEdit.ValidatePath;
    FBackup.FileEdit.Text := '';
  finally
    System.SysUtils.DeleteFile(Csv);
    RemoveDir(Dir);
  end;
end;

initialization
  RegisterShowcasePage('TPPGFileEdit', TDemoShowFileEditPage);

end.
