# TPPGRadioGroup

Palette **PPGlow** - Unit `PPG.RadioGroup` - Basis `TPPGCustomChoiceGroup`

**Vorbild:** TRadioGroup (DFM gleich: `Items`, `ItemIndex`, `Columns`, `Caption`, `OnClick`)

## Unterschiede und Hinweise

- Keine Kind-Buttons: Die Einträge zeichnet die Gruppe selbst. `Buttons[]` der VCL gibt es nicht; Bild, Beschreibung und Sperre je Eintrag stehen in `ItemsEx`.
- `ChoiceStyle`: `csList` (Kreise wie die VCL), `csSegmented` (Umschalter in einer Zeile, der Akzent gleitet zum neuen Eintrag), `csCards` (Kacheln mit Symbol, Titel und Beschreibung).
- `Columns = 0`: so viele Spalten, wie in die Breite passen.
- `ItemIndex` im Code setzen löst `OnChange` aus, aber kein `OnClick` (wie bei den übrigen PPGlow-Controls).
- Tastatur wie die VCL: Pfeile wechseln innerhalb der Gruppe, Tab verlässt sie. UI Automation: Gruppe mit Auswahl-Muster, Einträge als Optionsfelder.
- `ValidationState` markiert eine fehlende Pflichtauswahl wie bei den Eingabefeldern.

## Beispiel

```pascal
PPGRadioGroup1.ChoiceStyle := csCards;
PPGRadioGroup1.Columns := 0;
with PPGRadioGroup1.ItemsEx.Add do
begin
  Caption := 'Standard';
  Description := '3 bis 5 Werktage';
  Icon := $E7BF;
end;
```

## Verhalten (aus dem Quelltext)

TPPGRadioGroup und TPPGCheckGroup - Auswahlgruppen (Phase 18a).

Mehrwert gegenueber TRadioGroup/TcxRadioGroup:
- ChoiceStyle: csList (Kreise bzw. Kaestchen wie die VCL), csSegmented (Umschalter in einer Zeile mit gleitendem Akzent) und csCards (Kacheln mit Symbol, Titel und Beschreibung).
- ItemsEx: je Eintrag Beschreibung, Symbol (Zeichen der Symbolschrift oder ImageIndex), Enabled, Hint und Value. Items bleibt als einfache Sicht (TStrings) und laedt alte DFMs von TRadioGroup unveraendert.
- Columns = 0 passt die Spalten der Breite an.
- ValidationState wie bei den Feldern (Pflichtauswahl rot markieren).

Aufbau:
- Basis TPPGCustomGroupBox (Rahmen und Plakette); ein Fenster, Eintraege selbst gezeichnet (keine Fensterflut). ShowFrame = False ohne Rahmen.
- Gespeichert wird ItemsEx nur, wenn ein Eintrag mehr als die Beschriftung hat, sonst Items.Strings (wie TRadioGroup).
- csList ordnet wie TRadioGroup spaltenweise (erst nach unten), die Zeilen teilen sich die Hoehe. Kacheln, Segmente und Columns = 0 ordnen zeilenweise.
- Ereignisse: Anwender waehlt -> OnClick, dann OnChange. Code setzt ItemIndex bzw. Checked[] ohne Ereignis (PPGlow-Regel, wie CheckBox).
- Tastatur: Pfeile wechseln (RadioGroup: Auswahl folgt), Leertaste kreuzt an (CheckGroup), Pos1/Ende, Accelerator & in den Eintraegen.
- Screenreader: jeder Eintrag ist ein Kind (Optionsfeld bzw. Kontrollkaestchen).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighlightFocus` | `Boolean` | `True` | True: Liegt der Fokus auf einem Kind-Control, leuchtet die Plakette in der Fokusfarbe und zeigt so, in welcher Gruppe gerade gearbeitet wird. |
| `CaptionStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen der Beschriftungs-Plakette auf der Rahmenlinie: Fläche, Rand, Textfarbe und Schrift; clDefault = vom Preset. Nutzung: `PPGGroupBox1.CaptionStyle.Color := clNavy; PPGGroupBox1.CaptionStyle.TextColor := clWhite;` |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `Items` | `TStrings` |  | Einfache Sicht auf die Einträge als Stringliste, wie TRadioGroup.Items; jede Zeile ist ein Eintrag in ItemsEx. Nutzung: `Grp.Items.Add('Firma');` |
| `ItemsEx` | [TPPGChoiceItems](types/TPPGChoiceItems.md) |  | Einträge mit Beschreibung, Symbol, Bild, Wert, Hinweis und Enabled. Im Designer per Doppelklick. Nutzung: `with Grp.ItemsEx.Add do begin Caption := 'Express'; Description := 'Lieferung morgen'; Icon := $E7C1; end;` |
| `ItemIndex` | `Integer` | `-1` | Gewählter Eintrag (-1 = keiner). Setzen im Code löst OnChange aus, aber kein OnClick. Nutzung: `if Grp.ItemIndex = 1 then ...` |
| `Columns` | `Integer` | `1` | Spalten wie bei TRadioGroup; 0 = so viele, wie in die Breite passen (die Einträge brechen um wie Kacheln). |
| `ChoiceStyle` | `TPPGChoiceStyle` | `csList` | Darstellung: csList = Kreise bzw. Kästchen wie die VCL, csSegmented = Umschalter in einer Zeile mit gleitendem Akzent, csCards = Kacheln mit Symbol, Titel und Beschreibung. Werte: `csList`, `csSegmented`, `csCards`. Nutzung: `Grp.ChoiceStyle := csSegmented; Grp.ShowFrame := False;` |
| `ShowFrame` | `Boolean` | `True` | True: Rahmen und Beschriftungsplakette wie TPPGGroupBox. False: nur die Einträge, z. B. ein Segment-Umschalter in einer Werkzeugleiste. |
| `ValidationState` | `TPPGValidationState` | `pvsNone` | Fehler- bzw. Warnzustand wie bei den Eingabefeldern, z. B. rot bei fehlender Pflichtauswahl. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. Nutzung: `if Grp.ItemIndex < 0 then Grp.ValidationState := vsError;` |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `ItemStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen der Einträge: Fläche, Text, Rand und Schrift (Segmente, Kacheln, Text der Liste). |
| `SelectedStyle` | [TPPGElementStyle](types/TPPGElementStyle.md) |  | Aussehen des gewählten Eintrags; leer = Akzentfarbe des Presets. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Caption` | `TCaption` |  | Beschriftung. Ein & vor einem Buchstaben macht ihn zur Zugriffstaste (Alt+Buchstabe). Nutzung: `Button1.Caption := '&Speichern';` |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBackground` | `Boolean` | `True` | True: Der Hintergrund des Parents scheint durch (transparente Wirkung). |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Die Auswahl hat sich geändert (Benutzer oder Code). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGRadioGroup.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
