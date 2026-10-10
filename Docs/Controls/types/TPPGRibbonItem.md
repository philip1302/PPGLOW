# TPPGRibbonItem

Typ in Unit `PPG.Ribbon.Items` - Basis `TCollectionItem`

Ein Befehl im Ribbon: Art, Größe, Bild bzw. Symbol, Beschriftung, Action, Umschaltzustand, Galerie-Einträge oder eingebettetes Control.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Action` | `TBasicAction` |  | Verknüpfte Action: Beschriftung, Hint, Enabled, Checked, Bild und Ausführen kommen aus ihr. Im Schnellzugriff dient die Action als Schlüssel (SaveQuickAccess). Praxis: Für Befehle, die auch im Menü, im Kontextmenü oder per Tastenkürzel stehen: eine Action zuweisen. Text, Bild, Enabled und Ausführen kommen dann von dort. |
| `Caption` | `string` |  | Beschriftung des Befehls; ein & markiert die Zugriffstaste, sonst wird der KeyTip aus der Beschriftung gebildet. Praxis: Kurz und eindeutig („Speichern", „Als PDF"); lange Texte bricht ein großer Befehl in zwei Zeilen um. Ein & legt den KeyTip-Buchstaben fest. |
| `Hint` | `string` |  | Tooltip des Befehls (mit Titel aus Caption). Praxis: Erklären, was der Befehl tut, mit Tastenkürzel: „Speichert den Beleg (Strg+S)". Der Tooltip zeigt Caption als Titel darüber. |
| `Kind` | `TPPGRibbonItemKind` | `rikButton` | Art des Items: rikButton, rikSplitButton (Button + Pfeil mit DropDownMenu), rikCheck (Umschalt-Button), rikGallery (Galerie), rikControl (eingebettetes Control) oder rikSeparator (Trennlinie). Werte: `rikButton`, `rikSplitButton`, `rikCheck`, `rikGallery`, `rikControl`, `rikSeparator`. Praxis: rikButton für Befehle, rikSplitButton für Befehl mit Varianten, rikCheck für Umschalter, rikGallery für Vorlagen, rikControl für Eingaben, rikSeparator zum Trennen. |
| `Size` | `TPPGRibbonSize` | `rsLarge` | Größe, solange die Gruppe genug Platz hat: rsLarge (großes Symbol, Text darunter), rsMedium (kleines Symbol mit Text), rsSmall (nur Symbol). Werte: `rsLarge`, `rsMedium`, `rsSmall`. Praxis: rsLarge für die ein, zwei wichtigsten Befehle einer Gruppe, rsMedium für weitere mit Text, rsSmall für bekannte Symbole wie Fett oder Kursiv. |
| `MinSize` | `TPPGRibbonSize` | `rsSmall` | Kleinste Größe, auf die das Item schrumpfen darf, wenn die Breite nicht reicht (rsLarge = bleibt groß). Werte: `rsLarge`, `rsMedium`, `rsSmall`. Praxis: rsMedium für Befehle, deren Text auch bei schmalem Fenster sichtbar bleiben soll; rsSmall erlaubt das Schrumpfen auf das Symbol. |
| `ImageIndex` | `TPPGImageIndex` | `-1` | Kleines Bild (16 px) aus Ribbon.Images; -1 = keins. Praxis: Wenn die Anwendung eine eigene Bildliste hat: das 16-px-Bild für kleine und mittlere Befehle. |
| `ImageName` | `TImageName` |  | Bild per Namen aus den Images des Besitzers (TVirtualImageList, ab Delphi 10.4). Robust gegen Umsortieren; setzt ImageIndex passend, ein unbekannter Name ergibt „kein Bild". Praxis: Wie ImageIndex, aber über den Namen in einer TVirtualImageList (ab Delphi 10.4); robuster, wenn die Liste umsortiert wird. |
| `LargeImageIndex` | `TPPGImageIndex` | `-1` | Großes Bild (32 px) aus Ribbon.LargeImages für Size = rsLarge; -1 = ImageIndex verwenden. Praxis: Für die großen Hauptbefehle einer Gruppe ein 32-px-Bild aus LargeImages; sonst wird das kleine Bild hochskaliert. |
| `IconChar` | `Word` | `0` | Symbol aus der Icon-Schrift als Zeichencode (0 = keins), z. B. $E8C8 für „Kopieren"; Alternative zu ImageIndex. Praxis: Ohne Bildliste schnell zu Symbolen kommen: Zeichen der Symbolschrift, z. B. $E74E Speichern, $E749 Drucken, $E8C8 Kopieren. |
| `GroupIndex` | `Integer` | `0` | Umschalt-Items (rikCheck) mit gleichem GroupIndex <> 0 schließen sich gegenseitig aus (im ganzen Ribbon), z. B. Links/Zentriert/Rechts. Praxis: Gleicher Wert für Umschalter, von denen genau einer gilt (Links, Zentriert, Rechts); 0 für unabhängige Umschalter wie Fett. |
| `Down` | `Boolean` | `False` | Eingerastet (Kind = rikCheck). Setzen im Code ohne Ereignis; mit GroupIndex wie Radiobuttons. Praxis: Im Code den Zustand eines Umschalters setzen, z. B. Fett nach dem Wechsel der Markierung. Löst kein Ereignis aus. |
| `Enabled` | `Boolean` | `True` | False: Befehl grau und nicht auslösbar. Praxis: Befehle sperren, die gerade nicht gehen (Speichern ohne Änderung, Einfügen mit leerer Zwischenablage); mit Action besser zentral über Action.Enabled. |
| `Visible` | `Boolean` | `True` | False: Item ausgeblendet. Praxis: Befehle ausblenden, die der Anwender nicht nutzen darf; was nur gerade nicht geht, besser mit Enabled sperren. |
| `Tag` | `NativeInt` | `0` | Freier Ganzzahlwert, z. B. eine Befehls-ID für OnItemClick. Praxis: Eine Befehls-ID für den gemeinsamen Handler in OnItemClick, z. B. 1 = Neu, 2 = Speichern. |
| `KeyTip` | `string` |  | Eigener KeyTip (Buchstabe(n) für die Tastaturbedienung nach Alt); leer = automatisch aus der Beschriftung. Praxis: Nur setzen, wenn der automatisch vergebene Buchstabe ungünstig ist, z. B. „S" für Speichern, wie Anwender es aus Office kennen. |
| `BeginColumn` | `Boolean` | `False` | True: Beginnt einen neuen Stapel kleiner bzw. mittlerer Items (bis zu drei Zeilen untereinander). Praxis: Einen neuen Stapel kleiner Befehle beginnen, z. B. damit Kopieren/Ausschneiden und Format übertragen getrennte Spalten bilden. |
| `SameRow` | `Boolean` | `False` | True: Steht rechts neben dem vorigen kleinen Item in derselben Zeile (für kompakte Knopfreihen wie Fett/Kursiv/Unterstrichen). Praxis: Für kompakte Reihen kleiner Symbole in einer Zeile, z. B. Fett, Kursiv, Unterstrichen oder die drei Ausrichtungen. |
| `DropDownMenu` | `TPopupMenu` |  | Menü eines Split-Buttons (rikSplitButton: Pfeilteil) bzw. eines Buttons, der nur aufklappt. Praxis: Für Varianten eines Befehls: Split-Button „Drucken" mit Menü Vorschau, Als PDF. Der Hauptteil führt die häufigste Variante aus. |
| `Control` | `TControl` |  | Eingebettetes Control bei Kind = rikControl (z. B. eine ComboBox für die Schriftgröße); das Ribbon wird sein Parent und setzt die Lage. Praxis: Für Eingaben direkt im Band, z. B. eine TPPGComboBox für Schriftart oder Mandant: das Control aufs Formular legen und hier mit Kind = rikControl zuweisen. |
| `GalleryItems` | `TStrings` |  | Texte der Galerie-Einträge, einer je Zeile (wenn GalleryCount = 0). Praxis: Für feste Listen wie Formatvorlagen oder Berichtsstile, ein Eintrag je Zeile. „Kategorie\|Text" gruppiert die aufgeklappte Galerie. |
| `GalleryCount` | `Integer` | `0` | Anzahl virtueller Galerie-Einträge, deren Inhalt OnGetGalleryItem liefert (0..MaxInt); 0 = Einträge aus GalleryItems. Praxis: Für Galerien, deren Einträge aus der Anwendung kommen (Farben, Vorlagen aus der Datenbank): Anzahl setzen und den Inhalt in OnGetGalleryItem liefern. |
| `GalleryIndex` | `Integer` | `-1` | Gewählter Galerie-Eintrag (-1 = keiner). Praxis: Im Code die aktuelle Vorlage markieren, z. B. die Formatvorlage des Absatzes unter dem Cursor. Löst kein OnGalleryClick aus. |
| `GalleryColumns` | `Integer` | `4` | Spalten der Galerie direkt in der Leiste (1..50). Praxis: So viele Spalten, dass die Galerie im Band etwa so breit ist wie zwei, drei große Befehle (meist 3 bis 5). |
| `GalleryPopupColumns` | `Integer` | `0` | Spalten der aufgeklappten Galerie (0..50); 0 = GalleryColumns + 1. Praxis: Mehr Spalten in der aufgeklappten Galerie, wenn es viele Einträge gibt; 0 nimmt eine Spalte mehr als im Band. |
| `GalleryItemWidth` | `Integer` | `72` | Breite eines Galerie-Eintrags in logischen Pixeln (16..1000). Praxis: An die längsten Texte anpassen (z. B. 90 für „Überschrift 1"); zu schmale Kacheln kürzen den Text. |
| `GalleryItemHeight` | `Integer` | `0` | Höhe eines Galerie-Eintrags in logischen Pixeln (0..1000); 0 = volle Höhe der Leiste. Praxis: 0 lassen für Text-Einträge; eine feste Höhe für Vorschaubilder, die in OnCustomDrawGalleryItem gezeichnet werden. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnClick` | `TNotifyEvent` `(Sender: TObject)` | Das Item wurde ausgelöst; kommt vor Ribbon.OnItemClick. Mit Action wird stattdessen Action.Execute aufgerufen (außer OnClick weicht von OnExecute ab). Praxis: Die Aktion eines einzelnen Befehls ohne Action. Für viele gleichartige Befehle ist ein gemeinsamer Handler in Ribbon.OnItemClick mit Tag übersichtlicher. |

## Verwendet in

[TPPGRibbonItems](TPPGRibbonItems.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
