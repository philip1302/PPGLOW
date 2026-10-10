unit ExMemoHistory;

// Praxisbeispiel 2 zu TPPGMemo (Demo-Seite "Eingabe > TPPGMemo"):
// Verlauf eines Service-Tickets als schreibgeschuetztes Memo (ReadOnly,
// ReadOnlyStyle). Neue Eintraege kommen ueber Lines.Add dazu; ein Schalter
// wechselt zwischen Umbruch (WordWrap) und waagerechtem Scrollen (ScrollBars).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls, System.UITypes,
  PPG.StyleManager, PPG.Edit, PPG.Memo, PPG.Button, PPG.CheckBox;

type
  /// Verlauf eines Tickets: lesen, markieren und kopieren ja, aendern nein.
  /// Neue Eintraege kommen nur ueber das Eingabefeld dazu.
  TTicketHistory = class(TComponent)
  private
    FEntry: TPPGEdit;
    FAdd: TPPGButton;
    FHistory: TPPGMemo;
    FWrap: TPPGCheckBox;
    FClear: TPPGButton;
    procedure EntryChange(Sender: TObject);
    procedure AddClick(Sender: TObject);
    procedure WrapChange(Sender: TObject);
    procedure ClearClick(Sender: TObject);
  public
    constructor CreateHistory(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    procedure AddEntry(const AText: string);
    property Entry: TPPGEdit read FEntry;
    property AddButton: TPPGButton read FAdd;
    property History: TPPGMemo read FHistory;
    property WrapBox: TPPGCheckBox read FWrap;
    property ClearButton: TPPGButton read FClear;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TTicketHistory.CreateHistory(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  FEntry := TPPGEdit.Create(Self);
  FEntry.Parent := AParent;
  FEntry.SetBounds(16, 16, 296, 32);
  FEntry.StyleManager := AStyles;
  FEntry.TextHint := 'Neuer Eintrag, z. B. Kunde informiert';
  FEntry.OnChange := EntryChange;

  FAdd := TPPGButton.Create(Self);
  FAdd.Parent := AParent;
  FAdd.SetBounds(324, 16, 110, 32);
  FAdd.Caption := 'Eintragen';
  FAdd.StyleManager := AStyles;
  FAdd.Enabled := False;  // erst mit Text
  FAdd.OnClick := AddClick;

  // Der Verlauf: ReadOnly erlaubt Lesen, Markieren und Kopieren.
  // ReadOnlyStyle zeigt mit grauer Flaeche, dass hier niemand tippt.
  FHistory := TPPGMemo.Create(Self);
  FHistory.Parent := AParent;
  FHistory.SetBounds(16, 60, 418, 128);
  FHistory.StyleManager := AStyles;
  FHistory.ReadOnly := True;
  FHistory.ReadOnlyStyle.Color := $00F3F3F3;
  FHistory.ReadOnlyStyle.DarkColor := $00303030;
  FHistory.Font.Name := 'Consolas';
  FHistory.ScrollBars := ssVertical;
  FHistory.WordWrap := True;
  // Viele Zeilen auf einmal: BeginUpdate verhindert Flackern
  FHistory.Lines.BeginUpdate;
  try
    FHistory.Lines.Add('02.10.2026 09:12  Ticket angelegt: Drucker im Lager druckt nicht');
    FHistory.Lines.Add('02.10.2026 09:40  Ferndiagnose: Treiber veraltet, Update eingespielt');
    FHistory.Lines.Add('03.10.2026 14:05  Kunde meldet: Ausdrucke wieder in Ordnung');
  finally
    FHistory.Lines.EndUpdate;
  end;

  FWrap := TPPGCheckBox.Create(Self);
  FWrap.Parent := AParent;
  FWrap.SetBounds(16, 200, 250, 24);
  FWrap.Caption := 'Lange Zeilen umbrechen';
  FWrap.Checked := True;
  FWrap.OnChange := WrapChange;

  FClear := TPPGButton.Create(Self);
  FClear.Parent := AParent;
  FClear.SetBounds(324, 196, 110, 32);
  FClear.Caption := 'Leeren';
  FClear.StyleManager := AStyles;
  FClear.OnClick := ClearClick;
end;

procedure TTicketHistory.EntryChange(Sender: TObject);
begin
  FAdd.Enabled := Trim(FEntry.Text) <> '';
end;

procedure TTicketHistory.AddEntry(const AText: string);
begin
  // Lines.Add haengt hinten an und scrollt die neue Zeile ins Bild -
  // auch bei ReadOnly, das sperrt nur den Anwender
  FHistory.Lines.Add(FormatDateTime('dd.mm.yyyy hh:nn', Now) + '  ' + AText);
  FClear.Enabled := True;
end;

procedure TTicketHistory.AddClick(Sender: TObject);
begin
  AddEntry(Trim(FEntry.Text));
  FEntry.Text := '';
end;

procedure TTicketHistory.WrapChange(Sender: TObject);
begin
  // Mit Umbruch reicht die senkrechte Leiste; ohne Umbruch werden lange
  // Zeilen waagerecht gescrollt
  FHistory.WordWrap := FWrap.Checked;
  if FWrap.Checked then
    FHistory.ScrollBars := ssVertical
  else
    FHistory.ScrollBars := ssBoth;
end;

procedure TTicketHistory.ClearClick(Sender: TObject);
begin
  FHistory.Lines.Clear;
  FClear.Enabled := False;
end;
// EXAMPLE-END

end.
