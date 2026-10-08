# TPPGLinkLabel

Palette **PPGlow** - Unit `PPG.Labels` - Basis `TPPGCustomLinkLabel`

**Vorbild:** TLinkLabel

## Unterschiede und Hinweise

- Links aus dem Markup (`<a href>`) sind per Tab erreichbar; Enter/Klick → `OnLinkClick`.

## Verhalten (aus dem Quelltext)

TPPGLabel und TPPGLinkLabel (Phase 7a).

TPPGLabel - grafisches Control wie TLabel (kein Fensterhandle), DFM-kompatibel:
- Textfarbe folgt dem Dark Mode (TPPGTheme): die Standardfarben (clWindowText/clBtnText/clBlack) werden im Dunkeln zu TextPrimary, deaktiviert zu TextDisabled. Eigene Farben bleiben.
- Secondary = dezente Farbe (TextSecondary), z.B. fuer Hinweise.
- AllowMarkup: Mini-Markup (fett, kursiv, Farbe, Bilder); Links sind hier nur Darstellung - klickbare Links bietet TPPGLinkLabel.
- Bei aktivem VCL-Style zeichnet die VCL wie bei TLabel (Style-Farben).

TPPGLinkLabel - Fenster-Control mit Fokus fuer Text mit Links (wie TLinkLabel):
- Links per Markup (<a href="...">Text</a>), Hand-Cursor und Hover-Flaeche.
- Tastatur: Pfeile wechseln den Link, Enter/Leertaste loest ihn aus.
- OnLinkClick(Sender, Link, LinkType) wie TLinkLabel.
- Screenreader: jeder Link ist ein Kind mit Rolle Link.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `Images`, `HighContrastSupport`

## Eigenschaften wie in der VCL

`Align`, `Alignment`, `Anchors`, `AutoSize`, `BiDiMode`, `Caption`, `Constraints`, `Enabled`, `Font`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabOrder`, `TabStop`, `Visible`, `Touch`

## Ereignisse

`OnGesture`, `OnClick`, `OnContextPopup`, `OnEnter`, `OnExit`, `OnKeyDown`, `OnKeyPress`, `OnKeyUp`, `OnLinkClick`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGLinkLabel.md`.
