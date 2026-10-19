unit PPG.Tests.NavigatorExtras;

{ Tests fuer die Erweiterungen von TPPGDBNavigator: Freigabe je Knopf
  (OnButtonEnabled), Zusatzknoepfe (CustomButtons, OnCustomButtonClick) und
  Zaehler/Blaettern ueber eine Positionsquelle (PositionSource mit
  IPPGViewPosition). Die Quelle ist hier ein synthetischer Stellvertreter
  mit eigener Reihenfolge der Saetze (kein Grid). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils,
  System.Types, System.Generics.Collections, Vcl.Graphics, Vcl.Forms, Vcl.Controls,
  Vcl.ImgList, Vcl.DBCtrls, Data.DB, Datasnap.DBClient, MidasLib,
  PPG.Types, PPG.DB.Navigator, PPG.Tests.Controls;

type
  /// Positionsquelle zum Testen: Saetze in der Reihenfolge Order (IDs).
  TViewStub = class(TComponent, IPPGViewPosition)
  private
    FData: TDataSet;
    FObservers: TList<TComponent>;
    FMoves: string;
    function CurrentIndex: Integer;
  public
    Order: TArray<Integer>;
    constructor Create(AOwner: TComponent; AData: TDataSet); reintroduce;
    destructor Destroy; override;
    function ViewRecordNo: Integer;
    function ViewRecordCount: Integer;
    function ViewCanMove(Move: TPPGViewMove): Boolean;
    function ViewMove(Move: TPPGViewMove): Boolean;
    procedure ViewPositionObserver(AObserver: TComponent; Attach: Boolean);
    /// CM_PPGVIEWPOSITION an alle Beobachter.
    procedure NotifyObservers;
    property Observers: TList<TComponent> read FObservers;
    property Moves: string read FMoves;
  end;

  /// Navigator, der DataChanged zaehlt (Beobachter-Nachricht).
  TNavProbe = class(TPPGDBNavigator)
  public
    Changes: Integer;
  protected
    procedure DataChanged; override;
  end;

  TNavigatorExtrasTests = class(TControlTestCase)
  private
    FData: TClientDataSet;
    FSource: TDataSource;
    FNav: TNavProbe;
    FLog: string;
    FDeny: TNavButtonSet;
    FSeen: string;
    procedure NavBefore(Sender: TObject; Button: TNavigateBtn);
    procedure NavClick(Sender: TObject; Button: TNavigateBtn);
    procedure NavEnabled(Sender: TObject; Button: TNavigateBtn; var Enabled: Boolean);
    procedure ItemClick(Sender: TObject);
    procedure NavCustomClick(Sender: TObject; Button: TPPGNavButton);
    procedure ClickAt(const R: TRect);
    function CurID: Integer;
  protected
    procedure SetUp; override;
  published
    procedure DefaultsUnchanged;
    procedure ButtonEnabledEventLocksButtons;
    procedure CustomButtonsLayoutAndClick;
    procedure CustomButtonsKeyboardAccessAndOverflow;
    procedure CustomButtonsImagesAndPaint;
    procedure PositionSourceCounterAndMoves;
    procedure PositionSourceObserverAndRelease;
    procedure PositionSourceInvalidValues;
    procedure StreamsCustomButtons;
  end;

implementation

uses
  Winapi.oleacc, PPG.Lang, PPG.Consts, PPG.Exceptions, PPG.Accessibility;

type
  TNavAccess = class(TPPGCustomDBNavigator);

{ TViewStub }

constructor TViewStub.Create(AOwner: TComponent; AData: TDataSet);
begin
  inherited Create(AOwner);
  FData := AData;
  FObservers := TList<TComponent>.Create;
end;

destructor TViewStub.Destroy;
begin
  FreeAndNil(FObservers);
  inherited Destroy;
end;

function TViewStub.CurrentIndex: Integer;
var
  I, ID: Integer;
begin
  Result := -1;
  if (FData = nil) or not FData.Active or FData.IsEmpty then
    Exit;
  ID := FData.FieldByName('ID').AsInteger;
  for I := 0 to High(Order) do
    if Order[I] = ID then
      Exit(I);
end;

function TViewStub.ViewRecordNo: Integer;
begin
  Result := CurrentIndex + 1;
end;

function TViewStub.ViewRecordCount: Integer;
begin
  Result := Length(Order);
end;

function TViewStub.ViewCanMove(Move: TPPGViewMove): Boolean;
var
  I: Integer;
begin
  I := CurrentIndex;
  if Length(Order) = 0 then
    Exit(False);
  case Move of
    pvmFirst, pvmPrior: Result := I <> 0;
  else
    Result := I <> High(Order);
  end;
end;

function TViewStub.ViewMove(Move: TPPGViewMove): Boolean;
var
  I: Integer;
begin
  Result := ViewCanMove(Move);
  if not Result then
    Exit;
  I := CurrentIndex;
  case Move of
    pvmFirst: I := 0;
    pvmPrior: Dec(I);
    pvmNext: Inc(I);
    pvmLast: I := High(Order);
  end;
  FMoves := FMoves + IntToStr(Ord(Move));
  FData.Locate('ID', Order[I], []);
  NotifyObservers;
end;

procedure TViewStub.ViewPositionObserver(AObserver: TComponent; Attach: Boolean);
begin
  if Attach then
  begin
    if FObservers.IndexOf(AObserver) < 0 then
      FObservers.Add(AObserver);
  end
  else
    FObservers.Remove(AObserver);
end;

procedure TViewStub.NotifyObservers;
var
  I: Integer;
begin
  for I := 0 to FObservers.Count - 1 do
    if FObservers[I] is TControl then
      TControl(FObservers[I]).Perform(CM_PPGVIEWPOSITION, 0, 0);
end;

{ TNavProbe }

procedure TNavProbe.DataChanged;
begin
  Inc(Changes);
  inherited DataChanged;
end;

{ TNavigatorExtrasTests }

procedure TNavigatorExtrasTests.SetUp;
var
  I: Integer;
begin
  inherited SetUp;
  FLog := '';
  FSeen := '';
  FDeny := [];
  FData := TClientDataSet.Create(FForm);
  FData.FieldDefs.Add('ID', ftInteger);
  FData.FieldDefs.Add('Name', ftString, 20);
  FData.CreateDataSet;
  for I := 1 to 5 do
    FData.AppendRecord([I, 'Satz' + IntToStr(I)]);
  FData.First;
  FSource := TDataSource.Create(FForm);
  FSource.DataSet := FData;
  FNav := TNavProbe.Create(FForm);
  FNav.Parent := FForm;
  FNav.SetBounds(0, 0, 900, 36);
  FNav.DataSource := FSource;
  FNav.ConfirmDelete := False;
  FNav.BeforeAction := NavBefore;
  FNav.OnClick := NavClick;
end;

procedure TNavigatorExtrasTests.NavBefore(Sender: TObject; Button: TNavigateBtn);
begin
  FLog := FLog + 'B' + IntToStr(Ord(Button));
end;

procedure TNavigatorExtrasTests.NavClick(Sender: TObject; Button: TNavigateBtn);
begin
  FLog := FLog + 'C' + IntToStr(Ord(Button));
end;

procedure TNavigatorExtrasTests.NavEnabled(Sender: TObject; Button: TNavigateBtn;
  var Enabled: Boolean);
begin
  if Button = nbNext then
    FSeen := FSeen + System.SysUtils.BoolToStr(Enabled, True) + ';';
  if Button in FDeny then
    Enabled := False;
end;

procedure TNavigatorExtrasTests.ItemClick(Sender: TObject);
begin
  FLog := FLog + 'I' + IntToStr((Sender as TPPGNavButton).Index);
end;

procedure TNavigatorExtrasTests.NavCustomClick(Sender: TObject; Button: TPPGNavButton);
begin
  FLog := FLog + 'N' + IntToStr(Button.Index);
end;

procedure TNavigatorExtrasTests.ClickAt(const R: TRect);
var
  P: LPARAM;
begin
  CheckFalse(IsRectEmpty(R), 'Knopf sichtbar');
  P := MakeLParam((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2);
  FNav.Perform(WM_MOUSEMOVE, 0, P);
  FNav.Perform(WM_LBUTTONDOWN, MK_LBUTTON, P);
  FNav.Perform(WM_LBUTTONUP, 0, P);
end;

function TNavigatorExtrasTests.CurID: Integer;
begin
  Result := FData.FieldByName('ID').AsInteger;
end;

procedure TNavigatorExtrasTests.DefaultsUnchanged;
var
  A: IPPGAccessibleChildren;
begin
  CheckEquals(0, FNav.CustomButtons.Count, 'keine Zusatzknoepfe');
  CheckNull(FNav.PositionSource, 'keine Quelle');
  CheckFalse(Assigned(FNav.OnButtonEnabled));
  CheckEquals(0, FNav.ButtonRect(nbFirst).Left);
  CheckEquals(36, FNav.ButtonRect(nbFirst).Right, 'Knopfbreite wie bisher');
  CheckTrue(Supports(FNav, IPPGAccessibleChildren, A));
  CheckEquals(10, A.AccChildCount, 'nur Standardknoepfe');
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [1, 5]), FNav.CounterText, 'Zaehler der Datenmenge');
  FNav.BtnClick(nbLast);
  CheckEquals(5, FData.RecNo, 'Blaettern ueber die Datenmenge');
  CheckTrue(IsRectEmpty(FNav.CustomButtonRect(0)), 'kein Zusatzknopf');
end;

procedure TNavigatorExtrasTests.ButtonEnabledEventLocksButtons;
var
  A: IPPGAccessibleChildren;
  I, Id: Integer;
begin
  FNav.OnButtonEnabled := NavEnabled;
  CheckTrue(FNav.ButtonEnabled(nbNext), 'Ereignis ohne Einwand');
  CheckEquals('True;', FSeen, 'Standardregel wird uebergeben');
  FData.Last;
  FSeen := '';
  CheckFalse(FNav.ButtonEnabled(nbNext));
  CheckEquals('False;', FSeen, 'am Ende: Standard False');
  FData.First;
  FDeny := [nbNext, nbInsert];
  FNav.UpdateButtons;
  CheckFalse(FNav.ButtonEnabled(nbNext), 'gesperrt');
  CheckFalse(FNav.ButtonEnabled(nbInsert), 'gesperrt');
  CheckTrue(FNav.ButtonEnabled(nbLast), 'andere unveraendert');
  FLog := '';
  FNav.BtnClick(nbNext);
  CheckEquals(1, FData.RecNo, 'Klick per Code gesperrt');
  ClickAt(FNav.ButtonRect(nbNext));
  CheckEquals(1, FData.RecNo, 'Mausklick gesperrt');
  CheckEquals('', FLog, 'kein BeforeAction/OnClick');
  FNav.Perform(WM_KEYDOWN, VK_NEXT, 0);
  CheckEquals(1, FData.RecNo, 'Taste Bild ab gesperrt');
  FNav.Perform(WM_KEYDOWN, VK_INSERT, 0);
  CheckTrue(FData.State = dsBrowse, 'Einfg gesperrt');
  // Screenreader: Knopf "Naechster" (3. sichtbarer) ist nicht verfuegbar
  CheckTrue(Supports(FNav, IPPGAccessibleChildren, A));
  Id := 0;
  for I := 1 to A.AccChildCount do
    if A.AccChildName(I) = PPGStr(@SPPGNavNext) then
      Id := I;
  CheckTrue(Id > 0);
  CheckEquals(STATE_SYSTEM_UNAVAILABLE, A.AccChildState(Id), 'Screenreader: gesperrt');
  FDeny := [];
  FNav.UpdateButtons;
  FNav.BtnClick(nbNext);
  CheckEquals(2, FData.RecNo, 'wieder frei');
  // Navigator gesperrt bzw. ohne Datenmenge: Ereignis kann nichts freigeben
  FNav.DataSource := nil;
  FSeen := '';
  CheckFalse(FNav.ButtonEnabled(nbNext));
  CheckEquals('', FSeen, 'ohne Datenmenge wird nicht gefragt');
end;

procedure TNavigatorExtrasTests.CustomButtonsLayoutAndClick;
var
  B0, B1, B2: TPPGNavButton;
  R0, R1, R2: TRect;
begin
  FNav.OnCustomButtonClick := NavCustomClick;
  B0 := FNav.CustomButtons.Add;
  B0.IconChar := $E8C8;
  B0.Hint := 'Kopieren';
  B0.OnClick := ItemClick;
  B1 := FNav.CustomButtons.Add;
  B1.Caption := 'Pruefprotokoll drucken';
  B1.OnClick := ItemClick;
  B2 := FNav.CustomButtons.Add;
  B2.Caption := 'X';
  R0 := FNav.CustomButtonRect(0);
  R1 := FNav.CustomButtonRect(1);
  R2 := FNav.CustomButtonRect(2);
  CheckEquals(FNav.ButtonRect(nbRefresh).Right, R0.Left, 'hinter den Standardknoepfen');
  CheckEquals(36, R0.Right - R0.Left, 'Symbol: Knopfbreite');
  CheckEquals(R0.Right, R1.Left);
  CheckTrue(R1.Right - R1.Left > 36, 'Text: breiter als ein Symbolknopf');
  CheckEquals(36, R2.Right - R2.Left, 'kurzer Text: mindestens Knopfbreite');
  CheckTrue(B0.HasIcon and not B1.HasIcon);
  FLog := '';
  ClickAt(R0);
  CheckEquals('I0N0', FLog, 'erst OnClick des Knopfs, dann des Navigators');
  FLog := '';
  ClickAt(R2);
  CheckEquals('N2', FLog, 'ohne eigenes OnClick nur das Navigator-Ereignis');
  // Gesperrt: kein Ereignis
  B1.Enabled := False;
  FLog := '';
  ClickAt(FNav.CustomButtonRect(1));
  FNav.CustomButtonClick(B1);
  CheckEquals('', FLog, 'deaktivierter Zusatzknopf');
  FNav.Enabled := False;
  FNav.CustomButtonClick(B0);
  CheckEquals('', FLog, 'deaktivierter Navigator');
  FNav.Enabled := True;
  // Unsichtbar: kein Platz, Nachfolger rueckt auf
  B0.Visible := False;
  CheckTrue(IsRectEmpty(FNav.CustomButtonRect(0)), 'unsichtbar');
  CheckEquals(FNav.ButtonRect(nbRefresh).Right, FNav.CustomButtonRect(1).Left, 'rueckt auf');
  FNav.CustomButtonClick(B0);
  CheckEquals('', FLog, 'unsichtbar: kein Klick');
  // Loeschen: Layout folgt
  B0.Visible := True;
  FNav.CustomButtons.Delete(0);
  CheckEquals(2, FNav.CustomButtons.Count);
  CheckEquals(FNav.ButtonRect(nbRefresh).Right, FNav.CustomButtonRect(0).Left, 'nach Loeschen');
  CheckTrue(IsRectEmpty(FNav.CustomButtonRect(2)), 'geloeschter Index');
  CheckTrue(B1.Navigator = FNav);
  // Zusatzknoepfe haengen nicht an der Datenmenge
  FNav.DataSource := nil;
  B1.Enabled := True;
  FLog := '';
  FNav.CustomButtonClick(B1);
  CheckEquals('I0N0', FLog, 'ohne Datenmenge bedienbar');
end;

procedure TNavigatorExtrasTests.CustomButtonsKeyboardAccessAndOverflow;
var
  A: IPPGAccessibleChildren;
  B0, B1: TPPGNavButton;
  I: Integer;
begin
  FNav.OnCustomButtonClick := NavCustomClick;
  FNav.VisibleButtons := [nbPrior, nbNext];
  B0 := FNav.CustomButtons.Add;
  B0.IconChar := $E8C8;
  B0.Hint := 'Kopieren';
  B1 := FNav.CustomButtons.Add;
  B1.Caption := '&Drucken';
  CheckTrue(Supports(FNav, IPPGAccessibleChildren, A));
  CheckEquals(4, A.AccChildCount, '2 Standard + 2 Zusatz');
  CheckEquals('Kopieren', A.AccChildName(3), 'Name aus Hint (nur Symbol)');
  CheckEquals('Drucken', A.AccChildName(4), 'Name aus Caption ohne &');
  CheckEquals(ROLE_SYSTEM_PUSHBUTTON, A.AccChildRole(4));
  CheckEquals(STATE_SYSTEM_FOCUSABLE, A.AccChildState(4) and STATE_SYSTEM_FOCUSABLE);
  B1.Enabled := False;
  CheckEquals(STATE_SYSTEM_UNAVAILABLE, A.AccChildState(4), 'gesperrt');
  B1.Enabled := True;
  CheckEquals(4, TNavAccess(FNav).AccChildAt((FNav.CustomButtonRect(1).Left +
    FNav.CustomButtonRect(1).Right) div 2, 10), 'Treffer');
  // Tastatur: Pfeil rechts bis zum Zusatzknopf, Leertaste loest aus
  FLog := '';
  for I := 1 to 3 do
    FNav.Perform(WM_KEYDOWN, VK_RIGHT, 0);
  FNav.Perform(WM_KEYDOWN, VK_SPACE, 0);
  CheckEquals('N1', FLog, 'Leertaste auf dem Zusatzknopf');
  FNav.Perform(WM_KEYDOWN, VK_LEFT, 0);
  FNav.Perform(WM_KEYDOWN, VK_RETURN, 0);
  CheckEquals('N1N0', FLog, 'Enter auf dem vorigen Zusatzknopf');
  // Schmal: Zusatzknoepfe landen im Ueberlauf (Standardknoepfe zuerst sichtbar)
  FNav.Width := 110;
  CheckFalse(IsRectEmpty(FNav.ButtonRect(nbPrior)), 'vorn sichtbar');
  CheckTrue(IsRectEmpty(FNav.CustomButtonRect(1)), 'hinterer Zusatzknopf im Ueberlauf');
  CheckTrue(A.AccChildCount < 4, 'weniger sichtbare Knoepfe');
  FNav.Width := 900;
  CheckFalse(IsRectEmpty(FNav.CustomButtonRect(1)), 'breit: wieder sichtbar');
end;

procedure TNavigatorExtrasTests.CustomButtonsImagesAndPaint;
var
  IL: TImageList;
  Bmp, Pic: TBitmap;
  B0, B1: TPPGNavButton;
begin
  IL := TImageList.Create(FForm);
  IL.Width := 16;
  IL.Height := 16;
  Pic := TBitmap.Create;
  try
    Pic.SetSize(16, 16);
    Pic.Canvas.Brush.Color := clRed;
    Pic.Canvas.FillRect(Rect(0, 0, 16, 16));
    IL.Add(Pic, nil);
  finally
    Pic.Free;
  end;
  B0 := FNav.CustomButtons.Add;
  B0.Caption := 'Ein langer Text mit Bild';
  B0.ImageIndex := 0;
  B1 := FNav.CustomButtons.Add;
  B1.Caption := 'Ein langer Text';
  CheckFalse(B0.HasIcon, 'ohne Images kein Bild');
  FNav.Images := IL;
  CheckTrue(B0.HasIcon, 'mit Images: Bild');
  CheckEquals(36, FNav.CustomButtonRect(0).Right - FNav.CustomButtonRect(0).Left,
    'Bild: Knopfbreite');
  B0.ImageIndex := 5;
  CheckFalse(B0.HasIcon, 'Index ausserhalb der Liste: Text');
  B0.ImageIndex := 0;
  B1.Enabled := False;
  FNav.Flat := True;
  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(FNav.Width, FNav.Height);
    FNav.PaintTo(Bmp.Canvas, 0, 0);
    FNav.Flat := False;
    FNav.PaintTo(Bmp.Canvas, 0, 0);
  finally
    Bmp.Free;
  end;
  // Liste freigeben: Navigator haelt keinen Verweis mehr
  IL.Free;
  CheckNull(FNav.Images);
  CheckFalse(B0.HasIcon);
end;

procedure TNavigatorExtrasTests.PositionSourceCounterAndMoves;
var
  Src: TViewStub;
begin
  Src := TViewStub.Create(FForm, FData);
  Src.Order := TArray<Integer>.Create(3, 1, 5, 2, 4);
  FData.Locate('ID', 3, []);
  FNav.PositionSource := Src;
  CheckTrue(FNav.PositionSource = Src);
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [1, 5]), FNav.CounterText, 'erster der Ansicht');
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [1, 5]), TNavAccess(FNav).AccValue, 'Screenreader');
  CheckFalse(FNav.ButtonEnabled(nbFirst), 'am Anfang der Ansicht');
  CheckFalse(FNav.ButtonEnabled(nbPrior));
  CheckTrue(FNav.ButtonEnabled(nbNext));
  FLog := '';
  FNav.BtnClick(nbNext);
  CheckEquals(1, CurID, 'naechster in der Ansicht');
  CheckEquals('B' + IntToStr(Ord(nbNext)) + 'C' + IntToStr(Ord(nbNext)), FLog,
    'BeforeAction und OnClick wie bisher');
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [2, 5]), FNav.CounterText);
  ClickAt(FNav.ButtonRect(nbLast));
  CheckEquals(4, CurID, 'letzter der Ansicht (nicht der Datenmenge)');
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [5, 5]), FNav.CounterText);
  CheckFalse(FNav.ButtonEnabled(nbNext), 'Ende der Ansicht');
  CheckTrue(FNav.ButtonEnabled(nbPrior));
  FNav.Perform(WM_KEYDOWN, VK_PRIOR, 0);
  CheckEquals(2, CurID, 'Bild auf = voriger der Ansicht');
  FNav.BtnClick(nbFirst);
  CheckEquals(3, CurID);
  CheckEquals(IntToStr(Ord(pvmNext)) + IntToStr(Ord(pvmLast)) + IntToStr(Ord(pvmPrior)) +
    IntToStr(Ord(pvmFirst)), Src.Moves, 'alles ueber die Quelle');
  // Andere Knoepfe weiter ueber die Datenmenge; Bearbeitung sperrt das Blaettern
  FData.Edit;
  CheckFalse(FNav.ButtonEnabled(nbNext), 'bei Bearbeitung kein Blaettern');
  FData.Cancel;
  FData.Insert;
  CheckEquals(PPGStr(@SPPGNavNewRecord), FNav.CounterText, 'neuer Satz');
  FData.Cancel;
  // Satz nicht in der Ansicht: nur die Anzahl
  Src.Order := TArray<Integer>.Create(1, 2);
  FData.Locate('ID', 5, []);
  CheckEquals(Format(PPGStr(@SPPGNavCount), [2]), FNav.CounterText, 'nicht in der Ansicht');
  Src.Order := nil;
  CheckEquals(PPGStr(@SPPGNavNoRecords), FNav.CounterText, 'leere Ansicht');
  CheckFalse(FNav.ButtonEnabled(nbFirst));
  CheckFalse(FNav.ButtonEnabled(nbLast));
  // OnButtonEnabled laeuft auch mit Quelle
  Src.Order := TArray<Integer>.Create(3, 1, 5, 2, 4);
  FData.Locate('ID', 3, []);
  FNav.OnButtonEnabled := NavEnabled;
  FDeny := [nbNext];
  CheckFalse(FNav.ButtonEnabled(nbNext), 'Ereignis nach der Regel der Quelle');
  CheckEquals('True;', FSeen);
  // Ohne Quelle wieder die Datenmenge
  FNav.OnButtonEnabled := nil;
  FNav.PositionSource := nil;
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [3, 5]), FNav.CounterText, 'RecNo der Datenmenge');
  FNav.BtnClick(nbNext);
  CheckEquals(4, CurID, 'Datenmenge');
end;

procedure TNavigatorExtrasTests.PositionSourceObserverAndRelease;
var
  S1, S2: TViewStub;
  N: Integer;
begin
  S1 := TViewStub.Create(FForm, FData);
  S1.Order := TArray<Integer>.Create(1, 2, 3, 4, 5);
  S2 := TViewStub.Create(FForm, FData);
  S2.Order := TArray<Integer>.Create(5, 4);
  FNav.PositionSource := S1;
  CheckEquals(1, S1.Observers.Count, 'angemeldet');
  CheckTrue(S1.Observers[0] = FNav);
  FNav.PositionSource := S1;
  CheckEquals(1, S1.Observers.Count, 'nicht doppelt');
  N := FNav.Changes;
  S1.NotifyObservers;
  CheckEquals(N + 1, FNav.Changes, 'CM_PPGVIEWPOSITION -> neu zeichnen');
  // Wechsel der Quelle meldet bei der alten ab
  FNav.PositionSource := S2;
  CheckEquals(0, S1.Observers.Count, 'alte Quelle abgemeldet');
  CheckEquals(1, S2.Observers.Count, 'neue Quelle angemeldet');
  CheckEquals(Format(PPGStr(@SPPGNavCount), [2]), FNav.CounterText, 'Satz 1 nicht in S2');
  // Quelle freigeben: Navigator vergisst sie
  S2.Free;
  CheckNull(FNav.PositionSource, 'freigegebene Quelle -> nil');
  CheckEquals(Format(PPGStr(@SPPGNavCounter), [1, 5]), FNav.CounterText, 'wieder Datenmenge');
  // Navigator freigeben: meldet sich ab
  FNav.PositionSource := S1;
  CheckEquals(1, S1.Observers.Count);
  FreeAndNil(FNav);
  CheckEquals(0, S1.Observers.Count, 'Navigator meldet sich im Destruktor ab');
end;

procedure TNavigatorExtrasTests.PositionSourceInvalidValues;
var
  C: TComponent;
  Raised: Boolean;
begin
  C := TComponent.Create(FForm);
  Raised := False;
  try
    FNav.PositionSource := C;
  except
    on E: EPPGError do
      Raised := True;
  end;
  CheckTrue(Raised, 'Komponente ohne IPPGViewPosition');
  CheckNull(FNav.PositionSource, 'bleibt leer');
  Raised := False;
  try
    FNav.PositionSource := FNav;
  except
    on E: EPPGError do
      Raised := True;
  end;
  CheckTrue(Raised, 'Navigator selbst');
  CheckNull(FNav.PositionSource);
end;

procedure TNavigatorExtrasTests.StreamsCustomButtons;
var
  M, T: TMemoryStream;
  N2: TPPGDBNavigator;
  B: TPPGNavButton;
  Txt: string;
  SS: TStringStream;
begin
  // Ohne neue Properties: nichts davon in der DFM
  M := TMemoryStream.Create;
  T := TMemoryStream.Create;
  SS := TStringStream.Create('');
  try
    M.WriteComponent(FNav);
    M.Position := 0;
    ObjectBinaryToText(M, SS);
    Txt := SS.DataString;
    CheckEquals(0, Pos('CustomButtons', Txt), 'leere Sammlung nicht gespeichert');
    CheckEquals(0, Pos('PositionSource', Txt));
    // Zusatzknopf mit Vorgaben: nur das Item, keine Vorgabewerte
    FNav.CustomButtons.Add;
    M.Clear;
    SS.Size := 0;
    M.WriteComponent(FNav);
    M.Position := 0;
    ObjectBinaryToText(M, SS);
    Txt := SS.DataString;
    CheckTrue(Pos('CustomButtons', Txt) > 0, 'Sammlung gespeichert');
    CheckEquals(0, Pos('ImageIndex', Txt), 'Vorgabe nicht gespeichert');
    CheckEquals(0, Pos('Enabled', Txt));
    CheckEquals(0, Pos('IconChar', Txt));
    CheckEquals(0, Pos('Visible', Txt));
    B := FNav.CustomButtons[0];
    B.Caption := 'Kopieren';
    B.Hint := 'Satz kopieren';
    B.IconChar := $E8C8;
    B.ImageIndex := 2;
    B.Enabled := False;
    B.Visible := False;
    B.Tag := 7;
    FNav.CustomButtons.Add.Caption := 'Zweiter';
    M.Clear;
    M.WriteComponent(FNav);
    M.Position := 0;
    N2 := TPPGDBNavigator.Create(FForm);
    M.ReadComponent(N2);
    CheckEquals(2, N2.CustomButtons.Count);
    B := N2.CustomButtons[0];
    CheckEquals('Kopieren', B.Caption);
    CheckEquals('Satz kopieren', B.Hint);
    CheckEquals($E8C8, B.IconChar);
    CheckEquals(2, B.ImageIndex);
    CheckFalse(B.Enabled);
    CheckFalse(B.Visible);
    CheckEquals(7, B.Tag);
    CheckEquals('Zweiter', N2.CustomButtons[1].Caption);
    CheckTrue(N2.CustomButtons[1].Enabled and N2.CustomButtons[1].Visible);
    // Assign kopiert die Knoepfe
    N2.CustomButtons.Clear;
    N2.CustomButtons := FNav.CustomButtons;
    CheckEquals(2, N2.CustomButtons.Count);
    CheckEquals(7, N2.CustomButtons[0].Tag);
    CheckEquals('Kopieren', N2.CustomButtons[0].DisplayName);
  finally
    SS.Free;
    T.Free;
    M.Free;
  end;
end;

initialization
  RegisterTest('NavigatorExtras', TNavigatorExtrasTests.Suite);

end.
