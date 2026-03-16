object frmTestMain: TfrmTestMain
  Left = 0
  Top = 0
  Caption = 'TR4W Radio Factory Tester'
  ClientHeight = 700
  ClientWidth = 1100
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Size = 8
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlConnection: TPanel
    Left = 0
    Top = 0
    Width = 1100
    Height = 150
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object grpRadioSelection: TGroupBox
      Left = 10
      Top = 10
      Width = 1080
      Height = 130
      Caption = ' Radio Connection '
      TabOrder = 0
      object lblStatus: TLabel
        Left = 16
        Top = 100
        Width = 800
        Height = 13
        Caption = 'Status: Not connected'
      end
      object cboRadioModel: TComboBox
        Left = 16
        Top = 24
        Width = 200
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 0
        Text = 'Elecraft K4'
        OnChange = cboRadioModelChange
        Items.Strings = (
          'Elecraft K4'
          'Icom IC-9700'
          'Icom IC-7610'
          'Icom IC-7300')
      end
      object cboConnectionType: TComboBox
        Left = 230
        Top = 24
        Width = 120
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 1
        Text = 'Network'
        OnChange = cboConnectionTypeChange
        Items.Strings = (
          'Network'
          'Serial')
      end
      object edtAddress: TEdit
        Left = 16
        Top = 60
        Width = 150
        Height = 21
        TabOrder = 2
        Text = '192.168.1.100'
      end
      object edtPort: TEdit
        Left = 180
        Top = 60
        Width = 80
        Height = 21
        TabOrder = 3
        Text = '7373'
      end
      object cboSerialPort: TComboBox
        Left = 16
        Top = 60
        Width = 100
        Height = 21
        Style = csDropDownList
        TabOrder = 4
        Visible = False
        Items.Strings = (
          'COM1'
          'COM2'
          'COM3'
          'COM4'
          'COM5'
          'COM6'
          'COM7'
          'COM8'
          'COM9'
          'COM10')
      end
      object cboBaudRate: TComboBox
        Left = 130
        Top = 60
        Width = 100
        Height = 21
        Style = csDropDownList
        ItemIndex = 5
        TabOrder = 5
        Text = '115200'
        Visible = False
        Items.Strings = (
          '4800'
          '9600'
          '19200'
          '38400'
          '57600'
          '115200')
      end
      object btnConnect: TButton
        Left = 280
        Top = 58
        Width = 90
        Height = 25
        Caption = 'Connect'
        TabOrder = 6
        OnClick = btnConnectClick
      end
      object btnDisconnect: TButton
        Left = 380
        Top = 58
        Width = 90
        Height = 25
        Caption = 'Disconnect'
        Enabled = False
        TabOrder = 7
        OnClick = btnDisconnectClick
      end
    end
  end
  object pnlTests: TPanel
    Left = 0
    Top = 150
    Width = 350
    Height = 550
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 1
    object grpTests: TGroupBox
      Left = 10
      Top = 10
      Width = 330
      Height = 530
      Caption = ' Tests '
      TabOrder = 0
      object lvTests: TListView
        Left = 10
        Top = 50
        Width = 310
        Height = 420
        Columns = <
          item
            Caption = 'Test'
            Width = 180
          end
          item
            Caption = 'Category'
            Width = 70
          end
          item
            Caption = 'Status'
            Width = 50
          end>
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
        OnSelectItem = lvTestsSelectItem
      end
      object btnRunSelected: TButton
        Left = 10
        Top = 20
        Width = 90
        Height = 25
        Caption = 'Run Selected'
        TabOrder = 1
        OnClick = btnRunSelectedClick
      end
      object btnRunCategory: TButton
        Left = 110
        Top = 20
        Width = 90
        Height = 25
        Caption = 'Run Category'
        TabOrder = 2
        OnClick = btnRunCategoryClick
      end
      object btnRunAll: TButton
        Left = 210
        Top = 20
        Width = 90
        Height = 25
        Caption = 'Run All'
        TabOrder = 3
        OnClick = btnRunAllClick
      end
      object cboCategory: TComboBox
        Left = 110
        Top = 480
        Width = 120
        Height = 21
        Style = csDropDownList
        TabOrder = 4
        Items.Strings = (
          'Frequency'
          'Mode'
          'RIT'
          'XIT'
          'Split'
          'Filter'
          'Band'
          'TX/RX'
          'CW')
      end
      object btnResetTests: TButton
        Left = 10
        Top = 480
        Width = 90
        Height = 25
        Caption = 'Reset Tests'
        TabOrder = 5
        OnClick = btnResetTestsClick
      end
    end
  end
  object pnlDetails: TPanel
    Left = 350
    Top = 150
    Width = 750
    Height = 550
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object grpTestDetails: TGroupBox
      Left = 10
      Top = 10
      Width = 730
      Height = 280
      Caption = ' Test Details '
      TabOrder = 0
      object lblTestName: TLabel
        Left = 10
        Top = 20
        Width = 56
        Height = 13
        Caption = 'Test Name:'
      end
      object lblTestDescription: TLabel
        Left = 10
        Top = 60
        Width = 700
        Height = 13
        Caption = 'Description:'
      end
      object memoExpectedBehavior: TMemo
        Left = 10
        Top = 80
        Width = 710
        Height = 40
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object memoCommandsSent: TMemo
        Left = 10
        Top = 125
        Width = 710
        Height = 60
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
      object memoResponsesReceived: TMemo
        Left = 10
        Top = 190
        Width = 710
        Height = 60
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 2
      end
      object memoNotes: TMemo
        Left = 10
        Top = 255
        Width = 710
        Height = 18
        ReadOnly = True
        TabOrder = 3
      end
      object btnPass: TButton
        Left = 10
        Top = 255
        Width = 80
        Height = 25
        Caption = 'Pass'
        TabOrder = 4
        OnClick = btnPassClick
      end
      object btnFail: TButton
        Left = 100
        Top = 255
        Width = 80
        Height = 25
        Caption = 'Fail'
        TabOrder = 5
        OnClick = btnFailClick
      end
      object btnManualVerify: TButton
        Left = 190
        Top = 255
        Width = 110
        Height = 25
        Caption = 'Manual Verify'
        TabOrder = 6
        OnClick = btnManualVerifyClick
      end
    end
    object pnlLog: TPanel
      Left = 10
      Top = 295
      Width = 730
      Height = 245
      BevelOuter = bvNone
      TabOrder = 1
      object grpLog: TGroupBox
        Left = 0
        Top = 0
        Width = 730
        Height = 245
        Caption = ' Log '
        TabOrder = 0
        object memoLog: TMemo
          Left = 10
          Top = 20
          Width = 710
          Height = 185
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
        object btnClearLog: TButton
          Left = 10
          Top = 210
          Width = 90
          Height = 25
          Caption = 'Clear Log'
          TabOrder = 1
          OnClick = btnClearLogClick
        end
        object btnSaveLog: TButton
          Left = 110
          Top = 210
          Width = 90
          Height = 25
          Caption = 'Save Log'
          TabOrder = 2
          OnClick = btnSaveLogClick
        end
        object btnSaveResults: TButton
          Left = 210
          Top = 210
          Width = 100
          Height = 25
          Caption = 'Save Test Results'
          TabOrder = 3
          OnClick = btnSaveResultsClick
        end
      end
    end
  end
  object dlgSaveLog: TSaveDialog
    DefaultExt = 'log'
    Filter = 'Log Files (*.log)|*.log|Text Files (*.txt)|*.txt|All Files (*.*)|*.*'
    Left = 500
    Top = 100
  end
  object dlgSaveResults: TSaveDialog
    DefaultExt = 'txt'
    Filter = 'Text Report (*.txt)|*.txt|CSV Data (*.csv)|*.csv|All Files (*.*)|*.*'
    Left = 500
    Top = 140
  end
end
