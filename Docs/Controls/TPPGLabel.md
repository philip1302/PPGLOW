# TPPGLabel

Palette **PPGlow** - Unit `PPG.Labels` - Basis `TCustomLabel`

**Vorbild:** TLabel

## Unterschiede und Hinweise

- Grafisches Control (kein Fenster) mit Markup (`AllowMarkup`) und Token-Farben (Dark Mode).
- Ellipse, `ShowAccelChar`, `FocusControl` kommen von `TCustomLabel`.

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

`AllowMarkup`, `Secondary`

## Eigenschaften wie in der VCL

`Align`, `Alignment`, `Anchors`, `AutoSize`, `BiDiMode`, `Caption`, `Color`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `EllipsisPosition`, `Enabled`, `FocusControl`, `Font`, `ParentBiDiMode`, `ParentColor`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowAccelChar`, `ShowHint`, `StyleElements`, `Transparent`, `Layout`, `Visible`, `Touch`, `WordWrap`

## Ereignisse

`OnGesture`, `OnClick`, `OnContextPopup`, `OnDblClick`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnMouseActivate`, `OnMouseDown`, `OnMouseMove`, `OnMouseUp`, `OnMouseEnter`, `OnMouseLeave`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGLabel.md`.
