// PPG.inc - zentrale Compiler-Schalter der PPGlow-Suite.
//
// Regeln (siehe Docs\Coding-Rules.md):
// - Jede Unit bindet diese Datei direkt nach "unit ...;" ein.
// - $IF wird IMMER mit $IFEND geschlossen (XE2-Kompatibilitaet).
// - Features werden ueber PPG_HAS_* abgefragt, nie direkt ueber VERxxx.

{$IF CompilerVersion < 23.0}
  {$MESSAGE FATAL 'PPGlow benoetigt mindestens Delphi XE2.'}
{$IFEND}

// XE3+: TControl.StyleElements
{$IF CompilerVersion >= 24.0}
  {$DEFINE PPG_HAS_STYLEELEMENTS}
  // XE3+: TBasicAction/TContainedAction in der Unit System.Actions
  {$DEFINE PPG_HAS_SYSTEM_ACTIONS}
  // XE3+: TDBNavigator-Knoepfe nbApplyUpdates/nbCancelUpdates, IDataSetCommandSupport
  {$DEFINE PPG_HAS_DATASETCOMMANDS}
{$IFEND}

// 10.3 Rio+: Per-Monitor-V2, TControl.CurrentPPI, TImageCollection
{$IF CompilerVersion >= 33.0}
  {$DEFINE PPG_HAS_PPI}
  {$DEFINE PPG_HAS_IMAGECOLLECTION}
{$IFEND}

// 10.4 Sydney+: TImageIndex liegt in System.UITypes (Vcl.ImgList-Alias ist deprecated)
{$IF CompilerVersion >= 34.0}
  {$DEFINE PPG_HAS_UITYPES_IMAGEINDEX}
{$IFEND}

// 10.4 Sydney+: ImageName (Bilder per Name aus TImageCollection/TVirtualImageList)
{$IF CompilerVersion >= 34.0}
  {$DEFINE PPG_HAS_IMAGENAME}
{$IFEND}

// Delphi 13+: UI Automation in der VCL
{$IF CompilerVersion >= 37.0}
  {$DEFINE PPG_HAS_UIA}
{$IFEND}

// THintInfo liegt (belegt ab Delphi 13) in Vcl.Controls; Vcl.Forms.THintInfo ist dort
// veraltet. Aeltere Versionen nehmen Vcl.Forms (auch falls der Umzug frueher war:
// dann nur eine Veraltet-Warnung, kein Fehler).
{$IF CompilerVersion >= 37.0}
  {$DEFINE PPG_HINTINFO_IN_CONTROLS}
{$IFEND}

// Einheitliche Compiler-Einstellungen fuer alle Units
{$SCOPEDENUMS OFF}
{$BOOLEVAL OFF}
{$LONGSTRINGS ON}
{$EXTENDEDSYNTAX ON}
{$WRITEABLECONST OFF}

// Asserts nur im Debug-Build (interne Invarianten, nie Benutzereingaben)
{$IFDEF DEBUG}
  {$ASSERTIONS ON}
{$ELSE}
  {$ASSERTIONS OFF}
{$ENDIF}
