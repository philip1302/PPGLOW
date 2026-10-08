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

`ActivePage`, `StepPosition`, `ShowCancel`, `Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnCanAdvance`, `OnPageChanged`, `OnFinish`, `OnCancel`, `OnResize`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGWizard.md`.
