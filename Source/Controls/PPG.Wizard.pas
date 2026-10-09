unit PPG.Wizard;

{ TPPGWizard + TPPGWizardPage - Schritt-Assistent (Phase 11g).

  - Seiten wie beim TPPGPageControl: jede TPPGWizardPage mit diesem Parent ist
    ein Schritt (DFM-Reihenfolge = Schrittfolge, GetChildren). Nur die aktive
    Seite ist sichtbar, auch im Designer (csNoDesignVisible).
  - Schritt-Anzeige oben oder links (StepPosition): Kreise mit Nummer bzw.
    Haekchen, verbindende Linie, Titel = Caption der Seite. Seiten mit
    PageVisible = False werden uebersprungen und nicht angezeigt.
  - Leiste unten: Zurueck / Weiter (auf dem letzten Schritt: Fertig) /
    Abbrechen. Enter = Weiter (Default), Esc = Abbrechen, Mnemonics
    uebersetzbar (Alt+W/Alt+Z im Deutschen).
  - Ereignisse nur bei Anwenderaktionen (Buttons, Next/Back/Finish/Cancel als
    deren Gegenstueck): OnCanAdvance(Page, Allow) vor jedem Weiter/Fertig,
    OnChange, OnFinish, OnCancel. ActivePage aus Code: ohne Ereignisse.
  - Ohne OnFinish/OnCancel in einem modalen Formular: ModalResult mrOk bzw.
    mrCancel.
  - Klick auf einen erledigten Schritt geht dorthin zurueck; im Designer
    wechselt ein Klick auf einen Schritt die Seite.
  - Screenreader: Name "Schritt x von y: Titel", Seiten mit Rolle
    Eigenschaftsseite. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms,
  PPG.Types, PPG.Tokens, PPG.Render.Intf, PPG.Controls.Base, PPG.Controls.Container,
  PPG.Button;

type
  TPPGWizard = class;

  TPPGWizardPage = class(TPPGCustomContainer)
  private
    FDescription: string;
    FPageVisible: Boolean;
    FOnShow: TNotifyEvent;
    FOnHide: TNotifyEvent;
    function GetWizard: TPPGWizard;
    procedure SetWizard(const Value: TPPGWizard);
    function GetPageIndex: Integer;
    procedure SetPageIndex(const Value: Integer);
    procedure SetPageVisible(const Value: Boolean);
    procedure SetDescription(const Value: string);
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    function GetBackgroundColor: TColor; override;
    function GetChildBackground(Child: TControl; out ColorTop, ColorBottom: TColor): Boolean; override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function AccRole: Integer; override;
    function AccDescription: string; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Wizard: TPPGWizard read GetWizard write SetWizard;
  published
    property BorderWidth;
    property Caption;
    /// Kurzer Hinweis zum Schritt (Screenreader, Tooltip der Schritt-Anzeige).
    property Description: string read FDescription write SetDescription;
    property Constraints;
    property Enabled;
    property Font;
    property Height stored False;
    property Left stored False;
    property Padding;
    property PageIndex: Integer read GetPageIndex write SetPageIndex stored False;
    /// False = Schritt wird uebersprungen.
    property PageVisible: Boolean read FPageVisible write SetPageVisible default True;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Top stored False;
    property Width stored False;
    property OnContextPopup;
    property OnEnter;
    property OnExit;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnResize;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
  end;

  TPPGWizardStepPosition = (wspTop, wspLeft, wspNone);
  TPPGWizardCanAdvanceEvent = procedure(Sender: TObject; Page: TPPGWizardPage;
    var Allow: Boolean) of object;

  TPPGWizard = class(TPPGCustomContainer)
  private
    FPages: TList;
    FActivePage: TPPGWizardPage;
    FStepPosition: TPPGWizardStepPosition;
    FShowCancel: Boolean;
    FBackButton: TPPGButton;
    FNextButton: TPPGButton;
    FCancelButton: TPPGButton;
    FOnCanAdvance: TPPGWizardCanAdvanceEvent;
    FOnPageChanged: TNotifyEvent;
    FOnFinish: TNotifyEvent;
    FOnCancel: TNotifyEvent;
    procedure PaintDescription(const ACanvas: IPPGCanvas; const BarR: TRect; Color: TColor);
    function GetPage(Index: Integer): TPPGWizardPage;
    function GetPageCount: Integer;
    function GetActivePageIndex: Integer;
    procedure SetActivePageIndex(const Value: Integer);
    procedure SetActivePage(const Value: TPPGWizardPage);
    procedure SetStepPosition(const Value: TPPGWizardStepPosition);
    procedure SetShowCancel(const Value: Boolean);
    procedure InsertPage(Page: TPPGWizardPage);
    procedure RemovePage(Page: TPPGWizardPage);
    procedure MovePage(Page: TPPGWizardPage; NewIndex: Integer);
    procedure ChangeActivePage(Page: TPPGWizardPage);
    procedure BackClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure CMControlChange(var Message: TCMControlChange); message CM_CONTROLCHANGE;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    function HeaderSize: Integer;
    function BarHeight: Integer;
    function S(Value: Integer): Integer;
    /// Innenmasse ohne Fensterhandle (ClientWidth wuerde eines anfordern).
    function CW: Integer;
    function CH: Integer;
    function Colors(out Bg, Bar, Line, Text, Secondary, Accent, OnAccent: TColor): Boolean;
    procedure ModalClose(Result: TModalResult);
  protected
    procedure Loaded; override;
    procedure Resize; override;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure SetChildOrder(Child: TComponent; Order: Integer); override;
    procedure ShowControl(AControl: TControl); override;
    procedure DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect); override;
    function GetChildBackground(Child: TControl; out ColorTop, ColorBottom: TColor): Boolean; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure AppearanceUpdated; override;
    function AccRole: Integer; override;
    function AccName: string; override;
    /// Seite hat sich geaendert (Caption, PageVisible): Anzeige und Buttons.
    procedure PageChanged(Page: TPPGWizardPage);
    procedure UpdateButtons;
    procedure LayoutButtons;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    /// Naechste/vorige sichtbare Seite (nicht ringfoermig), nil = keine.
    function FindNextPage(CurPage: TPPGWizardPage; GoForward: Boolean): TPPGWizardPage;
    /// Wie die Buttons (mit Ereignissen). Next auf dem letzten Schritt = Finish.
    function Next: Boolean;
    function Back: Boolean;
    procedure Finish;
    procedure Cancel;
    /// Sichtbare Schritte und Nummer des aktiven (0-basiert, -1 = keiner).
    function StepCount: Integer;
    function StepIndex: Integer;
    function IsLastStep: Boolean;
    /// Lage des Kreises eines Schritts (Client-Koordinaten).
    function StepRect(Step: Integer): TRect;
    function StepAt(X, Y: Integer): Integer;
    property ActivePageIndex: Integer read GetActivePageIndex write SetActivePageIndex;
    property PageCount: Integer read GetPageCount;
    property Pages[Index: Integer]: TPPGWizardPage read GetPage;
    property BackButton: TPPGButton read FBackButton;
    property NextButton: TPPGButton read FNextButton;
    property CancelButton: TPPGButton read FCancelButton;
  published
    property ActivePage: TPPGWizardPage read FActivePage write SetActivePage;
    property StepPosition: TPPGWizardStepPosition read FStepPosition write SetStepPosition
      default wspTop;
    property ShowCancel: Boolean read FShowCancel write SetShowCancel default True;
    property Preset;
    property StyleManager;
    property Appearance;
    property HighContrastSupport;
    property Align;
    property Anchors;
    property BiDiMode;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property Visible;
    property Touch;
    property OnGesture;
    property OnCanAdvance: TPPGWizardCanAdvanceEvent read FOnCanAdvance write FOnCanAdvance;
    property OnChange: TNotifyEvent read FOnPageChanged write FOnPageChanged;
    property OnFinish: TNotifyEvent read FOnFinish write FOnFinish;
    property OnCancel: TNotifyEvent read FOnCancel write FOnCancel;
    property OnResize;
  end;

implementation

uses
  PPG.Lang,
  System.SysUtils, System.Math, Winapi.oleacc,
  PPG.Consts, PPG.Appearance, PPG.DpiUtils, PPG.VclStyles, PPG.IconFont, PPG.Render.Gdi;

{ TPPGWizardPage }

constructor TPPGWizardPage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csNoDesignVisible];
  ParentBackground := False;
  Align := alClient;
  Visible := False;
  FPageVisible := True;
end;

destructor TPPGWizardPage.Destroy;
begin
  if Parent is TPPGWizard then
    Parent := nil;
  inherited Destroy;
end;

function TPPGWizardPage.GetWizard: TPPGWizard;
begin
  if Parent is TPPGWizard then
    Result := TPPGWizard(Parent)
  else
    Result := nil;
end;

procedure TPPGWizardPage.SetWizard(const Value: TPPGWizard);
begin
  Parent := Value;
end;

function TPPGWizardPage.GetPageIndex: Integer;
begin
  if Wizard <> nil then
    Result := Wizard.FPages.IndexOf(Self)
  else
    Result := -1;
end;

procedure TPPGWizardPage.SetPageIndex(const Value: Integer);
begin
  if Wizard <> nil then
    Wizard.MovePage(Self, Value);
end;

procedure TPPGWizardPage.SetPageVisible(const Value: Boolean);
begin
  if FPageVisible <> Value then
  begin
    FPageVisible := Value;
    if Wizard <> nil then
      Wizard.PageChanged(Self);
  end;
end;

procedure TPPGWizardPage.SetDescription(const Value: string);
begin
  if FDescription = Value then
    Exit;
  FDescription := Value;
  if Parent <> nil then
    Parent.Invalidate;
end;

procedure TPPGWizardPage.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if Wizard <> nil then
    Wizard.PageChanged(Self);
end;

function TPPGWizardPage.GetBackgroundColor: TColor;
var
  Bg, Bar, Line, Txt, Sec, Acc, OnAcc: TColor;
begin
  if Wizard <> nil then
  begin
    Wizard.Colors(Bg, Bar, Line, Txt, Sec, Acc, OnAcc);
    Result := Bg;
  end
  else
    Result := GetContainerStyle(False).Color;
end;

function TPPGWizardPage.GetChildBackground(Child: TControl; out ColorTop,
  ColorBottom: TColor): Boolean;
begin
  ColorTop := GetBackgroundColor;
  ColorBottom := ColorTop;
  Result := True;
end;

procedure TPPGWizardPage.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
begin
  // Nur der Hintergrund (FillBackground)
end;

function TPPGWizardPage.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_PROPERTYPAGE;
end;

function TPPGWizardPage.AccDescription: string;
begin
  Result := FDescription;
end;

{ TPPGWizard }

constructor TPPGWizard.Create(AOwner: TComponent);

  function NewButton(const ACaption: string; AClick: TNotifyEvent): TPPGButton;
  begin
    Result := TPPGButton.Create(Self);
    Result.Parent := Self;
    Result.Caption := ACaption;
    Result.OnClick := AClick;
  end;

begin
  FPages := TList.Create;
  inherited Create(AOwner);
  ControlStyle := ControlStyle - [csAcceptsControls];
  Width := 480;
  Height := 320;
  FStepPosition := wspTop;
  FShowCancel := True;
  // Buttons gehoeren dem Assistenten: nicht in der DFM, nicht im Designer waehlbar
  FBackButton := NewButton(PPGStr(@SPPGWizBack), BackClick);
  FNextButton := NewButton(PPGStr(@SPPGWizNext), NextClick);
  FNextButton.Default := True;
  FCancelButton := NewButton(PPGStr(@SPPGDlgCancel), CancelClick);
  FCancelButton.Cancel := True;
  LayoutButtons;
  UpdateButtons;
end;

destructor TPPGWizard.Destroy;
begin
  inherited Destroy;
  FreeAndNil(FPages);
end;

function TPPGWizard.S(Value: Integer): Integer;
begin
  Result := PPGScale(Value, ScalePPI);
end;

function TPPGWizard.CW: Integer;
begin
  if HandleAllocated then
    Result := ClientWidth
  else
    Result := Width;
end;

function TPPGWizard.CH: Integer;
begin
  if HandleAllocated then
    Result := ClientHeight
  else
    Result := Height;
end;

function TPPGWizard.HeaderSize: Integer;
begin
  case FStepPosition of
    wspTop: Result := S(72);
    wspLeft: Result := S(200);
  else
    Result := 0;
  end;
end;

function TPPGWizard.BarHeight: Integer;
begin
  Result := S(56);
end;

function TPPGWizard.Colors(out Bg, Bar, Line, Text, Secondary, Accent, OnAccent: TColor): Boolean;
var
  T: TPPGTokens;
  St: TPPGSurfaceStyle;
begin
  T := Tokens;
  St := GetContainerStyle(False);
  if HighContrastSupport and PPGIsHighContrast then
  begin
    Bg := PPGColorToRGB(clWindow);
    Bar := PPGColorToRGB(clBtnFace);
    Text := PPGColorToRGB(clWindowText);
    Line := Text;
    Secondary := Text;
    Accent := PPGColorToRGB(clHighlight);
    OnAccent := PPGColorToRGB(clHighlightText);
    Exit(True);
  end;
  Bg := PPGColorToRGB(St.Color);
  Text := PPGColorToRGB(St.TextColor);
  Bar := PPGBlendColor(Bg, Text, 0.04);
  Line := PPGBlendColor(Bg, Text, 0.15);
  Secondary := PPGBlendColor(Text, Bg, 0.35);
  Accent := T.Accent;
  OnAccent := T.OnAccent;
  if UseVclStyle then
  begin
    Accent := PPGColorToRGB(St.GlowColor);
    OnAccent := Bg;
  end;
  Result := True;
end;

procedure TPPGWizard.Loaded;
begin
  inherited Loaded;
  if (FActivePage = nil) and (PageCount > 0) then
    ChangeActivePage(FindNextPage(nil, True));
  UpdateButtons;
end;

function TPPGWizard.GetPage(Index: Integer): TPPGWizardPage;
begin
  Result := TPPGWizardPage(FPages[Index]);
end;

function TPPGWizard.GetPageCount: Integer;
begin
  if FPages = nil then
    Result := 0
  else
    Result := FPages.Count;
end;

function TPPGWizard.GetActivePageIndex: Integer;
begin
  if FActivePage = nil then
    Result := -1
  else
    Result := FPages.IndexOf(FActivePage);
end;

procedure TPPGWizard.SetActivePageIndex(const Value: Integer);
begin
  if (Value >= 0) and (Value < PageCount) then
    SetActivePage(Pages[Value])
  else
    SetActivePage(nil);
end;

procedure TPPGWizard.SetActivePage(const Value: TPPGWizardPage);
begin
  // Aus Code: ohne Ereignisse
  if (Value <> nil) and (Value.Wizard <> Self) then
    Exit;
  ChangeActivePage(Value);
end;

procedure TPPGWizard.SetStepPosition(const Value: TPPGWizardStepPosition);
begin
  if FStepPosition = Value then
    Exit;
  FStepPosition := Value;
  Realign;
  LayoutButtons;
  Invalidate;
end;

procedure TPPGWizard.SetShowCancel(const Value: Boolean);
begin
  FShowCancel := Value;
  UpdateButtons;
  LayoutButtons;
end;

procedure TPPGWizard.CMControlChange(var Message: TCMControlChange);
begin
  inherited;
  if Message.Control is TPPGWizardPage then
    if Message.Inserting then
      InsertPage(TPPGWizardPage(Message.Control))
    else
      RemovePage(TPPGWizardPage(Message.Control));
end;

procedure TPPGWizard.InsertPage(Page: TPPGWizardPage);
begin
  if FPages.IndexOf(Page) >= 0 then
    Exit;
  FPages.Add(Page);
  if (csLoading in ComponentState) or (csReading in Page.ComponentState) then
    Exit;
  if FActivePage = nil then
    ChangeActivePage(Page);
  UpdateButtons;
  Invalidate;
end;

procedure TPPGWizard.RemovePage(Page: TPPGWizardPage);
var
  Next: TPPGWizardPage;
begin
  if FPages.IndexOf(Page) < 0 then
    Exit;
  if csDestroying in ComponentState then
  begin
    FPages.Remove(Page);
    if FActivePage = Page then
      FActivePage := nil;
    Exit;
  end;
  Next := nil;
  if FActivePage = Page then
  begin
    Next := FindNextPage(Page, True);
    if Next = nil then
      Next := FindNextPage(Page, False);
  end;
  FPages.Remove(Page);
  if FActivePage = Page then
  begin
    FActivePage := nil;
    ChangeActivePage(Next);
  end;
  UpdateButtons;
  Invalidate;
end;

procedure TPPGWizard.MovePage(Page: TPPGWizardPage; NewIndex: Integer);
var
  Cur: Integer;
begin
  Cur := FPages.IndexOf(Page);
  if Cur < 0 then
    Exit;
  NewIndex := EnsureRange(NewIndex, 0, FPages.Count - 1);
  if NewIndex = Cur then
    Exit;
  FPages.Move(Cur, NewIndex);
  UpdateButtons;
  Invalidate;
end;

procedure TPPGWizard.PageChanged(Page: TPPGWizardPage);
begin
  if csLoading in ComponentState then
    Exit;
  UpdateButtons;
  Invalidate;
end;

procedure TPPGWizard.ChangeActivePage(Page: TPPGWizardPage);
var
  Old: TPPGWizardPage;
  Form: TCustomForm;
  FocusInOld: Boolean;
begin
  if Page = FActivePage then
    Exit;
  Old := FActivePage;
  Form := GetParentForm(Self);
  FocusInOld := (Old <> nil) and (Form <> nil) and (Form.ActiveControl <> nil) and
    Old.ContainsControl(Form.ActiveControl) and not (csLoading in ComponentState);
  if Page <> nil then
  begin
    Page.BringToFront;
    Page.Visible := True;
  end;
  FActivePage := Page;
  if Old <> nil then
    Old.Visible := False;
  if FocusInOld then
  begin
    if (Page <> nil) and Page.CanFocus then
      Page.SelectFirst;
    if ((Page = nil) or not Page.ContainsControl(Form.ActiveControl)) and
      FNextButton.CanFocus then
      FNextButton.SetFocus;
  end;
  if not (csLoading in ComponentState) then
  begin
    if (Old <> nil) and Assigned(Old.FOnHide) then
      Old.FOnHide(Old);
    if (Page <> nil) and Assigned(Page.FOnShow) then
      Page.FOnShow(Page);
  end;
  UpdateButtons;
  Invalidate;
  if HandleAllocated then
    NotifyAccessibility(EVENT_OBJECT_NAMECHANGE);
end;

function TPPGWizard.FindNextPage(CurPage: TPPGWizardPage; GoForward: Boolean): TPPGWizardPage;
var
  I, Start: Integer;
begin
  Result := nil;
  Start := FPages.IndexOf(CurPage);
  if GoForward then
  begin
    for I := Start + 1 to FPages.Count - 1 do
      if Pages[I].PageVisible then
        Exit(Pages[I]);
  end
  else
  begin
    if Start < 0 then
      Start := FPages.Count;
    for I := Start - 1 downto 0 do
      if Pages[I].PageVisible then
        Exit(Pages[I]);
  end;
end;

function TPPGWizard.StepCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to PageCount - 1 do
    if Pages[I].PageVisible then
      Inc(Result);
end;

function TPPGWizard.StepIndex: Integer;
var
  I: Integer;
begin
  Result := -1;
  if FActivePage = nil then
    Exit;
  for I := 0 to PageCount - 1 do
  begin
    if Pages[I].PageVisible then
      Inc(Result);
    if Pages[I] = FActivePage then
      Exit;
  end;
end;

function TPPGWizard.IsLastStep: Boolean;
begin
  Result := (FActivePage <> nil) and (FindNextPage(FActivePage, True) = nil);
end;

procedure TPPGWizard.UpdateButtons;
begin
  if FBackButton = nil then
    Exit;
  FBackButton.Enabled := (FActivePage <> nil) and (FindNextPage(FActivePage, False) <> nil);
  if IsLastStep then
    FNextButton.Caption := PPGStr(@SPPGWizFinish)
  else
    FNextButton.Caption := PPGStr(@SPPGWizNext);
  FNextButton.Enabled := FActivePage <> nil;
  FCancelButton.Visible := FShowCancel;
  FBackButton.Caption := PPGStr(@SPPGWizBack);
  FCancelButton.Caption := PPGStr(@SPPGDlgCancel);
end;

procedure TPPGWizard.LayoutButtons;
var
  W, H, X, Y, Gap, I: Integer;
  B: array[0..2] of TPPGButton;
begin
  if FBackButton = nil then
    Exit;
  W := S(100);
  H := S(32);
  Gap := S(8);
  Y := CH - BarHeight + (BarHeight - H) div 2;
  X := CW - S(12);
  B[0] := FCancelButton;
  B[1] := FNextButton;
  B[2] := FBackButton;
  for I := 0 to 2 do
  begin
    if not B[I].Visible then
      Continue;
    Dec(X, W);
    if UseRightToLeftAlignment then
      B[I].SetBounds(CW - X - W, Y, W, H)
    else
      B[I].SetBounds(X, Y, W, H);
    Dec(X, Gap);
  end;
  // Tab-Reihenfolge: Zurueck, Weiter, Abbrechen
  FBackButton.TabOrder := 0;
  FNextButton.TabOrder := 1;
  FCancelButton.TabOrder := 2;
end;

procedure TPPGWizard.Resize;
begin
  inherited Resize;
  LayoutButtons;
end;

procedure TPPGWizard.AppearanceUpdated;
var
  I: Integer;
  B: TPPGButton;
begin
  inherited AppearanceUpdated;
  // Buttons folgen dem Preset des Assistenten
  for I := 0 to 2 do
  begin
    case I of
      0: B := FBackButton;
      1: B := FNextButton;
    else
      B := FCancelButton;
    end;
    if B = nil then
      Continue;
    if B.StyleManager <> StyleManager then
      B.StyleManager := StyleManager;
    if (StyleManager = nil) and (B.Preset <> Preset) then
      B.Preset := Preset;
  end;
end;

procedure TPPGWizard.AdjustClientRect(var Rect: TRect);
begin
  inherited AdjustClientRect(Rect);
  Dec(Rect.Bottom, BarHeight);
  case FStepPosition of
    wspTop: Inc(Rect.Top, HeaderSize);
    wspLeft:
      if UseRightToLeftAlignment then
        Dec(Rect.Right, HeaderSize)
      else
        Inc(Rect.Left, HeaderSize);
  end;
end;

function TPPGWizard.StepRect(Step: Integer): TRect;
var
  N, D, CX, CY, Span: Integer;
begin
  N := StepCount;
  D := S(28);
  Result := Rect(0, 0, 0, 0);
  if (N = 0) or (Step < 0) or (Step >= N) or (FStepPosition = wspNone) then
    Exit;
  if FStepPosition = wspTop then
  begin
    // Gleichmaessig ueber die Breite verteilt
    Span := CW div N;
    CX := Span * Step + Span div 2;
    if UseRightToLeftAlignment then
      CX := CW - CX;
    CY := S(22);
  end
  else
  begin
    CX := S(28);
    if UseRightToLeftAlignment then
      CX := CW - CX;
    CY := S(28) + Step * S(48);
  end;
  Result := Rect(CX - D div 2, CY - D div 2, CX + D div 2, CY + D div 2);
end;

function TPPGWizard.StepAt(X, Y: Integer): Integer;
var
  I: Integer;
  R: TRect;
begin
  Result := -1;
  for I := 0 to StepCount - 1 do
  begin
    R := StepRect(I);
    if FStepPosition = wspTop then
      R.Bottom := R.Bottom + S(24) // Titel unter dem Kreis
    else if UseRightToLeftAlignment then
      R.Left := R.Left - S(150)
    else
      R.Right := R.Right + S(150);
    if PtInRect(R, Point(X, Y)) then
      Exit(I);
  end;
end;

procedure TPPGWizard.PaintDescription(const ACanvas: IPPGCanvas; const BarR: TRect; Color: TColor);
var
  TR: TRect;
  B: TPPGButton;
  Edge: Integer;
  RTL: Boolean;
begin
  // Platz neben den Buttons (RTL: rechts von ihnen)
  RTL := UseRightToLeftAlignment;
  if RTL then
    Edge := BarR.Left
  else
    Edge := BarR.Right;
  for B in [FBackButton, FNextButton, FCancelButton] do
    if (B <> nil) and B.Visible then
    begin
      if RTL then
        Edge := Max(Edge, B.Left + B.Width)
      else
        Edge := Min(Edge, B.Left);
    end;
  if RTL then
    TR := Rect(Edge + S(16), BarR.Top, BarR.Right - S(16), BarR.Bottom)
  else
    TR := Rect(BarR.Left + S(16), BarR.Top, Edge - S(16), BarR.Bottom);
  if TR.Right <= TR.Left then
    Exit;
  ACanvas.DrawText(TR, FActivePage.Description, Font, Color,
    DrawTextBiDiModeFlags(DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX));
end;

procedure TPPGWizard.DoPaint(const ACanvas: IPPGCanvas; const ClientR: TRect);
var
  Bg, Bar, Line, Txt, Sec, Acc, OnAcc, Fill, NumC, TitleC: TColor;
  I, Step, Cur, N: Integer;
  R, Prev, TR: TRect;
  Pts: array[0..1] of TPoint;
  F: TFont;
  Title: string;
begin
  Colors(Bg, Bar, Line, Txt, Sec, Acc, OnAcc);
  ACanvas.FillRoundRect(ClientR, 0, Bg, 255);
  // Leiste unten mit Trennlinie
  R := Rect(ClientR.Left, ClientR.Bottom - BarHeight, ClientR.Right, ClientR.Bottom);
  ACanvas.FillRoundRect(R, 0, Bar, 255);
  ACanvas.FillRoundRect(Rect(R.Left, R.Top, R.Right, R.Top + Max(1, S(1))), 0, Line, 255);
  // Audit 5b: Beschreibung der aktiven Seite links in der Leiste
  if (FActivePage <> nil) and (FActivePage.Description <> '') then
    PaintDescription(ACanvas, R, Sec);
  if FStepPosition = wspNone then
    Exit;
  // Trennlinie zur Seite
  if FStepPosition = wspTop then
    ACanvas.FillRoundRect(Rect(0, HeaderSize - Max(1, S(1)), CW, HeaderSize), 0, Line, 255)
  else if UseRightToLeftAlignment then
    ACanvas.FillRoundRect(Rect(CW - HeaderSize, 0, CW - HeaderSize + Max(1, S(1)),
      CH - BarHeight), 0, Line, 255)
  else
    ACanvas.FillRoundRect(Rect(HeaderSize - Max(1, S(1)), 0, HeaderSize,
      CH - BarHeight), 0, Line, 255);
  N := StepCount;
  Cur := StepIndex;
  F := TFont.Create;
  try
    F.Assign(Font);
    Step := -1;
    for I := 0 to PageCount - 1 do
    begin
      if not Pages[I].PageVisible then
        Continue;
      Inc(Step);
      R := StepRect(Step);
      // Verbindungslinie zum vorigen Schritt
      if Step > 0 then
      begin
        Prev := StepRect(Step - 1);
        if FStepPosition = wspTop then
        begin
          Pts[0] := Point(Min(Prev.Right, R.Right) + S(6), (R.Top + R.Bottom) div 2);
          Pts[1] := Point(Max(Prev.Left, R.Left) - S(6), (R.Top + R.Bottom) div 2);
          if UseRightToLeftAlignment then
          begin
            Pts[0].X := R.Right + S(6);
            Pts[1].X := Prev.Left - S(6);
          end;
        end
        else
        begin
          Pts[0] := Point((R.Left + R.Right) div 2, Prev.Bottom + S(4));
          Pts[1] := Point((R.Left + R.Right) div 2, R.Top - S(4));
        end;
        if Step <= Cur then
          ACanvas.DrawPolyline(Pts, Max(1, S(2)), Acc, 255)
        else
          ACanvas.DrawPolyline(Pts, Max(1, S(1)), Line, 255);
      end;
      // Kreis: erledigt = Haekchen, aktiv = gefuellt, spaeter = Umriss
      if Step <= Cur then
      begin
        Fill := Acc;
        ACanvas.FillEllipse(R, Fill, 255);
        NumC := OnAcc;
      end
      else
      begin
        ACanvas.FillEllipse(R, Bg, 255);
        ACanvas.FrameRoundRect(R, (R.Right - R.Left) div 2, Max(1, S(1)), Line, 255);
        NumC := Sec;
      end;
      if Step < Cur then
      begin
        if not PPGDrawIcon(ACanvas, R, igCheckMark, NumC, S(14)) then
        begin
          F.Style := [fsBold];
          ACanvas.DrawText(R, 'v', F, NumC, DT_CENTER or DT_VCENTER or DT_SINGLELINE);
        end;
      end
      else
      begin
        F.Style := [fsBold];
        ACanvas.DrawText(R, IntToStr(Step + 1), F, NumC,
          DT_CENTER or DT_VCENTER or DT_SINGLELINE);
      end;
      // Titel
      Title := Pages[I].Caption;
      if Step = Cur then
      begin
        F.Style := [fsBold];
        TitleC := Txt;
      end
      else
      begin
        F.Style := [];
        TitleC := Sec;
      end;
      if not Enabled then
        TitleC := Sec;
      if FStepPosition = wspTop then
      begin
        TR := Rect((R.Left + R.Right) div 2 - CW div (2 * Max(N, 1)), R.Bottom + S(4),
          (R.Left + R.Right) div 2 + CW div (2 * Max(N, 1)), R.Bottom + S(24));
        ACanvas.DrawText(TR, Title, F, TitleC,
          DT_CENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
      end
      else if UseRightToLeftAlignment then
      begin
        TR := Rect(CW - HeaderSize + S(8), R.Top, R.Left - S(10), R.Bottom);
        ACanvas.DrawText(TR, Title, F, TitleC,
          DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
      end
      else
      begin
        TR := Rect(R.Right + S(10), R.Top, HeaderSize - S(8), R.Bottom);
        ACanvas.DrawText(TR, Title, F, TitleC,
          DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
      end;
    end;
  finally
    F.Free;
  end;
end;

function TPPGWizard.GetChildBackground(Child: TControl; out ColorTop,
  ColorBottom: TColor): Boolean;
var
  Bg, Bar, Line, Txt, Sec, Acc, OnAcc: TColor;
begin
  Colors(Bg, Bar, Line, Txt, Sec, Acc, OnAcc);
  if (Child = FBackButton) or (Child = FNextButton) or (Child = FCancelButton) then
    ColorTop := Bar
  else
    ColorTop := Bg;
  ColorBottom := ColorTop;
  Result := True;
end;

procedure TPPGWizard.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  // Im Designer: Klick auf einen Schritt wechselt die Seite
  if StepAt(Message.XPos, Message.YPos) >= 0 then
    Message.Result := 1
  else
    inherited;
end;

procedure TPPGWizard.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Step, I, N: Integer;
  Target: TPPGWizardPage;
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button <> mbLeft then
    Exit;
  Step := StepAt(X, Y);
  if Step < 0 then
    Exit;
  Target := nil;
  N := -1;
  for I := 0 to PageCount - 1 do
    if Pages[I].PageVisible then
    begin
      Inc(N);
      if N = Step then
      begin
        Target := Pages[I];
        Break;
      end;
    end;
  if Target = nil then
    Exit;
  if csDesigning in ComponentState then
    SetActivePage(Target)
  else if (Step < StepIndex) and Enabled then
  begin
    // Zurueck zu einem erledigten Schritt (wie Zurueck, ohne Pruefung)
    ChangeActivePage(Target);
    if Assigned(FOnPageChanged) then
      FOnPageChanged(Self);
  end;
end;

procedure TPPGWizard.BackClick(Sender: TObject);
begin
  Back;
end;

procedure TPPGWizard.NextClick(Sender: TObject);
begin
  Next;
end;

procedure TPPGWizard.CancelClick(Sender: TObject);
begin
  Cancel;
end;

function TPPGWizard.Next: Boolean;
var
  Allow: Boolean;
  P: TPPGWizardPage;
begin
  Result := False;
  if FActivePage = nil then
    Exit;
  Allow := True;
  if Assigned(FOnCanAdvance) then
    FOnCanAdvance(Self, FActivePage, Allow);
  if not Allow then
    Exit;
  P := FindNextPage(FActivePage, True);
  if P = nil then
  begin
    Finish;
    Exit(True);
  end;
  ChangeActivePage(P);
  if Assigned(FOnPageChanged) then
    FOnPageChanged(Self);
  Result := True;
end;

function TPPGWizard.Back: Boolean;
var
  P: TPPGWizardPage;
begin
  Result := False;
  // Ohne aktive Seite lieferte FindNextPage(nil, False) die letzte Seite
  if FActivePage = nil then
    Exit;
  P := FindNextPage(FActivePage, False);
  if P = nil then
    Exit;
  ChangeActivePage(P);
  if Assigned(FOnPageChanged) then
    FOnPageChanged(Self);
  Result := True;
end;

procedure TPPGWizard.ModalClose(Result: TModalResult);
var
  F: TCustomForm;
begin
  F := GetParentForm(Self);
  if (F <> nil) and (fsModal in F.FormState) then
    F.ModalResult := Result;
end;

procedure TPPGWizard.Finish;
begin
  if Assigned(FOnFinish) then
    FOnFinish(Self)
  else
    ModalClose(mrOk);
end;

procedure TPPGWizard.Cancel;
begin
  if Assigned(FOnCancel) then
    FOnCancel(Self)
  else
    ModalClose(mrCancel);
end;

procedure TPPGWizard.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  I: Integer;
begin
  // Seiten in Schrittfolge (die Buttons gehoeren dem Assistenten)
  for I := 0 to FPages.Count - 1 do
    Proc(TComponent(FPages[I]));
end;

procedure TPPGWizard.SetChildOrder(Child: TComponent; Order: Integer);
begin
  if Child is TPPGWizardPage then
    TPPGWizardPage(Child).PageIndex := Order
  else
    inherited SetChildOrder(Child, Order);
end;

procedure TPPGWizard.ShowControl(AControl: TControl);
begin
  if (AControl is TPPGWizardPage) and (TPPGWizardPage(AControl).Wizard = Self) then
    SetActivePage(TPPGWizardPage(AControl));
  inherited ShowControl(AControl);
end;

function TPPGWizard.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_GROUPING;
end;

function TPPGWizard.AccName: string;
begin
  if FActivePage = nil then
    Result := Name
  else
    Result := Format(PPGStr(@SPPGWizStep), [StepIndex + 1, StepCount, FActivePage.Caption]);
end;

end.
