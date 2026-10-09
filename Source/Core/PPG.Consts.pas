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
  SPPGNavFirst = 'First record';
  SPPGNavPrior = 'Previous record';
  SPPGNavNext = 'Next record';
  SPPGNavLast = 'Last record';
  SPPGNavInsert = 'Insert record';
  SPPGNavDelete = 'Delete record';
  SPPGNavEdit = 'Edit record';
  SPPGNavPost = 'Post edit';
  SPPGNavCancel = 'Cancel edit';
  SPPGNavRefresh = 'Refresh data';
  SPPGNavApply = 'Apply updates';
  SPPGNavCancelUpdates = 'Cancel updates';
  SPPGNavNewRecord = 'New record';
  SPPGNavNoRecords = 'No records';
  SPPGNavCounter = 'Record %d of %d';
  SPPGNavCount = '%d records';
  SPPGNavSearchHint = 'Search';
  SPPGNavFilter = 'Show matches only';
  SPPGNavDeleteConfirm = 'Delete record?';
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

  // Validator (Phase 19)
  SPPGValRequired = '%s is required.';
  SPPGValMustCheck = '%s must be checked.';
  SPPGValMustChoose = 'Please choose an option for %s.';
  SPPGValTooShort = '%s must have at least %d characters.';
  SPPGValTooLong = '%s must not have more than %d characters.';
  SPPGValBelowMin = '%s must be at least %s.';
  SPPGValAboveMax = '%s must not be greater than %s.';
  SPPGValNotANumber = '%s must be a number.';
  SPPGValPattern = '%s has an invalid format.';
  SPPGValEmail = '%s is not a valid e-mail address.';
  SPPGValPhone = '%s is not a valid phone number.';
  SPPGValPostalCode = '%s is not a valid postal code.';
  SPPGValIBAN = '%s is not a valid IBAN.';
  SPPGValEqual = '%s must match %s.';
  SPPGValNotEqual = '%s must be different from %s.';
  SPPGValLess = '%s must be less than %s.';
  SPPGValLessOrEqual = '%s must not be greater than %s.';
  SPPGValGreater = '%s must be greater than %s.';
  SPPGValGreaterOrEqual = '%s must not be less than %s.';
  SPPGValInvalid = '%s is invalid.';
  SPPGValUnsupported = 'The validator cannot read the value of %s (%s).';
  SPPGValOneError = '1 error';
  SPPGValErrors = '%d errors';
  SPPGValOneWarning = '1 warning';
  SPPGValWarnings = '%d warnings';
  SPPGValAndMore = '%s and %d more';
  SPPGValGoToError = 'Go to error';

  // Warte-Overlay (Phase 19c)
  SPPGBusyWait = 'Please wait...';
  SPPGBusyCancel = 'Cancel';
  SPPGBusyCancelling = 'Cancelling...';

  // Planer: Serienabfrage und Termin-Dialog (Phase 20a)
  SPPGPlannerSeriesTitle = 'Recurring appointment';
  SPPGPlannerSeriesChange = '"%s" is part of a series';
  SPPGPlannerSeriesDelete = 'Delete "%s"?';
  SPPGPlannerSeriesText = 'Only this occurrence or the whole series?';
  SPPGPlannerSeriesOne = 'Only this occurrence';
  SPPGPlannerSeriesOneHint = 'The other appointments of the series stay as they are.';
  SPPGPlannerSeriesAll = 'The whole series';
  SPPGPlannerSeriesAllHint = 'All appointments of the series change.';
  SPPGApptNew = 'New appointment';
  SPPGApptTitle = 'Appointment';
  SPPGApptSubject = 'Subject';
  SPPGApptLocation = 'Location';
  SPPGApptStart = 'Start';
  SPPGApptEnd = 'End';
  SPPGApptAllDay = 'All day';
  SPPGApptCategory = 'Category';
  SPPGApptNoCategory = '(None)';
  SPPGApptResource = 'Resource';
  SPPGApptNotes = 'Notes';
  SPPGApptRepeat = 'Repeat';
  SPPGApptFreqNone = 'Does not repeat';
  SPPGApptFreqDaily = 'Daily';
  SPPGApptFreqWeekly = 'Weekly';
  SPPGApptFreqMonthly = 'Monthly';
  SPPGApptFreqYearly = 'Yearly';
  SPPGApptFreqCustom = 'Custom (unchanged)';
  SPPGApptEvery = 'every';
  SPPGApptUnitDays = 'day(s)';
  SPPGApptUnitWeeks = 'week(s)';
  SPPGApptUnitMonths = 'month(s)';
  SPPGApptUnitYears = 'year(s)';
  SPPGApptEndsNever = 'Never ends';
  SPPGApptEndsAfter = 'Ends after';
  SPPGApptEndsOn = 'Ends on';
  SPPGApptEndBeforeStart = 'The end must not be before the start.';

implementation

end.
