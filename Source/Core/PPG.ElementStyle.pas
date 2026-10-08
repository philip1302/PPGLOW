unit PPG.ElementStyle;

{ Element-Stile (Anpassbarkeit): Farben und Schrift eines Bereichs in einem
  grossen Control, z.B. Kopfzeile, Auswahl, Zebra-Zeilen oder Gitterlinien
  eines Grids.

  - clDefault bedeutet "vom Preset berechnet". Ohne gesetzte Werte sieht das
    Control also genau so aus wie bisher; nur gesetzte Werte ueberschreiben.
  - Color/TextColor/BorderColor gelten im hellen Modus, DarkColor/
    DarkTextColor/DarkBorderColor im Dark Mode (wie bei der Appearance gelten
    helle Farben im Dunkeln nicht). Im Hochkontrast gelten nur Systemfarben,
    mit VCL-Style die Farben des Styles; Schriften gelten immer.
  - Font wirkt erst mit ParentFont = False (wie bei der VCL: Font aendern
    setzt ParentFont auf False). FontStyle ergaenzt die Schrift immer um
    weitere Stile, auch mit ParentFont.
  - TPPGFontCache haelt die je Zeichenvorgang benoetigten Schriften (eigene
    TFont-Objekte); Controls leeren ihn nach dem Zeichnen, damit keine
    GDI-Handles dauerhaft belegt bleiben. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Generics.Collections, Vcl.Graphics;

type
  TPPGElementStyle = class(TPersistent)
  private
    FOwner: TPersistent;
    FColors: array[0..5] of TColor;
    FFont: TFont;
    FParentFont: Boolean;
    FFontStyle: TFontStyles;
    FOnChange: TNotifyEvent;
    FFontChanging: Boolean;
    function GetColor(Index: Integer): TColor;
    procedure SetColor(Index: Integer; const Value: TColor);
    procedure SetFont(const Value: TFont);
    procedure SetParentFont(const Value: Boolean);
    procedure SetFontStyle(const Value: TFontStyles);
    procedure FontChanged(Sender: TObject);
    function IsFontStored: Boolean;
  protected
    procedure Changed;
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function Equals(Obj: TObject): Boolean; override;
    /// Alle Werte auf "vom Preset" zuruecksetzen.
    procedure Clear;
    /// True, wenn nichts gesetzt ist.
    function IsEmpty: Boolean;
    /// Flaeche fuer den Modus; Default, wenn nicht gesetzt (als RGB).
    function FillFor(Dark: Boolean; Default: TColor): TColor;
    function TextFor(Dark: Boolean; Default: TColor): TColor;
    function BorderFor(Dark: Boolean; Default: TColor): TColor;
    /// True, wenn fuer den Modus eine Flaeche gesetzt ist.
    function HasFill(Dark: Boolean): Boolean;
    function HasText(Dark: Boolean): Boolean;
    function HasBorder(Dark: Boolean): Boolean;
    /// Schrift des Elements: Base (ParentFont) bzw. Font, jeweils plus FontStyle.
    function HasOwnFont: Boolean;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    property Color: TColor index 0 read GetColor write SetColor default clDefault;
    property TextColor: TColor index 1 read GetColor write SetColor default clDefault;
    property BorderColor: TColor index 2 read GetColor write SetColor default clDefault;
    property DarkColor: TColor index 3 read GetColor write SetColor default clDefault;
    property DarkTextColor: TColor index 4 read GetColor write SetColor default clDefault;
    property DarkBorderColor: TColor index 5 read GetColor write SetColor default clDefault;
    property ParentFont: Boolean read FParentFont write SetParentFont default True;
    property Font: TFont read FFont write SetFont stored IsFontStored;
    property FontStyle: TFontStyles read FFontStyle write SetFontStyle default [];
  end;

  /// Basis fuer Gruppen von Element-Stilen eines Controls (z.B. Navigation:
  /// Leiste, Eintrag, Hover, gewaehlt). Nachfahren veroeffentlichen die
  /// Bereiche als "property X: TPPGElementStyle index N read GetItem write SetItem".
  TPPGStyleGroup = class(TPersistent)
  private
    FOwner: TPersistent;
    FItems: array of TPPGElementStyle;
    FOnChange: TNotifyEvent;
    procedure ItemChanged(Sender: TObject);
  protected
    function GetItem(Index: Integer): TPPGElementStyle;
    procedure SetItem(Index: Integer; const Value: TPPGElementStyle);
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent; ACount: Integer);
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    function IsEmpty: Boolean;
    function Count: Integer;
    property Items[Index: Integer]: TPPGElementStyle read GetItem;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

/// Schrift eines Element-Stils ohne Zwischenspeicher: eigene Schrift (auf die
/// PPI von Base) bzw. Base, jeweils plus FontStyle und Extra. Liefert Base,
/// wenn nichts abweicht, sonst Temp (der Aufrufer gibt Temp frei).
function PPGElementFont(Style: TPPGElementStyle; Base: TFont; Extra: TFontStyles;
  var Temp: TFont): TFont;

type
  /// Schriften fuer einen Zeichenvorgang: Basis-Schrift plus Stil-Abweichungen.
  /// Schatten unter einer Flaeche (Elevation). Size = 0: kein Schatten.
  /// Werte in logischen px (skaliert); im Hochkontrast nie gezeichnet.
  TPPGShadow = class(TPersistent)
  private
    FOwner: TPersistent;
    FSize: Integer;
    FOffsetY: Integer;
    FColor: TColor;
    FOpacity: Integer;
    FOnChange: TNotifyEvent;
    procedure SetSize(const Value: Integer);
    procedure SetOffsetY(const Value: Integer);
    procedure SetColor(const Value: TColor);
    procedure SetOpacity(const Value: Integer);
    procedure Changed;
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AOwner: TPersistent);
    procedure Assign(Source: TPersistent); override;
    /// Size > 0 und Opacity > 0.
    function IsVisible: Boolean;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  published
    /// Weichzeichnung (Ausdehnung um die Flaeche), 0..64.
    property Size: Integer read FSize write SetSize default 0;
    /// Versatz nach unten (negativ: nach oben), -64..64.
    property OffsetY: Integer read FOffsetY write SetOffsetY default 2;
    property Color: TColor read FColor write SetColor default clBlack;
    /// Deckkraft direkt an der Kante, 0..255.
    property Opacity: Integer read FOpacity write SetOpacity default 64;
  end;

  TPPGFontCache = class
  private
    FFonts: TObjectList<TFont>;
    function Find(Base: TFont; Extra: TFontStyles; const AName: string;
      ASize, APPI: Integer): TFont;
  public
    constructor Create;
    destructor Destroy; override;
    /// Base, wenn nichts abweicht; sonst eine (zwischengespeicherte) Kopie.
    /// AName = '' bzw. ASize = 0: wie Base.
    function Get(Base: TFont; Extra: TFontStyles; const AName: string = '';
      ASize: Integer = 0): TFont;
    /// Schrift eines Element-Stils (Font bzw. Base, plus FontStyle und Extra).
    function ForStyle(Style: TPPGElementStyle; Base: TFont; Extra: TFontStyles = []): TFont;
    /// Alle Kopien freigeben (nach dem Zeichnen).
    procedure Clear;
  end;

implementation

uses
  System.SysUtils, System.UITypes, PPG.Types;

{ TPPGShadow }

constructor TPPGShadow.Create(AOwner: TPersistent);
begin
  inherited Create;
  FOwner := AOwner;
  FOffsetY := 2;
  FColor := clBlack;
  FOpacity := 64;
end;

function TPPGShadow.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGShadow.Assign(Source: TPersistent);
begin
  if Source is TPPGShadow then
  begin
    FSize := TPPGShadow(Source).FSize;
    FOffsetY := TPPGShadow(Source).FOffsetY;
    FColor := TPPGShadow(Source).FColor;
    FOpacity := TPPGShadow(Source).FOpacity;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGShadow.IsVisible: Boolean;
begin
  Result := (FSize > 0) and (FOpacity > 0);
end;

procedure TPPGShadow.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGShadow.SetSize(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Size', Value, 0, 64);
  if FSize <> V then
  begin
    FSize := V;
    Changed;
  end;
end;

procedure TPPGShadow.SetOffsetY(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'OffsetY', Value, -64, 64);
  if FOffsetY <> V then
  begin
    FOffsetY := V;
    Changed;
  end;
end;

procedure TPPGShadow.SetColor(const Value: TColor);
begin
  if FColor <> Value then
  begin
    FColor := Value;
    Changed;
  end;
end;

procedure TPPGShadow.SetOpacity(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'Opacity', Value, 0, 255);
  if FOpacity <> V then
  begin
    FOpacity := V;
    Changed;
  end;
end;

{ TPPGElementStyle }

constructor TPPGElementStyle.Create(AOwner: TPersistent);
var
  I: Integer;
begin
  inherited Create;
  FOwner := AOwner;
  for I := Low(FColors) to High(FColors) do
    FColors[I] := clDefault;
  FParentFont := True;
  FFont := TFont.Create;
  FFont.OnChange := FontChanged;
end;

destructor TPPGElementStyle.Destroy;
begin
  FOnChange := nil;
  FFont.Free;
  inherited Destroy;
end;

function TPPGElementStyle.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGElementStyle.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGElementStyle.Clear;
var
  I: Integer;
begin
  for I := Low(FColors) to High(FColors) do
    FColors[I] := clDefault;
  FParentFont := True;
  FFontStyle := [];
  Changed;
end;

function TPPGElementStyle.IsEmpty: Boolean;
var
  I: Integer;
begin
  Result := FParentFont and (FFontStyle = []);
  if Result then
    for I := Low(FColors) to High(FColors) do
      if FColors[I] <> clDefault then
        Exit(False);
end;

procedure TPPGElementStyle.Assign(Source: TPersistent);
var
  S: TPPGElementStyle;
begin
  if Source is TPPGElementStyle then
  begin
    S := TPPGElementStyle(Source);
    FColors := S.FColors;
    FFontChanging := True;
    try
      FFont.Assign(S.FFont);
    finally
      FFontChanging := False;
    end;
    FParentFont := S.FParentFont;
    FFontStyle := S.FFontStyle;
    Changed;
  end
  else
    inherited Assign(Source);
end;

function TPPGElementStyle.Equals(Obj: TObject): Boolean;
var
  S: TPPGElementStyle;
  I: Integer;
begin
  if Obj = Self then
    Exit(True);
  if not (Obj is TPPGElementStyle) then
    Exit(False);
  S := TPPGElementStyle(Obj);
  for I := Low(FColors) to High(FColors) do
    if FColors[I] <> S.FColors[I] then
      Exit(False);
  Result := (FParentFont = S.FParentFont) and (FFontStyle = S.FFontStyle);
  if Result and not FParentFont then
    Result := (FFont.Name = S.FFont.Name) and (FFont.Size = S.FFont.Size) and
      (FFont.Style = S.FFont.Style) and (FFont.Color = S.FFont.Color);
end;

function TPPGElementStyle.GetColor(Index: Integer): TColor;
begin
  Result := FColors[Index];
end;

procedure TPPGElementStyle.SetColor(Index: Integer; const Value: TColor);
begin
  if FColors[Index] <> Value then
  begin
    FColors[Index] := Value;
    Changed;
  end;
end;

procedure TPPGElementStyle.SetFont(const Value: TFont);
begin
  FFont.Assign(Value); // FontChanged setzt ParentFont := False
end;

procedure TPPGElementStyle.FontChanged(Sender: TObject);
begin
  if FFontChanging then
    Exit;
  FParentFont := False;
  Changed;
end;

procedure TPPGElementStyle.SetParentFont(const Value: Boolean);
begin
  if FParentFont <> Value then
  begin
    FParentFont := Value;
    Changed;
  end;
end;

procedure TPPGElementStyle.SetFontStyle(const Value: TFontStyles);
begin
  if FFontStyle <> Value then
  begin
    FFontStyle := Value;
    Changed;
  end;
end;

function TPPGElementStyle.IsFontStored: Boolean;
begin
  Result := not FParentFont;
end;

function TPPGElementStyle.HasOwnFont: Boolean;
begin
  Result := not FParentFont;
end;

function TPPGElementStyle.HasFill(Dark: Boolean): Boolean;
begin
  if Dark then
    Result := FColors[3] <> clDefault
  else
    Result := FColors[0] <> clDefault;
end;

function TPPGElementStyle.HasText(Dark: Boolean): Boolean;
begin
  if Dark then
    Result := FColors[4] <> clDefault
  else
    Result := FColors[1] <> clDefault;
end;

function TPPGElementStyle.HasBorder(Dark: Boolean): Boolean;
begin
  if Dark then
    Result := FColors[5] <> clDefault
  else
    Result := FColors[2] <> clDefault;
end;

function Pick(C, Default: TColor): TColor;
begin
  if C = clDefault then
    Result := Default
  else
    Result := PPGColorToRGB(C);
end;

function TPPGElementStyle.FillFor(Dark: Boolean; Default: TColor): TColor;
begin
  if Dark then
    Result := Pick(FColors[3], Default)
  else
    Result := Pick(FColors[0], Default);
end;

function TPPGElementStyle.TextFor(Dark: Boolean; Default: TColor): TColor;
begin
  if Dark then
    Result := Pick(FColors[4], Default)
  else
    Result := Pick(FColors[1], Default);
end;

function TPPGElementStyle.BorderFor(Dark: Boolean; Default: TColor): TColor;
begin
  if Dark then
    Result := Pick(FColors[5], Default)
  else
    Result := Pick(FColors[2], Default);
end;

function PPGElementFont(Style: TPPGElementStyle; Base: TFont; Extra: TFontStyles;
  var Temp: TFont): TFont;
begin
  if (Style = nil) or not Style.HasOwnFont then
  begin
    if Style <> nil then
      Extra := Extra + Style.FontStyle;
    Exit(PPGStyledFont(Base, Extra, Temp));
  end;
  if Temp = nil then
    Temp := TFont.Create;
  Temp.Assign(Style.Font);
  Temp.PixelsPerInch := Base.PixelsPerInch;
  Temp.Size := Style.Font.Size;
  Temp.Style := Style.Font.Style + Style.FontStyle + Extra;
  Result := Temp;
end;

{ TPPGStyleGroup }

constructor TPPGStyleGroup.Create(AOwner: TPersistent; ACount: Integer);
var
  I: Integer;
begin
  inherited Create;
  FOwner := AOwner;
  SetLength(FItems, ACount);
  for I := 0 to ACount - 1 do
  begin
    FItems[I] := TPPGElementStyle.Create(Self);
    FItems[I].OnChange := ItemChanged;
  end;
end;

destructor TPPGStyleGroup.Destroy;
var
  I: Integer;
begin
  FOnChange := nil;
  for I := High(FItems) downto 0 do
    FItems[I].Free;
  inherited Destroy;
end;

function TPPGStyleGroup.GetOwner: TPersistent;
begin
  Result := FOwner;
end;

procedure TPPGStyleGroup.ItemChanged(Sender: TObject);
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

function TPPGStyleGroup.GetItem(Index: Integer): TPPGElementStyle;
begin
  Result := FItems[Index];
end;

procedure TPPGStyleGroup.SetItem(Index: Integer; const Value: TPPGElementStyle);
begin
  FItems[Index].Assign(Value);
end;

procedure TPPGStyleGroup.Assign(Source: TPersistent);
var
  I: Integer;
begin
  if (Source is TPPGStyleGroup) and (Source.ClassType = ClassType) then
  begin
    for I := 0 to High(FItems) do
      FItems[I].Assign(TPPGStyleGroup(Source).FItems[I]);
  end
  else
    inherited Assign(Source);
end;

function TPPGStyleGroup.IsEmpty: Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to High(FItems) do
    if not FItems[I].IsEmpty then
      Exit(False);
end;

function TPPGStyleGroup.Count: Integer;
begin
  Result := Length(FItems);
end;

{ TPPGFontCache }

constructor TPPGFontCache.Create;
begin
  inherited Create;
  FFonts := TObjectList<TFont>.Create(True);
end;

destructor TPPGFontCache.Destroy;
begin
  FFonts.Free;
  inherited Destroy;
end;

procedure TPPGFontCache.Clear;
begin
  FFonts.Clear;
end;

function TPPGFontCache.Find(Base: TFont; Extra: TFontStyles; const AName: string;
  ASize, APPI: Integer): TFont;
var
  I: Integer;
  F: TFont;
  N: string;
  Sz: Integer;
begin
  N := AName;
  if N = '' then
    N := Base.Name;
  Sz := ASize;
  if Sz = 0 then
    Sz := Base.Size;
  if APPI <= 0 then
    APPI := Base.PixelsPerInch;
  for I := 0 to FFonts.Count - 1 do
  begin
    F := FFonts[I];
    if (F.Name = N) and (F.Size = Sz) and (F.Style = Base.Style + Extra) and
      (F.Charset = Base.Charset) and (F.Color = Base.Color) and
      (F.PixelsPerInch = APPI) then
      Exit(F);
  end;
  F := TFont.Create;
  try
    F.Assign(Base);
    // Groesse in Punkten auf die PPI des Controls (eigene Element-Schriften
    // werden von der VCL beim DPI-Wechsel nicht mitskaliert)
    F.PixelsPerInch := APPI;
    F.Name := N;
    F.Size := Sz;
    F.Style := Base.Style + Extra;
    FFonts.Add(F);
  except
    F.Free;
    raise;
  end;
  Result := F;
end;

function TPPGFontCache.Get(Base: TFont; Extra: TFontStyles; const AName: string;
  ASize: Integer): TFont;
begin
  if Base = nil then
    Exit(nil);
  if (Extra - Base.Style = []) and ((AName = '') or (AName = Base.Name)) and
    ((ASize = 0) or (ASize = Base.Size)) then
    Exit(Base);
  Result := Find(Base, Extra, AName, ASize, 0);
end;

function TPPGFontCache.ForStyle(Style: TPPGElementStyle; Base: TFont;
  Extra: TFontStyles): TFont;
begin
  if Style = nil then
    Exit(Get(Base, Extra));
  if Style.HasOwnFont then
    Result := Find(Style.Font, Style.FontStyle + Extra, '', 0, Base.PixelsPerInch)
  else
    Result := Get(Base, Style.FontStyle + Extra);
end;

end.
