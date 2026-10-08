unit PPG.Markup;

{ Mini-Markup fuer formatierten Text in Listen, Labels, Statusleisten.

  Bewusst KEIN HTML. Unterstuetzt:
    <b> <i> <u> <s>               fett, kursiv, unterstrichen, durchgestrichen
    <color=#RRGGBB> <color=clRed> Textfarbe (</color> stellt die vorige her)
    <a href="ziel">Text</a>       Link (Farbe LinkColor, unterstrichen, Hit-Test)
    <img=3>                       Bild 3 aus der ImageList
    <br>                          Zeilenumbruch (ebenso CR/LF im Text)
    &lt; &gt; &amp; &quot; &nbsp; Sonderzeichen

  Robustheit: Der Parser wirft nie. Unbekannte oder kaputte Tags bleiben als
  Text sichtbar, nicht geschlossene Tags gelten bis zum Ende.
  Leistung: Text ohne '<' und '&' nimmt einen schnellen Pfad; geparste Texte
  werden zwischengespeichert (PPGParseMarkupCached, nur Hauptthread).
  Messen per GDI auf einem Speicher-DC (wie das Zeichnen): kein Paint noetig. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.ImgList, PPG.Render.Intf;

type
  TPPGMarkupRunKind = (mrkText, mrkImage, mrkBreak);

  TPPGMarkupRun = record
    Kind: TPPGMarkupRunKind;
    Text: string;
    Style: TFontStyles;
    Color: TColor;      // clNone = Standardfarbe
    ImageIndex: Integer;
    Link: string;       // '' = kein Link
  end;
  TPPGMarkupRuns = array of TPPGMarkupRun;

  TPPGMarkupFragment = record
    Run: Integer;
    Text: string;
    Rect: TRect;        // relativ zum Ursprung des Layouts
  end;

  TPPGMarkupLayout = class
  private
    FRuns: TPPGMarkupRuns;
    FFrags: array of TPPGMarkupFragment;
    FSize: TSize;
    FLineCount: Integer;
    FFonts: array[0..15] of TFont;
    FBaseFont: TFont;
    FImages: TCustomImageList;
    FRunLink: array of Integer;
    FLinkCount: Integer;
    function StyleFont(Style: TFontStyles): TFont;
    procedure ResetFonts;
    procedure IndexLinks;
  public
    constructor Create;
    destructor Destroy; override;
    /// Berechnet die Lage. MaxWidth <= 0 oder WordWrap = False: eine Zeile je Umbruch.
    procedure Layout(const S: string; Font: TFont; Images: TCustomImageList;
      MaxWidth: Integer; WordWrap: Boolean);
    /// Zeichnet an (X, Y). DefaultColor fuer normalen Text, LinkColor fuer Links.
    procedure Draw(const Canvas: IPPGCanvas; X, Y: Integer; DefaultColor, LinkColor: TColor;
      Enabled: Boolean = True);
    /// Link unter dem Punkt (relativ zum Ursprung), '' = keiner.
    function LinkAt(X, Y: Integer): string;
    function HasLinks: Boolean;
    /// Links in Lesereihenfolge (zusammenhaengende Abschnitte mit gleichem Ziel
    /// zaehlen als ein Link), fuer Tastaturbedienung und Fokusrahmen.
    function LinkCount: Integer;
    function LinkTarget(Index: Integer): string;
    /// Sichtbarer Text eines Links (Screenreader).
    function LinkText(Index: Integer): string;
    /// Umschliessendes Rechteck eines Links (relativ zum Ursprung des Layouts).
    function LinkBounds(Index: Integer): TRect;
    /// Link unter dem Punkt (relativ), -1 = keiner.
    function LinkIndexAt(X, Y: Integer): Integer;
    /// Link-Nummer eines Abschnitts (-1 = kein Link).
    function RunLinkIndex(Run: Integer): Integer;
    property Size: TSize read FSize;
    property LineCount: Integer read FLineCount;
  end;

/// True, wenn S kein Markup enthaelt (schneller Pfad).
function PPGIsPlainText(const S: string): Boolean;
/// Zerlegt S in Abschnitte; wirft nie.
function PPGParseMarkup(const S: string): TPPGMarkupRuns;
/// Wie PPGParseMarkup, mit Zwischenspeicher (nur im Hauptthread verwenden).
function PPGParseMarkupCached(const S: string): TPPGMarkupRuns;
/// Reiner Text ohne Tags (fuer Screenreader, Suche, Sortierung).
function PPGStripMarkup(const S: string): string;

implementation

uses
  System.SysUtils, System.UITypes, System.Generics.Collections, PPG.Render.Gdi, PPG.ErrorHandler;

const
  MaxCache = 512;

var
  GCache: TDictionary<string, TPPGMarkupRuns> = nil;

function PPGIsPlainText(const S: string): Boolean;
begin
  Result := (Pos('<', S) = 0) and (Pos('&', S) = 0) and (Pos(#10, S) = 0) and
    (Pos(#13, S) = 0);
end;

function ParseColor(const V: string; out C: TColor): Boolean;
var
  N: Integer;
  L: Longint;
  S: string;
begin
  Result := False;
  S := Trim(V);
  if (Length(S) >= 2) and (S[1] = '"') and (S[Length(S)] = '"') then
    S := Copy(S, 2, Length(S) - 2);
  if (Length(S) = 7) and (S[1] = '#') then
  begin
    if TryStrToInt('$' + Copy(S, 2, 6), N) then
    begin
      // #RRGGBB -> TColor ($00BBGGRR)
      C := TColor(RGB((N shr 16) and $FF, (N shr 8) and $FF, N and $FF));
      Result := True;
    end;
  end
  else if IdentToColor(S, L) then
  begin
    C := TColor(L);
    Result := True;
  end
  else if TryStrToInt(S, N) then
  begin
    C := TColor(N);
    Result := True;
  end;
end;

function Unquote(const S: string): string;
begin
  Result := Trim(S);
  if (Length(Result) >= 2) and ((Result[1] = '"') or (Result[1] = '''')) and
    (Result[Length(Result)] = Result[1]) then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

function PPGParseMarkup(const S: string): TPPGMarkupRuns;
var
  Count, I, J, Len, N: Integer;
  Buf, Tag, Name, Value: string;
  Bold, Ital, Under, Strike: Integer;
  Colors: array of TColor;
  Link: string;
  C: TColor;
  Recognized, Closing: Boolean;

  function CurStyle: TFontStyles;
  begin
    Result := [];
    if Bold > 0 then
      Include(Result, fsBold);
    if Ital > 0 then
      Include(Result, fsItalic);
    if Under > 0 then
      Include(Result, fsUnderline);
    if Strike > 0 then
      Include(Result, fsStrikeOut);
  end;

  function CurColor: TColor;
  begin
    if Length(Colors) = 0 then
      Result := clNone
    else
      Result := Colors[High(Colors)];
  end;

  procedure AddRun(Kind: TPPGMarkupRunKind; const AText: string; AImage: Integer);
  begin
    if Count = Length(Result) then
      SetLength(Result, Count * 2 + 4);
    Result[Count].Kind := Kind;
    Result[Count].Text := AText;
    Result[Count].Style := CurStyle;
    Result[Count].Color := CurColor;
    Result[Count].ImageIndex := AImage;
    Result[Count].Link := Link;
    Inc(Count);
  end;

  procedure Flush;
  begin
    if Buf <> '' then
    begin
      AddRun(mrkText, Buf, -1);
      Buf := '';
    end;
  end;

  function Dec0(var V: Integer): Integer;
  begin
    if V > 0 then
      Dec(V);
    Result := V;
  end;

begin
  Count := 0;
  SetLength(Result, 0);
  Buf := '';
  Bold := 0;
  Ital := 0;
  Under := 0;
  Strike := 0;
  Link := '';
  SetLength(Colors, 0);
  Len := Length(S);
  I := 1;
  try
    while I <= Len do
    begin
      case S[I] of
        '<':
          begin
            J := I + 1;
            while (J <= Len) and (S[J] <> '>') and (S[J] <> '<') do
              Inc(J);
            Recognized := False;
            if (J <= Len) and (S[J] = '>') then
            begin
              Tag := Trim(Copy(S, I + 1, J - I - 1));
              Closing := (Tag <> '') and (Tag[1] = '/');
              if Closing then
                Tag := Trim(Copy(Tag, 2, MaxInt));
              // Name und Wert: "color=#ff0000", "a href=x", "img=3", "br/"
              N := 1;
              while (N <= Length(Tag)) and CharInSet(Tag[N], ['a'..'z', 'A'..'Z']) do
                Inc(N);
              Name := LowerCase(Copy(Tag, 1, N - 1));
              Value := Trim(Copy(Tag, N, MaxInt));
              if (Value <> '') and (Value[Length(Value)] = '/') then
                Value := Trim(Copy(Value, 1, Length(Value) - 1));
              if (Name = 'b') or (Name = 'i') or (Name = 'u') or (Name = 's') then
              begin
                if Value = '' then
                begin
                  Recognized := True;
                  Flush;
                  case Name[1] of
                    'b': if Closing then Dec0(Bold) else Inc(Bold);
                    'i': if Closing then Dec0(Ital) else Inc(Ital);
                    'u': if Closing then Dec0(Under) else Inc(Under);
                    's': if Closing then Dec0(Strike) else Inc(Strike);
                  end;
                end;
              end
              else if Name = 'br' then
              begin
                if not Closing then
                begin
                  Recognized := True;
                  Flush;
                  AddRun(mrkBreak, '', -1);
                end;
              end
              else if Name = 'color' then
              begin
                if Closing then
                begin
                  Recognized := True;
                  Flush;
                  if Length(Colors) > 0 then
                    SetLength(Colors, Length(Colors) - 1);
                end
                else if (Value <> '') and (Value[1] = '=') then
                begin
                  Recognized := True;
                  Flush;
                  if not ParseColor(Copy(Value, 2, MaxInt), C) then
                    C := CurColor; // ungueltig: Farbe bleibt, </color> passt trotzdem
                  SetLength(Colors, Length(Colors) + 1);
                  Colors[High(Colors)] := C;
                end;
              end
              else if Name = 'a' then
              begin
                if Closing then
                begin
                  Recognized := True;
                  Flush;
                  Link := '';
                end
                else if SameText(Copy(Value, 1, 4), 'href') then
                begin
                  Value := Trim(Copy(Value, 5, MaxInt));
                  if (Value <> '') and (Value[1] = '=') then
                  begin
                    Recognized := True;
                    Flush;
                    Link := Unquote(Copy(Value, 2, MaxInt));
                    if Link = '' then
                      Link := ' '; // leerer Link bleibt als Link erkennbar
                  end;
                end;
              end
              else if (Name = 'img') and not Closing then
              begin
                if (Value <> '') and (Value[1] = '=') and
                  TryStrToInt(Unquote(Copy(Value, 2, MaxInt)), N) then
                begin
                  Recognized := True;
                  Flush;
                  AddRun(mrkImage, '', N);
                end;
              end;
            end;
            if Recognized then
              I := J + 1
            else
            begin
              Buf := Buf + '<'; // unbekannt: als Text
              Inc(I);
            end;
          end;
        '&':
          begin
            J := I + 1;
            while (J <= Len) and (J - I <= 6) and (S[J] <> ';') do
              Inc(J);
            Name := '';
            if (J <= Len) and (S[J] = ';') then
              Name := LowerCase(Copy(S, I + 1, J - I - 1));
            if Name = 'lt' then
              Buf := Buf + '<'
            else if Name = 'gt' then
              Buf := Buf + '>'
            else if Name = 'amp' then
              Buf := Buf + '&'
            else if Name = 'quot' then
              Buf := Buf + '"'
            else if Name = 'nbsp' then
              Buf := Buf + #$00A0
            else
            begin
              Buf := Buf + '&';
              Inc(I);
              Continue;
            end;
            I := J + 1;
          end;
        #13, #10:
          begin
            Flush;
            AddRun(mrkBreak, '', -1);
            if (S[I] = #13) and (I < Len) and (S[I + 1] = #10) then
              Inc(I);
            Inc(I);
          end;
      else
        Buf := Buf + S[I];
        Inc(I);
      end;
    end;
    Flush;
  except
    // Fehlergrenze: Markup darf nie eine Exception ausloesen -> roh anzeigen.
    // Protokollieren, damit ein Parserfehler nicht unbemerkt bleibt.
    on E: Exception do
    begin
      TPPGErrorHandler.LogWarning(nil, 'PPGParseMarkup: ' + E.ClassName + ': ' + E.Message);
      Count := 0;
      Link := '';
      SetLength(Colors, 0);
      Bold := 0;
      Ital := 0;
      Under := 0;
      Strike := 0;
      AddRun(mrkText, S, -1);
    end;
  end;
  SetLength(Result, Count);
end;

function PPGParseMarkupCached(const S: string): TPPGMarkupRuns;
begin
  if GCache = nil then
    GCache := TDictionary<string, TPPGMarkupRuns>.Create;
  if GCache.TryGetValue(S, Result) then
    Exit;
  Result := PPGParseMarkup(S);
  if GCache.Count >= MaxCache then
    GCache.Clear; // einfach und ohne Buchhaltung: selten genug
  GCache.Add(S, Result);
end;

function PPGStripMarkup(const S: string): string;
var
  R: TPPGMarkupRuns;
  I: Integer;
begin
  if PPGIsPlainText(S) then
    Exit(S);
  R := PPGParseMarkup(S);
  Result := '';
  for I := 0 to High(R) do
    case R[I].Kind of
      mrkText:
        Result := Result + R[I].Text;
      mrkBreak:
        Result := Result + sLineBreak;
    end;
end;

{ TPPGMarkupLayout }

constructor TPPGMarkupLayout.Create;
begin
  inherited Create;
  FBaseFont := TFont.Create;
end;

destructor TPPGMarkupLayout.Destroy;
begin
  ResetFonts;
  FreeAndNil(FBaseFont);
  inherited Destroy;
end;

procedure TPPGMarkupLayout.ResetFonts;
var
  I: Integer;
begin
  for I := Low(FFonts) to High(FFonts) do
    FreeAndNil(FFonts[I]);
end;

function TPPGMarkupLayout.StyleFont(Style: TFontStyles): TFont;
var
  K: Integer;
begin
  K := 0;
  if fsBold in Style then
    K := K or 1;
  if fsItalic in Style then
    K := K or 2;
  if fsUnderline in Style then
    K := K or 4;
  if fsStrikeOut in Style then
    K := K or 8;
  if FFonts[K] = nil then
  begin
    FFonts[K] := TFont.Create;
    FFonts[K].Assign(FBaseFont);
    FFonts[K].Style := FBaseFont.Style + Style;
  end;
  Result := FFonts[K];
end;

procedure TPPGMarkupLayout.Layout(const S: string; Font: TFont; Images: TCustomImageList;
  MaxWidth: Integer; WordWrap: Boolean);
var
  DC: HDC;
  X, LineTop, LineH, LineStart, I, P, Q, Len, W, H, FragCount, TextH: Integer;
  Token, T: string;
  Wrap: Boolean;
  Sz: TSize;
  F: TFont;

  procedure FinishLine;
  var
    K: Integer;
  begin
    if LineH = 0 then
      LineH := TextH;
    for K := LineStart to FragCount - 1 do
    begin
      H := FFrags[K].Rect.Bottom - FFrags[K].Rect.Top;
      FFrags[K].Rect.Top := LineTop + (LineH - H) div 2;
      FFrags[K].Rect.Bottom := FFrags[K].Rect.Top + H;
    end;
    if X > FSize.cx then
      FSize.cx := X;
    Inc(LineTop, LineH);
    Inc(FLineCount);
    LineH := 0;
    X := 0;
    LineStart := FragCount;
  end;

  procedure Place(RunIdx: Integer; const AText: string; AW, AH: Integer);
  begin
    // Gleicher Abschnitt in derselben Zeile: anhaengen (weniger DrawText-Aufrufe)
    if (FragCount > LineStart) and (FFrags[FragCount - 1].Run = RunIdx) and (AText <> '') then
    begin
      FFrags[FragCount - 1].Text := FFrags[FragCount - 1].Text + AText;
      FFrags[FragCount - 1].Rect.Right := X + AW;
      // Hoehe mitnehmen (z.B. Fragment begann mit reinen Leerzeichen)
      if AH > FFrags[FragCount - 1].Rect.Bottom then
        FFrags[FragCount - 1].Rect.Bottom := AH;
    end
    else
    begin
      if FragCount = Length(FFrags) then
        SetLength(FFrags, FragCount * 2 + 8);
      FFrags[FragCount].Run := RunIdx;
      FFrags[FragCount].Text := AText;
      FFrags[FragCount].Rect := Rect(X, 0, X + AW, AH);
      Inc(FragCount);
    end;
    Inc(X, AW);
    if AH > LineH then
      LineH := AH;
  end;

begin
  ResetFonts;
  FBaseFont.Assign(Font);
  FImages := Images;
  if PPGIsPlainText(S) then
  begin
    SetLength(FRuns, 1);
    FRuns[0].Kind := mrkText;
    FRuns[0].Text := S;
    FRuns[0].Style := [];
    FRuns[0].Color := clNone;
    FRuns[0].ImageIndex := -1;
    FRuns[0].Link := '';
  end
  else
    FRuns := PPGParseMarkupCached(S);
  SetLength(FFrags, 0);
  FragCount := 0;
  FSize.cx := 0;
  FSize.cy := 0;
  FLineCount := 0;
  X := 0;
  LineTop := 0;
  LineH := 0;
  LineStart := 0;
  Wrap := WordWrap and (MaxWidth > 0);

  DC := CreateCompatibleDC(0);
  try
    TextH := PPGGdiMeasureText(DC, 'Wg', FBaseFont, 0, False).cy;
    for I := 0 to High(FRuns) do
      case FRuns[I].Kind of
        mrkBreak:
          FinishLine;
        mrkImage:
          if (FImages <> nil) and (FRuns[I].ImageIndex >= 0) and
            (FRuns[I].ImageIndex < FImages.Count) then
          begin
            W := FImages.Width;
            if Wrap and (X > 0) and (X + W > MaxWidth) then
              FinishLine;
            Place(I, '', W, FImages.Height);
          end;
        mrkText:
          begin
            F := StyleFont(FRuns[I].Style);
            if FRuns[I].Link <> '' then
              F := StyleFont(FRuns[I].Style + [fsUnderline]);
            T := FRuns[I].Text;
            Len := Length(T);
            if not Wrap then
            begin
              Sz := PPGGdiMeasureText(DC, T, F, 0, False);
              Place(I, T, Sz.cx, Sz.cy);
              Continue;
            end;
            // Wortweise: Wort + folgende Leerzeichen bilden ein Token
            P := 1;
            while P <= Len do
            begin
              Q := P;
              while (Q <= Len) and (T[Q] <> ' ') do
                Inc(Q);
              while (Q <= Len) and (T[Q] = ' ') do
                Inc(Q);
              Token := Copy(T, P, Q - P);
              if TrimRight(Token) = '' then
                Sz := PPGGdiMeasureText(DC, Token, F, 0, False) // nur Leerzeichen: Hoehe der Schrift
              else
                Sz := PPGGdiMeasureText(DC, TrimRight(Token), F, 0, False);
              if (X > 0) and (X + Sz.cx > MaxWidth) then
                FinishLine;
              if Token <> TrimRight(Token) then
                Sz.cx := PPGGdiMeasureText(DC, Token, F, 0, False).cx;
              Place(I, Token, Sz.cx, Sz.cy);
              P := Q;
            end;
          end;
      end;
    if (FragCount > LineStart) or (FLineCount = 0) then
      FinishLine;
  finally
    DeleteDC(DC);
  end;
  SetLength(FFrags, FragCount);
  FSize.cy := LineTop;
  IndexLinks;
end;

procedure TPPGMarkupLayout.IndexLinks;
var
  Shown: array of Boolean;
  I, J, K, Idx: Integer;
  Visible: Boolean;
begin
  // Link-Nummern einmal je Layout berechnen (sonst O(n^2) bei jeder Abfrage).
  // Ein Link ohne Fragment (nur <img> ohne ImageList oder nur <br>) bekommt
  // keine Nummer, sonst landet der Tastaturfokus auf einem Link ohne Flaeche.
  SetLength(Shown, Length(FRuns));
  for I := 0 to High(Shown) do
    Shown[I] := False;
  for I := 0 to High(FFrags) do
    Shown[FFrags[I].Run] := True;
  SetLength(FRunLink, Length(FRuns));
  FLinkCount := 0;
  I := 0;
  while I <= High(FRuns) do
  begin
    if FRuns[I].Link = '' then
    begin
      FRunLink[I] := -1;
      Inc(I);
      Continue;
    end;
    // Zusammenhaengende Abschnitte mit gleichem Ziel bilden einen Link
    J := I;
    Visible := False;
    while (J <= High(FRuns)) and (FRuns[J].Link = FRuns[I].Link) do
    begin
      if Shown[J] then
        Visible := True;
      Inc(J);
    end;
    if Visible then
    begin
      Idx := FLinkCount;
      Inc(FLinkCount);
    end
    else
      Idx := -1;
    for K := I to J - 1 do
      FRunLink[K] := Idx;
    I := J;
  end;
end;

procedure TPPGMarkupLayout.Draw(const Canvas: IPPGCanvas; X, Y: Integer;
  DefaultColor, LinkColor: TColor; Enabled: Boolean);
var
  I: Integer;
  R: TRect;
  Run: TPPGMarkupRun;
  C: TColor;
  F: TFont;
begin
  for I := 0 to High(FFrags) do
  begin
    Run := FRuns[FFrags[I].Run];
    R := FFrags[I].Rect;
    OffsetRect(R, X, Y);
    case Run.Kind of
      mrkImage:
        Canvas.DrawImage(FImages, Run.ImageIndex, R.Left, R.Top, Enabled);
      mrkText:
        begin
          if Run.Link <> '' then
          begin
            F := StyleFont(Run.Style + [fsUnderline]);
            C := LinkColor;
          end
          else
          begin
            F := StyleFont(Run.Style);
            C := Run.Color;
          end;
          if (C = clNone) or not Enabled then
            C := DefaultColor;
          Canvas.DrawText(R, FFrags[I].Text, F, C,
            DT_SINGLELINE or DT_NOPREFIX or DT_NOCLIP or DT_LEFT or DT_TOP);
        end;
    end;
  end;
end;

function TPPGMarkupLayout.LinkAt(X, Y: Integer): string;
var
  I: Integer;
begin
  for I := 0 to High(FFrags) do
    if (FRuns[FFrags[I].Run].Link <> '') and PtInRect(FFrags[I].Rect, Point(X, Y)) then
      Exit(FRuns[FFrags[I].Run].Link);
  Result := '';
end;

function TPPGMarkupLayout.HasLinks: Boolean;
begin
  Result := FLinkCount > 0;
end;

function TPPGMarkupLayout.RunLinkIndex(Run: Integer): Integer;
begin
  if (Run < 0) or (Run > High(FRunLink)) then
    Result := -1
  else
    Result := FRunLink[Run];
end;

function TPPGMarkupLayout.LinkCount: Integer;
begin
  Result := FLinkCount;
end;

function TPPGMarkupLayout.LinkTarget(Index: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FRuns) do
    if RunLinkIndex(I) = Index then
      Exit(FRuns[I].Link);
end;

function TPPGMarkupLayout.LinkText(Index: Integer): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to High(FRuns) do
    if (FRuns[I].Kind = mrkText) and (RunLinkIndex(I) = Index) then
      Result := Result + FRuns[I].Text;
end;

function TPPGMarkupLayout.LinkBounds(Index: Integer): TRect;
var
  I: Integer;
  First: Boolean;
begin
  Result := Rect(0, 0, 0, 0);
  First := True;
  for I := 0 to High(FFrags) do
    if RunLinkIndex(FFrags[I].Run) = Index then
    begin
      if First then
        Result := FFrags[I].Rect
      else
        UnionRect(Result, Result, FFrags[I].Rect);
      First := False;
    end;
end;

function TPPGMarkupLayout.LinkIndexAt(X, Y: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FFrags) do
    if (FRuns[FFrags[I].Run].Link <> '') and PtInRect(FFrags[I].Rect, Point(X, Y)) then
      Exit(RunLinkIndex(FFrags[I].Run));
  Result := -1;
end;

initialization

finalization
  FreeAndNil(GCache);

end.
