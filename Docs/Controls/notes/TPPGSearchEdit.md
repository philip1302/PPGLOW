**Vorbild:** TSearchBox (Vcl.WinXCtrls), WinUI AutoSuggestBox

## Wofür

Das Suchfeld findet Datensätze, während der Anwender tippt: Kunden, Artikel, Belege. Nach einer kurzen Tipp-Pause (`SearchDelay`) meldet es `OnSearch`, die Anwendung füllt die Vorschläge oder filtert eine Liste. Enter, die Lupe oder die Wahl eines Vorschlags melden `OnSubmit`, dort wird der Treffer übernommen.

## Wann verwenden

- Für die Suche nach einem Datensatz in großen Beständen, die erst beim Tippen abgefragt werden (Kunden, Artikel). Für eine Auswahl aus einer festen, kurzen Liste ist `TPPGComboBox` klarer.
- Als Filterfeld über einer Liste oder Tabelle: `OnSearch` filtert die Liste selbst, die Vorschlagsliste bleibt leer.
- Statt `TPPGEdit` mit eigenem Timer, wenn nach einer Tipp-Pause gesucht werden soll. Für normale Texteingaben ohne Suche bleibt `TPPGEdit` richtig.
- Für Stichwörter, von denen mehrere gleichzeitig gelten, ist `TPPGTagEdit` gedacht; das Suchfeld hält genau einen Suchbegriff.
- Für die Auswahl eines Datensatzes aus einer Datenmenge mit Schlüsselfeld ist `TPPGDBLookupComboBox` gedacht; das Suchfeld liefert nur den Text, die Zuordnung macht die Anwendung in `OnSubmit`.

## Unterschiede und Hinweise

- Baut auf der ComboBox auf: Vorschläge in `Items` oder `ItemsEx` (mit Detailzeile, Bild, Plakette), Verzögerung `SearchDelay` über den gemeinsamen Animator (kein Timer), danach `OnSearch`.
- Text im Code setzen löst weder `OnSearch` noch `OnSubmit` aus; `FlushSearch` führt eine wartende Suche sofort aus.
- Enter und Esc gehen nicht an Default- und Cancel-Buttons des Dialogs: Enter sendet die Suche ab, Esc schließt die Liste bzw. leert das Feld.
- `OnInvokeSearch` von `TSearchBox` (Enter oder Klick auf die Lupe) entspricht hier `OnSubmit`. Das Migrationsskript benennt es derzeit in `OnSearch` um; nach der Migration prüfen und den Handler bei Bedarf an `OnSubmit` hängen.
