unit PPG.Tests.Phase4b;

{ Tests fuer Phase 4b: TPPGComboBox, Popup-Liste, virtuelle Kind-Elemente
  der Barrierefreiheit, IPPGListRenderer. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.oleacc,
  System.Classes, System.SysUtils, System.Types, System.Variants,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Consts, PPG.Render.Intf, PPG.Render.Registry, PPG.Render.Gdi,
  PPG.Button, PPG.Controls.Field, PPG.Popup, PPG.ComboBox,
  PPG.Tests.Controls, PPG.Tests.Gaps, PPG.Tests.Phase4a;

type
  TComboTestCase = class(TPhase4TestCase)
  protected
    FLog: TStringList;
    FSelects, FDropDowns2, FCloseUps: Integer;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure LogClick(Sender: TObject);
    procedure LogSelect(Sender: TObject);
    procedure LogChange(Sender: TObject);
    procedure LogDropDown(Sender: TObject);
    procedure LogCloseUp(Sender: TObject);
    procedure AddItemsOnDropDown(Sender: TObject);
    function NewCombo(AStyle: TComboBoxStyle = csDropDown): TPPGComboBox;
    /// Mausaktion an der Combo auf einen Eintrag der offenen Liste.
    procedure ClickItem(C: TPPGComboBox; Index: Integer);
    procedure TypeChar(C: TPPGComboBox; Ch: Char);
    procedure PumpPosted(Wnd: HWND);
  end;

  TComboBoxTests = class(TComboTestCase)
  published
    procedure DefaultsMatchTComboBox;
    procedure ItemIndexSetsTextWithoutEvents;
    procedure TextSelectsMatchingItem;
    procedure DropDownListHidesEditAndIsTabStop;
    procedure OpenAndCloseWithKeys;
    procedure SpecialKeysOnlyWhileOpen;
    procedure ClickOnItemSelectsAndCloses;
    procedure ClickOutsideCancels;
    procedure FocusOrCaptureLossCancels;
    procedure EventsInTComboBoxOrder;
    procedure ClosedKeysSelectDirectly;
    procedure TypeAheadInDropDownList;
    procedure AutoCompleteWhileTyping;
    procedure DropDownEventMayAddItems;
    procedure SortedAndItemChangesKeepSelection;
    procedure ClearButtonResetsSelection;
    procedure WheelScrollsOnlyOpenList;
    procedure PopupSizeFollowsDropDownCountAndWidth;
    procedure PopupOpensAboveWithoutRoomBelow;
    procedure TrackClickPagesList;
    procedure LoadsTComboBoxDfmAndRoundTrips;
  end;

  TComboAccessibilityTests = class(TComboTestCase)
  published
    procedure ComboRoleAndExpandedState;
    procedure ListExposesItemsAsChildren;
    procedure ItemDefaultActionSelectsAsynchronously;
  end;

  TPhase4bPaintTests = class(TComboTestCase)
  published
    procedure ArrowRotatesWhenOpen;
    procedure DropDownListPaintsItemText;
    procedure ListRendererBothPresetsAndGdi;
    procedure GdiCanvasBlendsAlpha;
    procedure FreeWhileOpenIsSafe;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

{$WARN SYMBOL_PLATFORM OFF}

type
  TComboAccess = class(TPPGComboBox);

const
  GR_GDIOBJECTS = 0;
  GR_USEROBJECTS = 1;

function PPG_AccessibleChildren(paccContainer: IAccessible; iChildStart, cChildren: Longint;
  rgvarChildren: POleVariant; out pcObtained: Longint): HResult; stdcall;
  external 'oleacc.dll' name 'AccessibleChildren';

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Cardinal(Word(SmallInt(X))) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function CenterOf(const R: TRect): TPoint;
begin
  Result := Point((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

procedure LoadDfm(const Text: string; Instance: TComponent);
var
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  Src := TStringStream.Create(Text);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(Instance);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

function ComponentToText(C: TComponent): string;
var
  Bin: TMemoryStream;
  Txt: TStringStream;
begin
  Bin := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    Bin.WriteComponent(C);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    Result := Txt.DataString;
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

function CountDiff(A, B: TBitmap; const R: TRect): Integer;
var
  X, Y: Integer;
begin
  Result := 0;
  for Y := R.Top to R.Bottom - 1 do
    for X := R.Left to R.Right - 1 do
      if A.Canvas.Pixels[X, Y] <> B.Canvas.Pixels[X, Y] then
        Inc(Result);
end;

{ TComboTestCase }

procedure TComboTestCase.SetUp;
begin
  inherited;
  FLog := TStringList.Create;
  FSelects := 0;
  FDropDowns2 := 0;
  FCloseUps := 0;
end;

procedure TComboTestCase.TearDown;
begin
  inherited;
  FreeAndNil(FLog);
end;

procedure TComboTestCase.LogClick(Sender: TObject);
begin
  FLog.Add('Click');
end;

procedure TComboTestCase.LogSelect(Sender: TObject);
begin
  Inc(FSelects);
  FLog.Add('Select');
end;

procedure TComboTestCase.LogChange(Sender: TObject);
begin
  Inc(FChanges);
  FLog.Add('Change');
end;

procedure TComboTestCase.LogDropDown(Sender: TObject);
begin
  Inc(FDropDowns2);
  FLog.Add('DropDown');
end;

procedure TComboTestCase.LogCloseUp(Sender: TObject);
begin
  Inc(FCloseUps);
  FLog.Add('CloseUp:' + IntToStr(TPPGComboBox(Sender).ItemIndex));
end;

procedure TComboTestCase.AddItemsOnDropDown(Sender: TObject);
begin
  TPPGComboBox(Sender).Items.Add('Neu');
end;

function TComboTestCase.NewCombo(AStyle: TComboBoxStyle): TPPGComboBox;
begin
  Result := TPPGComboBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 160, 25);
  Result.Preset := PPGPresetModernFlat;
  Result.Animation.Enabled := False;
  Result.Style := AStyle;
  Result.Items.Text := 'Apfel'#13#10'Banane'#13#10'Birne'#13#10'Cola'#13#10'Dattel';
  Result.OnChange := LogChange;
  Result.HandleNeeded;
end;

procedure TComboTestCase.ClickItem(C: TPPGComboBox; Index: Integer);
var
  P: TPoint;
begin
  P := C.PopupList.ClientToScreen(CenterOf(C.PopupList.ItemRect(Index)));
  P := C.ScreenToClient(P);
  C.Perform(WM_MOUSEMOVE, 0, MouseLParam(P.X, P.Y));
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(P.X, P.Y));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam(P.X, P.Y));
end;

procedure TComboTestCase.TypeChar(C: TPPGComboBox; Ch: Char);
var
  Inner: TWinControl;
  Before: string;
  S: string;
begin
  // Wie Tippen: KeyPress (WM_CHAR), dann Einfuegen an der Einfuegemarke.
  // Das native Edit fuegt WM_CHAR ohne echten Fokus nicht immer ein.
  Inner := TComboAccess(C).Inner;
  Before := C.Text;
  Inner.Perform(WM_CHAR, Ord(Ch), 0);
  if C.Text = Before then
  begin
    if Ch = #8 then
      S := ''
    else
      S := Ch;
    SendMessage(Inner.Handle, EM_REPLACESEL, 1, LPARAM(PChar(S)));
  end;
end;

procedure TComboTestCase.PumpPosted(Wnd: HWND);
var
  Msg: TMsg;
begin
  while PeekMessage(Msg, Wnd, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;
end;

{ TComboBoxTests }

procedure TComboBoxTests.DefaultsMatchTComboBox;
var
  C: TPPGComboBox;
begin
  C := TPPGComboBox.Create(nil);
  try
    CheckEquals(145, C.Width, 'Standardbreite wie TComboBox');
    CheckTrue(C.Style = csDropDown);
    CheckEquals(-1, C.ItemIndex);
    CheckEquals(8, C.DropDownCount);
    CheckEquals(0, C.DropDownWidth);
    CheckTrue(C.AutoComplete);
    CheckFalse(C.AutoDropDown);
    CheckFalse(C.Sorted);
    CheckTrue(C.TabStop);
    CheckFalse(C.DroppedDown);
    CheckEquals('', C.Text);
    CheckTrue(C.PopupList = nil, 'Popup erst beim ersten Aufklappen');
  finally
    C.Free;
  end;
end;

procedure TComboBoxTests.ItemIndexSetsTextWithoutEvents;
var
  C: TPPGComboBox;
begin
  C := NewCombo;
  C.ItemIndex := 1;
  CheckEquals('Banane', C.Text);
  CheckEquals(1, C.ItemIndex);
  C.ItemIndex := 99;
  CheckEquals(-1, C.ItemIndex, 'ungueltig = keine Auswahl (wie TComboBox)');
  CheckEquals('', C.Text);
  C.ItemIndex := 2;
  C.ItemIndex := -1;
  CheckEquals('', C.Text, '-1 leert den Text');
  CheckEquals(0, FChanges, 'Setzen im Code loest kein OnChange aus');
end;

procedure TComboBoxTests.TextSelectsMatchingItem;
var
  C: TPPGComboBox;
begin
  C := NewCombo;
  C.Text := 'birne';
  CheckEquals(2, C.ItemIndex, 'gleicher Text ohne Gross-/Kleinschreibung');
  C.Text := 'Kiwi';
  CheckEquals(-1, C.ItemIndex, 'freier Text');
  CheckEquals('Kiwi', C.Text);
  C.Style := csDropDownList;
  CheckEquals('', C.Text, 'Liste: freier Text entfaellt');
  C.Text := 'Cola';
  CheckEquals(3, C.ItemIndex);
  C.Text := 'Kiwi';
  CheckEquals(3, C.ItemIndex, 'Liste: unbekannter Text aendert nichts');
  CheckEquals('Cola', C.Text);
  CheckEquals(0, FChanges);
end;

procedure TComboBoxTests.DropDownListHidesEditAndIsTabStop;
var
  C: TPPGComboBox;
  B: TPPGButton;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    CheckFalse(TComboAccess(C).Inner.Visible, 'kein Edit');
    CheckTrue(TWinControl(C).TabStop, 'das Feld ist Tabstopp');
    CheckFalse(TComboAccess(C).Inner.TabStop);
    B := NewButton('B');
    B.Top := 200;
    B.SetFocus;
    FForm.Perform(WM_NEXTDLGCTL, 0, 0); // Tab
    CheckTrue(C.Focused, 'Tab erreicht die Combo');
    CheckEquals(C.Handle, GetFocus, 'Fokus liegt auf dem Feld selbst');
    C.Style := csDropDown;
    CheckTrue(TComboAccess(C).Inner.Visible);
    CheckFalse(TWinControl(C).TabStop);
    CheckTrue(TComboAccess(C).Inner.TabStop);
    C.TabStop := False;
    CheckFalse(TComboAccess(C).Inner.TabStop);
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.OpenAndCloseWithKeys;
var
  C: TPPGComboBox;
  Target: TWinControl;
  Style: TComboBoxStyle;
begin
  FForm.Show;
  try
    for Style := csDropDown to csDropDownList do
    begin
      if Style = csSimple then
        Continue;
      C := NewCombo(Style);
      C.ItemIndex := 1;
      C.SetFocus;
      if Style = csDropDown then
        Target := TComboAccess(C).Inner
      else
        Target := C;
      Target.Perform(WM_SYSKEYDOWN, VK_DOWN, $20000000); // Alt+Unten
      CheckTrue(C.DroppedDown, 'Alt+Unten oeffnet');
      CheckTrue(C.PopupList.IsOpen);
      CheckTrue(IsWindowVisible(C.PopupList.Handle), 'Popup sichtbar');
      CheckEquals(C.Handle, GetCapture, 'Combo haelt die Maus');
      CheckEquals(1, C.PopupList.Highlight, 'aktueller Eintrag hervorgehoben');
      CheckTrue(GetForegroundWindow <> C.PopupList.Handle, 'Popup wird nicht aktiviert');
      Target.Perform(WM_KEYDOWN, VK_DOWN, 0);
      CheckEquals(2, C.PopupList.Highlight);
      CheckEquals(1, C.ItemIndex, 'erst Enter uebernimmt');
      Target.Perform(WM_KEYDOWN, VK_ESCAPE, 0);
      CheckFalse(C.DroppedDown, 'Esc schliesst');
      CheckFalse(IsWindowVisible(C.PopupList.Handle));
      CheckEquals(1, C.ItemIndex, 'Esc verwirft');
      CheckTrue(GetCapture <> C.Handle, 'Maus freigegeben');

      Target.Perform(WM_KEYDOWN, VK_F4, 0);
      CheckTrue(C.DroppedDown, 'F4 oeffnet');
      Target.Perform(WM_KEYDOWN, VK_DOWN, 0);
      Target.Perform(WM_KEYDOWN, VK_RETURN, 0);
      CheckFalse(C.DroppedDown, 'Enter schliesst');
      CheckEquals(2, C.ItemIndex, 'Enter uebernimmt');
      CheckEquals('Birne', C.Text);
      C.Free;
    end;
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TComboBoxTests.SpecialKeysOnlyWhileOpen;
var
  C: TPPGComboBox;
  Inner: TWinControl;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.SetFocus;
    Inner := TComboAccess(C).Inner;
    // Geschlossen gehoeren Enter/Esc dem Formular (Default-/Cancel-Button)
    CheckEquals(0, Inner.Perform(CM_WANTSPECIALKEY, VK_ESCAPE, 0));
    CheckEquals(0, Inner.Perform(CM_WANTSPECIALKEY, VK_RETURN, 0));
    C.DroppedDown := True;
    CheckEquals(1, Inner.Perform(CM_WANTSPECIALKEY, VK_ESCAPE, 0), 'offen: Esc gehoert der Liste');
    CheckEquals(1, Inner.Perform(CM_WANTSPECIALKEY, VK_RETURN, 0));
    C.DroppedDown := False;
    C.Style := csDropDownList;
    C.SetFocus;
    C.DroppedDown := True;
    CheckEquals(1, C.Perform(CM_WANTSPECIALKEY, VK_RETURN, 0), 'auch ohne Edit');
    CheckTrue(C.Perform(WM_GETDLGCODE, 0, 0) and DLGC_WANTARROWS <> 0, 'Pfeiltasten');
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.ClickOnItemSelectsAndCloses;
var
  C: TPPGComboBox;
  Style: TComboBoxStyle;
begin
  FForm.Show;
  try
    for Style := csDropDown to csDropDownList do
    begin
      if Style = csSimple then
        Continue;
      FLog.Clear;
      C := NewCombo(Style);
      C.OnClick := LogClick;
      C.SetFocus;
      // Klick auf den Pfeil oeffnet
      ClickAt(C, CenterOf(TComboAccess(C).ButtonRect(PPGComboButtonDrop)).X, C.Height div 2);
      CheckTrue(C.DroppedDown, 'Klick auf den Pfeil oeffnet und bleibt offen');
      CheckEquals(-1, TComboAccess(C).PressedButton, 'Pfeil nicht gedrueckt haengen');
      ClickItem(C, 3);
      CheckFalse(C.DroppedDown, 'Klick auf Eintrag schliesst');
      CheckEquals(3, C.ItemIndex);
      CheckEquals('Cola', C.Text);
      CheckEquals('Click,Change', FLog.CommaText);
      C.Free;
    end;
    // csDropDownList: Klick irgendwo auf das Feld oeffnet
    C := NewCombo(csDropDownList);
    C.SetFocus;
    ClickAt(C, 20, C.Height div 2);
    CheckTrue(C.DroppedDown, 'Liste: Klick auf das Feld oeffnet');
    ClickAt(C, 20, C.Height div 2);
    CheckFalse(C.DroppedDown, 'zweiter Klick schliesst');
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TComboBoxTests.ClickOutsideCancels;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.ItemIndex := 0;
    C.OnCloseUp := LogCloseUp;
    C.SetFocus;
    C.DroppedDown := True;
    C.PopupList.MoveHighlight(2);
    C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(C.Width + 300, -200));
    CheckFalse(C.DroppedDown, 'Klick ausserhalb schliesst');
    CheckEquals(0, C.ItemIndex, 'ohne Uebernahme');
    CheckEquals('CloseUp:0', FLog.CommaText);
    C.Perform(WM_LBUTTONUP, 0, MouseLParam(C.Width + 300, -200));
    CheckFalse(C.DroppedDown);
    CheckEquals(0, FChanges);
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.FocusOrCaptureLossCancels;
var
  C: TPPGComboBox;
  B: TPPGButton;
begin
  FForm.Show;
  try
    C := NewCombo;
    B := NewButton('B');
    B.Top := 200;
    C.SetFocus;
    C.DroppedDown := True;
    B.SetFocus;
    CheckFalse(C.DroppedDown, 'Fokusverlust schliesst');
    C.SetFocus;
    C.DroppedDown := True;
    ReleaseCapture; // z.B. Dialog oder anderes Fenster holt die Maus
    CheckFalse(C.DroppedDown, 'Capture-Verlust schliesst');
    C.DroppedDown := True;
    C.Enabled := False;
    CheckFalse(C.DroppedDown, 'Deaktivieren schliesst');
    CheckFalse(C.PopupList.IsOpen);
    C.Enabled := True;
    C.DroppedDown := True;
    CheckTrue(C.DroppedDown);
    C.Visible := False;
    CheckFalse(C.DroppedDown, 'Ausblenden schliesst');
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TComboBoxTests.EventsInTComboBoxOrder;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    C.OnClick := LogClick;
    C.OnDropDown := LogDropDown;
    C.OnCloseUp := LogCloseUp;
    C.SetFocus;
    C.DroppedDown := True;
    C.PopupList.SetHighlight(2);
    C.CloseUp(True);
    CheckEquals('DropDown,Click,Change,CloseUp:2', FLog.CommaText,
      'ohne OnSelect: OnChange; OnCloseUp sieht schon den neuen ItemIndex');
    FLog.Clear;
    C.OnSelect := LogSelect;
    C.DroppedDown := True;
    C.PopupList.SetHighlight(4);
    C.CloseUp(True);
    CheckEquals('DropDown,Click,Select,CloseUp:4', FLog.CommaText,
      'mit OnSelect: kein OnChange (wie TComboBox)');
    FLog.Clear;
    C.DroppedDown := True;
    C.CloseUp(True);
    CheckEquals('DropDown,CloseUp:4', FLog.CommaText, 'gleicher Eintrag: keine Auswahl');
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.ClosedKeysSelectDirectly;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    C.SetFocus;
    C.Perform(WM_KEYDOWN, VK_DOWN, 0);
    CheckEquals(0, C.ItemIndex, 'Unten ohne Auswahl: erster Eintrag');
    CheckEquals(1, FChanges);
    C.Perform(WM_KEYDOWN, VK_DOWN, 0);
    CheckEquals(1, C.ItemIndex);
    C.Perform(WM_KEYDOWN, VK_UP, 0);
    CheckEquals(0, C.ItemIndex);
    C.Perform(WM_KEYDOWN, VK_UP, 0);
    CheckEquals(0, C.ItemIndex, 'am Anfang bleibt es');
    CheckEquals(3, FChanges, 'kein Ereignis ohne Aenderung');
    C.Perform(WM_KEYDOWN, VK_END, 0);
    CheckEquals(4, C.ItemIndex);
    C.Perform(WM_KEYDOWN, VK_HOME, 0);
    CheckEquals(0, C.ItemIndex);
    C.Perform(WM_KEYDOWN, VK_NEXT, 0);
    CheckEquals(4, C.ItemIndex, 'Bild ab: DropDownCount - 1 weiter (begrenzt)');
    CheckFalse(C.DroppedDown, 'geschlossen geblieben');
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.TypeAheadInDropDownList;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    C.SetFocus;
    C.Perform(WM_CHAR, Ord('b'), 0);
    CheckEquals(1, C.ItemIndex, 'b -> Banane');
    C.Perform(WM_CHAR, Ord('b'), 0);
    CheckEquals(2, C.ItemIndex, 'b nochmal -> Birne (blaettern)');
    C.Perform(WM_CHAR, Ord('b'), 0);
    CheckEquals(1, C.ItemIndex, 'und wieder von vorn');
    Sleep(1100);
    C.Perform(WM_CHAR, Ord('b'), 0);
    C.Perform(WM_CHAR, Ord('i'), 0);
    CheckEquals(2, C.ItemIndex, 'bi -> Birne');
    Sleep(1100);
    C.DroppedDown := True;
    C.Perform(WM_CHAR, Ord('d'), 0);
    CheckEquals(4, C.PopupList.Highlight, 'offen: nur Hervorhebung');
    CheckEquals(2, C.ItemIndex);
    C.Perform(WM_KEYDOWN, VK_RETURN, 0);
    CheckEquals(4, C.ItemIndex);
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.AutoCompleteWhileTyping;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.SetFocus;
    TypeChar(C, 'b');
    CheckEquals('Banane', C.Text, 'ergaenzt zum ersten Treffer');
    CheckEquals(1, C.SelStart);
    CheckEquals(5, C.SelLength, 'Rest markiert');
    CheckEquals(1, C.ItemIndex);
    CheckEquals(1, FChanges, 'ein OnChange pro Taste');
    TypeChar(C, 'i');
    CheckEquals('Birne', C.Text, 'Weitertippen ersetzt den Rest');
    CheckEquals(2, C.ItemIndex);
    CheckEquals(2, FChanges);
    TypeChar(C, #8);
    CheckEquals('Bi', C.Text, 'Ruecktaste ergaenzt nicht');
    CheckEquals(-1, C.ItemIndex, 'freier Text');
    C.AutoComplete := False;
    C.Text := '';
    TypeChar(C, 'c');
    CheckEquals('c', C.Text, 'ohne AutoComplete');
    C.AutoDropDown := True;
    TypeChar(C, 'o');
    CheckTrue(C.DroppedDown, 'AutoDropDown oeffnet beim Tippen');
    CheckEquals(3, C.PopupList.Highlight, 'offene Liste folgt dem Text');
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.DropDownEventMayAddItems;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.OnDropDown := AddItemsOnDropDown;
    C.DropDownCount := 20;
    C.DroppedDown := True;
    CheckEquals(6, C.Items.Count);
    CheckEquals(6, C.PopupList.VisibleRows, 'Liste kennt den neuen Eintrag');
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.SortedAndItemChangesKeepSelection;
var
  C: TPPGComboBox;
begin
  C := NewCombo(csDropDownList);
  C.Items.Text := 'c'#13#10'a'#13#10'b';
  C.ItemIndex := 0;
  C.Sorted := True;
  CheckEquals('a,b,c', C.Items.CommaText);
  CheckEquals(2, C.ItemIndex, 'Auswahl folgt dem Eintrag');
  CheckEquals('c', C.Text);
  C.Sorted := False;
  C.Items.Insert(0, 'x');
  CheckEquals(3, C.ItemIndex, 'Einfuegen davor verschiebt den Index');
  C.Items.Delete(3);
  CheckEquals(-1, C.ItemIndex, 'geloeschter Eintrag: keine Auswahl');
  CheckEquals('', C.Text);
  C.ItemIndex := 0;
  C.Clear;
  CheckEquals(0, C.Items.Count, 'Clear wie TComboBox: Eintraege weg');
  CheckEquals(-1, C.ItemIndex);
  CheckEquals(0, FChanges);
end;

procedure TComboBoxTests.ClearButtonResetsSelection;
var
  C: TPPGComboBox;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    C.ShowClearButton := True;
    C.ItemIndex := 2;
    C.SetFocus;
    CheckTrue(TComboAccess(C).ButtonVisible(PPGFieldButtonClear));
    TComboAccess(C).ButtonClick(PPGFieldButtonClear);
    CheckEquals(-1, C.ItemIndex);
    CheckEquals('', C.Text);
    CheckEquals(5, C.Items.Count, 'Eintraege bleiben');
    CheckEquals(1, FChanges, 'Leeren durch den Anwender: OnChange');
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.WheelScrollsOnlyOpenList;
var
  C: TPPGComboBox;
  I: Integer;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    for I := 1 to 30 do
      C.Items.Add('Eintrag ' + IntToStr(I));
    C.ItemIndex := 0;
    C.SetFocus;
    TComboAccess(C).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0));
    CheckEquals(0, C.ItemIndex, 'geschlossen: Rad aendert die Auswahl nicht');
    C.DroppedDown := True;
    CheckEquals(0, C.PopupList.TopIndex);
    CheckTrue(TComboAccess(C).DoMouseWheel([], -WHEEL_DELTA, Point(0, 0)));
    CheckEquals(3, C.PopupList.TopIndex, 'offen: drei Zeilen weiter');
    TComboAccess(C).DoMouseWheel([], WHEEL_DELTA, Point(0, 0));
    CheckEquals(0, C.PopupList.TopIndex);
    CheckEquals(0, C.ItemIndex);
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.PopupSizeFollowsDropDownCountAndWidth;
var
  C: TPPGComboBox;
  I: Integer;
  P: TPoint;
begin
  FForm.Show;
  try
    C := NewCombo;
    for I := 1 to 20 do
      C.Items.Add('Eintrag ' + IntToStr(I));
    C.DropDownCount := 6;
    C.DroppedDown := True;
    CheckEquals(6, C.PopupList.VisibleRows);
    CheckEquals(C.Width, C.PopupList.Width, 'mindestens so breit wie das Feld');
    P := C.ClientToScreen(Point(0, C.Height));
    CheckEquals(P.Y, C.PopupList.BoundsRect.Top, 'direkt unter dem Feld');
    CheckEquals(P.X, C.PopupList.BoundsRect.Left);
    C.DroppedDown := False;
    C.DropDownWidth := 300;
    C.DroppedDown := True;
    CheckEquals(300, C.PopupList.Width, 'DropDownWidth');
    C.DroppedDown := False;
    C.Items.Clear;
    C.DroppedDown := True;
    CheckEquals(1, C.PopupList.VisibleRows, 'leere Liste: eine Zeile hoch');
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.PopupOpensAboveWithoutRoomBelow;
var
  C: TPPGComboBox;
  WA: TRect;
  P: TPoint;
  I: Integer;
begin
  WA := Screen.MonitorFromWindow(FForm.Handle).WorkareaRect;
  FForm.SetBounds(WA.Left + 20, WA.Bottom - 110, 400, 300);
  FForm.Show;
  try
    C := NewCombo;
    for I := 1 to 10 do
      C.Items.Add('Eintrag ' + IntToStr(I));
    C.DroppedDown := True;
    P := C.ClientToScreen(Point(0, 0));
    CheckTrue(C.PopupList.OpenedAbove, 'unten kein Platz: oberhalb');
    CheckEquals(P.Y, C.PopupList.BoundsRect.Bottom, 'endet an der Oberkante des Felds');
    CheckTrue(C.PopupList.BoundsRect.Top >= WA.Top);
    // Hervorhebung und Klick funktionieren auch oberhalb
    ClickItem(C, 1);
    CheckEquals(1, C.ItemIndex);
  finally
    FForm.Hide;
    FForm.SetBounds(0, 0, 400, 300);
  end;
end;

procedure TComboBoxTests.TrackClickPagesList;
var
  C: TPPGComboBox;
  I: Integer;
  L: TPPGPopupList;
begin
  FForm.Show;
  try
    C := NewCombo;
    for I := 1 to 30 do
      C.Items.Add('Eintrag ' + IntToStr(I));
    C.DroppedDown := True;
    L := C.PopupList;
    // Unten in die Scrollleiste klicken: eine Seite weiter
    L.MouseDownAt(L.Width - 4, L.Height - 6);
    CheckEquals(-1, L.MouseUpAt(L.Width - 4, L.Height - 6), 'Scrollleiste waehlt nichts');
    CheckEquals(L.VisibleRows - 1, L.TopIndex);
    CheckTrue(C.DroppedDown);
    // Eintrag unter der Maus wird hervorgehoben
    L.MouseMoveAt(20, CenterOf(L.ItemRect(L.TopIndex + 1)).Y);
    CheckEquals(L.TopIndex + 1, L.Highlight);
  finally
    FForm.Hide;
  end;
end;

procedure TComboBoxTests.LoadsTComboBoxDfmAndRoundTrips;
const
  Dfm =
    'object Combo: TPPGComboBox'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 145'#13#10 +
    '  Height = 23'#13#10 +
    '  Style = csDropDownList'#13#10 +
    '  DropDownCount = 5'#13#10 +
    '  ItemIndex = 1'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  Text = ''Zwei'''#13#10 +
    '  Items.Strings = ('#13#10 +
    '    ''Eins'''#13#10 +
    '    ''Zwei'''#13#10 +
    '    ''Drei'')'#13#10 +
    'end'#13#10;
var
  C, C2: TPPGComboBox;
  S: string;
begin
  C := TPPGComboBox.Create(FForm);
  C.Parent := FForm;
  LoadDfm(Dfm, C);
  CheckEquals(1, C.ItemIndex, 'ItemIndex vor Items in der DFM');
  CheckEquals('Zwei', C.Text);
  CheckEquals(5, C.DropDownCount);
  CheckTrue(C.Style = csDropDownList);
  CheckFalse(TComboAccess(C).Inner.Visible);
  CheckTrue(TWinControl(C).TabStop);
  S := ComponentToText(C);
  CheckTrue(Pos('Items.Strings', S) > 0, S);
  CheckTrue(Pos('ItemIndex = 1', S) > 0, S);
  CheckTrue(Pos('Style = csDropDownList', S) > 0, S);
  C2 := TPPGComboBox.Create(FForm);
  C2.Parent := FForm;
  S := StringReplace(S, 'object Combo', 'object Combo2', []);
  LoadDfm(S, C2);
  CheckEquals(1, C2.ItemIndex);
  CheckEquals('Zwei', C2.Text);
  CheckEquals(3, C2.Items.Count);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TComboAccessibilityTests }

procedure TComboAccessibilityTests.ComboRoleAndExpandedState;
var
  C: TPPGComboBox;
  Acc: IAccessible;
  W: WideString;
begin
  FForm.Show;
  try
    C := NewCombo(csDropDownList);
    C.TextHint := 'Obst';
    C.ItemIndex := 1;
    Acc := AccOf(C);
    CheckEquals(ROLE_SYSTEM_COMBOBOX, AccRole(Acc));
    CheckTrue(AccState(Acc) and STATE_SYSTEM_COLLAPSED <> 0);
    CheckTrue(AccState(Acc) and STATE_SYSTEM_HASPOPUP <> 0);
    CheckEquals('Obst', AccName(Acc));
    CheckEquals(S_OK, Acc.Get_accValue(CHILDID_SELF, W));
    CheckEquals('Banane', string(W));
    CheckEquals(S_OK, Acc.Get_accDefaultAction(CHILDID_SELF, W));
    CheckEquals(SPPGAccOpen, string(W));
    C.DroppedDown := True;
    CheckTrue(AccState(Acc) and STATE_SYSTEM_EXPANDED <> 0);
    Acc.Get_accDefaultAction(CHILDID_SELF, W);
    CheckEquals(SPPGAccClose, string(W));
    CheckEquals(S_OK, Acc.accDoDefaultAction(CHILDID_SELF));
    CheckTrue(C.DroppedDown, 'asynchron');
    PumpPosted(C.Handle);
    CheckFalse(C.DroppedDown, 'Standardaktion schliesst');
  finally
    FForm.Hide;
  end;
end;

procedure TComboAccessibilityTests.ListExposesItemsAsChildren;
var
  C: TPPGComboBox;
  Acc: IAccessible;
  Count, Obtained, I, L, T, W, H: Integer;
  V: OleVariant;
  N: WideString;
  Children: array of OleVariant;
  P: TPoint;
  R: TRect;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.DroppedDown := True;
    Acc := AccOf(C.PopupList);
    CheckEquals(ROLE_SYSTEM_LIST, AccRole(Acc));
    CheckEquals(S_OK, Acc.Get_accChildCount(Count));
    CheckEquals(5, Count, 'ein Kind pro Eintrag');
    CheckEquals(S_OK, Acc.Get_accName(3, N));
    CheckEquals('Birne', string(N));
    CheckEquals(S_OK, Acc.Get_accRole(3, V));
    CheckEquals(ROLE_SYSTEM_LISTITEM, Integer(V));
    CheckEquals(E_INVALIDARG, Acc.Get_accName(99, N), 'ungueltige Id');

    C.PopupList.SetHighlight(2);
    CheckEquals(S_OK, Acc.Get_accState(3, V));
    CheckTrue(Integer(V) and STATE_SYSTEM_FOCUSED <> 0, 'hervorgehobener Eintrag');
    CheckEquals(S_OK, Acc.Get_accFocus(V));
    CheckEquals(3, Integer(V));

    // Lage und Hit-Test in Bildschirmkoordinaten
    CheckEquals(S_OK, Acc.accLocation(L, T, W, H, 4));
    R := C.PopupList.ItemRect(3);
    P := C.PopupList.ClientToScreen(R.TopLeft);
    CheckEquals(P.X, L);
    CheckEquals(P.Y, T);
    CheckEquals(R.Bottom - R.Top, H);
    P := C.PopupList.ClientToScreen(CenterOf(R));
    CheckEquals(S_OK, Acc.accHitTest(P.X, P.Y, V));
    CheckEquals(4, Integer(V));

    // Navigation und Aufzaehlung wie bei einer Windows-Liste
    CheckEquals(S_OK, Acc.accNavigate(NAVDIR_NEXT, 2, V));
    CheckEquals(3, Integer(V));
    CheckEquals(S_OK, Acc.accNavigate(NAVDIR_FIRSTCHILD, CHILDID_SELF, V));
    CheckEquals(1, Integer(V));
    SetLength(Children, Count);
    CheckTrue(Succeeded(PPG_AccessibleChildren(Acc, 0, Count, @Children[0], Obtained)));
    CheckEquals(Count, Obtained, 'AccessibleChildren liefert alle Eintraege');
    for I := 0 to Obtained - 1 do
      CheckEquals(I + 1, Integer(Children[I]));
  finally
    FForm.Hide;
  end;
end;

procedure TComboAccessibilityTests.ItemDefaultActionSelectsAsynchronously;
var
  C: TPPGComboBox;
  Acc: IAccessible;
  N: WideString;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.DroppedDown := True;
    Acc := AccOf(C.PopupList);
    CheckEquals(S_OK, Acc.Get_accDefaultAction(2, N));
    CheckEquals(SPPGAccSelect, string(N));
    CheckEquals(S_OK, Acc.accDoDefaultAction(2));
    CheckEquals(-1, C.ItemIndex, 'nicht im COM-Aufruf');
    PumpPosted(C.PopupList.Handle);
    CheckEquals(1, C.ItemIndex);
    CheckFalse(C.DroppedDown);
    CheckEquals(1, FChanges);
  finally
    FForm.Hide;
  end;
end;

{ TPhase4bPaintTests }

procedure TPhase4bPaintTests.ArrowRotatesWhenOpen;
var
  C: TPPGComboBox;
  A, B: TBitmap;
begin
  FForm.Show;
  try
    C := NewCombo;
    A := RenderToBitmap(C);
    try
      C.DroppedDown := True;
      CheckEquals(1.0, C.ArrowProgress, 0.001, 'ohne Animation sofort gedreht');
      B := RenderToBitmap(C);
      try
        CheckTrue(CountDiff(A, B, TComboAccess(C).ButtonRect(PPGComboButtonDrop)) > 4,
          'Pfeil zeigt geoeffnet nach oben');
      finally
        B.Free;
      end;
    finally
      A.Free;
    end;
    C.DroppedDown := False;
    CheckEquals(0.0, C.ArrowProgress, 0.001);
  finally
    FForm.Hide;
  end;
end;

procedure TPhase4bPaintTests.DropDownListPaintsItemText;
var
  C: TPPGComboBox;
  A, B: TBitmap;
  R: TRect;
begin
  C := NewCombo(csDropDownList);
  A := RenderToBitmap(C);
  try
    C.ItemIndex := 1;
    B := RenderToBitmap(C);
    try
      R := TComboAccess(C).Inner.BoundsRect;
      CheckTrue(CountDiff(A, B, R) > 10, 'Eintragstext wird gezeichnet');
    finally
      B.Free;
    end;
    C.ItemIndex := -1;
    C.TextHint := 'Bitte waehlen';
    B := RenderToBitmap(C);
    try
      CheckTrue(CountDiff(A, B, R) > 10, 'TextHint ohne Auswahl');
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4bPaintTests.ListRendererBothPresetsAndGdi;
const
  Presets: array[0..1] of string = (PPGPresetModernFlat, PPGPresetClassic);
var
  C: TPPGComboBox;
  Gdi: Boolean;
  I, Y: Integer;
  Bmp: TBitmap;
  R: TRect;
  Hl: TColor;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.ItemIndex := 0;
    for Gdi := False to True do
      for I := 0 to High(Presets) do
      begin
        TPPGRendererRegistry.ForceGdiFallback := Gdi;
        C.Preset := Presets[I];
        C.DroppedDown := True;
        C.PopupList.SetHighlight(2);
        Bmp := RenderToBitmap(C.PopupList);
        try
          R := C.PopupList.ItemRect(2);
          Y := (R.Top + R.Bottom) div 2;
          Hl := Bmp.Canvas.Pixels[R.Left + 8, Y];
          CheckTrue(Hl <> ColorToRGB(C.PopupList.ListColor),
            Presets[I] + ': Hervorhebung sichtbar');
          R := C.PopupList.ItemRect(4);
          CheckEquals(ColorToRGB(C.PopupList.ListColor),
            Bmp.Canvas.Pixels[R.Right - 6, (R.Top + R.Bottom) div 2],
            Presets[I] + ': Listenfarbe');
          // Gewaehlter Eintrag (dezent hinterlegt) muss hell bleiben - auch
          // im GDI-Fallback (Regression: Alpha wurde dort deckend gezeichnet)
          R := C.PopupList.ItemRect(0);
          CheckTrue(GetRValue(ColorToRGB(Bmp.Canvas.Pixels[R.Right - 12, R.Top + 3])) > 200,
            Presets[I] + ': gewaehlter Eintrag hell');
        finally
          Bmp.Free;
        end;
        C.DroppedDown := False;
      end;
  finally
    TPPGRendererRegistry.ForceGdiFallback := False;
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4bPaintTests.GdiCanvasBlendsAlpha;
var
  Bmp: TBitmap;
  Cv: IPPGCanvas;
  C: Cardinal;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(40, 20);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, 40, 20));
    Cv := TPPGGdiCanvas.Create(Bmp.Canvas.Handle);
    Cv.FillRoundRect(Rect(0, 0, 20, 20), 0, clBlack, 128);
    Cv.FillRoundRect(Rect(20, 0, 40, 20), 4, clBlack, 255);
    Cv := nil;
    C := ColorToRGB(Bmp.Canvas.Pixels[10, 10]);
    CheckTrue(Abs(GetRValue(C) - 127) < 6, Format('halbtransparent gemischt: %d', [GetRValue(C)]));
    CheckEquals(0, Integer(ColorToRGB(Bmp.Canvas.Pixels[30, 10])), 'deckend bleibt deckend');
    CheckEquals(Integer(clWhite), Integer(ColorToRGB(Bmp.Canvas.Pixels[20, 0])),
      'Ecke ausserhalb der Rundung unveraendert');
  finally
    Bmp.Free;
  end;
end;

procedure TPhase4bPaintTests.FreeWhileOpenIsSafe;
var
  C: TPPGComboBox;
  PopupWnd: HWND;
begin
  FForm.Show;
  try
    C := NewCombo;
    C.OnCloseUp := LogCloseUp;
    C.SetFocus;
    C.DroppedDown := True;
    PopupWnd := C.PopupList.Handle;
    C.Free;
    CheckFalse(IsWindow(PopupWnd), 'Popup-Fenster zerstoert');
    CheckEquals(0, FCloseUps, 'keine Ereignisse beim Freigeben');
    CheckTrue(GetCapture = 0, 'Maus freigegeben');
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase4bPaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    C: TPPGComboBox;
  begin
    for I := 1 to 15 do
    begin
      C := NewCombo;
      C.OnChange := nil;
      C.SetFocus;
      C.DroppedDown := True;
      RenderToBitmap(C.PopupList).Free;
      AccOf(C.PopupList);
      C.PopupList.MoveHighlight(1);
      C.CloseUp(True);
      RenderToBitmap(C).Free;
      C.Style := csDropDownList;
      C.DroppedDown := True;
      C.Free; // offen freigeben
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  FForm.Show;
  try
    Cycle;
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
    M0 := AllocatedBytes;
    Cycle;
    Cycle;
    M1 := AllocatedBytes;
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 1024, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Phase4b', TComboBoxTests.Suite);
  RegisterTest('Phase4b', TComboAccessibilityTests.Suite);
  RegisterTest('Phase4b', TPhase4bPaintTests.Suite);

end.
