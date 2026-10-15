unit DemoShowButton;

// Komponentenseite TPPGButton (Gruppe "Buttons & Aktionen"): Buehne und
// Inspektor kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten
// des Buttons (Hinweis zu ModalResult auf der Buehne) und die beiden
// Praxisbeispiele (ExButtonDialog, ExButtonToolbar).

interface

uses
  System.SysUtils, System.Classes, System.UITypes, Vcl.Controls, Vcl.Forms,
  PPG.Button, PPG.Labels, DemoKit, DemoShowcase, ExButtonDialog, ExButtonToolbar;

type
  TDemoShowButtonPage = class(TDemoComponentPage)
  private
    FDialogResult: TPPGLabel;
    FBar: TFormatBar;
    procedure OpenDialogClick(Sender: TObject);
    procedure ScrollInspectorFast(Check: TDemoCheck);
  protected
    function SubjectClass: TComponentClass; override;
    procedure BuildExamples; override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.Imaging.pngimage, PPG.Memo, PPG.Panel;

function TDemoShowButtonPage.SubjectClass: TComponentClass;
begin
  Result := TPPGButton;
end;

procedure TDemoShowButtonPage.EventOccurred(const AName, ADetail: string);
var
  Form: TCustomForm;
  Detail: string;
begin
  Detail := ADetail;
  if (AName = 'OnClick') and (Subject is TPPGButton) then
  begin
    // Der Klick hat ModalResult an das Formular weitergegeben. Im Dialog
    // schloesse sich das Fenster jetzt; das Demo-Fenster bleibt offen.
    Form := GetParentForm(TPPGButton(Subject));
    if (Form <> nil) and (Form.ModalResult <> mrNone) then
    begin
      Detail := L(Format('Formular.ModalResult = %d {-} in einem Dialog schlie{ss}t sich jetzt das Fenster',
        [Form.ModalResult]));
      Form.ModalResult := mrNone;
    end
    else if TPPGButton(Subject).GroupIndex <> 0 then
      Detail := Format('Down = %s', [BoolToStr(TPPGButton(Subject).Down, True)]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowButtonPage.BuildExamples;
var
  V: TDemoExampleView;
  Btn: TPPGButton;
begin
  V := AddExample('Praxis: Speichern-Dialog', 'ExButtonDialog',
    'Ein Dialog wie "Speichern unter": <b>Default</b> (Enter speichert), <b>Cancel</b> '
    + '(Esc bricht ab) und <b>ModalResult</b> (der Klick schlie{ss}t den Dialog ohne eigenen Code). '
    + 'Speichern ist gesperrt, solange kein Dateiname eingetragen ist. Probieren Sie: Feld leeren '
    + 'und Enter dr{ue}cken, dann einen Namen eingeben und Enter, zuletzt Esc.');
  Btn := NewButton(Own, V.Live, 24, 24, 220, 'Speichern unter {...}', OpenDialogClick, True);
  Btn.Images := Host.Images;
  Btn.ImageIndex := 0;
  FDialogResult := NewLabel(Own, V.Live, 24, 72, 600, 'Ergebnis: noch nicht ge{oe}ffnet', tkBody);

  V := AddExample('Praxis: Formatleiste', 'ExButtonToolbar',
    'Eine Formatleiste {ue}ber einem Text: drei <b>Umschalter mit GroupIndex</b> (immer genau einer '
    + 'gedr{ue}ckt, au{ss}en rund und innen eckig {-} RoundedCorners), ein <b>Fett-Umschalter mit '
    + 'AllowAllUp</b> und ein <b>Split-Button</b> "Exportieren": Der Hauptteil exportiert als PDF, '
    + 'der Pfeil (oder Alt+Pfeil runter) {oe}ffnet weitere Formate.');
  FBar := TFormatBar.CreateBar(Own, V.Live, DemoStyles);
end;

procedure TDemoShowButtonPage.OpenDialogClick(Sender: TObject);
var
  FileName: string;
begin
  FileName := AskFileName(Own, Host.Images, DemoStyles, 'Angebot 2026');
  if FileName = '' then
    FDialogResult.Caption := L('Ergebnis: abgebrochen (ShowModal = mrCancel)')
  else
    FDialogResult.Caption := Format(L('Ergebnis: gespeichert als "%s" (ShowModal = mrOk)'), [FileName]);
end;

procedure TDemoShowButtonPage.SelfTest(Check: TDemoCheck);
var
  Dlg: TSaveAsDialog;
  Btn: TPPGButton;
  Form: TCustomForm;
begin
  inherited SelfTest(Check);
  // Buehne: Klick erscheint im Protokoll; ModalResult wird gemeldet und am
  // Demo-Fenster zurueckgesetzt
  ResetSubject;
  Btn := TPPGButton(Subject);
  Btn.Click;
  Check('TPPGButton: Klick auf der B' + #$00FC + 'hne erscheint im Ereignis-Protokoll',
    (EventList.Items.Count > 0) and (Pos('OnClick', EventList.Items[0]) > 0));
  Inspector.SetValueText('ModalResult', 'mrOk');
  Btn.Click;
  Form := GetParentForm(Btn);
  Check('TPPGButton: ModalResult wird gemeldet, das Demo-Fenster bleibt offen',
    (Pos('ModalResult', EventList.Items[0]) > 0) and (Form <> nil) and (Form.ModalResult = mrNone));
  ResetSubject;

  // Praxisbeispiel 1 ohne ShowModal: Sperre, Default/Cancel, ModalResult
  Dlg := TSaveAsDialog.CreateDialog(nil, Host.Images, DemoStyles);
  try
    Check('Beispiel Dialog: Speichern ohne Dateinamen gesperrt', not Dlg.SaveButton.Enabled);
    Dlg.FileNameEdit.Text := 'Angebot';
    Check('Beispiel Dialog: Speichern mit Dateinamen frei', Dlg.SaveButton.Enabled);
    Check('Beispiel Dialog: Speichern = Default/mrOk, Abbrechen = Cancel/mrCancel',
      Dlg.SaveButton.Default and (Dlg.SaveButton.ModalResult = mrOk) and
      Dlg.CancelButton.Cancel and (Dlg.CancelButton.ModalResult = mrCancel));
    Dlg.SaveButton.Click;
    Check('Beispiel Dialog: Klick auf Speichern setzt ModalResult = mrOk', Dlg.ModalResult = mrOk);
    Dlg.ModalResult := mrNone;
    Dlg.CancelButton.Click;
    Check('Beispiel Dialog: Klick auf Abbrechen setzt ModalResult = mrCancel',
      Dlg.ModalResult = mrCancel);
  finally
    Dlg.Free;
  end;

  // Praxisbeispiel 2: Gruppe, Umschalter, Split-Button
  FBar.AlignCenter.Click;
  Check('Beispiel Formatleiste: Mitte gedr' + #$00FC + 'ckt, Links ausgerastet, Text zentriert',
    FBar.AlignCenter.Down and not FBar.AlignLeft.Down and (FBar.Text.Alignment = taCenter));
  FBar.AlignCenter.Click;
  Check('Beispiel Formatleiste: ohne AllowAllUp bleibt Mitte gedr' + #$00FC + 'ckt',
    FBar.AlignCenter.Down);
  FBar.Bold.Click;
  Check('Beispiel Formatleiste: Fett rastet ein', FBar.Bold.Down and (fsBold in FBar.Text.Font.Style));
  FBar.Bold.Click;
  Check('Beispiel Formatleiste: Fett rastet mit AllowAllUp wieder aus',
    (not FBar.Bold.Down) and not (fsBold in FBar.Text.Font.Style));
  FBar.ExportButton.Click;
  Check('Beispiel Formatleiste: Hauptteil des Split-Buttons exportiert als PDF',
    FBar.LastExport = 'PDF');
  FBar.ExportMenu.Items[1].Click;
  Check('Beispiel Formatleiste: Men' + #$00FC + 'eintrag exportiert als Excel',
    FBar.LastExport = 'Excel');
  FBar.Text.Lines.Text := '';
  FBar.ExportButton.OnDropDownClick(FBar.ExportButton);
  Check('Beispiel Formatleiste: OnDropDownClick sperrt "Zwischenablage" ohne Text',
    not FBar.ExportMenu.Items[2].Enabled);
  FBar.Text.Lines.Text := 'Text';
  FBar.AlignLeft.Click;
  ScrollInspectorFast(Check);
end;

procedure TDemoShowButtonPage.ScrollInspectorFast(Check: TDemoCheck);

  function Capture(C: TWinControl): TBitmap;
  var
    DC: HDC;
  begin
    // Was wirklich im Fenster steht (nicht neu gezeichnet)
    Result := TBitmap.Create;
    Result.PixelFormat := pf32bit;
    Result.SetSize(C.ClientWidth, C.ClientHeight);
    DC := GetDC(C.Handle);
    try
      BitBlt(Result.Canvas.Handle, 0, 0, C.ClientWidth, C.ClientHeight, DC, 0, 0, SRCCOPY);
    finally
      ReleaseDC(C.Handle, DC);
    end;
  end;

  procedure Pump(Count: Integer);
  var
    I: Integer;
  begin
    for I := 1 to Count do
    begin
      Application.ProcessMessages;
      Sleep(10);
    end;
  end;

  procedure SavePng(B: TBitmap; const AName: string);
  var
    Png: TPngImage;
  begin
    Png := TPngImage.Create;
    try
      Png.Assign(B);
      Png.SaveToFile(ExtractFilePath(ParamStr(0)) + AName);
    finally
      Png.Free;
    end;
  end;

var
  Box: TPPGScrollBox;
  Moved, Full: TBitmap;
  I, X, Y, Diff: Integer;
  P: TPoint;
begin
  // Objektinspektor schnell runter und wieder hoch scrollen (Mausrad mit
  // Animation), danach muss das Fenster aussehen wie komplett neu gezeichnet
  ShowTab(0);
  Box := Inspector.ScrollBox;
  Pump(20);
  if not IsWindowVisible(Box.Handle) then
  begin
    Check('Objektinspektor: schnelles Scrollen (Inspektor nicht sichtbar)', False);
    Exit;
  end;
  for I := 1 to 12 do
  begin
    Box.ScrollTo(0, Box.ScrollPos.Y + 120, True);
    Pump(2);
  end;
  for I := 1 to 12 do
  begin
    Box.ScrollTo(0, Box.ScrollPos.Y - 120, True);
    Pump(2);
  end;
  Pump(50);
  // Wie von Hand (nur auf dem echten Desktop): Fenster gross, Mauszeiger ueber
  // dem Inspektor, echte Mausrad-Ereignisse schnell hintereinander
  if FindCmdLineSwitch('realwheel') then
  begin
    GetParentForm(Box).WindowState := wsMaximized;
    Pump(30);
    P := Box.ClientToScreen(Point(Box.ClientWidth div 3, Box.ClientHeight div 2));
    SetCursorPos(P.X, P.Y);
    Pump(5);
    for I := 1 to 25 do
    begin
      mouse_event(MOUSEEVENTF_WHEEL, 0, 0, DWORD(-WHEEL_DELTA), 0);
      Pump(1);
    end;
    Pump(30);
    for I := 1 to 25 do
    begin
      mouse_event(MOUSEEVENTF_WHEEL, 0, 0, WHEEL_DELTA, 0);
      Pump(1);
    end;
    Pump(60);
  end;
  Moved := Capture(Box);
  try
    RedrawWindow(Box.Handle, nil, 0, RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
    Full := Capture(Box);
    try
      Diff := 0;
      for Y := 0 to Full.Height - 1 do
        for X := 0 to Full.Width - 1 do
          if Moved.Canvas.Pixels[X, Y] <> Full.Canvas.Pixels[X, Y] then
            Inc(Diff);
      if Diff > 0 then
      begin
        SavePng(Moved, 'scrolltest-moved.png');
        SavePng(Full, 'scrolltest-full.png');
      end;
      Check(Format('Objektinspektor: schnell runter und hoch gescrollt wie neu gezeichnet ' +
        '(%d abweichende Pixel)', [Diff]), Diff = 0);
    finally
      Full.Free;
    end;
  finally
    Moved.Free;
  end;
  Box.ScrollTo(0, 0);
end;

initialization
  RegisterShowcasePage('TPPGButton', TDemoShowButtonPage);

end.
