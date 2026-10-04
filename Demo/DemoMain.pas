unit DemoMain;

{ Showcase der PPGlow-Suite: Hauptfenster im Stil der Windows-11-Einstellungen
  (NavigationView links, Seiten rechts, Statusleiste). Jede Seite zeigt die
  Controls in kleinen Alltagsszenarien mit sichtbarem Ergebnis, damit
  Anwender sehen, dass die Funktionen wirklich arbeiten.

  Das Formular wird bewusst im Code aufgebaut (keine DFM), damit die Demo
  ohne installiertes Design-Package laeuft. Die Seiten stehen in DemoPages*,
  die Bausteine (Typografie, Karten, Akzent) in DemoKit. }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ImgList,
  PPG.Types, PPG.Consts, PPG.ErrorHandler, PPG.Render.Registry,
  PPG.Controls.Base, PPG.Button, PPG.PageControl, PPG.Theme, PPG.Tokens,
  PPG.NavigationView, PPG.StatusBar, PPG.Notifications, PPG.ComboBox,
  PPG.DatePicker, PPG.Controls.Field, PPG.Feedback,
  DemoKit;

type
  TDemoForm = class(TForm, IDemoHost)
  private
    FImages: TImageList;
    FPages: TPPGPageControl;
    FNav: TPPGNavigationView;
    FStatus: TPPGStatusBar;
    FNotify: TPPGNotificationCenter;
    FPageObjects: TList<TDemoPage>;
    FSpecial: TDictionary<string, TControl>;
    FEventsItem: TPPGNavItem;
    FUnseen: Integer;
    FVclStyle: string;
    FReport: TStringList;
    FFailures: Integer;
    procedure SelfCheck(const AName: string; AOk: Boolean);
    procedure BuildImages;
    procedure BuildPages;
    procedure BuildNavigation;
    procedure BuildStatusBar;
    procedure NavSelectionChange(Sender: TObject);
    procedure ThemeChanged(Sender: TObject);
    procedure ToastShown(Sender: TObject; Toast: TPPGToast);
    procedure ToastAction(Sender: TObject; Toast: TPPGToast; ActionIndex: Integer);
    procedure ToastClosed(Sender: TObject; Toast: TPPGToast; Reason: TPPGToastCloseReason);
    procedure HandlePPGError(Sender: TObject; E: Exception; const Context: string);
    procedure AppearanceChanged;
    procedure UpdateStatusPanels;
    function PageObject(Index: Integer): TDemoPage;
    function SpecialControl(const Key: string): TControl;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    { IDemoHost }
    procedure Log(const Category, Text: string);
    function Notifier: TPPGNotificationCenter;
    function Images: TCustomImageList;
    procedure GoToPage(Index: Integer);
    function CurrentPreset: string;
    procedure ApplyPreset(const AName: string);
    procedure ApplyVclStyle(const AName: string);
    procedure RegisterSpecial(const Key: string; C: TControl);
    { Screenshot-Modus }
    procedure SaveScreenshot(const FileName: string);
    procedure FocusDemoField;
    procedure DropDownDemoCombo;
    procedure DropDownImageCombo;
    procedure ShowHoverDemo;
    procedure ShowFocusDemo;
    procedure ShowPage(Index: Integer);
    procedure ApplyTheme(const AName: string);
    function EnableMica: Boolean;
    procedure SaveScreenCapture(const FileName: string);
    procedure SaveToastCapture(const FileName: string);
    procedure SaveDatePopupCapture(const FileName: string);
    /// Selbsttest aller Seiten (/selftest datei.txt). Ergebnis = Anzahl Fehler.
    function RunSelfTest(const FileName: string): Integer;
  end;

const
  // Seitennummern (auch fuer /page n)
  PgStart = 0;
  PgButtons = 1;
  PgChoice = 2;
  PgForm = 3;
  PgLists = 4;
  PgExplorer = 5;
  PgGrid = 6;
  PgDates = 7;
  PgLayout = 8;
  PgFeedback = 9;
  PgAppearance = 10;
  PgEvents = 11;

implementation

uses
  Winapi.Messages, Winapi.DwmApi, System.Types, System.Math, Vcl.Imaging.pngimage,
  Vcl.Themes,
  Vcl.Styles, // registriert die Engine fuer .vsf-Dateien (sonst ist jeder Style "ungueltig")
  PPG.IconFont, DemoPages1, DemoPages2, DemoPages3;

type
  TPageDef = record
    Caption: string;
    Icon: Word;
    Group: string;
    Footer: Boolean;
  end;

const
  PageDefs: array[0..11] of TPageDef = (
    (Caption: 'Start'; Icon: $E80F; Group: ''; Footer: False),
    (Caption: 'Buttons & Befehle'; Icon: $E8B0; Group: 'Grundlagen'; Footer: False),
    (Caption: 'Auswahl & Regler'; Icon: $E9E9; Group: ''; Footer: False),
    (Caption: 'Formular'; Icon: $E70F; Group: ''; Footer: False),
    (Caption: 'Listen'; Icon: $EA37; Group: 'Daten'; Footer: False),
    (Caption: 'Explorer'; Icon: $E8B7; Group: ''; Footer: False),
    (Caption: 'Tabelle'; Icon: $E80A; Group: ''; Footer: False),
    (Caption: 'Termine'; Icon: $E787; Group: ''; Footer: False),
    (Caption: 'Layout'; Icon: $ECA5; Group: 'Oberfl{ae}che'; Footer: False),
    (Caption: 'R{ue}ckmeldung'; Icon: $EA8F; Group: ''; Footer: False),
    (Caption: 'Darstellung'; Icon: $E771; Group: ''; Footer: True),
    (Caption: 'Ereignisse'; Icon: $E81C; Group: ''; Footer: True));

function PageClass(Index: Integer): TDemoPageClass;
begin
  case Index of
    PgStart: Result := TDemoStartPage;
    PgButtons: Result := TDemoButtonsPage;
    PgChoice: Result := TDemoChoicePage;
    PgForm: Result := TDemoFormPage;
    PgLists: Result := TDemoListsPage;
    PgExplorer: Result := TDemoExplorerPage;
    PgGrid: Result := TDemoGridPage;
    PgDates: Result := TDemoDatesPage;
    PgLayout: Result := TDemoLayoutPage;
    PgFeedback: Result := TDemoFeedbackPage;
    PgAppearance: Result := TDemoAppearancePage;
  else
    Result := TDemoEventsPage;
  end;
end;

constructor TDemoForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := L('PPGlow {-} Showcase');
  Position := poScreenCenter;
  ClientWidth := 1320;
  ClientHeight := 860;
  Constraints.MinWidth := 900;
  Constraints.MinHeight := 600;
  Font.Name := BodyFontName;
  Font.Size := 10;
  FPageObjects := TList<TDemoPage>.Create;
  FSpecial := TDictionary<string, TControl>.Create;
  DemoPreset := PPGPresetFluent11;
  DemoStyler := TDemoStyler.Create(Self);
  TPPGErrorHandler.OnError := HandlePPGError;
  // Formular und Titelleiste folgen dem Dark Mode
  TPPGTheme.StyleForms := True;
  TPPGTheme.OnChange := ThemeChanged;
  FNotify := TPPGNotificationCenter.Create(Self);
  FNotify.Preset := DemoPreset;
  FNotify.OnShow := ToastShown;
  FNotify.OnAction := ToastAction;
  FNotify.OnClose := ToastClosed;
  BuildImages;
  BuildStatusBar;
  BuildPages;
  BuildNavigation;
  ApplyPreset(DemoPreset);
  Log('Start', 'Demo gestartet {-} viel Spa{ss} beim Ausprobieren!');
end;

destructor TDemoForm.Destroy;
begin
  TPPGTheme.OnChange := nil;
  TPPGErrorHandler.OnError := nil;
  FreeAndNil(FSpecial);
  FreeAndNil(FPageObjects);
  inherited Destroy;
end;

procedure TDemoForm.BuildImages;
type
  TIconDef = record
    Glyph: Word;
    Color: TColor;
  end;
const
  // Farbige Fluent-Symbole; die Seiten verwenden die Indizes direkt
  Icons: array[0..19] of TIconDef = (
    (Glyph: $E74E; Color: $00D47800),  // 0 Speichern
    (Glyph: $E8B7; Color: $0030A8E8),  // 1 Ordner
    (Glyph: $E8A5; Color: $00D47800),  // 2 Dokument
    (Glyph: $E91B; Color: $00309A30),  // 3 Bild
    (Glyph: $E715; Color: $00D47800),  // 4 Post
    (Glyph: $E724; Color: $00B06A00),  // 5 Gesendet
    (Glyph: $E74D; Color: $002B2BC4),  // 6 Papierkorb
    (Glyph: $E734; Color: $0000B4F0),  // 7 Stern
    (Glyph: $E7BA; Color: $00006CE0),  // 8 Warnung
    (Glyph: $EA39; Color: $002B2BC4),  // 9 Fehler
    (Glyph: $E73E; Color: $00309A30),  // 10 Haken
    (Glyph: $E8D6; Color: $00B04898),  // 11 Musik
    (Glyph: $E714; Color: $004040C0),  // 12 Video
    (Glyph: $E7B8; Color: $00406A9A),  // 13 Paket
    (Glyph: $E77B; Color: $00806040),  // 14 Person
    (Glyph: $E70F; Color: $00707070),  // 15 Entwurf
    (Glyph: $E774; Color: $00B07800),  // 16 Globus
    (Glyph: $E713; Color: $00707070),  // 17 Einstellungen
    (Glyph: $EA3B; Color: $00309A30),  // 18 Punkt gruen
    (Glyph: $EA3B; Color: $002B2BC4)); // 19 Punkt rot
var
  Bmp: TBitmap;
  I, X, Y, A: Integer;
  P: PRGBQuad;
  R, G, B: Byte;
  IconFont: string;
begin
  FImages := TImageList.Create(Self);
  FImages.ColorDepth := cd32Bit;
  FImages.Width := 16;
  FImages.Height := 16;
  IconFont := PPGIconFontName;
  for I := 0 to High(Icons) do
  begin
    Bmp := TBitmap.Create;
    try
      // Symbol weiss auf schwarz mit Graustufen-Glaettung zeichnen, die
      // Helligkeit wird zur Deckkraft der Zielfarbe
      Bmp.PixelFormat := pf32bit;
      Bmp.SetSize(16, 16);
      Bmp.Canvas.Brush.Color := clBlack;
      Bmp.Canvas.FillRect(Rect(0, 0, 16, 16));
      if IconFont <> '' then
      begin
        Bmp.Canvas.Font.Name := IconFont;
        Bmp.Canvas.Font.Height := -16;
        Bmp.Canvas.Font.Color := clWhite;
        Bmp.Canvas.Font.Quality := fqAntialiased;
        Bmp.Canvas.Brush.Style := bsClear;
        Bmp.Canvas.TextOut(0, 0, Char(Icons[I].Glyph));
      end
      else
      begin
        Bmp.Canvas.Brush.Color := clWhite;
        Bmp.Canvas.Pen.Color := clWhite;
        Bmp.Canvas.Ellipse(2, 2, 14, 14);
      end;
      R := GetRValue(ColorToRGB(Icons[I].Color));
      G := GetGValue(ColorToRGB(Icons[I].Color));
      B := GetBValue(ColorToRGB(Icons[I].Color));
      for Y := 0 to 15 do
      begin
        P := Bmp.ScanLine[Y];
        for X := 0 to 15 do
        begin
          A := P^.rgbRed;
          // vormultipliziert
          P^.rgbRed := R * A div 255;
          P^.rgbGreen := G * A div 255;
          P^.rgbBlue := B * A div 255;
          P^.rgbReserved := A;
          Inc(P);
        end;
      end;
      Bmp.AlphaFormat := afPremultiplied;
      FImages.Add(Bmp, nil);
    finally
      Bmp.Free;
    end;
  end;
end;

procedure TDemoForm.BuildPages;
var
  I: Integer;
  Sheet: TPPGTabSheet;
begin
  FPages := TPPGPageControl.Create(Self);
  FPages.Parent := Self;
  FPages.Preset := DemoPreset;
  FPages.Align := alClient;
  for I := 0 to High(PageDefs) do
  begin
    Sheet := TPPGTabSheet.Create(Self);
    Sheet.Caption := L(PageDefs[I].Caption);
    Sheet.PageControl := FPages;
  end;
  for I := 0 to FPages.PageCount - 1 do
    FPageObjects.Add(PageClass(I).CreatePage(Self, Self, FPages.Pages[I]));
  FPages.ActivePageIndex := PgStart;
  // Die NavigationView navigiert: Reiter aus (die aktive Seite zuletzt,
  // sonst springt das PageControl zur Nachbarseite)
  for I := FPages.PageCount - 1 downto 0 do
    FPages.Pages[I].TabVisible := False;
end;

procedure TDemoForm.BuildNavigation;
var
  I: Integer;
  It: TPPGNavItem;
begin
  FNav := TPPGNavigationView.Create(Self);
  FNav.Parent := Self;
  FNav.Preset := DemoPreset;
  FNav.Align := alLeft;
  FNav.OpenPaneLength := 260;
  FNav.DisplayMode := pdmAuto;
  FNav.CompactModeThresholdWidth := 1000;
  FNav.PaneTitle := 'PPGlow';
  FNav.BeginItemsUpdate;
  try
    for I := 0 to High(PageDefs) do
    begin
      if PageDefs[I].Group <> '' then
        FNav.Items.AddHeader(L(PageDefs[I].Group));
      It := FNav.Items.AddItem(L(PageDefs[I].Caption), PageDefs[I].Icon, I);
      It.Footer := PageDefs[I].Footer;
      if I = PgEvents then
        FEventsItem := It;
    end;
  finally
    FNav.EndItemsUpdate;
  end;
  FNav.PageControl := FPages;
  FNav.OnSelectionChange := NavSelectionChange;
  FNav.Selected := FNav.Items[0];
end;

procedure TDemoForm.BuildStatusBar;
var
  P: TPPGStatusPanel;
begin
  FStatus := TPPGStatusBar.Create(Self);
  FStatus.Parent := Self;
  FStatus.AllowMarkup := True;
  FStatus.Images := FImages;
  P := FStatus.Panels.Add;
  P.Width := 560;
  P := FStatus.Panels.Add;
  P.Width := 170;
  P := FStatus.Panels.Add;
  P.Width := 150;
  P := FStatus.Panels.Add;
  P.Width := 150;
  P.Kind := spkBadge;
  P.Hint := 'Sichtbare Benachrichtigungen';
end;

function TDemoForm.PageObject(Index: Integer): TDemoPage;
begin
  Result := nil;
  if (FPageObjects <> nil) and (Index >= 0) and (Index < FPageObjects.Count) then
    Result := FPageObjects[Index];
end;

procedure TDemoForm.Log(const Category, Text: string);
begin
  if FStatus <> nil then
    FStatus.Panels[0].Text := '<b>' + MarkupEscape(L(Category)) + '</b>  ' +
      MarkupEscape(L(Text));
  if PageObject(PgEvents) is TDemoEventsPage then
    TDemoEventsPage(PageObject(PgEvents)).AddEvent(L(Category), L(Text));
  if (FEventsItem <> nil) and (FPages <> nil) and (FPages.ActivePageIndex <> PgEvents) then
  begin
    Inc(FUnseen);
    FEventsItem.BadgeCount := FUnseen;
  end;
end;

function TDemoForm.Notifier: TPPGNotificationCenter;
begin
  Result := FNotify;
end;

function TDemoForm.Images: TCustomImageList;
begin
  Result := FImages;
end;

procedure TDemoForm.GoToPage(Index: Integer);
begin
  ShowPage(Index);
end;

function TDemoForm.CurrentPreset: string;
begin
  Result := DemoPreset;
end;

type
  TControlAccess = class(TPPGCustomControl);

procedure TDemoForm.ApplyPreset(const AName: string);
var
  I: Integer;
begin
  if TPPGRendererRegistry.Get(AName) = nil then
    Exit;
  DemoPreset := AName;
  FNotify.Preset := AName;
  // Controls mit eigenem StyleManager (Vorschau-Kacheln) behalten ihr Preset
  for I := 0 to ComponentCount - 1 do
    if (Components[I] is TPPGCustomControl) and
      (TControlAccess(Components[I]).StyleManager = nil) then
      TControlAccess(Components[I]).Preset := AName;
  AppearanceChanged;
end;

procedure TDemoForm.AppearanceChanged;
var
  P: TDemoPage;
begin
  // Preset setzt die Appearance zurueck: Akzentfarben neu, Seiten informieren
  if DemoStyler <> nil then
    DemoStyler.Refresh;
  if FPageObjects <> nil then
    for P in FPageObjects do
      P.AppearanceChanged;
  UpdateStatusPanels;
end;

procedure TDemoForm.UpdateStatusPanels;
const
  ModeNames: array[TPPGThemeMode] of string = ('Hell', 'Dunkel', 'System');
var
  S: string;
begin
  if FStatus = nil then
    Exit;
  FStatus.Panels[1].Text := 'Preset: <b>' + DemoPreset + '</b>';
  S := ModeNames[TPPGTheme.Mode];
  if FVclStyle <> '' then
    S := FVclStyle;
  FStatus.Panels[2].Text := 'Modus: <b>' + S + '</b>';
end;

procedure TDemoForm.ApplyVclStyle(const AName: string);
var
  Info: TStyleInfo;
  FileName: string;
begin
  if SameText(AName, 'Windows') or (AName = '') then
  begin
    TStyleManager.SetStyle(TStyleManager.SystemStyle);
    FVclStyle := '';
  end
  else
  begin
    FileName := StylesDir + AName + '.vsf';
    if not TStyleManager.IsValidStyle(FileName, Info) then
      raise Exception.CreateFmt('Kein gueltiger VCL-Style: %s', [FileName]);
    // Bereits geladene Styles nicht erneut laden (LoadFromFile wuerde werfen)
    if not TStyleManager.TrySetStyle(Info.Name, False) then
    begin
      TStyleManager.LoadFromFile(FileName);
      TStyleManager.SetStyle(Info.Name);
    end;
    FVclStyle := AName;
  end;
  AppearanceChanged;
end;

procedure TDemoForm.RegisterSpecial(const Key: string; C: TControl);
begin
  FSpecial.AddOrSetValue(Key, C);
end;

function TDemoForm.SpecialControl(const Key: string): TControl;
begin
  if not FSpecial.TryGetValue(Key, Result) then
    Result := nil;
end;

procedure TDemoForm.NavSelectionChange(Sender: TObject);
var
  Idx: Integer;
begin
  if FNav.Selected = nil then
    Exit;
  Idx := FNav.Selected.PageIndex;
  if Idx = PgEvents then
  begin
    FUnseen := 0;
    if FEventsItem <> nil then
      FEventsItem.BadgeCount := 0;
  end;
  if PageObject(Idx) <> nil then
    PageObject(Idx).Activated;
end;

procedure TDemoForm.ShowPage(Index: Integer);
var
  I: Integer;
begin
  if (FPages = nil) or (Index < 0) or (Index >= FPages.PageCount) then
    Exit;
  FPages.ActivePageIndex := Index;
  if Index = PgEvents then
  begin
    FUnseen := 0;
    if FEventsItem <> nil then
      FEventsItem.BadgeCount := 0;
  end;
  for I := 0 to FNav.Items.Count - 1 do
    if (FNav.Items[I].Kind = nikItem) and (FNav.Items[I].PageIndex = Index) then
      FNav.Selected := FNav.Items[I];
  PageObject(Index).Activated;
end;

procedure TDemoForm.ThemeChanged(Sender: TObject);
begin
  AppearanceChanged;
end;

procedure TDemoForm.ToastShown(Sender: TObject; Toast: TPPGToast);
begin
  if FStatus <> nil then
    FStatus.Panels[3].BadgeCount := FNotify.VisibleCount + FNotify.PendingCount;
end;

procedure TDemoForm.ToastAction(Sender: TObject; Toast: TPPGToast; ActionIndex: Integer);
var
  S: string;
begin
  S := Format('"%s": %s', [Toast.Title, Toast.Actions[ActionIndex]]);
  Log('Toast-Aktion', S);
  if PageObject(PgFeedback) is TDemoFeedbackPage then
    TDemoFeedbackPage(PageObject(PgFeedback)).ToastEvent(S);
end;

procedure TDemoForm.ToastClosed(Sender: TObject; Toast: TPPGToast; Reason: TPPGToastCloseReason);
const
  Reasons: array[TPPGToastCloseReason] of string = ('abgelaufen', 'geschlossen',
    'nach Aktion', 'angeklickt', 'per Code');
var
  S: string;
begin
  // Der schliessende Toast zaehlt hier noch mit
  if FStatus <> nil then
    FStatus.Panels[3].BadgeCount := Max(0, FNotify.VisibleCount + FNotify.PendingCount - 1);
  S := Format('"%s" %s', [Toast.Title, Reasons[Reason]]);
  if PageObject(PgFeedback) is TDemoFeedbackPage then
    TDemoFeedbackPage(PageObject(PgFeedback)).ToastEvent(S);
end;

procedure TDemoForm.HandlePPGError(Sender: TObject; E: Exception; const Context: string);
begin
  Log('PPGlow-Fehler', Context + ': ' + E.Message);
end;

procedure TDemoForm.ApplyTheme(const AName: string);
begin
  if SameText(AName, 'dark') then
    TPPGTheme.Mode := tmDark
  else if SameText(AName, 'system') then
    TPPGTheme.Mode := tmSystem
  else
    TPPGTheme.Mode := tmLight;
end;

{ Screenshot-Modus }

procedure TDemoForm.FocusDemoField;
var
  C: TControl;
begin
  C := SpecialControl('fieldfocus');
  if C is TPPGCustomField then
  begin
    ShowPage(PgForm);
    TControlAccess(C).Animation.Enabled := False;
    TPPGCustomField(C).SetFocus;
  end;
end;

procedure TDemoForm.DropDownDemoCombo;
var
  C: TControl;
begin
  C := SpecialControl('dropdown');
  if C is TPPGComboBox then
  begin
    ShowPage(PgForm);
    TPPGComboBox(C).Animation.Enabled := False;
    TPPGComboBox(C).SetFocus;
    TPPGComboBox(C).DroppedDown := True;
    TPPGComboBox(C).PopupList.SetHighlight(2); // Hover-Darstellung zeigen
  end;
end;

procedure TDemoForm.DropDownImageCombo;
var
  C: TControl;
begin
  C := SpecialControl('dropdownimages');
  if C is TPPGComboBox then
  begin
    ShowPage(PgLists);
    TPPGComboBox(C).Animation.Enabled := False;
    TPPGComboBox(C).SetFocus;
    TPPGComboBox(C).DroppedDown := True;
    TPPGComboBox(C).PopupList.SetHighlight(2);
  end;
end;

procedure TDemoForm.ShowHoverDemo;
var
  I: Integer;
  B: TPPGButton;
begin
  // Hover-Zustand der markierten Buttons (Tag = 1) der aktiven Seite
  for I := 0 to ComponentCount - 1 do
    if Components[I] is TPPGButton then
    begin
      B := TPPGButton(Components[I]);
      if B.Showing and (B.Tag = 1) then
      begin
        B.Animation.Enabled := False;
        B.Perform(CM_MOUSEENTER, 0, 0);
      end;
    end;
end;

procedure TDemoForm.ShowFocusDemo;
var
  I: Integer;
begin
  Perform(WM_UPDATEUISTATE, MakeWParam(UIS_CLEAR, UISF_HIDEFOCUS or UISF_HIDEACCEL), 0);
  for I := 0 to ComponentCount - 1 do
    if (Components[I] is TPPGButton) and TPPGButton(Components[I]).Showing and
      TPPGButton(Components[I]).Enabled then
    begin
      TPPGButton(Components[I]).SetFocus;
      Exit;
    end;
end;

function TDemoForm.EnableMica: Boolean;
const
  DWMWA_SYSTEMBACKDROP_TYPE = 38;
  DWMSBT_MAINWINDOW = 2; // Mica
var
  V: Integer;
begin
  // Prototyp (Phase 8.4): Glasrahmen ueber die ganze Flaeche (die VCL fuellt
  // ihn schwarz = durchsichtig), dann Mica als Hintergrund des DWM
  Result := CheckWin32Version(10) and (TOSVersion.Build >= 22621);
  if not Result then
  begin
    Log('Mica', 'erst ab Windows 11 22H2');
    Exit;
  end;
  GlassFrame.SheetOfGlass := True;
  GlassFrame.Enabled := True;
  V := DWMSBT_MAINWINDOW;
  Result := Succeeded(DwmSetWindowAttribute(Handle, DWMWA_SYSTEMBACKDROP_TYPE, @V, SizeOf(V)));
  TPPGTheme.SetDarkTitleBar(Handle, TPPGTheme.IsDark);
  Log('Mica', BoolToStr(Result, True));
end;

procedure WaitMs(Ms: Cardinal);
var
  Tick: Cardinal;
begin
  Tick := GetTickCount;
  while GetTickCount - Tick < Ms do
  begin
    Application.ProcessMessages;
    Sleep(15);
  end;
end;

procedure SaveScreenRect(const R: TRect; const FileName: string);
var
  Bmp: TBitmap;
  Png: TPngImage;
  DC: HDC;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(R.Right - R.Left, R.Bottom - R.Top);
    DC := GetDC(0);
    try
      BitBlt(Bmp.Canvas.Handle, 0, 0, Bmp.Width, Bmp.Height, DC, R.Left, R.Top, SRCCOPY);
    finally
      ReleaseDC(0, DC);
    end;
    Png := TPngImage.Create;
    try
      Png.Assign(Bmp);
      Png.SaveToFile(FileName);
    finally
      Png.Free;
    end;
  finally
    Bmp.Free;
  end;
end;

procedure TDemoForm.SaveDatePopupCapture(const FileName: string);
var
  C: TControl;
begin
  ShowPage(PgDates);
  SetForegroundWindow(Handle);
  C := SpecialControl('datepicker');
  if C is TPPGDatePicker then
  begin
    TPPGDatePicker(C).SetFocus;
    TPPGDatePicker(C).DropDown;
  end;
  WaitMs(800);
  SaveScreenCapture(FileName);
end;

procedure TDemoForm.SaveToastCapture(const FileName: string);
var
  WA: TRect;
begin
  FNotify.Duration := 0;
  FNotify.Show('Hinweis', L('Ein einfacher Toast.'), psInformational);
  FNotify.Show('Export fertig', L('Die Datei <b>Bericht.pdf</b> wurde erstellt.'), psSuccess, -1,
    [L('{Oe}ffnen'), 'Ordner']);
  FNotify.Show('Verbindung verloren', L('Der Server antwortet nicht.'), psError, 0, ['Erneut']);
  WaitMs(1200);
  WA := Screen.MonitorFromWindow(Handle).WorkareaRect;
  SaveScreenRect(Rect(WA.Right - 440, WA.Bottom - 520, WA.Right, WA.Bottom), FileName);
end;

procedure TDemoForm.SaveScreenCapture(const FileName: string);
var
  R: TRect;
begin
  Winapi.Windows.GetWindowRect(Handle, R);
  SaveScreenRect(R, FileName);
end;

procedure TDemoForm.SelfCheck(const AName: string; AOk: Boolean);
begin
  if AOk then
    FReport.Add('OK      ' + AName)
  else
  begin
    FReport.Add('FEHLER  ' + AName);
    Inc(FFailures);
  end;
end;

function TDemoForm.RunSelfTest(const FileName: string): Integer;
var
  I: Integer;
begin
  // Jede Seite loest ihre Szenarien ueber Mausnachrichten an die Controls aus
  // und prueft die sichtbaren Ergebnisse (Ergebniszeilen, Zustaende, Listen)
  FReport := TStringList.Create;
  try
    FFailures := 0;
    FNotify.Animations := False;
    for I := 0 to FPageObjects.Count - 1 do
    begin
      ShowPage(I);
      Application.ProcessMessages;
      try
        FPageObjects[I].SelfTest(SelfCheck);
      except
        on E: Exception do
          SelfCheck(Format('Seite %d: %s: %s', [I, E.ClassName, E.Message]), False);
      end;
      Application.ProcessMessages;
    end;
    FNotify.CloseAll;
    FReport.Add(Format('%d Pruefungen, %d Fehler', [FReport.Count, FFailures]));
    FReport.SaveToFile(FileName, TEncoding.UTF8);
  finally
    FreeAndNil(FReport);
  end;
  Result := FFailures;
end;

procedure PaintTree(Control: TWinControl; DC: HDC; X, Y: Integer);
var
  I: Integer;
  Child: TWinControl;
  Saved: Integer;
begin
  Saved := SaveDC(DC);
  try
    // Nur der Control selbst (inkl. TGraphicControls), Kinder danach einzeln
    SetWindowOrgEx(DC, -X, -Y, nil);
    Control.Perform(WM_ERASEBKGND, WPARAM(DC), 0);
    Control.Perform(WM_PAINT, WPARAM(DC), 0);
  finally
    RestoreDC(DC, Saved);
  end;
  for I := 0 to Control.ControlCount - 1 do
    if (Control.Controls[I] is TWinControl) and Control.Controls[I].Visible then
    begin
      Child := TWinControl(Control.Controls[I]);
      Child.PaintTo(DC, X + Child.Left, Y + Child.Top);
    end;
end;

procedure TDemoForm.SaveScreenshot(const FileName: string);
var
  Bmp: TBitmap;
  Png: TPngImage;
  P: TPoint;
  C: TControl;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(ClientWidth, ClientHeight);
    // Formular und jedes Kindfenster einzeln rendern (funktioniert auch ohne
    // komponierten Desktop, z.B. in Dienst-/Remote-Sitzungen und CI).
    // Lock: sonst gibt die VCL den Bitmap-DC nach der naechsten Nachricht
    // eines Kind-Controls frei (FreeMemoryContexts) und der Rest bleibt leer.
    Bmp.Canvas.Lock;
    try
      PaintTree(Self, Bmp.Canvas.Handle, 0, 0);
      // Offene Aufklappliste ist ein eigenes Fenster: an ihrer Stelle einzeichnen
      for C in FSpecial.Values do
        if (C is TPPGComboBox) and TPPGComboBox(C).DroppedDown then
        begin
          P := ScreenToClient(TPPGComboBox(C).PopupList.ClientToScreen(Point(0, 0)));
          TPPGComboBox(C).PopupList.PaintTo(Bmp.Canvas.Handle, P.X, P.Y);
        end;
    finally
      Bmp.Canvas.Unlock;
    end;
    Png := TPngImage.Create;
    try
      Png.Assign(Bmp);
      Png.SaveToFile(FileName);
    finally
      Png.Free;
    end;
  finally
    Bmp.Free;
  end;
end;

end.
