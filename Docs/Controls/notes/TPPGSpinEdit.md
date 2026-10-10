**Vorbild:** TSpinEdit (Vcl.Samples.Spin)

## Wofür

Das Zahlenfeld nimmt eine ganze Zahl auf: Menge, Anzahl, Minuten, Prozent. Pfeile im Feld, Pfeiltasten, Bild auf/ab und das Mausrad ändern den Wert um `Increment`; `Min` und `Max` begrenzen ihn still. Es ersetzt `TSpinEdit` in der Optik des Presets.

## Wann verwenden

- Für kleine ganze Zahlen, die man oft nur um wenige Schritte ändert (Menge, Anzahl Kopien, Intervall in Minuten). Für Beträge, Nachkommastellen, Prozente mit Format oder Rechenausdrücke ist `TPPGNumberEdit` richtig.
- Statt `TPPGTrackBar`, wenn der genaue Wert zählt und eingetippt werden soll. Der Regler passt besser, wenn die ungefähre Lage im Bereich wichtiger ist (Lautstärke, Zoom).
- Statt `TPPGComboBox`, wenn die Werte eine gleichmäßige Reihe bilden (0, 5, 10 …). Feste, unregelmäßige Werte oder Werte mit Text („klein, mittel, groß“) gehören in eine Auswahlliste.
- Statt `TPPGEdit` mit eigener Prüfung, sobald nur ganze Zahlen erlaubt sind: Das Feld filtert die Tasten und liefert `Value` direkt als Integer.

## Unterschiede und Hinweise

- Die Grenzen heißen `Min` und `Max` (bei `TSpinEdit`: `MinValue` und `MaxValue`). Beim Umstellen einer DFM beide Namen mit ersetzen.
- `Min = Max` bedeutet wie bei `TSpinEdit` „keine Grenze“.
- `Min > Max` wirft **nicht** (wie `TSpinEdit`), sonst scheitert `Min := 10; Max := 100`.
- Ungültige Eingaben werden beim Verlassen und mit Enter auf den gültigen Wert gesetzt; `Value` ist auch während des Tippens schon begrenzt.
- `ReadOnly` sperrt auch die Pfeile; `EditorEnabled = False` sperrt nur das Tippen.
- Wiederholung beim Halten der Buttons über den Animator (400 ms, dann alle 50 ms).
