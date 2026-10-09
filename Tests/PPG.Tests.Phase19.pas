unit PPG.Tests.Phase19;

{ Tests fuer Phase 19: Formular-Produktivitaet.
  19a: TPPGValidator (Regelarten, Adapter, Markieren ohne fremde Zustaende
  zu zerstoeren, automatische Pruefung, Sprung zum ersten Fehler,
  Streaming). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Variants, Vcl.Forms, Vcl.Controls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.ExtCtrls,
  PPG.Types, PPG.Controls.Field, PPG.Edit, PPG.NumberEdit, PPG.DatePicker, PPG.RadioGroup,
  PPG.CheckBox, PPG.Labels, PPG.Panel, PPG.PageControl, PPG.Expander, PPG.Validator,
  PPG.Tests.Controls;

type
  TValidatorTests = class(TControlTestCase)
  private
    FV: TPPGValidator;
    FLog: string;
    procedure ShowError(Sender: TObject; Control: TControl; const Message: string;
      Severity: TPPGValidationState);
    procedure CustomRule(Sender: TObject; Rule: TPPGValidationRule; const Value: Variant;
      var Valid: Boolean; var Message: string);
    function NewEdit(const AName: string; Y: Integer; AParent: TWinControl = nil): TPPGEdit;
    function NewLabel(const ACaption: string; AFor: TWinControl): TPPGLabel;
    procedure Pump;
    function ResultNames: string;
  protected
    procedure SetUp; override;
  published
    procedure RequiredMarksAndClears;
    procedure CaptionFromLabelTextHintOrName;
    procedure OwnMessageWithPlaceholder;
    procedure LengthRule;
    procedure RangeOnNumbersDatesAndText;
    procedure PatternKinds;
    procedure IBANChecksum;
    procedure CompareRules;
    procedure CustomRuleEvent;
    procedure EmptyValuesOnlyCheckedByRequired;
    procedure WarningsDoNotFailValidate;
    procedure FirstErrorWinsOverWarning;
    procedure ForeignStateIsKept;
    procedure ChoiceAndCheckAdapters;
    procedure VclAdapters;
    procedure UnsupportedControlRaises;
    procedure HiddenAndDisabledAreSkipped;
    procedure InactiveTabCounts;
    procedure GroupsAndChildren;
    procedure ValidateOnExitThenLive;
    procedure ValidateOnSubmitDoesNothingAutomatically;
    procedure ValidateOnChange;
    procedure CompareDependentIsRechecked;
    procedure FocusFirstErrorRevealsTabAndExpander;
    procedure ResultsInTabOrder;
    procedure ShowErrorEventOnlyOnChange;
    procedure ShowValidMarksGreen;
    procedure InvalidValuesRaiseAndKeepState;
    procedure FreeingControlClearsReferences;
    procedure InactiveValidatorAcceptsAll;
    procedure StreamsRules;
  end;

implementation

uses
  PPG.Exceptions, PPG.Lang, PPG.Consts;

{ TValidatorTests }

procedure TValidatorTests.SetUp;
begin
  inherited SetUp;
  FLog := '';
  FV := TPPGValidator.Create(FForm);
  FV.Name := 'Val';
end;

procedure TValidatorTests.Pump;
begin
  Application.ProcessMessages;
end;

function TValidatorTests.ResultNames: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FV.ResultCount - 1 do
    Result := Result + FV.Results[I].Control.Name + ' ';
end;

procedure TValidatorTests.ShowError(Sender: TObject; Control: TControl;
  const Message: string; Severity: TPPGValidationState);
begin
  if Severity = pvsNone then
    FLog := FLog + Control.Name + '-;'
  else
    FLog := FLog + Control.Name + '+;';
end;

procedure TValidatorTests.CustomRule(Sender: TObject; Rule: TPPGValidationRule;
  const Value: Variant; var Valid: Boolean; var Message: string);
begin
  Valid := VarToStr(Value) <> 'verboten';
  if not Valid then
    Message := 'Nicht erlaubt';
end;

function TValidatorTests.NewEdit(const AName: string; Y: Integer;
  AParent: TWinControl): TPPGEdit;
begin
  Result := TPPGEdit.Create(FForm);
  Result.Name := AName;
  if AParent = nil then
    AParent := FForm;
  Result.Parent := AParent;
  Result.SetBounds(120, Y, 150, 28);
  Result.Text := '';
end;

function TValidatorTests.NewLabel(const ACaption: string; AFor: TWinControl): TPPGLabel;
begin
  Result := TPPGLabel.Create(FForm);
  Result.Parent := AFor.Parent;
  Result.Caption := ACaption;
  Result.FocusControl := AFor;
  Result.SetBounds(10, AFor.Top, 100, 20);
end;

procedure TValidatorTests.RequiredMarksAndClears;
var
  E: TPPGEdit;
  R: TPPGValidationResult;
begin
  E := NewEdit('EName', 10);
  NewLabel('&Name:', E);
  FV.Rules.AddRule(E, vrRequired);
  CheckFalse(FV.Validate, 'leer');
  CheckEquals(1, FV.ErrorCount);
  CheckTrue(E.ValidationState = pvsError, 'markiert');
  CheckTrue(FV.ResultFor(E, R));
  CheckEquals(Format(PPGStr(@SPPGValRequired), ['Name']), R.Message, 'Beschriftung ohne & und :');
  CheckEquals(R.Message, E.ValidationHint, 'Hinweis am Feld');
  E.Text := '   ';
  CheckFalse(FV.Validate, 'nur Leerzeichen gilt als leer');
  E.Text := 'Anna';
  CheckTrue(FV.Validate);
  CheckEquals(0, FV.ResultCount);
  CheckTrue(E.ValidationState = pvsNone, 'zurueckgenommen');
  CheckEquals('', E.ValidationHint);
end;

procedure TValidatorTests.CaptionFromLabelTextHintOrName;
var
  E1, E2, E3: TPPGEdit;
  R: TPPGValidationRule;
begin
  E1 := NewEdit('E1', 10);
  NewLabel('Ort', E1);
  E2 := NewEdit('E2', 50);
  E2.TextHint := 'Telefon';
  E3 := NewEdit('E3', 90);
  CheckEquals('Ort', FV.Rules.AddRule(E1, vrRequired).FieldCaption);
  CheckEquals('Telefon', FV.Rules.AddRule(E2, vrRequired).FieldCaption);
  CheckEquals('E3', FV.Rules.AddRule(E3, vrRequired).FieldCaption);
  R := FV.Rules.AddRule(E3, vrLength);
  R.Caption := 'Kundennummer';
  CheckEquals('Kundennummer', R.FieldCaption, 'Caption gewinnt');
end;

procedure TValidatorTests.OwnMessageWithPlaceholder;
var
  E: TPPGEdit;
  R: TPPGValidationRule;
  Res: TPPGValidationResult;
begin
  E := NewEdit('E', 10);
  R := FV.Rules.AddRule(E, vrRequired);
  R.Caption := 'PLZ';
  R.Message := 'Bitte {caption} angeben';
  FV.Validate;
  CheckTrue(FV.ResultFor(E, Res));
  CheckEquals('Bitte PLZ angeben', Res.Message);
end;

procedure TValidatorTests.LengthRule;
var
  E: TPPGEdit;
  R: TPPGValidationRule;
  Res: TPPGValidationResult;
begin
  E := NewEdit('E', 10);
  R := FV.Rules.AddRule(E, vrLength);
  R.MinLength := 3;
  R.MaxLength := 5;
  E.Text := 'ab';
  CheckFalse(FV.Validate, 'zu kurz');
  FV.ResultFor(E, Res);
  CheckTrue(Pos('3', Res.Message) > 0, Res.Message);
  E.Text := 'abc';
  CheckTrue(FV.Validate);
  E.Text := 'abcde';
  CheckTrue(FV.Validate);
  E.Text := 'abcdef';
  CheckFalse(FV.Validate, 'zu lang');
  FV.ResultFor(E, Res);
  CheckTrue(Pos('5', Res.Message) > 0, Res.Message);
end;

procedure TValidatorTests.RangeOnNumbersDatesAndText;
var
  N: TPPGNumberEdit;
  D: TPPGDatePicker;
  E: TPPGEdit;
  R: TPPGValidationRule;
begin
  N := TPPGNumberEdit.Create(FForm);
  N.Name := 'Menge';
  N.Parent := FForm;
  R := FV.Rules.AddRule(N, vrRange);
  R.MinValue := '1';
  R.MaxValue := '99.5';
  N.Value := 0;
  CheckFalse(FV.ValidateControl(N), '0 < 1');
  N.Value := 99.5;
  CheckTrue(FV.ValidateControl(N), 'Grenze inklusive');
  N.Value := 100;
  CheckFalse(FV.ValidateControl(N), '100 > 99.5');

  D := TPPGDatePicker.Create(FForm);
  D.Name := 'Termin';
  D.Parent := FForm;
  D.Top := 40;
  R := FV.Rules.AddRule(D, vrRange);
  R.MinValue := '2026-01-01';
  D.Date := EncodeDate(2025, 12, 31);
  CheckFalse(FV.ValidateControl(D), 'vor dem Mindestdatum');
  D.Date := EncodeDate(2026, 1, 1);
  CheckTrue(FV.ValidateControl(D));

  E := NewEdit('Preis', 80);
  R := FV.Rules.AddRule(E, vrRange);
  R.MaxValue := '10';
  E.Text := FormatFloat('0.00', 12.5);
  CheckFalse(FV.ValidateControl(E), 'Text im Gebietsschema als Zahl');
  E.Text := 'abc';
  CheckFalse(FV.ValidateControl(E), 'keine Zahl');
  E.Text := '7';
  CheckTrue(FV.ValidateControl(E));
end;

procedure TValidatorTests.PatternKinds;
const
  Cases: array[0..13] of record Kind: TPPGValidationPattern; Value: string; Ok: Boolean; end = (
    (Kind: vpEmail; Value: 'anna@example.com'; Ok: True),
    (Kind: vpEmail; Value: 'anna.b@mail.example.de'; Ok: True),
    (Kind: vpEmail; Value: 'anna@'; Ok: False),
    (Kind: vpEmail; Value: 'anna example.com'; Ok: False),
    (Kind: vpEmail; Value: 'anna@example'; Ok: False),
    (Kind: vpPhone; Value: '+49 (30) 123456'; Ok: True),
    (Kind: vpPhone; Value: '030/123-456'; Ok: True),
    (Kind: vpPhone; Value: '12ab'; Ok: False),
    (Kind: vpPostalCodeDE; Value: '10115'; Ok: True),
    (Kind: vpPostalCodeDE; Value: '1011'; Ok: False),
    (Kind: vpPostalCodeDE; Value: '101155'; Ok: False),
    (Kind: vpIBAN; Value: 'DE89 3704 0044 0532 0130 00'; Ok: True),
    (Kind: vpIBAN; Value: 'DE89 3704 0044 0532 0130 01'; Ok: False),
    (Kind: vpCustom; Value: 'AB-12'; Ok: True));
var
  E: TPPGEdit;
  R: TPPGValidationRule;
  I: Integer;
begin
  E := NewEdit('E', 10);
  R := FV.Rules.AddRule(E, vrPattern);
  R.Pattern := '[A-Z]{2}-[0-9]+';
  for I := Low(Cases) to High(Cases) do
  begin
    R.PatternKind := Cases[I].Kind;
    E.Text := Cases[I].Value;
    CheckEquals(Cases[I].Ok, FV.Validate, Cases[I].Value);
  end;
  R.PatternKind := vpCustom;
  E.Text := 'xAB-12';
  CheckFalse(FV.Validate, 'Muster gilt fuer den ganzen Wert');
end;

procedure TValidatorTests.IBANChecksum;
begin
  CheckTrue(PPGCheckIBAN('DE89370400440532013000'));
  CheckTrue(PPGCheckIBAN('gb82 west 1234 5698 7654 32'), 'Kleinbuchstaben und Leerzeichen');
  CheckFalse(PPGCheckIBAN('DE8937040044053201300'), 'zu kurz/Pruefsumme');
  CheckFalse(PPGCheckIBAN('1E89370400440532013000'), 'Laendercode');
  CheckFalse(PPGCheckIBAN('DE89-3704-0044-0532-0130-00'), 'Bindestriche');
  CheckFalse(PPGCheckIBAN(''));
end;

procedure TValidatorTests.CompareRules;
var
  P1, P2: TPPGEdit;
  D1, D2: TPPGDatePicker;
  R: TPPGValidationRule;
  Res: TPPGValidationResult;
begin
  P1 := NewEdit('Pass1', 10);
  P2 := NewEdit('Pass2', 50);
  NewLabel('Passwort', P1);
  R := FV.Rules.AddRule(P2, vrCompare);
  R.CompareControl := P1;
  P1.Text := 'Geheim1';
  P2.Text := 'geheim1';
  CheckFalse(FV.Validate, 'Gross-/Kleinschreibung zaehlt');
  FV.ResultFor(P2, Res);
  CheckTrue(Pos('Passwort', Res.Message) > 0, 'nennt das Vergleichsfeld: ' + Res.Message);
  P2.Text := 'Geheim1';
  CheckTrue(FV.Validate);
  P1.Text := '';
  CheckTrue(FV.Validate, 'leerer Vergleichswert ist Sache seiner Pflicht-Regel');

  D1 := TPPGDatePicker.Create(FForm);
  D1.Name := 'Von';
  D1.Parent := FForm;
  D2 := TPPGDatePicker.Create(FForm);
  D2.Name := 'Bis';
  D2.Parent := FForm;
  R := FV.Rules.AddRule(D2, vrCompare);
  R.CompareControl := D1;
  R.CompareOperator := coGreaterOrEqual;
  D1.Date := EncodeDate(2026, 5, 10);
  D2.Date := EncodeDate(2026, 5, 9);
  CheckFalse(FV.ValidateControl(D2), 'Bis vor Von');
  D2.Date := EncodeDate(2026, 5, 10);
  CheckTrue(FV.ValidateControl(D2), 'gleich erlaubt');
  R.CompareOperator := coGreater;
  CheckFalse(FV.ValidateControl(D2), 'gleich nicht erlaubt');
end;

procedure TValidatorTests.CustomRuleEvent;
var
  E: TPPGEdit;
  Res: TPPGValidationResult;
begin
  E := NewEdit('E', 10);
  FV.Rules.AddRule(E, vrCustom);
  FV.OnValidate := CustomRule;
  E.Text := 'ok';
  CheckTrue(FV.Validate);
  E.Text := 'verboten';
  CheckFalse(FV.Validate);
  FV.ResultFor(E, Res);
  CheckEquals('Nicht erlaubt', Res.Message, 'Meldung des Handlers');
  FV.OnValidate := nil;
  CheckTrue(FV.Validate, 'ohne Handler gueltig');
end;

procedure TValidatorTests.EmptyValuesOnlyCheckedByRequired;
var
  E: TPPGEdit;
  R: TPPGValidationRule;
begin
  E := NewEdit('E', 10);
  R := FV.Rules.AddRule(E, vrLength);
  R.MinLength := 3;
  FV.Rules.AddRule(E, vrPattern).PatternKind := vpEmail;
  FV.Rules.AddRule(E, vrRange).MinValue := '5';
  CheckTrue(FV.Validate, 'leer und nicht Pflicht: gueltig');
end;

procedure TValidatorTests.WarningsDoNotFailValidate;
var
  E: TPPGEdit;
  R: TPPGValidationRule;
begin
  E := NewEdit('E', 10);
  R := FV.Rules.AddRule(E, vrRequired);
  R.Severity := pvsWarning;
  CheckTrue(FV.Validate, 'Warnung haelt nicht auf');
  CheckEquals(0, FV.ErrorCount);
  CheckEquals(1, FV.WarningCount);
  CheckTrue(E.ValidationState = pvsWarning);
  CheckFalse(FV.FocusFirstError, 'Sprung nur zu Fehlern');
end;

procedure TValidatorTests.FirstErrorWinsOverWarning;
var
  E: TPPGEdit;
  R: TPPGValidationRule;
  Res: TPPGValidationResult;
begin
  E := NewEdit('E', 10);
  E.Text := 'ab';
  R := FV.Rules.AddRule(E, vrLength);
  R.MinLength := 5;
  R.Severity := pvsWarning;
  R := FV.Rules.AddRule(E, vrPattern);
  R.PatternKind := vpPostalCodeDE;
  CheckFalse(FV.Validate);
  CheckTrue(FV.ResultFor(E, Res));
  CheckTrue(Res.Severity = pvsError, 'Fehler schlaegt fruehere Warnung');
  CheckTrue(Res.Rule = R);
  CheckEquals(1, FV.ResultCount, 'ein Ergebnis je Control');
end;

procedure TValidatorTests.ForeignStateIsKept;
var
  E: TPPGEdit;
begin
  E := NewEdit('E', 10);
  FV.Rules.AddRule(E, vrRequired);
  // Fremder Fehler (z.B. DB-Feld) wird nicht ueberschrieben ...
  E.ValidationState := pvsError;
  E.ValidationHint := 'Datenbankfehler';
  E.Text := 'x';
  CheckTrue(FV.Validate);
  CheckTrue(E.ValidationState = pvsError, 'fremder Zustand bleibt');
  E.Text := '';
  CheckFalse(FV.Validate);
  CheckEquals('Datenbankfehler', E.ValidationHint, 'fremder Text bleibt');
  // ... und was jemand nach uns setzt, nimmt der Validator nicht zurueck
  E.ValidationState := pvsNone;
  E.ValidationHint := '';
  CheckFalse(FV.Validate);
  CheckTrue(E.ValidationState = pvsError, 'jetzt eigener Fehler');
  E.ValidationState := pvsWarning;
  E.Text := 'x';
  CheckTrue(FV.Validate);
  CheckTrue(E.ValidationState = pvsWarning, 'inzwischen fremd: bleibt');
end;

procedure TValidatorTests.ChoiceAndCheckAdapters;
var
  G: TPPGRadioGroup;
  C: TPPGCheckBox;
  Res: TPPGValidationResult;
begin
  G := TPPGRadioGroup.Create(FForm);
  G.Name := 'Anrede';
  G.Parent := FForm;
  G.Caption := 'Anrede';
  G.Items.CommaText := 'Frau,Herr';
  C := TPPGCheckBox.Create(FForm);
  C.Name := 'Agb';
  C.Parent := FForm;
  C.Top := 200;
  C.Caption := '&AGB gelesen';
  FV.Rules.AddRule(G, vrRequired);
  FV.Rules.AddRule(C, vrRequired);
  CheckFalse(FV.Validate);
  CheckEquals(2, FV.ErrorCount);
  CheckTrue(G.ValidationState = pvsError, 'Gruppe markiert');
  FV.ResultFor(G, Res);
  CheckEquals(Format(PPGStr(@SPPGValMustChoose), ['Anrede']), Res.Message);
  FV.ResultFor(C, Res);
  CheckEquals(Format(PPGStr(@SPPGValMustCheck), ['AGB gelesen']), Res.Message);
  G.ItemIndex := 1;
  C.Checked := True;
  CheckTrue(FV.Validate);
  CheckTrue(G.ValidationState = pvsNone);
end;

procedure TValidatorTests.VclAdapters;
var
  E: TEdit;
  C: TCheckBox;
  B: TComboBox;
  P: TDateTimePicker;
begin
  E := TEdit.Create(FForm);
  E.Name := 'VEdit';
  E.Parent := FForm;
  E.Text := '';
  C := TCheckBox.Create(FForm);
  C.Name := 'VCheck';
  C.Parent := FForm;
  B := TComboBox.Create(FForm);
  B.Name := 'VCombo';
  B.Parent := FForm;
  B.Text := '';
  P := TDateTimePicker.Create(FForm);
  P.Name := 'VDate';
  P.Parent := FForm;
  P.ShowCheckbox := True;
  P.Checked := False;
  FV.Rules.AddRule(E, vrRequired);
  FV.Rules.AddRule(C, vrRequired);
  FV.Rules.AddRule(B, vrRequired);
  FV.Rules.AddRule(P, vrRequired);
  CheckFalse(FV.Validate);
  CheckEquals(4, FV.ErrorCount, 'alle vier leer: ' + ResultNames);
  E.Text := 'x';
  C.Checked := True;
  B.Text := 'y';
  P.Checked := True;
  CheckTrue(FV.Validate);
  CheckEquals(0, FV.ResultCount);
end;

procedure TValidatorTests.UnsupportedControlRaises;
var
  S: TShape;
begin
  S := TShape.Create(FForm);
  S.Name := 'Shape1';
  S.Parent := FForm;
  FV.Rules.AddRule(S, vrRequired);
  try
    FV.Validate;
    Fail('Control ohne Adapter muss werfen');
  except
    on E: EPPGError do
      CheckTrue(Pos('TShape', E.Message) > 0, E.Message);
  end;
end;

procedure TValidatorTests.HiddenAndDisabledAreSkipped;
var
  E1, E2, E3: TPPGEdit;
  P: TPPGPanel;
begin
  E1 := NewEdit('E1', 10);
  E2 := NewEdit('E2', 50);
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 100, 300, 80);
  E3 := NewEdit('E3', 10, P);
  FV.Rules.AddRule(E1, vrRequired);
  FV.Rules.AddRule(E2, vrRequired);
  FV.Rules.AddRule(E3, vrRequired);
  E1.Visible := False;
  E2.Enabled := False;
  P.Visible := False;
  CheckTrue(FV.Validate, 'verdeckt/gesperrt zaehlt nicht');
  P.Visible := True;
  CheckFalse(FV.Validate);
  CheckEquals(1, FV.ErrorCount);
end;

procedure TValidatorTests.InactiveTabCounts;
var
  PC: TPPGPageControl;
  S1, S2: TPPGTabSheet;
  E: TPPGEdit;
begin
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  PC.SetBounds(0, 0, 380, 250);
  S1 := TPPGTabSheet.Create(FForm);
  S1.PageControl := PC;
  S2 := TPPGTabSheet.Create(FForm);
  S2.PageControl := PC;
  PC.ActivePage := S1;
  E := NewEdit('E', 10, S2);
  FV.Rules.AddRule(E, vrRequired);
  CheckFalse(FV.Validate, 'Feld auf inaktivem Reiter wird geprueft');
  S2.TabVisible := False;
  CheckTrue(FV.Validate, 'ausgeblendeter Reiter nicht');
end;

procedure TValidatorTests.GroupsAndChildren;
var
  E1, E2, E3: TPPGEdit;
  P: TPPGPanel;
begin
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(0, 100, 300, 80);
  E1 := NewEdit('E1', 10);
  E2 := NewEdit('E2', 50);
  E3 := NewEdit('E3', 10, P);
  FV.Rules.AddRule(E1, vrRequired);
  FV.Rules.AddRule(E2, vrRequired).Group := 'Lieferung';
  FV.Rules.AddRule(E3, vrRequired).Group := 'Rechnung';
  CheckFalse(FV.ValidateGroup('Lieferung'));
  CheckEquals(2, FV.ErrorCount, 'ohne Gruppe + Lieferung');
  CheckTrue(E3.ValidationState = pvsNone, 'Rechnung nicht geprueft');
  FV.ClearResults;
  CheckEquals(0, FV.ResultCount);
  CheckTrue(E1.ValidationState = pvsNone, 'ClearResults nimmt Markierung zurueck');
  CheckFalse(FV.ValidateChildren(P));
  CheckEquals(1, FV.ErrorCount, 'nur im Panel');
  CheckTrue(E3.ValidationState = pvsError);
end;

procedure TValidatorTests.ValidateOnExitThenLive;
var
  E: TPPGEdit;
begin
  E := NewEdit('E', 10);
  FV.Rules.AddRule(E, vrRequired);
  CheckTrue(FV.ValidateOn = voExit, 'Vorgabe');
  E.Text := 'a';
  E.Text := '';
  Pump;
  CheckEquals(0, FV.ResultCount, 'Tippen ohne vorheriges Verlassen prueft nicht');
  E.Perform(CM_EXIT, 0, 0);
  CheckEquals(0, FV.ResultCount, 'erst nach der Nachrichtenschleife');
  Pump;
  CheckEquals(1, FV.ErrorCount, 'beim Verlassen geprueft');
  E.Text := 'Anna';
  Pump;
  CheckEquals(0, FV.ResultCount, 'nach einem Fehler live beim Tippen');
  CheckTrue(E.ValidationState = pvsNone);
end;

procedure TValidatorTests.ValidateOnSubmitDoesNothingAutomatically;
var
  E: TPPGEdit;
begin
  E := NewEdit('E', 10);
  FV.ValidateOn := voSubmit;
  FV.Rules.AddRule(E, vrRequired);
  E.Perform(CM_EXIT, 0, 0);
  Pump;
  CheckEquals(0, FV.ResultCount);
  CheckFalse(FV.Validate);
  E.Text := 'x';
  Pump;
  CheckEquals(0, FV.ResultCount, 'Ergebnis wird auch bei voSubmit live behoben');
end;

procedure TValidatorTests.ValidateOnChange;
var
  E: TPPGEdit;
  R: TPPGValidationRule;
begin
  E := NewEdit('E', 10);
  FV.ValidateOn := voChange;
  R := FV.Rules.AddRule(E, vrLength);
  R.MaxLength := 3;
  E.Text := 'abcd';
  Pump;
  CheckEquals(1, FV.ErrorCount, 'sofort beim Tippen');
  E.Text := 'abc';
  Pump;
  CheckEquals(0, FV.ResultCount);
end;

procedure TValidatorTests.CompareDependentIsRechecked;
var
  P1, P2: TPPGEdit;
  R: TPPGValidationRule;
begin
  P1 := NewEdit('Pass1', 10);
  P2 := NewEdit('Pass2', 50);
  R := FV.Rules.AddRule(P2, vrCompare);
  R.CompareControl := P1;
  P1.Text := 'abc';
  P2.Text := 'abd';
  P2.Perform(CM_EXIT, 0, 0);
  Pump;
  CheckEquals(1, FV.ErrorCount, 'Wiederholung passt nicht');
  P1.Text := 'abd';
  Pump;
  CheckEquals(0, FV.ResultCount, 'Aendern des ersten Felds prueft die Wiederholung neu');
end;

procedure TValidatorTests.FocusFirstErrorRevealsTabAndExpander;
var
  PC: TPPGPageControl;
  S1, S2: TPPGTabSheet;
  X: TPPGExpander;
  E1, E2: TPPGEdit;
begin
  PC := TPPGPageControl.Create(FForm);
  PC.Parent := FForm;
  PC.SetBounds(0, 0, 380, 250);
  S1 := TPPGTabSheet.Create(FForm);
  S1.PageControl := PC;
  S2 := TPPGTabSheet.Create(FForm);
  S2.PageControl := PC;
  X := TPPGExpander.Create(FForm);
  X.Parent := S2;
  X.SetBounds(0, 0, 300, 150);
  E2 := NewEdit('E2', 30, X);
  E1 := NewEdit('E1', 10, S1);
  E1.Text := 'ok';
  X.Expanded := False;
  PC.ActivePage := S1;
  FV.Rules.AddRule(E1, vrRequired);
  FV.Rules.AddRule(E2, vrRequired);
  FForm.Show;
  CheckFalse(FV.Validate);
  CheckTrue(FV.FocusFirstError);
  CheckTrue(PC.ActivePage = S2, 'Reiter aktiviert');
  CheckTrue(X.Expanded, 'Expander aufgeklappt');
  CheckTrue(E2.Focused, 'Fokus im Feld');
end;

procedure TValidatorTests.ResultsInTabOrder;
var
  A, B, C: TPPGEdit;
begin
  A := NewEdit('A', 10);
  B := NewEdit('B', 50);
  C := NewEdit('C', 90);
  C.TabOrder := 0;
  FV.Rules.AddRule(A, vrRequired);
  FV.Rules.AddRule(B, vrRequired);
  FV.Rules.AddRule(C, vrRequired);
  FV.Validate;
  CheckEquals(3, FV.ResultCount);
  CheckEquals('C', FV.Results[0].Control.Name, 'nach TabOrder, nicht nach Regel');
  CheckEquals('A', FV.Results[1].Control.Name);
  CheckEquals('B', FV.Results[2].Control.Name);
end;

procedure TValidatorTests.ShowErrorEventOnlyOnChange;
var
  E: TPPGEdit;
begin
  E := NewEdit('E', 10);
  FV.Rules.AddRule(E, vrRequired);
  FV.OnShowError := ShowError;
  FV.Validate;
  FV.Validate;
  CheckEquals('E+;', FLog, 'gleicher Fehler nur einmal');
  E.Text := 'x';
  FV.Validate;
  CheckEquals('E+;E-;', FLog, 'behoben');
  FV.Validate;
  CheckEquals('E+;E-;', FLog);
end;

procedure TValidatorTests.ShowValidMarksGreen;
var
  E1, E2: TPPGEdit;
begin
  E1 := NewEdit('E1', 10);
  E2 := NewEdit('E2', 50);
  E1.Text := 'x';
  FV.Rules.AddRule(E1, vrRequired);
  FV.ShowValid := True;
  CheckTrue(E1.ValidationState = pvsNone, 'ungeprueft bleibt neutral');
  FV.Validate;
  CheckTrue(E1.ValidationState = pvsValid, 'geprueft und gueltig');
  CheckTrue(E2.ValidationState = pvsNone, 'ohne Regel nichts');
  FV.ShowValid := False;
  CheckTrue(E1.ValidationState = pvsNone, 'abschalten nimmt Gruen zurueck');
end;

procedure TValidatorTests.InvalidValuesRaiseAndKeepState;
var
  E: TPPGEdit;
  R: TPPGValidationRule;
  procedure Expect(const What: string; Proc: TProc);
  begin
    try
      Proc();
      Fail(What + ' muss werfen');
    except
      on EPPGError do
    end;
  end;
begin
  E := NewEdit('E', 10);
  R := FV.Rules.AddRule(E, vrRange);
  R.MinValue := '5';
  R.Pattern := '[0-9]+';
  Expect('Severity pvsNone', procedure begin R.Severity := pvsNone; end);
  Expect('Severity pvsValid', procedure begin R.Severity := pvsValid; end);
  Expect('MinLength -1', procedure begin R.MinLength := -1; end);
  Expect('MinValue x', procedure begin R.MinValue := 'x'; end);
  Expect('MaxValue 31.12.2026', procedure begin R.MaxValue := '31.12.2026'; end);
  Expect('Pattern (', procedure begin R.Pattern := '('; end);
  CheckTrue(R.Severity = pvsError, 'unveraendert');
  CheckEquals(0, R.MinLength);
  CheckEquals('5', R.MinValue);
  CheckEquals('', R.MaxValue);
  CheckEquals('[0-9]+', R.Pattern);
  R.MaxValue := '2026-12-31';
  R.MaxValue := '2026-12-31 18:30';
  R.MinValue := '-3.5';
  R.MinValue := '';
  CheckEquals('', R.MinValue, 'leer = keine Grenze');
end;

procedure TValidatorTests.FreeingControlClearsReferences;
var
  P1, P2: TPPGEdit;
  R: TPPGValidationRule;
begin
  P1 := NewEdit('P1', 10);
  P2 := NewEdit('P2', 50);
  FV.Rules.AddRule(P1, vrRequired);
  R := FV.Rules.AddRule(P2, vrCompare);
  R.CompareControl := P1;
  FV.Validate;
  CheckEquals(1, FV.ResultCount);
  P1.Free;
  CheckTrue(FV.Rules[0].Control = nil, 'Regel-Control geloescht');
  CheckTrue(R.CompareControl = nil, 'Vergleichs-Control geloescht');
  CheckEquals(0, FV.ResultCount, 'Ergebnis entfernt');
  CheckTrue(FV.Validate, 'Regel ohne Control wird uebersprungen');
  P2.Perform(CM_EXIT, 0, 0);
  Pump;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TValidatorTests.InactiveValidatorAcceptsAll;
var
  E: TPPGEdit;
begin
  E := NewEdit('E', 10);
  FV.Rules.AddRule(E, vrRequired);
  FV.Validate;
  CheckTrue(E.ValidationState = pvsError);
  FV.Active := False;
  CheckTrue(E.ValidationState = pvsNone, 'Abschalten nimmt Markierungen zurueck');
  CheckTrue(FV.Validate);
  CheckEquals(0, FV.ResultCount);
end;

procedure TValidatorTests.StreamsRules;
var
  M: TMemoryStream;
  E1, E2: TPPGEdit;
  R: TPPGValidationRule;
  F2: TForm;
  V2: TPPGValidator;
begin
  E1 := NewEdit('EMail', 10);
  E2 := NewEdit('EMail2', 50);
  FV.ValidateOn := voChange;
  FV.ShowValid := True;
  R := FV.Rules.AddRule(E1, vrPattern);
  R.PatternKind := vpEmail;
  R.Severity := pvsWarning;
  R.Caption := 'E-Mail';
  R.Message := 'Bitte pruefen';
  R.Group := 'Kontakt';
  R := FV.Rules.AddRule(E2, vrCompare);
  R.CompareControl := E1;
  R.CompareOperator := coNotEqual;
  R := FV.Rules.AddRule(E1, vrLength);
  R.MinLength := 2;
  R.MaxLength := 80;
  R := FV.Rules.AddRule(E1, vrRange);
  R.MinValue := '1.5';
  R.MaxValue := '2026-12-31';
  R.Enabled := False;
  R := FV.Rules.AddRule(E1, vrPattern);
  R.Pattern := '[a-z]+';
  RegisterClasses([TPPGEdit, TPPGValidator]);
  M := TMemoryStream.Create;
  F2 := TForm.CreateNew(nil);
  try
    M.WriteComponent(FForm);
    M.Position := 0;
    M.ReadComponent(F2);
    V2 := F2.FindComponent('Val') as TPPGValidator;
    CheckNotNull(V2);
    CheckTrue(V2.ValidateOn = voChange);
    CheckTrue(V2.ShowValid);
    CheckEquals(5, V2.Rules.Count);
    CheckTrue(V2.Rules[0].Control = F2.FindComponent('EMail'), 'Referenz aufgeloest');
    CheckTrue(V2.Rules[0].PatternKind = vpEmail);
    CheckTrue(V2.Rules[0].Severity = pvsWarning);
    CheckEquals('E-Mail', V2.Rules[0].Caption);
    CheckEquals('Bitte pruefen', V2.Rules[0].Message);
    CheckEquals('Kontakt', V2.Rules[0].Group);
    CheckTrue(V2.Rules[1].CompareControl = F2.FindComponent('EMail'));
    CheckTrue(V2.Rules[1].CompareOperator = coNotEqual);
    CheckEquals(2, V2.Rules[2].MinLength);
    CheckEquals(80, V2.Rules[2].MaxLength);
    CheckEquals('1.5', V2.Rules[3].MinValue);
    CheckEquals('2026-12-31', V2.Rules[3].MaxValue);
    CheckFalse(V2.Rules[3].Enabled);
    CheckEquals('[a-z]+', V2.Rules[4].Pattern);
  finally
    F2.Free;
    M.Free;
  end;
end;

initialization
  RegisterTest('Phase19', TValidatorTests.Suite);

end.
