unit PPG.TabStrip;

{ TPPGTabStrip - Reiterleiste fuer TabControl und PageControl (Komposition,
  kein Control: das besitzende Control fuettert die Reiter, ruft Layout auf
  und zeichnet ueber Paint).

  - Geometrie: Breite aus Text, Bild und Schliessen-Knopf (oder fest per
    TabWidth), Hoehe aus der Schrift (oder TabHeight); RTL wird gespiegelt.
  - Ueberlauf: reichen die Reiter nicht, erscheinen rechts zwei Blaetterpfeile;
    mit MultiLine stattdessen mehrere Reihen (die Reihe des gewaehlten Reiters
    liegt an der Seite, wie bei Windows; ohne RaggedRight fuellen die Reiter
    jede Reihe).
  - Darstellung (ButtonStyle): Reiter, Knoepfe oder flache Knoepfe (wie
    TTabControl.Style).
  - Element-Stile (TPPGTabStyles), Farben je Reiter und eigenes Zeichnen ueber
    OnDrawTab des Besitzers.
  - Senkrecht (Vertical, TabPosition tpLeft/tpRight): Reiter untereinander,
    Breite = breitester Reiter, Indikator an der Seitenkante, Pfeile hoch/runter.
  - ScrollOpposite (MultiLine): Reihen zwischen gewaehltem Reiter und Seite
    liegen auf der Gegenseite (OppositeRect), wie bei TPageControl.
  - Hit-Test fuer Reiter, Schliessen-Knopf und Pfeile, Hover-Zustand.
  - Unterstrich (Indikator) gleitet beim Wechsel ueber den gemeinsamen
    Animator von der alten zur neuen Position.
  - Zeichnet nur ueber IPPGTabRenderer; Paint sendet keine Nachrichten. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Graphics, Vcl.ImgList,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.ElementStyle, PPG.CustomDraw;

type
  TPPGTabInfo = record
    Caption: string;
    ImageIndex: Integer;
    Enabled: Boolean;
    Index: Integer; // Index beim Besitzer (Tabs-Eintrag bzw. Seite)
    // Anpassbarkeit: eigene Farben/Schrift des Reiters (clDefault = Stil)
    Color: TColor;
    TextColor: TColor;
    FontStyle: TFontStyles;
    Highlighted: Boolean; // TTabSheet.Highlighted: wie unter der Maus
  end;

  /// Darstellung der Reiter (wie Vcl.ComCtrls.TTabStyle).
  TPPGTabButtonStyle = (tbsTabs, tbsButtons, tbsFlatButtons);

  /// Eigenes Zeichnen eines Reiters (Pos = Position in der Leiste).
  TPPGTabDrawProc = procedure(Pos: Integer; const ACanvas: IPPGCanvas; const R: TRect;
    Active: Boolean; var Style: TPPGDrawStyle; var DefaultDraw: Boolean) of object;

  /// Inhalt eines Reiters selbst zeichnen (Hintergrund ist gezeichnet); True =
  /// gezeichnet, die Leiste zeichnet dann keinen Text/Bild.
  TPPGTabContentProc = function(Pos: Integer; const ACanvas: IPPGCanvas; const R: TRect;
    Active: Boolean): Boolean of object;

  /// Bereiche der Reiterleiste. Nur gesetzte Werte zaehlen (clDefault = Preset).
  TPPGTabStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Nicht gewaehlte Reiter (Color, TextColor, BorderColor, Schrift).
    property Tab: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Reiter unter der Maus.
    property HotTab: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Gewaehlter Reiter.
    property ActiveTab: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Flaeche hinter den Reitern (Color).
    property Strip: TPPGElementStyle index 3 read GetItem write SetItem;
    /// Unterstrich des gewaehlten Reiters (Color).
    property Indicator: TPPGElementStyle index 4 read GetItem write SetItem;
  end;

  TPPGTabHit = (thNone, thTab, thClose, thPrev, thNext);

  /// Farben und Zustaende zum Zeichnen (berechnet das besitzende Control).
  TPPGTabPaintInfo = record
    Strip: TPPGSurfaceStyle;     // Leiste (Color = clNone: nichts zeichnen)
    Tab: TPPGSurfaceStyle;       // nicht gewaehlter Reiter
    HotTab: TPPGSurfaceStyle;    // Reiter unter der Maus
    Selected: TPPGSurfaceStyle;  // gewaehlter Reiter (Seitenfarben)
    Accent: TColor;              // Unterstrich
    DisabledText: TColor;
    Overlap: Integer;            // Rahmenbreite der Seite (gewaehlter Reiter ragt hinein)
    HotTrack: Boolean;
    Focused: Boolean;            // Fokusrahmen um den gewaehlten Reiter
    ShowAccel: Boolean;          // &-Unterstriche sichtbar
    Enabled: Boolean;
    // Anpassbarkeit (Styles darf nil sein)
    Styles: TPPGTabStyles;
    UseColors: Boolean;
    Dark: Boolean;
    OnDrawTab: TPPGTabDrawProc;
    // Inhalt selbst gezeichnet (OwnerDraw/OnDrawTab des Besitzers)? True = ja
    OnDrawContent: TPPGTabContentProc;
  end;

  TPPGTabStrip = class
  private
    FTabs: array of TPPGTabInfo;
    FRects: array of TRect;
    FCloseRects: array of TRect;
    FStrip: TRect;
    FTabArea: TRect;
    FPrevRect: TRect;
    FNextRect: TRect;
    FOverflow: Boolean;
    FFirst: Integer;
    FMaxFirst: Integer;
    FSelected: Integer;
    FHot: Integer;
    FHotClose: Integer;
    FHotArrow: TPPGTabHit;
    FFont: TFont;
    FImages: TCustomImageList;
    FPPI: Integer;
    FTabWidth: Integer;
    FTabHeight: Integer;
    FShowClose: Boolean;
    FBottom: Boolean;
    FRightToLeft: Boolean;
    FIndicatorAnim: TPPGAnimation;
    FIndicatorFrom: TRect;
    FOnChange: TNotifyEvent;
    FMultiLine: Boolean;
    FRaggedRight: Boolean;
    FButtonStyle: TPPGTabButtonStyle;
    FAvailWidth: Integer;
    FRowCount: Integer;
    FFonts: TPPGFontCache;
    FVertical: Boolean;
    FScrollOpposite: Boolean;
    FOppRect: TRect;
    FOppRow: array of Boolean;
    // Audit 8D: Textbreite je Reiter (-1 = noch nicht gemessen), gueltig fuer
    // die gemerkte Schrift
    FTextW: array of Integer;
    FWFont: TFont;
    FWName: string;
    FWHeight: Integer;
    FWStyle: TFontStyles;
    FWCharset: TFontCharset;
    FWQuality: TFontQuality;
    FDirty: TRect;
    function TextWidthAt(Pos: Integer): Integer;
    function HotPartRect(Pos, Close: Integer; Arrow: TPPGTabHit): TRect;
    procedure LayoutVertical(const StripRect: TRect);
    function SelectedRow(const Starts: TArray<Integer>; RowsN: Integer): Integer;
    /// Reihen fuer MultiLine: Startposition je Reihe (Reihenfolge der Reiter).
    function PackRows(Avail: Integer; out Starts: TArray<Integer>): Integer;
    procedure LayoutMultiLine(const StripRect: TRect);
    procedure AnimStep(Sender: TObject);
    procedure Changed;
    function Scale(Value: Integer): Integer;
    function TabWidthAt(Pos: Integer): Integer;
    function IndicatorFor(Pos: Integer): TRect;
    function Mirror(const R: TRect): TRect;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Add(const Caption: string; ImageIndex: Integer; Enabled: Boolean;
      OwnerIndex: Integer);
    /// Eigene Farben/Schrift des zuletzt bzw. an Pos eingetragenen Reiters.
    procedure SetTabStyle(Pos: Integer; AColor, ATextColor: TColor; AFontStyle: TFontStyles);
    procedure SetTabHighlighted(Pos: Integer; Value: Boolean);
    /// Anzahl Reihen nach dem letzten Layout (1 ohne MultiLine).
    property RowCount: Integer read FRowCount;
    function Count: Integer;
    function Tab(Pos: Integer): TPPGTabInfo;
    /// Position eines Besitzer-Index in der Leiste, -1 = nicht vorhanden.
    function PosOf(OwnerIndex: Integer): Integer;
    /// Hoehe der Leiste in px (Reiter + Abstand zum Rand).
    function StripHeight: Integer;
    /// Hoehe eines Reiters (eine Reihe) in px.
    function TabRowHeight: Integer;
    /// Senkrecht: Breite der Leiste (breitester Reiter + Abstand).
    function StripWidth: Integer;
    /// ScrollOpposite: Reihen auf der Gegenseite bzw. deren Hoehe (0 = keine).
    function OppositeRows: Integer;
    function OppositeHeight: Integer;
    /// Berechnet alle Rechtecke (Client-Koordinaten des Besitzers).
    procedure Layout(const StripRect: TRect);
    function HitTest(X, Y: Integer; out OwnerIndex: Integer): TPPGTabHit;
    /// Rechteck eines Reiters (Position), leer = nicht sichtbar.
    function TabRectAt(Pos: Integer): TRect;
    function CloseRectAt(Pos: Integer): TRect;
    /// Waehlt einen Reiter (Besitzer-Index); Animate laesst den Unterstrich gleiten.
    procedure Select(OwnerIndex: Integer; Animate: Boolean; DurationMs: Cardinal);
    procedure MakeVisible(Pos: Integer);
    function CanScroll(Delta: Integer): Boolean;
    procedure Scroll(Delta: Integer);
    /// Hover aktualisieren; True, wenn sich etwas geaendert hat.
    function UpdateHot(X, Y: Integer): Boolean;
    function ClearHot: Boolean;
    /// Aktuelle Lage des Unterstrichs (waehrend der Animation interpoliert).
    function IndicatorRect: TRect;
    function IndicatorMoving: Boolean;
    procedure Paint(const Canvas: IPPGCanvas; const Renderer: IPPGTabRenderer;
      const Info: TPPGTabPaintInfo);
    property Font: TFont read FFont write FFont;
    property Images: TCustomImageList read FImages write FImages;
    property PPI: Integer read FPPI write FPPI;
    property TabWidth: Integer read FTabWidth write FTabWidth;
    property TabHeight: Integer read FTabHeight write FTabHeight;
    property ShowClose: Boolean read FShowClose write FShowClose;
    property Bottom: Boolean read FBottom write FBottom;
    property RightToLeft: Boolean read FRightToLeft write FRightToLeft;
    property MultiLine: Boolean read FMultiLine write FMultiLine;
    property RaggedRight: Boolean read FRaggedRight write FRaggedRight;
    property ButtonStyle: TPPGTabButtonStyle read FButtonStyle write FButtonStyle;
    /// Reiter untereinander (tpLeft/tpRight); Bottom = Leiste rechts.
    property Vertical: Boolean read FVertical write FVertical;
    property ScrollOpposite: Boolean read FScrollOpposite write FScrollOpposite;
    /// Bereich fuer die Reihen auf der Gegenseite (setzt der Besitzer vor dem Layout).
    property OppositeRect: TRect read FOppRect write FOppRect;
    /// Breite fuer StripHeight mit MultiLine (setzt der Besitzer vor dem Layout).
    property AvailWidth: Integer read FAvailWidth write FAvailWidth;
    property Overflow: Boolean read FOverflow;
    property FirstVisible: Integer read FFirst;
    property Selected: Integer read FSelected;
    property HotTab: Integer read FHot;
    property HotClose: Integer read FHotClose;
    property PrevRect: TRect read FPrevRect;
    property NextRect: TRect read FNextRect;
    property StripRect: TRect read FStrip;
    /// Bereich, der sich bei der letzten Meldung (OnChange, UpdateHot, ClearHot)
    /// geaendert hat; leer = alles neu zeichnen.
    property DirtyRect: TRect read FDirty;
    /// Neu zeichnen (Animation, Hover).
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  System.SysUtils, System.UITypes, System.Math, PPG.Appearance, PPG.Accessibility, PPG.Render.Gdi;

const
  TabPadX = 12;     // logische px links/rechts im Reiter
  TabPadY = 7;      // logische px ueber/unter dem Text
  StripPad = 4;     // logische px Abstand der Reiter zum aeusseren Rand
  TabGap = 2;       // logische px zwischen Reitern
  CloseSize = 16;   // logische px Schliessen-Knopf
  ImageGap = 6;     // logische px zwischen Bild und Text
  IndicatorH = 3;   // logische px Hoehe des Unterstrichs
  IndicatorInset = 10;

function JoinRect(const A, B: TRect): TRect;
begin
  // Huelle zweier Rechtecke; ein leeres zaehlt nicht
  if IsRectEmpty(A) then
    Exit(B);
  if IsRectEmpty(B) then
    Exit(A);
  Result := Rect(Min(A.Left, B.Left), Min(A.Top, B.Top), Max(A.Right, B.Right),
    Max(A.Bottom, B.Bottom));
end;

function LerpRect(const A, B: TRect; T: Single): TRect;
begin
  Result.Left := A.Left + Round((B.Left - A.Left) * T);
  Result.Top := A.Top + Round((B.Top - A.Top) * T);
  Result.Right := A.Right + Round((B.Right - A.Right) * T);
  Result.Bottom := A.Bottom + Round((B.Bottom - A.Bottom) * T);
end;

{ TPPGTabStyles }

constructor TPPGTabStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 5);
end;

{ TPPGTabStrip }

constructor TPPGTabStrip.Create;
begin
  inherited Create;
  FSelected := -1;
  FHot := -1;
  FHotClose := -1;
  FPPI := 96;
  FIndicatorAnim := TPPGAnimation.Create(Self);
  FIndicatorAnim.OnStep := AnimStep;
  FIndicatorAnim.Jump(1);
  FRowCount := 1;
  FFonts := TPPGFontCache.Create;
end;

destructor TPPGTabStrip.Destroy;
begin
  if FIndicatorAnim <> nil then
    FIndicatorAnim.OnStep := nil;
  FreeAndNil(FIndicatorAnim); // meldet sich selbst beim Animator ab
  FreeAndNil(FFonts);
  inherited Destroy;
end;

procedure TPPGTabStrip.AnimStep(Sender: TObject);
var
  Target: TRect;
begin
  // Audit 8D: Der Unterstrich gleitet zwischen alter und neuer Lage - nur
  // diesen Bereich neu zeichnen (die Reiter selbst aendern sich nicht)
  Target := IndicatorFor(FSelected);
  if IsRectEmpty(FIndicatorFrom) or IsRectEmpty(Target) then
    FDirty := Rect(0, 0, 0, 0)
  else
  begin
    FDirty := JoinRect(FIndicatorFrom, Target);
    InflateRect(FDirty, Scale(2), Scale(2));
  end;
  Changed;
  FDirty := Rect(0, 0, 0, 0);
end;

procedure TPPGTabStrip.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TPPGTabStrip.Scale(Value: Integer): Integer;
begin
  Result := PPGScale(Value, FPPI);
end;

procedure TPPGTabStrip.Clear;
begin
  SetLength(FTabs, 0);
  SetLength(FTextW, 0);
  SetLength(FRects, 0);
  SetLength(FCloseRects, 0);
  FSelected := -1;
  FHot := -1;
  FHotClose := -1;
end;

procedure TPPGTabStrip.Add(const Caption: string; ImageIndex: Integer; Enabled: Boolean;
  OwnerIndex: Integer);
var
  N: Integer;
begin
  N := Length(FTabs);
  SetLength(FTabs, N + 1);
  SetLength(FTextW, N + 1);
  FTextW[N] := -1;
  FTabs[N].Caption := Caption;
  FTabs[N].ImageIndex := ImageIndex;
  FTabs[N].Enabled := Enabled;
  FTabs[N].Index := OwnerIndex;
  FTabs[N].Color := clDefault;
  FTabs[N].TextColor := clDefault;
  FTabs[N].FontStyle := [];
  FTabs[N].Highlighted := False;
end;

procedure TPPGTabStrip.SetTabHighlighted(Pos: Integer; Value: Boolean);
begin
  if (Pos >= 0) and (Pos <= High(FTabs)) then
    FTabs[Pos].Highlighted := Value;
end;

procedure TPPGTabStrip.SetTabStyle(Pos: Integer; AColor, ATextColor: TColor;
  AFontStyle: TFontStyles);
begin
  if (Pos < 0) or (Pos > High(FTabs)) then
    Exit;
  FTabs[Pos].Color := AColor;
  FTabs[Pos].TextColor := ATextColor;
  FTabs[Pos].FontStyle := AFontStyle;
end;

function TPPGTabStrip.Count: Integer;
begin
  Result := Length(FTabs);
end;

function TPPGTabStrip.Tab(Pos: Integer): TPPGTabInfo;
begin
  Result := FTabs[Pos];
end;

function TPPGTabStrip.PosOf(OwnerIndex: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(FTabs) do
    if FTabs[I].Index = OwnerIndex then
      Exit(I);
end;

function TPPGTabStrip.TabRowHeight: Integer;
var
  H: Integer;
begin
  if FTabHeight > 0 then
    H := Scale(FTabHeight)
  else
  begin
    if FFont <> nil then
      H := PPGMeasureTextNoCanvas('Wg', FFont, 0, False).cy
    else
      H := Scale(15);
    H := H + 2 * Scale(TabPadY);
    if (FImages <> nil) and (FImages.Height + 2 * Scale(4) > H) then
      H := FImages.Height + 2 * Scale(4);
  end;
  Result := H;
end;

function TPPGTabStrip.StripHeight: Integer;
var
  H: Integer;
  Starts: TArray<Integer>;
begin
  H := TabRowHeight;
  Result := H + Scale(StripPad);
  // MultiLine: so viele Reihen, wie die Reiter bei AvailWidth brauchen (ohne
  // die Reihen auf der Gegenseite)
  if FMultiLine and not FVertical and (FAvailWidth > 0) and (Length(FTabs) > 0) then
    Result := Result + (PackRows(FAvailWidth - 2 * Scale(StripPad), Starts) - 1 - OppositeRows) * H;
end;

function TPPGTabStrip.StripWidth: Integer;
var
  I, W: Integer;
begin
  W := Scale(40);
  for I := 0 to High(FTabs) do
    if TabWidthAt(I) > W then
      W := TabWidthAt(I);
  Result := W + Scale(StripPad);
end;

function TPPGTabStrip.SelectedRow(const Starts: TArray<Integer>; RowsN: Integer): Integer;
var
  I: Integer;
begin
  Result := RowsN - 1;
  if FSelected < 0 then
    Exit;
  for I := 0 to RowsN - 1 do
    if (FSelected >= Starts[I]) and ((I = RowsN - 1) or (FSelected < Starts[I + 1])) then
      Exit(I);
end;

function TPPGTabStrip.OppositeRows: Integer;
var
  Starts: TArray<Integer>;
  RowsN: Integer;
begin
  Result := 0;
  if not FScrollOpposite or not FMultiLine or FVertical or (FAvailWidth <= 0) or
    (Length(FTabs) = 0) then
    Exit;
  RowsN := PackRows(FAvailWidth - 2 * Scale(StripPad), Starts);
  // Reihen hinter der gewaehlten (zwischen ihr und der Seite) wechseln die Seite
  Result := RowsN - 1 - SelectedRow(Starts, RowsN);
end;

function TPPGTabStrip.OppositeHeight: Integer;
var
  N: Integer;
begin
  N := OppositeRows;
  if N = 0 then
    Result := 0
  else
    Result := N * TabRowHeight + Scale(StripPad);
end;

function TPPGTabStrip.TextWidthAt(Pos: Integer): Integer;
var
  I: Integer;
  S: string;
begin
  // Audit 8D: Textbreiten merken (Layout, StripHeight, PackRows und
  // MakeVisible fragen sie mehrfach je Aenderung ab)
  if FFont = nil then
    Exit(0);
  if (FWFont <> FFont) or (FWHeight <> FFont.Height) or (FWStyle <> FFont.Style) or
    (FWCharset <> FFont.Charset) or (FWQuality <> FFont.Quality) or (FWName <> FFont.Name) then
  begin
    FWFont := FFont;
    FWName := FFont.Name;
    FWHeight := FFont.Height;
    FWStyle := FFont.Style;
    FWCharset := FFont.Charset;
    FWQuality := FFont.Quality;
    for I := 0 to High(FTextW) do
      FTextW[I] := -1;
  end;
  if Length(FTextW) <> Length(FTabs) then
  begin
    SetLength(FTextW, Length(FTabs));
    for I := 0 to High(FTextW) do
      FTextW[I] := -1;
  end;
  if FTextW[Pos] < 0 then
  begin
    S := PPGAccStripHotkey(FTabs[Pos].Caption);
    if S <> '' then
      FTextW[Pos] := PPGMeasureTextNoCanvas(S, FFont, 0, False).cx
    else
      FTextW[Pos] := 0;
  end;
  Result := FTextW[Pos];
end;

function TPPGTabStrip.TabWidthAt(Pos: Integer): Integer;
begin
  if FTabWidth > 0 then
    Exit(Scale(FTabWidth));
  Result := TextWidthAt(Pos);
  Inc(Result, 2 * Scale(TabPadX));
  if (FImages <> nil) and (FTabs[Pos].ImageIndex >= 0) then
    Inc(Result, FImages.Width + Scale(ImageGap));
  if FShowClose then
    Inc(Result, Scale(CloseSize) + Scale(4));
  if Result < Scale(40) then
    Result := Scale(40);
end;

function TPPGTabStrip.PackRows(Avail: Integer; out Starts: TArray<Integer>): Integer;
var
  I, X, W: Integer;
begin
  // Reiter der Reihe nach auffuellen; jede Reihe hat mindestens einen Reiter
  SetLength(Starts, 0);
  Result := 0;
  X := 0;
  for I := 0 to High(FTabs) do
  begin
    W := TabWidthAt(I);
    if (Result = 0) or ((X > 0) and (X + Scale(TabGap) + W > Avail)) then
    begin
      SetLength(Starts, Result + 1);
      Starts[Result] := I;
      Inc(Result);
      X := W;
    end
    else
      Inc(X, Scale(TabGap) + W);
  end;
  if Result = 0 then
    Result := 1;
end;

function TPPGTabStrip.Mirror(const R: TRect): TRect;
begin
  if IsRectEmpty(R) then
    Exit(R);
  Result := Rect(FStrip.Left + FStrip.Right - R.Right, R.Top,
    FStrip.Left + FStrip.Right - R.Left, R.Bottom);
end;

procedure TPPGTabStrip.LayoutMultiLine(const StripRect: TRect);
var
  N, I, J, X, TabH, Left0, Right0, RowsN, R0, R1, RowSel, Slot, Extra, Sum, CS, Opp: Integer;
  Starts: TArray<Integer>;
  W: array of Integer;
  Order: array of Integer;
  R: TRect;
begin
  N := Length(FTabs);
  Left0 := StripRect.Left + Scale(StripPad);
  Right0 := StripRect.Right - Scale(StripPad);
  RowsN := PackRows(Right0 - Left0, Starts);
  FRowCount := RowsN;
  TabH := (StripRect.Bottom - StripRect.Top - Scale(StripPad)) div RowsN;
  if TabH < 1 then
    TabH := 1;
  SetLength(W, N);
  for I := 0 to N - 1 do
    W[I] := TabWidthAt(I);
  Opp := 0;
  if FScrollOpposite then
  begin
    // Reihen 0..gewaehlte bleiben (gewaehlte an der Seite), der Rest geht auf die
    // Gegenseite; die Reihenhoehe kommt aus der eigenen Reihenzahl
    Opp := RowsN - 1 - SelectedRow(Starts, RowsN);
    TabH := (StripRect.Bottom - StripRect.Top - Scale(StripPad)) div (RowsN - Opp);
    if TabH < 1 then
      TabH := 1;
  end;
  // Reihe des gewaehlten Reiters liegt an der Seite (unten bzw. bei Reitern
  // unten oben); die uebrigen Reihen behalten ihre Reihenfolge
  RowSel := RowsN - 1;
  for I := 0 to RowsN - 1 do
    if (FSelected >= Starts[I]) and ((I = RowsN - 1) or (FSelected < Starts[I + 1])) then
      RowSel := I;
  SetLength(Order, RowsN);
  J := 0;
  for I := 0 to RowsN - 1 do
    if I <> RowSel then
    begin
      Order[J] := I;
      Inc(J);
    end;
  Order[RowsN - 1] := RowSel;
  if Opp > 0 then
    for I := 0 to RowsN - 1 do
      Order[I] := I;
  CS := Scale(CloseSize);
  for Slot := 0 to RowsN - 1 do
  begin
    I := Order[Slot];
    R0 := Starts[I];
    if I = RowsN - 1 then
      R1 := N - 1
    else
      R1 := Starts[I + 1] - 1;
    // Ohne RaggedRight fuellt jede Reihe die ganze Breite (mehrere Reihen)
    Extra := 0;
    if not FRaggedRight and (RowsN > 1) then
    begin
      Sum := 0;
      for J := R0 to R1 do
        Inc(Sum, W[J]);
      Inc(Sum, (R1 - R0) * Scale(TabGap));
      Extra := (Right0 - Left0) - Sum;
      if Extra < 0 then
        Extra := 0;
    end;
    X := Left0;
    for J := R0 to R1 do
    begin
      FOppRow[J] := (Opp > 0) and (I > RowsN - 1 - Opp);
      if FOppRow[J] then
      begin
        // Gegenseite: Reihe direkt hinter der gewaehlten liegt an der Seite
        if FBottom then
          R.Top := FOppRect.Bottom - (I - (RowsN - 1 - Opp)) * TabH
        else
          R.Top := FOppRect.Top + (I - (RowsN - Opp)) * TabH;
      end
      else if Opp > 0 then
      begin
        if FBottom then
          R.Top := StripRect.Top + (RowsN - 1 - Opp - I) * TabH
        else
          R.Top := StripRect.Top + Scale(StripPad) + I * TabH;
      end
      else if FBottom then
        R.Top := StripRect.Top + (RowsN - 1 - Slot) * TabH
      else
        R.Top := StripRect.Top + Scale(StripPad) + Slot * TabH;
      R.Bottom := R.Top + TabH;
      R.Left := X;
      if Extra > 0 then
        R.Right := X + W[J] + Extra div (R1 - R0 + 1) +
          Ord(J - R0 < Extra mod (R1 - R0 + 1))
      else
        R.Right := X + W[J];
      if R.Right > Right0 then
        R.Right := Right0;
      X := R.Right + Scale(TabGap);
      FRects[J] := R;
      if FShowClose then
        FCloseRects[J] := Rect(R.Right - Scale(TabPadX) div 2 - CS,
          (R.Top + R.Bottom - CS) div 2, R.Right - Scale(TabPadX) div 2,
          (R.Top + R.Bottom + CS) div 2)
      else
        FCloseRects[J] := Rect(0, 0, 0, 0);
    end;
  end;
  FOverflow := False;
  FFirst := 0;
  FMaxFirst := 0;
  FPrevRect := Rect(0, 0, 0, 0);
  FNextRect := Rect(0, 0, 0, 0);
  FTabArea := Rect(Left0, StripRect.Top, Right0, StripRect.Bottom);
  if Opp > 0 then
  begin
    // Reiter auf beiden Seiten: Zeichenbereich ueber alles
    if FOppRect.Top < FTabArea.Top then
      FTabArea.Top := FOppRect.Top;
    if FOppRect.Bottom > FTabArea.Bottom then
      FTabArea.Bottom := FOppRect.Bottom;
  end;
  if FRightToLeft then
  begin
    for I := 0 to N - 1 do
    begin
      FRects[I] := Mirror(FRects[I]);
      FCloseRects[I] := Mirror(FCloseRects[I]);
    end;
    FTabArea := Mirror(FTabArea);
  end;
end;

procedure TPPGTabStrip.LayoutVertical(const StripRect: TRect);
var
  N, I, Y, TabH, Gap, Pad, X0, X1, Top0, Bottom0, ArrowH, K, CS: Integer;
  R: TRect;
begin
  N := Length(FTabs);
  TabH := TabRowHeight;
  Gap := Scale(TabGap);
  Pad := Scale(StripPad);
  // Abstand nur zur Aussenkante; zur Seite hin beruehren die Reiter die Seite
  if FBottom then
  begin
    X0 := StripRect.Left;
    X1 := StripRect.Right - Pad;
  end
  else
  begin
    X0 := StripRect.Left + Pad;
    X1 := StripRect.Right;
  end;
  Top0 := StripRect.Top + Pad;
  Bottom0 := StripRect.Bottom - Pad;
  FPrevRect := Rect(0, 0, 0, 0);
  FNextRect := Rect(0, 0, 0, 0);
  FOverflow := (N > 0) and (N * TabH + (N - 1) * Gap > Bottom0 - Top0);
  if FOverflow then
  begin
    // Pfeile hoch/runter unten nebeneinander
    ArrowH := TabH * 4 div 5;
    FPrevRect := Rect(X0, Bottom0 - ArrowH, (X0 + X1) div 2, Bottom0);
    FNextRect := Rect((X0 + X1) div 2, Bottom0 - ArrowH, X1, Bottom0);
    Bottom0 := FPrevRect.Top - Gap;
    K := (Bottom0 - Top0 + Gap) div (TabH + Gap);
    if K < 1 then
      K := 1;
    FMaxFirst := N - K;
    if FMaxFirst < 0 then
      FMaxFirst := 0;
  end
  else
    FMaxFirst := 0;
  if FFirst > FMaxFirst then
    FFirst := FMaxFirst;
  if FFirst < 0 then
    FFirst := 0;
  FTabArea := Rect(StripRect.Left, Top0, StripRect.Right, Bottom0);
  CS := Scale(CloseSize);
  Y := Top0;
  for I := 0 to N - 1 do
  begin
    FRects[I] := Rect(0, 0, 0, 0);
    FCloseRects[I] := Rect(0, 0, 0, 0);
    if I < FFirst then
      Continue;
    R := Rect(X0, Y, X1, Y + TabH);
    Inc(Y, TabH + Gap);
    // nur ganz sichtbare Reiter (kein Anschneiden in der Hoehe)
    if R.Bottom > Bottom0 then
      Continue;
    FRects[I] := R;
    if FShowClose then
      FCloseRects[I] := Rect(R.Right - Scale(TabPadX) div 2 - CS, (R.Top + R.Bottom - CS) div 2,
        R.Right - Scale(TabPadX) div 2, (R.Top + R.Bottom + CS) div 2);
  end;
end;

procedure TPPGTabStrip.Layout(const StripRect: TRect);
var
  N, I, X, Y0, TabH, Left0, Right0, Total, ArrowW, Avail, Sum, CS: Integer;
  W: array of Integer;
  R: TRect;
begin
  FStrip := StripRect;
  N := Length(FTabs);
  SetLength(FRects, N);
  SetLength(FCloseRects, N);
  SetLength(FOppRow, N);
  for I := 0 to N - 1 do
    FOppRow[I] := False;
  SetLength(W, N);
  FRowCount := 1;
  if FVertical then
  begin
    LayoutVertical(StripRect);
    if FHot > N - 1 then
      FHot := -1;
    if FHotClose > N - 1 then
      FHotClose := -1;
    if FSelected > N - 1 then
      FSelected := -1;
    Exit;
  end;
  if FMultiLine and (N > 0) then
  begin
    LayoutMultiLine(StripRect);
    if FHot > N - 1 then
      FHot := -1;
    if FHotClose > N - 1 then
      FHotClose := -1;
    if FSelected > N - 1 then
      FSelected := -1;
    Exit;
  end;
  TabH := StripHeight - Scale(StripPad);
  if FBottom then
    Y0 := StripRect.Top
  else
    Y0 := StripRect.Bottom - TabH;
  Total := 0;
  for I := 0 to N - 1 do
  begin
    W[I] := TabWidthAt(I);
    Inc(Total, W[I]);
    if I > 0 then
      Inc(Total, Scale(TabGap));
  end;
  Left0 := StripRect.Left + Scale(StripPad);
  Right0 := StripRect.Right - Scale(StripPad);
  FPrevRect := Rect(0, 0, 0, 0);
  FNextRect := Rect(0, 0, 0, 0);
  FOverflow := Total > Right0 - Left0;
  if FOverflow then
  begin
    ArrowW := TabH * 4 div 5;
    FNextRect := Rect(Right0 - ArrowW, Y0, Right0, Y0 + TabH);
    FPrevRect := Rect(FNextRect.Left - ArrowW, Y0, FNextRect.Left, Y0 + TabH);
    Right0 := FPrevRect.Left - Scale(TabGap);
    // Groesster sinnvoller erster Reiter: ab dort passt der Rest
    Avail := Right0 - Left0;
    FMaxFirst := N - 1;
    Sum := 0;
    for I := N - 1 downto 0 do
    begin
      Inc(Sum, W[I]);
      if I < N - 1 then
        Inc(Sum, Scale(TabGap));
      if Sum > Avail then
        Break;
      FMaxFirst := I;
    end;
  end
  else
    FMaxFirst := 0;
  if FFirst > FMaxFirst then
    FFirst := FMaxFirst;
  if FFirst < 0 then
    FFirst := 0;
  FTabArea := Rect(Left0, StripRect.Top, Right0, StripRect.Bottom);

  CS := Scale(CloseSize);
  X := Left0;
  for I := 0 to N - 1 do
  begin
    FRects[I] := Rect(0, 0, 0, 0);
    FCloseRects[I] := Rect(0, 0, 0, 0);
    if I < FFirst then
      Continue;
    R := Rect(X, Y0, X + W[I], Y0 + TabH);
    Inc(X, W[I] + Scale(TabGap));
    if R.Left >= Right0 then
      Continue;
    if FShowClose then
      FCloseRects[I] := Rect(R.Right - Scale(TabPadX) div 2 - CS,
        (R.Top + R.Bottom - CS) div 2, R.Right - Scale(TabPadX) div 2,
        (R.Top + R.Bottom + CS) div 2);
    if R.Right > Right0 then
    begin
      R.Right := Right0; // angeschnitten (Text mit Ellipse)
      if FCloseRects[I].Right > Right0 then
        FCloseRects[I] := Rect(0, 0, 0, 0);
    end;
    FRects[I] := R;
  end;

  if FRightToLeft then
  begin
    for I := 0 to N - 1 do
    begin
      FRects[I] := Mirror(FRects[I]);
      FCloseRects[I] := Mirror(FCloseRects[I]);
    end;
    // Pfeile mitspiegeln: "zurueck" zeigt weiter zum ersten Reiter (rechts)
    FPrevRect := Mirror(FPrevRect);
    FNextRect := Mirror(FNextRect);
    FTabArea := Mirror(FTabArea);
  end;
  if FHot > N - 1 then
    FHot := -1;
  if FHotClose > N - 1 then
    FHotClose := -1;
  if FSelected > N - 1 then
    FSelected := -1;
end;

function TPPGTabStrip.TabRectAt(Pos: Integer): TRect;
begin
  if (Pos < 0) or (Pos > High(FRects)) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := FRects[Pos];
end;

function TPPGTabStrip.CloseRectAt(Pos: Integer): TRect;
begin
  if (Pos < 0) or (Pos > High(FCloseRects)) then
    Result := Rect(0, 0, 0, 0)
  else
    Result := FCloseRects[Pos];
end;

function TPPGTabStrip.HitTest(X, Y: Integer; out OwnerIndex: Integer): TPPGTabHit;
var
  I: Integer;
  P: TPoint;
begin
  OwnerIndex := -1;
  Result := thNone;
  P := Point(X, Y);
  if FOverflow then
  begin
    if PtInRect(FPrevRect, P) then
      Exit(thPrev);
    if PtInRect(FNextRect, P) then
      Exit(thNext);
  end;
  for I := 0 to High(FRects) do
    if not IsRectEmpty(FRects[I]) and PtInRect(FRects[I], P) then
    begin
      OwnerIndex := FTabs[I].Index;
      if not IsRectEmpty(FCloseRects[I]) and PtInRect(FCloseRects[I], P) then
        Result := thClose
      else
        Result := thTab;
      Exit;
    end;
end;

function TPPGTabStrip.UpdateHot(X, Y: Integer): Boolean;
var
  Hit: TPPGTabHit;
  Idx, Pos, Close: Integer;
  Arrow: TPPGTabHit;
begin
  Hit := HitTest(X, Y, Idx);
  Pos := -1;
  Close := -1;
  Arrow := thNone;
  case Hit of
    thTab:
      Pos := PosOf(Idx);
    thClose:
      begin
        Pos := PosOf(Idx);
        Close := Pos;
      end;
    thPrev, thNext:
      Arrow := Hit;
  end;
  Result := (Pos <> FHot) or (Close <> FHotClose) or (Arrow <> FHotArrow);
  // Audit 8D: alte und neue Hover-Flaeche (der Besitzer zeichnet nur sie neu)
  if Result then
    FDirty := JoinRect(HotPartRect(FHot, FHotClose, FHotArrow), HotPartRect(Pos, Close, Arrow))
  else
    FDirty := Rect(0, 0, 0, 0);
  FHot := Pos;
  FHotClose := Close;
  FHotArrow := Arrow;
end;

function TPPGTabStrip.ClearHot: Boolean;
begin
  Result := (FHot >= 0) or (FHotClose >= 0) or (FHotArrow <> thNone);
  FDirty := HotPartRect(FHot, FHotClose, FHotArrow);
  FHot := -1;
  FHotClose := -1;
  FHotArrow := thNone;
end;

function TPPGTabStrip.HotPartRect(Pos, Close: Integer; Arrow: TPPGTabHit): TRect;
var
  R: TRect;
begin
  // Reiter (samt Schliessen-Knopf) bzw. Pfeil; mit Rand fuer Rahmen und Schein
  Result := TabRectAt(Pos);
  if Close >= 0 then
    Result := JoinRect(Result, TabRectAt(Close));
  case Arrow of
    thPrev: R := FPrevRect;
    thNext: R := FNextRect;
  else
    R := Rect(0, 0, 0, 0);
  end;
  if not IsRectEmpty(R) then
    Result := JoinRect(Result, R);
  if not IsRectEmpty(Result) then
    InflateRect(Result, Scale(4), Scale(4));
end;

function TPPGTabStrip.IndicatorFor(Pos: Integer): TRect;
var
  R: TRect;
  Inset, H: Integer;
begin
  R := TabRectAt(Pos);
  if IsRectEmpty(R) then
    Exit(Rect(0, 0, 0, 0));
  Inset := Scale(IndicatorInset);
  if (R.Right - R.Left) - 2 * Inset < Scale(12) then
    Inset := ((R.Right - R.Left) - Scale(12)) div 2;
  if Inset < 0 then
    Inset := 0;
  H := Scale(IndicatorH);
  if FVertical then
  begin
    // senkrechter Strich an der Kante zur Seite
    Inset := (R.Bottom - R.Top) div 4;
    if FBottom then
      Result := Rect(R.Left, R.Top + Inset, R.Left + H, R.Bottom - Inset)
    else
      Result := Rect(R.Right - H, R.Top + Inset, R.Right, R.Bottom - Inset);
    Exit;
  end;
  if FBottom then
    Result := Rect(R.Left + Inset, R.Top, R.Right - Inset, R.Top + H)
  else
    Result := Rect(R.Left + Inset, R.Bottom - H, R.Right - Inset, R.Bottom);
end;

function TPPGTabStrip.IndicatorRect: TRect;
var
  Target: TRect;
begin
  Target := IndicatorFor(FSelected);
  if FIndicatorAnim.Running and not IsRectEmpty(FIndicatorFrom) and
    not IsRectEmpty(Target) then
    Result := LerpRect(FIndicatorFrom, Target, FIndicatorAnim.Value)
  else
    Result := Target;
end;

function TPPGTabStrip.IndicatorMoving: Boolean;
begin
  Result := FIndicatorAnim.Running;
end;

procedure TPPGTabStrip.Select(OwnerIndex: Integer; Animate: Boolean; DurationMs: Cardinal);
var
  NewPos: Integer;
begin
  NewPos := PosOf(OwnerIndex);
  if Animate and (DurationMs > 0) and (FSelected >= 0) and (NewPos >= 0) and
    (NewPos <> FSelected) then
  begin
    FIndicatorFrom := IndicatorRect;
    FSelected := NewPos;
    if FMultiLine then
      Layout(FStrip);
    MakeVisible(NewPos);
    FIndicatorAnim.Jump(0);
    FIndicatorAnim.AnimateTo(1, DurationMs, ekDecelerate);
  end
  else
  begin
    FSelected := NewPos;
    if FMultiLine then
      Layout(FStrip);
    MakeVisible(NewPos);
    FIndicatorAnim.Jump(1);
  end;
end;

procedure TPPGTabStrip.MakeVisible(Pos: Integer);
var
  F, I, Sum, Avail, Gap, TabH: Integer;

  function Fits: Boolean;
  begin
    // Wie das Layout: waagerecht ganz vor dem Rand, senkrecht ganz sichtbar
    if FVertical then
      Result := FTabArea.Top + (Pos - F) * (TabH + Gap) + TabH <= FTabArea.Bottom
    else
      Result := Sum <= Avail;
  end;

begin
  if (Pos < 0) or (Pos >= Length(FTabs)) or not FOverflow then
    Exit;
  if Pos < FFirst then
  begin
    FFirst := Pos;
    Layout(FStrip);
    Exit;
  end;
  // Audit 8D: Nach rechts weiterblaettern, bis der Reiter ganz sichtbar ist -
  // gerechnet aus den Breiten statt je Schritt das ganze Layout (vorher
  // quadratisch). Die Lage der Pfeile und der Platz haengen nicht vom
  // ersten Reiter ab.
  F := FFirst;
  Gap := Scale(TabGap);
  Avail := FTabArea.Right - FTabArea.Left;
  TabH := TabRowHeight;
  Sum := 0;
  if not FVertical then
    for I := F to Pos do
    begin
      Inc(Sum, TabWidthAt(I));
      if I > F then
        Inc(Sum, Gap);
    end;
  while (F < Pos) and (F < FMaxFirst) and not Fits do
  begin
    if not FVertical then
      Dec(Sum, TabWidthAt(F) + Gap);
    Inc(F);
  end;
  if F <> FFirst then
  begin
    FFirst := F;
    Layout(FStrip);
  end;
end;

function TPPGTabStrip.CanScroll(Delta: Integer): Boolean;
begin
  if not FOverflow then
    Result := False
  else if Delta < 0 then
    Result := FFirst > 0
  else
    Result := FFirst < FMaxFirst;
end;

procedure TPPGTabStrip.Scroll(Delta: Integer);
begin
  if not CanScroll(Delta) then
    Exit;
  Inc(FFirst, Delta);
  Layout(FStrip);
  FDirty := Rect(0, 0, 0, 0);
  Changed;
end;

procedure TPPGTabStrip.Paint(const Canvas: IPPGCanvas; const Renderer: IPPGTabRenderer;
  const Info: TPPGTabPaintInfo);
var
  St: TPPGTabStyles;

  function TabElement(IsSelected, Hot: Boolean): TPPGElementStyle;
  begin
    if St = nil then
      Result := nil
    else if IsSelected then
      Result := St.ActiveTab
    else if Hot then
      Result := St.HotTab
    else
      Result := St.Tab;
  end;

  function ApplyFill(Base: TPPGSurfaceStyle; Pos: Integer; E: TPPGElementStyle;
    const DS: TPPGDrawStyle): TPPGSurfaceStyle;
  var
    C: TColor;
  begin
    // Flaeche: Element-Stil, Farbe des Reiters, eigenes Zeichnen
    Result := Base;
    if not Info.UseColors then
      Exit;
    C := clNone;
    if (E <> nil) and E.HasFill(Info.Dark) then
      C := E.FillFor(Info.Dark, clNone);
    if (FTabs[Pos].Color <> clDefault) and (FTabs[Pos].Color <> clNone) then
      C := PPGColorToRGB(FTabs[Pos].Color);
    if DS.Fill <> clNone then
      C := PPGColorToRGB(DS.Fill);
    if C <> clNone then
    begin
      Result.Color := C;
      Result.ColorTo := C;
      Result.ColorMirror := C;
      Result.ColorMirrorTo := C;
    end;
    if (E <> nil) and E.HasBorder(Info.Dark) then
      Result.BorderColor := E.BorderFor(Info.Dark, Result.BorderColor);
    if DS.BorderColor <> clNone then
      Result.BorderColor := PPGColorToRGB(DS.BorderColor);
  end;

  function TextOf(Pos: Integer; Color: TColor; E: TPPGElementStyle;
    const DS: TPPGDrawStyle; out F: TFont): TColor;
  var
    Extra: TFontStyles;
  begin
    Result := Color;
    Extra := FTabs[Pos].FontStyle + DS.FontStyle;
    if Info.UseColors then
    begin
      if E <> nil then
        Result := E.TextFor(Info.Dark, Result);
      if (FTabs[Pos].TextColor <> clDefault) and (FTabs[Pos].TextColor <> clNone) then
        Result := PPGColorToRGB(FTabs[Pos].TextColor);
      if DS.TextColor <> clNone then
        Result := PPGColorToRGB(DS.TextColor);
    end;
    if E <> nil then
      F := FFonts.ForStyle(E, FFont, Extra)
    else
      F := FFonts.Get(FFont, Extra);
  end;

  function RunDraw(Pos: Integer; const R: TRect; Active: Boolean;
    var DS: TPPGDrawStyle): Boolean;
  begin
    DS.Reset;
    Result := True;
    if Assigned(Info.OnDrawTab) then
      Info.OnDrawTab(Pos, Canvas, R, Active, DS, Result);
  end;

  procedure PaintContent(Pos: Integer; const R: TRect; Color: TColor; IsSelected: Boolean;
    F: TFont);
  var
    C: TRect;
    T: TPPGTabInfo;
    Flags: Cardinal;
    X, Y: Integer;
    ImgEnabled: Boolean;
  begin
    if Assigned(Info.OnDrawContent) and Info.OnDrawContent(Pos, Canvas, R, IsSelected) then
      Exit;
    T := FTabs[Pos];
    C := R;
    InflateRect(C, -Scale(TabPadX), 0);
    if FShowClose and not IsRectEmpty(FCloseRects[Pos]) then
    begin
      Renderer.DrawTabClose(Canvas, FCloseRects[Pos], Color, Pos = FHotClose, FPPI);
      if FRightToLeft then
        C.Left := FCloseRects[Pos].Right + Scale(4)
      else
        C.Right := FCloseRects[Pos].Left - Scale(4);
    end;
    if (FImages <> nil) and (T.ImageIndex >= 0) and (T.ImageIndex < FImages.Count) then
    begin
      Y := (R.Top + R.Bottom - FImages.Height) div 2;
      if FRightToLeft then
      begin
        X := C.Right - FImages.Width;
        C.Right := X - Scale(ImageGap);
      end
      else
      begin
        X := C.Left;
        C.Left := X + FImages.Width + Scale(ImageGap);
      end;
      ImgEnabled := Info.Enabled and T.Enabled;
      Canvas.DrawImage(FImages, T.ImageIndex, X, Y, ImgEnabled);
    end;
    if C.Right <= C.Left then
      Exit;
    Flags := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS;
    // Feste Breite oder gefuellte Reihen (MultiLine): Text mittig
    if (FTabWidth > 0) or (FMultiLine and not FRaggedRight and (FRowCount > 1)) then
      Flags := Flags or DT_CENTER;
    if FRightToLeft then
      Flags := Flags or DT_RIGHT or DT_RTLREADING;
    if not Info.ShowAccel then
      Flags := Flags or DT_HIDEPREFIX;
    Canvas.DrawText(C, T.Caption, F, Color, Flags);
    if IsSelected and Info.Focused then
    begin
      C := R;
      InflateRect(C, -Scale(4), -Scale(4));
      Canvas.DrawFocusRect(C);
    end;
  end;

  procedure DrawVArrow(const R: TRect; Up, Hot, AEnabled: Boolean);
  var
    CX, CY, Half: Integer;
    Pts: array[0..2] of TPoint;
    Alpha: Byte;
  begin
    // Blaetterpfeil hoch/runter (senkrechte Leiste)
    if IsRectEmpty(R) then
      Exit;
    if Hot and AEnabled then
      Canvas.FillRoundRect(R, Scale(4), Info.Tab.TextColor, 28);
    CX := (R.Left + R.Right) div 2;
    CY := (R.Top + R.Bottom) div 2;
    Half := Scale(4);
    if Up then
    begin
      Pts[0] := Point(CX - Half, CY + Half div 2);
      Pts[1] := Point(CX, CY - Half div 2);
      Pts[2] := Point(CX + Half, CY + Half div 2);
    end
    else
    begin
      Pts[0] := Point(CX - Half, CY - Half div 2);
      Pts[1] := Point(CX, CY + Half div 2);
      Pts[2] := Point(CX + Half, CY - Half div 2);
    end;
    if AEnabled then
      Alpha := 255
    else
      Alpha := 90;
    Canvas.DrawPolyline(Pts, Scale(1) + 1, Info.Tab.TextColor, Alpha);
  end;

  procedure PaintButton(Pos: Integer; const R: TRect; IsSelected, Hot: Boolean);
  var
    Body: TRect;
    Fill, Border, TC: TColor;
    DS: TPPGDrawStyle;
    E: TPPGElementStyle;
    F: TFont;
    S: TPPGSurfaceStyle;
    Alpha: Byte;
  begin
    // Knoepfe (tsButtons) bzw. flache Knoepfe (tsFlatButtons) statt Reitern
    if not RunDraw(Pos, R, IsSelected, DS) then
      Exit;
    E := TabElement(IsSelected, Hot);
    Body := R;
    InflateRect(Body, -Scale(1), -Scale(2));
    if IsSelected then
    begin
      Fill := Info.Accent;
      Alpha := 40;
    end
    else if Hot then
    begin
      Fill := Info.HotTab.Color;
      Alpha := 255;
    end
    else
    begin
      Fill := Info.Tab.Color;
      Alpha := 255 * Ord(FButtonStyle = tbsButtons);
    end;
    S := Info.Tab;
    S.Color := Fill;
    S := ApplyFill(S, Pos, E, DS);
    if S.Color <> Fill then
      Alpha := 255;
    Border := Info.Tab.BorderColor;
    if (E <> nil) and Info.UseColors then
      Border := E.BorderFor(Info.Dark, Border);
    if Alpha > 0 then
      Canvas.FillRoundRect(Body, Scale(4), S.Color, Alpha);
    if (FButtonStyle = tbsButtons) or IsSelected then
      Canvas.FrameRoundRect(Body, Scale(4), 1, Border, 255);
    if not (Info.Enabled and FTabs[Pos].Enabled) then
      TC := Info.DisabledText
    else if IsSelected then
      TC := Info.Selected.TextColor
    else if Hot then
      TC := Info.HotTab.TextColor
    else
      TC := Info.Tab.TextColor;
    TC := TextOf(Pos, TC, E, DS, F);
    PaintContent(Pos, R, TC, IsSelected, F);
  end;

var
  I: Integer;
  R, Area: TRect;
  Hot: Boolean;
  Color: TColor;
  SS: TPPGSurfaceStyle;
  DS: TPPGDrawStyle;
  E: TPPGElementStyle;
  F: TFont;
  Accent: TColor;
begin
  if Renderer = nil then
    Exit;
  St := Info.Styles;
  try
    SS := Info.Strip;
    if (St <> nil) and Info.UseColors and St.Strip.HasFill(Info.Dark) then
    begin
      SS.Color := St.Strip.FillFor(Info.Dark, clNone);
      SS.ColorTo := SS.Color;
      SS.ColorMirror := SS.Color;
      SS.ColorMirrorTo := SS.Color;
    end;
    if not FVertical then
    begin
      Renderer.DrawTabStrip(Canvas, FStrip, SS, FBottom, FPPI);
      if not IsRectEmpty(FOppRect) and (Length(FOppRow) > 0) then
        Renderer.DrawTabStrip(Canvas, FOppRect, SS, not FBottom, FPPI);
    end
    else if Info.UseColors and (SS.Color <> clNone) then
      Canvas.FillRoundRect(FStrip, 0, SS.Color, 255);
    if FVertical or (FButtonStyle <> tbsTabs) then
    begin
      // Knoepfe: kein Hineinragen in die Seite, kein Unterstrich
      Canvas.PushClipRoundRect(FTabArea, 0);
      try
        for I := 0 to High(FRects) do
          if not IsRectEmpty(FRects[I]) then
            PaintButton(I, FRects[I], I = FSelected,
              (Info.HotTrack and Info.Enabled and FTabs[I].Enabled and (I = FHot)) or
              FTabs[I].Highlighted);
        // Senkrechte Reiter: Indikator an der Kante zur Seite
        if FVertical and (FButtonStyle = tbsTabs) then
        begin
          R := IndicatorRect;
          if not IsRectEmpty(R) and Info.Enabled then
          begin
            Accent := Info.Accent;
            if (St <> nil) and Info.UseColors then
              Accent := St.Indicator.FillFor(Info.Dark, Accent);
            Renderer.DrawTabIndicator(Canvas, R, Accent, FBottom, FPPI);
          end;
        end;
      finally
        Canvas.PopClip;
      end;
    end
    else
    begin
      // Reiter nur im Reiterbereich (nicht unter den Pfeilen); der gewaehlte
      // darf um Overlap in die Seite ragen
      Area := FTabArea;
      if FBottom then
        Dec(Area.Top, Info.Overlap)
      else
        Inc(Area.Bottom, Info.Overlap);
      Canvas.PushClipRoundRect(Area, 0);
      try
        for I := 0 to High(FRects) do
        begin
          R := FRects[I];
          if IsRectEmpty(R) or (I = FSelected) then
            Continue;
          Hot := (Info.HotTrack and Info.Enabled and FTabs[I].Enabled and (I = FHot)) or
            FTabs[I].Highlighted;
          if not RunDraw(I, R, False, DS) then
            Continue;
          E := TabElement(False, Hot);
          // Nicht gewaehlte Reiter haben im Preset keine Flaeche: eigene Farbe
          // (Stil, Reiter, eigenes Zeichnen) hier selbst fuellen
          SS := ApplyFill(Info.Tab, I, E, DS);
          if Info.UseColors and (SS.Color <> Info.Tab.Color) then
            Canvas.FillRoundRect(Rect(R.Left + Scale(1), R.Top + Scale(2), R.Right - Scale(1),
              R.Bottom), Scale(4), SS.Color, 255);
          if Hot then
            Renderer.DrawTab(Canvas, R, ApplyFill(Info.HotTab, I, E, DS), False, 1, FBottom xor FOppRow[I], FPPI)
          else
            Renderer.DrawTab(Canvas, R, ApplyFill(Info.Tab, I, E, DS), False, 0, FBottom xor FOppRow[I], FPPI);
          if not (Info.Enabled and FTabs[I].Enabled) then
            Color := Info.DisabledText
          else if Hot then
            Color := Info.HotTab.TextColor
          else
            Color := Info.Tab.TextColor;
          Color := TextOf(I, Color, E, DS, F);
          PaintContent(I, R, Color, False, F);
        end;
        if (FSelected >= 0) and not IsRectEmpty(TabRectAt(FSelected)) then
        begin
          R := FRects[FSelected];
          if FBottom then
            Dec(R.Top, Info.Overlap)
          else
            Inc(R.Bottom, Info.Overlap);
          if RunDraw(FSelected, FRects[FSelected], True, DS) then
          begin
            E := TabElement(True, False);
            Renderer.DrawTab(Canvas, R, ApplyFill(Info.Selected, FSelected, E, DS), True, 0,
              FBottom, FPPI);
            if Info.Enabled and FTabs[FSelected].Enabled then
              Color := Info.Selected.TextColor
            else
              Color := Info.DisabledText;
            Color := TextOf(FSelected, Color, E, DS, F);
            PaintContent(FSelected, FRects[FSelected], Color, True, F);
          end;
        end;
        R := IndicatorRect;
        if not IsRectEmpty(R) and Info.Enabled then
        begin
          Accent := Info.Accent;
          if (St <> nil) and Info.UseColors then
            Accent := St.Indicator.FillFor(Info.Dark, Accent);
          Renderer.DrawTabIndicator(Canvas, R, Accent, FBottom, FPPI);
        end;
      finally
        Canvas.PopClip;
      end;
    end;
    if FOverflow and FVertical then
    begin
      DrawVArrow(FPrevRect, True, FHotArrow = thPrev, Info.Enabled and CanScroll(-1));
      DrawVArrow(FNextRect, False, FHotArrow = thNext, Info.Enabled and CanScroll(1));
    end
    else if FOverflow then
    begin
      Renderer.DrawTabScrollArrow(Canvas, FPrevRect, Info.Tab.TextColor, FRightToLeft,
        FHotArrow = thPrev, Info.Enabled and CanScroll(-1), FPPI);
      Renderer.DrawTabScrollArrow(Canvas, FNextRect, Info.Tab.TextColor, not FRightToLeft,
        FHotArrow = thNext, Info.Enabled and CanScroll(1), FPPI);
    end;
  finally
    FFonts.Clear; // keine Schrift-Handles ueber das Zeichnen hinaus
  end;
end;

end.
