unit PPG.Selection;

{ TPPGSelection - Auswahl in Listen, Baeumen und Grids (gemeinsam genutzt).

  Modi wie Windows-Listen:
  - smSingle   : genau ein gewaehlter Eintrag = Fokus-Eintrag
  - smMulti    : Klick schaltet um (wie LBS_MULTIPLESEL / TListBox.MultiSelect
                 ohne ExtendedSelect)
  - smExtended : Klick waehlt allein, Strg+Klick schaltet um, Umschalt+Klick
                 waehlt den Bereich vom Anker, Strg+Umschalt erweitert
                 (wie Explorer / TListBox mit ExtendedSelect)

  Fokus-Eintrag (Rahmen) und Auswahl sind getrennt: Strg+Pfeil bewegt nur den
  Fokus, Strg+Leertaste schaltet ihn um. Speicher: TBits, also 1 Bit pro
  Eintrag (1 000 000 Eintraege = 125 KB). Einfuegen/Loeschen verschiebt die
  Auswahl mit. OnChange kommt einmal pro Aktion (BeginUpdate/EndUpdate). }

{$I ..\PPG.inc}

interface

uses
  System.Classes;

type
  TPPGSelectMode = (smSingle, smMulti, smExtended);

  TPPGSelection = class
  private
    FCount: Integer;
    FMode: TPPGSelectMode;
    FBits: TBits;
    FSelCount: Integer;
    FSingle: Integer; // Audit 8d #9: Stelle des einzigen gewaehlten Eintrags (-1 = unbekannt)
    FFocus: Integer;
    FAnchor: Integer;
    FUpdateCount: Integer;
    FChanged: Boolean;
    FOnChange: TNotifyEvent;
    procedure SetCount(const Value: Integer);
    procedure SetMode(const Value: TPPGSelectMode);
    function GetSelected(Index: Integer): Boolean;
    procedure SetSelected(Index: Integer; const Value: Boolean);
    procedure SetFocus(const Value: Integer);
    procedure Changed;
    procedure DoSelect(Index: Integer; Value: Boolean);
    procedure DoClear;
    function Valid(Index: Integer): Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginUpdate;
    procedure EndUpdate;
    /// Mausklick auf Index mit den gedrueckten Umschalttasten.
    procedure Click(Index: Integer; Shift: TShiftState);
    /// Tastatur: Fokus auf Index (Umschalt erweitert, Strg bewegt nur den Fokus).
    procedure MoveTo(Index: Integer; Shift: TShiftState);
    /// Strg+Leertaste bzw. Leertaste im Multi-Modus: Fokus-Eintrag umschalten.
    procedure ToggleFocused;
    procedure SelectAll;
    procedure Clear;
    /// Bereich A..B waehlen; Keep = bisherige Auswahl behalten.
    procedure SelectRange(A, B: Integer; Keep: Boolean);
    /// Erster gewaehlter Eintrag ab From, -1 = keiner.
    function NextSelected(From: Integer): Integer;
    /// Wie TListBox.ItemIndex: im Single-Modus der gewaehlte, sonst der Fokus.
    function ItemIndex: Integer;
    procedure ItemsInserted(Index, ACount: Integer);
    procedure ItemsDeleted(Index, ACount: Integer);
    property Count: Integer read FCount write SetCount;
    property Mode: TPPGSelectMode read FMode write SetMode;
    property Selected[Index: Integer]: Boolean read GetSelected write SetSelected; default;
    property SelCount: Integer read FSelCount;
    property Focus: Integer read FFocus write SetFocus;
    property Anchor: Integer read FAnchor;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  System.SysUtils;

{ TPPGSelection }

constructor TPPGSelection.Create;
begin
  inherited Create;
  FBits := TBits.Create;
  FFocus := -1;
  FSingle := -1;
  FAnchor := -1;
end;

destructor TPPGSelection.Destroy;
begin
  FreeAndNil(FBits);
  inherited Destroy;
end;

function TPPGSelection.Valid(Index: Integer): Boolean;
begin
  Result := (Index >= 0) and (Index < FCount);
end;

procedure TPPGSelection.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TPPGSelection.EndUpdate;
begin
  if FUpdateCount > 0 then
    Dec(FUpdateCount);
  if (FUpdateCount = 0) and FChanged then
  begin
    FChanged := False;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TPPGSelection.Changed;
begin
  FChanged := True;
  if FUpdateCount = 0 then
  begin
    FChanged := False;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TPPGSelection.DoSelect(Index: Integer; Value: Boolean);
begin
  if not Valid(Index) or (FBits[Index] = Value) then
    Exit;
  FBits[Index] := Value;
  if Value then
  begin
    Inc(FSelCount);
    if FSelCount = 1 then
      FSingle := Index
    else
      FSingle := -1;
  end
  else
  begin
    Dec(FSelCount);
    FSingle := -1; // welcher bleibt, sucht NextSelected bei Bedarf
  end;
  FChanged := True;
end;

procedure TPPGSelection.DoClear;
begin
  if FSelCount = 0 then
    Exit;
  FBits.Size := 0;
  FBits.Size := FCount;
  FSelCount := 0;
  FSingle := -1;
  FChanged := True;
end;

procedure TPPGSelection.SetCount(const Value: Integer);
var
  I, N: Integer;
begin
  N := Value;
  if N < 0 then
    N := 0;
  if N = FCount then
    Exit;
  BeginUpdate;
  try
    // Wegfallende gewaehlte Eintraege abziehen
    // TBits loescht beim Verkleinern innerhalb eines Speicherworts nicht:
    // Bits selbst loeschen, sonst tauchen sie beim Vergroessern wieder auf
    for I := N to FCount - 1 do
      if FBits[I] then
      begin
        FBits[I] := False;
        Dec(FSelCount);
        FChanged := True;
      end;
    FCount := N;
    FBits.Size := FCount;
    if FSingle >= FCount then
      FSingle := -1;
    if FFocus >= FCount then
    begin
      FFocus := FCount - 1;
      FChanged := True;
    end;
    if FAnchor >= FCount then
      FAnchor := FCount - 1;
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.SetMode(const Value: TPPGSelectMode);
var
  F: Integer;
begin
  if FMode = Value then
    Exit;
  FMode := Value;
  if FMode = smSingle then
  begin
    // Beim Wechsel auf Single bleibt hoechstens der Fokus gewaehlt
    BeginUpdate;
    try
      F := FFocus;
      if Valid(F) and FBits[F] then
      begin
        DoClear;
        DoSelect(F, True);
      end
      else if FSelCount > 1 then
        DoClear;
    finally
      EndUpdate;
    end;
  end;
end;

function TPPGSelection.GetSelected(Index: Integer): Boolean;
begin
  Result := Valid(Index) and FBits[Index];
end;

procedure TPPGSelection.SetSelected(Index: Integer; const Value: Boolean);
begin
  if not Valid(Index) then
    Exit;
  BeginUpdate;
  try
    if Value and (FMode = smSingle) then
    begin
      DoClear;
      FFocus := Index;
      FAnchor := Index;
    end;
    DoSelect(Index, Value);
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.SetFocus(const Value: Integer);
begin
  if not Valid(Value) and (Value <> -1) then
    Exit;
  if FFocus <> Value then
  begin
    FFocus := Value;
    Changed;
  end;
end;

procedure TPPGSelection.SelectRange(A, B: Integer; Keep: Boolean);
var
  I, T: Integer;
begin
  if FCount = 0 then
    Exit;
  if A > B then
  begin
    T := A;
    A := B;
    B := T;
  end;
  if A < 0 then
    A := 0;
  if B > FCount - 1 then
    B := FCount - 1;
  BeginUpdate;
  try
    if not Keep then
      DoClear;
    if FMode = smSingle then
      DoSelect(B, True)
    else
      for I := A to B do
        DoSelect(I, True);
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.Click(Index: Integer; Shift: TShiftState);
begin
  if not Valid(Index) then
    Exit;
  BeginUpdate;
  try
    case FMode of
      smSingle:
        begin
          DoClear;
          DoSelect(Index, True);
          FAnchor := Index;
        end;
      smMulti:
        begin
          DoSelect(Index, not FBits[Index]);
          FAnchor := Index;
        end;
      smExtended:
        if (ssShift in Shift) and Valid(FAnchor) then
          // Bereich vom Anker; mit Strg bleibt die uebrige Auswahl bestehen
          SelectRange(FAnchor, Index, ssCtrl in Shift)
        else if ssCtrl in Shift then
        begin
          DoSelect(Index, not FBits[Index]);
          FAnchor := Index;
        end
        else
        begin
          DoClear;
          DoSelect(Index, True);
          FAnchor := Index;
        end;
    end;
    if FFocus <> Index then
    begin
      FFocus := Index;
      FChanged := True;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.MoveTo(Index: Integer; Shift: TShiftState);
begin
  if FCount = 0 then
    Exit;
  if Index < 0 then
    Index := 0;
  if Index > FCount - 1 then
    Index := FCount - 1;
  BeginUpdate;
  try
    case FMode of
      smSingle:
        begin
          DoClear;
          DoSelect(Index, True);
          FAnchor := Index;
        end;
      smMulti:
        ; // Fokus wandert, Auswahl per Leertaste
      smExtended:
        if (ssShift in Shift) then
        begin
          if not Valid(FAnchor) then
            FAnchor := Index;
          SelectRange(FAnchor, Index, ssCtrl in Shift);
        end
        else if not (ssCtrl in Shift) then
        begin
          DoClear;
          DoSelect(Index, True);
          FAnchor := Index;
        end;
    end;
    if FFocus <> Index then
    begin
      FFocus := Index;
      FChanged := True;
    end;
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.ToggleFocused;
begin
  if not Valid(FFocus) then
    Exit;
  BeginUpdate;
  try
    if FMode = smSingle then
      DoSelect(FFocus, True)
    else
      DoSelect(FFocus, not FBits[FFocus]);
    FAnchor := FFocus;
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.SelectAll;
var
  I: Integer;
begin
  if (FMode = smSingle) or (FCount = 0) then
    Exit;
  BeginUpdate;
  try
    for I := 0 to FCount - 1 do
      DoSelect(I, True);
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.Clear;
begin
  BeginUpdate;
  try
    DoClear;
  finally
    EndUpdate;
  end;
end;

function TPPGSelection.NextSelected(From: Integer): Integer;
var
  I: Integer;
begin
  if From < 0 then
    From := 0;
  // Audit 8d #9: ein einziger gewaehlter Eintrag (Single-Modus) ohne Durchlauf
  if FSelCount = 1 then
  begin
    if FSingle < 0 then
      for I := 0 to FCount - 1 do
        if FBits[I] then
        begin
          FSingle := I;
          Break;
        end;
    if FSingle >= From then
      Result := FSingle
    else
      Result := -1;
    Exit;
  end;
  if FSelCount > 0 then
    for I := From to FCount - 1 do
      if FBits[I] then
        Exit(I);
  Result := -1;
end;

function TPPGSelection.ItemIndex: Integer;
begin
  if FMode = smSingle then
    Result := NextSelected(0)
  else
    Result := FFocus;
end;

procedure TPPGSelection.ItemsInserted(Index, ACount: Integer);
var
  I: Integer;
begin
  if ACount <= 0 then
    Exit;
  if (Index < 0) or (Index > FCount) then
    Index := FCount;
  // Audit 8d #9: ohne bzw. mit genau einem bekannten gewaehlten Eintrag nur
  // die Groesse aendern (statt jedes Bit ab Index zu verschieben)
  if FSelCount = 1 then
    NextSelected(0); // FSingle bestimmen
  BeginUpdate;
  try
    FBits.Size := FCount + ACount;
    if FSelCount = 1 then
    begin
      if FSingle >= Index then
      begin
        FBits[FSingle] := False;
        Inc(FSingle, ACount);
        FBits[FSingle] := True;
      end;
    end
    else if FSelCount > 0 then
    begin
      // Bits ab Index nach hinten schieben
      for I := FCount - 1 downto Index do
        FBits[I + ACount] := FBits[I];
      for I := Index to Index + ACount - 1 do
        FBits[I] := False;
    end;
    Inc(FCount, ACount);
    if FFocus >= Index then
      Inc(FFocus, ACount);
    if FAnchor >= Index then
      Inc(FAnchor, ACount);
    FChanged := True;
  finally
    EndUpdate;
  end;
end;

procedure TPPGSelection.ItemsDeleted(Index, ACount: Integer);
var
  I: Integer;
begin
  if (ACount <= 0) or not Valid(Index) then
    Exit;
  if Index + ACount > FCount then
    ACount := FCount - Index;
  if FSelCount = 1 then
    NextSelected(0); // FSingle bestimmen
  BeginUpdate;
  try
    if FSelCount = 1 then
    begin
      // Audit 8d #9: nur das eine Bit verschieben bzw. loeschen
      FBits[FSingle] := False;
      if FSingle >= Index + ACount then
      begin
        Dec(FSingle, ACount);
        FBits[FSingle] := True;
      end
      else if FSingle >= Index then
      begin
        FSelCount := 0;
        FSingle := -1;
      end
      else
        FBits[FSingle] := True;
    end
    else if FSelCount > 0 then
    begin
      for I := Index to Index + ACount - 1 do
        if FBits[I] then
          Dec(FSelCount);
      for I := Index to FCount - ACount - 1 do
        FBits[I] := FBits[I + ACount];
      for I := FCount - ACount to FCount - 1 do
        FBits[I] := False; // siehe SetCount
      FSingle := -1;
    end;
    Dec(FCount, ACount);
    FBits.Size := FCount;
    // Fokus: im geloeschten Bereich -> auf den Nachfolger (bzw. letzten)
    if FFocus >= Index + ACount then
      Dec(FFocus, ACount)
    else if FFocus >= Index then
    begin
      FFocus := Index;
      if FFocus > FCount - 1 then
        FFocus := FCount - 1;
    end;
    if FAnchor >= Index + ACount then
      Dec(FAnchor, ACount)
    else if FAnchor >= Index then
      FAnchor := FFocus;
    FChanged := True;
  finally
    EndUpdate;
  end;
end;

end.
