# Audit-Paket 11 – Tests, Build, Demo, Doku – Detailplan

*Stand 09.10.2026. **Vom User am 09.10.2026 zur Umsetzung freigegeben; die fuenf Entscheidungen am Ende wie empfohlen.** Grundlage: `Docs\Audit-Plan.md` (Paket 11). Alle Befunde wurden am 09.10.2026 (Stand f9ad28c) neu geprüft: Testqualität über alle 1764 Testmethoden, Build-Skripte und Regel-Prüfer, Demo und Doku.*

## Leitlinie des Users (verbindlich)
> „Stelle sicher …, dass sie wirklich testen und in Zukunft Tests nicht verändert werden nur um ihn zu bestehen, sondern nur wenn er fachlich technisch nicht korrekt funktioniert.“

Daraus folgt für dieses Paket und danach:
- Ein roter Test wird nicht passend gemacht. Erst wird geklärt, ob der Code falsch ist (dann wird der Code korrigiert) oder ob der Test fachlich bzw. technisch falsch prüft. Nur im zweiten Fall wird der Test geändert, mit Begründung im Commit („Test geändert: …“) und im Bericht.
- Wird ein Test in diesem Paket schärfer und zeigt dabei einen echten Fehler, wird der Fehler behoben. Kleine Fehler werden im Paket behoben, größere kommen auf eine Liste für den User. Der Test wird nicht entschärft.
- Referenzwerte und Referenzbilder stammen immer aus dem alten Code und sind eingecheckt. Nie werden sie aus dem Code abgelesen, der gerade geprüft wird.

## Befund (Nachprüfung)
- **Sicher wirkungslos (6):**
  - `Phase10a:215` `CheckTrue(Txt = Txt)`
  - `Audit8A:1410` `CheckTrue(True)`
  - `Phase10e:160` (`on Exception do;` verschluckt das eigene `Fail`)
  - `Phase14c:116` (Hash mit sich selbst verglichen)
  - `Audit7A:721` (`>= -1`)
  - `Audit8B` `PaintUnchanged`: Die Referenzbilder entstanden nach dem Umbau und sind nicht eingecheckt.
- **Fehlschlag verschluckt (7):** `Audit8B:1217`, `Check:238`, `Controls:684`, `Gaps:556`, `Phase3:890`, `Phase10d:1033`, `Phase10e:159`. Dazu kommen 5 Stellen, die jede Exception als Erfolg werten (`13a:338`, `13d:665`, `13e:353`, `12c:309`, `Audit8B:1221`).
- **Fast immer wahr oder zirkulär:**
  - Fast immer wahr: `Phase4a:1162`, `Phase8:180`.
  - Zirkulär (Erwartung nach derselben Formel bzw. Locale wie der Code): `Phase4b:737` (Radzeilen), `Phase10c:434/556`, `Phase10b:441`, `Phase13e:247`.
  - `Audit45` `CheckRejects` prüft nicht, dass der Wert nach der Ablehnung unverändert bleibt.
- **Stilles Überspringen (rund 25 Stellen):** `Exit`/`Status` in Phase3, Gaps (fester Styles-Pfad), Phase9b, 10c, 10d, Audit7A, Audit8D (PPI ≠ 96), Visual und Audit8B. Ein fehlendes Referenzbild gilt als bestanden. Tests, die bei Hochkontrast oder RTL ohne Änderung bleiben, melden nur `Status`.
- **Zentral ungeprüft:** `TControlTestCase.TearDown` prüft weder abgefangene Zeichenfehler (`FErrors`) noch Anwendungs-Exceptions. Theme, Sprache, GDI-Rückfall, Hochkontrast-Simulation und FormatSettings werden nicht zentral zurückgesetzt.
- **Zeit:** 22 Zeit-Asserts mit `GetTickCount` und rund 25 `Sleep` in Unit-Tests. Sie kippen unter Last, z. B. `TRibbonTests.ManyItemsStayFast`.
- **Abdeckung:**
  - Streaming prüft 43 von 84 Paletten-Controls (keine DB-Controls). Es verschluckt Fehler im Setter und prüft nicht, ob ein Wert übernommen wurde.
  - In der Visual-Galerie fehlen 19 sichtbare Controls und alle DB-Controls.
  - Zeichentests mit GDI-Rückfall fehlen für die Phasen 10e–17.
  - 36 „PaintsWithoutError“-Tests prüfen nur, dass keine Exception kommt.
  - Schwach getestet: Render.Classic/ModernFlat, VclStyles, ToolBar, Dialogs, Wizard, MenuBar, Hints/CustomHint, Breadcrumb, Rating, Mask/Password/FileEdit, ColumnCombo/CheckCombo, DB-Felder/Lookup, Kanban-/Planer-Druck, Editors.Forms, `PPGLoadICal` (Datei), `PPGGetTokenColor`.
- **Ordnung:** doppelte Klassennamen (`TLayoutTests`, `TStreamingTests`); kein Index „Control → Testunit“.
- **Frühere Teständerungen:** Alle bis auf eine waren fachlich begründet (Verhaltensänderungen nach Entscheidung, gemeldete Fehler). Die eine Ausnahme ist `Phase4b:737-746` (Hochkontrast-Commit 3d2062f): Die Erwartung wurde aus der Implementierung nachgebaut. Sie wird korrigiert (11a #6).
- **Win64-Referenzwerte der Planer-Layout-Tests (`Audit8D`):** Am 09.10.2026 mit dem alten Code (3594b0b, Win64) nachgeprüft, er lieferte genau diese Werte. Das wird im Test-Kommentar und hier festgehalten und beim Umbau noch einmal reproduzierbar nachgewiesen (11a #3).
- **Build:**
  - B1: Ein abgebrochener Build ohne Abschlussmarke gilt als Erfolg.
  - B2: Ein Tippfehler in `-Projects` startet `bds` auf den Ordner (600 s).
  - B3: natives `2>&1` unter `Stop`.
  - B4: Ein `throw` im Win64-Build beendet `install.ps1` sofort.
  - B5: `-Uninstall` ändert die Registry vor der Sicherung.
  - B6: Exit-Code von `reg export` ignoriert, PATH weder gesichert noch zurückgenommen.
  - B7: fester Pfad statt `BDSCOMMONDIR`.
- **Regel-Prüfer:** 11 Regeln; ohne Negativbeispiel für PROJECT und LANG.
- **Demo:**
  - 20 Paletten-Controls fehlen im Katalog, 7 kommen in der Demo gar nicht vor (GroupBox, CustomHint, KanbanPrinter, DBMaskEdit, DBColorPicker, DBCheckComboBox, DBRadioGroup).
  - Kein Selbsttest „jedes Control im Katalog“.
  - Die Texte sind englisch (keine deutsche Übersetzung aktiv).
  - Der GDI-Rückfall braucht einen Neuzeichnen-Workaround.
  - Das Preset wird per Schleife statt per StyleManager gesetzt.
- **Doku:**
  - `NAECHSTE-SCHRITTE.md` hat viele veraltete und widersprüchliche Stellen sowie kaputte Pfade.
  - `Architektur.md`: Seitenzahl, `Smooth`, Benchmark-Tabelle, Umbenennungsregel, fehlende Schalter `/hidden` und `/suite`, Leistungsabschnitt fehlt.
  - `Roadmap3.md`: Kopf und Phase 17.
  - `Coding-Rules.md`: `PPGStr` vs. `CreateRes`, `DefineProperties` vs. „ohne Aliase“, fehlende Regel „Referenz nach Anwender-Ereignis“, unvollständige Liste der catch-all-Grenzen.
  - DatePicker-Hilfe veraltet, `Kompatibilitaet.md` zu optimistisch.

## 11a Testintegrität (zuerst)
| # | Inhalt |
|---|---|
| 1 | **Regeln festschreiben:** neuer Abschnitt „Testintegrität“ in `Docs\Coding-Rules.md` (Leitlinie oben, Begründungspflicht, Referenzdaten aus altem Code, keine Zeit-Asserts in Unit-Tests, Systemabhängigkeiten einspeisen statt Formel/Exit, Skip nur über `Skip(Grund)`). |
| 2 | **Zentrale Prüfung im TearDown** von `TControlTestCase`: abgefangene Zeichenfehler und Anwendungs-Exceptions führen zum Fehlschlag. Danach wird zurückgesetzt: Theme-Modus, Sprache, `ForceGdiFallback`, Hochkontrast-Reader, FormatSettings, Mess- und Schatten-Caches. Was dabei rot wird, ist ein echter Fehler und wird im Code behoben. |
| 3 | **Referenzdaten:** Die Audit8B-Bilder werden aus 72f9e8a (Testcommit vor dem Grid-Umbau) erzeugt und eingecheckt; danach wird gegen sie geprüft. Ein fehlendes Referenzbild ist ein **Fehler**, angelegt wird nur mit dem Schalter `/baseline`. Die Win64-Planer-Digests werden mit 3594b0b nachgewiesen und belegt. |
| 4 | **Wirkungslose und verschluckende Tests reparieren:** die 6 wirkungslosen, die 7 verschluckenden, die 5 „jede Exception“-Stellen (konkrete Klasse statt `Exception`), die fast immer wahren Prüfungen und `CheckRejects` (Wert unverändert). |
| 5 | **Überspringen:** Neuer Helfer `Skip(Grund)`, am Ende gezählt und namentlich ausgegeben. Ohne `/allowskip` ist ein übersprungener Test **rot**. Umgebungsabhängigkeiten werden eingespeist, damit hier nichts mehr überspringen muss: PPI fest 96, Animationen per Haken, Radzeilen per Reader, Styles-Pfad aus der Registry, UIA-Verfügbarkeit. |
| 6 | **Zirkuläre Erwartungen auflösen:** Radzeilen-Reader (wie `PPGSetHighContrastReader`) und Literal statt Formel (`Phase4b`, `Audit7A`); feste `TFormatSettings` und Literale (`Phase10b/10c`); Datum per Zeitquelle (`Phase13e`). |
| 7 | **Zeit raus aus Unit-Tests:** Die 22 Zeit-Asserts wandern als Messung in den Benchmark (mit Vorgabe); im Unit-Test bleibt die fachliche Prüfung. Die `Sleep`-Wartezeiten der Tippsuche werden durch eingespeiste Ticks ersetzt; Warteschleifen auf Fenster und Zwischenablage bleiben, aber begrenzt und mit Fehlschlag statt `Status`. |
| 8 | **Regel-Prüfer für Tests (TESTS):** `CheckTrue(True`/`Check(True`; `Check`/`Fail` in `try` mit `except` ohne `raise` bzw. `on Exception`/`on EAbort` (DUnit-`ETestFailure` erbt von `EAbort`); `Exit` vor dem ersten Check nur über `Skip`. Mit Negativbeispielen. |

## 11b Abdeckung
| # | Inhalt |
|---|---|
| 1 | **Streaming** aus der Liste in `PPG.Reg`/`PPG.DB.Reg` (alle 84, DB-Controls mit Attrappen-DataSource); prüft, dass der Setter den Wert übernimmt; nur `EPPGPropertyError` wird erwartet, eine Zugriffsverletzung ist ein Fehler. Set-, Klassen- und Collection-Properties (Font, Appearance, Styles) über DFM-Rundreise. |
| 2 | **Visual-Galerie** um die 19 fehlenden sichtbaren Controls und die DB-Controls erweitern; neue Referenzbilder nur für neu aufgenommene Controls (angesehen, eingecheckt). Bei Hochkontrast und RTL eine Liste der Controls mit erwarteter Änderung; dort ist „keine Änderung“ ein Fehlschlag. |
| 3 | **GDI+ und GDI-Rückfall** je Unit der Phasen 10e–17 und für die Audit-Controls: zeichnet, nicht leer, Zustand ≠ Normal. |
| 4 | **Die 36 „PaintsWithoutError“-Tests** prüfen zusätzlich „nicht leer“ und „Zustand sichtbar“ (Muster `Visual.pas:882-905`); der Kanban-Smoke-Test bekommt Pixelproben je Zustand. |
| 5 | **Schwach getestete Bereiche** bekommen Verhaltenstests: Render-Presets, VclStyles, ToolBar, Dialogs, Wizard, MenuBar, Hints/CustomHint, Breadcrumb, Rating, Mask/Password/FileEdit, ColumnCombo/CheckCombo, DB-Felder/Lookup, Kanban-/Planer-Druck, Editors.Forms, `PPGLoadICal` (Datei mit und ohne BOM), `PPGGetTokenColor` (alle Arten). |
| 6 | **Ordnung:** doppelte Klassennamen umbenennen; `make-docs.ps1` erzeugt einen Index „Control → Testunits“ und auf jeder Control-Seite eine Zeile „Tests:“. |

## 11c Build-Skripte
B1 (nur „Erfolg“/„Success“ zählt, sonst Fehler bzw. „Timeout“), B2 (unbekannte Projekte sofort abweisen, `Test-Path -PathType Leaf`), B3 (lokal `Continue`), B4 (try/catch um den Build in `install.ps1`), B5 (Sicherung vor Uninstall), B6 (PATH-Schlüssel mitsichern, `reg export` prüfen, PATH nur zurücknehmen, wenn `install.ps1` ihn eingetragen hat – Marker), B7 (`BDSCOMMONDIR` aus Registry bzw. `rsvars.bat`). B8 (XE2-Suffix, msbuild ohne `.dproj`) bleibt Paket 10. **`install.ps1` wird nicht ausgeführt** (nur `-WhatIf`-artige Trockenläufe, falls vorhanden); Prüfung per Lesetest und `build.ps1`-Läufen.

## 11d Regel-Prüfer
Neue Regeln mit je einem Negativbeispiel in `check-rules-tests`, dazu Fälle für PROJECT und LANG:
- `Data.*`/`Datasnap.*`/`Vcl.DB*` nur in `Source\DB`; `DesignIntf` & Co. nur in `Source\Design*`.
- Sperrliste unqualifizierter RTL/VCL-Units; `TImageIndex` außer `PPG.Types`; `TTimer`/`SetTimer` außer `PPG.Animation`.
- `requires` gleich in XE2 und Delphi 13.
- Schichtmatrix (Core ↛ Controls/Render/Theme/Access usw.) – vorher den einzigen echten Verstoß beheben: `PPGStripMarkup` aus `PPG.Markup` nach Core (ICal).
- `except` ohne Klassenfilter und ohne `raise` nur an markierten Grenzen (Kommentar „Grenze“) bzw. in `Access\`, `PPG.ErrorHandler`, `PPG.Animation`; Liste der Grenzen in den Coding-Rules vervollständigen.
- Sichtbare Texte eng: `Caption`/`Hint`/`Text :=` mit Literal aus mindestens zwei Buchstaben außerhalb der Design-Units.
- XE2-Verbotsliste (`FMod`, unqualifiziertes `TCollectionNotification`/`cn*` in Units mit Generics, `DocumentProperties(… nil …)`) – vorher die 7 Stellen beheben (`PPG.ColorSpace`, `PPG.NavigationView`, `PPG.Print`; ohne XE2 nur unter Delphi 13 geprüft).
- Nicht umgesetzt: Systemfarben-Regel (rund 50 Treffer, fast alle legitim) und „Testmethode ohne Check“ (unzuverlässig ohne Aufrufanalyse).

## 11e Demo
- Katalog um die 20 fehlenden Controls ergänzen. Selbsttest: jedes Paletten-Control steht im Katalog (Liste in der Demo, Abgleich gegen `RegisterComponents` durch den Regel-Prüfer).
- Kleine Demo-Karten für die 7 fehlenden Controls (GroupBox, CustomHint, Druck-Verb auf der Kanban-Seite, DB-Mask/Color/CheckCombo/RadioGroup auf der DB-Seite).
- Die Demo startet auf Deutsch (`PPGSetLanguage('de')`), Englisch bleibt umschaltbar; Selbsttest und Aufnahmen prüfen.
- `ForceGdiFallback` bekommt einen Setter, der alle Formulare neu zeichnet (über einen Hook, Render kennt Theme nicht); der Workaround in der Demo entfällt.
- Preset über einen `TPPGStyleManager`. Vorher prüfen, ob PopupMenu, TeachingTip, NotificationCenter und Hints einen StyleManager nehmen; falls nicht, ist das die eigentliche Lücke und wird geschlossen.

## 11f Doku
- **`NAECHSTE-SCHRITTE.md`:** oben ein kurzer, richtiger Stand; die Historie wandert nach `Docs\Verlauf.md`. Veraltete Aussagen und kaputte Pfade werden korrigiert, die IDE-Prüflisten kommen in „Nach der nächsten Installation prüfen“.
- **`Docs\Architektur.md`:** neuer Abschnitt **„Leistung“** mit den Messwerten aus Paket 8 (vorher/nachher), den Bausteinen und dem Messablauf; die alten Tabellen verweisen darauf. Dazu Seitenzahl, `Smooth`, Umbenennungsregel und die Schalter `/hidden`, `/suite`, `/leaksuites`, `/baseline`, `/allowskip`.
- **`Docs\Coding-Rules.md`:**
  - Abschnitt Testintegrität (11a #1).
  - `PPGStr` zur Laufzeit, `CreateRes` nur in Design/Editors.
  - Umbenennen ohne Aliase, bis die Suite in einem Projekt läuft.
  - Neue Regel „Referenz nach Anwender-Ereignis prüfen“.
  - Liste der catch-all-Grenzen.
- **Übrige Dateien:** `Docs\Roadmap3.md` (Kopf, Phase 17 fertig, Entscheidungen beantwortet); DatePicker-Hilfe (`props`/`notes`, `make-docs`); `Docs\Kompatibilitaet.md` ehrlich (XE2-Weg ungetestet, Schalter ergänzt); Kommentar in `PPG.ProgressBar.pas:13`.

## Reihenfolge und Arbeitsweise
11a zuerst (Regeln, TearDown, Referenzdaten), weil alles Weitere darauf aufbaut. Danach parallel in Worktrees: **T1** 11a #4–#8 (Testintegrität), **T2** 11b (Abdeckung), **T3** 11c + 11d (Build, Regel-Prüfer), **T4** 11e + 11f (Demo, Doku). Jeder Agent bekommt die Leitlinie wörtlich mit. Tests laufen immer mit `/hidden`. Jede Teständerung steht im Bericht mit fachlichem Grund. Neue Fehler, die schärfere Tests aufdecken, kommen als eigene Liste in den Bericht.

## Verifikation
- `check-rules.ps1 -SelfTest` und `check-rules.ps1`; `build.ps1` alle sechs Projekte Win32, Tests Win64.
- `PPGlowTests.exe /hidden` und `/leaks /hidden` Win32/Win64: grün **ohne** übersprungene Tests (ohne `/allowskip`); Anzahl der Skips = 0.
- Gegenprobe Testintegrität: Einige absichtlich eingebaute Fehler (z. B. Summen falsch, Setter ohne Wirkung, Paint wirft) müssen rot werden; danach wieder entfernen. Das Ergebnis kommt in den Bericht.
- Benchmark `/hidden` (neue Messungen aus den Zeit-Asserts), Demo `/selftest /hidden` inkl. „jedes Control im Katalog“, `make-docs` 0 fehlend.
- Nichts installieren.

## Entscheidungen (User, 09.10.2026: alle fuenf wie empfohlen)
1. **Übersprungene Tests sind ohne `/allowskip` rot.** Alle heutigen Gründe (PPI, Animation, Radzeilen, Styles-Pfad, UIA) werden eingespeist, sodass hier 0 übrig bleiben. Empfehlung: ja.
2. **Zeit-Asserts nur noch im Benchmark**, nicht mehr in Unit-Tests. Empfehlung: ja.
3. **`NAECHSTE-SCHRITTE.md` kürzen**, Historie nach `Docs\Verlauf.md`. Empfehlung: ja.
4. **Demo startet auf Deutsch.** Empfehlung: ja.
5. **Echte Fehler, die schärfere Tests finden:** kleine im Paket beheben, größere als Liste an dich. Empfehlung: ja.

## Umsetzung (09./10.10.2026)

Zwei Wellen in Git-Worktrees. Welle 1: **F** Testgrundlage, **B** Build-Skripte und Regel-Prüfer, **D** Demo und Doku. Welle 2: **T** Reparatur bestehender Tests, **C** Abdeckung, **R** `ValidationHint` der Auswahlgruppen (Wunsch des Users während des Pakets). Jeder Agent bekam die Leitlinie wörtlich mit. Jede Teständerung steht im Commit als „Test geändert: …“.

Ergebnis: **1818 Tests Win32 und Win64 grün, 0 übersprungen (ohne `/allowskip`)**, vorher 1764. Leak-Lauf Win32/Win64 ohne Leck. Alle sechs Projekte gebaut. Regel-Prüfer ohne Verstoß (Selbsttest mit Negativbeispielen je Regel). Demo-Selbsttest 205/205 (vorher 185), `make-docs` 0 fehlend. Benchmark: alle Vorgaben eingehalten, einschließlich der aus den Unit-Tests übernommenen Zeitmessungen (`Bench11`). Nichts installiert.

**Testintegrität (F, T):**
- **Regeln:** Abschnitt „Testintegrität“ in `Docs\Coding-Rules.md`.
- **Zentrale Prüfung im `TControlTestCase.TearDown`:** abgefangene Zeichenfehler und Anwendungs-Exceptions führen zum Fehlschlag (`ExpectErrors` für absichtlich provozierte). Der globale Zustand wird zurückgesetzt: Theme, Sprache, GDI-Rückfall, Hochkontrast, FormatSettings, Caches und die eingespeisten Systemwerte.
- **Referenzdaten:** Ein fehlendes Referenzbild ist ein Fehler (anlegen nur mit `/baseline`). Die Grid-Referenzbilder aus Paket 8 wurden aus dem Code vor dem Umbau (72f9e8a) erzeugt und eingecheckt; der aktuelle Code ist pixelgleich. Die Win64-Planer-Digests sind mit dem alten Code (3594b0b) nachgewiesen.
- **Überspringen:** `Skip(Grund)`, ohne `/allowskip` rot; am Ende des Laufs Zählung und Liste. Auf diesem Rechner 0 Skips, weil PPI, Animationen, Radzeilen und die Uhr der Tippsuche eingespeist werden (`PPGSetWheelScrollLinesReader`, `PPGSetSystemAnimationsReader`, `PPGSetTypeAheadClock`).
- **Reparatur der Prüfungen:** 6 wirkungslose, 7 verschluckende und 5 „jede Exception“-Prüfungen. Dazu fast immer wahre und zirkuläre Erwartungen; letztere sind jetzt Literale, darunter die eigene Formel-Erwartung aus Paket 7 in `Phase4b`.
- **Zeit:** Die Zeitgrenzen sind aus den Unit-Tests in den Benchmark gewandert, `Sleep` ist durch eingespeiste Uhren ersetzt.
- **Regel TESTS im Regel-Prüfer:** `CheckTrue(True)`, verschluckte Fehlschläge, `Exit` ohne `Skip`. Sie fand beim Zusammenführen sofort eine Stelle im neuen Streaming-Test, die nun Fehlschläge ausdrücklich weiterreicht.
- **Gegenproben:** absichtlich eingebaute Fehler (Zeichenfehler, falsche Exception-Klasse, Setter ohne Wirkung, Radzeilen, Hash, iCal-Kodierung u. a.) machten die zuständigen Tests rot.

**Abdeckung (C):**
- **Streaming:** über alle 84 Paletten-Controls (vorher 43). Geprüft wird, dass der Setter den Wert übernimmt; dazu Set-, Klassen- und Collection-Properties und DB-Controls an einer Datenquelle.
- **Galerie:** 77 Controls, mit 72 neuen Referenzbildern nur für neu aufgenommene Controls. Bei RTL und Hochkontrast ist „keine Änderung“ ein Fehler, außer bei begründeten Ausnahmen.
- **Zeichentests:** 13 mit GDI+ und GDI-Rückfall; 34 bestehende Zeichentests prüfen jetzt „nicht leer“ und „Zustand sichtbar“.
- **Verhaltenstests:** 27 für die schwach getesteten Bereiche.
- **Index:** „Control → Testunits“ (`Docs\Controls\Tests.md`, Zeile „Tests:“ auf jeder Control-Seite).

**Build und Regel-Prüfer (B):**
- **Build-Skripte:**
  - Ein Build zählt nur mit Abschlusszeile als Erfolg.
  - Unbekannte Projektnamen werden sofort abgewiesen.
  - `install.ps1`: Sicherung vor jeder Änderung, auch beim Deinstallieren. PATH wird gesichert und nur zurückgenommen, wenn `install.ps1` ihn selbst eingetragen hat (Marker). `BDSCOMMONDIR` kommt aus Registry bzw. `rsvars.bat`.
  - `install.ps1` wurde nie ausgeführt, nur per Syntaxprüfung und herausgelöste Funktionen getestet.
- **Neue Regeln:** DB, DESIGN, UNITS, IMAGEINDEX, TIMER, TEXT, REQUIRES, LAYER, XE2, EXCEPT-Grenzen.
- **Code-Anpassungen dafür:**
  - Der Markup-Parser liegt jetzt in der Core-Unit `PPG.Markup.Parser`; damit ist die Schichtverletzung in ICal aufgelöst.
  - XE2-Stellen: `FMod`, `TCollectionNotification`, `DocumentProperties`.
  - 13 Grenzen sind kommentiert.

**Demo und Doku (D):**
- **Demo:**
  - Der Katalog enthält alle 84 Controls, mit Selbsttest. Neue Karten für GroupBox, CustomHint, KanbanPrinter und vier DB-Controls.
  - Die Demo startet auf Deutsch.
  - `ForceGdiFallback` zeichnet über einen Haken selbst neu.
  - Das Preset läuft über `TPPGStyleManager`; alle nicht sichtbaren Komponenten unterstützen ihn schon.
- **Doku:**
  - `NAECHSTE-SCHRITTE.md` ist neu aufgebaut, die Historie steht in `Docs\Verlauf.md`.
  - `Docs\Architektur.md` hat den Abschnitt „Leistung“ (Messwerte Paket 8), dazu weitere Korrekturen.
  - Ebenfalls korrigiert: Coding-Rules (PPGStr, Umbenennung, Referenz nach Anwender-Ereignis, catch-all-Grenzen), Roadmap 3, Kompatibilität, DatePicker-Hilfe.

**Auswahlgruppen (R):** `ValidationHint` an RadioGroup, CheckGroup und DBRadioGroup: Tooltip, Screenreader-Beschreibung und Alarm. Die DB-RadioGroup zeigt beim Verlassen die Meldung aus `OnValidate`, und der Validator setzt seinen Regeltext auch bei Auswahlgruppen. Ist `ShowHint` beim Anwender aus, wird es bei einem Fehler nur, solange die Maus über der Gruppe steht, eingeschaltet und danach wiederhergestellt.

**Echte Fehler, gefunden durch die schärferen Tests und behoben:**
1. Kontextmenü per Shift+F10 in Feldern erschien nie (`ERangeError` bei LParam = -1).
2. Splitter: Zugriffsverletzung, wenn das Ziel beim Ziehen freigegeben wird.
3. 11 DB-Controls: Zugriff auf die schon freigegebene Bindung in `CM_EXIT` beim Zerstören.
4. Wizard deaktiviert: Schrittkreise blieben in Akzentfarbe.
5. Kanban: Tastaturfokus auf der gewählten Karte unsichtbar (jetzt Fokusring).
6. DB-RadioGroup: Fehlertext aus `OnValidate` ging verloren.

**Abweichungen:**
- `ValidationHint` steht im DFM nach `ValidationState`, wie bei den Feldern.
- `Phase3` `ChildPaintsOnPanelBackground` lief bisher nie (Skip ohne Themes). Seine Erwartung „reines Grün“ war fachlich falsch, weil das Panel einen Verlauf zeichnet. Jetzt vergleicht der Test mit dem Panel-Pixel in gleicher Höhe.
- Zwei ExtremeSizes-Tests (1×1, 8×8 px) prüfen bewusst nicht „nicht leer“.
- Weiterhin weich: `Phase7b` wartet 400 ms fest auf eine Popup-Animation; `Visual` überspringt vor Delphi 10.3 per Status (hier nicht relevant).

**Offen für den User:**
- Planer und Kanban zeigen keinen Fokus, solange nichts gewählt ist (UX-Entscheidung).
- `PPG_HAS_IMAGECOLLECTION` ist definiert, aber unbenutzt.
- Die XE2-Anpassungen sind nur unter Delphi 13 gebaut (Paket 10).
