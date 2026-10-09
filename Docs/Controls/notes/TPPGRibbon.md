**Vorbild:** TMS AdvToolBar / Office-Ribbon, Windows Ribbon Framework

## Unterschiede und Hinweise

- Aufbau: `Tabs` → `Groups` → `Items`, alles im Objektinspektor und in der DFM pflegbar. Das Ribbon liegt unter der normalen Titelleiste (kein Zeichnen im Nicht-Client-Bereich, damit VCL-Styles, DPI und Snap-Layouts funktionieren).
- Item-Arten (`Kind`): Button, Split-Button (`DropDownMenu`), Umschalt-Button (`Down`, `GroupIndex` gilt im ganzen Ribbon), Galerie, eingebettetes Control (`Control`, z. B. eine `TPPGComboBox`; das Ribbon wird ihr Parent) und Trenner.
- Größe: `Size` (groß = Symbol über Text, mittel = kleines Symbol mit Text, klein = nur Symbol) und `MinSize`. Kleine Items stapeln sich zu drei Zeilen; `BeginColumn` beginnt einen neuen Stapel, `SameRow` stellt ein Item rechts neben das vorige (z. B. Fett, Kursiv, Unterstrichen in einer Zeile).
- Symbole: `ImageIndex` aus `Images` (16 px), `LargeImageIndex` aus `LargeImages` (32 px) oder `IconChar` (Zeichen der Symbolschrift, z. B. `$E8C8` für Kopieren).
- **Schrumpfen:** Passt die Breite nicht, schrumpfen die Gruppen in fester Reihenfolge: erst alle auf „mittel“, dann „nur Symbol“, dann „als Dropdown“. Innerhalb einer Stufe zuerst die Gruppen mit kleinerem `ReduceOrder`, bei Gleichstand von rechts. Ein Schritt, der eine Gruppe nicht schmaler macht, wird übersprungen; eine Gruppe aus lauter kleinen Items wird deshalb nicht zum Dropdown, wenn das Dropdown breiter wäre. Die Galerie zeigt erst weniger Spalten, dann einen Dropdown-Button.
- Eine als Dropdown geschrumpfte Gruppe öffnet ein Popup mit der voll aufgeklappten Gruppe; eingebettete Controls wandern mit. Symbol der geschrumpften Gruppe: `ImageIndex`/`IconChar` der Gruppe, sonst das erste Item mit Symbol.
- `ShowLauncher` zeigt unten rechts in der Gruppe den Startknopf für einen Dialog (`OnLauncherClick`).
- Galerie: Einträge aus `GalleryItems` oder virtuell (`GalleryCount` + `OnGetGalleryItem`, auch mit Farbfeld), eigenes Zeichnen über `OnDrawGalleryItem`. In der Leiste blättern die Pfeile rechts zeilenweise (auch mit dem Mausrad), der untere klappt die Galerie auf (Pfeile, Enter, Esc). Auswahl: `GalleryIndex`, `OnGalleryClick`. **Kategorien:** Einträge als „Kategorie|Text“ oder `Data.Group` in `OnGetGalleryItem`; die aufgeklappte Galerie zeigt je Kategorie eine Überschrift und beginnt eine neue Zeile, die Pfeile halten die Spalte und überspringen die Überschriften.
- **Actions** (`Item.Action`) liefern Caption, Hint, Enabled, Checked, Visible, ImageIndex und OnExecute, wie bei Menü und ToolBar.
- **KeyTips:** Alt bzw. F10 zeigt Plaketten über „Datei“, Schnellzugriff (1, 2, …) und Registerkarten; Alt+Buchstabe springt direkt in eine Karte. Danach zeigen die Befehle der Karte ihre Plaketten; Esc geht eine Ebene zurück. Vergeben werden sie automatisch aus der Beschriftung (`&`-Buchstabe, Wortanfänge, sonst zwei Zeichen); eigene über `KeyTip`. Die Plaketten zeichnet ein eigenes Overlay-Fenster je Monitor, auch über Popups.
- **Tastatur ohne Maus:** Nach Alt wechseln die Pfeiltasten in die Tastaturbedienung (Fokusrahmen; links/rechts innerhalb der Zeile, hoch/runter zwischen Karten und Band, Enter/Leertaste löst aus, Esc verlässt). Die Tastatur reicht bis in aufgeklappte Gruppen und Karten des eingeklappten Bands: Enter öffnet das Popup mit dem Fokus auf dem ersten Befehl, Tab und Pfeile bleiben darin, Esc geht eine Ebene zurück. Nach einem Öffnen mit der Maus führt ein Pfeil in das Popup.
- **Einklappen:** `Minimized`, Doppelklick auf eine Registerkarte, Strg+F1 oder der Knopf rechts. Eingeklappt öffnet ein Klick auf eine Karte sie als Popup.
- **Schnellzugriff:** `QuickAccess` (über oder unter dem Band, `QuickAccessPosition`). Rechtsklick auf einen Befehl fügt ihn hinzu, Rechtsklick im Schnellzugriff entfernt ihn (`QuickAccessCustomizable`, `OnQuickAccessChange`). Ein Schnellzugriff-Item wirkt auf das Item im Band mit gleicher Action bzw. gleicher Beschriftung, Art und Symbol (`QuickSource`).
- **Kontext-Registerkarten:** `ContextName` und `ContextColor` (farbige Leiste und Tönung). Die Anwendung schaltet `Visible` und `TabIndex` je nach Auswahl.
- **Datei:** Ist `Backstage` gesetzt (ein beliebiges Control, z. B. ein Panel oder PageControl), legt „Datei“ es über das ganze Formular bzw. seinen Parent; Esc oder `HideBackstage` schließt. Ohne Backstage öffnet „Datei“ `ApplicationMenu`. Vorher kommt immer `OnApplicationButtonClick`.
- Code setzt Werte ohne Ereignisse (`TabIndex`, `Minimized`, `Down`, `GalleryIndex`); Anwenderaktionen lösen `OnTabChanging`/`OnTabChange`, `OnItemClick`, `OnGalleryClick`, `OnMinimizedChange` usw. aus.
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
