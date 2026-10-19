@{
  # TMyGrid erbt (laut extra\MyGrid.pas) von TPPGDBGrid: Spalten und Handler wie bei TDBGrid
  ClassMap = @{
    'TOldGrid'    = @('TMyGrid', 'My.Grid')
    'TOldExtGrid' = @('TExternalGrid', 'Ext.Grid')
  }
  # TExternalGrid steht in keiner Quelle: Grid-Behandlung ueber GridClasses
  GridClasses  = @('TOldExtGrid')
  # weitere Parametertypen in Handlern migrierter Objekte
  HandlerTypes = @{ 'TOldGridBase' = 'TPPGDBGrid' }
}
