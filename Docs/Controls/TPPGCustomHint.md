# TPPGCustomHint

Palette **PPGlow** - Unit `PPG.Hints` - Basis `TCustomHint`

Fuer die CustomHint-Property einzelner Controls (wie TBalloonHint).

**Vorbild:** `TBalloonHint` der VCL

## Unterschiede und Hinweise

- Für die Property `CustomHint` einzelner Controls: Titel und Beschreibung kommen wie bei `TBalloonHint` aus dem Hint-Text des Controls (`"Titel|Beschreibung"`), das Bild aus `Images`/`ImageIndex`.
- Zeichnet wie der Hint-Manager (Preset, Dark Mode, Hochkontrast, DPI des Monitors), aber ohne Ballonform: `Style` ist standardmäßig `bhsStandard`.
- Ein- und Ausblenden übernimmt die VCL (`TCustomHint` mit eigenem Thread); `Delay` und `HideAfter` wirken wie gewohnt.
- `MaxWidth` begrenzt die Breite in logischen Pixeln (80–2000).

## Beispiel

```pascal
Edit1.CustomHint := PPGCustomHint1;
Edit1.Hint := 'Kundennummer|Sieben Ziffern, z. B. 1004711.';
Edit1.ShowHint := True;
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

`Preset`, `StyleManager`, `AllowMarkup`, `MaxWidth`, `Style`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGCustomHint.md`.
