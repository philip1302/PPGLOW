# TPPGToolBar

Palette **PPGlow** - Unit `PPG.ToolBar` - Basis `TPPGCustomControl`

**Vorbild:** TToolBar

## Unterschiede und Hinweise

- Einträge (`Items`) statt Kind-Buttons; daher kein automatischer Umstieg von `TToolBar`/`TToolButton`.
- Überlauf als natives Kontextmenü; Actions über `Items[].Action`.

## Anpassung

- Je Item `Color`, `TextColor`, `FontStyle`; `ImageTint` für einfarbige Symbole.

## Verhalten (aus dem Quelltext)

TPPGToolBar - Befehlsleiste (Phase 7c, wie WinUI CommandBar).

- Items: Buttons, Umschalt-Buttons (tisCheck, mit GroupIndex wie Radiobuttons) und Trenner; Symbol aus Images oder der Symbolschrift (IconChar), Text wahlweise daneben (ShowCaptions).
- Optik aus dem Preset: Hover/gedrueckt/eingerastet ueber den Renderer wie TPPGButton, in Ruhe flach.
- Ueberlauf: Was nicht in die Breite passt, landet in einem "..."-Menue am Ende (Menue im Stil der Suite mit Haken fuer Umschalt-Buttons, Phase 11).
- Actions: Item.Action verbindet Caption, Hint, Enabled, Checked, Visible, ImageIndex und OnExecute; die Leiste aktualisiert die Actions im Leerlauf (InitiateAction) wie die VCL-Controls.
- Tastatur: Links/Rechts, Pos1/Ende, Enter/Leertaste.
- Code (Down := ...) loest kein Ereignis aus; ein Klick loest Item.OnClick (bzw. Action.Execute) und danach OnItemClick aus.
- Screenreader: Symbolleiste; Kinder Buttons/Umschalt-Buttons/Trenner und der Ueberlauf-Knopf.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `Items` | [TPPGToolItems](types/TPPGToolItems.md) |  | Befehle der Leiste: Buttons, Umschalt-Buttons und Trenner; was nicht in die Breite passt, landet im „…"-Menü am Ende. Nutzung: Im Designer per Collection-Editor; im Code `PPGToolBar1.Items.AddButton('Neu', $E710, NeuClick);` |
| `ShowCaptions` | `Boolean` | `True` | True: Text neben dem Symbol; False: nur Symbole (Text dann als Tooltip). |
| `ImageTint` | `TPPGImageTint` | `itNone` | itTextColor färbt das Bild einfarbig in der Textfarbe des aktuellen Zustands. Ideal für einfarbige Symbole (SVG, Icon-Fonts), die so Hover, Dark Mode und Deaktiviert automatisch folgen. Werte: `itNone`, `itTextColor`. Nutzung: `PPGButton1.ImageTint := itTextColor;` |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` | `alTop` | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
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

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnItemClick` | `TPPGToolItemEvent` `(Sender: TObject; Item: TPPGToolItem)` | Ein Item wurde ausgelöst (nach Item.OnClick bzw. Action.Execute); Item ist der Befehl. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGToolBar.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
