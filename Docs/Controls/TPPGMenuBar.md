# TPPGMenuBar

Palette **PPGlow** - Unit `PPG.MenuBar` - Basis `TPPGCustomMenuBar`

**Vorbild:** TMS TAdvMainMenu, Menüleiste von Windows 11

## Unterschiede und Hinweise

- Zeigt ein normales `TMainMenu` (Property `Menu`) als Control, standardmäßig mit `Align = alTop` und automatischer Höhe.
- Ist `Menu` zugleich das Menü des Formulars, wird `Form.Menu` zur Laufzeit geleert (sonst gäbe es zwei Leisten) und beim Freigeben wiederhergestellt. Im Designer bleibt alles unverändert.
- Tastatur wie bei Windows: Alt oder F10 aktiviert die Leiste, Alt+Buchstabe öffnet ein Menü, Pfeile wechseln, Esc verlässt die Leiste. Tastenkürzel der Einträge (Strg+S …) wirken auch ohne geöffnetes Menü.
- Zwischen offenen Menüs wechselt die Maus ohne erneuten Klick; ein zweiter Klick auf dasselbe Menü schließt es.
- MDI-Menüs (`Merge`/`Unmerge`) werden noch nicht zusammengeführt.
- Screenreader: Rolle Menüleiste, Ereignisse `EVENT_SYSTEM_MENUSTART/END`.

## Anpassung

- `MenuStyles` und `OnCustomDrawItem` wie `TPPGPopupMenu`.

## Beispiel

```pascal
PPGMenuBar1.Menu := MainMenu1;
```

## Verhalten (aus dem Quelltext)

TPPGMenuBar - Hauptmenue als Control im Stil der Suite (Phase 11c).

- Modell ist ein normales TMainMenu (Menue-Designer, Actions, DFM). Die Leiste zeigt seine Eintraege; Untermenues kommen aus PPG.Menus.
- Zur Laufzeit wird Form.Menu geleert (die Menue-Leiste im Nicht-Client- Bereich laesst sich weder stylen noch auf Dark Mode umstellen); beim Freigeben der Leiste wird es wiederhergestellt. Zur Entwurfszeit bleibt das Formular-Menue sichtbar.
- Weil Form.Menu leer ist, loest die VCL die Tastenkuerzel der Eintraege nicht mehr aus: das uebernimmt die Leiste (TMenu.IsShortCut, wie TCustomForm.IsShortCut).
- Tastatur wie Windows: Alt allein bzw. F10 markiert die Leiste, Alt+ Buchstabe oeffnet den Eintrag, Pfeile wechseln, Esc verlaesst. Haken in PPG.AppHooks, nur fuer Nachrichten des eigenen Formulars.
- Barrierefreiheit: Rolle MENUBAR mit Eintraegen als Kindern, EVENT_SYSTEM_MENUSTART/END.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Menu` | `TMainMenu` |  | Das TMainMenu, dessen Einträge die Leiste zeigt (bearbeiten im normalen Menü-Designer, mit Actions und Tastenkürzeln). Zur Laufzeit wird Form.Menu geleert und die Leiste übernimmt Darstellung und Kürzel; beim Freigeben der Leiste wird es wiederhergestellt. Nutzung: `PPGMenuBar1.Menu := MainMenu1;` Die Leiste mit Align = alTop oben aufs Formular legen. |
| `Styles` | [TPPGMenuStyles](types/TPPGMenuStyles.md) |  | Aussehen der aufklappenden Untermenüs: Fläche, Hover-Eintrag, Trennlinien und Tastenkürzel; clDefault = vom Preset. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` | `alTop` | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnCustomDrawItem` | `TPPGMenuCustomDrawEvent` `(Sender: TObject; Canvas: TCanvas; Item: TMenuItem; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Eintrags der Untermenüs: Style (Fill, TextColor, BorderColor, FontStyle) für diesen Eintrag ändern oder mit DefaultDraw := False selbst auf Canvas zeichnen. Item ist der TMenuItem. Nutzung: `if Item.Tag = 1 then Style.TextColor := clRed;` |
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGMenuBar.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
