unit ExColorPickerHighlight;

// Praxisbeispiel 2 zu TPPGColorPicker (Demo-Seite "Eingabe > TPPGColorPicker"):
// Einstellung "Markierung in der Rechnungsliste" mit Hexwert (ShowHex),
// "Standard" = keine Markierung (cbIncludeDefault, DefaultColorColor),
// Pruefung per ValidationState und Speichern/Verwerfen der Einstellung
// samt "zuletzt benutzt" (Selected, RecentColors).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  Vcl.StdCtrls, Vcl.ExtCtrls, PPG.StyleManager, PPG.Controls.Field, PPG.Labels,
  PPG.Button, PPG.ColorPicker;

type
  /// Einstellungen "Markierung in der Rechnungsliste": eine Farbe fuer offene
  /// und eine fuer gemahnte Rechnungen; beide muessen sich unterscheiden.
  THighlightSettings = class(TComponent)
  private
    FOpen: TPPGColorPicker;
    FDunned: TPPGColorPicker;
    FOpenRow: TPPGLabel;
    FDunnedRow: TPPGLabel;
    FSave: TPPGButton;
    FDiscard: TPPGButton;
    FStatus: TPPGLabel;
    FStore: TStringList;
    function NewPicker(AParent: TWinControl; Y: Integer; const ACaption: string;
      AStyles: TPPGStyleManager): TPPGColorPicker;
    function NewRow(AParent: TWinControl; Y: Integer; const ACaption: string): TPPGLabel;
    procedure ColorChange(Sender: TObject);
    procedure SaveClick(Sender: TObject);
    procedure DiscardClick(Sender: TObject);
    procedure UpdatePreview;
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    destructor Destroy; override;
    /// Einstellungen schreiben bzw. lesen (hier eine Liste, sonst Ini/Registry).
    procedure SaveTo(AStore: TStrings);
    procedure LoadFrom(AStore: TStrings);
    property OpenColor: TPPGColorPicker read FOpen;
    property DunnedColor: TPPGColorPicker read FDunned;
    property OpenRow: TPPGLabel read FOpenRow;
    property DunnedRow: TPPGLabel read FDunnedRow;
    property SaveButton: TPPGButton read FSave;
    property DiscardButton: TPPGButton read FDiscard;
    property Store: TStringList read FStore;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TextColorFor(Back: TColor): TColor;
var
  RGB: Longint;
begin
  // Auf dunklem Grund weisse, sonst dunkle Schrift
  RGB := ColorToRGB(Back);
  if (GetRValue(RGB) * 299 + GetGValue(RGB) * 587 + GetBValue(RGB) * 114) div 1000 < 128 then
    Result := clWhite
  else
    Result := $00202020;
end;

function THighlightSettings.NewPicker(AParent: TWinControl; Y: Integer;
  const ACaption: string; AStyles: TPPGStyleManager): TPPGColorPicker;
var
  Lbl: TPPGLabel;
begin
  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(16, Y + 6, 150, 20);
  Lbl.Caption := ACaption;

  Result := TPPGColorPicker.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(176, Y, 180, 32);
  Result.StyleManager := AStyles;
  // "Standard" = keine Markierung; das Farbfeld zeigt dann Weiss wie die Liste
  Result.Style := [cbIncludeDefault, cbStandardColors, cbExtendedColors,
    cbCustomColor, cbPrettyNames];
  Result.DefaultColorColor := clWindow;
  // Feste Palette: die Markierung soll in jedem Preset gleich aussehen
  Result.ShowThemeColors := False;
  // Hexwert wie im Corporate-Design-Handbuch
  Result.ShowHex := True;
  Result.MaxRecent := 4;
  Result.OnChange := ColorChange;
end;

function THighlightSettings.NewRow(AParent: TWinControl; Y: Integer;
  const ACaption: string): TPPGLabel;
begin
  // Vorschau einer Listenzeile: Hintergrund = gewaehlte Markierung
  Result := TPPGLabel.Create(Self);
  Result.Parent := AParent;
  Result.AutoSize := False;
  Result.SetBounds(16, Y, 414, 28);
  Result.Transparent := False;
  Result.Layout := tlCenter;
  Result.Caption := ACaption;
end;

constructor THighlightSettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStore := TStringList.Create;
  FOpen := NewPicker(AParent, 16, 'Offene Rechnungen:', AStyles);
  FOpen.Selected := clDefault;
  FDunned := NewPicker(AParent, 56, 'Gemahnte Rechnungen:', AStyles);
  FDunned.Selected := $00C0C0FF;   // helles Rot

  FOpenRow := NewRow(AParent, 100, '  RE-2026-114    Schmidt GmbH    1.250,00 EUR    offen');
  FDunnedRow := NewRow(AParent, 130, '  RE-2026-087    Weber KG    480,00 EUR    1. Mahnung');

  FSave := TPPGButton.Create(Self);
  FSave.Parent := AParent;
  FSave.SetBounds(16, 172, 110, 32);
  FSave.Caption := 'Speichern';
  FSave.StyleManager := AStyles;
  FSave.OnClick := SaveClick;

  FDiscard := TPPGButton.Create(Self);
  FDiscard.Parent := AParent;
  FDiscard.SetBounds(134, 172, 110, 32);
  FDiscard.Caption := 'Verwerfen';
  FDiscard.StyleManager := AStyles;
  FDiscard.OnClick := DiscardClick;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 214, 414, 20);
  FStatus.Caption := 'Aktuelle Farben sind gespeichert.';

  SaveTo(FStore);
  UpdatePreview;
end;

destructor THighlightSettings.Destroy;
begin
  FStore.Free;
  inherited Destroy;
end;

procedure THighlightSettings.UpdatePreview;
var
  C: TColor;
begin
  C := FOpen.Selected;
  if C = clDefault then
    C := FOpen.DefaultColorColor;
  FOpenRow.Color := C;
  FOpenRow.Font.Color := TextColorFor(C);
  C := FDunned.Selected;
  if C = clDefault then
    C := FDunned.DefaultColorColor;
  FDunnedRow.Color := C;
  FDunnedRow.Font.Color := TextColorFor(C);

  // Beide gleich: in der Liste nicht unterscheidbar
  if FOpen.Selected = FDunned.Selected then
  begin
    FDunned.ValidationState := pvsError;
    FDunned.ValidationHint := 'Gleiche Farbe wie "Offene Rechnungen".';
  end
  else
  begin
    FDunned.ValidationState := pvsNone;
    FDunned.ValidationHint := '';
  end;
  FSave.Enabled := FDunned.ValidationState <> pvsError;
end;

procedure THighlightSettings.ColorChange(Sender: TObject);
begin
  // "Zuletzt benutzt" in beiden Pickern gleich halten
  if Sender = FOpen then
    FDunned.RecentColors.Assign(FOpen.RecentColors)
  else
    FOpen.RecentColors.Assign(FDunned.RecentColors);
  UpdatePreview;
  FStatus.Caption := 'Farbe gewechselt, noch nicht gespeichert.';
end;

procedure THighlightSettings.SaveTo(AStore: TStrings);
begin
  AStore.Values['Offen'] := ColorToString(FOpen.Selected);
  AStore.Values['Gemahnt'] := ColorToString(FDunned.Selected);
  // "Zuletzt benutzt" mitspeichern, damit die Hausfarben oben bleiben
  AStore.Values['Zuletzt'] := FDunned.RecentColors.CommaText;
end;

procedure THighlightSettings.LoadFrom(AStore: TStrings);
begin
  // Selected aus Code: kein OnChange, deshalb Vorschau selbst aktualisieren
  FOpen.Selected := StringToColor(AStore.Values['Offen']);
  FDunned.Selected := StringToColor(AStore.Values['Gemahnt']);
  FOpen.RecentColors.CommaText := AStore.Values['Zuletzt'];
  FDunned.RecentColors.CommaText := AStore.Values['Zuletzt'];
  UpdatePreview;
end;

procedure THighlightSettings.SaveClick(Sender: TObject);
begin
  SaveTo(FStore);
  FStatus.Caption := 'Gespeichert: ' + FDunned.ColorName(FDunned.Selected);
end;

procedure THighlightSettings.DiscardClick(Sender: TObject);
begin
  LoadFrom(FStore);
  FStatus.Caption := 'Gespeicherte Farben wiederhergestellt.';
end;
// EXAMPLE-END

end.
