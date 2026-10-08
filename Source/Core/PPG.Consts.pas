unit PPG.Consts;

{ Alle benutzersichtbaren Texte der Suite als resourcestring (lokalisierbar). }

{$I ..\PPG.inc}

interface

const
  PPGPaletteName = 'PPGlow';
  PPGDefaultPreset = 'ModernFlat';
  PPGPresetClassic = 'Classic';
  PPGPresetModernFlat = 'ModernFlat';
  PPGPresetFluent11 = 'Fluent11';

resourcestring
  SPPGInvalidPropertyValue = 'Invalid value "%s" for property %s.%s';
  SPPGValueOutOfRange = 'Value %d for property %s.%s is out of range (%d..%d)';
  SPPGValueClamped = 'Value %d for property %s.%s was clamped to %d while loading';
  SPPGUnknownPreset = 'Unknown preset "%s"';
  SPPGUnknownPresetFallback = 'Unknown preset "%s" while loading %s, falling back to "%s"';
  SPPGRendererAlreadyRegistered = 'A renderer named "%s" is already registered';
  SPPGRendererClassNil = 'Renderer class must not be nil';
  SPPGPaintFailed = 'Painting of %s failed: %s';
  SPPGGdiPlusStartupFailed = 'GDI+ could not be started (status %d), using GDI fallback';
  SPPGGdiPlusCallFailed = 'GDI+ call %s failed with status %d';
  SPPGOSCallFailed = 'Windows API call %s failed (error %d: %s)';
  SPPGCallbackFailed = 'Callback %s failed: %s';
  SPPGCircularStyleManager = 'Style manager cannot be assigned to itself';
  SPPGNotMainThread = '%s must only be accessed from the main thread';
  SPPGIndexOutOfRange = 'Index %d out of range (0..%d)';
  SPPGSortedListMove = 'Items of a sorted list cannot be moved';
  SPPGTreeMoveIntoChild = 'A tree node cannot be moved into its own children';
  SPPGInvalidArgument = 'Invalid value %d for %s';
  SPPGNoTarget = '%s needs a target component';

  // Barrierefreiheit (Standardaktionen, werden vom Screenreader vorgelesen)
  SPPGAccPress = 'Press';
  SPPGAccCheck = 'Check';
  SPPGAccUncheck = 'Uncheck';
  SPPGAccSelect = 'Select';
  SPPGAccOpen = 'Open';
  SPPGAccClose = 'Close';
  SPPGGridFilterHint = 'Filter';
  SPPGSortAscending = 'Sorted ascending';
  SPPGSortDescending = 'Sorted descending';
  SPPGDBGridConfirmDelete = 'Delete record?';
  SPPGDBEditPending = 'The data set is being edited elsewhere. Post or cancel that edit first.';
  SPPGAccJump = 'Jump';
  SPPGAccExpand = 'Expand';
  SPPGAccCollapse = 'Collapse';
  SPPGAccOn = 'On';
  SPPGAccOff = 'Off';
  SPPGAccToggle = 'Toggle';
  SPPGNavMenu = 'Open or close navigation';
  SPPGMoreOptions = 'More options';
  SPPGNotifications = 'Notifications';

  // ProgressBar: Prozentanzeige (Text im Balken und Wert fuer Screenreader)
  SPPGPercentFormat = '%d %%';

  // Diagramme (Phase 10)
  SPPGInvalidValueList = 'Invalid value list "%s" ignored while loading';
  SPPGChartNoData = 'No data';
  SPPGSparklineSummary = 'Min %s, max %s, last %s';
  SPPGGaugeRangeInvalid = 'Minimum (%s) must be less than maximum (%s)';
  SPPGKpiChange = 'Change %s';
  SPPGChartSeriesDefault = 'Series %d';
  SPPGChartPointName = '%s, %s: %s';
  SPPGChartSeriesName = '%s, %d points';
  SPPGChartSeriesHidden = '%s (hidden)';

  // Bearbeiten-Menue der Felder (Phase 11d)
  SPPGEditUndo = '&Undo';
  SPPGEditCut = 'Cu&t';
  SPPGEditCopy = '&Copy';
  SPPGEditPaste = '&Paste';
  SPPGEditDelete = '&Delete';
  SPPGEditSelectAll = 'Select &All';

  // Dialoge und Assistent (Phase 11g)
  SPPGDlgOK = 'OK';
  SPPGDlgCancel = 'Cancel';
  SPPGDlgYes = '&Yes';
  SPPGDlgNo = '&No';
  SPPGDlgAbort = '&Abort';
  SPPGDlgRetry = '&Retry';
  SPPGDlgIgnore = '&Ignore';
  SPPGDlgAll = '&All';
  SPPGDlgNoToAll = 'N&o to All';
  SPPGDlgYesToAll = 'Yes to A&ll';
  SPPGDlgHelp = '&Help';
  SPPGDlgClose = '&Close';
  SPPGDlgWarning = 'Warning';
  SPPGDlgError = 'Error';
  SPPGDlgInformation = 'Information';
  SPPGDlgConfirm = 'Confirm';
  SPPGDlgShowDetails = 'Show details';
  SPPGDlgHideDetails = 'Hide details';
  SPPGWizBack = '< &Back';
  SPPGWizNext = '&Next >';
  SPPGWizFinish = '&Finish';
  SPPGWizStep = 'Step %d of %d: %s';

  // Eingabefelder (Phase 12)
  SPPGNumberRequired = 'A value is required';
  SPPGNumberInvalid = 'Not a valid number';
  SPPGMaskInvalid = 'Input does not match the mask';
  SPPGCapsLockOn = 'Caps Lock is on';
  SPPGFileNotFound = 'File not found';
  SPPGFolderNotFound = 'Folder not found';
  SPPGColorNone = 'None';
  SPPGColorDefault = 'Default';
  SPPGColorMore = 'More colors...';
  SPPGColorRecent = 'Recent colors';
  SPPGColorStandard = 'Standard colors';
  SPPGColorTheme = 'Theme colors';
  SPPGColorSystem = 'System colors';
  SPPGColorApply = 'Apply';
  SPPGSelectAll = 'Select all';
  SPPGCheckedCount = '%d selected';
  SPPGAccRemove = 'Remove';

  // Grid-Kopfmenue (Phase 13b)
  SPPGGridSortAsc = 'Sort ascending';
  SPPGGridSortDesc = 'Sort descending';
  SPPGGridSortNone = 'Remove sorting';
  SPPGGridHideColumn = 'Hide column';
  SPPGGridColumnChooser = 'Columns';
  SPPGGridShowAll = 'Show all columns';
  SPPGGridBestFit = 'Best fit';
  SPPGGridBestFitAll = 'Best fit (all columns)';
  SPPGGridGroupBy = 'Group by this column';
  SPPGGridUngroup = 'Remove grouping';
  SPPGGridGroupPanelHint = 'Drag a column header here to group by that column';
  SPPGGridExpandAll = 'Expand all groups';
  SPPGGridCollapseAll = 'Collapse all groups';
  SPPGGridGroupName = '%s: %s, %d rows';

  // Drucken (Phase 13e)
  SPPGPrintFooterDefault = 'Page [Page] of [Pages]';
  SPPGPrintNoPrinter = 'No printer is installed';
  SPPGPrinterNotFound = 'Printer "%s" not found';
  SPPGPreviewTitle = 'Print preview';
  SPPGPreviewPrint = 'Print';
  SPPGPreviewPageSetup = 'Page setup...';
  SPPGPreviewClose = 'Close';
  SPPGPreviewPage = 'Page %d of %d';
  SPPGPreviewZoomPage = 'Whole page';
  SPPGPreviewZoomWidth = 'Page width';
  SPPGPageSetupTitle = 'Page setup';
  SPPGPageSetupPortrait = 'Portrait';
  SPPGPageSetupLandscape = 'Landscape';
  SPPGPageSetupFit = 'Fit to page width';
  SPPGPageSetupRepeat = 'Repeat column headers on every page';
  SPPGPageSetupGridLines = 'Print grid lines';
  SPPGPageSetupColors = 'Print colors';
  SPPGPageSetupGridLook = 'Look like the grid (colors, bands, groups, totals)';
  SPPGTileEmpty = 'No items';
  SPPGTileNoMatch = 'No matches';
  SPPGTileColText = 'Title';
  SPPGTileColDetail = 'Detail';
  SPPGTileColBadge = 'Badge';
  SPPGTileColGroup = 'Group';
  SPPGPageSetupMargins = 'Margins left, top, right, bottom (mm)';
  SPPGPageSetupHeader = 'Header';
  SPPGPageSetupFooter = 'Footer';

  // Export (Phase 13f)
  SPPGXlsxInvalid = 'Not a valid xlsx file (%s missing)';
  SPPGPdfPrinterMissing = 'The printer "Microsoft Print to PDF" is not installed (Windows features: "Microsoft Print to PDF")';

  // Planer (Phase 14a)
  SPPGRRuleInvalid = 'Invalid recurrence rule "%s"';
  SPPGICalInvalid = 'Not an iCalendar file (BEGIN:VCALENDAR missing)';
  SPPGPlannerAllDay = 'All day';
  SPPGPlannerMore = '+%d more';
  SPPGPlannerNone = 'No appointments';
  SPPGPlannerNoSubject = '(No subject)';
  SPPGPlannerAccItem = '%s, %s to %s';
  SPPGPlannerAccSlot = '%s to %s';
  SPPGPlannerPrintWorkHours = 'Print working hours only';
  SPPGKanbanPrintFitWidth = 'Shrink to page width';

  // Ribbon (Phase 14b)
  SPPGRibbonName = 'Ribbon';
  SPPGRibbonFile = 'File';
  SPPGRibbonCustomizeQat = 'Customize Quick Access Toolbar';
  SPPGRibbonAddToQat = 'Add to Quick Access Toolbar';
  SPPGRibbonRemoveFromQat = 'Remove from Quick Access Toolbar';
  SPPGRibbonQatBelow = 'Show Quick Access Toolbar below the Ribbon';
  SPPGRibbonQatAbove = 'Show Quick Access Toolbar above the Ribbon';
  SPPGRibbonMinimize = 'Collapse the Ribbon';
  SPPGRibbonExpand = 'Pin the Ribbon';
  SPPGRibbonGalleryUp = 'Previous row';
  SPPGRibbonGalleryDown = 'Next row';
  SPPGRibbonContextTab = '%s: %s';

  // Kanban (Phase 14c)
  SPPGKanbanAccCard = '%s, column %s, position %d of %d';
  SPPGKanbanAccDue = 'due %s';
  SPPGKanbanAccColumn = 'Column %s, %d cards';
  SPPGKanbanAccLimit = 'limit %d';
  SPPGKanbanAccCollapsed = 'collapsed';
  SPPGKanbanMoved = 'Moved to column %s, position %d of %d';
  SPPGKanbanMoveRejected = 'Moving to column %s is not allowed';

  // Anpassbarkeit (Theme-Datei, Farben)
  SPPGThemeFileInvalid = 'The theme file "%s" is invalid: %s';
  SPPGThemeValueInvalid = 'Invalid value "%s" for %s';
  SPPGColorInvalid = '"%s" is not a valid color';

implementation

end.
