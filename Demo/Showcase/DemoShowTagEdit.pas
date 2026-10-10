unit DemoShowTagEdit;

// Komponentenseite TPPGTagEdit (Gruppe "Eingabe"): Buehne und Inspektor kommen
// aus TDemoComponentPage; hier stehen nur die Besonderheiten des TagEdits
// (Vorschlaege und Tags auf der Buehne, eigene Ereignis-Signaturen
// OnTagAdding/OnTagRemoved/OnTagClick im Protokoll, Kategorien) und die beiden
// Praxisbeispiele (ExTagEditRecipients, ExTagEditTicket).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.TagEdit, DemoKit, DemoInspector, DemoShowcase, ExTagEditRecipients, ExTagEditTicket;

type
  TDemoShowTagEditPage = class(TDemoComponentPage)
  private
    FRecipients: TRecipientField;
    FTicket: TTicketTags;
    procedure SubjectTagAdding(Sender: TObject; var Tag: string; var Allow: Boolean);
    procedure SubjectTagRemoved(Sender: TObject; const Tag: string);
    procedure SubjectTagClick(Sender: TObject; const Tag: string);
    procedure TestRecipients(Check: TDemoCheck);
    procedure TestTicket(Check: TDemoCheck);
    function Logged(const AEvent: string): Boolean;
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    function SkipInRoundTrip(Node: TDemoPropNode; var AReason: string): Boolean; override;
    procedure BuildExamples; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.Messages, System.Types, PPG.Controls.Field;

const
  Ue = #$00FC;

function TDemoShowTagEditPage.SubjectClass: TComponentClass;
begin
  Result := TPPGTagEdit;
end;

procedure TDemoShowTagEditPage.SetupSubject(ASubject: TComponent);
var
  Ed: TPPGTagEdit;
begin
  inherited SetupSubject(ASubject);
  Ed := ASubject as TPPGTagEdit;
  // Sofort etwas zu sehen und auszuprobieren: zwei Tags und Vorschlaege
  Ed.Width := 380;
  Ed.Suggestions.CommaText := 'Vertrieb,Einkauf,Technik,Buchhaltung,Personal,Angebot,Rechnung';
  Ed.TagsText := 'Vertrieb;Angebot';
  // Eigene Signaturen protokolliert die Seite nicht von selbst
  Ed.OnTagAdding := SubjectTagAdding;
  Ed.OnTagRemoved := SubjectTagRemoved;
  Ed.OnTagClick := SubjectTagClick;
end;

procedure TDemoShowTagEditPage.SubjectTagAdding(Sender: TObject; var Tag: string;
  var Allow: Boolean);
begin
  LogEvent('OnTagAdding', Format('Tag = "%s", Allow = %s', [Tag, BoolToStr(Allow, True)]));
end;

procedure TDemoShowTagEditPage.SubjectTagRemoved(Sender: TObject; const Tag: string);
begin
  LogEvent('OnTagRemoved', Format('Tag = "%s"', [Tag]));
end;

procedure TDemoShowTagEditPage.SubjectTagClick(Sender: TObject; const Tag: string);
begin
  LogEvent('OnTagClick', Format('Tag = "%s"', [Tag]));
end;

procedure TDemoShowTagEditPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Tags') or SameText(AName, 'Suggestions') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'AllowNew') or SameText(AName, 'AllowDuplicates') or
    SameText(AName, 'CaseSensitive') or SameText(AName, 'MaxTags') or
    SameText(AName, 'AddOnExit') or SameText(AName, 'InputDelimiters') or
    SameText(AName, 'ShowClearButton') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'Delimiter') then
    ACategory := 'Daten'
  else if SameText(AName, 'ValidationState') or SameText(AName, 'ValidationHint') then
    ACategory := 'Hinweise & Hilfe'
  else if SameText(AName, 'TextHintVisibleOnFocus') then
    ACategory := 'Beschriftung & Bild'
  else if SameText(AName, 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

function TDemoShowTagEditPage.SkipInRoundTrip(Node: TDemoPropNode; var AReason: string): Boolean;
begin
  // Mit AutoSize = True (Vorgabe) bestimmen die Tag-Zeilen die Hoehe; ein
  // gesetzter oder zurueckgesetzter Wert wird sofort neu berechnet
  Result := (Node.Parent = nil) and SameText(Node.Name, 'Height') and
    (Subject is TPPGTagEdit) and TPPGTagEdit(Subject).AutoSize;
  if Result then
    AReason := 'AutoSize berechnet die H' + #$00F6 + 'he aus den Tag-Zeilen';
end;

procedure TDemoShowTagEditPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: E-Mail-Empf{ae}nger', 'ExTagEditRecipients',
    'Ein Empf{ae}ngerfeld wie in Outlook: <b>Suggestions</b> schlagen Adressen aus dem Adressbuch vor, '
    + '<b>OnTagAdding</b> schreibt jede Adresse klein und lehnt Ung{ue}ltiges ab, <b>ValidationState</b> f{ae}rbt dann den Rand '
    + 'rot, <b>MaxTags</b> erlaubt h{oe}chstens f{ue}nf Empf{ae}nger, <b>OnChange</b> gibt Senden frei. '
    + 'Probieren Sie: "anna" tippen und einen Vorschlag w{ae}hlen, dann "Max Huber" und Enter, '
    + 'zuletzt R{ue}cktaste zweimal im leeren Feld.');
  FRecipients := TRecipientField.CreateField(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Ticket-Schlagworte', 'ExTagEditTicket',
    'Schlagworte eines Support-Tickets: <b>AllowNew = False</b> l{ae}sst nur Eintr{ae}ge aus der Liste zu, '
    + '<b>TagsText</b> l{ae}dt und speichert alle als ein Datenbankfeld ("Drucker;Dringend"), '
    + '<b>OnTagClick</b> filtert nach dem angeklickten Schlagwort, <b>ReadOnly</b> sperrt abgeschlossene '
    + 'Tickets. Probieren Sie: "Kaffee" eingeben (wird nicht {ue}bernommen), "Netz" tippen und den '
    + 'Vorschlag w{ae}hlen, dann Speichern.');
  FTicket := TTicketTags.CreateTicket(Own, V.Live, DemoStyles, 'Drucker;Dringend');
end;

function TDemoShowTagEditPage.Logged(const AEvent: string): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to EventList.Items.Count - 1 do
    if Pos('<b>' + AEvent + '</b>', EventList.Items[I]) > 0 then
      Exit(True);
end;

procedure TDemoShowTagEditPage.TestRecipients(Check: TDemoCheck);
var
  Ed: TPPGTagEdit;
  OkTag, Dup, Bad, Max: Boolean;
  I: Integer;
begin
  Ed := FRecipients.Recipients;
  Ed.Clear;
  Check('Beispiel Empf' + #$00E4 + 'nger: ohne Adresse ist Senden gesperrt',
    not FRecipients.SendButton.Enabled);
  OkTag := Ed.AddTag(' Anna.Berger@Kunde.de ');
  Check('Beispiel Empf' + #$00E4 + 'nger: OnTagAdding schreibt die Adresse klein, Senden frei',
    OkTag and (Ed.Tags.Count = 1) and (Ed.Tags[0] = 'anna.berger@kunde.de') and
    FRecipients.SendButton.Enabled);
  Bad := Ed.AddTag('Max Huber');
  Check('Beispiel Empf' + #$00E4 + 'nger: "Max Huber" abgelehnt, ValidationState = pvsError',
    (not Bad) and (Ed.Tags.Count = 1) and (Ed.ValidationState = pvsError));
  Dup := Ed.AddTag('ANNA.BERGER@kunde.de');
  Check('Beispiel Empf' + #$00E4 + 'nger: doppelte Adresse abgelehnt (AllowDuplicates = False)',
    (not Dup) and (Ed.Tags.Count = 1));
  for I := 1 to 5 do
    Ed.AddTag(Format('kunde%d@firma.de', [I]));
  Max := Ed.AddTag('noch.einer@firma.de');
  Check('Beispiel Empf' + #$00E4 + 'nger: MaxTags = 5 begrenzt die Empf' + #$00E4 + 'nger',
    (not Max) and (Ed.Tags.Count = 5) and (Ed.ValidationState = pvsNone));
  Ed.RemoveTag(4);
  Check('Beispiel Empf' + #$00E4 + 'nger: OnTagRemoved meldet die entfernte Adresse',
    (Ed.Tags.Count = 4) and (Pos('kunde4@firma.de entfernt', FRecipients.Status.Caption) = 1) and
    (FRecipients.SendButton.Caption = 'Senden (4)'));
  FRecipients.SendButton.Click;
  Check('Beispiel Empf' + #$00E4 + 'nger: Senden nimmt TagsText mit ";" getrennt',
    FRecipients.LastSent = 'anna.berger@kunde.de;kunde1@firma.de;kunde2@firma.de;kunde3@firma.de');
  // Ausgangszustand fuer den Anwender
  Ed.Clear;
  Ed.ValidationState := pvsNone;
  Ed.ValidationHint := '';
  FRecipients.Status.Caption := 'Noch keine Adresse eingetragen.';
end;

procedure TDemoShowTagEditPage.TestTicket(Check: TDemoCheck);
var
  Ed: TPPGTagEdit;
  R: TRect;
  P: TPoint;
  Added: Boolean;
begin
  Ed := FTicket.Tags;
  Check('Beispiel Ticket: TagsText l' + #$00E4 + 'dt "Drucker;Dringend" als zwei Tags',
    (Ed.Tags.Count = 2) and (Ed.Tags[0] = 'Drucker') and (Ed.Tags[1] = 'Dringend'));
  Added := Ed.AddTag('Kaffeemaschine');
  Check('Beispiel Ticket: AllowNew = False lehnt "Kaffeemaschine" ab',
    (not Added) and (Ed.Tags.Count = 2));
  Added := Ed.AddTag('Netzwerk');
  Check('Beispiel Ticket: Schlagwort aus der Liste wird angenommen',
    Added and (Ed.Tags.Count = 3));
  // Klick auf den ersten Chip (Mitte, nicht das x) per Mausnachricht
  R := Ed.ChipRect(0);
  P := Point(R.Left + 8, (R.Top + R.Bottom) div 2);
  Ed.Perform(WM_LBUTTONDOWN, MK_LBUTTON, PointToLParam(P));
  Ed.Perform(WM_LBUTTONUP, 0, PointToLParam(P));
  Check('Beispiel Ticket: Klick auf "Drucker" setzt den Filter (OnTagClick)',
    (FTicket.Filter = 'Drucker') and (Ed.Tags.Count = 3));
  FTicket.SaveButton.Click;
  Check('Beispiel Ticket: Speichern schreibt "Drucker;Dringend;Netzwerk" ins Datenbankfeld',
    FTicket.FieldValue = 'Drucker;Dringend;Netzwerk');
  FTicket.Closed.Checked := True;
  Added := Ed.AddTag('Login');
  Check('Beispiel Ticket: abgeschlossen = ReadOnly, keine neuen Schlagworte',
    Ed.ReadOnly and (not Added) and (Ed.Tags.Count = 3));
  FTicket.Closed.Checked := False;
  Check('Beispiel Ticket: wieder offen = bearbeitbar', not Ed.ReadOnly);
  // Ausgangszustand
  Ed.TagsText := 'Drucker;Dringend';
  Ed.SelectedTag := -1;
end;

procedure TDemoShowTagEditPage.SelfTest(Check: TDemoCheck);
var
  Ed: TPPGTagEdit;
  Added: Boolean;
begin
  inherited SelfTest(Check);
  // Buehne: Anwender-Aktionen erscheinen mit eigener Signatur im Protokoll
  ResetSubject;
  Ed := TPPGTagEdit(Subject);
  Check('TPPGTagEdit: B' + Ue + 'hne zeigt zwei Tags und Vorschl' + #$00E4 + 'ge',
    (Ed.Tags.Count = 2) and (Ed.Suggestions.Count > 0));
  Added := Ed.AddTag('Technik');
  Check('TPPGTagEdit: AddTag erscheint als OnTagAdding im Protokoll',
    Added and Logged('OnTagAdding') and Logged('OnChange'));
  Ed.RemoveTag(0);
  Check('TPPGTagEdit: RemoveTag erscheint als OnTagRemoved im Protokoll',
    (Ed.Tags.Count = 2) and Logged('OnTagRemoved'));
  ResetSubject;

  TestRecipients(Check);
  TestTicket(Check);
end;

initialization
  RegisterShowcasePage('TPPGTagEdit', TDemoShowTagEditPage);

end.
