# PPGlow – Anforderungen an Anpassbarkeit und Praxistauglichkeit

*Stand: 07.10.2026, Umsetzungsstand in Abschnitt 3 und 4 aktualisiert am 08.10.2026. Grundlage: Quelltexte aller Paletten-Controls (`Source\Controls`, `Source\DB`), die erzeugte Hilfe `Docs\Controls\*.md` und Vergleiche mit VCL, TMS VCL UI Pack, DevExpress VCL und WinUI.*

## 1. Ziel und Methode

Frage des Users: Haben die PPGlow-Komponenten einen echten Mehrwert gegenüber den Standard-Komponenten? Kann man überall Farben, Stile und Schriften anpassen? Was fehlt noch für den Praxiseinsatz?

Vorgehen:
1. Die Anforderungen stammen aus drei Quellen:
   - **VCL-Standard:** Das ist die Mindestmenge. Jede Property eines VCL-Pendants muss es geben, sonst lassen sich DFMs nicht laden.
   - **Kommerzielle Suiten:**
     - TMS: `TAdvGlowButton` mit Farben je Zustand (`BorderColorHot`, `ColorMirrorHot` usw.); `TAdvStringGrid` mit `SelectionColor`, `ActiveCellColor`/`ActiveCellFont` und `Bands.PrimaryColor`/`SecondaryColor`.
     - DevExpress: Stil-Objekte je Bereich (`Content`, `ContentEven`/`ContentOdd`, `Header`, `Selection`, `Inactive`), auch je Zeile oder Spalte überschreibbar.
   - **WinUI:** „Lightweight Styling“, also eine Farbe pro Element und Zustand, getrennt für Hell und Dunkel.
2. Die veröffentlichten Properties und Ereignisse aller rund 75 Paletten-Komponenten wurden aus der Hilfe gezogen und gezielt im Quelltext geprüft:
   - woher Grid, Liste und Planer ihre Farben nehmen
   - welche Zeichen-Ereignisse es gibt
   - welche Eigenschaften die Elemente haben (Items, Spalten, Knoten)
3. Bewertung: ✔ erfüllt · ◐ teilweise · ✘ fehlt. Priorität: **M** = Muss (praxisnah, erwartet), **S** = Soll (Suiten-Niveau), **K** = Kann.

## 2. Kurzantwort

| Bereich | Ergebnis |
|---|---|
| Einfache Controls (Button, CheckBox, Felder, Panel, ProgressBar …) | **Deutlicher Mehrwert.** Pro Zustand einstellbar: Farbe, Verlauf mit Spiegelung, Rand, Glow und Textfarbe (Normal/Hot/Down/Disabled/Checked). Dazu Rundung, Randbreite, Fokusfarbe, Animation, drei Presets, Dark Mode, Hochkontrast, VCL-Styles, zentraler `TPPGStyleManager`, DPI, RTL und Screenreader. Das kann die VCL nicht. |
| Komplexe Controls (Grid, Baum, Listen, Kalender, Planer, Kanban, Ribbon, Reiter, Navigation) | **Lücke.** Sie haben nur eine `Appearance`, `Color` und **eine** `Font`. Kopf, Auswahl, inaktive Auswahl, Gitterlinien, Zebra-Zeilen, Fußzeile und Gruppenzeilen werden daraus **berechnet** und lassen sich nicht einzeln einstellen. Eigene Schriften für einzelne Bereiche gibt es nirgends. Im Grid ist das schwächer als bei `TStringGrid` (`FixedColor`, `GradientStartColor`, `DrawingStyle`) und deutlich schwächer als bei TMS und DevExpress. |
| Theme/Marke | **Lücke.** Eine eigene Akzent- oder Markenfarbe gibt es nicht als Property. Die Tokens (Akzent, Flächen, Signalfarben) kommen fest aus dem Preset. Selbst gesetzte Farben gelten im Dark Mode nicht, und eine Dunkel-Variante lässt sich nicht hinterlegen. |
| Grundausstattung (Margins, Hint, Actions, DB, Übersetzung, DPI) | **Erfüllt.** `AlignWithMargins`, `Margins` und `CustomHint` erben alle Controls von `TControl`. |

## 2a. Umsetzung (08.10.2026)

Alle in Abschnitt 3 als fehlend oder teilweise erfüllt markierten Punkte sind umgesetzt (Spalte „Stand“ zeigt den neuen Stand, die alte Bewertung steht in der Git-Historie). Die drei Bausteine aus Abschnitt 5 sind gebaut:

- **Element-Stile:** `TPPGElementStyle` und Gruppen (`PPG.ElementStyle`): `Color`, `TextColor`, `BorderColor`, Dunkel-Varianten, `ParentFont`/`Font`, `FontStyle`; `clDefault` = vom Preset. Mit Element-Stilen ausgestattet sind Grid, DB-Grid, Listen, TreeView, Combo-Liste, Reiter, NavigationView, Menüs, Kalender, Planer, Kanban, Chart und die kleinen Controls.
- **Theme-Tokens:** `TPPGStyleManager.AccentColor`, `ThemeColors.Light/Dark`, `ChartPalette`, Theme-Datei (`PPG.ThemeFile`).
- **Zeichen-Ereignisse:** `PPG.CustomDraw` (`TPPGDrawStyle`, `DefaultDraw`), in allen genannten Controls gleich aufgebaut.

Farben aus Stilen gelten nicht im Hochkontrast und nicht mit VCL-Style; Schriften gelten immer. Tests: `Tests\PPG.Tests.Custom.pas` (Suite „Anpassbarkeit“).

## 3. Anforderungsliste mit Erfüllungsgrad

### A. Zentrales Theme und Marke

| ID | Anforderung | Prio | Stand | Befund |
|---|---|---|---|---|
| A1 | Zentrale Stilquelle für alle Controls eines Formulars oder der Anwendung | M | ✔ | `TPPGStyleManager` mit `Preset`, `Appearance`, `Animation`, `ThemeMode`, `StyleForms` |
| A2 | Mehrere Designs, zur Laufzeit umschaltbar | M | ✔ | Classic, ModernFlat, Fluent11; eigene Renderer über `TPPGRendererRegistry.RegisterRenderer` |
| A3 | **Eigene Akzent- oder Markenfarbe** an einer Stelle, die auf alle abgeleiteten Farben wirkt (Fokus, Auswahl, Fortschritt, Schalter, Links, Diagramme) | M | ✔ | Umgesetzt: `TPPGStyleManager.AccentColor`. Die Akzent-Tokens (Fokus, Auswahl, Fortschritt, Schalter, Links) aller Presets werden daraus abgeleitet, mit Kontrastprüfung. |
| A4 | Einzelne Tokens überschreiben (Flächen, Text, Signalfarben Danger/Warning/Success, Radien) | S | ✔ | Umgesetzt: `ThemeColors.Light`/`.Dark` am StyleManager (Flächen, Text, Rand, Danger/Warning/Success …); nur gesetzte Werte überschreiben. Radien über `Appearance.Rounding`. |
| A5 | Dark Mode | M | ✔ | `ThemeMode` Hell/Dunkel/System, dunkle Titelleiste |
| A6 | **Eigene Farben auch im Dark Mode**, also eine Dunkel-Variante der Appearance | S | ✔ | Umgesetzt: `Appearance.Dark` (eigene Zustandsfarben im Dunkeln) und `ThemeColors.Dark` |
| A7 | Hochkontrast und VCL-Styles beachten | M | ✔ | `HighContrastSupport`, `StyleElements`; Rangfolge Hochkontrast > VCL-Style > Dark > Appearance |
| A8 | Theme als Datei speichern und laden (Firmen-Design weitergeben) | S | ✔ | Umgesetzt: `TPPGStyleManager.SaveToFile`/`LoadFromFile`/`…Stream` (INI `[PPGlowTheme]`); eine fehlerhafte Datei lässt den Manager unverändert |
| A9 | Design-Zeit-Editor für Stile | S | ✔ | Appearance-Editor und Preset-Galerie (Phase 9) |

### B. Erscheinungsbild einfacher Controls

| ID | Anforderung | Prio | Stand | Befund |
|---|---|---|---|---|
| B1 | Farben je Zustand (Normal, Hover, Gedrückt, Deaktiviert, Eingerastet) | M | ✔ | `TPPGStateStyle`: `Color`, `ColorTo`, `ColorMirror(To)`, `BorderColor`, `GlowColor`, `GlowAlpha`, `TextColor`, `GradientDirection` |
| B2 | Eigener Zustand **Fokussiert** (Fläche, Rand, Text), nicht nur eine Fokusfarbe | S | ✔ | Umgesetzt: `Appearance.Focused` (Fläche, Rand, Text; nur gesetzte Werte gelten) |
| B3 | Rundung, Randbreite, Glow-Größe | M | ✔ | `Rounding`, `BorderWidth`, `GlowSize` |
| B4 | Rundung je Ecke (z. B. Button-Gruppen, Segment-Buttons) | K | ✔ | Umgesetzt: `RoundedCorners` (Button, Panel, Edit, NumberEdit, SpinEdit, ComboBox); beide Zeichenwege (GDI+, GDI) |
| B5 | Schatten oder Elevation | K | ✔ | Umgesetzt: `Shadow` (Größe, Versatz, Farbe, Deckkraft) bei Button und Panel; im Hochkontrast aus |
| B6 | **Schriftstil je Zustand** (z. B. fett bei Hover oder eingerastet, unterstrichen bei Hover) | S | ✔ | Umgesetzt: `FontStyle` je Zustand (`Appearance.Hot.FontStyle` …), auch bei CheckBox/RadioButton |
| B7 | Text- und Bildlage im Button: Ausrichtung, Innenabstand (`Margin`) | S | ✔ | Umgesetzt: `Alignment` und `Margin` (wie `TBitBtn`) |
| B8 | Bilder je Zustand | M | ✔ | Umgesetzt: `PressedImageIndex`, `HotImageName`/`DisabledImageName`/`PressedImageName` (ab 10.4), `ImageTint = itTextColor` (Button, ToolBar, NavigationView) |
| B9 | Schrift über `Font`/`ParentFont` | M | ✔ | Bei allen Text-Controls (nicht bei Rating, ProgressRing, Sparkline; dort gibt es keinen Text) |
| B10 | Signalfarben einstellbar (InfoBar-Schwere, Badge, Validierung, Toast) | S | ✔ | Signalfarben über `ThemeColors` (Danger/Warning/Success), dazu `InfoBar.Style`, `TPPGBadge.Severity` |

### C. Komplexe Controls: Bereiche einzeln gestalten

Das ist der wichtigste Teil, weil Suiten sich vor allem hier von der VCL abheben. Beispiel Grid: `GetGridColors` (`PPG.Grid.pas:3645`) nimmt `Fill` und `Text` aus `Color`/`Font.Color`. Daraus werden berechnet: Kopf = 5 % Mischung, Linien = 13 % Mischung, Akzent = `Appearance.FocusColor`. Einzeln setzen kann man davon nichts.

| ID | Anforderung | Prio | Stand | Befund |
|---|---|---|---|---|
| C1 | **Kopf- bzw. Fixed-Bereich:** Farbe und Textfarbe | M | ✔ | Umgesetzt: Grid/DB-Grid `Styles.Header` (+ `FixedColor` als Alias), `Styles`, `Styles.Column`, `Styles` |
| C2 | **Auswahl:** Farbe, Textfarbe, eigene Farbe bei Fokus-Verlust („inaktiv“) | M | ✔ | Umgesetzt: `Styles.Selection`/`SelectionInactive` (Grid, ListBox, CheckListBox, TreeView, Combo-Liste) |
| C3 | **Zebra-Zeilen** (abwechselnde Zeilenfarbe) | M | ✔ | Umgesetzt: `Styles.AlternateRow` (Grid, Listen, Combo-Liste) |
| C4 | Hover-Zeile hervorheben, Farbe einstellbar | S | ✔ | Umgesetzt: `Styles.HotRow` (Grid), `Styles.HotItem` (Listen), `HotTrack` im TreeView |
| C5 | Gitterlinien: Farbe, Breite, ein/aus | S | ✔ | Umgesetzt: `Styles.GridLine` und `GridLineWidth` (0..10) |
| C6 | **Schrift je Bereich:** Kopf, Fußzeile, Gruppenzeile, Titel, Detailtext | M | ✔ | Umgesetzt: Element-Stile mit eigener Schrift (Grid-Kopf, -Fuß, -Gruppenzeile, `TitleFont` im DB-Grid, Chart `TitleFont`/`LegendFont`, `Expander.HeaderStyle`, `GroupBox.CaptionStyle`, KPI `ValueStyle`/`TitleStyle`, `Gauge.ValueStyle`, Kalender, Planer, Kanban) |
| C7 | **Spalte:** Farbe, Schrift, Kopf-Ausrichtung | M | ✔ | Umgesetzt: Spalte `Style`, `TitleStyle`, `TitleAlignment` |
| C8 | Stil je Zelle per Ereignis | M | ✔ | `OnGetCellStyle` (Grid, DB-Grid), jetzt auch mit `FontStyle`, `FontName`, `FontSize` |
| C9 | Bedingte Formatierung ohne Code | S | ✔ | `ConditionalFormats` (Grid, DB-Grid) |
| C10 | **Eigenes Zeichnen** (Owner-/Custom-Draw) | M | ✔ | Umgesetzt: einheitliches `OnCustomDrawItem` (ListBox, CheckListBox, Combo-Liste, Menüs, MenuBar, NavigationView), `OnCustomDrawNode` (TreeView), `OnDrawTab`/`OwnerDraw` (Tab-/PageControl), `OnCustomDrawDay` (Kalender, DatePicker), `OnCustomDrawCard` (Kanban), `OnCustomDrawAppointment` (Planer) |
| C11 | Kalender: Tage hervorheben (fett, Farbe, Markierung), z. B. Feiertage | S | ✔ | Umgesetzt: `OnCustomDrawDay` und `Styles` (Wochenende, Heute, Auswahl …) |
| C12 | **Farbe/Stil je Element** (Item, Knoten, Reiter, Navigationseintrag, Statusfeld) | S | ✔ | Umgesetzt: `Color`/`TextColor`/`FontStyle` bei `TPPGItem`, TreeView-Knoten (Laufzeit), TabSheet (`TabColor` …), `TPPGNavItem`, `TPPGStatusPanel`, `TPPGToolItem` |
| C13 | Planer: Kategorien mit Name und Farbe (wie Outlook) | S | ✔ | Umgesetzt: `Categories` (Name, Farbe) im Planer und DB-Planer |
| C14 | Diagramm: eigene Farbpalette, Schrift für Titel, Achsen und Legende | S | ✔ | Umgesetzt: `ChartPalette` am StyleManager, `Styles` (Titel, Achse, Gitter, Legende), `TitleFont`, `LegendFont` |

### D. Grundausstattung und Praxis

| ID | Anforderung | Prio | Stand | Befund |
|---|---|---|---|---|
| D1 | DFM-kompatibel zum VCL-Pendant | M | ✔ | Ergänzt: Grid `FixedColor`, `GridLineWidth`, `DrawingStyle`, `GradientStartColor`/`EndColor`; Tab-/PageControl `MultiLine`, `RaggedRight`, `ScrollOpposite`, `Style`, `OwnerDraw`, `OnDrawTab`; TreeView `HotTrack`, `ToolTips`. `migrate.ps1` überträgt DB-Grid-Spalten (`Title.Alignment`, `Title.Font`, `Title.Color`, `Font`, `Color`). |
| D2 | `AlignWithMargins`, `Margins`, `Hint`, `CustomHint`, `Cursor`, `Help*` | M | ✔ | Von `TControl` geerbt (veröffentlicht in `Vcl.Controls`) |
| D3 | `Padding` bei Containern | M | ✔ | Panel, GroupBox, Expander u. a. |
| D4 | `Touch`/Gesten | K | ✔ | Umgesetzt: `Touch` und `OnGesture` bei allen sichtbaren Controls veröffentlicht |
| D5 | Actions | M | ✔ | Button, CheckBox, ToolBar- und Ribbon-Items |
| D6 | Daten-sensitive Varianten | M | ✔ | 16 DB-Controls |
| D7 | Barrierefreiheit (MSAA/UIA), Tastatur | M | ✔ | — |
| D8 | DPI pro Monitor, RTL | M | ✔ | — |
| D9 | Übersetzung zur Laufzeit | S | ✔ | `PPG.Lang` |
| D10 | Animation abschaltbar, Systemeinstellung beachten | S | ✔ | `Animation.Enabled`, `Duration`, `RespectSystemSettings` |
| D11 | Benutzer-Layout speichern (Spalten, Breiten, Sortierung) | S | ✔ | Umgesetzt: Kanban und Planer `SaveLayout`/`LoadLayout`, Ribbon `SaveQuickAccess`/`LoadQuickAccess` |
| D12 | Drucken und Export | S | ✔ | Umgesetzt: `TPPGKanbanPrinter` (Vorschau, PDF, auf Seitenbreite verkleinern, Folgeseiten) |
| D13 | Validierung in Feldern | S | ✔ | `ValidationState`/`ValidationHint` |
| D14 | Nur-Lese-Optik (eigener Stil bei `ReadOnly`) | K | ✔ | Umgesetzt: `ReadOnlyStyle` (Fläche, Text, Rand) bei allen Eingabefeldern |

## 4. Übersicht nach Control-Gruppen

Stand nach der Umsetzung (08.10.2026):

| Gruppe | Farben | Schriften | Bereiche/Elemente | Eigenes Zeichnen | Gesamt |
|---|---|---|---|---|---|
| Button, Check, Radio, Toggle | ✔ je Zustand, Fokus, Dunkel | ✔ Stil je Zustand | ✔ Ecken, Schatten (Button) | – (kaum nötig) | **sehr gut** |
| Edit, Memo, Spin, Number, Mask, Password, File, Date, Time, Combo, Search, Tag, ColorPicker | ✔ inkl. ReadOnly-Optik | ✔ | ✔ Combo-Liste mit `Styles` | ✔ Combo-Liste | **sehr gut** |
| Panel, GroupBox, Expander, Splitter | ✔ | ✔ (`CaptionStyle`, `HeaderStyle`) | ✔ Ecken, Schatten (Panel) | ◐ | **sehr gut** |
| ProgressBar, TrackBar, ProgressRing, Rating, Badge, Gauge, Sparkline, KPI | ✔ | ✔ (`ValueStyle`, `TitleStyle`) | ◐ | – | **gut** |
| ListBox, CheckListBox | ✔ | ✔ | ✔ Zebra, Auswahl, Hover, Item-Farbe | ✔ | **sehr gut** |
| TreeView | ✔ | ✔ | ✔ Knotenfarbe/-stil | ✔ | **sehr gut** |
| Grid, DB-Grid | ✔ | ✔ Kopf, Fuß, Gruppe, Spalte | ✔ 10 Bereiche, Spalten, bedingte Formate | ✔ | **sehr gut** |
| Tab-, PageControl, NavigationView, Breadcrumb, ToolBar, StatusBar, MenuBar, Menüs, Ribbon | ✔ | ✔ | ✔ je Reiter/Eintrag | ✔ | **sehr gut** |
| Kalender, Planer | ✔ | ✔ | ✔ Tage, Kategorien, Ressourcen | ✔ | **sehr gut** |
| Kanban | ✔ | ✔ | ✔ | ✔ | **sehr gut** |
| Chart | ✔ Palette | ✔ Titel, Legende, Achsen | ✔ | – | **sehr gut** |
| InfoBar, Toast, TeachingTip, Hints, Dialoge | ✔ über Tokens, `Style` | ◐ | – | – | **gut** |

## 5. Empfehlung: drei Bausteine schließen fast alle Lücken

Die Lücken haben dieselbe Ursache: Jedes Control hat genau eine Appearance, und alle Bereichsfarben werden daraus berechnet. Statt in jedem Control einzelne Properties nachzurüsten, sollten drei gemeinsame Bausteine ins Fundament.

**1. Element-Stile (`TPPGElementStyle`)** – deckt C1–C7, C12 und B10 ab

- Ein kleines `TPersistent` mit `Color`, `TextColor`, `BorderColor`, `Font`, `ParentFont`/`UseFont` und `FontStyle`.
- **Standardwert `clDefault` bedeutet „vom Preset berechnet“.** So bleibt die heutige Optik unverändert, und nur gesetzte Werte überschreiben sie. Nach demselben Muster arbeitet DevExpress.
- Komplexe Controls bekommen eine Gruppe `Styles` mit den Bereichen, die sie wirklich haben:
  - Grid: `Header`, `Selection`, `SelectionInactive`, `AlternateRow`, `HotRow`, `GridLine`, `Footer`, `GroupRow`, `FilterRow`
  - Planer: `Header`, `TimeRuler`, `WorkHours`, `NonWorkHours`, `Today`, `NowLine`
  - entsprechend für Liste, Baum, Reiter, Kalender, Navigation, Kanban und Chart
- Spalten, Items, Knoten, Reiter und Einträge erhalten außerdem `Color`/`Font` als Überschreibung im Einzelfall.
- Zebra-Zeilen werden über `Styles.AlternateRow.Color` aktiviert.
- Kompatibilität: `TStringGrid.FixedColor` usw. werden als Aliase auf diese Stile gelegt, damit alte DFMs geladen werden.

**2. Theme-Tokens überschreibbar** – deckt A3, A4, A6, A8 und C14 ab

- `TPPGStyleManager` erhält:
  - `AccentColor` (`clDefault` = vom Preset bzw. vom System)
  - eine `Tokens`-Gruppe für Hell und eine für Dunkel (nur gesetzte Werte überschreiben)
  - eine `ChartPalette`
  - `SaveToFile`/`LoadFromFile` (JSON oder INI)
- Die Appearance bekommt eine Dunkel-Variante: entweder `AppearanceDark` oder Zustandsfarben, die auf Tokens verweisen statt auf feste Farben.

**3. Einheitliche Zeichen-Ereignisse** – deckt C10 und C11 ab

- Ein gemeinsames Muster `OnCustomDrawItem(Sender, Item, Canvas, Rect, State, var Style, var DefaultDraw)` für TreeView, Reiter, Navigation, Combo-Liste, Menüs, Kanban-Karte, Planer-Termin und Kalendertag.
- Zuerst ändert man nur den Stil (wie `OnGetCellStyle`), bei Bedarf übernimmt man das Zeichnen ganz.

Kleinere Ergänzungen, die in die Bausteine passen: Schriftstil je Zustand (B6), Fokus-Zustand (B2), `Margin` und Textausrichtung im Button (B7), `PressedImageIndex` und Symbol-Einfärbung (B8), DFM-Lücken bei PageControl/TreeView und Abbildung in `migrate.ps1` (D1).

**Vorgeschlagene Reihenfolge** (nach Nutzen für die Vorführung beim Arbeitgeber):
1. Baustein 2 mit `AccentColor` und Firmen-Theme-Datei: kleiner Aufwand, sofort sichtbar
2. Baustein 1 für Grid und DB-Grid (Kopf, Auswahl, Zebra, Linien, Spalten)
3. Baustein 1 für Liste, Baum, Reiter, Planer und Kalender
4. Baustein 3
5. Die Kleinigkeiten

Jeder Schritt bekommt Streaming-Tests („unverändert bei `clDefault`“), Sichttests in der Galerie und einen Dark-Mode-Test.

## 6. Quellen

- VCL: `Vcl.Controls.pas` (RAD Studio 13, veröffentlichter Teil von `TControl`), `Vcl.Grids` (`TStringGrid`), `Vcl.ComCtrls` (`TPageControl`, `TTreeView`, `TMonthCalendar`)
- TMS `TAdvGlowButton`: [Zustandsfarben in DFM-Auszügen](https://support.tmssoftware.com/t/advglowbutton-default-appearance/5808), [ColorMirrorHot](https://support.tmssoftware.com/t/color-button/5284), [TextColorChecked/Down](https://support.tmssoftware.com/t/glowbutton-behavior/6470)
- TMS `TAdvStringGrid`: [Bands Primary/SecondaryColor (FAQ)](https://tmssoftware.com/site/tips.asp?show=243), [SelectionColor](https://support.tmssoftware.com/t/tadvstringgrid-selectioncolor/615), [Auswahlfarben je Zeile](https://support.tmssoftware.com/t/custom-font-and-cell-background-colors-for-a-selected-row/24894)
- DevExpress: [TcxVerticalGridStyles (Content, ContentEven/Odd, Header, Selection, Inactive)](https://docs.devexpress.com/VCL/cxVGrid.TcxVerticalGridStyles._properties), [TcxTreeListStyles.ContentEven](https://docs.devexpress.com/VCL/cxTL.TcxTreeListStyles.ContentEven)
- Hinweis: Einzelne TMS-Namen (z. B. `TextColorHot`) ließen sich online nicht belegen. Die Anforderungen stützen sich deshalb auf das belegte Muster „Farbe je Zustand bzw. je Bereich“, nicht auf exakte Namen.
