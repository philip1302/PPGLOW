unit DemoPages2;

{ Demo-Seiten "Listen", "Explorer", "Tabelle", "Termine". }

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.DateUtils, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Grids, Vcl.ComCtrls,
  PPG.Types, PPG.Controls.Base, PPG.Button, PPG.Panel, PPG.Labels, PPG.Items,
  PPG.Controls.Field, PPG.Edit, PPG.SpinEdit, PPG.ComboBox, PPG.SearchEdit,
  PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.Grid, PPG.Splitter,
  PPG.Breadcrumb, PPG.ToolBar, PPG.Calendar, PPG.DatePicker, PPG.TimePicker,
  PPG.CheckBox, PPG.Feedback, PPG.Notifications,
  DemoKit;

type
  TDemoListsPage = class(TDemoPage)
  private
    FMail: TPPGListBox;
    FMailResult: TPPGLabel;
    FMulti: TPPGListBox;
    FMultiResult: TPPGLabel;
    FFeatures: TPPGCheckListBox;
    FFeatureResult: TPPGLabel;
    FSearchResult: TPPGLabel;
    FVirtual: TPPGListBox;
    FJump: TPPGSpinEdit;
    FVirtualResult: TPPGLabel;
    FAllBtn, FJumpBtn: TPPGButton;
    procedure MailClick(Sender: TObject);
    procedure MultiClick(Sender: TObject);
    procedure AllClick(Sender: TObject);
    procedure NoneClick(Sender: TObject);
    procedure FeatureCheck(Sender: TObject);
    procedure SearchSuggest(Sender: TObject; const SearchText: string);
    procedure SearchSubmit(Sender: TObject; const SearchText: string);
    procedure ComboSelect(Sender: TObject);
    procedure VirtualData(Control: TWinControl; Index: Integer; var Data: string);
    procedure VirtualClick(Sender: TObject);
    procedure JumpClick(Sender: TObject);
    procedure Reordered(Sender: TObject; FromIndex, ToIndex: Integer; var Allow: Boolean);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoExplorerPage = class(TDemoPage)
  private
    FTree: TPPGTreeView;
    FFiles: TPPGListBox;
    FCrumb: TPPGBreadcrumb;
    FResult: TPPGLabel;
    FSetup: TPPGTreeView;
    FSetupResult: TPPGLabel;
    FTasks: TPPGTreeView;
    FTaskResult: TPPGLabel;
    FNewCount: Integer;
    procedure FillTree;
    procedure TreeChange(Sender: TObject; Node: TPPGTreeNode);
    procedure TreeExpanding(Sender: TObject; Node: TPPGTreeNode; var AllowExpansion: Boolean);
    procedure TreeEdited(Sender: TObject; Node: TPPGTreeNode; var S: string);
    procedure CrumbClick(Sender: TObject; Index: Integer);
    procedure FilesDblClick(Sender: TObject);
    procedure ToolClick(Sender: TObject; Item: TPPGToolItem);
    procedure ShowFolder(Node: TPPGTreeNode);
    procedure SetupChecked(Sender: TObject; Node: TPPGTreeNode);
    procedure TaskDrop(Sender: TObject; Node, Target: TPPGTreeNode; Mode: TNodeAttachMode;
      var Accept: Boolean);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoGridPage = class(TDemoPage)
  private
    FGrid: TPPGGrid;
    FSum: TPPGLabel;
    FVirtualResult: TPPGLabel;
    FVirtual: TPPGGrid;
    procedure FillGrid;
    procedure UpdateRowValue(ARow: Integer);
    procedure UpdateSummary;
    procedure CellSet(Sender: TObject; ACol, ARow: Integer; const Value: string);
    procedure CellValidate(Sender: TObject; ACol, ARow: Integer; var Value: string;
      var Accept: Boolean);
    procedure ToolClick(Sender: TObject; Item: TPPGToolItem);
    procedure Sorted(Sender: TObject);
    procedure VirtualText(Sender: TObject; ACol, ARow: Integer; var Text: string);
    procedure VirtualScroll(Sender: TObject);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoDatesPage = class(TDemoPage)
  private
    FBooking: TPPGCalendar;
    FArrival, FDeparture, FNights, FPrice: TPPGLabel;
    FBookResult: TPPGLabel;
    FWeekCal: TPPGCalendar;
    FDate: TPPGDatePicker;
    FTime: TPPGTimePicker;
    FDuration: TPPGComboBox;
    FReminder: TPPGDatePicker;
    FMeetResult: TPPGLabel;
    FSyncing: Boolean;
    procedure BookingChange(Sender: TObject);
    procedure BookingDisabled(Sender: TObject; ADate: TDate; var Disabled: Boolean);
    procedure BookClick(Sender: TObject);
    procedure WeekCalChange(Sender: TObject);
    procedure MeetingChange(Sender: TObject);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

const
  ColW = 484;
  FullW = 2 * ColW + CardGap;
  Col2X = PageX + ColW + CardGap;
  Col3W = (FullW - 2 * CardGap) div 3;

  Countries = 'Belgien,D{ae}nemark,Deutschland,Estland,Finnland,Frankreich,Griechenland,' +
    'Irland,Italien,Kroatien,Lettland,Litauen,Luxemburg,Malta,Niederlande,' +
    '{Oe}sterreich,Polen,Portugal,Rum{ae}nien,Schweden,Schweiz,Slowakei,Slowenien,' +
    'Spanien,Tschechien,Ungarn,Zypern';

{ TDemoListsPage }

procedure TDemoListsPage.Build;
const
  FeatureNames: array[0..7] of string = ('Programm', 'Kern (Pflicht)', 'Werkzeuge',
    'Beispiele', 'Sprachen', 'Deutsch', 'Englisch', 'Franz{oe}sisch');
var
  Card: TPPGPanel;
  It: TPPGItem;
  S: TPPGSearchEdit;
  Combo: TPPGComboBox;
  Y, I: Integer;
begin
  NewPageHeader(Own, Sheet, 'Listen', 'Eintr{ae}ge mit Bild, Gruppe, Detail und Plakette, ' +
    'Mehrfachauswahl, Checklisten, Suche mit Vorschl{ae}gen und eine Million virtuelle Zeilen.');

  // Postfach mit ItemsEx
  Card := NewCard(Own, Sheet, PageX, PageContentTop, Col3W, 340, 'Postfach',
    'Gruppen, Bilder, Details und Plaketten (ItemsEx).');
  FMail := TPPGListBox.Create(Own);
  FMail.Parent := Card;
  FMail.SetBounds(CardPad, Card.Tag, Col3W - 2 * CardPad, 340 - Card.Tag - 50);
  FMail.Images := Host.Images;
  FMail.AllowMarkup := True;
  It := FMail.ItemsEx.Add('<b>Posteingang</b>', 4);
  It.Group := 'Favoriten';
  It.Badge := '12';
  It.Detail := 'Neue Nachrichten';
  It := FMail.ItemsEx.Add('Gesendet', 5);
  It.Group := 'Favoriten';
  It.Detail := 'Zuletzt heute, 09:12';
  It := FMail.ItemsEx.Add(L('Entw{ue}rfe'), 15);
  It.Group := 'Ordner';
  It.Badge := '3';
  It := FMail.ItemsEx.Add('Wichtig', 7);
  It.Group := 'Ordner';
  It.Detail := 'Markierte Nachrichten';
  It := FMail.ItemsEx.Add('Papierkorb', 6);
  It.Group := 'Ordner';
  It.Detail := 'Wird nach 30 Tagen geleert';
  It := FMail.ItemsEx.Add('Archiv', 13);
  It.Group := 'Ordner';
  It.Enabled := False;
  It.Detail := 'Nur lesen (deaktiviert)';
  FMail.ItemIndex := 0;
  FMail.OnClick := MailClick;
  FMailResult := NewResult(Own, Card, 'Ordner');
  MailClick(nil);

  // Mehrfachauswahl
  Card := NewCard(Own, Sheet, PageX + Col3W + CardGap, PageContentTop, Col3W, 340,
    'Mehrfachauswahl', 'Strg/Umschalt w{ae}hlen mehrere, Ziehen sortiert um.');
  Y := Card.Tag;
  FAllBtn := NewButton(Own, Card, CardPad, Y, 80, 'Alle', AllClick);
  FAllBtn.Tag := 1;
  NewButton(Own, Card, CardPad + 88, Y, 80, 'Keine', NoneClick);
  FMulti := TPPGListBox.Create(Own);
  FMulti.Parent := Card;
  FMulti.SetBounds(CardPad, Y + 40, Col3W - 2 * CardPad, 340 - Y - 40 - 50);
  FMulti.Items.CommaText := L(Countries);
  FMulti.MultiSelect := True;
  FMulti.AllowReorder := True;
  FMulti.Selected[2] := True;
  FMulti.Selected[15] := True;
  FMulti.ItemIndex := 2;
  FMulti.OnClick := MultiClick;
  FMulti.OnReorder := Reordered;
  FMultiResult := NewResult(Own, Card, 'Gew{ae}hlt');
  MultiClick(nil);

  // Checkliste mit Ueberschriften
  Card := NewCard(Own, Sheet, PageX + 2 * (Col3W + CardGap), PageContentTop, Col3W, 340,
    'Checkliste', '{Ue}berschriften gliedern, der Speicherbedarf rechnet mit.');
  FFeatures := TPPGCheckListBox.Create(Own);
  FFeatures.Parent := Card;
  FFeatures.SetBounds(CardPad, Card.Tag, Col3W - 2 * CardPad, 340 - Card.Tag - 50);
  for I := 0 to High(FeatureNames) do
    FFeatures.Items.Add(L(FeatureNames[I]));
  FFeatures.Header[0] := True;
  FFeatures.Header[4] := True;
  FFeatures.Checked[1] := True;
  FFeatures.ItemEnabled[1] := False;
  FFeatures.Checked[2] := True;
  FFeatures.Checked[5] := True;
  FFeatures.OnClickCheck := FeatureCheck;
  FFeatureResult := NewResult(Own, Card, 'Speicherbedarf');
  FeatureCheck(nil);

  // Suchen und Filtern
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 340 + CardGap, ColW, 262,
    'Suchen und Filtern', 'Die Suche liefert Vorschl{ae}ge nach einer kurzen Pause; die Combo ' +
    'filtert beim Tippen. Die dritte Liste zeigt Bilder.');
  Y := Card.Tag;
  NewLabel(Own, Card, CardPad, Y + 6, 0, 'Suche', tkBody);
  S := TPPGSearchEdit.Create(Own);
  S.Parent := Card;
  S.SetBounds(CardPad + 90, Y, ColW - 2 * CardPad - 90, CtlH);
  S.TextHint := L('Land suchen{...}');
  S.OnSearch := SearchSuggest;
  S.OnSubmit := SearchSubmit;
  NewLabel(Own, Card, CardPad, Y + 46, 0, 'Filter', tkBody);
  Combo := TPPGComboBox.Create(Own);
  Combo.Parent := Card;
  Combo.SetBounds(CardPad + 90, Y + 40, ColW - 2 * CardPad - 90, CtlH);
  Combo.Items.CommaText := L(Countries);
  Combo.FilterMode := fmContains;
  Combo.TextHint := L('Teil des Namens tippen, z. B. "land"');
  Combo.OnSelect := ComboSelect;
  NewLabel(Own, Card, CardPad, Y + 86, 0, 'Dateityp', tkBody);
  Combo := TPPGComboBox.Create(Own);
  Combo.Parent := Card;
  Combo.Style := csDropDownList;
  Combo.SetBounds(CardPad + 90, Y + 80, ColW - 2 * CardPad - 90, CtlH);
  Combo.Images := Host.Images;
  It := Combo.ItemsEx.Add('Dokument', 2);
  It.Detail := 'PDF, DOCX, TXT';
  It := Combo.ItemsEx.Add('Bild', 3);
  It.Detail := 'PNG, JPG, SVG';
  It := Combo.ItemsEx.Add('Musik', 11);
  It.Detail := 'MP3, FLAC';
  It := Combo.ItemsEx.Add('Video', 12);
  It.Detail := 'MP4, MKV';
  It.Badge := 'neu';
  Combo.ItemIndex := 0;
  Combo.OnSelect := ComboSelect;
  Host.RegisterSpecial('dropdownimages', Combo);
  FSearchResult := NewResult(Own, Card, 'Gew{ae}hlt');

  // Virtuell: eine Million
  Card := NewCard(Own, Sheet, Col2X, PageContentTop + 340 + CardGap, ColW, 262,
    'Eine Million Eintr{ae}ge', 'Virtueller Modus: die Liste fragt nur die sichtbaren Zeilen ab ' +
    '(OnData). Springen Sie an eine beliebige Stelle.');
  Y := Card.Tag;
  FVirtual := TPPGListBox.Create(Own);
  FVirtual.Parent := Card;
  FVirtual.SetBounds(CardPad, Y, 270, 262 - Y - 50);
  FVirtual.Style := lbVirtual;
  FVirtual.OnData := VirtualData;
  FVirtual.Count := 1000000;
  FVirtual.ItemIndex := 0;
  FVirtual.OnClick := VirtualClick;
  NewLabel(Own, Card, CardPad + 290, Y, 0, 'Gehe zu Nummer', tkBody);
  FJump := TPPGSpinEdit.Create(Own);
  FJump.Parent := Card;
  FJump.SetBounds(CardPad + 290, Y + 24, 150, CtlH);
  FJump.MinValue := 1;
  FJump.MaxValue := 1000000;
  FJump.Increment := 1000;
  FJump.Value := 500000;
  FJumpBtn := NewButton(Own, Card, CardPad + 290, Y + 66, 150, 'Springen', JumpClick, True);
  FJumpBtn.Tag := 1;
  FVirtualResult := NewResult(Own, Card, 'Auswahl');
  VirtualClick(nil);
end;

procedure TDemoListsPage.MailClick(Sender: TObject);
var
  It: TPPGItem;
  S: string;
begin
  if FMail.ItemIndex < 0 then
    Exit;
  It := FMail.ItemsEx[FMail.ItemIndex];
  S := StringReplace(StringReplace(It.Text, '<b>', '', []), '</b>', '', []);
  if It.Badge <> '' then
    S := S + ' (' + It.Badge + ' neu)';
  SetResult(FMailResult, S);
  if Sender <> nil then
    Host.Log('ListBox', 'Ordner ' + S);
end;

procedure TDemoListsPage.MultiClick(Sender: TObject);
var
  I, N: Integer;
  First: string;
begin
  N := 0;
  First := '';
  for I := 0 to FMulti.Items.Count - 1 do
    if FMulti.Selected[I] then
    begin
      Inc(N);
      if N <= 3 then
      begin
        if First <> '' then
          First := First + ', ';
        First := First + FMulti.Items[I];
      end;
    end;
  if N > 3 then
    First := First + ', {...}';
  if N = 0 then
    SetResult(FMultiResult, 'nichts')
  else
    SetResult(FMultiResult, Format('%d {-} %s', [N, First]));
  if Sender <> nil then
    Host.Log('ListBox', Format('%d ausgew{ae}hlt', [N]));
end;

procedure TDemoListsPage.AllClick(Sender: TObject);
begin
  FMulti.SelectAll;
  MultiClick(Sender);
end;

procedure TDemoListsPage.NoneClick(Sender: TObject);
begin
  FMulti.ClearSelection;
  MultiClick(Sender);
end;

procedure TDemoListsPage.Reordered(Sender: TObject; FromIndex, ToIndex: Integer;
  var Allow: Boolean);
begin
  Host.Log('ListBox', Format('Verschoben: %s von %d nach %d',
    [FMulti.Items[FromIndex], FromIndex + 1, ToIndex + 1]));
end;

procedure TDemoListsPage.FeatureCheck(Sender: TObject);
const
  Sizes: array[0..7] of Integer = (0, 180, 95, 140, 0, 12, 12, 14);
var
  I, Total, N: Integer;
begin
  Total := 0;
  N := 0;
  for I := 0 to FFeatures.Items.Count - 1 do
    if not FFeatures.Header[I] and FFeatures.Checked[I] then
    begin
      Inc(Total, Sizes[I]);
      Inc(N);
    end;
  SetResult(FFeatureResult, Format('%d MB {.} %d Komponenten', [Total, N]));
  if Sender <> nil then
    Host.Log('CheckListBox', Format('%d MB', [Total]));
end;

procedure TDemoListsPage.SearchSuggest(Sender: TObject; const SearchText: string);
var
  S: TPPGSearchEdit;
  All: TStringList;
  I: Integer;
begin
  // Die Anwendung liefert die Vorschlaege (hier: Filter einer festen Liste)
  S := TPPGSearchEdit(Sender);
  All := TStringList.Create;
  try
    All.CommaText := L(Countries);
    S.Items.BeginUpdate;
    try
      S.Items.Clear;
      if SearchText <> '' then
        for I := 0 to All.Count - 1 do
          if Pos(AnsiLowerCase(SearchText), AnsiLowerCase(All[I])) > 0 then
            S.Items.Add(All[I]);
    finally
      S.Items.EndUpdate;
    end;
  finally
    All.Free;
  end;
end;

procedure TDemoListsPage.SearchSubmit(Sender: TObject; const SearchText: string);
begin
  SetResult(FSearchResult, 'Suche nach "' + MarkupEscape(SearchText) + '"');
  Host.Log('SearchEdit', 'Suche: ' + SearchText);
end;

procedure TDemoListsPage.ComboSelect(Sender: TObject);
begin
  SetResult(FSearchResult, MarkupEscape(TPPGComboBox(Sender).Text));
  Host.Log('ComboBox', TPPGComboBox(Sender).Text);
end;

procedure TDemoListsPage.VirtualData(Control: TWinControl; Index: Integer; var Data: string);
begin
  Data := Format('Datensatz %s', [FormatFloat('#,##0', Index + 1,
    TFormatSettings.Create('de-DE'))]);
end;

procedure TDemoListsPage.VirtualClick(Sender: TObject);
begin
  if FVirtual.ItemIndex >= 0 then
    SetResult(FVirtualResult, Format('Datensatz %s von 1.000.000',
      [FormatFloat('#,##0', FVirtual.ItemIndex + 1, TFormatSettings.Create('de-DE'))]));
end;

procedure TDemoListsPage.JumpClick(Sender: TObject);
begin
  FVirtual.ItemIndex := FJump.Value - 1;
  FVirtual.Selected[FJump.Value - 1] := True;
  FVirtual.MakeItemVisible(FJump.Value - 1, True);
  FVirtual.SetFocus;
  VirtualClick(nil);
  Host.Log('ListBox', Format('Gesprungen zu %d', [FJump.Value]));
end;

{ TDemoExplorerPage }

type
  TFileDef = record
    Name: string;
    Kind: string;
    Size: Integer;
    Image: Integer;
  end;

function FilesOf(const Folder: string): TArray<TFileDef>;

  procedure Add(const AName, AKind: string; ASize, AImage: Integer);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name := AName;
    Result[High(Result)].Kind := AKind;
    Result[High(Result)].Size := ASize;
    Result[High(Result)].Image := AImage;
  end;

begin
  SetLength(Result, 0);
  if Folder = 'Berichte' then
  begin
    Add('Jahresbericht 2025.pdf', 'PDF-Dokument', 2480, 2);
    Add('Umsatz Q3.xlsx', 'Tabelle', 312, 2);
    Add('Pr{ae}sentation.pptx', 'Pr{ae}sentation', 5120, 2);
  end
  else if Folder = L('Vertr{ae}ge') then
  begin
    Add('Mietvertrag.pdf', 'PDF-Dokument', 840, 2);
    Add('Stromvertrag.pdf', 'PDF-Dokument', 410, 2);
  end
  else if Folder = 'Urlaub' then
  begin
    Add('Strand.jpg', 'JPG-Bild', 3650, 3);
    Add('Berge.jpg', 'JPG-Bild', 4210, 3);
    Add('Sonnenuntergang.png', 'PNG-Bild', 6020, 3);
    Add('Video vom Ausflug.mp4', 'Video', 182400, 12);
  end
  else if Folder = 'Musik' then
  begin
    Add('Playlist Sommer.m3u', 'Wiedergabeliste', 2, 11);
    Add('Konzert live.flac', 'Audio', 48200, 11);
  end
  else if Folder = 'Dokumente' then
    Add('Notizen.txt', 'Textdatei', 4, 2);
end;

function SizeText(KB: Integer): string;
begin
  if KB >= 1024 then
    Result := FormatFloat('0.0', KB / 1024) + ' MB'
  else
    Result := IntToStr(KB) + ' KB';
end;

procedure TDemoExplorerPage.Build;
var
  Card: TPPGPanel;
  TB: TPPGToolBar;
  Host2: TPanel;
  Sp: TPPGSplitter;
  Root, N: TPPGTreeNode;
  Y: Integer;
begin
  NewPageHeader(Own, Sheet, 'Explorer', 'TreeView, Breadcrumb, Splitter, ToolBar und ListBox ' +
    'arbeiten zusammen. F2 benennt um, Doppelklick {oe}ffnet, das Netzlaufwerk l{ae}dt erst beim ' +
    'Aufklappen.');

  Card := NewCard(Own, Sheet, PageX, PageContentTop, FullW, 390, '', '');
  TB := TPPGToolBar.Create(Own);
  TB.Parent := Card;
  TB.Align := alNone;
  TB.SetBounds(CardPad - 6, 12, 640, 40);
  TB.Items.AddButton('Neuer Ordner', $E8F4);
  TB.Items.AddButton('Umbenennen', $E8AC);
  TB.Items.AddButton(L('L{oe}schen'), $E74D);
  TB.Items.AddSeparator;
  TB.Items.AddButton('Alle aufklappen', $E70D);
  TB.Items.AddButton('Alle zuklappen', $E70E);
  TB.OnItemClick := ToolClick;
  FCrumb := TPPGBreadcrumb.Create(Own);
  FCrumb.Parent := Card;
  FCrumb.SetBounds(CardPad, 58, FullW - 2 * CardPad, 30);
  FCrumb.TruncateOnClick := False;
  FCrumb.OnItemClick := CrumbClick;

  Host2 := TPanel.Create(Own);
  Host2.Parent := Card;
  Host2.SetBounds(CardPad, 96, FullW - 2 * CardPad, 390 - 96 - 48);
  Host2.BevelOuter := bvNone;
  Host2.ParentBackground := True;
  Host2.ParentColor := True;
  Host2.Caption := '';
  FTree := TPPGTreeView.Create(Own);
  FTree.Parent := Host2;
  FTree.Align := alLeft;
  FTree.Width := 280;
  FTree.Images := Host.Images;
  FTree.OnChange := TreeChange;
  FTree.OnExpanding := TreeExpanding;
  FTree.OnEdited := TreeEdited;
  Sp := TPPGSplitter.Create(Own);
  Sp.Parent := Host2;
  Sp.Left := 290;
  Sp.Align := alLeft;
  Sp.MinSize := 160;
  FFiles := TPPGListBox.Create(Own);
  FFiles.Parent := Host2;
  FFiles.Align := alClient;
  FFiles.Images := Host.Images;
  FFiles.OnDblClick := FilesDblClick;
  FResult := NewResult(Own, Card, 'Inhalt');
  FillTree;

  // Installationsumfang mit Kaestchen
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 390 + CardGap, ColW, 236,
    'Installationsumfang', 'K{ae}stchen geben ihren Zustand an Eltern und Kinder weiter.');
  FSetup := TPPGTreeView.Create(Own);
  FSetup.Parent := Card;
  Y := Card.Tag;
  FSetup.SetBounds(CardPad, Y, ColW - 2 * CardPad, 236 - Y - 46);
  FSetup.CheckBoxes := True;
  FSetup.ShowLines := True;
  FSetup.Items.BeginUpdate;
  try
    Root := FSetup.Items.Add(nil, 'PPGlow Suite');
    N := FSetup.Items.AddChild(Root, 'Laufzeit-Packages');
    FSetup.Items.AddChild(N, 'Win32').Checked := True;
    FSetup.Items.AddChild(N, 'Win64').Checked := True;
    N := FSetup.Items.AddChild(Root, 'Entwurf');
    FSetup.Items.AddChild(N, 'Komponenten-Palette').Checked := True;
    FSetup.Items.AddChild(N, 'Hilfe');
    FSetup.Items.AddChild(Root, 'Beispiele');
  finally
    FSetup.Items.EndUpdate;
  end;
  FSetup.FullExpand;
  FSetup.OnChecked := SetupChecked;
  FSetupResult := NewResult(Own, Card, 'Ausgew{ae}hlt');
  SetupChecked(nil, nil);

  // Aufgaben: per Ziehen umordnen
  Card := NewCard(Own, Sheet, Col2X, PageContentTop + 390 + CardGap, ColW, 236,
    'Aufgaben ordnen', 'Ziehen Sie Aufgaben zwischen die Spalten {-} oder in eine andere Gruppe.');
  FTasks := TPPGTreeView.Create(Own);
  FTasks.Parent := Card;
  Y := Card.Tag;
  FTasks.SetBounds(CardPad, Y, ColW - 2 * CardPad, 236 - Y - 46);
  FTasks.AllowReorder := True;
  FTasks.Images := Host.Images;
  FTasks.Items.BeginUpdate;
  try
    Root := FTasks.Items.Add(nil, 'Zu erledigen');
    Root.Badge := '3';
    FTasks.Items.AddChild(Root, 'Angebot schreiben').ImageIndex := 15;
    FTasks.Items.AddChild(Root, L('Rechnung pr{ue}fen')).ImageIndex := 15;
    N := FTasks.Items.AddChild(Root, L('Kunden zur{ue}ckrufen'));
    N.ImageIndex := 14;
    N.Detail := 'Heute 14:00';
    Root := FTasks.Items.Add(nil, 'Erledigt');
    FTasks.Items.AddChild(Root, 'Newsletter versenden').ImageIndex := 10;
  finally
    FTasks.Items.EndUpdate;
  end;
  FTasks.FullExpand;
  FTasks.OnNodeDrop := TaskDrop;
  FTaskResult := NewResult(Own, Card, 'Zuletzt verschoben');
end;

procedure TDemoExplorerPage.FillTree;
var
  PC, Docs, N: TPPGTreeNode;
begin
  FTree.Items.BeginUpdate;
  try
    PC := FTree.Items.Add(nil, 'Dieser PC');
    PC.ImageIndex := 17;
    Docs := FTree.Items.AddChild(PC, 'Dokumente');
    Docs.ImageIndex := 1;
    N := FTree.Items.AddChild(Docs, 'Berichte');
    N.ImageIndex := 1;
    N.Badge := '3';
    N := FTree.Items.AddChild(Docs, L('Vertr{ae}ge'));
    N.ImageIndex := 1;
    N := FTree.Items.AddChild(PC, 'Bilder');
    N.ImageIndex := 1;
    FTree.Items.AddChild(N, 'Urlaub').ImageIndex := 1;
    N := FTree.Items.AddChild(PC, 'Musik');
    N.ImageIndex := 1;
    N := FTree.Items.Add(nil, L('Netzlaufwerk (l{ae}dt beim Aufklappen)'));
    N.ImageIndex := 16;
    N.HasChildren := True;
    Docs.Expand(False);
    PC.Expand(False);
  finally
    FTree.Items.EndUpdate;
  end;
  FTree.Selected := Docs;
  ShowFolder(Docs);
end;

procedure TDemoExplorerPage.ShowFolder(Node: TPPGTreeNode);
var
  Path: TStringList;
  N: TPPGTreeNode;
  Files: TArray<TFileDef>;
  It: TPPGItem;
  I, Folders: Integer;
begin
  FFiles.ItemsEx.BeginUpdate;
  try
    FFiles.ItemsEx.Clear;
    Folders := 0;
    Files := nil;
    if Node <> nil then
    begin
      for I := 0 to Node.Count - 1 do
      begin
        It := FFiles.ItemsEx.Add(Node[I].Text, 1);
        It.Detail := 'Dateiordner';
        It.Data := Node[I];
        Inc(Folders);
      end;
      Files := FilesOf(Node.Text);
      for I := 0 to High(Files) do
      begin
        It := FFiles.ItemsEx.Add(L(Files[I].Name), Files[I].Image);
        It.Detail := L(Files[I].Kind) + ' ' + #$00B7 + ' ' + SizeText(Files[I].Size);
      end;
    end;
  finally
    FFiles.ItemsEx.EndUpdate;
  end;
  // Breadcrumb = Pfad vom Stamm bis zum Knoten
  Path := TStringList.Create;
  try
    N := Node;
    while N <> nil do
    begin
      Path.Insert(0, N.Text);
      N := N.Parent;
    end;
    FCrumb.Items.Assign(Path);
  finally
    Path.Free;
  end;
  SetResult(FResult, Format('%d Ordner, %d Dateien', [Folders, Length(Files)]));
end;

procedure TDemoExplorerPage.TreeChange(Sender: TObject; Node: TPPGTreeNode);
begin
  ShowFolder(Node);
  if Node <> nil then
    Host.Log('TreeView', Node.Text);
end;

procedure TDemoExplorerPage.TreeExpanding(Sender: TObject; Node: TPPGTreeNode;
  var AllowExpansion: Boolean);
var
  I: Integer;
begin
  // Lazy Loading: Kinder erst beim ersten Aufklappen anlegen
  if (Node.Count > 0) or (Node.ImageIndex <> 16) then
    Exit;
  FTree.Items.BeginUpdate;
  try
    for I := 1 to 4 do
      FTree.Items.AddChild(Node, Format('Freigabe %d', [I])).ImageIndex := 1;
  finally
    FTree.Items.EndUpdate;
  end;
  Host.Log('TreeView', L('Netzlaufwerk geladen (4 Freigaben)'));
end;

procedure TDemoExplorerPage.TreeEdited(Sender: TObject; Node: TPPGTreeNode; var S: string);
begin
  Host.Log('TreeView', 'Umbenannt: ' + Node.Text + ' {>} ' + S);
  // Der neue Name gilt erst nach diesem Ereignis: Breadcrumb direkt anpassen
  if (Node = FTree.Selected) and (FCrumb.Items.Count > 0) then
    FCrumb.Items[FCrumb.Items.Count - 1] := S;
end;

procedure TDemoExplorerPage.CrumbClick(Sender: TObject; Index: Integer);
var
  N: TPPGTreeNode;
  Depth: Integer;
begin
  N := FTree.Selected;
  if N = nil then
    Exit;
  Depth := N.Level;
  while (N <> nil) and (Depth > Index) do
  begin
    N := N.Parent;
    Dec(Depth);
  end;
  if N <> nil then
    FTree.Selected := N;
end;

procedure TDemoExplorerPage.FilesDblClick(Sender: TObject);
var
  Node: TPPGTreeNode;
begin
  if FFiles.ItemIndex < 0 then
    Exit;
  Node := TPPGTreeNode(FFiles.ItemsEx[FFiles.ItemIndex].Data);
  if Node <> nil then
  begin
    Node.Parent.Expand(False);
    FTree.Selected := Node;
  end
  else
    Host.Notifier.Show(L('Datei {oe}ffnen'), MarkupEscape(FFiles.ItemsEx[FFiles.ItemIndex].Text) +
      L(' w{ue}rde jetzt ge{oe}ffnet.'), psInformational);
end;

procedure TDemoExplorerPage.ToolClick(Sender: TObject; Item: TPPGToolItem);
var
  N, Sel: TPPGTreeNode;
begin
  Sel := FTree.Selected;
  case Item.IconChar of
    $E8F4:
      if Sel <> nil then
      begin
        Inc(FNewCount);
        N := FTree.Items.AddChild(Sel, Format('Neuer Ordner %d', [FNewCount]));
        N.ImageIndex := 1;
        Sel.Expand(False);
        FTree.Selected := N;
        N.EditText;
      end;
    $E8AC:
      if Sel <> nil then
        Sel.EditText;
    $E74D:
      if (Sel <> nil) and (Sel.Parent <> nil) then
      begin
        Host.Log('TreeView', L('Gel{oe}scht: ') + Sel.Text);
        N := Sel.Parent;
        Sel.Delete;
        FTree.Selected := N;
      end;
    $E70D: FTree.FullExpand;
    $E70E: FTree.FullCollapse;
  end;
end;

procedure TDemoExplorerPage.SetupChecked(Sender: TObject; Node: TPPGTreeNode);
const
  Leaves: array[0..5] of string = ('Win32', 'Win64', 'Komponenten-Palette', 'Hilfe',
    'Beispiele', '');
  Sizes: array[0..4] of Integer = (14, 18, 3, 25, 40);
var
  I, N, MB: Integer;

  procedure Count(Nd: TPPGTreeNode);
  var
    J: Integer;
  begin
    if Nd.Count = 0 then
    begin
      if Nd.Checked then
        for J := 0 to 4 do
          if Nd.Text = Leaves[J] then
          begin
            Inc(N);
            Inc(MB, Sizes[J]);
          end;
    end
    else
      for J := 0 to Nd.Count - 1 do
        Count(Nd[J]);
  end;

begin
  N := 0;
  MB := 0;
  for I := 0 to FSetup.Items.RootCount - 1 do
    Count(FSetup.Items.Root(I));
  SetResult(FSetupResult, Format('%d von 5 Komponenten {.} %d MB', [N, MB]));
  if Node <> nil then
    Host.Log('TreeView', Node.Text + ': ' + BoolToStr(Node.Checked, True));
end;

procedure TDemoExplorerPage.TaskDrop(Sender: TObject; Node, Target: TPPGTreeNode;
  Mode: TNodeAttachMode; var Accept: Boolean);
begin
  SetResult(FTaskResult, MarkupEscape(Node.Text));
  Host.Log('TreeView', 'Verschoben: ' + Node.Text);
end;

{ TDemoGridPage }

const
  ColName = 0;
  ColCategory = 1;
  ColQty = 2;
  ColPrice = 3;
  ColActive = 4;
  ColValue = 5;

procedure TDemoGridPage.Build;
var
  Card: TPPGPanel;
  TB: TPPGToolBar;
  C: TPPGGridColumn;
begin
  NewPageHeader(Own, Sheet, 'Tabelle', 'Lagerliste mit Editoren in den Zellen, Sortieren per ' +
    'Klick auf den Kopf, Filterzeile und Summen, die sich bei jeder {Ae}nderung neu berechnen.');

  Card := NewCard(Own, Sheet, PageX, PageContentTop, FullW, 420, '', '');
  TB := TPPGToolBar.Create(Own);
  TB.Parent := Card;
  TB.Align := alNone;
  TB.SetBounds(CardPad - 6, 12, 760, 40);
  TB.Items.AddButton(L('Hinzuf{ue}gen'), $E710);
  TB.Items.AddButton(L('L{oe}schen'), $E74D);
  TB.Items.AddSeparator;
  TB.Items.AddCheck('Filterzeile', $E71C).Down := True;
  TB.Items.AddButton('Sortierung aufheben', $E8CB);
  TB.Items.AddSeparator;
  TB.Items.AddButton('Als CSV kopieren', $E8C8);
  TB.OnItemClick := ToolClick;

  FGrid := TPPGGrid.Create(Own);
  FGrid.Parent := Card;
  FGrid.SetBounds(CardPad, 58, FullW - 2 * CardPad, 420 - 58 - 48);
  FGrid.FixedCols := 0;
  FGrid.Options := FGrid.Options + [goEditing, goColSizing, goTabs];
  FGrid.ShowFilterRow := True;
  C := FGrid.Columns.Add;
  C.Title := 'Artikel';
  C.Width := 300;
  C := FGrid.Columns.Add;
  C.Title := 'Kategorie';
  C.Width := 160;
  C.EditorKind := gekCombo;
  C.PickList.CommaText := L('Befestigung,Elektro,Werkzeug,Licht');
  C := FGrid.Columns.Add;
  C.Title := 'Menge';
  C.Width := 110;
  C.Alignment := taRightJustify;
  C.EditorKind := gekSpin;
  C.MaxValue := 9999;
  C := FGrid.Columns.Add;
  C.Title := L('Preis ({EUR})');
  C.Width := 120;
  C.Alignment := taRightJustify;
  C := FGrid.Columns.Add;
  C.Title := 'Aktiv';
  C.Width := 80;
  C.EditorKind := gekCheck;
  C := FGrid.Columns.Add;
  C.Title := L('Wert ({EUR})');
  C.Width := 160;
  C.Alignment := taRightJustify;
  C.ReadOnly := True;
  FGrid.OnSetEditText := CellSet;
  FGrid.OnValidateCell := CellValidate;
  FGrid.OnSorted := Sorted;
  FSum := NewResult(Own, Card, 'Summe');
  FillGrid;

  // Virtuell
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 420 + CardGap, FullW, 206,
    'Eine Million Zeilen {x} 20 Spalten', 'Virtuelles Grid {-} der Inhalt entsteht beim ' +
    'Zeichnen (OnGetCellText). Scrollen Sie mit Rad, Bildlaufleiste oder Strg+Ende.');
  FVirtual := TPPGGrid.Create(Own);
  FVirtual.Parent := Card;
  FVirtual.SetBounds(CardPad, Card.Tag, FullW - 2 * CardPad, 206 - Card.Tag - 46);
  FVirtual.ColCount := 21;
  FVirtual.RowCount := 1000001;
  FVirtual.DefaultColWidth := 90;
  FVirtual.ColWidths[0] := 80;
  FVirtual.OnGetCellText := VirtualText;
  FVirtual.OnTopLeftChanged := VirtualScroll;
  FVirtual.OnScroll := VirtualScroll;
  FVirtualResult := NewResult(Own, Card, 'Sichtbar ab Zeile');
  VirtualScroll(nil);
end;

procedure TDemoGridPage.FillGrid;
const
  Names: array[0..9] of string = ('Schraube M4', 'Mutter M4', 'D{ue}bel 6 mm', 'Winkel 40 mm',
    'Scharnier', 'Kabel 3 m', 'Stecker', 'LED-Lampe', 'Akkuschrauber', 'Wasserwaage');
  Cats: array[0..9] of string = ('Befestigung', 'Befestigung', 'Befestigung', 'Befestigung',
    'Befestigung', 'Elektro', 'Elektro', 'Licht', 'Werkzeug', 'Werkzeug');
  Prices: array[0..9] of Double = (0.12, 0.08, 0.15, 1.20, 3.40, 6.90, 2.50, 8.99, 89.00, 19.90);
var
  I: Integer;
begin
  FGrid.RowCount := 31;
  for I := 1 to 30 do
  begin
    FGrid.Cells[ColName, I] := L(Names[(I - 1) mod 10]) + Format(' (%s)', [Chr(Ord('A') + (I - 1) div 10)]);
    FGrid.Cells[ColCategory, I] := Cats[(I - 1) mod 10];
    FGrid.Cells[ColQty, I] := IntToStr((I * 37) mod 400 + 5);
    FGrid.Cells[ColPrice, I] := FormatFloat('0.00', Prices[(I - 1) mod 10] * (1 + ((I - 1) div 10) * 0.1));
    FGrid.Cells[ColActive, I] := IntToStr(Ord(I mod 5 <> 0));
    UpdateRowValue(I);
  end;
  FGrid.Row := 1;
  FGrid.Col := ColQty;
  UpdateSummary;
end;

procedure TDemoGridPage.UpdateRowValue(ARow: Integer);
var
  Q: Integer;
  P: Double;
begin
  Q := StrToIntDef(FGrid.Cells[ColQty, ARow], 0);
  P := StrToFloatDef(FGrid.Cells[ColPrice, ARow], 0);
  FGrid.Cells[ColValue, ARow] := FormatFloat('#,##0.00', Q * P);
end;

procedure TDemoGridPage.UpdateSummary;
var
  I, Active: Integer;
  Total: Double;
begin
  Active := 0;
  Total := 0;
  for I := 1 to FGrid.RowCount - 1 do
  begin
    if FGrid.Cells[ColActive, I] = '1' then
      Inc(Active);
    Total := Total + StrToIntDef(FGrid.Cells[ColQty, I], 0) *
      StrToFloatDef(FGrid.Cells[ColPrice, I], 0);
  end;
  SetResult(FSum, Format('%d Artikel {.} %d aktiv {.} Lagerwert %s',
    [FGrid.RowCount - 1, Active, Euro(Total)]));
end;

procedure TDemoGridPage.CellSet(Sender: TObject; ACol, ARow: Integer; const Value: string);
begin
  if ACol in [ColQty, ColPrice] then
    UpdateRowValue(ARow);
  UpdateSummary;
  Host.Log('Grid', Format('Zeile %d, %s = %s', [ARow, FGrid.Columns[ACol].Title, Value]));
end;

procedure TDemoGridPage.CellValidate(Sender: TObject; ACol, ARow: Integer; var Value: string;
  var Accept: Boolean);
var
  P: Double;
begin
  if ACol = ColPrice then
  begin
    Value := StringReplace(Trim(Value), '.', FormatSettings.DecimalSeparator, []);
    Accept := TryStrToFloat(Value, P) and (P >= 0);
    if Accept then
      Value := FormatFloat('0.00', P)
    else
      Host.Notifier.Show(L('Ung{ue}ltiger Preis'), L('Bitte eine Zahl ab 0 eingeben, z. B. 4,99.'),
        psWarning);
  end
  else if (ACol = ColName) and (Trim(Value) = '') then
  begin
    Accept := False;
    Host.Notifier.Show('Artikel fehlt', L('Der Artikelname darf nicht leer sein.'), psWarning);
  end;
end;

procedure TDemoGridPage.ToolClick(Sender: TObject; Item: TPPGToolItem);
var
  R, I, C: Integer;
begin
  case Item.IconChar of
    $E710:
      begin
        FGrid.RowCount := FGrid.RowCount + 1;
        R := FGrid.RowCount - 1;
        FGrid.Cells[ColName, R] := 'Neuer Artikel';
        FGrid.Cells[ColCategory, R] := 'Werkzeug';
        FGrid.Cells[ColQty, R] := '1';
        FGrid.Cells[ColPrice, R] := '0,00';
        FGrid.Cells[ColActive, R] := '1';
        UpdateRowValue(R);
        FGrid.Row := R;
        FGrid.Col := ColName;
        FGrid.MakeCellVisible(ColName, FGrid.VisualRow(R));
        FGrid.SetFocus;
        UpdateSummary;
        Host.Log('Grid', L('Zeile hinzugef{ue}gt'));
      end;
    $E74D:
      if FGrid.RowCount > 2 then
      begin
        R := FGrid.Row;
        if R < 1 then
          Exit;
        Host.Log('Grid', L('Gel{oe}scht: ') + FGrid.Cells[ColName, R]);
        for I := R to FGrid.RowCount - 2 do
          for C := 0 to FGrid.ColCount - 1 do
            FGrid.Cells[C, I] := FGrid.Cells[C, I + 1];
        FGrid.RowCount := FGrid.RowCount - 1;
        UpdateSummary;
      end;
    $E71C:
      begin
        FGrid.ShowFilterRow := Item.Down;
        if not Item.Down then
          FGrid.ClearFilters;
      end;
    $E8CB:
      begin
        FGrid.ClearFilters;
        FillGrid;
        Host.Log('Grid', 'Sortierung und Filter aufgehoben');
      end;
    $E8C8:
      begin
        FGrid.SelectAll;
        FGrid.CopyToClipboard;
        Host.Notifier.Show('In Zwischenablage kopiert', L('Alle Zeilen als Text {-} ' +
          'zum Einf{ue}gen in Excel.'), psSuccess);
      end;
  end;
end;

procedure TDemoGridPage.Sorted(Sender: TObject);
begin
  if FGrid.SortColumn >= 0 then
    Host.Log('Grid', 'Sortiert nach ' + FGrid.Columns[FGrid.SortColumn].Title)
  else
    Host.Log('Grid', 'Unsortiert');
end;

procedure TDemoGridPage.VirtualText(Sender: TObject; ACol, ARow: Integer; var Text: string);
begin
  if ARow = 0 then
  begin
    if ACol > 0 then
      Text := 'Spalte ' + IntToStr(ACol)
    else
      Text := 'Nr.';
  end
  else if ACol = 0 then
    Text := IntToStr(ARow)
  else
    Text := IntToStr(ARow * ACol);
end;

procedure TDemoGridPage.VirtualScroll(Sender: TObject);
var
  RowH, V: Integer;
begin
  // Erste sichtbare Datenzeile ueber die Zellposition ermitteln
  RowH := Max(1, MulDiv(FVirtual.DefaultRowHeight, FVirtual.CurrentPPI, 96));
  V := 1 + FVirtual.ScrollY div RowH;
  SetResult(FVirtualResult, FormatFloat('#,##0', V, TFormatSettings.Create('de-DE')) +
    ' von 1.000.000');
end;

{ TDemoDatesPage }

procedure TDemoDatesPage.Build;
var
  Card: TPPGPanel;
  Y: Integer;
  B: TPPGButton;
begin
  NewPageHeader(Own, Sheet, 'Termine', 'Zeitraum im Kalender w{ae}hlen (ausgebuchte Tage sind ' +
    'gesperrt), Termine mit Datum und Uhrzeit planen und Kalender verkn{ue}pfen.');

  // Buchung mit Zeitraum
  Card := NewCard(Own, Sheet, PageX, PageContentTop, 600, 420, 'Hotel buchen',
    'Anreise anklicken, dann Abreise. Umschalt+Klick erweitert den Zeitraum.');
  Y := Card.Tag;
  FBooking := TPPGCalendar.Create(Own);
  FBooking.Parent := Card;
  FBooking.SetBounds(CardPad, Y, 300, 310);
  FBooking.SelectionMode := dsmRange;
  FBooking.MinDate := Date;
  FBooking.MaxDate := IncMonth(Date, 12);
  FBooking.OnIsDateDisabled := BookingDisabled;
  FBooking.OnChange := BookingChange;
  NewLabel(Own, Card, 350, Y, 0, 'Anreise', tkSecondary);
  FArrival := NewLabel(Own, Card, 350, Y + 20, 220, '', tkStrong);
  NewLabel(Own, Card, 350, Y + 56, 0, 'Abreise', tkSecondary);
  FDeparture := NewLabel(Own, Card, 350, Y + 76, 220, '', tkStrong);
  NewLabel(Own, Card, 350, Y + 112, 0, L('N{ae}chte'), tkSecondary);
  FNights := NewLabel(Own, Card, 350, Y + 132, 220, '', tkStrong);
  NewLabel(Own, Card, 350, Y + 168, 0, 'Gesamtpreis', tkSecondary);
  FPrice := NewLabel(Own, Card, 350, Y + 186, 0, '', tkValue);
  NewLabel(Own, Card, 350, Y + 226, 230, '89 {EUR} pro Nacht, Fr und Sa 119 {EUR}', tkCaption);
  B := NewButton(Own, Card, 350, Y + 270, 160, 'Jetzt buchen', BookClick, True);
  B.Tag := 1;
  FBookResult := NewResult(Own, Card, 'Buchung');
  FBooking.SelectRange(Date + 7, Date + 10);
  BookingChange(nil);

  // Kalender mit Wochennummern, verknuepft mit dem Termin
  Card := NewCard(Own, Sheet, PageX + 600 + CardGap, PageContentTop, FullW - 600 - CardGap, 420,
    'Kalender', 'Mit Kalenderwochen. Ein Klick setzt das Datum des Termins unten.');
  FWeekCal := TPPGCalendar.Create(Own);
  FWeekCal.Parent := Card;
  FWeekCal.SetBounds(CardPad, Card.Tag, Card.Width - 2 * CardPad, 310);
  FWeekCal.ShowWeekNumbers := True;
  FWeekCal.Date := Date + 1;
  FWeekCal.OnChange := WeekCalChange;

  // Termin
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 420 + CardGap, FullW, 206, 'Termin planen',
    'Datum per Kalender-Popup oder Tastatur, Uhrzeit mit Pfeiltasten (Teil an der ' +
    'Einf{ue}gemarke), optional eine Erinnerung.');
  Y := Card.Tag;
  NewLabel(Own, Card, CardPad, Y, 0, 'Datum', tkBody);
  FDate := TPPGDatePicker.Create(Own);
  FDate.Parent := Card;
  FDate.SetBounds(CardPad, Y + 22, 200, CtlH);
  FDate.Date := Date + 1;
  FDate.OnChange := MeetingChange;
  Host.RegisterSpecial('datepicker', FDate);
  NewLabel(Own, Card, CardPad + 220, Y, 0, 'Beginn', tkBody);
  FTime := TPPGTimePicker.Create(Own);
  FTime.Parent := Card;
  FTime.SetBounds(CardPad + 220, Y + 22, 120, CtlH);
  FTime.ClockFormat := pcf24Hour;
  FTime.Time := EncodeTime(9, 30, 0, 0);
  FTime.OnChange := MeetingChange;
  NewLabel(Own, Card, CardPad + 360, Y, 0, 'Dauer', tkBody);
  FDuration := TPPGComboBox.Create(Own);
  FDuration.Parent := Card;
  FDuration.Style := csDropDownList;
  FDuration.SetBounds(CardPad + 360, Y + 22, 150, CtlH);
  FDuration.Items.CommaText := '"15 Minuten","30 Minuten","1 Stunde","2 Stunden","Ganzer Tag"';
  FDuration.ItemIndex := 2;
  FDuration.OnChange := MeetingChange;
  NewLabel(Own, Card, CardPad + 530, Y, 0, 'Erinnerung am', tkBody);
  FReminder := TPPGDatePicker.Create(Own);
  FReminder.Parent := Card;
  FReminder.SetBounds(CardPad + 530, Y + 22, 230, CtlH);
  FReminder.ShowCheckbox := True;
  FReminder.Checked := False;
  FReminder.DateFormat := dfLong;
  FReminder.OnChange := MeetingChange;
  FMeetResult := NewResult(Own, Card, 'Termin');
  MeetingChange(nil);
end;

function NightPrice(D: TDate): Double;
begin
  if DayOfTheWeek(D) in [5, 6] then
    Result := 119
  else
    Result := 89;
end;

procedure TDemoDatesPage.BookingDisabled(Sender: TObject; ADate: TDate; var Disabled: Boolean);
begin
  // "Ausgebucht": jeder 9. Tag des Jahres
  if DayOfTheYear(ADate) mod 9 = 0 then
    Disabled := True;
end;

procedure TDemoDatesPage.BookingChange(Sender: TObject);
var
  D: TDate;
  N: Integer;
  Price: Double;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create('de-DE');
  N := Trunc(FBooking.RangeEnd) - Trunc(FBooking.RangeStart);
  if (FBooking.RangeStart = 0) or (N <= 0) then
  begin
    FArrival.Caption := FormatDateTime('dddd, d. mmmm', FBooking.Date, FS);
    FDeparture.Caption := L('{-}');
    FNights.Caption := L('{-}');
    FPrice.Caption := L('{-}');
    SetResult(FBookResult, 'Abreise w{ae}hlen');
    Exit;
  end;
  Price := 0;
  D := FBooking.RangeStart;
  while D < FBooking.RangeEnd do
  begin
    Price := Price + NightPrice(D);
    D := D + 1;
  end;
  FArrival.Caption := FormatDateTime('dddd, d. mmmm', FBooking.RangeStart, FS);
  FDeparture.Caption := FormatDateTime('dddd, d. mmmm', FBooking.RangeEnd, FS);
  FNights.Caption := IntToStr(N);
  FPrice.Caption := Euro(Price);
  SetResult(FBookResult, Format('%s {-} %s {.} %d N{ae}chte {.} %s',
    [FormatDateTime('dd.mm.', FBooking.RangeStart), FormatDateTime('dd.mm.', FBooking.RangeEnd),
     N, Euro(Price)]));
  if Sender <> nil then
    Host.Log('Calendar', Format('Zeitraum %s - %s', [DateToStr(FBooking.RangeStart),
      DateToStr(FBooking.RangeEnd)]));
end;

procedure TDemoDatesPage.BookClick(Sender: TObject);
begin
  if Trunc(FBooking.RangeEnd) - Trunc(FBooking.RangeStart) <= 0 then
  begin
    Host.Notifier.Show('Zeitraum fehlt', L('Bitte Anreise und Abreise w{ae}hlen.'), psWarning);
    Exit;
  end;
  Host.Notifier.Show('Gebucht', L(Format('%s bis %s {-} wir freuen uns auf Sie!',
    [DateToStr(FBooking.RangeStart), DateToStr(FBooking.RangeEnd)])), psSuccess, -1,
    ['Details', 'Kalender']);
  Host.Log('Buchung', FPrice.Caption);
end;

procedure TDemoDatesPage.WeekCalChange(Sender: TObject);
begin
  if FSyncing then
    Exit;
  FSyncing := True;
  try
    FDate.Date := FWeekCal.Date;
  finally
    FSyncing := False;
  end;
  MeetingChange(FWeekCal);
end;

procedure TDemoDatesPage.MeetingChange(Sender: TObject);
const
  Minutes: array[0..4] of Integer = (15, 30, 60, 120, 0);
var
  FS: TFormatSettings;
  S: string;
  EndTime: TDateTime;
begin
  FS := TFormatSettings.Create('de-DE');
  if (Sender = FDate) and not FSyncing then
  begin
    FSyncing := True;
    try
      FWeekCal.Date := FDate.Date;
    finally
      FSyncing := False;
    end;
  end;
  S := FormatDateTime('dddd, d. mmmm yyyy', FDate.Date, FS);
  if FDuration.ItemIndex = 4 then
    S := S + ' (ganzt{ae}gig)'
  else
  begin
    EndTime := FTime.Time + Minutes[Max(0, FDuration.ItemIndex)] / MinsPerDay;
    S := S + ', ' + FormatDateTime('hh:nn', FTime.Time) + '{-}' +
      FormatDateTime('hh:nn', EndTime) + ' Uhr';
  end;
  if FReminder.HasDate then
    S := S + ' {.} Erinnerung ' + FormatDateTime('dd.mm.', FReminder.Date);
  SetResult(FMeetResult, S);
  if (Sender <> nil) and (Sender <> FWeekCal) then
    Host.Log('Termin', L(S));
end;

{ Selbsttests }

procedure TDemoListsPage.SelfTest(Check: TDemoCheck);
begin
  FFeatures.Checked[3] := True;
  FeatureCheck(nil);
  Check('Listen: Checkliste rechnet (427 MB)', Pos('427 MB', FFeatureResult.Caption) > 0);
  DemoClick(FAllBtn);
  Check('Listen: Alle waehlt alle', FMulti.SelCount = FMulti.Items.Count);
  FJump.Value := 123456;
  DemoClick(FJumpBtn);
  Check('Listen: Springen in 1 Mio. Eintraegen', FVirtual.ItemIndex = 123455);
  Check('Listen: Ergebnis zeigt Datensatz', Pos('123.456', FVirtualResult.Caption) > 0);
end;

procedure TDemoExplorerPage.SelfTest(Check: TDemoCheck);

  function Find(const S: string): TPPGTreeNode;
  var
    I: Integer;
  begin
    Result := nil;
    for I := 0 to FTree.RowCount - 1 do
      if FTree.NodeOfRow(I).Text = S then
        Exit(FTree.NodeOfRow(I));
  end;

var
  N: TPPGTreeNode;
begin
  N := Find('Berichte');
  Check('Explorer: Knoten gefunden', N <> nil);
  if N = nil then
    Exit;
  FTree.Selected := N;
  ShowFolder(N);
  Check('Explorer: Liste zeigt Dateien des Ordners', FFiles.ItemsEx.Count = 3);
  Check('Explorer: Breadcrumb zeigt Pfad', (FCrumb.Items.Count = 3) and
    (FCrumb.Items[2] = 'Berichte'));
  CrumbClick(FCrumb, 0);
  Check('Explorer: Breadcrumb-Klick waehlt Vorfahren', (FTree.Selected <> nil) and
    (FTree.Selected.Text = 'Dieser PC'));
  N := Find(L('Netzlaufwerk (l{ae}dt beim Aufklappen)'));
  if N <> nil then
    N.Expand(False);
  Check('Explorer: Lazy Loading legt Kinder an', (N <> nil) and (N.Count = 4));
end;

procedure TDemoGridPage.SelfTest(Check: TDemoCheck);
var
  V: string;
  Ok: Boolean;
  MaxRow, R: Integer;
begin
  FillGrid;
  FGrid.Cells[ColQty, 1] := '10';
  CellSet(FGrid, ColQty, 1, '10');
  Check('Tabelle: Wert = Menge x Preis', FGrid.Cells[ColValue, 1] = FormatFloat('#,##0.00', 10 * 0.12));
  Check('Tabelle: Summe aktualisiert', Pos('30 Artikel', FSum.Caption) > 0);
  V := 'abc';
  Ok := True;
  CellValidate(FGrid, ColPrice, 1, V, Ok);
  Check('Tabelle: ungueltiger Preis abgelehnt', not Ok);
  V := '4.5';
  Ok := True;
  CellValidate(FGrid, ColPrice, 1, V, Ok);
  Check('Tabelle: Preis normalisiert', Ok and (V = FormatFloat('0.00', 4.5)));
  FGrid.SortBy(ColQty, False);
  // Die Zeile mit der groessten Menge muss ganz oben stehen
  MaxRow := 1;
  for R := 2 to FGrid.RowCount - 1 do
    if StrToIntDef(FGrid.Cells[ColQty, R], 0) > StrToIntDef(FGrid.Cells[ColQty, MaxRow], 0) then
      MaxRow := R;
  Ok := True;
  for R := 1 to FGrid.RowCount - 1 do
    if FGrid.VisualRow(R) < FGrid.VisualRow(MaxRow) then
      Ok := False;
  Check('Tabelle: Sortieren absteigend', Ok);
  FillGrid;
end;

procedure TDemoDatesPage.SelfTest(Check: TDemoCheck);
var
  D: TDate;
  Expected: Double;
  I: Integer;
begin
  // Drei freie Naechte ab einem Tag ohne Sperre suchen
  D := Date + 20;
  while (DayOfTheYear(D) mod 9 = 0) or (DayOfTheYear(D + 1) mod 9 = 0) or
    (DayOfTheYear(D + 2) mod 9 = 0) or (DayOfTheYear(D + 3) mod 9 = 0) do
    D := D + 1;
  FBooking.SelectRange(D, D + 3);
  BookingChange(FBooking);
  Expected := 0;
  for I := 0 to 2 do
    Expected := Expected + NightPrice(D + I);
  Check('Termine: drei Naechte', FNights.Caption = '3');
  Check('Termine: Preis stimmt', FPrice.Caption = Euro(Expected));
  Check('Termine: Ausgebuchter Tag gesperrt', FBooking.IsDateDisabled(EncodeDate(2026, 1, 9)));
  FWeekCal.Date := Date + 5;
  WeekCalChange(FWeekCal);
  Check('Termine: Kalender setzt Termin-Datum', Trunc(FDate.Date) = Trunc(Date + 5));
  FDuration.ItemIndex := 1;
  FTime.Time := EncodeTime(9, 0, 0, 0);
  MeetingChange(FDuration);
  Check('Termine: Ende = Beginn + Dauer', Pos('09:00' + #$2013 + '09:30', FMeetResult.Caption) > 0);
end;

end.
