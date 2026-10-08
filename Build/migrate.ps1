<#
  PPGlow Migration VCL/TMS -> PPGlow (Phase 9f)

  Ersetzt in Formularen (Text-DFM) und den zugehoerigen Units die Klassen
  der VCL bzw. von TMS durch die PPGlow-Pendants und passt die Properties an.
  Ausfuehrlich: Docs\Migration.md.

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\migrate.ps1 -Path <Ordner oder Datei>
           [-Recurse] [-WhatIf] [-Only TButton,TEdit] [-NoBackup]
           -SelfTest: prueft das Skript an Build\migrate-tests (Soll: *.expected)

  Was passiert je Formular (.dfm + gleichnamige .pas):
  - "object X: TButton" -> "object X: TPPGButton" (Tabelle unten), ebenso die
    Felder in der .pas ("X: TButton;") und fehlende PPGlow-Units in der
    uses-Liste des interface-Teils.
  - Properties: bekannte Umbenennungen (z.B. TMS EmptyText -> TextHint,
    TDBGrid-Spalten Title.Caption -> Title, Title.Alignment -> TitleAlignment,
    Title.Font/Title.Color -> TitleStyle, Font/Color -> Style,
    TToggleSwitch State -> Checked).
  - Properties, die die PPGlow-Klasse nicht hat, werden entfernt und im
    Bericht genannt. Die erlaubten Properties liest das Skript aus den
    PPGlow-Quelltexten (published-Abschnitte).
  - Ereignis-Handler mit anderem Parametertyp (TDBGrid OnTitleClick/OnCellClick)
    werden in der .pas angepasst.
  - Vorher Sicherung als *.bak (ausser -NoBackup); Bericht migrate-report.txt
    im Zielordner. -WhatIf schreibt nichts, zeigt nur den Bericht.

  Grenzen (stehen im Bericht):
  - Binaere DFMs: vorher in der IDE als Text speichern.
  - TTreeView-Knoten (binaer gespeichert) gehen verloren.
  - TToolBar/TToolButton: andere Struktur - nicht automatisch.
#>
param(
  [string]$Path = '',
  [switch]$SelfTest,
  [switch]$Recurse,
  [switch]$WhatIf,
  [switch]$NoBackup,
  [string[]]$Only = @(),
  [string]$Root = ''
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$Only = @($Only | ForEach-Object { $_ -split ',' } | Where-Object { $_ })

# Alte Klasse -> neue Klasse, Unit
$ClassMap = [ordered]@{
  'TButton'           = @('TPPGButton', 'PPG.Button')
  'TBitBtn'           = @('TPPGButton', 'PPG.Button')
  'TSpeedButton'      = @('TPPGButton', 'PPG.Button')
  'TAdvGlowButton'    = @('TPPGButton', 'PPG.Button')
  'TCheckBox'         = @('TPPGCheckBox', 'PPG.CheckBox')
  'TAdvOfficeCheckBox' = @('TPPGCheckBox', 'PPG.CheckBox')
  'TRadioButton'      = @('TPPGRadioButton', 'PPG.RadioButton')
  'TAdvOfficeRadioButton' = @('TPPGRadioButton', 'PPG.RadioButton')
  'TToggleSwitch'     = @('TPPGToggleSwitch', 'PPG.ToggleSwitch')
  'TProgressBar'      = @('TPPGProgressBar', 'PPG.ProgressBar')
  'TTrackBar'         = @('TPPGTrackBar', 'PPG.TrackBar')
  'TPanel'            = @('TPPGPanel', 'PPG.Panel')
  'TGroupBox'         = @('TPPGGroupBox', 'PPG.GroupBox')
  'TEdit'             = @('TPPGEdit', 'PPG.Edit')
  'TAdvEdit'          = @('TPPGEdit', 'PPG.Edit')
  'TMemo'             = @('TPPGMemo', 'PPG.Memo')
  'TSpinEdit'         = @('TPPGSpinEdit', 'PPG.SpinEdit')
  'TComboBox'         = @('TPPGComboBox', 'PPG.ComboBox')
  'TAdvComboBox'      = @('TPPGComboBox', 'PPG.ComboBox')
  'TTabControl'       = @('TPPGTabControl', 'PPG.TabControl')
  'TPageControl'      = @('TPPGPageControl', 'PPG.PageControl')
  'TAdvPageControl'   = @('TPPGPageControl', 'PPG.PageControl')
  'TTabSheet'         = @('TPPGTabSheet', 'PPG.PageControl')
  'TListBox'          = @('TPPGListBox', 'PPG.ListBox')
  'TCheckListBox'     = @('TPPGCheckListBox', 'PPG.CheckListBox')
  'TTreeView'         = @('TPPGTreeView', 'PPG.TreeView')
  'TStringGrid'       = @('TPPGGrid', 'PPG.Grid')
  'TAdvStringGrid'    = @('TPPGGrid', 'PPG.Grid')
  'TLabel'            = @('TPPGLabel', 'PPG.Labels')
  'TLinkLabel'        = @('TPPGLinkLabel', 'PPG.Labels')
  'TSplitter'         = @('TPPGSplitter', 'PPG.Splitter')
  'TSearchBox'        = @('TPPGSearchEdit', 'PPG.SearchEdit')
  'TMonthCalendar'    = @('TPPGCalendar', 'PPG.Calendar')
  'TDateTimePicker'   = @('TPPGDatePicker', 'PPG.DatePicker')
  'TStatusBar'        = @('TPPGStatusBar', 'PPG.StatusBar')
  'TDBEdit'           = @('TPPGDBEdit', 'PPG.DB.Controls')
  'TDBMemo'           = @('TPPGDBMemo', 'PPG.DB.Controls')
  'TDBCheckBox'       = @('TPPGDBCheckBox', 'PPG.DB.Controls')
  'TDBComboBox'       = @('TPPGDBComboBox', 'PPG.DB.Controls')
  'TDBLookupComboBox' = @('TPPGDBLookupComboBox', 'PPG.DB.Lookup')
  'TDBGrid'           = @('TPPGDBGrid', 'PPG.DB.Grid')
}

# Umbenennungen je ALTER Klasse: alter Name -> neuer Name ('' = entfernen)
$Renames = @{
  'TAdvEdit'     = @{ 'EmptyText' = 'TextHint' }
  'TAdvComboBox' = @{ 'EmptyText' = 'TextHint' }
  'TBitBtn'      = @{ 'Kind' = '' ; 'Glyph.Data' = ''; 'NumGlyphs' = ''; 'Layout' = '' }
  'TSpeedButton' = @{ 'Glyph.Data' = ''; 'NumGlyphs' = ''; 'Flat' = ''; 'Layout' = '' }
  'TSearchBox'   = @{ 'OnInvokeSearch' = 'OnSearch' }
}

# VCL-Vorgaben, die bei PPGlow anders sind. Die IDE schreibt Vorgabewerte
# nicht in die DFM; fehlt eine dieser Properties, gilt in der VCL der Wert
# hier, in PPGlow aber die PPGlow-Vorgabe. Damit sich das Verhalten nicht
# still aendert, schreibt das Skript den VCL-Wert ausdruecklich hinein.
# (Docs\Migration.md, Abschnitt "Abweichende Vorgaben")
$VclDefaults = @{
  'TTreeView'      = [ordered]@{ 'ShowLines' = 'True'; 'RowSelect' = 'False'; 'HideSelection' = 'True' }
  'TTabControl'    = [ordered]@{ 'HotTrack' = 'False' }
  'TPageControl'   = [ordered]@{ 'HotTrack' = 'False' }
  'TProgressBar'   = [ordered]@{ 'Smooth' = 'False' }
  'TRadioButton'   = [ordered]@{ 'TabStop' = 'False' }
  'TLinkLabel'     = [ordered]@{ 'TabStop' = 'False' }
  'TMonthCalendar' = [ordered]@{ 'TabStop' = 'False' }
  'TSplitter'      = [ordered]@{ 'ResizeStyle' = 'rsPattern' }
  'TTabSheet'      = [ordered]@{ 'ImageIndex' = '0' }
}

# Werte, die bei PPGlow anders heissen: Klasse -> Property -> alt -> neu
# ('' = entfernen und melden)
$ValueMap = @{
  'TButton' = @{ 'Style' = @{ 'bsPushButton' = 'pbsPushButton'; 'bsSplitButton' = 'pbsSplitButton'; 'bsCommandLink' = '' } }
}

# DB-Grid-Optionen ohne Wirkung in TPPGDBGrid (werden gemeldet)
$DBGridNoEffect = @('dgAlwaysShowEditor', 'dgAlwaysShowSelection', 'dgThumbTracking', 'dgMultiSelect')

# --- Dateien mit ihrer Kodierung lesen und schreiben -------------------------
# Kundenquellen sind oft ANSI (cp1252). Ohne Angabe wuerde .NET sie als UTF-8
# lesen und Umlaute als U+FFFD zurueckschreiben.

function Read-SourceFile([string]$File) {
  $bytes = [IO.File]::ReadAllBytes($File)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $enc = New-Object System.Text.UTF8Encoding($true)
    return @{ Text = $enc.GetString($bytes, 3, $bytes.Length - 3); Encoding = $enc }
  }
  if ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $enc = New-Object System.Text.UnicodeEncoding($false, $true)
    return @{ Text = $enc.GetString($bytes, 2, $bytes.Length - 2); Encoding = $enc }
  }
  # Ohne BOM: gueltiges UTF-8 bleibt UTF-8, sonst ANSI-Codepage des Systems
  $strict = New-Object System.Text.UTF8Encoding($false, $true)
  try {
    return @{ Text = $strict.GetString($bytes); Encoding = (New-Object System.Text.UTF8Encoding($false)) }
  }
  catch [System.Text.DecoderFallbackException] {
    $enc = [System.Text.Encoding]::Default
    return @{ Text = $enc.GetString($bytes); Encoding = $enc }
  }
}

function Write-SourceFile([string]$File, [string]$Text, $Encoding) {
  # WriteAllText schreibt das BOM, wenn die Kodierung eines vorsieht
  [IO.File]::WriteAllText($File, $Text, $Encoding)
}

function Backup-File([string]$File) {
  # Nie ueberschreiben: beim zweiten Lauf waere sonst das Original weg
  $bak = $File + '.bak'
  if (-not (Test-Path $bak)) { Copy-Item $File $bak }
}

# Eigenschaften, die TControl/TComponent immer veroeffentlichen bzw. die IDE schreibt
$AlwaysAllowed = @('Left', 'Top', 'Width', 'Height', 'Tag', 'Hint', 'Cursor', 'HelpType',
  'HelpKeyword', 'HelpContext', 'Margins', 'AlignWithMargins', 'CustomHint', 'ExplicitLeft',
  'ExplicitTop', 'ExplicitWidth', 'ExplicitHeight', 'Padding', 'Touch')

$report = New-Object System.Collections.Generic.List[string]

# --- Erlaubte Properties der PPGlow-Klassen aus den Quelltexten -------------

$script:ClassInfo = @{}  # Klasse -> @{ Parent = '...'; Props = HashSet }

function Read-PPGlowClasses {
  $src = Join-Path $Root 'Source'
  foreach ($f in Get-ChildItem -Path $src -Recurse -Filter '*.pas' -File) {
    $lines = [IO.File]::ReadAllLines($f.FullName)
    $current = $null
    $section = ''
    foreach ($raw in $lines) {
      $line = $raw.Trim()
      if ($line -match '^(T\w+)\s*=\s*class\s*\(\s*(T\w+)') {
        $current = @{ Parent = $Matches[2]; Props = New-Object 'System.Collections.Generic.HashSet[string]' }
        $script:ClassInfo[$Matches[1]] = $current
        $section = 'private'
        continue
      }
      if ($null -eq $current) { continue }
      if ($line -match '^(?i)(private|protected|public|published|strict)\b') { $section = $Matches[1].ToLower(); continue }
      if ($line -match '^(?i)end;') { $current = $null; continue }
      if ($section -eq 'published' -and $line -match '^(?i)property\s+(\w+)') {
        [void]$current.Props.Add($Matches[1])
      }
    }
  }
}

function Get-AllowedProps([string]$Class) {
  $set = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
  foreach ($p in $AlwaysAllowed) { [void]$set.Add($p) }
  $c = $Class
  $guard = 0
  while ($script:ClassInfo.ContainsKey($c) -and $guard -lt 20) {
    foreach ($p in $script:ClassInfo[$c].Props) { [void]$set.Add($p) }
    $c = $script:ClassInfo[$c].Parent
    $guard++
  }
  return $set
}

# --- DFM ---------------------------------------------------------------------

# Letzte Zeile eines Property-Werts, der in Zeile $Start beginnt (mehrzeilig:
# Stringliste "( ... )", Binaerdaten "{ ... }", Collection "< ... >" oder
# Fortsetzung mit "+").
function Get-ValueEnd([string[]]$Lines, [int]$Start, [string]$Value) {
  $v = $Value.Trim()
  if ($v -eq '(') {
    for ($k = $Start + 1; $k -lt $Lines.Count; $k++) { if ($Lines[$k].TrimEnd() -match '\)$') { return $k } }
  }
  elseif ($v -eq '{') {
    for ($k = $Start + 1; $k -lt $Lines.Count; $k++) { if ($Lines[$k].TrimEnd() -match '\}$') { return $k } }
  }
  elseif ($v -eq '<' -or $v -eq '<>') {
    if ($v -eq '<>') { return $Start }
    $depth = 1
    for ($k = $Start + 1; $k -lt $Lines.Count; $k++) {
      $t = $Lines[$k].Trim()
      if ($t -match '=\s*<\s*$') { $depth++ }
      if ($t -match '>$') { $depth--; if ($depth -eq 0) { return $k } }
    }
  }
  elseif ($v.EndsWith('+')) {
    $k = $Start + 1
    while ($k -lt $Lines.Count -and $Lines[$k].TrimEnd().EndsWith('+')) { $k++ }
    return $k
  }
  return $Start
}

function Convert-Dfm([string]$File, [hashtable]$Handlers) {
  $bytes = [IO.File]::ReadAllBytes($File)
  if ($bytes.Length -gt 0 -and $bytes[0] -eq 0xFF) {
    $report.Add("$File : binaere DFM - zuerst in der IDE als Text speichern (uebersprungen)")
    return $null
  }
  $src = Read-SourceFile $File
  $lines = [regex]::Split($src.Text, "`r?`n")
  if ($lines.Count -gt 1 -and $lines[$lines.Count - 1] -eq '') { $lines = $lines[0..($lines.Count - 2)] }
  $out = New-Object System.Collections.Generic.List[string]

  # Abweichende VCL-Vorgaben eines Objekts ausdruecklich schreiben (vor dem
  # ersten Kind-Objekt bzw. vor "end"; Properties stehen in der DFM vor Kindern)
  function Add-VclDefaults($e) {
    if ($null -eq $e -or $e.Done) { return }
    $e.Done = $true
    if ($null -eq $e.Allowed -or -not $VclDefaults.ContainsKey($e.Old)) { return }
    foreach ($p in $VclDefaults[$e.Old].Keys) {
      if (-not $e.Seen.Contains($p)) {
        $out.Add((' ' * ($e.Indent + 2)) + "$p = $($VclDefaults[$e.Old][$p])")
        $report.Add("$File :   $($e.Name).$p = $($VclDefaults[$e.Old][$p]) (VCL-Vorgabe, bei $($e.New) anders)")
        $script:changedByDefaults = $true
      }
    }
  }
  $script:changedByDefaults = $false
  # Stapel der Objekte: alte Klasse, neue Klasse, erlaubte Properties
  $stack = New-Object System.Collections.Generic.List[object]
  $usedUnits = New-Object 'System.Collections.Generic.HashSet[string]'
  $collection = $null # laufende Collection (z.B. Columns des DB-Grids)
  $colFont = $false; $colTitleFont = $false
  $changed = $false

  for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $indent = $line.Length - $line.TrimStart().Length
    $t = $line.Trim()

    if ($t -match '^(object|inherited|inline)\s+(\w+)\s*:\s*(\w+)(.*)$') {
      $kw = $Matches[1]; $name = $Matches[2]; $cls = $Matches[3]; $rest = $Matches[4]
      if ($stack.Count -gt 0) { Add-VclDefaults $stack[$stack.Count - 1] }
      $entry = @{ Old = $cls; New = $cls; Allowed = $null; Name = $name; Indent = $indent; Done = $false
        Seen = (New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)) }
      if ($ClassMap.Contains($cls) -and (($Only.Count -eq 0) -or ($Only -contains $cls))) {
        $new = $ClassMap[$cls][0]
        [void]$usedUnits.Add($ClassMap[$cls][1])
        $entry.New = $new
        $entry.Allowed = Get-AllowedProps $new
        $line = (' ' * $indent) + "$kw ${name}: $new$rest"
        $report.Add("$File : $name $cls -> $new")
        $changed = $true
        if ($cls -eq 'TTreeView') { $report.Add("$File :   $name - Knoten (Items.NodeData) gehen verloren, im Editor neu anlegen") }
      }
      $stack.Add($entry)
      $out.Add($line)
      continue
    }
    if ($t -eq 'end' -and $null -eq $collection) {
      if ($stack.Count -gt 0) {
        Add-VclDefaults $stack[$stack.Count - 1]
        $stack.RemoveAt($stack.Count - 1)
      }
      $out.Add($line)
      continue
    }

    $cur = $null
    if ($stack.Count -gt 0) { $cur = $stack[$stack.Count - 1] }
    if ($null -ne $cur -and $null -eq $collection -and $t -match '^([\w.]+)\s*=') {
      [void]$cur.Seen.Add(($Matches[1] -split '\.')[0])
    }

    # Collection-Elemente (item ... end) einer migrierten Klasse
    if ($null -ne $collection) {
      if ($t -match '^item$' -or $t -match '^end$' -or $t -match '^end>') {
        if ($t -match '>\s*$') { $collection = $null }
        # je Spalte: ParentFont = False nur einmal einfuegen
        $colFont = $false; $colTitleFont = $false
        $out.Add($line)
        continue
      }
      if ($t -match '^([\w.]+)\s*=(.*)$') {
        $p = $Matches[1]
        if ($collection -eq 'DBGridColumns') {
          $sp = ' ' * $indent
          $v = $Matches[2]
          if ($p -eq 'Title.Caption') { $line = $line.Replace('Title.Caption', 'Title'); $out.Add($line); continue }
          if ($p -eq 'Title.Alignment') {
            $al = @{ 'taLeftJustify' = 'gtaLeft'; 'taCenter' = 'gtaCenter'; 'taRightJustify' = 'gtaRight' }[$v.Trim()]
            if ($al) { $out.Add("${sp}TitleAlignment = $al") }
            continue
          }
          if ($p -eq 'Title.Color') { $out.Add("${sp}TitleStyle.Color =$v"); continue }
          if ($p -eq 'Color') { $out.Add("${sp}Style.Color =$v"); continue }
          if ($p -like 'Title.Font.*') {
            if (-not $colTitleFont) { $out.Add("${sp}TitleStyle.ParentFont = False"); $colTitleFont = $true }
            $out.Add("${sp}TitleStyle.$($p.Substring(6)) =$v")
            continue
          }
          if ($p -like 'Font.*') {
            if (-not $colFont) { $out.Add("${sp}Style.ParentFont = False"); $colFont = $true }
            $out.Add("${sp}Style.$p =$v")
            continue
          }
          if ($p -notin @('FieldName', 'Width', 'Alignment', 'ReadOnly', 'PickList.Strings', 'Visible')) {
            $report.Add("$File :   $($cur.Name).Columns: '$p' entfernt")
            $i = Get-ValueEnd $lines $i $Matches[2]
            continue
          }
        }
      }
      $out.Add($line)
      continue
    }

    if ($null -ne $cur -and $null -ne $cur.Allowed -and $t -match '^([\w.]+)\s*=(.*)$') {
      $prop = $Matches[1]
      $value = $Matches[2]
      $top = ($prop -split '\.')[0]
      # Umbenennungen
      if ($Renames.ContainsKey($cur.Old) -and $Renames[$cur.Old].ContainsKey($prop)) {
        $newName = $Renames[$cur.Old][$prop]
        if ($newName -eq '') {
          $report.Add("$File :   $($cur.Name).$prop entfernt")
          $i = Get-ValueEnd $lines $i $value
          $changed = $true
          continue
        }
        $line = $line.Replace("$prop =", "$newName =")
        $prop = $newName
        $top = ($prop -split '\.')[0]
        $changed = $true
      }
      # Werte mit anderem Namen (z. B. TButton.Style bsSplitButton)
      if ($ValueMap.ContainsKey($cur.Old) -and $ValueMap[$cur.Old].ContainsKey($prop)) {
        $mapped = $ValueMap[$cur.Old][$prop][$value.Trim()]
        if ($null -ne $mapped) {
          if ($mapped -eq '') {
            $report.Add("$File :   $($cur.Name).$prop = $($value.Trim()) gibt es bei $($cur.New) nicht (entfernt)")
            $changed = $true
            continue
          }
          $line = (' ' * $indent) + "$prop = $mapped"
          $changed = $true
        }
      }
      # DB-Grid-Optionen ohne Wirkung melden (bleiben stehen)
      if ($cur.Old -eq 'TDBGrid' -and $prop -eq 'Options') {
        $optText = $value
        $k = $i
        while ($optText -notmatch '\]' -and ($k + 1) -lt $lines.Count) { $k++; $optText += $lines[$k] }
        foreach ($o in $DBGridNoEffect) {
          if ($optText -match "\b$o\b") { $report.Add("$File :   $($cur.Name).Options: $o wirkt bei TPPGDBGrid nicht") }
        }
      }
      if ($cur.Old -eq 'TDateTimePicker' -and $prop -eq 'Kind' -and $value.Trim() -eq 'dtkTime') {
        $report.Add("$File :   $($cur.Name) ist eine Zeitauswahl - TPPGTimePicker verwenden (von Hand)")
      }
      # TToggleSwitch: State = tssOn -> Checked = True
      if ($cur.Old -eq 'TToggleSwitch' -and $prop -eq 'State') {
        $out.Add((' ' * $indent) + 'Checked = ' + $(if ($value.Trim() -eq 'tssOn') { 'True' } else { 'False' }))
        $changed = $true
        continue
      }
      # DB-Grid-Spalten
      if ($cur.Old -eq 'TDBGrid' -and $prop -eq 'Columns') {
        $collection = 'DBGridColumns'
        $out.Add($line)
        continue
      }
      # Ereignisse merken (Signatur ggf. anpassen)
      if ($prop -like 'On*' -and $cur.Old -eq 'TDBGrid' -and ($prop -eq 'OnTitleClick' -or $prop -eq 'OnCellClick')) {
        $Handlers[$value.Trim()] = 'TPPGDBGridColumn'
      }
      if (-not $cur.Allowed.Contains($top)) {
        $report.Add("$File :   $($cur.Name).$prop entfernt (gibt es bei $($cur.New) nicht)")
        $i = Get-ValueEnd $lines $i $value
        $changed = $true
        continue
      }
    }
    # Mehrzeilige Werte unveraendert uebernehmen (Collections "< item ... end >"
    # duerfen den Objektstapel nicht beruehren)
    if ($t -match '^([\w.]+)\s*=(.*)$') {
      $end = Get-ValueEnd $lines $i $Matches[2]
      $out.Add($line)
      for ($k = $i + 1; $k -le $end; $k++) { $out.Add($lines[$k]) }
      $i = $end
      continue
    }
    $out.Add($line)
  }
  return @{ Lines = $out; Units = $usedUnits; Changed = ($changed -or $script:changedByDefaults); Encoding = $src.Encoding }
}

# --- PAS ---------------------------------------------------------------------

function Convert-Pas([string]$File, $Units, [hashtable]$Handlers) {
  $text = (Read-SourceFile $File).Text
  $orig = $text
  foreach ($cls in $ClassMap.Keys) {
    if (($Only.Count -gt 0) -and ($Only -notcontains $cls)) { continue }
    $new = $ClassMap[$cls][0]
    # Felddeklarationen im Formular: "Name: TButton;"
    $text = [regex]::Replace($text, "(?m)^(\s+\w+(\s*,\s*\w+)*\s*:\s*)$cls(\s*;)", "`${1}$new`${3}")
  }
  # Handler-Signaturen (TColumn -> TPPGDBGridColumn)
  foreach ($h in $Handlers.Keys) {
    $text = [regex]::Replace($text, "(procedure\s+(\w+\.)?$h\s*\([^)]*Column\s*:\s*)TColumn", "`${1}$($Handlers[$h])")
  }
  # Units in den interface-uses
  $m = [regex]::Match($text, '(?is)\binterface\b.*?\buses\b(.*?);')
  if ($m.Success -and $Units.Count -gt 0) {
    $list = $m.Groups[1].Value
    $add = @($Units | Where-Object { $list -notmatch [regex]::Escape($_) })
    if ($add.Count -gt 0) {
      $insertAt = $m.Groups[1].Index + $m.Groups[1].Length
      $text = $text.Substring(0, $insertAt) + ",`r`n  " + ($add -join ', ') + $text.Substring($insertAt)
    }
  }
  if ($text -ne $orig) { return $text }
  return $null
}

# --- Lauf --------------------------------------------------------------------

if ($SelfTest) {
  $fixtures = Join-Path $PSScriptRoot 'migrate-tests'
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ('ppg-migrate-' + [Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmp | Out-Null
  try {
    Get-ChildItem $fixtures -File | Where-Object { $_.Extension -in '.dfm', '.pas' } |
      ForEach-Object { Copy-Item $_.FullName $tmp }
    & $PSCommandPath -Path $tmp -NoBackup -Root $Root | Out-Null
    $failed = 0
    foreach ($exp in Get-ChildItem $fixtures -Filter '*.expected' -File) {
      $actual = Join-Path $tmp ($exp.Name -replace '\.expected$', '')
      $a = ([IO.File]::ReadAllText($actual)) -replace "`r`n", "`n"
      $e = ([IO.File]::ReadAllText($exp.FullName)) -replace "`r`n", "`n"
      if ($a.TrimEnd() -ne $e.TrimEnd()) {
        Write-Output "FEHLER $($exp.Name): Ergebnis weicht ab"
        $failed++
      }
      else {
        Write-Output "ok     $($exp.Name)"
      }
    }
    exit $failed
  }
  finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}
if ($Path -eq '') { throw 'Bitte -Path angeben (Ordner oder .dfm).' }

Read-PPGlowClasses
$item = Get-Item $Path
if ($item.PSIsContainer) {
  $dfms = @(Get-ChildItem -Path $item.FullName -Filter '*.dfm' -File -Recurse:$Recurse)
  $reportDir = $item.FullName
}
else {
  $dfms = @($item)
  $reportDir = $item.DirectoryName
}

foreach ($dfm in $dfms) {
  $handlers = @{}
  $res = Convert-Dfm $dfm.FullName $handlers
  if ($null -eq $res -or -not $res.Changed) { continue }
  $pas = [IO.Path]::ChangeExtension($dfm.FullName, '.pas')
  $newPas = $null
  if (Test-Path $pas) { $newPas = Convert-Pas $pas $res.Units $handlers }
  if (-not $WhatIf) {
    if (-not $NoBackup) {
      Backup-File $dfm.FullName
      if ($null -ne $newPas) { Backup-File $pas }
    }
    # In der Kodierung der Quelle zurueckschreiben (ANSI bleibt ANSI)
    Write-SourceFile $dfm.FullName (($res.Lines -join "`r`n") + "`r`n") $res.Encoding
    if ($null -ne $newPas) { Write-SourceFile $pas $newPas (Read-SourceFile $pas).Encoding }
  }
}

$report.Insert(0, ('PPGlow-Migration {0} ({1})' -f (Get-Date -Format 'yyyy-MM-dd HH:mm'), $(if ($WhatIf) { 'nur Vorschau' } else { 'ausgefuehrt' })))
$report | ForEach-Object { Write-Output $_ }
if (-not $WhatIf) {
  [IO.File]::WriteAllLines((Join-Path $reportDir 'migrate-report.txt'), $report)
}
