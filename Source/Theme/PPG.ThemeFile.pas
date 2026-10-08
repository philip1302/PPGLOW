unit PPG.ThemeFile;

{ Theme-Dateien und Farbtexte (Anpassbarkeit).

  - PPGColorToText / PPGTextToColor: Farben als Text ("clRed", "#1E90FF",
    "$00FF8000", "clDefault"), z.B. fuer ChartPalette und Theme-Dateien.
  - PPGSaveObjectToIni / PPGLoadObjectFromIni: schreiben bzw. lesen alle
    veroeffentlichten Properties eines Objekts (rekursiv fuer Unterobjekte)
    als "Pfad=Wert" in einen INI-Abschnitt, in Deklarationsreihenfolge wie die
    DFM (GetPropList sortiert sonst alphabetisch, dann kaeme Preset erst nach
    Appearance und setzte sie zurueck). Komponenten-Referenzen, Ereignisse,
    Name und Tag werden ausgelassen. Unbekannte Schluessel werden beim Lesen
    ignoriert (neuere Dateien bleiben lesbar), ungueltige Werte werfen
    EPPGStreamError. }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.IniFiles, Vcl.Graphics;

/// "#RRGGBB" fuer feste Farben, sonst der VCL-Name (clRed, clBtnFace, clDefault).
function PPGColorToText(Color: TColor): string;
/// Liest "#RRGGBB", "#RGB", "$00BBGGRR", Dezimalzahl oder einen VCL-Farbnamen.
function PPGTryTextToColor(const S: string; out Color: TColor): Boolean;
/// Wie PPGTryTextToColor, wirft EPPGPropertyError bei ungueltigem Text.
function PPGTextToColor(const S: string): TColor;

procedure PPGSaveObjectToIni(Obj: TPersistent; Ini: TCustomIniFile;
  const Section, Prefix: string);
procedure PPGLoadObjectFromIni(Obj: TPersistent; Ini: TCustomIniFile;
  const Section, Prefix: string);

implementation

uses
  PPG.Lang,
  System.SysUtils, System.TypInfo, PPG.Consts, PPG.Exceptions;

function PPGColorToText(Color: TColor): string;
var
  RGB: Cardinal;
begin
  if (Cardinal(Color) and $FF000000) <> 0 then
  begin
    // Systemfarben (clBtnFace ...) und Sonderwerte (clNone, clDefault) als Name
    Result := ColorToString(Color);
    Exit;
  end;
  RGB := Cardinal(Color) and $00FFFFFF;
  Result := Format('#%.2x%.2x%.2x', [RGB and $FF, (RGB shr 8) and $FF, (RGB shr 16) and $FF]);
end;

function PPGTryTextToColor(const S: string; out Color: TColor): Boolean;
var
  T: string;
  V: Integer;
  R, G, B: Integer;
begin
  Result := False;
  Color := clNone;
  T := Trim(S);
  if T = '' then
    Exit;
  if T[1] = '#' then
  begin
    T := Copy(T, 2, MaxInt);
    if Length(T) = 3 then
      T := T[1] + T[1] + T[2] + T[2] + T[3] + T[3];
    if (Length(T) <> 6) or not TryStrToInt('$' + T, V) then
      Exit;
    R := (V shr 16) and $FF;
    G := (V shr 8) and $FF;
    B := V and $FF;
    Color := TColor(R or (G shl 8) or (B shl 16));
    Exit(True);
  end;
  if IdentToColor(T, V) then
  begin
    Color := TColor(V);
    Exit(True);
  end;
  // Kurzformen ohne "cl" (Red, Navy ...)
  if IdentToColor('cl' + T, V) then
  begin
    Color := TColor(V);
    Exit(True);
  end;
  if TryStrToInt(T, V) then
  begin
    Color := TColor(V);
    Exit(True);
  end;
end;

function PPGTextToColor(const S: string): TColor;
begin
  if not PPGTryTextToColor(S, Result) then
    raise EPPGPropertyError.CreateFmt(PPGStr(@SPPGColorInvalid), [S]);
end;

{ ---- RTTI ---- }

function IsColorProp(P: PPropInfo): Boolean;
begin
  Result := SameText(string(P^.PropType^.Name), 'TColor');
end;

function SkipProp(P: PPropInfo): Boolean;
var
  N: string;
begin
  N := string(P^.Name);
  Result := SameText(N, 'Name') or SameText(N, 'Tag') or (P^.SetProc = nil) and
    (P^.PropType^.Kind <> tkClass);
end;

procedure PPGSaveObjectToIni(Obj: TPersistent; Ini: TCustomIniFile;
  const Section, Prefix: string);
var
  Props: PPropList;
  Count, I: Integer;
  P: PPropInfo;
  Key: string;
  Sub: TObject;
begin
  if Obj = nil then
    Exit;
  Count := GetPropList(Obj.ClassInfo, tkProperties, nil, False);
  if Count = 0 then
    Exit;
  GetMem(Props, Count * SizeOf(PPropInfo));
  try
    GetPropList(Obj.ClassInfo, tkProperties, Props, False);
    for I := 0 to Count - 1 do
    begin
      P := Props^[I];
      if SkipProp(P) then
        Continue;
      Key := Prefix + string(P^.Name);
      case P^.PropType^.Kind of
        tkInteger:
          if IsColorProp(P) then
            Ini.WriteString(Section, Key, PPGColorToText(TColor(GetOrdProp(Obj, P))))
          else
            Ini.WriteInteger(Section, Key, GetOrdProp(Obj, P));
        tkEnumeration:
          Ini.WriteString(Section, Key, GetEnumProp(Obj, P));
        tkSet:
          Ini.WriteString(Section, Key, GetSetProp(Obj, P, True));
        tkString, tkLString, tkWString, tkUString:
          Ini.WriteString(Section, Key, GetStrProp(Obj, P));
        tkFloat:
          Ini.WriteString(Section, Key, FloatToStr(GetFloatProp(Obj, P),
            TFormatSettings.Create('en-US')));
        tkClass:
          begin
            Sub := GetObjectProp(Obj, P);
            if Sub is TStrings then
              Ini.WriteString(Section, Key, TStrings(Sub).CommaText)
            else if (Sub is TPersistent) and not (Sub is TComponent) and
              not (Sub is TCollection) then
              PPGSaveObjectToIni(TPersistent(Sub), Ini, Section, Key + '.');
          end;
      end;
    end;
  finally
    FreeMem(Props);
  end;
end;

procedure PPGLoadObjectFromIni(Obj: TPersistent; Ini: TCustomIniFile;
  const Section, Prefix: string);
var
  Props: PPropList;
  Count, I: Integer;
  P: PPropInfo;
  Key, V: string;
  Sub: TObject;
  C: TColor;
  F: Double;
begin
  if Obj = nil then
    Exit;
  Count := GetPropList(Obj.ClassInfo, tkProperties, nil, False);
  if Count = 0 then
    Exit;
  GetMem(Props, Count * SizeOf(PPropInfo));
  try
    GetPropList(Obj.ClassInfo, tkProperties, Props, False);
    for I := 0 to Count - 1 do
    begin
      P := Props^[I];
      if SkipProp(P) then
        Continue;
      Key := Prefix + string(P^.Name);
      if P^.PropType^.Kind = tkClass then
      begin
        Sub := GetObjectProp(Obj, P);
        if Sub is TStrings then
        begin
          if Ini.ValueExists(Section, Key) then
            TStrings(Sub).CommaText := Ini.ReadString(Section, Key, '');
        end
        else if (Sub is TPersistent) and not (Sub is TComponent) and
          not (Sub is TCollection) then
          PPGLoadObjectFromIni(TPersistent(Sub), Ini, Section, Key + '.');
        Continue;
      end;
      if not Ini.ValueExists(Section, Key) then
        Continue;
      V := Ini.ReadString(Section, Key, '');
      try
        case P^.PropType^.Kind of
          tkInteger:
            if IsColorProp(P) then
            begin
              if not PPGTryTextToColor(V, C) then
                raise EPPGStreamError.CreateFmt(PPGStr(@SPPGThemeValueInvalid), [V, Key]);
              SetOrdProp(Obj, P, Integer(C));
            end
            else
              SetOrdProp(Obj, P, StrToInt(V));
          tkEnumeration:
            SetEnumProp(Obj, P, V);
          tkSet:
            SetSetProp(Obj, P, V);
          tkString, tkLString, tkWString, tkUString:
            SetStrProp(Obj, P, V);
          tkFloat:
            begin
              F := StrToFloat(V, TFormatSettings.Create('en-US'));
              SetFloatProp(Obj, P, F);
            end;
        end;
      except
        on E: EPPGError do
          raise;
        on E: EConvertError do
          raise EPPGStreamError.CreateFmt(PPGStr(@SPPGThemeValueInvalid), [V, Key]);
        on E: EPropertyConvertError do
          raise EPPGStreamError.CreateFmt(PPGStr(@SPPGThemeValueInvalid), [V, Key]);
      end;
    end;
  finally
    FreeMem(Props);
  end;
end;

end.
