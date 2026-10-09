object Form4: TForm4
  Left = 0
  Top = 0
  Caption = 'Form4'
  ClientHeight = 200
  ClientWidth = 400
  object Spin1: TSpinEdit
    Left = 8
    Top = 8
    Width = 80
    Height = 24
    MaxValue = 99
    MinValue = 1
    TabOrder = 0
    Value = 5
  end
  object Grid1: TStringGrid
    Left = 8
    Top = 40
    Width = 300
    Height = 120
    TabOrder = 1
    OnTopLeftChanged = Grid1TopLeftChanged
  end
  object Track1: TTrackBar
    Left = 8
    Top = 168
    Width = 150
    Height = 24
    SliderVisible = False
    TabOrder = 2
  end
end
