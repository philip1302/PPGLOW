unit DemoPages8;

{ Demo-Seite "Ribbon" (Phase 14b): Menueband als Kopf einer kleinen
  Textverarbeitung. Start (Zwischenablage ueber Standard-Actions, Schrift,
  Absatz, Formatvorlagen als Galerie), Einfuegen (Tabelle zeigt die
  Kontext-Registerkarte "Tabellentools"), Ansicht (Einklappen, Schnellzugriff,
  KeyTips). "Datei" oeffnet einen Backstage-Bereich ueber der Karte. }

interface

uses
  Winapi.Windows,   System.SysUtils, System.Classes, System.Types, System.UITypes, System.Actions, Vcl.Controls,
  Vcl.Graphics, Vcl.StdCtrls,
  System.StrUtils, Vcl.Menus, Vcl.ActnList, Vcl.StdActns,
  PPG.Types, PPG.Items, PPG.Panel, PPG.Labels, PPG.Button, PPG.ComboBox, PPG.Memo, PPG.Menus,
  PPG.Ribbon.Layout, PPG.Ribbon.Items, PPG.Ribbon,
  DemoKit;

type
  TDemoActionClass = class of TCustomAction;

  TDemoRibbonPage = class(TDemoPage)
  private
    FRibbon: TPPGRibbon;
    FMemo: TPPGMemo;
    FFont: TPPGComboBox;
    FSize: TPPGComboBox;
    FBackstage: TPPGPanel;
    FResult: TPPGLabel;
    FActions: TActionList;
    FPasteMenu: TPPGPopupMenu;
    FBold, FItalic, FUnderline, FLeft, FCenter, FRight, FWrap: TPPGRibbonItem;
    FStyles, FTableStyles: TPPGRibbonItem;
    FTableTab: TPPGRibbonTab;
    procedure BuildRibbon;
    procedure BuildBackstage;
    function NewAction(AClass: TDemoActionClass; const ACaption: string): TCustomAction;
    procedure Report(const S: string);
    procedure FontStyleClick(Sender: TObject);
    procedure AlignClick(Sender: TObject);
    procedure WrapClick(Sender: TObject);
    procedure FontChange(Sender: TObject);
    procedure SizeChange(Sender: TObject);
    procedure GrowClick(Sender: TObject);
    procedure BulletClick(Sender: TObject);
    procedure FindClick(Sender: TObject);
    procedure TableClick(Sender: TObject);
    procedure CloseTableClick(Sender: TObject);
    procedure SimpleClick(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure MinimizeClick(Sender: TObject);
    procedure QatBelowClick(Sender: TObject);
    procedure KeyTipsClick(Sender: TObject);
    procedure PastePlainClick(Sender: TObject);
    procedure NewDocClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
    procedure GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
    procedure GetGalleryItem(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
      var Data: TPPGItemData; var Color: TColor);
    procedure LauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
    procedure TabChange(Sender: TObject);
    procedure BackstageChange(Sender: TObject);
    procedure QuickChange(Sender: TObject);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

const
  FullW = 2 * 484 + CardGap;
  CardH = 600;
  TableColors: array[0..7] of TColor = ($00D77800, $0000A5FF, $0032A852, $004040C0,
    $00A0A0A0, $00B05A8E, $00CCB700, $00505050);
  TableColorNames: array[0..7] of string = ('Blau', 'Orange', 'Gr{ue}n', 'Rot', 'Grau',
    'Violett', 'T{ue}rkis', 'Anthrazit');
  StyleNames: array[0..7] of string = ('Standard', 'Titel', '{Ue}berschrift 1', '{Ue}berschrift 2',
    'Zitat', 'Code', 'Hervorgehoben', 'Klein');

procedure TDemoRibbonPage.Build;
var
  Card: TPPGPanel;
  Y: Integer;
begin
  NewPageHeader(Own, Sheet, 'Ribbon', L('TPPGRibbon: Registerkarten, Gruppen, gro{ss}e und kleine ') +
    L('Befehle, Galerie mit Kategorien, eingebettete Controls, Kontext-Registerkarten, Schnellzugriff ') +
    L('und Backstage. Alt bzw. F10 zeigt die KeyTips; die Tastatur reicht bis in aufgeklappte ') +
    L('Gruppen und Galerien (Esc eine Ebene zur{ue}ck).'));
  Y := PageContentTop;
  Card := NewCard(Own, Sheet, PageX, Y, FullW, CardH, 'Kleine Textverarbeitung',
    L('Ziehen Sie das Fenster schmaler: Die Gruppen schrumpfen von rechts (gro{ss} {>} klein {>} ') +
    L('nur Symbol {>} Dropdown). Rechtsklick auf einen Befehl f{ue}gt ihn dem Schnellzugriff hinzu.'));
  FActions := TActionList.Create(Own);
  FMemo := TPPGMemo.Create(Own);
  FMemo.Parent := Card;
  FMemo.ScrollBars := ssVertical;
  FMemo.Font.Name := 'Segoe UI';
  FMemo.Font.Size := 11;
  FMemo.Lines.Text := L('PPGlow Ribbon') + sLineBreak + sLineBreak +
    L('Markieren Sie Text und probieren Sie Ausschneiden, Kopieren und Einf{ue}gen: Die Befehle ') +
    L('sind Standard-Actions und werden automatisch aktiviert bzw. deaktiviert.') + sLineBreak +
    L('Fett, Kursiv und Unterstrichen schalten die Schrift des Dokuments um; die ') +
    L('Formatvorlagen-Galerie wechselt Schriftart und -gr{oe}{ss}e.') + sLineBreak +
    L('Einf{ue}gen {>} Tabelle zeigt die Kontext-Registerkarte "Tabellentools".');
  FRibbon := TPPGRibbon.Create(Own);
  FRibbon.Parent := Card;
  FRibbon.Align := alNone;
  FRibbon.SetBounds(CardPad, Card.Tag, FullW - 2 * CardPad, 160);
  FRibbon.Anchors := [akLeft, akTop, akRight];
  BuildRibbon;
  FMemo.SetBounds(CardPad, FRibbon.Top + FRibbon.Height + 8, FullW - 2 * CardPad,
    CardH - (FRibbon.Top + FRibbon.Height + 8) - 52);
  FMemo.Anchors := [akLeft, akTop, akRight, akBottom];
  FResult := NewResult(Own, Card, 'Letzte Aktion');
  BuildBackstage;
  Host.RegisterSpecial('ribbon', FRibbon);
end;

function TDemoRibbonPage.NewAction(AClass: TDemoActionClass; const ACaption: string): TCustomAction;
begin
  Result := AClass.Create(Own);
  Result.ActionList := FActions;
  Result.Caption := L(ACaption);
end;

procedure TDemoRibbonPage.BuildRibbon;
var
  T: TPPGRibbonTab;
  G: TPPGRibbonGroup;
  It: TPPGRibbonItem;
  I: Integer;
  M: TMenuItem;
begin
  FRibbon.OnGalleryClick := GalleryClick;
  FRibbon.OnGetGalleryItem := GetGalleryItem;
  FRibbon.OnLauncherClick := LauncherClick;
  FRibbon.OnChange := TabChange;
  FRibbon.OnBackstageChange := BackstageChange;
  FRibbon.OnQuickAccessChange := QuickChange;
  FPasteMenu := TPPGPopupMenu.Create(Own);
  M := TMenuItem.Create(FPasteMenu);
  M.Caption := L('Einf{ue}gen');
  FPasteMenu.Items.Add(M);
  M := TMenuItem.Create(FPasteMenu);
  M.Caption := L('Nur den Text {ue}bernehmen');
  M.OnClick := PastePlainClick;
  FPasteMenu.Items.Add(M);
  FRibbon.Tabs.BeginUpdate;
  try
    // ---- Start ----
    T := FRibbon.Tabs.AddTab('Start');
    G := T.Groups.AddGroup('Zwischenablage');
    G.ShowLauncher := True;
    G.LauncherHint := L('Optionen der Zwischenablage');
    It := G.Items.Add;
    It.Action := NewAction(TEditPaste, 'Einf{ue}gen');
    It.Kind := rikSplitButton;
    It.IconChar := $E77F;
    It.DropDownMenu := FPasteMenu;
    FPasteMenu.Items[0].Action := It.Action;
    It := G.Items.Add;
    It.Action := NewAction(TEditCut, 'Ausschneiden');
    It.Size := rsMedium;
    It.IconChar := $E8C6;
    It := G.Items.Add;
    It.Action := NewAction(TEditCopy, 'Kopieren');
    It.Size := rsMedium;
    It.IconChar := $E8C8;
    It := G.Items.Add;
    It.Action := NewAction(TEditSelectAll, 'Alles markieren');
    It.Size := rsMedium;
    It.IconChar := $E8B3;
    G := T.Groups.AddGroup('Schriftart');
    G.IconChar := $E8D2;
    FFont := TPPGComboBox.Create(Own);
    FFont.Style := csDropDownList;
    FFont.Width := 150;
    FFont.Items.CommaText := '"Segoe UI",Calibri,Cambria,Consolas,Georgia,"Times New Roman"';
    FFont.ItemIndex := 0;
    FFont.OnChange := FontChange;
    It := G.Items.Add;
    It.Control := FFont;
    It.KeyTip := 'FF';
    FSize := TPPGComboBox.Create(Own);
    FSize.Style := csDropDownList;
    FSize.Width := 64;
    FSize.Items.CommaText := '8,9,10,11,12,14,16,18,20,24,28';
    FSize.ItemIndex := 3;
    FSize.OnChange := SizeChange;
    It := G.Items.Add;
    It.Control := FSize;
    It.SameRow := True;
    It.KeyTip := 'FS';
    FBold := G.Items.AddCheck('Fett', $E8DD);
    FBold.OnClick := FontStyleClick;
    FBold.KeyTip := '1';
    FItalic := G.Items.AddCheck('Kursiv', $E8DB);
    FItalic.OnClick := FontStyleClick;
    FItalic.SameRow := True;
    FItalic.KeyTip := '2';
    FUnderline := G.Items.AddCheck('Unterstrichen', $E8DC);
    FUnderline.OnClick := FontStyleClick;
    FUnderline.SameRow := True;
    FUnderline.KeyTip := '3';
    It := G.Items.AddButton(L('Schrift vergr{oe}{ss}ern'), $E8E8, rsSmall, GrowClick);
    It.SameRow := True;
    It.Tag := 1;
    It := G.Items.AddButton('Schrift verkleinern', $E8E7, rsSmall, GrowClick);
    It.SameRow := True;
    It.Tag := -1;
    G := T.Groups.AddGroup('Absatz');
    G.IconChar := $E8E4;
    FLeft := G.Items.AddCheck(L('Linksb{ue}ndig'), $E8E4, rsSmall, 1);
    FLeft.Down := True;
    FLeft.OnClick := AlignClick;
    FCenter := G.Items.AddCheck('Zentriert', $E8E3, rsSmall, 1);
    FCenter.SameRow := True;
    FCenter.OnClick := AlignClick;
    FRight := G.Items.AddCheck(L('Rechtsb{ue}ndig'), $E8E2, rsSmall, 1);
    FRight.SameRow := True;
    FRight.OnClick := AlignClick;
    G.Items.AddButton(L('Aufz{ae}hlung'), $E8FD, rsMedium, BulletClick);
    FWrap := G.Items.AddCheck('Zeilenumbruch', $E751, rsMedium);
    FWrap.Down := True;
    FWrap.OnClick := WrapClick;
    G := T.Groups.AddGroup('Formatvorlagen');
    FStyles := G.Items.Add;
    FStyles.Kind := rikGallery;
    FStyles.Caption := 'Formatvorlagen';
    FStyles.GalleryColumns := 4;
    FStyles.GalleryItemWidth := 92;
    for I := 0 to High(StyleNames) do
      FStyles.GalleryItems.Add(L(StyleNames[I]));
    FStyles.GalleryIndex := 0;
    G := T.Groups.AddGroup('Bearbeiten');
    G.IconChar := $E721;
    G.Items.AddButton('Suchen', $E721, rsMedium, FindClick);
    G.Items.AddButton('Ersetzen', $E8AB, rsMedium, SimpleClick);
    G.Items.AddButton('Markieren', $E8B3, rsMedium, SimpleClick);
    // ---- Einfuegen ----
    T := FRibbon.Tabs.AddTab(L('Einf{ue}gen'));
    G := T.Groups.AddGroup('Tabellen');
    G.Items.AddButton('Tabelle', $E80A, rsLarge, TableClick);
    G := T.Groups.AddGroup('Illustrationen');
    G.Items.AddButton('Bilder', $EB9F, rsLarge, SimpleClick);
    G.Items.AddButton('Formen', $E7B8, rsLarge, SimpleClick);
    G.Items.AddButton('Symbole', $E76E, rsLarge, SimpleClick);
    G := T.Groups.AddGroup(L('Kopf- und Fu{ss}zeile'));
    G.Items.AddButton('Kopfzeile', $E8A5, rsMedium, SimpleClick);
    G.Items.AddButton(L('Fu{ss}zeile'), $E8A5, rsMedium, SimpleClick);
    G.Items.AddButton('Seitenzahl', $E8EF, rsMedium, SimpleClick);
    // ---- Ansicht ----
    T := FRibbon.Tabs.AddTab('Ansicht');
    G := T.Groups.AddGroup(L('Men{ue}band'));
    G.Items.AddButton(L('Men{ue}band reduzieren'), $E70E, rsLarge, MinimizeClick);
    G.Items.AddCheck('Schnellzugriff unten', $E8A0, rsMedium).OnClick := QatBelowClick;
    G.Items.AddButton('KeyTips zeigen', $E765, rsMedium, KeyTipsClick);
    G := T.Groups.AddGroup('Zoom');
    It := G.Items.AddButton(L('Gr{oe}{ss}er'), $E8A3, rsLarge, GrowClick);
    It.Tag := 2;
    It := G.Items.AddButton('Kleiner', $E71F, rsLarge, GrowClick);
    It.Tag := -2;
    // ---- Kontext: Tabellentools ----
    FTableTab := FRibbon.Tabs.AddTab('Entwurf');
    FTableTab.ContextName := 'Tabellentools';
    FTableTab.ContextColor := $0032A852;
    FTableTab.Visible := False;
    G := FTableTab.Groups.AddGroup('Tabellenformatvorlagen');
    FTableStyles := G.Items.Add;
    FTableStyles.Kind := rikGallery;
    FTableStyles.Caption := 'Farben';
    FTableStyles.GalleryCount := Length(TableColors);
    FTableStyles.GalleryColumns := 5;
    FTableStyles.GalleryItemWidth := 80;
    G := FTableTab.Groups.AddGroup(L('Schlie{ss}en'));
    G.Items.AddButton(L('Tabellentools schlie{ss}en'), $E711, rsLarge, CloseTableClick);
  finally
    FRibbon.Tabs.EndUpdate;
  end;
  // Schnellzugriff
  It := FRibbon.QuickAccess.AddButton('Speichern', $E74E, rsSmall, SaveClick);
  It.Hint := L('Speichern (Strg+S)');
  It := FRibbon.QuickAccess.Add;
  It.Action := NewAction(TEditUndo, 'R{ue}ckg{ae}ngig');
  It.IconChar := $E7A7;
end;

procedure TDemoRibbonPage.BuildBackstage;
var
  Lbl: TPPGLabel;
begin
  FBackstage := TPPGPanel.Create(Own);
  FBackstage.Parent := FRibbon.Parent;
  FBackstage.ShowCaption := False;
  FBackstage.SetBounds(0, 0, 300, 200);
  Lbl := NewLabel(Own, FBackstage, 40, 32, 400, 'Datei', tkTitle);
  Lbl.Anchors := [akLeft, akTop];
  NewLabel(Own, FBackstage, 40, 84, 600, L('Der Backstage-Bereich ist ein beliebiges Control (hier ein ') +
    L('Panel), das "Datei" {ue}ber den ganzen Bereich legt. Esc schlie{ss}t ihn.'), tkSecondary);
  NewButton(Own, FBackstage, 40, 130, 180, 'Neues Dokument', NewDocClick, True);
  NewButton(Own, FBackstage, 40, 130 + CtlH + 10, 180, L('Zur{ue}ck'), BackClick);
  FRibbon.Backstage := FBackstage;
end;

procedure TDemoRibbonPage.Report(const S: string);
begin
  SetResult(FResult, S);
  Host.Log('Ribbon', L(S));
end;

procedure TDemoRibbonPage.FontStyleClick(Sender: TObject);
var
  St: TFontStyles;
begin
  St := [];
  if FBold.Down then
    Include(St, fsBold);
  if FItalic.Down then
    Include(St, fsItalic);
  if FUnderline.Down then
    Include(St, fsUnderline);
  FMemo.Font.Style := St;
  Report(TPPGRibbonItem(Sender).Caption + ': ' + BoolToStr(TPPGRibbonItem(Sender).Down, True));
end;

procedure TDemoRibbonPage.AlignClick(Sender: TObject);
begin
  if FCenter.Down then
    FMemo.Alignment := taCenter
  else if FRight.Down then
    FMemo.Alignment := taRightJustify
  else
    FMemo.Alignment := taLeftJustify;
  Report(TPPGRibbonItem(Sender).Caption);
end;

procedure TDemoRibbonPage.WrapClick(Sender: TObject);
begin
  FMemo.WordWrap := FWrap.Down;
  Report('Zeilenumbruch: ' + BoolToStr(FWrap.Down, True));
end;

procedure TDemoRibbonPage.FontChange(Sender: TObject);
begin
  if FFont.ItemIndex >= 0 then
    FMemo.Font.Name := FFont.Items[FFont.ItemIndex];
  Report('Schrift: ' + FMemo.Font.Name);
end;

procedure TDemoRibbonPage.SizeChange(Sender: TObject);
begin
  if FSize.ItemIndex >= 0 then
    FMemo.Font.Size := StrToIntDef(FSize.Items[FSize.ItemIndex], 11);
  Report(L('Schriftgr{oe}{ss}e: ') + IntToStr(FMemo.Font.Size));
end;

procedure TDemoRibbonPage.GrowClick(Sender: TObject);
var
  S: Integer;
begin
  S := FMemo.Font.Size + TPPGRibbonItem(Sender).Tag;
  if S < 6 then
    S := 6;
  if S > 48 then
    S := 48;
  FMemo.Font.Size := S;
  FSize.ItemIndex := FSize.Items.IndexOf(IntToStr(S));
  Report(L('Schriftgr{oe}{ss}e: ') + IntToStr(S));
end;

procedure TDemoRibbonPage.BulletClick(Sender: TObject);
begin
  FMemo.SelText := #$2022 + ' ';
  Report(L('Aufz{ae}hlungszeichen eingef{ue}gt'));
end;

procedure TDemoRibbonPage.FindClick(Sender: TObject);
var
  P: Integer;
begin
  P := Pos('Ribbon', FMemo.Text);
  if P > 0 then
  begin
    FMemo.SelStart := P - 1;
    FMemo.SelLength := Length('Ribbon');
    Report('"Ribbon" gefunden und markiert');
  end
  else
    Report('"Ribbon" nicht gefunden');
end;

procedure TDemoRibbonPage.TableClick(Sender: TObject);
begin
  FMemo.SelText := sLineBreak + '| Produkt | Menge | Preis |' + sLineBreak + '|---------|-------|-------|' +
    sLineBreak + '| Ribbon  |     1 |  ...  |' + sLineBreak;
  // Kontext-Registerkarte zeigen und waehlen (Code: ohne Ereignisse)
  FTableTab.Visible := True;
  FRibbon.TabIndex := FTableTab.Index;
  Report('Tabelle eingef{ue}gt {-} Kontext "Tabellentools" sichtbar');
end;

procedure TDemoRibbonPage.CloseTableClick(Sender: TObject);
begin
  FTableTab.Visible := False;
  FRibbon.TabIndex := 1;
  Report('Tabellentools geschlossen');
end;

procedure TDemoRibbonPage.SimpleClick(Sender: TObject);
begin
  Report(TPPGRibbonItem(Sender).Caption + ' angeklickt');
end;

procedure TDemoRibbonPage.SaveClick(Sender: TObject);
begin
  Report(L('Gespeichert (Demo: nur die Meldung)'));
end;

procedure TDemoRibbonPage.MinimizeClick(Sender: TObject);
begin
  FRibbon.Minimized := True;
  Report(L('Men{ue}band reduziert {-} Doppelklick auf eine Karte oder Strg+F1 klappt es wieder aus'));
end;

procedure TDemoRibbonPage.QatBelowClick(Sender: TObject);
begin
  if TPPGRibbonItem(Sender).Down then
    FRibbon.QuickAccessPosition := qapBelow
  else
    FRibbon.QuickAccessPosition := qapAbove;
  Report('Schnellzugriff ' + IfThen(TPPGRibbonItem(Sender).Down, 'unter', L('{ue}ber')) +
    L(' dem Men{ue}band'));
end;

procedure TDemoRibbonPage.KeyTipsClick(Sender: TObject);
begin
  FRibbon.ShowKeyTips;
  Report('KeyTips sichtbar {-} Buchstaben tippen, Esc geht zur{ue}ck');
end;

procedure TDemoRibbonPage.PastePlainClick(Sender: TObject);
begin
  FMemo.PasteFromClipboard;
  Report(L('Nur Text eingef{ue}gt'));
end;

procedure TDemoRibbonPage.NewDocClick(Sender: TObject);
begin
  FMemo.Clear;
  FRibbon.HideBackstage;
  Report('Neues Dokument');
end;

procedure TDemoRibbonPage.BackClick(Sender: TObject);
begin
  FRibbon.HideBackstage;
end;

procedure TDemoRibbonPage.GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
begin
  if Item = FStyles then
  begin
    case Index of
      0: begin FMemo.Font.Name := 'Segoe UI'; FMemo.Font.Size := 11; FMemo.Font.Style := []; end;
      1: begin FMemo.Font.Name := 'Segoe UI Light'; FMemo.Font.Size := 24; FMemo.Font.Style := []; end;
      2: begin FMemo.Font.Name := 'Segoe UI Semibold'; FMemo.Font.Size := 16; FMemo.Font.Style := []; end;
      3: begin FMemo.Font.Name := 'Segoe UI Semibold'; FMemo.Font.Size := 13; FMemo.Font.Style := []; end;
      4: begin FMemo.Font.Name := 'Georgia'; FMemo.Font.Size := 12; FMemo.Font.Style := [fsItalic]; end;
      5: begin FMemo.Font.Name := 'Consolas'; FMemo.Font.Size := 11; FMemo.Font.Style := []; end;
      6: begin FMemo.Font.Name := 'Segoe UI'; FMemo.Font.Size := 11; FMemo.Font.Style := [fsBold]; end;
    else
      begin FMemo.Font.Name := 'Segoe UI'; FMemo.Font.Size := 9; FMemo.Font.Style := []; end;
    end;
    FBold.Down := fsBold in FMemo.Font.Style;
    FItalic.Down := fsItalic in FMemo.Font.Style;
    FUnderline.Down := False;
    Report('Formatvorlage: ' + Item.GalleryItems[Index]);
  end
  else
    Report('Tabellenfarbe: ' + L(TableColorNames[Index]));
end;

procedure TDemoRibbonPage.GetGalleryItem(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
  var Data: TPPGItemData; var Color: TColor);
begin
  if (Item = FTableStyles) and (Index >= 0) and (Index <= High(TableColors)) then
  begin
    Data.Text := L(TableColorNames[Index]);
    Color := TableColors[Index];
  end
  else if Item = FStyles then
    // Kategorien der aufgeklappten Galerie (Phase 20c)
    case Index of
      0, 1: Data.Group := 'Dokument';
      2, 3: Data.Group := L('{Ue}berschriften');
    else
      Data.Group := 'Text';
    end;
end;

procedure TDemoRibbonPage.LauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
begin
  Report('Startknopf "' + Group.Caption + '": hier w{ue}rde ein Dialog ge{oe}ffnet');
end;

procedure TDemoRibbonPage.TabChange(Sender: TObject);
begin
  Report('Registerkarte: ' + FRibbon.ActiveTab.Caption);
end;

procedure TDemoRibbonPage.BackstageChange(Sender: TObject);
begin
  Report('Backstage ' + IfThen(FRibbon.BackstageVisible, 'ge{oe}ffnet', 'geschlossen'));
end;

procedure TDemoRibbonPage.QuickChange(Sender: TObject);
begin
  Report('Schnellzugriff: ' + IntToStr(FRibbon.QuickAccess.Count) + ' Befehle');
end;

procedure TDemoRibbonPage.SelfTest(Check: TDemoCheck);
var
  N, I, Collapsed: Integer;
  W: Integer;
begin
  FRibbon.UpdateLayout;
  Check('Ribbon: vier Registerkarten, eine verborgen', (FRibbon.Tabs.Count = 4) and not FTableTab.Visible);
  Check('Ribbon: Start mit fuenf Gruppen', FRibbon.GroupCount = 5);
  // Fett per Klick auf das Item
  FRibbon.ClickItem(FBold);
  Check('Ribbon: Fett schaltet das Dokument', FBold.Down and (fsBold in FMemo.Font.Style));
  FRibbon.ClickItem(FBold);
  Check('Ribbon: Fett wieder aus', not (fsBold in FMemo.Font.Style));
  // Absatz: Gruppe von Umschalt-Buttons
  FRibbon.ClickItem(FCenter);
  Check('Ribbon: zentriert', FCenter.Down and not FLeft.Down and (FMemo.Alignment = taCenter));
  FRibbon.ClickItem(FLeft);
  // Galerie
  FRibbon.SelectGalleryItem(FStyles, 5);
  Check('Ribbon: Formatvorlage Code', (FStyles.GalleryIndex = 5) and (FMemo.Font.Name = 'Consolas'));
  FRibbon.SelectGalleryItem(FStyles, 0);
  // Aufgeklappte Galerie mit Kategorien und Tastatur (Phase 20c)
  FRibbon.OpenGallery(FStyles);
  Check('Ribbon: Galerie nach Kategorien', (FRibbon.GalleryPopup <> nil) and
    FRibbon.GalleryPopup.IsOpen and FRibbon.GalleryPopup.Grouped);
  if (FRibbon.GalleryPopup <> nil) and FRibbon.GalleryPopup.IsOpen then
  begin
    FRibbon.GalleryPopup.HandleKey(VK_HOME);
    FRibbon.GalleryPopup.HandleKey(VK_DOWN);
    Check('Ribbon: Pfeil springt in die naechste Kategorie', FRibbon.GalleryPopup.FocusIndex = 2);
    FRibbon.GalleryPopup.HandleKey(VK_RETURN);
    Check(L('Ribbon: Enter w{ae}hlt {Ue}berschrift 1'), FStyles.GalleryIndex = 2);
  end;
  FRibbon.ClosePopups;
  FRibbon.SelectGalleryItem(FStyles, 0);
  // Kontext-Registerkarte
  FRibbon.TabIndex := 1;
  FRibbon.ClickItem(FRibbon.Tabs[1].Groups[0].Items[0]);
  Check('Ribbon: Tabellentools sichtbar und aktiv', FTableTab.Visible and (FRibbon.ActiveTab = FTableTab));
  FRibbon.SelectGalleryItem(FTableStyles, 2);
  Check('Ribbon: Tabellenfarbe', FTableStyles.GalleryIndex = 2);
  FRibbon.ClickItem(FTableTab.Groups[1].Items[0]);
  Check('Ribbon: Tabellentools geschlossen', not FTableTab.Visible);
  FRibbon.TabIndex := 0;
  // Schrumpfen
  W := FRibbon.Width;
  FRibbon.Width := 420;
  FRibbon.UpdateLayout;
  Collapsed := 0;
  for I := 0 to FRibbon.GroupCount - 1 do
    if FRibbon.GroupState(I) = rgsCollapsed then
      Inc(Collapsed);
  Check('Ribbon: schmal, Gruppen als Dropdown', Collapsed > 0);
  FRibbon.Width := W;
  FRibbon.UpdateLayout;
  Check('Ribbon: breit, nichts geschrumpft', FRibbon.GroupState(0) = rgsLarge);
  // KeyTips
  FRibbon.ShowKeyTips;
  N := FRibbon.KeyTipCount;
  Check('Ribbon: KeyTips Datei, Schnellzugriff und Karten', N >= 6);
  FRibbon.HandleKeyTipChar('S');
  Check('Ribbon: KeyTip S waehlt Start', (FRibbon.KeyTipLevel = 2) and (FRibbon.TabIndex = 0));
  FRibbon.HideKeyTips;
  // Einklappen und Schnellzugriff
  FRibbon.Minimized := True;
  Check('Ribbon: eingeklappt', FRibbon.Height < 100);
  FRibbon.Minimized := False;
  N := FRibbon.QuickAccess.Count;
  FRibbon.AddToQuickAccess(FBold);
  Check('Ribbon: Fett im Schnellzugriff', FRibbon.QuickAccess.Count = N + 1);
  FRibbon.RemoveFromQuickAccess(N);
  // Backstage
  FRibbon.ClickApplicationButton;
  Check('Ribbon: Backstage offen', FRibbon.BackstageVisible and FBackstage.Visible);
  FRibbon.HideBackstage;
  Check('Ribbon: Backstage geschlossen', not FBackstage.Visible);
end;

end.
