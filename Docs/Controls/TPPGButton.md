# TPPGButton

Palette **PPGlow** - Unit `PPG.Button` - Basis `TPPGCustomButton`

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

## Verhalten (aus dem Quelltext)

TPPGButton - Glow-Button mit Bild, ModalResult, Default/Cancel,
Toggle-Gruppen (GroupIndex/Down), DropDownMenu und Action-Unterstuetzung.

Stolpersteine:
- CS_DBLCLKS wird entfernt: sonst wird bei schnellem Doppelklick der zweite Klick als DblClick geliefert und "verschluckt".
- Default/Cancel folgen exakt der Logik von TButton (CM_FOCUSCHANGED / CM_DIALOGKEY), damit gemischte Formulare konsistent reagieren.
- GroupIndex wird vor Down gestreamt (Deklarationsreihenfolge!).
- Gruppen-Benachrichtigung nutzt eine EIGENE registrierte Nachricht statt CM_BUTTONPRESSED: TSpeedButton castet LParam von CM_BUTTONPRESSED blind auf TSpeedButton und wuerde bei gleichem GroupIndex unseren Speicher als TSpeedButton lesen/schreiben.
- Split-Button: Das Menue oeffnet beim Druecken auf den Pfeil (wie Windows). csClicked wird dabei entfernt, damit beim Loslassen KEIN OnClick folgt.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `ImageIndex`, `ImageName`, `HotImageIndex`, `DisabledImageIndex`, `PressedImageIndex`, `HotImageName`, `DisabledImageName`, `PressedImageName`, `ImageTint`, `ImagePosition`, `Spacing`, `Alignment`, `Margin`, `RoundedCorners`, `Shadow`, `WordWrap`, `ShowFocusRect`, `HighContrastSupport`, `ModalResult`, `Default`, `Cancel`, `Style`, `DropDownMenu`, `GroupIndex`, `AllowAllUp`, `Down`

## Eigenschaften wie in der VCL

`Action`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `ParentBackground`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnDropDownClick`, `OnGesture`, `OnClick`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGButton.md`.
