unit PPG.Grid.Print;

{ Drucken von Tabellen (Phase 13e).

  - TPPGGridPrinter (Komponente fuer den Formular-Designer) druckt eine
    IPPGTableSource: das Grid, das DB-Grid oder eine eigene Quelle. Er kennt
    das Control nicht (DIP); Darstellung (bedingte Formate, Zellarten) kommt
    ueber das schmale IPPGGridPrintSource.
  - Seite: Ausrichtung, Raender (mm), Kopf-/Fusszeile mit Platzhaltern
    [Seite]/[Page], [Seiten]/[Pages], [Datum]/[Date], [Titel]/[Title].
    Spaltenkoepfe auf jeder Seite, auf Seitenbreite einpassen oder Spalten
    auf mehrere Seiten verteilen, Gitterlinien und Farben abschaltbar.
  - Gezeichnet wird mit dem GDI-Canvas in der Aufloesung des Druckers (GDI+
    rastert Alpha-Flaechen auf Drucker-DCs zu grossen Bitmaps). Alle Masse
    sind logisch (96 dpi) und werden mit der Drucker-PPI umgerechnet; die
    Schrift wird ueber Font.Height mit der Drucker-PPI neu gesetzt.
  - Zeilen holt der Drucker seitenweise aus der Quelle (virtuelle Daten).
  - Vorschau: TPPGPrintPreviewForm (PPGlow-Controls) zeichnet nur sichtbare
    Seiten in Metafiles (mit Zwischenspeicher fuer wenige Seiten). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Printers,
  Vcl.ExtCtrls, PPG.Types, PPG.Render.Intf, PPG.Controls.Base, PPG.Controls.Scroll,
  PPG.Grid.Data, PPG.Grid.Styles, PPG.Grid.CellKinds, PPG.Grid.Paint, PPG.Grid,
  PPG.Panel, PPG.Button, PPG.Labels, PPG.ComboBox, PPG.ListBox, PPG.CheckBox,
  PPG.RadioButton, PPG.SpinEdit, PPG.Edit;

type
  /// Druckflaeche eines Geraets (alles in Geraetepunkten).
  TPPGPrintDevice = record
    PPI: Integer;
    /// Bedruckbarer Bereich (Ursprung = linke obere Ecke davon).
    PageWidth, PageHeight: Integer;
    /// Nicht bedruckbarer Rand links/oben und physische Blattgroesse.
    OffsetX, OffsetY: Integer;
    PhysWidth, PhysHeight: Integer;
    /// A4 ohne Drucker (Vorschau, Tests).
    class function A4(APPI: Integer; Landscape: Boolean): TPPGPrintDevice; static;
    class function FromDC(DC: HDC): TPPGPrintDevice; static;
    function SameAs(const Other: TPPGPrintDevice): Boolean;
  end;

  TPPGPrintMargins = class(TPersistent)
  private
    FLeft, FTop, FRight, FBottom: Integer;
    FOnChange: TNotifyEvent;
    procedure SetValue(Index: Integer; const Value: Integer);
  public
    constructor Create;
    procedure Assign(Source: TPersistent); override;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// Raender in Millimetern (vom Blattrand gemessen).
    property Left: Integer index 0 read FLeft write SetValue default 15;
    property Top: Integer index 1 read FTop write SetValue default 15;
    property Right: Integer index 2 read FRight write SetValue default 15;
    property Bottom: Integer index 3 read FBottom write SetValue default 15;
  end;

  TPPGPrintPage = record
    RowFirst, RowCount: Integer;
    ColFirst, ColCount: Integer;
    WithHeader: Boolean;
  end;

  TPPGGridPrinter = class(TComponent)
  private
    FGrid: TPPGCustomGrid;
    FSource: IPPGTableSource;
    FTitle: string;
    FHeaderText: string;
    FFooterText: string;
    FOrientation: TPrinterOrientation;
    FMargins: TPPGPrintMargins;
    FRepeatHeader: Boolean;
    FFitToPageWidth: Boolean;
    FPrintGridLines: Boolean;
    FPrintColors: Boolean;
    FPrinterName: string;
    // Layout fuer ein Geraet
    FLayoutDevice: TPPGPrintDevice;
    FLayoutValid: Boolean;
    FPages: array of TPPGPrintPage;
    FColW: array of Integer;
    FRowH, FPageHeadH, FPageFootH: Integer;
    FContent: TRect;
    FFont, FBoldFont: TFont;
    FPainter: TPPGCellPainter;
    FDate: TDateTime;
    procedure SetGrid(const Value: TPPGCustomGrid);
    procedure SetMargins(const Value: TPPGPrintMargins);
    procedure MarginsChanged(Sender: TObject);
    function PrintSource: IPPGGridPrintSource;
    procedure DoPrint(const APrinterName, AOutput: string);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Eigene Quelle statt Grid (z.B. TPPGStringTableSource); nil = Grid.
    procedure SetSource(const Value: IPPGTableSource);
    function Source: IPPGTableSource;
    /// Layout neu berechnen (nach Aenderung der Daten).
    procedure Invalidate;
    /// Geraet des eingestellten Druckers (ohne Drucker: A4 600 dpi).
    function PrinterDevice: TPPGPrintDevice;
    procedure Layout(const Device: TPPGPrintDevice);
    /// Seiten fuer das Geraet (Vorgabe: der eingestellte Drucker).
    function PageCount: Integer; overload;
    function PageCount(const Device: TPPGPrintDevice): Integer; overload;
    function Page(Index: Integer): TPPGPrintPage;
    /// Seite auf einen DC zeichnen (Ursprung = bedruckbarer Bereich).
    procedure RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice);
    /// Platzhalter ersetzen.
    function ExpandText(const S: string; PageNo, Pages: Integer): string;
    /// Drucken auf PrinterName ('' = Standarddrucker), ohne Dialog.
    procedure Print;
    /// Drucken in eine Datei (z.B. "Microsoft Print to PDF", Phase 13f).
    procedure PrintToFile(const APrinterName, AFileName: string);
    /// Vorschau (modal); True = gedruckt.
    function Preview: Boolean;
    /// Seite einrichten (modal); True = uebernommen.
    function PageSetup: Boolean;
    /// Spaltenbreiten des Layouts (Geraetepunkte).
    function LayoutColWidth(ACol: Integer): Integer;
    property LayoutRowHeight: Integer read FRowH;
    property ContentRect: TRect read FContent;
  published
    property Grid: TPPGCustomGrid read FGrid write SetGrid;
    property Title: string read FTitle write FTitle;
    property HeaderText: string read FHeaderText write FHeaderText;
    /// '' = keine Fusszeile; Vorgabe "Seite [Seite] von [Seiten]" (Sprache).
    property FooterText: string read FFooterText write FFooterText;
    property Orientation: TPrinterOrientation read FOrientation write FOrientation default poPortrait;
    property Margins: TPPGPrintMargins read FMargins write SetMargins;
    property RepeatHeader: Boolean read FRepeatHeader write FRepeatHeader default True;
    property FitToPageWidth: Boolean read FFitToPageWidth write FFitToPageWidth default True;
    property PrintGridLines: Boolean read FPrintGridLines write FPrintGridLines default True;
    property PrintColors: Boolean read FPrintColors write FPrintColors default True;
    /// '' = Standarddrucker.
    property PrinterName: string read FPrinterName write FPrinterName;
  end;

  /// Seitenansicht in der Vorschau (zeichnet nur sichtbare Seiten).
  TPPGPrintPreviewView = class(TPPGCustomScrollControl)
  private
    FPrinter: TPPGGridPrinter;
    FDevice: TPPGPrintDevice;
    FPageIndex: Integer;
    FZoom: Integer;          // Prozent; 0 = ganze Seite, -1 = Seitenbreite
    FCache: TObjectDictionary<Integer, TMetafile>;
    FCacheOrder: TList<Integer>;
    function PageScale: Double;
    procedure SetPageIndex(const Value: Integer);
    procedure SetZoom(const Value: Integer);
    procedure UpdateContent;
  protected
    procedure PaintViewport(const ACanvas: IPPGCanvas; const View: TRect); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Setup(APrinter: TPPGGridPrinter; const ADevice: TPPGPrintDevice);
    /// Metafile einer Seite (zwischengespeichert, hoechstens 8 Seiten).
    function PageMetafile(Index: Integer): TMetafile;
    procedure ClearCache;
    function CachedPages: Integer;
    property PageIndex: Integer read FPageIndex write SetPageIndex;
    property Zoom: Integer read FZoom write SetZoom;
  end;

  TPPGPrintPreviewForm = class(TForm)
  private
    FPrinter: TPPGGridPrinter;
    FDevice: TPPGPrintDevice;
    FBar: TPPGPanel;
    FPages: TPPGListBox;
    FView: TPPGPrintPreviewView;
    FPageLabel: TPPGLabel;
    FZoomBox: TPPGComboBox;
    FPrinted: Boolean;
    procedure BuildControls;
    procedure Refill;
    procedure PrintClick(Sender: TObject);
    procedure SetupClick(Sender: TObject);
    procedure NavClick(Sender: TObject);
    procedure PageListClick(Sender: TObject);
    procedure ZoomChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    function S(V: Integer): Integer;
  public
    constructor CreateFor(APrinter: TPPGGridPrinter); virtual;
    procedure GoToPage(Index: Integer);
    property View: TPPGPrintPreviewView read FView;
    property PageList: TPPGListBox read FPages;
    property Printed: Boolean read FPrinted;
  end;

  TPPGPageSetupForm = class(TForm)
  private
    FPrinter: TPPGGridPrinter;
    FPortrait, FLandscape: TPPGRadioButton;
    FFit, FLines, FColors, FRepeat: TPPGCheckBox;
    FMargin: array[0..3] of TPPGSpinEdit;
    FHeader, FFooter: TPPGEdit;
    function S(V: Integer): Integer;
  public
    constructor CreateFor(APrinter: TPPGGridPrinter); virtual;
    /// Werte in den Drucker uebernehmen.
    procedure Apply;
  end;

implementation

uses
  System.Math, System.UITypes, PPG.Lang, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler, PPG.Appearance, PPG.Theme,
  PPG.Render.Gdi, PPG.Render.Registry, PPG.Render.Shapes, Winapi.WinSpool;

const
  PreviewCacheSize = 8;

{ TPPGPrintDevice }

class function TPPGPrintDevice.A4(APPI: Integer; Landscape: Boolean): TPPGPrintDevice;
begin
  Result.PPI := APPI;
  Result.PhysWidth := Round(210 / 25.4 * APPI);
  Result.PhysHeight := Round(297 / 25.4 * APPI);
  if Landscape then
  begin
    Result.PhysWidth := Round(297 / 25.4 * APPI);
    Result.PhysHeight := Round(210 / 25.4 * APPI);
  end;
  // typischer nicht bedruckbarer Rand: 4 mm
  Result.OffsetX := Round(4 / 25.4 * APPI);
  Result.OffsetY := Result.OffsetX;
  Result.PageWidth := Result.PhysWidth - 2 * Result.OffsetX;
  Result.PageHeight := Result.PhysHeight - 2 * Result.OffsetY;
end;

class function TPPGPrintDevice.FromDC(DC: HDC): TPPGPrintDevice;
begin
  Result.PPI := GetDeviceCaps(DC, LOGPIXELSY);
  Result.PageWidth := GetDeviceCaps(DC, HORZRES);
  Result.PageHeight := GetDeviceCaps(DC, VERTRES);
  Result.OffsetX := GetDeviceCaps(DC, PHYSICALOFFSETX);
  Result.OffsetY := GetDeviceCaps(DC, PHYSICALOFFSETY);
  Result.PhysWidth := GetDeviceCaps(DC, PHYSICALWIDTH);
  Result.PhysHeight := GetDeviceCaps(DC, PHYSICALHEIGHT);
  // Bildschirm-/Bitmap-DCs kennen kein Blatt
  if Result.PhysWidth <= 0 then
    Result.PhysWidth := Result.PageWidth;
  if Result.PhysHeight <= 0 then
    Result.PhysHeight := Result.PageHeight;
  if Result.PPI <= 0 then
    Result.PPI := 96;
end;

function TPPGPrintDevice.SameAs(const Other: TPPGPrintDevice): Boolean;
begin
  Result := (PPI = Other.PPI) and (PageWidth = Other.PageWidth) and
    (PageHeight = Other.PageHeight) and (OffsetX = Other.OffsetX) and
    (OffsetY = Other.OffsetY) and (PhysWidth = Other.PhysWidth) and
    (PhysHeight = Other.PhysHeight);
end;

{ TPPGPrintMargins }

constructor TPPGPrintMargins.Create;
begin
  inherited Create;
  FLeft := 15;
  FTop := 15;
  FRight := 15;
  FBottom := 15;
end;

procedure TPPGPrintMargins.Assign(Source: TPersistent);
var
  M: TPPGPrintMargins;
begin
  if Source is TPPGPrintMargins then
  begin
    M := TPPGPrintMargins(Source);
    FLeft := M.FLeft;
    FTop := M.FTop;
    FRight := M.FRight;
    FBottom := M.FBottom;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end
  else
    inherited Assign(Source);
end;

procedure TPPGPrintMargins.SetValue(Index: Integer; const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Margin', Value, 0, 100);
  case Index of
    0: FLeft := V;
    1: FTop := V;
    2: FRight := V;
  else
    FBottom := V;
  end;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

{ TPPGGridPrinter }

constructor TPPGGridPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMargins := TPPGPrintMargins.Create;
  FMargins.OnChange := MarginsChanged;
  FRepeatHeader := True;
  FFitToPageWidth := True;
  FPrintGridLines := True;
  FPrintColors := True;
  FFooterText := PPGStr(@SPPGPrintFooterDefault);
  FFont := TFont.Create;
  FBoldFont := TFont.Create;
  FPainter := TPPGCellPainter.Create;
end;

destructor TPPGGridPrinter.Destroy;
begin
  FreeAndNil(FPainter);
  FreeAndNil(FBoldFont);
  FreeAndNil(FFont);
  FreeAndNil(FMargins);
  inherited Destroy;
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

procedure TPPGGridPrinter.SetMargins(const Value: TPPGPrintMargins);
begin
  FMargins.Assign(Value);
end;

procedure TPPGGridPrinter.MarginsChanged(Sender: TObject);
begin
  Invalidate;
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

/// Name des Druckers ('' = Standarddrucker); Fehler, wenn unbekannt.
function ResolvePrinterName(const Name: string): string;
begin
  if Printer.Printers.Count = 0 then
    raise EPPGError.Create(PPGStr(@SPPGPrintNoPrinter));
  if Name = '' then
  begin
    Printer.PrinterIndex := -1; // Standarddrucker
    Result := Printer.Printers[Printer.PrinterIndex];
  end
  else if Printer.Printers.IndexOf(Name) >= 0 then
    Result := Name
  else
    raise EPPGError.CreateFmt(PPGStr(@SPPGPrinterNotFound), [Name]);
end;

/// DC (bzw. Informations-DC) fuer einen Drucker mit Ausrichtung - ueber die
/// Windows-API statt TPrinter.GetPrinter (dessen PChar-Fassung ist veraltet,
/// die string-Fassung gibt es in XE2 noch nicht).
function CreatePrinterDC(const Name: string; Landscape, InfoOnly: Boolean): HDC;
var
  HPrn: THandle;
  Size: Integer;
  DM: PDeviceMode;
begin
  DM := nil;
  if OpenPrinter(PChar(Name), HPrn, nil) then
  try
    Size := DocumentProperties(0, HPrn, PChar(Name), nil, nil, 0);
    if Size > 0 then
    begin
      GetMem(DM, Size);
      if DocumentProperties(0, HPrn, PChar(Name), DM, nil, DM_OUT_BUFFER) = IDOK then
      begin
        if Landscape then
          DM^.dmOrientation := DMORIENT_LANDSCAPE
        else
          DM^.dmOrientation := DMORIENT_PORTRAIT;
        DM^.dmFields := DM^.dmFields or DM_ORIENTATION;
        DocumentProperties(0, HPrn, PChar(Name), DM, DM, DM_IN_BUFFER or DM_OUT_BUFFER);
      end
      else
      begin
        FreeMem(DM);
        DM := nil;
      end;
    end;
  finally
    ClosePrinter(HPrn);
  end;
  try
    if InfoOnly then
      Result := CreateIC('WINSPOOL', PChar(Name), nil, DM)
    else
      Result := CreateDC('WINSPOOL', PChar(Name), nil, DM);
  finally
    if DM <> nil then
      FreeMem(DM);
  end;
end;

function TPPGGridPrinter.PrinterDevice: TPPGPrintDevice;
var
  DC: HDC;
begin
  Result := TPPGPrintDevice.A4(600, FOrientation = poLandscape);
  try
    if Printer.Printers.Count = 0 then
      Exit;
    // Informations-DC: nur Masse, kein Druckauftrag
    DC := CreatePrinterDC(ResolvePrinterName(FPrinterName), FOrientation = poLandscape, True);
    if DC <> 0 then
    try
      Result := TPPGPrintDevice.FromDC(DC);
    finally
      DeleteDC(DC);
    end;
  except
    // Druckersystem nicht verfuegbar: A4 bleibt (protokolliert)
    on E: Exception do
      TPPGErrorHandler.LogWarning(Self, 'PrinterDevice: ' + E.Message);
  end;
end;

procedure TPPGGridPrinter.Layout(const Device: TPPGPrintDevice);
var
  Src: IPPGTableSource;
  PS: IPPGGridPrintSource;
  I, N, PPI, Total, Avail, TH, Body, R, C0, W, RowsLeft, RowFirst, NP: Integer;
  Scale: Double;
  ML, MT, MR, MB: Integer;
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
  // Raender in mm -> Punkte, vom Blattrand (der bedruckbare Bereich beginnt
  // bei OffsetX/OffsetY)
  ML := Max(0, Round(FMargins.Left / 25.4 * PPI) - Device.OffsetX);
  MT := Max(0, Round(FMargins.Top / 25.4 * PPI) - Device.OffsetY);
  MR := Min(Device.PageWidth, Device.PhysWidth - Round(FMargins.Right / 25.4 * PPI) - Device.OffsetX);
  MB := Min(Device.PageHeight, Device.PhysHeight - Round(FMargins.Bottom / 25.4 * PPI) - Device.OffsetY);
  if MR <= ML then
    MR := Device.PageWidth;
  if MB <= MT then
    MB := Device.PageHeight;
  FContent := Rect(ML, MT, MR, MB);
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
  if FHeaderText <> '' then
    FPageHeadH := TH * 2;
  FPageFootH := 0;
  if FFooterText <> '' then
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

function TPPGGridPrinter.PageCount: Integer;
begin
  Result := PageCount(PrinterDevice);
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

function TPPGGridPrinter.ExpandText(const S: string; PageNo, Pages: Integer): string;
var
  D: string;
begin
  if FDate = 0 then
    D := DateToStr(Date)
  else
    D := DateToStr(FDate);
  Result := S;
  Result := StringReplace(Result, '[Seiten]', IntToStr(Pages), [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[Pages]', IntToStr(Pages), [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[Seite]', IntToStr(PageNo), [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[Page]', IntToStr(PageNo), [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[Datum]', D, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[Date]', D, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[Titel]', FTitle, [rfReplaceAll, rfIgnoreCase]);
  Result := StringReplace(Result, '[Title]', FTitle, [rfReplaceAll, rfIgnoreCase]);
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
      Txt(ExpandText(FHeaderText, PageIndex + 1, Length(FPages)), TR, FBoldFont, clBlack,
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
      Txt(ExpandText(FFooterText, PageIndex + 1, Length(FPages)), TR, FFont, clBlack,
        DT_SINGLELINE or DT_BOTTOM or DT_CENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
    end;
  finally
    Canvas := nil;
    RestoreDC(DC, -1);
  end;
end;

procedure TPPGGridPrinter.DoPrint(const APrinterName, AOutput: string);
var
  DC: HDC;
  DI: TDocInfo;
  Device: TPPGPrintDevice;
  I: Integer;
  DocName: string;
begin
  DC := CreatePrinterDC(ResolvePrinterName(APrinterName), FOrientation = poLandscape, False);
  if DC = 0 then
    PPGRaiseLastOSError('CreateDC');
  try
    Device := TPPGPrintDevice.FromDC(DC);
    Layout(Device);
    DocName := FTitle;
    if DocName = '' then
      DocName := Application.Title;
    FillChar(DI, SizeOf(DI), 0);
    DI.cbSize := SizeOf(DI);
    DI.lpszDocName := PChar(DocName);
    // Ausgabedatei (z.B. PDF-Drucker) ohne Dialog
    if AOutput <> '' then
      DI.lpszOutput := PChar(AOutput);
    if StartDoc(DC, DI) <= 0 then
      PPGRaiseLastOSError('StartDoc');
    try
      for I := 0 to High(FPages) do
      begin
        if StartPage(DC) <= 0 then
          PPGRaiseLastOSError('StartPage');
        RenderPage(I, DC, Device);
        if EndPage(DC) <= 0 then
          PPGRaiseLastOSError('EndPage');
      end;
      EndDoc(DC);
    except
      AbortDoc(DC);
      raise;
    end;
  finally
    DeleteDC(DC);
    Invalidate; // Layout gehoerte zum Drucker-DC
  end;
end;

procedure TPPGGridPrinter.Print;
begin
  DoPrint(FPrinterName, '');
end;

procedure TPPGGridPrinter.PrintToFile(const APrinterName, AFileName: string);
begin
  DoPrint(APrinterName, AFileName);
end;

function TPPGGridPrinter.Preview: Boolean;
var
  F: TPPGPrintPreviewForm;
begin
  F := TPPGPrintPreviewForm.CreateFor(Self);
  try
    F.ShowModal;
    Result := F.Printed;
  finally
    F.Free;
  end;
end;

function TPPGGridPrinter.PageSetup: Boolean;
var
  F: TPPGPageSetupForm;
begin
  F := TPPGPageSetupForm.CreateFor(Self);
  try
    Result := F.ShowModal = mrOk;
    if Result then
      F.Apply;
  finally
    F.Free;
  end;
end;

{ TPPGPrintPreviewView }

constructor TPPGPrintPreviewView.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCache := TObjectDictionary<Integer, TMetafile>.Create([doOwnsValues]);
  FCacheOrder := TList<Integer>.Create;
  FZoom := 0;
  TabStop := True;
end;

destructor TPPGPrintPreviewView.Destroy;
begin
  FreeAndNil(FCacheOrder);
  FreeAndNil(FCache);
  inherited Destroy;
end;

procedure TPPGPrintPreviewView.Setup(APrinter: TPPGGridPrinter; const ADevice: TPPGPrintDevice);
begin
  FPrinter := APrinter;
  FDevice := ADevice;
  ClearCache;
  FPageIndex := 0;
  UpdateContent;
end;

procedure TPPGPrintPreviewView.ClearCache;
begin
  FCache.Clear;
  FCacheOrder.Clear;
  Invalidate;
end;

function TPPGPrintPreviewView.CachedPages: Integer;
begin
  Result := FCache.Count;
end;

function TPPGPrintPreviewView.PageMetafile(Index: Integer): TMetafile;
var
  MC: TMetafileCanvas;
  RefDC: HDC;
begin
  if FCache.TryGetValue(Index, Result) then
  begin
    FCacheOrder.Remove(Index);
    FCacheOrder.Add(Index);
    Exit;
  end;
  // Nur bei Bedarf zeichnen; die aeltesten Seiten fallen heraus
  while FCacheOrder.Count >= PreviewCacheSize do
  begin
    FCache.Remove(FCacheOrder[0]);
    FCacheOrder.Delete(0);
  end;
  Result := TMetafile.Create;
  Result.Width := FDevice.PhysWidth;
  Result.Height := FDevice.PhysHeight;
  RefDC := GetDC(0);
  try
    MC := TMetafileCanvas.Create(Result, RefDC);
    try
      // Metafile in Geraetepunkten des Druckers: Ursprung verschieben
      SetWindowOrgEx(MC.Handle, -FDevice.OffsetX, -FDevice.OffsetY, nil);
      FPrinter.RenderPage(Index, MC.Handle, FDevice);
    finally
      MC.Free;
    end;
  finally
    ReleaseDC(0, RefDC);
  end;
  FCache.Add(Index, Result);
  FCacheOrder.Add(Index);
end;

function TPPGPrintPreviewView.PageScale: Double;
var
  V: TRect;
  AW, AH: Integer;
begin
  V := ViewRect;
  AW := (V.Right - V.Left) - 32;
  AH := (V.Bottom - V.Top) - 32;
  if (FDevice.PhysWidth <= 0) or (FDevice.PhysHeight <= 0) then
    Exit(0.1);
  case FZoom of
    0: Result := Min(AW / FDevice.PhysWidth, AH / FDevice.PhysHeight);
    -1: Result := AW / FDevice.PhysWidth;
  else
    // Prozent bezogen auf die Bildschirmgroesse (96 dpi * Monitor)
    Result := FZoom / 100 * ScalePPI / FDevice.PPI;
  end;
  if Result <= 0 then
    Result := 0.01;
end;

procedure TPPGPrintPreviewView.UpdateContent;
var
  Sc: Double;
begin
  Sc := PageScale;
  SetContentSize(Round(FDevice.PhysWidth * Sc) + 32, Round(FDevice.PhysHeight * Sc) + 32);
  Invalidate;
end;

procedure TPPGPrintPreviewView.SetPageIndex(const Value: Integer);
begin
  if FPageIndex <> Value then
  begin
    FPageIndex := Value;
    ScrollTo(0, 0);
    Invalidate;
  end;
end;

procedure TPPGPrintPreviewView.SetZoom(const Value: Integer);
begin
  if FZoom <> Value then
  begin
    FZoom := Value;
    UpdateContent;
  end;
end;

procedure TPPGPrintPreviewView.Resize;
begin
  inherited Resize;
  if FZoom <= 0 then
    UpdateContent;
end;

procedure TPPGPrintPreviewView.PaintViewport(const ACanvas: IPPGCanvas; const View: TRect);
var
  Sc: Double;
  PR, SR: TRect;
  W, H, X, Y: Integer;
  MF: TMetafile;
  DC: HDC;
begin
  ACanvas.FillRoundRect(View, 0, PPGBlendColor(Color, clGray, 0.25), 255);
  if (FPrinter = nil) or (FPageIndex < 0) or (FPageIndex >= FPrinter.PageCount(FDevice)) then
    Exit;
  Sc := PageScale;
  W := Round(FDevice.PhysWidth * Sc);
  H := Round(FDevice.PhysHeight * Sc);
  X := View.Left + Max(16, ((View.Right - View.Left) - W) div 2) - ScrollX;
  Y := View.Top + 16 - ScrollY;
  PR := Rect(X, Y, X + W, Y + H);
  SR := PR;
  OffsetRect(SR, 4, 4);
  ACanvas.FillRoundRect(SR, 0, clBlack, 40); // Schatten
  ACanvas.FillRoundRect(PR, 0, clWhite, 255);
  MF := PageMetafile(FPageIndex);
  DC := ACanvas.BeginGdi;
  try
    PlayEnhMetaFile(DC, MF.Handle, PR);
  finally
    ACanvas.EndGdi(DC);
  end;
end;

{ TPPGPrintPreviewForm }

constructor TPPGPrintPreviewForm.CreateFor(APrinter: TPPGGridPrinter);
begin
  inherited CreateNew(nil);
  FPrinter := APrinter;
  Caption := PPGStr(@SPPGPreviewTitle);
  if APrinter.Title <> '' then
    Caption := Caption + ' - ' + APrinter.Title;
  Position := poScreenCenter;
  Width := S(900);
  Height := S(700);
  KeyPreview := True;
  OnKeyDown := FormKeyDown;
  Font.Assign(Screen.MessageFont);
  TPPGTheme.ApplyToForm(Self);
  BuildControls;
  Refill;
end;

function TPPGPrintPreviewForm.S(V: Integer): Integer;
begin
  Result := MulDiv(V, Screen.PixelsPerInch, 96);
end;

procedure TPPGPrintPreviewForm.BuildControls;
var
  X: Integer;

  function Btn(const ACaption: string; ATag, AWidth: Integer; AClick: TNotifyEvent): TPPGButton;
  begin
    Result := TPPGButton.Create(Self);
    Result.Parent := FBar;
    Result.Caption := ACaption;
    Result.Tag := ATag;
    Result.SetBounds(X, S(8), S(AWidth), S(30));
    Result.OnClick := AClick;
    Inc(X, S(AWidth) + S(6));
  end;

begin
  FBar := TPPGPanel.Create(Self);
  FBar.Parent := Self;
  FBar.Align := alTop;
  FBar.Height := S(46);
  X := S(8);
  Btn(PPGStr(@SPPGPreviewPrint), 0, 110, PrintClick).Default := True;
  Btn(PPGStr(@SPPGPreviewPageSetup), 0, 140, SetupClick);
  Inc(X, S(10));
  Btn('|<', -2, 36, NavClick);
  Btn('<', -1, 36, NavClick);
  FPageLabel := TPPGLabel.Create(Self);
  FPageLabel.Parent := FBar;
  FPageLabel.AutoSize := False;
  FPageLabel.Alignment := taCenter;
  FPageLabel.SetBounds(X, S(14), S(120), S(22));
  Inc(X, S(126));
  Btn('>', 1, 36, NavClick);
  Btn('>|', 2, 36, NavClick);
  Inc(X, S(10));
  FZoomBox := TPPGComboBox.Create(Self);
  FZoomBox.Parent := FBar;
  FZoomBox.SetBounds(X, S(8), S(140), S(30));
  FZoomBox.Items.Add(PPGStr(@SPPGPreviewZoomPage));
  FZoomBox.Items.Add(PPGStr(@SPPGPreviewZoomWidth));
  FZoomBox.Items.Add('50 %');
  FZoomBox.Items.Add('75 %');
  FZoomBox.Items.Add('100 %');
  FZoomBox.Items.Add('150 %');
  FZoomBox.Items.Add('200 %');
  FZoomBox.ItemIndex := 0;
  FZoomBox.OnChange := ZoomChange;
  Inc(X, S(150));
  Btn(PPGStr(@SPPGPreviewClose), 99, 100, NavClick).Cancel := True;
  FPages := TPPGListBox.Create(Self);
  FPages.Parent := Self;
  FPages.Align := alLeft;
  FPages.Width := S(130);
  FPages.OnClick := PageListClick;
  FView := TPPGPrintPreviewView.Create(Self);
  FView.Parent := Self;
  FView.Align := alClient;
end;

procedure TPPGPrintPreviewForm.Refill;
var
  I, N: Integer;
begin
  FDevice := FPrinter.PrinterDevice;
  FPrinter.Invalidate;
  N := FPrinter.PageCount(FDevice);
  FPages.Items.BeginUpdate;
  try
    FPages.Items.Clear;
    for I := 1 to N do
      FPages.Items.Add(Format(PPGStr(@SPPGPreviewPage), [I, N]));
  finally
    FPages.Items.EndUpdate;
  end;
  FView.Setup(FPrinter, FDevice);
  GoToPage(0);
end;

procedure TPPGPrintPreviewForm.GoToPage(Index: Integer);
var
  N: Integer;
begin
  N := FPrinter.PageCount(FDevice);
  if Index >= N then
    Index := N - 1;
  if Index < 0 then
    Index := 0;
  FView.PageIndex := Index;
  if FPages.ItemIndex <> Index then
    FPages.ItemIndex := Index;
  if N = 0 then
    FPageLabel.Caption := ''
  else
    FPageLabel.Caption := Format(PPGStr(@SPPGPreviewPage), [Index + 1, N]);
end;

procedure TPPGPrintPreviewForm.NavClick(Sender: TObject);
var
  N: Integer;
begin
  N := FPrinter.PageCount(FDevice);
  case TComponent(Sender).Tag of
    -2: GoToPage(0);
    -1: GoToPage(FView.PageIndex - 1);
    1: GoToPage(FView.PageIndex + 1);
    2: GoToPage(N - 1);
    99: ModalResult := mrCancel;
  end;
end;

procedure TPPGPrintPreviewForm.PageListClick(Sender: TObject);
begin
  if FPages.ItemIndex >= 0 then
    GoToPage(FPages.ItemIndex);
end;

procedure TPPGPrintPreviewForm.ZoomChange(Sender: TObject);
const
  Zooms: array[0..6] of Integer = (0, -1, 50, 75, 100, 150, 200);
begin
  if (FZoomBox.ItemIndex >= 0) and (FZoomBox.ItemIndex <= High(Zooms)) then
    FView.Zoom := Zooms[FZoomBox.ItemIndex];
end;

procedure TPPGPrintPreviewForm.PrintClick(Sender: TObject);
begin
  FPrinter.Print;
  FPrinted := True;
  ModalResult := mrOk;
end;

procedure TPPGPrintPreviewForm.SetupClick(Sender: TObject);
begin
  if FPrinter.PageSetup then
    Refill;
end;

procedure TPPGPrintPreviewForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE:
      ModalResult := mrCancel;
    VK_NEXT:
      GoToPage(FView.PageIndex + 1);
    VK_PRIOR:
      GoToPage(FView.PageIndex - 1);
  else
    Exit;
  end;
  Key := 0;
end;

{ TPPGPageSetupForm }

constructor TPPGPageSetupForm.CreateFor(APrinter: TPPGGridPrinter);
var
  Y, I: Integer;
  L: TPPGLabel;
  B: TPPGButton;

  function Lbl(const ACaption: string; AX, AY: Integer): TPPGLabel;
  begin
    Result := TPPGLabel.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.SetBounds(AX, AY, S(160), S(22));
  end;

  function Chk(const ACaption: string; AChecked: Boolean): TPPGCheckBox;
  begin
    Result := TPPGCheckBox.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.Checked := AChecked;
    Result.SetBounds(S(16), Y, S(330), S(24));
    Inc(Y, S(28));
  end;

begin
  inherited CreateNew(nil);
  FPrinter := APrinter;
  Caption := PPGStr(@SPPGPageSetupTitle);
  BorderStyle := bsDialog;
  Position := poScreenCenter;
  ClientWidth := S(370);
  Font.Assign(Screen.MessageFont);
  TPPGTheme.ApplyToForm(Self);
  Y := S(14);
  FPortrait := TPPGRadioButton.Create(Self);
  FPortrait.Parent := Self;
  FPortrait.Caption := PPGStr(@SPPGPageSetupPortrait);
  FPortrait.SetBounds(S(16), Y, S(160), S(24));
  FLandscape := TPPGRadioButton.Create(Self);
  FLandscape.Parent := Self;
  FLandscape.Caption := PPGStr(@SPPGPageSetupLandscape);
  FLandscape.SetBounds(S(180), Y, S(170), S(24));
  FPortrait.Checked := APrinter.Orientation = poPortrait;
  FLandscape.Checked := APrinter.Orientation = poLandscape;
  Inc(Y, S(34));
  FFit := Chk(PPGStr(@SPPGPageSetupFit), APrinter.FitToPageWidth);
  FRepeat := Chk(PPGStr(@SPPGPageSetupRepeat), APrinter.RepeatHeader);
  FLines := Chk(PPGStr(@SPPGPageSetupGridLines), APrinter.PrintGridLines);
  FColors := Chk(PPGStr(@SPPGPageSetupColors), APrinter.PrintColors);
  Inc(Y, S(6));
  L := Lbl(PPGStr(@SPPGPageSetupMargins), S(16), Y);
  L.Width := S(330);
  Inc(Y, S(26));
  for I := 0 to 3 do
  begin
    FMargin[I] := TPPGSpinEdit.Create(Self);
    FMargin[I].Parent := Self;
    FMargin[I].MinValue := 0;
    FMargin[I].MaxValue := 100;
    FMargin[I].SetBounds(S(16) + I * S(86), Y, S(78), S(28));
  end;
  FMargin[0].Value := APrinter.Margins.Left;
  FMargin[1].Value := APrinter.Margins.Top;
  FMargin[2].Value := APrinter.Margins.Right;
  FMargin[3].Value := APrinter.Margins.Bottom;
  Inc(Y, S(40));
  Lbl(PPGStr(@SPPGPageSetupHeader), S(16), Y);
  Inc(Y, S(24));
  FHeader := TPPGEdit.Create(Self);
  FHeader.Parent := Self;
  FHeader.SetBounds(S(16), Y, S(338), S(28));
  FHeader.Text := APrinter.HeaderText;
  Inc(Y, S(36));
  Lbl(PPGStr(@SPPGPageSetupFooter), S(16), Y);
  Inc(Y, S(24));
  FFooter := TPPGEdit.Create(Self);
  FFooter.Parent := Self;
  FFooter.SetBounds(S(16), Y, S(338), S(28));
  FFooter.Text := APrinter.FooterText;
  Inc(Y, S(44));
  B := TPPGButton.Create(Self);
  B.Parent := Self;
  B.Caption := PPGStr(@SPPGDlgOK);
  B.ModalResult := mrOk;
  B.Default := True;
  B.SetBounds(S(370 - 16 - 200 - 8), Y, S(100), S(30));
  B := TPPGButton.Create(Self);
  B.Parent := Self;
  B.Caption := PPGStr(@SPPGDlgCancel);
  B.ModalResult := mrCancel;
  B.Cancel := True;
  B.SetBounds(S(370 - 16 - 100), Y, S(100), S(30));
  ClientHeight := Y + S(46);
end;

function TPPGPageSetupForm.S(V: Integer): Integer;
begin
  Result := MulDiv(V, Screen.PixelsPerInch, 96);
end;

procedure TPPGPageSetupForm.Apply;
begin
  if FLandscape.Checked then
    FPrinter.Orientation := poLandscape
  else
    FPrinter.Orientation := poPortrait;
  FPrinter.FitToPageWidth := FFit.Checked;
  FPrinter.RepeatHeader := FRepeat.Checked;
  FPrinter.PrintGridLines := FLines.Checked;
  FPrinter.PrintColors := FColors.Checked;
  FPrinter.Margins.Left := FMargin[0].Value;
  FPrinter.Margins.Top := FMargin[1].Value;
  FPrinter.Margins.Right := FMargin[2].Value;
  FPrinter.Margins.Bottom := FMargin[3].Value;
  FPrinter.HeaderText := FHeader.Text;
  FPrinter.FooterText := FFooter.Text;
  FPrinter.Invalidate;
end;

end.
