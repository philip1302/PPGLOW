unit ExMaskEditTimeEntry;

// Praxisbeispiel 2 zu TPPGMaskEdit (Demo-Seite "Eingabe > TPPGMaskEdit"):
// Arbeitszeit buchen mit Datum, Beginn und Ende. Zeigt Masken mit
// gespeicherten Literalen (Text = "08:30"), OnChange fuer eine Live-Berechnung,
// IsEmpty sowie eigene Pruefungen ueber ValidationState und ValidationHint
// (Warnung "Ende vor Beginn", Fehler bei unmoeglicher Uhrzeit).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.MaskEdit;

type
  /// Zeitbuchung: rechnet die Dauer, sobald Beginn und Ende vollstaendig sind.
  TTimeEntry = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FDate: TPPGMaskEdit;
    FStart: TPPGMaskEdit;
    FEnd: TPPGMaskEdit;
    FDuration: TPPGLabel;
    FMinutes: Integer;
    function NewField(AParent: TWinControl; X, Y, AWidth: Integer;
      const ACaption, AMask: string): TPPGMaskEdit;
    function Complete(AField: TPPGMaskEdit): Boolean;
    function MinuteOfDay(AField: TPPGMaskEdit): Integer;
    procedure SetState(AField: TPPGMaskEdit; AState: TPPGValidationState;
      const AHint: string);
    procedure TimeChange(Sender: TObject);
  public
    constructor CreateEntry(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property DateEdit: TPPGMaskEdit read FDate;
    property StartEdit: TPPGMaskEdit read FStart;
    property EndEdit: TPPGMaskEdit read FEnd;
    property Duration: TPPGLabel read FDuration;
    /// Dauer in Minuten; -1 = noch nicht berechenbar.
    property Minutes: Integer read FMinutes;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TTimeEntry.NewField(AParent: TWinControl; X, Y, AWidth: Integer;
  const ACaption, AMask: string): TPPGMaskEdit;
var
  Lbl: TPPGLabel;
begin
  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(X, Y, AWidth, 20);
  Lbl.Caption := ACaption;

  Result := TPPGMaskEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(X, Y + 22, AWidth, 32);
  Result.EditMask := AMask;
  Result.Alignment := taCenter;
  Result.StyleManager := FStyles;
  Result.OnChange := TimeChange;
  Lbl.FocusControl := Result;
end;

constructor TTimeEntry.CreateEntry(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStyles := AStyles;
  FMinutes := -1;
  // ;1; = Punkte und Doppelpunkt gehoeren zum Text ("09.10.2026", "08:30")
  FDate := NewField(AParent, 16, 16, 130, '&Datum', '00.00.0000;1;_');
  FStart := NewField(AParent, 160, 16, 80, '&Beginn', '00:00;1;_');
  FEnd := NewField(AParent, 254, 16, 80, '&Ende', '00:00;1;_');

  FDuration := TPPGLabel.Create(Self);
  FDuration.Parent := AParent;
  FDuration.SetBounds(16, 84, 414, 20);
  FDuration.Caption := 'Dauer: Beginn und Ende eingeben';

  FDate.Text := FormatDateTime('dd"."mm"."yyyy', Date);
end;

function TTimeEntry.Complete(AField: TPPGMaskEdit): Boolean;
begin
  // Alle Stellen belegt: kein Leerzeichen-Symbol mehr im angezeigten Text
  Result := not AField.IsEmpty and (Pos('_', AField.EditText) = 0);
end;

function TTimeEntry.MinuteOfDay(AField: TPPGMaskEdit): Integer;
var
  H, M: Integer;
begin
  // "hh:mm" -> Minuten seit Mitternacht; -1 = keine gueltige Uhrzeit
  H := StrToIntDef(Copy(AField.Text, 1, 2), -1);
  M := StrToIntDef(Copy(AField.Text, 4, 2), -1);
  if (H < 0) or (H > 23) or (M < 0) or (M > 59) then
    Result := -1
  else
    Result := H * 60 + M;
end;

procedure TTimeEntry.SetState(AField: TPPGMaskEdit; AState: TPPGValidationState;
  const AHint: string);
begin
  AField.ValidationHint := AHint;
  AField.ValidationState := AState;
end;

procedure TTimeEntry.TimeChange(Sender: TObject);
var
  S, E: Integer;
begin
  FMinutes := -1;
  if not (Complete(FStart) and Complete(FEnd)) then
  begin
    SetState(FStart, pvsNone, '');
    SetState(FEnd, pvsNone, '');
    FDuration.Caption := 'Dauer: Beginn und Ende eingeben';
    Exit;
  end;
  S := MinuteOfDay(FStart);
  E := MinuteOfDay(FEnd);
  // Die Maske prueft nur Ziffern; ob die Uhrzeit moeglich ist, pruefen wir
  if S < 0 then
    SetState(FStart, pvsError, 'Keine g' + #$00FC + 'ltige Uhrzeit')
  else
    SetState(FStart, pvsNone, '');
  if E < 0 then
    SetState(FEnd, pvsError, 'Keine g' + #$00FC + 'ltige Uhrzeit')
  else if (S >= 0) and (E <= S) then
    SetState(FEnd, pvsWarning, 'Ende liegt nicht nach dem Beginn')
  else
    SetState(FEnd, pvsNone, '');
  if (S < 0) or (E <= S) then
  begin
    FDuration.Caption := 'Dauer: bitte Uhrzeiten pr' + #$00FC + 'fen';
    Exit;
  end;
  FMinutes := E - S;
  FDuration.Caption := Format('Dauer: %d:%.2d Std. am %s', [FMinutes div 60, FMinutes mod 60,
    FDate.Text]);
end;
// EXAMPLE-END

end.
