unit PPG.Print;

{ Gemeinsamer Druck-Weg (Phase 13e, in Phase 14a aus PPG.Grid.Print
  herausgeloest, damit Grid und Planer dieselbe Vorschau nutzen).

  - TPPGCustomPrinter: Titel, Kopf-/Fusszeile mit Platzhaltern
    [Seite]/[Page], [Seiten]/[Pages], [Datum]/[Date], [Titel]/[Title],
    Ausrichtung, Raender (mm), Drucker. Drucken, in eine Datei drucken (PDF),
    Vorschau und Seite einrichten. Nachfahren liefern nur Seitenzahl und
    Seiteninhalt (PageCount/RenderPage) und optional Ja/Nein-Optionen fuer
    den Dialog "Seite einrichten" (OptionCount ...).
  - Gezeichnet wird in Geraetepunkten des Druckers (bzw. eines Metafiles mit
    denselben Massen in der Vorschau).
  - TPPGPrintPreviewForm zeichnet nur sichtbare Seiten (Zwischenspeicher fuer
    wenige Seiten). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  System.Generics.Collections, Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.Printers,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Scroll, PPG.Panel, PPG.Button, PPG.Labels,
  PPG.ComboBox, PPG.ListBox, PPG.CheckBox, PPG.RadioButton, PPG.SpinEdit, PPG.Edit;

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

  TPPGCustomPrinter = class(TComponent)
  private
    FTitle: string;
    FHeaderText: string;
    FFooterText: string;
    FOrientation: TPrinterOrientation;
    FMargins: TPPGPrintMargins;
    FPrinterName: string;
    procedure SetMargins(const Value: TPPGPrintMargins);
    procedure MarginsChanged(Sender: TObject);
    procedure DoPrint(const APrinterName, AOutput: string);
  protected
    /// Fester Wert fuer [Datum] (Tests); 0 = heute.
    FDate: TDateTime;
    /// Bereich innerhalb der Raender (Geraetepunkte, Ursprung = bedruckbarer Bereich).
    function MarginRect(const Device: TPPGPrintDevice): TRect;
    /// Kopf-/Fusszeile zeichnen; liefert den Bereich dazwischen.
    function PaintHeaderFooter(DC: HDC; const Content: TRect; PageIndex, Pages: Integer;
      AFont, ABoldFont: TFont): TRect;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Layout neu berechnen (nach Aenderung der Daten).
    procedure Invalidate; virtual;
    /// Geraet des eingestellten Druckers (ohne Drucker: A4 600 dpi).
    function PrinterDevice: TPPGPrintDevice;
    /// Seiten fuer das Geraet (Vorgabe: der eingestellte Drucker).
    function PageCount: Integer; overload;
    function PageCount(const Device: TPPGPrintDevice): Integer; overload; virtual; abstract;
    /// Seite auf einen DC zeichnen (Ursprung = bedruckbarer Bereich).
    procedure RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice); virtual; abstract;
    /// Platzhalter ersetzen.
    function ExpandText(const S: string; PageNo, Pages: Integer): string;
    /// Drucken auf PrinterName ('' = Standarddrucker), ohne Dialog.
    procedure Print;
    /// Drucken in eine Datei (z.B. "Microsoft Print to PDF").
    procedure PrintToFile(const APrinterName, AFileName: string);
    /// Vorschau (modal); True = gedruckt.
    function Preview: Boolean;
    /// Seite einrichten (modal); True = uebernommen.
    function PageSetup: Boolean;
    { Ja/Nein-Optionen des Druckers fuer "Seite einrichten" }
    function OptionCount: Integer; virtual;
    function OptionCaption(Index: Integer): string; virtual;
    function GetOption(Index: Integer): Boolean; virtual;
    procedure SetOption(Index: Integer; Value: Boolean); virtual;
    // In den Endklassen published
    property Title: string read FTitle write FTitle;
    property HeaderText: string read FHeaderText write FHeaderText;
    /// '' = keine Fusszeile; Vorgabe "Seite [Seite] von [Seiten]" (Sprache).
    property FooterText: string read FFooterText write FFooterText;
    property Orientation: TPrinterOrientation read FOrientation write FOrientation default poPortrait;
    property Margins: TPPGPrintMargins read FMargins write SetMargins;
    /// '' = Standarddrucker.
    property PrinterName: string read FPrinterName write FPrinterName;
  end;

  /// Seitenansicht in der Vorschau (zeichnet nur sichtbare Seiten).
  TPPGPrintPreviewView = class(TPPGCustomScrollControl)
  private
    FPrinter: TPPGCustomPrinter;
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
    procedure Setup(APrinter: TPPGCustomPrinter; const ADevice: TPPGPrintDevice);
    /// Metafile einer Seite (zwischengespeichert, hoechstens 8 Seiten).
    function PageMetafile(Index: Integer): TMetafile;
    procedure ClearCache;
    function CachedPages: Integer;
    property PageIndex: Integer read FPageIndex write SetPageIndex;
    property Zoom: Integer read FZoom write SetZoom;
  end;

  TPPGPrintPreviewForm = class(TForm)
  private
    FPrinter: TPPGCustomPrinter;
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
    constructor CreateFor(APrinter: TPPGCustomPrinter); virtual;
    procedure GoToPage(Index: Integer);
    property View: TPPGPrintPreviewView read FView;
    property PageList: TPPGListBox read FPages;
    property Printed: Boolean read FPrinted;
  end;

  TPPGPageSetupForm = class(TForm)
  private
    FPrinter: TPPGCustomPrinter;
    FPortrait, FLandscape: TPPGRadioButton;
    FOptions: array of TPPGCheckBox;
    FMargin: array[0..3] of TPPGSpinEdit;
    FHeader, FFooter: TPPGEdit;
    function S(V: Integer): Integer;
  public
    constructor CreateFor(APrinter: TPPGCustomPrinter); virtual;
    /// Werte in den Drucker uebernehmen.
    procedure Apply;
  end;

/// Name des Druckers ('' = Standarddrucker); Fehler, wenn unbekannt.
function PPGResolvePrinterName(const Name: string): string;
/// DC (bzw. Informations-DC) fuer einen Drucker mit Ausrichtung.
function PPGCreatePrinterDC(const Name: string; Landscape, InfoOnly: Boolean): HDC;

implementation

uses
  System.Math, System.UITypes, PPG.Lang, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler,
  PPG.Theme, Winapi.WinSpool;

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

{ Drucker-Hilfen }

function PPGResolvePrinterName(const Name: string): string;
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

/// Ueber die Windows-API statt TPrinter.GetPrinter (dessen PChar-Fassung ist
/// veraltet, die string-Fassung gibt es in XE2 noch nicht).
function PPGCreatePrinterDC(const Name: string; Landscape, InfoOnly: Boolean): HDC;
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

{ TPPGCustomPrinter }

constructor TPPGCustomPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMargins := TPPGPrintMargins.Create;
  FMargins.OnChange := MarginsChanged;
  FFooterText := PPGStr(@SPPGPrintFooterDefault);
end;

destructor TPPGCustomPrinter.Destroy;
begin
  FreeAndNil(FMargins);
  inherited Destroy;
end;

procedure TPPGCustomPrinter.SetMargins(const Value: TPPGPrintMargins);
begin
  FMargins.Assign(Value);
end;

procedure TPPGCustomPrinter.MarginsChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TPPGCustomPrinter.Invalidate;
begin
end;

function TPPGCustomPrinter.OptionCount: Integer;
begin
  Result := 0;
end;

function TPPGCustomPrinter.OptionCaption(Index: Integer): string;
begin
  Result := '';
end;

function TPPGCustomPrinter.GetOption(Index: Integer): Boolean;
begin
  Result := False;
end;

procedure TPPGCustomPrinter.SetOption(Index: Integer; Value: Boolean);
begin
end;

function TPPGCustomPrinter.MarginRect(const Device: TPPGPrintDevice): TRect;
var
  ML, MT, MR, MB, PPI: Integer;
begin
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
  Result := Rect(ML, MT, MR, MB);
end;

function TPPGCustomPrinter.PaintHeaderFooter(DC: HDC; const Content: TRect; PageIndex,
  Pages: Integer; AFont, ABoldFont: TFont): TRect;
var
  TM: TTextMetric;
  Old: HGDIOBJ;
  TH: Integer;
  R: TRect;
  S: string;
begin
  Result := Content;
  Old := SelectObject(DC, AFont.Handle);
  GetTextMetrics(DC, TM);
  TH := TM.tmHeight;
  SetBkMode(DC, TRANSPARENT);
  SetTextColor(DC, 0);
  if FHeaderText <> '' then
  begin
    SelectObject(DC, ABoldFont.Handle);
    R := Rect(Content.Left, Content.Top, Content.Right, Content.Top + TH * 2);
    S := ExpandText(FHeaderText, PageIndex + 1, Pages);
    Winapi.Windows.DrawText(DC, PChar(S), Length(S), R,
      DT_SINGLELINE or DT_TOP or DT_NOPREFIX or DT_END_ELLIPSIS);
    Inc(Result.Top, TH * 2);
  end;
  if FFooterText <> '' then
  begin
    SelectObject(DC, AFont.Handle);
    R := Rect(Content.Left, Content.Bottom - TH * 2, Content.Right, Content.Bottom);
    S := ExpandText(FFooterText, PageIndex + 1, Pages);
    Winapi.Windows.DrawText(DC, PChar(S), Length(S), R,
      DT_SINGLELINE or DT_BOTTOM or DT_CENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
    Dec(Result.Bottom, TH * 2);
  end;
  SelectObject(DC, Old);
end;

function TPPGCustomPrinter.PrinterDevice: TPPGPrintDevice;
var
  DC: HDC;
begin
  Result := TPPGPrintDevice.A4(600, FOrientation = poLandscape);
  try
    if Printer.Printers.Count = 0 then
      Exit;
    // Informations-DC: nur Masse, kein Druckauftrag
    DC := PPGCreatePrinterDC(PPGResolvePrinterName(FPrinterName), FOrientation = poLandscape, True);
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

function TPPGCustomPrinter.PageCount: Integer;
begin
  Result := PageCount(PrinterDevice);
end;

function TPPGCustomPrinter.ExpandText(const S: string; PageNo, Pages: Integer): string;
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

procedure TPPGCustomPrinter.DoPrint(const APrinterName, AOutput: string);
var
  DC: HDC;
  DI: TDocInfo;
  Device: TPPGPrintDevice;
  I, N: Integer;
  DocName: string;
begin
  DC := PPGCreatePrinterDC(PPGResolvePrinterName(APrinterName), FOrientation = poLandscape, False);
  if DC = 0 then
    PPGRaiseLastOSError('CreateDC');
  try
    Device := TPPGPrintDevice.FromDC(DC);
    N := PageCount(Device);
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
      for I := 0 to N - 1 do
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

procedure TPPGCustomPrinter.Print;
begin
  DoPrint(FPrinterName, '');
end;

procedure TPPGCustomPrinter.PrintToFile(const APrinterName, AFileName: string);
begin
  DoPrint(APrinterName, AFileName);
end;

function TPPGCustomPrinter.Preview: Boolean;
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

function TPPGCustomPrinter.PageSetup: Boolean;
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

procedure TPPGPrintPreviewView.Setup(APrinter: TPPGCustomPrinter; const ADevice: TPPGPrintDevice);
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

constructor TPPGPrintPreviewForm.CreateFor(APrinter: TPPGCustomPrinter);
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

constructor TPPGPageSetupForm.CreateFor(APrinter: TPPGCustomPrinter);
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
  // Optionen des jeweiligen Druckers
  SetLength(FOptions, APrinter.OptionCount);
  for I := 0 to High(FOptions) do
  begin
    FOptions[I] := TPPGCheckBox.Create(Self);
    FOptions[I].Parent := Self;
    FOptions[I].Caption := APrinter.OptionCaption(I);
    FOptions[I].Checked := APrinter.GetOption(I);
    FOptions[I].SetBounds(S(16), Y, S(330), S(24));
    Inc(Y, S(28));
  end;
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
var
  I: Integer;
begin
  if FLandscape.Checked then
    FPrinter.Orientation := poLandscape
  else
    FPrinter.Orientation := poPortrait;
  for I := 0 to High(FOptions) do
    FPrinter.SetOption(I, FOptions[I].Checked);
  FPrinter.Margins.Left := FMargin[0].Value;
  FPrinter.Margins.Top := FMargin[1].Value;
  FPrinter.Margins.Right := FMargin[2].Value;
  FPrinter.Margins.Bottom := FMargin[3].Value;
  FPrinter.HeaderText := FHeader.Text;
  FPrinter.FooterText := FFooter.Text;
  FPrinter.Invalidate;
end;

end.
