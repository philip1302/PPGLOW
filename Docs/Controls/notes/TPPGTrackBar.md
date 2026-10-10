**Vorbild:** TTrackBar

## Wofür

Der Schieberegler wählt einen Zahlenwert aus einem festen Bereich, wenn die ungefähre Lage wichtiger ist als die exakte Zahl: Zoom, Lautstärke, Intervall, Schwellwert. Er ersetzt `TTrackBar` mit gleichen Eigenschaftsnamen, zeigt auf Wunsch einen empfohlenen Bereich (`SelStart`/`SelEnd`) und wird mit `RangeMode` zum Bereichsregler „von – bis“ mit zwei Griffen.

## Wann verwenden

- Für Werte, die man durch Ausprobieren einstellt und deren Wirkung sofort sichtbar ist (Zoom, Helligkeit). Muss ein exakter Wert eingetippt werden (Menge, Betrag), ist `TPPGNumberEdit` oder `TPPGSpinEdit` klarer; beides lässt sich auch kombinieren.
- Für einen Bereich „von – bis“ (Preisfilter, Zeitraum) mit `RangeMode` statt zweier getrennter Regler oder Felder.
- Nicht für Fortschritt oder reine Anzeigen: Dafür sind `TPPGProgressBar` bzw. `TPPGGauge` da (`ShowSlider = False` nur als Ausnahme).
- Für wenige benannte Stufen (Klein/Mittel/Groß) ist eine `TPPGRadioGroup` (auch als Segment) verständlicher als Zahlenstufen.

## Unterschiede und Hinweise

- `Position` wird still begrenzt; `Min > Max` wirft.
- Auswahlbereich wie `TTrackBar`: `SelStart`/`SelEnd` (mit `SelEnd` > `SelStart`) markieren einen Bereich auf der Schiene, `ShowSelRange` blendet ihn aus.
- **Bereichsregler:** `RangeMode` zeigt zwei Griffe, `Position` ist der Anfang, `PositionEnd` das Ende; sie überholen sich nicht (setzt der Code den Anfang hinter das Ende, wandert das Ende mit). Klick auf die Schiene bewegt den näheren Griff, Tab wechselt den Griff (`ActiveThumb`), danach verlässt Tab das Control. Screenreader: zwei Kinder „Von“/„Bis“.
- Noch nicht vorhanden: manuelle Ticks (`SetTick`) und `PositionToolTip`.
