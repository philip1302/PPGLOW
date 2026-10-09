# TPPGPageControl

Palette **PPGlow** - Unit `PPG.PageControl` - Basis `TPPGCustomTabs`

**Vorbild:** TPageControl / TTabSheet

## Unterschiede und Hinweise

- Seiten (`TPPGTabSheet`) über den Komponenteneditor: „New Page“, „Next/Previous Page“, „Delete Page“.
- Schließen einer Seite blendet standardmäßig nur den Reiter aus (`caHide`).
- Sind alle Reiter ausgeblendet, bleibt die aktive Seite aktiv und die Reiterleiste verschwindet (für die NavigationView).

## Anpassung

- Je TabSheet `TabColor`, `TabTextColor`, `TabFontStyle`; `TabStyles` (Reiter, Hover, aktiv, Leiste, Indikator).
- Wie `TPageControl`: `MultiLine`, `RaggedRight`, `Style`, `OwnerDraw`, `OnDrawTab`.

## Verhalten (aus dem Quelltext)

TPPGPageControl + TPPGTabSheet - Seiten mit Reitern, DFM-kompatibel zu
TPageControl/TTabSheet (ActivePage, TabPosition, TabWidth, TabHeight,
HotTrack, Images; Seiten mit Caption, ImageIndex, PageIndex, TabVisible).

- Seitenliste: Jede TPPGTabSheet, deren Parent das PageControl ist, ist eine Seite (auch per "Sheet.Parent := PC"). Die Reihenfolge ist die Einfuegereihenfolge bzw. PageIndex; GetChildren schreibt sie so in die DFM.
- Nur die aktive Seite ist sichtbar (csNoDesignVisible: auch im Designer).
- Wird die aktive Seite entfernt oder ihr Reiter ausgeblendet, wird die Nachbarseite aktiv (erst die folgende, sonst die vorige).
- Lag der Fokus auf der alten Seite, geht er auf die neue (erstes Control).
- Schliessen-Knopf: OnCloseQuery(Page, CanClose), dann OnClose(Page, Action) mit caHide (Reiter ausblenden, Standard), caFree oder caNone.
- Designer: Klick auf Reiter wechselt die Seite; ein Control auf einer verdeckten Seite auswaehlen zeigt diese (ShowControl). Komponenteneditor "Neue Seite" usw. in PPG.Reg.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `ActivePage` | `TPPGTabSheet` |  | Die sichtbare Seite (TPPGTabSheet). Setzen im Code löst kein OnChanging/OnChange aus; lag der Fokus auf der alten Seite, geht er auf die neue. Nutzung: `PPGPageControl1.ActivePage := tsAdresse;` |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `ShowCloseButton` | `Boolean` | `False` | True: Jeder Reiter zeigt einen Schließen-Knopf („×"); der Klick löst OnClosing und OnClose aus. |
| `Styles` | [TPPGTabStyles](types/TPPGTabStyles.md) |  | Aussehen der Reiterleiste einzeln: Tab (nicht gewählte Reiter), HotTab (Maus darüber), ActiveTab (gewählt), Strip (Fläche hinter den Reitern) und Indicator (Unterstrich); clDefault = vom Preset. Nutzung: `PPGPageControl1.Styles.ActiveTab.FontStyle := [fsBold];` |
| `MultiLine` | `Boolean` | `False` | True: Passen nicht alle Reiter in eine Zeile, werden sie auf mehrere Reihen verteilt (wie TPageControl); die Reihe mit dem gewählten Reiter liegt an der Seite. False: eine Reihe mit Blätterpfeilen. |
| `OwnerDraw` | `Boolean` | `False` | True: Der Inhalt der Reiter wird über OnDrawTab gezeichnet; Fläche und Rahmen kommen weiter aus dem Preset. |
| `RaggedRight` | `Boolean` | `False` | Nur mit MultiLine: True = Reihen werden nicht auf die volle Breite gestreckt. |
| `ScrollOpposite` | `Boolean` | `False` | Nur mit MultiLine und Reitern oben oder unten: Die Reihen zwischen dem gewählten Reiter und der Seite wechseln auf die Gegenseite (unter bzw. über die Seite), wie bei TPageControl. Wechselt die Auswahl in eine andere Reihe, ändern sich Aufteilung und Seitengröße. Nutzung: `PageControl1.MultiLine := True; PageControl1.ScrollOpposite := True;` |
| `Style` | `TTabStyle` | `tsTabs` | Darstellung wie TTabControl.Style: tsTabs (Reiter), tsButtons (Knöpfe) oder tsFlatButtons (flache Knöpfe). |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `HotTrack` | `Boolean` | `True` | True: Der Reiter unter der Maus wird hervorgehoben (Styles.HotTab). |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). |
| `TabHeight` | `Integer` | `0` | Höhe der Reiter in Pixeln (0..1000); 0 = aus der Schrift berechnet. |
| `TabPosition` | `TTabPosition` | `tpTop` | Lage der Reiterleiste: tpTop, tpBottom, tpLeft (Leiste links, Reiter untereinander) oder tpRight (rechts). Senkrecht ist die Leiste so breit wie der breiteste Reiter; der gewählte Reiter hat einen Indikator an der Kante zur Seite, bei zu vielen Reitern erscheinen Pfeile hoch/runter. MultiLine und ScrollOpposite gelten nur oben/unten. Nutzung: `PageControl1.TabPosition := tpLeft;` |
| `TabWidth` | `Integer` | `0` | Feste Breite aller Reiter in Pixeln (0..1000); 0 = jeder Reiter so breit wie seine Beschriftung. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `DragKind` | `TDragKind` |  | dkDrag = Drag & Drop, dkDock = Andocken beim Ziehen. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `TabOrder` | `TTabOrder` |  | Reihenfolge beim Weiterschalten mit Tab innerhalb des Parents (0 = zuerst). |
| `TabStop` | `Boolean` | `True` | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Der gewählte Reiter bzw. die aktive Seite hat sich durch den Anwender geändert (nicht beim Setzen im Code). |
| `OnChanging` | `TTabChangingEvent` `(Sender: TObject; var AllowChange: Boolean)` | Vor einem Reiterwechsel durch den Anwender; AllowChange := False verhindert ihn (z. B. wenn die aktuelle Seite ungültige Eingaben hat). |
| `OnDrawTab` | `TPPGDrawTabEvent` `(Control: TObject; TabIndex: Integer; const Rect: TRect; Active: Boolean)` | Mit OwnerDraw = True zeichnet die Anwendung den Inhalt jedes Reiters selbst (wie TTabControl.OnDrawTab): TabIndex, Rect und Active werden übergeben, gezeichnet wird auf Canvas des Controls. Nutzung: `PPGTabControl1.Canvas.TextOut(Rect.Left + 4, Rect.Top + 4, '★');` |
| `OnCustomDrawItem` | `TPPGCustomDrawItemEvent` `(Sender: TObject; Canvas: TCanvas; Index: Integer; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Reiters: Style (Fill, TextColor, BorderColor, FontStyle) für diesen Reiter ändern oder mit DefaultDraw := False selbst zeichnen; Index ist der Reiter, State enthält idsSelected/idsHot. Nutzung: `if Index = 0 then Style.FontStyle := [fsBold];` |
| `OnClose` | `TPPGPageCloseEvent` `(Sender: TObject; Page: TPPGTabSheet; var Action: TCloseAction)` | Eine Seite soll über ihren Schließen-Knopf geschlossen werden (nach OnClosing); Page ist die Seite. Action = caHide (Standard) blendet den Reiter aus, caFree gibt die Seite frei, caNone behält sie. |
| `OnClosing` | `TPPGPageCloseQueryEvent` `(Sender: TObject; Page: TPPGTabSheet; var CanClose: Boolean)` | Vor dem Schließen einer Seite; CanClose := False bricht ab. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. |
| `OnEndDock` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Andock-Vorgang dieses Controls beendet. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. |
| `OnResize` | `TNotifyEvent` `(Sender: TObject)` | Nach einer Größenänderung. |
| `OnStartDock` | `TStartDockEvent` `(Sender: TObject; var DragObject: TDragDockObject)` | Beginn des Andockens dieses Controls. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPageControl.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
