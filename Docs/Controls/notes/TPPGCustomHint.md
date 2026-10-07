**Vorbild:** `TBalloonHint` der VCL

## Unterschiede und Hinweise

- Für die Property `CustomHint` einzelner Controls: Titel und Beschreibung kommen wie bei `TBalloonHint` aus dem Hint-Text des Controls (`"Titel|Beschreibung"`), das Bild aus `Images`/`ImageIndex`.
- Zeichnet wie der Hint-Manager (Preset, Dark Mode, Hochkontrast, DPI des Monitors), aber ohne Ballonform: `Style` ist standardmäßig `bhsStandard`.
- Ein- und Ausblenden übernimmt die VCL (`TCustomHint` mit eigenem Thread); `Delay` und `HideAfter` wirken wie gewohnt.
- `MaxWidth` begrenzt die Breite in logischen Pixeln (80–2000).

## Beispiel

```pascal
Edit1.CustomHint := PPGCustomHint1;
Edit1.Hint := 'Kundennummer|Sieben Ziffern, z. B. 1004711.';
Edit1.ShowHint := True;
```
