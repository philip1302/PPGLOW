**Vorbild:** TMS TAdvPopupMenu, Windows-11-Kontextmenü

## Unterschiede und Hinweise

- `TPPGPopupMenu` ist ein `TPopupMenu`: Menü-Designer, Actions, `OnPopup`, `AutoCheck`, `RadioItem`, `Break`, Tastenkürzel und `OwnerDraw` funktionieren wie gewohnt. Ersetzt wird nur die Darstellung.
- Zum Umstellen genügt der Klassenname in DFM und `uses` (bzw. `migrate.ps1`).
- `Popup(X, Y)` ist modal wie bei der VCL: Der Aufruf kehrt erst nach dem Schließen zurück. Der Klick auf einen Eintrag wird erst danach ausgeführt (wie `WM_COMMAND`), damit ein Handler das Formular gefahrlos schließen oder freigeben kann.
- Ein Klick neben das Menü schließt es und wird verbraucht (wie bei Windows).
- `OnDrawItem`/`OnAdvancedDrawItem` werden unter derselben Bedingung wie bei der VCL aufgerufen (`OwnerDraw` oder `Images` gesetzt).
- Felder der Suite (Edit, Memo, ComboBox, …) zeigen ohne eigenes `PopupMenu` ein übersetztes Bearbeiten-Menü in diesem Stil. `UseSystemContextMenu = True` stellt das Windows-Menü wieder her.
- Screenreader: Ereignisse `EVENT_SYSTEM_MENUPOPUPSTART/END`, Einträge als Kinder mit Rolle Menüeintrag.

## Beispiel

```pascal
PPGPopupMenu1.Preset := 'Fluent11';
Panel1.PopupMenu := PPGPopupMenu1;   // Rechtsklick oder Umschalt+F10
```
