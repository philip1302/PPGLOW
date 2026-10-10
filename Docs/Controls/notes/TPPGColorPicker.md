**Vorbild:** `TColorBox`, TMS TAdvColorPickerDropDown

## Wofür

Der ColorPicker lässt den Anwender eine Farbe wählen, z. B. für Kategorien, Markierungen in Listen oder Diagrammfarben. Das Feld zeigt Farbfeld und Namen; das Popup bietet Designfarben, Standardfarben, zuletzt benutzte Farben und ein HSV-Feld mit Hex-Eingabe. Er ersetzt `TColorBox` und den Windows-Farbdialog und folgt Preset und Dark Mode.

## Wann verwenden

- Wenn der Anwender eine einzelne Farbe einstellt, die gespeichert wird (Einstellungen, Kategorien, Hervorhebungen). Für die Wahl aus wenigen festen Bedeutungen („Rot = dringend“) ist eine `TPPGComboBox` oder `TPPGRadioGroup` mit Text klarer.
- Statt `TColorBox`: gleiche `Style`-Werte und `Selected`, aber mit Designfarben, zuletzt benutzten Farben und eigener Farbe ohne Windows-Dialog.
- Statt `TColorDialog`, wenn die Farbe direkt im Formular sichtbar bleiben soll und kein eigener Dialog aufgehen soll.
- In datengebundenen Formularen `TPPGDBColorPicker` nehmen; er speichert die Farbe als Ganzzahl im Datenfeld.

## Unterschiede und Hinweise

- Das Feld zeigt Farbfeld und Namen bzw. Hexwert (`ShowHex`).
- Das Popup hat diese Abschnitte (von oben nach unten):
  - „Keine“ und „Standard“ (`cbIncludeNone`, `cbIncludeDefault`)
  - Designfarben (Diagramm-Palette des Presets, `ShowThemeColors`)
  - Standardfarben und erweiterte Farben
  - Systemfarben
  - zuletzt benutzte Farben (`RecentColors`, im DFM gespeichert)
  - „Weitere Farben…“ (`cbCustomColor`)
- `Style` hat den Typ von `TColorBox.Style` (`cbStandardColors`, `cbExtendedColors`, `cbSystemColors`, `cbIncludeNone`, `cbIncludeDefault`, `cbCustomColor`, `cbPrettyNames`).
- „Weitere Farben…“ öffnet ein eigenes HSV-Feld (Fläche für Sättigung und Helligkeit, Farbton-Leiste) mit Hex-Eingabe, ohne Windows-`ChooseColor`. Es folgt deshalb Preset und Dark Mode.
- Tastatur:
  - Leertaste, Alt+Pfeil oder F4 öffnen.
  - Pfeile wandern im Raster.
  - Enter übernimmt, Esc verwirft.
  - Im HSV-Teil Hexwert tippen und mit Enter übernehmen.
- Farbnamen kommen aus der VCL („Red“) und sind nicht übersetzt; andere Farben erscheinen als `#RRGGBB`.
- Systemfarben bleiben in „zuletzt benutzt“ Systemfarben (sie folgen dem Windows-Design).
- `OnChange` und `OnClick` (wie `TColorBox`) feuern nur, wenn der Anwender eine andere Farbe wählt. `Selected` aus Code löst kein Ereignis aus; zum Auswählen wie durch den Anwender gibt es `SelectColor`.

## Beispiel

```pascal
PPGColorPicker1.Style := PPGColorPicker1.Style + [cbIncludeNone];
PPGColorPicker1.Selected := clNone;
```
