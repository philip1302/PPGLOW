# TPPGNavigationView

Palette **PPGlow** - Unit `PPG.NavigationView` - Basis `TPPGCustomControl`

**Vorbild:** WinUI NavigationView, TMS AdvNavBar

## Unterschiede und Hinweise

- `Selected` im Code löst kein Ereignis aus; Elterneinträge klappen nur auf (werden nicht gewählt).
- `pdmAuto` beobachtet die Breite des Parents; kompakt öffnet ein Klick auf einen Elterneintrag die Leiste.
- Mit `PageControl` verbunden zeigt die Auswahl die Seite `Item.PageIndex` (Verb „Connect to ...“).
- Einträge im Designer über „Edit items...“ (Baum-Editor mit Einrücken/Ausrücken).

## Verhalten (aus dem Quelltext)

TPPGNavigationView - Seitenleiste wie WinUI NavigationView (Phase 7c).

- Eintraege (Items, verschachtelt): Symbol (Icon-Schrift-Zeichen oder ImageIndex), Text, Plakette (Zahl oder Punkt), Gruppenueberschrift, Trenner, Untereintraege (aufklappbar), Fussbereich (Footer = True, z.B. Einstellungen).
- Hamburger-Knopf klappt die Leiste zwischen voller Breite (OpenPaneLength) und kompakter Symbolleiste (CompactPaneLength) um; die Breite ist animiert. DisplayMode pdmAuto wechselt nach der Breite des Parents (CompactModeThresholdWidth). Kompakt zeigt einen Tooltip mit dem Text des Eintrags.
- Der Auswahl-Indikator gleitet zum gewaehlten Eintrag (ekDecelerate). Ist der gewaehlte Eintrag verborgen (zugeklappter Elterneintrag, kompakt), steht der Indikator am sichtbaren Vorfahren.
- PageControl: Ist eins verbunden, zeigt die Auswahl die Seite Item.PageIndex.
- Tastatur: Oben/Unten, Pos1/Ende, Enter/Leertaste waehlen, Rechts/Links klappen auf/zu (bzw. springen zum Elterneintrag).
- Code (Selected := ...) loest kein Ereignis aus; der Anwender loest OnItemInvoked und bei geaenderter Auswahl OnSelectionChange aus.
- Screenreader: Gliederung; Kinder sind die sichtbaren Zeilen und der Menue-Knopf.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `HighContrastSupport`, `Images`, `Items`, `IsPaneOpen`, `DisplayMode`, `OpenPaneLength`, `CompactPaneLength`, `CompactModeThresholdWidth`, `PaneTitle`, `ShowMenuButton`, `PageControl`, `Align`, `Anchors`, `BiDiMode`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `TabOrder`, `TabStop`, `Visible`

## Ereignisse

`OnEnter`, `OnExit`, `OnItemInvoked`, `OnPaneChange`, `OnSelectionChange`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGNavigationView.md`.
