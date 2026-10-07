<#
  PPGlow Hilfe pro Control (Phase 9f)

  Erzeugt fuer jede Paletten-Komponente (PPG.Reg und PPG.DB.Reg) eine Seite:
    Docs\Controls\<Klasse>.md      (Markdown, im Repository lesbar)
    Docs\Controls\html\<Klasse>.html und index.html (HTML-Hilfe)
  sowie Docs\Controls\README.md als Uebersicht.

  Quellen je Seite:
  - Kopfkommentar der Unit und ///-Kommentar der Klasse (Zweck, Verhalten)
  - published Properties und Ereignisse; was vor dem Kommentar "{ wie TXxx }"
    bzw. "{ VCL-Standard }" steht, ist PPGlow-eigen, der Rest wie in der VCL
  - Docs\Controls\notes\<Klasse>.md (von Hand): Vorbild, Unterschiede zur
    VCL, Beispiel. Fehlt die Datei, steht ein Hinweis auf der Seite.

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\make-docs.ps1
#>
param(
  [string]$Root = ''
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$sep = [IO.Path]::DirectorySeparatorChar
function P([string]$Rel) { return Join-Path $Root ($Rel -replace '[\\/]', $sep) }

$DocsDir = P 'Docs\Controls'
$HtmlDir = P 'Docs\Controls\html'
$NotesDir = P 'Docs\Controls\notes'
New-Item -ItemType Directory -Force $DocsDir, $HtmlDir | Out-Null

# --- Klassen der Palette -----------------------------------------------------

function Get-PaletteClasses([string]$RegFile) {
  $text = [IO.File]::ReadAllText($RegFile)
  $m = [regex]::Match($text, '(?s)RegisterComponents\([^,]+,\s*\[(.*?)\]\)')
  if (-not $m.Success) { return @() }
  return @([regex]::Matches($m.Groups[1].Value, 'TPPG\w+') | ForEach-Object { $_.Value })
}

$groups = [ordered]@{
  'PPGlow'    = Get-PaletteClasses (P 'Source\Design\PPG.Reg.pas')
  'PPGlow DB' = Get-PaletteClasses (P 'Source\DesignDB\PPG.DB.Reg.pas')
}

# --- Quelltexte lesen --------------------------------------------------------

$script:Units = @{}   # Klasse -> Info

function Read-Sources {
  foreach ($f in Get-ChildItem -Path (P 'Source') -Recurse -Filter '*.pas' -File) {
    $lines = [IO.File]::ReadAllLines($f.FullName)
    $unitName = ''
    $header = ''
    # Kopfkommentar: erster { }-Block nach "unit"
    $text = [IO.File]::ReadAllText($f.FullName)
    $hm = [regex]::Match($text, '(?s)^unit\s+([\w.]+);\s*\{(?!\$)(.*?)\}')
    if ($hm.Success) {
      $unitName = $hm.Groups[1].Value
      $header = $hm.Groups[2].Value
    }
    $doc = New-Object System.Collections.Generic.List[string]
    $current = $null
    $section = ''
    $vclPart = $false
    foreach ($raw in $lines) {
      $t = $raw.Trim()
      if ($null -eq $current) {
        if ($t.StartsWith('///')) { $doc.Add($t.Substring(3).Trim()); continue }
        if ($t -match '^(TPPG\w+)\s*=\s*class\s*\(\s*(\w+)') {
          $current = [pscustomobject]@{
            Name = $Matches[1]; Parent = $Matches[2]; Unit = $unitName; Header = $header
            Doc = ($doc -join ' '); Own = New-Object System.Collections.Generic.List[string]
            Vcl = New-Object System.Collections.Generic.List[string]
            Events = New-Object System.Collections.Generic.List[string]
          }
          $script:Units[$current.Name] = $current
          $section = 'private'
          $vclPart = $false
        }
        $doc.Clear()
        continue
      }
      if ($t -match '^(?i)(private|protected|public|published|strict)\b') { $section = $Matches[1].ToLower(); continue }
      if ($t -match '^(?i)end;') { $current = $null; continue }
      if ($section -ne 'published') { continue }
      if ($t -match '^\{\s*(wie\s+T\w+|VCL-Standard)') { $vclPart = $true; continue }
      if ($t -match '^(?i)property\s+(\w+)') {
        $n = $Matches[1]
        if ($n -like 'On*') { $current.Events.Add($n) }
        elseif ($vclPart) { $current.Vcl.Add($n) }
        else { $current.Own.Add($n) }
      }
    }
  }
}

# --- Markdown ----------------------------------------------------------------

function Format-Header([string]$Header) {
  # Kommentar in Absaetze und Aufzaehlungen umsetzen (Einrueckung entfernen)
  $out = New-Object System.Collections.Generic.List[string]
  foreach ($l in ($Header -split "`r?`n")) {
    $t = $l.Trim()
    if ($t -match '^- ') { $out.Add($t) }
    elseif ($t -eq '') { $out.Add('') }
    elseif ($out.Count -gt 0 -and $out[$out.Count - 1] -ne '' -and $l -match '^\s{4,}\S') {
      $out[$out.Count - 1] = $out[$out.Count - 1] + ' ' + $t
    }
    else { $out.Add($t) }
  }
  return ($out -join "`n").Trim()
}

function Build-Page($Info, [string]$Group) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("# $($Info.Name)")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine("Palette **$Group** - Unit ``$($Info.Unit)`` - Basis ``$($Info.Parent)``")
  [void]$sb.AppendLine('')
  if ($Info.Doc -ne '') {
    [void]$sb.AppendLine($Info.Doc)
    [void]$sb.AppendLine('')
  }
  $notes = Join-Path $NotesDir "$($Info.Name).md"
  if (Test-Path $notes) {
    [void]$sb.AppendLine(([IO.File]::ReadAllText($notes, [Text.Encoding]::UTF8)).Trim())
    [void]$sb.AppendLine('')
  }
  [void]$sb.AppendLine('## Verhalten (aus dem Quelltext)')
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine((Format-Header $Info.Header))
  [void]$sb.AppendLine('')
  if ($Info.Own.Count -gt 0) {
    [void]$sb.AppendLine('## PPGlow-Eigenschaften')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine((($Info.Own | ForEach-Object { "``$_``" }) -join ', '))
    [void]$sb.AppendLine('')
  }
  if ($Info.Vcl.Count -gt 0) {
    [void]$sb.AppendLine('## Eigenschaften wie in der VCL')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine((($Info.Vcl | ForEach-Object { "``$_``" }) -join ', '))
    [void]$sb.AppendLine('')
  }
  if ($Info.Events.Count -gt 0) {
    [void]$sb.AppendLine('## Ereignisse')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine((($Info.Events | ForEach-Object { "``$_``" }) -join ', '))
    [void]$sb.AppendLine('')
  }
  [void]$sb.AppendLine('---')
  [void]$sb.AppendLine('Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\' + $Info.Name + '.md`.')
  return $sb.ToString()
}

# --- Markdown -> HTML (kleiner Umfang: Ueberschriften, Absaetze, Listen,
#     Tabellen, Code, Fett, Links) -------------------------------------------

function ConvertTo-Inline([string]$S) {
  $s2 = [System.Net.WebUtility]::HtmlEncode($S)
  $s2 = [regex]::Replace($s2, '`([^`]+)`', '<code>$1</code>')
  $s2 = [regex]::Replace($s2, '\*\*([^*]+)\*\*', '<strong>$1</strong>')
  $s2 = [regex]::Replace($s2, '\[([^\]]+)\]\(([^)]+)\.md\)', '<a href="$2.html">$1</a>')
  $s2 = [regex]::Replace($s2, '\[([^\]]+)\]\(([^)]+)\)', '<a href="$2">$1</a>')
  return $s2
}

function ConvertTo-Html([string]$Md, [string]$Title) {
  $out = New-Object System.Text.StringBuilder
  $lines = $Md -split "`r?`n"
  $inList = $false; $inCode = $false; $inTable = $false; $para = @()
  foreach ($l in $lines) {
    if ($l -match '^```') {
      if ($para.Count -gt 0) { [void]$out.AppendLine('<p>' + (ConvertTo-Inline ($para -join ' ')) + '</p>'); $para = @() }
      if ($inCode) { [void]$out.AppendLine('</code></pre>'); $inCode = $false } else { [void]$out.Append('<pre><code>'); $inCode = $true }
      continue
    }
    if ($inCode) { [void]$out.AppendLine([System.Net.WebUtility]::HtmlEncode($l)); continue }
    $item = ''
    $isItem = $l -match '^\s*[-*]\s+(.*)$'
    if ($isItem) { $item = $Matches[1] }
    $isRow = $l -match '^\s*\|'
    if (($para.Count -gt 0) -and ($isItem -or $isRow -or $l.Trim() -eq '' -or $l -match '^#')) {
      [void]$out.AppendLine('<p>' + (ConvertTo-Inline ($para -join ' ')) + '</p>'); $para = @()
    }
    if ($inList -and -not $isItem) { [void]$out.AppendLine('</ul>'); $inList = $false }
    if ($inTable -and -not $isRow) { [void]$out.AppendLine('</table>'); $inTable = $false }
    if ($l -match '^(#{1,4})\s+(.*)$') {
      $n = $Matches[1].Length
      [void]$out.AppendLine("<h$n>" + (ConvertTo-Inline $Matches[2]) + "</h$n>")
    }
    elseif ($isItem) {
      if (-not $inList) { [void]$out.AppendLine('<ul>'); $inList = $true }
      [void]$out.AppendLine('<li>' + (ConvertTo-Inline $item) + '</li>')
    }
    elseif ($isRow) {
      if ($l -match '^\s*\|[\s:|-]+\|\s*$') { continue }
      $cells = $l.Trim().Trim('|') -split '\|'
      if (-not $inTable) {
        [void]$out.AppendLine('<table>')
        [void]$out.AppendLine('<tr>' + (($cells | ForEach-Object { '<th>' + (ConvertTo-Inline $_.Trim()) + '</th>' }) -join '') + '</tr>')
        $inTable = $true
      }
      else {
        [void]$out.AppendLine('<tr>' + (($cells | ForEach-Object { '<td>' + (ConvertTo-Inline $_.Trim()) + '</td>' }) -join '') + '</tr>')
      }
    }
    elseif ($l -match '^---\s*$') { [void]$out.AppendLine('<hr>') }
    elseif ($l.Trim() -ne '') { $para += $l.Trim() }
  }
  if ($para.Count -gt 0) { [void]$out.AppendLine('<p>' + (ConvertTo-Inline ($para -join ' ')) + '</p>') }
  if ($inList) { [void]$out.AppendLine('</ul>') }
  if ($inTable) { [void]$out.AppendLine('</table>') }
  $css = 'body{font-family:Segoe UI,sans-serif;max-width:56em;margin:2em auto;padding:0 1em;color:#242424;line-height:1.5}' +
    'code{background:#f3f3f3;padding:0 .25em;border-radius:3px}pre{background:#f3f3f3;padding:.75em;overflow:auto}' +
    'table{border-collapse:collapse}td,th{border:1px solid #ddd;padding:.25em .5em;text-align:left}a{color:#0f6cbd}' +
    '@media (prefers-color-scheme:dark){body{background:#202020;color:#e6e6e6}code,pre{background:#2b2b2b}a{color:#60cdff}td,th{border-color:#444}}'
  return "<!DOCTYPE html>`n<html lang=""de""><head><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width, initial-scale=1""><title>$Title</title><style>$css</style></head><body>`n<p><a href=""index.html"">PPGlow-Hilfe</a></p>`n" +
    $out.ToString() + "</body></html>`n"
}

# --- Lauf --------------------------------------------------------------------

Read-Sources
$utf8 = New-Object System.Text.UTF8Encoding($false)
$index = New-Object System.Text.StringBuilder
[void]$index.AppendLine('# PPGlow - Hilfe pro Control')
[void]$index.AppendLine('')
[void]$index.AppendLine('Erzeugt von `Build\make-docs.ps1` aus den Quelltexten und `Docs\Controls\notes`. HTML-Fassung: `Docs\Controls\html\index.html`.')
[void]$index.AppendLine('')
$count = 0
foreach ($g in $groups.Keys) {
  [void]$index.AppendLine("## Palette $g")
  [void]$index.AppendLine('')
  [void]$index.AppendLine('| Control | Unit | Kurzbeschreibung |')
  [void]$index.AppendLine('|---|---|---|')
  foreach ($cls in $groups[$g]) {
    if (-not $script:Units.ContainsKey($cls)) { Write-Warning "$cls nicht gefunden"; continue }
    $info = $script:Units[$cls]
    $md = Build-Page $info $g
    [IO.File]::WriteAllText((Join-Path $DocsDir "$cls.md"), $md, $utf8)
    [IO.File]::WriteAllText((Join-Path $HtmlDir "$cls.html"), (ConvertTo-Html $md $cls), $utf8)
    # Erster Absatz des Kopfkommentars ohne "TPPGXxx - ", bis zum ersten Satzende
    $para = (($info.Header.Trim() -split "`r?`n\s*`r?`n")[0] -split "`r?`n" | ForEach-Object { $_.Trim() }) -join ' '
    $para = [regex]::Replace($para, '^(TPPG\w+(\s*[,/]\s*TPPG\w+)*\s*-\s*)', '')
    $dot = $para.IndexOf('. ')
    if ($dot -gt 0) { $para = $para.Substring(0, $dot + 1) }
    if ($para.Length -gt 160) { $para = $para.Substring(0, 157) + '...' }
    $short = $para
    if ($info.Doc -ne '') { $short = $info.Doc }
    $short = $short.Replace('|', '/')
    [void]$index.AppendLine("| [$cls]($cls.md) | ``$($info.Unit)`` | $short |")
    $count++
  }
  [void]$index.AppendLine('')
}
[IO.File]::WriteAllText((Join-Path $DocsDir 'README.md'), $index.ToString(), $utf8)
[IO.File]::WriteAllText((Join-Path $HtmlDir 'index.html'), (ConvertTo-Html ($index.ToString().Replace('.md)', '.md)')) 'PPGlow-Hilfe'), $utf8)
Write-Output "$count Seiten in $DocsDir"
