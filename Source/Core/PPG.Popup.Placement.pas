unit PPG.Popup.Placement;

{ Platzierung von Popups (Phase 11a) - reine Rechnung, ohne Fenster testbar.

  Eine einzige Stelle fuer ComboBox-Liste, DatePicker, Menues, Untermenues,
  Hints und TeachingTips:
  - Seiten unten/oben (Listen, Kontextmenue am Punkt, Menueleiste) und
    rechts/links (Untermenue, Sprechblase).
  - Reicht der Platz auf der bevorzugten Seite nicht und ist gegenueber mehr
    Platz, wird gekippt. Danach wird in die Arbeitsflaeche geklemmt.
  - Anker als Punkt (Breite 0, Kontextmenue): links nicht klemmen, sondern
    wie Windows nach links aufklappen.
  - AlignEnd: am Ende des Ankers ausrichten (rechtsbuendig bzw. bei RTL die
    natuerliche Richtung); der Aufrufer entscheidet, was "Ende" ist. }

{$I ..\PPG.inc}

interface

uses
  System.Types;

type
  TPPGPopupSide = (ppsBelow, ppsAbove, ppsRight, ppsLeft);

  TPPGPlacement = record
    Bounds: TRect;          // Fenster in Bildschirmkoordinaten
    Side: TPPGPopupSide;    // tatsaechlich gewaehlte Seite
    Clipped: Boolean;       // Hoehe wurde gekuerzt (Inhalt muss scrollen)
  end;

/// Rechteck fuer ein Popup der Groesse W x H am Anker.
/// ClampHeight: bei unten/oben die Hoehe auf den Platz der Seite kuerzen
/// (Listen, Menues); sonst nur in die Arbeitsflaeche schieben.
function PPGPlacePopup(const Anchor: TRect; W, H: Integer; Preferred: TPPGPopupSide;
  const WorkArea: TRect; AlignEnd, ClampHeight: Boolean): TPPGPlacement;

type
  /// Sprechblase mit Pfeil (TeachingTip): Lage zum Anker.
  TPPGTipPlacement = record
    Bounds: TRect;          // Fenster inkl. Pfeil, Bildschirmkoordinaten
    Side: TPPGPopupSide;    // Seite der Blase (ppsAbove = ueber dem Anker, Pfeil unten)
    TailPos: Integer;       // Mitte des Pfeils entlang der Kante, relativ zu Bounds
  end;

/// Gegenseite (unten <-> oben, rechts <-> links).
function PPGOppositeSide(Side: TPPGPopupSide): TPPGPopupSide;

/// Platz fuer eine Sprechblase W x H (ohne Pfeil) am Anker, mittig zum Anker.
/// Tail = Laenge des Pfeils, EdgeMargin = kleinster Abstand der Pfeilmitte zur
/// Ecke. Auto: oben, unten, links, rechts - die erste Seite, auf die sie ganz
/// passt (wie WinUI); sonst Preferred bzw. deren Gegenseite.
function PPGPlaceTip(const Anchor: TRect; W, H, Tail, EdgeMargin: Integer;
  Preferred: TPPGPopupSide; Auto: Boolean; const WorkArea: TRect): TPPGTipPlacement;

implementation

function PPGOppositeSide(Side: TPPGPopupSide): TPPGPopupSide;
begin
  case Side of
    ppsBelow: Result := ppsAbove;
    ppsAbove: Result := ppsBelow;
    ppsRight: Result := ppsLeft;
  else
    Result := ppsRight;
  end;
end;

function Space(const Anchor, WA: TRect; Side: TPPGPopupSide): Integer;
begin
  case Side of
    ppsBelow: Result := WA.Bottom - Anchor.Bottom;
    ppsAbove: Result := Anchor.Top - WA.Top;
    ppsRight: Result := WA.Right - Anchor.Right;
  else
    Result := Anchor.Left - WA.Left;
  end;
end;

function PPGPlacePopup(const Anchor: TRect; W, H: Integer; Preferred: TPPGPopupSide;
  const WorkArea: TRect; AlignEnd, ClampHeight: Boolean): TPPGPlacement;
var
  Side: TPPGPopupSide;
  Need, Avail, X, Y, WAW, WAH: Integer;
  IsPoint: Boolean;
begin
  WAW := WorkArea.Right - WorkArea.Left;
  WAH := WorkArea.Bottom - WorkArea.Top;
  if W > WAW then
    W := WAW;
  if H > WAH then
    H := WAH;
  if W < 1 then
    W := 1;
  if H < 1 then
    H := 1;
  Result.Clipped := False;
  IsPoint := Anchor.Right <= Anchor.Left;

  // Seite: bevorzugt, sonst die Gegenseite, wenn dort mehr Platz ist
  Side := Preferred;
  if Side in [ppsBelow, ppsAbove] then
    Need := H
  else
    Need := W;
  if (Space(Anchor, WorkArea, Side) < Need) and
    (Space(Anchor, WorkArea, PPGOppositeSide(Side)) > Space(Anchor, WorkArea, Side)) then
    Side := PPGOppositeSide(Side);
  Result.Side := Side;

  if Side in [ppsBelow, ppsAbove] then
  begin
    Avail := Space(Anchor, WorkArea, Side);
    if ClampHeight and (H > Avail) and (Avail > 0) then
    begin
      H := Avail;
      Result.Clipped := True;
    end;
    if Side = ppsBelow then
      Y := Anchor.Bottom
    else
      Y := Anchor.Top - H;
    if AlignEnd then
      X := Anchor.Right - W
    else
      X := Anchor.Left;
    // Waagerecht: ein Punkt-Anker klappt zur anderen Seite auf (wie Windows)
    if X + W > WorkArea.Right then
    begin
      if IsPoint and (Anchor.Left - W >= WorkArea.Left) then
        X := Anchor.Left - W
      else
        X := WorkArea.Right - W;
    end;
    if X < WorkArea.Left then
    begin
      if IsPoint and (Anchor.Left + W <= WorkArea.Right) then
        X := Anchor.Left
      else
        X := WorkArea.Left;
    end;
  end
  else
  begin
    // Rechts/links: oben buendig mit dem Anker (Untermenue), nach oben schieben
    if Side = ppsRight then
      X := Anchor.Right
    else
      X := Anchor.Left - W;
    if X + W > WorkArea.Right then
      X := WorkArea.Right - W;
    if X < WorkArea.Left then
      X := WorkArea.Left;
    if AlignEnd then
      Y := Anchor.Bottom - H
    else
      Y := Anchor.Top;
  end;
  if Y + H > WorkArea.Bottom then
    Y := WorkArea.Bottom - H;
  if Y < WorkArea.Top then
    Y := WorkArea.Top;
  Result.Bounds := Rect(X, Y, X + W, Y + H);
end;


function TipFits(const Anchor, WA: TRect; W, H, Tail: Integer; Side: TPPGPopupSide): Boolean;
begin
  case Side of
    ppsBelow: Result := (WA.Bottom - Anchor.Bottom >= H + Tail) and (W <= WA.Right - WA.Left);
    ppsAbove: Result := (Anchor.Top - WA.Top >= H + Tail) and (W <= WA.Right - WA.Left);
    ppsRight: Result := (WA.Right - Anchor.Right >= W + Tail) and (H <= WA.Bottom - WA.Top);
  else
    Result := (Anchor.Left - WA.Left >= W + Tail) and (H <= WA.Bottom - WA.Top);
  end;
end;

function PPGPlaceTip(const Anchor: TRect; W, H, Tail, EdgeMargin: Integer;
  Preferred: TPPGPopupSide; Auto: Boolean; const WorkArea: TRect): TPPGTipPlacement;
const
  AutoOrder: array[0..3] of TPPGPopupSide = (ppsAbove, ppsBelow, ppsLeft, ppsRight);
var
  Side: TPPGPopupSide;
  I, FW, FH, X, Y, C, Len: Integer;
  Found: Boolean;
begin
  if W < 1 then
    W := 1;
  if H < 1 then
    H := 1;
  Side := Preferred;
  Found := False;
  if Auto then
    for I := 0 to High(AutoOrder) do
      if TipFits(Anchor, WorkArea, W, H, Tail, AutoOrder[I]) then
      begin
        Side := AutoOrder[I];
        Found := True;
        Break;
      end;
  if not Found then
  begin
    if Auto then
      Side := ppsBelow;
    if not TipFits(Anchor, WorkArea, W, H, Tail, Side) and
      (Space(Anchor, WorkArea, PPGOppositeSide(Side)) > Space(Anchor, WorkArea, Side)) then
      Side := PPGOppositeSide(Side);
  end;
  Result.Side := Side;
  if Side in [ppsBelow, ppsAbove] then
  begin
    FW := W;
    FH := H + Tail;
    C := (Anchor.Left + Anchor.Right) div 2;
    X := C - FW div 2;
    if Side = ppsBelow then
      Y := Anchor.Bottom
    else
      Y := Anchor.Top - FH;
  end
  else
  begin
    FW := W + Tail;
    FH := H;
    C := (Anchor.Top + Anchor.Bottom) div 2;
    Y := C - FH div 2;
    if Side = ppsRight then
      X := Anchor.Right
    else
      X := Anchor.Left - FW;
  end;
  // In die Arbeitsflaeche schieben (der Pfeil zeigt weiter auf den Anker)
  if X + FW > WorkArea.Right then
    X := WorkArea.Right - FW;
  if X < WorkArea.Left then
    X := WorkArea.Left;
  if Y + FH > WorkArea.Bottom then
    Y := WorkArea.Bottom - FH;
  if Y < WorkArea.Top then
    Y := WorkArea.Top;
  Result.Bounds := Rect(X, Y, X + FW, Y + FH);
  if Side in [ppsBelow, ppsAbove] then
  begin
    Len := FW;
    Result.TailPos := C - X;
  end
  else
  begin
    Len := FH;
    Result.TailPos := C - Y;
  end;
  if EdgeMargin * 2 > Len then
    EdgeMargin := Len div 2;
  if Result.TailPos < EdgeMargin then
    Result.TailPos := EdgeMargin;
  if Result.TailPos > Len - EdgeMargin then
    Result.TailPos := Len - EdgeMargin;
end;

end.
