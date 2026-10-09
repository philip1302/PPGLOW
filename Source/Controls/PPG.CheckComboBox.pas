unit PPG.CheckComboBox;

{ TPPGCheckComboBox - Mehrfachauswahl im Aufklappfeld (Phase 12e,
  Vorbild TMS TCheckListEdit).

  - Popup-Liste mit Kaestchen (Indikator-Renderer wie CheckListBox, keine
    neue Zeichenlogik). Das Popup bleibt beim Anhaken offen; Enter oder ein
    Klick daneben schliesst. Haken wirken sofort (OnItemCheck, OnChange).
  - Anzeige im Feld: "A, B, +2" (DisplayMode cdmCompact), alle Namen
    (cdmList) oder "3 ausgewaehlt" (cdmCount). Ohne Auswahl: TextHint.
  - Optional "Alle auswaehlen" als erste Zeile (ShowSelectAll) und eine
    Filterzeile ab FilterThreshold Eintraegen (getippte Zeichen filtern).
  - CheckedText: gewaehlte Eintraege getrennt durch Delimiter; damit
    gespeichert (DFM) und an DB-Felder gebunden (IPPGFieldValue).
  - Code (Checked[], CheckAll, CheckedText) loest keine Ereignisse aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base, PPG.Controls.Field,
  PPG.Controls.DropDown, PPG.Popup, PPG.RowPopup;

type
  TPPGCheckComboDisplay = (cdmCompact, cdmList, cdmCount);
  TPPGCheckItemEvent = procedure(Sender: TObject; Index: Integer) of object;

  TPPGCheckComboBox = class;

  TPPGCheckListPopup = class(TPPGRowPopup, IPPGAccessibleChildren)
  private
    FCombo: TPPGCheckComboBox;
    FMap: TArray<Integer>;   // Zeile -> Eintrag; -1 = "Alle auswaehlen"
    procedure BuildMap;
    /// Eintraege haben sich bei offener Liste geaendert.
    procedure ItemsChanged;
  protected
    function RowCount: Integer; override;
    procedure PaintRow(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Hot, Focused: Boolean); override;
    function RowActivate(Index: Integer; ByMouse: Boolean; X: Integer): TPPGDropAction; override;
    procedure FilterChanged; override;
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
    procedure Prepare(ACombo: TPPGCheckComboBox);
    function DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction; override;
    /// Eintrag einer Zeile (-1 = "Alle auswaehlen").
    function ItemOfRow(Row: Integer): Integer;
  end;

  TPPGCheckComboBox = class(TPPGCustomDropDownField, IPPGFieldValue)
  private
    FItems: TStrings;
    FChecked: TArray<Boolean>;
    // Stand vor einer Aenderung der Eintraege (OnChanging), damit die Haken
    // nach Insert/Delete/Sort beim selben Eintrag bleiben
    FSnapTexts: TArray<string>;
    FSnapChecked: TArray<Boolean>;
    FSnapValid: Boolean;
    FDelimiter: Char;
    FDisplayDelimiter: string;
    FDisplayMode: TPPGCheckComboDisplay;
    FMaxDisplayItems: Integer;
    FShowSelectAll: Boolean;
    FFilterThreshold: Integer;
    FDropDownCount: Integer;
    FPendingText: string;
    FOnItemCheck: TPPGCheckItemEvent;
    procedure SetItems(const Value: TStrings);
    procedure ItemsChanging(Sender: TObject);
    procedure ItemsChanged(Sender: TObject);
    function GetChecked(Index: Integer): Boolean;
    procedure SetChecked(Index: Integer; const Value: Boolean);
    function GetCheckedText: string;
    procedure SetCheckedText(const Value: string);
    procedure SetDisplayMode(const Value: TPPGCheckComboDisplay);
    procedure SetMaxDisplayItems(const Value: Integer);
    procedure SetDropDownCount(const Value: Integer);
    procedure SetDisplayDelimiter(const Value: string);
    procedure SetDelimiter(const Value: Char);
  protected
    procedure Loaded; override;
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
    /// Anwender hakt an/ab (OnItemCheck, OnChange).
    procedure ToggleItem(Index: Integer);
    /// Anwender: alle an bzw. aus (ein OnChange).
    procedure UserCheckAll(Value: Boolean);
    /// Aus Code: ohne Ereignisse.
    procedure CheckAll(Value: Boolean);
    function CheckedCount: Integer;
    function AllChecked: Boolean;
    /// Text wie im Feld angezeigt.
    function DisplayText: string;
    property Checked[Index: Integer]: Boolean read GetChecked write SetChecked;
  published
    property Items: TStrings read FItems write SetItems;
    /// Gewaehlte Eintraege, getrennt durch Delimiter (nach Items gespeichert).
    property CheckedText: string read GetCheckedText write SetCheckedText;
    property Delimiter: Char read FDelimiter write SetDelimiter default ';';
    property DisplayDelimiter: string read FDisplayDelimiter write SetDisplayDelimiter;
    property DisplayMode: TPPGCheckComboDisplay read FDisplayMode write SetDisplayMode
      default cdmCompact;
    property MaxDisplayItems: Integer read FMaxDisplayItems write SetMaxDisplayItems default 2;
    property ShowSelectAll: Boolean read FShowSelectAll write FShowSelectAll default False;
    /// Filterzeile ab so vielen Eintraegen (0 = nie).
    property FilterThreshold: Integer read FFilterThreshold write FFilterThreshold default 12;
    property DropDownCount: Integer read FDropDownCount write SetDropDownCount default 8;
    property OnItemCheck: TPPGCheckItemEvent read FOnItemCheck write FOnItemCheck;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
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
    property ReadOnly;
    property ReadOnlyStyle;
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
  System.Math, Winapi.oleacc, PPG.Appearance, PPG.DpiUtils, PPG.Lang, PPG.Consts,
  PPG.Render.Registry, PPG.Exceptions;

{ TPPGCheckListPopup }

procedure TPPGCheckListPopup.Prepare(ACombo: TPPGCheckComboBox);
begin
  FCombo := ACombo;
  MaxRows := ACombo.DropDownCount;
  FilterEnabled := (ACombo.FilterThreshold > 0) and
    (ACombo.Items.Count >= ACombo.FilterThreshold);
  ResetView(-1);
  BuildMap;
  if RowCount > 0 then
    SetFocusRow(0);
end;

procedure TPPGCheckListPopup.BuildMap;
var
  I, N: Integer;
  F: string;
begin
  F := AnsiLowerCase(Filter);
  SetLength(FMap, FCombo.Items.Count + 1);
  N := 0;
  if FCombo.ShowSelectAll and (F = '') then
  begin
    FMap[0] := -1;
    N := 1;
  end;
  for I := 0 to FCombo.Items.Count - 1 do
    if (F = '') or (Pos(F, AnsiLowerCase(FCombo.Items[I])) > 0) then
    begin
      FMap[N] := I;
      Inc(N);
    end;
  SetLength(FMap, N);
end;

procedure TPPGCheckListPopup.FilterChanged;
begin
  BuildMap;
end;

procedure TPPGCheckListPopup.ItemsChanged;
begin
  BuildMap;
  SetFocusRow(FocusRow); // auf den neuen Bereich begrenzen
  Invalidate;
end;

function TPPGCheckListPopup.RowCount: Integer;
begin
  Result := Length(FMap);
end;

function TPPGCheckListPopup.ItemOfRow(Row: Integer): Integer;
begin
  if (Row >= 0) and (Row < Length(FMap)) then
    Result := FMap[Row]
  else
    Result := -2;
end;

procedure TPPGCheckListPopup.PaintRow(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const ListStyle, HighlightStyle: TPPGSurfaceStyle; Hot, Focused: Boolean);
var
  IR: IPPGIndicatorRenderer;
  A: TPPGAppearance;
  S: TPPGSurfaceStyle;
  PPI, Sz, Item: Integer;
  Box, TR: TRect;
  State: TCheckBoxState;
  Caption: string;
  TextColor: TColor;
begin
  PPI := ScalePPI;
  // Audit 08.10.2026: Eintraege koennen sich bei offener Liste aendern
  // (z. B. OnItemCheck loescht); Paint wirft nie
  if (Index < 0) or (Index > High(FMap)) then
    Exit;
  Item := FMap[Index];
  if Item >= FCombo.Items.Count then
    Exit;
  if Item < 0 then
  begin
    Caption := PPGStr(@SPPGSelectAll);
    if FCombo.AllChecked then
      State := cbChecked
    else if FCombo.CheckedCount > 0 then
      State := cbGrayed
    else
      State := cbUnchecked;
  end
  else
  begin
    Caption := FCombo.Items[Item];
    if FCombo.Checked[Item] then
      State := cbChecked
    else
      State := cbUnchecked;
  end;
  A := EffectiveAppearance;
  if State = cbChecked then
    S := A.ResolveStyle(A.Checked, PPI, False)
  else if Hot then
    S := A.Resolve(vsHot, PPI, False)
  else
    S := A.Resolve(vsNormal, PPI, False);
  S.GlowAlpha := 0;
  S.GlowSize := 0;
  if HighContrastSupport and PPGIsHighContrast then
  begin
    S.Color := PPGColorToRGB(clWindow);
    S.ColorTo := S.Color;
    S.ColorMirror := S.Color;
    S.ColorMirrorTo := S.Color;
    S.BorderColor := PPGColorToRGB(clWindowText);
    S.TextColor := PPGColorToRGB(clWindowText);
  end;
  Sz := PPGScale(18, PPI);
  Box := Rect(R.Left + PPGScale(8, PPI), (R.Top + R.Bottom - Sz) div 2,
    R.Left + PPGScale(8, PPI) + Sz, (R.Top + R.Bottom - Sz) div 2 + Sz);
  if Supports(Renderer, IPPGIndicatorRenderer, IR) then
    IR.DrawCheckIndicator(ACanvas, Box, S, State, PPI);
  if Hot then
    TextColor := HighlightStyle.TextColor
  else
    TextColor := ListStyle.TextColor;
  TR := Rect(Box.Right + PPGScale(10, PPI), R.Top, R.Right - PPGScale(6, PPI), R.Bottom);
  ACanvas.DrawText(TR, Caption, Font, TextColor,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

function TPPGCheckListPopup.RowActivate(Index: Integer; ByMouse: Boolean;
  X: Integer): TPPGDropAction;
var
  Item: Integer;
begin
  Result := pdaKeepOpen;
  Item := ItemOfRow(Index);
  if Item = -1 then
    FCombo.UserCheckAll(not FCombo.AllChecked)
  else if Item >= 0 then
    FCombo.ToggleItem(Item);
  Invalidate;
  NotifyAccessibilityChild(EVENT_OBJECT_STATECHANGE, Index + 1);
end;

function TPPGCheckListPopup.DropKeyDown(var Key: Word; Shift: TShiftState): TPPGDropAction;
begin
  // Enter schliesst (Haken wirken schon), Leertaste hakt an
  if Key = VK_RETURN then
  begin
    Key := 0;
    Exit(pdaAccept);
  end;
  Result := inherited DropKeyDown(Key, Shift);
end;

function TPPGCheckListPopup.AccName: string;
begin
  if FCombo <> nil then
    Result := FCombo.AccName
  else
    Result := '';
end;

function TPPGCheckListPopup.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_LIST;
end;

function TPPGCheckListPopup.AccChildCount: Integer;
begin
  Result := RowCount;
end;

function TPPGCheckListPopup.AccChildName(Id: Integer): string;
var
  Item: Integer;
begin
  Item := ItemOfRow(Id - 1);
  if Item = -1 then
    Result := PPGStr(@SPPGSelectAll)
  else if Item >= 0 then
    Result := FCombo.Items[Item]
  else
    Result := '';
end;

function TPPGCheckListPopup.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_CHECKBUTTON;
end;

function TPPGCheckListPopup.AccChildState(Id: Integer): Integer;
var
  Item: Integer;
begin
  Result := STATE_SYSTEM_FOCUSABLE;
  Item := ItemOfRow(Id - 1);
  if ((Item >= 0) and FCombo.Checked[Item]) or ((Item = -1) and FCombo.AllChecked) then
    Result := Result or STATE_SYSTEM_CHECKED;
  if Id - 1 = FocusRow then
    Result := Result or STATE_SYSTEM_FOCUSED;
end;

function TPPGCheckListPopup.AccChildRect(Id: Integer): TRect;
begin
  Result := RowRect(Id - 1);
end;

function TPPGCheckListPopup.AccChildAt(X, Y: Integer): Integer;
begin
  Result := RowAt(X, Y) + 1;
end;

function TPPGCheckListPopup.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccToggle);
end;

procedure TPPGCheckListPopup.AccChildDoDefault(Id: Integer);
begin
  // Fokus setzen und die Leertaste des Felds posten (nie im COM-Aufruf)
  if (Id >= 1) and (Id <= RowCount) and (FCombo <> nil) and FCombo.HandleAllocated then
  begin
    SetFocusRow(Id - 1);
    PostMessage(FCombo.Handle, WM_KEYDOWN, VK_SPACE, 0);
  end;
end;

function TPPGCheckListPopup.AccFocusedChild: Integer;
begin
  Result := FocusRow + 1;
end;

function TPPGCheckListPopup.AccSelectedChild: Integer;
begin
  Result := 0;
end;

{ TPPGCheckComboBox }

constructor TPPGCheckComboBox.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FItems := TStringList.Create;
  TStringList(FItems).OnChanging := ItemsChanging;
  TStringList(FItems).OnChange := ItemsChanged;
  FDelimiter := ';';
  FDisplayDelimiter := ', ';
  FDisplayMode := cdmCompact;
  FMaxDisplayItems := 2;
  FFilterThreshold := 12;
  FDropDownCount := 8;
  SetInnerVisible(False);
end;

destructor TPPGCheckComboBox.Destroy;
begin
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TPPGCheckComboBox.Loaded;
begin
  inherited Loaded;
  // CheckedText kann vor Items gelesen worden sein
  if FPendingText <> '' then
    SetCheckedText(FPendingText);
  FPendingText := '';
end;

procedure TPPGCheckComboBox.SetItems(const Value: TStrings);
begin
  FItems.Assign(Value);
end;

procedure TPPGCheckComboBox.ItemsChanging(Sender: TObject);
var
  I: Integer;
begin
  if FSnapValid then
    Exit;
  SetLength(FSnapTexts, FItems.Count);
  for I := 0 to FItems.Count - 1 do
    FSnapTexts[I] := FItems[I];
  FSnapChecked := Copy(FChecked, 0, Length(FChecked));
  FSnapValid := True;
end;

procedure TPPGCheckComboBox.ItemsChanged(Sender: TObject);
var
  Old, I, J, K, N, Start: Integer;
  Same: Boolean;
  Claimed: TArray<Boolean>;
  NewChecked: TArray<Boolean>;
begin
  // Audit 08.10.2026: Die Haken hingen nur an der Position und wanderten
  // nach Insert/Delete/Sort auf andere Eintraege. Jetzt werden sie ueber
  // den Text (bei gleichen Texten in Reihenfolge) neu zugeordnet.
  if FSnapValid then
  begin
    FSnapValid := False;
    N := Length(FSnapTexts);
    Same := N = FItems.Count;
    if Same then
      for I := 0 to N - 1 do
        if FItems[I] <> FSnapTexts[I] then
        begin
          Same := False;
          Break;
        end;
    if not Same then
    begin
      SetLength(NewChecked, FItems.Count);
      SetLength(Claimed, N);
      // Suche ab dem letzten Treffer: bei gleichbleibender Reihenfolge
      // (Add, Insert, Delete) linear statt quadratisch
      Start := 0;
      for I := 0 to FItems.Count - 1 do
      begin
        NewChecked[I] := False;
        for K := 0 to N - 1 do
        begin
          J := (Start + K) mod N;
          if not Claimed[J] and (FSnapTexts[J] = FItems[I]) then
          begin
            Claimed[J] := True;
            NewChecked[I] := (J < Length(FSnapChecked)) and FSnapChecked[J];
            Start := J + 1;
            Break;
          end;
        end;
      end;
      FChecked := NewChecked;
    end;
    FSnapTexts := nil;
    FSnapChecked := nil;
  end;
  Old := Length(FChecked);
  SetLength(FChecked, FItems.Count);
  for I := Old to High(FChecked) do
    FChecked[I] := False;
  if DroppedDown and (Popup is TPPGCheckListPopup) then
    TPPGCheckListPopup(Popup).ItemsChanged;
  Invalidate;
end;

function TPPGCheckComboBox.GetChecked(Index: Integer): Boolean;
begin
  if (Index < 0) or (Index > High(FChecked)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, High(FChecked)]);
  Result := FChecked[Index];
end;

procedure TPPGCheckComboBox.SetChecked(Index: Integer; const Value: Boolean);
begin
  if (Index < 0) or (Index > High(FChecked)) then
    raise EPPGError.CreateFmt(PPGStr(@SPPGIndexOutOfRange), [Index, High(FChecked)]);
  FChecked[Index] := Value;
  Invalidate;
end;

procedure TPPGCheckComboBox.ToggleItem(Index: Integer);
begin
  if ReadOnly or not Enabled or (Index < 0) or (Index > High(FChecked)) then
    Exit;
  FChecked[Index] := not FChecked[Index];
  Invalidate;
  if Assigned(FOnItemCheck) then
    FOnItemCheck(Self, Index);
  Change;
end;

procedure TPPGCheckComboBox.CheckAll(Value: Boolean);
var
  I: Integer;
begin
  for I := 0 to High(FChecked) do
    FChecked[I] := Value;
  Invalidate;
end;

procedure TPPGCheckComboBox.UserCheckAll(Value: Boolean);
begin
  if ReadOnly or not Enabled then
    Exit;
  CheckAll(Value);
  Change;
end;

function TPPGCheckComboBox.CheckedCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(FChecked) do
    if FChecked[I] then
      Inc(Result);
end;

function TPPGCheckComboBox.AllChecked: Boolean;
begin
  Result := (Length(FChecked) > 0) and (CheckedCount = Length(FChecked));
end;

function TPPGCheckComboBox.GetCheckedText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FChecked) do
    if FChecked[I] then
    begin
      if Result <> '' then
        Result := Result + FDelimiter;
      Result := Result + FItems[I];
    end;
end;

procedure TPPGCheckComboBox.SetCheckedText(const Value: string);
var
  Parts: TArray<string>;
  I, J: Integer;
begin
  if csLoading in ComponentState then
  begin
    FPendingText := Value;
    Exit;
  end;
  CheckAll(False);
  Parts := PPGSplitString(Value, FDelimiter, True);
  for I := 0 to High(Parts) do
  begin
    J := FItems.IndexOf(Trim(Parts[I]));
    if J >= 0 then
      FChecked[J] := True;
  end;
  Invalidate;
end;

procedure TPPGCheckComboBox.SetDelimiter(const Value: Char);
begin
  if Value = #0 then
    raise EPPGPropertyError.CreateInvalid(Self, 'Delimiter', '#0');
  FDelimiter := Value;
end;

procedure TPPGCheckComboBox.SetDisplayDelimiter(const Value: string);
begin
  FDisplayDelimiter := Value;
  Invalidate;
end;

procedure TPPGCheckComboBox.SetDisplayMode(const Value: TPPGCheckComboDisplay);
begin
  FDisplayMode := Value;
  Invalidate;
end;

procedure TPPGCheckComboBox.SetMaxDisplayItems(const Value: Integer);
begin
  FMaxDisplayItems := PPGCheckRange(Self, 'MaxDisplayItems', Value, 1, 100);
  Invalidate;
end;

procedure TPPGCheckComboBox.SetDropDownCount(const Value: Integer);
begin
  FDropDownCount := PPGCheckRange(Self, 'DropDownCount', Value, 1, 100);
end;

function TPPGCheckComboBox.DisplayText: string;
var
  I, Shown, N: Integer;
begin
  N := CheckedCount;
  Result := '';
  if N = 0 then
    Exit;
  if FDisplayMode = cdmCount then
    Exit(Format(PPGStr(@SPPGCheckedCount), [N]));
  Shown := 0;
  for I := 0 to High(FChecked) do
    if FChecked[I] then
    begin
      if (FDisplayMode = cdmCompact) and (Shown = FMaxDisplayItems) then
      begin
        Result := Result + FDisplayDelimiter + '+' + IntToStr(N - Shown);
        Exit;
      end;
      if Result <> '' then
        Result := Result + FDisplayDelimiter;
      Result := Result + FItems[I];
      Inc(Shown);
    end;
end;

function TPPGCheckComboBox.CreatePopup: TPPGDropPopup;
begin
  Result := TPPGCheckListPopup.Create(Self);
end;

procedure TPPGCheckComboBox.PreparePopup(APopup: TPPGDropPopup);
begin
  TPPGCheckListPopup(APopup).Prepare(Self);
end;

procedure TPPGCheckComboBox.AcceptPopup(APopup: TPPGDropPopup);
begin
  // Haken wirken sofort; nichts mehr zu uebernehmen
end;

procedure TPPGCheckComboBox.ClosedKeyDown(var Key: Word; Shift: TShiftState);
begin
  if Key = VK_SPACE then
  begin
    DropDown;
    Key := 0;
  end;
end;

procedure TPPGCheckComboBox.DoPaintField(const ACanvas: IPPGCanvas;
  const Style: TPPGSurfaceStyle);
var
  R, B: TRect;
  S: string;
  C: TColor;
begin
  inherited DoPaintField(ACanvas, Style);
  R := ClientRect;
  InflateRect(R, -PPGScale(10, ScalePPI), 0);
  B := ButtonRect(PPGDropButton);
  if not IsRectEmpty(B) then
    R.Right := B.Left - PPGScale(4, ScalePPI);
  S := DisplayText;
  C := Style.TextColor;
  if S = '' then
  begin
    S := TextHint;
    C := HintColor;
  end;
  ACanvas.DrawText(R, S, Font, C,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

function TPPGCheckComboBox.AccValue: string;
begin
  Result := DisplayText;
end;

function TPPGCheckComboBox.FieldIsNull: Boolean;
begin
  Result := CheckedCount = 0;
end;

procedure TPPGCheckComboBox.FieldClear;
begin
  CheckAll(False);
end;

function TPPGCheckComboBox.GetFieldValue: Variant;
begin
  if CheckedCount = 0 then
    Result := Null
  else
    Result := GetCheckedText;
end;

procedure TPPGCheckComboBox.SetFieldValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    CheckAll(False)
  else
    SetCheckedText(VarToStr(Value));
end;

end.
