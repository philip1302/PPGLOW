unit PPG.Tests.Phase9d;

{ Tests fuer Phase 9d: Uebersetzung zur Laufzeit (PPG.Lang, PPG.Lang.De).
  Die RTL-Galerie steht in PPG.Tests.Visual (RtlGallery). }

interface

uses
  TestFramework, System.Classes, System.SysUtils,
  PPG.Consts, PPG.Exceptions, PPG.Lang, PPG.Lang.De, PPG.Controls.Base, PPG.Button,
  PPG.ProgressBar, PPG.Tests.Controls;

type
  TLanguageTests = class(TControlTestCase)
  protected
    procedure TearDown; override;
  published
    procedure GermanTableIsComplete;
    procedure PlaceholdersMatchOriginal;
    procedure SwitchChangesControlTexts;
    procedure ExceptionsUseActiveLanguage;
    procedure UnknownLanguageFallsBackToOriginal;
    procedure ChangeEventFires;
  end;

implementation

type
  TButtonAccess = class(TPPGButton);
  TProgressAccess = class(TPPGProgressBar);

const
  /// Alle Texte aus PPG.Consts (die Vollstaendigkeit gegen die Datei prueft
  /// zusaetzlich Build\make-lang.ps1 bzw. der Regel-Pruefer).
  AllTexts: array[0..208] of PResStringRec = (
    @SPPGInvalidPropertyValue, @SPPGValueOutOfRange, @SPPGValueClamped, @SPPGUnknownPreset,
    @SPPGUnknownPresetFallback, @SPPGRendererAlreadyRegistered, @SPPGRendererClassNil,
    @SPPGPaintFailed, @SPPGGdiPlusStartupFailed, @SPPGGdiPlusCallFailed, @SPPGOSCallFailed,
    @SPPGCallbackFailed, @SPPGCircularStyleManager, @SPPGNotMainThread, @SPPGIndexOutOfRange,
    @SPPGSortedListMove, @SPPGTreeMoveIntoChild, @SPPGInvalidArgument, @SPPGNoTarget,
    @SPPGAccPress, @SPPGAccCheck, @SPPGAccUncheck, @SPPGAccSelect, @SPPGAccOpen, @SPPGAccClose,
    @SPPGGridFilterHint, @SPPGSortAscending, @SPPGSortDescending, @SPPGDBGridConfirmDelete, @SPPGDBEditPending,
    @SPPGAccJump, @SPPGAccExpand, @SPPGAccCollapse, @SPPGAccOn, @SPPGAccOff, @SPPGAccToggle,
    @SPPGNavMenu, @SPPGMoreOptions, @SPPGNotifications, @SPPGPercentFormat,
    @SPPGInvalidValueList, @SPPGChartNoData, @SPPGSparklineSummary, @SPPGGaugeRangeInvalid,
    @SPPGKpiChange, @SPPGChartSeriesDefault, @SPPGChartPointName, @SPPGChartSeriesName,
    @SPPGChartSeriesHidden,
    @SPPGEditUndo, @SPPGEditCut, @SPPGEditCopy, @SPPGEditPaste, @SPPGEditDelete,
    @SPPGEditSelectAll,
    @SPPGDlgOK, @SPPGDlgCancel, @SPPGDlgYes, @SPPGDlgNo, @SPPGDlgAbort, @SPPGDlgRetry,
    @SPPGDlgIgnore, @SPPGDlgAll, @SPPGDlgNoToAll, @SPPGDlgYesToAll, @SPPGDlgHelp, @SPPGDlgClose,
    @SPPGDlgWarning, @SPPGDlgError, @SPPGDlgInformation, @SPPGDlgConfirm, @SPPGDlgShowDetails,
    @SPPGDlgHideDetails, @SPPGWizBack, @SPPGWizNext, @SPPGWizFinish, @SPPGWizStep,
    @SPPGNumberRequired, @SPPGNumberInvalid, @SPPGMaskInvalid, @SPPGCapsLockOn,
    @SPPGFileNotFound, @SPPGFolderNotFound,
    @SPPGColorNone, @SPPGColorDefault, @SPPGColorMore, @SPPGColorRecent, @SPPGColorStandard,
    @SPPGColorTheme, @SPPGColorSystem, @SPPGColorApply,
    @SPPGSelectAll, @SPPGCheckedCount, @SPPGAccRemove,
    @SPPGGridSortAsc, @SPPGGridSortDesc, @SPPGGridSortNone, @SPPGGridHideColumn,
    @SPPGGridColumnChooser, @SPPGGridShowAll, @SPPGGridBestFit, @SPPGGridBestFitAll,
    @SPPGGridGroupBy, @SPPGGridUngroup, @SPPGGridGroupPanelHint, @SPPGGridExpandAll,
    @SPPGGridCollapseAll, @SPPGGridGroupName,
    @SPPGPrintFooterDefault, @SPPGPrintNoPrinter, @SPPGPrinterNotFound, @SPPGPreviewTitle,
    @SPPGPreviewPrint, @SPPGPreviewPageSetup, @SPPGPreviewClose, @SPPGPreviewPage,
    @SPPGPreviewZoomPage, @SPPGPreviewZoomWidth, @SPPGPageSetupTitle, @SPPGPageSetupPortrait,
    @SPPGPageSetupLandscape, @SPPGPageSetupFit, @SPPGPageSetupRepeat, @SPPGPageSetupGridLines,
    @SPPGPageSetupColors, @SPPGPageSetupGridLook, @SPPGPageSetupMargins,
    @SPPGTileEmpty, @SPPGTileNoMatch, @SPPGTileColText, @SPPGTileColDetail, @SPPGTileColBadge,
    @SPPGTileColGroup,
    @SPPGNavFirst, @SPPGNavPrior, @SPPGNavNext, @SPPGNavLast, @SPPGNavInsert, @SPPGNavDelete,
    @SPPGNavEdit, @SPPGNavPost, @SPPGNavCancel, @SPPGNavRefresh, @SPPGNavApply,
    @SPPGNavCancelUpdates, @SPPGNavNewRecord, @SPPGNavNoRecords, @SPPGNavCounter, @SPPGNavCount,
    @SPPGNavSearchHint, @SPPGNavFilter, @SPPGNavDeleteConfirm,
    @SPPGPageSetupHeader, @SPPGPageSetupFooter,
    @SPPGXlsxInvalid, @SPPGPdfPrinterMissing,
    @SPPGRRuleInvalid, @SPPGICalInvalid, @SPPGPlannerAllDay,
    @SPPGPlannerMore, @SPPGPlannerNone, @SPPGPlannerNoSubject, @SPPGPlannerAccItem,
    @SPPGPlannerAccSlot, @SPPGPlannerPrintWorkHours,
    @SPPGRibbonName, @SPPGRibbonFile, @SPPGRibbonCustomizeQat, @SPPGRibbonAddToQat,
    @SPPGRibbonRemoveFromQat, @SPPGRibbonQatBelow, @SPPGRibbonQatAbove, @SPPGRibbonMinimize,
    @SPPGRibbonExpand, @SPPGRibbonGalleryUp, @SPPGRibbonGalleryDown, @SPPGRibbonContextTab,
    @SPPGKanbanAccCard, @SPPGKanbanAccDue, @SPPGKanbanAccColumn, @SPPGKanbanAccLimit,
    @SPPGKanbanAccCollapsed, @SPPGKanbanMoved, @SPPGKanbanMoveRejected,
    @SPPGKanbanPrintFitWidth,
    @SPPGThemeFileInvalid,
    @SPPGThemeValueInvalid,
    @SPPGColorInvalid,
    @SPPGValRequired,
    @SPPGValMustCheck,
    @SPPGValMustChoose,
    @SPPGValTooShort,
    @SPPGValTooLong,
    @SPPGValBelowMin,
    @SPPGValAboveMax,
    @SPPGValNotANumber,
    @SPPGValPattern,
    @SPPGValEmail,
    @SPPGValPhone,
    @SPPGValPostalCode,
    @SPPGValIBAN,
    @SPPGValEqual,
    @SPPGValNotEqual,
    @SPPGValLess,
    @SPPGValLessOrEqual,
    @SPPGValGreater,
    @SPPGValGreaterOrEqual,
    @SPPGValInvalid,
    @SPPGValUnsupported);

var
  GChanges: Integer;

procedure CountChange(Self, Sender: TObject);
begin
  Inc(GChanges);
end;

/// Platzhalter (%s, %d, %%, ...) in Reihenfolge.
function Placeholders(const S: string): string;
var
  I: Integer;
begin
  Result := '';
  I := 1;
  while I <= Length(S) do
  begin
    if S[I] = '%' then
    begin
      Inc(I);
      while (I <= Length(S)) and CharInSet(S[I], ['0'..'9', ':', '-', '.']) do
        Inc(I);
      if I <= Length(S) then
        Result := Result + '%' + LowerCase(S[I]);
    end;
    Inc(I);
  end;
end;

procedure TLanguageTests.TearDown;
begin
  PPGSetLanguage('');
  PPGOnLanguageChange := nil;
  inherited TearDown;
end;

procedure TLanguageTests.GermanTableIsComplete;
var
  I: Integer;
begin
  CheckEquals(Length(AllTexts), PPGLangDeCount, 'erzeugte Unit kennt alle Texte');
  CheckEquals(PPGLangDeCount, PPGTranslationCount('de'));
  for I := 0 to High(AllTexts) do
    CheckTrue(PPGTranslation('de', AllTexts[I]) <> '',
      'fehlt: ' + LoadResString(AllTexts[I]));
end;

procedure TLanguageTests.PlaceholdersMatchOriginal;
var
  I: Integer;
begin
  for I := 0 to High(AllTexts) do
    CheckEquals(Placeholders(LoadResString(AllTexts[I])),
      Placeholders(PPGTranslation('de', AllTexts[I])), LoadResString(AllTexts[I]));
end;

procedure TLanguageTests.SwitchChangesControlTexts;
var
  B: TPPGButton;
  P: TPPGProgressBar;
begin
  B := NewButton('A');
  P := TPPGProgressBar.Create(FForm);
  P.Parent := FForm;
  P.Position := 40;
  CheckEquals('Press', TButtonAccess(B).AccDefaultAction);
  PPGSetLanguage('de');
  CheckEquals('de', PPGLanguage);
  CheckEquals('Dr' + #$00FC + 'cken', TButtonAccess(B).AccDefaultAction);
  CheckEquals('40 %', TProgressAccess(P).AccValue);
  PPGSetLanguage('en');
  CheckEquals('', PPGLanguage, 'en = Original');
  CheckEquals('Press', TButtonAccess(B).AccDefaultAction);
end;

procedure TLanguageTests.ExceptionsUseActiveLanguage;
var
  B: TPPGButton;
  Msg: string;
begin
  B := NewButton('A');
  PPGSetLanguage('de');
  Msg := '';
  try
    B.Preset := 'GibtEsNicht';
  except
    on E: EPPGPropertyError do
      Msg := E.Message;
  end;
  CheckTrue(Pos('Ung' + #$00FC + 'ltiger Wert', Msg) = 1, Msg);
end;

procedure TLanguageTests.UnknownLanguageFallsBackToOriginal;
begin
  PPGSetLanguage('xx');
  CheckEquals('Press', PPGStr(@SPPGAccPress));
  CheckEquals('', PPGTranslation('xx', @SPPGAccPress));
end;

procedure TLanguageTests.ChangeEventFires;
var
  M: TMethod;
begin
  GChanges := 0;
  M.Code := @CountChange;
  M.Data := nil;
  PPGOnLanguageChange := TNotifyEvent(M);
  PPGSetLanguage('de');
  PPGSetLanguage('');
  CheckEquals(2, GChanges);
end;

initialization
  RegisterTest('Phase9d', TLanguageTests.Suite);

end.
