unit DemoPages10;

{ Demo-Seite "Anpassung": Markenfarbe fuer die ganze Anwendung, Grid-Bereiche
  (Kopf, Zebra, Auswahl, Linien), Eintraege mit eigener Farbe und
  Custom-Draw, Button-Gruppe mit eckigen Innenkanten, Schatten und
  Nur-Lese-Optik. Grundlage: Docs\Anforderungen-Anpassbarkeit.md. }

interface

uses
  System.SysUtils, System.Classes, System.Types, Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Panel, PPG.Labels, PPG.Button, PPG.ToggleSwitch, PPG.Edit,
  PPG.Grid, PPG.Grid.Columns, PPG.ListBox, PPG.Items, PPG.CustomDraw, PPG.StyleManager,
  DemoKit;

type
  TDemoCustomPage = class(TDemoPage)
  private
    FManager: TPPGStyleManager;
    FAccent: array[0..3] of TPPGButton;
    FGrid: TPPGGrid;
    FZebra: TPPGToggleSwitch;
    FHeader: TPPGToggleSwitch;
    FList: TPPGListBox;
    FSegments: array[0..2] of TPPGButton;
    FShadowBtn: TPPGButton;
    FReadOnly: TPPGEdit;
    FResult: TPPGLabel;
    procedure AccentClick(Sender: TObject);
    procedure ZebraChange(Sender: TObject);
    procedure HeaderChange(Sender: TObject);
    procedure SegmentClick(Sender: TObject);
    procedure ListDraw(Sender: TObject; Canvas: TCanvas; Index: Integer; const ARect: TRect;
      State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
    procedure BuildBrand(Y: Integer);
    procedure BuildGrid(Y: Integer);
    procedure BuildElements(Y: Integer);
    procedure LayoutSegments;
  protected
    procedure Build; override;
  public
    procedure AppearanceChanged; override;
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

type
  TButtonAccess = class(TPPGButton);

const
  ColW = 484;
  FullW = 2 * ColW + CardGap;
  BrandH = 150;
  GridH = 330;
  ElemH = 300;
  AccentColors: array[0..3] of TColor = (clDefault, $00B05A8E, $00327A1E, $000050C8);
  AccentNames: array[0..3] of string = ('Preset', 'Violett', 'Gr{ue}n', 'Orange');

procedure TDemoCustomPage.Build;
begin
  NewPageHeader(Own, Sheet, 'Anpassung', L('Markenfarbe, Bereiche, einzelne Eintr{ae}ge und eigenes ') +
    L('Zeichnen {-} ohne eigenen Renderer. Nicht gesetzte Werte kommen weiter aus dem Preset.'));
  BuildBrand(PageContentTop);
  BuildGrid(PageContentTop + BrandH + CardGap);
  BuildElements(PageContentTop + BrandH + CardGap + GridH + CardGap);
end;

procedure TDemoCustomPage.BuildBrand(Y: Integer);
var
  Card: TPPGPanel;
  I: Integer;
begin
  Card := NewCard(Own, Sheet, PageX, Y, FullW, BrandH, 'Markenfarbe',
    L('TPPGStyleManager.AccentColor: eine Farbe f{ue}r Fokus, Auswahl, Fortschritt, Schalter und ') +
    L('Links in allen Presets, hell und dunkel. Speichern als Theme-Datei mit SaveToFile.'));
  FManager := TPPGStyleManager.Create(Own);
  for I := 0 to High(FAccent) do
  begin
    FAccent[I] := NewButton(Own, Card, CardPad + I * 132, Card.Tag, 120, AccentNames[I], AccentClick);
    FAccent[I].Tag := I;
    FAccent[I].GroupIndex := 31;
    FAccent[I].Down := I = 0;
  end;
  FResult := NewResult(Own, Card, 'Akzent');
end;

procedure TDemoCustomPage.BuildGrid(Y: Integer);
const
  Names: array[0..7] of string = ('Schrauben M4', 'Muttern M4', 'Unterlegscheiben', 'D{ue}bel 6 mm',
    'Holzleim', 'Schleifpapier', 'Kabelbinder', 'Isolierband');
var
  Card: TPPGPanel;
  C: TPPGGridColumn;
  I: Integer;
begin
  Card := NewCard(Own, Sheet, PageX, Y, FullW, GridH, 'Grid-Bereiche',
    L('Styles.Header, AlternateRow, Selection, GridLine; Spalte "Bestand" mit eigenem Style und ') +
    L('rechtsb{ue}ndigem Kopf (TitleAlignment).'));
  FZebra := TPPGToggleSwitch.Create(Own);
  FZebra.Parent := Card;
  FZebra.SetBounds(CardPad, Card.Tag, 180, CtlH);
  FZebra.Caption := 'Zebra-Zeilen';
  FZebra.Checked := True;
  FZebra.OnChange := ZebraChange;
  FHeader := TPPGToggleSwitch.Create(Own);
  FHeader.Parent := Card;
  FHeader.SetBounds(CardPad + 196, Card.Tag, 200, CtlH);
  FHeader.Caption := 'Eigener Kopf';
  FHeader.Checked := True;
  FHeader.OnChange := HeaderChange;
  FGrid := TPPGGrid.Create(Own);
  FGrid.Parent := Card;
  FGrid.SetBounds(CardPad, Card.Tag + CtlH + 10, FullW - 2 * CardPad, GridH - Card.Tag - CtlH - 30);
  FGrid.FixedCols := 0;
  C := FGrid.Columns.Add;
  C.Title := 'Artikel';
  C.Width := 360;
  C := FGrid.Columns.Add;
  C.Title := 'Bestand';
  C.Width := 140;
  C.Alignment := taRightJustify;
  C.TitleAlignment := gtaRight;
  C.Style.TextColor := $00327A1E;
  C.Style.FontStyle := [fsBold];
  FGrid.RowCount := Length(Names) + 1;
  for I := 0 to High(Names) do
  begin
    FGrid.Cells[0, I + 1] := L(Names[I]);
    FGrid.Cells[1, I + 1] := IntToStr((I * 47) mod 300 + 12);
  end;
  FGrid.Styles.Selection.Color := $00F5E6D2;
  FGrid.Styles.Selection.TextColor := clBlack;
  FGrid.Styles.GridLine.Color := $00E0E0E0;
  ZebraChange(nil);
  HeaderChange(nil);
end;

procedure TDemoCustomPage.BuildElements(Y: Integer);
var
  Card: TPPGPanel;
  It: TPPGItem;
  I, X: Integer;
begin
  // Links: Liste mit Farbe je Eintrag und Custom-Draw
  Card := NewCard(Own, Sheet, PageX, Y, ColW, ElemH, 'Eintr{ae}ge',
    L('Item.Color/TextColor/FontStyle und OnCustomDrawItem: Eintr{ae}ge mit "!" werden rot und fett.'));
  FList := TPPGListBox.Create(Own);
  FList.Parent := Card;
  FList.SetBounds(CardPad, Card.Tag, ColW - 2 * CardPad, ElemH - Card.Tag - 20);
  FList.Styles.AlternateRow.Color := $00FAF7F2;
  FList.OnCustomDrawItem := ListDraw;
  FList.ItemsEx.Add(L('Angebot an M{ue}ller GmbH'), -1);
  FList.ItemsEx.Add(L('Rechnung 2026-117 {ue}berf{ae}llig!'), -1);
  It := FList.ItemsEx.Add(L('Neukunde: Becker & S{oe}hne'), -1);
  It.Color := $00D7F0DC;
  It.FontStyle := [fsBold];
  FList.ItemsEx.Add(L('Lieferung best{ae}tigt'), -1);
  FList.ItemsEx.Add(L('Mahnung vorbereiten!'), -1);
  It := FList.ItemsEx.Add(L('Archiviert'), -1);
  It.TextColor := clGray;
  It.FontStyle := [fsItalic];

  // Rechts: Button-Gruppe, Schatten, Nur-Lese-Feld
  Card := NewCard(Own, Sheet, PageX + ColW + CardGap, Y, ColW, ElemH, 'Form und Zust{ae}nde',
    L('RoundedCorners (Segment-Gruppe), Shadow und ReadOnlyStyle.'));
  X := CardPad;
  for I := 0 to 2 do
  begin
    FSegments[I] := TPPGButton.Create(Own);
    FSegments[I].Parent := Card;
    FSegments[I].SetBounds(X, Card.Tag, 110, CtlH);
    FSegments[I].GroupIndex := 32;
    FSegments[I].Tag := I;
    FSegments[I].OnClick := SegmentClick;
  end;
  FSegments[0].Caption := 'Tag';
  FSegments[1].Caption := 'Woche';
  FSegments[2].Caption := 'Monat';
  FSegments[0].RoundedCorners := [pcTopLeft, pcBottomLeft];
  FSegments[1].RoundedCorners := [];
  FSegments[2].RoundedCorners := [pcTopRight, pcBottomRight];
  FSegments[1].Down := True;
  LayoutSegments;
  FShadowBtn := TPPGButton.Create(Own);
  FShadowBtn.Parent := Card;
  FShadowBtn.SetBounds(CardPad, Card.Tag + CtlH + 24, 200, CtlH + 16);
  FShadowBtn.Caption := 'Mit Schatten';
  FShadowBtn.Shadow.Size := 6;
  FShadowBtn.Shadow.Opacity := 90;
  NewLabel(Own, Card, CardPad, Card.Tag + 2 * CtlH + 56, ColW - 2 * CardPad, 'Nur lesen:', tkCaption);
  FReadOnly := TPPGEdit.Create(Own);
  FReadOnly.Parent := Card;
  FReadOnly.SetBounds(CardPad, Card.Tag + 2 * CtlH + 78, ColW - 2 * CardPad, CtlH);
  FReadOnly.Text := L('Kundennummer 10-4711 (nicht {ae}nderbar)');
  FReadOnly.ReadOnlyStyle.Color := $00F0F0F0;
  FReadOnly.ReadOnlyStyle.TextColor := $00606060;
  FReadOnly.ReadOnly := True;
end;

procedure TDemoCustomPage.LayoutSegments;
var
  I, X, Inset: Integer;
begin
  // Koerper ohne Luecke aneinander: kein Glow-Rand (das Preset setzt ihn
  // bei jedem Wechsel neu), benachbarte Buttons teilen eine Randlinie
  X := FSegments[0].Left;
  for I := 0 to High(FSegments) do
  begin
    FSegments[I].Appearance.GlowSize := 0;
    Inset := TButtonAccess(FSegments[I]).LayoutBodyRect.Left;
    FSegments[I].Left := X - Inset;
    Inc(X, FSegments[I].Width - 2 * Inset - 1);
  end;
end;

procedure TDemoCustomPage.AppearanceChanged;
begin
  inherited AppearanceChanged;
  if FSegments[0] <> nil then
    LayoutSegments;
end;

procedure TDemoCustomPage.AccentClick(Sender: TObject);
var
  I: Integer;
begin
  I := TComponent(Sender).Tag;
  FManager.AccentColor := AccentColors[I];
  SetResult(FResult, AccentNames[I]);
  Host.Log('Anpassung', L('Markenfarbe: ' + AccentNames[I]));
end;

procedure TDemoCustomPage.ZebraChange(Sender: TObject);
begin
  if FZebra.Checked then
    FGrid.Styles.AlternateRow.Color := $00FAF5EE
  else
    FGrid.Styles.AlternateRow.Color := clDefault;
end;

procedure TDemoCustomPage.HeaderChange(Sender: TObject);
begin
  if FHeader.Checked then
  begin
    FGrid.Styles.Header.Color := $00704214;
    FGrid.Styles.Header.TextColor := clWhite;
    FGrid.Styles.Header.FontStyle := [fsBold];
  end
  else
    FGrid.Styles.Header.Clear;
end;

procedure TDemoCustomPage.SegmentClick(Sender: TObject);
begin
  SetResult(FResult, 'Ansicht ' + TPPGButton(Sender).Caption);
end;

procedure TDemoCustomPage.ListDraw(Sender: TObject; Canvas: TCanvas; Index: Integer;
  const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean);
begin
  if Pos('!', FList.ItemsEx[Index].Text) > 0 then
  begin
    if not (idsSelected in State) then
      Style.TextColor := $002020C0;
    Style.FontStyle := Style.FontStyle + [fsBold];
  end;
end;

procedure TDemoCustomPage.SelfTest(Check: TDemoCheck);
var
  Old: TColor;
begin
  Old := PPGDefaultTokens(False).Accent;
  DemoClick(FAccent[1]);
  Check('Anpassung: Markenfarbe gilt', PPGDefaultTokens(False).Accent <> Old);
  DemoClick(FAccent[0]);
  Check('Anpassung: Markenfarbe zurueck', FManager.AccentColor = clDefault);
  Check('Anpassung: Zebra an', FGrid.Styles.AlternateRow.Color <> clDefault);
  FZebra.Checked := False;
  Check('Anpassung: Zebra aus', FGrid.Styles.AlternateRow.Color = clDefault);
  FZebra.Checked := True;
  FHeader.Checked := False;
  Check('Anpassung: Kopf wie Preset', FGrid.Styles.Header.IsEmpty);
  FHeader.Checked := True;
  Check('Anpassung: Segment eckig', FSegments[1].RoundedCorners = []);
  Check('Anpassung: Schatten', FShadowBtn.Shadow.Size = 6);
  Check('Anpassung: ReadOnly-Stil', FReadOnly.ReadOnly and not FReadOnly.ReadOnlyStyle.IsEmpty);
  Check('Anpassung: sechs Eintraege', FList.ItemsEx.Count = 6);
end;

end.
