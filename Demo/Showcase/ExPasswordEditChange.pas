unit ExPasswordEditChange;

// Praxisbeispiel 2 zu TPPGPasswordEdit (Demo-Seite "Eingabe > TPPGPasswordEdit"):
// Einstellungen "Kennwort aendern" mit neuem Kennwort und Wiederholung.
// Pruefung beim Tippen (OnChange, ValidationState, ValidationHint), Auge zum
// Umschalten (rmToggle), das ueber OnRevealChange und Revealed auch das
// zweite Feld aufdeckt (dort ohne eigenes Auge: rmHidden).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.PasswordEdit, PPG.Button;

type
  /// Kennwort aendern: mindestens 8 Zeichen, Wiederholung muss passen;
  /// erst dann ist "Kennwort setzen" frei.
  TChangePasswordBox = class(TComponent)
  private
    FNew: TPPGPasswordEdit;
    FRepeat: TPPGPasswordEdit;
    FSave: TPPGButton;
    FStatus: TPPGLabel;
    FSavedCount: Integer;
    function NewLabel(AParent: TWinControl; Y: Integer; const ACaption: string): TPPGLabel;
    procedure CheckInput(Sender: TObject);
    procedure NewRevealChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  public
    constructor CreateBox(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property NewPassword: TPPGPasswordEdit read FNew;
    property RepeatPassword: TPPGPasswordEdit read FRepeat;
    property SaveButton: TPPGButton read FSave;
    property SavedCount: Integer read FSavedCount;
  end;

/// Bewertet ein Kennwort: Fehler (zu kurz), Warnung (nur Buchstaben oder
/// nur Ziffern) oder gueltig; AHint erklaert das Ergebnis.
function RatePassword(const S: string; out AHint: string): TPPGValidationState;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function RatePassword(const S: string; out AHint: string): TPPGValidationState;
var
  I: Integer;
  HasDigit, HasLetter: Boolean;
begin
  AHint := '';
  if S = '' then
    Exit(pvsNone);
  if Length(S) < 8 then
  begin
    AHint := 'Mindestens 8 Zeichen.';
    Exit(pvsError);
  end;
  HasDigit := False;
  HasLetter := False;
  for I := 1 to Length(S) do
    if CharInSet(S[I], ['0'..'9']) then
      HasDigit := True
    else
      HasLetter := True;
  if HasDigit and HasLetter then
    Result := pvsValid
  else
  begin
    AHint := 'Sicherer mit Ziffern und Buchstaben.';
    Result := pvsWarning;
  end;
end;

function TChangePasswordBox.NewLabel(AParent: TWinControl; Y: Integer;
  const ACaption: string): TPPGLabel;
begin
  Result := TPPGLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(16, Y, 300, 20);
  Result.Caption := ACaption;
end;

constructor TChangePasswordBox.CreateBox(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  // Neues Kennwort: Auge zum Umschalten, Laenge begrenzt
  FNew := TPPGPasswordEdit.Create(Self);
  FNew.Parent := AParent;
  FNew.SetBounds(16, 40, 300, 32);
  FNew.TextHint := 'Mindestens 8 Zeichen';
  FNew.RevealMode := rmToggle;
  FNew.MaxLength := 64;
  FNew.StyleManager := AStyles;
  FNew.OnChange := CheckInput;
  FNew.OnRevealChange := NewRevealChange;
  NewLabel(AParent, 16, '&Neues Kennwort:').FocusControl := FNew;

  // Wiederholung: kein eigenes Auge, folgt dem ersten Feld
  FRepeat := TPPGPasswordEdit.Create(Self);
  FRepeat.Parent := AParent;
  FRepeat.SetBounds(16, 108, 300, 32);
  FRepeat.TextHint := 'Kennwort wiederholen';
  FRepeat.RevealMode := rmHidden;
  FRepeat.MaxLength := 64;
  FRepeat.StyleManager := AStyles;
  FRepeat.OnChange := CheckInput;
  NewLabel(AParent, 84, '&Wiederholen:').FocusControl := FRepeat;

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(16, 156, 160, 32);
  FSave.Caption := 'Kennwort setzen';
  FSave.StyleManager := AStyles;
  FSave.Enabled := False;
  FSave.OnClick := SaveClick;

  FStatus := NewLabel(AParent, 200, 'Das Kennwort wurde noch nicht geaendert.');
  FStatus.Width := 414;
end;

procedure TChangePasswordBox.CheckInput(Sender: TObject);
var
  Hint: string;
begin
  // Beim Tippen pruefen: Rand und Tooltip sagen sofort, was fehlt
  FNew.ValidationState := RatePassword(FNew.Text, Hint);
  FNew.ValidationHint := Hint;
  if FRepeat.Text = '' then
    FRepeat.ValidationState := pvsNone
  else if FRepeat.Text = FNew.Text then
    FRepeat.ValidationState := pvsValid
  else
    FRepeat.ValidationState := pvsError;
  if FRepeat.ValidationState = pvsError then
    FRepeat.ValidationHint := 'Die Eingaben sind verschieden.'
  else
    FRepeat.ValidationHint := '';
  FSave.Enabled := (FNew.ValidationState in [pvsValid, pvsWarning]) and
    (FRepeat.ValidationState = pvsValid);
end;

procedure TChangePasswordBox.NewRevealChange(Sender: TObject);
begin
  // Der Anwender hat das Auge geklickt: Wiederholung gleich mit aufdecken.
  // Revealed aus Code loest kein weiteres OnRevealChange aus.
  FRepeat.Revealed := FNew.Revealed;
end;

procedure TChangePasswordBox.SaveClick(Sender: TObject);
begin
  Inc(FSavedCount);
  // Hier das Kennwort speichern (z. B. als Hash), danach nichts stehen lassen
  FNew.Clear;
  FRepeat.Clear;
  FNew.Revealed := False;
  FRepeat.Revealed := False;
  FStatus.Caption := 'Neues Kennwort gespeichert.';
end;
// EXAMPLE-END

end.
