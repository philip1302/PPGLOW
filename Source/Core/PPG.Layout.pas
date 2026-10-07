unit PPG.Layout;

{ Reine Layout-Berechnung (Text/Bild-Positionen). Kein Canvas, kein Fenster,
  deshalb vollstaendig per Unit-Test pruefbar. }

{$I ..\PPG.inc}

interface

uses
  System.Types, PPG.Types;

type
  TPPGHorzAlign = (haLeft, haCenter, haRight);

  TPPGLayoutInput = record
    Bounds: TRect;          // verfuegbarer Inhaltsbereich
    TextSize: TSize;        // gemessene Textgroesse (0,0 = kein Text)
    ImageSize: TSize;       // Bildgroesse (0,0 = kein Bild)
    ImagePosition: TPPGImagePosition;
    Spacing: Integer;       // Abstand Bild <-> Text (skaliert)
    Alignment: TPPGHorzAlign;
    RightToLeft: Boolean;   // BiDi: links/rechts werden gespiegelt
  end;

  TPPGLayoutResult = record
    TextRect: TRect;
    ImageRect: TRect;
    ContentRect: TRect;     // umschliessendes Rechteck Bild+Text
  end;

  TPPGLayoutEngine = class
  public
    class function Calculate(const Input: TPPGLayoutInput): TPPGLayoutResult; static;
  end;

implementation

class function TPPGLayoutEngine.Calculate(const Input: TPPGLayoutInput): TPPGLayoutResult;
var
  HasText, HasImage: Boolean;
  Pos: TPPGImagePosition;
  Gap, W, H, X, Y, BW, BH: Integer;
begin
  Result.TextRect := Rect(0, 0, 0, 0);
  Result.ImageRect := Rect(0, 0, 0, 0);
  Result.ContentRect := Rect(0, 0, 0, 0);

  BW := Input.Bounds.Right - Input.Bounds.Left;
  BH := Input.Bounds.Bottom - Input.Bounds.Top;
  if (BW <= 0) or (BH <= 0) then
    Exit;

  HasText := (Input.TextSize.cx > 0) and (Input.TextSize.cy > 0);
  HasImage := (Input.ImageSize.cx > 0) and (Input.ImageSize.cy > 0);
  if not (HasText or HasImage) then
    Exit;

  Pos := Input.ImagePosition;
  if Input.RightToLeft then
    case Pos of
      ipLeft: Pos := ipRight;
      ipRight: Pos := ipLeft;
    end;

  if HasText and HasImage then
    Gap := Input.Spacing
  else
    Gap := 0;
  if Gap < 0 then
    Gap := 0;

  // Gesamtgroesse des Inhaltsblocks
  if Pos in [ipLeft, ipRight] then
  begin
    W := Input.ImageSize.cx + Gap + Input.TextSize.cx;
    if Input.ImageSize.cy > Input.TextSize.cy then
      H := Input.ImageSize.cy
    else
      H := Input.TextSize.cy;
  end
  else
  begin
    if Input.ImageSize.cx > Input.TextSize.cx then
      W := Input.ImageSize.cx
    else
      W := Input.TextSize.cx;
    H := Input.ImageSize.cy + Gap + Input.TextSize.cy;
  end;

  // Text darf nicht breiter/hoeher als der verfuegbare Bereich werden
  if W > BW then
    W := BW;
  if H > BH then
    H := BH;

  case Input.Alignment of
    haLeft: X := Input.Bounds.Left;
    haRight: X := Input.Bounds.Right - W;
  else
    X := Input.Bounds.Left + (BW - W) div 2;
  end;
  Y := Input.Bounds.Top + (BH - H) div 2;
  Result.ContentRect := Rect(X, Y, X + W, Y + H);

  if not HasImage then
  begin
    Result.TextRect := Result.ContentRect;
    Exit;
  end;
  if not HasText then
  begin
    Result.ImageRect := Rect(X + (W - Input.ImageSize.cx) div 2,
      Y + (H - Input.ImageSize.cy) div 2,
      X + (W - Input.ImageSize.cx) div 2 + Input.ImageSize.cx,
      Y + (H - Input.ImageSize.cy) div 2 + Input.ImageSize.cy);
    Exit;
  end;

  case Pos of
    ipLeft:
      begin
        Result.ImageRect := Rect(X, Y + (H - Input.ImageSize.cy) div 2,
          X + Input.ImageSize.cx, Y + (H - Input.ImageSize.cy) div 2 + Input.ImageSize.cy);
        Result.TextRect := Rect(Result.ImageRect.Right + Gap, Y, X + W, Y + H);
      end;
    ipRight:
      begin
        Result.ImageRect := Rect(X + W - Input.ImageSize.cx, Y + (H - Input.ImageSize.cy) div 2,
          X + W, Y + (H - Input.ImageSize.cy) div 2 + Input.ImageSize.cy);
        Result.TextRect := Rect(X, Y, Result.ImageRect.Left - Gap, Y + H);
      end;
    ipTop:
      begin
        Result.ImageRect := Rect(X + (W - Input.ImageSize.cx) div 2, Y,
          X + (W - Input.ImageSize.cx) div 2 + Input.ImageSize.cx, Y + Input.ImageSize.cy);
        Result.TextRect := Rect(X, Result.ImageRect.Bottom + Gap, X + W, Y + H);
      end;
    ipBottom:
      begin
        Result.ImageRect := Rect(X + (W - Input.ImageSize.cx) div 2, Y + H - Input.ImageSize.cy,
          X + (W - Input.ImageSize.cx) div 2 + Input.ImageSize.cx, Y + H);
        Result.TextRect := Rect(X, Y, X + W, Result.ImageRect.Top - Gap);
      end;
  end;

  // Bei Platzmangel nie negative Rechtecke liefern
  if Result.TextRect.Right < Result.TextRect.Left then
    Result.TextRect.Right := Result.TextRect.Left;
  if Result.TextRect.Bottom < Result.TextRect.Top then
    Result.TextRect.Bottom := Result.TextRect.Top;
end;

end.
