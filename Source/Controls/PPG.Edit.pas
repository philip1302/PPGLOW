unit PPG.Edit;

{ TPPGEdit - einzeiliges Eingabefeld in der Optik des Presets.

  - Natives Edit ohne Rahmen im PPGlow-Rahmen (siehe PPG.Controls.Field)
  - TextHint auch ohne Themes, ValidationState (Rahmen/Fokuslinie in
    Signalfarbe, ValidationHint als Tooltip und fuer Screenreader)
  - ShowClearButton: Loesch-Button erscheint bei Text und Hover/Fokus
  - LeftButton/RightButton: Bild-Buttons im Feld (wie TButtonedEdit), optional
    mit DropDownMenu
  - Migration: Property-Namen von TEdit, eine DFM laesst sich per
    Suchen/Ersetzen (TEdit -> TPPGEdit) umstellen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.Menus,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Field;

type
  TPPGCustomEdit = class;

  /// Button links oder rechts im Feld (Bild aus Images des Felds).
  TPPGEditButton = class(TPersistent)
  private
    FEdit: TPPGCustomEdit;
    FVisible: Boolean;
    FEnabled: Boolean;
    FImageIndex: TPPGImageIndex;
    FDropDownMenu: TPopupMenu;
    procedure SetVisible(const Value: Boolean);
    procedure SetEnabled(const Value: Boolean);
    procedure SetImageIndex(const Value: TPPGImageIndex);
    procedure SetDropDownMenu(const Value: TPopupMenu);
  protected
    function GetOwner: TPersistent; override;
  public
    constructor Create(AEdit: TPPGCustomEdit);
    procedure Assign(Source: TPersistent); override;
  published
    property DropDownMenu: TPopupMenu read FDropDownMenu write SetDropDownMenu;
    property Enabled: Boolean read FEnabled write SetEnabled default True;
    property ImageIndex: TPPGImageIndex read FImageIndex write SetImageIndex default -1;
    property Visible: Boolean read FVisible write SetVisible default False;
  end;

  TPPGCustomEdit = class(TPPGCustomField)
  private
    FLeftButton: TPPGEditButton;
    FRightButton: TPPGEditButton;
    FOnLeftButtonClick: TNotifyEvent;
    FOnRightButtonClick: TNotifyEvent;
    function GetAutoSelect: Boolean;
    procedure SetAutoSelect(const Value: Boolean);
    function GetPasswordChar: Char;
    procedure SetPasswordChar(const Value: Char);
    function GetNumbersOnly: Boolean;
    procedure SetNumbersOnly(const Value: Boolean);
    procedure SetLeftButton(const Value: TPPGEditButton);
    procedure SetRightButton(const Value: TPPGEditButton);
    function EditButton(Id: Integer): TPPGEditButton;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure GetButtons(var Buttons: TPPGFieldButtons); override;
    function ButtonEnabled(Id: Integer): Boolean; override;
    procedure ButtonClick(Id: Integer); override;
    function AccRole: Integer; override;
    function AccValue: string; override;

    property AutoSelect: Boolean read GetAutoSelect write SetAutoSelect default True;
    property LeftButton: TPPGEditButton read FLeftButton write SetLeftButton;
    property NumbersOnly: Boolean read GetNumbersOnly write SetNumbersOnly default False;
    property PasswordChar: Char read GetPasswordChar write SetPasswordChar default #0;
    property RightButton: TPPGEditButton read FRightButton write SetRightButton;
    property OnLeftButtonClick: TNotifyEvent read FOnLeftButtonClick write FOnLeftButtonClick;
    property OnRightButtonClick: TNotifyEvent read FOnRightButtonClick write FOnRightButtonClick;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

  TPPGEdit = class(TPPGCustomEdit)
  published
    property RoundedCorners;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property Images;
    property LeftButton;
    property RightButton;
    property ShowClearButton;
    property TextHint;
    property UseSystemContextMenu;
    property TextHintVisibleOnFocus;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    { wie TEdit }
    property Align;
    property Alignment;
    property Anchors;
    property AutoSelect;
    property AutoSize default True;
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
    property MaxLength;
    property NumbersOnly;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property PopupMenu;
    property ReadOnly;
    property ReadOnlyStyle;
    property ShowHint;
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
    property OnLeftButtonClick;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnRightButtonClick;
    property OnStartDock;
    property OnStartDrag;
    // Audit 5d: VCL-Properties und -Ereignisse aus TControl/TWinControl
    property OnMouseActivate;
  end;

const
  PPGEditButtonLeft = 2;
  PPGEditButtonRight = 3;

implementation

uses
  System.SysUtils, Winapi.oleacc;

type
  TEditAccess = class(TCustomEdit);

{ TPPGEditButton }

constructor TPPGEditButton.Create(AEdit: TPPGCustomEdit);
begin
  inherited Create;
  FEdit := AEdit;
  FEnabled := True;
  FImageIndex := -1;
end;

function TPPGEditButton.GetOwner: TPersistent;
begin
  Result := FEdit;
end;

procedure TPPGEditButton.Assign(Source: TPersistent);
var
  S: TPPGEditButton;
begin
  if Source is TPPGEditButton then
  begin
    S := TPPGEditButton(Source);
    DropDownMenu := S.FDropDownMenu;
    Enabled := S.FEnabled;
    ImageIndex := S.FImageIndex;
    Visible := S.FVisible;
  end
  else
    inherited Assign(Source);
end;

procedure TPPGEditButton.SetVisible(const Value: Boolean);
begin
  if FVisible <> Value then
  begin
    FVisible := Value;
    FEdit.UpdateLayout;
  end;
end;

procedure TPPGEditButton.SetEnabled(const Value: Boolean);
begin
  if FEnabled <> Value then
  begin
    FEnabled := Value;
    FEdit.Invalidate;
  end;
end;

procedure TPPGEditButton.SetImageIndex(const Value: TPPGImageIndex);
begin
  if FImageIndex <> Value then
  begin
    FImageIndex := PPGCheckRange(Self, 'ImageIndex', Value, -1, MaxInt);
    FEdit.UpdateLayout;
  end;
end;

procedure TPPGEditButton.SetDropDownMenu(const Value: TPopupMenu);
begin
  if FDropDownMenu = Value then
    Exit;
  // Kein RemoveFreeNotification: das Menue kann auch am anderen Button haengen
  FDropDownMenu := Value;
  if Value <> nil then
    Value.FreeNotification(FEdit);
  FEdit.UpdateLayout;
end;

{ TPPGCustomEdit }

constructor TPPGCustomEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLeftButton := TPPGEditButton.Create(Self);
  FRightButton := TPPGEditButton.Create(Self);
end;

destructor TPPGCustomEdit.Destroy;
begin
  FreeAndNil(FLeftButton);
  FreeAndNil(FRightButton);
  inherited Destroy;
end;

procedure TPPGCustomEdit.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation <> opRemove then
    Exit;
  if (FLeftButton <> nil) and (AComponent = FLeftButton.FDropDownMenu) then
    FLeftButton.FDropDownMenu := nil;
  if (FRightButton <> nil) and (AComponent = FRightButton.FDropDownMenu) then
    FRightButton.FDropDownMenu := nil;
end;

function TPPGCustomEdit.EditButton(Id: Integer): TPPGEditButton;
begin
  case Id of
    PPGEditButtonLeft: Result := FLeftButton;
    PPGEditButtonRight: Result := FRightButton;
  else
    Result := nil;
  end;
end;

procedure TPPGCustomEdit.GetButtons(var Buttons: TPPGFieldButtons);

  procedure Add(B: TPPGEditButton; Id: Integer; Left: Boolean);
  var
    N: Integer;
  begin
    if (B = nil) or not B.Visible then
      Exit;
    N := Length(Buttons);
    SetLength(Buttons, N + 1);
    Buttons[N].Id := Id;
    Buttons[N].ImageIndex := B.ImageIndex;
    // Ohne Bild, aber mit Menue: Pfeil als Hinweis auf das Aufklappen
    if (B.ImageIndex < 0) and (B.DropDownMenu <> nil) then
      Buttons[N].Glyph := fgDropDown
    else
      Buttons[N].Glyph := fgNone;
    Buttons[N].LeftSide := Left;
  end;

begin
  inherited GetButtons(Buttons);
  Add(FLeftButton, PPGEditButtonLeft, True);
  Add(FRightButton, PPGEditButtonRight, False);
end;

function TPPGCustomEdit.ButtonEnabled(Id: Integer): Boolean;
var
  B: TPPGEditButton;
begin
  Result := inherited ButtonEnabled(Id);
  B := EditButton(Id);
  if B <> nil then
    Result := Result and B.Enabled;
end;

procedure TPPGCustomEdit.ButtonClick(Id: Integer);
var
  B: TPPGEditButton;
  R: TRect;
  P: TPoint;
begin
  B := EditButton(Id);
  if B = nil then
  begin
    inherited ButtonClick(Id);
    Exit;
  end;
  if (Id = PPGEditButtonLeft) and Assigned(FOnLeftButtonClick) then
    FOnLeftButtonClick(Self)
  else if (Id = PPGEditButtonRight) and Assigned(FOnRightButtonClick) then
    FOnRightButtonClick(Self);
  // Das Ereignis kann den Button entfernt oder das Feld zerstoert haben
  if (B.DropDownMenu <> nil) and HandleAllocated then
  begin
    R := ButtonRect(Id);
    if UseRightToLeftAlignment then
      P := ClientToScreen(Point(R.Right, R.Bottom))
    else
      P := ClientToScreen(Point(R.Left, R.Bottom));
    B.DropDownMenu.PopupComponent := Self;
    B.DropDownMenu.Popup(P.X, P.Y);
  end;
end;

function TPPGCustomEdit.GetAutoSelect: Boolean;
begin
  Result := TEditAccess(Inner).AutoSelect;
end;

procedure TPPGCustomEdit.SetAutoSelect(const Value: Boolean);
begin
  TEditAccess(Inner).AutoSelect := Value;
end;

function TPPGCustomEdit.GetPasswordChar: Char;
begin
  Result := TEditAccess(Inner).PasswordChar;
end;

procedure TPPGCustomEdit.SetPasswordChar(const Value: Char);
begin
  TEditAccess(Inner).PasswordChar := Value;
end;

function TPPGCustomEdit.GetNumbersOnly: Boolean;
begin
  Result := TEditAccess(Inner).NumbersOnly;
end;

procedure TPPGCustomEdit.SetNumbersOnly(const Value: Boolean);
begin
  TEditAccess(Inner).NumbersOnly := Value;
end;

procedure TPPGCustomEdit.SetLeftButton(const Value: TPPGEditButton);
begin
  FLeftButton.Assign(Value);
end;

procedure TPPGCustomEdit.SetRightButton(const Value: TPPGEditButton);
begin
  FRightButton.Assign(Value);
end;

function TPPGCustomEdit.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_GROUPING;
end;

function TPPGCustomEdit.AccValue: string;
begin
  // Kennwoerter nie an Screenreader oder andere Prozesse herausgeben
  if GetPasswordChar <> #0 then
    Result := ''
  else
    Result := Text;
end;

end.
