**Vorbild:** TScrollBox (DFM gleich: `AutoScroll`, `HorzScrollBar`, `VertScrollBar`, `BorderStyle`)

## Unterschiede und Hinweise

- Ein `TPPGPanel` mit `AutoScroll = True` und ohne Beschriftung; alles, was `TPPGPanel` kann (Preset, Rundung, Schatten), gilt auch hier.
- Leisten in PPGlow-Optik mit weichem Scrollen; das Mausrad wirkt auch über Kind-Controls, die es nicht selbst nutzen.
- Tab zu einem verdeckten Kind holt es ins Bild (`ScrollInView`), auch wenn es in einem Unter-Panel liegt.
- `BorderStyle = bsSingle` zeichnet den dünnen Rahmen des Presets statt des 3D-Rahmens der VCL.

## Beispiel

```pascal
PPGScrollBox1.VertScrollBar.Increment := 24;
PPGScrollBox1.ScrollInView(PPGEdit7);
```
