**Vorbild:** TDBNavigator (DFM gleich: `DataSource`, `VisibleButtons`, `Hints`, `ConfirmDelete`, `Flat`, `BeforeAction`, `OnClick`)

## Unterschiede und Hinweise

- `ShowCounter` (Vorgabe an): „Datensatz 12 von 340“ bzw. „neu“; Screenreader lesen den Zähler mit.
- `ShowSearch`: Suchfeld im Navigator, Enter springt zum nächsten Treffer (Teiltreffer in `SearchField`, leer = alle Textfelder). `FindText` macht dasselbe im Code.
- `ShowFilter`: Schnellfilter auf den Suchbegriff mit Knopf zum Aufheben; ein eigenes `OnFilterRecord` der Datenmenge bleibt wirksam. Im Code `SetQuickFilter`.
- Passt nicht alles in die Breite, wandern Knöpfe in ein Überlaufmenü statt zu schrumpfen.
- Tastatur: Strg+Pos1/Ende springen an Anfang/Ende, Einfg legt an, Strg+Entf löscht.
- Nur waagerecht; `Kind` der VCL entfällt (die Migration entfernt es). `nbApplyUpdates`/`nbCancelUpdates` nutzen die Datenmengen-Schnittstelle der VCL und sind unter XE2 nicht verfügbar.
- Liegt in der Unit `PPG.DB.Navigator` (Paket PPGlowDBR).

## Beispiel

```pascal
PPGDBNavigator1.ShowSearch := True;
PPGDBNavigator1.ShowFilter := True;
PPGDBNavigator1.SearchField := 'NAME';
```
