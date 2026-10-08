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
  TPPGGdiPlusCanvas = class(TInterfacedObject, IPPGCanvas, IPPGShapeCanvas, IPPGCornerCanvas)
  private
    FSquare: TPPGCorners;
    FDC: HDC;
    FGraphics: TGPGraphics;
    FClipStates: array of GraphicsState;
    FGdiSaved: Integer; // SaveDC-Index waehrend GdiBegin..GdiEnd
    procedure Check(Status: TStatus; const Call: string);
    function NewRoundRectPath(X, Y, W, H, Radius: Single): TGPGraphicsPath;
    function GdiBegin: HDC;
    procedure GdiEnd(DC: HDC);
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

/// Startet GDI+ bei Bedarf. False = nicht verfuegbar (GDI-Fallback nutzen).
function PPGGdiPlusAvailable: Boolean;
/// Speichert ein GDI-Bitmap als PNG ueber den GDI+-Encoder (ohne vclimg/
/// Vcl.Imaging.pngimage). EPPGRenderError, wenn GDI+ fehlt oder scheitert.
procedure PPGSaveBitmapAsPng(Bitmap: HBITMAP; const FileName: string);
/// Fuer DLL-Hosts: GDI+ explizit vor dem Entladen der DLL beenden
/// (ausserhalb von DllMain aufrufen!).
procedure PPGGdiPlusShutdown;

implementation

uses
  PPG.Lang,
  System.SysUtils, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler, PPG.Render.Gdi;

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

destructor TPPGGdiPlusCanvas.Destroy;
begin
  // Wirft ein Konstruktor, ist FGraphics evtl. nil -> nil-sicher freigeben
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
  N := Length(FClipStates);
  if N = 0 then
    Exit;
  FGraphics.Restore(FClipStates[N - 1]);
  SetLength(FClipStates, N - 1);
end;

function TPPGGdiPlusCanvas.GdiBegin: HDC;
var
  Region: TGPRegion;
  Rgn: HRGN;
begin
  // GDI+ puffert Operationen: vor GDI-Zugriff auf denselben DC muss der
  // DC ueber GetHDC "ausgeliehen" werden.
  // STOLPERSTEIN: GetHDC uebertraegt die GDI+-Clipregion NICHT auf den DC.
  // Ohne die Uebernahme hier ignorieren Text und Bilder jedes PushClip
  // (z.B. zweifarbiger Text im ProgressBar). Die Region wird deshalb VOR
  // GetHDC gelesen (danach ist das Graphics-Objekt gesperrt) und als
  // GDI-Clip gesetzt; GdiEnd stellt den DC wieder her.
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
    Result := FGraphics.GetHDC;
    if Result = 0 then
      raise EPPGRenderError.CreateFmt(PPGStr(@SPPGGdiPlusCallFailed), ['GetHDC', Ord(FGraphics.GetLastStatus)]);
    FGdiSaved := SaveDC(Result);
    if Rgn <> 0 then
      SelectClipRgn(Result, Rgn);
  finally
    if Rgn <> 0 then
      DeleteObject(Rgn); // SelectClipRgn arbeitet mit einer Kopie
  end;
end;

procedure TPPGGdiPlusCanvas.GdiEnd(DC: HDC);
begin
  if FGdiSaved <> 0 then
  begin
    RestoreDC(DC, FGdiSaved);
    FGdiSaved := 0;
  end;
  FGraphics.ReleaseHDC(DC);
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

initialization

finalization
  // In einer reinen DLL laeuft finalization in DllMain -> dort KEIN Shutdown
  // (Microsoft-Vorgabe). Der Host kann PPGGdiPlusShutdown selbst aufrufen.
  if (not IsLibrary) or ModuleIsPackage then
    PPGGdiPlusShutdown;

end.
