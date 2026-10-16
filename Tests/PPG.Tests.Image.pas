unit PPG.Tests.Image;

{ Tests fuer TPPGImage (Ersatz fuer TImage) und TPPGDBImage (Ersatz fuer TDBImage).
  - Formate: Erkennung an den ersten Bytes, Laden, Speichern, Alpha-Rechnung.
  - TPPGImage: Vorgaben und DFM wie TImage, DestRect wie TImage (alle
    Kombinationen), AutoSize, Zeichnen, Deaktiviert, Dark-Variante, Bildliste,
    Bildname, Rahmen, Streaming.
  - TPPGDBImage: Blob-Felder (BMP, PNG, JPEG, GIF, Null, unbekannt), AutoDisplay,
    Einfuegen, Laden, Ausschneiden, Esc, ReadOnly, StoreFormat, Platzhalter.
  Alle Controls haengen an dem versteckten Testformular der Suite (FForm). }

{$I ..\Source\PPG.inc}

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.UITypes, System.Variants, Vcl.Graphics, Vcl.Forms, Vcl.Controls,
  Vcl.ExtCtrls, Vcl.ImgList,
  Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Image, PPG.DB.Controls, PPG.Tests.Controls;

type
  TImageFormatTests = class(TTestCase)
  published
    procedure DetectsAllFormats;
    procedure EmptyAndGarbage;
    procedure LoadsEachFormat;
    procedure BrokenDataGivesNil;
    procedure SavesInChosenFormat;
    procedure PremultKeepsColorAndAlpha;
    procedure PremultDisabledIsGrayAndFaded;
  end;

  TImageTests = class(TControlTestCase)
  private
    function NewImage: TPPGImage;
    function PaintImage(C: TPPGImage): TBitmap;
    function Loaded(const Dfm: string): TPPGImage;
  published
    procedure DefaultsLikeTImage;
    procedure LoadsTImageDfm;
    procedure StreamsOnlyWhatIsNeeded;
    procedure PictureAndDarkPictureRoundTrip;
    procedure DestRectLikeTImage;
    procedure AutoSizeFollowsPicture;
    procedure AutoSizeAddsFrame;
    procedure PaintsPictureAtDestRect;
    procedure TransparentIsPassedToGraphic;
    procedure OpaqueOnlyWhenCovered;
    procedure DisabledIsGrayAndFaded;
    procedure DarkPictureReplacesInDarkMode;
    procedure NoDarkPictureKeepsLight;
    procedure ImageListSourceNaturalAndScaled;
    procedure ImageListDisabled;
    procedure DarkImageIndex;
    procedure ImageNameResolvesAndStreamsName;
    procedure ImageListFreedDetaches;
    procedure BorderFrameFollowsTheme;
    procedure CanvasCreatesBitmap;
    procedure InvalidImageIndexIsRejected;
  end;

  TDBImageCase = class(TControlTestCase)
  protected
    FData: TClientDataSet;
    FSource: TDataSource;
    procedure SetUp; override;
    function Blob: TBlobField;
    procedure PutBytes(const Bytes: TBytes);
    function NewImage: TPPGDBImage;
    function Paint(C: TPPGDBImage): TBitmap;
  end;

  TDBImageTests = class(TDBImageCase)
  published
    procedure LoadsTDBImageDfm;
    procedure StreamsOnlyWhatIsNeeded;
    procedure ShowsEachFormatAndScrolls;
    procedure NullAndGarbageShowNothing;
    procedure AutoDisplayFalseLoadsOnDemand;
    procedure LoadFromFileEditsAndPosts;
    procedure LoadFromStreamUnknownRaises;
    procedure StoreFormatConverts;
    procedure PasteWritesField;
    procedure CutClearsField;
    procedure ReadOnlyRejectsChange;
    procedure EscapeRestores;
    procedure PlaceholderForNullField;
    procedure DataSourceFreedDetaches;
    procedure SaveToFileKeepsFormat;
  end;

implementation

uses
  System.TypInfo, System.IOUtils, Vcl.Clipbrd, Vcl.ImageCollection, Vcl.VirtualImageList,
  PPG.Theme, PPG.Types, PPG.Exceptions, PPG.Render.Registry;

type
  TDBImageCrack = class(TPPGDBImage);
  TImageCrack = class(TImage);

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

function RgbOf(C: TColor; Shift: Integer): Integer;
begin
  Result := (Integer(ColorToRGB(C)) shr Shift) and $FF;
end;

function Near(A, B: TColor; Tol: Integer = 8): Boolean;
begin
  Result := (Abs(RgbOf(A, 0) - RgbOf(B, 0)) <= Tol) and (Abs(RgbOf(A, 8) - RgbOf(B, 8)) <= Tol) and
    (Abs(RgbOf(A, 16) - RgbOf(B, 16)) <= Tol);
end;

function Lum(C: TColor): Integer;
begin
  Result := (RgbOf(C, 0) + RgbOf(C, 8) + RgbOf(C, 16)) div 3;
end;

function MakeBmp(Color: TColor; W: Integer = 8; H: Integer = 8): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(W, H);
  Result.Canvas.Brush.Color := Color;
  Result.Canvas.FillRect(Rect(0, 0, W, H));
end;

function GraphicBytes(G: TGraphic): TBytes;
var
  MS: TBytesStream;
begin
  MS := TBytesStream.Create;
  try
    G.SaveToStream(MS);
    Result := Copy(MS.Bytes, 0, Integer(MS.Size));
  finally
    MS.Free;
  end;
end;

/// Bilddaten einer Farbe in einem Format.
function ImageBytes(Fmt: TPPGImageFormat; Color: TColor; W: Integer = 8; H: Integer = 8): TBytes;
var
  B: TBitmap;
  MS: TBytesStream;
begin
  B := MakeBmp(Color, W, H);
  try
    MS := TBytesStream.Create;
    try
      case Fmt of
        ifPng: PPGSaveGraphic(B, sfPng, MS);
        ifJpeg: PPGSaveGraphic(B, sfJpeg, MS);
        ifGif: PPGSaveGraphic(B, sfGif, MS);
      else
        B.SaveToStream(MS);
      end;
      Result := Copy(MS.Bytes, 0, Integer(MS.Size));
    finally
      MS.Free;
    end;
  finally
    B.Free;
  end;
end;

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

{ TImageFormatTests }

procedure TImageFormatTests.DetectsAllFormats;
var
  F: TPPGImageFormat;
begin
  for F in [ifBitmap, ifPng, ifJpeg, ifGif] do
    CheckTrue(F = PPGDetectImageFormat(ImageBytes(F, clRed)), 'Format ' + IntToStr(Ord(F)));
  CheckTrue(ifIcon = PPGDetectImageFormat(TBytes.Create(0, 0, 1, 0, 1, 0, 16, 16)), 'Icon');
  CheckTrue(ifMetafile = PPGDetectImageFormat(TBytes.Create($D7, $CD, $C6, $9A, 0, 0)), 'WMF');
end;

procedure TImageFormatTests.EmptyAndGarbage;
var
  MS: TBytesStream;
begin
  CheckTrue(ifNone = PPGDetectImageFormat(TBytes.Create()), 'leer');
  CheckTrue(ifUnknown = PPGDetectImageFormat(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8)), 'Muell');
  CheckTrue(ifUnknown = PPGDetectImageFormat(TBytes.Create($42)), 'zu kurz fuer BMP');
  MS := TBytesStream.Create(ImageBytes(ifPng, clRed));
  try
    MS.Position := 5;
    PPGDetectImageFormat(MS);
    CheckEquals(5, MS.Position, 'Position bleibt');
  finally
    MS.Free;
  end;
end;

procedure TImageFormatTests.LoadsEachFormat;
var
  Fmts: array[0..3] of TPPGImageFormat;
  I: Integer;
  MS: TBytesStream;
  G: TGraphic;
  Fmt: TPPGImageFormat;
begin
  Fmts[0] := ifBitmap;
  Fmts[1] := ifPng;
  Fmts[2] := ifJpeg;
  Fmts[3] := ifGif;
  for I := 0 to 3 do
  begin
    MS := TBytesStream.Create(ImageBytes(Fmts[I], clRed, 12, 6));
    try
      G := PPGLoadGraphic(MS, Fmt);
      try
        CheckNotNull(G, 'geladen ' + IntToStr(I));
        CheckTrue(Fmt = Fmts[I]);
        CheckEquals(12, G.Width);
        CheckEquals(6, G.Height);
        CheckTrue(PPGGraphicFormat(G) = Fmts[I], 'PPGGraphicFormat');
      finally
        G.Free;
      end;
    finally
      MS.Free;
    end;
  end;
end;

procedure TImageFormatTests.BrokenDataGivesNil;
var
  Bytes: TBytes;
  MS: TBytesStream;
  G: TGraphic;
  Fmt: TPPGImageFormat;
begin
  Bytes := ImageBytes(ifPng, clRed);
  SetLength(Bytes, 20); // PNG-Kopf, Rest fehlt
  MS := TBytesStream.Create(Bytes);
  try
    G := PPGLoadGraphic(MS, Fmt);
    CheckNull(G, 'abgeschnitten');
    CheckTrue(Fmt = ifUnknown);
  finally
    MS.Free;
  end;
  MS := TBytesStream.Create(TBytes.Create(9, 9, 9, 9, 9));
  try
    G := PPGLoadGraphic(MS, Fmt);
    CheckNull(G, 'Muell');
  finally
    MS.Free;
  end;
end;

procedure TImageFormatTests.SavesInChosenFormat;
var
  B: TBitmap;
  MS: TMemoryStream;
  Bytes: TBytes;
  F: TPPGImageStoreFormat;
  Expect: TPPGImageFormat;
begin
  B := MakeBmp(clGreen, 10, 10);
  try
    for F := Low(TPPGImageStoreFormat) to High(TPPGImageStoreFormat) do
    begin
      MS := TMemoryStream.Create;
      try
        PPGSaveGraphic(B, F, MS);
        SetLength(Bytes, MS.Size);
        MS.Position := 0;
        MS.ReadBuffer(Bytes[0], Length(Bytes));
      finally
        MS.Free;
      end;
      case F of
        sfPng: Expect := ifPng;
        sfJpeg: Expect := ifJpeg;
        sfGif: Expect := ifGif;
      else
        Expect := ifBitmap;
      end;
      CheckTrue(Expect = PPGDetectImageFormat(Bytes), 'Format ' + IntToStr(Ord(F)));
    end;
  finally
    B.Free;
  end;
end;

procedure TImageFormatTests.PremultKeepsColorAndAlpha;
var
  Bmp: TBitmap;
  P: PRGBQuad;
begin
  // Linke Haelfte rot und deckend, rechte Haelfte nichts gezeichnet
  Bmp := PPGRenderPremult(8, 4,
    procedure(C: TCanvas; const R: TRect)
    begin
      C.Brush.Color := clRed;
      C.FillRect(Rect(0, 0, 4, 4));
    end, False);
  try
    CheckTrue(Bmp.AlphaFormat = afPremultiplied);
    P := Bmp.ScanLine[1];
    CheckEquals(255, P.rgbReserved, 'deckend');
    CheckEquals(255, P.rgbRed);
    CheckEquals(0, P.rgbGreen);
    Inc(P, 6);
    CheckEquals(0, P.rgbReserved, 'durchsichtig');
    CheckEquals(0, P.rgbRed, 'vormultipliziert');
  finally
    Bmp.Free;
  end;
end;

procedure TImageFormatTests.PremultDisabledIsGrayAndFaded;
var
  Bmp: TBitmap;
  P: PRGBQuad;
begin
  Bmp := PPGRenderPremult(4, 4,
    procedure(C: TCanvas; const R: TRect)
    begin
      C.Brush.Color := clRed;
      C.FillRect(R);
    end, True);
  try
    P := Bmp.ScanLine[2];
    CheckTrue((P.rgbReserved >= 126) and (P.rgbReserved <= 128), 'halb durchsichtig');
    CheckEquals(P.rgbRed, P.rgbGreen, 'grau');
    CheckEquals(P.rgbRed, P.rgbBlue, 'grau');
  finally
    Bmp.Free;
  end;
end;

{ TImageTests }

function TImageTests.NewImage: TPPGImage;
begin
  Result := TPPGImage.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 40, 30);
end;

function TImageTests.PaintImage(C: TPPGImage): TBitmap;
begin
  Result := PaintGraphic(C);
end;

function TImageTests.Loaded(const Dfm: string): TPPGImage;
begin
  Result := TPPGImage.Create(FForm);
  LoadFromDfm(Result, Dfm);
  Result.Parent := FForm;
end;

procedure TImageTests.DefaultsLikeTImage;
var
  A: TPPGImage;
  V: TImage;
begin
  A := TPPGImage.Create(FForm);
  V := TImage.Create(FForm);
  CheckEquals(V.Width, A.Width, 'Width');
  CheckEquals(V.Height, A.Height, 'Height');
  CheckEquals(V.Stretch, A.Stretch);
  CheckEquals(V.Proportional, A.Proportional);
  CheckEquals(V.Center, A.Center);
  CheckEquals(V.Transparent, A.Transparent);
  CheckEquals(V.AutoSize, A.AutoSize);
  CheckEquals(V.IncrementalDisplay, A.IncrementalDisplay);
  CheckNull(A.Picture.Graphic);
  CheckTrue(A.BorderStyle = bsNone);
  CheckFalse(A.DpiScaling);
end;

procedure TImageTests.LoadsTImageDfm;
const
  Dfm =
    'object Image1: TPPGImage'#13#10 +
    '  Left = 12'#13#10 +
    '  Top = 20'#13#10 +
    '  Width = 80'#13#10 +
    '  Height = 40'#13#10 +
    '  Anchors = [akLeft, akTop, akRight]'#13#10 +
    '  Center = True'#13#10 +
    '  IncrementalDisplay = True'#13#10 +
    '  Proportional = True'#13#10 +
    '  Stretch = True'#13#10 +
    '  Transparent = True'#13#10 +
    '  Hint = ''Logo'''#13#10 +
    '  ShowHint = True'#13#10 +
    'end';
var
  A: TPPGImage;
begin
  A := Loaded(Dfm);
  CheckEquals(12, A.Left);
  CheckEquals(80, A.Width);
  CheckTrue(A.Center and A.Proportional and A.Stretch and A.Transparent);
  CheckTrue(A.IncrementalDisplay);
  CheckEquals('Logo', A.Hint);
  CheckTrue(A.Anchors = [akLeft, akTop, akRight]);
end;

procedure TImageTests.StreamsOnlyWhatIsNeeded;
var
  A: TPPGImage;
  T: string;
begin
  A := TPPGImage.Create(FForm);
  T := ComponentToText(A);
  CheckTrue(Pos('Picture', T) = 0, 'leeres Bild wird nicht gespeichert: ' + T);
  CheckTrue(Pos('Stretch', T) = 0);
  CheckTrue(Pos('BorderStyle', T) = 0);
  CheckTrue(Pos('ImageIndex', T) = 0);
  CheckTrue(Pos('DpiScaling', T) = 0);
  A.BorderStyle := bsSingle;
  A.DpiScaling := True;
  A.ImageIndexDark := 3;
  T := ComponentToText(A);
  CheckTrue(Pos('BorderStyle = bsSingle', T) > 0);
  CheckTrue(Pos('DpiScaling = True', T) > 0);
  CheckTrue(Pos('ImageIndexDark = 3', T) > 0);
end;

procedure TImageTests.PictureAndDarkPictureRoundTrip;
var
  A, B: TPPGImage;
  Bmp: TBitmap;
begin
  A := NewImage;
  Bmp := MakeBmp(clRed);
  try
    A.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
  Bmp := MakeBmp(clBlue, 6, 6);
  try
    A.PictureDark.Assign(Bmp);
  finally
    Bmp.Free;
  end;
  B := TPPGImage.Create(FForm);
  LoadFromDfm(B, ComponentToText(A));
  CheckNotNull(B.Picture.Graphic, 'Picture');
  CheckNotNull(B.PictureDark.Graphic, 'PictureDark');
  CheckEquals(8, B.Picture.Width);
  CheckEquals(6, B.PictureDark.Width);
end;

procedure TImageTests.DestRectLikeTImage;
const
  Sizes: array[0..2, 0..3] of Integer = ((20, 10, 100, 50), (200, 100, 100, 50), (30, 90, 100, 40));
var
  S, P, C, I: Integer;
  A: TPPGImage;
  V: TImage;
  Bmp: TBitmap;
  RA, RV: TRect;
begin
  for I := 0 to 2 do
    for S := 0 to 1 do
      for P := 0 to 1 do
        for C := 0 to 1 do
        begin
          A := TPPGImage.Create(FForm);
          V := TImage.Create(FForm);
          Bmp := MakeBmp(clRed, Sizes[I, 0], Sizes[I, 1]);
          try
            A.Picture.Assign(Bmp);
            V.Picture.Assign(Bmp);
          finally
            Bmp.Free;
          end;
          A.SetBounds(0, 0, Sizes[I, 2], Sizes[I, 3]);
          V.SetBounds(0, 0, Sizes[I, 2], Sizes[I, 3]);
          A.Stretch := S = 1;
          V.Stretch := S = 1;
          A.Proportional := P = 1;
          V.Proportional := P = 1;
          A.Center := C = 1;
          V.Center := C = 1;
          RA := A.DestRect;
          RV := TImageCrack(V).DestRect;
          CheckTrue(EqualRect(RA, RV), Format('Fall %d/%d/%d/%d: %d,%d,%d,%d gegen %d,%d,%d,%d',
            [I, S, P, C, RA.Left, RA.Top, RA.Right, RA.Bottom, RV.Left, RV.Top, RV.Right, RV.Bottom]));
        end;
end;

procedure TImageTests.AutoSizeFollowsPicture;
var
  A: TPPGImage;
  Bmp: TBitmap;
begin
  A := NewImage;
  A.AutoSize := True;
  CheckEquals(40, A.Width, 'ohne Bild bleibt die Groesse');
  Bmp := MakeBmp(clRed, 17, 9);
  try
    A.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
  CheckEquals(17, A.Width);
  CheckEquals(9, A.Height);
end;

procedure TImageTests.AutoSizeAddsFrame;
var
  A: TPPGImage;
  Bmp: TBitmap;
begin
  A := NewImage;
  A.BorderStyle := bsSingle;
  A.AutoSize := True;
  Bmp := MakeBmp(clRed, 17, 9);
  try
    A.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
  CheckEquals(19, A.Width, 'Bild + 2 * Rahmen');
  CheckEquals(11, A.Height);
end;

procedure TImageTests.PaintsPictureAtDestRect;
var
  A: TPPGImage;
  Bmp, Pic: TBitmap;
begin
  A := NewImage;
  Pic := MakeBmp(clRed, 10, 10);
  try
    A.Picture.Assign(Pic);
  finally
    Pic.Free;
  end;
  Bmp := PaintImage(A);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[5, 5], clRed), 'oben links rot');
    CheckTrue(Near(Bmp.Canvas.Pixels[30, 20], clWhite), 'ausserhalb weiss');
  finally
    Bmp.Free;
  end;
  A.Stretch := True;
  Bmp := PaintImage(A);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[30, 20], clRed), 'gestreckt rot');
  finally
    Bmp.Free;
  end;
  A.Stretch := False;
  A.Center := True;
  Bmp := PaintImage(A);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[2, 2], clWhite), 'zentriert: Ecke leer');
    CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clRed), 'zentriert: Mitte rot');
  finally
    Bmp.Free;
  end;
end;

procedure TImageTests.TransparentIsPassedToGraphic;
var
  A: TPPGImage;
  Pic: TBitmap;
begin
  A := NewImage;
  Pic := MakeBmp(clRed);
  try
    A.Picture.Assign(Pic);
  finally
    Pic.Free;
  end;
  CheckFalse(A.Picture.Graphic.Transparent);
  A.Transparent := True;
  CheckTrue(A.Picture.Graphic.Transparent, 'Transparent am Bitmap');
end;

procedure TImageTests.OpaqueOnlyWhenCovered;
var
  A: TPPGImage;
  Pic: TBitmap;
begin
  A := NewImage;
  Pic := MakeBmp(clRed, 40, 30);
  try
    A.Picture.Assign(Pic);
  finally
    Pic.Free;
  end;
  CheckTrue(csOpaque in A.ControlStyle, 'deckt alles');
  A.Enabled := False;
  CheckFalse(csOpaque in A.ControlStyle, 'deaktiviert ist halb durchsichtig');
  A.Enabled := True;
  A.SetBounds(0, 0, 80, 60);
  A.Picture.Assign(A.Picture); // Aenderung melden
  CheckFalse(csOpaque in A.ControlStyle, 'deckt nicht alles');
  A.Stretch := True;
  CheckTrue(csOpaque in A.ControlStyle, 'gestreckt deckt alles');
end;

procedure TImageTests.DisabledIsGrayAndFaded;
var
  A: TPPGImage;
  Bmp, Pic: TBitmap;
  C: TColor;
begin
  A := NewImage;
  Pic := MakeBmp(clRed, 40, 30);
  try
    A.Picture.Assign(Pic);
  finally
    Pic.Free;
  end;
  A.Enabled := False;
  Bmp := PaintImage(A);
  try
    C := Bmp.Canvas.Pixels[20, 15];
    CheckFalse(Near(C, clRed, 40), 'nicht mehr rot');
    CheckTrue(Abs(RgbOf(C, 0) - RgbOf(C, 8)) < 6, 'grau');
    CheckTrue(Abs(RgbOf(C, 8) - RgbOf(C, 16)) < 6, 'grau');
    CheckTrue(Lum(C) > 120, 'blass auf weissem Grund');
  finally
    Bmp.Free;
  end;
end;

procedure TImageTests.DarkPictureReplacesInDarkMode;
var
  A: TPPGImage;
  Bmp, Pic: TBitmap;
  Saved: TPPGThemeMode;
begin
  A := NewImage;
  Pic := MakeBmp(clRed, 40, 30);
  try
    A.Picture.Assign(Pic);
  finally
    Pic.Free;
  end;
  Pic := MakeBmp(clBlue, 40, 30);
  try
    A.PictureDark.Assign(Pic);
  finally
    Pic.Free;
  end;
  Saved := TPPGTheme.Mode;
  try
    TPPGTheme.Mode := tmLight;
    Bmp := PaintImage(A);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clRed), 'hell: rot');
    finally
      Bmp.Free;
    end;
    TPPGTheme.Mode := tmDark;
    Bmp := PaintImage(A);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clBlue), 'dunkel: blau');
    finally
      Bmp.Free;
    end;
  finally
    TPPGTheme.Mode := Saved;
  end;
end;

procedure TImageTests.NoDarkPictureKeepsLight;
var
  A: TPPGImage;
  Bmp, Pic: TBitmap;
  Saved: TPPGThemeMode;
begin
  A := NewImage;
  Pic := MakeBmp(clRed, 40, 30);
  try
    A.Picture.Assign(Pic);
  finally
    Pic.Free;
  end;
  Saved := TPPGTheme.Mode;
  try
    TPPGTheme.Mode := tmDark;
    Bmp := PaintImage(A);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clRed), 'bleibt rot');
    finally
      Bmp.Free;
    end;
  finally
    TPPGTheme.Mode := Saved;
  end;
end;

function RedBlueList(Size: Integer): TImageList;
var
  B: TBitmap;
begin
  Result := TImageList.CreateSize(Size, Size);
  B := MakeBmp(clRed, Size, Size);
  try
    Result.Add(B, nil);
  finally
    B.Free;
  end;
  B := MakeBmp(clBlue, Size, Size);
  try
    Result.Add(B, nil);
  finally
    B.Free;
  end;
end;

procedure TImageTests.ImageListSourceNaturalAndScaled;
var
  A: TPPGImage;
  L: TImageList;
  Bmp: TBitmap;
begin
  L := RedBlueList(16);
  try
    A := NewImage;
    A.Images := L;
    A.ImageIndex := 0;
    A.AutoSize := True;
    CheckEquals(16, A.Width, 'AutoSize = Listengroesse');
    Bmp := PaintImage(A);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[8, 8], clRed), 'rot');
    finally
      Bmp.Free;
    end;
    A.AutoSize := False;
    A.SetBounds(0, 0, 64, 64);
    A.Stretch := True;
    Bmp := PaintImage(A);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[50, 50], clRed, 16), 'gestreckt rot');
    finally
      Bmp.Free;
    end;
    A.Images := nil;
  finally
    L.Free;
  end;
end;

procedure TImageTests.ImageListDisabled;
var
  A: TPPGImage;
  L: TImageList;
  Bmp: TBitmap;
  C: TColor;
begin
  L := RedBlueList(16);
  try
    A := NewImage;
    A.Images := L;
    A.ImageIndex := 0;
    A.Stretch := True;
    A.SetBounds(0, 0, 32, 32);
    A.Enabled := False;
    Bmp := PaintImage(A);
    try
      C := Bmp.Canvas.Pixels[16, 16];
      CheckFalse(Near(C, clRed, 40), 'nicht mehr rot');
      CheckTrue(Abs(RgbOf(C, 0) - RgbOf(C, 8)) < 6, 'grau');
    finally
      Bmp.Free;
    end;
    A.Images := nil;
  finally
    L.Free;
  end;
end;

procedure TImageTests.DarkImageIndex;
var
  A: TPPGImage;
  L: TImageList;
  Bmp: TBitmap;
  Saved: TPPGThemeMode;
begin
  L := RedBlueList(16);
  Saved := TPPGTheme.Mode;
  try
    A := NewImage;
    A.Images := L;
    A.ImageIndex := 0;
    A.ImageIndexDark := 1;
    TPPGTheme.Mode := tmLight;
    Bmp := PaintImage(A);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[8, 8], clRed), 'hell');
    finally
      Bmp.Free;
    end;
    TPPGTheme.Mode := tmDark;
    Bmp := PaintImage(A);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[8, 8], clBlue), 'dunkel');
    finally
      Bmp.Free;
    end;
    A.Images := nil;
  finally
    TPPGTheme.Mode := Saved;
    L.Free;
  end;
end;

procedure TImageTests.ImageNameResolvesAndStreamsName;
{$IFDEF PPG_HAS_IMAGENAME}
var
  Coll: TImageCollection;
  VList: TVirtualImageList;
  A, B: TPPGImage;
  Dir, F1, F2, T: string;
begin
  Dir := TPath.Combine(TPath.GetTempPath, 'ppgimgtest' + IntToStr(GetCurrentProcessId));
  ForceDirectories(Dir);
  try
    F1 := TPath.Combine(Dir, 'a.png');
    F2 := TPath.Combine(Dir, 'b.png');
    TFile.WriteAllBytes(F1, ImageBytes(ifPng, clRed, 16, 16));
    TFile.WriteAllBytes(F2, ImageBytes(ifPng, clBlue, 16, 16));
    Coll := TImageCollection.Create(FForm);
    Coll.Add('red', F1);
    Coll.Add('blue', F2);
    VList := TVirtualImageList.Create(FForm);
    VList.SetSize(16, 16);
    VList.ImageCollection := Coll;
    VList.AutoFill := True;
    A := NewImage;
    A.Images := VList;
    A.ImageName := 'blue';
    CheckEquals(1, A.ImageIndex, 'Name -> Index');
    A.ImageNameDark := 'red';
    CheckEquals(0, A.ImageIndexDark, 'Dark-Name -> Index');
    T := ComponentToText(A);
    CheckTrue(Pos('ImageName = ''blue''', T) > 0, 'Name wird gespeichert');
    CheckTrue(Pos('ImageIndex =', T) = 0, 'Index nicht: ' + T);
    B := TPPGImage.Create(FForm);
    B.Parent := FForm;
    B.Images := VList;
    B.ImageName := 'red';
    CheckEquals(0, B.ImageIndex);
    B.ImageName := 'gibt es nicht';
    CheckEquals(-1, B.ImageIndex, 'unbekannter Name: kein Bild, kein Fehler');
    A.Images := nil;
    B.Images := nil;
  finally
    TDirectory.Delete(Dir, True);
  end;
end;
{$ELSE}
begin
  Skip('ImageName ab Delphi 10.4');
end;
{$ENDIF}

procedure TImageTests.ImageListFreedDetaches;
var
  A: TPPGImage;
  L: TImageList;
begin
  L := RedBlueList(16);
  A := NewImage;
  A.Images := L;
  A.ImageIndex := 1;
  L.Free;
  CheckNull(A.Images, 'Images wird geloest');
  PaintImage(A).Free;
end;

procedure TImageTests.BorderFrameFollowsTheme;
var
  A: TPPGImage;
  Bmp: TBitmap;
  Light, Dark: TColor;
  Saved: TPPGThemeMode;
begin
  A := NewImage;
  A.BorderStyle := bsSingle;
  Saved := TPPGTheme.Mode;
  try
    TPPGTheme.Mode := tmLight;
    Bmp := PaintImage(A);
    try
      Light := Bmp.Canvas.Pixels[0, 10];
      CheckFalse(Near(Light, clWhite, 10), 'Rahmen sichtbar');
      CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clWhite), 'innen leer');
    finally
      Bmp.Free;
    end;
    TPPGTheme.Mode := tmDark;
    Bmp := PaintImage(A);
    try
      Dark := Bmp.Canvas.Pixels[0, 10];
    finally
      Bmp.Free;
    end;
    CheckFalse(Near(Light, Dark, 4), 'Randfarbe folgt dem Theme');
  finally
    TPPGTheme.Mode := Saved;
  end;
  A.BorderStyle := bsNone;
  Bmp := PaintImage(A);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[0, 10], clWhite), 'ohne Rahmen');
  finally
    Bmp.Free;
  end;
end;

procedure TImageTests.CanvasCreatesBitmap;
var
  A: TPPGImage;
  Bmp: TBitmap;
begin
  A := NewImage;
  A.Canvas.Brush.Color := clLime;
  A.Canvas.FillRect(Rect(0, 0, 40, 30));
  CheckTrue(A.Picture.Graphic is TBitmap);
  Bmp := PaintImage(A);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[10, 10], clLime));
  finally
    Bmp.Free;
  end;
end;

procedure TImageTests.InvalidImageIndexIsRejected;
var
  A: TPPGImage;
begin
  A := NewImage;
  try
    A.ImageIndex := -5;
    Fail('negativer Index muss abgelehnt werden');
  except
    on EPPGPropertyError do
      ExpectErrors;
  end;
end;

{ TDBImageCase }

procedure TDBImageCase.SetUp;
begin
  inherited SetUp;
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Pic', ftBlob);
  FData.CreateDataSet;
  FData.AppendRecord([1, Null]);
  FData.AppendRecord([2, Null]);
  FData.AppendRecord([3, Null]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

function TDBImageCase.Blob: TBlobField;
begin
  Result := FData.FieldByName('Pic') as TBlobField;
end;

procedure TDBImageCase.PutBytes(const Bytes: TBytes);
var
  MS: TBytesStream;
begin
  FData.Edit;
  if Length(Bytes) = 0 then
    Blob.Clear
  else
  begin
    MS := TBytesStream.Create(Bytes);
    try
      Blob.LoadFromStream(MS);
    finally
      MS.Free;
    end;
  end;
  FData.Post;
end;

function TDBImageCase.NewImage: TPPGDBImage;
begin
  Result := TPPGDBImage.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 40, 30);
  Result.BorderStyle := bsNone;
  Result.Stretch := True;
  Result.DataSource := FSource;
  Result.DataField := 'Pic';
end;

function TDBImageCase.Paint(C: TPPGDBImage): TBitmap;
begin
  Result := RenderToBitmap(C);
end;

{ TDBImageTests }

procedure TDBImageTests.LoadsTDBImageDfm;
const
  Dfm =
    'object DBImage1: TPPGDBImage'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 105'#13#10 +
    '  Height = 105'#13#10 +
    '  AutoDisplay = False'#13#10 +
    '  BorderStyle = bsNone'#13#10 +
    '  Center = True'#13#10 +
    '  Ctl3D = False'#13#10 +
    '  DataField = ''Pic'''#13#10 +
    '  DataSource = DataSource1'#13#10 +
    '  ParentCtl3D = False'#13#10 +
    '  Proportional = True'#13#10 +
    '  QuickDraw = False'#13#10 +
    '  ReadOnly = True'#13#10 +
    '  Stretch = True'#13#10 +
    '  TabOrder = 0'#13#10 +
    'end';
var
  I: TPPGDBImage;
begin
  I := TPPGDBImage.Create(FForm);
  LoadFromDfm(I, Dfm);
  I.Parent := FForm;
  CheckFalse(I.AutoDisplay);
  CheckTrue(I.BorderStyle = bsNone);
  CheckTrue(I.Center and I.Proportional and I.Stretch and I.ReadOnly);
  CheckFalse(I.QuickDraw);
  CheckEquals('Pic', I.DataField);
end;

procedure TDBImageTests.StreamsOnlyWhatIsNeeded;
var
  I: TPPGDBImage;
  T: string;
begin
  I := TPPGDBImage.Create(FForm);
  T := ComponentToText(I);
  CheckTrue(Pos('Picture', T) = 0, 'Bild gehoert den Daten: ' + T);
  CheckTrue(Pos('BorderStyle', T) = 0);
  CheckTrue(Pos('AutoDisplay', T) = 0);
  CheckTrue(Pos('QuickDraw', T) = 0);
  CheckTrue(Pos('StoreFormat', T) = 0);
  CheckTrue(Pos('Color', T) = 0);
  CheckTrue(Pos('TabStop', T) = 0);
  I := NewImage;
  PutBytes(ImageBytes(ifPng, clRed));
  T := ComponentToText(I);
  CheckTrue(Pos('Picture', T) = 0, 'Bild aus dem Feld wird nicht gespeichert');
end;

procedure TDBImageTests.ShowsEachFormatAndScrolls;
var
  I: TPPGDBImage;
  Bmp: TBitmap;
begin
  I := NewImage;
  FData.First;
  PutBytes(ImageBytes(ifBitmap, clRed));
  FData.Next;
  PutBytes(ImageBytes(ifPng, clBlue));
  FData.Next;
  PutBytes(ImageBytes(ifGif, clLime));
  FData.First;
  CheckTrue(I.ImageFormat = ifBitmap);
  Bmp := Paint(I);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clRed), 'BMP');
  finally
    Bmp.Free;
  end;
  FData.Next;
  CheckTrue(I.ImageFormat = ifPng);
  Bmp := Paint(I);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clBlue), 'PNG');
  finally
    Bmp.Free;
  end;
  FData.Next;
  CheckTrue(I.ImageFormat = ifGif);
  Bmp := Paint(I);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clLime, 16), 'GIF');
  finally
    Bmp.Free;
  end;
  // JPEG (verlustbehaftet)
  FData.First;
  PutBytes(ImageBytes(ifJpeg, clRed, 16, 16));
  CheckTrue(I.ImageFormat = ifJpeg);
  Bmp := Paint(I);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clRed, 40), 'JPEG');
  finally
    Bmp.Free;
  end;
end;

procedure TDBImageTests.NullAndGarbageShowNothing;
var
  I: TPPGDBImage;
  Bmp: TBitmap;
begin
  I := NewImage;
  CheckTrue(I.ImageFormat = ifNone, 'Null');
  CheckTrue((I.Picture.Graphic = nil) or I.Picture.Graphic.Empty);
  FData.Next;
  PutBytes(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8, 9));
  CheckTrue(I.ImageFormat = ifUnknown, 'Muell wird gemeldet');
  Bmp := Paint(I);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], I.Color, 4), 'nur Hintergrund');
  finally
    Bmp.Free;
  end;
  CheckFalse(FData.State in [dsEdit, dsInsert], 'Anzeige aendert nichts');
end;

procedure TDBImageTests.AutoDisplayFalseLoadsOnDemand;
var
  I: TPPGDBImage;
  K: Char;
  Bmp: TBitmap;
begin
  PutBytes(ImageBytes(ifBitmap, clRed));
  I := NewImage;
  I.AutoDisplay := False;
  FData.First;
  FData.Next;
  FData.Prior;
  CheckTrue((I.Picture.Graphic = nil) or I.Picture.Graphic.Empty, 'nicht geladen');
  Bmp := Paint(I);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[1, 1], I.Color, 4));
  finally
    Bmp.Free;
  end;
  K := #13;
  TDBImageCrack(I).KeyPress(K);
  CheckFalse(I.Picture.Graphic.Empty, 'Enter laedt');
  Bmp := Paint(I);
  try
    CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clRed), 'Bild sichtbar');
  finally
    Bmp.Free;
  end;
  I.AutoDisplay := True;
  FData.Next;
  FData.Prior;
  CheckFalse(I.Picture.Graphic.Empty, 'AutoDisplay laedt wieder');
end;

procedure TDBImageTests.LoadFromFileEditsAndPosts;
var
  I: TPPGDBImage;
  F: string;
  Bytes: TBytes;
begin
  I := NewImage;
  F := TPath.Combine(TPath.GetTempPath, 'ppgdbimg' + IntToStr(GetCurrentProcessId) + '.png');
  TFile.WriteAllBytes(F, ImageBytes(ifPng, clGreen, 12, 12));
  try
    I.LoadFromFile(F);
  finally
    TFile.Delete(F);
  end;
  CheckTrue(FData.State = dsEdit, 'Datensatz im Bearbeiten-Modus');
  FData.Post;
  Bytes := Blob.AsBytes;
  CheckTrue(PPGDetectImageFormat(Bytes) = ifPng, 'PNG im Feld');
  CheckTrue(I.ImageFormat = ifPng);
  CheckEquals(12, I.Picture.Width);
end;

procedure TDBImageTests.LoadFromStreamUnknownRaises;
var
  I: TPPGDBImage;
  MS: TBytesStream;
begin
  I := NewImage;
  MS := TBytesStream.Create(TBytes.Create(1, 2, 3, 4, 5, 6, 7, 8));
  try
    try
      I.LoadFromStream(MS);
      Fail('unbekanntes Format muss melden');
    except
      on E: EPPGError do
        CheckTrue(E.Message <> '');
    end;
  finally
    MS.Free;
  end;
  CheckFalse(FData.State in [dsEdit, dsInsert], 'nichts veraendert');
end;

procedure TDBImageTests.StoreFormatConverts;
var
  I: TPPGDBImage;
  B: TBitmap;
begin
  I := NewImage;
  I.StoreFormat := sfPng;
  B := MakeBmp(clRed, 10, 10);
  try
    I.Picture.Assign(B);
  finally
    B.Free;
  end;
  FData.Post;
  CheckTrue(PPGDetectImageFormat(Blob.AsBytes) = ifPng, 'als PNG gespeichert');
  I.StoreFormat := sfKeep;
  B := MakeBmp(clBlue, 10, 10);
  try
    I.Picture.Assign(B);
  finally
    B.Free;
  end;
  FData.Post;
  CheckTrue(PPGDetectImageFormat(Blob.AsBytes) = ifBitmap, 'sfKeep: wie das Bild');
end;

procedure TDBImageTests.PasteWritesField;
var
  I: TPPGDBImage;
  B: TBitmap;
begin
  I := NewImage;
  B := MakeBmp(clGreen, 10, 10);
  try
    try
      Clipboard.Assign(B);
    except
      on Exception do
      begin
        Skip('Zwischenablage nicht verfuegbar');
        Exit;
      end;
    end;
  finally
    B.Free;
  end;
  I.PasteFromClipboard;
  CheckTrue(FData.State = dsEdit, 'Einfuegen bearbeitet den Datensatz');
  FData.Post;
  CheckTrue(PPGDetectImageFormat(Blob.AsBytes) = ifBitmap);
  I.CopyToClipboard; // darf nicht fehlschlagen
end;

procedure TDBImageTests.CutClearsField;
var
  I: TPPGDBImage;
begin
  PutBytes(ImageBytes(ifPng, clRed));
  I := NewImage;
  try
    I.CutToClipboard;
  except
    on Exception do
    begin
      Skip('Zwischenablage nicht verfuegbar');
      Exit;
    end;
  end;
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckTrue(Blob.IsNull, 'Feld leer');
  CheckTrue(I.ImageFormat = ifNone);
end;

procedure TDBImageTests.ReadOnlyRejectsChange;
var
  I: TPPGDBImage;
  B: TBitmap;
begin
  PutBytes(ImageBytes(ifPng, clRed));
  I := NewImage;
  I.ReadOnly := True;
  B := MakeBmp(clBlue, 8, 8);
  try
    I.Picture.Assign(B);
  finally
    B.Free;
  end;
  CheckFalse(FData.State in [dsEdit, dsInsert], 'ReadOnly: kein Bearbeiten');
  CheckTrue(I.ImageFormat = ifPng, 'altes Bild wieder da');
end;

procedure TDBImageTests.EscapeRestores;
var
  I: TPPGDBImage;
  B: TBitmap;
  Key: Word;
begin
  PutBytes(ImageBytes(ifPng, clRed));
  I := NewImage;
  B := MakeBmp(clBlue, 8, 8);
  try
    I.Picture.Assign(B);
  finally
    B.Free;
  end;
  CheckTrue(FData.State = dsEdit);
  CheckTrue(I.ImageFormat = ifBitmap);
  Key := VK_ESCAPE;
  TDBImageCrack(I).KeyDown(Key, []);
  CheckEquals(0, Key, 'Esc verbraucht');
  CheckTrue(I.ImageFormat = ifPng, 'zurueckgesetzt');
  FData.Cancel;
  CheckTrue(PPGDetectImageFormat(Blob.AsBytes) = ifPng);
end;

procedure TDBImageTests.PlaceholderForNullField;
var
  I: TPPGDBImage;
  L: TImageList;
  Bmp: TBitmap;
  B: TBitmap;
begin
  L := TImageList.CreateSize(8, 8);
  try
    B := MakeBmp(clFuchsia, 8, 8);
    try
      L.Add(B, nil);
    finally
      B.Free;
    end;
    I := NewImage;
    I.Stretch := False;
    I.Center := True;
    I.Images := L;
    I.ImageIndex := 0;
    Bmp := Paint(I);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clFuchsia), 'Platzhalter bei Null');
    finally
      Bmp.Free;
    end;
    PutBytes(ImageBytes(ifPng, clRed, 40, 30));
    Bmp := Paint(I);
    try
      CheckTrue(Near(Bmp.Canvas.Pixels[20, 15], clRed), 'Datenbild vor Platzhalter');
    finally
      Bmp.Free;
    end;
    I.Images := nil;
  finally
    L.Free;
  end;
end;

procedure TDBImageTests.DataSourceFreedDetaches;
var
  I: TPPGDBImage;
  S: TDataSource;
begin
  S := TDataSource.Create(nil);
  S.DataSet := FData;
  I := NewImage;
  I.DataSource := S;
  S.Free;
  CheckNull(I.DataSource);
  RenderToBitmap(I).Free;
end;

procedure TDBImageTests.SaveToFileKeepsFormat;
var
  I: TPPGDBImage;
  F: string;
  Bytes: TBytes;
begin
  PutBytes(ImageBytes(ifGif, clRed, 9, 9));
  I := NewImage;
  F := TPath.Combine(TPath.GetTempPath, 'ppgdbimgs' + IntToStr(GetCurrentProcessId) + '.bin');
  try
    I.SaveToFile(F);
    Bytes := TFile.ReadAllBytes(F);
    CheckTrue(PPGDetectImageFormat(Bytes) = ifGif, 'GIF bleibt GIF');
    I.SaveToFile(F, sfPng);
    Bytes := TFile.ReadAllBytes(F);
    CheckTrue(PPGDetectImageFormat(Bytes) = ifPng, 'als PNG');
  finally
    if TFile.Exists(F) then
      TFile.Delete(F);
  end;
end;

initialization
  RegisterTest('Image', TImageFormatTests.Suite);
  RegisterTest('Image', TImageTests.Suite);
  RegisterTest('Image', TDBImageTests.Suite);

end.
