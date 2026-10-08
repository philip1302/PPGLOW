unit PPG.Grid.Print;

{ Drucken von Tabellen (Phase 13e, Optik wie im Grid seit Phase 17).

  - TPPGGridPrinter (Komponente fuer den Formular-Designer) druckt eine
    IPPGTableSource: das Grid, das DB-Grid oder eine eigene Quelle. Er kennt
    das Control nicht (DIP); Darstellung (bedingte Formate, Zellarten) kommt
    ueber das schmale IPPGGridPrintSource.
  - UseGridLook (Vorgabe): mit IPPGTableLook wie am Bildschirm in heller
    Darstellung - Schrift, Kopf- und Bandzeilen, Spalten- und Zebra-Stile,
    bedingte Formate, Gruppenzeilen (TPPGTableLines), verbundene Zellen und
    die Summenzeile am Ende der letzten Seite. Ein Gruppenkopf bleibt nie
    allein am Seitenende stehen. Ohne IPPGTableLook bzw. mit False: grauer,
    fetter Kopf und nur Datenzeilen wie bisher.
  - Seite (Ausrichtung, Raender, Kopf-/Fusszeile), Drucken, PDF, Vorschau
    und "Seite einrichten" kommen aus TPPGCustomPrinter (PPG.Print, seit
    Phase 14a gemeinsam mit dem Planer). Hier: Spaltenkoepfe auf jeder Seite,
    auf Seitenbreite einpassen oder Spalten auf mehrere Seiten verteilen,
    Gitterlinien und Farben abschaltbar.
  - Gezeichnet wird mit dem GDI-Canvas in der Aufloesung des Druckers (GDI+
    rastert Alpha-Flaechen auf Drucker-DCs zu grossen Bitmaps). Alle Masse
    sind logisch (96 dpi) und werden mit der Drucker-PPI umgerechnet; die
    Schrift wird ueber Font.Height mit der Drucker-PPI neu gesetzt.
  - Zeilen holt der Drucker seitenweise aus der Quelle (virtuelle Daten).
  - Die frueher hier deklarierten Typen (TPPGPrintDevice, TPPGPrintMargins,
    Vorschau- und Seiten-Formular) gibt es weiter unter demselben Namen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, Vcl.Graphics, Vcl.Printers,
  System.Generics.Collections, PPG.Types, PPG.Render.Intf, PPG.Grid.Data, PPG.Grid.Styles,
  PPG.Grid.CellKinds, PPG.Grid.Paint, PPG.Grid.Look, PPG.Grid, PPG.Print;

type
  // Seit Phase 14a in PPG.Print (Namen bleiben fuer bestehenden Code)
  TPPGPrintDevice = PPG.Print.TPPGPrintDevice;
  TPPGPrintMargins = PPG.Print.TPPGPrintMargins;
  TPPGPrintPreviewView = PPG.Print.TPPGPrintPreviewView;
  TPPGPrintPreviewForm = PPG.Print.TPPGPrintPreviewForm;
  TPPGPageSetupForm = PPG.Print.TPPGPageSetupForm;

  /// Seite: RowFirst/RowCount zaehlen Druckzeilen (ohne Gliederung =
  /// Tabellenzeilen; mit Gliederung auch Gruppenkoepfe, am Ende die Summe).
  TPPGPrintPage = record
    RowFirst, RowCount: Integer;
    ColFirst, ColCount: Integer;
    WithHeader: Boolean;
  end;

  TPPGGridPrinter = class(TPPGCustomPrinter)
  private
    FGrid: TPPGCustomGrid;
    FSource: IPPGTableSource;
    // Komponente hinter FSource (z. B. ein Grid oder DB-Grid), per
    // FreeNotification gehalten
    FSourceComp: TComponent;
    FRepeatHeader: Boolean;
    FFitToPageWidth: Boolean;
    FPrintGridLines: Boolean;
    FPrintColors: Boolean;
    FUseGridLook: Boolean;
    // Layout fuer ein Geraet
    FLayoutDevice: TPPGPrintDevice;
    FLayoutValid: Boolean;
    FPages: array of TPPGPrintPage;
    FColW: array of Integer;
    FRowH, FPageHeadH, FPageFootH: Integer;
    FContent: TRect;
    FScale: Double;
    FFont, FBoldFont: TFont;
    FPainter: TPPGCellPainter;
    // Optik (im Layout bestimmt)
    FLookSrc: IPPGTableLook;
    FLook: TPPGTableLook;
    FColLook: array of TPPGTableColumnLook;
    FBands: TArray<TPPGTableBand>;
    FBandLevels: Integer;
    FMerges: TArray<TRect>;
    FLines: TPPGTableLines;
    FFonts: TObjectDictionary<string, TFont>;
    procedure SetGrid(const Value: TPPGCustomGrid);
    function PrintSource: IPPGGridPrintSource;
    procedure PrepareLook(const Src: IPPGTableSource);
    function FontFor(Style: TFontStyles; const Name: string; Size: Integer): TFont;
    function HeadRowCount: Integer;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Eigene Quelle statt Grid (z.B. TPPGStringTableSource); nil = Grid.
    procedure SetSource(const Value: IPPGTableSource);
    function Source: IPPGTableSource;
    procedure Invalidate; override;
    procedure Layout(const Device: TPPGPrintDevice);
    function PageCount(const Device: TPPGPrintDevice): Integer; override;
    function Page(Index: Integer): TPPGPrintPage;
    procedure RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice); override;
    function OptionCount: Integer; override;
    function OptionCaption(Index: Integer): string; override;
    function GetOption(Index: Integer): Boolean; override;
    procedure SetOption(Index: Integer; Value: Boolean); override;
    /// Spaltenbreiten des Layouts (Geraetepunkte).
    function LayoutColWidth(ACol: Integer): Integer;
    /// Art einer Druckzeile des Layouts (Daten, Gruppenkopf, Summe).
    function LayoutLineKind(Index: Integer): TPPGTableLineKind;
    /// Kopfzeilen je Seite (Baender + Spaltenkoepfe).
    property LayoutHeadRows: Integer read HeadRowCount;
    property LayoutRowHeight: Integer read FRowH;
    property ContentRect: TRect read FContent;
  published
    property Grid: TPPGCustomGrid read FGrid write SetGrid;
    property Title;
    property HeaderText;
    property FooterText;
    property Orientation;
    property Margins;
    property RepeatHeader: Boolean read FRepeatHeader write FRepeatHeader default True;
    property FitToPageWidth: Boolean read FFitToPageWidth write FFitToPageWidth default True;
    property PrintGridLines: Boolean read FPrintGridLines write FPrintGridLines default True;
    property PrintColors: Boolean read FPrintColors write FPrintColors default True;
    /// Optik des Grids (Farben, Baender, Gruppen, Summen); False = grauer Kopf
    /// und nur Datenzeilen wie vor Phase 17.
    property UseGridLook: Boolean read FUseGridLook write FUseGridLook default True;
    property PrinterName;
  end;

implementation

uses
  System.Math, System.UITypes, PPG.Lang, PPG.Consts, PPG.Exceptions,
  PPG.Render.Gdi, PPG.Render.Registry;

const
  // Ohne Optik der Quelle (wie vor Phase 17)
  PlainHeadFill = $00F0F0F0;
  PlainLineColor = $00A0A0A0;

{ TPPGGridPrinter }

constructor TPPGGridPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRepeatHeader := True;
  FFitToPageWidth := True;
  FPrintGridLines := True;
  FPrintColors := True;
  FUseGridLook := True;
  FScale := 1;
  FFont := TFont.Create;
  FBoldFont := TFont.Create;
  FPainter := TPPGCellPainter.Create;
  FFonts := TObjectDictionary<string, TFont>.Create([doOwnsValues]);
end;

destructor TPPGGridPrinter.Destroy;
begin
  FreeAndNil(FLines);
  FreeAndNil(FFonts);
  FreeAndNil(FPainter);
  FreeAndNil(FBoldFont);
  FreeAndNil(FFont);
  inherited Destroy;
end;

function TPPGGridPrinter.OptionCount: Integer;
begin
  Result := 5;
end;

function TPPGGridPrinter.OptionCaption(Index: Integer): string;
begin
  case Index of
    0: Result := PPGStr(@SPPGPageSetupFit);
    1: Result := PPGStr(@SPPGPageSetupRepeat);
    2: Result := PPGStr(@SPPGPageSetupGridLines);
    3: Result := PPGStr(@SPPGPageSetupColors);
  else
    Result := PPGStr(@SPPGPageSetupGridLook);
  end;
end;

function TPPGGridPrinter.GetOption(Index: Integer): Boolean;
begin
  case Index of
    0: Result := FFitToPageWidth;
    1: Result := FRepeatHeader;
    2: Result := FPrintGridLines;
    3: Result := FPrintColors;
  else
    Result := FUseGridLook;
  end;
end;

procedure TPPGGridPrinter.SetOption(Index: Integer; Value: Boolean);
begin
  case Index of
    0: FFitToPageWidth := Value;
    1: FRepeatHeader := Value;
    2: FPrintGridLines := Value;
    3: FPrintColors := Value;
  else
    FUseGridLook := Value;
  end;
  Invalidate;
end;

procedure TPPGGridPrinter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FGrid) then
  begin
    FGrid := nil;
    FLookSrc := nil;
    Invalidate;
  end;
  if (Operation = opRemove) and (AComponent <> nil) and (AComponent = FSourceComp) then
  begin
    FSourceComp := nil;
    FSource := nil;
    FLookSrc := nil;
    Invalidate;
  end;
end;

procedure TPPGGridPrinter.SetGrid(const Value: TPPGCustomGrid);
begin
  if FGrid <> Value then
  begin
    // Dieselbe Komponente kann zugleich Source sein
    if (FGrid <> nil) and (FGrid <> FSourceComp) then
      FGrid.RemoveFreeNotification(Self);
    FGrid := Value;
    if FGrid <> nil then
      FGrid.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TPPGGridPrinter.SetSource(const Value: IPPGTableSource);
var
  Ref: IInterfaceComponentReference;
  Comp: TComponent;
begin
  // Ist die Quelle eine Komponente (Grid, DB-Grid), haelt eine rohe
  // Interface-Referenz sie ueber ihre Freigabe hinaus: beim naechsten
  // Druck bzw. beim _Release traefe es freigegebenen Speicher.
  Comp := nil;
  if (Value <> nil) and Supports(Value, IInterfaceComponentReference, Ref) then
    Comp := Ref.GetComponent;
  Ref := nil;
  if (FSourceComp <> nil) and (FSourceComp <> Comp) and (FSourceComp <> FGrid) then
    FSourceComp.RemoveFreeNotification(Self);
  FSourceComp := Comp;
  if FSourceComp <> nil then
    FSourceComp.FreeNotification(Self);
  FSource := Value;
  Invalidate;
end;

function TPPGGridPrinter.Source: IPPGTableSource;
begin
  Result := FSource;
  if (Result = nil) and (FGrid <> nil) then
    Supports(FGrid, IPPGTableSource, Result);
end;

function TPPGGridPrinter.PrintSource: IPPGGridPrintSource;
begin
  if not Supports(Source, IPPGGridPrintSource, Result) then
    Result := nil;
end;

procedure TPPGGridPrinter.Invalidate;
begin
  FLayoutValid := False;
end;

function TPPGGridPrinter.HeadRowCount: Integer;
begin
  Result := FBandLevels + 1;
end;

function TPPGGridPrinter.LayoutLineKind(Index: Integer): TPPGTableLineKind;
begin
  if (FLines = nil) or (Index < 0) or (Index >= FLines.Count) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, 0]);
  Result := FLines.Kind(Index);
end;

procedure TPPGGridPrinter.PrepareLook(const Src: IPPGTableSource);
var
  C, N: Integer;
  Ex: IPPGTableExport;
begin
  FLookSrc := nil;
  SetLength(FBands, 0);
  SetLength(FMerges, 0);
  FBandLevels := 0;
  N := 0;
  if Src <> nil then
    N := Src.TableColCount;
  SetLength(FColLook, N);
  if FUseGridLook and (Src <> nil) and Supports(Src, IPPGTableLook, FLookSrc) then
  begin
    FLook := FLookSrc.ExportLook;
    // Weiss ist das Papier: keine Flaeche
    if (FLook.Fill <> clNone) and (ColorToRGB(FLook.Fill) = $FFFFFF) then
      FLook.Fill := clNone;
    for C := 0 to N - 1 do
      FColLook[C] := FLookSrc.ExportColumnLook(C);
    FBands := FLookSrc.ExportBands;
    FBandLevels := PPGTableBandLevels(FBands);
  end
  else
  begin
    // Wie vor Phase 17: grauer, fetter Kopf, schwarzer Text, graue Linien
    FLook.Reset;
    FLook.HeaderFill := PlainHeadFill;
    FLook.HeaderText := clBlack;
    FLook.HeaderFontStyle := [fsBold];
    FLook.HeaderLine := PlainLineColor;
    FLook.Line := PlainLineColor;
    FLook.Text := clBlack;
    FLook.FontName := FFont.Name;
    FLook.FontSize := FFont.Size;
    for C := 0 to N - 1 do
    begin
      FColLook[C].Reset;
      FColLook[C].HeaderAlignment := Src.TableColumn(C).Alignment;
    end;
  end;
  FreeAndNil(FLines);
  FLines := TPPGTableLines.Create(Src, FLookSrc <> nil,
    (FLookSrc <> nil) and PPGTableHasFooter(FLookSrc, N));
  // Verbundene Zellen nur ohne Gliederung (dann ist Druckzeile = Tabellenzeile)
  if (FLookSrc <> nil) and not FLines.Grouped and Supports(Src, IPPGTableExport, Ex) then
    FMerges := Ex.ExportMerges;
end;

function TPPGGridPrinter.FontFor(Style: TFontStyles; const Name: string; Size: Integer): TFont;
var
  Key: string;
begin
  // Grundschrift (Drucker-PPI, eingepasst) mit anderem Stil/Namen/Groesse
  if (Name = '') or SameText(Name, FFont.Name) then
    Key := ''
  else
    Key := Name;
  if (Size <= 0) or (Size = FLook.FontSize) then
    Size := 0;
  Key := Key + '|' + IntToStr(Size) + '|' + IntToStr(Byte(Style));
  if FFonts.TryGetValue(Key, Result) then
    Exit;
  Result := TFont.Create;
  try
    Result.Assign(FFont);
    if (Name <> '') and not SameText(Name, FFont.Name) then
      Result.Name := Name;
    if Size > 0 then
    begin
      Result.Height := Round(-MulDiv(Size, FLayoutDevice.PPI, 72) * FScale);
      if Result.Height = 0 then
        Result.Height := -1;
    end;
    Result.Style := Style;
    FFonts.Add(Key, Result);
  except
    Result.Free;
    raise;
  end;
end;

procedure TPPGGridPrinter.Layout(const Device: TPPGPrintDevice);
var
  Src: IPPGTableSource;
  PS: IPPGGridPrintSource;
  I, N, PPI, Total, Avail, TH, Body, R, C0, W, RowsLeft, RowFirst, NP, Lines: Integer;
  DC: HDC;
  Old: HGDIOBJ;
  TM: TTextMetric;
  ColPages: array of TPoint; // (Erste, Anzahl)
  First: Boolean;
begin
  if FLayoutValid and FLayoutDevice.SameAs(Device) then
    Exit;
  FLayoutDevice := Device;
  FLayoutValid := True;
  FPages := nil;
  FFonts.Clear;
  Src := Source;
  PS := PrintSource;
  PPI := Device.PPI;
  FContent := MarginRect(Device);
  // Schrift in Drucker-PPI (Font.Height, nicht Font.Size mit Bildschirm-PPI)
  if PS <> nil then
    FFont.Assign(PS.PrintFont);
  FFont.Height := -MulDiv(FFont.Size, PPI, 72);
  PrepareLook(Src);
  // Spaltenbreiten
  N := 0;
  if Src <> nil then
    N := Src.TableColCount;
  SetLength(FColW, N);
  Total := 0;
  for I := 0 to N - 1 do
  begin
    FColW[I] := MulDiv(Src.TableColumn(I).Width, PPI, 96);
    Inc(Total, FColW[I]);
  end;
  Avail := FContent.Right - FContent.Left;
  FScale := 1;
  if FFitToPageWidth and (Total > Avail) and (Total > 0) then
  begin
    FScale := Avail / Total;
    for I := 0 to N - 1 do
      FColW[I] := Trunc(FColW[I] * FScale);
    FFont.Height := Round(FFont.Height * FScale);
    if FFont.Height = 0 then
      FFont.Height := -1;
  end;
  FBoldFont.Assign(FFont);
  FBoldFont.Style := FBoldFont.Style + [fsBold];
  // Zeilenhoehe aus Schrift und (logischer) Zeilenhoehe des Grids
  DC := CreateCompatibleDC(0);
  try
    Old := SelectObject(DC, FFont.Handle);
    GetTextMetrics(DC, TM);
    SelectObject(DC, Old);
  finally
    DeleteDC(DC);
  end;
  TH := TM.tmHeight;
  FRowH := Round(TH * 1.6);
  if PS <> nil then
    FRowH := Max(FRowH, Round(MulDiv(PS.PrintRowHeight, PPI, 96) * FScale));
  if FRowH < 1 then
    FRowH := 1;
  FPageHeadH := 0;
  if HeaderText <> '' then
    FPageHeadH := TH * 2;
  FPageFootH := 0;
  if FooterText <> '' then
    FPageFootH := TH * 2;
  // Spalten auf Seiten verteilen (eingepasst: eine Spaltenseite)
  SetLength(ColPages, 0);
  C0 := 0;
  while C0 < N do
  begin
    W := 0;
    I := C0;
    while (I < N) and ((I = C0) or (W + FColW[I] <= Avail)) do
    begin
      Inc(W, FColW[I]);
      Inc(I);
    end;
    SetLength(ColPages, Length(ColPages) + 1);
    ColPages[High(ColPages)] := Point(C0, I - C0);
    C0 := I;
  end;
  if Length(ColPages) = 0 then
  begin
    SetLength(ColPages, 1);
    ColPages[0] := Point(0, 0);
  end;
  // Druckzeilen auf Seiten verteilen
  Lines := FLines.Count;
  RowsLeft := Lines;
  RowFirst := 0;
  First := True;
  NP := 0;
  repeat
    Body := (FContent.Bottom - FContent.Top) - FPageHeadH - FPageFootH;
    if First or FRepeatHeader then
      Dec(Body, FRowH * HeadRowCount);
    R := Max(1, Body div FRowH);
    if R > RowsLeft then
      R := RowsLeft;
    // Gruppenkopf nicht allein am Seitenende (auch verschachtelte Koepfe)
    if R < RowsLeft then
      while (R > 1) and (FLines.Kind(RowFirst + R - 1) = tlGroup) do
        Dec(R);
    for I := 0 to High(ColPages) do
    begin
      SetLength(FPages, NP + 1);
      FPages[NP].RowFirst := RowFirst;
      FPages[NP].RowCount := R;
      FPages[NP].ColFirst := ColPages[I].X;
      FPages[NP].ColCount := ColPages[I].Y;
      FPages[NP].WithHeader := First or FRepeatHeader;
      Inc(NP);
    end;
    Inc(RowFirst, R);
    Dec(RowsLeft, R);
    First := False;
  until RowsLeft <= 0;
end;

function TPPGGridPrinter.PageCount(const Device: TPPGPrintDevice): Integer;
begin
  Layout(Device);
  Result := Length(FPages);
end;

function TPPGGridPrinter.Page(Index: Integer): TPPGPrintPage;
begin
  if (Index < 0) or (Index > High(FPages)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, High(FPages)]);
  Result := FPages[Index];
end;

function TPPGGridPrinter.LayoutColWidth(ACol: Integer): Integer;
begin
  Result := FColW[ACol];
end;

procedure TPPGGridPrinter.RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice);
type
  TFrame = record
    R: TRect;
    Color: TColor;
  end;
var
  Src: IPPGTableSource;
  PS: IPPGGridPrintSource;
  Pg: TPPGPrintPage;
  Canvas: IPPGCanvas;
  X, Y, C, Li, Row, Pad, LW, B, First, LastLine, NF, M: Integer;
  CR, TR: TRect;
  Info: TPPGTableColumnInfo;
  S: string;
  St: TPPGGridCellStyle;
  K: IPPGCellKind;
  Ctx: TPPGCellKindContext;
  Kinds: array of IPPGCellKind;
  KindCtx: array of TPPGCellKindContext;
  ColX: array of Integer;     // linke Kante je Seitenspalte
  Frames: array of TFrame;    // Zellen fuer die Gitterlinien
  HasLook, Covered: Boolean;
  TableTop: Integer;

  procedure Txt(const AText: string; ARect: TRect; AFont: TFont; AColor: TColor; AFlags: Cardinal);
  begin
    if AText = '' then
      Exit;
    SelectObject(DC, AFont.Handle);
    SetBkMode(DC, TRANSPARENT);
    if (AColor = clNone) or not FPrintColors then
      AColor := clBlack;
    SetTextColor(DC, ColorToRGB(AColor));
    Winapi.Windows.DrawText(DC, PChar(AText), Length(AText), ARect, AFlags);
  end;

  procedure Fill(const ARect: TRect; AColor: TColor);
  var
    Br: HBRUSH;
  begin
    if (AColor = clNone) or not FPrintColors then
      Exit;
    Br := CreateSolidBrush(ColorToRGB(AColor));
    try
      Winapi.Windows.FillRect(DC, ARect, Br);
    finally
      DeleteObject(Br);
    end;
  end;

  procedure AddFrame(const ARect: TRect; AColor: TColor);
  begin
    if NF >= Length(Frames) then
      SetLength(Frames, NF * 2 + 32);
    Frames[NF].R := ARect;
    Frames[NF].Color := AColor;
    Inc(NF);
  end;

  function AlignFlags(A: TAlignment): Cardinal;
  begin
    Result := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
    case A of
      taRightJustify: Result := Result or DT_RIGHT;
      taCenter: Result := Result or DT_CENTER;
    end;
  end;

  function PageRight: Integer;
  begin
    Result := ColX[Pg.ColCount];
  end;

  /// Verbundene Zelle an (ACol, ARow): Index in FMerges, -1 = keine.
  function MergeAt(ACol, ARow: Integer): Integer;
  var
    J: Integer;
  begin
    for J := 0 to High(FMerges) do
      if (ACol >= FMerges[J].Left) and (ACol <= FMerges[J].Right) and
        (ARow >= FMerges[J].Top) and (ARow <= FMerges[J].Bottom) then
        Exit(J);
    Result := -1;
  end;

  procedure HeaderRows;
  var
    J, C, L: Integer;
    HF: TFont;
  begin
    HF := FontFor(FLook.HeaderFontStyle, '', 0);
    // Baender: Laeufe gleicher Baender auf dieser Seite
    for L := 0 to FBandLevels - 1 do
    begin
      J := Pg.ColFirst;
      while J < Pg.ColFirst + Pg.ColCount do
      begin
        B := PPGTableBandAt(FBands, L, J);
        First := J;
        Inc(J);
        while (J < Pg.ColFirst + Pg.ColCount) and (PPGTableBandAt(FBands, L, J) = B) do
          Inc(J);
        CR := Rect(ColX[First - Pg.ColFirst], Y, ColX[J - Pg.ColFirst], Y + FRowH);
        Fill(CR, FLook.HeaderFill);
        if B >= 0 then
        begin
          TR := CR;
          InflateRect(TR, -Pad, 0);
          Txt(FBands[B].Caption, TR, HF, FLook.HeaderText, AlignFlags(FBands[B].Alignment));
        end;
        AddFrame(CR, FLook.HeaderLine);
      end;
      Inc(Y, FRowH);
    end;
    // Spaltenkoepfe
    for C := Pg.ColFirst to Pg.ColFirst + Pg.ColCount - 1 do
    begin
      CR := Rect(ColX[C - Pg.ColFirst], Y, ColX[C - Pg.ColFirst + 1], Y + FRowH);
      if FColLook[C].Header.Fill <> clNone then
        Fill(CR, FColLook[C].Header.Fill)
      else
        Fill(CR, FLook.HeaderFill);
      Info := Src.TableColumn(C);
      TR := CR;
      InflateRect(TR, -Pad, 0);
      if FColLook[C].Header.TextColor <> clNone then
        Txt(Info.Title, TR, FontFor(FLook.HeaderFontStyle + FColLook[C].Header.FontStyle, '', 0),
          FColLook[C].Header.TextColor, AlignFlags(FColLook[C].HeaderAlignment))
      else
        Txt(Info.Title, TR, FontFor(FLook.HeaderFontStyle + FColLook[C].Header.FontStyle, '', 0),
          FLook.HeaderText, AlignFlags(FColLook[C].HeaderAlignment));
      AddFrame(CR, FLook.HeaderLine);
    end;
    Inc(Y, FRowH);
  end;

  procedure GroupLine;
  begin
    // Eine Flaeche ueber alle Spalten der Seite, Text eingerueckt je Ebene
    CR := Rect(ColX[0], Y, PageRight, Y + FRowH);
    Fill(CR, FLook.GroupFill);
    TR := CR;
    InflateRect(TR, -Pad, 0);
    Inc(TR.Left, FLines.Level(Li) * Pad * 4);
    Txt(FLines.Text(Li), TR, FontFor(FLook.GroupFontStyle, '', 0), FLook.GroupText,
      DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
    AddFrame(CR, FLook.Line);
  end;

  procedure FooterLine;
  var
    C: Integer;
    FF: TFont;
  begin
    FF := FontFor(FLook.FooterFontStyle, '', 0);
    for C := Pg.ColFirst to Pg.ColFirst + Pg.ColCount - 1 do
    begin
      CR := Rect(ColX[C - Pg.ColFirst], Y, ColX[C - Pg.ColFirst + 1], Y + FRowH);
      Fill(CR, FLook.FooterFill);
      TR := CR;
      InflateRect(TR, -Pad, 0);
      Txt(FLookSrc.ExportFooterText(C), TR, FF, FLook.FooterText,
        AlignFlags(Src.TableColumn(C).Alignment));
      AddFrame(CR, FLook.HeaderLine);
    end;
  end;

  procedure DataCell(ACol, ARow: Integer; const ARect: TRect; Alt: Boolean);
  var
    Cs: TPPGGridCellStyle;
    BarR: TRect;
  begin
    S := Src.TableCellText(ACol, ARow);
    Cs.Reset;
    if HasLook then
      Cs := FLookSrc.ExportCellStyle(ACol, ARow, S, Alt)
    else if FPrintColors and (PS <> nil) then
      Cs := PS.PrintCellStyle(ACol, ARow, S);
    St := PPGResolveCellLook(FLook, Cs);
    Fill(ARect, St.Fill);
    if FPrintColors and (St.Bar >= 0) then
    begin
      BarR := ARect;
      InflateRect(BarR, -Pad div 2, -FRowH div 5);
      BarR.Right := BarR.Left + Round((BarR.Right - BarR.Left) * St.Bar);
      if BarR.Right > BarR.Left then
        Fill(BarR, PPGBlendColor(clWhite, St.BarColor, 0.45));
    end;
    K := Kinds[ACol - Pg.ColFirst];
    if K <> nil then
    begin
      Ctx := KindCtx[ACol - Pg.ColFirst];
      if St.Fill <> clNone then
        Ctx.FillColor := St.Fill;
      if St.TextColor <> clNone then
        Ctx.TextColor := St.TextColor;
      K.PaintCell(Ctx, ARect, S);
    end
    else
    begin
      Info := Src.TableColumn(ACol);
      TR := ARect;
      InflateRect(TR, -Pad, 0);
      Txt(S, TR, FontFor(St.FontStyle, St.FontName, St.FontSize), St.TextColor,
        AlignFlags(Info.Alignment));
    end;
    AddFrame(ARect, FLook.Line);
  end;

  procedure DataLine;
  var
    J, VR, VC: Integer;
    MR: TRect;
  begin
    Row := FLines.Row(Li);
    for J := Pg.ColFirst to Pg.ColFirst + Pg.ColCount - 1 do
    begin
      CR := Rect(ColX[J - Pg.ColFirst], Y, ColX[J - Pg.ColFirst + 1], Y + FRowH);
      M := -1;
      if Length(FMerges) > 0 then
        M := MergeAt(J, Row);
      if M < 0 then
      begin
        DataCell(J, Row, CR, FLines.Alternate(Li));
        Continue;
      end;
      // Verbundene Zelle: einmal je Seite an ihrer ersten sichtbaren Zelle,
      // ueber den sichtbaren Teil, mit Text und Stil der Ursprungszelle
      VR := Max(FMerges[M].Top, Pg.RowFirst);
      VC := Max(FMerges[M].Left, Pg.ColFirst);
      Covered := (J <> VC) or (Row <> VR);
      if Covered then
        Continue;
      MR.Left := CR.Left;
      MR.Top := CR.Top;
      MR.Right := ColX[Min(FMerges[M].Right, Pg.ColFirst + Pg.ColCount - 1) - Pg.ColFirst + 1];
      MR.Bottom := Y + (Min(FMerges[M].Bottom, Pg.RowFirst + Pg.RowCount - 1) - Row + 1) * FRowH;
      DataCell(FMerges[M].Left, FMerges[M].Top, MR, FLines.Alternate(FMerges[M].Top));
    end;
  end;

  procedure GridLines;
  var
    J: Integer;
    LB: HBRUSH;
    Last: TColor;
    Bottom: Integer;
    FR: TRect;
  begin
    // Rechte und untere Kante jeder Zelle, dazu linke und obere Tabellenkante
    if not FPrintGridLines or (NF = 0) then
      Exit;
    LB := 0;
    Last := clNone;
    Bottom := TableTop;
    try
      for J := 0 to NF - 1 do
      begin
        Bottom := Max(Bottom, Frames[J].R.Bottom);
        if Frames[J].Color = clNone then
          Continue;
        if (LB = 0) or (Frames[J].Color <> Last) then
        begin
          if LB <> 0 then
            DeleteObject(LB);
          LB := CreateSolidBrush(ColorToRGB(Frames[J].Color));
          Last := Frames[J].Color;
        end;
        FR := Frames[J].R;
        Winapi.Windows.FillRect(DC, Rect(FR.Right, FR.Top, FR.Right + LW, FR.Bottom + LW), LB);
        Winapi.Windows.FillRect(DC, Rect(FR.Left, FR.Bottom, FR.Right + LW, FR.Bottom + LW), LB);
      end;
      if LB <> 0 then
        DeleteObject(LB);
      LB := 0;
      if FLook.HeaderLine <> clNone then
        LB := CreateSolidBrush(ColorToRGB(FLook.HeaderLine))
      else if FLook.Line <> clNone then
        LB := CreateSolidBrush(ColorToRGB(FLook.Line));
      if LB <> 0 then
      begin
        Winapi.Windows.FillRect(DC, Rect(ColX[0], TableTop, ColX[0] + LW, Bottom + LW), LB);
        Winapi.Windows.FillRect(DC, Rect(ColX[0], TableTop, PageRight + LW, TableTop + LW), LB);
      end;
    finally
      if LB <> 0 then
        DeleteObject(LB);
    end;
  end;

begin
  Layout(Device);
  if (PageIndex < 0) or (PageIndex > High(FPages)) then
    Exit;
  Src := Source;
  PS := PrintSource;
  Pg := FPages[PageIndex];
  HasLook := FLookSrc <> nil;
  Pad := MulDiv(4, Device.PPI, 96);
  LW := Max(1, Device.PPI div 200); // duenne Linien (bei 600 dpi 3 Punkte)
  NF := 0;
  SaveDC(DC);
  try
    SetMapMode(DC, MM_TEXT);
    Canvas := TPPGGdiCanvas.Create(DC);
    // Kopfzeile
    if FPageHeadH > 0 then
    begin
      TR := Rect(FContent.Left, FContent.Top, FContent.Right, FContent.Top + FPageHeadH div 2 * 2);
      Txt(ExpandText(HeaderText, PageIndex + 1, Length(FPages)), TR, FBoldFont, clBlack,
        DT_SINGLELINE or DT_TOP or DT_NOPREFIX or DT_END_ELLIPSIS);
    end;
    Y := FContent.Top + FPageHeadH;
    TableTop := Y;
    if Src = nil then
      Exit;
    // Spaltenkanten der Seite
    SetLength(ColX, Pg.ColCount + 1);
    X := FContent.Left;
    for C := 0 to Pg.ColCount - 1 do
    begin
      ColX[C] := X;
      Inc(X, FColW[Pg.ColFirst + C]);
    end;
    ColX[Pg.ColCount] := X;
    // Zellarten der Spalten (einmal je Seite)
    SetLength(Kinds, Pg.ColCount);
    SetLength(KindCtx, Pg.ColCount);
    if PS <> nil then
    begin
      FPainter.Prepare(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName));
      for C := 0 to Pg.ColCount - 1 do
      begin
        Kinds[C] := PS.PrintCellKind(Pg.ColFirst + C, KindCtx[C]);
        if Kinds[C] <> nil then
        begin
          // Papier: Text, Akzent und Sterne wie im hellen Grid
          KindCtx[C].Canvas := Canvas;
          KindCtx[C].Painter := FPainter;
          KindCtx[C].PPI := Device.PPI;
          KindCtx[C].Font := FFont;
          KindCtx[C].TextColor := clBlack;
          KindCtx[C].FillColor := clWhite;
          KindCtx[C].LineColor := PlainLineColor;
          KindCtx[C].HintColor := $00808080;
          KindCtx[C].RightToLeft := False;
          if HasLook then
          begin
            if FLook.Text <> clNone then
              KindCtx[C].TextColor := FLook.Text;
            if FLook.Line <> clNone then
              KindCtx[C].LineColor := FLook.Line;
            KindCtx[C].AccentColor := FLook.Accent;
            KindCtx[C].HintColor := FLook.Hint;
            KindCtx[C].Tokens.Accent := FLook.Accent;
            KindCtx[C].Tokens.Warning := FLook.Warning;
          end;
        end;
      end;
    end;
    if Pg.WithHeader then
      HeaderRows;
    // Druckzeilen (seitenweise aus der Quelle)
    LastLine := Pg.RowFirst + Pg.RowCount - 1;
    for Li := Pg.RowFirst to LastLine do
    begin
      case FLines.Kind(Li) of
        tlGroup: GroupLine;
        tlFooter: FooterLine;
      else
        DataLine;
      end;
      Inc(Y, FRowH);
    end;
    GridLines;
    // Fusszeile
    if FPageFootH > 0 then
    begin
      TR := Rect(FContent.Left, FContent.Bottom - FPageFootH, FContent.Right, FContent.Bottom);
      Txt(ExpandText(FooterText, PageIndex + 1, Length(FPages)), TR, FFont, clBlack,
        DT_SINGLELINE or DT_BOTTOM or DT_CENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
    end;
  finally
    Canvas := nil;
    RestoreDC(DC, -1);
  end;
end;

end.
