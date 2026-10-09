**Vorbild:** TRadioGroup (DFM gleich: `Items`, `ItemIndex`, `Columns`, `Caption`, `OnClick`)

## Unterschiede und Hinweise

- Keine Kind-Buttons: Die Einträge zeichnet die Gruppe selbst. `Buttons[]` der VCL gibt es nicht; Bild, Beschreibung und Sperre je Eintrag stehen in `ItemsEx`.
- `ChoiceStyle`: `csList` (Kreise wie die VCL), `csSegmented` (Umschalter in einer Zeile, der Akzent gleitet zum neuen Eintrag), `csCards` (Kacheln mit Symbol, Titel und Beschreibung).
- `Columns = 0`: so viele Spalten, wie in die Breite passen.
- `ItemIndex` im Code setzen löst `OnChange` aus, aber kein `OnClick` (wie bei den übrigen PPGlow-Controls).
- Tastatur wie die VCL: Pfeile wechseln innerhalb der Gruppe, Tab verlässt sie. UI Automation: Gruppe mit Auswahl-Muster, Einträge als Optionsfelder.
- `ValidationState` markiert eine fehlende Pflichtauswahl wie bei den Eingabefeldern.

## Beispiel

```pascal
PPGRadioGroup1.ChoiceStyle := csCards;
PPGRadioGroup1.Columns := 0;
with PPGRadioGroup1.ItemsEx.Add do
begin
  Caption := 'Standard';
  Description := '3 bis 5 Werktage';
  Icon := $E7BF;
end;
```
