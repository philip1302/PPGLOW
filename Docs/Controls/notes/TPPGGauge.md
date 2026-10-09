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
  Kind := grkError;
end;
PPGGauge1.Value := Auslastung;
```
