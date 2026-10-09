# TPPGHintManager

Palette **PPGlow** - Unit `PPG.Hints` - Basis `TComponent`

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

## Verhalten (aus dem Quelltext)

Hints im Stil der Suite (Phase 11e).

TPPGHintManager (nicht sichtbare Komponente, Opt-in):
- setzt zur Laufzeit Vcl.Forms.HintWindowClass := TPPGHintWindow und stellt beim Freigeben die vorige Klasse wieder her. Zur Entwurfszeit nie (sonst bekaeme die IDE selbst diese Hints).
- Die VCL legt ihr Hint-Fenster erst beim ersten Hint an; nach dem Wechsel wird es ueber Application.ShowHint := False/True neu erzeugt.
- Hint-Text "Titel|Text" wie bei der VCL: zeigt die VCL sonst nur den kurzen Teil, zeigt der Manager (ShowTitle) Titel fett und Text darunter. Ein Control, das den Text in CM_HINTSHOW selbst setzt, behaelt ihn.
- Optional Markup (<b>, <i>, <color=...>) ueber PPG.Markup.

TPPGHintWindow (THintWindow):
- zeichnet ueber IPPGHintRenderer mit den Farben des Presets (Hell/Dunkel, Hochkontrast: clInfoBk/clInfoText).
- Groesse und Schrift fuer die DPI des Monitors unter dem Mauszeiger.
- Schatten ueber CS_DROPSHADOW (vom THintWindow), kein Layered-Alpha.
- Screenreader: Rolle Tooltip und Name = Text (IAccPropServices), EVENT_OBJECT_SHOW beim Zeigen.

TPPGCustomHint (TCustomHint):
- fuer die CustomHint-Property einzelner Controls (wie TBalloonHint): Title, Description, Images/ImageIndex; zeichnet wie TPPGHintWindow.

Gemeinsam: TPPGHintContent misst und zeichnet den Inhalt (DRY).

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Active` | `Boolean` | `True` | True: Alle Hints der Anwendung erscheinen zur Laufzeit im PPGlow-Stil (HintWindowClass wird ersetzt und beim Freigeben wiederhergestellt). Im Designer ohne Wirkung. Nutzung: Einen TPPGHintManager auf das Hauptformular legen, Active := True. |
| `Preset` | `string` |  | Optik-Vorlage der Hints; '' = Standard bzw. StyleManager. |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle für Preset und Farben der Hints. |
| `ShowTitle` | `Boolean` | `True` | True: Besteht ein Hint aus Titel und Text, getrennt durch einen senkrechten Strich (wie bei der VCL), erscheint der Titel fett und der Text darunter; False: nur der kurze Teil wie bei der VCL. Nutzung: Hint-Text im Format der VCL: kurzer Titel, senkrechter Strich, ausführlicher Text. |
| `AllowMarkup` | `Boolean` | `False` | True: Hint-Texte dürfen Mini-Markup enthalten (<b>, <i>, <color=...>). |
| `MaxWidth` | `Integer` | `360` | Größte Breite eines Hints in logischen Pixeln (80..2000); längerer Text bricht um. |
| `HighContrastSupport` | `Boolean` | `True` | True: Im Windows-Hochkontrastmodus erscheinen die Hinweise in den Systemfarben für Tooltips statt in den Farben des Presets. |

Tests: `PPG.Tests.Audit11C` (TAudit11CBehaviourTests); `PPG.Tests.Audit45` (TStreamingFixTests); `PPG.Tests.Audit7C` (THighContrastTokenTests); `PPG.Tests.Phase11b` (THintTests); `PPG.Tests.Streaming` (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGHintManager.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
