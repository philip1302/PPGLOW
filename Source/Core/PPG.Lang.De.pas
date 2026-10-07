unit PPG.Lang.De;

{ Uebersetzung 'de' der PPGlow-Texte. ERZEUGT von Build\make-lang.ps1
  aus Lang\PPGlow.de.txt - nicht von Hand aendern.

  Einbinden und aktivieren:
    uses PPG.Lang, PPG.Lang.De;
    PPGSetLanguage('de'); }

{$I ..\PPG.inc}

interface

const
  PPGLangDeCode = 'de';
  PPGLangDeCount = 157;

implementation

uses
  PPG.Consts, PPG.Lang;

procedure RegisterTexts;
begin
  PPGAddTranslation(PPGLangDeCode, @SPPGInvalidPropertyValue,
    'Ung'#$00FC'ltiger Wert "%s" f'#$00FC'r die Eigenschaft %s.%s');
  PPGAddTranslation(PPGLangDeCode, @SPPGValueOutOfRange,
    'Wert %d f'#$00FC'r die Eigenschaft %s.%s liegt au'#$00DF'erhalb des Bereichs (%d..%d)');
  PPGAddTranslation(PPGLangDeCode, @SPPGValueClamped,
    'Wert %d f'#$00FC'r die Eigenschaft %s.%s wurde beim Laden auf %d begrenzt');
  PPGAddTranslation(PPGLangDeCode, @SPPGUnknownPreset,
    'Unbekanntes Preset "%s"');
  PPGAddTranslation(PPGLangDeCode, @SPPGUnknownPresetFallback,
    'Unbekanntes Preset "%s" beim Laden von %s, verwende "%s"');
  PPGAddTranslation(PPGLangDeCode, @SPPGRendererAlreadyRegistered,
    'Ein Renderer mit dem Namen "%s" ist bereits registriert');
  PPGAddTranslation(PPGLangDeCode, @SPPGRendererClassNil,
    'Die Renderer-Klasse darf nicht nil sein');
  PPGAddTranslation(PPGLangDeCode, @SPPGPaintFailed,
    'Zeichnen von %s fehlgeschlagen: %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGGdiPlusStartupFailed,
    'GDI+ konnte nicht gestartet werden (Status %d), GDI wird verwendet');
  PPGAddTranslation(PPGLangDeCode, @SPPGGdiPlusCallFailed,
    'GDI+-Aufruf %s fehlgeschlagen mit Status %d');
  PPGAddTranslation(PPGLangDeCode, @SPPGOSCallFailed,
    'Windows-API-Aufruf %s fehlgeschlagen (Fehler %d: %s)');
  PPGAddTranslation(PPGLangDeCode, @SPPGCallbackFailed,
    'R'#$00FC'ckruf %s fehlgeschlagen: %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGCircularStyleManager,
    'Ein StyleManager kann nicht sich selbst zugewiesen werden');
  PPGAddTranslation(PPGLangDeCode, @SPPGNotMainThread,
    '%s darf nur im Haupt-Thread verwendet werden');
  PPGAddTranslation(PPGLangDeCode, @SPPGIndexOutOfRange,
    'Index %d au'#$00DF'erhalb des Bereichs (0..%d)');
  PPGAddTranslation(PPGLangDeCode, @SPPGSortedListMove,
    'Eintr'#$00E4'ge einer sortierten Liste k'#$00F6'nnen nicht verschoben werden');
  PPGAddTranslation(PPGLangDeCode, @SPPGTreeMoveIntoChild,
    'Ein Knoten kann nicht in seine eigenen Kinder verschoben werden');
  PPGAddTranslation(PPGLangDeCode, @SPPGInvalidArgument,
    'Ung'#$00FC'ltiger Wert %d f'#$00FC'r %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGNoTarget,
    '%s braucht eine Zielkomponente');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccPress,
    'Dr'#$00FC'cken');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccCheck,
    'Aktivieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccUncheck,
    'Deaktivieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccSelect,
    'Ausw'#$00E4'hlen');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccOpen,
    #$00D6'ffnen');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccClose,
    'Schlie'#$00DF'en');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridFilterHint,
    'Filter');
  PPGAddTranslation(PPGLangDeCode, @SPPGSortAscending,
    'Aufsteigend sortiert');
  PPGAddTranslation(PPGLangDeCode, @SPPGSortDescending,
    'Absteigend sortiert');
  PPGAddTranslation(PPGLangDeCode, @SPPGDBGridConfirmDelete,
    'Datensatz l'#$00F6'schen?');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccJump,
    'Springen');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccExpand,
    'Erweitern');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccCollapse,
    'Reduzieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccOn,
    'Ein');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccOff,
    'Aus');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccToggle,
    'Umschalten');
  PPGAddTranslation(PPGLangDeCode, @SPPGNavMenu,
    'Navigation '#$00F6'ffnen oder schlie'#$00DF'en');
  PPGAddTranslation(PPGLangDeCode, @SPPGMoreOptions,
    'Weitere Optionen');
  PPGAddTranslation(PPGLangDeCode, @SPPGNotifications,
    'Benachrichtigungen');
  PPGAddTranslation(PPGLangDeCode, @SPPGPercentFormat,
    '%d %%');
  PPGAddTranslation(PPGLangDeCode, @SPPGInvalidValueList,
    'Ung'#$00FC'ltige Werteliste "%s" beim Laden ignoriert');
  PPGAddTranslation(PPGLangDeCode, @SPPGChartNoData,
    'Keine Daten');
  PPGAddTranslation(PPGLangDeCode, @SPPGSparklineSummary,
    'Min %s, Max %s, letzter %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGGaugeRangeInvalid,
    'Minimum (%s) muss kleiner als Maximum (%s) sein');
  PPGAddTranslation(PPGLangDeCode, @SPPGKpiChange,
    'Ver'#$00E4'nderung %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGChartSeriesDefault,
    'Reihe %d');
  PPGAddTranslation(PPGLangDeCode, @SPPGChartPointName,
    '%s, %s: %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGChartSeriesName,
    '%s, %d Punkte');
  PPGAddTranslation(PPGLangDeCode, @SPPGChartSeriesHidden,
    '%s (ausgeblendet)');
  PPGAddTranslation(PPGLangDeCode, @SPPGEditUndo,
    '&R'#$00FC'ckg'#$00E4'ngig');
  PPGAddTranslation(PPGLangDeCode, @SPPGEditCut,
    '&Ausschneiden');
  PPGAddTranslation(PPGLangDeCode, @SPPGEditCopy,
    '&Kopieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGEditPaste,
    '&Einf'#$00FC'gen');
  PPGAddTranslation(PPGLangDeCode, @SPPGEditDelete,
    '&L'#$00F6'schen');
  PPGAddTranslation(PPGLangDeCode, @SPPGEditSelectAll,
    'Alles &markieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgOK,
    'OK');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgCancel,
    'Abbrechen');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgYes,
    '&Ja');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgNo,
    '&Nein');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgAbort,
    '&Abbrechen');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgRetry,
    '&Wiederholen');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgIgnore,
    '&Ignorieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgAll,
    'A&lle');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgNoToAll,
    'N&ein f'#$00FC'r alle');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgYesToAll,
    'Ja f'#$00FC'r a&lle');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgHelp,
    '&Hilfe');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgClose,
    '&Schlie'#$00DF'en');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgWarning,
    'Warnung');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgError,
    'Fehler');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgInformation,
    'Information');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgConfirm,
    'Best'#$00E4'tigen');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgShowDetails,
    'Details einblenden');
  PPGAddTranslation(PPGLangDeCode, @SPPGDlgHideDetails,
    'Details ausblenden');
  PPGAddTranslation(PPGLangDeCode, @SPPGWizBack,
    '< &Zur'#$00FC'ck');
  PPGAddTranslation(PPGLangDeCode, @SPPGWizNext,
    '&Weiter >');
  PPGAddTranslation(PPGLangDeCode, @SPPGWizFinish,
    '&Fertig stellen');
  PPGAddTranslation(PPGLangDeCode, @SPPGWizStep,
    'Schritt %d von %d: %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGNumberRequired,
    'Ein Wert ist erforderlich');
  PPGAddTranslation(PPGLangDeCode, @SPPGNumberInvalid,
    'Keine g'#$00FC'ltige Zahl');
  PPGAddTranslation(PPGLangDeCode, @SPPGMaskInvalid,
    'Eingabe passt nicht zur Maske');
  PPGAddTranslation(PPGLangDeCode, @SPPGCapsLockOn,
    'Feststelltaste ist aktiv');
  PPGAddTranslation(PPGLangDeCode, @SPPGFileNotFound,
    'Datei nicht gefunden');
  PPGAddTranslation(PPGLangDeCode, @SPPGFolderNotFound,
    'Ordner nicht gefunden');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorNone,
    'Keine');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorDefault,
    'Standard');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorMore,
    'Weitere Farben...');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorRecent,
    'Zuletzt verwendet');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorStandard,
    'Standardfarben');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorTheme,
    'Designfarben');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorSystem,
    'Systemfarben');
  PPGAddTranslation(PPGLangDeCode, @SPPGColorApply,
    #$00DC'bernehmen');
  PPGAddTranslation(PPGLangDeCode, @SPPGSelectAll,
    'Alle ausw'#$00E4'hlen');
  PPGAddTranslation(PPGLangDeCode, @SPPGCheckedCount,
    '%d ausgew'#$00E4'hlt');
  PPGAddTranslation(PPGLangDeCode, @SPPGAccRemove,
    'Entfernen');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridSortAsc,
    'Aufsteigend sortieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridSortDesc,
    'Absteigend sortieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridSortNone,
    'Sortierung entfernen');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridHideColumn,
    'Spalte ausblenden');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridColumnChooser,
    'Spalten');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridShowAll,
    'Alle Spalten einblenden');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridBestFit,
    'Optimale Breite');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridBestFitAll,
    'Optimale Breite (alle Spalten)');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridGroupBy,
    'Nach dieser Spalte gruppieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridUngroup,
    'Gruppierung aufheben');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridGroupPanelHint,
    'Spaltenkopf hierher ziehen, um nach dieser Spalte zu gruppieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridExpandAll,
    'Alle Gruppen aufklappen');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridCollapseAll,
    'Alle Gruppen zuklappen');
  PPGAddTranslation(PPGLangDeCode, @SPPGGridGroupName,
    '%s: %s, %d Zeilen');
  PPGAddTranslation(PPGLangDeCode, @SPPGPrintFooterDefault,
    'Seite [Seite] von [Seiten]');
  PPGAddTranslation(PPGLangDeCode, @SPPGPrintNoPrinter,
    'Es ist kein Drucker installiert');
  PPGAddTranslation(PPGLangDeCode, @SPPGPrinterNotFound,
    'Drucker '#$201E'%s'#$201C' nicht gefunden');
  PPGAddTranslation(PPGLangDeCode, @SPPGPreviewTitle,
    'Seitenansicht');
  PPGAddTranslation(PPGLangDeCode, @SPPGPreviewPrint,
    'Drucken');
  PPGAddTranslation(PPGLangDeCode, @SPPGPreviewPageSetup,
    'Seite einrichten...');
  PPGAddTranslation(PPGLangDeCode, @SPPGPreviewClose,
    'Schlie'#$00DF'en');
  PPGAddTranslation(PPGLangDeCode, @SPPGPreviewPage,
    'Seite %d von %d');
  PPGAddTranslation(PPGLangDeCode, @SPPGPreviewZoomPage,
    'Ganze Seite');
  PPGAddTranslation(PPGLangDeCode, @SPPGPreviewZoomWidth,
    'Seitenbreite');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupTitle,
    'Seite einrichten');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupPortrait,
    'Hochformat');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupLandscape,
    'Querformat');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupFit,
    'Auf Seitenbreite anpassen');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupRepeat,
    'Spaltenk'#$00F6'pfe auf jeder Seite wiederholen');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupGridLines,
    'Gitterlinien drucken');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupColors,
    'Farben drucken');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupMargins,
    'R'#$00E4'nder links, oben, rechts, unten (mm)');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupHeader,
    'Kopfzeile');
  PPGAddTranslation(PPGLangDeCode, @SPPGPageSetupFooter,
    'Fu'#$00DF'zeile');
  PPGAddTranslation(PPGLangDeCode, @SPPGXlsxInvalid,
    'Keine g'#$00FC'ltige xlsx-Datei (%s fehlt)');
  PPGAddTranslation(PPGLangDeCode, @SPPGPdfPrinterMissing,
    'Der Drucker '#$201E'Microsoft Print to PDF'#$201C' ist nicht installiert (Windows-Features: '#$201E'Microsoft Print to PDF'#$201C')');
  PPGAddTranslation(PPGLangDeCode, @SPPGRRuleInvalid,
    'Ung'#$00FC'ltige Wiederholungsregel '#$201E'%s'#$201C);
  PPGAddTranslation(PPGLangDeCode, @SPPGICalInvalid,
    'Keine iCalendar-Datei (BEGIN:VCALENDAR fehlt)');
  PPGAddTranslation(PPGLangDeCode, @SPPGPlannerAllDay,
    'Ganzt'#$00E4'gig');
  PPGAddTranslation(PPGLangDeCode, @SPPGPlannerMore,
    '+%d weitere');
  PPGAddTranslation(PPGLangDeCode, @SPPGPlannerNone,
    'Keine Termine');
  PPGAddTranslation(PPGLangDeCode, @SPPGPlannerNoSubject,
    '(Kein Betreff)');
  PPGAddTranslation(PPGLangDeCode, @SPPGPlannerAccItem,
    '%s, %s bis %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGPlannerAccSlot,
    '%s bis %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGPlannerPrintWorkHours,
    'Nur die Arbeitszeit drucken');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonName,
    'Men'#$00FC'band');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonFile,
    'Datei');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonCustomizeQat,
    'Symbolleiste f'#$00FC'r den Schnellzugriff anpassen');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonAddToQat,
    'Zur Symbolleiste f'#$00FC'r den Schnellzugriff hinzuf'#$00FC'gen');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonRemoveFromQat,
    'Aus der Symbolleiste f'#$00FC'r den Schnellzugriff entfernen');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonQatBelow,
    'Symbolleiste f'#$00FC'r den Schnellzugriff unter dem Men'#$00FC'band anzeigen');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonQatAbove,
    'Symbolleiste f'#$00FC'r den Schnellzugriff '#$00FC'ber dem Men'#$00FC'band anzeigen');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonMinimize,
    'Men'#$00FC'band reduzieren');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonExpand,
    'Men'#$00FC'band anheften');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonGalleryUp,
    'Vorherige Zeile');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonGalleryDown,
    'N'#$00E4'chste Zeile');
  PPGAddTranslation(PPGLangDeCode, @SPPGRibbonContextTab,
    '%s: %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGKanbanAccCard,
    '%s, Spalte %s, Position %d von %d');
  PPGAddTranslation(PPGLangDeCode, @SPPGKanbanAccDue,
    'f'#$00E4'llig %s');
  PPGAddTranslation(PPGLangDeCode, @SPPGKanbanAccColumn,
    'Spalte %s, %d Karten');
  PPGAddTranslation(PPGLangDeCode, @SPPGKanbanAccLimit,
    'Limit %d');
  PPGAddTranslation(PPGLangDeCode, @SPPGKanbanAccCollapsed,
    'eingeklappt');
  PPGAddTranslation(PPGLangDeCode, @SPPGKanbanMoved,
    'Verschoben nach Spalte %s, Position %d von %d');
  PPGAddTranslation(PPGLangDeCode, @SPPGKanbanMoveRejected,
    'Verschieben in die Spalte %s ist nicht erlaubt');
end;

initialization
  RegisterTexts;

end.
