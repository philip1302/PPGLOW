# Plan: Automatische Umstellung eines Millionenzeilen-Projekts auf PPGlow

## Context
Morgen sollen in einem großen Kundenprojekt (Delphi Professional/Enterprise, mit dcc32/MSBuild) alle sichtbaren Komponenten durch PPGlow ersetzt werden: VCL-Standard, TMS und DevExpress. Gefordert sind zwei Garantien: Das Programm **kompiliert** danach, und **wirklich alle** Komponenten sind getauscht.

Was es schon gibt: `Build\migrate.ps1` (Phase 9f) mit Selbsttest (`Build\migrate-tests`) und Leitfaden `Docs\Migration.md`. Das Skript arbeitet aber nur pro Formular (DFM + gleichnamige PAS) und kennt VCL plus einige TMS-Klassen. **DevExpress fehlt ganz**, ebenso reine Code-Units, `TButton.Create(...)`, `is`/`as`/Typecasts, eigene Unterklassen fremder Controls und Binär-DFMs.

Entscheidungen des Users:
- Das Projekt liegt erst morgen vor. Deshalb ist die Bestandsaufnahme morgen der erste Schritt.
- Der Umfang umfasst auch die VCL-Standard-Controls.
- Für Klassen ohne PPGlow-Gegenstück (cxGrid-Views, dxLayoutControl, dxBarManager, TAdvToolBar …) gilt **„erst nur melden“**: Sie bleiben vorerst stehen und landen auf einer ausdrücklichen Ausnahmeliste.

**Ehrliche Einordnung:** Die Garantie „alles getauscht“ heißt damit: Jede Fremdklasse ist entweder getauscht oder steht namentlich mit Fundstelle auf der Ausnahmeliste. Dass nichts unbemerkt durchrutscht, beweisen Prüftore (Gates). Ein Bauchgefühl reicht dafür nicht. Eine vollständige Ablösung von cxGrid und dxLayout an einem Tag ist nicht realistisch.

## Grundprinzip
1. **Alles per Skript, nichts von Hand im Zielcode.** Jeder Fehler wird als Regel im Skript behoben, danach folgt ein neuer Lauf ab einem sauberen git-Stand. So ist das Ergebnis reproduzierbar und idempotent.
2. **Die Garantie liefern Gates, nicht das Migrationsskript.** Gates sind der Compiler, ein statischer Vollständigkeitsprüfer, ein Ladetest aller Formulare und ein Build ohne Fremdbibliotheken.

## Stand 07.10.2026
Heute wird nichts umgesetzt, der Plan ist für morgen (08.10.2026). Die Werkzeuge 1–4 entstehen morgen früh **vor** dem Ablauf unten, im PPGlow-Repo. Das kostet etwa 3–4 h, danach erst geht es ans Kundenprojekt.

## Vorbereitung morgen früh (im PPGlow-Repo)

### 1. Neues Skript `Build\inventory.ps1` (nur lesend)
- Es scannt alle `.dfm` (bei Binär-DFMs mit `convert.exe -t` aus dem Delphi-`bin` in eine Kopie) und alle `.pas`/`.dpr`/`.inc`.
- Es zählt die Klassen aus `object|inherited|inline X: TKlasse`, je Klasse die genutzten Properties und Events, Frames und Formularvererbung.
- In den PAS-Dateien sucht es tokenbasiert (ohne Kommentare und Strings) nach Felddeklarationen, `var`, Parametern, `TKlasse.Create`, `is`/`as`, Typecasts `TKlasse(`, `class(TFremd)` (eigene Unterklassen) und Units aus `uses` (`Adv*`, `cx*`, `dx*`, `Vcl.StdCtrls` …).
- Ausgabe: `inventory.csv` (Klasse, Anzahl, gemappt ja/nein, nicht unterstützte Properties mit Häufigkeit) und `inventory-summary.txt`.
- Die Klassentabelle teilt es sich mit `migrate.ps1`. Dazu wird `$ClassMap` in eine gemeinsame Datei `Build\migrate-map.psd1` ausgelagert.

### 2. `Build\migrate.ps1` erweitern
- **Mapping auslagern** nach `migrate-map.psd1`: Klassen, Umbenennungen, Units, die entfernt werden, und Event-Typänderungen.
- **DevExpress (einfache Editoren)** kommt dazu, jeder Eintrag wird morgen an der Inventur bestätigt:
  - `TcxButton`→`TPPGButton`, `TcxTextEdit`/`TcxButtonEdit`→`TPPGEdit`, `TcxMemo`→`TPPGMemo`
  - `TcxCheckBox`, `TcxRadioButton`, `TcxComboBox`, `TcxSpinEdit`
  - `TcxDateEdit`→`TPPGDatePicker`, `TcxTimeEdit`→`TPPGTimePicker`, `TcxCurrencyEdit`/`TcxCalcEdit`→`TPPGNumberEdit`, `TcxMaskEdit`→`TPPGMaskEdit`
  - `TcxLabel`, `TcxGroupBox`, `TcxPageControl`/`TcxTabSheet`, `TcxTreeView`, `TcxListBox`, `TcxCheckListBox`
  - `TcxProgressBar`, `TcxTrackBar`, `TcxSplitter`, `TcxColorComboBox`→`TPPGColorPicker`, `TcxCheckComboBox`
  - `TcxDB*`-Varianten → `PPG.DB.Controls`/`PPG.DB.Fields`/`PPG.DB.Lookup`
- **Weitere TMS-Klassen** nach Inventur, z. B. `TAdvMaskEdit`, `TAdvMoneyEdit`→`TPPGNumberEdit`, `TAdvPanel`, `TAdvGroupBox`, `TAdvSpinEdit`, `TAdvDateTimePicker`, `TAdvProgressBar`, `TAdvSearchEdit`.
- **DevExpress-Regel `Properties.*`:** `Properties.ReadOnly`, `Properties.MaxLength`, `Properties.Items.Strings` usw. verlieren das Präfix, wenn es die Property bei der PPGlow-Klasse gibt. Sonst werden sie entfernt und gemeldet. `Properties.OnChange`→`OnChange`. `Style.*`/`StyleFocused.*`/`LookAndFeel.*` werden entfernt (die Optik kommt aus dem Preset). Bei `EditValue` hängt das Ziel von der Klasse ab (`Text`/`Value`/`Date`/`Checked`).
- **PAS ohne DFM:** Alle Units werden bearbeitet, nicht nur Formular-Units. Ersetzt werden `TAlt` → `TNeu` als ganzes Token in Deklarationen, `.Create`, `is`, `as` und Casts, und die nötigen PPG-Units werden ergänzt.
- **Units aufräumen:** TMS- und DevExpress-Units verschwinden aus `uses`, wenn die Unit danach keine Klasse daraus mehr nennt. Sonst bleiben sie stehen und werden gemeldet.
- **Ausnahmeliste** `migrate-exclude.txt`: Klassen ohne Gegenstück bleiben unangetastet. Jede Fundstelle (Datei:Zeile) kommt in den Bericht.
- **`class(TFremd)` im Kundencode** (eigene Unterklassen fremder Controls) wird nicht automatisch umgehängt, sondern gemeldet. Sonst folgen Folgefehler in überschriebenen Methoden.
- **Event-Signaturen:** Der Compiler prüft DFM-Handler **nicht**. Deshalb gibt es eine Tabelle „Event bei alter Klasse → Ereignistyp bei neuer Klasse“. Wo die Signatur abweicht, wird der Handler angepasst oder gemeldet (Muster wie bei `TColumn`→`TPPGDBGridColumn`).
- **Selbsttest erweitern:** Neue Fixtures in `Build\migrate-tests` für DevExpress-, TMS-, Frame-, `inherited`- und Code-Only-Units. Morgen kommen anonymisierte echte DFM-Ausschnitte dazu.

### 3. Neues Skript `Build\verify-migration.ps1` (Gates G2 und G5)
- **G2 Vollständigkeit:** Jedes DFM-Objekt ist entweder eine PPG-Klasse, steht auf der Allowlist nicht sichtbarer Klassen (`TDataSource`, `TImageList`, `TActionList`, `TTimer`, Queries …) oder steht auf `migrate-exclude.txt`. Jede Klasse aus der Quellspalte der Map, die irgendwo in PAS-Token oder DFM vorkommt, lässt das Gate scheitern. Exit-Code = Anzahl der Funde.
- **G5 Verhaltensrisiken (Warnliste, kein Abbruch):**
  - Code, der `.Checked`/`.State` setzt, auf Controls mit `OnClick`-Handler (PPGlow löst dann nur `OnChange` aus)
  - `TDateTimePicker` mit `Kind = dtkTime`
  - verlorene TreeView-Knoten und Glyphen
  - `ItemHeight`
- Dieselbe Tokenizer-Logik wie in `inventory.ps1` (gemeinsame Funktionen in `Build\migrate-common.ps1`).

### 4. Formular-Ladetest (Gate G4): Vorlage `Build\FormLoadCheck\`
- Ein Generator liest die `.dpr` des Kunden und erzeugt ein Testprogramm. Es erzeugt jedes Formular und jeden Frame per `TFormX.Create(nil)` in einem Prüfmodus und fängt `EReadError`/`EClassNotFound` ab.
- Danach durchläuft es rekursiv alle `Components` und meldet jede Instanz, deren `ClassName` in der Quellspalte der Map steht. Damit werden auch zur Laufzeit erzeugte Controls aus `OnCreate` erfasst.
- Seiteneffekte (DB-Verbindungen in `OnCreate`) klären wir morgen. Falls nötig, gibt es einen Schalter im Kundenprojekt oder einen reinen Streaming-Test über `TReader` mit `OnError`.

## Ablauf morgen
1. **Ausgangslage (≈30 min):** Einen git-Zweig anlegen, den Baseline-Build per MSBuild/dcc32 ausführen und Fehler- und Warnungszahl festhalten. Die Delphi-Version des Kunden klären. **PPGlow ist bisher nur mit Delphi 13 kompiliert.** Bei einer anderen Version werden zuerst die PPGlow-Packages dafür gebaut und `PPGlowTests.exe` laufen gelassen.
2. **Inventur (≈1 h):** `inventory.ps1` auf das Projekt anwenden, Binär-DFMs als Text speichern (eigener Commit) und die Map sowie `migrate-exclude.txt` anhand der echten Zahlen festlegen.
3. **Pilot (≈1–2 h):** 5–10 typische Formulare migrieren (VCL, TMS, DevExpress, Frame, vererbtes Formular), kompilieren und Fehler **als Regeln** ins Skript einbauen. Echte Ausschnitte kommen in die Fixtures, dann `-SelfTest` laufen lassen.
4. **Gesamtlauf in einer Schleife:**
   `git reset --hard <baseline>` → `migrate.ps1 -Recurse` → MSBuild.
   Die Fehler werden nach Art gruppiert, als Regel behoben, und der Lauf beginnt von vorn, bis G1 grün ist.
   Nur was sich nicht als Regel fassen lässt, kommt als eigener Commit „manuelle Nacharbeit“ hinzu und wird nach jedem Lauf wieder angewendet (Patch-Datei).
5. **Gates:**
   - **G1** Vollständiger Build: 0 Fehler, Warnungen nicht mehr als in der Baseline.
   - **G2** `verify-migration.ps1`: 0 Funde außerhalb der Ausnahmeliste.
   - **G3** Build **ohne** TMS- und DevExpress-Pfade bzw. -Packages für jede Familie, die nicht mehr auf der Ausnahmeliste steht. Das ist der härteste Beweis, dass dort nichts mehr referenziert wird.
   - **G4** FormLoadCheck: Alle Formulare laden, keine alte Klasse zur Laufzeit.
   - **G5** Die Warnliste wird durchgesehen.
6. **Smoke-Test** der Anwendung mit den Hauptformularen, dann Bericht, Ausnahmeliste und Nacharbeitsliste an den User.

## Dateien
- Ändern: `Build\migrate.ps1`, `Build\migrate-tests\*`, `Docs\Migration.md`
- Neu: `Build\migrate-map.psd1`, `Build\migrate-common.ps1`, `Build\inventory.ps1`, `Build\verify-migration.ps1`, `Build\FormLoadCheck\` (Generator und Vorlage), `Build\migrate-exclude.txt` (Vorlage)
- Wiederverwenden: `Read-PPGlowClasses`/`Get-AllowedProps` (liest erlaubte Properties aus den PPGlow-Quellen), `Get-ValueEnd` (mehrzeilige DFM-Werte), das Selbsttest-Muster aus `migrate.ps1`

## Ältere Delphi-Versionen zum Testen
- Die Community Edition gibt es nur für die aktuelle Version. Ältere Versionen brauchen eine Pro/Enterprise-Lizenz mit Update-Subscription. Damit lassen sie sich über my.embarcadero.com laden („Previous versions“).
- Mehrere Delphi-Versionen laufen nebeneinander (eigener `Studio\xx.0`-Ordner und Registry-Zweig). Für alte Versionen wie XE2 bis 10.x empfiehlt sich eine **VM**, weil Installer und Hilfe unter Windows 11 zicken.
- Priorität: genau die Version des Kundenprojekts installieren, PPGlow dort bauen und `PPGlowTests.exe` laufen lassen (Prüfplan `Docs\Kompatibilitaet.md`). Das kann auch morgen auf dem Rechner mit der Kundenlizenz passieren.

## Verifikation der Werkzeuge (morgen früh, vor dem Kundenprojekt)
- `migrate.ps1 -SelfTest` mit neuen Fixtures für DevExpress, TMS, Frame, inherited und Code-Only: alles „ok“.
- `verify-migration.ps1` gegen die migrierten Fixtures meldet 0 Funde, gegen die unmigrierten Originale die erwartete Zahl.
- `inventory.ps1` auf `Demo\` und die Fixtures: plausible CSV.
- Die migrierten Fixtures in ein kleines Testprojekt einbinden und per `build.ps1` kompilieren. Der Formular-Ladetest läuft darauf grün.
- Prüfskript `check-rules.ps1` laufen lassen, danach Commit auf dem Zweig `claude/task-elizkl`.

## Risiken
- Die Delphi-Version des Kunden ist ungleich 13: PPGlow ist dort ungetestet (XE2 nie kompiliert). Das ist der größte Unsicherheitsfaktor für morgen.
- **Kompiliert heißt nicht, dass es läuft:** DFM-Properties und Event-Signaturen prüft der Compiler nicht. Deshalb gibt es G4 und die Signatur-Tabelle.
- Verhaltensunterschiede (`OnClick` bei `Checked`, `ItemHeight`, Grid-Zeilenbegriffe) erzeugen keine Compilerfehler, sondern stehen auf der G5-Warnliste.
- cxGrid, dxLayout, dxBar und TAdvStringGrid mit Profi-Features bleiben laut Entscheidung auf der Ausnahmeliste. Der Tausch ist erst vollständig, wenn diese Liste leer ist.
