# TPPGValidator

Palette **PPGlow** - Unit `PPG.Validator` - Basis `TComponent`

**Vorbild:** keins; ersetzt den Prüfcode in Formularen (`if Edit1.Text = '' then ShowMessage(...)`)

## Unterschiede und Hinweise

- Regeln im Designer: Pflicht, Länge, Bereich (Zahl oder Datum), Format (E-Mail, Telefon, PLZ, IBAN mit Prüfsumme, eigener regulärer Ausdruck), Vergleich mit einem anderen Feld, eigene Regel per `OnValidate`.
- Fehler stehen direkt am Feld (`ValidationState`/`ValidationHint`, auch für Screenreader). Der Validator nimmt nur zurück, was er selbst gesetzt hat; Fehler eines DB-Felds bleiben stehen.
- Geprüft wird beim Verlassen eines Felds (`ValidateOn`); nach einem Fehler prüft das Feld beim Tippen sofort neu. `Validate` prüft alles, `ValidateGroup`/`ValidateChildren` nur einen Teil.
- `FocusFirstError` springt zum ersten Fehler in Tab-Reihenfolge und aktiviert dafür Reiter und Assistent-Seiten, klappt Expander auf und scrollt.
- `SummaryBar` (InfoBar) zeigt „2 Fehler: Name, E-Mail“ mit „Zum Fehler“; `CheckOnClose` hält ein Formular mit OK offen, solange etwas fehlt; `SubmitControl` sperrt den OK-Knopf bis alle Pflichtfelder gefüllt sind; `Wizard` lässt „Weiter“ erst bei gültiger Seite zu.
- `AutoFieldRules`: DB-Controls ohne eigene Regel werden nach ihrem `TField` geprüft (Required, Size, MinValue/MaxValue), solange die Datenmenge bearbeitet wird. Das gilt für alle DB-Controls desselben Besitzers.
- Fremde Controls ohne `ValidationState` (VCL, TMS) werden geprüft, aber nicht markiert: Sie erscheinen in `Results`, der Sammelleiste und `OnShowError`.
- Ausgeblendete und gesperrte Controls zählen nicht; Controls auf nicht aktiven Reitern schon.

## Beispiel

```pascal
PPGValidator1.Rules.AddRule(EditName, vrRequired);
R := PPGValidator1.Rules.AddRule(EditMail, vrPattern);
R.PatternKind := vpEmail;
if not PPGValidator1.Validate then
  PPGValidator1.FocusFirstError;
```

## Verhalten (aus dem Quelltext)

Formularweite Eingabepruefung (Phase 19a).

TPPGValidator (nicht sichtbar): Regeln je Control im Designer statt
Pruefcode im Formular.
- Regelarten: Pflicht, Laenge, Bereich (Zahl oder Datum), Muster (eigener regulaerer Ausdruck oder E-Mail, Telefon, PLZ, IBAN mit Pruefsumme), Vergleich mit einem anderen Control, eigene Regel per OnValidate.
- Leere Werte prueft nur die Pflicht-Regel (und OnValidate); die uebrigen greifen erst, wenn etwas eingegeben ist.
- Je Control gilt das erste Ergebnis: der erste Fehler, sonst die erste Warnung (Reihenfolge der Regeln).
- Werte liest ein Adapter je Control-Klasse (PPGRegisterValidationAdapter, der zuletzt registrierte passende gewinnt). Eingebaut: PPGlow-Felder (IPPGFieldValue, DatePicker, SpinEdit, sonst Text), Auswahlgruppen, Kaestchen/Schalter und die VCL-Pendants (Edit, ComboBox, CheckBox, DateTimePicker).
- Markiert wird ueber ValidationState/ValidationHint (Tooltip und Screenreader). Der Validator setzt nur zurueck, was er selbst gesetzt hat: hat jemand anderes (z.B. ein DB-Feld) den Zustand inzwischen geaendert, bleibt er stehen. Controls ohne ValidationState erscheinen nur in Results und OnShowError.
- Automatisch pruefen (ValidateOn): beim Verlassen (CM_EXIT) bzw. bei jeder Aenderung. Ein Control mit Ergebnis prueft bei jeder Aenderung sofort neu, damit der Fehler verschwindet, sobald er behoben ist. Aenderungen melden die PPGlow-Controls per CM_PPGVALUECHANGED, VCL-Controls ueber ihre Benachrichtigungen (CN_COMMAND, CN_NOTIFY). Die Pruefung laeuft danach ueber eine gepostete Nachricht, nie mitten in OnChange.
- Ausgeblendete und gesperrte Controls zaehlen nicht; Controls auf nicht aktiven Reitern schon (sie sind nur verdeckt, auch bei TabVisible = False), ebenso auf nicht aktiven Seiten des Assistenten (ausser PageVisible = False).
- FocusFirstError: erster Fehler in Tab-Reihenfolge; aktiviert unterwegs Reiter, klappt Expander auf und scrollt ihn ins Bild.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Active` | `Boolean` | `True` | False: Der Validator prüft nichts mehr, Validate liefert immer True, und vorhandene Markierungen werden zurückgenommen. |
| `ValidateOn` | `TPPGValidateOn` | `voExit` | Wann automatisch geprüft wird: voSubmit nur auf Aufruf, voExit beim Verlassen eines Felds (Vorgabe), voChange bei jeder Änderung. Ein Feld mit Fehler prüft in jedem Fall beim Tippen sofort neu. Werte: `voSubmit`, `voExit`, `voChange`. |
| `ShowValid` | `Boolean` | `False` | Geprüfte Felder ohne Fehler bekommen den Zustand pvsValid (grüner Rand) – erst nach der ersten Prüfung, nicht beim Öffnen des Formulars. |
| `Rules` | [TPPGValidationRules](types/TPPGValidationRules.md) |  | Die Regeln: je Regel ein Control, eine Art und ihre Einstellungen. Im Designer per Doppelklick; das Verb „Add required rules for all fields“ legt für jedes Eingabefeld ohne Regel eine Pflicht-Regel an. Nutzung: `Validator.Rules.AddRule(EditName, vrRequired);` |
| `AutoFieldRules` | `Boolean` | `True` | DB-Controls (alles mit einer Property Field: TField, auch TDBEdit der VCL) prüft der Validator ohne eigene Regel nach ihrem Datenfeld: Required, Size bei Text, MinValue/MaxValue bei Zahlen – solange die Datenmenge bearbeitet wird. Gilt für alle DB-Controls desselben Besitzers; bei mehreren Formularteilen ValidateChildren nehmen oder abschalten. Nutzung: `if not Validator.ValidateChildren(DetailPanel) then Abort;` |
| `SummaryBar` | `TPPGCustomInfoBar` |  | InfoBar für die Sammelanzeige: „2 Fehler“ mit den Feldnamen und dem Knopf „Zum Fehler“. Erscheint erst nach dem ersten Validate (bzw. Schließen mit OK, Weiter im Assistenten) und klappt zu, sobald alles stimmt. |
| `CheckOnClose` | `Boolean` | `True` | Schließt das Formular mit ModalResult mrOk oder mrYes (z. B. OK-Knopf), prüft der Validator vorher und bricht das Schließen bei Fehlern ab. Abbrechen und das Schließfeld bleiben frei; ein vorhandenes OnCloseQuery läuft zuerst. |
| `SubmitControl` | `TControl` |  | Control (meist der OK- oder Speichern-Knopf), das gesperrt ist, solange ein Pflichtfeld leer ist. Andere Regeln zählen hier nicht, damit der Knopf nicht bei jedem Tastendruck flackert. |
| `Wizard` | `TPPGWizard` |  | Assistent, dessen „Weiter“ erst geht, wenn die Felder der aktuellen Seite gültig sind; der Validator hängt sich in OnCanAdvance ein (ein vorhandener Handler läuft zuerst). |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnValidate` | `TPPGValidateRuleEvent` `(Sender: TObject; Rule: TPPGValidationRule; const Value: Variant; var Valid: Boolean; var Message: string)` | Für Regeln der Art vrCustom: Value ist der Wert des Controls; Valid := False und eine Meldung setzen, wenn er nicht passt. Nutzung: `Valid := not KundennummerVergeben(VarToStr(Value)); Message := 'Kundennummer ist schon vergeben';` |
| `OnValidated` | `TNotifyEvent` `(Sender: TObject)` | Nach jeder Prüfung, auch der automatischen beim Verlassen eines Felds; Results und ErrorCount sind dann aktuell. |
| `OnShowError` | `TPPGShowErrorEvent` `(Sender: TObject; Control: TControl; const Message: string; Severity: TPPGValidationState)` | Das Ergebnis eines Controls hat sich geändert: neue oder geänderte Meldung bzw. behoben (Severity = pvsNone). Für eigene Anzeigen, z. B. bei Controls ohne ValidationState. Nutzung: `if Severity = pvsNone then MyLabel.Caption := '' else MyLabel.Caption := Message;` |

Tests: `PPG.Tests.Audit7D` (TAudit7DTests); `PPG.Tests.Phase19` (TValidatorComfortTests, TValidatorTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGValidator.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
