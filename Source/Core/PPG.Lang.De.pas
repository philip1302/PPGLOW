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
  PPGLangDeCount = 39;

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
end;

initialization
  RegisterTexts;

end.
