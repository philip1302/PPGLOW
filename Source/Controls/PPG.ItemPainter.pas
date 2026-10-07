unit PPG.ItemPainter;

{ TPPGItemPainter - zeichnet den Inhalt eines Eintrags (Bild, Text oder
  Markup, Detailzeile, Plakette) und Gruppen-Ueberschriften.

  Komposition statt Vererbung: ListBox, CheckListBox, TreeView (Scroll-
  Controls) und die Combo-Liste (Popup-Fenster) haben verschiedene Basen,
  zeichnen ihre Zeilen aber alle hiermit - eine Optik, einmal getestet.
  Den Hintergrund (Auswahl, Hover, Fokus) zeichnet IPPGItemRenderer des
  Presets; hier nur der Inhalt. Kein Fensterzugriff: auch aus Paint sicher. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.ImgList,
  PPG.Types, PPG.Items, PPG.Render.Intf, PPG.Markup;

type
  /// Alles, was fuer das Zeichnen einer Zeile ausser den Daten gebraucht wird.
  TPPGItemPaintInfo = record
    ListStyle: TPPGSurfaceStyle;      // Color = Hintergrund, TextColor, GlowColor = Akzent
    HighlightStyle: TPPGSurfaceStyle; // Hover/Auswahl (TextColor bei Hervorhebung)
    Font: TFont;
    Images: TCustomImageList;
    AllowMarkup: Boolean;
    RightToLeft: Boolean;
    Enabled: Boolean;                 // Control aktiviert
    PPI: Integer;
  end;

  TPPGItemPainter = class
  private
    FMarkup: TPPGMarkupLayout;
  public
    constructor Create;
    destructor Destroy; override;
    /// Hoehe einer Textzeile in Font (ohne Abstand).
    class function TextLineHeight(Font: TFont): Integer;
    /// Zeilenhoehe ohne Gruppen-Ueberschrift: Text (+ Detailzeile) + Abstand,
    /// mindestens Bildhoehe.
    class function RowHeight(Font: TFont; Images: TCustomImageList; TwoLines: Boolean;
      PPI: Integer): Integer;
    class function GroupHeaderHeight(Font: TFont; PPI: Integer): Integer;
    /// Hintergrund ueber den Renderer (Auswahl, Hover, Fokus).
    procedure PaintBackground(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
      const R: TRect; const Info: TPPGItemPaintInfo; Selected, Focused: Boolean; Hot: Single);
    /// Inhalt in R (R ist bereits um Einzug/Kaestchen verkleinert).
    /// Highlighted: Text in HighlightStyle.TextColor (Auswahl/Hover).
    procedure PaintContent(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
      const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo;
      Highlighted: Boolean);
    procedure PaintGroupHeader(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
      const R: TRect; const Text: string; const Info: TPPGItemPaintInfo);
    /// Text eines Eintrags fuer Suche/Screenreader (ohne Markup).
    class function PlainText(const Data: TPPGItemData): string;
  end;

/// Renderer fuer Eintraege (fremde Presets ohne IPPGItemRenderer: Standard-Preset).
function PPGItemRendererOf(const R: IPPGRenderer): IPPGItemRenderer;

const
  PPGItemPadX = 12;  // logische px links (Platz fuer den Akzentbalken)
  PPGItemPadY = 5;   // logische px ueber/unter dem Text
  PPGItemGap = 8;    // logische px zwischen Bild, Text und Plakette

implementation

uses
  System.SysUtils, PPG.Appearance, PPG.Tokens, PPG.Render.Gdi, PPG.Render.Registry;

function PPGItemRendererOf(const R: IPPGRenderer): IPPGItemRenderer;
begin
  if not Supports(R, IPPGItemRenderer, Result) then
    Supports(TPPGRendererRegistry.Get(TPPGRendererRegistry.DefaultName),
      IPPGItemRenderer, Result);
end;

{ TPPGItemPainter }

constructor TPPGItemPainter.Create;
begin
  inherited Create;
  FMarkup := TPPGMarkupLayout.Create;
end;

destructor TPPGItemPainter.Destroy;
begin
  FreeAndNil(FMarkup);
  inherited Destroy;
end;

class function TPPGItemPainter.TextLineHeight(Font: TFont): Integer;
begin
  Result := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy;
  if Result < 1 then
    Result := 1;
end;

class function TPPGItemPainter.RowHeight(Font: TFont; Images: TCustomImageList;
  TwoLines: Boolean; PPI: Integer): Integer;
var
  ImgH: Integer;
begin
  Result := TextLineHeight(Font);
  if TwoLines then
    Result := Result * 2;
  ImgH := 0;
  if Images <> nil then
    ImgH := Images.Height;
  if ImgH > Result then
    Result := ImgH;
  Inc(Result, 2 * PPGScale(PPGItemPadY, PPI));
end;

class function TPPGItemPainter.GroupHeaderHeight(Font: TFont; PPI: Integer): Integer;
begin
  Result := TextLineHeight(Font) + 2 * PPGScale(6, PPI) + PPGScale(2, PPI);
end;

class function TPPGItemPainter.PlainText(const Data: TPPGItemData): string;
begin
  if PPGIsPlainText(Data.Text) then
    Result := Data.Text
  else
    Result := PPGStripMarkup(Data.Text);
end;

procedure TPPGItemPainter.PaintBackground(const Canvas: IPPGCanvas;
  const IR: IPPGItemRenderer; const R: TRect; const Info: TPPGItemPaintInfo;
  Selected, Focused: Boolean; Hot: Single);
begin
  IR.DrawItemBackground(Canvas, R, Info.ListStyle, Info.HighlightStyle, Selected, Focused,
    Hot, Info.RightToLeft, Info.PPI);
end;

procedure TPPGItemPainter.PaintGroupHeader(const Canvas: IPPGCanvas;
  const IR: IPPGItemRenderer; const R: TRect; const Text: string;
  const Info: TPPGItemPaintInfo);
begin
  IR.DrawGroupHeader(Canvas, R, PPGStripMarkup(Text), Info.Font, Info.ListStyle,
    Info.RightToLeft, Info.PPI);
end;

procedure TPPGItemPainter.PaintContent(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo;
  Highlighted: Boolean);
var
  PPI, Gap, X, Y, LineH, BlockH: Integer;
  Content, TextR, DetailR, BadgeR: TRect;
  BS: TSize;
  TextColor, DetailColor, BadgeText: TColor;
  Flags: Cardinal;
  ItemEnabled, HasDetail: Boolean;
begin
  if IsRectEmpty(R) then
    Exit;
  PPI := Info.PPI;
  Gap := PPGScale(PPGItemGap, PPI);
  ItemEnabled := Data.Enabled and Info.Enabled;
  if Highlighted then
    TextColor := Info.HighlightStyle.TextColor
  else
    TextColor := Info.ListStyle.TextColor;
  if not ItemEnabled then
    TextColor := PPGBlendColor(TextColor, Info.ListStyle.Color, 0.55);
  DetailColor := PPGBlendColor(TextColor, Info.ListStyle.Color, 0.35);

  Content := R;
  if Info.RightToLeft then
    Dec(Content.Right, PPGScale(PPGItemPadX, PPI))
  else
    Inc(Content.Left, PPGScale(PPGItemPadX, PPI));
  Dec(Content.Right, PPGScale(6, PPI) * Ord(not Info.RightToLeft));
  Inc(Content.Left, PPGScale(6, PPI) * Ord(Info.RightToLeft));

  // Bild am Anfang der Zeile
  if (Info.Images <> nil) and (Data.ImageIndex >= 0) and
    (Data.ImageIndex < Info.Images.Count) then
  begin
    Y := (Content.Top + Content.Bottom - Info.Images.Height) div 2;
    if Info.RightToLeft then
    begin
      X := Content.Right - Info.Images.Width;
      Content.Right := X - Gap;
    end
    else
    begin
      X := Content.Left;
      Content.Left := X + Info.Images.Width + Gap;
    end;
    Canvas.DrawImage(Info.Images, Data.ImageIndex, X, Y, ItemEnabled);
  end;

  // Plakette am Ende der Zeile
  if Data.Badge <> '' then
  begin
    BS := IR.BadgeSize(Canvas, Data.Badge, Info.Font, PPI);
    BadgeR.Top := (Content.Top + Content.Bottom - BS.cy) div 2;
    BadgeR.Bottom := BadgeR.Top + BS.cy;
    if Info.RightToLeft then
    begin
      BadgeR.Left := Content.Left;
      BadgeR.Right := BadgeR.Left + BS.cx;
      Content.Left := BadgeR.Right + Gap;
    end
    else
    begin
      BadgeR.Right := Content.Right;
      BadgeR.Left := BadgeR.Right - BS.cx;
      Content.Right := BadgeR.Left - Gap;
    end;
    // Text auf dem Akzent: weiss auf dunklem, schwarz auf hellem Akzent
    if PPGRelativeLuminance(Info.ListStyle.GlowColor) < 0.4 then
      BadgeText := clWhite
    else
      BadgeText := clBlack;
    IR.DrawBadge(Canvas, BadgeR, Data.Badge, Info.Font, Info.ListStyle.GlowColor,
      BadgeText, PPI);
  end;

  if Content.Right <= Content.Left then
    Exit;

  // Text (eine Zeile) und optional die Detailzeile darunter, als Block zentriert
  LineH := TextLineHeight(Info.Font);
  HasDetail := (Data.Detail <> '') and (Content.Bottom - Content.Top >= 2 * LineH);
  if HasDetail then
    BlockH := 2 * LineH
  else
    BlockH := LineH;
  TextR := Content;
  TextR.Top := (Content.Top + Content.Bottom - BlockH) div 2;
  TextR.Bottom := TextR.Top + LineH;

  Flags := DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS;
  if Info.RightToLeft then
    Flags := Flags or DT_RIGHT or DT_RTLREADING;
  if Info.AllowMarkup and not PPGIsPlainText(Data.Text) then
  begin
    FMarkup.Layout(Data.Text, Info.Font, Info.Images, TextR.Right - TextR.Left, False);
    if Info.RightToLeft then
      X := TextR.Right - FMarkup.Size.cx
    else
      X := TextR.Left;
    Canvas.PushClipRoundRect(TextR, 0);
    try
      FMarkup.Draw(Canvas, X, TextR.Top + (LineH - FMarkup.Size.cy) div 2, TextColor,
        Info.ListStyle.GlowColor, ItemEnabled);
    finally
      Canvas.PopClip;
    end;
  end
  else
    Canvas.DrawText(TextR, Data.Text, Info.Font, TextColor, Flags);

  if HasDetail then
  begin
    DetailR := TextR;
    OffsetRect(DetailR, 0, LineH);
    Canvas.DrawText(DetailR, PPGStripMarkup(Data.Detail), Info.Font, DetailColor, Flags);
  end;
end;

end.
