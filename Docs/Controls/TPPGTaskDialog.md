# TPPGTaskDialog

Palette **PPGlow** - Unit `PPG.Dialogs` - Basis `TCustomTaskDialog`

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

## Verhalten (aus dem Quelltext)

Dialoge im Stil der Suite (Phase 11g).

TPPGTaskDialog erbt von Vcl.Dialogs.TCustomTaskDialog und ersetzt nur
DoExecute: alle Properties, Collections (Buttons, RadioButtons) und
Ereignisse sind die des Originals - DFMs und Code eines TTaskDialog laufen
unveraendert (Klassenname tauschen). Statt TaskDialogIndirect baut er ein
echtes Formular aus PPGlow-Controls (Label, Button, RadioButton, CheckBox,
ProgressBar): eine Zeichenlogik, Presets, Dark Mode, Hochkontrast und
Tastatur kommen aus den Controls.

Verhalten wie das Windows-Original:
- Ereignisse OnButtonClicked (CanClose), OnRadioButtonClicked, OnVerificationClicked, OnHyperlinkClicked, OnExpanded, OnTimer (200 ms, tfCallbackTimer), OnDialogCreated/Constructed/Destroyed. Nach Execute stehen ModalResult, Button, RadioButton, Expanded und tfVerificationFlagChecked wie beim Original.
- Esc und Schliessen-Kreuz nur mit tfAllowDialogCancellation oder einem Abbrechen-Button (Ergebnis mrCancel, OnButtonClicked wird gefragt).
- Strg+C kopiert Titel, Text und Buttons im Windows-Format, F1 = Hilfe.
- Ton je Symbol (MessageBeep), Fenster ueber dem Elternformular bzw. mittig auf dessen Monitor (tfPositionRelativeToWindow), DPI des Zielmonitors.
- Aenderungen aus Ereignissen (ProgressBar.Position, Buttons[i].Enabled, Text, Title) werden nach jedem Ereignis uebernommen - beim Original laufen sie ueber das Fensterhandle, das es hier nicht gibt.
Zusaetzlich: Preset/StyleManager, AllowMarkup (Text mit <b>, <i>, ...) und
ContentControl (eigenes Control im Dialog, wird danach zurueckgegeben).

PPGMessageDlg/PPGMessageDlgPos/PPGShowMessage/PPGInputQuery/PPGInputBox:
gleiche Signaturen wie die VCL-Funktionen, laufen ueber TPPGTaskDialog.
Aufruf nur im Haupt-Thread (EPPGError statt Haenger).

## PPGlow-Eigenschaften

`Buttons`, `Caption`, `CommonButtons`, `CustomFooterIcon`, `CustomMainIcon`, `DefaultButton`, `ExpandButtonCaption`, `ExpandedText`, `Flags`, `FooterIcon`, `FooterText`, `HelpContext`, `MainIcon`, `ProgressBar`, `RadioButtons`, `Text`, `Title`, `VerificationText`, `Preset`, `StyleManager`, `AllowMarkup`, `ContentControl`

## Ereignisse

`OnButtonClicked`, `OnDialogConstructed`, `OnDialogCreated`, `OnDialogDestroyed`, `OnExpanded`, `OnHyperlinkClicked`, `OnNavigated`, `OnRadioButtonClicked`, `OnTimer`, `OnVerificationClicked`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTaskDialog.md`.
