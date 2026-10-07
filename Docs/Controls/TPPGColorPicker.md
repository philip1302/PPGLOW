# TPPGColorPicker

Palette **PPGlow** - Unit `PPG.ColorPicker` - Basis `TPPGCustomDropDownField`

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

## Verhalten (aus dem Quelltext)

TPPGColorPicker - Farbauswahl mit Palette (Phase 12d).

- Feld mit Farbfeld und Namen bzw. Hexwert; das Popup (TPPGColorPopup) nutzt die Aufklapp-Basis (PPG.Controls.DropDown) und PPG.Popup.Placement.
- Abschnitte: Designfarben (Akzent, Signalfarben, Diagramm-Palette des Presets), Standardfarben (16 + erweiterte), Systemfarben, zuletzt benutzt (RecentColors, im DFM gespeichert), "Keine"/"Standard".
- "Weitere Farben...": eigenes HSV-Feld (Saettigung/Helligkeit-Flaeche, Farbton-Leiste) mit Hex-Eingabe im Popup - kein Windows-ChooseColor, damit es dem Preset und dem Dark Mode folgt. Die Hex-Eingabe laeuft ueber die Tastatur des Felds (das Popup wird nie aktiviert).
- Style wie TColorBox.Style (TColorBoxStyle, cbStandardColors, ...), Selected: TColor, clNone/clDefault fuer "keine"/"Standard".
- Tastatur: Pfeile im Raster, Enter uebernimmt, Esc verwirft; im HSV-Teil Hex tippen, Enter uebernimmt. Screenreader: Farben als Kinder mit Namen.
- OnChange nur bei Auswahl durch den Anwender; Selected aus Code ohne.

## PPGlow-Eigenschaften

`Selected`, `Style`, `ShowThemeColors`, `RecentColors`, `MaxRecent`, `ShowHex`, `NoneColorColor`, `DefaultColorColor`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnChange`, `OnCloseUp`, `OnDropDown`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGColorPicker.md`.
