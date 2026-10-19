@{
  # Ziele erben (laut extra\MyButtons.pas) von TPPGButton: Glyph-Behandlung automatisch
  ClassMap = @{
    'TOldLinkButton'  = @('TMyLinkButton', 'My.Buttons')
    'TOldPrintButton' = @('TMyPrintButton', 'My.Buttons')
    'TOldOwnButton'   = @('TMyLayoutButton', 'My.Buttons')
    'TOldExtButton'   = @('TExternalButton', 'Ext.Buttons')
    'TOldThing'       = @('TExternalThing', 'Ext.Things')
    'TOldEdit'        = @('TMyGlyphEdit', 'My.Buttons')
  }
  # TExternalButton steht in keiner Quelle: Glyph-Behandlung ueber GlyphClasses
  GlyphClasses = @('TOldExtButton')
  # Renames der Map gewinnen: NumGlyphs bleibt hier als Umbenennung
  Renames = @{ 'TOldPrintButton' = @{ 'NumGlyphs' = '' } }
}
