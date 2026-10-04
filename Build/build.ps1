<#
  PPGlow Build-Skript

  Baut Runtime-Package, Design-Package, Tests und Demo fuer alle gefundenen
  RAD-Studio-Versionen.

  - Editionen mit Kommandozeilen-Compiler (Professional+): msbuild ueber rsvars.bat
  - Community/Starter (kein dcc32 auf der Kommandozeile): IDE-Batchbuild "bds -b",
    Ausgabe in <Projekt>.err

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\build.ps1 [-Only Delphi13] [-Projects Runtime,Tests]
           Projekte: Runtime, Design, DBRuntime, DBDesign, Tests, Demo (Standard) sowie Bench
           (Leistungsmessung, am besten -Config Release). DBRuntime/DBDesign = DB-Controls (PPGlowDBR/dclPPGlowDB)
           Vorher laeuft check-rules.ps1 (Coding-Rules); -NoRuleCheck laesst ihn aus
#>
param(
  [string]$Only = '',
  [string[]]$Projects = @('Runtime', 'Design', 'DBRuntime', 'DBDesign', 'Tests', 'Demo'),
  [int]$TimeoutSec = 600,
  [ValidateSet('Win32', 'Win64')][string]$Platform = 'Win32',
  [ValidateSet('Debug', 'Release')][string]$Config = 'Debug',
  # Regel-Pruefer (check-rules.ps1) vor dem Build auslassen
  [switch]$NoRuleCheck
)

$ErrorActionPreference = 'Stop'
$BuildProfile = 'PPGlowBuild'   # HKCU\Software\Embarcadero\PPGlowBuild - nur fuer Batch-Builds
# -File uebergibt Arrays als einen String ("A,B") -> aufteilen
$Projects = @($Projects | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$Root = Split-Path -Parent $PSScriptRoot

# Studio-Version -> Ordnername unter Packages\
$Versions = [ordered]@{
  '9.0'  = 'XE2'
  '37.0' = 'Delphi13'
}

$ProjectFiles = @{
  'Runtime' = 'Packages\{0}\PPGlowR.dproj'
  'Design'  = 'Packages\{0}\dclPPGlow.dproj'
  'DBRuntime' = 'Packages\{0}\PPGlowDBR.dproj'
  'DBDesign'  = 'Packages\{0}\dclPPGlowDB.dproj'
  'Tests'   = 'Tests\PPGlowTests.dproj'
  'Demo'    = 'Demo\PPGlowDemo.dproj'
  'Bench'   = 'Tests\Bench\PPGlowBench.dproj'
}

function Get-StudioDir([string]$Ver) {
  $key = "HKCU:\Software\Embarcadero\BDS\$Ver"
  if (-not (Test-Path $key)) { return $null }
  return (Get-ItemProperty $key).RootDir
}

function Test-CommandLineCompiler([string]$StudioDir) {
  $out = & (Join-Path $StudioDir 'bin\dcc32.exe') '--version' 2>&1 | Out-String
  return ($out -notmatch 'does not support command line')
}

function Invoke-IdeBuild([string]$StudioDir, [string]$Project) {
  # "bds -b" baut immer die Vorgabe-Konfiguration/-Plattform des Projekts.
  # Fuer andere Ziele wird die Vorgabe in der .dproj kurzzeitig umgestellt und
  # danach exakt wiederhergestellt (auch falls die IDE die Datei anfasst).
  $original = $null
  if ($Project -like '*.dproj') {
    $original = [IO.File]::ReadAllText($Project)
    $patched = $original -replace "<Config Condition=`"'\`$\(Config\)'==''`">\w+</Config>", "<Config Condition=`"'`$(Config)'==''`">$Config</Config>"
    $patched = $patched -replace "<Platform Condition=`"'\`$\(Platform\)'==''`">\w+</Platform>", "<Platform Condition=`"'`$(Platform)'==''`">$Platform</Platform>"
    if (($original -notmatch "<Config Condition=`"'\`$\(Config\)'==''`">") -or
        ($original -notmatch "<Platform Condition=`"'\`$\(Platform\)'==''`">")) {
      Write-Host "    Hinweis: Vorgabe in $Project nicht umstellbar - baue Projekt-Vorgabe" -ForegroundColor DarkYellow
    }
    [IO.File]::WriteAllText($Project, $patched)
  }
  try {
    return Invoke-IdeBuildCore $StudioDir $Project
  } finally {
    if ($original -ne $null) { [IO.File]::WriteAllText($Project, $original) }
  }
}

if (-not ('PPGBuildWin' -as [type])) {
  Add-Type @"
using System; using System.Text; using System.Runtime.InteropServices;
public static class PPGBuildWin {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr w, EnumProc p, IntPtr l);
  [DllImport("user32.dll")] static extern int GetWindowThreadProcessId(IntPtr h, out int pid);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] static extern bool IsWindowEnabled(IntPtr h);
  [DllImport("user32.dll")] static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  // Klickt "OK" im Fortschrittsdialog (TProgressForm) der IDE-Instanz pid.
  public static int ClickProgressOk(int pid) { return ClickOkIn(pid, "TProgressForm"); }
  // Klickt "OK" im Lizenzhinweis der Community Edition (TCENotificationDialog),
  // der zufaellig beim Kompilieren erscheint und den Batch-Build anhaelt.
  // Nur in der eigenen IDE-Instanz pid (Profil PPGlowBuild), nie in anderen.
  public static int ClickNoticeOk(int pid) { return ClickOkIn(pid, "TCENotificationDialog"); }
  static int ClickOkIn(int pid, string cls) {
    int n = 0;
    EnumWindows((h, l) => {
      int p; GetWindowThreadProcessId(h, out p);
      if (p != pid) return true;
      var c = new StringBuilder(256); GetClassName(h, c, 256);
      if (c.ToString() != cls) return true;
      EnumChildWindows(h, (b, l2) => {
        var t = new StringBuilder(64); GetWindowText(b, t, 64);
        if (t.ToString() == "OK" && IsWindowEnabled(b)) { PostMessage(b, 0x00F5, IntPtr.Zero, IntPtr.Zero); n++; }
        return true; }, IntPtr.Zero);
      return true; }, IntPtr.Zero);
    return n;
  }
}
"@
}

function Invoke-IdeBuildCore([string]$StudioDir, [string]$Project) {
  $bds = Join-Path $StudioDir 'bin\bds.exe'
  $err = [IO.Path]::ChangeExtension($Project, '.err')
  if (Test-Path $err) { Remove-Item $err -Force }
  # Eigenes IDE-Profil (-r): ohne installierte Packages (die IDE verweigert sonst
  # das Kompilieren eines Packages, das sie selbst geladen hat, und haengt mit
  # unsichtbarem Dialog) und ohne die Einstellungen des Entwicklers anzufassen.
  $p = Start-Process -FilePath $bds -ArgumentList "-r$BuildProfile", '-pDelphi', '-ns', '-b', "`"$Project`"" -PassThru
  # Die IDE beendet sich nach "-b" nicht immer (z.B. Dialog im Hintergrund).
  # Deshalb auf das Abschlusskennzeichen in der .err-Datei warten und die
  # eigene IDE-Instanz danach notfalls beenden.
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  $text = ''
  while ((Get-Date) -lt $deadline) {
    if ($p.HasExited) { break }
    # Bei Compilerfehlern wartet die IDE im Fortschrittsdialog auf "OK" und
    # schreibt die .err-Datei erst danach -> Dialog bestaetigen
    [void][PPGBuildWin]::ClickProgressOk($p.Id)
    # Lizenzhinweis der Community Edition (vom User freigegeben, 04.10.2026)
    [void][PPGBuildWin]::ClickNoticeOk($p.Id)
    if (Test-Path $err) {
      $text = Get-Content $err -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
      if ($text -match '(Erfolg|Misslungen|Success|Failed)') { break }
    }
    Start-Sleep -Milliseconds 500
  }
  if (-not $p.HasExited) {
    # Erst regulaer schliessen: ein harter Kill reisst die Hilfsprozesse der
    # IDE (DelphiLSP, GetIt-Helper) mit und erzeugt "Runtime error"-Meldungen.
    Start-Sleep -Seconds 2
    if (-not $p.HasExited) { [void]$p.CloseMainWindow() }
    if (-not $p.WaitForExit(30000)) {
      Write-Host "    Warnung: IDE reagiert nicht auf Schliessen - wird hart beendet" -ForegroundColor DarkYellow
      $p | Stop-Process -Force
    }
  }
  if (-not (Test-Path $err)) { throw "Keine Build-Ausgabe ($err) fuer $Project (Timeout?)" }
  $text = Get-Content $err -Raw -Encoding UTF8
  $problems = ($text -split "`r?`n") | Where-Object { $_ -match '\[dcc(32|64) (Fehler|Fataler Fehler|Error|Fatal|Warnung|Warning|Hinweis|Hint)\]' }
  $failed = $text -match '(Misslungen|Failed|Fehler beim Erzeugen)'
  return [pscustomobject]@{ Failed = $failed; Problems = $problems; Log = $text }
}

function Invoke-MsBuild([string]$StudioDir, [string]$Project, [string]$Platform) {
  $rsvars = Join-Path $StudioDir 'bin\rsvars.bat'
  $cmd = "call `"$rsvars`" && msbuild `"$Project`" /t:Build /p:Config=$Config /p:Platform=$Platform /nologo /v:minimal"
  $text = cmd /c $cmd 2>&1 | Out-String
  $problems = ($text -split "`r?`n") | Where-Object { $_ -match ': (error|warning|hint) ' }
  return [pscustomobject]@{ Failed = ($LASTEXITCODE -ne 0); Problems = $problems; Log = $text }
}

# Zuerst die Coding-Rules pruefen: ein Verstoss (z.B. Unit fehlt in einer
# Projektliste, Inline-Variable) faellt sonst erst beim XE2-Build auf.
if (-not $NoRuleCheck) {
  & (Join-Path $PSScriptRoot 'check-rules.ps1') -Root $Root
  if ($LASTEXITCODE -ne 0) {
    Write-Host "Regel-Pruefer meldet Verstoesse - Build abgebrochen (-NoRuleCheck zum Uebergehen)" -ForegroundColor Red
    exit 1
  }
}

$total = 0; $failedCount = 0
foreach ($ver in $Versions.Keys) {
  $folder = $Versions[$ver]
  if ($Only -and $Only -ne $folder) { continue }
  $studio = Get-StudioDir $ver
  if (-not $studio) { Write-Host "[$folder] nicht installiert - uebersprungen" -ForegroundColor DarkGray; continue }
  $cmdLine = Test-CommandLineCompiler $studio
  Write-Host "[$folder] $studio (Kommandozeilen-Compiler: $cmdLine), $Platform/$Config" -ForegroundColor Cyan

  foreach ($name in $Projects) {
    $proj = Join-Path $Root ($ProjectFiles[$name] -f $folder)
    # Ohne .dproj (z.B. aeltere Delphi-Version): Quelle direkt, die IDE erzeugt das .dproj
    foreach ($ext in '.dpr', '.dpk') {
      $alt = [IO.Path]::ChangeExtension($proj, $ext)
      if (-not (Test-Path $proj) -and (Test-Path $alt)) { $proj = $alt }
    }
    if (-not (Test-Path $proj)) { Write-Host "  $name : $proj fehlt - uebersprungen" -ForegroundColor DarkYellow; continue }
    $total++
    if ($cmdLine) { $r = Invoke-MsBuild $studio $proj $Platform } else { $r = Invoke-IdeBuild $studio $proj }
    if ($r.Failed) {
      $failedCount++
      Write-Host "  $name : FEHLER" -ForegroundColor Red
    } elseif ($r.Problems) {
      Write-Host "  $name : OK mit Meldungen" -ForegroundColor Yellow
    } else {
      Write-Host "  $name : OK" -ForegroundColor Green
    }
    $r.Problems | ForEach-Object { Write-Host "    $_" }
  }
}

Write-Host ""
Write-Host "Projekte: $total, fehlgeschlagen: $failedCount"
if ($failedCount -gt 0) { exit 1 }
exit 0
