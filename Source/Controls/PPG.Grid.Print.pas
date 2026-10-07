unit PPG.Grid.Print;

{ Drucken von Tabellen (Phase 13e).

  - TPPGGridPrinter (Komponente fuer den Formular-Designer) druckt eine
    IPPGTableSource: das Grid, das DB-Grid oder eine eigene Quelle. Er kennt
    das Control nicht (DIP); Darstellung (bedingte Formate, Zellarten) kommt
    ueber das schmale IPPGGridPrintSource.
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
  PPG.Types, PPG.Render.Intf, PPG.Grid.Data, PPG.Grid.Styles, PPG.Grid.CellKinds,
  PPG.Grid.Paint, PPG.Grid, PPG.Print;

type
  // Seit Phase 14a in PPG.Print (Namen bleiben fuer bestehenden Code)
  TPPGPrintDevice = PPG.Print.TPPGPrintDevice;
  TPPGPrintMargins = PPG.Print.TPPGPrintMargins;
  TPPGPrintPreviewView = PPG.Print.TPPGPrintPreviewView;
  TPPGPrintPreviewForm = PPG.Print.TPPGPrintPreviewForm;
  TPPGPageSetupForm = PPG.Print.TPPGPageSetupForm;

  TPPGPrintPage = record
    RowFirst, RowCount: Integer;
    ColFirst, ColCount: Integer;
    WithHeader: Boolean;
  end;

  TPPGGridPrinter = class(TPPGCustomPrinter)
  private
    FGrid: TPPGCustomGrid;
    FSource: IPPGTableSource;
    FRepeatHeader: Boolean;
    FFitToPageWidth: Boolean;
    FPrintGridLines: Boolean;
    FPrintColors: Boolean;
    // Layout fuer ein Geraet
    FLayoutDevice: TPPGPrintDevice;
    FLayoutValid: Boolean;
    FPages: array of TPPGPrintPage;
    FColW: array of Integer;
    FRowH, FPageHeadH, FPageFootH: Integer;
    FContent: TRect;
    FFont, FBoldFont: TFont;
    FPainter: TPPGCellPainter;
    procedure SetGrid(const Value: TPPGCustomGrid);
    function PrintSource: IPPGGridPrintSource;
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
    property PrinterName;
  end;

implementation

uses
  System.Math, System.UITypes, PPG.Lang, PPG.Consts, PPG.Exceptions, PPG.Render.Gdi,
  PPG.Render.Registry;

{ TPPGGridPrinter }

constructor TPPGGridPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRepeatHeader := True;
  FFitToPageWidth := True;
  FPrintGridLines := True;
  FPrintColors := True;
  FFont := TFont.Create;
  FBoldFont := TFont.Create;
  FPainter := TPPGCellPainter.Create;
end;

destructor TPPGGridPrinter.Destroy;
begin
  FreeAndNil(FPainter);
  FreeAndNil(FBoldFont);
  FreeAndNil(FFont);
  inherited Destroy;
end;

function TPPGGridPrinter.OptionCount: Integer;
begin
  Result := 4;
end;

function TPPGGridPrinter.OptionCaption(Index: Integer): string;
begin
  case Index of
    0: Result := PPGStr(@SPPGPageSetupFit);
    1: Result := PPGStr(@SPPGPageSetupRepeat);
    2: Result := PPGStr(@SPPGPageSetupGridLines);
  else
    Result := PPGStr(@SPPGPageSetupColors);
  end;
end;

function TPPGGridPrinter.GetOption(Index: Integer): Boolean;
begin
  case Index of
    0: Result := FFitToPageWidth;
    1: Result := FRepeatHeader;
    2: Result := FPrintGridLines;
  else
    Result := FPrintColors;
  end;
end;

procedure TPPGGridPrinter.SetOption(Index: Integer; Value: Boolean);
begin
  case Index of
    0: FFitToPageWidth := Value;
    1: FRepeatHeader := Value;
    2: FPrintGridLines := Value;
  else
    FPrintColors := Value;
  end;
  Invalidate;
end;

procedure TPPGGridPrinter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FGrid) then
    FGrid := nil;
end;

procedure TPPGGridPrinter.SetGrid(const Value: TPPGCustomGrid);
begin
  if FGrid <> Value then
  begin
    if FGrid <> nil then
      FGrid.RemoveFreeNotification(Self);
    FGrid := Value;
    if FGrid <> nil then
      FGrid.FreeNotification(Self);
    Invalidate;
  end;
end;

procedure TPPGGridPrinter.SetSource(const Value: IPPGTableSource);
begin
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

procedure TPPGGridPrinter.Layout(const Device: TPPGPrintDevice);
var
  Src: IPPGTableSource;
  PS: IPPGGridPrintSource;
  I, N, PPI, Total, Avail, TH, Body, R, C0, W, RowsLeft, RowFirst, NP: Integer;
  Scale: Double;
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
  Src := Source;
  PS := PrintSource;
  PPI := Device.PPI;
  FContent := MarginRect(Device);
  // Schrift in Drucker-PPI (Font.Height, nicht Font.Size mit Bildschirm-PPI)
  if PS <> nil then
    FFont.Assign(PS.PrintFont);
  FFont.Height := -MulDiv(FFont.Size, PPI, 72);
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
  Scale := 1;
  if FFitToPageWidth and (Total > Avail) and (Total > 0) then
  begin
    Scale := Avail / Total;
    for I := 0 to N - 1 do
      FColW[I] := Trunc(FColW[I] * Scale);
    FFont.Height := Round(FFont.Height * Scale);
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
    FRowH := Max(FRowH, Round(MulDiv(PS.PrintRowHeight, PPI, 96) * Scale));
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
  // Zeilen auf Seiten verteilen
  RowsLeft := 0;
  if Src <> nil then
    RowsLeft := Src.TableRowCount;
  RowFirst := 0;
  First := True;
  NP := 0;
  repeat
    Body := (FContent.Bottom - FContent.Top) - FPageHeadH - FPageFootH;
    if First or FRepeatHeader then
      Dec(Body, FRowH);
    R := Max(1, Body div FRowH);
    if R > RowsLeft then
      R := RowsLeft;
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
const
  HeadFill = $00F0F0F0;
  LineColor = $00A0A0A0;
var
  Src: IPPGTableSource;
  PS: IPPGGridPrintSource;
  Pg: TPPGPrintPage;
  Canvas: IPPGCanvas;
  X, Y, C, R, Pad, LW: Integer;
  CR, TR: TRect;
  Info: TPPGTableColumnInfo;
  S: string;
  St: TPPGGridCellStyle;
  K: IPPGCellKind;
  Ctx: TPPGCellKindContext;
  Fl: Cardinal;
  LineBrush: HBRUSH;
  Kinds: array of IPPGCellKind;
  KindCtx: array of TPPGCellKindContext;

  procedure Txt(const AText: string; ARect: TRect; AFont: TFont; AColor: TColor; AFlags: Cardinal);
  begin
    if AText = '' then
      Exit;
    SelectObject(DC, AFont.Handle);
    SetBkMode(DC, TRANSPARENT);
    SetTextColor(DC, ColorToRGB(AColor));
    Winapi.Windows.DrawText(DC, PChar(AText), Length(AText), ARect, AFlags);
  end;

  procedure Fill(const ARect: TRect; AColor: TColor);
  var
    B: HBRUSH;
  begin
    B := CreateSolidBrush(ColorToRGB(AColor));
    try
      Winapi.Windows.FillRect(DC, ARect, B);
    finally
      DeleteObject(B);
    end;
  end;

  function AlignFlags(A: TAlignment): Cardinal;
  begin
    Result := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
    case A of
      taRightJustify: Result := Result or DT_RIGHT;
      taCenter: Result := Result or DT_CENTER;
    end;
  end;

begin
  Layout(Device);
  if (PageIndex < 0) or (PageIndex > High(FPages)) then
    Exit;
  Src := Source;
  PS := PrintSource;
  Pg := FPages[PageIndex];
  Pad := MulDiv(4, Device.PPI, 96);
  LW := Max(1, Device.PPI div 200); // duenne Linien (bei 600 dpi 3 Punkte)
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
    if Src = nil then
      Exit;
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
          // Druckfarben: schwarzer Text auf weissem Papier
          KindCtx[C].Canvas := Canvas;
          KindCtx[C].Painter := FPainter;
          KindCtx[C].PPI := Device.PPI;
          KindCtx[C].Font := FFont;
          KindCtx[C].TextColor := clBlack;
          KindCtx[C].FillColor := clWhite;
          KindCtx[C].LineColor := LineColor;
          KindCtx[C].HintColor := $00808080;
          KindCtx[C].RightToLeft := False;
        end;
      end;
    end;
    // Spaltenkoepfe
    if Pg.WithHeader then
    begin
      X := FContent.Left;
      for C := Pg.ColFirst to Pg.ColFirst + Pg.ColCount - 1 do
      begin
        CR := Rect(X, Y, X + FColW[C], Y + FRowH);
        if FPrintColors then
          Fill(CR, HeadFill);
        Info := Src.TableColumn(C);
        TR := CR;
        InflateRect(TR, -Pad, 0);
        Txt(Info.Title, TR, FBoldFont, clBlack, AlignFlags(Info.Alignment));
        Inc(X, FColW[C]);
      end;
      Inc(Y, FRowH);
    end;
    // Zeilen (seitenweise aus der Quelle)
    for R := Pg.RowFirst to Pg.RowFirst + Pg.RowCount - 1 do
    begin
      X := FContent.Left;
      for C := Pg.ColFirst to Pg.ColFirst + Pg.ColCount - 1 do
      begin
        CR := Rect(X, Y, X + FColW[C], Y + FRowH);
        S := Src.TableCellText(C, R);
        St.Reset;
        if FPrintColors and (PS <> nil) then
          St := PS.PrintCellStyle(C, R, S);
        if St.Fill <> clNone then
          Fill(CR, St.Fill);
        if FPrintColors and (St.Bar >= 0) then
        begin
          TR := CR;
          InflateRect(TR, -Pad div 2, -FRowH div 5);
          TR.Right := TR.Left + Round((TR.Right - TR.Left) * St.Bar);
          if TR.Right > TR.Left then
            Fill(TR, PPGBlendColor(clWhite, St.BarColor, 0.45));
        end;
        K := Kinds[C - Pg.ColFirst];
        if K <> nil then
        begin
          Ctx := KindCtx[C - Pg.ColFirst];
          K.PaintCell(Ctx, CR, S);
        end
        else
        begin
          Info := Src.TableColumn(C);
          TR := CR;
          InflateRect(TR, -Pad, 0);
          Fl := AlignFlags(Info.Alignment);
          if St.TextColor <> clNone then
          begin
            if St.Bold then
              Txt(S, TR, FBoldFont, St.TextColor, Fl)
            else
              Txt(S, TR, FFont, St.TextColor, Fl);
          end
          else if St.Bold then
            Txt(S, TR, FBoldFont, clBlack, Fl)
          else
            Txt(S, TR, FFont, clBlack, Fl);
        end;
        Inc(X, FColW[C]);
      end;
      Inc(Y, FRowH);
    end;
    // Gitterlinien
    if FPrintGridLines then
    begin
      LineBrush := CreateSolidBrush(LineColor);
      try
        R := FContent.Top + FPageHeadH;
        X := FContent.Left;
        for C := Pg.ColFirst to Pg.ColFirst + Pg.ColCount do
        begin
          Winapi.Windows.FillRect(DC, Rect(X, R, X + LW, Y), LineBrush);
          if C < Pg.ColFirst + Pg.ColCount then
            Inc(X, FColW[C]);
        end;
        while R <= Y do
        begin
          Winapi.Windows.FillRect(DC, Rect(FContent.Left, R, X + LW, R + LW), LineBrush);
          Inc(R, FRowH);
        end;
      finally
        DeleteObject(LineBrush);
      end;
    end;
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
