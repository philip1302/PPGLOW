# Startet die Demo (immer mit /hidden anhaengen!); nur ein Lauf gleichzeitig (Mutex).
# Aufruf: powershell -ExecutionPolicy Bypass -File run-lock.ps1 -Exe <Worktree>\Demo\PPGlowDemo.exe -Arguments '/selftest','C:\x.txt','/only','TPPGEdit','/hidden'
param([Parameter(Mandatory = $true)][string]$Exe, [string[]]$Arguments = @())
$m = New-Object System.Threading.Mutex($false, 'Local\PPGlowDemoRun')
try { [void]$m.WaitOne() } catch [System.Threading.AbandonedMutexException] { }
# Ueber 'powershell -File' kommt die Liste als ein Text 'a,b,c' an: aufteilen
if (($Arguments.Count -eq 1) -and ($Arguments[0] -match ',')) { $Arguments = $Arguments[0] -split ',' }
$code = 1
try {
  $p = Start-Process -FilePath $Exe -ArgumentList $Arguments -Wait -PassThru
  $code = $p.ExitCode
} finally { $m.ReleaseMutex(); $m.Dispose() }
Write-Output "ExitCode: $code"
exit $code
