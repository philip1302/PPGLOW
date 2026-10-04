<#
  PPGlow - Installation in die RAD-Studio-IDE (32- und 64-Bit-IDE)

  Voraussetzung: Packages wurden gebaut:
    Build\build.ps1 -Projects Runtime,Design,DBRuntime,DBDesign -Platform Win32 -Config Release
    Build\build.ps1 -Projects Runtime,Design,DBRuntime,DBDesign -Platform Win64 -Config Release
  Die DB-Controls (PPGlowDBR/dclPPGlowDB) werden mit installiert, wenn sie
  gebaut sind; -NoDB laesst sie aus.

  Was das Skript tut (idempotent, beliebig oft ausfuehrbar):
    1. Kopiert die BPL/DCP-Dateien in die Standard-Ordner der IDE
       (BDSCOMMONDIR\Bpl[\Win64], BDSCOMMONDIR\Dcp[\Win64]) - diese liegen im PATH.
    2. Registriert das Design-Package fuer die 32-Bit-IDE (Known Packages)
       und die 64-Bit-IDE (Known Packages x64).
    3. Traegt die DCU-Ordner in den Bibliothekspfad (Win32/Win64) ein.

  Die IDE muss geschlossen sein - sie ueberschreibt die Registry beim Beenden.

  Aufruf:   powershell -ExecutionPolicy Bypass -File Build\install.ps1 [-Version 37.0] [-Config Release]
  Entfernen: powershell -ExecutionPolicy Bypass -File Build\install.ps1 -Uninstall
#>
param(
  [string]$Version = '37.0',
  [ValidateSet('Debug', 'Release')][string]$Config = 'Release',
  [switch]$Uninstall,
  [switch]$NoDB
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Key = "HKCU:\Software\Embarcadero\BDS\$Version"
$Description = 'PPGlow Components - Designtime'
$DescriptionDB = 'PPGlow Components - Data-aware Designtime'
$Suffix = ($Version -split '\.')[0] + '0'   # 37.0 -> 370 (LIBSUFFIX AUTO)

if (-not (Test-Path $Key)) { throw "RAD Studio $Version ist nicht installiert ($Key fehlt)." }
if (Get-Process bds -ErrorAction SilentlyContinue) {
  throw 'Bitte zuerst alle RAD-Studio-Instanzen schliessen (die IDE ueberschreibt die Registry beim Beenden).'
}

$CommonDir = [Environment]::ExpandEnvironmentVariables(
  "C:\Users\Public\Documents\Embarcadero\Studio\$Version")

# Sicherung der betroffenen Registry-Schluessel vor jeder Aenderung
$BackupDir = Join-Path $PSScriptRoot 'registry-backup'
New-Item -ItemType Directory -Force $BackupDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($sub in 'Known Packages', 'Known Packages x64', 'Library\Win32', 'Library\Win64') {
  $regPath = "HKCU\Software\Embarcadero\BDS\$Version\$sub"
  $file = Join-Path $BackupDir ("$stamp-" + ($sub -replace '[\\ ]', '_') + '.reg')
  & reg.exe export $regPath $file /y | Out-Null
}
Write-Host "Registry-Sicherung: $BackupDir\$stamp-*.reg" -ForegroundColor DarkGray

$Targets = @(
  @{ Platform = 'Win32'; BplDir = "$CommonDir\Bpl";       DcpDir = "$CommonDir\Dcp";       Known = 'Known Packages' },
  @{ Platform = 'Win64'; BplDir = "$CommonDir\Bpl\Win64"; DcpDir = "$CommonDir\Dcp\Win64"; Known = 'Known Packages x64' }
)

function Set-SearchPath([string]$Platform, [string]$Dir, [bool]$Add) {
  $libKey = "$Key\Library\$Platform"
  if (-not (Test-Path $libKey)) { return }
  $current = (Get-ItemProperty $libKey -Name 'Search Path' -ErrorAction SilentlyContinue).'Search Path'
  $parts = @($current -split ';' | Where-Object { $_ -and ($_ -notlike "$Root\Lib\*") })
  if ($Add) { $parts += $Dir }
  Set-ItemProperty $libKey -Name 'Search Path' -Value ($parts -join ';')
}

foreach ($t in $Targets) {
  $src = Join-Path $Root "Lib\$Version\$($t.Platform)\$Config"
  $dcl = Join-Path $t.BplDir "dclPPGlow$Suffix.bpl"
  $dclDB = Join-Path $t.BplDir "dclPPGlowDB$Suffix.bpl"
  $knownKey = "$Key\$($t.Known)"

  if ($Uninstall) {
    foreach ($d in $dcl, $dclDB) {
      Remove-ItemProperty $knownKey -Name $d -ErrorAction SilentlyContinue
      Remove-ItemProperty "$Key\Disabled Packages" -Name $d -ErrorAction SilentlyContinue
    }
    foreach ($f in "dclPPGlowDB$Suffix.bpl", "PPGlowDBR$Suffix.bpl", "dclPPGlow$Suffix.bpl", "PPGlowR$Suffix.bpl") {
      Remove-Item (Join-Path $t.BplDir $f) -ErrorAction SilentlyContinue
    }
    foreach ($n in 'dclPPGlowDB', 'PPGlowDBR', 'dclPPGlow', 'PPGlowR') {
      foreach ($e in '.dcp', '.bpi') { Remove-Item (Join-Path $t.DcpDir ($n + $e)) -ErrorAction SilentlyContinue }
    }
    Set-SearchPath $t.Platform '' $false
    Write-Host "[$($t.Platform)] entfernt" -ForegroundColor Yellow
    continue
  }

  $files = @("PPGlowR$Suffix.bpl", "dclPPGlow$Suffix.bpl")
  foreach ($f in $files) {
    if (-not (Test-Path (Join-Path $src $f))) {
      throw "$f fehlt in $src - zuerst bauen: Build\build.ps1 -Projects Runtime,Design -Platform $($t.Platform) -Config $Config"
    }
  }
  # DB-Controls nur, wenn gebaut (und nicht abgewaehlt)
  $withDB = (-not $NoDB) -and (Test-Path (Join-Path $src "PPGlowDBR$Suffix.bpl")) -and
    (Test-Path (Join-Path $src "dclPPGlowDB$Suffix.bpl"))
  $names = @('PPGlowR', 'dclPPGlow')
  if ($withDB) {
    $files += @("PPGlowDBR$Suffix.bpl", "dclPPGlowDB$Suffix.bpl")
    $names += @('PPGlowDBR', 'dclPPGlowDB')
  }
  New-Item -ItemType Directory -Force $t.BplDir, $t.DcpDir | Out-Null
  foreach ($f in $files) { Copy-Item (Join-Path $src $f) $t.BplDir -Force }
  Get-ChildItem (Join-Path $src '*') -Include '*.dcp', '*.bpi' -File -ErrorAction SilentlyContinue |
    Where-Object { $names -contains $_.BaseName } |
    ForEach-Object { Copy-Item $_.FullName $t.DcpDir -Force }

  if (-not (Test-Path $knownKey)) { New-Item $knownKey -Force | Out-Null }
  New-ItemProperty $knownKey -Name $dcl -Value $Description -PropertyType String -Force | Out-Null
  # Falls frueher deaktiviert (z.B. nach einem Ladefehler): wieder aktivieren
  Remove-ItemProperty "$Key\Disabled Packages" -Name $dcl -ErrorAction SilentlyContinue
  if ($withDB) {
    New-ItemProperty $knownKey -Name $dclDB -Value $DescriptionDB -PropertyType String -Force | Out-Null
    Remove-ItemProperty "$Key\Disabled Packages" -Name $dclDB -ErrorAction SilentlyContinue
  }
  else {
    Remove-ItemProperty $knownKey -Name $dclDB -ErrorAction SilentlyContinue
  }
  Set-SearchPath $t.Platform $src $true

  Write-Host "[$($t.Platform)] installiert: $dcl" -ForegroundColor Green
  if ($withDB) { Write-Host "           und: $dclDB" -ForegroundColor Green }
  Write-Host "           Bibliothekspfad: $src"
}

if (-not $Uninstall) {
  Write-Host ''
  Write-Host 'Fertig. IDE starten -> Tool-Palette, Kategorien "PPGlow" und "PPGlow DB".'
}
