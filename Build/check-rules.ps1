<#
  PPGlow Regel-Pruefer (Phase 9e, erweitert in Audit 11d)

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
  - EXCEPT      kein leeres "except end"; in Source ein "except" ohne "on"-Filter
                (oder mit "on E: Exception") und ohne raise/Abort nur an einer
                Grenze (Kommentar "Grenze" bis 6 Zeilen davor oder im Handler)
                oder in Source\Access, PPG.ErrorHandler, PPG.Animation
  - DB          Data.*, Datasnap.*, Vcl.DB*, MidasLib nur in Source\DB und
                Source\DesignDB (geprueft wird Source)
  - DESIGN      DesignIntf, DesignEditors, VCLEditors, ToolsAPI, ColnEdit ...
                nur in Source\Design und Source\DesignDB
  - UNITS       keine unqualifizierten RTL/VCL-Units in uses (Windows statt
                Winapi.Windows ...) in Source, Tests, Demo
  - IMAGEINDEX  TImageIndex nur in PPG.Types (sonst TPPGImageIndex)
  - TIMER       TTimer/SetTimer/KillTimer in Source nur in PPG.Animation
  - LAYER       Schichten in Source: eine Unit nutzt nur erlaubte Schichten
                (Core -> Core; Render -> Core, Render; ...; siehe $LayerAllowed)
  - TEXT        kein Caption/Hint/Text := 'Literal' (>= 2 Buchstaben) in Source
                ausser Design, DesignDB, Editors (Texte ueber PPGStr)
  - XE2         Verbotsliste: FMod; unqualifiziertes TCollectionNotification/
                cnAdded... in Units mit System.Generics.Collections;
                DocumentProperties(...) mit nil
  - PROJECT     jede Unit steht in allen Projektlisten ihrer Gruppe, und jede
                eingetragene Datei existiert
  - REQUIRES    die requires-Liste jedes Pakets ist in Packages\XE2 und
                Packages\Delphi13 gleich
  - LANG        jede resourcestring ist in Lang\PPGlow.*.txt uebersetzt, die
                Platzhalter passen, und die erzeugten PPG.Lang.*.pas sind aktuell
                (Build\make-lang.ps1 -Check)
  - TESTS       Testintegritaet in Tests\*.pas: kein CheckTrue(True)/
                Check(True)/CheckFalse(False); Check/Fail in einem try, dessen
                except alles faengt (ohne "on", "on Exception", "on EAbort",
                "on ETestFailure", "else") ohne raise bzw. Klassenpruefung
                (DUnits ETestFailure erbt von EAbort); Exit in einer published
                Testmethode vor der ersten Pruefung nur direkt nach Skip(...)

  -SelfTest prueft den Pruefer selbst an den Beispieldateien in
  Build\check-rules-tests: jede .pas-Datei nennt in Zeile 1 die erwarteten
  Regeln ("// expect: REGEL ..."), optional in den Zeilen 2 und 3 den Pfad, als
  laege sie im Projekt ("// path: Source\Core\X.pas"), und die Zahl der
  Meldungen ("// count: 2"). Jeder Unterordner ist ein kleines
  Projekt fuer die Regeln ueber mehrere Dateien (PROJECT, REQUIRES, LANG);
  seine expect.txt nennt die Regeln und mit "text:" Teile der Meldungen.
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
# Listen fuer die Regeln
# ---------------------------------------------------------------------------

# Unqualifizierte RTL/VCL-Unitnamen (Regel UNITS). Voll qualifiziert lauten sie
# Winapi.Windows, System.SysUtils, Vcl.Controls ...
$UnqualifiedUnits = @(
  'Windows', 'Messages', 'SysUtils', 'Classes', 'Graphics', 'Controls', 'Forms', 'Math', 'Types',
  'Variants', 'StdCtrls', 'ExtCtrls', 'ImgList', 'Dialogs', 'ComCtrls', 'Menus', 'Buttons', 'Grids',
  'Mask', 'CheckLst', 'ActnList', 'ToolWin', 'Clipbrd', 'Printers', 'Themes', 'GraphUtil', 'CommCtrl',
  'ShellAPI', 'ShlObj', 'ActiveX', 'ComObj', 'MultiMon', 'UxTheme', 'DwmApi', 'MMSystem', 'Imm',
  'RichEdit', 'WinSpool', 'UITypes', 'StrUtils', 'DateUtils', 'IniFiles', 'Registry', 'SyncObjs',
  'Character', 'Contnrs', 'TypInfo', 'Rtti', 'IOUtils', 'Masks', 'RTLConsts', 'Consts', 'ZLib',
  'Generics.Collections', 'Generics.Defaults', 'DB', 'DBCtrls', 'DBGrids', 'DBClient', 'Jpeg',
  'pngimage', 'GIFImg', 'AppEvnts', 'ExtDlgs', 'FileCtrl', 'Tabs', 'ValEdit', 'ImageList', 'UIConsts',
  'Diagnostics', 'TimeSpan', 'StdActns', 'OleCtrls', 'Hash', 'NetEncoding', 'SqlTimSt', 'FMTBcd'
)

# Units der Entwicklungsumgebung (Regel DESIGN)
$DesignUnits = @('DesignIntf', 'DesignEditors', 'VCLEditors', 'ToolsAPI', 'ColnEdit', 'DesignMenus',
  'DesignWindows', 'PropInspAPI', 'TreeIntf')

# Schichtmatrix (Regel LAYER): Schicht (Ordner unter Source) -> erlaubte Schichten
# der PPGlow-Units in ihren uses-Klauseln
$LayerAllowed = @{
  'Core'     = @('Core')
  'Render'   = @('Core', 'Render')
  'Theme'    = @('Core', 'Render', 'Theme')
  'Access'   = @('Core', 'Render', 'Theme', 'Access')
  'Controls' = @('Core', 'Render', 'Theme', 'Access', 'Controls')
  'DB'       = @('Core', 'Render', 'Theme', 'Access', 'Controls', 'DB')
  'Editors'  = @('Core', 'Render', 'Theme', 'Access', 'Controls', 'Editors')
  'Design'   = @('Core', 'Render', 'Theme', 'Access', 'Controls', 'DB', 'Editors', 'Design', 'DesignDB')
  'DesignDB' = @('Core', 'Render', 'Theme', 'Access', 'Controls', 'DB', 'Editors', 'Design', 'DesignDB')
}

# Unit-Name -> Schicht, aus dem Dateisystem (Source\<Schicht>\<Unit>.pas)
$script:UnitLayers = @{}
function Update-UnitLayers {
  $script:UnitLayers = @{}
  $src = Join-Path $Root 'Source'
  if (-not (Test-Path $src)) { return }
  foreach ($d in Get-ChildItem -Path $src -Directory) {
    foreach ($f in Get-ChildItem -Path $d.FullName -Filter '*.pas' -File) {
      $script:UnitLayers[$f.BaseName] = $d.Name
    }
  }
}

# ---------------------------------------------------------------------------
# Quelltext in Code und Direktiven zerlegen (Strings und Kommentare entfernt)
# ---------------------------------------------------------------------------

# Liefert je Zeile den reinen Code (Strings durch '' ersetzt, Kommentare
# entfernt), den Code mit Strings (Literal), den Kommentartext sowie die Liste
# der Direktiven mit Zeilennummer. Meldet dabei Kommentare, die ein "{"
# enthalten (Regel COMMENT).
function Split-Source([string]$File, [string[]]$Lines) {
  $code = New-Object string[] $Lines.Count
  $literal = New-Object string[] $Lines.Count
  $comments = New-Object string[] $Lines.Count
  $directives = New-Object System.Collections.Generic.List[object]
  $state = ''          # '' | 'brace' | 'paren' | 'directive'
  $dirText = ''
  $dirLine = 0
  for ($n = 0; $n -lt $Lines.Count; $n++) {
    $s = $Lines[$n]
    $sb = New-Object System.Text.StringBuilder
    $sl = New-Object System.Text.StringBuilder
    $cm = New-Object System.Text.StringBuilder
    $i = 0
    while ($i -lt $s.Length) {
      $c = $s[$i]
      if ($state -eq 'brace') {
        if ($c -eq '}') { $state = '' }
        else {
          [void]$cm.Append($c)
          if ($c -eq '{') { Add-Finding $File ($n + 1) 'COMMENT' 'Kommentar { } enthaelt ein "{" (endet sonst zu frueh)' }
        }
        $i++; continue
      }
      if ($state -eq 'directive') {
        if ($c -eq '}') { $state = ''; $directives.Add([pscustomobject]@{ Line = $dirLine; Text = $dirText }) }
        else { $dirText += $c }
        $i++; continue
      }
      if ($state -eq 'paren') {
        if ($c -eq '*' -and $i + 1 -lt $s.Length -and $s[$i + 1] -eq ')') { $state = ''; $i += 2; continue }
        [void]$cm.Append($c)
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
        [void]$sl.Append($s.Substring($i, [Math]::Min($j, $s.Length - 1) - $i + 1))
        $i = $j + 1; continue
      }
      if ($c -eq '/' -and $i + 1 -lt $s.Length -and $s[$i + 1] -eq '/') { [void]$cm.Append($s.Substring($i + 2)); break }
      if ($c -eq '{') {
        if ($i + 1 -lt $s.Length -and $s[$i + 1] -eq '$') {
          $state = 'directive'; $dirText = ''; $dirLine = $n + 1; $i += 2; continue
        }
        $state = 'brace'; $i++; continue
      }
      if ($c -eq '(' -and $i + 1 -lt $s.Length -and $s[$i + 1] -eq '*') { $state = 'paren'; $i += 2; continue }
      [void]$sb.Append($c)
      [void]$sl.Append($c)
      $i++
    }
    $code[$n] = $sb.ToString()
    $literal[$n] = $sl.ToString()
    $comments[$n] = $cm.ToString()
  }
  return @{ Code = $code; Literal = $literal; Comments = $comments; Directives = $directives }
}

# Units aller uses-Klauseln (Name, Zeile), aus dem reinen Code
function Get-UsesClauses([string[]]$Code) {
  $result = New-Object System.Collections.Generic.List[object]
  $inUses = $false
  $expectName = $false
  for ($n = 0; $n -lt $Code.Count; $n++) {
    foreach ($m in [regex]::Matches($Code[$n], "[A-Za-z_]\w*(?:\s*\.\s*[A-Za-z_]\w*)*|''|[;,]")) {
      $t = $m.Value
      if (-not $inUses) {
        if ($t -ieq 'uses') { $inUses = $true; $expectName = $true }
        continue
      }
      if ($t -eq ';') { $inUses = $false; continue }
      if ($t -eq ',') { $expectName = $true; continue }
      if ($expectName) {
        $result.Add([pscustomobject]@{ Name = ($t -replace '\s', ''); Line = $n + 1 })
        $expectName = $false
      }
    }
  }
  return $result
}

# Woerter des reinen Codes mit Zeilennummer (fuer Bloecke ueber mehrere Zeilen)
function Get-Words([string[]]$Code) {
  $result = New-Object System.Collections.Generic.List[object]
  for ($n = 0; $n -lt $Code.Count; $n++) {
    foreach ($m in [regex]::Matches($Code[$n], '[A-Za-z_]\w*')) {
      $result.Add([pscustomobject]@{ Text = $m.Value; Line = $n + 1 })
    }
  }
  return $result
}

# Prueft except-Bloecke ohne Klassenfilter (Regel EXCEPT, nur Source)
function Test-CatchAll([string]$File, [string[]]$Code, [string[]]$Comments) {
  $words = Get-Words $Code
  for ($i = 0; $i -lt $words.Count; $i++) {
    if ($words[$i].Text -ine 'except') { continue }
    if ($i + 1 -ge $words.Count) { break }
    $first = $words[$i + 1].Text
    # "except end": schon als leer gemeldet
    if ($first -ieq 'end') { continue }
    # Ohne "on" faengt der Block alles; mit "on" nur, wenn ein Zweig
    # "on Exception do" bzw. "on E: Exception do" lautet (ab dort zaehlt raise)
    $catchAll = ($first -ine 'on')
    $raiseFrom = $i
    $depth = 0
    $raiseAt = @()
    $k = $i + 1
    while ($k -lt $words.Count) {
      $t = $words[$k].Text
      if ($t -ieq 'begin' -or $t -ieq 'try' -or $t -ieq 'case' -or $t -ieq 'asm') { $depth++ }
      elseif ($t -ieq 'end') {
        if ($depth -eq 0) { break }
        $depth--
      }
      elseif ($t -ieq 'raise' -or $t -ieq 'Abort') { $raiseAt += $k }
      elseif ($t -ieq 'on' -and $depth -eq 0 -and -not $catchAll -and $k + 2 -lt $words.Count) {
        $w1 = $words[$k + 1].Text; $w2 = $words[$k + 2].Text
        $w3 = ''; if ($k + 3 -lt $words.Count) { $w3 = $words[$k + 3].Text }
        if (($w1 -ieq 'Exception' -and $w2 -ieq 'do') -or ($w2 -ieq 'Exception' -and $w3 -ieq 'do')) {
          $catchAll = $true; $raiseFrom = $k
        }
      }
      $k++
    }
    if (-not $catchAll) { continue }
    if (@($raiseAt | Where-Object { $_ -gt $raiseFrom }).Count -gt 0) { continue }
    $from = [Math]::Max(0, $words[$i].Line - 7)
    $to = $Code.Count - 1
    if ($k -lt $words.Count) { $to = $words[$k].Line - 1 }
    $marked = $false
    for ($n = $from; $n -le $to; $n++) {
      if ($Comments[$n] -match '(?i)Grenze') { $marked = $true; break }
    }
    if (-not $marked) {
      Add-Finding $File $words[$i].Line 'EXCEPT' '"except" ohne Klassenfilter (bzw. "on Exception") und ohne raise nur an einer Grenze (Kommentar "Grenze: ...") - sonst gezielt filtern'
    }
  }
}

# Woerter des reinen Codes mit Zeile und Spalte; Call = Pruefaufruf
# (Check...(...) bzw. Fail(...), nicht als Feld "X.Check")
function Get-TestWords([string[]]$Code) {
  $result = New-Object System.Collections.Generic.List[object]
  for ($n = 0; $n -lt $Code.Count; $n++) {
    $line = $Code[$n]
    foreach ($m in [regex]::Matches($line, '[A-Za-z_]\w*')) {
      $isCall = $false
      if ($m.Value -match '^(?i)(Check\w*|Fail)$') {
        $before = ''
        if ($m.Index -gt 0) { $before = $line.Substring(0, $m.Index).TrimEnd() }
        $after = $line.Substring($m.Index + $m.Length)
        $isCall = ($after -match '^\s*\(') -and -not $before.EndsWith('.')
      }
      $result.Add([pscustomobject]@{ Text = $m.Value; Line = $n + 1; Col = $m.Index; Call = $isCall })
    }
  }
  return $result
}

# Regel TESTS (nur Tests\*.pas): Pruefungen, die nichts pruefen oder deren
# Fehlschlag verschluckt wird (DUnits ETestFailure erbt von EAbort), und
# stilles Ueberspringen per Exit.
function Test-TestRules([string]$File, [string[]]$Code) {
  # 1. Immer wahr: CheckTrue(True / Check(True / CheckFalse(False
  for ($n = 0; $n -lt $Code.Count; $n++) {
    if ($Code[$n] -match '(?i)(?<![\w.])(CheckTrue|Check)\s*\(\s*True\s*[,)]' -or
        $Code[$n] -match '(?i)(?<![\w.])CheckFalse\s*\(\s*False\s*[,)]') {
      Add-Finding $File ($n + 1) 'TESTS' 'Pruefung ist immer erfuellt (CheckTrue(True)/CheckFalse(False)) - fachliche Bedingung pruefen'
    }
  }
  $words = Get-TestWords $Code
  # 2. Check/Fail im try-Teil, der Handler faengt alles ohne raise
  for ($i = 0; $i -lt $words.Count; $i++) {
    if ($words[$i].Text -ine 'try') { continue }
    $depth = 0
    $hasCheck = $false
    $k = $i + 1
    $partner = -1
    while ($k -lt $words.Count) {
      $t = $words[$k].Text
      if ($t -ieq 'begin' -or $t -ieq 'try' -or $t -ieq 'case' -or $t -ieq 'asm') { $depth++ }
      elseif ($t -ieq 'end') { if ($depth -eq 0) { break }; $depth-- }
      elseif ($depth -eq 0 -and ($t -ieq 'except' -or $t -ieq 'finally')) { $partner = $k; break }
      elseif ($words[$k].Call) { $hasCheck = $true }
      $k++
    }
    if ($partner -lt 0 -or $words[$partner].Text -ine 'except' -or -not $hasCheck) { continue }
    # Handler bis zum end auf Tiefe 0
    $catchAll = ($partner + 1 -lt $words.Count -and $words[$partner + 1].Text -ine 'on')
    $from = $partner
    $handled = $false
    $depth = 0
    $k = $partner + 1
    while ($k -lt $words.Count) {
      $t = $words[$k].Text
      if ($t -ieq 'begin' -or $t -ieq 'try' -or $t -ieq 'case' -or $t -ieq 'asm') { $depth++ }
      elseif ($t -ieq 'end') { if ($depth -eq 0) { break }; $depth-- }
      elseif ($depth -eq 0 -and $t -ieq 'on' -and $k + 2 -lt $words.Count) {
        $w1 = $words[$k + 1].Text; $w2 = $words[$k + 2].Text
        $w3 = ''; if ($k + 3 -lt $words.Count) { $w3 = $words[$k + 3].Text }
        $cls = ''
        if ($w2 -ieq 'do') { $cls = $w1 } elseif ($w3 -ieq 'do') { $cls = $w2 }
        if ($cls -match '^(?i)(Exception|EAbort|ETestFailure)$' -and -not $catchAll) { $catchAll = $true; $from = $k }
      }
      elseif ($depth -eq 0 -and $t -ieq 'else' -and -not $catchAll) { $catchAll = $true; $from = $k }
      elseif ($k -gt $from -and ($t -ieq 'raise' -or $t -ieq 'is' -or $t -ieq 'CheckIs' -or $t -ieq 'ClassType' -or $t -ieq 'InheritsFrom')) {
        if ($catchAll) { $handled = $true }
      }
      $k++
    }
    if ($catchAll -and -not $handled) {
      Add-Finding $File $words[$partner].Line 'TESTS' 'Check/Fail im try, "except" faengt alles (auch ETestFailure) ohne raise - konkrete Klasse (on EPPG... do) oder raise'
    }
  }
  # 3. Exit vor dem ersten Check in einer published Testmethode nur nach Skip(
  $published = @{}
  $cls = ''
  $inPublished = $false
  for ($n = 0; $n -lt $Code.Count; $n++) {
    $c = $Code[$n]
    if ($c -match '^\s*(T\w+)\s*=\s*class\b') { $cls = $Matches[1]; $inPublished = $false; continue }
    if ($cls -eq '') { continue }
    if ($c -match '^\s*published\b') { $inPublished = $true; continue }
    if ($c -match '^\s*(private|protected|public|strict)\b') { $inPublished = $false; continue }
    if ($c -match '^\s*end\s*;') { $cls = ''; $inPublished = $false; continue }
    if ($inPublished -and $c -match '^\s*procedure\s+(\w+)\s*;') { $published[($cls + '.' + $Matches[1]).ToLowerInvariant()] = $true }
  }
  if ($published.Count -eq 0) { return }
  $byLine = @{}
  foreach ($w in $words) {
    if (-not $byLine.ContainsKey($w.Line)) { $byLine[$w.Line] = New-Object System.Collections.Generic.List[object] }
    $byLine[$w.Line].Add($w)
  }
  $n = 0
  while ($n -lt $Code.Count) {
    if (-not ($Code[$n] -match '^procedure\s+(\w+\.\w+)\s*;' -and $published.ContainsKey($Matches[1].ToLowerInvariant()))) { $n++; continue }
    # Hauptrumpf: erstes "begin" in Spalte 0 (lokale Routinen sind eingerueckt)
    $b = $n + 1
    while ($b -lt $Code.Count -and $Code[$b] -notmatch '^begin\b') { $b++ }
    $e = $b + 1
    while ($e -lt $Code.Count -and $Code[$e] -notmatch '^end\s*;') { $e++ }
    $prev = ''
    $stop = $false
    for ($m = $b; $m -le $e -and $m -lt $Code.Count -and -not $stop; $m++) {
      if (-not $byLine.ContainsKey($m + 1)) { $prev = $prev + ' ' + $Code[$m]; continue }
      foreach ($w in $byLine[$m + 1]) {
        if ($w.Call) { $stop = $true; break }
        if ($w.Text -ieq 'Exit') {
          # Vorherige Anweisung muss Skip(...) / PPGSkip(...) sein
          $stmt = $prev + ' ' + $Code[$m].Substring(0, $w.Col)
          $parts = $stmt -split ';'
          $last = ''
          if ($parts.Count -ge 2) { $last = $parts[$parts.Count - 2] }
          if ($last -notmatch '(?i)(?<![\w.])(PPG)?Skip\s*\(') {
            Add-Finding $File ($m + 1) 'TESTS' 'Exit vor der ersten Pruefung nur direkt nach Skip(Grund) - stilles Ueberspringen'
          }
        }
      }
      $prev = $prev + ' ' + $Code[$m]
    }
    $n = $e + 1
  }
}

# ---------------------------------------------------------------------------
# Regeln je Datei
# ---------------------------------------------------------------------------

# $Rel: Pfad relativ zur Wurzel (z. B. Source\Core\PPG.Types.pas); bestimmt,
# welche Regeln gelten
function Test-SourceFile([string]$File, [string]$Rel) {
  $IsSourceUnit = $Rel -match '^Source[\\/].+\.pas$'
  $isSrc = $Rel -match '^Source[\\/]'
  $isCode = $Rel -match '^(Source|Tests|Demo)[\\/]'
  $layer = ''
  if ($Rel -match '^Source[\\/]([^\\/]+)[\\/]') { $layer = $Matches[1] }
  $base = [IO.Path]::GetFileNameWithoutExtension($Rel)

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
  $literal = $parts.Literal
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

  # uses-Klauseln: DB, DESIGN, UNITS, LAYER
  $uses = Get-UsesClauses $code
  # Ab dieser Zeile ist System.Generics.Collections sichtbar (0 = nie)
  $genericsFrom = 0
  foreach ($u in $uses) {
    $name = $u.Name
    if ($name -ieq 'System.Generics.Collections' -or $name -ieq 'Generics.Collections') { if ($genericsFrom -eq 0) { $genericsFrom = $u.Line } }
    if ($isSrc -and $layer -ne 'DB' -and $layer -ne 'DesignDB' -and $name -match '^(?i)(Data\.|Datasnap\.|Vcl\.DB|MidasLib$)') {
      Add-Finding $File $u.Line 'DB' "$name nur in Source\DB bzw. Source\DesignDB (das Grundpaket linkt keine DB-Units)"
    }
    if ($isCode -and $layer -ne 'Design' -and $layer -ne 'DesignDB' -and $DesignUnits -contains $name) {
      Add-Finding $File $u.Line 'DESIGN' "$name nur in Source\Design bzw. Source\DesignDB (IDE-Unit)"
    }
    if ($isCode -and $UnqualifiedUnits -contains $name) {
      Add-Finding $File $u.Line 'UNITS' "Unit voll qualifizieren: $name"
    }
    if ($isSrc -and $LayerAllowed.ContainsKey($layer) -and $script:UnitLayers.ContainsKey($name)) {
      $target = $script:UnitLayers[$name]
      if ($LayerAllowed[$layer] -notcontains $target) {
        Add-Finding $File $u.Line 'LAYER' "$layer darf $target nicht verwenden ($name)"
      }
    }
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
    # TImageIndex nur in PPG.Types (Kompatibilitaet XE2: Vcl.ImgList/System.UITypes)
    if ($isCode -and $base -ne 'PPG.Types' -and $c -match '\bTImageIndex\b') {
      Add-Finding $File $ln 'IMAGEINDEX' 'TPPGImageIndex statt TImageIndex verwenden'
    }
    # Timer nur ueber den gemeinsamen Animator
    if ($isSrc -and $base -ne 'PPG.Animation' -and $c -match '\b(TTimer|SetTimer|KillTimer)\b') {
      Add-Finding $File $ln 'TIMER' "$($Matches[1]) nur in PPG.Animation (Timer laufen ueber den Animator)"
    }
    # Sichtbare Texte nur ueber PPGStr (Design-Units ausgenommen)
    if ($isSrc -and $layer -ne 'Design' -and $layer -ne 'DesignDB' -and $layer -ne 'Editors' -and
        $literal[$n] -match "(?i)(?<![\w])(Caption|Hint|Text)\s*:=\s*'((?:[^']|'')*)'") {
      if (([regex]::Matches($Matches[2], '[A-Za-z]')).Count -ge 2) {
        Add-Finding $File $ln 'TEXT' "$($Matches[1]) := '$($Matches[2])' - sichtbarer Text gehoert als resourcestring nach PPG.Consts (PPGStr)"
      }
    }
    # XE2-Verbotsliste
    if ($isCode) {
      if ($c -match '\bFMod\b') { Add-Finding $File $ln 'XE2' 'FMod gibt es in XE2 nicht (eigene Modulo-Funktion)' }
      if ($genericsFrom -gt 0 -and $ln -gt $genericsFrom -and $c -match '(?<![\w.])(TCollectionNotification|cnAdded|cnRemoved|cnExtracted|cnExtracting|cnDeleting)\b') {
        Add-Finding $File $ln 'XE2' "$($Matches[1]) mit System.Classes. qualifizieren (System.Generics.Collections verdeckt es)"
      }
      if ($c -match '\bDocumentProperties\s*\(') {
        # Argumente bis zur schliessenden Klammer (auch ueber Zeilen)
        $argText = $c.Substring($c.IndexOf($Matches[0]) + $Matches[0].Length)
        $m = $n
        while (($argText.Split('(').Count -ge $argText.Split(')').Count) -and $m + 1 -lt $code.Count -and $m - $n -lt 5) {
          $m++; $argText += ' ' + $code[$m]
        }
        if ($argText -match '(?i)\bnil\b') {
          Add-Finding $File $ln 'XE2' 'DocumentProperties mit nil (XE2 erwartet var DevMode) - eigenen Import mit PDeviceMode verwenden'
        }
      }
    }
    # Klammertiefe fuer die Erkennung von Parameterlisten ueber mehrere Zeilen
    foreach ($ch in $c.ToCharArray()) {
      if ($ch -eq '(') { $depth++ }
      elseif ($ch -eq ')' -and $depth -gt 0) { $depth-- }
    }
  }

  # except ohne Klassenfilter nur an Grenzen
  if ($isSrc -and $layer -ne 'Access' -and $base -ne 'PPG.ErrorHandler' -and $base -ne 'PPG.Animation') {
    Test-CatchAll $File $code $parts.Comments
  }
  # Testintegritaet (Regel TESTS)
  if ($Rel -match '^Tests[\\/][^\\/]+\.pas$') {
    Test-TestRules $File $code
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
  @{ Name = 'Editors'; Folders = @('Source\Editors');
     Lists = @('Packages\Delphi13\dclPPGlow.dpk', 'Packages\Delphi13\dclPPGlow.dproj', 'Packages\XE2\dclPPGlow.dpk',
               'Tests\PPGlowTests.dpr', 'Tests\PPGlowTests.dproj') },
  @{ Name = 'Tests'; Folders = @('Tests');
     Lists = @('Tests\PPGlowTests.dpr', 'Tests\PPGlowTests.dproj') },
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

# requires-Liste eines Pakets (Kommentare entfernt, Namen in Kleinbuchstaben)
function Get-Requires([string]$Dpk) {
  $lines = [IO.File]::ReadAllText($Dpk) -split "`r?`n"
  $code = (Split-Source $Dpk $lines).Code -join ' '
  if ($code -notmatch '(?is)\brequires\b(.*?);') { return @() }
  return @($Matches[1] -split ',' | ForEach-Object { $_.Trim().ToLowerInvariant() } | Where-Object { $_ })
}

# Jedes Paket hat in XE2 und Delphi 13 dieselbe requires-Liste
function Test-Requires {
  $dirs = @('Packages\XE2', 'Packages\Delphi13') | ForEach-Object { Join-RootPath $_ }
  if (-not ((Test-Path $dirs[0]) -and (Test-Path $dirs[1]))) { return }
  $names = @($dirs | ForEach-Object { Get-ChildItem -Path $_ -Filter '*.dpk' -File } | ForEach-Object { $_.Name } | Sort-Object -Unique)
  foreach ($name in $names) {
    $a = Join-Path $dirs[0] $name
    $b = Join-Path $dirs[1] $name
    if (-not (Test-Path $a)) { Add-Finding $b 0 'REQUIRES' "Paket fehlt in Packages\XE2: $name"; continue }
    if (-not (Test-Path $b)) { Add-Finding $a 0 'REQUIRES' "Paket fehlt in Packages\Delphi13: $name"; continue }
    $ra = @(Get-Requires $a | Sort-Object)
    $rb = @(Get-Requires $b | Sort-Object)
    if (($ra -join ',') -ne ($rb -join ',')) {
      Add-Finding $b 0 'REQUIRES' ("requires weicht von Packages\XE2\{0} ab: XE2 [{1}], Delphi13 [{2}]" -f $name, ($ra -join ', '), ($rb -join ', '))
    }
  }
}

# ---------------------------------------------------------------------------
# Lauf
# ---------------------------------------------------------------------------

function Test-Languages {
  $script = Join-Path $PSScriptRoot 'make-lang.ps1'
  if (-not (Test-Path $script)) { return }
  $out = & $script -Check -Root $Root
  foreach ($line in @($out)) {
    if ($line) { Add-Finding (Join-Path $Root 'Lang') 0 'LANG' $line }
  }
}

function Get-RelPath([string]$File) {
  if ($File.StartsWith($Root)) { return $File.Substring($Root.Length).TrimStart('\', '/') }
  return $File
}

function Invoke-Check([string[]]$Files, [bool]$WithProjects) {
  $script:Findings.Clear()
  Update-UnitLayers
  foreach ($f in $Files) {
    Test-SourceFile $f (Get-RelPath $f)
  }
  if ($WithProjects) {
    Test-ProjectLists
    Test-Requires
    Test-Languages
  }
}

if ($SelfTest) {
  $dir = Join-Path $PSScriptRoot 'check-rules-tests'
  $failed = 0
  Update-UnitLayers
  # Einzeldateien: Zeile 1 "// expect: REGEL1 REGEL2" (oder "none"), optional
  # Zeile 2 "// path: Source\...\X.pas" (Lage im Projekt, bestimmt die Regeln);
  # "source-unit" ohne path steht fuer eine Unit unter Source (ohne Schicht)
  foreach ($f in Get-ChildItem -Path $dir -Filter '*.pas' -File) {
    $head = @(Get-Content -Path $f.FullName -TotalCount 3)
    $expected = @()
    if ($head[0] -match '^//\s*expect:\s*(.+)$') { $expected = @($Matches[1].Trim() -split '\s+' | Where-Object { $_ -ne 'none' }) }
    $rel = 'SelfTest\' + $f.Name
    if ($head[0] -match 'source-unit') { $rel = 'Source\SelfTest\' + $f.Name }
    $count = -1
    foreach ($h in ($head | Select-Object -Skip 1)) {
      if ($h -match '^//\s*path:\s*(\S+)\s*$') { $rel = $Matches[1] }
      elseif ($h -match '^//\s*count:\s*(\d+)\s*$') { $count = [int]$Matches[1] }
    }
    $script:Findings.Clear()
    Test-SourceFile $f.FullName $rel
    $got = @($script:Findings | ForEach-Object { $_.Rule } | Sort-Object -Unique)
    $want = @($expected | Where-Object { $_ -ne 'source-unit' } | Sort-Object -Unique)
    if ((Compare-Object -ReferenceObject $want -DifferenceObject $got -SyncWindow 0) -ne $null -or $want.Count -ne $got.Count -or
        ($count -ge 0 -and $script:Findings.Count -ne $count)) {
      Write-Output ("FEHLER {0}: erwartet [{1}], gefunden [{2}]; Anzahl erwartet {3}, gefunden {4}" -f $f.Name,
        ($want -join ' '), ($got -join ' '), $count, $script:Findings.Count)
      $script:Findings | ForEach-Object { Write-Output ("    {0}({1}) {2}: {3}" -f $_.File, $_.Line, $_.Rule, $_.Text) }
      $failed++
    }
    else {
      Write-Output ("ok     {0}: [{1}]" -f $f.Name, ($got -join ' '))
    }
  }
  # Kleine Projekte (Unterordner): expect.txt mit "expect: REGEL ..." und
  # beliebig vielen "text: ..."-Zeilen (Teil einer erwarteten Meldung).
  # Es laufen nur die genannten Regeln ueber mehrere Dateien.
  $realRoot = $Root
  foreach ($d in Get-ChildItem -Path $dir -Directory) {
    $exp = Join-Path $d.FullName 'expect.txt'
    if (-not (Test-Path $exp)) { continue }
    $want = @(); $texts = @()
    foreach ($l in [IO.File]::ReadAllLines($exp)) {
      if ($l -match '^\s*expect:\s*(.+)$') { $want = @($Matches[1].Trim() -split '\s+' | Sort-Object -Unique) }
      elseif ($l -match '^\s*text:\s*(.+?)\s*$') { $texts += $Matches[1] }
    }
    $Root = $d.FullName
    $script:Findings.Clear()
    try {
      if ($want -contains 'PROJECT') { Test-ProjectLists }
      if ($want -contains 'REQUIRES') { Test-Requires }
      if ($want -contains 'LANG') { Test-Languages }
    } finally { $Root = $realRoot }
    $got = @($script:Findings | ForEach-Object { $_.Rule } | Sort-Object -Unique)
    $missing = @($texts | Where-Object { $t = $_; -not ($script:Findings | Where-Object { $_.Text -like "*$t*" }) })
    if ((($want -join ' ') -ne ($got -join ' ')) -or $missing.Count -gt 0) {
      Write-Output ("FEHLER {0}\: erwartet [{1}], gefunden [{2}]" -f $d.Name, ($want -join ' '), ($got -join ' '))
      $missing | ForEach-Object { Write-Output "    Meldung fehlt: $_" }
      $script:Findings | ForEach-Object { Write-Output ("    {0}({1}) {2}: {3}" -f $_.File, $_.Line, $_.Rule, $_.Text) }
      $failed++
    }
    else {
      Write-Output ("ok     {0}\: [{1}] ({2} Meldungen geprueft)" -f $d.Name, ($got -join ' '), $texts.Count)
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
