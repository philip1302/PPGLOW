**Vorbild:** TcxCheckGroup (DevExpress); in der VCL gibt es keine Entsprechung

## Wofür

Die CheckGroup ist eine Gruppe von Kästchen mit Rahmen und Überschrift, von denen der Anwender beliebig viele ankreuzt: Liefertage, Benachrichtigungswege, Rechte je Modul. Sie ersetzt eine Handvoll einzelner `TCheckBox` in einer `TGroupBox` durch ein Control, dessen `Value` die Auswahl als Kommaliste liefert und auch wieder lädt. Neben der klassischen Liste kann sie Segmente (Filterleiste) und Kacheln mit Symbol und Beschreibung zeigen.

## Wann verwenden

- Für eine feste, kurze Liste (etwa 2 bis 10 Einträge), aus der mehrere gewählt werden dürfen. Darf nur genau einer gewählt werden, ist `TPPGRadioGroup` richtig.
- Statt mehrerer `TPPGCheckBox`, wenn die Optionen zusammengehören und gemeinsam gespeichert werden (`Value`). Eine einzelne Ja/Nein-Einstellung bleibt eine `TPPGCheckBox` oder ein `TPPGToggleSwitch`.
- Statt `TPPGCheckListBox`, wenn alle Einträge ohne Scrollen sichtbar sein sollen. Lange oder zur Laufzeit wachsende Listen (Filialen, Artikelgruppen) gehören in die CheckListBox, im knappen Platz in die `TPPGCheckComboBox`.
- Mit `ChoiceStyle = csSegmented` und `ShowFrame = False` als Mehrfach-Filter über Listen (Status „Offen / In Arbeit / Erledigt“); mit `csCards` für wenige wichtige Optionen, die eine Erklärung brauchen.
- Mit `AllowGrayed`, wenn ein dritter Zustand fachlich gebraucht wird, z. B. „nur lesen“ zwischen „bearbeiten“ und „kein Zugriff“.

## Unterschiede und Hinweise

- Dieselbe Basis wie `TPPGRadioGroup` (`ChoiceStyle`, `Columns = 0`, `ItemsEx`), aber mit Mehrfachauswahl.
- `Checked[i]` liest und setzt ein Kästchen, `ItemsEx[i].State` auch den grauen Zustand (`AllowGrayed`).
- `Value` ist die Kommaliste der angehakten Werte (`ItemsEx[i].Value`, leer = Beschriftung) und lässt sich auch setzen, z. B. aus einem Datenbankfeld.
- Bei `csSegmented` hebt der Akzent die angehakten Einträge hervor, bei `csCards` zusätzlich ein Kästchen in der Ecke der Kachel.

## Beispiel

```pascal
PPGCheckGroup1.Items.CommaText := 'Mo,Di,Mi,Do,Fr';
PPGCheckGroup1.Value := 'Mo,Mi';
ShowMessage(PPGCheckGroup1.Value);
```
