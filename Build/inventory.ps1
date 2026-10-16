<#
.SYNOPSIS
  Bestandsaufnahme der Komponentenklassen eines Delphi-Projekts (vor/nach der Migration auf PPGlow).

.DESCRIPTION
  Liest die uses-Liste der .dpr (inkl. "in 'pfad'"), nimmt die zugehoerigen .dfm
  (Formulare, Frames, Datenmodule) und zaehlt je Datei alle Zeilen
  "object|inherited|inline Name: TKlasse". Jede Klasse kommt in eine Rubrik:
    PPGlow     - beginnt mit TPPG oder ist in <Root>\Source\**\*.pas als Klasse deklariert
    bleibt     - steht in der KeepList (hat Vorrang vor "migrierbar")
    migrierbar - steht in $ClassMap von Build\migrate.ps1
    offen      - alles andere
  Die Wurzelklasse (TForm/TFrame/TDataModule/...) wird je Datei getrennt ausgewiesen
  und nicht in den Rubriken mitgezaehlt.
  Binaere DFMs (erstes Byte 0xFF) werden gemeldet und uebersprungen.

.PARAMETER Project   Pfad der .dpr (Pflicht).
.PARAMETER OutFile   Ausgabedatei; ohne Angabe Konsole.
.PARAMETER Format    text | csv | md (Standard md).
.PARAMETER KeepList  Klassen, die bleiben duerfen: .psd1 (Array oder Hashtable mit Arrays),
                     Textdatei (eine Klasse je Zeile, # = Kommentar) oder direkt eine Liste
                     von Klassennamen.
.PARAMETER Root      PPGlow-Repo (Standard: Elternordner dieses Skripts).

.EXAMPLE
  .\inventory.ps1 -Project C:\Proj\App.dpr -OutFile inventur.md
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Project,
  [string]$OutFile,
  [ValidateSet('text', 'csv', 'md')][string]$Format = 'md',
  [string[]]$KeepList = @(),
  [string]$Root
)

$ErrorActionPreference = 'Stop'
if (-not $Root) { $Root = Split-Path -Parent $PSScriptRoot }

if (-not (Test-Path -LiteralPath $Project -PathType Leaf)) {
  Write-Error "Projektdatei nicht gefunden: $Project"
  exit 1
}
$Project = (Resolve-Path -LiteralPath $Project).Path
$projDir = Split-Path -Parent $Project

# ---------------------------------------------------------------- Hilfen
function Read-TextTolerant([string]$Path) {
  $bytes = [System.IO.File]::ReadAllBytes($Path)
  $start = 0
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) { $start = 3 }
  try {
    $enc = New-Object System.Text.UTF8Encoding($false, $true)
    return $enc.GetString($bytes, $start, $bytes.Length - $start)
  } catch {
    return [System.Text.Encoding]::GetEncoding(1252).GetString($bytes, $start, $bytes.Length - $start)
  }
}

# ---------------------------------------------------------------- ClassMap aus migrate.ps1
$migrated = @{}
$migrate = Join-Path $PSScriptRoot 'migrate.ps1'
if (Test-Path -LiteralPath $migrate) {
  $mt = Read-TextTolerant $migrate
  $m = [regex]::Match($mt, '(?ms)\$ClassMap\s*=\s*\[ordered\]@\{(.*?)^\}')
  if ($m.Success) {
    foreach ($e in [regex]::Matches($m.Groups[1].Value, "(?m)^\s*'([\w.]+)'\s*=\s*@\(")) {
      $migrated[$e.Groups[1].Value] = $true
    }
  }
  if ($migrated.Count -eq 0) { Write-Warning 'ClassMap in migrate.ps1 nicht gefunden - Rubrik "migrierbar" bleibt leer.' }
} else {
  Write-Warning "migrate.ps1 nicht gefunden ($migrate) - Rubrik `"migrierbar`" bleibt leer."
}

# ---------------------------------------------------------------- PPGlow-Klassen aus Source
$ppg = @{}
$srcDir = Join-Path $Root 'Source'
if (Test-Path -LiteralPath $srcDir) {
  foreach ($f in Get-ChildItem -LiteralPath $srcDir -Recurse -Filter *.pas -File) {
    $t = Read-TextTolerant $f.FullName
    foreach ($e in [regex]::Matches($t, '(?im)^\s*(T\w+)\s*=\s*(?:packed\s+)?class\b(?!\s*(?:of\b|;))')) {
      $ppg[$e.Groups[1].Value] = $true
    }
  }
} else {
  Write-Warning "Quellordner nicht gefunden: $srcDir (nur Praefix TPPG zaehlt als PPGlow)."
}

# ---------------------------------------------------------------- KeepList
$keep = @{}
foreach ($k in $KeepList) {
  if ([string]::IsNullOrWhiteSpace($k)) { continue }
  if (Test-Path -LiteralPath $k -PathType Leaf) {
    if ($k -like '*.psd1') {
      $d = Import-PowerShellDataFile -LiteralPath $k
      $vals = @()
      if ($d -is [hashtable]) { foreach ($v in $d.Values) { $vals += @($v) } } else { $vals = @($d) }
      foreach ($v in $vals) { if ($v -is [string]) { $keep[$v.Trim()] = $true } }
    } else {
      foreach ($line in (Read-TextTolerant $k) -split "`r?`n") {
        $l = ($line -replace '#.*$', '').Trim()
        foreach ($c in ($l -split '[,;\s]+')) { if ($c) { $keep[$c] = $true } }
      }
    }
  } else {
    foreach ($c in ($k -split '[,;\s]+')) { if ($c) { $keep[$c] = $true } }
  }
}

function Get-Category([string]$Cls) {
  if ($Cls -like 'TPPG*' -or $ppg.ContainsKey($Cls)) { return 'PPGlow' }
  if ($keep.ContainsKey($Cls)) { return 'bleibt' }
  if ($migrated.ContainsKey($Cls)) { return 'migrierbar' }
  return 'offen'
}
$cats = @('PPGlow', 'migrierbar', 'bleibt', 'offen')

# ---------------------------------------------------------------- .dpr: uses-Liste
$dpr = Read-TextTolerant $Project
$dpr = [regex]::Replace($dpr, '(?s)\(\*.*?\*\)', ' ')
$dpr = [regex]::Replace($dpr, '(?s)\{.*?\}', ' ')
$dpr = [regex]::Replace($dpr, '(?m)//[^\r\n]*', ' ')
$um = [regex]::Match($dpr, '(?is)\buses\b(.*?);')
$units = New-Object System.Collections.Generic.List[object]
if ($um.Success) {
  foreach ($item in $um.Groups[1].Value -split ',') {
    $im = [regex]::Match($item, "^\s*([\w.]+)(?:\s+in\s+'([^']*)')?\s*$")
    if (-not $im.Success) { continue }
    $unit = $im.Groups[1].Value
    $rel = $im.Groups[2].Value
    if ($rel) { $pas = Join-Path $projDir ($rel -replace '/', '\') }
    else      { $pas = Join-Path $projDir ($unit + '.pas') }
    if (-not (Test-Path -LiteralPath $pas -PathType Leaf)) { continue }   # Bibliothek
    $units.Add([pscustomobject]@{ Unit = $unit; Pas = $pas; Dfm = [System.IO.Path]::ChangeExtension($pas, '.dfm') })
  }
}

# ---------------------------------------------------------------- DFMs auswerten
$forms = New-Object System.Collections.Generic.List[object]
$skipped = New-Object System.Collections.Generic.List[string]
$total = @{}     # Klasse -> Anzahl
$rx = [regex]'(?i)^\s*(?:object|inherited|inline)\s+[\w.]+\s*:\s*([\w.]+)'
$rootRx = [regex]'(?i)^(?:object|inherited|inline)\s+[\w.]+\s*:\s*([\w.]+)'

foreach ($u in $units) {
  if (-not (Test-Path -LiteralPath $u.Dfm -PathType Leaf)) { continue }
  $rel = $u.Dfm.Substring($projDir.Length).TrimStart('\')
  $b = New-Object byte[] 1
  $fs = [System.IO.File]::OpenRead($u.Dfm)
  try { [void]$fs.Read($b, 0, 1) } finally { $fs.Close() }
  if ($b[0] -eq 0xFF) { $skipped.Add($rel); continue }

  $lines = (Read-TextTolerant $u.Dfm) -split "`r?`n"
  $counts = @{}
  $rootCls = ''
  $first = $true
  foreach ($line in $lines) {
    $mm = $rx.Match($line)
    if (-not $mm.Success) { continue }
    $cls = $mm.Groups[1].Value
    if ($first) { $rootCls = $cls; $first = $false; continue }
    if ($counts.ContainsKey($cls)) { $counts[$cls]++ } else { $counts[$cls] = 1 }
    if ($total.ContainsKey($cls)) { $total[$cls]++ } else { $total[$cls] = 1 }
  }
  $row = [ordered]@{ Datei = $rel; Wurzel = $rootCls; PPGlow = 0; migrierbar = 0; bleibt = 0; offen = 0; Gesamt = 0 }
  foreach ($c in $counts.Keys) {
    $row[(Get-Category $c)] += $counts[$c]
    $row.Gesamt += $counts[$c]
  }
  $forms.Add([pscustomobject]$row)
}

# Summe je Klasse
$classRows = @($total.Keys | ForEach-Object {
  [pscustomobject]@{ Klasse = $_; Rubrik = (Get-Category $_); Anzahl = $total[$_] }
} | Sort-Object @{ Expression = 'Anzahl'; Descending = $true }, Klasse)

$complete = @($forms | Where-Object { $_.migrierbar -eq 0 -and $_.offen -eq 0 })
$sum = @{}
foreach ($c in $cats) { $sum[$c] = ($forms | Measure-Object -Property $c -Sum).Sum; if (-not $sum[$c]) { $sum[$c] = 0 } }

# ---------------------------------------------------------------- Ausgabe
$out = New-Object System.Collections.Generic.List[string]
$projName = [System.IO.Path]::GetFileName($Project)

function Md-Row($cells) { '| ' + (($cells | ForEach-Object { "$_" }) -join ' | ') + ' |' }

switch ($Format) {
  'csv' {
    $out.Add('Abschnitt;Datei/Klasse;Wurzel/Rubrik;PPGlow;migrierbar;bleibt;offen;Gesamt/Anzahl')
    foreach ($f in $forms) {
      $out.Add(('formular;{0};{1};{2};{3};{4};{5};{6}' -f $f.Datei, $f.Wurzel, $f.PPGlow, $f.migrierbar, $f.bleibt, $f.offen, $f.Gesamt))
    }
    foreach ($c in $classRows) { $out.Add(('klasse;{0};{1};;;;;{2}' -f $c.Klasse, $c.Rubrik, $c.Anzahl)) }
    foreach ($f in $complete) { $out.Add(('vollstaendig;{0};{1};;;;;' -f $f.Datei, $f.Wurzel)) }
    foreach ($s in $skipped) { $out.Add(('binaer;{0};;;;;;' -f $s)) }
  }
  'text' {
    $out.Add("Inventur $projName")
    $out.Add(("Formulare/Frames/Datenmodule: {0}, binaer uebersprungen: {1}" -f $forms.Count, $skipped.Count))
    $out.Add(("Komponenten: PPGlow {0}, migrierbar {1}, bleibt {2}, offen {3}" -f $sum.PPGlow, $sum.migrierbar, $sum.bleibt, $sum.offen))
    $out.Add('')
    $out.Add('Je Formular')
    $out.Add(('{0,-45} {1,-12} {2,7} {3,11} {4,7} {5,7}' -f 'Datei', 'Wurzel', 'PPGlow', 'migrierbar', 'bleibt', 'offen'))
    foreach ($f in $forms) {
      $out.Add(('{0,-45} {1,-12} {2,7} {3,11} {4,7} {5,7}' -f $f.Datei, $f.Wurzel, $f.PPGlow, $f.migrierbar, $f.bleibt, $f.offen))
    }
    $out.Add('')
    $out.Add('Je Klasse')
    foreach ($c in $classRows) { $out.Add(('{0,6}  {1,-11} {2}' -f $c.Anzahl, $c.Rubrik, $c.Klasse)) }
    $out.Add('')
    $out.Add('Vollstaendig PPGlow (keine migrierbaren/offenen Klassen)')
    if ($complete.Count -eq 0) { $out.Add('  (keine)') }
    foreach ($f in $complete) { $out.Add("  $($f.Datei)") }
    if ($skipped.Count -gt 0) {
      $out.Add('')
      $out.Add('Binaere DFMs (uebersprungen)')
      foreach ($s in $skipped) { $out.Add("  $s") }
    }
  }
  default {
    $out.Add("# Inventur $projName")
    $out.Add('')
    $out.Add(("- Formulare/Frames/Datenmodule mit DFM: **{0}** (binaer uebersprungen: {1})" -f $forms.Count, $skipped.Count))
    $out.Add(("- Komponenten gesamt: PPGlow **{0}**, migrierbar **{1}**, bleibt **{2}**, offen **{3}**" -f $sum.PPGlow, $sum.migrierbar, $sum.bleibt, $sum.offen))
    $out.Add('')
    $out.Add('## Je Formular')
    $out.Add('')
    $out.Add((Md-Row @('Datei', 'Wurzel', 'PPGlow', 'migrierbar', 'bleibt', 'offen')))
    $out.Add('|---|---|--:|--:|--:|--:|')
    foreach ($f in $forms) { $out.Add((Md-Row @($f.Datei, $f.Wurzel, $f.PPGlow, $f.migrierbar, $f.bleibt, $f.offen))) }
    $out.Add('')
    $out.Add('## Je Klasse')
    $out.Add('')
    $out.Add((Md-Row @('Klasse', 'Rubrik', 'Anzahl')))
    $out.Add('|---|---|--:|')
    foreach ($c in $classRows) { $out.Add((Md-Row @($c.Klasse, $c.Rubrik, $c.Anzahl))) }
    $out.Add('')
    $out.Add('## Vollstaendig PPGlow')
    $out.Add('')
    if ($complete.Count -eq 0) { $out.Add('Keines (alle Formulare enthalten noch migrierbare oder offene Klassen).') }
    foreach ($f in $complete) { $out.Add("- $($f.Datei) ($($f.Wurzel))") }
    if ($skipped.Count -gt 0) {
      $out.Add('')
      $out.Add('## Binaere DFMs (uebersprungen)')
      $out.Add('')
      foreach ($s in $skipped) { $out.Add("- $s") }
    }
  }
}

if ($OutFile) {
  $dir = Split-Path -Parent $OutFile
  if ($dir -and -not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
  [System.IO.File]::WriteAllLines($OutFile, $out.ToArray(), (New-Object System.Text.UTF8Encoding($true)))
  Write-Host "Inventur geschrieben: $OutFile ($($forms.Count) Formulare)"
} else {
  $out | ForEach-Object { Write-Output $_ }
}
exit 0
