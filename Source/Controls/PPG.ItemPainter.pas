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
  Winapi.Windows, System.Classes, System.Types, Vcl.Graphics, Vcl.ImgList,
  PPG.Types, PPG.Items, PPG.Render.Intf, PPG.Markup, PPG.ElementStyle;

type
  /// Bereiche einer Liste (ListBox, CheckListBox, TreeView, Combo-Liste).
  /// Nur gesetzte Werte ueberschreiben das Preset (clDefault = Preset).
  TPPGListStyles = class(TPPGStyleGroup)
  public
    constructor Create(AOwner: TPersistent);
  published
    /// Gewaehlte Eintraege bei Fokus: Color = deckende Flaeche, BorderColor =
    /// Akzentbalken, TextColor, Schrift.
    property Selection: TPPGElementStyle index 0 read GetItem write SetItem;
    /// Gewaehlte Eintraege ohne Fokus.
    property SelectionInactive: TPPGElementStyle index 1 read GetItem write SetItem;
    /// Zebra: jede zweite Zeile (Color setzen schaltet es ein).
    property AlternateRow: TPPGElementStyle index 2 read GetItem write SetItem;
    /// Eintrag unter der Maus.
    property HotItem: TPPGElementStyle index 3 read GetItem write SetItem;
    /// Gruppen-Ueberschriften.
    property GroupHeader: TPPGElementStyle index 4 read GetItem write SetItem;
    /// Detailzeile (zweite Zeile) der Eintraege.
    property Detail: TPPGElementStyle index 5 read GetItem write SetItem;
  end;

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
    // Anpassbarkeit (Styles darf nil sein)
    Styles: TPPGListStyles;
    UseColors: Boolean;  // False: Hochkontrast/VCL-Style (nur Schriften)
    Dark: Boolean;
    Focused: Boolean;    // Control hat den Fokus (Selection/SelectionInactive)
    TabWidth: Integer;   // Tabulator-Abstand in px (0 = Tabs nicht aufloesen)
  end;

  TPPGItemPainter = class
  private
    FMarkup: TPPGMarkupLayout;
    FFonts: TPPGFontCache;
    procedure PaintItemContentCore(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
      const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo; Index: Integer;
      Selected: Boolean; Hot: Single);
  public
    constructor Create;
    destructor Destroy; override;
    /// Hoehe einer Textzeile in Font (ohne Abstand).
    class function TextLineHeight(Font: TFont): Integer;
    /// Text mit Tabulatoren: jedes Stueck beginnt am naechsten Vielfachen von TabPx.
    class procedure DrawTabbedText(const Canvas: IPPGCanvas; const R: TRect; const Text: string;
      Font: TFont; Color: TColor; Flags: Cardinal; TabPx: Integer);
    /// Tabulatorbreite in Dialogeinheiten (wie TListBox.TabWidth) in px.
    class function TabUnitsToPixels(Font: TFont; Units: Integer): Integer;
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
    /// Hintergrund mit Element-Stilen (Zebra, Farbe des Eintrags, Hover,
    /// Auswahl) und danach Renderer. Index = Zeile (Zebra; -1 = keins).
    procedure PaintItemBackground(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
      const R: TRect; const Info: TPPGItemPaintInfo; const Data: TPPGItemData; Index: Integer;
      Selected, Focused: Boolean; Hot: Single);
    /// Inhalt mit Element-Stilen (Textfarbe und Schrift nach Eintrag, Zebra,
    /// Hover und Auswahl).
    procedure PaintItemContent(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
      const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo; Index: Integer;
      Selected: Boolean; Hot: Single);
    /// Schriften dieses Zeichenvorgangs freigeben (am Ende von Paint).
    procedure EndPaint;
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

{ TPPGListStyles }

constructor TPPGListStyles.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, 6);
end;

{ TPPGItemPainter }

constructor TPPGItemPainter.Create;
begin
  inherited Create;
  FMarkup := TPPGMarkupLayout.Create;
  FFonts := TPPGFontCache.Create;
end;

destructor TPPGItemPainter.Destroy;
begin
  FreeAndNil(FFonts);
  FreeAndNil(FMarkup);
  inherited Destroy;
end;

class procedure TPPGItemPainter.DrawTabbedText(const Canvas: IPPGCanvas; const R: TRect;
  const Text: string; Font: TFont; Color: TColor; Flags: Cardinal; TabPx: Integer);
var
  Parts: TArray<string>;
  I, X, W: Integer;
  SR: TRect;
begin
  Parts := PPGSplitString(Text, #9, False);
  X := R.Left;
  for I := 0 to High(Parts) do
  begin
    if X >= R.Right then
      Break;
    SR := Rect(X, R.Top, R.Right, R.Bottom);
    if Parts[I] <> '' then
      Canvas.DrawText(SR, Parts[I], Font, Color, Flags);
    W := Canvas.MeasureText(Parts[I], Font, 0, False).cx;
    // naechster Tabstopp (mindestens ein Pixel weiter)
    X := R.Left + ((X - R.Left + W) div TabPx + 1) * TabPx;
  end;
end;

class function TPPGItemPainter.TabUnitsToPixels(Font: TFont; Units: Integer): Integer;
const
  Sample = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
var
  Avg: Integer;
begin
  // Dialogeinheit = mittlere Zeichenbreite / 4 (wie LB_SETTABSTOPS)
  Avg := (PPGMeasureTextNoCanvas(Sample, Font, 0, False).cx + Length(Sample) div 2) div Length(Sample);
  Result := Units * Avg div 4;
  if (Units > 0) and (Result < 1) then
    Result := 1;
end;

type
  // Audit 8d #2: Zeilenhoehe je Schrift (LOGFONT enthaelt Name, Hoehe in px,
  // Stil, Zeichensatz, Qualitaet); Gruppenlisten fragen sie sonst je Eintrag
  // mit eigenem DC ab. Nur Hauptthread (wie das Zeichnen).
  TLineHeightEntry = record
    LF: TLogFont;
    H: Integer;
  end;

const
  LineHeightSlots = 8;

var
  GLineHeights: array[0..LineHeightSlots - 1] of TLineHeightEntry;
  GLineHeightCount: Integer = 0;
  GLineHeightNext: Integer = 0;

class function TPPGItemPainter.TextLineHeight(Font: TFont): Integer;
var
  LF: TLogFont;
  I: Integer;
  Keyed: Boolean;
begin
  FillChar(LF, SizeOf(LF), 0);
  Keyed := GetObject(Font.Handle, SizeOf(LF), @LF) <> 0;
  if Keyed then
    for I := 0 to GLineHeightCount - 1 do
      if CompareMem(@GLineHeights[I].LF, @LF, SizeOf(LF)) then
        Exit(GLineHeights[I].H);
  Result := PPGMeasureTextNoCanvas('Wg', Font, 0, False).cy;
  if Result < 1 then
    Result := 1;
  if Keyed then
  begin
    GLineHeights[GLineHeightNext].LF := LF;
    GLineHeights[GLineHeightNext].H := Result;
    GLineHeightNext := (GLineHeightNext + 1) mod LineHeightSlots;
    if GLineHeightCount < LineHeightSlots then
      Inc(GLineHeightCount);
  end;
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
var
  L: TPPGSurfaceStyle;
  F: TFont;
  GS: TPPGElementStyle;
begin
  L := Info.ListStyle;
  F := Info.Font;
  if Info.Styles <> nil then
  begin
    GS := Info.Styles.GroupHeader;
    if Info.UseColors then
    begin
      if GS.HasFill(Info.Dark) then
        Canvas.FillRoundRect(R, 0, GS.FillFor(Info.Dark, clNone), 255);
      L.TextColor := GS.TextFor(Info.Dark, L.TextColor);
      L.GlowColor := GS.BorderFor(Info.Dark, L.GlowColor);
    end;
    F := FFonts.ForStyle(GS, Info.Font);
  end;
  IR.DrawGroupHeader(Canvas, R, PPGStripMarkup(Text), F, L, Info.RightToLeft, Info.PPI);
end;

procedure TPPGItemPainter.EndPaint;
begin
  FFonts.Clear;
end;

function SelStyleOf(const Info: TPPGItemPaintInfo): TPPGElementStyle;
begin
  if Info.Styles = nil then
    Result := nil
  else if Info.Focused then
    Result := Info.Styles.Selection
  else
    Result := Info.Styles.SelectionInactive;
end;

procedure TPPGItemPainter.PaintItemBackground(const Canvas: IPPGCanvas;
  const IR: IPPGItemRenderer; const R: TRect; const Info: TPPGItemPaintInfo;
  const Data: TPPGItemData; Index: Integer; Selected, Focused: Boolean; Hot: Single);
var
  L, H: TPPGSurfaceStyle;
  S: TPPGListStyles;
  SS: TPPGElementStyle;
  Fill, C: TColor;
  Body, Bar: TRect;
  PPI, Rad, BarW, BarH: Integer;
  OwnSel: Boolean;
begin
  L := Info.ListStyle;
  H := Info.HighlightStyle;
  S := Info.Styles;
  OwnSel := False;
  PPI := Info.PPI;
  if Info.UseColors then
  begin
    // Flaeche der Zeile: Zebra, darueber die Farbe des Eintrags
    Fill := clNone;
    if (S <> nil) and (Index >= 0) and Odd(Index) and S.AlternateRow.HasFill(Info.Dark) then
      Fill := S.AlternateRow.FillFor(Info.Dark, clNone);
    if (Data.Color <> clDefault) and (Data.Color <> clNone) then
      Fill := PPGColorToRGB(Data.Color);
    if Fill <> clNone then
      Canvas.FillRoundRect(R, 0, Fill, 255);
    if S <> nil then
    begin
      // Hover: Farbe in alle Verlaufsfarben (Classic zeichnet einen Verlauf)
      if S.HotItem.HasFill(Info.Dark) then
      begin
        C := S.HotItem.FillFor(Info.Dark, H.Color);
        H.Color := C;
        H.ColorTo := C;
        H.ColorMirror := C;
        H.ColorMirrorTo := C;
      end;
      SS := SelStyleOf(Info);
      if Selected and SS.HasBorder(Info.Dark) then
        L.GlowColor := SS.BorderFor(Info.Dark, L.GlowColor);
      if Selected and SS.HasFill(Info.Dark) then
      begin
        // Eigene Auswahl deckend (gleiche Pille wie das Preset), Akzentbalken
        // nur mit BorderColor
        OwnSel := True;
        Body := R;
        InflateRect(Body, -PPGScale(4, PPI), -PPGScale(1, PPI));
        if IsRectEmpty(Body) then
          Body := R;
        Rad := PPGScale(4, PPI);
        if Rad * 2 > Body.Bottom - Body.Top then
          Rad := (Body.Bottom - Body.Top) div 2;
        Canvas.FillRoundRect(Body, Rad, SS.FillFor(Info.Dark, clNone), 255);
        if SS.HasBorder(Info.Dark) then
        begin
          BarW := PPGScale(3, PPI);
          BarH := (Body.Bottom - Body.Top) div 2;
          if Info.RightToLeft then
            Bar := Rect(Body.Right - BarW, 0, Body.Right, 0)
          else
            Bar := Rect(Body.Left, 0, Body.Left + BarW, 0);
          Bar.Top := (Body.Top + Body.Bottom - BarH) div 2;
          Bar.Bottom := Bar.Top + BarH;
          Canvas.FillRoundRect(Bar, BarW div 2, L.GlowColor, 255);
        end;
      end;
    end;
  end;
  if OwnSel then
    // Renderer nur noch fuer Fokusrahmen (ohne Auswahl und Hover)
    IR.DrawItemBackground(Canvas, R, L, H, False, Focused, 0, Info.RightToLeft, PPI)
  else
    IR.DrawItemBackground(Canvas, R, L, H, Selected, Focused, Hot, Info.RightToLeft, PPI);
end;

procedure TPPGItemPainter.PaintContent(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo;
  Highlighted: Boolean);
begin
  // Ohne Zeile und Zustand: hervorgehoben wie eine Auswahl
  PaintItemContent(Canvas, IR, R, Data, Info, -1, Highlighted, 0);
end;

procedure TPPGItemPainter.PaintItemContent(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo; Index: Integer;
  Selected: Boolean; Hot: Single);
begin
  // Audit 8a #5: Bild, Text und Detail eines Eintrags teilen sich einen DC
  PPGBeginBatch(Canvas);
  try
    PaintItemContentCore(Canvas, IR, R, Data, Info, Index, Selected, Hot);
  finally
    PPGEndBatch(Canvas);
  end;
end;

procedure TPPGItemPainter.PaintItemContentCore(const Canvas: IPPGCanvas; const IR: IPPGItemRenderer;
  const R: TRect; const Data: TPPGItemData; const Info: TPPGItemPaintInfo; Index: Integer;
  Selected: Boolean; Hot: Single);
var
  Highlighted: Boolean;
  S: TPPGListStyles;
  SS: TPPGElementStyle;
  Extra: TFontStyles;
  F, DF: TFont;
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
  Highlighted := Selected or (Hot > 0);
  if Highlighted then
    TextColor := Info.HighlightStyle.TextColor
  else
    TextColor := Info.ListStyle.TextColor;
  // Element-Stile: Eintrag -> Zebra -> Hover -> Auswahl (Farben nur ohne
  // Hochkontrast/VCL-Style, Schriftstile immer)
  S := Info.Styles;
  Extra := Data.FontStyle;
  if Info.UseColors and (Data.TextColor <> clDefault) and (Data.TextColor <> clNone) then
    TextColor := PPGColorToRGB(Data.TextColor);
  if S <> nil then
  begin
    if (Index >= 0) and Odd(Index) and S.AlternateRow.HasFill(Info.Dark) then
    begin
      if Info.UseColors then
        TextColor := S.AlternateRow.TextFor(Info.Dark, TextColor);
      Extra := Extra + S.AlternateRow.FontStyle;
    end;
    if Hot > 0 then
    begin
      if Info.UseColors then
        TextColor := S.HotItem.TextFor(Info.Dark, TextColor);
      Extra := Extra + S.HotItem.FontStyle;
    end;
    if Selected then
    begin
      SS := SelStyleOf(Info);
      if Info.UseColors then
        TextColor := SS.TextFor(Info.Dark, TextColor);
      Extra := Extra + SS.FontStyle;
    end;
  end;
  F := FFonts.Get(Info.Font, Extra);
  if not ItemEnabled then
    TextColor := PPGBlendColor(TextColor, Info.ListStyle.Color, 0.55);
  DetailColor := PPGBlendColor(TextColor, Info.ListStyle.Color, 0.35);
  DF := Info.Font;
  if S <> nil then
  begin
    if Info.UseColors then
      DetailColor := S.Detail.TextFor(Info.Dark, DetailColor);
    DF := FFonts.ForStyle(S.Detail, Info.Font);
  end;

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
    // Text auf dem Akzent in der Farbe mit dem hoeheren Kontrast
    BadgeText := PPGContrastTextColor(Info.ListStyle.GlowColor);
    IR.DrawBadge(Canvas, BadgeR, Data.Badge, Info.Font, Info.ListStyle.GlowColor,
      BadgeText, PPI);
  end;

  if Content.Right <= Content.Left then
    Exit;

  // Text (eine Zeile) und optional die Detailzeile darunter, als Block zentriert
  LineH := TextLineHeight(F);
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
    FMarkup.Layout(Data.Text, F, Info.Images, TextR.Right - TextR.Left, False);
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
  else if (Info.TabWidth > 0) and not Info.RightToLeft and (Pos(#9, Data.Text) > 0) then
    DrawTabbedText(Canvas, TextR, Data.Text, F, TextColor, Flags, Info.TabWidth)
  else
    Canvas.DrawText(TextR, Data.Text, F, TextColor, Flags);

  if HasDetail then
  begin
    DetailR := TextR;
    OffsetRect(DetailR, 0, LineH);
    Canvas.DrawText(DetailR, PPGStripMarkup(Data.Detail), DF, DetailColor, Flags);
  end;
end;

end.
