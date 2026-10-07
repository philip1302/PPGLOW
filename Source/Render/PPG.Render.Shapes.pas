unit PPG.Render.Shapes;

{ Formen fuer Diagramme (Phase 10): Kreisboegen, Kreis-/Ringsegmente und
  Zugriff auf IPPGShapeCanvas mit Rueckfallweg.

  Controls zeichnen freie Formen nur ueber diese Helfer. Unterstuetzt ein
  (fremder) Canvas IPPGShapeCanvas nicht, entsteht statt der Flaeche ein
  Umriss bzw. statt der gestrichelten eine halbtransparente Linie - das
  Diagramm bleibt lesbar. }

{$I ..\PPG.inc}

interface

uses
  System.Types, Vcl.Graphics, PPG.Render.Intf;

/// Punkte eines Kreisbogens (Winkel in Grad, 0 = oben, im Uhrzeigersinn).
procedure PPGShapeArcPoints(const Center: TPoint; Radius: Integer; StartDeg, SweepDeg: Single;
  var Points: TArray<TPoint>);
/// Kreissegment (InnerRadius = 0) bzw. Ringsegment als geschlossenes Polygon.
function PPGArcSegmentPolygon(const Center: TPoint; OuterRadius, InnerRadius: Integer;
  StartDeg, SweepDeg: Single): TArray<TPoint>;
procedure PPGFillPolygon(const Canvas: IPPGCanvas; const Points: array of TPoint;
  Color: TColor; Alpha: Byte);
procedure PPGDrawDashedLine(const Canvas: IPPGCanvas; const Points: array of TPoint;
  Width, Dash, Gap: Integer; Color: TColor; Alpha: Byte);
/// Diagramm-Renderer des Presets (Standard-Renderer, wenn das Preset keinen hat).
function PPGChartRendererOf(const R: IPPGRenderer): IPPGChartRenderer;

implementation

uses
  System.SysUtils, PPG.Render.Registry;

procedure PPGShapeArcPoints(const Center: TPoint; Radius: Integer; StartDeg, SweepDeg: Single;
  var Points: TArray<TPoint>);
var
  N, I: Integer;
  A: Double;
begin
  // Segmente nach Bogenlaenge: glatt auch bei grossen Ringen
  N := Round(Abs(SweepDeg) / 6) + 2;
  SetLength(Points, N + 1);
  for I := 0 to N do
  begin
    A := (StartDeg + SweepDeg * I / N - 90) * Pi / 180;
    Points[I] := Point(Center.X + Round(Radius * Cos(A)), Center.Y + Round(Radius * Sin(A)));
  end;
end;

function PPGArcSegmentPolygon(const Center: TPoint; OuterRadius, InnerRadius: Integer;
  StartDeg, SweepDeg: Single): TArray<TPoint>;
var
  Outer, Inner: TArray<TPoint>;
  I, N: Integer;
begin
  PPGShapeArcPoints(Center, OuterRadius, StartDeg, SweepDeg, Outer);
  if InnerRadius <= 0 then
  begin
    // Kreissegment: Mittelpunkt + Bogen (bei vollem Kreis nur der Bogen)
    if Abs(SweepDeg) >= 359.9 then
      Exit(Outer);
    SetLength(Result, Length(Outer) + 1);
    Result[0] := Center;
    for I := 0 to High(Outer) do
      Result[I + 1] := Outer[I];
    Exit;
  end;
  PPGShapeArcPoints(Center, InnerRadius, StartDeg, SweepDeg, Inner);
  N := Length(Outer);
  SetLength(Result, N + Length(Inner));
  for I := 0 to N - 1 do
    Result[I] := Outer[I];
  // Innenbogen rueckwaerts: ein zusammenhaengender Umriss
  for I := 0 to High(Inner) do
    Result[N + I] := Inner[High(Inner) - I];
end;

procedure PPGFillPolygon(const Canvas: IPPGCanvas; const Points: array of TPoint;
  Color: TColor; Alpha: Byte);
var
  Shape: IPPGShapeCanvas;
  Closed: array of TPoint;
  I: Integer;
begin
  if Length(Points) < 3 then
    Exit;
  if Supports(Canvas, IPPGShapeCanvas, Shape) then
  begin
    Shape.FillPolygon(Points, Color, Alpha);
    Exit;
  end;
  SetLength(Closed, Length(Points) + 1);
  for I := 0 to High(Points) do
    Closed[I] := Points[I];
  Closed[High(Closed)] := Points[0];
  Canvas.DrawPolyline(Closed, 1, Color, Alpha);
end;

procedure PPGDrawDashedLine(const Canvas: IPPGCanvas; const Points: array of TPoint;
  Width, Dash, Gap: Integer; Color: TColor; Alpha: Byte);
var
  Shape: IPPGShapeCanvas;
begin
  if Supports(Canvas, IPPGShapeCanvas, Shape) then
    Shape.DrawDashedPolyline(Points, Width, Dash, Gap, Color, Alpha)
  else
    Canvas.DrawPolyline(Points, Width, Color, Alpha div 2);
end;

function PPGChartRendererOf(const R: IPPGRenderer): IPPGChartRenderer;
begin
  if not Supports(R, IPPGChartRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGChartRenderer, Result);
end;

end.
