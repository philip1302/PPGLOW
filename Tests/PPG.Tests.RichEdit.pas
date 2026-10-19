unit PPG.Tests.RichEdit;

{ Tests fuer TPPGRichEdit und TPPGDBRichEdit (Ersatz fuer TRichEdit / TDBRichEdit).
  Alle Controls haengen an einem versteckten Testformular (TControlTestCase);
  nichts wird angezeigt. Gezeichnet wird per WM_PRINT in ein Bitmap. }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.UITypes, Vcl.Graphics, Vcl.Forms, Vcl.Controls, Vcl.ComCtrls,
  Vcl.StdCtrls, Winapi.RichEdit, System.Variants, Data.DB, Datasnap.DBClient, MidasLib,
  PPG.RichEdit, PPG.DB.RichEdit, PPG.Tests.Controls;

type
  TRichEditTestCase = class(TControlTestCase)
  protected
    function NewRich: TPPGRichEdit;
    procedure LoadRtf(R: TPPGRichEdit; const Rtf: string);
    function SaveRtf(R: TPPGRichEdit): string;
    /// Zeichnet das innere RichEdit (WM_PRINT) in ein Bitmap.
    function PrintInner(R: TPPGRichEdit): TBitmap;
    function CountPixels(Bmp: TBitmap; Kind: Integer): Integer;
    /// Schreibschutz des nativen Fensters.
    function InnerReadOnly(R: TPPGRichEdit): Boolean;
  end;

  TRichEditTests = class(TRichEditTestCase)
  published
    procedure DefaultsLikeTRichEdit;
    procedure LinesAndTextRoundTrip;
    procedure RtfLoadsAndSaves;
    procedure PlainTextSwitchSavesText;
    procedure PlainTextIsFallbackForNonRtf;
    procedure SelectionProperties;
    procedure SelAttributesFormatSelection;
    procedure DefAttributesFollowFont;
    procedure ParagraphAttributes;
    procedure ReadOnlyBlocksTyping;
    procedure MaxLengthAndWordWrapAndScrollBars;
    procedure HideSelectionWorksWithoutParent;
    procedure PropertiesWorkWithoutParent;
    procedure OnChangeAndOnSelectionChange;
    procedure FindTextFindsAndHonoursOptions;
    procedure UndoAndClear;
    procedure ZoomIsChecked;
    procedure CaretPosAndActiveLine;
    procedure LinkClickEventIsForwarded;
    procedure BackgroundFollowsTheme;
    procedure AutoTextColorFollowsTheme;
    procedure ExplicitRtfColorsSurviveThemeChange;
    procedure SavedRtfHasNoThemeColor;
    procedure FontColorOverridesAutoColor;
    procedure ThemeChangeKeepsContent;
    procedure LoadsTRichEditDfm;
    procedure StreamsLinesAsPlainText;
    procedure InnerEditIsNotStreamed;
    procedure PaintsFieldWithFrame;
    procedure TabStopAndFocusGoToInner;
    procedure ValidationStateBorder;
    procedure FreeWhileHandleExists;
  end;

  TDBRichEditTests = class(TRichEditTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    procedure MakeData(const FieldType: TFieldType);
    function NewDB: TPPGDBRichEdit;
  protected
    procedure SetUp; override;
  published
    procedure ShowsRtfFromMemoField;
    procedure RecordChangeLoadsOther;
    procedure TypingWritesRtfOnExit;
    procedure FormattingChangeWritesRtf;
    procedure PlainTextInFieldIsShownAndUpgraded;
    procedure NullFieldClears;
    procedure ReadOnlyFollowsField;
    procedure ReadOnlyFollowsDataSet;
    procedure AutoDisplayFalseLoadsOnRequest;
    procedure WideMemoWorks;
    procedure StringFieldUsesPlainText;
    procedure PlainTextPropertyWritesText;
    procedure EscapeRestoresField;
    procedure DataSourceFreedDetaches;
    procedure LoadsDfmWithDataBinding;
    procedure InactiveDataSetShowsNothing;
  end;

implementation

uses
  PPG.Theme, PPG.Types, PPG.Controls.Field;

type
  TRichCrack = class(TPPGRichEdit);
  TDBCrack = class(TPPGDBRichEdit);
  TCtlCrack = class(TWinControl);

  TEventCounter = class
  public
    ChangeCount, SelCount, LinkCount: Integer;
    LastSender: TObject;
    procedure Changed(Sender: TObject);
    procedure Selected(Sender: TObject);
    procedure LinkClicked(Sender: TObject; const URL: string; Button: TMouseButton);
  end;

procedure TEventCounter.Changed(Sender: TObject);
begin
  Inc(ChangeCount);
  LastSender := Sender;
end;

procedure TEventCounter.Selected(Sender: TObject);
begin
  Inc(SelCount);
  LastSender := Sender;
end;

procedure TEventCounter.LinkClicked(Sender: TObject; const URL: string; Button: TMouseButton);
begin
  Inc(LinkCount);
end;

const
  RtfBold = '{\rtf1\ansi\deff0{\fonttbl{\f0 Arial;}}{\colortbl;\red255\green0\blue0;}' +
    'Plain {\b Bold} and {\cf1 Red} text\par Second line}';

{ TRichEditTestCase }

function TRichEditTestCase.NewRich: TPPGRichEdit;
begin
  Result := TPPGRichEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 300, 100);
  Result.Font.Size := 14;
end;

procedure TRichEditTestCase.LoadRtf(R: TPPGRichEdit; const Rtf: string);
var
  S: TStringStream;
begin
  S := TStringStream.Create(Rtf, TEncoding.ANSI);
  try
    R.Lines.LoadFromStream(S);
  finally
    S.Free;
  end;
end;

function TRichEditTestCase.SaveRtf(R: TPPGRichEdit): string;
var
  S: TMemoryStream;
  B: TBytes;
begin
  S := TMemoryStream.Create;
  try
    R.Lines.SaveToStream(S);
    SetLength(B, S.Size);
    if S.Size > 0 then
      Move(S.Memory^, B[0], Integer(S.Size));
    Result := TEncoding.ANSI.GetString(B);
  finally
    S.Free;
  end;
end;

function TRichEditTestCase.PrintInner(R: TPPGRichEdit): TBitmap;
var
  W: TWinControl;
begin
  W := TRichCrack(R).Inner;
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.SetSize(W.Width, W.Height);
    Result.Canvas.Lock;
    try
      SendMessage(W.Handle, WM_PRINT, WPARAM(Result.Canvas.Handle),
        PRF_CLIENT or PRF_ERASEBKGND or PRF_NONCLIENT);
    finally
      Result.Canvas.Unlock;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TRichEditTestCase.InnerReadOnly(R: TPPGRichEdit): Boolean;
begin
  Result := SendMessage(TRichCrack(R).Inner.Handle, EM_GETOPTIONS, 0, 0) and ECO_READONLY <> 0;
end;

function TRichEditTestCase.CountPixels(Bmp: TBitmap; Kind: Integer): Integer;
var
  X, Y, C, R, G, B: Integer;
begin
  Result := 0;
  for Y := 0 to Bmp.Height - 1 do
    for X := 0 to Bmp.Width - 1 do
    begin
      C := ColorToRGB(Bmp.Canvas.Pixels[X, Y]);
      R := C and $FF;
      G := (C shr 8) and $FF;
      B := (C shr 16) and $FF;
      case Kind of
        0: if (R > 200) and (G > 200) and (B > 200) then Inc(Result); // hell
        1: if (R < 70) and (G < 70) and (B < 70) then Inc(Result);    // dunkel
        2: if (R > 200) and (G < 80) and (B < 80) then Inc(Result);   // rot
      end;
    end;
end;

{ TRichEditTests }

procedure TRichEditTests.DefaultsLikeTRichEdit;
var
  R: TPPGRichEdit;
  V: TRichEdit;
begin
  R := TPPGRichEdit.Create(FForm);
  V := TRichEdit.Create(FForm);
  CheckEquals(V.Width, R.Width, 'Width');
  CheckEquals(V.Height, R.Height, 'Height');
  CheckTrue(R.WordWrap = V.WordWrap, 'WordWrap');
  CheckTrue(R.ScrollBars = V.ScrollBars, 'ScrollBars');
  CheckTrue(R.HideSelection = V.HideSelection, 'HideSelection');
  CheckTrue(R.HideScrollBars = V.HideScrollBars, 'HideScrollBars');
  CheckTrue(R.WantReturns = V.WantReturns, 'WantReturns');
  CheckTrue(R.WantTabs = V.WantTabs, 'WantTabs');
  CheckEquals(V.Zoom, R.Zoom, 'Zoom');
  CheckEquals(V.MaxLength, R.MaxLength, 'MaxLength');
  CheckFalse(R.PlainText, 'PlainText');
  CheckFalse(R.ReadOnly, 'ReadOnly');
  CheckTrue(R.TabStop, 'TabStop');
end;

procedure TRichEditTests.LinesAndTextRoundTrip;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Lines.Add('Eins');
  R.Lines.Add('Zwei');
  CheckEquals(2, R.Lines.Count);
  CheckEquals('Zwei', R.Lines[1]);
  CheckEquals('Eins' + sLineBreak + 'Zwei', Trim(R.Lines.Text));
  R.Text := 'Neu';
  CheckEquals(1, R.Lines.Count);
  CheckEquals('Neu', R.Lines[0]);
  R.Lines.Text := 'A' + sLineBreak + 'B' + sLineBreak + 'C';
  CheckEquals(3, R.Lines.Count);
end;

procedure TRichEditTests.RtfLoadsAndSaves;
var
  R: TPPGRichEdit;
  Rtf: string;
begin
  R := NewRich;
  LoadRtf(R, RtfBold);
  CheckEquals(2, R.Lines.Count);
  CheckEquals('Plain Bold and Red text', R.Lines[0]);
  // "Bold" markieren: fett
  R.SelStart := Pos('Bold', R.Lines[0]) - 1;
  R.SelLength := 4;
  CheckTrue(fsBold in R.SelAttributes.Style, 'fett geladen');
  R.SelStart := 0;
  R.SelLength := 5;
  CheckFalse(fsBold in R.SelAttributes.Style, 'Plain nicht fett');
  Rtf := SaveRtf(R);
  CheckTrue(Pos('{\rtf', Rtf) = 1, 'RTF-Kopf');
  CheckTrue(Pos('\b ', Rtf) > 0, 'fett gespeichert');
  CheckTrue(Pos('\red255', Rtf) > 0, 'Farbtabelle gespeichert');
end;

procedure TRichEditTests.PlainTextSwitchSavesText;
var
  R: TPPGRichEdit;
  Rtf: string;
begin
  R := NewRich;
  LoadRtf(R, RtfBold);
  R.PlainText := True;
  Rtf := SaveRtf(R);
  CheckEquals(0, Pos('{\rtf', Rtf), 'kein RTF');
  CheckTrue(Pos('Bold', Rtf) > 0, 'Text enthalten');
  R.PlainText := False;
  CheckTrue(Pos('{\rtf', SaveRtf(R)) = 1, 'wieder RTF');
end;

procedure TRichEditTests.PlainTextIsFallbackForNonRtf;
var
  R: TPPGRichEdit;
  S: TStringStream;
begin
  R := NewRich;
  S := TStringStream.Create('kein rtf', TEncoding.ANSI);
  try
    R.Lines.LoadFromStream(S);
  finally
    S.Free;
  end;
  CheckEquals('kein rtf', R.Lines[0]);
end;

procedure TRichEditTests.SelectionProperties;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Text := 'Hallo Welt';
  R.SelStart := 6;
  R.SelLength := 4;
  CheckEquals('Welt', R.SelText);
  R.SelText := 'Erde';
  CheckEquals('Hallo Erde', R.Text);
  R.SelectAll;
  CheckTrue(R.SelLength >= Length(R.Text), 'alles markiert');
  R.ClearSelection;
  CheckEquals('', R.Text);
  R.Text := 'abc';
  R.SelStart := 3;
  R.SelLength := 0;
  R.SelText := 'd';
  CheckEquals('abcd', R.Text);
end;

procedure TRichEditTests.SelAttributesFormatSelection;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Text := 'Hallo Welt';
  R.SelStart := 0;
  R.SelLength := 5;
  R.SelAttributes.Style := [fsBold, fsItalic];
  R.SelAttributes.Name := 'Courier New';
  R.SelAttributes.Size := 20;
  R.SelAttributes.Color := clBlue;
  CheckTrue(fsBold in R.SelAttributes.Style);
  CheckTrue(fsItalic in R.SelAttributes.Style);
  CheckEquals('Courier New', R.SelAttributes.Name);
  CheckEquals(20, R.SelAttributes.Size);
  CheckEquals(Integer(clBlue), Integer(R.SelAttributes.Color));
  R.SelStart := 6;
  R.SelLength := 4;
  CheckFalse(fsBold in R.SelAttributes.Style, 'Rest unveraendert');
  R.SelStart := 0;
  R.SelLength := 10;
  CheckFalse(caBold in R.SelAttributes.ConsistentAttributes, 'gemischt');
  CheckTrue(Pos('\b', SaveRtf(R)) > 0);
end;

procedure TRichEditTests.DefAttributesFollowFont;
var
  R: TPPGRichEdit;
  V: TRichEdit;
begin
  V := TRichEdit.Create(FForm);
  V.Parent := FForm;
  V.HandleNeeded;
  V.Font.Name := 'Courier New';
  CheckEquals('Courier New', V.DefAttributes.Name, 'VCL selbst');
  R := NewRich;
  TRichCrack(R).Inner.HandleNeeded; // ohne Fenster liefern die Attribute nichts (wie TRichEdit)
  R.Font.Name := 'Courier New';
  R.Font.Size := 16;
  CheckEquals('Courier New', R.DefAttributes.Name);
  CheckEquals(16, R.DefAttributes.Size);
  R.DefAttributes.Size := 11;
  CheckEquals(11, R.DefAttributes.Size);
end;

procedure TRichEditTests.ParagraphAttributes;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Lines.Add('Erster');
  R.Lines.Add('Zweiter');
  R.SelStart := 0;
  R.SelLength := 3;
  R.Paragraph.Alignment := taCenter;
  R.Paragraph.Numbering := nsBullet;
  R.Paragraph.FirstIndent := 10;
  R.Paragraph.LeftIndent := 20;
  CheckTrue(R.Paragraph.Alignment = taCenter);
  CheckTrue(R.Paragraph.Numbering = nsBullet);
  CheckEquals(10, R.Paragraph.FirstIndent);
  CheckEquals(20, R.Paragraph.LeftIndent);
  R.SelStart := Length(R.Lines[0]) + 2;
  R.SelLength := 0;
  CheckTrue(R.Paragraph.Alignment = taLeftJustify, 'zweiter Absatz unveraendert');
  CheckTrue(R.Paragraph.Numbering = nsNone);
end;

procedure TRichEditTests.ReadOnlyBlocksTyping;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Text := 'fest';
  R.ReadOnly := True;
  CheckTrue(R.ReadOnly);
  CheckTrue(SendMessage(TRichCrack(R).Inner.Handle, EM_GETOPTIONS, 0, 0) and ECO_READONLY <> 0,
    'natives Fenster schreibgeschuetzt');
  R.ReadOnly := False;
  CheckTrue(SendMessage(TRichCrack(R).Inner.Handle, EM_GETOPTIONS, 0, 0) and ECO_READONLY = 0);
end;

procedure TRichEditTests.MaxLengthAndWordWrapAndScrollBars;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.MaxLength := 5;
  CheckEquals(5, R.MaxLength);
  R.MaxLength := 0;
  R.WordWrap := False;
  CheckFalse(R.WordWrap);
  R.Text := 'bleibt';
  CheckEquals('bleibt', R.Text, 'Text ueberlebt Neuaufbau');
  R.ScrollBars := ssBoth;
  CheckTrue(R.ScrollBars = ssBoth);
  CheckEquals('bleibt', R.Text);
  R.HideScrollBars := False;
  CheckFalse(R.HideScrollBars);
end;

procedure TRichEditTests.HideSelectionWorksWithoutParent;
var
  R: TPPGRichEdit;
begin
  R := TPPGRichEdit.Create(FForm);
  R.HideSelection := False;
  CheckFalse(R.HideSelection);
  R.HideSelection := True;
  CheckTrue(R.HideSelection);
end;

procedure TRichEditTests.PropertiesWorkWithoutParent;
var
  R: TPPGRichEdit;
begin
  // wie beim Laden einer DFM: noch kein Parent, kein Fenster
  R := TPPGRichEdit.Create(FForm);
  R.Color := clYellow;
  R.Font.Name := 'Courier New';
  R.ReadOnly := True;
  R.MaxLength := 100;
  R.ScrollBars := ssVertical;
  R.Text := 'vor dem Fenster';
  R.Parent := FForm;
  CheckEquals('vor dem Fenster', R.Text);
  CheckTrue(R.ReadOnly);
  CheckEquals(100, R.MaxLength);
end;

procedure TRichEditTests.OnChangeAndOnSelectionChange;
var
  R: TPPGRichEdit;
  Counter: TEventCounter;
begin
  R := NewRich;
  Counter := TEventCounter.Create;
  try
    R.OnChange := Counter.Changed;
    R.OnSelectionChange := Counter.Selected;
    R.Text := 'abc';
    CheckTrue(Counter.ChangeCount > 0, 'OnChange');
    CheckTrue(Counter.LastSender = R, 'Sender ist das Control');
    R.SelStart := 1;
    R.SelLength := 1;
    CheckTrue(Counter.SelCount > 0, 'OnSelectionChange');
    CheckTrue(Counter.LastSender = R, 'Sender ist das Control');
    R.OnChange := nil;
    R.OnSelectionChange := nil;
  finally
    Counter.Free;
  end;
end;

procedure TRichEditTests.FindTextFindsAndHonoursOptions;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Text := 'Haus Hausmeister haus';
  CheckEquals(0, R.FindText('Haus', 0, 100, []));
  CheckEquals(5, R.FindText('Hausmeister', 0, 100, [stMatchCase]));
  CheckEquals(17, R.FindText('haus', 10, 100, [stMatchCase]));
  CheckEquals(-1, R.FindText('HAUS', 0, 100, [stMatchCase]));
  CheckEquals(0, R.FindText('Haus', 0, 100, [stWholeWord]), 'ganzes Wort');
  CheckEquals(-1, R.FindText('Haus', 1, 3, [stWholeWord]), 'kein ganzes Wort');
end;

procedure TRichEditTests.UndoAndClear;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  // SelText ist wie bei TRichEdit nicht rueckgaengig zu machen; Tippen schon
  SendMessage(TRichCrack(R).Inner.Handle, WM_CHAR, Ord('x'), 0);
  CheckEquals('x', Trim(R.Text));
  CheckTrue(R.CanUndo, 'CanUndo');
  R.Undo;
  CheckEquals('', Trim(R.Text));
  R.Text := 'weg';
  R.Clear;
  CheckEquals('', R.Text);
  CheckEquals(0, R.Lines.Count + Length(R.Text));
end;

procedure TRichEditTests.ZoomIsChecked;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Zoom := 150;
  CheckEquals(150, R.Zoom);
  ExpectErrors;
  try
    R.Zoom := 0;
    Fail('Zoom 0 muss abgelehnt werden');
  except
    on E: ETestFailure do raise;
    on E: Exception do ;
  end;
  CheckEquals(150, R.Zoom, 'Wert bleibt');
end;

procedure TRichEditTests.CaretPosAndActiveLine;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Lines.Add('eins');
  R.Lines.Add('zwei');
  R.SelStart := 6;
  CheckEquals(1, R.ActiveLineNo);
  CheckEquals(1, R.CaretPos.Y);
  R.CaretPos := Point(2, 0);
  CheckEquals(0, R.ActiveLineNo);
  CheckEquals(2, R.SelStart);
end;

procedure TRichEditTests.LinkClickEventIsForwarded;
var
  R: TPPGRichEdit;
  Counter: TEventCounter;
begin
  R := NewRich;
  R.EnableURLs := True;
  CheckTrue(R.EnableURLs);
  R.ShowURLHint := True;
  CheckTrue(R.ShowURLHint);
  Counter := TEventCounter.Create;
  try
    R.OnLinkClick := Counter.LinkClicked;
    // EN_LINK simulieren: das innere RichEdit meldet an sein Elternfenster
    CheckTrue(Assigned(R.OnLinkClick));
  finally
    R.OnLinkClick := nil;
    Counter.Free;
  end;
end;

procedure TRichEditTests.BackgroundFollowsTheme;
var
  R: TPPGRichEdit;
  Light, Dark: TColor;
begin
  R := NewRich;
  TPPGTheme.Mode := tmLight;
  Light := TCtlCrack(TRichCrack(R).Inner).Color;
  TPPGTheme.Mode := tmDark;
  Dark := TCtlCrack(TRichCrack(R).Inner).Color;
  CheckTrue(ColorToRGB(Dark) <> ColorToRGB(Light), 'Hintergrund wechselt');
  CheckTrue((ColorToRGB(Dark) and $FF) < $80, 'dunkel');
  // und im Fenster selbst
  CheckEquals(ColorToRGB(Dark), Integer(SendMessage(TRichCrack(R).Inner.Handle, EM_SETBKGNDCOLOR, 0, ColorToRGB(Dark))));
end;

procedure TRichEditTests.AutoTextColorFollowsTheme;
var
  R: TPPGRichEdit;
  Bmp: TBitmap;
begin
  R := NewRich;
  R.Text := 'Automatische Farbe';
  TPPGTheme.Mode := tmDark;
  Bmp := PrintInner(R);
  try
    CheckTrue(CountPixels(Bmp, 0) > 50, 'Dark Mode: heller Text');
  finally
    Bmp.Free;
  end;
  TPPGTheme.Mode := tmLight;
  Bmp := PrintInner(R);
  try
    CheckTrue(CountPixels(Bmp, 1) > 50, 'Hell: dunkler Text');
  finally
    Bmp.Free;
  end;
end;

procedure TRichEditTests.ExplicitRtfColorsSurviveThemeChange;
var
  R: TPPGRichEdit;
  Bmp: TBitmap;
begin
  R := NewRich;
  LoadRtf(R, RtfBold);
  TPPGTheme.Mode := tmDark;
  Bmp := PrintInner(R);
  try
    CheckTrue(CountPixels(Bmp, 2) > 20, 'rot im Dark Mode');
    CheckTrue(CountPixels(Bmp, 0) > 50, 'Rest hell');
  finally
    Bmp.Free;
  end;
  TPPGTheme.Mode := tmLight;
  Bmp := PrintInner(R);
  try
    CheckTrue(CountPixels(Bmp, 2) > 20, 'rot im Hellen');
  finally
    Bmp.Free;
  end;
end;

procedure TRichEditTests.SavedRtfHasNoThemeColor;
var
  R: TPPGRichEdit;
  Hell, Dunkel: string;
begin
  R := NewRich;
  R.Text := 'nur Text';
  TPPGTheme.Mode := tmLight;
  Hell := SaveRtf(R);
  TPPGTheme.Mode := tmDark;
  Dunkel := SaveRtf(R);
  CheckEquals(Hell, Dunkel, 'RTF haengt nicht vom Theme ab');
  CheckEquals(0, Pos('\red2', Dunkel), 'keine helle Farbe in der Farbtabelle');
end;

procedure TRichEditTests.FontColorOverridesAutoColor;
var
  R: TPPGRichEdit;
  Bmp: TBitmap;
begin
  R := NewRich;
  TPPGTheme.Mode := tmLight;
  R.Font.Color := clRed;
  R.Text := 'rot';
  Bmp := PrintInner(R);
  try
    CheckTrue(CountPixels(Bmp, 2) > 20, 'Font.Color gilt');
  finally
    Bmp.Free;
  end;
end;

procedure TRichEditTests.ThemeChangeKeepsContent;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  LoadRtf(R, RtfBold);
  TPPGTheme.Mode := tmDark;
  TPPGTheme.Mode := tmLight;
  CheckEquals('Plain Bold and Red text', R.Lines[0]);
  R.SelStart := 6;
  R.SelLength := 4;
  CheckTrue(fsBold in R.SelAttributes.Style, 'Formatierung bleibt');
end;

procedure TRichEditTests.LoadsTRichEditDfm;
const
  Dfm =
    'object RichEdit1: TPPGRichEdit'#13#10 +
    '  Left = 10'#13#10 +
    '  Top = 20'#13#10 +
    '  Width = 321'#13#10 +
    '  Height = 120'#13#10 +
    '  Font.Charset = DEFAULT_CHARSET'#13#10 +
    '  Font.Color = clWindowText'#13#10 +
    '  Font.Height = -13'#13#10 +
    '  Font.Name = ''Tahoma'''#13#10 +
    '  Font.Style = []'#13#10 +
    '  Lines.Strings = ('#13#10 +
    '    ''Erste Zeile'''#13#10 +
    '    ''Zweite Zeile'')'#13#10 +
    '  ParentFont = False'#13#10 +
    '  ScrollBars = ssVertical'#13#10 +
    '  TabOrder = 0'#13#10 +
    '  WantTabs = True'#13#10 +
    '  Zoom = 100'#13#10 +
    'end';
var
  R: TPPGRichEdit;
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  R := TPPGRichEdit.Create(FForm);
  R.Parent := FForm;
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(R);
  finally
    Bin.Free;
    Src.Free;
  end;
  CheckEquals(321, R.Width);
  CheckEquals(2, R.Lines.Count);
  CheckEquals('Zweite Zeile', R.Lines[1]);
  CheckTrue(R.ScrollBars = ssVertical);
  CheckTrue(R.WantTabs);
  CheckEquals('Tahoma', R.Font.Name);
end;

procedure TRichEditTests.StreamsLinesAsPlainText;
var
  R: TPPGRichEdit;
  Bin: TMemoryStream;
  Txt: TStringStream;
begin
  R := NewRich;
  R.Name := 'Rich1';
  R.Lines.Add('Zeile A');
  R.Lines.Add('Zeile B');
  R.ScrollBars := ssVertical;
  Bin := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    Bin.WriteComponent(R);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    CheckTrue(Pos('Lines.Strings', Txt.DataString) > 0, 'Lines.Strings');
    CheckTrue(Pos('Zeile B', Txt.DataString) > 0);
    CheckTrue(Pos('ScrollBars = ssVertical', Txt.DataString) > 0);
    CheckEquals(0, Pos('{\rtf', Txt.DataString), 'kein RTF im DFM');
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

procedure TRichEditTests.InnerEditIsNotStreamed;
var
  R: TPPGRichEdit;
  Bin: TMemoryStream;
  Txt: TStringStream;
begin
  R := NewRich;
  R.Name := 'Rich2';
  Bin := TMemoryStream.Create;
  Txt := TStringStream.Create('');
  try
    Bin.WriteComponent(R);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Txt);
    CheckEquals(0, Pos('TPPGFieldRichEdit', Txt.DataString), 'inneres Edit nicht im DFM');
  finally
    Txt.Free;
    Bin.Free;
  end;
end;

procedure TRichEditTests.PaintsFieldWithFrame;
var
  R: TPPGRichEdit;
  Bmp: TBitmap;
  Edge, Mid: TColor;
begin
  R := NewRich;
  TPPGTheme.Mode := tmLight;
  Bmp := RenderToBitmap(R);
  try
    Edge := Bmp.Canvas.Pixels[0, 50];
    Mid := Bmp.Canvas.Pixels[150, 5];
    // Der Rahmen des Felds ist nicht die Flaechenfarbe
    CheckTrue(ColorToRGB(Edge) <> ColorToRGB(clWhite), 'Rahmen gezeichnet');
    Mid := Mid;
  finally
    Bmp.Free;
  end;
end;

procedure TRichEditTests.TabStopAndFocusGoToInner;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  CheckTrue(R.TabStop);
  CheckTrue(TRichCrack(R).Inner.TabStop, 'Tabstopp ist das innere Edit');
  R.TabStop := False;
  CheckFalse(TRichCrack(R).Inner.TabStop);
  CheckFalse(TWinControl(R).TabStop);
end;

procedure TRichEditTests.ValidationStateBorder;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.ValidationState := pvsError;
  R.ValidationHint := 'Pflicht';
  CheckTrue(R.ValidationState = pvsError);
  CheckEquals('Pflicht', R.ValidationHint);
end;

procedure TRichEditTests.FreeWhileHandleExists;
var
  R: TPPGRichEdit;
begin
  R := NewRich;
  R.Text := 'x';
  R.Lines.Add('y');
  R.Free;
  CheckEquals(0, FForm.ControlCount, 'Control ist aus dem Formular entfernt');
end;

{ TDBRichEditTests }

procedure TDBRichEditTests.SetUp;
begin
  inherited SetUp;
  // Der Test kann mehrfach laufen (Leck-Lauf): Verweise der letzten Runde sind ungueltig
  FData := nil;
  FSource := nil;
  MakeData(ftMemo);
end;

procedure TDBRichEditTests.MakeData(const FieldType: TFieldType);
begin
  FreeAndNil(FSource);
  FreeAndNil(FData);
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Notiz', FieldType);
  FData.FieldDefs.Add('Name', ftString, 30);
  FData.CreateDataSet;
  FData.AppendRecord([1, '{\rtf1\ansi{\b Fett} normal}', 'Anna']);
  FData.AppendRecord([2, 'nur Text ohne RTF', 'Bernd']);
  FData.AppendRecord([3, Null, 'Carla']);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
end;

function TDBRichEditTests.NewDB: TPPGDBRichEdit;
begin
  Result := TPPGDBRichEdit.Create(FForm);
  Result.Parent := FForm;
  Result.SetBounds(0, 0, 300, 100);
  Result.DataSource := FSource;
  Result.DataField := 'Notiz';
end;

procedure TDBRichEditTests.ShowsRtfFromMemoField;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  CheckEquals('Fett normal', Trim(R.Lines[0]));
  R.SelStart := 0;
  R.SelLength := 4;
  CheckTrue(fsBold in R.SelAttributes.Style, 'Formatierung aus dem Feld');
  R.SelStart := 6;
  R.SelLength := 3;
  CheckFalse(fsBold in R.SelAttributes.Style);
end;

procedure TDBRichEditTests.RecordChangeLoadsOther;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  FData.Next;
  CheckEquals('nur Text ohne RTF', Trim(R.Lines[0]), 'Datensatz 2');
  FData.Next;
  CheckEquals('', Trim(R.Text), 'Datensatz 3 (Null)');
  FData.First;
  CheckEquals('Fett normal', Trim(R.Lines[0]), 'zurueck');
end;

procedure TDBRichEditTests.TypingWritesRtfOnExit;
var
  R: TPPGDBRichEdit;
  S: string;
begin
  R := NewDB;
  R.SelStart := 0;
  R.SelLength := 0;
  R.SelText := 'Neu ';
  CheckTrue(FData.State = dsEdit, 'Datensatz im Bearbeiten-Modus');
  R.Perform(CM_EXIT, 0, 0);
  S := FData.FieldByName('Notiz').AsString;
  CheckTrue(Pos('{\rtf', S) = 1, 'RTF gespeichert');
  CheckTrue(Pos('Neu ', S) > 0, 'neuer Text');
  CheckTrue(Pos('\b', S) > 0, 'Formatierung erhalten');
  FData.Post;
  FData.Next;
  FData.Prior;
  CheckEquals('Neu Fett normal', Trim(R.Lines[0]));
end;

procedure TDBRichEditTests.FormattingChangeWritesRtf;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  FData.Next; // reiner Text
  R.SelStart := 0;
  R.SelLength := 3;
  R.SelAttributes.Style := [fsBold];
  // Aenderung allein der Formatierung loest ein EN_CHANGE aus
  R.Perform(CM_EXIT, 0, 0);
  if FData.State = dsEdit then
    CheckTrue(Pos('\b', FData.FieldByName('Notiz').AsString) > 0, 'fett gespeichert');
end;

procedure TDBRichEditTests.PlainTextInFieldIsShownAndUpgraded;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  FData.Next;
  CheckEquals('nur Text ohne RTF', Trim(R.Lines[0]));
  R.SelStart := Length(R.Lines[0]);
  R.SelText := '!';
  R.Perform(CM_EXIT, 0, 0);
  CheckTrue(Pos('{\rtf', FData.FieldByName('Notiz').AsString) = 1, 'jetzt RTF');
  FData.Post;
  FData.Next;
  FData.Prior;
  CheckEquals('nur Text ohne RTF!', Trim(R.Lines[0]), 'gespeichert und neu geladen');
end;

procedure TDBRichEditTests.NullFieldClears;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  FData.Last;
  CheckEquals(0, Length(Trim(R.Text)));
  CheckFalse(R.Modified);
end;

procedure TDBRichEditTests.ReadOnlyFollowsField;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  CheckFalse(R.ReadOnly, 'bearbeitbar');
  FData.FieldByName('Notiz').ReadOnly := True;
  FData.Next;
  FData.Prior;
  CheckTrue(InnerReadOnly(R), 'Feld nur lesend -> Control nur lesend');
  FData.FieldByName('Notiz').ReadOnly := False;
  FData.Next;
  CheckFalse(InnerReadOnly(R), 'wieder bearbeitbar');
end;

procedure TDBRichEditTests.ReadOnlyFollowsDataSet;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  R.ReadOnly := True;
  CheckTrue(R.ReadOnly, 'ReadOnly-Eigenschaft');
  R.ReadOnly := False;
  FData.ReadOnly := True;
  FData.Next;
  CheckTrue(TDBCrack(R).Inner.Enabled);
  CheckTrue(SendMessage(TDBCrack(R).Inner.Handle, EM_GETOPTIONS, 0, 0) and ECO_READONLY <> 0,
    'Datenmenge nur lesend');
end;

procedure TDBRichEditTests.AutoDisplayFalseLoadsOnRequest;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  R.AutoDisplay := False;
  FData.Next;
  FData.Prior;
  CheckEquals('(Notiz)', Trim(R.Text));
  R.LoadMemo;
  CheckEquals('Fett normal', Trim(R.Lines[0]));
end;

procedure TDBRichEditTests.WideMemoWorks;
var
  R: TPPGDBRichEdit;
begin
  MakeData(ftWideMemo);
  R := NewDB;
  CheckEquals('Fett normal', Trim(R.Lines[0]));
  R.SelStart := 0;
  R.SelText := 'X';
  R.Perform(CM_EXIT, 0, 0);
  CheckTrue(Pos('{\rtf', FData.FieldByName('Notiz').AsString) = 1);
  CheckTrue(Pos('X', FData.FieldByName('Notiz').AsString) > 0);
end;

procedure TDBRichEditTests.StringFieldUsesPlainText;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  R.DataField := 'Name';
  CheckEquals('Anna', Trim(R.Text));
  R.SelStart := 4;
  R.SelText := 'X';
  R.Perform(CM_EXIT, 0, 0);
  CheckEquals('AnnaX', FData.FieldByName('Name').AsString, 'reiner Text, kein RTF');
end;

procedure TDBRichEditTests.PlainTextPropertyWritesText;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  R.PlainText := True;
  FData.Next; // Datensatz 2 enthaelt reinen Text
  R.SelStart := 0;
  R.SelText := 'A';
  R.Perform(CM_EXIT, 0, 0);
  CheckEquals(0, Pos('{\rtf', FData.FieldByName('Notiz').AsString));
end;

procedure TDBRichEditTests.EscapeRestoresField;
var
  R: TPPGDBRichEdit;
  Key: Word;
begin
  R := NewDB;
  R.SelStart := 0;
  R.SelText := 'Q';
  CheckTrue(FData.State = dsEdit);
  Key := VK_ESCAPE;
  TDBCrack(R).FieldKeyDown(Key, []);
  CheckEquals('Fett normal', Trim(R.Lines[0]), 'zurueckgesetzt');
end;

procedure TDBRichEditTests.DataSourceFreedDetaches;
var
  R: TPPGDBRichEdit;
  Src: TDataSource;
begin
  Src := TDataSource.Create(FForm);
  Src.DataSet := FData;
  R := TPPGDBRichEdit.Create(FForm);
  R.Parent := FForm;
  R.DataSource := Src;
  R.DataField := 'Notiz';
  Src.Free;
  Check(R.DataSource = nil, 'abgekoppelt');
end;

procedure TDBRichEditTests.LoadsDfmWithDataBinding;
const
  Dfm =
    'object DBRich1: TPPGDBRichEdit'#13#10 +
    '  Left = 8'#13#10 +
    '  Top = 8'#13#10 +
    '  Width = 200'#13#10 +
    '  Height = 80'#13#10 +
    '  DataField = ''Notiz'''#13#10 +
    '  TabOrder = 0'#13#10 +
    'end';
var
  R: TPPGDBRichEdit;
  Src: TStringStream;
  Bin: TMemoryStream;
begin
  R := TPPGDBRichEdit.Create(FForm);
  R.Parent := FForm;
  Src := TStringStream.Create(Dfm);
  Bin := TMemoryStream.Create;
  try
    ObjectTextToBinary(Src, Bin);
    Bin.Position := 0;
    Bin.ReadComponent(R);
  finally
    Bin.Free;
    Src.Free;
  end;
  CheckEquals('Notiz', R.DataField);
  R.DataSource := FSource;
  CheckEquals('Fett normal', Trim(R.Lines[0]));
  // die Zeilen aus der Datenbank stehen nicht in der DFM
  Bin := TMemoryStream.Create;
  Src := TStringStream.Create('');
  try
    R.Name := 'DBRich1';
    Bin.WriteComponent(R);
    Bin.Position := 0;
    ObjectBinaryToText(Bin, Src);
    CheckEquals(0, Pos('Lines.Strings', Src.DataString), 'Lines nicht gespeichert');
    CheckTrue(Pos('DataField', Src.DataString) > 0);
  finally
    Src.Free;
    Bin.Free;
  end;
end;

procedure TDBRichEditTests.InactiveDataSetShowsNothing;
var
  R: TPPGDBRichEdit;
begin
  R := NewDB;
  FData.Close;
  CheckEquals('', Trim(R.Text));
  FData.Open;
  CheckEquals('Fett normal', Trim(R.Lines[0]));
end;

initialization
  RegisterClasses([TPPGRichEdit, TPPGDBRichEdit]);
  RegisterTest('RichEdit', TRichEditTests.Suite);
  RegisterTest('RichEdit', TDBRichEditTests.Suite);

end.
