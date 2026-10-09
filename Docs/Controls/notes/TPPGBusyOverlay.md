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
