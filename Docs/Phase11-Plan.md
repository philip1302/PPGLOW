# Phase 11 – Detailplan: Menüs, Hints, TeachingTip, Dialoge

*Stand 05.10.2026. Teil von `Docs\Roadmap2.md`. **Vom User freigegeben am 05.10.2026 (Empfehlungen übernommen).***

## Warum
Menüs, Tooltips und Meldungsfenster sieht man in jeder Anwendung. Heute stammen sie in PPGlow-Anwendungen von Windows:
- Im Dark Mode erscheinen helle Kontextmenüs.
- Das Kontextmenü der Eingabefelder ist das native Windows-Menü.
- `MessageDlg` zeigt den VCL-Dialog.
- ToolBar und Breadcrumb zeigen ihren Überlauf als natives Menü.

Das ist die sichtbarste Lücke zu TMS (TAdvPopupMenu, TAdvMainMenu, TAdvOfficeHint, TAdvTaskDialog).

## Teilschritte

| Teil | Inhalt | Größe |
|---|---|---|
| 11a | Gemeinsame Basis: Platzierung, Tastatur-Weiterleitung, `IPPGMenuRenderer`/`IPPGHintRenderer`/`IPPGDialogRenderer` | mittel |
| 11b | `TPPGPopupMenu` (auf `TPopupMenu`), Menüfenster mit Untermenüs; ToolBar/Breadcrumb/Grid nutzen es | groß |
| 11c | `TPPGMenuBar` (Hauptmenü als Control auf Basis `TMainMenu`), Alt/F10-Steuerung | groß |
| 11d | Kontextmenü der Felder (Edit, Memo, Combo, Spin …) im Suite-Stil, übersetzt | klein |
| 11e | `TPPGHintManager` + `TPPGHintWindow` (Hints mit Titel, Markup, Bild) | mittel |
| 11f | `TPPGTeachingTip` (WinUI TeachingTip: angeheftete Sprechblase) | mittel |
| 11g | `TPPGTaskDialog`, `PPGMessageDlg`, `PPGInputQuery`, `TPPGWizard` (Schritt-Assistent) | groß |

## 11a – Gemeinsame Basis

**`PPG.Popup.Placement`** (neu, ohne VCL-Controls, testbar):
- `PPGPlacePopup(Anchor, Size, Preferred, MonitorWorkArea, RTL)` liefert das Rechteck und die tatsächliche Seite.
- Seiten: unten, oben, rechts, links; Untermenüs rechts bzw. links und bei RTL gespiegelt.
- Ausweichen, wenn der Platz fehlt; Klemmen an die Arbeitsfläche des Monitors unter dem Anker, nicht des Formulars (C3).
- Wird von ComboBox, DatePicker, Menü, Hint und TeachingTip benutzt. Die vorhandene Logik in `TPPGPopupWindow` zieht hierher um (DRY).

**Tastatur ohne Aktivierung.** Popups dürfen das Formular nicht deaktivieren (Titelleiste bleibt aktiv). Menüs brauchen aber die ganze Tastatur.
- Lösung wie bei Windows-Menüs: ein Message-Hook auf den Thread (`WH_MSGFILTER` bzw. `WH_GETMESSAGE`), solange ein Menü offen ist. Er leitet `WM_KEYDOWN`/`WM_CHAR`/`WM_SYSKEYDOWN` an die oberste offene Menüebene um.
- Gekapselt in `TPPGMenuLoop`. Nur sie kennt den Hook; die Menüfenster bekommen fertige Tasten (SRP).

**Renderer-Interfaces** (je mit Standard in `TPPGRendererBase`, Classic mit Glanz, Fluent11 nach WinUI):
- `IPPGMenuRenderer`: Rahmen und Schatten, Eintrag (normal/hot/deaktiviert), Häkchen/Radio, Trenner, Untermenü-Pfeil, Tastenkürzel-Spalte, Menüleiste, Leisten-Eintrag
- `IPPGHintRenderer`: Fläche, Titel, Trennlinie
- `IPPGDialogRenderer`: Kopfbereich mit Symbol, Befehlslink, Fußzeile, Schritt-Anzeige des Assistenten

## 11b – TPPGPopupMenu

**Entscheidung (Vorschlag): Modell der VCL behalten, Ansicht ersetzen.** `TPPGPopupMenu = class(TPopupMenu)`. Damit bleiben erhalten:
- der Menü-Designer der IDE
- `TMenuItem` mit Actions, `ShortCut`, `ImageIndex`, `Checked`/`RadioItem`/`GroupIndex`, `Default`, `Break`, `Hint` und `OnClick`
- DFMs; `migrate.ps1` ersetzt nur den Klassennamen (C1)

`Popup(X, Y)` zeigt statt `TrackPopupMenu` das eigene Fenster. Bestehende `PopupMenu`-Properties aller Controls funktionieren unverändert.

**Menüfenster (`TPPGMenuWindow` auf `TPPGPopupWindow`):**
- **Spalten:** Bild bzw. Häkchen | Text mit Mnemonic | Tastenkürzel | Pfeil. Spaltenbreiten werden über alle Einträge ermittelt.
- **Untermenüs:**
  - Öffnen nach `SPI_GETMENUSHOWDELAY` oder sofort mit Pfeil rechts.
  - Schließen mit Pfeil links bzw. Esc (nur die Ebene).
  - „Gnadenzone“ (Safety Triangle): Diagonal zur offenen Untermenü-Ebene laufende Maus schließt sie nicht.
- **Lange Menüs:** Blätterpfeile oben/unten, Mausrad. `Break = mbBreak` erzeugt eine neue Spalte.
- **Tastatur:**
  - Pfeile mit Umlauf und Überspringen von Trennern und Deaktivierten
  - Pos1/Ende, Enter/Leertaste
  - Mnemonic: eindeutig = auslösen, mehrfach = reihum markieren (wie Windows)
  - Alt oder F10 schließt alles
- **Auslösen:** Erst alle Menüfenster schließen und den Hook entfernen, **dann** `TMenuItem.Click` per `PostMessage`. Sonst liefe Anwender-Code mit offenem Menü und Hook (Coding-Rules: Zustand vor Ereignissen setzen).
- **Hints der Einträge:** `Application.Hint` und `OnHint` wie bei VCL-Menüs, z. B. für Statusleisten.
- **Animation:** Einblenden mit Deckkraft und Verschiebung über den Animator; aus bei `SPI_GETMENUANIMATION = False` und in Remote-Sitzungen (C10).
- **Barrierefreiheit (C4):**
  - Rollen `ROLE_SYSTEM_MENUPOPUP` und `ROLE_SYSTEM_MENUITEM`.
  - Ereignisse `EVENT_SYSTEM_MENUPOPUPSTART`/`END` und `EVENT_OBJECT_FOCUS` für den hervorgehobenen Eintrag.
  - Ohne diese Ereignisse lesen Narrator und NVDA eigene Menüs nicht vor.
- **Nutzer der Suite:** ToolBar- und Breadcrumb-Überlauf, Grid-Spaltenkopfmenü (Phase 13) und Split-Button-`DropDownMenu` wechseln auf das neue Menü. Ein normales `TPopupMenu` wird weiter nativ gezeigt.

## 11c – TPPGMenuBar

**Entscheidung (Vorschlag): eigenes Control statt Formular-Menü.** `TPPGMenuBar` (Align alTop) mit Property `Menu: TMainMenu`.
- Zur Laufzeit setzt die Leiste `Form.Menu := nil`; zur Entwurfszeit bleibt das Formular-Menü sichtbar.
- Der Nicht-Client-Bereich ist nicht stylbar; die einzigen Alternativen wären undokumentierte uxtheme-Aufrufe (Ordinal 133/135), die bei Windows-Updates brechen.
- Einträge aus `Menu.Items`; Untermenüs über `TPPGMenuWindow`.
- Mehrere Leisten (MDI) und die Menüzusammenführung (`GroupIndex`) wie in der VCL.

**Alt-Steuerung:**
- Alt allein bzw. F10 markiert den ersten Eintrag, Alt+Buchstabe öffnet ihn.
- Eingehängt über einen `Application.OnMessage`-Verteiler mit Kette (`PPG.AppHooks`, neu): Mehrere PPGlow-Komponenten und fremder Code teilen sich den Hook, niemand überschreibt `Application.OnMessage`.
- `WM_SYSKEYDOWN` mit `VK_MENU` wird nur verbraucht, wenn das Formular eine `TPPGMenuBar` hat und kein natives Menü.
- Alt+Leertaste (Systemmenü) bleibt unberührt.

**Unterstreichung der Mnemonics** nach `WM_UPDATEUISTATE` wie bei den übrigen Controls (vorhandener `FUIState`-Cache).

## 11d – Kontextmenü der Felder
- `TPPGCustomField` beantwortet `WM_CONTEXTMENU` des inneren Edits. Ist kein eigenes `PopupMenu` gesetzt, erscheint ein `TPPGPopupMenu` mit Rückgängig, Ausschneiden, Kopieren, Einfügen, Löschen und Alles markieren.
- Die Befehle werden als `EM_UNDO`, `WM_CUT`, `WM_COPY`, `WM_PASTE`, `WM_CLEAR`, `EM_SETSEL` an das Edit geschickt; Einträge sind je nach Zustand (Auswahl, `ReadOnly`, Zwischenablage) aktiv oder grau.
- Texte über `PPGStr` (C9).
- Gleiches für Memo, SpinEdit, ComboBox (Edit-Teil), SearchEdit, DatePicker, TimePicker.
- Schalter `UseSystemContextMenu` je Feld für Anwendungen, die das native Menü wollen.

## 11e – Hints

**`TPPGHintManager`** (nicht sichtbare Komponente, Opt-in):
- Setzt `Vcl.Forms.HintWindowClass := TPPGHintWindow` und stellt beim Freigeben die vorige Klasse wieder her.
- Fallstrick: Die VCL legt ihr Hint-Fenster erst beim ersten Hint an. Ein späterer Wechsel braucht `Application.ShowHint := False; ... True`, damit das Fenster neu erzeugt wird. Der Manager erledigt das.

**`TPPGHintWindow = class(THintWindow)`:**
- Zeichnet über `IPPGHintRenderer`.
- Hint-Text `Titel|Text` wie die VCL (`GetShortHint`/`GetLongHint`), optional mit Markup (`<b>`, Links nur als Anzeige), Bild über `HintImages`.
- Maximale Breite mit Umbruch; DPI des Monitors unter dem Mauszeiger (C3).
- Schatten über `CS_DROPSHADOW`, ohne Layered-Alpha in Remote-Sitzungen (C10).
- Rolle `ROLE_SYSTEM_TOOLTIP`, damit Screenreader ihn vorlesen.

**Ergänzend:**
- `TPPGCustomHint = class(TCustomHint)` für die `CustomHint`-Property einzelner Controls, Vorbild `TBalloonHint` (ab XE2 vorhanden).
- Zeiten aus `Application.HintPause`/`HintHidePause`; nichts selbst nachbauen.

## 11f – TPPGTeachingTip
Sprechblase mit Pfeil, die an ein Control angeheftet ist (WinUI TeachingTip). Grundlage der geführten Tour in Phase 16.
- **Inhalt:** Titel, Untertitel, Text mit Markup und Links, optionales Bild bzw. Symbol aus der Icon-Schrift, bis zu zwei Buttons plus Schließen-Knopf.
- **Anheften:** `Target: TControl` (FreeNotification) und `Placement` (auto/oben/unten/links/rechts). Bewegt oder verkleinert sich das Ziel, folgt die Blase; dafür beobachtet sie das Formular über ein Hilfsobjekt in `WindowProc`, wie `TPPGNavigationView` den Parent.
- **Modi:**
  - light-dismiss: Schließen bei Klick daneben
  - fest: nur über Buttons oder Esc
- **Ereignisse:** `OnActionClick`, `OnClosing` (abbrechbar), `OnClose`. Code-Aufrufe (`Show`, `Hide`) lösen keine Ereignisse aus (Suite-Regel).
- **Tastatur:** Ein fester TeachingTip nimmt den Fokus, Tab wechselt zwischen den Buttons.
- **Screenreader:** Rolle Dialog, `EVENT_SYSTEM_ALERT` beim Zeigen.

## 11g – Dialoge

**Entscheidung (Vorschlag): eigener Dialog statt `TaskDialogIndirect`.** Der Windows-TaskDialog lässt sich weder stylen noch auf Dark Mode umstellen, und unter XE2 auf Windows XP gibt es ihn nicht.

**`TPPGTaskDialog`** (Komponente):
- Properties wie `Vcl.Dialogs.TTaskDialog`, damit DFMs und Code passen (C1): `Caption`, `Title`, `Text`, `ExpandedText`, `FooterText`, `MainIcon`, `Buttons`, `RadioButtons`, `CommonButtons`, `DefaultButton`, `Flags` (u. a. `tfUseCommandLinks`, `tfAllowDialogCancellation`, `tfShowProgressBar`), `VerificationText` und `ModalResult`.
- Zusätzlich Markup im Text sowie ein Bereich für eigene Controls (`ContentControl`).
- Ereignisse `OnButtonClicked`, `OnHyperlinkClicked`, `OnRadioButtonClicked`, `OnVerificationClicked`, `OnExpanded`, `OnTimer` (über den Animator, alle 200 ms wie beim Original).

**Darstellung:** ein echtes Formular (`TForm.CreateNew`) mit PPGlow-Controls (Label, Button, RadioButton, CheckBox, ProgressBar, Expander). Damit gibt es keine zweite Zeichenlogik (DRY), und Barrierefreiheit kommt aus den Controls.

**Funktionen:**
- `PPGMessageDlg(Msg, DlgType, Buttons, HelpCtx)` mit derselben Signatur wie `MessageDlg`.
- `PPGMessageDlgPos`, `PPGShowMessage`, `PPGInputQuery`/`PPGInputBox` mit Prüfung über `OnValidate`.
- `migrate.ps1` bietet das Umstellen der Aufrufe als Option an (nicht automatisch, weil die Aufrufe im Code stehen).

**Assistent `TPPGWizard`:**
- Seiten wie `TPPGPageControl` (`TPPGWizardPage`, DFM).
- Schritt-Anzeige oben oder links (Kreise mit Nummer/Häkchen, verbindende Linie).
- Zurück/Weiter/Fertig/Abbrechen mit `OnCanAdvance(Page, var Allow)` für die Prüfung je Seite; übersprungene Seiten (`PageVisible`).
- Tastatur: Alt+W/Alt+Z (übersetzbar), Enter = Weiter.

## Fallstricke
| Bereich | Fallstrick | Gegenmittel |
|---|---|---|
| Menü | Ein `PostMessage` an das Formular kann eine Nachricht verlieren, wenn das Formular im Klick-Handler zerstört wird | Ziel der Nachricht ist ein eigenes Hilfsfenster der Unit (`AllocateHWnd`), nicht das Formular |
| Menü | `TPopupMenu.Popup` wird teils aus `OnMouseUp` mit aktivem Capture aufgerufen | Capture zuerst freigeben, eigenes Capture beim Menüfenster |
| Menü | Ein Klick in ein anderes Fenster der Anwendung schließt das Menü; der Klick darf dort nicht verloren gehen | wie Windows: schließen und Klick durchlassen; Ausnahme: Klick auf den Auslöser selbst (sonst öffnet er gleich wieder) |
| Menü | Wechsel zu einer anderen Anwendung (Alt+Tab), Sperrbildschirm, Fenster wird minimiert | `WM_ACTIVATEAPP`, `WM_CANCELMODE`, `WM_CAPTURECHANGED` schließen alles |
| Menü | `TMenuItem.OnClick` von Actions mit `OnUpdate` | vor dem Zeigen `Item.InitiateAction` wie die VCL |
| Menü | `OwnerDraw`-Menüs fremder Komponenten (`OnDrawItem`/`OnAdvancedDrawItem`) | werden weiter aufgerufen, in eine Zeichenfläche des Eintrags (Kompatibilität) |
| MenuBar | MDI: Menü des Kindfensters wird in das Hauptmenü gemischt | VCL-`Merge`/`Unmerge` nutzen und bei `CM_MENUCHANGED` neu aufbauen |
| Hints | `HintWindowClass` ist global: fremde Komponenten erben unsere Hints | Opt-in über den Manager, dokumentiert |
| Hints | Hint über einem Popup-Fenster (Combo-Liste) erscheint dahinter | Hint-Fenster `HWND_TOPMOST` nur während des Zeigens |
| Dialoge | Modaler Dialog auf dem falschen Monitor bzw. hinter dem Hauptformular | `PopupParent` = aktives Formular, `PopupMode = pmExplicit`, Monitor des Elternformulars, DPI vor dem Zeigen anwenden |
| Dialoge | Aufruf aus einem Thread | `Assert(MainThreadID = GetCurrentThreadId)` mit klarer Exception statt Hänger |
| Dialoge | Windows-Meldungsfenster können mit Strg+C den Text kopieren; Anwender erwarten das | Strg+C im Dialog kopiert Titel, Text und Buttons im Windows-Format |
| Dialoge | Ton je Art (Fehler/Warnung/Info) | `MessageBeep` mit `MB_ICONHAND` usw. wie Windows |
| alle | XE2 kennt `TTaskDialog`-Flags späterer Versionen nicht | eigener Aufzählungstyp mit gleichen Namen, wo nötig `{$IF}` über `PPG.inc` |

## Anforderungen (Zuordnung zu Roadmap2)
- C1: Menü-Designer und DFM bleiben; `MessageDlg`-Signatur; `TTaskDialog`-Properties.
- C2: Menüs, Hints und Dialoge folgen Preset, Dark Mode und Hochkontrast.
- C3: Platzierung und DPI nach dem Zielmonitor.
- C4: Windows-Menüereignisse, Mnemonics, Strg+C.
- C7: keine neuen Pakete.
- C9: Feldmenü und Dialog-Buttons übersetzt.
- C10: Animationen und Schatten in Remote-Sitzungen aus.

## Tests (`Tests\PPG.Tests.Phase11a`–`g`)
- **Platzierung:** reine Funktionstests (Monitorränder, RTL, Untermenü links/rechts).
- **Menü:**
  - Tastatur (Pfeile, Mnemonic eindeutig/mehrfach, Untermenü, Esc pro Ebene), Maus mit Gnadenzone
  - Auslösen nach dem Schließen (Ereignisreihenfolge geloggt)
  - Actions (`OnUpdate`, Deaktivieren), `OnHint`
  - MSAA-Ereignisse über einen WinEvent-Hook im Test (wie Phase 9b UIA)
- **MenuBar:** Alt/F10/Alt+Buchstabe, MDI-Merge, Formular ohne/mit nativem Menü.
- **Feldmenü:** Zustände der Einträge, Ausführung je Befehl.
- **Hints:** Titel/Text-Trennung, Markup, Breite, Monitor-DPI (simuliert), Manager setzt die Klasse zurück.
- **TeachingTip:** folgt dem Ziel, light-dismiss, Ereignisse nur bei Anwenderaktionen.
- **Dialoge:**
  - `PPGMessageDlg` mit allen `TMsgDlgBtn` und Rückgabewerten
  - Esc nur bei Abbrechen-fähigen Dialogen, Strg+C-Text
  - DFM eines `TTaskDialog` mit `TPPGTaskDialog` laden
  - Assistent: `OnCanAdvance`, übersprungene Seiten
- **Galerie und Streaming** für alle neuen Komponenten; Leak-Lauf.

## Demo
- Seite „Menüs & Dialoge“: Kontextmenü auf einer Karte, Menüleiste über der Seite, Dialog-Knöpfe für jede Art, Assistent.
- Die Hints der ganzen Demo laufen über den Manager.

## Entscheidungen für den User
1. Menüs: VCL-Modell behalten und nur die Darstellung ersetzen (empfohlen), oder eigenes Item-Modell?
2. Hauptmenü als Control (`TPPGMenuBar`, empfohlen) – das native Formular-Menü bleibt dann zur Laufzeit leer.
3. Dialoge als eigene Formulare (empfohlen) statt Windows-TaskDialog.
4. Hints nur per Opt-in über `TPPGHintManager` (empfohlen) oder automatisch, sobald ein PPGlow-Control auf dem Formular liegt.

## Umsetzung (05.10.2026)

| Teil | Units | Ergebnis |
|---|---|---|
| 11a | `PPG.Popup.Placement` (`PPGPlacePopup`, `PPGPlaceTip`), `PPG.AppHooks` (Nachrichten-Verteiler, `PPGWatchControl`), `IPPGMenuRenderer`/`IPPGHintRenderer` in `PPG.Render.Intf` | Tests `PPG.Tests.Phase11a`/`11b` |
| 11b | `PPG.Menus` (`TPPGMenuLoop`, `TPPGMenuWindow`, `TPPGPopupMenu`); ToolBar und Breadcrumb nutzen es für den Überlauf | Tests `PPG.Tests.Phase11a` |
| 11c | `PPG.MenuBar` (`TPPGMenuBar`) | Tests `PPG.Tests.Phase11a` |
| 11d | Bearbeiten-Menü in `PPG.Controls.Field` (alle Felder), `UseSystemContextMenu` | Tests `PPG.Tests.Phase11a` |
| 11e | `PPG.Hints` (`TPPGHintManager`, `TPPGHintWindow`, `TPPGCustomHint`, `TPPGHintContent`) | Tests `PPG.Tests.Phase11b` |
| 11f | `PPG.TeachingTip` | Tests `PPG.Tests.Phase11b` |
| 11g | `PPG.Dialogs` (`TPPGTaskDialog`, `PPGMessageDlg`, `PPGMessageDlgPos`, `PPGShowMessage`, `PPGInputQuery`, `PPGInputBox`), `PPG.Wizard` | Tests `PPG.Tests.Phase11c` |

**Außerdem:**
- Designer: alle sieben Komponenten auf der Palette mit Symbolen; Preset-Auswahl im Objektinspektor. Der Assistent hat einen Seiten-Editor (Neue Seite, Weiter, Zurück, Seite löschen; Klick auf einen Schritt wechselt die Seite). Der TaskDialog hat das Verb „Dialog testen…“.
- 28 neue Texte mit deutscher Übersetzung (Feldmenü, Buttons, Assistent).
- Hilfeseiten `Docs\Controls\notes` für alle neuen Komponenten; Galerien `Menu.png`, `Hint.png`, `TeachingTip.png`, `Dialog.png`, `Wizard.png`.
- `PPGCheckMainThread` (`PPG.Exceptions`) und `PPGAccSetWindowRole`/`PPGAccSetWindowDescription` (`PPG.Accessibility`).
- Demo: Seite 14 „Menüs & Dialoge“ (Menüleiste, Kontextmenü, Hints, TeachingTip-Tour, sechs Dialogarten, Assistent). Die Hints der ganzen Demo laufen über `TPPGHintManager`.

**QS:**
- 757 Tests grün (vorher 706), Win32 und Win64.
- `/leaks` grün (Zuwachs 6 KB).
- Demo-Selbsttest 88/88.
- Alle Pakete und die Demo bauen ohne Warnungen.

**Abweichungen vom Plan:**
- Nachrichten über einen internen `TApplicationEvents` statt `WH_GETMESSAGE`-Hook. Das ist einfacher, ohne globalen Hook und reicht, weil alle Fenster im selben Thread laufen.
- Ein Klick neben ein **Menü** schließt es und wird verbraucht (wie Windows-Menüs). Beim TeachingTip mit Light-Dismiss geht der Klick dagegen durch.
- Owner-Draw-Ereignisse werden unter derselben Bedingung wie bei der VCL aufgerufen (`OwnerDraw` oder `Images`).
- Kein `IPPGDialogRenderer`: Die Dialoge bestehen aus Suite-Controls und zeichnen nichts selbst.
- `TPPGTaskDialog` erbt von `TCustomTaskDialog` statt die Properties nachzubauen. So passen DFM, Collections und Ereignisse ohne eigene Typen, auch unter XE2.
- `OnTimer` läuft über einen `TTimer` (200 ms) statt über den Animator, weil er in der modalen Schleife verlässlicher ist.
- Hint-Bilder (`HintImages`) gibt es nur bei `TPPGCustomHint` (`Images`/`ImageIndex`), nicht beim Manager.
- Beim TeachingTip fehlen das Bild oben (Hero) und Links per Tab.

**Offen (nicht in dieser Phase):**
- MDI-Menüs (`Merge`) in der Menüleiste.
- Kontextmenü im Grid (Kopfzeile, Filter).
- `migrate.ps1` für `TPopupMenu` → `TPPGPopupMenu` und `TTaskDialog` → `TPPGTaskDialog`. Das Skript entfernt heute alle Properties, die die PPGlow-Klasse nicht selbst veröffentlicht; geerbte VCL-Properties wie `AutoPopup` und `Images` gingen dabei verloren. Es muss zuerst die Vererbung kennen.
- Test der MSAA-Ereignisse über einen echten WinEvent-Hook. Getestet ist bisher die Schnittstelle (Rollen, Namen, Kinder, Standardaktion).

**Beim Prüfen gefunden und behoben (jeweils mit Regressionstest):**
- Alt/F10 startete beim Loslassen die Systemmenü-Schleife von Windows; der Testlauf hing.
- `ShowModal` setzt `ModalResult` nach `OnShow` zurück: Ein Dialog, der sofort geschlossen wird (Automatisierung), blieb offen. Behoben durch eine zusätzlich gepostete Nachricht.
- `TPPGWizard` forderte im Konstruktor über `ClientWidth` ein Fensterhandle an („kein übergeordnetes Fenster“).
- Win64: `Power(10, n)` wählte die Single-Überladung, die Achsenschritte bekamen Reste (0,100000001). Das betraf Phase 10 und fiel erst im Win64-Testlauf auf.
