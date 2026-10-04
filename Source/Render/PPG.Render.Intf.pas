unit PPG.Render.Intf;

{ Abstraktionen der Zeichenschicht (Dependency Inversion):
  - IPPGCanvas   : Zeichenprimitive, implementiert durch GDI+ oder GDI-Fallback
  - IPPGRenderer : Optik eines Presets (Classic, ModernFlat, ...)

  Controls kennen nur diese Interfaces, nie GDI+ direkt. Renderer sind
  zustandslos und werden von allen Controls geteilt (TInterfacedObject,
  referenzgezaehlt - KEINE TComponent-Instanzen!). }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.ImgList, Vcl.StdCtrls, PPG.Types, PPG.Appearance,
  PPG.Tokens;

type
  IPPGCanvas = interface
    ['{8F7C2E51-6B4A-4D3C-A1E9-0C5D7B2F9A31}']
    function IsAntialiased: Boolean;
    procedure FillRoundRect(const R: TRect; Radius: Integer; Color: TColor; Alpha: Byte);
    procedure FillGradientRect(const R: TRect; ColorFrom, ColorTo: TColor;
      Direction: TPPGGradientDirection; Alpha: Byte);
    procedure FrameRoundRect(const R: TRect; Radius, Width: Integer; Color: TColor; Alpha: Byte);
    /// Weicher Leuchtrand AUSSERHALB von R (R = Koerper des Elements).
    procedure DrawOuterGlow(const R: TRect; Radius, Size: Integer; Color: TColor; Alpha: Byte);
    /// Elliptischer Lichtfleck (Mitte Color/Alpha, Rand transparent).
    procedure FillRadialGlow(const R: TRect; Color: TColor; Alpha: Byte);
    procedure FillEllipse(const R: TRect; Color: TColor; Alpha: Byte);
    procedure FrameEllipse(const R: TRect; Width: Integer; Color: TColor; Alpha: Byte);
    procedure DrawPolyline(const Points: array of TPoint; Width: Integer; Color: TColor; Alpha: Byte);
    /// Begrenzt alle folgenden Zeichenoperationen auf ein abgerundetes Rechteck.
    procedure PushClipRoundRect(const R: TRect; Radius: Integer);
    procedure PopClip;
    function MeasureText(const Text: string; Font: TFont; MaxWidth: Integer;
      WordWrap: Boolean): TSize;
    procedure DrawText(const R: TRect; const Text: string; Font: TFont; Color: TColor;
      Flags: Cardinal);
    procedure DrawImage(Images: TCustomImageList; Index, X, Y: Integer; Enabled: Boolean);
    procedure DrawFocusRect(const R: TRect);
    /// Roher GDI-DC fuer fremde Zeichenroutinen (Owner-Draw mit TCanvas):
    /// Clip ist uebernommen; nach Gebrauch immer EndGdi (try/finally).
    function BeginGdi: HDC;
    procedure EndGdi(DC: HDC);
  end;

  IPPGRenderer = interface
    ['{2D4B6A90-7E13-4C58-B0F2-91A8C3E5D746}']
    function Name: string;
    /// Setzt die Preset-Farben und -Masse in die Appearance.
    procedure ApplyDefaults(Appearance: TPPGAppearance);
    /// Abstand, den der Koerper vom Control-Rand einhaelt (z.B. Platz fuer
    /// aeusseren Glow), bezogen auf den maximalen Stil.
    function BodyInset(const Style: TPPGSurfaceStyle): Integer;
    /// Zeichnet Hintergrund, Glow und Rahmen einer Flaeche.
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle);
    /// Fokusmarkierung (nur wenn Fokus-Cues sichtbar sind).
    procedure DrawFocus(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle);
    /// Haken fuer CheckBox/Menues.
    procedure DrawCheckMark(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      PPI: Integer);
  end;

  /// Indikatoren der Auswahl-Controls (Interface Segregation: nur Controls mit
  /// Kaestchen/Kreis/Schalter brauchen das). TPPGRendererBase liefert eine
  /// Standard-Darstellung auf Basis von DrawSurface; Presets koennen sie
  /// ueberschreiben, ohne dass sich ein Control aendert.
  // Alias auf den VCL-Typ: DFMs von TCheckBox ("State = cbChecked") bleiben
  // beim Umstieg auf TPPGCheckBox gueltig.
  TPPGCheckState = Vcl.StdCtrls.TCheckBoxState;

  IPPGIndicatorRenderer = interface
    ['{6E3A1F09-B2C4-4D7E-8F15-3A9C0D2E4B61}']
    procedure DrawCheckIndicator(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; State: TPPGCheckState; PPI: Integer);
    procedure DrawRadioIndicator(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Checked: Boolean; PPI: Integer);
    /// Position: 0 = aus (Knopf links), 1 = an (Knopf rechts); Zwischenwerte
    /// waehrend der Animation. RightToLeft spiegelt die Richtung.
    procedure DrawSwitch(const Canvas: IPPGCanvas; const Track: TRect;
      const Style: TPPGSurfaceStyle; Position: Single; RightToLeft: Boolean; PPI: Integer);
    { Ist Style.Focused gesetzt, zeichnen alle Methoden die Fokusmarkierung
      selbst - in der Form des jeweiligen Indikators (Kreis, Pille, Kaestchen). }
  end;

  /// Wertebereich-Controls (ProgressBar, TrackBar). Die Geometrie (wo steht
  /// die Fuellung, wo der Griff) berechnet das Control; der Renderer zeichnet nur.
  IPPGRangeRenderer = interface
    ['{B7D41C2E-5A93-4E08-9F6B-2C8E1A7D3F55}']
    /// Spur des Fortschrittsbalkens mit Fuellung. Fill darf ueber Track
    /// hinausragen (Marquee) und wird auf die Form der Spur begrenzt.
    procedure DrawProgress(const Canvas: IPPGCanvas; const Track, Fill: TRect;
      const TrackStyle, FillStyle: TPPGSurfaceStyle; PPI: Integer);
    /// Schiene des Schiebereglers; Fill = Abschnitt von Min bis zur Position.
    procedure DrawSliderTrack(const Canvas: IPPGCanvas; const Track, Fill: TRect;
      const TrackStyle, FillStyle: TPPGSurfaceStyle; PPI: Integer);
    /// Griff des Schiebereglers. Accent = Farbe des inneren Punkts,
    /// HotProgress (0..1) laesst ihn beim Hover wachsen. Style.Focused ->
    /// Fokusmarkierung in Griffform.
    procedure DrawSliderThumb(const Canvas: IPPGCanvas; const Thumb: TRect;
      const Style: TPPGSurfaceStyle; Accent: TColor; HotProgress: Single; PPI: Integer);
  end;

  /// Container (Panel, GroupBox): grosse Flaechen ohne Glanzkante und Glow.
  IPPGContainerRenderer = interface
    ['{4F2A8C61-D3B7-49E5-A0C8-7B1E6D9F2A04}']
    procedure DrawContainer(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle);
  end;

  /// Symbole der Feld-Buttons (fgNone = nur Hintergrund, z.B. fuer ein Bild).
  TPPGFieldGlyph = (fgNone, fgClear, fgSpinUp, fgSpinDown, fgDropDown);

  /// Eingabefelder (Edit, Memo, SpinEdit, ComboBox). Das Innere ist immer
  /// EINFARBIG Style.Color: dort liegt das native Edit, das keinen Verlauf kann.
  /// Style.GlowColor ist die Akzentfarbe der Fokusmarkierung.
  IPPGFieldRenderer = interface
    ['{C3E81B5A-2F64-4D97-8A0B-5E9D1C7F3A26}']
    /// FocusProgress 0..1 blendet die Fokusmarkierung ein (Animation).
    procedure DrawField(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle; FocusProgress: Single; PPI: Integer);
    /// Button innerhalb des Felds. Style.TextColor = Farbe des Symbols.
    procedure DrawFieldButton(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Glyph: TPPGFieldGlyph; Hot, Pressed: Boolean;
      PPI: Integer);
  end;

  /// Aufklapplisten (ComboBox-Popup). Zwei Stile:
  /// - ListStyle: Color = Listenhintergrund, BorderColor = Rahmen des Popups,
  ///   TextColor = Text, GlowColor = Akzent (Markierung des gewaehlten Eintrags),
  ///   Rounding = Rundung des Popups
  /// - HighlightStyle: Optik des hervorgehobenen Eintrags (Hover/Tastatur),
  ///   bei Classic ein Glanz-Verlauf aus Color/ColorTo/ColorMirror/ColorMirrorTo.
  /// Den Text zeichnet das Control (HighlightStyle.TextColor bei Hervorhebung).
  IPPGListRenderer = interface
    ['{8A4D2F17-C6E9-4B30-95A1-D7E2B04C6F18}']
    procedure DrawPopupFrame(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle: TPPGSurfaceStyle; PPI: Integer);
    /// Selected = aktueller Wert (ItemIndex), Highlight 0..1 = Hervorhebung.
    procedure DrawListItem(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected: Boolean;
      Highlight: Single; PPI: Integer);
    /// Schmale Scrollleiste; Thumb liegt in Track.
    procedure DrawScrollThumb(const Canvas: IPPGCanvas; const Track, Thumb: TRect;
      const ListStyle: TPPGSurfaceStyle; Hot: Boolean; PPI: Integer);
    /// Aufklapp-Pfeil; Rotation 0..1 dreht ihn um 0..180 Grad (offen = 1).
    procedure DrawDropArrow(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Rotation: Single; PPI: Integer);
  end;

  /// Reiter (TabControl, PageControl). Die Geometrie berechnet das Control
  /// (TPPGTabStrip); Bottom = Reiter unterhalb der Seite (gespiegelt).
  /// Der gewaehlte Reiter ragt um die Rahmenbreite in die Seite und verdeckt
  /// deren Rahmen - so haengt er mit der Seite zusammen.
  IPPGTabRenderer = interface
    ['{E5B19C42-7A3D-4F81-9C26-0D4A8B3E7F51}']
    /// Leiste hinter den Reitern. Style.Color = Hintergrund (clNone = nichts).
    procedure DrawTabStrip(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Bottom: Boolean; PPI: Integer);
    /// Ein Reiter. Gewaehlt: Style = Seitenfarben; sonst Style = Reiterflaeche
    /// (bei Classic ein Glanz-Verlauf), HotProgress 0..1.
    procedure DrawTab(const Canvas: IPPGCanvas; const R: TRect;
      const Style: TPPGSurfaceStyle; Selected: Boolean; HotProgress: Single;
      Bottom: Boolean; PPI: Integer);
    /// Markierung des gewaehlten Reiters (gleitet beim Wechsel).
    procedure DrawTabIndicator(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Bottom: Boolean; PPI: Integer);
    procedure DrawTabClose(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Hot: Boolean; PPI: Integer);
    /// Blaetterpfeil bei Ueberlauf; Forward = nach rechts.
    procedure DrawTabScrollArrow(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Forward, Hot, Enabled: Boolean; PPI: Integer);
  end;

  /// Overlay-Scrollleisten (Scroll-Controls). Track = gesamte Leiste in ihrer
  /// breiten Form, Thumb = Daumen darin. Expand 0..1: 0 = ruhend schmal
  /// (nur Daumen als duenne Linie am Rand), 1 = breit mit Spur.
  /// Style.TextColor = Farbe des Daumens, Style.Color = Hintergrund darunter.
  /// Design-Tokens eines Presets (Hell/Dunkel) und ihre Abbildung auf die
  /// Farben der Appearance. ApplyThemeColors setzt NUR Farben (keine Formen);
  /// ApplyDefaults = ApplyThemeColors(Hell) + Formen des Presets.
  IPPGThemeRenderer = interface
    ['{F2A64C17-8D35-4B9E-A6C0-3E71D58B9F24}']
    function Tokens(Dark: Boolean): TPPGTokens;
    procedure ApplyThemeColors(Appearance: TPPGAppearance; Dark: Boolean);
  end;

  /// Eintraege von ListBox, CheckListBox und TreeView (Phase 6).
  /// ListStyle: Color = Listenhintergrund, TextColor = Text, GlowColor = Akzent
  /// (Auswahlbalken), BorderColor = Trennlinien. HighlightStyle = Hover-Flaeche
  /// (bei Classic ein Glanz-Verlauf aus Color/ColorTo/ColorMirror/ColorMirrorTo).
  IPPGItemRenderer = interface
    ['{9E4B7C21-3D58-4A6F-B0E2-7C1D95F3A486}']
    /// Hintergrund eines Eintrags. Selected = gewaehlt, Focused = Tastaturfokus
    /// (nur wenn das Control den Fokus hat und Fokus-Cues sichtbar sind),
    /// Hot 0..1 = Hover. RightToLeft spiegelt den Auswahlbalken.
    procedure DrawItemBackground(const Canvas: IPPGCanvas; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Selected, Focused: Boolean;
      Hot: Single; RightToLeft: Boolean; PPI: Integer);
    /// Ueberschrift einer Gruppe (Text und Trennlinie in R).
    procedure DrawGroupHeader(const Canvas: IPPGCanvas; const R: TRect; const Text: string;
      Font: TFont; const ListStyle: TPPGSurfaceStyle; RightToLeft: Boolean; PPI: Integer);
    /// Groesse einer Plakette (z.B. Anzahl) fuer Text.
    function BadgeSize(const Canvas: IPPGCanvas; const Text: string; Font: TFont;
      PPI: Integer): TSize;
    procedure DrawBadge(const Canvas: IPPGCanvas; const R: TRect; const Text: string;
      Font: TFont; Fill, TextColor: TColor; PPI: Integer);
    /// Auf-/Zuklapp-Pfeil (Baum). Expanded 0..1 dreht von "zu" (zeigt nach
    /// rechts, bei RTL nach links) nach "auf" (zeigt nach unten).
    procedure DrawExpander(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      Expanded: Single; RightToLeft: Boolean; PPI: Integer);
    /// Verbindungslinien des Baums (optional, ShowLines).
    procedure DrawTreeLine(const Canvas: IPPGCanvas; const Points: array of TPoint;
      Color: TColor; PPI: Integer);
    /// Einfuegemarke beim Umsortieren/Ziehen (waagerechte Linie in R).
    procedure DrawDropIndicator(const Canvas: IPPGCanvas; const R: TRect; Color: TColor;
      PPI: Integer);
  end;

  IPPGScrollRenderer = interface
    ['{2C7E4A91-B5D3-4F06-8E1A-6F9B3D0C5A72}']
    procedure DrawScrollBar(const Canvas: IPPGCanvas; const Track, Thumb: TRect;
      const Style: TPPGSurfaceStyle; Vertical: Boolean; Expand: Single;
      Hot, Pressed: Boolean; PPI: Integer);
  end;

implementation

end.
