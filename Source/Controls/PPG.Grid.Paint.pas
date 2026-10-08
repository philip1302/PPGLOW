unit PPG.Grid.Paint;

{ Zeichnen von Grid-Zellen (Phase 13a), unabhaengig vom Control.

  - TPPGCellPainter sammelt Texte und gibt sie in EINEM GDI-Block aus
    (Schrift einmal waehlen, Farbe nur bei Wechsel). Die Arrays werden ueber
    Zeichenvorgaenge hinweg wiederverwendet (keine Allokation je Paint).
  - Zellarten (Kaestchen, Sortierpfeil) ueber IPPGGridCellRenderer (ISP):
    ein Preset-Renderer kann es selbst umsetzen; sonst nimmt der Painter
    Indikator- und Listen-Renderer des Presets (bzw. des Standard-Presets).
  - Grid, Drucker (13e) und Vorschau nutzen denselben Painter. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.Types, Vcl.Graphics,
  PPG.Types, PPG.Render.Intf;

type
  IPPGGridCellRenderer = interface
    ['{4B8E0D27-91A6-4C3F-B5D2-6E07A3F918C4}']
    /// Kaestchen einer gekCheck-Zelle (Style: aufgeloester Preset-Stil).
    procedure DrawGridCheck(const ACanvas: IPPGCanvas; const R: TRect; Checked: Boolean;
      const Style: TPPGSurfaceStyle; PPI: Integer);
    /// Sortierpfeil im Spaltenkopf.
    procedure DrawGridSortArrow(const ACanvas: IPPGCanvas; const R: TRect;
      Ascending: Boolean; Color: TColor; PPI: Integer);
    /// Auf-/Zuklapp-Pfeil einer Gruppenzeile.
    procedure DrawGridExpander(const ACanvas: IPPGCanvas; const R: TRect; Color: TColor;
      Expanded, RightToLeft: Boolean; PPI: Integer);
  end;

  TPPGCellPainter = class
  private
    FTexts: array of string;
    FRects: array of TRect;
    FColors: array of TColor;
    FFlags: array of Cardinal;
    FBold: array of Boolean;
    FFonts: array of HFONT;
    FCount: Integer;
    FCells: IPPGGridCellRenderer;
  public
    /// Zellarten-Renderer fuer diesen Zeichenvorgang bestimmen (Preset-Renderer
    /// oder direkt ein IPPGGridCellRenderer).
    procedure Prepare(const Renderer: IInterface);
    /// Text vormerken (R = Textrechteck, Flags = DrawText-Flags).
    procedure AddText(const R: TRect; const S: string; Color: TColor; Flags: Cardinal;
      Bold: Boolean = False);
    /// Text mit eigener Schrift (Element-Stil, Spalte); 0 = Standard-Schrift.
    procedure AddTextFont(const R: TRect; const S: string; Color: TColor; Flags: Cardinal;
      AFont: HFONT);
    /// Vorgemerkte Texte ausgeben (Schrift und Farbe bleiben im DC gesetzt).
    /// BoldFont fuer fett markierte Texte (0 = normale Schrift).
    procedure FlushTexts(DC: HDC; Font: HFONT; BoldFont: HFONT = 0);
    procedure DrawCheck(const ACanvas: IPPGCanvas; const CellR: TRect; Checked: Boolean;
      const Style: TPPGSurfaceStyle; PPI: Integer);
    procedure DrawSortArrow(const ACanvas: IPPGCanvas; const CellR: TRect;
      Ascending, RightToLeft: Boolean; Color: TColor; PPI: Integer);
    procedure DrawExpander(const ACanvas: IPPGCanvas; const R: TRect; Color: TColor;
      Expanded, RightToLeft: Boolean; PPI: Integer);
    /// Text einer Kaestchen-Zelle als Zustand ('1', 'True', 'Ja').
    class function IsCheckedText(const S: string): Boolean; static;
    /// DrawText-Flags fuer eine Ausrichtung (einzeilig, Ellipse).
    class function TextFlags(Alignment: TAlignment): Cardinal; static;
    /// Deckend fuellen (GDI).
    class procedure FillGdi(DC: HDC; const R: TRect; Color: TColor); static;
    /// Breite des Sortierpfeils (logische px), um die der Kopftext kuerzer wird.
    class function SortArrowSpace: Integer; static;
    property Cells: IPPGGridCellRenderer read FCells;
  end;

implementation

uses
  System.SysUtils, Vcl.StdCtrls, PPG.Appearance, PPG.Render.Registry;

type
  /// Standard: Kaestchen und Pfeil aus den vorhandenen Preset-Renderern.
  TPPGPresetGridCellRenderer = class(TInterfacedObject, IPPGGridCellRenderer)
  private
    FInd: IPPGIndicatorRenderer;
    FList: IPPGListRenderer;
    FItem: IPPGItemRenderer;
  public
    constructor Create(const Renderer: IInterface);
    procedure DrawGridCheck(const ACanvas: IPPGCanvas; const R: TRect; Checked: Boolean;
      const Style: TPPGSurfaceStyle; PPI: Integer);
    procedure DrawGridSortArrow(const ACanvas: IPPGCanvas; const R: TRect;
      Ascending: Boolean; Color: TColor; PPI: Integer);
    procedure DrawGridExpander(const ACanvas: IPPGCanvas; const R: TRect; Color: TColor;
      Expanded, RightToLeft: Boolean; PPI: Integer);
  end;

{ TPPGPresetGridCellRenderer }

constructor TPPGPresetGridCellRenderer.Create(const Renderer: IInterface);
begin
  inherited Create;
  if not Supports(Renderer, IPPGIndicatorRenderer, FInd) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGIndicatorRenderer, FInd);
  if not Supports(Renderer, IPPGListRenderer, FList) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGListRenderer, FList);
  if not Supports(Renderer, IPPGItemRenderer, FItem) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGItemRenderer, FItem);
end;

procedure TPPGPresetGridCellRenderer.DrawGridCheck(const ACanvas: IPPGCanvas; const R: TRect;
  Checked: Boolean; const Style: TPPGSurfaceStyle; PPI: Integer);
begin
  if FInd = nil then
    Exit;
  if Checked then
    FInd.DrawCheckIndicator(ACanvas, R, Style, cbChecked, PPI)
  else
    FInd.DrawCheckIndicator(ACanvas, R, Style, cbUnchecked, PPI);
end;

procedure TPPGPresetGridCellRenderer.DrawGridSortArrow(const ACanvas: IPPGCanvas;
  const R: TRect; Ascending: Boolean; Color: TColor; PPI: Integer);
begin
  if FList <> nil then
    FList.DrawDropArrow(ACanvas, R, Color, Ord(Ascending), PPI);
end;

procedure TPPGPresetGridCellRenderer.DrawGridExpander(const ACanvas: IPPGCanvas;
  const R: TRect; Color: TColor; Expanded, RightToLeft: Boolean; PPI: Integer);
begin
  if FItem <> nil then
    FItem.DrawExpander(ACanvas, R, Color, Ord(Expanded), RightToLeft, PPI);
end;

{ TPPGCellPainter }

procedure TPPGCellPainter.Prepare(const Renderer: IInterface);
begin
  FCount := 0;
  if not Supports(Renderer, IPPGGridCellRenderer, FCells) then
    FCells := TPPGPresetGridCellRenderer.Create(Renderer);
end;

procedure TPPGCellPainter.AddText(const R: TRect; const S: string; Color: TColor;
  Flags: Cardinal; Bold: Boolean);
begin
  AddTextFont(R, S, Color, Flags, 0);
  FBold[FCount - 1] := Bold;
end;

procedure TPPGCellPainter.AddTextFont(const R: TRect; const S: string; Color: TColor;
  Flags: Cardinal; AFont: HFONT);
var
  N: Integer;
begin
  if FCount >= Length(FTexts) then
  begin
    N := Length(FTexts) * 2;
    if N < 64 then
      N := 64;
    SetLength(FTexts, N);
    SetLength(FRects, N);
    SetLength(FColors, N);
    SetLength(FFlags, N);
    SetLength(FBold, N);
    SetLength(FFonts, N);
  end;
  FTexts[FCount] := S;
  FRects[FCount] := R;
  FColors[FCount] := Color;
  FFlags[FCount] := Flags;
  FBold[FCount] := False;
  FFonts[FCount] := AFont;
  Inc(FCount);
end;

procedure TPPGCellPainter.FlushTexts(DC: HDC; Font: HFONT; BoldFont: HFONT);
var
  I: Integer;
  LastColor: TColor;
  TR: TRect;
  Want, Current: HFONT;
begin
  if FCount = 0 then
    Exit;
  SelectObject(DC, Font);
  Current := Font;
  SetBkMode(DC, TRANSPARENT);
  LastColor := clNone;
  for I := 0 to FCount - 1 do
  begin
    if FColors[I] <> LastColor then
    begin
      SetTextColor(DC, ColorToRGB(FColors[I]));
      LastColor := FColors[I];
    end;
    // Schrift nur bei Wechsel waehlen (eigene Schrift > fett > Standard)
    if FFonts[I] <> 0 then
      Want := FFonts[I]
    else if FBold[I] and (BoldFont <> 0) then
      Want := BoldFont
    else
      Want := Font;
    if Want <> Current then
    begin
      SelectObject(DC, Want);
      Current := Want;
    end;
    TR := FRects[I];
    Winapi.Windows.DrawText(DC, PChar(FTexts[I]), Length(FTexts[I]), TR, FFlags[I]);
    FTexts[I] := ''; // Strings nicht bis zum naechsten Paint festhalten
  end;
  FCount := 0;
end;

procedure TPPGCellPainter.DrawCheck(const ACanvas: IPPGCanvas; const CellR: TRect;
  Checked: Boolean; const Style: TPPGSurfaceStyle; PPI: Integer);
var
  R: TRect;
  Sz: Integer;
begin
  if FCells = nil then
    Exit;
  Sz := PPGScale(16, PPI);
  R.Left := (CellR.Left + CellR.Right - Sz) div 2;
  R.Top := (CellR.Top + CellR.Bottom - Sz) div 2;
  R.Right := R.Left + Sz;
  R.Bottom := R.Top + Sz;
  FCells.DrawGridCheck(ACanvas, R, Checked, Style, PPI);
end;

procedure TPPGCellPainter.DrawSortArrow(const ACanvas: IPPGCanvas; const CellR: TRect;
  Ascending, RightToLeft: Boolean; Color: TColor; PPI: Integer);
var
  R: TRect;
begin
  if FCells = nil then
    Exit;
  R := CellR;
  if RightToLeft then
    R.Right := R.Left + PPGScale(18, PPI)
  else
    R.Left := R.Right - PPGScale(18, PPI);
  FCells.DrawGridSortArrow(ACanvas, R, Ascending, Color, PPI);
end;

procedure TPPGCellPainter.DrawExpander(const ACanvas: IPPGCanvas; const R: TRect;
  Color: TColor; Expanded, RightToLeft: Boolean; PPI: Integer);
begin
  if FCells <> nil then
    FCells.DrawGridExpander(ACanvas, R, Color, Expanded, RightToLeft, PPI);
end;

class function TPPGCellPainter.IsCheckedText(const S: string): Boolean;
begin
  Result := (S = '1') or SameText(S, 'True') or SameText(S, 'Ja');
end;

class function TPPGCellPainter.TextFlags(Alignment: TAlignment): Cardinal;
begin
  Result := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
  case Alignment of
    taRightJustify: Result := Result or DT_RIGHT;
    taCenter: Result := Result or DT_CENTER;
  end;
end;

class procedure TPPGCellPainter.FillGdi(DC: HDC; const R: TRect; Color: TColor);
var
  B: HBRUSH;
begin
  if IsRectEmpty(R) then
    Exit;
  B := CreateSolidBrush(ColorToRGB(Color));
  if B = 0 then
    Exit;
  try
    Winapi.Windows.FillRect(DC, R, B);
  finally
    DeleteObject(B);
  end;
end;

class function TPPGCellPainter.SortArrowSpace: Integer;
begin
  Result := 14;
end;

end.
