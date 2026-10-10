Du baust in der Delphi-VCL-Komponentensuite PPGlow die Demo-Komponentenseite für **{CLS}** (Gruppe „{GROUP}“). Arbeite selbstständig bis zum Ende und liefere am Schluss einen Bericht (Format unten).

## Hintergrund
Der User will PPGlow seinem Arbeitgeber vorführen. Die Demo ist dafür ein Nachschlagewerk: für jede Komponente eine eigene Seite. Seine Worte: „Dann sehe ich die Komponenten plus den Objektinspektor und kann alle Properties verändern und sehe, wie sich das Control verändert … Dann gibt es noch zwei Praxisbeispiele, bei denen gezeigt wird, wie man das Control in der Praxis einsetzt, und ich kann mir dazu den Code anzeigen lassen … Dafür sollten die Beispiele einfach gehalten werden … Es muss jede Property und Eigenschaft erklärt werden mit Anwendungsbeispiel und Bedienungsanleitung in der Praxis.“
Die erste Seite (TPPGButton) ist fertig und ist die **Vorlage**. Das Gerüst (Inspektor, Code-Erzeugung, Erklärung, Selbsttests) ist allgemein und funktioniert für jede Komponente. Du schreibst nur die komponentenspezifischen Teile. Parallel bauen 20 weitere Agenten die Seiten anderer Komponenten, jeder in einem eigenen Worktree.

## Dein Arbeitsplatz
- Worktree: `{WT}` (Zweig `sc/{SHORT}`). Arbeite **nur dort**: absolute Pfade, nie im Hauptbaum `C:\AI\Claude_Arbeitsplatz\PPGlow` und nie in anderen Worktrees.
- Zuerst lesen:
  - `{WT}\Docs\Demo-Komponentenseiten.md` (Konzept und Ablauf).
  - `{WT}\Demo\Showcase\DemoShowButton.pas`, `ExButtonDialog.pas` und `ExButtonToolbar.pas` (Vorlage).
  - Das Gerüst: `{WT}\Demo\Showcase\DemoShowcase.pas`, und zwar die Klasse `TDemoComponentPage`, ihre virtuellen Methoden und den Selbsttest.
  - `{WT}\Docs\Controls\{CLS}.md` (alle Eigenschaften und Ereignisse mit Typ und Wirkung) und `{WT}\Docs\Controls\notes\{CLS}.md`.
  - Den Quelltext der Komponente unter `{WT}\Source`.
  - `{WT}\Docs\Controls\props\90-praxis.txt` (Format der Praxis-Texte).
  - `{WT}\Docs\Coding-Rules.md`.

## Aufgaben
1. **Texte** in der neuen Datei `{WT}\Docs\Controls\props\95-praxis-{CLS}.txt` (UTF-8, Format wie `90-praxis.txt`):
   - Für **jede** Eigenschaft und jedes Ereignis, das der Inspektor für {CLS} zeigt, einen Praxis-Text als `{CLS}.Name ! Text`: wann und wie man es im Alltag einsetzt, konkret, ein bis zwei Sätze, auf diese Komponente bezogen. Gemeint sind die eigenen, die geerbten PPGlow- und die VCL-Eigenschaften, z. B. `{CLS}.Hint ! …`, `{CLS}.Height ! …`, `{CLS}.OnChange ! …`.
   - Unterobjekte, Collection-Einträge und VCL-Unterobjekte (z. B. `TPPGElementStyle`, Items einer Collection) brauchen ebenfalls Praxis-Texte. Prüfe vorher mit grep über `props\*.txt`, ob es den Schlüssel `Typ.Name` schon gibt. Wenn nicht, schreibe einen allgemeinen Text (er gilt für alle Controls) in einen eigenen Abschnitt `# --- Typen ---` am Ende deiner Datei und liste diese Schlüssel im Bericht auf.
   - Fehlt einer Eigenschaft die Wirkung, ergänze sie ebenfalls in **deiner** Datei als `Klasse.Name = Wirkung`. Keine anderen props-Dateien ändern.
   - Kontrolle: `powershell -ExecutionPolicy Bypass -File {WT}\Build\make-docs.ps1 -Missing {WT}\fehlt.txt`. Sobald deine Seite angemeldet ist, muss die Liste für {CLS} und seine Typen leer sein. Lücken anderer Komponenten ignorieren. `fehlt.txt` und die neu erzeugten `Docs\Controls\*.md/html` **nicht** committen.
2. **Notiz** `{WT}\Docs\Controls\notes\{CLS}.md`:
   - Nach der Zeile „Vorbild“ die Abschnitte `## Wofür` (2–3 Sätze) und `## Wann verwenden` (Liste mit Abgrenzung zu ähnlichen Controls) einfügen, wie in `notes\TPPGButton.md`. Den Rest behalten, Fehler darin korrigieren.
   - Die Datei hat CRLF; beim Schreiben erhalten.
3. **Zwei Praxisbeispiele** als eigene Units `{WT}\Demo\Showcase\Ex{SHORT}<Thema>.pas`:
   - Inhalt: einfache, realistische Alltagsszenarien aus Business-Software (Formular, Dialog, Einstellungen, Liste …), die die wichtigsten Eigenschaften und Ereignisse von {CLS} zeigen.
   - Aufbau: eine kleine Klasse (TComponent mit Konstruktor, der in einen Parent baut, oder TForm wie beim Dialog), Eigenschaften für den Selbsttest. Der gezeigte Code steht zwischen `// EXAMPLE-BEGIN` und `// EXAMPLE-END`; mehrere Abschnitte sind erlaubt, z. B. ab `uses` im interface und die Implementierung.
   - **Keine Demo-Units** (kein DemoKit) in den Beispielen. Den StyleManager als Parameter übergeben und an die PPGlow-Controls hängen, wie in ExButtonToolbar.
   - **Platz:** Die Live-Fläche ist bei eingeblendetem Code nur etwa 450 px breit. Die Beispiele also kompakt anordnen (Breite ≤ 430 px ab x = 16).
4. **Seite** `{WT}\Demo\Showcase\DemoShow{SHORT}.pas`:
   - `TDemoShow{SHORT}Page = class(TDemoComponentPage)` mit `SubjectClass` und `BuildExamples` (`AddExample(Titel, UnitName, Beschreibung)`; die Beschreibung sagt, was man ausprobieren soll).
   - Bei Bedarf `SetupSubject`: der Komponente auf der Bühne sinnvollen Inhalt geben (z. B. Einträge, Text), damit man sofort etwas sieht; `inherited` aufrufen.
   - Bei Bedarf `CategoryFor` (eigene Eigenschaften sinnvollen Kategorien aus `DemoInspector.DemoCategories` zuordnen) und `EventOccurred` (Zusatzinfo im Protokoll).
   - Ereignisse mit eigener Signatur werden nicht automatisch protokolliert. Solche Handler in `SetupSubject` selbst zuweisen und darin `LogEvent(Name, Detail)` aufrufen.
   - `SkipInRoundTrip` nur mit fachlicher Begründung, die im Bericht steht (z. B. ItemIndex ohne Einträge, Werte, die von anderen abhängen).
   - `SelfTest`: `inherited SelfTest(Check)` aufrufen, danach die Szenarien beider Beispiele prüfen (wie DemoShowButton: Klicks per `.Click` bzw. Methoden, Ergebnis prüfen). Mindestens drei sinnvolle Prüfungen je Beispiel.
   - `initialization RegisterShowcasePage('{CLS}', TDemoShow{SHORT}Page);`
   - Texte in der Seite: Umlaute über `L('{ae}')` aus DemoKit (siehe DemoKit-Kopf), die Quelltexte bleiben reines ASCII.
5. **Projekt eintragen, nur lokal, nicht committen**: in `{WT}\Demo\PPGlowDemo.dpr` (vor `DemoMain in`) und `{WT}\Demo\PPGlowDemo.dproj` (`DCCReference` wie die anderen Showcase-Units). Die Integration macht später der Hauptagent.
6. **Bauen und prüfen**, immer über die Sperr-Skripte (Builds und Demo-Läufe der parallelen Agenten laufen damit nacheinander; Wartezeit ist normal):
   - Bauen: `powershell -ExecutionPolicy Bypass -File {TOOLS}\build-lock.ps1 -Root {WT}`. Der Build erzeugt auch `Demo\Showcase\ShowcaseData.res` neu (nicht committen). Kontrolliere das Ergebnis in der Ausgabe („Demo : OK“). Hinweise (Hxxxx) und Warnungen aus deinen Units beseitigen.
   - Selbsttest nur deiner Seite: `powershell -ExecutionPolicy Bypass -File {TOOLS}\run-lock.ps1 -Exe {WT}\Demo\PPGlowDemo.exe -Arguments '/selftest','{WT}\selftest.txt','/only','{CLS}','/hidden'`. Danach die Datei lesen. Ziel: 0 Fehler, darunter „… mit Wirkung“, „… mit Praxis-Text“, „… Zeilen gesetzt und zurückgesetzt“, Code, DFM und deine Beispielprüfungen.
   - Screenshots: `... run-lock.ps1 -Exe {WT}\Demo\PPGlowDemo.exe -Arguments '/show','{CLS}','/screenshot','{WT}\s1.png','/hidden'`, dazu `/tab 1 /showcode` und `/tab 2 /showcode` sowie `/select <Pfad> /bottomtab 1`. Die PNGs mit dem Read-Tool **ansehen** und Darstellungsfehler (abgeschnitten, überlappend, leer) beheben. Screenshots und selftest.txt nicht committen.
7. **Committen** auf deinem Zweig, nur mit ausdrücklich genannten Dateien (`git -C {WT} add <dateien>`, nie `-A`, nie `.`):
   - Committet werden `Demo\Showcase\DemoShow{SHORT}.pas`, deine `Demo\Showcase\Ex{SHORT}*.pas`, `Docs\Controls\props\95-praxis-{CLS}.txt` und `Docs\Controls\notes\{CLS}.md`.
   - **Nicht** committet werden dpr, dproj, .res, .dcu, .exe und die erzeugte Doku.
   - Die Commit-Nachricht endet mit diesen zwei Zeilen:
     ```
     Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
     Claude-Session: https://claude.ai/code/session_017dErpxxinRXmCX5bZ2rCTT
     ```
   - Nicht pushen, nicht mergen.

## Grenzen (wichtig)
- **Nicht ändern:** `Demo\Showcase\DemoShowcase.pas`, `DemoInspector.pas`, `DemoCodeGen.pas`, `DemoDocs.pas`, `Demo\DemoKit.pas`, `Demo\DemoMain.pas`, alles unter `Source\`, `Build\`, `Tests\` und fremde props-Dateien. Andere Agenten arbeiten parallel, und Änderungen dort erzeugen Konflikte.
- Findest du einen **Fehler im Gerüst** oder in der **Komponente selbst** (Source), beschreibe ihn genau im Bericht: Datei, Stelle, Ablauf, Vorschlag. Umgehe ihn wenn möglich in deiner Seite. Nicht selbst beheben.
- Rote Prüfungen nie passend machen: entweder deine Seite korrigieren oder (fachlich begründet) `SkipInRoundTrip`.
- Code-Regeln: XE2-tauglich (keine Inline-Variablen, kein `for var`, `{$IF}` mit `{$IFEND}`), voll qualifizierte Units (`System.Classes`, `Vcl.Controls`), Quelltexte reines ASCII mit CRLF. Das Write-Tool schreibt LF, danach umstellen mit Bash: `perl -pi -e 's/\r?\n/\r\n/' <datei>`.
- **Shell-Fallen:**
  - Programme mit `/`-Schaltern nur über PowerShell starten, nie über Git-Bash (die wandelt `/x` in Pfade um).
  - Perl-Einzeiler mit Backslashes nur über das Bash-Tool, nie über PowerShell. In Perl-Ersetzungen Backslashes als `\x5C` schreiben.
  - Für Mehrzeiliges lieber das Edit-Tool nehmen.
- Demo und Tests **immer mit `/hidden`**. Nie etwas installieren, keine IDE und keine fremden Prozesse beenden. Ist eine `PPGlowDemo.exe` in deinem Worktree gesperrt, benenne sie um (`PPGlowDemo.locked-1.exe`) statt den Prozess zu beenden.
- Sprache in Texten, Kommentaren und Bericht: Deutsch, klar und knapp.

## Bericht (deine letzte Antwort)
- Ergebnis: Commit-Hash, committete Dateien, Selbsttest-Zeile „N Pruefungen, M Fehler“ und die Zeilen zu Wirkung, Praxis und Rundlauf.
- Die beiden Beispiele in je einem Satz.
- Zeilen für dpr und dproj, die die Integration eintragen muss.
- Neue Schlüssel unter `# --- Typen ---` (gemeinsame Typen).
- `SkipInRoundTrip`-Ausnahmen mit Begründung.
- Gefundene Fehler im Gerüst oder in der Komponente (genau, mit Vorschlag).
- Was offen ist oder nicht geprüft wurde.
