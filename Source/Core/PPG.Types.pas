unit PPG.Types;

{ Grundtypen, Farb-Hilfsfunktionen und Validierung. Keine VCL-Controls,
  daher ohne Fenster testbar. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Types, Vcl.Graphics,
  {$IFDEF PPG_HAS_UITYPES_IMAGEINDEX}System.UITypes{$ELSE}Vcl.ImgList{$ENDIF};

type
  /// Versionsneutraler Alias (gleiche RTTI wie TImageIndex -> Bildauswahl im
  /// Object Inspector funktioniert).
  {$IFDEF PPG_HAS_UITYPES_IMAGEINDEX}
  TPPGImageIndex = System.UITypes.TImageIndex;
  {$ELSE}
  TPPGImageIndex = Vcl.ImgList.TImageIndex;
  {$ENDIF}

  /// Visueller Grundzustand eines Controls (Fokus ist ein zusaetzliches Overlay).
  TPPGVisualState = (vsNormal, vsHot, vsDown, vsDisabled);

  TPPGGradientDirection = (gdVertical, gdHorizontal);

  TPPGImagePosition = (ipLeft, ipRight, ipTop, ipBottom);

  /// Ecken einer Flaeche (Rundung je Ecke, z.B. Button-Gruppen).
  TPPGCorner = (pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft);
  TPPGCorners = set of TPPGCorner;

  /// Einfaerben von Bildern: keins bzw. einfarbig in der Textfarbe.
  TPPGImageTint = (itNone, itTextColor);

  TPPGPresetName = type string;

const
  /// Signalfarben (Windows/Fluent): Fehler, Warnung, Erfolg.
  PPGColorError = TColor($002311E8);   // RGB(232, 17, 35)
  PPGColorWarning = TColor($00009DEA); // RGB(234, 157, 0)
  PPGColorSuccess = TColor($00107C10); // RGB(16, 124, 16)

  /// Ein Eingabe-Control hat seinen Wert geaendert (Benutzer oder Code).
  /// Per Perform an das Control selbst, nach dem internen Zustand und vor
  /// OnChange; der Validator beobachtet es (CM_BASE + $7A0, Vcl.Controls).
  CM_PPGVALUECHANGED = $B000 + $7A0;

type

  /// Vollstaendig aufgeloester Stil fuer genau einen Zeichenvorgang.
  /// Farben sind bereits zwischen Zustaenden interpoliert, Masse bereits
  /// DPI-skaliert. Renderer arbeiten ausschliesslich mit diesem Record.
  TPPGSurfaceStyle = record
    Color: TColor;
    ColorTo: TColor;
    ColorMirror: TColor;
    ColorMirrorTo: TColor;
    BorderColor: TColor;
    GlowColor: TColor;
    TextColor: TColor;
    Direction: TPPGGradientDirection;
    Rounding: Integer;     // px, skaliert
    BorderWidth: Integer;  // px, skaliert
    GlowSize: Integer;     // px, skaliert
    GlowAlpha: Byte;       // 0 = kein Glow, 255 = voller Glow
    Focused: Boolean;
    FontStyle: TFontStyles; // zusaetzliche Schriftstile des Zustands
  end;

const
  PPGAllCorners = [pcTopLeft, pcTopRight, pcBottomRight, pcBottomLeft];

/// Wandelt clXxx-Systemfarben in echte RGB-Werte um.
function PPGColorToRGB(Color: TColor): TColor;
/// True, wenn eine Farbe gesetzt ist (clDefault und clNone gelten als "nicht gesetzt").
function PPGColorIsSet(Color: TColor): Boolean;
/// Mischt zwei Farben; T = 0 -> A, T = 1 -> B.
function PPGBlendColor(A, B: TColor; T: Single): TColor;
function PPGLighten(Color: TColor; Amount: Single): TColor;
function PPGDarken(Color: TColor; Amount: Single): TColor;
function PPGBlendSurface(const A, B: TPPGSurfaceStyle; T: Single): TPPGSurfaceStyle;
function PPGClampSingle(Value, AMin, AMax: Single): Single;
/// Zerlegt S an Delim (wie string.Split, das es erst ab XE3 gibt).
function PPGSplitString(const S: string; Delim: Char; SkipEmpty: Boolean): TArray<string>;

/// Schrift mit zusaetzlichen Stilen (Zustand, Element-Stil): liefert Base, wenn
/// Extra nichts aendert, sonst eine Kopie in Temp (Aufrufer gibt Temp frei).
function PPGStyledFont(Base: TFont; Extra: TFontStyles; var Temp: TFont): TFont;

/// Validiert einen Integer-Property-Wert.
/// - Zur Laufzeit: ausserhalb des Bereichs -> EPPGPropertyError (Objekt bleibt unveraendert).
/// - Waehrend DFM-Laden (csLoading): Wert wird geklemmt und protokolliert,
///   damit sich Formulare mit Altwerten immer oeffnen lassen.
function PPGCheckRange(Sender: TPersistent; const PropName: string;
  Value, AMin, AMax: Integer): Integer;

/// True, wenn Sender (oder sein Besitzer) gerade aus einem Stream geladen wird.
function PPGIsLoading(Sender: TPersistent): Boolean;

/// True fuer endliche Zahlen (weder NaN noch +-Unendlich).
function PPGIsFinite(const Value: Double): Boolean;
/// Wirft EPPGPropertyError, wenn Value nicht endlich ist (NaN, +-Unendlich).
/// Solche Werte liessen spaeter Round/Trunc in Layout oder Paint scheitern.
procedure PPGCheckFinite(Sender: TPersistent; const PropName: string; const Value: Double);
/// Prueft einen Gleitkomma-Property-Wert wie PPGCheckRange: Ist Value nicht
/// endlich oder Valid False, wirft es zur Laufzeit EPPGPropertyError; beim
/// DFM-Laden wird protokolliert und Fallback geliefert (Formular oeffnet sich).
function PPGCheckFloat(Sender: TPersistent; const PropName: string; const Value: Double;
  Valid: Boolean; const Fallback: Double): Double;

const
  /// Gleiche Vorgaben fuer gleiche Konzepte (Audit 5c).
  PPGDefaultDropDownCount = 8;
  PPGMaxDropDownCount = 100;
  PPGKanbanMinColumnWidth = 80;

type
  /// Ein Eintrag wurde vom Anwender an- oder abgehakt.
  TPPGItemCheckEvent = procedure(Sender: TObject; Index: Integer) of object;

  /// Tippsuche ohne Timer (Audit 7a #7), gemeinsam fuer Listen, Combos und
  /// TileView: Zeichen sammeln sich bis zu einer Pause von PPGTypeAheadMs.
  /// Derselbe Buchstabe wiederholt blaettert durch die Treffer (wie Windows).
  TPPGTypeAhead = record
    Text: string;
    Tick: Cardinal;
    /// Nimmt ein Zeichen auf und liefert den Suchtext. Hat er die Laenge 1
    /// (neuer Anfang oder Blaettern), sucht der Aufrufer ab dem Eintrag NACH
    /// dem aktuellen, sonst ab dem aktuellen.
    function Add(Key: Char): string;
    procedure Reset;
  end;

const
  /// Pause, nach der die Tippsuche neu beginnt.
  PPGTypeAheadMs = 1000;

/// True, wenn sich die Maus seit DownPt weit genug fuer ein Ziehen bewegt hat
/// (Audit 7f #4): ausserhalb des Rechtecks SM_CXDRAG x SM_CYDRAG um DownPt,
/// wie DragDetect von Windows.
function PPGDragExceeded(const DownPt, P: TPoint): Boolean;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Math, Winapi.Windows, PPG.Consts, PPG.Exceptions, PPG.ErrorHandler;

type
  TPersistentAccess = class(TPersistent);

{ TPPGTypeAhead }

function TPPGTypeAhead.Add(Key: Char): string;
var
  Now: Cardinal;
  I: Integer;
  Same: Boolean;
begin
  Now := GetTickCount;
  if Now - Tick > PPGTypeAheadMs then
    Text := '';
  Tick := Now;
  Text := Text + Key;
  // Nur derselbe Buchstabe: blaettern (Suchtext ist der eine Buchstabe)
  Same := True;
  for I := 2 to Length(Text) do
    if AnsiUpperCase(Text[I]) <> AnsiUpperCase(Text[1]) then
    begin
      Same := False;
      Break;
    end;
  if Same then
    Result := Text[1]
  else
    Result := Text;
end;

procedure TPPGTypeAhead.Reset;
begin
  Text := '';
  Tick := 0;
end;

function PPGDragExceeded(const DownPt, P: TPoint): Boolean;
begin
  // DragDetect: Rechteck SM_CXDRAG x SM_CYDRAG, mittig um den Startpunkt
  Result := (Abs(P.X - DownPt.X) > Max(1, GetSystemMetrics(SM_CXDRAG) div 2)) or
    (Abs(P.Y - DownPt.Y) > Max(1, GetSystemMetrics(SM_CYDRAG) div 2));
end;

function PPGColorIsSet(Color: TColor): Boolean;
begin
  Result := (Color <> clDefault) and (Color <> clNone);
end;

function PPGColorToRGB(Color: TColor): TColor;
begin
  Result := TColor(ColorToRGB(Color));
end;

function PPGClampSingle(Value, AMin, AMax: Single): Single;
begin
  if Value < AMin then
    Result := AMin
  else if Value > AMax then
    Result := AMax
  else
    Result := Value;
end;

function PPGBlendColor(A, B: TColor; T: Single): TColor;
var
  CA, CB: Cardinal;
  R, G, Bl: Integer;
begin
  T := PPGClampSingle(T, 0, 1);
  CA := Cardinal(PPGColorToRGB(A));
  CB := Cardinal(PPGColorToRGB(B));
  R := Round(GetRValue(CA) + (Integer(GetRValue(CB)) - Integer(GetRValue(CA))) * T);
  G := Round(GetGValue(CA) + (Integer(GetGValue(CB)) - Integer(GetGValue(CA))) * T);
  Bl := Round(GetBValue(CA) + (Integer(GetBValue(CB)) - Integer(GetBValue(CA))) * T);
  Result := TColor(RGB(R, G, Bl));
end;

function PPGLighten(Color: TColor; Amount: Single): TColor;
begin
  Result := PPGBlendColor(Color, clWhite, Amount);
end;

function PPGDarken(Color: TColor; Amount: Single): TColor;
begin
  Result := PPGBlendColor(Color, clBlack, Amount);
end;

function PPGBlendSurface(const A, B: TPPGSurfaceStyle; T: Single): TPPGSurfaceStyle;
begin
  T := PPGClampSingle(T, 0, 1);
  if T <= 0 then
    Exit(A);
  if T >= 1 then
    Exit(B);
  Result := B;
  Result.Color := PPGBlendColor(A.Color, B.Color, T);
  Result.ColorTo := PPGBlendColor(A.ColorTo, B.ColorTo, T);
  Result.ColorMirror := PPGBlendColor(A.ColorMirror, B.ColorMirror, T);
  Result.ColorMirrorTo := PPGBlendColor(A.ColorMirrorTo, B.ColorMirrorTo, T);
  Result.BorderColor := PPGBlendColor(A.BorderColor, B.BorderColor, T);
  Result.GlowColor := PPGBlendColor(A.GlowColor, B.GlowColor, T);
  Result.TextColor := PPGBlendColor(A.TextColor, B.TextColor, T);
  Result.GlowAlpha := Round(A.GlowAlpha + (Integer(B.GlowAlpha) - Integer(A.GlowAlpha)) * T);
  Result.GlowSize := Round(A.GlowSize + (B.GlowSize - A.GlowSize) * T);
  Result.Rounding := Round(A.Rounding + (B.Rounding - A.Rounding) * T);
  Result.BorderWidth := Round(A.BorderWidth + (B.BorderWidth - A.BorderWidth) * T);
  // Schriftstil springt in der Mitte des Uebergangs
  if T < 0.5 then
    Result.FontStyle := A.FontStyle;
end;

function PPGStyledFont(Base: TFont; Extra: TFontStyles; var Temp: TFont): TFont;
begin
  if (Base = nil) or (Extra - Base.Style = []) then
    Exit(Base);
  if Temp = nil then
    Temp := TFont.Create;
  Temp.Assign(Base);
  Temp.Style := Base.Style + Extra;
  Result := Temp;
end;

function PPGIsLoading(Sender: TPersistent): Boolean;
var
  P: TPersistent;
  Depth: Integer;
begin
  Result := False;
  P := Sender;
  Depth := 0;
  // Besitzerkette bis zur Komponente hochlaufen (Appearance -> Control).
  // Tiefenbegrenzung schuetzt vor fehlerhaften zyklischen GetOwner-Ketten.
  while (P <> nil) and (Depth < 16) do
  begin
    if P is TComponent then
      Exit(csLoading in TComponent(P).ComponentState);
    P := TPersistentAccess(P).GetOwner;
    Inc(Depth);
  end;
end;

function PPGIsFinite(const Value: Double): Boolean;
begin
  Result := not IsNan(Value) and not IsInfinite(Value);
end;

procedure PPGCheckFinite(Sender: TPersistent; const PropName: string; const Value: Double);
begin
  if not PPGIsFinite(Value) then
    raise EPPGPropertyError.CreateInvalid(Sender, PropName, FloatToStr(Value));
end;

function PPGCheckFloat(Sender: TPersistent; const PropName: string; const Value: Double;
  Valid: Boolean; const Fallback: Double): Double;
begin
  if Valid and PPGIsFinite(Value) then
    Exit(Value);
  if not PPGIsLoading(Sender) then
    raise EPPGPropertyError.CreateInvalid(Sender, PropName, FloatToStr(Value));
  Result := Fallback;
  TPPGErrorHandler.LogWarning(Sender, Format(PPGStr(@SPPGInvalidPropertyValue),
    [FloatToStr(Value), PPGDisplayName(Sender), PropName]));
end;

function PPGCheckRange(Sender: TPersistent; const PropName: string;
  Value, AMin, AMax: Integer): Integer;
begin
  if (Value >= AMin) and (Value <= AMax) then
    Exit(Value);
  if not PPGIsLoading(Sender) then
    raise EPPGPropertyError.CreateRange(Sender, PropName, Value, AMin, AMax);
  if Value < AMin then
    Result := AMin
  else
    Result := AMax;
  TPPGErrorHandler.LogWarning(Sender, Format(PPGStr(@SPPGValueClamped),
    [Value, PPGDisplayName(Sender), PropName, Result]));
end;

function PPGSplitString(const S: string; Delim: Char; SkipEmpty: Boolean): TArray<string>;
var
  I, Start, N: Integer;
  Part: string;
begin
  SetLength(Result, 0);
  N := 0;
  Start := 1;
  for I := 1 to Length(S) + 1 do
    if (I > Length(S)) or (S[I] = Delim) then
    begin
      Part := Copy(S, Start, I - Start);
      Start := I + 1;
      if SkipEmpty and (Part = '') then
        Continue;
      SetLength(Result, N + 1);
      Result[N] := Part;
      Inc(N);
    end;
end;

end.
