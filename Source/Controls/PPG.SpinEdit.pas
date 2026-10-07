unit PPG.SpinEdit;

{ TPPGSpinEdit - Zahlenfeld mit Auf-/Ab-Buttons in der Optik des Presets.

  - Verhalten wie Vcl.Samples.Spin.TSpinEdit (gleiche Property-Namen, DFM per
    Suchen/Ersetzen umstellbar):
    * MinValue = MaxValue bedeutet "keine Grenze", sonst wird Value auf den
      Bereich begrenzt (still, wie TSpinEdit; auch MinValue > MaxValue wirft
      nicht, damit "MinValue := 10; MaxValue := 100" in jeder Reihenfolge geht)
    * Ungueltige Eingabe wird beim Verlassen und mit Enter auf Value gesetzt
    * EditorEnabled = False: nur ueber Buttons, Tasten und Mausrad aenderbar
  - Buttons im Feld; gedrueckt halten wiederholt (400 ms, dann alle 50 ms).
    Der Takt kommt vom gemeinsamen Animator (kein eigener Timer).
  - Pfeiltasten (+/- Increment), Bild auf/ab (+/- 10 * Increment), Mausrad. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Animation, PPG.Render.Intf, PPG.Controls.Field;

type
  TPPGSpinStepEvent = procedure(Steps: Integer) of object;

  /// Wiederholung gehaltener Spin-Buttons: sofort ein Schritt, nach 400 ms
  /// alle 50 ms, nur solange die Maus auf dem gedrueckten Button steht.
  /// Der Takt kommt vom gemeinsamen Animator. Fuer SpinEdit und NumberEdit.
  TPPGSpinRepeater = class
  private
    FField: TPPGCustomField;
    FOnStep: TPPGSpinStepEvent;
    FAnim: TPPGAnimation;
    FId: Integer;
    FDirection: Integer;
    FStart: Cardinal;
    FDone: Integer;
    procedure Tick(Sender: TObject);
  public
    constructor Create(AField: TPPGCustomField; AOnStep: TPPGSpinStepEvent);
    destructor Destroy; override;
    /// Button Id gedrueckt: ein Schritt in Direction (+1/-1), dann Wiederholung.
    procedure Start(Id, Direction: Integer);
    procedure Stop;
    function Running: Boolean;
  end;

  TPPGCustomSpinEdit = class(TPPGCustomField)
  private
    FMinValue: Integer;
    FMaxValue: Integer;
    FIncrement: Integer;
    FEditorEnabled: Boolean;
    FReadOnly: Boolean;
    FRepeater: TPPGSpinRepeater;
    FValueCache: Integer; // Value ohne WM_GETTEXT (Paint sendet keine Nachrichten)
    function GetValue: Integer;
    procedure SetValue(const Value: Integer);
    procedure SetMinValue(const Value: Integer);
    procedure SetMaxValue(const Value: Integer);
    procedure SetIncrement(const Value: Integer);
    procedure SetEditorEnabled(const Value: Boolean);
    procedure SetSpinReadOnly(const Value: Boolean);
    function GetAutoSelect: Boolean;
    procedure SetAutoSelect(const Value: Boolean);
    procedure UpdateInnerReadOnly;
    procedure NormalizeForRange;
    procedure CMExit(var Message: TCMExit); message CM_EXIT;
  protected
    procedure Loaded; override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    function ButtonEnabled(Id: Integer): Boolean; override;
    procedure ButtonDown(Id: Integer); override;
    procedure ButtonUp(Id: Integer); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    procedure Change; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    function AccRole: Integer; override;
    function AccValue: string; override;
    /// Begrenzt einen Wert auf MinValue..MaxValue (MinValue = MaxValue: keine Grenze).
    function CheckValue(NewValue: Int64): Integer;
    /// Text auf den gueltigen Wert setzen (nach freier Eingabe).
    procedure NormalizeText;

    property AutoSelect: Boolean read GetAutoSelect write SetAutoSelect default True;
    property EditorEnabled: Boolean read FEditorEnabled write SetEditorEnabled default True;
    property Increment: Integer read FIncrement write SetIncrement default 1;
    property MaxValue: Integer read FMaxValue write SetMaxValue default 0;
    property MinValue: Integer read FMinValue write SetMinValue default 0;
    property ReadOnly: Boolean read FReadOnly write SetSpinReadOnly default False;
    property Value: Integer read GetValue write SetValue;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Aendert Value um Steps * Increment (wie ein Klick auf Auf/Ab).
    procedure Spin(Steps: Integer);
    /// True, solange ein Button gehalten wird (Wiederholung laeuft).
    function Repeating: Boolean;
  end;

  TPPGSpinEdit = class(TPPGCustomSpinEdit)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property UseSystemContextMenu;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    { wie TSpinEdit }
    property Align;
    property Alignment;
    property Anchors;
    property AutoSelect;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property EditorEnabled;
    property Enabled;
    property Font;
    property Increment;
    property MaxLength;
    property MaxValue;
    property MinValue;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Value;
    property Visible;
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
  end;

const
  PPGSpinButtonUp = 10;
  PPGSpinButtonDown = 11;

implementation

uses
  System.SysUtils, Winapi.oleacc;

type
  TEditAccess = class(TCustomEdit);
  TFieldAccess = class(TPPGCustomField);

const
  RepeatDelay = 400;   // ms bis zur ersten Wiederholung
  RepeatInterval = 50; // ms zwischen Wiederholungen
  PageSteps = 10;

{ TPPGSpinRepeater }

constructor TPPGSpinRepeater.Create(AField: TPPGCustomField; AOnStep: TPPGSpinStepEvent);
begin
  inherited Create;
  FField := AField;
  FOnStep := AOnStep;
  FAnim := TPPGAnimation.Create(nil);
  FAnim.OnStep := Tick;
end;

destructor TPPGSpinRepeater.Destroy;
begin
  if FAnim <> nil then
    FAnim.OnStep := nil;
  FreeAndNil(FAnim); // meldet sich selbst beim Animator ab
  inherited Destroy;
end;

procedure TPPGSpinRepeater.Start(Id, Direction: Integer);
begin
  FId := Id;
  FDirection := Direction;
  FStart := GetTickCount;
  FDone := 0;
  FOnStep(Direction);
  if not (csDesigning in FField.ComponentState) then
    FAnim.StartLoop(1000);
end;

procedure TPPGSpinRepeater.Stop;
begin
  FAnim.Stop;
  FId := 0;
end;

function TPPGSpinRepeater.Running: Boolean;
begin
  Result := (FAnim <> nil) and FAnim.Running;
end;

procedure TPPGSpinRepeater.Tick(Sender: TObject);
var
  Elapsed: Cardinal;
  Due: Integer;
  F: TFieldAccess;
begin
  F := TFieldAccess(FField);
  if (F.PressedButton < 0) or (FId = 0) then
  begin
    FAnim.Stop;
    Exit;
  end;
  Elapsed := GetTickCount - FStart;
  if Elapsed < RepeatDelay then
    Exit;
  Due := 1 + Integer((Elapsed - RepeatDelay) div RepeatInterval);
  // Nur solange die Maus auf dem gedrueckten Button steht (wie Windows)
  if F.HotButton <> F.PressedButton then
  begin
    FDone := Due;
    Exit;
  end;
  while FDone < Due do
  begin
    Inc(FDone);
    FOnStep(FDirection);
  end;
end;

{ TPPGCustomSpinEdit }

constructor TPPGCustomSpinEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FIncrement := 1;
  FEditorEnabled := True;
  FRepeater := TPPGSpinRepeater.Create(Self, Spin);
  Text := '0';
end;

destructor TPPGCustomSpinEdit.Destroy;
begin
  FreeAndNil(FRepeater);
  inherited Destroy;
end;

procedure TPPGCustomSpinEdit.Loaded;
begin
  inherited Loaded;
  NormalizeText; // Grenzen sind erst jetzt vollstaendig gelesen
end;

function TPPGCustomSpinEdit.CheckValue(NewValue: Int64): Integer;
begin
  if FMaxValue <> FMinValue then
  begin
    if NewValue < FMinValue then
      NewValue := FMinValue
    else if NewValue > FMaxValue then
      NewValue := FMaxValue;
  end;
  if NewValue < Low(Integer) then
    NewValue := Low(Integer)
  else if NewValue > High(Integer) then
    NewValue := High(Integer);
  Result := Integer(NewValue);
end;

function TPPGCustomSpinEdit.GetValue: Integer;
var
  V: Integer;
begin
  // Wie TSpinEdit: unlesbarer Text gilt als MinValue; immer im Bereich
  if not TryStrToInt(Trim(Text), V) then
    V := FMinValue;
  Result := CheckValue(V);
end;

procedure TPPGCustomSpinEdit.SetValue(const Value: Integer);
var
  S: string;
begin
  // Beim Laden roh uebernehmen: MinValue/MaxValue koennen spaeter kommen
  if csLoading in ComponentState then
    S := IntToStr(Value)
  else
    S := IntToStr(CheckValue(Value));
  if Text <> S then
    Text := S;
  FValueCache := GetValue;
end;

procedure TPPGCustomSpinEdit.NormalizeText;
var
  S: string;
begin
  S := IntToStr(GetValue);
  if Text <> S then
    Text := S;
  FValueCache := GetValue;
end;

procedure TPPGCustomSpinEdit.SetMinValue(const Value: Integer);
begin
  if FMinValue <> Value then
  begin
    FMinValue := Value;
    NormalizeForRange;
    Invalidate; // Buttons koennen (in)aktiv werden
  end;
end;

procedure TPPGCustomSpinEdit.SetMaxValue(const Value: Integer);
begin
  if FMaxValue <> Value then
  begin
    FMaxValue := Value;
    NormalizeForRange;
    Invalidate;
  end;
end;

procedure TPPGCustomSpinEdit.NormalizeForRange;
begin
  // Nur bei stimmigem Bereich: "MinValue := 10; MaxValue := 100" ist nach der
  // ersten Zuweisung voruebergehend verkehrt (Max noch 0) und darf den Wert
  // nicht veraendern - wie bei TSpinEdit, das den Text nie anpasst.
  if not (csLoading in ComponentState) and (FMinValue <= FMaxValue) then
    NormalizeText;
end;

procedure TPPGCustomSpinEdit.SetIncrement(const Value: Integer);
begin
  FIncrement := PPGCheckRange(Self, 'Increment', Value, 1, MaxInt);
end;

procedure TPPGCustomSpinEdit.SetEditorEnabled(const Value: Boolean);
begin
  if FEditorEnabled <> Value then
  begin
    FEditorEnabled := Value;
    UpdateInnerReadOnly;
  end;
end;

procedure TPPGCustomSpinEdit.SetSpinReadOnly(const Value: Boolean);
begin
  if FReadOnly <> Value then
  begin
    FReadOnly := Value;
    UpdateInnerReadOnly;
    Invalidate;
  end;
end;

procedure TPPGCustomSpinEdit.UpdateInnerReadOnly;
begin
  // Ohne Editor ist das Edit schreibgeschuetzt, die Buttons bleiben bedienbar
  TEditAccess(Inner).ReadOnly := FReadOnly or not FEditorEnabled;
end;

function TPPGCustomSpinEdit.GetAutoSelect: Boolean;
begin
  Result := TEditAccess(Inner).AutoSelect;
end;

procedure TPPGCustomSpinEdit.SetAutoSelect(const Value: Boolean);
begin
  TEditAccess(Inner).AutoSelect := Value;
end;

procedure TPPGCustomSpinEdit.Spin(Steps: Integer);
begin
  if FReadOnly or not Enabled or (Steps = 0) then
    Exit;
  SetValue(CheckValue(Int64(GetValue) + Int64(Steps) * FIncrement));
end;

procedure TPPGCustomSpinEdit.Change;
begin
  FValueCache := GetValue;
  inherited Change;
  Invalidate; // Buttons an den Grenzen (in)aktiv
end;

procedure TPPGCustomSpinEdit.CMExit(var Message: TCMExit);
begin
  inherited;
  NormalizeText;
end;

{ ---- Buttons ---- }

procedure TPPGCustomSpinEdit.GetButtons(var Buttons: TPPGFieldButtons);
var
  N: Integer;
begin
  inherited GetButtons(Buttons);
  // Rechts von aussen nach innen: [Text][Auf][Ab]
  N := Length(Buttons);
  SetLength(Buttons, N + 2);
  Buttons[N].Id := PPGSpinButtonDown;
  Buttons[N].Glyph := fgSpinDown;
  Buttons[N].ImageIndex := -1;
  Buttons[N].LeftSide := False;
  Buttons[N + 1].Id := PPGSpinButtonUp;
  Buttons[N + 1].Glyph := fgSpinUp;
  Buttons[N + 1].ImageIndex := -1;
  Buttons[N + 1].LeftSide := False;
end;

function TPPGCustomSpinEdit.ButtonEnabled(Id: Integer): Boolean;
var
  V: Integer;
begin
  Result := inherited ButtonEnabled(Id) and not FReadOnly;
  if not Result or (FMaxValue = FMinValue) then
    Exit;
  V := FValueCache;
  if Id = PPGSpinButtonUp then
    Result := V < FMaxValue
  else if Id = PPGSpinButtonDown then
    Result := V > FMinValue;
end;

procedure TPPGCustomSpinEdit.ButtonDown(Id: Integer);
begin
  if (Id <> PPGSpinButtonUp) and (Id <> PPGSpinButtonDown) then
    Exit;
  if Id = PPGSpinButtonUp then
    FRepeater.Start(Id, 1)
  else
    FRepeater.Start(Id, -1);
end;

procedure TPPGCustomSpinEdit.ButtonUp(Id: Integer);
begin
  FRepeater.Stop;
end;

function TPPGCustomSpinEdit.Repeating: Boolean;
begin
  Result := (FRepeater <> nil) and FRepeater.Running;
end;

{ ---- Tastatur und Mausrad ---- }

procedure TPPGCustomSpinEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  case Key of
    VK_UP: Spin(1);
    VK_DOWN: Spin(-1);
    VK_PRIOR: Spin(PageSteps);
    VK_NEXT: Spin(-PageSteps);
  else
    Exit;
  end;
  Key := 0;
end;

procedure TPPGCustomSpinEdit.FieldKeyPress(var Key: Char);
begin
  if Key = #13 then
  begin
    NormalizeText;
    Key := #0; // kein Signalton des einzeiligen Edits
    Exit;
  end;
  // Wie TSpinEdit: Ziffern, Vorzeichen und Steuerzeichen
  if not (CharInSet(Key, ['+', '-', '0'..'9']) or (Key < #32)) then
  begin
    Key := #0;
    MessageBeep(0);
  end;
end;

function TPPGCustomSpinEdit.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  Result := inherited DoMouseWheel(Shift, WheelDelta, MousePos);
  if Result or FReadOnly or not Enabled or (WheelDelta = 0) then
    Exit;
  if WheelDelta > 0 then
    Spin(1)
  else
    Spin(-1);
  Result := True;
end;

{ ---- Barrierefreiheit ---- }

function TPPGCustomSpinEdit.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_SPINBUTTON;
end;

function TPPGCustomSpinEdit.AccValue: string;
begin
  Result := IntToStr(GetValue);
end;

end.
