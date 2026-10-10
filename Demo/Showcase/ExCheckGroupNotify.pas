unit ExCheckGroupNotify;

// Praxisbeispiel 1 zu TPPGCheckGroup (Demo-Seite "Auswahl > TPPGCheckGroup"):
// Einstellungsseite "Benachrichtigungen" eines Kundenstamms. Mehrfachauswahl
// mit Value (Kommaliste fuer die Datenbank), gesperrtem Eintrag mit Hinweis
// (ItemEnabled, ItemsEx[i].Hint) und Pflichtauswahl (ValidationState).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls,
  PPG.StyleManager, PPG.Controls.Field, PPG.Labels, PPG.Edit, PPG.RadioGroup;

type
  /// Benachrichtigungswege eines Kunden: mindestens einer muss gewaehlt
  /// sein, SMS geht erst mit einer Mobilnummer.
  TNotifySettings = class(TComponent)
  private
    FChannels: TPPGCheckGroup;
    FPhoneLabel: TPPGLabel;
    FPhone: TPPGEdit;
    FStatus: TPPGLabel;
    FSavedValue: string;
    procedure ChannelsChange(Sender: TObject);
    procedure PhoneChange(Sender: TObject);
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager; const AStoredValue: string);
    property Channels: TPPGCheckGroup read FChannels;
    property Phone: TPPGEdit read FPhone;
    /// Zuletzt gespeicherter Wert (so stuende er im Datenbankfeld).
    property SavedValue: string read FSavedValue;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  SmsIndex = 1;

constructor TNotifySettings.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager; const AStoredValue: string);

  procedure AddChannel(const ACaption, AValue: string);
  var
    Item: TPPGChoiceItem;
  begin
    Item := FChannels.ItemsEx.Add;
    Item.Caption := ACaption;
    Item.Value := AValue;   // Kuerzel fuer die Datenbank statt der Beschriftung
  end;

begin
  inherited Create(AOwner);

  FChannels := TPPGCheckGroup.Create(Self);
  FChannels.Parent := AParent;
  FChannels.SetBounds(16, 16, 418, 112);
  FChannels.Caption := 'Benachrichtigen per';
  FChannels.Columns := 2;
  FChannels.StyleManager := AStyles;
  AddChannel('&E-Mail', 'mail');
  AddChannel('&SMS', 'sms');
  AddChannel('&Push im Kundenportal', 'push');
  AddChannel('&Brief', 'post');
  // SMS erst mit Mobilnummer: Eintrag sperren und den Grund als Hinweis zeigen
  FChannels.ItemEnabled[SmsIndex] := False;
  FChannels.ItemsEx[SmsIndex].Hint := 'Erst eine Mobilnummer eintragen';
  FChannels.ShowHint := True;
  // Gespeicherten Wert aus der Datenbank laden (loest kein OnChange aus)
  FChannels.Value := AStoredValue;
  FChannels.OnChange := ChannelsChange;

  FPhoneLabel := TPPGLabel.Create(Self);
  FPhoneLabel.Parent := AParent;
  FPhoneLabel.SetBounds(16, 144, 200, 20);
  FPhoneLabel.Caption := '&Mobilnummer:';

  FPhone := TPPGEdit.Create(Self);
  FPhone.Parent := AParent;
  FPhone.SetBounds(16, 166, 200, 32);
  FPhone.TextHint := 'z. B. 0171 1234567';
  FPhone.StyleManager := AStyles;
  FPhone.OnChange := PhoneChange;
  FPhoneLabel.FocusControl := FPhone;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 214, 418, 20);
  FSavedValue := FChannels.Value;
  FStatus.Caption := 'Gespeichert: ' + FSavedValue;
end;

procedure TNotifySettings.ChannelsChange(Sender: TObject);
begin
  // Pflichtauswahl: ohne Haken rot markieren und nicht speichern
  if FChannels.Value = '' then
  begin
    FChannels.ValidationHint := 'Bitte mindestens einen Weg ankreuzen.';
    FChannels.ValidationState := pvsError;
    FStatus.Caption := 'Nicht gespeichert: kein Weg gewaehlt.';
    Exit;
  end;
  FChannels.ValidationState := pvsNone;
  FSavedValue := FChannels.Value;   // z. B. 'mail,push'
  FStatus.Caption := 'Gespeichert: ' + FSavedValue;
end;

procedure TNotifySettings.PhoneChange(Sender: TObject);
var
  HasPhone: Boolean;
begin
  HasPhone := Trim(FPhone.Text) <> '';
  FChannels.ItemEnabled[SmsIndex] := HasPhone;
  if HasPhone then
    FChannels.ItemsEx[SmsIndex].Hint := 'SMS an ' + Trim(FPhone.Text)
  else
  begin
    FChannels.ItemsEx[SmsIndex].Hint := 'Erst eine Mobilnummer eintragen';
    // Ohne Nummer darf SMS nicht angehakt bleiben
    if FChannels.Checked[SmsIndex] then
    begin
      FChannels.Checked[SmsIndex] := False;
      ChannelsChange(FChannels);
    end;
  end;
end;
// EXAMPLE-END

end.
