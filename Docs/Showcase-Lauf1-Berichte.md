## TPPGComboBox (eace270f) 25/0
- Gerüst: CreateSubject SelectPath('Caption') -> ohne Caption leere Erklärung; Fallback/InitialPath.
- Komponente: PPG.ComboBox TComboExSource.GetItem gibt TPPGItem.Group nicht weiter (keine Gruppenköpfe in ItemsEx).
- Typ-Schlüssel: TPPGListStyles.*, TPPGElementStyle.*, TPPGItem.*
## TPPGCheckComboBox (9d40804e) 27/0
- Doku: props\10-grid-db.txt TPPGCheckComboBox.OnItemCheck behauptet "auch über Alle auswählen" - UserCheckAll löst nur Change aus (Komponente oder Text korrigieren).
- Gerüst: KindOf tkChar/tkWChar -> pkOther; Delimiter (Char) nicht editierbar/kein Code. Char wie String Länge 1.
- Typ-Schlüssel: TPPGElementStyle.* (doppelt mit ComboBox)
## TPPGPasswordEdit (9a3dfbdb) 28/0
- Gerüst: Char-Eigenschaften (PasswordChar) ohne Editor; Rundlauf überspringt Zeilen ohne Editor still -> melden.
- Typ-Schlüssel: TPPGElementStyle.* (doppelt)
## TPPGSearchEdit (24dec070) 27/0
- migrate.ps1 Z.113 + Docs\Migration.md Z.81: TSearchBox OnInvokeSearch -> muss OnSubmit sein, nicht OnSearch.
- Typ-Schlüssel: TPPGItem.* (doppelt mit ComboBox)
## TPPGNumberEdit (88b28656) 27/0
- Komponente: Löschknopf ruft Clear (StoreValue ohne UserAction) -> kein OnChange; Vorschlag ClearByUser/ClearButtonClick.
- Komponente: SetMinValue/SetMaxValue nennen 'MinValue'/'MaxValue' in Fehlermeldung, Properties heißen Min/Max; Kopfkommentar veraltet.
- Gerüst: Caption-Default (wie oben). Code-Panel 540px schneidet lange Zeilen.
- Typ-Schlüssel: TPPGElementStyle.*
## TPPGToolBar (75a6a707) 31/0
- Komponente: PPG.ToolBar InitiateAction wird nie aufgerufen (kein csActionClient) -> Action.OnUpdate an Items läuft nie. Fix in TPPGToolItem.SetAction + Test.
- Gerüst: DfmText leert nur Ereignisse der Komponente, nicht der Collection-Einträge -> ungültige DFM möglich.
- Doku: 02-typen.txt TPPGToolItems/TPPGToolItem erwähnt Dropdowns/Menü (gibt es nicht).
- Komponente: Überlaufmenü übernimmt IconChar nicht.
- Typ-Schlüssel: TPPGToolItem.*
## TPPGRating (12642ef1) 26/0
- Komponente: SetMaxValue nennt 'MaxValue' statt 'Max'; Max< Value und SetAllowHalf ohne NotifyAccessibility VALUECHANGE.
- Gerüst: Float (Value Double) wird im Rundlauf ausgelassen; clDefault-Farbe sieht schwarz aus.
## TPPGFileEdit (4da3b8bc) 26/0
- Komponente: DropPaths prüft AcceptDrop nicht.
- Typ-Schlüssel: TPPGElementStyle.*
## TPPGCheckBox (13375d03) 25/0
- Doku: 01-basis.txt TPPGCustomCheckControl.State "cbGrayed nur mit AllowGrayed" gilt nur für Klick; per Code immer setzbar -> präzisieren.
## TPPGColorPicker (1e0ea36e) 26/0
- Gerüst: Caption-Default; Agent hat Activated-Override (wählt 'Selected') -> nach Gerüst-Fix (InitialPath) entfernen/umstellen.
- Doku/Kommentar: ShowThemeColors nennt Akzent+Signalfarben, Code zeigt nur Diagrammpalette (10-grid-db.txt, PPG.ColorPicker Kopf).
## TPPGMemo (a80890b0) 25/0
- Typ-Schlüssel: TPPGElementStyle.*; Gerüst: clDefault-Farbfeld schwarz.
## TPPGCheckGroup (88d10469) 25/0
- Gerüst/CodeGen: Items (TStrings, stored False) + ItemsEx (Collection) beide ausgegeben -> doppelte Einträge. Nicht gespeicherte Sicht weglassen (IsStoredProp).
- Doku: 70-auswahl-kacheln.txt TPPGCustomChoiceGroup.OnChange/ItemIndex behaupten OnChange bei Code - falsch.
- Komponente: TPPGChoiceItem.SetState nimmt cbGrayed ohne AllowGrayed an.
- Typ-Schlüssel: TPPGChoiceItem.*, TPPGElementStyle.*
## TPPGEdit (58ec2ed0) 26/0
- ACHTUNG: TextHint-Änderung in DemoShowEdit.pas NACH dem Commit (evtl. nicht committet) -> beim Mergen prüfen.
- Typ-Schlüssel: TPPGEditButton.*, TPPGElementStyle.*
## TPPGToggleSwitch (c57fd66c) 21/0
- Doku: 01-basis.txt TPPGCustomCheckControl.Alignment ("Kästchen") und Spacing ("Bild und Text") allgemeiner formulieren.
## TPPGSpinEdit (d6aaf1e0, 0914f24d) 25/0 - BuildContent-Override wählt Value (nach InitialPath-Fix vereinfachen); Kommentare MinValue/MaxValue in PPG.SpinEdit; migrate.ps1 MinValue->Min prüfen.
## TPPGTrackBar (3c9a67c3) 24/0 - Ticks bei Fluent11 blass; Code-Ansicht schneidet ab ~72 Zeichen.
## TPPGRadioButton (b545c5e9) 25/0 - keine Fehler.
## TPPGRibbon (22f2bbc6) 31/0
- Komponente/Doku: OnGetGalleryItem feuert für jede Galerie (auch mit GalleryItems), Text sagt nur virtuell (PPG.Ribbon GetGalleryData ~3051).
- Doku: 50-navigation.txt TPPGRibbonTab.ContextColor Vorgabe ist clDefault, nicht clNone.
- Gerüst: Bühnen-Hinweis von alTop-Controls verdeckt -> Label im Gerüst alTop.
- Typ-Schlüssel: TPPGRibbonTab.*, TPPGRibbonGroup.*, TPPGRibbonItem.*
## TPPGTagEdit (aff505f0) 29/0
- SkipInRoundTrip Height bei AutoSize (Höhe aus Inhalt); allgemeiner Hinweis für AutoSize-Controls.
## TPPGRadioGroup (d6d542e8) 24/0
- SkipInRoundTrip Items (gleiche Einträge wie ItemsEx).
- CodeGen stored-Fehler (inzwischen im Gerüst behoben).
- Doku: 70-auswahl-kacheln.txt ItemIndex/OnChange falsch (wie CheckGroup).
## TPPGMaskEdit (07fb38cf) 22/0
- KOMPONENTE (wichtig): TPPGMaskEdit.Text umgeht TCustomMaskEdit.Text (PPG.Controls.Field GetText/SetText ~1654 über TCustomEdit): Maske ";0;" wirkt nicht, Text := '' löscht Platzhalter; FieldClear/SetFieldValue(Null) betroffen. Fix: Text-Zugriff in TPPGCustomMaskEdit auf die Masken-Logik umleiten + Test.
- VCL: ValidateInput prüft nur Pflichtstellen, nicht Zeichenart.
