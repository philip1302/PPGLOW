unit PPG.Grid.Edit;

{ Zell-Editoren des Grids (Phase 13a, aus PPG.Grid herausgeloest).

  - Welche Control-Klasse eine Editor-Art bearbeitet, steht in einer
    Registry (PPGRegisterGridEditor) statt in einem case im Grid (OCP):
    eigene Editoren lassen sich registrieren, ohne das Grid zu aendern.
  - Das Grid spricht den Editor nur ueber IPPGGridCellEditor an. Ein
    registriertes Control ohne dieses Interface, aber mit IPPGFieldValue
    (alle Felder aus Phase 12), funktioniert ebenfalls: Text rein/raus ueber
    den Feldwert.
  - Enter/Esc/Tab gehoeren dem Grid (WantSpecialKey), nicht dem Dialog. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils, System.Variants, Vcl.Controls,
  PPG.Controls.Base, PPG.Edit, PPG.ComboBox, PPG.SpinEdit, PPG.Grid.Columns;

type
  IPPGGridCellEditor = interface
    ['{7F3A9C24-D61B-4E85-A0C7-2B94E15D6F83}']
    /// Editor fuer eine Zelle vorbereiten (Text, Auswahlliste, Bereich).
    procedure CellEditorBegin(const Text: string; Column: TPPGGridColumn);
    function CellEditorText: string;
    /// Bearbeitung beginnt mit einem getippten Zeichen (wie Excel).
    procedure CellEditorTypeChar(C: Char);
    /// True: Pfeil hoch/runter uebernimmt und wechselt die Zeile.
    function CellEditorArrowsLeave: Boolean;
  end;

  TPPGGridEdit = class(TPPGEdit, IPPGGridCellEditor)
  protected
    function WantSpecialKey(Key: Word): Boolean; override;
  public
    procedure CellEditorBegin(const Text: string; Column: TPPGGridColumn);
    function CellEditorText: string;
    procedure CellEditorTypeChar(C: Char);
    function CellEditorArrowsLeave: Boolean;
  end;

  TPPGGridCombo = class(TPPGComboBox, IPPGGridCellEditor)
  protected
    function WantSpecialKey(Key: Word): Boolean; override;
  public
    procedure CellEditorBegin(const Text: string; Column: TPPGGridColumn);
    function CellEditorText: string;
    procedure CellEditorTypeChar(C: Char);
    function CellEditorArrowsLeave: Boolean;
  end;

  TPPGGridSpin = class(TPPGSpinEdit, IPPGGridCellEditor)
  protected
    function WantSpecialKey(Key: Word): Boolean; override;
  public
    procedure CellEditorBegin(const Text: string; Column: TPPGGridColumn);
    function CellEditorText: string;
    procedure CellEditorTypeChar(C: Char);
    function CellEditorArrowsLeave: Boolean;
  end;

  TPPGGridEditorClass = class of TPPGCustomControl;

/// Editor-Klasse fuer eine Art festlegen (ersetzt eine fruehere Zuordnung).
procedure PPGRegisterGridEditor(Kind: TPPGGridEditorKind; AClass: TPPGGridEditorClass);
/// Registrierte Klasse; nil = Art hat keinen Editor (gekNone, gekCheck).
function PPGGridEditorClass(Kind: TPPGGridEditorKind): TPPGGridEditorClass;

/// Editor erzeugen und an das Grid haengen (Parent, Preset, Ereignisse).
function PPGCreateGridEditor(Kind: TPPGGridEditorKind; Grid: TPPGCustomControl;
  OnKeyDown: TKeyEvent; OnExit: TNotifyEvent): TPPGCustomControl;
procedure PPGGridEditorBegin(Editor: TPPGCustomControl; const Text: string;
  Column: TPPGGridColumn);
function PPGGridEditorText(Editor: TPPGCustomControl): string;
procedure PPGGridEditorTypeChar(Editor: TPPGCustomControl; C: Char);
function PPGGridEditorArrowsLeave(Editor: TObject): Boolean;

implementation

uses
  PPG.Controls.Field;

type
  TCtrlAccess = class(TPPGCustomControl);

var
  GEditors: array[TPPGGridEditorKind] of TPPGGridEditorClass;

procedure PPGRegisterGridEditor(Kind: TPPGGridEditorKind; AClass: TPPGGridEditorClass);
begin
  GEditors[Kind] := AClass;
end;

function PPGGridEditorClass(Kind: TPPGGridEditorKind): TPPGGridEditorClass;
begin
  Result := GEditors[Kind];
end;

function PPGCreateGridEditor(Kind: TPPGGridEditorKind; Grid: TPPGCustomControl;
  OnKeyDown: TKeyEvent; OnExit: TNotifyEvent): TPPGCustomControl;
var
  Cls: TPPGGridEditorClass;
begin
  Cls := GEditors[Kind];
  if Cls = nil then
    Cls := GEditors[gekText];
  Result := Cls.Create(Grid);
  Result.Visible := False;
  Result.Parent := Grid;
  TCtrlAccess(Result).Preset := TCtrlAccess(Grid).Preset;
  TCtrlAccess(Result).Animation.Enabled := False;
  TCtrlAccess(Result).AutoSize := False;
  TCtrlAccess(Result).OnKeyDown := OnKeyDown;
  TCtrlAccess(Result).OnExit := OnExit;
end;

procedure PPGGridEditorBegin(Editor: TPPGCustomControl; const Text: string;
  Column: TPPGGridColumn);
var
  CE: IPPGGridCellEditor;
  FV: IPPGFieldValue;
begin
  if Supports(Editor, IPPGGridCellEditor, CE) then
    CE.CellEditorBegin(Text, Column)
  else if Supports(Editor, IPPGFieldValue, FV) then
  begin
    if Text = '' then
      FV.FieldClear
    else
      FV.SetFieldValue(Text);
  end;
end;

function PPGGridEditorText(Editor: TPPGCustomControl): string;
var
  CE: IPPGGridCellEditor;
  FV: IPPGFieldValue;
begin
  if Supports(Editor, IPPGGridCellEditor, CE) then
    Result := CE.CellEditorText
  else if Supports(Editor, IPPGFieldValue, FV) then
  begin
    if FV.FieldIsNull then
      Result := ''
    else
      Result := VarToStr(FV.GetFieldValue);
  end
  else
    Result := '';
end;

procedure PPGGridEditorTypeChar(Editor: TPPGCustomControl; C: Char);
var
  CE: IPPGGridCellEditor;
begin
  if Supports(Editor, IPPGGridCellEditor, CE) then
    CE.CellEditorTypeChar(C);
end;

function PPGGridEditorArrowsLeave(Editor: TObject): Boolean;
var
  CE: IPPGGridCellEditor;
begin
  Result := Supports(Editor, IPPGGridCellEditor, CE) and CE.CellEditorArrowsLeave;
end;

function GridWantsKey(Key: Word): Boolean;
begin
  Result := (Key = VK_RETURN) or (Key = VK_ESCAPE) or (Key = VK_TAB);
end;

{ TPPGGridEdit }

function TPPGGridEdit.WantSpecialKey(Key: Word): Boolean;
begin
  Result := GridWantsKey(Key) or inherited WantSpecialKey(Key);
end;

procedure TPPGGridEdit.CellEditorBegin(const Text: string; Column: TPPGGridColumn);
begin
  Self.Text := Text;
  SelectAll;
end;

function TPPGGridEdit.CellEditorText: string;
begin
  Result := Text;
end;

procedure TPPGGridEdit.CellEditorTypeChar(C: Char);
begin
  Text := C;
  SelStart := 1;
end;

function TPPGGridEdit.CellEditorArrowsLeave: Boolean;
begin
  Result := True;
end;

{ TPPGGridCombo }

function TPPGGridCombo.WantSpecialKey(Key: Word): Boolean;
begin
  Result := GridWantsKey(Key) or inherited WantSpecialKey(Key);
end;

procedure TPPGGridCombo.CellEditorBegin(const Text: string; Column: TPPGGridColumn);
begin
  if Column <> nil then
    Items.Assign(Column.PickList);
  Self.Text := Text;
end;

function TPPGGridCombo.CellEditorText: string;
begin
  Result := Text;
end;

procedure TPPGGridCombo.CellEditorTypeChar(C: Char);
begin
  Text := C;
end;

function TPPGGridCombo.CellEditorArrowsLeave: Boolean;
begin
  Result := False; // Pfeile blaettern in der Liste
end;

{ TPPGGridSpin }

function TPPGGridSpin.WantSpecialKey(Key: Word): Boolean;
begin
  Result := GridWantsKey(Key) or inherited WantSpecialKey(Key);
end;

procedure TPPGGridSpin.CellEditorBegin(const Text: string; Column: TPPGGridColumn);
begin
  if Column <> nil then
  begin
    Min := Column.MinValue;
    Max := Column.MaxValue;
  end;
  Value := StrToIntDef(Text, 0);
end;

function TPPGGridSpin.CellEditorText: string;
begin
  Result := IntToStr(Value);
end;

procedure TPPGGridSpin.CellEditorTypeChar(C: Char);
begin
  Value := StrToIntDef(C, Value);
end;

function TPPGGridSpin.CellEditorArrowsLeave: Boolean;
begin
  Result := False; // Pfeile aendern den Wert
end;

initialization
  PPGRegisterGridEditor(gekText, TPPGGridEdit);
  PPGRegisterGridEditor(gekCombo, TPPGGridCombo);
  PPGRegisterGridEditor(gekSpin, TPPGGridSpin);

end.
