# TPPGWizard

Palette **PPGlow** - Unit `PPG.Wizard` - Basis `TPPGCustomContainer`

**Vorbild:** TMS TAdvWizard, Windows-Assistenten (Aero Wizard)

## Unterschiede und Hinweise

- Seiten (`TPPGWizardPage`) wie beim `TPPGPageControl`: Jede Seite mit diesem Parent ist ein Schritt. Die DFM-Reihenfolge ist die Schrittfolge. Neue Seiten entstehen über das Kontextmenü im Designer, ein Klick auf einen Schritt wechselt dort die Seite.
- Die Schritt-Anzeige steht oben oder links (`StepPosition`). Seiten mit `PageVisible = False` werden übersprungen und nicht angezeigt.
- Leiste unten: Zurück / Weiter (auf dem letzten Schritt Fertig) / Abbrechen. Enter = Weiter, Esc = Abbrechen. Die Beschriftungen sind übersetzt (deutsch Alt+Z / Alt+W).
- `OnCanAdvance(Page, Allow)` prüft jeden Schritt vor Weiter bzw. Fertig. `OnPageChanged`, `OnFinish` und `OnCancel` kommen nur bei Anwenderaktionen; `ActivePage` aus Code löst nichts aus.
- Ohne `OnFinish`/`OnCancel` in einem modalen Formular wird `ModalResult` auf `mrOk` bzw. `mrCancel` gesetzt.
- Ein Klick auf einen erledigten Schritt geht dorthin zurück (ohne Prüfung).

## Beispiel

```pascal
procedure TForm1.PPGWizard1CanAdvance(Sender: TObject; Page: TPPGWizardPage;
  var Allow: Boolean);
begin
  Allow := (Page <> PageAccount) or (NameEdit.Text <> '');
end;
```

## Verhalten (aus dem Quelltext)

TPPGWizard + TPPGWizardPage - Schritt-Assistent (Phase 11g).

- Seiten wie beim TPPGPageControl: jede TPPGWizardPage mit diesem Parent ist ein Schritt (DFM-Reihenfolge = Schrittfolge, GetChildren). Nur die aktive Seite ist sichtbar, auch im Designer (csNoDesignVisible).
- Schritt-Anzeige oben oder links (StepPosition): Kreise mit Nummer bzw. Haekchen, verbindende Linie, Titel = Caption der Seite. Seiten mit PageVisible = False werden uebersprungen und nicht angezeigt.
- Leiste unten: Zurueck / Weiter (auf dem letzten Schritt: Fertig) / Abbrechen. Enter = Weiter (Default), Esc = Abbrechen, Mnemonics uebersetzbar (Alt+W/Alt+Z im Deutschen).
- Ereignisse nur bei Anwenderaktionen (Buttons, Next/Back/Finish/Cancel als deren Gegenstueck): OnCanAdvance(Page, Allow) vor jedem Weiter/Fertig, OnPageChanged, OnFinish, OnCancel. ActivePage aus Code: ohne Ereignisse.
- Ohne OnFinish/OnCancel in einem modalen Formular: ModalResult mrOk bzw. mrCancel.
- Klick auf einen erledigten Schritt geht dorthin zurueck; im Designer wechselt ein Klick auf einen Schritt die Seite.
- Screenreader: Name "Schritt x von y: Titel", Seiten mit Rolle Eigenschaftsseite.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `ActivePage` | `TPPGWizardPage` |  | Der aktuelle Schritt (TPPGWizardPage). Setzen im Code ohne Ereignisse. |
| `StepPosition` | `TPPGWizardStepPosition` | `wspTop` | Lage der Schritt-Anzeige: wspTop (oben), wspLeft (links) oder wspNone (keine). Werte: `wspTop`, `wspLeft`, `wspNone`. |
| `ShowCancel` | `Boolean` | `True` | True: Der Button „Abbrechen" ist sichtbar. |
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Align` | `TAlign` |  | Dockt das Control an eine Seite des Parents (alTop, alBottom, alLeft, alRight) oder füllt den Rest (alClient). alNone = freie Position. Nutzung: `Panel1.Align := alClient;` Abstände über `AlignWithMargins` und `Margins`. |
| `Anchors` | `TAnchors` |  | Kanten, deren Abstand zum Parent beim Vergrößern gleich bleibt. [akLeft, akRight] dehnt das Control in der Breite mit. Nutzung: `Edit1.Anchors := [akLeft, akTop, akRight];` |
| `BiDiMode` | `TBiDiMode` |  | Leserichtung. bdRightToLeft spiegelt Layout und Text für Arabisch und Hebräisch. Nutzung: Meist über `ParentBiDiMode` vom Formular übernehmen. |
| `Constraints` | `TSizeConstraints` |  | Mindest- und Höchstmaße (MinWidth, MinHeight, MaxWidth, MaxHeight); 0 = keine Grenze. Nutzung: `Panel1.Constraints.MinWidth := 200;` |
| `Enabled` | `Boolean` |  | False: Das Control ist deaktiviert (grau, keine Eingabe, kein Fokus). Kinder eines deaktivierten Containers sind ebenfalls gesperrt. |
| `Font` | `TFont` |  | Schrift (Name, Größe, Stil, Farbe). Die Textfarbe der Zustände kann Appearance überschreiben. Nutzung: `Label1.Font.Size := 12; Label1.Font.Style := [fsBold];` |
| `ParentBiDiMode` | `Boolean` |  | True: BiDiMode wird vom Parent übernommen. |
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
| `OnCanAdvance` | `TPPGWizardCanAdvanceEvent` `(Sender: TObject; Page: TPPGWizardPage; var Allow: Boolean)` | Vor jedem „Weiter" bzw. „Fertig"; Page ist der aktuelle Schritt, Allow := False bleibt auf der Seite (z. B. bei unvollständigen Eingaben). Nutzung: `Allow := (Page <> pgAdresse) or (edName.Text <> '');` |
| `OnPageChanged` | `TNotifyEvent` `(Sender: TObject)` | Der Anwender hat den Schritt gewechselt (Weiter, Zurück oder Klick auf einen erledigten Schritt). |
| `OnFinish` | `TNotifyEvent` `(Sender: TObject)` | „Fertig" auf dem letzten Schritt wurde gewählt (nach OnCanAdvance). Ohne Ereignis schließt ein modales Formular mit mrOk. |
| `OnCancel` | `TNotifyEvent` `(Sender: TObject)` | „Abbrechen" (bzw. Esc) wurde gewählt. Ohne Ereignis schließt ein modales Formular mit mrCancel. |
| `OnResize` | `TNotifyEvent` `(Sender: TObject)` | Nach einer Größenänderung. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGWizard.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
