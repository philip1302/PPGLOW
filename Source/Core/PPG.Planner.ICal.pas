unit PPG.Planner.ICal;

{ iCalendar (.ics, RFC 5545) fuer den Planer (Phase 14a).

  - Export: VEVENT je Termin mit UID, DTSTAMP, DTSTART/DTEND (UTC mit "Z",
    ganztaegig als VALUE=DATE, bei tzmLocal ohne Zone), SUMMARY, LOCATION,
    DESCRIPTION (ohne Markup), RRULE, EXDATE; geaenderte Einzeltermine mit
    der UID der Serie und RECURRENCE-ID. Kategorie und Ressource als
    X-PPG-CATEGORY/X-PPG-RESOURCE.
  - Zeilen werden nach 75 Bytes (UTF-8) gefaltet, Texte maskiert (\\ \; \, \n).
  - Import: DTSTART/DTEND mit TZID (Windows- oder IANA-Name), UTC oder ohne
    Zone (= Anzeige-Zone), DURATION statt DTEND, RRULE, EXDATE, RECURRENCE-ID.
    VTIMEZONE-Bloecke werden nicht ausgewertet (die Regeln kommen von Windows). }

{$I ..\PPG.inc}

interface

uses
  System.Classes, System.SysUtils, PPG.Planner.Model;

function PPGICalText(Items: TPPGAppointments; const CalendarName: string = ''): string;
procedure PPGSaveICal(Items: TPPGAppointments; const FileName: string;
  const CalendarName: string = '');
/// Termine aus iCalendar-Text anhaengen; Ergebnis = Anzahl neuer Termine.
function PPGLoadICalText(Items: TPPGAppointments; const S: string): Integer;
function PPGLoadICal(Items: TPPGAppointments; const FileName: string): Integer;

implementation

uses
  System.DateUtils, System.Generics.Collections, PPG.Types, PPG.Exceptions, PPG.Lang,
  PPG.Consts, PPG.Markup, PPG.TimeZones, PPG.Planner.Recurrence;

function Escape(const S: string): string;
begin
  Result := StringReplace(S, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, ';', '\;', [rfReplaceAll]);
  Result := StringReplace(Result, ',', '\,', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\n', [rfReplaceAll]);
end;

function Unescape(const S: string): string;
var
  I: Integer;
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create(Length(S));
  try
    I := 1;
    while I <= Length(S) do
    begin
      if (S[I] = '\') and (I < Length(S)) then
      begin
        Inc(I);
        case S[I] of
          'n', 'N': SB.Append(#13#10);
        else
          SB.Append(S[I]);
        end;
      end
      else
        SB.Append(S[I]);
      Inc(I);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

/// Klartext als Markup (Body): & < > maskieren.
function MarkupText(const S: string): string;
begin
  Result := StringReplace(S, '&', '&amp;', [rfReplaceAll]);
  Result := StringReplace(Result, '<', '&lt;', [rfReplaceAll]);
  Result := StringReplace(Result, '>', '&gt;', [rfReplaceAll]);
end;

/// Zeile falten: hoechstens 75 Bytes (UTF-8), Fortsetzung mit Leerzeichen.
procedure AddFolded(SB: TStringBuilder; const Line: string);
var
  I, Bytes, CharBytes: Integer;
  C: Char;
begin
  Bytes := 0;
  I := 1;
  while I <= Length(Line) do
  begin
    C := Line[I];
    if Ord(C) < $80 then
      CharBytes := 1
    else if Ord(C) < $800 then
      CharBytes := 2
    else if (Ord(C) >= $D800) and (Ord(C) <= $DBFF) then
      CharBytes := 4
    else
      CharBytes := 3;
    if Bytes + CharBytes > 75 then
    begin
      SB.Append(#13#10' ');
      Bytes := 1;
    end;
    SB.Append(C);
    if CharBytes = 4 then
    begin
      // Ersatzpaar nie trennen
      Inc(I);
      if I <= Length(Line) then
        SB.Append(Line[I]);
    end;
    Inc(Bytes, CharBytes);
    Inc(I);
  end;
  SB.Append(#13#10);
end;

function UidOf(A: TPPGAppointment): string;
begin
  Result := 'PPG-' + IntToStr(A.Id) + '@ppglow';
end;

function TimeProp(const Name: string; A: TPPGAppointment; Stored: TDateTime;
  Items: TPPGAppointments): string;
begin
  if A.AllDay then
    Result := Name + ';VALUE=DATE:' + PPGFormatICalDateTime(Stored, False, True)
  else if Items.TimeZoneMode = tzmUtc then
    Result := Name + ':' + PPGFormatICalDateTime(Stored, True, False)
  else
    Result := Name + ':' + PPGFormatICalDateTime(Stored, False, False);
end;

function ExportExDates(Items: TPPGAppointments; A: TPPGAppointment): string;
var
  Parts: TArray<string>;
  I, K: Integer;
  D: TDateTime;
  IsUtc, IsDate, Skip: Boolean;
  C: TPPGAppointment;
  S: string;
begin
  Result := '';
  Parts := PPGSplitString(A.ExDates, ',', True);
  for I := 0 to High(Parts) do
  begin
    S := Trim(Parts[I]);
    if not PPGParseICalDateTime(S, D, IsUtc, IsDate) then
      Continue;
    // Herausgeloeste Vorkommen stehen als eigenes VEVENT mit RECURRENCE-ID
    // in der Datei. Als EXDATE wuerden Clients sie mit loeschen.
    Skip := False;
    if A.Id <> 0 then
      for K := 0 to Items.Count - 1 do
      begin
        C := Items[K];
        if (C = A) or (C.RecurrenceParent <> A.Id) then
          Continue;
        if A.AllDay then
          Skip := Trunc(C.RecurrenceStart) = Trunc(D)
        else
          Skip := Abs(C.RecurrenceStart - D) < 1 / SecsPerDay;
        if Skip then
          Break;
      end;
    if Skip then
      Continue;
    // Ganztaegig nur das Datum (VALUE=DATE), auch fuer Eintraege mit Uhrzeit
    if A.AllDay then
      S := PPGFormatICalDateTime(Trunc(D), False, True);
    if Result <> '' then
      Result := Result + ',';
    Result := Result + S;
  end;
end;

function PPGICalText(Items: TPPGAppointments; const CalendarName: string): string;
var
  SB: TStringBuilder;
  I: Integer;
  A, P: TPPGAppointment;
  Uid, ExDates: string;
begin
  SB := TStringBuilder.Create;
  try
    AddFolded(SB, 'BEGIN:VCALENDAR');
    AddFolded(SB, 'VERSION:2.0');
    AddFolded(SB, 'PRODID:-//PPGlow//Planner//DE');
    AddFolded(SB, 'CALSCALE:GREGORIAN');
    if CalendarName <> '' then
      AddFolded(SB, 'X-WR-CALNAME:' + Escape(CalendarName));
    for I := 0 to Items.Count - 1 do
    begin
      A := Items[I];
      AddFolded(SB, 'BEGIN:VEVENT');
      Uid := UidOf(A);
      P := nil;
      if A.RecurrenceParent <> 0 then
        P := Items.FindById(A.RecurrenceParent);
      if P <> nil then
        Uid := UidOf(P);
      AddFolded(SB, 'UID:' + Uid);
      AddFolded(SB, 'DTSTAMP:' + PPGFormatICalDateTime(TTimeZone.Local.ToUniversalTime(Now), True, False));
      AddFolded(SB, TimeProp('DTSTART', A, A.StartTime, Items));
      AddFolded(SB, TimeProp('DTEND', A, A.FinishTime, Items));
      if P <> nil then
        AddFolded(SB, TimeProp('RECURRENCE-ID', P, A.RecurrenceStart, Items));
      if A.Subject <> '' then
        AddFolded(SB, 'SUMMARY:' + Escape(A.Subject));
      if A.Location <> '' then
        AddFolded(SB, 'LOCATION:' + Escape(A.Location));
      if A.Body <> '' then
        AddFolded(SB, 'DESCRIPTION:' + Escape(PPGStripMarkup(A.Body)));
      if A.Recurrence <> '' then
        AddFolded(SB, 'RRULE:' + A.Recurrence);
      ExDates := ExportExDates(Items, A);
      if ExDates <> '' then
      begin
        if A.AllDay then
          AddFolded(SB, 'EXDATE;VALUE=DATE:' + ExDates)
        else
          AddFolded(SB, 'EXDATE:' + ExDates);
      end;
      if A.Category >= 0 then
        AddFolded(SB, 'X-PPG-CATEGORY:' + IntToStr(A.Category));
      if A.ResourceId <> 0 then
        AddFolded(SB, 'X-PPG-RESOURCE:' + IntToStr(A.ResourceId));
      AddFolded(SB, 'END:VEVENT');
    end;
    AddFolded(SB, 'END:VCALENDAR');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure PPGSaveICal(Items: TPPGAppointments; const FileName: string; const CalendarName: string);
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.WriteBOM := False;
    L.LineBreak := #13#10;
    L.Text := PPGICalText(Items, CalendarName);
    L.SaveToFile(FileName, TEncoding.UTF8);
  finally
    L.Free;
  end;
end;

type
  TICalProp = record
    Name: string;
    Params: string;   // ";TZID=...;VALUE=DATE"
    Value: string;
  end;

function ParseLine(const Line: string; out P: TICalProp): Boolean;
var
  I, Colon, Semi: Integer;
  InQuote: Boolean;
begin
  // Name;Param=Wert;Param="a:b":Wert - Doppelpunkt in Anfuehrungszeichen ueberspringen
  Colon := 0;
  InQuote := False;
  for I := 1 to Length(Line) do
  begin
    if Line[I] = '"' then
      InQuote := not InQuote
    else if (Line[I] = ':') and not InQuote then
    begin
      Colon := I;
      Break;
    end;
  end;
  Result := Colon > 0;
  if not Result then
    Exit;
  P.Value := Copy(Line, Colon + 1, MaxInt);
  P.Name := Copy(Line, 1, Colon - 1);
  Semi := Pos(';', P.Name);
  if Semi > 0 then
  begin
    P.Params := Copy(P.Name, Semi, MaxInt);
    P.Name := Copy(P.Name, 1, Semi - 1);
  end
  else
    P.Params := '';
  P.Name := UpperCase(P.Name);
end;

function Param(const P: TICalProp; const Name: string): string;
var
  Parts: TArray<string>;
  I, E: Integer;
begin
  Result := '';
  Parts := PPGSplitString(P.Params, ';', True);
  for I := 0 to High(Parts) do
  begin
    E := Pos('=', Parts[I]);
    if (E > 0) and SameText(Copy(Parts[I], 1, E - 1), Name) then
    begin
      Result := Copy(Parts[I], E + 1, MaxInt);
      if (Length(Result) >= 2) and (Result[1] = '"') then
        Result := Copy(Result, 2, Length(Result) - 2);
      Exit;
    end;
  end;
end;

type
  /// Zeitwert aus der Datei: als UTC (Zeit) bzw. Datum (ganztaegig) oder
  /// "ohne Zone" (Anzeige-Zone).
  TICalTime = record
    Value: TDateTime;
    IsDate: Boolean;
    IsUtc: Boolean;   // Value ist UTC
    Valid: Boolean;
  end;

function ReadTime(const P: TICalProp): TICalTime;
var
  Tz: string;
  Zone: IPPGTimeZone;
begin
  Result.Valid := PPGParseICalDateTime(P.Value, Result.Value, Result.IsUtc, Result.IsDate);
  if not Result.Valid or Result.IsUtc or Result.IsDate then
    Exit;
  Tz := Param(P, 'TZID');
  if Tz <> '' then
  begin
    Zone := PPGFindTimeZone(Tz);
    if Zone <> nil then
    begin
      Result.Value := Zone.ToUtc(Result.Value);
      Result.IsUtc := True;
    end;
  end;
end;

/// Gespeicherte Zeit eines Werts fuer die Collection.
function StoredTime(Items: TPPGAppointments; const T: TICalTime; AllDay: Boolean): TDateTime;
begin
  Result := T.Value;
  if AllDay or T.IsDate then
    Exit(Trunc(T.Value));
  if Items.TimeZoneMode = tzmUtc then
  begin
    if not T.IsUtc then
      Result := Items.DisplayZone.ToUtc(T.Value); // ohne Zone: Anzeige-Zone
  end
  else if T.IsUtc then
    Result := Items.DisplayZone.ToLocal(T.Value);
end;

/// DURATION (z. B. PT1H30M, P1D, P1W) in Tagen.
function ParseDuration(const S: string; out D: TDateTime): Boolean;
var
  I, N: Integer;
  T: string;
  InTime, Neg: Boolean;
begin
  D := 0;
  T := UpperCase(Trim(S));
  Neg := (T <> '') and (T[1] = '-');
  if (T <> '') and CharInSet(T[1], ['+', '-']) then
    Delete(T, 1, 1);
  Result := (T <> '') and (T[1] = 'P');
  if not Result then
    Exit;
  InTime := False;
  N := 0;
  for I := 2 to Length(T) do
    case T[I] of
      '0'..'9': N := N * 10 + Ord(T[I]) - Ord('0');
      'T': InTime := True;
      'W': begin D := D + N * 7; N := 0; end;
      'D': begin D := D + N; N := 0; end;
      'H': begin D := D + N / 24; N := 0; end;
      'M': begin
             if InTime then
               D := D + N / MinsPerDay;
             N := 0;
           end;
      'S': begin D := D + N / SecsPerDay; N := 0; end;
    else
      Exit(False);
    end;
  if Neg then
    D := -D;
end;

function PPGLoadICalText(Items: TPPGAppointments; const S: string): Integer;
var
  Lines: TStringList;
  Raw: string;
  I: Integer;
  P: TICalProp;
  InEvent, InOther: Boolean;
  Depth: Integer;
  A: TPPGAppointment;
  Dtstart, Dtend, RecId: TICalTime;
  Dur: TDateTime;
  HasDur: Boolean;
  Uid, ExList: string;
  Uids: TDictionary<string, TPPGAppointment>;
  Pending: TList<TPair<TPPGAppointment, string>>; // Ausnahme -> UID der Serie
  Parent: TPPGAppointment;
  K: Integer;
  ExParts: TArray<string>;
  ExT: TICalTime;
  ExP: TICalProp;
  Pair: TPair<TPPGAppointment, string>;
begin
  Result := 0;
  // Zeilen entfalten (CRLF + Leerzeichen/Tab = Fortsetzung)
  Raw := StringReplace(S, #13#10' ', '', [rfReplaceAll]);
  Raw := StringReplace(Raw, #13#10#9, '', [rfReplaceAll]);
  Raw := StringReplace(Raw, #10' ', '', [rfReplaceAll]);
  Raw := StringReplace(Raw, #10#9, '', [rfReplaceAll]);
  if Pos('BEGIN:VCALENDAR', UpperCase(Raw)) = 0 then
    raise EPPGError.Create(PPGStr(@SPPGICalInvalid));
  Lines := TStringList.Create;
  Uids := TDictionary<string, TPPGAppointment>.Create;
  Pending := TList<TPair<TPPGAppointment, string>>.Create;
  Items.BeginUpdate;
  try
    Lines.Text := Raw;
    InEvent := False;
    InOther := False;
    Depth := 0;
    A := nil;
    HasDur := False;
    Dur := 0;
    for I := 0 to Lines.Count - 1 do
    begin
      if not ParseLine(Lines[I], P) then
        Continue;
      if P.Name = 'BEGIN' then
      begin
        if SameText(P.Value, 'VEVENT') and not InEvent then
        begin
          InEvent := True;
          A := Items.Add;
          FillChar(Dtstart, SizeOf(Dtstart), 0);
          FillChar(Dtend, SizeOf(Dtend), 0);
          FillChar(RecId, SizeOf(RecId), 0);
          HasDur := False;
          Uid := '';
          ExList := '';
        end
        else if InEvent then
        begin
          InOther := True; // VALARM u. ae. im Termin
          Inc(Depth);
        end;
        Continue;
      end;
      if P.Name = 'END' then
      begin
        if InOther then
        begin
          Dec(Depth);
          InOther := Depth > 0;
        end
        else if InEvent and SameText(P.Value, 'VEVENT') then
        begin
          InEvent := False;
          if not Dtstart.Valid then
          begin
            A.Free; // ohne Beginn unbrauchbar
            Continue;
          end;
          A.AllDay := Dtstart.IsDate;
          A.StartTime := StoredTime(Items, Dtstart, A.AllDay);
          if Dtend.Valid then
            A.FinishTime := StoredTime(Items, Dtend, A.AllDay)
          else if HasDur then
            A.FinishTime := A.StartTime + Dur
          else if A.AllDay then
            A.FinishTime := A.StartTime + 1
          else
            A.FinishTime := A.StartTime;
          // EXDATE in gespeicherter Form
          if ExList <> '' then
            A.ExDates := ExList;
          if RecId.Valid then
          begin
            A.RecurrenceStart := StoredTime(Items, RecId, A.AllDay);
            Pending.Add(TPair<TPPGAppointment, string>.Create(A, Uid));
          end
          else if (Uid <> '') and not Uids.ContainsKey(Uid) then
            Uids.Add(Uid, A);
          Inc(Result);
        end;
        Continue;
      end;
      if not InEvent or InOther then
        Continue;
      if P.Name = 'UID' then
        Uid := P.Value
      else if P.Name = 'DTSTART' then
        Dtstart := ReadTime(P)
      else if P.Name = 'DTEND' then
        Dtend := ReadTime(P)
      else if P.Name = 'DURATION' then
        HasDur := ParseDuration(P.Value, Dur)
      else if P.Name = 'RECURRENCE-ID' then
        RecId := ReadTime(P)
      else if P.Name = 'SUMMARY' then
        A.Subject := Unescape(P.Value)
      else if P.Name = 'LOCATION' then
        A.Location := Unescape(P.Value)
      else if P.Name = 'DESCRIPTION' then
        // Body ist Markup: Text aus der Datei darf keine Tags ausloesen
        A.Body := MarkupText(Unescape(P.Value))
      else if P.Name = 'RRULE' then
        A.Recurrence := P.Value
      else if P.Name = 'EXDATE' then
      begin
        // Liste, ggf. mit TZID: in gespeicherte Form (UTC mit Z bzw. Datum)
        ExParts := PPGSplitString(P.Value, ',', True);
        for K := 0 to High(ExParts) do
        begin
          ExP := P;
          ExP.Value := Trim(ExParts[K]);
          ExT := ReadTime(ExP);
          if not ExT.Valid then
            Continue;
          if ExList <> '' then
            ExList := ExList + ',';
          if ExT.IsDate then
            ExList := ExList + PPGFormatICalDateTime(ExT.Value, False, True)
          else if Items.TimeZoneMode = tzmUtc then
            ExList := ExList + PPGFormatICalDateTime(StoredTime(Items, ExT, False), True, False)
          else
            ExList := ExList + PPGFormatICalDateTime(StoredTime(Items, ExT, False), False, False);
        end;
      end
      else if P.Name = 'X-PPG-CATEGORY' then
        A.Category := StrToIntDef(P.Value, -1)
      else if P.Name = 'X-PPG-RESOURCE' then
        A.ResourceId := StrToIntDef(P.Value, 0);
    end;
    // Datei endet mitten im Termin (abgeschnitten): nicht als leeren Termin
    // am 30.12.1899 stehen lassen
    if InEvent and (A <> nil) then
      A.Free;
    // Geaenderte Einzeltermine der Serie zuordnen
    for Pair in Pending do
      if Uids.TryGetValue(Pair.Value, Parent) then
      begin
        Pair.Key.RecurrenceParent := Parent.Id;
        // urspruenglicher Beginn (gespeicherte Zeit) in Anzeige-Zeit
        if (Items.TimeZoneMode = tzmUtc) and not Pair.Key.AllDay then
          Parent.AddException(Items.DisplayZone.ToLocal(Pair.Key.RecurrenceStart))
        else
          Parent.AddException(Pair.Key.RecurrenceStart);
      end;
  finally
    Items.EndUpdate;
    Pending.Free;
    Uids.Free;
    Lines.Free;
  end;
end;

function PPGLoadICal(Items: TPPGAppointments; const FileName: string): Integer;
var
  L: TStringList;
begin
  L := TStringList.Create;
  try
    L.LoadFromFile(FileName, TEncoding.UTF8);
    Result := PPGLoadICalText(Items, L.Text);
  finally
    L.Free;
  end;
end;

end.
