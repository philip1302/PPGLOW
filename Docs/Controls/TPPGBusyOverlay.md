# TPPGBusyOverlay

Palette **PPGlow** - Unit `PPG.BusyOverlay` - Basis `TComponent`

**Vorbild:** keins; ersetzt `Screen.Cursor := crHourGlass` und selbst gebaute „Bitte warten“-Fenster

## Unterschiede und Hinweise

- Legt sich über ein Control (`Target`) oder das ganze Formular: abgedunkelt, darauf eine Karte mit Ring, Text, Beschreibung, Fortschritt und optional „Abbrechen“.
- Eingaben ins Ziel sind gesperrt, ohne dass es grau wird; der Rest des Formulars bleibt bedienbar. Esc bricht bei `ShowCancel` ab, das Formular lässt sich währenddessen nicht schließen.
- `Delay` (Vorgabe 300 ms) verhindert Aufblitzen bei kurzen Arbeiten, `MinDisplayTime` (500 ms) verhindert Flackern.
- **`Run`** führt die Arbeit in einem Hintergrund-Thread aus; die Oberfläche bleibt lebendig, der Ring dreht sich. Fortschritt und Texte kommen über `IPPGBusyContext`, eine Exception aus dem Thread kommt an der Aufrufstelle an. In der Arbeit keine VCL-Controls anfassen.
- `RunAsync` kehrt sofort zurück und ruft danach `OnDone` im Hauptthread.
- Für Code, der den Hauptthread selbst blockiert: `ShowNow` zeigt die Karte sofort und zeichnet sie; sie steht dann, dreht sich aber nicht.
- Die Abdunklung ist ein eigenes Fenster mit gleichmäßiger Deckkraft; das geht auch per Remote-Desktop.

## Beispiel

```pascal
PPGBusyOverlay1.Run(
  procedure(const C: IPPGBusyContext)
  var
    I: Integer;
  begin
    for I := 1 to 100 do
    begin
      if C.Cancelled then
        Exit;
      ImportiereZeile(I);   // ohne VCL-Zugriff
      C.Report(I);
    end;
  end);
```

## Verhalten (aus dem Quelltext)

Warte-Overlay ueber einem Control oder Formular (Phase 19c).

TPPGBusyOverlay (nicht sichtbar):
- Show/Hide (zaehlend, verschachtelbar): legt eine abgedunkelte Flaeche (TPPGDimWindow aus PPG.Overlay) ueber das Ziel und darauf eine Karte mit Ring, Text, Beschreibung, Fortschritt und optional Abbrechen.
- Eingaben ins Ziel sind ab Show gesperrt, ohne dass es grau wird: die Maus faengt die Flaeche ab (zuerst fast durchsichtig), die Tastatur fuer Fenster im Ziel verwirft ein Nachrichtenhaken (PPG.AppHooks); Esc loest bei ShowCancel Abbrechen aus. Das Formular laesst sich waehrenddessen nicht schliessen (OnCloseQuery verkettet).
- Delay: erst nach dieser Zeit wird abgedunkelt und die Karte gezeigt (kurze Arbeiten blitzen nicht). MinDisplayTime: einmal gezeigt, bleibt das Overlay mindestens so lange stehen. ShowNow zeigt sofort und zeichnet synchron - fuer Code, der danach den Hauptthread blockiert (dann steht das Overlay, animiert aber nicht).
- Run(Work) fuehrt Work in einem Hintergrund-Thread aus und wartet mit laufender Nachrichtenschleife; der Ring dreht sich, Report/SetText aus dem Thread kommen ueber den Kontext an (thread-sicher, der Hauptthread holt sie ab). Eine Exception im Thread wird im Hauptthread erneut ausgeloest. RunAsync kehrt sofort zurueck und ruft OnDone im Hauptthread.
- Die Lage folgt dem Ziel (Formular und Ziel werden beobachtet, dazu ein Abgleich je Animationsschritt); ist das Ziel nicht sichtbar, wird nichts gezeigt. Ohne Platz fuer die Karte nur der Ring.
- Screenreader: Die Karte meldet sich beim Erscheinen (EVENT_SYSTEM_ALERT), Rolle Fortschritt, Name = Text, Wert = Prozent, Standardaktion = Abbrechen.

Grenzen: Die Arbeit in Run darf keine VCL-Controls anfassen (Thread). Wer
waehrend Run das Overlay selbst freigibt (z.B. aus einem Timer), bekommt
einen Fehler.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Target` | `TWinControl` |  | Abgedeckter Bereich: ein Control (nur sein sichtbarer Teil) oder leer = das ganze Formular ohne Titelleiste. Andere Teile des Formulars bleiben bedienbar. |
| `Text` | `string` |  | Haupttext der Karte (fett); leer = „Bitte warten …“. Screenreader lesen ihn beim Erscheinen vor. |
| `Description` | `string` |  | Zweite Zeile unter dem Text, z. B. „Datei 3 von 6“; aus Run über Context.SetDescription. |
| `Progress` | `Integer` | `-1` | -1 = unbestimmt (drehender Ring), 0 … 100 = Prozent im Ring. Aus Run über Context.Report. Nutzung: `Overlay.Run(procedure(const C: IPPGBusyContext) begin C.Report(50); end);` |
| `ShowCancel` | `Boolean` | `False` | Knopf „Abbrechen“ auf der Karte; Esc im gesperrten Bereich bricht dann ebenfalls ab. |
| `CancelCaption` | `string` |  | Beschriftung des Abbrechen-Knopfs; leer = „Abbrechen“. Nach dem Klick zeigt er „Wird abgebrochen …“. |
| `Delay` | `Integer` | `300` | Millisekunden bis zur Anzeige (0 … 60 000). Eingaben ins Ziel sind schon ab Show gesperrt; kurze Arbeiten blitzen so nicht auf. |
| `MinDisplayTime` | `Integer` | `500` | Ist die Karte einmal erschienen, bleibt sie mindestens so viele Millisekunden stehen (0 … 60 000), damit sie nicht nur aufflackert. |
| `DimOpacity` | `Byte` | `96` | Deckkraft der Abdunklung (0 … 255, Vorgabe 96). 0 = keine sichtbare Abdunklung; Maus und Tastatur bleiben trotzdem gesperrt. |
| `Preset` | `string` |  | Preset der Karte ('' = wie der StyleManager bzw. die Vorgabe). |
| `StyleManager` | `TPPGStyleManager` |  | StyleManager für Preset und Farben der Karte. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnCancel` | `TNotifyEvent` `(Sender: TObject)` | Der Benutzer hat abgebrochen (Knopf, Esc oder Screenreader); Cancelled ist dann True, in Run auch Context.Cancelled. |
| `OnShow` | `TNotifyEvent` `(Sender: TObject)` | Die Karte ist erschienen (nach Delay). |
| `OnHide` | `TNotifyEvent` `(Sender: TObject)` | Die Karte ist verschwunden. |

Tests: `PPG.Tests.Audit11C` (TAudit11CGdiTests); `PPG.Tests.Phase19` (TBusyOverlayTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGBusyOverlay.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
