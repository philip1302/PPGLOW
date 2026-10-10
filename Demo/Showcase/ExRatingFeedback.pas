unit ExRatingFeedback;

// Praxisbeispiel 1 zu TPPGRating (Demo-Seite "Auswahl > TPPGRating"):
// Kundenfeedback nach einem Support-Ticket. Die Bewertung (OnChange) gibt das
// Absenden frei, zeigt die Stufe als Text, fragt bei schlechter Bewertung
// nach dem Grund und wird nach dem Absenden zur reinen Anzeige (ReadOnly).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  PPG.StyleManager, PPG.Labels, PPG.Edit, PPG.Button, PPG.Rating;

type
  /// Feedback zu einem Ticket: Sterne vergeben, bei 1-2 Sternen einen Grund
  /// nennen, absenden. Danach ist die Bewertung nur noch Anzeige.
  TTicketFeedback = class(TComponent)
  private
    FQuestion: TPPGLabel;
    FRating: TPPGRating;
    FVerdict: TPPGLabel;
    FComment: TPPGEdit;
    FSend: TPPGButton;
    FStatus: TPPGLabel;
    procedure RatingChange(Sender: TObject);
    procedure CommentChange(Sender: TObject);
    procedure SendClick(Sender: TObject);
    procedure UpdateState;
  public
    constructor CreateFeedback(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Rating: TPPGRating read FRating;
    property Verdict: TPPGLabel read FVerdict;
    property Comment: TPPGEdit read FComment;
    property SendButton: TPPGButton read FSend;
    property Status: TPPGLabel read FStatus;
  end;

/// Text zur Bewertung: 0 = noch keine, 1 = mangelhaft ... 5 = sehr gut.
function VerdictText(AValue: Double): string;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function VerdictText(AValue: Double): string;
begin
  case Round(AValue) of
    1: Result := 'Mangelhaft';
    2: Result := 'Ausreichend';
    3: Result := 'Befriedigend';
    4: Result := 'Gut';
    5: Result := 'Sehr gut';
  else
    Result := 'Noch keine Bewertung';
  end;
end;

constructor TTicketFeedback.CreateFeedback(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  FQuestion := TPPGLabel.Create(Self);
  FQuestion.Parent := AParent;
  FQuestion.SetBounds(16, 16, 418, 20);
  FQuestion.Caption := 'Wie zufrieden sind Sie mit der Bearbeitung von Ticket 4711?';

  // Grosse Sterne fuer die zentrale Frage; ein zweiter Klick auf den
  // gewaehlten Stern nimmt die Bewertung zurueck (AllowClear)
  FRating := TPPGRating.Create(Self);
  FRating.Parent := AParent;
  FRating.Left := 16;   // Breite und Hoehe: AutoSize aus Max und StarSize
  FRating.Top := 44;
  FRating.Max := 5;
  FRating.StarSize := 28;
  FRating.StarSpacing := 6;
  FRating.AllowClear := True;
  FRating.Hint := '1 = mangelhaft, 5 = sehr gut. Erneut klicken entfernt die Bewertung.';
  FRating.ShowHint := True;
  FRating.StyleManager := AStyles;
  FRating.OnChange := RatingChange;

  FVerdict := TPPGLabel.Create(Self);
  FVerdict.Parent := AParent;
  FVerdict.SetBounds(212, 52, 222, 20);
  FVerdict.Font.Style := [fsBold];

  FComment := TPPGEdit.Create(Self);
  FComment.Parent := AParent;
  FComment.SetBounds(16, 92, 418, 32);
  FComment.StyleManager := AStyles;
  FComment.OnChange := CommentChange;

  FSend := TPPGButton.Create(Self);
  FSend.Parent := AParent;
  FSend.SetBounds(16, 140, 120, 32);
  FSend.Caption := 'Absenden';
  FSend.StyleManager := AStyles;
  FSend.OnClick := SendClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(148, 146, 286, 20);

  UpdateState;   // Value im Code loest kein OnChange aus
end;

procedure TTicketFeedback.UpdateState;
var
  Poor: Boolean;
begin
  FVerdict.Caption := VerdictText(FRating.Value);
  // Bei 1-2 Sternen ist ein Grund Pflicht, sonst freiwillig
  Poor := (FRating.Value > 0) and (FRating.Value <= 2);
  if Poor then
    FComment.TextHint := 'Was ist schiefgelaufen? (Pflicht bei 1-2 Sternen)'
  else
    FComment.TextHint := 'Anmerkung (freiwillig)';
  FSend.Enabled := not FRating.ReadOnly and (FRating.Value > 0) and
    (not Poor or (Trim(FComment.Text) <> ''));
end;

procedure TTicketFeedback.RatingChange(Sender: TObject);
begin
  // Nur bei Eingabe des Anwenders (Klick, Pfeiltasten, Ziffern)
  UpdateState;
end;

procedure TTicketFeedback.CommentChange(Sender: TObject);
begin
  UpdateState;
end;

procedure TTicketFeedback.SendClick(Sender: TObject);
begin
  // Hier wuerde die Bewertung gespeichert; danach nur noch anzeigen
  FRating.ReadOnly := True;
  FComment.ReadOnly := True;
  FStatus.Caption := Format('Danke! %d von %d Sternen gesendet.',
    [Round(FRating.Value), FRating.Max]);
  UpdateState;
end;
// EXAMPLE-END

end.
