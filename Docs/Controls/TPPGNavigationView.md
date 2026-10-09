# TPPGNavigationView

Palette **PPGlow** - Unit `PPG.NavigationView` - Basis `TPPGCustomControl`

**Vorbild:** WinUI NavigationView, TMS AdvNavBar

## Unterschiede und Hinweise

- `Selected` im Code löst kein Ereignis aus; Elterneinträge klappen nur auf (werden nicht gewählt).
- `pdmAuto` beobachtet die Breite des Parents; kompakt öffnet ein Klick auf einen Elterneintrag die Leiste.
- Mit `PageControl` verbunden zeigt die Auswahl die Seite `Item.PageIndex` (Verb „Connect to ...“).
- Einträge im Designer über „Edit items...“ (Baum-Editor mit Einrücken/Ausrücken).

## Anpassung

- Je Eintrag `Color`, `TextColor`, `FontStyle`; `Styles` und `OnCustomDrawItem`; `ImageTint` für einfarbige Symbole.

## Verhalten (aus dem Quelltext)

TPPGNavigationView - Seitenleiste wie WinUI NavigationView (Phase 7c).

- Eintraege (Items, verschachtelt): Symbol (Icon-Schrift-Zeichen oder ImageIndex), Text, Plakette (Zahl oder Punkt), Gruppenueberschrift, Trenner, Untereintraege (aufklappbar), Fussbereich (Footer = True, z.B. Einstellungen).
- Hamburger-Knopf klappt die Leiste zwischen voller Breite (OpenPaneLength) und kompakter Symbolleiste (CompactPaneLength) um; die Breite ist animiert. DisplayMode pdmAuto wechselt nach der Breite des Parents (CompactModeThresholdWidth). Kompakt zeigt einen Tooltip mit dem Text des Eintrags.
- Der Auswahl-Indikator gleitet zum gewaehlten Eintrag (ekDecelerate). Ist der gewaehlte Eintrag verborgen (zugeklappter Elterneintrag, kompakt), steht der Indikator am sichtbaren Vorfahren.
- PageControl: Ist eins verbunden, zeigt die Auswahl die Seite Item.PageIndex.
- Tastatur: Oben/Unten, Pos1/Ende, Enter/Leertaste waehlen, Rechts/Links klappen auf/zu (bzw. springen zum Elterneintrag).
- Code (Selected := ...) loest kein Ereignis aus; der Anwender loest OnItemClick und bei geaenderter Auswahl OnChange aus.
- Screenreader: Gliederung; Kinder sind die sichtbaren Zeilen und der Menue-Knopf.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `Items` | [TPPGNavItems](types/TPPGNavItems.md) |  | Einträge der Leiste (verschachtelt über Item.Items), mit Symbol, Text, Plakette, Überschriften, Trennern und Fußbereich. Nutzung: Im Designer per Collection-Editor; im Code `with PPGNavigationView1.Items.AddItem('Kunden', $E716, 2) do BadgeCount := 3;` |
| `SelectedIndex` | `Integer` | `-1` | Index des gewählten Eintrags in Items; -1 = keiner. Wird gespeichert, damit die Startauswahl im Designer festgelegt werden kann (Selected ist nur zur Laufzeit). |
| `IsPaneOpen` | `Boolean` | `True` | True: Leiste in voller Breite (OpenPaneLength); False: kompakt (CompactPaneLength). Der Wechsel ist animiert. |
| `DisplayMode` | `TPPGNavDisplayMode` | `pdmLeft` | Verhalten der Leiste: pdmLeft (immer links, Menü-Knopf klappt zwischen voll und kompakt), pdmLeftCompact (startet kompakt), pdmAuto (wechselt nach der Breite des Parents, siehe CompactModeThresholdWidth). Werte: `pdmLeft`, `pdmLeftCompact`, `pdmAuto`. |
| `OpenPaneLength` | `Integer` | `280` | Breite der offenen Leiste in logischen Pixeln (96 DPI), 48..2000. |
| `CompactPaneLength` | `Integer` | `48` | Breite der kompakten Leiste (nur Symbole) in logischen Pixeln, 24..200. |
| `CompactModeThresholdWidth` | `Integer` | `640` | Nur mit DisplayMode = pdmAuto: Ist der Parent schmaler als dieser Wert (Pixel), wird die Leiste kompakt. |
| `PaneTitle` | `string` |  | Titel oben in der offenen Leiste neben dem Menü-Knopf. |
| `ShowMenuButton` | `Boolean` | `True` | True: Der Hamburger-Knopf zum Auf- und Zuklappen der Leiste ist sichtbar. |
| `ImageTint` | `TPPGImageTint` | `itNone` | itTextColor färbt das Bild einfarbig in der Textfarbe des aktuellen Zustands. Ideal für einfarbige Symbole (SVG, Icon-Fonts), die so Hover, Dark Mode und Deaktiviert automatisch folgen. Werte: `itNone`, `itTextColor`. Nutzung: `PPGButton1.ImageTint := itTextColor;` |
| `PageControl` | `TPPGPageControl` |  | Verbundenes PageControl: Die Auswahl eines Eintrags zeigt dort die Seite Item.PageIndex. Nutzung: `PPGNavigationView1.PageControl := PPGPageControl1;` Die Reiter des PageControls dann ausblenden (TabVisible = False). |
| `Styles` | [TPPGNavStyles](types/TPPGNavStyles.md) |  | Aussehen der Leiste in Bereichen (Hintergrund, Einträge, Hover, Auswahl, Indikator, Überschriften); clDefault = vom Preset. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` | `alLeft` | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnCustomDrawItem` | `TPPGNavCustomDrawEvent` `(Sender: TObject; Canvas: TCanvas; Item: TPPGNavItem; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Eintrags: Style (Fill, TextColor, BorderColor, FontStyle) ändern oder mit DefaultDraw := False selbst zeichnen; Item ist der Eintrag. Nutzung: `if Item.Tag = 99 then Style.TextColor := clRed;` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnItemClick` | `TPPGNavItemEvent` `(Sender: TObject; Item: TPPGNavItem)` | Der Anwender hat einen Eintrag ausgelöst (Klick, Enter, Screenreader), auch wenn er schon gewählt war; Item ist der Eintrag. Nutzung: Befehle ohne eigene Seite ausführen, z. B. über Item.Tag. |
| `OnPaneChange` | `TNotifyEvent` `(Sender: TObject)` | Die Leiste wurde über den Menü-Knopf auf- oder zugeklappt. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Die Auswahl hat sich durch den Anwender geändert (nicht beim Setzen von Selected im Code). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGNavigationView.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
