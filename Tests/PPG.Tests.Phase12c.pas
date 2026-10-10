unit PPG.Tests.Phase12c;

{ Tests fuer Phase 12e/f: TPPGCheckComboBox, TPPGColumnComboBox, TPPGTagEdit. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  PPG.Types, PPG.Render.Registry, PPG.Controls.Base, PPG.Controls.Field, PPG.Edit,
  PPG.Controls.DropDown, PPG.RowPopup, PPG.CheckComboBox, PPG.ColumnComboBox, PPG.TagEdit,
  PPG.Accessibility, PPG.Tests.Controls, PPG.Exceptions;

type
  TDropTestCase = class(TControlTestCase)
  protected
    FLog: TStringList;
    FOther: TPPGEdit;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure Changed(Sender: TObject);
    procedure KeyTo(C: TWinControl; VK: Word; Shift: TShiftState = []);
    procedure CharTo(C: TWinControl; Ch: Char);
  end;

  TCheckComboTests = class(TDropTestCase)
  private
    FDeleteOnCheck: Boolean;
    procedure ItemCheck(Sender: TObject; Index: Integer);
    function NewCombo: TPPGCheckComboBox;
  published
    procedure ChecksFollowItems;
    procedure ItemsChangeWhileOpen;
    procedure SpaceTogglesAndStaysOpen;
    procedure DisplayModes;
    procedure SelectAllRow;
    procedure FilterRow;
    procedure CodeChecksSilently;
    procedure StreamingKeepsChecks;
    procedure AccessibilityCheckedState;
  end;

  TColumnComboTests = class(TDropTestCase)
  private
    procedure GetCell(Sender: TObject; Row, Column: Integer; var Text: string);
    function NewCombo: TPPGColumnComboBox;
  published
    procedure CellsKeyAndDisplay;
    procedure ClosedArrowsAndTypeAhead;
    procedure PopupSortsByHeader;
    procedure EnterAcceptsFocusedRow;
    procedure VirtualRowsAreFast;
    procedure StreamingColumns;
  end;

  TTagEditTests = class(TDropTestCase)
  private
    FDeny: string;
    procedure TagAdding(Sender: TObject; var Tag: string; var Allow: Boolean);
    procedure TagRemoved(Sender: TObject; const Tag: string);
    function NewTags: TPPGTagEdit;
    procedure TypeText(T: TPPGTagEdit; const S: string);
  published
    procedure DelimiterAndEnterAddTags;
    procedure PasteCreatesSeveralTags;
    procedure DuplicatesAndMaxTags;
    procedure AddingCanChangeOrDeny;
    procedure BackspaceSelectsThenDeletes;
    procedure ArrowsWalkChips;
    procedure WrapsAndGrows;
    procedure SuggestionsWhileTyping;
    procedure OnlySuggestionsWhenNotAllowNew;
    procedure CodeSetsTagsSilently;
    procedure ManyTagsLayoutFast;
    procedure AccessibilityChildren;
    procedure PostedRemoveIgnoresChangedTags;
  end;

  TFieldsGalleryTests = class(TDropTestCase)
  published
    procedure FieldsGallery;
  end;

implementation

uses
  PPG.Tests.Visual,
  System.StrUtils, Winapi.oleacc, Vcl.Imaging.pngimage, PPG.Lang, PPG.Consts, PPG.Theme,
  PPG.NumberFormat, PPG.NumberEdit, PPG.MaskEdit, PPG.PasswordEdit, PPG.FileEdit;

type
  TCheckAccess = class(TPPGCheckComboBox);
  TColumnAccess = class(TPPGColumnComboBox);
  TTagAccess = class(TPPGTagEdit);
  TCtrlCrack = class(TPPGCustomControl);
  TCheckPopupAccess = class(TPPGCheckListPopup);
  TSuggestAccess = class(TPPGTagSuggestPopup);

{ TDropTestCase }

procedure TDropTestCase.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FOther := TPPGEdit.Create(FForm);
  FOther.Parent := FForm;
  FOther.SetBounds(10, 300, 100, 32);
  FForm.SetBounds(100, 100, 600, 420);
  FForm.Show;
end;

procedure TDropTestCase.TearDown;
begin
  FreeAndNil(FLog);
  inherited TearDown;
end;

procedure TDropTestCase.Changed(Sender: TObject);
begin
  FLog.Add('change');
end;

procedure TDropTestCase.KeyTo(C: TWinControl; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  if C is TPPGTagEdit then
    TTagAccess(C).FieldKeyDown(K, Shift)
  else
    TCheckAccess(C).KeyDown(K, Shift);
end;

procedure TDropTestCase.CharTo(C: TWinControl; Ch: Char);
var
  K: Char;
begin
  K := Ch;
  TCheckAccess(C).KeyPress(K);
end;

{ TCheckComboTests }

procedure TCheckComboTests.ItemCheck(Sender: TObject; Index: Integer);
begin
  FLog.Add('check:' + IntToStr(Index));
  if FDeleteOnCheck then
    TPPGCheckComboBox(Sender).Items.Delete(Index);
end;

function TCheckComboTests.NewCombo: TPPGCheckComboBox;
begin
  Result := TPPGCheckComboBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 260, 32);
  Result.Animation.Enabled := False;
  Result.Items.CommaText := 'Rot,Gruen,Blau,Gelb';
  Result.OnChange := Changed;
  Result.OnItemCheck := ItemCheck;
  FDeleteOnCheck := False;
end;

procedure TCheckComboTests.ChecksFollowItems;
var
  C: TPPGCheckComboBox;
begin
  // Audit 08.10.2026: Die Haken hingen am Index und sassen nach Insert,
  // Delete oder Sortieren auf anderen Eintraegen.
  C := NewCombo; // Rot,Gruen,Blau,Gelb
  C.CheckedText := 'Blau';
  C.Items.Insert(0, 'Weiss');
  CheckTrue(C.Checked[3], 'Blau jetzt an Index 3');
  CheckFalse(C.Checked[2]);
  CheckEquals('Blau', C.CheckedText);
  C.Items.Delete(0);
  C.Items.Delete(0);
  CheckEquals('Blau', C.CheckedText, 'nach Delete');
  CheckTrue(C.Checked[1]);
  TStringList(C.Items).Sort; // Blau,Gelb,Gruen
  CheckEquals('Blau', C.CheckedText, 'nach Sort');
  CheckTrue(C.Checked[0]);
  C.Items.BeginUpdate;
  try
    C.Items.Add('Lila');
    C.Items.Delete(1);
  finally
    C.Items.EndUpdate;
  end;
  CheckEquals('Blau', C.CheckedText, 'mehrere Aenderungen in einer Klammer');
  CheckEquals(1, C.CheckedCount);
end;

procedure TCheckComboTests.ItemsChangeWhileOpen;
var
  C: TPPGCheckComboBox;
  P: TPPGCheckListPopup;
begin
  // Audit 08.10.2026: OnItemCheck loescht den Eintrag bei offener Liste; die
  // Zeilen-Zuordnung blieb stehen und Paint griff ueber das Ende hinaus.
  C := NewCombo;
  C.SetFocus;
  C.DropDown;
  P := TPPGCheckListPopup(C.Popup);
  CheckEquals(4, TCheckPopupAccess(P).RowCount);
  FDeleteOnCheck := True;
  KeyTo(C, VK_SPACE); // hakt "Rot" an, der Handler loescht ihn
  FDeleteOnCheck := False;
  CheckEquals(3, C.Items.Count);
  CheckEquals(3, TCheckPopupAccess(P).RowCount, 'Zuordnung neu aufgebaut');
  CheckEquals(2, P.ItemOfRow(2));
  CheckEquals(-2, P.ItemOfRow(3));
  P.Repaint;
  CheckEquals(0, C.CheckedCount);
  C.CloseUp(False);
end;

procedure TCheckComboTests.SpaceTogglesAndStaysOpen;
var
  C: TPPGCheckComboBox;
begin
  C := NewCombo;
  C.SetFocus;
  KeyTo(C, VK_SPACE);
  CheckTrue(C.DroppedDown, 'Leertaste klappt auf');
  KeyTo(C, VK_SPACE);
  CheckTrue(C.Checked[0]);
  CheckTrue(C.DroppedDown, 'bleibt beim Anhaken offen');
  KeyTo(C, VK_DOWN);
  KeyTo(C, VK_DOWN);
  KeyTo(C, VK_SPACE);
  CheckTrue(C.Checked[2]);
  CheckEquals('check:0,change,check:2,change', FLog.CommaText);
  KeyTo(C, VK_RETURN);
  CheckFalse(C.DroppedDown, 'Enter schliesst');
  CheckEquals('Rot;Blau', C.CheckedText);
end;

procedure TCheckComboTests.DisplayModes;
var
  C: TPPGCheckComboBox;
begin
  C := NewCombo;
  CheckEquals('', C.DisplayText);
  C.CheckedText := 'Rot;Gruen;Blau';
  CheckEquals('Rot, Gruen, +1', C.DisplayText);
  C.DisplayMode := cdmList;
  CheckEquals('Rot, Gruen, Blau', C.DisplayText);
  C.DisplayMode := cdmCount;
  CheckEquals(Format(PPGStr(@SPPGCheckedCount), [3]), C.DisplayText);
end;

procedure TCheckComboTests.SelectAllRow;
var
  C: TPPGCheckComboBox;
  P: TPPGCheckListPopup;
begin
  C := NewCombo;
  C.ShowSelectAll := True;
  C.SetFocus;
  C.DropDown;
  P := TPPGCheckListPopup(C.Popup);
  CheckEquals(-1, P.ItemOfRow(0), 'erste Zeile = Alle');
  KeyTo(C, VK_SPACE);
  CheckTrue(C.AllChecked);
  CheckEquals('change', FLog.CommaText, 'ein OnChange');
  KeyTo(C, VK_SPACE);
  CheckEquals(0, C.CheckedCount);
  C.CloseUp(False);
end;

procedure TCheckComboTests.FilterRow;
var
  C: TPPGCheckComboBox;
  P: TPPGCheckListPopup;
begin
  C := NewCombo;
  C.FilterThreshold := 3;
  C.SetFocus;
  C.DropDown;
  P := TPPGCheckListPopup(C.Popup);
  CheckTrue(P.FilterEnabled);
  CharTo(C, 'b');
  CharTo(C, 'l');
  CheckEquals('bl', P.Filter);
  CheckEquals(1, TCheckPopupAccess(P).RowCount, 'nur "Blau"');
  CheckEquals(2, P.ItemOfRow(0));
  KeyTo(C, VK_SPACE);
  CheckTrue(C.Checked[2]);
  KeyTo(C, VK_BACK);
  KeyTo(C, VK_BACK);
  CheckEquals(4, TCheckPopupAccess(P).RowCount);
  C.CloseUp(False);
end;

procedure TCheckComboTests.CodeChecksSilently;
var
  C: TPPGCheckComboBox;
begin
  C := NewCombo;
  C.Checked[1] := True;
  C.CheckAll(True);
  C.CheckedText := 'Gelb';
  CheckEquals(0, FLog.Count);
  CheckEquals('Gelb', C.CheckedText);
  CheckTrue(C.Checked[3]);
  try
    C.Checked[9] := True;
    Fail('Index ausserhalb');
  except
    // Audit 11a #4: konkrete Klasse (vorher galt jede Exception ausser
    // ETestFailure als Erfolg, auch eine Zugriffsverletzung)
    on EPPGError do
      ;
  end;
end;

procedure TCheckComboTests.StreamingKeepsChecks;
var
  C, C2: TPPGCheckComboBox;
  MS: TMemoryStream;
begin
  C := NewCombo;
  C.CheckedText := 'Gruen;Gelb';
  C.ShowSelectAll := True;
  C.DisplayMode := cdmList;
  MS := TMemoryStream.Create;
  C2 := TPPGCheckComboBox.Create(nil);
  try
    MS.WriteComponent(C);
    MS.Position := 0;
    MS.ReadComponent(C2);
    CheckEquals('Gruen;Gelb', C2.CheckedText, 'Haken nach den Items geladen');
    CheckTrue(C2.ShowSelectAll);
    CheckTrue(C2.DisplayMode = cdmList);
  finally
    C2.Free;
    MS.Free;
  end;
end;

procedure TCheckComboTests.AccessibilityCheckedState;
var
  C: TPPGCheckComboBox;
  AC: IPPGAccessibleChildren;
begin
  C := NewCombo;
  C.CheckedText := 'Blau';
  C.SetFocus;
  C.DropDown;
  CheckTrue(Supports(C.Popup, IPPGAccessibleChildren, AC));
  CheckEquals('Blau', AC.AccChildName(3));
  CheckEquals(ROLE_SYSTEM_CHECKBUTTON, AC.AccChildRole(3));
  CheckTrue(AC.AccChildState(3) and STATE_SYSTEM_CHECKED <> 0);
  CheckFalse(AC.AccChildState(1) and STATE_SYSTEM_CHECKED <> 0);
  AC := nil;
  C.CloseUp(False);
  CheckEquals('Blau', TCheckAccess(C).AccValue);
end;

{ TColumnComboTests }

procedure TColumnComboTests.GetCell(Sender: TObject; Row, Column: Integer; var Text: string);
begin
  if Column = 0 then
    Text := IntToStr(100000 + Row)
  else
    Text := 'Kunde ' + IntToStr(Row);
end;

function TColumnComboTests.NewCombo: TPPGColumnComboBox;
begin
  Result := TPPGColumnComboBox.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 260, 32);
  Result.Animation.Enabled := False;
  with Result.Columns.Add do
  begin
    Title := 'Nr';
    Width := 60;
  end;
  with Result.Columns.Add do
  begin
    Title := 'Name';
    Width := 140;
  end;
  with Result.Columns.Add do
  begin
    Title := 'Ort';
    Width := 100;
  end;
  Result.Items.Add('1003|Mueller|Berlin');
  Result.Items.Add('1001|Albers|Hamburg');
  Result.Items.Add('1002|Zander|Koeln');
  Result.DisplayColumn := 1;
  Result.OnChange := Changed;
end;

procedure TColumnComboTests.CellsKeyAndDisplay;
var
  C: TPPGColumnComboBox;
begin
  C := NewCombo;
  CheckEquals('Albers', C.CellText(1, 1));
  CheckEquals('', C.CellText(1, 7));
  C.KeyValue := '1002';
  CheckEquals(2, C.ItemIndex);
  CheckEquals('Zander', C.DisplayText);
  C.KeyValue := 'gibt es nicht';
  CheckEquals(-1, C.ItemIndex);
  CheckEquals(0, FLog.Count, 'Code ohne OnChange');
end;

procedure TColumnComboTests.ClosedArrowsAndTypeAhead;
var
  C: TPPGColumnComboBox;
begin
  C := NewCombo;
  C.SetFocus;
  KeyTo(C, VK_DOWN);
  CheckEquals(0, C.ItemIndex);
  KeyTo(C, VK_DOWN);
  CheckEquals(1, C.ItemIndex);
  CheckEquals(2, FLog.Count);
  CharTo(C, 'z');
  CheckEquals(2, C.ItemIndex, 'Tippsuche in der Anzeigespalte');
  CheckEquals(0, C.FindRow('mu', 0));
  CheckEquals(0, C.FindRow('MU', 0), 'ohne Gross-/Kleinschreibung');
  CheckEquals(-1, C.FindRow('xy', 0));
end;

procedure TColumnComboTests.PopupSortsByHeader;
var
  C: TPPGColumnComboBox;
  P: TPPGColumnPopup;
begin
  C := NewCombo;
  C.ItemIndex := 1;
  C.SetFocus;
  C.DropDown;
  P := TPPGColumnPopup(C.Popup);
  CheckEquals(0, P.TopRow, 'erstes Oeffnen: nicht weggescrollt');
  CheckEquals(1, P.FocusRow);
  CheckTrue(P.HeaderHeight > 0, 'Kopfzeile');
  P.SortBy(1, True);
  CheckEquals(1, P.DataRow(0), 'Albers zuerst');
  CheckEquals(2, P.DataRow(2), 'Zander zuletzt');
  P.SortBy(1, False);
  CheckEquals(2, P.DataRow(0));
  P.SortBy(0, True);
  CheckEquals(1, P.DataRow(0), '1001');
  CheckEquals('1003|Mueller|Berlin', C.Items[0], 'Daten unveraendert');
  C.CloseUp(False);
end;

procedure TColumnComboTests.EnterAcceptsFocusedRow;
var
  C: TPPGColumnComboBox;
begin
  C := NewCombo;
  C.SetFocus;
  KeyTo(C, VK_DOWN, [ssAlt]);
  CheckTrue(C.DroppedDown);
  KeyTo(C, VK_DOWN);
  KeyTo(C, VK_RETURN);
  CheckFalse(C.DroppedDown);
  CheckEquals(1, C.ItemIndex);
  CheckEquals('change', FLog.CommaText);
  CheckEquals('1001', C.KeyValue);
end;

procedure TColumnComboTests.VirtualRowsAreFast;
var
  C: TPPGColumnComboBox;
begin
  // Audit 11a #7: Laufzeit im Benchmark (Bench11, vorher 1000 ms im Test)
  C := NewCombo;
  C.OnGetCellText := GetCell;
  C.VirtualRowCount := 100000;
  CheckEquals(100000, C.RowCount);
  CheckEquals('Kunde 99999', C.CellText(99999, 1));
  C.SetFocus;
  C.DropDown;
  KeyTo(C, VK_END);
  CheckEquals(99999, TPPGColumnPopup(C.Popup).FocusRow);
  C.CloseUp(False);
end;

procedure TColumnComboTests.StreamingColumns;
var
  C, C2: TPPGColumnComboBox;
  MS: TMemoryStream;
begin
  C := NewCombo;
  C.Columns[2].Alignment := taRightJustify;
  C.KeyColumn := 0;
  C.DropDownWidth := 320;
  MS := TMemoryStream.Create;
  C2 := TPPGColumnComboBox.Create(nil);
  try
    MS.WriteComponent(C);
    MS.Position := 0;
    MS.ReadComponent(C2);
    CheckEquals(3, C2.Columns.Count);
    CheckEquals('Name', C2.Columns[1].Title);
    CheckEquals(140, C2.Columns[1].Width);
    CheckTrue(C2.Columns[2].Alignment = taRightJustify);
    CheckEquals(3, C2.Items.Count);
    CheckEquals(1, C2.DisplayColumn);
    CheckEquals(320, C2.DropDownWidth);
  finally
    C2.Free;
    MS.Free;
  end;
end;

{ TTagEditTests }

procedure TTagEditTests.TagAdding(Sender: TObject; var Tag: string; var Allow: Boolean);
begin
  FLog.Add('adding:' + Tag);
  if Tag = FDeny then
    Allow := False;
  if Tag = 'klein' then
    Tag := 'KLEIN';
end;

procedure TTagEditTests.TagRemoved(Sender: TObject; const Tag: string);
begin
  FLog.Add('removed:' + Tag);
end;

function TTagEditTests.NewTags: TPPGTagEdit;
begin
  Result := TPPGTagEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 300, 32);
  Result.Animation.Enabled := False;
  Result.OnChange := Changed;
end;

procedure TTagEditTests.TypeText(T: TPPGTagEdit; const S: string);
var
  I: Integer;
begin
  for I := 1 to Length(S) do
    T.Controls[0].Perform(WM_CHAR, Ord(S[I]), 0);
end;

procedure TTagEditTests.DelimiterAndEnterAddTags;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  T.SetFocus;
  TypeText(T, 'Delphi;');
  CheckEquals('Delphi', T.TagsText);
  CheckEquals('', T.Text, 'Eingabe geleert');
  TypeText(T, 'VCL');
  CheckEquals(1, FLog.Count, 'ein OnChange fuer Delphi');
  KeyTo(T, VK_RETURN);
  CheckEquals('Delphi;VCL', T.TagsText);
  TypeText(T, 'Rest');
  FOther.SetFocus;
  Application.ProcessMessages;
  CheckEquals('Delphi;VCL;Rest', T.TagsText, 'beim Verlassen uebernommen');
  CheckEquals(3, FLog.Count);
end;

procedure TTagEditTests.PasteCreatesSeveralTags;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  T.SetFocus;
  T.SelText := 'a; b ; c';
  CheckEquals('a;b;c', T.TagsText);
  CheckEquals('', T.Text);
end;

procedure TTagEditTests.DuplicatesAndMaxTags;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  CheckTrue(T.AddTag('Eins'));
  CheckFalse(T.AddTag('eins'), 'ohne Doppelte, ohne Gross-/Kleinschreibung');
  T.CaseSensitive := True;
  CheckTrue(T.AddTag('eins'));
  T.MaxTags := 3;
  CheckTrue(T.AddTag('Drei'));
  CheckFalse(T.AddTag('Vier'), 'MaxTags');
  CheckEquals(3, T.Tags.Count);
  CheckFalse(T.AddTag('   '), 'leer');
end;

procedure TTagEditTests.AddingCanChangeOrDeny;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  T.OnTagAdding := TagAdding;
  FDeny := 'boese';
  CheckFalse(T.AddTag('boese'));
  CheckTrue(T.AddTag('klein'));
  CheckEquals('KLEIN', T.TagsText);
  // Abgelehnte Eingabe bleibt zum Korrigieren stehen
  T.SetFocus;
  TypeText(T, 'boese');
  KeyTo(T, VK_RETURN);
  CheckEquals('boese', T.Text);
end;

procedure TTagEditTests.BackspaceSelectsThenDeletes;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  T.OnTagRemoved := TagRemoved;
  T.TagsText := 'a;b;c';
  T.SetFocus;
  KeyTo(T, VK_BACK);
  CheckEquals(2, T.SelectedTag, 'erst markieren');
  CheckEquals(3, T.Tags.Count);
  KeyTo(T, VK_BACK);
  CheckEquals('a;b', T.TagsText, 'dann loeschen');
  CheckEquals('removed:c', FLog[0]);
  CheckEquals(-1, T.SelectedTag);
end;

procedure TTagEditTests.ArrowsWalkChips;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  T.OnTagRemoved := TagRemoved;
  T.TagsText := 'a;b;c';
  T.SetFocus;
  KeyTo(T, VK_LEFT);
  CheckEquals(2, T.SelectedTag);
  KeyTo(T, VK_LEFT);
  CheckEquals(1, T.SelectedTag);
  KeyTo(T, VK_DELETE);
  CheckEquals('a;c', T.TagsText);
  T.SelectedTag := 0;
  KeyTo(T, VK_RIGHT);
  CheckEquals(1, T.SelectedTag);
  KeyTo(T, VK_RIGHT);
  CheckEquals(-1, T.SelectedTag, 'zurueck in die Eingabe');
end;

procedure TTagEditTests.WrapsAndGrows;
var
  T: TPPGTagEdit;
  H1, I: Integer;
begin
  T := NewTags;
  T.TagsText := 'eins';
  H1 := T.Height;
  CheckEquals(1, T.LineCount, Format('W=%d Chip=%d..%d Inner=%d', [T.Width, T.ChipRect(0).Left, T.ChipRect(0).Right, T.Controls[0].Left]));
  for I := 1 to 12 do
    T.Tags.Add('Stichwort' + IntToStr(I));
  CheckTrue(T.LineCount > 1, 'umgebrochen');
  CheckTrue(T.Height > H1, 'AutoSize: hoeher');
  // Kein Chip ragt rechts hinaus, keine Ueberlappung
  for I := 0 to T.Tags.Count - 1 do
    CheckTrue(T.ChipRect(I).Right <= T.Width, 'innerhalb');
  CheckTrue(T.ChipRect(1).Left >= T.ChipRect(0).Right);
end;

procedure TTagEditTests.SuggestionsWhileTyping;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  T.Suggestions.CommaText := 'Berlin,Bern,Bonn,Hamburg';
  T.TagsText := 'Bonn';
  T.SetFocus;
  TypeText(T, 'be');
  CheckTrue(T.DroppedDown, 'Vorschlaege beim Tippen');
  CheckEquals(2, TSuggestAccess(T.Popup).RowCount, 'Berlin, Bern (Bonn ist schon da)');
  KeyTo(T, VK_DOWN);
  KeyTo(T, VK_DOWN);
  KeyTo(T, VK_RETURN);
  CheckEquals('Bonn;Bern', T.TagsText);
  CheckEquals('', T.Text);
end;

procedure TTagEditTests.OnlySuggestionsWhenNotAllowNew;
var
  T: TPPGTagEdit;
begin
  T := NewTags;
  T.Suggestions.CommaText := 'Rot,Gruen';
  T.AllowNew := False;
  CheckFalse(T.AddTag('Lila'));
  CheckTrue(T.AddTag('Rot'));
end;

procedure TTagEditTests.CodeSetsTagsSilently;
var
  T: TPPGTagEdit;
  FV: IPPGFieldValue;
begin
  T := NewTags;
  T.Tags.Add('x');
  T.TagsText := 'a;b';
  CheckTrue(Supports(T, IPPGFieldValue, FV));
  FV.SetFieldValue('p;q;r');
  CheckEquals(3, T.Tags.Count);
  CheckEquals('p;q;r', VarToStr(FV.GetFieldValue));
  FV.FieldClear;
  CheckTrue(FV.FieldIsNull);
  FV := nil;
  CheckEquals(0, FLog.Count);
end;

procedure TTagEditTests.ManyTagsLayoutFast;
var
  T: TPPGTagEdit;
  I: Integer;
  B: TBitmap;
begin
  // Audit 11a #7: Laufzeit im Benchmark (Bench11, vorher 1500 ms im Test)
  T := NewTags;
  T.Width := 500;
  T.Tags.BeginUpdate;
  try
    for I := 1 to 500 do
      T.Tags.Add('Tag' + IntToStr(I));
  finally
    T.Tags.EndUpdate;
  end;
  B := RenderToBitmap(T);
  B.Free;
  CheckEquals(500, T.Tags.Count);
end;

procedure TTagEditTests.AccessibilityChildren;
var
  T: TPPGTagEdit;
  AC: IPPGAccessibleChildren;
begin
  T := NewTags;
  T.OnTagRemoved := TagRemoved;
  T.TagsText := 'a;b';
  CheckTrue(Supports(T, IPPGAccessibleChildren, AC));
  CheckEquals(2, AC.AccChildCount);
  CheckEquals('b', AC.AccChildName(2));
  CheckEquals(PPGStr(@SPPGAccRemove), AC.AccChildDefaultAction(1));
  AC.AccChildDoDefault(1);
  CheckEquals(2, T.Tags.Count, 'nicht im COM-Aufruf');
  Application.ProcessMessages;
  CheckEquals('b', T.TagsText);
  AC := nil;
end;

procedure TTagEditTests.PostedRemoveIgnoresChangedTags;
var
  T: TPPGTagEdit;
  AC: IPPGAccessibleChildren;
begin
  // Audit 08.10.2026: Die gepostete Entfernen-Aktion trug nur den Index;
  // aenderten sich die Tags bis zur Verarbeitung, traf sie einen anderen Tag.
  T := NewTags;
  T.TagsText := 'a;b;c';
  CheckTrue(Supports(T, IPPGAccessibleChildren, AC));
  AC.AccChildDoDefault(1);
  T.Tags.Insert(0, 'x');
  Application.ProcessMessages;
  CheckEquals('x;a;b;c', T.TagsText, 'veraltete Aktion verworfen');
  // Unveraendert: wirkt wie bisher
  AC.AccChildDoDefault(2);
  Application.ProcessMessages;
  CheckEquals('x;b;c', T.TagsText);
  AC := nil;
end;

{ TFieldsGalleryTests }

procedure TFieldsGalleryTests.FieldsGallery;
var
  Names: TStringList;
  P, Row, I, Y: Integer;
  Dark: Boolean;
  Sheet, B: TBitmap;
  Png: TPngImage;
  Dir: string;
  Num: TPPGNumberEdit;
  Mask: TPPGMaskEdit;
  Pwd: TPPGPasswordEdit;
  Fil: TPPGFileEdit;
  Chk: TPPGCheckComboBox;
  Col: TPPGColumnComboBox;
  Tag: TPPGTagEdit;
  Ctl: array[0..6] of TWinControl;
begin
  Names := TStringList.Create;
  Sheet := TBitmap.Create;
  try
    Num := TPPGNumberEdit.Create(FForm);
    Num.Parent := FForm;
    Num.Kind := nkCurrency;
    Num.ShowSpinButtons := True;
    Num.Value := 1234.5;
    Mask := TPPGMaskEdit.Create(FForm);
    Mask.Parent := FForm;
    Mask.EditMask := '!(999) 000-0000;1;_';
    Mask.Text := '(089) 123-4567';
    Pwd := TPPGPasswordEdit.Create(FForm);
    Pwd.Parent := FForm;
    Pwd.Text := 'geheim';
    Fil := TPPGFileEdit.Create(FForm);
    Fil.Parent := FForm;
    Fil.FileName := 'C:\Daten\Bericht.docx';
    Chk := TPPGCheckComboBox.Create(FForm);
    Chk.Parent := FForm;
    Chk.Animation.Enabled := False;
    Chk.Items.CommaText := 'Rot,Gruen,Blau,Gelb,Lila';
    Chk.ShowSelectAll := True;
    Chk.CheckedText := 'Rot;Blau;Gelb';
    Col := TPPGColumnComboBox.Create(FForm);
    Col.Parent := FForm;
    Col.Animation.Enabled := False;
    Col.Columns.Add.Title := 'Nr';
    Col.Columns[0].Width := 60;
    Col.Columns.Add.Title := 'Name';
    Col.Columns.Add.Title := 'Ort';
    Col.Items.Add('1001|Albers|Hamburg');
    Col.Items.Add('1002|Mueller|Berlin');
    Col.Items.Add('1003|Zander|Koeln');
    Col.DisplayColumn := 1;
    Col.ItemIndex := 1;
    Tag := TPPGTagEdit.Create(FForm);
    Tag.Parent := FForm;
    Tag.TagsText := 'Delphi;VCL;Windows 11;Fluent';
    Ctl[0] := Num;
    Ctl[1] := Mask;
    Ctl[2] := Pwd;
    Ctl[3] := Fil;
    Ctl[4] := Chk;
    Ctl[5] := Col;
    Ctl[6] := Tag;
    for I := 0 to High(Ctl) do
      Ctl[I].SetBounds(10, 10 + I * 40, 260, 32);
    TPPGRendererRegistry.GetNames(Names);
    Sheet.PixelFormat := pf24bit;
    Sheet.SetSize(900, Names.Count * 2 * 420);
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    Row := 0;
    for P := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        for I := 0 to High(Ctl) do
          TCtrlCrack(Ctl[I]).Preset := Names[P];
        Sheet.Canvas.TextOut(4, Row * 420, Names[P] + IfThen(Dark, ' dunkel', ' hell'));
        Y := Row * 420 + 18;
        for I := 0 to High(Ctl) do
        begin
          B := RenderToBitmap(Ctl[I]);
          try
            PPGCheckPainted(Self, B, Names[P] + ' ' + Ctl[I].ClassName); // Audit 11b
            Sheet.Canvas.Draw(10, Y, B);
            Inc(Y, B.Height + 8);
          finally
            B.Free;
          end;
        end;
        // Offene Popups daneben
        Chk.SetFocus;
        Chk.DropDown;
        B := RenderToBitmap(Chk.Popup);
        try
          PPGCheckPainted(Self, B, Names[P] + ' CheckCombo-Popup'); // Audit 11b
          Sheet.Canvas.Draw(300, Row * 420 + 18, B);
        finally
          B.Free;
        end;
        Chk.CloseUp(False);
        Col.SetFocus;
        Col.DropDown;
        B := RenderToBitmap(Col.Popup);
        try
          PPGCheckPainted(Self, B, Names[P] + ' ColumnCombo-Popup'); // Audit 11b
          Sheet.Canvas.Draw(560, Row * 420 + 18, B);
        finally
          B.Free;
        end;
        Col.CloseUp(False);
        Inc(Row);
      end;
    TPPGTheme.Mode := tmLight;
    Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
    ForceDirectories(Dir);
    Png := TPngImage.Create;
    try
      Png.Assign(Sheet);
      Png.SaveToFile(Dir + 'Fields12.png');
    finally
      Png.Free;
    end;
    // Audit 11b: Zustaende sichtbar anders als Normal (GDI+ und GDI)
    FForm.Show;
    for I := 0 to High(Ctl) do
    begin
      TCtrlCrack(Ctl[I]).Preset := PPGPresetModernFlat;
      PPGCheckStates(Self, Ctl[I], Ctl[I].ClassName, True, True, True, Point(100, 16));
    end;
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Sheet.Free;
    Names.Free;
  end;
end;

initialization
  RegisterTest('Phase12c', TCheckComboTests.Suite);
  RegisterTest('Phase12c', TColumnComboTests.Suite);
  RegisterTest('Phase12c', TTagEditTests.Suite);
  RegisterTest('Phase12c', TFieldsGalleryTests.Suite);

end.
