# Phase 9 – Detailplan: Profi-Qualität und Vertrieb

*Stand 04.10.2026. Teil der Roadmap (`Docs\Roadmap.md`). **Vom User freigegeben** (Antworten siehe unten) und in derselben Cloud-Sitzung umgesetzt (Abschnitt „Umsetzung“). **Hier gab es kein Delphi:** Es wurde nichts kompiliert und kein Test ausgeführt. Geprüft wurde mit einem Pascal-Parser (Syntax), dem Regel-Prüfer, den Selbsttests der Skripte und durch Lesen. Der erste echte Build steht noch aus.*

Phase 9 bringt keine neuen Grund-Controls mehr. Sie macht die Suite **im Alltag eines Delphi-Entwicklers** benutzbar: Komfort im Formulardesigner, Datenbank-Anbindung, volle Barrierefreiheit für Grid und Baum, Übersetzung, geprüfte Kompatibilität und eine Doku, mit der man ohne Quelltext auskommt. Alles baut auf dem Bestehenden auf (35 Paletten-Controls, Renderer-Interfaces, `TPPGAccessible`, `IPPGItemSource`, Streaming-Test, Sichttests).

## Schritt 0 – vor dem Start (mit dem User)
- Packages neu installieren (IDE schließen, Release Win32/Win64, `install.ps1`). Die IDE kennt bisher nur den Stand Phase 8.1.
- Kurzer Praxistest der Controls aus Phase 6 und 7 im Formulardesigner (Ablegen, Properties, DFM speichern/laden). Was dabei auffällt, gehört in 9a.

## Teilschritte (Vorschlag)

| Teil | Inhalt | Größe |
|---|---|---|
| **9a** | Designer-Komfort: Palettensymbole, Collection-/Item-Editoren, Appearance-Editor mit Vorschau, Preset-Galerie, Verben | mittel |
| **9b** | UI Automation für Grid, TreeView und ListBox (Tabellen-, Baum- und Auswahlmuster) | groß |
| **9c** | Datenbindung: `TPPGDBEdit`, `TPPGDBMemo`, `TPPGDBCheckBox`, `TPPGDBComboBox`, `TPPGDBLookupComboBox`, `TPPGDBDatePicker`, `TPPGDBGrid` | groß |
| **9d** | Lokalisierung: deutsche Übersetzung, Umschalten, RTL in den Sichttests | klein |
| **9e** | Kompatibilität und Prüfung: Regel-Prüfer (läuft ohne Delphi), DPI-Läufe 100/150/200 %, Vorbereitung XE2/10.x | mittel |
| **9f** | Doku und Demo: Demo als Katalog mit Suche, Hilfe pro Control, Migrationsleitfaden VCL/TMS → PPGlow | mittel |

Reihenfolge-Idee: 9a zuerst, weil der Designer-Komfort jedes weitere Ausprobieren erleichtert. 9b vor 9c, weil das DB-Grid das UIA-Tabellenmuster des Grids gleich mitbekommt. 9d–9f sind unabhängig und klein genug, um am Ende zu folgen.

## 9a – Designer-Komfort

Alles liegt ausschließlich im Design-Package `dclPPGlow` (Regel in `PPG.Reg.pas`: `DesignIntf` nie in Anwendungen). Jeder Editor fängt Exceptions und zeigt sie an, die IDE darf nie instabil werden.

| Baustein | Kern |
|---|---|
| **Palettensymbole** | Eine `PPGlow.dcr` mit Bitmaps je Klasse in 16, 24 und 32 px (Ressourcennamen `TPPGBUTTON`, `TPPGBUTTON16`, `TPPGBUTTON32` wie von der IDE erwartet). Erzeugt per Skript `Build\make-icons.ps1` aus den Fluent-Glyphen (dieselbe Quelle wie `PPG.IconFont`) mit einem Akzentpunkt als PPGlow-Erkennungszeichen; ohne Symbolschrift einfache Formen. Das Skript schreibt BMPs und kompiliert sie mit `brcc32`/`cgrc` zur `.dcr`. Die Bitmaps werden eingecheckt, damit kein Rechner die Schrift braucht |
| **Item-Editoren** | Verb „Items bearbeiten…“ bzw. Doppelklick: Für flache Collections (`ItemsEx` von ListBox/CheckListBox/ComboBox, `Grid.Columns`, `StatusBar.Panels`, `ToolBar.Items`) öffnet der Standard-Collection-Editor (`ShowCollectionEditor`). Eigener Baum-Editor für die verschachtelten Einträge der `TPPGNavigationView` (Unterpunkte anlegen, einrücken, ausrücken, verschieben) und für `TPPGTreeView.Items` (wie der Items-Editor von `TTreeView`: Text, Bild, Detail, Plakette, Haken) |
| **Appearance-Editor** | Modaler Dialog mit den Zuständen (Normal, Hover, Gedrückt, Fokus, Deaktiviert, Checked) links und einer **Live-Vorschau mit echten PPGlow-Controls** rechts (hell und dunkel nebeneinander). Arbeitet auf einer Kopie (`Assign`); OK schreibt zurück und ruft `Designer.Modified`, Abbrechen verwirft. Knopf „Preset-Werte“ entspricht dem vorhandenen Verb |
| **Preset-Galerie** | Verb am Formular-Control bzw. am `TPPGStyleManager`: „Preset auf das ganze Formular anwenden…“. Zeigt die registrierten Presets (`TPPGRendererRegistry.GetNames`) als Vorschau-Kacheln hell/dunkel; Übernehmen setzt `Preset` aller PPGlow-Controls des Formulars (`Designer.GetRoot`) in **einem** Undo-Schritt |
| **Verben je Control** | Kurze, häufige Aktionen ohne Objektinspektor, z. B. PageControl (vorhanden), Grid „Spalten bearbeiten…“/„Zeilen und Spalten…“, NavigationView „Mit PageControl verbinden…“, NotificationCenter „Test-Toast zeigen“, ListBox „Beispieleinträge“. Echte Smart-Tags gibt es im VCL-Designer nicht; Verben sind der Ersatz |
| **Selection-Editor** | `RegisterSelectionEditor` ergänzt beim Ablegen fehlende Units in der `uses`-Liste (z. B. `PPG.Types` für Aufzählungen in Ereignis-Signaturen), damit generierte Event-Handler sofort kompilieren |

Fallstricke:
- Der Komponenteneditor bekommt das Control des Formulars; Änderungen ohne `Designer.Modified` gehen beim Speichern verloren.
- Vorschau-Controls im Dialog dürfen sich nicht beim globalen `TPPGStyleManager` des Formulars anmelden (eigener Manager oder `StyleManager := nil`), sonst färbt die Vorschau das Formular.
- Die 64-Bit-IDE (Delphi 12/13) lädt dasselbe Design-Package als Win64 – alle Editoren müssen ohne Zeigerarithmetik auf 32 Bit auskommen.

## 9b – UI Automation (Grid, TreeView, ListBox)

**Warum:** MSAA kennt keine Tabellen und keine Hierarchie. Das Grid meldet heute nur Zeilen als Kinder (Abweichung aus Phase 6), der Baum nur eine flache Liste. Narrator und NVDA können so weder „Zeile 5, Spalte Preis“ ansagen noch „Ebene 2, aufgeklappt“.

**Weg:** Ein eigener, nativer UIA-Provider nur für die drei Daten-Controls. Alle anderen Controls bleiben bei `TPPGAccessible` (MSAA, von Windows nach UIA übersetzt), das funktioniert dort gut.

| Baustein | Kern |
|---|---|
| `Source\Access\PPG.UIA.Intf.pas` | Eigene Deklaration der benötigten UIA-Interfaces und Konstanten (GUIDs aus `UIAutomationCore.h`), so wie MSAA mit festen eigenen Typen importiert wird. Damit gleich ab XE2, unabhängig von `PPG_HAS_UIA` und davon, was die VCL der jeweiligen Version selbst mitbringt. `UiaReturnRawElementProvider`, `UiaHostProviderFromHwnd`, `UiaRaiseAutomationEvent`, `UiaRaiseAutomationPropertyChangedEvent`, `UiaClientsAreListening`, `UiaDisconnectProvider` werden **dynamisch** aus `UIAutomationCore.dll` geladen (fehlt eine Funktion, bleibt es bei MSAA) |
| `Source\Access\PPG.UIA.pas` | `TPPGUiaProvider` (Wurzel: `IRawElementProviderSimple`, `IRawElementProviderFragment`, `IRawElementProviderFragmentRoot`) und `TPPGUiaElement` (Kind-Element: Zeile, Zelle, Knoten, Kopf). Die Controls liefern die Daten über ein schmales Interface `IPPGUiaSource` (DIP, wie `IPPGAccessibleChildren`) |
| Grid | Muster `Grid`, `Table`, `GridItem`, `TableItem`, `Selection`/`SelectionItem`, `Value` (Zelltext, schreibbar wenn editierbar), `ScrollItem` (Zelle ins Bild holen). Spalten- und Zeilenköpfe als `ColumnHeaders`/`RowHeaders`. Sichtbare Zeile ↔ Datenzeile wie im Grid (Sortierung, Filter) |
| TreeView | Muster `ExpandCollapse`, `SelectionItem`, `Toggle` (Haken, drei Zustände), `ScrollItem`; Hierarchie über Fragment-Navigation (Eltern, erstes/letztes Kind, Geschwister), Ebene und Position im Satz (`Level`, `PositionInSet`, `SizeOfSet`) |
| ListBox/CheckListBox | `Selection` (Mehrfach), `SelectionItem`, `Toggle` (CheckListBox), `ScrollItem`; Gruppen als `Group`-Elemente |
| Ereignisse | Fokus, Auswahl, Auf-/Zuklappen, Wert, Struktur geändert – nur wenn `UiaClientsAreListening`, damit es ohne Screenreader nichts kostet (Benchmark unverändert) |

Fallstricke:
- **Thread:** Der Provider meldet `ProviderOptions_ServerSideProvider or ProviderOptions_UseComThreading`. Dann ruft UIA im Haupt-Thread (STA) auf, und die VCL-Regel „nur Main-Thread“ bleibt gültig. Ohne `UseComThreading` kämen Aufrufe aus fremden Threads.
- **Lebensdauer:** Elemente halten keine Zeiger auf Zeilen oder Knoten, sondern eine Kennung (Datenzeile/Spalte bzw. Knoten-ID mit Generationszähler). Ist das Ziel weg, liefern sie `UIA_E_ELEMENTNOTAVAILABLE`. Beim Zerstören des Fensters `UiaDisconnectProvider` (ab Windows 8, sonst nur Kennung ungültig).
- **Fehlergrenze:** Wie bei MSAA verlässt keine Exception eine COM-Methode (`E_FAIL` + Protokoll). Aktionen von außen (`Invoke`, `Expand`, `SetValue`) posten eine Nachricht, Anwender-Code läuft nie im COM-Aufruf.
- `WM_GETOBJECT` mit `UiaRootObjectId` wird nur beantwortet, wenn das Control einen Provider hat; `OBJID_CLIENT` bleibt bei MSAA. Unter Delphi 13 vorher prüfen, ob die VCL `UiaRootObjectId` selbst schon beantwortet (`PPG_HAS_UIA`), und das gezielt übersteuern.

## 9c – Datenbindung

**Paket:** Eigene Packages `PPGlowDBR`/`dclPPGlowDB` (Units `PPG.DB.*`), damit Anwendungen ohne Datenbank kein `Data.DB` linken. Die DB-Controls erben von den vorhandenen Controls und fügen nur die Anbindung hinzu.

| Control | Vorbild | Kern |
|---|---|---|
| `TPPGDBEdit` | `TDBEdit` | `DataSource`, `DataField`, `ReadOnly`; `TFieldDataLink`, Esc verwirft, `EditMask` des Felds nur als Zeichenfilter, `ValidationState` bei ungültigem Wert statt Dialog |
| `TPPGDBMemo` | `TDBMemo` | Memo-/Textfelder, `AutoDisplay` |
| `TPPGDBCheckBox` | `TDBCheckBox` | `ValueChecked`/`ValueUnchecked`, Null = gemischt |
| `TPPGDBComboBox` | `TDBComboBox` | Feste `Items`, Wert ins Feld |
| `TPPGDBLookupComboBox` | `TDBLookupComboBox` | `ListSource`, `KeyField`, `ListField` (mehrere Spalten in der Liste über `ItemsEx`-Detail), `FilterMode` aus Phase 6 |
| `TPPGDBDatePicker` | – | Datumsfeld, Null über `ShowCheckbox` |
| `TPPGDBGrid` | `TDBGrid` | Auf Basis von `TPPGCustomGrid`: Spalten aus den Feldern oder aus `Columns`, Datensatz-Puffer über einen `TDataLink` (`BufferCount` = sichtbare Zeilen, nie die ganze Tabelle), Indikatorspalte, Bearbeiten mit den Grid-Editoren, Einfügen/Löschen per Tastatur, Sortieren per Kopfklick über `OnTitleClick` (das Dataset sortiert, nicht das Grid), Scrollleiste nach `RecNo`/`RecordCount`, wenn `IsSequenced`, sonst dreistufig wie `TDBGrid` |

Fallstricke:
- `TDataLink`-Ereignisse kommen auch während `Paint` (z. B. durch berechnete Felder). Darin nur Zustand cachen und `Invalidate` posten, nie zeichnen (Roadmap).
- `UpdateRecord` vor dem Speichern, auch wenn der Fokus noch im Feld ist (`CM_EXIT`, `CM_GETDATALINK` für `TDataSource`-Aktionen).
- Das DB-Grid darf nie alle Datensätze holen. Die virtuelle Zeilenzahl des Grids wird nicht genutzt; das Grid zeigt nur den Puffer.
- Tests brauchen ein Dataset ohne Server: `TClientDataSet` mit `MidasLib` (gibt es ab XE2, keine DLL nötig).

LiveBindings: **Vorschlag weglassen.** Die DB-Controls decken den Bedarf; LiveBindings stehen in der Roadmap ohnehin als optional und können später über `TPPGEdit` usw. per `ObserverData` nachgerüstet werden.

## 9d – Lokalisierung

- Alle sichtbaren Texte sind schon `resourcestring` (`PPG.Consts`, `PPG.Exceptions`, `PPG.Reg`). Vorher prüfen, ob noch feste Texte in Controls stehen (z. B. Barrierefreiheits-Namen, „Heute“, „Mehr“) und sie nach `PPG.Consts` ziehen.
- **Deutsche Übersetzung** als Beispiel. Vorschlag: eine Unit `PPG.Lang.De` mit `PPGSetLanguage('de')`, die zur Laufzeit die Texte über eine Tabelle ersetzt (funktioniert in jeder Edition, auch Community ohne Übersetzungs-Manager). Alternativ der VCL-Standardweg mit Ressourcen-DLL (`.DEU`), der aber einen Build pro Sprache braucht. Wochentage und Monatsnamen kommen weiter aus `FormatSettings`.
- Ein Test prüft, dass jede englische Zeichenkette eine deutsche Entsprechung hat und die Platzhalter (`%s`, `%d`) übereinstimmen.
- **RTL:** Die Sichttests (`PPG.Tests.Visual`) bekommen eine Variante `BiDiMode = bdRightToLeft` für alle Controls; bisher ist RTL nur bei TrackBar, Kalender und einigen Reitern geprüft.

## 9e – Kompatibilität und Prüfung

| Baustein | Kern |
|---|---|
| **Regel-Prüfer** `Build\check-rules.ps1` | Prüft ohne Compiler die Coding-Rules: nur ASCII, CRLF, `{$I ..\PPG.inc}` direkt nach `unit`, jedes `{$IF` mit `{$IFEND}`, keine Inline-Variablen/`for var`, kein `NameOf`, keine Multiline-Strings, keine `}` in `{ }`-Kommentaren, neue Unit in **allen** Projektlisten (dpk/dproj Delphi 13 und XE2, Tests, Demo, Bench). Läuft lokal vor jedem Build und auch auf einem Rechner ohne Delphi |
| **DPI-Läufe** | Tests und Sichttests mit 96, 144 und 192 PPI (`ScaleForPPI` bzw. `ChangeScale`), Galerie je Stufe; prüft, dass nichts abgeschnitten wird und Linien nicht verschwimmen |
| **XE2/10.x** | Kann hier nicht gebaut werden (nur Delphi 13). Vorbereitung: `Packages\XE2` vollständig halten (Prüfer), eine Liste der Stellen mit `PPG_HAS_*` als Prüfplan; der echte Lauf erfolgt auf einem Rechner mit diesen Versionen (`build.ps1` erkennt sie) |
| **Leak-Lauf** | Ein Testlauf mit ReportMemoryLeaksOnShutdown in der Konsole, Ergebnis als Exit-Code (bisher nur in der GUI) |

## 9f – Doku und Demo

- **Demo als Katalog:** Die NavigationView bekommt ein `TPPGSearchEdit` oben (Suche über Control-Namen und Stichworte), Kategorien statt der zehn festen Seiten, pro Control eine Seite mit Beispiel und den wichtigsten Properties zum Umschalten.
- **Hilfe pro Control:** `Docs\Controls\TPPGxxx.md` (Zweck, Vorbild, wichtigste Properties/Ereignisse, Unterschiede zur VCL, Beispiel), daraus per Skript eine HTML-Hilfe. Die bisherigen „eigenen Entscheidungen“ aus `NAECHSTE-SCHRITTE.md` wandern dorthin.
- **Migrationsleitfaden** `Docs\Migration.md`: DFM-Ersetzungstabelle VCL → PPGlow (`TButton` → `TPPGButton`, `TEdit` → `TPPGEdit`, … `TStringGrid` → `TPPGGrid`, `TStatusBar` → `TPPGStatusBar`) mit den Abweichungen (z. B. `ItemHeight` als Mindesthöhe, `Checked` im Code ohne `OnClick`) sowie TMS → PPGlow (`TAdvGlowButton` → `TPPGButton` mit Property-Zuordnung). Optional ein Skript `Build\migrate.ps1`, das Klassennamen in `.dfm`/`.pas` ersetzt (mit Sicherungskopie und Bericht).

## Bewusste Entscheidungen (Vorschlag)
- Designer-Code nur im Design-Package; jeder Editor fängt Exceptions.
- UIA nur dort, wo MSAA an Grenzen stößt (Grid, Baum, Listen); eigene Interface-Deklarationen statt der VCL-Unit, damit es von XE2 bis 13 gleich funktioniert.
- DB-Controls in eigenen Packages, erben von den vorhandenen Controls (keine zweite Zeichenlogik).
- Keine LiveBindings in Phase 9.
- Übersetzung über eine Laufzeit-Tabelle, Englisch bleibt Standard.

## Tests (`Tests\PPG.Tests.Phase9a.pas` … `Phase9e.pas`, DB in eigenem Testprojekt-Teil)
- 9a: Editoren ohne IDE testbar halten (Logik in eigenen Klassen, die Dialoge nur dünn darüber): Preset auf alle Controls anwenden, Kopie/Zurückschreiben der Appearance, Baum-Editor-Operationen auf `TPPGNavItems`.
- 9b: Provider über die Interfaces direkt aufrufen (ohne Screenreader): Tabellenmaße, Zelle an Position, Köpfe, Sortierung/Filter, Auf-/Zuklappen, Toggle, ungültig gewordene Elemente, Exception-Grenze; ein Test mit echter `IUIAutomation`-Client-Abfrage (`CUIAutomation`) auf das eigene Fenster.
- 9c: `TClientDataSet` im Speicher: Anzeigen, Bearbeiten, Abbrechen, Null, Lookup, Grid-Puffer bei 100 000 Datensätzen (Benchmark-Vorgabe: 300 × scrollen + zeichnen), Ereignisse während Paint.
- 9d: Vollständigkeit der Übersetzung, Platzhalter, RTL-Galerie.
- 9e: Regel-Prüfer gegen absichtlich fehlerhafte Beispieldateien.
- Wie immer: DFM-Roundtrip (Streaming-Test auf die neuen Controls erweitern), Sichttests, Leaks.

## Fragen an den User und Antworten (04.10.2026)
1. **Umfang und Reihenfolge:** alle sechs Teile am Stück, Bericht am Ende.
2. **Datenbindung:** eigene Packages `PPGlowDBR`/`dclPPGlowDB`. Ob LiveBindings wegfallen, durfte ich entscheiden: Sie fallen weg (siehe Abweichungen).
3. **UI Automation:** nur Grid, TreeView und ListBox (Empfehlung).
4. **Übersetzung:** Laufzeit-Tabelle.
5. **Palettensymbole:** automatisch erzeugen.
6. **Migration:** Leitfaden **und** Skript `migrate.ps1`.

Außerdem: „Entscheide dich für die bessere Architektur.“

## Umsetzung (04.10.2026)

| Teil | Ergebnis |
|---|---|
| **9a** | `Build\make-icons.ps1` erzeugt `Source\Design\PPGlow.dcr` (36 Klassen) und `Source\DesignDB\PPGlowDB.dcr` (7 Klassen), jeweils 16/24/32 px. Vorschau: `Docs\palette-icons.png`. Die Logik der Editoren steht in `Source\Editors\PPG.Editors.Logic.pas` und ist ohne IDE testbar: `TPPGPresetTargets`, `TPPGNavItemOps`, `TPPGTreeNodeOps`, `TPPGAppearanceSession`. Die Dialoge stehen in `PPG.Editors.Forms.pas`: Appearance mit Live-Vorschau hell/dunkel, Preset-Galerie, Editoren für Navigations- und Baumeinträge. In `PPG.Reg` gibt es eine gemeinsame Basis `TPPGComponentEditor` mit den Verben Zurücksetzen, Darstellung und Galerie. Dazu kommen Collection-Editoren für `ItemsEx`, `Columns`, `Panels` und `Items`, „Mit PageControl verbinden…“, „Test-Toast zeigen“ und `TPPGSelectionEditor`. `dclPPGlow` braucht dafür `vclsmp`. Tests: `PPG.Tests.Phase9a` (16) |
| **9b** | `PPG.UIA.Intf` enthält eigene UIA-Deklarationen und lädt `UIAutomationCore.dll` dynamisch. `PPG.UIA` bringt `TPPGUiaRoot`/`TPPGUiaElement` mit allen Mustern sowie `IPPGUiaSource` mit Element-Kennungen (Art, A, B). Aktionen von außen laufen über eine Warteschlange per `PostMessage`. Der globale Schalter `PPGUiaEnabled` schaltet alles ab. `TPPGCustomControl` beantwortet `UiaRootObjectId` nur für Controls mit `IPPGUiaSource`. `NotifyAccessibilityChild` löst auch die UIA-Ereignisse aus. ListBox/CheckListBox (Toggle), TreeView (stabile Knoten-IDs über ein Dictionary) und Grid (Zeile, Zelle, Kopfzeile, Kopfzelle) liefern die Daten. Tests: `PPG.Tests.Phase9b` (21) mit Client-Test über `IUIAutomation` |
| **9c** | `Source\DB\PPG.DB.Controls.pas` mit `TPPGDBEdit`, `TPPGDBMemo`, `TPPGDBCheckBox`, `TPPGDBComboBox` und `TPPGDBDatePicker`; dazu `PPG.DB.Lookup.pas` (`TPPGDBLookupComboBox`) und `PPG.DB.Grid.pas` (`TPPGDBGrid` mit `TDBGridOptions`). Design: `Source\DesignDB\PPG.DB.Reg.pas` mit Palette „PPGlow DB“, Feld-Editoren und Spalten-Editor. Pakete `PPGlowDBR`/`dclPPGlowDB` für Delphi 13 und XE2; `build.ps1` und `install.ps1` kennen sie (`-NoDB`). Neue Hooks im Grid für abgeleitete Grids: `CreateColumns`, `ColumnOf`, `ColumnsChanged`, `RowScrollY`, `ScrollCellsTo`, `GetEditText`. Der DatePicker hat jetzt den Hook `UserChange`. Tests: `PPG.Tests.Phase9c` (22) mit `TClientDataSet` |
| **9d** | `PPG.Lang` stellt `PPGStr`, `PPGSetLanguage`, `PPGSystemLanguage` und `PPGOnLanguageChange` bereit. `Lang\PPGlow.de.txt` → `Build\make-lang.ps1` → `PPG.Lang.De` (39 Texte). Alle Textstellen der Runtime lesen über `PPGStr(@…)`. Die Sichttests haben eine RTL-Galerie (`RTL.png`) und eine DPI-Galerie (`DPI.png`, 96/144/192 PPI). Tests: `PPG.Tests.Phase9d` (6) |
| **9e** | `Build\check-rules.ps1` prüft die Regeln ASCII, CRLF, INCLUDE, IFEND, INLINEVAR, SYNTAX, COMMENT, RAISE, EXCEPT, PROJECT und LANG. `-SelfTest` prüft gegen `Build\check-rules-tests`. `build.ps1` ruft ihn vorher auf (`-NoRuleCheck` schaltet das ab). `.gitattributes` sorgt für CRLF. `PPGlowTests.exe /leaks` macht zwei Durchläufe und meldet Leaks als Exit-Code (Toleranz 256 KB). Prüfplan für XE2/10.x: `Docs\Kompatibilitaet.md` |
| **9f** | `Build\make-docs.ps1` erzeugt `Docs\Controls\*.md` (43 Seiten) und `Docs\Controls\html` aus den Quelltexten; eigene Hinweise kommen aus `Docs\Controls\notes`. Der Leitfaden `Docs\Migration.md` beschreibt `Build\migrate.ps1` (Klassen, Units, Umbenennungen, Entfernen unbekannter Properties, Event-Signaturen, Sicherung, Bericht, `-SelfTest`). Die Demo ist jetzt ein Katalog: Suchfeld über allen Seiten (43 Einträge, Name oder Stichwort), neue Seite „Datenbank“ (`/page 12`) und Sprachumschaltung auf „Darstellung“ |

**Abweichungen vom Plan:**
- **LiveBindings fallen ganz weg**, auch später. Die DB-Controls decken den Bedarf ab. Ein zweiter Bindungsweg würde jedes Control um Observer-Code erweitern, und den müsste man in allen Versionen testen.
- **Palettensymbole aus Vektorformen statt aus der Symbolschrift.** Das Skript zeichnet eigene Formen auf einem 32er-Raster und schreibt die `.dcr` selbst. So braucht es weder `brcc32` noch die Schrift, und das Ergebnis ist auf jedem Rechner gleich.
- **Preset-Galerie ohne gemeinsamen Undo-Schritt.** Die Open-Tools-API bietet dafür nichts Verlässliches. Die Galerie meldet die Zahl der umgestellten Controls und ruft `Designer.Modified`.
- **RTL-Galerie meldet statt zu scheitern.** Controls, die sich bei `bdRightToLeft` nicht spiegeln, erscheinen als Status. Fehler zählen nur leere oder falsch gezeichnete Zellen. Ob ein Control spiegeln muss, entscheidet der Blick auf `RTL.png`.
- **DB-Grid:** Das Sortieren übernimmt die Anwendung in `OnTitleClick`. Die Ereignisse `OnTitleClick`/`OnCellClick` haben die Signatur `(Column)` ohne `Sender`, damit migrierte `TDBGrid`-Handler passen. Spalten-Eigenschaften von `TDBGrid` wie `Color`, `Title.Font`, `Expanded` und `Visible` gibt es nicht; `migrate.ps1` entfernt sie und listet sie im Bericht auf.
- **Grid-Puffer** ist mit 1 000 Datensätzen getestet. Ein Benchmark mit 100 000 Datensätzen fehlt noch.
- **Streaming-Test:** Die DB-Controls haben einen eigenen DFM-Roundtrip in `Phase9c` (`StreamingKeepsColumnsAndOptions`) und laufen nicht durch `PPG.Tests.Streaming`.
- **Demo:** keine eigene Seite pro Control. Das Suchfeld führt zur Seite, auf der das Control im Einsatz ist; die Hilfe pro Control steht in `Docs\Controls`.
- Kein eigenes `PPG.Tests.Phase9e`. Der Regel-Prüfer testet sich selbst (`check-rules.ps1 -SelfTest`), ebenso `migrate.ps1 -SelfTest` und `make-lang.ps1 -Check`.

**Offen, nur mit Delphi prüfbar:** Build aller Projekte (Win32/Win64), die vier neuen Test-Suiten, `/leaks`, die Galerien `RTL.png`/`DPI.png`, Installation der vier Pakete, Paletten-Symbole in der IDE, Narrator auf Grid/Baum/Liste und der XE2-Lauf nach `Docs\Kompatibilitaet.md`.
