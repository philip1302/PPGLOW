unit ExToolBarActions;

// Praxisbeispiel 2 zu TPPGToolBar (Demo-Seite "Buttons & Aktionen > TPPGToolBar"):
// Notiz-Editor, dessen Leiste an Actions haengt (Item.Action): Speichern ist
// nur nach einer Aenderung frei (Action.Enabled), Zeilenumbruch ist eine
// AutoCheck-Action (wird automatisch zum Umschalt-Button). Dazu eine
// hervorgehobene Hauptaktion (Color, TextColor, FontStyle) und ein
// Umschalter "Nur Symbole" fuer ShowCaptions.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics,
  {$IF CompilerVersion >= 24.0}System.Actions, {$IFEND}Vcl.ActnList,
  PPG.StyleManager, PPG.Labels, PPG.Memo, PPG.ToolBar;

type
  /// Notiz mit Befehlsleiste: Speichern und Zeilenumbruch kommen aus Actions,
  /// "Nur Symbole" schaltet die Beschriftungen der Leiste ab.
  TNoteEditor = class(TComponent)
  private
    FActions: TActionList;
    FSave: TAction;
    FWordWrap: TAction;
    FToolBar: TPPGToolBar;
    FIconsOnly: TPPGToolItem;
    FNote: TPPGMemo;
    FStatus: TPPGLabel;
    FSaveCount: Integer;
    procedure SaveExecute(Sender: TObject);
    procedure WordWrapExecute(Sender: TObject);
    procedure IconsOnlyClick(Sender: TObject);
    procedure NoteChange(Sender: TObject);
  public
    constructor CreateEditor(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property SaveAction: TAction read FSave;
    property WordWrapAction: TAction read FWordWrap;
    property ToolBar: TPPGToolBar read FToolBar;
    property IconsOnly: TPPGToolItem read FIconsOnly;
    property Note: TPPGMemo read FNote;
    property SaveCount: Integer read FSaveCount;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TNoteEditor.CreateEditor(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
var
  Item: TPPGToolItem;
begin
  inherited Create(AOwner);
  // Actions: dieselben Befehle koennten auch im Menue oder per Tastenkuerzel stehen
  FActions := TActionList.Create(Self);
  FSave := TAction.Create(Self);
  FSave.ActionList := FActions;
  FSave.Caption := 'Speichern';
  FSave.Hint := 'Notiz speichern';
  FSave.OnExecute := SaveExecute;
  FSave.Enabled := False;             // frei erst nach einer Aenderung
  FWordWrap := TAction.Create(Self);
  FWordWrap.ActionList := FActions;
  FWordWrap.Caption := 'Umbruch';
  FWordWrap.Hint := 'Lange Zeilen umbrechen';
  FWordWrap.AutoCheck := True;        // Umschalt-Button ohne eigenen Code
  FWordWrap.Checked := True;
  FWordWrap.OnExecute := WordWrapExecute;

  FToolBar := TPPGToolBar.Create(Self);
  FToolBar.Parent := AParent;
  FToolBar.Align := alNone;
  FToolBar.SetBounds(16, 16, 418, 40);
  FToolBar.StyleManager := AStyles;
  FToolBar.ShowHint := True;

  // Hauptaktion hervorheben: eigene Flaeche auch in Ruhe, fette Schrift
  Item := FToolBar.Items.Add;
  Item.Action := FSave;
  Item.IconChar := $E74E;
  Item.Color := $00D77800;
  Item.TextColor := clWhite;
  Item.FontStyle := [fsBold];

  Item := FToolBar.Items.Add;
  Item.Action := FWordWrap;           // Checked/AutoCheck: Style wird tisCheck
  Item.IconChar := $E751;
  FToolBar.Items.AddSeparator;

  // Ohne Beschriftung zeigt der Tooltip den Text
  FIconsOnly := FToolBar.Items.AddCheck('Nur Symbole', $E8FD);
  FIconsOnly.OnClick := IconsOnlyClick;

  FNote := TPPGMemo.Create(Self);
  FNote.Parent := AParent;
  FNote.SetBounds(16, 64, 418, 130);
  FNote.StyleManager := AStyles;
  FNote.Lines.Text := 'Rueckruf Firma Weber: Angebot fuer die Wartung 2027 bis Freitag ' +
    'schicken, Ansprechpartner ist Herr Krause aus dem Einkauf.';
  FNote.OnChange := NoteChange;

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 204, 418, 20);
  FStatus.Caption := 'Gespeichert.';
end;

procedure TNoteEditor.NoteChange(Sender: TObject);
begin
  // Die Action gibt Enabled an alle verbundenen Items (und Menues) weiter
  FSave.Enabled := True;
  FStatus.Caption := 'Geaendert.';
end;

procedure TNoteEditor.SaveExecute(Sender: TObject);
begin
  Inc(FSaveCount);
  FSave.Enabled := False;
  FStatus.Caption := Format('Gespeichert (%d. Mal).', [FSaveCount]);
end;

procedure TNoteEditor.WordWrapExecute(Sender: TObject);
begin
  // AutoCheck hat Checked schon umgeschaltet
  FNote.WordWrap := FWordWrap.Checked;
end;

procedure TNoteEditor.IconsOnlyClick(Sender: TObject);
begin
  FToolBar.ShowCaptions := not FIconsOnly.Down;
end;
// EXAMPLE-END

end.
