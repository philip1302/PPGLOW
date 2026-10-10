unit ExCheckComboBoxFilter;

// Praxisbeispiel 1 zu TPPGCheckComboBox (Demo-Seite "Auswahl > TPPGCheckComboBox"):
// Filterleiste ueber einer Kundenliste. Zwei Mehrfachfilter (Status mit
// "Alle auswaehlen", Region mit Filterzeile), die Liste folgt bei jedem Haken.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.Button, PPG.ListBox, PPG.CheckComboBox;

type
  /// Kundenliste mit zwei Filtern: Status und Region. Ohne Haken gilt ein
  /// Filter als "alle".
  TCustomerFilter = class(TComponent)
  private
    FStatus: TPPGCheckComboBox;
    FRegion: TPPGCheckComboBox;
    FList: TPPGListBox;
    FCount: TPPGLabel;
    FReset: TPPGButton;
    function NewCombo(AParent: TWinControl; X: Integer; const ACaption,
      AHint: string): TPPGCheckComboBox;
    function Matches(AFilter: TPPGCheckComboBox; const AValue: string): Boolean;
    procedure FilterChange(Sender: TObject);
    procedure ResetClick(Sender: TObject);
  public
    constructor CreateFilter(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    /// Liste nach den Haken neu fuellen.
    procedure ApplyFilter;
    property StatusFilter: TPPGCheckComboBox read FStatus;
    property RegionFilter: TPPGCheckComboBox read FRegion;
    property CustomerList: TPPGListBox read FList;
    property ResetButton: TPPGButton read FReset;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  // Kundenstamm: Name, Status, Region
  Customers: array[0..9, 0..2] of string = (
    ('Albers GmbH', 'Aktiv', 'Bayern'),
    ('Brandt & Co.', 'Aktiv', 'Hamburg'),
    ('Claasen KG', 'Interessent', 'Bayern'),
    ('Dorn Logistik', 'Gesperrt', 'Hessen'),
    ('Eckert AG', 'Aktiv', 'Sachsen'),
    ('Fuchs Bau', 'Inaktiv', 'Hessen'),
    ('Gerber Technik', 'Interessent', 'Berlin'),
    ('Hahn Moebel', 'Aktiv', 'Berlin'),
    ('Ilg Druck', 'Gesperrt', 'Bayern'),
    ('Jung Medien', 'Inaktiv', 'Hamburg'));

function TCustomerFilter.NewCombo(AParent: TWinControl; X: Integer;
  const ACaption, AHint: string): TPPGCheckComboBox;
var
  Lbl: TPPGLabel;
begin
  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(X, 16, 200, 20);
  Lbl.Caption := ACaption;

  Result := TPPGCheckComboBox.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(X, 40, 200, 32);
  Result.TextHint := AHint;          // erscheint, solange nichts angehakt ist
  Result.OnChange := FilterChange;   // jeder Haken wirkt sofort
  Lbl.FocusControl := Result;
end;

constructor TCustomerFilter.CreateFilter(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  // Status: wenige Werte, "Alle auswaehlen" als erste Zeile
  FStatus := NewCombo(AParent, 16, '&Status:', 'Alle Status');
  FStatus.Items.CommaText := 'Aktiv,Interessent,Inaktiv,Gesperrt';
  FStatus.ShowSelectAll := True;
  FStatus.StyleManager := AStyles;

  // Region: viele Werte. Ab FilterThreshold Eintraegen zeigt die Liste eine
  // Filterzeile; die Anzeige nennt nur die Zahl ("3 ausgewaehlt").
  FRegion := NewCombo(AParent, 230, '&Region:', 'Alle Regionen');
  FRegion.Items.CommaText := 'Bayern,Berlin,Brandenburg,Bremen,Hamburg,Hessen,' +
    'Mecklenburg-Vorpommern,Niedersachsen,Nordrhein-Westfalen,Rheinland-Pfalz,' +
    'Saarland,Sachsen,Sachsen-Anhalt,Schleswig-Holstein';
  FRegion.FilterThreshold := 10;
  FRegion.DropDownCount := 8;
  FRegion.DisplayMode := cdmCount;
  FRegion.StyleManager := AStyles;

  FList := TPPGListBox.Create(Self);
  FList.Parent := AParent;
  FList.SetBounds(16, 84, 414, 150);
  FList.StyleManager := AStyles;

  FCount := TPPGLabel.Create(Self);
  FCount.Parent := AParent;
  FCount.SetBounds(16, 252, 260, 20);

  FReset := TPPGButton.Create(Self);
  FReset.Parent := AParent;
  FReset.SetBounds(290, 246, 140, 32);
  FReset.Caption := 'Alle anzeigen';
  FReset.StyleManager := AStyles;
  FReset.OnClick := ResetClick;

  ApplyFilter;
end;

function TCustomerFilter.Matches(AFilter: TPPGCheckComboBox; const AValue: string): Boolean;
var
  I: Integer;
begin
  // Kein Haken = Filter aus
  if AFilter.CheckedCount = 0 then
    Exit(True);
  I := AFilter.Items.IndexOf(AValue);
  Result := (I >= 0) and AFilter.Checked[I];
end;

procedure TCustomerFilter.ApplyFilter;
var
  I: Integer;
begin
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to High(Customers) do
      if Matches(FStatus, Customers[I, 1]) and Matches(FRegion, Customers[I, 2]) then
        FList.Items.Add(Customers[I, 0] + '  (' + Customers[I, 1] + ', ' + Customers[I, 2] + ')');
  finally
    FList.Items.EndUpdate;
  end;
  FCount.Caption := Format('%d von %d Kunden', [FList.Items.Count, Length(Customers)]);
  FReset.Enabled := (FStatus.CheckedCount > 0) or (FRegion.CheckedCount > 0);
end;

procedure TCustomerFilter.FilterChange(Sender: TObject);
begin
  ApplyFilter;
end;

procedure TCustomerFilter.ResetClick(Sender: TObject);
begin
  // Aus Code: CheckAll loest kein OnChange aus, deshalb selbst neu filtern
  FStatus.CheckAll(False);
  FRegion.CheckAll(False);
  ApplyFilter;
end;
// EXAMPLE-END

end.
