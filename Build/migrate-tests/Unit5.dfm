object Form5: TForm5
  Left = 0
  Top = 0
  Caption = 'Form5'
  ClientHeight = 300
  ClientWidth = 500
  DesignSize = (
    500
    300)
  PixelsPerInch = 96
  object Panel1: TPanel
    Left = 8
    Top = 8
    Width = 300
    Height = 100
    Anchors = [akLeft, akTop, akRight]
    AutoSize = True
    Caption = 'Panel1'
    TabOrder = 0
    DesignSize = (
      300
      100)
    object Edit1: TEdit
      Left = 8
      Top = 8
      Width = 100
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
    end
  end
  object OkBtn: TBitBtn
    Left = 8
    Top = 120
    Caption = 'OK'
    Kind = bkOK
    TabOrder = 1
  end
  object CancelBtn: TBitBtn
    Left = 100
    Top = 120
    Caption = 'Abbrechen'
    ModalResult = 2
    Kind = bkCancel
    TabOrder = 2
  end
  object YesBtn: TBitBtn
    Left = 200
    Top = 120
    Kind = bkYes
    TabOrder = 3
  end
  object NoBtn: TBitBtn
    Left = 300
    Top = 120
    Kind = bkNo
    TabOrder = 4
  end
  object CloseBtn: TBitBtn
    Left = 8
    Top = 160
    Kind = bkClose
    TabOrder = 5
  end
  object CustomBtn: TBitBtn
    Left = 100
    Top = 160
    Kind = bkCustom
    TabOrder = 6
  end
  object PopupMenu1: TPopupMenu
    AutoPopup = False
    Left = 400
    Top = 8
    object Item1: TMenuItem
      Caption = 'Eins'
      ShortCut = 16433
      OnClick = Item1Click
    end
    object Item2: TMenuItem
      Caption = '-'
    end
  end
end
