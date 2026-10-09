unit PPG.Markup;

{ Mini-Markup fuer formatierten Text in Listen, Labels, Statusleisten.

  Bewusst KEIN HTML. Unterstuetzt:
    <b> <i> <u> <s>               fett, kursiv, unterstrichen, durchgestrichen
    <color=#RRGGBB> <color=clRed> Textfarbe (</color> stellt die vorige her)
    <a href="ziel">Text</a>       Link (Farbe LinkColor, unterstrichen, Hit-Test)
    <img=3>                       Bild 3 aus der ImageList
    <br>                          Zeilenumbruch (ebenso CR/LF im Text)
    &lt; &gt; &amp; &quot; &nbsp; Sonderzeichen

  Der Parser (Runs, PPGParseMarkup(Cached), PPGStripMarkup, PPGIsPlainText)
  liegt seit Audit 11d in der Core-Unit PPG.Markup.Parser; diese Unit
  enthaelt Layout, Messen und Zeichnen.

  Robustheit: Der Parser wirft nie. Unbekannte oder kaputte Tags bleiben als
  Text sichtbar, nicht geschlossene Tags gelten bis zum Ende.
  Leistung: Text ohne '<' und '&' nimmt einen schnellen Pfad; geparste Texte
  werden zwischengespeichert (PPGParseMarkupCached, nur Hauptthread).
  Messen per GDI auf einem Speicher-DC (wie das Zeichnen): kein Paint noetig. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, Vcl.ImgList, PPG.Render.Intf, PPG.Markup.Parser;

type
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
    FBaseLF: TLogFont; // Audit 8d #7: Schrift, zu der FFonts/FTextH gehoeren
    FBaseValid: Boolean;
    FTextH: Integer;
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

implementation

uses
  System.SysUtils, System.UITypes, PPG.Render.Gdi;

var
  // Audit 8d #7: ein Speicher-DC fuer alle Layouts (nur Hauptthread, wie
  // GCache in PPG.Markup.Parser); vorher ein neuer DC je Layout-Aufruf
  GMeasureDC: HDC = 0;

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
  FBaseValid := False;
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
  LF: TLogFont;
  OwnDC: Boolean;

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
  // Audit 8d #7: Stil-Schriften und Zeilenhoehe behalten, solange die
  // Grundschrift gleich bleibt (Listen, Kanban, Hints messen sonst je Text neu)
  FillChar(LF, SizeOf(LF), 0);
  if (GetObject(Font.Handle, SizeOf(LF), @LF) = 0) or not FBaseValid or
    not CompareMem(@LF, @FBaseLF, SizeOf(LF)) then
  begin
    ResetFonts;
    FBaseFont.Assign(Font);
    FBaseLF := LF;
    FBaseValid := True;
    FTextH := -1;
  end;
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

  if GMeasureDC = 0 then
    GMeasureDC := CreateCompatibleDC(0);
  DC := GMeasureDC;
  OwnDC := DC = 0;
  if OwnDC then
    DC := CreateCompatibleDC(0);
  try
    if FTextH < 0 then
      FTextH := PPGGdiMeasureText(DC, 'Wg', FBaseFont, 0, False).cy;
    TextH := FTextH;
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
    if OwnDC then
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
  if GMeasureDC <> 0 then
    DeleteDC(GMeasureDC);
  GMeasureDC := 0;

end.
