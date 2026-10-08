object Form2: TForm2
  Left = 0
  Top = 0
  Caption = #220'bersicht'
  object Tree1: TTreeView
    Left = 8
    Top = 8
    RowSelect = True
  end
  object Pages1: TPageControl
    Left = 8
    Top = 100
    ActivePage = Sheet1
    object Sheet1: TTabSheet
      Caption = 'A'
    end
  end
  object Split1: TButton
    Left = 8
    Top = 200
    Caption = 'Mehr'
    Style = bsSplitButton
  end
  object Link1: TButton
    Left = 100
    Top = 200
    Style = bsCommandLink
  end
  object Bar1: TProgressBar
    Left = 8
    Top = 240
  end
  object Grid1: TDBGrid
    Left = 8
    Top = 280
    Options = [dgTitles, dgIndicator, dgColumnResize, dgColLines, dgRowLines, dgTabs,
      dgMultiSelect]
  end
end
