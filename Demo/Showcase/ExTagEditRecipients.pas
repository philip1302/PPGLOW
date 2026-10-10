unit ExTagEditRecipients;

// Praxisbeispiel 1 zu TPPGTagEdit (Demo-Seite "Eingabe > TPPGTagEdit"):
// Empfaengerfeld einer E-Mail wie in Outlook. Vorschlaege aus dem Adressbuch
// (Suggestions), Pruefung jeder Adresse (OnTagAdding, ValidationState),
// Hoechstzahl (MaxTags) und Senden erst mit mindestens einem Empfaenger
// (OnChange). Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als
// Code an (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.Controls.Field, PPG.TagEdit, PPG.Button;

type
  /// Empfaengerfeld einer E-Mail: nur gueltige Adressen, hoechstens fuenf,
  /// Senden erst mit mindestens einem Empfaenger.
  TRecipientField = class(TComponent)
  private
    FPrompt: TPPGLabel;
    FTo: TPPGTagEdit;
    FStatus: TPPGLabel;
    FSend: TPPGButton;
    FLastSent: string;
    procedure RecipientAdding(Sender: TObject; var Tag: string; var Allow: Boolean);
    procedure RecipientRemoved(Sender: TObject; const Tag: string);
    procedure RecipientsChange(Sender: TObject);
    procedure SendClick(Sender: TObject);
  public
    constructor CreateField(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property Recipients: TPPGTagEdit read FTo;
    property SendButton: TPPGButton read FSend;
    property Status: TPPGLabel read FStatus;
    property LastSent: string read FLastSent;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  MaxRecipients = 5;

function IsMailAddress(const S: string): Boolean;
var
  At: Integer;
begin
  // Bewusst einfach: Name@Domain.Endung ohne Leerzeichen
  At := Pos('@', S);
  Result := (At > 1) and (Pos(' ', S) = 0) and (Pos('.', Copy(S, At + 2, MaxInt)) > 0) and
    (S[Length(S)] <> '.');
end;

constructor TRecipientField.CreateField(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  FPrompt := TPPGLabel.Create(Self);
  FPrompt.Parent := AParent;
  FPrompt.SetBounds(16, 16, 410, 20);
  FPrompt.Caption := '&An:';

  // Adressen mit Enter, ";" oder "," abschliessen; Vorschlaege beim Tippen
  FTo := TPPGTagEdit.Create(Self);
  FTo.Parent := AParent;
  FTo.SetBounds(16, 40, 410, 32);
  FTo.StyleManager := AStyles;
  FTo.TextHint := 'Name oder E-Mail-Adresse';
  FTo.Suggestions.CommaText := 'anna.berger@kunde.de,max.huber@kunde.de,' +
    'einkauf@kunde.de,buchhaltung@kunde.de,service@lieferant.de';
  FTo.MaxTags := MaxRecipients;
  FTo.OnTagAdding := RecipientAdding;
  FTo.OnTagRemoved := RecipientRemoved;
  FTo.OnChange := RecipientsChange;
  FPrompt.FocusControl := FTo;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 150, 410, 20);
  FStatus.Caption := 'Noch keine Adresse eingetragen.';

  FSend := TPPGButton.Create(Self);
  FSend.Parent := AParent;
  FSend.SetBounds(16, 180, 120, 32);
  FSend.Caption := 'Senden';
  FSend.StyleManager := AStyles;
  FSend.Enabled := False;   // erst mit einem Empfaenger
  FSend.OnClick := SendClick;
end;

procedure TRecipientField.RecipientAdding(Sender: TObject; var Tag: string;
  var Allow: Boolean);
begin
  // Vor dem Anlegen: Schreibweise vereinheitlichen und Adresse pruefen
  Tag := LowerCase(Trim(Tag));
  Allow := IsMailAddress(Tag);
  if Allow then
  begin
    FTo.ValidationState := pvsNone;
    FTo.ValidationHint := '';
  end
  else
  begin
    // Abgelehnter Text bleibt im Feld stehen und kann korrigiert werden
    FTo.ValidationState := pvsError;
    FTo.ValidationHint := 'Keine E-Mail-Adresse: ' + Tag;
    FStatus.Caption := FTo.ValidationHint;
  end;
end;

procedure TRecipientField.RecipientRemoved(Sender: TObject; const Tag: string);
begin
  FStatus.Caption := Tag + ' entfernt.';
end;

procedure TRecipientField.RecipientsChange(Sender: TObject);
begin
  // OnChange kommt nur bei Aenderungen durch den Anwender
  FSend.Enabled := FTo.Tags.Count > 0;
  if FTo.Tags.Count > 0 then
    FSend.Caption := Format('Senden (%d)', [FTo.Tags.Count])
  else
    FSend.Caption := 'Senden';
  if FTo.Tags.Count >= MaxRecipients then
    FStatus.Caption := Format('Maximal %d Adressen erreicht.', [MaxRecipients]);
end;

procedure TRecipientField.SendClick(Sender: TObject);
begin
  // TagsText: alle Adressen, getrennt durch Delimiter (";")
  FLastSent := FTo.TagsText;
  FStatus.Caption := 'Gesendet an ' + FLastSent;
end;
// EXAMPLE-END

end.
