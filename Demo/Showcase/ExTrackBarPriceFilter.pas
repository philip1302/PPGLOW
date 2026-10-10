unit ExTrackBarPriceFilter;

// Praxisbeispiel 2 zu TPPGTrackBar (Demo-Seite "Auswahl > TPPGTrackBar"):
// Preisfilter einer Artikelliste als Bereichsregler (RangeMode, Position,
// PositionEnd). Waehrend des Ziehens zeigt OnTracking nur die Grenzen an;
// die Liste wird erst gefiltert, wenn der Griff losgelassen ist (Dragging).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.ListBox, PPG.TrackBar;

type
  /// Artikelliste mit Preisfilter "von - bis" (ein Regler, zwei Griffe).
  TPriceFilter = class(TComponent)
  private
    FCaption: TPPGLabel;
    FRange: TPPGTrackBar;
    FList: TPPGListBox;
    FStatus: TPPGLabel;
    procedure ShowRange;
    procedure ApplyFilter;
    procedure RangeTracking(Sender: TObject);
    procedure RangeChange(Sender: TObject);
    procedure RangeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  public
    constructor CreateFilter(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Range: TPPGTrackBar read FRange;
    property List: TPPGListBox read FList;
    property CaptionLabel: TPPGLabel read FCaption;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  ArticleNames: array[0..7] of string = ('USB-Stick 64 GB', 'Funkmaus',
    'Tastatur', 'Headset', 'Webcam Full HD', 'Monitor 24 Zoll',
    'Dockingstation', 'Monitor 27 Zoll');
  ArticlePrices: array[0..7] of Integer = (12, 25, 49, 79, 95, 189, 229, 349);

constructor TPriceFilter.CreateFilter(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FCaption := TPPGLabel.Create(Self);
  FCaption.Parent := AParent;
  FCaption.SetBounds(16, 16, 418, 20);

  // Zwei Griffe: Position = Preis von, PositionEnd = Preis bis.
  // Max vor PositionEnd setzen, sonst wird das Ende auf 10 begrenzt.
  FRange := TPPGTrackBar.Create(Self);
  FRange.Parent := AParent;
  FRange.SetBounds(16, 40, 418, 40);
  FRange.StyleManager := AStyles;
  FRange.Max := 400;
  FRange.Frequency := 50;
  FRange.LineSize := 10;
  FRange.PageSize := 50;
  FRange.RangeMode := True;
  FRange.Position := 0;
  FRange.PositionEnd := 400;
  FRange.OnTracking := RangeTracking;
  FRange.OnChange := RangeChange;
  FRange.OnMouseUp := RangeMouseUp;

  FList := TPPGListBox.Create(Self);
  FList.Parent := AParent;
  FList.SetBounds(16, 92, 418, 136);
  FList.StyleManager := AStyles;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 236, 418, 20);

  ShowRange;
  ApplyFilter;
end;

procedure TPriceFilter.ShowRange;
begin
  FCaption.Caption := Format('Preis von %d bis %d EUR',
    [FRange.Position, FRange.PositionEnd]);
end;

procedure TPriceFilter.ApplyFilter;
var
  I: Integer;
begin
  // In echten Programmen eine Datenbankabfrage: deshalb nur einmal je Aenderung
  FList.Items.BeginUpdate;
  try
    FList.Items.Clear;
    for I := 0 to High(ArticleNames) do
      if (ArticlePrices[I] >= FRange.Position) and (ArticlePrices[I] <= FRange.PositionEnd) then
        FList.Items.Add(Format('%s  (%d EUR)', [ArticleNames[I], ArticlePrices[I]]));
  finally
    FList.Items.EndUpdate;
  end;
  FStatus.Caption := Format('%d von %d Artikeln', [FList.Items.Count, Length(ArticleNames)]);
end;

procedure TPriceFilter.RangeTracking(Sender: TObject);
begin
  // Waehrend des Ziehens: nur die Grenzen anzeigen
  ShowRange;
end;

procedure TPriceFilter.RangeChange(Sender: TObject);
begin
  ShowRange;
  // Tastatur, Mausrad und Code filtern sofort, das Ziehen erst beim Loslassen
  if not FRange.Dragging then
    ApplyFilter;
end;

procedure TPriceFilter.RangeMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    ApplyFilter;
end;
// EXAMPLE-END

end.
