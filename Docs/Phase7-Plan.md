# Phase 7 – Detailplan: Navigation, Datum/Zeit, Rückmeldung

*Stand 04.10.2026. Teil der Roadmap (`Docs\Roadmap.md`). **Vom User freigegeben am 04.10.2026. Umgesetzt am 04.10.2026 (7a–7d, 513 Tests grün, Benchmark eingehalten) – siehe „Umsetzung“ am Ende.***

**Entscheidungen des Users (04.10.2026):** alle vier Teile (7a–7d) mit allen 16 Controls, **am Stück** (Bericht am Ende); die Demo bekommt die **NavigationView als Hauptnavigation**.

Phase 7 bringt die Controls, mit denen ganze Anwendungen gebaut werden, die keine Datenlisten sind: Navigation, Datum und Zeit, Rückmeldungen an den Anwender sowie kleinere Bausteine. Alle Controls entstehen auf der vorhandenen Infrastruktur (Tokens, Dark Mode, `ekDecelerate`, `PPG.IconFont`, `TPPGItemPainter`, `TPPGPopupWindow`, Feld-Basis, Scroll-Basis) und damit von Anfang an in allen Presets, hell und dunkel, mit Hochkontrast, DPI und Screenreader.

## Teilschritte (Vorschlag)

| Teil | Inhalt | Größe |
|---|---|---|
| **7a** | Kleinere Controls: `TPPGLabel`/`TPPGLinkLabel`, `TPPGBadge`, `TPPGProgressRing`, `TPPGInfoBar`, `TPPGExpander`, `TPPGSplitter`, `TPPGRating`, `TPPGSearchEdit` | mittel |
| **7b** | Datum/Zeit: `TPPGCalendar`, `TPPGDatePicker`, `TPPGTimePicker` | groß |
| **7c** | Navigation: `TPPGNavigationView`, `TPPGBreadcrumb`, `TPPGToolBar`, `TPPGStatusBar` | groß |
| **7d** | Benachrichtigungen: `TPPGToast` / `TPPGNotificationCenter` | mittel |

Reihenfolge-Idee: Die kleinen Bausteine aus 7a (Badge, ProgressRing, LinkLabel) werden in 7c/7d wiederverwendet, deshalb zuerst.

## 7a – Kleinere Controls

| Control | Vorbild | Kern |
|---|---|---|
| `TPPGLabel` | `TLabel` | Grafisches Control (kein Fenster), Markup (`AllowMarkup`), Ellipse, `WordWrap`, `FocusControl`, Accelerator, Farbe aus Tokens (TextPrimary/Secondary, Dark Mode); DFM wie `TLabel` |
| `TPPGLinkLabel` | `TLinkLabel` | Fenster-Control mit Fokus: Links im Markup (`<a href>`) per Tab erreichbar, Enter/Klick → `OnLinkClick(Link, LinkType)`, Hover-Unterstreichung; Screenreader: Rolle Link |
| `TPPGBadge` | WinUI InfoBadge | Punkt, Zahl oder Symbol (Icon-Schrift), Farbe Akzent/Signalfarbe; auch als Zeichen-Helfer für NavigationView/Reiter |
| `TPPGProgressRing` | WinUI ProgressRing | Bestimmt (0–100 %) und unbestimmt (rotierender Bogen über den Animator, `ekDecelerate`-artige Längenänderung); ruht, wenn unsichtbar |
| `TPPGInfoBar` | WinUI InfoBar | Info/Erfolg/Warnung/Fehler mit Symbol, Titel, Text (Markup), optionaler Aktions-Button und Schließen-Knopf; `OnClose`, Ein-/Ausblenden animiert; Screenreader-Meldung beim Zeigen |
| `TPPGExpander` | WinUI Expander / TMS CategoryPanel | Container mit Kopfzeile (Titel, Detail, Pfeil), Auf-/Zuklappen animiert (Höhe), Kinder bleiben erhalten; `Expanded`, `OnExpanding/OnExpanded`; mehrere untereinander = Kategorie-Panel |
| `TPPGSplitter` | `TSplitter` | Ziehgriff im Preset-Stil (Hover-Linie, Griffpunkte), Tastatur (Pfeile verschieben), `MinSize`, `ResizeStyle`; DFM wie `TSplitter` |
| `TPPGRating` | TMS Rating | Sterne (Icon-Schrift, sonst Polygon), halbe Sterne optional, Hover-Vorschau, Tastatur, `ReadOnly`, `OnChange` |
| `TPPGSearchEdit` | WinUI AutoSuggestBox | Feld-Basis mit Lupe, Löschen-Knopf, Verzögerung (`SearchDelay`, über den Animator, kein Timer), `OnSearch`, optionale Vorschlagsliste im Popup (`TPPGPopupList` mit `ItemsEx`) |

## 7b – Datum/Zeit

| Control | Kern |
|---|---|
| `TPPGCalendar` | Monat/Jahr/Dekade mit animiertem Zoom (Klick auf den Titel), Wochennummern nach ISO 8601, erster Wochentag aus `FormatSettings`/Locale, Bereichsauswahl (`SelectionMode` Einzel/Bereich/Mehrfach), gesperrte Tage (`OnIsDateDisabled`), Min/Max, Heute-Markierung, Tastatur (Pfeile, Bild = Monat, Strg+Bild = Jahr), Screenreader (Tabelle mit Tagen) |
| `TPPGDatePicker` | Feld-Basis + Popup mit `TPPGCalendar`; Eingabe mit Maske nach `FormatSettings.ShortDateFormat`, Prüfen beim Verlassen (ValidationState), `Date`/`Checked` (leeres Datum wie `ShowCheckbox` bei `TDateTimePicker`), `OnChange`; DFM-nah zu `TDateTimePicker` (Kind=dtkDate) |
| `TPPGTimePicker` | Feld-Basis, Stunden/Minuten (optional Sekunden) per Tastatur/Mausrad/Spin, 12/24 h aus Locale, Popup-Liste mit Schritten (`MinuteIncrement`) |

Fallstricke: Kalenderwoche und erster Wochentag sind Locale-abhängig (nicht `DayOfWeek` hart verdrahten); Zeitzonen nur Anzeige; Tests mit fester Locale (de/en) und Datumsgrenzen (Jahreswechsel KW 53, Schaltjahre).

## 7c – Navigation

| Control | Kern |
|---|---|
| `TPPGNavigationView` | Seitenleiste wie WinUI (links, einklappbar mit Hamburger, kompakt nur Symbole, Breite animiert), Einträge mit Icon (Icon-Schrift oder ImageList), Text, Badge, Gruppen/Trenner, Untereinträge (aufklappbar), Auswahl-Indikator gleitet (`ekDecelerate`), Fußbereich (Einstellungen); optional verbunden mit einem PageControl (`PageControl`-Property, Seite je Eintrag) |
| `TPPGBreadcrumb` | Pfad aus Segmenten mit Chevrons, Überlauf mit „…“-Menü, Klick → `OnItemClick`; Tastatur |
| `TPPGToolBar` | Buttons/Trenner/Toggle-Buttons im Preset-Stil (nutzt `TPPGButton`-Optik), Überlauf in ein „…“-Menü, wenn zu schmal; Actions; Tastatur |
| `TPPGStatusBar` | Panels (Text mit Markup, Bild, Badge, ProgressBar-Panel), Größengriff; DFM-nah zu `TStatusBar` (`Panels`, `SimplePanel`) |

## 7d – Benachrichtigungen

| Control | Kern |
|---|---|
| `TPPGNotificationCenter` | Komponente aufs Formular; `Show(Titel, Text, Art, Dauer, Aktionen)` erzeugt Toasts: eigene Top-Level-Fenster ohne Aktivierung (wie das Popup, `WS_EX_NOACTIVATE`), gestapelt in einer Bildschirmecke (Position wählbar), Ein-/Ausblenden animiert, Auto-Ausblenden mit Pause bei Hover, Schließen-Knopf, Aktions-Buttons → `OnAction`; Monitor des Formulars; nicht über Vollbild-Anwendungen (`SHQueryUserNotificationState`); Screenreader-Meldung |

## Bewusste Entscheidungen (Vorschlag)
- Alle Controls benutzen ausschließlich Tokens/`EffectiveAppearance` → Dark Mode, VCL-Style, Hochkontrast ohne Sonderwege.
- Zeitgesteuertes (ProgressRing, SearchEdit-Verzögerung, Toast-Ausblenden) läuft über den gemeinsamen Animator, nie über eigene Timer.
- `TPPGLabel` ist ein `TGraphicControl` (wie `TLabel`, keine Fenster-Handles); alle anderen sind Fenster-Controls auf `TPPGCustomControl`.
- DFM-Nähe zu den VCL-Vorbildern, wo es sie gibt (`TLabel`, `TLinkLabel`, `TSplitter`, `TDateTimePicker`, `TStatusBar`).
- Toasts sind PPGlow-eigen (keine Windows-Benachrichtigungen über das Action Center; das wäre ein späterer Schritt mit WinRT).

## Tests (`Tests\PPG.Tests.Phase7a/b/c/d.pas`)
Wie bisher je Control: Lebenszyklus, DFM-Roundtrip (inkl. DFM des VCL-Vorbilds), Verhalten (Maus, Tastatur, Ereignisreihenfolge, Code ohne Ereignisse), Zeichnen in allen Presets hell/dunkel/GDI, Hochkontrast-Zweig, Barrierefreiheit, Leaks; Datum mit fester Locale und Grenzfällen; Benchmark-Vorgaben für Calendar und NavigationView.

## Demo
Neue Seiten „Kleine Controls“, „Datum/Zeit“, „Navigation“ (die Demo selbst könnte die NavigationView als Hauptnavigation bekommen) und ein Knopf für Toasts.

## Fragen an den User
Beantwortet am 04.10.2026 (siehe „Entscheidungen des Users“ oben).

## Umsetzung (04.10.2026)

| Teil | Units | Ergebnis |
|---|---|---|
| 7a | `PPG.Labels`, `PPG.Feedback`, `PPG.Expander`, `PPG.Splitter`, `PPG.Rating`, `PPG.SearchEdit` | alle 9 Controls, Tests `PPG.Tests.Phase7a` |
| 7b | `PPG.Calendar`, `PPG.DatePicker`, `PPG.TimePicker` | Tests `PPG.Tests.Phase7b` (feste Locale, KW 53, Schaltjahr, RTL) |
| 7c | `PPG.NavigationView`, `PPG.Breadcrumb`, `PPG.ToolBar`, `PPG.StatusBar` | Tests `PPG.Tests.Phase7c` |
| 7d | `PPG.Notifications` | Tests `PPG.Tests.Phase7d` (echte Fenster, Zeitablauf, Ruhezeit) |

**QS:** 513 Tests grün (vorher 410), Runtime auch Win64. Benchmark-Vorgaben neu: Calendar 1000 Monate blättern + zeichnen ≤ 2500 ms (gemessen 1750), 20 000 Tage per Tastatur ≤ 1000 ms (640), NavigationView mit 1000 Einträgen 300 × scrollen + zeichnen ≤ 2500 ms (690) und 1000 × Auswahl + zeichnen ≤ 3000 ms (2235). Sichtprüfung per Demo-Screenshot hell, dunkel, Fluent11 und der Toasts (`/toastcapture`).

**Abweichungen vom Plan:**
- Unit `PPG.Labels` statt `PPG.Label` (`Label` ist ein reserviertes Wort).
- `TPPGLabel` ohne eigene Ellipse/Accelerator-Logik: diese kommen von `TCustomLabel` (EllipsisPosition, ShowAccelChar, FocusControl).
- Badge ohne Symbol-Variante; dafür Zahl (mit `MaxValue` → „99+“), Punkt und kurzer Text.
- InfoBar blendet nicht animiert ein/aus (nur `IsOpen` → `Visible`), meldet aber `EVENT_SYSTEM_ALERT`.
- Calendar: Monat/Jahr/Dekade mit Zoom- und Blätteranimation; Wochennummern nach ISO 8601 (bei Wochenbeginn ≠ Montag die Woche mit den meisten Tagen der Zeile).
- DatePicker ohne echte Eingabemaske: Zeichenfilter (Ziffern + Trenner) und Prüfung beim Verlassen/Enter.
- TimePicker ohne Spin-Buttons; Oben/Unten und Mausrad ändern den Teil an der Einfügemarke, die Liste bietet die Schritte.
- Breadcrumb/ToolBar: Überlauf als natives Kontextmenü.
- NotificationCenter: Toasts gleiten von der Seite herein (Deckkraft + Position), Stapel rückt animiert nach.

**Nebenbei behoben bzw. erweitert:**
- `PPG.Markup`: beim Umbruch bekam ein Fragment, das mit reinen Leerzeichen begann, die Höhe 0 – nachfolgender Text stand eine halbe Zeile zu tief.
- `TPPGCustomControl.AutoSizeWidth`: Controls, die per AutoSize nur ihre Höhe bestimmen, verschluckten Breitenänderungen.
- `TPPGPageControl`: alle Reiter ausgeblendet → aktive Seite bleibt, Reiterleiste verschwindet (wie `TPageControl`).
- `PPG.IconFont.PPGDrawIconChar` (beliebiges Zeichen), weitere Glyphen; `PPGSplitString` (XE2 kennt `string.Split` nicht); Schalter `PPG_HAS_SYSTEM_ACTIONS`.
- `Build\build.ps1` bestätigt den Lizenzhinweis der Community Edition in der eigenen Batch-IDE (vom User freigegeben).

**Prüfrunde nach Rückmeldung des Users (04.10.2026), behoben:**
- DatePicker: Popup war leer. Ein Popup ohne Parent bekommt von der VCL kein `UpdateShowing`, sein Kind (der Kalender) blieb deshalb versteckt. Jetzt zeigt bzw. versteckt `TPPGCalendarPopup.ShowCalendar/HideCalendar` das Kalenderfenster selbst; der Kalender prüft für Animationen `IsWindowVisible` statt `Showing`.
- DatePicker: Fokus-Tag im Popup war unsichtbar (Fokus bleibt beim Feld) → `TPPGCalendar.ShowFocusAlways`.
- Rating: halbe Sterne gingen beim Laden verloren (`Value` vor `AllowHalf` im DFM) → gerundet wird erst in `Loaded`.
- StatusBar: eigene Schrift ging beim Laden verloren → Schriftänderung schaltet `UseSystemFont` ab (wie `TStatusBar`), `Font` wird nur ohne Systemschrift gespeichert.
- Expander: `Padding.Top`/`Padding.Bottom` wurden ignoriert.
- Splitter: `Beveled` und `OnPaint` (mit `Canvas`) wie `TSplitter`; selbst gesetzter `Cursor` bleibt.
- InfoBar: Öffnen/Schließen jetzt animiert (Höhe über AutoSize).
- NotificationCenter: Auswahlliste für `Preset` im Objektinspektor.
- SearchEdit: filtert die alten Vorschläge nicht mehr vor der Suche.
- Neuer Test `PPG.Tests.Streaming`: jede einfache published Property aller 35 Controls durch die DFM. Demo: `/datepopup datei.png` (DatePicker aufgeklappt, echte Bildschirmpixel).

**Optische Prüfrunde (04.10.2026), behoben** (Galerie und Sichttests `PPG.Tests.Visual`):
- CheckBox, RadioButton, ToggleSwitch (ModernFlat, Classic, GDI): Fokus bei angehaktem Zustand war unsichtbar (Rand in der Akzentfarbe auf Akzentfläche). Jetzt Ring außen (`DrawOuterFocusRing` in der Renderer-Basis).
- Fluent11 deaktiviert: Bei Kästchen, Kreis und Schalter fehlte der Rand. Eine graue Füllung bekommt jetzt immer einen sichtbaren Rand (`FilledBorder`).
- Fluent11-Hover bei Auswahl-Controls und Feldern war unsichtbar. Hat ein Preset keine eigene Hover-Randfarbe, wird der Rand jetzt kräftiger bzw. die Fläche leicht getönt; ModernFlat und Classic bleiben unverändert.
- Deaktiviert ohne volle Akzent-/Signalfarben: Grid (vorher gar keine Änderung), ListBox/CheckListBox/TreeView (Auswahl), StatusBar, NavigationView (Plaketten, Indikator), InfoBar (Symbol, Fläche, Text), ToolBar (Strich unter eingerasteten Buttons).
- LinkLabel: Der Fokusrahmen berührte die Nachbarwörter.
- Offen gelassen: Hover im Grid (war nicht geplant).
