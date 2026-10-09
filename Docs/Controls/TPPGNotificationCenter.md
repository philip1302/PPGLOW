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

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `Position` | `TPPGToastPosition` | `npBottomRight` | Bildschirmecke, in der die Toasts gestapelt werden (auf dem Monitor des Formulars). Werte: `npBottomRight`, `npTopRight`, `npBottomLeft`, `npTopLeft`. |
| `Duration` | `Integer` | `5000` | Anzeigedauer in Millisekunden (0..600000); 0 = bis zum Schließen. Solange die Maus über dem Toast steht, ist die Zeit angehalten. Show kann pro Toast eine eigene Dauer angeben. |
| `MaxVisible` | `Integer` | `3` | Höchstzahl gleichzeitig sichtbarer Toasts (1..20); weitere warten in einer Schlange. |
| `ToastWidth` | `Integer` | `360` | Breite eines Toasts in logischen Pixeln (160..1000). |
| `Preset` | `string` |  | Optik-Vorlage der Toasts ('' = Standard bzw. StyleManager). |
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle für Preset und Farben der Toasts. |
| `Animation` | [TPPGAnimationSettings](types/TPPGAnimationSettings.md) |  | Ein- und Ausblenden der Toasts wie Animation der Controls: Enabled = False schaltet ab, Duration und Easing steuern den Verlauf. Toasts gleiten ein und aus, der Stapel rückt animiert nach (nur, wenn Windows Animationen erlaubt). |
| `RespectQuietHours` | `Boolean` | `True` | True: Läuft eine Vollbild-Anwendung oder Präsentation, warten neue Toasts, bis sie beendet ist. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnAction` | `TPPGToastActionEvent` `(Sender: TObject; Toast: TPPGToast; ActionIndex: Integer)` | Ein Aktions-Button eines Toasts wurde geklickt; ActionIndex = Nummer der Aktion (0-basiert, Reihenfolge wie bei Show). Nutzung: `if ActionIndex = 0 then OeffneDatei(Toast.Tag);` |
| `OnClose` | `TPPGToastCloseEvent` `(Sender: TObject; Toast: TPPGToast; Reason: TPPGToastCloseReason)` | Ein Toast wurde geschlossen; Reason sagt warum (Zeit abgelaufen, Anwender, Aktion, Klick, Code). |
| `OnShow` | `TPPGToastEvent` `(Sender: TObject; Toast: TPPGToast)` | Ein Toast ist erschienen (nach Warteschlange bzw. Ruhezeit). |
| `OnToastClick` | `TPPGToastEvent` `(Sender: TObject; Toast: TPPGToast)` | Der Anwender hat auf die Fläche eines Toasts geklickt (nicht auf Buttons), z. B. um zum Vorgang zu springen. |

Tests: `PPG.Tests.Audit45` (TNamingTests, TStreamingFixTests); `PPG.Tests.Audit8A` (TAudit8AAnimatorTests); `PPG.Tests.Phase7d` (TNotificationTests); `PPG.Tests.Streaming`; `PPG.Tests.Visual` (TVisualTests) (Uebersicht: [Control -> Testunits](Tests.md))

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGNotificationCenter.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
