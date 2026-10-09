# TPPGDBNavigator

Palette **PPGlow DB** - Unit `PPG.DB.Navigator` - Basis `TPPGCustomDBNavigator`

**Vorbild:** TDBNavigator (DFM gleich: `DataSource`, `VisibleButtons`, `Hints`, `ConfirmDelete`, `Flat`, `BeforeAction`, `OnClick`)

## Unterschiede und Hinweise

- `ShowCounter` (Vorgabe an): „Datensatz 12 von 340“ bzw. „neu“; Screenreader lesen den Zähler mit.
- `ShowSearch`: Suchfeld im Navigator, Enter springt zum nächsten Treffer (Teiltreffer in `SearchField`, leer = alle Textfelder). `FindText` macht dasselbe im Code.
- `ShowFilter`: Schnellfilter auf den Suchbegriff mit Knopf zum Aufheben; ein eigenes `OnFilterRecord` der Datenmenge bleibt wirksam. Im Code `SetQuickFilter`.
- Passt nicht alles in die Breite, wandern Knöpfe in ein Überlaufmenü statt zu schrumpfen.
- Tastatur: Strg+Pos1/Ende springen an Anfang/Ende, Einfg legt an, Strg+Entf löscht.
- Nur waagerecht; `Kind` der VCL entfällt (die Migration entfernt es). `nbApplyUpdates`/`nbCancelUpdates` nutzen die Datenmengen-Schnittstelle der VCL und sind unter XE2 nicht verfügbar.
- Liegt in der Unit `PPG.DB.Navigator` (Paket PPGlowDBR).

## Beispiel

```pascal
PPGDBNavigator1.ShowSearch := True;
PPGDBNavigator1.ShowFilter := True;
PPGDBNavigator1.SearchField := 'NAME';
```

## Verhalten (aus dem Quelltext)

TPPGDBNavigator und TPPGDBRadioGroup (Phase 18c).

TPPGDBNavigator - DFM wie TDBNavigator (DataSource, VisibleButtons, Hints,
ConfirmDelete, Flat, BeforeAction, OnClick mit TNavigateBtn). Mehrwert:
- ShowCounter: "Datensatz 12 von 340" bzw. "Neuer Datensatz" (auch fuer Screenreader), ohne RecNo-Unterstuetzung nur die Anzahl.
- ShowSearch: Suchfeld; Tippen sucht ab dem aktuellen Datensatz (Feld SearchField bzw. alle Textfelder, enthaelt, ohne Gross-/Kleinschreibung), Enter springt zum naechsten Treffer, ohne Treffer rot markiert.
- ShowFilter: Knopf "Nur Treffer" filtert die Datenmenge auf das Suchwort. Dafuer haengt sich der Navigator in OnFilterRecord ein und ruft einen vorhandenen Handler zuerst auf; Filtered und Handler werden beim Aufheben wiederhergestellt.
- Ueberlauf: Passen nicht alle Knoepfe, kommen die hinteren in ein Menue.
- Tastatur (mit Fokus): Pfeile wechseln den Knopf, Leertaste/Enter loest aus; Strg+Pos1/Ende, Bild auf/ab, Einfg, Strg+Entf, F2, Strg+Enter, Esc.
- Ein Control mit selbst gezeichneten Knoepfen und Fluent-Symbolen; das Suchfeld ist ein eingebettetes TPPGSearchEdit.

TPPGDBRadioGroup - wie TDBRadioGroup (Items, Values, DataField, ReadOnly)
auf TPPGRadioGroup: Segmente und Kacheln auch fuer Datenbankfelder.

Eigene Unit (statt PPG.DB.Controls), damit die laufenden Arbeiten an den
DB-Controls (Audit Paket 4) unabhaengig bleiben.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Preset` | `string` |  | Optik-Vorlage: „Classic" (glänzend, Office-Stil), „ModernFlat" (flach mit Glow, Standard) oder „Fluent11" (Windows 11) sowie selbst registrierte Renderer. Beim Wechsel übernimmt Appearance die Farben und Formen der Vorlage. Ein unbekannter Name löst zur Laufzeit EPPGPropertyError aus; beim Laden einer DFM wird auf den Standard zurückgefallen. Nutzung: `PPGButton1.Preset := 'Fluent11';` Für alle Controls eines Formulars einheitlich über StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle (TPPGStyleManager). Ist sie gesetzt, kommen Preset, Appearance und Animation vom Manager; eigene Werte des Controls gelten dann nicht. Nutzung: Einen TPPGStyleManager aufs Formular legen und bei allen Controls zuweisen. |
| `Appearance` | [TPPGAppearance](types/TPPGAppearance.md) |  | Aussehen je Zustand: Farben, Verläufe, Rand, Glow und Textfarbe für Normal, Hot (Maus darüber), Down (gedrückt), Disabled und Checked, dazu Rundung, Randbreite, Glow-Größe, Fokusfarbe, eigene Fokus- und Dunkel-Farben. Wird beim Preset-Wechsel neu befüllt. Nutzung: `PPGButton1.Appearance.Normal.Color := $00F0E0D0; PPGButton1.Appearance.Rounding := 8;` |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Übergänge zwischen den Zuständen (Hover, Drücken, Fokus): an/aus, Dauer und ob die Windows-Einstellung „Animationen anzeigen" beachtet wird. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus verwendet das Control die Systemfarben statt der eigenen Farben (empfohlen für Barrierefreiheit). |
| `DataSource` | `TDataSource` |  | Datenquelle, die der Navigator bewegt und deren Zustand er zeigt. |
| `VisibleButtons` | `TNavButtonSet` | `[nbFirst, nbPrior, nbNext, nbLast, nbInsert, nbDelete, nbEdit, nbPost, nbCancel, nbRefresh]` | Sichtbare Knöpfe wie bei TDBNavigator; passen nicht alle in die Breite, kommen die übrigen ins Überlaufmenü. |
| `Hints` | `TStrings` |  | Eigene Hinweistexte je Knopf in der Reihenfolge von TNavigateBtn; leere Zeilen behalten den Standardtext. |
| `ConfirmDelete` | `Boolean` | `True` | Vor dem Löschen nachfragen (Vorgabe True). |
| `Flat` | `Boolean` | `False` | Knöpfe ohne Fläche, erst beim Überfahren sichtbar (wie TDBNavigator.Flat). |
| `ShowCounter` | `Boolean` | `True` | Zeigt „Datensatz 12 von 340“ bzw. „neu“; Screenreader lesen den Zähler mit. |
| `ShowSearch` | `Boolean` | `False` | Suchfeld im Navigator; Enter springt zum nächsten Datensatz, der den Begriff enthält (Teiltreffer, ohne Groß-/Kleinschreibung). Nutzung: `Nav.ShowSearch := True; Nav.SearchField := 'NAME';` |
| `ShowFilter` | `Boolean` | `False` | Schnellfilter: zeigt nur Datensätze, deren SearchField den Suchbegriff enthält; ein Knopf hebt den Filter auf. Ein vorhandenes OnFilterRecord bleibt wirksam. |
| `SearchField` | `string` |  | Feld für Suchfeld und Schnellfilter; leer = alle Textfelder. |
| `BeforeAction` | `ENavClick` |  | Vor der Aktion eines Knopfs, wie bei TDBNavigator; mit Abort im Handler unterbleibt sie. |
| `OnClick` | `ENavClick` |  | Nach der Aktion eines Knopfs; Button nennt den Knopf (gleiche Signatur wie TDBNavigator.OnClick). |

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
| `TabStop` | `Boolean` |  | True: Das Control ist mit Tab erreichbar. |
| `Visible` | `Boolean` |  | False: Das Control ist ausgeblendet und nimmt keinen Platz bei Align ein. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnContextPopup` | `TContextPopupEvent` `(Sender: TObject; MousePos: TPoint; var Handled: Boolean)` | Vor dem Kontextmenü; Handled := True unterdrückt das Standardmenü. |
| `OnEnter` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus erhalten. |
| `OnExit` | `TNotifyEvent` `(Sender: TObject)` | Das Control hat den Fokus verloren; guter Ort für Prüfungen der Eingabe. |
| `OnResize` | `TNotifyEvent` `(Sender: TObject)` | Nach einer Größenänderung. |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBNavigator.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
