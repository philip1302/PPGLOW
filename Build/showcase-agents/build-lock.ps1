# Baut ein PPGlow-Projekt in einem Worktree; nur ein Batch-Build gleichzeitig (Mutex).
# Aufruf: powershell -ExecutionPolicy Bypass -File build-lock.ps1 -Root C:\AI\Claude_Arbeitsplatz\PPGlow-sc-Edit [-Projects Demo] [-Only Delphi13]
# -Only waehlt die Delphi-Version (Ordner unter Packages\). Vorgabe bleibt Delphi13: die Demo ist nur dafuer angelegt.
param([Parameter(Mandatory = $true)][string]$Root, [string[]]$Projects = @('Demo'), [string]$Only = 'Delphi13')
$m = New-Object System.Threading.Mutex($false, 'Local\PPGlowIdeBuild')
try { [void]$m.WaitOne() } catch [System.Threading.AbandonedMutexException] { }
$code = 1
try {
  & (Join-Path $Root 'Build\build.ps1') -Only $Only -Projects $Projects
  $code = $LASTEXITCODE
} finally { $m.ReleaseMutex(); $m.Dispose() }
exit $code
