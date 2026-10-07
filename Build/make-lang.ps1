<#
  PPGlow Sprach-Units (Phase 9d)

  Liest die Texte aus Source\Core\PPG.Consts.pas (resourcestrings, Englisch)
  und die Uebersetzungen aus Lang\PPGlow.<sprache>.txt (UTF-8, Name=Text) und
  erzeugt daraus Source\Core\PPG.Lang.<Sprache>.pas. Die erzeugte Unit ist
  reines ASCII (Coding-Rules): Umlaute stehen als Zeichencode (#$00FC).

  Geprueft wird:
  - jede resourcestring hat eine Uebersetzung, und es gibt keine unbekannten
  - die Platzhalter (%s, %d, %%, %0:s, ...) stimmen in Art und Reihenfolge
  - mit -Check: die erzeugte Unit ist aktuell (sonst Meldung, nichts geschrieben)

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\make-lang.ps1 [-Check] [-Root <Ordner>]
  Exit-Code = Anzahl der Probleme (0 = in Ordnung).
#>
param(
  [switch]$Check,
  [string]$Root = ''
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$sep = [IO.Path]::DirectorySeparatorChar
$ConstsFile = Join-Path $Root ("Source{0}Core{0}PPG.Consts.pas" -f $sep)
$LangDir = Join-Path $Root 'Lang'

$problems = New-Object System.Collections.Generic.List[string]

function Read-ResourceStrings([string]$File) {
  # Name -> Text (einzeilige resourcestrings; '' = Apostroph)
  $result = [ordered]@{}
  $inRes = $false
  foreach ($line in [IO.File]::ReadAllLines($File)) {
    $t = $line.Trim()
    if ($t -match '^(?i)resourcestring\b') { $inRes = $true; continue }
    if ($inRes -and $t -match '^(?i)(implementation|const|type|var)\b') { $inRes = $false }
    if (-not $inRes) { continue }
    if ($t -match "^(SPPG\w+)\s*=\s*'((?:[^']|'')*)'\s*;\s*$") {
      $result[$Matches[1]] = $Matches[2].Replace("''", "'")
    }
  }
  return $result
}

function Get-Placeholders([string]$Text) {
  return @([regex]::Matches($Text, '%(\d+:)?-?\d*(\.\d+)?[dsfxemgnpu%]', 'IgnoreCase') |
    ForEach-Object { $_.Value.ToLowerInvariant() })
}

function ConvertTo-PascalString([string]$Text) {
  # 'abc'#$00FC'def' - Zeichen ab 128 als Code, Apostroph verdoppelt
  $sb = New-Object System.Text.StringBuilder
  $open = $false
  foreach ($ch in $Text.ToCharArray()) {
    $code = [int]$ch
    if ($code -ge 32 -and $code -lt 127) {
      if (-not $open) { [void]$sb.Append("'"); $open = $true }
      if ($ch -eq "'") { [void]$sb.Append("''") } else { [void]$sb.Append($ch) }
    }
    else {
      if ($open) { [void]$sb.Append("'"); $open = $false }
      [void]$sb.Append(('#${0:X4}' -f $code))
    }
  }
  if ($open) { [void]$sb.Append("'") }
  if ($sb.Length -eq 0) { return "''" }
  return $sb.ToString()
}

function Build-Unit([string]$Lang, $Pairs) {
  $code = $Lang.Substring(0, 1).ToUpperInvariant() + $Lang.Substring(1).ToLowerInvariant()
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("unit PPG.Lang.$code;")
  $lines.Add('')
  $lines.Add("{ Uebersetzung '$($Lang.ToLowerInvariant())' der PPGlow-Texte. ERZEUGT von Build\make-lang.ps1")
  $lines.Add("  aus Lang\PPGlow.$($Lang.ToLowerInvariant()).txt - nicht von Hand aendern.")
  $lines.Add('')
  $lines.Add('  Einbinden und aktivieren:')
  $lines.Add("    uses PPG.Lang, PPG.Lang.$code;")
  $lines.Add("    PPGSetLanguage('$($Lang.ToLowerInvariant())'); }")
  $lines.Add('')
  $lines.Add('{$I ..\PPG.inc}')
  $lines.Add('')
  $lines.Add('interface')
  $lines.Add('')
  $lines.Add('const')
  $lines.Add("  PPGLang$($code)Code = '$($Lang.ToLowerInvariant())';")
  $lines.Add("  PPGLang$($code)Count = $($Pairs.Count);")
  $lines.Add('')
  $lines.Add('implementation')
  $lines.Add('')
  $lines.Add('uses')
  $lines.Add('  PPG.Consts, PPG.Lang;')
  $lines.Add('')
  $lines.Add('procedure RegisterTexts;')
  $lines.Add('begin')
  foreach ($name in $Pairs.Keys) {
    $lines.Add("  PPGAddTranslation(PPGLang$($code)Code, @$name,")
    $lines.Add("    $(ConvertTo-PascalString $Pairs[$name]));")
  }
  $lines.Add('end;')
  $lines.Add('')
  $lines.Add('initialization')
  $lines.Add('  RegisterTexts;')
  $lines.Add('')
  $lines.Add('end.')
  return ($lines -join "`r`n") + "`r`n"
}

$english = Read-ResourceStrings $ConstsFile
$files = @(Get-ChildItem -Path $LangDir -Filter 'PPGlow.*.txt' -File -ErrorAction SilentlyContinue)
foreach ($f in $files) {
  $lang = ($f.Name -split '\.')[1]
  $pairs = [ordered]@{}
  $lineNo = 0
  foreach ($line in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
    $lineNo++
    if ($line -match '^\s*(#|$)') { continue }
    $i = $line.IndexOf('=')
    if ($i -lt 1) { $problems.Add("$($f.Name)($lineNo): Zeile ohne Name=Text"); continue }
    $name = $line.Substring(0, $i).Trim()
    $text = $line.Substring($i + 1)
    if (-not $english.Contains($name)) { $problems.Add("$($f.Name)($lineNo): unbekannter Name $name"); continue }
    $a = (Get-Placeholders $english[$name]) -join ' '
    $b = (Get-Placeholders $text) -join ' '
    if ($a -ne $b) { $problems.Add("$($f.Name)($lineNo): Platzhalter von $name passen nicht ('$a' / '$b')") }
    $pairs[$name] = $text
  }
  foreach ($name in $english.Keys) {
    if (-not $pairs.Contains($name)) { $problems.Add("$($f.Name): Uebersetzung fehlt fuer $name") }
  }
  # Reihenfolge wie in PPG.Consts (stabile Ausgabe)
  $ordered = [ordered]@{}
  foreach ($name in $english.Keys) { if ($pairs.Contains($name)) { $ordered[$name] = $pairs[$name] } }
  $code = $lang.Substring(0, 1).ToUpperInvariant() + $lang.Substring(1).ToLowerInvariant()
  $target = Join-Path $Root ("Source{0}Core{0}PPG.Lang.$code.pas" -f $sep)
  $content = Build-Unit $lang $ordered
  if ($Check) {
    if (-not (Test-Path $target)) {
      $problems.Add("PPG.Lang.$code.pas fehlt (Build\make-lang.ps1 ausfuehren)")
    }
    elseif ([IO.File]::ReadAllText($target) -ne $content) {
      $problems.Add("PPG.Lang.$code.pas ist nicht aktuell (Build\make-lang.ps1 ausfuehren)")
    }
  }
  else {
    [IO.File]::WriteAllText($target, $content, [Text.Encoding]::ASCII)
    Write-Output "$target ($($ordered.Count) Texte)"
  }
}

foreach ($p in $problems) { Write-Output $p }
exit $problems.Count
