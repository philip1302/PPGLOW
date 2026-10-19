unit UnitCX;

interface

uses
  Winapi.Windows, System.Classes, Vcl.Forms, cxButtons, cxCheckBox, cxDBLookupComboBox, cxPC,
  cxNavigator, cxCheckComboBox, JvToolEdit, JvCheckBox, JvComboBox;

type
  TFormCX = class(TForm)
    BtnGlyph: TcxButton;
    BtnIndex: TcxButton;
    BtnDrop: TcxButton;
    CheckA: TcxCheckBox;
    LookupA: TcxDBLookupComboBox;
    ToggleA: TdxDBToggleSwitch;
    Pages: TcxPageControl;
    SheetA, SheetB: TcxTabSheet;
    NavA: TcxNavigator;
    CheckCombo: TcxCheckComboBox;
    CheckComboLeer: TcxCheckComboBox;
    DirEdit: TJvDirectoryEdit;
    FileEdit: TJvFilenameEdit;
    FileEditOpen: TJvFilenameEdit;
    JvChkBoth: TJvCheckBox;
    JvChkOnly: TJvCheckBox;
    JvChkOff: TJvCheckBox;
    JvCombo: TJvComboBox;
    procedure BtnGlyphClick(Sender: TObject);
  end;

implementation

procedure TFormCX.BtnGlyphClick(Sender: TObject);
begin
  if TcxCheckBox(Sender).Checked then
    CheckA.Properties.Alignment := taLeftJustify;
  if CheckA.EditValue = True then
    Exit;
end;

end.
