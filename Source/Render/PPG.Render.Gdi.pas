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

  TPPGGdiCanvas = class(TInterfacedObject, IPPGCanvas)
  private
    FDC: HDC;
    FClipDepth: Integer;
    function BeginLayer(const Bounds: TRect; out Layer: TPPGGdiLayer): Boolean;
    procedure EndLayer(var Layer: TPPGGdiLayer; Alpha: Byte);
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
  end;

{ Gemeinsame GDI-Helfer (auch vom GDI+-Canvas ueber GetHDC benutzt) }
function PPGGdiMeasureText(DC: HDC; const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
procedure PPGGdiDrawText(DC: HDC; const R: TRect; const Text: string; Font: TFont;
  Color: TColor; Flags: Cardinal);
procedure PPGGdiDrawImage(DC: HDC; Images: TCustomImageList; Index, X, Y: Integer;
  Enabled: Boolean);
procedure PPGGdiDrawFocusRect(DC: HDC; const R: TRect);
/// Misst Text ohne vorhandenen Canvas (z.B. fuer AutoSize ausserhalb von Paint).
/// Legt kurzzeitig einen Speicher-DC an und gibt ihn sofort wieder frei.
function PPGMeasureTextNoCanvas(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;

implementation

uses
  System.SysUtils, PPG.Exceptions;

{ Helfer }

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

function PPGMeasureTextNoCanvas(const Text: string; Font: TFont; MaxWidth: Integer;
  WordWrap: Boolean): TSize;
var
  DC: HDC;
begin
  DC := CreateCompatibleDC(0);
  if DC = 0 then
    PPGRaiseLastOSError('CreateCompatibleDC');
  try
    Result := PPGGdiMeasureText(DC, Text, Font, MaxWidth, WordWrap);
  finally
    DeleteDC(DC);
  end;
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

procedure PaintFillRoundRect(DC: HDC; const R: TRect; Radius: Integer; Color: TColor);
var
  Brush: HBRUSH;
  Saved: Integer;
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
      PaintFillRoundRect(L.DC, R, Radius, Color);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintFillRoundRect(FDC, R, Radius, Color);
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

procedure PaintFrameRoundRect(DC: HDC; const R: TRect; Radius, Width: Integer; Color: TColor);
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
      if Radius <= 0 then
        Rectangle(DC, R.Left, R.Top, R.Right, R.Bottom)
      else
        RoundRect(DC, R.Left, R.Top, R.Right, R.Bottom, Radius * 2, Radius * 2);
    finally
      RestoreDC(DC, Saved);
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
      PaintFrameRoundRect(L.DC, R, Radius, Width, Color);
    finally
      EndLayer(L, Alpha);
    end
  else
    PaintFrameRoundRect(FDC, R, Radius, Width, Color);
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

procedure TPPGGdiCanvas.PushClipRoundRect(const R: TRect; Radius: Integer);
var
  Rgn: HRGN;
begin
  SaveDC(FDC);
  Inc(FClipDepth);
  if Radius <= 0 then
    Rgn := CreateRectRgn(R.Left, R.Top, R.Right, R.Bottom)
  else
    Rgn := CreateRoundRectRgn(R.Left, R.Top, R.Right + 1, R.Bottom + 1, Radius * 2, Radius * 2);
  if Rgn = 0 then
    Exit; // ohne Clipping weiterzeichnen ist besser als ein Abbruch
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

end.
