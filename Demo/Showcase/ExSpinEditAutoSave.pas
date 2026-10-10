unit ExSpinEditAutoSave;

// Praxisbeispiel 2 zu TPPGSpinEdit (Demo-Seite "Eingabe > TPPGSpinEdit"):
// Einstellungen "Automatisch speichern": Intervall mit Warnung bei sehr
// kurzen Abstaenden (ValidationState, ValidationHint), Sperre ueber eine
// CheckBox (Enabled) und ein vom Administrator festgelegter Wert (ReadOnly).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Controls.Field, PPG.StyleManager, PPG.Labels, PPG.CheckBox, PPG.SpinEdit;

type
  /// Einstellungen zum automatischen Speichern.
  TAutoSaveSettings = class(TComponent)
  private
    FActive: TPPGCheckBox;
    FInterval: TPPGSpinEdit;
    FVersions: TPPGSpinEdit;
    FStatus: TPPGLabel;
    function NewSpin(AParent: TWinControl; Y: Integer; const ACaption: string;
      AStyles: TPPGStyleManager): TPPGSpinEdit;
    procedure ActiveChange(Sender: TObject);
    procedure IntervalChange(Sender: TObject);
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Active: TPPGCheckBox read FActive;
    property Interval: TPPGSpinEdit read FInterval;
    property Versions: TPPGSpinEdit read FVersions;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TAutoSaveSettings.NewSpin(AParent: TWinControl; Y: Integer;
  const ACaption: string; AStyles: TPPGStyleManager): TPPGSpinEdit;
var
  Lbl: TPPGLabel;
begin
  Result := TPPGSpinEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(240, Y, 100, 32);
  Result.StyleManager := AStyles;
  Result.Alignment := taRightJustify;
  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(16, Y + 6, 216, 20);
  Lbl.Caption := ACaption;
  Lbl.FocusControl := Result;
end;

constructor TAutoSaveSettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FActive := TPPGCheckBox.Create(Self);
  FActive.Parent := AParent;
  FActive.SetBounds(16, 16, 300, 24);
  FActive.Caption := '&Automatisch speichern';
  FActive.StyleManager := AStyles;
  FActive.Checked := True;
  FActive.OnChange := ActiveChange;

  // Intervall 1 bis 60 Minuten; unter 5 Minuten nur eine Warnung
  FInterval := NewSpin(AParent, 52, '&Intervall (Minuten):', AStyles);
  FInterval.Min := 1;
  FInterval.Max := 60;
  FInterval.Value := 10;
  FInterval.OnChange := IntervalChange;

  // Vom Administrator festgelegt: lesbar und kopierbar, aber nicht aenderbar
  FVersions := NewSpin(AParent, 96, 'Aufbewahrte &Versionen:', AStyles);
  FVersions.Min := 0;
  FVersions.Max := 20;
  FVersions.Value := 5;
  FVersions.ReadOnly := True;
  FVersions.Hint := 'Vom Administrator festgelegt';
  FVersions.ShowHint := True;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 144, 410, 20);
  IntervalChange(nil);
end;

procedure TAutoSaveSettings.ActiveChange(Sender: TObject);
begin
  // Ohne automatisches Speichern ist das Intervall bedeutungslos: sperren
  FInterval.Enabled := FActive.Checked;
  IntervalChange(nil);
end;

procedure TAutoSaveSettings.IntervalChange(Sender: TObject);
begin
  // Erlaubt, aber ungeschickt: Warnung statt Fehler, Grund im Tooltip
  if FInterval.Value < 5 then
  begin
    FInterval.ValidationState := pvsWarning;
    FInterval.ValidationHint := 'Sehr kurze Abstaende bremsen bei grossen Dateien.';
  end
  else
  begin
    FInterval.ValidationState := pvsNone;
    FInterval.ValidationHint := '';
  end;
  if FActive.Checked then
    FStatus.Caption := Format('Speichert alle %d Minuten, behaelt %d Versionen.',
      [FInterval.Value, FVersions.Value])
  else
    FStatus.Caption := 'Automatisches Speichern ist aus.';
end;
// EXAMPLE-END

end.
