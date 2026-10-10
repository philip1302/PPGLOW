unit DemoInspector;

// Objektinspektor der Komponentenseiten: zeigt alle published Eigenschaften
// und Ereignisse einer Komponente samt Unterobjekten (Appearance, Font ...)
// und aendert sie live, wie der Objektinspektor der IDE.
//
// Modell (TDemoPropModel, TDemoPropNode): reines TypInfo (XE2-tauglich).
// Ein Knoten kennt nur seinen Pfad (Appearance.Normal.Color); das Objekt,
// an dem die Eigenschaft steht, wird bei jedem Zugriff ueber die Eltern
// aufgeloest. Deshalb lassen sich dieselben Knoten auf eine zweite Instanz
// anwenden (Vergleich mit einer frisch erzeugten Komponente: "geaendert",
// "zuruecksetzen" und Code-Erzeugung).
//
// Ansicht (TDemoInspector): Zeilen in einer TPPGScrollBox, nach Kategorien
// gruppiert; Unterobjekte klappen auf und werden erst dann aufgebaut. Je Typ
// ein PPGlow-Editor (Schalter, Auswahlliste, Zahlfeld, Farbauswahl,
// Kontrollkaestchen-Gruppe, Textfeld).

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.TypInfo,
  System.Generics.Collections, Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls,
  PPG.Types, PPG.Panel, PPG.Labels, PPG.Edit, PPG.SpinEdit, PPG.ComboBox, PPG.ToggleSwitch,
  PPG.RadioGroup, PPG.ColorPicker, PPG.Button, PPG.Memo;

type
  TDemoPropKind = (pkInteger, pkInt64, pkEnum, pkBoolean, pkSet, pkString, pkColor,
    pkIdentInt, pkFloat, pkComponent, pkObject, pkEvent, pkOther,
    // TStrings (Items, Lines), TCollection (Panels, Tabs ...) und ein Eintrag darin
    pkStrings, pkCollection, pkItem,
    // Char (PasswordChar, Delimiter ...)
    pkChar);

  TDemoPropModel = class;

  TDemoPropNode = class
  private
    FModel: TDemoPropModel;
    FParent: TDemoPropNode;
    FInfo: PPropInfo;
    FKind: TDemoPropKind;
    FChildren: TObjectList<TDemoPropNode>;
    FItemIndex: Integer;
    FItemClass: string;
  public
    constructor Create(AModel: TDemoPropModel; AParent: TDemoPropNode; AInfo: PPropInfo);
    /// Eintrag Nr. AIndex einer Collection (Knoten ohne PropInfo).
    constructor CreateItem(AModel: TDemoPropModel; AParent: TDemoPropNode; AIndex: Integer;
      const AClassName: string);
    destructor Destroy; override;
    function Name: string;
    /// Pfad ab der Komponente, z. B. Appearance.Normal.Color.
    function Path: string;
    function Level: Integer;
    function PropType: PTypeInfo;
    function TypeName: string;
    function ReadOnly: Boolean;
    /// Objekt, an dem die Eigenschaft steht, fuer die Komponente ARoot.
    function OwnerIn(ARoot: TObject): TObject;
    function GetOrd(ARoot: TObject): Int64;
    procedure SetOrd(ARoot: TObject; Value: Int64);
    function GetStr(ARoot: TObject): string;
    procedure SetStr(ARoot: TObject; const Value: string);
    function GetObj(ARoot: TObject): TObject;
    procedure SetObj(ARoot: TObject; Value: TObject);
    /// Objekt dieses Knotens (Unterobjekt, Liste, Collection, Eintrag) oder nil.
    function ValueIn(ARoot: TObject): TObject;
    /// Knoten liegt in einem Collection-Eintrag (Panels[0].Text ...).
    function InItem: Boolean;
    property ItemIndex: Integer read FItemIndex;
    /// Wert als Pascal-Ausdruck (clRed, [fsBold], 'Text', taCenter, nil ...).
    function Literal(ARoot: TObject): string;
    /// Gleicher Wert in beiden Komponenten (Unterobjekte: alle Kinder gleich;
    /// Ereignisse zaehlen nie als Unterschied).
    function SameIn(A, B: TObject): Boolean;
    /// Wert von ASource nach ATarget uebernehmen (Unterobjekte: alle Kinder).
    procedure CopyValue(ASource, ATarget: TObject);
    property Model: TDemoPropModel read FModel;
    property Parent: TDemoPropNode read FParent;
    property Info: PPropInfo read FInfo;
    property Kind: TDemoPropKind read FKind;
    property Children: TObjectList<TDemoPropNode> read FChildren;
  end;

  TDemoPropModel = class
  private
    FRoot: TObject;
    FNodes: TObjectList<TDemoPropNode>;
    procedure AddChildren(AParent: TDemoPropNode; AObj: TObject; List: TObjectList<TDemoPropNode>;
      Depth: Integer);
    procedure CollectAll(List: TObjectList<TDemoPropNode>; Target: TList<TDemoPropNode>);
  public
    constructor Create(ARoot: TObject);
    destructor Destroy; override;
    /// Alle Knoten (Tiefensuche, Deklarations- und damit Streaming-Reihenfolge).
    procedure GetAll(Target: TList<TDemoPropNode>);
    function Find(const APath: string): TDemoPropNode;
    property Root: TObject read FRoot;
    /// Eigenschaften der Komponente selbst (Deklarationsreihenfolge).
    property Nodes: TObjectList<TDemoPropNode> read FNodes;
  end;

  TDemoInspector = class;

  TDemoRowKind = (rkCategory, rkProp);

  /// Eine Zeile des Inspektors (Kategorie oder Eigenschaft).
  TDemoInspRow = class(TPanel)
  private
    FInspector: TDemoInspector;
    FRowKind: TDemoRowKind;
    FNode: TDemoPropNode;
    FCategory: string;
    FParentRow: TDemoInspRow;
    FExpanded: Boolean;
    FChildrenBuilt: Boolean;
    FChevron: TPPGLabel;
    FCaptionLbl: TPPGLabel;
    FValueLbl: TPPGLabel;
    FEditor: TControl;
    FEditor2: TControl;
    FReset: TPPGLabel;
    FEventCount: Integer;
    FSelected: Boolean;
    FRowHeight: Integer;
    procedure RowClick(Sender: TObject);
    procedure ResetClick(Sender: TObject);
    procedure EditorEnter(Sender: TObject);
    procedure SetSelected(const Value: Boolean);
  protected
    procedure Resize; override;
  public
    constructor CreateRow(AInspector: TDemoInspector; AKind: TDemoRowKind; ANode: TDemoPropNode;
      const ACategory: string; AParentRow: TDemoInspRow);
    /// Editor bzw. Wertanzeige aus der Komponente neu lesen.
    procedure ReadValue;
    procedure LayoutParts;
    function Expandable: Boolean;
    property Node: TDemoPropNode read FNode;
    property RowKind: TDemoRowKind read FRowKind;
    property Category: string read FCategory;
    property ParentRow: TDemoInspRow read FParentRow;
    property Expanded: Boolean read FExpanded;
    property Editor: TControl read FEditor;
    property CaptionLabel: TPPGLabel read FCaptionLbl;
    property RowHeight: Integer read FRowHeight;
    property Selected: Boolean read FSelected write SetSelected;
  end;

  TDemoNodeEvent = procedure(Sender: TObject; Node: TDemoPropNode) of object;
  TDemoNodeErrorEvent = procedure(Sender: TObject; Node: TDemoPropNode; const Msg: string) of object;
  /// Kategorie einer Eigenschaft der Komponente festlegen (Name ohne Pfad);
  /// nur Namen aus DemoCategories, sonst gilt Sonstiges.
  TDemoCategoryEvent = procedure(Sender: TObject; const AName: string; var ACategory: string) of object;

  TDemoInspector = class(TPanel)
  private
    FModel: TDemoPropModel;
    FReference: TObject;
    FCandidates: TList<TComponent>;
    FFilter: TPPGEdit;
    FBox: TPPGScrollBox;
    FRows: TList<TDemoInspRow>;
    FUpdating: Integer;
    FChangingRow: TDemoInspRow;
    FSelectedRow: TDemoInspRow;
    FSelectedColor: TColor;
    FOnSelect: TDemoNodeEvent;
    FOnChanged: TDemoNodeEvent;
    FOnError: TDemoNodeErrorEvent;
    FOnCategory: TDemoCategoryEvent;
    FRebuildPath: string;
    procedure FilterChange(Sender: TObject);
    procedure StringsClick(Sender: TObject);
    procedure AddItemClick(Sender: TObject);
    procedure RemoveItemClick(Sender: TObject);
    procedure WMRebuild(var Msg: TMessage); message WM_USER + 501;
    procedure ChangeCollection(Node: TDemoPropNode; AAdd: Boolean);
    procedure BoxResize(Sender: TObject);
    procedure EditorChange(Sender: TObject);
    procedure ComboSelect(Sender: TObject);
    function RowOfEditor(Sender: TObject): TDemoInspRow;
    procedure ApplyEditor(Row: TDemoInspRow);
    procedure BuildChildRows(Row: TDemoInspRow);
    procedure BuildAllRows;
    function RowShown(Row: TDemoInspRow): Boolean;
    function MatchesFilter(Row: TDemoInspRow): Boolean;
    procedure CreateEditor(Row: TDemoInspRow);
    procedure FillCombo(Row: TDemoInspRow; Combo: TPPGComboBox);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Komponente anzeigen. AReference: frisch erzeugte Instanz derselben
    /// Klasse als Vorgabe (fuer "geaendert" und "zuruecksetzen"), darf nil sein.
    procedure Inspect(AComponent, AReference: TObject);
    /// Alle Zeilen neu aus der Komponente lesen (nach Aenderungen von aussen).
    procedure RefreshValues;
    procedure Relayout;
    /// Zeile zur Eigenschaft (Pfad) waehlen, Kategorie und Eltern aufklappen.
    function SelectPath(const APath: string): Boolean;
    /// Ereignis wurde ausgeloest (Zaehler in der Zeile).
    procedure EventFired(const AName: string);
    /// Wert einer Zeile wie durch den Anwender setzen (Selbsttest).
    function SetValueText(const APath, AValue: string): Boolean;
    procedure ResetNode(Node: TDemoPropNode);
    function IsChanged(Node: TDemoPropNode): Boolean;
    function RowOf(const APath: string): TDemoInspRow;
    function CategoryOf(Node: TDemoPropNode): string;
    procedure SetSelectionColor(AColor: TColor);
    /// Modell neu aufbauen (nach Aenderungen an Collections), Zeile APath waehlen.
    procedure Rebuild(const APath: string);
    /// Eintrag an eine Collection anhaengen bzw. den letzten entfernen (wie die
    /// Knoepfe + und -), danach Neuaufbau. False = keine Collection.
    function AddCollectionItem(const APath: string): Boolean;
    function RemoveCollectionItem(const APath: string): Boolean;
    property Model: TDemoPropModel read FModel;
    property Reference: TObject read FReference;
    /// Komponenten, die fuer Verweis-Eigenschaften (Images, PopupMenu ...)
    /// zur Auswahl stehen.
    property Candidates: TList<TComponent> read FCandidates;
    property Rows: TList<TDemoInspRow> read FRows;
    property FilterEdit: TPPGEdit read FFilter;
    property ScrollBox: TPPGScrollBox read FBox;
    property OnSelect: TDemoNodeEvent read FOnSelect write FOnSelect;
    property OnChanged: TDemoNodeEvent read FOnChanged write FOnChanged;
    property OnError: TDemoNodeErrorEvent read FOnError write FOnError;
    property OnCategory: TDemoCategoryEvent read FOnCategory write FOnCategory;
  end;

const
  /// Kategorien in der Reihenfolge des Inspektors.
  DemoCategories: array[0..11] of string = ('PPGlow', 'Inhalt', 'Beschriftung & Bild', 'Verhalten',
    'Layout', 'Tastatur & Fokus', 'Hinweise & Hilfe', 'Darstellung (VCL)', 'Ziehen & Touch',
    'Daten', 'Sonstiges', 'Ereignisse');

/// Name eines TModalResult-Werts (mrOk ...), '' = keiner.
function ModalResultIdent(Value: Integer): string;

implementation

uses
  System.Math, System.UITypes, System.Generics.Defaults, Vcl.Forms, Vcl.StdCtrls,
  PPG.Render.Registry, PPG.IconFont, DemoKit;

type
  TWinControlAccess = class(TWinControl);

const
  RowH = 34;
  ModalNames: array[0..10] of string = ('mrNone', 'mrOk', 'mrCancel', 'mrAbort', 'mrRetry',
    'mrIgnore', 'mrYes', 'mrNo', 'mrAll', 'mrNoToAll', 'mrYesToAll');

function ModalValue(Index: Integer): Integer;
begin
  case Index of
    1: Result := mrOk;
    2: Result := mrCancel;
    3: Result := mrAbort;
    4: Result := mrRetry;
    5: Result := mrIgnore;
    6: Result := mrYes;
    7: Result := mrNo;
    8: Result := mrAll;
    9: Result := mrNoToAll;
    10: Result := mrYesToAll;
  else
    Result := mrNone;
  end;
end;

function ModalResultIdent(Value: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(ModalNames) do
    if ModalValue(I) = Value then
      Exit(ModalNames[I]);
end;

function TypeNameOf(T: PTypeInfo): string;
begin
  Result := string(T^.Name);
end;

function KindOf(Info: PPropInfo): TDemoPropKind;
var
  T: PTypeInfo;
  N: string;
  C: TClass;
begin
  T := Info^.PropType^;
  N := TypeNameOf(T);
  case T^.Kind of
    tkInteger:
      if SameText(N, 'TColor') then
        Result := pkColor
      else if SameText(N, 'TCursor') or SameText(N, 'TModalResult') or SameText(N, 'TFontCharset') then
        Result := pkIdentInt
      else
        Result := pkInteger;
    tkInt64:
      Result := pkInt64;
    tkEnumeration:
      if GetTypeData(T)^.BaseType^ = System.TypeInfo(Boolean) then
        Result := pkBoolean
      else
        Result := pkEnum;
    tkSet:
      Result := pkSet;
    tkString, tkLString, tkWString, tkUString:
      Result := pkString;
    tkFloat:
      Result := pkFloat;
    tkClass:
      begin
        C := GetTypeData(T)^.ClassType;
        if C.InheritsFrom(TComponent) then
          Result := pkComponent
        else if C.InheritsFrom(TCollection) then
          Result := pkCollection
        else if C.InheritsFrom(TStrings) then
          Result := pkStrings
        else
          Result := pkObject;
      end;
    tkChar, tkWChar:
      Result := pkChar;
    tkMethod:
      Result := pkEvent;
  else
    Result := pkOther;
  end;
end;

{ TDemoPropNode }

constructor TDemoPropNode.Create(AModel: TDemoPropModel; AParent: TDemoPropNode; AInfo: PPropInfo);
begin
  inherited Create;
  FModel := AModel;
  FParent := AParent;
  FInfo := AInfo;
  FItemIndex := -1;
  FKind := KindOf(AInfo);
  FChildren := TObjectList<TDemoPropNode>.Create(True);
end;

constructor TDemoPropNode.CreateItem(AModel: TDemoPropModel; AParent: TDemoPropNode;
  AIndex: Integer; const AClassName: string);
begin
  inherited Create;
  FModel := AModel;
  FParent := AParent;
  FInfo := nil;
  FItemIndex := AIndex;
  FItemClass := AClassName;
  FKind := pkItem;
  FChildren := TObjectList<TDemoPropNode>.Create(True);
end;

destructor TDemoPropNode.Destroy;
begin
  FChildren.Free;
  inherited Destroy;
end;

function TDemoPropNode.Name: string;
begin
  if FInfo = nil then
    Result := Format('[%d]', [FItemIndex])
  else
    Result := string(FInfo^.Name);
end;

function TDemoPropNode.Path: string;
begin
  if FParent = nil then
    Result := Name
  else if FInfo = nil then
    Result := FParent.Path + Name
  else
    Result := FParent.Path + '.' + Name;
end;

function TDemoPropNode.Level: Integer;
begin
  if FParent = nil then
    Result := 0
  else
    Result := FParent.Level + 1;
end;

function TDemoPropNode.PropType: PTypeInfo;
begin
  if FInfo = nil then
    Result := nil
  else
    Result := FInfo^.PropType^;
end;

function TDemoPropNode.TypeName: string;
begin
  if FInfo = nil then
    Result := FItemClass
  else
    Result := TypeNameOf(PropType);
end;

function TDemoPropNode.ReadOnly: Boolean;
begin
  if FInfo = nil then
    Result := True
  else
    Result := (FInfo^.SetProc = nil) and not (FKind in [pkObject, pkStrings, pkCollection]);
end;

function TDemoPropNode.InItem: Boolean;
var
  P: TDemoPropNode;
begin
  Result := False;
  P := FParent;
  while P <> nil do
  begin
    if P.FKind = pkItem then
      Exit(True);
    P := P.FParent;
  end;
end;

function TDemoPropNode.OwnerIn(ARoot: TObject): TObject;
begin
  if FParent = nil then
    Result := ARoot
  else
    Result := FParent.ValueIn(ARoot);
end;

function TDemoPropNode.ValueIn(ARoot: TObject): TObject;
var
  O: TObject;
begin
  Result := nil;
  if FInfo = nil then
  begin
    // Eintrag einer Collection: Eltern-Knoten ist die Collection
    if FParent = nil then
      Exit;
    O := FParent.ValueIn(ARoot);
    if (O is TCollection) and (FItemIndex >= 0) and (FItemIndex < TCollection(O).Count) then
      Result := TCollection(O).Items[FItemIndex];
    Exit;
  end;
  if FInfo^.PropType^.Kind <> tkClass then
    Exit;
  O := OwnerIn(ARoot);
  if O <> nil then
    Result := GetObjectProp(O, FInfo);
end;

function TDemoPropNode.GetOrd(ARoot: TObject): Int64;
var
  O: TObject;
begin
  O := OwnerIn(ARoot);
  if (O = nil) or (FInfo = nil) then
    Exit(0);
  if FKind = pkInt64 then
    Result := GetInt64Prop(O, FInfo)
  else
    Result := GetOrdProp(O, FInfo);
end;

procedure TDemoPropNode.SetOrd(ARoot: TObject; Value: Int64);
var
  O: TObject;
begin
  O := OwnerIn(ARoot);
  if (O = nil) or (FInfo = nil) then
    Exit;
  if FKind = pkInt64 then
    SetInt64Prop(O, FInfo, Value)
  else
    SetOrdProp(O, FInfo, Value);
end;

function TDemoPropNode.GetStr(ARoot: TObject): string;
var
  O: TObject;
begin
  O := OwnerIn(ARoot);
  if (O = nil) or (FInfo = nil) then
    Result := ''
  else if FKind = pkStrings then
  begin
    O := ValueIn(ARoot);
    if O is TStrings then
      Result := TStrings(O).Text
    else
      Result := '';
  end
  else
    Result := GetStrProp(O, FInfo);
end;

procedure TDemoPropNode.SetStr(ARoot: TObject; const Value: string);
var
  O: TObject;
begin
  O := OwnerIn(ARoot);
  if (O = nil) or (FInfo = nil) then
    Exit;
  if FKind = pkStrings then
  begin
    O := ValueIn(ARoot);
    if O is TStrings then
      TStrings(O).Text := Value;
  end
  else
    SetStrProp(O, FInfo, Value);
end;

function TDemoPropNode.GetObj(ARoot: TObject): TObject;
begin
  Result := ValueIn(ARoot);
end;

procedure TDemoPropNode.SetObj(ARoot: TObject; Value: TObject);
var
  O: TObject;
begin
  O := OwnerIn(ARoot);
  if (O <> nil) and (FInfo <> nil) then
    SetObjectProp(O, FInfo, Value);
end;

function StringsLiteral(S: TStrings): string;
var
  I: Integer;
begin
  // 'Zeile 1' + sLineBreak + 'Zeile 2'
  Result := '';
  for I := 0 to S.Count - 1 do
  begin
    if I > 0 then
      Result := Result + ' + sLineBreak + ';
    Result := Result + QuotedStr(S[I]);
  end;
  if Result = '' then
    Result := '''''';
end;

function TDemoPropNode.Literal(ARoot: TObject): string;
var
  V: Int64;
  O: TObject;
  S: string;
  FS: TFormatSettings;
begin
  O := OwnerIn(ARoot);
  if O = nil then
    Exit('');
  case FKind of
    pkInteger, pkInt64:
      Result := IntToStr(GetOrd(ARoot));
    pkColor:
      begin
        V := GetOrd(ARoot);
        if not ColorToIdent(Integer(V), Result) then
          Result := '$' + IntToHex(Integer(V), 8);
      end;
    pkIdentInt:
      begin
        V := GetOrd(ARoot);
        Result := '';
        if SameText(TypeName, 'TCursor') then
        begin
          if not CursorToIdent(Integer(V), Result) then
            Result := '';
        end
        else if SameText(TypeName, 'TModalResult') then
          Result := ModalResultIdent(Integer(V))
        else if SameText(TypeName, 'TFontCharset') then
        begin
          if not CharsetToIdent(Integer(V), Result) then
            Result := '';
        end;
        if Result = '' then
          Result := IntToStr(V);
      end;
    pkEnum, pkBoolean:
      Result := GetEnumName(PropType, Integer(GetOrd(ARoot)));
    pkSet:
      Result := SetToString(FInfo, Integer(GetOrd(ARoot)), True);
    pkString:
      Result := QuotedStr(GetStr(ARoot));
    pkFloat:
      begin
        FS := TFormatSettings.Create('en-US');
        Result := FloatToStr(GetFloatProp(O, FInfo), FS);
      end;
    pkComponent:
      begin
        O := GetObj(ARoot);
        if O = nil then
          Result := 'nil'
        else
        begin
          S := TComponent(O).Name;
          if S = '' then
            S := '(' + O.ClassName + ')';
          Result := S;
        end;
      end;
    pkObject:
      begin
        O := GetObj(ARoot);
        if O = nil then
          Result := 'nil'
        else
          Result := '(' + O.ClassName + ')';
      end;
    pkStrings:
      begin
        O := ValueIn(ARoot);
        if O is TStrings then
          Result := StringsLiteral(TStrings(O))
        else
          Result := '''''';
      end;
    pkCollection:
      begin
        O := ValueIn(ARoot);
        if O is TCollection then
          Result := Format('(%d)', [TCollection(O).Count])
        else
          Result := '(0)';
      end;
    pkItem:
      begin
        O := ValueIn(ARoot);
        if O is TCollectionItem then
          Result := TCollectionItem(O).DisplayName
        else
          Result := '';
      end;
    pkChar:
      begin
        V := GetOrd(ARoot);
        if (V >= 32) and (V < 127) and (V <> 39) then
          Result := QuotedStr(Char(V))
        else
          Result := '#$' + IntToHex(Integer(V), 4);
      end;
    pkEvent:
      Result := TypeName;
  else
    Result := '(' + TypeName + ')';
  end;
end;

function TDemoPropNode.SameIn(A, B: TObject): Boolean;
var
  I: Integer;
  OA, OB: TObject;
begin
  OA := OwnerIn(A);
  OB := OwnerIn(B);
  if (OA = nil) or (OB = nil) then
    Exit(OA = OB);
  case FKind of
    pkObject, pkItem:
      begin
        if (FKind = pkItem) and ((ValueIn(A) = nil) or (ValueIn(B) = nil)) then
          Exit(ValueIn(A) = ValueIn(B));
        for I := 0 to FChildren.Count - 1 do
          if not FChildren[I].SameIn(A, B) then
            Exit(False);
        Result := True;
      end;
    pkCollection:
      begin
        OA := ValueIn(A);
        OB := ValueIn(B);
        if not ((OA is TCollection) and (OB is TCollection)) then
          Exit(OA = OB);
        if TCollection(OA).Count <> TCollection(OB).Count then
          Exit(False);
        for I := 0 to FChildren.Count - 1 do
          if not FChildren[I].SameIn(A, B) then
            Exit(False);
        Result := True;
      end;
    pkEvent, pkOther:
      Result := True;
    pkString, pkStrings:
      Result := GetStr(A) = GetStr(B);
    pkFloat:
      Result := SameValue(GetFloatProp(OA, FInfo), GetFloatProp(OB, FInfo));
    pkComponent:
      Result := GetObj(A) = GetObj(B);
  else
    Result := GetOrd(A) = GetOrd(B);
  end;
end;

procedure TDemoPropNode.CopyValue(ASource, ATarget: TObject);
var
  I: Integer;
  OS, OT: TObject;
begin
  OS := OwnerIn(ASource);
  OT := OwnerIn(ATarget);
  if (OS = nil) or (OT = nil) then
    Exit;
  case FKind of
    pkObject, pkItem:
      for I := 0 to FChildren.Count - 1 do
        FChildren[I].CopyValue(ASource, ATarget);
    pkCollection, pkStrings:
      begin
        OS := ValueIn(ASource);
        OT := ValueIn(ATarget);
        if (OS is TPersistent) and (OT is TPersistent) then
          TPersistent(OT).Assign(TPersistent(OS));
      end;
    pkEvent, pkOther:
      ;
    pkString:
      if not ReadOnly then
        SetStr(ATarget, GetStr(ASource));
    pkFloat:
      if not ReadOnly then
        SetFloatProp(OT, FInfo, GetFloatProp(OS, FInfo));
    pkComponent:
      if not ReadOnly then
        SetObj(ATarget, GetObj(ASource));
  else
    if not ReadOnly then
      SetOrd(ATarget, GetOrd(ASource));
  end;
end;

{ TDemoPropModel }

constructor TDemoPropModel.Create(ARoot: TObject);
begin
  inherited Create;
  FRoot := ARoot;
  FNodes := TObjectList<TDemoPropNode>.Create(True);
  AddChildren(nil, ARoot, FNodes, 0);
end;

destructor TDemoPropModel.Destroy;
begin
  FNodes.Free;
  inherited Destroy;
end;

procedure TDemoPropModel.AddChildren(AParent: TDemoPropNode; AObj: TObject;
  List: TObjectList<TDemoPropNode>; Depth: Integer);
var
  Props: PPropList;
  Count, I, J: Integer;
  P: PPropInfo;
  N, It: TDemoPropNode;
  Sub: TObject;
begin
  if (AObj = nil) or (AObj.ClassInfo = nil) then
    Exit;
  Count := GetPropList(AObj.ClassInfo, tkAny, nil, False);
  if Count = 0 then
    Exit;
  GetMem(Props, Count * SizeOf(PPropInfo));
  try
    GetPropList(AObj.ClassInfo, tkAny, Props, False);
    for I := 0 to Count - 1 do
    begin
      P := Props^[I];
      if P^.GetProc = nil then
        Continue;
      N := TDemoPropNode.Create(Self, AParent, P);
      List.Add(N);
      if Depth >= 6 then
        Continue;
      if N.Kind = pkObject then
      begin
        Sub := GetObjectProp(AObj, P);
        if Sub <> nil then
          AddChildren(N, Sub, N.FChildren, Depth + 1);
      end
      else if N.Kind = pkCollection then
      begin
        // Je Eintrag ein Knoten mit den Eigenschaften des Eintrags
        Sub := GetObjectProp(AObj, P);
        if Sub is TCollection then
          for J := 0 to TCollection(Sub).Count - 1 do
          begin
            It := TDemoPropNode.CreateItem(Self, N, J, TCollection(Sub).Items[J].ClassName);
            N.FChildren.Add(It);
            AddChildren(It, TCollection(Sub).Items[J], It.FChildren, Depth + 1);
          end;
      end;
    end;
  finally
    FreeMem(Props);
  end;
end;

procedure TDemoPropModel.CollectAll(List: TObjectList<TDemoPropNode>; Target: TList<TDemoPropNode>);
var
  N: TDemoPropNode;
begin
  for N in List do
  begin
    Target.Add(N);
    CollectAll(N.Children, Target);
  end;
end;

procedure TDemoPropModel.GetAll(Target: TList<TDemoPropNode>);
begin
  CollectAll(FNodes, Target);
end;

function TDemoPropModel.Find(const APath: string): TDemoPropNode;
var
  All: TList<TDemoPropNode>;
  N: TDemoPropNode;
begin
  Result := nil;
  All := TList<TDemoPropNode>.Create;
  try
    GetAll(All);
    for N in All do
      if SameText(N.Path, APath) then
        Exit(N);
  finally
    All.Free;
  end;
end;

{ TDemoInspRow }

constructor TDemoInspRow.CreateRow(AInspector: TDemoInspector; AKind: TDemoRowKind;
  ANode: TDemoPropNode; const ACategory: string; AParentRow: TDemoInspRow);
var
  Lvl: Integer;
begin
  inherited Create(AInspector);
  FInspector := AInspector;
  FRowKind := AKind;
  FNode := ANode;
  FCategory := ACategory;
  FParentRow := AParentRow;
  FRowHeight := RowH;
  BevelOuter := bvNone;
  Caption := '';
  ParentBackground := True;
  ParentColor := True;
  ShowCaption := False;
  Parent := AInspector.FBox;
  OnClick := RowClick;
  Lvl := 0;
  if ANode <> nil then
    Lvl := ANode.Level + 1;
  if Expandable then
  begin
    FChevron := TPPGLabel.Create(Self);
    FChevron.Parent := Self;
    FChevron.Transparent := True;
    FChevron.Font.Name := PPGIconFontName;
    if FChevron.Font.Name = '' then
      FChevron.Font.Name := 'Segoe UI Symbol';
    FChevron.Font.Size := 8;
    FChevron.Caption := Char($E76C);
    FChevron.Left := 6 + Lvl * 14;
    FChevron.OnClick := RowClick;
  end;
  FCaptionLbl := TPPGLabel.Create(Self);
  FCaptionLbl.Parent := Self;
  FCaptionLbl.Transparent := True;
  FCaptionLbl.ShowAccelChar := False;
  FCaptionLbl.AutoSize := False;
  FCaptionLbl.Layout := tlCenter;
  FCaptionLbl.EllipsisPosition := epEndEllipsis;
  FCaptionLbl.OnClick := RowClick;
  if AKind = rkCategory then
  begin
    ApplyTextKind(FCaptionLbl.Font, tkStrong);
    FCaptionLbl.Caption := L(ACategory);
    FExpanded := ACategory <> 'Ereignisse';
  end
  else
  begin
    ApplyTextKind(FCaptionLbl.Font, tkBody);
    FCaptionLbl.Caption := ANode.Name;
    FCaptionLbl.Hint := ANode.Path + ': ' + ANode.TypeName;
    FCaptionLbl.ShowHint := True;
  end;
  FCaptionLbl.Left := 24 + Lvl * 14;
end;

function TDemoInspRow.Expandable: Boolean;
begin
  Result := (FRowKind = rkCategory) or ((FNode <> nil) and
    (FNode.Kind in [pkObject, pkCollection, pkItem]) and (FNode.Children.Count > 0));
end;

procedure TDemoInspRow.SetSelected(const Value: Boolean);
begin
  if FSelected = Value then
    Exit;
  FSelected := Value;
  if Value then
  begin
    ParentBackground := False;
    Color := FInspector.FSelectedColor;
  end
  else
  begin
    ParentColor := True;
    ParentBackground := True;
  end;
  Invalidate;
end;

procedure TDemoInspRow.RowClick(Sender: TObject);
begin
  if Expandable then
  begin
    FExpanded := not FExpanded;
    if FExpanded and (FRowKind = rkProp) then
      FInspector.BuildChildRows(Self);
    if FChevron <> nil then
      if FExpanded then
        FChevron.Caption := Char($E70D)
      else
        FChevron.Caption := Char($E76C);
    FInspector.Relayout;
  end;
  if FRowKind = rkProp then
    FInspector.SelectPath(FNode.Path);
end;

procedure TDemoInspRow.ResetClick(Sender: TObject);
begin
  FInspector.ResetNode(FNode);
end;

procedure TDemoInspRow.EditorEnter(Sender: TObject);
begin
  if FInspector.FSelectedRow <> Self then
    FInspector.SelectPath(FNode.Path);
end;

procedure TDemoInspRow.Resize;
begin
  inherited Resize;
  LayoutParts;
end;

procedure TDemoInspRow.LayoutParts;
var
  NameW, X, W, EH, X2: Integer;
begin
  if FCaptionLbl = nil then
    Exit;
  if FChevron <> nil then
  begin
    if FExpanded then
      FChevron.Caption := Char($E70D)
    else
      FChevron.Caption := Char($E76C);
    FChevron.Top := (RowH - FChevron.Height) div 2;
  end;
  if FRowKind = rkCategory then
  begin
    FCaptionLbl.SetBounds(FCaptionLbl.Left, 0, Max(10, Width - FCaptionLbl.Left - 4), RowH);
    Exit;
  end;
  NameW := Max(120, Width * 44 div 100);
  FCaptionLbl.SetBounds(FCaptionLbl.Left, 0, Max(10, NameW - FCaptionLbl.Left - 4), RowH);
  X := NameW;
  W := Width - X - 4;
  if FReset <> nil then
  begin
    FReset.SetBounds(Width - 28, 0, 26, RowH);
    W := W - 30;
  end;
  if FEditor is TPPGButton then
  begin
    // Liste bzw. Collection: Wert links, Knoepfe rechts
    X2 := X + W - FEditor.Width;
    if FEditor2 <> nil then
      Dec(X2, FEditor2.Width + 4);
    if FValueLbl <> nil then
      FValueLbl.SetBounds(X, 0, Max(10, X2 - X - 4), RowH);
    FEditor.SetBounds(X2, (RowH - 28) div 2, FEditor.Width, 28);
    if FEditor2 <> nil then
      FEditor2.SetBounds(X2 + FEditor.Width + 4, (RowH - 28) div 2, FEditor2.Width, 28);
    Exit;
  end;
  if FValueLbl <> nil then
    FValueLbl.SetBounds(X, 0, Max(10, W), RowH);
  if FEditor <> nil then
  begin
    EH := FEditor.Height;
    if FEditor is TPPGToggleSwitch then
      FEditor.SetBounds(X, (RowH - EH) div 2, Min(W, 60), EH)
    else if FEditor is TPPGCheckGroup then
      FEditor.SetBounds(X, 2, Max(10, W), EH)
    else
      FEditor.SetBounds(X, (RowH - EH) div 2, Max(10, W), EH);
  end;
end;

procedure TDemoInspRow.ReadValue;
var
  N: TDemoPropNode;
  Root: TObject;
  V: Int64;
  I, Idx: Integer;
  Changed: Boolean;
  Obj: TObject;
  Mask: Integer;
  TD: PTypeData;
begin
  if FRowKind <> rkProp then
    Exit;
  N := FNode;
  Root := FInspector.FModel.Root;
  Changed := FInspector.IsChanged(N);
  if Changed then
    FCaptionLbl.Font.Style := [fsBold]
  else
    FCaptionLbl.Font.Style := [];
  if FReset <> nil then
    FReset.Enabled := Changed;
  if FValueLbl <> nil then
  begin
    if N.Kind = pkEvent then
    begin
      if FEventCount > 0 then
        FValueLbl.Caption := Format('%s  <b>%d' + #$00D7 + '</b>', [N.TypeName, FEventCount])
      else
        FValueLbl.Caption := N.TypeName;
    end
    else if N.Kind = pkStrings then
    begin
      Obj := N.ValueIn(Root);
      if (Obj is TStrings) and (TStrings(Obj).Count > 0) then
        FValueLbl.Caption := MarkupEscape(Format(L('(%d Zeilen) %s'), [TStrings(Obj).Count,
          TStrings(Obj)[0]]))
      else
        FValueLbl.Caption := L('(leer)');
    end
    else if N.Kind = pkCollection then
    begin
      Obj := N.ValueIn(Root);
      if Obj is TCollection then
        FValueLbl.Caption := Format(L('%d Eintr{ae}ge'), [TCollection(Obj).Count])
      else
        FValueLbl.Caption := '';
    end
    else
      FValueLbl.Caption := MarkupEscape(N.Literal(Root));
  end;
  if FEditor = nil then
    Exit;
  if FInspector.FChangingRow = Self then
    Exit;
  Inc(FInspector.FUpdating);
  try
    case N.Kind of
      pkBoolean:
        TPPGToggleSwitch(FEditor).Checked := N.GetOrd(Root) <> 0;
      pkInteger, pkInt64:
        TPPGSpinEdit(FEditor).Value := Integer(Max(Low(Integer), Min(High(Integer), N.GetOrd(Root))));
      pkColor:
        TPPGColorPicker(FEditor).Selected := TColor(N.GetOrd(Root));
      pkString, pkFloat, pkChar:
        if FEditor is TPPGEdit then
        begin
          if N.Kind = pkString then
            TPPGEdit(FEditor).Text := N.GetStr(Root)
          else if N.Kind = pkChar then
            TPPGEdit(FEditor).Text := Char(N.GetOrd(Root))
          else
            TPPGEdit(FEditor).Text := N.Literal(Root);
        end
        else
          TPPGComboBox(FEditor).ItemIndex := TPPGComboBox(FEditor).Items.IndexOf(N.GetStr(Root));
      pkEnum, pkIdentInt:
        begin
          V := N.GetOrd(Root);
          Idx := -1;
          for I := 0 to TPPGComboBox(FEditor).Items.Count - 1 do
            if NativeInt(TPPGComboBox(FEditor).Items.Objects[I]) = V then
              Idx := I;
          if (Idx < 0) and (N.Kind = pkIdentInt) then
          begin
            TPPGComboBox(FEditor).Items.AddObject(N.Literal(Root), TObject(NativeInt(V)));
            Idx := TPPGComboBox(FEditor).Items.Count - 1;
          end;
          TPPGComboBox(FEditor).ItemIndex := Idx;
        end;
      pkComponent:
        begin
          Obj := N.GetObj(Root);
          Idx := TPPGComboBox(FEditor).Items.IndexOfObject(Obj);
          if (Idx < 0) and (Obj <> nil) then
          begin
            TPPGComboBox(FEditor).Items.AddObject(N.Literal(Root), Obj);
            Idx := TPPGComboBox(FEditor).Items.Count - 1;
          end;
          TPPGComboBox(FEditor).ItemIndex := Idx;
        end;
      pkSet:
        begin
          Mask := Integer(N.GetOrd(Root));
          TD := GetTypeData(GetTypeData(N.PropType)^.CompType^);
          for I := 0 to TPPGCheckGroup(FEditor).Items.Count - 1 do
            TPPGCheckGroup(FEditor).Checked[I] := (Mask and (1 shl (TD^.MinValue + I))) <> 0;
        end;
    end;
  finally
    Dec(FInspector.FUpdating);
  end;
end;

{ TDemoInspector }

constructor TDemoInspector.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  Caption := '';
  ShowCaption := False;
  ParentBackground := True;
  ParentColor := True;
  FRows := TList<TDemoInspRow>.Create;
  FCandidates := TList<TComponent>.Create;
  FSelectedColor := clHighlight;
  FFilter := TPPGEdit.Create(Self);
  FFilter.Parent := Self;
  FFilter.Align := alTop;
  FFilter.AlignWithMargins := True;
  FFilter.Margins.SetBounds(0, 0, 12, 8);
  FFilter.TextHint := L('Eigenschaft suchen {...}');
  FFilter.ShowClearButton := True;
  FFilter.OnChange := FilterChange;
  FBox := TPPGScrollBox.Create(Self);
  FBox.Parent := Self;
  FBox.Align := alClient;
  FBox.BorderStyle := bsNone;
  FBox.OnResize := BoxResize;
end;

destructor TDemoInspector.Destroy;
begin
  FreeAndNil(FModel);
  FreeAndNil(FRows);
  FreeAndNil(FCandidates);
  inherited Destroy;
end;

procedure TDemoInspector.SetSelectionColor(AColor: TColor);
begin
  FSelectedColor := AColor;
  if FSelectedRow <> nil then
  begin
    FSelectedRow.Selected := False;
    FSelectedRow.Selected := True;
  end;
end;

function TDemoInspector.CategoryOf(Node: TDemoPropNode): string;

  function InList(const N: string; const Names: array of string): Boolean;
  var
    I: Integer;
  begin
    Result := False;
    for I := 0 to High(Names) do
      if SameText(N, Names[I]) then
        Exit(True);
  end;

var
  N: string;
begin
  while Node.Parent <> nil do
    Node := Node.Parent;
  N := Node.Name;
  if Node.Kind = pkEvent then
    Result := 'Ereignisse'
  else if InList(N, ['Preset', 'StyleManager', 'Appearance', 'Animation', 'RoundedCorners',
    'Shadow', 'HighContrastSupport', 'ImageTint', 'Styles', 'ReadOnlyStyle']) then
    Result := 'PPGlow'
  else if InList(N, ['Items', 'ItemsEx', 'Lines', 'Panels', 'Tabs', 'Pages', 'Columns', 'Series']) and
    (Node.Kind in [pkStrings, pkCollection]) then
    Result := 'Inhalt'
  else if InList(N, ['DataSource', 'DataField', 'ListSource', 'ListField', 'KeyField', 'ReadOnlyField']) then
    Result := 'Daten'
  else if InList(N, ['Caption', 'Images', 'ImageIndex', 'ImageName', 'HotImageIndex',
    'DisabledImageIndex', 'PressedImageIndex', 'HotImageName', 'DisabledImageName',
    'PressedImageName', 'ImagePosition', 'Spacing', 'Alignment', 'Margin', 'WordWrap', 'Font',
    'ParentFont', 'Text', 'TextHint']) then
    Result := 'Beschriftung & Bild'
  else if InList(N, ['Action', 'Enabled', 'Visible', 'ModalResult', 'Default', 'Cancel', 'Style',
    'DropDownMenu', 'GroupIndex', 'AllowAllUp', 'Down', 'PopupMenu', 'ReadOnly', 'Checked']) then
    Result := 'Verhalten'
  else if InList(N, ['Align', 'AlignWithMargins', 'Anchors', 'AutoSize', 'Constraints', 'Left',
    'Top', 'Width', 'Height', 'Margins', 'Padding']) then
    Result := 'Layout'
  else if InList(N, ['TabOrder', 'TabStop', 'ShowFocusRect']) then
    Result := 'Tastatur & Fokus'
  else if InList(N, ['Hint', 'ShowHint', 'ParentShowHint', 'CustomHint', 'ParentCustomHint',
    'HelpType', 'HelpKeyword', 'HelpContext', 'Cursor']) then
    Result := 'Hinweise & Hilfe'
  else if InList(N, ['Color', 'ParentColor', 'ParentBackground', 'BiDiMode', 'ParentBiDiMode',
    'StyleElements', 'StyleName', 'DoubleBuffered', 'ParentDoubleBuffered']) then
    Result := 'Darstellung (VCL)'
  else if InList(N, ['DragCursor', 'DragKind', 'DragMode', 'Touch']) then
    Result := 'Ziehen & Touch'
  else
    Result := 'Sonstiges';
  if (Node.Kind <> pkEvent) and Assigned(FOnCategory) then
  begin
    FOnCategory(Self, N, Result);
    if not InList(Result, DemoCategories) then
      Result := 'Sonstiges';
  end;
end;

procedure TDemoInspector.Inspect(AComponent, AReference: TObject);
var
  I: Integer;
  Cat: TDemoInspRow;
  Sorted: TList<TDemoPropNode>;
  N: TDemoPropNode;
  Row: TDemoInspRow;
begin
  for I := FRows.Count - 1 downto 0 do
    FRows[I].Free;
  FRows.Clear;
  FSelectedRow := nil;
  FreeAndNil(FModel);
  FReference := AReference;
  FModel := TDemoPropModel.Create(AComponent);
  Sorted := TList<TDemoPropNode>.Create;
  try
    for N in FModel.Nodes do
      Sorted.Add(N);
    Sorted.Sort(TComparer<TDemoPropNode>.Construct(
      function(const A, B: TDemoPropNode): Integer
      begin
        Result := CompareText(A.Name, B.Name);
      end));
    for I := 0 to High(DemoCategories) do
    begin
      Cat := nil;
      for N in Sorted do
        if CategoryOf(N) = DemoCategories[I] then
        begin
          if Cat = nil then
          begin
            Cat := TDemoInspRow.CreateRow(Self, rkCategory, nil, DemoCategories[I], nil);
            FRows.Add(Cat);
          end;
          Row := TDemoInspRow.CreateRow(Self, rkProp, N, DemoCategories[I], Cat);
          FRows.Add(Row);
          CreateEditor(Row);
        end;
    end;
  finally
    Sorted.Free;
  end;
  RefreshValues;
  Relayout;
end;

procedure TDemoInspector.FillCombo(Row: TDemoInspRow; Combo: TPPGComboBox);
var
  N: TDemoPropNode;
  T: PTypeInfo;
  TD: PTypeData;
  I: Integer;
  S: string;
  C: TComponent;
  Names: TStringList;
begin
  N := Row.Node;
  Combo.Items.BeginUpdate;
  try
    Combo.Items.Clear;
    case N.Kind of
      pkEnum:
        begin
          T := N.PropType;
          TD := GetTypeData(T);
          for I := TD^.MinValue to TD^.MaxValue do
            Combo.Items.AddObject(GetEnumName(T, I), TObject(NativeInt(I)));
        end;
      pkIdentInt:
        if SameText(N.TypeName, 'TCursor') then
        begin
          for I := 0 downto -30 do
            if CursorToIdent(I, S) then
              Combo.Items.AddObject(S, TObject(NativeInt(I)));
        end
        else if SameText(N.TypeName, 'TModalResult') then
        begin
          for I := 0 to High(ModalNames) do
            Combo.Items.AddObject(ModalNames[I], TObject(NativeInt(ModalValue(I))));
        end
        else
        begin
          for I := 0 to 255 do
            if CharsetToIdent(I, S) then
              Combo.Items.AddObject(S, TObject(NativeInt(I)));
        end;
      pkComponent:
        begin
          Combo.Items.AddObject('nil', nil);
          T := N.PropType;
          for C in FCandidates do
            if (C <> nil) and C.InheritsFrom(GetTypeData(T)^.ClassType) then
              Combo.Items.AddObject(C.Name, C);
        end;
      pkString:
        begin
          Names := TStringList.Create;
          try
            if SameText(N.Name, 'Preset') then
              TPPGRendererRegistry.GetNames(Names)
            else
              Names.Assign(Screen.Fonts);
            Names.Sorted := True;
            Combo.Items.Assign(Names);
          finally
            Names.Free;
          end;
        end;
    end;
  finally
    Combo.Items.EndUpdate;
  end;
end;

procedure TDemoInspector.CreateEditor(Row: TDemoInspRow);
var
  N: TDemoPropNode;
  Combo: TPPGComboBox;
  Spin: TPPGSpinEdit;
  Group: TPPGCheckGroup;
  TD: PTypeData;
  I, Lo, Hi: Integer;
  Lbl: TPPGLabel;
  Ed: TPPGEdit;
  Sw: TPPGToggleSwitch;
  Picker: TPPGColorPicker;
  BaseT: PTypeInfo;
  IsFontName: Boolean;
  Btn, Btn2: TPPGButton;
begin
  N := Row.Node;
  if N.Kind in [pkStrings, pkCollection] then
  begin
    Lbl := TPPGLabel.Create(Row);
    Lbl.Parent := Row;
    Lbl.Transparent := True;
    Lbl.AutoSize := False;
    Lbl.Layout := tlCenter;
    Lbl.ShowAccelChar := False;
    Lbl.AllowMarkup := True;
    Lbl.Secondary := True;
    Lbl.EllipsisPosition := epEndEllipsis;
    Lbl.OnClick := Row.RowClick;
    ApplyTextKind(Lbl.Font, tkSecondary);
    Row.FValueLbl := Lbl;
    Btn := TPPGButton.Create(Row);
    Btn.Parent := Row;
    if N.Kind = pkStrings then
    begin
      Btn.Caption := L('Bearbeiten {...}');
      Btn.Width := 110;
      Btn.OnClick := StringsClick;
    end
    else
    begin
      Btn.Caption := '+';
      Btn.Width := 32;
      Btn.Hint := L('Eintrag hinzuf{ue}gen');
      Btn.ShowHint := True;
      Btn.OnClick := AddItemClick;
      Btn2 := TPPGButton.Create(Row);
      Btn2.Parent := Row;
      Btn2.Caption := #$2212;
      Btn2.Width := 32;
      Btn2.Hint := L('Letzten Eintrag entfernen');
      Btn2.ShowHint := True;
      Btn2.OnClick := RemoveItemClick;
      Row.FEditor2 := Btn2;
    end;
    Row.FEditor := Btn;
  end
  else if (N.Kind in [pkObject, pkEvent, pkOther, pkItem]) or N.ReadOnly then
  begin
    Lbl := TPPGLabel.Create(Row);
    Lbl.Parent := Row;
    Lbl.Transparent := True;
    Lbl.AutoSize := False;
    Lbl.Layout := tlCenter;
    Lbl.ShowAccelChar := False;
    Lbl.AllowMarkup := True;
    Lbl.Secondary := True;
    Lbl.EllipsisPosition := epEndEllipsis;
    Lbl.OnClick := Row.RowClick;
    ApplyTextKind(Lbl.Font, tkSecondary);
    Row.FValueLbl := Lbl;
    Row.LayoutParts;
    Exit;
  end;
  IsFontName := (N.Kind = pkString) and SameText(N.Name, 'Name') and (N.Parent <> nil) and
    SameText(N.Parent.TypeName, 'TFont');
  case N.Kind of
    pkBoolean:
      begin
        Sw := TPPGToggleSwitch.Create(Row);
        Sw.Parent := Row;
        Sw.Caption := '';
        Sw.OnChange := EditorChange;
        Row.FEditor := Sw;
      end;
    pkInteger, pkInt64:
      begin
        Spin := TPPGSpinEdit.Create(Row);
        Spin.Parent := Row;
        TD := GetTypeData(N.PropType);
        Lo := -100000;
        Hi := 100000;
        if N.Kind = pkInteger then
        begin
          Lo := Max(Lo, TD^.MinValue);
          Hi := Min(Hi, TD^.MaxValue);
          if (TD^.OrdType = otULong) or (Hi < Lo) then
          begin
            Lo := 0;
            Hi := 100000;
          end;
        end;
        Spin.Min := Lo;
        Spin.Max := Hi;
        Spin.OnChange := EditorChange;
        Row.FEditor := Spin;
      end;
    pkColor:
      begin
        Picker := TPPGColorPicker.Create(Row);
        Picker.Parent := Row;
        Picker.Style := [cbStandardColors, cbExtendedColors, cbSystemColors, cbIncludeNone,
          cbIncludeDefault, cbCustomColor, cbPrettyNames];
        Picker.OnChange := EditorChange;
        Row.FEditor := Picker;
      end;
    pkSet:
      begin
        Group := TPPGCheckGroup.Create(Row);
        Group.Parent := Row;
        Group.ShowFrame := False;
        Group.Caption := '';
        Group.Columns := 2;
        BaseT := GetTypeData(N.PropType)^.CompType^;
        TD := GetTypeData(BaseT);
        for I := TD^.MinValue to TD^.MaxValue do
          Group.Items.Add(GetEnumName(BaseT, I));
        Group.Height := ((Group.Items.Count + 1) div 2) * 28 + 8;
        Row.FRowHeight := Max(RowH, Group.Height + 4);
        Group.OnChange := EditorChange;
        Row.FEditor := Group;
      end;
    pkString, pkFloat, pkChar:
      if (N.Kind = pkString) and (SameText(N.Name, 'Preset') or IsFontName) then
      begin
        Combo := TPPGComboBox.Create(Row);
        Combo.Parent := Row;
        Combo.Style := csDropDownList;
        FillCombo(Row, Combo);
        Combo.OnSelect := ComboSelect;
        Row.FEditor := Combo;
      end
      else
      begin
        Ed := TPPGEdit.Create(Row);
        Ed.Parent := Row;
        if N.Kind = pkChar then
          Ed.MaxLength := 1;
        Ed.OnChange := EditorChange;
        Row.FEditor := Ed;
      end;
    pkEnum, pkIdentInt, pkComponent:
      begin
        Combo := TPPGComboBox.Create(Row);
        Combo.Parent := Row;
        Combo.Style := csDropDownList;
        FillCombo(Row, Combo);
        Combo.OnSelect := ComboSelect;
        Row.FEditor := Combo;
      end;
  end;
  if Row.FEditor is TWinControl then
    TWinControlAccess(Row.FEditor).OnEnter := Row.EditorEnter;
  Row.FReset := TPPGLabel.Create(Row);
  Row.FReset.Parent := Row;
  Row.FReset.Transparent := True;
  Row.FReset.AutoSize := False;
  Row.FReset.Alignment := taCenter;
  Row.FReset.Layout := tlCenter;
  Row.FReset.Font.Name := PPGIconFontName;
  if Row.FReset.Font.Name = '' then
    Row.FReset.Font.Name := 'Segoe UI Symbol';
  Row.FReset.Font.Size := 10;
  Row.FReset.Caption := Char($E7A7);
  Row.FReset.Cursor := crHandPoint;
  Row.FReset.Hint := L('Auf die Vorgabe zur{ue}cksetzen');
  Row.FReset.ShowHint := True;
  Row.FReset.OnClick := Row.ResetClick;
  Row.LayoutParts;
end;

function TDemoInspector.RowOfEditor(Sender: TObject): TDemoInspRow;
var
  C: TControl;
begin
  Result := nil;
  if not (Sender is TControl) then
    Exit;
  C := TControl(Sender);
  while (C <> nil) and not (C is TDemoInspRow) do
    C := C.Parent;
  Result := TDemoInspRow(C);
end;

procedure TDemoInspector.EditorChange(Sender: TObject);
var
  Row: TDemoInspRow;
begin
  if FUpdating > 0 then
    Exit;
  Row := RowOfEditor(Sender);
  if Row <> nil then
    ApplyEditor(Row);
end;

procedure TDemoInspector.ComboSelect(Sender: TObject);
begin
  EditorChange(Sender);
end;

procedure TDemoInspector.ApplyEditor(Row: TDemoInspRow);
var
  N: TDemoPropNode;
  Root: TObject;
  Combo: TPPGComboBox;
  I, Mask: Integer;
  TD: PTypeData;
  FS: TFormatSettings;
  F: Double;
begin
  N := Row.Node;
  Root := FModel.Root;
  FChangingRow := Row;
  try
    try
      case N.Kind of
        pkBoolean:
          N.SetOrd(Root, Ord(TPPGToggleSwitch(Row.Editor).Checked));
        pkInteger, pkInt64:
          N.SetOrd(Root, TPPGSpinEdit(Row.Editor).Value);
        pkColor:
          N.SetOrd(Root, TPPGColorPicker(Row.Editor).Selected);
        pkString:
          if Row.Editor is TPPGComboBox then
          begin
            Combo := TPPGComboBox(Row.Editor);
            if Combo.ItemIndex >= 0 then
              N.SetStr(Root, Combo.Items[Combo.ItemIndex]);
          end
          else
            N.SetStr(Root, TPPGEdit(Row.Editor).Text);
        pkChar:
          if TPPGEdit(Row.Editor).Text <> '' then
            N.SetOrd(Root, Ord(TPPGEdit(Row.Editor).Text[1]));
        pkFloat:
          begin
            FS := TFormatSettings.Create('en-US');
            if TryStrToFloat(TPPGEdit(Row.Editor).Text, F, FS) then
              SetFloatProp(N.OwnerIn(Root), N.Info, F);
          end;
        pkEnum, pkIdentInt:
          begin
            Combo := TPPGComboBox(Row.Editor);
            if Combo.ItemIndex >= 0 then
              N.SetOrd(Root, NativeInt(Combo.Items.Objects[Combo.ItemIndex]));
          end;
        pkComponent:
          begin
            Combo := TPPGComboBox(Row.Editor);
            if Combo.ItemIndex >= 0 then
              N.SetObj(Root, Combo.Items.Objects[Combo.ItemIndex]);
          end;
        pkSet:
          begin
            TD := GetTypeData(GetTypeData(N.PropType)^.CompType^);
            Mask := 0;
            for I := 0 to TPPGCheckGroup(Row.Editor).Items.Count - 1 do
              if TPPGCheckGroup(Row.Editor).Checked[I] then
                Mask := Mask or (1 shl (TD^.MinValue + I));
            N.SetOrd(Root, Mask);
          end;
      end;
    except
      // Grenze: Ungueltige Eingaben (z. B. EPPGPropertyError bei Margin = 5000)
      // sind hier gewollt: Der Inspektor zeigt die Meldung der Komponente und
      // liest den unveraenderten Wert zurueck.
      on E: Exception do
      begin
        FChangingRow := nil;
        RefreshValues;
        if Assigned(FOnError) then
          FOnError(Self, N, E.ClassName + ': ' + E.Message);
        Exit;
      end;
    end;
  finally
    FChangingRow := nil;
  end;
  // Das bearbeitete Feld nicht ueberschreiben (Cursor beim Tippen), die
  // anderen Zeilen koennen sich mitgeaendert haben (Preset, AutoSize ...)
  FChangingRow := Row;
  try
    RefreshValues;
  finally
    FChangingRow := nil;
  end;
  if FSelectedRow <> Row then
    SelectPath(N.Path);
  if Assigned(FOnChanged) then
    FOnChanged(Self, N);
end;

function TDemoInspector.SetValueText(const APath, AValue: string): Boolean;
var
  Row: TDemoInspRow;
  Combo: TPPGComboBox;
  I: Integer;
begin
  Result := False;
  Row := RowOf(APath);
  if (Row = nil) or (Row.Editor = nil) then
    Exit;
  if Row.Node.Kind = pkStrings then
  begin
    try
      Row.Node.SetStr(FModel.Root, AValue);
    except
      // Grenze: wie ApplyEditor, die Meldung der Komponente wird gezeigt
      on E: Exception do
      begin
        if Assigned(FOnError) then
          FOnError(Self, Row.Node, E.ClassName + ': ' + E.Message);
        Exit(True);
      end;
    end;
    RefreshValues;
    if Assigned(FOnChanged) then
      FOnChanged(Self, Row.Node);
    Exit(True);
  end;
  Inc(FUpdating);
  try
    if Row.Editor is TPPGToggleSwitch then
      TPPGToggleSwitch(Row.Editor).Checked := SameText(AValue, 'True')
    else if Row.Editor is TPPGSpinEdit then
      TPPGSpinEdit(Row.Editor).Value := StrToInt(AValue)
    else if Row.Editor is TPPGColorPicker then
      TPPGColorPicker(Row.Editor).Selected := StringToColor(AValue)
    else if Row.Editor is TPPGEdit then
      TPPGEdit(Row.Editor).Text := AValue
    else if Row.Editor is TPPGComboBox then
    begin
      Combo := TPPGComboBox(Row.Editor);
      Combo.ItemIndex := Combo.Items.IndexOf(AValue);
      if Combo.ItemIndex < 0 then
        Exit;
    end
    else if Row.Editor is TPPGCheckGroup then
      for I := 0 to TPPGCheckGroup(Row.Editor).Items.Count - 1 do
        TPPGCheckGroup(Row.Editor).Checked[I] :=
          Pos(',' + TPPGCheckGroup(Row.Editor).Items[I] + ',', ',' + StringReplace(AValue, ' ', '', [rfReplaceAll]) + ',') > 0;
  finally
    Dec(FUpdating);
  end;
  ApplyEditor(Row);
  Result := True;
end;

function TDemoInspector.IsChanged(Node: TDemoPropNode): Boolean;
begin
  Result := False;
  if (FReference = nil) or (Node.Kind in [pkEvent, pkOther]) then
    Exit;
  // Der Name unterscheidet sich immer (Vorgabe-Instanz ohne Namen)
  if (Node.Parent = nil) and SameText(Node.Name, 'Name') then
    Exit;
  Result := not Node.SameIn(FModel.Root, FReference);
end;

procedure TDemoInspector.ResetNode(Node: TDemoPropNode);
begin
  if (FReference = nil) or (Node = nil) then
    Exit;
  try
    Node.CopyValue(FReference, FModel.Root);
  except
    // Grenze: wie ApplyEditor, die Komponente meldet ungueltige Kombinationen
    on E: Exception do
      if Assigned(FOnError) then
        FOnError(Self, Node, E.ClassName + ': ' + E.Message);
  end;
  RefreshValues;
  if Assigned(FOnChanged) then
    FOnChanged(Self, Node);
end;

procedure TDemoInspector.RefreshValues;
var
  Row: TDemoInspRow;
begin
  if FModel = nil then
    Exit;
  for Row in FRows do
    Row.ReadValue;
end;

procedure TDemoInspector.BuildChildRows(Row: TDemoInspRow);
var
  Idx: Integer;
  Sorted: TList<TDemoPropNode>;
  N: TDemoPropNode;
  Child: TDemoInspRow;
begin
  if Row.FChildrenBuilt or (Row.Node = nil) then
    Exit;
  Row.FChildrenBuilt := True;
  Idx := FRows.IndexOf(Row) + 1;
  Sorted := TList<TDemoPropNode>.Create;
  try
    for N in Row.Node.Children do
      Sorted.Add(N);
    Sorted.Sort(TComparer<TDemoPropNode>.Construct(
      function(const A, B: TDemoPropNode): Integer
      begin
        Result := CompareText(A.Name, B.Name);
      end));
    for N in Sorted do
    begin
      Child := TDemoInspRow.CreateRow(Self, rkProp, N, Row.Category, Row);
      FRows.Insert(Idx, Child);
      Inc(Idx);
      CreateEditor(Child);
      Child.ReadValue;
      // Enkel direkt hinter dem Kind einsortieren, wenn es spaeter aufklappt
    end;
  finally
    Sorted.Free;
  end;
end;

procedure TDemoInspector.BuildAllRows;
var
  I: Integer;
begin
  I := 0;
  while I < FRows.Count do
  begin
    if (FRows[I].RowKind = rkProp) and FRows[I].Expandable then
      BuildChildRows(FRows[I]);
    Inc(I);
  end;
end;

function TDemoInspector.MatchesFilter(Row: TDemoInspRow): Boolean;
var
  F: string;
begin
  F := AnsiLowerCase(Trim(FFilter.Text));
  Result := (F = '') or ((Row.RowKind = rkProp) and (Pos(F, AnsiLowerCase(Row.Node.Path)) > 0));
end;

function TDemoInspector.RowShown(Row: TDemoInspRow): Boolean;
var
  I: Integer;
  P: TDemoInspRow;
begin
  if Trim(FFilter.Text) <> '' then
  begin
    // Treffer, deren Vorfahren und die Kategorien mit Treffern
    if MatchesFilter(Row) then
      Exit(True);
    for I := 0 to FRows.Count - 1 do
      if (FRows[I].RowKind = rkProp) and MatchesFilter(FRows[I]) then
      begin
        P := FRows[I].ParentRow;
        while P <> nil do
        begin
          if P = Row then
            Exit(True);
          P := P.ParentRow;
        end;
      end;
    Exit(False);
  end;
  Result := True;
  P := Row.ParentRow;
  while P <> nil do
  begin
    if not P.Expanded then
      Exit(False);
    P := P.ParentRow;
  end;
end;

procedure TDemoInspector.Relayout;
var
  Row: TDemoInspRow;
  Y, W, OffY: Integer;
  Shown: Boolean;
begin
  if (FBox = nil) or (FRows = nil) then
    Exit;
  W := Max(100, FBox.ClientWidth - 14);
  OffY := FBox.ScrollPos.Y;
  Y := 0;
  FBox.DisableAlign;
  try
    for Row in FRows do
    begin
      Shown := RowShown(Row);
      if Shown then
      begin
        Row.SetBounds(0, Y - OffY, W, Row.RowHeight);
        Inc(Y, Row.RowHeight);
      end;
      Row.Visible := Shown;
    end;
  finally
    FBox.EnableAlign;
  end;
end;

procedure TDemoInspector.BoxResize(Sender: TObject);
begin
  Relayout;
end;

procedure TDemoInspector.FilterChange(Sender: TObject);
begin
  if Trim(FFilter.Text) <> '' then
    BuildAllRows;
  FBox.ScrollTo(0, 0);
  Relayout;
end;

function TDemoInspector.RowOf(const APath: string): TDemoInspRow;
var
  Row: TDemoInspRow;
  N, P: TDemoPropNode;
  Chain: TList<TDemoPropNode>;
  I, J: Integer;
begin
  Result := nil;
  if FModel = nil then
    Exit;
  N := FModel.Find(APath);
  if N = nil then
    Exit;
  // Zeilen der Vorfahren (Unterobjekt, Collection, Eintrag) von aussen nach
  // innen aufbauen, damit die Zeile selbst existiert
  Chain := TList<TDemoPropNode>.Create;
  try
    P := N.Parent;
    while P <> nil do
    begin
      Chain.Insert(0, P);
      P := P.Parent;
    end;
    for I := 0 to Chain.Count - 1 do
      for J := 0 to FRows.Count - 1 do
        if (FRows[J].RowKind = rkProp) and (FRows[J].Node = Chain[I]) then
        begin
          BuildChildRows(FRows[J]);
          Break;
        end;
  finally
    Chain.Free;
  end;
  for Row in FRows do
    if (Row.RowKind = rkProp) and (Row.Node = N) then
      Exit(Row);
end;

function TDemoInspector.SelectPath(const APath: string): Boolean;
var
  Row, P: TDemoInspRow;
  Y, I: Integer;
begin
  Row := RowOf(APath);
  Result := Row <> nil;
  if not Result then
    Exit;
  // Kategorie und Eltern aufklappen
  P := Row.ParentRow;
  while P <> nil do
  begin
    if not P.FExpanded then
    begin
      P.FExpanded := True;
      P.LayoutParts;
    end;
    P := P.ParentRow;
  end;
  if FSelectedRow <> nil then
    FSelectedRow.Selected := False;
  FSelectedRow := Row;
  Row.Selected := True;
  Relayout;
  // Zeile ins Bild holen
  Y := 0;
  for I := 0 to FRows.Count - 1 do
  begin
    if FRows[I] = Row then
      Break;
    if FRows[I].Visible then
      Inc(Y, FRows[I].RowHeight);
  end;
  if (Y < FBox.ScrollPos.Y) or (Y + Row.RowHeight > FBox.ScrollPos.Y + FBox.ClientHeight) then
  begin
    FBox.ScrollTo(0, Max(0, Y - FBox.ClientHeight div 3));
    Relayout;
  end;
  if Assigned(FOnSelect) then
    FOnSelect(Self, Row.Node);
end;

function StringsDialog(const ATitle: string; var AText: string): Boolean;
var
  F: TForm;
  Memo: TPPGMemo;
  Bar: TPanel;
  Ok, Cancel: TPPGButton;
begin
  F := TForm.CreateNew(nil);
  try
    F.Caption := ATitle;
    F.Position := poMainFormCenter;
    F.BorderStyle := bsSizeToolWin;
    F.ClientWidth := 480;
    F.ClientHeight := 360;
    F.Font.Name := BodyFontName;
    F.Font.Size := 10;
    Bar := TPanel.Create(F);
    Bar.Parent := F;
    Bar.Align := alBottom;
    Bar.Height := 52;
    Bar.BevelOuter := bvNone;
    Bar.ParentBackground := True;
    Bar.ParentColor := True;
    Bar.Caption := '';
    Memo := TPPGMemo.Create(F);
    Memo.Parent := F;
    Memo.Align := alClient;
    Memo.AlignWithMargins := True;
    Memo.Margins.SetBounds(12, 12, 12, 0);
    Memo.ScrollBars := ssVertical;
    Memo.Lines.Text := AText;
    Ok := TPPGButton.Create(F);
    Ok.Parent := Bar;
    Ok.SetBounds(F.ClientWidth - 232, 10, 104, 32);
    Ok.Anchors := [akTop, akRight];
    Ok.Caption := 'OK';
    Ok.Default := True;
    Ok.ModalResult := mrOk;
    Cancel := TPPGButton.Create(F);
    Cancel.Parent := Bar;
    Cancel.SetBounds(F.ClientWidth - 116, 10, 104, 32);
    Cancel.Anchors := [akTop, akRight];
    Cancel.Caption := L('Abbrechen');
    Cancel.Cancel := True;
    Cancel.ModalResult := mrCancel;
    ApplyDemoStyles(F, nil);
    F.ActiveControl := Memo;
    Result := F.ShowModal = mrOk;
    if Result then
      AText := Memo.Lines.Text;
  finally
    F.Free;
  end;
end;

procedure TDemoInspector.StringsClick(Sender: TObject);
var
  Row: TDemoInspRow;
  S: string;
begin
  Row := RowOfEditor(Sender);
  if Row = nil then
    Exit;
  S := Row.Node.GetStr(FModel.Root);
  if StringsDialog(Row.Node.Path, S) then
    SetValueText(Row.Node.Path, S);
end;

procedure TDemoInspector.ChangeCollection(Node: TDemoPropNode; AAdd: Boolean);
var
  O: TObject;
begin
  O := Node.ValueIn(FModel.Root);
  if not (O is TCollection) then
    Exit;
  try
    if AAdd then
      TCollection(O).Add
    else if TCollection(O).Count > 0 then
      TCollection(O).Delete(TCollection(O).Count - 1);
  except
    // Grenze: die Komponente lehnt den Eintrag ab; Meldung zeigen
    on E: Exception do
      if Assigned(FOnError) then
        FOnError(Self, Node, E.ClassName + ': ' + E.Message);
  end;
end;

procedure TDemoInspector.AddItemClick(Sender: TObject);
var
  Row: TDemoInspRow;
begin
  Row := RowOfEditor(Sender);
  if Row = nil then
    Exit;
  ChangeCollection(Row.Node, True);
  // Die Zeile gehoert zum alten Modell: erst nach dem Klick neu aufbauen
  FRebuildPath := Row.Node.Path;
  PostMessage(Handle, WM_USER + 501, 0, 0);
end;

procedure TDemoInspector.RemoveItemClick(Sender: TObject);
var
  Row: TDemoInspRow;
begin
  Row := RowOfEditor(Sender);
  if Row = nil then
    Exit;
  ChangeCollection(Row.Node, False);
  FRebuildPath := Row.Node.Path;
  PostMessage(Handle, WM_USER + 501, 0, 0);
end;

procedure TDemoInspector.WMRebuild(var Msg: TMessage);
begin
  Rebuild(FRebuildPath);
end;

procedure TDemoInspector.Rebuild(const APath: string);
var
  Root, Ref: TObject;
  Row: TDemoInspRow;
begin
  if FModel = nil then
    Exit;
  Root := FModel.Root;
  Ref := FReference;
  Inspect(Root, Ref);
  ApplyDemoStyles(Self, nil);
  if APath = '' then
    Exit;
  if SelectPath(APath) then
  begin
    Row := RowOf(APath);
    if (Row <> nil) and Row.Expandable and not Row.Expanded then
      Row.RowClick(Row);
    if Assigned(FOnChanged) and (Row <> nil) then
      FOnChanged(Self, Row.Node);
  end;
end;

function TDemoInspector.AddCollectionItem(const APath: string): Boolean;
var
  N: TDemoPropNode;
begin
  N := FModel.Find(APath);
  Result := (N <> nil) and (N.Kind = pkCollection);
  if not Result then
    Exit;
  ChangeCollection(N, True);
  Rebuild(APath);
end;

function TDemoInspector.RemoveCollectionItem(const APath: string): Boolean;
var
  N: TDemoPropNode;
begin
  N := FModel.Find(APath);
  Result := (N <> nil) and (N.Kind = pkCollection);
  if not Result then
    Exit;
  ChangeCollection(N, False);
  Rebuild(APath);
end;

procedure TDemoInspector.EventFired(const AName: string);

var
  Row: TDemoInspRow;
begin
  for Row in FRows do
    if (Row.RowKind = rkProp) and (Row.Node.Parent = nil) and SameText(Row.Node.Name, AName) then
    begin
      Inc(Row.FEventCount);
      Row.ReadValue;
    end;
end;

end.
