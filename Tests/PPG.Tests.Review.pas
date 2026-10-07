unit PPG.Tests.Review;

{ Regressionstests zu den Funden der Ultra Review vom 07.10.2026
  (PRs 3 und 4: Core/Theme und Render). }

interface

uses
  TestFramework, Winapi.Windows, Winapi.Messages, System.Classes, System.SysUtils, System.Types,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  PPG.ErrorHandler, PPG.Theme, PPG.StyleManager, PPG.Markup,
  PPG.Render.Intf, PPG.Render.Gdi;

type
  TReviewTests = class(TTestCase)
  private
    FLog: TStringList;
    FAppExceptions: Integer;
    procedure RecordAppException(Sender: TObject; E: Exception);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ErrorLogNamesSenderAndMessageOnce;
    procedure ThemeChangeReachesClientsAfterFailingOne;
    procedure StyleManagerChangeReachesClientsAfterFailingOne;
    procedure MarkupLinkWithoutFragmentIsNotCounted;
    procedure MarkupLinkIndexesStayInReadingOrder;
    procedure GdiDashedLineBlendsOnceWithGaps;
  end;

implementation

type
  TListLogger = class(TInterfacedObject, IPPGLogger)
  private
    FList: TStrings;
  public
    constructor Create(AList: TStrings);
    procedure Log(Level: TPPGLogLevel; const Msg: string);
  end;

  // Meldet sich beim Theme an und zaehlt bzw. wirft beim Wechsel
  TThemeProbe = class(TControl)
  public
    Fail: Boolean;
    Calls: Integer;
    procedure WndProc(var Message: TMessage); override;
  end;

  TStyleProbe = class(TComponent, IPPGStyleClient)
  public
    Fail: Boolean;
    Calls: Integer;
    procedure StyleManagerChanged(Sender: TObject);
  end;

  TStyleManagerAccess = class(TPPGStyleManager);

constructor TListLogger.Create(AList: TStrings);
begin
  inherited Create;
  FList := AList;
end;

procedure TListLogger.Log(Level: TPPGLogLevel; const Msg: string);
begin
  FList.Add(Msg);
end;

procedure TThemeProbe.WndProc(var Message: TMessage);
begin
  if (PPGThemeChangedMessage <> 0) and (Message.Msg = PPGThemeChangedMessage) then
  begin
    Inc(Calls);
    if Fail then
      raise Exception.Create('Probe failed');
  end;
  inherited WndProc(Message);
end;

procedure TStyleProbe.StyleManagerChanged(Sender: TObject);
begin
  Inc(Calls);
  if Fail then
    raise Exception.Create('Probe failed');
end;

function CountOf(const Sub, S: string): Integer;
var
  P, Start: Integer;
begin
  Result := 0;
  Start := 1;
  repeat
    P := Pos(Sub, Copy(S, Start, MaxInt));
    if P > 0 then
    begin
      Inc(Result);
      Start := Start + P - 1 + Length(Sub);
    end;
  until P = 0;
end;

{ TReviewTests }

procedure TReviewTests.SetUp;
begin
  inherited;
  FLog := TStringList.Create;
  FAppExceptions := 0;
  Application.OnException := RecordAppException;
end;

procedure TReviewTests.TearDown;
begin
  TPPGErrorHandler.Logger := nil;
  Application.OnException := nil;
  FreeAndNil(FLog);
  inherited;
end;

procedure TReviewTests.RecordAppException(Sender: TObject; E: Exception);
begin
  Inc(FAppExceptions);
end;

procedure TReviewTests.ErrorLogNamesSenderAndMessageOnce;
var
  C: TComponent;
  E: Exception;
begin
  // Vorher: "Probe1: Painting of Probe1 failed: Boom (Exception: Boom)"
  TPPGErrorHandler.Logger := TListLogger.Create(FLog);
  C := TComponent.Create(nil);
  E := Exception.Create('Boom');
  try
    C.Name := 'Probe1';
    TPPGErrorHandler.ReportPaintError(C, E);
    TPPGErrorHandler.HandleCallbackError(C, E, 'Probe.Tick');
    CheckEquals(2, FLog.Count);
    CheckEquals(1, CountOf('Probe1', FLog[0]), 'Paint: Sender einmal - ' + FLog[0]);
    CheckEquals(1, CountOf('Boom', FLog[0]), 'Paint: Meldung einmal - ' + FLog[0]);
    CheckEquals(1, CountOf('Probe1', FLog[1]), 'Callback: Sender einmal - ' + FLog[1]);
    CheckEquals(1, CountOf('Boom', FLog[1]), 'Callback: Meldung einmal - ' + FLog[1]);
    CheckEquals(1, CountOf('Probe.Tick', FLog[1]), 'Callback: Kontext - ' + FLog[1]);
  finally
    E.Free;
    C.Free;
  end;
end;

procedure TReviewTests.ThemeChangeReachesClientsAfterFailingOne;
var
  Bad, Good: TThemeProbe;
  OldMode: TPPGThemeMode;
begin
  OldMode := TPPGTheme.Mode;
  Bad := TThemeProbe.Create(nil);
  Good := TThemeProbe.Create(nil);
  try
    Bad.Fail := True;
    TPPGTheme.AddClient(Bad);  // zuerst angemeldet, also zuerst benachrichtigt
    TPPGTheme.AddClient(Good);
    try
      if OldMode = tmDark then
        TPPGTheme.Mode := tmLight
      else
        TPPGTheme.Mode := tmDark;
      CheckEquals(1, Bad.Calls, 'fehlerhafter Client aufgerufen');
      CheckEquals(1, Good.Calls, 'folgender Client trotzdem benachrichtigt');
      CheckEquals(1, FAppExceptions, 'Fehler wie die VCL gemeldet');
    finally
      TPPGTheme.RemoveClient(Bad);
      TPPGTheme.RemoveClient(Good);
      TPPGTheme.Mode := OldMode;
    end;
  finally
    Good.Free;
    Bad.Free;
  end;
end;

procedure TReviewTests.StyleManagerChangeReachesClientsAfterFailingOne;
var
  M: TPPGStyleManager;
  Bad, Good: TStyleProbe;
begin
  M := TPPGStyleManager.Create(nil);
  Bad := TStyleProbe.Create(nil);
  Good := TStyleProbe.Create(nil);
  try
    Bad.Fail := True;
    M.AddClient(Bad);
    M.AddClient(Good);
    TStyleManagerAccess(M).Changed;
    CheckEquals(1, Bad.Calls, 'fehlerhafter Client aufgerufen');
    CheckEquals(1, Good.Calls, 'folgender Client trotzdem benachrichtigt');
    CheckEquals(1, FAppExceptions, 'Fehler wie die VCL gemeldet');
    M.RemoveClient(Bad);
    M.RemoveClient(Good);
  finally
    Good.Free;
    Bad.Free;
    M.Free;
  end;
end;

procedure TReviewTests.MarkupLinkWithoutFragmentIsNotCounted;
var
  L: TPPGMarkupLayout;
  F: TFont;
  R: TRect;
begin
  F := TFont.Create;
  L := TPPGMarkupLayout.Create;
  try
    // Bild ohne ImageList und reiner Umbruch erzeugen kein Fragment
    L.Layout('<a href="bild"><img=0></a>x<a href="umbruch"><br></a>y', F, nil, 0, False);
    CheckEquals(0, L.LinkCount, 'Links ohne Flaeche zaehlen nicht');
    CheckFalse(L.HasLinks);
    CheckEquals(-1, L.RunLinkIndex(0));
    R := L.LinkBounds(0);
    CheckTrue(IsRectEmpty(R), 'kein Link 0');
  finally
    L.Free;
    F.Free;
  end;
end;

procedure TReviewTests.MarkupLinkIndexesStayInReadingOrder;
var
  L: TPPGMarkupLayout;
  F: TFont;
  R: TRect;
  I: Integer;
begin
  F := TFont.Create;
  L := TPPGMarkupLayout.Create;
  try
    L.Layout('<a href="a">eins</a> <a href="bild"><img=0></a> <b><a href="c">zw</a></b>' +
      '<a href="c">ei</a> <a href="d">drei</a>', F, nil, 0, False);
    CheckEquals(3, L.LinkCount);
    CheckEquals('a', L.LinkTarget(0));
    CheckEquals('c', L.LinkTarget(1), 'unsichtbarer Link uebersprungen');
    CheckEquals('d', L.LinkTarget(2));
    CheckEquals('zwei', L.LinkText(1), 'zusammenhaengende Abschnitte = ein Link');
    for I := 0 to L.LinkCount - 1 do
    begin
      R := L.LinkBounds(I);
      CheckFalse(IsRectEmpty(R), Format('Link %d hat Flaeche', [I]));
      CheckEquals(I, L.LinkIndexAt((R.Left + R.Right) div 2, (R.Top + R.Bottom) div 2),
        Format('Link %d per Maus erreichbar', [I]));
    end;
  finally
    L.Free;
    F.Free;
  end;
end;

procedure TReviewTests.GdiDashedLineBlendsOnceWithGaps;
var
  Bmp: TBitmap;
  Cv: IPPGShapeCanvas;
  C: Cardinal;
  X, Dash, Gap: Integer;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf24bit;
    Bmp.SetSize(120, 20);
    Bmp.Canvas.Brush.Color := clWhite;
    Bmp.Canvas.FillRect(Rect(0, 0, 120, 20));
    Cv := TPPGGdiCanvas.Create(Bmp.Canvas.Handle);
    // Strich laeuft ueber die Ecke bei (56,10): beide Teilstuecke haben runde
    // Enden und ueberlappen dort. Vorher (eine Ebene je Strich) doppelt geblendet.
    Cv.DrawDashedPolyline([Point(10, 10), Point(56, 10), Point(56, 19)], 3, 8, 6, clBlack, 128);
    Cv := nil;
    Dash := 0;
    Gap := 0;
    for X := 10 to 54 do
    begin
      C := ColorToRGB(Bmp.Canvas.Pixels[X, 10]);
      if GetRValue(C) > 240 then
        Inc(Gap)
      else
      begin
        Inc(Dash);
        // Halbtransparent: grau, weder weiss noch schwarz
        CheckTrue((GetRValue(C) > 90) and (GetRValue(C) < 170),
          Format('Strichpixel %d halbtransparent (%d)', [X, GetRValue(C)]));
      end;
    end;
    CheckTrue(Dash > 10, Format('Striche gezeichnet (%d)', [Dash]));
    CheckTrue(Gap > 5, Format('Luecken bleiben frei (runde Enden verkuerzen sie) (%d)', [Gap]));
    for X := 55 to 57 do
    begin
      C := ColorToRGB(Bmp.Canvas.Pixels[X, 10]);
      CheckTrue(GetRValue(C) > 90, Format('Ecke %d nur einmal geblendet (%d)', [X, GetRValue(C)]));
    end;
  finally
    Bmp.Free;
  end;
end;

initialization
  RegisterTest('Review', TReviewTests.Suite);

end.
