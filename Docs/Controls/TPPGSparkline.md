# TPPGSparkline

Palette **PPGlow** - Unit `PPG.Sparkline` - Basis `TPPGCustomSparkline`

**Vorbild:** Excel-Sparklines, TMS FNC Chart (Sparkline)

## Unterschiede und Hinweise

- Kein Fokus, kein Hover, keine Ereignisse außer Maus/Klick. Werte im Code (`SetValues`, `AddValue`) oder im DFM über `ValuesText` (`"3;5;2.5"`, Punkt als Dezimaltrenner).
- `MaxCount` > 0 macht aus `AddValue` ein Lauffenster.
- Ohne eigenen Bereich (`UseRange = False`) stehen Säulen und Flächen auf der Nulllinie.
- Sehr viele Werte werden pro Pixelspalte auf Min/Max verdichtet.
- `PPGDrawSparkline`/`PPGDrawSparklineOnCanvas` zeichnen dieselbe Darstellung ohne Control (Grid-Zellen, eigene Kacheln).

## Beispiel

```pascal
procedure TForm1.PPGGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  O: TPPGSparklineOptions;
begin
  if (ACol = 3) and (ARow > 0) then
  begin
    O := PPGDefaultSparklineOptions(PPGDefaultTokens(False), clWindow, Screen.PixelsPerInch);
    InflateRect(Rect, -4, -3);
    PPGDrawSparklineOnCanvas(PPGGrid1.Canvas, Rect, FVerlauf[ARow], O);
  end;
end;
```

## Verhalten (aus dem Quelltext)

TPPGSparkline - kleiner Werteverlauf ohne Achsen (Phase 10b).

- Arten: Linie, Flaeche, Saeulen, Gewinn/Verlust.
- Markierungen fuer Minimum, Maximum, ersten und letzten Wert; Referenzlinie (z.B. Ziel oder Durchschnitt); eigener Wertebereich.
- Werte im Code (SetValues, AddValue mit MaxCount als Lauffenster) oder im DFM ueber ValuesText ("3;5;2.5;8", Punkt als Dezimaltrenner).
- PPGDrawSparkline zeichnet dieselbe Darstellung ohne Control, z.B. in Grid-Zellen (OnDrawCell) oder in TPPGKpiTile.
- Sehr viele Werte werden pro Pixelspalte auf Min/Max verdichtet.
- Kein Fokus, kein Hover. Screenreader: Rolle Diagramm, Wert "Min x, Max y, letzter z".

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `HighContrastSupport`, `Kind`, `Markers`, `MaxCount`, `LineWidth`, `LineColor`, `NegativeColor`, `UseRange`, `RangeMin`, `RangeMax`, `ShowReference`, `ReferenceValue`, `ValuesText`, `Align`, `Anchors`, `Constraints`, `Enabled`, `Hint`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnClick`, `OnDblClick`, `OnMouseDown`, `OnMouseMove`, `OnMouseUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGSparkline.md`.
