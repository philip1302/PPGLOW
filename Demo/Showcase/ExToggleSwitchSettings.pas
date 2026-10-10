unit ExToggleSwitchSettings;

// Praxisbeispiel 1 zu TPPGToggleSwitch (Demo-Seite "Auswahl > TPPGToggleSwitch"):
// Einstellungsseite "Benachrichtigungen" wie in Windows: Text links, Schalter
// rechts (Alignment), ein Hauptschalter gibt die abhaengigen Schalter frei
// (Checked, Enabled, OnChange).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  PPG.StyleManager, PPG.Labels, PPG.ToggleSwitch;

type
  /// Einstellungsseite "Benachrichtigungen": Der Hauptschalter gibt die
  /// einzelnen Benachrichtigungen frei; eine Zeile fasst den Stand zusammen.
  TNotifySettings = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FNotify: TPPGToggleSwitch;
    FNewOrders: TPPGToggleSwitch;
    FDailySummary: TPPGToggleSwitch;
    FSound: TPPGToggleSwitch;
    FStatus: TPPGLabel;
    function NewSwitch(AParent: TWinControl; X, Y: Integer; const ACaption,
      AHint: string): TPPGToggleSwitch;
    procedure NotifyChange(Sender: TObject);
    procedure OptionChange(Sender: TObject);
    procedure UpdateStatus;
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    /// Anzahl der wirksamen Benachrichtigungen (0, wenn der Hauptschalter aus ist).
    function ActiveCount: Integer;
    property Notify: TPPGToggleSwitch read FNotify;
    property NewOrders: TPPGToggleSwitch read FNewOrders;
    property DailySummary: TPPGToggleSwitch read FDailySummary;
    property Sound: TPPGToggleSwitch read FSound;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TNotifySettings.NewSwitch(AParent: TWinControl; X, Y: Integer;
  const ACaption, AHint: string): TPPGToggleSwitch;
begin
  Result := TPPGToggleSwitch.Create(Self);
  Result.Parent := AParent;
  // Text links, Schalter am rechten Rand: alle Schalter fluchten untereinander
  Result.SetBounds(X, Y, 416 - X, 28);
  Result.Alignment := taLeftJustify;
  Result.Caption := ACaption;
  Result.Hint := AHint;
  Result.ShowHint := True;
  Result.StyleManager := FStyles;
end;

constructor TNotifySettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  // Hauptschalter: fett, damit er als Ueberschrift der Gruppe wirkt
  FNotify := NewSwitch(AParent, 16, 16, '&Benachrichtigungen',
    'Schaltet alle Benachrichtigungen dieser Anwendung ein oder aus');
  FNotify.Font.Style := [fsBold];

  // Abhaengige Einstellungen, eingerueckt unter dem Hauptschalter
  FNewOrders := NewSwitch(AParent, 40, 52, 'Bei neuen &Auftr' + #$00E4 + 'gen',
    'Meldung, sobald ein Kunde einen Auftrag anlegt');
  FDailySummary := NewSwitch(AParent, 40, 84, '&T' + #$00E4 + 'gliche Zusammenfassung',
    'Eine E-Mail um 8 Uhr mit allen offenen Vorg' + #$00E4 + 'ngen');
  FSound := NewSwitch(AParent, 40, 116, 'T&on abspielen',
    'Kurzer Hinweiston bei jeder Meldung');

  // Werte wie aus der Konfiguration geladen; OnChange erst danach zuweisen
  FNotify.Checked := True;
  FNewOrders.Checked := True;
  FSound.Checked := True;

  FNotify.OnChange := NotifyChange;
  FNewOrders.OnChange := OptionChange;
  FDailySummary.OnChange := OptionChange;
  FSound.OnChange := OptionChange;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 160, 400, 20);
  UpdateStatus;
end;

procedure TNotifySettings.NotifyChange(Sender: TObject);
begin
  // Abhaengige Schalter nur sperren: ihr Wert bleibt erhalten und gilt
  // wieder, sobald der Hauptschalter an ist
  FNewOrders.Enabled := FNotify.Checked;
  FDailySummary.Enabled := FNotify.Checked;
  FSound.Enabled := FNotify.Checked;
  UpdateStatus;
end;

procedure TNotifySettings.OptionChange(Sender: TObject);
begin
  // Hier wuerde die Einstellung gespeichert, z. B. in der Konfiguration
  UpdateStatus;
end;

function TNotifySettings.ActiveCount: Integer;
begin
  Result := 0;
  if not FNotify.Checked then
    Exit;
  if FNewOrders.Checked then
    Inc(Result);
  if FDailySummary.Checked then
    Inc(Result);
  if FSound.Checked then
    Inc(Result);
end;

procedure TNotifySettings.UpdateStatus;
begin
  if FNotify.Checked then
    FStatus.Caption := Format('%d von 3 Benachrichtigungen aktiv.', [ActiveCount])
  else
    FStatus.Caption := 'Alle Benachrichtigungen sind ausgeschaltet.';
end;
// EXAMPLE-END

end.
