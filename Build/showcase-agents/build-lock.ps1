# Baut ein PPGlow-Projekt in einem Worktree; nur ein Batch-Build gleichzeitig (Mutex).
# Aufruf: powershell -ExecutionPolicy Bypass -File build-lock.ps1 -Root C:\AI\Claude_Arbeitsplatz\PPGlow-sc-Edit [-Projects Demo]
param([Parameter(Mandatory = $true)][string]$Root, [string[]]$Projects = @('Demo'))
$m = New-Object System.Threading.Mutex($false, 'Local\PPGlowIdeBuild')
try { [void]$m.WaitOne() } catch [System.Threading.AbandonedMutexException] { }
$code = 1
try {
  & (Join-Path $Root 'Build\build.ps1') -Only Delphi13 -Projects $Projects
  $code = $LASTEXITCODE
} finally { $m.ReleaseMutex(); $m.Dispose() }
exit $code
