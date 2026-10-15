<#
  PPGlow - Dateien fuer Setup und Release-ZIP zusammenstellen

  Kopiert genau die Dateien, die zum Bauen und Installieren der Pakete noetig
  sind, nach -Out: Quelltexte (Source), Paketprojekte (Packages\XE2, Delphi11,
  Delphi13), build.ps1/install.ps1 und die Installer-Hilfen. Grundlage ist
  "git ls-files": nur eingecheckte Dateien, keine Build-Ausgaben (.dcu, .bpl,
  .err, .res, .local).

  Aufruf:  powershell -ExecutionPolicy Bypass -File Installer\stage.ps1 -Out stage
#>
param([Parameter(Mandatory = $true)][string]$Out)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Include = @('Source', 'Packages/XE2', 'Packages/Delphi11', 'Packages/Delphi13',
  'Build/build.ps1', 'Build/install.ps1', 'Installer/run-install.ps1', 'Installer/LIESMICH.txt',
  'Docs/Kompatibilitaet.md')
$Exclude = '\.(dcu|dcp|bpl|err|res|rsm|local|identcache|exe)$'

$files = @(& git -C $Root ls-files -- $Include)
if ($LASTEXITCODE -ne 0) { throw 'git ls-files fehlgeschlagen' }
$files = @($files | Where-Object { $_ -notmatch $Exclude })
if ($files.Count -eq 0) { throw 'Keine Dateien gefunden' }

if (Test-Path $Out) { Remove-Item $Out -Recurse -Force }
New-Item -ItemType Directory -Force $Out | Out-Null
foreach ($f in $files) {
  $src = Join-Path $Root $f
  $dst = Join-Path $Out $f
  New-Item -ItemType Directory -Force (Split-Path -Parent $dst) | Out-Null
  Copy-Item $src $dst -Force
}
Write-Host ("{0} Dateien nach {1}" -f $files.Count, (Resolve-Path $Out))
