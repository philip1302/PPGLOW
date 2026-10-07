**Vorbild:** `TColorBox`, TMS TAdvColorPickerDropDown

## Unterschiede und Hinweise

- Das Feld zeigt Farbfeld und Namen bzw. Hexwert (`ShowHex`).
- Das Popup hat diese Abschnitte:
  - Designfarben (Diagramm-Palette des Presets, `ShowThemeColors`)
  - Standardfarben und erweiterte Farben
  - Systemfarben
  - zuletzt benutzte Farben (`RecentColors`, im DFM gespeichert)
  - „Keine“ und „Standard“
- `Style` hat den Typ von `TColorBox.Style` (`cbStandardColors`, `cbExtendedColors`, `cbSystemColors`, `cbIncludeNone`, `cbIncludeDefault`, `cbCustomColor`, `cbPrettyNames`).
- „Weitere Farben…“ öffnet ein eigenes HSV-Feld (Fläche für Sättigung und Helligkeit, Farbton-Leiste) mit Hex-Eingabe, ohne Windows-`ChooseColor`. Es folgt deshalb Preset und Dark Mode.
- Tastatur:
  - Leertaste, Alt+Pfeil oder F4 öffnen.
  - Pfeile wandern im Raster.
  - Enter übernimmt, Esc verwirft.
  - Im HSV-Teil Hexwert tippen und mit Enter übernehmen.
- Farbnamen kommen aus der VCL („Red“) und sind nicht übersetzt; andere Farben erscheinen als `#RRGGBB`.
- Systemfarben bleiben in „zuletzt benutzt“ Systemfarben (sie folgen dem Windows-Design).

## Beispiel

```pascal
PPGColorPicker1.Style := PPGColorPicker1.Style + [cbIncludeNone];
PPGColorPicker1.Selected := clNone;
```
