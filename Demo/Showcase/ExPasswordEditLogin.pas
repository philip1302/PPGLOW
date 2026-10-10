unit ExPasswordEditLogin;

// Praxisbeispiel 1 zu TPPGPasswordEdit (Demo-Seite "Eingabe > TPPGPasswordEdit"):
// Anmeldemaske mit Benutzer und Kennwort. Das Auge deckt nur auf, solange es
// gedrueckt ist (rmPeek); ein falsches Kennwort wird geloescht und rot
// markiert (Clear, ValidationState, ValidationHint), nach drei Fehlversuchen
// ist die Anmeldung gesperrt.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.Edit, PPG.PasswordEdit, PPG.Button;

type
  /// Anmeldemaske: Anmelden geht erst mit Benutzer und Kennwort,
  /// Enter im Kennwortfeld meldet an, drei Fehlversuche sperren.
  TLoginBox = class(TComponent)
  private
    FUser: TPPGEdit;
    FPassword: TPPGPasswordEdit;
    FLogin: TPPGButton;
    FStatus: TPPGLabel;
    FAttempts: Integer;
    FLoggedIn: Boolean;
    function NewLabel(AParent: TWinControl; Y: Integer; const ACaption: string): TPPGLabel;
    procedure InputChange(Sender: TObject);
    procedure PasswordKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure LoginClick(Sender: TObject);
  public
    const
      MaxAttempts = 3;
    constructor CreateBox(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property UserEdit: TPPGEdit read FUser;
    property PasswordEdit: TPPGPasswordEdit read FPassword;
    property LoginButton: TPPGButton read FLogin;
    property Attempts: Integer read FAttempts;
    property LoggedIn: Boolean read FLoggedIn;
  end;

/// Nur fuer das Beispiel; im echten Programm prueft der Server.
function CheckCredentials(const AUser, APassword: string): Boolean;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function CheckCredentials(const AUser, APassword: string): Boolean;
begin
  Result := (AUser <> '') and (APassword = 'Sommer2026');
end;

function TLoginBox.NewLabel(AParent: TWinControl; Y: Integer; const ACaption: string): TPPGLabel;
begin
  Result := TPPGLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(16, Y, 300, 20);
  Result.Caption := ACaption;
end;

constructor TLoginBox.CreateBox(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  FUser := TPPGEdit.Create(Self);
  FUser.Parent := AParent;
  FUser.SetBounds(16, 40, 300, 32);
  FUser.TextHint := 'z. B. m.mueller';
  FUser.StyleManager := AStyles;
  FUser.OnChange := InputChange;
  NewLabel(AParent, 16, '&Benutzer:').FocusControl := FUser;

  // Kennwort: Auge nur solange gedrueckt (rmPeek), Hinweis bei
  // Feststelltaste (CapsLockWarning), Enter meldet an
  FPassword := TPPGPasswordEdit.Create(Self);
  FPassword.Parent := AParent;
  FPassword.SetBounds(16, 108, 300, 32);
  FPassword.TextHint := 'Kennwort';
  FPassword.RevealMode := rmPeek;
  FPassword.CapsLockWarning := True;
  FPassword.StyleManager := AStyles;
  FPassword.OnChange := InputChange;
  FPassword.OnKeyDown := PasswordKeyDown;
  NewLabel(AParent, 84, '&Kennwort:').FocusControl := FPassword;

  FLogin := TPPGButton.Create(Self);
  FLogin.Parent := AParent;
  FLogin.SetBounds(16, 156, 140, 32);
  FLogin.Caption := 'Anmelden';
  FLogin.StyleManager := AStyles;
  FLogin.Enabled := False;   // erst mit Benutzer und Kennwort
  FLogin.OnClick := LoginClick;

  FStatus := NewLabel(AParent, 200, 'Noch nicht angemeldet.');
  FStatus.Width := 414;
end;

procedure TLoginBox.InputChange(Sender: TObject);
begin
  FLogin.Enabled := (FAttempts < MaxAttempts) and (Trim(FUser.Text) <> '') and
    (FPassword.Text <> '');
  // Wer neu tippt, sieht die alte Fehlermeldung nicht mehr
  if (Sender = FPassword) and (FPassword.Text <> '') then
    FPassword.ValidationState := pvsNone;
end;

procedure TLoginBox.PasswordKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_RETURN) and FLogin.Enabled then
  begin
    Key := 0;
    FLogin.Click;
  end;
end;

procedure TLoginBox.LoginClick(Sender: TObject);
begin
  if CheckCredentials(Trim(FUser.Text), FPassword.Text) then
  begin
    FLoggedIn := True;
    FPassword.ValidationState := pvsValid;
    FPassword.ValidationHint := '';
    FStatus.Caption := 'Angemeldet als ' + Trim(FUser.Text) + '.';
    Exit;
  end;
  Inc(FAttempts);
  // Falsches Kennwort nicht stehen lassen: Clear ueberschreibt es im Speicher
  FPassword.Clear;
  FPassword.ValidationState := pvsError;
  if FAttempts >= MaxAttempts then
  begin
    FPassword.ValidationHint := 'Zu viele Fehlversuche.';
    FPassword.Enabled := False;
    FStatus.Caption := 'Anmeldung gesperrt. Bitte wenden Sie sich an den Support.';
  end
  else
  begin
    FPassword.ValidationHint := Format('Kennwort falsch. Noch %d Versuche.',
      [MaxAttempts - FAttempts]);
    FStatus.Caption := FPassword.ValidationHint;
    if FPassword.CanFocus then
      FPassword.SetFocus;
  end;
end;
// EXAMPLE-END

end.
