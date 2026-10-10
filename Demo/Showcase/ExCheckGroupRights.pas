unit ExCheckGroupRights;

// Praxisbeispiel 2 zu TPPGCheckGroup (Demo-Seite "Auswahl > TPPGCheckGroup"):
// Rechte einer Benutzerrolle als Kacheln (ChoiceStyle = csCards) mit
// Symbol und Beschreibung. AllowGrayed liefert den dritten Zustand
// "nur lesen"; OnItemClick meldet, welche Kachel umgeschaltet wurde.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.StdCtrls,
  PPG.StyleManager, PPG.Labels, PPG.Button, PPG.RadioGroup;

type
  /// Rechte der Rolle "Vertrieb" je Modul: Haken = bearbeiten,
  /// grau = nur lesen, leer = kein Zugriff.
  TRoleRights = class(TComponent)
  private
    FModules: TPPGCheckGroup;
    FReadOnlyAll: TPPGButton;
    FLastChange: TPPGLabel;
    FSummary: TPPGLabel;
    procedure ModuleItemClick(Sender: TObject; Index: Integer);
    procedure ModulesChange(Sender: TObject);
    procedure ReadOnlyAllClick(Sender: TObject);
    procedure UpdateSummary;
  public
    constructor CreateRights(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    /// Recht eines Moduls als Text: 'bearbeiten', 'nur lesen' oder 'kein Zugriff'.
    function RightOf(Index: Integer): string;
    property Modules: TPPGCheckGroup read FModules;
    property ReadOnlyAllButton: TPPGButton read FReadOnlyAll;
    property LastChange: TPPGLabel read FLastChange;
    property Summary: TPPGLabel read FSummary;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TRoleRights.CreateRights(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);

  procedure AddModule(const ACaption, ADescription: string; AIcon: Word;
    AState: TCheckBoxState);
  var
    Item: TPPGChoiceItem;
  begin
    Item := FModules.ItemsEx.Add;
    Item.Caption := ACaption;
    Item.Description := ADescription;
    Item.Icon := AIcon;          // Zeichen der Symbolschrift (Segoe Fluent Icons)
    Item.State := AState;
  end;

begin
  inherited Create(AOwner);

  FModules := TPPGCheckGroup.Create(Self);
  FModules.Parent := AParent;
  FModules.SetBounds(16, 16, 418, 192);
  FModules.Caption := 'Rechte der Rolle "Vertrieb"';
  FModules.ChoiceStyle := csCards;
  FModules.Columns := 2;
  // Dritter Zustand: Klick wechselt aus -> bearbeiten -> nur lesen -> aus
  FModules.AllowGrayed := True;
  FModules.StyleManager := AStyles;
  FModules.BeginUpdate;
  try
    AddModule('Kunden', 'Adressen und Kontakte', $E716, cbChecked);
    AddModule('Angebote', 'Angebote erstellen', $E8A5, cbChecked);
    AddModule('Rechnungen', 'Rechnungen und Mahnungen', $E8C7, cbGrayed);
    AddModule('Berichte', 'Umsatz und Auswertungen', $E9D2, cbUnchecked);
  finally
    FModules.EndUpdate;
  end;
  FModules.OnItemClick := ModuleItemClick;
  FModules.OnChange := ModulesChange;

  FReadOnlyAll := TPPGButton.Create(Self);
  FReadOnlyAll.Parent := AParent;
  FReadOnlyAll.SetBounds(16, 220, 150, 32);
  FReadOnlyAll.Caption := 'Alles nur lesen';
  FReadOnlyAll.StyleManager := AStyles;
  FReadOnlyAll.OnClick := ReadOnlyAllClick;

  FLastChange := TPPGLabel.Create(Self);
  FLastChange.Parent := AParent;
  FLastChange.SetBounds(180, 226, 254, 20);
  FLastChange.Caption := 'Noch nichts geaendert.';

  FSummary := TPPGLabel.Create(Self);
  FSummary.Parent := AParent;
  FSummary.SetBounds(16, 264, 418, 20);
  UpdateSummary;
end;

function TRoleRights.RightOf(Index: Integer): string;
begin
  case FModules.ItemState[Index] of
    cbChecked: Result := 'bearbeiten';
    cbGrayed: Result := 'nur lesen';
  else
    Result := 'kein Zugriff';
  end;
end;

procedure TRoleRights.ModuleItemClick(Sender: TObject; Index: Integer);
begin
  // Index nennt die Kachel; der neue Zustand ist schon gesetzt
  FLastChange.Caption := FModules.Items[Index] + ': ' + RightOf(Index);
end;

procedure TRoleRights.ModulesChange(Sender: TObject);
begin
  UpdateSummary;
end;

procedure TRoleRights.ReadOnlyAllClick(Sender: TObject);
var
  I: Integer;
begin
  // Im Code gesetzt: kein OnItemClick/OnChange, deshalb selbst aktualisieren
  FModules.BeginUpdate;
  try
    for I := 0 to FModules.Items.Count - 1 do
      FModules.ItemState[I] := cbGrayed;
  finally
    FModules.EndUpdate;
  end;
  FLastChange.Caption := 'Alle Module: nur lesen';
  UpdateSummary;
end;

procedure TRoleRights.UpdateSummary;
begin
  // Value enthaelt nur die angehakten Eintraege (nicht die grauen)
  if FModules.Value = '' then
    FSummary.Caption := 'Bearbeiten: keine Module'
  else
    FSummary.Caption := 'Bearbeiten: ' + FModules.Value;
end;
// EXAMPLE-END

end.
