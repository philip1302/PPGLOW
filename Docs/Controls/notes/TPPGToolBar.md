**Vorbild:** TToolBar

## Wofür

Die ToolBar ist die Befehlsleiste über einer Liste, einem Editor oder einem Formular: Neu, Bearbeiten, Drucken, Filter. Die Befehle sind Einträge (`Items`), keine eigenen Controls: Buttons, Umschalt-Buttons (auch in Gruppen) und Trenner, mit Symbol aus der Symbolschrift oder einer Bildliste. Was nicht in die Breite passt, landet automatisch im „…“-Menü am Ende.

## Wann verwenden

- Für eine Reihe von Befehlen, die zu einem Inhalt gehören (Liste, Editor, Detailansicht). Für wenige, frei platzierte Befehle, z. B. OK/Abbrechen in Dialogen, ist `TPPGButton` passender.
- Statt `TPPGRibbon`, wenn die Befehle in eine Zeile passen. Ein Menüband mit Registerkarten, Gruppen und KeyTips lohnt sich erst bei sehr vielen Befehlen.
- Statt `TPPGMenuBar`, wenn die Befehle direkt sichtbar und mit einem Klick erreichbar sein sollen; die Menüleiste ordnet sie in aufklappenden Menüs.
- Für Ein/Aus-Zustände direkt am Befehl (Filter „Nur aktive“, Fett, Ansicht Liste/Kacheln) mit `Style = tisCheck`. Eine gespeicherte Einstellung in einem Formular ist mit `TPPGToggleSwitch` oder `TPPGCheckBox` klarer.
- Für Befehle mit Varianten (Exportieren als PDF/Excel) gibt es keine Dropdown-Einträge; dafür einen `TPPGButton` mit `Style = pbsSplitButton` neben die Leiste stellen.

## Unterschiede und Hinweise

- Einträge (`Items`) statt Kind-Buttons; daher kein automatischer Umstieg von `TToolBar`/`TToolButton`.
- Überlauf als Menü im Stil der Suite (`TPPGPopupMenu`, mit Haken für Umschalt-Buttons); Actions über `Items[].Action`.

## Anpassung

- Je Item `Color`, `TextColor`, `FontStyle`; `ImageTint` für einfarbige Symbole.
