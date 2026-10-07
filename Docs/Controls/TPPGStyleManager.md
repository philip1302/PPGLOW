# TPPGStyleManager

Palette **PPGlow** - Unit `PPG.StyleManager` - Basis `TComponent`

**Vorbild:** TMS TAdvFormStyler

## Unterschiede und Hinweise

- Ein Preset und eine Appearance für alle verbundenen Controls; `ThemeMode` (Hell/Dunkel/System) wirkt auch im Designer.
- `StyleForms` färbt Formulare mit den neutralen Windows-11-Farben (nur zur Laufzeit).
- Verb „Apply preset to form...“ setzt das Preset aller Controls des Formulars.

## Verhalten (aus dem Quelltext)

Zentrales Theme fuer beliebig viele PPGlow-Controls (Observer-Muster).

Lebenszyklus-Regeln:
- Clients werden als TComponent gehalten (NIE als Interface-Referenz: TComponent zaehlt keine Referenzen -> haengende Zeiger).
- FreeNotification in beide Richtungen: wird ein Client oder der Manager freigegeben, raeumt Notification(opRemove) die Referenzen auf.
- Benachrichtigt wird ueber ein kurzlebiges IPPGStyleClient (Supports), dadurch kennt diese Unit keine Control-Klassen (keine Zyklen).

## PPGlow-Eigenschaften

`Preset`, `Appearance`, `Animation`, `ThemeMode`, `StyleForms`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGStyleManager.md`.
