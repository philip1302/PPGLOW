**Vorbild:** TMS TAdvEdit (`EditType`), WinUI NumberBox

## Unterschiede und Hinweise

- Ein Feld für Ganzzahl, Kommazahl, Währung und Prozent (`NumberKind`). Es ersetzt das früher geplante `TPPGFloatSpinEdit`; `TPPGSpinEdit` bleibt für die Kompatibilität mit `TSpinEdit`.
- Ohne Fokus zeigt es das Anzeigeformat (`1.234,50 €`), mit Fokus das Bearbeitungsformat (`1234,5`). Die Einfügemarke bleibt dabei an derselben Ziffer.
- Eingabe:
  - Erlaubt sind Ziffern, Trenner und Minus. Mit `AllowExpressions` darf man auch rechnen (`2*19,99`, Klammern, Punkt vor Strich).
  - Der Punkt des Ziffernblocks wird zum Dezimaltrenner des Gebietsschemas.
  - Eingefügtes `1.234,50 €`, `1,234.50`, `CHF 1'234.50` oder `(12,50)` wird erkannt.
- Übernommen wird bei Enter, beim Verlassen, mit Pfeil/Bild auf/ab, Spin-Buttons und dem Mausrad (nur mit Fokus).
  - Ungültige Eingabe bei Enter: Fehler am Feld.
  - Ungültige Eingabe beim Verlassen: Der letzte gültige Wert kommt zurück.
  - Esc verwirft die Eingabe.
- `nkCurrency` rechnet in `Currency` (`AsCurrency`) und rundet kaufmännisch: 2,345 → 2,35. `Round` der RTL würde dagegen zur geraden Ziffer runden.
- `MinValue = MaxValue` bedeutet ohne Grenze (wie `TSpinEdit`); Werte werden still begrenzt.
- `OnChange` kommt nur, wenn der Anwender den Wert ändert, also nicht je Tastendruck und nicht aus Code.
- `AllowNull`: Ein leeres Feld bedeutet „kein Wert“ (`IsNull`). In `TPPGDBNumberEdit` ist das die Vorgabe.
- Prozent: `Value` ist die angezeigte Zahl (12,5 für 12,5 %), nicht der Anteil (0,125).

## Beispiel

```pascal
PPGNumberEdit1.NumberKind := nkCurrency;
PPGNumberEdit1.MinValue := 0;
PPGNumberEdit1.MaxValue := 100000;
PPGNumberEdit1.AsCurrency := 19.99;
```
