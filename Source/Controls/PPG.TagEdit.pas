unit PPG.TagEdit;

{ TPPGTagEdit - Stichwoerter als Chips (Phase 12f, Vorbild Outlook-Empfaenger,
  WinUI TokenizingTextBox).

  - Chips (Text mit x) vor dem Eingabebereich, Umbruch ueber mehrere Zeilen;
    mit AutoSize waechst die Hoehe mit. Das Layout wird nur bei Aenderung der
    Tags, der Breite oder der Schrift berechnet (nicht je Tastendruck).
  - Ein Tag entsteht mit Enter, mit einem der Delimiters (";" ",") oder beim
    Verlassen (AddOnExit). Eingefuegtes "a; b; c" ergibt drei Tags.
  - Ruecktaste im leeren Feld markiert zuerst das letzte Tag und loescht es
    beim zweiten Druck (wie Outlook); Pfeil links/rechts wandert zwischen den
    Chips, Entf loescht das markierte.
  - Vorschlaege (Suggestions) im Aufklapp-Fenster waehrend des Tippens;
    AllowNew = False erlaubt nur Vorschlaege. MaxTags, CaseSensitive, keine
    Doppelten.
  - Ereignisse nur bei Anwenderaktionen: OnTagAdding (abbrechbar, Text
    aenderbar - z.B. E-Mail pruefen), OnTagRemoved, OnTagClick, OnChange.
    Tags aus Code (Tags.Add, TagsText) loesen nichts aus.
  - Screenreader: Chips als Kinder, Standardaktion Entfernen. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.Variants, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Accessibility, PPG.Controls.Base, PPG.Controls.Field,
  PPG.Controls.DropDown, PPG.Popup, PPG.RowPopup;

type
  TPPGTagAddingEvent = procedure(Sender: TObject; var Tag: string; var Allow: Boolean) of object;
  TPPGTagEvent = procedure(Sender: TObject; const Tag: string) of object;

  TPPGTagEdit = class;

  TPPGTagSuggestPopup = class(TPPGRowPopup)
  private
    FEdit: TPPGTagEdit;
    FRows: TStringList;
  protected
    function RowCount: Integer; override;
    procedure PaintRow(const ACanvas: IPPGCanvas; Index: Integer; const R: TRect;
      const ListStyle, HighlightStyle: TPPGSurfaceStyle; Hot, Focused: Boolean); override;
    function RowActivate(Index: Integer; ByMouse: Boolean; X: Integer): TPPGDropAction; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Vorschlaege zum Text; False = keine.
    function Fill(AEdit: TPPGTagEdit; const Text: string): Boolean;
    function RowText(Index: Integer): string;
  end;

  TPPGTagEdit = class(TPPGCustomDropDownField, IPPGFieldValue, IPPGAccessibleChildren)
  private
    FTags: TStrings;
    // Zaehlt jede Aenderung der Tags; gepostete Aktionen pruefen damit, ob
    // der Index noch denselben Tag meint
    FTagsVersion: Cardinal;
    FSuggestions: TStrings;
    FDelimiters: string;
    FDelimiter: Char;
    FAllowNew: Boolean;
    FAllowDuplicates: Boolean;
    FCaseSensitive: Boolean;
    FMaxTags: Integer;
    FAddOnExit: Boolean;
    FSelectedTag: Integer;
    FHotTag: Integer;
    FHotCross: Boolean;
    FChipRects: TArray<TRect>;
    FLines: Integer;
    FLayoutWidth: Integer;
    FLayoutValid: Boolean;
    FInChange: Boolean;
    FOnTagAdding: TPPGTagAddingEvent;
    FOnTagRemoved: TPPGTagEvent;
    FOnTagClick: TPPGTagEvent;
    procedure SetDelimiter(const Value: Char);
    procedure ReadDelimitersEmpty(Reader: TReader);
    procedure WriteDelimitersEmpty(Writer: TWriter);
    function IsDelimitersStored: Boolean;
    procedure SetTags(const Value: TStrings);
    procedure SetSuggestions(const Value: TStrings);
    procedure TagsChanged(Sender: TObject);
    function GetTagsText: string;
    procedure SetTagsText(const Value: string);
    procedure SetMaxTags(const Value: Integer);
    procedure SetSelectedTag(Value: Integer);
    function ChipHeight: Integer;
    function ChipGap: Integer;
    function ChipWidth(const S: string): Integer;
    function CrossRect(const Chip: TRect): TRect;
    procedure LayoutChips(const Area: TRect; out InnerRect: TRect);
    function TextArea: TRect;
    function ChipAt(X, Y: Integer; out OnCross: Boolean): Integer;
    procedure UpdateSuggestions;
    function IsDelimiter(C: Char): Boolean;
    procedure WMRemoveTag(var Message: TMessage); message WM_USER + $540;
  protected
    procedure DefineProperties(Filer: TFiler); override;
    function CreatePopup: TPPGDropPopup; override;
    procedure PreparePopup(APopup: TPPGDropPopup); override;
    procedure AcceptPopup(APopup: TPPGDropPopup); override;
    function ButtonVisible(Id: Integer): Boolean; override;
    procedure AdjustInnerBounds(var R: TRect); override;
    function CalcAutoSize(out AWidth, AHeight: Integer): Boolean; override;
    procedure Resize; override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    procedure FieldKeyPress(var Key: Char); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    /// Tags vom Anwender geaendert: OnChange (DB-Variante haengt sich ein).
    procedure DoTagsChange; virtual;
    procedure Change; override;
    procedure FocusChanged; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle); override;
    function AccRole: Integer; override;
    function AccValue: string; override;
    { IPPGFieldValue }
    function FieldIsNull: Boolean;
    procedure FieldClear;
    function GetFieldValue: Variant;
    procedure SetFieldValue(const Value: Variant);
    { IPPGAccessibleChildren }
    function AccChildCount: Integer;
    function AccChildName(Id: Integer): string;
    function AccChildRole(Id: Integer): Integer;
    function AccChildState(Id: Integer): Integer;
    function AccChildRect(Id: Integer): TRect;
    function AccChildAt(X, Y: Integer): Integer;
    function AccChildDefaultAction(Id: Integer): string;
    procedure AccChildDoDefault(Id: Integer);
    function AccFocusedChild: Integer;
    function AccSelectedChild: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    /// Anwender fuegt hinzu (OnTagAdding, OnChange). False = abgelehnt.
    function AddTag(const S: string): Boolean;
    /// Anwender entfernt (OnTagRemoved, OnChange).
    procedure RemoveTag(Index: Integer);
    /// Aktuelle Eingabe als Tag(s) uebernehmen (wie Enter).
    function CommitText: Boolean;
    function IndexOfTag(const S: string): Integer;
    /// Rechteck eines Chips (Client-Koordinaten).
    function ChipRect(Index: Integer): TRect;
    /// Zeilen der Chip-Anordnung.
    function LineCount: Integer;
    /// Markiertes Tag (Ruecktaste/Pfeile), -1 = keins.
    property SelectedTag: Integer read FSelectedTag write SetSelectedTag;
    /// Tags getrennt durch Delimiter (aus Code ohne Ereignisse).
    property TagsText: string read GetTagsText write SetTagsText;
  published
    property Tags: TStrings read FTags write SetTags;
    property Suggestions: TStrings read FSuggestions write SetSuggestions;
    /// Zeichen, die ein Tag beenden.
    property InputDelimiters: string read FDelimiters write FDelimiters stored IsDelimitersStored;
    /// Trenner fuer TagsText (DB-Wert).
    property Delimiter: Char read FDelimiter write SetDelimiter default ';';
    property AllowNew: Boolean read FAllowNew write FAllowNew default True;
    property AllowDuplicates: Boolean read FAllowDuplicates write FAllowDuplicates default False;
    property CaseSensitive: Boolean read FCaseSensitive write FCaseSensitive default False;
    /// 0 = ohne Grenze.
    property MaxTags: Integer read FMaxTags write SetMaxTags default 0;
    property AddOnExit: Boolean read FAddOnExit write FAddOnExit default True;
    property OnTagAdding: TPPGTagAddingEvent read FOnTagAdding write FOnTagAdding;
    property OnTagRemoved: TPPGTagEvent read FOnTagRemoved write FOnTagRemoved;
    property OnTagClick: TPPGTagEvent read FOnTagClick write FOnTagClick;
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ReadOnly;
    property ReadOnlyStyle;
    property ShowHint;
    {$IFDEF PPG_HAS_STYLEELEMENTS}
    property StyleElements;
    {$ENDIF}
    property TabOrder;
    property TabStop;
    property Visible;
    property Touch;
    property OnGesture;
    property OnChange;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

implementation

uses
  System.Math, Winapi.oleacc, PPG.Appearance, PPG.Tokens, PPG.DpiUtils, PPG.Lang,
  PPG.Consts, PPG.Exceptions, PPG.Render.Gdi, PPG.Render.Registry;

const
  DefDelimiters = ';,';
  WM_REMOVETAG = WM_USER + $540;
  MinInnerWidth = 60; // logische px fuer die Eingabe hinter dem letzten Chip

type
  TEditAccess = class(TCustomEdit);

{ TPPGTagSuggestPopup }

constructor TPPGTagSuggestPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRows := TStringList.Create;
end;

destructor TPPGTagSuggestPopup.Destroy;
begin
  FreeAndNil(FRows);
  inherited Destroy;
end;

function TPPGTagSuggestPopup.Fill(AEdit: TPPGTagEdit; const Text: string): Boolean;
var
  I: Integer;
  T, S: string;
begin
  FEdit := AEdit;
  FRows.Clear;
  T := AnsiLowerCase(Trim(Text));
  if T <> '' then
    for I := 0 to AEdit.Suggestions.Count - 1 do
    begin
      S := AEdit.Suggestions[I];
      if (Pos(T, AnsiLowerCase(S)) > 0) and (AEdit.FAllowDuplicates or
        (AEdit.IndexOfTag(S) < 0)) then
        FRows.Add(S);
    end;
  Result := FRows.Count > 0;
end;

function TPPGTagSuggestPopup.RowCount: Integer;
begin
  Result := FRows.Count;
end;

function TPPGTagSuggestPopup.RowText(Index: Integer): string;
begin
  Result := FRows[Index];
end;

procedure TPPGTagSuggestPopup.PaintRow(const ACanvas: IPPGCanvas; Index: Integer;
  const R: TRect; const ListStyle, HighlightStyle: TPPGSurfaceStyle; Hot, Focused: Boolean);
var
  C: TColor;
begin
  if Hot then
    C := HighlightStyle.TextColor
  else
    C := ListStyle.TextColor;
  ACanvas.DrawText(Rect(R.Left + PPGScale(10, ScalePPI), R.Top, R.Right - PPGScale(6, ScalePPI),
    R.Bottom), FRows[Index], Font, C,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
end;

function TPPGTagSuggestPopup.RowActivate(Index: Integer; ByMouse: Boolean;
  X: Integer): TPPGDropAction;
begin
  Result := pdaAccept;
end;

{ TPPGTagEdit }

procedure TPPGTagEdit.DefineProperties(Filer: TFiler);
begin
  inherited DefineProperties(Filer);
  // Leer mit nicht leerer Vorgabe: der Writer schreibt '' nie - eigene Marke
  Filer.DefineProperty('InputDelimitersEmpty', ReadDelimitersEmpty, WriteDelimitersEmpty, FDelimiters = '');
end;

procedure TPPGTagEdit.ReadDelimitersEmpty(Reader: TReader);
begin
  if Reader.ReadBoolean then
    FDelimiters := '';
end;

procedure TPPGTagEdit.WriteDelimitersEmpty(Writer: TWriter);
begin
  Writer.WriteBoolean(True);
end;

procedure TPPGTagEdit.SetDelimiter(const Value: Char);
begin
  // Steuerzeichen (#0, Tab, Zeilenende) trennen keine Tags im Text
  if Value < ' ' then
  begin
    if not PPGIsLoading(Self) then
      raise EPPGPropertyError.CreateInvalid(Self, 'Delimiter', IntToStr(Ord(Value)));
    Exit;
  end;
  FDelimiter := Value;
end;

function TPPGTagEdit.IsDelimitersStored: Boolean;
begin
  // Auch leer speichern (Vorgabe ';,')
  Result := FDelimiters <> DefDelimiters;
end;

constructor TPPGTagEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTags := TStringList.Create;
  TStringList(FTags).OnChange := TagsChanged;
  FSuggestions := TStringList.Create;
  FDelimiters := DefDelimiters;
  FDelimiter := ';';
  FAllowNew := True;
  FAddOnExit := True;
  FSelectedTag := -1;
  FHotTag := -1;
end;

destructor TPPGTagEdit.Destroy;
begin
  FreeAndNil(FTags);
  FreeAndNil(FSuggestions);
  inherited Destroy;
end;

procedure TPPGTagEdit.SetTags(const Value: TStrings);
begin
  FTags.Assign(Value);
end;

procedure TPPGTagEdit.SetSuggestions(const Value: TStrings);
begin
  FSuggestions.Assign(Value);
end;

procedure TPPGTagEdit.TagsChanged(Sender: TObject);
begin
  Inc(FTagsVersion);
  FLayoutValid := False;
  if FSelectedTag >= FTags.Count then
    FSelectedTag := -1;
  FHotTag := -1;
  if not (csLoading in ComponentState) then
  begin
    UpdateLayout;
    RequestAutoSize;
  end;
  Invalidate;
end;

procedure TPPGTagEdit.SetMaxTags(const Value: Integer);
begin
  FMaxTags := PPGCheckRange(Self, 'MaxTags', Value, 0, MaxInt);
end;

function TPPGTagEdit.GetTagsText: string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to FTags.Count - 1 do
  begin
    if I > 0 then
      Result := Result + FDelimiter;
    Result := Result + FTags[I];
  end;
end;

procedure TPPGTagEdit.SetTagsText(const Value: string);
var
  Parts: TArray<string>;
  I: Integer;
begin
  FTags.BeginUpdate;
  try
    FTags.Clear;
    Parts := PPGSplitString(Value, FDelimiter, True);
    for I := 0 to High(Parts) do
      if Trim(Parts[I]) <> '' then
        FTags.Add(Trim(Parts[I]));
  finally
    FTags.EndUpdate;
  end;
end;

function TPPGTagEdit.IndexOfTag(const S: string): Integer;
var
  I: Integer;
begin
  for I := 0 to FTags.Count - 1 do
    if (FCaseSensitive and (FTags[I] = S)) or
      (not FCaseSensitive and SameText(FTags[I], S)) then
      Exit(I);
  Result := -1;
end;

function TPPGTagEdit.IsDelimiter(C: Char): Boolean;
begin
  Result := Pos(C, FDelimiters) > 0;
end;

function TPPGTagEdit.AddTag(const S: string): Boolean;
var
  T: string;
  Allow: Boolean;
begin
  Result := False;
  T := Trim(S);
  if (T = '') or ReadOnly or not Enabled then
    Exit;
  if (FMaxTags > 0) and (FTags.Count >= FMaxTags) then
    Exit;
  if not FAllowNew and (FSuggestions.IndexOf(T) < 0) then
    Exit;
  if not FAllowDuplicates and (IndexOfTag(T) >= 0) then
    Exit;
  Allow := True;
  if Assigned(FOnTagAdding) then
    FOnTagAdding(Self, T, Allow);
  if not Allow or (Trim(T) = '') then
    Exit;
  FTags.Add(Trim(T));
  Result := True;
  NotifyAccessibility(EVENT_OBJECT_REORDER);
  DoTagsChange;
end;

procedure TPPGTagEdit.RemoveTag(Index: Integer);
var
  S: string;
begin
  if ReadOnly or not Enabled or (Index < 0) or (Index >= FTags.Count) then
    Exit;
  S := FTags[Index];
  FTags.Delete(Index);
  NotifyAccessibility(EVENT_OBJECT_REORDER);
  if Assigned(FOnTagRemoved) then
    FOnTagRemoved(Self, S);
  DoTagsChange;
end;

procedure TPPGTagEdit.DoTagsChange;
begin
  inherited Change;
end;

function TPPGTagEdit.CommitText: Boolean;
var
  S, Part: string;
  I: Integer;
begin
  S := Text;
  Result := False;
  Part := '';
  // Mehrere Tags auf einmal (eingefuegt "a; b; c")
  for I := 1 to Length(S) do
    if IsDelimiter(S[I]) then
    begin
      if AddTag(Part) then
        Result := True;
      Part := '';
    end
    else
      Part := Part + S[I];
  if AddTag(Part) then
    Result := True;
  // Abgelehnter Rest bleibt stehen, damit der Anwender ihn korrigieren kann
  if Result or (Trim(Part) = '') then
    SetTextSilent('')
  else
    SetTextSilent(Trim(Part));
  UpdateSuggestions;
end;

procedure TPPGTagEdit.Change;
var
  I: Integer;
  HasDelim: Boolean;
begin
  // Tippen: Vorschlaege; ein Trenner im Text (getippt oder eingefuegt) beendet Tags
  if FInChange then
    Exit;
  FSelectedTag := -1;
  HasDelim := False;
  for I := 1 to Length(Text) do
    if IsDelimiter(Text[I]) then
      HasDelim := True;
  if HasDelim then
  begin
    FInChange := True;
    try
      CommitText;
    finally
      FInChange := False;
    end;
    Exit;
  end;
  UpdateSuggestions;
end;

procedure TPPGTagEdit.UpdateSuggestions;
var
  P: TPPGTagSuggestPopup;
begin
  if (csDestroying in ComponentState) or not HandleAllocated or not FieldFocused then
    Exit;
  if FSuggestions.Count = 0 then
    Exit;
  if Popup = nil then
  begin
    // erstes Mal: DropDown legt das Popup an
    if Trim(Text) <> '' then
      DropDown;
    Exit;
  end;
  P := TPPGTagSuggestPopup(Popup);
  if P.Fill(Self, Text) then
  begin
    if DroppedDown then
    begin
      P.ResetView(0);
      P.SetFocusRow(-1);
      P.Invalidate;
    end
    else
      DropDown;
  end
  else if DroppedDown then
    CloseUp(False);
end;

function TPPGTagEdit.CreatePopup: TPPGDropPopup;
begin
  Result := TPPGTagSuggestPopup.Create(Self);
end;

procedure TPPGTagEdit.PreparePopup(APopup: TPPGDropPopup);
var
  P: TPPGTagSuggestPopup;
begin
  P := TPPGTagSuggestPopup(APopup);
  P.MaxRows := 8;
  P.Fill(Self, Text);
  P.ResetView(-1);
end;

procedure TPPGTagEdit.AcceptPopup(APopup: TPPGDropPopup);
var
  P: TPPGTagSuggestPopup;
begin
  P := TPPGTagSuggestPopup(APopup);
  if (P.FocusRow >= 0) and (P.FocusRow < P.RowCount) then
  begin
    if AddTag(P.RowText(P.FocusRow)) then
      SetTextSilent('');
  end;
end;

function TPPGTagEdit.ButtonVisible(Id: Integer): Boolean;
begin
  // Kein Aufklapp-Pfeil: Vorschlaege erscheinen beim Tippen
  if Id = PPGDropButton then
    Result := False
  else
    Result := inherited ButtonVisible(Id);
end;

function TPPGTagEdit.ChipHeight: Integer;
begin
  Result := LineHeight + PPGScale(6, ScalePPI);
end;

function TPPGTagEdit.ChipGap: Integer;
begin
  Result := PPGScale(4, ScalePPI);
end;

function TPPGTagEdit.ChipWidth(const S: string): Integer;
begin
  // Text + Abstand + Kreuz
  Result := PPGMeasureTextNoCanvas(S, Font, 0, False).cx + PPGScale(10, ScalePPI) +
    ChipHeight;
end;

function TPPGTagEdit.CrossRect(const Chip: TRect): TRect;
var
  S: Integer;
begin
  S := Chip.Bottom - Chip.Top;
  Result := Rect(Chip.Right - S, Chip.Top, Chip.Right, Chip.Bottom);
  InflateRect(Result, -PPGScale(4, ScalePPI), -PPGScale(4, ScalePPI));
end;

function TPPGTagEdit.TextArea: TRect;
var
  B: Integer;
begin
  // Wie das Feld: Rahmen + Innenabstand (ohne Buttons; TagEdit hat keine)
  B := PPGScale(1, ScalePPI) + PPGScale(6, ScalePPI);
  Result := Rect(B, PPGScale(4, ScalePPI), Width - B, Height - PPGScale(4, ScalePPI));
end;

procedure TPPGTagEdit.LayoutChips(const Area: TRect; out InnerRect: TRect);
var
  I, X, Y, W, H, Gap, MinW: Integer;
begin
  H := ChipHeight;
  Gap := ChipGap;
  MinW := PPGScale(MinInnerWidth, ScalePPI);
  SetLength(FChipRects, FTags.Count);
  X := Area.Left;
  Y := Area.Top;
  FLines := 1;
  for I := 0 to FTags.Count - 1 do
  begin
    W := Min(ChipWidth(FTags[I]), Area.Right - Area.Left);
    if (X > Area.Left) and (X + W > Area.Right) then
    begin
      X := Area.Left;
      Inc(Y, H + Gap);
      Inc(FLines);
    end;
    FChipRects[I] := Rect(X, Y, X + W, Y + H);
    Inc(X, W + Gap);
  end;
  // Eingabe hinter dem letzten Chip, sonst in der naechsten Zeile
  if (X > Area.Left) and (Area.Right - X < MinW) then
  begin
    X := Area.Left;
    Inc(Y, H + Gap);
    Inc(FLines);
  end;
  InnerRect := Rect(X, Y + (H - (LineHeight + 2)) div 2, Area.Right,
    Y + (H - (LineHeight + 2)) div 2 + LineHeight + 2);
  if UseRightToLeftAlignment then
  begin
    for I := 0 to High(FChipRects) do
      FChipRects[I] := Rect(Width - FChipRects[I].Right, FChipRects[I].Top,
        Width - FChipRects[I].Left, FChipRects[I].Bottom);
    InnerRect := Rect(Width - InnerRect.Right, InnerRect.Top, Width - InnerRect.Left,
      InnerRect.Bottom);
  end;
  FLayoutWidth := Width;
  FLayoutValid := True;
end;

procedure TPPGTagEdit.AdjustInnerBounds(var R: TRect);
var
  Inner: TRect;
begin
  if FTags = nil then
    Exit; // Layout schon im Konstruktor des Felds
  LayoutChips(TextArea, Inner);
  R := Inner;
end;

function TPPGTagEdit.CalcAutoSize(out AWidth, AHeight: Integer): Boolean;
var
  Inner: TRect;
begin
  if FTags = nil then
    Exit(inherited CalcAutoSize(AWidth, AHeight));
  // Hoehe nach Zeilen der Chips
  LayoutChips(TextArea, Inner);
  AWidth := Width;
  AHeight := FLines * ChipHeight + (FLines - 1) * ChipGap + 2 * PPGScale(4, ScalePPI);
  Result := True;
end;

procedure TPPGTagEdit.Resize;
begin
  inherited Resize;
  if FLayoutWidth <> Width then
    RequestAutoSize;
end;

function TPPGTagEdit.LineCount: Integer;
begin
  Result := FLines;
end;

function TPPGTagEdit.ChipRect(Index: Integer): TRect;
begin
  if (Index >= 0) and (Index <= High(FChipRects)) then
    Result := FChipRects[Index]
  else
    Result := Rect(0, 0, 0, 0);
end;

function TPPGTagEdit.ChipAt(X, Y: Integer; out OnCross: Boolean): Integer;
var
  I: Integer;
begin
  OnCross := False;
  for I := 0 to High(FChipRects) do
    if PtInRect(FChipRects[I], Point(X, Y)) then
    begin
      OnCross := PtInRect(CrossRect(FChipRects[I]), Point(X, Y));
      Exit(I);
    end;
  Result := -1;
end;

procedure TPPGTagEdit.SetSelectedTag(Value: Integer);
begin
  if (Value < -1) or (Value >= FTags.Count) then
    Value := -1;
  if FSelectedTag = Value then
    Exit;
  FSelectedTag := Value;
  Invalidate;
  if Value >= 0 then
    NotifyAccessibilityChild(EVENT_OBJECT_FOCUS, Value + 1);
end;

function TPPGTagEdit.WantSpecialKey(Key: Word): Boolean;
begin
  // Enter mit Text gehoert dem Feld (Tag anlegen), sonst dem Formular
  Result := inherited WantSpecialKey(Key) or ((Key = VK_RETURN) and (Trim(Text) <> ''));
end;

procedure TPPGTagEdit.FieldKeyDown(var Key: Word; Shift: TShiftState);
var
  AtStart: Boolean;
begin
  // Offene Vorschlaege: nur Navigation geht ans Popup, Zeichen ins Edit
  if DroppedDown and (Key in [VK_UP, VK_DOWN, VK_PRIOR, VK_NEXT, VK_ESCAPE]) then
  begin
    inherited FieldKeyDown(Key, Shift);
    Exit;
  end;
  if DroppedDown and (Key = VK_RETURN) and (Popup <> nil) and
    (TPPGTagSuggestPopup(Popup).FocusRow >= 0) then
  begin
    CloseUp(True);
    Key := 0;
    Exit;
  end;
  AtStart := (SelStart = 0) and (SelLength = 0);
  case Key of
    VK_RETURN:
      begin
        if DroppedDown then
          CloseUp(False);
        if Trim(Text) <> '' then
        begin
          CommitText;
          Key := 0;
        end;
      end;
    VK_BACK:
      if AtStart and (FTags.Count > 0) then
      begin
        // Erst markieren, beim zweiten Druck loeschen (wie Outlook)
        if FSelectedTag < 0 then
          SetSelectedTag(FTags.Count - 1)
        else
          RemoveTag(FSelectedTag);
        Key := 0;
      end;
    VK_DELETE:
      if FSelectedTag >= 0 then
      begin
        RemoveTag(FSelectedTag);
        Key := 0;
      end;
    VK_LEFT:
      if AtStart and (FTags.Count > 0) then
      begin
        if FSelectedTag < 0 then
          SetSelectedTag(FTags.Count - 1)
        else if FSelectedTag > 0 then
          SetSelectedTag(FSelectedTag - 1);
        Key := 0;
      end;
    VK_RIGHT:
      if FSelectedTag >= 0 then
      begin
        if FSelectedTag < FTags.Count - 1 then
          SetSelectedTag(FSelectedTag + 1)
        else
          SetSelectedTag(-1);
        Key := 0;
      end;
  end;
end;

procedure TPPGTagEdit.FieldKeyPress(var Key: Char);
begin
  if (Key = #13) or (Key = #27) then
  begin
    Key := #0; // kein Signalton
    Exit;
  end;
  // Ein Trenner beendet das Tag sofort (nicht erst ueber Change)
  if IsDelimiter(Key) then
  begin
    CommitText;
    Key := #0;
    Exit;
  end;
  if Key >= #32 then
    SetSelectedTag(-1);
end;

procedure TPPGTagEdit.FocusChanged;
begin
  inherited FocusChanged;
  if not FieldFocused and not (csDestroying in ComponentState) then
  begin
    SetSelectedTag(-1);
    if FAddOnExit and (Trim(Text) <> '') then
      CommitText;
  end;
end;

procedure TPPGTagEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  Cross: Boolean;
begin
  I := ChipAt(X, Y, Cross);
  if (Button = mbLeft) and (I >= 0) then
  begin
    if Cross then
      RemoveTag(I)
    else
    begin
      SetSelectedTag(I);
      if Assigned(FOnTagClick) then
        FOnTagClick(Self, FTags[I]);
    end;
    if CanFocus then
      SetFocus;
    Exit;
  end;
  inherited MouseDown(Button, Shift, X, Y);
  // Klick in die freie Flaeche: Eingabe fokussieren
  if (Button = mbLeft) and CanFocus then
    SetFocus;
end;

procedure TPPGTagEdit.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
  Cross: Boolean;
begin
  inherited MouseMove(Shift, X, Y);
  I := ChipAt(X, Y, Cross);
  if (I <> FHotTag) or (Cross <> FHotCross) then
  begin
    FHotTag := I;
    FHotCross := Cross;
    Invalidate;
  end;
end;

procedure TPPGTagEdit.DoPaintField(const ACanvas: IPPGCanvas; const Style: TPPGSurfaceStyle);
var
  I, PPI, Rad: Integer;
  R, CR, TR: TRect;
  T: TPPGTokens;
  Fill, Txt, Border: TColor;
  HC: Boolean;
  Pts: array[0..1] of TPoint;
begin
  inherited DoPaintField(ACanvas, Style);
  if not FLayoutValid or (FLayoutWidth <> Width) then
    UpdateLayout;
  PPI := ScalePPI;
  T := Tokens;
  HC := HighContrastSupport and PPGIsHighContrast;
  Rad := PPGScale(4, PPI);
  for I := 0 to High(FChipRects) do
  begin
    R := FChipRects[I];
    if HC then
    begin
      Fill := PPGColorToRGB(clBtnFace);
      Txt := PPGColorToRGB(clBtnText);
      Border := Txt;
    end
    else
    begin
      Fill := PPGBlendColor(Style.Color, Style.TextColor, 0.08);
      if I = FHotTag then
        Fill := PPGBlendColor(Style.Color, Style.TextColor, 0.14);
      Txt := Style.TextColor;
      Border := PPGBlendColor(Style.Color, Style.TextColor, 0.2);
    end;
    if I = FSelectedTag then
    begin
      if HC then
      begin
        Fill := PPGColorToRGB(clHighlight);
        Txt := PPGColorToRGB(clHighlightText);
      end
      else
      begin
        Fill := T.Accent;
        Txt := T.OnAccent;
      end;
      Border := Fill;
    end;
    ACanvas.FillRoundRect(R, Rad, Fill, 255);
    ACanvas.FrameRoundRect(R, Rad, 1, Border, 255);
    CR := CrossRect(R);
    TR := Rect(R.Left + PPGScale(8, PPI), R.Top, CR.Left - PPGScale(2, PPI), R.Bottom);
    ACanvas.DrawText(TR, FTags[I], Font, Txt,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX or DT_END_ELLIPSIS);
    if (I = FHotTag) and FHotCross then
      ACanvas.FillRoundRect(CR, PPGScale(3, PPI), Txt, 30);
    InflateRect(CR, -PPGScale(3, PPI), -PPGScale(3, PPI));
    Pts[0] := Point(CR.Left, CR.Top);
    Pts[1] := Point(CR.Right, CR.Bottom);
    ACanvas.DrawPolyline(Pts, Max(1, PPGScale(1, PPI)), Txt, 255);
    Pts[0] := Point(CR.Right, CR.Top);
    Pts[1] := Point(CR.Left, CR.Bottom);
    ACanvas.DrawPolyline(Pts, Max(1, PPGScale(1, PPI)), Txt, 255);
  end;
end;

function TPPGTagEdit.AccRole: Integer;
begin
  Result := ROLE_SYSTEM_TEXT;
end;

function TPPGTagEdit.AccValue: string;
begin
  Result := GetTagsText;
end;

function TPPGTagEdit.FieldIsNull: Boolean;
begin
  Result := FTags.Count = 0;
end;

procedure TPPGTagEdit.FieldClear;
begin
  FTags.Clear;
end;

function TPPGTagEdit.GetFieldValue: Variant;
begin
  if FTags.Count = 0 then
    Result := Null
  else
    Result := GetTagsText;
end;

procedure TPPGTagEdit.SetFieldValue(const Value: Variant);
begin
  if VarIsNull(Value) or VarIsEmpty(Value) then
    FTags.Clear
  else
    SetTagsText(VarToStr(Value));
end;

function TPPGTagEdit.AccChildCount: Integer;
begin
  Result := FTags.Count;
end;

function TPPGTagEdit.AccChildName(Id: Integer): string;
begin
  if (Id >= 1) and (Id <= FTags.Count) then
    Result := FTags[Id - 1]
  else
    Result := '';
end;

function TPPGTagEdit.AccChildRole(Id: Integer): Integer;
begin
  Result := ROLE_SYSTEM_LISTITEM;
end;

function TPPGTagEdit.AccChildState(Id: Integer): Integer;
begin
  Result := STATE_SYSTEM_SELECTABLE;
  if Id - 1 = FSelectedTag then
    Result := Result or STATE_SYSTEM_SELECTED or STATE_SYSTEM_FOCUSED;
end;

function TPPGTagEdit.AccChildRect(Id: Integer): TRect;
begin
  Result := ChipRect(Id - 1);
end;

function TPPGTagEdit.AccChildAt(X, Y: Integer): Integer;
var
  Cross: Boolean;
begin
  Result := ChipAt(X, Y, Cross) + 1;
end;

function TPPGTagEdit.AccChildDefaultAction(Id: Integer): string;
begin
  Result := PPGStr(@SPPGAccRemove);
end;

procedure TPPGTagEdit.AccChildDoDefault(Id: Integer);
begin
  // Nie im COM-Aufruf entfernen
  if HandleAllocated then
    PostMessage(Handle, WM_REMOVETAG, WPARAM(Id - 1), LPARAM(FTagsVersion));
end;

procedure TPPGTagEdit.WMRemoveTag(var Message: TMessage);
begin
  // Tags inzwischen geaendert: der Index meint womoeglich einen anderen Tag
  if Cardinal(Message.LParam) <> FTagsVersion then
    Exit;
  RemoveTag(Integer(Message.WParam));
end;

function TPPGTagEdit.AccFocusedChild: Integer;
begin
  Result := FSelectedTag + 1;
end;

function TPPGTagEdit.AccSelectedChild: Integer;
begin
  Result := FSelectedTag + 1;
end;

end.
