**Vorbild:** WinUI/Windows-Toasts

## Unterschiede und Hinweise

- PPGlow-eigene Fenster (keine Windows-Benachrichtigungen); neuester Toast an der Ecke, höchstens 3 sichtbar.
- Bei Vollbild/Präsentation warten Toasts (`RespectQuietHours`).
- Im Designer zeigt das Verb „Show test toast“ einen Toast mit den aktuellen Einstellungen.

## Beispiel

```pascal
PPGNotificationCenter1.Show('Gespeichert', 'Die Datei wurde gespeichert.', psSuccess);
```
