unit PPG.Tests.Phase7a;

{$WARN SYMBOL_PLATFORM OFF}

{ Tests fuer Phase 7a: TPPGLabel/TPPGLinkLabel, TPPGBadge, TPPGProgressRing,
  TPPGInfoBar, TPPGExpander, TPPGSplitter, TPPGRating, TPPGSearchEdit. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls, Vcl.ExtCtrls,
  PPG.Types, PPG.Consts, PPG.Render.Intf, PPG.Render.Registry, PPG.Controls.Base,
  PPG.Labels, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.ComboBox, PPG.Accessibility, PPG.Exceptions, PPG.Tests.Controls, PPG.Tests.Phase4b;

type
  TPhase7aTestCase = class(TComboTestCase)
  protected
    FEvents: TStringList;
    FAllow: Boolean;
    FFillOnSearch: Boolean;
    procedure SetUp; override;
    procedure TearDown; override;
    procedure LogLink(Sender: TObject; const Link: string; LinkType: TSysLinkType);
    procedure LogClosing(Sender: TObject; var AllowClose: Boolean);
    procedure LogClose(Sender: TObject);
    procedure LogAction(Sender: TObject);
    procedure LogExpanding(Sender: TObject; var AllowChange: Boolean);
    procedure LogExpanded(Sender: TObject);
    procedure LogCollapsed(Sender: TObject);
    procedure LogMoved(Sender: TObject);
    procedure LogRating(Sender: TObject);
    procedure LogSearch(Sender: TObject; const SearchText: string);
    procedure LogSubmit(Sender: TObject; const SearchText: string);
    procedure LogChange7(Sender: TObject);
    procedure LogSplitPaint(Sender: TObject);
    procedure Click7(C: TWinControl; X, Y: Integer);
    procedure Key7(C: TWinControl; VK: Word; Shift: TShiftState = []);
    procedure TypeSearch(S: TPPGSearchEdit; Ch: Char);
    function RoundTrip(C: TComponent): TComponent;
    function PaintLabel(L: TPPGLabel): TBitmap;
  end;

  TLabelTests = class(TPhase7aTestCase)
  published
    procedure LabelLoadsTLabelDfm;
    procedure LabelColorsFollowTheme;
    procedure LabelPaintsMarkup;
    procedure LinkLabelFindsLinks;
    procedure LinkLabelKeyboard;
    procedure LinkLabelClick;
    procedure LinkLabelAccessibility;
  end;

  TFeedbackTests = class(TPhase7aTestCase)
  published
    procedure BadgeTextAndSize;
    procedure ProgressRingValueAndLoop;
    procedure InfoBarCloseEvents;
    procedure InfoBarKeyboard;
    procedure InfoBarGrowsWithText;
    procedure InfoBarAccessibility;
    procedure InfoBarAnimatesOpenClose;
  end;

  TExpanderTests = class(TPhase7aTestCase)
  published
    procedure CollapseByCodeWithoutEvents;
    procedure UserToggleFiresEvents;
    procedure ExpandingCanBeRefused;
    procedure CollapsedChildrenNotInTabOrder;
    procedure KeyboardToggles;
    procedure RoundTripKeepsState;
    procedure PaddingIsRespected;
  end;

  TSplitterTests = class(TPhase7aTestCase)
  published
    procedure DefaultsLikeTSplitter;
    procedure DragResizesLeftControl;
    procedure DragRightAlignedShrinks;
    procedure MinSizeAndAutoSnap;
    procedure KeyboardMoves;
    procedure LoadsTSplitterDfm;
    procedure BeveledOnPaintAndCursor;
  end;

  TRatingTests = class(TPhase7aTestCase)
  published
    procedure ClickSetsAndClears;
    procedure HalfStars;
    procedure KeyboardAndReadOnly;
    procedure CodeSetsWithoutEvent;
  end;

  TSearchEditTests = class(TPhase7aTestCase)
  published
    procedure DelayedSearchAndSuggestions;
    procedure ZeroDelaySearchesImmediately;
    procedure EnterSubmits;
    procedure EscapeClears;
    procedure CodeTextWithoutEvents;
    procedure DropButtonHidden;
    procedure NoFilterBeforeSearch;
  end;

  TPhase7aPaintTests = class(TPhase7aTestCase)
  published
    procedure PaintAllPresetsAndModes;
    procedure NoHandleOrMemoryLeaks;
  end;

implementation

uses
  Winapi.oleacc, PPG.Theme, PPG.Tokens;

type
  TLinkAccess = class(TPPGLinkLabel);
  TInfoAccess = class(TPPGInfoBar);
  TRingAccess = class(TPPGProgressRing);
  TExpanderAccess = class(TPPGExpander);
  TSplitterAccess = class(TPPGSplitter);
  TRatingAccess = class(TPPGRating);
  TSearchAccess = class(TPPGSearchEdit);
  TBadgeAccess = class(TPPGBadge);
  TWinAccess = class(TWinControl);
  TCCAccess = class(TPPGCustomControl);

function MouseLParam(X, Y: Integer): LPARAM;
begin
  Result := LPARAM(Word(SmallInt(X)) or (Cardinal(Word(SmallInt(Y))) shl 16));
end;

function AllocatedBytes: NativeUInt;
var
  S: TMemoryManagerState;
  I: Integer;
begin
  GetMemoryManagerState(S);
  Result := S.TotalAllocatedMediumBlockSize + S.TotalAllocatedLargeBlockSize;
  for I := Low(S.SmallBlockTypeStates) to High(S.SmallBlockTypeStates) do
    Inc(Result, S.SmallBlockTypeStates[I].AllocatedBlockCount *
      S.SmallBlockTypeStates[I].UseableBlockSize);
end;

function LoadDfm7(const Text: string): TComponent;
var
  Src, Bin: TMemoryStream;
  B: TBytes;
begin
  Src := TMemoryStream.Create;
  Bin := TMemoryStream.Create;
  try
    B := TEncoding.UTF8.GetBytes(Text);
    if Length(B) > 0 then
      Src.WriteBuffer(B[0], Length(B));
    Src.Position := 0;
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Result := Bin.ReadComponent(nil);
  finally
    Bin.Free;
    Src.Free;
  end;
end;

{ TPhase7aTestCase }

procedure TPhase7aTestCase.SetUp;
begin
  inherited SetUp;
  FEvents := TStringList.Create;
  FAllow := True;
  FFillOnSearch := False;
end;

procedure TPhase7aTestCase.TearDown;
begin
  FreeAndNil(FEvents);
  inherited TearDown;
end;

procedure TPhase7aTestCase.LogLink(Sender: TObject; const Link: string; LinkType: TSysLinkType);
begin
  FEvents.Add('link:' + Link);
end;

procedure TPhase7aTestCase.LogClosing(Sender: TObject; var AllowClose: Boolean);
begin
  FEvents.Add('closing');
  AllowClose := FAllow;
end;

procedure TPhase7aTestCase.LogClose(Sender: TObject);
begin
  FEvents.Add('close');
end;

procedure TPhase7aTestCase.LogAction(Sender: TObject);
begin
  FEvents.Add('action');
end;

procedure TPhase7aTestCase.LogExpanding(Sender: TObject; var AllowChange: Boolean);
begin
  FEvents.Add('expanding');
  AllowChange := FAllow;
end;

procedure TPhase7aTestCase.LogExpanded(Sender: TObject);
begin
  FEvents.Add('expanded');
end;

procedure TPhase7aTestCase.LogCollapsed(Sender: TObject);
begin
  FEvents.Add('collapsed');
end;

procedure TPhase7aTestCase.LogMoved(Sender: TObject);
begin
  FEvents.Add('moved');
end;

procedure TPhase7aTestCase.LogRating(Sender: TObject);
begin
  FEvents.Add('rating:' + FloatToStr(TPPGRating(Sender).Value));
end;

procedure TPhase7aTestCase.LogSearch(Sender: TObject; const SearchText: string);
begin
  FEvents.Add('search:' + SearchText);
  if FFillOnSearch then
    TPPGSearchEdit(Sender).Items.CommaText := 'Apfel,Banane,Traube';
end;

procedure TPhase7aTestCase.LogSubmit(Sender: TObject; const SearchText: string);
begin
  FEvents.Add('submit:' + SearchText);
end;

procedure TPhase7aTestCase.LogChange7(Sender: TObject);
begin
  FEvents.Add('change');
end;

procedure TPhase7aTestCase.LogSplitPaint(Sender: TObject);
begin
  if (TPPGSplitter(Sender).Canvas <> nil) and (TPPGSplitter(Sender).Canvas.Handle <> 0) then
    FEvents.Add('paint')
  else
    FEvents.Add('paint ohne Canvas');
end;

procedure TPhase7aTestCase.Click7(C: TWinControl; X, Y: Integer);
begin
  C.Perform(WM_MOUSEMOVE, 0, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(X, Y));
  C.Perform(WM_LBUTTONUP, 0, MouseLParam(X, Y));
end;

procedure TPhase7aTestCase.Key7(C: TWinControl; VK: Word; Shift: TShiftState);
var
  K: Word;
begin
  K := VK;
  TWinAccess(C).KeyDown(K, Shift); // KeyDown ist in TWinControl protected
end;

procedure TPhase7aTestCase.TypeSearch(S: TPPGSearchEdit; Ch: Char);
var
  Inner: TWinControl;
  Before: string;
begin
  Inner := TSearchAccess(S).Inner;
  Before := S.Text;
  Inner.Perform(WM_CHAR, Ord(Ch), 0);
  if S.Text = Before then
    SendMessage(Inner.Handle, EM_REPLACESEL, 1, LPARAM(PChar(string(Ch))));
end;

function TPhase7aTestCase.RoundTrip(C: TComponent): TComponent;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;
  try
    M.WriteComponent(C);
    M.Position := 0;
    Result := M.ReadComponent(nil);
  finally
    M.Free;
  end;
end;

function TPhase7aTestCase.PaintLabel(L: TPPGLabel): TBitmap;
begin
  Result := TBitmap.Create;
  Result.PixelFormat := pf24bit;
  Result.SetSize(L.Width, L.Height);
  Result.Canvas.Brush.Color := clWhite;
  Result.Canvas.FillRect(Rect(0, 0, L.Width, L.Height));
  Result.Canvas.Lock;
  try
    L.Perform(WM_PAINT, WPARAM(Result.Canvas.Handle), 0);
  finally
    Result.Canvas.Unlock;
  end;
end;

{ TLabelTests }

procedure TLabelTests.LabelLoadsTLabelDfm;
var
  L: TPPGLabel;
begin
  L := LoadDfm7(
    'object Label1: TPPGLabel'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 60'#13#10 +
    '  Height = 13'#13#10 +
    '  Caption = ''&Name:'''#13#10 +
    '  Layout = tlCenter'#13#10 +
    '  WordWrap = True'#13#10 +
    'end') as TPPGLabel;
  try
    CheckEquals('&Name:', L.Caption);
    CheckTrue(L.Layout = tlCenter);
    CheckTrue(L.WordWrap);
    CheckTrue(L.ShowAccelChar);
    CheckFalse(L.AllowMarkup);
  finally
    L.Free;
  end;
end;

procedure TLabelTests.LabelColorsFollowTheme;
var
  L: TPPGLabel;
  Light, Dark, Sec: TColor;
begin
  L := TPPGLabel.Create(FForm);
  L.Parent := FForm;
  L.Caption := 'Text';
  try
    TPPGTheme.Mode := tmLight;
    Light := L.TextColor;
    TPPGTheme.Mode := tmDark;
    Dark := L.TextColor;
    CheckTrue(PPGRelativeLuminance(Dark) > PPGRelativeLuminance(Light),
      'im Dark Mode heller Text');
    L.Secondary := True;
    Sec := L.TextColor;
    CheckTrue(Sec <> Dark, 'Secondary hat eigene Farbe');
    L.Enabled := False;
    CheckTrue(L.TextColor <> Sec, 'deaktiviert anders');
  finally
    TPPGTheme.Mode := tmLight;
  end;
end;

procedure TLabelTests.LabelPaintsMarkup;
var
  L: TPPGLabel;
  Bmp: TBitmap;
  X, Y, Dark: Integer;
begin
  L := TPPGLabel.Create(FForm);
  L.Parent := FForm;
  L.AutoSize := False;
  L.SetBounds(0, 0, 160, 24);
  L.AllowMarkup := True;
  L.Caption := '<b>Fett</b> und <color=#FF0000>rot</color>';
  Bmp := PaintLabel(L);
  try
    Dark := 0;
    for Y := 0 to Bmp.Height - 1 do
      for X := 0 to Bmp.Width - 1 do
        if Bmp.Canvas.Pixels[X, Y] <> clWhite then
          Inc(Dark);
    CheckTrue(Dark > 20, 'Text gezeichnet');
  finally
    Bmp.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TLabelTests.LinkLabelFindsLinks;
var
  L: TPPGLinkLabel;
begin
  L := TPPGLinkLabel.Create(FForm);
  L.Parent := FForm;
  L.Caption := 'Siehe <a href="https://a.example">Seite A</a> und <a href="b">B</a>.';
  CheckEquals(2, L.LinkCount);
  CheckEquals('https://a.example', L.LinkTarget(0));
  CheckEquals('b', L.LinkTarget(1));
  CheckFalse(IsRectEmpty(L.LinkRect(0)));
  CheckTrue(L.LinkRect(1).Left > L.LinkRect(0).Right, 'B rechts von A');
  CheckTrue(L.AutoSize);
  CheckTrue(L.Width > 50, 'AutoSize misst den Text');
end;

procedure TLabelTests.LinkLabelKeyboard;
var
  L: TPPGLinkLabel;
begin
  L := TPPGLinkLabel.Create(FForm);
  L.Parent := FForm;
  L.Caption := '<a href="eins">1</a> <a href="zwei">2</a>';
  L.OnLinkClick := LogLink;
  L.HandleNeeded;
  L.FocusedLink := 0;
  Key7(L, VK_RIGHT);
  CheckEquals(1, L.FocusedLink, 'Pfeil wechselt den Link');
  Key7(L, VK_RETURN);
  CheckEquals('link:zwei', FEvents.Text.Trim);
  Key7(L, VK_LEFT);
  CheckEquals(0, L.FocusedLink);
end;

procedure TLabelTests.LinkLabelClick;
var
  L: TPPGLinkLabel;
  R: TRect;
begin
  FForm.Show;
  try
    L := TPPGLinkLabel.Create(FForm);
    L.Parent := FForm;
    L.Caption := 'Text <a href="ziel">Link</a>';
    L.OnLinkClick := LogLink;
    R := L.LinkRect(0);
    Click7(L, (R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
    CheckEquals('link:ziel', FEvents.Text.Trim);
    FEvents.Clear;
    Click7(L, 1, 1);
    CheckEquals(0, FEvents.Count, 'Klick neben den Link');
  finally
    FForm.Hide;
  end;
end;

procedure TLabelTests.LinkLabelAccessibility;
var
  L: TPPGLinkLabel;
  A: IPPGAccessibleChildren;
begin
  L := TPPGLinkLabel.Create(FForm);
  L.Parent := FForm;
  L.Caption := 'Mehr <a href="x">Hilfe</a> oder <a href="y">Kontakt</a>';
  CheckTrue(Supports(L, IPPGAccessibleChildren, A));
  CheckEquals(2, A.AccChildCount);
  CheckEquals('Hilfe', A.AccChildName(1));
  CheckEquals('Kontakt', A.AccChildName(2));
  CheckEquals(ROLE_SYSTEM_LINK, A.AccChildRole(1));
  CheckEquals(SPPGAccJump, A.AccChildDefaultAction(1));
end;

{ TFeedbackTests }

procedure TFeedbackTests.BadgeTextAndSize;
var
  B: TPPGBadge;
  W: Integer;
begin
  B := TPPGBadge.Create(FForm);
  B.Parent := FForm;
  B.Value := 7;
  CheckEquals('7', B.DisplayText);
  W := B.Width;
  B.Value := 150;
  CheckEquals('99+', B.DisplayText);
  CheckTrue(B.Width > W, 'AutoSize waechst mit dem Text');
  B.MaxValue := 0;
  CheckEquals('150', B.DisplayText);
  B.Kind := bkDot;
  CheckEquals('', B.DisplayText);
  CheckEquals(8, B.Width);
  CheckEquals(8, B.Height);
  B.Kind := bkText;
  B.Caption := 'Neu';
  CheckEquals('Neu', B.DisplayText);
  CheckEquals('Neu', TBadgeAccess(B).AccName);
  try
    B.MaxValue := -1;
    Fail('MaxValue < 0 muss werfen');
  except
    on E: Exception do
      CheckTrue(E is EPPGError, E.ClassName);
  end;
end;

procedure TFeedbackTests.ProgressRingValueAndLoop;
var
  R: TPPGProgressRing;
begin
  R := TPPGProgressRing.Create(FForm);
  R.Parent := FForm;
  R.HandleNeeded;
  CheckTrue(R.Indeterminate);
  CheckFalse(R.Spinning, 'unsichtbar: keine Animation');
  FForm.Show;
  try
    if R.Animation.EffectiveEnabled then
      CheckTrue(R.Spinning, 'sichtbar und unbestimmt: dreht');
    R.Indeterminate := False;
    CheckFalse(R.Spinning);
    R.Value := 150;
    CheckEquals(100, R.Value, 'begrenzt');
    R.Value := 42;
    CheckEquals('42 %', TRingAccess(R).AccValue);
    CheckEquals(ROLE_SYSTEM_PROGRESSBAR, TRingAccess(R).AccRole);
    R.Indeterminate := True;
    R.Animation.Enabled := False;
    CheckFalse(R.Spinning, 'Animation aus: ruht');
    CheckTrue(TRingAccess(R).AccState and STATE_SYSTEM_BUSY <> 0);
    RenderToBitmap(R).Free;
  finally
    FForm.Hide;
  end;
  CheckFalse(R.Spinning);
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TFeedbackTests.InfoBarCloseEvents;
var
  I: TPPGInfoBar;
begin
  I := TPPGInfoBar.Create(FForm);
  I.Parent := FForm;
  I.Title := 'Hinweis';
  I.Message := 'Text';
  I.OnClosing := LogClosing;
  I.OnClose := LogClose;
  FAllow := False;
  CheckFalse(I.CloseByUser, 'abgelehnt');
  CheckTrue(I.IsOpen);
  CheckTrue(I.Visible);
  FAllow := True;
  CheckTrue(I.CloseByUser);
  CheckEquals('closing,closing,close', FEvents.CommaText);
  CheckFalse(I.IsOpen);
  CheckFalse(I.Visible, 'geschlossen = unsichtbar');
  FEvents.Clear;
  I.IsOpen := True;
  CheckTrue(I.Visible);
  CheckEquals(0, FEvents.Count, 'Code ohne Ereignisse');
  I.IsClosable := False;
  CheckFalse(I.CloseByUser);
  CheckTrue(IsRectEmpty(I.PartRect(ipClose)));
end;

procedure TFeedbackTests.InfoBarKeyboard;
var
  I: TPPGInfoBar;
begin
  I := TPPGInfoBar.Create(FForm);
  I.Parent := FForm;
  I.Width := 400;
  I.Message := 'Datei gespeichert';
  I.ActionCaption := 'Oeffnen';
  I.OnActionClick := LogAction;
  I.OnClose := LogClose;
  I.HandleNeeded;
  TInfoAccess(I).DoEnter;
  CheckTrue(I.FocusPart = ipAction, 'zuerst der Aktions-Button');
  Key7(I, VK_RETURN);
  CheckEquals('action', FEvents.CommaText);
  Key7(I, VK_RIGHT);
  CheckTrue(I.FocusPart = ipClose);
  Key7(I, VK_SPACE);
  CheckEquals('action,close', FEvents.CommaText);
  I.IsOpen := True;
  FEvents.Clear;
  Key7(I, VK_ESCAPE);
  CheckEquals('close', FEvents.CommaText, 'Esc schliesst');
end;

procedure TFeedbackTests.InfoBarGrowsWithText;
var
  I: TPPGInfoBar;
  H: Integer;
begin
  I := TPPGInfoBar.Create(FForm);
  I.Parent := FForm;
  I.Width := 300;
  I.Message := 'Kurz';
  I.HandleNeeded;
  H := I.Height;
  CheckEquals(48, H, 'Mindesthoehe');
  I.Message := 'Ein sehr langer Hinweistext, der in einer schmalen Leiste ' +
    'sicher auf mehrere Zeilen umbrechen muss, damit alles lesbar bleibt.';
  CheckTrue(I.Height > H, 'Hoehe folgt dem Umbruch');
  I.Width := 1200;
  CheckTrue(I.Height < 70, 'breiter = weniger Zeilen');
  CheckFalse(IsRectEmpty(I.PartRect(ipClose)));
end;

procedure TFeedbackTests.InfoBarAccessibility;
var
  I: TPPGInfoBar;
begin
  I := TPPGInfoBar.Create(FForm);
  I.Parent := FForm;
  I.Severity := psError;
  I.Title := 'Fehler';
  I.Message := 'Datei <b>fehlt</b>';
  CheckEquals(ROLE_SYSTEM_ALERT, TInfoAccess(I).AccRole);
  CheckEquals('Fehler Datei fehlt', TInfoAccess(I).AccName);
  CheckEquals(SPPGAccClose, TInfoAccess(I).AccDefaultAction);
  I.ActionCaption := 'Suchen';
  CheckEquals('Suchen', TInfoAccess(I).AccDefaultAction);
  CheckTrue(I.SeverityColor = I.Tokens.Danger);
end;

procedure TFeedbackTests.InfoBarAnimatesOpenClose;
var
  I: TPPGInfoBar;
  T0: Cardinal;
  Seen: Boolean;
begin
  FForm.Show;
  try
    I := TPPGInfoBar.Create(FForm);
    I.Parent := FForm;
    I.Width := 400;
    I.Message := 'Hinweis';
    I.HandleNeeded;
    CheckEquals(48, I.Height);
    I.IsOpen := False;
    if I.Animation.EffectiveEnabled then
      CheckTrue(I.Visible, 'schliesst animiert: noch sichtbar');
    T0 := GetTickCount;
    Seen := False;
    while I.Visible and (GetTickCount - T0 < 2000) do
    begin
      if (I.Height > 1) and (I.Height < 48) then
        Seen := True;
      Application.ProcessMessages;
      Sleep(5);
    end;
    CheckFalse(I.Visible, 'am Ende unsichtbar');
    if I.Animation.EffectiveEnabled then
      CheckTrue(Seen, 'Zwischenhoehe beim Schliessen');
    I.IsOpen := True;
    CheckTrue(I.Visible);
    T0 := GetTickCount;
    while (I.Height < 48) and (GetTickCount - T0 < 2000) do
    begin
      Application.ProcessMessages;
      Sleep(5);
    end;
    CheckEquals(48, I.Height, 'volle Hoehe nach dem Oeffnen');
    I.Animation.Enabled := False;
    I.IsOpen := False;
    CheckFalse(I.Visible, 'ohne Animation sofort');
  finally
    FForm.Hide;
  end;
end;

{ TExpanderTests }

function NewExpander(F: TForm): TPPGExpander;
begin
  Result := TPPGExpander.Create(F);
  Result.Parent := F;
  Result.SetBounds(10, 10, 300, 200);
  Result.Caption := 'Einstellungen';
  Result.Animation.Enabled := False;
end;

procedure TExpanderTests.CollapseByCodeWithoutEvents;
var
  E: TPPGExpander;
begin
  E := NewExpander(FForm);
  E.OnExpanded := LogExpanded;
  E.OnCollapsed := LogCollapsed;
  E.OnExpanding := LogExpanding;
  CheckEquals(200, E.ExpandedHeight);
  E.Expanded := False;
  CheckEquals(E.HeaderHeight, E.Height, 'zu = nur Kopfzeile');
  CheckEquals(200, E.ExpandedHeight, 'aufgeklappte Hoehe bleibt');
  CheckEquals(0, FEvents.Count, 'Code ohne Ereignisse');
  E.Expanded := True;
  CheckEquals(200, E.Height);
  E.Height := 250;
  CheckEquals(250, E.ExpandedHeight, 'Groesse von aussen = neue aufgeklappte Hoehe');
  E.Detail := 'Mit Detailzeile';
  E.Expanded := False;
  CheckEquals(E.HeaderHeight, E.Height);
  CheckTrue(E.HeaderHeight >= 48);
end;

procedure TExpanderTests.UserToggleFiresEvents;
var
  E: TPPGExpander;
begin
  FForm.Show;
  try
    E := NewExpander(FForm);
    E.OnExpanded := LogExpanded;
    E.OnCollapsed := LogCollapsed;
    E.OnExpanding := LogExpanding;
    Click7(E, 100, 10);
    CheckFalse(E.Expanded, 'Klick auf die Kopfzeile');
    CheckEquals('expanding,collapsed', FEvents.CommaText);
    FEvents.Clear;
    Click7(E, 100, 10);
    CheckTrue(E.Expanded);
    CheckEquals('expanding,expanded', FEvents.CommaText);
    FEvents.Clear;
    Click7(E, 100, 150);
    CheckTrue(E.Expanded, 'Klick in den Inhalt schaltet nicht');
    CheckEquals(0, FEvents.Count);
  finally
    FForm.Hide;
  end;
end;

procedure TExpanderTests.ExpandingCanBeRefused;
var
  E: TPPGExpander;
begin
  E := NewExpander(FForm);
  E.OnExpanding := LogExpanding;
  E.OnCollapsed := LogCollapsed;
  FAllow := False;
  CheckFalse(E.ToggleByUser);
  CheckTrue(E.Expanded);
  CheckEquals('expanding', FEvents.CommaText);
  E.Enabled := False;
  FAllow := True;
  CheckFalse(E.ToggleByUser, 'deaktiviert');
end;

procedure TExpanderTests.CollapsedChildrenNotInTabOrder;
var
  E: TPPGExpander;
  Ed: TEdit;
  L: TList;
begin
  E := NewExpander(FForm);
  Ed := TEdit.Create(FForm);
  Ed.Parent := E;
  Ed.SetBounds(20, 80, 100, 21);
  L := TList.Create;
  try
    E.GetTabOrderList(L);
    CheckEquals(1, L.Count, 'aufgeklappt erreichbar');
    L.Clear;
    E.Expanded := False;
    E.GetTabOrderList(L);
    CheckEquals(0, L.Count, 'zugeklappt nicht per Tab');
  finally
    L.Free;
  end;
  CheckTrue(Ed.Top >= E.HeaderHeight, 'Kind liegt unter der Kopfzeile');
end;

procedure TExpanderTests.KeyboardToggles;
var
  E: TPPGExpander;
begin
  E := NewExpander(FForm);
  E.OnCollapsed := LogCollapsed;
  E.OnExpanded := LogExpanded;
  E.HandleNeeded;
  Key7(E, VK_LEFT);
  CheckFalse(E.Expanded, 'Links klappt zu');
  Key7(E, VK_LEFT);
  CheckFalse(E.Expanded);
  Key7(E, VK_RIGHT);
  CheckTrue(E.Expanded, 'Rechts klappt auf');
  Key7(E, VK_SPACE);
  CheckFalse(E.Expanded, 'Leertaste schaltet um');
  CheckEquals('collapsed,expanded,collapsed', FEvents.CommaText);
  CheckTrue(TExpanderAccess(E).AccState and STATE_SYSTEM_COLLAPSED <> 0);
  CheckEquals(SPPGAccExpand, TExpanderAccess(E).AccDefaultAction);
end;

procedure TExpanderTests.RoundTripKeepsState;
var
  E, E2: TPPGExpander;
begin
  E := NewExpander(FForm);
  E.Detail := 'Detail';
  E.Expanded := False;
  E2 := RoundTrip(E) as TPPGExpander;
  try
    CheckFalse(E2.Expanded);
    CheckEquals(200, E2.ExpandedHeight);
    CheckEquals('Detail', E2.Detail);
    CheckEquals(E2.HeaderHeight, E2.Height);
    E2.Parent := FForm;
    E2.Expanded := True;
    CheckEquals(200, E2.Height);
  finally
    E2.Free;
  end;
end;

procedure TExpanderTests.PaddingIsRespected;
var
  E: TPPGExpander;
  P: TPanel;
begin
  FForm.Show; // ohne Fensterhandle richtet die VCL keine Kinder aus
  E := NewExpander(FForm);
  E.Padding.SetBounds(10, 20, 10, 15);
  P := TPanel.Create(FForm);
  P.Parent := E;
  P.Align := alClient;
  CheckTrue(P.Top >= E.HeaderHeight + 20, Format('Padding.Top: %d', [P.Top]));
  CheckTrue(P.Left >= 10);
  CheckTrue(P.Top + P.Height <= E.Height - 15, 'Padding.Bottom');
  E.Expanded := False;
  E.Expanded := True;
  CheckTrue(P.Top + P.Height <= E.Height - 15, 'Padding.Bottom nach Zu-/Aufklappen');
  FForm.Hide;
end;

{ TSplitterTests }

procedure BuildSplit(F: TForm; AAlign: TAlign; out P: TPanel; out S: TPPGSplitter);
var
  Rest: TPanel;
begin
  F.SetBounds(0, 0, 600, 400);
  P := TPanel.Create(F);
  P.Parent := F;
  if AAlign in [alLeft, alRight] then
    P.Width := 150
  else
    P.Height := 120;
  P.Align := AAlign;
  S := TPPGSplitter.Create(F);
  S.Parent := F;
  case AAlign of
    alLeft: S.Left := 500;
    alRight: S.Left := 0;
    alTop: S.Top := 300;
    alBottom: S.Top := 0;
  end;
  S.Align := AAlign;
  Rest := TPanel.Create(F);
  Rest.Parent := F;
  Rest.Align := alClient;
end;

procedure TSplitterTests.DefaultsLikeTSplitter;
var
  S: TPPGSplitter;
begin
  S := TPPGSplitter.Create(nil);
  try
    CheckTrue(S.Align = alLeft);
    CheckEquals(30, S.MinSize);
    CheckTrue(S.AutoSnap);
    CheckTrue(S.ResizeStyle = rsUpdate);
    CheckFalse(S.TabStop);
    CheckEquals(Integer(crHSplit), Integer(S.Cursor));
    S.Align := alTop;
    CheckEquals(Integer(crVSplit), Integer(S.Cursor));
  finally
    S.Free;
  end;
end;

procedure TSplitterTests.DragResizesLeftControl;
var
  P: TPanel;
  S: TPPGSplitter;
begin
  FForm.Show;
  try
    BuildSplit(FForm, alLeft, P, S);
    S.OnMoved := LogMoved;
    CheckTrue(S.FindResizeControl = P);
    CheckEquals(150, S.Left, 'Splitter haengt am Panel');
    S.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(2, 50));
    CheckTrue(S.IsDragging);
    S.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(52, 50));
    CheckEquals(200, P.Width, 'live (rsUpdate)');
    S.Perform(WM_LBUTTONUP, 0, MouseLParam(52, 50));
    CheckFalse(S.IsDragging);
    CheckEquals(200, P.Width);
    CheckEquals(200, S.Left);
    CheckEquals('moved', FEvents.CommaText);
    // Esc bricht ab
    S.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(2, 50));
    S.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(-48, 50));
    CheckEquals(150, P.Width);
    Key7(S, VK_ESCAPE);
    CheckEquals(200, P.Width, 'Esc: alte Breite');
    CheckFalse(S.IsDragging);
  finally
    FForm.Hide;
  end;
end;

procedure TSplitterTests.DragRightAlignedShrinks;
var
  P: TPanel;
  S: TPPGSplitter;
begin
  FForm.Show;
  try
    BuildSplit(FForm, alRight, P, S);
    CheckTrue(S.FindResizeControl = P);
    S.ResizeStyle := rsNone;
    S.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(2, 50));
    S.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(42, 50));
    CheckEquals(150, P.Width, 'rsNone: erst beim Loslassen');
    S.Perform(WM_LBUTTONUP, 0, MouseLParam(42, 50));
    CheckEquals(110, P.Width, 'nach rechts ziehen verkleinert');
    CheckEquals(FForm.ClientWidth - 110, P.Left);
  finally
    FForm.Hide;
  end;
end;

procedure TSplitterTests.MinSizeAndAutoSnap;
var
  P: TPanel;
  S: TPPGSplitter;
begin
  FForm.Show;
  try
    BuildSplit(FForm, alTop, P, S);
    CheckTrue(S.FindResizeControl = P);
    S.Perform(WM_LBUTTONDOWN, MK_LBUTTON, MouseLParam(50, 2));
    S.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(50, -98));
    CheckEquals(30, P.Height, 'nicht unter MinSize');
    S.Perform(WM_MOUSEMOVE, MK_LBUTTON, MouseLParam(50, -110));
    CheckEquals(0, P.Height, 'AutoSnap klappt zu');
    S.Perform(WM_LBUTTONUP, 0, MouseLParam(50, -110));
    CheckTrue(S.FindResizeControl = P, 'zugeklapptes Panel bleibt gefunden');
    S.AutoSnap := False;
    CheckTrue(S.MoveBy(500));
    CheckTrue(P.Height <= FForm.ClientHeight - S.Height - S.MinSize, 'Maximum laesst MinSize Platz');
  finally
    FForm.Hide;
  end;
end;

procedure TSplitterTests.KeyboardMoves;
var
  P: TPanel;
  S: TPPGSplitter;
begin
  BuildSplit(FForm, alLeft, P, S);
  S.OnMoved := LogMoved;
  S.HandleNeeded;
  Key7(S, VK_RIGHT);
  CheckEquals(160, P.Width, '10 px');
  Key7(S, VK_LEFT, [ssCtrl]);
  CheckEquals(159, P.Width, 'Strg = 1 px');
  Key7(S, VK_UP);
  CheckEquals(159, P.Width, 'falsche Achse');
  Key7(S, VK_HOME);
  CheckEquals(0, P.Width, 'Pos1 = zu (AutoSnap)');
  CheckEquals('moved,moved,moved', FEvents.CommaText);
  CheckEquals('0', TSplitterAccess(S).AccValue);
end;

procedure TSplitterTests.LoadsTSplitterDfm;
var
  S: TPPGSplitter;
begin
  S := LoadDfm7(
    'object Splitter1: TPPGSplitter'#13#10 +
    '  Left = 185'#13#10 +
    '  Top = 0'#13#10 +
    '  Height = 300'#13#10 +
    '  Align = alRight'#13#10 +
    '  MinSize = 50'#13#10 +
    '  ResizeStyle = rsLine'#13#10 +
    '  AutoSnap = False'#13#10 +
    'end') as TPPGSplitter;
  try
    CheckTrue(S.Align = alRight);
    CheckEquals(50, S.MinSize);
    CheckTrue(S.ResizeStyle = rsLine);
    CheckFalse(S.AutoSnap);
    CheckEquals(6, S.Width, 'Breite ohne Angabe');
  finally
    S.Free;
  end;
end;

procedure TSplitterTests.BeveledOnPaintAndCursor;
var
  S: TPPGSplitter;
  P: TPanel;
begin
  S := LoadDfm7(
    'object Splitter1: TPPGSplitter'#13#10 +
    '  Left = 0'#13#10 +
    '  Top = 100'#13#10 +
    '  Width = 300'#13#10 +
    '  Height = 3'#13#10 +
    '  Cursor = crVSplit'#13#10 +
    '  Align = alTop'#13#10 +
    '  Beveled = True'#13#10 +
    'end') as TPPGSplitter;
  try
    CheckTrue(S.Beveled, 'DFM von TSplitter mit Beveled');
    CheckEquals(Integer(crVSplit), Integer(S.Cursor));
  finally
    S.Free;
  end;
  BuildSplit(FForm, alLeft, P, S);
  S.Cursor := crSizeWE;
  S.Align := alRight;
  CheckEquals(Integer(crSizeWE), Integer(S.Cursor), 'eigener Cursor bleibt');
  S.OnPaint := LogSplitPaint;
  FForm.Show;
  try
    RenderToBitmap(S).Free;
  finally
    FForm.Hide;
  end;
  CheckEquals('paint', FEvents.CommaText, 'OnPaint mit Canvas');
  CheckTrue(S.Canvas = nil, 'Canvas nur waehrend OnPaint');
end;

{ TRatingTests }

function NewRating(F: TForm): TPPGRating;
begin
  Result := TPPGRating.Create(F);
  Result.Parent := F;
  Result.SetBounds(10, 10, 10, 10);
  Result.HandleNeeded;
end;

procedure TRatingTests.ClickSetsAndClears;
var
  R: TPPGRating;
  C: TRect;
begin
  FForm.Show;
  try
    R := NewRating(FForm);
    R.OnChange := LogRating;
    CheckEquals(120, R.Width, 'AutoSize: 5 Sterne');
    C := R.StarRect(2);
    Click7(R, (C.Left + C.Right) div 2, (C.Top + C.Bottom) div 2);
    CheckEquals(3, R.Value, 0);
    Click7(R, (C.Left + C.Right) div 2, (C.Top + C.Bottom) div 2);
    CheckEquals(0, R.Value, 0, 'AllowClear');
    R.AllowClear := False;
    Click7(R, (C.Left + C.Right) div 2, (C.Top + C.Bottom) div 2);
    Click7(R, (C.Left + C.Right) div 2, (C.Top + C.Bottom) div 2);
    CheckEquals(3, R.Value, 0);
    CheckEquals('rating:3,rating:0,rating:3', FEvents.CommaText);
    R.Perform(WM_MOUSEMOVE, 0, MouseLParam(R.StarRect(4).Left + 3, 5));
    CheckEquals(5, R.HoverValue, 0, 'Vorschau');
    CheckEquals(3, R.Value, 0);
  finally
    FForm.Hide;
  end;
end;

procedure TRatingTests.HalfStars;
var
  R: TPPGRating;
  C: TRect;
begin
  R := NewRating(FForm);
  R.AllowHalf := True;
  C := R.StarRect(2);
  CheckEquals(2.5, R.ValueAt(C.Left + 2), 0);
  CheckEquals(3, R.ValueAt(C.Right - 2), 0);
  R.Value := 3.7;
  CheckEquals(3.5, R.Value, 0, 'auf halbe gerundet');
  R.AllowHalf := False;
  CheckEquals(4, R.Value, 0, 'ganze');
  R.Value := 99;
  CheckEquals(5, R.Value, 0, 'begrenzt');
  R.MaxValue := 3;
  CheckEquals(3, R.Value, 0);
  CheckEquals('3 / 3', TRatingAccess(R).AccValue);
end;

procedure TRatingTests.KeyboardAndReadOnly;
var
  R: TPPGRating;
  K: Char;
begin
  R := NewRating(FForm);
  R.OnChange := LogRating;
  Key7(R, VK_RIGHT);
  Key7(R, VK_RIGHT);
  CheckEquals(2, R.Value, 0);
  Key7(R, VK_END);
  CheckEquals(5, R.Value, 0);
  Key7(R, VK_LEFT);
  CheckEquals(4, R.Value, 0);
  K := '1';
  TRatingAccess(R).KeyPress(K);
  CheckEquals(1, R.Value, 0, 'Ziffer');
  Key7(R, VK_HOME);
  CheckEquals(0, R.Value, 0);
  CheckEquals(6, FEvents.Count);
  R.ReadOnly := True;
  Key7(R, VK_END);
  CheckEquals(0, R.Value, 0, 'ReadOnly');
  CheckTrue(TRatingAccess(R).AccState and STATE_SYSTEM_READONLY <> 0);
  CheckEquals(ROLE_SYSTEM_SLIDER, TRatingAccess(R).AccRole);
end;

procedure TRatingTests.CodeSetsWithoutEvent;
var
  R: TPPGRating;
begin
  R := NewRating(FForm);
  R.OnChange := LogRating;
  R.Value := 4;
  R.MaxValue := 10;
  CheckEquals(4, R.Value, 0);
  CheckEquals(0, FEvents.Count);
end;

{ TSearchEditTests }

function NewSearch(F: TForm; T: TPhase7aTestCase): TPPGSearchEdit;
begin
  Result := TPPGSearchEdit.Create(F);
  Result.Parent := F;
  Result.SetBounds(10, 10, 200, 24);
  Result.Animation.Enabled := False;
  Result.OnSearch := T.LogSearch;
  Result.OnSubmit := T.LogSubmit;
  Result.OnChange := T.LogChange7;
  Result.HandleNeeded;
end;

procedure TSearchEditTests.DelayedSearchAndSuggestions;
var
  S: TPPGSearchEdit;
begin
  FForm.Show;
  try
    S := NewSearch(FForm, Self);
    FFillOnSearch := True;
    S.SetFocus;
    TypeSearch(S, 'a');
    CheckTrue(S.SearchPending, 'wartet SearchDelay');
    CheckEquals('change', FEvents.CommaText);
    TypeSearch(S, 'n');
    S.FlushSearch;
    CheckFalse(S.SearchPending);
    CheckEquals('change,change,search:an', FEvents.CommaText, 'nur eine Suche');
    CheckTrue(S.DroppedDown, 'Vorschlaege nach der Suche');
    CheckEquals(1, S.PopupList.RowCount, 'gefiltert: nur Banane');
    S.CloseUp(True);
    CheckEquals('Banane', S.Text);
    CheckEquals('submit:Banane', FEvents[FEvents.Count - 1], 'Vorschlag = absenden');
  finally
    FForm.Hide;
  end;
end;

procedure TSearchEditTests.ZeroDelaySearchesImmediately;
var
  S: TPPGSearchEdit;
begin
  FForm.Show;
  try
    S := NewSearch(FForm, Self);
    S.SearchDelay := 0;
    S.SetFocus;
    TypeSearch(S, 'x');
    CheckFalse(S.SearchPending);
    CheckEquals('change,search:x', FEvents.CommaText);
    CheckFalse(S.DroppedDown, 'keine Vorschlaege');
  finally
    FForm.Hide;
  end;
end;

procedure TSearchEditTests.EnterSubmits;
var
  S: TPPGSearchEdit;
  K: Word;
begin
  FForm.Show;
  try
    S := NewSearch(FForm, Self);
    S.SetFocus;
    TypeSearch(S, 'q');
    FEvents.Clear;
    K := VK_RETURN;
    TSearchAccess(S).FieldKeyDown(K, []);
    CheckEquals(0, K);
    CheckEquals('submit:q', FEvents.CommaText);
    CheckFalse(S.SearchPending, 'wartende Suche entfaellt');
    CheckTrue(TSearchAccess(S).WantSpecialKey(VK_RETURN), 'Enter nicht an den Default-Button');
  finally
    FForm.Hide;
  end;
end;

procedure TSearchEditTests.EscapeClears;
var
  S: TPPGSearchEdit;
  K: Word;
begin
  FForm.Show;
  try
    S := NewSearch(FForm, Self);
    S.SearchDelay := 0;
    S.SetFocus;
    TypeSearch(S, 'z');
    FEvents.Clear;
    CheckTrue(TSearchAccess(S).WantSpecialKey(VK_ESCAPE));
    K := VK_ESCAPE;
    TSearchAccess(S).FieldKeyDown(K, []);
    CheckEquals('', S.Text);
    CheckEquals('change,search:', FEvents.CommaText);
    CheckFalse(TSearchAccess(S).WantSpecialKey(VK_ESCAPE), 'leer: Esc gehoert dem Formular');
  finally
    FForm.Hide;
  end;
end;

procedure TSearchEditTests.CodeTextWithoutEvents;
var
  S: TPPGSearchEdit;
begin
  S := NewSearch(FForm, Self);
  S.Text := 'Code';
  CheckEquals('Code', S.Text);
  CheckFalse(S.SearchPending);
  CheckEquals(0, FEvents.Count);
  CheckTrue(S.FilterMode = fmContains);
  CheckTrue(S.ShowClearButton);
  CheckFalse(S.AutoComplete);
  CheckEquals(300, S.SearchDelay);
end;

procedure TSearchEditTests.DropButtonHidden;
var
  S: TPPGSearchEdit;
begin
  S := NewSearch(FForm, Self);
  CheckFalse(IsRectEmpty(TSearchAccess(S).ButtonRect(PPGSearchButtonQuery)), 'Lupe');
  CheckFalse(TSearchAccess(S).ButtonVisible(PPGComboButtonDrop), 'kein Pfeil');
  CheckTrue(TSearchAccess(S).ButtonAt(
    TSearchAccess(S).ButtonRect(PPGSearchButtonQuery).Left + 2, 12) >= 0);
  FEvents.Clear;
  TSearchAccess(S).ButtonClick(PPGSearchButtonQuery);
  CheckEquals('submit:', FEvents.CommaText, 'Lupe sendet ab');
end;

procedure TSearchEditTests.NoFilterBeforeSearch;
var
  S: TPPGSearchEdit;
begin
  FForm.Show;
  try
    S := NewSearch(FForm, Self);
    S.Items.CommaText := 'Apfel,Banane,Traube';
    S.SetFocus;
    S.DropDown;
    TypeSearch(S, 'b');
    CheckTrue(S.SearchPending);
    CheckEquals(3, S.PopupList.RowCount, 'vor der Suche keine Filterung alter Vorschlaege');
    S.FlushSearch;
    CheckEquals(2, S.PopupList.RowCount, 'nach der Suche gefiltert (Banane, Traube)');
    S.CloseUp(False);
  finally
    FForm.Hide;
  end;
end;

{ TPhase7aPaintTests }

procedure TPhase7aPaintTests.PaintAllPresetsAndModes;
var
  Names: TStringList;
  P: Integer;
  Dark, Gdi: Boolean;
  List: array of TWinControl;
  L: TPPGLabel;
  I: Integer;
  Info: TPPGInfoBar;
  Bmp: TBitmap;
begin
  Names := TStringList.Create;
  try
    TPPGRendererRegistry.GetNames(Names);
    FForm.Show;
    try
      for P := 0 to Names.Count - 1 do
        for Dark := False to True do
          for Gdi := False to True do
          begin
            if Dark then
              TPPGTheme.Mode := tmDark
            else
              TPPGTheme.Mode := tmLight;
            TPPGRendererRegistry.ForceGdiFallback := Gdi;
            SetLength(List, 0);
            SetLength(List, 9);
            List[0] := TPPGLinkLabel.Create(FForm);
            TPPGLinkLabel(List[0]).Caption := 'Ein <a href="x">Link</a>';
            List[1] := TPPGBadge.Create(FForm);
            TPPGBadge(List[1]).Value := 5;
            List[2] := TPPGProgressRing.Create(FForm);
            TPPGProgressRing(List[2]).Indeterminate := False;
            TPPGProgressRing(List[2]).Value := 60;
            Info := TPPGInfoBar.Create(FForm);
            Info.Width := 360;
            Info.Severity := psWarning;
            Info.Title := 'Achtung';
            Info.Message := 'Text';
            Info.ActionCaption := 'OK';
            List[3] := Info;
            List[4] := TPPGExpander.Create(FForm);
            TPPGExpander(List[4]).Detail := 'Detail';
            List[5] := TPPGSplitter.Create(FForm);
            List[6] := TPPGRating.Create(FForm);
            TPPGRating(List[6]).Value := 3;
            List[7] := TPPGSearchEdit.Create(FForm);
            TPPGSearchEdit(List[7]).Text := 'Suche';
            List[8] := TPPGBadge.Create(FForm);
            TPPGBadge(List[8]).Kind := bkDot;
            for I := 0 to High(List) do
            begin
              List[I].Parent := FForm;
              TCCAccess(List[I]).Preset := Names[P];
              RenderToBitmap(List[I]).Free;
            end;
            L := TPPGLabel.Create(FForm);
            L.Parent := FForm;
            L.AllowMarkup := True;
            L.Caption := '<b>Label</b>';
            Bmp := PaintLabel(L);
            Bmp.Free;
            L.Free;
            for I := 0 to High(List) do
              List[I].Free;
          end;
    finally
      FForm.Hide;
      TPPGTheme.Mode := tmLight;
      TPPGRendererRegistry.ForceGdiFallback := False;
    end;
  finally
    Names.Free;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

procedure TPhase7aPaintTests.NoHandleOrMemoryLeaks;

  procedure Cycle;
  var
    I: Integer;
    C: TWinControl;
    L: TPPGLabel;
  begin
    for I := 1 to 5 do
    begin
      C := TPPGLinkLabel.Create(FForm);
      C.Parent := FForm;
      TPPGLinkLabel(C).Caption := '<a href="x">L</a>';
      RenderToBitmap(C).Free;
      C.Free;
      C := TPPGProgressRing.Create(FForm);
      C.Parent := FForm;
      RenderToBitmap(C).Free;
      C.Free;
      C := TPPGInfoBar.Create(FForm);
      C.Parent := FForm;
      TPPGInfoBar(C).Message := 'Hinweis';
      RenderToBitmap(C).Free;
      C.Free;
      C := TPPGExpander.Create(FForm);
      C.Parent := FForm;
      TPPGExpander(C).Expanded := False;
      RenderToBitmap(C).Free;
      C.Free;
      C := TPPGRating.Create(FForm);
      C.Parent := FForm;
      RenderToBitmap(C).Free;
      C.Free;
      C := TPPGSearchEdit.Create(FForm);
      C.Parent := FForm;
      TPPGSearchEdit(C).Items.CommaText := 'a,b';
      RenderToBitmap(C).Free;
      C.Free;
      C := TPPGSplitter.Create(FForm);
      C.Parent := FForm;
      RenderToBitmap(C).Free;
      C.Free;
      L := TPPGLabel.Create(FForm);
      L.Parent := FForm;
      L.AllowMarkup := True;
      L.Caption := '<i>x</i>';
      PaintLabel(L).Free;
      L.Free;
    end;
  end;

var
  Gdi0, User0: Cardinal;
  M0, M1: NativeUInt;
begin
  FForm.Show;
  try
    Cycle;
    Gdi0 := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
    User0 := GetGuiResources(GetCurrentProcess, GR_USEROBJECTS);
    M0 := AllocatedBytes;
    Cycle;
    Cycle;
    M1 := AllocatedBytes;
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS) <= Gdi0 + 2, 'GDI-Handles wachsen');
    CheckTrue(GetGuiResources(GetCurrentProcess, GR_USEROBJECTS) <= User0 + 2, 'USER-Handles wachsen');
    CheckTrue(M1 <= M0 + 2048, Format('Speicher waechst: %d -> %d', [M0, M1]));
  finally
    FForm.Hide;
  end;
  CheckEquals(0, FErrors.Count, FErrors.Text);
end;

initialization
  RegisterClasses([TPPGLabel, TPPGLinkLabel, TPPGBadge, TPPGProgressRing, TPPGInfoBar,
    TPPGExpander, TPPGSplitter, TPPGRating, TPPGSearchEdit]);
  RegisterTest('Phase7a', TLabelTests.Suite);
  RegisterTest('Phase7a', TFeedbackTests.Suite);
  RegisterTest('Phase7a', TExpanderTests.Suite);
  RegisterTest('Phase7a', TSplitterTests.Suite);
  RegisterTest('Phase7a', TRatingTests.Suite);
  RegisterTest('Phase7a', TSearchEditTests.Suite);
  RegisterTest('Phase7a', TPhase7aPaintTests.Suite);

end.
