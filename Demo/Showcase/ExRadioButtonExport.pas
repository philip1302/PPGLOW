unit ExRadioButtonExport;

// Praxisbeispiel 2 zu TPPGRadioButton (Demo-Seite "Auswahl > TPPGRadioButton"):
// Export-Einstellungen mit zwei Gruppen im selben Container, getrennt ueber
// GroupIndex. OnChange haelt die Zusammenfassung aktuell, auch wenn der Code
// die Auswahl setzt ("Standard wiederherstellen").
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  PPG.StyleManager, PPG.Labels, PPG.Button, PPG.RadioButton;

type
  /// Export-Einstellungen: Format (Gruppe 1) und Umfang (Gruppe 2) liegen
  /// im selben Parent und schliessen sich nur innerhalb ihrer Gruppe aus.
  TExportOptions = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FParent: TWinControl;
    FPdf: TPPGRadioButton;
    FExcel: TPPGRadioButton;
    FCsv: TPPGRadioButton;
    FAllRows: TPPGRadioButton;
    FSelectedRows: TPPGRadioButton;
    FReset: TPPGButton;
    FSummary: TPPGLabel;
    FSelectedCount: Integer;
    function NewOption(X, Y, AGroup: Integer; const ACaption: string): TPPGRadioButton;
    procedure OptionChange(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    function GetFormatName: string;
  public
    constructor CreateOptions(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager; ASelectedCount: Integer);
    /// Vorgabe: PDF, alle Zeilen.
    procedure RestoreDefaults;
    property Pdf: TPPGRadioButton read FPdf;
    property Excel: TPPGRadioButton read FExcel;
    property Csv: TPPGRadioButton read FCsv;
    property AllRows: TPPGRadioButton read FAllRows;
    property SelectedRows: TPPGRadioButton read FSelectedRows;
    property ResetButton: TPPGButton read FReset;
    property Summary: TPPGLabel read FSummary;
    property FormatName: string read GetFormatName;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TExportOptions.NewOption(X, Y, AGroup: Integer; const ACaption: string): TPPGRadioButton;
begin
  Result := TPPGRadioButton.Create(Self);
  Result.Parent := FParent;
  Result.SetBounds(X, Y, 200, 24);
  Result.Caption := ACaption;
  Result.GroupIndex := AGroup;        // gleiche Zahl = eine Gruppe
  Result.StyleManager := FStyles;
  Result.OnChange := OptionChange;    // auch bei Checked := True im Code
end;

constructor TExportOptions.CreateOptions(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager; ASelectedCount: Integer);
var
  Title: TPPGLabel;
begin
  inherited Create(AOwner);
  FStyles := AStyles;
  FParent := AParent;
  FSelectedCount := ASelectedCount;

  Title := TPPGLabel.Create(Self);
  Title.Parent := AParent;
  Title.SetBounds(16, 16, 200, 20);
  Title.Caption := 'Format';
  Title.Font.Style := [fsBold];
  FPdf := NewOption(16, 44, 1, '&PDF-Dokument');
  FExcel := NewOption(16, 72, 1, '&Excel-Tabelle');
  FCsv := NewOption(16, 100, 1, '&CSV-Datei');

  Title := TPPGLabel.Create(Self);
  Title.Parent := AParent;
  Title.SetBounds(232, 16, 200, 20);
  Title.Caption := 'Umfang';
  Title.Font.Style := [fsBold];
  FAllRows := NewOption(232, 44, 2, '&Alle Zeilen');
  FSelectedRows := NewOption(232, 72, 2, Format('&Nur Auswahl (%d)', [ASelectedCount]));
  // Ohne markierte Zeilen gibt es keine Auswahl zu exportieren
  FSelectedRows.Enabled := ASelectedCount > 0;

  FReset := TPPGButton.Create(Self);
  FReset.Parent := AParent;
  FReset.SetBounds(16, 140, 220, 32);
  FReset.Caption := 'Standard wiederherstellen';
  FReset.StyleManager := AStyles;
  FReset.OnClick := ResetClick;

  FSummary := TPPGLabel.Create(Self);
  FSummary.Parent := AParent;
  FSummary.SetBounds(16, 184, 414, 20);

  RestoreDefaults;
end;

procedure TExportOptions.RestoreDefaults;
begin
  // Checked im Code: schaltet die anderen der Gruppe aus und loest OnChange
  // aus (OnClick nicht, das gehoert zur Bedienung)
  FPdf.Checked := True;
  FAllRows.Checked := True;
  OptionChange(nil);
end;

function TExportOptions.GetFormatName: string;
begin
  if FExcel.Checked then
    Result := 'Excel'
  else if FCsv.Checked then
    Result := 'CSV'
  else
    Result := 'PDF';
end;

procedure TExportOptions.OptionChange(Sender: TObject);
begin
  // OnChange kommt auch fuer die Option, die gerade ausgeschaltet wird;
  // deshalb den Gesamtzustand lesen statt nur den Sender
  if FSelectedRows.Checked then
    FSummary.Caption := Format('Export: %d markierte Zeilen als %s', [FSelectedCount, FormatName])
  else
    FSummary.Caption := 'Export: alle Zeilen als ' + FormatName;
end;

procedure TExportOptions.ResetClick(Sender: TObject);
begin
  RestoreDefaults;
end;
// EXAMPLE-END

end.
