unit DemoShowColorPicker;

// Komponentenseite TPPGColorPicker (Gruppe "Eingabe"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// ColorPickers (Breite auf der Buehne, Kategorien, Farbname im Protokoll) und
// die beiden Praxisbeispiele (ExColorPickerCategories, ExColorPickerHighlight).

interface

uses
  System.SysUtils, System.Classes, System.UITypes, Vcl.Controls, Vcl.Graphics,
  PPG.ColorPicker, DemoKit, DemoShowcase, ExColorPickerCategories, ExColorPickerHighlight;

type
  TDemoShowColorPickerPage = class(TDemoComponentPage)
  private
    FCategories: TCategoryColors;
    FHighlight: THighlightSettings;
    FFirstSelect: Boolean;
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure Activated; override;
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  PPG.Controls.Field;

function TDemoShowColorPickerPage.SubjectClass: TComponentClass;
begin
  Result := TPPGColorPicker;
end;

procedure TDemoShowColorPickerPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Platz fuer Farbfeld und Namen bzw. Hexwert
  TPPGColorPicker(ASubject).Width := 220;
end;

procedure TDemoShowColorPickerPage.Activated;
begin
  inherited Activated;
  // Ohne Caption zeigt die Erklaerung sonst nichts: beim ersten Oeffnen
  // die wichtigste Eigenschaft waehlen
  if not FFirstSelect and (Inspector <> nil) then
  begin
    FFirstSelect := True;
    Inspector.SelectPath('Selected');
  end;
end;

procedure TDemoShowColorPickerPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Selected') or SameText(AName, 'Style') or SameText(AName, 'ShowThemeColors') or
    SameText(AName, 'RecentColors') or SameText(AName, 'MaxRecent') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'ShowHex') or SameText(AName, 'NoneColorColor') or
    SameText(AName, 'DefaultColorColor') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'ValidationState') or SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if SameText(AName, 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowColorPickerPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
  P: TPPGColorPicker;
begin
  Detail := ADetail;
  if (Subject is TPPGColorPicker) and ((AName = 'OnChange') or (AName = 'OnClick')) then
  begin
    P := TPPGColorPicker(Subject);
    Detail := Format('Selected = %s, zuletzt benutzt: %d', [P.ColorName(P.Selected),
      P.RecentCount]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowColorPickerPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kategorie-Farben', 'ExColorPickerCategories',
    'Einstellungen f{ue}r Termin-Kategorien: drei Picker mit einem gemeinsamen <b>OnChange</b> '
    + '(<b>Tag</b> = Kategorie), <b>Style</b> mit "Keine" (cbIncludeNone) und eine gemeinsame Liste '
    + '<b>RecentColors</b>. Probieren Sie: bei "Kunde" eine Farbe w{ae}hlen, dann "Intern" '
    + '{oe}ffnen {-} die Farbe steht dort unter "Zuletzt benutzt". "Keine" zeigt die Vorschau nur '
    + 'als Rahmen.');
  FCategories := TCategoryColors.CreateSettings(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Listenmarkierung', 'ExColorPickerHighlight',
    'Markierung offener und gemahnter Rechnungen: <b>ShowHex</b> zeigt den Hexwert, "Standard" '
    + '(cbIncludeDefault mit <b>DefaultColorColor</b>) hei{ss}t keine Markierung, '
    + '<b>ValidationState</b> meldet gleiche Farben. Probieren Sie: bei "Gemahnte Rechnungen" '
    + 'eine Farbe w{ae}hlen und Speichern, dann eine andere w{ae}hlen und Verwerfen. W{ae}hlen Sie '
    + 'f{ue}r beide dieselbe Farbe, wird das Feld rot und Speichern gesperrt.');
  FHighlight := THighlightSettings.CreateSettings(Own, V.Live, DemoStyles);
end;

procedure TDemoShowColorPickerPage.SelfTest(Check: TDemoCheck);
const
  LightRed = $00C0C0FF;
var
  P: TPPGColorPicker;
  Before: string;
begin
  inherited SelfTest(Check);
  // Buehne: Auswahl wie durch den Anwender erscheint mit Farbname im Protokoll,
  // Selected aus Code nicht
  ResetSubject;
  P := TPPGColorPicker(Subject);
  P.SelectColor(clRed);
  Check('TPPGColorPicker: Auswahl auf der B' + #$00FC + 'hne meldet OnChange mit Farbname',
    (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('Red', EventList.Items[0]) > 0));
  Before := EventList.Items[0];
  P.Selected := clBlue;
  Check('TPPGColorPicker: Selected aus Code l' + #$00F6 + 'st kein Ereignis aus',
    (EventList.Items.Count > 0) and (EventList.Items[0] = Before));
  Check('TPPGColorPicker: Auswahl landet in RecentColors',
    (P.RecentCount = 1) and (P.RecentColor(0) = clRed));
  ResetSubject;

  // Praxisbeispiel 1: Kategorie-Farben
  FCategories.Pickers[0].SelectColor(clRed);
  Check('Beispiel Kategorien: OnChange f' + #$00E4 + 'rbt die Vorschau von "Kunde"',
    (FCategories.Chips[0].Brush.Style = bsSolid) and (FCategories.Chips[0].Brush.Color = clRed));
  Check('Beispiel Kategorien: Status nennt Kategorie und Farbe',
    Pos('Kunde: Red', FCategories.Status.Caption) = 1);
  Check('Beispiel Kategorien: "Zuletzt benutzt" gilt f' + #$00FC + 'r alle Kategorien',
    (FCategories.Pickers[1].RecentCount > 0) and (FCategories.Pickers[1].RecentColor(0) = clRed) and
    (FCategories.Pickers[2].RecentColor(0) = clRed));
  FCategories.Pickers[0].SelectColor(clNone);
  Check('Beispiel Kategorien: "Keine" zeigt nur einen Rahmen',
    FCategories.Chips[0].Brush.Style = bsClear);
  FCategories.Pickers[1].Selected := clYellow;
  Check('Beispiel Kategorien: Selected aus Code ' + #$00E4 + 'ndert die Vorschau nicht (kein OnChange)',
    FCategories.Chips[1].Brush.Color = clGreen);
  FCategories.Pickers[0].SelectColor(clBlue);
  FCategories.Pickers[1].Selected := clGreen;

  // Praxisbeispiel 2: Listenmarkierung
  Check('Beispiel Markierung: Start ohne Fehler, Speichern frei, Zeile hellrot',
    (FHighlight.DunnedColor.ValidationState = pvsNone) and FHighlight.SaveButton.Enabled and
    (FHighlight.DunnedRow.Color = LightRed));
  Check('Beispiel Markierung: "Standard" zeigt die Listenfarbe (DefaultColorColor)',
    FHighlight.OpenRow.Color = clWindow);
  FHighlight.OpenColor.SelectColor(LightRed);
  Check('Beispiel Markierung: gleiche Farben melden pvsError und sperren Speichern',
    (FHighlight.DunnedColor.ValidationState = pvsError) and not FHighlight.SaveButton.Enabled);
  FHighlight.OpenColor.SelectColor(clDefault);
  Check('Beispiel Markierung: andere Farbe hebt den Fehler auf',
    (FHighlight.DunnedColor.ValidationState = pvsNone) and FHighlight.SaveButton.Enabled);
  FHighlight.DunnedColor.SelectColor(clYellow);
  FHighlight.SaveButton.Click;
  Check('Beispiel Markierung: Speichern schreibt Farbe und "zuletzt benutzt"',
    (FHighlight.Store.Values['Gemahnt'] = ColorToString(clYellow)) and
    (Pos('#FFFF00', FHighlight.Store.Values['Zuletzt']) > 0));
  FHighlight.DunnedColor.SelectColor(clLime);
  FHighlight.DiscardButton.Click;
  Check('Beispiel Markierung: Verwerfen stellt die gespeicherte Farbe wieder her',
    (FHighlight.DunnedColor.Selected = clYellow) and (FHighlight.DunnedRow.Color = clYellow));
  Check('Beispiel Markierung: ShowHex zeigt den Hexwert',
    FHighlight.DunnedColor.ColorName(clYellow) = '#FFFF00');
  FHighlight.DunnedColor.SelectColor(LightRed);
  FHighlight.SaveButton.Click;
end;

initialization
  RegisterShowcasePage('TPPGColorPicker', TDemoShowColorPickerPage);

end.
