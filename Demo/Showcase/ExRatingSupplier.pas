unit ExRatingSupplier;

// Praxisbeispiel 2 zu TPPGRating (Demo-Seite "Auswahl > TPPGRating"):
// Lieferantenbewertung mit drei Kriterien (ein gemeinsames OnChange, Tag =
// Kriterium) und einer Gesamtnote als reine Anzeige (ReadOnly, AllowHalf,
// StarColor). Nicht bewertete Kriterien (0) zaehlen nicht mit.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  PPG.StyleManager, PPG.Labels, PPG.Rating;

type
  /// Bewertungsbogen fuer einen Lieferanten: drei Kriterien, daraus die
  /// Gesamtnote in halben Sternen.
  TSupplierScore = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FCriteria: array[0..2] of TPPGRating;
    FTotal: TPPGRating;
    FTotalText: TPPGLabel;
    FStatus: TPPGLabel;
    function NewCriterion(AParent: TWinControl; AIndex: Integer; const ACaption: string;
      AValue: Integer): TPPGRating;
    procedure CriterionChange(Sender: TObject);
    function GetCriterion(Index: Integer): TPPGRating;
  public
    constructor CreateScore(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    /// Durchschnitt der bewerteten Kriterien (0 = keines bewertet).
    function Average: Double;
    procedure UpdateTotal;
    property Criterion[Index: Integer]: TPPGRating read GetCriterion;
    property Total: TPPGRating read FTotal;
    property TotalText: TPPGLabel read FTotalText;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TSupplierScore.NewCriterion(AParent: TWinControl; AIndex: Integer;
  const ACaption: string; AValue: Integer): TPPGRating;
var
  Lbl: TPPGLabel;
begin
  Lbl := TPPGLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.SetBounds(16, 54 + AIndex * 34, 140, 20);
  Lbl.Caption := ACaption;

  Result := TPPGRating.Create(Self);
  Result.Parent := AParent;
  Result.Left := 160;
  Result.Top := 50 + AIndex * 34;
  Result.Tag := AIndex;              // Kriterium fuer das gemeinsame OnChange
  Result.Value := AValue;            // gespeicherter Wert, ohne OnChange
  Result.StyleManager := FStyles;
  Result.OnChange := CriterionChange;
end;

constructor TSupplierScore.CreateScore(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Head, Sum: TPPGLabel;
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  Head := TPPGLabel.Create(Self);
  Head.Parent := AParent;
  Head.SetBounds(16, 16, 418, 20);
  Head.Caption := 'Lieferant: Becker Office GmbH, Bewertung 2026';
  Head.Font.Style := [fsBold];

  FCriteria[0] := NewCriterion(AParent, 0, 'Lieferzeit', 4);
  FCriteria[1] := NewCriterion(AParent, 1, 'Preis-Leistung', 5);
  FCriteria[2] := NewCriterion(AParent, 2, 'Kommunikation', 4);

  Sum := TPPGLabel.Create(Self);
  Sum.Parent := AParent;
  Sum.SetBounds(16, 168, 140, 20);
  Sum.Caption := 'Gesamt';
  Sum.Font.Style := [fsBold];

  // Gesamtnote: nur Anzeige, halbe Sterne, klassisches Gold
  FTotal := TPPGRating.Create(Self);
  FTotal.Parent := AParent;
  FTotal.Left := 160;
  FTotal.Top := 162;
  FTotal.ReadOnly := True;
  FTotal.AllowHalf := True;
  FTotal.StarSize := 24;
  FTotal.StarColor := $0000C0FF;
  FTotal.StyleManager := AStyles;

  FTotalText := TPPGLabel.Create(Self);
  FTotalText.Parent := AParent;
  FTotalText.SetBounds(316, 168, 118, 20);

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 204, 418, 20);
  FStatus.Caption := 'Stern anklicken oder Pfeiltasten und Ziffern benutzen.';

  // Value im Code loest kein OnChange aus: Gesamtnote einmal selbst rechnen
  UpdateTotal;
end;

function TSupplierScore.GetCriterion(Index: Integer): TPPGRating;
begin
  Result := FCriteria[Index];
end;

function TSupplierScore.Average: Double;
var
  I, Count: Integer;
  Sum: Double;
begin
  Sum := 0;
  Count := 0;
  for I := 0 to High(FCriteria) do
    if FCriteria[I].Value > 0 then   // 0 = nicht bewertet, zaehlt nicht mit
    begin
      Sum := Sum + FCriteria[I].Value;
      Inc(Count);
    end;
  if Count = 0 then
    Result := 0
  else
    Result := Sum / Count;
end;

procedure TSupplierScore.UpdateTotal;
var
  Avg: Double;
begin
  Avg := Average;
  FTotal.Value := Avg;   // AllowHalf rundet auf halbe Sterne
  if Avg = 0 then
    FTotalText.Caption := 'nicht bewertet'
  else
    FTotalText.Caption := FormatFloat('0.0', Avg) + ' von 5';
end;

procedure TSupplierScore.CriterionChange(Sender: TObject);
const
  Names: array[0..2] of string = ('Lieferzeit', 'Preis-Leistung', 'Kommunikation');
var
  R: TPPGRating;
begin
  // Ein Handler fuer alle Kriterien; welches es war, sagt Tag
  R := TPPGRating(Sender);
  if R.Value = 0 then
    FStatus.Caption := Names[R.Tag] + ': Bewertung entfernt.'
  else
    FStatus.Caption := Format('%s: %d von %d Sternen.', [Names[R.Tag], Round(R.Value), R.Max]);
  UpdateTotal;
end;
// EXAMPLE-END

end.
