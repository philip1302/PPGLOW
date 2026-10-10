unit DemoShowToolBar;

// Komponentenseite TPPGToolBar (Gruppe "Buttons & Aktionen"): Buehne und
// Inspektor kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten
// der Befehlsleiste (Eintraege auf der Buehne, OnItemClick im Protokoll) und
// die beiden Praxisbeispiele (ExToolBarList, ExToolBarActions).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.ToolBar, DemoKit, DemoShowcase, ExToolBarList, ExToolBarActions;

type
  TDemoShowToolBarPage = class(TDemoComponentPage)
  private
    FList: TCustomerListBar;
    FEditor: TNoteEditor;
    procedure SubjectItemClick(Sender: TObject; Item: TPPGToolItem);
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Vcl.Graphics;

const
  // Eintraege auf der Buehne (SetupSubject)
  ItemBold = 4;
  ItemLeft = 7;
  ItemCenter = 8;

function TDemoShowToolBarPage.SubjectClass: TComponentClass;
begin
  Result := TPPGToolBar;
end;

procedure TDemoShowToolBarPage.SetupSubject(ASubject: TComponent);
var
  Bar: TPPGToolBar;
begin
  inherited SetupSubject(ASubject);
  Bar := ASubject as TPPGToolBar;
  // Align = alTop wie aus der Palette: Platz fuer den Buehnen-Hinweis lassen
  Stage.Padding.Top := 60;
  Bar.Items.AddButton('Neu', $E710);
  Bar.Items.AddButton(L('{Oe}ffnen'), $E8E5);
  Bar.Items.AddButton('Speichern', $E74E);
  Bar.Items.AddSeparator;
  Bar.Items.AddCheck('Fett', $E8DD);
  Bar.Items.AddCheck('Kursiv', $E8DB);
  Bar.Items.AddSeparator;
  Bar.Items.AddCheck('Links', $E8E4, 1).Down := True;
  Bar.Items.AddCheck('Mitte', $E8E3, 1);
  Bar.Items.AddCheck('Rechts', $E8E2, 1);
  Bar.Items.AddSeparator;
  Bar.Items.AddButton('Drucken', $E749);
  Bar.Items.AddButton('Exportieren', $EDE1);
  // Eigene Signatur (Sender, Item): wird nicht automatisch protokolliert
  Bar.OnItemClick := SubjectItemClick;
end;

procedure TDemoShowToolBarPage.SubjectItemClick(Sender: TObject; Item: TPPGToolItem);
var
  Detail: string;
begin
  Detail := Format('Item = Items[%d] "%s"', [Item.Index, Item.Caption]);
  if Item.Style = tisCheck then
    Detail := Detail + Format(', Down = %s', [BoolToStr(Item.Down, True)]);
  LogEvent('OnItemClick', Detail);
end;

procedure TDemoShowToolBarPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'ShowCaptions') then
    ACategory := 'Beschriftung & Bild';
end;

procedure TDemoShowToolBarPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Kundenliste', 'ExToolBarList',
    'Eine Befehlsleiste {ue}ber einer Liste: <b>AddButton</b>, <b>AddCheck</b> und '
    + '<b>AddSeparator</b>, ein gemeinsames <b>OnItemClick</b> (Tag = Befehl). Bearbeiten und '
    + 'Entfernen sind ohne Auswahl gesperrt (<b>Enabled</b>). Was nicht in die Breite passt, '
    + 'landet im <b>{...}-Men{ue}</b> am Ende. Probieren Sie: einen Kunden w{ae}hlen und entfernen, '
    + '"Nur aktive" ein- und ausschalten, {ue}ber {...} drucken.');
  FList := TCustomerListBar.CreateList(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Notiz mit Actions', 'ExToolBarActions',
    'Die Eintr{ae}ge h{ae}ngen an <b>Actions</b> (Item.Action): Speichern ist erst nach einer '
    + '{Ae}nderung frei, "Umbruch" ist eine AutoCheck-Action und wird so zum Umschalt-Button. '
    + 'Die Hauptaktion ist hervorgehoben (<b>Color</b>, <b>TextColor</b>, <b>FontStyle</b>). '
    + 'Probieren Sie: Text {ae}ndern und speichern, Umbruch abschalten, "Nur Symbole" '
    + '(<b>ShowCaptions</b>) einschalten und mit der Maus auf ein Symbol zeigen.');
  FEditor := TNoteEditor.CreateEditor(Own, V.Live, DemoStyles);
end;

procedure TDemoShowToolBarPage.SelfTest(Check: TDemoCheck);
var
  Bar: TPPGToolBar;
  Count, Last: Integer;
begin
  inherited SelfTest(Check);
  // Buehne: Klick auf ein Item erscheint als OnItemClick; Gruppe schliesst aus
  ResetSubject;
  Bar := TPPGToolBar(Subject);
  Bar.ClickItem(Bar.Items[ItemCenter]);
  Check('TPPGToolBar: Klick auf "Mitte" erscheint als OnItemClick im Protokoll',
    (EventList.Items.Count > 0) and (Pos('OnItemClick', EventList.Items[0]) > 0) and
    (Pos('Mitte', EventList.Items[0]) > 0));
  Check(L('TPPGToolBar: GroupIndex 1 {-} Mitte eingerastet, Links ausgerastet'),
    Bar.Items[ItemCenter].Down and not Bar.Items[ItemLeft].Down);
  Bar.ClickItem(Bar.Items[ItemCenter]);
  Check('TPPGToolBar: Klick auf den eingerasteten Gruppen-Button l' + #$00E4 + 'sst ihn eingerastet',
    Bar.Items[ItemCenter].Down);
  Count := EventList.Items.Count;
  Bar.Items[ItemBold].Down := True;
  Check('TPPGToolBar: Down per Code l' + #$00F6 + 'st kein Ereignis aus',
    Bar.Items[ItemBold].Down and (EventList.Items.Count = Count) and
    (Pos('Fett', EventList.Items[0]) = 0));
  ResetSubject;

  // Praxisbeispiel 1: Kundenliste
  Check('Beispiel Kundenliste: ohne Auswahl sind Bearbeiten und Entfernen gesperrt',
    (FList.List.ItemIndex = -1) and not FList.EditItem.Enabled and not FList.RemoveItem.Enabled);
  Last := FList.LastCommand;
  FList.ToolBar.ClickItem(FList.RemoveItem);
  Check('Beispiel Kundenliste: gesperrter Befehl l' + #$00F6 + 'st nichts aus',
    (FList.LastCommand = Last) and (FList.List.Items.Count = 5));
  FList.List.ItemIndex := 0;
  FList.UpdateCommands;
  Check('Beispiel Kundenliste: mit Auswahl sind Bearbeiten und Entfernen frei',
    FList.EditItem.Enabled and FList.RemoveItem.Enabled);
  FList.ToolBar.ClickItem(FList.EditItem);
  Check('Beispiel Kundenliste: OnItemClick erkennt den Befehl am Tag',
    FList.LastCommand = cmdEdit);
  FList.ToolBar.ClickItem(FList.RemoveItem);
  Check('Beispiel Kundenliste: Entfernen l' + #$00F6 + 'scht den Kunden und sperrt wieder',
    (FList.List.Items.Count = 4) and (FList.List.Items.IndexOf('Becker & Sohn KG') < 0) and
    not FList.RemoveItem.Enabled);
  FList.ToolBar.ClickItem(FList.ActiveOnly);
  Check('Beispiel Kundenliste: "Nur aktive" rastet ein und filtert',
    FList.ActiveOnly.Down and (FList.List.Items.Count = 2));
  FList.ToolBar.ClickItem(FList.ActiveOnly);
  Check('Beispiel Kundenliste: "Nur aktive" rastet wieder aus',
    (not FList.ActiveOnly.Down) and (FList.List.Items.Count = 4));
  FList.ToolBar.ClickItem(FList.ToolBar.Items[0]);
  Check('Beispiel Kundenliste: Neu legt einen Kunden an',
    (FList.LastCommand = cmdNew) and (FList.List.Items.Count = 5));
  Check('Beispiel Kundenliste: seltene Befehle liegen im ' + #$2026 + '-Men' + #$00FC,
    FList.ToolBar.HasOverflow and FList.ToolBar.IsInOverflow(FList.ToolBar.Items.Count - 1) and
    not FList.ToolBar.IsInOverflow(0));

  // Praxisbeispiel 2: Notiz mit Actions
  Check('Beispiel Notiz: Speichern ohne ' + #$00C4 + 'nderung gesperrt (Action und Item)',
    (not FEditor.SaveAction.Enabled) and not FEditor.ToolBar.Items[0].Enabled);
  Check('Beispiel Notiz: AutoCheck-Action macht "Umbruch" zum eingerasteten Umschalt-Button',
    (FEditor.ToolBar.Items[1].Style = tisCheck) and FEditor.ToolBar.Items[1].Down);
  FEditor.Note.Lines.Text := FEditor.Note.Lines.Text + ' Erledigt.';
  Check('Beispiel Notiz: nach einer ' + #$00C4 + 'nderung ist Speichern frei',
    FEditor.SaveAction.Enabled and FEditor.ToolBar.Items[0].Enabled);
  FEditor.ToolBar.ClickItem(FEditor.ToolBar.Items[0]);
  Check('Beispiel Notiz: Klick auf Speichern f' + #$00FC + 'hrt die Action aus und sperrt wieder',
    (FEditor.SaveCount = 1) and not FEditor.ToolBar.Items[0].Enabled);
  FEditor.ToolBar.ClickItem(FEditor.ToolBar.Items[1]);
  Check('Beispiel Notiz: Umbruch per Klick aus (Action.Checked, Item.Down, Memo.WordWrap)',
    (not FEditor.WordWrapAction.Checked) and (not FEditor.ToolBar.Items[1].Down) and
    not FEditor.Note.WordWrap);
  FEditor.ToolBar.ClickItem(FEditor.ToolBar.Items[1]);
  FEditor.ToolBar.ClickItem(FEditor.IconsOnly);
  Check('Beispiel Notiz: "Nur Symbole" schaltet ShowCaptions ab',
    FEditor.IconsOnly.Down and not FEditor.ToolBar.ShowCaptions);
  FEditor.ToolBar.ClickItem(FEditor.IconsOnly);
  Check('Beispiel Notiz: Hauptaktion mit eigener Fl' + #$00E4 + 'che und Umbruch wieder an',
    (FEditor.ToolBar.Items[0].Color <> clDefault) and FEditor.ToolBar.ShowCaptions and
    FEditor.Note.WordWrap);
end;

initialization
  RegisterShowcasePage('TPPGToolBar', TDemoShowToolBarPage);

end.
