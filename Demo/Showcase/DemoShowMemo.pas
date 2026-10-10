unit DemoShowMemo;

// Komponentenseite TPPGMemo (Gruppe "Eingabe"): Buehne und Inspektor kommen
// aus TDemoComponentPage; hier stehen nur die Besonderheiten des Memos
// (Beispieltext auf der Buehne, Kategorien, Zeilen/Zeichen im Protokoll)
// und die beiden Praxisbeispiele (ExMemoComment, ExMemoHistory).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Memo, DemoKit, DemoShowcase, ExMemoComment, ExMemoHistory;

type
  TDemoShowMemoPage = class(TDemoComponentPage)
  private
    FComment: TOrderComment;
    FHistory: TTicketHistory;
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

uses
  Vcl.StdCtrls, System.UITypes, PPG.Controls.Field;

// Logische Zeilen eines Textes. Lines.Count zaehlt bei WordWrap = True die
// sichtbaren (umbrochenen) Zeilen, deshalb hier ueber die Zeilenumbrueche.
// Ein Umbruch am Ende (Lines.Add haengt ihn an) beginnt keine neue Zeile.
function TextLines(const S: string): Integer;
var
  I: Integer;
begin
  Result := 0;
  if S = '' then
    Exit;
  Result := 1;
  for I := 1 to Length(S) do
    if S[I] = #10 then
      Inc(Result);
  if S[Length(S)] = #10 then
    Dec(Result);
end;

function TDemoShowMemoPage.SubjectClass: TComponentClass;
begin
  Result := TPPGMemo;
end;

procedure TDemoShowMemoPage.SetupSubject(ASubject: TComponent);
var
  M: TPPGMemo;
begin
  inherited SetupSubject(ASubject);
  // Etwas Text, damit Umbruch, Ausrichtung und Scrollleisten sofort wirken
  M := TPPGMemo(ASubject);
  M.SetBounds(32, 64, 360, 120);
  M.Lines.Text := L('Sehr geehrte Frau M{ue}ller,' + sLineBreak + sLineBreak +
    'vielen Dank f{ue}r Ihre Bestellung. Die Lieferung erfolgt voraussichtlich in der '
    + 'n{ae}chsten Woche, die Rechnung liegt der Sendung bei.' + sLineBreak +
    'Mit freundlichen Gr{ue}{ss}en');
end;

procedure TDemoShowMemoPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if (AName = 'TextHintVisibleOnFocus') then
    ACategory := 'Beschriftung & Bild'
  else if (AName = 'ValidationState') or (AName = 'ValidationHint') or (AName = 'MaxLength') or
    (AName = 'CharCase') or (AName = 'HideSelection') or (AName = 'UseSystemContextMenu') then
    ACategory := 'Verhalten'
  else if (AName = 'WantReturns') or (AName = 'WantTabs') then
    ACategory := 'Tastatur & Fokus'
  else if (AName = 'ScrollBars') then
    ACategory := 'Layout'
  else if (AName = 'BorderStyle') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowMemoPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
begin
  Detail := ADetail;
  if (AName = 'OnChange') and (Subject is TPPGMemo) then
    Detail := Format('%d Zeilen, %d Zeichen', [TextLines(TPPGMemo(Subject).Text),
      Length(TPPGMemo(Subject).Text)]);
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowMemoPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Bemerkungsfeld', 'ExMemoComment',
    'Ein Pflichtfeld "Bemerkung" in einem Auftrag: <b>TextHint</b> zeigt ein Beispiel, '
    + '<b>MaxLength</b> begrenzt auf 200 Zeichen, <b>OnChange</b> f{ue}hrt den Z{ae}hler nach und '
    + 'warnt ab 180 Zeichen (<b>ValidationState</b>). Probieren Sie: leer auf Speichern klicken '
    + '(roter Rand mit <b>ValidationHint</b>), dann tippen, Enter f{ue}r neue Zeilen nutzen und '
    + 'l{ae}ngeren Text einf{ue}gen.');
  FComment := TOrderComment.CreateComment(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Ticket-Verlauf', 'ExMemoHistory',
    'Der Verlauf eines Service-Tickets als <b>ReadOnly</b>-Memo mit grauer Fl{ae}che '
    + '(<b>ReadOnlyStyle</b>): lesen, markieren und kopieren geht, tippen nicht. Neue Eintr{ae}ge '
    + 'h{ae}ngt <b>Lines.Add</b> an. Probieren Sie: einen Eintrag schreiben und eintragen, dann '
    + '"Lange Zeilen umbrechen" ausschalten (<b>WordWrap</b> und <b>ScrollBars</b> = ssBoth) und '
    + 'zuletzt den Verlauf leeren.');
  FHistory := TTicketHistory.CreateHistory(Own, V.Live, DemoStyles);
end;

procedure TDemoShowMemoPage.SelfTest(Check: TDemoCheck);
var
  M: TPPGMemo;
  S: string;
  Count: Integer;
begin
  inherited SelfTest(Check);
  // Buehne: Text aus Code loest OnChange aus, das Protokoll nennt Zeilen und Zeichen
  ResetSubject;
  M := TPPGMemo(Subject);
  Check('TPPGMemo: B' + #$00FC + 'hne zeigt Beispieltext', TextLines(M.Text) = 4);
  M.Lines.Text := 'Erste Zeile' + sLineBreak + 'Zweite Zeile';
  Check('TPPGMemo: Text aus Code erscheint als OnChange mit Zeilen im Protokoll',
    (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('2 Zeilen', EventList.Items[0]) > 0));
  ResetSubject;

  // Praxisbeispiel 1: Zaehler, Pflichtpruefung, Warnung, Speichern
  FComment.Memo.Text := '';
  Check('Beispiel Bemerkung: MaxLength = 200, Z' + #$00E4 + 'hler startet bei 0',
    (FComment.Memo.MaxLength = CommentMaxChars) and (FComment.Counter.Caption = '0 / 200 Zeichen'));
  FComment.SaveButton.Click;
  Check('Beispiel Bemerkung: Speichern ohne Text setzt pvsError und ValidationHint',
    (FComment.Memo.ValidationState = pvsError) and (FComment.Memo.ValidationHint <> '') and
    (FComment.SavedText = ''));
  S := 'Lieferung nur vormittags' + sLineBreak + 'Zufahrt ' + #$00FC + 'ber Tor 2';
  FComment.Memo.Text := S;
  Check('Beispiel Bemerkung: Tippen hebt den Fehler auf, Z' + #$00E4 + 'hler z' + #$00E4 + 'hlt mit',
    (FComment.Memo.ValidationState = pvsNone) and
    (FComment.Counter.Caption = Format('%d / 200 Zeichen', [Length(S)])));
  FComment.Memo.Text := StringOfChar('x', 185);
  Check('Beispiel Bemerkung: ab 180 Zeichen Warnung "Noch 15 Zeichen frei"',
    (FComment.Memo.ValidationState = pvsWarning) and
    (FComment.Memo.ValidationHint = 'Noch 15 Zeichen frei'));
  FComment.Memo.Text := S;
  FComment.SaveButton.Click;
  Check('Beispiel Bemerkung: Speichern mit Text ' + #$00FC + 'bernimmt den Text',
    (FComment.SavedText = S) and (Pos(IntToStr(Length(S)) + ' Zeichen', FComment.Status.Caption) > 0) and
    not FComment.Memo.Modified);
  FComment.Memo.Text := '';

  // Praxisbeispiel 2: ReadOnly-Verlauf, Lines.Add, Umbruch, Leeren
  Count := TextLines(FHistory.History.Text);
  Check('Beispiel Verlauf: schreibgesch' + #$00FC + 'tzt mit 3 Eintr' + #$00E4 + 'gen, Eintragen gesperrt',
    FHistory.History.ReadOnly and (Count = 3) and not FHistory.AddButton.Enabled);
  FHistory.Entry.Text := 'Kunde zur' + #$00FC + 'ckgerufen';
  Check('Beispiel Verlauf: Eintragen mit Text frei', FHistory.AddButton.Enabled);
  FHistory.AddButton.Click;
  Check('Beispiel Verlauf: Eintrag mit Zeitstempel angeh' + #$00E4 + 'ngt, Eingabe geleert',
    (TextLines(FHistory.History.Text) = Count + 1) and
    (Pos('Kunde zur' + #$00FC + 'ckgerufen', FHistory.History.Text) > 0) and (FHistory.Entry.Text = '') and
    not FHistory.AddButton.Enabled);
  FHistory.WrapBox.Checked := False;
  Check('Beispiel Verlauf: ohne Umbruch WordWrap = False und ScrollBars = ssBoth',
    (not FHistory.History.WordWrap) and (FHistory.History.ScrollBars = ssBoth));
  FHistory.WrapBox.Checked := True;
  Check('Beispiel Verlauf: mit Umbruch WordWrap = True und ScrollBars = ssVertical',
    FHistory.History.WordWrap and (FHistory.History.ScrollBars = ssVertical));
  FHistory.ClearButton.Click;
  Check('Beispiel Verlauf: Leeren entfernt alle Zeilen und sperrt den Button',
    (FHistory.History.Text = '') and not FHistory.ClearButton.Enabled);
  FHistory.AddEntry('Verlauf neu begonnen');
  Check('Beispiel Verlauf: AddEntry gibt Leeren wieder frei',
    (TextLines(FHistory.History.Text) = 1) and FHistory.ClearButton.Enabled);
end;

initialization
  RegisterShowcasePage('TPPGMemo', TDemoShowMemoPage);

end.
