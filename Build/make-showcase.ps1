<#
  Daten der Demo-Komponentenseiten (Showcase) als Ressource

  Erzeugt Demo\Showcase\ShowcaseData.res (wird eingecheckt) mit RCDATA:
    PROPS        alle Docs\Controls\props\*.txt hintereinander (UTF-8): Wirkung,
                 Nutzung ("> ") und Praxis ("! ") jeder Eigenschaft
    NOTES        alle Docs\Controls\notes\*.md, je Datei eingeleitet durch eine
                 Zeile "@@ <Klasse>" (Abschnitte "Wofuer", "Wann verwenden")
    EX_<UNIT>    Quelltext jedes Praxisbeispiels Demo\Showcase\Ex*.pas; die Demo
                 zeigt den Teil zwischen // EXAMPLE-BEGIN und // EXAMPLE-END.
                 So ist der angezeigte Code genau der, der das Beispiel baut.

  Die .res wird direkt geschrieben (32-Bit-Ressourcenformat), ohne brcc32.
  build.ps1 ruft das Skript vor dem Demo-Build auf.

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\make-showcase.ps1 [-Check]
           -Check: nur pruefen, ob die .res aktuell ist (Exit-Code 1 = veraltet)
#>
param(
  [string]$Root = '',
  [switch]$Check
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
function P([string]$Rel) { return Join-Path $Root $Rel }

$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-Utf8([string]$File) {
  # ohne BOM, Zeilenenden einheitlich CRLF
  $t = [IO.File]::ReadAllText($File, $utf8)
  if ($t.Length -gt 0 -and $t[0] -eq [char]0xFEFF) { $t = $t.Substring(1) }
  return ($t -replace "`r?`n", "`r`n")
}

$entries = New-Object System.Collections.Generic.List[object]

$sb = New-Object System.Text.StringBuilder
foreach ($f in Get-ChildItem -Path (P 'Docs\Controls\props') -Filter '*.txt' -File | Sort-Object Name) {
  [void]$sb.Append((Read-Utf8 $f.FullName))
  [void]$sb.Append("`r`n")
}
$entries.Add(@{ Name = 'PROPS'; Data = $utf8.GetBytes($sb.ToString()) })

$sb = New-Object System.Text.StringBuilder
foreach ($f in Get-ChildItem -Path (P 'Docs\Controls\notes') -Filter '*.md' -File | Sort-Object Name) {
  [void]$sb.Append("@@ $([IO.Path]::GetFileNameWithoutExtension($f.Name))`r`n")
  [void]$sb.Append((Read-Utf8 $f.FullName))
  [void]$sb.Append("`r`n")
}
$entries.Add(@{ Name = 'NOTES'; Data = $utf8.GetBytes($sb.ToString()) })

foreach ($f in Get-ChildItem -Path (P 'Demo\Showcase') -Filter 'Ex*.pas' -File | Sort-Object Name) {
  $name = 'EX_' + [IO.Path]::GetFileNameWithoutExtension($f.Name).ToUpperInvariant()
  $src = Read-Utf8 $f.FullName
  if ($src -notmatch '// EXAMPLE-BEGIN' -or $src -notmatch '// EXAMPLE-END') {
    throw "$($f.Name): Marken // EXAMPLE-BEGIN und // EXAMPLE-END fehlen"
  }
  $entries.Add(@{ Name = $name; Data = $utf8.GetBytes($src) })
}

# --- .res schreiben ----------------------------------------------------------

function Add-Pad([System.IO.BinaryWriter]$W) {
  while (($W.BaseStream.Position % 4) -ne 0) { $W.Write([byte]0) }
}

$ms = New-Object System.IO.MemoryStream
$w = New-Object System.IO.BinaryWriter($ms)
# Leerer Eintrag am Anfang kennzeichnet eine 32-Bit-.res
$w.Write([uint32]0); $w.Write([uint32]32)
$w.Write([uint16]0xFFFF); $w.Write([uint16]0); $w.Write([uint16]0xFFFF); $w.Write([uint16]0)
$w.Write([uint32]0); $w.Write([uint16]0); $w.Write([uint16]0); $w.Write([uint32]0); $w.Write([uint32]0)
foreach ($e in $entries) {
  $nameBytes = [Text.Encoding]::Unicode.GetBytes($e.Name + [char]0)
  $nameLen = $nameBytes.Length
  if (($nameLen % 4) -ne 0) { $nameLen += 4 - ($nameLen % 4) }
  $headerSize = 8 + 4 + $nameLen + 16
  $w.Write([uint32]$e.Data.Length)
  $w.Write([uint32]$headerSize)
  $w.Write([uint16]0xFFFF); $w.Write([uint16]10)   # RT_RCDATA
  $w.Write($nameBytes)
  Add-Pad $w
  $w.Write([uint32]0)          # DataVersion
  $w.Write([uint16]0x0030)     # MemoryFlags: MOVEABLE, PURE
  $w.Write([uint16]0)          # Sprache neutral
  $w.Write([uint32]0)          # Version
  $w.Write([uint32]0)          # Characteristics
  $w.Write($e.Data)
  Add-Pad $w
}
$w.Flush()
$bytes = $ms.ToArray()

$target = P 'Demo\Showcase\ShowcaseData.res'
$same = (Test-Path $target) -and ([Convert]::ToBase64String([IO.File]::ReadAllBytes($target)) -eq [Convert]::ToBase64String($bytes))
if ($Check) {
  if ($same) { Write-Output 'ShowcaseData.res ist aktuell'; exit 0 }
  Write-Output 'ShowcaseData.res ist veraltet: Build\make-showcase.ps1 ausfuehren'
  exit 1
}
if ($same) { Write-Output "ShowcaseData.res unveraendert ($($entries.Count) Eintraege)"; exit 0 }
[IO.File]::WriteAllBytes($target, $bytes)
Write-Output "ShowcaseData.res geschrieben: $($entries.Count) Eintraege, $($bytes.Length) Bytes"
