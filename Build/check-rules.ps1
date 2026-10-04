<#
  PPGlow Regel-Pruefer (Phase 9e)

  Prueft die verbindlichen Coding-Rules (Docs\Coding-Rules.md) OHNE Compiler.
  Laeuft deshalb auch auf Rechnern ohne Delphi und vor jedem Build.

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\check-rules.ps1
           [-Root <Ordner>] [-SkipLineEndings] [-SelfTest]
  Exit-Code = Anzahl der Verstoesse (0 = alles in Ordnung).

  Geprueft wird:
  - ASCII       nur ASCII-Zeichen in .pas/.dpr/.dpk/.inc
  - CRLF        Zeilenenden CRLF (RAD Studio)
  - INCLUDE     jede Unit unter Source bindet {$I ..\PPG.inc} vor "interface" ein
  - IFEND       jedes {$IF ...} wird mit {$IFEND} geschlossen (XE2)
  - INLINEVAR   keine Inline-Variablen und kein "for var" (erst ab 10.3)
  - SYNTAX      kein NameOf, keine Multiline-Strings ('''), kein if-Ausdruck,
                keine [weak]/[unsafe]-Attribute
  - COMMENT     kein "{" innerhalb eines { }-Kommentars (z. B. {$IF} im Text)
  - RAISE       nur PPGlow-Exceptions werfen (EPPG...), kein RaiseLastOSError
  - EXCEPT      kein leeres "except end"
  - PROJECT     jede Unit steht in allen Projektlisten ihrer Gruppe, und jede
                eingetragene Datei existiert

  -SelfTest prueft den Pruefer selbst an den Beispieldateien in
  Build\check-rules-tests (jede Datei nennt die erwarteten Regeln).
#>
param(
  [string]$Root = '',
  [switch]$SkipLineEndings,
  [switch]$SelfTest
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$Root = (Resolve-Path $Root).Path

$script:Findings = New-Object System.Collections.Generic.List[object]

function Add-Finding([string]$File, [int]$Line, [string]$Rule, [string]$Text) {
  $rel = $File
  if ($File.StartsWith($Root)) { $rel = $File.Substring($Root.Length).TrimStart('\', '/') }
  $script:Findings.Add([pscustomobject]@{ File = $rel; Line = $Line; Rule = $Rule; Text = $Text })
}

# ---------------------------------------------------------------------------
# Quelltext in Code und Direktiven zerlegen (Strings und Kommentare entfernt)
# ---------------------------------------------------------------------------

# Liefert je Zeile den reinen Code (Strings durch '' ersetzt, Kommentare
# entfernt) sowie die Liste der Direktiven mit Zeilennummer. Meldet dabei
# Kommentare, die ein "{" enthalten (Regel COMMENT).
function Split-Source([string]$File, [string[]]$Lines) {
  $code = New-Object string[] $Lines.Count
  $directives = New-Object System.Collections.Generic.List[object]
  $state = ''          # '' | 'brace' | 'paren' | 'directive'
  $dirText = ''
  $dirLine = 0
  for ($n = 0; $n -lt $Lines.Count; $n++) {
    $s = $Lines[$n]
    $sb = New-Object System.Text.StringBuilder
    $i = 0
    while ($i -lt $s.Length) {
      $c = $s[$i]
      if ($state -eq 'brace') {
        if ($c -eq '}') { $state = '' }
        elseif ($c -eq '{') { Add-Finding $File ($n + 1) 'COMMENT' 'Kommentar { } enthaelt ein "{" (endet sonst zu frueh)' }
        $i++; continue
      }
      if ($state -eq 'directive') {
        if ($c -eq '}') { $state = ''; $directives.Add([pscustomobject]@{ Line = $dirLine; Text = $dirText }) }
        else { $dirText += $c }
        $i++; continue
      }
      if ($state -eq 'paren') {
        if ($c -eq '*' -and $i + 1 -lt $s.Length -and $s[$i + 1] -eq ')') { $state = ''; $i += 2; continue }
        $i++; continue
      }
      if ($c -eq "'") {
        # String bis zum schliessenden ' ('' = Apostroph)
        $j = $i + 1
        while ($j -lt $s.Length) {
          if ($s[$j] -eq "'") {
            if ($j + 1 -lt $s.Length -and $s[$j + 1] -eq "'") { $j += 2; continue }
            break
          }
          $j++
        }
        [void]$sb.Append("''")
        $i = $j + 1; continue
      }
      if ($c -eq '/' -and $i + 1 -lt $s.Length -and $s[$i + 1] -eq '/') { break }
      if ($c -eq '{') {
        if ($i + 1 -lt $s.Length -and $s[$i + 1] -eq '$') {
          $state = 'directive'; $dirText = ''; $dirLine = $n + 1; $i += 2; continue
        }
        $state = 'brace'; $i++; continue
      }
      if ($c -eq '(' -and $i + 1 -lt $s.Length -and $s[$i + 1] -eq '*') { $state = 'paren'; $i += 2; continue }
      [void]$sb.Append($c)
      $i++
    }
    $code[$n] = $sb.ToString()
  }
  return @{ Code = $code; Directives = $directives }
}

# ---------------------------------------------------------------------------
# Regeln je Datei
# ---------------------------------------------------------------------------

function Test-SourceFile([string]$File, [bool]$IsSourceUnit) {
  $bytes = [IO.File]::ReadAllBytes($File)
  # ASCII
  $line = 1
  $reported = 0
  for ($k = 0; $k -lt $bytes.Length; $k++) {
    $b = $bytes[$k]
    if ($b -eq 10) { $line++ }
    elseif ($b -gt 127) {
      if ($reported -lt 5) { Add-Finding $File $line 'ASCII' ('Nicht-ASCII-Byte 0x{0:X2}' -f $b) }
      $reported++
      # Rest der Zeile ueberspringen
      while ($k + 1 -lt $bytes.Length -and $bytes[$k + 1] -ne 10) { $k++ }
    }
  }
  # CRLF
  if (-not $SkipLineEndings) {
    $line = 1
    $bad = 0
    for ($k = 0; $k -lt $bytes.Length; $k++) {
      if ($bytes[$k] -eq 10) {
        if ($k -eq 0 -or $bytes[$k - 1] -ne 13) {
          if ($bad -eq 0) { Add-Finding $File $line 'CRLF' 'Zeilenende ohne CR (RAD Studio braucht CRLF)' }
          $bad++
        }
        $line++
      }
    }
  }

  $text = [Text.Encoding]::ASCII.GetString($bytes)
  $lines = $text -split "`r?`n"
  $parts = Split-Source $File $lines
  $code = $parts.Code
  $dirs = $parts.Directives

  # IF / IFEND
  $stack = New-Object System.Collections.Generic.Stack[object]
  foreach ($d in $dirs) {
    $t = $d.Text.Trim()
    if ($t -match '^(?i)IF\s') { $stack.Push(@('IF', $d.Line)) }
    elseif ($t -match '^(?i)(IFDEF|IFNDEF|IFOPT)\b') { $stack.Push(@('IFDEF', $d.Line)) }
    elseif ($t -match '^(?i)IFEND\b') {
      if ($stack.Count -eq 0) { Add-Finding $File $d.Line 'IFEND' '{$IFEND} ohne {$IF}' }
      else {
        $top = $stack.Pop()
        if ($top[0] -ne 'IF') { Add-Finding $File $d.Line 'IFEND' "{`$IFEND} schliesst ein {`$IFDEF} aus Zeile $($top[1])" }
      }
    }
    elseif ($t -match '^(?i)ENDIF\b') {
      if ($stack.Count -eq 0) { Add-Finding $File $d.Line 'IFEND' '{$ENDIF} ohne {$IFDEF}' }
      else {
        $top = $stack.Pop()
        if ($top[0] -eq 'IF') { Add-Finding $File $d.Line 'IFEND' "{`$IF} aus Zeile $($top[1]) muss mit {`$IFEND} geschlossen werden (XE2)" }
      }
    }
  }
  foreach ($open in $stack) { Add-Finding $File $open[1] 'IFEND' 'Bedingte Direktive wird nicht geschlossen' }

  # INCLUDE: {$I ..\PPG.inc} vor "interface" (nur Units unter Source)
  if ($IsSourceUnit) {
    $ifaceLine = 0
    for ($n = 0; $n -lt $code.Count; $n++) {
      if ($code[$n] -match '^\s*interface\b') { $ifaceLine = $n + 1; break }
    }
    $inc = $dirs | Where-Object { $_.Text -match '^(?i)(I|INCLUDE)\s+\.\.[\\/]PPG\.inc\s*$' } | Select-Object -First 1
    if ($null -eq $inc) { Add-Finding $File 1 'INCLUDE' '{$I ..\PPG.inc} fehlt' }
    elseif ($ifaceLine -gt 0 -and $inc.Line -gt $ifaceLine) { Add-Finding $File $inc.Line 'INCLUDE' '{$I ..\PPG.inc} muss vor "interface" stehen' }
  }

  # Zeilenweise Muster auf dem reinen Code
  $depth = 0
  $prevEndsExcept = $false
  $prevExceptLine = 0
  for ($n = 0; $n -lt $code.Count; $n++) {
    $c = $code[$n]
    $ln = $n + 1
    if ($depth -eq 0 -and $c -match '^\s*var\s+[A-Za-z_]\w*\s*(,\s*[A-Za-z_]\w*\s*)*(:|:=)') {
      Add-Finding $File $ln 'INLINEVAR' 'Inline-Variable (erst ab Delphi 10.3)'
    }
    if ($c -match '(?i)\bfor\s+var\b') { Add-Finding $File $ln 'INLINEVAR' '"for var" (erst ab Delphi 10.3)' }
    if ($c -match '(?i)\bNameOf\s*\(') { Add-Finding $File $ln 'SYNTAX' 'NameOf (erst ab Delphi 12)' }
    if ($lines[$n] -match "(:=|\(|,|=|\+)\s*'''\s*$") { Add-Finding $File $ln 'SYNTAX' 'Multiline-String (erst ab Delphi 12)' }
    if ($c -match '(?i)(:=|\()\s*if\b.*\bthen\b.*\belse\b') { Add-Finding $File $ln 'SYNTAX' 'if-Ausdruck (erst ab Delphi 13)' }
    if ($c -match '(?i)\[\s*(weak|unsafe)\s*\]') { Add-Finding $File $ln 'SYNTAX' '[weak]/[unsafe] ist verboten' }
    # Nur fuer die Bibliothek; Tests und Demo werfen absichtlich fremde Exceptions
    if ($IsSourceUnit -and $c -match '\braise\s+(E\w+|Exception)\s*\.\s*Create') {
      if ($Matches[1] -notmatch '^EPPG') { Add-Finding $File $ln 'RAISE' "Nur PPGlow-Exceptions werfen (gefunden: $($Matches[1]))" }
    }
    if ($IsSourceUnit -and $c -match '(?<![\w.])RaiseLastOSError\b') { Add-Finding $File $ln 'RAISE' 'PPGRaiseLastOSError statt RaiseLastOSError verwenden' }
    # leeres except ... end (auch ueber Zeilen)
    $trim = $c.Trim()
    if ($trim -match '(?i)^except\s+end\s*;?$' -or $trim -match '(?i)\bexcept\s+end\s*;') {
      Add-Finding $File $ln 'EXCEPT' 'Leeres "except end"'
    }
    elseif ($prevEndsExcept -and $trim -match '(?i)^end\b') {
      Add-Finding $File $prevExceptLine 'EXCEPT' 'Leeres "except end"'
    }
    if ($trim -ne '') {
      $prevEndsExcept = $trim -match '(?i)\bexcept$'
      $prevExceptLine = $ln
    }
    # Klammertiefe fuer die Erkennung von Parameterlisten ueber mehrere Zeilen
    foreach ($ch in $c.ToCharArray()) {
      if ($ch -eq '(') { $depth++ }
      elseif ($ch -eq ')' -and $depth -gt 0) { $depth-- }
    }
  }
}

# ---------------------------------------------------------------------------
# Projektlisten
# ---------------------------------------------------------------------------

# Gruppen: welche Units (Ordner) in welche Projektdateien gehoeren
$Groups = @(
  @{ Name = 'Runtime'; Folders = @('Source\Core', 'Source\Render', 'Source\Theme', 'Source\Access', 'Source\Controls');
     Lists = @('Packages\Delphi13\PPGlowR.dpk', 'Packages\Delphi13\PPGlowR.dproj', 'Packages\XE2\PPGlowR.dpk',
               'Tests\PPGlowTests.dpr', 'Tests\PPGlowTests.dproj', 'Demo\PPGlowDemo.dpr', 'Demo\PPGlowDemo.dproj',
               'Tests\Bench\PPGlowBench.dpr') },
  @{ Name = 'Design'; Folders = @('Source\Design');
     Lists = @('Packages\Delphi13\dclPPGlow.dpk', 'Packages\Delphi13\dclPPGlow.dproj', 'Packages\XE2\dclPPGlow.dpk') },
  @{ Name = 'DB'; Folders = @('Source\DB');
     Lists = @('Packages\Delphi13\PPGlowDBR.dpk', 'Packages\Delphi13\PPGlowDBR.dproj', 'Packages\XE2\PPGlowDBR.dpk',
               'Tests\PPGlowTests.dpr', 'Tests\PPGlowTests.dproj') },
  @{ Name = 'DesignDB'; Folders = @('Source\DesignDB');
     Lists = @('Packages\Delphi13\dclPPGlowDB.dpk', 'Packages\Delphi13\dclPPGlowDB.dproj', 'Packages\XE2\dclPPGlowDB.dpk') }
)

function Join-RootPath([string]$Rel) {
  return Join-Path $Root ($Rel -replace '[\\/]', [IO.Path]::DirectorySeparatorChar)
}

# Liefert die eingetragenen .pas-Dateien einer Projektdatei als volle Pfade.
function Get-ListedUnits([string]$ListFile) {
  $dir = Split-Path -Parent $ListFile
  $text = [IO.File]::ReadAllText($ListFile)
  $result = @()
  if ($ListFile -like '*.dproj') {
    foreach ($m in [regex]::Matches($text, '<DCCReference\s+Include="([^"]+\.pas)"')) { $result += $m.Groups[1].Value }
  }
  else {
    foreach ($m in [regex]::Matches($text, "\bin\s+'([^']+\.pas)'")) { $result += $m.Groups[1].Value }
  }
  return $result | ForEach-Object {
    $p = Join-Path $dir ($_ -replace '[\\/]', [IO.Path]::DirectorySeparatorChar)
    [IO.Path]::GetFullPath($p)
  }
}

function Test-ProjectLists {
  foreach ($g in $Groups) {
    $units = @()
    foreach ($f in $g.Folders) {
      $dir = Join-RootPath $f
      if (Test-Path $dir) { $units += Get-ChildItem -Path $dir -Filter '*.pas' -File | ForEach-Object { $_.FullName } }
    }
    if ($units.Count -eq 0) { continue }
    foreach ($l in $g.Lists) {
      $lf = Join-RootPath $l
      if (-not (Test-Path $lf)) {
        Add-Finding $lf 0 'PROJECT' "Projektdatei fehlt (Gruppe $($g.Name))"
        continue
      }
      $listed = Get-ListedUnits $lf
      foreach ($u in $units) {
        if ($listed -notcontains $u) {
          Add-Finding $lf 0 'PROJECT' "Unit fehlt: $([IO.Path]::GetFileName($u))"
        }
      }
    }
  }
  # Jede eingetragene Datei muss existieren
  $allLists = $Groups | ForEach-Object { $_.Lists } | Sort-Object -Unique
  foreach ($l in $allLists) {
    $lf = Join-RootPath $l
    if (-not (Test-Path $lf)) { continue }
    foreach ($u in (Get-ListedUnits $lf)) {
      if (-not (Test-Path $u)) { Add-Finding $lf 0 'PROJECT' "Eingetragene Datei existiert nicht: $u" }
    }
  }
}

# ---------------------------------------------------------------------------
# Lauf
# ---------------------------------------------------------------------------

function Invoke-Check([string[]]$Files, [bool]$WithProjects) {
  $script:Findings.Clear()
  foreach ($f in $Files) {
    $isSource = $f -match '[\\/]Source[\\/].+\.pas$'
    Test-SourceFile $f $isSource
  }
  if ($WithProjects) { Test-ProjectLists }
}

if ($SelfTest) {
  # Jede Beispieldatei beginnt mit "// expect: REGEL1 REGEL2" (oder "// expect: none")
  $dir = Join-Path $PSScriptRoot 'check-rules-tests'
  $failed = 0
  foreach ($f in Get-ChildItem -Path $dir -Filter '*.pas' -File) {
    $first = (Get-Content -Path $f.FullName -TotalCount 1)
    $expected = @()
    if ($first -match '^//\s*expect:\s*(.+)$') { $expected = @($Matches[1].Trim() -split '\s+' | Where-Object { $_ -ne 'none' }) }
    $isSource = $first -match 'source-unit'
    $script:Findings.Clear()
    Test-SourceFile $f.FullName $isSource
    $got = @($script:Findings | ForEach-Object { $_.Rule } | Sort-Object -Unique)
    $want = @($expected | Where-Object { $_ -ne 'source-unit' } | Sort-Object -Unique)
    if ((Compare-Object -ReferenceObject $want -DifferenceObject $got -SyncWindow 0) -ne $null -or $want.Count -ne $got.Count) {
      Write-Output ("FEHLER {0}: erwartet [{1}], gefunden [{2}]" -f $f.Name, ($want -join ' '), ($got -join ' '))
      $script:Findings | ForEach-Object { Write-Output ("    {0}({1}) {2}: {3}" -f $_.File, $_.Line, $_.Rule, $_.Text) }
      $failed++
    }
    else {
      Write-Output ("ok     {0}: [{1}]" -f $f.Name, ($got -join ' '))
    }
  }
  exit $failed
}

$files = @()
foreach ($d in @('Source', 'Tests', 'Demo', 'Packages')) {
  $p = Join-Path $Root $d
  if (Test-Path $p) {
    $files += Get-ChildItem -Path $p -Recurse -File -Include '*.pas', '*.dpr', '*.dpk', '*.inc' | ForEach-Object { $_.FullName }
  }
}
Invoke-Check $files $true

foreach ($f in ($script:Findings | Sort-Object File, Line)) {
  Write-Output ("{0}({1}) {2}: {3}" -f $f.File, $f.Line, $f.Rule, $f.Text)
}
if ($script:Findings.Count -eq 0) {
  Write-Output ("Regel-Pruefer: {0} Dateien, keine Verstoesse." -f $files.Count)
}
else {
  Write-Output ("Regel-Pruefer: {0} Verstoesse in {1} Dateien." -f $script:Findings.Count, $files.Count)
}
exit $script:Findings.Count
