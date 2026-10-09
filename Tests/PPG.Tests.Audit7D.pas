unit PPG.Tests.Audit7D;

{ Audit-Paket 7D (Docs\Audit-Paket7-Plan.md): Regressionstests.
  Barrierefreiheit:
  #1 Validierungstext eines Felds als Beschreibung am inneren Edit, mit
     Ereignissen (DESCRIPTIONCHANGE, bei Fehler ALERT).
  #2 Rolle und Standardaktion aller Paletten-Controls: "Druecken" und die
     Button-Rolle nur bei Buttons, keine Standardaktion loest dort OnClick aus. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.oleacc,
  System.Classes, System.SysUtils, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  PPG.Types, PPG.Consts, PPG.Lang, PPG.Controls.Base, PPG.Controls.Field, PPG.Edit,
  PPG.Button, PPG.Gauge, PPG.Feedback, PPG.Labels, PPG.Validator,
  PPG.Tests.Controls, PPG.Tests.Audit5d;

type
  TAudit7DTests = class(TControlTestCase)
  private
    FClicks: Integer;
    FLinkClicks: Integer;
    procedure CountClick(Sender: TObject);
    procedure CountLink(Sender: TObject; const Link: string; LinkType: TSysLinkType);
    function AccOf(Wnd: HWND): IAccessible;
    function AccDescr(Wnd: HWND): string;
    function AccAction(const Acc: IAccessible): string;
    function AccRoleOf(const Acc: IAccessible): Integer;
  protected
    procedure SetUp; override;
  published
    procedure FieldValidationDescriptionOnInnerEdit;
    procedure FieldValidationRaisesEvents;
    procedure ValidatorMarksInnerEdit;
    procedure PaletteRolesAndDefaultActions;
    procedure ButtonKeepsPress;
    procedure ClickableTilesAndBadgesArePressable;
    procedure LinkLabelSingleLinkJumps;
  end;

implementation

type
  TWinAccess = class(TWinControl);
  TCtrlAccess = class(TControl);

var
  GEvents: TStringList;
  GEventWnd: HWND;

procedure WinEventProc(hWinEventHook: THandle; Event: DWORD; Wnd: HWND;
  idObject, idChild: Longint; idEventThread, dwmsEventTime: DWORD); stdcall;
begin
  if (GEvents <> nil) and (Wnd = GEventWnd) and (DWORD(idObject) = DWORD(OBJID_CLIENT)) then
    GEvents.Add(IntToStr(Event));
end;

{ TAudit7DTests }

procedure TAudit7DTests.SetUp;
begin
  inherited SetUp;
  FClicks := 0;
  FLinkClicks := 0;
end;

procedure TAudit7DTests.CountClick(Sender: TObject);
begin
  Inc(FClicks);
end;

procedure TAudit7DTests.CountLink(Sender: TObject; const Link: string; LinkType: TSysLinkType);
begin
  Inc(FLinkClicks);
end;

function TAudit7DTests.AccOf(Wnd: HWND): IAccessible;
begin
  Result := nil;
  CheckEquals(S_OK, AccessibleObjectFromWindow(Wnd, OBJID_CLIENT, IID_IAccessible, Result),
    'AccessibleObjectFromWindow');
  CheckTrue(Result <> nil);
end;

function TAudit7DTests.AccDescr(Wnd: HWND): string;
var
  W: WideString;
begin
  W := '';
  AccOf(Wnd).Get_accDescription(CHILDID_SELF, W);
  Result := W;
end;

function TAudit7DTests.AccAction(const Acc: IAccessible): string;
var
  W: WideString;
begin
  W := '';
  Acc.Get_accDefaultAction(CHILDID_SELF, W);
  Result := W;
end;

function TAudit7DTests.AccRoleOf(const Acc: IAccessible): Integer;
var
  V: OleVariant;
begin
  CheckEquals(S_OK, Acc.Get_accRole(CHILDID_SELF, V), 'accRole');
  Result := V;
end;

{ ---- 7d #1 ---- }

procedure TAudit7DTests.FieldValidationDescriptionOnInnerEdit;
var
  E: TPPGEdit;
  Inner: TWinControl;
begin
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.HandleNeeded;
  Inner := TWinControl(E.Controls[0]);
  Inner.HandleNeeded;
  E.ValidationHint := 'Pflichtfeld';
  E.ValidationState := pvsError;
  // Der Fokus steht im inneren Edit: dort muss der Screenreader den Fehler finden
  CheckEquals('Pflichtfeld', AccDescr(Inner.Handle), 'Fehler am inneren Edit');
  E.ValidationHint := 'Zu kurz';
  CheckEquals('Zu kurz', AccDescr(Inner.Handle), 'neuer Text');
  E.ValidationState := pvsNone;
  CheckEquals('', AccDescr(Inner.Handle), 'ohne Validierung leer');
  E.ValidationState := pvsWarning;
  CheckEquals('Zu kurz', AccDescr(Inner.Handle), 'Warnung');
  // Nach neuem Fensterhandle (inneres Edit und ganzes Feld) erneut gesetzt
  TWinAccess(Inner).RecreateWnd;
  Inner.HandleNeeded;
  CheckEquals('Zu kurz', AccDescr(Inner.Handle), 'nach RecreateWnd des Edits');
  TWinAccess(E).RecreateWnd;
  E.HandleNeeded;
  Inner.HandleNeeded;
  CheckEquals('Zu kurz', AccDescr(Inner.Handle), 'nach RecreateWnd des Felds');
end;

procedure TAudit7DTests.FieldValidationRaisesEvents;
var
  E: TPPGEdit;
  Inner: TWinControl;
  Hook: THandle;
  Alerts: Integer;
  I: Integer;
begin
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.HandleNeeded;
  Inner := TWinControl(E.Controls[0]);
  Inner.HandleNeeded;
  E.ValidationHint := 'Pflichtfeld';
  GEvents := TStringList.Create;
  try
    GEventWnd := Inner.Handle;
    Hook := SetWinEventHook(EVENT_SYSTEM_ALERT, EVENT_OBJECT_DESCRIPTIONCHANGE, 0,
      @WinEventProc, GetCurrentProcessId, 0, WINEVENT_OUTOFCONTEXT);
    CheckTrue(Hook <> 0, 'SetWinEventHook');
    try
      Application.ProcessMessages;
      GEvents.Clear;
      E.ValidationState := pvsError;
      Application.ProcessMessages;
      CheckTrue(GEvents.IndexOf(IntToStr(EVENT_OBJECT_DESCRIPTIONCHANGE)) >= 0,
        'DESCRIPTIONCHANGE am inneren Edit');
      CheckTrue(GEvents.IndexOf(IntToStr(EVENT_SYSTEM_ALERT)) >= 0, 'ALERT beim Fehler');
      // Nur der Wechsel auf Fehler alarmiert, nicht jede Textaenderung
      GEvents.Clear;
      E.ValidationHint := 'Zu kurz';
      Application.ProcessMessages;
      CheckTrue(GEvents.IndexOf(IntToStr(EVENT_OBJECT_DESCRIPTIONCHANGE)) >= 0,
        'DESCRIPTIONCHANGE bei neuem Text');
      Alerts := 0;
      for I := 0 to GEvents.Count - 1 do
        if GEvents[I] = IntToStr(EVENT_SYSTEM_ALERT) then
          Inc(Alerts);
      CheckEquals(0, Alerts, 'kein ALERT ohne Wechsel');
      GEvents.Clear;
      E.ValidationState := pvsWarning;
      Application.ProcessMessages;
      CheckEquals(-1, GEvents.IndexOf(IntToStr(EVENT_SYSTEM_ALERT)), 'kein ALERT bei Warnung');
      CheckTrue(GEvents.IndexOf(IntToStr(EVENT_OBJECT_DESCRIPTIONCHANGE)) >= 0,
        'DESCRIPTIONCHANGE bei Warnung');
    finally
      UnhookWinEvent(Hook);
    end;
  finally
    FreeAndNil(GEvents);
    GEventWnd := 0;
  end;
end;

procedure TAudit7DTests.ValidatorMarksInnerEdit;
var
  E: TPPGEdit;
  V: TPPGValidator;
  R: TPPGValidationRule;
begin
  E := TPPGEdit.Create(FForm);
  E.Parent := FForm;
  E.HandleNeeded;
  TWinControl(E.Controls[0]).HandleNeeded;
  V := TPPGValidator.Create(FForm);
  R := V.Rules.Add;
  R.Control := E;
  R.Kind := vrRequired;
  R.Message := 'Bitte ausfuellen';
  CheckFalse(V.Validate, 'leeres Pflichtfeld');
  CheckEquals('Bitte ausfuellen', AccDescr(TWinControl(E.Controls[0]).Handle),
    'Validator meldet den Fehler am inneren Edit');
end;

{ ---- 7d #2 ---- }

procedure TAudit7DTests.PaletteRolesAndDefaultActions;
var
  CC: TControlClass;
  C: TControl;
  Acc: IAccessible;
  Role: Integer;
  Act, Bad: string;
  Press: string;
begin
  FForm.SetBounds(0, 0, 900, 700);
  FForm.Show;
  Press := PPGStr(@SPPGAccPress);
  Bad := '';
  for CC in VisualClasses do
  begin
    if not CC.InheritsFrom(TPPGCustomControl) then
      Continue;
    C := CC.Create(FForm);
    try
      C.Parent := FForm;
      C.SetBounds(10, 10, 300, 200);
      TWinControl(C).HandleNeeded;
      Acc := AccOf(TWinControl(C).Handle);
      Role := AccRoleOf(Acc);
      Act := AccAction(Acc);
      // OnClick erst danach: KpiTile und Badge werden damit zum Button
      TCtrlAccess(C).OnClick := CountClick;
      FClicks := 0;
      if C is TPPGCustomButton then
      begin
        if Role <> ROLE_SYSTEM_PUSHBUTTON then
          Bad := Bad + #13#10 + CC.ClassName + ': Rolle ' + IntToStr(Role);
        if Act <> Press then
          Bad := Bad + #13#10 + CC.ClassName + ': Aktion ' + Act;
      end
      else
      begin
        if (Role = ROLE_SYSTEM_PUSHBUTTON) or (Role = ROLE_SYSTEM_CLIENT) then
          Bad := Bad + #13#10 + CC.ClassName + ': Rolle ' + IntToStr(Role);
        if Act = Press then
          Bad := Bad + #13#10 + CC.ClassName + ': Aktion ' + Act;
        if AccAction(Acc) = '' then
        begin
          // Ohne Standardaktion darf der Screenreader nichts ausloesen
          Acc.accDoDefaultAction(CHILDID_SELF);
          Application.ProcessMessages;
          if FClicks <> 0 then
            Bad := Bad + #13#10 + CC.ClassName + ': OnClick ohne Standardaktion';
        end;
      end;
      Acc := nil;
    finally
      C.Free;
    end;
    Application.ProcessMessages;
  end;
  CheckEquals('', Bad, 'Rolle/Standardaktion');
end;

procedure TAudit7DTests.ButtonKeepsPress;
var
  B: TPPGButton;
  Acc: IAccessible;
begin
  B := NewButton('Los');
  B.OnClick := CountClick;
  Acc := AccOf(B.Handle);
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, AccRoleOf(Acc));
  CheckEquals(PPGStr(@SPPGAccPress), AccAction(Acc));
  CheckEquals(S_OK, Acc.accDoDefaultAction(CHILDID_SELF));
  CheckEquals(0, FClicks, 'nicht im COM-Aufruf');
  Application.ProcessMessages;
  CheckEquals(1, FClicks, 'Druecken loest OnClick aus');
end;

procedure TAudit7DTests.ClickableTilesAndBadgesArePressable;
var
  K: TPPGKpiTile;
  B: TPPGBadge;
  Acc: IAccessible;
begin
  K := TPPGKpiTile.Create(FForm);
  K.Parent := FForm;
  Acc := AccOf(K.Handle);
  CheckEquals(ROLE_SYSTEM_STATICTEXT, AccRoleOf(Acc), 'Kachel ohne OnClick');
  CheckEquals('', AccAction(Acc), 'Kachel ohne OnClick: keine Aktion');
  K.OnClick := CountClick;
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, AccRoleOf(Acc), 'Kachel mit OnClick');
  CheckEquals(PPGStr(@SPPGAccPress), AccAction(Acc), 'Kachel mit OnClick');
  Acc.accDoDefaultAction(CHILDID_SELF);
  Application.ProcessMessages;
  CheckEquals(1, FClicks, 'Kachel gedrueckt');

  FClicks := 0;
  B := TPPGBadge.Create(FForm);
  B.Parent := FForm;
  B.Top := 100;
  Acc := AccOf(B.Handle);
  CheckEquals(ROLE_SYSTEM_STATICTEXT, AccRoleOf(Acc), 'Badge ohne OnClick');
  CheckEquals('', AccAction(Acc), 'Badge ohne OnClick: keine Aktion');
  B.OnClick := CountClick;
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, AccRoleOf(Acc), 'Badge mit OnClick');
  CheckEquals(PPGStr(@SPPGAccPress), AccAction(Acc), 'Badge mit OnClick');
  Acc.accDoDefaultAction(CHILDID_SELF);
  Application.ProcessMessages;
  CheckEquals(1, FClicks, 'Badge gedrueckt');
end;

procedure TAudit7DTests.LinkLabelSingleLinkJumps;
var
  L: TPPGLinkLabel;
  Acc: IAccessible;
begin
  L := TPPGLinkLabel.Create(FForm);
  L.Parent := FForm;
  L.Caption := 'Siehe <a href="x">Hilfe</a>';
  L.OnClick := CountClick;
  L.OnLinkClick := CountLink;
  Acc := AccOf(L.Handle);
  CheckEquals(ROLE_SYSTEM_LINK, AccRoleOf(Acc));
  CheckEquals(PPGStr(@SPPGAccJump), AccAction(Acc), 'wie die Link-Kinder');
  Acc.accDoDefaultAction(CHILDID_SELF);
  CheckEquals(0, FLinkClicks, 'nicht im COM-Aufruf');
  Application.ProcessMessages;
  CheckEquals(1, FLinkClicks, 'Link ausgeloest');
  CheckEquals(0, FClicks, 'kein OnClick');
  // Mehrere Links: der Text selbst hat keine Aktion, die Links sind Kinder
  L.Caption := '<a href="a">A</a> und <a href="b">B</a>';
  CheckEquals(ROLE_SYSTEM_STATICTEXT, AccRoleOf(Acc));
  CheckEquals('', AccAction(Acc));
end;

initialization
  RegisterTest('Audit7D', TAudit7DTests.Suite);

end.
