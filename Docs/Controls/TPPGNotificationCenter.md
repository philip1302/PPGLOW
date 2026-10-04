# TPPGNotificationCenter

Palette **PPGlow** - Unit `PPG.Notifications` - Basis `TComponent`

**Vorbild:** WinUI/Windows-Toasts

## Unterschiede und Hinweise

- PPGlow-eigene Fenster (keine Windows-Benachrichtigungen); neuester Toast an der Ecke, höchstens 3 sichtbar.
- Bei Vollbild/Präsentation warten Toasts (`RespectQuietHours`).
- Im Designer zeigt das Verb „Show test toast“ einen Toast mit den aktuellen Einstellungen.

## Beispiel

```pascal
PPGNotificationCenter1.Show('Gespeichert', 'Die Datei wurde gespeichert.', psSuccess);
```

## Verhalten (aus dem Quelltext)

TPPGNotificationCenter - Benachrichtigungen ("Toasts") der Anwendung (Phase 7d).

- Komponente aufs Formular; Show(Titel, Text, Art, Dauer, Aktionen) zeigt einen Toast: eigenes Fenster ohne Aktivierung (WS_EX_NOACTIVATE, der Fokus bleibt in der Anwendung), gestapelt in einer Ecke des Monitors des Formulars (Position), hoechstens MaxVisible zugleich, weitere warten.
- Ein-/Ausblenden (Deckkraft und Gleiten) und das Nachruecken des Stapels sind animiert; Auto-Ausblenden nach Duration ms, solange die Maus ueber dem Toast steht, ist die Zeit angehalten.
- Schliessen-Knopf, bis zu drei Aktions-Buttons (OnAction), Klick auf den Toast (OnToastClick); OnClose mit Grund.
- Laeuft eine Vollbild-Anwendung bzw. Praesentation (SHQueryUserNotificationState), warten neue Toasts, bis das vorbei ist.
- Kein eigener Timer: alles laeuft ueber den gemeinsamen Animator.
- Screenreader: Rolle Alarm, Meldung EVENT_SYSTEM_ALERT beim Zeigen.

## PPGlow-Eigenschaften

`Position`, `Duration`, `MaxVisible`, `ToastWidth`, `Preset`, `StyleManager`, `Animations`, `RespectQuietHours`

## Ereignisse

`OnAction`, `OnClose`, `OnShow`, `OnToastClick`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGNotificationCenter.md`.
