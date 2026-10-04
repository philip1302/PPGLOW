unit PPG.RadioButton;

{ TPPGRadioButton - Optionsfeld. Innerhalb desselben Parents und derselben
  GroupIndex ist immer hoechstens einer eingeschaltet.

  Bedienung wie unter Windows:
  - Klick/Leertaste schaltet ein (nie aus).
  - Pfeiltasten wechseln innerhalb der Gruppe (nach TabOrder, mit Umlauf)
    und schalten den neuen RadioButton ein.

  Stolperstein: Pfeiltasten verarbeitet sonst das Formular (Fokuswechsel).
  Deshalb meldet WM_GETDLGCODE DLGC_WANTARROWS. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Controls,
  Vcl.StdCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Check;

type
  TPPGCustomRadioButton = class(TPPGCustomCheckControl)
  private
    FGroupIndex: Integer;
    procedure SetGroupIndex(const Value: Integer);
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    function IsSameGroup(C: TControl): Boolean;
  protected
    procedure Toggle; override;
    procedure StateChanged; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function AccRole: Integer; override;
    function AccDefaultAction: string; override;
    function GetIndicatorSize: TSize; override;
    procedure DrawIndicator(const ACanvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; const IR: IPPGIndicatorRenderer); override;
    /// Naechster/vorheriger bedienbarer RadioButton der Gruppe (nach TabOrder).
    function FindSibling(Forward: Boolean): TPPGCustomRadioButton;
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex default 0;
  end;

  TPPGRadioButton = class(TPPGCustomRadioButton)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Alignment;
    property GroupIndex;
    property Checked;
    property Spacing;
    property WordWrap;
    property ShowFocusRect;
    property HighContrastSupport;
    property OnChange;
    { VCL-Standard }
    property Action;
    property Align;
    property Anchors;
    property AutoSize;
    property BiDiMode;
    property Caption;
    property Color;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property ParentBackground default True;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

implementation

uses
  System.Generics.Collections, System.Generics.Defaults, Winapi.oleacc, PPG.Consts;

function TPPGCustomRadioButton.IsSameGroup(C: TControl): Boolean;
begin
  Result := (C <> Self) and (C is TPPGCustomRadioButton) and
    (TPPGCustomRadioButton(C).FGroupIndex = FGroupIndex);
end;

procedure TPPGCustomRadioButton.Toggle;
begin
  // RadioButtons werden durch Bedienung nur EINgeschaltet
  if not Checked then
    SetStateInternal(cbChecked, True);
end;

procedure TPPGCustomRadioButton.StateChanged;
var
  I: Integer;
  Sibling: TPPGCustomRadioButton;
begin
  inherited StateChanged;
  // Beim Laden nichts korrigieren: die DFM ist die Wahrheit, Geschwister
  // sind evtl. noch gar nicht geladen.
  if not Checked or (Parent = nil) or (csLoading in ComponentState) then
    Exit;
  for I := 0 to Parent.ControlCount - 1 do
    if IsSameGroup(Parent.Controls[I]) then
    begin
      Sibling := TPPGCustomRadioButton(Parent.Controls[I]);
      if Sibling.Checked then
        Sibling.SetStateInternal(cbUnchecked, True);
    end;
end;

procedure TPPGCustomRadioButton.SetGroupIndex(const Value: Integer);
begin
  if FGroupIndex <> Value then
  begin
    FGroupIndex := Value;
    if Checked then
      StateChanged; // in der neuen Gruppe exklusiv machen
  end;
end;

procedure TPPGCustomRadioButton.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

function TPPGCustomRadioButton.FindSibling(Forward: Boolean): TPPGCustomRadioButton;
var
  List: TList<TPPGCustomRadioButton>;
  I, Idx: Integer;
  C: TControl;
begin
  Result := nil;
  if Parent = nil then
    Exit;
  List := TList<TPPGCustomRadioButton>.Create;
  try
    for I := 0 to Parent.ControlCount - 1 do
    begin
      C := Parent.Controls[I];
      if (C = Self) or (IsSameGroup(C) and C.Visible and C.Enabled) then
        List.Add(TPPGCustomRadioButton(C));
    end;
    if List.Count < 2 then
      Exit;
    List.Sort(TComparer<TPPGCustomRadioButton>.Construct(
      function(const A, B: TPPGCustomRadioButton): Integer
      begin
        Result := A.TabOrder - B.TabOrder;
      end));
    Idx := List.IndexOf(Self);
    if Forward then
      Idx := (Idx + 1) mod List.Count
    else
      Idx := (Idx - 1 + List.Count) mod List.Count;
    Result := List[Idx];
  finally
    List.Free;
  end;
end;

procedure TPPGCustomRadioButton.KeyDown(var Key: Word; Shift: TShiftState);
var
  Next: TPPGCustomRadioButton;
begin
  if (Shift = []) and ((Key = VK_LEFT) or (Key = VK_UP) or (Key = VK_RIGHT) or
    (Key = VK_DOWN)) then
  begin
    Next := FindSibling((Key = VK_RIGHT) or (Key = VK_DOWN));
    Key := 0;
    if Next <> nil then
    begin
      if Next.CanFocus then
        Next.SetFocus;
      Next.Click; // einschalten + OnClick wie bei Benutzerbedienung
    end;
    Exit;
  end;
  inherited KeyDown(Key, Shift);
end;

function TPPGCustomRadioButton.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_RADIOBUTTON;
end;

function TPPGCustomRadioButton.AccDefaultAction: string;
begin
  Result := SPPGAccSelect;
end;

function TPPGCustomRadioButton.GetIndicatorSize: TSize;
begin
  Result.cx := 16;
  Result.cy := 16;
end;

procedure TPPGCustomRadioButton.DrawIndicator(const ACanvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; const IR: IPPGIndicatorRenderer);
begin
  IR.DrawRadioIndicator(ACanvas, R, Style, CheckProgress > 0.5, ScalePPI);
end;

end.
