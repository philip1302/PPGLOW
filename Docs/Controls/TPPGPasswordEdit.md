# TPPGPasswordEdit

Palette **PPGlow** - Unit `PPG.PasswordEdit` - Basis `TPPGCustomPasswordEdit`

**Vorbild:** WinUI PasswordBox

## Unterschiede und Hinweise

- Die Zeichen sind verdeckt (`PasswordChar`, Vorgabe ●).
- Das Auge im Feld deckt auf:
  - `rmPeek`: nur solange gedrückt
  - `rmToggle`: Umschalten
  - `rmHidden`: ohne Auge
- `Revealed` aus Code löst kein Ereignis aus. `OnRevealChange` kommt nur bei Anwenderaktionen.
- Bei aktiver Feststelltaste erscheint eine Plakette im Feld, solange es den Fokus hat (`CapsLockWarning`). Screenreader hören den Hinweis in der Beschreibung.
- Solange das Passwort verdeckt ist, sind Kopieren und Ausschneiden gesperrt (`WM_COPY`/`WM_CUT`, Strg+C, Strg+Einfg).
- Nach dem Aufdecken wird der Rückgängig-Puffer des Edits geleert, damit kein Klartext darin liegt. `Clear` überschreibt den Text im Speicher.
- Screenreader: Zustand „geschützt“ (`STATE_SYSTEM_PROTECTED`), kein Wert.

## Beispiel

```pascal
PPGPasswordEdit1.RevealMode := rmToggle;
if Length(PPGPasswordEdit1.Text) < 8 then
  PPGPasswordEdit1.ValidationState := pvsError;
```

## Verhalten (aus dem Quelltext)

TPPGPasswordEdit - Kennwortfeld (Phase 12b, Vorbild WinUI PasswordBox).

- Zeichen verdeckt (PasswordChar, Vorgabe Punkt U+25CF).
- Auge im Feld: RevealMode rmPeek zeigt nur, solange es gedrueckt ist; rmToggle schaltet um; rmHidden ohne Auge. Revealed aus Code.
- Hinweis bei aktiver Feststelltaste (Plakette im Feld, solange es den Fokus hat; CapsLockWarning).
- Kein Kopieren und Ausschneiden, solange verdeckt (WM_COPY/WM_CUT werden abgefangen, auch Strg+C/Strg+Einfg). Nach dem Aufdecken wird der Rueckgaengig-Puffer des Edits geleert (EM_EMPTYUNDOBUFFER), damit dort kein Klartext liegt. Clear ueberschreibt den Text im Speicher.
- Screenreader: Rolle Text mit STATE_SYSTEM_PROTECTED, kein Wert.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `PasswordChar`, `RevealMode`, `CapsLockWarning`, `TextHint`, `TextHintVisibleOnFocus`, `ValidationState`, `ValidationHint`, `HighContrastSupport`, `Align`, `Anchors`, `AutoSize`, `BiDiMode`, `BorderStyle`, `Color`, `Constraints`, `Enabled`, `Font`, `MaxLength`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ReadOnly`, `ReadOnlyStyle`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Text`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnChange`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnRevealChange`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPasswordEdit.md`.
