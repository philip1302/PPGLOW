object FormGR: TFormGR
  Left = 0
  Top = 0
  object Grid1: TOldGrid
    Left = 8
    Top = 8
    Options = [dgTitles, dgAlwaysShowEditor]
    OnCellClick = Grid1CellClick
    OnDrawColumnCell = Grid1DrawColumnCell
    OnTitleRightClick = Grid1TitleRightClick
    OnColumnResized = Grid1ColumnResized
    SortOnTitleClick = False
    Bogus = 1
    Columns = <
      item
        Expanded = False
        FieldName = 'Name'
        Title.Caption = 'Name'
        Title.Font.Style = [fsBold]
        Width = 120
        Visible = True
      end>
  end
  object Grid2: TOldExtGrid
    Left = 8
    Top = 200
    OnCellClick = Grid1CellClick
    Columns = <
      item
        Expanded = False
        FieldName = 'Nr'
        Title.Caption = 'Nr.'
        Title.Alignment = taRightJustify
        Visible = True
      end>
  end
end
