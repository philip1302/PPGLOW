**Vorbild:** TListBox

## Unterschiede und Hinweise

- `ItemHeight` ist eine Mindesthöhe.
- Mehrfachauswahl: `ItemIndex := X` setzt nur den Fokus (wie `TListBox`), nicht die Auswahl.
- Quellen: `Items`, `ItemsEx` (reich: Bild, Detail, Gruppe, Plakette) oder virtuell (`Style = lbVirtual`, `Count` + `OnData`).
- UI Automation: Liste mit Auswahl-Muster, Einträge mit Position im Satz.

## Beispiel

```pascal
PPGListBox1.Style := lbVirtual;
PPGListBox1.Count := 1000000;   // Texte über OnData
```
