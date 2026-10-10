unit PPG.Tests.Phase14bRibbon;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 14b: das Control TPPGRibbon (Layout und Schrumpfen,
  Klicks und Actions, Registerkarten, Einklappen mit Popup, geschrumpfte
  Gruppe, Galerie, KeyTips, Tastaturbedienung, Schnellzugriff, Kontext-
  Registerkarten, Backstage, Screenreader, Streaming, Zeichnen). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Actions, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Menus, Vcl.ActnList,
  Vcl.Imaging.pngimage, PPG.Types, PPG.Accessibility, PPG.Render.Registry, PPG.Theme,
  PPG.Controls.Base, PPG.ComboBox, PPG.Panel, PPG.Items, PPG.Ribbon.Layout, PPG.Ribbon.Items,
  PPG.Ribbon, PPG.Lang, PPG.Tests.Controls;

type
  /// Menue, das nur mitschreibt (TPopupMenu.Popup waere modal).
  TRecordingMenu = class(TPopupMenu)
  public
    Count: Integer;
    LastPos: TPoint;
    procedure Popup(X, Y: Integer); override;
  end;

  TRibbonTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FVeto: Boolean;
    FMenu: TRecordingMenu;
    FCombo: TPPGComboBox;
    function NewRibbon: TPPGRibbon;
    function FindItem(R: TPPGRibbon; const ACaption: string): TPPGRibbonItem;
    procedure Click(C: TWinControl; const Pt: TPoint);
    procedure ItemOnClick(Sender: TObject);
    procedure ItemFreesSelf(Sender: TObject);
    procedure RibbonItemClick(Sender: TObject; Item: TPPGRibbonItem);
    procedure TabChanging(Sender: TObject; NewTab: TPPGRibbonTab; var AllowChange: Boolean);
    procedure TabChange(Sender: TObject);
    procedure GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
    procedure LauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
    procedure MinimizedChange(Sender: TObject);
    procedure QuickChange(Sender: TObject);
    procedure AppButtonClick(Sender: TObject);
    procedure BackstageChange(Sender: TObject);
    procedure ActionExecute(Sender: TObject);
    procedure Shot(C: TWinControl; const Name: string);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure CreateFreeAndDefaults;
    procedure HeightFollowsQatAndMinimized;
    procedure WideLayoutKeepsEverythingLarge;
    procedure NarrowLayoutShrinksRightToLeft;
    procedure EmbeddedControlFollowsLayout;
    procedure ClickRunsOnClickAndOnItemClick;
    procedure CheckAndGroupIndex;
    procedure ActionDrivesItem;
    procedure SplitButtonPartsAndMenu;
    procedure TabsByMouseAndCode;
    procedure HiddenActiveTabFallsBack;
    procedure MinimizedOpensTabPopup;
    procedure CollapsedGroupOpensPopup;
    procedure GalleryInlineAndPopup;
    procedure LauncherFiresEvent;
    procedure KeyTipLevels;
    procedure KeyTipsForSmallItemsAndGroups;
    procedure KeyboardNavigation;
    procedure QuickAccessCustomizing;
    procedure ContextMenuEntries;
    procedure ContextualTabs;
    procedure BackstageCoversForm;
    procedure AccessibleChildren;
    procedure StreamingRoundTrip;
    procedure RightToLeftMirrors;
    procedure LanguageSwitchRelayouts;
    procedure PaintsAllStates;
    procedure ManyItemsStayFast;
    procedure RemovedItemsAreReleased;
  end;

implementation

uses
  Winapi.oleacc, PPG.Tests.Visual, PPG.Exceptions;

type
  TPPGCustomControlAccess = class(TPPGCustomControl);

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

{ TRecordingMenu }

procedure TRecordingMenu.Popup(X, Y: Integer);
begin
  Inc(Count);
  LastPos := Point(X, Y);
end;

{ TRibbonTests }

procedure TRibbonTests.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FVeto := False;
  FForm.SetBounds(0, 0, 1200, 500);
  FMenu := TRecordingMenu.Create(FForm);
  FMenu.Items.Add(NewItem('Inhalte einfuegen', 0, False, True, nil, 0, ''));
end;

procedure TRibbonTests.TearDown;
begin
  FreeAndNil(FLog);
  inherited TearDown;
end;

procedure TRibbonTests.ItemOnClick(Sender: TObject);
begin
  FLog.Add('click:' + TPPGRibbonItem(Sender).Caption);
end;

procedure TRibbonTests.ItemFreesSelf(Sender: TObject);
begin
  FLog.Add('free:' + TPPGRibbonItem(Sender).Caption);
  TPPGRibbonItem(Sender).Free;
end;

procedure TRibbonTests.RemovedItemsAreReleased;
var
  R: TPPGRibbon;
  It: TPPGRibbonItem;
  GP: TPPGRibbonGalleryPopup;
begin
  // Audit 08.10.2026: OnItemClick bekam ein im OnClick freigegebenes Item;
  // eine offene Galerie zeigte nach dem Loeschen ihres Items ins Leere.
  R := NewRibbon;
  It := FindItem(R, 'Kopieren');
  It.OnClick := ItemFreesSelf;
  R.ClickItem(It);
  CheckEquals('free:Kopieren', FLog.CommaText, 'kein OnItemClick mit freigegebenem Item');
  CheckNull(FindItem(R, 'Kopieren'));
  FForm.Show;
  try
    R.Width := 1600;
    R.UpdateLayout;
    It := R.Tabs[0].Groups[3].Items[0];
    R.OpenGallery(It);
    GP := R.GalleryPopup;
    CheckTrue((GP <> nil) and GP.IsOpen);
    It.Free;
    CheckFalse(GP.IsOpen, 'Galerie mit dem Item geschlossen');
    RenderToBitmap(GP).Free;
    RenderToBitmap(R).Free;
  finally
    FForm.Hide;
  end;
end;

procedure TRibbonTests.RibbonItemClick(Sender: TObject; Item: TPPGRibbonItem);
begin
  FLog.Add('item:' + Item.Caption);
end;

procedure TRibbonTests.TabChanging(Sender: TObject; NewTab: TPPGRibbonTab; var AllowChange: Boolean);
begin
  FLog.Add('changing:' + NewTab.Caption);
  if FVeto then
    AllowChange := False;
end;

procedure TRibbonTests.TabChange(Sender: TObject);
begin
  FLog.Add('change:' + TPPGRibbon(Sender).ActiveTab.Caption);
end;

procedure TRibbonTests.GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
begin
  FLog.Add('gallery:' + IntToStr(Index));
end;

procedure TRibbonTests.LauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
begin
  FLog.Add('launcher:' + Group.Caption);
end;

procedure TRibbonTests.MinimizedChange(Sender: TObject);
begin
  FLog.Add('minimized:' + System.SysUtils.BoolToStr(TPPGRibbon(Sender).Minimized, True));
end;

procedure TRibbonTests.QuickChange(Sender: TObject);
begin
  FLog.Add('qat');
end;

procedure TRibbonTests.AppButtonClick(Sender: TObject);
begin
  FLog.Add('app');
end;

procedure TRibbonTests.BackstageChange(Sender: TObject);
begin
  FLog.Add('backstage:' + System.SysUtils.BoolToStr(TPPGRibbon(Sender).BackstageVisible, True));
end;

procedure TRibbonTests.ActionExecute(Sender: TObject);
begin
  FLog.Add('action:' + TAction(Sender).Caption);
end;

procedure TRibbonTests.Click(C: TWinControl; const Pt: TPoint);
begin
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Pt.X, Pt.Y));
  C.Perform(WM_LBUTTONUP, 0, MakeLParam(Pt.X, Pt.Y));
end;

function TRibbonTests.FindItem(R: TPPGRibbon; const ACaption: string): TPPGRibbonItem;
var
  T, G, I: Integer;
begin
  for T := 0 to R.Tabs.Count - 1 do
    for G := 0 to R.Tabs[T].Groups.Count - 1 do
      for I := 0 to R.Tabs[T].Groups[G].Items.Count - 1 do
        if R.Tabs[T].Groups[G].Items[I].Caption = ACaption then
          Exit(R.Tabs[T].Groups[G].Items[I]);
  Result := nil;
end;

function TRibbonTests.NewRibbon: TPPGRibbon;
var
  T: TPPGRibbonTab;
  G: TPPGRibbonGroup;
  It: TPPGRibbonItem;
  I: Integer;
begin
  Result := TPPGRibbon.Create(FForm);
  Result.Parent := FForm;
  Result.Animation.Enabled := False;
  // Breite frei waehlbar (mit alTop gehoert sie dem Formular)
  Result.Align := alNone;
  Result.Font.Name := 'Segoe UI';
  Result.Font.Height := -12;
  Result.OnItemClick := RibbonItemClick;
  Result.OnChanging := TabChanging;
  Result.OnChange := TabChange;
  Result.OnGalleryClick := GalleryClick;
  Result.OnLauncherClick := LauncherClick;
  Result.OnMinimizedChange := MinimizedChange;
  Result.OnQuickAccessChange := QuickChange;
  Result.OnApplicationButtonClick := AppButtonClick;
  Result.OnBackstageChange := BackstageChange;
  // Start
  T := Result.Tabs.AddTab('Start');
  G := T.Groups.AddGroup('Zwischenablage');
  G.ShowLauncher := True;
  It := G.Items.AddButton('Einf'#$00FC'gen', $E77F, rsLarge, ItemOnClick);
  It.Kind := rikSplitButton;
  It.DropDownMenu := FMenu;
  G.Items.AddButton('Ausschneiden', $E8C6, rsMedium, ItemOnClick);
  G.Items.AddButton('Kopieren', $E8C8, rsMedium, ItemOnClick);
  G.Items.AddButton('Format '#$00FC'bertragen', $E8DC, rsMedium, ItemOnClick);
  G := T.Groups.AddGroup('Schriftart');
  FCombo := TPPGComboBox.Create(FForm);
  FCombo.Width := 140;
  FCombo.Items.Add('Segoe UI');
  It := G.Items.Add;
  It.Control := FCombo;
  G.Items.AddCheck('Fett', $E8DD).OnClick := ItemOnClick;
  It := G.Items.AddCheck('Kursiv', $E8DB);
  It.OnClick := ItemOnClick;
  It.SameRow := True;
  It := G.Items.AddCheck('Unterstrichen', $E8DC);
  It.OnClick := ItemOnClick;
  It.SameRow := True;
  G := T.Groups.AddGroup('Absatz');
  G.Items.AddCheck('Links', $E8E4, rsSmall, 1).Down := True;
  G.Items.AddCheck('Zentriert', $E8E3, rsSmall, 1);
  G.Items.AddCheck('Rechts', $E8E2, rsSmall, 1);
  G.Items.AddButton('Aufz'#$00E4'hlung', $E8FD, rsMedium);
  G.Items.AddButton('Nummerierung', $E9D5, rsMedium);
  G.Items.AddButton('Einzug', $E8E5, rsMedium);
  G := T.Groups.AddGroup('Formatvorlagen');
  It := G.Items.Add;
  It.Kind := rikGallery;
  It.Caption := 'Formatvorlagen';
  It.GalleryColumns := 4;
  for I := 1 to 14 do
    It.GalleryItems.Add('Vorlage ' + IntToStr(I));
  G := T.Groups.AddGroup('Bearbeiten');
  G.Items.AddButton('Suchen', $E721, rsMedium, ItemOnClick);
  G.Items.AddButton('Ersetzen', $E8AB, rsMedium, ItemOnClick);
  G.Items.AddButton('Markieren', $E8B3, rsMedium, ItemOnClick);
  // Einfuegen
  T := Result.Tabs.AddTab('Einf'#$00FC'gen');
  G := T.Groups.AddGroup('Tabellen');
  G.Items.AddButton('Tabelle', $E80A, rsLarge, ItemOnClick);
  G := T.Groups.AddGroup('Illustrationen');
  G.Items.AddButton('Bilder', $EB9F, rsLarge, ItemOnClick);
  G.Items.AddButton('Formen', $E7B8, rsLarge, ItemOnClick);
  // Ansicht und Kontext
  T := Result.Tabs.AddTab('Ansicht');
  T.Groups.AddGroup('Zoom').Items.AddButton('Zoom', $E71E, rsLarge, ItemOnClick);
  T := Result.Tabs.AddTab('Entwurf');
  T.ContextName := 'Tabellentools';
  T.ContextColor := $00309030;
  T.Visible := False;
  T.Groups.AddGroup('Formatvorlagen').Items.AddButton('Raster', $E80A, rsLarge, ItemOnClick);
  Result.Width := FForm.ClientWidth;
  Result.UpdateLayout;
end;

procedure TRibbonTests.Shot(C: TWinControl; const Name: string);
var
  B: TBitmap;
  Png: TPngImage;
  Dir: string;
begin
  B := RenderToBitmap(C);
  try
    CheckEquals(0, FErrors.Count, 'Fehler beim Zeichnen: ' + FErrors.Text);
    PPGCheckPainted(Self, B, 'Ribbon ' + Name); // Audit 11b
    Dir := GetEnvironmentVariable('PPG_SHOTS');
    if Dir <> '' then
    begin
      Png := TPngImage.Create;
      try
        Png.Assign(B);
        Png.SaveToFile(IncludeTrailingPathDelimiter(Dir) + 'ribbon-' + Name + '.png');
      finally
        Png.Free;
      end;
    end;
  finally
    B.Free;
  end;
end;

procedure TRibbonTests.CreateFreeAndDefaults;
var
  R: TPPGRibbon;
begin
  R := TPPGRibbon.Create(nil);
  try
    CheckTrue(R.Align = alTop);
    CheckTrue(R.AutoSize);
    CheckEquals(0, R.TabIndex);
    CheckFalse(R.Minimized);
    CheckTrue(R.ShowQuickAccess);
    CheckTrue(R.QuickAccessCustomizable);
    CheckTrue(R.ShowApplicationButton);
    CheckTrue(R.KeyTipsEnabled);
    CheckTrue(R.QuickAccessPosition = qapAbove);
    CheckTrue(R.ActiveTab = nil);
    // ohne Parent: Layout rechnet trotzdem
    R.Tabs.AddTab('A').Groups.AddGroup('G').Items.AddButton('X');
    CheckTrue(R.ActiveTab <> nil);
    CheckEquals(1, R.GroupCount);
  finally
    R.Free;
  end;
  // ungueltige Werte
  R := NewRibbon;
  try
    R.TabIndex := 9;
    Fail('TabIndex 9 muss werfen');
  except
    on E: EPPGPropertyError do
      CheckEquals(0, R.TabIndex, 'unveraendert');
  end;
  try
    R.Tabs[0].Groups[3].Items[0].GalleryColumns := 0;
    Fail('GalleryColumns 0 muss werfen');
  except
    on E: EPPGPropertyError do
      CheckEquals(4, R.Tabs[0].Groups[3].Items[0].GalleryColumns);
  end;
  try
    R.Backstage := R;
    Fail('Backstage = Ribbon muss werfen');
  except
    on E: EPPGPropertyError do
      CheckTrue(R.Backstage = nil);
  end;
end;

procedure TRibbonTests.HeightFollowsQatAndMinimized;
var
  R: TPPGRibbon;
  Full, Mini, NoQat: Integer;
begin
  R := NewRibbon;
  Full := R.Height;
  CheckTrue(Full > 100, 'Band mit drei Zeilen: ' + IntToStr(Full));
  CheckFalse(IsRectEmpty(R.QuickCustomizeRect), 'Anpassen-Knopf');
  CheckTrue(R.QuickCustomizeRect.Bottom <= R.TabRect(0).Top, 'Schnellzugriff oben');
  R.Minimized := True;
  Mini := R.Height;
  CheckTrue(Mini < Full - 60, 'eingeklappt');
  CheckTrue(IsRectEmpty(R.PanelRect));
  CheckEquals(0, FLog.Count, 'Code loest kein Ereignis aus');
  R.Minimized := False;
  CheckEquals(Full, R.Height);
  R.ShowQuickAccess := False;
  NoQat := R.Height;
  CheckTrue(NoQat < Full, 'ohne Schnellzugriff niedriger');
  R.ShowQuickAccess := True;
  R.QuickAccessPosition := qapBelow;
  CheckEquals(Full, R.Height);
  CheckTrue(R.QuickCustomizeRect.Top >= R.PanelRect.Bottom, 'unter dem Band');
end;

procedure TRibbonTests.WideLayoutKeepsEverythingLarge;
var
  R: TPPGRibbon;
  G: Integer;
  Ins, Cut, Copy, Fett: TPPGRibbonItem;
begin
  R := NewRibbon;
  R.Width := 1600;
  R.UpdateLayout;
  CheckEquals(5, R.GroupCount);
  for G := 0 to R.GroupCount - 1 do
    CheckTrue(R.GroupState(G) = rgsLarge, 'Gruppe ' + IntToStr(G));
  Ins := FindItem(R, 'Einf'#$00FC'gen');
  Cut := FindItem(R, 'Ausschneiden');
  Copy := FindItem(R, 'Kopieren');
  Fett := FindItem(R, 'Fett');
  CheckTrue(R.ItemSize(Ins) = rsLarge);
  CheckTrue(R.ItemSize(Cut) = rsMedium);
  CheckTrue(R.ItemSize(Fett) = rsSmall);
  // gross ueber die volle Hoehe, kleine stapeln sich
  CheckTrue(R.ItemRect(Ins).Bottom - R.ItemRect(Ins).Top > 2 * (R.ItemRect(Cut).Bottom - R.ItemRect(Cut).Top));
  CheckEquals(R.ItemRect(Cut).Left, R.ItemRect(Copy).Left, 'gleiche Spalte');
  CheckEquals(R.ItemRect(Cut).Bottom, R.ItemRect(Copy).Top, 'untereinander');
  CheckTrue(R.ItemRect(Cut).Left > R.ItemRect(Ins).Right - 1);
  // Gruppen liegen nebeneinander im Band
  for G := 1 to R.GroupCount - 1 do
    CheckTrue(R.GroupRect(G).Left >= R.GroupRect(G - 1).Right);
  CheckTrue(R.GroupRect(0).Top >= R.PanelRect.Top);
  CheckTrue(R.GroupRect(0).Bottom <= R.PanelRect.Bottom);
end;

procedure TRibbonTests.NarrowLayoutShrinksRightToLeft;
var
  R, Q: TPPGRibbon;
  G, Last, Collapsed: Integer;
  Grp: TPPGRibbonGroup;
begin
  R := NewRibbon;
  R.Width := 1600;
  R.UpdateLayout;
  Last := R.GroupRect(R.GroupCount - 1).Right;
  // etwas zu schmal: "Bearbeiten" (nur mittlere Items) gewinnt mit "mittel"
  // nichts, also schrumpft die Galerie daneben; links bleibt alles gross
  R.Width := Last - 20;
  R.UpdateLayout;
  CheckTrue(R.GroupState(4) = rgsLarge, 'Schritt ohne Gewinn uebersprungen');
  CheckTrue(R.GroupState(3) = rgsMedium, 'Galerie mit halber Spaltenzahl');
  CheckTrue(R.GroupState(0) = rgsLarge, 'linke bleibt');
  CheckTrue(R.GroupRect(R.GroupCount - 1).Right <= R.Width, 'passt');
  // sehr schmal: Dropdowns
  R.Width := 300;
  R.UpdateLayout;
  Collapsed := 0;
  for G := 0 to R.GroupCount - 1 do
    if R.GroupState(G) = rgsCollapsed then
      Inc(Collapsed);
  CheckTrue(Collapsed >= 2, 'Gruppen als Dropdown');
  CheckTrue(IsRectEmpty(R.ItemRect(FindItem(R, 'Ausschneiden'))) or
    (R.GroupState(0) <> rgsCollapsed), 'Items einer geschrumpften Gruppe sind nicht im Band');
  // ReduceOrder: zwei gleiche Gruppen mit grossen Buttons
  Q := TPPGRibbon.Create(FForm);
  Q.Parent := FForm;
  Q.Align := alNone;
  Q.Animation.Enabled := False;
  for G := 0 to 1 do
  begin
    if Q.Tabs.Count = 0 then
      Q.Tabs.AddTab('T');
    Grp := Q.Tabs[0].Groups.AddGroup('G' + IntToStr(G));
    Grp.Items.AddButton('Eins', $E700);
    Grp.Items.AddButton('Zwei', $E701);
    Grp.Items.AddButton('Drei', $E702);
  end;
  Q.Width := 1000;
  Q.UpdateLayout;
  Last := Q.GroupRect(1).Right;
  Q.Width := Last - 10;
  Q.UpdateLayout;
  CheckTrue(Q.GroupState(1) = rgsMedium, 'ohne ReduceOrder: rechts zuerst');
  CheckTrue(Q.GroupState(0) = rgsLarge);
  Q.Tabs[0].Groups[0].ReduceOrder := -1;
  Q.UpdateLayout;
  CheckTrue(Q.GroupState(0) = rgsMedium, 'ReduceOrder -1 schrumpft zuerst');
  CheckTrue(Q.GroupState(1) = rgsLarge);
end;

procedure TRibbonTests.EmbeddedControlFollowsLayout;
var
  R: TPPGRibbon;
  IR: TRect;
  It: TPPGRibbonItem;
begin
  R := NewRibbon;
  R.Width := 1600;
  R.UpdateLayout;
  CheckSame(R, FCombo.Parent, 'Ribbon ist Parent');
  It := R.Tabs[0].Groups[1].Items[0];
  CheckTrue(It.Kind = rikControl, 'Art folgt aus Control');
  IR := R.ItemRect(It);
  CheckFalse(IsRectEmpty(IR));
  CheckEquals(IR.Left, FCombo.Left);
  CheckTrue(FCombo.Visible);
  CheckTrue((FCombo.Top >= IR.Top) and (FCombo.Top + FCombo.Height <= IR.Bottom + 1));
  // andere Registerkarte: verborgen
  R.TabIndex := 1;
  R.UpdateLayout;
  CheckFalse(FCombo.Visible, 'verborgen auf anderer Karte');
  R.TabIndex := 0;
  R.UpdateLayout;
  CheckTrue(FCombo.Visible);
  // Gruppe geschrumpft: verborgen
  R.Width := 300;
  R.UpdateLayout;
  CheckTrue(R.GroupState(1) = rgsCollapsed);
  CheckFalse(FCombo.Visible, 'Gruppe als Dropdown');
  // Item.Enabled gilt fuer das Control
  It.Enabled := False;
  CheckFalse(FCombo.Enabled);
  // Control freigegeben: Referenz wird geloescht
  FCombo.Free;
  FCombo := nil;
  CheckTrue(It.Control = nil);
end;

procedure TRibbonTests.ClickRunsOnClickAndOnItemClick;
var
  R: TPPGRibbon;
  It: TPPGRibbonItem;
begin
  R := NewRibbon;
  It := FindItem(R, 'Kopieren');
  Click(R, Center(R.ItemRect(It)));
  CheckEquals(2, FLog.Count, FLog.Text);
  CheckEquals('click:Kopieren', FLog[0]);
  CheckEquals('item:Kopieren', FLog[1]);
  // Druecken, wegziehen, loslassen: nichts
  FLog.Clear;
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(R.ItemRect(It)).X, Center(R.ItemRect(It)).Y));
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(R.TabRect(1)).X, Center(R.TabRect(1)).Y));
  CheckEquals(0, FLog.Count, 'abgebrochen');
  // deaktiviert
  It.Enabled := False;
  Click(R, Center(R.ItemRect(It)));
  CheckEquals(0, FLog.Count, 'deaktiviert');
  R.ClickItem(It);
  CheckEquals(0, FLog.Count);
  It.Enabled := True;
  R.ClickItem(It);
  CheckEquals(2, FLog.Count);
  // Hover wird gemerkt, Mausverlassen loescht ihn
  R.Perform(WM_MOUSEMOVE, 0, MakeLParam(Center(R.ItemRect(It)).X, Center(R.ItemRect(It)).Y));
  CheckTrue(R.HotHit.Part = rpItem);
  R.Perform(CM_MOUSELEAVE, 0, 0);
  CheckTrue(R.HotHit.Part = rpNone);
end;

procedure TRibbonTests.CheckAndGroupIndex;
var
  R: TPPGRibbon;
  Fett, Links, Zentriert: TPPGRibbonItem;
begin
  R := NewRibbon;
  Fett := FindItem(R, 'Fett');
  Click(R, Center(R.ItemRect(Fett)));
  CheckTrue(Fett.Down, 'umgeschaltet');
  Click(R, Center(R.ItemRect(Fett)));
  CheckFalse(Fett.Down, 'zurueck');
  Links := FindItem(R, 'Links');
  Zentriert := FindItem(R, 'Zentriert');
  CheckTrue(Links.Down);
  Click(R, Center(R.ItemRect(Zentriert)));
  CheckTrue(Zentriert.Down);
  CheckFalse(Links.Down, 'Gruppe: einer gilt');
  Click(R, Center(R.ItemRect(Zentriert)));
  CheckTrue(Zentriert.Down, 'Klick auf den eingerasteten rastet nicht aus');
  // Code: Down ohne Ereignis
  FLog.Clear;
  Links.Down := True;
  CheckFalse(Zentriert.Down);
  CheckEquals(0, FLog.Count);
end;

procedure TRibbonTests.ActionDrivesItem;
var
  R: TPPGRibbon;
  AL: TActionList;
  A: TAction;
  It: TPPGRibbonItem;
begin
  R := NewRibbon;
  AL := TActionList.Create(FForm);
  A := TAction.Create(FForm);
  A.ActionList := AL;
  A.Caption := 'Speichern';
  A.Hint := 'Dokument speichern';
  A.OnExecute := ActionExecute;
  It := R.Tabs[1].Groups[0].Items.Add;
  It.Action := A;
  CheckEquals('Speichern', It.Caption);
  CheckEquals('Dokument speichern', It.Hint);
  R.TabIndex := 1;
  R.UpdateLayout;
  Click(R, Center(R.ItemRect(It)));
  CheckEquals('action:Speichern', FLog[0]);
  CheckEquals('item:Speichern', FLog[1]);
  A.Enabled := False;
  CheckFalse(It.Enabled, 'Action -> Item');
  A.Caption := 'Sichern';
  CheckEquals('Sichern', It.Caption);
  A.Enabled := True;
  // AutoCheck-Action macht das Item zum Umschalt-Button
  A.AutoCheck := True;
  It.Action := nil;
  It.Kind := rikButton;
  It.Action := A;
  CheckTrue(It.Kind = rikCheck);
  FLog.Clear;
  R.ClickItem(It);
  CheckTrue(A.Checked, 'AutoCheck schaltet die Action');
  CheckTrue(It.Down, 'Item folgt');
  // Action freigeben
  A.Free;
  CheckTrue(It.Action = nil);
  R.InitiateAction;
end;

procedure TRibbonTests.SplitButtonPartsAndMenu;
var
  R: TPPGRibbon;
  It: TPPGRibbonItem;
  IR: TRect;
  H: TPPGRibbonHit;
begin
  R := NewRibbon;
  It := FindItem(R, 'Einf'#$00FC'gen');
  IR := R.ItemRect(It);
  H := R.HitTest(Center(IR).X, IR.Top + 10);
  CheckTrue(H.Part = rpItem, 'oberer Teil: Befehl');
  H := R.HitTest(Center(IR).X, IR.Bottom - 6);
  CheckTrue(H.Part = rpItemArrow, 'unterer Teil: Menue');
  // Klick auf den Befehl
  Click(R, Point(Center(IR).X, IR.Top + 10));
  CheckEquals('click:Einf'#$00FC'gen', FLog[0]);
  CheckEquals(0, FMenu.Count);
  // Druecken auf den Pfeil oeffnet das Menue sofort (unter dem Button)
  FLog.Clear;
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(IR).X, IR.Bottom - 6));
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(IR).X, IR.Bottom - 6));
  CheckEquals(1, FMenu.Count);
  CheckEquals(0, FLog.Count, 'kein OnClick');
  CheckEquals(R.ClientToScreen(Point(IR.Left, IR.Bottom)).Y, FMenu.LastPos.Y);
  // Button mit Menue (kein Split): Klick klappt auf
  It := FindItem(R, 'Suchen');
  It.DropDownMenu := FMenu;
  R.UpdateLayout;
  FLog.Clear;
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(R.ItemRect(It)).X, Center(R.ItemRect(It)).Y));
  CheckEquals(2, FMenu.Count);
  CheckEquals('click:Suchen', FLog[0], 'OnClick vor dem Menue');
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(R.ItemRect(It)).X, Center(R.ItemRect(It)).Y));
  CheckEquals(2, FLog.Count, 'Loslassen loest nicht noch einmal aus');
  // Menue freigeben
  FMenu.Free;
  FMenu := nil;
  CheckTrue(It.DropDownMenu = nil);
end;

procedure TRibbonTests.TabsByMouseAndCode;
var
  R: TPPGRibbon;
begin
  R := NewRibbon;
  Click(R, Center(R.TabRect(1)));
  CheckEquals(1, R.TabIndex);
  CheckEquals('changing:Einf'#$00FC'gen', FLog[0]);
  CheckEquals('change:Einf'#$00FC'gen', FLog[1]);
  CheckEquals(2, R.GroupCount, 'Gruppen der neuen Karte');
  FLog.Clear;
  FVeto := True;
  Click(R, Center(R.TabRect(2)));
  CheckEquals(1, R.TabIndex, 'abgelehnt');
  CheckEquals(1, FLog.Count);
  FVeto := False;
  FLog.Clear;
  R.TabIndex := 2;
  CheckEquals(0, FLog.Count, 'Code ohne Ereignisse');
  CheckEquals('Ansicht', R.ActiveTab.Caption);
  // unsichtbare Karte hat kein Rechteck
  CheckTrue(IsRectEmpty(R.TabRect(3)));
end;

procedure TRibbonTests.HiddenActiveTabFallsBack;
var
  R: TPPGRibbon;
begin
  R := NewRibbon;
  R.TabIndex := 1;
  R.Tabs[1].Visible := False;
  CheckEquals('Start', R.ActiveTab.Caption, 'erste sichtbare');
  R.Tabs[1].Visible := True;
  CheckEquals('Einf'#$00FC'gen', R.ActiveTab.Caption);
  // Karten loeschen
  R.Tabs.Clear;
  CheckTrue(R.ActiveTab = nil);
  CheckEquals(0, R.GroupCount);
  R.Repaint;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TRibbonTests.MinimizedOpensTabPopup;
var
  R: TPPGRibbon;
  It: TPPGRibbonItem;
  P: TPPGRibbonPanelPopup;
  G, I: Integer;
  IR: TRect;
begin
  R := NewRibbon;
  FForm.Show;
  R.Minimized := True;
  R.UpdateLayout;
  CheckEquals(0, R.GroupCount, 'kein Band');
  CheckTrue(FCombo.Parent = R);
  CheckFalse(FCombo.Visible, 'Control verborgen');
  // Klick auf die Karte: Popup mit der ganzen Karte
  Click(R, Center(R.TabRect(0)));
  P := R.PanelPopup;
  CheckTrue((P <> nil) and P.IsOpen, 'Popup offen');
  CheckEquals(5, P.View.GroupCount);
  CheckSame(P, FCombo.Parent, 'Control wandert ins Popup');
  CheckTrue(FCombo.Visible);
  CheckTrue(IsWindowVisible(FCombo.Handle), 'Fenster wirklich sichtbar (Band-Popup)');
  CheckEquals(R.ClientToScreen(Point(0, R.Height)).Y, P.Top, 'unter der Kartenzeile');
  // Klick auf ein Item im Popup: ausloesen und schliessen
  It := FindItem(R, 'Kopieren');
  IR := Rect(0, 0, 0, 0);
  for G := 0 to P.View.GroupCount - 1 do
    for I := 0 to High(P.View.Groups[G].Items) do
      if P.View.Groups[G].Items[I] = It then
        IR := P.View.Groups[G].Places[I].Bounds;
  CheckFalse(IsRectEmpty(IR));
  Click(P, Center(IR));
  CheckEquals('click:Kopieren', FLog[0]);
  CheckFalse(P.IsOpen, 'nach dem Befehl zu');
  CheckSame(R, FCombo.Parent, 'Control zurueck');
  // zweiter Klick auf dieselbe Karte schliesst
  Click(R, Center(R.TabRect(0)));
  CheckTrue(P.IsOpen);
  Click(R, Center(R.TabRect(0)));
  CheckFalse(P.IsOpen, 'Umschalten');
  // andere Karte: Popup mit deren Gruppen
  Click(R, Center(R.TabRect(1)));
  CheckTrue(P.IsOpen);
  CheckEquals(2, P.View.GroupCount);
  CheckEquals(1, R.TabIndex);
  R.ClosePopups;
  CheckFalse(P.IsOpen);
  // Doppelklick klappt wieder aus
  FLog.Clear;
  R.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, MakeLParam(Center(R.TabRect(1)).X, Center(R.TabRect(1)).Y));
  CheckFalse(R.Minimized);
  CheckEquals('minimized:False', FLog[FLog.Count - 1]);
  // Einklapp-Knopf
  Click(R, Center(R.MinimizeButtonRect));
  CheckTrue(R.Minimized);
  FForm.Hide;
end;

procedure TRibbonTests.CollapsedGroupOpensPopup;
var
  R: TPPGRibbon;
  P: TPPGRibbonPanelPopup;
  G, I, Place: Integer;
  IR: TRect;
begin
  R := NewRibbon;
  FForm.Show;
  R.Width := 200;
  R.UpdateLayout;
  // die Gruppe "Zwischenablage" (grosser Split-Button) wird zum Dropdown
  Place := R.GroupPlaceOf(R.Tabs[0].Groups[0]);
  CheckTrue(R.GroupState(Place) = rgsCollapsed, 'Zwischenablage als Dropdown');
  CheckTrue(R.HitTest(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y).Part = rpGroup);
  // Druecken oeffnet das Popup mit der voll aufgeklappten Gruppe
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  P := R.GroupPopup;
  CheckTrue((P <> nil) and P.IsOpen, 'Popup offen');
  CheckEquals(1, P.View.GroupCount);
  CheckTrue(P.View.Groups[0].State = rgsLarge);
  CheckEquals(R.ClientToScreen(R.GroupRect(Place).BottomRight).Y, P.Top, 'unter der Gruppe');
  IR := Rect(0, 0, 0, 0);
  for G := 0 to P.View.GroupCount - 1 do
    for I := 0 to High(P.View.Groups[G].Items) do
      if P.View.Groups[G].Items[I].Caption = 'Kopieren' then
        IR := P.View.Groups[G].Places[I].Bounds;
  Click(P, Center(IR));
  CheckEquals('click:Kopieren', FLog[0]);
  CheckFalse(P.IsOpen);
  // zweiter Druck auf die Gruppe schliesst ihr Popup wieder
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  CheckTrue(P.IsOpen);
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  CheckFalse(P.IsOpen, 'zweiter Druck schliesst');
  // Schriftart (mit Control) als Popup: Control wandert mit
  Place := R.GroupPlaceOf(R.Tabs[0].Groups[1]);
  CheckTrue(R.GroupState(Place) = rgsCollapsed, 'Schriftart als Dropdown');
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Center(R.GroupRect(Place)).X, Center(R.GroupRect(Place)).Y));
  CheckSame(P, FCombo.Parent);
  CheckTrue(FCombo.Visible);
  CheckTrue(IsWindowVisible(FCombo.Handle), 'Fenster wirklich sichtbar (Gruppen-Popup)');
  R.ClosePopups;
  CheckSame(R, FCombo.Parent);
  CheckFalse(FCombo.Visible);
  FForm.Hide;
end;

procedure TRibbonTests.GalleryInlineAndPopup;
var
  R: TPPGRibbon;
  It: TPPGRibbonItem;
  IR: TRect;
  H: TPPGRibbonHit;
  X, Y: Integer;
  GP: TPPGRibbonGalleryPopup;
begin
  R := NewRibbon;
  FForm.Show;
  R.Width := 1600;
  R.UpdateLayout;
  It := R.Tabs[0].Groups[3].Items[0];
  IR := R.ItemRect(It);
  CheckFalse(IsRectEmpty(IR));
  // erste Kachel
  H := R.HitTest(IR.Left + 10, Center(IR).Y);
  CheckTrue(H.Part = rpGalleryTile);
  CheckEquals(0, H.Tile);
  Click(R, Point(IR.Left + 10, Center(IR).Y));
  CheckEquals(0, It.GalleryIndex);
  CheckEquals('gallery:0', FLog[0]);
  // Blaetterleiste rechts: unten = aufklappen, Mitte = naechste Zeile
  X := IR.Right - 6;
  Y := IR.Bottom - 6;
  CheckTrue(R.HitTest(X, Y).Part = rpGalleryMore);
  CheckTrue(R.HitTest(X, Center(IR).Y).Part = rpGalleryDown);
  CheckTrue(R.HitTest(X, IR.Top + 6).Part = rpGalleryUp);
  Click(R, Point(X, Center(IR).Y));
  CheckEquals(1, It.GalleryTopRow, 'eine Zeile weiter');
  H := R.HitTest(IR.Left + 10, Center(IR).Y);
  CheckEquals(4, H.Tile, 'erste Kachel der zweiten Zeile');
  Click(R, Point(X, IR.Top + 6));
  CheckEquals(0, It.GalleryTopRow);
  // aufklappen
  R.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(X, Y));
  GP := R.GalleryPopup;
  CheckTrue((GP <> nil) and GP.IsOpen);
  CheckEquals(5, GP.Columns, 'GalleryColumns + 1');
  CheckEquals(0, GP.FocusIndex, 'Fokus auf dem gewaehlten');
  // Tastatur in der offenen Galerie
  GP.HandleKey(VK_RIGHT);
  GP.HandleKey(VK_DOWN);
  CheckEquals(6, GP.FocusIndex);
  GP.HandleKey(VK_END);
  CheckEquals(13, GP.FocusIndex);
  GP.HandleKey(VK_RETURN);
  CheckEquals(13, It.GalleryIndex);
  CheckFalse(GP.IsOpen);
  CheckEquals('gallery:13', FLog[FLog.Count - 1]);
  // Maus in der offenen Galerie
  R.OpenGallery(It);
  CheckTrue(GP.IsOpen);
  Click(GP, Center(GP.TileRect(2)));
  CheckEquals(2, It.GalleryIndex);
  CheckFalse(GP.IsOpen);
  // Esc schliesst ohne Auswahl
  R.OpenGallery(It);
  GP.HandleKey(VK_ESCAPE);
  CheckFalse(GP.IsOpen);
  CheckEquals(2, It.GalleryIndex);
  // geschrumpft: Galerie als Dropdown-Button
  R.Width := 300;
  R.UpdateLayout;
  X := R.GroupPlaceOf(R.Tabs[0].Groups[3]);
  CheckTrue(R.GroupState(X) in [rgsSmall, rgsCollapsed], 'geschrumpft');
  if R.GroupState(X) = rgsSmall then
  begin
    CheckTrue(R.ItemSize(It) = rsSmall, 'Galerie als Dropdown-Button');
    CheckTrue(R.HitTest(Center(R.ItemRect(It)).X, Center(R.ItemRect(It)).Y).Part = rpGalleryMore);
  end;
  FForm.Hide;
end;

procedure TRibbonTests.LauncherFiresEvent;
var
  R: TPPGRibbon;
  H: TPPGRibbonHit;
begin
  R := NewRibbon;
  R.Width := 1600;
  R.UpdateLayout;
  H := R.HitTest(R.GroupRect(0).Right - 6, R.GroupRect(0).Bottom - 6);
  CheckTrue(H.Part = rpLauncher, 'Startknopf unten rechts');
  Click(R, Point(R.GroupRect(0).Right - 6, R.GroupRect(0).Bottom - 6));
  CheckEquals('launcher:Zwischenablage', FLog[0]);
end;

procedure TRibbonTests.KeyTipLevels;
var
  R: TPPGRibbon;
  I, Start, Ins: Integer;
  Tip: string;
  It: TPPGRibbonItem;
begin
  R := NewRibbon;
  FForm.Show;
  R.ApplicationButtonCaption := 'Datei';
  R.ShowKeyTips;
  CheckEquals(1, R.KeyTipLevel);
  CheckTrue(R.KeyTipOverlayCount >= 1, 'Overlay-Fenster');
  // Datei, drei sichtbare Karten
  CheckEquals(4, R.KeyTipCount);
  CheckTrue(R.KeyTipHit(0).Part = rpAppButton);
  Start := -1;
  Ins := -1;
  for I := 0 to R.KeyTipCount - 1 do
    if R.KeyTipHit(I).Part = rpTab then
      if R.KeyTipHit(I).Index = 0 then
        Start := I
      else if R.KeyTipHit(I).Index = 1 then
        Ins := I;
  CheckEquals('S', R.KeyTipText(Start));
  CheckTrue((R.KeyTipText(Ins) <> '') and (R.KeyTipText(Ins) <> 'S'));
  CheckEquals('D', R.KeyTipText(0), 'Datei');
  // Karte "Einfuegen" waehlen: zweite Ebene mit deren Befehlen
  R.HandleKeyTipChar(R.KeyTipText(Ins)[1]);
  CheckEquals(1, R.TabIndex);
  CheckEquals(2, R.KeyTipLevel);
  CheckEquals(3, R.KeyTipCount, 'Tabelle, Bilder, Formen');
  // Esc: zurueck auf die oberste Ebene
  R.HandleKeyTipKey(VK_ESCAPE);
  CheckEquals(1, R.KeyTipLevel);
  CheckEquals(4, R.KeyTipCount);
  R.HandleKeyTipChar('s');
  CheckEquals(0, R.TabIndex);
  CheckEquals(2, R.KeyTipLevel);
  // Befehl per KeyTip
  It := FindItem(R, 'Kopieren');
  Tip := '';
  for I := 0 to R.KeyTipCount - 1 do
    if (R.KeyTipHit(I).Part = rpItem) and (R.KeyTipHit(I).View.Groups[R.KeyTipHit(I).Index].Items[
      R.KeyTipHit(I).Item] = It) then
      Tip := R.KeyTipText(I);
  CheckTrue(Tip <> '', 'KeyTip fuer Kopieren');
  FLog.Clear;
  for I := 1 to Length(Tip) do
    R.HandleKeyTipChar(Tip[I]);
  CheckEquals('click:Kopieren', FLog[0]);
  CheckEquals(0, R.KeyTipLevel, 'ausgeloest: KeyTips weg');
  CheckEquals(0, R.KeyTipOverlayCount);
  // eigener KeyTip
  R.Tabs[2].KeyTip := 'W';
  R.ShowKeyTips;
  R.HandleKeyTipChar('w');
  CheckEquals(2, R.TabIndex);
  // unbekannter Buchstabe: bleibt auf der Ebene
  R.HandleKeyTipKey(VK_ESCAPE);
  CheckFalse(R.HandleKeyTipChar('#'));
  CheckEquals(1, R.KeyTipLevel);
  // Esc auf der obersten Ebene beendet
  R.HandleKeyTipKey(VK_ESCAPE);
  CheckEquals(0, R.KeyTipLevel);
  FForm.Hide;
end;

procedure TRibbonTests.KeyTipsForSmallItemsAndGroups;
var
  R: TPPGRibbon;
  I, Grp: Integer;
  Seen: TStringList;
begin
  R := NewRibbon;
  FForm.Show;
  R.Width := 420;
  R.UpdateLayout;
  R.ShowKeyTips;
  R.HandleKeyTipChar('s');
  CheckEquals(2, R.KeyTipLevel);
  Seen := TStringList.Create;
  try
    Grp := -1;
    for I := 0 to R.KeyTipCount - 1 do
    begin
      CheckTrue(Seen.IndexOf(R.KeyTipText(I)) < 0, 'eindeutig: ' + R.KeyTipText(I));
      Seen.Add(R.KeyTipText(I));
      if (R.KeyTipHit(I).Part = rpGroup) and (Grp < 0) then
        Grp := I;
    end;
    CheckTrue(Grp >= 0, 'geschrumpfte Gruppe hat einen KeyTip');
    // Gruppe per KeyTip: Popup und dritte Ebene
    for I := 1 to Length(R.KeyTipText(Grp)) do
      R.HandleKeyTipChar(R.KeyTipText(Grp)[I]);
    CheckEquals(3, R.KeyTipLevel);
    CheckTrue(R.GroupPopup.IsOpen);
    CheckTrue(R.KeyTipCount > 0);
    CheckTrue(R.KeyTipHit(0).View = R.GroupPopup.View, 'Plaketten im Popup');
    R.HandleKeyTipKey(VK_ESCAPE);
    CheckEquals(2, R.KeyTipLevel);
    CheckFalse(R.GroupPopup.IsOpen);
  finally
    Seen.Free;
  end;
  R.HideKeyTips;
  FForm.Hide;
end;

procedure TRibbonTests.KeyboardNavigation;
var
  R: TPPGRibbon;
  E0: Integer;
  Acc: IPPGAccessibleChildren;
begin
  R := NewRibbon;
  FForm.Show;
  R.ShowKeyTips;
  // Pfeil: Plaketten weg, Tastaturbedienung auf der aktiven Karte
  R.HandleKeyTipKey(VK_DOWN);
  CheckEquals(0, R.KeyTipLevel);
  CheckTrue(R.KeyboardNavigation);
  CheckTrue(Supports(R, IPPGAccessibleChildren, Acc));
  E0 := R.NavIndex;
  CheckEquals('Start', Acc.AccChildName(E0 + 1));
  CheckEquals(E0 + 1, Acc.AccFocusedChild);
  // rechts: naechste Karte wird aktiv
  R.HandleNavKey(VK_RIGHT, []);
  CheckEquals(1, R.TabIndex);
  R.HandleNavKey(VK_LEFT, []);
  CheckEquals(0, R.TabIndex);
  // runter ins Band, Enter loest aus
  R.HandleNavKey(VK_DOWN, []);
  CheckEquals('Einf'#$00FC'gen', Acc.AccChildName(R.NavIndex + 1));
  R.HandleNavKey(VK_RIGHT, []);
  CheckEquals('Ausschneiden', Acc.AccChildName(R.NavIndex + 1));
  R.HandleNavKey(VK_DOWN, []);
  CheckEquals('Kopieren', Acc.AccChildName(R.NavIndex + 1), 'darunter');
  R.HandleNavKey(VK_UP, []);
  R.HandleNavKey(VK_UP, []);
  CheckEquals('Start', Acc.AccChildName(R.NavIndex + 1), 'oben raus: Karte');
  R.HandleNavKey(VK_DOWN, []);
  R.HandleNavKey(VK_RIGHT, []);
  R.HandleNavKey(VK_DOWN, []);
  FLog.Clear;
  R.HandleNavKey(VK_RETURN, []);
  CheckEquals('click:Kopieren', FLog[0]);
  CheckFalse(R.KeyboardNavigation, 'nach dem Befehl verlassen');
  R.EnterKeyboardNavigation;
  R.HandleNavKey(VK_ESCAPE, []);
  CheckFalse(R.KeyboardNavigation);
  FForm.Hide;
end;

procedure TRibbonTests.QuickAccessCustomizing;
var
  R: TPPGRibbon;
  Fett, Q: TPPGRibbonItem;
begin
  R := NewRibbon;
  Fett := FindItem(R, 'Fett');
  Q := R.AddToQuickAccess(Fett);
  CheckNotNull(Q);
  CheckEquals(1, R.QuickAccess.Count);
  CheckEquals('qat', FLog[0]);
  CheckSame(Fett, R.QuickSource(Q), 'wirkt auf das Original');
  CheckNull(R.AddToQuickAccess(Fett), 'nicht doppelt');
  CheckNull(R.AddToQuickAccess(R.Tabs[0].Groups[1].Items[0]), 'kein Control');
  R.UpdateLayout;
  CheckFalse(IsRectEmpty(R.QuickItemRect(0)));
  // Klick im Schnellzugriff schaltet das Original
  FLog.Clear;
  Click(R, Center(R.QuickItemRect(0)));
  CheckTrue(Fett.Down);
  CheckEquals('click:Fett', FLog[0]);
  R.ClickQuickItem(0);
  CheckFalse(Fett.Down);
  // entfernen
  FLog.Clear;
  R.RemoveFromQuickAccess(0);
  CheckEquals(0, R.QuickAccess.Count);
  CheckEquals('qat', FLog[0]);
  // eigenes Item ohne Original
  Q := R.QuickAccess.AddButton('Eigen', $E74E, rsSmall, ItemOnClick);
  CheckNull(R.QuickSource(Q));
  FLog.Clear;
  R.ClickQuickItem(0);
  CheckEquals('click:Eigen', FLog[0]);
end;

procedure TRibbonTests.ContextMenuEntries;
var
  R: TPPGRibbon;
  M: TPopupMenu;
  H: TPPGRibbonHit;
  It: TPPGRibbonItem;
  Below: Integer;
begin
  R := NewRibbon;
  It := FindItem(R, 'Kopieren');
  H := R.HitTest(Center(R.ItemRect(It)).X, Center(R.ItemRect(It)).Y);
  M := R.PrepareContextMenu(H);
  CheckEquals(4, M.Items.Count, 'hinzufuegen, Trenner, Position, Einklappen');
  CheckTrue(M.Items[0].Enabled);
  M.Items[0].Click;
  CheckEquals(1, R.QuickAccess.Count, 'hinzugefuegt');
  M := R.PrepareContextMenu(H);
  CheckFalse(M.Items[0].Enabled, 'schon im Schnellzugriff');
  // Position wechseln
  M.Items[2].Click;
  CheckTrue(R.QuickAccessPosition = qapBelow);
  Below := R.QuickItemRect(0).Top;
  CheckTrue(Below > R.PanelRect.Top);
  // Kontextmenue auf dem Schnellzugriff: entfernen
  H := R.HitTest(Center(R.QuickItemRect(0)).X, Center(R.QuickItemRect(0)).Y);
  CheckTrue(H.Part = rpQuickItem);
  M := R.PrepareContextMenu(H);
  M.Items[0].Click;
  CheckEquals(0, R.QuickAccess.Count);
  // leerer Bereich: nur Position und Einklappen
  M := R.PrepareContextMenu(R.HitTest(R.Width - 200, R.TabRect(0).Top + 2));
  CheckEquals(2, M.Items.Count);
  M.Items[1].Click;
  CheckTrue(R.Minimized);
end;

procedure TRibbonTests.ContextualTabs;
var
  R: TPPGRibbon;
  Acc: IPPGAccessibleChildren;
  I: Integer;
  Found: Boolean;
begin
  R := NewRibbon;
  CheckTrue(R.Tabs[3].IsContextual);
  CheckTrue(IsRectEmpty(R.TabRect(3)));
  R.Tabs[3].Visible := True;
  CheckFalse(IsRectEmpty(R.TabRect(3)), 'erscheint');
  CheckTrue(R.TabRect(3).Left > R.TabRect(2).Right - 1, 'hinten');
  CheckTrue(Supports(R, IPPGAccessibleChildren, Acc));
  Found := False;
  for I := 1 to Acc.AccChildCount do
    if Acc.AccChildName(I) = 'Tabellentools: Entwurf' then
      Found := True;
  CheckTrue(Found, 'Name mit Kontext');
  Shot(R, 'context');
end;

procedure TRibbonTests.BackstageCoversForm;
var
  R: TPPGRibbon;
  P: TPPGPanel;
begin
  R := NewRibbon;
  P := TPPGPanel.Create(FForm);
  P.Parent := FForm;
  P.SetBounds(10, 200, 100, 100);
  R.Backstage := P;
  CheckFalse(P.Visible, 'zur Laufzeit verborgen');
  R.ClickApplicationButton;
  CheckTrue(R.BackstageVisible);
  CheckTrue(P.Visible);
  CheckEquals(0, P.Top);
  CheckEquals(FForm.ClientWidth, P.Width, 'ganzes Formular');
  CheckEquals('app', FLog[0]);
  CheckEquals('backstage:True', FLog[1]);
  R.HideBackstage;
  CheckFalse(P.Visible);
  CheckEquals(200, P.Top, 'alte Lage');
  CheckEquals('backstage:False', FLog[2]);
  // Klick auf "Datei"
  Click(R, Center(R.ApplicationButtonRect));
  CheckTrue(R.BackstageVisible);
  R.HideBackstage;
  // Backstage freigegeben
  P.Free;
  CheckTrue(R.Backstage = nil);
  FLog.Clear;
  R.ClickApplicationButton;
  CheckEquals(1, FLog.Count, 'nur das Ereignis');
end;

procedure TRibbonTests.AccessibleChildren;
var
  R: TPPGRibbon;
  Acc: IPPGAccessibleChildren;
  I, N, Fett, Tab1: Integer;
begin
  R := NewRibbon;
  R.Width := 1600;
  R.UpdateLayout;
  CheckTrue(Supports(R, IPPGAccessibleChildren, Acc));
  CheckEquals(ROLE_SYSTEM_GROUPING, TPPGCustomControlAccess(R).AccRole);
  CheckTrue(TPPGCustomControlAccess(R).AccName <> '');
  N := Acc.AccChildCount;
  CheckTrue(N > 20, IntToStr(N));
  Fett := 0;
  Tab1 := 0;
  for I := 1 to N do
  begin
    if Acc.AccChildName(I) = 'Fett' then
      Fett := I;
    if Acc.AccChildName(I) = 'Einf'#$00FC'gen' then
      if Acc.AccChildRole(I) = ROLE_SYSTEM_PAGETAB then
        Tab1 := I;
  end;
  CheckTrue(Fett > 0);
  CheckEquals(ROLE_SYSTEM_CHECKBUTTON, Acc.AccChildRole(Fett));
  CheckEquals(0, Acc.AccChildState(Fett) and STATE_SYSTEM_CHECKED);
  FindItem(R, 'Fett').Down := True;
  CheckTrue(Acc.AccChildState(Fett) and STATE_SYSTEM_CHECKED <> 0);
  CheckEquals(Fett, Acc.AccChildAt(Center(Acc.AccChildRect(Fett)).X, Center(Acc.AccChildRect(Fett)).Y));
  CheckEquals(ROLE_SYSTEM_SPLITBUTTON, Acc.AccChildRole(Acc.AccChildAt(Center(R.ItemRect(FindItem(R,
    'Einf'#$00FC'gen'))).X, R.ItemRect(FindItem(R, 'Einf'#$00FC'gen')).Top + 8)));
  // Registerkarte: gewaehlt, Standardaktion wird gepostet
  CheckTrue(Tab1 > 0);
  CheckEquals(0, Acc.AccChildState(Tab1) and STATE_SYSTEM_SELECTED);
  R.HandleNeeded;
  Acc.AccChildDoDefault(Tab1);
  CheckEquals(0, R.TabIndex, 'noch nicht (gepostet)');
  Application.ProcessMessages;
  CheckEquals(1, R.TabIndex);
  CheckTrue(Acc.AccChildState(Tab1) and STATE_SYSTEM_SELECTED <> 0);
  CheckEquals(Tab1, Acc.AccSelectedChild);
end;

procedure TRibbonTests.StreamingRoundTrip;
var
  R, Q: TPPGRibbon;
  M: TMemoryStream;
  It: TPPGRibbonItem;
begin
  R := NewRibbon;
  // Control-Referenzen streamen nur mit dem Formular als Wurzel
  R.Tabs[0].Groups[1].Items[0].Control := nil;
  R.TabIndex := 1;
  R.Minimized := True;
  R.QuickAccessPosition := qapBelow;
  R.ApplicationButtonCaption := 'Datei';
  R.QuickAccess.AddButton('Speichern', $E74E, rsSmall);
  R.Tabs[0].Groups[0].ReduceOrder := 3;
  R.Tabs[0].Groups[0].KeyTip := 'zw';
  It := FindItem(R, 'Kopieren');
  It.KeyTip := 'C';
  It.MinSize := rsMedium;
  It.BeginColumn := True;
  It.Hint := 'Kopiert die Auswahl';
  M := TMemoryStream.Create;
  try
    M.WriteComponent(R);
    M.Position := 0;
    Q := TPPGRibbon(M.ReadComponent(nil));
    try
      CheckEquals(4, Q.Tabs.Count);
      CheckEquals(1, Q.TabIndex);
      CheckTrue(Q.Minimized);
      CheckTrue(Q.QuickAccessPosition = qapBelow);
      CheckEquals('Datei', Q.ApplicationButtonCaption);
      CheckEquals(1, Q.QuickAccess.Count);
      CheckEquals('Speichern', Q.QuickAccess[0].Caption);
      CheckEquals(5, Q.Tabs[0].Groups.Count);
      CheckEquals(3, Q.Tabs[0].Groups[0].ReduceOrder);
      CheckEquals('ZW', Q.Tabs[0].Groups[0].KeyTip);
      CheckTrue(Q.Tabs[0].Groups[0].ShowLauncher);
      CheckTrue(Q.Tabs[0].Groups[0].Items[0].Kind = rikSplitButton);
      CheckEquals($E77F, Q.Tabs[0].Groups[0].Items[0].IconChar);
      It := Q.Tabs[0].Groups[0].Items[2];
      CheckEquals('Kopieren', It.Caption);
      CheckEquals('C', It.KeyTip);
      CheckTrue(It.MinSize = rsMedium);
      CheckTrue(It.Size = rsMedium);
      CheckTrue(It.BeginColumn);
      CheckEquals('Kopiert die Auswahl', It.Hint);
      CheckEquals(14, Q.Tabs[0].Groups[3].Items[0].GalleryItems.Count);
      CheckEquals(1, Q.Tabs[0].Groups[2].Items[0].GroupIndex);
      CheckTrue(Q.Tabs[0].Groups[2].Items[0].Down);
      CheckEquals('Tabellentools', Q.Tabs[3].ContextName);
      CheckEquals($00309030, Q.Tabs[3].ContextColor);
      CheckFalse(Q.Tabs[3].Visible);
    finally
      Q.Free;
    end;
  finally
    M.Free;
  end;
end;

procedure TRibbonTests.RightToLeftMirrors;
var
  R: TPPGRibbon;
  It: TPPGRibbonItem;
  H: TPPGRibbonHit;
begin
  R := NewRibbon;
  R.Width := 1600;
  R.BiDiMode := bdRightToLeft;
  R.UpdateLayout;
  CheckTrue(R.ApplicationButtonRect.Left > R.Width div 2, 'Datei rechts');
  CheckTrue(R.TabRect(1).Right < R.TabRect(0).Left + 1, 'Karten von rechts nach links');
  CheckTrue(R.MinimizeButtonRect.Left < R.Width div 2, 'Einklappen links');
  CheckTrue(R.GroupRect(1).Right <= R.GroupRect(0).Left, 'Gruppen gespiegelt');
  It := FindItem(R, 'Kopieren');
  H := R.HitTest(Center(R.ItemRect(It)).X, Center(R.ItemRect(It)).Y);
  CheckTrue(H.Part = rpItem);
  Click(R, Center(R.ItemRect(It)));
  CheckEquals('click:Kopieren', FLog[0]);
  Shot(R, 'rtl');
end;

procedure TRibbonTests.LanguageSwitchRelayouts;
var
  R: TPPGRibbon;
  W: Integer;
begin
  R := NewRibbon;
  W := R.ApplicationButtonRect.Right - R.ApplicationButtonRect.Left;
  PPGSetLanguage('de');
  try
    // "Datei" ist breiter als "File": Karten ruecken nach rechts
    CheckTrue(R.ApplicationButtonRect.Right - R.ApplicationButtonRect.Left > W, 'Datei-Button neu vermessen');
    CheckTrue(R.TabRect(0).Left >= R.ApplicationButtonRect.Right);
    CheckEquals('Men'#$00FC'band', TPPGCustomControlAccess(R).AccName);
  finally
    PPGSetLanguage('');
  end;
  CheckEquals(W, R.ApplicationButtonRect.Right - R.ApplicationButtonRect.Left, 'zurueck');
end;

procedure TRibbonTests.PaintsAllStates;
var
  R: TPPGRibbon;
begin
  R := NewRibbon;
  R.Width := 1600;
  R.UpdateLayout;
  FindItem(R, 'Fett').Down := True;
  R.Tabs[3].Visible := True;
  R.QuickAccess.AddButton('Speichern', $E74E, rsSmall);
  R.AddToQuickAccess(FindItem(R, 'Fett'));
  R.Tabs[0].Groups[3].Items[0].GalleryIndex := 1;
  R.Perform(WM_MOUSEMOVE, 0, MakeLParam(Center(R.ItemRect(FindItem(R, 'Kopieren'))).X,
    Center(R.ItemRect(FindItem(R, 'Kopieren'))).Y));
  Shot(R, 'wide');
  R.Width := 700;
  R.UpdateLayout;
  Shot(R, 'medium');
  R.Width := 360;
  R.UpdateLayout;
  Shot(R, 'narrow');
  R.Width := 1100;
  R.Minimized := True;
  R.UpdateLayout;
  Shot(R, 'minimized');
  R.Minimized := False;
  R.UpdateLayout;
  R.Enabled := False;
  Shot(R, 'disabled');
  R.Enabled := True;
  R.Preset := 'Classic';
  Shot(R, 'classic');
  R.Preset := 'Fluent11';
  TPPGTheme.Mode := tmDark;
  try
    Shot(R, 'dark');
  finally
    TPPGTheme.Mode := tmLight;
  end;
  TPPGRendererRegistry.ForceGdiFallback := True;
  Shot(R, 'gdi');
  TPPGRendererRegistry.ForceGdiFallback := False;
  // Audit 11b: Zustaende sichtbar (GDI+ und GDI): Hover auf "Kopieren", Deaktiviert;
  // das Ribbon steht nicht in der Tab-Folge (Tastatur ueber KeyTips)
  R.Preset := 'ModernFlat';
  R.Width := 1100;
  R.UpdateLayout;
  PPGCheckStates(Self, R, 'Ribbon', True, False, True, Center(R.ItemRect(FindItem(R, 'Kopieren'))));
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TRibbonTests.ManyItemsStayFast;
var
  R: TPPGRibbon;
  T, G, I: Integer;
  Tab: TPPGRibbonTab;
  Grp: TPPGRibbonGroup;
begin
  FForm.Show;
  R := TPPGRibbon.Create(FForm);
  R.Parent := FForm;
  R.Animation.Enabled := False;
  R.Align := alNone;
  // 10 Karten mit je 10 Gruppen zu 10 Items, dazu 30 weitere Gruppen auf Karte 0
  for T := 0 to 9 do
  begin
    Tab := R.Tabs.AddTab('Karte ' + IntToStr(T));
    for G := 0 to 9 do
    begin
      Grp := Tab.Groups.AddGroup('Gruppe ' + IntToStr(G));
      for I := 0 to 9 do
        Grp.Items.AddButton('Befehl ' + IntToStr(G) + '.' + IntToStr(I), $E700 + I, TPPGRibbonSize(I mod 3));
    end;
  end;
  for G := 0 to 29 do
  begin
    Grp := R.Tabs[0].Groups.AddGroup('Viel ' + IntToStr(G));
    for I := 0 to 9 do
      Grp.Items.AddButton('Befehl ' + IntToStr(I), $E700 + I, TPPGRibbonSize(I mod 3));
  end;
  // Audit 11a #7: Laufzeit im Benchmark (Bench11, vorher 4000 ms im Test);
  // hier bleibt: 200 x neu anordnen und zeichnen ohne Fehler (TearDown)
  for I := 0 to 199 do
  begin
    R.Width := 300 + (I * 7) mod 1300;
    R.UpdateLayout;
    R.Repaint;
  end;
  FForm.Hide;
end;

initialization
  RegisterClass(TPPGRibbon);
  RegisterTest('Phase14b', TRibbonTests.Suite);

end.
