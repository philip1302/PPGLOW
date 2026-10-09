unit PPG.Tests.Phase12b;

{ Tests fuer Phase 12c/d: TPPGFileEdit, Farbraum (PPG.ColorSpace),
  Aufklapp-Basis und TPPGColorPicker. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Variants, System.IOUtils, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  Vcl.ExtCtrls,
  PPG.Types, PPG.Render.Registry, PPG.Controls.Base, PPG.Controls.Field, PPG.Edit,
  PPG.FileEdit, PPG.ColorSpace, PPG.Controls.DropDown, PPG.ColorPicker, PPG.Tests.Controls;

type
  TTestFileEdit = class(TPPGFileEdit)
  public
    NextResult: string;
    DialogShown: Integer;
  protected
    function ExecuteDialog(var AFileName: string): Boolean; override;
  end;

  TFileEditTests = class(TControlTestCase)
  private
    FLog: TStringList;
    FDir: string;
    FFile: string;
    FDeny: Boolean;
    procedure Changed(Sender: TObject);
    procedure Before(Sender: TObject; var Allow: Boolean);
    procedure After(Sender: TObject; var FileName: string; var Accept: Boolean);
    function NewFileEdit: TTestFileEdit;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure BrowseSetsTextWithEvents;
    procedure BeforeAndAfterCanCancel;
    procedure DropAcceptsMatchingKind;
    procedure MustExistValidates;
    procedure CodeSetsFileNameSilently;
  end;

  TColorSpaceTests = class(TTestCase)
  published
    procedure HsvRoundTrip;
    procedure HexParsing;
  end;

  TColorPickerTests = class(TControlTestCase)
  private
    FChanges: Integer;
    FOther: TPPGEdit;
    procedure Changed(Sender: TObject);
    function NewPicker: TPPGColorPicker;
    procedure KeyTo(P: TPPGColorPicker; VK: Word; Shift: TShiftState = []);
    procedure ClickPopup(P: TPPGColorPicker; X, Y: Integer);
  protected
    procedure SetUp; override;
  published
    procedure CodeSetsSelectedSilently;
    procedure NamesAndHex;
    procedure KeyboardSelectsAndRemembers;
    procedure MouseClickSelects;
    procedure EscapeAndOutsideClickCancel;
    procedure CustomColorByHex;
    procedure RecentColorsStreamAndLimit;
    procedure AccessibilityChildren;
    procedure PickerGallery;
  end;

implementation

uses
  PPG.Tests.Visual,
  System.StrUtils, Winapi.oleacc, Vcl.Imaging.pngimage, PPG.Theme, PPG.Lang, PPG.Consts, PPG.Accessibility;

type
  TPickerAccess = class(TPPGColorPicker);
  TFileAccess = class(TPPGFileEdit);

{ TTestFileEdit }

function TTestFileEdit.ExecuteDialog(var AFileName: string): Boolean;
begin
  Inc(DialogShown);
  Result := NextResult <> '';
  if Result then
    AFileName := NextResult;
end;

{ TFileEditTests }

procedure TFileEditTests.SetUp;
begin
  inherited SetUp;
  FLog := TStringList.Create;
  FDir := TPath.Combine(TPath.GetTempPath, 'PPGFileEditTest');
  ForceDirectories(FDir);
  FFile := TPath.Combine(FDir, 'probe.txt');
  TFile.WriteAllText(FFile, 'x');
  FDeny := False;
  FForm.Show;
end;

procedure TFileEditTests.TearDown;
begin
  if FileExists(FFile) then
    DeleteFile(FFile);
  RemoveDir(FDir);
  FreeAndNil(FLog);
  inherited TearDown;
end;

procedure TFileEditTests.Changed(Sender: TObject);
begin
  FLog.Add('change');
end;

procedure TFileEditTests.Before(Sender: TObject; var Allow: Boolean);
begin
  FLog.Add('before');
  Allow := not FDeny;
end;

procedure TFileEditTests.After(Sender: TObject; var FileName: string; var Accept: Boolean);
begin
  FLog.Add('after:' + ExtractFileName(FileName));
  if FileName = 'umbenennen' then
    FileName := 'neu.txt';
end;

function TFileEditTests.NewFileEdit: TTestFileEdit;
begin
  Result := TTestFileEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 300, 32);
  Result.OnChange := Changed;
end;

procedure TFileEditTests.BrowseSetsTextWithEvents;
var
  E: TTestFileEdit;
begin
  E := NewFileEdit;
  CheckFalse(IsRectEmpty(TFileAccess(E).ButtonRect(PPGFileButtonBrowse)), 'Knopf im Feld');
  E.NextResult := FFile;
  TFileAccess(E).ButtonClick(PPGFileButtonBrowse);
  CheckEquals(1, E.DialogShown);
  CheckEquals(FFile, E.FileName);
  CheckTrue(FLog.IndexOf('change') >= 0, 'Anwender: OnChange');
  // Abbruch im Dialog: nichts aendert sich
  FLog.Clear;
  E.NextResult := '';
  CheckFalse(E.Browse);
  CheckEquals(FFile, E.FileName);
  CheckEquals(0, FLog.Count);
end;

procedure TFileEditTests.BeforeAndAfterCanCancel;
var
  E: TTestFileEdit;
begin
  E := NewFileEdit;
  E.OnBeforeDialog := Before;
  E.OnAfterDialog := After;
  FDeny := True;
  E.NextResult := FFile;
  CheckFalse(E.Browse);
  CheckEquals(0, E.DialogShown, 'OnBeforeDialog bricht ab');
  FDeny := False;
  E.NextResult := 'umbenennen';
  CheckTrue(E.Browse);
  CheckEquals('neu.txt', E.FileName, 'OnAfterDialog aendert den Namen');
end;

procedure TFileEditTests.DropAcceptsMatchingKind;
var
  E: TTestFileEdit;
begin
  E := NewFileEdit;
  E.Kind := fkFolder;
  CheckTrue(E.DropPaths([FFile, FDir]), 'Ordner aus der Liste');
  CheckEquals(FDir, E.FileName);
  E.Kind := fkOpenFile;
  CheckTrue(E.DropPaths([FDir, FFile]));
  CheckEquals(FFile, E.FileName);
  E.FileName := '';
  CheckFalse(E.DropPaths([FDir]), 'nur Ordner, aber Datei verlangt');
  CheckEquals('', E.FileName);
  E.ReadOnly := True;
  CheckFalse(E.DropPaths([FFile]), 'schreibgeschuetzt');
end;

procedure TFileEditTests.MustExistValidates;
var
  E: TTestFileEdit;
begin
  E := NewFileEdit;
  E.MustExist := True;
  CheckTrue(E.ValidatePath, 'leer ist gueltig');
  E.FileName := FFile + '.fehlt';
  CheckFalse(E.ValidatePath);
  CheckTrue(E.ValidationState = pvsError);
  CheckEquals(PPGStr(@SPPGFileNotFound), E.ValidationHint);
  E.FileName := FFile;
  CheckTrue(E.ValidatePath);
  CheckTrue(E.ValidationState = pvsNone);
  E.Kind := fkFolder;
  E.FileName := FDir + '\fehlt';
  CheckFalse(E.ValidatePath);
  CheckEquals(PPGStr(@SPPGFolderNotFound), E.ValidationHint);
  E.MustExist := False;
  CheckTrue(E.ValidationState = pvsNone, 'abgeschaltet: Fehler weg');
end;

procedure TFileEditTests.CodeSetsFileNameSilently;
var
  E: TTestFileEdit;
  FV: IPPGFieldValue;
begin
  E := NewFileEdit;
  E.FileName := 'C:\a.txt';
  CheckEquals(0, FLog.Count);
  CheckTrue(Supports(E, IPPGFieldValue, FV));
  CheckEquals('C:\a.txt', VarToStr(FV.GetFieldValue));
  FV.FieldClear;
  CheckTrue(FV.FieldIsNull);
  FV := nil;
  CheckEquals(0, FLog.Count);
end;

{ TColorSpaceTests }

procedure TColorSpaceTests.HsvRoundTrip;
var
  R, G, B: Integer;
  C, C2: TColor;
  H, S, V: Double;
begin
  R := 0;
  while R <= 255 do
  begin
    G := 0;
    while G <= 255 do
    begin
      B := 0;
      while B <= 255 do
      begin
        C := TColor(R or (G shl 8) or (B shl 16));
        PPGColorToHSV(C, H, S, V);
        C2 := PPGHSVToColor(H, S, V);
        CheckEquals(Integer(C), Integer(C2), Format('%d %d %d', [R, G, B]));
        Inc(B, 51);
      end;
      Inc(G, 17);
    end;
    Inc(R, 15);
  end;
  PPGColorToHSV(clRed, H, S, V);
  CheckEquals(0, H, 1E-9);
  CheckEquals(1, S, 1E-9);
  PPGColorToHSV(clLime, H, S, V);
  CheckEquals(120, H, 1E-9);
end;

procedure TColorSpaceTests.HexParsing;
var
  C: TColor;
begin
  CheckEquals('#FF0000', PPGColorToHex(clRed));
  CheckEquals('#0000FF', PPGColorToHex(clBlue));
  CheckTrue(PPGTryHexToColor('#abc', C));
  CheckEquals(Integer($CCBBAA), Integer(C));
  CheckTrue(PPGTryHexToColor('1A2B3C', C));
  CheckEquals(Integer($3C2B1A), Integer(C));
  CheckFalse(PPGTryHexToColor('#12345', C));
  CheckFalse(PPGTryHexToColor('#GGGGGG', C));
  CheckFalse(PPGTryHexToColor('', C));
end;

{ TColorPickerTests }

procedure TColorPickerTests.SetUp;
begin
  inherited SetUp;
  FChanges := 0;
  FOther := TPPGEdit.Create(FForm);
  FOther.Parent := FForm;
  FOther.SetBounds(10, 250, 100, 32);
  FForm.SetBounds(100, 100, 500, 400);
  FForm.Show;
end;

procedure TColorPickerTests.Changed(Sender: TObject);
begin
  Inc(FChanges);
end;

function TColorPickerTests.NewPicker: TPPGColorPicker;
begin
  Result := TPPGColorPicker.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(10, 10, 220, 32);
  Result.OnChange := Changed;
  Result.Animation.Enabled := False; // Klicks treffen das fertige Popup
end;

procedure TColorPickerTests.KeyTo(P: TPPGColorPicker; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TPickerAccess(P).KeyDown(K, Shift);
end;

procedure TColorPickerTests.ClickPopup(P: TPPGColorPicker; X, Y: Integer);
var
  Pt: TPoint;
begin
  // Popup-Koordinaten -> Feld-Koordinaten (das Feld haelt die Maus)
  Pt := P.ScreenToClient(P.Popup.ClientToScreen(Point(X, Y)));
  P.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Word(Pt.X), Word(Pt.Y)));
  P.Perform(WM_LBUTTONUP, 0, MakeLParam(Word(Pt.X), Word(Pt.Y)));
end;

procedure TColorPickerTests.CodeSetsSelectedSilently;
var
  P: TPPGColorPicker;
begin
  P := NewPicker;
  P.Selected := clRed;
  P.Selected := clNone;
  CheckEquals(0, FChanges);
  CheckEquals(0, P.RecentCount, 'Code fuellt "zuletzt benutzt" nicht');
end;

procedure TColorPickerTests.NamesAndHex;
var
  P: TPPGColorPicker;
begin
  P := NewPicker;
  CheckEquals('Red', P.ColorName(clRed));
  CheckEquals('#123456', P.ColorName(TColor($563412)));
  CheckEquals(PPGStr(@SPPGColorNone), P.ColorName(clNone));
  CheckEquals(PPGStr(@SPPGColorDefault), P.ColorName(clDefault));
  P.Style := P.Style - [cbPrettyNames];
  CheckEquals('clRed', P.ColorName(clRed));
  P.ShowHex := True;
  CheckEquals('#FF0000', P.ColorName(clRed));
end;

procedure TColorPickerTests.KeyboardSelectsAndRemembers;
var
  P: TPPGColorPicker;
  Pop: TPPGColorPopup;
  Start: Integer;
begin
  P := NewPicker;
  P.Selected := clBlack;
  P.SetFocus;
  KeyTo(P, VK_DOWN, [ssAlt]);
  CheckTrue(P.DroppedDown, 'Alt+Pfeil runter klappt auf');
  Pop := TPPGColorPopup(P.Popup);
  Start := Pop.FocusIndex;
  CheckEquals(clBlack, Pop.Cell(Start).Color, 'Fokus auf der aktuellen Farbe');
  KeyTo(P, VK_RIGHT);
  CheckEquals(Start + 1, Pop.FocusIndex);
  KeyTo(P, VK_DOWN);
  CheckTrue(Pop.FocusIndex <> Start + 1, 'Pfeil runter: naechste Zeile');
  KeyTo(P, VK_UP);
  CheckEquals(Start + 1, Pop.FocusIndex, 'zurueck in dieselbe Spalte');
  KeyTo(P, VK_RETURN);
  CheckFalse(P.DroppedDown);
  CheckEquals(clMaroon, P.Selected);
  CheckEquals(1, FChanges);
  CheckEquals(1, P.RecentCount);
  CheckEquals(clMaroon, P.RecentColor(0));
  // Leertaste oeffnet ebenfalls
  KeyTo(P, VK_SPACE);
  CheckTrue(P.DroppedDown);
  P.CloseUp(False);
end;

procedure TColorPickerTests.MouseClickSelects;
var
  P: TPPGColorPicker;
  Pop: TPPGColorPopup;
  I: Integer;
  R: TRect;
begin
  P := NewPicker;
  P.SetFocus;
  P.DropDown;
  Pop := TPPGColorPopup(P.Popup);
  I := Pop.IndexOfColor(clRed);
  CheckTrue(I >= 0);
  R := Pop.Cell(I).Rect;
  ClickPopup(P, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  CheckFalse(P.DroppedDown);
  CheckEquals(clRed, P.Selected);
  CheckEquals(1, FChanges);
end;

procedure TColorPickerTests.EscapeAndOutsideClickCancel;
var
  P: TPPGColorPicker;
begin
  P := NewPicker;
  P.Selected := clBlue;
  P.SetFocus;
  P.DropDown;
  KeyTo(P, VK_RIGHT);
  KeyTo(P, VK_ESCAPE);
  CheckFalse(P.DroppedDown);
  CheckEquals(clBlue, P.Selected, 'Esc verwirft');
  P.DropDown;
  P.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MakeLParam(Word(-300), Word(-300)));
  CheckFalse(P.DroppedDown, 'Klick ausserhalb');
  P.DropDown;
  FOther.SetFocus;
  Application.ProcessMessages;
  CheckFalse(P.DroppedDown, 'Fokusverlust');
  CheckEquals(0, FChanges);
end;

procedure TColorPickerTests.CustomColorByHex;
var
  P: TPPGColorPicker;
  Pop: TPPGColorPopup;
  I: Integer;
  Ch: Char;
  S: string;
  R: TRect;
begin
  P := NewPicker;
  P.SetFocus;
  P.DropDown;
  Pop := TPPGColorPopup(P.Popup);
  // "Weitere Farben..." ist die letzte breite Zeile
  I := Pop.CellCount - 1;
  CheckTrue(Pop.Cell(I).Kind = cckMore);
  R := Pop.Cell(I).Rect;
  ClickPopup(P, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  CheckTrue(P.DroppedDown, 'bleibt offen');
  CheckTrue(Pop.CustomMode);
  S := 'FF8800';
  for I := 1 to Length(S) do
  begin
    Ch := S[I];
    TPickerAccess(P).KeyPress(Ch);
  end;
  CheckEquals('FF8800', Pop.HexText);
  KeyTo(P, VK_RETURN);
  CheckFalse(P.DroppedDown);
  CheckEquals(Integer($0088FF), Integer(P.Selected));
  CheckEquals(1, FChanges);
end;

procedure TColorPickerTests.RecentColorsStreamAndLimit;
var
  P, P2: TPPGColorPicker;
  MS: TMemoryStream;
  I: Integer;
begin
  P := NewPicker;
  P.MaxRecent := 3;
  for I := 1 to 5 do
    P.SelectColor(TColor(I * $10));
  CheckEquals(3, P.RecentCount);
  CheckEquals(Integer($50), Integer(P.RecentColor(0)), 'neueste zuerst');
  P.SelectColor(TColor($30));
  CheckEquals(Integer($30), Integer(P.RecentColor(0)), 'ohne Doppelte nach vorn');
  CheckEquals(3, P.RecentCount);
  P.SelectColor(clHighlight);
  CheckEquals(clHighlight, P.RecentColor(0), 'Systemfarbe bleibt Systemfarbe');
  MS := TMemoryStream.Create;
  P2 := TPPGColorPicker.Create(nil);
  try
    MS.WriteComponent(P);
    MS.Position := 0;
    MS.ReadComponent(P2);
    CheckEquals(3, P2.MaxRecent);
    CheckEquals(P.RecentColors.Text, P2.RecentColors.Text);
    CheckEquals(clHighlight, P2.Selected);
  finally
    P2.Free;
    MS.Free;
  end;
end;

procedure TColorPickerTests.AccessibilityChildren;
var
  P: TPPGColorPicker;
  AC: IPPGAccessibleChildren;
  I: Integer;
begin
  P := NewPicker;
  P.Selected := clRed;
  CheckEquals('Red', TPickerAccess(P).AccValue);
  CheckEquals(ROLE_SYSTEM_COMBOBOX, TPickerAccess(P).AccRole);
  P.SetFocus;
  P.DropDown;
  CheckTrue(TPickerAccess(P).AccState and STATE_SYSTEM_EXPANDED <> 0);
  CheckTrue(Supports(P.Popup, IPPGAccessibleChildren, AC));
  I := TPPGColorPopup(P.Popup).IndexOfColor(clRed);
  CheckEquals('Red', AC.AccChildName(I + 1));
  CheckTrue(AC.AccChildState(I + 1) and STATE_SYSTEM_SELECTED <> 0);
  CheckEquals(I + 1, AC.AccSelectedChild);
  AC := nil;
  P.CloseUp(False);
end;

procedure TColorPickerTests.PickerGallery;
var
  Names: TStringList;
  Pn, Row: Integer;
  Dark, Custom: Boolean;
  P: TPPGColorPicker;
  Sheet, B: TBitmap;
  Png: TPngImage;
  Dir: string;
  X: Integer;
begin
  Names := TStringList.Create;
  Sheet := TBitmap.Create;
  try
    P := NewPicker;
    P.Style := P.Style + [cbIncludeNone, cbIncludeDefault];
    P.SelectColor(TColor($2266AA));
    P.Selected := clRed;
    TPPGRendererRegistry.GetNames(Names);
    Sheet.PixelFormat := pf24bit;
    Sheet.SetSize(800, Names.Count * 2 * 480);
    Sheet.Canvas.Brush.Color := clWhite;
    Sheet.Canvas.FillRect(Rect(0, 0, Sheet.Width, Sheet.Height));
    Row := 0;
    P.SetFocus;
    for Pn := 0 to Names.Count - 1 do
      for Dark := False to True do
      begin
        if Dark then
          TPPGTheme.Mode := tmDark
        else
          TPPGTheme.Mode := tmLight;
        P.Preset := Names[Pn];
        Sheet.Canvas.TextOut(4, Row * 480, Names[Pn] + IfThen(Dark, ' dunkel', ' hell'));
        B := RenderToBitmap(P);
        try
          PPGCheckPainted(Self, B, Names[Pn] + ' Picker'); // Audit 11b
          Sheet.Canvas.Draw(10, Row * 480 + 18, B);
        finally
          B.Free;
        end;
        X := 250;
        for Custom := False to True do
        begin
          P.DropDown;
          TPPGColorPopup(P.Popup).SetCustomMode(Custom);
          B := RenderToBitmap(P.Popup);
          try
            PPGCheckPainted(Self, B, Names[Pn] + ' Popup'); // Audit 11b
            Sheet.Canvas.Draw(X, Row * 480 + 18, B);
            Inc(X, B.Width + 20);
          finally
            B.Free;
          end;
          P.CloseUp(False);
        end;
        Inc(Row);
      end;
    TPPGTheme.Mode := tmLight;
    Dir := ExtractFilePath(ParamStr(0)) + 'Visual\Gallery\';
    ForceDirectories(Dir);
    Png := TPngImage.Create;
    try
      Png.Assign(Sheet);
      Png.SaveToFile(Dir + 'ColorPicker.png');
    finally
      Png.Free;
    end;
    // Audit 11b: Zustaende sichtbar anders als Normal (GDI+ und GDI)
    PPGCheckStates(Self, P, 'ColorPicker', True, True, True, Point(P.Width div 2, P.Height div 2));
    CheckEquals(0, FErrors.Count, FErrors.Text);
  finally
    Sheet.Free;
    Names.Free;
  end;
end;

initialization
  RegisterTest('Phase12b', TFileEditTests.Suite);
  RegisterTest('Phase12b', TColorSpaceTests.Suite);
  RegisterTest('Phase12b', TColorPickerTests.Suite);

end.
