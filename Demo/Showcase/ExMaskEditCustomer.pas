unit ExMaskEditCustomer;

// Praxisbeispiel 1 zu TPPGMaskEdit (Demo-Seite "Eingabe > TPPGMaskEdit"):
// Kundendaten erfassen mit Kundennummer, PLZ und IBAN. Zeigt EditMask (feste
// Zeichen wie "KD-", Grossschreibung per ">"), ValidateInput,
// IsEmpty, ValidationState/ValidationHint, OnChange und OnValidationError.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.MaskEdit, PPG.Button;

type
  /// Kundendaten: Kundennummer und PLZ sind Pflicht, die IBAN ist freiwillig.
  /// Speichern prueft alle Felder und markiert falsche rot.
  TCustomerForm = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FCustomerNo: TPPGMaskEdit;
    FZip: TPPGMaskEdit;
    FIban: TPPGMaskEdit;
    FSave: TPPGButton;
    FStatus: TPPGLabel;
    FSaved: Boolean;
    FLastInvalid: TPPGMaskEdit;
    function NewField(AParent: TWinControl; Y, AWidth: Integer;
      const ACaption, AMask: string): TPPGMaskEdit;
    function CheckField(AField: TPPGMaskEdit; ARequired: Boolean): Boolean;
    procedure FieldChange(Sender: TObject);
    procedure FieldInvalid(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  public
    constructor CreateForm(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property CustomerNo: TPPGMaskEdit read FCustomerNo;
    property Zip: TPPGMaskEdit read FZip;
    property Iban: TPPGMaskEdit read FIban;
    property SaveButton: TPPGButton read FSave;
    property Status: TPPGLabel read FStatus;
    property Saved: Boolean read FSaved;
    property LastInvalid: TPPGMaskEdit read FLastInvalid;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TCustomerForm.NewField(AParent: TWinControl; Y, AWidth: Integer;
  const ACaption, AMask: string): TPPGMaskEdit;
var
  Lbl: TPPGLabel;
begin
  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(16, Y + 6, 120, 20);
  Lbl.Caption := ACaption;

  Result := TPPGMaskEdit.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(140, Y, AWidth, 32);
  Result.EditMask := AMask;
  Result.StyleManager := FStyles;
  Result.OnChange := FieldChange;
  Result.OnValidationError := FieldInvalid;
  Lbl.FocusControl := Result;
end;

constructor TCustomerForm.CreateForm(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  // Maske = Muster;Literale speichern (1/0);Leerzeichen-Symbol
  // "KD-" ist fest vorgegeben und wird mit gespeichert (;1;)
  FCustomerNo := NewField(AParent, 16, 120, '&Kundennummer', 'KD-000000;1;_');
  // 0 = Ziffer Pflicht; eine PLZ hat keine festen Zeichen
  FZip := NewField(AParent, 56, 80, '&PLZ', '00000;0;_');
  // > = ab hier Grossbuchstaben, L = Buchstabe Pflicht; die Leerzeichen
  // gliedern die IBAN in Vierergruppen wie auf Rechnungen
  FIban := NewField(AParent, 96, 290, '&IBAN (optional)', '>LL00 0000 0000 0000 0000 00;1;_');

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(140, 144, 120, 32);
  FSave.Caption := 'Speichern';
  FSave.StyleManager := AStyles;
  FSave.OnClick := SaveClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 188, 414, 44);
  FStatus.AutoSize := False;
  FStatus.WordWrap := True;
  FStatus.Caption := 'Noch nicht gespeichert.';
end;

function TCustomerForm.CheckField(AField: TPPGMaskEdit; ARequired: Boolean): Boolean;
begin
  AField.ValidationState := pvsNone;
  if AField.IsEmpty then
  begin
    // Die Maske haelt ein leeres Feld fuer gueltig; Pflicht prueft man selbst
    Result := not ARequired;
    if ARequired then
    begin
      AField.ValidationHint := 'Pflichtfeld';
      AField.ValidationState := pvsError;
    end;
  end
  else
    // Wie beim Verlassen: rot mit Hinweis, OnValidationError bei Fehler
    Result := AField.ValidateInput;
end;

procedure TCustomerForm.FieldChange(Sender: TObject);
begin
  // Neue Eingabe: die Markierung bis zum naechsten Speichern entfernen
  TPPGMaskEdit(Sender).ValidationState := pvsNone;
  TPPGMaskEdit(Sender).ValidationHint := '';
  FSaved := False;
end;

procedure TCustomerForm.FieldInvalid(Sender: TObject);
begin
  FLastInvalid := TPPGMaskEdit(Sender);
  FStatus.Caption := Format('Eingabe unvollst' + #$00E4 + 'ndig ab Stelle %d.',
    [FLastInvalid.InvalidPos + 1]);
end;

procedure TCustomerForm.SaveClick(Sender: TObject);
var
  Ok: Boolean;
begin
  FLastInvalid := nil;
  Ok := CheckField(FCustomerNo, True);
  Ok := CheckField(FZip, True) and Ok;
  Ok := CheckField(FIban, False) and Ok;
  FSaved := Ok;
  if Ok then
    FStatus.Caption := Format('Gespeichert: %s, PLZ %s, IBAN %s',
      [FCustomerNo.Text, FZip.Text, Trim(FIban.Text)])
  else if FLastInvalid = nil then
    FStatus.Caption := 'Bitte die rot markierten Pflichtfelder ausf' + #$00FC + 'llen.';
end;
// EXAMPLE-END

end.
