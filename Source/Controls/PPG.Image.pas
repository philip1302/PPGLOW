unit PPG.Image;

{ TPPGImage - Bildanzeige (Ersatz fuer TImage), dazu die gemeinsame Zeichen-
  und Quellenlogik (TPPGImageView), die auch TPPGDBImage nutzt.

  Grafisches Control wie TImage (kein Fensterhandle) und DFM-kompatibel:
  Picture, Stretch, Proportional, Center, Transparent, AutoSize und
  IncrementalDisplay heissen und streamen wie in der VCL, damit ein Tausch im
  Formular ohne Nacharbeit geht (Build\migrate.ps1).

  Mehrwert gegenueber TImage:
  - Bildlisten: Images/ImageIndex/ImageName wie bei den anderen Controls
    (TImageCollection/TVirtualImageList ab 10.4). Eine Bildliste skaliert sich
    selbst mit der DPI; das Bild wird in ihrer Groesse gezeichnet, mit Stretch
    und Proportional eingepasst.
  - Dunkelmodus: PictureDark bzw. ImageIndexDark/ImageNameDark ersetzen das
    Bild im Dark Mode (ohne Eintrag bleibt das helle Bild).
  - Rahmen: BorderStyle = bsSingle zeichnet einen Rand in der Randfarbe des
    Themes (Dark Mode, Hochkontrast, deaktiviert).
  - Deaktiviert: Enabled = False zeigt das Bild grau und blasser.
  - DpiScaling: Bilder aus Picture werden mit der DPI des Controls
    vergroessert (natuerliche Groesse, AutoSize); Vorgabe aus wie bei TImage.

  Formate: BMP, ICO und WMF/EMF liest die VCL selbst, PNG, JPEG, GIF und TIFF
  das TWICImage der VCL. Es wird kein Vcl.Imaging.* benutzt, damit PPGlowR
  das Paket vclimg nicht braucht.

  Zeichnen: Grafiken laufen ueber Canvas.StretchDraw wie bei TImage (PNG mit
  Alpha, JPEG, GIF, TIFF ueber WIC, Icon, Metafile). Nur die deaktivierte Darstellung und
  skalierte Bildlisten-Bilder werden vorher in ein Bild mit Alpha gerechnet
  (zweimal auf Schwarz und Weiss gezeichnet), das geht mit jeder Grafikart.

  Nicht uebernommen: animierte GIFs (das erste Bild wird gezeigt). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  {$IFDEF PPG_HAS_IMAGENAME}System.UITypes,{$ENDIF}
  Vcl.Controls, Vcl.Graphics, Vcl.ImgList, Vcl.ExtCtrls, Vcl.Forms,
  PPG.Types;

type
  /// Grafikformat eines BLOBs bzw. einer Datei.
  TPPGImageFormat = (ifNone, ifUnknown, ifBitmap, ifPng, ifJpeg, ifGif, ifIcon, ifMetafile, ifTiff);

  /// Format, in dem TPPGDBImage Bilder ins Feld schreibt. sfKeep: das Format der
  /// Grafik (BMP, PNG, JPEG, GIF, ICO, WMF/EMF bleiben, wie sie sind).
  TPPGImageStoreFormat = (sfKeep, sfBitmap, sfPng, sfJpeg, sfGif);

  /// Zeichnet in R auf C (fuer RenderPremult).
  TPPGImageDrawProc = reference to procedure(C: TCanvas; const R: TRect);

  /// Bildquellen, Platzierung, Rahmen und Zeichnen, gemeinsam fuer TPPGImage
  /// und TPPGDBImage. Der Besitzer reicht Notification und Loaded durch.
  TPPGImageView = class
  private
    FOwner: TControl;
    FOnChange: TNotifyEvent;
    FOnPictureChange: TNotifyEvent;
    FPicture: TPicture;
    FPictureDark: TPicture;
    FImages: TCustomImageList;
    FChangeLink: TChangeLink;
    FImageIndex: TPPGImageIndex;
    FImageIndexDark: TPPGImageIndex;
    {$IFDEF PPG_HAS_IMAGENAME}
    FImageName: TImageName;
    FImageNameDark: TImageName;
    {$ENDIF}
    FStretch: Boolean;
    FProportional: Boolean;
    FCenter: Boolean;
    FTransparent: Boolean;
    FDpiScaling: Boolean;
    FBorderStyle: TBorderStyle;
    procedure Changed;
    procedure ResolveNames;
    procedure PictureChange(Sender: TObject);
    procedure ImagesChange(Sender: TObject);
    procedure ApplyTransparent(P: TPicture);
    procedure SetPicture(Value: TPicture);
    procedure SetPictureDark(Value: TPicture);
    procedure SetImages(const Value: TCustomImageList);
    procedure SetStretch(const Value: Boolean);
    procedure SetProportional(const Value: Boolean);
    procedure SetCenter(const Value: Boolean);
    procedure SetTransparent(const Value: Boolean);
    procedure SetDpiScaling(const Value: Boolean);
    procedure SetBorderStyle(const Value: TBorderStyle);
    function GetImageIndex(Index: Integer): TPPGImageIndex;
    procedure SetImageIndex(Index: Integer; const Value: TPPGImageIndex);
    {$IFDEF PPG_HAS_IMAGENAME}
    function GetImageName(Index: Integer): TImageName;
    procedure SetImageName(Index: Integer; const Value: TImageName);
    {$ENDIF}
    function ScaleToPPI(Value: Integer): Integer;
    procedure DrawGraphic(ACanvas: TCanvas; G: TGraphic; const D: TRect; AEnabled: Boolean);
    procedure DrawListImage(ACanvas: TCanvas; Idx, NW, NH: Integer; const D: TRect;
      AEnabled: Boolean);
  public
    constructor Create(AOwner: TControl; AOnChange: TNotifyEvent; ABorderStyle: TBorderStyle);
    destructor Destroy; override;
    /// Aus Notification des Besitzers: freigegebene Bildliste loesen.
    procedure Notification(AComponent: TComponent; Operation: TOperation);
    /// Aus Loaded des Besitzers: Namen in Indizes aufloesen.
    procedure Loaded;
    /// True, wenn Bildnamen verfuegbar sind (Bildliste mit Namen, ab 10.4).
    function ImageNameAvailable: Boolean;
    function IsImageIndexStored(Dark: Boolean): Boolean;
    function IsImageNameStored(Dark: Boolean): Boolean;
    /// Dunkle Darstellung aktiv (Dark Mode der Suite, nicht im Hochkontrast).
    function IsDarkActive: Boolean;
    /// Die zu zeichnende Grafik aus Picture/PictureDark (nil = keine).
    function ActiveGraphic: TGraphic;
    /// Der zu zeichnende Bildlisten-Index (-1 = keiner).
    function ActiveIndex: Integer;
    /// True, wenn irgendeine Quelle ein Bild liefert.
    function HasImage: Boolean;
    /// Natuerliche Groesse des aktiven Bilds (0 = keins), mit DpiScaling.
    function NaturalSize: TSize;
    /// Breite des Rahmens in Pixeln (0 ohne Rahmen).
    function FrameWidth: Integer;
    /// Der Bereich innerhalb des Rahmens.
    function ContentRect(const AClient: TRect): TRect;
    /// Wohin das Bild gezeichnet wird (wie TImage.DestRect, innerhalb des Rahmens).
    function DestRect(const AClient: TRect): TRect;
    /// True, wenn das Bild den ganzen Bereich undurchsichtig ueberdeckt.
    function CoversOpaque(const AClient: TRect): Boolean;
    /// Randfarbe des Themes.
    function FrameColor(AEnabled: Boolean): TColor;
    procedure PaintFrame(ACanvas: TCanvas; const AClient: TRect; AEnabled: Boolean);
    /// Rahmen und Bild.
    procedure Paint(ACanvas: TCanvas; const AClient: TRect; AEnabled: Boolean);
    property Owner: TControl read FOwner;
    /// Nur wenn sich Picture (nicht PictureDark) aendert.
    property OnPictureChange: TNotifyEvent read FOnPictureChange write FOnPictureChange;
    property Picture: TPicture read FPicture write SetPicture;
    property PictureDark: TPicture read FPictureDark write SetPictureDark;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageIndex: TPPGImageIndex index 0 read GetImageIndex write SetImageIndex;
    property ImageIndexDark: TPPGImageIndex index 1 read GetImageIndex write SetImageIndex;
    {$IFDEF PPG_HAS_IMAGENAME}
    property ImageName: TImageName index 0 read GetImageName write SetImageName;
    property ImageNameDark: TImageName index 1 read GetImageName write SetImageName;
    {$ENDIF}
    property Stretch: Boolean read FStretch write SetStretch;
    property Proportional: Boolean read FProportional write SetProportional;
    property Center: Boolean read FCenter write SetCenter;
    property Transparent: Boolean read FTransparent write SetTransparent;
    property DpiScaling: Boolean read FDpiScaling write SetDpiScaling;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle;
  end;

  TPPGImage = class(TGraphicControl)
  private
    FView: TPPGImageView;
    FIncrementalDisplay: Boolean;
    FOnProgress: TProgressEvent;
    procedure ViewChanged(Sender: TObject);
    procedure PictureProgress(Sender: TObject; Stage: TProgressStage;
      PercentDone: Byte; RedrawNow: Boolean; const R: TRect; const Msg: string);
    procedure UpdateOpaque;
    function GetCanvas: TCanvas;
    function GetPicture: TPicture;
    procedure SetPicture(Value: TPicture);
    function GetPictureDark: TPicture;
    procedure SetPictureDark(Value: TPicture);
    function GetImages: TCustomImageList;
    procedure SetImages(const Value: TCustomImageList);
    function GetImageIndex: TPPGImageIndex;
    procedure SetImageIndex(const Value: TPPGImageIndex);
    function GetImageIndexDark: TPPGImageIndex;
    procedure SetImageIndexDark(const Value: TPPGImageIndex);
    function IsImageIndexStored: Boolean;
    function IsImageIndexDarkStored: Boolean;
    {$IFDEF PPG_HAS_IMAGENAME}
    function GetImageName: TImageName;
    procedure SetImageName(const Value: TImageName);
    function GetImageNameDark: TImageName;
    procedure SetImageNameDark(const Value: TImageName);
    function IsImageNameStored: Boolean;
    function IsImageNameDarkStored: Boolean;
    {$ENDIF}
    function GetStretch: Boolean;
    procedure SetStretch(const Value: Boolean);
    function GetProportional: Boolean;
    procedure SetProportional(const Value: Boolean);
    function GetCenter: Boolean;
    procedure SetCenter(const Value: Boolean);
    function GetTransparent: Boolean;
    procedure SetTransparent(const Value: Boolean);
    function GetDpiScaling: Boolean;
    procedure SetDpiScaling(const Value: Boolean);
    function GetBorderStyle: TBorderStyle;
    procedure SetBorderStyle(const Value: TBorderStyle);
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure Paint; override;
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure WndProc(var Message: TMessage); override;
    function CanAutoSize(var NewWidth, NewHeight: Integer): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Wohin das Bild gezeichnet wird (Stretch, Proportional, Center, Rahmen).
    function DestRect: TRect;
    /// Zeichenflaeche des Bitmaps in Picture (wie TImage.Canvas; legt bei
    /// Bedarf ein leeres Bitmap in Controlgroesse an).
    property Canvas: TCanvas read GetCanvas;
  published
    property Picture: TPicture read GetPicture write SetPicture;
    /// Bild im Dark Mode; leer = das helle Bild bleibt.
    property PictureDark: TPicture read GetPictureDark write SetPictureDark;
    property Images: TCustomImageList read GetImages write SetImages;
    property ImageIndex: TPPGImageIndex read GetImageIndex write SetImageIndex
      stored IsImageIndexStored default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    property ImageName: TImageName read GetImageName write SetImageName stored IsImageNameStored;
    {$ENDIF}
    /// Bild aus Images im Dark Mode; -1 = das helle Bild bleibt.
    property ImageIndexDark: TPPGImageIndex read GetImageIndexDark write SetImageIndexDark
      stored IsImageIndexDarkStored default -1;
    {$IFDEF PPG_HAS_IMAGENAME}
    property ImageNameDark: TImageName read GetImageNameDark write SetImageNameDark
      stored IsImageNameDarkStored;
    {$ENDIF}
    property Stretch: Boolean read GetStretch write SetStretch default False;
    property Proportional: Boolean read GetProportional write SetProportional default False;
    property Center: Boolean read GetCenter write SetCenter default False;
    property Transparent: Boolean read GetTransparent write SetTransparent default False;
    /// True: Bilder aus Picture in der natuerlichen Groesse mit der DPI des Controls
    /// vergroessern (Bildlisten skalieren sich selbst).
    property DpiScaling: Boolean read GetDpiScaling write SetDpiScaling default False;
    /// bsSingle: Rand in der Randfarbe des Themes.
    property BorderStyle: TBorderStyle read GetBorderStyle write SetBorderStyle default bsNone;
    /// Ohne Wirkung (Kompatibilitaet mit TImage).
    property IncrementalDisplay: Boolean read FIncrementalDisplay write FIncrementalDisplay
      default False;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    { wie TImage }
    property Align;
    property Anchors;
    property AutoSize;
    property Constraints;
    property DragCursor;
    property DragKind;
    property DragMode;
    property Enabled;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property Touch;
    property Visible;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnEndDrag;
    property OnGesture;
    property OnMouseActivate;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
    property OnStartDrag;
  end;

/// Erkennt das Grafikformat an den ersten Bytes (BMP, PNG, JPEG, GIF, TIFF, ICO,
/// WMF/EMF). Leer = ifNone, sonst ifUnknown.
function PPGDetectImageFormat(const Data: TBytes): TPPGImageFormat; overload;
function PPGDetectImageFormat(Stream: TStream): TPPGImageFormat; overload;
/// Neue, leere Grafik zum Format (nil bei ifNone/ifUnknown). Aufrufer gibt frei.
function PPGCreateGraphic(Format: TPPGImageFormat): TGraphic;
/// Format einer vorhandenen Grafik (ifNone bei nil oder leer).
function PPGGraphicFormat(G: TGraphic): TPPGImageFormat;
/// Laedt Bilddaten; das Format wird erkannt. nil bei unbekanntem Format oder
/// Ladefehler (Format meldet dann ifUnknown bzw. ifNone). Aufrufer gibt frei.
function PPGLoadGraphic(Stream: TStream; out Format: TPPGImageFormat): TGraphic;
/// Laedt Bilddaten direkt in die Grafik von Picture (ohne Kopieren einer geladenen
/// Grafik). False bei unbekanntem Format oder Ladefehler; Picture ist dann leer.
function PPGLoadPicture(Picture: TPicture; Stream: TStream; out Format: TPPGImageFormat): Boolean;
/// Schreibt die Grafik in das gewaehlte Format (sfKeep: eigenes Format).
procedure PPGSaveGraphic(G: TGraphic; Format: TPPGImageStoreFormat; Stream: TStream);
/// Rechnet eine Zeichnung in ein 32-Bit-Bild mit vormultipliziertem Alpha:
/// Draw laeuft einmal auf Schwarz und einmal auf Weiss, daraus ergeben sich
/// Alpha und Farbe. Disabled: grau und halb durchsichtig. Aufrufer gibt frei.
function PPGRenderPremult(W, H: Integer; const Draw: TPPGImageDrawProc;
  Disabled: Boolean): TBitmap;

implementation

uses
  System.Math, Vcl.Consts,
  PPG.Lang, PPG.Consts, PPG.Exceptions, PPG.Appearance, PPG.DpiUtils, PPG.VclStyles,
  PPG.Theme, PPG.Tokens, PPG.Render.Intf, PPG.Render.Registry;

type
  PQuadArray = ^TQuadArray;
  TQuadArray = array[0..65535] of TRGBQuad;

{ Formate }

function PPGDetectImageFormat(const Data: TBytes): TPPGImageFormat;
var
  N: Integer;
begin
  N := Length(Data);
  if N = 0 then
    Exit(ifNone);
  Result := ifUnknown;
  if (N >= 2) and (Data[0] = $42) and (Data[1] = $4D) then
    Result := ifBitmap
  else if (N >= 8) and (Data[0] = $89) and (Data[1] = $50) and (Data[2] = $4E) and
    (Data[3] = $47) and (Data[4] = $0D) and (Data[5] = $0A) and (Data[6] = $1A) and
    (Data[7] = $0A) then
    Result := ifPng
  else if (N >= 3) and (Data[0] = $FF) and (Data[1] = $D8) and (Data[2] = $FF) then
    Result := ifJpeg
  else if (N >= 4) and (Data[0] = $47) and (Data[1] = $49) and (Data[2] = $46) and
    (Data[3] = $38) then
    Result := ifGif
  else if (N >= 4) and (((Data[0] = $49) and (Data[1] = $49) and (Data[2] = $2A) and
    (Data[3] = 0)) or ((Data[0] = $4D) and (Data[1] = $4D) and (Data[2] = 0) and
    (Data[3] = $2A))) then
    Result := ifTiff
  else if (N >= 4) and (Data[0] = 0) and (Data[1] = 0) and (Data[2] = 1) and (Data[3] = 0) then
    Result := ifIcon
  else if (N >= 4) and (Data[0] = $D7) and (Data[1] = $CD) and (Data[2] = $C6) and
    (Data[3] = $9A) then
    Result := ifMetafile // WMF mit Placeable-Kopf
  else if (N >= 44) and (Data[0] = 1) and (Data[1] = 0) and (Data[2] = 0) and (Data[3] = 0) and
    (Data[40] = $20) and (Data[41] = $45) and (Data[42] = $4D) and (Data[43] = $46) then
    Result := ifMetafile; // EMF
end;

function PPGDetectImageFormat(Stream: TStream): TPPGImageFormat;
var
  Pos: Int64;
  Buf: TBytes;
  N: Integer;
begin
  Pos := Stream.Position;
  try
    SetLength(Buf, 64);
    N := Stream.Read(Buf[0], Length(Buf));
    SetLength(Buf, N);
    Result := PPGDetectImageFormat(Buf);
  finally
    Stream.Position := Pos;
  end;
end;

function PPGCreateGraphic(Format: TPPGImageFormat): TGraphic;
begin
  case Format of
    ifBitmap: Result := TBitmap.Create;
    // PNG, JPEG, GIF und TIFF decodiert WIC (in der VCL), so braucht PPGlowR kein vclimg
    ifPng, ifJpeg, ifGif, ifTiff: Result := TWICImage.Create;
    ifIcon: Result := TIcon.Create;
    ifMetafile: Result := TMetafile.Create;
  else
    Result := nil;
  end;
end;

function PPGGraphicFormat(G: TGraphic): TPPGImageFormat;
begin
  if (G = nil) or G.Empty then
    Result := ifNone
  else if G is TBitmap then
    Result := ifBitmap
  else if G is TWICImage then
  begin
    case TWICImage(G).ImageFormat of
      wifBmp: Result := ifBitmap;
      wifPng: Result := ifPng;
      wifJpeg: Result := ifJpeg;
      wifGif: Result := ifGif;
      wifTiff: Result := ifTiff;
    else
      Result := ifUnknown;
    end;
  end
  else if G is TIcon then
    Result := ifIcon
  else if G is TMetafile then
    Result := ifMetafile
  else
    Result := ifUnknown;
end;

function PPGLoadGraphic(Stream: TStream; out Format: TPPGImageFormat): TGraphic;
var
  Pos: Int64;
begin
  Pos := Stream.Position;
  Format := PPGDetectImageFormat(Stream);
  Result := PPGCreateGraphic(Format);
  if Result = nil then
    Exit;
  try
    Stream.Position := Pos;
    Result.LoadFromStream(Stream);
  except
    // Grenze: beliebige Bilddaten aus einem Feld; jeder Ladefehler heisst "kein Bild"
    on Exception do
    begin
      FreeAndNil(Result);
      Format := ifUnknown;
    end;
  end;
end;

function PPGLoadPicture(Picture: TPicture; Stream: TStream; out Format: TPPGImageFormat): Boolean;
var
  Pos: Int64;
  G: TGraphic;
begin
  Pos := Stream.Position;
  Format := PPGDetectImageFormat(Stream);
  G := PPGCreateGraphic(Format);
  if G = nil then
  begin
    Picture.Graphic := nil;
    Exit(False);
  end;
  try
    Picture.Graphic := G; // Kopie des leeren Bilds
  finally
    G.Free;
  end;
  try
    Stream.Position := Pos;
    Picture.Graphic.LoadFromStream(Stream);
    Result := True;
  except
    // Grenze: beliebige Bilddaten aus einem Feld; jeder Ladefehler heisst "kein Bild"
    on Exception do
    begin
      Picture.Graphic := nil;
      Format := ifUnknown;
      Result := False;
    end;
  end;
end;

function GraphicToBitmap(G: TGraphic): TBitmap;
begin
  Result := TBitmap.Create;
  try
    if (G is TBitmap) or (G is TWICImage) then
      Result.Assign(G)
    else
    begin
      Result.PixelFormat := pf24bit;
      Result.SetSize(G.Width, G.Height);
      Result.Canvas.Brush.Color := clWhite;
      Result.Canvas.FillRect(Rect(0, 0, Result.Width, Result.Height));
      Result.Canvas.Draw(0, 0, G);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure SaveWic(G: TGraphic; Fmt: TWICImageFormat; Stream: TStream);
var
  W: TWICImage;
  B: TBitmap;
  Old: TWICImageFormat;
begin
  if G is TWICImage then
  begin
    Old := TWICImage(G).ImageFormat;
    TWICImage(G).ImageFormat := Fmt;
    try
      G.SaveToStream(Stream);
    finally
      TWICImage(G).ImageFormat := Old;
    end;
    Exit;
  end;
  B := GraphicToBitmap(G);
  try
    W := TWICImage.Create;
    try
      W.Assign(B);
      W.ImageFormat := Fmt;
      W.SaveToStream(Stream);
    finally
      W.Free;
    end;
  finally
    B.Free;
  end;
end;

procedure PPGSaveGraphic(G: TGraphic; Format: TPPGImageStoreFormat; Stream: TStream);
var
  B: TBitmap;
begin
  case Format of
    sfBitmap:
      if G is TBitmap then
        G.SaveToStream(Stream)
      else
      begin
        B := GraphicToBitmap(G);
        try
          B.SaveToStream(Stream);
        finally
          B.Free;
        end;
      end;
    sfPng: SaveWic(G, wifPng, Stream);
    sfJpeg: SaveWic(G, wifJpeg, Stream);
    sfGif: SaveWic(G, wifGif, Stream);
  else
    G.SaveToStream(Stream);
  end;
end;

{ Alpha }

function NewCanvasBitmap(W, H: Integer; Color: TColor): TBitmap;
begin
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf32bit;
    Result.SetSize(W, H);
    Result.Canvas.Brush.Color := Color;
    Result.Canvas.FillRect(Rect(0, 0, W, H));
  except
    Result.Free;
    raise;
  end;
end;

function PPGRenderPremult(W, H: Integer; const Draw: TPPGImageDrawProc;
  Disabled: Boolean): TBitmap;
var
  Blk, Wht: TBitmap;
  X, Y, A, R, G, B, L: Integer;
  PB, PW, PD: PQuadArray;
begin
  W := Max(W, 1);
  H := Max(H, 1);
  Blk := NewCanvasBitmap(W, H, clBlack);
  try
    Wht := NewCanvasBitmap(W, H, clWhite);
    try
      Draw(Blk.Canvas, Rect(0, 0, W, H));
      Draw(Wht.Canvas, Rect(0, 0, W, H));
      Result := TBitmap.Create;
      try
        Result.PixelFormat := pf32bit;
        Result.SetSize(W, H);
        for Y := 0 to H - 1 do
        begin
          PB := Blk.ScanLine[Y];
          PW := Wht.ScanLine[Y];
          PD := Result.ScanLine[Y];
          for X := 0 to W - 1 do
          begin
            // Auf Schwarz = Farbe * Alpha (vormultipliziert); Weiss - Schwarz = 255 - Alpha
            B := PB[X].rgbBlue;
            G := PB[X].rgbGreen;
            R := PB[X].rgbRed;
            A := 255 - ((PW[X].rgbBlue - B) + (PW[X].rgbGreen - G) + (PW[X].rgbRed - R)) div 3;
            A := EnsureRange(A, 0, 255);
            if R > A then
              R := A;
            if G > A then
              G := A;
            if B > A then
              B := A;
            if Disabled then
            begin
              // grau und halb durchsichtig
              L := (R * 77 + G * 151 + B * 28) shr 8;
              R := L div 2;
              G := R;
              B := R;
              A := A div 2;
            end;
            PD[X].rgbBlue := Byte(B);
            PD[X].rgbGreen := Byte(G);
            PD[X].rgbRed := Byte(R);
            PD[X].rgbReserved := Byte(A);
          end;
        end;
        Result.AlphaFormat := afPremultiplied;
      except
        Result.Free;
        raise;
      end;
    finally
      Wht.Free;
    end;
  finally
    Blk.Free;
  end;
end;

{ TPPGImageView }

constructor TPPGImageView.Create(AOwner: TControl; AOnChange: TNotifyEvent;
  ABorderStyle: TBorderStyle);
begin
  inherited Create;
  FOwner := AOwner;
  FOnChange := AOnChange;
  FBorderStyle := ABorderStyle;
  FImageIndex := -1;
  FImageIndexDark := -1;
  FPicture := TPicture.Create;
  FPicture.OnChange := PictureChange;
  FPictureDark := TPicture.Create;
  FPictureDark.OnChange := PictureChange;
  FChangeLink := TChangeLink.Create;
  FChangeLink.OnChange := ImagesChange;
end;

destructor TPPGImageView.Destroy;
begin
  if FImages <> nil then
    FImages.UnRegisterChanges(FChangeLink);
  FreeAndNil(FChangeLink);
  FreeAndNil(FPictureDark);
  FreeAndNil(FPicture);
  inherited Destroy;
end;

procedure TPPGImageView.Changed;
begin
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TPPGImageView.Notification(AComponent: TComponent; Operation: TOperation);
begin
  if (Operation = opRemove) and (AComponent <> nil) and (AComponent = FImages) then
  begin
    FImages := nil;
    Changed;
  end;
end;

procedure TPPGImageView.ResolveNames;
begin
  {$IFDEF PPG_HAS_IMAGENAME}
  if (csLoading in FOwner.ComponentState) or not ImageNameAvailable then
    Exit;
  // Unbekannter Name -> -1 (kein Bild), keine Exception: die Liste kann zur
  // Laufzeit befuellt werden
  if FImageName <> '' then
    FImageIndex := FImages.GetIndexByName(FImageName);
  if FImageNameDark <> '' then
    FImageIndexDark := FImages.GetIndexByName(FImageNameDark);
  {$ENDIF}
end;

procedure TPPGImageView.Loaded;
begin
  ResolveNames;
  ApplyTransparent(FPicture);
  ApplyTransparent(FPictureDark);
  Changed;
end;

procedure TPPGImageView.ApplyTransparent(P: TPicture);
var
  G: TGraphic;
begin
  G := P.Graphic;
  if (G <> nil) and not ((G is TMetafile) or (G is TIcon)) and (G.Transparent <> FTransparent) then
    G.Transparent := FTransparent;
end;

procedure TPPGImageView.PictureChange(Sender: TObject);
begin
  if Sender = FPicture then
  begin
    ApplyTransparent(FPicture);
    if Assigned(FOnPictureChange) then
      FOnPictureChange(Self);
  end
  else
    ApplyTransparent(FPictureDark);
  Changed;
end;

procedure TPPGImageView.ImagesChange(Sender: TObject);
begin
  // Bilder koennen umsortiert worden sein -> Index ueber den Namen neu bestimmen
  ResolveNames;
  Changed;
end;

procedure TPPGImageView.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TPPGImageView.SetPictureDark(Value: TPicture);
begin
  FPictureDark.Assign(Value);
end;

procedure TPPGImageView.SetImages(const Value: TCustomImageList);
begin
  if FImages = Value then
    Exit;
  if FImages <> nil then
  begin
    FImages.UnRegisterChanges(FChangeLink);
    FImages.RemoveFreeNotification(FOwner);
  end;
  FImages := Value;
  if FImages <> nil then
  begin
    FImages.RegisterChanges(FChangeLink);
    FImages.FreeNotification(FOwner);
  end;
  ImagesChange(nil);
end;

procedure TPPGImageView.SetStretch(const Value: Boolean);
begin
  if FStretch <> Value then
  begin
    FStretch := Value;
    Changed;
  end;
end;

procedure TPPGImageView.SetProportional(const Value: Boolean);
begin
  if FProportional <> Value then
  begin
    FProportional := Value;
    Changed;
  end;
end;

procedure TPPGImageView.SetCenter(const Value: Boolean);
begin
  if FCenter <> Value then
  begin
    FCenter := Value;
    Changed;
  end;
end;

procedure TPPGImageView.SetTransparent(const Value: Boolean);
begin
  if FTransparent <> Value then
  begin
    FTransparent := Value;
    ApplyTransparent(FPicture);
    ApplyTransparent(FPictureDark);
    Changed;
  end;
end;

procedure TPPGImageView.SetDpiScaling(const Value: Boolean);
begin
  if FDpiScaling <> Value then
  begin
    FDpiScaling := Value;
    Changed;
  end;
end;

procedure TPPGImageView.SetBorderStyle(const Value: TBorderStyle);
begin
  if FBorderStyle <> Value then
  begin
    FBorderStyle := Value;
    Changed;
  end;
end;

{ Bildlisten und Namen }

function TPPGImageView.ImageNameAvailable: Boolean;
begin
  {$IFDEF PPG_HAS_IMAGENAME}
  Result := (FImages <> nil) and FImages.IsImageNameAvailable;
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

function TPPGImageView.GetImageIndex(Index: Integer): TPPGImageIndex;
begin
  if Index = 1 then
    Result := FImageIndexDark
  else
    Result := FImageIndex;
end;

procedure TPPGImageView.SetImageIndex(Index: Integer; const Value: TPPGImageIndex);
var
  V: TPPGImageIndex;
  PropName: string;
  Dark: Boolean;
begin
  Dark := Index = 1;
  if Dark then
    PropName := 'ImageIndexDark'
  else
    PropName := 'ImageIndex';
  V := PPGCheckRange(FOwner, PropName, Value, -1, MaxInt);
  if GetImageIndex(Index) = V then
    Exit;
  if Dark then
    FImageIndexDark := V
  else
    FImageIndex := V;
  {$IFDEF PPG_HAS_IMAGENAME}
  if ImageNameAvailable then
  begin
    // Mit Namen wird nur der Name gespeichert (robust gegen Umsortieren)
    if Dark then
      FImageNameDark := FImages.GetNameByIndex(V)
    else
      FImageName := FImages.GetNameByIndex(V);
  end;
  {$ENDIF}
  Changed;
end;

function TPPGImageView.IsImageIndexStored(Dark: Boolean): Boolean;
begin
  // Mit Namen wird nur ImageName gespeichert
  Result := (GetImageIndex(Ord(Dark)) <> -1) and not ImageNameAvailable;
end;

{$IFDEF PPG_HAS_IMAGENAME}
function TPPGImageView.GetImageName(Index: Integer): TImageName;
begin
  if Index = 1 then
    Result := FImageNameDark
  else
    Result := FImageName;
end;

procedure TPPGImageView.SetImageName(Index: Integer; const Value: TImageName);
begin
  if GetImageName(Index) = Value then
    Exit;
  if Index = 1 then
    FImageNameDark := Value
  else
    FImageName := Value;
  ResolveNames;
  Changed;
end;
{$ENDIF}

function TPPGImageView.IsImageNameStored(Dark: Boolean): Boolean;
begin
  {$IFDEF PPG_HAS_IMAGENAME}
  Result := ImageNameAvailable and (GetImageName(Ord(Dark)) <> '');
  {$ELSE}
  Result := False;
  {$ENDIF}
end;

{ Quelle waehlen }

function TPPGImageView.IsDarkActive: Boolean;
begin
  Result := TPPGTheme.IsDark and not PPGUseHighContrast(True);
end;

function HasGraphic(P: TPicture): Boolean;
begin
  Result := (P.Graphic <> nil) and not P.Graphic.Empty;
end;

function TPPGImageView.ActiveGraphic: TGraphic;
begin
  Result := nil;
  if IsDarkActive then
  begin
    if HasGraphic(FPictureDark) then
      Exit(FPictureDark.Graphic);
    // ein dunkles Listenbild geht dem hellen Picture vor
    if (FImages <> nil) and (FImageIndexDark >= 0) and (FImageIndexDark < FImages.Count) then
      Exit;
  end;
  if HasGraphic(FPicture) then
    Result := FPicture.Graphic;
end;

function TPPGImageView.ActiveIndex: Integer;
begin
  Result := -1;
  if (FImages = nil) or (ActiveGraphic <> nil) then
    Exit;
  if IsDarkActive and (FImageIndexDark >= 0) and (FImageIndexDark < FImages.Count) then
    Result := FImageIndexDark
  else if (FImageIndex >= 0) and (FImageIndex < FImages.Count) then
    Result := FImageIndex;
end;

function TPPGImageView.HasImage: Boolean;
begin
  Result := (ActiveGraphic <> nil) or (ActiveIndex >= 0);
end;

function TPPGImageView.ScaleToPPI(Value: Integer): Integer;
begin
  if FDpiScaling then
    Result := PPGScale(Value, PPGControlPPI(FOwner))
  else
    Result := Value;
end;

function TPPGImageView.NaturalSize: TSize;
var
  G: TGraphic;
begin
  Result.cx := 0;
  Result.cy := 0;
  G := ActiveGraphic;
  if G <> nil then
  begin
    Result.cx := ScaleToPPI(G.Width);
    Result.cy := ScaleToPPI(G.Height);
  end
  else if ActiveIndex >= 0 then
  begin
    Result.cx := FImages.Width;
    Result.cy := FImages.Height;
  end;
end;

{ Platz }

function TPPGImageView.FrameWidth: Integer;
begin
  if FBorderStyle = bsSingle then
    Result := Max(1, PPGScale(1, PPGControlPPI(FOwner)))
  else
    Result := 0;
end;

function TPPGImageView.ContentRect(const AClient: TRect): TRect;
var
  F: Integer;
begin
  Result := AClient;
  F := FrameWidth;
  if F > 0 then
    InflateRect(Result, -F, -F);
end;

function TPPGImageView.DestRect(const AClient: TRect): TRect;
var
  C: TRect;
  CW, CH, W, H, DW, DH: Integer;
  Aspect: Double;
  S: TSize;
begin
  C := ContentRect(AClient);
  CW := Max(0, C.Right - C.Left);
  CH := Max(0, C.Bottom - C.Top);
  S := NaturalSize;
  W := S.cx;
  H := S.cy;
  DW := W;
  DH := H;
  // Wie TImage.DestRect: Proportional verkleinert nur, mit Stretch auch vergroessert
  if FStretch or (FProportional and ((W > CW) or (H > CH))) then
  begin
    if FProportional and (W > 0) and (H > 0) then
    begin
      Aspect := W / H;
      DW := CW;
      DH := Integer(Trunc(CW / Aspect));
      if DH > CH then
      begin
        DH := CH;
        DW := Integer(Trunc(CH * Aspect));
      end;
    end
    else
    begin
      DW := CW;
      DH := CH;
    end;
  end;
  Result := Rect(0, 0, DW, DH);
  if FCenter then
    OffsetRect(Result, (CW - DW) div 2, (CH - DH) div 2);
  OffsetRect(Result, C.Left, C.Top);
end;

function TPPGImageView.CoversOpaque(const AClient: TRect): Boolean;
var
  G: TGraphic;
  D, C: TRect;
begin
  G := ActiveGraphic;
  if (G = nil) or G.Transparent then
    Exit(False);
  D := DestRect(AClient);
  C := ContentRect(AClient);
  Result := (D.Left <= C.Left) and (D.Top <= C.Top) and (D.Right >= C.Right) and
    (D.Bottom >= C.Bottom);
end;

{ Zeichnen }

function TPPGImageView.FrameColor(AEnabled: Boolean): TColor;
var
  HC, Dark: Boolean;
  T: TPPGTokens;
begin
  HC := PPGUseHighContrast(True);
  Dark := TPPGTheme.IsDark and not PPGVclStyleActive and not HC;
  T := PPGPresetTokens('', Dark, HC);
  if AEnabled then
    Result := T.Stroke
  else
    Result := T.StrokeDisabled;
  Result := ColorToRGB(Result);
end;

procedure TPPGImageView.PaintFrame(ACanvas: TCanvas; const AClient: TRect; AEnabled: Boolean);
var
  Cv: IPPGCanvas;
  F: Integer;
begin
  F := FrameWidth;
  if (F = 0) or IsRectEmpty(AClient) then
    Exit;
  Cv := TPPGRendererRegistry.CreateCanvas(ACanvas.Handle);
  try
    Cv.FrameRoundRect(AClient, 0, F, FrameColor(AEnabled), 255);
  finally
    Cv := nil;
  end;
end;

procedure TPPGImageView.DrawGraphic(ACanvas: TCanvas; G: TGraphic; const D: TRect;
  AEnabled: Boolean);
var
  Bmp: TBitmap;
begin
  if AEnabled then
    ACanvas.StretchDraw(D, G)
  else
  begin
    Bmp := PPGRenderPremult(D.Right - D.Left, D.Bottom - D.Top,
      procedure(C: TCanvas; const R: TRect)
      begin
        C.StretchDraw(R, G);
      end, True);
    try
      ACanvas.Draw(D.Left, D.Top, Bmp);
    finally
      Bmp.Free;
    end;
  end;
end;

procedure TPPGImageView.DrawListImage(ACanvas: TCanvas; Idx, NW, NH: Integer; const D: TRect;
  AEnabled: Boolean);
var
  Bmp: TBitmap;
  Img: TCustomImageList;
begin
  Img := FImages;
  if (D.Right - D.Left = NW) and (D.Bottom - D.Top = NH) then
    Img.Draw(ACanvas, D.Left, D.Top, Idx, AEnabled)
  else
  begin
    Bmp := PPGRenderPremult(NW, NH,
      procedure(C: TCanvas; const R: TRect)
      begin
        Img.Draw(C, 0, 0, Idx, True);
      end, not AEnabled);
    try
      ACanvas.StretchDraw(D, Bmp);
    finally
      Bmp.Free;
    end;
  end;
end;

procedure TPPGImageView.Paint(ACanvas: TCanvas; const AClient: TRect; AEnabled: Boolean);
var
  C, D: TRect;
  G: TGraphic;
  Idx, Saved: Integer;
  S: TSize;
begin
  PaintFrame(ACanvas, AClient, AEnabled);
  G := ActiveGraphic;
  Idx := ActiveIndex;
  if (G = nil) and (Idx < 0) then
    Exit;
  S := NaturalSize;
  if (S.cx <= 0) or (S.cy <= 0) then
    Exit;
  C := ContentRect(AClient);
  D := DestRect(AClient);
  if IsRectEmpty(D) or IsRectEmpty(C) then
    Exit;
  Saved := SaveDC(ACanvas.Handle);
  try
    IntersectClipRect(ACanvas.Handle, C.Left, C.Top, C.Right, C.Bottom);
    if G <> nil then
      DrawGraphic(ACanvas, G, D, AEnabled)
    else
      DrawListImage(ACanvas, Idx, S.cx, S.cy, D, AEnabled);
  finally
    RestoreDC(ACanvas.Handle, Saved);
  end;
end;

{ TPPGImage }

constructor TPPGImage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csReplicatable];
  Width := 105;
  Height := 105;
  FView := TPPGImageView.Create(Self, ViewChanged, bsNone);
  FView.Picture.OnProgress := PictureProgress;
  TPPGTheme.AddClient(Self);
end;

destructor TPPGImage.Destroy;
begin
  TPPGTheme.RemoveClient(Self);
  FreeAndNil(FView);
  inherited Destroy;
end;

procedure TPPGImage.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if FView <> nil then
    FView.Notification(AComponent, Operation);
end;

procedure TPPGImage.Loaded;
begin
  inherited Loaded;
  FView.Loaded;
end;

procedure TPPGImage.WndProc(var Message: TMessage);
begin
  if (PPGThemeChangedMessage <> 0) and (Message.Msg = PPGThemeChangedMessage) then
  begin
    ViewChanged(nil); // Hell/Dunkel gewechselt: anderes Bild, Randfarbe
    Exit;
  end;
  inherited WndProc(Message);
end;

procedure TPPGImage.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  UpdateOpaque;
  Invalidate;
end;

procedure TPPGImage.PictureProgress(Sender: TObject; Stage: TProgressStage;
  PercentDone: Byte; RedrawNow: Boolean; const R: TRect; const Msg: string);
begin
  if Assigned(FOnProgress) then
    FOnProgress(Self, Stage, PercentDone, RedrawNow, R, Msg);
end;

procedure TPPGImage.UpdateOpaque;
begin
  if Enabled and FView.CoversOpaque(Rect(0, 0, Width, Height)) then
    ControlStyle := ControlStyle + [csOpaque]
  else
    ControlStyle := ControlStyle - [csOpaque];
end;

procedure TPPGImage.ViewChanged(Sender: TObject);
begin
  if (FView = nil) or (csDestroying in ComponentState) then
    Exit;
  UpdateOpaque;
  if AutoSize and not (csLoading in ComponentState) then
    AdjustSize;
  Invalidate;
end;

function TPPGImage.CanAutoSize(var NewWidth, NewHeight: Integer): Boolean;
var
  S: TSize;
  F: Integer;
begin
  Result := False;
  S := FView.NaturalSize;
  if (S.cx <= 0) or (S.cy <= 0) then
    Exit;
  F := FView.FrameWidth;
  NewWidth := S.cx + 2 * F;
  NewHeight := S.cy + 2 * F;
  Result := True;
end;

function TPPGImage.DestRect: TRect;
begin
  Result := FView.DestRect(Rect(0, 0, Width, Height));
end;

function TPPGImage.GetCanvas: TCanvas;
var
  Bitmap: TBitmap;
begin
  if Picture.Graphic = nil then
  begin
    Bitmap := TBitmap.Create;
    try
      Bitmap.Width := Width;
      Bitmap.Height := Height;
      Picture.Graphic := Bitmap;
    finally
      Bitmap.Free;
    end;
  end;
  if Picture.Graphic is TBitmap then
    Result := TBitmap(Picture.Graphic).Canvas
  else
    raise EPPGError.Create(SImageCanvasNeedsBitmap);
end;

procedure TPPGImage.Paint;
var
  Cv: TCanvas;
begin
  Cv := inherited Canvas;
  if (csDesigning in ComponentState) and not FView.HasImage then
  begin
    Cv.Pen.Style := psDash;
    Cv.Brush.Style := bsClear;
    Cv.Rectangle(0, 0, Width, Height);
  end;
  FView.Paint(Cv, Rect(0, 0, Width, Height), Enabled);
end;

function TPPGImage.GetPicture: TPicture;
begin
  Result := FView.Picture;
end;

procedure TPPGImage.SetPicture(Value: TPicture);
begin
  FView.Picture := Value;
end;

function TPPGImage.GetPictureDark: TPicture;
begin
  Result := FView.PictureDark;
end;

procedure TPPGImage.SetPictureDark(Value: TPicture);
begin
  FView.PictureDark := Value;
end;

function TPPGImage.GetImages: TCustomImageList;
begin
  Result := FView.Images;
end;

procedure TPPGImage.SetImages(const Value: TCustomImageList);
begin
  FView.Images := Value;
end;

function TPPGImage.GetImageIndex: TPPGImageIndex;
begin
  Result := FView.ImageIndex;
end;

procedure TPPGImage.SetImageIndex(const Value: TPPGImageIndex);
begin
  FView.ImageIndex := Value;
end;

function TPPGImage.GetImageIndexDark: TPPGImageIndex;
begin
  Result := FView.ImageIndexDark;
end;

procedure TPPGImage.SetImageIndexDark(const Value: TPPGImageIndex);
begin
  FView.ImageIndexDark := Value;
end;

function TPPGImage.IsImageIndexStored: Boolean;
begin
  Result := FView.IsImageIndexStored(False);
end;

function TPPGImage.IsImageIndexDarkStored: Boolean;
begin
  Result := FView.IsImageIndexStored(True);
end;

{$IFDEF PPG_HAS_IMAGENAME}
function TPPGImage.GetImageName: TImageName;
begin
  Result := FView.ImageName;
end;

procedure TPPGImage.SetImageName(const Value: TImageName);
begin
  FView.ImageName := Value;
end;

function TPPGImage.GetImageNameDark: TImageName;
begin
  Result := FView.ImageNameDark;
end;

procedure TPPGImage.SetImageNameDark(const Value: TImageName);
begin
  FView.ImageNameDark := Value;
end;

function TPPGImage.IsImageNameStored: Boolean;
begin
  Result := FView.IsImageNameStored(False);
end;

function TPPGImage.IsImageNameDarkStored: Boolean;
begin
  Result := FView.IsImageNameStored(True);
end;
{$ENDIF}

function TPPGImage.GetStretch: Boolean;
begin
  Result := FView.Stretch;
end;

procedure TPPGImage.SetStretch(const Value: Boolean);
begin
  FView.Stretch := Value;
end;

function TPPGImage.GetProportional: Boolean;
begin
  Result := FView.Proportional;
end;

procedure TPPGImage.SetProportional(const Value: Boolean);
begin
  FView.Proportional := Value;
end;

function TPPGImage.GetCenter: Boolean;
begin
  Result := FView.Center;
end;

procedure TPPGImage.SetCenter(const Value: Boolean);
begin
  FView.Center := Value;
end;

function TPPGImage.GetTransparent: Boolean;
begin
  Result := FView.Transparent;
end;

procedure TPPGImage.SetTransparent(const Value: Boolean);
begin
  FView.Transparent := Value;
end;

function TPPGImage.GetDpiScaling: Boolean;
begin
  Result := FView.DpiScaling;
end;

procedure TPPGImage.SetDpiScaling(const Value: Boolean);
begin
  FView.DpiScaling := Value;
end;

function TPPGImage.GetBorderStyle: TBorderStyle;
begin
  Result := FView.BorderStyle;
end;

procedure TPPGImage.SetBorderStyle(const Value: TBorderStyle);
begin
  FView.BorderStyle := Value;
end;

end.
