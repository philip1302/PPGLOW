**Vorbild:** TPageControl / TTabSheet

## Unterschiede und Hinweise

- Seiten (`TPPGTabSheet`) über den Komponenteneditor: „New Page“, „Next/Previous Page“, „Delete Page“.
- Schließen einer Seite blendet standardmäßig nur den Reiter aus (`caHide`).
- Sind alle Reiter ausgeblendet, bleibt die aktive Seite aktiv und die Reiterleiste verschwindet (für die NavigationView).

## Anpassung

- Je TabSheet `TabColor`, `TabTextColor`, `TabFontStyle`; `TabStyles` (Reiter, Hover, aktiv, Leiste, Indikator).
- Wie `TPageControl`: `MultiLine`, `RaggedRight`, `Style`, `OwnerDraw`, `OnDrawTab`.
