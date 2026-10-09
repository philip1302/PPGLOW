unit PPG.DB.Validator;

{ Regeln aus dem Datenfeld fuer TPPGValidator (Phase 19b).

  Meldet beim Start eine Quelle fuer Feldregeln an (PPGSetFieldRuleProvider):
  Jedes Control mit einer oeffentlichen Property "Field: TField" gilt als
  datensensitiv - die PPGlow-DB-Controls ebenso wie TDBEdit und Co. der VCL.
  Abgeleitet werden:
  - Required (ohne DefaultExpression) -> Pflicht
  - Size bei Textfeldern -> Hoechstlaenge
  - MinValue/MaxValue bei Zahlfeldern -> Bereich (wie die VCL nur, wenn
    nicht beide 0 sind; TFMTBCDField: leer = keine Grenze)
  Geprueft wird nur, solange die Datenmenge bearbeitet wird (dsEdit,
  dsInsert). Schreibgeschuetzte Felder und Controls, berechnete Felder und
  AutoInc zaehlen nicht. Die Meldung nennt DisplayLabel.

  Die DB-Units binden diese Unit ein; wer nur VCL-DB-Controls verwendet,
  nimmt PPG.DB.Validator selbst in die uses-Liste. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, Vcl.Controls, Data.DB, PPG.Validator;

/// Datenfeld eines datensensitiven Controls (Property Field), nil = keins
/// bzw. nicht verbunden.
function PPGControlField(AControl: TControl): TField;
/// True, wenn das Control eine Property "Field: TField" hat.
function PPGIsDataAwareControl(AControl: TControl): Boolean;

implementation

uses
  System.SysUtils, System.Rtti, System.TypInfo, System.Generics.Collections;

var
  GContext: TRttiContext;
  // Klasse -> Property Field (nil = keine), damit RTTI nur einmal je Klasse laeuft
  GFieldProps: TDictionary<TClass, TRttiProperty>;

function FieldProperty(AControl: TControl): TRttiProperty;
var
  T: TRttiType;
  P: TRttiProperty;
begin
  if GFieldProps.TryGetValue(AControl.ClassType, Result) then
    Exit;
  Result := nil;
  T := GContext.GetType(AControl.ClassType);
  if T <> nil then
  begin
    P := T.GetProperty('Field');
    if (P <> nil) and P.IsReadable and (P.PropertyType is TRttiInstanceType) and
      TRttiInstanceType(P.PropertyType).MetaclassType.InheritsFrom(TField) then
      Result := P;
  end;
  GFieldProps.Add(AControl.ClassType, Result);
end;

function PPGIsDataAwareControl(AControl: TControl): Boolean;
begin
  Result := (AControl <> nil) and (FieldProperty(AControl) <> nil);
end;

function PPGControlField(AControl: TControl): TField;
var
  P: TRttiProperty;
  V: TValue;
begin
  Result := nil;
  if AControl = nil then
    Exit;
  P := FieldProperty(AControl);
  if P = nil then
    Exit;
  V := P.GetValue(AControl);
  if V.IsObject and (V.AsObject is TField) then
    Result := TField(V.AsObject);
end;

function ControlReadOnly(AControl: TControl): Boolean;
var
  Info: PPropInfo;
begin
  Info := GetPropInfo(AControl, 'ReadOnly');
  Result := (Info <> nil) and (Info^.PropType^.Kind = tkEnumeration) and
    (GetOrdProp(AControl, Info) <> 0);
end;

function FieldRules(AControl: TControl; out Info: TPPGFieldRuleInfo): Boolean;
var
  F: TField;
  S: string;
begin
  Info := Default(TPPGFieldRuleInfo);
  Result := PPGIsDataAwareControl(AControl);
  if not Result then
    Exit;
  F := PPGControlField(AControl);
  if (F = nil) or (F.DataSet = nil) then
    Exit;
  if F.ReadOnly or (F.FieldKind <> fkData) or (F.DataType = ftAutoInc) or
    ControlReadOnly(AControl) then
    Exit;
  Info.Editing := F.DataSet.State in dsEditModes;
  Info.Required := F.Required and (F.DefaultExpression = '');
  Info.Caption := F.DisplayLabel;
  if F is TStringField then
    Info.MaxLength := F.Size;
  if F is TIntegerField then
  begin
    if (TIntegerField(F).MinValue <> 0) or (TIntegerField(F).MaxValue <> 0) then
    begin
      Info.HasMin := True;
      Info.HasMax := True;
      Info.MinValue := TIntegerField(F).MinValue;
      Info.MaxValue := TIntegerField(F).MaxValue;
    end;
  end
  else if F is TLargeintField then
  begin
    if (TLargeintField(F).MinValue <> 0) or (TLargeintField(F).MaxValue <> 0) then
    begin
      Info.HasMin := True;
      Info.HasMax := True;
      Info.MinValue := TLargeintField(F).MinValue;
      Info.MaxValue := TLargeintField(F).MaxValue;
    end;
  end
  else if F is TFloatField then
  begin
    if (TFloatField(F).MinValue <> 0) or (TFloatField(F).MaxValue <> 0) then
    begin
      Info.HasMin := True;
      Info.HasMax := True;
      Info.MinValue := TFloatField(F).MinValue;
      Info.MaxValue := TFloatField(F).MaxValue;
    end;
  end
  else if F is TBCDField then
  begin
    if (TBCDField(F).MinValue <> 0) or (TBCDField(F).MaxValue <> 0) then
    begin
      Info.HasMin := True;
      Info.HasMax := True;
      Info.MinValue := TBCDField(F).MinValue;
      Info.MaxValue := TBCDField(F).MaxValue;
    end;
  end
  else if F is TFMTBCDField then
  begin
    S := TFMTBCDField(F).MinValue;
    Info.HasMin := (S <> '') and TryStrToFloat(S, Info.MinValue);
    S := TFMTBCDField(F).MaxValue;
    Info.HasMax := (S <> '') and TryStrToFloat(S, Info.MaxValue);
  end;
end;

initialization
  GContext := TRttiContext.Create;
  GFieldProps := TDictionary<TClass, TRttiProperty>.Create;
  PPGSetFieldRuleProvider(FieldRules);

finalization
  PPGSetFieldRuleProvider(nil);
  FreeAndNil(GFieldProps);
  GContext.Free;

end.
