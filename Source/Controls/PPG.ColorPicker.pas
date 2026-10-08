unit PPG.ColorPicker;

{ TPPGColorPicker - Farbauswahl mit Palette (Phase 12d).

  - Feld mit Farbfeld und Namen bzw. Hexwert; das Popup (TPPGColorPopup) nutzt
    die Aufklapp-Basis (PPG.Controls.DropDown) und PPG.Popup.Placement.
  - Abschnitte: Designfarben (Akzent, Signalfarben, Diagramm-Palette des
    Presets), Standardfarben (16 + erweiterte), Systemfarben, zuletzt benutzt
    (RecentColors, im DFM gespeichert), "Keine"/"Standard".
  - "Weitere Farben...": eigenes HSV-Feld (Saettigung/Helligkeit-Flaeche,
    Farbton-Leiste) mit Hex-Eingabe im Popup - kein Windows-ChooseColor,
    damit es dem Preset und dem Dark Mode folgt. Die Hex-Eingabe laeuft ueber
    die Tastatur des Felds (das Popup wird nie aktiviert).
  - Style wie TColorBox.Style (TColorBoxStyle, cbStandardColors, ...),
    Selected: TColor, clNone/clDefault fuer "keine"/"Standard".
  - Tastatur: Pfeile im Raster, Enter uebernimmt, Esc verwirft; im HSV-Teil
    Hex tippen, Enter uebernimmt. Screenreader: Farben als Kinder mit Namen.
  - OnChange nur bei Auswahl durch den Anwender; Selected aus Code ohne. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base,
  PPG.Controls.Field, PPG.Controls.DropDown, PPG.Popup, PPG.Popup.Placement;

type
  TPPGColorCellKind = (cckColor, cckNone, cckDefault, cckMore, cckApply, cckHeader);

  TPPGColorCell = record
    Kind: TPPGColorCellKind;
    Color: TColor;
    Name: string;
    Rect: TRect;
  end;

  TPPGColorPicker = class;

  TPPGColorPopup = class(TPPGDropPopup, IPPGAccessibleChildren)
  private
    FPicker: TPPGColorPicker;
    FCells: TArray<TPPGColorCell>;
    FHot: Integer;
    FFocus: Integer;
    FCustom: Boolean;
    FHue, FSat, FVal: Double;
    FHex: string;
    FDragSV: Boolean;
    FDragHue: Boolean;
    FSVRect: TRect;
    FHueRect: TRect;
    FPreviewRect: TRect;
    FHexRect: TRect;
    FSVBitmap: TBitmap;
    FSVBitmapHue: Double;
    FHueBitmap: TBitmap;
    FResult: TColor;
    FHasResult: Boolean;
    FWidth: Integer;
    FHeight: Integer;
    FSmallFont: TFont;
    procedure BuildCells;
    procedure AddHeader(const Caption: string; var Y: Integer);
    procedure AddGrid(const Colors: array of TColor; var Y: Integer);
    procedure AddWide(Kind: TPPGColorCellKind; AColor: TColor; const Caption: string;
      var Y: Integer);
    function S(V: Integer): Integer;
    function CellAt(X, Y: Integer): Integer;
    function Selectable(Index: Integer): Boolean;
    procedure MoveFocus(DX, DY: Integer);
    procedure SetCustomFromColor(C: TColor);
    function CustomColor: TColor;
    procedure UpdateSVFromPoint(X, Y: Integer);
    procedure UpdateHueFromPoint(X: Integer);
    procedure EnsureBitmaps;
    procedure Relayout;
    function Activate(Index: Integer): TPPGDropAction;
  protected
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function AccName: string; override;
    function AccRole: Integer; override;
    { IPPGAccessibleChildren }
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string;
    function AccChildRole(Id: Integer): Integer;
    function AccChildState(Id: Integer): Integer;
    function AccChildRect(Id: Integer): TRect;
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string;
    procedure AccChildDoDefault(Id: Integer);
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Prepare(APicker: TPPGColorPicker);
    function PreferredSize(FieldWidth: Integer): TSize; override;
    procedure DropMouseMove(X, Y: Integer; Shift: TShiftState); override;
    function DropMouseDown(X, Y: Integer): TPPGDropAction; override;
    function DropMouseUp(X, Y: Integer): TPPGDropAction; override;
    function DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction; override;
    function DropKeyPress(var Key: Char): TPPGDropAction; override;
    procedure DropMouseLeave; override;
    function CellCount: Integer;
    function Cell(Index: Integer): TPPGColorCell;
    function IndexOfColor(C: TColor): Integer;
    /// HSV-Teil ein-/ausblenden ("Weitere Farben...").
    procedure SetCustomMode(Value: Boolean);
    property CustomMode: Boolean read FCustom;
    property FocusIndex: Integer read FFocus;
    property HexText: string read FHex;
    property Hue: Double read FHue;
    property Saturation: Double read FSat;
    property Brightness: Double read FVal;
    property ResultColor: TColor read FResult;
    property HasResult: Boolean read FHasResult;
  end;

  TPPGColorPicker = class(TPPGCustomDropDownField, IPPGFieldValue)
  private
    FSelected: TColor;
    FStyle: TColorBoxStyle;
    FShowThemeColors: Boolean;
    FRecent: TStrings;
    FMaxRecent: Integer;
    FNoneColorColor: TColor;
    FDefaultColorColor: TColor;
    FShowHex: Boolean;
    procedure SetSelected(const Value: TColor);
    procedure SetStyle(const Value: TColorBoxStyle);
    procedure SetRecent(const Value: TStrings);
    procedure SetMaxRecent(const Value: Integer);
    procedure SetShowHex(const Value: Boolean);
    procedure RecentChanged(Sender: TObject);
  protected
    function CreatePopup: TPPGDropPopup; override;
    procedure PreparePopup(APopup: TPPGDropPopup); override;
    procedure AcceptPopup(APopup: TPPGDropPopup); override;
    procedure ClosedKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccValue: string; override;
    { IPPGFieldValue }
    function FieldIsNull: Boolean;
    procedure FieldClear;
    function GetFieldValue: Variant;
    procedure SetFieldValue(const Value: Variant);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Auswahl wie durch den Anwender (OnChange, zuletzt benutzt).
    procedure SelectColor(AColor: TColor);
    /// Name fuer Anzeige und Screenreader ("Rot", "#1A2B3C", "Keine").
    function ColorName(AColor: TColor): string;
    /// Farbe vorn in "zuletzt benutzt" (ohne Doppelte, MaxRecent).
    procedure AddRecentColor(AColor: TColor);
    function RecentColor(Index: Integer): TColor;
    function RecentCount: Integer;
  published
    property Selected: TColor read FSelected write SetSelected default clBlack;
    property Style: TColorBoxStyle read FStyle write SetStyle
      default [cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames];
    property ShowThemeColors: Boolean read FShowThemeColors write FShowThemeColors default True;
    /// Zuletzt benutzte Farben als Hex ("#RRGGBB"), neueste zuerst.
    property RecentColors: TStrings read FRecent write SetRecent;
    property MaxRecent: Integer read FMaxRecent write SetMaxRecent default 8;
    /// Hexwert statt Name anzeigen.
    property ShowHex: Boolean read FShowHex write SetShowHex default False;
    property NoneColorColor: TColor read FNoneColorColor write FNoneColorColor default clBlack;
    property DefaultColorColor: TColor read FDefaultColorColor write FDefaultColorColor
      default clBlack;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnCloseUp;
    property OnDropDown;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Appearance, PPG.DpiUtils, PPG.Theme, PPG.Lang,
  PPG.Consts, PPG.ColorSpace, PPG.Chart.Palette, PPG.Render.Registry, PPG.Render.Gdi;

const
  StandardColors: array[0..15] of TColor = (clBlack, clMaroon, clGreen, clOlive, clNavy,
    clPurple, clTeal, clGray, clSilver, clRed, clLime, clYellow, clBlue, clFuchsia, clAqua,
    clWhite);
  ExtendedColors: array[0..3] of TColor = (clMoneyGreen, clSkyBlue, clCream, clMedGray);
  SystemColors: array[0..23] of TColor = (clScrollBar, clBackground, clActiveCaption,
    clInactiveCaption, clMenu, clWindow, clWindowFrame, clMenuText, clWindowText,
    clCaptionText, clActiveBorder, clInactiveBorder, clAppWorkSpace, clHighlight,
    clHighlightText, clBtnFace, clBtnShadow, clGrayText, clBtnText, clInactiveCaptionText,
    clBtnHighlight, cl3DDkShadow, cl3DLight, clInfoBk);
  Columns = 8;
  Swatch = 20;   // logische px
  SwGap = 4;
  Pad = 10;

function IfThenColor(B: Boolean; T, F: TColor): TColor;
begin
  if B then
    Result := T
  else
    Result := F;
end;

{ TPPGColorPopup }

constructor TPPGColorPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHot := -1;
  FFocus := -1;
  FSmallFont := TFont.Create;
  FSVBitmapHue := -1;
end;

destructor TPPGColorPopup.Destroy;
begin
  FreeAndNil(FSVBitmap);
  FreeAndNil(FHueBitmap);
  FreeAndNil(FSmallFont);
  inherited Destroy;
end;

function TPPGColorPopup.S(V: Integer): Integer;
begin
  Result := PPGScale(V, ScalePPI);
end;

procedure TPPGColorPopup.AddHeader(const Caption: string; var Y: Integer);
var
  N: Integer;
begin
  N := Length(FCells);
  SetLength(FCells, N + 1);
  FCells[N].Kind := cckHeader;
  FCells[N].Name := Caption;
  FCells[N].Rect := Rect(S(Pad), Y, FWidth - S(Pad), Y + S(18));
  Inc(Y, S(20));
end;

procedure TPPGColorPopup.AddGrid(const Colors: array of TColor; var Y: Integer);
var
  I, N, Col: Integer;
  X: Integer;
begin
  Col := 0;
  for I := 0 to High(Colors) do
  begin
    N := Length(FCells);
    SetLength(FCells, N + 1);
    FCells[N].Kind := cckColor;
    FCells[N].Color := Colors[I];
    FCells[N].Name := FPicker.ColorName(Colors[I]);
    X := S(Pad) + Col * (S(Swatch) + S(SwGap));
    FCells[N].Rect := Rect(X, Y, X + S(Swatch), Y + S(Swatch));
    Inc(Col);
    if Col = Columns then
    begin
      Col := 0;
      Inc(Y, S(Swatch) + S(SwGap));
    end;
  end;
  if Col > 0 then
    Inc(Y, S(Swatch) + S(SwGap));
  Inc(Y, S(4));
end;

procedure TPPGColorPopup.AddWide(Kind: TPPGColorCellKind; AColor: TColor;
  const Caption: string; var Y: Integer);
var
  N: Integer;
begin
  N := Length(FCells);
  SetLength(FCells, N + 1);
  FCells[N].Kind := Kind;
  FCells[N].Color := AColor;
  FCells[N].Name := Caption;
  FCells[N].Rect := Rect(S(Pad), Y, FWidth - S(Pad), Y + S(26));
  Inc(Y, S(28));
end;

procedure TPPGColorPopup.BuildCells;
var
  Y, I: Integer;
  T: TPPGTokens;
  Dark: Boolean;
  Theme: array of TColor;
  Recent: array of TColor;
begin
  SetLength(FCells, 0);
  FWidth := 2 * S(Pad) + Columns * S(Swatch) + (Columns - 1) * S(SwGap);
  Y := S(Pad);
  if cbIncludeNone in FPicker.Style then
    AddWide(cckNone, clNone, FPicker.ColorName(clNone), Y);
  if cbIncludeDefault in FPicker.Style then
    AddWide(cckDefault, clDefault, FPicker.ColorName(clDefault), Y);
  if FPicker.ShowThemeColors then
  begin
    T := FPicker.Tokens;
    Dark := FPicker.UseDarkMode;
    SetLength(Theme, 0);
    SetLength(Theme, Columns);
    for I := 0 to Columns - 1 do
      Theme[I] := PPGChartColor(T, Dark, I);
    AddHeader(PPGStr(@SPPGColorTheme), Y);
    AddGrid(Theme, Y);
  end;
  if FPicker.Style * [cbStandardColors, cbExtendedColors] <> [] then
  begin
    AddHeader(PPGStr(@SPPGColorStandard), Y);
    if cbStandardColors in FPicker.Style then
      AddGrid(StandardColors, Y);
    if cbExtendedColors in FPicker.Style then
      AddGrid(ExtendedColors, Y);
  end;
  if cbSystemColors in FPicker.Style then
  begin
    AddHeader(PPGStr(@SPPGColorSystem), Y);
    AddGrid(SystemColors, Y);
  end;
  if FPicker.RecentCount > 0 then
  begin
    SetLength(Recent, FPicker.RecentCount);
    for I := 0 to FPicker.RecentCount - 1 do
      Recent[I] := FPicker.RecentColor(I);
    AddHeader(PPGStr(@SPPGColorRecent), Y);
    AddGrid(Recent, Y);
  end;
  if cbCustomColor in FPicker.Style then
  begin
    AddWide(cckMore, clNone, PPGStr(@SPPGColorMore), Y);
    if FCustom then
    begin
      FSVRect := Rect(S(Pad), Y, FWidth - S(Pad), Y + S(120));
      Inc(Y, S(126));
      FHueRect := Rect(S(Pad), Y, FWidth - S(Pad), Y + S(14));
      Inc(Y, S(22));
      FPreviewRect := Rect(S(Pad), Y, S(Pad) + S(26), Y + S(26));
      FHexRect := Rect(FPreviewRect.Right + S(8), Y, FWidth - S(Pad) - S(80), Y + S(26));
      AddWide(cckApply, clNone, PPGStr(@SPPGColorApply), Y);
      // Uebernehmen-Button rechts neben dem Hexfeld
      FCells[High(FCells)].Rect := Rect(FWidth - S(Pad) - S(72), FPreviewRect.Top,
        FWidth - S(Pad), FPreviewRect.Bottom);
    end;
  end;
  FHeight := Y + S(Pad) - S(4);
end;

procedure TPPGColorPopup.Prepare(APicker: TPPGColorPicker);
begin
  FPicker := APicker;
  FCustom := False;
  FHasResult := False;
  FHot := -1;
  FSmallFont.Assign(Font);
  FSmallFont.Height := MulDiv(Font.Height, 9, 10);
  SetCustomFromColor(APicker.Selected);
  BuildCells;
  FFocus := IndexOfColor(APicker.Selected);
  if FFocus < 0 then
    MoveFocus(1, 0);
end;

function TPPGColorPopup.PreferredSize(FieldWidth: Integer): TSize;
begin
  Result.cx := FWidth;
  Result.cy := FHeight;
end;

function TPPGColorPopup.CellCount: Integer;
begin
  Result := Length(FCells);
end;

function TPPGColorPopup.Cell(Index: Integer): TPPGColorCell;
begin
  Result := FCells[Index];
end;

function TPPGColorPopup.IndexOfColor(C: TColor): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FCells) do
    if (FCells[I].Kind in [cckColor, cckNone, cckDefault]) and (FCells[I].Color = C) then
      Exit(I);
  Result := -1;
end;

function TPPGColorPopup.Selectable(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index <= High(FCells)) and (FCells[Index].Kind <> cckHeader);
end;

function TPPGColorPopup.CellAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FCells) do
    if Selectable(I) and PtInRect(FCells[I].Rect, Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

procedure TPPGColorPopup.MoveFocus(DX, DY: Integer);
var
  I, Best, D, BestD, CX, CY: Integer;
  R: TRect;
begin
  if Length(FCells) = 0 then
    Exit;
  if not Selectable(FFocus) then
  begin
    for I := 0 to High(FCells) do
      if Selectable(I) then
      begin
        FFocus := I;
        Break;
      end;
    Invalidate;
    Exit;
  end;
  if DY = 0 then
  begin
    // Links/rechts: naechste waehlbare Zelle in Lesereihenfolge
    I := FFocus;
    repeat
      Inc(I, DX);
    until (I < 0) or (I > High(FCells)) or Selectable(I);
    if Selectable(I) then
      FFocus := I;
  end
  else
  begin
    // Hoch/runter: naechste Zeile, waagerecht am naechsten
    R := FCells[FFocus].Rect;
    CX := (R.Left + R.Right) div 2;
    CY := (R.Top + R.Bottom) div 2;
    Best := -1;
    BestD := MaxInt;
    for I := 0 to High(FCells) do
    begin
      if not Selectable(I) or (I = FFocus) then
        Continue;
      if (DY > 0) and (FCells[I].Rect.Top <= R.Top) then
        Continue;
      if (DY < 0) and (FCells[I].Rect.Top >= R.Top) then
        Continue;
      D := Abs((FCells[I].Rect.Top + FCells[I].Rect.Bottom) div 2 - CY) * 4 +
        Abs((FCells[I].Rect.Left + FCells[I].Rect.Right) div 2 - CX);
      if (FCells[I].Rect.Left <= CX) and (FCells[I].Rect.Right >= CX) then
        D := D - S(8); // breite Zeile unter dem Punkt bevorzugen
      if D < BestD then
      begin
        BestD := D;
        Best := I;
      end;
    end;
    if Best >= 0 then
      FFocus := Best;
  end;
  Invalidate;
  NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FFocus + 1);
end;

procedure TPPGColorPopup.SetCustomFromColor(C: TColor);
begin
  if (C = clNone) or (C = clDefault) then
    C := clRed;
  PPGColorToHSV(C, FHue, FSat, FVal);
  FHex := Copy(PPGColorToHex(C), 2, 6);
end;

function TPPGColorPopup.CustomColor: TColor;
begin
  Result := PPGHSVToColor(FHue, FSat, FVal);
end;

procedure TPPGColorPopup.SetCustomMode(Value: Boolean);
begin
  if FCustom = Value then
    Exit;
  FCustom := Value;
  Relayout;
end;

procedure TPPGColorPopup.Relayout;
var
  R: TRect;
  OldH: Integer;
begin
  OldH := FHeight;
  BuildCells;
  if not HandleAllocated or not IsOpen then
    Exit;
  GetWindowRect(Handle, R);
  // Nach oben geoeffnet: die Unterkante bleibt am Feld
  if OpenedAbove then
    R.Top := R.Bottom - FHeight
  else
    R.Bottom := R.Top + FHeight;
  if FHeight <> OldH then
  begin
    if OpenedAbove then
      PopupAt(R, ppsAbove, 0)
    else
      PopupAt(R, ppsBelow, 0);
  end;
  Invalidate;
end;

procedure TPPGColorPopup.EnsureBitmaps;
var
  W, H, X, Y: Integer;
  Line: PRGBTriple;
  C: TColor;
begin
  W := FSVRect.Right - FSVRect.Left;
  H := FSVRect.Bottom - FSVRect.Top;
  if (W <= 0) or (H <= 0) then
    Exit;
  if (FSVBitmap = nil) or (FSVBitmap.Width <> W) or (FSVBitmap.Height <> H) or
    (FSVBitmapHue <> FHue) then
  begin
    if FSVBitmap = nil then
      FSVBitmap := TBitmap.Create;
    FSVBitmap.PixelFormat := pf24bit;
    FSVBitmap.SetSize(W, H);
    for Y := 0 to H - 1 do
    begin
      Line := FSVBitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        C := PPGHSVToColor(FHue, X / Max(W - 1, 1), 1 - Y / Max(H - 1, 1));
        Line^.rgbtRed := C and $FF;
        Line^.rgbtGreen := (C shr 8) and $FF;
        Line^.rgbtBlue := (C shr 16) and $FF;
        Inc(Line);
      end;
    end;
    FSVBitmapHue := FHue;
  end;
  W := FHueRect.Right - FHueRect.Left;
  H := FHueRect.Bottom - FHueRect.Top;
  if (FHueBitmap = nil) or (FHueBitmap.Width <> W) or (FHueBitmap.Height <> H) then
  begin
    if FHueBitmap = nil then
      FHueBitmap := TBitmap.Create;
    FHueBitmap.PixelFormat := pf24bit;
    FHueBitmap.SetSize(W, H);
    for Y := 0 to H - 1 do
    begin
      Line := FHueBitmap.ScanLine[Y];
      for X := 0 to W - 1 do
      begin
        C := PPGHSVToColor(360 * X / Max(W - 1, 1), 1, 1);
        Line^.rgbtRed := C and $FF;
        Line^.rgbtGreen := (C shr 8) and $FF;
        Line^.rgbtBlue := (C shr 16) and $FF;
        Inc(Line);
      end;
    end;
  end;
end;

procedure TPPGColorPopup.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  L, H: TPPGSurfaceStyle;
  I, PPI, X, Y: Integer;
  R: TRect;
  C: TPPGColorCell;
  Text, Frame: TColor;
  DC: HDC;
  Hex: string;
begin
  if FPicker = nil then
    Exit;
  PPI := ScalePPI;
  T := Tokens;
  GetPopupStyles(T.Layer, T.TextPrimary, L, H);
  ACanvas.FillRoundRect(ClientR, 0, L.Color, 255);
  ACanvas.FrameRoundRect(ClientR, PopupRounding, Max(1, L.BorderWidth), L.BorderColor, 255);
  Text := L.TextColor;
  Frame := PPGBlendColor(L.Color, Text, 0.35);
  for I := 0 to High(FCells) do
  begin
    C := FCells[I];
    R := C.Rect;
    case C.Kind of
      cckHeader:
        ACanvas.DrawText(R, C.Name, FSmallFont, PPGBlendColor(Text, L.Color, 0.3),
          DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
      cckColor:
        begin
          ACanvas.FillRoundRect(R, PPGScale(3, PPI), PPGColorToRGB(C.Color), 255);
          ACanvas.FrameRoundRect(R, PPGScale(3, PPI), 1, Frame, 255);
          if (C.Color = FPicker.Selected) then
          begin
            InflateRect(R, PPGScale(2, PPI), PPGScale(2, PPI));
            ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI), Text, 255);
            R := C.Rect;
          end;
          if I = FHot then
          begin
            InflateRect(R, PPGScale(1, PPI), PPGScale(1, PPI));
            ACanvas.FrameRoundRect(R, PPGScale(4, PPI), 1, H.Color, 255);
            R := C.Rect;
          end;
        end;
    else
      begin
        // Breite Zeile: Keine/Standard/Weitere/Uebernehmen
        if (I = FHot) or (C.Kind = cckApply) then
        begin
          if C.Kind = cckApply then
            ACanvas.FillRoundRect(R, PPGScale(4, PPI), T.Accent, 255)
          else
            ACanvas.FillRoundRect(R, PPGScale(4, PPI), H.Color, 255);
        end;
        X := R.Left + PPGScale(6, PPI);
        if C.Kind in [cckNone, cckDefault] then
        begin
          ACanvas.FrameRoundRect(Rect(X, R.Top + PPGScale(4, PPI), X + PPGScale(18, PPI),
            R.Bottom - PPGScale(4, PPI)), PPGScale(3, PPI), 1, Frame, 255);
          if C.Kind = cckDefault then
            ACanvas.FillRoundRect(Rect(X + 2, R.Top + PPGScale(4, PPI) + 2,
              X + PPGScale(18, PPI) - 2, R.Bottom - PPGScale(4, PPI) - 2), PPGScale(2, PPI),
              PPGColorToRGB(FPicker.DefaultColorColor), 255)
          else
            ACanvas.DrawPolyline([Point(X + 2, R.Bottom - PPGScale(6, PPI)),
              Point(X + PPGScale(16, PPI), R.Top + PPGScale(6, PPI))], 1, T.Danger, 255);
          Inc(X, PPGScale(26, PPI));
        end;
        if C.Kind = cckApply then
          ACanvas.DrawText(R, C.Name, Font, T.OnAccent,
            DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX)
        else
          ACanvas.DrawText(Rect(X, R.Top, R.Right, R.Bottom), C.Name, Font,
            IfThenColor(I = FHot, H.TextColor, Text),
            DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
      end;
    end;
    // Tastaturfokus
    if (I = FFocus) and (C.Kind <> cckHeader) then
    begin
      R := C.Rect;
      InflateRect(R, PPGScale(3, PPI), PPGScale(3, PPI));
      ACanvas.FrameRoundRect(R, PPGScale(5, PPI), PPGScale(2, PPI),
        PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
    end;
  end;
  if FCustom then
  begin
    EnsureBitmaps;
    DC := ACanvas.BeginGdi;
    try
      if FSVBitmap <> nil then
        BitBlt(DC, FSVRect.Left, FSVRect.Top, FSVBitmap.Width, FSVBitmap.Height,
          FSVBitmap.Canvas.Handle, 0, 0, SRCCOPY);
      if FHueBitmap <> nil then
        BitBlt(DC, FHueRect.Left, FHueRect.Top, FHueBitmap.Width, FHueBitmap.Height,
          FHueBitmap.Canvas.Handle, 0, 0, SRCCOPY);
    finally
      ACanvas.EndGdi(DC);
    end;
    // Marken: Kreis im Feld, Strich in der Leiste
    X := FSVRect.Left + Round(FSat * (FSVRect.Right - FSVRect.Left - 1));
    Y := FSVRect.Top + Round((1 - FVal) * (FSVRect.Bottom - FSVRect.Top - 1));
    ACanvas.FrameEllipse(Rect(X - PPGScale(6, PPI), Y - PPGScale(6, PPI), X + PPGScale(6, PPI),
      Y + PPGScale(6, PPI)), PPGScale(2, PPI), clWhite, 255);
    ACanvas.FrameEllipse(Rect(X - PPGScale(7, PPI), Y - PPGScale(7, PPI), X + PPGScale(7, PPI),
      Y + PPGScale(7, PPI)), 1, clBlack, 255);
    X := FHueRect.Left + Round(FHue / 360 * (FHueRect.Right - FHueRect.Left - 1));
    ACanvas.FrameRoundRect(Rect(X - PPGScale(3, PPI), FHueRect.Top - PPGScale(2, PPI),
      X + PPGScale(3, PPI), FHueRect.Bottom + PPGScale(2, PPI)), PPGScale(2, PPI),
      PPGScale(2, PPI), Text, 255);
    ACanvas.FillRoundRect(FPreviewRect, PPGScale(3, PPI), CustomColor, 255);
    ACanvas.FrameRoundRect(FPreviewRect, PPGScale(3, PPI), 1, Frame, 255);
    // Hexfeld (eigene Eingabe ueber die Tastatur des Felds)
    ACanvas.FrameRoundRect(FHexRect, PPGScale(3, PPI), 1, Frame, 255);
    Hex := '#' + FHex + '|';
    ACanvas.DrawText(Rect(FHexRect.Left + PPGScale(6, PPI), FHexRect.Top, FHexRect.Right,
      FHexRect.Bottom), Hex, Font, Text, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;
end;

procedure TPPGColorPopup.UpdateSVFromPoint(X, Y: Integer);
begin
  FSat := EnsureRange((X - FSVRect.Left) / Max(FSVRect.Right - FSVRect.Left - 1, 1), 0, 1);
  FVal := EnsureRange(1 - (Y - FSVRect.Top) / Max(FSVRect.Bottom - FSVRect.Top - 1, 1), 0, 1);
  FHex := Copy(PPGColorToHex(CustomColor), 2, 6);
  Invalidate;
end;

procedure TPPGColorPopup.UpdateHueFromPoint(X: Integer);
begin
  FHue := EnsureRange(360 * (X - FHueRect.Left) / Max(FHueRect.Right - FHueRect.Left - 1, 1),
    0, 359.999);
  FHex := Copy(PPGColorToHex(CustomColor), 2, 6);
  Invalidate;
end;

function TPPGColorPopup.Activate(Index: Integer): TPPGDropAction;
var
  C: TColor;
begin
  Result := pdaNone;
  if not Selectable(Index) then
    Exit;
  case FCells[Index].Kind of
    cckColor, cckNone, cckDefault:
      begin
        FResult := FCells[Index].Color;
        FHasResult := True;
        Result := pdaAccept;
      end;
    cckMore:
      begin
        SetCustomMode(not FCustom);
        Result := pdaKeepOpen;
      end;
    cckApply:
      if PPGTryHexToColor(FHex, C) then
      begin
        FResult := C;
        FHasResult := True;
        Result := pdaAccept;
      end
      else
        MessageBeep(MB_ICONWARNING);
  end;
end;

procedure TPPGColorPopup.DropMouseMove(X, Y: Integer; Shift: TShiftState);
var
  I: Integer;
begin
  if FDragSV then
  begin
    UpdateSVFromPoint(X, Y);
    Exit;
  end;
  if FDragHue then
  begin
    UpdateHueFromPoint(X);
    Exit;
  end;
  I := CellAt(X, Y);
  if I <> FHot then
  begin
    FHot := I;
    Invalidate;
  end;
end;

procedure TPPGColorPopup.DropMouseLeave;
begin
  if FHot >= 0 then
  begin
    FHot := -1;
    Invalidate;
  end;
end;

function TPPGColorPopup.DropMouseDown(X, Y: Integer): TPPGDropAction;
begin
  Result := pdaNone;
  if FCustom and PtInRect(FSVRect, Point(X, Y)) then
  begin
    FDragSV := True;
    UpdateSVFromPoint(X, Y);
  end
  else if FCustom and PtInRect(FHueRect, Point(X, Y)) then
  begin
    FDragHue := True;
    UpdateHueFromPoint(X);
  end;
end;

function TPPGColorPopup.DropMouseUp(X, Y: Integer): TPPGDropAction;
var
  I: Integer;
begin
  if FDragSV or FDragHue then
  begin
    FDragSV := False;
    FDragHue := False;
    Exit(pdaKeepOpen);
  end;
  I := CellAt(X, Y);
  if I >= 0 then
  begin
    FFocus := I;
    Result := Activate(I);
  end
  else
    Result := pdaNone;
end;

function TPPGColorPopup.DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction;
begin
  Result := pdaNone;
  case Key of
    VK_LEFT: MoveFocus(-1, 0);
    VK_RIGHT: MoveFocus(1, 0);
    VK_UP: MoveFocus(0, -1);
    VK_DOWN: MoveFocus(0, 1);
    VK_HOME:
      begin
        FFocus := -1;
        MoveFocus(1, 0);
      end;
    VK_RETURN, VK_SPACE:
      begin
        // Im HSV-Teil uebernimmt Enter die eigene Farbe
        if (Key = VK_RETURN) and FCustom and
          ((FFocus < 0) or (FCells[FFocus].Kind in [cckApply, cckMore])) then
          Result := Activate(High(FCells))
        else
          Result := Activate(FFocus);
      end;
    VK_BACK:
      if FCustom and (FHex <> '') then
      begin
        Delete(FHex, Length(FHex), 1);
        Invalidate;
      end;
  else
    Exit;
  end;
  Key := 0;
end;

function TPPGColorPopup.DropKeyPress(var Key: Char): TPPGDropAction;
var
  C: TColor;
begin
  Result := pdaNone;
  // Hex-Eingabe im HSV-Teil
  if FCustom and CharInSet(Key, ['0'..'9', 'a'..'f', 'A'..'F']) then
  begin
    if Length(FHex) >= 6 then
      FHex := '';
    FHex := FHex + UpCase(Key);
    if (Length(FHex) = 6) and PPGTryHexToColor(FHex, C) then
      PPGColorToHSV(C, FHue, FSat, FVal);
    Invalidate;
  end;
end;

function TPPGColorPopup.AccName: string;
begin
  if FPicker <> nil then
    Result := FPicker.AccName
  else
    Result := '';
end;

function TPPGColorPopup.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TABLE;
end;

function TPPGColorPopup.AccChildCount: Integer;
begin
  Result := Length(FCells);
end;

function TPPGColorPopup.AccChildName(Id: Integer): string;
begin
  if (Id >= 1) and (Id <= Length(FCells)) then
    Result := FCells[Id - 1].Name
  else
    Result := '';
end;

function TPPGColorPopup.AccChildRole(Id: Integer): Integer;
begin
  if (Id >= 1) and (Id <= Length(FCells)) then
    case FCells[Id - 1].Kind of
      cckHeader: Exit(ROLE_SYSTEM_STATICTEXT);
      cckMore, cckApply: Exit(ROLE_SYSTEM_PUSHBUTTON);
    end;
  Result := ROLE_SYSTEM_CELL;
end;

function TPPGColorPopup.AccChildState(Id: Integer): Integer;
begin
  Result := 0;
  if (Id < 1) or (Id > Length(FCells)) then
    Exit;
  if FCells[Id - 1].Kind <> cckHeader then
    Result := STATE_SYSTEM_FOCUSABLE or STATE_SYSTEM_SELECTABLE;
  if Id - 1 = FFocus then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if (FPicker <> nil) and (FCells[Id - 1].Kind in [cckColor, cckNone, cckDefault]) and
    (FCells[Id - 1].Color = FPicker.Selected) then
    Result := Result or STATE_SYSTEM_SELECTED;
end;

function TPPGColorPopup.AccChildRect(Id: Integer): TRect;
begin
  if (Id >= 1) and (Id <= Length(FCells)) then
    Result := FCells[Id - 1].Rect
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGColorPopup.AccChildAt(X, Y: Integer): Integer;
begin
  Result := CellAt(X, Y) + 1;
end;

function TPPGColorPopup.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccSelect);
end;

procedure TPPGColorPopup.AccChildDoDefault(Id: Integer);
begin
  // Nie im COM-Aufruf auswaehlen: Fokus setzen, Enter des Felds uebernimmt
  if Selectable(Id - 1) then
  begin
    FFocus := Id - 1;
    Invalidate;
    if (FPicker <> nil) and FPicker.HandleAllocated then
    begin
      PostMessage(FPicker.Handle, WM_KEYDOWN, VK_RETURN, 0);
    end;
  end;
end;

function TPPGColorPopup.AccFocusedChild: Integer;
begin
  Result := FFocus + 1;
end;

function TPPGColorPopup.AccSelectedChild: Integer;
begin
  if FPicker = nil then
    Result := 0
  else
    Result := IndexOfColor(FPicker.Selected) + 1;
end;

{ TPPGColorPicker }

constructor TPPGColorPicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSelected := clBlack;
  FStyle := [cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames];
  FShowThemeColors := True;
  FMaxRecent := 8;
  FNoneColorColor := clBlack;
  FDefaultColorColor := clBlack;
  FRecent := TStringList.Create;
  TStringList(FRecent).OnChange := RecentChanged;
  // Wie eine DropDownList: kein freies Edit, das Feld zeigt Farbe und Namen
  SetInnerVisible(False);
end;

destructor TPPGColorPicker.Destroy;
begin
  FreeAndNil(FRecent);
  inherited Destroy;
end;

function TPPGColorPicker.CreatePopup: TPPGDropPopup;
begin
  Result := TPPGColorPopup.Create(Self);
end;

procedure TPPGColorPicker.PreparePopup(APopup: TPPGDropPopup);
begin
  TPPGColorPopup(APopup).Prepare(Self);
end;

procedure TPPGColorPicker.AcceptPopup(APopup: TPPGDropPopup);
var
  P: TPPGColorPopup;
begin
  P := TPPGColorPopup(APopup);
  if P.HasResult then
    SelectColor(P.ResultColor);
end;

procedure TPPGColorPicker.SelectColor(AColor: TColor);
var
  Changed: Boolean;
begin
  Changed := AColor <> FSelected;
  FSelected := AColor;
  if (AColor <> clNone) and (AColor <> clDefault) then
    AddRecentColor(AColor);
  Invalidate;
  if Changed then
    Change;
end;

procedure TPPGColorPicker.SetSelected(const Value: TColor);
begin
  // Aus Code: ohne OnChange
  if FSelected = Value then
    Exit;
  FSelected := Value;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
end;

procedure TPPGColorPicker.SetStyle(const Value: TColorBoxStyle);
begin
  FStyle := Value;
  Invalidate;
end;

procedure TPPGColorPicker.SetRecent(const Value: TStrings);
begin
  FRecent.Assign(Value);
end;

procedure TPPGColorPicker.RecentChanged(Sender: TObject);
begin
  // nichts zu tun: das Popup baut die Liste bei jedem Aufklappen neu
end;

procedure TPPGColorPicker.SetMaxRecent(const Value: Integer);
begin
  FMaxRecent := PPGCheckRange(Self, 'MaxRecent', Value, 0, 32);
  while FRecent.Count > FMaxRecent do
    FRecent.Delete(FRecent.Count - 1);
end;

procedure TPPGColorPicker.SetShowHex(const Value: Boolean);
begin
  FShowHex := Value;
  Invalidate;
end;

procedure TPPGColorPicker.AddRecentColor(AColor: TColor);
var
  Hex: string;
  I: Integer;
begin
  if FMaxRecent = 0 then
    Exit;
  Hex := PPGColorToHex(AColor);
  // Systemfarben bleiben als Name erhalten (sonst friert die Farbe ein)
  if AColor < 0 then
    ColorToIdent(AColor, Hex);
  I := FRecent.IndexOf(Hex);
  if I = 0 then
    Exit;
  if I > 0 then
    FRecent.Delete(I);
  FRecent.Insert(0, Hex);
  while FRecent.Count > FMaxRecent do
    FRecent.Delete(FRecent.Count - 1);
end;

function TPPGColorPicker.RecentCount: Integer;
begin
  Result := FRecent.Count;
end;

function TPPGColorPicker.RecentColor(Index: Integer): TColor;
var
  C: Integer;
begin
  if PPGTryHexToColor(FRecent[Index], Result) then
    Exit;
  if IdentToColor(FRecent[Index], C) then
    Result := C
  else
    Result := clNone;
end;

function TPPGColorPicker.ColorName(AColor: TColor): string;
var
  S: string;
begin
  if AColor = clNone then
    Exit(PPGStr(@SPPGColorNone));
  if AColor = clDefault then
    Exit(PPGStr(@SPPGColorDefault));
  if not FShowHex and ColorToIdent(AColor, S) and (Copy(S, 1, 2) = 'cl') then
  begin
    S := Copy(S, 3, MaxInt);
    if cbPrettyNames in FStyle then
      Exit(S);
    Exit('cl' + S);
  end;
  Result := PPGColorToHex(AColor);
end;

procedure TPPGColorPicker.ClosedKeyDown(var Key: Word; Shift: TShiftState);
begin
  // Geschlossen: Leertaste/Enter? Nein - wie Windows: Pfeile oeffnen nicht,
  // Alt+Pfeil/F4 macht die Basis. Leertaste klappt auf.
  if Key = VK_SPACE then
  begin
    DropDown;
    Key := 0;
  end;
end;

procedure TPPGColorPicker.DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle);
var
  R, SW: TRect;
  PPI, Sz: Integer;
  Frame, Fill: TColor;
begin
  inherited DoPaintField(ACanvas, Style);
  PPI := ScalePPI;
  R := ClientRect;
  InflateRect(R, -PPGScale(8, PPI), -PPGScale(5, PPI));
  SW := ButtonRect(PPGDropButton);
  if not IsRectEmpty(SW) then
    R.Right := SW.Left - PPGScale(4, PPI);
  Sz := R.Bottom - R.Top;
  if Sz > PPGScale(20, PPI) then
  begin
    Inc(R.Top, (Sz - PPGScale(20, PPI)) div 2);
    Sz := PPGScale(20, PPI);
  end;
  SW := Rect(R.Left, R.Top, R.Left + Sz, R.Top + Sz);
  Frame := PPGBlendColor(Style.Color, Style.TextColor, 0.35);
  if FSelected = clNone then
    Fill := Style.Color
  else if FSelected = clDefault then
    Fill := PPGColorToRGB(FDefaultColorColor)
  else
    Fill := PPGColorToRGB(FSelected);
  ACanvas.FillRoundRect(SW, PPGScale(3, PPI), Fill, 255);
  ACanvas.FrameRoundRect(SW, PPGScale(3, PPI), 1, Frame, 255);
  if FSelected = clNone then
    ACanvas.DrawPolyline([Point(SW.Left + 2, SW.Bottom - 3), Point(SW.Right - 3, SW.Top + 2)],
      1, Tokens.Danger, 255);
  R.Left := SW.Right + PPGScale(8, PPI);
  ACanvas.DrawText(Rect(R.Left, ClientRect.Top, R.Right, ClientRect.Bottom),
    ColorName(FSelected), Font, Style.TextColor,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

function TPPGColorPicker.AccValue: string;
begin
  Result := ColorName(FSelected);
end;

function TPPGColorPicker.FieldIsNull: Boolean;
begin
  Result := FSelected = clNone;
end;

procedure TPPGColorPicker.FieldClear;
begin
  SetSelected(clNone);
end;

function TPPGColorPicker.GetFieldValue: Variant;
begin
  if FSelected = clNone then
    Result := Null
  else
    Result := Integer(FSelected);
end;

procedure TPPGColorPicker.SetFieldValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    SetSelected(clNone)
  else
    SetSelected(TColor(Integer(Value)));
end;

end.
