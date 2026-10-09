unit PPG.Tests.Phase11c;

{ Tests fuer Phase 11g: TPPGTaskDialog, PPGMessageDlg, PPGInputQuery.
  Die modalen Dialoge werden ueber PPGOnDialogShow gesteuert. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.Dialogs,
  Vcl.ExtCtrls,
  PPG.Types, PPG.Render.Registry, PPG.Controls.Base, PPG.Button, PPG.Edit, PPG.Dialogs,
  PPG.Exceptions, PPG.Wizard, PPG.Tests.Controls;

type
  TDialogTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FAction: Integer;
    FClick: TModalResult;
    FInfo: string;
    FTicks: Integer;
    FRefuse: Integer;
    FSheet: TBitmap;
    FSheetY: Integer;
    procedure OnShowClick(Form: TPPGDialogForm);
    procedure OnShowCancel(Form: TPPGDialogForm);
    procedure OnShowTask(Form: TPPGDialogForm);
    procedure OnShowInput(Form: TPPGDialogForm);
    procedure OnShowCapture(Form: TPPGDialogForm);
    procedure TaskButtonClicked(Sender: TObject; ModalResult: TModalResult; var CanClose: Boolean);
    procedure TaskRadio(Sender: TObject);
    procedure TaskVerify(Sender: TObject);
    procedure TaskExpanded(Sender: TObject);
    procedure TaskTimer(Sender: TObject; TickCount: Cardinal; var Reset: Boolean);
    procedure TaskCreated(Sender: TObject);
    procedure TaskDestroyed(Sender: TObject);
    function NewTask: TPPGTaskDialog;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure MessageDlgAllButtonsAndResults;
    procedure MessageDlgDefaultAndEscapeLikeVcl;
    procedure HelpButtonDoesNotClose;
    procedure TaskDialogEventsAndResults;
    procedure EscapeOnlyWhenCancellable;
    procedure CopyTextInWindowsFormat;
    procedure ExpandAndTimerAndProgress;
    procedure CommandLinks;
    procedure ContentControlIsReturned;
    procedure LoadsTTaskDialogDfm;
    procedure InputQueryValidates;
    procedure CallFromThreadRaises;
    procedure DialogGallery;
  end;

  TWizardTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FBlock: Boolean;
    function NewWizard: TPPGWizard;
    procedure CanAdvance(Sender: TObject; Page: TPPGWizardPage; var Allow: Boolean);
    procedure Changed(Sender: TObject);
    procedure Finished(Sender: TObject);
    procedure Cancelled(Sender: TObject);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure StepsSkipInvisiblePages;
    procedure CanAdvanceBlocks;
    procedure CodeSetFiresNoEvents;
    procedure ButtonsAndCaptions;
    procedure ClickOnDoneStepGoesBack;
    procedure StreamingRoundTrip;
    procedure WizardGallery;
    procedure BackWithoutActivePageStays;
  end;

implementation

uses
  System.StrUtils, Vcl.Menus, Vcl.Imaging.pngimage, PPG.Theme, PPG.Labels, PPG.RadioButton,
  PPG.CheckBox, PPG.Lang, PPG.Consts;

{ TDialogTests }

procedure TDialogTests.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FAction := 0;
  FClick := mrNone;
  FInfo := '';
  FTicks := 0;
  FRefuse := 0;
  FForm.Show;
end;

procedure TDialogTests.TearDown;
begin
  PPGOnDialogShow := nil;
  TPPGTheme.Mode := tmLight;
  FreeAndNil(FLog);
  inherited TearDown;
end;

function TDialogTests.NewTask: TPPGTaskDialog;
begin
  Result := TPPGTaskDialog.Create(FForm);
  Result.Caption := 'Testdialog';
  Result.Title := 'Datei speichern?';
  Result.Text := 'Die Datei wurde geaendert.';
end;

procedure TDialogTests.OnShowClick(Form: TPPGDialogForm);
var
  I: Integer;
begin
  FInfo := '';
  for I := 0 to Form.ButtonCount - 1 do
    if Form.ButtonAt(I) is TPPGButton then
      FInfo := FInfo + StripHotkey(TPPGButton(Form.ButtonAt(I)).Caption) + ';';
  Form.ClickButton(FClick);
end;

procedure TDialogTests.OnShowCancel(Form: TPPGDialogForm);
begin
  FInfo := System.SysUtils.BoolToStr(Form.CanCancel, True);
  if Form.ButtonByResult(mrYes) is TPPGButton then
    FInfo := FInfo + ',yesdefault=' + System.SysUtils.BoolToStr(TPPGButton(Form.ButtonByResult(mrYes)).Default, True);
  Form.Cancel;
  if FClick <> mrNone then
    Form.ClickButton(FClick); // falls Esc nicht schliessen durfte
end;

procedure TDialogTests.MessageDlgAllButtonsAndResults;
const
  Expected: array[TMsgDlgBtn] of TModalResult = (mrYes, mrNo, mrOk, mrCancel, mrAbort,
    mrRetry, mrIgnore, mrAll, mrNoToAll, mrYesToAll, mrHelp, mrClose);
var
  B: TMsgDlgBtn;
  R: Integer;
begin
  PPGOnDialogShow := OnShowClick;
  for B := Low(TMsgDlgBtn) to High(TMsgDlgBtn) do
  begin
    if B = TMsgDlgBtn.mbHelp then
      Continue; // schliesst nicht, eigener Test
    FClick := Expected[B];
    R := PPGMessageDlg('Frage', TMsgDlgType.mtConfirmation, [B, TMsgDlgBtn.mbHelp], 0);
    CheckEquals(Expected[B], R, 'Ergebnis ' + IntToStr(Ord(B)));
    CheckEquals(2, Length(PPGSplitString(FInfo, ';', True)), 'zwei Buttons: ' + FInfo);
  end;
  // Reihenfolge wie die VCL
  FClick := mrNo;
  PPGMessageDlg('Frage', TMsgDlgType.mtWarning, [TMsgDlgBtn.mbNo, TMsgDlgBtn.mbCancel,
    TMsgDlgBtn.mbYes], 0);
  CheckEquals(StripHotkey(PPGStr(@SPPGDlgYes)) + ';' + StripHotkey(PPGStr(@SPPGDlgNo)) + ';' +
    PPGStr(@SPPGDlgCancel) + ';', FInfo);
end;

procedure TDialogTests.MessageDlgDefaultAndEscapeLikeVcl;
var
  R: Integer;
begin
  PPGOnDialogShow := OnShowCancel;
  // Ja/Nein: Ja ist Standard, Esc = Nein
  R := PPGMessageDlg('?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0);
  CheckEquals(mrNo, R);
  CheckEquals('True,yesdefault=True', FInfo);
  // Mit Abbrechen: Esc = Abbrechen
  R := PPGMessageDlg('?', TMsgDlgType.mtConfirmation, mbYesNoCancel, 0);
  CheckEquals(mrCancel, R);
  // Nur OK: Esc = OK
  R := PPGMessageDlg('!', TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], 0);
  CheckEquals(mrOk, R);
  // Ohne Abbrechen-faehigen Button: Esc wirkungslos
  FClick := mrRetry;
  R := PPGMessageDlg('!', TMsgDlgType.mtError, mbAbortRetryIgnore, 0);
  CheckEquals(mrRetry, R);
  CheckTrue(StartsText('False', FInfo), FInfo);
  // Eigener Standard-Button
  FClick := mrNone;
  PPGOnDialogShow := OnShowClick;
  FClick := mrNo;
  R := PPGMessageDlg('?', TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0,
    TMsgDlgBtn.mbNo);
  CheckEquals(mrNo, R);
end;

procedure TDialogTests.HelpButtonDoesNotClose;
begin
  FAction := 7;
  PPGOnDialogShow := OnShowTask;
  CheckEquals(mrOk, PPGMessageDlg('!', TMsgDlgType.mtInformation,
    [TMsgDlgBtn.mbOK, TMsgDlgBtn.mbHelp], 0));
  CheckEquals('True', FInfo, 'Hilfe schliesst nicht');
end;

procedure TDialogTests.TaskButtonClicked(Sender: TObject; ModalResult: TModalResult;
  var CanClose: Boolean);
begin
  FLog.Add('button:' + IntToStr(ModalResult));
  if FRefuse > 0 then
  begin
    Dec(FRefuse);
    CanClose := False;
  end;
end;

procedure TDialogTests.TaskRadio(Sender: TObject);
begin
  FLog.Add('radio:' + TPPGTaskDialog(Sender).RadioButton.Caption);
end;

procedure TDialogTests.TaskVerify(Sender: TObject);
begin
  FLog.Add('verify:' + System.SysUtils.BoolToStr(tfVerificationFlagChecked in TPPGTaskDialog(Sender).Flags, True));
end;

procedure TDialogTests.TaskExpanded(Sender: TObject);
begin
  FLog.Add('expanded:' + System.SysUtils.BoolToStr(TPPGTaskDialog(Sender).Expanded, True));
end;

procedure TDialogTests.TaskCreated(Sender: TObject);
begin
  FLog.Add('created');
end;

procedure TDialogTests.TaskDestroyed(Sender: TObject);
begin
  FLog.Add('destroyed');
end;

procedure TDialogTests.TaskTimer(Sender: TObject; TickCount: Cardinal; var Reset: Boolean);
var
  D: TPPGTaskDialog;
begin
  D := TPPGTaskDialog(Sender);
  Inc(FTicks);
  if FTicks = 1 then
  begin
    D.ProgressBar.Position := 40;
    D.Text := 'Schritt 2';
    D.Buttons[0].Enabled := False;
  end
  else if FTicks = 2 then
  begin
    FInfo := IntToStr(D.DialogForm.ProgressBar.Position) + ',' +
      System.SysUtils.BoolToStr(D.DialogForm.ButtonByResult(D.Buttons[0].ModalResult).Enabled, True);
    D.DialogForm.ClickButton(mrCancel);
  end;
end;

procedure TDialogTests.OnShowTask(Form: TPPGDialogForm);
begin
  case FAction of
    1:
      begin
        // Radio 3 waehlen, Bestaetigung an, erster Klick wird abgelehnt
        Form.Radio(2).Checked := True;
        Form.Radio(2).Click;
        Form.VerificationBox.Click;
        FRefuse := 1;
        Form.ClickButton(101);
        FInfo := System.SysUtils.BoolToStr(Form.ModalResult = mrNone, True);
        Form.ClickButton(101);
      end;
    2:
      begin
        FInfo := System.SysUtils.BoolToStr(Form.CanCancel, True);
        Form.Cancel;
        Form.ClickButton(mrOk);
      end;
    3:
      begin
        FInfo := Form.CopyText;
        Form.ClickButton(mrOk);
      end;
    4:
      begin
        Form.ExpandButton.Click;
        FLog.Add('caption:' + StripHotkey(Form.ExpandButton.Caption));
      end;
    5:
      begin
        CheckTrue(Form.ButtonAt(0) is TPPGCommandLink, 'Command-Link');
        CheckTrue(TPPGCommandLink(Form.ButtonAt(0)).Parent = Form.ContentPanel);
        CheckEquals('Hinweis', TPPGCommandLink(Form.ButtonAt(0)).Note);
        TPPGCommandLink(Form.ButtonAt(1)).Click;
      end;
    7:
      begin
        Form.ClickButton(mrHelp);
        FInfo := System.SysUtils.BoolToStr(Form.ModalResult = mrNone, True);
        Form.ClickButton(mrOk);
      end;
    6:
      begin
        FInfo := System.SysUtils.BoolToStr(TControl(FForm.FindComponent('Inhalt')).Parent <> FForm, True);
        Form.ClickButton(mrOk);
      end;
  end;
end;

procedure TDialogTests.TaskDialogEventsAndResults;
var
  D: TPPGTaskDialog;
  Item: TTaskDialogBaseButtonItem;
begin
  D := NewTask;
  D.CommonButtons := [tcbCancel];
  Item := D.Buttons.Add;
  Item.Caption := 'Speichern';
  Item.ModalResult := 101;
  Item := D.Buttons.Add;
  Item.Caption := 'Verwerfen';
  Item.ModalResult := 102;
  D.RadioButtons.Add.Caption := 'Eins';
  D.RadioButtons.Add.Caption := 'Zwei';
  D.RadioButtons.Add.Caption := 'Drei';
  D.RadioButtons[1].Default := True;
  D.VerificationText := 'Nicht mehr fragen';
  D.OnButtonClicked := TaskButtonClicked;
  D.OnRadioButtonClicked := TaskRadio;
  D.OnVerificationClicked := TaskVerify;
  D.OnDialogCreated := TaskCreated;
  D.OnDialogDestroyed := TaskDestroyed;
  FAction := 1;
  PPGOnDialogShow := OnShowTask;
  CheckTrue(D.Execute);
  CheckEquals('created,radio:Drei,verify:True,button:101,button:101,destroyed', FLog.CommaText);
  CheckEquals('True', FInfo, 'abgelehnter Klick laesst den Dialog offen');
  CheckEquals(101, D.ModalResult);
  CheckTrue(D.Button <> nil);
  CheckEquals('Speichern', D.Button.Caption);
  CheckTrue(D.RadioButton <> nil);
  CheckEquals('Drei', D.RadioButton.Caption);
  CheckTrue(tfVerificationFlagChecked in D.Flags);
  // Vorauswahl ohne Ereignis, Ergebnis ohne Klick auf ein Optionsfeld
  FLog.Clear;
  FAction := 0;
  FClick := mrCancel;
  PPGOnDialogShow := OnShowClick;
  D.Execute;
  CheckEquals('Zwei', D.RadioButton.Caption, 'Standard-Optionsfeld');
  CheckEquals(mrCancel, D.ModalResult);
  CheckEquals(-1, FLog.IndexOf('radio:Zwei'), 'Vorauswahl ohne Ereignis');
end;

procedure TDialogTests.EscapeOnlyWhenCancellable;
var
  D: TPPGTaskDialog;
begin
  D := NewTask;
  D.CommonButtons := [tcbOk];
  D.Flags := [];
  FAction := 2;
  PPGOnDialogShow := OnShowTask;
  D.Execute;
  CheckEquals('False', FInfo);
  CheckEquals(mrOk, D.ModalResult, 'Esc schliesst nicht');
  D.Flags := [tfAllowDialogCancellation];
  D.Execute;
  CheckEquals('True', FInfo);
  CheckEquals(mrCancel, D.ModalResult, 'Esc = mrCancel');
end;

procedure TDialogTests.CopyTextInWindowsFormat;
var
  D: TPPGTaskDialog;
begin
  D := NewTask;
  D.FooterText := 'Fuss';
  FAction := 3;
  PPGOnDialogShow := OnShowTask;
  D.Execute;
  CheckTrue(Pos('[Window Title]' + sLineBreak + 'Testdialog', FInfo) = 1, FInfo);
  CheckTrue(Pos('[Main Instruction]' + sLineBreak + 'Datei speichern?', FInfo) > 0);
  CheckTrue(Pos('[Content]' + sLineBreak + 'Die Datei wurde geaendert.', FInfo) > 0);
  CheckTrue(Pos('[' + PPGStr(@SPPGDlgOK) + '] [' + PPGStr(@SPPGDlgCancel) + ']', FInfo) > 0, FInfo);
  CheckTrue(Pos('[Footer]' + sLineBreak + 'Fuss', FInfo) > 0);
end;

procedure TDialogTests.ExpandAndTimerAndProgress;
var
  D: TPPGTaskDialog;
begin
  D := NewTask;
  D.ExpandedText := 'Weitere Angaben';
  D.Flags := [tfAllowDialogCancellation, tfCallbackTimer, tfShowProgressBar];
  D.Buttons.Add.Caption := 'Eigener';
  D.OnExpanded := TaskExpanded;
  D.OnTimer := TaskTimer;
  FAction := 4;
  PPGOnDialogShow := OnShowTask;
  CheckFalse(D.Expanded);
  D.Execute;
  CheckEquals('expanded:True,"caption:' + PPGStr(@SPPGDlgHideDetails) + '"', FLog.CommaText);
  CheckTrue(D.Expanded);
  CheckEquals('40,False', FInfo, 'Fortschritt und Enabled aus OnTimer uebernommen');
  CheckEquals(mrCancel, D.ModalResult);
  // Ausgeklappt nach Vorgabe
  D.Flags := [tfExpandedByDefault, tfAllowDialogCancellation];
  D.OnExpanded := nil;
  FClick := mrOk;
  PPGOnDialogShow := OnShowClick;
  D.Execute;
  CheckTrue(D.Expanded);
end;

procedure TDialogTests.CommandLinks;
var
  D: TPPGTaskDialog;
  Item: TTaskDialogButtonItem;
begin
  D := NewTask;
  D.Flags := [tfUseCommandLinks, tfAllowDialogCancellation];
  D.CommonButtons := [tcbCancel];
  Item := TTaskDialogButtonItem(D.Buttons.Add);
  Item.Caption := 'Speichern';
  Item.CommandLinkHint := 'Hinweis';
  Item.ModalResult := 201;
  Item := TTaskDialogButtonItem(D.Buttons.Add);
  Item.Caption := 'Nicht speichern';
  Item.ModalResult := 202;
  FAction := 5;
  PPGOnDialogShow := OnShowTask;
  D.Execute;
  CheckEquals(202, D.ModalResult);
end;

procedure TDialogTests.ContentControlIsReturned;
var
  D: TPPGTaskDialog;
  P: TPanel;
begin
  P := TPanel.Create(FForm);
  P.Name := 'Inhalt';
  P.Parent := FForm;
  P.SetBounds(5, 6, 120, 40);
  P.Visible := False;
  D := NewTask;
  D.ContentControl := P;
  FAction := 6;
  PPGOnDialogShow := OnShowTask;
  D.Execute;
  CheckEquals('True', FInfo, 'im Dialog');
  CheckTrue(P.Parent = FForm, 'zurueckgegeben');
  CheckEquals(5, P.Left);
  CheckEquals(6, P.Top);
  CheckEquals(120, P.Width);
  CheckFalse(P.Visible);
  // Freigegebenes Control wird vergessen
  P.Free;
  CheckTrue(D.ContentControl = nil);
end;

procedure TDialogTests.LoadsTTaskDialogDfm;
var
  T: TTaskDialog;
  D: TPPGTaskDialog;
  MS: TMemoryStream;
  B: TTaskDialogBaseButtonItem;
begin
  T := TTaskDialog.Create(nil);
  D := TPPGTaskDialog.Create(nil);
  MS := TMemoryStream.Create;
  try
    T.Caption := 'C';
    T.Title := 'T';
    T.Text := 'X';
    T.MainIcon := tdiWarning;
    T.CommonButtons := [tcbYes, tcbNo];
    T.DefaultButton := tcbNo;
    T.Flags := [tfUseCommandLinks, tfAllowDialogCancellation];
    T.VerificationText := 'V';
    T.FooterText := 'F';
    T.ExpandedText := 'E';
    B := T.Buttons.Add;
    B.Caption := 'Eigener';
    B.ModalResult := 150;
    T.RadioButtons.Add.Caption := 'R1';
    MS.WriteComponent(T);
    MS.Position := 0;
    MS.ReadComponent(D);
    CheckEquals('C', D.Caption);
    CheckEquals('T', D.Title);
    CheckEquals('X', D.Text);
    CheckEquals(tdiWarning, D.MainIcon);
    CheckTrue(D.CommonButtons = [tcbYes, tcbNo]);
    CheckTrue(D.DefaultButton = tcbNo);
    CheckTrue(tfUseCommandLinks in D.Flags);
    CheckEquals('V', D.VerificationText);
    CheckEquals('F', D.FooterText);
    CheckEquals('E', D.ExpandedText);
    CheckEquals(1, D.Buttons.Count);
    CheckEquals('Eigener', D.Buttons[0].Caption);
    CheckEquals(150, D.Buttons[0].ModalResult);
    CheckEquals('R1', D.RadioButtons[0].Caption);
  finally
    MS.Free;
    D.Free;
    T.Free;
  end;
end;

procedure TDialogTests.OnShowInput(Form: TPPGDialogForm);
var
  E: TPPGEdit;
  I: Integer;
  P: TWinControl;
begin
  P := TWinControl(Form.Dialog.ContentControl);
  E := nil;
  for I := 0 to P.ControlCount - 1 do
    if P.Controls[I] is TPPGEdit then
    begin
      E := TPPGEdit(P.Controls[I]);
      if FAction = 1 then
        FInfo := FInfo + IntToStr(Ord(E.PasswordChar <> #0)) + ',';
    end;
  if FAction = 1 then
  begin
    // Erster Versuch zu kurz: bleibt offen, Fehlertext sichtbar
    E.Text := 'ab';
    Form.ClickButton(mrOk);
    FInfo := FInfo + System.SysUtils.BoolToStr(Form.ModalResult = mrNone, True) + ',';
    for I := 0 to P.ControlCount - 1 do
      if (P.Controls[I] is TPPGLabel) and (TPPGLabel(P.Controls[I]).Caption = 'zu kurz') then
        FInfo := FInfo + System.SysUtils.BoolToStr(P.Controls[I].Visible, True);
    E.Text := 'abc';
    Form.ClickButton(mrOk);
  end
  else
    Form.Cancel;
end;

procedure TDialogTests.InputQueryValidates;
var
  Values: array[0..1] of string;
  S: string;
begin
  Values[0] := 'Anna';
  Values[1] := '';
  FAction := 1;
  PPGOnDialogShow := OnShowInput;
  CheckTrue(PPGInputQuery('Anmelden', ['Name', #31'Kennwort'], Values,
    function(const V: TArray<string>; var ErrorText: string; var FieldIndex: Integer): Boolean
    begin
      Result := Length(V[1]) >= 3;
      if not Result then
      begin
        ErrorText := 'zu kurz';
        FieldIndex := 1;
      end;
    end));
  CheckEquals('0,1,True,True', FInfo, 'Passwortfeld, offen nach Fehler, Fehlertext');
  CheckEquals('Anna', Values[0]);
  CheckEquals('abc', Values[1]);
  // Abbrechen: Wert bleibt
  FAction := 2;
  S := 'alt';
  CheckFalse(PPGInputQuery('Titel', 'Wert', S));
  CheckEquals('alt', S);
  CheckEquals('vorgabe', PPGInputBox('Titel', 'Wert', 'vorgabe'));
end;

type
  TDlgThread = class(TThread)
  public
    Raised: Boolean;
  protected
    procedure Execute; override;
  end;

procedure TDlgThread.Execute;
begin
  try
    PPGShowMessage('aus dem Thread');
  except
    on EPPGError do
      Raised := True;
  end;
end;

procedure TDialogTests.CallFromThreadRaises;
var
  T: TDlgThread;
begin
  T := TDlgThread.Create(False);
  try
    T.WaitFor;
    CheckTrue(T.Raised, 'EPPGError statt Haenger');
  finally
    T.Free;
  end;
end;

procedure TDialogTests.OnShowCapture(Form: TPPGDialogForm);
var
  B: TBitmap;
begin
  B := RenderToBitmap(Form);
  try
    FSheet.Canvas.TextOut(4, FSheetY, Form.Dialog.Preset + ' ' + FInfo);
    FSheet.Canvas.Draw(10, FSheetY + 18, B);
    Inc(FSheetY, B.Height + 30);
  finally
    B.Free;
  end;
  Form.Cancel;
  Form.ClickButton(mrOk);
end;

procedure TDialogTests.DialogGallery;
var
  Names: TStringList;
  P: Integer;
  Dark: Boolean;
  D: TPPGTaskDialog;
  Item: TTaskDialogButtonItem;
  Png: TPngImage;
  Dir: string;
  CL: Boolean;
begin
  Names := TStringList.Create;
  FSheet := TBitmap.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    FSheet.PixelFormat := pf24bit;
    FSheet.SetSize(1300, Names.Count * 2 * 2 * 330);
    FSheet.Canvas.Brush.Color := clWhite;
    FSheet.Canvas.FillRect(Rect(0, 0, FSheet.Width, FSheet.Height));
    FSheetY := 0;
    PPGOnDialogShow := OnShowCapture;
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
        for CL := False to True do
        begin
          if Dark then
            TPPGTheme.Mode := tmDark
          else
            TPPGTheme.Mode := tmLight;
          FInfo := IfThen(Dark, 'dunkel', 'hell');
          D := NewTask;
          try
            D.Preset := Names[P];
            D.MainIcon := tdiWarning;
            D.CommonButtons := [tcbCancel];
            D.FooterText := 'Aenderungen gehen sonst verloren.';
            D.FooterIcon := tdiInformation;
            D.VerificationText := 'Nicht mehr fragen';
            D.ExpandedText := 'Pfad: C:\Daten\Bericht.docx';
            D.RadioButtons.Add.Caption := 'Alle Dateien';
            D.RadioButtons.Add.Caption := 'Nur diese Datei';
            D.Flags := [tfAllowDialogCancellation, tfShowProgressBar];
            D.ProgressBar.Position := 60;
            if CL then
              D.Flags := D.Flags + [tfUseCommandLinks];
            Item := TTaskDialogButtonItem(D.Buttons.Add);
            Item.Caption := '&Speichern';
            Item.CommandLinkHint := 'Speichert die Aenderungen in der Datei.';
            Item.Default := True;
            Item := TTaskDialogButtonItem(D.Buttons.Add);
            Item.Caption := '&Nicht speichern';
            D.Execute;
          finally
            D.Free;
          end;
        end;
    Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
    ForceDirectories(Dir);
    Png := TPngImage.Create;
    try
      Png.Assign(FSheet);
      Png.SaveToFile(Dir + 'Dialog.png');
    finally
      Png.Free;
    end;
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    FreeAndNil(FSheet);
    Names.Free;
  end;
end;

{ TWizardTests }

procedure TWizardTests.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FBlock := False;
  FForm.SetBounds(100, 100, 640, 420);
end;

procedure TWizardTests.TearDown;
begin
  TPPGTheme.Mode := tmLight;
  FreeAndNil(FLog);
  inherited TearDown;
end;

function TWizardTests.NewWizard: TPPGWizard;
const
  Titles: array[0..3] of string = ('Willkommen', 'Optionen', 'Erweitert', 'Fertig');
var
  I: Integer;
  P: TPPGWizardPage;
begin
  Result := TPPGWizard.Create(FForm);
  Result.Parent := FForm;
  Result.Align := alClient;
  for I := 0 to High(Titles) do
  begin
    P := TPPGWizardPage.Create(FForm);
    P.Caption := Titles[I];
    P.Wizard := Result;
  end;
  Result.OnCanAdvance := CanAdvance;
  Result.OnChange := Changed;
  Result.OnFinish := Finished;
  Result.OnCancel := Cancelled;
end;

procedure TWizardTests.CanAdvance(Sender: TObject; Page: TPPGWizardPage; var Allow: Boolean);
begin
  FLog.Add('can:' + Page.Caption);
  if FBlock then
    Allow := False;
end;

procedure TWizardTests.Changed(Sender: TObject);
begin
  FLog.Add('page:' + TPPGWizard(Sender).ActivePage.Caption);
end;

procedure TWizardTests.Finished(Sender: TObject);
begin
  FLog.Add('finish');
end;

procedure TWizardTests.Cancelled(Sender: TObject);
begin
  FLog.Add('cancel');
end;

procedure TWizardTests.BackWithoutActivePageStays;
var
  W: TPPGWizard;
begin
  // Audit 08.10.2026: Back ohne aktive Seite sprang auf die letzte Seite
  W := NewWizard;
  W.ActivePage := nil;
  FLog.Clear;
  CheckFalse(W.Back, 'nichts zurueck');
  CheckNull(W.ActivePage, 'keine Seite aktiviert');
  CheckEquals(0, FLog.Count, 'kein Ereignis');
end;

procedure TWizardTests.StepsSkipInvisiblePages;
var
  W: TPPGWizard;
begin
  W := NewWizard;
  CheckEquals(4, W.PageCount);
  CheckTrue(W.ActivePage = W.Pages[0], 'erste Seite aktiv');
  CheckTrue(W.Pages[0].Visible);
  W.Pages[2].PageVisible := False;
  CheckEquals(3, W.StepCount);
  CheckTrue(W.Next);
  CheckTrue(W.Next);
  CheckEquals('Fertig', W.ActivePage.Caption, 'unsichtbare Seite uebersprungen');
  CheckEquals(2, W.StepIndex);
  CheckTrue(W.IsLastStep);
  CheckTrue(W.Back);
  CheckEquals('Optionen', W.ActivePage.Caption);
  CheckEquals('can:Willkommen,page:Optionen,can:Optionen,page:Fertig,page:Optionen',
    FLog.CommaText);
  CheckFalse(W.Pages[0].Visible, 'nur die aktive Seite sichtbar');
end;

procedure TWizardTests.CanAdvanceBlocks;
var
  W: TPPGWizard;
begin
  W := NewWizard;
  FBlock := True;
  CheckFalse(W.Next);
  CheckEquals('Willkommen', W.ActivePage.Caption);
  CheckEquals('can:Willkommen', FLog.CommaText);
  // Letzter Schritt: Weiter = Fertig (nach Pruefung)
  FBlock := False;
  FLog.Clear;
  W.ActivePage := W.Pages[3];
  W.Next;
  CheckEquals('can:Fertig,finish', FLog.CommaText);
end;

procedure TWizardTests.CodeSetFiresNoEvents;
var
  W: TPPGWizard;
begin
  W := NewWizard;
  W.ActivePage := W.Pages[2];
  W.ActivePageIndex := 1;
  CheckEquals('Optionen', W.ActivePage.Caption);
  CheckEquals(0, FLog.Count);
end;

procedure TWizardTests.ButtonsAndCaptions;
var
  W: TPPGWizard;
begin
  W := NewWizard;
  FForm.Show;
  CheckFalse(W.BackButton.Enabled, 'Zurueck auf dem ersten Schritt aus');
  CheckEquals(PPGStr(@SPPGWizNext), W.NextButton.Caption);
  CheckTrue(W.NextButton.Default, 'Enter = Weiter');
  CheckTrue(W.CancelButton.Cancel, 'Esc = Abbrechen');
  W.NextButton.Click;
  CheckTrue(W.BackButton.Enabled);
  W.ActivePage := W.Pages[3];
  CheckEquals(PPGStr(@SPPGWizFinish), W.NextButton.Caption);
  W.CancelButton.Click;
  CheckEquals('can:Willkommen,page:Optionen,cancel', FLog.CommaText);
  W.ShowCancel := False;
  CheckFalse(W.CancelButton.Visible);
  // Buttons liegen in der Leiste unten, rechts
  CheckTrue(W.NextButton.Top > W.ClientHeight - 56);
  CheckTrue(W.NextButton.Left > W.BackButton.Left);
  // Seite liegt zwischen Kopf und Leiste
  CheckTrue(W.ActivePage.Top >= 60);
  CheckTrue(W.ActivePage.BoundsRect.Bottom <= W.NextButton.Top);
end;

procedure TWizardTests.ClickOnDoneStepGoesBack;
var
  W: TPPGWizard;
  R: TRect;
begin
  W := NewWizard;
  FForm.Show;
  W.ActivePage := W.Pages[2];
  R := W.StepRect(0);
  W.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam((R.Left + R.Right) div 2,
    (R.Top + R.Bottom) div 2));
  W.Perform(WM_LBUTTONUP, 0, MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
  CheckEquals('Willkommen', W.ActivePage.Caption);
  CheckEquals('page:Willkommen', FLog.CommaText);
  // Spaeterer Schritt: kein Sprung nach vorn ohne Pruefung
  R := W.StepRect(3);
  W.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam((R.Left + R.Right) div 2,
    (R.Top + R.Bottom) div 2));
  W.Perform(WM_LBUTTONUP, 0, MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2));
  CheckEquals('Willkommen', W.ActivePage.Caption);
end;

procedure TWizardTests.StreamingRoundTrip;
var
  W, W2: TPPGWizard;
  MS: TMemoryStream;
  I, Pages, Btns: Integer;
begin
  RegisterClass(TPPGWizardPage);
  W := NewWizard;
  W.StepPosition := wspLeft;
  W.ShowCancel := False;
  W.Pages[2].PageVisible := False;
  W.Pages[1].Description := 'Hinweis';
  MS := TMemoryStream.Create;
  W2 := TPPGWizard.Create(nil);
  try
    MS.WriteComponent(W);
    MS.Position := 0;
    MS.ReadComponent(W2);
    CheckEquals(4, W2.PageCount);
    CheckEquals('Erweitert', W2.Pages[2].Caption);
    CheckFalse(W2.Pages[2].PageVisible);
    CheckEquals('Hinweis', W2.Pages[1].Description);
    CheckTrue(W2.StepPosition = wspLeft);
    CheckFalse(W2.ShowCancel);
    Pages := 0;
    Btns := 0;
    for I := 0 to W2.ControlCount - 1 do
      if W2.Controls[I] is TPPGWizardPage then
        Inc(Pages)
      else if W2.Controls[I] is TPPGButton then
        Inc(Btns);
    CheckEquals(4, Pages);
    CheckEquals(3, Btns, 'Buttons nicht aus der DFM verdoppelt');
  finally
    W2.Free;
    MS.Free;
  end;
end;

procedure TWizardTests.WizardGallery;
var
  Names: TStringList;
  P, Y: Integer;
  Dark: Boolean;
  Pos: TPPGWizardStepPosition;
  W: TPPGWizard;
  Sheet, B: TBitmap;
  Png: TPngImage;
  Dir: string;
begin
  Names := TStringList.Create;
  Sheet := TBitmap.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    Sheet.PixelFormat := pf24bit;
    Sheet.SetSize(1320, Names.Count * 2 * 360);
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    FForm.SetBounds(0, 0, 640, 360);
    FForm.Show;
    W := NewWizard;
    W.ActivePage := W.Pages[1];
    Y := 0;
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        W.Preset := Names[P];
        Sheet.Canvas.TextOut(4, Y, Names[P] + IfThen(Dark, ' dunkel', ' hell'));
        for Pos := wspTop to wspLeft do
        begin
          W.StepPosition := Pos;
          B := RenderToBitmap(W);
          try
            Sheet.Canvas.Draw(10 + Ord(Pos) * 660, Y + 18, B);
          finally
            B.Free;
          end;
        end;
        Inc(Y, 360);
      end;
    Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
    ForceDirectories(Dir);
    Png := TPngImage.Create;
    try
      Png.Assign(Sheet);
      Png.SaveToFile(Dir + 'Wizard.png');
    finally
      Png.Free;
    end;
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Sheet.Free;
    Names.Free;
  end;
end;

initialization
  RegisterTest('Phase11c', TDialogTests.Suite);
  RegisterTest('Phase11c', TWizardTests.Suite);

end.
