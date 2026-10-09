unit PPG.RowPopup;

{ TPPGRowPopup - Zeilenliste im Aufklapp-Fenster (Phase 12e), gemeinsame
  Basis fuer CheckComboBox (Kaestchen) und ColumnComboBox (Spalten, Kopf).

  - Zeilen gleicher Hoehe, Bildlauf mit Mausrad, Tasten und Bildlaufleiste
    (Daumen ziehen, Klick in die Spur blaettert).
  - Optional Kopfzeile (HeaderHeight > 0, z.B. Spaltentitel, Klick sortiert)
    und Filterzeile (FilterEnabled: getippte Zeichen filtern, Ruecktaste
    loescht). Was der Filter bedeutet, entscheidet die Ableitung
    (FilterChanged).
  - Tastatur: Pfeile, Bild auf/ab, Pos1/Ende bewegen den Fokus; Leertaste
    und Enter rufen RowActivate. Ob das Popup offen bleibt (Kaestchen) oder
    uebernimmt (Auswahl), meldet RowActivate. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.Popup;

type
  TPPGRowPopup = class(TPPGDropPopup)
  private
    FTop: Integer;
    FHot: Integer;
    FFocus: Integer;
    FMaxRows: Integer;
    FHeaderHeight: Integer;
    FFilterEnabled: Boolean;
    FFilter: string;
    FThumbDrag: Boolean;
    FDragOffset: Integer;
    FPressedRow: Integer;
    function GetRowHeight: Integer;
    function ListTop: Integer;
    function VisibleRows: Integer;
    function TrackRect: TRect;
    function ThumbRect: TRect;
    function NeedScroll: Boolean;
    procedure SetTop(Value: Integer);
  protected
    function RowCount: Integer; virtual; abstract;
    procedure PaintRow(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Hot, Focused: Boolean); virtual; abstract;
    procedure PaintHeader(const ACanvas: IPPGCanvas; const R: TRect;
      const ListStyle: TPPGSurfaceStyle); virtual;
    /// Zeile ausgeloest (Klick bei X bzw. Taste); Aktion fuer das Feld.
    function RowActivate(Index: Integer; ByMouse: Boolean; X: Integer): TPPGDropAction;
      virtual; abstract;
    procedure HeaderClick(X: Integer); virtual;
    /// Filtertext hat sich geaendert: Zeilen neu bestimmen.
    procedure FilterChanged; virtual;
    /// Zeichen ohne Filter (z.B. Tippsuche). True = verbraucht.
    function TypeAhead(Key: Char): Boolean; virtual;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function Pad: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    function PreferredSize(FieldWidth: Integer): TSize; override;
    procedure DropMouseMove(X, Y: Integer; Shift: TShiftState); override;
    function DropMouseDown(X, Y: Integer): TPPGDropAction; override;
    function DropMouseUp(X, Y: Integer): TPPGDropAction; override;
    function DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction; override;
    function DropKeyPress(var Key: Char): TPPGDropAction; override;
    procedure DropWheel(Delta: Integer); override;
    procedure DropMouseLeave; override;
    function RowRect(Index: Integer): TRect;
    function RowAt(X, Y: Integer): Integer;
    procedure SetFocusRow(Index: Integer);
    procedure EnsureVisible(Index: Integer);
    /// Fokus und Bildlauf zuruecksetzen (vor dem Zeigen).
    procedure ResetView(FocusRow: Integer);
    procedure SetFilter(const Value: string);
    property RowHeight: Integer read GetRowHeight;
    property MaxRows: Integer read FMaxRows write FMaxRows;
    property HeaderHeight: Integer read FHeaderHeight write FHeaderHeight;
    property FilterEnabled: Boolean read FFilterEnabled write FFilterEnabled;
    property Filter: string read FFilter;
    property FocusRow: Integer read FFocus;
    property HotRow: Integer read FHot;
    property TopRow: Integer read FTop;
  end;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Appearance, PPG.Render.Registry, PPG.Controls.Base;

function IfThenSingle(B: Boolean; T, F: Single): Single;
begin
  if B then
    Result := T
  else
    Result := F;
end;

{ TPPGRowPopup }

constructor TPPGRowPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMaxRows := 8;
  FHot := -1;
  FFocus := -1;
  FPressedRow := -1;
end;

function TPPGRowPopup.Pad: Integer;
begin
  Result := PPGScale(4, ScalePPI);
end;

function TPPGRowPopup.GetRowHeight: Integer;
var
  TM: TTextMetric;
  DC: HDC;
  Old: HGDIOBJ;
begin
  // Schrifthoehe + Abstand, mindestens 32 logische px (Fluent-Liste)
  DC := GetDC(0);
  try
    Old := SelectObject(DC, Font.Handle);
    GetTextMetrics(DC, TM);
    SelectObject(DC, Old);
  finally
    ReleaseDC(0, DC);
  end;
  Result := Max(TM.tmHeight + PPGScale(12, ScalePPI), PPGScale(30, ScalePPI));
end;

function TPPGRowPopup.ListTop: Integer;
begin
  Result := Pad + FHeaderHeight;
  if FFilterEnabled then
    Inc(Result, RowHeight);
end;

function TPPGRowPopup.VisibleRows: Integer;
begin
  // Vor dem ersten Zeigen hat das Fenster noch nicht seine Hoehe: dann aus
  // MaxRows (sonst scrollt EnsureVisible zu weit)
  if HandleAllocated and IsOpen and (ClientHeight > ListTop) then
    Result := Max(1, (ClientHeight - ListTop - Pad) div RowHeight)
  else
    Result := Max(1, Min(RowCount, FMaxRows));
end;

function TPPGRowPopup.NeedScroll: Boolean;
begin
  Result := RowCount > VisibleRows;
end;

function TPPGRowPopup.PreferredSize(FieldWidth: Integer): TSize;
var
  N: Integer;
begin
  N := Max(1, Min(RowCount, FMaxRows));
  if FFilterEnabled then
    N := Max(N, Min(FMaxRows, 3)); // Platz, auch wenn der Filter viel wegnimmt
  Result.cx := FieldWidth;
  Result.cy := ListTop + N * RowHeight + Pad;
end;

function TPPGRowPopup.TrackRect: TRect;
begin
  Result := Rect(ClientWidth - Pad - PPGScale(6, ScalePPI), ListTop, ClientWidth - Pad,
    ClientHeight - Pad);
end;

function TPPGRowPopup.ThumbRect: TRect;
var
  T: TRect;
  H, Range: Integer;
begin
  T := TrackRect;
  if not NeedScroll then
    Exit(Rect(0, 0, 0, 0));
  H := Max(PPGScale(20, ScalePPI), (T.Bottom - T.Top) * VisibleRows div RowCount);
  Range := RowCount - VisibleRows;
  Result := T;
  Result.Top := T.Top + MulDiv(T.Bottom - T.Top - H, FTop, Max(Range, 1));
  Result.Bottom := Result.Top + H;
end;

procedure TPPGRowPopup.SetTop(Value: Integer);
begin
  Value := EnsureRange(Value, 0, Max(0, RowCount - VisibleRows));
  if Value <> FTop then
  begin
    FTop := Value;
    Invalidate;
  end;
end;

function TPPGRowPopup.RowRect(Index: Integer): TRect;
var
  Right: Integer;
begin
  Right := ClientWidth - Pad;
  if NeedScroll then
    Dec(Right, PPGScale(10, ScalePPI));
  Result := Rect(Pad, ListTop + (Index - FTop) * RowHeight, Right,
    ListTop + (Index - FTop + 1) * RowHeight);
end;

function TPPGRowPopup.RowAt(X, Y: Integer): Integer;
begin
  Result := -1;
  if (Y < ListTop) or (Y >= ClientHeight - Pad) or (X < 0) or (X >= ClientWidth) then
    Exit;
  if NeedScroll and (X >= TrackRect.Left - PPGScale(2, ScalePPI)) then
    Exit;
  Result := FTop + (Y - ListTop) div RowHeight;
  if Result >= RowCount then
    Result := -1;
end;

procedure TPPGRowPopup.EnsureVisible(Index: Integer);
begin
  if Index < 0 then
    Exit;
  if Index < FTop then
    SetTop(Index)
  else if Index >= FTop + VisibleRows then
    SetTop(Index - VisibleRows + 1);
end;

procedure TPPGRowPopup.SetFocusRow(Index: Integer);
begin
  if RowCount = 0 then
    Index := -1
  else
    Index := EnsureRange(Index, 0, RowCount - 1);
  if Index <> FFocus then
  begin
    FFocus := Index;
    Invalidate;
    if Index >= 0 then
      NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Index + 1);
  end;
  EnsureVisible(Index);
end;

procedure TPPGRowPopup.ResetView(FocusRow: Integer);
begin
  FFilter := '';
  FHot := -1;
  FTop := 0;
  FFocus := -1;
  FThumbDrag := False;
  if (FocusRow >= 0) and (FocusRow < RowCount) then
    FFocus := FocusRow;
end;

procedure TPPGRowPopup.SetFilter(const Value: string);
begin
  if FFilter = Value then
    Exit;
  FFilter := Value;
  FilterChanged;
  FTop := 0;
  if RowCount > 0 then
    FFocus := 0
  else
    FFocus := -1;
  Invalidate;
end;

procedure TPPGRowPopup.FilterChanged;
begin
end;

function TPPGRowPopup.TypeAhead(Key: Char): Boolean;
begin
  Result := False;
end;

procedure TPPGRowPopup.PaintHeader(const ACanvas: IPPGCanvas; const R: TRect;
  const ListStyle: TPPGSurfaceStyle);
begin
end;

procedure TPPGRowPopup.HeaderClick(X: Integer);
begin
end;

procedure TPPGRowPopup.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  L, H: TPPGSurfaceStyle;
  LR: IPPGListRenderer;
  I, Last: Integer;
  R: TRect;
  Text: string;
begin
  T := Tokens;
  GetPopupStyles(T.Layer, T.TextPrimary, L, H);
  if not Supports(Renderer, IPPGListRenderer, LR) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName), IPPGListRenderer, LR);
  LR.DrawPopupFrame(ACanvas, Rect(0, -ContentOffset, ClientWidth, FullHeight - ContentOffset),
    L, ScalePPI);
  if FHeaderHeight > 0 then
    PaintHeader(ACanvas, Rect(Pad, Pad, ClientWidth - Pad, Pad + FHeaderHeight), L);
  if FFilterEnabled then
  begin
    // Filterzeile: getippter Text mit Lupe-Zeichen, sonst Hinweis
    R := Rect(Pad + PPGScale(8, ScalePPI), Pad + FHeaderHeight, ClientWidth - Pad,
      Pad + FHeaderHeight + RowHeight);
    if FFilter = '' then
      Text := #$2315 + ' ...'
    else
      Text := #$2315 + ' ' + FFilter + '|';
    ACanvas.DrawText(R, Text, Font, PPGBlendColor(L.TextColor, L.Color, IfThenSingle(FFilter = '', 0.45, 0)),
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
    ACanvas.FillRoundRect(Rect(Pad, R.Bottom - 1, ClientWidth - Pad, R.Bottom), 0,
      PPGBlendColor(L.Color, L.TextColor, 0.15), 255);
  end;
  ACanvas.PushClipRoundRect(Rect(0, ListTop, ClientWidth, ClientHeight - Pad), 0);
  try
    Last := Min(RowCount - 1, FTop + VisibleRows);
    for I := FTop to Last do
    begin
      R := RowRect(I);
      LR.DrawListItem(ACanvas, R, L, H, False, IfThenSingle(I = FHot, 1, 0), ScalePPI);
      PaintRow(ACanvas, I, R, L, H, I = FHot, I = FFocus);
      if I = FFocus then
        ACanvas.FrameRoundRect(Rect(R.Left + 1, R.Top + 1, R.Right - 1, R.Bottom - 1),
          PPGScale(4, ScalePPI), PPGScale(2, ScalePPI),
          PPGColorToRGB(EffectiveAppearance.FocusColor), 255);
    end;
  finally
    ACanvas.PopClip;
  end;
  if NeedScroll then
    LR.DrawScrollThumb(ACanvas, TrackRect, ThumbRect, L, FThumbDrag, ScalePPI);
end;

procedure TPPGRowPopup.DropMouseMove(X, Y: Integer; Shift: TShiftState);
var
  I: Integer;
  T: TRect;
begin
  if FThumbDrag then
  begin
    T := TrackRect;
    I := MulDiv(Y - FDragOffset - T.Top, Max(RowCount - VisibleRows, 1),
      Max(T.Bottom - T.Top - (ThumbRect.Bottom - ThumbRect.Top), 1));
    SetTop(I);
    Exit;
  end;
  I := RowAt(X, Y);
  if I <> FHot then
  begin
    FHot := I;
    Invalidate;
  end;
end;

procedure TPPGRowPopup.DropMouseLeave;
begin
  if FHot >= 0 then
  begin
    FHot := -1;
    Invalidate;
  end;
end;

function TPPGRowPopup.DropMouseDown(X, Y: Integer): TPPGDropAction;
var
  Th: TRect;
begin
  Result := pdaNone;
  FPressedRow := -1;
  if (FHeaderHeight > 0) and (Y >= Pad) and (Y < Pad + FHeaderHeight) then
  begin
    HeaderClick(X);
    Invalidate;
    Exit(pdaKeepOpen);
  end;
  if NeedScroll and (X >= TrackRect.Left - PPGScale(2, ScalePPI)) and (Y >= ListTop) then
  begin
    Th := ThumbRect;
    if (Y >= Th.Top) and (Y < Th.Bottom) then
    begin
      FThumbDrag := True;
      FDragOffset := Y - Th.Top;
    end
    else if Y < Th.Top then
      SetTop(FTop - VisibleRows)
    else
      SetTop(FTop + VisibleRows);
    Invalidate;
    Exit(pdaKeepOpen);
  end;
  FPressedRow := RowAt(X, Y);
end;

function TPPGRowPopup.DropMouseUp(X, Y: Integer): TPPGDropAction;
var
  I: Integer;
begin
  Result := pdaNone;
  if FThumbDrag then
  begin
    FThumbDrag := False;
    Invalidate;
    Exit(pdaKeepOpen);
  end;
  I := RowAt(X, Y);
  if (I >= 0) and (I = FPressedRow) then
  begin
    FFocus := I;
    Invalidate;
    Result := RowActivate(I, True, X);
  end;
  FPressedRow := -1;
end;

function TPPGRowPopup.DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction;
begin
  Result := pdaNone;
  case Key of
    VK_UP: SetFocusRow(Max(FFocus - 1, 0));
    VK_DOWN: SetFocusRow(FFocus + 1);
    VK_PRIOR: SetFocusRow(Max(FFocus - (VisibleRows - 1), 0));
    VK_NEXT: SetFocusRow(FFocus + VisibleRows - 1);
    VK_HOME: SetFocusRow(0);
    VK_END: SetFocusRow(RowCount - 1);
    VK_RETURN, VK_SPACE:
      if FFocus >= 0 then
        Result := RowActivate(FFocus, False, 0)
      else if Key = VK_RETURN then
        Result := pdaAccept;
    VK_BACK:
      if FFilterEnabled and (FFilter <> '') then
        SetFilter(Copy(FFilter, 1, Length(FFilter) - 1))
      else
        Exit;
  else
    Exit;
  end;
  Key := 0;
end;

function TPPGRowPopup.DropKeyPress(var Key: Char): TPPGDropAction;
begin
  Result := pdaNone;
  // Leertaste kommt als Taste (Kaestchen), nie als Filterzeichen
  if (Key < #32) or (Key = ' ') then
    Exit;
  if FFilterEnabled then
    SetFilter(FFilter + Key)
  else
    TypeAhead(Key);
end;

procedure TPPGRowPopup.DropWheel(Delta: Integer);
var
  Lines: Integer;
begin
  // Audit 7b: Zeilen aus der Systemeinstellung, Teil-Deltas gesammelt
  Lines := PPGWheelScrollLines;
  if Lines < 0 then
    Lines := VisibleRows - 1; // seitenweise
  if Lines < 1 then
    Lines := 1;
  SetTop(FTop - WheelSteps(Delta, Lines));
end;

end.
