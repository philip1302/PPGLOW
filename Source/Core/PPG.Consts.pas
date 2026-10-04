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

  // Barrierefreiheit (Standardaktionen, werden vom Screenreader vorgelesen)
  SPPGAccPress = 'Press';
  SPPGAccCheck = 'Check';
  SPPGAccUncheck = 'Uncheck';
  SPPGAccSelect = 'Select';
  SPPGAccOpen = 'Open';
  SPPGAccClose = 'Close';
  SPPGGridFilterHint = 'Filter';
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

implementation

end.
