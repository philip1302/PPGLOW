unit ExToggleSwitchFilter;

// Praxisbeispiel 2 zu TPPGToggleSwitch (Demo-Seite "Auswahl > TPPGToggleSwitch"):
// Filter-Schalter ueber einer Auftragsliste. OnChange filtert bei jeder
// Aenderung (auch aus dem Code, z. B. "Filter zuruecksetzen"), OnClick meldet
// nur die Bedienung durch den Anwender.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Menus,
  PPG.StyleManager, PPG.Labels, PPG.Button, PPG.ListBox, PPG.ToggleSwitch;

type
  /// Auftragsliste mit zwei Filter-Schaltern und "Filter zuruecksetzen".
  TOrderFilter = class(TComponent)
  private
    FOnlyOpen: TPPGToggleSwitch;
    FOnlyMine: TPPGToggleSwitch;
    FList: TPPGListBox;
    FReset: TPPGButton;
    FStatus: TPPGLabel;
    FUserChanges: Integer;
    procedure FilterChange(Sender: TObject);
    procedure FilterClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure FillList;
  public
    constructor CreateFilter(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property OnlyOpen: TPPGToggleSwitch read FOnlyOpen;
    property OnlyMine: TPPGToggleSwitch read FOnlyMine;
    property List: TPPGListBox read FList;
    property ResetButton: TPPGButton read FReset;
    /// Wie oft der Anwender einen Filter umgeschaltet hat (nur OnClick).
    property UserChanges: Integer read FUserChanges;
  end;

const
  OrderCount = 6;
  // Beispieldaten: Nummer und Kunde, offen?, Sachbearbeiter
  Orders: array[0..OrderCount - 1] of string = ('A-1001  Becker GmbH',
    'A-1002  Hansa Logistik', 'A-1003  Kaufhaus Nord', 'A-1004  Stadtwerke Ulm',
    'A-1005  Weber Bau KG', 'A-1006  Hotel am Markt');
  OrderOpen: array[0..OrderCount - 1] of Boolean = (True, False, True, True, False, True);
  OrderOwner: array[0..OrderCount - 1] of string = ('Ich', 'Ich', 'Meier', 'Ich',
    'Meier', 'Meier');
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TOrderFilter.CreateFilter(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  // Zwei Filter nebeneinander; Text rechts vom Schalter (Vorgabe)
  FOnlyOpen := TPPGToggleSwitch.Create(Self);
  FOnlyOpen.Parent := AParent;
  FOnlyOpen.SetBounds(16, 16, 200, 28);
  FOnlyOpen.Caption := 'Nur &offene';
  FOnlyOpen.StyleManager := AStyles;
  FOnlyOpen.OnChange := FilterChange;
  FOnlyOpen.OnClick := FilterClick;

  FOnlyMine := TPPGToggleSwitch.Create(Self);
  FOnlyMine.Parent := AParent;
  FOnlyMine.SetBounds(216, 16, 200, 28);
  FOnlyMine.Caption := 'Nur &meine';
  FOnlyMine.StyleManager := AStyles;
  FOnlyMine.OnChange := FilterChange;
  FOnlyMine.OnClick := FilterClick;

  FList := TPPGListBox.Create(Self);
  FList.Parent := AParent;
  FList.SetBounds(16, 56, 400, 172);
  FList.StyleManager := AStyles;

  FReset := TPPGButton.Create(Self);
  FReset.Parent := AParent;
  FReset.SetBounds(16, 240, 180, 32);
  FReset.Caption := 'Filter &zur' + #$00FC + 'cksetzen';
  FReset.StyleManager := AStyles;
  FReset.OnClick := ResetClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 284, 400, 20);
  FStatus.Caption := 'Noch kein Filter vom Anwender umgeschaltet.';

  FillList;
end;

procedure TOrderFilter.FilterChange(Sender: TObject);
begin
  // Jede Aenderung filtert neu: Klick, Leertaste oder Checked := ... im Code
  FillList;
end;

procedure TOrderFilter.FilterClick(Sender: TObject);
begin
  // Nur bei Bedienung durch den Anwender, nicht beim Zuruecksetzen im Code
  Inc(FUserChanges);
  FStatus.Caption := Format('Vom Anwender umgeschaltet: %s (%dx)',
    [StripHotkey(TPPGToggleSwitch(Sender).Caption), FUserChanges]);
end;

procedure TOrderFilter.ResetClick(Sender: TObject);
begin
  // Setzen im Code: OnChange filtert neu, OnClick bleibt still
  FOnlyOpen.Checked := False;
  FOnlyMine.Checked := False;
end;

procedure TOrderFilter.FillList;
var
  I: Integer;
begin
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to OrderCount - 1 do
      if ((not FOnlyOpen.Checked) or OrderOpen[I]) and
        ((not FOnlyMine.Checked) or (OrderOwner[I] = 'Ich')) then
        FList.Items.Add(Orders[I]);
  finally
    FList.Items.EndUpdate;
  end;
end;
// EXAMPLE-END

end.
