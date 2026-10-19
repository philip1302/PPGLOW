object FormCX: TFormCX
  Left = 0
  Top = 0
  Caption = 'FormCX'
  ClientHeight = 400
  ClientWidth = 600
  PixelsPerInch = 96
  TextHeight = 13
  object BtnGlyph: TcxButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Glyph'
    LookAndFeel.Kind = lfUltraFlat
    LookAndFeel.NativeStyle = True
    OptionsImage.Glyph.SourceDPI = 96
    OptionsImage.Glyph.Data = {
      424D560000000000000036000000280000000400000002000000010020000000
      00002000000000000000000000000000000000000000FF0000FFC0C0C00000FF
      00FF00FF00FF0000FFFFC0C0C00000FF00FF00FF00FF}
    OptionsImage.Layout = blGlyphTop
    OptionsImage.NumGlyphs = 2
    OptionsImage.Spacing = 4
    SpeedButtonOptions.CanBeFocused = False
    SpeedButtonOptions.Flat = True
    TabOrder = 0
    OnClick = BtnGlyphClick
  end
  object BtnIndex: TcxButton
    Left = 96
    Top = 8
    Width = 75
    Height = 25
    Action = actTest
    OptionsImage.ImageIndex = 3
    OptionsImage.Images = ImageList1
    TabOrder = 1
  end
  object BtnDrop: TcxButton
    Left = 184
    Top = 8
    Width = 75
    Height = 25
    Caption = 'Drop'
    Kind = cxbkDropDown
    TabOrder = 2
  end
  object CheckA: TcxCheckBox
    Left = 8
    Top = 48
    Caption = 'Zeitraum'
    State = cbsChecked
    Properties.AllowGrayed = True
    Properties.Alignment = taRightJustify
    Properties.OnChange = CheckAPropertiesChange
    Style.LookAndFeel.NativeStyle = False
    StyleHot.LookAndFeel.NativeStyle = False
    TabOrder = 3
    OnClick = CheckAClick
  end
  object LookupA: TcxDBLookupComboBox
    Left = 8
    Top = 80
    DataBinding.DataField = 'Code'
    DataBinding.DataSource = srcMain
    Properties.DropDownListStyle = lsEditList
    Properties.ImmediatePost = True
    Properties.KeyFieldNames = 'Id'
    Properties.ListColumns = <
      item
        FieldName = 'Name'
      end
      item
        Width = 40
        FieldName = 'Ort'
      end>
    Properties.ListSource = srcList
    Properties.OnEditValueChanged = LookupAChanged
    Style.BorderStyle = ebsSingle
    Style.Color = clYellow
    StyleHot.BorderStyle = ebsThick
    TabOrder = 4
    Width = 200
  end
  object ToggleA: TdxDBToggleSwitch
    Left = 8
    Top = 112
    AutoSize = False
    DataBinding.DataField = 'Flag_Kz'
    DataBinding.DataSource = srcMain
    Properties.DisplayChecked = 'Gruppe'
    Properties.DisplayUnchecked = 'Einzeln'
    Properties.ImmediatePost = True
    Properties.StateIndicator.Kind = sikText
    Properties.StateIndicator.OffText = 'Einzeln'
    Properties.StateIndicator.OnText = 'Gruppe'
    Properties.ValueChecked = 'J'
    Properties.ValueUnchecked = 'N'
    TabOrder = 5
    Height = 21
    Width = 312
  end
  object Pages: TcxPageControl
    Left = 8
    Top = 144
    Width = 400
    Height = 150
    TabOrder = 6
    Properties.ActivePage = SheetB
    Properties.CustomButtons.Buttons = <>
    Properties.MultiLine = True
    Properties.TabPosition = tpBottom
    Properties.TabSlants.Kind = skCutCorner
    LookAndFeel.NativeStyle = False
    ClientRectBottom = 150
    ClientRectRight = 400
    ClientRectTop = 24
    object SheetA: TcxTabSheet
      Caption = 'Eins'
      ImageIndex = 0
    end
    object SheetB: TcxTabSheet
      Caption = 'Zwei'
      ImageIndex = 1
    end
  end
  object NavA: TcxNavigator
    Left = 8
    Top = 300
    Width = 200
    Height = 25
    Control = GridView
    Buttons.Insert.ImageIndex = 5
    TabOrder = 7
  end
  object CheckCombo: TcxCheckComboBox
    Left = 8
    Top = 332
    Properties.Items = <
      item
        Description = 'Gut'
      end
      item
        Description = 'Schlecht'
        ShortDescription = 'S'
      end
      item
      end>
    StyleFocused.LookAndFeel.NativeStyle = False
    TabOrder = 8
    Width = 200
  end
  object CheckComboLeer: TcxCheckComboBox
    Left = 220
    Top = 332
    Properties.Items = <>
    TabOrder = 9
    Width = 200
  end
  object DirEdit: TJvDirectoryEdit
    Left = 8
    Top = 364
    Width = 200
    Height = 22
    AcceptFiles = False
    DisabledColor = clGray
    DialogKind = dkWin32
    Flat = True
    ParentFlat = False
    ButtonWidth = 24
    TabOrder = 10
    Text = 'DirEdit'
    OnAfterDialog = DirEditAfterDialog
  end
  object FileEdit: TJvFilenameEdit
    Left = 220
    Top = 364
    Width = 200
    Height = 22
    AddQuotes = False
    DefaultExt = 'dat'
    DialogKind = dkSave
    Filter = 'Daten(*.dat)|*.dat'
    DialogTitle = 'Datei'
    TabOrder = 11
    Text = 'FileEdit'
  end
  object FileEditOpen: TJvFilenameEdit
    Left = 432
    Top = 364
    Width = 100
    Height = 22
    TabOrder = 12
    Text = 'FileEditOpen'
  end
  object JvChkBoth: TJvCheckBox
    Left = 8
    Top = 390
    Width = 13
    Height = 17
    Checked = True
    State = cbChecked
    TabOrder = 13
    LinkedControls = <>
  end
  object JvChkOnly: TJvCheckBox
    Left = 40
    Top = 390
    Width = 13
    Height = 17
    Checked = True
    TabOrder = 14
    LinkedControls = <>
  end
  object JvChkOff: TJvCheckBox
    Left = 72
    Top = 390
    Width = 13
    Height = 17
    TabOrder = 15
    LinkedControls = <>
  end
  object JvCombo: TJvComboBox
    Left = 100
    Top = 390
    Width = 92
    Height = 24
    Style = csDropDownList
    Flat = True
    ParentFlat = False
    TabOrder = 16
    Text = ''
    OnCloseUp = JvComboCloseUp
    Items.Strings = (
      '2009'
      '2008')
  end
end
