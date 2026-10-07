unit PPG.Lang;

{ Uebersetzung der PPGlow-Texte zur Laufzeit (Phase 9d).

  Alle sichtbaren Texte der Suite sind resourcestrings (PPG.Consts). Sie
  werden ueber PPGStr(@SPPGxxx) gelesen: Ist eine Sprache aktiv und gibt es
  eine Uebersetzung, kommt diese, sonst der Originaltext (Englisch).

  Sprachen sind Units, die ihre Tabelle beim Start registrieren (z.B.
  PPG.Lang.De, erzeugt von Build\make-lang.ps1 aus Lang\PPGlow.de.txt).
  Anwendung:

    uses PPG.Lang, PPG.Lang.De;
    PPGSetLanguage('de');      // oder PPGSetLanguage(PPGSystemLanguage)

  Das funktioniert in jeder Edition (kein Uebersetzungs-Manager und keine
  Ressourcen-DLL noetig) und laesst sich zur Laufzeit umschalten. Offene
  Fenster zeichnen sich nach dem Umschalten neu. Wochentage und Monatsnamen
  kommen weiter aus FormatSettings. }

{$I ..\PPG.inc}

interface

uses
  System.SysUtils, System.Classes;

/// Text einer resourcestring in der aktiven Sprache.
function PPGStr(Res: PResStringRec): string;
/// Uebersetzung eintragen (aus der initialization einer Sprach-Unit).
procedure PPGAddTranslation(const Lang: string; Res: PResStringRec; const Text: string);
/// Aktive Sprache ('' oder 'en' = Original). Unbekannte Sprachen: Original.
procedure PPGSetLanguage(const Lang: string);
function PPGLanguage: string;
/// Uebersetzung in einer bestimmten Sprache, '' = keine.
function PPGTranslation(const Lang: string; Res: PResStringRec): string;
/// Anzahl der Uebersetzungen einer Sprache.
function PPGTranslationCount(const Lang: string): Integer;
/// Zweibuchstabiger Code der Windows-Anzeigesprache (z.B. 'de').
function PPGSystemLanguage: string;

var
  /// Nach jedem Sprachwechsel (z.B. eigene Beschriftungen neu setzen).
  PPGOnLanguageChange: TNotifyEvent = nil;

implementation

uses
  Winapi.Windows, System.Generics.Collections, Vcl.Forms, Vcl.Controls;

type
  TPPGTable = TDictionary<Pointer, string>;

var
  GTables: TObjectDictionary<string, TPPGTable> = nil;
  GActive: TPPGTable = nil;
  GLanguage: string = '';

function Tables: TObjectDictionary<string, TPPGTable>;
begin
  if GTables = nil then
    GTables := TObjectDictionary<string, TPPGTable>.Create([doOwnsValues]);
  Result := GTables;
end;

function PPGStr(Res: PResStringRec): string;
begin
  if (GActive <> nil) and GActive.TryGetValue(Res, Result) then
    Exit;
  Result := LoadResString(Res);
end;

procedure PPGAddTranslation(const Lang: string; Res: PResStringRec; const Text: string);
var
  T: TPPGTable;
  Key: string;
begin
  Key := LowerCase(Lang);
  if not Tables.TryGetValue(Key, T) then
  begin
    T := TPPGTable.Create;
    Tables.Add(Key, T);
    if SameText(Key, GLanguage) then
      GActive := T;
  end;
  T.AddOrSetValue(Res, Text);
end;

function PPGTranslation(const Lang: string; Res: PResStringRec): string;
var
  T: TPPGTable;
begin
  if (GTables = nil) or not GTables.TryGetValue(LowerCase(Lang), T) or
    not T.TryGetValue(Res, Result) then
    Result := '';
end;

function PPGTranslationCount(const Lang: string): Integer;
var
  T: TPPGTable;
begin
  if (GTables <> nil) and GTables.TryGetValue(LowerCase(Lang), T) then
    Result := T.Count
  else
    Result := 0;
end;

function PPGLanguage: string;
begin
  Result := GLanguage;
end;

procedure InvalidateAll(C: TWinControl);
var
  I: Integer;
begin
  C.Invalidate;
  for I := 0 to C.ControlCount - 1 do
    if C.Controls[I] is TWinControl then
      InvalidateAll(TWinControl(C.Controls[I]))
    else
      C.Controls[I].Invalidate;
end;

procedure PPGSetLanguage(const Lang: string);
var
  Key: string;
  T: TPPGTable;
  I: Integer;
begin
  Key := LowerCase(Lang);
  if Key = 'en' then
    Key := '';
  if (Key <> '') and (GTables <> nil) and GTables.TryGetValue(Key, T) then
    GActive := T
  else
    GActive := nil;
  GLanguage := Key;
  // Sichtbare Texte (Hinweise, Prozent, Screenreader-Namen) neu zeichnen
  if Screen <> nil then
    for I := 0 to Screen.FormCount - 1 do
      InvalidateAll(Screen.Forms[I]);
  if Assigned(PPGOnLanguageChange) then
    PPGOnLanguageChange(nil);
end;

function PPGSystemLanguage: string;
var
  Buf: array[0..9] of Char;
begin
  // ISO-639-Code der Benutzeroberflaeche (z.B. "de", "en")
  if GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_SISO639LANGNAME, Buf, Length(Buf)) > 0 then
    Result := LowerCase(string(Buf))
  else
    Result := '';
end;

initialization

finalization
  GActive := nil;
  FreeAndNil(GTables);

end.
