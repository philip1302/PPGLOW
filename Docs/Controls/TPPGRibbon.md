# TPPGRibbon

Palette **PPGlow** - Unit `PPG.Ribbon` - Basis `TPPGCustomRibbon`

**Vorbild:** TMS AdvToolBar / Office-Ribbon, Windows Ribbon Framework

## Wofür

Das Ribbon ist das Menüband am oberen Rand des Hauptfensters: Registerkarten mit Gruppen von Befehlen, dazu „Datei", Schnellzugriff und Kontext-Registerkarten wie in Office. Es ersetzt Hauptmenü und Symbolleisten in Anwendungen mit vielen Befehlen, z. B. Belegerfassung, Berichts- oder Texteditoren. Bei schmalem Fenster schrumpft es selbst, und mit Alt bzw. F10 ist es vollständig per Tastatur bedienbar.

## Wann verwenden

- Für das Hauptfenster einer Anwendung mit vielen Befehlen, die sich thematisch auf Karten verteilen lassen (Start, Einfügen, Ansicht).
- Statt `TPPGToolBar`, wenn es mehr als eine Leiste voll Befehle gibt oder Galerien, eingebettete Felder und große Hauptbefehle gebraucht werden. Für eine einzelne Leiste über einer Liste oder in einem Dialog ist die ToolBar schlanker.
- Statt `TPPGMenuBar`, wenn die Anwender Office gewohnt sind und Befehle sichtbar statt in Menüs versteckt sein sollen. Für klassische Programme mit wenigen Befehlen bleibt die Menüleiste kompakter.
- Nicht für Navigation zwischen Bereichen der Anwendung: Dafür sind `TPPGNavigationView` oder `TPPGTabControl` gedacht. Die Registerkarten des Ribbons wechseln nur die Befehle, nicht den Inhalt.
- Nicht in kleinen Dialogen: Dort genügen einzelne `TPPGButton`.

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
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Das Standard-Preset wird nicht in der DFM gespeichert. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. Praxis: Passend zur übrigen Anwendung wählen: Fluent11 für Windows-11-Optik, ModernFlat flach, Classic im Office-2010-Stil. Am bequemsten über den StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. Praxis: Den gemeinsamen TPPGStyleManager zuweisen, dann wechselt das Band mit Hell/Dunkel und Preset der ganzen Anwendung. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. In der DFM stehen nur die Werte, die vom Preset abweichen; der Rest kommt beim Laden aus dem Preset. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` Praxis: Selten einzeln ändern: Farben und Rundung der Befehle kommen am besten aus Preset bzw. StyleManager, damit das Band zum Rest der Anwendung passt. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. Praxis: Vorgaben lassen; die Übergänge beim Überfahren der Befehle wirken dann wie in Office. Ausschalten nur für sehr langsame Remote-Desktop-Sitzungen. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). Praxis: True lassen: Im Hochkontrastmodus von Windows zeigt das Band Systemfarben und bleibt für sehbehinderte Anwender lesbar. |
| `Images` | `TCustomImageList` |  | Bildliste für ImageIndex bzw. ImageName (TImageList, TVirtualImageList, SVG-Bildlisten). Praxis: Die gemeinsame ImageList (16 px) der Anwendung zuweisen, dieselbe wie bei Menüs und Actions. Ohne Bildliste genügen IconChar-Symbole aus der Symbolschrift. |
| `LargeImages` | `TCustomImageList` |  | Bildliste für große Symbole (32 px) der Items mit Size = rsLarge (LargeImageIndex); die kleinen Symbole kommen aus Images. Praxis: Eine zweite ImageList mit 32-px-Bildern für große Befehle (Size = rsLarge, LargeImageIndex). Ohne sie werden die kleinen Bilder bzw. IconChar vergrößert. |
| `Tabs` | [TPPGRibbonTabs](types/TPPGRibbonTabs.md) |  | Registerkarten des Bands; jede hat Gruppen (Groups), diese die Befehle (Items). Kontext-Registerkarten über ContextName. Nutzung: Im Designer über den Ribbon-Editor (Doppelklick); im Code `PPGRibbon1.Tabs.AddTab('Start').Groups.AddGroup('Ablage').Items.AddButton('Einfügen', $E77F);` Praxis: Im Designer per Doppelklick bzw. „Edit tabs…" pflegen; im Code mit Tabs.AddTab, Groups.AddGroup und Items.AddButton aufbauen. Pro Karte nicht mehr als fünf bis sechs Gruppen. |
| `TabIndex` | `Integer` | `0` | Index der aktiven Registerkarte in Tabs (-1 bis Tabs.Count - 1). Setzen im Code löst keine Ereignisse aus. Praxis: Im Code die passende Karte zeigen, z. B. nach dem Markieren einer Tabelle die Kontext-Registerkarte. Löst kein OnChange aus. |
| `QuickAccess` | [TPPGRibbonItems](types/TPPGRibbonItems.md) |  | Items der Schnellzugriffsleiste. Ein Eintrag mit derselben Action bzw. Beschriftung wie ein Item im Band wirkt auf dieses (QuickSource). Der Anwender passt sie über das Kontextmenü an, wenn QuickAccessCustomizable = True. Nutzung: Im Designer per Collection-Editor oder `PPGRibbon1.AddToQuickAccess(ItemSpeichern);` Praxis: Die zwei, drei häufigsten Befehle (Speichern, Rückgängig) hier eintragen, am besten mit derselben Action wie im Band; dann wirkt der Eintrag auf denselben Befehl. |
| `QuickAccessPosition` | `TPPGQuickAccessPosition` | `qapAbove` | Lage der Schnellzugriffsleiste: über den Registerkarten (qapAbove) oder unter dem Band (qapBelow). Werte: `qapAbove`, `qapBelow`. Praxis: qapAbove wie in Office; qapBelow, wenn der Schnellzugriff näher am Arbeitsbereich liegen soll. Den Wunsch des Anwenders mit speichern. |
| `ShowQuickAccess` | `Boolean` | `True` | True: Die Schnellzugriffsleiste ist sichtbar. Praxis: Ausblenden in kleinen Fenstern mit wenigen Befehlen; dort genügt das Band. |
| `QuickAccessCustomizable` | `Boolean` | `True` | True: Das Kontextmenü bietet „Zum Schnellzugriff hinzufügen/entfernen" und die Lage über/unter dem Band an. Praxis: True, damit Anwender per Rechtsklick eigene Befehle in den Schnellzugriff legen. In OnQuickAccessChange mit SaveQuickAccess speichern. |
| `ShowApplicationButton` | `Boolean` | `True` | True: Der „Datei"-Button links neben den Registerkarten ist sichtbar. Praxis: True, wenn es Datei-Befehle gibt (Backstage oder ApplicationMenu). Bei reinen Werkzeugleisten ohne Dateien ausblenden. |
| `ApplicationButtonCaption` | `string` |  | Beschriftung des „Datei"-Buttons links neben den Registerkarten; leer = „Datei" in der aktuellen Sprache. Praxis: Leer lassen, dann steht dort „Datei" in der Sprache der Anwendung. Einen eigenen Text nur, wenn das Menü dahinter anders heißt, z. B. „Mandant" oder „Projekt". |
| `ApplicationMenu` | `TPopupMenu` |  | Menü, das beim Klick auf „Datei" aufklappt, wenn kein Backstage gesetzt ist. Mit TPPGPopupMenu im Stil der Suite. Nutzung: `PPGRibbon1.ApplicationMenu := PPGPopupMenu1;` Praxis: Für einfache Programme statt eines Backstage: ein TPPGPopupMenu mit Neu, Öffnen, Drucken und Beenden anlegen und hier zuweisen. |
| `Backstage` | `TControl` |  | Backstage-Bereich: ein beliebiges Control (z. B. ein PageControl oder Panel), das beim Klick auf „Datei" über das ganze Formular gelegt wird. Hat Vorrang vor ApplicationMenu; Esc oder der Zurück-Knopf schließen ihn. Nutzung: Ein Panel mit Visible = False aufs Formular legen und hier zuweisen. Praxis: Für „Datei"-Seiten wie in Office (Zuletzt verwendet, Drucken, Optionen): ein Panel oder PageControl mit Visible = False aufs Formular legen und hier zuweisen. |
| `Minimized` | `Boolean` | `False` | True: Das Band ist eingeklappt, nur die Registerkarten sind sichtbar; ein Klick auf eine Karte öffnet sie als Popup. Umschalten auch per Doppelklick auf eine Karte, Strg+F1 oder den Knopf rechts. Praxis: Den Zustand beim Beenden speichern und beim Start wiederherstellen; Anwender mit kleinen Bildschirmen klappen das Band gern ein (Strg+F1). |
| `KeyTipsEnabled` | `Boolean` | `True` | True: Alt bzw. F10 zeigt Tasten-Plaketten (KeyTips) über Registerkarten, „Datei" und Schnellzugriff; ein Buchstabe wählt aus, Esc geht eine Ebene zurück. Praxis: True lassen: Tastaturnutzer bedienen das Band mit Alt und Buchstaben wie in Office. Ausschalten nur, wenn Alt+Buchstabe schon von der Anwendung belegt ist. |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` | `alTop` | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. Praxis: alTop lassen: Das Menüband gehört an den oberen Rand des Hauptfensters, direkt unter die Titelleiste. Andere Werte nur, wenn es in einem Panel über einem Teilbereich liegt. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` Praxis: Nur bei Align = alNone wichtig: [akLeft, akTop, akRight], damit das Band beim Vergrößern des Fensters mitwächst und die Gruppen wieder aufklappen. |
| `AutoSize` | `Boolean` | `True` | True: Das Control passt seine Größe dem Inhalt an (Text, Bild, Schrift). Praxis: True lassen: Die Höhe ergibt sich aus Schrift, Schnellzugriff und Einklappen. Beim Einklappen (Minimized) rückt der Inhalt darunter dann automatisch nach oben. |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. Praxis: Nur für arabische oder hebräische Oberflächen ändern; dann spiegelt sich das ganze Band samt Datei-Button und Schnellzugriff. Am besten über ParentBiDiMode vom Formular. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` Praxis: MinWidth setzen, wenn das Hauptfenster nicht so schmal werden soll, dass alle Gruppen nur noch Dropdowns sind (z. B. 480). |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. Praxis: Für Phasen, in denen nichts bedient werden darf (z. B. während eines langen Imports), das ganze Band sperren. Einzelne Befehle sperren Sie über Item.Enabled oder die Action. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` Praxis: Über ParentFont die Formularschrift übernehmen (Segoe UI 9). Eine größere Schrift (z. B. 11) macht das Band für Touch-Arbeitsplätze höher. |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. Praxis: True lassen, damit das Band der Leserichtung des Formulars folgt. |
| `ParentFont` | `Boolean` |  | True: Font wird vom Parent übernommen; wird automatisch False, sobald Font geändert wird. Praxis: True lassen, damit das Band die Schrift des Hauptfensters trägt. |
| `ParentShowHint` | `Boolean` |  | True: ShowHint wird vom Parent übernommen (meist vom Formular). Praxis: True lassen und ShowHint am Formular einschalten, dann zeigen alle Befehle ihre Tooltips. |
| `PopupMenu` | `TPopupMenu` |  | Kontextmenü bei Rechtsklick bzw. Umschalt+F10. Funktioniert mit TPopupMenu und TPPGPopupMenu. Praxis: Meist leer lassen: Das Ribbon bringt ein eigenes Kontextmenü mit (Schnellzugriff anpassen, Band einklappen). |
| `ShowHint` | `Boolean` |  | True: Hint wird als Tooltip angezeigt. Praxis: Am Formular einschalten statt hier; die Tooltips der Befehle sind für Symbol-Befehle ohne Text wichtig. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. Praxis: Für einen Vollbild- oder Lesemodus das ganze Band ausblenden; sonst lieber Minimized, dann bleiben die Registerkarten sichtbar. |
| `Touch` | `TTouchManager` |  | Gesten und Touch-Einstellungen (Gestures, InteractiveGestures, GestureManager). Wirkt zusammen mit OnGesture. Nutzung: Im Objektinspektor unter Touch.Gestures Standardgesten (z. B. Wischen links) anhaken und in OnGesture auswerten. Praxis: Nur für Touch-Geräte: Gesten anhaken und in OnGesture auswerten. Für die Bedienung der Befehle nicht nötig. |
| `StyleElements` | `TStyleElements` |  | Welche Teile ein aktiver VCL-Style färbt (seFont, seClient, seBorder). Ohne seClient behält ein PPGlow-Control seine eigenen Farben aus Appearance. Praxis: Nur bei VCL-Styles wichtig: seClient herausnehmen, wenn das Band seine Preset-Farben behalten soll. |
| `DragMode` | `TDragMode` |  | dmAutomatic: Ziehen beginnt automatisch mit der Maus; dmManual: per Code mit BeginDrag. Praxis: dmManual lassen: Mit dmAutomatic würde jeder Klick auf einen Befehl ein Ziehen beginnen. |
| `DragCursor` | `TCursor` |  | Mauszeiger während das Control gezogen wird (Drag & Drop). Praxis: Beim Ribbon ohne Bedeutung, solange DragMode = dmManual bleibt. |
| `Color` | `TColor` |  | Hintergrundfarbe des Controls. Bei PPGlow-Controls gilt sie nur ohne Dark Mode, VCL-Style und Hochkontrast; die Flächenfarben der Zustände stehen in Appearance. Nutzung: `clWindow`, `clBtnFace` oder eine RGB-Farbe wie `$00F0F0F0`. Praxis: Beim Ribbon kaum nötig: Hintergrund und Registerkarten färbt das Preset. Color wirkt nur ohne Dark Mode und VCL-Style. |
| `ParentColor` | `Boolean` |  | True: Color wird vom Parent übernommen. Praxis: False lassen; die Flächenfarbe kommt aus dem Preset. |
| `DoubleBuffered` | `Boolean` |  | Zeichnen über einen Puffer gegen Flackern. PPGlow-Controls puffern immer selbst; die Property ist da, damit Formulare aus der VCL laden, und bewirkt nur einen zweiten Puffer. Das innere Edit der Eingabefelder übernimmt sie nicht. Praxis: Nicht nötig, das Ribbon zeichnet immer gepuffert. Steht nur da, damit alte Formulare ohne Fehler laden. |
| `ParentDoubleBuffered` | `Boolean` |  | True: DoubleBuffered wird vom Parent übernommen. Praxis: True lassen; ohne sichtbare Wirkung. |
| `TabStop` | `Boolean` |  | True: Das Control ist mit Tab erreichbar. Praxis: False lassen: Das Band erreicht man über Alt/F10 (KeyTips), nicht über Tab, damit Tab im Formular von Feld zu Feld springt. |
| `AlignWithMargins` | `Boolean` |  | True: Beim Ausrichten (Align) gelten die Abstände aus Margins. Nutzung: `Edit1.AlignWithMargins := True; Edit1.Margins.SetBounds(8, 4, 8, 4);` Praxis: Meist aus lassen, das Band soll bündig am Fensterrand sitzen. Einschalten, wenn es in einer Karte oder einem Panel mit Abstand zum Rand liegt. |
| `Left` | `Integer` |  | Linke Kante relativ zum Parent in Pixeln. Praxis: Bei Align = alTop ohne Wirkung; nur bei alNone im Designer per Maus. |
| `Top` | `Integer` |  | Obere Kante relativ zum Parent in Pixeln. Praxis: Bei Align = alTop ohne Wirkung. |
| `Width` | `Integer` |  | Breite in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Bei Align = alTop bestimmt das Fenster die Breite. Wird es schmal, schrumpfen die Gruppen von selbst (ReduceOrder). |
| `Height` | `Integer` |  | Höhe in Pixeln (bei hoher DPI skaliert die VCL beim Laden). Praxis: Nicht von Hand setzen: Mit AutoSize bestimmt das Ribbon seine Höhe selbst (Schnellzugriff, Registerkarten, Band). |
| `Cursor` | `TCursor` |  | Mauszeiger über dem Control. Nutzung: `crHandPoint` für klickbare Flächen. Praxis: crDefault lassen; Office zeigt über dem Band den normalen Pfeil. |
| `Hint` | `string` |  | Kurzinfo beim Verweilen der Maus. Wird nur gezeigt, wenn ShowHint (oder ParentShowHint mit ShowHint am Formular) True ist. Text vor "\|" = Tooltip, danach = Langtext für die Statusleiste. Nutzung: `Button1.Hint := 'Dokument speichern\|Speichert das Dokument unter dem bisherigen Namen';` Praxis: Für das Band selbst selten nötig; die Tooltips stehen an den Befehlen (Item.Hint bzw. Action.Hint). |
| `HelpType` | `THelpType` |  | Ob F1 HelpContext (htContext) oder HelpKeyword (htKeyword) verwendet. Praxis: htKeyword bei HTML-Hilfen mit Stichwörtern, sonst htContext. Ohne Hilfedatei egal. |
| `HelpKeyword` | `string` |  | Stichwort für die Hilfe (F1), wenn HelpType = htKeyword. Praxis: Wie HelpContext, aber als Stichwort (HelpType = htKeyword), z. B. „Menüband". |
| `HelpContext` | `THelpContext` |  | Kontext-ID für die Hilfe (F1). Praxis: Kontext-ID der Hilfeseite „Menüband", die F1 zeigt, solange das Ribbon den Fokus hat. Ohne Hilfedatei egal. |
| `Margins` | `TMargins` |  | Außenabstände für das Ausrichten; wirken nur mit AlignWithMargins = True. Praxis: Mit AlignWithMargins: Abstand zum Rand, wenn das Band in einer Karte liegt, z. B. 8 rundum. |
| `CustomHint` | `TCustomHint` |  | Eigenes Hint-Objekt (z. B. TBalloonHint) statt des Standard-Tooltips. Praxis: Für Tooltips mit Titel: einen TPPGCustomHint zuweisen. Die Befehle zeigen dann Caption als Titel und Hint als Text. |
| `ParentCustomHint` | `Boolean` |  | True: CustomHint wird vom Parent übernommen. Praxis: True lassen, damit ein am Formular gesetzter CustomHint auch für die Befehle im Band gilt. |
| `Name` | `TComponentName` |  | Name der Komponente im Formular; daraus wird das Feld in der Formular-Klasse (PPGButton1) und der Bezug in der DFM. Muss ein gültiger Pascal-Bezeichner und im Formular eindeutig sein. Nutzung: `PPGButton1.Name := 'btnSpeichern';` (meist nur im Objektinspektor ändern) Praxis: Sprechend benennen, z. B. rbnHaupt; im Code greifen Sie über den Namen auf Tabs und Schnellzugriff zu. |
| `Tag` | `NativeInt` |  | Freier Ganzzahlwert für eigene Zwecke (z. B. eine ID oder einen Zeiger). Praxis: Freier Wert, z. B. um mehrere Ribbons (Haupt- und Editorfenster) in gemeinsamen Handlern zu unterscheiden. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnGesture` | `TGestureEvent` `(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)` | Eine Touch- oder Mausgeste wurde erkannt (siehe Touch). EventInfo.GestureID nennt die Geste; Handled := True beendet die Standardbehandlung. Nutzung: `if EventInfo.GestureID = sgiLeft then NaechsteSeite;` Praxis: Auf Touch-Geräten z. B. Wischen nach links/rechts zum Wechseln der Registerkarte auswerten. |
| `OnItemClick` | `TPPGRibbonItemEvent` `(Sender: TObject; Item: TPPGRibbonItem)` | Ein Item wurde ausgelöst (Klick, KeyTip, Tastatur, Schnellzugriff); kommt nach Item.OnClick bzw. Action.Execute. Gut für eine zentrale Behandlung aller Befehle über Item.Tag. Praxis: Zentrale Stelle für alle Befehle ohne eigene Action: über Item.Tag eine Befehls-ID auswerten, z. B. für Protokoll oder Rechteprüfung. |
| `OnChange` | `TNotifyEvent` `(Sender: TObject)` | Die aktive Registerkarte wurde durch den Anwender gewechselt (nicht bei TabIndex im Code). Praxis: Auf den Wechsel der Registerkarte durch den Anwender reagieren, z. B. die Statusleiste anpassen oder die Wahl für den nächsten Start merken. |
| `OnChanging` | `TPPGRibbonTabChangingEvent` `(Sender: TObject; NewTab: TPPGRibbonTab; var AllowChange: Boolean)` | Vor einem Wechsel der Registerkarte durch den Anwender; NewTab ist das Ziel, AllowChange := False verhindert den Wechsel. Praxis: Einen Kartenwechsel verhindern (AllowChange := False), solange etwas nicht abgeschlossen ist, z. B. eine Eingabe in einem eingebetteten Feld ungültig ist. |
| `OnGalleryClick` | `TPPGRibbonGalleryEvent` `(Sender: TObject; Item: TPPGRibbonItem; Index: Integer)` | Ein Galerie-Eintrag wurde gewählt (in der Leiste oder in der aufgeklappten Galerie); Index ist der Eintrag, Item.GalleryIndex ist schon gesetzt. Praxis: Die gewählte Vorlage anwenden: Index ist der Eintrag, Item die Galerie. Bei mehreren Galerien über Item (oder Item.Tag) unterscheiden. |
| `OnGetGalleryItem` | `TPPGRibbonGetGalleryItemEvent` `(Sender: TObject; Item: TPPGRibbonItem; Index: Integer; var Data: TPPGItemData; var Color: TColor)` | Liefert den Inhalt eines virtuellen Galerie-Eintrags (Item.GalleryCount > 0): Data mit Text, Bild usw. füllen; Color setzt optional ein Farbfeld. Nutzung: `Data.Text := Vorlagen[Index].Name;` Praxis: Für Galerien mit Daten aus der Anwendung (Vorlagen aus der Datenbank, Farben): GalleryCount setzen und hier Data.Text bzw. Color je Index füllen. |
| `OnCustomDrawGalleryItem` | `TPPGRibbonDrawGalleryItemEvent` `(Sender: TObject; Item: TPPGRibbonItem; Index: Integer; Canvas: TCanvas; const Rect: TRect; Selected, Hot: Boolean; var Handled: Boolean)` | Eigenes Zeichnen eines Galerie-Eintrags: Item ist die Galerie, Index der Eintrag, Canvas/Rect die Zeichenfläche, Selected/Hot der Zustand. Handled := True ersetzt das Standard-Zeichnen. Nutzung: Für Vorschauen wie Formatvorlagen oder Farbfelder. Praxis: Für Vorschaubilder in einer Galerie (Farbschema, Tabellenvorlage, Diagrammtyp): selbst auf Canvas zeichnen und Handled := True setzen. |
| `OnLauncherClick` | `TPPGRibbonGroupEvent` `(Sender: TObject; Group: TPPGRibbonGroup)` | Der kleine Pfeil unten rechts in einer Gruppe (Dialog-Starter) wurde geklickt; Group ist die Gruppe. Nutzung: Typisch: den passenden Einstellungsdialog öffnen. Praxis: Den Einstellungsdialog der Gruppe öffnen, z. B. „Seite einrichten" bei der Gruppe Seite. Über Group (oder Group.Tag) unterscheiden. |
| `OnMinimizedChange` | `TNotifyEvent` `(Sender: TObject)` | Minimized wurde durch den Anwender umgeschaltet. Praxis: Den Zustand Minimized speichern, damit das Band beim nächsten Start wieder ein- oder ausgeklappt ist. |
| `OnQuickAccessChange` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat den Schnellzugriff geändert (hinzugefügt, entfernt, geladen). Nutzung: Hier `SaveQuickAccess` aufrufen und das Ergebnis z. B. in einer INI-Datei speichern. Praxis: Hier SaveQuickAccess aufrufen und das Ergebnis in INI-Datei oder Registry schreiben; beim Start mit LoadQuickAccess laden. |
| `OnApplicationButtonClick` | `TNotifyEvent` `(Sender: TObject)` | Der „Datei"-Button wurde geklickt; kommt vor dem Öffnen von Backstage bzw. ApplicationMenu. Praxis: Hier die Backstage-Seite vorbereiten, bevor sie erscheint, z. B. die Liste „Zuletzt verwendet" neu füllen. |
| `OnBackstageChange` | `TNotifyEvent` `(Sender: TObject)` | Der Backstage-Bereich wurde ein- oder ausgeblendet (Abfrage über BackstageVisible). Praxis: Den Arbeitsbereich darunter sperren bzw. wieder freigeben oder beim Schließen des Backstage den Fokus zurück ins Dokument setzen (BackstageVisible abfragen). |
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Klick mit der linken Maustaste, Leertaste/Enter bei Buttons oder Auslösen per Zugriffstaste. Bei Listen, Baum, Grid, Auswahlgruppen und Aufklapp-Auswahlfeldern (ComboBox, ColorPicker, ColumnComboBox, CheckComboBox) meldet OnClick wie in der VCL die Auswahl durch den Anwender. Praxis: Selten gebraucht; für Befehle ist OnItemClick bzw. Item.OnClick der richtige Ort. OnClick kommt bei jedem Klick auf die Fläche des Bands. |
| `OnDblClick` | `TNotifyEvent` `(Sender: TObject)` | Doppelklick mit der linken Maustaste. Controls, bei denen schnelle Klicks einzeln zählen (Button, CheckBox, ToggleSwitch, Rating, ToolBar …), haben es wie TButton nicht. Praxis: Selten gebraucht; der Doppelklick auf eine Registerkarte klappt das Band schon von selbst ein. |
| `OnMouseDown` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control gedrückt. Praxis: Selten; Befehle gehören in Item.OnClick bzw. OnItemClick. |
| `OnMouseMove` | `TMouseMoveEvent` `(Sender: TObject; Shift: TShiftState; X, Y: Integer)` | Maus über dem Control bewegt. Praxis: Selten; Tooltips der Befehle zeigt das Ribbon selbst. |
| `OnMouseUp` | `TMouseEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)` | Maustaste über dem Control losgelassen. Praxis: Selten; Befehle gehören in Item.OnClick bzw. OnItemClick. |
| `OnMouseEnter` | `TNotifyEvent` `(Sender: TObject)` | Die Maus ist in das Control hineinbewegt worden. Praxis: Z. B. eine Hilfezeile in der Statusleiste zeigen, sobald die Maus über dem Band ist. |
| `OnMouseLeave` | `TNotifyEvent` `(Sender: TObject)` | Die Maus hat das Control verlassen. Praxis: Gegenstück zu OnMouseEnter: die Hilfezeile wieder leeren. |
| `OnMouseWheel` | `TMouseWheelEvent` `(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)` | Mausrad gedreht; Handled := True verhindert das Standard-Scrollen. Praxis: Mit Handled := True verhindern, dass das Mausrad über einer Galerie im Band deren Zeilen blättert, z. B. in einer Anwendung, die das Rad global für den Zoom nutzt. |
| `OnMouseActivate` | `TMouseActivateEvent` `(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)` | Mausklick auf ein noch inaktives Fenster; legt fest, ob es aktiviert wird. Praxis: Nicht belegen; nur für Spezialfälle wie Werkzeugfenster. |
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. Praxis: Mit Handled := True das eingebaute Kontextmenü (Schnellzugriff, Einklappen) unterdrücken, z. B. in einer gesperrten Kiosk-Anwendung. |
| `OnDragDrop` | `TDragDropEvent` `(Sender, Source: TObject; X, Y: Integer)` | Ein gezogenes Objekt wurde über dem Control losgelassen. Nutzung: Source ist das gezogene Control; X, Y die Position im Control. Praxis: Beim Ribbon kaum gebraucht; denkbar zum Ablegen von Dateien auf das Band, die dann geöffnet werden. |
| `OnDragOver` | `TDragOverEvent` `(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)` | Ein Objekt wird über dem Control gezogen; Accept := True erlaubt das Ablegen. Praxis: Zusammen mit OnDragDrop: Accept nur für passende Quellen setzen. |
| `OnStartDrag` | `TStartDragEvent` `(Sender: TObject; var DragObject: TDragObject)` | Beginn des Ziehens dieses Controls; hier kann ein eigenes DragObject gesetzt werden. Praxis: Beim Ribbon kaum gebraucht. |
| `OnEndDrag` | `TEndDragEvent` `(Sender, Target: TObject; X, Y: Integer)` | Ziehen dieses Controls beendet (abgelegt oder abgebrochen; Target = nil bei Abbruch). Praxis: Beim Ribbon kaum gebraucht, das Band selbst wird nicht gezogen. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. Praxis: Selten; das Band nimmt den Fokus nur bei der Tastaturbedienung (Alt, Pfeiltasten). |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. Praxis: Selten; z. B. eine Statuszeile mit Tastenhinweisen wieder leeren, wenn die Tastaturbedienung des Bands endet. |
| `OnKeyDown` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste gedrückt (auch Sondertasten wie Pfeile, F-Tasten); Key := 0 verwirft sie. Nutzung: `if Key = VK_RETURN then Speichern;` Praxis: Selten; die Tastaturbedienung (Pfeile, Enter, Esc) erledigt das Ribbon selbst. |
| `OnKeyPress` | `TKeyPressEvent` `(Sender: TObject; var Key: Char)` | Zeichen eingegeben; Key := #0 verwirft es. Praxis: Selten; Buchstaben nach Alt wertet das Ribbon als KeyTips aus. |
| `OnKeyUp` | `TKeyEvent` `(Sender: TObject; var Key: Word; Shift: TShiftState)` | Taste losgelassen. Praxis: Selten für das Ribbon. |

Tests: `PPG.Tests.Audit11C` (TAudit11CGdiTests); `PPG.Tests.Audit45` (TNamingTests); `PPG.Tests.Audit5d` (TStage3Tests); `PPG.Tests.Audit8D` (TAudit8DCountTests, TAudit8DTests); `PPG.Tests.Custom` (TCustomRestTests); `PPG.Tests.Phase14bRibbon` (TRibbonTests); `PPG.Tests.Phase20` (TRibbonPopupKeyTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGRibbon.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
