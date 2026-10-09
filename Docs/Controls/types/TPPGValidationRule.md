# TPPGValidationRule

Typ in Unit `PPG.Validator` - Basis `TCollectionItem`

Eine Regel fuer ein Control.

## Eigenschaften

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Control` | `TControl` |  | Das geprüfte Control. Lesen kann der Validator PPGlow-Felder, Auswahlgruppen, Kästchen und die VCL-Pendants; weitere über PPGRegisterValidationAdapter. |
| `Kind` | `TPPGValidationRuleKind` | `vrRequired` | Art der Regel: vrRequired (Pflicht), vrLength (Länge), vrRange (Zahl/Datum im Bereich), vrPattern (Format), vrCompare (Vergleich mit einem anderen Feld), vrCustom (eigene Regel in OnValidate). Nur vrRequired und vrCustom prüfen leere Werte. Werte: `vrRequired`, `vrLength`, `vrRange`, `vrPattern`, `vrCompare`, `vrCustom`. |
| `Enabled` | `Boolean` | `True` | False: Regel vorübergehend aus, z. B. wenn ein Feld nur bei einer bestimmten Auswahl Pflicht ist. |
| `Severity` | `TPPGValidationState` | `pvsError` | pvsError (Vorgabe) blockiert Validate und das Schließen; pvsWarning markiert gelb, hält aber nicht auf. Werte: `pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`. |
| `Caption` | `string` |  | Name des Felds in Meldungen. Leer: die Beschriftung (Label mit FocusControl), sonst der Platzhaltertext, sonst der Name des Controls. |
| `Message` | `string` |  | Eigene Meldung statt des Standardtexts; {caption} wird durch den Feldnamen ersetzt. Nutzung: `R.Message := 'Bitte {caption} angeben';` |
| `Group` | `string` |  | Name einer Gruppe: ValidateGroup('Lieferung') prüft nur Regeln ohne Gruppe und dieser Gruppe. Leer = immer dabei. |
| `MinLength` | `Integer` | `0` | Nur vrLength: geringste Zahl der Zeichen (0 = keine Grenze). |
| `MaxLength` | `Integer` | `0` | Nur vrLength: höchste Zahl der Zeichen (0 = keine Grenze); Leerzeichen am Rand zählen nicht. |
| `MinValue` | `string` |  | Nur vrRange: untere Grenze als Zahl mit Punkt („1“, „-3.5“) oder Datum („2026-01-01“); leer = keine. Ungültige Angaben werfen schon beim Setzen. |
| `MaxValue` | `string` |  | Nur vrRange: obere Grenze als Zahl mit Punkt („99.5“) oder Datum („2026-12-31“, auch mit Uhrzeit „2026-12-31 18:30“); leer = keine. |
| `PatternKind` | `TPPGValidationPattern` | `vpCustom` | Nur vrPattern: fertige Formate – vpEmail, vpPhone, vpPostalCodeDE (fünf Ziffern), vpIBAN (mit Prüfsumme) – oder vpCustom für Pattern. Werte: `vpCustom`, `vpEmail`, `vpPhone`, `vpPostalCodeDE`, `vpIBAN`. |
| `Pattern` | `string` |  | Nur vrPattern mit vpCustom: regulärer Ausdruck, der auf den ganzen Wert passen muss (er wird mit ^…$ umschlossen). Ein ungültiger Ausdruck wirft schon beim Setzen. Nutzung: `R.Pattern := '[A-Z]{2}-[0-9]{4}';` |
| `CompareControl` | `TControl` |  | Nur vrCompare: das Control, mit dessen Wert verglichen wird (z. B. „Kennwort wiederholen“ mit „Kennwort“, „Bis“ mit „Von“). Ist es leer, gilt die Regel als erfüllt. |
| `CompareOperator` | `TPPGCompareOperator` | `coEqual` | Nur vrCompare: Wert dieses Controls im Verhältnis zum Vergleichswert – coEqual, coNotEqual, coLess, coLessOrEqual, coGreater, coGreaterOrEqual. Zahlen und Daten werden als Zahl verglichen, Text genau (mit Groß-/Kleinschreibung). Werte: `coEqual`, `coNotEqual`, `coLess`, `coLessOrEqual`, `coGreater`, `coGreaterOrEqual`. Nutzung: `R.CompareControl := DateFrom; R.CompareOperator := coGreaterOrEqual;` |

## Verwendet in

[TPPGValidationRules](TPPGValidationRules.md)

---
Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.
