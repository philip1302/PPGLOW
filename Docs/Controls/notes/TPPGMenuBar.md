**Vorbild:** TMS TAdvMainMenu, Menüleiste von Windows 11

## Unterschiede und Hinweise

- Zeigt ein normales `TMainMenu` (Property `Menu`) als Control, standardmäßig mit `Align = alTop` und automatischer Höhe.
- Ist `Menu` zugleich das Menü des Formulars, wird `Form.Menu` zur Laufzeit geleert (sonst gäbe es zwei Leisten) und beim Freigeben wiederhergestellt. Im Designer bleibt alles unverändert.
- Tastatur wie bei Windows: Alt oder F10 aktiviert die Leiste, Alt+Buchstabe öffnet ein Menü, Pfeile wechseln, Esc verlässt die Leiste. Tastenkürzel der Einträge (Strg+S …) wirken auch ohne geöffnetes Menü.
- Zwischen offenen Menüs wechselt die Maus ohne erneuten Klick; ein zweiter Klick auf dasselbe Menü schließt es.
- MDI-Menüs (`Merge`/`Unmerge`) werden noch nicht zusammengeführt.
- Screenreader: Rolle Menüleiste, Ereignisse `EVENT_SYSTEM_MENUSTART/END`.

## Beispiel

```pascal
PPGMenuBar1.Menu := MainMenu1;
```
