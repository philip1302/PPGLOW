<#
  PPGlow Hilfe pro Control (Phase 9f, Property-Referenz 08.10.2026)

  Erzeugt fuer jede Paletten-Komponente (PPG.Reg und PPG.DB.Reg) eine Seite:
    Docs\Controls\<Klasse>.md      (Markdown, im Repository lesbar)
    Docs\Controls\html\<Klasse>.html und index.html (HTML-Hilfe)
  dazu je Unterobjekt-Typ (Appearance, Styles, Spalten, Items ...) eine Seite
    Docs\Controls\types\<Typ>.md und html\types\<Typ>.html
  sowie Docs\Controls\README.md als Uebersicht.

  Quellen je Seite:
  - Kopfkommentar der Unit und ///-Kommentar der Klasse (Zweck, Verhalten)
  - Docs\Controls\notes\<Klasse>.md (von Hand): Vorbild, Unterschiede, Beispiel
  - jede published Property und jedes Ereignis (auch geerbte) mit Typ,
    Vorgabe und Beschreibung. Die Beschreibung kommt aus
    Docs\Controls\props\*.txt (deutsch, mit Nutzung), sonst aus dem
    ///-Kommentar im Quelltext. Format der props-Dateien:
        # Kommentar
        Schluessel = Wirkung
        > Nutzung (optional, auch mehrere Zeilen; `Code` in Backticks)
    Schluessel: "Klasse.Name" (Komponente, Typ oder deklarierende Klasse;
    die genaueste Angabe gewinnt), "VCL.Name" (aus der VCL geerbt) oder
    "Name" (gilt ueberall, nur fuer wirklich gleiche Bedeutung).

  Aufruf:  powershell -ExecutionPolicy Bypass -File Build\make-docs.ps1 [-Missing datei.txt]
           -Missing: Liste aller Properties ohne Beschreibung schreiben
#>
param(
  [string]$Root = '',
  [string]$Missing = ''
)

$ErrorActionPreference = 'Stop'
if ($Root -eq '') { $Root = Split-Path -Parent $PSScriptRoot }
$sep = [IO.Path]::DirectorySeparatorChar
function P([string]$Rel) { return Join-Path $Root ($Rel -replace '[\\/]', $sep) }
. (Join-Path $PSScriptRoot 'docs-parser.ps1')

$DocsDir = P 'Docs\Controls'
$TypesDir = P 'Docs\Controls\types'
$HtmlDir = P 'Docs\Controls\html'
$HtmlTypesDir = P 'Docs\Controls\html\types'
$NotesDir = P 'Docs\Controls\notes'
$PropsDir = P 'Docs\Controls\props'
New-Item -ItemType Directory -Force $DocsDir, $TypesDir, $HtmlDir, $HtmlTypesDir | Out-Null

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

# --- Beschreibungen ----------------------------------------------------------

$script:Desc = @{}    # Schluessel -> @{ Text; Usage }
function Read-Descriptions {
  if (-not (Test-Path $PropsDir)) { return }
  foreach ($f in Get-ChildItem -Path $PropsDir -Filter '*.txt' -File | Sort-Object Name) {
    $last = $null
    $n = 0
    foreach ($l in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
      $n++
      $t = $l.Trim()
      if ($t -eq '' -or $t.StartsWith('#')) { continue }
      if ($t.StartsWith('>')) {
        if ($null -eq $last) { throw "$($f.Name):${n}: Nutzung ohne Eintrag" }
        $u = $t.Substring(1).Trim()
        if ($last.Usage -eq '') { $last.Usage = $u } else { $last.Usage += ' ' + $u }
        continue
      }
      $p = $t.IndexOf('=')
      if ($p -le 0) { throw "$($f.Name):${n}: '=' fehlt" }
      $key = $t.Substring(0, $p).Trim()
      $last = @{ Text = $t.Substring($p + 1).Trim(); Usage = '' }
      if ($script:Desc.ContainsKey($key)) { Write-Warning "$($f.Name):${n}: $key doppelt" }
      $script:Desc[$key] = $last
    }
  }
}

$script:MissingList = New-Object System.Collections.Generic.List[string]
function Find-Description($Model, [string]$Owner, $Prop) {
  # genaueste Angabe zuerst: Owner, dessen Vorfahren (bis zur deklarierenden
  # Klasse), dann der Name allein, zuletzt der Quelltext-Kommentar
  foreach ($c in (Get-ClassChain $Model $Owner)) {
    $k = "$($c.Name).$($Prop.Name)"
    if ($script:Desc.ContainsKey($k)) { return $script:Desc[$k] }
  }
  # "VCL.Name" nur fuer Properties, die aus der VCL geerbt sind
  if ($null -eq $Prop.DeclClass -and $script:Desc.ContainsKey("VCL.$($Prop.Name)")) { return $script:Desc["VCL.$($Prop.Name)"] }
  if ($script:Desc.ContainsKey($Prop.Name)) { return $script:Desc[$Prop.Name] }
  $decl = $Prop.DeclClass
  if ($null -eq $decl) { $decl = 'VCL' }
  if ($Prop.Comment -ne '') {
    # nur der knappe Quelltext-Kommentar: als "noch zu beschreiben" melden
    $script:MissingList.Add("$Owner.$($Prop.Name)  (deklariert: $decl, Typ: $($Prop.Type), Kommentar: $($Prop.Comment))")
    return @{ Text = $Prop.Comment; Usage = '' }
  }
  $script:MissingList.Add("$Owner.$($Prop.Name)  (deklariert: $decl, Typ: $($Prop.Type))")
  return @{ Text = ''; Usage = '' }
}

# Typen der VCL fuer geerbte Properties und Ereignisse
$VclTypes = @{
  Align = 'TAlign'; AlignWithMargins = 'Boolean'; Anchors = 'TAnchors'; BiDiMode = 'TBiDiMode'
  Caption = 'TCaption'; Color = 'TColor'; Constraints = 'TSizeConstraints'; Cursor = 'TCursor'
  CustomHint = 'TCustomHint'; DoubleBuffered = 'Boolean'; DragCursor = 'TCursor'; DragKind = 'TDragKind'
  DragMode = 'TDragMode'; Enabled = 'Boolean'; Font = 'TFont'; Height = 'Integer'; HelpContext = 'THelpContext'
  HelpKeyword = 'string'; HelpType = 'THelpType'; Hint = 'string'; Left = 'Integer'; Margins = 'TMargins'
  Padding = 'TPadding'; ParentBiDiMode = 'Boolean'; ParentColor = 'Boolean'; ParentCustomHint = 'Boolean'
  ParentDoubleBuffered = 'Boolean'; ParentFont = 'Boolean'; ParentShowHint = 'Boolean'; PopupMenu = 'TPopupMenu'
  ShowHint = 'Boolean'; StyleElements = 'TStyleElements'; StyleName = 'string'; TabOrder = 'TTabOrder'; TabStop = 'Boolean'
  Tag = 'NativeInt'; Top = 'Integer'; Touch = 'TTouchManager'; Visible = 'Boolean'; Width = 'Integer'
  Name = 'TComponentName'; Action = 'TBasicAction'; BorderWidth = 'TBorderWidth'; BevelEdges = 'TBevelEdges'
  BevelInner = 'TBevelCut'; BevelKind = 'TBevelKind'; BevelOuter = 'TBevelCut'; BevelWidth = 'TBevelWidth'
  AutoSize = 'Boolean'; DockSite = 'Boolean'; UseDockManager = 'Boolean'; Ctl3D = 'Boolean'; ParentCtl3D = 'Boolean'
  ParentBackground = 'Boolean'; ImeMode = 'TImeMode'; ImeName = 'TImeName'
  OnClick = 'TNotifyEvent'; OnDblClick = 'TNotifyEvent'; OnEnter = 'TNotifyEvent'; OnExit = 'TNotifyEvent'
  OnChange = 'TNotifyEvent'; OnResize = 'TNotifyEvent'; OnKeyDown = 'TKeyEvent'; OnKeyUp = 'TKeyEvent'
  OnKeyPress = 'TKeyPressEvent'; OnMouseDown = 'TMouseEvent'; OnMouseUp = 'TMouseEvent'; OnMouseMove = 'TMouseMoveEvent'
  OnMouseEnter = 'TNotifyEvent'; OnMouseLeave = 'TNotifyEvent'; OnMouseActivate = 'TMouseActivateEvent'
  OnMouseWheel = 'TMouseWheelEvent'; OnMouseWheelDown = 'TMouseWheelUpDownEvent'; OnMouseWheelUp = 'TMouseWheelUpDownEvent'
  OnContextPopup = 'TContextPopupEvent'; OnDragDrop = 'TDragDropEvent'; OnDragOver = 'TDragOverEvent'
  OnEndDrag = 'TEndDragEvent'; OnStartDrag = 'TStartDragEvent'; OnEndDock = 'TEndDragEvent'; OnStartDock = 'TStartDockEvent'
  OnGesture = 'TGestureEvent'; OnCanResize = 'TCanResizeEvent'; OnConstrainedResize = 'TConstrainedResizeEvent'
  OnAlignInsertBefore = 'TAlignInsertBeforeEvent'; OnAlignPosition = 'TAlignPositionEvent'
  OnDockDrop = 'TDockDropEvent'; OnDockOver = 'TDockOverEvent'; OnGetSiteInfo = 'TGetSiteInfoEvent'
  OnUnDock = 'TUnDockEvent'
}
# Ereignisse von TCustomTaskDialog (TPPGTaskDialog)
$TaskDialogTypes = @{
  OnButtonClicked = 'TTaskDlgClickEvent'; OnTimer = 'TTaskDlgTimerEvent'; OnDialogConstructed = 'TNotifyEvent'
  OnDialogCreated = 'TNotifyEvent'; OnDialogDestroyed = 'TNotifyEvent'; OnExpanded = 'TNotifyEvent'
  OnHyperlinkClicked = 'TNotifyEvent'; OnNavigated = 'TNotifyEvent'; OnRadioButtonClicked = 'TNotifyEvent'
  OnVerificationClicked = 'TNotifyEvent'
}
foreach ($k in $TaskDialogTypes.Keys) { if (-not $VclTypes.ContainsKey($k)) { $VclTypes[$k] = $TaskDialogTypes[$k] } }
$VclEvents = @{
  TNotifyEvent = '(Sender: TObject)'
  TKeyEvent = '(Sender: TObject; var Key: Word; Shift: TShiftState)'
  TKeyPressEvent = '(Sender: TObject; var Key: Char)'
  TMouseEvent = '(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer)'
  TMouseMoveEvent = '(Sender: TObject; Shift: TShiftState; X, Y: Integer)'
  TMouseActivateEvent = '(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y, HitTest: Integer; var MouseActivate: TMouseActivate)'
  TMouseWheelEvent = '(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean)'
  TMouseWheelUpDownEvent = '(Sender: TObject; Shift: TShiftState; MousePos: TPoint; var Handled: Boolean)'
  TContextPopupEvent = '(Sender: TObject; MousePos: TPoint; var Handled: Boolean)'
  TDragDropEvent = '(Sender, Source: TObject; X, Y: Integer)'
  TDragOverEvent = '(Sender, Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean)'
  TEndDragEvent = '(Sender, Target: TObject; X, Y: Integer)'
  TStartDragEvent = '(Sender: TObject; var DragObject: TDragObject)'
  TStartDockEvent = '(Sender: TObject; var DragObject: TDragDockObject)'
  TGestureEvent = '(Sender: TObject; const EventInfo: TGestureEventInfo; var Handled: Boolean)'
  TCanResizeEvent = '(Sender: TObject; var NewWidth, NewHeight: Integer; var Resize: Boolean)'
  TConstrainedResizeEvent = '(Sender: TObject; var MinWidth, MinHeight, MaxWidth, MaxHeight: Integer)'
  TAlignInsertBeforeEvent = '(Sender: TWinControl; C1, C2: TControl): Boolean'
  TAlignPositionEvent = '(Sender: TWinControl; Control: TControl; var NewLeft, NewTop, NewWidth, NewHeight: Integer; var AlignRect: TRect; AlignInfo: TAlignInfo)'
  TDrawItemEvent = '(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState)'
  TMeasureItemEvent = '(Control: TWinControl; Index: Integer; var Height: Integer)'
  TTVChangedEvent = '(Sender: TObject; Node: TTreeNode)'
  TTVChangingEvent = '(Sender: TObject; Node: TTreeNode; var AllowChange: Boolean)'
  TTVExpandingEvent = '(Sender: TObject; Node: TTreeNode; var AllowExpansion: Boolean)'
  TTVCollapsingEvent = '(Sender: TObject; Node: TTreeNode; var AllowCollapse: Boolean)'
  TTVExpandedEvent = '(Sender: TObject; Node: TTreeNode)'
  TTVEditingEvent = '(Sender: TObject; Node: TTreeNode; var AllowEdit: Boolean)'
  TTVEditedEvent = '(Sender: TObject; Node: TTreeNode; var S: string)'
  TTabChangingEvent = '(Sender: TObject; var AllowChange: Boolean)'
  TSelectCellEvent = '(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean)'
  TDrawCellEvent = '(Sender: TObject; ACol, ARow: Longint; Rect: TRect; State: TGridDrawState)'
  TGetEditEvent = '(Sender: TObject; ACol, ARow: Longint; var Value: string)'
  TSetEditEvent = '(Sender: TObject; ACol, ARow: Longint; const Value: string)'
  TMovedEvent = '(Sender: TObject; FromIndex, ToIndex: Longint)'
  TDataChangeEvent = '(Sender: TObject; Field: TField)'
  TCloseEvent = '(Sender: TObject; var Action: TCloseAction)'
  THelpEvent = '(Command: Word; Data: THelpEventData; var CallHelp: Boolean): Boolean'
  TMenuChangeEvent = '(Sender: TObject; Source: TMenuItem; Rebuild: Boolean)'
  TUnDockEvent = '(Sender: TObject; Client: TControl; NewTarget: TWinControl; var Allow: Boolean)'
  TDockOverEvent = '(Sender: TObject; Source: TDragDockObject; X, Y: Integer; State: TDragState; var Accept: Boolean)'
  TDockDropEvent = '(Sender: TObject; Source: TDragDockObject; X, Y: Integer)'
  TGetSiteInfoEvent = '(Sender: TObject; DockClient: TControl; var InfluenceRect: TRect; MousePos: TPoint; var CanDock: Boolean)'
  TLBGetDataEvent = '(Control: TWinControl; Index: Integer; var Data: string)'
  TLBGetDataObjectEvent = '(Control: TWinControl; Index: Integer; var DataObject: TObject)'
  TLBFindDataEvent = '(Control: TWinControl; FindString: string): Integer'
  TTabGetImageEvent = '(Sender: TObject; TabIndex: Integer; var ImageIndex: Integer)'
  TSysLinkEvent = '(Sender: TObject; const Link: string; LinkType: TSysLinkType)'
  TFixedCellClickEvent = '(Sender: TObject; ACol, ARow: Longint)'
  TTaskDlgClickEvent = '(Sender: TObject; ModalResult: TModalResult; var CanClose: Boolean)'
  TTaskDlgTimerEvent = '(Sender: TObject; TickCount: Cardinal; var Reset: Boolean)'
  TDTParseInputEvent = '(Sender: TObject; const UserString: string; var DateAndTime: TDateTime; var AllowChange: Boolean)'
}

# --- Formatierung ------------------------------------------------------------

function Esc([string]$S) { return $S.Replace('|', '\|') }

function Format-Header([string]$Header) {
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

$script:TypeQueue = New-Object System.Collections.Generic.List[string]
function Test-TypePage($Model, [string]$Type) {
  # Eigene Seite fuer Klassen mit published Properties oder Collections
  if (-not $Model.Classes.ContainsKey($Type)) { return $false }
  $c = $Model.Classes[$Type]
  if ($c.ItemClass -ne '' -and $Model.Classes.ContainsKey($c.ItemClass)) { return $true }
  $props = Get-PublishedProps $Model $Type
  return ($props.Count -gt 0) -and -not (Test-IsComponent $Model $Type)
}

function Test-IsComponent($Model, [string]$Type) {
  foreach ($c in (Get-ClassChain $Model $Type)) {
    if ($c.Parent -match '^(TComponent|TControl|TWinControl|TCustomControl|TGraphicControl|TCustomPanel|TCustomForm|TForm)$') { return $true }
  }
  return $false
}

function Format-Type($Model, [string]$Type, [string]$Prefix) {
  if ($Type -eq '') { return '' }
  if (Test-TypePage $Model $Type) {
    if (-not $script:TypeQueue.Contains($Type)) { $script:TypeQueue.Add($Type) }
    return "[$Type]($Prefix$Type.md)"
  }
  return "``$Type``"
}

function Format-Values($Model, [string]$Type) {
  $t = $Type
  $isSet = $false
  if ($Model.Sets.ContainsKey($t)) { $t = $Model.Sets[$t]; $isSet = $true }
  if (-not $Model.Enums.ContainsKey($t)) { return '' }
  $vals = ($Model.Enums[$t] -split ',' | ForEach-Object { '`' + $_.Trim() + '`' }) -join ', '
  if ($isSet) { return "Menge aus: $vals." }
  return "Werte: $vals."
}

function Format-Default($Prop) {
  if ($Prop.ReadOnly) { return 'nur lesen' }
  if ($Prop.Default -ne '') { return "``$($Prop.Default)``" }
  return ''
}

function Build-PropRows($Model, [string]$Owner, $Props, [string]$Prefix) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('| Eigenschaft | Typ | Vorgabe | Wirkung und Nutzung |')
  [void]$sb.AppendLine('|---|---|---|---|')
  foreach ($p in $Props) {
    $type = $p.Type
    if ($type -eq '' -and $VclTypes.ContainsKey($p.Name)) { $type = $VclTypes[$p.Name] }
    $d = Find-Description $Model $Owner $p
    $text = $d.Text
    $vals = Format-Values $Model $type
    if ($vals -ne '' -and $text -notmatch 'Werte:') { $text = ($text + ' ' + $vals).Trim() }
    if ($d.Usage -ne '') { $text += ' Nutzung: ' + $d.Usage }
    [void]$sb.AppendLine("| ``$($p.Name)`` | $(Esc (Format-Type $Model $type $Prefix)) | $(Esc (Format-Default $p)) | $(Esc $text) |")
  }
  return $sb.ToString()
}

function Build-EventRows($Model, [string]$Owner, $Events) {
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine('| Ereignis | Typ und Parameter | Wann und wozu |')
  [void]$sb.AppendLine('|---|---|---|')
  foreach ($p in $Events) {
    $type = $p.Type
    if ($type -eq '' -and $VclTypes.ContainsKey($p.Name)) { $type = $VclTypes[$p.Name] }
    $sig = ''
    if ($Model.Events.ContainsKey($type)) {
      $m = [regex]::Match($Model.Events[$type], '(\(.*\))(\s*:\s*\w+)?\s*of\s+object')
      if ($m.Success) { $sig = $m.Groups[1].Value + $m.Groups[2].Value }
    }
    elseif ($VclEvents.ContainsKey($type)) { $sig = $VclEvents[$type] }
    $d = Find-Description $Model $Owner $p
    $text = $d.Text
    if ($d.Usage -ne '') { $text += ' Nutzung: ' + $d.Usage }
    $cell = "``$type``"
    if ($sig -ne '') { $cell += " ``$sig``" }
    [void]$sb.AppendLine("| ``$($p.Name)`` | $(Esc $cell) | $(Esc $text) |")
  }
  return $sb.ToString()
}

function Build-Page($Model, $Info, [string]$Group) {
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
  $all = Get-PublishedProps $Model $Info.Name
  $own = @($all | Where-Object { -not $_.IsEvent -and $null -ne $_.DeclClass })
  $vcl = @($all | Where-Object { -not $_.IsEvent -and $null -eq $_.DeclClass })
  $ev = @($all | Where-Object { $_.IsEvent })
  if ($own.Count -gt 0) {
    [void]$sb.AppendLine('## PPGlow-Eigenschaften')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine('Verlinkte Typen haben eine eigene Seite mit allen Untereigenschaften.')
    [void]$sb.AppendLine('')
    [void]$sb.Append((Build-PropRows $Model $Info.Name $own 'types/'))
    [void]$sb.AppendLine('')
  }
  if ($vcl.Count -gt 0) {
    [void]$sb.AppendLine('## Eigenschaften wie in der VCL')
    [void]$sb.AppendLine('')
    [void]$sb.Append((Build-PropRows $Model $Info.Name $vcl 'types/'))
    [void]$sb.AppendLine('')
  }
  if ($ev.Count -gt 0) {
    [void]$sb.AppendLine('## Ereignisse')
    [void]$sb.AppendLine('')
    [void]$sb.Append((Build-EventRows $Model $Info.Name $ev))
    [void]$sb.AppendLine('')
  }
  [void]$sb.AppendLine('---')
  [void]$sb.AppendLine('Erzeugt von `Build\make-docs.ps1`. Eigene Ergaenzungen in `Docs\Controls\notes\' + $Info.Name + '.md`, Beschreibungen der Eigenschaften in `Docs\Controls\props\*.txt`.')
  return $sb.ToString()
}

function Build-TypePage($Model, [string]$Type, $UsedBy) {
  $c = $Model.Classes[$Type]
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.AppendLine("# $Type")
  [void]$sb.AppendLine('')
  [void]$sb.AppendLine("Typ in Unit ``$($c.Unit)`` - Basis ``$($c.Parent)``")
  [void]$sb.AppendLine('')
  if ($c.Doc -ne '') { [void]$sb.AppendLine($c.Doc); [void]$sb.AppendLine('') }
  if ($script:Desc.ContainsKey($Type)) {
    $d = $script:Desc[$Type]
    [void]$sb.AppendLine($d.Text)
    if ($d.Usage -ne '') { [void]$sb.AppendLine(''); [void]$sb.AppendLine('Nutzung: ' + $d.Usage) }
    [void]$sb.AppendLine('')
  }
  if ($c.ItemClass -ne '' -and $Model.Classes.ContainsKey($c.ItemClass)) {
    [void]$sb.AppendLine("Collection: Die Eintraege sind vom Typ $(Format-Type $Model $c.ItemClass ''). Im Designer ueber den Collection-Editor (Doppelklick auf die Eigenschaft), im Code ueber ``Add``, ``Items[i]``, ``Count``, ``Delete``, ``Clear``.")
    [void]$sb.AppendLine('')
  }
  $all = Get-PublishedProps $Model $Type
  $props = @($all | Where-Object { -not $_.IsEvent })
  $ev = @($all | Where-Object { $_.IsEvent })
  if ($props.Count -gt 0) {
    [void]$sb.AppendLine('## Eigenschaften')
    [void]$sb.AppendLine('')
    [void]$sb.Append((Build-PropRows $Model $Type $props ''))
    [void]$sb.AppendLine('')
  }
  if ($ev.Count -gt 0) {
    [void]$sb.AppendLine('## Ereignisse')
    [void]$sb.AppendLine('')
    [void]$sb.Append((Build-EventRows $Model $Type $ev))
    [void]$sb.AppendLine('')
  }
  if ($UsedBy.Count -gt 0) {
    [void]$sb.AppendLine('## Verwendet in')
    [void]$sb.AppendLine('')
    [void]$sb.AppendLine((($UsedBy | Sort-Object -Unique | ForEach-Object {
      if ($_ -like 'type:*') { $n = $_.Substring(5); "[$n]($n.md)" } else { "[$_](../$_.md)" } }) -join ', '))
    [void]$sb.AppendLine('')
  }
  [void]$sb.AppendLine('---')
  [void]$sb.AppendLine('Erzeugt von `Build\make-docs.ps1`; Beschreibungen in `Docs\Controls\props\*.txt`.')
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

function Split-Row([string]$Line) {
  # Zellen an | trennen, \| bleibt Text
  $cells = New-Object System.Collections.Generic.List[string]
  $cur = New-Object System.Text.StringBuilder
  $s = $Line.Trim().Trim('|')
  for ($i = 0; $i -lt $s.Length; $i++) {
    $ch = $s[$i]
    if ($ch -eq '\' -and $i + 1 -lt $s.Length -and $s[$i + 1] -eq '|') { [void]$cur.Append('|'); $i++; continue }
    if ($ch -eq '|') { $cells.Add($cur.ToString()); [void]$cur.Clear(); continue }
    [void]$cur.Append($ch)
  }
  $cells.Add($cur.ToString())
  return , $cells
}

function ConvertTo-Html([string]$Md, [string]$Title, [string]$IndexHref) {
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
      $cells = Split-Row $l
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
  $css = 'body{font-family:Segoe UI,sans-serif;max-width:72em;margin:2em auto;padding:0 1em;color:#242424;line-height:1.5}' +
    'code{background:#f3f3f3;padding:0 .25em;border-radius:3px}pre{background:#f3f3f3;padding:.75em;overflow:auto}' +
    'table{border-collapse:collapse}td,th{border:1px solid #ddd;padding:.25em .5em;text-align:left;vertical-align:top}a{color:#0f6cbd}' +
    '@media (prefers-color-scheme:dark){body{background:#202020;color:#e6e6e6}code,pre{background:#2b2b2b}a{color:#60cdff}td,th{border-color:#444}}'
  return "<!DOCTYPE html>`n<html lang=""de""><head><meta charset=""utf-8""><meta name=""viewport"" content=""width=device-width, initial-scale=1""><title>$Title</title><style>$css</style></head><body>`n<p><a href=""$IndexHref"">PPGlow-Hilfe</a></p>`n" +
    $out.ToString() + "</body></html>`n"
}

# --- Lauf --------------------------------------------------------------------

$model = Read-PPGSources (P 'Source')
Read-Descriptions
$utf8 = New-Object System.Text.UTF8Encoding($false)
$index = New-Object System.Text.StringBuilder
[void]$index.AppendLine('# PPGlow - Hilfe pro Control')
[void]$index.AppendLine('')
[void]$index.AppendLine('Erzeugt von `Build\make-docs.ps1` aus den Quelltexten, `Docs\Controls\notes` und `Docs\Controls\props`. Jede Seite listet alle Eigenschaften und Ereignisse mit Typ, Vorgabe und Wirkung; Unterobjekte (Appearance, Styles, Spalten ...) stehen unter [Typen](#typen). HTML-Fassung: `Docs\Controls\html\index.html`.')
[void]$index.AppendLine('')
$count = 0
$usedBy = @{}
foreach ($g in $groups.Keys) {
  [void]$index.AppendLine("## Palette $g")
  [void]$index.AppendLine('')
  [void]$index.AppendLine('| Control | Unit | Kurzbeschreibung |')
  [void]$index.AppendLine('|---|---|---|')
  foreach ($cls in $groups[$g]) {
    if (-not $model.Classes.ContainsKey($cls)) { Write-Warning "$cls nicht gefunden"; continue }
    $info = $model.Classes[$cls]
    $before = $script:TypeQueue.Count
    $md = Build-Page $model $info $g
    foreach ($p in (Get-PublishedProps $model $cls)) {
      if ($p.Type -ne '' -and (Test-TypePage $model $p.Type)) {
        if (-not $usedBy.ContainsKey($p.Type)) { $usedBy[$p.Type] = New-Object System.Collections.Generic.List[string] }
        $usedBy[$p.Type].Add($cls)
      }
    }
    [IO.File]::WriteAllText((Join-Path $DocsDir "$cls.md"), $md, $utf8)
    [IO.File]::WriteAllText((Join-Path $HtmlDir "$cls.html"), (ConvertTo-Html $md $cls 'index.html'), $utf8)
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

# Typ-Seiten (die Warteschlange waechst, solange Typen auf weitere verweisen)
$done = 0
for ($i = 0; $i -lt $script:TypeQueue.Count; $i++) {
  $t = $script:TypeQueue[$i]
  $c = $model.Classes[$t]
  if ($c.ItemClass -ne '' -and $model.Classes.ContainsKey($c.ItemClass)) { [void](Format-Type $model $c.ItemClass '') }
  foreach ($p in (Get-PublishedProps $model $t)) {
    if ($p.Type -ne '' -and (Test-TypePage $model $p.Type)) {
      [void](Format-Type $model $p.Type '')   # in die Warteschlange
      if (-not $usedBy.ContainsKey($p.Type)) { $usedBy[$p.Type] = New-Object System.Collections.Generic.List[string] }
      $usedBy[$p.Type].Add("type:$t")
    }
  }
  if ($c.ItemClass -ne '' -and $model.Classes.ContainsKey($c.ItemClass)) {
    if (-not $usedBy.ContainsKey($c.ItemClass)) { $usedBy[$c.ItemClass] = New-Object System.Collections.Generic.List[string] }
    $usedBy[$c.ItemClass].Add("type:$t")
  }
}
$sortedTypes = @($script:TypeQueue | Sort-Object)
foreach ($t in $sortedTypes) {
  $ub = @()
  if ($usedBy.ContainsKey($t)) { $ub = $usedBy[$t] }
  $md = Build-TypePage $model $t $ub
  [IO.File]::WriteAllText((Join-Path $TypesDir "$t.md"), $md, $utf8)
  $html = (ConvertTo-Html $md $t '../index.html').Replace('href="../', 'href="../')
  [IO.File]::WriteAllText((Join-Path $HtmlTypesDir "$t.html"), $html, $utf8)
  $done++
}
[void]$index.AppendLine('## Typen')
[void]$index.AppendLine('')
[void]$index.AppendLine((($sortedTypes | ForEach-Object { "[$_](types/$_.md)" }) -join ', '))
[void]$index.AppendLine('')
[IO.File]::WriteAllText((Join-Path $DocsDir 'README.md'), $index.ToString(), $utf8)
[IO.File]::WriteAllText((Join-Path $HtmlDir 'index.html'), (ConvertTo-Html $index.ToString() 'PPGlow-Hilfe' 'index.html'), $utf8)
$miss = @($script:MissingList | Sort-Object -Unique)
if ($Missing -ne '') { [IO.File]::WriteAllLines($Missing, $miss, $utf8) }
Write-Output "$count Seiten und $done Typ-Seiten in $DocsDir; ohne Beschreibung: $($miss.Count)"
