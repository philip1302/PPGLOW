# TPPGPopupMenu

Palette **PPGlow** - Unit `PPG.Menus` - Basis `TPopupMenu`

**Vorbild:** TMS TAdvPopupMenu, Windows-11-Kontextmenü

## Unterschiede und Hinweise

- `TPPGPopupMenu` ist ein `TPopupMenu`: Menü-Designer, Actions, `OnPopup`, `AutoCheck`, `RadioItem`, `Break`, Tastenkürzel und `OwnerDraw` funktionieren wie gewohnt. Ersetzt wird nur die Darstellung.
- Zum Umstellen genügt der Klassenname in DFM und `uses` (bzw. `migrate.ps1`).
- `Popup(X, Y)` ist modal wie bei der VCL: Der Aufruf kehrt erst nach dem Schließen zurück. Der Klick auf einen Eintrag wird erst danach ausgeführt (wie `WM_COMMAND`), damit ein Handler das Formular gefahrlos schließen oder freigeben kann.
- Ein Klick neben das Menü schließt es und wird verbraucht (wie bei Windows).
- `OnDrawItem`/`OnAdvancedDrawItem` werden unter derselben Bedingung wie bei der VCL aufgerufen (`OwnerDraw` oder `Images` gesetzt).
- Felder der Suite (Edit, Memo, ComboBox, …) zeigen ohne eigenes `PopupMenu` ein übersetztes Bearbeiten-Menü in diesem Stil. `UseSystemContextMenu = True` stellt das Windows-Menü wieder her.
- Screenreader: Ereignisse `EVENT_SYSTEM_MENUPOPUPSTART/END`, Einträge als Kinder mit Rolle Menüeintrag.

## Anpassung

- `MenuStyles` (Menü, Hover, Trennlinie, Tastenkürzel) und `OnCustomDrawItem`.

## Beispiel

```pascal
PPGPopupMenu1.Preset := 'Fluent11';
Panel1.PopupMenu := PPGPopupMenu1;   // Rechtsklick oder Umschalt+F10
```

## Verhalten (aus dem Quelltext)

Menues im Stil der Suite (Phase 11b).

Modell bleibt die VCL: TPopupMenu/TMainMenu mit TMenuItem (Menue-Designer,
Actions, ShortCut, ImageIndex, Checked/RadioItem, Default, Break, Hint,
OnClick, DFM). Ersetzt wird nur die Darstellung:

- TPPGMenuWindow: eine Menue-Ebene als Popup ohne Aktivierung (wie die ComboBox-Liste). Spalten Bild/Haken | Text mit Mnemonic | Tastenkuerzel | Pfeil; Trenner, Break-Spalten, Blaettern bei sehr langen Menues.
- TPPGMenuLoop: steuert alle offenen Ebenen. Solange ein Menue offen ist, leitet ein Haken in PPG.AppHooks Tasten und Mausklicks an das Menue (Fokus und Titelleiste bleiben beim Formular, wie bei Windows-Menues). Klick ausserhalb schliesst (und wird verbraucht, wie bei Windows), Deaktivieren der Anwendung schliesst.
- Ausloesen: erst alles schliessen, dann TMenuItem.Click ueber eine gepostete Nachricht - wie die VCL (WM_COMMAND nach TrackPopupMenu). So laeuft Anwender-Code nie mit offenem Menue oder aus einem Menuefenster.
- TPPGPopupMenu = TPopupMenu mit eigener Darstellung: bestehende PopupMenu-Properties, Split-Button-DropDownMenu usw. funktionieren unveraendert. Popup(X, Y) kehrt wie bei der VCL erst nach dem Schliessen zurueck.
- Barrierefreiheit: ROLE_SYSTEM_MENUPOPUP/MENUITEM, EVENT_SYSTEM_MENUPOPUPSTART /END, EVENT_OBJECT_FOCUS fuer den hervorgehobenen Eintrag - nur damit lesen Narrator und NVDA eigene Menues vor.
- Owner-Draw fremder Menues (OnDrawItem/OnAdvancedDrawItem) wird weiter aufgerufen.

## PPGlow-Eigenschaften

Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.

| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |
|---|---|---|---|
| `StyleManager` | `TPPGStyleManager` |  | Zentrale Stilquelle: Preset und Appearance wie bei den Controls. Ohne Manager übernimmt das Menü die Optik des auslösenden Controls. |
| `Preset` | `string` |  | Optik-Vorlage des Menüs, wenn kein StyleManager gesetzt ist; leer = Preset des auslösenden Controls bzw. Standard. |
| `MenuStyles` | [TPPGMenuStyles](types/TPPGMenuStyles.md) |  | Aussehen des Menüs in Bereichen (Fläche, Hover, Trennlinien, Tastenkürzel); clDefault = vom Preset. |

## Ereignisse

| Ereignis | Typ und Parameter | Wann und wozu |
|---|---|---|
| `OnCustomDrawItem` | `TPPGMenuCustomDrawEvent` `(Sender: TObject; Canvas: TCanvas; Item: TMenuItem; const ARect: TRect; State: TPPGItemDrawState; var Style: TPPGDrawStyle; var DefaultDraw: Boolean)` | Vor dem Zeichnen jedes Eintrags: Style (Fill, TextColor, BorderColor, FontStyle) ändern oder mit DefaultDraw := False selbst zeichnen; Item ist der TMenuItem. Nutzung: `if Item = miLoeschen then Style.TextColor := clRed;` |

---
Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\TPPGPopupMenu.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.
