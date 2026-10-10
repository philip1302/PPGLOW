unit DemoShowCheckGroup;

// Komponentenseite TPPGCheckGroup (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten der
// CheckGroup (Eintraege auf der Buehne, OnItemClick im Protokoll, Value bei
// OnChange) und die beiden Praxisbeispiele (ExCheckGroupNotify,
// ExCheckGroupRights).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls,
  PPG.RadioGroup, PPG.Controls.Field, DemoKit, DemoShowcase, ExCheckGroupNotify,
  ExCheckGroupRights;

type
  TDemoShowCheckGroupPage = class(TDemoComponentPage)
  private
    FNotify: TNotifySettings;
    FRights: TRoleRights;
    procedure SubjectItemClick(Sender: TObject; Index: Integer);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

type
  // Zugriff auf ActivateItem (protected): dieselbe Aktion wie ein Klick bzw.
  // die Leertaste des Anwenders, mit OnItemClick, OnClick und OnChange
  TCheckGroupAccess = class(TPPGCheckGroup);

procedure UserToggle(AGroup: TPPGCheckGroup; Index: Integer);
begin
  TCheckGroupAccess(AGroup).ActivateItem(Index);
end;

function TDemoShowCheckGroupPage.SubjectClass: TComponentClass;
begin
  Result := TPPGCheckGroup;
end;

procedure TDemoShowCheckGroupPage.SetupSubject(ASubject: TComponent);
var
  Grp: TPPGCheckGroup;
begin
  inherited SetupSubject(ASubject);
  // Wie nach dem Ablegen und Fuellen von Items im Designer: vier Eintraege,
  // damit man sofort ankreuzen kann
  Grp := ASubject as TPPGCheckGroup;
  Grp.SetBounds(Grp.Left, Grp.Top, 260, 150);
  Grp.Items.Text := 'E-Mail' + sLineBreak + 'SMS' + sLineBreak + 'Telefon' + sLineBreak + 'Brief';
  // Eigene Signatur (Sender, Index): wird nicht automatisch protokolliert
  Grp.OnItemClick := SubjectItemClick;
end;

procedure TDemoShowCheckGroupPage.SubjectItemClick(Sender: TObject; Index: Integer);
var
  Grp: TPPGCheckGroup;
  State: string;
begin
  Grp := Sender as TPPGCheckGroup;
  case Grp.ItemState[Index] of
    cbChecked: State := L('angekreuzt');
    cbGrayed: State := L('grau');
  else
    State := L('leer');
  end;
  LogEvent('OnItemClick', Format('Index = %d (%s: %s)', [Index, Grp.Items[Index], State]));
end;

procedure TDemoShowCheckGroupPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if (AName = 'OnChange') and (Subject is TPPGCheckGroup) then
    Detail := Format('Value = ''%s''', [TPPGCheckGroup(Subject).Value]);
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowCheckGroupPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'AllowGrayed') or SameText(AName, 'ValidationState') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'Columns') or SameText(AName, 'ShowFrame') then
    ACategory := 'Layout'
  else if SameText(AName, 'ChoiceStyle') or SameText(AName, 'ItemStyle') or
    SameText(AName, 'SelectedStyle') or SameText(AName, 'CaptionStyle') or
    SameText(AName, 'HighlightFocus') then
    ACategory := 'PPGlow'
  else if SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe';
end;

procedure TDemoShowCheckGroupPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Benachrichtigungen', 'ExCheckGroupNotify',
    'Einstellungen eines Kunden: Auf welchen Wegen darf er benachrichtigt werden? '
    + '<b>Value</b> liefert die Kommaliste f{ue}r die Datenbank ("mail,push") und l{ae}dt sie '
    + 'auch wieder. SMS ist <b>gesperrt</b> (ItemEnabled), bis eine Mobilnummer eingetragen ist; '
    + 'der <b>Hinweis</b> des Eintrags nennt den Grund. Probieren Sie: alle Haken entfernen '
    + '({-} <b>ValidationState</b> markiert die Pflichtauswahl rot), dann eine Nummer eintragen '
    + 'und SMS ankreuzen.');
  FNotify := TNotifySettings.CreateSettings(Own, V.Live, DemoStyles, 'mail');

  V := AddExample('Praxis: Benutzerrechte', 'ExCheckGroupRights',
    'Rechte einer Rolle je Modul als <b>Kacheln</b> (ChoiceStyle = csCards) mit Symbol und '
    + 'Beschreibung. Mit <b>AllowGrayed</b> hat jede Kachel drei Zust{ae}nde: Haken = bearbeiten, '
    + 'grau = nur lesen, leer = kein Zugriff. <b>OnItemClick</b> meldet die umgeschaltete Kachel. '
    + 'Probieren Sie: eine Kachel mehrmals anklicken oder mit Pfeiltasten und Leertaste '
    + 'bedienen, dann "Alles nur lesen".');
  FRights := TRoleRights.CreateRights(Own, V.Live, DemoStyles);
end;

procedure TDemoShowCheckGroupPage.SelfTest(Check: TDemoCheck);
const
  Prefix = 'TPPGCheckGroup: ';
var
  Grp: TPPGCheckGroup;
  Notify: TNotifySettings;
begin
  inherited SelfTest(Check);

  // Buehne: Anwender kreuzt an -> OnItemClick (eigene Signatur) und OnChange
  // mit Value im Protokoll
  ResetSubject;
  Grp := TPPGCheckGroup(Subject);
  UserToggle(Grp, 1);
  Check(Prefix + 'Ankreuzen auf der B' + #$00FC + 'hne: OnItemClick und OnChange im Protokoll',
    (EventList.Items.Count >= 3) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('''SMS''', EventList.Items[0]) > 0) and (Pos('OnItemClick', EventList.Items[2]) > 0) and
    (Pos('Index = 1', EventList.Items[2]) > 0));
  ResetSubject;

  // Praxisbeispiel 1: eigene Instanz, damit die Live-Flaeche unberuehrt bleibt
  Notify := TNotifySettings.CreateSettings(nil, FNotify.Channels.Parent, DemoStyles, 'mail,post');
  try
    Grp := Notify.Channels;
    Check('Beispiel Benachrichtigungen: Value l' + #$00E4 + 'dt die Kommaliste ohne OnChange',
      Grp.Checked[0] and Grp.Checked[3] and not Grp.Checked[2] and
      (Notify.SavedValue = 'mail,post'));
    Check('Beispiel Benachrichtigungen: SMS ohne Mobilnummer gesperrt',
      not Grp.ItemEnabled[1]);
    UserToggle(Grp, 1);
    Check('Beispiel Benachrichtigungen: gesperrter Eintrag l' + #$00E4 + 'sst sich nicht ankreuzen',
      not Grp.Checked[1]);
    Notify.Phone.Text := '0171 1234567';
    UserToggle(Grp, 1);
    Check('Beispiel Benachrichtigungen: mit Mobilnummer SMS frei und gespeichert',
      Grp.ItemEnabled[1] and Grp.Checked[1] and (Notify.SavedValue = 'mail,sms,post'));
    UserToggle(Grp, 0);
    UserToggle(Grp, 1);
    UserToggle(Grp, 3);
    Check('Beispiel Benachrichtigungen: ohne Haken Pflichtfehler, alter Wert bleibt',
      (Grp.Value = '') and (Grp.ValidationState = pvsError) and (Grp.ValidationHint <> '') and
      (Notify.SavedValue = 'post'));
    UserToggle(Grp, 2);
    Check('Beispiel Benachrichtigungen: neuer Haken hebt den Fehler auf',
      (Grp.ValidationState = pvsNone) and (Notify.SavedValue = 'push'));
    UserToggle(Grp, 1);
    Notify.Phone.Text := '';
    Check('Beispiel Benachrichtigungen: Nummer gel' + #$00F6 + 'scht -> SMS gesperrt und abgehakt',
      (not Grp.ItemEnabled[1]) and (not Grp.Checked[1]) and (Notify.SavedValue = 'push'));
  finally
    Notify.Free;
  end;

  // Praxisbeispiel 2: Zyklus mit AllowGrayed, OnItemClick, Value, Code-Aenderung
  Grp := FRights.Modules;
  Check('Beispiel Rechte: Startzustand (Value nur mit den angehakten Modulen)',
    (Grp.Value = 'Kunden,Angebote') and (Grp.ItemState[2] = cbGrayed) and
    (FRights.Summary.Caption = 'Bearbeiten: Kunden,Angebote'));
  UserToggle(Grp, 3);
  Check('Beispiel Rechte: Klick auf leere Kachel -> bearbeiten, OnItemClick meldet sie',
    (Grp.ItemState[3] = cbChecked) and (FRights.LastChange.Caption = 'Berichte: bearbeiten') and
    (FRights.Summary.Caption = 'Bearbeiten: Kunden,Angebote,Berichte'));
  UserToggle(Grp, 3);
  Check('Beispiel Rechte: zweiter Klick -> grau (nur lesen)',
    (Grp.ItemState[3] = cbGrayed) and (FRights.LastChange.Caption = 'Berichte: nur lesen') and
    (Grp.Value = 'Kunden,Angebote'));
  UserToggle(Grp, 3);
  Check('Beispiel Rechte: dritter Klick -> kein Zugriff',
    (Grp.ItemState[3] = cbUnchecked) and (FRights.LastChange.Caption = 'Berichte: kein Zugriff'));
  FRights.ReadOnlyAllButton.Click;
  Check('Beispiel Rechte: "Alles nur lesen" setzt alle grau, Value leer',
    (Grp.ItemState[0] = cbGrayed) and (Grp.ItemState[3] = cbGrayed) and (Grp.Value = '') and
    (FRights.Summary.Caption = 'Bearbeiten: keine Module'));
  // Ausgangszustand des Beispiels wiederherstellen
  Grp.ItemState[0] := cbChecked;
  Grp.ItemState[1] := cbChecked;
  Grp.ItemState[3] := cbUnchecked;
  UserToggle(Grp, 2);
  UserToggle(Grp, 2);
  UserToggle(Grp, 2);
  FRights.LastChange.Caption := 'Noch nichts geaendert.';
  Check('Beispiel Rechte: Ausgangszustand wiederhergestellt',
    (Grp.Value = 'Kunden,Angebote') and (Grp.ItemState[2] = cbGrayed));
end;

initialization
  RegisterShowcasePage('TPPGCheckGroup', TDemoShowCheckGroupPage);

end.
