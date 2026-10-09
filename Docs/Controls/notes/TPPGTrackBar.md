**Vorbild:** TTrackBar

## Unterschiede und Hinweise

- `Position` wird still begrenzt; `Min > Max` wirft.
- Auswahlbereich wie `TTrackBar`: `SelStart`/`SelEnd` (mit `SelEnd` > `SelStart`) markieren einen Bereich auf der Schiene, `ShowSelRange` blendet ihn aus.
- **Bereichsregler:** `RangeMode` zeigt zwei Griffe, `Position` ist der Anfang, `PositionEnd` das Ende; sie überholen sich nicht (setzt der Code den Anfang hinter das Ende, wandert das Ende mit). Klick auf die Schiene bewegt den näheren Griff, Tab wechselt den Griff (`ActiveThumb`), danach verlässt Tab das Control. Screenreader: zwei Kinder „Von“/„Bis“.
- Noch nicht vorhanden: manuelle Ticks (`SetTick`) und `PositionToolTip`.
