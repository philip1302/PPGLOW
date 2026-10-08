# TPPGTabControl

Palette **PPGlow** - Unit `PPG.TabControl` - Basis `TPPGCustomTabControl`

**Vorbild:** TTabControl

## Unterschiede und Hinweise

- Strg+Tab wirkt im innersten Reiter-Control (die VCL nimmt das äußerste).
- Pfeiltasten auf den Reitern laufen nicht um.
- `tpLeft`/`tpRight` werden wie oben/unten gezeichnet.
- Überlauf mit Blätterpfeilen, gleitender Unterstrich, Schließen-Knöpfe.

## Anpassung

- `TabStyles`, `MultiLine`, `RaggedRight`, `Style`, `OwnerDraw`, `OnDrawTab` und `OnCustomDrawItem`.

## Verhalten (aus dem Quelltext)

Reiter-Controls der Suite.

TPPGCustomTabs - gemeinsame Basis von TPPGTabControl und TPPGPageControl:
- Reiterleiste (TPPGTabStrip) oben oder unten, darunter bzw. darueber die Seite als Container-Flaeche. Der gewaehlte Reiter haengt mit der Seite zusammen; ModernFlat zeigt zusaetzlich einen gleitenden Unterstrich.
- Maus: Klick waehlt (OnChanging kann abbrechen, danach OnChange), Schliessen-Knopf (ShowCloseButtons), Blaetterpfeile bei Ueberlauf.
- Tastatur: Strg+Tab / Strg+Umschalt+Tab / Strg+Bild auf/ab, wenn der Fokus im Control liegt (das innerste Reiter-Control gewinnt); Links/Rechts/Pos1/Ende, wenn das Control selbst den Fokus hat; Accelerator (&) in den Beschriftungen.
- Designer: Klicks auf die Reiter erreichen das Control (CM_DESIGNHITTEST).
- Barrierefreiheit: Rolle PAGETABLIST mit virtuellen PAGETAB-Kindern.
- Wie bei TPageControl loest das Setzen im Code (TabIndex, ActivePage) kein OnChanging/OnChange aus.

TPPGTabControl - wie TTabControl: Tabs (TStrings) + TabIndex; der Inhalt
wechselt nicht selbst, die Anwendung reagiert in OnChange. Kinder liegen
direkt im Innenbereich.

## PPGlow-Eigenschaften

`Preset`, `StyleManager`, `Appearance`, `Animation`, `ShowCloseButtons`, `HighContrastSupport`, `TabStyles`

## Eigenschaften wie in der VCL

`MultiLine`, `OwnerDraw`, `RaggedRight`, `ScrollOpposite`, `Style`, `Align`, `Anchors`, `BiDiMode`, `Constraints`, `DragCursor`, `DragKind`, `DragMode`, `Enabled`, `Font`, `HotTrack`, `Images`, `Padding`, `ParentBiDiMode`, `ParentFont`, `ParentShowHint`, `PopupMenu`, `ShowHint`, `StyleElements`, `TabHeight`, `TabOrder`, `TabPosition`, `Tabs`, `TabIndex`, `TabStop`, `TabWidth`, `Visible`, `Touch`

## Ereignisse

`OnDrawTab`, `OnCustomDrawItem`, `OnGesture`, `OnChange`, `OnChanging`, `OnClose`, `OnCloseQuery`, `OnContextPopup`, `OnDragDrop`, `OnDragOver`, `OnEndDock`, `OnEndDrag`, `OnEnter`, `OnExit`, `OnGetImageIndex`, `OnMouseDown`, `OnMouseEnter`, `OnMouseLeave`, `OnMouseMove`, `OnMouseUp`, `OnResize`, `OnStartDock`, `OnStartDrag`

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGTabControl.md`.
