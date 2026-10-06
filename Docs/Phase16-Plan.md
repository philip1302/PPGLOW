# Phase 16 – Detailplan: Demo mit geführter Tour durch alle Controls

*Stand 05.10.2026. Teil von `Docs\Roadmap2.md`. **Vom User freigegeben am 05.10.2026 (Empfehlungen übernommen).** Kommt bewusst zuletzt, damit die Tour alle Controls der Phasen 11–15 enthält. Setzt `TPPGTeachingTip` (Phase 11f) und die Hilfe (Phase 15d) voraus.*

## Ziel
Wer die Demo startet, wird **Schritt für Schritt durch alle Controls geführt**. Zu jedem Control gibt es:
- **Name**: Klasse und Unit, z. B. `TPPGGauge` aus `PPG.Gauge`
- **Wofür**: ein, zwei Sätze, was das Control ist
- **Wann verwenden**: typische Einsatzfälle und die Abgrenzung zu ähnlichen Controls, z. B. „Gauge vs. ProgressBar vs. ProgressRing“
- **Funktionen**: die wichtigsten Properties und Ereignisse, jeweils mit einem Satz
- **Zum Ausprobieren**: eine kleine Aufgabe („Ziehen Sie den Regler auf 80 %“). Die Tour erkennt die Erledigung und geht weiter.
- **Code**: ein kurzes Beispiel mit Kopierknopf und ein Link zur Hilfeseite (F1-Seite aus Phase 15d)

Daneben bleibt freies Erkunden möglich (Navigation, Suche, Katalog).

## Teilschritte

| Teil | Inhalt | Größe |
|---|---|---|
| 16a | `TPPGTour` (Suite-Komponente) + Spotlight-Overlay | mittel |
| 16b | Tour-Inhalte als Daten, erzeugt aus den Hilfe-Notizen (eine Quelle für Hilfe und Tour) | mittel |
| 16c | Demo neu gliedern: Startseite, Kapitel = Kategorien, Code-Leiste je Seite | groß |
| 16d | Aufgaben mit Erfolgserkennung, Fortschritt, Fortsetzen, Sprache de/en | mittel |
| 16e | Prüfung: jede Palettenklasse hat mindestens einen Schritt (Selbsttest), Screenshot-Modus je Schritt | klein |

## 16a – TPPGTour (wiederverwendbar, nicht nur für die Demo)
Anwendungen können damit ihre eigene Einführung bauen. TMS hat dafür nichts Vergleichbares; das wäre ein Alleinstellungsmerkmal.

**Modell (SRP, keine Zeichenlogik): `PPG.Tour.Model`**
- `TPPGTourStep` (CollectionItem):
  - Inhalt: `Title`, `Text` (Markup), `Code` (Text), `HelpKeyword`, `Placement`
  - Ziel: `TargetName` (Name-Pfad, z. B. `PageCharts.Gauge1`) **oder** `Target: TControl`, dazu `Page` (Ziel-Seite oder Navigation)
  - Ablauf: `Task` (Text der Aufgabe), `Chapter`, `Condition` (siehe 16d)
- `TPPGTourSteps` mit Kapiteln; laden und speichern als JSON-Text (für die Inhalte aus 16b).

**Steuerung: `TPPGTour`** (nicht sichtbare Komponente)
- Methoden `Start(Chapter)`, `Next`, `Back`, `Skip`, `Stop`; Eigenschaften `CurrentStep`, `Progress`.
- Ereignisse `OnNavigate(Step)`: Die Anwendung zeigt die passende Seite bzw. klappt Bereiche auf. Die Tour kennt die Navigation der Anwendung nicht (DIP).
- Weitere Ereignisse: `OnStepShown`, `OnFinished`, `OnCheckCondition`.
- **Ziel auflösen:** Name-Pfad über `FindComponent`. Ist das Ziel unsichtbar (andere Seite, zugeklappter Expander, außerhalb des Scrollbereichs), wird zuerst `OnNavigate` aufgerufen, dann `ScrollInView` (für Scroll-Container und PPGlow-Scroll-Controls), dann erst angezeigt.
- **Darstellung über `TPPGTeachingTip`** (Phase 11f):
  - Titel, Text, Fortschritt „Schritt 12 von 58“, Buttons Zurück/Weiter und „Tour beenden“
  - Code-Bereich mit Kopierknopf und Link zur Hilfe

**Spotlight-Overlay: `TPPGTourOverlay`**
- Fenster über dem Formular, das alles außer dem Ziel abdunkelt.
- **Fensterregion mit Loch** (`SetWindowRgn`): Klicks im Loch gehen direkt an das echte Control. Mit nur halbtransparentem Layered-Fenster müsste man Klicks weiterleiten, und Ziehen oder Tastatur im Ziel würden brechen.
- Abdunklung per `WS_EX_LAYERED` mit konstanter Deckkraft (`SetLayeredWindowAttributes`). In Remote-Sitzungen bzw. ohne DWM gibt es stattdessen einen Rahmen um das Ziel, ohne Abdunklung (C10).
- Folgt dem Ziel bei Größenänderung, Scrollen und DPI-Wechsel (Beobachter am Formular wie beim TeachingTip).
- Esc beendet die Tour; die Tastatur bleibt beim Formular. Die Tour aktiviert nie ein eigenes Fenster außer für die Buttons der Sprechblase.

## 16b – Inhalte aus einer Quelle
Die Hilfe-Notizen (`Docs\Controls\notes\<Klasse>.md`) gibt es schon. Sie bekommen einen Abschnitt `## Tour` mit festen Unterpunkten:

```markdown
## Tour
- Wofür: ...
- Wann verwenden: ... (statt X, wenn ...)
- Funktionen: `Value` – ...; `Ranges` – ...; `OnChange` – ...
- Aufgabe: Ziehen Sie den Bogen auf 80 %.
- Bedingung: Value >= 80
- Ziel: PageCharts.Gauge1
- Code: |
    PPGGauge1.Ranges.Add.EndValue := 60;
```

- `make-tour.ps1` erzeugt daraus `Demo\Tour\tour.de.json` und `tour.en.json`. Die englischen Texte stehen in `notes\en\`; fehlt eine, nimmt das Skript die deutsche und meldet sie.
- So sind Hilfe und Tour nie verschieden (DRY), und eine neue Komponente bekommt Hilfe und Tour mit einer Datei.
- Der Regel-Prüfer (neue Regel TOUR) meldet Palettenklassen ohne `## Tour`-Abschnitt.

## 16c – Neue Gliederung der Demo
- **Startseite:**
  - Begrüßung mit drei Wegen: „Geführte Tour starten“, „Kapitel wählen“, „Frei erkunden“
  - Kapitelkacheln mit Fortschritt, z. B. „Eingabe 6/9“
  - Darstellung wählen (Preset, Hell/Dunkel, Sprache), weil das jedes Control betrifft
- **Kapitel** = Kategorien der Navigation:
  1. Grundlagen (Buttons, Auswahl, Regler)
  2. Eingabe (Felder aus Phase 4 und 12)
  3. Listen und Bäume
  4. Tabelle (Grid-Profi aus Phase 13)
  5. Datum und Planung (Kalender, Picker, Planer)
  6. Navigation und Layout (NavigationView, Reiter, Expander, Ribbon, Menüs)
  7. Rückmeldung (InfoBar, Toast, Dialoge, Hints, TeachingTip)
  8. Diagramme
  9. Datenbank
  10. Darstellung und Barrierefreiheit (Presets, Dark Mode, Hochkontrast, Screenreader, RTL, DPI)
  11. Für Entwickler (StyleManager, Übersetzung, Migration, Tour-Komponente selbst)
- **Jede Seite:**
  - Kopf mit Kapitelname und „Tour ab hier“
  - Karten je Control mit Name (Klasse) und Einzeiler
  - unten eine **Code-Leiste**, die beim Fokus bzw. Überfahren einer Karte das passende Beispiel zeigt
- Die vorhandenen Seiten werden auf diese Kapitel verteilt; die Seitennummern für `/page` bleiben über eine Zuordnungstabelle erhalten (Skripte und Doku verwenden sie).

## 16d – Aufgaben und Fortschritt
- **Bedingungen** als kleine Ausdrücke über Properties des Ziels, ohne Skriptsprache: `Prop op Wert`, mit und ohne „und“, z. B. `Value >= 80`, `Checked = True`, `ItemIndex = 2`, `Series[1].Visible = False`.
  - Ausgewertet über RTTI (`System.TypInfo`, XE2-tauglich) nach jedem Ereignis des Ziels und spätestens alle 250 ms über den Animator.
  - Für Sonderfälle `OnCheckCondition`.
- **Erledigt:** Häkchen-Animation in der Sprechblase, nach 600 ms automatisch weiter (abschaltbar); „Überspringen“ ist immer möglich.
- **Fortschritt** je Kapitel und gesamt; gespeichert in einer INI-Datei im Benutzerprofil (`%APPDATA%\PPGlow\Demo.ini`). „Fortsetzen“ auf der Startseite.
- **Sprache:** Deutsch und Englisch für Tour, Demo und Suite (`PPGSetLanguage`); Umschalten mitten in der Tour lädt die andere JSON-Datei und bleibt beim Schritt.
- **Barrierefreiheit:**
  - Jeder Schritt wird angesagt (`EVENT_SYSTEM_ALERT` mit Titel und Aufgabe)
  - Tastatur: Strg+Enter = weiter, Strg+Rücktaste = zurück, Esc = beenden
  - Die Tour ist auch ohne Maus vollständig durchführbar.

## 16e – Prüfung
- **Selbsttest** (`/selftest`):
  - Jede Klasse aus `RegisterComponents` (PPG.Reg und PPG.DB.Reg) hat mindestens einen Schritt.
  - Jedes Ziel lässt sich auflösen.
  - Jede Bedingung lässt sich auswerten.
  - Die Tour läuft einmal automatisch komplett durch: Aufgaben werden per Code erfüllt, ohne Fehler.
- **Screenshot je Schritt:** `/tourshot n datei.png` bzw. `/tourshots ordner`, für die Doku und die Sichtprüfung.
- **Leak-Lauf** mit einmal kompletter Tour.

## Fallstricke
| Fallstrick | Gegenmittel |
|---|---|
| Ziel in einem Popup (Combo-Liste, Menü) | Schritte zeigen auf den Auslöser; die Aufgabe öffnet das Popup, die Bedingung prüft das Ergebnis |
| Fensterregion mit Loch und DPI-Wechsel | Region bei `WM_DPICHANGED` und jedem Layout neu |
| Overlay über modalen Dialogen | Dialoge sind eigene Fenster: Die Tour pausiert, solange ein modales Fenster offen ist (`Screen.ActiveForm` ≠ Hauptformular) |
| Texte zu lang für die Sprechblase | Maximalbreite, Umbruch, Code-Bereich scrollbar; `make-tour.ps1` warnt ab N Zeichen |
| Inhalte veralten | eine Quelle (16b) und die Prüfungen in 16e |
| Remote-Desktop | kein Layered-Overlay, nur Rahmen (C10) |

## Anforderungen (Zuordnung zu Roadmap2)
- C4: Tour ohne Maus, Ansagen.
- C9: de/en.
- C10: Rückfall ohne Abdunklung.
- C11: Erklärungen, Code und Hilfe-Link je Control.
- C12: Selbsttest deckt jede Komponente ab.

## Tests
- `PPG.Tests.Phase16`: Modell (JSON-Rundreise, Kapitel), Ziel-Auflösung mit Navigation, Bedingungs-Parser (Tabelle gültiger und ungültiger Ausdrücke), Overlay-Region (Loch an der richtigen Stelle, Klick geht durch)
- TeachingTip folgt dem Ziel, `TPPGTour` ohne Ereignisse bei Code-Aufrufen
- Demo-Selbsttest wie oben.

## Entscheidungen für den User
1. `TPPGTour` als Suite-Komponente für eigene Anwendungen (empfohlen) oder nur in der Demo?
2. Englisch von Anfang an mitpflegen (empfohlen, die Suite hat bereits die Übersetzung)?
3. Automatisches Weitergehen nach erledigter Aufgabe (empfohlen, abschaltbar)?
