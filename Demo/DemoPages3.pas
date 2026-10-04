unit DemoPages3;

{ Demo-Seiten "Layout", "Rueckmeldung", "Darstellung", "Ereignisse". }

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Forms,
  Vcl.Clipbrd, Vcl.Themes, Vcl.Menus,
  PPG.Types, PPG.Consts, PPG.Theme, PPG.Render.Registry, PPG.StyleManager,
  PPG.Controls.Base, PPG.Button, PPG.Panel, PPG.Labels, PPG.Items, PPG.CheckBox,
  PPG.RadioButton, PPG.ToggleSwitch, PPG.ProgressBar, PPG.Controls.Field, PPG.Edit,
  PPG.Memo, PPG.ComboBox, PPG.ListBox, PPG.TabControl, PPG.PageControl,
  PPG.Expander, PPG.Splitter, PPG.NavigationView, PPG.Feedback, PPG.Notifications,
  PPG.ToolBar, PPG.DpiUtils, PPG.Lang,
  DemoKit;

type
  TDemoLayoutPage = class(TDemoPage)
  private
    FTabs: TPPGTabControl;
    FTabContent: TPPGLabel;
    FTabResult: TPPGLabel;
    FTabCount: Integer;
    FPagesResult: TPPGLabel;
    FExpResult: TPPGLabel;
    FSplitList: TPPGListBox;
    FSplitResult: TPPGLabel;
    FNavContent: TPPGLabel;
    FNavResult: TPPGLabel;
    FNewTabBtn: TPPGButton;
    procedure TabChange(Sender: TObject);
    procedure TabClose(Sender: TObject; Index: Integer; var Action: TCloseAction);
    procedure NewTabClick(Sender: TObject);
    procedure PagesChange(Sender: TObject);
    procedure ExpChange(Sender: TObject);
    procedure SplitMoved(Sender: TObject);
    procedure NavChange(Sender: TObject);
  protected
    procedure Build; override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoFeedbackPage = class(TDemoPage)
  private
    FBarHost: TPanel;
    FBars: array[0..3] of TPPGInfoBar;
    FBarResult: TPPGLabel;
    FPosition: TPPGComboBox;
    FToastResult: TPPGLabel;
    FTimer: TTimer;
    FDownload: TPPGProgressBar;
    FRing: TPPGProgressRing;
    FDlText: TPPGLabel;
    FStart, FPause, FCancel: TPPGButton;
    FDlResult: TPPGLabel;
    FPaused: Boolean;
    FBadge: TPPGBadge;
    FBadgeResult: TPPGLabel;
    FPlus50: TPPGButton;
    procedure BarClosed(Sender: TObject);
    procedure BarAction(Sender: TObject);
    procedure ReopenClick(Sender: TObject);
    procedure UpdateBarResult;
    procedure ToastClick(Sender: TObject);
    procedure PositionChange(Sender: TObject);
    procedure StartClick(Sender: TObject);
    procedure PauseClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure UpdateDownloadText;
    procedure BadgeClick(Sender: TObject);
  protected
    procedure Build; override;
  public
    destructor Destroy; override;
    /// Rueckmeldung des Notification-Centers (vom Hauptformular weitergereicht).
    procedure ToastEvent(const Text: string);
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoAppearancePage = class(TDemoPage)
  private
    FPresetRadios: array[0..2] of TPPGRadioButton;
    FModeRadios: array[0..2] of TPPGRadioButton;
    FStyleCombo: TPPGComboBox;
    FGdi: TPPGToggleSwitch;
    FLang: TPPGComboBox;
    FInfo: TPPGLabel;
    FStyleInfo: TPPGInfoBar;
    FSyncing: Boolean;
    procedure PresetRadioChange(Sender: TObject);
    procedure ModeRadioChange(Sender: TObject);
    procedure StyleChange(Sender: TObject);
    procedure GdiChange(Sender: TObject);
    procedure LangChange(Sender: TObject);
    procedure FailClick(Sender: TObject);
    procedure UpdateInfo;
  protected
    procedure Build; override;
  public
    procedure AppearanceChanged; override;
    procedure Activated; override;
    procedure SelfTest(Check: TDemoCheck); override;
  end;

  TDemoEventsPage = class(TDemoPage)
  private
    FList: TPPGListBox;
    FResult: TPPGLabel;
    FCount: Integer;
    procedure ToolClick(Sender: TObject; Item: TPPGToolItem);
  protected
    procedure Build; override;
  public
    procedure AddEvent(const Category, Text: string);
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

const
  ColW = 484;
  FullW = 2 * ColW + CardGap;
  Col2X = PageX + ColW + CardGap;
  Col3W = (FullW - 2 * CardGap) div 3;

function NewHost(AOwner: TComponent; AParent: TWinControl; X, Y, W, H: Integer): TPanel;
begin
  // Unsichtbarer Traeger fuer ausgerichtete Kinder (Align) innerhalb einer Karte
  Result := TPanel.Create(AOwner);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, H);
  Result.BevelOuter := bvNone;
  Result.ParentBackground := True;
  Result.ParentColor := True;
  Result.Caption := '';
  Result.ShowCaption := False;
end;

{ TDemoLayoutPage }

procedure TDemoLayoutPage.Build;
var
  Card: TPPGPanel;
  PC: TPPGPageControl;
  S: TPPGTabSheet;
  Host2: TPanel;
  E: TPPGExpander;
  Sp: TPPGSplitter;
  M: TPPGMemo;
  NV: TPPGNavigationView;
  Cb: TPPGCheckBox;
  Sw: TPPGToggleSwitch;
  Ed: TPPGEdit;
  I, Y: Integer;
const
  PageNames: array[0..2] of string = ('Allgemein', 'Erweitert', 'Info');
begin
  NewPageHeader(Own, Sheet, 'Layout', 'Reiter mit Schlie{ss}en-Kn{oe}pfen und {Ue}berlauf, ' +
    'Seiten, aufklappbare Bereiche wie in den Windows-Einstellungen, Splitter und eine ' +
    'kompakte Navigation.');

  // TabControl
  Card := NewCard(Own, Sheet, PageX, PageContentTop, ColW, 290, 'Reiter (TabControl)',
    'Schlie{ss}en per X oder Mittelklick, Strg+Tab wechselt. Neue Reiter erzeugen den ' +
    '{Ue}berlauf mit Bl{ae}tterpfeilen.');
  Y := Card.Tag;
  FTabs := TPPGTabControl.Create(Own);
  FTabs.Parent := Card;
  FTabs.SetBounds(CardPad, Y, ColW - 2 * CardPad, 120);
  for I := 1 to 4 do
    FTabs.Tabs.Add('Dokument ' + IntToStr(I));
  FTabCount := 4;
  FTabs.ShowCloseButtons := True;
  FTabs.TabIndex := 0;
  FTabs.OnChange := TabChange;
  FTabs.OnClose := TabClose;
  FTabContent := NewLabel(Own, FTabs, 20, 60, 380, '', tkSubtitle);
  FNewTabBtn := NewButton(Own, Card, CardPad, Y + 128, 140, 'Neuer Reiter', NewTabClick);
  FNewTabBtn.Tag := 1;
  FTabResult := NewResult(Own, Card, 'Reiter');
  TabChange(nil);

  // PageControl
  Card := NewCard(Own, Sheet, Col2X, PageContentTop, ColW, 290, 'Seiten (PageControl)',
    'Jede Seite hat eigene Controls; der Unterstrich gleitet zum gew{ae}hlten Reiter.');
  Y := Card.Tag;
  PC := TPPGPageControl.Create(Own);
  PC.Parent := Card;
  PC.SetBounds(CardPad, Y, ColW - 2 * CardPad, 160);
  PC.Images := Host.Images;
  for I := 0 to 2 do
  begin
    S := TPPGTabSheet.Create(Own);
    S.Caption := L(PageNames[I]);
    S.PageControl := PC;
  end;
  Ed := TPPGEdit.Create(Own);
  Ed.Parent := PC.Pages[0];
  Ed.SetBounds(16, 16, 260, CtlH);
  Ed.TextHint := 'Projektname';
  Cb := TPPGCheckBox.Create(Own);
  Cb.Parent := PC.Pages[0];
  Cb.SetBounds(16, 60, 260, 28);
  Cb.Caption := L('Automatisch speichern');
  Cb.Checked := True;
  Sw := TPPGToggleSwitch.Create(Own);
  Sw.Parent := PC.Pages[1];
  Sw.SetBounds(16, 16, 260, CtlH);
  Sw.Caption := 'Protokoll schreiben';
  Cb := TPPGCheckBox.Create(Own);
  Cb.Parent := PC.Pages[1];
  Cb.SetBounds(16, 56, 260, 28);
  Cb.Caption := L('Experimentelle Funktionen');
  NewLabel(Own, PC.Pages[2], 16, 16, 380, 'PPGlow {-} VCL-Komponenten f{ue}r Delphi XE2 bis 13. ' +
    'Diese Seite ist reiner Text.', tkBody);
  PC.ActivePageIndex := 0;
  PC.OnChange := PagesChange;
  FPagesResult := NewResult(Own, Card, 'Aktive Seite');
  SetResult(FPagesResult, PC.ActivePage.Caption);

  // Expander
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 290 + CardGap, Col3W, 320, 'Expander',
    'Kategorien klappen weich auf und zu.');
  Host2 := NewHost(Own, Card, CardPad, Card.Tag, Col3W - 2 * CardPad, 320 - Card.Tag - 46);
  E := TPPGExpander.Create(Own);
  E.Parent := Host2;
  E.Top := 0;
  E.Height := 100;
  E.Align := alTop;
  E.Caption := 'Allgemein';
  E.Detail := 'Name und Sprache';
  E.OnExpanded := ExpChange;
  E.OnCollapsed := ExpChange;
  Ed := TPPGEdit.Create(Own);
  Ed.Parent := E;
  Ed.SetBounds(16, 56, 200, CtlH);
  Ed.TextHint := 'Anzeigename';
  E := TPPGExpander.Create(Own);
  E.Parent := Host2;
  E.Top := 200;
  E.Height := 100;
  E.Align := alTop;
  E.Caption := 'Darstellung';
  E.Detail := 'Farben und Schrift';
  E.OnExpanded := ExpChange;
  E.OnCollapsed := ExpChange;
  Cb := TPPGCheckBox.Create(Own);
  Cb.Parent := E;
  Cb.SetBounds(16, 58, 200, 28);
  Cb.Caption := 'Kompakte Zeilen';
  E.Expanded := False;
  E := TPPGExpander.Create(Own);
  E.Parent := Host2;
  E.Top := 400;
  E.Height := 100;
  E.Align := alTop;
  E.Caption := 'Erweitert';
  E.Detail := 'Nur f{ue}r Profis';
  E.Detail := L(E.Detail);
  E.OnExpanded := ExpChange;
  E.OnCollapsed := ExpChange;
  Sw := TPPGToggleSwitch.Create(Own);
  Sw.Parent := E;
  Sw.SetBounds(16, 56, 200, CtlH);
  Sw.Caption := 'Entwicklermodus';
  E.Expanded := False;
  FExpResult := NewResult(Own, Card, 'Zuletzt');

  // Splitter
  Card := NewCard(Own, Sheet, PageX + Col3W + CardGap, PageContentTop + 290 + CardGap, Col3W, 320,
    'Splitter', 'Ziehen oder mit Fokus per Pfeiltasten verschieben.');
  Host2 := NewHost(Own, Card, CardPad, Card.Tag, Col3W - 2 * CardPad, 320 - Card.Tag - 46);
  FSplitList := TPPGListBox.Create(Own);
  FSplitList.Parent := Host2;
  FSplitList.Align := alLeft;
  FSplitList.Width := 110;
  FSplitList.Items.CommaText := 'Eins,Zwei,Drei,Vier,F{ue}nf';
  FSplitList.Items.CommaText := L(FSplitList.Items.CommaText);
  Sp := TPPGSplitter.Create(Own);
  Sp.Parent := Host2;
  Sp.Left := 120;
  Sp.Align := alLeft;
  Sp.TabStop := True;
  Sp.MinSize := 60;
  Sp.OnMoved := SplitMoved;
  M := TPPGMemo.Create(Own);
  M.Parent := Host2;
  M.Align := alClient;
  M.Lines.Text := L('Der Splitter ver{ae}ndert die Breite der Liste links.');
  FSplitResult := NewResult(Own, Card, 'Breite der Liste');
  SplitMoved(nil);

  // Kompakte NavigationView
  Card := NewCard(Own, Sheet, PageX + 2 * (Col3W + CardGap), PageContentTop + 290 + CardGap,
    Col3W, 320, 'Kompakte Navigation', 'Nur Symbole; das Men{ue} oben klappt die Leiste auf.');
  Host2 := NewHost(Own, Card, CardPad, Card.Tag, Col3W - 2 * CardPad, 320 - Card.Tag - 46);
  NV := TPPGNavigationView.Create(Own);
  NV.Parent := Host2;
  NV.Align := alLeft;
  NV.DisplayMode := pdmLeftCompact;
  NV.OpenPaneLength := 180;
  NV.Items.AddItem('Start', $E80F);
  NV.Items.AddItem('Post', $E715).BadgeCount := 2;
  NV.Items.AddItem('Kontakte', $E716);
  NV.Items.AddItem('Kalender', $E787);
  NV.Items.AddItem('Einstellungen', $E713).Footer := True;
  NV.OnSelectionChange := NavChange;
  FNavContent := NewLabel(Own, Host2, 64, 12, 0, '', tkSubtitle);
  FNavResult := NewResult(Own, Card, 'Gew{ae}hlt');
  NV.Selected := NV.Items[0];
  NavChange(NV);
end;

procedure TDemoLayoutPage.TabChange(Sender: TObject);
var
  S: string;
begin
  if FTabs.TabIndex >= 0 then
    S := FTabs.Tabs[FTabs.TabIndex]
  else
    S := 'kein Reiter';
  FTabContent.Caption := L('Inhalt von {>} ') + S;
  SetResult(FTabResult, Format('%d offen {.} aktiv: %s', [FTabs.Tabs.Count, S]));
  if Sender <> nil then
    Host.Log('TabControl', S);
end;

procedure TDemoLayoutPage.TabClose(Sender: TObject; Index: Integer; var Action: TCloseAction);
begin
  Host.Log('TabControl', 'Geschlossen: ' + FTabs.Tabs[Index]);
  Action := caFree;
  // Der Reiter verschwindet erst nach diesem Ereignis; ist er aktiv, folgt OnChange
  SetResult(FTabResult, Format('%d offen', [FTabs.Tabs.Count - 1]));
end;

procedure TDemoLayoutPage.NewTabClick(Sender: TObject);
begin
  Inc(FTabCount);
  FTabs.Tabs.Add('Dokument ' + IntToStr(FTabCount));
  FTabs.TabIndex := FTabs.Tabs.Count - 1;
  TabChange(Sender);
end;

procedure TDemoLayoutPage.PagesChange(Sender: TObject);
begin
  SetResult(FPagesResult, TPPGPageControl(Sender).ActivePage.Caption);
  Host.Log('PageControl', TPPGPageControl(Sender).ActivePage.Caption);
end;

procedure TDemoLayoutPage.ExpChange(Sender: TObject);
const
  States: array[Boolean] of string = ('zugeklappt', 'aufgeklappt');
begin
  SetResult(FExpResult, TPPGExpander(Sender).Caption + ' ' + States[TPPGExpander(Sender).Expanded]);
  Host.Log('Expander', TPPGExpander(Sender).Caption + ' ' + States[TPPGExpander(Sender).Expanded]);
end;

procedure TDemoLayoutPage.SplitMoved(Sender: TObject);
begin
  SetResult(FSplitResult, IntToStr(FSplitList.Width) + ' px');
  if Sender <> nil then
    Host.Log('Splitter', IntToStr(FSplitList.Width) + ' px');
end;

procedure TDemoLayoutPage.NavChange(Sender: TObject);
var
  NV: TPPGNavigationView;
begin
  NV := TPPGNavigationView(Sender);
  if NV.Selected = nil then
    Exit;
  FNavContent.Caption := NV.Selected.Caption;
  SetResult(FNavResult, NV.Selected.Caption);
  Host.Log('NavigationView', NV.Selected.Caption);
end;

{ TDemoFeedbackPage }

destructor TDemoFeedbackPage.Destroy;
begin
  if FTimer <> nil then
    FTimer.Enabled := False;
  inherited Destroy;
end;

procedure TDemoFeedbackPage.Build;
const
  Sev: array[0..3] of TPPGSeverity = (psInformational, psSuccess, psWarning, psError);
  Titles: array[0..3] of string = ('Hinweis', 'Gespeichert', 'Achtung', 'Fehler');
  Msgs: array[0..3] of string = ('Ein Update ist verf{ue}gbar.',
    'Alle {Ae}nderungen sind gesichert.', 'Es gibt <b>3</b> ungespeicherte {Ae}nderungen.',
    'Die Verbindung zum Server ist unterbrochen.');
  ToastCaptions: array[0..3] of string = ('Hinweis', 'Erfolg mit Aktionen', 'Fehler (bleibt)',
    'Drei auf einmal');
  StateNames: array[0..3] of string = ('Normal', 'Pausiert', 'Fehler', 'Unbestimmt');
var
  Card: TPPGPanel;
  I, Y: Integer;
  B: TPPGButton;
  Bd: TPPGBadge;
  PB: TPPGProgressBar;
begin
  NewPageHeader(Own, Sheet, 'R{ue}ckmeldung', 'Hinweisleisten in vier Stufen, Toasts mit ' +
    'Aktionen, ein simulierter Download mit Pause und Abbruch sowie Plaketten.');

  // InfoBars
  Card := NewCard(Own, Sheet, PageX, PageContentTop, ColW, 380, 'Hinweisleisten (InfoBar)',
    'Schlie{ss}en per X oder Esc {-} die anderen r{ue}cken nach.');
  FBarHost := NewHost(Own, Card, CardPad, Card.Tag, ColW - 2 * CardPad, 380 - Card.Tag - 90);
  for I := 0 to 3 do
  begin
    FBars[I] := TPPGInfoBar.Create(Own);
    FBars[I].Top := I * 100;
    FBars[I].Parent := FBarHost;
    FBars[I].Align := alTop;
    FBars[I].AlignWithMargins := True;
    FBars[I].Margins.SetBounds(0, 0, 0, 6);
    FBars[I].Severity := Sev[I];
    FBars[I].Title := L(Titles[I]);
    FBars[I].Message := L(Msgs[I]);
    FBars[I].OnClose := BarClosed;
  end;
  FBars[0].ActionCaption := 'Installieren';
  FBars[0].OnActionClick := BarAction;
  FBars[2].ActionCaption := 'Speichern';
  FBars[2].OnActionClick := BarAction;
  NewButton(Own, Card, CardPad, 380 - 82, 180, 'Alle wieder anzeigen', ReopenClick).Tag := 1;
  FBarResult := NewResult(Own, Card, 'Offen');
  UpdateBarResult;

  // Toasts
  Card := NewCard(Own, Sheet, Col2X, PageContentTop, ColW, 380, 'Benachrichtigungen (Toast)',
    'Erscheinen ohne den Fokus zu stehlen. Maus dar{ue}ber h{ae}lt sie an, h{oe}chstens drei ' +
    'sind gleichzeitig sichtbar.');
  Y := Card.Tag;
  for I := 0 to High(ToastCaptions) do
  begin
    B := NewButton(Own, Card, CardPad + (I mod 2) * 226, Y + (I div 2) * 44, 214,
      ToastCaptions[I], ToastClick, I = 1);
    B.HelpContext := I;
    if I = 0 then
      B.Tag := 1;
  end;
  NewLabel(Own, Card, CardPad, Y + 100, 0, 'Position', tkBody);
  FPosition := TPPGComboBox.Create(Own);
  FPosition.Parent := Card;
  FPosition.Style := csDropDownList;
  FPosition.SetBounds(CardPad + 90, Y + 94, 200, CtlH);
  FPosition.Items.Text := 'Unten rechts'#13#10'Oben rechts'#13#10'Unten links'#13#10'Oben links';
  FPosition.ItemIndex := 0;
  FPosition.OnChange := PositionChange;
  FToastResult := NewResult(Own, Card, 'Zuletzt');

  // Download
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 380 + CardGap, ColW, 262,
    'Download simulieren', 'Fortschritt mit Text, Ring w{ae}hrend der Arbeit, Pause (gelb) und ' +
    'Abbruch (rot). Am Ende kommt ein Toast.');
  Y := Card.Tag;
  FDownload := TPPGProgressBar.Create(Own);
  FDownload.Parent := Card;
  FDownload.SetBounds(CardPad, Y + 6, ColW - 2 * CardPad - 50, 20);
  FDownload.ShowText := True;
  FRing := TPPGProgressRing.Create(Own);
  FRing.Parent := Card;
  FRing.SetBounds(ColW - CardPad - 32, Y, 32, 32);
  FRing.Visible := False;
  FDlText := NewLabel(Own, Card, CardPad, Y + 36, ColW - 2 * CardPad, '', tkSecondary);
  FStart := NewButton(Own, Card, CardPad, Y + 70, 130, 'Starten', StartClick, True);
  FStart.Tag := 1;
  FPause := NewButton(Own, Card, CardPad + 142, Y + 70, 130, 'Pause', PauseClick);
  FCancel := NewButton(Own, Card, CardPad + 284, Y + 70, 130, 'Abbrechen', CancelClick);
  FPause.Enabled := False;
  FCancel.Enabled := False;
  FDlResult := NewResult(Own, Card, 'Status');
  SetResult(FDlResult, 'bereit');
  FTimer := TTimer.Create(Own);
  FTimer.Enabled := False;
  FTimer.Interval := 80;
  FTimer.OnTimer := TimerTick;
  UpdateDownloadText;

  // Plaketten und Zustaende
  Card := NewCard(Own, Sheet, Col2X, PageContentTop + 380 + CardGap, ColW, 262,
    'Plaketten und Zust{ae}nde', 'Zahlen ab 100 werden zu 99+. Darunter die Zust{ae}nde des ' +
    'Fortschrittsbalkens.');
  Y := Card.Tag;
  B := NewButton(Own, Card, CardPad, Y, 44, '{-}', BadgeClick);
  B.HelpContext := -1;
  FBadge := TPPGBadge.Create(Own);
  FBadge.Parent := Card;
  FBadge.Left := CardPad + 58;
  FBadge.Top := Y + 7;
  FBadge.Value := 5;
  B := NewButton(Own, Card, CardPad + 110, Y, 44, '+', BadgeClick);
  B.HelpContext := 1;
  B := NewButton(Own, Card, CardPad + 162, Y, 60, '+50', BadgeClick);
  FPlus50 := B;
  B.HelpContext := 50;
  Bd := TPPGBadge.Create(Own);
  Bd.Parent := Card;
  Bd.Left := CardPad + 250;
  Bd.Top := Y + 7;
  Bd.Kind := bkText;
  Bd.Caption := 'Neu';
  Bd.BadgeColor := bcSuccess;
  Bd := TPPGBadge.Create(Own);
  Bd.Parent := Card;
  Bd.Left := CardPad + 300;
  Bd.Top := Y + 7;
  Bd.Kind := bkText;
  Bd.Caption := 'Beta';
  Bd.BadgeColor := bcWarning;
  for I := 0 to 2 do
  begin
    Bd := TPPGBadge.Create(Own);
    Bd.Parent := Card;
    Bd.Kind := bkDot;
    Bd.SetBounds(CardPad + 360 + I * 20, Y + 12, 8, 8);
    case I of
      0: Bd.BadgeColor := bcSuccess;
      1: Bd.BadgeColor := bcWarning;
    else
      Bd.BadgeColor := bcError;
    end;
  end;
  for I := 0 to 3 do
  begin
    PB := TPPGProgressBar.Create(Own);
    PB.Parent := Card;
    PB.SetBounds(CardPad + 90, Y + 48 + I * 22, ColW - 2 * CardPad - 90, 6);
    NewLabel(Own, Card, CardPad, Y + 41 + I * 22, 0, StateNames[I], tkCaption);
    case I of
      0: PB.Position := 70;
      1:
        begin
          PB.Position := 45;
          PB.State := pbsPaused;
        end;
      2:
        begin
          PB.Position := 85;
          PB.State := pbsError;
        end;
    else
      PB.Style := pbstMarquee;
    end;
  end;
  FBadgeResult := NewResult(Own, Card, 'Z{ae}hler');
  SetResult(FBadgeResult, '5');
end;

procedure TDemoFeedbackPage.UpdateBarResult;
var
  I, N: Integer;
begin
  N := 0;
  for I := 0 to 3 do
    if FBars[I].IsOpen then
      Inc(N);
  SetResult(FBarResult, Format('%d von 4', [N]));
end;

procedure TDemoFeedbackPage.BarClosed(Sender: TObject);
begin
  UpdateBarResult;
  Host.Log('InfoBar', 'Geschlossen: ' + TPPGInfoBar(Sender).Title);
end;

procedure TDemoFeedbackPage.BarAction(Sender: TObject);
var
  Bar: TPPGInfoBar;
begin
  Bar := TPPGInfoBar(Sender);
  Host.Log('InfoBar', 'Aktion: ' + Bar.ActionCaption);
  Bar.IsOpen := False;
  UpdateBarResult;
  if Bar = FBars[2] then
    Host.Notifier.Show('Gespeichert', L('Die 3 {Ae}nderungen wurden gespeichert.'), psSuccess)
  else
    Host.Notifier.Show('Update', L('Das Update wird im Hintergrund installiert.'), psInformational);
end;

procedure TDemoFeedbackPage.ReopenClick(Sender: TObject);
var
  I: Integer;
begin
  // In Anzeige-Reihenfolge oeffnen (alTop: zuletzt geoeffnet = unten)
  for I := 0 to 3 do
  begin
    FBars[I].Top := I * 100;
    FBars[I].IsOpen := True;
  end;
  UpdateBarResult;
  Host.Log('InfoBar', 'Alle wieder angezeigt');
end;

procedure TDemoFeedbackPage.ToastClick(Sender: TObject);
var
  I: Integer;
begin
  case TControl(Sender).HelpContext of
    0: Host.Notifier.Show('Hinweis', L('Ein einfacher Toast, der nach 5 Sekunden ausblendet.'),
         psInformational);
    1: Host.Notifier.Show('Export fertig', L('Die Datei <b>Bericht.pdf</b> wurde erstellt.'),
         psSuccess, -1, [L('{Oe}ffnen'), 'Ordner zeigen']);
    2: Host.Notifier.Show('Verbindung verloren', L('Der Server antwortet nicht. Dieser Toast ' +
         'bleibt, bis Sie ihn schlie{ss}en.'), psError, 0, ['Erneut versuchen']);
  else
    for I := 1 to 3 do
      Host.Notifier.Show('Nachricht ' + IntToStr(I), L('Toasts stapeln sich in der Ecke.'),
        psInformational);
  end;
  Host.Log('Toast', StripHotkey(TPPGButton(Sender).Caption));
end;

procedure TDemoFeedbackPage.ToastEvent(const Text: string);
begin
  SetResult(FToastResult, MarkupEscape(Text));
end;

procedure TDemoFeedbackPage.PositionChange(Sender: TObject);
begin
  Host.Notifier.CloseAll;
  Host.Notifier.Position := TPPGToastPosition(FPosition.ItemIndex);
  Host.Notifier.Show('Neue Position', FPosition.Text, psInformational);
end;

procedure TDemoFeedbackPage.UpdateDownloadText;
var
  Done: Double;
begin
  Done := FDownload.Position * 0.48;
  if FDownload.Position >= 100 then
    FDlText.Caption := L('48,0 MB {-} fertig')
  else
    FDlText.Caption := L(Format('%s von 48,0 MB {.} noch etwa %d s',
      [FormatFloat('0.0', Done), Ceil((100 - FDownload.Position) * 0.08)]));
end;

procedure TDemoFeedbackPage.StartClick(Sender: TObject);
begin
  FDownload.Position := 0;
  FDownload.State := pbsNormal;
  FPaused := False;
  FPause.Caption := 'Pause';
  FTimer.Enabled := True;
  FRing.Visible := True;
  FStart.Enabled := False;
  FPause.Enabled := True;
  FCancel.Enabled := True;
  SetResult(FDlResult, 'l{ae}dt{...}');
  Host.Log('Download', 'Gestartet');
end;

procedure TDemoFeedbackPage.PauseClick(Sender: TObject);
begin
  FPaused := not FPaused;
  FTimer.Enabled := not FPaused;
  FRing.Visible := not FPaused;
  if FPaused then
  begin
    FDownload.State := pbsPaused;
    FPause.Caption := 'Fortsetzen';
    SetResult(FDlResult, 'pausiert');
  end
  else
  begin
    FDownload.State := pbsNormal;
    FPause.Caption := 'Pause';
    SetResult(FDlResult, 'l{ae}dt{...}');
  end;
  Host.Log('Download', FPause.Caption);
end;

procedure TDemoFeedbackPage.CancelClick(Sender: TObject);
begin
  FTimer.Enabled := False;
  FRing.Visible := False;
  FDownload.State := pbsError;
  FStart.Enabled := True;
  FPause.Enabled := False;
  FCancel.Enabled := False;
  FPause.Caption := 'Pause';
  SetResult(FDlResult, 'abgebrochen');
  Host.Notifier.Show('Download abgebrochen', L('Sie k{oe}nnen ihn jederzeit neu starten.'),
    psWarning);
  Host.Log('Download', 'Abgebrochen');
end;

procedure TDemoFeedbackPage.TimerTick(Sender: TObject);
begin
  FDownload.Position := Min(100, FDownload.Position + 1);
  UpdateDownloadText;
  if FDownload.Position >= 100 then
  begin
    FTimer.Enabled := False;
    FRing.Visible := False;
    FStart.Enabled := True;
    FPause.Enabled := False;
    FCancel.Enabled := False;
    SetResult(FDlResult, 'fertig');
    Host.Notifier.Show('Download abgeschlossen', L('<b>Installer.exe</b> (48 MB) liegt im ' +
      'Download-Ordner.'), psSuccess, -1, [L('{Oe}ffnen'), 'Ordner zeigen']);
    Host.Log('Download', 'Fertig');
  end;
end;

procedure TDemoFeedbackPage.BadgeClick(Sender: TObject);
begin
  FBadge.Value := Max(0, FBadge.Value + TControl(Sender).HelpContext);
  SetResult(FBadgeResult, IntToStr(FBadge.Value) + ' (angezeigt: ' + FBadge.DisplayText + ')');
  Host.Log('Badge', IntToStr(FBadge.Value));
end;

{ TDemoAppearancePage }

procedure TDemoAppearancePage.Build;
const
  Presets: array[0..2] of string = (PPGPresetClassic, PPGPresetModernFlat, PPGPresetFluent11);
  PresetText: array[0..2] of string = ('Gl{ae}nzend mit Verlauf, angelehnt an Office.',
    'Flach mit weichem Glow {-} der Klassiker der Suite.',
    'Windows 11: Akzentfarbe des Systems, Symbolschrift, 4-px-Ecken.');
  ModeNames: array[0..2] of string = ('Hell', 'Dunkel', 'Wie Windows');
var
  Card, Tile: TPPGPanel;
  Mgr: TPPGStyleManager;
  I, W, Y: Integer;
  B: TPPGButton;
  Cb: TPPGCheckBox;
  Sw: TPPGToggleSwitch;
  PB: TPPGProgressBar;
  SR: TSearchRec;
begin
  NewPageHeader(Own, Sheet, 'Darstellung', 'Ein Preset bestimmt die Optik aller Controls. ' +
    'Hell/Dunkel, VCL-Styles und der GDI-Fallback lassen sich live umschalten.');

  // Presets mit fester Vorschau (eigener StyleManager je Kachel)
  Card := NewCard(Own, Sheet, PageX, PageContentTop, FullW, 270, 'Preset',
    'Die Vorschau in jeder Kachel bleibt im jeweiligen Preset; die Auswahl gilt f{ue}r die ' +
    'ganze Demo.');
  W := (FullW - 2 * CardPad - 2 * CardGap) div 3;
  for I := 0 to 2 do
  begin
    Mgr := TPPGStyleManager.Create(Own);
    Mgr.Preset := Presets[I];
    Tile := TPPGPanel.Create(Own);
    Tile.Parent := Card;
    Tile.ShowCaption := False;
    Tile.SetBounds(CardPad + I * (W + CardGap), Card.Tag, W, 270 - Card.Tag - 20);
    FPresetRadios[I] := TPPGRadioButton.Create(Own);
    FPresetRadios[I].Parent := Tile;
    FPresetRadios[I].SetBounds(14, 12, W - 28, 26);
    FPresetRadios[I].Caption := Presets[I];
    FPresetRadios[I].GroupIndex := 10;
    FPresetRadios[I].Tag := I;
    FPresetRadios[I].OnChange := PresetRadioChange;
    NewLabel(Own, Tile, 42, 38, W - 56, PresetText[I], tkCaption);
    B := TPPGButton.Create(Own);
    B.Parent := Tile;
    B.StyleManager := Mgr;
    B.SetBounds(14, 84, 110, CtlH);
    B.Caption := 'Button';
    Cb := TPPGCheckBox.Create(Own);
    Cb.Parent := Tile;
    Cb.StyleManager := Mgr;
    Cb.SetBounds(136, 86, 120, 28);
    Cb.Caption := 'Aktiv';
    Cb.Checked := True;
    Sw := TPPGToggleSwitch.Create(Own);
    Sw.Parent := Tile;
    Sw.StyleManager := Mgr;
    Sw.SetBounds(14, 124, 120, CtlH);
    Sw.Checked := True;
    PB := TPPGProgressBar.Create(Own);
    PB.Parent := Tile;
    PB.StyleManager := Mgr;
    PB.SetBounds(136, 136, W - 150, 8);
    PB.Position := 60;
  end;

  // Farbmodus
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 270 + CardGap, Col3W, 190, 'Farbmodus',
    'Dunkel ohne VCL-Style, inklusive Titelleiste.');
  Y := Card.Tag;
  for I := 0 to 2 do
  begin
    FModeRadios[I] := TPPGRadioButton.Create(Own);
    FModeRadios[I].Parent := Card;
    FModeRadios[I].SetBounds(CardPad, Y + I * 30, Col3W - 2 * CardPad, 26);
    FModeRadios[I].Caption := ModeNames[I];
    FModeRadios[I].GroupIndex := 11;
    FModeRadios[I].Tag := I;
    FModeRadios[I].OnChange := ModeRadioChange;
  end;

  // VCL-Style und Zeichnen
  Card := NewCard(Own, Sheet, PageX + Col3W + CardGap, PageContentTop + 270 + CardGap, Col3W, 190,
    'VCL-Style', 'PPGlow {ue}bernimmt die Farben des aktiven Styles.');
  FStyleCombo := TPPGComboBox.Create(Own);
  FStyleCombo.Parent := Card;
  FStyleCombo.Style := csDropDownList;
  FStyleCombo.SetBounds(CardPad, Card.Tag, Col3W - 2 * CardPad, CtlH);
  FStyleCombo.Items.Add('Windows');
  if FindFirst(StylesDir + 'Windows10*.vsf', faAnyFile, SR) = 0 then
  try
    repeat
      FStyleCombo.Items.Add(ChangeFileExt(SR.Name, ''));
    until FindNext(SR) <> 0;
  finally
    FindClose(SR);
  end;
  FStyleCombo.ItemIndex := 0;
  FStyleCombo.OnChange := StyleChange;
  FStyleInfo := TPPGInfoBar.Create(Own);
  FStyleInfo.Parent := Card;
  FStyleInfo.SetBounds(CardPad, Card.Tag + 42, Col3W - 2 * CardPad, 40);
  FStyleInfo.Severity := psWarning;
  FStyleInfo.Title := '';
  FStyleInfo.IsOpen := False;

  Card := NewCard(Own, Sheet, PageX + 2 * (Col3W + CardGap), PageContentTop + 270 + CardGap, Col3W,
    190, 'Zeichnen und Sprache', 'GDI-Fallback ohne GDI+; Sprache der eingebauten Texte.');
  FGdi := TPPGToggleSwitch.Create(Own);
  FGdi.Parent := Card;
  FGdi.SetBounds(CardPad, Card.Tag, Col3W - 2 * CardPad, CtlH);
  FGdi.Caption := L('GDI-Fallback erzwingen');
  FGdi.OnChange := GdiChange;
  // Uebersetzung zur Laufzeit (PPG.Lang): Hinweise, Prozentwerte,
  // Screenreader-Namen und Meldungen der Controls
  FLang := TPPGComboBox.Create(Own);
  FLang.Parent := Card;
  FLang.Style := csDropDownList;
  FLang.SetBounds(CardPad, Card.Tag + 42, Col3W - 2 * CardPad, CtlH);
  FLang.Items.Add('Texte: Englisch (Original)');
  FLang.Items.Add('Texte: Deutsch');
  FLang.Items.Add('Texte: wie Windows');
  FLang.ItemIndex := 0;
  FLang.OnChange := LangChange;

  // Robustheit
  Card := NewCard(Own, Sheet, PageX, PageContentTop + 270 + 190 + 2 * CardGap, ColW, 204,
    'Robustheit', 'Eine Exception im OnClick l{ae}uft normal zur Anwendung; der Button bleibt ' +
    'danach voll bedienbar. Fehler in Paint und Animation f{ae}ngt PPGlow ab und meldet sie.');
  B := NewButton(Own, Card, CardPad, Card.Tag + 6, 220, 'OnClick l{oe}st Exception aus', FailClick);
  B.Tag := 1;

  // Systeminfo
  Card := NewCard(Own, Sheet, Col2X, PageContentTop + 270 + 190 + 2 * CardGap, ColW, 204,
    'Umgebung', '');
  FInfo := NewLabel(Own, Card, CardPad, Card.Tag, ColW - 2 * CardPad, '', tkBody);
  FInfo.AllowMarkup := True;
  FInfo.AutoSize := True;
  AppearanceChanged;
end;

procedure TDemoAppearancePage.UpdateInfo;
const
  ModeNames: array[TPPGThemeMode] of string = ('Hell', 'Dunkel', 'System');
var
  S, Lang: string;
begin
  if FInfo = nil then
    Exit;
  Lang := PPGLanguage;
  if Lang = '' then
    Lang := 'en';
  if TPPGRendererRegistry.ForceGdiFallback then
    S := 'GDI (erzwungen)'
  else
    S := 'GDI+';
  FInfo.Caption := L(Format('Zeichnen: <b>%s</b><br>Preset: <b>%s</b>  {.}  Modus: <b>%s</b>' +
    '<br>Bildschirm: <b>%d DPI</b> (Skalierung %d %%)<br>Windows <b>%d.%d</b> Build <b>%d</b>' +
    '<br>Delphi-Compiler <b>%s</b>, %d Bit  {.}  Texte: <b>%s</b>',
    [S, Host.CurrentPreset, ModeNames[TPPGTheme.Mode],
     Sheet.CurrentPPI, MulDiv(Sheet.CurrentPPI, 100, 96), TOSVersion.Major, TOSVersion.Minor,
     TOSVersion.Build, FormatFloat('0.0', CompilerVersion), SizeOf(Pointer) * 8, Lang]));
end;

procedure TDemoAppearancePage.AppearanceChanged;
var
  I: Integer;
const
  Presets: array[0..2] of string = (PPGPresetClassic, PPGPresetModernFlat, PPGPresetFluent11);
begin
  if FPresetRadios[0] = nil then
    Exit;
  FSyncing := True;
  try
    for I := 0 to 2 do
    begin
      FPresetRadios[I].Checked := SameText(Presets[I], Host.CurrentPreset);
      FModeRadios[I].Checked := Ord(TPPGTheme.Mode) = I;
    end;
  finally
    FSyncing := False;
  end;
  UpdateInfo;
end;

procedure TDemoAppearancePage.Activated;
begin
  UpdateInfo;
end;

procedure TDemoAppearancePage.PresetRadioChange(Sender: TObject);
begin
  if FSyncing or not TPPGRadioButton(Sender).Checked then
    Exit;
  Host.ApplyPreset(TPPGRadioButton(Sender).Caption);
  Host.Log('Darstellung', 'Preset: ' + TPPGRadioButton(Sender).Caption);
end;

procedure TDemoAppearancePage.ModeRadioChange(Sender: TObject);
begin
  if FSyncing or not TPPGRadioButton(Sender).Checked then
    Exit;
  TPPGTheme.Mode := TPPGThemeMode(TPPGRadioButton(Sender).Tag);
  Host.Log('Darstellung', 'Modus: ' + TPPGRadioButton(Sender).Caption);
end;

procedure TDemoAppearancePage.StyleChange(Sender: TObject);
begin
  if FStyleCombo.ItemIndex < 0 then
    Exit;
  try
    Host.ApplyVclStyle(FStyleCombo.Items[FStyleCombo.ItemIndex]);
    FStyleInfo.IsOpen := False;
    Host.Log('Darstellung', 'VCL-Style: ' + FStyleCombo.Items[FStyleCombo.ItemIndex]);
  except
    on E: Exception do
    begin
      FStyleInfo.Message := MarkupEscape(E.Message);
      FStyleInfo.IsOpen := True;
    end;
  end;
end;

procedure TDemoAppearancePage.GdiChange(Sender: TObject);
var
  F: TCustomForm;
begin
  TPPGRendererRegistry.ForceGdiFallback := FGdi.Checked;
  F := GetParentForm(Sheet);
  if F <> nil then
    RedrawWindow(F.Handle, nil, 0, RDW_INVALIDATE or RDW_ALLCHILDREN or RDW_UPDATENOW);
  UpdateInfo;
  Host.Log('Darstellung', 'GDI-Fallback: ' + BoolToStr(FGdi.Checked, True));
end;

procedure TDemoAppearancePage.LangChange(Sender: TObject);
begin
  case FLang.ItemIndex of
    1: PPGSetLanguage('de');
    2: PPGSetLanguage(PPGSystemLanguage);
  else
    PPGSetLanguage('');
  end;
  UpdateInfo;
  // Sichtbarer Beweis: die Prozentanzeige im Hinweis der Fortschrittsleiste
  // und die Screenreader-Aktion eines Buttons kommen jetzt aus der Tabelle
  Host.Log('Darstellung', Format('Sprache: %s {-} Beispiel: "%s"',
    [FLang.Items[Max(0, FLang.ItemIndex)], PPGStr(@SPPGAccPress)]));
end;

procedure TDemoAppearancePage.FailClick(Sender: TObject);
begin
  Host.Log('Robustheit', 'Exception wird ausgel{oe}st');
  raise Exception.Create(L('Absichtlicher Fehler im OnClick-Handler {-} der Button bleibt ' +
    'bedienbar.'));
end;

{ TDemoEventsPage }

procedure TDemoEventsPage.Build;
var
  Card: TPPGPanel;
  TB: TPPGToolBar;
begin
  NewPageHeader(Own, Sheet, 'Ereignisse', 'Jede Aktion in der Demo landet hier {-} der Beweis, ' +
    'dass die Ereignisse der Controls ankommen. Neueste zuerst.');
  Card := NewCard(Own, Sheet, PageX, PageContentTop, FullW, 620, '', '');
  TB := TPPGToolBar.Create(Own);
  TB.Parent := Card;
  TB.Align := alNone;
  TB.SetBounds(CardPad - 6, 12, 400, 40);
  TB.Items.AddButton('Leeren', $E74D);
  TB.Items.AddButton('Kopieren', $E8C8);
  TB.OnItemClick := ToolClick;
  FList := TPPGListBox.Create(Own);
  FList.Parent := Card;
  FList.SetBounds(CardPad, 58, FullW - 2 * CardPad, 620 - 58 - 48);
  FList.AllowMarkup := True;
  FResult := NewResult(Own, Card, 'Ereignisse');
  SetResult(FResult, '0');
end;

procedure TDemoEventsPage.AddEvent(const Category, Text: string);
var
  It: TPPGItem;
begin
  if FList = nil then
    Exit;
  It := FList.ItemsEx.Insert(0);
  It.Text := '<b>' + MarkupEscape(Category) + '</b>  ' + MarkupEscape(Text);
  It.Detail := FormatDateTime('hh:nn:ss', Now);
  Inc(FCount);
  SetResult(FResult, IntToStr(FCount));
end;

procedure TDemoEventsPage.ToolClick(Sender: TObject; Item: TPPGToolItem);
var
  SL: TStringList;
  I: Integer;
begin
  if Item.IconChar = $E74D then
  begin
    FList.ItemsEx.Clear;
    FCount := 0;
    SetResult(FResult, '0');
  end
  else
  begin
    SL := TStringList.Create;
    try
      for I := 0 to FList.ItemsEx.Count - 1 do
        SL.Add(FList.ItemsEx[I].Detail + #9 + StringReplace(StringReplace(
          FList.ItemsEx[I].Text, '<b>', '', []), '</b>', '', []));
      Clipboard.AsText := SL.Text;
    finally
      SL.Free;
    end;
    Host.Notifier.Show('Kopiert', L(Format('%d Ereignisse in der Zwischenablage.',
      [FList.ItemsEx.Count])), psSuccess);
  end;
end;

{ Selbsttests }

type
  TTabAccess = class(TPPGTabControl); // CloseTab ist protected (Weg des Schliessen-Knopfs)

procedure TDemoLayoutPage.SelfTest(Check: TDemoCheck);
var
  N: Integer;
begin
  N := FTabs.Tabs.Count;
  DemoClick(FNewTabBtn);
  Check('Layout: neuer Reiter wird aktiv', (FTabs.Tabs.Count = N + 1) and
    (FTabs.TabIndex = N) and (Pos(FTabs.Tabs[N], FTabContent.Caption) > 0));
  TTabAccess(FTabs).CloseTab(N);
  Check('Layout: Reiter schliessen', FTabs.Tabs.Count = N);
end;

procedure TDemoFeedbackPage.SelfTest(Check: TDemoCheck);
var
  I: Integer;
begin
  FBars[1].IsOpen := False;
  UpdateBarResult;
  Check('Rueckmeldung: InfoBar schliessen', Pos('3 von 4', FBarResult.Caption) > 0);
  ReopenClick(nil);
  Check('Rueckmeldung: alle wieder offen', Pos('4 von 4', FBarResult.Caption) > 0);
  DemoClick(FStart);
  Check('Rueckmeldung: Download startet', FTimer.Enabled and not FStart.Enabled and FPause.Enabled);
  DemoClick(FPause);
  Check('Rueckmeldung: Pause', not FTimer.Enabled and (FDownload.State = pbsPaused));
  DemoClick(FPause);
  for I := 1 to 120 do
    if FTimer.Enabled then
      TimerTick(FTimer);
  Check('Rueckmeldung: Download fertig', (FDownload.Position = 100) and FStart.Enabled and
    not FTimer.Enabled);
  DemoClick(FPlus50);
  DemoClick(FPlus50);
  Check('Rueckmeldung: Plakette zeigt 99+', FBadge.DisplayText = '99+');
end;

procedure TDemoAppearancePage.SelfTest(Check: TDemoCheck);
var
  Old: string;
begin
  Old := Host.CurrentPreset;
  DemoClick(FPresetRadios[0]);
  Check('Darstellung: Preset Classic', Host.CurrentPreset = PPGPresetClassic);
  DemoClick(FModeRadios[1]);
  Check('Darstellung: Dunkel', TPPGTheme.IsDark);
  DemoClick(FModeRadios[0]);
  Check('Darstellung: Hell', not TPPGTheme.IsDark);
  FLang.ItemIndex := 1;
  LangChange(FLang);
  Check('Darstellung: Sprache Deutsch', (PPGLanguage = 'de') and
    (PPGStr(@SPPGAccPress) <> LoadResString(@SPPGAccPress)));
  FLang.ItemIndex := 0;
  LangChange(FLang);
  Check('Darstellung: Sprache Original', PPGLanguage = '');
  Host.ApplyPreset(Old);
  Check('Darstellung: Preset zurueck', FPresetRadios[2].Checked = SameText(Old, PPGPresetFluent11));
end;

procedure TDemoEventsPage.SelfTest(Check: TDemoCheck);
begin
  Check('Ereignisse: Protokoll gefuellt', FList.ItemsEx.Count > 10);
end;

end.
