**Vorbild:** TRadioButton

## Wofür

Der RadioButton bietet eine Wahl aus wenigen, sich gegenseitig ausschließenden Möglichkeiten: Versandart, Exportformat, Zahlungsweise. Alle Optionen sind gleichzeitig sichtbar, genau eine ist gewählt. Gruppen bilden sich über den gemeinsamen Parent und `GroupIndex`, die Bedienung mit Tab und Pfeiltasten entspricht Windows.

## Wann verwenden

- Für zwei bis etwa sechs Optionen, die der Anwender vergleichen soll. Bei mehr Optionen oder wenig Platz ist `TPPGComboBox` besser.
- Statt `TPPGRadioGroup`, wenn die Optionen frei angeordnet werden oder eigene Zusätze brauchen (eigenes `Enabled`, `Hint`, ein Eingabefeld direkt neben einer Option). Für eine einfache Liste von Optionen in einem Rahmen ist die RadioGroup mit `Items` und `ItemIndex` kürzer.
- Nicht für Ein/Aus: Ein einzelner Zustand gehört in `TPPGCheckBox` (Einstellung, die mit OK gilt) oder `TPPGToggleSwitch` (wirkt sofort). Ein einzelner RadioButton lässt sich nicht wieder ausschalten.
- Nicht für Befehle: Was sofort etwas tut, ist ein `TPPGButton`; als Umschalter in einer Leiste ein Button mit `GroupIndex`.

## Unterschiede und Hinweise

- Gruppe = gleicher Parent und gleicher `GroupIndex` (die VCL kennt nur den Parent). Mit `GroupIndex` lassen sich mehrere Gruppen in einem Container trennen.
- Klick, Leertaste, Pfeiltaste und Zugriffstaste schalten nur ein, nie aus. Die Pfeiltasten wechseln innerhalb der Gruppe nach `TabOrder` (mit Umlauf) und wählen die neue Option.
- Nur die gewählte Option der Gruppe (ohne Auswahl die erste nach `TabOrder`) ist Tabstopp; `TabStop` verwaltet die Gruppe selbst.
- `Checked` im Code schaltet die anderen der Gruppe aus und löst nur `OnChange` aus, `OnClick` nicht. `OnChange` kommt auch für die Option, die ausgeschaltet wird.
