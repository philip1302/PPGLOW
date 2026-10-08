**Vorbild:** TListBox

## Unterschiede und Hinweise

- `ItemHeight` ist eine Mindesthöhe.
- Mehrfachauswahl: `ItemIndex := X` setzt nur den Fokus (wie `TListBox`), nicht die Auswahl.
- Quellen: `Items`, `ItemsEx` (reich: Bild, Detail, Gruppe, Plakette) oder virtuell (`Style = lbVirtual`, `Count` + `OnData`).
- UI Automation: Liste mit Auswahl-Muster, Einträge mit Position im Satz.

## Anpassung

- `Styles` (`Selection`, `SelectionInactive`, `AlternateRow`, `HotItem`, `GroupHeader`, `Detail`); je Eintrag `Color`, `TextColor`, `FontStyle`.
- `OnCustomDrawItem`: Stil eines Eintrags vor dem Zeichnen ändern oder mit `DefaultDraw := False` selbst zeichnen.

## Beispiel

```pascal
PPGListBox1.Style := lbVirtual;
PPGListBox1.Count := 1000000;   // Texte über OnData
```
