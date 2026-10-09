unit DemoPages6;

{ Demo-Seite "Menues & Dialoge" (Phase 11): Menueleiste, Kontextmenue,
  Hints im Suite-Stil, TeachingTip (kleine Tour), Meldungen, TaskDialog,
  Fortschritt, Eingabe mit Pruefung und Assistent. }

interface

uses
  System.SysUtils, System.Classes, System.Types, System.UITypes, Vcl.Controls, Vcl.Menus,
  Vcl.Dialogs,
  PPG.Types, PPG.Panel, PPG.Labels, PPG.Button, PPG.CheckBox, PPG.Edit,
  PPG.Menus, PPG.MenuBar, PPG.Hints, PPG.TeachingTip, PPG.Dialogs, PPG.Wizard,
  DemoKit;

type
  TDemoMenusPage = class(TDemoPage)
  private
    FMainMenu: TMainMenu;
    FBar: TPPGMenuBar;
    FPopup: TPPGPopupMenu;
    FArea: TPPGPanel;
    FMenuResult: TPPGLabel;
    FHintBox: TPPGCheckBox;
    FTipButton: TPPGButton;
    FTipTarget: array[0..1] of TPPGButton;
    FTip: TPPGTeachingTip;
    FTipStep: Integer;
    FLightDismiss: TPPGCheckBox;
    FTipResult: TPPGLabel;
    FDialogResult: TPPGLabel;
    FWizard: TPPGWizard;
    FName: TPPGEdit;
    FAdvanced: TPPGCheckBox;
    FSummary: TPPGLabel;
    FWizardResult: TPPGLabel;
    FAutoClose: TModalResult;
    function Item(AOwner: TMenuItem; const ACaption: string; AShortCut: TShortCut = 0): TMenuItem;
    procedure BuildMenus(Card: TPPGPanel);
    procedure BuildHints(Card: TPPGPanel);
    procedure BuildDialogs(Card: TPPGPanel);
    procedure BuildWizard(Card: TPPGPanel);
    procedure MenuClick(Sender: TObject);
    procedure HintBoxClick(Sender: TObject);
    procedure TipClick(Sender: TObject);
    procedure ShowTipStep;
    procedure TipAction(Sender: TObject);
    procedure TipClose(Sender: TObject; Reason: TPPGTipCloseReason);
    procedure InfoClick(Sender: TObject);
    procedure WarningClick(Sender: TObject);
    procedure QuestionClick(Sender: TObject);
    procedure TaskClick(Sender: TObject);
    procedure ProgressClick(Sender: TObject);
    procedure ProgressTimer(Sender: TObject; TickCount: Cardinal; var Reset: Boolean);
    procedure InputClick(Sender: TObject);
    procedure WizardCanAdvance(Sender: TObject; Page: TPPGWizardPage; var Allow: Boolean);
    procedure WizardChanged(Sender: TObject);
    procedure WizardFinish(Sender: TObject);
    procedure WizardCancel(Sender: TObject);
    procedure AdvancedClick(Sender: TObject);
    procedure AutoCloseDialog(Form: TPPGDialogForm);
  protected
    procedure Build; override;
  public
    procedure AppearanceChanged; override;
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  PPG.Controls.Base;

const
  FullW = 2 * 484 + CardGap;
  HalfW = 484;
  Row1H = 300;
  DialogH = 150;
  WizardH = 380;

function ModalText(R: Integer): string;
begin
  case R of
    mrOk: Result := 'OK';
    mrCancel: Result := 'Abbrechen';
    mrYes: Result := 'Ja';
    mrNo: Result := 'Nein';
    mrRetry: Result := 'Wiederholen';
    mrIgnore: Result := 'Ignorieren';
  else
    Result := IntToStr(R);
  end;
end;

procedure TDemoMenusPage.Build;
var
  Y: Integer;
begin
  NewPageHeader(Own, Sheet, L('Men{ue}s & Dialoge'), L('Men{ue}leiste und Kontextmen{ue} im ') +
    L('Stil des Presets, Hints mit Titel, TeachingTip, Meldungen und TaskDialog als echte ') +
    L('Formulare sowie ein Schritt-Assistent. Alles folgt Dark Mode und Hochkontrast.'));
  Y := PageContentTop;
  BuildMenus(NewCard(Own, Sheet, PageX, Y, HalfW, Row1H, L('Men{ue}leiste & Kontextmen{ue}'),
    L('TPPGMenuBar zeigt ein TMainMenu, TPPGPopupMenu ist ein TPopupMenu mit eigener ') +
    L('Darstellung. Alt oder F10 aktiviert die Leiste.')));
  BuildHints(NewCard(Own, Sheet, PageX + HalfW + CardGap, Y, HalfW, Row1H, 'Hints & TeachingTip',
    L('TPPGHintManager stellt alle Hints der Anwendung um ("Titel|Text"). Der TeachingTip ') +
    L('h{ae}ngt als Sprechblase an einem Control.')));
  Inc(Y, Row1H + CardGap);
  BuildDialogs(NewCard(Own, Sheet, PageX, Y, FullW, DialogH, 'Dialoge',
    L('PPGMessageDlg und PPGInputQuery haben die Signatur der VCL-Funktionen; TPPGTaskDialog ') +
    L('hat die Properties von TTaskDialog. Strg+C kopiert den Text.')));
  Inc(Y, DialogH + CardGap);
  BuildWizard(NewCard(Own, Sheet, PageX, Y, FullW, WizardH, 'Assistent',
    L('TPPGWizard mit Seiten wie ein PageControl, Pr{ue}fung je Schritt (OnCanAdvance) und ') +
    L('{ue}bersprungenen Seiten (PageVisible).')));
end;

function TDemoMenusPage.Item(AOwner: TMenuItem; const ACaption: string;
  AShortCut: TShortCut): TMenuItem;
begin
  Result := TMenuItem.Create(Own);
  Result.Caption := L(ACaption);
  Result.ShortCut := AShortCut;
  if ACaption <> '-' then
    Result.OnClick := MenuClick;
  AOwner.Add(Result);
end;

procedure TDemoMenusPage.BuildMenus(Card: TPPGPanel);
var
  M, Sub, It: TMenuItem;
  Lbl: TPPGLabel;
begin
  FMainMenu := TMainMenu.Create(Own);
  M := Item(FMainMenu.Items, '&Datei');
  M.OnClick := nil;
  Item(M, '&Neu', ShortCut(Ord('N'), [ssCtrl]));
  Item(M, '{Oe}&ffnen{...}', ShortCut(Ord('O'), [ssCtrl]));
  Sub := Item(M, '&Zuletzt verwendet');
  Sub.OnClick := nil;
  Item(Sub, 'Bericht.docx');
  Item(Sub, 'Notizen.txt');
  Item(M, '-');
  It := Item(M, '&Drucken{...}', ShortCut(Ord('P'), [ssCtrl]));
  It.Enabled := False;
  M := Item(FMainMenu.Items, '&Bearbeiten');
  M.OnClick := nil;
  Item(M, '&R{ue}ckg{ae}ngig', ShortCut(Ord('Z'), [ssCtrl]));
  Item(M, '-');
  Item(M, '&Ausschneiden', ShortCut(Ord('X'), [ssCtrl]));
  Item(M, '&Kopieren', ShortCut(Ord('C'), [ssCtrl]));
  Item(M, '&Einf{ue}gen', ShortCut(Ord('V'), [ssCtrl]));
  M := Item(FMainMenu.Items, '&Ansicht');
  M.OnClick := nil;
  It := Item(M, '&Statusleiste');
  It.AutoCheck := True;
  It.Checked := True;
  Item(M, '-');
  It := Item(M, '&Klein');
  It.RadioItem := True;
  It.GroupIndex := 1;
  It.AutoCheck := True;
  It := Item(M, '&Mittel');
  It.RadioItem := True;
  It.GroupIndex := 1;
  It.AutoCheck := True;
  It.Checked := True;
  It := Item(M, '&Gro{ss}');
  It.RadioItem := True;
  It.GroupIndex := 1;
  It.AutoCheck := True;

  FBar := TPPGMenuBar.Create(Own);
  FBar.Parent := Card;
  FBar.Align := alNone;
  FBar.Preset := DemoPreset;
  FBar.Menu := FMainMenu;
  FBar.SetBounds(CardPad, Card.Tag, HalfW - 2 * CardPad, CtlH);
  Host.RegisterSpecial('menubar', FBar);

  FPopup := TPPGPopupMenu.Create(Own);
  FPopup.Preset := DemoPreset;
  Item(FPopup.Items, '&Kopieren', ShortCut(Ord('C'), [ssCtrl]));
  Item(FPopup.Items, '&Einf{ue}gen', ShortCut(Ord('V'), [ssCtrl]));
  Item(FPopup.Items, '-');
  It := Item(FPopup.Items, '&Hervorheben');
  It.AutoCheck := True;
  Sub := Item(FPopup.Items, '&Farbe');
  Sub.OnClick := nil;
  It := Item(Sub, '&Rot');
  It.RadioItem := True;
  It.AutoCheck := True;
  It.Checked := True;
  It := Item(Sub, '&Gr{ue}n');
  It.RadioItem := True;
  It.AutoCheck := True;
  It := Item(Sub, '&Blau');
  It.RadioItem := True;
  It.AutoCheck := True;
  Item(FPopup.Items, '-');
  Item(FPopup.Items, '&Eigenschaften{...}', ShortCut(13, [ssAlt]));

  FArea := TPPGPanel.Create(Own);
  FArea.Parent := Card;
  FArea.Preset := DemoPreset;
  FArea.ShowCaption := False;
  FArea.Caption := '';
  FArea.SetBounds(CardPad, Card.Tag + CtlH + 16, HalfW - 2 * CardPad, 96);
  FArea.PopupMenu := FPopup;
  Lbl := NewLabel(Own, FArea, 16, 36, HalfW - 2 * CardPad - 32,
    L('Rechtsklick (oder Umschalt+F10) hier f{ue}r das Kontextmen{ue}'), tkSecondary);
  Lbl.PopupMenu := FPopup;
  Host.RegisterSpecial('popup', FArea);
  FMenuResult := NewResult(Own, Card, 'Zuletzt gew{ae}hlt');
end;

procedure TDemoMenusPage.MenuClick(Sender: TObject);
begin
  SetResult(FMenuResult, MarkupEscape(StripHotkey(TMenuItem(Sender).Caption)));
  Host.Log('Men{ue}', StripHotkey(TMenuItem(Sender).Caption));
end;

procedure TDemoMenusPage.BuildHints(Card: TPPGPanel);
var
  B: TPPGButton;
  X: Integer;
begin
  X := CardPad;
  B := NewButton(Own, Card, X, Card.Tag, 128, 'Speichern', nil);
  B.Hint := L('Speichern (Strg+S)|Speichert das Dokument unter seinem bisherigen Namen.');
  B.ShowHint := True;
  B := NewButton(Own, Card, X + 136, Card.Tag, 128, 'Teilen', nil);
  B.Hint := L('Teilen|Schickt einen Link per E-Mail oder kopiert ihn in die Zwischenablage.');
  B.ShowHint := True;
  FTipTarget[0] := B;
  B := NewButton(Own, Card, X + 272, Card.Tag, 128, 'Verlauf', nil);
  B.Hint := L('Verlauf|Zeigt fr{ue}here Versionen.');
  B.ShowHint := True;
  FTipTarget[1] := B;
  FHintBox := TPPGCheckBox.Create(Own);
  FHintBox.Parent := Card;
  FHintBox.Preset := DemoPreset;
  FHintBox.SetBounds(X, Card.Tag + CtlH + 12, HalfW - 2 * CardPad, 24);
  FHintBox.Caption := 'Hints im Suite-Stil (TPPGHintManager.Active)';
  FHintBox.Checked := (DemoHints <> nil) and DemoHints.Active;
  FHintBox.OnClick := HintBoxClick;

  FTipButton := NewButton(Own, Card, X, Card.Tag + CtlH + 52, 180, 'Tour starten', TipClick, True);
  FLightDismiss := TPPGCheckBox.Create(Own);
  FLightDismiss.Parent := Card;
  FLightDismiss.Preset := DemoPreset;
  FLightDismiss.SetBounds(X + 196, Card.Tag + CtlH + 56, 240, 24);
  FLightDismiss.Caption := 'Light-Dismiss';
  FLightDismiss.Hint := L('Light-Dismiss|Ein Klick neben den Tipp schlie{ss}t ihn.');
  FLightDismiss.ShowHint := True;

  FTip := TPPGTeachingTip.Create(Own);
  FTip.Preset := DemoPreset;
  FTip.Icon := tiInfo;
  FTip.OnActionClick := TipAction;
  FTip.OnClose := TipClose;
  FTipResult := NewResult(Own, Card, 'TeachingTip');
end;

procedure TDemoMenusPage.HintBoxClick(Sender: TObject);
begin
  if DemoHints <> nil then
    DemoHints.Active := FHintBox.Checked;
end;

procedure TDemoMenusPage.TipClick(Sender: TObject);
begin
  FTipStep := 0;
  FTip.LightDismiss := FLightDismiss.Checked;
  ShowTipStep;
end;

procedure TDemoMenusPage.ShowTipStep;
begin
  if FTipStep = 0 then
  begin
    FTip.Title := 'Neu: Teilen';
    FTip.Subtitle := 'Schritt 1 von 2';
    FTip.Text := L('Mit <b>Teilen</b> schicken Sie einen Link an Kollegen. ') +
      L('Der Tipp folgt dem Button, wenn sich das Fenster bewegt.');
    FTip.ActionButtonText := '&Weiter';
    FTip.CloseButtonText := L('&Sp{ae}ter');
  end
  else
  begin
    FTip.Title := 'Verlauf';
    FTip.Subtitle := 'Schritt 2 von 2';
    FTip.Text := L('Hier finden Sie fr{ue}here Versionen. Esc schlie{ss}t den Tipp.');
    FTip.ActionButtonText := '&Fertig';
    FTip.CloseButtonText := '';
  end;
  FTip.ShowFor(FTipTarget[FTipStep]);
  SetResult(FTipResult, Format('Schritt %d', [FTipStep + 1]));
end;

procedure TDemoMenusPage.TipAction(Sender: TObject);
begin
  if FTipStep = 0 then
  begin
    FTipStep := 1;
    ShowTipStep;
  end
  else
  begin
    FTip.Hide;
    SetResult(FTipResult, 'Tour abgeschlossen');
  end;
end;

procedure TDemoMenusPage.TipClose(Sender: TObject; Reason: TPPGTipCloseReason);
const
  Names: array[TPPGTipCloseReason] of string = ('Schlie{ss}en-Knopf', 'Klick daneben',
    'Esc', 'Code');
begin
  SetResult(FTipResult, 'geschlossen ({-} ' + Names[Reason] + ')');
end;

procedure TDemoMenusPage.BuildDialogs(Card: TPPGPanel);
const
  W = 140;
var
  X: Integer;
begin
  X := CardPad;
  NewButton(Own, Card, X, Card.Tag, W, 'Information', InfoClick);
  NewButton(Own, Card, X + (W + 8), Card.Tag, W, 'Warnung', WarningClick);
  NewButton(Own, Card, X + 2 * (W + 8), Card.Tag, W, 'Frage', QuestionClick);
  NewButton(Own, Card, X + 3 * (W + 8), Card.Tag, W, 'TaskDialog', TaskClick, True);
  NewButton(Own, Card, X + 4 * (W + 8), Card.Tag, W, 'Fortschritt', ProgressClick);
  NewButton(Own, Card, X + 5 * (W + 8), Card.Tag, W, 'Eingabe', InputClick);
  FDialogResult := NewResult(Own, Card, 'Ergebnis');
end;

procedure TDemoMenusPage.InfoClick(Sender: TObject);
begin
  PPGShowMessage(L('Die Datei wurde gespeichert.'));
  SetResult(FDialogResult, 'OK');
end;

procedure TDemoMenusPage.WarningClick(Sender: TObject);
begin
  SetResult(FDialogResult, ModalText(PPGMessageDlg(L('Die Verbindung zum Server ist ') +
    L('unterbrochen. Erneut versuchen?'), TMsgDlgType.mtWarning, mbAbortRetryIgnore, 0)));
end;

procedure TDemoMenusPage.QuestionClick(Sender: TObject);
begin
  SetResult(FDialogResult, ModalText(PPGMessageDlg(L('M{oe}chten Sie die {Ae}nderungen ') +
    'speichern?', TMsgDlgType.mtConfirmation, mbYesNoCancel, 0)));
end;

procedure TDemoMenusPage.TaskClick(Sender: TObject);
var
  D: TPPGTaskDialog;
  B: TTaskDialogButtonItem;
  S: string;
begin
  D := TPPGTaskDialog.Create(nil);
  try
    D.Preset := DemoPreset;
    D.Caption := 'PPGlow';
    D.Title := L('{Ae}nderungen an "Bericht.docx" speichern?');
    D.Text := L('Wenn Sie nicht speichern, gehen Ihre {Ae}nderungen verloren.');
    D.MainIcon := tdiWarning;
    D.CommonButtons := [tcbCancel];
    D.Flags := [tfAllowDialogCancellation, tfUseCommandLinks, tfEnableHyperlinks];
    B := TTaskDialogButtonItem(D.Buttons.Add);
    B.Caption := '&Speichern';
    B.CommandLinkHint := L('Speichert die Datei an ihrem bisherigen Ort.');
    B.ModalResult := 101;
    B.Default := True;
    B := TTaskDialogButtonItem(D.Buttons.Add);
    B.Caption := '&Nicht speichern';
    B.CommandLinkHint := L('Verwirft alle {Ae}nderungen seit dem letzten Speichern.');
    B.ModalResult := 102;
    D.VerificationText := L('F{ue}r alle ge{oe}ffneten Dokumente');
    D.ExpandedText := 'Pfad: C:\Users\Public\Documents\Bericht.docx';
    D.FooterText := L('Mehr zu <a href="autosave">AutoSpeichern</a>');
    D.FooterIcon := tdiInformation;
    D.Execute;
    case D.ModalResult of
      101: S := 'Speichern';
      102: S := 'Nicht speichern';
    else
      S := 'Abbrechen';
    end;
    if tfVerificationFlagChecked in D.Flags then
      S := S + L(' (f{ue}r alle)');
    SetResult(FDialogResult, S);
  finally
    D.Free;
  end;
end;

procedure TDemoMenusPage.ProgressClick(Sender: TObject);
var
  D: TPPGTaskDialog;
begin
  D := TPPGTaskDialog.Create(nil);
  try
    D.Preset := DemoPreset;
    D.Caption := 'PPGlow';
    D.Title := 'Dateien werden kopiert';
    D.Text := '0 von 20 Dateien';
    D.MainIcon := tdiNone;
    D.CommonButtons := [tcbCancel];
    D.Flags := [tfAllowDialogCancellation, tfShowProgressBar, tfCallbackTimer];
    D.ProgressBar.Max := 20;
    D.OnTimer := ProgressTimer;
    D.Execute;
    if D.ModalResult = mrOk then
      SetResult(FDialogResult, 'Kopieren fertig')
    else
      SetResult(FDialogResult, Format('abgebrochen bei %d von 20', [D.ProgressBar.Position]));
  finally
    D.Free;
  end;
end;

procedure TDemoMenusPage.ProgressTimer(Sender: TObject; TickCount: Cardinal; var Reset: Boolean);
var
  D: TPPGTaskDialog;
begin
  D := TPPGTaskDialog(Sender);
  D.ProgressBar.Position := D.ProgressBar.Position + 1;
  D.Text := Format('%d von 20 Dateien', [D.ProgressBar.Position]);
  if (D.ProgressBar.Position >= 20) and (D.DialogForm <> nil) then
    D.DialogForm.ClickButton(mrOk);
end;

procedure TDemoMenusPage.InputClick(Sender: TObject);
var
  V: array[0..1] of string;
begin
  V[0] := '';
  V[1] := '';
  if PPGInputQuery('Anmelden', ['Benutzername', #31 + 'Kennwort'], V,
    function(const Values: TArray<string>; var ErrorText: string; var FieldIndex: Integer): Boolean
    begin
      Result := False;
      if Trim(Values[0]) = '' then
      begin
        ErrorText := 'Bitte einen Benutzernamen eingeben.';
        FieldIndex := 0;
      end
      else if Length(Values[1]) < 4 then
      begin
        ErrorText := L('Das Kennwort braucht mindestens 4 Zeichen.');
        FieldIndex := 1;
      end
      else
        Result := True;
    end) then
    SetResult(FDialogResult, 'angemeldet als ' + MarkupEscape(V[0]))
  else
    SetResult(FDialogResult, 'Anmeldung abgebrochen');
end;

procedure TDemoMenusPage.BuildWizard(Card: TPPGPanel);
var
  P: TPPGWizardPage;
  CB: TPPGCheckBox;

  function NewPage(const ACaption, ADescription: string): TPPGWizardPage;
  begin
    Result := TPPGWizardPage.Create(Own);
    Result.Caption := L(ACaption);
    Result.Description := L(ADescription);
    Result.Wizard := FWizard;
  end;

begin
  FWizard := TPPGWizard.Create(Own);
  FWizard.Parent := Card;
  FWizard.Preset := DemoPreset;
  FWizard.SetBounds(CardPad, Card.Tag, FullW - 2 * CardPad, WizardH - Card.Tag - 44);
  FWizard.OnCanAdvance := WizardCanAdvance;
  FWizard.OnChange := WizardChanged;
  FWizard.OnFinish := WizardFinish;
  FWizard.OnCancel := WizardCancel;

  P := NewPage('Konto', 'Name des neuen Kontos');
  NewLabel(Own, P, 24, 16, 400, L('Wie soll das Konto hei{ss}en?'), tkBody);
  FName := TPPGEdit.Create(Own);
  FName.Parent := P;
  FName.Preset := DemoPreset;
  FName.SetBounds(24, 44, 320, CtlH);
  FName.TextHint := 'z. B. Vertrieb';

  P := NewPage('Optionen', 'Einstellungen des Kontos');
  CB := TPPGCheckBox.Create(Own);
  CB.Parent := P;
  CB.Preset := DemoPreset;
  CB.SetBounds(24, 16, 400, 24);
  CB.Caption := 'Benachrichtigungen per E-Mail';
  CB.Checked := True;
  FAdvanced := TPPGCheckBox.Create(Own);
  FAdvanced.Parent := P;
  FAdvanced.Preset := DemoPreset;
  FAdvanced.SetBounds(24, 48, 400, 24);
  FAdvanced.Caption := L('Erweiterte Einstellungen anzeigen (blendet Schritt 3 ein)');
  FAdvanced.OnClick := AdvancedClick;

  P := NewPage('Erweitert', 'Nur mit erweiterten Einstellungen');
  P.PageVisible := False;
  NewLabel(Own, P, 24, 16, 600, L('Dieser Schritt erscheint nur, wenn er gebraucht wird ') +
    '(PageVisible).', tkBody);

  P := NewPage('Fertig', 'Zusammenfassung');
  FSummary := NewLabel(Own, P, 24, 16, 600, '', tkBody);
  FSummary.AllowMarkup := True;

  FWizard.ActivePage := FWizard.Pages[0];
  Host.RegisterSpecial('wizard', FWizard);
  FWizardResult := NewResult(Own, Card, 'Assistent');
end;

procedure TDemoMenusPage.AdvancedClick(Sender: TObject);
begin
  FWizard.Pages[2].PageVisible := FAdvanced.Checked;
end;

procedure TDemoMenusPage.WizardCanAdvance(Sender: TObject; Page: TPPGWizardPage;
  var Allow: Boolean);
begin
  if (Page = FWizard.Pages[0]) and (Trim(FName.Text) = '') then
  begin
    Allow := False;
    SetResult(FWizardResult, 'Bitte zuerst einen Namen eingeben');
    if FName.CanFocus then
      FName.SetFocus;
  end;
end;

procedure TDemoMenusPage.WizardChanged(Sender: TObject);
begin
  SetResult(FWizardResult, Format('Schritt %d von %d', [FWizard.StepIndex + 1, FWizard.StepCount]));
  if FWizard.ActivePage = FWizard.Pages[3] then
    FSummary.Caption := 'Konto <b>' + MarkupEscape(FName.Text) + '</b> wird angelegt.' +
      L(' Erweitert: ') + BoolToStr(FAdvanced.Checked, True);
end;

procedure TDemoMenusPage.WizardFinish(Sender: TObject);
begin
  SetResult(FWizardResult, 'Konto "' + MarkupEscape(FName.Text) + '" angelegt');
  FWizard.ActivePage := FWizard.Pages[0];
  FName.Text := '';
end;

procedure TDemoMenusPage.WizardCancel(Sender: TObject);
begin
  SetResult(FWizardResult, 'abgebrochen');
  FWizard.ActivePage := FWizard.Pages[0];
end;

procedure TDemoMenusPage.AppearanceChanged;
begin
  inherited AppearanceChanged;
  // Nicht sichtbare Komponenten folgen dem Preset nicht von selbst
  if FPopup <> nil then
    FPopup.Preset := DemoPreset;
  if FTip <> nil then
  begin
    FTip.Preset := DemoPreset;
    if FTip.IsOpen then
      FTip.UpdatePosition;
  end;
end;

procedure TDemoMenusPage.AutoCloseDialog(Form: TPPGDialogForm);
begin
  Form.ClickButton(FAutoClose);
end;

procedure TDemoMenusPage.SelfTest(Check: TDemoCheck);
var
  Old: TPPGDialogShowEvent;
  R: Integer;
begin
  Check(L('Men{ue}s: Leiste hat drei Men{ue}s'), FBar.Menu.Items.Count = 3);
  Check(L('Men{ue}s: Kontextmen{ue} am Bereich'), FArea.PopupMenu = FPopup);
  Check('Hints: Manager aktiv', PPGActiveHintManager <> nil);
  // TeachingTip: Tour
  FTipButton.Click;
  Check('TeachingTip: offen am Ziel', FTip.IsOpen and (FTip.Target = FTipTarget[0]));
  FTip.Hide;
  Check('TeachingTip: geschlossen', not FTip.IsOpen);
  // Assistent: Pruefung und uebersprungene Seite
  FName.Text := '';
  Check('Assistent: ohne Namen kein Weiter', not FWizard.Next);
  FName.Text := 'Test';
  Check('Assistent: Weiter', FWizard.Next and (FWizard.ActivePage = FWizard.Pages[1]));
  FWizard.Next;
  Check(L('Assistent: Schritt 3 {ue}bersprungen'), FWizard.ActivePage = FWizard.Pages[3]);
  FWizard.ActivePage := FWizard.Pages[0];
  FName.Text := '';
  // Dialog: automatisch beantwortet
  Old := PPGOnDialogShow;
  PPGOnDialogShow := AutoCloseDialog;
  try
    FAutoClose := mrNo;
    R := PPGMessageDlg('Selbsttest', TMsgDlgType.mtConfirmation, mbYesNoCancel, 0);
    Check('Dialog: Ergebnis Nein', R = mrNo);
  finally
    PPGOnDialogShow := Old;
  end;
end;

end.
