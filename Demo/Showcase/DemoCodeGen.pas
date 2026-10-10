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
  System.TypInfo, System.Generics.Collections, Vcl.Controls;

/// Knoten ist (oder liegt in) einer Liste bzw. Collection mit stored False,
/// also einer zweiten Sicht auf Daten, die eine andere Eigenschaft speichert.
function InUnstoredList(N: TDemoPropNode; Root: TObject): Boolean;
var
  P: TDemoPropNode;
  O: TObject;
begin
  Result := False;
  P := N;
  while P <> nil do
  begin
    if (P.Kind in [pkStrings, pkCollection]) and (P.Info <> nil) then
    begin
      O := P.OwnerIn(Root);
      if (O <> nil) and not IsStoredProp(O, P.Info) then
        Exit(True);
    end;
    P := P.Parent;
  end;
end;

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
  Padded: TList<TCollection>;
  PadCount: TList<Integer>;
  OrigCount: TDictionary<TDemoPropNode, Integer>;
  I, K: Integer;
  RC, SC: TObject;
begin
  Root := AModel.Root;
  Lines := TStringList.Create;
  All := TList<TDemoPropNode>.Create;
  Padded := TList<TCollection>.Create;
  PadCount := TList<Integer>.Create;
  OrigCount := TDictionary<TDemoPropNode, Integer>.Create;
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
      // Collections der Vorgabe auf die Zahl der Eintraege des Ziels bringen,
      // damit die Eintraege vergleichbar sind (danach wieder entfernt)
      for N in All do
        if N.Kind = pkCollection then
        begin
          RC := N.ValueIn(AReference);
          SC := N.ValueIn(Root);
          if (RC is TCollection) and (SC is TCollection) then
          begin
            OrigCount.AddOrSetValue(N, TCollection(RC).Count);
            K := 0;
            while TCollection(RC).Count < TCollection(SC).Count do
            begin
              TCollection(RC).Add;
              Inc(K);
            end;
            Padded.Add(TCollection(RC));
            PadCount.Add(K);
          end;
        end;
      L := AModel.Find('Left');
      T := AModel.Find('Top');
      W := AModel.Find('Width');
      H := AModel.Find('Height');
      // Ausgerichtete Controls (Align <> alNone): Lage kommt aus Align
      BoundsDiffer := (L <> nil) and (T <> nil) and (W <> nil) and (H <> nil) and
        not ((Root is TControl) and (TControl(Root).Align <> alNone)) and
        not (L.SameIn(Root, AReference) and T.SameIn(Root, AReference) and
        W.SameIn(Root, AReference) and H.SameIn(Root, AReference));
      if BoundsDiffer then
        Lines.Add(Format('%s.SetBounds(%s, %s, %s, %s);', [AVarName, L.Literal(Root),
          T.Literal(Root), W.Literal(Root), H.Literal(Root)]));
      for N in All do
      begin
        // Nicht gespeicherte Sicht (z. B. Items neben ItemsEx): wie die DFM auslassen
        if InUnstoredList(N, Root) then
          Continue;
        if N.Kind = pkCollection then
        begin
          SC := N.ValueIn(Root);
          if (SC is TCollection) and OrigCount.TryGetValue(N, K) and
            ((K > 0) or (TCollection(SC).Count > 0)) and
            ((K <> TCollection(SC).Count) or not N.SameIn(Root, AReference)) then
          begin
            if K > 0 then
              Lines.Add(Format('%s.%s.Clear;', [AVarName, N.Path]));
            for I := 0 to TCollection(SC).Count - 1 do
              Lines.Add(Format('%s.%s.Add;', [AVarName, N.Path]));
          end;
          Continue;
        end;
        if N.Kind = pkStrings then
        begin
          if not N.SameIn(Root, AReference) then
            Lines.Add(Format('%s.%s.Text := %s;', [AVarName, N.Path, N.Literal(Root)]));
          Continue;
        end;
        if N.Kind in [pkObject, pkEvent, pkOther, pkItem] then
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
      for I := Padded.Count - 1 downto 0 do
        for K := 1 to PadCount[I] do
          Padded[I].Delete(Padded[I].Count - 1);
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
    OrigCount.Free;
    PadCount.Free;
    Padded.Free;
    All.Free;
    Lines.Free;
  end;
end;

type
  TSavedEvent = record
    Obj: TObject;
    Info: PPropInfo;
    Method: TMethod;
  end;

// Ereignisse von AObj, seinen Unterobjekten und Collection-Eintraegen merken
// und leeren (ihre Handler gehoeren der Demo, nicht einem Formular)
procedure ClearEvents(AObj: TObject; Saved: TList<TSavedEvent>; Depth: Integer);
var
  Props: PPropList;
  Count, I, J: Integer;
  E: TSavedEvent;
  Empty: TMethod;
  Sub: TObject;
begin
  if (AObj = nil) or (AObj.ClassInfo = nil) or (Depth > 6) then
    Exit;
  Count := GetPropList(AObj.ClassInfo, tkAny, nil, False);
  if Count = 0 then
    Exit;
  GetMem(Props, Count * SizeOf(PPropInfo));
  try
    GetPropList(AObj.ClassInfo, tkAny, Props, False);
    Empty.Code := nil;
    Empty.Data := nil;
    for I := 0 to Count - 1 do
    begin
      if Props^[I]^.PropType^^.Kind = tkMethod then
      begin
        E.Obj := AObj;
        E.Info := Props^[I];
        E.Method := GetMethodProp(AObj, E.Info);
        if (E.Method.Code <> nil) and (E.Info^.SetProc <> nil) then
        begin
          Saved.Add(E);
          SetMethodProp(AObj, E.Info, Empty);
        end;
      end
      else if (Props^[I]^.PropType^^.Kind = tkClass) and (Props^[I]^.GetProc <> nil) then
      begin
        Sub := GetObjectProp(AObj, Props^[I]);
        if Sub is TCollection then
        begin
          for J := 0 to TCollection(Sub).Count - 1 do
            ClearEvents(TCollection(Sub).Items[J], Saved, Depth + 1);
        end
        else if (Sub is TPersistent) and not (Sub is TComponent) then
          ClearEvents(Sub, Saved, Depth + 1);
      end;
    end;
  finally
    FreeMem(Props);
  end;
end;

function DfmText(AComponent: TComponent): string;
var
  Saved: TList<TSavedEvent>;
  E: TSavedEvent;
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
    ClearEvents(AComponent, Saved, 0);
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
        SetMethodProp(E.Obj, E.Info, E.Method);
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
