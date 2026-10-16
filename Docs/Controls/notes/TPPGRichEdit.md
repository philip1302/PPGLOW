**Vorbild:** TRichEdit

## Wofür

Das RichEdit nimmt formatierten Text auf: Schriftart, Größe, Fett, Kursiv, Farbe, Absatzausrichtung, Einzüge und Aufzählungen. Es liest und schreibt RTF und kommt mit Bearbeiten-Menü, Undo und Zwischenablage des Systems. Optik und Verhalten des Rahmens entsprechen `TPPGMemo` (Preset, Fokusrahmen, `ValidationState`).

## Wann verwenden

- Für Formulare, die bisher `TRichEdit` benutzen: Der DFM-Tausch ist 1:1 (`Lines`, `ScrollBars`, `WordWrap`, `PlainText`, `Zoom` …), ebenso der Code (`SelAttributes`, `Paragraph`, `DefAttributes`, `FindText`).
- Für Texte, in denen Anwender Formatierung brauchen (Briefe, Notizen mit Hervorhebung, Hilfetexte). Reiner Text ohne Formatierung gehört in `TPPGMemo`; nur zum Anzeigen formatierter Texte genügt `TPPGLabel` mit `AllowMarkup`.
- An ein Memo- oder BLOB-Feld gebunden: `TPPGDBRichEdit`.

## Unterschiede und Hinweise

- Dahinter arbeitet das native RichEdit (`msftedit`), das in einen PPGlow-Rahmen eingebettet ist. `SelAttributes`, `DefAttributes` und `Paragraph` sind die VCL-Klassen `TTextAttributes` und `TParaAttributes`; `Lines.LoadFromStream`/`SaveToStream` lesen und schreiben RTF (mit `PlainText = True` reinen Text).
- **Farben:** Der Hintergrund folgt dem Theme (Dark Mode, Hochkontrast, VCL-Style). Text ohne eigene Farbe („automatisch“) wird in der Themefarbe gezeichnet, im Dark Mode also hell. Text mit eigener Farbe (RTF-Farbtabelle, `SelAttributes.Color`) und der gespeicherte RTF-Inhalt bleiben unverändert: Beim Wechsel zwischen hell und dunkel ändert sich keine Zeichenformatierung. Wer Schwarz als Zeichenfarbe festlegt, bekommt im Dark Mode schwarzen Text auf dunklem Grund.
- Wie bei `TRichEdit` zählen `SelStart`/`SelLength` mit dem Absatzende, `Text` trennt Absätze mit `#13` (`Lines.Text` mit `#13#10`), und `SelText` lässt sich nicht rückgängig machen (nur getippter Text).
- In der DFM stehen die Zeilen als reiner Text (`Lines.Strings`), ohne Formatierung. Formatierter Text wird zur Laufzeit aus Datei oder Ressource geladen.
- Die Attribut-Objekte (`SelAttributes`, `DefAttributes`) liefern ohne Fensterhandle (noch kein Parent) leere Werte; das ist das Verhalten von `TRichEdit`.
- `TextHint` und `CharCase` gibt es beim RichEdit nicht.
- Drucken: `Print(Caption)` druckt formatiert auf den Standarddrucker.
- Technik: Für die Themefarbe des automatischen Texts setzt das Control während des Zeichnens kurz `COLOR_WINDOWTEXT` (`SetSysColorsTemp`, wie die VCL beim Zeichnen deaktivierter RichEdits).

## Beispiel

```pascal
RichEdit1.Lines.LoadFromFile('brief.rtf');
RichEdit1.SelStart := 0;
RichEdit1.SelLength := 5;
RichEdit1.SelAttributes.Style := [fsBold];
RichEdit1.Paragraph.Alignment := taCenter;
RichEdit1.Lines.SaveToFile('brief.rtf');
```
