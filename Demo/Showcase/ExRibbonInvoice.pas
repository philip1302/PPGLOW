unit ExRibbonInvoice;

// Praxisbeispiel 1 zu TPPGRibbon (Demo-Seite "Buttons & Aktionen > TPPGRibbon"):
// Menueband einer Belegerfassung mit Registerkarten, Gruppen, grossen und
// kleinen Befehlen, Split-Button (DropDownMenu), Umschalter (rikCheck),
// Schnellzugriff, "Datei"-Menue (ApplicationMenu) und einer zentralen
// Befehlsbehandlung in OnItemClick ueber Item.Tag.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Menus,
  PPG.StyleManager, PPG.Labels, PPG.Memo, PPG.Menus,
  PPG.Ribbon.Layout, PPG.Ribbon.Items, PPG.Ribbon;

const
  // Befehls-IDs in Item.Tag: ein Handler (OnItemClick) fuer alle Befehle
  cmdNew = 1;
  cmdSave = 2;
  cmdPrint = 3;
  cmdGross = 4;
  cmdArticle = 5;
  cmdDiscount = 6;

type
  /// Belegerfassung: Menueband ueber dem Beleg. Speichern geht nur, wenn
  /// der Beleg geaendert wurde; der Schnellzugriff wirkt auf denselben Befehl.
  TInvoiceRibbon = class(TComponent)
  private
    FRibbon: TPPGRibbon;
    FFileMenu: TPPGPopupMenu;
    FPrintMenu: TPPGPopupMenu;
    FSave: TPPGRibbonItem;
    FPrint: TPPGRibbonItem;
    FGross: TPPGRibbonItem;
    FText: TPPGMemo;
    FStatus: TPPGLabel;
    FLastCommand: string;
    function NewMenu(const ACaptions: array of string; AOnClick: TNotifyEvent): TPPGPopupMenu;
    procedure RibbonItemClick(Sender: TObject; Item: TPPGRibbonItem);
    procedure PrintMenuClick(Sender: TObject);
    procedure TextChange(Sender: TObject);
    procedure Done(const ACommand: string);
  public
    constructor CreateRibbon(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property Ribbon: TPPGRibbon read FRibbon;
    property SaveItem: TPPGRibbonItem read FSave;
    property PrintItem: TPPGRibbonItem read FPrint;
    property GrossItem: TPPGRibbonItem read FGross;
    property PrintMenu: TPPGPopupMenu read FPrintMenu;
    property Text: TPPGMemo read FText;
    property LastCommand: string read FLastCommand;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TInvoiceRibbon.NewMenu(const ACaptions: array of string;
  AOnClick: TNotifyEvent): TPPGPopupMenu;
var
  I: Integer;
begin
  Result := TPPGPopupMenu.Create(Self);
  Result.StyleManager := FRibbon.StyleManager;
  for I := 0 to High(ACaptions) do
    Result.Items.Add(NewItem(ACaptions[I], 0, False, True, AOnClick, 0, ''));
end;

constructor TInvoiceRibbon.CreateRibbon(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Tab: TPPGRibbonTab;
  Group: TPPGRibbonGroup;
  Item: TPPGRibbonItem;
begin
  inherited Create(AOwner);
  FRibbon := TPPGRibbon.Create(Self);
  FRibbon.Parent := AParent;            // Align = alTop ist die Vorgabe
  FRibbon.StyleManager := AStyles;
  FRibbon.OnItemClick := RibbonItemClick;

  // "Datei": ein einfaches Menue statt eines Backstage-Bereichs
  FFileMenu := NewMenu(['Neuer Beleg', 'Beleg laden ...', 'Beenden'], nil);
  FRibbon.ApplicationMenu := FFileMenu;

  // Karte "Beleg": die haeufigsten Befehle gross
  Tab := FRibbon.Tabs.AddTab('Beleg');
  Group := Tab.Groups.AddGroup('Bearbeiten');
  Group.Items.AddButton('Neu', $E710).Tag := cmdNew;
  FSave := Group.Items.AddButton('Speichern', $E74E);
  FSave.Tag := cmdSave;
  FSave.Hint := 'Speichert den Beleg (Strg+S)';
  FSave.KeyTip := 'S';
  FSave.Enabled := False;               // erst nach einer Aenderung

  // Split-Button: Hauptteil druckt, der Pfeil bietet die Varianten an
  FPrintMenu := NewMenu(['Drucken', 'Vorschau', 'Als PDF'], PrintMenuClick);
  FPrint := Group.Items.AddButton('Drucken', $E749);
  FPrint.Kind := rikSplitButton;
  FPrint.DropDownMenu := FPrintMenu;
  FPrint.Tag := cmdPrint;

  // Umschalter: rikCheck rastet bei jedem Klick ein bzw. aus
  Group := Tab.Groups.AddGroup('Ansicht');
  FGross := Group.Items.AddCheck('Bruttopreise', $E8EF, rsMedium);
  FGross.Tag := cmdGross;

  // Zweite Karte mit Befehlen fuer die Positionen
  Tab := FRibbon.Tabs.AddTab('Positionen');
  Group := Tab.Groups.AddGroup('Position');
  Group.Items.AddButton('Artikel', $E710).Tag := cmdArticle;
  Item := Group.Items.AddButton('Rabatt', $E8C7, rsMedium);
  Item.Tag := cmdDiscount;
  Item.Hint := 'Rabatt auf die markierte Position';

  // Schnellzugriff: wirkt auf den Befehl im Band (gleiche Beschriftung/Symbol)
  FRibbon.AddToQuickAccess(FSave);

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.Align := alBottom;
  FStatus.AlignWithMargins := True;
  FStatus.Margins.SetBounds(16, 4, 16, 8);
  FStatus.Caption := 'Bereit.';

  FText := TPPGMemo.Create(Self);
  FText.Parent := AParent;
  FText.Align := alClient;
  FText.AlignWithMargins := True;
  FText.Margins.SetBounds(16, 8, 16, 0);
  FText.StyleManager := AStyles;
  FText.Lines.Text := 'Rechnung 2026-0142, Mueller GmbH' + sLineBreak +
    'Pos. 1: Wartung Server, 2 Std., 180,00 EUR' + sLineBreak +
    'Pos. 2: Anfahrt, pauschal, 45,00 EUR';
  FText.OnChange := TextChange;
end;

procedure TInvoiceRibbon.RibbonItemClick(Sender: TObject; Item: TPPGRibbonItem);
begin
  // Ein Handler fuer alle Befehle: die Befehls-ID steht in Item.Tag
  case Item.Tag of
    cmdNew: Done('Neuer Beleg');
    cmdSave:
      begin
        FSave.Enabled := False;         // gespeichert: nichts mehr zu tun
        Done('Gespeichert');
      end;
    cmdPrint: Done('Gedruckt');
    cmdGross:
      if FGross.Down then
        Done('Preise brutto')
      else
        Done('Preise netto');
    cmdArticle: Done('Artikel eingefuegt');
    cmdDiscount: Done('Rabatt gewaehrt');
  end;
end;

procedure TInvoiceRibbon.PrintMenuClick(Sender: TObject);
begin
  case TMenuItem(Sender).MenuIndex of
    0: Done('Gedruckt');
    1: Done('Vorschau');
  else
    Done('Als PDF');
  end;
end;

procedure TInvoiceRibbon.TextChange(Sender: TObject);
begin
  // Was gerade nicht geht, sperren statt eine Meldung zu zeigen
  FSave.Enabled := True;
end;

procedure TInvoiceRibbon.Done(const ACommand: string);
begin
  FLastCommand := ACommand;
  FStatus.Caption := ACommand + '.';
end;
// EXAMPLE-END

end.
