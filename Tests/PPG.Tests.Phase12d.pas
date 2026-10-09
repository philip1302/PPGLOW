unit PPG.Tests.Phase12d;

{ Tests fuer Phase 12g: DB-Varianten der Eingabefelder (PPG.DB.Fields) an
  einem TClientDataSet im Speicher. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Data.DB, Datasnap.DBClient,
  MidasLib,
  PPG.Types, PPG.Controls.Field, PPG.Edit, PPG.NumberFormat, PPG.NumberEdit, PPG.MaskEdit,
  PPG.ColorPicker, PPG.CheckComboBox, PPG.TagEdit, PPG.DB.Fields, PPG.Tests.Controls;

type
  TDBFieldTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FOther: TPPGEdit;
    FOldFS: TFormatSettings;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure NumberShowsValueAndNull;
    procedure NumberWritesOnCommit;
    procedure NumberPendingInputOnPost;
    procedure MaskTakesFieldMask;
    procedure ColorPickerWritesInteger;
    procedure CheckComboStoresText;
    procedure TagEditStoresTextAndPendingTag;
    procedure ReadOnlyWithoutModify;
    procedure InvalidValueStaysAtField;
  end;

implementation

uses
  PPG.Lang;

type
  TNumberAccess = class(TPPGDBNumberEdit);
  TFieldCrack = class(TPPGCustomField);

procedure TDBFieldTests.SetUp;
begin
  inherited SetUp;
  FOldFS := FormatSettings;
  FormatSettings := TFormatSettings.Create('de-DE');
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Betrag', ftCurrency);
  FData.FieldDefs.Add('PLZ', ftString, 5);
  FData.FieldDefs.Add('Farbe', ftInteger);
  FData.FieldDefs.Add('Kategorien', ftString, 100);
  FData.FieldDefs.Add('Tags', ftString, 100);
  FData.CreateDataSet;
  FData.FieldByName('PLZ').EditMask := '00000;0;_';
  FData.AppendRecord([1, 12.5, '10115', Integer(clRed), 'Rot;Blau', 'a;b']);
  FData.AppendRecord([2, Null, Null, Null, Null, Null]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  FOther := TPPGEdit.Create(FForm);
  FOther.Parent := FForm;
  FOther.SetBounds(10, 300, 100, 32);
  FForm.Show;
end;

procedure TDBFieldTests.TearDown;
begin
  FormatSettings := FOldFS;
  inherited TearDown;
end;

procedure TDBFieldTests.NumberShowsValueAndNull;
var
  E: TPPGDBNumberEdit;
begin
  E := TPPGDBNumberEdit.Create(FForm);
  E.Parent := FForm;
  E.Kind := nkCurrency;
  E.DataSource := FSource;
  E.DataField := 'Betrag';
  CheckTrue(E.AllowNull, 'DB: Null ist Vorgabe');
  CheckTrue(E.AsCurrency = 12.5);
  FData.Next;
  CheckTrue(E.IsNull, 'Null bleibt Null (nicht 0)');
  CheckEquals('', E.Text);
  CheckFalse(FData.State in dsEditModes, 'Anzeigen setzt nichts in Bearbeitung');
end;

procedure TDBFieldTests.NumberWritesOnCommit;
var
  E: TPPGDBNumberEdit;
  I: Integer;
  S: string;
begin
  E := TPPGDBNumberEdit.Create(FForm);
  E.Parent := FForm;
  E.Kind := nkCurrency;
  E.DataSource := FSource;
  E.DataField := 'Betrag';
  E.SetFocus;
  E.SelectAll;
  E.SelText := '';
  S := '2*19,99';
  for I := 1 to Length(S) do
    E.Controls[0].Perform(WM_CHAR, Ord(S[I]), 0);
  CheckTrue(FData.State = dsEdit, 'Tippen setzt den Datensatz in Bearbeitung');
  FOther.SetFocus;
  Application.ProcessMessages;
  CheckTrue(FData.FieldByName('Betrag').AsCurrency = 39.98);
  // Leeren = Null ins Feld
  E.SetFocus;
  E.SelectAll;
  E.SelText := '';
  FOther.SetFocus;
  Application.ProcessMessages;
  CheckTrue(FData.FieldByName('Betrag').IsNull);
end;

procedure TDBFieldTests.NumberPendingInputOnPost;
var
  E: TPPGDBNumberEdit;
  I: Integer;
  S: string;
begin
  E := TPPGDBNumberEdit.Create(FForm);
  E.Parent := FForm;
  E.DataSource := FSource;
  E.DataField := 'Betrag';
  E.SetFocus;
  E.SelectAll;
  E.SelText := '';
  S := '7+1';
  for I := 1 to Length(S) do
    E.Controls[0].Perform(WM_CHAR, Ord(S[I]), 0);
  // Post ueber Code (wie ein Navigator), Fokus bleibt im Feld
  FData.Post;
  CheckEquals(8, FData.FieldByName('Betrag').AsFloat, 1E-9, 'laufende Eingabe uebernommen');
end;

procedure TDBFieldTests.MaskTakesFieldMask;
var
  M: TPPGDBMaskEdit;
begin
  M := TPPGDBMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.DataSource := FSource;
  M.DataField := 'PLZ';
  CheckEquals('00000;0;_', M.EditMask, 'Maske aus dem Feld');
  CheckEquals('10115', M.Text);
  // Eigene Maske hat Vorrang
  M.DataField := '';
  M.EditMask := '99999;0;_';
  M.DataField := 'PLZ';
  CheckEquals('99999;0;_', M.EditMask);
  FData.Next;
  CheckTrue(M.IsEmpty, 'Null = leer');
end;

procedure TDBFieldTests.ColorPickerWritesInteger;
var
  P: TPPGDBColorPicker;
begin
  P := TPPGDBColorPicker.Create(FForm);
  P.Parent := FForm;
  P.DataSource := FSource;
  P.DataField := 'Farbe';
  CheckEquals(clRed, P.Selected);
  P.SelectColor(clBlue);
  CheckTrue(FData.State = dsEdit);
  FData.Post;
  CheckEquals(Integer(clBlue), FData.FieldByName('Farbe').AsInteger);
  FData.Next;
  CheckEquals(clNone, P.Selected, 'Null = keine Farbe');
end;

procedure TDBFieldTests.CheckComboStoresText;
var
  C: TPPGDBCheckComboBox;
begin
  C := TPPGDBCheckComboBox.Create(FForm);
  C.Parent := FForm;
  C.Items.CommaText := 'Rot,Gruen,Blau';
  C.DataSource := FSource;
  C.DataField := 'Kategorien';
  CheckEquals('Rot;Blau', C.CheckedText);
  C.ToggleItem(1);
  FData.Post;
  CheckEquals('Rot;Gruen;Blau', FData.FieldByName('Kategorien').AsString);
  FData.Next;
  CheckEquals(0, C.CheckedCount);
end;

procedure TDBFieldTests.TagEditStoresTextAndPendingTag;
var
  T: TPPGDBTagEdit;
  I: Integer;
begin
  T := TPPGDBTagEdit.Create(FForm);
  T.Parent := FForm;
  T.DataSource := FSource;
  T.DataField := 'Tags';
  CheckEquals('a;b', T.TagsText);
  CheckTrue(T.AddTag('c'));
  CheckTrue(FData.State = dsEdit, 'neues Tag setzt in Bearbeitung');
  T.SetFocus;
  for I := 1 to 1 do
    T.Controls[0].Perform(WM_CHAR, Ord('d'), 0);
  FData.Post;
  CheckEquals('a;b;c;d', FData.FieldByName('Tags').AsString, 'getippter Rest wird Tag');
  T.RemoveTag(0);
  FData.Post;
  CheckEquals('b;c;d', FData.FieldByName('Tags').AsString);
end;

procedure TDBFieldTests.ReadOnlyWithoutModify;
var
  E: TPPGDBNumberEdit;
  C: TPPGDBCheckComboBox;
begin
  E := TPPGDBNumberEdit.Create(FForm);
  E.Parent := FForm;
  E.DataSource := FSource;
  E.DataField := 'Betrag';
  E.ReadOnly := True;
  CheckTrue(E.ReadOnly);
  CheckTrue(TFieldCrack(E).ReadOnly, 'inneres Edit schreibgeschuetzt');
  C := TPPGDBCheckComboBox.Create(FForm);
  C.Parent := FForm;
  C.Items.CommaText := 'Rot,Gruen,Blau';
  C.DataSource := FSource;
  C.DataField := 'Kategorien';
  FData.ReadOnly := True;
  C.ToggleItem(1);
  CheckEquals('Rot;Blau', C.CheckedText, 'nicht aenderbar: Feldwert bleibt');
  FData.ReadOnly := False;
end;

procedure TDBFieldTests.InvalidValueStaysAtField;
var
  M: TPPGDBMaskEdit;
begin
  M := TPPGDBMaskEdit.Create(FForm);
  M.Parent := FForm;
  M.DataSource := FSource;
  M.DataField := 'PLZ';
  FData.FieldByName('PLZ').OnValidate := nil;
  M.SetFocus;
  M.Controls[0].Perform(WM_CHAR, Ord('1'), 0);
  M.Controls[0].Perform(WM_CHAR, Ord('2'), 0);
  FOther.SetFocus;
  Application.ProcessMessages;
  CheckTrue(M.ValidationState = pvsError, 'Fehler am Feld');
  CheckEquals(0, FAppExceptions, 'kein Dialog');
  CheckEquals('10115', FData.FieldByName('PLZ').AsString, 'ungueltiges nicht geschrieben');
end;

initialization
  RegisterTest('Phase12d', TDBFieldTests.Suite);

end.
