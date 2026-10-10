unit ExCheckComboBoxSettings;

// Praxisbeispiel 2 zu TPPGCheckComboBox (Demo-Seite "Auswahl > TPPGCheckComboBox"):
// Einstellung "Wochenbericht": an welchen Tagen der Bericht verschickt wird.
// Die Auswahl wird als CheckedText (mit Delimiter) gespeichert und geladen,
// OnItemCheck prueft die Eingabe (mindestens ein Tag), ValidationState zeigt
// den Fehler.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.Button, PPG.CheckComboBox;

type
  /// Einstellung "Wochenbericht senden am": Tage anhaken, Speichern schreibt
  /// sie als Text in die Einstellungen, Verwerfen laedt den letzten Stand.
  TReportSettings = class(TComponent)
  private
    FSettings: TStringList;   // steht hier fuer INI-Datei oder Datenbank
    FDays: TPPGCheckComboBox;
    FSave: TPPGButton;
    FDiscard: TPPGButton;
    FStatus: TPPGLabel;
    procedure DayCheck(Sender: TObject; Index: Integer);
    procedure SaveClick(Sender: TObject);
    procedure DiscardClick(Sender: TObject);
    procedure Validate;
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    destructor Destroy; override;
    /// Einstellungen lesen (wie beim Programmstart).
    procedure LoadSettings;
    property Days: TPPGCheckComboBox read FDays;
    property SaveButton: TPPGButton read FSave;
    property DiscardButton: TPPGButton read FDiscard;
    property Settings: TStringList read FSettings;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TReportSettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Lbl: TPPGLabel;
begin
  inherited Create(AOwner);
  FSettings := TStringList.Create;
  FSettings.Values['Berichtstage'] := 'Montag,Mittwoch,Freitag';

  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(16, 16, 414, 20);
  Lbl.Caption := 'Wochenbericht &senden am:';

  FDays := TPPGCheckComboBox.Create(Self);
  FDays.Parent := AParent;
  FDays.SetBounds(16, 40, 414, 32);
  FDays.Items.CommaText := 'Montag,Dienstag,Mittwoch,Donnerstag,Freitag,Samstag,Sonntag';
  FDays.Delimiter := ',';            // so steht die Auswahl in den Einstellungen
  FDays.MaxDisplayItems := 3;        // "Montag, Mittwoch, Freitag, +1"
  FDays.TextHint := 'Noch kein Tag';
  FDays.Hint := 'An diesen Tagen geht der Bericht per E-Mail raus.';
  FDays.ShowHint := True;
  FDays.StyleManager := AStyles;
  FDays.OnItemCheck := DayCheck;     // nur Anwender-Haken, nicht Code
  Lbl.FocusControl := FDays;

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(16, 88, 120, 32);
  FSave.Caption := 'Speichern';
  FSave.StyleManager := AStyles;
  FSave.OnClick := SaveClick;

  FDiscard := TPPGButton.Create(Self);
  FDiscard.Parent := AParent;
  FDiscard.SetBounds(144, 88, 120, 32);
  FDiscard.Caption := 'Verwerfen';
  FDiscard.StyleManager := AStyles;
  FDiscard.OnClick := DiscardClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 136, 414, 20);

  LoadSettings;
end;

destructor TReportSettings.Destroy;
begin
  FSettings.Free;
  inherited Destroy;
end;

procedure TReportSettings.LoadSettings;
begin
  // CheckedText aus Code hakt an, ohne OnItemCheck/OnChange auszuloesen
  FDays.CheckedText := FSettings.Values['Berichtstage'];
  Validate;
  FStatus.Caption := 'Geladen: ' + FDays.CheckedText;
end;

procedure TReportSettings.Validate;
begin
  // Ohne Tag gaebe es keinen Bericht: Fehler zeigen, Speichern sperren
  if FDays.CheckedCount = 0 then
  begin
    FDays.ValidationState := pvsError;
    FDays.ValidationHint := 'Bitte mindestens einen Tag ankreuzen.';
  end
  else
  begin
    FDays.ValidationState := pvsNone;
    FDays.ValidationHint := '';
  end;
  FSave.Enabled := FDays.CheckedCount > 0;
end;

procedure TReportSettings.DayCheck(Sender: TObject; Index: Integer);
begin
  Validate;
  if FDays.Checked[Index] then
    FStatus.Caption := FDays.Items[Index] + ' dazu (nicht gespeichert)'
  else
    FStatus.Caption := FDays.Items[Index] + ' entfernt (nicht gespeichert)';
end;

procedure TReportSettings.SaveClick(Sender: TObject);
begin
  FSettings.Values['Berichtstage'] := FDays.CheckedText;
  FStatus.Caption := 'Gespeichert: Berichtstage=' + FDays.CheckedText;
end;

procedure TReportSettings.DiscardClick(Sender: TObject);
begin
  LoadSettings;
end;
// EXAMPLE-END

end.
