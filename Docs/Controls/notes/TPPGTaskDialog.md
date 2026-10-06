**Vorbild:** `Vcl.Dialogs.TTaskDialog`, TMS TAdvTaskDialog

## Unterschiede und Hinweise

- Erbt von `TCustomTaskDialog`: alle Properties, `Buttons`/`RadioButtons`, `Flags` und Ereignisse sind die des Originals. Ein `TTaskDialog` wird durch Tauschen des Klassennamens umgestellt; DFMs laden unverändert.
- Statt `TaskDialogIndirect` erscheint ein echtes Formular aus Suite-Controls. Es folgt Preset, Dark Mode und Hochkontrast und läuft auch ohne Vista-API.
- Wie das Original: Esc und das Schließen-Kreuz gibt es nur mit `tfAllowDialogCancellation` oder einem Abbrechen-Button. `OnButtonClicked` kann das Schließen verhindern. Nach `Execute` stehen `ModalResult`, `Button`, `RadioButton`, `Expanded` und `tfVerificationFlagChecked` bereit.
- Strg+C kopiert den Text im Windows-Format, F1 öffnet `HelpContext`. Der Ton richtet sich nach dem Symbol.
- Änderungen aus Ereignissen (`ProgressBar.Position`, `Buttons[i].Enabled`, `Text`, `Title`) werden nach jedem Ereignis übernommen.
- `OnTimer` (mit `tfCallbackTimer`) läuft alle 200 ms über einen `TTimer`.
- Zusätzlich gibt es `Preset`/`StyleManager`, `AllowMarkup` und `ContentControl` (ein eigenes Control im Dialog, das danach zurückgegeben wird).
- Dazu die Funktionen `PPGMessageDlg`, `PPGMessageDlgPos`, `PPGShowMessage`, `PPGInputQuery` (mit Prüfung) und `PPGInputBox` mit den Signaturen der VCL. Der Aufruf aus einem Thread löst `EPPGError` aus statt zu hängen.
- Für Tests und Automatisierung: `PPGOnDialogShow` und `DialogForm.ClickButton`.

## Beispiel

```pascal
if PPGMessageDlg('Änderungen speichern?', mtConfirmation, mbYesNoCancel, 0) = mrYes then
  Save;

PPGTaskDialog1.Title := 'Speichern?';
PPGTaskDialog1.Flags := [tfUseCommandLinks, tfAllowDialogCancellation];
if PPGTaskDialog1.Execute and (PPGTaskDialog1.ModalResult = 101) then
  Save;
```
