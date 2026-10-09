unit PPG.ToggleSwitch;

{ TPPGToggleSwitch - Ein/Aus-Schalter mit gleitendem Knopf (animiert ueber
  dieselbe Zustandslogik wie CheckBox/RadioButton). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Types, Vcl.StdCtrls, PPG.Types, PPG.Render.Intf,
  PPG.Controls.Check;

type
  TPPGCustomToggleSwitch = class(TPPGCustomCheckControl)
  protected
    function GetIndicatorSize: TSize; override;
    procedure DrawIndicator(const ACanvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; const IR: IPPGIndicatorRenderer); override;
  protected
    function AccValue: string; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

  TPPGToggleSwitch = class(TPPGCustomToggleSwitch)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Alignment;
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
    property Touch;
    property OnGesture;
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
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseWheel;
    property OnMouseActivate;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
  end;

implementation

uses
  PPG.Lang,
  PPG.Consts;

function TPPGCustomToggleSwitch.AccValue: string;
begin
  // Schalter melden zusaetzlich "Ein"/"Aus" als Wert (wie Windows-Schalter)
  if Checked then
    Result := PPGStr(@SPPGAccOn)
  else
    Result := PPGStr(@SPPGAccOff);
end;

constructor TPPGCustomToggleSwitch.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Height := 28;
end;

function TPPGCustomToggleSwitch.GetIndicatorSize: TSize;
begin
  Result.cx := 40;
  Result.cy := 20;
end;

procedure TPPGCustomToggleSwitch.DrawIndicator(const ACanvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; const IR: IPPGIndicatorRenderer);
begin
  IR.DrawSwitch(ACanvas, R, Style, CheckProgress, UseRightToLeftAlignment, ScalePPI);
end;

end.
