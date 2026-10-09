<#
  Quelltext-Parser fuer make-docs.ps1: liest alle Units unter Source und
  liefert ein Modell der Klassen (Eltern, Properties mit Typ, Vorgabe und
  ///-Kommentar, published-Liste), Aufzaehlungstypen und Ereignistypen.

  Read-PPGSources <Ordner>          -> Modell
  Get-PublishedProps <Modell> <Klasse>
      -> published Properties der Klasse samt geerbter, je Eintrag Name, Typ,
         Vorgabe, Kommentar, DeclClass (Klasse mit der typisierten
         Deklaration; $null = aus der VCL geerbt), ReadOnly, IsEvent
#>

function New-PPGModel {
  return [pscustomobject]@{
    Classes = @{}   # Name -> Klasse
    Enums   = @{}   # Name -> Werte (Text)
    Events  = @{}   # Name -> Parameterliste (Text)
    Sets    = @{}   # Name -> Basistyp
  }
}

function Split-PropStatement([string]$Stmt) {
  # "property Name[Idx]: Typ index n read X write Y stored Z default D;"
  $r = [pscustomobject]@{ Name = ''; Type = ''; Default = ''; ReadOnly = $false; IsArray = $false; Index = '' }
  $m = [regex]::Match($Stmt, '^property\s+(\w+)\s*(\[[^\]]*\])?\s*(.*)$', 'Singleline')
  if (-not $m.Success) { return $null }
  $r.Name = $m.Groups[1].Value
  $r.IsArray = $m.Groups[2].Success
  $rest = $m.Groups[3].Value.Trim()
  if ($rest.StartsWith(':')) {
    $tm = [regex]::Match($rest, '^:\s*(.+?)\s*(?=\b(read|write|index|stored|default|nodefault|implements)\b|;|$)', 'Singleline')
    if ($tm.Success) { $r.Type = ($tm.Groups[1].Value -replace '\s+', ' ').Trim() }
    $hasRead = $rest -match '\bread\b'
    $hasWrite = $rest -match '\bwrite\b'
    $r.ReadOnly = $hasRead -and -not $hasWrite
  }
  $im = [regex]::Match($rest, '\bindex\s+(\w+)')
  if ($im.Success) { $r.Index = $im.Groups[1].Value }
  $dm = [regex]::Match($rest, '\bdefault\s+(.+?)\s*;\s*$', 'Singleline')
  if ($dm.Success) { $r.Default = ($dm.Groups[1].Value -replace '\s+', ' ').Trim() }
  return $r
}

function Read-PPGSources([string]$Dir) {
  $model = New-PPGModel
  foreach ($f in Get-ChildItem -Path $Dir -Recurse -Filter '*.pas' -File) {
    if ($f.FullName -match '\\__(history|recovery)\\') { continue }
    $text = [IO.File]::ReadAllText($f.FullName)
    $unitName = ''
    $um = [regex]::Match($text, '(?m)^unit\s+([\w.]+)\s*;')
    if ($um.Success) { $unitName = $um.Groups[1].Value }
    $header = ''
    $hm = [regex]::Match($text, '(?s)^unit\s+[\w.]+;\s*\{(?!\$)(.*?)\}')
    if ($hm.Success) { $header = $hm.Groups[1].Value }
    # nur der interface-Teil
    $ip = $text.IndexOf("`nimplementation")
    if ($ip -gt 0) { $text = $text.Substring(0, $ip) }
    $lines = $text -split "`r?`n"
    $doc = New-Object System.Collections.Generic.List[string]
    $cur = $null
    $section = ''
    $stmt = $null
    $stmtDoc = ''
    $pending = $null   # mehrzeilige Aufzaehlung / Ereignistyp
    $pendingName = ''
    $pendingKind = ''
    $depth = 0
    foreach ($raw in $lines) {
      $t = $raw.Trim()
      if ($null -ne $pending) {
        $pending += ' ' + $t
        # Ereignistyp erst fertig, wenn die Klammern geschlossen sind ("of object;")
        $evDone = $false
        if ($pendingKind -eq 'event' -and $t -match ';\s*(//.*)?$') {
          $evDone = ([regex]::Matches($pending, '\(').Count -eq [regex]::Matches($pending, '\)').Count)
        }
        if (($pendingKind -eq 'enum' -and $t -match '\)\s*;') -or $evDone) {
          if ($pendingKind -eq 'enum') {
            $model.Enums[$pendingName] = (($pending -replace '//[^\r\n]*', '') -replace '^.*?\(', '' -replace '\)\s*;.*$', '' -replace '\s+', ' ').Trim()
          }
          else {
            $model.Events[$pendingName] = ($pending -replace '\s+', ' ').Trim().TrimEnd(';')
          }
          $pending = $null
        }
        continue
      }
      if ($null -ne $stmt) {
        $code = ($t -replace '\s//.*$', '')
        $stmt += ' ' + $code
        if ($code.TrimEnd().EndsWith(';')) {
          $p = Split-PropStatement $stmt.Trim()
          if ($null -ne $p) { Add-Prop $cur $p $stmtDoc $section }
          $stmt = $null
        }
        continue
      }
      if ($t.StartsWith('///')) { $doc.Add($t.Substring(3).Trim()); continue }
      if ($t -match '^\{\$' -or $t -eq '') { continue }
      if ($null -eq $cur) {
        if ($t -match '^(T\w+)\s*=\s*class\s*;') { $doc.Clear(); continue }
        # Metaklasse "TFooClass = class of TFoo;" ist keine Klasse mit Rumpf
        if ($t -match '^(T\w+)\s*=\s*class\s+of\b') { $doc.Clear(); continue }
        if ($t -match '^(T\w+)\s*=\s*class(\s+(sealed|abstract))?\s*(\(\s*([\w.]+))?') {
          $name = $Matches[1]
          $parent = 'TObject'
          if ($Matches[5]) { $parent = $Matches[5] }
          # Vorfahrenliste darf ueber mehrere Zeilen gehen; "class(TBar);" hat keinen Rumpf
          if ($t -match '\)\s*;\s*(//.*)?$') {
            # "TFoo = class(TBar);" ohne Rumpf
            $model.Classes[$name] = [pscustomobject]@{ Name = $name; Parent = $parent; Unit = $unitName; Header = $header
              Doc = ($doc -join ' '); Props = [ordered]@{}; Published = New-Object System.Collections.Generic.List[string]; ItemClass = '' }
            $doc.Clear(); continue
          }
          $cur = [pscustomobject]@{ Name = $name; Parent = $parent; Unit = $unitName; Header = $header
            Doc = ($doc -join ' '); Props = [ordered]@{}; Published = New-Object System.Collections.Generic.List[string]; ItemClass = '' }
          $model.Classes[$name] = $cur
          $section = 'published'   # ohne Angabe: published (wie bei $M+)
          if ($parent -eq 'TObject') { $section = 'public' }
          $depth = 0
          $doc.Clear()
          continue
        }
        if ($t -match '^(T\w+)\s*=\s*\((.*)$') {
          $pendingName = $Matches[1]; $pendingKind = 'enum'; $pending = $t
          if ($t -match '\)\s*;') {
            $model.Enums[$pendingName] = (($t -replace '^.*?\(', '') -replace '\)\s*;.*$', '' -replace '\s+', ' ').Trim()
            $pending = $null
          }
          $doc.Clear(); continue
        }
        if ($t -match '^(T\w+)\s*=\s*set\s+of\s+(\w+)\s*;') { $model.Sets[$Matches[1]] = $Matches[2]; $doc.Clear(); continue }
        if ($t -match '^(T\w+)\s*=\s*(reference\s+to\s+)?procedure\b') {
          $pendingName = $Matches[1]; $pendingKind = 'event'; $pending = $t
          if ($t -match ';\s*(//.*)?$' -and $t -match 'of\s+object') {
            $model.Events[$pendingName] = ($t -replace '\s+', ' ').Trim().TrimEnd(';'); $pending = $null
          }
          elseif ($t -match ';\s*$' -and $t -notmatch '\(' ) {
            $model.Events[$pendingName] = $t; $pending = $null
          }
          $doc.Clear(); continue
        }
        if (-not $t.StartsWith('//')) { $doc.Clear() }
        continue
      }
      # in einer Klasse
      if ($t -match '^(?i)(strict\s+)?(private|protected|public|published)\s*$') { $section = $Matches[2].ToLower(); $doc.Clear(); continue }
      if ($t -match '^(?i)(record|case\b.*\bof)\b' -or $t -match '=\s*record\b' -or $t -match ':\s*(packed\s+)?(array\b.*\bof\s+)?record\s*$') { $depth++; continue }
      if ($t -match '^(?i)end\s*;') {
        if ($depth -gt 0) { $depth--; continue }
        $cur = $null; $doc.Clear(); continue
      }
      if ($t -match '^(?i)(class\s+)?property\s') {
        $code = ($t -replace '^(?i)class\s+', '') -replace '\s//.*$', ''
        $stmtDoc = ($doc -join ' ')
        $cm = [regex]::Match($t, '\s//\s*(.*)$')
        if ($stmtDoc -eq '' -and $cm.Success) { $stmtDoc = $cm.Groups[1].Value.Trim() }
        $doc.Clear()
        if ($code.TrimEnd().EndsWith(';')) {
          $p = Split-PropStatement $code.Trim()
          if ($null -ne $p) { Add-Prop $cur $p $stmtDoc $section }
        }
        else { $stmt = $code }
        continue
      }
      if (-not $t.StartsWith('//') -and -not $t.StartsWith('{')) { $doc.Clear() }
    }
  }
  return $model
}

function Add-Prop($Cls, $P, [string]$Doc, [string]$Section) {
  $rec = [pscustomobject]@{ Name = $P.Name; Type = $P.Type; Default = $P.Default; ReadOnly = $P.ReadOnly
    IsArray = $P.IsArray; Comment = $Doc; Section = $Section }
  $Cls.Props[$P.Name] = $rec
  if ($Section -eq 'published' -and -not $Cls.Published.Contains($P.Name)) { $Cls.Published.Add($P.Name) }
  if ($P.Name -eq 'Items' -and $P.IsArray -and $P.Type -ne '') { $Cls.ItemClass = $P.Type }
}

function Get-ClassChain($Model, [string]$Name) {
  $chain = New-Object System.Collections.Generic.List[object]
  $n = $Name
  $guard = 0
  while ($Model.Classes.ContainsKey($n) -and $guard -lt 30) {
    $chain.Add($Model.Classes[$n])
    $n = $Model.Classes[$n].Parent
    $guard++
  }
  return , $chain
}

function Get-PublishedProps($Model, [string]$Name) {
  $chain = Get-ClassChain $Model $Name
  $names = New-Object System.Collections.Generic.List[string]
  foreach ($c in $chain) { foreach ($n in $c.Published) { if (-not $names.Contains($n)) { $names.Add($n) } } }
  $result = New-Object System.Collections.Generic.List[object]
  foreach ($n in $names) {
    $type = ''; $decl = $null; $def = ''; $hasDef = $false; $cmt = ''; $ro = $false
    foreach ($c in $chain) {
      if (-not $c.Props.Contains($n)) { continue }
      $r = $c.Props[$n]
      if (-not $hasDef -and $r.Default -ne '') { $def = $r.Default; $hasDef = $true }
      if ($cmt -eq '' -and $r.Comment -ne '') { $cmt = $r.Comment }
      if ($r.Type -ne '') { $type = $r.Type; $decl = $c.Name; $ro = $r.ReadOnly; break }
    }
    $result.Add([pscustomobject]@{ Name = $n; Type = $type; Default = $def; Comment = $cmt; DeclClass = $decl
      ReadOnly = $ro; IsEvent = (($n -cmatch '^On[A-Z]') -and ($type -eq '' -or $type -match '(Event|Proc)$')) })
  }
  return , $result
}
