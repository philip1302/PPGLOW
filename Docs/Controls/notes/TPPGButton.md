**Vorbild:** TButton, TBitBtn, TSpeedButton, TMS TAdvGlowButton

## Wofür

Der Button löst einen Befehl aus: Speichern, Abbrechen, Exportieren. Er ersetzt `TButton`, `TBitBtn` und `TSpeedButton` in einem Control. Er kann ein Symbol zeigen, als Umschalter einrasten, als Split-Button ein Menü öffnen und in Dialogen mit `Default`, `Cancel` und `ModalResult` arbeiten.

## Wann verwenden

- Für Befehle, die sofort etwas tun. Für Ein/Aus-Einstellungen, die gespeichert werden, ist `TPPGToggleSwitch` oder `TPPGCheckBox` klarer.
- Statt `TPPGCommandLink`, wenn der Befehl keinen erklärenden Zusatztext braucht. Command-Links sind für große Auswahl-Buttons in Dialogen.
- Statt einzelner Buttons in einer `TPPGToolBar`, wenn nur wenige, frei platzierte Befehle nötig sind. Viele Befehle in einer Leiste mit Überlauf gehören in die ToolBar oder das Ribbon.
- Als Umschalter (`GroupIndex`, `Down`), wenn der Zustand direkt am Befehl sichtbar sein soll, z. B. Fett oder Ausrichtung in einer Formatleiste.

## Unterschiede und Hinweise

- Ein Fenster-Control (auch als Ersatz für `TSpeedButton`): bekommt den Fokus, wenn `TabStop` gesetzt ist.
- Umschalt-Gruppen wie `TSpeedButton`: `GroupIndex` + `Down` + `AllowAllUp`.
- Split-Button: `Style = pbsSplitButton` mit `DropDownMenu`; Klick auf den Pfeil öffnet das Menü ohne `OnClick`.
- Bilder kommen aus `Images`/`ImageIndex` (ab 10.4 auch `ImageName`), nicht aus `Glyph`.

## Anpassung

- `Alignment` und `Margin` (wie `TBitBtn`) für die Lage von Bild und Text.
- Bilder je Zustand: `HotImageIndex`, `DisabledImageIndex`, `PressedImageIndex` (bzw. `…ImageName` ab 10.4); `ImageTint = itTextColor` färbt einfarbige Symbole in der Textfarbe des Zustands.
- `RoundedCorners` (Segment-Buttons, Button-Gruppen) und `Shadow` (Elevation).
- Schriftstil je Zustand über `Appearance.Hot.FontStyle` usw.; `Appearance.Focused` und `Appearance.Dark` für Fokus- und Dunkel-Farben.

## Beispiel

```pascal
PPGButton1.Caption := '&Speichern';
PPGButton1.ModalResult := mrOk;
PPGButton1.Default := True;
```
