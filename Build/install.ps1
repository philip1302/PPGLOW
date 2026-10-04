<#
  PPGlow - Installation in die RAD-Studio-IDE (32- und 64-Bit-IDE)

  Ein Aufruf erledigt alles (idempotent, beliebig oft ausfuehrbar):
    1. Baut die Pakete PPGlowR, dclPPGlow, PPGlowDBR, dclPPGlowDB als Release
       fuer Win32 und Win64 (ueber build.ps1; -NoBuild laesst das aus).
    2. Prueft, dass die BPLs neuer als die Quelltexte sind (sonst wuerde ein
       alter Stand installiert, den die IDE nicht laden kann).
    3. Raeumt alte PPGlow-Eintraege in der Registry auf (andere Pfade,
       "Disabled Packages" nach einem Ladefehler) und meldet sie.
    4. Kopiert BPL/DCP nach BDSCOMMONDIR\Bpl[\Win64] bzw. Dcp[\Win64] (im PATH),
       registriert die Design-Pakete (Known Packages / Known Packages x64)
       und traegt die DCU-Ordner in den Bibliothekspfad ein.
    5. Ladetest: laedt jede installierte BPL so, wie die IDE es tut
       (Abhaengigkeiten, Einsprungpunkte). Schlaegt er fehl, steht der Grund da.

  Win32 ist Pflicht. Win64 wird mitgenommen, wenn es sich bauen laesst; ein
  Fehler dort bricht die Win32-Installation nicht ab.

  Die IDE muss geschlossen sein - sie ueberschreibt die Registry beim Beenden.

  Aufruf:   powershell -ExecutionPolicy Bypass -File Build\install.ps1
            [-Version 37.0] [-Config Release] [-Platforms Win32,Win64] [-NoBuild] [-NoDB]
  Entfernen: powershell -ExecutionPolicy Bypass -File Build\install.ps1 -Uninstall
#>
param(
  [string]$Version = '37.0',
  [ValidateSet('Debug', 'Release')][string]$Config = 'Release',
  [string[]]$Platforms = @('Win32', 'Win64'),
  [switch]$Uninstall,
  [switch]$NoDB,
  [switch]$NoBuild
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Key = "HKCU:\Software\Embarcadero\BDS\$Version"
$Description = 'PPGlow Components - Designtime'
$DescriptionDB = 'PPGlow Components - Data-aware Designtime'
$Suffix = ($Version -split '\.')[0] + '0'   # 37.0 -> 370 (LIBSUFFIX AUTO)
# -File uebergibt Arrays als einen String ("A,B") -> aufteilen
$Platforms = @($Platforms | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
foreach ($p in $Platforms) {
  if ($p -notin 'Win32', 'Win64') { throw "Unbekannte Plattform '$p' (erlaubt: Win32, Win64)." }
}
if ($Platforms -notcontains 'Win32') { throw 'Win32 ist Pflicht: die IDE selbst laedt Win32-Pakete.' }

# BDS-Version -> Ordner unter Packages\ (wie in build.ps1)
$Folders = @{ '9.0' = 'XE2'; '37.0' = 'Delphi13' }
$Folder = $Folders[$Version]
if (-not $Folder) { throw "Version $Version ist in install.ps1/build.ps1 nicht bekannt." }

if (-not (Test-Path $Key)) { throw "RAD Studio $Version ist nicht installiert ($Key fehlt)." }
if (Get-Process bds -ErrorAction SilentlyContinue) {
  throw 'Bitte zuerst alle RAD-Studio-Instanzen schliessen (die IDE ueberschreibt die Registry beim Beenden).'
}
$StudioDir = (Get-ItemProperty $Key).RootDir
$CommonDir = "C:\Users\Public\Documents\Embarcadero\Studio\$Version"

$Targets = @(
  @{ Platform = 'Win32'; BplDir = "$CommonDir\Bpl";       DcpDir = "$CommonDir\Dcp";       Known = 'Known Packages';
     StudioBin = (Join-Path $StudioDir 'bin') },
  @{ Platform = 'Win64'; BplDir = "$CommonDir\Bpl\Win64"; DcpDir = "$CommonDir\Dcp\Win64"; Known = 'Known Packages x64';
     StudioBin = (Join-Path $StudioDir 'bin64') }
) | Where-Object { $Platforms -contains $_.Platform }

function Set-SearchPath([string]$Platform, [string]$Dir, [bool]$Add) {
  $libKey = "$Key\Library\$Platform"
  if (-not (Test-Path $libKey)) { return }
  $current = (Get-ItemProperty $libKey -Name 'Search Path' -ErrorAction SilentlyContinue).'Search Path'
  $parts = @($current -split ';' | Where-Object { $_ -and ($_ -notlike "$Root\Lib\*") })
  if ($Add) { $parts += $Dir }
  Set-ItemProperty $libKey -Name 'Search Path' -Value ($parts -join ';')
}

# Entfernt PPGlow-Eintraege eines Registry-Schluessels ausser $Keep; liefert die entfernten Namen
function Remove-PPGlowEntries([string]$RegKey, [string[]]$Keep) {
  $removed = @()
  if (-not (Test-Path $RegKey)) { return $removed }
  foreach ($n in (Get-Item $RegKey).GetValueNames()) {
    if ((Split-Path $n -Leaf) -like '*PPGlow*.bpl' -and ($Keep -notcontains $n)) {
      Remove-ItemProperty $RegKey -Name $n
      $removed += $n
    }
  }
  return $removed
}

# Laedt BPLs in einem Prozess der passenden Bitness (wie die IDE: PATH = eigene
# Bpl-Ordner + Studio\bin). Liefert je Datei 'OK' oder die Windows-Fehlermeldung.
function Test-BplLoad([string]$Platform, [string[]]$Dirs, [string[]]$Files) {
  $q = { param($s) "'" + ($s -replace "'", "''") + "'" }
  $script = '$Dirs = @(' + (($Dirs | ForEach-Object { & $q $_ }) -join ',') + ')' + "`n" +
    '$Files = @(' + (($Files | ForEach-Object { & $q $_ }) -join ',') + ')' + "`n" + @'
$env:PATH = ($Dirs -join ';') + ';' + $env:PATH
Add-Type -Namespace PPG -Name K -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
public static extern IntPtr LoadLibraryW(string f);
"@
foreach ($f in $Files) {
  $h = [PPG.K]::LoadLibraryW($f)
  if ($h -eq [IntPtr]::Zero) {
    $e = [Runtime.InteropServices.Marshal]::GetLastWin32Error()
    "FAIL|$f|$e|" + (New-Object ComponentModel.Win32Exception $e).Message
  } else { "OK|$f" }
}
'@
  $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($script))
  $sys = if ([Environment]::Is64BitProcess) { 'System32' } else { 'Sysnative' }
  if ($Platform -eq 'Win32') { $sys = 'SysWOW64' }
  $ps = Join-Path $env:SystemRoot "$sys\WindowsPowerShell\v1.0\powershell.exe"
  if (-not (Test-Path $ps)) { return @("SKIP||0|$ps fehlt") }
  return @(& $ps -NoProfile -NonInteractive -EncodedCommand $enc)
}

function Get-LoadHint([int]$Code) {
  switch ($Code) {
    126 { 'Ein benoetigtes Paket wurde nicht gefunden (z.B. PPGlowR nicht im Bpl-Ordner).' }
    127 { 'Einsprungpunkt fehlt: das Paket passt nicht zur installierten Runtime (alter Stand). Neu bauen.' }
    193 { 'Falsche Bitness (Win32/Win64 vertauscht).' }
    default { '' }
  }
}

# --- Entfernen ---------------------------------------------------------------
if ($Uninstall) {
  foreach ($t in $Targets) {
    $r = Remove-PPGlowEntries "$Key\$($t.Known)" @()
    [void](Remove-PPGlowEntries "$Key\Disabled Packages" @())
    foreach ($f in "dclPPGlowDB$Suffix.bpl", "PPGlowDBR$Suffix.bpl", "dclPPGlow$Suffix.bpl", "PPGlowR$Suffix.bpl") {
      Remove-Item (Join-Path $t.BplDir $f) -ErrorAction SilentlyContinue
    }
    foreach ($n in 'dclPPGlowDB', 'PPGlowDBR', 'dclPPGlow', 'PPGlowR') {
      foreach ($e in '.dcp', '.bpi') { Remove-Item (Join-Path $t.DcpDir ($n + $e)) -ErrorAction SilentlyContinue }
    }
    Set-SearchPath $t.Platform '' $false
    Write-Host "[$($t.Platform)] entfernt ($($r.Count) Registry-Eintraege)" -ForegroundColor Yellow
  }
  exit 0
}

# --- 1. Bauen ------------------------------------------------------------------
$Projects = @('Runtime', 'Design')
if (-not $NoDB) { $Projects += @('DBRuntime', 'DBDesign') }
$BuildFailed = @{}
if (-not $NoBuild) {
  foreach ($t in $Targets) {
    Write-Host "Baue $($Projects -join ', ') fuer $($t.Platform)/$Config ..." -ForegroundColor Cyan
    $global:LASTEXITCODE = 0
    & (Join-Path $PSScriptRoot 'build.ps1') -Only $Folder -Projects $Projects -Platform $t.Platform -Config $Config
    if ($LASTEXITCODE -ne 0) { $BuildFailed[$t.Platform] = $true }
  }
  if ($BuildFailed['Win32']) {
    Write-Host ''
    Write-Host 'Der Win32-Build ist fehlgeschlagen - ohne ihn kann die IDE die Pakete nicht laden.' -ForegroundColor Red
    Write-Host "Die Fehler stehen in Packages\$Folder\*.err (bitte an Claude schicken)." -ForegroundColor Red
    exit 1
  }
}

# Neueste Quelle (Units, Includes, Ressourcen, Paketdateien) fuer die Altersprobe
$Newest = (Get-ChildItem (Join-Path $Root 'Source'), (Join-Path $Root "Packages\$Folder") -Recurse -File `
  -Include '*.pas', '*.inc', '*.dcr', '*.dpk' | Measure-Object LastWriteTime -Maximum).Maximum

# Registry sichern
$BackupDir = Join-Path $PSScriptRoot 'registry-backup'
New-Item -ItemType Directory -Force $BackupDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($sub in 'Known Packages', 'Known Packages x64', 'Disabled Packages', 'Library\Win32', 'Library\Win64') {
  $regPath = "HKCU\Software\Embarcadero\BDS\$Version\$sub"
  $file = Join-Path $BackupDir ("$stamp-" + ($sub -replace '[\\ ]', '_') + '.reg')
  & reg.exe export $regPath $file /y 2>$null | Out-Null
}
Write-Host "Registry-Sicherung: $BackupDir\$stamp-*.reg" -ForegroundColor DarkGray

$Problems = 0
foreach ($t in $Targets) {
  $P = $t.Platform
  Write-Host ''
  Write-Host "[$P]" -ForegroundColor Cyan
  $optional = ($P -eq 'Win64')
  if ($BuildFailed[$P]) {
    Write-Host "  Build fehlgeschlagen - $P wird nicht installiert (Win32 bleibt nutzbar)." -ForegroundColor Yellow
    $Problems++
    continue
  }
  $src = Join-Path $Root "Lib\$Version\$P\$Config"
  $dcl = Join-Path $t.BplDir "dclPPGlow$Suffix.bpl"
  $dclDB = Join-Path $t.BplDir "dclPPGlowDB$Suffix.bpl"
  $knownKey = "$Key\$($t.Known)"

  # --- 2. Vorhanden und aktuell? ----------------------------------------------
  $files = @("PPGlowR$Suffix.bpl", "dclPPGlow$Suffix.bpl")
  $withDB = (-not $NoDB) -and (Test-Path (Join-Path $src "PPGlowDBR$Suffix.bpl")) -and
    (Test-Path (Join-Path $src "dclPPGlowDB$Suffix.bpl"))
  if ($withDB) { $files += @("PPGlowDBR$Suffix.bpl", "dclPPGlowDB$Suffix.bpl") }
  $stale = @()
  foreach ($f in $files) {
    $path = Join-Path $src $f
    if (-not (Test-Path $path)) { $stale += "$f fehlt" }
    elseif ((Get-Item $path).LastWriteTime -lt $Newest) { $stale += "$f ist aelter als die Quelltexte" }
  }
  if ($stale) {
    $stale | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    $msg = "  Zuerst bauen (ohne -NoBuild ruft install.ps1 das selbst auf): " +
      "Build\build.ps1 -Only $Folder -Projects Runtime,Design,DBRuntime,DBDesign -Platform $P -Config $Config"
    if ($optional) { Write-Host $msg -ForegroundColor Yellow; $Problems++; continue }
    throw ($msg.Trim())
  }
  $names = $files | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) -replace ($Suffix + '$'), '' }
  # Design-Pakete braucht nur eine IDE dieser Bitness (64-Bit-IDE: bin64\bds.exe)
  $hasIde = Test-Path (Join-Path $t.StudioBin 'bds.exe')
  if (-not $hasIde) { Write-Host "  Keine $P-IDE installiert: nur Runtime-Pakete und Bibliothekspfad." -ForegroundColor DarkGray }

  # --- 3. Alte Eintraege --------------------------------------------------------
  $keep = @(); if ($hasIde) { $keep += $dcl; if ($withDB) { $keep += $dclDB } }
  $disabled = Remove-PPGlowEntries "$Key\Disabled Packages" @()
  foreach ($d in $disabled) {
    Write-Host "  Die IDE hatte $(Split-Path $d -Leaf) deaktiviert (Ladefehler beim letzten Start) - wieder aktiviert." -ForegroundColor Yellow
  }
  foreach ($d in (Remove-PPGlowEntries $knownKey $keep)) {
    Write-Host "  Alter Eintrag entfernt: $d" -ForegroundColor Yellow
  }
  if (-not $withDB) { Remove-ItemProperty $knownKey -Name $dclDB -ErrorAction SilentlyContinue }

  # --- 4. Kopieren und registrieren -----------------------------------------------
  New-Item -ItemType Directory -Force $t.BplDir, $t.DcpDir | Out-Null
  foreach ($f in $files) { Copy-Item (Join-Path $src $f) $t.BplDir -Force }
  Get-ChildItem (Join-Path $src '*') -Include '*.dcp', '*.bpi' -File -ErrorAction SilentlyContinue |
    Where-Object { $names -contains $_.BaseName } |
    ForEach-Object { Copy-Item $_.FullName $t.DcpDir -Force }
  if (-not (Test-Path $knownKey)) { New-Item $knownKey -Force | Out-Null }
  if ($hasIde) {
    New-ItemProperty $knownKey -Name $dcl -Value $Description -PropertyType String -Force | Out-Null
    if ($withDB) { New-ItemProperty $knownKey -Name $dclDB -Value $DescriptionDB -PropertyType String -Force | Out-Null }
    Write-Host "  installiert: $dcl" -ForegroundColor Green
    if ($withDB) { Write-Host "          und: $dclDB" -ForegroundColor Green }
  }
  Set-SearchPath $P $src $true
  Write-Host "  Bibliothekspfad: $src"

  # --- 5. Ladetest ----------------------------------------------------------------
  $order = @($files | Where-Object { $hasIde -or ($_ -notlike 'dcl*') } | ForEach-Object { Join-Path $t.BplDir $_ })
  $result = Test-BplLoad $P @($t.BplDir, $t.StudioBin) $order
  foreach ($line in $result) {
    $parts = "$line" -split '\|', 4
    switch ($parts[0]) {
      'OK' { Write-Host "  Ladetest OK: $(Split-Path $parts[1] -Leaf)" -ForegroundColor Green }
      'FAIL' {
        $Problems++
        Write-Host "  Ladetest FEHLER: $(Split-Path $parts[1] -Leaf): $($parts[3]) (Code $($parts[2]))" -ForegroundColor Red
        $hint = Get-LoadHint ([int]$parts[2])
        if ($hint) { Write-Host "    $hint" -ForegroundColor Red }
      }
      'SKIP' { Write-Host "  Ladetest uebersprungen: $($parts[3])" -ForegroundColor DarkYellow }
      default { if ("$line".Trim()) { Write-Host "  $line" -ForegroundColor DarkGray } }
    }
  }
}

Write-Host ''
if ($Problems -eq 0) {
  Write-Host 'Fertig, alle Pakete laden.' -ForegroundColor Green
} else {
  Write-Host "Fertig mit $Problems Problem(en) - siehe oben." -ForegroundColor Yellow
}
Write-Host 'So erscheinen die Komponenten:'
Write-Host '  1. RAD Studio starten.'
Write-Host '  2. Ein VCL-Formular im Designer oeffnen (Datei > Neu > Windows-VCL-Anwendung).'
Write-Host '     Die Palette zeigt Komponenten nur, solange ein Formular im Design-Modus aktiv ist.'
Write-Host '  3. Palette: Kategorien "PPGlow" und "PPGlow DB" (Suchfeld oben: "TPPG").'
Write-Host '  Fehlt etwas: Komponente > Packages installieren - "PPGlow Components" muss angehakt sein.'
Write-Host '  Meldet die IDE beim Start einen Ladefehler, install.ps1 erneut ausfuehren: es zeigt den Grund.'
if ($Problems -gt 0) { exit 1 }
