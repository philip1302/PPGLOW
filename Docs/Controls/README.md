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

