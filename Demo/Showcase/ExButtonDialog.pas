unit ExButtonDialog;

// Praxisbeispiel 1 zu TPPGButton (Demo-Seite "Buttons & Aktionen > TPPGButton"):
// Dialog "Speichern unter" mit Default-, Cancel- und ModalResult-Buttons.
// Die Demo zeigt die Abschnitte zwischen den EXAMPLE-Marken als Code an
// (Build\make-showcase.ps1 bindet die Unit als Ressource ein). Deshalb ist
// dieser Code bewusst schlicht und ohne Demo-Bausteine geschrieben.

interface

// EXAMPLE-BEGIN
uses
  System.SysUtils, System.Classes, System.UITypes, Vcl.Controls, Vcl.Forms, Vcl.ImgList,
  PPG.StyleManager, PPG.Labels, PPG.Edit, PPG.Button;

type
  /// Dialog "Speichern unter": Speichern geht erst mit einem Dateinamen,
  /// Enter speichert, Esc bricht ab.
  TSaveAsDialog = class(TForm)
  private
    FPrompt: TPPGLabel;
    FFileName: TPPGEdit;
    FSave: TPPGButton;
    FCancel: TPPGButton;
    procedure FileNameChange(Sender: TObject);
  public
    constructor CreateDialog(AOwner: TComponent; AImages: TCustomImageList;
      AStyles: TPPGStyleManager);
    property FileNameEdit: TPPGEdit read FFileName;
    property SaveButton: TPPGButton read FSave;
    property CancelButton: TPPGButton read FCancel;
  end;

/// Fragt nach einem Dateinamen; '' = abgebrochen.
function AskFileName(AOwner: TComponent; AImages: TCustomImageList;
  AStyles: TPPGStyleManager; const ADefault: string): string;
// EXAMPLE-END

implementation

// EXAMPLE-BEGIN
constructor TSaveAsDialog.CreateDialog(AOwner: TComponent; AImages: TCustomImageList;
  AStyles: TPPGStyleManager);
begin
  inherited CreateNew(AOwner);
  Caption := 'Speichern unter';
  BorderStyle := bsDialog;
  Position := poOwnerFormCenter;
  Font.Name := 'Segoe UI';
  Font.Size := 10;
  ClientWidth := 380;
  ClientHeight := 160;

  FPrompt := TPPGLabel.Create(Self);
  FPrompt.Parent := Self;
  FPrompt.SetBounds(16, 16, 348, 20);
  FPrompt.Caption := '&Dateiname:';

  FFileName := TPPGEdit.Create(Self);
  FFileName.Parent := Self;
  FFileName.SetBounds(16, 40, 348, 32);
  FFileName.TextHint := 'z. B. Angebot 2026';
  FFileName.StyleManager := AStyles;
  FFileName.OnChange := FileNameChange;
  FPrompt.FocusControl := FFileName;

  // Hauptbefehl: Enter loest ihn aus, der Klick schliesst mit mrOk
  FSave := TPPGButton.Create(Self);
  FSave.Parent := Self;
  FSave.SetBounds(148, 112, 104, 32);
  FSave.Caption := 'Speichern';
  FSave.Default := True;
  FSave.ModalResult := mrOk;
  FSave.Images := AImages;
  FSave.ImageIndex := 0;
  FSave.StyleManager := AStyles;
  FSave.Enabled := False;   // erst mit einem Dateinamen

  // Abbrechen: Esc loest ihn aus, der Klick schliesst mit mrCancel
  FCancel := TPPGButton.Create(Self);
  FCancel.Parent := Self;
  FCancel.SetBounds(260, 112, 104, 32);
  FCancel.Caption := 'Abbrechen';
  FCancel.Cancel := True;
  FCancel.ModalResult := mrCancel;
  FCancel.StyleManager := AStyles;

  ActiveControl := FFileName;
end;

procedure TSaveAsDialog.FileNameChange(Sender: TObject);
begin
  // Was gerade nicht geht, sperren statt eine Fehlermeldung zu zeigen
  FSave.Enabled := Trim(FFileName.Text) <> '';
end;

function AskFileName(AOwner: TComponent; AImages: TCustomImageList;
  AStyles: TPPGStyleManager; const ADefault: string): string;
var
  Dlg: TSaveAsDialog;
begin
  Result := '';
  Dlg := TSaveAsDialog.CreateDialog(AOwner, AImages, AStyles);
  try
    Dlg.FileNameEdit.Text := ADefault;
    // ShowModal endet, sobald ein Button mit ModalResult geklickt wurde
    if Dlg.ShowModal = mrOk then
      Result := Trim(Dlg.FileNameEdit.Text);
  finally
    Dlg.Free;
  end;
end;
// EXAMPLE-END

end.
