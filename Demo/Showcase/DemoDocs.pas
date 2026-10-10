unit DemoDocs;

// Texte der Komponentenseiten: Wirkung, Nutzung und Praxis jeder Eigenschaft
// (Docs\Controls\props\*.txt), Notizen je Klasse (Docs\Controls\notes\*.md)
// und der Quelltext der Praxisbeispiele. Alles kommt als RCDATA aus
// ShowcaseData.res (erzeugt von Build\make-showcase.ps1), damit die Demo
// dieselben Texte zeigt wie die Hilfe und ohne Doku-Ordner laeuft.
//
// Aufloesung wie in Build\make-docs.ps1 (Find-DescriptionCore): Klasse.Name
// entlang der Klassenkette, dann VCL.Name (nur fuer Komponenten), dann Name.
// Wirkung (mit Nutzung) und Praxis werden getrennt gesucht; ein Eintrag
// "TPPGButton.Height ! ..." liefert nur die Praxis.

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TDemoPropDoc = record
    Text: string;
    Usage: string;
    Practice: string;
    /// Schluessel, von dem die Wirkung kommt ('' = keine Beschreibung).
    TextKey: string;
    PracticeKey: string;
  end;

  TDemoDocs = class
  private type
    TEntry = class
      Text: string;
      Usage: string;
      Practice: string;
    end;
  private
    FEntries: TObjectDictionary<string, TEntry>;
    FNotes: TDictionary<string, string>;
    procedure LoadProps(const S: string);
    procedure LoadNotes(const S: string);
    function Entry(const Key: string): TEntry;
  public
    constructor Create;
    destructor Destroy; override;
    /// Beschreibung der Eigenschaft APropName eines Objekts der Klasse AClass.
    function Describe(AClass: TClass; const APropName: string): TDemoPropDoc;
    /// Notiz der Klasse (Markdown) oder ''.
    function Note(const AClassName: string): string;
    /// Abschnitt "## AHeading" der Notiz ohne Ueberschrift, '' = fehlt.
    function NoteSection(const AClassName, AHeading: string): string;
    /// Text einer RCDATA-Ressource (UTF-8), '' = fehlt.
    class function ResourceText(const AName: string): string;
    /// Gezeigter Code eines Praxisbeispiels: alle Abschnitte zwischen
    /// // EXAMPLE-BEGIN und // EXAMPLE-END der Unit AUnitName.
    class function ExampleCode(const AUnitName: string): string;
  end;

/// Gemeinsame Instanz (beim ersten Zugriff geladen).
function Docs: TDemoDocs;

/// Text aus props/notes fuer ein TPPGLabel mit Markup: & < > maskiert,
/// `Code` fett, Listenpunkte als eigene Zeilen.
function DocToMarkup(const S: string): string;

implementation

uses
  Winapi.Windows;

var
  GDocs: TDemoDocs;

function Docs: TDemoDocs;
begin
  if GDocs = nil then
    GDocs := TDemoDocs.Create;
  Result := GDocs;
end;

function DocToMarkup(const S: string): string;
var
  I: Integer;
  InCode: Boolean;
  Lines: TStringList;
  T: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := S;
    Result := '';
    for I := 0 to Lines.Count - 1 do
    begin
      T := Trim(Lines[I]);
      if T = '' then
        Continue;
      if (Copy(T, 1, 2) = '- ') or (Copy(T, 1, 2) = '* ') then
        T := #$2022 + ' ' + Copy(T, 3, MaxInt);
      if Result <> '' then
        Result := Result + '<br>';
      Result := Result + T;
    end;
  finally
    Lines.Free;
  end;
  // Markup-Zeichen maskieren, <br> danach wiederherstellen
  Result := StringReplace(Result, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
  Result := StringReplace(Result, '&lt;br&gt;', '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, '**', '', [rfReplaceAll]);
  // `Code` fett
  InCode := False;
  I := Pos('`', Result);
  while I > 0 do
  begin
    if InCode then
      Result := Copy(Result, 1, I - 1) + '</b>' + Copy(Result, I + 1, MaxInt)
    else
      Result := Copy(Result, 1, I - 1) + '<b>' + Copy(Result, I + 1, MaxInt);
    InCode := not InCode;
    I := Pos('`', Result);
  end;
  if InCode then
    Result := Result + '</b>';
end;

{ TDemoDocs }

constructor TDemoDocs.Create;
begin
  inherited Create;
  FEntries := TObjectDictionary<string, TEntry>.Create([doOwnsValues]);
  FNotes := TDictionary<string, string>.Create;
  LoadProps(ResourceText('PROPS'));
  LoadNotes(ResourceText('NOTES'));
end;

destructor TDemoDocs.Destroy;
begin
  FNotes.Free;
  FEntries.Free;
  inherited Destroy;
end;

class function TDemoDocs.ResourceText(const AName: string): string;
var
  Stream: TResourceStream;
  Bytes: TBytes;
begin
  Result := '';
  if FindResource(HInstance, PChar(AName), RT_RCDATA) = 0 then
    Exit;
  Stream := TResourceStream.Create(HInstance, AName, RT_RCDATA);
  try
    SetLength(Bytes, Stream.Size);
    if Length(Bytes) > 0 then
      Stream.ReadBuffer(Bytes[0], Length(Bytes));
  finally
    Stream.Free;
  end;
  Result := TEncoding.UTF8.GetString(Bytes);
end;

class function TDemoDocs.ExampleCode(const AUnitName: string): string;
const
  BeginMark = '// EXAMPLE-BEGIN';
  EndMark = '// EXAMPLE-END';
var
  Src: TStringList;
  I: Integer;
  Inside: Boolean;
  Part: TStringList;
begin
  Result := '';
  Src := TStringList.Create;
  Part := TStringList.Create;
  try
    Src.Text := ResourceText('EX_' + UpperCase(AUnitName));
    Inside := False;
    for I := 0 to Src.Count - 1 do
    begin
      if Trim(Src[I]) = BeginMark then
      begin
        if Part.Count > 0 then
          Part.Add('');
        Inside := True;
        Continue;
      end;
      if Trim(Src[I]) = EndMark then
      begin
        Inside := False;
        Continue;
      end;
      if Inside then
        Part.Add(Src[I]);
    end;
    Result := Part.Text;
  finally
    Part.Free;
    Src.Free;
  end;
end;

function TDemoDocs.Entry(const Key: string): TEntry;
begin
  if not FEntries.TryGetValue(UpperCase(Key), Result) then
    Result := nil;
end;

procedure TDemoDocs.LoadProps(const S: string);
var
  Lines: TStringList;
  I, P: Integer;
  T, Key: string;
  Last: TEntry;

  function Ensure(const AKey: string): TEntry;
  begin
    Result := Entry(AKey);
    if Result = nil then
    begin
      Result := TEntry.Create;
      FEntries.Add(UpperCase(AKey), Result);
    end;
  end;

  procedure Append(var Target: string; const Value: string);
  begin
    if Target = '' then
      Target := Value
    else
      Target := Target + ' ' + Value;
  end;

  function IsPracticeKey(const Line: string; out AKey, AText: string): Boolean;
  var
    J: Integer;
  begin
    // "Klasse.Name ! Text": Schluessel nur aus Buchstaben, Ziffern, _ und .
    Result := False;
    J := 1;
    while (J <= Length(Line)) and CharInSet(Line[J], ['A'..'Z', 'a'..'z', '0'..'9', '_', '.']) do
      Inc(J);
    if J = 1 then
      Exit;
    AKey := Copy(Line, 1, J - 1);
    while (J <= Length(Line)) and (Line[J] = ' ') do
      Inc(J);
    if (J > Length(Line)) or (Line[J] <> '!') then
      Exit;
    AText := Trim(Copy(Line, J + 1, MaxInt));
    Result := True;
  end;

var
  PKey, PText: string;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := S;
    Last := nil;
    for I := 0 to Lines.Count - 1 do
    begin
      T := Trim(Lines[I]);
      if (T = '') or (T[1] = '#') then
        Continue;
      if T[1] = '>' then
      begin
        if Last <> nil then
          Append(Last.Usage, Trim(Copy(T, 2, MaxInt)));
        Continue;
      end;
      if T[1] = '!' then
      begin
        if Last <> nil then
          Append(Last.Practice, Trim(Copy(T, 2, MaxInt)));
        Continue;
      end;
      if IsPracticeKey(T, PKey, PText) then
      begin
        Last := Ensure(PKey);
        Last.Practice := PText;
        Continue;
      end;
      P := Pos('=', T);
      if P <= 1 then
        Continue;
      Key := Trim(Copy(T, 1, P - 1));
      Last := Ensure(Key);
      Last.Text := Trim(Copy(T, P + 1, MaxInt));
      Last.Usage := '';
    end;
  finally
    Lines.Free;
  end;
end;

procedure TDemoDocs.LoadNotes(const S: string);
var
  Lines: TStringList;
  I: Integer;
  Cls: string;
  Body: TStringList;

  procedure Flush;
  begin
    if Cls <> '' then
      FNotes.AddOrSetValue(UpperCase(Cls), Body.Text);
    Body.Clear;
  end;

begin
  Lines := TStringList.Create;
  Body := TStringList.Create;
  try
    Lines.Text := S;
    Cls := '';
    for I := 0 to Lines.Count - 1 do
      if Copy(Lines[I], 1, 3) = '@@ ' then
      begin
        Flush;
        Cls := Trim(Copy(Lines[I], 4, MaxInt));
      end
      else
        Body.Add(Lines[I]);
    Flush;
  finally
    Body.Free;
    Lines.Free;
  end;
end;

function TDemoDocs.Describe(AClass: TClass; const APropName: string): TDemoPropDoc;
var
  Keys: TStringList;
  C: TClass;
  I: Integer;
  E: TEntry;
begin
  Result.Text := '';
  Result.Usage := '';
  Result.Practice := '';
  Result.TextKey := '';
  Result.PracticeKey := '';
  Keys := TStringList.Create;
  try
    C := AClass;
    while C <> nil do
    begin
      Keys.Add(C.ClassName + '.' + APropName);
      C := C.ClassParent;
    end;
    if (AClass <> nil) and AClass.InheritsFrom(TComponent) then
      Keys.Add('VCL.' + APropName);
    Keys.Add(APropName);
    for I := 0 to Keys.Count - 1 do
    begin
      E := Entry(Keys[I]);
      if E = nil then
        Continue;
      if (Result.TextKey = '') and (E.Text <> '') then
      begin
        Result.Text := E.Text;
        Result.Usage := E.Usage;
        Result.TextKey := Keys[I];
      end;
      if (Result.PracticeKey = '') and (E.Practice <> '') then
      begin
        Result.Practice := E.Practice;
        Result.PracticeKey := Keys[I];
      end;
    end;
  finally
    Keys.Free;
  end;
end;

function TDemoDocs.Note(const AClassName: string): string;
begin
  if not FNotes.TryGetValue(UpperCase(AClassName), Result) then
    Result := '';
end;

function TDemoDocs.NoteSection(const AClassName, AHeading: string): string;
var
  Lines, Part: TStringList;
  I: Integer;
  Inside: Boolean;
begin
  Lines := TStringList.Create;
  Part := TStringList.Create;
  try
    Lines.Text := Note(AClassName);
    Inside := False;
    for I := 0 to Lines.Count - 1 do
      if Copy(Lines[I], 1, 3) = '## ' then
        Inside := SameText(Trim(Copy(Lines[I], 4, MaxInt)), AHeading)
      else if Inside then
        Part.Add(Lines[I]);
    Result := Trim(Part.Text);
  finally
    Part.Free;
    Lines.Free;
  end;
end;

initialization

finalization
  FreeAndNil(GDocs);

end.
