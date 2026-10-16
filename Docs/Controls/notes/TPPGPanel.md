**Vorbild:** TPanel

## Unterschiede und Hinweise

- `AutoSize` wie bei `TPanel`: Größe aus den Kind-Controls (Regeln unter `AutoSize`), begrenzt durch `Constraints`.
- Kinder auf dem Panel zeichnen ihren Hintergrund über den schnellen Eltern-Hintergrund (`GetChildBackground`).

## Anpassung

- `RoundedCorners` und `Shadow`; der Schatten verkleinert die Fläche, Kinder bleiben innerhalb.
