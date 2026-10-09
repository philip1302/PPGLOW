unit PPG.Tests.Streaming;

{ DFM-Pruefung ueber ALLE Paletten-Controls: jede einfache published Property
  wird geaendert, gespeichert und geladen; der geladene Wert muss dem gesetzten
  entsprechen. Dazu Faelle mit abhaengigen Properties (Reihenfolge beim Laden). }

interface

uses
  TestFramework, System.Classes, System.SysUtils, System.TypInfo, Vcl.Controls,
  Vcl.Forms, Vcl.Graphics,
  PPG.Button, PPG.CheckBox, PPG.RadioButton, PPG.ToggleSwitch, PPG.ProgressBar, PPG.TrackBar,
  PPG.Panel, PPG.GroupBox, PPG.RadioGroup, PPG.TileView, PPG.Edit, PPG.Memo, PPG.SpinEdit, PPG.ComboBox, PPG.TabControl,
  PPG.PageControl, PPG.ListBox, PPG.CheckListBox, PPG.TreeView, PPG.Grid,
  PPG.Labels, PPG.Feedback, PPG.Expander, PPG.Splitter, PPG.Rating, PPG.SearchEdit,
  PPG.Calendar, PPG.DatePicker, PPG.TimePicker, PPG.NavigationView, PPG.Breadcrumb,
  PPG.ToolBar, PPG.StatusBar, PPG.Notifications, PPG.Sparkline, PPG.Gauge, PPG.Chart,
  PPG.Tests.Controls;

type
  TStreamingTests = class(TControlTestCase)
  private
    function RoundTrip(C: TComponent): TComponent;
  published
    procedure EveryPropertySurvivesDfm;
    procedure RatingHalfValueSurvivesDfm;
    procedure StatusBarOwnFontSurvivesDfm;
  end;

implementation

const
  ControlClasses: array[0..42] of TComponentClass = (TPPGButton, TPPGCheckBox, TPPGRadioButton,
    TPPGToggleSwitch, TPPGProgressBar, TPPGTrackBar, TPPGPanel, TPPGGroupBox, TPPGEdit,
    TPPGMemo, TPPGSpinEdit, TPPGComboBox, TPPGTabControl, TPPGPageControl, TPPGListBox,
    TPPGCheckListBox, TPPGTreeView, TPPGGrid, TPPGLabel, TPPGLinkLabel, TPPGBadge,
    TPPGProgressRing, TPPGInfoBar, TPPGExpander, TPPGSplitter, TPPGRating, TPPGSearchEdit,
    TPPGCalendar, TPPGDatePicker, TPPGTimePicker, TPPGNavigationView, TPPGBreadcrumb,
    TPPGToolBar, TPPGStatusBar, TPPGNotificationCenter,
    TPPGSparkline, TPPGGauge, TPPGKpiTile, TPPGChart, TPPGRadioGroup, TPPGCheckGroup,
    TPPGTileView, TPPGScrollBox);

  // Layout-, Eltern- und Verweis-Properties gehoeren nicht zum Einzeltest
  SkipProps: array[0..24] of string = ('Name', 'Left', 'Top', 'Width', 'Height', 'Align',
    'Preset', 'TabOrder', 'Visible', 'ParentFont', 'ParentColor', 'ParentBackground',
    'ParentShowHint', 'ParentBiDiMode', 'HelpContext', 'ImageName', 'DragKind', 'DragCursor',
    'DockSite', 'AutoSize', 'Tag', 'ParentDoubleBuffered',
    // Bildnamen werden nur mit einer ImageList mit Namen gespeichert
    'HotImageName', 'DisabledImageName', 'PressedImageName');

function TStreamingTests.RoundTrip(C: TComponent): TComponent;
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

procedure TStreamingTests.EveryPropertySurvivesDfm;
const
  Kinds: TTypeKinds = [tkInteger, tkEnumeration, tkFloat, tkUString, tkLString, tkWString];
var
  CI, P, N, K, Checked: Integer;
  Props: PPropList;
  PInfo: PPropInfo;
  C, C2: TComponent;
  Want, Got, PName: string;
  Skip: Boolean;
  TD: PTypeData;
  Errors: TStringList;
begin
  Errors := TStringList.Create;
  try
    Checked := 0;
    for CI := 0 to High(ControlClasses) do
    begin
      RegisterClass(TPersistentClass(ControlClasses[CI]));
      N := GetPropList(ControlClasses[CI].ClassInfo, Kinds, nil);
      GetMem(Props, N * SizeOf(PPropInfo));
      try
        GetPropList(ControlClasses[CI].ClassInfo, Kinds, Props);
        for P := 0 to N - 1 do
        begin
          PInfo := Props[P];
          PName := string(PInfo^.Name);
          Skip := PInfo^.SetProc = nil;
          for K := 0 to High(SkipProps) do
            if SameText(PName, SkipProps[K]) then
              Skip := True;
          if Skip then
            Continue;
          C := ControlClasses[CI].Create(FForm);
          try
            if C is TControl then
              TControl(C).Parent := FForm;
            try
              case PInfo^.PropType^.Kind of
                tkEnumeration:
                  begin
                    TD := GetTypeData(PInfo^.PropType^);
                    K := GetOrdProp(C, PInfo) + 1;
                    if K > TD^.MaxValue then
                      K := TD^.MinValue;
                    SetOrdProp(C, PInfo, K);
                  end;
                tkInteger:
                  if PInfo^.PropType^ = TypeInfo(TColor) then
                    SetOrdProp(C, PInfo, $123456)
                  else
                    SetOrdProp(C, PInfo, GetOrdProp(C, PInfo) + 3);
                tkFloat:
                  SetFloatProp(C, PInfo, GetFloatProp(C, PInfo) + 2.5);
              else
                SetStrProp(C, PInfo, GetStrProp(C, PInfo) + 'Xy');
              end;
            except
              Continue; // Wert ungueltig (Pruefung wirft) - nicht Gegenstand dieses Tests
            end;
            Want := GetPropValue(C, PName, True);
            Inc(Checked);
            try
              C2 := RoundTrip(C);
            except
              on E: Exception do
              begin
                Errors.Add(C.ClassName + '.' + PName + ': Laden wirft ' + E.Message);
                Continue;
              end;
            end;
            try
              Got := GetPropValue(C2, PName, True);
              if Got <> Want then
                Errors.Add(Format('%s.%s: gesetzt %s, geladen %s', [C.ClassName, PName, Want, Got]));
            finally
              C2.Free;
            end;
          finally
            C.Free;
          end;
        end;
      finally
        FreeMem(Props);
      end;
    end;
    CheckTrue(Checked > 500, Format('nur %d Properties geprueft', [Checked]));
    CheckEquals('', Errors.Text, Errors.Text);
  finally
    Errors.Free;
  end;
end;

procedure TStreamingTests.RatingHalfValueSurvivesDfm;
var
  R, R2: TPPGRating;
begin
  // Value steht im DFM vor AllowHalf: darf beim Laden nicht gerundet werden
  R := TPPGRating.Create(FForm);
  R.Parent := FForm;
  R.AllowHalf := True;
  R.Max := 10;
  R.Value := 7.5;
  R2 := RoundTrip(R) as TPPGRating;
  try
    CheckEquals(7.5, R2.Value, 0);
    CheckEquals(10, R2.Max);
  finally
    R2.Free;
  end;
end;

procedure TStreamingTests.StatusBarOwnFontSurvivesDfm;
var
  S, S2: TPPGStatusBar;
begin
  S := TPPGStatusBar.Create(FForm);
  S.Parent := FForm;
  CheckTrue(S.UseSystemFont);
  S.Font.Size := 16;
  CheckFalse(S.UseSystemFont, 'eigene Schrift schaltet die Systemschrift ab (wie TStatusBar)');
  S2 := RoundTrip(S) as TPPGStatusBar;
  try
    CheckEquals(16, S2.Font.Size);
    CheckFalse(S2.UseSystemFont);
  finally
    S2.Free;
  end;
  S.UseSystemFont := True;
  CheckEquals(Screen.MessageFont.Size, S.Font.Size, 'zurueck zur Systemschrift');
  CheckTrue(S.UseSystemFont);
  S2 := RoundTrip(S) as TPPGStatusBar;
  try
    CheckTrue(S2.UseSystemFont);
    CheckEquals(Screen.MessageFont.Size, S2.Font.Size);
  finally
    S2.Free;
  end;
end;

initialization
  RegisterTest('Streaming', TStreamingTests.Suite);

end.
