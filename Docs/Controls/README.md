# PPGlow - Hilfe pro Control

Erzeugt von `Build\make-docs.ps1` aus den Quelltexten und `Docs\Controls\notes`. HTML-Fassung: `Docs\Controls\html\index.html`.

## Palette PPGlow

| Control | Unit | Kurzbeschreibung |
|---|---|---|
| [TPPGButton](TPPGButton.md) | `PPG.Button` | Glow-Button mit Bild, ModalResult, Default/Cancel, Toggle-Gruppen (GroupIndex/Down), DropDownMenu und Action-Unterstuetzung. |
| [TPPGCheckBox](TPPGCheckBox.md) | `PPG.CheckBox` | Kontrollkaestchen mit optionalem dritten Zustand (AllowGrayed). |
| [TPPGRadioButton](TPPGRadioButton.md) | `PPG.RadioButton` | Optionsfeld. |
| [TPPGToggleSwitch](TPPGToggleSwitch.md) | `PPG.ToggleSwitch` | Ein/Aus-Schalter mit gleitendem Knopf (animiert ueber dieselbe Zustandslogik wie CheckBox/RadioButton). |
| [TPPGProgressBar](TPPGProgressBar.md) | `PPG.ProgressBar` | Fortschrittsbalken in der Optik des Presets. |
| [TPPGTrackBar](TPPGTrackBar.md) | `PPG.TrackBar` | Schieberegler mit Glow-Griff. |
| [TPPGPanel](TPPGPanel.md) | `PPG.Panel` | Container-Flaeche in der Optik des Presets (abgerundet, Rahmen, im Classic-Preset mit dezentem Verlauf). |
| [TPPGGroupBox](TPPGGroupBox.md) | `PPG.GroupBox` | Gruppierung mit Rahmen und Beschriftung. |
| [TPPGEdit](TPPGEdit.md) | `PPG.Edit` | einzeiliges Eingabefeld in der Optik des Presets. |
| [TPPGMemo](TPPGMemo.md) | `PPG.Memo` | mehrzeiliges Eingabefeld in der Optik des Presets. |
| [TPPGSpinEdit](TPPGSpinEdit.md) | `PPG.SpinEdit` | Zahlenfeld mit Auf-/Ab-Buttons in der Optik des Presets. |
| [TPPGComboBox](TPPGComboBox.md) | `PPG.ComboBox` | Auswahlfeld mit eigener Aufklappliste in der Optik des Presets. |
| [TPPGTabControl](TPPGTabControl.md) | `PPG.TabControl` | Reiter-Controls der Suite. |
| [TPPGPageControl](TPPGPageControl.md) | `PPG.PageControl` | TPPGPageControl + TPPGTabSheet - Seiten mit Reitern, DFM-kompatibel zu TPageControl/TTabSheet (ActivePage, TabPosition, TabWidth, TabHeight, HotTrack, Images... |
| [TPPGListBox](TPPGListBox.md) | `PPG.ListBox` | Liste im Stil der Suite, DFM-kompatibel zu TListBox. |
| [TPPGCheckListBox](TPPGCheckListBox.md) | `PPG.CheckListBox` | ListBox mit Kaestchen, DFM-kompatibel zu TCheckListBox. |
| [TPPGTreeView](TPPGTreeView.md) | `PPG.TreeView` | Baum im Stil der Suite (Phase 6b). |
| [TPPGGrid](TPPGGrid.md) | `PPG.Grid` | Tabelle im Stil der Suite (Phase 6c). |
| [TPPGLabel](TPPGLabel.md) | `PPG.Labels` | TPPGLabel und TPPGLinkLabel (Phase 7a). |
| [TPPGLinkLabel](TPPGLinkLabel.md) | `PPG.Labels` | TPPGLabel und TPPGLinkLabel (Phase 7a). |
| [TPPGBadge](TPPGBadge.md) | `PPG.Feedback` | Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar. |
| [TPPGProgressRing](TPPGProgressRing.md) | `PPG.Feedback` | Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar. |
| [TPPGInfoBar](TPPGInfoBar.md) | `PPG.Feedback` | Rueckmelde-Controls (Phase 7a): TPPGBadge, TPPGProgressRing, TPPGInfoBar. |
| [TPPGExpander](TPPGExpander.md) | `PPG.Expander` | Container mit Kopfzeile, auf- und zuklappbar (Phase 7a). |
| [TPPGSplitter](TPPGSplitter.md) | `PPG.Splitter` | Ziehgriff zwischen ausgerichteten Controls (Phase 7a). |
| [TPPGRating](TPPGRating.md) | `PPG.Rating` | Sternebewertung (Phase 7a). |
| [TPPGSearchEdit](TPPGSearchEdit.md) | `PPG.SearchEdit` | Suchfeld mit Vorschlagsliste (Phase 7a, wie WinUI AutoSuggestBox). |
| [TPPGCalendar](TPPGCalendar.md) | `PPG.Calendar` | Monatskalender mit Jahres- und Dekadenansicht (Phase 7b). |
| [TPPGDatePicker](TPPGDatePicker.md) | `PPG.DatePicker` | Datumsfeld mit Kalender-Popup (Phase 7b). |
| [TPPGTimePicker](TPPGTimePicker.md) | `PPG.TimePicker` | Uhrzeitfeld (Phase 7b). |
| [TPPGNavigationView](TPPGNavigationView.md) | `PPG.NavigationView` | Seitenleiste wie WinUI NavigationView (Phase 7c). |
| [TPPGBreadcrumb](TPPGBreadcrumb.md) | `PPG.Breadcrumb` | Pfadleiste aus Segmenten (Phase 7c, wie WinUI BreadcrumbBar). |
| [TPPGToolBar](TPPGToolBar.md) | `PPG.ToolBar` | Befehlsleiste (Phase 7c, wie WinUI CommandBar). |
| [TPPGStatusBar](TPPGStatusBar.md) | `PPG.StatusBar` | Statusleiste (Phase 7c). |
| [TPPGNotificationCenter](TPPGNotificationCenter.md) | `PPG.Notifications` | Benachrichtigungen ("Toasts") der Anwendung (Phase 7d). |
| [TPPGSparkline](TPPGSparkline.md) | `PPG.Sparkline` | kleiner Werteverlauf ohne Achsen (Phase 10b). |
| [TPPGGauge](TPPGGauge.md) | `PPG.Gauge` | Dashboard-Bausteine (Phase 10c): TPPGGauge und TPPGKpiTile. |
| [TPPGKpiTile](TPPGKpiTile.md) | `PPG.Gauge` | Dashboard-Bausteine (Phase 10c): TPPGGauge und TPPGKpiTile. |
| [TPPGChart](TPPGChart.md) | `PPG.Chart` | Diagramm im Stil der Suite (Phase 10d). |
| [TPPGPopupMenu](TPPGPopupMenu.md) | `PPG.Menus` | Menues im Stil der Suite (Phase 11b). |
| [TPPGMenuBar](TPPGMenuBar.md) | `PPG.MenuBar` | Hauptmenue als Control im Stil der Suite (Phase 11c). |
| [TPPGHintManager](TPPGHintManager.md) | `PPG.Hints` | Hints im Stil der Suite (Phase 11e). |
| [TPPGCustomHint](TPPGCustomHint.md) | `PPG.Hints` | Fuer die CustomHint-Property einzelner Controls (wie TBalloonHint). |
| [TPPGTeachingTip](TPPGTeachingTip.md) | `PPG.TeachingTip` | TeachingTip (Phase 11f): Sprechblase mit Pfeil, an ein Control geheftet (wie WinUI TeachingTip). |
| [TPPGTaskDialog](TPPGTaskDialog.md) | `PPG.Dialogs` | Dialoge im Stil der Suite (Phase 11g). |
| [TPPGWizard](TPPGWizard.md) | `PPG.Wizard` | TPPGWizard + TPPGWizardPage - Schritt-Assistent (Phase 11g). |
| [TPPGNumberEdit](TPPGNumberEdit.md) | `PPG.NumberEdit` | ein Feld fuer Ganzzahl, Kommazahl, Waehrung und Prozent (Phase 12b; Vorbild TMS TAdvEdit EditType, WinUI NumberBox). |
| [TPPGMaskEdit](TPPGMaskEdit.md) | `PPG.MaskEdit` | Eingabe mit Maske (Phase 12b, Vorbild TMaskEdit). |
| [TPPGPasswordEdit](TPPGPasswordEdit.md) | `PPG.PasswordEdit` | Kennwortfeld (Phase 12b, Vorbild WinUI PasswordBox). |
| [TPPGFileEdit](TPPGFileEdit.md) | `PPG.FileEdit` | Feld fuer eine Datei oder einen Ordner (Phase 12c). |
| [TPPGColorPicker](TPPGColorPicker.md) | `PPG.ColorPicker` | Farbauswahl mit Palette (Phase 12d). |
| [TPPGCheckComboBox](TPPGCheckComboBox.md) | `PPG.CheckComboBox` | Mehrfachauswahl im Aufklappfeld (Phase 12e, Vorbild TMS TCheckListEdit). |
| [TPPGColumnComboBox](TPPGColumnComboBox.md) | `PPG.ColumnComboBox` | mehrspaltige Auswahl mit Kopfzeile (Phase 12e, Vorbild TMS TAdvMultiColumnComboBox). |
| [TPPGTagEdit](TPPGTagEdit.md) | `PPG.TagEdit` | Stichwoerter als Chips (Phase 12f, Vorbild Outlook-Empfaenger, WinUI TokenizingTextBox). |
| [TPPGGridPrinter](TPPGGridPrinter.md) | `PPG.Grid.Print` | Drucken von Tabellen (Phase 13e). |
| [TPPGStyleManager](TPPGStyleManager.md) | `PPG.StyleManager` | Zentrales Theme fuer beliebig viele PPGlow-Controls (Observer-Muster). |

## Palette PPGlow DB

| Control | Unit | Kurzbeschreibung |
|---|---|---|
| [TPPGDBEdit](TPPGDBEdit.md) | `PPG.DB.Controls` | Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox, TPPGDBDatePicker. |
| [TPPGDBMemo](TPPGDBMemo.md) | `PPG.DB.Controls` | Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox, TPPGDBDatePicker. |
| [TPPGDBCheckBox](TPPGDBCheckBox.md) | `PPG.DB.Controls` | Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox, TPPGDBDatePicker. |
| [TPPGDBComboBox](TPPGDBComboBox.md) | `PPG.DB.Controls` | Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox, TPPGDBDatePicker. |
| [TPPGDBLookupComboBox](TPPGDBLookupComboBox.md) | `PPG.DB.Lookup` | Auswahl eines Schluessels aus einer zweiten Datenmenge (Phase 9c), wie TDBLookupComboBox. |
| [TPPGDBDatePicker](TPPGDBDatePicker.md) | `PPG.DB.Controls` | Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox, TPPGDBComboBox, TPPGDBDatePicker. |
| [TPPGDBGrid](TPPGDBGrid.md) | `PPG.DB.Grid` | Tabelle einer Datenmenge (Phase 9c), wie TDBGrid. |
| [TPPGDBChart](TPPGDBChart.md) | `PPG.DB.Chart` | Diagramm aus einer Datenmenge (Phase 10e, Paket PPGlowDBR). |
| [TPPGDBMaskEdit](TPPGDBMaskEdit.md) | `PPG.DB.Fields` | DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit. |
| [TPPGDBNumberEdit](TPPGDBNumberEdit.md) | `PPG.DB.Fields` | DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit. |
| [TPPGDBColorPicker](TPPGDBColorPicker.md) | `PPG.DB.Fields` | DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit. |
| [TPPGDBCheckComboBox](TPPGDBCheckComboBox.md) | `PPG.DB.Fields` | DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit. |
| [TPPGDBTagEdit](TPPGDBTagEdit.md) | `PPG.DB.Fields` | DB-Varianten der Eingabefelder aus Phase 12 (12g): TPPGDBMaskEdit, TPPGDBNumberEdit, TPPGDBColorPicker, TPPGDBCheckComboBox, TPPGDBTagEdit. |

