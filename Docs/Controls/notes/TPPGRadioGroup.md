**Vorbild:** TRadioGroup (DFM gleich: `Items`, `ItemIndex`, `Columns`, `Caption`, `OnClick`)

## Wofür

Die Optionsgruppe lässt den Anwender genau eine aus wenigen, sich ausschließenden Möglichkeiten wählen: Zahlungsart, Versandart, Abrechnungszeitraum. Sie ersetzt `TRadioGroup` und kann dieselbe Auswahl auch als Segment-Umschalter (`csSegmented`) oder als Auswahlkacheln mit Symbol und Beschreibung (`csCards`) zeigen. Alle Optionen sind gleichzeitig sichtbar, der Anwender vergleicht sie ohne Aufklappen.

## Wann verwenden

- Für zwei bis etwa sieben Optionen, die man auf einen Blick vergleichen soll. Bei vielen oder wechselnden Einträgen (Länder, Kunden) ist `TPPGComboBox` platzsparender.
- Statt `TPPGCheckGroup`, wenn genau eine Option gelten darf; mehrere gleichzeitig wählbare Optionen gehören in die CheckGroup.
- Statt einzelner `TPPGRadioButton`, wenn die Optionen beieinanderstehen: eine Gruppe, ein `ItemIndex`, ein Ereignis. Einzelne RadioButtons nur, wenn zwischen den Optionen andere Controls liegen sollen.
- Statt `TPPGCheckBox` oder `TPPGToggleSwitch` bei mehr als zwei Zuständen oder wenn beide Möglichkeiten einen eigenen Namen haben („Rechnung" / „Lastschrift" statt „Lastschrift an/aus").
- Als Segment-Umschalter (`csSegmented`, `ShowFrame = False`) für Ansicht oder Zeitraum über einer Liste oder in einer Werkzeugleiste; für das Umschalten ganzer Seiten sind `TPPGTabControl` bzw. `TPPGPageControl` gedacht.
- Als Kacheln (`csCards`), wenn jede Option eine kurze Erklärung braucht (Versand, Tarif). Große Auswahlen, die sofort etwas tun, sind dagegen Buttons bzw. die Command-Links im `TPPGTaskDialog`.

## Unterschiede und Hinweise

- Keine Kind-Buttons: Die Einträge zeichnet die Gruppe selbst. `Buttons[]` der VCL gibt es nicht; Bild, Beschreibung und Sperre je Eintrag stehen in `ItemsEx`.
- `ChoiceStyle`: `csList` (Kreise wie die VCL), `csSegmented` (Umschalter in einer Zeile, der Akzent gleitet zum neuen Eintrag), `csCards` (Kacheln mit Symbol, Titel und Beschreibung).
- `Columns = 0`: so viele Spalten, wie in die Breite passen.
- Wählt der Anwender (Maus, Pfeiltasten, Zugriffstaste), kommt erst `OnClick`, dann `OnChange`. `ItemIndex` bzw. `Value` im Code setzen löst keines von beiden aus (wie bei den übrigen PPGlow-Controls); abhängige Felder danach selbst aktualisieren.
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
