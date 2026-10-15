<#
  PPGlow - Aufruf von Build\install.ps1 aus dem Setup (Installer\PPGlow.iss)

  Schreibt ein Protokoll (-LogFile) und liefert einen eindeutigen Exit-Code:
  0 = installiert bzw. entfernt, sonst Fehler (Details im Protokoll).
  Der Regel-Pruefer laeuft hier nicht (-NoRuleCheck): im Setup fehlen Tests
  und Demo, die er erwartet; geprueft wird vor jedem Release in der CI.

  Aufruf:  powershell -ExecutionPolicy Bypass -File Installer\run-install.ps1
           -Version 22.0 [-Platforms Win32,Win64] [-NoDB] [-Uninstall] [-LogFile <Datei>]
#>
param(
  [Parameter(Mandatory = $true)][string]$Version,
  [string]$Platforms = 'Win32,Win64',
  [switch]$NoDB,
  [switch]$Uninstall,
  [string]$LogFile = ''
)

$transcript = $false
if ($LogFile) {
  try {
    New-Item -ItemType Directory -Force (Split-Path -Parent $LogFile) | Out-Null
    Start-Transcript -Path $LogFile -Force | Out-Null
    $transcript = $true
  } catch {
    Write-Host "Protokoll nicht moeglich: $($_.Exception.Message)" -ForegroundColor DarkYellow
  }
}

$code = 1
try {
  $install = Join-Path (Split-Path -Parent $PSScriptRoot) 'Build\install.ps1'
  $global:LASTEXITCODE = 0
  if ($Uninstall) {
    & $install -Version $Version -Platforms $Platforms -Uninstall
  } else {
    & $install -Version $Version -Platforms $Platforms -NoDB:$NoDB -NoRuleCheck
  }
  $code = $LASTEXITCODE
} catch {
  Write-Host "FEHLER: $($_.Exception.Message)" -ForegroundColor Red
  $code = 1
} finally {
  if ($transcript) { try { Stop-Transcript | Out-Null } catch { } }
}
exit $code
