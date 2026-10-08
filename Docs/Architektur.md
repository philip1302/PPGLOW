# PPGlow – Architektur

VCL-Komponentensuite im Glow-Stil (vergleichbar mit TMS GlowButtons). Alle Controls teilen sich Optik, Properties und Bedienlogik. Zielversionen sind Delphi XE2 bis Delphi 13, für Win32 und Win64.

## Schichten

```
 Controls (TPPGButton …)        Zustand, Input, Lebenszyklus
     │
 TPPGCustomControl (Basis)      Hot/Down/Fokus, DPI, Notification, Animation, Paint-Fehlergrenze
     │ fragt                       │ liest
 IPPGRenderer (Strategie)        TPPGAppearance (reine Stil-Daten)
     │ implementiert                ↑ Vorgaben
 Classic / ModernFlat / Fluent11  TPPGStyleManager (zentrales Theme, Observer)
     │ zeichnen über
 IPPGCanvas (GDI+ | GDI-Fallback)
```

| Ordner | Inhalt |
|---|---|
| `Source\Core` | Typen, Exceptions, resourcestrings, Fehler-Handler, Appearance, Animation, Layout, DPI |
| `Source\Render` | Canvas-Abstraktion, GDI+-/GDI-Implementierung, Renderer-Registry, Presets |
| `Source\Theme` | StyleManager, Preset-Composition-Root |
| `Source\Controls` | Basisklasse und Controls |
| `Source\Access` | Barrierefreiheit: MSAA (`PPG.Accessibility`), UI Automation (`PPG.UIA.Intf`, `PPG.UIA`) |
| `Source\DB` | DB-Controls (`PPG.DB.*`, eigenes Paket `PPGlowDBR`) |
| `Source\Design` | Registrierung und Property-Editoren (**nur** im Design-Package) |
| `Source\Editors` | Logik und Dialoge der Komponenten-Editoren (im Design-Package, aber ohne `DesignIntf` und damit testbar) |
| `Source\DesignDB` | Registrierung der DB-Controls (`dclPPGlowDB`) |
| `Lang` | Übersetzungen (`PPGlow.de.txt`), daraus erzeugt `Build\make-lang.ps1` die Unit `PPG.Lang.De` |
| `Packages\<Version>` | `PPGlowR`/`PPGlowDBR` (runtime) und `dclPPGlow`/`dclPPGlowDB` (designtime) je Delphi-Version |
| `Tests` | DUnit-Suite (Konsole, Exit-Code = Anzahl Fehler) |
| `Demo` | Showcase mit NavigationView, Suchfeld (Katalog: Control oder Stichwort → Seite) und 13 Seiten (`/page 0..12`, 12 = Datenbank); `/selftest datei.txt` prüft die Szenarien aller Seiten. `/screenshot datei.png [/page n] [/dropdownimages] [/preset Name] [/theme dark|light|system] [/hover] [/focus] [/fieldfocus] [/dropdown] [/gdi] [/style Name]`, außerdem `/mica [/screencapture datei.png]` (Prototyp) für automatische Sichtprüfung |
| `Build\build.ps1` | Baut alles für alle installierten Delphi-Versionen |

## SOLID

- **S, Single Responsibility:** Die Aufgaben sind getrennt verteilt. Das Control verwaltet Zustand und Input. `TPPGAppearance` hält nur Daten. Der Renderer zeichnet. `TPPGLayoutEngine` rechnet Positionen (als reine Funktion testbar). `TPPGAnimation` interpoliert.
- **O, Open/Closed:** Ein neues Preset ist eine neue Renderer-Klasse plus `TPPGRendererRegistry.RegisterRenderer`. Kein Control wird dafür geändert. Controls erweitern das Zeichnen über die virtuellen Hooks `DoPaintBackground`, `DoPaintContent`, `DoPaintCaption` und `DoPaintOverlay`.
- **L, Liskov:** Jedes Control erfüllt den Basisvertrag (Zustände, Fokus, Appearance, StyleManager). Es gibt keine Overrides, die „nicht unterstützt“ werfen.
- **I, Interface Segregation:** kleine Interfaces: `IPPGCanvas`, `IPPGRenderer`, `IPPGStyleClient`, `IPPGLogger`.
- **D, Dependency Inversion:** Controls kennen nur `IPPGRenderer` und `IPPGCanvas`, nie GDI+ direkt. Tests registrieren eigene Renderer, zum Beispiel einen, der absichtlich wirft.

**Interfaces und TComponent:** `TComponent` zählt keine Referenzen. Interface-Referenzen werden deshalb nur auf `TInterfacedObject` gehalten (Renderer, Canvas, Logger). Komponenten wie StyleManager, ImageList und PopupMenu werden als Objektreferenz mit `FreeNotification` gehalten. Der StyleManager spricht seine Clients nur kurzzeitig über `Supports(..., IPPGStyleClient)` an.

## Exception-Konzept

Alle Exceptions erben von `EPPGError`: `EPPGPropertyError` (mit `PropertyName`), `EPPGRenderError`, `EPPGConfigError`, `EPPGStreamError`. Die Meldungen sind `resourcestring`s in `PPG.Consts`.

| Situation | Verhalten |
|---|---|
| Ungültiger Property-Wert zur Laufzeit | `EPPGPropertyError`. Das Objekt bleibt unverändert, weil erst validiert und dann zugewiesen wird. |
| Ungültiger Wert beim DFM-Laden (`csLoading`) | Der Wert wird geklemmt, eine Warnung geht ins Log, das Formular öffnet trotzdem. |
| Unbekanntes Preset in der DFM | Fallback auf das Default-Preset plus Warnung |
| Exception beim Zeichnen | Wird **nie** weitergeworfen (sonst WM_PAINT-Endlosschleife). Sie wird einmal pro Control gemeldet, dann wird ein Notfall-Zustand gezeichnet. |
| Exception in Timer/Animation | Die betroffene Animation stoppt, die Meldung geht an `Application.HandleException` (wie bei der VCL). |
| Exception beim Theme-Wechsel aus `WM_SETTINGCHANGE` (Hilfsfenster von `PPG.Theme`) | Geht an `Application.HandleException`, das Hilfsfenster bleibt funktionsfähig. |
| Exception im Anwender-Event (`OnClick` …) | Propagiert normal. Der interne Zustand (Pressed, Capture) ist vorher schon zurückgesetzt. |
| Fehler im Fehler-Handler selbst | Wird abgefangen und per `OutputDebugString` ausgegeben. Das ist die einzige bewusst verworfene Exception. |

Anwendungen hängen ihr Logging an zwei Stellen ein: `TPPGErrorHandler.Logger` (`IPPGLogger`) und `TPPGErrorHandler.OnError`. Windows-API-Fehler werden mit dem Namen des Aufrufs gemeldet, zum Beispiel `Windows API call BitBlt failed (error 6: …)`.

## DPI-Strategie

Alle Maße (Rounding, GlowSize, BorderWidth, Spacing) werden **logisch in 96 DPI** gespeichert und erst beim Zeichnen skaliert. Ab Delphi 10.3 geschieht das über `CurrentPPI`, davor über `Screen.PixelsPerInch`. `ChangeScale` muss deshalb nicht überschrieben werden, und es gibt keine Doppelskalierung beim Monitorwechsel.

## Stolpersteine (und wie die Suite sie löst)

| Stolperstein | Lösung |
|---|---|
| `Winapi.GDIPOBJ` startet GDI+ in DLLs nicht (`if not IsLibrary`) | Eigener, verzögerter Startup beim ersten Paint. Kein Shutdown in DllMain. `PPGGdiPlusShutdown` steht für DLL-Hosts bereit. |
| `TControl.WMLButtonUp` ruft `Click` **vor** `MouseUp` auf | Der Pressed-Zustand wird bereits in `WM_LBUTTONUP` vor `inherited` zurückgesetzt (Test `ExceptionInOnClickLeavesNoPressedState`). |
| VCL ruft nach **jeder** Nachricht `FreeMemoryContexts` auf, das gibt Bitmap-DCs frei | `Paint` sendet keine Nachrichten, der UI-Zustand wird gecacht. Wer `PaintTo` in eine `TBitmap` aufruft, sollte `Bitmap.Canvas.Lock` setzen (Test `PaintToBitmapWithCaptionAndFocusCues`). |
| `CM_BUTTONPRESSED` wird von `TSpeedButton` blind auf `TSpeedButton` gecastet | Die Gruppenlogik nutzt eine eigene, registrierte Nachricht (`RegisterWindowMessage`). |
| FreeNotification im Destruktor zu früh entfernt, dadurch hängende Zeiger | Der StyleManager entfernt sie nicht, `TComponent.Destroy` benachrichtigt die Clients (Test `StyleManagerFreedBeforeButton`). |
| `CanFocus` ist `True`, `SetFocus` wirft trotzdem (unsichtbarer Vorfahr) | Zusätzliche Prüfung mit `IsWindowVisible`/`IsWindowEnabled` |
| Doppelklick verschluckt den zweiten Klick | `CS_DBLCLKS` wird beim Button entfernt |
| Unit-Finalisierung läuft **vor** der Zerstörung der Formulare | Der Animator meldet beim Finalisieren alle Animationen ab, Controls prüfen vor der Abmeldung. |
| Viele Controls erschöpfen GDI-/USER-Handles | Ein gemeinsamer Animations-Timer. Offscreen-Puffer pro Paint, keine dauerhaften Handles (Test `NoGdiOrUserHandleLeaks`). |
| `TGPGraphics.GetHDC` überträgt die GDI+-Clipregion nicht auf den DC (Text/Bilder per GDI ignorierten jedes `PushClipRoundRect`) | `GdiBegin` liest die Region vor `GetHDC` und setzt sie als GDI-Clip, `GdiEnd` stellt den DC wieder her (Test `GdiTextRespectsCanvasClip`) |
| `AccessibleChildren` fragt zuerst `IEnumVARIANT` ab, sonst gibt es nur Kind-IDs | `TPPGAccessible` reicht `IEnumVARIANT` und die Kinderzahl an den Standard-Proxy durch, Controls auf Containern sind so als Objekte erreichbar |
| `TWinControl.ClientRect`/`ClientWidth` erzeugen das Fensterhandle (ohne Parent: „Element hat kein übergeordnetes Fenster“) | Layout, das schon im Konstruktor läuft, rechnet mit `Width`/`Height` (Feld-Layout) |
| Das Freigeben der Maus (`MouseCapture := False` in `TControl.WMLButtonUp`) löst `WM_CAPTURECHANGED` aus | Gedrückte Feld-Buttons werden in `WM_LBUTTONUP` **vor** `inherited` ausgewertet, sonst bricht der Capture-Verlust jeden Klick ab |
| `IAccPropServices.SetHwndPropStr` erwartet die Property-GUID **als Wert** (MSAAPROPID) | Parameter als `TGUID` (Wert) deklariert, nicht als Zeiger (Test `InnerEditGetsAccessibleName`) |
| Der GDI-Fallback ignorierte Alpha: halbtransparente Flächen (Hover von Feld-Buttons, gewählter Listeneintrag) wurden deckend schwarz | `TPPGGdiCanvas` blendet bei Alpha < 255 über eine Zwischenebene: Ziel kopieren, deckend zeichnen, mit `AlphaBlend` zurück (Test `GdiCanvasBlendsAlpha`) |
| `LoWord(Message.LParam)` mit negativen Mauskoordinaten (Capture, außerhalb links/oben) löst eine Bereichsprüfung aus | `TWMMouse(Message).XPos`/`YPos` (SmallInt) verwenden (Test `ClickOutsideCancels`) |
| Protected-Member eines **anderen** Objekts aus einer anderen Unit (z. B. `FPopup.Color`) sind nicht erreichbar (E2362) | Setter im Objekt selbst (`ListColor` setzt `Color`) bzw. Cracker-Klasse in der eigenen Unit |
| `CM_CONTROLLISTCHANGE` kommt beim Einfügen **vor** `Insert` (Parent noch nicht gesetzt) | Seitenliste über `CM_CONTROLCHANGE` pflegen (nach dem Einfügen, vor dem Entfernen) |
| `AlignControls` richtet unsichtbare Controls nicht aus | Seiten werden beim Sichtbarwerden ausgerichtet; Tests prüfen die Lage nur an der aktiven Seite |
| `TControl.WMLButtonDown` setzt die Maus-Capture, `WMLButtonUp` gibt sie frei; ein beim Drücken geöffnetes Popup verlöre sie sofort | Bei offener Liste fängt die Combo die Mausnachrichten in `WndProc` ab, bevor `TControl` sie sieht; der gedrückte Pfeil-Button wird per `CancelButtonPress` gelöst |
| `TBits` löscht beim Verkleinern innerhalb desselben Speicherworts die Bits nicht; beim Vergrößern tauchen alte Auswahlen wieder auf | Vor dem Verkleinern die wegfallenden Bits selbst auf `False` setzen (Test `ShrinkingCountDropsSelection`) |
| `DrawParentBackground` zeichnet für jedes Kind den ganzen Parent (300 Kinder = 300 volle Container-Paints) | Schneller Eltern-Hintergrund über `GetChildBackground` (Benchmark „Panel mit 300 Kindern“: 5,3 s → 0,6 s) |
| Messungen mit unsichtbarem Formular sind geschönt (keine echten `SetWindowPos`-Kosten) | Benchmark-Formular sichtbar außerhalb des Bildschirms; Windows-lastige Vorgaben relativ zur VCL |
| Property-Getter direkt auf ein Array-Element (`read FArr[saVert]`) ist nicht erlaubt | Getter-Funktionen |
| `{$IF}` muss in XE2 mit `{$IFEND}` geschlossen werden | Wird immer mit `{$IFEND}` geschlossen. Features stehen zentral in `PPG.inc`. |
| `TImageIndex` ist ab 10.4 in `Vcl.ImgList` deprecated | Alias `TPPGImageIndex` (gleiche RTTI, Bildauswahl im Object Inspector funktioniert) |
| `DesignIntf` in Runtime-Code | Nur in `Source\Design`, nur im Package `dclPPGlow` |
| Streaming-Reihenfolge | `Preset` vor `Appearance`, `GroupIndex` vor `Down`. `Down` wird beim Laden nicht korrigiert. |
| IDE schreibt `.dpk`-Dateien beim Speichern neu (Conditionals gehen verloren) | Ein Package-Ordner je Delphi-Version statt `{$IF}` im `.dpk` |

## Auswahl-Controls (CheckBox, RadioButton, ToggleSwitch)

Alle drei Controls erben von `TPPGCustomCheckControl` (`Source\Controls\PPG.Controls.Check.pas`). Die Basis verwaltet:
- den Zustand (`TCheckBoxState`, also der VCL-Typ)
- die animierte Umschaltung
- das Layout aus Indikator und Beschriftung (`Alignment`, RTL)
- die Anbindung an Actions (`Checked` wird synchronisiert)

Gezeichnet wird über `IPPGIndicatorRenderer`. Presets können Kästchen, Kreis und Schalter überschreiben. Die Farben des „an“-Zustands stehen in `Appearance.Checked`.

| Verhalten | PPGlow | VCL |
|---|---|---|
| `Checked := True` im Code | nur `OnChange` | `OnClick` (bekannte Fehlerquelle) |
| Bedienung (Maus, Leertaste, Accelerator) | `OnChange`, danach `OnClick` | `OnClick` |
| Laden aus der DFM | kein Ereignis | kein Ereignis |
| Exception in `OnChange` | Zustand ist bereits gesetzt, `OnClick` entfällt | – |
| `Click` aufrufen | simuliert einen Benutzerklick (öffentlich) | geschützt |

**Migration von VCL-Controls:** `TCheckBox` lässt sich in der DFM durch `TPPGCheckBox` ersetzen, ebenso `TRadioButton` durch `TPPGRadioButton`. `State = cbChecked`, `AllowGrayed`, `Checked`, `Alignment` und `Caption` bleiben gültig. Achtung bei Code, der sich auf `OnClick` beim Setzen von `Checked` verlässt: Dieser Code muss auf `OnChange` umgestellt werden.

**RadioButton:** Gruppiert wird nach Parent und `GroupIndex`. Die Pfeiltasten wechseln innerhalb der Gruppe (Reihenfolge nach TabOrder, mit Umlauf), weil `WM_GETDLGCODE` `DLGC_WANTARROWS` liefert. Beim Laden wird die Gruppe nicht korrigiert, die DFM gilt.

**Animation:** Es wird nur animiert, wenn das Control sichtbar ist. Beim Aufbau eines Formulars springen die Controls sofort in den Endzustand.

## Wertebereich-Controls (ProgressBar, TrackBar)

Beide erben von `TPPGCustomRangeControl` (`Source\Controls\PPG.Controls.Range.pas`). Die Basis verwaltet `Min`, `Max`, `Position`, `OnChange` und rechnet intern mit `Int64`/`Double`, damit auch `Low(Integer)..High(Integer)` nicht überläuft. Gezeichnet wird über `IPPGRangeRenderer` (Spur, Füllung, Griff); die Geometrie berechnet das Control.

| Verhalten | PPGlow | VCL |
|---|---|---|
| `Position` außerhalb von `Min..Max` | still geklemmt | still geklemmt |
| `Min > Max` zur Laufzeit | `EPPGPropertyError`, Objekt unverändert | `EInvalidOperation` bzw. ignoriert |
| Beide Grenzen ändern | `SetRange(AMin, AMax)` | `SetParams` (geschützt) |
| Laden aus der DFM | Werte roh übernehmen, in `Loaded` prüfen (`Min > Max` → `Max := Min` plus Warnung) | – |
| `OnChange` | bei jeder Änderung von `Position`, nicht beim Laden | ebenso |

**Migration:** Die Typen kommen aus `Vcl.ComCtrls` (`TProgressBarStyle`, `TProgressBarState`, `TTrackBarOrientation`, `TTickMark`, `TTickStyle`). Eine DFM lässt sich deshalb per Suchen/Ersetzen umstellen. `TProgressBar.Smooth` wird nur gelesen (PPGlow zeichnet immer durchgehend). Nicht unterstützt sind beim TrackBar der Auswahlbereich (`SelStart`/`SelEnd`), `PositionToolTip` und manuelle Ticks per `SetTick`.

**ProgressBar:**
- Spur = `Appearance.Normal`, Füllung = `Appearance.Checked`. `State = pbsError`/`pbsPaused` färbt die Füllung rot bzw. gelb, Glanz-Presets behalten dabei ihren Verlauf.
- `Style = pbstMarquee` läuft als Endlosschleife über den gemeinsamen Animator (`TPPGAnimation.StartLoop`), aber nur, solange das Control sichtbar ist (`CM_SHOWINGCHANGED`). Mit abgeschalteten Animationen steht das Segment in der Mitte. Eine Periode dauert `MarqueeInterval × 150` ms.
- Positionswechsel gleiten weich (Dauer aus `Animation`), aber nur sichtbar. `Position` selbst ist sofort gesetzt.
- `ShowText` zeigt `Caption` oder den Prozentwert, zweifarbig (auf der Füllung in deren Textfarbe).

**TrackBar:**
- Ein Klick auf die Schiene setzt den Wert direkt und startet das Ziehen (wie Windows 11). Wer den Griff packt, zieht ohne Sprung.
- Tastatur wie `TTrackBar`: Pfeile = `LineSize`, Bild auf/ab = `PageSize`, Pos1/Ende. Bei RTL sind Links/Rechts gespiegelt. Mausrad: eine Raste = `LineSize`.
- Vertikal steht `Min` oben; `Orientation` tauscht wie bei `TTrackBar` Breite und Höhe.
- Zu dichte Ticks (Abstand unter 3 px) werden ausgelassen, dann zeigt der Regler nur die Enden.
- `AutoSize` passt nur die Dicke an.

## Container (Panel, GroupBox)

Beide erben von `TPPGCustomContainer` (`Source\Controls\PPG.Controls.Container.pas`): `csAcceptsControls` (damit `WS_CLIPCHILDREN` und `WS_EX_CONTROLPARENT`), kein Hover-/Druckzustand, Flächen über `IPPGContainerRenderer.DrawContainer` (höchstens ein dezenter Verlauf, keine Glanzkante).

- **Innenbereich:** `AdjustClientRect` hält Kinder innerhalb von Rahmen und Rundung. Der Versatz `BorderWidth + 0,3 × Rounding` reicht, damit eine Rechteck-Ecke die Rundung nie berührt (r × (1 − 1/√2)). `Padding` kommt wie bei der VCL hinzu. Ändern sich Schrift, Caption, VCL-Style oder Appearance, werden die Kinder neu ausgerichtet (Hook `AppearanceUpdated` der Basis).
- **Hintergrund der Kinder:** Kinder mit `ParentBackground` holen ihren Hintergrund per `WM_PRINTCLIENT` vom Container. Dessen `Paint` zeichnet dann in den DC des Kindes, deshalb gilt auch hier: Paint sendet keine Nachrichten.
- **GroupBox:** Die Beschriftung sitzt als „Plakette“ (Pille) auf der oberen Rahmenlinie, so braucht der Rahmen keine ausgesparte Lücke. Liegt der Fokus auf einem Kind, leuchtet die Plakette in der Fokusfarbe (`HighlightFocus`). Der Zustand wird aus `CM_FOCUSCHANGED` zwischengespeichert. Der Accelerator fokussiert wie bei `TGroupBox` das erste Kind.
- **Panel:** `Caption`, `Alignment`, `VerticalAlignment`, `ShowCaption`, `Padding` und die Bevel-Properties von `TPanel` bleiben gültig. `Color` färbt nur den Hintergrund hinter den Ecken, die Fläche kommt aus `Appearance.Normal`.
- Bei aktivem VCL-Style kommen die Farben aus `scPanel`/`scBorder` und den Panel- bzw. GroupBox-Schriftfarben.
- `AutoSize` gibt es bewusst nicht (die Größe aus den Kindern wäre ein eigenes Regelwerk).

## Eingabefelder (Edit, Memo, SpinEdit)

Alle drei erben von `TPPGCustomField` (`Source\Controls\PPG.Controls.Field.pas`). **Die Texteingabe ist ein natives Edit bzw. Memo ohne Rahmen** (das „innere Edit“). PPGlow zeichnet nur den Rahmen, die Buttons im Feld und den TextHint. IME, Undo, Kontextmenü, Zwischenablage und Screenreader verhalten sich deshalb wie bei `TEdit`.

- **Fokus:** Das Feld selbst ist kein Tabstopp. `SetFocus`, `WM_SETFOCUS` (z. B. `ActiveControl` des Formulars) und Klicks auf den Rahmen geben den Fokus an das innere Edit weiter.
  - `TabStop` des Felds ist `TabStop` des inneren Edits.
  - `Focused` ist auch dann `True`, wenn das innere Edit den Fokus hat.
  - `OnEnter`/`OnExit` liefert die VCL, weil `CM_ENTER`/`CM_EXIT` über alle Eltern laufen.
- **Ereignisse:** Tasten, Maus (Koordinaten in Feld-Koordinaten), `OnClick`, `OnDblClick`, `OnMouseWheel` und `OnChange` des inneren Edits kommen an den Ereignissen des Felds an, `Sender` ist das Feld. `OnChange` feuert wie bei `TEdit` nur bei echten Änderungen und nicht beim Laden.
- **Optik:** Fokus = Akzentlinie unten (ModernFlat, Fluent) bzw. ganzer Rahmen mit Innenschein (Classic), animiert über `IPPGFieldRenderer.DrawField`. Die Fläche ist einfarbig, weil das native Edit keinen Verlauf kann.
- **Farben:** Fläche und Text kommen aus `Color`/`Font` (wie `TEdit`), bei aktivem VCL-Style aus `scEdit`/`sfEditBoxText*` und im Hochkontrastmodus aus `clWindow`/`clWindowText`. Mit VCL-Style färbt der Style-Hook der VCL das innere Edit in denselben Farben. Die Ecken außerhalb der Rundung zeigen die Farbe des Parents (`GetBackgroundColor`).
- **TextHint** zeichnet das Feld selbst nach dem `WM_PAINT` des inneren Edits (Caret dabei verborgen). Gründe: `EM_SETCUEBANNER` braucht aktive Themes, und Memos kennen ihn gar nicht. `TextHintVisibleOnFocus` steuert, ob der Hint bei Fokus sichtbar bleibt (Standard: nein, wie Windows).
- **ValidationState** (`pvsNone`, `pvsValid`, `pvsWarning`, `pvsError`) färbt Rahmen und Fokuslinie in den Signalfarben aus `PPG.Types`. `ValidationHint` erscheint als Tooltip über dem Edit und als Beschreibung für Screenreader.
- **Buttons im Feld** (`GetButtons`, `ButtonClick` …) werden gezeichnet und sind keine Kind-Controls. Beispiele: Löschen (`ShowClearButton`, sichtbar nur bei Text und Hover/Fokus, Platz bleibt reserviert), `LeftButton`/`RightButton` (Bild aus `Images`, optional `DropDownMenu`), Auf/Ab im SpinEdit. Bei RTL wird alles gespiegelt.
- **AutoSize** (Standard bei Edit und SpinEdit): Nur die Höhe folgt der Schrift. Das einzeilige `EDIT` zentriert nicht vertikal, deshalb setzt das Feld das innere Edit selbst in die Mitte.
- **SpinEdit** verhält sich wie `TSpinEdit`:
  - `MinValue = MaxValue` bedeutet keine Grenze.
  - `MinValue > MaxValue` wirft bewusst **nicht**, damit `MinValue := 10; MaxValue := 100` in jeder Reihenfolge funktioniert. Der Text wird nur bei stimmigem Bereich angepasst.
  - Freie Eingabe wird mit Enter und beim Verlassen auf `Value` gesetzt.
  - Gedrückt halten wiederholt nach 400 ms alle 50 ms. Der Takt kommt vom gemeinsamen Animator, es gibt keinen eigenen Timer.
- **Memo:** Die Scrollbalken bleiben nativ (mit VCL-Style färbt sie der Style-Hook). Kein `AutoSize`.
- **Streaming:** Das innere Edit wird nie gespeichert (`GetChildren`), auch nicht, wenn das Feld selbst Root ist (Kopieren im Designer). `Lines` des Memos braucht beim Laden wie bei `TMemo` ein Fenster, also einen Parent.
- **Barrierefreiheit:** Das native Edit bleibt das fokussierte Element (Rolle Text, Wert über den Standard-Proxy, Kennwörter verdeckt). Den Namen setzt das Feld per `IAccPropServices` am inneren Edit: zuerst ein Label mit `FocusControl` auf das Feld, sonst `TextHint`, sonst `Hint`. Das braucht COM; das ist in praktisch jeder VCL-Anwendung (`ComObj`) initialisiert, ohne COM bleibt der Name leer. Das Feld selbst hat die Rolle Gruppierung (SpinEdit: Drehfeld mit Wert).

## Auswahlliste (ComboBox) und Popup

`TPPGComboBox` (`PPG.ComboBox.pas`) erbt von `TPPGCustomField`. Die Liste ist ein eigenes Popup (`PPG.Popup.pas`), keine native ComboBox.

- **Stile:**
  - `csDropDown`: Das innere Edit ist sichtbar, der Text ist frei editierbar. AutoComplete ergänzt per Präfix und markiert den ergänzten Rest; Rücktaste ergänzt nicht.
  - `csDropDownList`: Das innere Edit ist ausgeblendet (`SetInnerVisible`). Das Feld selbst ist dann Tabstopp und Fokusziel und zeichnet den Eintrag bzw. den TextHint.
  - Tippsuche über die Anfangsbuchstaben; derselbe Buchstabe wiederholt blättert durch die Treffer (Puffer 1 s, ohne Timer).
  - `csSimple` wird wie `csDropDown` behandelt, `csOwnerDraw*` wie `csDropDownList`.
- **Popup-Fenster (`TPPGPopupWindow`):**
  - `WS_POPUP`, `WS_EX_TOOLWINDOW`, Besitzer = Formular des Auslösers. Es hat keinen Parent und wird deshalb nicht abgeschnitten.
  - Gezeigt mit `SWP_NOACTIVATE`, `WM_MOUSEACTIVATE` = `MA_NOACTIVATE`. Fokus und Titelleiste bleiben beim Formular.
  - Liegt unter dem Feld, sonst darüber, wenn oben mehr Platz ist (Arbeitsfläche des Monitors). Aufklappen als Höhen-Animation über den gemeinsamen Animator.
  - Abgerundete Ecken per Fensterregion, Schatten per `CS_DROPSHADOW` (folgt der Systemeinstellung).
- **Maus:** Die Combo hält bei offener Liste die Maus (`SetCapture`) und fängt die Mausnachrichten in `WndProc` ab, bevor die VCL sie sieht. Sie rechnet die Koordinaten ins Popup um (`MouseDownAt`/`MouseMoveAt`/`MouseUpAt`).
  - Klick außerhalb oder auf das Feld schließt ohne Übernahme.
  - Loslassen auf einem Eintrag übernimmt. Drücken auf dem Pfeil, Ziehen in die Liste und Loslassen funktioniert also wie bei Windows.
  - Capture-Verlust (Dialog, Alt+Tab), Fokusverlust, `Enabled := False` und Ausblenden schließen ebenfalls ohne Übernahme.
- **Tastatur:**
  - Alt+↓/Alt+↑/F4 klappen auf und zu.
  - Bei offener Liste bewegen ↑/↓/Bild/Pos1/Ende die Hervorhebung; Enter übernimmt, Esc verwirft. Solange die Liste offen ist, gehören Enter und Esc der Combo und nicht Default-/Cancel-Button (`CM_WANTSPECIALKEY`, im inneren Edit über `WantSpecialKey`).
  - Bei geschlossener Liste wählen ↑/↓/Bild direkt.
  - Das Mausrad scrollt nur die offene Liste; geschlossen ändert es die Auswahl bewusst nicht.
- **Ereignisse wie `TComboBox`:**
  - Auswahl durch den Anwender löst `OnClick` und danach `OnSelect` aus. Ist `OnSelect` nicht zugewiesen, kommt stattdessen `OnChange` (wie `TCustomComboBox.Select`).
  - Tippen im Edit löst `OnChange` aus, einmal pro Taste, auch mit AutoComplete.
  - `ItemIndex`/`Text` im Code setzen löst nichts aus.
  - `OnCloseUp` kommt nach der Auswahl; `ItemIndex` ist dort schon aktuell.
  - `Clear` leert wie `TComboBox` Einträge und Text; der Lösch-Button leert nur die Auswahl.
- **Streaming:** `ItemIndex` wird beim Laden gemerkt und erst in `Loaded` angewendet, weil `Items` in der DFM später kommen kann. `ItemHeight` ist eine Mindesthöhe der Zeilen (0 = aus der Schrift), damit alte `TComboBox`-DFMs keine zu engen Zeilen ergeben.
- **Optik:** `IPPGListRenderer`.
  - ModernFlat: Hover-Pille und Akzentbalken am gewählten Eintrag (Fluent).
  - Classic: Glanz-Verlauf.
  - Der Pfeil dreht sich beim Öffnen um 180°.
  - Die Farben kommen aus dem Feld bzw. im VCL-Style aus `scListBox`/Markierung, im Hochkontrastmodus aus `clHighlight`.

## Reiter (TabControl, PageControl)

`TPPGTabControl` (`PPG.TabControl.pas`) und `TPPGPageControl` + `TPPGTabSheet` (`PPG.PageControl.pas`) erben von `TPPGCustomTabs`. Die Reiterleiste ist die Hilfsklasse `TPPGTabStrip` (`PPG.TabStrip.pas`, Komposition, kein Control).

- **TabStrip:**
  - Geometrie: Die Breite ergibt sich aus Text, Bild und Schließen-Knopf, die Höhe aus der Schrift; alternativ fest über `TabWidth`/`TabHeight`.
  - Hit-Test für Reiter, Schließen-Knopf und Blätterpfeile; Hover.
  - Bei Überlauf zwei Blätterpfeile, keine mehrzeiligen Reiter. RTL wird gespiegelt.
  - Der Unterstrich (ModernFlat) gleitet beim Wechsel über den Animator von der alten zur neuen Position.
  - Der gewählte Reiter ragt um die Rahmenbreite in die Seite und verdeckt deren Rahmen: Er hängt mit der Seite zusammen.
- **Wechsel:**
  - Durch den Anwender (Klick, Tastatur, Screenreader): `OnChanging(AllowChange)`, dann der Wechsel, dann `OnChange`.
  - Im Code (`TabIndex`, `ActivePage`) ohne Ereignisse (wie VCL).
- **Tastatur:**
  - Strg+Tab, Strg+Umschalt+Tab, Strg+Bild auf/ab über `CM_DIALOGKEY`. Es reagiert nur das **innerste** Reiter-Control, in dem der Fokus liegt (die VCL nimmt das äußerste).
  - ←/→/Pos1/Ende, wenn das Control selbst fokussiert ist, ohne Umlauf (wie Windows).
  - `&` in Beschriftungen über `CM_DIALOGCHAR`.
- **PageControl:**
  - Jede `TPPGTabSheet`, deren Parent das PageControl ist, ist eine Seite (über `CM_CONTROLCHANGE`, das **nach** dem Einfügen und **vor** dem Entfernen kommt; `CM_CONTROLLISTCHANGE` kommt beim Einfügen zu früh).
  - Nur die aktive Seite ist sichtbar. Die Seiten haben `csNoDesignVisible`, das gilt also auch im Designer.
  - Wird die aktive Seite entfernt oder ihr Reiter ausgeblendet, wird die Nachbarseite aktiv: erst die folgende, sonst die vorige.
  - Lag der Fokus auf der alten Seite, geht er auf das erste Control der neuen.
- **Streaming wie `TPageControl`:**
  - `GetChildren` schreibt die Seiten in Seitenreihenfolge.
  - `Left`/`Top`/`Width`/`Height`/`PageIndex` der Seiten werden nicht gespeichert (`Align = alClient`).
  - `ActivePage` wird per Fixup vor `Loaded` gesetzt.
  - `TPPGTabSheet` wird zur Laufzeit registriert (`RegisterClass`), damit DFMs ohne Formularfeld (Frames, dynamisch geladen) die Klasse finden.
- **Schließen-Knopf** (`ShowCloseButtons`): `OnCloseQuery(…, CanClose)`, dann `OnClose(…, Action)`.
  - PageControl: Standard `caHide` (Reiter ausblenden); `caFree` gibt die Seite frei, `caNone` tut nichts.
  - TabControl: Standard `caFree` (Reiter löschen).
- **Designer:**
  - `CM_DESIGNHITTEST` lässt Klicks auf Reiter und Pfeile zum Control durch; ein Seitenwechsel meldet `Designer.Modified`.
  - Wird ein Control auf einer verdeckten Seite ausgewählt, zeigt `ShowControl` die Seite.
  - Der Komponenteneditor (PageControl und TabSheet) bietet „New Page“, „Next Page“, „Previous Page“, „Delete Page“ und „Reset to preset defaults“.
- **Optik:** `IPPGTabRenderer`.
  - ModernFlat: flache Reiter, Hover-Fläche, Unterstrich in Akzentfarbe.
  - Classic: Glanz-Reiter, nicht gewählte etwas niedriger, ohne Unterstrich.
  - Die Seite ist einfarbig (`PageColor`); TabSheets füllen sich in derselben Farbe.
  - `tpLeft`/`tpRight` werden derzeit wie oben/unten dargestellt.

## Fundament für Daten-Controls (Phase 5)

Gemeinsame Bausteine für ListBox, TreeView und Grid (Phase 6). Jedes Grundproblem ist **einmal** gelöst und getestet:

| Baustein | Unit | Kern |
|---|---|---|
| Scroll-Basis | `PPG.Controls.Scroll` (`TPPGCustomScrollControl`) | Inhalt wird gezeichnet, nie aus Kind-Controls gebaut. Eigene Overlay-Scrollleisten über `IPPGScrollRenderer`, weiches Scrollen, Mausrad mit Rest, horizontal, Auto-Scroll, RTL. Nachfahren überschreiben `PaintViewport` und `ContentMouseDown/Move/Up` |
| Zeilen-Layout | `PPG.RowLayout` (`TPPGRowLayout`) | Feste Höhe in O(1), variable Höhe mit Präfixsummen-Cache und binärer Suche, `Int64`-Positionen |
| Auswahl | `PPG.Selection` (`TPPGSelection`) | Single/Multi/Extended wie Windows-Listen, Anker und Fokus getrennt, `TBits`, Einfügen/Löschen verschiebt die Auswahl, ein `OnChange` pro Aktion |
| Daten | `PPG.Items` (`IPPGItemSource`) | Quellen: Collection (`TPPGItems`, im Designer pflegbar), `TStrings` (DFM wie `TListBox.Items`), virtuell (`OnGetItem`). `OnChanged(Index)`: ≥ 0 = Eintrag, −1 = Struktur |
| Formatierter Text | `PPG.Markup` | `<b> <i> <u> <s> <color> <a href> <img> <br>` und Entities. Wirft nie, Unbekanntes bleibt Text, Cache, Link-Hit-Test |
| Barrierefreiheit | `IPPGAccessibleMultiSelection` | `accSelection` liefert bei mehreren gewählten Kindern einen Enumerator, `accSelect` wird weitergereicht |

**Scrollleisten:**
- `ScrollBarMode = sbmAuto`: Overlay. Ruhend schmal, beim Überfahren breit, nach 1,2 s Ruhe ausgeblendet. Ist in Windows „Bildlaufleisten immer anzeigen“ eingestellt (`HKCU\Control Panel\Accessibility\DynamicScrollbars = 0`), verhält sich `sbmAuto` wie `sbmAlways`.
- `sbmAlways`: Die Leisten sind breit und nehmen Platz weg (`ViewRect`).
- `sbmNever`: keine Leisten.
- Screenreader bekommen keine eigenen Scrollleisten-Kinder; den Bildlauf übernimmt das Anzeigen des fokussierten Eintrags.

**Mausrad:**
- Zeilen pro Schritt kommen aus `SPI_GETWHEELSCROLLLINES`.
- Hochauflösende Deltas (Touchpad, < 120) werden gesammelt und ohne Animation gescrollt.
- Am Rand wird das Rad nicht verbraucht (`False`), damit ein umgebendes Control weiterscrollen kann.

**Schneller Eltern-Hintergrund:** Kinder mit `ParentBackground` auf einem PPGlow-Container füllen ihren Hintergrund selbst, aus der Flächenfarbe bzw. dem Verlauf des Containers (`GetChildBackground`/`ChildSurface`). Sonst würde `DrawParentBackground` für **jedes** Kind den ganzen Container zeichnen. Liegt ein Kind über Rahmen, Rundung oder Panel-Beschriftung, gilt weiter der exakte Weg.

**Leistung** (`Tests\Bench\PPGlowBench.exe`, Release, gemessen am 03.10.2026):

| Messung | Zeit |
|---|---|
| 1000 Buttons erzeugen, zeichnen, freigeben | ca. 1,8 s (Formular sichtbar) |
| 1 000 000 Zeilen fest / variabel: 1M × `RowAt` | < 16 ms / ca. 35 ms |
| Auswahl 1 000 000: alle, Bereich, Löschen | < 20 ms |
| Markup: 10 000 Texte parsen und umbrechen | ca. 1,7 s |
| Scroll-Control 100 000 Zeilen: 300 × scrollen und zeichnen | ca. 0,36 s |
| Panel mit 300 Kindern 10 × zeichnen | 0,6 s (vorher 5,3 s, siehe schneller Eltern-Hintergrund) |
| 200 × Größenänderung mit 100 ausgerichteten Kindern | wie Standard-VCL (Referenzmessung, ca. 7 s; die Zeit steckt in `SetWindowPos`) |

Der Benchmark beendet sich mit Exit-Code = Anzahl überschrittener Vorgaben. Vorgaben, die vor allem Windows misst (Ausrichten), sind relativ zur VCL formuliert.

## Daten-Controls (Phase 6): ListBox, CheckListBox, TreeView, Grid

**Gemeinsame Bausteine:**

| Baustein | Unit | Kern |
|---|---|---|
| Zeilen-Zeichner | `PPG.ItemPainter` (`TPPGItemPainter`) | Inhalt einer Zeile: Bild, Text oder Markup, Detailzeile, Plakette, Gruppen-Überschrift. **Komposition**: ListBox/CheckListBox/TreeView (Scroll-Controls) und die Combo-Liste (Popup-Fenster) haben verschiedene Basen und zeichnen trotzdem gleich |
| Eintrags-Renderer | `IPPGItemRenderer` | Hintergrund (Fluent: Pille mit Akzentbalken; Classic: Glanz), Gruppen-Überschrift, Plakette, Auf-/Zuklapp-Pfeil (drehbar), Baumlinien, Einfügemarke. Standard in `TPPGRendererBase` |
| Listen-Basis | `PPG.Controls.ItemList` (`TPPGCustomItemList`) | Quelle (`IPPGItemSource`), `TPPGRowLayout`, `TPPGSelection`, Hover, Tastatur, Tippsuche, Umsortieren, Rahmen (`FrameInset` der Scroll-Basis), Barrierefreiheit inkl. Mehrfachauswahl. Haken: `ItemIndent`, `PaintItem`, `ItemMouseDown`, `ItemHorzKey`, `CanChangeFocusTo`, `DropTargetAt`/`DoDropAt`, `ReplaceSelection` |
| Canvas | `IPPGCanvas.BeginGdi`/`EndGdi` | Roher DC (Clip übernommen) für Owner-Draw mit `TCanvas` und für schnelles Text-Zeichnen in einem Block |

**Gemeinsame Regeln:**
- Anwender-Aktionen (Maus, Tastatur, Tippsuche, Screenreader) melden sich über `UserSelectionChanged`. Die ListBox löst dann `OnClick` aus, der Baum `OnChange` + `OnClick`. Code löst nichts aus. Ausnahme: `TreeView.Selected := X` löst wie `TTreeView` `OnChange` aus.
- `csClickEvents` ist abgeschaltet, sonst käme beim Loslassen ein zweites `OnClick`.
- Klicks fokussieren nur sichtbare Fenster (`IsWindowVisible`), sonst wirft `SetFocus`.
- Beim Loslassen gibt `TControl.WMLButtonUp` die Maus frei, *bevor* `MouseUp` kommt. Das daraus folgende `WM_CAPTURECHANGED` darf das Ziehen nicht abbrechen (`FInButtonUp`).
- Das Layout wird nicht im Paint neu berechnet, sondern per geposteter Nachricht. Viele Änderungen hintereinander ergeben so einen Durchlauf, und Paint löst kein `OnScroll` aus.
- `ItemHeight` ist eine **Mindesthöhe**, wie bei der Combo, weil `TListBox`-DFMs immer `ItemHeight = 13` speichern.

**ListBox / CheckListBox:**
- Quelle nach Rangfolge: virtueller Stil (`Count` + `OnData`/`OnGetItem`), `ItemsEx` (wenn gefüllt), sonst `Items`. `Items` ist eine eigene `TStringList` (`TPPGListBoxStrings`), die Einfügen und Löschen mit Index meldet; die Auswahl wandert mit. Pro Zeile gibt es eine Hülle (Anwender-Objekt, Kästchen-Zustand, Überschrift), die beim Sortieren und Verschieben mitwandert (`OwnsObjects` gibt sie frei; `Move` ist überschrieben, weil die Basis sie sonst neu anlegt).
- Variable Zeilenhöhen nur bei Gruppen (`ItemsEx`) oder `lbOwnerDrawVariable`, nie im virtuellen Modus. Owner-Draw: `OnDrawItem` zeichnet auf `Canvas`, das ist während des Aufrufs ein `TCanvas` auf dem Puffer; Hintergrund und Auswahl sind vorher im Preset-Stil gezeichnet.
- Umsortieren (`AllowReorder`): Einfügemarke, Auto-Scroll, `OnReorder` kann ablehnen. Sortierte Listen lassen sich nicht verschieben.
- CheckListBox: Kästchen über `IPPGIndicatorRenderer`, `Header[]` als Überschrift (nicht wählbar, wird bei Pfeiltasten übersprungen), `CheckAll`, Zustand je nach Quelle in Hülle, `TPPGItem` oder `OnSetChecked`.

**ComboBox-Ausbau:** `ItemsEx` füllt `Items` mit dem Text ohne Markup (Suche, AutoComplete und Text arbeiten unverändert). Die Popup-Liste arbeitet intern mit Zeilen und nach außen mit Eintrags-Indizes; `SetFilter` setzt die Abbildung Zeile → Eintrag. `FilterMode` (Anfang/enthält) ersetzt beim Tippen AutoComplete; ohne Treffer schließt die Liste. Aufklappen per Pfeil zeigt immer alle Einträge.

**TreeView:**
- Knoten (`TPPGTreeNode`/`TPPGTreeNodes`) mit einer API wie `TTreeNode`. Die sichtbaren Knoten bilden die flache Zeilenliste (Quelle der Listen-Basis). Beim Neuaufbau bleibt die Auswahl an den Knoten; unsichtbar gewordene Auswahl wandert zum sichtbaren Vorfahren (mit `OnChange`). Gelöschte Knoten werden sofort aus der Zeilenliste genommen, damit dort keine hängenden Zeiger bleiben. Ein `Add` unter einem zugeklappten Eltern-Knoten baut keine Zeilen neu auf.
- Lazy Loading: `HasChildren := True` zeigt den Pfeil; `OnExpanding` füllt die Kinder. Liefert es keine, verschwindet der Pfeil. Aufklappen ruft `OnExpanding` auch aus dem Code.
- Kästchen mit drei Zuständen: `AutoCheck` gibt an Kinder weiter und berechnet die Eltern neu, auch beim Hinzufügen, Löschen und Verschieben von Kindern.
- Tastatur wie Windows (←/→, `+`, `-`, `*`, F2). Klick auf den Pfeil klappt um, ohne zu wählen. Doppelklick klappt um.
- Umbenennen über ein natives Edit (`TPPGTreeEdit`, `DLGC_WANTALLKEYS`; `WS_CLIPCHILDREN`): Enter übernimmt, Esc verwirft, Fokusverlust und Scrollen übernehmen.
- Ziehen: oberes/unteres Viertel davor/danach, Mitte hinein (Zeile wird hervorgehoben); nie in die eigenen Kinder (`MoveTo` wirft dann).
- Streaming als lesbare Zeilen (`Items.Nodes`: Ebene|Flags|Bild|Bild gewählt|Text|Detail|Plakette, mit Escape für `|`, `\` und Zeilenumbrüche). Binäre `TTreeView`-Knoten werden nicht gelesen.

**Grid:**
- Ein Fenster, alle Zellen gezeichnet. Feste Zeilen/Spalten bleiben stehen. Zeilen über `TPPGRowLayout` (1 000 000 in O(1)), Spaltenanfänge als Präfix-Array.
- **Sichtbare Zeile ≠ Datenzeile:** Sortieren und Filtern arbeiten auf einem Index-Array (`FRowMap`/`FInvMap`), die Daten bleiben unangetastet. `Row` und `Cells[]` verwenden Datenzeilen, `Selection` sichtbare Zeilen. Der Fokus bleibt beim Umsortieren an der Datenzeile. Sortierung stabil (Merge-Sort), Zahlen numerisch, `OnCompareCells`. Klick auf den Kopf: aufsteigend → absteigend → unsortiert.
- Filterzeile (`ShowFilterRow`): eine zusätzliche feste Zeile; Klick bearbeitet den Filter (enthält, ohne Groß-/Kleinschreibung).
- Editoren sind PPGlow-Felder (`TPPGGridEdit`/`Combo`/`Spin`; `WantSpecialKey` für Enter/Esc/Tab). Kästchen-Spalten schalten per Klick/Leertaste direkt um. `OnValidateCell` lässt den Editor bei ungültigem Wert offen. Scrollen und Fokusverlust übernehmen.
- Zeichnen pro Bereich (Daten, Kopfzeilen, Kopfspalten, Ecke): Hintergrund, Gitterlinien und alle Texte in deckenden GDI-Blöcken; nur die halbtransparente Auswahl läuft über GDI+. Das war 5× schneller als Zelle für Zelle (Benchmark 11,6 s → 2,3 s für 300 Bilder mit 800 × 600).
- DFM-kompatibel zu `TStringGrid` (`ColWidths`/`RowHeights` per `DefineProperties`, `Options` = `TGridOptions`). Breiten und Höhen logisch in 96 DPI.

**Leistung** (Benchmark, Release, 04.10.2026):

| Messung | Zeit |
|---|---|
| ListBox virtuell 1 000 000: 300 × scrollen + zeichnen | ca. 1,2 s |
| TreeView 100 000 Knoten: aufbauen, aufklappen, 50 × zeichnen | ca. 0,13 s |
| Grid 1 000 000 × 20 virtuell: 300 × scrollen + zeichnen | ca. 2,3 s |

## Phase 7: Navigation, Datum/Zeit, Rückmeldung

**Units und Basis:**
- `PPG.Labels`: `TPPGLabel` ist ein `TCustomLabel` (kein Fenster) mit Markup und Token-Farben. `TPPGLinkLabel` ist ein Fenster-Control mit Links aus dem Markup (`TPPGMarkupLayout.LinkCount/LinkBounds/LinkIndexAt`).
- `PPG.Feedback`: `TPPGBadge` (über `IPPGItemRenderer.DrawBadge`), `TPPGProgressRing` (Polylinien-Bogen, Schleife über den Animator, nur wenn sichtbar) und `TPPGInfoBar`.
- `TPPGExpander` ist ein Container. Die Höhe wird zwischen Kopfzeile und `ExpandedHeight` animiert; `GetTabOrderList` blendet zugeklappte Kinder aus. `AdjustClientRect` richtet die Kinder an der aufgeklappten Höhe aus, damit sie beim Animieren nicht wandern.
- `TPPGSplitter` ist ein Fenster-Control mit der Logik von `TSplitter` (`FindResizeControl`, MaxSize, AutoSnap). `rsLine`/`rsPattern` zeichnen eine XOR-Linie auf den Parent.
- `TPPGSearchEdit` und `TPPGTimePicker` bauen auf `TPPGCustomComboBox` auf. Dafür gibt die Combo `ApplyFilter` und `IsQuiet` als protected frei.
- `TPPGCalendar` ist ein einzelnes Control für Monat, Jahr und Dekade. Alle Zelltexte entstehen in **einem** GDI-Block (`BeginGdi`), sonst kosten 42 GDI+-Textaufrufe zu viel Zeit (Benchmark).
- `TPPGDatePicker`: Das Popup (`TPPGCalendarPopup`, ein `TPPGPopupWindow`) enthält einen echten `TPPGCalendar` ohne TabStop. Tasten leitet das Feld weiter. Klicks außerhalb erkennt ein **Maus-Hook des Threads (`WH_MOUSE`), solange das Popup offen ist**; er meldet sie per PostMessage.
- `TPPGNavigationView`: Die Items sind eine verschachtelte `TOwnedCollection` (DFM-fähig). Zeilen und ihre Anfänge werden zwischengespeichert, deshalb geht `RowRect` in O(1) und `RowAt` mit binärer Suche. Der Indikator gleitet per eigener Animation. `pdmAuto` braucht die Größenänderung des Parents; dafür hängt sich `TPPGParentWatcher` in die `WindowProc`-Kette des Parents. Er gehört dem Parent und bleibt bis zu dessen Ende in der Kette, damit sie nie bricht.
- `TPPGToolBar`: Items mit eigenem `TActionLink` (`TPPGToolItemActionLink`); `InitiateAction` aktualisiert sie im Leerlauf.
- `TPPGStatusBar`: `AutoHint` über `ExecuteAction(THintAction)` wie `TStatusBar`. Der Größengriff liefert `HTBOTTOMRIGHT` und schickt bei Klick `SC_SIZE` an das Formular.
- `PPG.Notifications`: Toasts sind `TPPGCustomControl`s ohne Parent, mit `WS_POPUP` und `WS_EX_NOACTIVATE`/`TOPMOST`/`LAYERED` (Deckkraft über `SetLayeredWindowAttributes`) und einer Fensterregion für die runden Ecken. Lebensdauer, Ein- und Ausblenden sowie die Ruhezeit-Abfrage laufen über den Animator. Freigegeben wird per PostMessage an ein verstecktes Fenster des Centers, also nie im Animator-Takt.

**Gemeinsame Regeln:** Code setzt Werte ohne Ereignisse; Anwenderaktionen und Screenreader-Aktionen (immer per PostMessage) lösen sie aus. Farben kommen aus Tokens bzw. `EffectiveAppearance` (Hochkontrast > VCL-Style > Dark Mode). Maße sind logische 96-DPI-Werte.

**Fallen aus Phase 7:**
- `TWinControl.SetBounds` verwirft gleiche Werte **vor** `CanResize`. Ein alLeft-Control erfährt also nichts davon, wenn der Parent nur breiter wird (deshalb der Parent-Watcher).
- `CanAutoSize` wird schon mit der **neuen** Breite gerufen, während `Width` noch die alte ist. Controls, die per AutoSize nur die Höhe bestimmen, melden `AutoSizeWidth = False`; die InfoBar berechnet die Höhe für `NewWidth`.
- Ohne Fensterhandle ruft die VCL nach `SetBounds` kein `Resize` auf, deshalb überschreibt der Expander `SetBounds`.

**Benchmark (Release, Vorgaben):**
| Messung | Vorgabe | gemessen |
|---|---|---|
| Calendar 1000 Monate blättern + zeichnen | 2500 ms | ca. 1,75 s |
| Calendar 20 000 Tage per Tastatur | 1000 ms | ca. 0,64 s |
| NavigationView 1000 Einträge: 300 × scrollen + zeichnen | 2500 ms | ca. 0,69 s |
| NavigationView 1000 Einträge: 1000 × Auswahl + zeichnen | 3000 ms | ca. 2,2 s |

## Barrierefreiheit (Screenreader)

Jedes PPGlow-Control beantwortet `WM_GETOBJECT(OBJID_CLIENT)` mit einem `TPPGAccessible`, einer MSAA-Schnittstelle (`Source\Access\PPG.Accessibility.pas`). Windows reicht sie automatisch an UI Automation weiter. Narrator, NVDA und JAWS lesen damit die folgenden Angaben vor:

| Angabe | Quelle |
|---|---|
| Name | `Caption` ohne `&` (Eingabefelder: Label mit `FocusControl`, sonst `TextHint`, sonst `Hint`) |
| Rolle | Button, Menü-Button, Split-Button, CheckBox, RadioButton, Fortschrittsanzeige, Schieberegler, Gruppierung, Bereich (Panel), Drehfeld (SpinEdit), Kombinationsfeld mit Liste und Listeneinträgen, Reiterliste mit Reitern, Eigenschaftsseite (TabSheet); das native Edit im Feld hat die Rolle Text |
| Zustand | deaktiviert, fokussiert, gedrückt, an, gemischt, hat Popup, schreibgeschützt (ProgressBar), beschäftigt (Marquee) |
| Beschreibung | kurzer Teil von `Hint` |
| Tastenkürzel | `Alt+X` aus dem `&` der Caption |
| Standardaktion | „Press“, „Check“/„Uncheck“, „Select“ |
| Wert | ToggleSwitch: „On“/„Off“, ProgressBar: Prozent, TrackBar: Position |

**Virtuelle Kind-Elemente** ohne eigenes Fenster (Listeneinträge, Reiter) liefert ein Control über das optionale Interface `IPPGAccessibleChildren`. Unterstützt es das Interface, beantwortet `TPPGAccessible` Kind-IDs 1..n über dieses Interface: Name, Rolle, Zustand, Lage, Hit-Test, Navigation, Fokus, Auswahl und Standardaktion. Die Aufzählung (`IEnumVARIANT`) liefert zuerst die Kind-Fenster des Standard-Proxys, dann die virtuellen IDs. Ohne das Interface bleibt alles wie zuvor. Hervorhebung und Wechsel werden per `NotifyAccessibilityChild` (`EVENT_OBJECT_FOCUS`/`SELECTION` mit Kind-ID) gemeldet; Narrator liest so den Listeneintrag bzw. Reiter vor.

Position, Kind-Fenster, Navigation und Hit-Test liefert der Windows-Standard-Proxy. Kind-Fenster sind wichtig für Container: Controls auf einem `TPPGPanel` sind nur so für MSAA-Screenreader erreichbar (Test `AccessibilityExposesChildren`). Wertänderungen melden ProgressBar und TrackBar per `EVENT_OBJECT_VALUECHANGE`. Zustandsänderungen werden per `NotifyWinEvent` gemeldet. Abgeleitete Controls überschreiben `AccRole`, `AccState`, `AccDefaultAction` und `AccValue`.

**Robustheit:**
- Die Methoden werden über COM aus fremden Prozessen aufgerufen. Eine Exception verlässt sie deshalb **nie**, sie liefern stattdessen `E_FAIL` und protokollieren den Fehler. Das ist die einzige weitere dokumentierte Fehlergrenze neben Paint und Timer.
- Nach dem Freigeben oder Neuerzeugen des Fensters antwortet ein noch gehaltenes Objekt mit `CO_E_OBJNOTCONNECTED`, statt abzustürzen.
- `accDoDefaultAction` postet eine Nachricht. Anwender-Code läuft also nie innerhalb des COM-Aufrufs des Screenreaders.

## Design-Tokens (Phase 8.1)

Jedes Preset beschreibt seine Farben, Maße und Bewegungsdauern als **Design-Tokens** (`TPPGTokens` in `Source\Core\PPG.Tokens.pas`), je einmal für Hell und Dunkel.

- **Farben:** Accent, AccentHover, AccentPressed, OnAccent, Background, Layer, Surface (+ Hover/Pressed/Disabled), Stroke, StrokeStrong, StrokeDisabled, TextPrimary/Secondary/Disabled, Danger, Warning, Success, Paused.
- **Maße:** RadiusSmall/Medium/Large, StrokeWidth.
- **Bewegung:** DurationFast/Normal/Slow.

**Ablauf:**
- Renderer implementieren `IPPGThemeRenderer`. `Tokens(Dark)` liefert die Palette, `ApplyThemeColors(Appearance, Dark)` bildet sie auf die Zustandsfarben der Appearance ab und setzt **nur Farben**; Rundung, Rahmen und Glow-Stärken bleiben.
- `ApplyDefaults` = `ApplyThemeColors(Hell)` + Formen des Presets.
- `TPPGRendererBase` liefert die neutrale Windows-11-Palette (`PPGDefaultTokens`) und eine Standard-Abbildung: Ruhe = Surface/Stroke, Hover = SurfaceHover/Accent, Druck = SurfacePressed/AccentPressed, Deaktiviert = SurfaceDisabled/StrokeDisabled/TextDisabled, An = Accent/OnAccent.
- Ein neues Preset muss also nur `Tokens` überschreiben, um Hell und Dunkel zu bekommen. Classic überschreibt zusätzlich die Abbildung, weil sein Glanz vier Verlaufsfarben pro Zustand braucht.
- Die Hell-Farben von ModernFlat und Classic sind **exakt die bisherigen** (Test `LegacyPresetColorsUnchanged`); bestehende DFMs und Screenshots ändern sich nicht.

**Nutzung in Controls:** `TPPGCustomControl.Tokens` liefert die Tokens des aktuellen Presets. Signalfarben kommen daraus: Validierung im Feld aus Danger/Warning/Success, ProgressBar-Fehler und -Pause aus Danger/Paused. Im Dark Mode liefert `Tokens` die dunklen Werte; Felder und Scroll-Controls holen dann auch Flächen- und Textfarben von hier statt aus `clWindow`/`clWindowText`.

**Qualität:** Der Test `TextContrastMeetsWcag` prüft für jedes registrierte Preset in Hell und Dunkel die Kontraste nach WCAG 2.x (`PPGContrastRatio`). Text auf Surface/Layer/Background/Hover muss mindestens 4,5:1 erreichen, Akzent und Signalfarben mindestens 3:1. Ein neues Preset mit zu schwachem Kontrast fällt also im Test durch.

## Preset Fluent11 (Phase 8.2)

`PPG.Render.Fluent11` bildet Windows 11 (WinUI) nach. Grundlage sind die neutralen Windows-11-Tokens (`PPGDefaultTokens`), nur der Akzent kommt aus dem System.

- **Flächen:** kein Glow. Hover und Druck ändern nur die Fläche, der Rand bleibt neutral. Der Rand hat eine dunklere Unterkante (Elevation), dunkle neutrale Flächen stattdessen eine hellere Oberkante. Der Druck-Zustand behält den dunklen Text und bekommt einen kräftigeren Rand, weil er auch der eingerastete Toggle-Button ist (WinUI würde den Text blasser machen).
- **Fokus:** Doppelring **außerhalb** des Körpers, außen dunkel, innen hell (bei 96 DPI 2 + 1 px). Der Abstand ist `GlowSize` (Standard 3), `BodyInset` hält ihn frei. Bei `GlowSize` < 2 liegt der Ring innen auf dem Rand. Den Modus (hell/dunkel) erkennt der Renderer an der Helligkeit der Fokusfarbe; deshalb muss der dunkle Akzent mindestens 7:1 zu Schwarz haben. Der Rand des Körpers bleibt bei Fokus neutral.
- **Kästchen, Kreis, Schalter:** kräftiger Rand (zwischen Fläche und Text), gemischter Zustand als waagerechter Strich, Schalter „aus“ mit grauem Knopf.
- **Akzent:**
  - Reihenfolge: `TPPGFluent11Renderer.AccentOverride` (feste Markenfarbe), sonst `HKCU\…\Explorer\Accent\AccentPalette` (Hell = AccentDark1, Dunkel = AccentLight2, wie Windows selbst), sonst `HKCU\…\DWM\AccentColor`, sonst Windows-Blau.
  - Ungeeignete Farben werden nachgedunkelt bzw. aufgehellt, bis Weiß auf dem hellen Akzent 4,5:1 und Schwarz auf dem dunklen 7:1 erreicht.
  - Der Systemwert wird zwischengespeichert; `PPGRefreshSystemAccent` verwirft ihn (automatisch bei `WM_SETTINGCHANGE` über das Hilfsfenster von `PPG.Theme`, dort aber nur, solange `TPPGTheme.Mode = tmSystem` ist).
- **Symbole:** Haken, Chevrons, Löschen, Schließen und Blätterpfeile kommen aus der Fluent-Symbolschrift (`PPG.IconFont`). Ohne Schrift zeichnet die Basis ihre Linien. Der Aufklapp-Pfeil dreht sich dann nicht, sondern wechselt ab halber Animation auf „oben“; deaktivierte Blätterpfeile bleiben Linien, weil Text keine Transparenz kennt.
  - **Achtung DFM:** Wie alle Preset-Farben landet der Akzent beim Anwenden des Presets in der `Appearance` und damit in der DFM. Ein im Designer abgelegtes Control behält also den Akzent des Entwicklungsrechners. Zur Laufzeit erzeugte Controls und Controls am StyleManager bekommen den Akzent des Anwenders.

## Dark Mode ohne VCL-Style (Phase 8.3)

`TPPGTheme` (`Source\Theme\PPG.Theme.pas`) schaltet **anwendungsweit** zwischen Hell, Dunkel und System um. Standard ist `tmLight`; bestehende Anwendungen ändern sich also nicht.

- **System:** `tmSystem` folgt `HKCU\…\Themes\Personalize\AppsUseLightTheme`. Ein unsichtbares Hilfsfenster (`AllocateHWnd`, nur solange `tmSystem` gilt) empfängt `WM_SETTINGCHANGE("ImmersiveColorSet")`, liest die Einstellung neu und verwirft den Systemakzent. Tests ersetzen die Registry über `TPPGTheme.SystemDarkReader` und schicken die Nachricht an `TPPGTheme.WindowHandle`.
- **Benachrichtigung:** Jedes PPGlow-Control meldet sich im Konstruktor an und im Destruktor ab (`AddClient`/`RemoveClient`, Suche von hinten). Ein Wechsel schickt allen per `Perform` die registrierte Nachricht `PPGThemeChangedMessage`, auch ohne Fensterhandle und auch an offene Popups. Das Control ruft `ThemeChanged` auf (Cache leeren, `AppearanceUpdated`, neu zeichnen). Danach kommt `TPPGTheme.OnChange` für eigene Fremd-Controls. Die Unit kennt keine Control-Klassen; `RemoveClient` ist auch nach ihrer Finalisierung sicher.
- **Farben:** `UseDarkMode` = dunkler Modus und kein VCL-Style und kein Hochkontrast (ab XE3 zusätzlich `seClient`). `EffectiveAppearance` liefert dann eine Kopie der Appearance mit `ApplyThemeColors(…, True)`: Formen bleiben, Farben kommen aus dem Preset. Die gespeicherte Appearance und die DFM bleiben unverändert (Test `DarkKeepsAppearanceAndDfm`). Selbst gesetzte Farben gelten im Dunkeln nicht, wie beim VCL-Style.
- **Felder:** Fläche und Text kommen aus den Tokens (Surface/TextPrimary, deaktiviert SurfaceDisabled/TextDisabled), denn `clWindow` bleibt weiß. Die Textfarbe des inneren Edits setzt das Feld über `TPPGFieldEdit.TextColor` bzw. `TPPGFieldMemo.TextColor` (Antwort auf `CN_CTLCOLOREDIT`/`CN_CTLCOLORSTATIC`). Die Schrift des Felds bleibt unangetastet. Das Memo bekommt dunkle native Scrollleisten (`SetWindowTheme("DarkMode_Explorer")`). Eine offene Combo-Liste wird mit umgefärbt.
- **Kontrast:** Leere Kästchen und Kreise bekommen auf dunklen Flächen mindestens 3:1 Randkontrast (WCAG 1.4.11), indem der Rand Richtung Textfarbe gemischt wird. Helle Flächen bleiben unverändert.
- **Formulare (`StyleForms`):** Formularfarbe = Background, Schriftfarbe = TextPrimary (neutrale Windows-11-Tokens), Titelleiste über `DWMWA_USE_IMMERSIVE_DARK_MODE` (20, auf Windows 10 1809–1909 die 19; ältere Systeme ignorieren das). Gefärbt werden alle `Screen.Forms` beim Wechsel und neue Formulare, sobald ein PPGlow-Control dort sein Fenster erzeugt (`FormNeeded`, auch nach neuem Fensterhandle). Formulare ohne PPGlow-Controls färbt `TPPGTheme.ApplyToForm(Self)`. Formulare im Designer werden nie gefärbt. Beim Ausschalten bekommen die Formulare ihre ursprüngliche Farbe und Schriftfarbe zurück.
- **StyleManager:** `ThemeMode` setzt `TPPGTheme.Mode`, auch im Designer, damit man den Dark Mode dort prüfen kann. Bei mehreren Managern gilt der zuletzt gesetzte. `StyleForms` wirkt nur zur Laufzeit, denn im Designer enthält `Screen.Forms` die Fenster der IDE.
- **Grenzen:** Standard-VCL-Controls (`TEdit`, `TMemo`, `TCheckBox` …) bleiben hell; Labels mit eigener Schrift (`ParentFont = False`) behalten ihre Schriftfarbe. Beides färbt die Anwendung in `TPPGTheme.OnChange` (siehe Demo).

## Bewegungskurven (Phase 8.5)

`TPPGEasing` in `PPG.Animation`: `ekSmooth` (Smoothstep, wie bisher, Standard), `ekDecelerate` (Ease-out-Quart, angenähert an Fluent `cubic-bezier(0, 0, 0, 1)`: schnell starten, weich enden) und `ekLinear`. `AnimateTo(Ziel, Dauer, Kurve)`; `PPGEase` ist als reine Funktion testbar. Aufklappen (Popup), gleitender Unterstrich, weiches Scrollen und Fokuslinie der Felder nutzen `ekDecelerate`; Zustandswechsel (Hover, Druck, Haken) bleiben `ekSmooth`. `RespectSystemSettings` gilt unverändert.

## Fluent-Icons (Phase 8.6)

`PPG.IconFont` zeichnet Symbole aus der Symbolschrift von Windows: „Segoe Fluent Icons“ (Windows 11), sonst „Segoe MDL2 Assets“ (Windows 10). Beide haben dieselben Codepunkte (ChevronDown `E70D`, ChevronUp `E70E`, Left `E76B`, Right `E76C`, Cancel `E711`, CheckMark `E73E`). Die Schrift wird einmal per `EnumFontFamiliesEx` gesucht und zwischengespeichert. `PPGDrawIcon` liefert `False`, wenn keine da ist; der Renderer zeichnet dann seine Linien. Gezeichnet wird über `IPPGCanvas.DrawText`, also mit ClearType wie der übrige Text, aber ohne Drehung und ohne Transparenz. `PPGSetIconFontOverride('-')` erzwingt den Rückfall (Tests).

## Mica-Prototyp (Phase 8.4) – Ergebnis

Demo-Schalter `/mica [/screencapture datei.png]`: VCL-`GlassFrame` über die ganze Fläche (`SheetOfGlass`) plus `DWMWA_SYSTEMBACKDROP_TYPE = 2` (Mica, ab Windows 11 22H2, Build 22621). Geprüft am 04.10.2026 auf Build 26200 mit echten Bildschirmpixeln:

- **Hell: unbrauchbar.** GDI schreibt Alpha 0. Auf der Glasfläche werden Texte und helle Flächen dadurch fast unsichtbar, Labels verschwinden.
- **Dunkel: nur zufällig brauchbar.** Mica scheint durch, aber auch durch alle Flächen: Die Farben werden verfälscht (Seiten violett getönt), und schwarze Pixel sind ganz durchsichtig.
- **Folgerung:** Kommt nicht in die Suite. Tragfähig wäre es nur, wenn jedes Control deckend mit Alpha 255 zeichnet (32-Bit-Puffer mit gesetztem Alpha bzw. `BeginBufferedPaint` + `BufferedPaintSetAlpha`) und Text über `DrawThemeTextEx` läuft. Native Kind-Controls (inneres Edit, Standard-VCL) blieben trotzdem fehlerhaft. Mögliche Alternative: Mica nur in Bereichen ohne Inhalt (Titel-/Leistenbereich), z. B. ein eigener „Backdrop“-Container. Das wäre ein Kandidat für Phase 9.

## Phase 9: Designer, UI Automation, Datenbank, Übersetzung

*Geschrieben ohne Delphi (Cloud-Sitzung), noch nicht kompiliert. Plan und Abweichungen: `Docs\Phase9-Plan.md`.*

**Designer (9a).** Die Editoren haben drei Schichten:
- `PPG.Editors.Logic`: reine Logik, testbar ohne IDE (Preset auf ein Formular anwenden, Appearance auf einer Kopie bearbeiten, Baum-Operationen auf `TPPGNavItems`/`TPPGTreeNodes`).
- `PPG.Editors.Forms`: dünne Dialoge darüber. Sie sind mit `CreateNew` gebaut, brauchen also keine DFM. Ihre Vorschau-Controls haben `StyleElements := []` und keinen StyleManager, damit sie das Formular nicht umfärben.
- `PPG.Reg`: nur noch die Anbindung an `DesignIntf` (Verben, `Designer.Modified`, `ShowCollectionEditor`).

Jedes Verb fängt Exceptions und zeigt sie an. Die Palettensymbole erzeugt `Build\make-icons.ps1` aus Vektorformen.

**UI Automation (9b).** Nur Grid, TreeView, ListBox und CheckListBox haben einen nativen Provider; alle anderen Controls bleiben bei MSAA.
- `PPG.UIA.Intf` deklariert die Interfaces selbst und lädt `UIAutomationCore.dll` dynamisch. Fehlt eine Funktion, bleibt es bei MSAA.
- Ein Control nimmt teil, indem es `IPPGUiaSource` implementiert. Elemente sind nur Kennungen `(Kind, A, B)`, etwa Zeile/Spalte oder eine Knoten-ID, und halten keine Zeiger. Ist das Ziel weg, liefern sie `UIA_E_ELEMENTNOTAVAILABLE`.
- Die Wurzel meldet `ServerSideProvider or UseComThreading`. Damit kommen die Aufrufe im Haupt-Thread an.
- Aktionen von außen (`Invoke`, `Select`, `Expand`, `Toggle`, `SetValue`, `ScrollIntoView`) kommen in eine Warteschlange und laufen erst nach einem `PostMessage`. So läuft Anwender-Code nie im COM-Aufruf.
- `TPPGCustomControl` beantwortet `WM_GETOBJECT` mit `UiaRootObjectId` nur, wenn das Control `IPPGUiaSource` hat. Es trennt den Provider in `ReleaseAccessible` und löst in `NotifyAccessibilityChild` auch die UIA-Ereignisse aus, aber nur, wenn ein Client zuhört.
- `PPGUiaEnabled := False` schaltet alles ab.

**Datenbank (9c).** Die DB-Controls erben von den vorhandenen Controls und bringen nur die Anbindung mit; Zeichnen und Verhalten bleiben gleich.
- `TPPGFieldDataLink` sperrt das Überschreiben, solange der Anwender tippt (`EditByUser`/`Locked`).
- `PPGDBCommitField` schreibt den Wert zurück. Ein ungültiger Wert setzt `ValidationState` am Feld, statt einen Dialog zu zeigen, und der Fokus bleibt im Feld.
- Das DB-Grid (`TPPGCustomDBGrid` auf `TPPGCustomGrid`) zeigt nur den Puffer des `TDataLink` (sichtbare Zeilen). Die Texte werden außerhalb von `Paint` zwischengespeichert; `Paint` fasst die Datenmenge nie an.
- Die Scrollleiste folgt `RecNo`/`RecordCount`, wenn die Datenmenge `IsSequenced` ist, sonst dreistufig (Anfang, Mitte, Ende).
- Das Grid stellt dafür die Hooks `CreateColumns`, `ColumnOf`, `ColumnsChanged`, `RowScrollY`, `ScrollCellsTo` und `GetEditText` bereit.

**Übersetzung (9d).** Alle Texte bleiben `resourcestring` in `PPG.Consts`, gelesen wird aber immer über `PPGStr(@SPPGxxx)`.
- `PPGSetLanguage('de')` schaltet eine Tabelle `PResStringRec → string` aktiv, und alle Fenster zeichnen sich neu.
- Sprach-Units wie `PPG.Lang.De` tragen ihre Tabelle in der `initialization` ein. Sie werden aus `Lang\PPGlow.<sprache>.txt` erzeugt (`make-lang.ps1`).
- Der Regel-Prüfer (Regel LANG) und der Test `PlaceholdersMatchOriginal` sorgen dafür, dass jede Übersetzung vollständig ist und die Platzhalter stimmen.
- So geht es in jeder Edition, ohne Ressourcen-DLL, und ist zur Laufzeit umschaltbar.

**Prüfung ohne Compiler (9e).** `Build\check-rules.ps1` prüft die Coding-Rules und die Projektlisten. `build.ps1` ruft ihn vor jedem Build auf.

## Phase 10: Datenvisualisierung (Sparkline, Gauge, KPI-Kachel, Chart, DB-Chart)

*Plan, Umsetzung und Abweichungen: `Docs\Phase10-Plan.md`.*

**Zeichenschicht.** `IPPGCanvas` bleibt unverändert. Freie Formen kommen über ein eigenes Interface `IPPGShapeCanvas` (`FillPolygon`, `DrawDashedPolyline`), das GDI+ und der GDI-Fallback implementieren. Der GDI-Fallback zerlegt gestrichelte Linien selbst, weil GDI-Stifte Muster nur bei 1 px Breite können.
- Controls benutzen nur die Helfer in `PPG.Render.Shapes`: Bögen, Kreis- und Ringsegmente, `PPGFillPolygon` und `PPGDrawDashedLine`. Ohne `IPPGShapeCanvas` (fremder Canvas) entstehen Umrisse statt Flächen.
- `IPPGChartRenderer` (Balken, Datenpunkt, Tooltip-Fläche) hat eine Standard-Umsetzung in `TPPGRendererBase`. Classic zeichnet glänzende Balken.

**Kern ohne VCL.**
- `PPG.Chart.Scale`: Achsen nach „Nice Numbers“; nur die Schrittweite wird gerundet, nicht vorher der Bereich, sonst wird die Achse oft doppelt so hoch wie die Daten. Datumsachse von Sekunde bis Jahr, Wochen beginnen am Montag.
- `PPG.Chart.Palette`: Serienfarben, Farbe 0 ist der Akzent des Presets. Der Test prüft für jedes Preset hell und dunkel mindestens 3:1 zu `Layer` und `Background`.

**Datenmodell.** `TPPGChartSeries` speichert X, Y, Text und Farbe in getrennten Arrays. Text und Farbe werden nur angelegt, wenn sie gebraucht werden. Dazu kommt ein Startversatz für das Lauffenster (`Append`).
- Die erste Fassung mit `TList<TPPGChartPoint>` kopierte bei jedem Lesen einen Record mit String (`CopyRecord`).
- Layout und Zeichnen lesen über `XAt`/`YAt` ohne Kopie.
- Jede Änderung meldet sich vorher (`ChartBeforeDataChange`: angezeigte Werte merken) und nachher (`ChartDataChanged`) über `IPPGChartHost`.

**Animation.** Aufbau, Übergang nach Datenänderung (nur bei gleicher Punktzahl, höchstens 10 000 Punkte) und Ein-/Ausblenden laufen über den gemeinsamen Animator.
- Wird `Animation` abgeschaltet, springen alle laufenden Animationen ans Ende (`UpdateVisualState`); sonst bliebe das Diagramm im Zwischenstand stehen.
- Ein Export (`SaveToBitmap`) zeigt immer den Endzustand.

**Layout und Treffer.** `Layout` berechnet alles rein aus dem Zustand: Modus, Legende, Achsen, Zeichenfläche. `DoPaint`, `HitTest`, `PointPos` und die Screenreader-Kinder benutzen dieselbe Berechnung.
- Der Tooltip ist Teil des Controls statt eines Popups. So erscheint er im Export und in Screenshots und braucht keine Fensteraktivierung.
- `SaveToPng` speichert über den PNG-Encoder von GDI+ (`PPGSaveBitmapAsPng` in `PPG.Render.GdiPlus`), nicht über `Vcl.Imaging.pngimage`. Sonst müsste `PPGlowR` das Paket `vclimg` verlangen, und Anwendungen mit Laufzeitpaketen müssten es mitliefern.

**Leistung.** Linien werden pro Pixelspalte auf Min/Max verdichtet.
- Für den Abstand der Kategorie-Beschriftungen wird nur eine Stichprobe gemessen.
- Ein Slot kann bei sehr vielen Kategorien schmaler als 1 px sein; der Abstand darf deshalb nicht auf 1 px gerundet werden. Sonst wurden bei 100 000 Kategorien über 2 000 Texte gezeichnet.
- Benchmark: 100 000 Punkte etwa 15 ms je Bild.

**DB-Chart.** Anbinden, Öffnen und Schließen laden sofort; Datenänderungen laden nach `ReloadDelay` über den Animator.
- Ereignisse des eigenen Lesens (`EnableControls`) werden ignoriert.
- Während `Edit`/`Insert` wird nicht gelesen: `First` würde über `CheckBrowseMode` die Eingabe des Anwenders speichern.

## Phase 11: Menüs, Hints, TeachingTip, Dialoge, Assistent

*Plan, Umsetzung und Abweichungen: `Docs\Phase11-Plan.md`.*

**Gemeinsame Bausteine.**
- `PPG.Popup.Placement` (Kern, ohne VCL): `PPGPlacePopup` für Listen, Menüs und Untermenüs (kippen, klemmen, Punkt-Anker klappt nach links) und `PPGPlaceTip` für Sprechblasen (mittig zum Anker, Auto-Reihenfolge oben/unten/links/rechts, Pfeil an der Rundung begrenzt). Beides ist ohne Fenster getestet.
- `PPG.AppHooks`: Tasten und Klicks, die an andere Fenster gehen, sieht man über **einen** internen `TApplicationEvents` statt über `Application.OnMessage`. Der zuletzt angemeldete Haken kommt zuerst (oberstes Menü vor Menüleiste vor TeachingTip); `Handled` beendet die Kette. Dazu kommt `PPGWatchControl`: Ein Hilfsobjekt hängt sich einmal je Control in `WindowProc` ein und gehört dem Control. Hat sich danach jemand anderes eingehängt, bleibt es als Durchreiche stehen, damit dessen Kette nicht bricht.
- Popup-Fenster werden nie aktiviert (`MA_NOACTIVATE`), der Fokus bleibt im Formular. Darum laufen Tastatur und „Klick daneben“ über die App-Haken.
- Renderer: `IPPGMenuRenderer` und `IPPGHintRenderer` (`DrawHint`, `DrawTip` für Fläche mit Pfeil). Die Geometrie bestimmt das Control, der Renderer nur die Form. Standards stehen in `TPPGRendererBase`.

**Menüs.** Das VCL-Modell bleibt (`TMenuItem`, Menü-Designer, Actions); ersetzt wird nur die Darstellung.
- `TPPGMenuLoop` führt die offenen Ebenen (`TPPGMenuWindow`).
- Ein Klick wird erst **nach** dem Schließen ausgeführt, über eine Nachricht an ein eigenes Hilfsfenster (`AllocateHWnd`) statt an das Formular. So darf der Handler das Formular freigeben.
- Alt/F10 schließen erst beim Loslassen der Taste; sonst startet `DefWindowProc` die Systemmenü-Schleife.
- `TPPGPopupMenu.Popup` ist modal wie bei der VCL. Die Menüleiste läuft nicht modal und schaltet bei Mausbewegung zwischen den Menüs um.

**Hints.** `TPPGHintManager` setzt `HintWindowClass` (opt-in, einer zur Zeit) und stellt die vorige Klasse wieder her. `TPPGHintContent` misst und zeichnet Titel, Markup-Text und Bild für `TPPGHintWindow` und `TPPGCustomHint` (DRY). DPI und Schrift richten sich nach dem Monitor unter dem Mauszeiger.

**TeachingTip.** Fenster ist ein `TPPGPopupWindow` mit Region (abgerundete Fläche plus Pfeil, `ApplyRegion` ist dafür virtuell). Er folgt Ziel und Formular über `PPGWatchControl`; die Neuplatzierung wird gesammelt gepostet und nicht in der Nachricht des Ziels ausgeführt. Gibt ein Ereignis den Tipp frei, gibt sich das Fenster nach seinem Handler selbst frei (`CM_RELEASE`).

**Dialoge.** `TPPGTaskDialog` erbt von `TCustomTaskDialog` und überschreibt nur `DoExecute`, deshalb sind Properties, Collections und DFMs die des Originals.
- Das Formular (`TPPGDialogForm`) besteht aus Suite-Controls, eine zweite Zeichenlogik gibt es nicht.
- Private Ergebnisfelder des Vorfahren (`RadioButton`, `Expanded`, `URL`) setzt der Dialog über dessen eigene `DoOn…`-Methoden. Fehlt ein Ereignis, wird kurz ein leerer Handler eingesetzt, weil der Vorfahr sonst nichts merkt.
- Schließen aus `OnShow` heraus wird zusätzlich gepostet, weil `ShowModal` `ModalResult` nach `OnShow` zurücksetzt.
- `PPGMessageDlg`, `PPGInputQuery` usw. laufen über denselben Dialog.

**Assistent.** `TPPGWizard` verwaltet Seiten wie `TPPGPageControl` (`CM_CONTROLCHANGE`, `GetChildren`, `SetChildOrder`, `ShowControl`). Die drei Buttons gehören dem Assistenten und stehen nicht in der DFM. `ClientWidth` wird vor dem Fensterhandle nicht benutzt, weil `TWinControl.GetClientRect` sonst eines anfordert.

## Phase 12: Eingabe-Erweiterungen

*Plan, Umsetzung und Abweichungen: `Docs\Phase12-Plan.md`.*

**Feld-Basis.**
- `IPPGFieldInner`: Jedes innere Edit, auch ein `TCustomMaskEdit`-Nachfahre, bekommt Textfarbe und dunkle Scrollleisten über diese Schnittstelle. Die Farbroutine steht nur einmal da (`PPGFieldCtlColor`); Sonderfälle nach Klasse gibt es nicht mehr.
- `IPPGFieldValue` (`FieldIsNull`, `FieldClear`, `GetFieldValue`, `SetFieldValue`): typisierte Felder bieten ihren Wert so an. `TPPGDBValueBinding` bindet jedes solche Feld an ein Datenbankfeld, eine Anbindung statt einer je Feldtyp. Die Zell-Editoren des Grids (Phase 13) sollen dieselbe Schnittstelle nutzen.
- `SetTextSilent` setzt den Text ohne `OnChange` (Anzeige-/Bearbeitungsformat, Werte aus Code).
- `AdjustInnerBounds` verschiebt das innere Edit, z. B. hinter Chips.
- Felder folgen mit `AutoSize` nur in der Höhe (`AutoSizeWidth = False`).

**Kern ohne VCL.**
- `PPG.NumberFormat`: Zahlen tolerant lesen (Gebietsschema, Tausender, Währung, Prozent, Schweizer Apostroph, Buchhaltungsklammern). Ergebnis ist ein invarianter Text, den `TryStrToCurr` exakt liest. Dazu Ausdrücke rechnen, Anzeige/Bearbeitung formatieren und die Einfügemarke nach Ziffern umrechnen.
- `PPG.ColorSpace`: HSV ↔ RGB, Hex.

**Aufklapp-Basis.** `TPPGCustomDropDownField` übernimmt das Verhalten der ComboBox:
- Das Popup wird nie aktiviert; das Feld hält per `SetCapture` die Maus und reicht sie in Popup-Koordinaten weiter.
- Tastatur: Alt+Pfeil/F4 klappen auf und zu, Enter/Esc gehören bei offenem Popup dem Feld.
- Fokus-, Capture-, Enabled- und Visible-Verlust schließen das Popup.
- Barrierefreiheit: Rolle ComboBox, auf-/zugeklappt.

Das Popup (`TPPGDropPopup`) antwortet auf Maus und Tasten mit einer Aktion (`pdaKeepOpen`, `pdaAccept`, `pdaCancel`).

`TPPGRowPopup` ist die Zeilenliste dazu: Bildlauf mit Daumen, optionale Kopf- und Filterzeile. Getippte Zeichen kommen über die Tastatur des Felds, deshalb braucht auch eine Filter- oder Hex-Eingabe keinen Fokus im Popup.

**Rundung von Geld.** `Round`/`RoundTo` der RTL runden zur geraden Ziffer. `TPPGNumberEdit` rundet `Currency` deshalb kaufmännisch über die Ganzzahl (`Currency` = Int64 · 10⁻⁴), `Double` über `SimpleRoundTo`.

## Phase 13: Grid-Profi

*Plan, Umsetzung und Abweichungen: `Docs\Phase13-Plan.md`.*

**Schichten.** `PPG.Grid` ist nur noch das Control (Eingabe, Scrollen, Layout) und verbindet:
- `PPG.Grid.Columns`: Spalten und Bänder. Die Spalten kennen ihr Grid nicht; Änderungen melden sie über `IPPGGridColumnsHost` an den Owner (Grid, DB-Grid).
- `PPG.Grid.View`: Ansicht als Kette von Stufen hinter `IPPGGridViewStage` (Filter → Sortieren → Gruppieren). Die Stufen arbeiten auf einem Index-Array und fragen „passt?“, „kleiner?“ und „Gruppenschlüssel?“ beim Host (`IPPGGridViewHost`). Ohne aktive Stufe ist die Ansicht die Identität (kein Array).
- `PPG.Grid.Data`: `IPPGTableSource` (Tabelle, wie Druck und Export sie sehen), `IPPGGridPrintSource` (Darstellung für Druck/HTML), `IPPGTableExport` (Summen, Verbindungen, Gliederung für xlsx), `TPPGCellStore` (Cells[]), `TPPGAggregateAcc`.
- `PPG.Grid.Paint`: `TPPGCellPainter` sammelt Texte und gibt sie in einem GDI-Block aus; Kästchen, Sortierpfeil und Gruppenpfeil über `IPPGGridCellRenderer` (ein Preset kann es selbst umsetzen).
- `PPG.Grid.Edit`: Editor-Registry je `TPPGGridEditorKind`; das Grid spricht Editoren nur über `IPPGGridCellEditor` an, Felder aus Phase 12 funktionieren über `IPPGFieldValue`.
- `PPG.Grid.CellKinds`: Zellarten (`IPPGCellKind`: zeichnen, Klick, Taste, Mauszeiger, Screenreader-Text), registrierbar.
- `PPG.Grid.Styles`: bedingte Formate, vorab kompiliert; Statistiken (Min/Max/N-ter Wert) entstehen mit den Summen, nicht beim Zeichnen.
- `PPG.Grid.Print`, `PPG.Xlsx`, `PPG.Grid.Export`: Druck und Export sehen nur die Schnittstellen aus `PPG.Grid.Data`, nie das Control. Grid, DB-Grid und eigene Quellen drucken und exportieren deshalb gleich.
- **xlsx mit Optik (08.10.2026):** `IPPGTableLook` (`PPG.Grid.Data`) liefert die helle Darstellung: `ExportLook` (Schrift, Kopf-, Gruppen- und Summenfarben, Gitterlinien, Zeilenhöhe), `ExportColumnLook` (Zellart, Kopfstil, Summenformat, Datenbalken/Symbolsatz), `ExportCellStyle` (Zebra → Spaltenstil → bedingte Formate → `OnGetCellStyle`, wie beim Zeichnen) und `ExportBands`. Das DB-Grid überschreibt nur `TableDataCol`/`TableStyleRow` (ohne Indikator, Satznummer) und erkennt Boolean-Felder als Kästchen. `TPPGXlsxWriter` legt jede Schrift/Fläche/Rahmen/Kombination nur einmal an (höchstens 60 000 Zellformate, danach Spaltenformat). Datenbalken, Fortschritt und Symbolsätze sind native Excel-Regeln, Kästchen sind 1/0 mit Zahlenformat ☑/☐, Sterne einfacher Text in Segoe UI Symbol (Rich-Text-Läufe stellt OpenOffice falsch dar). Summen als `SUBTOTAL(9,…)` statt 109 (OpenOffice kennt 101–111 nicht). `Styled := False` schreibt wie früher nur Werte. Nebenbei: `PPGTableValueOf` liest Zahlen mit Tausendertrennern (`30.082,00`) streng als Zahl, vorher landeten sie als Text in Excel.
- **Druck/PDF und HTML mit Optik (Phase 17):** `PPG.Grid.Look` bündelt, was xlsx, Druck und HTML gemeinsam brauchen: `TPPGTableLines` (Druckzeilen aus der Gliederung plus Summe; ohne Gliederung ist Zeile I = Tabellenzeile I, nichts wird vorab gelesen), Bandebenen, Kästchen-/Sterne-Text, `PPGResolveCellLook`. `IPPGTableLook.ExportFooterText` liefert den Summentext wie am Bildschirm (nur mit `ShowFooter`). `TPPGGridPrinter.UseGridLook` (Vorgabe True): Kopf mit Bändern, Spalten-/Zebra-Stile, bedingte Formate, Gruppenzeilen, verbundene Zellen (nur ungegliedert, je Seite einmal an der ersten sichtbaren Zelle), Summe am Ende der letzten Seite; Gitterlinien je Zelle (rechte/untere Kante), daher keine Linien in verbundenen Zellen und Gruppenzeilen. Ein Gruppenkopf am Seitenende wandert auf die nächste Seite. Ohne `IPPGTableLook` bzw. mit `False` bleibt der alte Graustufen-Druck. HTML: Vorgaben als CSS, Abweichungen inline, Bänder/Gruppen per `colspan`, Summe in `<tfoot>`, Fortschritt und Datenbalken als `linear-gradient`, Links nur `http(s)`/`mailto` (kein `javascript:` aus Zelldaten). Nicht im Druck: Gruppenfüße (`GroupFooter`) und Symbolsätze (Pfeile).

**Indizes.** Zwei Arten, nie gemischt:
- Anzeige: sichtbare Zeile (`VRow`) und Anzeige-Spalte (`VCol`) – Geometrie, Fokus (`FocusRow`/`FocusCol`), `Selection`, `CellRect`, `MouseCoord`.
- Daten: Datenzeile und Datenspalte – `Cells[]`, `Row`, `Col`, `Columns[]`, alle Ereignisse.
- Umrechnung nur über `DataRow`/`VisualRow` und `DataCol`/`VisualCol`. Gruppenzeilen haben keine Datenzeile (`DataRow` < 0, `Row` = -1).

**Gruppieren.** Die Gruppenstufe verteilt die Zeilen per Hash und Counting Sort (O(n)) und legt einen Gruppenbaum in Vorordnung an. Die Ansicht enthält Kopf- und Fuß-Einträge als negative Werte. Auf-/Zuklappen baut nur die flache Liste neu. Der Zustand hängt am Pfad der Schlüssel und übersteht damit Neusortieren.

**Summen.** Unterste Gruppen lesen ihre Zeilen, obere führen die Ergebnisse der Untergruppen zusammen (`TPPGAggregateAcc.Merge`). Neu gerechnet wird beim Ändern der Ansicht sofort, bei Datenänderungen verzögert über eine gepostete Nachricht (viele `Cells[]`-Zuweisungen → eine Rechnung). `FooterText` rechnet bei Bedarf sofort.

**DB-Grid.** Gruppieren und eigene Summen gibt es nicht (`CanGroup` = False): die Summenzeile kommt aus der Datenmenge (`FooterField`, z. B. `TAggregateField`) oder `OnGetFooterText`. Druck und Export lesen die Datenmenge einmal mit `DisableControls` und Lesezeichen (höchstens `ExportMaxRecords`); der Schnappschuss verfällt mit jeder Datenänderung.

## Phase 14a: Terminplaner

*Plan, Umsetzung und Abweichungen: `Docs\Phase14-Plan.md`.*

**Schichten.** Wie beim Grid kennt der Kern das Control nicht:
- `PPG.TimeZones`: `IPPGTimeZone` (`ToUtc`, `ToLocal`, `OffsetMinutes`). Regeln aus der Registry (`TZI`), Umstellungstage selbst berechnet. Lücke im Frühjahr: Winter-Abstand (02:30 → 03:30); doppelte Stunde im Herbst: die erste. Grenzvergleiche mit einer halben Millisekunde Toleranz (`TDateTime` ist nicht exakt).
- `PPG.Planner.Recurrence`: RRULE als Record (`TPPGRecurrence`), aufgelöst auf der Wanduhr und nur für den angefragten Zeitraum. DTSTART zählt immer als erstes Vorkommen; nicht vorhandene Tage (31., 29.02.) fallen nach RFC 5545 weg (`MonthEnd = mebLastDay` verschiebt stattdessen).
- `PPG.Planner.Layout`: reine Funktionen. `PPGLayoutColumns` (Gruppen sich überschneidender Termine, gierige Spalten, `ColSpan` in freie Spalten rechts) und `PPGLayoutRows` (Bänder).
- `PPG.Planner.Model`: Termine in UTC (`StartTime`/`FinishTime`), Anzeige über `DisplayZone` (`Start`/`Finish`). `GetOccurrences(Von, Bis)` ist die einzige Abfrage des Controls; `IPPGAppointmentSource` ersetzt die Collection (DB, eigene Quellen).
- `PPG.Planner.ICal`: Export/Import ohne das Control.
- `PPG.Planner`: das Control. Es kennt den Kalender nur über `IPPGCalendarLink` (in `PPG.Calendar`) und schreibt Änderungen über überschreibbare Methoden (`DoCreateAppointment`, `DoDeleteAppointment`, `AppointmentWritten`), die der DB-Planer nutzt.

**Layout im Control.** `EnsureLayout` holt die Vorkommen des Zeitraums und legt „Stücke“ (`TPPGPlannerPiece`) an: ein Termin über drei Tage hat drei Stücke. Lage je Stück: fest (Kopf, Band, Monat), nur senkrecht gescrollt (Raster, Agenda) oder in beide Richtungen (Zeitleiste). Zeichnen und Trefferprüfung rechnen dieselben Rechtecke um; RTL spiegelt erst ganz am Ende. Texte gehen gesammelt in einem GDI-Block raus (wie im Kalender).

**Auswahl** merkt sich Termin und Beginn des Vorkommens, nicht den Index: nach jedem Neuaufbau (Daten, Zeitraum, DB-Reload) wird sie wiedergefunden.

**Drucken.** `PPG.Print` ist seit 14a die gemeinsame Basis (`TPPGCustomPrinter`: Seite, Kopf/Fuß, Drucker, PDF, Vorschau, Seite einrichten mit Ja/Nein-Optionen des Druckers). Grid- und Planer-Drucker liefern nur Seitenzahl und Seiteninhalt. Der Planer-Drucker zeichnet über einen unsichtbaren Planer mit `ScalePPI` = Drucker-PPI; deshalb sieht Papier aus wie der Bildschirm.

## Phase 14b: Ribbon

*Plan, Umsetzung und Abweichungen: `Docs\Phase14-Plan.md`.*

**Schichten.**
- `PPG.Ribbon.Layout` (Kern): `PPGRibbonLayoutGroup` legt die Zellen einer Gruppe in einem Zustand aus (große Items und Galerien als Spalte über drei Zeilen, kleine Items und Controls in Stapeln, `SameRow` in derselben Zeile). `PPGRibbonReduce` wählt die Zustände aller Gruppen: Stufe für Stufe über alle Gruppen (mittel → nur Symbol → Dropdown), innerhalb einer Stufe nach `ReduceOrder`, bei Gleichstand von rechts; Schritte ohne Gewinn werden übersprungen. Die Breiten misst das Control, die Funktionen rechnen nur.
- `PPG.KeyTips` (Kern): Vergabe je Ebene (eigene, `&`-Buchstabe, Wortanfänge, sonst zwei Zeichen mit einem Präfix, das kein Einzelzeichen ist) und Präfix-Abgleich.
- `PPG.Ribbon.Items`: Modell ohne Control-Bezug; Änderungen und Komponenten-Referenzen gehen über `IPPGRibbonHost` an den Besitzer der obersten Collection.
- `PPG.Ribbon`: das Control. Die Geometrie einer Registerkarte steckt in `TPPGRibbonView` (Gruppen, Zustände, Item-Rechtecke in Koordinaten des Fensters). Dieselbe Klasse dient dem Band, dem Popup des eingeklappten Bands und dem Popup einer geschrumpften Gruppe; Zeichnen, Trefferprüfung und Mausbehandlung arbeiten auf einer Ansicht und sind deshalb für alle drei gleich. Treffer sind Werte (`TPPGRibbonHit`: Teil, Ansicht, Gruppe, Item, Kachel).

**Layout und Controls.** `EnsureLayout` ist reine Geometrie und darf auch aus Paint kommen; es prüft Breite, DPI und Sprache selbst (ohne Fensterhandle kommt kein `Resize`, ein Sprachwechsel zeichnet nur neu). Die Lage eingebetteter Controls setzt `ApplyControlLayout` nie im Paint, sondern nach einer geposteten Nachricht (`UpdateLayout` sofort). Controls in Popups werden umgehängt und per `ShowWindow(SW_SHOWNA)` gezeigt, weil die VCL ein per API gezeigtes Fenster ohne Parent für unsichtbar hält. Im Designer werden Controls inaktiver Karten verschoben statt verborgen, damit `Visible` nicht in der DFM landet.

**Tasten und Klicks.** Ein Haken in `PPG.AppHooks` sieht die Tasten des Formulars (Fokus bleibt im Formular): Alt allein/F10 zeigt die KeyTips, Alt+Buchstabe springt direkt (nur wenn eine Plakette passt, sonst bleibt die Taste beim Formular), Zeichen werden im KeyTip-Modus per `TranslateMessage` zu `WM_CHAR` und dort abgefangen. Klicks außerhalb eines Popups schließen es und alle darüber (Galerie → Gruppe → Band); Klicks auf das Ribbon selbst entscheidet `MouseDown` (zweiter Klick auf Karte oder Gruppe schließt). Menüs laufen modal; währenddessen ruht der Haken (`FBusy`).

**KeyTip-Overlay.** Ein Fenster je Monitor (`WS_EX_LAYERED` mit Farbschlüssel, `WS_EX_TRANSPARENT`, `WS_EX_NOACTIVATE`), so groß wie die Plaketten darauf. Gezeichnet ohne Kantenglättung, weil Mischpixel mit dem Farbschlüssel sichtbare Ränder ergäben.

## Phase 14c: Kanban

*Plan, Umsetzung und Abweichungen: `Docs\Phase14-Plan.md`.*

**Schichten.** `PPG.Kanban.Layout` (reine Funktionen: Stapel, Einfügeposition, Zielindex, Initialen, Labels, WIP), `PPG.Kanban.Items` (Modell ohne Control-Bezug, Änderungen über `IPPGKanbanHost`), `PPG.Kanban` (Control auf `TPPGCustomScrollControl`), `PPG.DB.Kanban` (Datenmenge ↔ Karten).

**Layout.** `EnsureLayout` verteilt die Karten in Zellen (Spalte × Swimlane, Reihenfolge = Collection), misst ihre Höhe einmal (Cache je Karte, verworfen bei jeder Modelländerung) und legt Stapel an. Adressen sind Werte `(Spalte, Swimlane, Position)` der sichtbaren Spalten, keine Zeiger. Ohne Swimlanes hat jede Spalte einen eigenen Bildlauf (gemerkt je Spalten-Id), das Board nur einen waagerechten; mit Swimlanes scrollt das Board senkrecht, die Spaltenköpfe bleiben stehen und die Swimlane-Köpfe liegen als Band über den Spalten. Virtuelle Spalten haben feste Kartenhöhe: Lage, Treffer und erste sichtbare Karte sind Arithmetik. RTL spiegelt nur die Umrechnung Inhalt ↔ Client.

**Ziehen.** Ab 4 px Bewegung. Das Ziel ist eine Einfügeposition, gezählt ohne die gezogene Karte (`PPGKanbanDropIndex` mit Skip), deshalb springt beim Ziehen innerhalb der Spalte nichts. Ausweichen: Verschiebung je Karte als Funktion des Ziels; zwischen altem und neuem Ziel blendet eine Animation des gemeinsamen Animators über. Bildlauf am Rand: Board über `AutoScrollAt`, Spalte über eine eigene Schleife des Animators. `MoveCard` ist der einzige Weg für Maus, Tastatur und Code: WIP-Sperre, `OnCardMoving`, dann `DoMoveCard` (überschreibbar, DB: nur mit Schlüssel), dann `CardMoved` (DB: schreiben) und `OnCardMoved`.

**Tastatur und Screenreader.** Die Scroll-Basis darf die Pfeile nicht nehmen (`KeyboardScrolling := False`), sie gehören der Kartenauswahl. Kinder für MSAA sind je Spalte der Kopf und ihre Karten; die Ansage nach einem Verschieben steht vor dem Namen der fokussierten Karte und wird per `NAMECHANGE` gemeldet.

## Anpassbarkeit (Element-Stile, Tokens, Zeichen-Ereignisse)

*Anforderungen und Stand: `Docs\Anforderungen-Anpassbarkeit.md`.*

**Element-Stile.** `TPPGElementStyle` (`PPG.ElementStyle`) beschreibt einen Bereich: `Color`, `TextColor`, `BorderColor`, je eine Dunkel-Variante, `ParentFont`/`Font` und `FontStyle`. `clDefault` heißt „vom Preset“, ein leerer Stil ändert also nichts und wird nicht gespeichert. Gruppen erben von `TPPGStyleGroup` (`Create(AOwner, Count)`, Properties über `index`), z. B. `TPPGGridStyles`, `TPPGListStyles`, `TPPGPlannerStyles`. Gezeichnet wird mit `FillFor`/`TextFor`/`BorderFor(Dark, Vorgabe)`. Farben gelten nur ohne Hochkontrast und ohne VCL-Style, Schriften immer. Schriften für einen Paint-Durchgang hält `TPPGFontCache` (DPI-korrigiert, nach dem Zeichnen geleert); dauerhafte GDI-Handles je Control gibt es dadurch nicht.

**Tokens.** Die Renderer liefern nur noch `BaseTokens`; `Tokens` = `BaseTokens` + `PPGApplyTokenOverrides`. Die Überschreibungen (`TPPGTokenOverrides`: Akzent, Farben je Modus, Diagrammpalette, Versionszähler) setzt der `TPPGStyleManager` (`AccentColor`, `ThemeColors`, `ChartPalette`); gibt es mehrere Manager, gilt der zuletzt gesetzte, und sein Destruktor räumt nur eigene Werte ab. Ändern sich helle Farben, leitet der Manager die Appearance neu ab und meldet `TPPGTheme.Changed`. Die Theme-Datei (`PPG.ThemeFile`, INI per RTTI in Deklarationsreihenfolge) wird zuerst in einen Hilfs-Manager geladen, damit eine fehlerhafte Datei nichts halb übernimmt.

**Zeichen-Ereignisse.** `PPG.CustomDraw`: `TPPGDrawStyle` (Fill, TextColor, BorderColor, FontStyle) und `PPGRunCustomDraw`. Das Ereignis läuft vor dem Zeichnen eines Elements mit dem berechneten Stil; Änderungen gelten für dieses Element, `DefaultDraw := False` überspringt das eingebaute Zeichnen. Reihenfolge der Farben: Preset < Bereichsstil < Element (`Item.Color`) < Ereignis.

**Ecken und Schatten.** `IPPGCornerCanvas` ist eine optionale Erweiterung der Canvas (GDI und GDI+): eckige Ecken gelten für alle folgenden Round-Rect-Aufrufe, bis der Aufrufer den alten Wert zurücksetzt (`PPGSetSquareCorners`). Das Basis-Control setzt sie um Fläche und Fokus (`RoundedCorners`), nicht um den Inhalt, deshalb brauchen die Renderer keine Änderung. `Shadow` zeichnet gestapelte, halbtransparente Flächen unter dem Körper; `GetBodyRect` hält dafür Platz frei, Container ziehen ihn auch für die Kinder ab.

**Layout speichern.** Grid, Kanban, Planer und Ribbon-Schnellzugriff speichern als Text im INI-Stil mit Kopfzeile (`[PPGGridLayout]`, `[PPGKanbanLayout]`, `[PPGPlannerLayout]`, `[PPGRibbonQuickAccess]`). Fremder Text ändert nichts; unbekannte Schlüssel und ungültige Werte werden einzeln übergangen, damit alte Dateien nach einem Update weiter laden.

## VCL-Styles

Ist ein VCL-Style aktiv, verwendet ein Control beim Zeichnen `EffectiveAppearance`: Die Formen (Rundung, Rahmen, Glow-Größe und -Intensität) kommen aus dem Preset, die Farben aus dem Style. Das Classic-Preset bleibt dabei glänzend. Die gespeicherte `Appearance` wird nie verändert, Style-Farben landen also nicht in der DFM. Ab XE3 lässt sich das pro Control abschalten, indem `seClient` aus `StyleElements` entfernt wird.

Rangfolge der Farben: **Hochkontrast > VCL-Style > Dark Mode > Appearance**.

**Wichtig für Anwendungen:** Damit `.vsf`-Dateien geladen werden können, muss die Unit `Vcl.Styles` eingebunden sein. Sonst meldet `TStyleManager.IsValidStyle` jeden Style als ungültig. Die IDE bindet sie automatisch ein, wenn in den Projektoptionen Styles ausgewählt sind.

**Beobachtung:** In der Konsolen-Testumgebung schlägt nach „Style → System → Style“ das nächste `CreateWindow` fehl, auch für den Standard-`TButton`. In der grafischen Demo tritt das nicht auf (geprüft mit dem Wechsel dunkel → System → dunkel vor dem Erzeugen der Fenster). Die Tests wechseln den Style deshalb nur einmal hin und zurück.

## Button-Funktionen

- **AutoSize** (alle Controls): Die Größe ergibt sich aus Text, Bild, Abstand, Rahmen, Glow und gegebenenfalls dem Pfeilbereich. Mit `WordWrap` bleibt die Breite fest und nur die Höhe passt sich an. Ausgerichtete Kanten (`Align`) gehören dem Parent.
  - Falle: `TWinControl.AdjustSize` tut ohne Fensterhandle nichts, und `SetBounds` mit unveränderten Werten wird verworfen. Deshalb berechnet `RequestAutoSize` die Größe selbst und setzt sie direkt.
- **Split-Button** (`Style = pbsSplitButton`): Der Klick auf den Körper löst `OnClick` aus. Der Pfeil sowie `Alt+↓` oder `F4` lösen `OnDropDownClick` aus und öffnen danach `DropDownMenu`. Das Menü öffnet beim Drücken, wie unter Windows; `csClicked` wird dabei entfernt, damit beim Loslassen kein `OnClick` folgt. Ein Push-Button mit `DropDownMenu` zeigt einen Pfeil und öffnet das Menü nach `OnClick`.
- **ImageName** (ab 10.4) für `TVirtualImageList`/`TImageCollection`: Gespeichert wird dann nur der Name, nicht der Index. Das ist robust gegen Umsortieren, der Index wird bei jeder Änderung der ImageList nachgeführt. Ein unbekannter Name ergibt „kein Bild“ und keine Exception.
- **SVG:** Jede `TCustomImageList` funktioniert, also auch SVG-Image-Listen wie SVGIconImageList. Einen eigenen SVG-Renderer gibt es nicht.

## Erweitern

**Neues Preset:**
```pascal
type
  TMyRenderer = class(TPPGRendererBase)
  public
    function Name: string; override;
    procedure ApplyDefaults(Appearance: TPPGAppearance); override;
    procedure DrawSurface(const Canvas: IPPGCanvas; const Body: TRect;
      const Style: TPPGSurfaceStyle); override;
  end;
initialization
  TPPGRendererRegistry.RegisterRenderer('MyLook', TMyRenderer);
finalization
  TPPGRendererRegistry.UnregisterRenderer('MyLook');
```

`TPPGRendererBase` liefert außerdem Standard-Darstellungen für Indikatoren (`IPPGIndicatorRenderer`), Wertebereiche (`IPPGRangeRenderer`), Container (`IPPGContainerRenderer`), Eingabefelder (`IPPGFieldRenderer`), Aufklapplisten (`IPPGListRenderer`), Reiter (`IPPGTabRenderer`) und Scrollleisten (`IPPGScrollRenderer`), die ersten drei auf Basis von `DrawSurface`. Ein Preset überschreibt nur, was anders aussehen soll.

**Neues Control:** Ein neues Control wird von `TPPGCustomControl` abgeleitet. Zustandslogik steht in `IsDown`/`IsHot`, das Zeichnen in `DoPaintContent`. Danach folgen die gemeinsamen Properties im `published`-Abschnitt (Reihenfolge wie bei `TPPGButton`) und Tests nach dem Muster in `Tests\PPG.Tests.Controls.pas`.

## Bauen und Testen

```powershell
powershell -ExecutionPolicy Bypass -File Build\build.ps1              # alles, alle Versionen
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Only Delphi13 -Projects Runtime,Tests
Tests\PPGlowTests.exe            # Konsole, Exit-Code 0 = grün
Tests\PPGlowTests.exe /gui       # DUnit-GUI inkl. Leak-Report beim Beenden
Tests\PPGlowTests.exe /leaks     # zwei Läufe, Exit-Code <> 0 bei Speicherlecks
```

Die DB-Pakete heißen in `build.ps1` `DBRuntime` und `DBDesign`; beide sind im Standard enthalten.

Die Community/Starter Edition hat keinen Kommandozeilen-Compiler. Das Skript nutzt dann automatisch den IDE-Batchbuild `bds -b` und wertet die `.err`-Datei aus. Ab Professional läuft der Build über `msbuild`.

**Installation in der IDE** (32- und 64-Bit-IDE, die IDE muss geschlossen sein):

```powershell
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Projects Runtime,Design -Platform Win32 -Config Release
powershell -ExecutionPolicy Bypass -File Build\build.ps1 -Projects Runtime,Design -Platform Win64 -Config Release
powershell -ExecutionPolicy Bypass -File Build\install.ps1          # -Uninstall zum Entfernen
```

`install.ps1` erledigt alles in einem Aufruf:
1. Es baut `PPGlowR`, `dclPPGlow`, `PPGlowDBR` und `dclPPGlowDB` als Release für Win32 und Win64 über `build.ps1` (`-NoBuild` lässt das aus). Win64 ist optional.
2. Es bricht ab, wenn eine BPL älter als die Quelltexte ist. So wird nie ein alter Stand installiert, den die IDE nicht laden kann.
3. Es sichert die Registry nach `Build\registry-backup\`.
4. Es räumt alte PPGlow-Einträge auf (andere Pfade, „Disabled Packages“ nach einem Ladefehler) und meldet sie.
5. Es kopiert BPL/DCP nach `BDSCOMMONDIR\Bpl` bzw. `Bpl\Win64` (beide im `PATH`).
6. Es registriert die Design-Pakete unter *Known Packages*; unter *Known Packages x64* nur, wenn die 64-Bit-IDE installiert ist.
7. Es trägt `Lib\37.0\<Plattform>\Release` in den Bibliothekspfad ein.
8. Zum Schluss lädt es jede BPL testweise in einem Prozess der passenden Bitness und meldet Fehler mit Grund (Code 126: Paket fehlt, 127: alter Stand).

Das Skript ist idempotent. Die Komponenten erscheinen auf den Palettenseiten **PPGlow** und **PPGlow DB**, aber nur, solange ein VCL-Formular im Designer offen ist.
