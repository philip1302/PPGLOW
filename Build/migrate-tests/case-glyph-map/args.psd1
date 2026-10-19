@{
  Map         = 'glyph.map.psd1'
  ExtraSource = @('extra')
  GlyphDir    = 'glyphs'
  # Glyph 8x4 (Magenta = Transparenz, links Rot, rechts Blau); NumGlyphs = 2 -> 4x4
  ExpectPng = @{
    'FormGM_Link1.png'  = @{ Width = 4; Height = 4; Transparent = @('0,3', '0,0'); Opaque = @('1,1=FF0000', '2,1=FF0000') }
    'FormGM_Print1.png' = @{ Width = 8; Height = 4; Transparent = @('0,3'); Opaque = @('1,1=FF0000', '5,1=0000FF') }
    'FormGM_Ext1.png'   = @{ Width = 4; Height = 4; Transparent = @('0,3'); Opaque = @('2,1=FF0000') }
    'FormGM_Own1.png'   = @{ Width = 8; Height = 4; Transparent = @('0,3'); Opaque = @('6,2=0000FF') }
  }
}
