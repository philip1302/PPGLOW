object Form7: TForm7
  Left = 0
  Top = 0
  Caption = 'Form7'
  ClientHeight = 200
  ClientWidth = 300
  PixelsPerInch = 96
  object RichEdit1: TRichEdit
    Left = 8
    Top = 8
    Width = 281
    Height = 89
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = []
    Lines.Strings = (
      'RichEdit1')
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
    Zoom = 100
  end
  object DBRichEdit1: TDBRichEdit
    Left = 8
    Top = 104
    Width = 281
    Height = 89
    DataField = 'Notiz'
    DataSource = DataSource1
    TabOrder = 1
  end
  object DataSource1: TDataSource
    Left = 240
    Top = 8
  end
end
