# Phase 5 – Detailplan: Fundament für Daten-Controls

*Stand 03.10.2026. Teil der Roadmap (`Docs\Roadmap.md`). Ergebnis: keine neuen Paletten-Controls, sondern die gemeinsame Infrastruktur für ListBox, TreeView und Grid (Phase 6).*

**Status: umgesetzt (03.10.2026).**
- 296 Tests grün; Benchmark hält alle Vorgaben ein; Runtime auch für Win64 kompiliert.
- Zusätzlich zum Plan: schneller Eltern-Hintergrund für Kinder auf PPGlow-Containern. Der Benchmark hatte gezeigt, dass `DrawParentBackground` für jedes Kind den ganzen Container zeichnet.
- Ergebnisse und Fallstricke stehen in `Docs\Architektur.md` („Fundament für Daten-Controls“).

## Bausteine

| Unit | Inhalt |
|---|---|
| `Render\PPG.Render.Intf` | `IPPGScrollRenderer.DrawScrollBar(Track, Thumb, Style, Vertical, Expand, Hot, Pressed, PPI)`. Standard in `TPPGRendererBase`: Fluent-Overlay (ruhend 2 px, beim Hover breit mit Spur) |
| `Controls\PPG.RowLayout` | `TPPGRowLayout`: Zeilenpositionen. Bei fester Höhe O(1), bei variabler Höhe ein Präfixsummen-Cache, der lazy neu aufgebaut wird, plus binäre Suche. Getestet mit 1 000 000 Zeilen |
| `Controls\PPG.Controls.Scroll` | `TPPGCustomScrollControl`: Inhaltsgröße, ScrollX/ScrollY, weiches Scrollen über den Animator, Mausrad mit Rest (hochauflösende Touchpad-Deltas), Shift+Rad und `WM_MOUSEHWHEEL` horizontal, Overlay-Scrollleisten (Daumen ziehen, Spur blättert, Ein- und Ausblenden), Tastatur-Helfer, Auto-Scroll beim Ziehen, RTL, `ScrollBarMode` (Auto/Always/Never; Auto folgt der Windows-Einstellung „Bildlaufleisten immer anzeigen“) |
| `Core\PPG.Selection` | `TPPGSelection`: Single, Multi und Extended (Strg/Shift wie Windows-Listen), Anker und Fokus-Element, `TBits`-Speicher, Einfügen und Löschen verschiebt die Auswahl, `BeginUpdate`/`EndUpdate`, `OnChange` |
| `Core\PPG.Items` | `TPPGItem`/`TPPGItems` (`TOwnedCollection`: Text, Detail, ImageIndex, Badge, Group, Checked, Enabled, Tag, Data), `TPPGItemData`, `IPPGItemSource` mit drei Quellen: Collection, `TStrings` (DFM-kompatibel zu `TListBox.Items`) und virtuell (`OnGetItem`) |
| `Render\PPG.Markup` | Mini-Markup: `<b> <i> <u> <s> <color=..> <a href=..> <img=n> <br>` sowie `&lt; &gt; &amp;`. Parser (wirft nie, Unbekanntes bleibt Text), Layout mit Umbruch über `PPGMeasureTextNoCanvas`, Zeichnen über `IPPGCanvas`, Link-Hit-Test, Cache |
| `Access\PPG.Accessibility` | Optional `IPPGAccessibleMultiSelection`: Mehrfachauswahl für `accSelection` (Enumerator) und `accSelect` |
| `Tests\Bench\PPGlowBench` | Konsolen-Benchmark mit Zeitvorgaben (Exit-Code 1 bei Überschreitung): 1000 Buttons, Zeilen-Layout 1M, Auswahl 1M, Markup 10k, Scroll-Control 100k Zeilen, Resize-Sturm |

## Bewusste Entscheidungen
- Die Scrollleisten liegen über dem Inhalt (Overlay, wie Windows 11). Wer das nicht möchte, setzt `ScrollBarMode = sbmAlways`: Die Leiste bleibt dann breit sichtbar, und der Inhalt wird um ihre Breite schmaler.
- Screenreader bekommen keine eigenen Scrollleisten-Kinder: Die virtuellen Kinder gehören den Einträgen (ListBox, Baum). Den Bildlauf übernimmt das Anzeigen des fokussierten Eintrags.
- Markup ist kein HTML: Es gibt keine Tabellen, Schriftgrößen oder CSS.

## Tests (`Tests\PPG.Tests.Phase5.pas`)
Abgedeckt sind:
- Zeilen-Layout: fest, variabel, Grenzen, 1M
- Auswahl: alle Tastatur- und Maus-Kombinationen, Einfügen und Löschen
- Quellen und Collection-Streaming
- Markup: Parser, Escapes, ungültige Eingaben (Fuzz), Umbruch, Links
- Scroll-Control: Rad, Rest, horizontal, Daumen, Spur, weich, Modus, RTL, Sichtbar-Machen, Auto-Scroll, Pixeltest beider Presets und GDI, Leaks
- Barrierefreiheit: Mehrfachauswahl
