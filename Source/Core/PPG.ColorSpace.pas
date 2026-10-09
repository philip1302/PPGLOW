unit PPG.ColorSpace;

{ Farbraeume und Hex-Text (Phase 12d) - ohne Controls, testbar.
  H in Grad 0..360, S und V 0..1. Hex als "#RRGGBB" (Reihenfolge wie im Web,
  nicht wie TColor $00BBGGRR). }

{$I ..\PPG.inc}

interface

uses
  System.UITypes;

procedure PPGColorToHSV(Color: TColor; out H, S, V: Double);
function PPGHSVToColor(H, S, V: Double): TColor;
/// "#RRGGBB"; Systemfarben werden vorher aufgeloest (ColorToRGB).
function PPGColorToHex(Color: TColor): string;
/// Liest "#RGB", "#RRGGBB", "RGB" und "RRGGBB" (Gross-/Kleinschreibung egal).
function PPGTryHexToColor(const S: string; out Color: TColor): Boolean;

implementation

uses
  System.SysUtils, System.Math, Winapi.Windows;

// Rest einer Gleitkomma-Division wie System.Math.FMod (Vorzeichen des
// Zaehlers); FMod gibt es in XE2 noch nicht.
function FloatMod(const Numerator, Denominator: Double): Double;
begin
  Result := Numerator - Double(Trunc(Numerator / Denominator) * Denominator);
end;

function RGBOf(Color: TColor): Cardinal;
begin
  if Color < 0 then
    Result := GetSysColor(Color and $FF)
  else
    Result := Cardinal(Color) and $FFFFFF;
end;

procedure PPGColorToHSV(Color: TColor; out H, S, V: Double);
var
  C: Cardinal;
  R, G, B, Mx, Mn, D: Double;
begin
  C := RGBOf(Color);
  R := (C and $FF) / 255;
  G := ((C shr 8) and $FF) / 255;
  B := ((C shr 16) and $FF) / 255;
  Mx := Max(R, Max(G, B));
  Mn := Min(R, Min(G, B));
  D := Mx - Mn;
  V := Mx;
  if Mx <= 0 then
    S := 0
  else
    S := D / Mx;
  if D <= 0 then
    H := 0
  else if Mx = R then
    H := 60 * FloatMod((G - B) / D, 6)
  else if Mx = G then
    H := 60 * ((B - R) / D + 2)
  else
    H := 60 * ((R - G) / D + 4);
  if H < 0 then
    H := H + 360;
end;

function PPGHSVToColor(H, S, V: Double): TColor;
var
  C, X, M, R, G, B: Double;
  Sector: Integer;
begin
  H := FloatMod(H, 360);
  if H < 0 then
    H := H + 360;
  S := EnsureRange(S, 0, 1);
  V := EnsureRange(V, 0, 1);
  C := V * S;
  Sector := Trunc(H / 60) mod 6;
  X := C * (1 - Abs(FloatMod(H / 60, 2) - 1));
  M := V - C;
  case Sector of
    0: begin R := C; G := X; B := 0; end;
    1: begin R := X; G := C; B := 0; end;
    2: begin R := 0; G := C; B := X; end;
    3: begin R := 0; G := X; B := C; end;
    4: begin R := X; G := 0; B := C; end;
  else
    begin R := C; G := 0; B := X; end;
  end;
  Result := TColor(Round((R + M) * 255) or (Round((G + M) * 255) shl 8) or
    (Round((B + M) * 255) shl 16));
end;

function PPGColorToHex(Color: TColor): string;
var
  C: Cardinal;
begin
  C := RGBOf(Color);
  Result := Format('#%.2X%.2X%.2X', [C and $FF, (C shr 8) and $FF, (C shr 16) and $FF]);
end;

function PPGTryHexToColor(const S: string; out Color: TColor): Boolean;
var
  T: string;
  N: Integer;
  R, G, B: Integer;
begin
  Result := False;
  Color := 0;
  T := Trim(S);
  if (T <> '') and (T[1] = '#') then
    Delete(T, 1, 1);
  if Length(T) = 3 then
    T := T[1] + T[1] + T[2] + T[2] + T[3] + T[3];
  if Length(T) <> 6 then
    Exit;
  if not TryStrToInt('$' + T, N) then
    Exit;
  R := (N shr 16) and $FF;
  G := (N shr 8) and $FF;
  B := N and $FF;
  Color := TColor(R or (G shl 8) or (B shl 16));
  Result := True;
end;

end.
