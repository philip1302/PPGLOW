unit PPG.CheckBox;

{ TPPGCheckBox - Kontrollkaestchen mit optionalem dritten Zustand
  (AllowGrayed). Ereignis-Semantik siehe PPG.Controls.Check. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.Types, Vcl.StdCtrls, PPG.Types, PPG.Render.Intf,
  PPG.Controls.Check;

type
  TPPGCustomCheckBox = class(TPPGCustomCheckControl)
  protected
    procedure DrawIndicator(const ACanvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; const IR: IPPGIndicatorRenderer); override;
  end;

  TPPGCheckBox = class(TPPGCustomCheckBox)
  public
    property Checked; // zur Laufzeit; gespeichert wird State
  published
    { PPGlow - Preset VOR Appearance (Streaming-Reihenfolge) }
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Alignment;
    property AllowGrayed;
    property State;
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

procedure TPPGCustomCheckBox.DrawIndicator(const ACanvas: IPPGCanvas; const R: TRect;
  const Style: TPPGSurfaceStyle; const IR: IPPGIndicatorRenderer);
var
  S: TPPGCheckState;
begin
  S := State;
  // Waehrend der Ausblend-Animation den Haken noch zeigen
  if (S = cbUnchecked) and (CheckProgress > 0.5) then
    S := cbChecked;
  if (S = cbChecked) and (CheckProgress < 0.5) then
    S := cbUnchecked;
  IR.DrawCheckIndicator(ACanvas, R, Style, S, ScalePPI);
end;

end.
