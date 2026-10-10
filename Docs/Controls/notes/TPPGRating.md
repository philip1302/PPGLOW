**Vorbild:** TMS Rating

## Wofür

Die Bewertung zeigt und erfasst einen Wert als Sterne: Zufriedenheit nach einem Support-Ticket, Einstufung eines Lieferanten, Durchschnitt aus vielen Produktbewertungen. Der Anwender klickt einen Stern, benutzt die Pfeiltasten oder tippt eine Ziffer. Mit `ReadOnly` und `AllowHalf` dient dasselbe Control als reine Anzeige mit halben Sternen.

## Wann verwenden

- Für subjektive Einstufungen auf einer kleinen, festen Skala (meist 1 bis 5), die man auf einen Blick lesen soll. Für genaue Zahlenwerte ist `TPPGSpinEdit` besser, für stufenlose Werte und Bereiche `TPPGTrackBar`.
- Statt einer `TPPGRadioGroup` mit „1" bis „5", wenn die Skala selbsterklärend ist. Haben die Stufen eigene Bedeutungen („Kritisch", „Hoch", „Normal"), sind benannte Optionen oder eine `TPPGComboBox` klarer.
- Als Anzeige (`ReadOnly = True`, `AllowHalf = True`) für Durchschnittswerte in Formularen und Karten. In einer Tabelle nimmt man statt vieler Controls die Zellart `ckRating` von `TPPGGrid`.

## Unterschiede und Hinweise

- `Value` im Code löst kein Ereignis aus; nur Klick und Tastatur melden `OnChange`. Nach dem Laden eines Werts die eigene Auswertung deshalb selbst aufrufen.
- `Value` wird sofort auf ganze bzw. mit `AllowHalf` auf halbe Sterne gerundet und auf 0..`Max` begrenzt. Nur beim Laden aus der DFM wird erst in `Loaded` gerundet, weil `AllowHalf` und `Max` dort erst später gelesen werden können.
- `AllowClear` (Vorgabe True): Ein Klick auf den aktuellen Wert setzt ihn auf 0. 0 bedeutet „nicht bewertet".
- Tastatur: Pfeiltasten ±1 (mit `AllowHalf` ±0,5), Pos1 = 0, Ende = `Max`, Ziffern setzen den Wert direkt. Das Mausrad ändert den Wert nicht.
- `ReadOnly` zeigt nur an, bleibt aber in voller Farbe und fokussierbar (Screenreader lesen „3,5 / 5"); `Enabled = False` graut die Sterne aus.

## Anpassung

- Größe über `StarSize` und `StarSpacing`; mit `AutoSize` folgt das Control der Sternzahl `Max`.
- `StarColor` für die gefüllten Sterne (Vorgabe: Akzentfarbe des Presets), leere Sterne aus `Appearance.Normal.BorderColor` mit mindestens 3:1 Kontrast zum Hintergrund.

## Beispiel

```pascal
rtgService.Max := 5;
rtgService.StarSize := 28;
rtgService.OnChange := ServiceRatingChange;   // nur bei Eingabe des Anwenders
rtgService.Value := Ticket.Rating;            // ohne OnChange
ShowVerdict(rtgService.Value);
```
