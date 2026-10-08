# TPPGNumberEdit

Palette **PPGlow** - Unit `PPG.NumberEdit` - Basis `TPPGCustomNumberEdit`

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

## Verhalten (aus dem Quelltext)

TPPGNumberEdit - ein Feld fuer Ganzzahl, Kommazahl, Waehrung und Prozent
(Phase 12b; Vorbild TMS TAdvEdit EditType, WinUI NumberBox).

- Ohne Fokus zeigt das Feld formatiert ("1.234,50 EUR"), mit Fokus roh ("1234,5"). Gewechselt wird in FocusChanged (nie in Paint), die Einfuegemarke bleibt an derselben Ziffer.
- Eingabe: Ziffern, Trenner, Minus; mit AllowExpressions auch + - * / und Klammern ("2*19,99"), ausgerechnet bei Enter und beim Verlassen. Der Punkt des Ziffernblocks wird zum Dezimaltrenner des Gebietsschemas. Eingefuegtes "1.234,50 EUR" oder "1,234.50" wird erkannt (PPG.NumberFormat).
- Uebernommen wird bei Enter, beim Verlassen, mit Pfeilen, Spin-Buttons und Mausrad (nur mit Fokus). Ungueltige Eingabe: Enter zeigt den Fehler am Feld (ValidationState), Verlassen stellt den letzten gueltigen Wert wieder her. Esc verwirft die Eingabe.
- nkCurrency rechnet in Currency (AsCurrency, keine Rundungsfehler bei Geld).
- MinValue = MaxValue: keine Grenze (wie TSpinEdit); Werte werden still begrenzt.
- OnChange kommt nur, wenn der Anwender den Wert aendert (nicht bei jedem Tastendruck und nicht aus Code). Value aus Code loest nichts aus.
- AllowNull: leeres Feld = kein Wert (IsNull). IPPGFieldValue fuer DB-Felder und Grid.

## PPGlow-Eigenschaften

`RoundedCorners`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `NumberKind`, `Decimals`, `MinValue`, `MaxValue`, `Increment`, `LargeIncrement`, `ShowSpinButtons`, `ShowThousandSeparator`, `CurrencyString`, `AllowExpressions`, `AllowNull`, `Value`, `TextHint`, `TextHintVisibleOnFocus`, `UseSystemContextMenu`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Alignment`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ReadOnlyStyle`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnChange`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGNumberEdit.md`.
