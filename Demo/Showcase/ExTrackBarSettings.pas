unit ExTrackBarSettings;

// Praxisbeispiel 1 zu TPPGTrackBar (Demo-Seite "Auswahl > TPPGTrackBar"):
// Einstellungsseite "Ansicht" mit zwei Schiebereglern: Zoom der Liste
// (Min/Max, Frequency, LineSize/PageSize, empfohlener Bereich mit
// SelStart/SelEnd) und Intervall fuer automatisches Sichern (0 = aus).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.ComCtrls,
  PPG.StyleManager, PPG.Labels, PPG.TrackBar;

type
  /// Einstellungen "Ansicht": Zoom der Kundenliste und Intervall fuer das
  /// automatische Sichern. Jede Aenderung wirkt sofort (OnChange).
  TViewSettings = class(TComponent)
  private
    FZoomLabel: TPPGLabel;
    FZoom: TPPGTrackBar;
    FIntervalLabel: TPPGLabel;
    FInterval: TPPGTrackBar;
    FPreview: TPPGLabel;
    function NewLabel(AParent: TWinControl; Y: Integer; const ACaption: string): TPPGLabel;
    function NewTrackBar(AParent: TWinControl; Y: Integer;
      AStyles: TPPGStyleManager): TPPGTrackBar;
    procedure ZoomChange(Sender: TObject);
    procedure IntervalChange(Sender: TObject);
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Zoom: TPPGTrackBar read FZoom;
    property ZoomLabel: TPPGLabel read FZoomLabel;
    property Interval: TPPGTrackBar read FInterval;
    property IntervalLabel: TPPGLabel read FIntervalLabel;
    property Preview: TPPGLabel read FPreview;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TViewSettings.NewLabel(AParent: TWinControl; Y: Integer;
  const ACaption: string): TPPGLabel;
begin
  Result := TPPGLabel.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(16, Y, 418, 20);
  Result.Caption := ACaption;
end;

function TViewSettings.NewTrackBar(AParent: TWinControl; Y: Integer;
  AStyles: TPPGStyleManager): TPPGTrackBar;
begin
  Result := TPPGTrackBar.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(16, Y, 418, 40);
  Result.StyleManager := AStyles;
end;

constructor TViewSettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  // Zoom 50..200 %: Pfeiltasten in 5er-, Bild auf/ab in 25er-Schritten,
  // ein Teilstrich je 25 %. Der markierte Bereich zeigt die Empfehlung.
  // Erst Max, dann Min setzen: Min > Max loest eine Exception aus.
  FZoomLabel := NewLabel(AParent, 16, '');
  FZoom := NewTrackBar(AParent, 40, AStyles);
  FZoom.Max := 200;
  FZoom.Min := 50;
  FZoom.Frequency := 25;
  FZoom.LineSize := 5;
  FZoom.PageSize := 25;
  FZoom.SelStart := 90;
  FZoom.SelEnd := 125;
  FZoom.Position := 100;
  FZoom.Hint := 'Empfohlen: 90 bis 125 %';
  FZoom.ShowHint := True;
  FZoom.OnChange := ZoomChange;

  // Automatisch sichern: 0 (aus) bis 60 Minuten, Teilstriche oben und unten
  FIntervalLabel := NewLabel(AParent, 92, '');
  FInterval := NewTrackBar(AParent, 122, AStyles);
  FInterval.Height := 46;   // Platz fuer Teilstriche oben und unten
  FInterval.Max := 60;
  FInterval.Frequency := 5;
  FInterval.PageSize := 5;
  FInterval.TickMarks := tmBoth;
  FInterval.Position := 10;
  FInterval.OnChange := IntervalChange;

  FPreview := NewLabel(AParent, 184, 'Kunde 10042 - Berger Logistik GmbH');
  FPreview.Height := 48;

  // Anfangszustand anzeigen (OnChange kam vor der Zuweisung)
  ZoomChange(FZoom);
  IntervalChange(FInterval);
end;

procedure TViewSettings.ZoomChange(Sender: TObject);
begin
  FZoomLabel.Caption := Format('Zoom der Kundenliste: %d %%', [FZoom.Position]);
  // Grundschrift 9 pt, skaliert mit dem Zoom
  FPreview.Font.Size := Round(9 * FZoom.Position / 100);
end;

procedure TViewSettings.IntervalChange(Sender: TObject);
begin
  if FInterval.Position = 0 then
    FIntervalLabel.Caption := 'Automatisch sichern: aus'
  else
    FIntervalLabel.Caption := Format('Automatisch sichern alle %d Minuten',
      [FInterval.Position]);
end;
// EXAMPLE-END

end.
