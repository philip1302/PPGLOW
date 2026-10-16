<#
  PPGlow Migration VCL/TMS -> PPGlow (Phase 9f)

  Ersetzt in Formularen (Text-DFM) und den zugehoerigen Units die Klassen
  der VCL bzw. von TMS durch die PPGlow-Pendants und passt die Properties an.
  Ausfuehrlich: Docs\Migration.md.

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\migrate.ps1 -Path <Ordner oder Datei>
           [-Recurse] [-WhatIf] [-Only TButton,TEdit] [-NoBackup]
           -SelfTest: prueft das Skript an Build\migrate-tests (Soll: *.expected)

  Weitere Parameter:
    -Map <datei.psd1>     zusaetzliche Zuordnungen (PowerShell-Datendatei):
                          @{ ClassMap = @{ 'TAlt' = @('TNeu','Unit') }; Renames = @{ 'TAlt' = @{ 'A' = 'B' } };
                             ReportOnly = @{ 'TX' = 'Hinweis' }; InheritsVcl = @('TNeu') }
                          Die Eintraege werden in die Tabellen gemischt (Map gewinnt).
    -ExtraSource <ordner[]>  weitere Quellordner, deren published-Properties gelesen werden
                          (eigene Ableitungen ausserhalb von Source)
    -StyleManager <name>  setzt an jedem migrierten Objekt mit published StyleManager
                          "StyleManager = <name>" (auch "DM.PPGStyle" fuer ein Datenmodul)
    -GlyphDir <ordner>    sichert TBitBtn/TSpeedButton-Glyphs als <Form>_<Komponente>.png
                          (erstes Teilbild, Transparenz = Pixel unten links); ohne: entfernt
    -Project <datei.dpr>  nur Formulare migrieren, deren Unit in der uses-Liste der .dpr steht
    TBitBtn.Kind wird in ModalResult/Default/Cancel uebersetzt. Code-Stellen, die durch den
    Klassenwechsel brechen koennen (as/is/Cast/with), werden nur gemeldet.

  Was passiert je Formular (.dfm + gleichnamige .pas):
  - "object X: TButton" -> "object X: TPPGButton" (Tabelle unten), ebenso die
    Felder in der .pas ("X: TButton;") und fehlende PPGlow-Units in der
    uses-Liste des interface-Teils.
  - Properties: bekannte Umbenennungen (z.B. TMS EmptyText -> TextHint,
    TDBGrid-Spalten Title.Caption -> Title, Title.Alignment -> TitleAlignment,
    Title.Font/Title.Color -> TitleStyle, Font/Color -> Style,
    TToggleSwitch State -> Checked, TSpinEdit MinValue/MaxValue -> Min/Max,
    TTrackBar SliderVisible -> ShowSlider, OnTopLeftChanged -> OnTopLeftChange).
    Dieselben Umbenennungen auch im Code der .pas ("Spin1.MinValue" -> "Spin1.Min").
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
  - TListView: nur gemeldet (TPPGTileView bzw. TPPGGrid von Hand).
#>
param(
  [string]$Path = '',
  [switch]$SelfTest,
  [switch]$Recurse,
  [switch]$WhatIf,
  [switch]$NoBackup,
  [string[]]$Only = @(),
  [string]$Root = '',
  [string]$Map = '',
  [string[]]$ExtraSource = @(),
  [string]$StyleManager = '',
  [string]$GlyphDir = '',
  [string]$Project = ''
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
  'TShape'            = @('TPPGShape', 'PPG.Shape')
  'TSplitter'         = @('TPPGSplitter', 'PPG.Splitter')
  'TSearchBox'        = @('TPPGSearchEdit', 'PPG.SearchEdit')
  'TMonthCalendar'    = @('TPPGCalendar', 'PPG.Calendar')
  'TDateTimePicker'   = @('TPPGDatePicker', 'PPG.DatePicker')
  'TStatusBar'        = @('TPPGStatusBar', 'PPG.StatusBar')
  'TDBEdit'           = @('TPPGDBEdit', 'PPG.DB.Controls')
  'TDBMemo'           = @('TPPGDBMemo', 'PPG.DB.Controls')
  'TDBCheckBox'       = @('TPPGDBCheckBox', 'PPG.DB.Controls')
  'TDBText'           = @('TPPGDBText', 'PPG.DB.Controls')
  'TDBComboBox'       = @('TPPGDBComboBox', 'PPG.DB.Controls')
  'TDBLookupComboBox' = @('TPPGDBLookupComboBox', 'PPG.DB.Lookup')
  'TDBGrid'           = @('TPPGDBGrid', 'PPG.DB.Grid')
  'TRadioGroup'       = @('TPPGRadioGroup', 'PPG.RadioGroup')
  'TcxRadioGroup'     = @('TPPGRadioGroup', 'PPG.RadioGroup')
  'TcxCheckGroup'     = @('TPPGCheckGroup', 'PPG.RadioGroup')
  'TDBRadioGroup'     = @('TPPGDBRadioGroup', 'PPG.DB.Navigator')
  'TDBNavigator'      = @('TPPGDBNavigator', 'PPG.DB.Navigator')
  'TScrollBox'        = @('TPPGScrollBox', 'PPG.Panel')
  'TPopupMenu'        = @('TPPGPopupMenu', 'PPG.Menus')
}

# PPGlow-Klassen, die von einer VCL-Klasse erben, deren Properties das Skript
# nicht kennt (z. B. TPopupMenu: Items, Images, ...): hier wird nicht gefiltert
$InheritsVcl = @('TPPGPopupMenu')

# Klassen, die nicht automatisch umgestellt werden (API zu verschieden),
# aber im Bericht mit einem Hinweis erscheinen
$ReportOnly = @{
  'TListView' = 'nicht umgestellt - Symbol-/Kachelansicht: TPPGTileView, Detailansicht (vsReport): TPPGGrid (von Hand)'
}

# Umbenennungen je ALTER Klasse: alter Name -> neuer Name ('' = entfernen)
$Renames = @{
  'TAdvEdit'     = @{ 'EmptyText' = 'TextHint' }
  'TAdvComboBox' = @{ 'EmptyText' = 'TextHint' }
  'TBitBtn'      = @{ 'Kind' = '' ; 'Glyph.Data' = ''; 'NumGlyphs' = ''; 'Layout' = '' }
  'TSpeedButton' = @{ 'Glyph.Data' = ''; 'NumGlyphs' = ''; 'Flat' = ''; 'Layout' = '' }
  'TSearchBox'   = @{ 'OnInvokeSearch' = 'OnSearch' }
  # Audit 5c: einheitliche Namen in PPGlow (Min/Max, ShowSlider, On...Change)
  'TSpinEdit'      = @{ 'MinValue' = 'Min'; 'MaxValue' = 'Max' }
  'TTrackBar'      = @{ 'SliderVisible' = 'ShowSlider' }
  'TStringGrid'    = @{ 'OnTopLeftChanged' = 'OnTopLeftChange' }
  'TAdvStringGrid' = @{ 'OnTopLeftChanged' = 'OnTopLeftChange' }
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
$DBGridNoEffect = @('dgAlwaysShowEditor', 'dgAlwaysShowSelection', 'dgThumbTracking')

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
  'ExplicitTop', 'ExplicitWidth', 'ExplicitHeight', 'Padding', 'Touch',
  'DesignSize')  # DesignSize: jedes TWinControl liest es (wichtig fuer Anchors)

$report = New-Object System.Collections.Generic.List[string]

# --- Erlaubte Properties der PPGlow-Klassen aus den Quelltexten -------------

$script:ClassInfo = @{}  # Klasse -> @{ Parent = '...'; Props = HashSet }

function Read-PPGlowClasses {
  $dirs = @(Join-Path $Root 'Source') + @($ExtraSource | Where-Object { $_ })
  foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { throw "Quellordner nicht gefunden: $d" }
  }
  foreach ($f in ($dirs | ForEach-Object { Get-ChildItem -Path $_ -Recurse -Filter '*.pas' -File })) {
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

# Wert einer Property im selben Objekt suchen (vor und nach Zeile $At, gleiche
# Einrueckung; Kind-Objekte und das Objektende begrenzen die Suche)
function Find-DfmProp([string[]]$Lines, [int]$At, [string]$Name) {
  $indent = $Lines[$At].Length - $Lines[$At].TrimStart().Length
  foreach ($dir in @(-1, 1)) {
    for ($k = $At + $dir; $k -ge 0 -and $k -lt $Lines.Count; $k += $dir) {
      $l = $Lines[$k]
      $ind = $l.Length - $l.TrimStart().Length
      $tt = $l.Trim()
      if ($tt -eq '') { continue }
      if ($ind -lt $indent) { break }
      if ($ind -eq $indent -and $tt -match '^(object|inherited|inline)\s') { break }
      if ($ind -eq $indent -and $tt -match "^$([regex]::Escape($Name))\s*=\s*(.*)$") { return $Matches[1].Trim() }
    }
  }
  return $null
}

# Glyph.Data (DFM-Hex: 4 Byte Laenge LE + BMP-Datei) als PNG sichern: nur das
# erste Teilbild, Transparenzfarbe = Pixel unten links (VCL-Regel)
function Save-Glyph([string[]]$HexLines, [int]$NumGlyphs, [string]$OutFile) {
  Add-Type -AssemblyName System.Drawing
  $hex = ($HexLines -join '') -replace '[^0-9A-Fa-f]', ''
  if ($hex.Length -lt 16 -or ($hex.Length % 2) -ne 0) { return 'Glyph-Daten unlesbar' }
  $bytes = New-Object byte[] ($hex.Length / 2)
  for ($b = 0; $b -lt $bytes.Length; $b++) { $bytes[$b] = [Convert]::ToByte($hex.Substring(2 * $b, 2), 16) }
  $len = [BitConverter]::ToInt32($bytes, 0)
  if ($len -le 0 -or $len -gt ($bytes.Length - 4)) { $len = $bytes.Length - 4 }
  if ($bytes[4] -ne 0x42 -or $bytes[5] -ne 0x4D) { return 'Glyph-Daten unlesbar (keine BMP-Daten)' }
  $ms = New-Object System.IO.MemoryStream($bytes, 4, $len)
  $src = $null; $frame = $null
  try {
    $src = New-Object System.Drawing.Bitmap($ms)
    if ($NumGlyphs -lt 1) { $NumGlyphs = 1 }
    $w = [int][Math]::Floor($src.Width / $NumGlyphs)
    if ($w -lt 1) { $w = $src.Width }
    $trans = $src.GetPixel(0, $src.Height - 1)
    $rect = New-Object System.Drawing.Rectangle(0, 0, $w, $src.Height)
    $frame = $src.Clone($rect, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $frame.MakeTransparent($trans)
    $dir = Split-Path -Parent $OutFile
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    $frame.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
  }
  finally {
    if ($frame) { $frame.Dispose() }
    if ($src) { $src.Dispose() }
    $ms.Dispose()
  }
  return $null
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
    if ($null -eq $e.Allowed) { return }
    $sp = ' ' * ($e.Indent + 2)
    if ($VclDefaults.ContainsKey($e.Old)) {
      foreach ($p in $VclDefaults[$e.Old].Keys) {
        if (-not $e.Seen.Contains($p)) {
          $out.Add($sp + "$p = $($VclDefaults[$e.Old][$p])")
          $report.Add("$File :   $($e.Name).$p = $($VclDefaults[$e.Old][$p]) (VCL-Vorgabe, bei $($e.New) anders)")
          $script:changedByDefaults = $true
        }
      }
    }
    # TBitBtn.Kind -> ModalResult/Default/Cancel (nur, was nicht ausdruecklich in der DFM steht)
    if ($e.Pending.Count -gt 0) {
      $done = @(); $manual = @()
      foreach ($pe in $e.Pending) {
        if ($e.Seen.Contains($pe[0])) { continue }
        if (-not $e.Allowed.Contains($pe[0])) { $manual += $pe[0]; continue }
        $out.Add($sp + "$($pe[0]) = $($pe[1])")
        $done += "$($pe[0]) = $($pe[1])"
        $script:changedByDefaults = $true
      }
      if ($done.Count -gt 0) { $report.Add("$File :   $($e.Name) Kind = $($e.Kind) -> $($done -join ', ')") }
      if ($manual.Count -gt 0) { $report.Add("$File :   $($e.Name) Kind = $($e.Kind): $($manual -join ', ') bei $($e.New) nicht veroeffentlicht - von Hand setzen") }
    }
    if ($StyleManager -ne '' -and $e.Allowed.Contains('StyleManager') -and -not $e.Seen.Contains('StyleManager')) {
      $out.Add($sp + "StyleManager = $StyleManager")
      $report.Add("$File :   $($e.Name).StyleManager = $StyleManager")
      $script:changedByDefaults = $true
      $script:styleManagerUsed = $true
    }
  }
  $script:changedByDefaults = $false
  $script:styleManagerUsed = $false
  $migrated = New-Object System.Collections.Generic.List[object]
  $rootName = ''
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
      if ($rootName -eq '') { $rootName = $name }
      $entry = @{ Old = $cls; New = $cls; Allowed = $null; Name = $name; Indent = $indent; Done = $false
        NoFilter = $false; Kind = ''; Pending = (New-Object System.Collections.Generic.List[object])
        Seen = (New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)) }
      if ($ClassMap.Contains($cls) -and (($Only.Count -eq 0) -or ($Only -contains $cls))) {
        $new = $ClassMap[$cls][0]
        [void]$usedUnits.Add($ClassMap[$cls][1])
        $entry.New = $new
        $entry.Allowed = Get-AllowedProps $new
        $migrated.Add(@{ Name = $name; Old = $cls })
        if ($InheritsVcl -contains $new) { $entry.NoFilter = $true }
        elseif (-not $script:ClassInfo.ContainsKey($new)) {
          $entry.NoFilter = $true
          $report.Add("$File :   $name - $new nicht in den Quellen gefunden (-ExtraSource?): Properties werden nicht gefiltert")
        }
        $line = (' ' * $indent) + "$kw ${name}: $new$rest"
        $report.Add("$File : $name $cls -> $new")
        if ($Renames.ContainsKey($cls)) { $script:CodeRenames[$name] = $Renames[$cls] }
        $changed = $true
        if ($cls -eq 'TTreeView') { $report.Add("$File :   $name - Knoten (Items.NodeData) gehen verloren, im Editor neu anlegen") }
      }
      elseif ($ReportOnly.ContainsKey($cls)) {
        $report.Add("$File : $name $cls $($ReportOnly[$cls])")
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
          if ($p -notin @('FieldName', 'Width', 'Alignment', 'ReadOnly', 'PickList.Strings', 'Visible',
            'ButtonStyle')) {
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
      # TBitBtn.Kind -> ModalResult/Default/Cancel (geschrieben beim Objektende)
      if ($cur.Old -eq 'TBitBtn' -and $prop -eq 'Kind') {
        $kind = $value.Trim()
        $modal = @{ bkOK = 1; bkCancel = 2; bkAbort = 3; bkRetry = 4; bkIgnore = 5; bkYes = 6; bkNo = 7; bkAll = 8 }
        $cur.Kind = $kind
        if ($modal.ContainsKey($kind)) {
          [void]$cur.Pending.Add(@('ModalResult', [string]$modal[$kind]))
          if ($kind -eq 'bkOK' -or $kind -eq 'bkYes') { [void]$cur.Pending.Add(@('Default', 'True')) }
          if ($kind -eq 'bkCancel') { [void]$cur.Pending.Add(@('Cancel', 'True')) }
        }
        elseif ($kind -eq 'bkClose') {
          $report.Add("$File :   $($cur.Name) Kind = bkClose entfernt - Schliessen-Verhalten von Hand (Form schliessen, z. B. im OnClick)")
        }
        elseif ($kind -eq 'bkHelp') {
          $report.Add("$File :   $($cur.Name) Kind = bkHelp entfernt - Hilfe-Aufruf von Hand (z. B. Application.HelpContext im OnClick)")
        }
        $changed = $true
        continue
      }
      # Glyphs (TBitBtn/TSpeedButton): als PNG sichern oder entfernen
      if (($cur.Old -eq 'TBitBtn' -or $cur.Old -eq 'TSpeedButton') -and $prop -eq 'Glyph.Data') {
        $end = Get-ValueEnd $lines $i $value
        if ($GlyphDir -ne '') {
          $ng = Find-DfmProp $lines $i 'NumGlyphs'
          $n = 1
          if ($null -ne $ng) { [void][int]::TryParse($ng, [ref]$n) }
          $png = "${rootName}_$($cur.Name).png" -replace '[^\w.\-]', '_'
          $hexLines = @($value) + @($lines[($i + 1)..$end] | Where-Object { $_ -ne $null })
          if ($end -eq $i) { $hexLines = @($value) }
          if ($WhatIf) { $err = $null }
          else { $err = Save-Glyph $hexLines $n (Join-Path $GlyphDir $png) }
          if ($err) { $report.Add("$File :   $($cur.Name).Glyph entfernt - $err") }
          else {
            $report.Add("$File :   $($cur.Name).Glyph entfernt, gesichert als $png - in eine TImageCollection aufnehmen und am Button Images/ImageName setzen")
          }
        }
        else {
          $report.Add("$File :   $($cur.Name).Glyph entfernt (mit -GlyphDir als PNG sichern)")
        }
        $i = $end
        $changed = $true
        continue
      }
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
      if (-not $cur.NoFilter -and -not $cur.Allowed.Contains($top)) {
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
  return @{ Lines = $out; Units = $usedUnits; Migrated = $migrated; Changed = ($changed -or $script:changedByDefaults); Encoding = $src.Encoding }
}

# --- PAS ---------------------------------------------------------------------

# Code-Stellen melden, die durch den Klassenwechsel brechen koennen (aendert nichts)
function Test-PasCode([string]$File, [string]$Text, $Migrated) {
  $classes = @($Migrated | ForEach-Object { $_.Old } | Sort-Object -Unique)
  $names = @($Migrated | ForEach-Object { $_.Name } | Sort-Object -Unique)
  if ($classes.Count -eq 0) { return }
  $codeLines = [regex]::Split($Text, "`r?`n")
  for ($n = 0; $n -lt $codeLines.Count; $n++) {
    $l = $codeLines[$n] -replace '//.*$', '' -replace "'[^']*'", "''"
    if ($l.Trim() -eq '') { continue }
    foreach ($c in $classes) {
      $e = [regex]::Escape($c)
      if ($l -match "(?i)\bas\s+$e\b") { $report.Add("$File :$($n + 1): 'as $c' - Klasse wurde umgestellt, Code pruefen") }
      if ($l -match "(?i)\bis\s+$e\b") { $report.Add("$File :$($n + 1): 'is $c' - Klasse wurde umgestellt, Code pruefen") }
      if ($l -match "(?i)(?<![\w.])$e\s*\(") { $report.Add("$File :$($n + 1): Cast '$c(' - Klasse wurde umgestellt, Code pruefen") }
    }
    foreach ($m in [regex]::Matches($l, '(?i)\bwith\s+([\w\s,.]+?)\s+do\b')) {
      foreach ($part in ($m.Groups[1].Value -split ',')) {
        $nm = $part.Trim()
        if ($names -contains $nm) { $report.Add("$File :$($n + 1): 'with $nm do' - Komponente wurde umgestellt (Eigenschaftsnamen in with-Block pruefen)") }
      }
    }
  }
}

function Convert-Pas([string]$File, $Units, [hashtable]$Handlers, $Migrated) {
  $text = (Read-SourceFile $File).Text
  $orig = $text
  Test-PasCode $File $orig $Migrated
  foreach ($cls in $ClassMap.Keys) {
    if (($Only.Count -gt 0) -and ($Only -notcontains $cls)) { continue }
    $new = $ClassMap[$cls][0]
    # Felddeklarationen im Formular: "Name: TButton;"
    $text = [regex]::Replace($text, "(?m)^(\s+\w+(\s*,\s*\w+)*\s*:\s*)$cls(\s*;)", "`${1}$new`${3}")
  }
  # Umbenannte Properties im Code: "SpinEdit1.MinValue" -> "SpinEdit1.Min"
  # (nur mit Komponentenname davor; in with-Bloecken nicht erkennbar)
  foreach ($comp in $script:CodeRenames.Keys) {
    foreach ($old in $script:CodeRenames[$comp].Keys) {
      $newName = $script:CodeRenames[$comp][$old]
      if ($newName -eq '' -or $old.Contains('.')) { continue }
      $pattern = "(?i)\b$comp\.$old\b"
      if ($text -match $pattern) {
        $text = [regex]::Replace($text, $pattern, "$comp.$newName")
        $report.Add("$File :   Code $comp.$old -> $comp.$newName")
      }
    }
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
  # Fall 1: die Dateien in migrate-tests selbst; weitere Faelle: Unterordner mit
  # eigenen Fixtures und optional args.psd1 (Map, ExtraSource, StyleManager,
  # GlyphDir, Project - relativ zum Fallordner; ExpectPng = Pruefung der PNGs).
  # Je Fall: *.expected = Soll-Dateien, report.contains = Textstuecke, die im
  # Bericht stehen muessen (je Zeile; Pfade sind weggelassen).
  $fixtures = Join-Path $PSScriptRoot 'migrate-tests'
  $tmpRoot = Join-Path ([IO.Path]::GetTempPath()) ('ppg-migrate-' + [Guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $tmpRoot | Out-Null
  try {
    $cases = @($fixtures) + @(Get-ChildItem $fixtures -Directory | ForEach-Object { $_.FullName })
    $failed = 0
    foreach ($caseDir in $cases) {
      $isTop = ($caseDir -eq $fixtures)
      $label = if ($isTop) { '' } else { (Split-Path -Leaf $caseDir) + '\' }
      $tmp = Join-Path $tmpRoot ([Guid]::NewGuid().ToString('N'))
      New-Item -ItemType Directory -Path $tmp | Out-Null
      if ($isTop) {
        Get-ChildItem $caseDir -File | Where-Object { $_.Extension -in '.dfm', '.pas' } |
          ForEach-Object { Copy-Item $_.FullName $tmp }
      }
      else {
        Copy-Item (Join-Path $caseDir '*') $tmp -Recurse
      }
      $splat = @{ Path = $tmp; NoBackup = $true; Root = $Root }
      $argsFile = Join-Path $caseDir 'args.psd1'
      $caseArgs = @{}
      if (Test-Path $argsFile) {
        $caseArgs = Import-PowerShellDataFile $argsFile
        foreach ($k in 'Map', 'GlyphDir', 'Project') { if ($caseArgs.ContainsKey($k)) { $splat[$k] = Join-Path $tmp $caseArgs[$k] } }
        if ($caseArgs.ContainsKey('ExtraSource')) { $splat['ExtraSource'] = @($caseArgs['ExtraSource'] | ForEach-Object { Join-Path $tmp $_ }) }
        if ($caseArgs.ContainsKey('StyleManager')) { $splat['StyleManager'] = $caseArgs['StyleManager'] }
      }
      & $PSCommandPath @splat | Out-Null
      foreach ($exp in Get-ChildItem $caseDir -Filter '*.expected' -File) {
        $actual = Join-Path $tmp ($exp.Name -replace '\.expected$', '')
        $a = ([IO.File]::ReadAllText($actual)) -replace "`r`n", "`n"
        $e = ([IO.File]::ReadAllText($exp.FullName)) -replace "`r`n", "`n"
        if ($a.TrimEnd() -ne $e.TrimEnd()) {
          Write-Output "FEHLER $label$($exp.Name): Ergebnis weicht ab"
          $failed++
        }
        else {
          Write-Output "ok     $label$($exp.Name)"
        }
      }
      $contains = Join-Path $caseDir 'report.contains'
      if (Test-Path $contains) {
        $rep = ([IO.File]::ReadAllText((Join-Path $tmp 'migrate-report.txt'))).Replace($tmp + '\', '')
        $miss = 0
        foreach ($want in [IO.File]::ReadAllLines($contains)) {
          if ($want.Trim() -eq '') { continue }
          if (-not $rep.Contains($want.Trim())) { Write-Output "FEHLER ${label}report.contains: fehlt '$($want.Trim())'"; $miss++ }
        }
        if ($miss -eq 0) { Write-Output "ok     ${label}report.contains" } else { $failed += $miss }
      }
      if ($caseArgs.ContainsKey('ExpectPng')) {
        Add-Type -AssemblyName System.Drawing
        foreach ($pn in $caseArgs['ExpectPng'].Keys) {
          $want = $caseArgs['ExpectPng'][$pn]
          $pf = Join-Path (Join-Path $tmp $caseArgs['GlyphDir']) $pn
          $ok = $true
          if (-not (Test-Path $pf)) { $ok = $false }
          else {
            $bmp = New-Object System.Drawing.Bitmap($pf)
            try {
              if ($bmp.Width -ne $want.Width -or $bmp.Height -ne $want.Height) { $ok = $false }
              foreach ($pt in @($want.Transparent)) {
                $xy = $pt -split ','
                if ($bmp.GetPixel([int]$xy[0], [int]$xy[1]).A -ne 0) { $ok = $false }
              }
              foreach ($pt in @($want.Opaque)) {
                $parts = $pt -split '='
                $xy = $parts[0] -split ','
                $c = $bmp.GetPixel([int]$xy[0], [int]$xy[1])
                if ($c.A -ne 255 -or ('{0:X2}{1:X2}{2:X2}' -f $c.R, $c.G, $c.B) -ne $parts[1]) { $ok = $false }
              }
            }
            finally { $bmp.Dispose() }
          }
          if ($ok) { Write-Output "ok     $label$pn" } else { Write-Output "FEHLER $label${pn}: PNG fehlt oder weicht ab"; $failed++ }
        }
      }
    }
    exit $failed
  }
  finally {
    Remove-Item $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}
if ($Path -eq '') { throw 'Bitte -Path angeben (Ordner oder .dfm).' }

# Zusaetzliche Zuordnungen (-Map): in die Tabellen mischen, Map gewinnt
if ($Map -ne '') {
  $m = Import-PowerShellDataFile -Path $Map
  if ($m.ContainsKey('ClassMap')) { foreach ($k in $m.ClassMap.Keys) { $ClassMap[$k] = @($m.ClassMap[$k]) } }
  if ($m.ContainsKey('Renames')) {
    foreach ($k in $m.Renames.Keys) {
      if (-not $Renames.ContainsKey($k)) { $Renames[$k] = @{} }
      foreach ($p in $m.Renames[$k].Keys) { $Renames[$k][$p] = $m.Renames[$k][$p] }
    }
  }
  if ($m.ContainsKey('ReportOnly')) { foreach ($k in $m.ReportOnly.Keys) { $ReportOnly[$k] = $m.ReportOnly[$k] } }
  if ($m.ContainsKey('InheritsVcl')) { $InheritsVcl = @($InheritsVcl) + @($m.InheritsVcl) }
}

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

# Projektdatei: Text der uses-Liste ohne Kommentare
$projectUses = $null
if ($Project -ne '') {
  $dpr = [IO.File]::ReadAllText($Project)
  $dpr = [regex]::Replace($dpr, '(?s)\(\*.*?\*\)|\{[^}]*\}|//[^\r\n]*', ' ')
  $um = [regex]::Match($dpr, '(?is)\buses\b(.*?);')
  $projectUses = if ($um.Success) { $um.Groups[1].Value } else { '' }
}

foreach ($dfm in $dfms) {
  $handlers = @{}
  $script:CodeRenames = @{}
  $pas = [IO.Path]::ChangeExtension($dfm.FullName, '.pas')
  if ($null -ne $projectUses) {
    $unitName = $dfm.BaseName
    if (Test-Path $pas) {
      $uh = [regex]::Match((Read-SourceFile $pas).Text, '(?im)^\s*unit\s+([\w.]+)\s*;')
      if ($uh.Success) { $unitName = $uh.Groups[1].Value }
    }
    if ($projectUses -notmatch ('(?i)(?<![\w.])' + [regex]::Escape($unitName) + '(?![\w.])')) {
      $report.Add("$($dfm.FullName) : Unit $unitName gehoert nicht zum Projekt - uebersprungen")
      continue
    }
  }
  $res = Convert-Dfm $dfm.FullName $handlers
  if ($null -eq $res -or -not $res.Changed) { continue }
  if ($script:styleManagerUsed -and $StyleManager.Contains('.')) {
    $report.Add("$($dfm.FullName) :   StyleManager = $StyleManager verweist auf ein anderes Datenmodul - dessen Unit muss in der uses-Liste der Unit stehen")
  }
  $newPas = $null
  if (Test-Path $pas) { $newPas = Convert-Pas $pas $res.Units $handlers $res.Migrated }
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
