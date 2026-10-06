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
