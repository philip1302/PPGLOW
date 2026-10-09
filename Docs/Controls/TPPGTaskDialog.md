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

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage des Dialogs ('' = Standard bzw. StyleManager). |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle für Preset und Farben des Dialogs. |
| `AllowMarkup` | `Boolean` | `False` | True: Text, Fußzeile und Zusatztexte dürfen Mini-Markup enthalten (<b>, <i>, <color=...>). |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet der Dialog mit allen Teilen (Schaltflächen, Felder, Fußzeile) die Systemfarben. |
| `ContentControl` | `TControl` |  | Eigenes Control, das im Dialog unter dem Text eingebettet wird (z. B. ein Panel mit Eingabefeldern). Es wird für die Dauer des Dialogs umgehängt. Nutzung: `PPGTaskDialog1.ContentControl := pnlOptionen;` |

## Eigenschaften wie in der VCL

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Buttons` |  |  | Eigene Schaltflächen (Collection). Jede hat Caption, ModalResult, Default und bei Flag tfUseCommandLinks einen Hinweistext (CommandLinkHint). Nutzung: Im Designer per Doppelklick; im Code `with PPGTaskDialog1.Buttons.Add do begin Caption := 'Speichern'; ModalResult := mrYes; end;` |
| `Caption` | `TCaption` |  | Fenstertitel des Dialogs. |
| `CommonButtons` |  |  | Standardschaltflächen (tcbOk, tcbYes, tcbNo, tcbCancel, tcbRetry, tcbClose) zusätzlich zu Buttons. Nutzung: `PPGTaskDialog1.CommonButtons := [tcbYes, tcbNo];` |
| `CustomFooterIcon` |  |  | Eigenes Symbol in der Fußzeile (statt FooterIcon); braucht Flag tfUseHiconFooter. |
| `CustomMainIcon` |  |  | Eigenes Hauptsymbol (statt MainIcon); braucht Flag tfUseHiconMain. |
| `DefaultButton` |  |  | Standardschaltfläche aus CommonButtons (Enter löst sie aus). |
| `ExpandButtonCaption` |  |  | Beschriftung des Aufklappers für ExpandedText. |
| `ExpandedText` |  |  | Zusatztext, der erst nach Klick auf den Aufklapper erscheint (Details). |
| `Flags` |  |  | Verhalten: tfUseCommandLinks (Buttons als große Befehlslinks), tfAllowDialogCancellation (Esc schließt), tfShowProgressBar, tfShowMarqueeProgressBar, tfExpandedByDefault, tfVerificationFlagChecked, tfPositionRelativeToWindow u. a. |
| `FooterIcon` |  |  | Symbol der Fußzeile (tdiNone, tdiWarning, tdiError, tdiInformation, tdiShield). |
| `FooterText` |  |  | Text in der Fußzeile, z. B. ein Hinweis oder Link. |
| `HelpContext` | `THelpContext` |  | Hilfe-Kontext für F1 im Dialog. |
| `MainIcon` |  |  | Hauptsymbol links neben dem Titel (tdiNone, tdiWarning, tdiError, tdiInformation, tdiShield). |
| `ProgressBar` |  |  | Fortschrittsbalken im Dialog (Position, Min, Max, State); sichtbar mit Flag tfShowProgressBar. |
| `RadioButtons` |  |  | Optionsfelder im Dialog (Collection); die Wahl steht danach in RadioButton. |
| `Text` |  |  | Haupttext unter dem Titel. |
| `Title` |  |  | Fett hervorgehobene Hauptanweisung (Überschrift im Dialog). Nutzung: `PPGTaskDialog1.Title := 'Änderungen speichern?';` |
| `VerificationText` |  |  | Text eines Kontrollkästchens unten links, z. B. „Nicht mehr anzeigen"; Zustand über Flag tfVerificationFlagChecked. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnButtonClicked` | `TTaskDlgClickEvent` `(Sender: TObject; ModalResult: TModalResult; var CanClose: Boolean)` | Eine Schaltfläche wurde geklickt; CanClose := False hält den Dialog offen. |
| `OnDialogConstructed` | `TNotifyEvent` `(Sender: TObject)` | Der Dialog ist aufgebaut, aber noch nicht sichtbar. |
| `OnDialogCreated` | `TNotifyEvent` `(Sender: TObject)` | Der Dialog ist erzeugt und sichtbar. |
| `OnDialogDestroyed` | `TNotifyEvent` `(Sender: TObject)` | Der Dialog wurde geschlossen und zerstört. |
| `OnExpanded` | `TNotifyEvent` `(Sender: TObject)` | Der Aufklapper für ExpandedText wurde umgeschaltet. |
| `OnHyperlinkClicked` | `TNotifyEvent` `(Sender: TObject)` | Ein Link (<a href="...">) in Text oder FooterText wurde geklickt (braucht Flag tfEnableHyperlinks); die Adresse steht in URL. |
| `OnRadioButtonClicked` | `TNotifyEvent` `(Sender: TObject)` | Ein Optionsfeld wurde gewählt. |
| `OnTimer` | `TTaskDlgTimerEvent` `(Sender: TObject; TickCount: Cardinal; var Reset: Boolean)` | Wird etwa alle 200 ms aufgerufen (braucht Flag tfCallbackTimer), z. B. um ProgressBar fortzuschreiben. |
| `OnVerificationClicked` | `TNotifyEvent` `(Sender: TObject)` | Das Kontrollkästchen (VerificationText) wurde umgeschaltet. |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests, TAudit11CGdiTests); `PPG.Tests.Audit45` (TEffectFixTests); `PPG.Tests.Audit7C` (THighContrastTokenTests); `PPG.Tests.Phase11c` (TDialogTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTaskDialog.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
