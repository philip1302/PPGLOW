# PPGlow – Coding-Regeln

Diese Regeln sind verbindlich für jede neue Unit und jedes neue Control. Sie sichern die Kompatibilität von **Delphi XE2 bis Delphi 13** und das Enterprise-Niveau.

## Kompatibilität (XE2+)
- Jede Unit beginnt mit `{$I ..\PPG.inc}` direkt nach `unit …;`.
- `{$IF …}` wird **immer** mit `{$IFEND}` geschlossen. Versionsabfragen laufen nur über die `PPG_HAS_*`-Defines in `PPG.inc`.
- **Verboten:** Inline-Variablen und `for var` (erst ab 10.3), Managed Records (ab 10.4), `[weak]`/`[unsafe]`, Ternary-`if`-Ausdrücke, Multiline-Strings, `TArray<T>`-Helper neuerer RTLs, `NameOf`.
- Unit-Namen werden immer voll qualifiziert (`Vcl.Controls`, `System.Classes`).
- Generics nur einfach einsetzen (`TList<T>`), keine verschachtelten Constraints.
- `TImageIndex` nicht direkt verwenden, stattdessen `TPPGImageIndex`.
- Quelltexte enthalten nur ASCII (keine Umlaute, auch nicht in Kommentaren) und CRLF-Zeilenenden.
- Kommentare `{ … }` dürfen keine `}` enthalten, also auch keine Direktiven wie `{$IF}` im Kommentartext. Für solche Fälle `//` verwenden.

## Texte und Übersetzung
- Jeder sichtbare Text, also Meldung, Hinweis, Screenreader-Name oder Prozentformat, steht als `resourcestring` in `PPG.Consts`.
- Gelesen wird er **immer** über `PPGStr(@SPPGxxx)`, nie direkt als `SPPGxxx`; sonst greift die Übersetzung nicht. Für Exceptions gilt deshalb `CreateFmt(PPGStr(@SPPGxxx), […])` bzw. `Create(PPGStr(@SPPGxxx))`.
- Ausgenommen sind die Design-Units (`Source\Design`, `Source\DesignDB`, `Source\Editors`); die IDE bleibt englisch.
- Jeder neue Text bekommt eine Zeile in `Lang\PPGlow.de.txt`, danach `Build\make-lang.ps1` ausführen. Der Regel-Prüfer (Regel LANG) meldet fehlende oder veraltete Einträge.

## Prüfung ohne Compiler
- `Build\check-rules.ps1` prüft vor jedem Build: ASCII, CRLF, `{$I ..\PPG.inc}`, `{$IFEND}`, Inline-Variablen und `NameOf`, Syntaxreste, `}` in Kommentaren, `raise` nur mit `PPG.Exceptions` (in `Source`), keine leeren `except`, jede Unit in allen Projektlisten und vollständige Übersetzungen. Dazu kommen (Audit 11d):
  - **EXCEPT**: Ein `except` ohne `on`-Filter (oder mit `on E: Exception`) und ohne `raise`/`Abort` steht in `Source` nur an einer Grenze. Die Grenze trägt einen Kommentar mit „Grenze: <warum>“ (bis sechs Zeilen davor oder im Handler). Ausgenommen sind `Source\Access`, `PPG.ErrorHandler` und `PPG.Animation`.
  - **DB**: `Data.*`, `Datasnap.*`, `Vcl.DB*` und `MidasLib` stehen in `Source` nur in `Source\DB` und `Source\DesignDB`.
  - **DESIGN**: `DesignIntf`, `DesignEditors`, `VCLEditors`, `ToolsAPI`, `ColnEdit` und andere IDE-Units stehen nur in `Source\Design` und `Source\DesignDB`.
  - **UNITS**: keine unqualifizierten RTL/VCL-Units in `uses` (`Windows`, `SysUtils`, `Classes`, `Controls` …), geprüft in Source, Tests und Demo.
  - **IMAGEINDEX**: `TImageIndex` nur in `PPG.Types`.
  - **TIMER**: `TTimer`/`SetTimer`/`KillTimer` in `Source` nur in `PPG.Animation`.
  - **LAYER**: Die Schichten in `Source` (Ordner = Schicht) bilden eine Matrix. Core nutzt nur Core. Render nutzt Core und Render. Theme nutzt Core, Render und Theme. Access nutzt Core, Render, Theme und Access. Controls nutzt alles außer DB, Editors und Design. DB nutzt zusätzlich DB, Editors zusätzlich Editors. Design und DesignDB nutzen alles. Rein textuelle Hilfen gehören deshalb nach Core (Beispiel: der Markup-Parser `PPG.Markup.Parser`).
  - **TEXT** (eng): kein `Caption`/`Hint`/`Text := '…'` mit mindestens zwei Buchstaben in `Source`; ausgenommen sind Design, DesignDB und Editors.
  - **XE2** (Verbotsliste): kein `FMod`; kein unqualifiziertes `TCollectionNotification`/`cnAdded`/`cnExtracting`/… nach `System.Generics.Collections` (stattdessen `System.Classes.` voranstellen); kein `DocumentProperties(…)` mit `nil` (stattdessen eigener Import mit `PDeviceMode`).
  - **REQUIRES**: Die `requires`-Liste jedes Pakets ist in `Packages\XE2` und `Packages\Delphi13` gleich.
  - **TESTS** (Audit 11a #8, `Tests\*.pas`): kein `CheckTrue(True`/`Check(True`/`CheckFalse(False`; kein `Check…`/`Fail` in einem `try`, dessen `except` alles fängt (ohne `on`, `on Exception`, `on EAbort`, `on ETestFailure`, `else`) und weder `raise` noch eine Klassenprüfung (`is`, `CheckIs`) enthält; ein `Exit` in einer published Testmethode vor der ersten Prüfung steht nur direkt nach `Skip(…)`/`PPGSkip(…)` (Abschnitt Testintegrität).
- Ein Verstoß bricht `build.ps1` ab. `-NoRuleCheck` gibt es nur für Notfälle.
- Neue Regeln bekommen ein Negativbeispiel in `Build\check-rules-tests` (`check-rules.ps1 -SelfTest`). Zeile 1 nennt die erwarteten Regeln (`// expect:`). Optional folgen die Lage im Projekt (`// path: Source\Core\X.pas`) und die Zahl der Meldungen (`// count:`). Regeln über mehrere Dateien (PROJECT, REQUIRES, LANG) prüft je ein kleines Projekt in einem Unterordner mit `expect.txt`.
- DB-Units (`Data.DB`) gehören nur nach `Source\DB` und damit in `PPGlowDBR`. Das Grundpaket `PPGlowR` linkt kein `Data.DB`.

## Exceptions
- Nur Klassen aus `PPG.Exceptions` werfen. Die Meldung kommt aus einem `resourcestring`. Zur Laufzeit wird sie über `PPGStr` gelesen (`Create(PPGStr(@SPPGxxx))`, `CreateFmt(PPGStr(@SPPGxxx), […])`), damit die Übersetzung greift. `CreateRes`/`CreateResFmt` gibt es nur in den Design-Units (`Source\Design`, `Source\DesignDB`, `Source\Editors`), deren Texte englisch bleiben.
- **Erst validieren, dann zuweisen.** Zahlenwerte werden über `PPGCheckRange` geprüft. Das wirft zur Laufzeit und klemmt beim DFM-Laden.
- **Kein** leeres `except end`. Ein `except` ohne Klassenfilter (bzw. `on E: Exception` ohne `raise`) gibt es nur an den dokumentierten Grenzen. Jede solche Stelle trägt einen Kommentar, der mit `Grenze:` beginnt und sagt, warum hier nicht weitergeworfen wird. Die Grenzen:
  - **Paint:** wirft nie (sonst `WM_PAINT`-Endlosschleife); einmal je Control melden, dann den Notfall-Zustand zeichnen.
  - **Timer/Animation:** die betroffene Animation stoppt, die Meldung geht an `Application.HandleException`.
  - **COM/IAccessible und UIA:** Aufrufe aus fremden Prozessen; protokollieren und einen Fehlercode (`E_FAIL`) zurückgeben, nie eine Delphi-Exception über die COM-Grenze.
  - **Fehler-Handler selbst** (`PPG.ErrorHandler`): ein Fehler beim Melden geht nur noch an `OutputDebugString`.
  - **Hilfsfenster von Theme** (`WM_SETTINGCHANGE` in `PPG.Theme`): `Exception` an `Application.HandleException`, das Fenster bleibt funktionsfähig.
  - **Callback-Grenzen:** Schleifen, die viele Empfänger benachrichtigen (StyleManager-Clients, Theme-Wechsel, AppHooks-Beobachter, Validator), sichern jeden Empfänger einzeln ab und melden über `TPPGErrorHandler.HandleCallbackError`, damit ein fehlerhafter Empfänger die übrigen nicht abschneidet.
  - **WndProc** eigener Hilfsfenster (`AllocateHWnd`): Exception an `Application.HandleException`, nie aus der Fensterprozedur heraus.
  - **Thread-Grenze:** Eine Exception im Hintergrund-Thread wird gefangen (`AcquireExceptionObject`) und im Hauptthread erneut ausgelöst (z. B. `TPPGBusyOverlay.Run`).
  - **IDE-Grenze** in den Design-Units: Editoren und Verben dürfen die IDE nicht mit einer Exception aus einem Callback abschießen; Meldung an den Anwender bzw. das IDE-Log.
- Neue Controls melden sich nicht selbst beim Theme an; das erledigt `TPPGCustomControl`. Farben, die nicht in der Appearance stehen, kommen aus `Tokens` (im Dark Mode dunkel), nie direkt aus `clWindow`/`clBtnFace`, außer im Hochkontrast-Zweig.
- Code, der von außen über COM oder Fensternachrichten angestoßen wird (z. B. `accDoDefaultAction`), führt keinen Anwender-Code direkt aus, sondern postet eine Nachricht.
- Windows-API-Fehler werden über `PPGRaiseLastOSError('ApiName')` gemeldet, nicht über `RaiseLastOSError`.
- Interne Zustände werden **vor** dem Aufruf von Anwender-Events gesetzt bzw. zurückgesetzt.
- **Referenz nach Anwender-Ereignis prüfen:** Ein Handler darf das eigene Element löschen, die Liste umbauen oder das Control freigeben (`OnClose` ruft `Page.Free`, `OnClick` baut das Menü um, `OnItemClick` löscht das Item). Nach jedem Anwender-Ereignis werden Index und Objekt deshalb neu geprüft, bevor der Code weiterarbeitet: Index noch `< Count` und dasselbe Objekt an der Stelle (`(Index < Count) and (Items[Index] = It)`), Mitgliedschaft in der Collection (`IndexOf(P) >= 0`), bei möglicher Freigabe des Controls ein Destroy-Flag bzw. lokaler Zeiger. Accessibility-Aktionen posten die Identität des Elements, nicht nur einen Index. Gecachte Zeiger (`FDownIndex`, `FHotPart`, `FCacheNode`) werden vor dem Callback zurückgesetzt. Jede solche Stelle bekommt einen Test „Handler löscht das eigene Element“ (Muster: `Docs\Audit-Plan.md`, Paket 1c).
- Destruktoren sind nil-sicher (sie laufen auch nach einer Exception im Konstruktor) und werfen nie.
- `Assert` prüft nur interne Invarianten, nie Benutzereingaben.

## Ressourcen
- Jede GDI-/GDI+-Ressource bekommt ihr **eigenes** `try/finally`. Dazu gehören auch `SaveDC`/`RestoreDC`.
- Keine dauerhaften GDI-Handles pro Control. Es gibt genau zwei Ausnahmen: der Rückpuffer der Basis für den Fenster-DC (Audit 8a #1: ein Bitmap je sichtbarem Control, neu nur bei Größen- oder Farbtiefenwechsel, freigegeben bei `DestroyWnd`, Unsichtbarkeit und Destroy) und die Grid-Schriften (unten). Alles andere (Puffer für fremde DCs, Ebenen, übrige Schriften) wird pro Paint angelegt; globale Caches (ein Mess-DC, Pixel-Caches) gibt es nur einmal je Anwendung.
- Neu zeichnen gezielt: `InvalidateArea(R)` statt `Invalidate`, wenn sich nur ein Bereich ändert; in `PaintViewport` Teile außerhalb von `NeedsPaint`/`ViewportClip` überspringen (Rand für Glow, Fokus, Schatten mitrechnen).
- Timer laufen nur über den gemeinsamen Animator.
- Ausnahme Grid-Schriften (Audit 8c #10): Der Font-Cache des Grids (`TPPGFontCache`) behält seine Schrift-Handles über Zeichenvorgänge; er wird bei Änderung von Schrift, Element-Stil, Spalten, DPI oder Theme geleert und hält höchstens 64 Schriften.

## Paint
- `Paint` zeichnet nur: kein `Invalidate`, keine Zustandsänderung und **keine Fensternachrichten** (auch kein `SendMessage` an sich selbst).
- Was Paint braucht, wird außerhalb zwischengespeichert (Beispiel: `FUIState`).

## Lebenszyklus und Streaming
- Referenzen auf Komponenten werden mit `FreeNotification` gehalten und in `Notification(opRemove)` auf `nil` gesetzt. Den Partner beim Zerstören **nicht** vorzeitig abmelden.
- Setter von Sub-Objekten rufen `Assign` auf. Jede `TPersistent`-Klasse implementiert `Assign`, `GetOwner` und bei Bedarf `Equals`.
- Default-Werte nach einem Release nie ändern. **Umbenennen ohne Aliase, bis die Suite in einem echten Projekt läuft** (die Installationen in der eigenen IDE zählen nicht); `migrate.ps1` und die Doku ziehen mit. Danach bleiben umbenannte Properties per `DefineProperties` lesbar.
- Published-Reihenfolge ist Streaming-Reihenfolge. Abhängige Properties stehen deshalb hinter ihren Voraussetzungen.
- In Settern `csLoading` beachten. Die Initialisierung gehört in `Loaded`.

## Threads
- Die VCL darf nur im Main-Thread verwendet werden. `Invalidate` prüft das im Debug-Build per `Assert`.

## Tests
- Jede neue Property bekommt einen Test für den gültigen Wert, den ungültigen Wert (Exception, Objekt unverändert) und das Streaming.
- Jedes neue Control bekommt Lebenszyklus-, Paint- (GDI+ **und** GDI-Fallback), Verhaltens- und Ressourcentests.
- Ein gefundener Bug bekommt zuerst einen Regressionstest, danach wird er behoben.

### Testintegrität
Leitlinie des Users (verbindlich): „Stelle sicher …, dass sie wirklich testen und in Zukunft Tests nicht verändert werden nur um ihn zu bestehen, sondern nur wenn er fachlich technisch nicht korrekt funktioniert.“
- **Ein roter Test wird nie passend gemacht.** Erst wird geklärt, ob der Code falsch ist (dann wird der Code korrigiert) oder ob der Test fachlich bzw. technisch falsch prüft. Nur im zweiten Fall wird der Test geändert.
- **Begründungspflicht:** Jede Änderung an einer bestehenden Prüfung steht im Commit als eigene Zeile `Test geändert: <fachlicher Grund>` und im Bericht. Zeigt ein schärferer Test einen echten Fehler, wird der Fehler behoben (größere kommen auf eine Liste für den User); der Test wird nicht entschärft.
- **Referenzdaten aus dem alten Code:** Referenzwerte, Digests und Referenzbilder werden mit dem Code **vor** der Änderung erzeugt (temporärer Worktree auf dem alten Commit, nicht `git stash`) und eingecheckt. Nie werden sie aus dem Code abgelesen, der gerade geprüft wird. Herkunft (Commit, Datum, Vorgehen) steht im Test-Kommentar.
- **Fehlendes Referenzbild = Fehlschlag.** Angelegt wird nur mit dem Runner-Schalter `/baseline` (`PPGTestBaseline`); vorhandene Bilder werden nie überschrieben.
- **Keine Zeit-Asserts in Unit-Tests** (`GetTickCount`, Stoppuhr). Laufzeiten gehören in den Benchmark (`Bench`, mit Vorgabe); im Unit-Test bleibt die fachliche Prüfung. Kein `Sleep` als Ersatz für eine Bedingung; Warteschleifen sind begrenzt und enden mit `Fail`, nicht mit `Status`.
- **Systemabhängigkeiten einspeisen statt nachrechnen oder überspringen:** PPI (Control bzw. Formular per `ScaleForPPI(96)`), Radzeilen (`PPGSetWheelScrollLinesReader`), Locale/`FormatSettings` (`PPGTestGermanFormat`), Datum/Uhrzeit (Uhr der Tippsuche: `PPGSetTypeAheadClock`), Animationen (`PPGSetSystemAnimationsReader`), Hochkontrast (`PPGSetHighContrastReader`), System-Dark-Mode (`TPPGTheme.SystemDarkReader`). Die Erwartung ist ein Literal, nicht dieselbe Formel wie im Code.
- **Überspringen nur über `Skip(Grund)`** (in `TControlTestCase`) bzw. `PPGSkip(Self, Grund)` (übrige `TTestCase`-Ableitungen, Unit `PPG.Tests.Controls`), nie über ein stilles `Exit` oder nur `Status`. Muster: `if Bedingung then begin Skip('Grund'); Exit; end;`. Ohne den Runner-Schalter `/allowskip` ist ein Skip ein Fehlschlag; mit ihm kehrt `Skip` zurück und der Runner meldet am Ende „N übersprungen“ mit Testname und Grund.
- **`except` um Prüfungen** nur mit `raise` am Ende oder mit konkreter Klasse (`on EPPGPropertyError do`). `on Exception`/`on EAbort` verschluckt auch das eigene `Fail`/`Check`: DUnits `ETestFailure` erbt von `EAbort`. Erwartete Exceptions mit `StartExpectingException`/`CheckException` oder `try … Fail('…'); except on E: EKonkret do; end`.
- **Zentrale Prüfung in `TControlTestCase.TearDown`:** Zeichen-/Callback-Fehler an der Fehlergrenze (`FErrors`) und Anwendungs-Exceptions (`FAppExceptions`) lassen den Test fehlschlagen. Ein Test, der Fehler absichtlich provoziert, prüft sie selbst und quittiert sie danach mit `ExpectErrors`. Das TearDown setzt Theme-Modus, `StyleForms`, `SystemDarkReader`, Sprache, `ForceGdiFallback`, Hochkontrast-Reader, Radzeilen- und Animations-Reader, Uhr der Tippsuche, `FormatSettings`, Schatten-Cache-Haken, `PPGAppointmentDialogHook` und den Mess-Cache zurück. Eigene `TearDown`-Methoden rufen `inherited` in `try … finally`, wenn danach noch aufgeräumt wird.
