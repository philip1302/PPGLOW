**Vorbild:** TButton, TBitBtn, TSpeedButton, TMS TAdvGlowButton

## Unterschiede und Hinweise

- Ein Fenster-Control (auch als Ersatz für `TSpeedButton`): bekommt den Fokus, wenn `TabStop` gesetzt ist.
- Umschalt-Gruppen wie `TSpeedButton`: `GroupIndex` + `Down` + `AllowAllUp`.
- Split-Button: `Style = bsSplitButton` mit `DropDownMenu`; Klick auf den Pfeil öffnet das Menü ohne `OnClick`.
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
