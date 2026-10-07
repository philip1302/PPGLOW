unit DemoKit;

// Bausteine der Demo: Typografie nach Windows 11 (Segoe UI Variable, Type
// Ramp), Seitenkopf, Karten, Ergebniszeilen und Akzent-Buttons.
//
// Texte: Quelltexte sind reines ASCII. Umlaute und Sonderzeichen stehen als
// Kuerzel in geschweiften Klammern im Text und werden von L() ersetzt:
//   {ae} {oe} {ue} {Ae} {Oe} {Ue} {ss}   Umlaute, sz
//   {-} Gedankenstrich   {.} Mittelpunkt   {EUR} Euro   {...} Auslassung
//   {>} Pfeil nach rechts   {x} Mal-Zeichen
// Alle New*-Funktionen und SetResult rufen L() selbst auf.
// (Kommentar mit // statt geschweifter Klammern, weil die Kuerzel sie enthalten.)
//
// Die Seiten sprechen das Hauptformular nur ueber IDemoHost an.

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.ImgList, Vcl.StdCtrls,
  PPG.Types, PPG.Tokens, PPG.Appearance, PPG.Theme, PPG.Controls.Base, PPG.Button, PPG.Panel,
  PPG.Labels, PPG.PageControl, PPG.Notifications, PPG.Hints;

type
  TDemoTextKind = (tkBody, tkStrong, tkSecondary, tkCaption, tkCardTitle,
    tkSubtitle, tkTitle, tkDisplay, tkIcon, tkIconLarge, tkValue);

  /// Was die Seiten vom Hauptformular brauchen.
  IDemoHost = interface
    ['{6B0E2F4C-31D7-4E8A-9C55-0F8A3B7D1E62}']
    /// Ereignis protokollieren (Seite "Ereignisse" und Statusleiste).
    procedure Log(const Category, Text: string);
    function Notifier: TPPGNotificationCenter;
    function Images: TCustomImageList;
    procedure GoToPage(Index: Integer);
    function CurrentPreset: string;
    procedure ApplyPreset(const AName: string);
    procedure ApplyVclStyle(const AName: string);
    /// Control fuer den Screenshot-Modus bekannt machen ('fieldfocus',
    /// 'dropdown', 'dropdownimages', 'datepicker').
    procedure RegisterSpecial(const Key: string; C: TControl);
  end;

  /// Basis aller Demo-Seiten (eine Klasse pro Seite, Ereignisse inklusive).
  TDemoCheck = procedure(const AName: string; AOk: Boolean) of object;

  TDemoPage = class(TComponent)
  private
    FHost: IDemoHost;
    FSheet: TPPGTabSheet;
  protected
    procedure Build; virtual; abstract;
    function Own: TComponent;
    property Host: IDemoHost read FHost;
    property Sheet: TPPGTabSheet read FSheet;
  public
    constructor CreatePage(AOwner: TComponent; const AHost: IDemoHost; ASheet: TPPGTabSheet);
    /// Wird nach jedem Preset-, Theme- oder Style-Wechsel aufgerufen.
    procedure AppearanceChanged; virtual;
    /// Seite wurde sichtbar.
    procedure Activated; virtual;
    /// Selbsttest (/selftest): Szenarien der Seite ausloesen und pruefen.
    procedure SelfTest(Check: TDemoCheck); virtual;
  end;
  TDemoPageClass = class of TDemoPage;

  /// Merkt sich Controls mit Akzentfarbe und faerbt sie bei Theme-/Preset-
  /// Wechsel neu (eigene Farben folgen dem Dark Mode bewusst nicht).
  TDemoStyler = class(TComponent)
  private
    FButtons: TList<TPPGButton>;
    FLabels: TList<TPPGLabel>;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddAccentButton(B: TPPGButton);
    procedure AddAccentLabel(Lbl: TPPGLabel);
    procedure Refresh;
    /// Akzentfarbe des aktuellen Presets im aktuellen Modus.
    function Accent: TColor;
    function Tokens: TPPGTokens;
  end;

const
  PageX = 36;           // Seitenrand links (Windows 11: 36 - 56 epx)
  PageTop = 24;
  PageContentTop = 104; // unter Titel und Untertitel
  CardGap = 16;         // Abstand zwischen Karten
  CardPad = 20;         // Innenabstand der Karten
  CtlH = 32;            // Standardhoehe von Bedienelementen (Fluent)
  StylesDir = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0\Styles\';

var
  /// Wird vom Hauptformular angelegt.
  DemoStyler: TDemoStyler;
  /// Hints der ganzen Demo (vom Hauptformular angelegt).
  DemoHints: TPPGHintManager;
  /// Name des aktiven Presets (fuer die Akzentfarbe).
  DemoPreset: string;

/// Ersetzt die Kuerzel fuer Umlaute und Sonderzeichen (siehe Kopf der Unit).
function L(const S: string): string;
/// Schriftfamilie der Textart (Segoe UI Variable, sonst Segoe UI).
procedure ApplyTextKind(AFont: TFont; Kind: TDemoTextKind);
function BodyFontName: string;

function NewLabel(AOwner: TComponent; AParent: TWinControl; X, Y, W: Integer;
  const ACaption: string; Kind: TDemoTextKind = tkBody): TPPGLabel;
/// Symbol aus Segoe Fluent Icons (Codepunkt, z.B. $E80F).
function NewIcon(AOwner: TComponent; AParent: TWinControl; X, Y: Integer;
  CodePoint: Word; Large: Boolean = False; Accent: Boolean = True): TPPGLabel;
/// Titel + Untertitel einer Seite.
procedure NewPageHeader(AOwner: TComponent; APage: TWinControl; const ATitle, ASubtitle: string);
/// Karte mit Titel und Beschreibung. Tag = erste freie Zeile fuer Inhalt.
function NewCard(AOwner: TComponent; AParent: TWinControl; X, Y, W, H: Integer;
  const ATitle, ADescription: string): TPPGPanel;
/// Ergebniszeile ("Ergebnis: Wert") am unteren Rand einer Karte.
function NewResult(AOwner: TComponent; ACard: TPPGPanel; const APrefix: string): TPPGLabel;
procedure SetResult(Lbl: TPPGLabel; const AValue: string);
function NewButton(AOwner: TComponent; AParent: TWinControl; X, Y, W: Integer;
  const ACaption: string; AOnClick: TNotifyEvent; Accent: Boolean = False): TPPGButton;
/// Klick per Mausnachrichten (ohne den echten Mauszeiger), fuer den Selbsttest.
procedure DemoClick(C: TControl);
/// Escape fuer Markup-Text (Werte aus Eingaben).
function MarkupEscape(const S: string): string;
/// Deutsch formatierte Zahl mit zwei Nachkommastellen und Euro.
function Euro(Value: Double): string;

implementation

uses
  Winapi.Messages, System.Types, PPG.Render.Intf, PPG.Render.Registry, PPG.IconFont, Vcl.Forms;

function L(const S: string): string;
begin
  Result := S;
  if Pos('{', Result) = 0 then
    Exit;
  Result := StringReplace(Result, '{ae}', #$00E4, [rfReplaceAll]);
  Result := StringReplace(Result, '{oe}', #$00F6, [rfReplaceAll]);
  Result := StringReplace(Result, '{ue}', #$00FC, [rfReplaceAll]);
  Result := StringReplace(Result, '{Ae}', #$00C4, [rfReplaceAll]);
  Result := StringReplace(Result, '{Oe}', #$00D6, [rfReplaceAll]);
  Result := StringReplace(Result, '{Ue}', #$00DC, [rfReplaceAll]);
  Result := StringReplace(Result, '{ss}', #$00DF, [rfReplaceAll]);
  Result := StringReplace(Result, '{-}', #$2013, [rfReplaceAll]);
  Result := StringReplace(Result, '{.}', #$00B7, [rfReplaceAll]);
  Result := StringReplace(Result, '{EUR}', #$20AC, [rfReplaceAll]);
  Result := StringReplace(Result, '{...}', #$2026, [rfReplaceAll]);
  Result := StringReplace(Result, '{>}', #$203A, [rfReplaceAll]);
  Result := StringReplace(Result, '{x}', #$00D7, [rfReplaceAll]);
end;

function MarkupEscape(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

function Euro(Value: Double): string;
var
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create('de-DE');
  Result := FormatFloat('#,##0.00', Value, FS) + ' ' + #$20AC;
end;

function FontExists(const AName: string): Boolean;
begin
  Result := Screen.Fonts.IndexOf(AName) >= 0;
end;

var
  GBodyFont: string;
  GTitleFont: string;      // Semibold-Familie fuer Titel
  GTitleBold: Boolean;     // keine Semibold-Familie: fett
  GStrongFont: string;
  GStrongBold: Boolean;

procedure ResolveFonts;
begin
  if GBodyFont <> '' then
    Exit;
  if FontExists('Segoe UI Variable Text') then
    GBodyFont := 'Segoe UI Variable Text'
  else
    GBodyFont := 'Segoe UI';
  // GDI kennt die Semibold-Stufen als eigene Familien
  if FontExists('Segoe UI Variable Display Semib') then
    GTitleFont := 'Segoe UI Variable Display Semib'
  else if FontExists('Segoe UI Semibold') then
    GTitleFont := 'Segoe UI Semibold'
  else
  begin
    GTitleFont := 'Segoe UI';
    GTitleBold := True;
  end;
  if FontExists('Segoe UI Variable Text Semibold') then
    GStrongFont := 'Segoe UI Variable Text Semibold'
  else if FontExists('Segoe UI Semibold') then
    GStrongFont := 'Segoe UI Semibold'
  else
  begin
    GStrongFont := 'Segoe UI';
    GStrongBold := True;
  end;
end;

function BodyFontName: string;
begin
  ResolveFonts;
  Result := GBodyFont;
end;

procedure ApplyTextKind(AFont: TFont; Kind: TDemoTextKind);
begin
  ResolveFonts;
  AFont.Style := [];
  // Standardfarbe ausdruecklich setzen: TPPGLabel faerbt nur Standardfarben im
  // Dark Mode um. Ohne diese Zeile erbt ein Label mit eigener Schrift die
  // Formularschrift samt der festen Farbe, die TPPGTheme.StyleForms dort setzt.
  AFont.Color := clWindowText;
  // Windows-11-Type-Ramp: Caption 12, Body 14, Body Strong 14, Subtitle 20,
  // Title 28, Display 40 epx (in Punkt: x 0,75)
  case Kind of
    tkBody, tkSecondary:
      begin
        AFont.Name := GBodyFont;
        AFont.Size := 10;
      end;
    tkCaption:
      begin
        AFont.Name := GBodyFont;
        AFont.Size := 9;
      end;
    tkStrong, tkCardTitle:
      begin
        AFont.Name := GStrongFont;
        AFont.Size := 11;
        if Kind = tkStrong then
          AFont.Size := 10;
        if GStrongBold then
          AFont.Style := [fsBold];
      end;
    tkSubtitle, tkTitle, tkDisplay, tkValue:
      begin
        AFont.Name := GTitleFont;
        case Kind of
          tkSubtitle: AFont.Size := 15;
          tkTitle: AFont.Size := 21;
          tkValue: AFont.Size := 24;
        else
          AFont.Size := 30;
        end;
        if GTitleBold then
          AFont.Style := [fsBold];
      end;
    tkIcon, tkIconLarge:
      begin
        AFont.Name := PPGIconFontName;
        if AFont.Name = '' then
          AFont.Name := 'Segoe UI Symbol';
        if Kind = tkIcon then
          AFont.Size := 15
        else
          AFont.Size := 24;
      end;
  end;
end;

function NewLabel(AOwner: TComponent; AParent: TWinControl; X, Y, W: Integer;
  const ACaption: string; Kind: TDemoTextKind): TPPGLabel;
begin
  Result := TPPGLabel.Create(AOwner);
  Result.Parent := AParent;
  Result.Transparent := True;
  Result.ShowAccelChar := False;
  // Markup nur bei Tags: sonst misst der Parser z.B. ein "&" anders
  Result.AllowMarkup := Pos('<', ACaption) > 0;
  ApplyTextKind(Result.Font, Kind);
  Result.Secondary := Kind in [tkSecondary, tkCaption];
  Result.SetBounds(X, Y, W, 20);
  if W > 0 then
  begin
    Result.AutoSize := False;
    Result.WordWrap := True;
    Result.Width := W;
    Result.Caption := L(ACaption);
    // Hoehe nach Text (Umbruch) per AutoSize; AutoSize schrumpft dabei auch
    // die Breite auf den Text, deshalb danach die feste Breite zurueck
    Result.AutoSize := True;
    Result.AutoSize := False;
    Result.Width := W;
  end
  else
    Result.Caption := L(ACaption);
end;

function NewIcon(AOwner: TComponent; AParent: TWinControl; X, Y: Integer;
  CodePoint: Word; Large, Accent: Boolean): TPPGLabel;
begin
  Result := TPPGLabel.Create(AOwner);
  Result.Parent := AParent;
  Result.Transparent := True;
  Result.ShowAccelChar := False;
  if Large then
    ApplyTextKind(Result.Font, tkIconLarge)
  else
    ApplyTextKind(Result.Font, tkIcon);
  Result.Left := X;
  Result.Top := Y;
  Result.Caption := Char(CodePoint);
  if Accent and (DemoStyler <> nil) then
    DemoStyler.AddAccentLabel(Result);
end;

procedure NewPageHeader(AOwner: TComponent; APage: TWinControl; const ATitle, ASubtitle: string);
begin
  NewLabel(AOwner, APage, PageX, PageTop, 0, ATitle, tkTitle);
  NewLabel(AOwner, APage, PageX, PageTop + 44, 900, ASubtitle, tkSecondary);
end;

function NewCard(AOwner: TComponent; AParent: TWinControl; X, Y, W, H: Integer;
  const ATitle, ADescription: string): TPPGPanel;
var
  T, D: TPPGLabel;
  Top: Integer;
begin
  Result := TPPGPanel.Create(AOwner);
  Result.Parent := AParent;
  Result.ShowCaption := False;
  Result.Caption := '';
  Result.SetBounds(X, Y, W, H);
  Top := 16;
  if ATitle <> '' then
  begin
    T := NewLabel(AOwner, Result, CardPad, Top, 0, ATitle, tkCardTitle);
    Top := T.Top + T.Height + 2;
  end;
  if ADescription <> '' then
  begin
    D := NewLabel(AOwner, Result, CardPad, Top, W - 2 * CardPad, ADescription, tkSecondary);
    Top := D.Top + D.Height;
  end;
  Result.Tag := Top + 14;
end;

function NewResult(AOwner: TComponent; ACard: TPPGPanel; const APrefix: string): TPPGLabel;
begin
  Result := NewLabel(AOwner, ACard, CardPad, ACard.Height - 34, ACard.Width - 2 * CardPad,
    APrefix, tkBody);
  // Prefix merken, SetResult haengt den Wert an
  Result.Hint := L(APrefix);
  Result.AllowMarkup := True;
  Result.WordWrap := False;
  Result.AutoSize := False;
  Result.Width := ACard.Width - 2 * CardPad;
  Result.Height := 20;
  Result.Anchors := [akLeft, akBottom];
  SetResult(Result, '{-}');
end;

procedure SetResult(Lbl: TPPGLabel; const AValue: string);
begin
  if Lbl <> nil then
    Lbl.Caption := Lbl.Hint + ': <b>' + L(AValue) + '</b>';
end;

function NewButton(AOwner: TComponent; AParent: TWinControl; X, Y, W: Integer;
  const ACaption: string; AOnClick: TNotifyEvent; Accent: Boolean): TPPGButton;
begin
  Result := TPPGButton.Create(AOwner);
  Result.Parent := AParent;
  Result.SetBounds(X, Y, W, CtlH);
  Result.Preset := DemoPreset;
  Result.Caption := L(ACaption);
  Result.OnClick := AOnClick;
  if Accent and (DemoStyler <> nil) then
    DemoStyler.AddAccentButton(Result);
end;

{ TDemoPage }

constructor TDemoPage.CreatePage(AOwner: TComponent; const AHost: IDemoHost;
  ASheet: TPPGTabSheet);
begin
  inherited Create(AOwner);
  FHost := AHost;
  FSheet := ASheet;
  Build;
end;

function TDemoPage.Own: TComponent;
begin
  // Controls gehoeren dem Formular (Preset-Wechsel laeuft ueber Components)
  Result := Owner;
end;

procedure TDemoPage.AppearanceChanged;
begin
end;

procedure TDemoPage.Activated;
begin
end;

procedure TDemoPage.SelfTest(Check: TDemoCheck);
begin
end;

procedure DemoClick(C: TControl);
var
  P: TPoint;
begin
  P := Point(C.Width div 2, C.Height div 2);
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, PointToLParam(P));
  C.Perform(WM_LBUTTONUP, 0, PointToLParam(P));
end;

{ TDemoStyler }

constructor TDemoStyler.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FButtons := TList<TPPGButton>.Create;
  FLabels := TList<TPPGLabel>.Create;
end;

destructor TDemoStyler.Destroy;
begin
  if DemoStyler = Self then
    DemoStyler := nil;
  FButtons.Free;
  FLabels.Free;
  inherited Destroy;
end;

procedure TDemoStyler.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if FButtons <> nil then
      FButtons.Remove(TPPGButton(AComponent));
    if FLabels <> nil then
      FLabels.Remove(TPPGLabel(AComponent));
  end;
end;

function TDemoStyler.Tokens: TPPGTokens;
var
  TR: IPPGThemeRenderer;
begin
  if Supports(TPPGRendererRegistry.Get(DemoPreset), IPPGThemeRenderer, TR) then
    Result := TR.Tokens(TPPGTheme.IsDark)
  else
    Result := PPGDefaultTokens(TPPGTheme.IsDark);
end;

function TDemoStyler.Accent: TColor;
begin
  Result := Tokens.Accent;
end;

procedure TDemoStyler.AddAccentButton(B: TPPGButton);
begin
  if FButtons.IndexOf(B) < 0 then
  begin
    FButtons.Add(B);
    B.FreeNotification(Self);
  end;
  Refresh;
end;

procedure TDemoStyler.AddAccentLabel(Lbl: TPPGLabel);
begin
  if FLabels.IndexOf(Lbl) < 0 then
  begin
    FLabels.Add(Lbl);
    Lbl.FreeNotification(Self);
  end;
  Refresh;
end;

procedure TDemoStyler.Refresh;

  procedure Fill(S: TPPGStateStyle; C, Txt: TColor);
  begin
    S.Color := C;
    S.ColorTo := C;
    S.ColorMirror := C;
    S.ColorMirrorTo := C;
    S.BorderColor := C;
    S.GlowColor := C;
    S.TextColor := Txt;
  end;

var
  T: TPPGTokens;
  B: TPPGButton;
  Lbl: TPPGLabel;
begin
  T := Tokens;
  for B in FButtons do
  begin
    // Eigene Farben auch im Dark Mode behalten (seClient aus), dafuer selbst
    // die dunkle Variante setzen
    {$IF CompilerVersion >= 24.0}
    B.StyleElements := B.StyleElements - [seClient];
    {$IFEND}
    B.Appearance.BeginUpdate;
    try
      Fill(B.Appearance.Normal, T.Accent, T.OnAccent);
      Fill(B.Appearance.Hot, T.AccentHover, T.OnAccent);
      Fill(B.Appearance.Down, T.AccentPressed, T.OnAccent);
      Fill(B.Appearance.Checked, T.AccentPressed, T.OnAccent);
      Fill(B.Appearance.Disabled, T.SurfaceDisabled, T.TextDisabled);
      B.Appearance.Disabled.BorderColor := T.StrokeDisabled;
    finally
      B.Appearance.EndUpdate;
    end;
  end;
  for Lbl in FLabels do
    Lbl.Font.Color := T.Accent;
end;

end.
