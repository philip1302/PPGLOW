unit ExToolBarList;

// Praxisbeispiel 1 zu TPPGToolBar (Demo-Seite "Buttons & Aktionen > TPPGToolBar"):
// Befehlsleiste ueber einer Kundenliste. Buttons, Umschalt-Button und Trenner
// per AddButton/AddCheck/AddSeparator, ein gemeinsames OnItemClick (Tag als
// Befehls-ID), Enabled je nach Auswahl und der Ueberlauf ("..."-Menue), wenn
// die Leiste zu schmal ist.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.ListBox, PPG.ToolBar;

const
  cmdNew = 1;
  cmdEdit = 2;
  cmdRemove = 3;
  cmdActiveOnly = 4;
  cmdRefresh = 5;
  cmdPrint = 6;
  cmdExport = 7;

type
  /// Kundenliste mit Befehlsleiste: Neu, Bearbeiten, Entfernen, Filter
  /// "Nur aktive" und seltene Befehle, die bei wenig Platz ins "..."-Menue
  /// wandern.
  TCustomerListBar = class(TComponent)
  private
    FCustomers: TStringList;   // Name, Objects[] <> nil = aktiv
    FToolBar: TPPGToolBar;
    FList: TPPGListBox;
    FStatus: TPPGLabel;
    FEditItem: TPPGToolItem;
    FRemoveItem: TPPGToolItem;
    FActiveOnly: TPPGToolItem;
    FLastCommand: Integer;
    procedure ToolItemClick(Sender: TObject; Item: TPPGToolItem);
    procedure ListClick(Sender: TObject);
    procedure FillList;
  public
    constructor CreateList(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    destructor Destroy; override;
    /// Bearbeiten/Entfernen nur mit Auswahl.
    procedure UpdateCommands;
    property ToolBar: TPPGToolBar read FToolBar;
    property List: TPPGListBox read FList;
    property EditItem: TPPGToolItem read FEditItem;
    property RemoveItem: TPPGToolItem read FRemoveItem;
    property ActiveOnly: TPPGToolItem read FActiveOnly;
    property LastCommand: Integer read FLastCommand;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TCustomerListBar.CreateList(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FCustomers := TStringList.Create;
  FCustomers.AddObject('Becker & Sohn KG', TObject(1));
  FCustomers.AddObject('Nordlicht Logistik', TObject(1));
  FCustomers.AddObject('Schmidt Elektro', nil);
  FCustomers.AddObject('Weber Bau GmbH', TObject(1));
  FCustomers.AddObject('Zimmermann Druck', nil);

  // Die Leiste: Symbol aus der Symbolschrift (IconChar), Text daneben.
  // Tag ist die Befehls-ID fuer das gemeinsame OnItemClick.
  FToolBar := TPPGToolBar.Create(Self);
  FToolBar.Parent := AParent;
  FToolBar.Align := alNone;               // Vorgabe ist alTop
  FToolBar.SetBounds(16, 16, 418, 40);
  FToolBar.StyleManager := AStyles;
  FToolBar.ShowHint := True;
  FToolBar.Items.AddButton('Neu', $E710).Tag := cmdNew;
  FEditItem := FToolBar.Items.AddButton('Bearbeiten', $E70F);
  FEditItem.Tag := cmdEdit;
  FRemoveItem := FToolBar.Items.AddButton('Entfernen', $E74D);
  FRemoveItem.Tag := cmdRemove;
  FRemoveItem.Hint := 'Kunden aus der Liste entfernen (Entf)';
  FToolBar.Items.AddSeparator;
  // Umschalt-Button ohne Gruppe: rastet ein und wieder aus
  FActiveOnly := FToolBar.Items.AddCheck('Nur aktive', $E71C);
  FActiveOnly.Tag := cmdActiveOnly;
  FToolBar.Items.AddSeparator;
  // Seltene Befehle stehen hinten: Sie wandern zuerst ins "..."-Menue
  FToolBar.Items.AddButton('Aktualisieren', $E72C).Tag := cmdRefresh;
  FToolBar.Items.AddButton('Drucken', $E749).Tag := cmdPrint;
  FToolBar.Items.AddButton('Exportieren', $EDE1).Tag := cmdExport;
  FToolBar.OnItemClick := ToolItemClick;

  FList := TPPGListBox.Create(Self);
  FList.Parent := AParent;
  FList.SetBounds(16, 64, 418, 150);
  FList.StyleManager := AStyles;
  FList.OnClick := ListClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 224, 418, 20);
  FStatus.Caption := 'Bereit.';

  FillList;
end;

destructor TCustomerListBar.Destroy;
begin
  FCustomers.Free;
  inherited Destroy;
end;

procedure TCustomerListBar.FillList;
var
  I: Integer;
begin
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to FCustomers.Count - 1 do
      if not FActiveOnly.Down or (FCustomers.Objects[I] <> nil) then
        FList.Items.Add(FCustomers[I]);
  finally
    FList.Items.EndUpdate;
  end;
  UpdateCommands;
end;

procedure TCustomerListBar.UpdateCommands;
begin
  // Was ohne Auswahl nicht geht, wird gesperrt statt eine Meldung zu zeigen
  FEditItem.Enabled := FList.ItemIndex >= 0;
  FRemoveItem.Enabled := FList.ItemIndex >= 0;
end;

procedure TCustomerListBar.ListClick(Sender: TObject);
begin
  UpdateCommands;
end;

procedure TCustomerListBar.ToolItemClick(Sender: TObject; Item: TPPGToolItem);
var
  Name: string;
begin
  // Ein Handler fuer alle Befehle; Down ist bei Umschalt-Buttons schon umgeschaltet
  FLastCommand := Item.Tag;
  Name := '';
  if FList.ItemIndex >= 0 then
    Name := FList.Items[FList.ItemIndex];
  case Item.Tag of
    cmdNew:
      begin
        FCustomers.AddObject(Format('Neuer Kunde %d', [FCustomers.Count + 1]), TObject(1));
        FillList;
        FStatus.Caption := 'Kunde angelegt.';
      end;
    cmdEdit:
      FStatus.Caption := 'Bearbeiten: ' + Name;
    cmdRemove:
      begin
        FCustomers.Delete(FCustomers.IndexOf(Name));
        FillList;
        FStatus.Caption := 'Entfernt: ' + Name;
      end;
    cmdActiveOnly:
      begin
        FillList;
        FStatus.Caption := Format('%d Kunden angezeigt.', [FList.Items.Count]);
      end;
    cmdRefresh:
      begin
        FillList;
        FStatus.Caption := 'Liste aktualisiert.';
      end;
    cmdPrint:
      FStatus.Caption := 'Kundenliste gedruckt.';
    cmdExport:
      FStatus.Caption := 'Kundenliste exportiert.';
  end;
end;
// EXAMPLE-END

end.
