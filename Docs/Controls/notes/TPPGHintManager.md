**Vorbild:** TMS TAdvOfficeHint, Tooltips von Windows 11

## Unterschiede und Hinweise

- Opt-in: Erst ein `TPPGHintManager` auf einem Formular stellt die Hints der **ganzen Anwendung** um (`HintWindowClass`). Beim Freigeben oder mit `Active = False` kommt die vorige Klasse zurück. Im Designer passiert nichts.
- Hint-Text `"Titel|Text"` wie bei der VCL: Mit `ShowTitle` (Vorgabe) erscheint der Titel fett und der Text darunter, ohne nur der kurze Teil. Hat ein Control den Text in `CM_HINTSHOW` selbst gesetzt, bleibt dieser.
- `AllowMarkup` erlaubt `<b>`, `<i>`, `<color=…>` im Text; ohne bleiben `<` und `&` sichtbar.
- Größe und Schrift folgen der DPI des Monitors unter dem Mauszeiger; Farben dem Preset, Dark Mode, VCL-Style und Hochkontrast (`clInfoBk`).
- Zeiten kommen unverändert aus `Application.HintPause`/`HintHidePause`.
- Für einzelne Controls gibt es `TPPGCustomHint` (Property `CustomHint`).
- Nur ein Manager ist aktiv; ein zweiter übernimmt.

## Beispiel

```pascal
PPGHintManager1.Preset := 'Fluent11';
SaveButton.Hint := 'Speichern (Strg+S)|Speichert das Dokument.';
SaveButton.ShowHint := True;
```
