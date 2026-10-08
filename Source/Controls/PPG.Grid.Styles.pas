unit PPG.Grid.Styles;

{ Bedingte Formate des Grids (Phase 13d).

  - TPPGGridConditionalFormats: Regeln je Spalte (Wertbereich, Gleich,
    Enthaelt, Oben/Unten-N, Farbskala, Datenbalken, Symbolsatz).
  - Farben kommen aus den Tokens (Erfolg, Warnung, Fehler, Akzent), damit
    Dark Mode und Presets stimmen; ccCustom fuer eigene Farben.
  - Leistung: Schwellen werden beim Aendern der Regeln vorab berechnet
    (Compile), Spalten-Statistiken (Min/Max/N-ter Wert) beim Aendern von
    Ansicht oder Daten (ComputeStats) - beim Zeichnen nur noch Vergleiche.
  - Regeln mit Statistik (Oben/Unten-N, Farbskala, Datenbalken, Symbolsatz)
    brauchen eine feste Spalte (Column >= 0). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, Vcl.Graphics, PPG.Types, PPG.Tokens, PPG.ElementStyle;

type
  TPPGCondRule = (crRange, crEqual, crContains, crTop, crBottom, crColorScale,
    crDataBar, crIconSet);
  TPPGCondColor = (ccWarning, ccSuccess, ccDanger, ccAccent, ccCustom);
  TPPGCondTarget = (ctFill, ctText);

  /// Darstellung einer Zelle (bedingte Formate, OnGetCellStyle).
  TPPGGridCellStyle = record
    Fill: TColor;       // clNone = Standard
    TextColor: TColor;  // clNone = Standard
    Bold: Boolean;
    Bar: Single;        // Datenbalken 0..1; < 0 = keiner
    BarColor: TColor;
    Icon: Integer;      // Symbolsatz: -1 = keins, 0 = runter, 1 = gleich, 2 = hoch
    IconColor: TColor;
    /// Zusaetzliche Schriftstile (Bold bleibt aus Kompatibilitaet erhalten).
    FontStyle: TFontStyles;
    /// Andere Schrift ('' = Schrift der Spalte) bzw. Groesse in Punkt (0 = gleich).
    FontName: string;
    FontSize: Integer;
    procedure Reset;
    function IsDefault: Boolean;
  end;

  /// Bereiche des Grids (Anpassbarkeit). Nur gesetzte Werte ueberschreiben
  /// die vom Preset berechneten Farben (clDefault = Preset).
  TPPGGridStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Kopfzeilen und -spalten, Baender (Color, TextColor, BorderColor =
    /// Linien im Kopf, Font).
    property Header: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Summenzeile (ShowFooter) und Gruppenfuss; ohne Werte wie Header.
    property Footer: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Auswahl bei Fokus. Mit Color deckend statt halbtransparent.
    property Selection: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Auswahl ohne Fokus.
    property SelectionInactive: TPPGElementStyle index 3 read GetItem write SetItem;
    /// Zebra: jede zweite Datenzeile (Color setzen schaltet es ein).
    property AlternateRow: TPPGElementStyle index 4 read GetItem write SetItem;
    /// Zeile unter der Maus (Color setzen schaltet es ein).
    property HotRow: TPPGElementStyle index 5 read GetItem write SetItem;
    /// Gitterlinien: Color = Linienfarbe.
    property GridLine: TPPGElementStyle index 6 read GetItem write SetItem;
    /// Fokuszelle: BorderColor = Rahmen, Color = Flaeche, TextColor.
    property FocusedCell: TPPGElementStyle index 7 read GetItem write SetItem;
    /// Gruppenkopf-Zeilen.
    property GroupRow: TPPGElementStyle index 8 read GetItem write SetItem;
    /// Filterzeile.
    property FilterRow: TPPGElementStyle index 9 read GetItem write SetItem;
  end;

  IPPGGridStylesHost = interface
    ['{6A1D3F85-C27E-4B90-8D54-E9F13B6A0C72}']
    procedure StylesChanged;
  end;

  TPPGGridConditionalFormat = class(TCollectionItem)
  private
    FColumn: Integer;
    FRule: TPPGCondRule;
    FValue1: string;
    FValue2: string;
    FColor: TPPGCondColor;
    FCustomColor: TColor;
    FTarget: TPPGCondTarget;
    FBold: Boolean;
    FEnabled: Boolean;
    // vorab berechnet
    FNum1, FNum2: Double;
    FHas1, FHas2: Boolean;
    FUpper1: string;
    FStatMin, FStatMax, FThreshold: Double;
    FStatsValid: Boolean;
    procedure SetColumn(const Value: Integer);
    procedure SetRule(const Value: TPPGCondRule);
    procedure SetValue1(const Value: string);
    procedure SetValue2(const Value: string);
    procedure SetColor(const Value: TPPGCondColor);
    procedure SetCustomColor(const Value: TColor);
    procedure SetTarget(const Value: TPPGCondTarget);
    procedure SetBold(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
  protected
    function GetDisplayName: string; override;
  public
    constructor Create(Collection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    procedure Compile;
    /// Braucht Werte der ganzen Spalte (Min/Max/N-ter Wert)?
    function NeedsStats: Boolean;
    /// Statistik aus den Zahlen der Spalte (Ansicht, gefiltert).
    procedure ComputeStats(const Values: TArray<Double>);
    function RuleColor(const Tokens: TPPGTokens): TColor;
  published
    /// Datenspalte; -1 = alle Spalten (nur Regeln ohne Statistik).
    property Column: Integer read FColumn write SetColumn default -1;
    property Rule: TPPGCondRule read FRule write SetRule default crRange;
    /// Bereich: Value1 = von, Value2 = bis ('' = offen); Gleich/Enthaelt:
    /// Value1; Oben/Unten: Value1 = Anzahl (z.B. '10' oder '10%').
    property Value1: string read FValue1 write SetValue1;
    property Value2: string read FValue2 write SetValue2;
    property Color: TPPGCondColor read FColor write SetColor default ccWarning;
    property CustomColor: TColor read FCustomColor write SetCustomColor default clNone;
    property Target: TPPGCondTarget read FTarget write SetTarget default ctFill;
    property Bold: Boolean read FBold write SetBold default False;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
  end;

/// Zahl aus Zelltext (auch mit Tausendertrennern) - wie die Regeln selbst.
function PPGCondParseNumber(const S: string; out V: Double): Boolean;

type
  TPPGGridConditionalFormats = class(TOwnedCollection)
  private
    function GetItem(Index: Integer): TPPGGridConditionalFormat;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    function Add: TPPGGridConditionalFormat;
    /// Gibt es Regeln fuer diese Datenspalte?
    function HasRulesFor(ACol: Integer): Boolean;
    function NeedsStats: Boolean;
    /// Regeln auf eine Zelle anwenden. GridFill = Hintergrund des Grids (die
    /// Fuellfarben werden damit gemischt, Text bleibt lesbar).
    procedure Apply(ACol: Integer; const Text: string; const Tokens: TPPGTokens;
      GridFill: TColor; var Style: TPPGGridCellStyle);
    property Items[Index: Integer]: TPPGGridConditionalFormat read GetItem; default;
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, PPG.NumberFormat;

{ TPPGGridCellStyle }

procedure TPPGGridCellStyle.Reset;
begin
  FontStyle := [];
  FontName := '';
  FontSize := 0;
  Fill := clNone;
  TextColor := clNone;
  Bold := False;
  Bar := -1;
  BarColor := clNone;
  Icon := -1;
  IconColor := clNone;
end;

function TPPGGridCellStyle.IsDefault: Boolean;
begin
  Result := (Fill = clNone) and (TextColor = clNone) and not Bold and (Bar < 0) and (Icon < 0) and
    (FontStyle = []) and (FontName = '') and (FontSize = 0);
end;

{ TPPGGridStyles }

constructor TPPGGridStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 10);
end;

function PPGCondParseNumber(const S: string; out V: Double): Boolean;
begin
  Result := (S <> '') and (TryStrToFloat(S, V) or PPGParseNumber(S, FormatSettings, V));
end;

{ TPPGGridConditionalFormat }

constructor TPPGGridConditionalFormat.Create(Collection: TCollection);
begin
  FColumn := -1;
  FCustomColor := clNone;
  FEnabled := True;
  inherited Create(Collection);
end;

procedure TPPGGridConditionalFormat.Assign(Source: TPersistent);
var
  S: TPPGGridConditionalFormat;
begin
  if Source is TPPGGridConditionalFormat then
  begin
    S := TPPGGridConditionalFormat(Source);
    FColumn := S.FColumn;
    FRule := S.FRule;
    FValue1 := S.FValue1;
    FValue2 := S.FValue2;
    FColor := S.FColor;
    FCustomColor := S.FCustomColor;
    FTarget := S.FTarget;
    FBold := S.FBold;
    FEnabled := S.FEnabled;
    Changed(False);
  end
  else
    inherited Assign(Source);
end;

function TPPGGridConditionalFormat.GetDisplayName: string;
const
  Names: array[TPPGCondRule] of string = ('Range', 'Equal', 'Contains', 'Top', 'Bottom',
    'ColorScale', 'DataBar', 'IconSet');
begin
  Result := Names[FRule];
  if FColumn >= 0 then
    Result := Result + ' [' + IntToStr(FColumn) + ']';
end;

procedure TPPGGridConditionalFormat.Compile;
begin
  FHas1 := PPGCondParseNumber(FValue1, FNum1);
  FHas2 := PPGCondParseNumber(FValue2, FNum2);
  FUpper1 := AnsiUpperCase(FValue1);
end;

function TPPGGridConditionalFormat.NeedsStats: Boolean;
begin
  Result := FEnabled and (FColumn >= 0) and
    (FRule in [crTop, crBottom, crColorScale, crDataBar, crIconSet]);
end;

procedure TPPGGridConditionalFormat.ComputeStats(const Values: TArray<Double>);
var
  Sorted: TArray<Double>;
  N, K: Integer;
  T: string;
begin
  N := Length(Values);
  FStatsValid := N > 0;
  if not FStatsValid then
    Exit;
  Sorted := Copy(Values);
  TArray.Sort<Double>(Sorted);
  FStatMin := Sorted[0];
  FStatMax := Sorted[N - 1];
  if FRule in [crTop, crBottom] then
  begin
    // Anzahl: '10' oder '10%' (Vorgabe 10)
    T := Trim(FValue1);
    if (T <> '') and (T[Length(T)] = '%') then
      K := Round(N * StrToIntDef(Copy(T, 1, Length(T) - 1), 10) / 100)
    else
      K := StrToIntDef(T, 10);
    if K < 1 then
      K := 1;
    if K > N then
      K := N;
    if FRule = crTop then
      FThreshold := Sorted[N - K]
    else
      FThreshold := Sorted[K - 1];
  end;
end;

function TPPGGridConditionalFormat.RuleColor(const Tokens: TPPGTokens): TColor;
begin
  case FColor of
    ccSuccess: Result := Tokens.Success;
    ccDanger: Result := Tokens.Danger;
    ccAccent: Result := Tokens.Accent;
    ccCustom:
      if FCustomColor <> clNone then
        Result := FCustomColor
      else
        Result := Tokens.Warning;
  else
    Result := Tokens.Warning;
  end;
end;

procedure TPPGGridConditionalFormat.SetColumn(const Value: Integer);
begin
  if FColumn <> Value then
  begin
    FColumn := PPGCheckRange(Self, 'Column', Value, -1, 100000);
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetRule(const Value: TPPGCondRule);
begin
  if FRule <> Value then
  begin
    FRule := Value;
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetValue1(const Value: string);
begin
  if FValue1 <> Value then
  begin
    FValue1 := Value;
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetValue2(const Value: string);
begin
  if FValue2 <> Value then
  begin
    FValue2 := Value;
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetColor(const Value: TPPGCondColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetCustomColor(const Value: TColor);
begin
  if FCustomColor <> Value then
  begin
    FCustomColor := Value;
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetTarget(const Value: TPPGCondTarget);
begin
  if FTarget <> Value then
  begin
    FTarget := Value;
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetBold(const Value: Boolean);
begin
  if FBold <> Value then
  begin
    FBold := Value;
    Changed(False);
  end;
end;

procedure TPPGGridConditionalFormat.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    Changed(False);
  end;
end;

{ TPPGGridConditionalFormats }

function TPPGGridConditionalFormats.Add: TPPGGridConditionalFormat;
begin
  Result := TPPGGridConditionalFormat(inherited Add);
end;

function TPPGGridConditionalFormats.GetItem(Index: Integer): TPPGGridConditionalFormat;
begin
  Result := TPPGGridConditionalFormat(inherited Items[Index]);
end;

procedure TPPGGridConditionalFormats.Update(Item: TCollectionItem);
var
  I: Integer;
  H: IPPGGridStylesHost;
begin
  inherited Update(Item);
  for I := 0 to Count - 1 do
    Items[I].Compile;
  if (GetOwner is TComponent) and (csLoading in TComponent(GetOwner).ComponentState) then
    Exit;
  if Supports(GetOwner, IPPGGridStylesHost, H) then
    H.StylesChanged;
end;

function TPPGGridConditionalFormats.HasRulesFor(ACol: Integer): Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].FEnabled and ((Items[I].FColumn = ACol) or
      ((Items[I].FColumn < 0) and not Items[I].NeedsStats)) then
      Exit(True);
  Result := False;
end;

function TPPGGridConditionalFormats.NeedsStats: Boolean;
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
    if Items[I].NeedsStats then
      Exit(True);
  Result := False;
end;

procedure TPPGGridConditionalFormats.Apply(ACol: Integer; const Text: string;
  const Tokens: TPPGTokens; GridFill: TColor; var Style: TPPGGridCellStyle);
var
  I: Integer;
  R: TPPGGridConditionalFormat;
  V, T: Double;
  IsNum, Hit: Boolean;
  C: TColor;
begin
  IsNum := PPGCondParseNumber(Text, V);
  for I := 0 to Count - 1 do
  begin
    R := Items[I];
    if not R.FEnabled then
      Continue;
    if R.FColumn >= 0 then
    begin
      if R.FColumn <> ACol then
        Continue;
    end
    else if R.NeedsStats or (R.FRule in [crTop, crBottom, crColorScale, crDataBar, crIconSet]) then
      Continue;
    C := R.RuleColor(Tokens);
    Hit := False;
    case R.FRule of
      crRange:
        Hit := IsNum and (not R.FHas1 or (V >= R.FNum1)) and (not R.FHas2 or (V <= R.FNum2)) and
          (R.FHas1 or R.FHas2);
      crEqual:
        Hit := SameText(Text, R.FValue1) or (IsNum and R.FHas1 and (V = R.FNum1));
      crContains:
        Hit := (R.FUpper1 <> '') and (Pos(R.FUpper1, AnsiUpperCase(Text)) > 0);
      crTop:
        Hit := IsNum and R.FStatsValid and (V >= R.FThreshold);
      crBottom:
        Hit := IsNum and R.FStatsValid and (V <= R.FThreshold);
      crColorScale, crDataBar, crIconSet:
        if IsNum and R.FStatsValid then
        begin
          if R.FStatMax > R.FStatMin then
            T := (V - R.FStatMin) / (R.FStatMax - R.FStatMin)
          else
            T := 1;
          if T < 0 then
            T := 0;
          if T > 1 then
            T := 1;
          case R.FRule of
            crColorScale:
              if Style.Fill = clNone then
              begin
                // Erfolg: niedrig rot -> hoch gruen; Fehler: umgekehrt;
                // sonst Hintergrund -> Regelfarbe
                case R.FColor of
                  ccSuccess:
                    if T < 0.5 then
                      C := PPGBlendColor(Tokens.Danger, Tokens.Warning, T * 2)
                    else
                      C := PPGBlendColor(Tokens.Warning, Tokens.Success, (T - 0.5) * 2);
                  ccDanger:
                    if T < 0.5 then
                      C := PPGBlendColor(Tokens.Success, Tokens.Warning, T * 2)
                    else
                      C := PPGBlendColor(Tokens.Warning, Tokens.Danger, (T - 0.5) * 2);
                else
                  C := PPGBlendColor(GridFill, C, T);
                end;
                Style.Fill := PPGBlendColor(GridFill, C, 0.45);
              end;
            crDataBar:
              if Style.Bar < 0 then
              begin
                Style.Bar := T;
                Style.BarColor := C;
              end;
            crIconSet:
              if Style.Icon < 0 then
              begin
                if T >= 2 / 3 then
                begin
                  Style.Icon := 2;
                  Style.IconColor := Tokens.Success;
                end
                else if T >= 1 / 3 then
                begin
                  Style.Icon := 1;
                  Style.IconColor := Tokens.Warning;
                end
                else
                begin
                  Style.Icon := 0;
                  Style.IconColor := Tokens.Danger;
                end;
              end;
          end;
        end;
    end;
    if not Hit then
      Continue;
    // Erste passende Regel gewinnt je Merkmal
    if R.FTarget = ctFill then
    begin
      if Style.Fill = clNone then
        Style.Fill := PPGBlendColor(GridFill, C, 0.3);
    end
    else if Style.TextColor = clNone then
      Style.TextColor := C;
    if R.FBold then
      Style.Bold := True;
  end;
end;

end.
