unit ExRibbonReport;

// Praxisbeispiel 2 zu TPPGRibbon (Demo-Seite "Buttons & Aktionen > TPPGRibbon"):
// Berichtsdesigner mit Galerie (GalleryItems, OnGalleryClick), Umschalt-
// Gruppe (GroupIndex), Dialog-Starter (ShowLauncher, OnLauncherClick) und
// einer Kontext-Registerkarte (ContextName, ContextColor, Visible, TabIndex),
// die nur erscheint, solange eine Tabelle gewaehlt ist.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.ListBox,
  PPG.Ribbon.Layout, PPG.Ribbon.Items, PPG.Ribbon;

type
  /// Berichtsdesigner: links die Elemente des Berichts, oben das Menueband.
  /// Ist die Tabelle gewaehlt, erscheint die Karte "Tabellentools".
  TReportRibbon = class(TComponent)
  private
    FRibbon: TPPGRibbon;
    FStyles: TPPGRibbonItem;
    FPortrait: TPPGRibbonItem;
    FLandscape: TPPGRibbonItem;
    FPageGroup: TPPGRibbonGroup;
    FTableTab: TPPGRibbonTab;
    FElements: TPPGListBox;
    FStatus: TPPGLabel;
    FLastAction: string;
    procedure GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
    procedure LauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
    procedure OrientationClick(Sender: TObject);
    procedure TableCommandClick(Sender: TObject);
    procedure ElementsClick(Sender: TObject);
    procedure Done(const AAction: string);
  public
    constructor CreateRibbon(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    /// Ein Element des Berichts waehlen wie per Klick in der Liste.
    procedure SelectElement(Index: Integer);
    property Ribbon: TPPGRibbon read FRibbon;
    property StyleGallery: TPPGRibbonItem read FStyles;
    property Portrait: TPPGRibbonItem read FPortrait;
    property Landscape: TPPGRibbonItem read FLandscape;
    property PageGroup: TPPGRibbonGroup read FPageGroup;
    property TableTab: TPPGRibbonTab read FTableTab;
    property Elements: TPPGListBox read FElements;
    property LastAction: string read FLastAction;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TReportRibbon.CreateRibbon(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Tab: TPPGRibbonTab;
  Group: TPPGRibbonGroup;
begin
  inherited Create(AOwner);
  FRibbon := TPPGRibbon.Create(Self);
  FRibbon.Parent := AParent;
  FRibbon.StyleManager := AStyles;
  FRibbon.ShowQuickAccess := False;      // kleiner Editor: kein Schnellzugriff
  FRibbon.ShowApplicationButton := False;
  FRibbon.OnGalleryClick := GalleryClick;
  FRibbon.OnLauncherClick := LauncherClick;

  Tab := FRibbon.Tabs.AddTab('Entwurf');
  // Galerie: feste Liste von Vorlagen, eine je Zeile
  Group := Tab.Groups.AddGroup('Formatvorlage');
  FStyles := Group.Items.Add;
  FStyles.Kind := rikGallery;
  FStyles.Caption := 'Vorlagen';
  FStyles.GalleryItems.Text := 'Standard' + sLineBreak + 'Kompakt' + sLineBreak +
    'Praesentation' + sLineBreak + 'Druck';
  FStyles.GalleryColumns := 2;
  FStyles.GalleryItemWidth := 96;
  FStyles.GalleryIndex := 0;

  // Hoch- und Querformat: gleicher GroupIndex = genau einer gedrueckt;
  // der Pfeil unten rechts oeffnet den Dialog "Seite einrichten"
  FPageGroup := Tab.Groups.AddGroup('Seite');
  FPageGroup.ShowLauncher := True;
  FPageGroup.LauncherHint := 'Seite einrichten';
  FPortrait := FPageGroup.Items.AddCheck('Hochformat', $E7C3, rsMedium, 1);
  FPortrait.Down := True;
  FPortrait.OnClick := OrientationClick;
  FLandscape := FPageGroup.Items.AddCheck('Querformat', $E7C3, rsMedium, 1);
  FLandscape.OnClick := OrientationClick;

  // Kontext-Registerkarte: farbig markiert, nur sichtbar bei gewaehlter Tabelle
  FTableTab := FRibbon.Tabs.AddTab('Tabelle');
  FTableTab.ContextName := 'Tabellentools';
  FTableTab.ContextColor := $0032A852;
  FTableTab.Visible := False;
  Group := FTableTab.Groups.AddGroup('Zeilen und Spalten');
  Group.Items.AddButton('Zeile', $E710, rsLarge, TableCommandClick);
  Group.Items.AddButton('Spalte', $E710, rsLarge, TableCommandClick);
  Group.Items.AddCheck('Summenzeile', $E8EF, rsMedium).OnClick := TableCommandClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.Align := alBottom;
  FStatus.AlignWithMargins := True;
  FStatus.Margins.SetBounds(16, 4, 16, 8);
  FStatus.Caption := 'Waehlen Sie ein Element des Berichts.';

  FElements := TPPGListBox.Create(Self);
  FElements.Parent := AParent;
  FElements.Align := alClient;
  FElements.AlignWithMargins := True;
  FElements.Margins.SetBounds(16, 8, 16, 0);
  FElements.StyleManager := AStyles;
  FElements.Items.Text := 'Ueberschrift' + sLineBreak + 'Umsatztabelle' + sLineBreak +
    'Diagramm';
  FElements.OnClick := ElementsClick;
end;

procedure TReportRibbon.SelectElement(Index: Integer);
begin
  FElements.ItemIndex := Index;
  ElementsClick(FElements);
end;

procedure TReportRibbon.ElementsClick(Sender: TObject);
var
  IsTable: Boolean;
begin
  // Die Kontext-Karte gehoert zur Auswahl: einblenden und gleich zeigen
  IsTable := FElements.ItemIndex = 1;
  FTableTab.Visible := IsTable;
  if IsTable then
    FRibbon.TabIndex := FTableTab.Index
  else if FRibbon.TabIndex = FTableTab.Index then
    FRibbon.TabIndex := 0;
  if FElements.ItemIndex >= 0 then
    Done('Gewaehlt: ' + FElements.Items[FElements.ItemIndex]);
end;

procedure TReportRibbon.GalleryClick(Sender: TObject; Item: TPPGRibbonItem; Index: Integer);
begin
  if Item = FStyles then
    Done('Vorlage: ' + FStyles.GalleryItems[Index]);
end;

procedure TReportRibbon.LauncherClick(Sender: TObject; Group: TPPGRibbonGroup);
begin
  // Hier wuerde der ausfuehrliche Dialog der Gruppe geoeffnet
  if Group = FPageGroup then
    Done('Dialog "Seite einrichten"');
end;

procedure TReportRibbon.OrientationClick(Sender: TObject);
begin
  if FLandscape.Down then
    Done('Querformat')
  else
    Done('Hochformat');
end;

procedure TReportRibbon.TableCommandClick(Sender: TObject);
begin
  Done('Tabelle: ' + TPPGRibbonItem(Sender).Caption);
end;

procedure TReportRibbon.Done(const AAction: string);
begin
  FLastAction := AAction;
  FStatus.Caption := AAction + '.';
end;
// EXAMPLE-END

end.
