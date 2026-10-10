unit DemoShowPasswordEdit;

// Komponentenseite TPPGPasswordEdit (Gruppe "Eingabe"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// Kennwortfelds (Beispieltext auf der Buehne, Zusatzinfo im Protokoll ohne
// Klartext) und die beiden Praxisbeispiele (ExPasswordEditLogin,
// ExPasswordEditChange).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.PasswordEdit, DemoKit, DemoShowcase, ExPasswordEditLogin, ExPasswordEditChange;

type
  TDemoShowPasswordEditPage = class(TDemoComponentPage)
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure BuildExamples; override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Vcl.ExtCtrls, PPG.Controls.Field;

const
  StageText = 'Sommer2026';

function TDemoShowPasswordEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGPasswordEdit;
end;

procedure TDemoShowPasswordEditPage.SetupSubject(ASubject: TComponent);
var
  P: TPPGPasswordEdit;
begin
  inherited SetupSubject(ASubject);
  // Mit Beispieltext, damit das Auge sofort etwas aufdecken kann
  P := ASubject as TPPGPasswordEdit;
  P.Width := 280;
  P.TextHint := L('Kennwort eingeben');
  P.Text := StageText;
end;

procedure TDemoShowPasswordEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'PasswordChar') or SameText(AName, 'RevealMode') or
    SameText(AName, 'CapsLockWarning') or SameText(AName, 'MaxLength') or
    SameText(AName, 'ShowClearButton') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'TextHintVisibleOnFocus') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'ValidationState') or SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if SameText(AName, 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowPasswordEditPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if Subject is TPPGPasswordEdit then
  begin
    if AName = 'OnRevealChange' then
      Detail := Format('Revealed = %s', [BoolToStr(TPPGPasswordEdit(Subject).Revealed, True)])
    else if AName = 'OnChange' then
      // Nie den Klartext ins Protokoll schreiben, nur die Laenge
      Detail := L(Format('%d Zeichen (der Text selbst bleibt verborgen)',
        [Length(TPPGPasswordEdit(Subject).Text)]));
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowPasswordEditPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Anmeldung', 'ExPasswordEditLogin',
    'Eine Anmeldemaske: <b>Anmelden</b> ist erst frei, wenn Benutzer und Kennwort eingetragen '
    + 'sind. Das <b>Auge</b> zeigt das Kennwort nur, solange Sie es gedr{ue}ckt halten (rmPeek). '
    + 'Ein falsches Kennwort wird <b>gel{oe}scht</b> (Clear) und rot markiert (ValidationState, '
    + 'ValidationHint als Tooltip); nach drei Fehlversuchen ist gesperrt. Probieren Sie: einen '
    + 'Namen und ein falsches Kennwort mit Enter, dann <b>Sommer2026</b>. Mit Feststelltaste '
    + 'erscheint im Feld ein Hinweis.');
  TLoginBox.CreateBox(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Kennwort {ae}ndern', 'ExPasswordEditChange',
    'Einstellungen {>} Kennwort {ae}ndern: Das neue Kennwort wird <b>beim Tippen gepr{ue}ft</b> '
    + '(OnChange): unter 8 Zeichen rot, nur Buchstaben oder nur Ziffern gelb, gemischt gr{ue}n. '
    + 'Die Wiederholung muss passen. Das <b>Auge</b> schaltet um (rmToggle) und deckt '
    + '{ue}ber <b>OnRevealChange</b> auch die Wiederholung auf, die selbst kein Auge hat (rmHidden). '
    + 'Fahren Sie mit der Maus {ue}ber ein markiertes Feld, um den Hinweis zu lesen.');
  TChangePasswordBox.CreateBox(Own, V.Live, DemoStyles);
end;

procedure TDemoShowPasswordEditPage.SelfTest(Check: TDemoCheck);
var
  P: TPPGPasswordEdit;
  Host2: TPanel;
  Login: TLoginBox;
  Change: TChangePasswordBox;
  I: Integer;
  Logged: Boolean;
begin
  inherited SelfTest(Check);
  // Buehne: Revealed aus Code ohne Ereignis, rmHidden deckt zu, Text nicht in der DFM
  ResetSubject;
  P := TPPGPasswordEdit(Subject);
  P.Revealed := True;
  Logged := False;
  for I := 0 to EventList.Items.Count - 1 do
    if Pos('OnRevealChange', EventList.Items[I]) > 0 then
      Logged := True;
  Check('TPPGPasswordEdit: Revealed aus Code deckt auf, ohne OnRevealChange',
    P.Revealed and not Logged);
  Inspector.SetValueText('RevealMode', 'rmHidden');
  Check('TPPGPasswordEdit: RevealMode = rmHidden deckt wieder zu', not P.Revealed);
  Check('TPPGPasswordEdit: Klartext steht nicht in der DFM (Text stored False)',
    Pos(StageText, DfmMemo.Lines.Text) = 0);
  P.Text := 'abc';
  Check('TPPGPasswordEdit: OnChange protokolliert nur die L' + #$00E4 + 'nge, nicht den Text',
    (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('abc', EventList.Items[0]) = 0));
  P.Clear;
  Check('TPPGPasswordEdit: Clear leert das Feld', P.Text = '');
  ResetSubject;

  // Die Beispiele laufen auf einer unsichtbaren Flaeche, damit die Live-Ansicht
  // unveraendert bleibt
  Host2 := TPanel.Create(nil);
  try
    Host2.Visible := False;
    Host2.Parent := Stage;
    Host2.SetBounds(0, 0, 450, 260);

    // Praxisbeispiel 1: Anmeldung
    Login := TLoginBox.CreateBox(nil, Host2, DemoStyles);
    try
      Check('Beispiel Anmeldung: Anmelden ohne Eingaben gesperrt, Auge mit rmPeek',
        (not Login.LoginButton.Enabled) and (Login.PasswordEdit.RevealMode = rmPeek));
      Login.UserEdit.Text := 'm.mueller';
      Login.PasswordEdit.Text := 'falsch';
      Check('Beispiel Anmeldung: mit Benutzer und Kennwort frei', Login.LoginButton.Enabled);
      Login.LoginButton.Click;
      Check('Beispiel Anmeldung: falsches Kennwort geleert und rot markiert',
        (Login.PasswordEdit.Text = '') and (Login.PasswordEdit.ValidationState = pvsError) and
        (Pos('Noch 2', Login.PasswordEdit.ValidationHint) > 0) and (Login.Attempts = 1) and
        not Login.LoginButton.Enabled);
      Login.PasswordEdit.Text := 'x';
      Check('Beispiel Anmeldung: neues Tippen nimmt die Fehlermarke weg',
        Login.PasswordEdit.ValidationState = pvsNone);
      Login.PasswordEdit.Text := 'Sommer2026';
      Login.LoginButton.Click;
      Check('Beispiel Anmeldung: richtiges Kennwort meldet an (gr' + #$00FC + 'n)',
        Login.LoggedIn and (Login.PasswordEdit.ValidationState = pvsValid));
    finally
      Login.Free;
    end;
    Login := TLoginBox.CreateBox(nil, Host2, DemoStyles);
    try
      Login.UserEdit.Text := 'm.mueller';
      for I := 1 to TLoginBox.MaxAttempts do
      begin
        Login.PasswordEdit.Text := 'falsch';
        Login.LoginButton.Click;
      end;
      Check('Beispiel Anmeldung: nach drei Fehlversuchen gesperrt',
        (not Login.PasswordEdit.Enabled) and (not Login.LoginButton.Enabled) and
        not Login.LoggedIn);
    finally
      Login.Free;
    end;

    // Praxisbeispiel 2: Kennwort aendern
    Change := TChangePasswordBox.CreateBox(nil, Host2, DemoStyles);
    try
      Change.NewPassword.Text := 'abc';
      Check('Beispiel Kennwort: unter 8 Zeichen rot mit Hinweis',
        (Change.NewPassword.ValidationState = pvsError) and
        (Change.NewPassword.ValidationHint <> '') and not Change.SaveButton.Enabled);
      Change.NewPassword.Text := 'abcdefgh';
      Check('Beispiel Kennwort: nur Buchstaben gelb',
        Change.NewPassword.ValidationState = pvsWarning);
      Change.NewPassword.Text := 'abcdefg1';
      Change.RepeatPassword.Text := 'abcdefg2';
      Check('Beispiel Kennwort: gemischt gr' + #$00FC + 'n, abweichende Wiederholung rot, Setzen gesperrt',
        (Change.NewPassword.ValidationState = pvsValid) and
        (Change.RepeatPassword.ValidationState = pvsError) and not Change.SaveButton.Enabled);
      Change.RepeatPassword.Text := 'abcdefg1';
      Check('Beispiel Kennwort: passende Wiederholung gibt Setzen frei',
        (Change.RepeatPassword.ValidationState = pvsValid) and Change.SaveButton.Enabled);
      // Wie ein Klick auf das Auge: Revealed umschalten, dann OnRevealChange
      Change.NewPassword.Revealed := True;
      Change.NewPassword.OnRevealChange(Change.NewPassword);
      Check('Beispiel Kennwort: OnRevealChange deckt auch die Wiederholung auf',
        Change.RepeatPassword.Revealed and (Change.RepeatPassword.RevealMode = rmHidden));
      Change.SaveButton.Click;
      Check('Beispiel Kennwort: Setzen speichert und leert beide Felder, wieder verdeckt',
        (Change.SavedCount = 1) and (Change.NewPassword.Text = '') and
        (Change.RepeatPassword.Text = '') and not Change.NewPassword.Revealed and
        not Change.RepeatPassword.Revealed and not Change.SaveButton.Enabled);
    finally
      Change.Free;
    end;
  finally
    Host2.Free;
  end;
end;

initialization
  RegisterShowcasePage('TPPGPasswordEdit', TDemoShowPasswordEditPage);

end.
