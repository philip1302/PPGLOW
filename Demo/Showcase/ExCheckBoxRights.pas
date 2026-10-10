unit ExCheckBoxRights;

// Praxisbeispiel 2 zu TPPGCheckBox (Demo-Seite "Auswahl > TPPGCheckBox"):
// Rechte einer Benutzerrolle mit "Alle Module" (State cbGrayed fuer
// "teilweise"), OnClick fuer die Bedienung und OnChange fuer jede Aenderung.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.StyleManager, PPG.Labels, PPG.CheckBox;

const
  ModuleCount = 4;
  ModuleNames: array[0..ModuleCount - 1] of string = ('Kunden', 'Rechnungen',
    'Berichte', 'Einstellungen');

type
  /// Freigaben einer Rolle: ein Kaestchen je Modul und darueber "Alle
  /// Module", das an, aus oder teilweise (cbGrayed) zeigt.
  TRoleRights = class(TComponent)
  private
    FAll: TPPGCheckBox;
    FModules: array[0..ModuleCount - 1] of TPPGCheckBox;
    FSummary: TPPGLabel;
    function GetModule(Index: Integer): TPPGCheckBox;
    function CheckedCount: Integer;
    procedure AllClick(Sender: TObject);
    procedure ModuleChange(Sender: TObject);
  public
    constructor CreateRights(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property All: TPPGCheckBox read FAll;
    property Modules[Index: Integer]: TPPGCheckBox read GetModule;
    property Summary: TPPGLabel read FSummary;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TRoleRights.CreateRights(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  I: Integer;
begin
  inherited Create(AOwner);

  // "Alle Module": AllowGrayed bleibt False. Den gemischten Zustand setzt
  // nur der Code; ein Klick schaltet zwischen alle an und alle aus.
  FAll := TPPGCheckBox.Create(Self);
  FAll.Parent := AParent;
  FAll.SetBounds(16, 16, 300, 24);
  FAll.Caption := 'Alle Module';
  FAll.Font.Style := [fsBold];
  FAll.StyleManager := AStyles;
  FAll.OnClick := AllClick;          // nur Bedienung durch den Anwender

  for I := 0 to ModuleCount - 1 do
  begin
    FModules[I] := TPPGCheckBox.Create(Self);
    FModules[I].Parent := AParent;
    FModules[I].SetBounds(40, 48 + I * 30, 276, 24);
    FModules[I].Caption := ModuleNames[I];
    FModules[I].StyleManager := AStyles;
    FModules[I].OnChange := ModuleChange;   // jede Aenderung, auch aus dem Code
  end;
  FModules[0].Checked := True;   // Vorgabe der Rolle "Vertrieb"

  FSummary := TPPGLabel.Create(Self);
  FSummary.Parent := AParent;
  FSummary.SetBounds(16, 176, 400, 20);
  ModuleChange(nil);
end;

function TRoleRights.GetModule(Index: Integer): TPPGCheckBox;
begin
  Result := FModules[Index];
end;

function TRoleRights.CheckedCount: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ModuleCount - 1 do
    if FModules[I].Checked then
      Inc(Result);
end;

procedure TRoleRights.AllClick(Sender: TObject);
var
  I: Integer;
  TurnOn: Boolean;
begin
  // Der Klick hat FAll schon umgeschaltet (aus teilweise wird an). Den Wert
  // vorher merken: OnChange der Module stellt FAll unterwegs neu ein.
  // Checked im Code loest bei den Modulen nur OnChange aus, kein OnClick.
  TurnOn := FAll.Checked;
  for I := 0 to ModuleCount - 1 do
    FModules[I].Checked := TurnOn;
end;

procedure TRoleRights.ModuleChange(Sender: TObject);
var
  N: Integer;
begin
  N := CheckedCount;
  if N = 0 then
    FAll.State := cbUnchecked
  else if N = ModuleCount then
    FAll.State := cbChecked
  else
    FAll.State := cbGrayed;    // teilweise freigegeben
  FSummary.Caption := Format('%d von %d Modulen freigegeben', [N, ModuleCount]);
end;
// EXAMPLE-END

end.
