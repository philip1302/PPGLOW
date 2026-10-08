# TPPGKpiTile

Palette **PPGlow** - Unit `PPG.Gauge` - Basis `TPPGCustomKpiTile`

**Vorbild:** Dashboard-Kacheln (Power BI „Card“, TMS FNC Tile)

## Unterschiede und Hinweise

- Wert über `Value` + `ValueFormat` oder frei über `ValueText`; `Units` wird mit Leerzeichen angehängt.
- Trendpfeil und Farbe aus `Change`: steigend = Erfolg, fallend = Fehler; `InvertTrend` dreht das um (z. B. Fehlerquote).
- Eingebettete Sparkline über `SparklineText` bzw. `SetSparkline`; sie entfällt, wenn die Kachel zu niedrig ist.
- Klick, Leertaste und Enter lösen `OnClick` aus. Mit `OnClick` meldet sich die Kachel beim Screenreader als Schaltfläche.

## Beispiel

```pascal
PPGKpiTile1.Title := 'Retourenquote';
PPGKpiTile1.ValueText := FormatFloat('0.0', Quote) + ' %';
PPGKpiTile1.Change := Quote - QuoteVormonat;
PPGKpiTile1.InvertTrend := True;
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

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Title`, `TitleStyle`, `Value`, `ValueText`, `ValueStyle`, `ValueFormat`, `Units`, `Change`, `ChangeFormat`, `ShowChange`, `InvertTrend`, `SparklineKind`, `ShowSparkline`, `SparklineText`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `Hint`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnClick`, `OnEnter`, `OnExit`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGKpiTile.md`.
