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

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Selected` | `TColor` | `clBlack` | Die gewählte Farbe. clNone = „Keine", clDefault = „Standard". Setzen aus Code löst kein OnChange aus. Nutzung: `Panel1.Color := PPGColorPicker1.Selected;` |
| `Style` | `TColorBoxStyle` | `[cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames]` | Abschnitte des Popups wie bei TColorBox: cbStandardColors (16 Grundfarben), cbExtendedColors (weitere Farben), cbSystemColors (clBtnFace usw.), cbIncludeNone („Keine"), cbIncludeDefault („Standard"), cbCustomColor (Schaltfläche „Weitere Farben …" mit HSV-Feld und Hex-Eingabe), cbPrettyNames (lesbare Namen). Nutzung: `PPGColorPicker1.Style := [cbStandardColors, cbIncludeNone, cbCustomColor];` |
| `ShowThemeColors` | `Boolean` | `True` | True: Das Popup zeigt oben die Designfarben des Presets (Akzent, Signalfarben, Diagrammpalette), damit gewählte Farben zum Theme passen. |
| `RecentColors` | `TStrings` |  | Zuletzt benutzte Farben als Hexwerte „#RRGGBB", die neueste zuerst. Wird beim Wählen automatisch fortgeschrieben und in der DFM gespeichert; kann zum Speichern in einer Einstellung gelesen und wieder gesetzt werden. Nutzung: `Ini.WriteString('Farben', 'Zuletzt', PPGColorPicker1.RecentColors.CommaText);` |
| `MaxRecent` | `Integer` | `8` | Wie viele zuletzt benutzte Farben gemerkt und als eigener Abschnitt gezeigt werden (0..32; 0 = kein Abschnitt). |
| `ShowHex` | `Boolean` | `False` | True: Das Feld zeigt den Hexwert („#1E90FF") statt des Farbnamens. |
| `NoneColorColor` | `TColor` | `clBlack` | Wie TColorBox.NoneColorColor; wird gespeichert, beeinflusst die Darstellung von „Keine" (clNone) im PPGlow-Popup aber nicht. |
| `DefaultColorColor` | `TColor` | `clBlack` | Farbe, mit der das Feld „Standard" (Selected = clDefault, mit cbIncludeDefault im Style) dargestellt wird. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Ergebnis einer Prüfung: pvsNone (neutral), pvsValid (grüner Rand), pvsWarning (gelb), pvsError (rot). Die Farben kommen aus den Signal-Tokens; ValidationHint erklärt den Zustand. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if not IstMail(Edit1.Text) then begin Edit1.ValidationState := pvsError; Edit1.ValidationHint := 'Keine gültige Adresse'; end;` |
| `ValidationHint` | `string` |  | Erklärung zum ValidationState; erscheint als Tooltip und wird vom Screenreader vorgelesen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `BorderStyle` | `TBorderStyle` | `bsSingle` | bsSingle: Rahmen nach Appearance; bsNone: ohne Rahmen (z. B. eingebettet in eigene Flächen). |
| `TabStop` | `Boolean` | `True` | True: Das Feld ist mit Tab erreichbar. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Color` | `TColor` | `clWindow` | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` | `False` | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der Text wurde geändert (Tippen, Einfügen, Code). |
| `OnCloseUp` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste wurde geschlossen (mit oder ohne Auswahl). |
| `OnDropDown` | `TNotifyEvent` `(Sender: TObject)` | Die Aufklappliste öffnet sich gleich; hier kann sie noch befüllt werden. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGColorPicker.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
