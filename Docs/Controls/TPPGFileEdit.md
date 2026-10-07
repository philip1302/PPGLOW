# TPPGFileEdit

Palette **PPGlow** - Unit `PPG.FileEdit` - Basis `TPPGCustomFileEdit`

**Vorbild:** TMS TAdvFileNameEdit / TAdvDirectoryEdit

## Unterschiede und Hinweise

- `Kind`: Datei öffnen, Datei speichern oder Ordner.
- Der Knopf im Feld (oder Alt+Pfeil runter, F4) öffnet ab Vista `TFileOpenDialog`/`TFileSaveDialog`. Davor gibt es `TOpenDialog`/`TSaveDialog`, für Ordner `SHBrowseForFolder`. `Filter` im VCL-Format wird in Dateitypen umgesetzt.
- Dateien aus dem Explorer lassen sich ablegen: Es zählt die erste Datei bzw. der erste Ordner, der zu `Kind` passt.
- Die Autovervollständigung von Pfaden kommt von Windows (`SHAutoComplete`).
- `MustExist`: Eine fehlende Datei bzw. ein fehlender Ordner steht beim Verlassen als Fehler am Feld. Ein leeres Feld ist gültig.
- `OnBeforeDialog` kann den Dialog abbrechen, `OnAfterDialog` den gewählten Namen ändern oder ablehnen.

## Beispiel

```pascal
PPGFileEdit1.Kind := fkOpenFile;
PPGFileEdit1.Filter := 'Dokumente|*.pdf;*.docx|Alle Dateien|*.*';
PPGFileEdit1.MustExist := True;
```

## Verhalten (aus dem Quelltext)

TPPGFileEdit - Feld fuer eine Datei oder einen Ordner (Phase 12c).

- Kind: Datei oeffnen, Datei speichern oder Ordner. Der Knopf im Feld oeffnet ab Vista TFileOpenDialog/TFileSaveDialog (Ordner ueber fdoPickFolders), davor TOpenDialog/TSaveDialog bzw. SHBrowseForFolder (Laufzeitpruefung, XE2 auf XP).
- Ablegen aus dem Explorer (DragAcceptFiles/WM_DROPFILES): die erste Datei bzw. der erste Ordner passend zu Kind.
- Autovervollstaendigung von Pfaden ueber SHAutoComplete auf dem inneren Edit (dynamisch geladen; ohne Shell-Funktion einfach ohne).
- MustExist: fehlende Datei bzw. fehlender Ordner beim Verlassen als ValidationState (kein Dialog). Leeres Feld ist gueltig.
- Ereignisse: OnBeforeDialog (abbrechbar, Dialog vorbereiten), OnAfterDialog (Name pruefen/aendern), OnChange wie beim Edit.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Kind`, `Filter`, `FilterIndex`, `InitialDir`, `DefaultExt`, `DialogTitle`, `MustExist`, `AcceptDrop`, `AutoComplete`, `ShowClearButton`, `TextHint`, `TextHintVisibleOnFocus`, `UseSystemContextMenu`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `Enabled`, `Font`, `MaxLength`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Text`, `Visible`

## Ereignisse

`OnAfterDialog`, `OnBeforeDialog`, `OnChange`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGFileEdit.md`.
