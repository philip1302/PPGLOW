unit PPG.Tests.Inventur;

{ Tests fuer die Inventur-Controls: Controls, die eine Inventur verlangt hat (VCL-Kompatibilitaet
  fuer Migrationen).
  - TPPGShape: Ersatz fuer TShape (DFM, alle Formen, Antialiasing, Theme).
  - TPPGDBText: Ersatz fuer TDBText (Anzeige, Scrollen, NullText, DisplayFormat).
  - TPPGDBToggleSwitch: Schalter an einem Ja/Nein-Feld (Boolean und Werteliste). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.UITypes, System.Variants, Vcl.StdCtrls, Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.ExtCtrls,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Shape, PPG.Labels, PPG.ToggleSwitch, PPG.DB.Controls, PPG.Tests.Controls;

type
  TShapeTests = class(TControlTestCase)
  private
    function NewShape(AType: TShapeType): TPPGShape;
    function PaintShape(S: TPPGShape): TBitmap;
    function Loaded(const Dfm: string): TPPGShape;
  published
    procedure DefaultsLikeTShape;
    procedure LoadsTShapeDfm;
    procedure StreamsOnlyWhatIsNeeded;
    procedure PaintsAllShapesGdiPlusAndGdi;
    procedure CornersOfRoundAndEllipseStayEmpty;
    procedure SquareAndCircleAreCentered;
    procedure ClassicPathForDashedPen;
    procedure ClearStyleDrawsNothing;
    procedure DarkModeMapsDefaultColorsOnly;
    procedure ThemeColorsCanBeSwitchedOff;
    procedure ThemeChangeRepaints;
  end;

  TDBTestCase = class(TControlTestCase)
  protected
    FData: TClientDataSet;
    FSource: TDataSource;
    procedure SetUp; override;
  end;

  TDBTextTests = class(TDBTestCase)
  private
    function NewText: TPPGDBText;
    function Shown(T: TPPGDBText): string;
  published
    procedure LoadsTDBTextDfm;
    procedure CaptionIsNotStored;
    procedure ShowsFieldAndFollowsScroll;
    procedure FollowsEditsOfTheField;
    procedure NullTextAndDisplayFormat;
    procedure InactiveDataSetShowsNothing;
    procedure DataSourceFreedDetaches;
    procedure TextColorFollowsDarkMode;
    procedure PaintsText;
  end;

  TDBToggleSwitchTests = class(TDBTestCase)
  private
    function NewSwitch(const Field: string): TPPGDBToggleSwitch;
  published
    procedure BooleanFieldShowsAndScrolls;
    procedure ClickWritesBooleanField;
    procedure ValueListShowsAndWrites;
    procedure NullIsGrayedAndClickChecks;
    procedure ReadOnlyKeepsField;
    procedure EscapeRestoresField;
    procedure StreamsValuesAndNotChecked;
    procedure LoadsDfmWithValues;
    procedure PaintsBothStates;
  end;

implementation

uses
  System.TypInfo, PPG.Theme, PPG.Types, PPG.Render.Registry;

type
  TDBTextCrack = class(TPPGDBText);

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

procedure LoadFromDfm(C: TComponent; const Dfm: string);
var
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(C);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

/// Zeichnet ein grafisches Control auf weissem Grund (wie das Elternfenster).
function PaintGraphic(C: TGraphicControl): TBitmap;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.SetSize(C.Width, C.Height);
    Result.Canvas.Brush.Color := clWhite;
    Result.Canvas.FillRect(Rect(0, 0, C.Width, C.Height));
    Result.Canvas.Lock;
    try
      C.Perform(WM_PAINT, WPARAM(Result.Canvas.Handle), 0);
    finally
      Result.Canvas.Unlock;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function RgbOf(C: TColor; Shift: Integer): Integer;
begin
  Result := (Integer(ColorToRGB(C)) shr Shift) and $FF;
end;

function Lum(C: TColor): Integer;
begin
  Result := (RgbOf(C, 0) + RgbOf(C, 8) + RgbOf(C, 16)) div 3;
end;

function Near(A, B: TColor; Tol: Integer = 6): Boolean;
begin
  Result := (Abs(RgbOf(A, 0) - RgbOf(B, 0)) <= Tol) and (Abs(RgbOf(A, 8) - RgbOf(B, 8)) <= Tol) and
    (Abs(RgbOf(A, 16) - RgbOf(B, 16)) <= Tol);
end;

{ TShapeTests }

function TShapeTests.NewShape(AType: TShapeType): TPPGShape;
begin
  Result := TPPGShape.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 65, 65);
  Result.Shape := AType;
  Result.Brush.Color := clRed;
  Result.Pen.Color := clBlue;
end;

function TShapeTests.PaintShape(S: TPPGShape): TBitmap;
begin
  Result := PaintGraphic(S);
end;

function TShapeTests.Loaded(const Dfm: string): TPPGShape;
begin
  Result := TPPGShape.Create(FForm);
  LoadFromDfm(Result, Dfm);
  Result.Parent := FForm;
end;

procedure TShapeTests.DefaultsLikeTShape;
var
  S: TPPGShape;
  V: TShape;
begin
  S := TPPGShape.Create(FForm);
  V := TShape.Create(FForm);
  CheckEquals(V.Width, S.Width, 'Width');
  CheckEquals(V.Height, S.Height, 'Height');
  CheckTrue(S.Shape = V.Shape, 'Shape');
  CheckEquals(Integer(V.Brush.Color), Integer(S.Brush.Color), 'Brush.Color');
  CheckEquals(Integer(V.Pen.Color), Integer(S.Pen.Color), 'Pen.Color');
  CheckEquals(V.Pen.Width, S.Pen.Width, 'Pen.Width');
  CheckTrue(S.ThemeColors);
end;

procedure TShapeTests.LoadsTShapeDfm;
const
  Dfm =
    'object Shape1: TPPGShape'#13#10 +
    '  Left = 12'#13#10 +
    '  Top = 20'#13#10 +
    '  Width = 80'#13#10 +
    '  Height = 40'#13#10 +
    '  Anchors = [akLeft, akTop, akRight]'#13#10 +
    '  Brush.Color = clYellow'#13#10 +
    '  Pen.Color = clGreen'#13#10 +
    '  Pen.Width = 3'#13#10 +
    '  Pen.Style = psDash'#13#10 +
    '  Shape = stRoundRect'#13#10 +
    'end';
var
  S: TPPGShape;
begin
  S := Loaded(Dfm);
  CheckEquals(12, S.Left);
  CheckEquals(80, S.Width);
  CheckTrue(S.Shape = stRoundRect);
  CheckEquals(Integer(clYellow), Integer(S.Brush.Color));
  CheckEquals(Integer(clGreen), Integer(S.Pen.Color));
  CheckEquals(3, S.Pen.Width);
  CheckTrue(S.Pen.Style = psDash);
  CheckTrue(S.Anchors = [akLeft, akTop, akRight]);
end;

procedure TShapeTests.StreamsOnlyWhatIsNeeded;
var
  S, B: TPPGShape;
  T: string;
begin
  S := TPPGShape.Create(FForm);
  T := ComponentToText(S);
  CheckTrue(Pos('Shape =', T) = 0, 'Vorgabe-Form wird nicht gespeichert: ' + T);
  CheckTrue(Pos('Brush', T) = 0, 'Vorgabe-Pinsel wird nicht gespeichert');
  CheckTrue(Pos('ThemeColors', T) = 0, 'ThemeColors-Vorgabe wird nicht gespeichert');
  S.Shape := stCircle;
  S.ThemeColors := False;
  S.Brush.Color := clLime;
  B := TPPGShape.Create(FForm);
  LoadFromDfm(B, ComponentToText(S));
  CheckTrue(B.Shape = stCircle);
  CheckFalse(B.ThemeColors);
  CheckEquals(Integer(clLime), Integer(B.Brush.Color));
end;

procedure TShapeTests.PaintsAllShapesGdiPlusAndGdi;
var
  T: TShapeType;
  Gdi: Boolean;
  S: TPPGShape;
  Bmp: TBitmap;
begin
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    for T := Low(TShapeType) to High(TShapeType) do
    begin
      S := NewShape(T);
      Bmp := PaintShape(S);
      try
        CheckTrue(Near(Bmp.Canvas.Pixels[32, 32], clRed),
          Format('Mitte rot, Form %d, GDI %d', [Ord(T), Ord(Gdi)]));
      finally
        Bmp.Free;
      end;
      S.Free;
    end;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TShapeTests.CornersOfRoundAndEllipseStayEmpty;
var
  T: TShapeType;
  Gdi: Boolean;
  S: TPPGShape;
  Bmp: TBitmap;
begin
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    for T in [stRoundRect, stRoundSquare, stEllipse, stCircle] do
    begin
      S := NewShape(T);
      Bmp := PaintShape(S);
      try
        CheckTrue(Near(Bmp.Canvas.Pixels[0, 0], clWhite),
          Format('Ecke leer, Form %d, GDI %d', [Ord(T), Ord(Gdi)]));
      finally
        Bmp.Free;
      end;
      S.Free;
    end;
    // Rechteck: der Rand liegt am Rand des Controls
    S := NewShape(stRectangle);
    Bmp := PaintShape(S);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[0, 32], clBlue, 40),
        Format('Rechteck: Rand am linken Rand, GDI %d, Pixel %x', [Ord(Gdi), Integer(Bmp.Canvas.Pixels[0, 32])]));
      CheckTrue(Near(Bmp.Canvas.Pixels[3, 3], clRed),
        Format('Rechteck: Fuellung innen, GDI %d, Pixel %x', [Ord(Gdi), Integer(Bmp.Canvas.Pixels[3, 3])]));
    finally
      Bmp.Free;
    end;
    S.Free;
  end;
end;

procedure TShapeTests.SquareAndCircleAreCentered;
var
  S: TPPGShape;
  Bmp: TBitmap;
  R: TRect;
begin
  S := NewShape(stSquare);
  S.SetBounds(0, 0, 100, 40);
  R := S.ShapeRect;
  CheckEquals(40, R.Right - R.Left);
  CheckEquals(30, R.Left);
  Bmp := PaintShape(S);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[50, 20], clRed), 'Mitte gefuellt');
    CheckTrue(Near(Bmp.Canvas.Pixels[10, 20], clWhite), 'links neben dem Quadrat leer');
    CheckTrue(Near(Bmp.Canvas.Pixels[90, 20], clWhite), 'rechts neben dem Quadrat leer');
  finally
    Bmp.Free;
  end;
  S.Shape := stCircle;
  R := S.ShapeRect;
  CheckEquals(40, R.Bottom - R.Top);
end;

procedure TShapeTests.ClassicPathForDashedPen;
var
  S: TPPGShape;
  Bmp: TBitmap;
begin
  S := NewShape(stEllipse);
  S.Pen.Style := psDash;
  Bmp := PaintShape(S);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[32, 32], clRed), 'gestrichelter Stift: Mitte gefuellt');
    CheckTrue(Near(Bmp.Canvas.Pixels[1, 1], clWhite), 'gestrichelter Stift: Ecke leer');
  finally
    Bmp.Free;
  end;
  S.Pen.Style := psSolid;
  S.Brush.Style := bsDiagCross;
  Bmp := PaintShape(S);
  Bmp.Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TShapeTests.ClearStyleDrawsNothing;
var
  S: TPPGShape;
  Bmp: TBitmap;
begin
  S := NewShape(stRectangle);
  S.Brush.Style := bsClear;
  S.Pen.Style := psClear;
  Bmp := PaintShape(S);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[32, 32], clWhite), 'ohne Pinsel keine Fuellung');
    CheckTrue(Near(Bmp.Canvas.Pixels[0, 0], clWhite), 'ohne Stift kein Rand');
  finally
    Bmp.Free;
  end;
end;

procedure TShapeTests.DarkModeMapsDefaultColorsOnly;
var
  S, E: TPPGShape;
  Bmp: TBitmap;
begin
  S := TPPGShape.Create(FForm);
  S.Parent := FForm;
  S.SetBounds(0, 0, 65, 65);
  E := NewShape(stRectangle);
  TPPGTheme.Mode := tmLight;
  CheckEquals(Integer(clWhite), Integer(S.EffectiveBrushColor), 'hell: Vorgabe wie TShape');
  CheckEquals(Integer(clBlack), Integer(S.EffectivePenColor));
  TPPGTheme.Mode := tmDark;
  CheckTrue(Lum(S.EffectiveBrushColor) < 100, 'dunkel: Vorgabe-Flaeche dunkel');
  CheckTrue(Lum(S.EffectivePenColor) > 60, 'dunkel: Vorgabe-Rand sichtbar');
  CheckEquals(Integer(clRed), Integer(E.EffectiveBrushColor), 'eigene Fuellfarbe bleibt');
  CheckEquals(Integer(clBlue), Integer(E.EffectivePenColor), 'eigene Randfarbe bleibt');
  Bmp := PaintShape(S);
  try
    CheckTrue(Lum(Bmp.Canvas.Pixels[32, 32]) < 100, 'dunkel gezeichnet');
  finally
    Bmp.Free;
  end;
end;

procedure TShapeTests.ThemeColorsCanBeSwitchedOff;
var
  S: TPPGShape;
begin
  S := TPPGShape.Create(FForm);
  S.ThemeColors := False;
  TPPGTheme.Mode := tmDark;
  CheckEquals(Integer(clWhite), Integer(S.EffectiveBrushColor));
  CheckEquals(Integer(clBlack), Integer(S.EffectivePenColor));
end;

procedure TShapeTests.ThemeChangeRepaints;
var
  S: TPPGShape;
  Before, After: TBitmap;
begin
  S := TPPGShape.Create(FForm);
  S.Parent := FForm;
  S.SetBounds(0, 0, 65, 65);
  TPPGTheme.Mode := tmLight;
  Before := PaintShape(S);
  try
    TPPGTheme.Mode := tmDark;
    After := PaintShape(S);
    try
      CheckTrue(Lum(Before.Canvas.Pixels[32, 32]) > Lum(After.Canvas.Pixels[32, 32]) + 100,
        'Theme-Wechsel aendert die Darstellung');
    finally
      After.Free;
    end;
  finally
    Before.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TDBTestCase }

procedure TDBTestCase.SetUp;
begin
  inherited SetUp;
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 20);
  FData.FieldDefs.Add('Active', ftBoolean);
  FData.FieldDefs.Add('Flag', ftString, 4);
  FData.FieldDefs.Add('Amount', ftFloat);
  FData.FieldDefs.Add('Born', ftDate);
  FData.CreateDataSet;
  FData.AppendRecord([1, 'Anna', True, 'J', 3.14159, EncodeDate(2020, 1, 2)]);
  FData.AppendRecord([2, 'Bernd', False, 'Nein', 2.5, EncodeDate(2021, 3, 4)]);
  FData.AppendRecord([3, 'Carla', Null, Null, Null, Null]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

{ TDBTextTests }

function TDBTextTests.NewText: TPPGDBText;
begin
  Result := TPPGDBText.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 160, 24);
  Result.DataSource := FSource;
  Result.DataField := 'Name';
end;

function TDBTextTests.Shown(T: TPPGDBText): string;
begin
  Result := TDBTextCrack(T).GetLabelText;
end;

procedure TDBTextTests.LoadsTDBTextDfm;
const
  Dfm =
    'object DBText1: TPPGDBText'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 121'#13#10 +
    '  Height = 17'#13#10 +
    '  Alignment = taCenter'#13#10 +
    '  AutoSize = True'#13#10 +
    '  Color = clYellow'#13#10 +
    '  DataField = ''Name'''#13#10 +
    '  Font.Charset = DEFAULT_CHARSET'#13#10 +
    '  Font.Color = clWindowText'#13#10 +
    '  Font.Height = -11'#13#10 +
    '  Font.Name = ''Tahoma'''#13#10 +
    '  Font.Style = [fsBold]'#13#10 +
    '  Layout = tlCenter'#13#10 +
    '  ParentColor = False'#13#10 +
    '  ParentFont = False'#13#10 +
    '  ShowAccelChar = True'#13#10 +
    '  Transparent = False'#13#10 +
    '  WordWrap = True'#13#10 +
    'end';
var
  T: TPPGDBText;
begin
  T := TPPGDBText.Create(FForm);
  LoadFromDfm(T, Dfm);
  T.Parent := FForm;
  T.DataSource := FSource;
  CheckEquals('Name', T.DataField);
  CheckTrue(T.Alignment = taCenter);
  CheckTrue(T.AutoSize);
  CheckTrue(T.Layout = tlCenter);
  CheckTrue(T.WordWrap);
  CheckFalse(T.Transparent);
  CheckTrue(T.ShowAccelChar);
  CheckEquals(Integer(clYellow), Integer(T.Color));
  CheckTrue(fsBold in T.Font.Style);
  CheckEquals('Anna', Shown(T));
  // Vorgaben wie TDBText: kein AutoSize, keine Zugriffstasten
  T := TPPGDBText.Create(FForm);
  CheckFalse(T.AutoSize);
  CheckFalse(T.ShowAccelChar);
end;

procedure TDBTextTests.CaptionIsNotStored;
var
  T: TPPGDBText;
  S: string;
begin
  T := NewText;
  T.NullText := '-';
  S := ComponentToText(T);
  CheckTrue(Pos('Caption', S) = 0, 'Caption nicht gespeichert: ' + S);
  CheckTrue(Pos('DataField = ''Name''', S) > 0);
  CheckTrue(Pos('NullText', S) > 0);
  CheckTrue(Pos('ShowAccelChar', S) = 0, 'Vorgabe False nicht gespeichert');
end;

procedure TDBTextTests.ShowsFieldAndFollowsScroll;
var
  T: TPPGDBText;
begin
  T := NewText;
  CheckEquals('Anna', Shown(T));
  FData.Next;
  CheckEquals('Bernd', Shown(T));
  FData.Last;
  CheckEquals('Carla', Shown(T));
  CheckTrue(T.Field = FData.FieldByName('Name'));
  // DisplayText des Feldes gilt (hier: Boolean-Feld mit eigener Anzeige)
  T.DataField := 'Active';
  FData.First;
  CheckEquals(FData.FieldByName('Active').DisplayText, Shown(T));
  // Anzeige wird auch gezeichnet
  T.DataField := 'Name';
  CheckEquals('Anna', Shown(T));
  CheckEquals('', T.Caption, 'Caption bleibt leer');
end;

procedure TDBTextTests.FollowsEditsOfTheField;
var
  T: TPPGDBText;
begin
  T := NewText;
  FData.Edit;
  FData.FieldByName('Name').AsString := 'Anja';
  CheckEquals('Anja', Shown(T), 'Aenderung im Feld sichtbar');
  FData.Cancel;
  CheckEquals('Anna', Shown(T), 'Abbrechen stellt den Wert wieder her');
end;

procedure TDBTextTests.NullTextAndDisplayFormat;
var
  T: TPPGDBText;
begin
  T := NewText;
  T.DataField := 'Flag';
  FData.Last;
  CheckEquals('', Shown(T), 'leeres Feld ohne NullText');
  T.NullText := 'offen';
  CheckEquals('offen', Shown(T));
  FData.First;
  CheckEquals('J', Shown(T), 'NullText nur bei leerem Feld');
  // DisplayFormat fuer Zahl und Datum (sprachunabhaengige Formate)
  T.DataField := 'Amount';
  T.DisplayFormat := '000';
  CheckEquals('003', Shown(T));
  FData.Next;
  CheckEquals('003', Shown(T), '2,5 rundet auf 3');
  FData.Last;
  CheckEquals('offen', Shown(T), 'leer: NullText vor DisplayFormat');
  T.DataField := 'Born';
  T.DisplayFormat := 'yyyy"/"mm"/"dd';
  FData.First;
  CheckEquals('2020/01/02', Shown(T));
  // Text-Feld: DisplayFormat gilt nicht
  T.DataField := 'Name';
  CheckEquals('Anna', Shown(T));
  T.DisplayFormat := '';
  T.DataField := 'Born';
  CheckEquals(FData.FieldByName('Born').DisplayText, Shown(T));
end;

procedure TDBTextTests.InactiveDataSetShowsNothing;
var
  T: TPPGDBText;
begin
  T := NewText;
  FData.Close;
  CheckEquals('', Shown(T));
  FData.Open;
  CheckEquals('Anna', Shown(T), 'nach dem Oeffnen wieder da');
  T.DataSource := nil;
  CheckEquals('', Shown(T));
  T.DataField := '';
  CheckEquals('', Shown(T));
end;

procedure TDBTextTests.DataSourceFreedDetaches;
var
  T: TPPGDBText;
  DS: TDataSource;
begin
  DS := TDataSource.Create(FForm);
  DS.DataSet := FData;
  T := NewText;
  T.DataSource := DS;
  DS.Free;
  CheckTrue(T.DataSource = nil);
  CheckEquals('', Shown(T));
end;

procedure TDBTextTests.TextColorFollowsDarkMode;
var
  T: TPPGDBText;
  Light, Dark: TColor;
begin
  T := NewText;
  TPPGTheme.Mode := tmLight;
  Light := T.TextColor;
  TPPGTheme.Mode := tmDark;
  Dark := T.TextColor;
  CheckTrue(Lum(Dark) > Lum(Light) + 100, 'Dark Mode: heller Text');
end;

procedure TDBTextTests.PaintsText;
var
  T: TPPGDBText;
  Bmp: TBitmap;
  X, Y, Dark: Integer;
begin
  T := NewText;
  T.Font.Size := 12;
  Bmp := PaintGraphic(T);
  try
    Dark := 0;
    for Y := 0 to Bmp.Height - 1 do
      for X := 0 to Bmp.Width - 1 do
        if Lum(Bmp.Canvas.Pixels[X, Y]) < 128 then
          Inc(Dark);
    CheckTrue(Dark > 20, 'Text gezeichnet');
  finally
    Bmp.Free;
  end;
  FData.Next;
  Bmp := PaintGraphic(T);
  Bmp.Free;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

{ TDBToggleSwitchTests }

function TDBToggleSwitchTests.NewSwitch(const Field: string): TPPGDBToggleSwitch;
begin
  Result := TPPGDBToggleSwitch.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 120, 28);
  Result.Animation.Enabled := False;
  Result.DataSource := FSource;
  Result.DataField := Field;
end;

procedure TDBToggleSwitchTests.BooleanFieldShowsAndScrolls;
var
  S: TPPGDBToggleSwitch;
begin
  S := NewSwitch('Active');
  CheckTrue(S.State = cbChecked, 'Anna: an');
  CheckTrue(S.Checked);
  FData.Next;
  CheckTrue(S.State = cbUnchecked, 'Bernd: aus');
  CheckFalse(S.Checked);
  FData.Next;
  CheckTrue(S.State = cbGrayed, 'Carla: leer');
end;

procedure TDBToggleSwitchTests.ClickWritesBooleanField;
var
  S: TPPGDBToggleSwitch;
begin
  S := NewSwitch('Active');
  FData.Next;
  S.Click;
  CheckTrue(FData.State = dsEdit, 'Satz im Bearbeiten-Modus');
  CheckTrue(S.Checked);
  FData.Post;
  CheckTrue(FData.FieldByName('Active').AsBoolean, 'ins Feld geschrieben');
  S.Click;
  FData.Post;
  CheckFalse(FData.FieldByName('Active').AsBoolean);
end;

procedure TDBToggleSwitchTests.ValueListShowsAndWrites;
var
  S: TPPGDBToggleSwitch;
begin
  S := NewSwitch('Flag');
  S.ValueChecked := 'J;Ja';
  S.ValueUnchecked := 'N;Nein';
  CheckTrue(S.State = cbChecked, 'J: an');
  FData.Next;
  CheckTrue(S.State = cbUnchecked, 'Nein: aus (zweiter Wert der Liste)');
  S.Click;
  FData.Post;
  CheckEquals('J', FData.FieldByName('Flag').AsString, 'der erste Wert wird geschrieben');
  S.Click;
  FData.Post;
  CheckEquals('N', FData.FieldByName('Flag').AsString);
end;

procedure TDBToggleSwitchTests.NullIsGrayedAndClickChecks;
var
  S: TPPGDBToggleSwitch;
begin
  S := NewSwitch('Active');
  FData.Last;
  CheckTrue(S.State = cbGrayed);
  CheckFalse(S.Checked);
  S.Click;
  CheckTrue(S.State = cbChecked, 'aus "leer" wird an');
  FData.Post;
  CheckTrue(FData.FieldByName('Active').AsBoolean);
end;

procedure TDBToggleSwitchTests.ReadOnlyKeepsField;
var
  S: TPPGDBToggleSwitch;
begin
  S := NewSwitch('Active');
  S.ReadOnly := True;
  S.Click;
  CheckTrue(S.Checked, 'unveraendert');
  CheckTrue(FData.State = dsBrowse, 'kein Bearbeiten-Modus');
  CheckTrue(FData.FieldByName('Active').AsBoolean);
  S.ReadOnly := False;
  S.DataSource := nil;
  S.Click;
  CheckTrue(FData.State = dsBrowse, 'ohne Datenquelle nichts schreiben');
end;

procedure TDBToggleSwitchTests.EscapeRestoresField;
var
  S: TPPGDBToggleSwitch;
begin
  S := NewSwitch('Active');
  S.Click;
  CheckFalse(S.Checked);
  CheckTrue(FData.State = dsEdit);
  S.Perform(WM_KEYDOWN, VK_ESCAPE, 0);
  CheckTrue(S.Checked, 'Esc stellt den Feldwert wieder her');
  CheckTrue(FData.FieldByName('Active').AsBoolean);
end;

procedure TDBToggleSwitchTests.StreamsValuesAndNotChecked;
var
  S: TPPGDBToggleSwitch;
  T: string;
begin
  S := NewSwitch('Active');
  CheckTrue(S.Checked, 'Anna: an');
  T := ComponentToText(S);
  CheckTrue(Pos('ValueChecked', T) = 0, 'Vorgabe nicht gespeichert');
  CheckTrue(Pos(#13#10'  Checked = ', T) = 0, 'Checked wird nie gespeichert: ' + T);
  S.DataField := 'Flag';
  S.ValueChecked := 'J';
  S.ValueUnchecked := 'N';
  T := ComponentToText(S);
  CheckTrue(Pos('ValueChecked = ''J''', T) > 0);
  CheckTrue(Pos('ValueUnchecked = ''N''', T) > 0);
  CheckTrue(Pos('DataField = ''Flag''', T) > 0);
  CheckTrue(Pos(#13#10'  Checked = ', T) = 0, 'Checked nicht gespeichert');
end;

procedure TDBToggleSwitchTests.LoadsDfmWithValues;
const
  Dfm =
    'object DBToggle1: TPPGDBToggleSwitch'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 120'#13#10 +
    '  Height = 28'#13#10 +
    '  Caption = ''Aktiv'''#13#10 +
    '  DataField = ''Flag'''#13#10 +
    '  ReadOnly = True'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  ValueChecked = ''J;Ja'''#13#10 +
    '  ValueUnchecked = ''N;Nein'''#13#10 +
    'end';
var
  S: TPPGDBToggleSwitch;
begin
  S := TPPGDBToggleSwitch.Create(FForm);
  LoadFromDfm(S, Dfm);
  S.Parent := FForm;
  S.DataSource := FSource;
  CheckEquals('Flag', S.DataField);
  CheckTrue(S.ReadOnly);
  CheckEquals('J;Ja', S.ValueChecked);
  CheckEquals('Aktiv', S.Caption);
  CheckTrue(S.State = cbChecked, 'Anna: J');
  FData.Next;
  CheckTrue(S.State = cbUnchecked, 'Bernd: Nein');
end;

procedure TDBToggleSwitchTests.PaintsBothStates;
var
  S: TPPGDBToggleSwitch;
  Gdi: Boolean;
  Bmp: TBitmap;
begin
  S := NewSwitch('Active');
  S.Caption := 'Aktiv';
  for Gdi := False to True do
  begin
    TPPGRendererRegistry.ForceGdiFallback := Gdi;
    FData.First;
    Bmp := RenderToBitmap(S);
    Bmp.Free;
    FData.Next;
    Bmp := RenderToBitmap(S);
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterTest('Inventur', TShapeTests.Suite);
  RegisterTest('Inventur', TDBTextTests.Suite);
  RegisterTest('Inventur', TDBToggleSwitchTests.Suite);

end.
