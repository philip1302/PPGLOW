@{
  GlyphDir = 'glyphs'
  # Glyph 32x16 mit NumGlyphs = 2 -> 16x16; Pixel unten links = Transparenzfarbe;
  # BtnB hat 1 Teilbild: 32x16 bleibt
  ExpectPng = @{
    'FormG_BtnA.png' = @{ Width = 16; Height = 16; Transparent = @('0,15', '15,0', '3,4'); Opaque = @('8,8=FF0000', '4,4=FF0000') }
    'FormG_BtnB.png' = @{ Width = 32; Height = 16; Transparent = @('0,15'); Opaque = @('20,8=0000FF') }
  }
}
