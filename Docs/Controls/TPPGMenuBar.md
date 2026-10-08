# TPPGMenuBar

Palette **PPGlow** - Unit `PPG.MenuBar` - Basis `TPPGCustomMenuBar`

**Vorbild:** TMS TAdvMainMenu, Menüleiste von Windows 11

## Unterschiede und Hinweise

- Zeigt ein normales `TMainMenu` (Property `Menu`) als Control, standardmäßig mit `Align = alTop` und automatischer Höhe.
- Ist `Menu` zugleich das Menü des Formulars, wird `Form.Menu` zur Laufzeit geleert (sonst gäbe es zwei Leisten) und beim Freigeben wiederhergestellt. Im Designer bleibt alles unverändert.
- Tastatur wie bei Windows: Alt oder F10 aktiviert die Leiste, Alt+Buchstabe öffnet ein Menü, Pfeile wechseln, Esc verlässt die Leiste. Tastenkürzel der Einträge (Strg+S …) wirken auch ohne geöffnetes Menü.
- Zwischen offenen Menüs wechselt die Maus ohne erneuten Klick; ein zweiter Klick auf dasselbe Menü schließt es.
- MDI-Menüs (`Merge`/`Unmerge`) werden noch nicht zusammengeführt.
- Screenreader: Rolle Menüleiste, Ereignisse `EVENT_SYSTEM_MENUSTART/END`.

## Anpassung

- `MenuStyles` und `OnCustomDrawItem` wie `TPPGPopupMenu`.

## Beispiel

```pascal
PPGMenuBar1.Menu := MainMenu1;
```

## Verhalten (aus dem Quelltext)

TPPGMenuBar - Hauptmenue als Control im Stil der Suite (Phase 11c).

- Modell ist ein normales TMainMenu (Menue-Designer, Actions, DFM). Die Leiste zeigt seine Eintraege; Untermenues kommen aus PPG.Menus.
- Zur Laufzeit wird Form.Menu geleert (die Menue-Leiste im Nicht-Client- Bereich laesst sich weder stylen noch auf Dark Mode umstellen); beim Freigeben der Leiste wird es wiederhergestellt. Zur Entwurfszeit bleibt das Formular-Menue sichtbar.
- Weil Form.Menu leer ist, loest die VCL die Tastenkuerzel der Eintraege nicht mehr aus: das uebernimmt die Leiste (TMenu.IsShortCut, wie TCustomForm.IsShortCut).
- Tastatur wie Windows: Alt allein bzw. F10 markiert die Leiste, Alt+ Buchstabe oeffnet den Eintrag, Pfeile wechseln, Esc verlaesst. Haken in PPG.AppHooks, nur fuer Nachrichten des eigenen Formulars.
- Barrierefreiheit: Rolle MENUBAR mit Eintraegen als Kindern, EVENT_SYSTEM_MENUSTART/END.

## PPGlow-Eigenschaften

`Menu`, `MenuStyles`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `Visible`, `Touch`

## Ereignisse

`OnCustomDrawItem`, `OnGesture`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGMenuBar.md`.
