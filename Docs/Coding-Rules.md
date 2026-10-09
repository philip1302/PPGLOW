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
- `Build\check-rules.ps1` prüft vor jedem Build: ASCII, CRLF, `{$I ..\PPG.inc}`, `{$IFEND}`, Inline-Variablen und `NameOf`, Syntaxreste, `}` in Kommentaren, `raise` nur mit `PPG.Exceptions` (in `Source`), keine leeren `except`, jede Unit in allen Projektlisten und vollständige Übersetzungen.
- Ein Verstoß bricht `build.ps1` ab. `-NoRuleCheck` gibt es nur für Notfälle.
- Neue Regeln bekommen ein Negativbeispiel in `Build\check-rules-tests` (`check-rules.ps1 -SelfTest`).
- DB-Units (`Data.DB`) gehören nur nach `Source\DB` und damit in `PPGlowDBR`. Das Grundpaket `PPGlowR` linkt kein `Data.DB`.

## Exceptions
- Nur Klassen aus `PPG.Exceptions` werfen. Die Meldung kommt aus einem `resourcestring` (`CreateRes`/`CreateResFmt`).
- **Erst validieren, dann zuweisen.** Zahlenwerte werden über `PPGCheckRange` geprüft. Das wirft zur Laufzeit und klemmt beim DFM-Laden.
- **Kein** leeres `except end`. Ein `except` ohne Klassenfilter gibt es nur an den dokumentierten Grenzen: Paint, Timer/Animation, die COM-Methoden von `IAccessible` (Aufruf aus fremden Prozessen, Rückgabe `E_FAIL`) und den Fehler-Handler selbst. Das Hilfsfenster von `PPG.Theme` (`WM_SETTINGCHANGE`) fängt `Exception` und gibt sie an `Application.HandleException` weiter.
- Neue Controls melden sich nicht selbst beim Theme an; das erledigt `TPPGCustomControl`. Farben, die nicht in der Appearance stehen, kommen aus `Tokens` (im Dark Mode dunkel), nie direkt aus `clWindow`/`clBtnFace`, außer im Hochkontrast-Zweig.
- Code, der von außen über COM oder Fensternachrichten angestoßen wird (z. B. `accDoDefaultAction`), führt keinen Anwender-Code direkt aus, sondern postet eine Nachricht.
- Windows-API-Fehler werden über `PPGRaiseLastOSError('ApiName')` gemeldet, nicht über `RaiseLastOSError`.
- Interne Zustände werden **vor** dem Aufruf von Anwender-Events gesetzt bzw. zurückgesetzt.
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
- Default-Werte nach einem Release nie ändern. Umbenannte Properties bleiben per `DefineProperties` lesbar.
- Published-Reihenfolge ist Streaming-Reihenfolge. Abhängige Properties stehen deshalb hinter ihren Voraussetzungen.
- In Settern `csLoading` beachten. Die Initialisierung gehört in `Loaded`.

## Threads
- Die VCL darf nur im Main-Thread verwendet werden. `Invalidate` prüft das im Debug-Build per `Assert`.

## Tests
- Jede neue Property bekommt einen Test für den gültigen Wert, den ungültigen Wert (Exception, Objekt unverändert) und das Streaming.
- Jedes neue Control bekommt Lebenszyklus-, Paint- (GDI+ **und** GDI-Fallback), Verhaltens- und Ressourcentests.
- Ein gefundener Bug bekommt zuerst einen Regressionstest, danach wird er behoben.
