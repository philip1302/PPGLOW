**Vorbild:** TcxCheckGroup (DevExpress); in der VCL gibt es keine Entsprechung

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
