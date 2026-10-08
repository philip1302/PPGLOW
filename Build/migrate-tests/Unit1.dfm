object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 300
  ClientWidth = 500
  object Button1: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'OK'
    ModalResult = 1
    TabOrder = 0
    WordWrap = True
    ElevationRequired = True
  end
  object BitBtn1: TBitBtn
    Left = 8
    Top = 40
    Caption = 'Hilfe'
    Kind = bkHelp
    Glyph.Data = {
      0A000000}
    NumGlyphs = 2
  end
  object Edit1: TAdvEdit
    Left = 8
    Top = 80
    EmptyText = 'Name'
    LabelCaption = 'X'
    Text = 'abc'
  end
  object Switch1: TToggleSwitch
    Left = 8
    Top = 120
    State = tssOn
  end
  object StatusBar1: TStatusBar
    Panels = <
      item
        Text = 'Bereit'
        Width = 100
      end
      item
        Width = 50
      end>
  end
  object Grid1: TDBGrid
    Left = 8
    Top = 160
    DataSource = DataSource1
    FixedColor = clSkyBlue
    TitleFont.Name = 'Segoe UI'
    OnTitleClick = Grid1TitleClick
    Columns = <
      item
        Expanded = False
        FieldName = 'Name'
        Title.Caption = 'Kunde'
        Title.Font.Style = [fsBold]
        Width = 120
        Visible = True
      end
      item
        Expanded = False
        Color = clInfoBk
        FieldName = 'Ort'
        Font.Color = clNavy
        Font.Name = 'Arial'
        Title.Alignment = taCenter
        Title.Caption = 'Ort'
        Title.Color = clYellow
        Visible = False
      end>
  end
  object Memo1: TMemo
    Lines.Strings = (
      'Zeile 1'
      'Zeile 2')
    TabOrder = 3
  end
  object DataSource1: TDataSource
    Left = 300
  end
end
