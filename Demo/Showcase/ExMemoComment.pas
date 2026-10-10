unit ExMemoComment;

// Praxisbeispiel 1 zu TPPGMemo (Demo-Seite "Eingabe > TPPGMemo"):
// Bemerkungsfeld in einem Auftragsformular mit Platzhalter (TextHint),
// Zeichengrenze (MaxLength) samt Zaehler (OnChange), Pflichtpruefung beim
// Speichern (ValidationState, ValidationHint) und senkrechter Scrollleiste.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, System.UITypes,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.Memo, PPG.Button;

const
  CommentMaxChars = 200;   // Grenze fuer die Bemerkung
  CommentWarnChars = 180;  // ab hier warnt das Feld

type
  /// Bemerkung zu einem Auftrag: Pflichtfeld mit hoechstens 200 Zeichen,
  /// Zaehler unter dem Feld, Pruefung beim Speichern.
  TOrderComment = class(TComponent)
  private
    FPrompt: TPPGLabel;
    FMemo: TPPGMemo;
    FCounter: TPPGLabel;
    FSave: TPPGButton;
    FStatus: TPPGLabel;
    FSavedText: string;
    procedure MemoChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  public
    constructor CreateComment(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Memo: TPPGMemo read FMemo;
    property Counter: TPPGLabel read FCounter;
    property SaveButton: TPPGButton read FSave;
    property Status: TPPGLabel read FStatus;
    property SavedText: string read FSavedText;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TOrderComment.CreateComment(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  FPrompt := TPPGLabel.Create(Self);
  FPrompt.Parent := AParent;
  FPrompt.SetBounds(16, 16, 418, 20);
  FPrompt.Caption := '&Bemerkung zum Auftrag (Pflichtfeld):';

  // Das Memo: Enter beginnt eine neue Zeile (WantReturns, Vorgabe),
  // lange Zeilen brechen um (WordWrap, Vorgabe) - deshalb reicht die
  // senkrechte Scrollleiste.
  FMemo := TPPGMemo.Create(Self);
  FMemo.Parent := AParent;
  FMemo.SetBounds(16, 40, 418, 110);
  FMemo.StyleManager := AStyles;
  FMemo.TextHint := 'z. B. Lieferung nur vormittags, Zufahrt an Tor 2';
  FMemo.MaxLength := CommentMaxChars;  // Tippen und Einfuegen stoppen hier
  FMemo.ScrollBars := ssVertical;
  FMemo.OnChange := MemoChange;
  FPrompt.FocusControl := FMemo;

  FCounter := TPPGLabel.Create(Self);
  FCounter.Parent := AParent;
  FCounter.AutoSize := False;
  FCounter.SetBounds(234, 156, 200, 20);
  FCounter.Alignment := taRightJustify;

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(16, 184, 120, 32);
  FSave.Caption := 'Speichern';
  FSave.StyleManager := AStyles;
  FSave.OnClick := SaveClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(148, 190, 286, 20);
  FStatus.Caption := 'Noch nicht gespeichert.';

  MemoChange(nil);  // Zaehler fuellen
end;

procedure TOrderComment.MemoChange(Sender: TObject);
var
  Len: Integer;
begin
  // OnChange kommt bei jeder Aenderung: Tippen, Einfuegen, Code
  Len := Length(FMemo.Text);
  FCounter.Caption := Format('%d / %d Zeichen', [Len, CommentMaxChars]);
  if Len >= CommentWarnChars then
  begin
    FMemo.ValidationState := pvsWarning;
    FMemo.ValidationHint := Format('Noch %d Zeichen frei', [CommentMaxChars - Len]);
  end
  else
    FMemo.ValidationState := pvsNone;  // auch ein Fehler vom Speichern verschwindet
end;

procedure TOrderComment.SaveClick(Sender: TObject);
begin
  if Trim(FMemo.Text) = '' then
  begin
    // Pflichtfeld leer: roter Rand und Erklaerung als Tooltip
    FMemo.ValidationState := pvsError;
    FMemo.ValidationHint := 'Bitte eine Bemerkung eintragen.';
    FStatus.Caption := 'Nicht gespeichert: Bemerkung fehlt.';
    if FMemo.CanFocus then
      FMemo.SetFocus;
    Exit;
  end;
  FSavedText := FMemo.Text;
  FMemo.Modified := False;
  FStatus.Caption := Format('Gespeichert (%d Zeichen).', [Length(FSavedText)]);
end;
// EXAMPLE-END

end.
