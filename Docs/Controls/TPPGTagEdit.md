# TPPGTagEdit

Palette **PPGlow** - Unit `PPG.TagEdit` - Basis `TPPGCustomDropDownField`

**Vorbild:** Empfängerfeld von Outlook, WinUI TokenizingTextBox

## Unterschiede und Hinweise

- Chips (Text mit ×) stehen vor dem Eingabebereich und brechen über mehrere Zeilen um. Mit `AutoSize` wächst die Höhe mit. Das Layout wird nur bei Änderung der Tags, der Breite oder der Schrift neu berechnet.
- Ein Tag entsteht:
  - mit Enter
  - mit einem Zeichen aus `Delimiters` (`;` `,`)
  - beim Verlassen (`AddOnExit`)
  - eingefügtes `a; b; c` ergibt drei Tags
- Rücktaste im leeren Feld markiert zuerst das letzte Tag und löscht es beim zweiten Druck (wie Outlook). Pfeil links/rechts wandert zwischen den Chips, Entf löscht das markierte.
- `Suggestions` erscheinen während des Tippens. Mit `AllowNew = False` sind nur Vorschläge erlaubt. Doppelte sind ausgeschlossen (`AllowDuplicates`, `CaseSensitive`); `MaxTags` begrenzt die Anzahl.
- `OnTagAdding` kann ablehnen oder den Text ändern (z. B. eine E-Mail prüfen). Dazu kommen `OnTagRemoved` und `OnTagClick`. Code (`Tags`, `TagsText`) löst nichts aus.
- Screenreader: Die Chips sind Kinder; die Standardaktion ist Entfernen.

## Beispiel

```pascal
PPGTagEdit1.Suggestions.CommaText := 'Delphi,VCL,Windows';
PPGTagEdit1.TagsText := 'Delphi;VCL';
```

## Verhalten (aus dem Quelltext)

TPPGTagEdit - Stichwoerter als Chips (Phase 12f, Vorbild Outlook-Empfaenger,
WinUI TokenizingTextBox).

- Chips (Text mit x) vor dem Eingabebereich, Umbruch ueber mehrere Zeilen; mit AutoSize waechst die Hoehe mit. Das Layout wird nur bei Aenderung der Tags, der Breite oder der Schrift berechnet (nicht je Tastendruck).
- Ein Tag entsteht mit Enter, mit einem der Delimiters (";" ",") oder beim Verlassen (AddOnExit). Eingefuegtes "a; b; c" ergibt drei Tags.
- Ruecktaste im leeren Feld markiert zuerst das letzte Tag und loescht es beim zweiten Druck (wie Outlook); Pfeil links/rechts wandert zwischen den Chips, Entf loescht das markierte.
- Vorschlaege (Suggestions) im Aufklapp-Fenster waehrend des Tippens; AllowNew = False erlaubt nur Vorschlaege. MaxTags, CaseSensitive, keine Doppelten.
- Ereignisse nur bei Anwenderaktionen: OnTagAdding (abbrechbar, Text aenderbar - z.B. E-Mail pruefen), OnTagRemoved, OnTagClick, OnChange. Tags aus Code (Tags.Add, TagsText) loesen nichts aus.
- Screenreader: Chips als Kinder, Standardaktion Entfernen.

## PPGlow-Eigenschaften

`Tags`, `Suggestions`, `Delimiters`, `Delimiter`, `AllowNew`, `AllowDuplicates`, `CaseSensitive`, `MaxTags`, `AddOnExit`, `Preset`, `StyleManager`, `Appearance`, `Animation`, `TextHint`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ReadOnlyStyle`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnTagAdding`, `OnTagRemoved`, `OnTagClick`, `OnGesture`, `OnChange`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTagEdit.md`.
