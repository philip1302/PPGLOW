unit PPG.Breadcrumb;

{ TPPGBreadcrumb - Pfadleiste aus Segmenten (Phase 7c, wie WinUI BreadcrumbBar).

  - Items: Segmente von der Wurzel bis zum aktuellen Ort (letztes Segment),
    getrennt durch Chevrons. Das letzte Segment ist hervorgehoben.
  - Passt der Pfad nicht in die Breite, fallen die vorderen Segmente in ein
    "..."-Menue am Anfang (Menue im Stil der Suite, Screenreader-tauglich, Phase 11).
  - Klick bzw. Enter auf ein Segment loest OnItemClick(Index) aus; mit
    TruncateOnClick werden die folgenden Segmente entfernt.
  - Tastatur: Links/Rechts wechseln das Segment, Pos1/Ende, Enter/Leertaste
    loesen aus. RTL gespiegelt.
  - Screenreader: Kinder sind die sichtbaren Segmente (Link) und der
    Ueberlauf-Knopf. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.Menus,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base;

type
  TPPGBreadcrumbClickEvent = procedure(Sender: TObject; Index: Integer) of object;

  TPPGCustomBreadcrumb = class(TPPGCustomControl, IPPGAccessibleChildren)
  private
    FItems: TStringList;
    FFirstVisible: Integer;
    FLayoutValid: Boolean;
    FHotPart: Integer;      // -1 = keins, -2 = Ueberlauf, sonst Segment
    FDownPart: Integer;
    FFocusPart: Integer;
    FTruncateOnClick: Boolean;
    FMenu: TPopupMenu;
    FOnItemClick: TPPGBreadcrumbClickEvent;
    function GetItems: TStrings;
    procedure SetItems(const Value: TStrings);
    procedure ItemsChange(Sender: TObject);
    procedure EnsureLayout;
    function SegmentWidth(Index: Integer): Integer;
    function ChevronWidth: Integer;
    function EllipsisWidth: Integer;
    procedure MenuItemClick(Sender: TObject);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure WndProc(var Message: TMessage); override;
    procedure Resize; override;
    function IsHot: Boolean; override;
    function IsDown: Boolean; override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    function AutoSizeWidth: Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
    /// Segment durch den Anwender ausgeloest.
    procedure DoItemClick(Index: Integer); virtual;
    procedure ActivatePart(Part: Integer);
    function AccRole: Integer; override;
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
    property Items: TStrings read GetItems write SetItems;
    property TruncateOnClick: Boolean read FTruncateOnClick write FTruncateOnClick default False;
    property OnItemClick: TPPGBreadcrumbClickEvent read FOnItemClick write FOnItemClick;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Erstes sichtbares Segment (davor: Ueberlauf-Menue).
    function FirstVisible: Integer;
    /// Rechteck eines Teils (-2 = Ueberlauf, Segment-Index), leer = unsichtbar.
    function PartRect(Part: Integer): TRect;
    function PartAt(X, Y: Integer): Integer;
    /// Ueberlauf-Menue oeffnen (fuer Tastatur und Screenreader).
    procedure ShowOverflowMenu;
    /// Pfad aus einem Text mit Trennzeichen setzen (z.B. 'C:\Daten\Bilder').
    procedure SetPath(const APath: string; Delimiter: Char = '\');
    property HotPart: Integer read FHotPart;
    property FocusPart: Integer read FFocusPart;
    property OverflowMenu: TPopupMenu read FMenu;
  end;

  TPPGBreadcrumb = class(TPPGCustomBreadcrumb)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property Items;
    property TruncateOnClick;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property Touch;
    property OnGesture;
    property OnEnter;
    property OnExit;
    property OnItemClick;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
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
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property Color;
    property ParentColor;
  end;

implementation

uses
  PPG.Lang,
  System.Math, System.UITypes, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.Tokens, PPG.Render.Gdi, PPG.Menus;

const
  SegPad = 8;
  ChevW = 16;

var
  GMsgCrumbAction: Cardinal = 0;

{ TPPGCustomBreadcrumb }

constructor TPPGCustomBreadcrumb.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csSetCaption, csDoubleClicks]; // Audit 5d: OnClick wie TControl
  FItems := TStringList.Create;
  FItems.OnChange := ItemsChange;
  FHotPart := -1;
  FDownPart := -1;
  FFocusPart := -1;
  TabStop := True;
  Width := 300;
  Height := 32;
  AutoSize := True;
  if GMsgCrumbAction = 0 then
    GMsgCrumbAction := RegisterWindowMessage('PPGlow.BreadcrumbAction');
end;

destructor TPPGCustomBreadcrumb.Destroy;
begin
  FreeAndNil(FMenu);
  FreeAndNil(FItems);
  inherited Destroy;
end;

function TPPGCustomBreadcrumb.GetItems: TStrings;
begin
  Result := FItems;
end;

procedure TPPGCustomBreadcrumb.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TPPGCustomBreadcrumb.SetPath(const APath: string; Delimiter: Char);
var
  Parts: TArray<string>;
  I: Integer;
begin
  Parts := PPGSplitString(APath, Delimiter, True);
  FItems.BeginUpdate;
  try
    FItems.Clear;
    for I := 0 to High(Parts) do
      FItems.Add(Parts[I]);
  finally
    FItems.EndUpdate;
  end;
end;

procedure TPPGCustomBreadcrumb.ItemsChange(Sender: TObject);
begin
  FLayoutValid := False;
  if FFocusPart >= FItems.Count then
    FFocusPart := FItems.Count - 1;
  FHotPart := -1;
  RequestAutoSize;
  Invalidate;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
end;

function TPPGCustomBreadcrumb.IsHot: Boolean;
begin
  Result := False;
end;

function TPPGCustomBreadcrumb.IsDown: Boolean;
begin
  Result := False;
end;

function TPPGCustomBreadcrumb.SegmentWidth(Index: Integer): Integer;
begin
  Result := PPGMeasureTextNoCanvas(FItems[Index], Font, 0, False).cx + 2 * PPGScale(SegPad, ScalePPI);
end;

function TPPGCustomBreadcrumb.ChevronWidth: Integer;
begin
  Result := PPGScale(ChevW, ScalePPI);
end;

function TPPGCustomBreadcrumb.EllipsisWidth: Integer;
begin
  Result := PPGMeasureTextNoCanvas('...', Font, 0, False).cx + 2 * PPGScale(SegPad, ScalePPI);
end;

procedure TPPGCustomBreadcrumb.EnsureLayout;
var
  Total, I: Integer;
begin
  if FLayoutValid then
    Exit;
  FLayoutValid := True;
  FFirstVisible := 0;
  if FItems.Count = 0 then
    Exit;
  Total := 0;
  for I := 0 to FItems.Count - 1 do
    Inc(Total, SegmentWidth(I));
  Inc(Total, (FItems.Count - 1) * ChevronWidth);
  // Vorne Segmente ins Menue verschieben, bis es passt (das letzte bleibt)
  while (Total > Width) and (FFirstVisible < FItems.Count - 1) do
  begin
    Dec(Total, SegmentWidth(FFirstVisible) + ChevronWidth);
    if FFirstVisible = 0 then
      Inc(Total, EllipsisWidth + ChevronWidth);
    Inc(FFirstVisible);
  end;
end;

function TPPGCustomBreadcrumb.FirstVisible: Integer;
begin
  EnsureLayout;
  Result := FFirstVisible;
end;

function TPPGCustomBreadcrumb.PartRect(Part: Integer): TRect;
var
  X, I, W: Integer;
begin
  EnsureLayout;
  Result := Rect(0, 0, 0, 0);
  X := 0;
  if FFirstVisible > 0 then
  begin
    W := EllipsisWidth;
    if Part = -2 then
      Result := Rect(X, 0, X + W, Height);
    Inc(X, W + ChevronWidth);
  end;
  if Part >= FFirstVisible then
    for I := FFirstVisible to FItems.Count - 1 do
    begin
      W := SegmentWidth(I);
      if I = Part then
      begin
        Result := Rect(X, 0, Min(X + W, Width), Height);
        Break;
      end;
      Inc(X, W + ChevronWidth);
    end;
  if UseRightToLeftAlignment and not IsRectEmpty(Result) then
    Result := Rect(Width - Result.Right, Result.Top, Width - Result.Left, Result.Bottom);
end;

function TPPGCustomBreadcrumb.PartAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  if (Y < 0) or (Y >= Height) then
    Exit(-1);
  EnsureLayout;
  if (FFirstVisible > 0) and PtInRect(PartRect(-2), Point(X, Y)) then
    Exit(-2);
  for I := FFirstVisible to FItems.Count - 1 do
    if PtInRect(PartRect(I), Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

function TPPGCustomBreadcrumb.AutoSizeWidth: Boolean;
begin
  Result := False; // nur die Hoehe folgt der Schrift
end;

function TPPGCustomBreadcrumb.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
begin
  // Nur die Hoehe folgt der Schrift; die Breite bestimmt der Anwender
  AWidth := Width;
  AHeight := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy + 2 * PPGScale(7, ScalePPI);
  Result := True;
end;

procedure TPPGCustomBreadcrumb.Resize;
begin
  inherited Resize;
  FLayoutValid := False;
end;

procedure TPPGCustomBreadcrumb.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FLayoutValid := False;
  Invalidate;
end;

procedure TPPGCustomBreadcrumb.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  T: TPPGTokens;
  A: TPPGAppearance;
  PPI, I, CX, CY, H: Integer;
  HC, Last: Boolean;
  TextCol, Secondary, Accent, C: TColor;
  R: TRect;
  Bold: TFont;
  Pts: array[0..2] of TPoint;
begin
  EnsureLayout;
  PPI := ScalePPI;
  T := Tokens;
  A := EffectiveAppearance;
  HC := HighContrastSupport and PPGIsHighContrast;
  if HC then
  begin
    TextCol := PPGColorToRGB(clWindowText);
    Secondary := TextCol;
    Accent := PPGColorToRGB(clHighlight);
  end
  else
  begin
    TextCol := T.TextPrimary;
    Secondary := T.TextSecondary;
    Accent := PPGColorToRGB(A.FocusColor);
    if UseVclStyle then
    begin
      TextCol := PPGColorToRGB(A.Normal.TextColor);
      Secondary := PPGBlendColor(TextCol, PPGColorToRGB(GetBackgroundColor), 0.35);
    end;
  end;
  if not Enabled then
  begin
    TextCol := T.TextDisabled;
    Secondary := T.TextDisabled;
  end;
  Bold := TFont.Create;
  try
    Bold.Assign(Font);
    Bold.Style := Bold.Style + [fsBold];
    if FFirstVisible > 0 then
    begin
      R := PartRect(-2);
      if Enabled and (FHotPart = -2) then
        ACanvas.FillRoundRect(R, PPGScale(4, PPI), TextCol, IfThen(FDownPart = -2, 24, 14));
      ACanvas.DrawText(R, '...', Font, Secondary, DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX);
      if FocusVisible and Focused and (FFocusPart = -2) then
        ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI), Accent, 255);
    end;
    for I := FFirstVisible to FItems.Count - 1 do
    begin
      R := PartRect(I);
      Last := I = FItems.Count - 1;
      // Chevron vor dem Segment
      if (I > FFirstVisible) or (FFirstVisible > 0) then
      begin
        CY := (R.Top + R.Bottom) div 2;
        H := PPGScale(4, PPI);
        if UseRightToLeftAlignment then
        begin
          CX := R.Right + ChevronWidth div 2;
          Pts[0] := Point(CX + H div 2, CY - H);
          Pts[1] := Point(CX - H div 2, CY);
          Pts[2] := Point(CX + H div 2, CY + H);
        end
        else
        begin
          CX := R.Left - ChevronWidth div 2;
          Pts[0] := Point(CX - H div 2, CY - H);
          Pts[1] := Point(CX + H div 2, CY);
          Pts[2] := Point(CX - H div 2, CY + H);
        end;
        ACanvas.DrawPolyline(Pts, Max(1, PPGScale(1, PPI)), Secondary, 255);
      end;
      if Enabled and (FHotPart = I) then
        ACanvas.FillRoundRect(R, PPGScale(4, PPI), TextCol, IfThen(FDownPart = I, 24, 14));
      if Last then
        ACanvas.DrawText(R, FItems[I], Bold, TextCol,
          DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS)
      else
      begin
        if FHotPart = I then
          C := TextCol
        else
          C := Secondary;
        ACanvas.DrawText(R, FItems[I], Font, C,
          DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
      end;
      if FocusVisible and Focused and (FFocusPart = I) then
        ACanvas.FrameRoundRect(R, PPGScale(4, PPI), PPGScale(2, PPI), Accent, 255);
    end;
  finally
    Bold.Free;
  end;
end;

procedure TPPGCustomBreadcrumb.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if (Button = mbLeft) and Enabled then
  begin
    FDownPart := PartAt(X, Y);
    Invalidate;
  end;
end;

procedure TPPGCustomBreadcrumb.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  P: Integer;
begin
  inherited MouseMove(Shift, X, Y);
  P := PartAt(X, Y);
  if P <> FHotPart then
  begin
    FHotPart := P;
    Invalidate;
  end;
end;

procedure TPPGCustomBreadcrumb.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  P, D: Integer;
begin
  D := FDownPart;
  FDownPart := -1;
  Invalidate;
  inherited MouseUp(Button, Shift, X, Y);
  if (Button <> mbLeft) or not Enabled then
    Exit;
  P := PartAt(X, Y);
  if (P = D) and (P <> -1) then
    ActivatePart(P);
end;

procedure TPPGCustomBreadcrumb.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotPart <> -1 then
  begin
    FHotPart := -1;
    Invalidate;
  end;
end;

procedure TPPGCustomBreadcrumb.ActivatePart(Part: Integer);
begin
  if Part = -2 then
    ShowOverflowMenu
  else if (Part >= 0) and (Part < FItems.Count) then
    DoItemClick(Part);
end;

procedure TPPGCustomBreadcrumb.DoItemClick(Index: Integer);
var
  OldPath: string;
begin
  OldPath := FItems.Text;
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, Index);
  // Nach dem Ereignis kuerzen (der Anwender sieht noch den alten Pfad).
  // Hat der Handler selbst einen neuen Pfad gesetzt, gilt dieser: Index
  // bezieht sich dann nicht mehr auf die aktuellen Segmente.
  if FTruncateOnClick and (FItems.Text = OldPath) and (Index < FItems.Count - 1) then
  begin
    FItems.BeginUpdate;
    try
      while FItems.Count > Index + 1 do
        FItems.Delete(FItems.Count - 1);
    finally
      FItems.EndUpdate;
    end;
  end;
end;

procedure TPPGCustomBreadcrumb.ShowOverflowMenu;
var
  I: Integer;
  M: TMenuItem;
  R: TRect;
  P: TPoint;
begin
  EnsureLayout;
  if (FFirstVisible = 0) or not HandleAllocated then
    Exit;
  if FMenu = nil then
    FMenu := TPPGPopupMenu.Create(nil);
  FMenu.Items.Clear;
  for I := 0 to FFirstVisible - 1 do
  begin
    M := TMenuItem.Create(FMenu);
    M.Caption := StringReplace(FItems[I], '&', '&&', [rfReplaceAll]);
    M.Tag := I;
    M.OnClick := MenuItemClick;
    FMenu.Items.Add(M);
  end;
  FMenu.BiDiMode := BiDiMode;
  // Menue im Stil der Suite unter dem "..."-Teil (Preset vom Breadcrumb)
  FMenu.PopupComponent := Self;
  R := PartRect(-2);
  P := ClientToScreen(R.TopLeft);
  TPPGPopupMenu(FMenu).PopupAtRect(Rect(P.X, P.Y, P.X + R.Right - R.Left, P.Y + R.Bottom - R.Top));
end;

procedure TPPGCustomBreadcrumb.MenuItemClick(Sender: TObject);
begin
  DoItemClick(TMenuItem(Sender).Tag);
end;

procedure TPPGCustomBreadcrumb.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

procedure TPPGCustomBreadcrumb.KeyDown(var Key: Word; Shift: TShiftState);
var
  K: Word;
  First: Integer;
begin
  inherited KeyDown(Key, Shift);
  if not Enabled or (FItems.Count = 0) then
    Exit;
  EnsureLayout;
  if FFirstVisible > 0 then
    First := -2
  else
    First := 0;
  K := Key;
  if UseRightToLeftAlignment then
    if K = VK_LEFT then
      K := VK_RIGHT
    else if K = VK_RIGHT then
      K := VK_LEFT;
  case K of
    VK_LEFT:
      if FFocusPart = FFirstVisible then
        FFocusPart := First
      else if FFocusPart > FFirstVisible then
        Dec(FFocusPart);
    VK_RIGHT:
      if FFocusPart = -2 then
        FFocusPart := FFirstVisible
      else if FFocusPart < FItems.Count - 1 then
        Inc(FFocusPart);
    VK_HOME: FFocusPart := First;
    VK_END: FFocusPart := FItems.Count - 1;
    VK_RETURN, VK_SPACE:
      begin
        ActivatePart(FFocusPart);
        Key := 0;
        Exit;
      end;
  else
    Exit;
  end;
  Invalidate;
  if FFocusPart = -2 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, 1)
  else
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, FFocusPart - FFirstVisible + 1 + Ord(FFirstVisible > 0));
  Key := 0;
end;

procedure TPPGCustomBreadcrumb.DoEnter;
begin
  inherited DoEnter;
  EnsureLayout;
  if (FFocusPart = -1) or (FFocusPart >= FItems.Count) or
    ((FFocusPart >= 0) and (FFocusPart < FFirstVisible)) then
    FFocusPart := FItems.Count - 1;
  Invalidate;
end;

procedure TPPGCustomBreadcrumb.DoExit;
begin
  inherited DoExit;
  Invalidate;
end;

{ ---- Barrierefreiheit: Kind 1 = Ueberlauf (falls da), dann die Segmente ---- }

function IdToPart(B: TPPGCustomBreadcrumb; Id: Integer): Integer;
begin
  if B.FirstVisible > 0 then
  begin
    if Id = 1 then
      Exit(-2);
    Result := B.FirstVisible + Id - 2;
  end
  else
    Result := Id - 1;
end;

function PartToId(B: TPPGCustomBreadcrumb; Part: Integer): Integer;
begin
  if Part = -1 then
    Exit(0);
  if B.FirstVisible > 0 then
  begin
    if Part = -2 then
      Exit(1);
    Result := Part - B.FirstVisible + 2;
  end
  else
    Result := Part + 1;
end;

procedure TPPGCustomBreadcrumb.WndProc(var Message: TMessage);
begin
  if (GMsgCrumbAction <> 0) and (Message.Msg = GMsgCrumbAction) then
  begin
    ActivatePart(IdToPart(Self, Integer(Message.WParam)));
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGCustomBreadcrumb.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TOOLBAR;
end;

function TPPGCustomBreadcrumb.AccChildCount: Integer;
begin
  EnsureLayout;
  Result := FItems.Count - FFirstVisible + Ord(FFirstVisible > 0);
end;

function TPPGCustomBreadcrumb.AccChildName(Id: Integer): string;
var
  P: Integer;
begin
  P := IdToPart(Self, Id);
  if P = -2 then
    Result := PPGStr(@SPPGMoreOptions)
  else if (P >= 0) and (P < FItems.Count) then
    Result := FItems[P]
  else
    Result := '';
end;

function TPPGCustomBreadcrumb.AccChildRole(Id: Integer): Integer;
begin
  if IdToPart(Self, Id) = -2 then
    Result := ROLE_SYSTEM_BUTTONMENU
  else
    Result := ROLE_SYSTEM_LINK;
end;

function TPPGCustomBreadcrumb.AccChildState(Id: Integer): Integer;
var
  P: Integer;
begin
  Result := STATE_SYSTEM_FOCUSABLE;
  P := IdToPart(Self, Id);
  if Focused and (P = FFocusPart) then
    Result := Result or STATE_SYSTEM_FOCUSED;
  if P = FItems.Count - 1 then
    Result := Result or STATE_SYSTEM_SELECTED; // aktueller Ort
  if not Enabled then
    Result := STATE_SYSTEM_UNAVAILABLE;
end;

function TPPGCustomBreadcrumb.AccChildRect(Id: Integer): TRect;
begin
  Result := PartRect(IdToPart(Self, Id));
end;

function TPPGCustomBreadcrumb.AccChildAt(X, Y: Integer): Integer;
begin
  Result := PartToId(Self, PartAt(X, Y));
end;

function TPPGCustomBreadcrumb.AccChildDefaultAction(Id: Integer): string;
begin
  if IdToPart(Self, Id) = -2 then
    Result := PPGStr(@SPPGAccOpen)
  else
    Result := PPGStr(@SPPGAccJump);
end;

procedure TPPGCustomBreadcrumb.AccChildDoDefault(Id: Integer);
begin
  if HandleAllocated then
    PostMessage(Handle, GMsgCrumbAction, WPARAM(Id), 0);
end;

function TPPGCustomBreadcrumb.AccFocusedChild: Integer;
begin
  if Focused then
    Result := PartToId(Self, FFocusPart)
  else
    Result := 0;
end;

function TPPGCustomBreadcrumb.AccSelectedChild: Integer;
begin
  if FItems.Count = 0 then
    Result := 0
  else
    Result := PartToId(Self, FItems.Count - 1);
end;

end.
