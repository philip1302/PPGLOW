unit DemoPages11;

{ Demo-Seite "Kacheln" (Phase 18b): TPPGTileView als Dokumenten-Galerie mit
  Suche (Treffer hervorgehoben), Ansicht per Segment-Umschalter (Symbole,
  Kacheln, Karten), Gruppen, Mehrfachauswahl, Zoom mit Strg+Rad und eine
  virtuelle Ansicht mit 100 000 Eintraegen. }

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Panel, PPG.Labels, PPG.Items, PPG.SearchEdit, PPG.ToggleSwitch,
  PPG.RadioGroup, PPG.TileView, DemoKit;

type
  TDemoTilesPage = class(TDemoPage)
  private
    FSearch: TPPGSearchEdit;
    FStyle: TPPGRadioGroup;
    FGrouped: TPPGToggleSwitch;
    FTiles: TPPGTileView;
    FVirtual: TPPGTileView;
    FResult: TPPGLabel;
    FVirtualResult: TPPGLabel;
    procedure SearchChange(Sender: TObject; const SearchText: string);
    procedure StyleChange(Sender: TObject);
    procedure GroupedChange(Sender: TObject);
    procedure TilesChange(Sender: TObject);
    procedure TileIcon(Sender: TObject; Index: Integer; var CodePoint: Word);
    procedure VirtualItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
    procedure VirtualIcon(Sender: TObject; Index: Integer; var CodePoint: Word);
    procedure VirtualChange(Sender: TObject);
    procedure UpdateResult;
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

const
  ColW = 484;
  FullW = 2 * ColW + CardGap;
  GalleryH = 560;
  VirtualH = 300;
  Kinds: array[0..3] of string = ('Berichte', 'Tabellen', 'Bilder', 'Pr{ae}sentationen');
  KindIcons: array[0..3] of Word = ($E8A5, $E80A, $EB9F, $E8FD);
  Names: array[0..3, 0..5] of string = (
    ('Quartalsbericht Q3', 'Jahresabschluss 2025', 'Pr{ue}fbericht Anlage 4', 'Besprechung Vertrieb',
      'Wartungsprotokoll', 'Lieferantenbewertung'),
    ('Lagerliste', 'Preisliste 2026', 'Kostenstellen', 'Urlaubsplanung', 'Inventur Halle B',
      'Budget Marketing'),
    ('Produktfoto Akkuschrauber', 'Logo hell', 'Logo dunkel', 'Messestand Entwurf',
      'Hallenplan', 'Teamfoto'),
    ('Kundenpr{ae}sentation', 'Schulung PPGlow', 'Roadmap 2027', 'Projektstart', 'Messe-Vortrag',
      'Strategie'));

procedure TDemoTilesPage.Build;
var
  Card: TPPGPanel;
  Y, K, I: Integer;
  It: TPPGItem;
begin
  NewPageHeader(Own, Sheet, 'Kacheln', 'TPPGTileView: Galerie mit Kacheln, Karten oder ' +
    'Symbolen, Suche mit Hervorhebung, Gruppen, Mehrfachauswahl (Strg/Umschalt, Gummiband) ' +
    'und Zoom mit Strg+Mausrad {-} Export und Druck wie beim Grid.');

  Card := NewCard(Own, Sheet, PageX, PageContentTop, FullW, GalleryH, 'Dokumente',
    'Tippen Sie in die Suche, wechseln Sie die Ansicht oder klappen Sie eine Gruppe zu.');
  Y := Card.Tag;
  FSearch := TPPGSearchEdit.Create(Own);
  FSearch.Parent := Card;
  FSearch.SetBounds(CardPad, Y, 260, CtlH);
  FSearch.TextHint := 'Dokumente durchsuchen';
  FSearch.OnSearch := SearchChange;
  FStyle := TPPGRadioGroup.Create(Own);
  FStyle.Parent := Card;
  FStyle.ChoiceStyle := csSegmented;
  FStyle.ShowFrame := False;
  FStyle.SetBounds(CardPad + 280, Y, 300, CtlH + 2);
  FStyle.Items.CommaText := 'Symbole,Kacheln,Karten';
  FStyle.ItemsEx[0].Icon := $ECA5;
  FStyle.ItemsEx[1].Icon := $E8FD;
  FStyle.ItemsEx[2].Icon := $E8B9;
  FStyle.ItemIndex := 1;
  FStyle.OnChange := StyleChange;
  NewLabel(Own, Card, CardPad + 610, Y + 7, 0, 'Gruppiert', tkBody);
  FGrouped := TPPGToggleSwitch.Create(Own);
  FGrouped.Parent := Card;
  FGrouped.SetBounds(CardPad + 690, Y + 4, 44, 24);
  FGrouped.Checked := True;
  FGrouped.OnChange := GroupedChange;

  FTiles := TPPGTileView.Create(Own);
  FTiles.Parent := Card;
  FTiles.SetBounds(CardPad, Y + CtlH + 12, FullW - 2 * CardPad, GalleryH - Y - CtlH - 12 - 48);
  FTiles.MultiSelect := True;
  FTiles.ShowHint := True;
  FTiles.BeginUpdate;
  try
    for K := 0 to 3 do
      for I := 0 to 5 do
      begin
        It := FTiles.Items.Add(L(Names[K, I]));
        It.Group := L(Kinds[K]);
        It.Detail := Format('%d KB {.} %d. Oktober 2026', [(K + 1) * 120 + I * 37, 1 + (K * 6 + I) mod 28]);
        It.Detail := L(It.Detail);
        It.Tag := K;
        if (K * 6 + I) mod 7 = 2 then
          It.Badge := 'Neu';
      end;
  finally
    FTiles.EndUpdate;
  end;
  FTiles.OnGetItemIcon := TileIcon;
  FTiles.OnChange := TilesChange;
  Host.RegisterSpecial('tiles', FTiles);
  FResult := NewResult(Own, Card, 'Auswahl');
  UpdateResult;

  Card := NewCard(Own, Sheet, PageX, PageContentTop + GalleryH + CardGap, FullW, VirtualH,
    'Virtuell: 100 000 Dateien', 'Die Daten liefert OnGetItem erst beim Zeichnen {-} ' +
    'Layout, Scrollen und Suche bleiben fl{ue}ssig.');
  FVirtual := TPPGTileView.Create(Own);
  FVirtual.Parent := Card;
  FVirtual.SetBounds(CardPad, Card.Tag, FullW - 2 * CardPad, VirtualH - Card.Tag - 48);
  FVirtual.TileStyle := tsIcons;
  FVirtual.Zoom := 80;
  FVirtual.OnGetItem := VirtualItem;
  FVirtual.OnGetItemIcon := VirtualIcon;
  FVirtual.OnChange := VirtualChange;
  FVirtual.OwnerData := True;
  FVirtual.ItemCount := 100000;
  FVirtualResult := NewResult(Own, Card, 'Gew{ae}hlt');
  VirtualChange(nil);
end;

procedure TDemoTilesPage.TileIcon(Sender: TObject; Index: Integer; var CodePoint: Word);
begin
  CodePoint := KindIcons[FTiles.Items[Index].Tag];
end;

procedure TDemoTilesPage.VirtualItem(Sender: TObject; Index: Integer; var Data: TPPGItemData);
begin
  Data.Text := Format('Datei %.6d.dat', [Index + 1]);
  Data.Detail := Format('%d KB', [(Index * 37) mod 9000 + 1]);
end;

procedure TDemoTilesPage.VirtualIcon(Sender: TObject; Index: Integer; var CodePoint: Word);
begin
  CodePoint := KindIcons[Index mod 4];
end;

procedure TDemoTilesPage.VirtualChange(Sender: TObject);
begin
  if FVirtual.ItemIndex >= 0 then
    SetResult(FVirtualResult, Format('Datei %.6d.dat', [FVirtual.ItemIndex + 1]))
  else
    SetResult(FVirtualResult, '{-}');
end;

procedure TDemoTilesPage.SearchChange(Sender: TObject; const SearchText: string);
begin
  FTiles.FilterText := SearchText;
  UpdateResult;
end;

procedure TDemoTilesPage.StyleChange(Sender: TObject);
begin
  FTiles.TileStyle := TPPGTileStyle(FStyle.ItemIndex);
end;

procedure TDemoTilesPage.GroupedChange(Sender: TObject);
begin
  FTiles.GroupView := FGrouped.Checked;
end;

procedure TDemoTilesPage.TilesChange(Sender: TObject);
begin
  UpdateResult;
end;

procedure TDemoTilesPage.UpdateResult;
begin
  SetResult(FResult, Format('%d von %d sichtbar {.} %d gew{ae}hlt', [FTiles.VisibleCount,
    FTiles.Items.Count, FTiles.SelCount]));
end;

procedure TDemoTilesPage.SelfTest(Check: TDemoCheck);
begin
  SearchChange(nil, 'logo');
  Check('Kacheln: Suche filtert', FTiles.VisibleCount = 2);
  SearchChange(nil, '');
  Check('Kacheln: alle sichtbar', FTiles.VisibleCount = 24);
  FStyle.ItemIndex := 2;
  StyleChange(nil);
  Check('Kacheln: Ansicht Karten', FTiles.TileStyle = tsCards);
  FTiles.GroupCollapsed[L(Kinds[2])] := True;
  Check('Kacheln: Gruppe zugeklappt', FTiles.VisibleCount = 18);
  FTiles.GroupCollapsed[L(Kinds[2])] := False;
  FTiles.ItemIndex := 3;
  Check('Kacheln: Auswahl', FTiles.Selected[3]);
  Check('Kacheln: virtuell 100 000', FVirtual.VisibleCount = 100000);
  FStyle.ItemIndex := 1;
  StyleChange(nil);
end;

end.
