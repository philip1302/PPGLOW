unit PPG.TimePicker;

{ TPPGTimePicker - Uhrzeitfeld (Phase 7b).

  Basis ist die ComboBox (csDropDown): die Aufklappliste enthaelt die Zeiten
  im Abstand MinuteIncrement (Klick bzw. Enter uebernimmt). Dazu:
  - 12/24 Stunden aus dem Gebietsschema (LOCALE_ITIME) oder fest
    (ClockFormat); AM/PM aus FormatSettings; Sekunden optional.
  - Oben/Unten bzw. Mausrad aendern den Teil unter der Einfuegemarke
    (Stunde, Minute, Sekunde, AM/PM) mit Uebertrag.
  - Freie Eingabe ("14:30", "1430", "2:30 PM"); geprueft wird beim
    Verlassen bzw. Enter: gueltig = uebernehmen (OnChange), ungueltig =
    ValidationState pvsError.
  - Beim Aufklappen ist die naechstliegende Zeit der Liste hervorgehoben.
  - Code (Time := ...) loest kein OnChange aus. }

{$I ..\PPG.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls,
  PPG.Types, PPG.Render.Intf, PPG.Controls.Field, PPG.ComboBox;

type
  TPPGClockFormat = (pcfLocale, pcf12Hour, pcf24Hour);

  TPPGCustomTimePicker = class(TPPGCustomComboBox)
  private
    FTime: TTime;
    FShowSeconds: Boolean;
    FClockFormat: TPPGClockFormat;
    FMinuteIncrement: Integer;
    FQuietTime: Integer;
    FFiring: Boolean;
    FTimes: array of TTime;
    procedure SetTime(const Value: TTime);
    procedure SetShowSeconds(const Value: Boolean);
    procedure SetClockFormat(const Value: TPPGClockFormat);
    procedure SetMinuteIncrement(const Value: Integer);
    procedure RebuildItems;
    procedure UpdateText;
    function TimeFormat: string;
    function SegmentAtCaret: Integer;
    procedure StepSegment(Segment, Delta: Integer);
    function NearestItem(T: TTime): Integer;
  protected
    procedure Loaded; override;
    procedure WndProc(var Message: TMessage); override;
    procedure FieldKeyDown(var Key: Word; Shift: TShiftState); override;
    function WantSpecialKey(Key: Word): Boolean; override;
    procedure FocusChanged; override;
    procedure DoSelect; override;
    procedure Change; override;
    procedure DoDropDown; override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
      MousePos: TPoint): Boolean; override;
    function AccValue: string; override;
    /// Text pruefen und uebernehmen (True = gueltig).
    function CommitText(UserAction: Boolean): Boolean;
    procedure UserSetTime(T: TTime);
    property Time: TTime read FTime write SetTime;
    property ShowSeconds: Boolean read FShowSeconds write SetShowSeconds default False;
    property ClockFormat: TPPGClockFormat read FClockFormat write SetClockFormat default pcfLocale;
    property MinuteIncrement: Integer read FMinuteIncrement write SetMinuteIncrement default 15;
  public
    constructor Create(AOwner: TComponent); override;
    /// True bei 24-Stunden-Anzeige.
    function Uses24Hour: Boolean;
    function FormatTime(T: TTime): string;
    function ParseTime(const S: string; out T: TTime): Boolean;
  end;

  TPPGTimePicker = class(TPPGCustomTimePicker)
  published
    property Preset;
    property StyleManager;
    property Appearance;
    property Animation;
    property TextHint;
    property UseSystemContextMenu;
    property ValidationState;
    property ValidationHint;
    property HighContrastSupport;
    property Time;
    property ShowSeconds;
    property ClockFormat;
    property MinuteIncrement;
    property Align;
    property Anchors;
    property AutoSize default True;
    property BiDiMode;
    property BorderStyle;
    property Color default clWindow;
    property Constraints;
    property DropDownCount;
    property Enabled;
    property Font;
    property ParentBiDiMode;
    property ParentColor default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
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
    property OnCloseUp;
    property OnContextPopup;
    property OnDropDown;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

/// True, wenn das Gebietsschema 24 Stunden verwendet.
function PPGLocaleUses24Hour: Boolean;

implementation

uses
  System.Math, System.DateUtils, Winapi.oleacc;

var
  GMsgTimeHighlight: Cardinal = 0;

function PPGLocaleUses24Hour: Boolean;
var
  Buf: array[0..3] of Char;
begin
  Result := True;
  if GetLocaleInfo(LOCALE_USER_DEFAULT, LOCALE_ITIME, Buf, Length(Buf)) > 0 then
    Result := Buf[0] = '1';
end;

{ TPPGCustomTimePicker }

constructor TPPGCustomTimePicker.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FMinuteIncrement := 15;
  AutoComplete := False;
  FilterMode := fmNone;
  if GMsgTimeHighlight = 0 then
    GMsgTimeHighlight := RegisterWindowMessage('PPGlow.TimePickerHighlight');
  RebuildItems;
  UpdateText;
end;

procedure TPPGCustomTimePicker.Loaded;
begin
  inherited Loaded;
  RebuildItems;
  UpdateText;
end;

function TPPGCustomTimePicker.Uses24Hour: Boolean;
begin
  case FClockFormat of
    pcf12Hour: Result := False;
    pcf24Hour: Result := True;
  else
    Result := PPGLocaleUses24Hour;
  end;
end;

function TPPGCustomTimePicker.TimeFormat: string;
begin
  if Uses24Hour then
    Result := 'hh:nn'
  else
    Result := 'h:nn';
  if FShowSeconds then
    Result := Result + ':ss';
  if not Uses24Hour then
    Result := Result + ' ampm';
end;

function TPPGCustomTimePicker.FormatTime(T: TTime): string;
var
  FS: TFormatSettings;
begin
  FS := FormatSettings;
  FS.TimeSeparator := ':';
  if FS.TimeAMString = '' then
    FS.TimeAMString := 'AM';
  if FS.TimePMString = '' then
    FS.TimePMString := 'PM';
  Result := FormatDateTime(TimeFormat, T, FS);
end;

function TPPGCustomTimePicker.ParseTime(const S: string; out T: TTime): Boolean;
var
  Str, Digits, Rest: string;
  H, M, Sec, I: Integer;
  PM, AM: Boolean;
  Parts: TArray<string>;
begin
  Result := False;
  T := 0;
  Str := Trim(S);
  if Str = '' then
    Exit;
  // AM/PM erkennen (Gebietsschema und Englisch)
  PM := False;
  AM := False;
  Rest := AnsiUpperCase(Str);
  if (FormatSettings.TimePMString <> '') and (Pos(AnsiUpperCase(FormatSettings.TimePMString), Rest) > 0) then
    PM := True
  else if Pos('PM', Rest) > 0 then
    PM := True
  else if ((FormatSettings.TimeAMString <> '') and (Pos(AnsiUpperCase(FormatSettings.TimeAMString), Rest) > 0)) or
    (Pos('AM', Rest) > 0) then
    AM := True;
  // Nur Ziffern und Trenner behalten
  Digits := '';
  for I := 1 to Length(Str) do
    if CharInSet(Str[I], ['0'..'9']) then
      Digits := Digits + Str[I]
    else if CharInSet(Str[I], [':', '.']) or (Str[I] = FormatSettings.TimeSeparator) then
      Digits := Digits + ':';
  if Digits = '' then
    Exit;
  Sec := 0;
  if Pos(':', Digits) > 0 then
  begin
    Parts := PPGSplitString(Digits, ':', False);
    if (Length(Parts) < 2) or (Length(Parts) > 3) then
      Exit;
    if not TryStrToInt(Parts[0], H) or not TryStrToInt(Parts[1], M) then
      Exit;
    if (Length(Parts) = 3) and not TryStrToInt(Parts[2], Sec) then
      Exit;
  end
  else
  begin
    // "930", "1430", "143000"
    case Length(Digits) of
      1, 2:
        begin
          H := StrToInt(Digits);
          M := 0;
        end;
      3, 4:
        begin
          H := StrToInt(Copy(Digits, 1, Length(Digits) - 2));
          M := StrToInt(Copy(Digits, Length(Digits) - 1, 2));
        end;
      6:
        begin
          H := StrToInt(Copy(Digits, 1, 2));
          M := StrToInt(Copy(Digits, 3, 2));
          Sec := StrToInt(Copy(Digits, 5, 2));
        end;
    else
      Exit;
    end;
  end;
  if PM or AM then
  begin
    if (H < 1) or (H > 12) then
      Exit;
    if PM and (H < 12) then
      Inc(H, 12);
    if AM and (H = 12) then
      H := 0;
  end;
  if (H < 0) or (H > 23) or (M < 0) or (M > 59) or (Sec < 0) or (Sec > 59) then
    Exit;
  T := EncodeTime(H, M, Sec, 0);
  Result := True;
end;

procedure TPPGCustomTimePicker.RebuildItems;
var
  N, I: Integer;
begin
  if csLoading in ComponentState then
    Exit;
  N := (24 * 60) div FMinuteIncrement;
  SetLength(FTimes, N);
  Items.BeginUpdate;
  try
    Items.Clear;
    for I := 0 to N - 1 do
    begin
      FTimes[I] := EncodeTime((I * FMinuteIncrement) div 60, (I * FMinuteIncrement) mod 60, 0, 0);
      Items.Add(FormatTime(FTimes[I]));
    end;
  finally
    Items.EndUpdate;
  end;
  UpdateText; // Leeren der Items setzt den Text zurueck
end;

procedure TPPGCustomTimePicker.UpdateText;
begin
  Inc(FQuietTime);
  try
    Text := FormatTime(FTime);
  finally
    Dec(FQuietTime);
  end;
end;

function TPPGCustomTimePicker.NearestItem(T: TTime): Integer;
var
  Mins: Integer;
begin
  Mins := Round(Frac(T) * 24 * 60);
  Result := Round(Mins / FMinuteIncrement);
  if Result >= Length(FTimes) then
    Result := 0;
end;

procedure TPPGCustomTimePicker.SetTime(const Value: TTime);
var
  V: TTime;
begin
  V := Frac(Value);
  if V < 0 then
    V := V + 1;
  if FTime <> V then
  begin
    FTime := V;
    NotifyAccessibility(EVENT_OBJECT_VALUECHANGE);
  end;
  if ValidationState = pvsError then
    ValidationState := pvsNone;
  UpdateText;
end;

procedure TPPGCustomTimePicker.UserSetTime(T: TTime);
var
  Old: TTime;
begin
  Old := FTime;
  SetTime(T);
  if FTime <> Old then
  begin
    FFiring := True;
    try
      Change;
    finally
      FFiring := False;
    end;
  end;
end;

procedure TPPGCustomTimePicker.SetShowSeconds(const Value: Boolean);
begin
  if FShowSeconds <> Value then
  begin
    FShowSeconds := Value;
    RebuildItems;
  end;
end;

procedure TPPGCustomTimePicker.SetClockFormat(const Value: TPPGClockFormat);
begin
  if FClockFormat <> Value then
  begin
    FClockFormat := Value;
    RebuildItems;
  end;
end;

procedure TPPGCustomTimePicker.SetMinuteIncrement(const Value: Integer);
var
  V: Integer;
begin
  V := PPGCheckRange(Self, 'MinuteIncrement', Value, 1, 60);
  if FMinuteIncrement <> V then
  begin
    FMinuteIncrement := V;
    RebuildItems;
  end;
end;

function TPPGCustomTimePicker.CommitText(UserAction: Boolean): Boolean;
var
  T: TTime;
begin
  Result := ParseTime(Text, T);
  if not Result then
  begin
    if Trim(Text) = '' then
    begin
      UpdateText; // leer ist nicht erlaubt: alte Zeit
      Exit(True);
    end;
    ValidationState := pvsError;
    Exit;
  end;
  if ValidationState = pvsError then
    ValidationState := pvsNone;
  if UserAction then
    UserSetTime(T)
  else
    SetTime(T);
end;

function TPPGCustomTimePicker.SegmentAtCaret: Integer;
var
  S: string;
  P, I, Colons: Integer;
begin
  // 0 = Stunde, 1 = Minute, 2 = Sekunde, 3 = AM/PM
  S := Text;
  P := SelStart;
  Colons := 0;
  for I := 1 to Min(P, Length(S)) do
    if S[I] = ':' then
      Inc(Colons)
    else if S[I] = ' ' then
      Exit(3);
  Result := Colons;
  if (Result = 2) and not FShowSeconds then
    Result := 1;
end;

procedure TPPGCustomTimePicker.StepSegment(Segment, Delta: Integer);
var
  T: TTime;
  Secs: Integer;
  Caret: Integer;
begin
  if not ParseTime(Text, T) then
    T := FTime;
  Secs := Round(Frac(T) * SecsPerDay);
  case Segment of
    0: Inc(Secs, Delta * 3600);
    1: Inc(Secs, Delta * 60);
    2: Inc(Secs, Delta);
    3: Inc(Secs, 12 * 3600);
  end;
  Secs := ((Secs mod SecsPerDay) + SecsPerDay) mod SecsPerDay;
  Caret := SelStart;
  UserSetTime(Secs / SecsPerDay);
  SelStart := Caret; // Einfuegemarke im selben Teil lassen
end;

procedure TPPGCustomTimePicker.FieldKeyDown(var Key: Word; Shift: TShiftState);
begin
  if not DroppedDown and not ReadOnly then
    case Key of
      VK_UP, VK_DOWN:
        if not (ssAlt in Shift) then
        begin
          if Key = VK_UP then
            StepSegment(SegmentAtCaret, 1)
          else
            StepSegment(SegmentAtCaret, -1);
          Key := 0;
          Exit;
        end;
      VK_RETURN:
        begin
          CommitText(True);
          SelectAll;
          Key := 0;
          Exit;
        end;
    end;
  inherited FieldKeyDown(Key, Shift);
end;

function TPPGCustomTimePicker.WantSpecialKey(Key: Word): Boolean;
begin
  Result := inherited WantSpecialKey(Key) or (Key = VK_RETURN);
end;

function TPPGCustomTimePicker.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer;
  MousePos: TPoint): Boolean;
begin
  if DroppedDown or ReadOnly or not FieldFocused then
    Exit(inherited DoMouseWheel(Shift, WheelDelta, MousePos));
  if WheelDelta > 0 then
    StepSegment(SegmentAtCaret, 1)
  else if WheelDelta < 0 then
    StepSegment(SegmentAtCaret, -1);
  Result := True;
end;

procedure TPPGCustomTimePicker.FocusChanged;
begin
  inherited FocusChanged;
  if not FieldFocused and not (csDestroying in ComponentState) then
    CommitText(True);
end;

procedure TPPGCustomTimePicker.Change;
var
  Saved: TNotifyEvent;
begin
  if FFiring then
  begin
    inherited Change;
    Exit;
  end;
  // Tippen: die Combo gleicht Text und Liste ab, OnChange kommt aber erst mit
  // der Uebernahme (Verlassen, Enter, Liste, Pfeile)
  if not IsQuiet and (FQuietTime = 0) and (ValidationState = pvsError) then
    ValidationState := pvsNone;
  Saved := OnChange;
  OnChange := nil;
  try
    inherited Change;
  finally
    OnChange := Saved;
  end;
end;

procedure TPPGCustomTimePicker.DoSelect;
var
  I: Integer;
begin
  I := ItemIndex;
  if (I >= 0) and (I < Length(FTimes)) then
    UserSetTime(FTimes[I]);
end;

procedure TPPGCustomTimePicker.DoDropDown;
begin
  inherited DoDropDown;
  // Hervorhebung erst nach dem Aufklappen setzen (die Combo setzt sie dort)
  if HandleAllocated then
    PostMessage(Handle, GMsgTimeHighlight, 0, 0);
end;

procedure TPPGCustomTimePicker.WndProc(var Message: TMessage);
var
  I: Integer;
  T: TTime;
begin
  if (GMsgTimeHighlight <> 0) and (Message.Msg = GMsgTimeHighlight) then
  begin
    if DroppedDown and (PopupList <> nil) then
    begin
      if not ParseTime(Text, T) then
        T := FTime;
      I := NearestItem(T);
      PopupList.SetHighlight(I);
      PopupList.MakeVisible(I);
    end;
    Exit;
  end;
  inherited WndProc(Message);
end;

function TPPGCustomTimePicker.AccValue: string;
begin
  Result := FormatTime(FTime);
end;

end.
