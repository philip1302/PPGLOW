unit DemoCodeGen;

// Code zur Komponente im Inspektor: Pascal (nur die Eigenschaften, die von
// einer frisch erzeugten Komponente abweichen, in Streaming-Reihenfolge) und
// der DFM-Text, den die IDE fuer die Komponente speichern wuerde.

interface

uses
  System.SysUtils, System.Classes, DemoInspector;

/// Pascal-Code, der AModel.Root so erzeugt. AReference ist eine frisch
/// erzeugte Instanz derselben Klasse (gleicher Parent-Typ); sie wird fuer den
/// Vergleich kurz auf Preset und StyleManager des Ziels gestellt und danach
/// zurueckgesetzt, damit nur echte Abweichungen von der Optik-Vorlage
/// erscheinen.
function PascalCode(AModel: TDemoPropModel; AReference: TObject;
  const AVarName, AParentName: string): string;

/// DFM-Text der Komponente (Ereignisse ausgenommen: deren Handler gehoeren
/// der Demo, nicht einem Formular).
function DfmText(AComponent: TComponent): string;

implementation

uses
  System.TypInfo, System.Generics.Collections;

function IsBoundsName(const N: string): Boolean;
begin
  Result := SameText(N, 'Left') or SameText(N, 'Top') or SameText(N, 'Width') or SameText(N, 'Height');
end;

function PascalCode(AModel: TDemoPropModel; AReference: TObject;
  const AVarName, AParentName: string): string;
var
  Lines: TStringList;
  All: TList<TDemoPropNode>;
  N, PresetNode, ManagerNode: TDemoPropNode;
  Root: TObject;
  OldPreset: string;
  OldManager: TObject;
  BoundsDiffer: Boolean;
  L, T, W, H: TDemoPropNode;
begin
  Root := AModel.Root;
  Lines := TStringList.Create;
  All := TList<TDemoPropNode>.Create;
  try
    AModel.GetAll(All);
    Lines.Add(Format('%s := %s.Create(Self);', [AVarName, Root.ClassName]));
    Lines.Add(Format('%s.Parent := %s;', [AVarName, AParentName]));
    if AReference = nil then
    begin
      Result := Lines.Text;
      Exit;
    end;
    PresetNode := AModel.Find('Preset');
    ManagerNode := AModel.Find('StyleManager');
    OldPreset := '';
    OldManager := nil;
    if PresetNode <> nil then
      OldPreset := PresetNode.GetStr(AReference);
    if ManagerNode <> nil then
      OldManager := ManagerNode.GetObj(AReference);
    try
      // Optik-Vorlage zuerst ausgeben und in der Vorgabe angleichen:
      // Appearance-Werte des Presets sind keine eigenen Aenderungen
      if (PresetNode <> nil) and not PresetNode.SameIn(Root, AReference) then
      begin
        Lines.Add(Format('%s.Preset := %s;', [AVarName, PresetNode.Literal(Root)]));
        PresetNode.SetStr(AReference, PresetNode.GetStr(Root));
      end;
      if (ManagerNode <> nil) and not ManagerNode.SameIn(Root, AReference) then
      begin
        Lines.Add(Format('%s.StyleManager := %s;', [AVarName, ManagerNode.Literal(Root)]));
        ManagerNode.SetObj(AReference, ManagerNode.GetObj(Root));
      end;
      L := AModel.Find('Left');
      T := AModel.Find('Top');
      W := AModel.Find('Width');
      H := AModel.Find('Height');
      BoundsDiffer := (L <> nil) and (T <> nil) and (W <> nil) and (H <> nil) and
        not (L.SameIn(Root, AReference) and T.SameIn(Root, AReference) and
        W.SameIn(Root, AReference) and H.SameIn(Root, AReference));
      if BoundsDiffer then
        Lines.Add(Format('%s.SetBounds(%s, %s, %s, %s);', [AVarName, L.Literal(Root),
          T.Literal(Root), W.Literal(Root), H.Literal(Root)]));
      for N in All do
      begin
        if N.Kind in [pkObject, pkEvent, pkOther] then
          Continue;
        if N.ReadOnly then
          Continue;
        if (N = PresetNode) or (N = ManagerNode) then
          Continue;
        if (N.Parent = nil) and (SameText(N.Name, 'Name') or IsBoundsName(N.Name)) then
          Continue;
        // Font.Height folgt aus Font.Size (beide abweichend waere doppelt)
        if (N.Parent <> nil) and SameText(N.Name, 'Height') and SameText(N.Parent.TypeName, 'TFont') then
          Continue;
        if N.SameIn(Root, AReference) then
          Continue;
        Lines.Add(Format('%s.%s := %s;', [AVarName, N.Path, N.Literal(Root)]));
      end;
    finally
      // Erst den Manager, dann das Preset: ein Manager setzt sein Preset mit
      if ManagerNode <> nil then
        ManagerNode.SetObj(AReference, OldManager);
      if PresetNode <> nil then
        PresetNode.SetStr(AReference, OldPreset);
    end;
    Lines.Add('');
    Lines.Add('// Ereignisse: im Objektinspektor doppelklicken bzw. im Code zuweisen,');
    Lines.Add(Format('// z. B. %s.OnClick := %sClick;', [AVarName, AVarName]));
    Result := Lines.Text;
  finally
    All.Free;
    Lines.Free;
  end;
end;

type
  TSavedEvent = record
    Info: PPropInfo;
    Method: TMethod;
  end;

function DfmText(AComponent: TComponent): string;
var
  Props: PPropList;
  Count, I: Integer;
  Saved: TList<TSavedEvent>;
  E: TSavedEvent;
  Empty: TMethod;
  Bin, Txt: TMemoryStream;
  Writer: TWriter;
  Lines: TStringList;
begin
  Result := '';
  Saved := TList<TSavedEvent>.Create;
  Bin := TMemoryStream.Create;
  Txt := TMemoryStream.Create;
  Lines := TStringList.Create;
  try
    Count := GetPropList(AComponent.ClassInfo, [tkMethod], nil, False);
    GetMem(Props, Count * SizeOf(PPropInfo) + 1);
    try
      GetPropList(AComponent.ClassInfo, [tkMethod], Props, False);
      Empty.Code := nil;
      Empty.Data := nil;
      for I := 0 to Count - 1 do
      begin
        E.Info := Props^[I];
        E.Method := GetMethodProp(AComponent, E.Info);
        if E.Method.Code <> nil then
        begin
          Saved.Add(E);
          SetMethodProp(AComponent, E.Info, Empty);
        end;
      end;
    finally
      FreeMem(Props);
    end;
    try
      Writer := TWriter.Create(Bin, 4096);
      try
        // Verweise (Images, PopupMenu ...) wie in einer DFM ueber den Namen
        Writer.Root := AComponent.Owner;
        Writer.WriteSignature;
        Writer.WriteComponent(AComponent);
      finally
        Writer.Free;
      end;
    finally
      for E in Saved do
        SetMethodProp(AComponent, E.Info, E.Method);
    end;
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    Txt.Position := 0;
    Lines.LoadFromStream(Txt);
    Result := Lines.Text;
  finally
    Lines.Free;
    Txt.Free;
    Bin.Free;
    Saved.Free;
  end;
end;

end.
