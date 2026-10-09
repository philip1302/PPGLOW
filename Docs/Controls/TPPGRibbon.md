# TPPGRibbon

Palette **PPGlow** - Unit `PPG.Ribbon` - Basis `TPPGCustomRibbon`

**Vorbild:** TMS AdvToolBar / Office-Ribbon, Windows Ribbon Framework

## Unterschiede und Hinweise

- Aufbau: `Tabs` → `Groups` → `Items`, alles im Objektinspektor und in der DFM pflegbar. Das Ribbon liegt unter der normalen Titelleiste (kein Zeichnen im Nicht-Client-Bereich, damit VCL-Styles, DPI und Snap-Layouts funktionieren).
- Item-Arten (`Kind`): Button, Split-Button (`DropDownMenu`), Umschalt-Button (`Down`, `GroupIndex` gilt im ganzen Ribbon), Galerie, eingebettetes Control (`Control`, z. B. eine `TPPGComboBox`; das Ribbon wird ihr Parent) und Trenner.
- Größe: `Size` (groß = Symbol über Text, mittel = kleines Symbol mit Text, klein = nur Symbol) und `MinSize`. Kleine Items stapeln sich zu drei Zeilen; `BeginColumn` beginnt einen neuen Stapel, `SameRow` stellt ein Item rechts neben das vorige (z. B. Fett, Kursiv, Unterstrichen in einer Zeile).
- Symbole: `ImageIndex` aus `Images` (16 px), `LargeImageIndex` aus `LargeImages` (32 px) oder `IconChar` (Zeichen der Symbolschrift, z. B. `$E8C8` für Kopieren).
- **Schrumpfen:** Passt die Breite nicht, schrumpfen die Gruppen in fester Reihenfolge: erst alle auf „mittel“, dann „nur Symbol“, dann „als Dropdown“. Innerhalb einer Stufe zuerst die Gruppen mit kleinerem `ReduceOrder`, bei Gleichstand von rechts. Ein Schritt, der eine Gruppe nicht schmaler macht, wird übersprungen; eine Gruppe aus lauter kleinen Items wird deshalb nicht zum Dropdown, wenn das Dropdown breiter wäre. Die Galerie zeigt erst weniger Spalten, dann einen Dropdown-Button.
- Eine als Dropdown geschrumpfte Gruppe öffnet ein Popup mit der voll aufgeklappten Gruppe; eingebettete Controls wandern mit. Symbol der geschrumpften Gruppe: `ImageIndex`/`IconChar` der Gruppe, sonst das erste Item mit Symbol.
- `ShowLauncher` zeigt unten rechts in der Gruppe den Startknopf für einen Dialog (`OnLauncherClick`).
- Galerie: Einträge aus `GalleryItems` oder virtuell (`GalleryCount` + `OnGetGalleryItem`, auch mit Farbfeld), eigenes Zeichnen über `OnCustomDrawGalleryItem`. In der Leiste blättern die Pfeile rechts zeilenweise (auch mit dem Mausrad), der untere klappt die Galerie auf (Pfeile, Enter, Esc). Auswahl: `GalleryIndex`, `OnGalleryClick`. **Kategorien:** Einträge als „Kategorie|Text“ oder `Data.Group` in `OnGetGalleryItem`; die aufgeklappte Galerie zeigt je Kategorie eine Überschrift und beginnt eine neue Zeile, die Pfeile halten die Spalte und überspringen die Überschriften.
- **Actions** (`Item.Action`) liefern Caption, Hint, Enabled, Checked, Visible, ImageIndex und OnExecute, wie bei Menü und ToolBar.
- **KeyTips:** Alt bzw. F10 zeigt Plaketten über „Datei“, Schnellzugriff (1, 2, …) und Registerkarten; Alt+Buchstabe springt direkt in eine Karte. Danach zeigen die Befehle der Karte ihre Plaketten; Esc geht eine Ebene zurück. Vergeben werden sie automatisch aus der Beschriftung (`&`-Buchstabe, Wortanfänge, sonst zwei Zeichen); eigene über `KeyTip`. Die Plaketten zeichnet ein eigenes Overlay-Fenster je Monitor, auch über Popups.
- **Tastatur ohne Maus:** Nach Alt wechseln die Pfeiltasten in die Tastaturbedienung (Fokusrahmen; links/rechts innerhalb der Zeile, hoch/runter zwischen Karten und Band, Enter/Leertaste löst aus, Esc verlässt). Die Tastatur reicht bis in aufgeklappte Gruppen und Karten des eingeklappten Bands: Enter öffnet das Popup mit dem Fokus auf dem ersten Befehl, Tab und Pfeile bleiben darin, Esc geht eine Ebene zurück. Nach einem Öffnen mit der Maus führt ein Pfeil in das Popup.
- **Einklappen:** `Minimized`, Doppelklick auf eine Registerkarte, Strg+F1 oder der Knopf rechts. Eingeklappt öffnet ein Klick auf eine Karte sie als Popup.
- **Schnellzugriff:** `QuickAccess` (über oder unter dem Band, `QuickAccessPosition`). Rechtsklick auf einen Befehl fügt ihn hinzu, Rechtsklick im Schnellzugriff entfernt ihn (`QuickAccessCustomizable`, `OnQuickAccessChange`). Ein Schnellzugriff-Item wirkt auf das Item im Band mit gleicher Action bzw. gleicher Beschriftung, Art und Symbol (`QuickSource`).
- **Kontext-Registerkarten:** `ContextName` und `ContextColor` (farbige Leiste und Tönung). Die Anwendung schaltet `Visible` und `TabIndex` je nach Auswahl.
- **Datei:** Ist `Backstage` gesetzt (ein beliebiges Control, z. B. ein Panel oder PageControl), legt „Datei“ es über das ganze Formular bzw. seinen Parent; Esc oder `HideBackstage` schließt. Ohne Backstage öffnet „Datei“ `ApplicationMenu`. Vorher kommt immer `OnApplicationButtonClick`.
- Code setzt Werte ohne Ereignisse (`TabIndex`, `Minimized`, `Down`, `GalleryIndex`); Anwenderaktionen lösen `OnChanging`/`OnChange`, `OnItemClick`, `OnGalleryClick`, `OnMinimizedChange` usw. aus.
- Im Designer wechselt ein Klick auf eine Registerkarte die Karte; das Kontextmenü bietet „Edit tabs…“, „Edit groups of the active tab…“, „Edit Quick Access items…“, „New Tab“, „Next/Previous Tab“. Eingebettete Controls legt man auf das Ribbon und weist sie einem Item zu.
- Screenreader: Gruppierung „Menüband“; Kinder sind Datei, Schnellzugriff, Registerkarten (gewählt) und die Befehle der aktiven Karte mit Rolle (Button, Split-Button, Umschalt-Button, Menü-Button). RTL gespiegelt.
- Nicht unterstützt: Ribbon in der Titelleiste, MDI-Zusammenführung, Speichern des Schnellzugriffs (die Anwendung tut das in `OnQuickAccessChange`).

## Anpassung

- `SaveQuickAccess`/`LoadQuickAccess`: vom Anwender angepassten Schnellzugriff speichern (Schlüssel: Action-Name, sonst Reiter/Gruppe/Item mit Beschriftung).

## Beispiel

```pascal
uses PPG.Ribbon.Items, PPG.Ribbon.Layout;

var
  T: TPPGRibbonTab;
  G: TPPGRibbonGroup;
begin
  T := PPGRibbon1.Tabs.AddTab('Start');
  G := T.Groups.AddGroup('Zwischenablage');
  G.Items.Add.Action := EditPaste1;          // Standard-Action
  G.Items[0].IconChar := $E77F;
  G.Items.AddButton('Kopieren', $E8C8, rsMedium, CopyClick);
  G := T.Groups.AddGroup('Schriftart');
  G.Items.Add.Control := FontCombo;          // eingebettetes Control
  G.Items.AddCheck('Fett', $E8DD);
  G.Items.AddCheck('Kursiv', $E8DB).SameRow := True;
  PPGRibbon1.QuickAccess.AddButton('Speichern', $E74E, rsSmall, SaveClick);
  PPGRibbon1.Backstage := BackstagePanel;
end;
```

## Verhalten (aus dem Quelltext)

TPPGRibbon - Menueband im Stil von Office (Phase 14b).

Aufbau (von oben): Schnellzugriffsleiste (wahlweise ueber oder unter dem
Band), Registerkartenzeile mit "Datei"-Button und Einklapp-Knopf, Band mit
den Gruppen der aktiven Registerkarte. Das Ribbon liegt unter der normalen
Titelleiste (kein Zeichnen im Nicht-Client-Bereich).

- Modell: PPG.Ribbon.Items (Tabs -> Groups -> Items, Actions als Quelle).
- Layout: PPG.Ribbon.Layout (reine Funktionen). Reicht die Breite nicht, schrumpfen die Gruppen in fester Reihenfolge: gross -> klein -> nur Symbol -> Gruppe als Dropdown. Die Geometrie einer Registerkarte haelt ein TPPGRibbonView; dieselbe Klasse dient dem Band, dem Popup des eingeklappten Bands und dem Popup einer geschrumpften Gruppe.
- Eingebettete Controls (Item.Control) sind Kinder des Ribbons bzw. des offenen Popups. Ihre Lage wird nie im Paint gesetzt, sondern per geposteter Nachricht (UpdateLayout erzwingt es sofort).
- KeyTips: Alt (bzw. F10) zeigt Plaketten ueber Registerkarten, "Datei" und Schnellzugriff, ein Buchstabe waehlt die Karte und zeigt die Plaketten ihrer Befehle; Esc geht eine Ebene zurueck. Die Plaketten zeichnet ein eigenes Overlay-Fenster je Monitor (auch ueber Popups). Tasten kommen ueber PPG.AppHooks, der Fokus bleibt im Formular.
- Tastatur ohne Maus: nach Alt wechseln die Pfeiltasten in die Tastaturbedienung (Fokusrahmen, Enter/Leertaste loest aus).
- Einklappen: Doppelklick auf eine Registerkarte, Strg+F1 oder der Knopf rechts; eingeklappt oeffnet ein Klick die Karte als Popup.
- Schnellzugriff anpassbar ueber das Kontextmenue (hinzufuegen, entfernen, ueber/unter dem Band); Kontext-Registerkarten farbig hervorgehoben.
- "Datei" zeigt den Backstage-Bereich (ein beliebiges Control, z.B. ein PageControl, ueber dem ganzen Formular) oder ein Anwendungsmenue.
- Code setzt Werte ohne Ereignisse; Anwenderaktionen loesen sie aus.
- Screenreader: Gruppierung "Menueband" mit Datei, Schnellzugriff, Registerkarten und den Befehlen der aktiven Karte als Kindern.

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
| `LargeImages` | `TCustomImageList` |  | Bildliste für große Symbole (32 px) der Items mit Size = rsLarge (LargeImageIndex); die kleinen Symbole kommen aus Images. |
| `Tabs` | [TPPGRibbonTabs](types/TPPGRibbonTabs.md) |  | Registerkarten des Bands; jede hat Gruppen (Groups), diese die Befehle (Items). Kontext-Registerkarten über ContextName. Nutzung: Im Designer über den Ribbon-Editor (Doppelklick); im Code `PPGRibbon1.Tabs.AddTab('Start').Groups.AddGroup('Ablage').Items.AddButton('Einfügen', $E77F);` |
| `TabIndex` | `Integer` | `0` | Index der aktiven Registerkarte in Tabs (-1 bis Tabs.Count - 1). Setzen im Code löst keine Ereignisse aus. |
| `QuickAccess` | [TPPGRibbonItems](types/TPPGRibbonItems.md) |  | Items der Schnellzugriffsleiste. Ein Eintrag mit derselben Action bzw. Beschriftung wie ein Item im Band wirkt auf dieses (QuickSource). Der Anwender passt sie über das Kontextmenü an, wenn QuickAccessCustomizable = True. Nutzung: Im Designer per Collection-Editor oder `PPGRibbon1.AddToQuickAccess(ItemSpeichern);` |
| `QuickAccessPosition` | `TPPGQuickAccessPosition` | `qapAbove` | Lage der Schnellzugriffsleiste: über den Registerkarten (qapAbove) oder unter dem Band (qapBelow). Werte: `qapAbove`, `qapBelow`. |
| `ShowQuickAccess` | `Boolean` | `True` | True: Die Schnellzugriffsleiste ist sichtbar. |
| `QuickAccessCustomizable` | `Boolean` | `True` | True: Das Kontextmenü bietet „Zum Schnellzugriff hinzufügen/entfernen" und die Lage über/unter dem Band an. |
| `ShowApplicationButton` | `Boolean` | `True` | True: Der „Datei"-Button links neben den Registerkarten ist sichtbar. |
| `ApplicationButtonCaption` | `string` |  | Beschriftung des „Datei"-Buttons links neben den Registerkarten; leer = „Datei" in der aktuellen Sprache. |
| `ApplicationMenu` | `TPopupMenu` |  | Menü, das beim Klick auf „Datei" aufklappt, wenn kein Backstage gesetzt ist. Mit TPPGPopupMenu im Stil der Suite. Nutzung: `PPGRibbon1.ApplicationMenu := PPGPopupMenu1;` |
| `Backstage` | `TControl` |  | Backstage-Bereich: ein beliebiges Control (z. B. ein PageControl oder Panel), das beim Klick auf „Datei" über das ganze Formular gelegt wird. Hat Vorrang vor ApplicationMenu; Esc oder der Zurück-Knopf schließen ihn. Nutzung: Ein Panel mit Visible = False aufs Formular legen und hier zuweisen. |
| `Minimized` | `Boolean` | `False` | True: Das Band ist eingeklappt, nur die Registerkarten sind sichtbar; ein Klick auf eine Karte öffnet sie als Popup. Umschalten auch per Doppelklick auf eine Karte, Strg+F1 oder den Knopf rechts. |
| `KeyTipsEnabled` | `Boolean` | `True` | True: Alt bzw. F10 zeigt Tasten-Plaketten (KeyTips) über Registerkarten, „Datei" und Schnellzugriff; ein Buchstabe wählt aus, Esc geht eine Ebene zurück. |

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
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. |
| `TabStop` | `Boolean` |  | True: Das Control ist mit Tab erreichbar. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` |
| `OnItemClick` | `TPPGRibbonItemEvent` `(Sender: TObject; Item: TPPGRibbonItem)` | Ein Item wurde ausgelöst (Klick, KeyTip, Tastatur, Schnellzugriff); kommt nach Item.OnClick bzw. Action.Execute. Gut für eine zentrale Behandlung aller Befehle über Item.Tag. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Die aktive Registerkarte wurde durch den Anwender gewechselt (nicht bei TabIndex im Code). |
| `OnChanging` | `TPPGRibbonTabChangingEvent` `(Sender: TObject; NewTab: TPPGRibbonTab; var AllowChange: Boolean)` | Vor einem Wechsel der Registerkarte durch den Anwender; NewTab ist das Ziel, AllowChange := False verhindert den Wechsel. |
| `OnGalleryClick` | `TPPGRibbonGalleryEvent` `(Sender: TObject; Item: TPPGRibbonItem; Index: Integer)` | Ein Galerie-Eintrag wurde gewählt (in der Leiste oder in der aufgeklappten Galerie); Index ist der Eintrag, Item.GalleryIndex ist schon gesetzt. |
| `OnGetGalleryItem` | `TPPGRibbonGetGalleryItemEvent` `(Sender: TObject; Item: TPPGRibbonItem; Index: Integer; var Data: TPPGItemData; var Color: TColor)` | Liefert den Inhalt eines virtuellen Galerie-Eintrags (Item.GalleryCount > 0): Data mit Text, Bild usw. füllen; Color setzt optional ein Farbfeld. Nutzung: `Data.Text := Vorlagen[Index].Name;` |
| `OnCustomDrawGalleryItem` | `TPPGRibbonDrawGalleryItemEvent` `(Sender: TObject; Item: TPPGRibbonItem; Index: Integer; Canvas: TCanvas; const Rect: TRect; Selected, Hot: Boolean; var Handled: Boolean)` | Eigenes Zeichnen eines Galerie-Eintrags: Item ist die Galerie, Index der Eintrag, Canvas/Rect die Zeichenfläche, Selected/Hot der Zustand. Handled := True ersetzt das Standard-Zeichnen. Nutzung: Für Vorschauen wie Formatvorlagen oder Farbfelder. |
| `OnLauncherClick` | `TPPGRibbonGroupEvent` `(Sender: TObject; Group: TPPGRibbonGroup)` | Der kleine Pfeil unten rechts in einer Gruppe (Dialog-Starter) wurde geklickt; Group ist die Gruppe. Nutzung: Typisch: den passenden Einstellungsdialog öffnen. |
| `OnMinimizedChange` | `TNotifyEvent` `(Sender: TObject)` | Minimized wurde durch den Anwender umgeschaltet. |
| `OnQuickAccessChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat den Schnellzugriff geändert (hinzugefügt, entfernt, geladen). Nutzung: Hier `SaveQuickAccess` aufrufen und das Ergebnis z. B. in einer INI-Datei speichern. |
| `OnApplicationButtonClick` | `TNotifyEvent` `(Sender: TObject)` | Der „Datei"-Button wurde geklickt; kommt vor dem Öffnen von Backstage bzw. ApplicationMenu. |
| `OnBackstageChange` | `TNotifyEvent` `(Sender: TObject)` | Der Backstage-Bereich wurde ein- oder ausgeblendet (Abfrage über BackstageVisible). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. |
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
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGRibbon.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
