unit PPG.SearchEdit;

{ TPPGSearchEdit - Suchfeld mit Vorschlagsliste (Phase 7a, wie WinUI AutoSuggestBox).

  Basis ist die ComboBox (csDropDown): natives Edit, eigene Aufklappliste,
  Filter beim Tippen und Tastatur kommen von dort. Dazu:
  - Lupen-Button rechts (Klick = Suche absenden), Loeschen-Knopf, kein
    Aufklapp-Pfeil.
  - SearchDelay: Nach dem Tippen wartet das Feld SearchDelay ms (ueber den
    gemeinsamen Animator, kein Timer) und loest dann OnSearch aus. Dort kann
    die Anwendung Items (die Vorschlaege) neu fuellen; danach zeigt das Feld
    die Liste automatisch (gefiltert nach FilterMode).
  - Enter, Klick auf die Lupe oder Wahl eines Vorschlags loesen OnSubmit aus
    (sofort, eine wartende Suche entfaellt). Esc schliesst die Liste bzw.
    leert den Text.
  - Text im Code setzen loest weder OnSearch noch OnSubmit aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Field, PPG.ComboBox;

type
  TPPGSearchEvent = procedure(Sender: TObject; const SearchText: string) of object;

  TPPGCustomSearchEdit = class(TPPGCustomComboBox)
  private
    FSearchDelay: Integer;
    FDelayAnim: TPPGAnimation;
    FSearchPending: Boolean;
    FInSearch: Boolean;
    FOnSearch: TPPGSearchEvent;
    FOnSubmit: TPPGSearchEvent;
    procedure SetSearchDelay(const Value: Integer);
    procedure DelayStep(Sender: TObject);
  protected
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    function ButtonVisible(Id: Integer): Boolean; override;
    procedure ButtonClick(Id: Integer); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure Change; override;
    procedure DoSelect; override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccRole: Integer; override;
    /// Suche ausloesen (OnSearch), danach Vorschlaege zeigen.
    procedure DoSearch; virtual;
    /// Suche absenden (OnSubmit).
    procedure DoSubmit; virtual;
    /// Wartezeit in ms bis OnSearch (0 = sofort bei jeder Aenderung).
    property SearchDelay: Integer read FSearchDelay write SetSearchDelay default 300;
    property OnSearch: TPPGSearchEvent read FOnSearch write FOnSearch;
    property OnSubmit: TPPGSearchEvent read FOnSubmit write FOnSubmit;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Wartende Suche sofort ausfuehren (z.B. vor dem Schliessen eines Dialogs).
    procedure FlushSearch;
    /// Vorschlaege (Items) zeigen, wenn Text und Treffer vorhanden sind.
    procedure ShowSuggestions;
    /// True, solange eine Suche auf den Ablauf von SearchDelay wartet.
    property SearchPending: Boolean read FSearchPending;
  end;

  TPPGSearchEdit = class(TPPGCustomSearchEdit)
  private
    function GetAutoSelect: Boolean;
    procedure SetAutoSelect(const Value: Boolean);
  published
    /// Text beim Fokuserhalt markieren (wie TSearchBox).
    property AutoSelect: Boolean read GetAutoSelect write SetAutoSelect default True;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property ItemsEx;
    property FilterMode default fmContains;
    property SearchDelay;
    property ShowClearButton default True;
    property TextHint;
    property UseSystemContextMenu;
    property TextHintVisibleOnFocus;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property Align;
    property Anchors;
    property AutoComplete default False;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property CharCase;
    property Color default clWindow;
    property Constraints;
    property DropDownCount;
    property DropDownWidth;
    property Enabled;
    property Font;
    property ItemHeight;
    property Items;
    property MaxLength;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Sorted;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Text;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnCloseUp;
    property OnContextPopup;
    property OnDropDown;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnSearch;
    property OnSelect;
    property OnSubmit;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseActivate;
    property DragMode;
    property DragCursor;
    property OnDragDrop;
    property OnDragOver;
    property OnStartDrag;
    property OnEndDrag;
    // Audit 5d: wie VCL (PPGlow zeichnet ohnehin gepuffert)
    property DoubleBuffered;
    property ParentDoubleBuffered;
    // Audit 5d Stufe 3: wie VCL
    property ReadOnly;
    property Alignment;
  end;

const
  /// Button-Id der Lupe.
  PPGSearchButtonQuery = 30;

implementation

uses
  System.SysUtils, System.Math, Winapi.oleacc,
  PPG.Appearance, PPG.DpiUtils, PPG.IconFont;

type
  TEditAccess = class(TCustomEdit);

{ TPPGSearchEdit }

function TPPGSearchEdit.GetAutoSelect: Boolean;
begin
  Result := TEditAccess(Inner).AutoSelect;
end;

procedure TPPGSearchEdit.SetAutoSelect(const Value: Boolean);
begin
  TEditAccess(Inner).AutoSelect := Value;
end;

{ TPPGCustomSearchEdit }

constructor TPPGCustomSearchEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSearchDelay := 300;
  FilterMode := fmContains;
  AutoComplete := False;
  ShowClearButton := True;
  FDelayAnim := TPPGAnimation.Create(Self);
  FDelayAnim.OnStep := DelayStep;
end;

destructor TPPGCustomSearchEdit.Destroy;
begin
  if FDelayAnim <> nil then
    FDelayAnim.OnStep := nil;
  FreeAndNil(FDelayAnim);
  inherited Destroy;
end;

procedure TPPGCustomSearchEdit.SetSearchDelay(const Value: Integer);
begin
  FSearchDelay := PPGCheckRange(Self, 'SearchDelay', Value, 0, 10000);
end;

procedure TPPGCustomSearchEdit.GetButtons(var Buttons: TPPGFieldButtons);
var
  N, I, J: Integer;
begin
  // Lupe ganz aussen, dann Loeschen-Knopf (Basis); den Pfeil der Combo gibt es nicht
  N := Length(Buttons);
  SetLength(Buttons, N + 1);
  Buttons[N].Id := PPGSearchButtonQuery;
  Buttons[N].Glyph := fgNone; // Lupe zeichnet DoPaintField
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
  inherited GetButtons(Buttons);
  J := 0;
  for I := 0 to High(Buttons) do
    if Buttons[I].Id <> PPGComboButtonDrop then
    begin
      Buttons[J] := Buttons[I];
      Inc(J);
    end;
  SetLength(Buttons, J);
end;

function TPPGCustomSearchEdit.ButtonVisible(Id: Integer): Boolean;
begin
  if Id = PPGComboButtonDrop then
    Result := False
  else
    Result := inherited ButtonVisible(Id);
end;

procedure TPPGCustomSearchEdit.ButtonClick(Id: Integer);
begin
  if Id = PPGSearchButtonQuery then
  begin
    if DroppedDown then
      CloseUp(False);
    DoSubmit;
    if not FieldFocused and CanFocus and HandleAllocated and IsWindowVisible(Handle) then
      SetFocus;
    Exit;
  end;
  inherited ButtonClick(Id);
end;

procedure TPPGCustomSearchEdit.Change;
var
  Mode: TPPGFilterMode;
begin
  // Die Combo filtert beim Tippen sofort - hier waeren das die Vorschlaege der
  // letzten Suche. Gefiltert wird erst nach OnSearch (ShowSuggestions).
  Mode := FilterMode;
  FilterMode := fmNone;
  try
    inherited Change;
  finally
    FilterMode := Mode;
  end;
  if IsQuiet or (csLoading in ComponentState) or FInSearch then
    Exit;
  // Getippt oder geleert: Suche nach SearchDelay
  if (FSearchDelay = 0) or (csDesigning in ComponentState) then
    DoSearch
  else
  begin
    FSearchPending := True;
    FDelayAnim.Jump(0);
    FDelayAnim.AnimateTo(1, Cardinal(FSearchDelay), ekLinear);
  end;
end;

procedure TPPGCustomSearchEdit.DelayStep(Sender: TObject);
begin
  if FSearchPending and not FDelayAnim.Running then
    DoSearch;
end;

procedure TPPGCustomSearchEdit.FlushSearch;
begin
  if FSearchPending then
    DoSearch;
end;

procedure TPPGCustomSearchEdit.DoSearch;
begin
  FSearchPending := False;
  if FDelayAnim.Running then
    FDelayAnim.Stop;
  FInSearch := True;
  try
    if Assigned(FOnSearch) then
      FOnSearch(Self, Text);
  finally
    FInSearch := False;
  end;
  if not (csDestroying in ComponentState) then
    ShowSuggestions;
end;

procedure TPPGCustomSearchEdit.ShowSuggestions;
begin
  if not FieldFocused or (Text = '') then
  begin
    if DroppedDown then
      CloseUp(False);
    Exit;
  end;
  if Items.Count = 0 then
  begin
    if DroppedDown then
      CloseUp(False);
    Exit;
  end;
  if FilterMode <> fmNone then
    ApplyFilter // filtert und klappt auf bzw. zu
  else if not DroppedDown then
    DropDown;
end;

procedure TPPGCustomSearchEdit.DoSubmit;
begin
  FSearchPending := False;
  if FDelayAnim.Running then
    FDelayAnim.Stop;
  if Assigned(FOnSubmit) then
    FOnSubmit(Self, Text);
end;

procedure TPPGCustomSearchEdit.DoSelect;
begin
  inherited DoSelect;
  DoSubmit; // Vorschlag gewaehlt = Suche absenden
end;

function TPPGCustomSearchEdit.WantSpecialKey(Key: Word): Boolean;
begin
  // Enter sendet die Suche ab, Esc leert - beides nicht an Default-/Cancel-Button
  Result := inherited WantSpecialKey(Key) or (Key = VK_RETURN) or
    ((Key = VK_ESCAPE) and HasText and not ReadOnly);
end;

procedure TPPGCustomSearchEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if not DroppedDown then
    case Key of
      VK_RETURN:
        begin
          DoSubmit;
          Key := 0;
          Exit;
        end;
      VK_ESCAPE:
        if HasText and not ReadOnly then
        begin
          Text := '';
          Change; // Anwender hat geleert: OnChange und Suche
          Key := 0;
          Exit;
        end;
      VK_DOWN:
        if (Shift = []) and (Items.Count > 0) then
        begin
          // Unten oeffnet die Vorschlaege (statt den Eintrag zu wechseln)
          ShowSuggestions;
          if not DroppedDown then
            DropDown;
          Key := 0;
          Exit;
        end;
      VK_UP:
        if Shift = [] then
        begin
          Key := 0; // kein Blaettern durch die Vorschlaege im geschlossenen Feld
          Exit;
        end;
    end;
  inherited FieldKeyDown(Key, Shift);
end;

procedure TPPGCustomSearchEdit.DoPaintField(const ACanvas: IPPGCanvas;
  const Style: TPPGSurfaceStyle);
var
  R, C: TRect;
  PPI, D, W: Integer;
  Pts: array[0..1] of TPoint;
  Col: TColor;
begin
  inherited DoPaintField(ACanvas, Style);
  R := ButtonRect(PPGSearchButtonQuery);
  if IsRectEmpty(R) then
    Exit;
  PPI := ScalePPI;
  Col := Style.TextColor;
  if not PPGDrawIcon(ACanvas, R, igSearch, Col, PPGScale(12, PPI)) then
  begin
    // Ersatz: Kreis mit Stiel
    D := PPGScale(9, PPI);
    W := Max(1, Round(1.5 * PPI / 96));
    C := Rect((R.Left + R.Right) div 2 - D div 2 - 1, (R.Top + R.Bottom) div 2 - D div 2 - 1,
      (R.Left + R.Right) div 2 - D div 2 - 1 + D, (R.Top + R.Bottom) div 2 - D div 2 - 1 + D);
    ACanvas.FrameEllipse(C, W, Col, 255);
    Pts[0] := Point(C.Right - D div 6, C.Bottom - D div 6);
    Pts[1] := Point(C.Right + D div 3, C.Bottom + D div 3);
    ACanvas.DrawPolyline(Pts, W, Col, 255);
  end;
end;

function TPPGCustomSearchEdit.AccRole: Integer;
begin
  // Ein Suchfeld ist fuer Screenreader ein Eingabefeld mit Vorschlagsliste
  Result := ROLE_SYSTEM_COMBOBOX;
end;

end.
