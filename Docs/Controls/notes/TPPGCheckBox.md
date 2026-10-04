**Vorbild:** TCheckBox

## Unterschiede und Hinweise

- `Checked`/`State` im Code setzen löst nur `OnChange` aus, nicht `OnClick` (bewusst anders als die VCL).
- Der gemischte Zustand (`cbGrayed`) ist ein Akzent-Strich; Anwender erreichen ihn nur mit `AllowGrayed = True`.

## Beispiel

```pascal
PPGCheckBox1.AllowGrayed := True;
PPGCheckBox1.State := cbGrayed;  // OnChange, kein OnClick
```
