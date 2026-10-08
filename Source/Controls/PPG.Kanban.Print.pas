unit PPG.Kanban.Print;

{ Drucken des Kanban-Boards ueber den gemeinsamen Druck-Weg
  (TPPGCustomPrinter: Vorschau, PDF, Seite einrichten).

  - Gezeichnet wird mit demselben Code wie auf dem Bildschirm: ein
    unsichtbares Board in Druckeraufloesung (ScalePPI = Drucker-PPI) mit den
    Spalten, Swimlanes, Karten, Stilen und Ereignissen des Boards, helle
    Farben, ohne Auswahl und Hover. Das Board wird so hoch, dass alle Karten
    ohne Scrollen Platz haben.
  - FitToPageWidth: alle Spalten auf die Seitenbreite verkleinern (kleinere
    Aufloesung); sonst werden zu breite Boards auf mehrere Seiten
    nebeneinander verteilt. Zu hohe Boards gehen auf Folgeseiten weiter. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Types, Vcl.Graphics,
  PPG.Print, PPG.Kanban;

type
  TPPGKanbanPrinter = class(TPPGCustomPrinter)
  private
    FKanban: TPPGCustomKanban;
    FFitToPageWidth: Boolean;
    procedure SetKanban(const Value: TPPGCustomKanban);
    function BodyRect(DC: HDC; const Device: TPPGPrintDevice; PageIndex, Pages: Integer;
      AFont, ABoldFont: TFont): TRect;
    procedure MakeFonts(const Device: TPPGPrintDevice; AFont, ABoldFont: TFont);
    /// Druck-Board fuer die Seitenflaeche W x H aufbauen; liefert die Zahl
    /// der Seiten neben- und untereinander.
    function Prepare(const Device: TPPGPrintDevice; W, H: Integer; out Cols, Rows: Integer): TObject;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function PageCount(const Device: TPPGPrintDevice): Integer; override;
    procedure RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice); override;
    function OptionCount: Integer; override;
    function OptionCaption(Index: Integer): string; override;
    function GetOption(Index: Integer): Boolean; override;
    procedure SetOption(Index: Integer; Value: Boolean); override;
  published
    property Kanban: TPPGCustomKanban read FKanban write SetKanban;
    /// Alle Spalten auf die Seitenbreite verkleinern.
    property FitToPageWidth: Boolean read FFitToPageWidth write FFitToPageWidth default True;
    property Title;
    property HeaderText;
    property FooterText;
    property Orientation;
    property Margins;
    property PrinterName;
  end;

implementation

uses
  System.Math, System.UITypes, Vcl.Controls, PPG.Lang, PPG.Consts,
  PPG.Controls.Scroll, PPG.Render.Intf, PPG.Render.Gdi;

type
  /// Unsichtbares Board in Druckeraufloesung.
  TPrintKanban = class(TPPGCustomKanban)
  private
    FPPI: Integer;
  public
    function ScalePPI: Integer; override;
    procedure RenderTo(const ACanvas: IPPGCanvas; const R: TRect);
  end;

function TPrintKanban.ScalePPI: Integer;
begin
  if FPPI > 0 then
    Result := FPPI
  else
    Result := inherited ScalePPI;
end;

procedure TPrintKanban.RenderTo(const ACanvas: IPPGCanvas; const R: TRect);
begin
  PaintViewport(ACanvas, R);
end;

function Acc(K: TPPGCustomKanban): TPrintKanban;
begin
  // Zugriff auf die geschuetzten Einstellungen (nur lesen)
  Result := TPrintKanban(K);
end;

{ TPPGKanbanPrinter }

constructor TPPGKanbanPrinter.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FFitToPageWidth := True;
end;

procedure TPPGKanbanPrinter.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FKanban) then
    FKanban := nil;
end;

procedure TPPGKanbanPrinter.SetKanban(const Value: TPPGCustomKanban);
begin
  if FKanban <> Value then
  begin
    if FKanban <> nil then
      FKanban.RemoveFreeNotification(Self);
    FKanban := Value;
    if FKanban <> nil then
      FKanban.FreeNotification(Self);
  end;
end;

function TPPGKanbanPrinter.OptionCount: Integer;
begin
  Result := 1;
end;

function TPPGKanbanPrinter.OptionCaption(Index: Integer): string;
begin
  Result := PPGStr(@SPPGKanbanPrintFitWidth);
end;

function TPPGKanbanPrinter.GetOption(Index: Integer): Boolean;
begin
  Result := FFitToPageWidth;
end;

procedure TPPGKanbanPrinter.SetOption(Index: Integer; Value: Boolean);
begin
  FFitToPageWidth := Value;
end;

procedure TPPGKanbanPrinter.MakeFonts(const Device: TPPGPrintDevice; AFont, ABoldFont: TFont);
begin
  AFont.Assign(Acc(FKanban).Font);
  AFont.Height := -MulDiv(Acc(FKanban).Font.Size, Device.PPI, 72);
  ABoldFont.Assign(AFont);
  ABoldFont.Style := ABoldFont.Style + [fsBold];
end;

function TPPGKanbanPrinter.BodyRect(DC: HDC; const Device: TPPGPrintDevice; PageIndex,
  Pages: Integer; AFont, ABoldFont: TFont): TRect;
begin
  Result := PaintHeaderFooter(DC, MarginRect(Device), PageIndex, Pages, AFont, ABoldFont);
end;

function TPPGKanbanPrinter.Prepare(const Device: TPPGPrintDevice; W, H: Integer;
  out Cols, Rows: Integer): TObject;
var
  K: TPrintKanban;
  Src: TPrintKanban;
  CW, BH: Integer;
begin
  Src := Acc(FKanban);
  K := TPrintKanban.Create(nil);
  try
    K.FPPI := Device.PPI;
    K.SetBounds(0, 0, W, H);
    K.HighContrastSupport := False;
    K.ScrollBarMode := sbmNever;
    K.Preset := Src.Preset;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    // Papier: helle Farben, weder Dark Mode noch VCL-Style
    K.StyleElements := K.StyleElements - [seClient];
    {$ENDIF}
    K.BiDiMode := Src.BiDiMode;
    K.Font.Assign(Src.Font);
    K.ColumnWidth := Src.ColumnWidth;
    K.CardGap := Src.CardGap;
    K.MaxTextLines := Src.MaxTextLines;
    K.VirtualCardHeight := Src.VirtualCardHeight;
    K.WipMode := Src.WipMode;
    K.ShowCardCount := Src.ShowCardCount;
    K.KanbanStyles := Src.KanbanStyles;
    K.OnCustomDrawCard := Src.OnCustomDrawCard;
    K.OnGetCard := Src.OnGetCard;
    K.Columns := Src.Columns;
    K.Lanes := Src.Lanes;
    K.Cards := Src.Cards;
    K.Font.Height := -MulDiv(Src.Font.Size, K.FPPI, 72);
    K.EnsureLayout;
    CW := K.ContentWidth;
    if FFitToPageWidth and (CW > W) and (CW > 0) then
    begin
      // Kleinere Aufloesung: Spalten, Abstaende und Schrift schrumpfen gleich
      K.FPPI := Max(24, MulDiv(Device.PPI, W, CW));
      K.Font.Height := -MulDiv(Src.Font.Size, K.FPPI, 72);
      K.EnsureLayout;
      CW := K.ContentWidth;
      // Gerundete Aufloesung: notfalls schrittweise weiter verkleinern
      while (CW > W) and (K.FPPI > 24) do
      begin
        K.FPPI := K.FPPI - 1;
        K.Font.Height := -MulDiv(Src.Font.Size, K.FPPI, 72);
        K.EnsureLayout;
        CW := K.ContentWidth;
      end;
    end;
    // Ganzes Board ohne Scrollen, nur so hoch wie noetig (ohne Swimlanes
    // reichen die Spalten sonst bis zum Seitenende)
    K.SetBounds(0, 0, Max(W, CW), H);
    BH := Max(1, K.BoardHeight);
    K.SetBounds(0, 0, Max(W, CW), BH);
    K.EnsureLayout;
    Cols := Max(1, (CW + W - 1) div W);
    Rows := Max(1, (BH + H - 1) div H);
    Result := K;
  except
    K.Free;
    raise;
  end;
end;

function TPPGKanbanPrinter.PageCount(const Device: TPPGPrintDevice): Integer;
var
  DC: HDC;
  F, FB: TFont;
  Body: TRect;
  K: TObject;
  Cols, Rows: Integer;
begin
  if FKanban = nil then
    Exit(0);
  F := TFont.Create;
  FB := TFont.Create;
  DC := CreateCompatibleDC(0);
  try
    MakeFonts(Device, F, FB);
    Body := BodyRect(DC, Device, 0, 1, F, FB);
    if (Body.Right <= Body.Left) or (Body.Bottom <= Body.Top) then
      Exit(1);
    K := Prepare(Device, Body.Right - Body.Left, Body.Bottom - Body.Top, Cols, Rows);
    K.Free;
    Result := Min(1000, Cols * Rows);
  finally
    DeleteDC(DC);
    FB.Free;
    F.Free;
  end;
end;

procedure TPPGKanbanPrinter.RenderPage(PageIndex: Integer; DC: HDC; const Device: TPPGPrintDevice);
var
  Body: TRect;
  F, FB: TFont;
  K: TPrintKanban;
  Canvas: IPPGCanvas;
  W, H, Cols, Rows, Pages, PX, PY: Integer;
begin
  Pages := PageCount(Device);
  if (FKanban = nil) or (PageIndex < 0) or (PageIndex >= Pages) then
    Exit;
  F := TFont.Create;
  FB := TFont.Create;
  K := nil;
  SaveDC(DC);
  try
    MakeFonts(Device, F, FB);
    Body := BodyRect(DC, Device, PageIndex, Pages, F, FB);
    W := Body.Right - Body.Left;
    H := Body.Bottom - Body.Top;
    if (W <= 0) or (H <= 0) then
      Exit;
    K := TPrintKanban(Prepare(Device, W, H, Cols, Rows));
    // Seiten erst nebeneinander, dann untereinander
    PX := PageIndex mod Cols;
    PY := PageIndex div Cols;
    SetViewportOrgEx(DC, Body.Left - PX * W, Body.Top - PY * H, nil);
    IntersectClipRect(DC, PX * W, PY * H, PX * W + W, PY * H + H);
    Canvas := TPPGGdiCanvas.Create(DC);
    K.RenderTo(Canvas, Rect(0, 0, K.Width, K.Height));
    Canvas := nil;
  finally
    RestoreDC(DC, -1);
    K.Free;
    FB.Free;
    F.Free;
  end;
end;

end.
