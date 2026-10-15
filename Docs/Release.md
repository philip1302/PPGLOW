# Release und Installer

*Stand 15.10.2026.*

## Was ausgeliefert wird

Jedes Release unter [GitHub Releases](https://github.com/philip1302/ppglow/releases) enthält zwei Dateien:

| Datei | Inhalt |
|---|---|
| `PPGlow-Setup-<Version>.exe` | Setup (Inno Setup 6), Deutsch, ohne Administratorrechte |
| `PPGlow-<Version>-Quellen.zip` | Dieselben Dateien für die Installation von Hand |

Das Setup ist ein **Quelltext-Installer**. Fertige BPLs liefert es nicht aus, weil sie nur zu genau einer Delphi-Version passen und es auf den GitHub-Runnern kein Delphi gibt. Stattdessen:

1. Das Setup kopiert `Source`, die Paketprojekte (`Packages\XE2`, `Delphi11`, `Delphi13`), `Build\build.ps1`, `Build\install.ps1` und `Installer\run-install.ps1` nach `%LOCALAPPDATA%\PPGlow` (änderbar).
2. Es zeigt nur die installierten Delphi-Versionen zur Auswahl (Registry `HKCU\Software\Embarcadero\BDS\22.0` bzw. `37.0`). Optional wählbar: DB-Komponenten (Vorgabe an) und Win64 (Vorgabe an).
3. Vor dem Installieren wartet es, bis RAD Studio geschlossen ist.
4. Je Version ruft es `Installer\run-install.ps1` auf, das `Build\install.ps1 -NoRuleCheck` startet. Das baut mit dem eigenen Delphi und registriert die Pakete. Das Protokoll steht in `Logs\install-<BDS-Version>.log`. Ein Fehler erscheint am Ende als Meldung; die Quelltexte bleiben dann installiert.
5. Die Deinstallation ruft `install.ps1 -Uninstall` für jede Version auf, die das Setup erfolgreich installiert hat (gemerkt unter `HKCU\Software\PPGlow\Setup`). Danach löscht sie Dateien, `Lib` und `Logs`. `Build\registry-backup` bleibt als Sicherung liegen.

XE2 bietet das Setup nicht an: Der XE2-Bauweg ist noch nie gelaufen (`Docs\Kompatibilitaet.md`).

## Release anlegen

```
git tag v1.0.0
git push origin v1.0.0
```

Der Workflow `.github/workflows/installer.yml` läuft auf `windows-latest` und erledigt den Rest:

1. Regel-Prüfer (`Build\check-rules.ps1`). Ein Verstoß bricht das Release ab.
2. `Installer\stage.ps1` stellt die Dateien aus `git ls-files` zusammen (ohne Build-Ausgaben).
3. Inno Setup baut das Setup (fehlt Inno Setup auf dem Runner, wird es per Chocolatey installiert).
4. Das ZIP entsteht aus denselben Dateien.
5. `gh release create` legt das Release an. Ein Tag mit Bindestrich (`v1.0.0-beta1`) wird als Vorabversion markiert.

Ohne Tag (Push mit Änderungen unter `Installer\`, an `build.ps1`/`install.ps1` oder am Workflow bzw. manueller Start unter „Actions“) wird nur gebaut; Setup und ZIP hängen dann als Artefakt am Workflow-Lauf.

## Grenzen

- **Nicht signiert:** Windows SmartScreen warnt beim ersten Start („Weitere Informationen“ > „Trotzdem ausführen“). Für eine Signatur braucht es ein Code-Signing-Zertifikat (Phase 15).
- **Lizenz:** Das Repository hat keine Lizenzdatei. Ein öffentliches Release macht die Komponenten zum Herunterladen verfügbar. Lizenz und Arbeitgeber sind vorher zu klären (Phase 15 ist deshalb zurückgestellt).
- **Dauer:** Das Bauen dauert je Version und Plattform einige Minuten, bei der Community Edition über die IDE im Hintergrund (`bds -b`).
- **Delphi 11** ist noch nicht mit einem vollständigen Build geprüft (`Docs\Kompatibilitaet.md`).
