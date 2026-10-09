unit PPG.Tests.Phase12a;

{ Tests fuer Phase 12a/b: Feld-Basis (IPPGFieldInner, IPPGFieldValue,
  SetTextSilent), Zahlen lesen/rechnen/formatieren, TPPGNumberEdit,
  TPPGMaskEdit, TPPGPasswordEdit. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.Clipbrd,
  PPG.Types, PPG.Render.Registry, PPG.Controls.Base, PPG.Controls.Field, PPG.Edit, PPG.Memo,
  PPG.NumberFormat, PPG.NumberEdit, PPG.MaskEdit, PPG.PasswordEdit, PPG.SpinEdit,
  PPG.Exceptions, PPG.Tests.Controls;

type
  TNumberFormatTests = class(TTestCase)
  private
    FDE, FEN, FCH: TFormatSettings;
  protected
    procedure SetUp; override;
  published
    procedure ParseGerman;
    procedure ParseEnglishAndSwiss;
    procedure ParseCurrencyIsExact;
    procedure ParseRejectsGarbage;
    procedure EvalExpressions;
    procedure FormatDisplayAndEdit;
    procedure CaretFollowsDigits;
  end;

  TFieldBaseTests = class(TControlTestCase)
  private
    FChanges: Integer;
    procedure Changed(Sender: TObject);
  published
    procedure InnerEditsSupportFieldInner;
    procedure SetTextSilentFiresNoChange;
  end;

  TNumberEditTests = class(TControlTestCase)
  private
    FChanges: Integer;
    FDummy: TPPGEdit;
    FOldFS: TFormatSettings;
    FChangeText: string;
    procedure Changed(Sender: TObject);
    function NewNumber: TPPGNumberEdit;
    procedure TypeText(E: TPPGNumberEdit; const S: string);
    procedure Key(E: TPPGNumberEdit; VK: Word);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CodeSetsValueWithoutChange;
    procedure DisplayAndEditFormat;
    procedure EnterCommitsExpression;
    procedure InvalidInputShowsErrorAndReverts;
    procedure ClampAndSpin;
    procedure CurrencyRoundsHalfUpExactly;
    procedure NullHandling;
    procedure NumpadDecimalBecomesComma;
    procedure WheelOnlyWithFocus;
    procedure FieldValueInterface;
    procedure StreamingRoundTrip;
    procedure HugeAndNonFiniteValues;
    procedure PageKeysUseLargeIncrement;
  end;

  TMaskEditTests = class(TControlTestCase)
  private
    FErrorsSeen: Integer;
    procedure ValidationError(Sender: TObject);
  published
    procedure MaskAndTexts;
    procedure InvalidOnExitWithoutException;
    procedure EmptyIsValidAndNull;
    procedure StreamingRoundTrip;
  end;

  TPasswordEditTests = class(TControlTestCase)
  published
    procedure MasksAndReveals;
    procedure NoCopyWhileHidden;
    procedure CapsLockHint;
    procedure AccessibleAsProtected;
    procedure PaintsInAllPresets;
    procedure ZeroPasswordCharLoadsFromDfm;
  end;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Theme, PPG.Lang, PPG.Consts;

type
  TNumberAccess = class(TPPGNumberEdit);
  TPasswordAccess = class(TPPGPasswordEdit);

  TCapsPassword = class(TPPGPasswordEdit)
  public
    Caps: Boolean;
  protected
    function IsCapsLockOn: Boolean; override;
  end;

function TCapsPassword.IsCapsLockOn: Boolean;
begin
  Result := Caps;
end;

{ TNumberFormatTests }

procedure TNumberFormatTests.SetUp;
begin
  inherited SetUp;
  FDE := TFormatSettings.Create('de-DE');
  FDE.CurrencyString := #$20AC;
  FEN := TFormatSettings.Create('en-US');
  FCH := TFormatSettings.Create('de-CH');
  FCH.ThousandSeparator := '''';
  FCH.DecimalSeparator := '.';
end;

procedure CheckNum(T: TTestCase; const S: string; const FS: TFormatSettings; Expected: Double);
var
  V: Double;
begin
  T.CheckTrue(PPGParseNumber(S, FS, V), 'lesbar: ' + S);
  T.CheckEquals(Expected, V, 1E-9, S);
end;

procedure TNumberFormatTests.ParseGerman;
begin
  CheckNum(Self, '1.234,50', FDE, 1234.5);
  CheckNum(Self, '1234,5', FDE, 1234.5);
  CheckNum(Self, '1,234.50', FDE, 1234.5);       // eingefuegt aus englischer Quelle
  CheckNum(Self, '1.5', FDE, 1.5);               // Punkt mit einer Nachkommastelle
  CheckNum(Self, '1.234', FDE, 1234);            // Tausendergruppe
  CheckNum(Self, '0.234', FDE, 0.234);           // fuehrende Null: kein Tausender
  CheckNum(Self, '1.234.567,89', FDE, 1234567.89);
  CheckNum(Self, '12,5 %', FDE, 12.5);
  CheckNum(Self, '-1.234,50 '#$20AC, FDE, -1234.5);
  CheckNum(Self, '1.234,50 EUR', FDE, 1234.5);
  CheckNum(Self, '(12,50)', FDE, -12.5);
  CheckNum(Self, ',5', FDE, 0.5);
  CheckNum(Self, '1'#$A0'234,5', FDE, 1234.5);  // geschuetztes Leerzeichen
end;

procedure TNumberFormatTests.ParseEnglishAndSwiss;
begin
  CheckNum(Self, '1,234.50', FEN, 1234.5);
  CheckNum(Self, '$1,234.50', FEN, 1234.5);
  CheckNum(Self, '1.234,50', FEN, 1234.5);
  CheckNum(Self, '1,234', FEN, 1234);
  CheckNum(Self, '1''234.50', FCH, 1234.5);
  CheckNum(Self, 'CHF 1''234.50', FCH, 1234.5);
end;

procedure TNumberFormatTests.ParseCurrencyIsExact;
var
  A, B: Currency;
begin
  CheckTrue(PPGParseCurrency('0,1', FDE, A));
  CheckTrue(PPGParseCurrency('0,2', FDE, B));
  CheckTrue(A + B = 0.3, 'Currency ohne Rundungsrest');
  CheckTrue(PPGParseCurrency('1.234.567,8901', FDE, A));
  CheckTrue(A = 1234567.8901);
end;

procedure TNumberFormatTests.ParseRejectsGarbage;
var
  V: Double;
begin
  CheckFalse(PPGParseNumber('', FDE, V));
  CheckFalse(PPGParseNumber('abc!', FDE, V));
  CheckFalse(PPGParseNumber('1.2.3', FDE, V));
  CheckFalse(PPGParseNumber('--5', FDE, V));
  CheckFalse(PPGParseNumber(',', FDE, V));
  // Audit 08.10.2026: Kuerzel und Ausdruecke sind keine Zahlen (Summen im Grid)
  CheckFalse(PPGParseNumber('A-100', FDE, V), 'A-100');
  CheckFalse(PPGParseNumber('1e3', FDE, V), '1e3');
  CheckFalse(PPGParseNumber('3x4', FDE, V), '3x4');
  CheckFalse(PPGParseNumber('100-5', FDE, V), '100-5');
  CheckFalse(PPGParseNumber('1+2', FDE, V), '1+2');
  CheckNum(Self, '100-', FDE, -100);
  CheckNum(Self, 'EUR -5,00', FDE, -5);
end;

procedure TNumberFormatTests.EvalExpressions;
var
  V: Double;
begin
  CheckTrue(PPGEvalNumber('2*19,99', FDE, V));
  CheckEquals(39.98, V, 1E-9);
  CheckTrue(PPGEvalNumber('(1+2)*3', FDE, V));
  CheckEquals(9, V, 1E-9);
  CheckTrue(PPGEvalNumber('-3+5', FDE, V));
  CheckEquals(2, V, 1E-9);
  CheckTrue(PPGEvalNumber('2*-3', FDE, V));
  CheckEquals(-6, V, 1E-9);
  CheckTrue(PPGEvalNumber('1.000 + 1,5', FDE, V));
  CheckEquals(1001.5, V, 1E-9);
  CheckTrue(PPGEvalNumber('10 / 4', FDE, V));
  CheckEquals(2.5, V, 1E-9);
  CheckFalse(PPGEvalNumber('10/0', FDE, V), 'Division durch Null');
  CheckFalse(PPGEvalNumber('1+', FDE, V));
  CheckFalse(PPGEvalNumber('(1+2', FDE, V));
  CheckTrue(PPGIsExpression('1+2'));
  CheckFalse(PPGIsExpression('-5'));
  CheckFalse(PPGIsExpression('(12,50)'));
end;

procedure TNumberFormatTests.FormatDisplayAndEdit;
begin
  CheckEquals('1.234,50 '#$20AC, PPGFormatNumber(1234.5, nkCurrency, 2, True, '', FDE));
  CheckEquals('$1,234.50', PPGFormatNumber(1234.5, nkCurrency, 2, True, '', FEN));
  CheckEquals('1.234,50 CHF', PPGFormatNumber(1234.5, nkCurrency, 2, True, 'CHF', FDE));
  CheckEquals('1234,50 '#$20AC, PPGFormatNumber(1234.5, nkCurrency, 2, False, '', FDE));
  CheckEquals('12,5'#$A0'%', PPGFormatNumber(12.5, nkPercent, 1, True, '', FDE));
  CheckEquals('12.5%', PPGFormatNumber(12.5, nkPercent, 1, True, '', FEN));
  CheckEquals('1.235', PPGFormatNumber(1234.6, nkInteger, 2, True, '', FDE));
  CheckEquals('1.234,568', PPGFormatNumber(1234.5678, nkFloat, 3, True, '', FDE));
  CheckEquals('1234,5', PPGFormatEditNumber(1234.5, 2, FDE));
  CheckEquals('1234', PPGFormatEditNumber(1234, 2, FDE));
  CheckEquals('0', PPGFormatEditNumber(-0.0001, 2, FDE));
end;

procedure TNumberFormatTests.CaretFollowsDigits;
begin
  // "1.234,50 EUR": Marke hinter der 3 (Position 4) -> "1234,5": hinter der 3 (3)
  CheckEquals(3, PPGMapCaretByDigits('1.234,50 '#$20AC, 4, '1234,5', FDE));
  // hinter dem Komma bleibt die Nachkommastelle erhalten
  CheckEquals(6, PPGMapCaretByDigits('1.234,50 '#$20AC, 7, '1234,5', FDE));
  // Anfang bleibt Anfang
  CheckEquals(0, PPGMapCaretByDigits('1.234,50', 0, '1234,5', FDE));
  // zurueck: "1234,5" Position 3 -> "1.234,50" hinter der 3 (Position 4)
  CheckEquals(4, PPGMapCaretByDigits('1234,5', 3, '1.234,50', FDE));
end;

{ TFieldBaseTests }

procedure TFieldBaseTests.Changed(Sender: TObject);
begin
  Inc(FChanges);
end;

procedure TFieldBaseTests.InnerEditsSupportFieldInner;
var
  E: TPPGEdit;
  M: TPPGMemo;
  K: TPPGMaskEdit;
  I: IPPGFieldInner;
begin
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  M := TPPGMemo.Create(FForm);
  M.Parent := FForm;
  K := TPPGMaskEdit.Create(FForm);
  K.Parent := FForm;
  CheckTrue(Supports(TControl(E.Controls[0]), IPPGFieldInner, I), 'Edit');
  CheckTrue(Supports(TControl(M.Controls[0]), IPPGFieldInner, I), 'Memo');
  CheckTrue(Supports(TControl(K.Controls[0]), IPPGFieldInner, I), 'MaskEdit');
  I := nil;
  // Dark Mode faerbt auch das innere Masken-Edit (kein Sonderfall im Feld)
  TPPGTheme.Mode := tmDark;
  try
    K.HandleNeeded;
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    TPPGTheme.Mode := tmLight;
  end;
end;

procedure TFieldBaseTests.SetTextSilentFiresNoChange;
var
  E: TPPGNumberEdit;
begin
  E := TPPGNumberEdit.Create(FForm);
  E.Parent := FForm;
  E.HandleNeeded;
  E.OnChange := Changed;
  FChanges := 0;
  TNumberAccess(E).SetTextSilent('12');
  CheckEquals(0, FChanges);
  CheckEquals('12', E.Text);
end;

{ TNumberEditTests }

procedure TNumberEditTests.SetUp;
begin
  inherited SetUp;
  FOldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
  FormatSettings.CurrencyString := #$20AC;
  FChanges := 0;
  FDummy := TPPGEdit.Create(FForm);
  FDummy.Parent := FForm;
  FDummy.SetBounds(10, 200, 100, 32);
  FForm.Show;
end;

procedure TNumberEditTests.TearDown;
begin
  FormatSettings := FOldFS;
  inherited TearDown;
end;

procedure TNumberEditTests.Changed(Sender: TObject);
begin
  Inc(FChanges);
  FChangeText := TPPGNumberEdit(Sender).Text;
end;

function TNumberEditTests.NewNumber: TPPGNumberEdit;
begin
  Result := TPPGNumberEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 200, 32);
  Result.OnChange := Changed;
end;

procedure TNumberEditTests.TypeText(E: TPPGNumberEdit; const S: string);
var
  I: Integer;
begin
  E.SelectAll;
  E.SelText := '';
  for I := 1 to Length(S) do
    E.Controls[0].Perform(WM_CHAR, Ord(S[I]), 0);
end;

procedure TNumberEditTests.Key(E: TPPGNumberEdit; VK: Word);
begin
  E.Controls[0].Perform(WM_KEYDOWN, VK, 0);
  if VK = VK_RETURN then
    E.Controls[0].Perform(WM_CHAR, 13, 0)
  else if VK = VK_ESCAPE then
    E.Controls[0].Perform(WM_CHAR, 27, 0);
end;

procedure TNumberEditTests.CodeSetsValueWithoutChange;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.Value := 1234.5;
  E.AsCurrency := 7;
  E.Clear;
  E.AllowNull := True;
  E.Clear;
  CheckEquals(0, FChanges, 'Code loest kein OnChange aus');
end;

procedure TNumberEditTests.DisplayAndEditFormat;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.Kind := nkCurrency;
  E.Value := 1234.5;
  CheckEquals('1.234,50 '#$20AC, E.Text, 'ohne Fokus formatiert');
  E.SetFocus;
  Application.ProcessMessages;
  CheckEquals('1234,5', E.Text, 'mit Fokus roh');
  FDummy.SetFocus;
  Application.ProcessMessages;
  CheckEquals('1.234,50 '#$20AC, E.Text, 'nach dem Verlassen wieder formatiert');
  CheckEquals(0, FChanges);
end;

procedure TNumberEditTests.EnterCommitsExpression;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.SetFocus;
  TypeText(E, '2*19,99');
  CheckEquals(0, FChanges, 'kein OnChange je Tastendruck');
  Key(E, VK_RETURN);
  CheckEquals(39.98, E.Value, 1E-9);
  CheckEquals(1, FChanges);
  CheckEquals('39,98', E.Text);
  // Gleicher Wert erneut: kein OnChange
  Key(E, VK_RETURN);
  CheckEquals(1, FChanges);
  // Ohne Rechnen: Ausdruck ist ungueltig
  E.AllowExpressions := False;
  TypeText(E, '5');
  Key(E, VK_RETURN);
  CheckEquals(5, E.Value, 1E-9);
end;

procedure TNumberEditTests.InvalidInputShowsErrorAndReverts;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.Value := 10;
  E.SetFocus;
  E.Text := '1.2.3';
  Key(E, VK_RETURN);
  CheckTrue(E.ValidationState = pvsError, 'Fehler am Feld');
  CheckEquals(10, E.Value, 1E-9, 'Wert unveraendert');
  CheckTrue(E.ValidationHint <> '');
  FDummy.SetFocus;
  Application.ProcessMessages;
  CheckTrue(E.ValidationState = pvsNone, 'Fehler beim Verlassen weg');
  CheckEquals('10,00', E.Text, 'letzter gueltiger Wert');
  // Eigener Fehlerzustand des Anwenders bleibt unberuehrt
  E.ValidationState := pvsWarning;
  E.Value := 3;
  CheckTrue(E.ValidationState = pvsWarning);
end;

procedure TNumberEditTests.ClampAndSpin;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.Kind := nkInteger;
  E.Min := 0;
  E.Max := 10;
  E.Value := 50;
  CheckEquals(10, E.Value, 1E-9, 'still begrenzt');
  E.SetFocus;
  Key(E, VK_UP);
  CheckEquals(10, E.Value, 1E-9, 'Obergrenze');
  CheckEquals(0, FChanges, 'keine Aenderung, kein Ereignis');
  Key(E, VK_DOWN);
  CheckEquals(9, E.Value, 1E-9);
  CheckEquals(1, FChanges);
  E.LargeIncrement := 5;
  Key(E, VK_NEXT);
  CheckEquals(4, E.Value, 1E-9);
  E.ShowSpinButtons := True;
  CheckTrue(TNumberAccess(E).ButtonEnabled(PPGSpinButtonUp));
  E.Value := 0;
  CheckFalse(TNumberAccess(E).ButtonEnabled(PPGSpinButtonDown), 'Untergrenze');
  // Integer rundet kaufmaennisch
  E.Max := 0;
  E.Value := 2.5;
  CheckEquals(3, E.Value, 1E-9);
end;

procedure TNumberEditTests.CurrencyRoundsHalfUpExactly;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.Kind := nkCurrency;
  E.Decimals := 2;
  E.AsCurrency := 2.345;
  CheckTrue(E.AsCurrency = 2.35, 'kaufmaennisch, nicht zur geraden Ziffer: ' +
    CurrToStr(E.AsCurrency));
  E.AsCurrency := -2.345;
  CheckTrue(E.AsCurrency = -2.35);
  E.SetFocus;
  TypeText(E, '0,1+0,2');
  Key(E, VK_RETURN);
  CheckTrue(E.AsCurrency = 0.3);
  TypeText(E, '19,99 '#$20AC);
  Key(E, VK_RETURN);
  CheckTrue(E.AsCurrency = 19.99);
end;

procedure TNumberEditTests.NullHandling;
var
  E: TPPGNumberEdit;
  V: Variant;
begin
  E := NewNumber;
  E.SetFocus;
  TypeText(E, '');
  Key(E, VK_RETURN);
  CheckTrue(E.ValidationState = pvsError, 'leer ohne AllowNull');
  E.AllowNull := True;
  Key(E, VK_RETURN);
  CheckTrue(E.IsNull);
  CheckTrue(E.ValidationState = pvsNone);
  V := TNumberAccess(E).GetFieldValue;
  CheckTrue(VarIsNull(V));
  E.Value := 4;
  CheckFalse(E.IsNull);
  E.AllowNull := False;
  E.IsNull := True;
  CheckFalse(E.IsNull, 'ohne AllowNull kein Null');
end;

procedure TNumberEditTests.NumpadDecimalBecomesComma;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.SetFocus;
  TypeText(E, '3');
  E.Controls[0].Perform(WM_KEYDOWN, VK_DECIMAL, 0);
  E.Controls[0].Perform(WM_CHAR, Ord('.'), 0);
  E.Controls[0].Perform(WM_CHAR, Ord('5'), 0);
  CheckEquals('3,5', E.Text);
  Key(E, VK_RETURN);
  CheckEquals(3.5, E.Value, 1E-9);
  // Buchstaben werden abgewiesen
  E.Controls[0].Perform(WM_CHAR, Ord('x'), 0);
  CheckEquals(0, Pos('x', E.Text));
end;

procedure TNumberEditTests.WheelOnlyWithFocus;
var
  E: TPPGNumberEdit;
begin
  E := NewNumber;
  E.Value := 5;
  FDummy.SetFocus;
  TNumberAccess(E).DoMouseWheel([], WHEEL_DELTA, Point(0, 0));
  CheckEquals(5, E.Value, 1E-9, 'ohne Fokus kein Aendern beim Scrollen');
  E.SetFocus;
  TNumberAccess(E).DoMouseWheel([], WHEEL_DELTA, Point(0, 0));
  CheckEquals(6, E.Value, 1E-9);
end;

procedure TNumberEditTests.FieldValueInterface;
var
  E: TPPGNumberEdit;
  FV: IPPGFieldValue;
begin
  E := NewNumber;
  E.AllowNull := True;
  CheckTrue(Supports(E, IPPGFieldValue, FV));
  FV.SetFieldValue(12.5);
  CheckEquals(12.5, E.Value, 1E-9);
  FV.SetFieldValue(Null);
  CheckTrue(FV.FieldIsNull);
  E.Kind := nkCurrency;
  FV.SetFieldValue(1.1);
  CheckEquals(varCurrency, VarType(FV.GetFieldValue));
  FV := nil;
  CheckEquals(0, FChanges);
end;

procedure TNumberEditTests.HugeAndNonFiniteValues;
var
  E: TPPGNumberEdit;
  Raised: Integer;
begin
  // Audit 08.10.2026: Auch bei nkFloat wurde nach Currency gewandelt;
  // 1E15 bzw. NaN warfen EInvalidOp beim Verlassen bzw. beim Setzen.
  E := NewNumber;
  E.Kind := nkFloat;
  E.SetFocus;
  TypeText(E, '1000000000000000');
  FDummy.SetFocus;
  Application.ProcessMessages;
  CheckEquals(1E15, E.Value, 1, 'grosse Zahl uebernommen');
  CheckEquals(1, FChanges);
  CheckEquals(E.Text, FChangeText, 'OnChange sieht schon das Anzeigeformat');
  Raised := 0;
  try
    E.Value := NaN;
  except
    on Ex: EPPGPropertyError do
      Inc(Raised);
  end;
  E.Kind := nkFloat;
  E.Value := 5;
  E.Kind := nkCurrency;
  try
    E.Value := 1E16;
  except
    on Ex: EPPGPropertyError do
      Inc(Raised);
  end;
  try
    E.Increment := 0;
  except
    on Ex: EPPGPropertyError do
      Inc(Raised);
  end;
  CheckEquals(3, Raised);
  CheckEquals(5, E.Value, 1E-9, 'Wert unveraendert');
end;

procedure TNumberEditTests.PageKeysUseLargeIncrement;
var
  E: TPPGNumberEdit;
begin
  // Audit 08.10.2026: Round(LargeIncrement / Increment) Schritte: 0,4/1 = kein
  // Schritt, 10/3 = 9
  E := NewNumber;
  E.Kind := nkFloat;
  E.Value := 0;
  E.Increment := 1;
  E.LargeIncrement := 0.4;
  E.SetFocus;
  Key(E, VK_PRIOR);
  CheckEquals(0.4, E.Value, 1E-9, '0,4');
  E.Value := 0;
  E.Increment := 3;
  E.LargeIncrement := 10;
  Key(E, VK_PRIOR);
  CheckEquals(10, E.Value, 1E-9, '10 statt 9');
  Key(E, VK_NEXT);
  CheckEquals(0, E.Value, 1E-9);
end;

procedure TNumberEditTests.StreamingRoundTrip;
var
  E, E2: TPPGNumberEdit;
  MS: TMemoryStream;
begin
  E := NewNumber;
  E.Kind := nkPercent;
  E.Decimals := 1;
  E.Min := -5;
  E.Max := 200;
  E.Increment := 0.5;
  E.Value := 12.5;
  E.ShowSpinButtons := True;
  MS := TMemoryStream.Create;
  E2 := TPPGNumberEdit.Create(nil);
  try
    MS.WriteComponent(E);
    MS.Position := 0;
    MS.ReadComponent(E2);
    CheckTrue(E2.Kind = nkPercent);
    CheckEquals(1, E2.Decimals);
    CheckEquals(-5, E2.Min, 1E-9);
    CheckEquals(200, E2.Max, 1E-9);
    CheckEquals(0.5, E2.Increment, 1E-9);
    CheckEquals(12.5, E2.Value, 1E-9);
    CheckTrue(E2.ShowSpinButtons);
    // Null wird gespeichert
    E.AllowNull := True;
    E.Clear;
    MS.Clear;
    MS.WriteComponent(E);
    MS.Position := 0;
    E2.Free;
    E2 := TPPGNumberEdit.Create(nil);
    MS.ReadComponent(E2);
    CheckTrue(E2.IsNull);
  finally
    E2.Free;
    MS.Free;
  end;
end;

{ TMaskEditTests }

procedure TMaskEditTests.ValidationError(Sender: TObject);
begin
  Inc(FErrorsSeen);
end;

procedure TMaskEditTests.MaskAndTexts;
var
  M: TPPGMaskEdit;
begin
  M := TPPGMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.EditMask := '00000;0;_';
  M.Text := '12345';
  CheckEquals('12345', M.Text);
  CheckTrue(M.IsMasked);
  M.EditMask := '!(999) 000-0000;1;_';
  M.Text := '(089) 123-4567';
  CheckEquals('(089) 123-4567', M.EditText);
  CheckTrue(M.ValidateInput);
end;

procedure TMaskEditTests.InvalidOnExitWithoutException;
var
  M: TPPGMaskEdit;
  B: TPPGEdit;
begin
  FErrorsSeen := 0; // Leak-Lauf startet die Tests zweimal
  FForm.Show;
  M := TPPGMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.OnValidationError := ValidationError;
  B := TPPGEdit.Create(FForm);
  B.Parent := FForm;
  B.Top := 50;
  M.EditMask := '00000;0;_';
  M.SetFocus;
  M.Controls[0].Perform(WM_CHAR, Ord('1'), 0);
  M.Controls[0].Perform(WM_CHAR, Ord('2'), 0);
  B.SetFocus; // verlassen mit "12___": VCL wuerde EDBEditError werfen
  Application.ProcessMessages;
  CheckTrue(M.ValidationState = pvsError, 'Fehler am Feld');
  CheckEquals(1, FErrorsSeen);
  CheckEquals(0, FAppExceptions, 'keine Exception');
  CheckTrue(B.Focused, 'Fokus wird nicht festgehalten');
  // Korrigieren: Fehler weg
  M.Text := '12345';
  CheckTrue(M.ValidateInput);
  CheckTrue(M.ValidationState = pvsNone);
end;

procedure TMaskEditTests.EmptyIsValidAndNull;
var
  M: TPPGMaskEdit;
  FV: IPPGFieldValue;
begin
  M := TPPGMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.EditMask := '!99/99/0000;1;_';
  CheckTrue(M.IsEmpty);
  CheckTrue(M.ValidateInput, 'leeres Feld ist gueltig');
  CheckTrue(Supports(M, IPPGFieldValue, FV));
  CheckTrue(FV.FieldIsNull);
  FV.SetFieldValue('01/02/2026');
  CheckFalse(FV.FieldIsNull);
  CheckEquals('01/02/2026', VarToStr(FV.GetFieldValue));
  FV.FieldClear;
  CheckTrue(M.IsEmpty);
  FV := nil;
end;

procedure TMaskEditTests.StreamingRoundTrip;
var
  M, M2: TPPGMaskEdit;
  MS: TMemoryStream;
begin
  M := TPPGMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.EditMask := '>LL 00;1;_';
  M.Text := 'AB 12';
  MS := TMemoryStream.Create;
  M2 := TPPGMaskEdit.Create(nil);
  try
    MS.WriteComponent(M);
    MS.Position := 0;
    MS.ReadComponent(M2);
    CheckEquals('>LL 00;1;_', M2.EditMask);
    CheckEquals('AB 12', M2.Text);
  finally
    M2.Free;
    MS.Free;
  end;
end;

/// Zwischenablage kurz belegt (anderes Programm): einige Male versuchen.
procedure SetClip(const S: string);
var
  I: Integer;
begin
  for I := 1 to 20 do
    try
      Clipboard.AsText := S;
      Exit;
    except
      on EClipboardException do
        Sleep(50);
    end;
  Clipboard.AsText := S;
end;

function GetClip: string;
var
  I: Integer;
begin
  for I := 1 to 20 do
    try
      Exit(Clipboard.AsText);
    except
      on EClipboardException do
        Sleep(50);
    end;
  Result := Clipboard.AsText;
end;

{ TPasswordEditTests }

procedure TPasswordEditTests.MasksAndReveals;
var
  P: TPPGPasswordEdit;
  Inner: TCustomEdit;
begin
  P := TPPGPasswordEdit.Create(FForm);
  P.Parent := FForm;
  Inner := TCustomEdit(P.Controls[0]);
  P.Text := 'geheim';
  CheckTrue(TEdit(Inner).PasswordChar = #$25CF, 'verdeckt');
  // Peek: nur solange gedrueckt
  TPasswordAccess(P).ButtonDown(PPGPasswordButtonReveal);
  CheckTrue(P.Revealed);
  CheckTrue(TEdit(Inner).PasswordChar = #0);
  TPasswordAccess(P).ButtonUp(PPGPasswordButtonReveal);
  CheckFalse(P.Revealed);
  // Umschalten
  P.RevealMode := rmToggle;
  TPasswordAccess(P).ButtonClick(PPGPasswordButtonReveal);
  CheckTrue(P.Revealed);
  TPasswordAccess(P).ButtonClick(PPGPasswordButtonReveal);
  CheckFalse(P.Revealed);
  // Ohne Auge
  P.RevealMode := rmHidden;
  CheckFalse(TPasswordAccess(P).ButtonVisible(PPGPasswordButtonReveal));
  // PasswordChar #0 ist kein gueltiger Wert
  try
    P.PasswordChar := #0;
    Fail('#0 muss abgelehnt werden');
  except
    on EPPGPropertyError do
      ;
  end;
  P.Clear;
  CheckEquals('', P.Text);
end;

procedure TPasswordEditTests.ZeroPasswordCharLoadsFromDfm;
var
  Src, Bin: TStringStream;
  P: TPPGPasswordEdit;
begin
  // Audit 08.10.2026: PasswordChar = #0 in der DFM warf beim Laden
  Src := TStringStream.Create('object Pw: TPPGPasswordEdit'#13#10'  PasswordChar = #0'#13#10'end'#13#10);
  Bin := TStringStream.Create('');
  P := TPPGPasswordEdit.Create(nil);
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(P);
    CheckTrue(P.PasswordChar = #$25CF, 'bisheriges Zeichen bleibt');
  finally
    P.Free;
    Bin.Free;
    Src.Free;
  end;
end;

procedure TPasswordEditTests.NoCopyWhileHidden;
var
  P: TPPGPasswordEdit;
begin
  P := TPPGPasswordEdit.Create(FForm);
  P.Parent := FForm;
  P.HandleNeeded;
  P.Text := 'geheim';
  SetClip('vorher');
  P.SelectAll;
  P.Controls[0].Perform(WM_COPY, 0, 0);
  CheckEquals('vorher', GetClip, 'verdeckt: kein Kopieren');
  P.Controls[0].Perform(WM_CUT, 0, 0);
  CheckEquals('geheim', P.Text, 'verdeckt: kein Ausschneiden');
  P.Revealed := True;
  P.SelectAll;
  P.Controls[0].Perform(WM_COPY, 0, 0);
  CheckEquals('geheim', GetClip, 'aufgedeckt: kopieren erlaubt');
  SetClip('');
end;

procedure TPasswordEditTests.CapsLockHint;
var
  P: TCapsPassword;
begin
  FForm.Show;
  P := TCapsPassword.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(10, 10, 220, 32);
  P.Caps := True;
  P.SetFocus;
  Application.ProcessMessages;
  P.CheckCapsLock;
  CheckTrue(P.CapsLockHintVisible, 'Feststelltaste an, Fokus');
  CheckFalse(IsRectEmpty(P.ButtonRect(PPGPasswordButtonCaps)), 'Plakette hat Platz');
  CheckTrue(Pos(PPGStr(@SPPGCapsLockOn), P.AccDescription) > 0);
  P.Caps := False;
  P.CheckCapsLock;
  CheckFalse(P.CapsLockHintVisible);
  P.CapsLockWarning := False;
  P.Caps := True;
  P.CheckCapsLock;
  CheckFalse(P.CapsLockHintVisible, 'abgeschaltet');
end;

procedure TPasswordEditTests.AccessibleAsProtected;
var
  P: TPPGPasswordEdit;
begin
  P := TPPGPasswordEdit.Create(FForm);
  P.Parent := FForm;
  P.Text := 'geheim';
  CheckTrue(TPasswordAccess(P).AccState and STATE_SYSTEM_PROTECTED <> 0);
  CheckEquals('', TPasswordAccess(P).AccValue, 'nie Klartext');
end;

procedure TPasswordEditTests.PaintsInAllPresets;
var
  Names: TStringList;
  I: Integer;
  Dark: Boolean;
  P: TCapsPassword;
  N: TPPGNumberEdit;
  M: TPPGMaskEdit;
  B: TBitmap;
begin
  FForm.Show;
  Names := TStringList.Create;
  try
    P := TCapsPassword.Create(FForm);
    P.Parent := FForm;
    P.SetBounds(10, 10, 220, 32);
    P.Text := 'x';
    P.Caps := True;
    N := TPPGNumberEdit.Create(FForm);
    N.Parent := FForm;
    N.SetBounds(10, 60, 220, 32);
    N.ShowSpinButtons := True;
    M := TPPGMaskEdit.Create(FForm);
    M.Parent := FForm;
    M.SetBounds(10, 110, 220, 32);
    M.EditMask := '00000;0;_';
    P.SetFocus;
    P.CheckCapsLock;
    TPPGRendererRegistry.GetNames(Names);
    for I := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        P.Preset := Names[I];
        N.Preset := Names[I];
        M.Preset := Names[I];
        B := RenderToBitmap(P);
        B.Free;
        B := RenderToBitmap(N);
        B.Free;
        B := RenderToBitmap(M);
        B.Free;
      end;
    TPPGTheme.Mode := tmLight;
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Names.Free;
  end;
end;

initialization
  RegisterTest('Phase12a', TNumberFormatTests.Suite);
  RegisterTest('Phase12a', TFieldBaseTests.Suite);
  RegisterTest('Phase12a', TNumberEditTests.Suite);
  RegisterTest('Phase12a', TMaskEditTests.Suite);
  RegisterTest('Phase12a', TPasswordEditTests.Suite);

end.
