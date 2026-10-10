unit DemoShowRating;

// Komponentenseite TPPGRating (Gruppe "Auswahl"): Buehne und Inspektor kommen
// aus TDemoComponentPage; hier stehen nur die Besonderheiten der Bewertung
// (Startwert auf der Buehne, Kategorien, Wert im Protokoll) und die beiden
// Praxisbeispiele (ExRatingFeedback, ExRatingSupplier).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.Rating, DemoKit, DemoShowcase, ExRatingFeedback, ExRatingSupplier;

type
  TDemoShowRatingPage = class(TDemoComponentPage)
  private
    FFeedback: TTicketFeedback;
    FSupplier: TSupplierScore;
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
  Winapi.Windows, Winapi.Messages, System.Types;

// Tastatur und Maus wie beim Anwender (loest OnChange aus, anders als Value := ...)
procedure PressKey(R: TPPGRating; Key: Word);
begin
  R.Perform(WM_KEYDOWN, Key, 0);
end;

procedure TypeChar(R: TPPGRating; C: Char);
begin
  R.Perform(WM_CHAR, Ord(C), 0);
end;

procedure ClickStar(R: TPPGRating; Index: Integer);
var
  S: TRect;
  P: TPoint;
begin
  S := R.StarRect(Index);
  P := Point((S.Left + S.Right) div 2 + 1, (S.Top + S.Bottom) div 2);
  R.Perform(WM_LBUTTONUP, 0, MakeLParam(Word(P.X), Word(P.Y)));
end;

function TDemoShowRatingPage.SubjectClass: TComponentClass;
begin
  Result := TPPGRating;
end;

procedure TDemoShowRatingPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Drei von fuenf Sternen, damit gefuellte und leere Sterne zu sehen sind
  TPPGRating(ASubject).Value := 3;
end;

procedure TDemoShowRatingPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Value') or SameText(AName, 'Max') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'AllowHalf') or SameText(AName, 'AllowClear') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'StarSize') or SameText(AName, 'StarSpacing') then
    ACategory := 'Layout'
  else if SameText(AName, 'StarColor') then
    ACategory := 'PPGlow';
end;

procedure TDemoShowRatingPage.EventOccurred(const AName, ADetail: string);
var
  Detail: string;
  R: TPPGRating;
begin
  Detail := ADetail;
  if (AName = 'OnChange') and (Subject is TPPGRating) then
  begin
    R := TPPGRating(Subject);
    Detail := Format('Value = %s von %d', [FloatToStr(R.Value), R.Max]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowRatingPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Ticket-Feedback', 'ExRatingFeedback',
    'Kundenfeedback nach einem Support-Ticket: <b>OnChange</b> zeigt die Stufe als Text und gibt '
    + '<b>Absenden</b> erst mit einer Bewertung frei; bei 1{-}2 Sternen ist ein Grund Pflicht. '
    + '<b>AllowClear</b>: ein zweiter Klick auf denselben Stern nimmt die Bewertung zur{ue}ck. '
    + 'Nach dem Absenden wird die Bewertung <b>ReadOnly</b>. Probieren Sie: 2 Sterne, Grund eintragen, '
    + 'absenden {-} oder per Tab auf die Sterne und Ziffern bzw. Pfeiltasten dr{ue}cken.');
  FFeedback := TTicketFeedback.CreateFeedback(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Lieferantenbewertung', 'ExRatingSupplier',
    'Ein Bewertungsbogen mit drei Kriterien: ein <b>gemeinsames OnChange</b> f{ue}r alle, '
    + 'das Kriterium steht in <b>Tag</b>. Die Gesamtnote ist <b>ReadOnly</b> mit <b>AllowHalf</b> und '
    + 'goldener <b>StarColor</b>: Der Durchschnitt 4,3 wird als 4,5 Sterne gezeigt. Probieren Sie: '
    + 'ein Kriterium {ae}ndern oder durch erneuten Klick auf seinen Stern entfernen {-} es z{ae}hlt '
    + 'dann nicht mehr mit.');
  FSupplier := TSupplierScore.CreateScore(Own, V.Live, DemoStyles);
end;

procedure TDemoShowRatingPage.SelfTest(Check: TDemoCheck);
var
  R: TPPGRating;
  Changes: Integer;
  Fb: TTicketFeedback;
  Sp: TSupplierScore;
begin
  inherited SelfTest(Check);
  // Buehne: Eingabe per Tastatur erscheint mit Wert im Protokoll, Value im
  // Code nicht
  ResetSubject;
  R := TPPGRating(Subject);
  Check('TPPGRating: B' + #$00FC + 'hne startet mit 3 Sternen', R.Value = 3);
  PressKey(R, VK_RIGHT);
  Check('TPPGRating: Pfeil rechts setzt 4 und erscheint im Protokoll mit Wert',
    (R.Value = 4) and (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('Value = 4', EventList.Items[0]) > 0));
  Changes := EventList.Items.Count;
  R.Value := 2;
  Check('TPPGRating: Value im Code l' + #$00F6 + 'st kein OnChange aus',
    EventList.Items.Count = Changes);
  ResetSubject;

  // Praxisbeispiel 1: Ticket-Feedback
  Fb := TTicketFeedback.CreateFeedback(nil, Stage, DemoStyles);
  try
    Check('Beispiel Feedback: ohne Bewertung ist Absenden gesperrt',
      (Fb.Rating.Value = 0) and not Fb.SendButton.Enabled);
    TypeChar(Fb.Rating, '4');
    Check('Beispiel Feedback: Ziffer 4 setzt 4 Sterne, Text "Gut", Absenden frei',
      (Fb.Rating.Value = 4) and (Fb.Verdict.Caption = 'Gut') and Fb.SendButton.Enabled);
    ClickStar(Fb.Rating, 3);
    Check('Beispiel Feedback: Klick auf den gew' + #$00E4 + 'hlten Stern entfernt die Bewertung (AllowClear)',
      (Fb.Rating.Value = 0) and not Fb.SendButton.Enabled);
    ClickStar(Fb.Rating, 1);
    Check('Beispiel Feedback: 2 Sterne ohne Grund bleiben gesperrt',
      (Fb.Rating.Value = 2) and (Fb.Verdict.Caption = 'Ausreichend') and not Fb.SendButton.Enabled);
    Fb.Comment.Text := 'Antwort kam erst nach drei Tagen';
    Check('Beispiel Feedback: mit Grund ist Absenden frei', Fb.SendButton.Enabled);
    Fb.SendButton.Click;
    Check('Beispiel Feedback: nach dem Absenden ReadOnly, Button gesperrt, Dank im Status',
      Fb.Rating.ReadOnly and not Fb.SendButton.Enabled and
      (Pos('2 von 5', Fb.Status.Caption) > 0));
    TypeChar(Fb.Rating, '5');
    Check('Beispiel Feedback: ReadOnly-Bewertung ignoriert Eingaben', Fb.Rating.Value = 2);
  finally
    Fb.Free;
  end;

  // Praxisbeispiel 2: Lieferantenbewertung
  Sp := TSupplierScore.CreateScore(nil, Stage, DemoStyles);
  try
    Check('Beispiel Lieferant: Start 4/5/4 ergibt Gesamt 4,5 Sterne (AllowHalf), ReadOnly',
      (Sp.Total.Value = 4.5) and Sp.Total.ReadOnly and Sp.Total.AllowHalf and
      (Sp.Total.StarColor = $0000C0FF));
    TypeChar(Sp.Criterion[1], '1');
    Check('Beispiel Lieferant: Preis-Leistung 1 ergibt Gesamt 3 und Status mit Kriterium (Tag)',
      (Sp.Criterion[1].Value = 1) and (Sp.Total.Value = 3) and
      (Pos('Preis-Leistung: 1 von 5', Sp.Status.Caption) > 0));
    PressKey(Sp.Criterion[0], VK_HOME);
    Check('Beispiel Lieferant: nicht bewertetes Kriterium z' + #$00E4 + 'hlt nicht mit',
      (Sp.Criterion[0].Value = 0) and (Abs(Sp.Average - 2.5) < 0.001) and (Sp.Total.Value = 2.5));
    PressKey(Sp.Criterion[1], VK_HOME);
    PressKey(Sp.Criterion[2], VK_HOME);
    Check('Beispiel Lieferant: ohne Bewertung Gesamt 0 und "nicht bewertet"',
      (Sp.Total.Value = 0) and (Sp.TotalText.Caption = 'nicht bewertet'));
    TypeChar(Sp.Total, '5');
    Check('Beispiel Lieferant: Gesamtnote (ReadOnly) l' + #$00E4 + 'sst sich nicht eingeben',
      Sp.Total.Value = 0);
  finally
    Sp.Free;
  end;
end;

initialization
  RegisterShowcasePage('TPPGRating', TDemoShowRatingPage);

end.
