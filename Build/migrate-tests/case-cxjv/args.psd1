@{
  GlyphDir = 'glyphs'
  # 4x2-Glyph (32 Bit BMP mit Alpha), NumGlyphs = 2 -> erstes Teilbild 2x2:
  # (0,0) rot, (1,0) und (1,1) durchsichtig, (0,1) blau
  ExpectPng = @{
    'FormCX_BtnGlyph.png' = @{ Width = 2; Height = 2; Transparent = @('1,0', '1,1'); Opaque = @('0,0=FF0000', '0,1=0000FF') }
  }
}
