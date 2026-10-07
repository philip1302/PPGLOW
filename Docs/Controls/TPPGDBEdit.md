# TPPGDBEdit

Palette **PPGlow DB** - Unit `PPG.DB.Controls` - Basis `TPPGEdit`

**Vorbild:** TDBEdit

## Unterschiede und Hinweise

- Ungültige Eingabe (z. B. Text in einem Zahlenfeld) zeigt `ValidationState = pvsError` mit der Meldung als Hinweis, behält den Fokus und bricht still ab – kein Dialog.
- Ohne änderbares Feld (Datenmenge/Feld nur lesbar) bleibt das Edit schreibgeschützt.
- Keine Eingabemaske: `EditMask` des Felds wirkt nur über `Field.IsValidChar`.

## Beispiel

```pascal
PPGDBEdit1.DataSource := DataSource1;
PPGDBEdit1.DataField := 'Name';
```

## Verhalten (aus dem Quelltext)

Datenbank-Controls (Phase 9c): TPPGDBEdit, TPPGDBMemo, TPPGDBCheckBox,
TPPGDBComboBox, TPPGDBDatePicker.

Eigenes Package (PPGlowDBR): Anwendungen ohne Datenbank linken kein Data.DB.
Die Controls erben von den PPGlow-Controls und fuegen nur die Anbindung
hinzu (TFieldDataLink) - keine zweite Zeichenlogik.

Ablauf wie bei den VCL-DB-Controls:
- Datensatz wechselt (DataChange): Wert aus dem Feld anzeigen (mit Fokus Field.Text, ohne Field.DisplayText).
- Anwender aendert: zuerst den Datensatz in den Bearbeiten-Modus setzen (TPPGFieldDataLink.EditByUser), dann Modified. Waehrend EditByUser darf DataChange den neuen Wert nicht ueberschreiben (Sperre).
- Verlassen (CM_EXIT): UpdateRecord schreibt ins Feld. Ein ungueltiger Wert setzt ValidationState = pvsError mit der Meldung als ValidationHint, behaelt den Fokus und bricht still ab (kein Dialog).
- Esc waehrend der Bearbeitung: Wert aus dem Feld zuruecksetzen.

Fallstrick (Roadmap): TDataLink-Ereignisse kommen auch, waehrend gezeichnet
wird (berechnete Felder). Die Handler setzen deshalb nur Werte; Zeichnen
passiert immer erst im naechsten Paint.

## PPGlow-Eigenschaften

`DataField`, `DataSource`, `ReadOnly`, `Text`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGDBEdit.md`.
