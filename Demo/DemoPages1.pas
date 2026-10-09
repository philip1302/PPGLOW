unit DemoPages1;

{ Demo-Seiten "Start", "Buttons & Befehle", "Auswahl & Regler", "Formular".
  Jede Karte zeigt ein kleines Szenario mit sichtbarem Ergebnis. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Math, System.UITypes, Vcl.Graphics,
  Vcl.Controls, Vcl.Menus, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Forms, Vcl.ExtCtrls,
  PPG.Types, PPG.Consts, PPG.Theme, PPG.Render.Registry, PPG.Controls.Base,
  PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch, PPG.ProgressBar,
  PPG.TrackBar, PPG.Panel, PPG.RadioGroup, PPG.Labels, PPG.Controls.Field, PPG.Edit, PPG.Memo,
  PPG.NumberFormat, PPG.NumberEdit, PPG.MaskEdit, PPG.PasswordEdit, PPG.FileEdit,
  PPG.ColorPicker, PPG.CheckComboBox, PPG.ColumnComboBox, PPG.TagEdit,
  PPG.Validator, PPG.BusyOverlay, PPG.PageControl,
  PPG.SpinEdit, PPG.ComboBox, PPG.Feedback, PPG.Rating, PPG.ToolBar,
  PPG.DatePicker, PPG.TimePicker, PPG.ListBox, PPG.Items, PPG.Notifications,
  DemoKit;

type
  TDemoStartPage = class(TDemoPage)
  private
    FDarkSwitch: TPPGToggleSwitch;
    FPresetCombo: TPPGComboBox;
    FSyncing: Boolean;
    procedure TileClick(Sender: TObject);
    procedure TourClick(Sender: TObject);
    procedure DarkChange(Sender: TObject);
    procedure PresetChange(Sender: TObject);
    procedure AddTile(Col, Row: Integer; Icon: Word; const ATitle, AText: string; APage: Integer);
  protected
    procedure Build; override;
  public
    procedure AppearanceChanged; override;
  end;

  TDemoButtonsPage = class(TDemoPage)
  private
    FClickResult: TPPGLabel;
    FMenuResult: TPPGLabel;
    FToggleResult: TPPGLabel;
    FDialogResult: TPPGLabel;
    FSample: TPPGLabel;
    FAlign: array[0..2] of TPPGButton;
    FBold: TPPGButton;
    FItalic: TPPGButton;
    FMemo: TPPGMemo;
    FLastClick: string;
    FSaveBtn: TPPGButton;
    FClickCount: Integer;
    procedure ButtonClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure MenuItemClick(Sender: TObject);
    procedure ToggleClick(Sender: TObject);
    procedure DialogOk(Sender: TObject);
    procedure DialogCancel(Sender: TObject);
    procedure ToolClick(Sender: TObject; Item: TPPGToolItem);
    function NewMenu(const Captions: array of string): TPopupMenu;
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoChoicePage = class(TDemoPage)
  private
    FMaster: TPPGCheckBox;
    FChecks: array[0..3] of TPPGCheckBox;
    FCheckResult: TPPGLabel;
    FRadios: array[0..2] of TPPGRadioButton;
    FRadioResult: TPPGLabel;
    FWifi, FBluetooth, FAirplane: TPPGToggleSwitch;
    FWifiBefore, FBluetoothBefore: Boolean;
    FSwitchResult: TPPGLabel;
    FRating: TPPGRating;
    FRatingResult: TPPGLabel;
    FVolume: TPPGTrackBar;
    FQuality: TPPGTrackBar;
    FPrice: TPPGTrackBar;
    FPriceValue: TPPGLabel;
    FVolumeBar: TPPGProgressBar;
    FVolumeRing: TPPGProgressRing;
    FVolumeValue: TPPGLabel;
    FQualityValue: TPPGLabel;
    FRangeResult: TPPGLabel;
    FPeriod: TPPGRadioGroup;
    FDays: TPPGCheckGroup;
    FShipping: TPPGRadioGroup;
    FGroupResult: TPPGLabel;
    FUpdating: Boolean;
    procedure MasterClick(Sender: TObject);
    procedure ChildClick(Sender: TObject);
    procedure UpdateMaster;
    procedure RadioChange(Sender: TObject);
    procedure SwitchChange(Sender: TObject);
    procedure AirplaneChange(Sender: TObject);
    procedure RatingChange(Sender: TObject);
    procedure RangeChange(Sender: TObject);
    procedure GroupsChange(Sender: TObject);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoContact = record
    FirstName, LastName, Mail, Phone, Salutation, Country: string;
    Licenses: Integer;
  end;

  TDemoFormPage = class(TDemoPage)
  private
    FFirst, FLast, FMail, FPhone, FPassword: TPPGEdit;
    FSalutation, FCountry: TPPGComboBox;
    FBirth: TPPGDatePicker;
    FCallback: TPPGTimePicker;
    FLicenses: TPPGSpinEdit;
    FNotes: TPPGMemo;
    FTerms: TPPGCheckBox;
    FStrength: TPPGProgressBar;
    FStrengthText: TPPGLabel;
    FInfo: TPPGInfoBar;
    FList: TPPGListBox;
    FListResult: TPPGLabel;
    FContacts: array of TDemoContact;
    FSaveBtn: TPPGButton;
    FPlz: TPPGMaskEdit;
    FAmount: TPPGNumberEdit;
    FDiscount: TPPGNumberEdit;
    FPin: TPPGPasswordEdit;
    FFile: TPPGFileEdit;
    FColor: TPPGColorPicker;
    FCats: TPPGCheckComboBox;
    FCustomer: TPPGColumnComboBox;
    FTags: TPPGTagEdit;
    FSpecialResult: TPPGLabel;
    // Phase 19: Pruefung per Validator statt Handarbeit
    FValidator: TPPGValidator;
    // Bestellung: zwei Reiter, Sammelleiste, Arbeit im Hintergrund
    FOrderPages: TPPGPageControl;
    FOrderShip: TPPGTabSheet;
    FOrderPay: TPPGTabSheet;
    FZip: TPPGEdit;
    FShipFrom: TPPGDatePicker;
    FShipTo: TPPGDatePicker;
    FIban: TPPGEdit;
    FOrderAmount: TPPGNumberEdit;
    FOrderBtn: TPPGButton;
    FOrderBar: TPPGInfoBar;
    FOrderResult: TPPGLabel;
    FOrderValidator: TPPGValidator;
    FOrderBusy: TPPGBusyOverlay;
    FOrderStepMs: Integer;
    procedure BuildSpecialFields;
    procedure BuildOrder;
    procedure OrderClick(Sender: TObject);
    procedure SpecialChange(Sender: TObject);
    function Field(AParent: TWinControl; Col, Row: Integer; const ACaption: string): TPoint;
    procedure PasswordChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure ListClick(Sender: TObject);
    procedure AddContact(const C: TDemoContact);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

const
  ColW = 484;                      // halbe Inhaltsbreite
  FullW = 2 * ColW + CardGap;      // volle Inhaltsbreite
  Col2X = PageX + ColW + CardGap;

  Countries = 'Belgien,D{ae}nemark,Deutschland,Estland,Finnland,Frankreich,Griechenland,' +
    'Irland,Italien,Kroatien,Lettland,Litauen,Luxemburg,Malta,Niederlande,' +
    '{Oe}sterreich,Polen,Portugal,Rum{ae}nien,Schweden,Schweiz,Slowakei,Slowenien,' +
    'Spanien,Tschechien,Ungarn,Zypern';

{ TDemoStartPage }

procedure TDemoStartPage.Build;
var
  Hero, Tile: TPPGPanel;
  B: TPPGButton;
  Ring: TPPGProgressRing;
  R: TPPGRating;
  Sw: TPPGToggleSwitch;
  Badge: TPPGBadge;
  I, X: Integer;
const
  Kpi: array[0..3, 0..2] of string = (
    ('35', 'Controls', 'Von Button bis Grid {-} alle mit gleicher Optik und Bedienlogik'),
    ('3', 'Presets', 'Classic, ModernFlat und Fluent11 {-} umschaltbar zur Laufzeit'),
    ('523', 'Tests', 'Automatische DUnit- und Sichttests sichern jede Funktion ab'),
    ('XE2{-}13', 'Delphi', 'Win32 und Win64, DPI-bewusst, barrierefrei'));
  KpiIcons: array[0..3] of Word = ($E8FD, $E771, $E9D9, $E7F4);
begin
  NewPageHeader(Own, Sheet, 'Willkommen', 'Moderne VCL-Controls im Windows-11-Stil. ' +
    'Jede Seite zeigt ein Alltagsszenario {-} probieren Sie alles direkt aus.');

  // Hero: Titel, Botschaft, Schnellzugriff auf Theme und Preset
  Hero := NewCard(Own, Sheet, PageX, PageContentTop, FullW, 190, '', '');
  NewLabel(Own, Hero, 28, 20, 0, 'PPGlow', tkDisplay);
  NewLabel(Own, Hero, 30, 78, 520, 'Eine Komponentensuite, ein Look: Glow-Buttons, Formulare, ' +
    'Listen, B{ae}ume, Tabellen, Kalender und Benachrichtigungen {-} hell, dunkel und ' +
    'mit Hochkontrast.', tkBody);
  B := NewButton(Own, Hero, 30, 136, 150, 'Tour starten', TourClick, True);
  B.Tag := 1;
  B := NewButton(Own, Hero, 192, 136, 150, 'Darstellung', TileClick);
  B.HelpContext := 100 + 10; // Seite Darstellung
  B.Tag := 1;

  NewLabel(Own, Hero, 620, 24, 0, 'Schnell umschalten', tkStrong);
  FDarkSwitch := TPPGToggleSwitch.Create(Own);
  FDarkSwitch.Parent := Hero;
  FDarkSwitch.SetBounds(620, 54, 200, CtlH);
  FDarkSwitch.Caption := L('Dunkles Design');
  FDarkSwitch.OnChange := DarkChange;
  NewLabel(Own, Hero, 620, 98, 0, 'Preset', tkSecondary);
  FPresetCombo := TPPGComboBox.Create(Own);
  FPresetCombo.Parent := Hero;
  FPresetCombo.Style := csDropDownList;
  FPresetCombo.SetBounds(620, 120, 180, CtlH);
  TPPGRendererRegistry.GetNames(FPresetCombo.Items);
  FPresetCombo.OnChange := PresetChange;

  // Kleine Live-Vorschau rechts
  Ring := TPPGProgressRing.Create(Own);
  Ring.Parent := Hero;
  Ring.SetBounds(860, 30, 40, 40);
  R := TPPGRating.Create(Own);
  R.Parent := Hero;
  R.Left := 830;
  R.Top := 90;
  R.AllowHalf := True;
  R.Value := 4.5;
  R.StarSize := 16;
  Sw := TPPGToggleSwitch.Create(Own);
  Sw.Parent := Hero;
  Sw.SetBounds(842, 124, 70, CtlH);
  Sw.Checked := True;
  Badge := TPPGBadge.Create(Own);
  Badge.Parent := Hero;
  Badge.Left := 912;
  Badge.Top := 40;
  Badge.Value := 3;

  // Kennzahlen
  for I := 0 to 3 do
  begin
    X := PageX + I * ((FullW - 3 * CardGap) div 4 + CardGap);
    Tile := NewCard(Own, Sheet, X, 310, (FullW - 3 * CardGap) div 4, 118, '', '');
    NewIcon(Own, Tile, 18, 18, KpiIcons[I]);
    NewLabel(Own, Tile, 48, 8, 0, Kpi[I, 0], tkValue);
    NewLabel(Own, Tile, 18, 50, 0, Kpi[I, 1], tkStrong);
    NewLabel(Own, Tile, 18, 72, Tile.Width - 36, Kpi[I, 2], tkCaption);
  end;

  NewLabel(Own, Sheet, PageX, 448, 0, 'Entdecken', tkSubtitle);
  AddTile(0, 0, $E70F, 'Formular mit Pr{ue}fung', 'Pflichtfelder, E-Mail-Pr{ue}fung beim Tippen, ' +
    'Kennwortst{ae}rke und Speichern in eine Liste.', 3);
  AddTile(1, 0, $E8B7, 'Explorer', 'Baum, Breadcrumb und Splitter arbeiten zusammen ' +
    '{-} wie im Datei-Explorer.', 5);
  AddTile(2, 0, $E80A, 'Tabelle', 'Sortieren, Filterzeile, Editoren in Zellen und ' +
    'Summen, die sich sofort aktualisieren.', 6);
  AddTile(0, 1, $E787, 'Termine', 'Zeitraum im Kalender w{ae}hlen und den Preis ' +
    'f{ue}r die Buchung sehen.', 7);
  AddTile(1, 1, $EA8F, 'R{ue}ckmeldung', 'Hinweisleisten, Toasts und ein Download mit ' +
    'Fortschritt, Pause und Abbruch.', 9);
  AddTile(2, 1, $E771, 'Darstellung', 'Presets, Hell und Dunkel, VCL-Styles und ' +
    'GDI-Fallback live umschalten.', 10);
  AppearanceChanged;
end;

procedure TDemoStartPage.AddTile(Col, Row: Integer; Icon: Word; const ATitle, AText: string;
  APage: Integer);
var
  W: Integer;
  Tile: TPPGPanel;
  Lbl: TPPGLabel;
  I: Integer;
begin
  W := (FullW - 2 * CardGap) div 3;
  Tile := NewCard(Own, Sheet, PageX + Col * (W + CardGap), 488 + Row * (124 + CardGap), W, 124, '', '');
  NewIcon(Own, Tile, 18, 18, Icon);
  NewLabel(Own, Tile, 52, 18, 0, ATitle, tkCardTitle);
  NewLabel(Own, Tile, 52, 44, W - 72, AText, tkSecondary);
  Lbl := NewLabel(Own, Tile, W - 90, 96, 0, '{Oe}ffnen {>}', tkStrong);
  DemoStyler.AddAccentLabel(Lbl);
  // Die ganze Kachel ist klickbar
  Tile.HelpContext := 100 + APage;
  Tile.Cursor := crHandPoint;
  Tile.OnClick := TileClick;
  for I := 0 to Tile.ControlCount - 1 do
    if Tile.Controls[I] is TPPGLabel then
    begin
      TPPGLabel(Tile.Controls[I]).Cursor := crHandPoint;
      TPPGLabel(Tile.Controls[I]).OnClick := TileClick;
    end;
end;

procedure TDemoStartPage.TileClick(Sender: TObject);
var
  C: TControl;
begin
  C := TControl(Sender);
  if (C.HelpContext < 100) and (C.Parent <> nil) then
    C := C.Parent;
  if C.HelpContext >= 100 then
    Host.GoToPage(C.HelpContext - 100);
end;

procedure TDemoStartPage.TourClick(Sender: TObject);
begin
  Host.Log('Start', 'Tour gestartet');
  Host.Notifier.Show(L('Willkommen zur Tour'), L('Links in der Navigation finden Sie alle ' +
    'Bereiche. Jede Karte zeigt unten ihr Ergebnis.'), psInformational);
  Host.GoToPage(1);
end;

procedure TDemoStartPage.DarkChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  if FDarkSwitch.Checked then
    TPPGTheme.Mode := tmDark
  else
    TPPGTheme.Mode := tmLight;
  Host.Log('Darstellung', 'Dunkles Design: ' + BoolToStr(FDarkSwitch.Checked, True));
end;

procedure TDemoStartPage.PresetChange(Sender: TObject);
begin
  if FSyncing or (FPresetCombo.ItemIndex < 0) then
    Exit;
  Host.ApplyPreset(FPresetCombo.Items[FPresetCombo.ItemIndex]);
  Host.Log('Darstellung', 'Preset: ' + Host.CurrentPreset);
end;

procedure TDemoStartPage.AppearanceChanged;
begin
  if FDarkSwitch = nil then
    Exit;
  FSyncing := True;
  try
    FDarkSwitch.Checked := TPPGTheme.IsDark;
    FPresetCombo.ItemIndex := FPresetCombo.Items.IndexOf(Host.CurrentPreset);
  finally
    FSyncing := False;
  end;
end;

{ TDemoButtonsPage }

function TDemoButtonsPage.NewMenu(const Captions: array of string): TPopupMenu;
var
  I: Integer;
  Item: TMenuItem;
begin
  Result := TPopupMenu.Create(Own);
  for I := 0 to High(Captions) do
  begin
    Item := TMenuItem.Create(Result);
    Item.Caption := L(Captions[I]);
    Item.OnClick := MenuItemClick;
    Result.Items.Add(Item);
  end;
end;

procedure TDemoButtonsPage.Build;
var
  Card: TPPGPanel;
  B: TPPGButton;
  E: TPPGEdit;
  TB: TPPGToolBar;
  Y, I: Integer;
const
  AlignCaptions: array[0..2] of string = ('Links', 'Mitte', 'Rechts');
begin
  NewPageHeader(Own, Sheet, 'Buttons & Befehle', 'Schaltfl{ae}chen mit Bild, Split- und ' +
    'Men{ue}-Buttons, Umschaltgruppen, Default/Cancel und eine ToolBar mit {Ue}berlauf.');

  // Schaltflaechen
  Card := NewCard(Own, Sheet, PageX, PageContentTop, ColW, 206, 'Schaltfl{ae}chen',
    'Klicken Sie die Buttons {-} der Z{ae}hler zeigt, was ankommt.');
  Y := Card.Tag;
  B := NewButton(Own, Card, CardPad, Y, 130, 'Speichern', ButtonClick, True);
  FSaveBtn := B;
  B.Images := Host.Images;
  B.ImageIndex := -1;
  B.Tag := 1;
  B := NewButton(Own, Card, CardPad + 142, Y, 130, 'Abbrechen', ButtonClick);
  B.Tag := 1;
  B := NewButton(Own, Card, CardPad + 284, Y, 130, 'L{oe}schen', ButtonClick);
  B.Images := Host.Images;
  B.ImageIndex := 6;
  B := NewButton(Own, Card, CardPad, Y + 44, 130, 'Deaktiviert', ButtonClick);
  B.Images := Host.Images;
  B.ImageIndex := 0;
  B.Enabled := False;
  B := NewButton(Own, Card, CardPad + 142, Y + 44, 272, 'Langer Text, der sauber umbricht',
    ButtonClick);
  B.WordWrap := True;
  FClickResult := NewResult(Own, Card, 'Zuletzt geklickt');

  // Split- und Menue-Button
  Card := NewCard(Own, Sheet, Col2X, PageContentTop, ColW, 206, 'Split- und Men{ue}-Button',
    'Der Hauptteil f{ue}hrt die Standardaktion aus, der Pfeil {oe}ffnet weitere Optionen.');
  Y := Card.Tag;
  B := NewButton(Own, Card, CardPad, Y, 170, 'Exportieren', ExportClick);
  B.Style := pbsSplitButton;
  B.Images := Host.Images;
  B.ImageIndex := 2;
  B.DropDownMenu := NewMenu(['Als PDF exportieren', 'Als CSV exportieren', 'Drucken{...}']);
  B.Tag := 1;
  B := NewButton(Own, Card, CardPad + 186, Y, 150, 'Weitere', nil);
  B.DropDownMenu := NewMenu(['Umbenennen', 'Duplizieren', 'In Papierkorb verschieben']);
  FMenuResult := NewResult(Own, Card, 'Aktion');

  // Umschalt-Buttons
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 206 + CardGap, ColW, 206,
    'Umschalt-Buttons', 'Gruppe (GroupIndex) f{ue}r die Ausrichtung, einzeln umschaltbar f{ue}r ' +
    'Fett und Kursiv.');
  Y := Card.Tag;
  for I := 0 to 2 do
  begin
    FAlign[I] := NewButton(Own, Card, CardPad + I * 84, Y, 80, AlignCaptions[I], ToggleClick);
    FAlign[I].GroupIndex := 1;
  end;
  FAlign[0].Down := True;
  FAlign[0].Tag := 1;
  FBold := NewButton(Own, Card, CardPad + 268, Y, 80, 'Fett', ToggleClick);
  FBold.GroupIndex := 2;
  FBold.AllowAllUp := True;
  FItalic := NewButton(Own, Card, CardPad + 352, Y, 80, 'Kursiv', ToggleClick);
  FItalic.GroupIndex := 3;
  FItalic.AllowAllUp := True;
  FSample := NewLabel(Own, Card, CardPad, Y + 48, ColW - 2 * CardPad, 'Beispieltext', tkSubtitle);
  FSample.AutoSize := False;
  FSample.Height := 34;
  FToggleResult := NewResult(Own, Card, 'Format');
  ToggleClick(nil);

  // Default und Cancel
  Card := NewCard(Own, Sheet, Col2X, PageContentTop + 206 + CardGap, ColW, 206,
    'Enter und Esc', 'In das Feld klicken und Enter oder Esc dr{ue}cken: Default- und ' +
    'Cancel-Button reagieren wie bei TButton.');
  Y := Card.Tag;
  E := TPPGEdit.Create(Own);
  E.Parent := Card;
  E.SetBounds(CardPad, Y, 210, CtlH);
  E.TextHint := L('Name eingeben{...}');
  B := NewButton(Own, Card, CardPad + 222, Y, 100, 'OK', DialogOk, True);
  B.Default := True;
  B := NewButton(Own, Card, CardPad + 330, Y, 100, 'Abbrechen', DialogCancel);
  B.Cancel := True;
  FDialogResult := NewResult(Own, Card, 'Ausgel{oe}st');

  // ToolBar mit Editor
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 2 * (206 + CardGap), FullW, 190, 'ToolBar',
    'Befehle, Umschalter und eine Gruppe. Wird das Fenster schmal, wandern Eintr{ae}ge ins ' +
    '{Ue}berlauf-Men{ue}.');
  Y := Card.Tag - 4;
  TB := TPPGToolBar.Create(Own);
  TB.Parent := Card;
  TB.Align := alNone;
  TB.SetBounds(CardPad - 4, Y, FullW - 2 * CardPad + 8, 40);
  TB.Anchors := [akLeft, akTop, akRight];
  TB.Items.AddButton('Neu', $E710);
  TB.Items.AddButton(L('{Oe}ffnen'), $E8E5);
  TB.Items.AddButton('Speichern', $E74E);
  TB.Items.AddSeparator;
  TB.Items.AddButton('Kopieren', $E8C8);
  TB.Items.AddButton(L('Einf{ue}gen'), $E77F);
  TB.Items.AddSeparator;
  TB.Items.AddCheck('Fett', $E8DD);
  TB.Items.AddCheck('Kursiv', $E8DB);
  TB.Items.AddCheck('Unterstrichen', $E8DC);
  TB.Items.AddSeparator;
  TB.Items.AddCheck('Links', $E8E4, 1).Down := True;
  TB.Items.AddCheck('Zentriert', $E8E3, 1);
  TB.Items.AddCheck('Rechts', $E8E2, 1);
  TB.OnItemClick := ToolClick;
  FMemo := TPPGMemo.Create(Own);
  FMemo.Parent := Card;
  FMemo.SetBounds(CardPad, Y + 46, FullW - 2 * CardPad, 66);
  FMemo.Lines.Text := L('Die ToolBar formatiert diesen Text. Probieren Sie Fett, Kursiv und ' +
    'die Ausrichtung {-} oder Kopieren und Einf{ue}gen.');
end;

procedure TDemoButtonsPage.ButtonClick(Sender: TObject);
var
  S: string;
begin
  S := StripHotkey(TPPGButton(Sender).Caption);
  if S = FLastClick then
    Inc(FClickCount)
  else
  begin
    FLastClick := S;
    FClickCount := 1;
  end;
  SetResult(FClickResult, Format('%s (%d{x})', [S, FClickCount]));
  Host.Log('Button', S);
end;

procedure TDemoButtonsPage.ExportClick(Sender: TObject);
begin
  SetResult(FMenuResult, 'Standardaktion {-} als PDF exportiert');
  Host.Log('Split-Button', 'Hauptteil: als PDF exportiert');
end;

procedure TDemoButtonsPage.MenuItemClick(Sender: TObject);
var
  S: string;
begin
  S := StripHotkey(TMenuItem(Sender).Caption);
  SetResult(FMenuResult, S);
  Host.Log('Men{ue}', S);
end;

procedure TDemoButtonsPage.ToggleClick(Sender: TObject);
const
  Aligns: array[0..2] of TAlignment = (taLeftJustify, taCenter, taRightJustify);
  Names: array[0..2] of string = ('Links', 'Mitte', 'Rechts');
var
  I, Idx: Integer;
  St: TFontStyles;
  S: string;
begin
  Idx := 0;
  for I := 0 to 2 do
    if FAlign[I].Down then
      Idx := I;
  FSample.Alignment := Aligns[Idx];
  St := [];
  S := Names[Idx];
  if FBold.Down then
  begin
    Include(St, fsBold);
    S := S + ' {.} Fett';
  end;
  if FItalic.Down then
  begin
    Include(St, fsItalic);
    S := S + ' {.} Kursiv';
  end;
  FSample.Font.Style := St;
  SetResult(FToggleResult, S);
  if Sender <> nil then
    Host.Log('Umschalt-Button', L(S));
end;

procedure TDemoButtonsPage.DialogOk(Sender: TObject);
begin
  SetResult(FDialogResult, 'OK (Enter oder Klick)');
  Host.Log('Default-Button', 'OK');
end;

procedure TDemoButtonsPage.DialogCancel(Sender: TObject);
begin
  SetResult(FDialogResult, 'Abbrechen (Esc oder Klick)');
  Host.Log('Cancel-Button', 'Abbrechen');
end;

procedure TDemoButtonsPage.ToolClick(Sender: TObject; Item: TPPGToolItem);
var
  St: TFontStyles;
  TB: TPPGToolBar;
  I: Integer;
begin
  TB := TPPGToolBar(Sender);
  St := [];
  for I := 0 to TB.Items.Count - 1 do
    if TB.Items[I].Down then
      case TB.Items[I].IconChar of
        $E8DD: Include(St, fsBold);
        $E8DB: Include(St, fsItalic);
        $E8DC: Include(St, fsUnderline);
        $E8E4: FMemo.Alignment := taLeftJustify;
        $E8E3: FMemo.Alignment := taCenter;
        $E8E2: FMemo.Alignment := taRightJustify;
      end;
  FMemo.Font.Style := St;
  case Item.IconChar of
    $E710: FMemo.Lines.Clear;
    $E8C8:
      begin
        FMemo.SelectAll;
        FMemo.CopyToClipboard;
      end;
    $E77F: FMemo.PasteFromClipboard;
  end;
  Host.Log('ToolBar', Item.Caption);
end;

{ TDemoChoicePage }

procedure TDemoChoicePage.Build;
var
  Card: TPPGPanel;
  Y, I: Integer;
  R: TPPGRating;
const
  ChildCaptions: array[0..3] of string = ('Neue Nachrichten', 'Erw{ae}hnungen',
    'Software-Updates', 'Newsletter');
  RadioCaptions: array[0..2] of string = ('Standard', 'Express', 'Abholung im Laden');
  RadioDetails: array[0..2] of string = ('4,90 {EUR} {.} 3{-}5 Werktage',
    '9,90 {EUR} {.} Lieferung morgen', 'kostenlos {.} ab heute 16 Uhr');
begin
  NewPageHeader(Own, Sheet, 'Auswahl & Regler', 'Kontrollk{ae}stchen mit Dreifachzustand, ' +
    'Optionsfelder, Schalter, Bewertung, Schieberegler und Fortschritt {-} jeweils verkn{ue}pft.');

  // Kontrollkaestchen mit "Alle"
  Card := NewCard(Own, Sheet, PageX, PageContentTop, ColW, 252, 'Kontrollk{ae}stchen',
    'Das obere K{ae}stchen fasst die anderen zusammen (gemischt = teilweise).');
  Y := Card.Tag;
  FMaster := TPPGCheckBox.Create(Own);
  FMaster.Parent := Card;
  FMaster.SetBounds(CardPad, Y, 300, 28);
  FMaster.Caption := L('Alle Benachrichtigungen');
  FMaster.OnClick := MasterClick;
  for I := 0 to 3 do
  begin
    FChecks[I] := TPPGCheckBox.Create(Own);
    FChecks[I].Parent := Card;
    FChecks[I].SetBounds(CardPad + 28, Y + 30 + I * 28, 300, 28);
    FChecks[I].Caption := L(ChildCaptions[I]);
    FChecks[I].Checked := I < 2;
    FChecks[I].OnClick := ChildClick;
  end;
  FCheckResult := NewResult(Own, Card, 'Aktiv');
  UpdateMaster;

  // Optionsfelder
  Card := NewCard(Own, Sheet, Col2X, PageContentTop, ColW, 252, 'Optionsfelder',
    'Versandart w{ae}hlen {-} der Preis folgt der Auswahl.');
  Y := Card.Tag;
  for I := 0 to 2 do
  begin
    FRadios[I] := TPPGRadioButton.Create(Own);
    FRadios[I].Parent := Card;
    FRadios[I].SetBounds(CardPad, Y + I * 46, 260, 26);
    FRadios[I].Caption := L(RadioCaptions[I]);
    FRadios[I].GroupIndex := 1;
    FRadios[I].Tag := I;
    FRadios[I].OnChange := RadioChange;
    NewLabel(Own, Card, CardPad + 28, Y + I * 46 + 24, 0, RadioDetails[I], tkCaption);
  end;
  FRadioResult := NewResult(Own, Card, 'Versand');
  FRadios[0].Checked := True;

  // Schalter
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 252 + CardGap, ColW, 196, 'Schalter',
    'Der Flugmodus schaltet Funk aus und sperrt die anderen Schalter.');
  Y := Card.Tag;
  FWifi := TPPGToggleSwitch.Create(Own);
  FWifi.Parent := Card;
  FWifi.SetBounds(CardPad, Y, 200, CtlH);
  FWifi.Caption := 'WLAN';
  FWifi.Checked := True;
  FWifi.OnChange := SwitchChange;
  FBluetooth := TPPGToggleSwitch.Create(Own);
  FBluetooth.Parent := Card;
  FBluetooth.SetBounds(CardPad, Y + 36, 200, CtlH);
  FBluetooth.Caption := 'Bluetooth';
  FBluetooth.OnChange := SwitchChange;
  FAirplane := TPPGToggleSwitch.Create(Own);
  FAirplane.Parent := Card;
  FAirplane.SetBounds(CardPad + 230, Y, 200, CtlH);
  FAirplane.Caption := 'Flugmodus';
  FAirplane.OnChange := AirplaneChange;
  FSwitchResult := NewResult(Own, Card, 'Status');
  SwitchChange(nil);

  // Bewertung
  Card := NewCard(Own, Sheet, Col2X, PageContentTop + 252 + CardGap, ColW, 196, 'Bewertung',
    'Halbe Sterne mit der Maus oder per Pfeiltasten. Rechts ein schreibgesch{ue}tzter ' +
    'Durchschnitt.');
  Y := Card.Tag;
  FRating := TPPGRating.Create(Own);
  FRating.Parent := Card;
  FRating.Left := CardPad;
  FRating.Top := Y;
  FRating.AllowHalf := True;
  FRating.StarSize := 24;
  FRating.Value := 3.5;
  FRating.OnChange := RatingChange;
  R := TPPGRating.Create(Own);
  R.Parent := Card;
  R.Left := CardPad + 230;
  R.Top := Y + 4;
  R.ReadOnly := True;
  R.AllowHalf := True;
  R.Value := 4.5;
  NewLabel(Own, Card, CardPad + 230, Y + 32, 0, '4,4 von 5 {.} 128 Bewertungen', tkCaption);
  FRatingResult := NewResult(Own, Card, 'Ihre Bewertung');
  RatingChange(nil);

  // Regler und Fortschritt
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 252 + 196 + 2 * CardGap, FullW, 196,
    'Schieberegler und Fortschritt', 'Lautst{ae}rke mit empfohlenem Bereich steuert Balken und ' +
    'Ring, Qualit{ae}t rastet ein, der Preis hat zwei Griffe (Tab wechselt).');
  Y := Card.Tag;
  NewLabel(Own, Card, CardPad, Y + 8, 0, 'Lautst{ae}rke', tkBody);
  FVolume := TPPGTrackBar.Create(Own);
  FVolume.Parent := Card;
  FVolume.SetBounds(CardPad + 100, Y, 300, 36);
  FVolume.Max := 100;
  FVolume.Frequency := 10;
  FVolume.TickMarks := tmBottomRight;
  FVolume.Position := 65;
  FVolume.SelStart := 40;
  FVolume.SelEnd := 80;
  FVolume.OnChange := RangeChange;
  FVolumeValue := NewLabel(Own, Card, CardPad + 410, Y + 8, 0, '', tkStrong);
  FVolumeBar := TPPGProgressBar.Create(Own);
  FVolumeBar.Parent := Card;
  FVolumeBar.SetBounds(CardPad + 480, Y + 14, 330, 8);
  FVolumeRing := TPPGProgressRing.Create(Own);
  FVolumeRing.Parent := Card;
  FVolumeRing.SetBounds(CardPad + 836, Y, 36, 36);
  FVolumeRing.Indeterminate := False;
  NewLabel(Own, Card, CardPad, Y + 56, 0, 'Qualit{ae}t', tkBody);
  FQuality := TPPGTrackBar.Create(Own);
  FQuality.Parent := Card;
  FQuality.SetBounds(CardPad + 100, Y + 48, 300, 40);
  FQuality.Min := 1;
  FQuality.Max := 5;
  FQuality.TickMarks := tmBottomRight;
  FQuality.Position := 4;
  FQuality.OnChange := RangeChange;
  FQualityValue := NewLabel(Own, Card, CardPad + 410, Y + 56, 0, '', tkStrong);
  // Bereichsregler (Phase 20d): Preisfilter von/bis
  NewLabel(Own, Card, CardPad + 520, Y + 56, 0, 'Preis', tkBody);
  FPrice := TPPGTrackBar.Create(Own);
  FPrice.Parent := Card;
  FPrice.SetBounds(CardPad + 570, Y + 48, 230, 40);
  FPrice.Max := 500;
  FPrice.Frequency := 50;
  FPrice.LineSize := 10;
  FPrice.PageSize := 50;
  FPrice.RangeMode := True;
  FPrice.Position := 50;
  FPrice.PositionEnd := 250;
  FPrice.OnChange := RangeChange;
  FPriceValue := NewLabel(Own, Card, CardPad + 810, Y + 56, 0, '', tkStrong);
  FRangeResult := NewResult(Own, Card, 'Einstellung');
  RangeChange(nil);

  // Auswahlgruppen (Phase 18): Segmente, Liste mit Spalten nach Breite, Kacheln
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 252 + 196 + 196 + 3 * CardGap, FullW, 330,
    'Auswahlgruppen', 'RadioGroup und CheckGroup als Segment-Umschalter, als Liste (Spalten ' +
    'nach Breite) und als Kacheln mit Symbol und Beschreibung {-} DFM wie TRadioGroup.');
  Y := Card.Tag;
  FPeriod := TPPGRadioGroup.Create(Own);
  FPeriod.Parent := Card;
  FPeriod.ChoiceStyle := csSegmented;
  FPeriod.ShowFrame := False;
  FPeriod.SetBounds(CardPad, Y, 360, 36);
  FPeriod.Items.CommaText := 'Tag,Woche,Monat,Jahr';
  FPeriod.ItemIndex := 1;
  FPeriod.OnChange := GroupsChange;
  FDays := TPPGCheckGroup.Create(Own);
  FDays.Parent := Card;
  FDays.Caption := 'Liefertage';
  FDays.Columns := 0;
  FDays.SetBounds(CardPad, Y + 52, 360, 120);
  FDays.Items.CommaText := 'Mo,Di,Mi,Do,Fr,Sa,So';
  FDays.Value := 'Mo,Mi,Fr';
  FDays.ItemEnabled[6] := False;
  FDays.ItemsEx[6].Hint := L('Sonntags keine Zustellung');
  FDays.ShowHint := True;
  FDays.OnChange := GroupsChange;
  FShipping := TPPGRadioGroup.Create(Own);
  FShipping.Parent := Card;
  FShipping.ChoiceStyle := csCards;
  FShipping.ShowFrame := False;
  FShipping.Columns := 3;
  FShipping.SetBounds(CardPad + 390, Y, FullW - 2 * CardPad - 390, 172);
  for I := 0 to 2 do
  begin
    FShipping.ItemsEx.Add.Caption := L(RadioCaptions[I]);
    FShipping.ItemsEx[I].Description := L(RadioDetails[I]);
  end;
  FShipping.ItemsEx[0].Icon := $E715;
  FShipping.ItemsEx[1].Icon := $E916;
  FShipping.ItemsEx[2].Icon := $E80F;
  FShipping.ItemIndex := 0;
  FShipping.OnChange := GroupsChange;
  FGroupResult := NewResult(Own, Card, 'Auswahl');
  GroupsChange(nil);
end;

procedure TDemoChoicePage.GroupsChange(Sender: TObject);
begin
  SetResult(FGroupResult, FPeriod.Value + ' {.} ' + FDays.Value + ' {.} ' + FShipping.Value);
end;

procedure TDemoChoicePage.UpdateMaster;
var
  I, N: Integer;
begin
  N := 0;
  for I := 0 to 3 do
    if FChecks[I].Checked then
      Inc(N);
  FUpdating := True;
  try
    if N = 0 then
      FMaster.State := cbUnchecked
    else if N = 4 then
      FMaster.State := cbChecked
    else
      FMaster.State := cbGrayed;
  finally
    FUpdating := False;
  end;
  SetResult(FCheckResult, Format('%d von 4', [N]));
end;

procedure TDemoChoicePage.MasterClick(Sender: TObject);
var
  I: Integer;
begin
  if FUpdating then
    Exit;
  for I := 0 to 3 do
    FChecks[I].Checked := FMaster.Checked;
  UpdateMaster;
  Host.Log('CheckBox', 'Alle: ' + BoolToStr(FMaster.Checked, True));
end;

procedure TDemoChoicePage.ChildClick(Sender: TObject);
begin
  UpdateMaster;
  Host.Log('CheckBox', TPPGCheckBox(Sender).Caption + ' = ' +
    BoolToStr(TPPGCheckBox(Sender).Checked, True));
end;

procedure TDemoChoicePage.RadioChange(Sender: TObject);
const
  Results: array[0..2] of string = ('Standard {.} 4,90 {EUR}', 'Express {.} 9,90 {EUR}',
    'Abholung {.} kostenlos');
begin
  if not TPPGRadioButton(Sender).Checked then
    Exit;
  SetResult(FRadioResult, Results[TPPGRadioButton(Sender).Tag]);
  Host.Log('RadioButton', TPPGRadioButton(Sender).Caption);
end;

procedure TDemoChoicePage.SwitchChange(Sender: TObject);
const
  OnOff: array[Boolean] of string = ('aus', 'an');
begin
  if FUpdating then
    Exit;
  SetResult(FSwitchResult, 'WLAN ' + OnOff[FWifi.Checked] + ' {.} Bluetooth ' +
    OnOff[FBluetooth.Checked] + ' {.} Flugmodus ' + OnOff[FAirplane.Checked]);
  if Sender <> nil then
    Host.Log('ToggleSwitch', TPPGToggleSwitch(Sender).Caption + ' ' +
      OnOff[TPPGToggleSwitch(Sender).Checked]);
end;

procedure TDemoChoicePage.AirplaneChange(Sender: TObject);
begin
  FUpdating := True;
  try
    if FAirplane.Checked then
    begin
      FWifiBefore := FWifi.Checked;
      FBluetoothBefore := FBluetooth.Checked;
      FWifi.Checked := False;
      FBluetooth.Checked := False;
    end
    else
    begin
      FWifi.Checked := FWifiBefore;
      FBluetooth.Checked := FBluetoothBefore;
    end;
    FWifi.Enabled := not FAirplane.Checked;
    FBluetooth.Enabled := not FAirplane.Checked;
  finally
    FUpdating := False;
  end;
  SwitchChange(FAirplane);
end;

procedure TDemoChoicePage.RatingChange(Sender: TObject);
const
  Words: array[0..5] of string = ('keine', 'schlecht', 'mittelm{ae}{ss}ig', 'gut', 'sehr gut',
    'ausgezeichnet');
var
  S: string;
begin
  S := FormatFloat('0.#', FRating.Value) + ' von 5 {-} ' + Words[Ceil(FRating.Value)];
  SetResult(FRatingResult, S);
  if Sender <> nil then
    Host.Log('Rating', L(S));
end;

procedure TDemoChoicePage.RangeChange(Sender: TObject);
const
  Levels: array[1..5] of string = ('Niedrig', 'Mittel', 'Hoch', 'Sehr hoch', 'Maximal');
begin
  FVolumeValue.Caption := IntToStr(FVolume.Position) + ' %';
  FVolumeBar.Position := FVolume.Position;
  FVolumeRing.Value := FVolume.Position;
  // Gedaempft: unter 20 % Warnfarbe
  if FVolume.Position < 20 then
    FVolumeBar.State := pbsPaused
  else
    FVolumeBar.State := pbsNormal;
  FQualityValue.Caption := Levels[FQuality.Position];
  if FPrice <> nil then
    FPriceValue.Caption := L(Format('%d{-}%d {EUR}', [FPrice.Position, FPrice.PositionEnd]));
  SetResult(FRangeResult, Format('Lautst{ae}rke %d %% {.} Qualit{ae}t %s',
    [FVolume.Position, Levels[FQuality.Position]]));
  if (Sender = FPrice) and (FPrice <> nil) then
    Host.Log('TrackBar', L(Format('Preis %d{-}%d {EUR}', [FPrice.Position, FPrice.PositionEnd])));
  if Sender = FQuality then
    Host.Log('TrackBar', L('Qualit{ae}t: ') + Levels[FQuality.Position]);
end;

{ TDemoFormPage }

function TDemoFormPage.Field(AParent: TWinControl; Col, Row: Integer;
  const ACaption: string): TPoint;
begin
  // Raster: 2 Spalten zu 270 px, Zeilen zu 62 px; Beschriftung ueber dem Feld
  Result.X := CardPad + Col * 290;
  Result.Y := 70 + Row * 62;
  NewLabel(Own, AParent, Result.X, Result.Y, 0, ACaption, tkBody);
  Inc(Result.Y, 22);
end;

procedure TDemoFormPage.Build;
var
  Card: TPPGPanel;
  P: TPoint;
  B: TPPGButton;
  C: TDemoContact;
  FormW: Integer;
  R: TPPGValidationRule;

  function NewEdit(APos: TPoint; W: Integer; const AHint: string): TPPGEdit;
  begin
    Result := TPPGEdit.Create(Own);
    Result.Parent := Card;
    Result.SetBounds(APos.X, APos.Y, W, CtlH);
    Result.TextHint := L(AHint);
  end;

begin
  NewPageHeader(Own, Sheet, 'Formular', 'Ein echtes Eingabeformular: Pflichtfelder und Formate ' +
    'pr{ue}ft ein TPPGValidator (Regeln statt Pr{ue}fcode), Auswahllisten, Datum und Uhrzeit ' +
    '{-} Speichern legt den Kontakt rechts ab.');

  FormW := 600;
  Card := NewCard(Own, Sheet, PageX, PageContentTop, FormW, 640, 'Neuer Kontakt',
    'Mit * markierte Felder sind Pflicht.');

  P := Field(Card, 0, 0, 'Vorname *');
  FFirst := NewEdit(P, 270, 'z. B. Anna');
  Host.RegisterSpecial('fieldfocus', FFirst);
  P := Field(Card, 1, 0, 'Nachname *');
  FLast := NewEdit(P, 270, 'z. B. Schmidt');

  P := Field(Card, 0, 1, 'E-Mail *');
  FMail := NewEdit(P, 270, 'name@firma.de');
  FMail.ShowClearButton := True;
  P := Field(Card, 1, 1, 'Telefon');
  FPhone := NewEdit(P, 270, '+49 30 1234567');

  P := Field(Card, 0, 2, 'Anrede');
  FSalutation := TPPGComboBox.Create(Own);
  FSalutation.Parent := Card;
  FSalutation.Style := csDropDownList;
  FSalutation.SetBounds(P.X, P.Y, 270, CtlH);
  FSalutation.Items.Text := L('Frau'#13#10'Herr'#13#10'Divers'#13#10'Keine Angabe');
  FSalutation.ItemIndex := 3;
  Host.RegisterSpecial('dropdown', FSalutation);
  P := Field(Card, 1, 2, 'Land (Tippen erg{ae}nzt)');
  FCountry := TPPGComboBox.Create(Own);
  FCountry.Parent := Card;
  FCountry.SetBounds(P.X, P.Y, 270, CtlH);
  FCountry.Items.CommaText := L(Countries);
  FCountry.TextHint := L('Land eingeben oder w{ae}hlen{...}');

  P := Field(Card, 0, 3, 'Geburtsdatum');
  FBirth := TPPGDatePicker.Create(Own);
  FBirth.Parent := Card;
  FBirth.SetBounds(P.X, P.Y, 270, CtlH);
  FBirth.ShowCheckbox := True;
  FBirth.Checked := False;
  FBirth.MaxDate := Date;
  P := Field(Card, 1, 3, 'R{ue}ckruf um');
  FCallback := TPPGTimePicker.Create(Own);
  FCallback.Parent := Card;
  FCallback.SetBounds(P.X, P.Y, 130, CtlH);
  FCallback.ClockFormat := pcf24Hour;
  FCallback.MinuteIncrement := 30;
  FCallback.Time := EncodeTime(10, 0, 0, 0);
  NewLabel(Own, Card, P.X + 142, P.Y + 6, 0, 'Uhr', tkSecondary);

  P := Field(Card, 0, 4, 'Lizenzen');
  FLicenses := TPPGSpinEdit.Create(Own);
  FLicenses.Parent := Card;
  FLicenses.SetBounds(P.X, P.Y, 130, CtlH);
  FLicenses.Min := 1;
  FLicenses.Max := 500;
  FLicenses.Value := 5;
  P := Field(Card, 1, 4, 'Kennwort');
  FPassword := NewEdit(P, 270, 'mindestens 8 Zeichen');
  FPassword.PasswordChar := #$25CF;
  FPassword.OnChange := PasswordChange;
  FStrength := TPPGProgressBar.Create(Own);
  FStrength.Parent := Card;
  FStrength.SetBounds(P.X, P.Y + CtlH + 6, 180, 4);
  FStrengthText := NewLabel(Own, Card, P.X + 190, P.Y + CtlH - 1, 0, '', tkCaption);

  P := Field(Card, 0, 5, 'Notiz');
  FNotes := TPPGMemo.Create(Own);
  FNotes.Parent := Card;
  FNotes.SetBounds(P.X, P.Y, FormW - 2 * CardPad, 64);
  FNotes.TextHint := L('Optional: worum geht es?');
  FNotes.ScrollBars := ssVertical;

  FTerms := TPPGCheckBox.Create(Own);
  FTerms.Parent := Card;
  FTerms.SetBounds(CardPad, P.Y + 76, 400, 28);
  FTerms.Caption := L('Ich akzeptiere die Nutzungsbedingungen *');

  B := NewButton(Own, Card, CardPad, P.Y + 118, 130, 'Speichern', SaveClick, True);
  FSaveBtn := B;
  B.Default := True;
  B.Tag := 1;
  NewButton(Own, Card, CardPad + 142, P.Y + 118, 130, 'Zur{ue}cksetzen', ResetClick);

  FInfo := TPPGInfoBar.Create(Own);
  FInfo.Parent := Card;
  FInfo.SetBounds(CardPad, P.Y + 162, FormW - 2 * CardPad, 48);
  FInfo.Open := False;

  // Liste der gespeicherten Kontakte
  Card := NewCard(Own, Sheet, PageX + FormW + CardGap, PageContentTop, FullW - FormW - CardGap,
    640, 'Gespeicherte Kontakte', 'Nach Land gruppiert. Ein Klick l{ae}dt den Kontakt ins Formular.');
  FList := TPPGListBox.Create(Own);
  FList.Parent := Card;
  FList.SetBounds(CardPad, Card.Tag, Card.Width - 2 * CardPad, Card.Height - Card.Tag - 52);
  FList.Images := Host.Images;
  FList.OnClick := ListClick;
  FListResult := NewResult(Own, Card, 'Anzahl');
  BuildSpecialFields;
  BuildOrder;

  // Regeln statt Pruefcode: Pflicht beim Verlassen, nach einem Fehler live,
  // Sammelanzeige in der Leiste unter den Knoepfen, gruen = geprueft und gut
  FValidator := TPPGValidator.Create(Own);
  FValidator.CheckOnClose := False;
  FValidator.AutoFieldRules := False; // die DB-Controls der Datenbankseite gehoeren demselben Formular
  FValidator.ShowValid := True;
  FValidator.SummaryBar := FInfo;
  FValidator.Rules.AddRule(FFirst, vrRequired).Caption := 'Vorname';
  FValidator.Rules.AddRule(FLast, vrRequired).Caption := 'Nachname';
  FValidator.Rules.AddRule(FMail, vrRequired).Caption := 'E-Mail';
  R := FValidator.Rules.AddRule(FMail, vrPattern);
  R.Caption := 'E-Mail';
  R.PatternKind := vpEmail;
  R.Message := L('Bitte eine g{ue}ltige E-Mail-Adresse eingeben, z. B. name@firma.de');
  R := FValidator.Rules.AddRule(FPhone, vrPattern);
  R.Caption := 'Telefon';
  R.PatternKind := vpPhone;
  R.Severity := pvsWarning;
  R := FValidator.Rules.AddRule(FPassword, vrLength);
  R.Caption := 'Kennwort';
  R.MinLength := 8;
  R.Severity := pvsWarning;
  FValidator.Rules.AddRule(FTerms, vrRequired).Caption := 'Nutzungsbedingungen';

  C.FirstName := 'Anna';
  C.LastName := 'Schmidt';
  C.Mail := 'anna.schmidt@beispiel.de';
  C.Phone := '+49 30 1234567';
  C.Salutation := 'Frau';
  C.Country := 'Deutschland';
  C.Licenses := 12;
  AddContact(C);
  C.FirstName := 'Lukas';
  C.LastName := 'Gruber';
  C.Mail := 'l.gruber@beispiel.at';
  C.Phone := '';
  C.Salutation := 'Herr';
  C.Country := L('{Oe}sterreich');
  C.Licenses := 3;
  AddContact(C);
  C.FirstName := 'Sophie';
  C.LastName := 'Weber';
  C.Mail := 'sophie@weber.example';
  C.Phone := '+49 89 555010';
  C.Salutation := 'Frau';
  C.Country := 'Deutschland';
  C.Licenses := 25;
  AddContact(C);
  PasswordChange(nil);
end;

procedure TDemoFormPage.PasswordChange(Sender: TObject);
const
  Names: array[0..4] of string = ('', 'Sehr schwach', 'Schwach', 'Mittel', 'Stark');
var
  S: string;
  Score, I: Integer;
  Lower, Upper, Digit, Other: Boolean;
begin
  S := FPassword.Text;
  Lower := False;
  Upper := False;
  Digit := False;
  Other := False;
  for I := 1 to Length(S) do
    if CharInSet(S[I], ['a'..'z']) then
      Lower := True
    else if CharInSet(S[I], ['A'..'Z']) then
      Upper := True
    else if CharInSet(S[I], ['0'..'9']) then
      Digit := True
    else
      Other := True;
  Score := 0;
  if S <> '' then
  begin
    Score := 1;
    if Length(S) >= 8 then
      Inc(Score);
    if Lower and Upper then
      Inc(Score);
    if Digit or Other then
      Inc(Score);
    if (Length(S) < 8) and (Score > 2) then
      Score := 2;
  end;
  FStrength.Position := Score * 25;
  case Score of
    0, 1, 2: FStrength.State := pbsError;
    3: FStrength.State := pbsPaused;
  else
    FStrength.State := pbsNormal;
  end;
  FStrengthText.Caption := L(Names[Score]);
end;

procedure TDemoFormPage.SaveClick(Sender: TObject);
var
  C: TDemoContact;
begin
  // Alles, was frueher hier von Hand stand, sind jetzt Regeln (Build)
  if not FValidator.Validate then
  begin
    FValidator.FocusFirstError;
    Host.Log('Formular', L('Speichern abgelehnt: ') + FInfo.Message);
    Exit;
  end;
  C.FirstName := Trim(FFirst.Text);
  C.LastName := Trim(FLast.Text);
  C.Mail := Trim(FMail.Text);
  C.Phone := Trim(FPhone.Text);
  if FSalutation.ItemIndex >= 0 then
    C.Salutation := FSalutation.Items[FSalutation.ItemIndex];
  C.Country := Trim(FCountry.Text);
  if C.Country = '' then
    C.Country := L('Ohne Land');
  C.Licenses := FLicenses.Value;
  AddContact(C);
  FInfo.Severity := psSuccess;
  FInfo.Title := 'Gespeichert';
  FInfo.Message := MarkupEscape(C.FirstName + ' ' + C.LastName) + L(' steht jetzt in der Liste.');
  FInfo.Open := True;
  Host.Notifier.Show('Kontakt gespeichert', MarkupEscape(C.FirstName + ' ' + C.LastName) +
    ' (' + MarkupEscape(C.Country) + ')', psSuccess);
  Host.Log('Formular', 'Gespeichert: ' + C.FirstName + ' ' + C.LastName);
end;

procedure TDemoFormPage.ResetClick(Sender: TObject);
begin
  FFirst.Text := '';
  FLast.Text := '';
  FMail.Text := '';
  FPhone.Text := '';
  FPassword.Text := '';
  FCountry.Text := '';
  FSalutation.ItemIndex := 3;
  FBirth.Checked := False;
  FLicenses.Value := 5;
  FNotes.Lines.Clear;
  FTerms.Checked := False;
  FValidator.ClearResults;
  FInfo.Open := False;
  Host.Log('Formular', L('Zur{ue}ckgesetzt'));
end;

procedure TDemoFormPage.AddContact(const C: TDemoContact);
var
  It: TPPGItem;
begin
  SetLength(FContacts, Length(FContacts) + 1);
  FContacts[High(FContacts)] := C;
  It := FList.ItemsEx.Add(MarkupEscape(C.FirstName + ' ' + C.LastName), 14);
  It.Detail := C.Mail;
  It.Group := C.Country;
  It.Badge := IntToStr(C.Licenses);
  It.Tag := High(FContacts);
  FList.AllowMarkup := True;
  SetResult(FListResult, Format('%d Kontakte', [Length(FContacts)]));
end;

procedure TDemoFormPage.ListClick(Sender: TObject);
var
  C: TDemoContact;
  Idx: Integer;
begin
  if FList.ItemIndex < 0 then
    Exit;
  Idx := FList.ItemsEx[FList.ItemIndex].Tag;
  if (Idx < 0) or (Idx > High(FContacts)) then
    Exit;
  C := FContacts[Idx];
  FFirst.Text := C.FirstName;
  FLast.Text := C.LastName;
  FMail.Text := C.Mail;
  FPhone.Text := C.Phone;
  FCountry.Text := C.Country;
  FSalutation.ItemIndex := FSalutation.Items.IndexOf(C.Salutation);
  FLicenses.Value := C.Licenses;
  FInfo.Open := False;
  Host.Log('ListBox', 'Kontakt geladen: ' + C.FirstName + ' ' + C.LastName);
end;

{ Selbsttests }

procedure TDemoButtonsPage.SelfTest(Check: TDemoCheck);
begin
  DemoClick(FSaveBtn);
  DemoClick(FSaveBtn);
  Check('Buttons: Klick zaehlt (2x)', Pos('(2', FClickResult.Caption) > 0);
  DemoClick(FBold);
  Check('Buttons: Umschalter Fett', FBold.Down and (fsBold in FSample.Font.Style));
  DemoClick(FAlign[1]);
  Check('Buttons: Gruppe exklusiv', FAlign[1].Down and not FAlign[0].Down and
    (FSample.Alignment = taCenter));
  DemoClick(FBold);
  Check('Buttons: Umschalter wieder aus', not FBold.Down and not (fsBold in FSample.Font.Style));
end;

procedure TDemoChoicePage.SelfTest(Check: TDemoCheck);
var
  I: Integer;
  All: Boolean;
begin
  DemoClick(FMaster);
  All := True;
  for I := 0 to 3 do
    All := All and FChecks[I].Checked;
  Check('Auswahl: Alle-Kaestchen setzt alle', All and (FMaster.State = cbChecked));
  DemoClick(FChecks[2]);
  Check('Auswahl: Alle-Kaestchen wird gemischt', FMaster.State = cbGrayed);
  DemoClick(FRadios[1]);
  Check('Auswahl: Optionsfeld Express', FRadios[1].Checked and not FRadios[0].Checked and
    (Pos('9,90', FRadioResult.Caption) > 0));
  DemoClick(FAirplane);
  Check('Auswahl: Flugmodus sperrt Funk', FAirplane.Checked and not FWifi.Checked and
    not FWifi.Enabled and not FBluetooth.Enabled);
  DemoClick(FAirplane);
  Check('Auswahl: Flugmodus aus stellt WLAN wieder her', FWifi.Checked and FWifi.Enabled);
  FVolume.Position := 30;
  Check('Auswahl: Regler steuert Balken und Ring', (FVolumeBar.Position = 30) and
    (FVolumeRing.Value = 30));
  Check('Auswahl: empfohlener Bereich markiert', (FVolume.SelStart = 40) and (FVolume.SelEnd = 80));
  FPrice.PositionEnd := 400;
  FPrice.Position := 450;
  Check('Auswahl: Preisfilter schiebt das Ende mit', (FPrice.Position = 450) and
    (FPrice.PositionEnd = 450) and (Pos('450', FPriceValue.Caption) > 0));
  FPrice.Position := 50;
  FPrice.PositionEnd := 250;
  FPeriod.ItemIndex := 3;
  FDays.Checked[1] := True;
  GroupsChange(nil);
  Check('Auswahl: Gruppen liefern Werte', (FPeriod.Value = 'Jahr') and
    (FDays.Value = 'Mo,Di,Mi,Fr') and (Pos('Standard', FGroupResult.Caption) > 0));
end;

procedure TDemoFormPage.BuildSpecialFields;
const
  W = 290;
var
  Card: TPPGPanel;
  Y0: Integer;

  function Pos(Col, Row: Integer; const ACaption: string): TPoint;
  begin
    Result.X := CardPad + Col * (W + 20);
    Result.Y := Y0 + Row * 64;
    NewLabel(Own, Card, Result.X, Result.Y, 0, ACaption, tkBody);
    Inc(Result.Y, 22);
  end;

  procedure Place(C: TPPGCustomControl; P: TPoint);
  begin
    C.Parent := Card;
    C.SetBounds(P.X, P.Y, W, CtlH);
  end;

begin
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 640 + CardGap, FullW, 340,
    'Spezialfelder',
    L('Maske, Betrag, Prozent, Kennwort, Datei, Farbe, Mehrfachauswahl, Spaltenliste und ') +
    L('Stichw{oe}rter {-} alle mit Tastatur, Screenreader und Fehler am Feld.'));
  Y0 := Card.Tag;
  FPlz := TPPGMaskEdit.Create(Own);
  Place(FPlz, Pos(0, 0, 'PLZ (Maske 00000)'));
  FPlz.EditMask := '00000;0;_';
  FPlz.OnChange := SpecialChange;
  FAmount := TPPGNumberEdit.Create(Own);
  Place(FAmount, Pos(1, 0, L('Betrag (rechnet: 2*19,99)')));
  FAmount.Kind := nkCurrency;
  FAmount.ShowSpinButtons := True;
  FAmount.Min := 0;
  FAmount.Max := 100000;
  FAmount.Value := 1234.5;
  FAmount.OnChange := SpecialChange;
  FDiscount := TPPGNumberEdit.Create(Own);
  Place(FDiscount, Pos(2, 0, 'Rabatt'));
  FDiscount.Kind := nkPercent;
  FDiscount.Decimals := 1;
  FDiscount.Max := 100;
  FDiscount.Value := 12.5;
  FDiscount.OnChange := SpecialChange;
  FPin := TPPGPasswordEdit.Create(Own);
  Place(FPin, Pos(0, 1, 'Kennwort'));
  FPin.RevealMode := rmToggle;
  FPin.TextHint := L('Auge zum Aufdecken');
  FFile := TPPGFileEdit.Create(Own);
  Place(FFile, Pos(1, 1, L('Anhang (Datei hierher ziehen)')));
  FFile.Filter := 'Dokumente|*.pdf;*.docx|Alle Dateien|*.*';
  FFile.MustExist := True;
  FFile.OnChange := SpecialChange;
  FColor := TPPGColorPicker.Create(Own);
  Place(FColor, Pos(2, 1, 'Farbe'));
  FColor.Style := FColor.Style + [cbIncludeNone];
  FColor.Selected := TColor($D47800);
  FColor.OnChange := SpecialChange;
  FCats := TPPGCheckComboBox.Create(Own);
  Place(FCats, Pos(0, 2, 'Kategorien'));
  FCats.Items.CommaText := L('Kunde,Lieferant,Partner,Presse,Intern,Interessent');
  FCats.ShowSelectAll := True;
  FCats.CheckedText := 'Kunde;Partner';
  FCats.TextHint := L('ausw{ae}hlen{...}');
  FCats.OnChange := SpecialChange;
  FCustomer := TPPGColumnComboBox.Create(Own);
  Place(FCustomer, Pos(1, 2, 'Kunde (mehrspaltig)'));
  with FCustomer.Columns.Add do
  begin
    Title := 'Nr';
    Width := 60;
  end;
  with FCustomer.Columns.Add do
  begin
    Title := 'Name';
    Width := 150;
  end;
  with FCustomer.Columns.Add do
  begin
    Title := 'Ort';
    Width := 110;
  end;
  FCustomer.Items.Add('1001|Albers GmbH|Hamburg');
  FCustomer.Items.Add(L('1002|M{ue}ller & S{oe}hne|Berlin'));
  FCustomer.Items.Add(L('1003|Zander AG|K{oe}ln'));
  FCustomer.Items.Add(L('1004|Bauer KG|M{ue}nchen'));
  FCustomer.DisplayColumn := 1;
  FCustomer.TextHint := L('Kunde w{ae}hlen{...}');
  FCustomer.OnChange := SpecialChange;
  FTags := TPPGTagEdit.Create(Own);
  Place(FTags, Pos(2, 2, L('Stichw{oe}rter (Enter oder ;)')));
  FTags.Suggestions.CommaText := 'Delphi,VCL,Windows,Fluent,Datenbank,Design,Barrierefreiheit';
  FTags.TagsText := 'Delphi;VCL';
  FTags.OnChange := SpecialChange;
  FSpecialResult := NewResult(Own, Card, L('Zuletzt ge{ae}ndert'));
  Host.RegisterSpecial('numberedit', FAmount);
  Host.RegisterSpecial('tagedit', FTags);
end;

procedure TDemoFormPage.BuildOrder;
const
  TabW = 600;
var
  Card: TPPGPanel;
  Lbl: TPPGLabel;
  R: TPPGValidationRule;
  X: Integer;
begin
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 640 + CardGap + 340 + CardGap, FullW, 300,
    'Bestellung (Validator und Warte-Overlay)', 'Ein Fehler auf dem verdeckten Reiter holt ' +
    '"Bestellen" nach vorn. Danach l{ae}uft die {Ue}bertragung im Hintergrund-Thread: Ring, ' +
    'Fortschritt, Abbrechen (auch mit Esc), die Karte ist so lange gesperrt.');
  Host.RegisterSpecial('ordercard', Card);
  FOrderPages := TPPGPageControl.Create(Own);
  FOrderPages.Parent := Card;
  FOrderPages.SetBounds(CardPad, Card.Tag, TabW, 200);
  FOrderShip := TPPGTabSheet.Create(Own);
  FOrderShip.PageControl := FOrderPages;
  FOrderShip.Caption := 'Lieferung';
  FOrderPay := TPPGTabSheet.Create(Own);
  FOrderPay.PageControl := FOrderPages;
  FOrderPay.Caption := 'Zahlung';
  FOrderPages.ActivePage := FOrderShip;

  // Lieferung: Beschriftungen per FocusControl - der Validator nimmt sie als Feldnamen
  Lbl := NewLabel(Own, FOrderShip, 16, 16, 0, 'PLZ *', tkBody);
  FZip := TPPGEdit.Create(Own);
  FZip.Parent := FOrderShip;
  FZip.SetBounds(16, 40, 140, CtlH);
  FZip.TextHint := '10115';
  Lbl.FocusControl := FZip;
  Lbl := NewLabel(Own, FOrderShip, 186, 16, 0, 'Lieferung ab', tkBody);
  FShipFrom := TPPGDatePicker.Create(Own);
  FShipFrom.Parent := FOrderShip;
  FShipFrom.SetBounds(186, 40, 170, CtlH);
  FShipFrom.Date := Date + 1;
  Lbl.FocusControl := FShipFrom;
  Lbl := NewLabel(Own, FOrderShip, 386, 16, 0, 'Lieferung bis', tkBody);
  FShipTo := TPPGDatePicker.Create(Own);
  FShipTo.Parent := FOrderShip;
  FShipTo.SetBounds(386, 40, 170, CtlH);
  FShipTo.Date := Date + 7;
  Lbl.FocusControl := FShipTo;

  // Zahlung
  Lbl := NewLabel(Own, FOrderPay, 16, 16, 0, 'IBAN *', tkBody);
  FIban := TPPGEdit.Create(Own);
  FIban.Parent := FOrderPay;
  FIban.SetBounds(16, 40, 320, CtlH);
  FIban.TextHint := 'DE89 3704 0044 0532 0130 00';
  Lbl.FocusControl := FIban;
  Lbl := NewLabel(Own, FOrderPay, 366, 16, 0, L('Betrag ({EUR})'), tkBody);
  FOrderAmount := TPPGNumberEdit.Create(Own);
  FOrderAmount.Parent := FOrderPay;
  FOrderAmount.SetBounds(366, 40, 160, CtlH);
  FOrderAmount.Value := 249;
  Lbl.FocusControl := FOrderAmount;

  X := CardPad + TabW + 24;
  FOrderBar := TPPGInfoBar.Create(Own);
  FOrderBar.Parent := Card;
  FOrderBar.SetBounds(X, Card.Tag, FullW - X - CardPad, 64);
  FOrderBar.Open := False;
  FOrderBtn := NewButton(Own, Card, X, Card.Tag + 150, 150, 'Bestellen', OrderClick, True);
  FOrderResult := NewResult(Own, Card, 'Bestellung');

  FOrderValidator := TPPGValidator.Create(Own);
  FOrderValidator.Name := 'OrderValidator';
  FOrderValidator.CheckOnClose := False;
  FOrderValidator.AutoFieldRules := False;
  FOrderValidator.SummaryBar := FOrderBar;
  FOrderValidator.Rules.AddRule(FZip, vrRequired);
  R := FOrderValidator.Rules.AddRule(FZip, vrPattern);
  R.PatternKind := vpPostalCodeDE;
  R := FOrderValidator.Rules.AddRule(FShipTo, vrCompare);
  R.CompareControl := FShipFrom;
  R.CompareOperator := coGreaterOrEqual;
  FOrderValidator.Rules.AddRule(FIban, vrRequired);
  R := FOrderValidator.Rules.AddRule(FIban, vrPattern);
  R.PatternKind := vpIBAN;
  R := FOrderValidator.Rules.AddRule(FOrderAmount, vrRange);
  R.MinValue := '1';
  R.MaxValue := '10000';

  FOrderBusy := TPPGBusyOverlay.Create(Own);
  FOrderBusy.Name := 'OrderBusy';
  FOrderBusy.Target := Card;
  FOrderBusy.ShowCancel := True;
  FOrderBusy.Text := L('Bestellung wird {ue}bertragen');
  FOrderStepMs := 120;
end;

procedure TDemoFormPage.OrderClick(Sender: TObject);
var
  StepMs: Integer;
begin
  if not FOrderValidator.Validate then
  begin
    FOrderValidator.FocusFirstError;
    Host.Log('Validator', L('Bestellung unvollst{ae}ndig: ') + FOrderBar.Message);
    Exit;
  end;
  StepMs := FOrderStepMs;
  FOrderBusy.Progress := 0;
  FOrderBusy.Description := '';
  // Die Arbeit laeuft im Thread und fasst keine VCL-Controls an
  FOrderBusy.Run(
    procedure(const C: IPPGBusyContext)
    var
      I: Integer;
    begin
      for I := 1 to 20 do
      begin
        if C.Cancelled then
          Exit;
        Sleep(StepMs);
        C.Report(I * 5);
        C.SetDescription(Format('Schritt %d von 20', [I]));
      end;
    end);
  if FOrderBusy.Cancelled then
  begin
    SetResult(FOrderResult, 'abgebrochen');
    Host.Log('BusyOverlay', 'Bestellung abgebrochen');
  end
  else
  begin
    SetResult(FOrderResult, L('{ue}bertragen'));
    Host.Notifier.Show('Bestellung', L('Die Bestellung wurde {ue}bertragen.'), psSuccess);
    Host.Log('BusyOverlay', L('Bestellung {ue}bertragen'));
  end;
end;

procedure TDemoFormPage.SpecialChange(Sender: TObject);
var
  S: string;
begin
  if Sender = FAmount then
    S := 'Betrag = ' + FAmount.DisplayText
  else if Sender = FDiscount then
    S := 'Rabatt = ' + FDiscount.DisplayText
  else if Sender = FPlz then
    S := 'PLZ = ' + FPlz.Text
  else if Sender = FFile then
    S := 'Datei = ' + ExtractFileName(FFile.FileName)
  else if Sender = FColor then
    S := 'Farbe = ' + FColor.ColorName(FColor.Selected)
  else if Sender = FCats then
    S := 'Kategorien = ' + FCats.CheckedText
  else if Sender = FCustomer then
    S := 'Kunde = ' + FCustomer.KeyValue + ' ' + FCustomer.DisplayText
  else if Sender = FTags then
    S := L('Stichw{oe}rter = ') + FTags.TagsText;
  SetResult(FSpecialResult, MarkupEscape(S));
  Host.Log('Formular', S);
end;

procedure TDemoFormPage.SelfTest(Check: TDemoCheck);
var
  N: Integer;
begin
  Check('Spezialfelder: Betrag als Waehrung', FAmount.AsCurrency = 1234.5);
  FAmount.Value := 2.345;
  Check(L('Spezialfelder: kaufm{ae}nnisch gerundet'), FAmount.AsCurrency = 2.35);
  FAmount.Value := 1234.5;
  Check('Spezialfelder: Kategorien', FCats.CheckedCount = 2);
  Check(L('Spezialfelder: Stichw{oe}rter'), FTags.AddTag('Design') and (FTags.Tags.Count = 3));
  FTags.TagsText := 'Delphi;VCL';
  FCustomer.KeyValue := '1003';
  Check('Spezialfelder: Kunde per Schluessel', FCustomer.ItemIndex = 2);
  FCustomer.ItemIndex := -1;
  FPlz.Text := '1';
  Check('Spezialfelder: Maske prueft', not FPlz.ValidateInput);
  FPlz.Text := '';
  FPlz.ValidateInput;
  ResetClick(nil);
  N := Length(FContacts);
  DemoClick(FSaveBtn);
  Check('Formular: leeres Speichern wird abgelehnt', FInfo.Open and (FInfo.Severity = psError) and
    (FFirst.ValidationState = pvsError) and (Length(FContacts) = N));
  Check('Validator: Sammelleiste nennt die Felder', Pos('Vorname', FInfo.Message) > 0);
  // Nach einem Fehler prueft der Validator live (gepostet, daher Nachrichten abholen)
  FMail.Text := 'kaputt@';
  Application.ProcessMessages;
  Check('Formular: E-Mail falsch -> Fehler', FMail.ValidationState = pvsError);
  FMail.Text := 'max@firma.de';
  Application.ProcessMessages;
  Check('Formular: E-Mail richtig -> gueltig', FMail.ValidationState = pvsValid);
  FFirst.Text := 'Max';
  Application.ProcessMessages;
  Check('Formular: Pflichtfeld-Fehler verschwindet', FFirst.ValidationState <> pvsError);
  FLast.Text := 'Muster';
  FPassword.Text := 'abc';
  Check('Formular: schwaches Kennwort', (FStrength.Position <= 50) and (FStrength.State = pbsError));
  FPassword.Text := 'Abcdefg1!';
  Check('Formular: starkes Kennwort', FStrength.Position = 100);
  DemoClick(FTerms);
  DemoClick(FSaveBtn);
  Check('Formular: Speichern legt Kontakt ab', (Length(FContacts) = N + 1) and
    (FInfo.Severity = psSuccess) and (FList.ItemsEx.Count = N + 1));
  FList.ItemIndex := 0;
  ListClick(FList);
  Check('Formular: Klick laedt Kontakt', FFirst.Text = FContacts[FList.ItemsEx[0].Tag].FirstName);

  // Bestellung: Validator ueber zwei Reiter, danach Arbeit im Hintergrund
  FOrderStepMs := 1;
  FOrderPages.ActivePage := FOrderShip;
  FZip.Text := '10115';
  FIban.Text := 'DE00 1234';
  DemoClick(FOrderBtn);
  Check('Validator: Sprung auf den Reiter mit dem Fehler', FOrderPages.ActivePage = FOrderPay);
  Check('Validator: Sammelleiste der Bestellung', FOrderBar.Open and (FOrderBar.Severity = psError));
  FIban.Text := 'DE89 3704 0044 0532 0130 00';
  FShipTo.Date := FShipFrom.Date - 1;
  DemoClick(FOrderBtn);
  Check('Validator: Lieferung bis vor ab', (FOrderPages.ActivePage = FOrderShip) and
    (FShipTo.ValidationState = pvsError));
  FShipTo.Date := FShipFrom.Date + 3;
  DemoClick(FOrderBtn);
  Check(L('Warte-Overlay: Bestellung l{ae}uft im Hintergrund durch'), not FOrderBusy.Active and
    (FOrderBusy.Progress = 100) and not FOrderBusy.Cancelled);
  Check('Validator: Sammelleiste zu, wenn alles stimmt', not FOrderBar.Open);
  FOrderStepMs := 120;
end;

end.
