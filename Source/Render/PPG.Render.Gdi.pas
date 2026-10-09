unit PPG.Render.Gdi;

{ GDI-Fallback-Canvas (ohne Antialiasing, Alpha per AlphaBlend) und GDI-Helfer
  fuer Text, Bilder und Fokusrahmen.

  Der Fallback wird benutzt, wenn GDI+ nicht verfuegbar ist oder vom
  Anwender erzwungen wird. Er garantiert, dass ein Control IMMER bedienbar
  dargestellt wird. Jede GDI-Ressource hat ihr eigenes try/finally. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.ImgList,
  PPG.Types, PPG.Render.Intf;

type
  /// Zwischenebene fuer halbtransparentes Zeichnen (siehe BeginLayer).
  TPPGGdiLayer = record
    DC: HDC;
    Bmp: HBITMAP;
    OldBmp: HGDIOBJ;
    Bounds: TRect;
  end;

  TPPGGdiCanvas = class(TInterfacedObject, IPPGCanvas, IPPGShapeCanvas, IPPGCornerCanvas)
  private
    FDC: HDC;
    FSquare: TPPGCorners;
    FClipDepth: Integer;
    function BeginLayer(const Bounds: TRect; out Layer: TPPGGdiLayer): Boolean;
    procedure EndLayer(var Layer: TPPGGdiLayer; Alpha: Byte);
    procedure AddSquareCorners(Rgn: HRGN; const R: TRect; Radius: Integer);
  public
    constructor Create(ADC: HDC);
    destructor Destroy; override;
    { IPPGCanvas }
    function IsAntialiased: Boolean;
    procedure FillRoundRect(const R: TRect; Radius: Integer; Color: TColor; Alpha: Byte);
    procedure FillGradientRect(const R: TRect; ColorFrom, ColorTo: TColor;
      Direction: TPPGGradientDirection; Alpha: Byte);
    procedure FrameRoundRect(const R: TRect; Radius, Width: Integer; Color: TColor; Alpha: Byte);
    procedure DrawOuterGlow(const R: TRect; Radius, Size: Integer; Color: TColor; Alpha: Byte);
    procedure FillRadialGlow(const R: TRect; Color: TColor; Alpha: Byte);
    procedure FillEllipse(const R: TRect; Color: TColor; Alpha: Byte);
    procedure FrameEllipse(const R: TRect; Width: Integer; Color: TColor; Alpha: Byte);
    procedure DrawPolyline(const Points: array of TPoint; Width: Integer; Color: TColor; Alpha: Byte);
    procedure PushClipRoundRect(const R: TRect; Radius: Integer);
    procedure PopClip;
    function MeasureText(const Text: string; Font: TFont; MaxWidth: Integer;
      WordWrap: Boolean): TSize;
    procedure DrawText(const R: TRect; const Text: string; Font: TFont; Color: TColor;
      Flags: Cardinal);
    procedure DrawImage(Images: TCustomImageList; Index, X, Y: Integer; Enabled: Boolean);
    procedure DrawFocusRect(const R: TRect);
    function BeginGdi: HDC;
    procedure EndGdi(DC: HDC);
    { IPPGCornerCanvas }
    function GetSquareCorners: TPPGCorners;
    procedure SetSquareCorners(Corners: TPPGCorners);
    { IPPGShapeCanvas }
    procedure FillPolygon(const Points: array of TPoint; Color: TColor; Alpha: Byte);
    procedure DrawDashedPolyline(const Points: array of TPoint; Width, Dash, Gap: Integer;
      Color: TColor; Alpha: Byte);
  end;

{ Gemeinsame GDI-Helfer (auch vom GDI+-Canvas ueber GetHDC benutzt) }
function PPGGdiMeasureText(DC: HDC; const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
procedure PPGGdiDrawText(DC: HDC; const R: TRect; const Text: string; Font: TFont;
  Color: TColor; Flags: Cardinal);
procedure PPGGdiDrawImage(DC: HDC; Images: TCustomImageList; Index, X, Y: Integer;
  Enabled: Boolean);
procedure PPGGdiDrawFocusRect(DC: HDC; const R: TRect);
/// Zeichnet ein Bild einfarbig in Color (Form aus dem Alphakanal bzw. der
/// Maske), z.B. einfarbige Symbole in der Textfarbe des Zustands.
procedure PPGGdiDrawImageTinted(DC: HDC; Images: TCustomImageList; Index, X, Y: Integer;
  Color: TColor);
/// Misst Text ohne vorhandenen Canvas (z.B. fuer AutoSize ausserhalb von Paint).
/// Audit 8a #4: im Hauptthread ueber einen gemeinsamen Mess-DC und einen
/// Cache je (Schrift, Breite, Umbruch, Text); in anderen Threads mit einem
/// kurzlebigen Speicher-DC wie bisher.
function PPGMeasureTextNoCanvas(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
/// Leert den Mess-Cache (z.B. nach einem Wechsel der Systemschriften).
procedure PPGClearMeasureCache;
/// Diagnose/Tests: Anzahl der bisher angelegten Mess-DCs.
function PPGMeasureDCCount: Integer;
/// Leert den Cache eingefaerbter Bilder (PPGGdiDrawImageTinted); Controls
/// rufen das, wenn sich ihre Bilderliste aendert.
procedure PPGClearTintCache;

implementation

uses
  System.SysUtils, System.Math, System.Classes, System.Generics.Collections,
  Winapi.CommCtrl, PPG.Exceptions;

type
  /// Beobachtet die Bilderlisten im Cache eingefaerbter Bilder: Aenderung
  /// oder Freigabe einer Liste leert den Cache (auch fuer Aufrufer ohne
  /// eigenes Control, z.B. direkte Aufrufe von PPGGdiDrawImageTinted).
  TPPGTintWatcher = class(TComponent)
  private
    FLinks: TObjectDictionary<TCustomImageList, TChangeLink>;
    procedure ListChanged(Sender: TObject);
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Watch(Images: TCustomImageList);
  end;

const
  MaxMeasureEntries = 4096; // danach wird der Mess-Cache geleert
  MaxMeasureText = 256;     // laengere Texte werden nicht gecacht
  MaxTintEntries = 256;

var
  GMeasureDC: HDC = 0;
  GMeasureDCCount: Integer = 0;
  GMeasureCache: TDictionary<string, TSize> = nil;
  GTintCache: TDictionary<string, TArray<Cardinal>> = nil;
  GTintWatcher: TPPGTintWatcher = nil;
  GFinalized: Boolean = False; // nach der Finalisierung: ohne Cache und gemeinsamen DC

{ Helfer }

function TintKey(Images: TCustomImageList; Index: Integer; Color: Cardinal;
  W, H: Integer): string;
begin
  Result := Format('%p|%d|%d|%d|%d', [Pointer(Images), Index, Color, W, H]);
end;

procedure PPGClearTintCache;
begin
  if GTintCache <> nil then
    GTintCache.Clear;
end;

{ TPPGTintWatcher }

constructor TPPGTintWatcher.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLinks := TObjectDictionary<TCustomImageList, TChangeLink>.Create([doOwnsValues]);
end;

destructor TPPGTintWatcher.Destroy;
begin
  FreeAndNil(FLinks); // TChangeLink meldet sich bei der Liste ab
  inherited Destroy;
end;

procedure TPPGTintWatcher.Watch(Images: TCustomImageList);
var
  L: TChangeLink;
begin
  if FLinks.ContainsKey(Images) then
    Exit;
  L := TChangeLink.Create;
  try
    L.OnChange := ListChanged;
    Images.RegisterChanges(L);
    FLinks.Add(Images, L);
  except
    L.Free;
    raise;
  end;
  Images.FreeNotification(Self);
end;

procedure TPPGTintWatcher.ListChanged(Sender: TObject);
begin
  PPGClearTintCache;
end;

procedure TPPGTintWatcher.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (FLinks <> nil) and (AComponent is TCustomImageList) and
    FLinks.ContainsKey(TCustomImageList(AComponent)) then
  begin
    // Adresse kann fuer eine neue Liste wiederverwendet werden
    PPGClearTintCache;
    FLinks.Remove(TCustomImageList(AComponent));
  end;
end;

/// Eingefaerbtes Bild als vormultiplizierte BGRA-Pixel (oben nach unten).
function BuildTintedBits(DC: HDC; Images: TCustomImageList; Index, W, H: Integer;
  C: Cardinal): TArray<Cardinal>;
const
  KeyColor = $00FF00FF; // Magenta als Hintergrund fuer Bilder ohne Alphakanal
var
  MemDC: HDC;
  Bmp, OldBmp: HBITMAP;
  BI: TBitmapInfo;
  Bits: Pointer;
  P: PCardinal;
  I, N: Integer;
  A, R, G, B: Cardinal;
  HasAlpha: Boolean;
begin
  N := W * H;
  SetLength(Result, N);
  FillChar(BI, SizeOf(BI), 0);
  BI.bmiHeader.biSize := SizeOf(BI.bmiHeader);
  BI.bmiHeader.biWidth := W;
  BI.bmiHeader.biHeight := -H; // von oben nach unten
  BI.bmiHeader.biPlanes := 1;
  BI.bmiHeader.biBitCount := 32;
  BI.bmiHeader.biCompression := BI_RGB;
  MemDC := CreateCompatibleDC(DC);
  if MemDC = 0 then
    PPGRaiseLastOSError('CreateCompatibleDC');
  try
    Bmp := CreateDIBSection(MemDC, BI, DIB_RGB_COLORS, Bits, 0, 0);
    if (Bmp = 0) or (Bits = nil) then
      PPGRaiseLastOSError('CreateDIBSection');
    try
      OldBmp := SelectObject(MemDC, Bmp);
      try
        // 1. Mit Alphakanal (32-Bit-Listen, TVirtualImageList): auf
        // durchsichtigen Grund zeichnen, der Alphakanal bleibt erhalten
        FillChar(Bits^, N * 4, 0);
        ImageList_Draw(Images.Handle, Index, MemDC, 0, 0, ILD_TRANSPARENT);
        GdiFlush;
        HasAlpha := False;
        P := Bits;
        for I := 0 to N - 1 do
        begin
          if P^ shr 24 <> 0 then
          begin
            HasAlpha := True;
            Break;
          end;
          Inc(P);
        end;
        // 2. Ohne Alphakanal (Maske): auf Magenta zeichnen, alles andere ist Form
        if not HasAlpha then
        begin
          P := Bits;
          for I := 0 to N - 1 do
          begin
            P^ := KeyColor;
            Inc(P);
          end;
          ImageList_Draw(Images.Handle, Index, MemDC, 0, 0, ILD_TRANSPARENT);
          GdiFlush;
          P := Bits;
          for I := 0 to N - 1 do
          begin
            if P^ and $00FFFFFF = KeyColor then
              P^ := 0
            else
              P^ := $FF000000;
            Inc(P);
          end;
        end;
        // 3. Einfaerben: Farbe vormultipliziert mit dem Alpha (BGRA im Speicher)
        R := C and $FF;
        G := (C shr 8) and $FF;
        B := (C shr 16) and $FF;
        P := Bits;
        for I := 0 to N - 1 do
        begin
          A := P^ shr 24;
          Result[I] := (A shl 24) or ((R * A div 255) shl 16) or ((G * A div 255) shl 8) or
            (B * A div 255);
          Inc(P);
        end;
      finally
        SelectObject(MemDC, OldBmp);
      end;
    finally
      DeleteObject(Bmp);
    end;
  finally
    DeleteDC(MemDC);
  end;
end;

procedure PPGGdiDrawImageTinted(DC: HDC; Images: TCustomImageList; Index, X, Y: Integer;
  Color: TColor);
var
  MemDC: HDC;
  Bmp, OldBmp: HBITMAP;
  BI: TBitmapInfo;
  Bits: Pointer;
  W, H: Integer;
  C: Cardinal;
  Px: TArray<Cardinal>;
  Key: string;
  Cache: Boolean;
  BF: TBlendFunction;
begin
  if (Images = nil) or (Index < 0) or (Index >= Images.Count) then
    Exit;
  W := Images.Width;
  H := Images.Height;
  if (W <= 0) or (H <= 0) then
    Exit;
  C := Cardinal(ColorToRGB(Color));
  // Audit 8a #6: eingefaerbte Pixel je (Liste, Bild, Farbe, Groesse) merken;
  // die Controls leeren den Cache, wenn sich ihre Liste aendert
  Cache := (GetCurrentThreadId = MainThreadID) and not GFinalized;
  Key := '';
  if Cache then
  begin
    if GTintCache = nil then
      GTintCache := TDictionary<string, TArray<Cardinal>>.Create;
    Key := TintKey(Images, Index, C, W, H);
    if not GTintCache.TryGetValue(Key, Px) then
    begin
      if GTintWatcher = nil then
        GTintWatcher := TPPGTintWatcher.Create(nil);
      GTintWatcher.Watch(Images);
      Px := BuildTintedBits(DC, Images, Index, W, H, C);
      if GTintCache.Count >= MaxTintEntries then
        GTintCache.Clear;
      GTintCache.Add(Key, Px);
    end;
  end
  else
    Px := BuildTintedBits(DC, Images, Index, W, H, C);
  FillChar(BI, SizeOf(BI), 0);
  BI.bmiHeader.biSize := SizeOf(BI.bmiHeader);
  BI.bmiHeader.biWidth := W;
  BI.bmiHeader.biHeight := -H; // von oben nach unten
  BI.bmiHeader.biPlanes := 1;
  BI.bmiHeader.biBitCount := 32;
  BI.bmiHeader.biCompression := BI_RGB;
  MemDC := CreateCompatibleDC(DC);
  if MemDC = 0 then
    PPGRaiseLastOSError('CreateCompatibleDC');
  try
    Bmp := CreateDIBSection(MemDC, BI, DIB_RGB_COLORS, Bits, 0, 0);
    if (Bmp = 0) or (Bits = nil) then
      PPGRaiseLastOSError('CreateDIBSection');
    try
      OldBmp := SelectObject(MemDC, Bmp);
      try
        Move(Px[0], Bits^, W * H * 4);
        BF.BlendOp := AC_SRC_OVER;
        BF.BlendFlags := 0;
        BF.SourceConstantAlpha := 255;
        BF.AlphaFormat := AC_SRC_ALPHA;
        if not Winapi.Windows.AlphaBlend(DC, X, Y, W, H, MemDC, 0, 0, W, H, BF) then
          PPGRaiseLastOSError('AlphaBlend');
      finally
        SelectObject(MemDC, OldBmp);
      end;
    finally
      DeleteObject(Bmp);
    end;
  finally
    DeleteDC(MemDC);
  end;
end;


function PPGGdiMeasureText(DC: HDC; const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
var
  R: TRect;
  Saved: Integer;
  Flags: Cardinal;
begin
  Result.cx := 0;
  Result.cy := 0;
  if Text = '' then
    Exit;
  Saved := SaveDC(DC);
  try
    SelectObject(DC, Font.Handle);
    if MaxWidth <= 0 then
      MaxWidth := MaxInt div 2;
    R := Rect(0, 0, MaxWidth, 0);
    Flags := DT_CALCRECT or DT_NOCLIP;
    if WordWrap then
      Flags := Flags or DT_WORDBREAK
    else
      Flags := Flags or DT_SINGLELINE;
    Winapi.Windows.DrawText(DC, PChar(Text), Length(Text), R, Flags);
    Result.cx := R.Right - R.Left;
    Result.cy := R.Bottom - R.Top;
  finally
    RestoreDC(DC, Saved);
  end;
end;

procedure PPGGdiDrawText(DC: HDC; const R: TRect; const Text: string; Font: TFont;
  Color: TColor; Flags: Cardinal);
var
  Saved: Integer;
  TR: TRect;
begin
  if Text = '' then
    Exit;
  Saved := SaveDC(DC);
  try
    SelectObject(DC, Font.Handle);
    SetTextColor(DC, ColorToRGB(Color));
    SetBkMode(DC, TRANSPARENT);
    TR := R;
    Winapi.Windows.DrawText(DC, PChar(Text), Length(Text), TR, Flags);
  finally
    RestoreDC(DC, Saved);
  end;
end;

procedure PPGGdiDrawImage(DC: HDC; Images: TCustomImageList; Index, X, Y: Integer;
  Enabled: Boolean);
var
  C: TCanvas;
begin
  if (Images = nil) or (Index < 0) or (Index >= Images.Count) then
    Exit;
  C := TCanvas.Create;
  try
    C.Handle := DC;
    try
      Images.Draw(C, X, Y, Index, Enabled);
    finally
      C.Handle := 0; // DC gehoert dem Aufrufer, nicht dem TCanvas
    end;
  finally
    C.Free;
  end;
end;

procedure PPGGdiDrawFocusRect(DC: HDC; const R: TRect);
var
  Saved: Integer;
begin
  Saved := SaveDC(DC);
  try
    SetTextColor(DC, ColorToRGB(clBlack));
    SetBkColor(DC, ColorToRGB(clWhite));
    Winapi.Windows.DrawFocusRect(DC, R);
  finally
    RestoreDC(DC, Saved);
  end;
end;

function MeasureKey(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): string;
var
  LF: TLogFont;
  N: Integer;
begin
  // Schluessel: vollstaendige LOGFONT (Name, Hoehe = PPI, Stil, Zeichensatz,
  // Qualitaet ...), Breite, Umbruch und Text
  FillChar(LF, SizeOf(LF), 0);
  GetObject(Font.Handle, SizeOf(LF), @LF);
  N := (SizeOf(LF) + SizeOf(Char) - 1) div SizeOf(Char);
  SetLength(Result, N);
  Move(LF, Pointer(Result)^, SizeOf(LF));
  Result := Result + IntToStr(MaxWidth) + Char(Ord('0') + Ord(WordWrap)) + Text;
end;

function PPGMeasureTextNoCanvas(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
var
  DC: HDC;
  Key: string;
begin
  if Text = '' then
  begin
    Result.cx := 0;
    Result.cy := 0;
    Exit;
  end;
  if (GetCurrentThreadId <> MainThreadID) or GFinalized then
  begin
    // Ausserhalb des Hauptthreads (bzw. beim Beenden): eigener, kurzlebiger DC, kein Cache
    DC := CreateCompatibleDC(0);
    if DC = 0 then
      PPGRaiseLastOSError('CreateCompatibleDC');
    try
      Result := PPGGdiMeasureText(DC, Text, Font, MaxWidth, WordWrap);
    finally
      DeleteDC(DC);
    end;
    Exit;
  end;
  Key := '';
  if Length(Text) <= MaxMeasureText then
  begin
    Key := MeasureKey(Text, Font, MaxWidth, WordWrap);
    if (GMeasureCache <> nil) and GMeasureCache.TryGetValue(Key, Result) then
      Exit;
  end;
  // Gemeinsamer Mess-DC (lazy, bis zum Programmende; PPGGdiMeasureText
  // waehlt die Schrift nur innerhalb von SaveDC/RestoreDC)
  if GMeasureDC = 0 then
  begin
    GMeasureDC := CreateCompatibleDC(0);
    if GMeasureDC = 0 then
      PPGRaiseLastOSError('CreateCompatibleDC');
    Inc(GMeasureDCCount);
  end;
  Result := PPGGdiMeasureText(GMeasureDC, Text, Font, MaxWidth, WordWrap);
  if Key <> '' then
  begin
    if GMeasureCache = nil then
      GMeasureCache := TDictionary<string, TSize>.Create;
    if GMeasureCache.Count >= MaxMeasureEntries then
      GMeasureCache.Clear;
    GMeasureCache.AddOrSetValue(Key, Result);
  end;
end;

procedure PPGClearMeasureCache;
begin
  if GMeasureCache <> nil then
    GMeasureCache.Clear;
end;

function PPGMeasureDCCount: Integer;
begin
  Result := GMeasureDCCount;
end;

{ TPPGGdiCanvas }

constructor TPPGGdiCanvas.Create(ADC: HDC);
begin
  inherited Create;
  FDC := ADC;
end;

destructor TPPGGdiCanvas.Destroy;
begin
  // Unausgeglichene PushClip-Aufrufe aufraeumen (z.B. nach Exception im Renderer)
  while FClipDepth > 0 do
    PopClip;
  inherited Destroy;
end;

function TPPGGdiCanvas.IsAntialiased: Boolean;
begin
  Result := False;
end;

{ Halbtransparenz ohne GDI+: Ziel in eine Ebene kopieren, dort deckend
  zeichnen und die Ebene mit konstantem Alpha zurueckblenden (AlphaBlend).
  Pixel ausserhalb der Form bleiben dabei unveraendert, der Clip des
  Ziel-DCs gilt beim Zurueckblenden. }

function TPPGGdiCanvas.BeginLayer(const Bounds: TRect; out Layer: TPPGGdiLayer): Boolean;
var
  W, H: Integer;
begin
  Result := False;
  FillChar(Layer, SizeOf(Layer), 0);
  W := Bounds.Right - Bounds.Left;
  H := Bounds.Bottom - Bounds.Top;
  if (W <= 0) or (H <= 0) then
    Exit;
  Layer.Bounds := Bounds;
  Layer.DC := CreateCompatibleDC(FDC);
  if Layer.DC = 0 then
    Exit;
  Layer.Bmp := CreateCompatibleBitmap(FDC, W, H);
  if Layer.Bmp = 0 then
  begin
    DeleteDC(Layer.DC);
    Layer.DC := 0;
    Exit;
  end;
  Layer.OldBmp := SelectObject(Layer.DC, Layer.Bmp);
  BitBlt(Layer.DC, 0, 0, W, H, FDC, Bounds.Left, Bounds.Top, SRCCOPY);
  // Gleiche Koordinaten wie im Ziel
  SetWindowOrgEx(Layer.DC, Bounds.Left, Bounds.Top, nil);
  Result := True;
end;

procedure TPPGGdiCanvas.EndLayer(var Layer: TPPGGdiLayer; Alpha: Byte);
var
  BF: TBlendFunction;
  W, H: Integer;
begin
  if Layer.DC = 0 then
    Exit;
  try
    SetWindowOrgEx(Layer.DC, 0, 0, nil);
    W := Layer.Bounds.Right - Layer.Bounds.Left;
    H := Layer.Bounds.Bottom - Layer.Bounds.Top;
    BF.BlendOp := AC_SRC_OVER;
    BF.BlendFlags := 0;
    BF.SourceConstantAlpha := Alpha;
    BF.AlphaFormat := 0;
    Winapi.Windows.AlphaBlend(FDC, Layer.Bounds.Left, Layer.Bounds.Top, W, H,
      Layer.DC, 0, 0, W, H, BF);
  finally
    SelectObject(Layer.DC, Layer.OldBmp);
    DeleteObject(Layer.Bmp);
    DeleteDC(Layer.DC);
    Layer.DC := 0;
  end;
end;

/// Quadrat der Rundung an einer Ecke (fuer eckige Ecken).
function CornerBox(const R: TRect; Radius: Integer; C: TPPGCorner): TRect;
var
  D: Integer;
begin
  D := Min(Radius, Min((R.Right - R.Left) div 2, (R.Bottom - R.Top) div 2));
  case C of
    pcTopLeft: Result := Rect(R.Left, R.Top, R.Left + D, R.Top + D);
    pcTopRight: Result := Rect(R.Right - D, R.Top, R.Right, R.Top + D);
    pcBottomRight: Result := Rect(R.Right - D, R.Bottom - D, R.Right, R.Bottom);
  else
    Result := Rect(R.Left, R.Bottom - D, R.Left + D, R.Bottom);
  end;
end;

procedure PaintFillRoundRect(DC: HDC; const R: TRect; Radius: Integer; Color: TColor;
  Square: TPPGCorners = []);
var
  Brush: HBRUSH;
  Saved: Integer;
  C: TPPGCorner;
  B: TRect;
begin
  Brush := CreateSolidBrush(ColorToRGB(Color));
  if Brush = 0 then
    PPGRaiseLastOSError('CreateSolidBrush');
  try
    if Radius <= 0 then
      Winapi.Windows.FillRect(DC, R, Brush)
    else
    begin
      Saved := SaveDC(DC);
      try
        SelectObject(DC, Brush);
        SelectObject(DC, GetStockObject(NULL_PEN));
        // NULL_PEN zeichnet rechts/unten exklusiv -> +1
        RoundRect(DC, R.Left, R.Top, R.Right + 1, R.Bottom + 1, Radius * 2, Radius * 2);
      finally
        RestoreDC(DC, Saved);
      end;
      // Eckige Ecken: Rundung mit dem Eckquadrat auffuellen
      for C := Low(TPPGCorner) to High(TPPGCorner) do
        if C in Square then
        begin
          B := CornerBox(R, Radius, C);
          Winapi.Windows.FillRect(DC, B, Brush);
        end;
    end;
  finally
    DeleteObject(Brush);
  end;
end;

procedure TPPGGdiCanvas.FillRoundRect(const R: TRect; Radius: Integer; Color: TColor;
  Alpha: Byte);
var
  L: TPPGGdiLayer;
begin
  if (Alpha = 0) or IsRectEmpty(R) then
    Exit;
  if (Alpha < 255) and BeginLayer(Rect(R.Left, R.Top, R.Right + 1, R.Bottom + 1), L) then
    try
      PaintFillRoundRect(L.DC, R, Radius, Color, FSquare);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintFillRoundRect(FDC, R, Radius, Color, FSquare);
end;

procedure PaintGradient(DC: HDC; const R: TRect; ColorFrom, ColorTo: TColor;
  Direction: TPPGGradientDirection);
var
  V: array[0..1] of TTriVertex;
  GR: TGradientRect;
  C1, C2: Cardinal;
  Mode: Cardinal;
begin
  C1 := ColorToRGB(ColorFrom);
  C2 := ColorToRGB(ColorTo);
  V[0].x := R.Left;
  V[0].y := R.Top;
  V[0].Red := GetRValue(C1) shl 8;
  V[0].Green := GetGValue(C1) shl 8;
  V[0].Blue := GetBValue(C1) shl 8;
  V[0].Alpha := 0;
  V[1].x := R.Right;
  V[1].y := R.Bottom;
  V[1].Red := GetRValue(C2) shl 8;
  V[1].Green := GetGValue(C2) shl 8;
  V[1].Blue := GetBValue(C2) shl 8;
  V[1].Alpha := 0;
  GR.UpperLeft := 0;
  GR.LowerRight := 1;
  if Direction = gdHorizontal then
    Mode := GRADIENT_FILL_RECT_H
  else
    Mode := GRADIENT_FILL_RECT_V;
  if not GradientFill(DC, @V[0], 2, @GR, 1, Mode) then
    PaintFillRoundRect(DC, R, 0, ColorFrom); // Fallback des Fallbacks
end;

procedure TPPGGdiCanvas.FillGradientRect(const R: TRect; ColorFrom, ColorTo: TColor;
  Direction: TPPGGradientDirection; Alpha: Byte);
var
  L: TPPGGdiLayer;
begin
  if (Alpha = 0) or IsRectEmpty(R) then
    Exit;
  if (Alpha < 255) and BeginLayer(R, L) then
    try
      PaintGradient(L.DC, R, ColorFrom, ColorTo, Direction);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintGradient(FDC, R, ColorFrom, ColorTo, Direction);
end;

procedure PaintFrameRoundRect(DC: HDC; const R: TRect; Radius, Width: Integer; Color: TColor;
  Square: TPPGCorners = []);
var
  Pen: HPEN;
  Brush: HBRUSH;
  Saved: Integer;
  C: TPPGCorner;
  B: TRect;
begin
  Pen := CreatePen(PS_INSIDEFRAME, Width, ColorToRGB(Color));
  if Pen = 0 then
    PPGRaiseLastOSError('CreatePen');
  try
    Saved := SaveDC(DC);
    try
      SelectObject(DC, Pen);
      SelectObject(DC, GetStockObject(NULL_BRUSH));
      if Radius <= 0 then
        Rectangle(DC, R.Left, R.Top, R.Right, R.Bottom)
      else
      begin
        // Eckige Ecken: Bogen dort ausblenden, danach gerade Kanten
        for C := Low(TPPGCorner) to High(TPPGCorner) do
          if C in Square then
          begin
            B := CornerBox(R, Radius, C);
            ExcludeClipRect(DC, B.Left, B.Top, B.Right, B.Bottom);
          end;
        RoundRect(DC, R.Left, R.Top, R.Right, R.Bottom, Radius * 2, Radius * 2);
      end;
    finally
      RestoreDC(DC, Saved);
    end;
    if (Radius > 0) and (Square <> []) then
    begin
      Brush := CreateSolidBrush(ColorToRGB(Color));
      if Brush = 0 then
        PPGRaiseLastOSError('CreateSolidBrush');
      try
        for C := Low(TPPGCorner) to High(TPPGCorner) do
          if C in Square then
          begin
            B := CornerBox(R, Radius, C);
            // waagerechte Kante
            if C in [pcTopLeft, pcTopRight] then
              Winapi.Windows.FillRect(DC, Rect(B.Left, B.Top, B.Right, Min(B.Bottom, B.Top + Width)), Brush)
            else
              Winapi.Windows.FillRect(DC, Rect(B.Left, Max(B.Top, B.Bottom - Width), B.Right, B.Bottom), Brush);
            // senkrechte Kante
            if C in [pcTopLeft, pcBottomLeft] then
              Winapi.Windows.FillRect(DC, Rect(B.Left, B.Top, Min(B.Right, B.Left + Width), B.Bottom), Brush)
            else
              Winapi.Windows.FillRect(DC, Rect(Max(B.Left, B.Right - Width), B.Top, B.Right, B.Bottom), Brush);
          end;
      finally
        DeleteObject(Brush);
      end;
    end;
  finally
    DeleteObject(Pen);
  end;
end;

procedure TPPGGdiCanvas.FrameRoundRect(const R: TRect; Radius, Width: Integer;
  Color: TColor; Alpha: Byte);
var
  L: TPPGGdiLayer;
begin
  if (Alpha = 0) or (Width <= 0) or IsRectEmpty(R) then
    Exit;
  if (Alpha < 255) and BeginLayer(R, L) then
    try
      PaintFrameRoundRect(L.DC, R, Radius, Width, Color, FSquare);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintFrameRoundRect(FDC, R, Radius, Width, Color, FSquare);
end;

procedure TPPGGdiCanvas.DrawOuterGlow(const R: TRect; Radius, Size: Integer; Color: TColor;
  Alpha: Byte);
var
  G: TRect;
begin
  // Ohne Alpha-Verlauf kein weicher Glow moeglich: bei deutlichem Glow 1px-Ring
  if (Size <= 0) or (Alpha < 64) then
    Exit;
  G := R;
  InflateRect(G, 1, 1);
  FrameRoundRect(G, Radius + 1, 1, Color, 255);
end;

procedure TPPGGdiCanvas.FillRadialGlow(const R: TRect; Color: TColor; Alpha: Byte);
begin
  // Im GDI-Fallback bewusst nicht dargestellt (rein dekorativ)
end;

procedure PaintFillEllipse(DC: HDC; const R: TRect; Color: TColor);
var
  Brush: HBRUSH;
  Saved: Integer;
begin
  Brush := CreateSolidBrush(ColorToRGB(Color));
  if Brush = 0 then
    PPGRaiseLastOSError('CreateSolidBrush');
  try
    Saved := SaveDC(DC);
    try
      SelectObject(DC, Brush);
      SelectObject(DC, GetStockObject(NULL_PEN));
      Ellipse(DC, R.Left, R.Top, R.Right + 1, R.Bottom + 1);
    finally
      RestoreDC(DC, Saved);
    end;
  finally
    DeleteObject(Brush);
  end;
end;

procedure TPPGGdiCanvas.FillEllipse(const R: TRect; Color: TColor; Alpha: Byte);
var
  L: TPPGGdiLayer;
begin
  if (Alpha = 0) or IsRectEmpty(R) then
    Exit;
  if (Alpha < 255) and BeginLayer(Rect(R.Left, R.Top, R.Right + 1, R.Bottom + 1), L) then
    try
      PaintFillEllipse(L.DC, R, Color);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintFillEllipse(FDC, R, Color);
end;

procedure PaintFrameEllipse(DC: HDC; const R: TRect; Width: Integer; Color: TColor);
var
  Pen: HPEN;
  Saved: Integer;
begin
  Pen := CreatePen(PS_INSIDEFRAME, Width, ColorToRGB(Color));
  if Pen = 0 then
    PPGRaiseLastOSError('CreatePen');
  try
    Saved := SaveDC(DC);
    try
      SelectObject(DC, Pen);
      SelectObject(DC, GetStockObject(NULL_BRUSH));
      Ellipse(DC, R.Left, R.Top, R.Right, R.Bottom);
    finally
      RestoreDC(DC, Saved);
    end;
  finally
    DeleteObject(Pen);
  end;
end;

procedure TPPGGdiCanvas.FrameEllipse(const R: TRect; Width: Integer; Color: TColor;
  Alpha: Byte);
var
  L: TPPGGdiLayer;
begin
  if (Alpha = 0) or (Width <= 0) or IsRectEmpty(R) then
    Exit;
  if (Alpha < 255) and BeginLayer(R, L) then
    try
      PaintFrameEllipse(L.DC, R, Width, Color);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintFrameEllipse(FDC, R, Width, Color);
end;

procedure PaintPolyline(DC: HDC; const Points: array of TPoint; Width: Integer; Color: TColor);
var
  Pen: HPEN;
  Saved: Integer;
begin
  Pen := CreatePen(PS_SOLID, Width, ColorToRGB(Color));
  if Pen = 0 then
    PPGRaiseLastOSError('CreatePen');
  try
    Saved := SaveDC(DC);
    try
      SelectObject(DC, Pen);
      Polyline(DC, Points[0], Length(Points));
    finally
      RestoreDC(DC, Saved);
    end;
  finally
    DeleteObject(Pen);
  end;
end;

procedure TPPGGdiCanvas.DrawPolyline(const Points: array of TPoint; Width: Integer;
  Color: TColor; Alpha: Byte);
var
  L: TPPGGdiLayer;
  B: TRect;
  I: Integer;
begin
  if (Alpha = 0) or (Width <= 0) or (Length(Points) < 2) then
    Exit;
  if Alpha < 255 then
  begin
    B := Rect(Points[0].X, Points[0].Y, Points[0].X, Points[0].Y);
    for I := 1 to High(Points) do
    begin
      if Points[I].X < B.Left then
        B.Left := Points[I].X;
      if Points[I].Y < B.Top then
        B.Top := Points[I].Y;
      if Points[I].X > B.Right then
        B.Right := Points[I].X;
      if Points[I].Y > B.Bottom then
        B.Bottom := Points[I].Y;
    end;
    InflateRect(B, Width + 1, Width + 1);
    if BeginLayer(B, L) then
    begin
      try
        PaintPolyline(L.DC, Points, Width, Color);
      finally
        EndLayer(L, Alpha);
      end;
      Exit;
    end;
  end;
  PaintPolyline(FDC, Points, Width, Color);
end;

function PointsBounds(const Points: array of TPoint; Margin: Integer): TRect;
var
  I: Integer;
begin
  Result := Rect(Points[0].X, Points[0].Y, Points[0].X, Points[0].Y);
  for I := 1 to High(Points) do
  begin
    if Points[I].X < Result.Left then
      Result.Left := Points[I].X;
    if Points[I].Y < Result.Top then
      Result.Top := Points[I].Y;
    if Points[I].X > Result.Right then
      Result.Right := Points[I].X;
    if Points[I].Y > Result.Bottom then
      Result.Bottom := Points[I].Y;
  end;
  InflateRect(Result, Margin, Margin);
end;

procedure PaintPolygon(DC: HDC; const Points: array of TPoint; Color: TColor);
var
  Brush: HBRUSH;
  Saved: Integer;
begin
  Brush := CreateSolidBrush(ColorToRGB(Color));
  if Brush = 0 then
    PPGRaiseLastOSError('CreateSolidBrush');
  try
    Saved := SaveDC(DC);
    try
      SelectObject(DC, Brush);
      SelectObject(DC, GetStockObject(NULL_PEN));
      SetPolyFillMode(DC, ALTERNATE);
      Polygon(DC, Points[0], Length(Points));
    finally
      RestoreDC(DC, Saved);
    end;
  finally
    DeleteObject(Brush);
  end;
end;

procedure TPPGGdiCanvas.FillPolygon(const Points: array of TPoint; Color: TColor;
  Alpha: Byte);
var
  L: TPPGGdiLayer;
begin
  if (Alpha = 0) or (Length(Points) < 3) then
    Exit;
  if (Alpha < 255) and BeginLayer(PointsBounds(Points, 1), L) then
    try
      PaintPolygon(L.DC, Points, Color);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintPolygon(FDC, Points, Color);
end;

procedure PaintDashes(DC: HDC; const Points: array of TPoint;
  Width, Dash, Gap: Integer; Color: TColor);
var
  I: Integer;
  SegLen, Pos, Phase, Take: Double;
  DX, DY: Double;
  OnDash: Boolean;
  A, B: TPoint;
begin
  // GDI-Stifte koennen Muster nur bei 1 px Breite; deshalb selbst zerlegen
  OnDash := True;
  Phase := Dash; // Rest des aktuellen Abschnitts (Strich oder Luecke)
  for I := 0 to High(Points) - 1 do
  begin
    DX := Points[I + 1].X - Points[I].X;
    DY := Points[I + 1].Y - Points[I].Y;
    SegLen := Sqrt(DX * DX + DY * DY);
    Pos := 0;
    while Pos < SegLen do
    begin
      Take := Phase;
      if Pos + Take > SegLen then
        Take := SegLen - Pos;
      if OnDash and (SegLen > 0) then
      begin
        A := Point(Points[I].X + Round(DX * Pos / SegLen), Points[I].Y + Round(DY * Pos / SegLen));
        B := Point(Points[I].X + Round(DX * (Pos + Take) / SegLen),
          Points[I].Y + Round(DY * (Pos + Take) / SegLen));
        PaintPolyline(DC, [A, B], Width, Color);
      end;
      Pos := Pos + Take;
      Phase := Phase - Take;
      if Phase <= 0 then
      begin
        OnDash := not OnDash;
        if OnDash then
          Phase := Dash
        else
          Phase := Gap;
      end;
    end;
  end;
end;

procedure TPPGGdiCanvas.DrawDashedPolyline(const Points: array of TPoint;
  Width, Dash, Gap: Integer; Color: TColor; Alpha: Byte);
var
  L: TPPGGdiLayer;
begin
  if (Alpha = 0) or (Width <= 0) or (Length(Points) < 2) then
    Exit;
  if Dash < 1 then
    Dash := 1;
  if Gap < 1 then
    Gap := 1;
  // Eine Ebene fuer die ganze Linie statt einer je Strich: sonst entsteht
  // pro Strich ein Speicher-DC mit Bitmap, und Striche, die sich an Ecken
  // ueberlappen, wuerden doppelt geblendet.
  if (Alpha < 255) and BeginLayer(PointsBounds(Points, Width + 1), L) then
    try
      PaintDashes(L.DC, Points, Width, Dash, Gap, Color);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintDashes(FDC, Points, Width, Dash, Gap, Color);
end;

function TPPGGdiCanvas.GetSquareCorners: TPPGCorners;
begin
  Result := FSquare;
end;

procedure TPPGGdiCanvas.SetSquareCorners(Corners: TPPGCorners);
begin
  FSquare := Corners;
end;

procedure TPPGGdiCanvas.AddSquareCorners(Rgn: HRGN; const R: TRect; Radius: Integer);
var
  C: TPPGCorner;
  B: TRect;
  Box: HRGN;
begin
  for C := Low(TPPGCorner) to High(TPPGCorner) do
    if C in FSquare then
    begin
      B := CornerBox(R, Radius, C);
      // Region ist rechts/unten exklusiv
      Box := CreateRectRgn(B.Left, B.Top, B.Right + Ord(C in [pcTopRight, pcBottomRight]),
        B.Bottom + Ord(C in [pcBottomLeft, pcBottomRight]));
      if Box <> 0 then
      try
        CombineRgn(Rgn, Rgn, Box, RGN_OR);
      finally
        DeleteObject(Box);
      end;
    end;
end;

procedure TPPGGdiCanvas.PushClipRoundRect(const R: TRect; Radius: Integer);
var
  Rgn: HRGN;
  P: array[0..1] of TPoint;
begin
  SaveDC(FDC);
  Inc(FClipDepth);
  // Regionen sind in Geraetekoordinaten: ein verschobener Ursprung
  // (SetViewportOrgEx/SetWindowOrgEx, z.B. beim Drucken) muss umgerechnet werden
  if Radius <= 0 then
  begin
    IntersectClipRect(FDC, R.Left, R.Top, R.Right, R.Bottom);
    Exit;
  end;
  P[0] := R.TopLeft;
  P[1] := Point(R.Right + 1, R.Bottom + 1);
  LPtoDP(FDC, P, 2);
  Rgn := CreateRoundRectRgn(P[0].X, P[0].Y, P[1].X, P[1].Y, Radius * 2, Radius * 2);
  if Rgn = 0 then
    Exit; // ohne Clipping weiterzeichnen ist besser als ein Abbruch
  AddSquareCorners(Rgn, Rect(P[0].X, P[0].Y, P[1].X - 1, P[1].Y - 1), Radius);
  try
    ExtSelectClipRgn(FDC, Rgn, RGN_AND);
  finally
    DeleteObject(Rgn);
  end;
end;

procedure TPPGGdiCanvas.PopClip;
begin
  if FClipDepth <= 0 then
    Exit;
  Dec(FClipDepth);
  RestoreDC(FDC, -1);
end;

function TPPGGdiCanvas.MeasureText(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
begin
  Result := PPGGdiMeasureText(FDC, Text, Font, MaxWidth, WordWrap);
end;

procedure TPPGGdiCanvas.DrawText(const R: TRect; const Text: string; Font: TFont;
  Color: TColor; Flags: Cardinal);
begin
  PPGGdiDrawText(FDC, R, Text, Font, Color, Flags);
end;

procedure TPPGGdiCanvas.DrawImage(Images: TCustomImageList; Index, X, Y: Integer;
  Enabled: Boolean);
begin
  PPGGdiDrawImage(FDC, Images, Index, X, Y, Enabled);
end;

procedure TPPGGdiCanvas.DrawFocusRect(const R: TRect);
begin
  PPGGdiDrawFocusRect(FDC, R);
end;

function TPPGGdiCanvas.BeginGdi: HDC;
begin
  // Zustand sichern: fremder Code darf Stift, Pinsel, Schrift frei setzen
  SaveDC(FDC);
  Result := FDC;
end;

procedure TPPGGdiCanvas.EndGdi(DC: HDC);
begin
  RestoreDC(DC, -1);
end;

initialization

finalization
  GFinalized := True;
  if GMeasureDC <> 0 then
    DeleteDC(GMeasureDC);
  GMeasureDC := 0;
  FreeAndNil(GMeasureCache);
  FreeAndNil(GTintWatcher);
  FreeAndNil(GTintCache);

end.
