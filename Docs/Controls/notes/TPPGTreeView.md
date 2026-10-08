**Vorbild:** TTreeView

## Unterschiede und Hinweise

- `ItemHeight` ist eine Mindesthöhe.
- `Selected := X` löst wie `TTreeView` `OnChange` aus (anders als die übrigen PPGlow-Controls).
- Lazy Loading über `HasChildren` + `OnExpanding`; nur der Pfeil dreht sich animiert.
- Knoten aus `TTreeView`-DFMs (binär) werden nicht gelesen; Knoten im Designer über „Edit nodes...“ anlegen.
- UI Automation: Hierarchie, Auf-/Zuklappen, Ebene und Position im Satz.

## Anpassung

- `Styles` wie die Listen; je Knoten `Color`, `TextColor`, `FontStyle` (zur Laufzeit).
- `OnCustomDrawNode`; wie `TTreeView`: `HotTrack` und `ToolTips` (abgeschnittene Knoten, braucht `ShowHint`).

## Beispiel

```pascal
N := PPGTreeView1.Items.AddChild(nil, 'Dokumente');
N.HasChildren := True;  // Kinder erst in OnExpanding
```
