unit ExRadioGroupSubscription;

// Praxisbeispiel 2 zu TPPGRadioGroup (Demo-Seite "Auswahl > TPPGRadioGroup"):
// Abo-Einstellungen mit einem Segment-Umschalter ohne Rahmen (csSegmented,
// ShowFrame = False, OnChange) und einer klassischen Optionsgruppe (Items,
// Columns, OnClick), die ein Eingabefeld freischaltet. LoadSettings zeigt,
// dass ItemIndex im Code kein Ereignis ausloest.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Labels, PPG.Edit, PPG.RadioGroup;

type
  /// Abo-Einstellungen: Abrechnung pro Monat/Quartal/Jahr (Segmente) und
  /// Zahlungsart (Optionsgruppe); die IBAN ist nur bei Lastschrift frei.
  TSubscriptionSettings = class(TComponent)
  private
    FIntervalLabel: TPPGLabel;
    FInterval: TPPGRadioGroup;
    FPayment: TPPGRadioGroup;
    FIban: TPPGEdit;
    FPrice: TPPGLabel;
    procedure IntervalChange(Sender: TObject);
    procedure PaymentClick(Sender: TObject);
    procedure UpdatePrice;
    procedure UpdateIban;
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    /// Gespeicherte Einstellungen zeigen (z. B. beim Oeffnen des Dialogs).
    procedure LoadSettings(AInterval, APayment: Integer);
    property Interval: TPPGRadioGroup read FInterval;
    property Payment: TPPGRadioGroup read FPayment;
    property Iban: TPPGEdit read FIban;
    property Price: TPPGLabel read FPrice;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TSubscriptionSettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);

  FIntervalLabel := TPPGLabel.Create(Self);
  FIntervalLabel.Parent := AParent;
  FIntervalLabel.SetBounds(16, 16, 418, 20);
  FIntervalLabel.Caption := '&Abrechnung pro';

  // Segment-Umschalter: eine aus drei, ohne Rahmen in einer Zeile
  FInterval := TPPGRadioGroup.Create(Self);
  FInterval.Parent := AParent;
  FInterval.SetBounds(16, 40, 300, 36);
  FInterval.ChoiceStyle := csSegmented;
  FInterval.ShowFrame := False;
  FInterval.Items.CommaText := 'Monat,Quartal,Jahr';
  FInterval.StyleManager := AStyles;
  FInterval.OnChange := IntervalChange;   // nur bei Auswahl durch den Anwender
  FIntervalLabel.FocusControl := FInterval;

  // Klassische Optionsgruppe wie TRadioGroup, drei Spalten nebeneinander
  FPayment := TPPGRadioGroup.Create(Self);
  FPayment.Parent := AParent;
  FPayment.SetBounds(16, 92, 418, 64);
  FPayment.Caption := '&Zahlungsart';
  FPayment.Columns := 3;
  FPayment.Items.Add('Rechnung');
  FPayment.Items.Add('Lastschrift');
  FPayment.Items.Add('Kreditkarte');
  FPayment.StyleManager := AStyles;
  FPayment.OnClick := PaymentClick;        // wie bei TRadioGroup

  FIban := TPPGEdit.Create(Self);
  FIban.Parent := AParent;
  FIban.SetBounds(16, 168, 418, 32);
  FIban.TextHint := 'IBAN (nur bei Lastschrift)';
  FIban.StyleManager := AStyles;

  FPrice := TPPGLabel.Create(Self);
  FPrice.Parent := AParent;
  FPrice.SetBounds(16, 212, 418, 20);

  LoadSettings(0, 0);
end;

procedure TSubscriptionSettings.LoadSettings(AInterval, APayment: Integer);
begin
  // ItemIndex im Code loest weder OnClick noch OnChange aus.
  // Deshalb danach selbst aktualisieren.
  FInterval.ItemIndex := AInterval;
  FPayment.ItemIndex := APayment;
  UpdatePrice;
  UpdateIban;
end;

procedure TSubscriptionSettings.IntervalChange(Sender: TObject);
begin
  UpdatePrice;
end;

procedure TSubscriptionSettings.PaymentClick(Sender: TObject);
begin
  UpdateIban;
  if FIban.Enabled and FIban.CanFocus then
    FIban.SetFocus;   // gleich weiter zur IBAN
end;

procedure TSubscriptionSettings.UpdatePrice;
begin
  case FInterval.ItemIndex of
    0: FPrice.Caption := 'Preis: 29,00 EUR pro Monat';
    1: FPrice.Caption := 'Preis: 84,00 EUR pro Quartal (3 % Rabatt)';
    2: FPrice.Caption := 'Preis: 290,00 EUR pro Jahr (2 Monate gratis)';
  else
    FPrice.Caption := '';
  end;
end;

procedure TSubscriptionSettings.UpdateIban;
begin
  // Was gerade nicht gebraucht wird, sperren statt ausblenden
  FIban.Enabled := FPayment.ItemIndex = 1;   // 1 = Lastschrift
end;
// EXAMPLE-END

end.
