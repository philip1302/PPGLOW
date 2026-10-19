unit PPG.Tests.ImageStored;

{ Bildreferenz in der DFM (ImageIndex/ImageName) darf beim Speichern nie
  verloren gehen. Regel: Ist ImageName gesetzt und die Liste kennt Namen
  (TVirtualImageList), wird nur ImageName gespeichert (wie VCL, robust gegen
  Umsortieren); sonst ImageIndex (TImageList, Bild ohne Namen, ImageName
  leer, Images erst nach ImageIndex gesetzt). Eintraege (ToolBar, NavigationView,
  StatusBar, PageControl, Ribbon, DBNavigator) speichern beides; ihr ImageName
  folgt einem neu gesetzten ImageIndex (wie TMenuItem), sonst ueberschreibt
  beim Laden ein veralteter Name den Index.
  Rundreise ueber ein ganzes Formular (WriteComponent/ReadComponent, wie die
  IDE), damit die Images-Verweise aufgeloest und Loaded aufgerufen werden. }

interface

uses
  TestFramework, Winapi.Windows, System.Classes, System.SysUtils, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.ImgList, Vcl.Imaging.pngimage
  {$IF CompilerVersion >= 34.0}, Vcl.ImageCollection, Vcl.VirtualImageList{$IFEND},
  PPG.Types, PPG.Button, PPG.Image, PPG.DB.Controls, PPG.ToolBar, PPG.NavigationView,
  PPG.StatusBar, PPG.PageControl, PPG.Ribbon, PPG.Ribbon.Items, PPG.DB.Navigator,
  PPG.Tests.Controls;

type
  TImageStoredTests = class(TControlTestCase)
  private
    FRoots: TObjectList<TForm>;
    function NewRoot: TForm;
    function RootToText(Root: TForm): string;
    function TextToRoot(const Text: string): TForm;
    function RoundTrip(Root: TForm): TForm;
    function ObjectText(const Text, ObjName: string): string;
    {$IF CompilerVersion >= 34.0}
    /// Liste mit save/open/print (Namen) und Index 3 ohne Namen.
    function MakeVil(Root: TForm): TVirtualImageList;
    {$IFEND}
    function MakeImageList(Root: TForm): TImageList;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ButtonIndexWithoutNameIsStored;
    procedure ButtonUnnamedImageStoresIndex;
    procedure ButtonNamedImageStoresOnlyName;
    procedure ButtonImageListStoresIndex;
    procedure ButtonNoImageStoresNothing;
    procedure ButtonNamesUnavailableStoresIndex;
    procedure ButtonStateImagesWithoutName;
    procedure OldDfmWithIndexOnlyLoadsAndKeepsIndex;
    procedure ImageAndDBImageIndexWithoutName;
    procedure ItemsIndexFollowsNameAndSurvives;
    procedure ItemsUnnamedAndUnknownNames;
  end;

implementation

{ Hilfen }

procedure TImageStoredTests.SetUp;
begin
  inherited;
  FRoots := TObjectList<TForm>.Create(True);
end;

procedure TImageStoredTests.TearDown;
begin
  FRoots.Free;
  inherited;
end;

function TImageStoredTests.NewRoot: TForm;
begin
  Result := TForm.CreateNew(nil);
  FRoots.Add(Result);
  Result.Name := 'ImgRoot';
end;

function TImageStoredTests.RootToText(Root: TForm): string;
var
  Bin, Txt: TMemoryStream;
  A: AnsiString;
begin
  Bin := TMemoryStream.Create;
  Txt := TMemoryStream.Create;
  try
    Bin.WriteComponent(Root);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    SetString(A, PAnsiChar(Txt.Memory), Txt.Size);
    Result := string(A);
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

function TImageStoredTests.TextToRoot(const Text: string): TForm;
var
  Bin, Txt: TMemoryStream;
  A: AnsiString;
begin
  A := AnsiString(Text);
  Bin := TMemoryStream.Create;
  Txt := TMemoryStream.Create;
  try
    Txt.WriteBuffer(PAnsiChar(A)^, Length(A));
    Txt.Position := 0;
    ObjectTextToBinary(Txt, Bin);
    Bin.Position := 0;
    Result := TForm.CreateNew(nil);
    FRoots.Add(Result);
    Bin.ReadComponent(Result);
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

function TImageStoredTests.RoundTrip(Root: TForm): TForm;
begin
  Result := TextToRoot(RootToText(Root));
end;

function TImageStoredTests.ObjectText(const Text, ObjName: string): string;
var
  P, Q: Integer;
begin
  // Abschnitt "object ObjName: ..." (Ebene 1) bis einschliesslich "  end"
  P := Pos('object ' + ObjName + ':', Text);
  if P = 0 then
    Exit('');
  Result := Copy(Text, P, MaxInt);
  Q := Pos(#13#10'  end'#13#10, Result);
  if Q > 0 then
    Result := Copy(Result, 1, Q + 8);
end;

{$IF CompilerVersion >= 34.0}
function TImageStoredTests.MakeVil(Root: TForm): TVirtualImageList;
const
  Names: array[0..2] of string = ('save', 'open', 'print');
var
  I: Integer;
  Bmp: TBitmap;
  Png: TPngImage;
  S: TMemoryStream;
  IC: TImageCollection;
begin
  IC := TImageCollection.Create(Root);
  IC.Name := 'IC';
  for I := 0 to High(Names) do
  begin
    Bmp := TBitmap.Create;
    Png := TPngImage.Create;
    S := TMemoryStream.Create;
    try
      Bmp.SetSize(16, 16);
      Bmp.Canvas.Brush.Color := RGB(I * 80, 100, 200);
      Bmp.Canvas.FillRect(Rect(0, 0, 16, 16));
      Png.Assign(Bmp);
      Png.SaveToStream(S);
      S.Position := 0;
      IC.Add(Names[I], S);
    finally
      S.Free;
      Png.Free;
      Bmp.Free;
    end;
  end;
  Result := TVirtualImageList.Create(Root);
  Result.Name := 'VIL';
  Result.ImageCollection := IC;
  for I := 0 to High(Names) do
    Result.Add(Names[I], Names[I]);
  Result.Add('print', 'print');
  Result.Images[3].Name := ''; // Bild ohne Namen
  CheckEquals('', Result.GetNameByIndex(3), 'Vorbedingung: Index 3 ohne Namen');
end;
{$IFEND}

function TImageStoredTests.MakeImageList(Root: TForm): TImageList;
var
  I: Integer;
  Bmp: TBitmap;
begin
  Result := TImageList.Create(Root);
  Result.Name := 'IL';
  for I := 0 to 2 do
  begin
    Bmp := TBitmap.Create;
    try
      Bmp.SetSize(16, 16);
      Bmp.Canvas.Brush.Color := RGB(I * 80, 0, 0);
      Bmp.Canvas.FillRect(Rect(0, 0, 16, 16));
      Result.Add(Bmp, nil);
    finally
      Bmp.Free;
    end;
  end;
end;

function NewBtn(Root: TForm; const AName: string): TPPGButton;
begin
  Result := TPPGButton.Create(Root);
  Result.Name := AName;
  Result.Parent := Root;
end;

{ Tests }

procedure TImageStoredTests.ButtonIndexWithoutNameIsStored;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  B: TPPGButton;
  T: string;
begin
  // Wie eine DFM, deren Images-Verweis erst nach ImageIndex aufgeloest wird
  // (Liste auf einem anderen Modul): Index gesetzt, ImageName bleibt leer
  R := NewRoot;
  B := NewBtn(R, 'B1');
  B.ImageIndex := 2;
  B.Images := MakeVil(R);
  CheckEquals(2, B.ImageIndex);
  CheckEquals('', B.ImageName, 'Vorbedingung: kein Name');
  T := ObjectText(RootToText(R), 'B1');
  CheckTrue(Pos('ImageIndex = 2', T) > 0, 'ImageIndex muss gespeichert werden: ' + T);
  CheckTrue(Pos('ImageName', T) = 0, 'leerer ImageName nicht: ' + T);
  R2 := RoundTrip(R);
  B := R2.FindComponent('B1') as TPPGButton;
  CheckEquals(2, B.ImageIndex, 'Bild nach der Rundreise');
  CheckTrue(B.Images = R2.FindComponent('VIL'), 'Images');
  CheckEquals(2, (RoundTrip(R2).FindComponent('B1') as TPPGButton).ImageIndex, 'zweite Rundreise');
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ButtonUnnamedImageStoresIndex;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  B: TPPGButton;
  T: string;
begin
  R := NewRoot;
  B := NewBtn(R, 'B1');
  B.Images := MakeVil(R);
  B.ImageIndex := 3;
  CheckEquals('', B.ImageName, 'Bild ohne Namen');
  T := ObjectText(RootToText(R), 'B1');
  CheckTrue(Pos('ImageIndex = 3', T) > 0, 'ImageIndex muss gespeichert werden: ' + T);
  // Die TVirtualImageList vergibt beim Laden selbst wieder Namen; der
  // gespeicherte Index findet das Bild trotzdem
  R2 := RoundTrip(R);
  CheckEquals(3, (R2.FindComponent('B1') as TPPGButton).ImageIndex);
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ButtonNamedImageStoresOnlyName;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  B: TPPGButton;
  VIL: TVirtualImageList;
  T: string;
begin
  R := NewRoot;
  B := NewBtn(R, 'B1');
  B.Images := MakeVil(R);
  B.ImageIndex := 1;
  CheckEquals('open', B.ImageName, 'Index -> Name');
  T := ObjectText(RootToText(R), 'B1');
  CheckTrue(Pos('ImageName = ''open''', T) > 0, 'Name: ' + T);
  CheckTrue(Pos('ImageIndex', T) = 0, 'Index entfaellt (wie VCL): ' + T);
  R2 := RoundTrip(R);
  B := R2.FindComponent('B1') as TPPGButton;
  CheckEquals(1, B.ImageIndex);
  CheckEquals('open', B.ImageName);
  // Umsortiert gespeichert: der Name findet das Bild am neuen Platz
  VIL := R2.FindComponent('VIL') as TVirtualImageList;
  VIL.Delete(0);
  CheckEquals(0, B.ImageIndex, 'Name folgt dem Umsortieren');
  CheckEquals(0, (RoundTrip(R2).FindComponent('B1') as TPPGButton).ImageIndex);
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ButtonImageListStoresIndex;
var
  R, R2: TForm;
  B: TPPGButton;
  T: string;
begin
  R := NewRoot;
  B := NewBtn(R, 'B1');
  B.Images := MakeImageList(R);
  B.ImageIndex := 2;
  T := ObjectText(RootToText(R), 'B1');
  CheckTrue(Pos('ImageIndex = 2', T) > 0, 'TImageList: Index: ' + T);
  CheckTrue(Pos('ImageName', T) = 0, 'kein Name: ' + T);
  R2 := RoundTrip(R);
  CheckEquals(2, (R2.FindComponent('B1') as TPPGButton).ImageIndex);
end;

procedure TImageStoredTests.ButtonNoImageStoresNothing;
{$IF CompilerVersion >= 34.0}
var
  R: TForm;
  B: TPPGButton;
  T: string;
begin
  R := NewRoot;
  B := NewBtn(R, 'B1');
  B.Images := MakeVil(R);
  B.ImageIndex := 1;
  B.ImageIndex := -1;
  CheckEquals('', B.ImageName, '-1 leert den Namen');
  T := ObjectText(RootToText(R), 'B1');
  CheckTrue(Pos('ImageIndex', T) = 0, 'Vorgabe -1 nicht gespeichert: ' + T);
  CheckTrue(Pos('ImageName', T) = 0, T);
  CheckEquals(-1, (RoundTrip(R).FindComponent('B1') as TPPGButton).ImageIndex);
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ButtonNamesUnavailableStoresIndex;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  B: TPPGButton;
  VIL: TVirtualImageList;
  T: string;
begin
  // ImageName gesetzt, die Liste stellt aber keine Namen bereit -> Index
  R := NewRoot;
  B := NewBtn(R, 'B1');
  VIL := MakeVil(R);
  B.Images := VIL;
  B.ImageName := 'print';
  VIL.ImageNameAvailable := False;
  CheckEquals(2, B.ImageIndex);
  T := ObjectText(RootToText(R), 'B1');
  CheckTrue(Pos('ImageIndex = 2', T) > 0, 'Index: ' + T);
  CheckTrue(Pos('ImageName', T) = 0, 'Name nicht: ' + T);
  R2 := RoundTrip(R);
  CheckEquals(2, (R2.FindComponent('B1') as TPPGButton).ImageIndex);
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ButtonStateImagesWithoutName;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  B: TPPGButton;
  T: string;
begin
  R := NewRoot;
  B := NewBtn(R, 'B1');
  B.ImageIndex := 0;
  B.HotImageIndex := 1;
  B.DisabledImageIndex := 2;
  B.PressedImageIndex := 3;
  B.Images := MakeVil(R);
  T := ObjectText(RootToText(R), 'B1');
  CheckTrue(Pos('HotImageIndex = 1', T) > 0, T);
  CheckTrue(Pos('DisabledImageIndex = 2', T) > 0, T);
  CheckTrue(Pos('PressedImageIndex = 3', T) > 0, T);
  R2 := RoundTrip(R);
  B := R2.FindComponent('B1') as TPPGButton;
  CheckEquals(0, B.ImageIndex);
  CheckEquals(1, B.HotImageIndex);
  CheckEquals(2, B.DisabledImageIndex);
  CheckEquals(3, B.PressedImageIndex);
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.OldDfmWithIndexOnlyLoadsAndKeepsIndex;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  B: TPPGButton;
  T, BtnTxt, NewTxt: string;
  P: Integer;
begin
  // Alte DFM: Knopf vor der Liste (Verweis wird erst nach dem Lesen
  // aufgeloest), nur ImageIndex, kein ImageName
  R := NewRoot;
  B := NewBtn(R, 'B1');
  B.Images := MakeVil(R);
  B.ImageName := 'print';
  T := RootToText(R);
  BtnTxt := ObjectText(T, 'B1');
  CheckTrue(BtnTxt <> '', 'Knopf im Text');
  T := StringReplace(T, BtnTxt, '', []);
  NewTxt := StringReplace(BtnTxt, 'ImageName = ''print''', 'ImageIndex = 2', []);
  CheckTrue(NewTxt <> BtnTxt, 'ImageName ersetzt');
  P := Pos('  object ', T);
  Insert(NewTxt, T, P);
  R2 := TextToRoot(T);
  B := R2.FindComponent('B1') as TPPGButton;
  CheckTrue(B.Images = R2.FindComponent('VIL'), 'Images aufgeloest');
  CheckEquals(2, B.ImageIndex, 'alte DFM: Index geladen');
  // Speichern darf das Bild nicht verlieren (gemeldeter Fehler)
  CheckEquals(2, (RoundTrip(R2).FindComponent('B1') as TPPGButton).ImageIndex,
    'nach dem Speichern: ' + ObjectText(RootToText(R2), 'B1'));
  // Alte DFM mit beidem: der Name gewinnt
  T := StringReplace(T, 'ImageIndex = 2', 'ImageIndex = 0' + #13#10 + '    ImageName = ''print''', []);
  CheckEquals(2, (TextToRoot(T).FindComponent('B1') as TPPGButton).ImageIndex, 'Name gewinnt');
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ImageAndDBImageIndexWithoutName;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  I: TPPGImage;
  D: TPPGDBImage;
  VIL: TVirtualImageList;
  T: string;
begin
  R := NewRoot;
  I := TPPGImage.Create(R);
  I.Name := 'Img1';
  I.Parent := R;
  D := TPPGDBImage.Create(R);
  D.Name := 'DBImg1';
  D.Parent := R;
  I.ImageIndex := 2;
  I.ImageIndexDark := 3;
  D.ImageIndex := 1;
  D.ImageIndexDark := 2;
  VIL := MakeVil(R);
  I.Images := VIL;
  D.Images := VIL;
  T := RootToText(R);
  CheckTrue(Pos('ImageIndex = 2', ObjectText(T, 'Img1')) > 0, ObjectText(T, 'Img1'));
  CheckTrue(Pos('ImageIndexDark = 3', ObjectText(T, 'Img1')) > 0, ObjectText(T, 'Img1'));
  CheckTrue(Pos('ImageIndex = 1', ObjectText(T, 'DBImg1')) > 0, ObjectText(T, 'DBImg1'));
  CheckTrue(Pos('ImageIndexDark = 2', ObjectText(T, 'DBImg1')) > 0, ObjectText(T, 'DBImg1'));
  R2 := RoundTrip(R);
  I := R2.FindComponent('Img1') as TPPGImage;
  D := R2.FindComponent('DBImg1') as TPPGDBImage;
  CheckEquals(2, I.ImageIndex);
  CheckEquals(3, I.ImageIndexDark);
  CheckEquals(1, D.ImageIndex);
  CheckEquals(2, D.ImageIndexDark);
  // Mit Namen: nur der Name
  I.ImageIndex := 1;
  CheckEquals('open', I.ImageName);
  T := ObjectText(RootToText(R2), 'Img1');
  CheckTrue(Pos('ImageName = ''open''', T) > 0, T);
  CheckTrue(Pos('ImageIndex = ', T) = 0, T);
  CheckTrue(Pos('ImageIndexDark = 3', T) > 0, 'Dark ohne Namen bleibt Index: ' + T);
  I.Images := nil;
  D.Images := nil;
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ItemsIndexFollowsNameAndSurvives;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  VIL: TVirtualImageList;
  TB: TPPGToolBar;
  NV: TPPGNavigationView;
  SB: TPPGStatusBar;
  PC: TPPGPageControl;
  TS: TPPGTabSheet;
  RB: TPPGRibbon;
  DN: TPPGDBNavigator;
  Host: TPanel;
begin
  R := NewRoot;
  VIL := MakeVil(R);
  TB := TPPGToolBar.Create(R); TB.Name := 'TB'; TB.Parent := R; TB.Images := VIL;
  // Eigener Parent: die Leiste haengt zur Laufzeit einen Beobachter (Besitzer
  // = Parent) an, der sonst als Komponente des Formulars mitgestreamt wuerde
  Host := TPanel.Create(R); Host.Name := 'Host'; Host.Parent := R;
  NV := TPPGNavigationView.Create(R); NV.Name := 'NV'; NV.Parent := Host; NV.Images := VIL;
  SB := TPPGStatusBar.Create(R); SB.Name := 'SB'; SB.Parent := R; SB.Images := VIL;
  PC := TPPGPageControl.Create(R); PC.Name := 'PC'; PC.Parent := R; PC.Images := VIL;
  TS := TPPGTabSheet.Create(R); TS.Name := 'TS'; TS.PageControl := PC;
  RB := TPPGRibbon.Create(R); RB.Name := 'RB'; RB.Parent := R; RB.Images := VIL;
  DN := TPPGDBNavigator.Create(R); DN.Name := 'DN'; DN.Parent := R; DN.Images := VIL;
  TB.Items.Add.ImageName := 'open';
  NV.Items.AddItem('A').ImageName := 'open';
  SB.Panels.Add.ImageName := 'open';
  TS.ImageName := 'open';
  RB.QuickAccess.Add.ImageName := 'open';
  DN.CustomButtons.Add.ImageName := 'open';
  CheckEquals(1, TB.Items[0].ImageIndex, 'Vorbedingung Name -> Index');
  // Index neu setzen (Objektinspektor): der Name muss folgen
  TB.Items[0].ImageIndex := 2;
  NV.Items[0].ImageIndex := 2;
  SB.Panels[0].ImageIndex := 2;
  TS.ImageIndex := 2;
  RB.QuickAccess[0].ImageIndex := 2;
  DN.CustomButtons[0].ImageIndex := 2;
  CheckEquals('print', TB.Items[0].ImageName, 'ToolItem');
  CheckEquals('print', NV.Items[0].ImageName, 'NavItem');
  CheckEquals('print', SB.Panels[0].ImageName, 'StatusPanel');
  CheckEquals('print', TS.ImageName, 'TabSheet');
  CheckEquals('print', RB.QuickAccess[0].ImageName, 'RibbonItem');
  CheckEquals('print', DN.CustomButtons[0].ImageName, 'NavButton');
  R2 := RoundTrip(R);
  CheckEquals(2, (R2.FindComponent('TB') as TPPGToolBar).Items[0].ImageIndex, 'ToolItem');
  CheckEquals(2, (R2.FindComponent('NV') as TPPGNavigationView).Items[0].ImageIndex, 'NavItem');
  CheckEquals(2, (R2.FindComponent('SB') as TPPGStatusBar).Panels[0].ImageIndex, 'StatusPanel');
  CheckEquals(2, (R2.FindComponent('TS') as TPPGTabSheet).ImageIndex, 'TabSheet');
  CheckEquals(2, (R2.FindComponent('RB') as TPPGRibbon).QuickAccess[0].ImageIndex, 'RibbonItem');
  CheckEquals(2, (R2.FindComponent('DN') as TPPGDBNavigator).CustomButtons[0].ImageIndex, 'NavButton');
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

procedure TImageStoredTests.ItemsUnnamedAndUnknownNames;
{$IF CompilerVersion >= 34.0}
var
  R, R2: TForm;
  VIL: TVirtualImageList;
  TB: TPPGToolBar;
  SB: TPPGStatusBar;
  It: TPPGToolItem;
begin
  R := NewRoot;
  VIL := MakeVil(R);
  TB := TPPGToolBar.Create(R); TB.Name := 'TB'; TB.Parent := R; TB.Images := VIL;
  SB := TPPGStatusBar.Create(R); SB.Name := 'SB'; SB.Parent := R;
  // Bild ohne Namen: Index bleibt, Name leer
  It := TB.Items.Add;
  It.ImageName := 'open';
  It.ImageIndex := 3;
  CheckEquals('', It.ImageName, 'Bild ohne Namen leert den alten Namen');
  // Unbekannter Name: bleibt (Liste kann zur Laufzeit befuellt werden)
  It := TB.Items.Add;
  It.ImageName := 'gibtsnicht';
  CheckEquals(-1, It.ImageIndex);
  CheckEquals('gibtsnicht', It.ImageName, 'unbekannter Name bleibt');
  // Index ohne Liste, Liste danach: Index bleibt
  SB.Panels.Add.ImageIndex := 1;
  SB.Images := MakeImageList(R);
  R2 := RoundTrip(R);
  TB := R2.FindComponent('TB') as TPPGToolBar;
  CheckEquals(3, TB.Items[0].ImageIndex, 'unbenanntes Bild');
  CheckEquals(-1, TB.Items[1].ImageIndex);
  CheckEquals('gibtsnicht', TB.Items[1].ImageName);
  CheckEquals(1, (R2.FindComponent('SB') as TPPGStatusBar).Panels[0].ImageIndex, 'TImageList');
  // Index -1 bei bekanntem Namen leert den Namen
  TB.Items[0].ImageName := 'save';
  TB.Items[0].ImageIndex := -1;
  CheckEquals('', TB.Items[0].ImageName);
end;
{$ELSE}
begin
  Skip('ImageName erst ab Delphi 10.4');
end;
{$IFEND}

initialization
  RegisterClasses([TForm, TPanel, TPPGButton, TPPGImage, TPPGDBImage, TPPGToolBar, TPPGNavigationView,
    TPPGStatusBar, TPPGPageControl, TPPGTabSheet, TPPGRibbon, TPPGDBNavigator, TImageList
    {$IF CompilerVersion >= 34.0}, TImageCollection, TVirtualImageList{$IFEND}]);
  RegisterTest('Luecken', TImageStoredTests.Suite);

end.
