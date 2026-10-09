# Phase 19 – Detailplan: Formular-Produktivität (Validator, BusyOverlay)

*Stand 09.10.2026. Grundlage: `Docs\Roadmap3.md`, Phase 19. **Vom User am 09.10.2026 freigegeben („Mach Phase 19“, alle vier Entscheidungen wie empfohlen).***

## Context
Jedes Eingabeformular braucht dieselben zwei Dinge: Eingaben prüfen und während langer Arbeit „bitte warten“ zeigen. Heute schreibt man das in jedem Formular von Hand (`if Edit1.Text = '' then begin ShowMessage(...); Edit1.SetFocus; Exit; end;`) bzw. setzt `Screen.Cursor := crHourGlass`. Weder die VCL noch TMS haben dafür einen formularweiten Baustein.

Regel aus Phase 18 gilt weiter: mindestens zwei Dinge, die VCL und TMS nicht können.

| Teil | Inhalt | Mehrwert |
|---|---|---|
| 19a | `TPPGValidator` – Kern (Regeln, Prüfen, Markieren) | Regeln im Designer statt Code, Fehler direkt am Feld (`ValidationState`/`ValidationHint` gibt es schon), springt zum ersten Fehler auch auf verdeckten Reitern |
| 19b | Validator – Komfort | Regeln automatisch aus `TField` (Required, Size, Min/Max), Sammelanzeige in einer `TPPGInfoBar`, Schließen mit OK nur bei gültigen Eingaben, Assistenten-Seiten |
| 19c | `TPPGBusyOverlay` | Abgedunkelte Fläche mit ProgressRing, Text, Fortschritt und Abbrechen über einem Control oder Formular; `Run` führt Arbeit im Hintergrund-Thread aus, die Oberfläche bleibt lebendig |
| 19d | Demo, Tests, Doku, Prüfung | – |

## 19a – `TPPGValidator` (`PPG.Validator`, nicht sichtbar)
- **Regeln** (`Rules`, Collection `TPPGValidationRule`), je Regel:
  - `Control` (beliebiges `TControl` des Formulars), `Kind`, `Message` (leer = Standardtext mit Platzhaltern, z. B. „%s ist ein Pflichtfeld“ mit der Beschriftung), `Severity` (`pvsError`/`pvsWarning`), `Enabled`, `Group` (Text, um nur Teile zu prüfen)
  - `Kind`:
    - `vrRequired` – nicht leer; bei Kästchen: angehakt (z. B. AGB), bei Auswahlgruppen: etwas gewählt
    - `vrLength` – `MinLength`/`MaxLength`
    - `vrRange` – `MinValue`/`MaxValue` (Zahl oder Datum, je nach Control)
    - `vrPattern` – regulärer Ausdruck (`System.RegularExpressions`, ab XE2 vorhanden), dazu fertige Muster `vpEmail`, `vpPhone`, `vpPostalCodeDE`, `vpIBAN` (mit Prüfsumme)
    - `vrCompare` – gleich/ungleich/größer/kleiner einem anderen Control (Passwort wiederholen, Bis-Datum ≥ Von-Datum)
    - `vrCustom` – Ereignis `OnValidate(Rule, Value, var Valid, var Message)`
- **Wert eines Controls** über einen kleinen Adapter (offen erweiterbar per `PPGRegisterValidationAdapter`):
  - `IPPGFieldValue` (Zahl, Maske, Farbe, Tags …), sonst `TPPGCustomField.Text`
  - Auswahlgruppe (`ItemIndex`/`Value`), CheckBox/ToggleSwitch (`Checked`), DatePicker (`Date`, leer = Null)
  - VCL: `TCustomEdit.Text`, `TCustomComboBox.Text`/`ItemIndex`, `TCheckBox.Checked`, `TDateTimePicker.Date`
- **Prüfen:**
  - `Validate: Boolean` (alles), `ValidateGroup(const Group)`, `ValidateContainer(AParent)` (alles in einem Panel/Reiter), `ValidateControl(C)`
  - `ValidateOn`: `voSubmit` (nur auf Aufruf), `voExit` (beim Verlassen des Felds, Vorgabe), `voChange` (sofort beim Tippen). Nach dem ersten Fehler prüft ein Feld beim Tippen sofort neu, damit der Fehler verschwindet, sobald er behoben ist (wie in modernen Web-Formularen).
  - Leere Felder prüft nur `vrRequired`; die übrigen Regeln greifen erst, wenn etwas eingegeben ist.
- **Markieren:**
  - PPGlow-Controls: `ValidationState` + `ValidationHint` (Tooltip und Screenreader). Der Validator setzt nur zurück, was er selbst gesetzt hat; Fehler eines DB-Felds bleiben stehen.
  - Fremde Controls ohne `ValidationState`: keine Markierung am Control, aber Sammelanzeige, Fokus und Ereignis `OnShowError(Control, Message)` für eigene Anzeige.
- **Ergebnis:** `Errors` (Liste: Control, Regel, Text, Schwere), `ErrorCount`, `WarningCount`, `OnValidated`.
- **Zum Fehler springen:** `FocusFirstError` aktiviert unterwegs Reiter (`TPPGPageControl`/`TPageControl`), klappt `TPPGExpander` auf und scrollt (`ScrollInView` aus Phase 18d). Reihenfolge nach Tab-Reihenfolge, nicht nach Regelreihenfolge.

## 19b – Validator-Komfort
- **Regeln aus der Datenbank** (`AutoFieldRules`, Vorgabe True): Für DB-Controls (`TPPGDB…`) leitet der Validator ohne eigene Regel ab: `TField.Required` → Pflicht, `Size` bei Text → Höchstlänge, `MinValue`/`MaxValue` bei Zahlfeldern → Bereich. Die Meldung nimmt `DisplayLabel`. Liegt im DB-Paket (`PPG.DB.Validator`, Adapter registriert sich).
- **Sammelanzeige:** `SummaryBar: TPPGInfoBar` zeigt „2 Fehler: Name, E-Mail“ mit Schwere passend (Fehler/Warnung); ein Klick auf die Leiste springt zum ersten Fehler. Leer bzw. alles gültig: Leiste verschwindet.
- **Schließen absichern:** `CheckOnClose` (Vorgabe True): Schließt das Formular mit `mrOk`/`mrYes` (z. B. OK-Button mit `ModalResult`), prüft der Validator vorher und bricht das Schließen bei Fehlern ab. Ein vorhandenes `OnCloseQuery` bleibt wirksam (verkettet, wie der Schnellfilter des Navigators).
- **`SubmitControl`** (optional): Button, der gesperrt ist, solange Pflichtfelder fehlen (nur `vrRequired`, damit er nicht bei jedem Tastendruck flackert).
- **Assistent:** `TPPGWizard.OnCanAdvance` kann `Validator.ValidateContainer(Page)` aufrufen; dafür gibt es die Eigenschaft `Wizard` am Validator, die das selbst einhängt.
- **Designer:** Regel-Editor (Doppelklick: Liste der Regeln mit Control, Art, Meldung), Verb „Regeln für alle Pflichtfelder anlegen“ (aus DB-Feldern), Symbol in der Palette.

## 19c – `TPPGBusyOverlay` (`PPG.BusyOverlay`, nicht sichtbar)
- **Eigenschaften:** `Target` (`TWinControl`, leer = Formular), `Text`, `Description`, `Progress` (-1 = unbestimmt, 0–100), `ShowCancel`, `CancelCaption`, `Delay` (ms bis zum Erscheinen, Vorgabe 300 – kurze Arbeiten blitzen nicht), `MinDisplayTime` (Vorgabe 500 ms), `DimOpacity`, Preset/StyleManager wie alle Controls.
- **Aufruf:**
  - `Show`/`Hide` (zählend, verschachtelbar), `Active`, `Cancelled`, `OnCancel`
  - `Run(Work: TProc<IPPGBusyContext>)`: führt `Work` in einem Hintergrund-Thread aus und wartet mit laufender Nachrichtenschleife; `Context.Report(Progress, Text)` und `Context.Cancelled` sind thread-sicher. Eine Exception im Thread kommt im Hauptthread wieder an (nicht verschluckt).
  - `RunAsync` mit `OnDone` für Code, der nicht warten soll.
- **Technik:**
  - Eigenes Fenster über dem Ziel (`WS_EX_LAYERED`, `WS_EX_NOACTIVATE`, vom Formular besessen): Abdunklung, Ring, Text und Knopf per GDI+ mit Alphakanal. Es folgt dem Ziel bei Bewegen, Größe, Scrollen, Minimieren und DPI-Wechsel (`PPGWatchControl`). Ohne DWM bzw. im Remote-Desktop: gleichmäßige Deckkraft ohne Verlauf.
  - **Eingaben sperren ohne Grau:** Maus fängt das Fenster ab. Tastatur für Fenster im Ziel verwirft ein Nachrichtenhaken (`PPGAddMessageHook`); Esc löst bei `ShowCancel` Abbrechen aus. Alt+F4 auf ein gesperrtes Formular wird abgefangen. Das Ziel bleibt `Enabled` und sieht unverändert aus.
  - Ring über den gemeinsamen Animator; der Hauptthread bleibt frei, weil die Arbeit im Thread läuft.
  - Screenreader: Beim Erscheinen wird `Text` angesagt, Fortschritt als Wert, Abbrechen als Knopf.
- Grundlage für das Spotlight-Overlay der Tour (Phase 16): Fenster, Mitlaufen und Abdunklung kommen in eine gemeinsame Basis `PPG.Overlay`.

## 19d – Demo, Tests, Doku, Prüfung
- **Demo:** neue Karte „Formular prüfen“ (Kundenformular mit Pflichtfeldern, E-Mail, PLZ, Passwort wiederholen, Von/Bis-Datum, AGB-Kästchen, Sammelleiste, OK nur bei gültigen Daten; Felder auf zwei Reitern, damit der Sprung sichtbar ist). Datenbankseite: Validator mit Regeln aus den Feldern. Karte „Warten“: Export von 1 000 000 Zeilen über `Run` mit Fortschritt und Abbrechen. Selbsttest-Szenarien.
- **Tests (`PPG.Tests.Phase19`):** jede Regelart mit gültigen/ungültigen Werten (Tabelle), Adapter je Control, Markieren/Zurücksetzen ohne fremde Zustände zu zerstören, Sprung über Reiter und Expander, `CheckOnClose` mit verkettetem `OnCloseQuery`, Regeln aus `TField`, Overlay: Lage folgt dem Ziel, Tastatur gesperrt, Esc bricht ab, `Delay`/`MinDisplayTime`, Exception aus dem Thread, Streaming, Leak-Lauf, Sichtgalerie.
- **Doku:** Hilfe-Notizen, Property-Referenz, Architektur, Roadmap3, `NAECHSTE-SCHRITTE.md`; Texte nach `PPG.Consts` und `Lang\PPGlow.de.txt`; neue Units in alle Projektlisten (inkl. XE2).

## Entscheidungen (mit Empfehlung)
1. **Arbeit, die den Hauptthread blockiert:** Ein Overlay kann sich nur bewegen, wenn die Nachrichtenschleife läuft. *Empfehlung:* `Run` (Arbeit im Thread) als Hauptweg und für Altcode `Show` mit einem einmalig gezeichneten Overlay (steht, animiert aber nicht). Ein eigener Overlay-Thread für blockierenden Code wäre möglich, ist aber fehleranfällig (gekoppelte Eingabewarteschlangen, Fenster zweier Threads) und kommt nicht.
2. **Fremde Controls** (VCL/TMS ohne `ValidationState`): *Empfehlung:* nur Sammelanzeige, Fokus und `OnShowError`, kein gezeichneter Rahmen über fremden Controls.
3. **Wann prüfen:** *Empfehlung:* Vorgabe `voExit`, nach einem Fehler live beim Tippen.
4. **Regeln aus `TField` automatisch:** *Empfehlung:* ja, abschaltbar (`AutoFieldRules`).

## Reihenfolge
19a → 19b → 19c → 19d, Bericht nach 19d. Zwischenstände in `NAECHSTE-SCHRITTE.md`.

## Verifikation
- `Build\check-rules.ps1`, `build.ps1` (alle Projekte, Win32 und Win64)
- `Tests\PPGlowTests.exe` (0 = grün) und `/leaks`, Win32 und Win64
- `Demo\PPGlowDemo.exe /selftest datei.txt`, Screenshots der neuen Karten (Fehlerzustände, Overlay hell/dunkel) vergrößert ansehen
- Benchmark: Validator mit 500 Regeln, `Validate` < 50 ms

## Umsetzung (09.10.2026)
Umgesetzt in der Reihenfolge 19a → 19d, je Teil ein Commit.

- **19a** (`PPG.Validator`): Regeln `vrRequired`, `vrLength`, `vrRange`, `vrPattern` (`vpEmail`, `vpPhone`, `vpPostalCodeDE`, `vpIBAN` mit Prüfsumme, eigener Ausdruck), `vrCompare`, `vrCustom`; `Validate`, `ValidateGroup`, `ValidateChildren`, `ValidateControl`, `ClearResults`, `FocusFirstError`, `Results`/`ResultFor`, `ShowValid`, `OnShowError`. Adapter-Registry (`PPGRegisterValidationAdapter`) für PPGlow-Felder, Auswahlgruppen, Kästchen und VCL-Edit/ComboBox/CheckBox/DateTimePicker. Neue Nachricht `CM_PPGVALUECHANGED` (`PPG.Types`), die Felder, Kästchen und Auswahlgruppen bei jeder Wertänderung an sich selbst schicken.
- **19b:** `PPG.DB.Validator` (Feldregeln aus `TField` per RTTI für jedes Control mit Property `Field`, auch VCL), `SummaryBar`, `CheckOnClose`, `SubmitControl`, `Wizard`; Komponenteneditor mit „Edit rules…“ und „Add required rules for all fields“.
- **19c:** `PPG.Overlay` (`TPPGDimWindow`, `PPGOverlayRect`, `PPGWindowInTarget`) und `PPG.BusyOverlay` (`Show`/`ShowNow`/`Hide`, `Run`, `RunAsync`, `IPPGBusyContext`, Karte `TPPGBusyCard`).
- **19d:**
  - Demo: Die Formularseite prüft jetzt per Validator statt mit Handcode (vier Prüfroutinen entfallen). Neue Karte „Bestellung“ mit zwei Reitern, Sammelleiste und Übertragung über `Run`. Die Datenbankseite prüft vor dem Speichern die Pflichtfelder aus `TField`. Neu ist der Schalter `/busycapture busy|errors datei.png`, zwei Katalogeinträge.
  - Tests: `Tests\PPG.Tests.Phase19.pas` mit 60 Tests (Validator, Komfort, Overlay). Benchmark: `Validate` mit 500 Feldern und 1000 Regeln dauert 15 ms (500 Fehler) bzw. 32 ms (alles gültig), Vorgabe 50 ms.
  - Doku: Hilfe-Notizen, `Docs\Controls\props\80-formular.txt`, Architektur. `docs-parser.ps1` überspringt jetzt `class of` (vorher wurde die nächste Klasse verschluckt).
- **Prüfung:** 1420 Tests Win32 und Win64, Leak-Lauf Win32/Win64 grün (kein Zuwachs), Demo-Selbsttest 171/171, Benchmark eingehalten, Regel-Prüfer ohne Verstöße. Sichtprüfung der Aufnahmen `/busycapture busy` und `/busycapture errors`.

**Abweichungen:**
- Overlay: zwei Fenster statt eines mit Alphakanal je Pixel. Unten liegt eine Abdunklung mit gleichmäßiger Deckkraft (fängt die Maus ab), darüber eine undurchsichtige Karte, die mit dem Renderer der Suite gezeichnet wird. Das ist einfacher, geht ohne DWM und per Remote-Desktop und nutzt die vorhandene Zeichnung.
- Reiter mit `TabVisible = False` gelten als verdeckt, nicht als ausgeblendet. Die Demo blendet die Reiterköpfe aus, weil die NavigationView navigiert; per Code umgeschaltete Seiten sind ein gängiges Muster. Nur gesperrte Reiter zählen nicht. Assistent-Seiten mit `PageVisible = False` zählen dagegen nicht (ausgelassener Schritt).
- `AutoFieldRules` gilt für alle DB-Controls desselben Besitzers. In der Demo prüft die Datenbankseite deshalb nur ihr Detailformular (`ValidateChildren`), die Validatoren der Formularseite schalten es ab.
- Die Warte-Demo überträgt keinen echten xlsx-Export, sondern simuliert die Arbeit, weil Grid und Writer VCL-Objekte sind und nicht im Thread laufen dürfen.
- Ungültige `MinValue`/`MaxValue`/`Pattern`/`Severity` werfen zur Laufzeit. Beim DFM-Laden werden sie gemeldet und verworfen (Regel der Suite: Formulare öffnen sich immer).

**Offen:**
- Der Validator markiert fremde Controls nicht (Entscheidung 2).
- Englische Standardtexte in der Demo, weil sie die Sprache nicht umschaltet (wie bisher).
- Kein XE2-Lauf.
