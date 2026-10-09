unit PPG.Memo;

{ TPPGMemo - mehrzeiliges Eingabefeld in der Optik des Presets.

  - Natives Memo ohne Rahmen im PPGlow-Rahmen (siehe PPG.Controls.Field)
  - TextHint (auch fuer Memos, die ihn nativ nicht kennen), ValidationState
  - Die Scrollbalken bleiben nativ; mit VCL-Style faerbt sie der Style-Hook.
    Eigene Scrollbalken waeren ein eigenes Control (bewusst nicht in Phase 4).
  - Migration: Property-Namen von TMemo (Lines, ScrollBars, WordWrap, ...). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Types, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  // nach Vcl.StdCtrls: ab XE3 liegt TScrollStyle in System.UITypes (Alias deprecated)
  System.UITypes,
  PPG.Controls.Field;

type
  TPPGCustomMemo = class(TPPGCustomField)
  private
    function GetLines: TStrings;
    procedure SetLines(const Value: TStrings);
    function GetScrollBars: TScrollStyle;
    procedure SetScrollBars(const Value: TScrollStyle);
    function GetWantReturns: Boolean;
    procedure SetWantReturns(const Value: Boolean);
    function GetWantTabs: Boolean;
    procedure SetWantTabs(const Value: Boolean);
    function GetMemoWordWrap: Boolean;
    procedure SetMemoWordWrap(const Value: Boolean);
    function GetCaretPos: TPoint;
    procedure SetCaretPos(const Value: TPoint);
  protected
    function CreateInner: TCustomEdit; override;
    function AccValue: string; override;
    property Lines: TStrings read GetLines write SetLines;
    property ScrollBars: TScrollStyle read GetScrollBars write SetScrollBars default ssNone;
    property WantReturns: Boolean read GetWantReturns write SetWantReturns default True;
    property WantTabs: Boolean read GetWantTabs write SetWantTabs default False;
    property WordWrap: Boolean read GetMemoWordWrap write SetMemoWordWrap default True;
  public
    constructor Create(AOwner: TComponent); override;
    property CaretPos: TPoint read GetCaretPos write SetCaretPos;
  end;

  TPPGMemo = class(TPPGCustomMemo)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property UseSystemContextMenu;
    property TextHintVisibleOnFocus;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    { wie TMemo }
    property Align;
    property Alignment;
    property Anchors;
    property BiDiMode;
    property BorderStyle;
    property CharCase;
    property Color default clWindow;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property Font;
    property HideSelection;
    property Lines;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ReadOnlyStyle;
    property ScrollBars;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Visible;
    property Touch;
    property OnGesture;
    property WantReturns;
    property WantTabs;
    property WordWrap;
    property OnChange;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
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
    property OnMouseWheel;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseActivate;
  end;

implementation

type
  TMemoAccess = class(TCustomMemo);

function Memo(C: TCustomEdit): TMemoAccess; inline;
begin
  Result := TMemoAccess(C);
end;

{ TPPGCustomMemo }

constructor TPPGCustomMemo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoSize := False; // Mehrzeiler: Groesse bestimmt der Anwender
  Width := 185;
  Height := 89;
end;

function TPPGCustomMemo.CreateInner: TCustomEdit;
begin
  Result := TPPGFieldMemo.Create(Self);
end;

function TPPGCustomMemo.GetLines: TStrings;
begin
  Result := Memo(Inner).Lines;
end;

procedure TPPGCustomMemo.SetLines(const Value: TStrings);
begin
  Memo(Inner).Lines.Assign(Value);
end;

function TPPGCustomMemo.GetScrollBars: TScrollStyle;
begin
  Result := Memo(Inner).ScrollBars;
end;

procedure TPPGCustomMemo.SetScrollBars(const Value: TScrollStyle);
begin
  Memo(Inner).ScrollBars := Value;
end;

function TPPGCustomMemo.GetWantReturns: Boolean;
begin
  Result := Memo(Inner).WantReturns;
end;

procedure TPPGCustomMemo.SetWantReturns(const Value: Boolean);
begin
  Memo(Inner).WantReturns := Value;
end;

function TPPGCustomMemo.GetWantTabs: Boolean;
begin
  Result := Memo(Inner).WantTabs;
end;

procedure TPPGCustomMemo.SetWantTabs(const Value: Boolean);
begin
  Memo(Inner).WantTabs := Value;
end;

function TPPGCustomMemo.GetMemoWordWrap: Boolean;
begin
  Result := Memo(Inner).WordWrap;
end;

procedure TPPGCustomMemo.SetMemoWordWrap(const Value: Boolean);
begin
  Memo(Inner).WordWrap := Value;
  InvalidateInner;
end;

function TPPGCustomMemo.GetCaretPos: TPoint;
begin
  Result := Memo(Inner).CaretPos;
end;

procedure TPPGCustomMemo.SetCaretPos(const Value: TPoint);
begin
  Memo(Inner).CaretPos := Value;
end;

function TPPGCustomMemo.AccValue: string;
begin
  Result := Text;
end;

end.
