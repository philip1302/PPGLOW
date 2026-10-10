unit ExButtonToolbar;

// Praxisbeispiel 2 zu TPPGButton (Demo-Seite "Buttons & Aktionen > TPPGButton"):
// Formatleiste ueber einem Text mit Umschalt-Gruppe (GroupIndex, Down),
// einzelnem Umschalter (AllowAllUp), Segment-Optik (RoundedCorners) und
// Split-Button (Style, DropDownMenu, OnDropDownClick).
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein).

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Graphics, Vcl.Menus,
  PPG.Types, PPG.StyleManager, PPG.Labels, PPG.Memo, PPG.Button, PPG.Menus;

type
  /// Formatleiste ueber einem Text: Ausrichtung (eine aus drei), Fett
  /// (Umschalter) und Exportieren (Split-Button mit Menue).
  TFormatBar = class(TComponent)
  private
    FStyles: TPPGStyleManager;
    FAlignLeft: TPPGButton;
    FAlignCenter: TPPGButton;
    FAlignRight: TPPGButton;
    FBold: TPPGButton;
    FExport: TPPGButton;
    FExportMenu: TPPGPopupMenu;
    FText: TPPGMemo;
    FStatus: TPPGLabel;
    FLastExport: string;
    function NewButton(AParent: TWinControl; X: Integer; const ACaption: string): TPPGButton;
    procedure AlignClick(Sender: TObject);
    procedure BoldClick(Sender: TObject);
    procedure ExportClick(Sender: TObject);
    procedure ExportMenuClick(Sender: TObject);
    procedure ExportDropDown(Sender: TObject);
    procedure DoExport(const AFormat: string);
  public
    constructor CreateBar(AOwner: TComponent; AParent: TWinControl; AStyles: TPPGStyleManager);
    property AlignLeft: TPPGButton read FAlignLeft;
    property AlignCenter: TPPGButton read FAlignCenter;
    property AlignRight: TPPGButton read FAlignRight;
    property Bold: TPPGButton read FBold;
    property ExportButton: TPPGButton read FExport;
    property ExportMenu: TPPGPopupMenu read FExportMenu;
    property Text: TPPGMemo read FText;
    property LastExport: string read FLastExport;
  end;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
function TFormatBar.NewButton(AParent: TWinControl; X: Integer; const ACaption: string): TPPGButton;
begin
  Result := TPPGButton.Create(Self);
  Result.Parent := AParent;
  Result.SetBounds(X, 16, 64, 32);
  Result.Caption := ACaption;
  Result.StyleManager := FStyles;
end;

constructor TFormatBar.CreateBar(AOwner: TComponent; AParent: TWinControl;
  AStyles: TPPGStyleManager);
begin
  inherited Create(AOwner);
  FStyles := AStyles;

  // Ausrichtung: eine aus drei (gleicher GroupIndex). Ohne AllowAllUp bleibt
  // immer genau einer gedrueckt. Aussen rund, innen eckig = Segment-Optik.
  FAlignLeft := NewButton(AParent, 16, 'Links');
  FAlignLeft.GroupIndex := 1;
  FAlignLeft.Down := True;
  FAlignLeft.RoundedCorners := [pcTopLeft, pcBottomLeft];
  FAlignLeft.Tag := Ord(taLeftJustify);
  FAlignLeft.OnClick := AlignClick;

  FAlignCenter := NewButton(AParent, 80, 'Mitte');
  FAlignCenter.GroupIndex := 1;
  FAlignCenter.RoundedCorners := [];
  FAlignCenter.Tag := Ord(taCenter);
  FAlignCenter.OnClick := AlignClick;

  FAlignRight := NewButton(AParent, 144, 'Rechts');
  FAlignRight.GroupIndex := 1;
  FAlignRight.RoundedCorners := [pcTopRight, pcBottomRight];
  FAlignRight.Tag := Ord(taRightJustify);
  FAlignRight.OnClick := AlignClick;

  // Fett: Umschalter, der auch wieder ausrasten darf (eigene Gruppe)
  FBold := NewButton(AParent, 224, 'Fett');
  FBold.GroupIndex := 2;
  FBold.AllowAllUp := True;
  FBold.Font.Style := [fsBold];
  FBold.OnClick := BoldClick;

  // Exportieren: der Hauptteil macht den haeufigsten Fall (PDF),
  // der Pfeil oeffnet die weiteren Formate
  FExportMenu := TPPGPopupMenu.Create(Self);
  FExportMenu.StyleManager := AStyles;
  FExportMenu.Items.Add(NewItem('Als PDF', 0, False, True, ExportMenuClick, 0, 'miPdf'));
  FExportMenu.Items.Add(NewItem('Als Excel-Datei', 0, False, True, ExportMenuClick, 0, 'miExcel'));
  FExportMenu.Items.Add(NewItem('In die Zwischenablage', 0, False, True, ExportMenuClick, 0,
    'miClipboard'));
  FExport := NewButton(AParent, 304, 'Exportieren');
  FExport.Width := 130;
  FExport.Style := pbsSplitButton;
  FExport.DropDownMenu := FExportMenu;
  FExport.OnClick := ExportClick;
  FExport.OnDropDownClick := ExportDropDown;

  FText := TPPGMemo.Create(Self);
  FText.Parent := AParent;
  FText.SetBounds(16, 64, 418, 120);
  FText.StyleManager := AStyles;
  FText.Lines.Text := 'Sehr geehrte Damen und Herren,' + sLineBreak + sLineBreak +
    'anbei unser Angebot zur Wartung 2027.' + sLineBreak + 'Ihr Service-Team';

  FStatus := TPPGLabel.Create(Self);
  FStatus.Parent := AParent;
  FStatus.SetBounds(16, 196, 418, 20);
  FStatus.Caption := 'Noch nichts exportiert.';
end;

procedure TFormatBar.AlignClick(Sender: TObject);
begin
  // Down ist beim Klick schon umgeschaltet; Tag haelt die Ausrichtung
  FText.Alignment := TAlignment(TPPGButton(Sender).Tag);
end;

procedure TFormatBar.BoldClick(Sender: TObject);
begin
  if FBold.Down then
    FText.Font.Style := [fsBold]
  else
    FText.Font.Style := [];
end;

procedure TFormatBar.ExportClick(Sender: TObject);
begin
  DoExport('PDF');
end;

procedure TFormatBar.ExportMenuClick(Sender: TObject);
begin
  case TMenuItem(Sender).MenuIndex of
    0: DoExport('PDF');
    1: DoExport('Excel');
  else
    DoExport('Zwischenablage');
  end;
end;

procedure TFormatBar.ExportDropDown(Sender: TObject);
begin
  // Vor dem Oeffnen anpassen: ohne Text gibt es nichts zu kopieren
  FExportMenu.Items[2].Enabled := Trim(FText.Lines.Text) <> '';
end;

procedure TFormatBar.DoExport(const AFormat: string);
begin
  FLastExport := AFormat;
  FStatus.Caption := 'Exportiert als ' + AFormat + '.';
end;
// EXAMPLE-END

end.
