unit ExColorPickerCategories;

// Praxisbeispiel 1 zu TPPGColorPicker (Demo-Seite "Eingabe > TPPGColorPicker"):
// Farben fuer Termin-Kategorien einstellen. Drei Picker mit gemeinsamem
// OnChange (Tag = Kategorie), "Keine" erlaubt (cbIncludeNone) und eine
// gemeinsame Liste "zuletzt benutzt" (RecentColors).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.ExtCtrls,
  PPG.StyleManager, PPG.Labels, PPG.ColorPicker;

const
  CategoryCount = 3;
  CategoryNames: array[0..CategoryCount - 1] of string = ('Kunde', 'Intern', 'Urlaub');

type
  /// Einstellungen "Termin-Kategorien": je Kategorie eine Farbe, rechts
  /// eine Vorschau, wie die Kategorie im Kalender erscheint.
  TCategoryColors = class(TComponent)
  private
    FPickers: array[0..CategoryCount - 1] of TPPGColorPicker;
    FChips: array[0..CategoryCount - 1] of TShape;
    FStatus: TPPGLabel;
    procedure PickerChange(Sender: TObject);
    procedure ShowChip(Index: Integer);
    function GetPicker(Index: Integer): TPPGColorPicker;
    function GetChip(Index: Integer): TShape;
  public
    constructor CreateSettings(AOwner: TComponent; AParent: TWinControl;
      AStyles: TPPGStyleManager);
    property Pickers[Index: Integer]: TPPGColorPicker read GetPicker;
    property Chips[Index: Integer]: TShape read GetChip;
    property Status: TPPGLabel read FStatus;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
const
  StartColors: array[0..CategoryCount - 1] of TColor = (clBlue, clGreen, clNone);

constructor TCategoryColors.CreateSettings(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  I, Y: Integer;
  Lbl: TPPGLabel;
begin
  inherited Create(AOwner);
  for I := 0 to CategoryCount - 1 do
  begin
    Y := 16 + I * 44;
    Lbl := TPPGLabel.Create(Self);
    Lbl.Parent := AParent;
    Lbl.SetBounds(16, Y + 6, 90, 20);
    Lbl.Caption := CategoryNames[I] + ':';

    FPickers[I] := TPPGColorPicker.Create(Self);
    FPickers[I].Parent := AParent;
    FPickers[I].SetBounds(112, Y, 200, 32);
    FPickers[I].StyleManager := AStyles;
    // "Keine" erlaubt: Kategorie ohne Farbe
    FPickers[I].Style := [cbStandardColors, cbExtendedColors, cbIncludeNone,
      cbCustomColor, cbPrettyNames];
    FPickers[I].MaxRecent := 6;
    // Aus Code gesetzt: kein OnChange
    FPickers[I].Selected := StartColors[I];
    // Ein Handler fuer alle Picker; Tag sagt, welche Kategorie
    FPickers[I].Tag := I;
    FPickers[I].OnChange := PickerChange;

    // Vorschau wie im Kalender
    FChips[I] := TShape.Create(Self);
    FChips[I].Parent := AParent;
    FChips[I].SetBounds(326, Y + 6, 104, 20);
    FChips[I].Shape := stRoundRect;
    ShowChip(I);
  end;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 16 + CategoryCount * 44 + 4, 414, 20);
  FStatus.Caption := 'Klicken Sie auf ein Farbfeld.';
end;

procedure TCategoryColors.ShowChip(Index: Integer);
var
  C: TColor;
begin
  C := FPickers[Index].Selected;
  if C = clNone then
  begin
    // Ohne Farbe: nur ein gestrichelter Rahmen
    FChips[Index].Brush.Style := bsClear;
    FChips[Index].Pen.Style := psDot;
  end
  else
  begin
    FChips[Index].Brush.Style := bsSolid;
    FChips[Index].Brush.Color := C;
    FChips[Index].Pen.Style := psSolid;
  end;
end;

procedure TCategoryColors.PickerChange(Sender: TObject);
var
  P: TPPGColorPicker;
  I: Integer;
begin
  // Nur bei Auswahl durch den Anwender (nicht bei Selected aus Code)
  P := TPPGColorPicker(Sender);
  ShowChip(P.Tag);
  FStatus.Caption := CategoryNames[P.Tag] + ': ' + P.ColorName(P.Selected);
  // "Zuletzt benutzt" fuer alle Kategorien gemeinsam
  for I := 0 to CategoryCount - 1 do
    if FPickers[I] <> P then
      FPickers[I].RecentColors.Assign(P.RecentColors);
end;

function TCategoryColors.GetPicker(Index: Integer): TPPGColorPicker;
begin
  Result := FPickers[Index];
end;

function TCategoryColors.GetChip(Index: Integer): TShape;
begin
  Result := FChips[Index];
end;
// EXAMPLE-END

end.
