unit PPG.Render.GdiPlus;

{ GDI+-Canvas mit Antialiasing und Alpha.

  STOLPERSTEIN GDI+-Startup: Winapi.GDIPOBJ startet GDI+ in seiner
  initialization nur "if not IsLibrary". In DLLs, ActiveX-Controls und
  Plugins ist GDI+ deshalb NICHT gestartet. Ausserdem darf GdiplusStartup /
  GdiplusShutdown laut Microsoft nicht in DllMain laufen.
  Loesung:
  - Eigener, verzoegerter Startup beim ersten Zeichnen (nie in DllMain).
  - Shutdown in finalization nur, wenn wir NICHT in einer reinen DLL laufen
    (Packages sind ok, deren finalization laeuft nicht in DllMain).
  - Schlaegt der Startup fehl, wird dauerhaft der GDI-Fallback genutzt. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.ImgList,
  Winapi.GDIPAPI, Winapi.GDIPOBJ,
  PPG.Types, PPG.Render.Intf;

type
  TPPGGdiPlusCanvas = class(TInterfacedObject, IPPGCanvas, IPPGShapeCanvas, IPPGCornerCanvas,
    IPPGBatchCanvas)
  private
    FSquare: TPPGCorners;
    FDC: HDC;
    FGraphics: TGPGraphics;
    FClipStates: array of GraphicsState;
    FGdiSaved: Integer; // SaveDC-Index, solange der DC ausgeliehen ist
    FHeldDC: HDC;       // ausgeliehener DC (GetHDC), 0 = Graphics frei
    FGdiUse: Integer;   // offene GdiBegin (verschachtelbar)
    FBatch: Integer;    // offene BeginBatch
    procedure Check(Status: TStatus; const Call: string);
    function NewRoundRectPath(X, Y, W, H, Radius: Single): TGPGraphicsPath;
    function GdiBegin: HDC;
    procedure GdiEnd(DC: HDC);
    procedure AcquireDC;
    procedure ReleaseHeldDC;
    /// Vor jedem GDI+-Aufruf: einen im Block gehaltenen DC zurueckgeben.
    procedure NeedGraphics;
  public
    constructor Create(ADC: HDC);
    /// Zeichnet in ein GDI+-Bild (z.B. 32 Bit mit Alpha, Schatten-Vorlage).
    constructor CreateForImage(AImage: TGPImage);
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
    { IPPGBatchCanvas }
    procedure BeginBatch;
    procedure EndBatch;
  end;

/// Startet GDI+ bei Bedarf. False = nicht verfuegbar (GDI-Fallback nutzen).
function PPGGdiPlusAvailable: Boolean;
/// Speichert ein GDI-Bitmap als PNG ueber den GDI+-Encoder (ohne vclimg/
/// Vcl.Imaging.pngimage). EPPGRenderError, wenn GDI+ fehlt oder scheitert.
procedure PPGSaveBitmapAsPng(Bitmap: HBITMAP; const FileName: string);
/// Audit 8a #7: gestapelter Schatten (Size Ringe FillRoundRect mit Alpha um R,
/// Radius + I) aus einer zwischengespeicherten Neun-Teile-Vorlage je
/// (Radius, Size, Farbe, Alpha, eckige Ecken). False = nicht moeglich
/// (kein Antialiasing, Flaeche zu klein, Cache aus): dann direkt zeichnen.
function PPGDrawCachedShadow(const Canvas: IPPGCanvas; const R: TRect; Radius, Size: Integer;
  Color: TColor; Alpha: Byte): Boolean;

var
  /// Testhaken: False = Schatten immer direkt zeichnen (Vergleich).
  PPGShadowCacheEnabled: Boolean = True;

/// Fuer DLL-Hosts: GDI+ explizit vor dem Entladen der DLL beenden
/// (ausserhalb von DllMain aufrufen!).
procedure PPGGdiPlusShutdown;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Generics.Collections, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler,
  PPG.Render.Gdi;

type
  TPPGGdiplusStartupInput = record
    GdiplusVersion: Cardinal;
    DebugEventCallback: Pointer;
    SuppressBackgroundThread: BOOL;
    SuppressExternalCodecs: BOOL;
  end;

// Eigene Importe: Token-Typ ist versionsunabhaengig NativeUInt
// (aeltere GDIPAPI-Versionen deklarieren ihn unterschiedlich).
function PPG_GdiplusStartup(out Token: NativeUInt; Input: Pointer;
  Output: Pointer): Integer; stdcall; external 'gdiplus.dll' name 'GdiplusStartup';
procedure PPG_GdiplusShutdown(Token: NativeUInt); stdcall;
  external 'gdiplus.dll' name 'GdiplusShutdown';

type
  TGdiPlusState = (gpsUnknown, gpsStarted, gpsFailed);

var
  GState: TGdiPlusState = gpsUnknown;
  GToken: NativeUInt = 0;

var
  GShadowCache: TDictionary<string, TArray<Cardinal>> = nil;

function PPGGdiPlusAvailable: Boolean;
var
  Input: TPPGGdiplusStartupInput;
  Status: Integer;
begin
  if GState = gpsUnknown then
  begin
    FillChar(Input, SizeOf(Input), 0);
    Input.GdiplusVersion := 1;
    Status := PPG_GdiplusStartup(GToken, @Input, nil);
    if Status = 0 then
      GState := gpsStarted
    else
    begin
      GState := gpsFailed;
      TPPGErrorHandler.LogWarning(nil, Format(PPGStr(@SPPGGdiPlusStartupFailed), [Status]));
    end;
  end;
  Result := GState = gpsStarted;
end;

procedure PPGGdiPlusShutdown;
begin
  if GState = gpsStarted then
  begin
    GState := gpsFailed; // danach nur noch GDI-Fallback
    PPG_GdiplusShutdown(GToken);
    GToken := 0;
  end;
end;

function ToARGB(Color: TColor; Alpha: Byte): ARGB;
var
  C: Cardinal;
begin
  C := ColorToRGB(Color);
  Result := MakeColor(Alpha, GetRValue(C), GetGValue(C), GetBValue(C));
end;

procedure PPGSaveBitmapAsPng(Bitmap: HBITMAP; const FileName: string);
const
  // CLSID des eingebauten PNG-Encoders von GDI+ (fest seit Windows XP)
  PngEncoder: TGUID = '{557CF406-1A04-11D3-9A73-0000F81EF32E}';
var
  B: TGPBitmap;
  S: TStatus;
begin
  if not PPGGdiPlusAvailable then
    raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), ['GdiplusStartup', -1]);
  B := TGPBitmap.Create(Bitmap, 0);
  try
    S := B.GetLastStatus;
    if S <> Ok then
      raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed),
        ['GdipCreateBitmapFromHBITMAP', Ord(S)]);
    S := B.Save(FileName, PngEncoder);
    if S <> Ok then
      raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed),
        ['GdipSaveImageToFile', Ord(S)]);
  finally
    B.Free;
  end;
end;

{ TPPGGdiPlusCanvas }

constructor TPPGGdiPlusCanvas.Create(ADC: HDC);
begin
  inherited Create;
  FDC := ADC;
  if not PPGGdiPlusAvailable then
    raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), ['GdiplusStartup', -1]);
  FGraphics := TGPGraphics.Create(ADC);
  Check(FGraphics.GetLastStatus, 'Graphics.Create');
  FGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
  FGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
end;

constructor TPPGGdiPlusCanvas.CreateForImage(AImage: TGPImage);
begin
  inherited Create;
  FDC := 0;
  if not PPGGdiPlusAvailable then
    raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), ['GdiplusStartup', -1]);
  FGraphics := TGPGraphics.Create(AImage);
  Check(FGraphics.GetLastStatus, 'Graphics.Create');
  FGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
  FGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
end;

destructor TPPGGdiPlusCanvas.Destroy;
begin
  // Wirft ein Konstruktor, ist FGraphics evtl. nil -> nil-sicher freigeben
  if FGraphics <> nil then
    ReleaseHeldDC; // unausgeglichener Block (z.B. nach Exception)
  if (FGraphics <> nil) and (Length(FClipStates) > 0) then
    FGraphics.Restore(FClipStates[0]);
  FGraphics.Free;
  inherited Destroy;
end;

procedure TPPGGdiPlusCanvas.Check(Status: TStatus; const Call: string);
begin
  if Status <> Ok then
    raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), [Call, Ord(Status)]);
end;

function TPPGGdiPlusCanvas.IsAntialiased: Boolean;
begin
  Result := True;
end;

function TPPGGdiPlusCanvas.GetSquareCorners: TPPGCorners;
begin
  Result := FSquare;
end;

procedure TPPGGdiPlusCanvas.SetSquareCorners(Corners: TPPGCorners);
begin
  FSquare := Corners;
end;

function TPPGGdiPlusCanvas.NewRoundRectPath(X, Y, W, H, Radius: Single): TGPGraphicsPath;
var
  D: Single;
begin
  Result := TGPGraphicsPath.Create;
  try
    Check(Result.GetLastStatus, 'GraphicsPath.Create');
    if W < 0 then
      W := 0;
    if H < 0 then
      H := 0;
    D := Radius * 2;
    if D > W then
      D := W;
    if D > H then
      D := H;
    if D <= 0.5 then
      Result.AddRectangle(MakeRect(X, Y, W, H))
    else
    begin
      // Eckige Ecken (IPPGCornerCanvas): Punkt statt Bogen
      if pcTopLeft in FSquare then
        Result.AddLine(X, Y, X, Y)
      else
        Result.AddArc(X, Y, D, D, 180, 90);
      if pcTopRight in FSquare then
        Result.AddLine(X + W, Y, X + W, Y)
      else
        Result.AddArc(X + W - D, Y, D, D, 270, 90);
      if pcBottomRight in FSquare then
        Result.AddLine(X + W, Y + H, X + W, Y + H)
      else
        Result.AddArc(X + W - D, Y + H - D, D, D, 0, 90);
      if pcBottomLeft in FSquare then
        Result.AddLine(X, Y + H, X, Y + H)
      else
        Result.AddArc(X, Y + H - D, D, D, 90, 90);
      Result.CloseFigure;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TPPGGdiPlusCanvas.FillRoundRect(const R: TRect; Radius: Integer; Color: TColor;
  Alpha: Byte);
var
  Path: TGPGraphicsPath;
  Brush: TGPSolidBrush;
begin
  if (Alpha = 0) or IsRectEmpty(R) then
    Exit;
  NeedGraphics;
  if Radius <= 0 then
  begin
    // Audit 8a #5: ohne Rundung kein Pfad (gleiche Pixel wie das Pfad-Rechteck)
    Brush := TGPSolidBrush.Create(ToARGB(Color, Alpha));
    try
      Check(FGraphics.FillRectangle(Brush, MakeRect(R.Left * 1.0, R.Top * 1.0,
        R.Right - R.Left * 1.0, R.Bottom - R.Top * 1.0)), 'FillRectangle');
    finally
      Brush.Free;
    end;
    Exit;
  end;
  Path := NewRoundRectPath(R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, Radius);
  try
    Brush := TGPSolidBrush.Create(ToARGB(Color, Alpha));
    try
      Check(FGraphics.FillPath(Brush, Path), 'FillPath');
    finally
      Brush.Free;
    end;
  finally
    Path.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.FillGradientRect(const R: TRect; ColorFrom, ColorTo: TColor;
  Direction: TPPGGradientDirection; Alpha: Byte);
var
  Brush: TGPLinearGradientBrush;
  Mode: LinearGradientMode;
  GR: TGPRectF;
begin
  if (Alpha = 0) or IsRectEmpty(R) then
    Exit;
  NeedGraphics;
  if Direction = gdHorizontal then
    Mode := LinearGradientModeHorizontal
  else
    Mode := LinearGradientModeVertical;
  GR := MakeRect(R.Left * 1.0, R.Top * 1.0, R.Right - R.Left * 1.0, R.Bottom - R.Top * 1.0);
  // Brush-Rechteck minimal groesser: verhindert die bekannte GDI+-Randlinie
  // in der Startfarbe der Gegenseite (Wrap-Artefakt)
  Brush := TGPLinearGradientBrush.Create(MakeRect(GR.X - 0.5, GR.Y - 0.5, GR.Width + 1, GR.Height + 1),
    ToARGB(ColorFrom, Alpha), ToARGB(ColorTo, Alpha), Mode);
  try
    Check(Brush.GetLastStatus, 'LinearGradientBrush.Create');
    Check(FGraphics.FillRectangle(Brush, GR), 'FillRectangle');
  finally
    Brush.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.FrameRoundRect(const R: TRect; Radius, Width: Integer;
  Color: TColor; Alpha: Byte);
var
  Path: TGPGraphicsPath;
  Pen: TGPPen;
  Half: Single;
begin
  if (Alpha = 0) or (Width <= 0) or IsRectEmpty(R) then
    Exit;
  NeedGraphics;
  // Stift liegt mittig auf dem Pfad -> um halbe Breite nach innen versetzen
  Half := Width / 2;
  Path := NewRoundRectPath(R.Left + Half, R.Top + Half, R.Right - R.Left - Width,
    R.Bottom - R.Top - Width, Radius - Half);
  try
    Pen := TGPPen.Create(ToARGB(Color, Alpha), Width);
    try
      Check(FGraphics.DrawPath(Pen, Path), 'DrawPath');
    finally
      Pen.Free;
    end;
  finally
    Path.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.DrawOuterGlow(const R: TRect; Radius, Size: Integer;
  Color: TColor; Alpha: Byte);
var
  I: Integer;
  Path: TGPGraphicsPath;
  Pen: TGPPen;
  T: Single;
  A: Integer;
begin
  if (Alpha = 0) or (Size <= 0) or IsRectEmpty(R) then
    Exit;
  NeedGraphics;
  // Konzentrische Ringe mit quadratisch abnehmender Deckkraft
  for I := 1 to Size do
  begin
    T := 1 - (I - 1) / Size;
    A := Round(Alpha * T * T * 0.55);
    if A <= 0 then
      Continue;
    Path := NewRoundRectPath(R.Left - I + 0.5, R.Top - I + 0.5,
      R.Right - R.Left + 2 * I - 1, R.Bottom - R.Top + 2 * I - 1, Radius + I);
    try
      Pen := TGPPen.Create(ToARGB(Color, A), 1.0);
      try
        Check(FGraphics.DrawPath(Pen, Path), 'DrawPath(Glow)');
      finally
        Pen.Free;
      end;
    finally
      Path.Free;
    end;
  end;
end;

procedure TPPGGdiPlusCanvas.FillRadialGlow(const R: TRect; Color: TColor; Alpha: Byte);
var
  Path: TGPGraphicsPath;
  Brush: TGPPathGradientBrush;
  Surround: ARGB;
  Count: Integer;
begin
  if (Alpha = 0) or IsRectEmpty(R) then
    Exit;
  NeedGraphics;
  Path := TGPGraphicsPath.Create;
  try
    Check(Path.AddEllipse(MakeRect(R.Left * 1.0, R.Top * 1.0, R.Right - R.Left * 1.0,
      R.Bottom - R.Top * 1.0)), 'AddEllipse');
    Brush := TGPPathGradientBrush.Create(Path);
    try
      Check(Brush.GetLastStatus, 'PathGradientBrush.Create');
      Brush.SetCenterColor(ToARGB(Color, Alpha));
      Surround := ToARGB(Color, 0);
      Count := 1;
      Brush.SetSurroundColors(@Surround, Count);
      Check(FGraphics.FillPath(Brush, Path), 'FillPath(Radial)');
    finally
      Brush.Free;
    end;
  finally
    Path.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.FillEllipse(const R: TRect; Color: TColor; Alpha: Byte);
var
  Brush: TGPSolidBrush;
begin
  if (Alpha = 0) or IsRectEmpty(R) then
    Exit;
  NeedGraphics;
  Brush := TGPSolidBrush.Create(ToARGB(Color, Alpha));
  try
    Check(FGraphics.FillEllipse(Brush, MakeRect(R.Left * 1.0, R.Top * 1.0,
      R.Right - R.Left * 1.0, R.Bottom - R.Top * 1.0)), 'FillEllipse');
  finally
    Brush.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.FrameEllipse(const R: TRect; Width: Integer; Color: TColor;
  Alpha: Byte);
var
  Pen: TGPPen;
  Half: Single;
begin
  if (Alpha = 0) or (Width <= 0) or IsRectEmpty(R) then
    Exit;
  NeedGraphics;
  Half := Width / 2;
  Pen := TGPPen.Create(ToARGB(Color, Alpha), Width);
  try
    Check(FGraphics.DrawEllipse(Pen, MakeRect(R.Left + Half, R.Top + Half,
      R.Right - R.Left - Width * 1.0, R.Bottom - R.Top - Width * 1.0)), 'DrawEllipse');
  finally
    Pen.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.DrawPolyline(const Points: array of TPoint; Width: Integer;
  Color: TColor; Alpha: Byte);
var
  Pts: array of TGPPointF;
  Pen: TGPPen;
  I: Integer;
begin
  if (Alpha = 0) or (Width <= 0) or (Length(Points) < 2) then
    Exit;
  NeedGraphics;
  SetLength(Pts, Length(Points));
  for I := 0 to High(Points) do
  begin
    Pts[I].X := Points[I].X;
    Pts[I].Y := Points[I].Y;
  end;
  Pen := TGPPen.Create(ToARGB(Color, Alpha), Width);
  try
    Pen.SetLineJoin(LineJoinRound);
    Pen.SetStartCap(LineCapRound);
    Pen.SetEndCap(LineCapRound);
    Check(FGraphics.DrawLines(Pen, PGPPointF(@Pts[0]), Length(Pts)), 'DrawLines');
  finally
    Pen.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.FillPolygon(const Points: array of TPoint; Color: TColor;
  Alpha: Byte);
var
  Pts: array of TGPPointF;
  Brush: TGPSolidBrush;
  I: Integer;
begin
  if (Alpha = 0) or (Length(Points) < 3) then
    Exit;
  NeedGraphics;
  SetLength(Pts, Length(Points));
  for I := 0 to High(Points) do
  begin
    Pts[I].X := Points[I].X;
    Pts[I].Y := Points[I].Y;
  end;
  Brush := TGPSolidBrush.Create(ToARGB(Color, Alpha));
  try
    Check(FGraphics.FillPolygon(Brush, PGPPointF(@Pts[0]), Length(Pts)), 'FillPolygon');
  finally
    Brush.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.DrawDashedPolyline(const Points: array of TPoint;
  Width, Dash, Gap: Integer; Color: TColor; Alpha: Byte);
var
  Pts: array of TGPPointF;
  Pattern: array[0..1] of Single;
  Pen: TGPPen;
  I: Integer;
begin
  if (Alpha = 0) or (Width <= 0) or (Length(Points) < 2) then
    Exit;
  NeedGraphics;
  if Dash < 1 then
    Dash := 1;
  if Gap < 1 then
    Gap := 1;
  SetLength(Pts, Length(Points));
  for I := 0 to High(Points) do
  begin
    Pts[I].X := Points[I].X;
    Pts[I].Y := Points[I].Y;
  end;
  Pen := TGPPen.Create(ToARGB(Color, Alpha), Width);
  try
    // Muster ist relativ zur Strichstaerke
    Pattern[0] := Dash / Width;
    Pattern[1] := Gap / Width;
    Check(Pen.SetDashPattern(@Pattern[0], 2), 'SetDashPattern');
    Check(FGraphics.DrawLines(Pen, PGPPointF(@Pts[0]), Length(Pts)), 'DrawLines');
  finally
    Pen.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.PushClipRoundRect(const R: TRect; Radius: Integer);
var
  Path: TGPGraphicsPath;
  N: Integer;
begin
  NeedGraphics;
  N := Length(FClipStates);
  SetLength(FClipStates, N + 1);
  FClipStates[N] := FGraphics.Save;
  Path := NewRoundRectPath(R.Left, R.Top, R.Right - R.Left, R.Bottom - R.Top, Radius);
  try
    Check(FGraphics.SetClip(Path, CombineModeIntersect), 'SetClip');
  finally
    Path.Free;
  end;
end;

procedure TPPGGdiPlusCanvas.PopClip;
var
  N: Integer;
begin
  NeedGraphics;
  N := Length(FClipStates);
  if N = 0 then
    Exit;
  FGraphics.Restore(FClipStates[N - 1]);
  SetLength(FClipStates, N - 1);
end;

procedure TPPGGdiPlusCanvas.AcquireDC;
var
  Region: TGPRegion;
  Rgn, Old: HRGN;
  DC: HDC;
begin
  // GDI+ puffert Operationen: vor GDI-Zugriff auf denselben DC muss der
  // DC ueber GetHDC "ausgeliehen" werden.
  // STOLPERSTEIN: GetHDC uebertraegt die GDI+-Clipregion NICHT auf den DC.
  // Ohne die Uebernahme hier ignorieren Text und Bilder jedes PushClip
  // (z.B. zweifarbiger Text im ProgressBar). Die Region wird deshalb VOR
  // GetHDC gelesen (danach ist das Graphics-Objekt gesperrt) und als
  // GDI-Clip gesetzt; ReleaseHeldDC stellt den DC wieder her.
  Rgn := 0;
  if Length(FClipStates) > 0 then
  begin
    Region := TGPRegion.Create;
    try
      Check(FGraphics.GetClip(Region), 'GetClip');
      Rgn := Region.GetHRGN(FGraphics);
    finally
      Region.Free;
    end;
  end;
  try
    DC := FGraphics.GetHDC;
    if DC = 0 then
      raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), ['GetHDC', Ord(FGraphics.GetLastStatus)]);
    FHeldDC := DC;
    FGdiSaved := SaveDC(DC);
    if Rgn <> 0 then
    begin
      // Audit 8a #1: ein vorhandener Clip des DCs (neu zu zeichnender
      // Bereich) bleibt bestehen - Schnittmenge statt Ersetzen
      Old := CreateRectRgn(0, 0, 0, 0);
      if Old <> 0 then
      try
        if GetClipRgn(DC, Old) = 1 then
          CombineRgn(Rgn, Rgn, Old, RGN_AND);
      finally
        DeleteObject(Old);
      end;
      SelectClipRgn(DC, Rgn);
    end;
  finally
    if Rgn <> 0 then
      DeleteObject(Rgn); // SelectClipRgn arbeitet mit einer Kopie
  end;
end;

procedure TPPGGdiPlusCanvas.ReleaseHeldDC;
var
  DC: HDC;
begin
  if FHeldDC = 0 then
    Exit;
  DC := FHeldDC;
  FHeldDC := 0;
  FGdiUse := 0;
  if FGdiSaved <> 0 then
  begin
    RestoreDC(DC, FGdiSaved);
    FGdiSaved := 0;
  end;
  FGraphics.ReleaseHDC(DC);
end;

procedure TPPGGdiPlusCanvas.NeedGraphics;
begin
  // Im Block (BeginBatch) bleibt der DC zwischen GDI-Ausgaben ausgeliehen;
  // GDI+ selbst ist so lange gesperrt. Waehrend BeginGdi (FGdiUse > 0) wird
  // nichts zurueckgegeben (fremder Code haelt den DC).
  if (FHeldDC <> 0) and (FGdiUse = 0) then
    ReleaseHeldDC;
end;

function TPPGGdiPlusCanvas.GdiBegin: HDC;
begin
  // Verschachtelbar: solange der DC ausgeliehen ist, denselben weitergeben
  if FHeldDC = 0 then
    AcquireDC;
  Inc(FGdiUse);
  Result := FHeldDC;
end;

procedure TPPGGdiPlusCanvas.GdiEnd(DC: HDC);
begin
  if FGdiUse > 0 then
    Dec(FGdiUse);
  if (FGdiUse = 0) and (FBatch = 0) then
    ReleaseHeldDC;
end;

procedure TPPGGdiPlusCanvas.BeginBatch;
begin
  Inc(FBatch);
end;

procedure TPPGGdiPlusCanvas.EndBatch;
begin
  if FBatch > 0 then
    Dec(FBatch);
  if (FBatch = 0) and (FGdiUse = 0) then
    ReleaseHeldDC;
end;

function TPPGGdiPlusCanvas.MeasureText(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
var
  DC: HDC;
begin
  DC := GdiBegin;
  try
    Result := PPGGdiMeasureText(DC, Text, Font, MaxWidth, WordWrap);
  finally
    GdiEnd(DC);
  end;
end;

procedure TPPGGdiPlusCanvas.DrawText(const R: TRect; const Text: string; Font: TFont;
  Color: TColor; Flags: Cardinal);
var
  DC: HDC;
begin
  // Text bewusst per GDI: ClearType-Darstellung identisch zu Standard-Controls
  DC := GdiBegin;
  try
    PPGGdiDrawText(DC, R, Text, Font, Color, Flags);
  finally
    GdiEnd(DC);
  end;
end;

procedure TPPGGdiPlusCanvas.DrawImage(Images: TCustomImageList; Index, X, Y: Integer;
  Enabled: Boolean);
var
  DC: HDC;
begin
  DC := GdiBegin;
  try
    PPGGdiDrawImage(DC, Images, Index, X, Y, Enabled);
  finally
    GdiEnd(DC);
  end;
end;

procedure TPPGGdiPlusCanvas.DrawFocusRect(const R: TRect);
var
  DC: HDC;
begin
  DC := GdiBegin;
  try
    PPGGdiDrawFocusRect(DC, R);
  finally
    GdiEnd(DC);
  end;
end;

function TPPGGdiPlusCanvas.BeginGdi: HDC;
begin
  Result := GdiBegin;
  SaveDC(Result); // fremder Code darf Stift, Pinsel, Schrift frei setzen
end;

procedure TPPGGdiPlusCanvas.EndGdi(DC: HDC);
begin
  RestoreDC(DC, -1);
  GdiEnd(DC);
end;

/// Vorlage: Koerper 2 * Radius + 3 breit/hoch, Ringe wie PaintShadow, als
/// vormultiplizierte BGRA-Pixel (Breite = Hoehe = 2 * (Size + Radius + 1) + 1).
function BuildShadowTemplate(Radius, Size: Integer; Color: TColor; Alpha: Byte;
  Square: TPPGCorners): TArray<Cardinal>;
var
  Bmp: TGPBitmap;
  Cv: TPPGGdiPlusCanvas;
  CvRef: IPPGCanvas;
  Data: TBitmapData;
  T, Wb, I, Y: Integer;
  Body, SR: TRect;
  Src: PByte;
begin
  Wb := 2 * Radius + 3;
  T := Wb + 2 * Size;
  SetLength(Result, T * T);
  Bmp := TGPBitmap.Create(T, T, PixelFormat32bppPARGB);
  try
    if Bmp.GetLastStatus <> Ok then
      raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), ['Bitmap.Create', Ord(Bmp.GetLastStatus)]);
    Cv := TPPGGdiPlusCanvas.CreateForImage(Bmp);
    CvRef := Cv; // Referenzzaehlung: gibt den Canvas am Ende frei
    Cv.FGraphics.Clear(0); // durchsichtig
    Cv.SetSquareCorners(Square);
    Body := Rect(Size, Size, Size + Wb, Size + Wb);
    for I := Size downto 1 do
    begin
      SR := Body;
      InflateRect(SR, I, I);
      Cv.FillRoundRect(SR, Radius + I, Color, Alpha);
    end;
    CvRef := nil; // Graphics freigeben, bevor die Pixel gelesen werden
    if Bmp.LockBits(MakeRect(0, 0, T, T), ImageLockModeRead, PixelFormat32bppPARGB, Data) <> Ok then
      raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), ['LockBits', Ord(Bmp.GetLastStatus)]);
    try
      Src := Data.Scan0;
      for Y := 0 to T - 1 do
      begin
        Move(Src^, Result[Y * T], T * 4);
        Inc(Src, Data.Stride);
      end;
    finally
      Bmp.UnlockBits(Data);
    end;
  finally
    Bmp.Free;
  end;
end;

function PPGDrawCachedShadow(const Canvas: IPPGCanvas; const R: TRect; Radius, Size: Integer;
  Color: TColor; Alpha: Byte): Boolean;
var
  CC: IPPGCornerCanvas;
  Square: TPPGCorners;
  Key: string;
  Px: TArray<Cardinal>;
  K, T, Wb, OW, OH: Integer;
  O: TRect;
  DC, MemDC: HDC;
  Bmp, OldBmp: HBITMAP;
  BI: TBitmapInfo;
  Bits: Pointer;
  BF: TBlendFunction;

  procedure Blit(DX, DY, DW, DH, SX, SY, SW, SH: Integer);
  begin
    if (DW > 0) and (DH > 0) then
      Winapi.Windows.AlphaBlend(DC, DX, DY, DW, DH, MemDC, SX, SY, SW, SH, BF);
  end;

begin
  Result := False;
  if not PPGShadowCacheEnabled or (Canvas = nil) or not Canvas.IsAntialiased or
    (Size <= 0) or (Alpha = 0) or (GetCurrentThreadId <> MainThreadID) then
    Exit;
  if Radius < 0 then
    Radius := 0;
  // Gerade Kanten muessen gleichmaessig sein: Koerper mindestens so gross
  // wie die Vorlage (keine gekappte Rundung)
  Wb := 2 * Radius + 3;
  if (R.Right - R.Left < Wb) or (R.Bottom - R.Top < Wb) then
    Exit;
  Square := [];
  if Supports(Canvas, IPPGCornerCanvas, CC) then
    Square := CC.GetSquareCorners;
  Key := Format('%d|%d|%d|%d|%d', [Radius, Size, Integer(ColorToRGB(Color)), Alpha,
    Integer(Byte(Square))]);
  if GShadowCache = nil then
    GShadowCache := TDictionary<string, TArray<Cardinal>>.Create;
  if not GShadowCache.TryGetValue(Key, Px) then
  begin
    Px := BuildShadowTemplate(Radius, Size, Color, Alpha, Square);
    if GShadowCache.Count >= 64 then
      GShadowCache.Clear;
    GShadowCache.Add(Key, Px);
  end;
  T := Wb + 2 * Size;
  K := Size + Radius + 1; // Ecke inkl. Rundung, ab dort sind die Kanten gleichmaessig
  O := R;
  InflateRect(O, Size, Size);
  OW := O.Right - O.Left;
  OH := O.Bottom - O.Top;
  FillChar(BI, SizeOf(BI), 0);
  BI.bmiHeader.biSize := SizeOf(BI.bmiHeader);
  BI.bmiHeader.biWidth := T;
  BI.bmiHeader.biHeight := -T;
  BI.bmiHeader.biPlanes := 1;
  BI.bmiHeader.biBitCount := 32;
  BI.bmiHeader.biCompression := BI_RGB;
  BF.BlendOp := AC_SRC_OVER;
  BF.BlendFlags := 0;
  BF.SourceConstantAlpha := 255;
  BF.AlphaFormat := AC_SRC_ALPHA;
  DC := Canvas.BeginGdi;
  try
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
          Move(Px[0], Bits^, T * T * 4);
          // Ecken 1:1, Kanten und Mitte aus der mittleren Zeile/Spalte gestreckt
          Blit(O.Left, O.Top, K, K, 0, 0, K, K);
          Blit(O.Right - K, O.Top, K, K, T - K, 0, K, K);
          Blit(O.Left, O.Bottom - K, K, K, 0, T - K, K, K);
          Blit(O.Right - K, O.Bottom - K, K, K, T - K, T - K, K, K);
          Blit(O.Left + K, O.Top, OW - 2 * K, K, K, 0, 1, K);
          Blit(O.Left + K, O.Bottom - K, OW - 2 * K, K, K, T - K, 1, K);
          Blit(O.Left, O.Top + K, K, OH - 2 * K, 0, K, K, 1);
          Blit(O.Right - K, O.Top + K, K, OH - 2 * K, T - K, K, K, 1);
          Blit(O.Left + K, O.Top + K, OW - 2 * K, OH - 2 * K, K, K, 1, 1);
        finally
          SelectObject(MemDC, OldBmp);
        end;
      finally
        DeleteObject(Bmp);
      end;
    finally
      DeleteDC(MemDC);
    end;
  finally
    Canvas.EndGdi(DC);
  end;
  Result := True;
end;

initialization

finalization
  PPGShadowCacheEnabled := False; // beim Beenden ohne Cache
  FreeAndNil(GShadowCache);
  // In einer reinen DLL laeuft finalization in DllMain -> dort KEIN Shutdown
  // (Microsoft-Vorgabe). Der Host kann PPGGdiPlusShutdown selbst aufrufen.
  if (not IsLibrary) or ModuleIsPackage then
    PPGGdiPlusShutdown;

end.
