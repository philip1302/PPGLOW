unit PPG.Sparkline;

{ TPPGSparkline - kleiner Werteverlauf ohne Achsen (Phase 10b).

  - Arten: Linie, Flaeche, Saeulen, Gewinn/Verlust.
  - Markierungen fuer Minimum, Maximum, ersten und letzten Wert;
    Referenzlinie (z.B. Ziel oder Durchschnitt); eigener Wertebereich.
  - Werte im Code (SetValues, AddValue mit MaxCount als Lauffenster) oder im
    DFM ueber ValuesText ("3;5;2.5;8", Punkt als Dezimaltrenner).
  - PPGDrawSparkline zeichnet dieselbe Darstellung ohne Control, z.B. in
    Grid-Zellen (OnDrawCell) oder in TPPGKpiTile.
  - Sehr viele Werte werden pro Pixelspalte auf Min/Max verdichtet.
  - Kein Fokus, kein Hover. Screenreader: Rolle Diagramm, Wert
    "Min x, Max y, letzter z". }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.Controls.Base;

type
  TPPGSparklineKind = (skLine, skArea, skColumn, skWinLoss);
  TPPGSparklineMarker = (smMin, smMax, smFirst, smLast);
  TPPGSparklineMarkers = set of TPPGSparklineMarker;

  /// Alle Angaben fuer PPGDrawSparkline. Farben als RGB (keine clDefault),
  /// Masse in Pixeln (bereits skaliert).
  TPPGSparklineOptions = record
    Kind: TPPGSparklineKind;
    Markers: TPPGSparklineMarkers;
    Color: TColor;
    NegativeColor: TColor;
    MinColor: TColor;
    MaxColor: TColor;
    Background: TColor;     // Ring um die Markierungen
    LineWidth: Integer;
    MarkerRadius: Integer;
    UseRange: Boolean;      // False = Bereich aus den Werten
    RangeMin: Double;
    RangeMax: Double;
    ShowReference: Boolean;
    Reference: Double;
    ReferenceColor: TColor;
  end;

/// Vorgaben aus den Tokens (Akzent, Signalfarben) fuer die PPI.
function PPGDefaultSparklineOptions(const Tokens: TPPGTokens; Background: TColor;
  PPI: Integer): TPPGSparklineOptions;
procedure PPGDrawSparkline(const Canvas: IPPGCanvas; const R: TRect;
  const AValues: array of Double; const Options: TPPGSparklineOptions);
/// Bequemer Weg fuer OnDrawCell u.ae.: zeichnet auf einen TCanvas (GDI+,
/// sonst GDI-Fallback).
procedure PPGDrawSparklineOnCanvas(ACanvas: TCanvas; const R: TRect;
  const Values: array of Double; const Options: TPPGSparklineOptions);
/// "3;5;2.5" -> Werte (Punkt als Dezimaltrenner). False bei ungueltigem Text.
function PPGParseValueList(const S: string; out Values: TArray<Double>): Boolean;
function PPGFormatValueList(const Values: array of Double): string;

type
  TPPGCustomSparkline = class(TPPGCustomControl)
  private
    FValues: TArray<Double>;
    FKind: TPPGSparklineKind;
    FMarkers: TPPGSparklineMarkers;
    FMaxCount: Integer;
    FLineWidth: Integer;
    FLineColor: TColor;
    FNegativeColor: TColor;
    FUseRange: Boolean;
    FRangeMin: Double;
    FRangeMax: Double;
    FShowReference: Boolean;
    FReferenceValue: Double;
    function GetValuesText: string;
    procedure SetValuesText(const Value: string);
    procedure SetKind(const Value: TPPGSparklineKind);
    procedure SetMarkers(const Value: TPPGSparklineMarkers);
    procedure SetMaxCount(const Value: Integer);
    procedure SetLineWidth(const Value: Integer);
    procedure SetLineColor(const Value: TColor);
    procedure SetNegativeColor(const Value: TColor);
    procedure SetUseRange(const Value: Boolean);
    procedure SetRangeMin(const Value: Double);
    procedure SetRangeMax(const Value: Double);
    procedure SetShowReference(const Value: Boolean);
    procedure SetReferenceValue(const Value: Double);
    function GetCount: Integer;
    function GetValue(Index: Integer): Double;
    function IsRangeMinStored: Boolean;
    function IsRangeMaxStored: Boolean;
    function IsReferenceStored: Boolean;
    procedure TrimToMaxCount;
    procedure ValuesChanged;
  protected
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function AccName: string; override;
    function AccRole: Integer; override;
    function AccState: Integer; override;
    function AccValue: string; override;
    property Kind: TPPGSparklineKind read FKind write SetKind default skLine;
    property Markers: TPPGSparklineMarkers read FMarkers write SetMarkers default [smLast];
    /// Hoechstzahl der Werte (0 = unbegrenzt); AddValue schiebt Alte hinaus.
    property MaxCount: Integer read FMaxCount write SetMaxCount default 0;
    /// Strichstaerke in logischen px.
    property LineWidth: Integer read FLineWidth write SetLineWidth default 2;
    /// clDefault = Akzentfarbe des Presets.
    property LineColor: TColor read FLineColor write SetLineColor default clDefault;
    /// Farbe negativer Saeulen (clDefault = Signalfarbe Fehler).
    property NegativeColor: TColor read FNegativeColor write SetNegativeColor default clDefault;
    property UseRange: Boolean read FUseRange write SetUseRange default False;
    property RangeMin: Double read FRangeMin write SetRangeMin stored IsRangeMinStored;
    property RangeMax: Double read FRangeMax write SetRangeMax stored IsRangeMaxStored;
    property ShowReference: Boolean read FShowReference write SetShowReference default False;
    property ReferenceValue: Double read FReferenceValue write SetReferenceValue
      stored IsReferenceStored;
    /// Werte als Text fuer das DFM ("3;5;2.5").
    property ValuesText: string read GetValuesText write SetValuesText stored True;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetValues(const AValues: array of Double);
    procedure AddValue(const AValue: Double);
    procedure Clear;
    /// Darstellung, wie sie das Control gerade zeichnet (Farben aufgeloest).
    function DrawOptions: TPPGSparklineOptions;
    property Count: Integer read GetCount;
    property Values[Index: Integer]: Double read GetValue;
  end;

  TPPGSparkline = class(TPPGCustomSparkline)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property Kind;
    property Markers;
    property MaxCount;
    property LineWidth;
    property LineColor;
    property NegativeColor;
    property UseRange;
    property RangeMin;
    property RangeMax;
    property ShowReference;
    property ReferenceValue;
    property ValuesText;
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Hint;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property Touch;
    property OnGesture;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseWheel;
    property OnMouseActivate;
    property OnContextPopup;
    property StyleElements;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    property Color;
    property ParentColor;
  end;

implementation

uses
  PPG.Lang,
  System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Exceptions, PPG.ErrorHandler, PPG.Appearance, PPG.DpiUtils,
  PPG.Render.Registry, PPG.Render.Shapes;

var
  GInvariant: TFormatSettings;

{ ---- Werteliste ---- }

function PPGParseValueList(const S: string; out Values: TArray<Double>): Boolean;
var
  Parts: TArray<string>;
  I, N: Integer;
  V: Double;
begin
  SetLength(Values, 0);
  Parts := PPGSplitString(S, ';', True);
  SetLength(Values, Length(Parts));
  N := 0;
  for I := 0 to High(Parts) do
  begin
    if not TryStrToFloat(Trim(Parts[I]), V, GInvariant) or not PPGIsFinite(V) then
    begin
      SetLength(Values, 0);
      Exit(False);
    end;
    Values[N] := V;
    Inc(N);
  end;
  SetLength(Values, N);
  Result := True;
end;

function PPGFormatValueList(const Values: array of Double): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(Values) do
  begin
    if I > 0 then
      Result := Result + ';';
    Result := Result + FloatToStr(Values[I], GInvariant);
  end;
end;

{ ---- Zeichnen ---- }

function PPGDefaultSparklineOptions(const Tokens: TPPGTokens; Background: TColor;
  PPI: Integer): TPPGSparklineOptions;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Kind := skLine;
  Result.Markers := [smLast];
  Result.Color := Tokens.Accent;
  Result.NegativeColor := Tokens.Danger;
  Result.MinColor := Tokens.Danger;
  Result.MaxColor := Tokens.Success;
  Result.Background := PPGColorToRGB(Background);
  Result.LineWidth := PPGScale(2, PPI);
  Result.MarkerRadius := PPGScale(3, PPI);
  Result.ReferenceColor := Tokens.TextSecondary;
end;

procedure DrawMarker(const Canvas: IPPGCanvas; const P: TPoint; Radius: Integer;
  Color, Ring: TColor);
var
  W: Integer;
begin
  W := Radius div 2;
  if W < 1 then
    W := 1;
  Canvas.FillEllipse(Rect(P.X - Radius - W, P.Y - Radius - W, P.X + Radius + W,
    P.Y + Radius + W), Ring, 255);
  Canvas.FillEllipse(Rect(P.X - Radius, P.Y - Radius, P.X + Radius, P.Y + Radius), Color, 255);
end;

procedure PPGDrawSparkline(const Canvas: IPPGCanvas; const R: TRect;
  const AValues: array of Double; const Options: TPPGSparklineOptions);
var
  Values: TArray<Double>;
  N, I, Pad, W, H, Cols, Col, Base, X0, X1, Y, K: Integer;
  Lo, Hi, Span, Slot: Double;
  Plot, Bar: TRect;
  Pts, Poly: TArray<TPoint>;
  ColMin, ColMax: array of Double;
  ColFirst: array of Integer;
  MinIdx, MaxIdx: Integer;

  function YOf(V: Double): Integer;
  begin
    if Span <= 0 then
      Result := (Plot.Top + Plot.Bottom) div 2
    else
      Result := Plot.Bottom - Round((V - Lo) / Span * (Plot.Bottom - Plot.Top));
  end;

  function XOf(Index: Integer): Integer;
  begin
    if N <= 1 then
      Result := (Plot.Left + Plot.Right) div 2
    else
      Result := Plot.Left + Round(Index / (N - 1) * (Plot.Right - Plot.Left));
  end;

begin
  // Audit 08.10.2026: NaN/Unendlich (z. B. aus Grid-Zellen) machten Lo/Hi
  // zu NaN, Round warf im Paint. Nicht endliche Werte auslassen.
  SetLength(Values, Length(AValues));
  N := 0;
  for I := 0 to High(AValues) do
    if PPGIsFinite(AValues[I]) then
    begin
      Values[N] := AValues[I];
      Inc(N);
    end;
  SetLength(Values, N);
  if (N = 0) or IsRectEmpty(R) then
    Exit;
  // Bereich
  MinIdx := 0;
  MaxIdx := 0;
  for I := 1 to N - 1 do
  begin
    if Values[I] < Values[MinIdx] then
      MinIdx := I;
    if Values[I] > Values[MaxIdx] then
      MaxIdx := I;
  end;
  if Options.UseRange and PPGIsFinite(Options.RangeMin) and PPGIsFinite(Options.RangeMax) and
    (Options.RangeMax > Options.RangeMin) then
  begin
    Lo := Options.RangeMin;
    Hi := Options.RangeMax;
  end
  else
  begin
    Lo := Values[MinIdx];
    Hi := Values[MaxIdx];
    if Options.ShowReference and PPGIsFinite(Options.Reference) then
    begin
      Lo := System.Math.Min(Lo, Options.Reference);
      Hi := System.Math.Max(Hi, Options.Reference);
    end;
    if Options.Kind in [skColumn, skArea] then
    begin
      // Saeulen und Flaechen stehen auf der Nulllinie
      if Lo > 0 then
        Lo := 0;
      if Hi < 0 then
        Hi := 0;
    end;
  end;
  Span := Hi - Lo;
  if Options.Kind = skWinLoss then
  begin
    Lo := -1;
    Span := 2;
  end;
  // Platz fuer Markierungen und Strich
  Pad := System.Math.Max(Options.LineWidth, 1);
  if (Options.Markers <> []) and (Options.Kind in [skLine, skArea]) then
    Pad := System.Math.Max(Pad, Options.MarkerRadius + System.Math.Max(Options.MarkerRadius div 2, 1));
  Plot := R;
  InflateRect(Plot, -Pad, -Pad);
  if (Plot.Right <= Plot.Left) or (Plot.Bottom < Plot.Top) then
    Plot := R;
  W := Plot.Right - Plot.Left;
  H := Plot.Bottom - Plot.Top;
  if H < 0 then
    Exit;

  if Options.ShowReference and (Options.Kind <> skWinLoss) then
  begin
    Y := YOf(Options.Reference);
    PPGDrawDashedLine(Canvas, [Point(R.Left, Y), Point(R.Right, Y)], 1,
      System.Math.Max(Options.LineWidth * 2, 2), System.Math.Max(Options.LineWidth * 2, 2),
      Options.ReferenceColor, 255);
  end;

  if Options.Kind in [skColumn, skWinLoss] then
  begin
    Slot := (R.Right - R.Left) / N;
    if Options.Kind = skWinLoss then
      Base := (Plot.Top + Plot.Bottom) div 2
    else
      Base := YOf(System.Math.Max(Lo, System.Math.Min(0, Hi)));
    for I := 0 to N - 1 do
    begin
      X0 := R.Left + Round(I * Slot + Slot * 0.15);
      X1 := R.Left + Round((I + 1) * Slot - Slot * 0.15);
      if X1 <= X0 then
        X1 := X0 + 1;
      if Options.Kind = skWinLoss then
      begin
        if Values[I] > 0 then
          Bar := Rect(X0, Plot.Top, X1, Base - 1)
        else if Values[I] < 0 then
          Bar := Rect(X0, Base + 1, X1, Plot.Bottom)
        else
          Continue;
      end
      else
      begin
        Y := YOf(Values[I]);
        if Y < Base then
          Bar := Rect(X0, Y, X1, Base)
        else
          Bar := Rect(X0, Base, X1, System.Math.Max(Y, Base + 1));
      end;
      if Values[I] < 0 then
        Canvas.FillRoundRect(Bar, 0, Options.NegativeColor, 255)
      else if (smMax in Options.Markers) and (I = MaxIdx) then
        Canvas.FillRoundRect(Bar, 0, Options.MaxColor, 255)
      else if (smMin in Options.Markers) and (I = MinIdx) then
        Canvas.FillRoundRect(Bar, 0, Options.MinColor, 255)
      else
        Canvas.FillRoundRect(Bar, 0, Options.Color, 255);
    end;
    Exit;
  end;

  // Linie/Flaeche: bei mehr Werten als Pixeln je Spalte Min und Max
  if (N > 2 * W) and (W > 0) then
  begin
    Cols := W + 1;
    SetLength(ColMin, Cols);
    SetLength(ColMax, Cols);
    SetLength(ColFirst, Cols);
    for Col := 0 to Cols - 1 do
      ColFirst[Col] := -1;
    for I := 0 to N - 1 do
    begin
      Col := Round(I / (N - 1) * W);
      if ColFirst[Col] < 0 then
      begin
        ColFirst[Col] := I;
        ColMin[Col] := Values[I];
        ColMax[Col] := Values[I];
      end
      else
      begin
        if Values[I] < ColMin[Col] then
          ColMin[Col] := Values[I];
        if Values[I] > ColMax[Col] then
          ColMax[Col] := Values[I];
      end;
    end;
    SetLength(Pts, 2 * Cols);
    K := 0;
    for Col := 0 to Cols - 1 do
      if ColFirst[Col] >= 0 then
      begin
        Pts[K] := Point(Plot.Left + Col, YOf(ColMax[Col]));
        Pts[K + 1] := Point(Plot.Left + Col, YOf(ColMin[Col]));
        Inc(K, 2);
      end;
    SetLength(Pts, K);
  end
  else
  begin
    SetLength(Pts, N);
    for I := 0 to N - 1 do
      Pts[I] := Point(XOf(I), YOf(Values[I]));
  end;

  if (Options.Kind = skArea) and (Length(Pts) >= 2) then
  begin
    Base := YOf(System.Math.Max(Lo, System.Math.Min(0, Hi)));
    SetLength(Poly, Length(Pts) + 2);
    for I := 0 to High(Pts) do
      Poly[I] := Pts[I];
    Poly[Length(Pts)] := Point(Pts[High(Pts)].X, Base);
    Poly[Length(Pts) + 1] := Point(Pts[0].X, Base);
    PPGFillPolygon(Canvas, Poly, Options.Color, 64);
  end;
  if Length(Pts) >= 2 then
    Canvas.DrawPolyline(Pts, System.Math.Max(Options.LineWidth, 1), Options.Color, 255)
  else if Length(Pts) = 1 then
    DrawMarker(Canvas, Pts[0], System.Math.Max(Options.LineWidth, 1), Options.Color,
      Options.Background);

  if Options.MarkerRadius > 0 then
  begin
    if smFirst in Options.Markers then
      DrawMarker(Canvas, Point(XOf(0), YOf(Values[0])), Options.MarkerRadius,
        Options.Color, Options.Background);
    if smMin in Options.Markers then
      DrawMarker(Canvas, Point(XOf(MinIdx), YOf(Values[MinIdx])), Options.MarkerRadius,
        Options.MinColor, Options.Background);
    if smMax in Options.Markers then
      DrawMarker(Canvas, Point(XOf(MaxIdx), YOf(Values[MaxIdx])), Options.MarkerRadius,
        Options.MaxColor, Options.Background);
    if smLast in Options.Markers then
      DrawMarker(Canvas, Point(XOf(N - 1), YOf(Values[N - 1])), Options.MarkerRadius,
        Options.Color, Options.Background);
  end;
end;

procedure PPGDrawSparklineOnCanvas(ACanvas: TCanvas; const R: TRect;
  const Values: array of Double; const Options: TPPGSparklineOptions);
var
  C: IPPGCanvas;
begin
  C := TPPGRendererRegistry.CreateCanvas(ACanvas.Handle);
  PPGDrawSparkline(C, R, Values, Options);
  C := nil; // GDI+ gibt den DC vor dem naechsten TCanvas-Zugriff frei
end;

{ TPPGCustomSparkline }

constructor TPPGCustomSparkline.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption];
  FMarkers := [smLast];
  FLineWidth := 2;
  FLineColor := clDefault;
  FNegativeColor := clDefault;
  TabStop := False;
  Width := 120;
  Height := 32;
end;

function TPPGCustomSparkline.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomSparkline.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomSparkline.GetCount: Integer;
begin
  Result := Length(FValues);
end;

function TPPGCustomSparkline.GetValue(Index: Integer): Double;
begin
  if (Index < 0) or (Index >= Length(FValues)) then
    raise EPPGPropertyError.CreateRange(Self, 'Values', Index, 0, Length(FValues) - 1);
  Result := FValues[Index];
end;

procedure TPPGCustomSparkline.ValuesChanged;
begin
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGCustomSparkline.TrimToMaxCount;
var
  Drop, I: Integer;
begin
  if (FMaxCount <= 0) or (Length(FValues) <= FMaxCount) then
    Exit;
  Drop := Length(FValues) - FMaxCount;
  for I := 0 to FMaxCount - 1 do
    FValues[I] := FValues[I + Drop];
  SetLength(FValues, FMaxCount);
end;

procedure TPPGCustomSparkline.SetValues(const AValues: array of Double);
var
  I: Integer;
begin
  for I := 0 to High(AValues) do
    PPGCheckFinite(Self, 'Values', AValues[I]);
  SetLength(FValues, Length(AValues));
  for I := 0 to High(AValues) do
    FValues[I] := AValues[I];
  TrimToMaxCount;
  ValuesChanged;
end;

procedure TPPGCustomSparkline.AddValue(const AValue: Double);
var
  N: Integer;
begin
  PPGCheckFinite(Self, 'Value', AValue);
  N := Length(FValues);
  SetLength(FValues, N + 1);
  FValues[N] := AValue;
  TrimToMaxCount;
  ValuesChanged;
end;

procedure TPPGCustomSparkline.Clear;
begin
  if Length(FValues) = 0 then
    Exit;
  SetLength(FValues, 0);
  ValuesChanged;
end;

function TPPGCustomSparkline.GetValuesText: string;
begin
  Result := PPGFormatValueList(FValues);
end;

procedure TPPGCustomSparkline.SetValuesText(const Value: string);
var
  V: TArray<Double>;
begin
  if not PPGParseValueList(Value, V) then
  begin
    if not PPGIsLoading(Self) then
      raise EPPGPropertyError.CreateInvalid(Self, 'ValuesText', Value);
    TPPGErrorHandler.LogWarning(Self, Format(PPGStr(@SPPGInvalidValueList), [Value]));
    Exit;
  end;
  SetValues(V);
end;

procedure TPPGCustomSparkline.SetKind(const Value: TPPGSparklineKind);
begin
  if FKind <> Value then
  begin
    FKind := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetMarkers(const Value: TPPGSparklineMarkers);
begin
  if FMarkers <> Value then
  begin
    FMarkers := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetMaxCount(const Value: Integer);
begin
  if FMaxCount = Value then
    Exit;
  FMaxCount := PPGCheckRange(Self, 'MaxCount', Value, 0, MaxInt);
  if Length(FValues) > FMaxCount then
  begin
    TrimToMaxCount;
    ValuesChanged;
  end;
end;

procedure TPPGCustomSparkline.SetLineWidth(const Value: Integer);
begin
  if FLineWidth = Value then
    Exit;
  FLineWidth := PPGCheckRange(Self, 'LineWidth', Value, 1, 20);
  Invalidate;
end;

procedure TPPGCustomSparkline.SetLineColor(const Value: TColor);
begin
  if FLineColor <> Value then
  begin
    FLineColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetNegativeColor(const Value: TColor);
begin
  if FNegativeColor <> Value then
  begin
    FNegativeColor := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetUseRange(const Value: Boolean);
begin
  if FUseRange <> Value then
  begin
    FUseRange := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetRangeMin(const Value: Double);
begin
  PPGCheckFinite(Self, 'RangeMin', Value);
  if FRangeMin <> Value then
  begin
    FRangeMin := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetRangeMax(const Value: Double);
begin
  PPGCheckFinite(Self, 'RangeMax', Value);
  if FRangeMax <> Value then
  begin
    FRangeMax := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetShowReference(const Value: Boolean);
begin
  if FShowReference <> Value then
  begin
    FShowReference := Value;
    Invalidate;
  end;
end;

procedure TPPGCustomSparkline.SetReferenceValue(const Value: Double);
begin
  PPGCheckFinite(Self, 'ReferenceValue', Value);
  if FReferenceValue <> Value then
  begin
    FReferenceValue := Value;
    Invalidate;
  end;
end;

function TPPGCustomSparkline.IsRangeMinStored: Boolean;
begin
  Result := FRangeMin <> 0;
end;

function TPPGCustomSparkline.IsRangeMaxStored: Boolean;
begin
  Result := FRangeMax <> 0;
end;

function TPPGCustomSparkline.IsReferenceStored: Boolean;
begin
  Result := FReferenceValue <> 0;
end;

function TPPGCustomSparkline.DrawOptions: TPPGSparklineOptions;
var
  T: TPPGTokens;
begin
  T := Tokens;
  Result := PPGDefaultSparklineOptions(T, GetBackgroundColor, ScalePPI);
  Result.Kind := FKind;
  Result.Markers := FMarkers;
  Result.LineWidth := PPGScale(FLineWidth, ScalePPI);
  Result.MarkerRadius := PPGScale(FLineWidth + 1, ScalePPI);
  if FLineColor <> clDefault then
    Result.Color := PPGColorToRGB(FLineColor)
  else
    Result.Color := PPGColorToRGB(EffectiveAppearance.FocusColor);
  if FNegativeColor <> clDefault then
    Result.NegativeColor := PPGColorToRGB(FNegativeColor);
  Result.UseRange := FUseRange;
  Result.RangeMin := FRangeMin;
  Result.RangeMax := FRangeMax;
  Result.ShowReference := FShowReference;
  Result.Reference := FReferenceValue;
  if HighContrastSupport and PPGIsHighContrast then
  begin
    Result.Color := PPGColorToRGB(clHighlight);
    Result.NegativeColor := PPGColorToRGB(clWindowText);
    Result.MinColor := PPGColorToRGB(clWindowText);
    Result.MaxColor := PPGColorToRGB(clHighlight);
    Result.ReferenceColor := PPGColorToRGB(clGrayText);
    Result.Background := PPGColorToRGB(clWindow);
  end
  else if not Enabled then
  begin
    // Deaktiviert: keine kraeftigen Farben (Sichttest der Galerie)
    Result.Color := T.TextDisabled;
    Result.NegativeColor := T.TextDisabled;
    Result.MinColor := T.TextDisabled;
    Result.MaxColor := T.TextDisabled;
    Result.ReferenceColor := T.TextDisabled;
  end;
end;

procedure TPPGCustomSparkline.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
begin
  PPGDrawSparkline(ACanvas, ClientR, FValues, DrawOptions);
end;

function TPPGCustomSparkline.AccName: string;
begin
  Result := Hint;
end;

function TPPGCustomSparkline.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_CHART;
end;

function TPPGCustomSparkline.AccState: Integer;
begin
  Result := (inherited AccState) or STATE_SYSTEM_READONLY;
end;

function TPPGCustomSparkline.AccValue: string;
var
  I: Integer;
  Lo, Hi: Double;
begin
  if Length(FValues) = 0 then
    Exit(PPGStr(@SPPGChartNoData));
  Lo := FValues[0];
  Hi := FValues[0];
  for I := 1 to High(FValues) do
  begin
    Lo := System.Math.Min(Lo, FValues[I]);
    Hi := System.Math.Max(Hi, FValues[I]);
  end;
  Result := Format(PPGStr(@SPPGSparklineSummary), [FloatToStr(Lo), FloatToStr(Hi),
    FloatToStr(FValues[High(FValues)])]);
end;

initialization
  GInvariant := FormatSettings;
  GInvariant.DecimalSeparator := '.';
  GInvariant.ThousandSeparator := ',';

end.
