unit DemoShowRibbon;

// Komponentenseite TPPGRibbon (Gruppe "Buttons & Aktionen"): Buehne und
// Inspektor kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten
// des Ribbons (Inhalt auf der Buehne, Backstage-Kandidat, Protokoll der
// Ereignisse mit eigener Signatur) und die beiden Praxisbeispiele
// (ExRibbonInvoice, ExRibbonReport).

interface

uses
  System.SysUtils, System.Classes, System.Types, System.Generics.Collections,
  Vcl.Controls, Vcl.Graphics,
  PPG.Items, PPG.Panel, PPG.Labels, PPG.Ribbon.Layout, PPG.Ribbon.Items, PPG.Ribbon,
  DemoKit, DemoShowcase, ExRibbonInvoice, ExRibbonReport;

type
  TDemoShowRibbonPage = class(TDemoComponentPage)
  private
    FBackstage: TPPGPanel;
    FInvoice: TInvoiceRibbon;
    FReport: TReportRibbon;
    FLastDrawIndex: Integer;
    procedure EnsureBackstage;
    procedure BackstageBackClick(Sender: TObject);
    procedure SubjectItemClick(Sender: TObject; Item: TPPGRibbonItem);
    procedure SubjectChanging(Sender: TObject; NewTab: TPPGRibbonTab; var AllowChange: Boolean);
    procedure SubjectGalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
    procedure SubjectGetGalleryItem(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
      var Data: TPPGItemData; var Color: TColor);
    procedure SubjectDrawGalleryItem(Sender: TObject; Item: TPPGRibbonItem; Index: Integer;
      Canvas: TCanvas; const Rect: TRect; Selected, Hot: Boolean; var Handled: Boolean);
    procedure SubjectLauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure AddCandidates(List: TList<TComponent>); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

function TDemoShowRibbonPage.SubjectClass: TComponentClass;
begin
  Result := TPPGRibbon;
end;

procedure TDemoShowRibbonPage.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  // Wird das Panel einem Item als Control zugewiesen, wird das Ribbon sein
  // Parent und gibt es beim Zuruecksetzen mit frei: dann neu anlegen
  if (Operation = opRemove) and (AComponent = FBackstage) then
    FBackstage := nil;
end;

procedure TDemoShowRibbonPage.EnsureBackstage;
var
  Lbl: TPPGLabel;
begin
  if FBackstage <> nil then
    Exit;
  // Kandidat fuer die Eigenschaft Backstage: ein Panel, das "Datei" ueber
  // die ganze Buehne legt
  FBackstage := TPPGPanel.Create(Own);
  FBackstage.Name := 'pnlRibbonBackstage';
  FBackstage.FreeNotification(Self);
  FBackstage.Parent := Stage;
  FBackstage.ShowCaption := False;
  FBackstage.Caption := '';
  FBackstage.Visible := False;
  FBackstage.SetBounds(0, 0, 400, 200);
  Lbl := NewLabel(Own, FBackstage, 32, 24, 400, 'Datei', tkTitle);
  Lbl.Anchors := [akLeft, akTop];
  NewLabel(Own, FBackstage, 32, 72, 560, 'Backstage-Bereich: ein beliebiges Control (hier ein Panel), '
    + 'das "Datei" {ue}ber den Bereich legt. Esc oder "Zur{ue}ck" schlie{ss}t ihn.', tkSecondary);
  NewButton(Own, FBackstage, 32, 120, 160, 'Zur{ue}ck', BackstageBackClick, True);
end;

procedure TDemoShowRibbonPage.BackstageBackClick(Sender: TObject);
begin
  if Subject is TPPGRibbon then
    TPPGRibbon(Subject).HideBackstage;
end;

procedure TDemoShowRibbonPage.AddCandidates(List: TList<TComponent>);
begin
  inherited AddCandidates(List);
  EnsureBackstage;
  List.Add(FBackstage);
end;

procedure TDemoShowRibbonPage.SetupSubject(ASubject: TComponent);
var
  R: TPPGRibbon;
  T: TPPGRibbonTab;
  G: TPPGRibbonGroup;
  It: TPPGRibbonItem;
  I: Integer;
begin
  inherited SetupSubject(ASubject);
  R := TPPGRibbon(ASubject);
  FLastDrawIndex := -1;
  // Der Hinweis der Buehne steht ueber dem Band (das Ribbon dockt oben an)
  for I := 0 to Stage.ControlCount - 1 do
    if (Stage.Controls[I] is TPPGLabel) and (Stage.Controls[I].Align = alNone) then
    begin
      Stage.Controls[I].Align := alTop;
      Stage.Controls[I].AlignWithMargins := True;
      Stage.Controls[I].Margins.SetBounds(16, 12, 16, 8);
    end;
  EnsureBackstage;
  FBackstage.Visible := False;

  // Inhalt wie in einer kleinen Textverarbeitung, damit man sofort etwas sieht
  R.Tabs.BeginUpdate;
  try
    T := R.Tabs.AddTab('Start');
    G := T.Groups.AddGroup('Zwischenablage');
    G.ShowLauncher := True;
    G.LauncherHint := L('Optionen der Zwischenablage');
    G.Items.AddButton(L('Einf{ue}gen'), $E77F);
    G.Items.AddButton('Ausschneiden', $E8C6, rsMedium);
    G.Items.AddButton('Kopieren', $E8C8, rsMedium);
    G := T.Groups.AddGroup('Schrift');
    G.Items.AddCheck('Fett', $E8DD);
    G.Items.AddCheck('Kursiv', $E8DB).SameRow := True;
    G.Items.AddCheck('Unterstrichen', $E8DC).SameRow := True;
    It := G.Items.AddCheck(L('Linksb{ue}ndig'), $E8E4, rsSmall, 1);
    It.Down := True;
    G.Items.AddCheck('Zentriert', $E8E3, rsSmall, 1).SameRow := True;
    G.Items.AddCheck(L('Rechtsb{ue}ndig'), $E8E2, rsSmall, 1).SameRow := True;
    G := T.Groups.AddGroup('Formatvorlagen');
    It := G.Items.Add;
    It.Kind := rikGallery;
    It.Caption := 'Formatvorlagen';
    It.GalleryItems.Text := 'Standard' + sLineBreak + 'Titel' + sLineBreak + L('{Ue}berschrift 1')
      + sLineBreak + L('{Ue}berschrift 2') + sLineBreak + 'Zitat' + sLineBreak + 'Code';
    It.GalleryColumns := 3;
    It.GalleryItemWidth := 90;
    It.GalleryIndex := 0;
    G := T.Groups.AddGroup('Ausgabe');
    It := G.Items.AddButton('Exportieren', $EDE1);
    It.Kind := rikSplitButton;
    It.Hint := L('Exportiert das Dokument; der Pfeil zeigt weitere Formate');
    G.Items.AddButton('Drucken', $E749, rsMedium);
    T := R.Tabs.AddTab(L('Einf{ue}gen'));
    G := T.Groups.AddGroup('Tabellen');
    G.Items.AddButton('Tabelle', $E80A);
    G := T.Groups.AddGroup('Illustrationen');
    G.Items.AddButton('Bilder', $EB9F);
    G.Items.AddButton('Formen', $E7B8, rsMedium);
    // Kontext-Registerkarte (farbig), wie sie nur bei gewaehlter Tabelle erscheint
    T := R.Tabs.AddTab('Entwurf');
    T.ContextName := 'Tabellentools';
    T.ContextColor := $0032A852;
    G := T.Groups.AddGroup('Zeilen und Spalten');
    G.Items.AddButton(L('Zeile einf{ue}gen'), $E710, rsMedium);
    G.Items.AddButton(L('Spalte einf{ue}gen'), $E710, rsMedium);
  finally
    R.Tabs.EndUpdate;
  end;
  R.QuickAccess.AddButton('Speichern', $E74E, rsSmall).Hint := 'Speichern (Strg+S)';
  R.QuickAccess.AddButton(L('R{ue}ckg{ae}ngig'), $E7A7, rsSmall);

  // Ereignisse mit eigener Signatur protokolliert die Seite selbst
  R.OnItemClick := SubjectItemClick;
  R.OnChanging := SubjectChanging;
  R.OnGalleryClick := SubjectGalleryClick;
  R.OnGetGalleryItem := SubjectGetGalleryItem;
  R.OnCustomDrawGalleryItem := SubjectDrawGalleryItem;
  R.OnLauncherClick := SubjectLauncherClick;
end;

procedure TDemoShowRibbonPage.SubjectItemClick(Sender: TObject; Item: TPPGRibbonItem);
var
  S: string;
begin
  S := 'Item = ' + Item.Caption;
  if Item.Kind = rikCheck then
    S := S + ', Down = ' + BoolToStr(Item.Down, True);
  LogEvent('OnItemClick', S);
end;

procedure TDemoShowRibbonPage.SubjectChanging(Sender: TObject; NewTab: TPPGRibbonTab;
  var AllowChange: Boolean);
begin
  LogEvent('OnChanging', 'NewTab = ' + NewTab.Caption + ', AllowChange = True');
end;

procedure TDemoShowRibbonPage.SubjectGalleryClick(Sender: TObject; Item: TPPGRibbonItem;
  Index: Integer);
var
  S: string;
begin
  S := Format('Index = %d', [Index]);
  if (Index >= 0) and (Index < Item.GalleryItems.Count) then
    S := S + ' (' + Item.GalleryItems[Index] + ')';
  LogEvent('OnGalleryClick', S);
end;

procedure TDemoShowRibbonPage.SubjectGetGalleryItem(Sender: TObject; Item: TPPGRibbonItem;
  Index: Integer; var Data: TPPGItemData; var Color: TColor);
const
  Colors: array[0..5] of TColor = ($00D77800, $0000A5FF, $0032A852, $004040C0, $00A0A0A0,
    $00B05A8E);
begin
  // Das Ereignis kommt fuer jede Galerie, auch fuer GalleryItems. Nur eine
  // virtuelle Galerie (GalleryCount > 0) bekommt hier Farbfelder. Protokolliert
  // wird nur der erste Eintrag je Zeichnen, sonst fuellt sich die Liste.
  if Item.GalleryCount = 0 then
    Exit;
  Data.Text := Format('Farbe %d', [Index + 1]);
  Color := Colors[Index mod Length(Colors)];
  if Index = 0 then
    LogEvent('OnGetGalleryItem', Format('Index = 0 von %d', [Item.GalleryCount]));
end;

procedure TDemoShowRibbonPage.SubjectDrawGalleryItem(Sender: TObject; Item: TPPGRibbonItem;
  Index: Integer; Canvas: TCanvas; const Rect: TRect; Selected, Hot: Boolean; var Handled: Boolean);
begin
  // Standard-Zeichnen behalten (Handled = False); nur ein neuer Hover-Eintrag
  // wird protokolliert, sonst kaeme jedes Zeichnen ins Protokoll
  if Hot and (Index <> FLastDrawIndex) then
  begin
    FLastDrawIndex := Index;
    LogEvent('OnCustomDrawGalleryItem', Format('Index = %d, Hot', [Index]));
  end;
end;

procedure TDemoShowRibbonPage.SubjectLauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
begin
  LogEvent('OnLauncherClick', 'Group = ' + Group.Caption);
end;

procedure TDemoShowRibbonPage.EventOccurred(const AName, ADetail: string);
var
  R: TPPGRibbon;
  Detail: string;
begin
  Detail := ADetail;
  if Subject is TPPGRibbon then
  begin
    R := TPPGRibbon(Subject);
    if (AName = 'OnChange') and (R.ActiveTab <> nil) then
      Detail := Format('TabIndex = %d (%s)', [R.TabIndex, R.ActiveTab.Caption])
    else if AName = 'OnMinimizedChange' then
      Detail := 'Minimized = ' + BoolToStr(R.Minimized, True)
    else if AName = 'OnBackstageChange' then
      Detail := 'BackstageVisible = ' + BoolToStr(R.BackstageVisible, True)
    else if AName = 'OnQuickAccessChange' then
      Detail := Format('QuickAccess.Count = %d', [R.QuickAccess.Count]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowRibbonPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if (AName = 'Tabs') or (AName = 'TabIndex') or (AName = 'QuickAccess') then
    ACategory := 'Inhalt'
  else if (AName = 'LargeImages') or (AName = 'ApplicationButtonCaption') then
    ACategory := 'Beschriftung & Bild'
  else if (AName = 'Minimized') or (AName = 'ApplicationMenu') or (AName = 'Backstage') or
    (AName = 'ShowQuickAccess') or (AName = 'QuickAccessPosition') or
    (AName = 'QuickAccessCustomizable') or (AName = 'ShowApplicationButton') then
    ACategory := 'Verhalten'
  else if AName = 'KeyTipsEnabled' then
    ACategory := 'Tastatur & Fokus';
end;

procedure TDemoShowRibbonPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Belegerfassung', 'ExRibbonInvoice',
    'Das Men{ue}band einer Belegerfassung: zwei <b>Registerkarten</b> mit <b>Gruppen</b>, gro{ss}e '
    + 'Befehle, ein <b>Split-Button</b> "Drucken" (DropDownMenu), ein <b>Umschalter</b> (rikCheck) '
    + 'und "Datei" als <b>ApplicationMenu</b>. Alle Befehle laufen {ue}ber <b>OnItemClick</b> mit '
    + 'Item.Tag. Probieren Sie: Speichern ist gesperrt, bis Sie den Beleg {ae}ndern; der '
    + '<b>Schnellzugriff</b> oben links speichert ebenfalls. Alt zeigt die KeyTips.');
  FInvoice := TInvoiceRibbon.CreateRibbon(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Berichtsdesigner', 'ExRibbonReport',
    'Ein Berichtsdesigner: eine <b>Galerie</b> mit Formatvorlagen (OnGalleryClick), Hoch- und '
    + 'Querformat als <b>Umschalt-Gruppe</b> (GroupIndex) und der <b>Dialog-Starter</b> unten rechts '
    + 'in "Seite" (ShowLauncher, OnLauncherClick). W{ae}hlen Sie in der Liste die Umsatztabelle: '
    + 'Dann erscheint die farbige <b>Kontext-Registerkarte</b> "Tabellentools" und wird gleich '
    + 'gezeigt; bei einem anderen Element verschwindet sie wieder.');
  FReport := TReportRibbon.CreateRibbon(Own, V.Live, DemoStyles);
end;

procedure TDemoShowRibbonPage.SelfTest(Check: TDemoCheck);
var
  R: TPPGRibbon;
  It: TPPGRibbonItem;
begin
  inherited SelfTest(Check);
  // Buehne: Inhalt vorhanden, Klick und Galerie erscheinen im Protokoll
  ResetSubject;
  R := TPPGRibbon(Subject);
  Check('TPPGRibbon: B' + #$00FC + 'hne mit Registerkarten und Schnellzugriff',
    (R.Tabs.Count = 3) and (R.QuickAccess.Count = 2) and (R.ActiveTab = R.Tabs[0]));
  It := R.Tabs[0].Groups[1].Items[0];
  R.ClickItem(It);
  Check('TPPGRibbon: Klick auf "Fett" schaltet um und erscheint als OnItemClick im Protokoll',
    It.Down and (EventList.Items.Count > 0) and (Pos('OnItemClick', EventList.Items[0]) > 0));
  R.SelectGalleryItem(R.Tabs[0].Groups[2].Items[0], 2);
  Check('TPPGRibbon: Galerie-Auswahl erscheint als OnGalleryClick',
    (R.Tabs[0].Groups[2].Items[0].GalleryIndex = 2) and (Pos('OnGalleryClick', EventList.Items[0]) > 0));
  R.Backstage := FBackstage;
  R.ClickApplicationButton;
  Check('TPPGRibbon: "Datei" zeigt den Backstage-Bereich, Zur' + #$00FC + 'ck schlie' + #$00DF + 't ihn',
    R.BackstageVisible and FBackstage.Visible);
  BackstageBackClick(nil);
  Check('TPPGRibbon: Backstage nach Zur' + #$00FC + 'ck geschlossen',
    (not R.BackstageVisible) and not FBackstage.Visible);
  ResetSubject;

  // Praxisbeispiel 1: Speichern-Sperre, Schnellzugriff, Umschalter, Split-Button
  Check('Beispiel Beleg: Speichern ohne '#$00C4'nderung gesperrt', not FInvoice.SaveItem.Enabled);
  FInvoice.Text.Lines.Add('Pos. 3: Material, 12,50 EUR');
  if not FInvoice.SaveItem.Enabled then
    FInvoice.Text.OnChange(FInvoice.Text);   // ohne Fenster-Handle kein EN_CHANGE
  Check('Beispiel Beleg: nach einer '#$00C4'nderung ist Speichern frei', FInvoice.SaveItem.Enabled);
  Check('Beispiel Beleg: Schnellzugriff-Eintrag wirkt auf Speichern im Band',
    (FInvoice.Ribbon.QuickAccess.Count = 1) and
    (FInvoice.Ribbon.QuickSource(FInvoice.Ribbon.QuickAccess[0]) = FInvoice.SaveItem));
  FInvoice.Ribbon.ClickQuickItem(0);
  Check('Beispiel Beleg: Schnellzugriff speichert (OnItemClick, Tag) und sperrt Speichern wieder',
    (FInvoice.LastCommand = 'Gespeichert') and not FInvoice.SaveItem.Enabled);
  FInvoice.Ribbon.ClickItem(FInvoice.GrossItem);
  Check('Beispiel Beleg: Umschalter Bruttopreise rastet ein',
    FInvoice.GrossItem.Down and (FInvoice.LastCommand = 'Preise brutto'));
  FInvoice.Ribbon.ClickItem(FInvoice.GrossItem);
  Check('Beispiel Beleg: Umschalter Bruttopreise rastet wieder aus',
    (not FInvoice.GrossItem.Down) and (FInvoice.LastCommand = 'Preise netto'));
  FInvoice.Ribbon.ClickItem(FInvoice.PrintItem);
  Check('Beispiel Beleg: Hauptteil des Split-Buttons druckt', FInvoice.LastCommand = 'Gedruckt');
  FInvoice.PrintMenu.Items[1].Click;
  Check('Beispiel Beleg: Men' + #$00FC + 'eintrag des Split-Buttons zeigt die Vorschau',
    FInvoice.LastCommand = 'Vorschau');

  // Praxisbeispiel 2: Kontext-Registerkarte, Galerie, Umschalt-Gruppe, Dialog-Starter
  Check('Beispiel Bericht: Kontext-Registerkarte anfangs ausgeblendet',
    (not FReport.TableTab.Visible) and FReport.TableTab.IsContextual);
  FReport.SelectElement(1);
  Check('Beispiel Bericht: Tabelle gew' + #$00E4 + 'hlt zeigt "Tabellentools" und wechselt dorthin',
    FReport.TableTab.Visible and (FReport.Ribbon.TabIndex = FReport.TableTab.Index));
  FReport.SelectElement(2);
  Check('Beispiel Bericht: anderes Element blendet die Kontext-Karte aus, zur' + #$00FC + 'ck auf Entwurf',
    (not FReport.TableTab.Visible) and (FReport.Ribbon.TabIndex = 0));
  FReport.Ribbon.SelectGalleryItem(FReport.StyleGallery, 2);
  Check('Beispiel Bericht: Galerie w' + #$00E4 + 'hlt die Vorlage (OnGalleryClick)',
    (FReport.StyleGallery.GalleryIndex = 2) and (FReport.LastAction = 'Vorlage: Praesentation'));
  FReport.Ribbon.ClickItem(FReport.Landscape);
  Check('Beispiel Bericht: Querformat rastet ein, Hochformat aus (GroupIndex)',
    FReport.Landscape.Down and (not FReport.Portrait.Down) and (FReport.LastAction = 'Querformat'));
  FReport.Ribbon.ClickItem(FReport.Landscape);
  Check('Beispiel Bericht: erneuter Klick l' + #$00E4 + 'sst Querformat gedr' + #$00FC + 'ckt',
    FReport.Landscape.Down);
  FReport.Ribbon.OnLauncherClick(FReport.Ribbon, FReport.PageGroup);
  Check('Beispiel Bericht: Dialog-Starter der Gruppe Seite (OnLauncherClick)',
    FReport.PageGroup.ShowLauncher and (Pos('Seite einrichten', FReport.LastAction) > 0));
  FReport.Ribbon.ClickItem(FReport.Portrait);
  FReport.Ribbon.SelectGalleryItem(FReport.StyleGallery, 0);
  FReport.SelectElement(0);
end;

initialization
  RegisterShowcasePage('TPPGRibbon', TDemoShowRibbonPage);

end.
