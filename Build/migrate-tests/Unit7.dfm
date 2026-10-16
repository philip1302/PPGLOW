object Form7: TForm7
  Left = 0
  Top = 0
  Caption = 'Form7'
  ClientHeight = 200
  ClientWidth = 300
  PixelsPerInch = 96
  object Image1: TImage
    Left = 8
    Top = 8
    Width = 65
    Height = 65
    Center = True
    IncrementalDisplay = True
    Picture.Data = {
      07544269746D617036000000424D360000000000000036000000280000000100
      0000010000000100180000000000000000000000000000000000000000000000
      0000FF00}
    Proportional = True
    Stretch = True
    Transparent = True
  end
  object DBImage1: TDBImage
    Left = 88
    Top = 8
    Width = 105
    Height = 105
    AutoDisplay = False
    BorderStyle = bsNone
    DataField = 'Photo'
    DataSource = DataSource1
    QuickDraw = False
    Stretch = True
    TabOrder = 0
  end
  object DataSource1: TDataSource
    Left = 240
    Top = 8
  end
end
