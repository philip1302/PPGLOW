# TPPGAppearance

Typ in Unit `PPG.Appearance` - Basis `TPersistent`

Aussehen eines Controls: je ein TPPGStateStyle für die Zustände Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Formen (Rounding, BorderWidth, GlowSize), die Fokusfarbe sowie eigene Farben im Fokus (Focused) und im Dark Mode (Dark). Ein Preset-Wechsel setzt alle Werte neu; danach geänderte Werte bleiben, bis das Preset wieder gewechselt wird.

Nutzung: `PPGButton1.Appearance.Hot.Color := $00FFE8CC; PPGButton1.Appearance.Hot.FontStyle := [fsUnderline];`

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Normal` | [TPPGStateStyle](TPPGStateStyle.md) |  | Aussehen im Ruhezustand. |
| `Hot` | [TPPGStateStyle](TPPGStateStyle.md) |  | Aussehen, solange die Maus über dem Control ist (weich überblendet, siehe Animation). |
| `Down` | [TPPGStateStyle](TPPGStateStyle.md) |  | Aussehen beim Drücken bzw. im eingerasteten Zustand (Down = True bei Toggle-Buttons). |
| `Disabled` | [TPPGStateStyle](TPPGStateStyle.md) |  | Aussehen bei Enabled = False. |
| `Checked` | [TPPGStateStyle](TPPGStateStyle.md) |  | „An"-Zustand von CheckBox, RadioButton und ToggleSwitch: Color* = Füllung des Kästchens bzw. Schalters, TextColor = Haken, Punkt bzw. Schalterknopf. |
| `FocusColor` | `TColor` |  | Farbe des Fokusrings bzw. der Fokuslinie bei Tastaturfokus. Mit einer Markenfarbe am StyleManager (AccentColor) meist nicht nötig. |
| `Rounding` | `Integer` |  | Eckenradius in logischen Pixeln (0 = eckig). Einzelne Ecken eckig über RoundedCorners. |
| `BorderWidth` | `Integer` |  | Randbreite in logischen Pixeln (0 = ohne Rand). |
| `GlowSize` | `Integer` |  | Breite des äußeren Glows (ModernFlat) in logischen Pixeln; um diesen Platz ist die Fläche kleiner als das Control. |
| `Focused` | [TPPGStateColors](TPPGStateColors.md) |  | Eigene Farben, solange das Control den Tastaturfokus hat; nur gesetzte Werte (≠ clDefault) gelten, der Rest kommt aus dem aktuellen Zustand. Nutzung: `Edit1.Appearance.Focused.Color := $00F2FBFF;` |
| `Dark` | [TPPGDarkColors](TPPGDarkColors.md) |  | Eigene Farben für den Dark Mode, je Zustand. Ohne Angabe gelten im Dunkeln die Farben des Presets (eigene helle Farben würden dort nicht passen). Nutzung: `PPGButton1.Appearance.Dark.Normal.Color := $00402810;` |

## Verwendet in

[TPPGBadge](../TPPGBadge.md), [TPPGBreadcrumb](../TPPGBreadcrumb.md), [TPPGButton](../TPPGButton.md), [TPPGCalendar](../TPPGCalendar.md), [TPPGChart](../TPPGChart.md), [TPPGCheckBox](../TPPGCheckBox.md), [TPPGCheckComboBox](../TPPGCheckComboBox.md), [TPPGCheckGroup](../TPPGCheckGroup.md), [TPPGCheckListBox](../TPPGCheckListBox.md), [TPPGColorPicker](../TPPGColorPicker.md), [TPPGColumnComboBox](../TPPGColumnComboBox.md), [TPPGComboBox](../TPPGComboBox.md), [TPPGDatePicker](../TPPGDatePicker.md), [TPPGDBChart](../TPPGDBChart.md), [TPPGDBCheckBox](../TPPGDBCheckBox.md), [TPPGDBCheckComboBox](../TPPGDBCheckComboBox.md), [TPPGDBColorPicker](../TPPGDBColorPicker.md), [TPPGDBComboBox](../TPPGDBComboBox.md), [TPPGDBDatePicker](../TPPGDBDatePicker.md), [TPPGDBEdit](../TPPGDBEdit.md), [TPPGDBGrid](../TPPGDBGrid.md), [TPPGDBKanban](../TPPGDBKanban.md), [TPPGDBLookupComboBox](../TPPGDBLookupComboBox.md), [TPPGDBMaskEdit](../TPPGDBMaskEdit.md), [TPPGDBMemo](../TPPGDBMemo.md), [TPPGDBNavigator](../TPPGDBNavigator.md), [TPPGDBNumberEdit](../TPPGDBNumberEdit.md), [TPPGDBPlanner](../TPPGDBPlanner.md), [TPPGDBRadioGroup](../TPPGDBRadioGroup.md), [TPPGDBTagEdit](../TPPGDBTagEdit.md), [TPPGEdit](../TPPGEdit.md), [TPPGExpander](../TPPGExpander.md), [TPPGFileEdit](../TPPGFileEdit.md), [TPPGGauge](../TPPGGauge.md), [TPPGGrid](../TPPGGrid.md), [TPPGGroupBox](../TPPGGroupBox.md), [TPPGInfoBar](../TPPGInfoBar.md), [TPPGKanban](../TPPGKanban.md), [TPPGKpiTile](../TPPGKpiTile.md), [TPPGLinkLabel](../TPPGLinkLabel.md), [TPPGListBox](../TPPGListBox.md), [TPPGMaskEdit](../TPPGMaskEdit.md), [TPPGMemo](../TPPGMemo.md), [TPPGMenuBar](../TPPGMenuBar.md), [TPPGNavigationView](../TPPGNavigationView.md), [TPPGNumberEdit](../TPPGNumberEdit.md), [TPPGPageControl](../TPPGPageControl.md), [TPPGPanel](../TPPGPanel.md), [TPPGPasswordEdit](../TPPGPasswordEdit.md), [TPPGPlanner](../TPPGPlanner.md), [TPPGProgressBar](../TPPGProgressBar.md), [TPPGProgressRing](../TPPGProgressRing.md), [TPPGRadioButton](../TPPGRadioButton.md), [TPPGRadioGroup](../TPPGRadioGroup.md), [TPPGRating](../TPPGRating.md), [TPPGRibbon](../TPPGRibbon.md), [TPPGScrollBox](../TPPGScrollBox.md), [TPPGSearchEdit](../TPPGSearchEdit.md), [TPPGSparkline](../TPPGSparkline.md), [TPPGSpinEdit](../TPPGSpinEdit.md), [TPPGSplitter](../TPPGSplitter.md), [TPPGStatusBar](../TPPGStatusBar.md), [TPPGStyleManager](../TPPGStyleManager.md), [TPPGTabControl](../TPPGTabControl.md), [TPPGTagEdit](../TPPGTagEdit.md), [TPPGTileView](../TPPGTileView.md), [TPPGTimePicker](../TPPGTimePicker.md), [TPPGToggleSwitch](../TPPGToggleSwitch.md), [TPPGToolBar](../TPPGToolBar.md), [TPPGTrackBar](../TPPGTrackBar.md), [TPPGTreeView](../TPPGTreeView.md), [TPPGWizard](../TPPGWizard.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
