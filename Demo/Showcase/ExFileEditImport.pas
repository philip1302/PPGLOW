unit ExFileEditImport;

// Praxisbeispiel 1 zu TPPGFileEdit (Demo-Seite "Eingabe > TPPGFileEdit"):
// Kundendaten aus einer CSV-Datei importieren. Zeigt Kind, Filter,
// DialogTitle, InitialDir, MustExist, ShowClearButton, AcceptDrop,
// OnChange und OnAfterDialog.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, System.IOUtils, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.FileEdit, PPG.Button;

type
  /// Import von Kundendaten: Datei waehlen, aus dem Explorer ziehen oder
  /// tippen. "Importieren" geht erst, wenn die Datei existiert.
  TCsvImportPanel = class(TComponent)
  private
    FSource: TPPGFileEdit;
    FImport: TPPGButton;
    FStatus: TPPGLabel;
    FImportedRows: Integer;
    procedure SourceChange(Sender: TObject);
    procedure SourceAfterDialog(Sender: TObject; var FileName: string;
      var Accept: Boolean);
    procedure ImportClick(Sender: TObject);
  public
    constructor CreatePanel(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Source: TPPGFileEdit read FSource;
    property ImportButton: TPPGButton read FImport;
    property Status: TPPGLabel read FStatus;
    property ImportedRows: Integer read FImportedRows;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TCsvImportPanel.CreatePanel(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Prompt: TPPGLabel;
begin
  inherited Create(AOwner);
  Prompt := TPPGLabel.Create(Self);
  Prompt.Parent := AParent;
  Prompt.SetBounds(16, 16, 414, 20);
  Prompt.Caption := '&Quelldatei (CSV):';

  FSource := TPPGFileEdit.Create(Self);
  FSource.Parent := AParent;
  FSource.SetBounds(16, 40, 414, 32);
  FSource.StyleManager := AStyles;
  FSource.Kind := fkOpenFile;
  FSource.Filter := 'CSV-Dateien (*.csv)|*.csv|Textdateien (*.txt)|*.txt|' +
    'Alle Dateien (*.*)|*.*';
  FSource.DialogTitle := 'Kundendaten importieren';
  FSource.InitialDir := TPath.GetDocumentsPath;
  FSource.TextHint := 'Datei angeben oder aus dem Explorer ziehen';
  FSource.MustExist := True;        // fehlende Datei beim Verlassen rot
  FSource.ShowClearButton := True;  // "x" leert das Feld
  FSource.AcceptDrop := True;       // Vorgabe: Ablegen aus dem Explorer
  FSource.OnChange := SourceChange;
  FSource.OnAfterDialog := SourceAfterDialog;
  Prompt.FocusControl := FSource;

  FImport := TPPGButton.Create(Self);
  FImport.Parent := AParent;
  FImport.SetBounds(16, 88, 130, 32);
  FImport.Caption := 'Importieren';
  FImport.StyleManager := AStyles;
  FImport.Enabled := False;         // erst mit einer vorhandenen Datei
  FImport.OnClick := ImportClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.AutoSize := False;
  FStatus.WordWrap := True;
  FStatus.SetBounds(16, 132, 414, 40);
  FStatus.Caption := 'Noch nichts importiert.';
end;

procedure TCsvImportPanel.SourceChange(Sender: TObject);
begin
  // Getippt, abgelegt, gewaehlt oder geleert: Knopf passend sperren
  FImport.Enabled := FileExists(Trim(FSource.Text));
end;

procedure TCsvImportPanel.SourceAfterDialog(Sender: TObject; var FileName: string;
  var Accept: Boolean);
var
  Ext: string;
begin
  // "Alle Dateien" erlaubt jede Datei; importiert wird nur Text
  Ext := LowerCase(ExtractFileExt(FileName));
  Accept := (Ext = '.csv') or (Ext = '.txt');
  if not Accept then
    FStatus.Caption := 'Bitte eine CSV- oder Textdatei angeben.';
end;

procedure TCsvImportPanel.ImportClick(Sender: TObject);
var
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(Trim(FSource.Text));
    // erste Zeile = Spaltennamen
    FImportedRows := Lines.Count - 1;
    if FImportedRows < 0 then
      FImportedRows := 0;
    FStatus.Caption := Format('%d Kunden aus %s importiert.',
      [FImportedRows, ExtractFileName(FSource.Text)]);
  finally
    Lines.Free;
  end;
end;
// EXAMPLE-END

end.
