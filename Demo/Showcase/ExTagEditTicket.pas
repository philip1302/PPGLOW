unit ExTagEditTicket;

// Praxisbeispiel 2 zu TPPGTagEdit (Demo-Seite "Eingabe > TPPGTagEdit"):
// Schlagworte eines Support-Tickets. Nur Schlagworte aus einer festen Liste
// (AllowNew = False), Laden und Speichern als ein Datenbankfeld (TagsText,
// Delimiter), Klick auf ein Schlagwort filtert (OnTagClick) und ein
// abgeschlossenes Ticket ist gesperrt (ReadOnly). Die Demo zeigt die
// Abschnitte zwischen den EXAMPLE-Marken als Code an.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.TagEdit, PPG.CheckBox, PPG.Button;

type
  /// Schlagworte eines Tickets: feste Liste, gespeichert als ein Textfeld
  /// "Drucker;Dringend".
  TTicketTags = class(TComponent)
  private
    FPrompt: TPPGLabel;
    FTags: TPPGTagEdit;
    FClosed: TPPGCheckBox;
    FSave: TPPGButton;
    FStatus: TPPGLabel;
    FFieldValue: string;
    FFilter: string;
    procedure TagClick(Sender: TObject; const Tag: string);
    procedure ClosedChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
  public
    constructor CreateTicket(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager;
      const AFieldValue: string);
    property Tags: TPPGTagEdit read FTags;
    property Closed: TPPGCheckBox read FClosed;
    property SaveButton: TPPGButton read FSave;
    /// Inhalt des Datenbankfelds nach dem Speichern.
    property FieldValue: string read FFieldValue;
    /// Zuletzt angeklicktes Schlagwort (Filter der Ticketliste).
    property Filter: string read FFilter;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TTicketTags.CreateTicket(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager; const AFieldValue: string);
begin
  inherited Create(AOwner);

  FPrompt := TPPGLabel.Create(Self);
  FPrompt.Parent := AParent;
  FPrompt.SetBounds(16, 16, 410, 20);
  FPrompt.Caption := '&Schlagworte (nur aus der Liste):';

  // Nur Schlagworte aus Suggestions, damit die Auswertung sauber bleibt
  FTags := TPPGTagEdit.Create(Self);
  FTags.Parent := AParent;
  FTags.SetBounds(16, 40, 410, 32);
  FTags.StyleManager := AStyles;
  FTags.TextHint := 'Schlagwort tippen, z. B. Dru';
  FTags.Suggestions.CommaText := 'Drucker,Netzwerk,Login,Rechnung,Hardware,Software,Dringend';
  FTags.AllowNew := False;
  FTags.Delimiter := ';';
  FTags.OnTagClick := TagClick;
  FPrompt.FocusControl := FTags;
  // Aus der Datenbank laden: TagsText loest keine Ereignisse aus
  FTags.TagsText := AFieldValue;

  FClosed := TPPGCheckBox.Create(Self);
  FClosed.Parent := AParent;
  FClosed.SetBounds(16, 120, 250, 24);
  FClosed.Caption := 'Ticket abgeschlossen';
  FClosed.StyleManager := AStyles;
  FClosed.OnChange := ClosedChange;

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(306, 116, 120, 32);
  FSave.Caption := 'Speichern';
  FSave.StyleManager := AStyles;
  FSave.OnClick := SaveClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 160, 410, 20);
  FStatus.Caption := 'Klicken Sie auf ein Schlagwort, um danach zu filtern.';
end;

procedure TTicketTags.TagClick(Sender: TObject; const Tag: string);
begin
  // Klick auf einen Chip (nicht auf das x): alle Tickets mit diesem Schlagwort
  FFilter := Tag;
  FStatus.Caption := 'Filter: alle Tickets mit "' + Tag + '"';
end;

procedure TTicketTags.ClosedChange(Sender: TObject);
begin
  // Abgeschlossene Tickets: lesen ja, aendern nein
  FTags.ReadOnly := FClosed.Checked;
end;

procedure TTicketTags.SaveClick(Sender: TObject);
begin
  // Ein Textfeld in der Datenbank: "Drucker;Dringend"
  FFieldValue := FTags.TagsText;
  FStatus.Caption := 'Gespeichert: Schlagworte = "' + FFieldValue + '"';
end;
// EXAMPLE-END

end.
