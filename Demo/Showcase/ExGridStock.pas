unit ExGridStock;

// Praxisbeispiel 2 zu TPPGGrid (Demo-Seite "Tabelle > TPPGGrid"):
// Lagerbestand direkt in der Tabelle pflegen: Editoren je Spalte (Auswahl,
// Zahl, Kaestchen), Pruefung der Eingabe (OnValidateCell), Hinweis bei
// wenig Bestand (ConditionalFormats) und Gruppieren nach Kategorie mit
// Summen je Gruppe (GroupBy, GroupFooter, OnGetGroupText).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Grids,
  PPG.StyleManager, PPG.Labels, PPG.CheckBox, PPG.Grid, PPG.Grid.Columns, PPG.Grid.Styles;

const
  // Datenspalten der Bestandsliste
  colItem = 0;
  colCategory = 1;
  colPrice = 2;
  colStock = 3;
  colActive = 4;

type
  /// Bestandsliste zum direkten Bearbeiten: Preis wird geprueft, wenig
  /// Bestand rot markiert, auf Wunsch nach Kategorie gruppiert.
  TStockEditor = class(TComponent)
  private
    FGrid: TPPGGrid;
    FGroup: TPPGCheckBox;
    FStatus: TPPGLabel;
    FChanges: Integer;
    function AddColumn(const ATitle: string; AWidth: Integer;
      AEditor: TPPGGridEditorKind): TPPGGridColumn;
    procedure AddItem(ARow: Integer; const AName, ACategory: string; APrice: Double;
      AStock: Integer; AActive: Boolean);
    procedure GridValidateCell(Sender: TObject; ACol, ARow: Integer; var Value: string;
      var Accept: Boolean);
    procedure GridSetEditText(Sender: TObject; ACol, ARow: Longint; const Value: string);
    procedure GridGetGroupText(Sender: TObject; Group: Integer; var Text: string);
    procedure GroupClick(Sender: TObject);
  public
    constructor CreateEditor(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property Grid: TPPGGrid read FGrid;
    property GroupCheck: TPPGCheckBox read FGroup;
    property Status: TPPGLabel read FStatus;
    /// Anzahl uebernommener Aenderungen.
    property Changes: Integer read FChanges;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TStockEditor.AddColumn(const ATitle: string; AWidth: Integer;
  AEditor: TPPGGridEditorKind): TPPGGridColumn;
begin
  Result := FGrid.Columns.Add;
  Result.Title := ATitle;
  Result.Width := AWidth;
  Result.EditorKind := AEditor;
end;

procedure TStockEditor.AddItem(ARow: Integer; const AName, ACategory: string; APrice: Double;
  AStock: Integer; AActive: Boolean);
begin
  FGrid.Cells[colItem, ARow] := AName;
  FGrid.Cells[colCategory, ARow] := ACategory;
  FGrid.Cells[colPrice, ARow] := FormatFloat('#,##0.00', APrice);
  FGrid.Cells[colStock, ARow] := IntToStr(AStock);
  // Kaestchen-Spalten speichern '1' bzw. '0'
  FGrid.Cells[colActive, ARow] := IntToStr(Ord(AActive));
end;

constructor TStockEditor.CreateEditor(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Col: TPPGGridColumn;
  Rule: TPPGGridConditionalFormat;
begin
  inherited Create(AOwner);
  FGrid := TPPGGrid.Create(Self);
  FGrid.Parent := AParent;
  FGrid.SetBounds(16, 16, 418, 268);
  FGrid.StyleManager := AStyles;
  FGrid.FixedCols := 0;
  // Bearbeiten: Doppelklick, F2 oder einfach lostippen; Tab springt weiter
  FGrid.Options := FGrid.Options + [goEditing, goTabs];
  FGrid.GroupFooter := True;                  // Summen unter jeder Gruppe

  Col := AddColumn('Artikel', 130, gekText);
  Col.ReadOnly := True;                       // Stammdaten nicht hier aendern
  Col := AddColumn('Kategorie', 84, gekCombo);
  Col.PickList.CommaText := 'Technik,Papier,Versand';
  Col := AddColumn('Preis', 72, gekText);
  Col.Alignment := taRightJustify;
  Col := AddColumn('Bestand', 68, gekSpin);
  Col.Alignment := taRightJustify;
  Col.MinValue := 0;
  Col.MaxValue := 999;
  Col.Aggregate := agSum;                     // Summe im Gruppenfuss
  Col := AddColumn('Aktiv', 52, gekCheck);
  Col.CellKind := ckCheck;                    // Kaestchen statt 1/0
  Col.TitleAlignment := gtaCenter;

  // Wenig Bestand (0 bis 9): rot hinterlegt und fett, ohne eigenen Zeichencode
  Rule := FGrid.ConditionalFormats.Add;
  Rule.Column := colStock;
  Rule.Rule := crRange;
  Rule.Value1 := '0';
  Rule.Value2 := '9';
  Rule.Color := ccDanger;
  Rule.Bold := True;

  FGrid.RowCount := 1 + 7;
  AddItem(1, 'Laptop 14"', 'Technik', 899, 12, True);
  AddItem(2, 'Monitor 27"', 'Technik', 279, 4, True);
  AddItem(3, 'Dockingstation', 'Technik', 189, 0, False);
  AddItem(4, 'Kopierpapier A4', 'Papier', 4.99, 250, True);
  AddItem(5, 'Briefumschlag C4', 'Versand', 0.12, 750, True);
  AddItem(6, 'Notizblock A5', 'Papier', 1.49, 7, True);
  AddItem(7, 'Versandkarton M', 'Versand', 0.89, 320, True);

  FGrid.OnValidateCell := GridValidateCell;
  FGrid.OnSetEditText := GridSetEditText;
  FGrid.OnGetGroupText := GridGetGroupText;

  FGroup := TPPGCheckBox.Create(Self);
  FGroup.Parent := AParent;
  FGroup.SetBounds(16, 296, 260, 24);
  FGroup.Caption := 'Nach &Kategorie gruppieren';
  FGroup.StyleManager := AStyles;
  FGroup.OnClick := GroupClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 330, 418, 20);
  FStatus.Caption := 'Doppelklick auf Preis oder Bestand zum Bearbeiten.';
end;

procedure TStockEditor.GridValidateCell(Sender: TObject; ACol, ARow: Integer;
  var Value: string; var Accept: Boolean);
var
  Price: Double;
begin
  // Vor dem Uebernehmen pruefen; Accept = False laesst den Editor offen
  if ACol <> colPrice then
    Exit;
  Accept := TryStrToFloat(Trim(Value), Price) and (Price > 0);
  if Accept then
    Value := FormatFloat('#,##0.00', Price)   // einheitlich formatieren
  else
    FStatus.Caption := 'Bitte einen Preis gr' + #$00F6 + #$00DF + 'er 0 eingeben.';
end;

procedure TStockEditor.GridSetEditText(Sender: TObject; ACol, ARow: Longint;
  const Value: string);
begin
  // Der neue Wert steht in der Zelle: hier z. B. in die Datenbank schreiben
  Inc(FChanges);
  FStatus.Caption := Format('%s: %s = %s', [FGrid.Cells[colItem, ARow],
    FGrid.Columns[ACol].Title, Value]);
end;

procedure TStockEditor.GridGetGroupText(Sender: TObject; Group: Integer; var Text: string);
var
  Info: TPPGGridGroupInfo;
begin
  Info := FGrid.GroupInfo(Group);
  Text := Format('<b>%s</b>  (%d Artikel)', [Info.Key, Info.Count]);
end;

procedure TStockEditor.GroupClick(Sender: TObject);
begin
  if FGroup.Checked then
    FGrid.GroupBy([colCategory])
  else
    FGrid.Ungroup;
end;
// EXAMPLE-END

end.
