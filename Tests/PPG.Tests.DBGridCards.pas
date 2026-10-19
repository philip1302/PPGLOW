unit PPG.Tests.DBGridCards;

{ Tests fuer die Kartenansicht des DB-Grids (ViewStyle = dgvCards): Masse
  und Anordnung, Treffer, Tastatur, Maus, Mehrfachauswahl, Puffer und
  Scrollen, Wechsel Tabelle <-> Karten, Zeichnen (hell, dunkel, GDI),
  Owner-Draw, Editor, UI Automation, DPI und Streaming. Daten aus einem
  TClientDataSet im Speicher (MidasLib statisch gelinkt). Gezeichnet wird
  mit PaintTo in eine Bitmap; ein Formular wird nur auf dem unsichtbaren
  Testdesktop (/hidden) angezeigt (Editor-Test).

  Erwartete Masse gelten fuer 96 PPI (ForcePPI96), BorderStyle = bsNone und
  ScrollBarMode = sbmNever: Ansicht = Client, 640 x 400. CardWidth 200,
  CardSpacing 10, Innenabstand 8, Feldzeile 24 (DefaultRowHeight). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Grids, Vcl.ExtCtrls,
  Vcl.DBGrids, Data.DB, Datasnap.DBClient, MidasLib,
  System.Math, PPG.Types, PPG.Grid, PPG.DB.Grid, PPG.Theme, PPG.Render.Intf, PPG.UIA,
  PPG.Render.Registry, PPG.Controls.Scroll, PPG.Exceptions, PPG.Tests.Controls, PPG.Tests.Phase9c,
  PPG.TestDesktop;

type
  TDBGridCardsTests = class(TDBTestCase)
  private
    FDrawCalls: Integer;
    FDrawIds: TStringList;
    /// Grid in Kartenansicht, 640 x 400, Spalten ID, Name, Aktiv, Preis.
    function NewGrid(N: Integer; Cols: Boolean = True; AParent: TWinControl = nil): TPPGDBGrid;
    procedure Key(G: TPPGDBGrid; AKey: Word; Shift: TShiftState = []);
    /// Klick auf den Wert des Felds FieldIdx in der Karte der Pufferzeile ARow.
    procedure ClickCard(G: TPPGDBGrid; ARow: Integer; FieldIdx: Integer = 0; Keys: Integer = 0);
    function ValueRect(G: TPPGDBGrid; ARow, FieldIdx: Integer): TRect;
    function ActiveRow(G: TPPGDBGrid): Integer;
    function Id: Integer;
    function SelectedIds(G: TPPGDBGrid): string;
    /// Prueft: aktive Karte in ihrer Spalte (RecNo), alle sichtbaren Plaetze
    /// mit Karten belegt, aktive Karte im Bild.
    procedure CheckLayoutConsistent(G: TPPGDBGrid; const Msg: string);
    procedure RecordDraw(Sender: TObject; const Rect: TRect; DataCol: Integer;
      Column: TPPGDBGridColumn; State: TGridDrawState);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure DefaultsAndRangeChecks;
    procedure StreamingKeepsCardProperties;
    procedure MetricsAndCardRects;
    procedure LabelWidthAndNarrowView;
    procedure HitTestFindsCardAndField;
    procedure KeyboardMovesBetweenCards;
    procedure ClickSelectsRecordAndField;
    procedure BufferStaysAlignedWhileNavigating;
    procedure ScrollingMovesRecordIntoView;
    procedure ResizeReflowsCards;
    procedure MultiSelectCtrlShiftAndKeys;
    procedure SwitchTableAndCards;
    procedure PaintLightDarkAndGdi;
    procedure DrawColumnCellPerField;
    procedure CheckBoxToggleInCard;
    procedure TallCardRevealsFocusedField;
    procedure EditorOpensOnF2AndDoubleClick;
    procedure UiaFollowsCards;
    procedure DpiScalesCards;
    procedure WithoutRecNoShowsLoadedCards;
  end;

  /// Datenmenge ohne RecNo (wie manche Server-Cursor): IsSequenced = False.
  TNoSeqDataSet = class(TClientDataSet)
  public
    function IsSequenced: Boolean; override;
  end;

implementation

type
  TGridAccess = class(TPPGDBGrid);

const
  // Erwartete Masse bei 96 PPI (siehe Kopf)
  ExpGap = 10;
  ExpPad = 8;
  ExpLine = 24;
  ExpCardW = 200;
  ExpCardH = 2 * ExpPad + 4 * ExpLine; // 4 Felder = 112
  ExpRowH = ExpCardH + ExpGap;         // 122

/// Referenzwerte gelten fuer 96 PPI (wie Audit 11a #5).
procedure ForcePPI96(C: TControl);
begin
{$IF CompilerVersion >= 33.0}
  if C.CurrentPPI <> 96 then
    C.ScaleForPPI(96);
{$IFEND}
end;

function Center(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function RectText(const R: TRect): string;
begin
  Result := Format('(%d,%d,%d,%d)', [R.Left, R.Top, R.Right, R.Bottom]);
end;

{ TNoSeqDataSet }

function TNoSeqDataSet.IsSequenced: Boolean;
begin
  Result := False;
end;

{ TDBGridCardsTests }

procedure TDBGridCardsTests.SetUp;
begin
  inherited SetUp;
  FDrawIds := TStringList.Create;
  FDrawCalls := 0;
end;

procedure TDBGridCardsTests.TearDown;
begin
  FreeAndNil(FDrawIds);
  inherited TearDown;
end;

function TDBGridCardsTests.NewGrid(N: Integer; Cols: Boolean; AParent: TWinControl): TPPGDBGrid;

  procedure AddCol(const FieldName: string);
  begin
    TPPGDBGridColumn(Result.Columns.Add).FieldName := FieldName;
  end;

begin
  FillData(N);
  Result := TPPGDBGrid.Create(FForm);
  if AParent = nil then
    AParent := FForm;
  Result.Parent := AParent;
  ForcePPI96(Result);
  Result.BorderStyle := bsNone;
  Result.ScrollBarMode := sbmNever;
  Result.Animation.Enabled := False;
  Result.SmoothScrolling := False;
  Result.SetBounds(0, 0, 640, 400);
  Result.HandleNeeded;
  Result.ViewStyle := dgvCards;
  Result.CardWidth := ExpCardW;
  Result.CardSpacing := ExpGap;
  if Cols then
  begin
    AddCol('ID');
    AddCol('Name');
    AddCol('Aktiv');
    AddCol('Preis');
  end;
  Result.DataSource := FSource;
end;

procedure TDBGridCardsTests.Key(G: TPPGDBGrid; AKey: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := AKey;
  TGridAccess(G).KeyDown(K, Shift);
end;

function TDBGridCardsTests.ValueRect(G: TPPGDBGrid; ARow, FieldIdx: Integer): TRect;
begin
  Result := G.CellRect(TGridAccess(G).FixedCols + FieldIdx,
    G.VisualRow(TGridAccess(G).FixedRows + ARow));
end;

procedure TDBGridCardsTests.ClickCard(G: TPPGDBGrid; ARow, FieldIdx, Keys: Integer);
var
  R: TRect;
  P: TPoint;
  LP: LPARAM;
begin
  R := ValueRect(G, ARow, FieldIdx);
  CheckFalse(IsRectEmpty(R), 'Feld sichtbar (Pufferzeile ' + IntToStr(ARow) + ')');
  P := Center(R);
  LP := MakeLParam(Word(SmallInt(P.X)), Word(SmallInt(P.Y)));
  G.Perform(WM_LBUTTONDOWN, MK_LBUTTON or Keys, LP);
  G.Perform(WM_LBUTTONUP, Keys, LP);
end;

function TDBGridCardsTests.ActiveRow(G: TPPGDBGrid): Integer;
begin
  Result := TGridAccess(G).DataLink.ActiveRecord;
end;

function TDBGridCardsTests.Id: Integer;
begin
  Result := FData.FieldByName('ID').AsInteger;
end;

function TDBGridCardsTests.SelectedIds(G: TPPGDBGrid): string;
var
  I: Integer;
  B: TBookmark;
  L: TStringList;
begin
  // Nur fuer Datenmengen, die ganz im Puffer stehen (Lage bleibt gleich)
  L := TStringList.Create;
  try
    B := FData.Bookmark;
    FData.DisableControls;
    try
      for I := 0 to G.SelectedRows.Count - 1 do
      begin
        FData.Bookmark := G.SelectedRows[I];
        L.Add(Format('%.4d', [Id]));
      end;
      FData.Bookmark := B;
    finally
      FData.EnableControls;
    end;
    L.Sort;
    for I := 0 to L.Count - 1 do
      L[I] := IntToStr(StrToInt(L[I]));
    L.Delimiter := ',';
    Result := L.DelimitedText;
  finally
    L.Free;
  end;
end;

procedure TDBGridCardsTests.CheckLayoutConsistent(G: TPPGDBGrid; const Msg: string);
var
  M: TPPGDBGridCardMetrics;
  A, I, Expected, Found, Row, Top, Total: Integer;
  R, Tmp: TRect;
begin
  M := G.CardMetrics;
  Total := FData.RecordCount;
  A := FData.RecNo - 1;
  // Aktive Karte steht in der Spalte ihrer Satznummer und ganz im Bild
  R := G.CardRect(ActiveRow(G));
  CheckEquals(M.View.Left + M.Gap + (A mod M.PerRow) * (M.CardW + M.Gap), R.Left,
    Msg + ': Spalte der aktiven Karte (Satz ' + IntToStr(A + 1) + ')');
  CheckTrue((R.Top >= M.View.Top) and (R.Bottom <= M.View.Bottom),
    Msg + ': aktive Karte im Bild ' + RectText(R));
  // Jeder sichtbare Platz einer Kartenzeile hat seine Karte (keine Luecken)
  Expected := 0;
  for Row := 0 to (Total - 1) div M.PerRow do
  begin
    Top := M.View.Top + M.Gap + Row * M.RowH - G.ScrollY;
    if (Top < M.View.Bottom) and (Top + M.CardH > M.View.Top) then
      Inc(Expected, Min(M.PerRow, Total - Row * M.PerRow));
  end;
  Found := 0;
  for I := 0 to TGridAccess(G).DataLink.RecordCount - 1 do
    if IntersectRect(Tmp, G.CardRect(I), M.View) then
      Inc(Found);
  CheckEquals(Expected, Found, Msg + ': sichtbare Karten geladen');
end;

procedure TDBGridCardsTests.RecordDraw(Sender: TObject; const Rect: TRect; DataCol: Integer;
  Column: TPPGDBGridColumn; State: TGridDrawState);
begin
  Inc(FDrawCalls);
  if DataCol = 0 then
    FDrawIds.Add(IntToStr(Column.Field.AsInteger));
end;

procedure TDBGridCardsTests.DefaultsAndRangeChecks;
var
  G: TPPGDBGrid;
begin
  G := TPPGDBGrid.Create(FForm);
  CheckTrue(G.ViewStyle = dgvTable, 'Vorgabe Tabelle');
  CheckEquals(280, G.CardWidth);
  CheckEquals(8, G.CardSpacing);
  CheckEquals(110, G.CardLabelWidth);
  CheckEquals(0, G.CardsPerRow, 'Tabelle: keine Karten');
  try
    G.CardWidth := 59;
    Fail('CardWidth 59');
  except
    on E: EPPGPropertyError do
      ;
  end;
  CheckEquals(280, G.CardWidth, 'unveraendert');
  try
    G.CardSpacing := -1;
    Fail('CardSpacing -1');
  except
    on E: EPPGPropertyError do
      ;
  end;
  CheckEquals(8, G.CardSpacing, 'unveraendert');
  try
    G.CardLabelWidth := 2001;
    Fail('CardLabelWidth 2001');
  except
    on E: EPPGPropertyError do
      ;
  end;
  CheckEquals(110, G.CardLabelWidth, 'unveraendert');
  G.CardWidth := 60;
  G.CardSpacing := 0;
  G.CardLabelWidth := 0;
  CheckEquals(60, G.CardWidth);
  CheckEquals(0, G.CardSpacing);
  CheckEquals(0, G.CardLabelWidth);
  // Ohne Datenmenge und ohne Fenster: Umschalten ohne Fehler
  G.ViewStyle := dgvCards;
  CheckTrue(G.ViewStyle = dgvCards);
  CheckTrue(IsRectEmpty(G.CardRect(0)), 'keine Karte ohne Daten');
end;

procedure TDBGridCardsTests.StreamingKeepsCardProperties;
var
  G, G2: TPPGDBGrid;
  M: TMemoryStream;
  T: TStringStream;
begin
  G := TPPGDBGrid.Create(nil);
  M := TMemoryStream.Create;
  T := TStringStream.Create('');
  try
    // Vorgaben werden nicht gespeichert
    M.WriteComponent(G);
    M.Position := 0;
    ObjectBinaryToText(M, T);
    CheckEquals(0, Pos('ViewStyle', T.DataString), 'Vorgabe ViewStyle nicht gespeichert');
    CheckEquals(0, Pos('CardWidth', T.DataString), 'Vorgabe CardWidth nicht gespeichert');
    G.ViewStyle := dgvCards;
    G.CardWidth := 320;
    G.CardSpacing := 12;
    G.CardLabelWidth := 0;
    M.Clear;
    M.WriteComponent(G);
    M.Position := 0;
    G2 := TPPGDBGrid(M.ReadComponent(nil));
    try
      CheckTrue(G2.ViewStyle = dgvCards, 'ViewStyle');
      CheckEquals(320, G2.CardWidth, 'CardWidth');
      CheckEquals(12, G2.CardSpacing, 'CardSpacing');
      CheckEquals(0, G2.CardLabelWidth, 'CardLabelWidth');
    finally
      G2.Free;
    end;
  finally
    T.Free;
    M.Free;
    G.Free;
  end;
end;

procedure TDBGridCardsTests.MetricsAndCardRects;
var
  G: TPPGDBGrid;
  M: TPPGDBGridCardMetrics;
begin
  G := NewGrid(30);
  M := G.CardMetrics;
  CheckEquals(ExpGap, M.Gap, 'Abstand');
  CheckEquals(ExpPad, M.Pad, 'Innenabstand');
  CheckEquals(ExpLine, M.LineH, 'Feldzeile');
  CheckEquals(4, M.Fields, 'sichtbare Felder');
  CheckEquals(ExpCardW, M.CardW, 'Breite');
  CheckEquals(ExpCardH, M.CardH, 'Hoehe aus den Feldern');
  CheckEquals(3, M.PerRow, '(640 - 10) div 210');
  CheckEquals(3, G.CardsPerRow);
  CheckEquals(110, M.LabelW, 'Beschriftung');
  CheckEquals(RectText(Rect(10, 10, 210, 122)), RectText(G.CardRect(0)), 'Karte 1');
  CheckEquals(RectText(Rect(220, 10, 420, 122)), RectText(G.CardRect(1)), 'Karte 2');
  CheckEquals(RectText(Rect(430, 10, 630, 122)), RectText(G.CardRect(2)), 'Karte 3');
  CheckEquals(RectText(Rect(10, 132, 210, 244)), RectText(G.CardRect(3)), 'Karte 4 umgebrochen');
  // 30 Saetze = 10 Kartenzeilen: 10 + 10 * 122
  CheckEquals(10 + 10 * ExpRowH, G.ContentHeight, 'Inhaltshoehe');
  CheckEquals(0, G.ContentWidth, 'nie waagerecht scrollen');
  // Puffer: Kartenzeilen um die aktive (2 * 5 + 2 Zeilen zu 3 Karten)
  CheckEquals(36, TGridAccess(G).DataLink.BufferCount, 'Puffer');
  CheckEquals(30, TGridAccess(G).DataLink.RecordCount, 'alle Saetze geladen');
  // Ausgeblendete Spalte fehlt in der Karte
  G.Columns[2].Visible := False;
  CheckEquals(3, G.CardMetrics.Fields, 'ausgeblendet');
  CheckEquals(2 * ExpPad + 3 * ExpLine, G.CardMetrics.CardH, 'Hoehe folgt');
  CheckTrue(IsRectEmpty(G.CardRect(30)), 'keine Karte hinter dem Puffer');
end;

procedure TDBGridCardsTests.LabelWidthAndNarrowView;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(5);
  // Wert rechts der Beschriftung: Karte 10 + 8, Beschriftung 110
  CheckEquals(RectText(Rect(128, 18, 202, 42)), RectText(ValueRect(G, 0, 0)), 'Wert');
  CheckEquals(RectText(Rect(128, 42, 202, 66)), RectText(ValueRect(G, 0, 1)), 'zweite Zeile');
  G.CardLabelWidth := 0;
  CheckEquals(RectText(Rect(18, 18, 202, 42)), RectText(ValueRect(G, 0, 0)), 'ohne Beschriftung');
  // Beschriftung laesst dem Wert mindestens 24 px
  G.CardLabelWidth := 500;
  CheckEquals(200 - 2 * ExpPad - 24, G.CardMetrics.LabelW, 'Beschriftung begrenzt');
  // Schmale Ansicht: eine schmalere Karte je Zeile
  G.Width := 150;
  CheckEquals(1, G.CardsPerRow);
  CheckEquals(130, G.CardMetrics.CardW, '150 - 2 * 10');
  CheckEquals(RectText(Rect(10, 132, 140, 244)), RectText(G.CardRect(1)), 'untereinander');
end;

procedure TDBGridCardsTests.HitTestFindsCardAndField;
var
  G: TPPGDBGrid;
  C, V: Integer;
begin
  G := NewGrid(5);
  // Karte 5 (Zeile 1, Spalte 1): links 220, oben 132; dritte Feldzeile
  CheckTrue(G.MouseCoord(300, 132 + 8 + 2 * 24 + 12, C, V), 'Treffer');
  CheckEquals(TGridAccess(G).FixedCols + 2, C, 'Feld Aktiv');
  CheckEquals(G.VisualRow(TGridAccess(G).FixedRows + 4), V, 'Satz 5');
  // Innenabstand oben zaehlt zur ersten Feldzeile, unten zur letzten
  CheckTrue(G.MouseCoord(300, 134, C, V));
  CheckEquals(TGridAccess(G).FixedCols, C, 'oben: erstes Feld');
  CheckTrue(G.MouseCoord(300, 132 + 110, C, V));
  CheckEquals(TGridAccess(G).FixedCols + 3, C, 'unten: letztes Feld');
  // Beschriftung gehoert zur Feldzeile
  CheckTrue(G.MouseCoord(230, 132 + 8 + 30, C, V));
  CheckEquals(TGridAccess(G).FixedCols + 1, C, 'Beschriftung');
  CheckFalse(G.MouseCoord(215, 50, C, V), 'Abstand zwischen Karten');
  CheckFalse(G.MouseCoord(300, 126, C, V), 'Abstand zwischen Zeilen');
  CheckFalse(G.MouseCoord(500, 200, C, V), 'Platz ohne Satz (nur 5 Saetze)');
  CheckFalse(G.MouseCoord(300, 390, C, V), 'unter den Karten');
end;

procedure TDBGridCardsTests.KeyboardMovesBetweenCards;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(29);
  CheckEquals(1, Id);
  Key(G, VK_RIGHT);
  CheckEquals(2, Id, 'rechts');
  Key(G, VK_DOWN);
  CheckEquals(5, Id, 'runter = eine Kartenzeile');
  Key(G, VK_LEFT);
  CheckEquals(4, Id, 'links');
  Key(G, VK_UP);
  CheckEquals(1, Id, 'hoch');
  Key(G, VK_UP);
  CheckEquals(1, Id, 'oben bleibt');
  Key(G, VK_LEFT);
  CheckEquals(1, Id, 'Anfang bleibt');
  Key(G, VK_NEXT);
  CheckEquals(10, Id, 'Bild ab: 3 Zeilen zu 3 Karten');
  Key(G, VK_PRIOR);
  CheckEquals(1, Id, 'Bild auf');
  Key(G, VK_END);
  CheckEquals(29, Id, 'Ende');
  Key(G, VK_DOWN);
  CheckEquals(29, Id, 'letzte Zeile bleibt');
  Key(G, VK_HOME);
  CheckEquals(1, Id, 'Pos1');
  // Letzte Zeile ist kuerzer (28, 29): von 27 runter auf die letzte Karte
  FData.RecNo := 27;
  Key(G, VK_DOWN);
  CheckEquals(29, Id, 'kuerzere Zeile: letzte Karte');
  FData.RecNo := 26;
  Key(G, VK_DOWN);
  CheckEquals(29, Id, 'direkt darunter');
  // RTL: links und rechts gespiegelt
  G.BiDiMode := bdRightToLeft;
  FData.RecNo := 5;
  Key(G, VK_LEFT);
  CheckEquals(6, Id, 'RTL links = naechste');
  // Satz 6 = dritte Karte der Zeile: bei RTL ganz links
  CheckEquals(10, G.CardRect(ActiveRow(G)).Left, 'RTL: links');
  CheckEquals(210, G.CardRect(ActiveRow(G)).Right, 'RTL: rechts');
  G.BiDiMode := bdLeftToRight;
  // Tab wechselt das Feld, nicht den Satz
  CheckEquals(TGridAccess(G).FixedCols, G.FocusCol, 'erstes Feld');
  Key(G, VK_TAB);
  CheckEquals(6, Id, 'Tab: gleicher Satz');
  CheckEquals(TGridAccess(G).FixedCols + 1, G.FocusCol, 'Tab: naechstes Feld');
  CheckEquals('Name', G.SelectedField.FieldName);
end;

procedure TDBGridCardsTests.ClickSelectsRecordAndField;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(10);
  ClickCard(G, 4, 1);
  CheckEquals(5, Id, 'Karte 5');
  CheckEquals('Name', G.SelectedField.FieldName, 'angeklicktes Feld');
  CheckEquals(G.VisualRow(TGridAccess(G).FixedRows + ActiveRow(G)), G.FocusRow, 'Fokuszeile');
  ClickCard(G, 7, 3);
  CheckEquals(8, Id);
  CheckEquals('Preis', G.SelectedField.FieldName);
  CheckTrue(FData.State = dsBrowse, 'Klick bearbeitet nicht');
end;

procedure TDBGridCardsTests.BufferStaysAlignedWhileNavigating;
var
  G: TPPGDBGrid;
  I: Integer;
begin
  G := NewGrid(200);
  CheckEquals(36, TGridAccess(G).DataLink.BufferCount, 'Puffer kleiner als die Datenmenge');
  CheckLayoutConsistent(G, 'Start');
  for I := 1 to 40 do
  begin
    Key(G, VK_DOWN);
    CheckLayoutConsistent(G, 'runter ' + IntToStr(I));
  end;
  CheckEquals(121, Id, '40 Zeilen tiefer');
  for I := 1 to 50 do
  begin
    Key(G, VK_RIGHT);
    CheckLayoutConsistent(G, 'rechts ' + IntToStr(I));
  end;
  CheckEquals(171, Id);
  for I := 1 to 45 do
  begin
    Key(G, VK_UP);
    CheckLayoutConsistent(G, 'hoch ' + IntToStr(I));
  end;
  CheckEquals(36, Id);
  Key(G, VK_END);
  CheckLayoutConsistent(G, 'Ende');
  CheckEquals(200, Id);
  Key(G, VK_PRIOR);
  CheckLayoutConsistent(G, 'Bild auf');
  // Von aussen bewegt (Navigator, Code)
  FData.RecNo := 77;
  CheckLayoutConsistent(G, 'RecNo 77');
  FData.Prior;
  CheckLayoutConsistent(G, 'Prior');
  FData.First;
  CheckLayoutConsistent(G, 'First');
  CheckEquals(0, G.ScrollY, 'oben');
end;

procedure TDBGridCardsTests.ScrollingMovesRecordIntoView;
var
  G: TPPGDBGrid;
  M: TPPGDBGridCardMetrics;
  R, Tmp: TRect;
begin
  G := NewGrid(200);
  M := G.CardMetrics;
  Key(G, VK_RIGHT);
  CheckEquals(2, Id);
  // Weit nach unten: der Satz folgt in die Ansicht, Spalte bleibt, Lage bleibt
  G.ScrollTo(0, 2000);
  CheckEquals(2000, G.ScrollY, 'Lage bleibt');
  R := G.CardRect(ActiveRow(G));
  CheckTrue(IntersectRect(Tmp, R, M.View), 'aktive Karte im Bild ' + RectText(R));
  CheckEquals(1, (FData.RecNo - 1) mod M.PerRow, 'gleiche Spalte');
  CheckTrue(FData.RecNo > 30, 'Satz gewechselt');
  CheckLayoutConsistent(G, 'nach Scrollen');
  // Kleiner Schritt, Karte bleibt sichtbar: kein Satzwechsel
  G.ScrollTo(0, 2010);
  CheckEquals(2010, G.ScrollY);
  CheckTrue(IntersectRect(Tmp, G.CardRect(ActiveRow(G)), M.View), 'noch im Bild');
  // Zurueck nach oben
  G.ScrollTo(0, 0);
  CheckTrue(FData.RecNo <= 3 * 3, 'oben ' + IntToStr(FData.RecNo));
  CheckLayoutConsistent(G, 'oben');
end;

procedure TDBGridCardsTests.ResizeReflowsCards;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(200);
  FData.RecNo := 50;
  CheckLayoutConsistent(G, '3 je Zeile');
  G.Width := 860;
  CheckEquals(4, G.CardsPerRow, '(860 - 10) div 210');
  CheckEquals(4 * (2 * 5 + 2), TGridAccess(G).DataLink.BufferCount, 'Puffer folgt');
  CheckEquals(50, FData.RecNo, 'Satz bleibt');
  CheckLayoutConsistent(G, '4 je Zeile');
  G.Height := 250;
  CheckLayoutConsistent(G, 'niedriger');
end;

procedure TDBGridCardsTests.MultiSelectCtrlShiftAndKeys;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(30);
  G.Options := G.Options + [dgMultiSelect];
  ClickCard(G, 0);
  CheckEquals('1', SelectedIds(G), 'Klick waehlt');
  ClickCard(G, 2, 0, MK_CONTROL);
  CheckEquals('1,3', SelectedIds(G), 'Strg+Klick');
  ClickCard(G, 5, 0, MK_SHIFT);
  CheckEquals('3,4,5,6', SelectedIds(G), 'Umschalt+Klick vom Anker');
  Key(G, VK_RIGHT, [ssShift]);
  CheckEquals('3,4,5,6,7', SelectedIds(G), 'Umschalt+rechts');
  Key(G, VK_LEFT, [ssShift]);
  CheckEquals('3,4,5,6', SelectedIds(G), 'Umschalt+links verkleinert');
  Key(G, VK_DOWN, [ssShift]);
  CheckEquals(9, Id);
  CheckEquals('3,4,5,6,7,8,9', SelectedIds(G), 'Umschalt+runter: Bereich vom Anker');
  Key(G, VK_RIGHT, [ssCtrl]);
  CheckEquals(10, Id, 'Strg+Pfeil bewegt');
  CheckEquals('3,4,5,6,7,8,9', SelectedIds(G), 'Strg+Pfeil laesst die Auswahl');
  Key(G, VK_SPACE, [ssCtrl]);
  CheckEquals('3,4,5,6,7,8,9,10', SelectedIds(G), 'Strg+Leertaste');
  Key(G, VK_RIGHT);
  CheckEquals('', SelectedIds(G), 'Pfeil ohne Taste hebt auf');
  Key(G, Ord('A'), [ssCtrl]);
  CheckEquals(30, G.SelectedRows.Count, 'Strg+A');
  ClickCard(G, 9);
  CheckEquals('10', SelectedIds(G), 'Klick setzt zurueck');
end;

procedure TDBGridCardsTests.SwitchTableAndCards;
var
  G: TPPGDBGrid;
  R: TRect;
  Tmp: TRect;
begin
  G := NewGrid(200);
  G.ViewStyle := dgvTable;
  CheckEquals(0, G.CardsPerRow);
  CheckEquals((400 - 24) div 24, TGridAccess(G).DataLink.BufferCount, 'Tabelle: sichtbare Zeilen');
  FData.RecNo := 120;
  R := G.CellRect(TGridAccess(G).FixedCols, G.FocusRow);
  CheckEquals(24, R.Bottom - R.Top, 'Tabellenzelle');
  G.ViewStyle := dgvCards;
  CheckEquals(120, FData.RecNo, 'Satz bleibt');
  CheckEquals(36, TGridAccess(G).DataLink.BufferCount, 'Karten: Puffer');
  CheckTrue(IntersectRect(Tmp, G.CardRect(ActiveRow(G)), G.CardMetrics.View), 'Karte im Bild');
  CheckLayoutConsistent(G, 'Karten');
  CheckEquals(G.VisualRow(TGridAccess(G).FixedRows + ActiveRow(G)), G.FocusRow, 'Fokus = Satz');
  Key(G, VK_DOWN);
  CheckEquals(123, FData.RecNo, 'Karten: runter');
  G.ViewStyle := dgvTable;
  CheckEquals(123, FData.RecNo, 'Satz bleibt');
  CheckEquals((400 - 24) div 24, TGridAccess(G).DataLink.BufferCount, 'Tabelle wieder');
  Key(G, VK_DOWN);
  CheckEquals(124, FData.RecNo, 'Tabelle: runter = naechster Satz');
  R := G.CellRect(TGridAccess(G).FixedCols, G.FocusRow);
  CheckEquals(24, R.Bottom - R.Top, 'wieder Tabellenzelle');
end;

procedure TDBGridCardsTests.PaintLightDarkAndGdi;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
  Card: TRect;
  Gap, Inner: TColor;

  function Lum(C: TColor): Integer;
  begin
    C := ColorToRGB(C);
    Result := GetRValue(C) + GetGValue(C) + GetBValue(C);
  end;

begin
  G := NewGrid(10);
  FData.RecNo := 2;
  Card := G.CardRect(3);
  Bmp := RenderToBitmap(G);
  try
    Gap := Bmp.Canvas.Pixels[5, 5];
    Inner := Bmp.Canvas.Pixels[Card.Left + 4, Card.Bottom - 4];
    CheckNotEquals(Integer(Gap), Integer(Inner), 'Karte hebt sich ab');
    CheckTrue(Lum(Inner) > 3 * 128, 'hell: Karte hell');
  finally
    Bmp.Free;
  end;
  CheckEquals(2, FData.RecNo, 'Zeichnen bewegt die Datenmenge nicht');
  TPPGTheme.Mode := tmDark;
  Bmp := RenderToBitmap(G);
  try
    Inner := Bmp.Canvas.Pixels[Card.Left + 4, Card.Bottom - 4];
    CheckTrue(Lum(Inner) < 3 * 128, 'dunkel: Karte dunkel');
  finally
    Bmp.Free;
  end;
  TPPGTheme.Mode := tmLight;
  TPPGRendererRegistry.ForceGdiFallback := True;
  Bmp := RenderToBitmap(G);
  try
    Inner := Bmp.Canvas.Pixels[Card.Left + 4, Card.Bottom - 4];
    CheckTrue(Lum(Inner) > 3 * 128, 'GDI: Karte hell');
  finally
    Bmp.Free;
  end;
  // Leere Datenmenge und geschlossene Datenmenge zeichnen ohne Fehler
  FData.EmptyDataSet;
  Bmp := RenderToBitmap(G);
  Bmp.Free;
  FData.Close;
  Bmp := RenderToBitmap(G);
  Bmp.Free;
  CheckEquals(0, FErrors.Count, 'keine Fehler beim Zeichnen');
end;

procedure TDBGridCardsTests.DrawColumnCellPerField;
var
  G: TPPGDBGrid;
  Bmp: TBitmap;
begin
  G := NewGrid(5);
  FData.RecNo := 3;
  G.OnDrawColumnCell := RecordDraw;
  Bmp := RenderToBitmap(G);
  try
    CheckEquals(5 * 4, FDrawCalls, '5 Karten x 4 Felder');
    CheckEquals('1,2,3,4,5', FDrawIds.CommaText, 'Column.Field = gezeichneter Satz');
  finally
    Bmp.Free;
  end;
  CheckEquals(3, Id, 'Satzzeiger unveraendert');
  CheckTrue(FData.State = dsBrowse);
end;

procedure TDBGridCardsTests.CheckBoxToggleInCard;
var
  G: TPPGDBGrid;
begin
  G := NewGrid(5);
  // Satz 2: Aktiv = False (Odd(2)); Klick auf das Kaestchen in Karte 2
  CheckFalse(FData.Lookup('ID', 2, 'Aktiv'));
  ClickCard(G, 1, 2);
  CheckEquals(2, Id);
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean, 'umgeschaltet');
  FData.Post;
  // Leertaste auf dem Kaestchen-Feld schaltet zurueck
  Key(G, VK_SPACE);
  CheckFalse(FData.FieldByName('Aktiv').AsBoolean, 'Leertaste');
  FData.Cancel;
  // ReadOnly: kein Umschalten
  G.ReadOnly := True;
  ClickCard(G, 1, 2);
  CheckTrue(FData.FieldByName('Aktiv').AsBoolean, 'ReadOnly');
  CheckTrue(FData.State = dsBrowse);
end;

procedure TDBGridCardsTests.TallCardRevealsFocusedField;
var
  G: TPPGDBGrid;
  I: Integer;
  R: TRect;
  M: TPPGDBGridCardMetrics;
begin
  // 33 Felder: Karte (16 + 33 * 24 = 808) hoeher als die Ansicht (400)
  FData.Close;
  FData.FieldDefs.Clear;
  for I := 1 to 33 do
    FData.FieldDefs.Add('F' + IntToStr(I), ftInteger);
  FData.CreateDataSet;
  for I := 1 to 12 do
    FData.AppendRecord([I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I, I,
      I, I, I, I, I, I, I, I, I, I]);
  FData.First;
  G := TPPGDBGrid.Create(FForm);
  G.Parent := FForm;
  ForcePPI96(G);
  G.BorderStyle := bsNone;
  G.ScrollBarMode := sbmNever;
  G.SetBounds(0, 0, 640, 400);
  G.HandleNeeded;
  G.ViewStyle := dgvCards;
  G.DataSource := FSource;
  M := G.CardMetrics;
  CheckEquals(33, M.Fields);
  CheckEquals(16 + 33 * 24, M.CardH);
  for I := 1 to 30 do
    Key(G, VK_TAB);
  CheckEquals('F31', G.SelectedField.FieldName);
  R := G.CellRect(G.FocusCol, G.FocusRow);
  CheckFalse(IsRectEmpty(R), 'Fokusfeld sichtbar');
  CheckTrue((R.Top >= 0) and (R.Bottom <= 400), 'ganz im Bild ' + RectText(R));
  CheckTrue(G.ScrollY > 0, 'gescrollt');
  CheckEquals(1, FData.RecNo, 'Satz bleibt');
  // Naechste Karte: Fokusfeld bleibt, die Karte kommt ins Bild
  Key(G, VK_RIGHT);
  CheckEquals(2, FData.RecNo);
  R := G.CellRect(G.FocusCol, G.FocusRow);
  CheckTrue((R.Top >= 0) and (R.Bottom <= 400), 'Feld der neuen Karte im Bild');
end;

procedure TDBGridCardsTests.EditorOpensOnF2AndDoubleClick;
var
  G: TPPGDBGrid;
  P: TPoint;
  LP: LPARAM;
  R: TRect;
begin
  G := NewGrid(10);
  // Der Editor braucht ein angezeigtes Formular: nur auf dem unsichtbaren
  // Testdesktop (/hidden), nie auf dem Bildschirm
  if not PPGOnHiddenDesktop then
  begin
    Skip('Editor braucht ein angezeigtes Formular, nur mit /hidden');
    Exit;
  end;
  FForm.Show;
  try
    G.SetFocus;
    ClickCard(G, 4, 1);
    CheckEquals(5, Id);
    Key(G, VK_F2);
    CheckTrue(G.EditorMode, 'F2 oeffnet den Editor');
    R := ValueRect(G, ActiveRow(G), 1);
    CheckEquals(RectText(R), RectText(G.InplaceEditor.BoundsRect), 'Editor ueber dem Wert');
    TPPGGridEdit(G.InplaceEditor).Text := 'Neu';
    G.HideEditor(True);
    CheckEquals('Neu', FData.FieldByName('Name').AsString, 'geschrieben');
    CheckEquals(5, Id, 'gleicher Satz');
    // Pfeil im Editor wechselt das Feld, nicht den Satz
    TGridAccess(G).EditorArrowMove(True);
    CheckEquals('Aktiv', G.SelectedField.FieldName, 'Pfeil runter: naechstes Feld');
    CheckEquals(5, Id);
    FData.Post;
    // Doppelklick auf ein Feld einer anderen Karte bearbeitet dieses Feld
    P := Center(ValueRect(G, 7, 3));
    LP := MakeLParam(Word(SmallInt(P.X)), Word(SmallInt(P.Y)));
    G.Perform(WM_LBUTTONDOWN, MK_LBUTTON, LP);
    G.Perform(WM_LBUTTONUP, 0, LP);
    G.Perform(WM_LBUTTONDBLCLK, MK_LBUTTON, LP);
    G.Perform(WM_LBUTTONUP, 0, LP);
    CheckEquals(8, Id, 'Karte 8');
    CheckTrue(G.EditorMode, 'Doppelklick oeffnet den Editor');
    CheckEquals('Preis', G.SelectedField.FieldName);
    CheckEquals(RectText(ValueRect(G, ActiveRow(G), 3)), RectText(G.InplaceEditor.BoundsRect));
    G.HideEditor(False);
    CheckFalse(G.EditorMode);
  finally
    FForm.Hide;
  end;
end;

procedure TDBGridCardsTests.UiaFollowsCards;
var
  G: TPPGDBGrid;
  R: TRect;
  P: TPoint;
  UId: TPPGUiaId;
begin
  G := NewGrid(10);
  R := ValueRect(G, 4, 1);
  P := Center(R);
  UId := TGridAccess(G).UiaElementAt(P.X, P.Y);
  CheckEquals(PPGUiaKindGridCell, UId.Kind, 'Zelle');
  CheckEquals(TGridAccess(G).FixedRows + 4, UId.A, 'Datenzeile = Satz 5');
  CheckEquals(G.DataCol(TGridAccess(G).FixedCols + 1), UId.B, 'Spalte Name');
  CheckEquals(RectText(R), RectText(TGridAccess(G).UiaRect(UId)), 'Rechteck = Wert');
  CheckEquals('Name5', TGridAccess(G).UiaValue(UId), 'Wert');
  // Zeile = ganze Karte
  UId := PPGUiaId(PPGUiaKindGridRow, TGridAccess(G).FixedRows + 4, 0);
  CheckEquals(RectText(G.CardRect(4)), RectText(TGridAccess(G).UiaRect(UId)), 'Zeile = Karte');
end;

procedure TDBGridCardsTests.DpiScalesCards;
{$IF CompilerVersion >= 33.0}
var
  G: TPPGDBGrid;
  M: TPPGDBGridCardMetrics;
  Host: TPanel;
{$IFEND}
begin
{$IF CompilerVersion >= 33.0}
  // Wie beim Wechsel auf einen Monitor mit 200 %: der Container skaliert.
  // Ohne Scaled liefert CurrentPPI die gesetzte PPI statt der des Fensters.
  FForm.Scaled := False;
  Host := TPanel.Create(FForm);
  Host.Parent := FForm;
  ForcePPI96(Host);
  Host.SetBounds(0, 0, 700, 450);
  G := NewGrid(10, True, Host);
  Host.ScaleForPPI(192);
  CheckEquals(192, G.CurrentPPI, 'PPI');
  M := G.CardMetrics;
  CheckEquals(2 * ExpGap, M.Gap, 'Abstand doppelt');
  CheckEquals(2 * ExpPad, M.Pad, 'Innenabstand doppelt');
  CheckEquals(2 * ExpLine, M.LineH, 'Feldzeile doppelt');
  CheckEquals(2 * ExpCardW, M.CardW, 'Breite doppelt');
  CheckEquals(2 * ExpCardH, M.CardH, 'Hoehe doppelt');
  CheckEquals(220, M.LabelW, 'Beschriftung doppelt');
  CheckEquals(3, M.PerRow, 'Ansicht waechst mit');
  CheckEquals(RectText(Rect(20, 20, 420, 244)), RectText(G.CardRect(0)), 'Karte 1');
  CheckEquals(200, G.CardWidth, 'Property bleibt logisch');
{$ELSE}
  Skip('Erst ab Delphi 10.3 (ScaleForPPI)');
{$IFEND}
end;

procedure TDBGridCardsTests.WithoutRecNoShowsLoadedCards;
var
  G: TPPGDBGrid;
  D: TNoSeqDataSet;
  I: Integer;
  R, Tmp: TRect;
begin
  // Ohne RecNo: die geladenen Karten fliessen ab dem Pufferanfang; Tastatur
  // und Code blaettern weiter, die aktive Karte bleibt im Bild
  D := TNoSeqDataSet.Create(FForm);
  D.FieldDefs.Add('ID', ftInteger);
  D.FieldDefs.Add('Name', ftString, 20);
  D.CreateDataSet;
  for I := 1 to 100 do
    D.AppendRecord([I, 'Name' + IntToStr(I)]);
  D.First;
  G := NewGrid(1, False);
  FSource.DataSet := D;
  CheckEquals(2, G.CardMetrics.Fields, 'automatische Spalten');
  for I := 1 to 30 do
  begin
    Key(G, VK_DOWN);
    R := G.CardRect(ActiveRow(G));
    CheckTrue(IntersectRect(Tmp, R, G.CardMetrics.View), 'aktive Karte im Bild ' + IntToStr(I));
  end;
  CheckEquals(1 + 30 * 3, D.FieldByName('ID').AsInteger, '30 Kartenzeilen');
  Key(G, VK_END);
  CheckEquals(100, D.FieldByName('ID').AsInteger, 'Ende');
  CheckTrue(IntersectRect(Tmp, G.CardRect(ActiveRow(G)), G.CardMetrics.View), 'Ende im Bild');
  G.ScrollTo(0, 0);
  CheckEquals(100, D.FieldByName('ID').AsInteger, 'Scrollen bewegt ohne RecNo nicht');
  Key(G, VK_HOME);
  CheckEquals(1, D.FieldByName('ID').AsInteger, 'Pos1');
end;

initialization
  RegisterTest('DBGridCards', TDBGridCardsTests.Suite);
end.
