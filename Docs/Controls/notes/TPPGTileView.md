**Vorbild:** keins; ersetzt `TListView` in den Ansichten `vsIcon`/`vsSmallIcon` (für `vsReport` ist `TPPGGrid` gedacht)

## Unterschiede und Hinweise

- Ansichten über `TileStyle`: `tsIcons` (Explorer), `tsTiles` (Symbol links, Titel und Details), `tsCards` (Karten mit Vorschaubild aus `OnGetPicture` und Plakette).
- Einträge in `Items` (wie `TPPGListBox.ItemsEx`) oder virtuell: `OwnerData := True`, `ItemCount`, `OnGetItem`. Auch bei 100 000 Einträgen holt das Control nur die sichtbaren Kacheln.
- `FilterText` filtert und hebt den Begriff hervor; `OnFilterItem` für eigene Regeln. Indizes in Ereignissen und `Selected[]` sind immer Datenindizes, auch bei aktivem Filter.
- Gruppen (`Group` des Eintrags) mit klappbarem Kopf, `GroupCollapsed[...]` im Code.
- Bedienung: Pfeile in zwei Richtungen, Pos1/Ende, Bild auf/ab, Tippsuche, F2 benennt um (`OnRename`), Strg+Mausrad zoomt, Gummiband mit `MultiSelect`.
- Export und Druck: Die Kachelansicht ist eine Tabellenquelle (Text, Detail, Gruppe, Plakette); xlsx, CSV, HTML und `TPPGGridPrinter` funktionieren damit direkt.
- Die API ist bewusst nicht die der `TListView`; `migrate.ps1` stellt deshalb nicht automatisch um, sondern meldet die Stelle.

## Beispiel

```pascal
PPGTileView1.TileStyle := tsCards;
PPGTileView1.OwnerData := True;
PPGTileView1.ItemCount := Length(FProducts);  // Daten über OnGetItem
PPGTileView1.FilterText := PPGSearchEdit1.Text;
```
