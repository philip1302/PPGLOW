unit DemoShowTrackBar;

// Komponentenseite TPPGTrackBar (Gruppe "Auswahl"): Buehne und Inspektor
// kommen aus TDemoComponentPage; hier stehen nur die Besonderheiten des
// Schiebereglers (Breite und Startwert auf der Buehne, Wert im Protokoll,
// eigene Kategorien) und die beiden Praxisbeispiele (ExTrackBarSettings,
// ExTrackBarPriceFilter).

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.TrackBar, DemoKit, DemoShowcase, ExTrackBarSettings, ExTrackBarPriceFilter;

type
  TDemoShowTrackBarPage = class(TDemoComponentPage)
  private
    FSettings: TViewSettings;
    FFilter: TPriceFilter;
  protected
    function SubjectClass: TComponentClass; override;
    procedure SetupSubject(ASubject: TComponent); override;
    procedure BuildExamples; override;
    procedure CategoryFor(Sender: TObject; const AName: string; var ACategory: string); override;
    procedure EventOccurred(const AName, ADetail: string); override;
  public
    procedure SelfTest(Check: TDemoCheck); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.Messages;

function TDemoShowTrackBarPage.SubjectClass: TComponentClass;
begin
  Result := TPPGTrackBar;
end;

procedure TDemoShowTrackBarPage.SetupSubject(ASubject: TComponent);
begin
  inherited SetupSubject(ASubject);
  // Breiter als aus der Palette (150), damit Ticks und Bereiche lesbar sind
  if ASubject is TPPGTrackBar then
  begin
    TPPGTrackBar(ASubject).Width := 320;
    TPPGTrackBar(ASubject).Position := 3;
  end;
end;

procedure TDemoShowTrackBarPage.CategoryFor(Sender: TObject; const AName: string;
  var ACategory: string);
begin
  if SameText(AName, 'Min') or SameText(AName, 'Max') or SameText(AName, 'Position') or
    SameText(AName, 'PositionEnd') or SameText(AName, 'SelStart') or SameText(AName, 'SelEnd') then
    ACategory := 'Inhalt'
  else if SameText(AName, 'RangeMode') then
    ACategory := 'Verhalten'
  else if SameText(AName, 'LineSize') or SameText(AName, 'PageSize') then
    ACategory := 'Tastatur & Fokus'
  else if SameText(AName, 'Orientation') or SameText(AName, 'ThumbLength') then
    ACategory := 'Layout'
  else if SameText(AName, 'Frequency') or SameText(AName, 'TickMarks') or
    SameText(AName, 'TickStyle') or SameText(AName, 'ShowSlider') or
    SameText(AName, 'ShowSelRange') then
    ACategory := 'Darstellung (VCL)';
end;

procedure TDemoShowTrackBarPage.EventOccurred(const AName, ADetail: string);
var
  T: TPPGTrackBar;
  Detail: string;
begin
  Detail := ADetail;
  if ((AName = 'OnChange') or (AName = 'OnTracking')) and (Subject is TPPGTrackBar) then
  begin
    T := TPPGTrackBar(Subject);
    if T.RangeMode then
      Detail := Format('Position = %d, PositionEnd = %d', [T.Position, T.PositionEnd])
    else
      Detail := Format('Position = %d', [T.Position]);
  end;
  inherited EventOccurred(AName, Detail);
end;

procedure TDemoShowTrackBarPage.BuildExamples;
var
  V: TDemoExampleView;
begin
  V := AddExample('Praxis: Einstellungen', 'ExTrackBarSettings',
    'Eine Einstellungsseite "Ansicht": <b>Zoom</b> 50 bis 200 % mit Teilstrichen je 25 '
    + '(<b>Frequency</b>), Pfeiltasten in 5er- und Bild auf/ab in 25er-Schritten '
    + '(<b>LineSize</b>, <b>PageSize</b>) und einem markierten Empfehlungsbereich '
    + '(<b>SelStart</b>/<b>SelEnd</b>). Darunter das Intervall f{ue}r automatisches Sichern '
    + '(0 = aus). Probieren Sie: Zoom ziehen und die Vorschau beobachten, dann mit Tab und '
    + 'Pfeiltasten bzw. Bild auf/ab bedienen.');
  FSettings := TViewSettings.CreateSettings(Own, V.Live, DemoStyles);

  V := AddExample('Praxis: Preisfilter', 'ExTrackBarPriceFilter',
    'Ein Preisfilter {ue}ber einer Artikelliste als <b>Bereichsregler</b> (<b>RangeMode</b>): '
    + '<b>Position</b> ist der Preis von, <b>PositionEnd</b> der Preis bis. W{ae}hrend des '
    + 'Ziehens zeigt <b>OnTracking</b> nur die Grenzen, gefiltert wird erst beim Loslassen '
    + '({ue}ber <b>Dragging</b>). Probieren Sie: einen Griff ziehen, auf die Schiene klicken '
    + '(der n{ae}here Griff springt) und mit Tab zwischen den Griffen wechseln.');
  FFilter := TPriceFilter.CreateFilter(Own, V.Live, DemoStyles);
end;

procedure TDemoShowTrackBarPage.SelfTest(Check: TDemoCheck);
var
  T: TPPGTrackBar;
  Ok: Boolean;
begin
  inherited SelfTest(Check);
  // Buehne: Werte im Protokoll, Tastatur mit LineSize, Begrenzung
  ResetSubject;
  T := TPPGTrackBar(Subject);
  T.Position := 7;
  Check('TPPGTrackBar: OnChange erscheint mit dem neuen Wert im Ereignis-Protokoll',
    (EventList.Items.Count > 0) and (Pos('OnChange', EventList.Items[0]) > 0) and
    (Pos('Position = 7', EventList.Items[0]) > 0));
  T.Position := 99;
  Check('TPPGTrackBar: Position au' + #$00DF + 'erhalb wird still auf Max begrenzt',
    T.Position = T.Max);
  T.LineSize := 2;
  T.Position := 4;
  T.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  Check('TPPGTrackBar: Pfeil rechts erh' + #$00F6 + 'ht um LineSize', T.Position = 6);
  T.RangeMode := True;
  T.PositionEnd := 8;
  T.Position := 9;
  Check('TPPGTrackBar: im RangeMode wandert PositionEnd mit, wenn Position dahinter liegt',
    T.PositionEnd = 9);
  ResetSubject;

  // Praxisbeispiel 1: Einstellungen
  Check('Beispiel Einstellungen: Zoom 50..200 mit Empfehlung 90..125 und Startwert 100',
    (FSettings.Zoom.Min = 50) and (FSettings.Zoom.Max = 200) and
    (FSettings.Zoom.SelStart = 90) and (FSettings.Zoom.SelEnd = 125) and
    (FSettings.Zoom.Position = 100));
  FSettings.Zoom.Position := 150;
  Check('Beispiel Einstellungen: Zoom 150 % zeigt den Wert und vergr' + #$00F6 +
    #$00DF + 'ert die Vorschau', (Pos('150 %', FSettings.ZoomLabel.Caption) > 0) and
    (FSettings.Preview.Font.Size = 14));
  FSettings.Zoom.Perform(WM_KEYDOWN, VK_NEXT, 0);
  Check('Beispiel Einstellungen: Bild ab erh' + #$00F6 + 'ht um PageSize 25',
    FSettings.Zoom.Position = 175);
  FSettings.Zoom.Position := 100;
  FSettings.Interval.Position := 0;
  Ok := Pos('aus', FSettings.IntervalLabel.Caption) > 0;
  FSettings.Interval.Position := 100;
  Check('Beispiel Einstellungen: Intervall 0 = aus, zu gro' + #$00DF + 'e Werte enden bei 60',
    Ok and (FSettings.Interval.Position = 60) and
    (Pos('60 Minuten', FSettings.IntervalLabel.Caption) > 0));
  FSettings.Interval.Position := 10;

  // Praxisbeispiel 2: Preisfilter
  Check('Beispiel Preisfilter: Bereichsregler 0..400 zeigt alle 8 Artikel',
    FFilter.Range.RangeMode and (FFilter.Range.Position = 0) and
    (FFilter.Range.PositionEnd = 400) and (FFilter.List.Items.Count = 8));
  FFilter.Range.Position := 50;
  FFilter.Range.PositionEnd := 200;
  Check('Beispiel Preisfilter: 50 bis 200 EUR filtert auf 3 Artikel',
    (FFilter.List.Items.Count = 3) and (Pos('50 bis 200', FFilter.CaptionLabel.Caption) > 0) and
    (Pos('3 von 8', FFilter.Status.Caption) > 0));
  FFilter.Range.Position := 300;
  Check('Beispiel Preisfilter: Anfang hinter dem Ende schiebt das Ende mit',
    (FFilter.Range.PositionEnd = 300) and (FFilter.List.Items.Count = 0));
  FFilter.Range.PositionEnd := 100;
  Check('Beispiel Preisfilter: Ende vor dem Anfang wird auf den Anfang begrenzt',
    FFilter.Range.PositionEnd = 300);
  FFilter.Range.Position := 0;
  FFilter.Range.PositionEnd := 400;
  Check('Beispiel Preisfilter: zur' + #$00FC + 'ck auf alle Artikel', FFilter.List.Items.Count = 8);
end;

initialization
  RegisterShowcasePage('TPPGTrackBar', TDemoShowTrackBarPage);

end.
