# TPPGGauge

Palette **PPGlow** - Unit `PPG.Gauge` - Basis `TPPGCustomGauge`

**Vorbild:** TMS FNC Widget Gauge, WinUI RadialGauge

## Unterschiede und Hinweise

- `Min`/`Max`/`Value` sind `Double`. `Min >= Max` wirft zur Laufzeit; beim Laden aus dem DFM wird `Max` korrigiert. `Value` wird still auf den Bereich begrenzt.
- `StartAngle`/`SweepAngle` in Grad, 0 = oben, im Uhrzeigersinn (Vorgabe 270°, halbrund: -90/180).
- `Ranges` färbt die Spur; mit `ValueColorFromRange` nimmt der Wertbogen die Farbe seines Abschnitts an.
- Wertwechsel gleiten über den gemeinsamen Animator; ein Abschalten von `Animation` beendet einen laufenden Wechsel sofort.
- `ReadOnly = True` (Vorgabe): Anzeige ohne Tabstopp. Sonst Schieberegler (Ziehen, Pfeile, Bild, Pos1/Ende); `OnChange` nur bei Anwender-Änderungen.

## Beispiel

```pascal
PPGGauge1.Ranges.Add.EndValue := 60;          // grün (grcSuccess)
with PPGGauge1.Ranges.Add do
begin
  StartValue := 85;
  EndValue := 100;
  RangeColor := grcDanger;
end;
PPGGauge1.Value := Auslastung;
```

## Verhalten (aus dem Quelltext)

Dashboard-Bausteine (Phase 10c): TPPGGauge und TPPGKpiTile.

TPPGGauge - Bogenanzeige fuer einen Wert:
- Min/Max/Value (Double), Bogen ueber StartAngle/SweepAngle (0 Grad = oben, im Uhrzeigersinn; Vorgabe 270 Grad, halbrund = -90/180).
- Ranges: farbige Abschnitte der Spur (Signalfarben aus den Tokens). Mit ValueColorFromRange nimmt der Wertbogen die Farbe seines Abschnitts an.
- Zielmarke (ShowTarget/TargetValue), Werttext mit ValueFormat und Units, Beschriftung (Caption) darunter.
- Wertwechsel gleitet ueber den gemeinsamen Animator (ekDecelerate), der Text zaehlt dabei mit. Code setzt Werte ohne OnChange.
- ReadOnly (Vorgabe): reine Anzeige ohne Fokus. Sonst Schieberegler: Ziehen auf dem Bogen, Pfeile/Bild/Pos1/Ende; OnChange nur bei Anwender- Aenderungen.
- Screenreader: Rolle Fortschritt (ReadOnly) bzw. Schieberegler.

TPPGKpiTile - Kennzahl-Kachel:
- Title, Wert (Value/ValueFormat oder freier ValueText) mit Units, Veraenderung (Change/ChangeFormat) mit Trendpfeil: gruen = gut, rot = schlecht (InvertTrend: weniger ist besser).
- Eingebettete Sparkline (SparklineText/SetSparkline) ueber PPGDrawSparkline.
- Flaeche wie ein Container (IPPGContainerRenderer), Hover; Klick, Enter und Leertaste loesen OnClick aus.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Min`, `Max`, `Value`, `StartAngle`, `SweepAngle`, `Thickness`, `Ranges`, `ValueColorFromRange`, `ShowTarget`, `TargetValue`, `ShowValue`, `ValueFormat`, `Units`, `ValueColor`, `ReadOnly`, `Increment`, `Caption`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `Hint`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnClick`, `OnEnter`, `OnExit`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGGauge.md`.
