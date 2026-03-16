unit uTestMain;

{
  Main Form for Radio Factory Tester

  Interactive UI for testing radio commands against physical hardware.
}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ComCtrls, ExtCtrls, Grids,
  uTestDefinitions, uRadioFactory, uNetRadioBase, TF, Log4D, VC;

type
  TfrmTestMain = class(TForm)
    pnlConnection: TPanel;
    grpRadioSelection: TGroupBox;
    cboRadioModel: TComboBox;
    cboConnectionType: TComboBox;
    edtAddress: TEdit;
    edtPort: TEdit;
    cboSerialPort: TComboBox;
    cboBaudRate: TComboBox;
    btnConnect: TButton;
    btnDisconnect: TButton;
    lblStatus: TLabel;

    pnlTests: TPanel;
    grpTests: TGroupBox;
    lvTests: TListView;
    btnRunSelected: TButton;
    btnRunCategory: TButton;
    btnRunAll: TButton;
    btnResetTests: TButton;
    cboCategory: TComboBox;

    pnlDetails: TPanel;
    grpTestDetails: TGroupBox;
    lblTestName: TLabel;
    lblTestDescription: TLabel;
    memoExpectedBehavior: TMemo;
    memoCommandsSent: TMemo;
    memoResponsesReceived: TMemo;
    memoNotes: TMemo;
    btnPass: TButton;
    btnFail: TButton;
    btnManualVerify: TButton;

    pnlLog: TPanel;
    grpLog: TGroupBox;
    memoLog: TMemo;
    btnClearLog: TButton;
    btnSaveLog: TButton;
    btnSaveResults: TButton;

    dlgSaveLog: TSaveDialog;
    dlgSaveResults: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnConnectClick(Sender: TObject);
    procedure btnDisconnectClick(Sender: TObject);
    procedure cboRadioModelChange(Sender: TObject);
    procedure cboConnectionTypeChange(Sender: TObject);
    procedure btnRunSelectedClick(Sender: TObject);
    procedure btnRunCategoryClick(Sender: TObject);
    procedure btnRunAllClick(Sender: TObject);
    procedure btnResetTestsClick(Sender: TObject);
    procedure lvTestsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure btnPassClick(Sender: TObject);
    procedure btnFailClick(Sender: TObject);
    procedure btnManualVerifyClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
    procedure btnSaveLogClick(Sender: TObject);
    procedure btnSaveResultsClick(Sender: TObject);

  private
    FTestSuite: TTestSuite;
    FRadio: TNetRadioBase;
    FCurrentTest: TRadioTest;

    procedure InitializeUI;
    procedure PopulateTestList;
    procedure UpdateTestListItem(Test: TRadioTest);
    procedure DisplayTestDetails(Test: TRadioTest);
    procedure LogMessage(const Msg: string);
    procedure UpdateConnectionUI(Connected: Boolean);

    // Test execution procedures
    procedure ExecuteFrequencyTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteModeTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteRITTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteXITTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteSplitTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteFilterTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteBandTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteTXTest(Test: TRadioTest; Radio: TNetRadioBase);
    procedure ExecuteCWTest(Test: TRadioTest; Radio: TNetRadioBase);

  public
  end;

var
  frmTestMain: TfrmTestMain;
  logger: TLogLogger;

implementation

{$R *.dfm}

procedure TfrmTestMain.FormCreate(Sender: TObject);
begin
  // Initialize logging
  logger := TLogLogger.GetLogger('RadioFactoryTester');
  logger.Level := All;

  FTestSuite := TTestSuite.Create;
  FRadio := nil;
  FCurrentTest := nil;

  InitializeUI;
  FTestSuite.LoadStandardTests;
  PopulateTestList;

  LogMessage('Radio Factory Tester started');
end;

procedure TfrmTestMain.FormDestroy(Sender: TObject);
begin
  if Assigned(FRadio) then
  begin
    FRadio.Disconnect;
    FRadio.Free;
  end;

  FTestSuite.Free;
end;

procedure TfrmTestMain.InitializeUI;
var
  Cat: TTestCategory;
begin
  // Radio models
  cboRadioModel.Items.Clear;
  cboRadioModel.Items.Add('Elecraft K4');
  cboRadioModel.Items.Add('Icom IC-9700');
  cboRadioModel.Items.Add('Icom IC-7610');
  cboRadioModel.Items.Add('Icom IC-7300');
  cboRadioModel.ItemIndex := 0;

  // Connection types (Index 0 = Network, Index 1 = Serial)
  cboConnectionType.Items.Clear;
  cboConnectionType.Items.Add('Network');
  cboConnectionType.Items.Add('Serial');
  cboConnectionType.ItemIndex := 0; // Default to Network

  // Serial ports
  cboSerialPort.Items.Clear;
  cboSerialPort.Items.Add('COM1');
  cboSerialPort.Items.Add('COM2');
  cboSerialPort.Items.Add('COM3');
  cboSerialPort.Items.Add('COM4');
  cboSerialPort.Items.Add('COM5');
  cboSerialPort.Items.Add('COM6');
  cboSerialPort.Items.Add('COM7');
  cboSerialPort.Items.Add('COM8');
  cboSerialPort.ItemIndex := 4; // COM5

  // Baud rates
  cboBaudRate.Items.Clear;
  cboBaudRate.Items.Add('4800');
  cboBaudRate.Items.Add('9600');
  cboBaudRate.Items.Add('19200');
  cboBaudRate.Items.Add('38400');
  cboBaudRate.Items.Add('115200');
  cboBaudRate.ItemIndex := 4; // 115200

  // Categories
  cboCategory.Items.Clear;
  for Cat := Low(TTestCategory) to High(TTestCategory) do
    cboCategory.Items.Add(TestCategoryToString(Cat));
  cboCategory.ItemIndex := 0;

  // Test list view columns
  lvTests.Columns.Clear;
  lvTests.Columns.Add.Caption := 'Test Name';
  lvTests.Columns.Add.Caption := 'Category';
  lvTests.Columns.Add.Caption := 'Status';
  lvTests.Columns[0].Width := 200;
  lvTests.Columns[1].Width := 100;
  lvTests.Columns[2].Width := 100;

  UpdateConnectionUI(False);
  cboConnectionTypeChange(nil);
end;

procedure TfrmTestMain.PopulateTestList;
var
  i: Integer;
  Test: TRadioTest;
  Item: TListItem;
begin
  lvTests.Items.Clear;

  for i := 0 to FTestSuite.Count - 1 do
  begin
    Test := FTestSuite[i];
    Item := lvTests.Items.Add;
    Item.Caption := Test.Name;
    Item.SubItems.Add(TestCategoryToString(Test.Category));
    Item.SubItems.Add(TestStatusToString(Test.Status));
    Item.Data := Test;
  end;
end;

procedure TfrmTestMain.UpdateTestListItem(Test: TRadioTest);
var
  i: Integer;
  Item: TListItem;
begin
  for i := 0 to lvTests.Items.Count - 1 do
  begin
    Item := lvTests.Items[i];
    if Item.Data = Test then
    begin
      Item.SubItems[1] := TestStatusToString(Test.Status);
      Exit;
    end;
  end;
end;

procedure TfrmTestMain.DisplayTestDetails(Test: TRadioTest);
begin
  if not Assigned(Test) then
  begin
    lblTestName.Caption := 'No test selected';
    lblTestDescription.Caption := '';
    memoExpectedBehavior.Clear;
    memoCommandsSent.Clear;
    memoResponsesReceived.Clear;
    memoNotes.Clear;
    Exit;
  end;

  lblTestName.Caption := 'Test: ' + Test.Name;
  lblTestDescription.Caption := Test.Description;
  memoExpectedBehavior.Text := Test.ExpectedBehavior;
  memoCommandsSent.Lines.Assign(Test.CommandsSent);
  memoResponsesReceived.Lines.Assign(Test.ResponsesReceived);
  memoNotes.Text := Test.Notes;

  // Enable manual status buttons if test was run
  btnPass.Enabled := Test.Status <> tsNotRun;
  btnFail.Enabled := Test.Status <> tsNotRun;
  btnManualVerify.Enabled := Test.Status <> tsNotRun;
end;

procedure TfrmTestMain.LogMessage(const Msg: string);
begin
  memoLog.Lines.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss', Now), Msg]));
  logger.Info(Msg);
end;

procedure TfrmTestMain.UpdateConnectionUI(Connected: Boolean);
begin
  btnConnect.Enabled := not Connected;
  btnDisconnect.Enabled := Connected;
  cboRadioModel.Enabled := not Connected;
  cboConnectionType.Enabled := not Connected;
  edtAddress.Enabled := not Connected;
  edtPort.Enabled := not Connected;
  cboSerialPort.Enabled := not Connected;
  cboBaudRate.Enabled := not Connected;

  btnRunSelected.Enabled := Connected;
  btnRunCategory.Enabled := Connected;
  btnRunAll.Enabled := Connected;

  if Connected then
    lblStatus.Caption := 'Connected'
  else
    lblStatus.Caption := 'Disconnected';
end;

procedure TfrmTestMain.cboRadioModelChange(Sender: TObject);
begin
  // Adjust default settings based on radio model
  case cboRadioModel.ItemIndex of
    0: // K4
    begin
      cboBaudRate.ItemIndex := 3; // 38400
      edtAddress.Text := '192.168.1.100';
      edtPort.Text := '9200';
    end;
    1, 2, 3: // Icom radios
    begin
      cboBaudRate.ItemIndex := 3; // 38400
      edtAddress.Text := '';
      edtPort.Text := '';
    end;
  end;
end;

procedure TfrmTestMain.cboConnectionTypeChange(Sender: TObject);
var
  IsSerial: Boolean;
begin
  // Index 0 = Network, Index 1 = Serial
  IsSerial := cboConnectionType.ItemIndex = 1;

  // Show/hide and enable/disable serial controls
  cboSerialPort.Visible := IsSerial;
  cboSerialPort.Enabled := IsSerial and not btnDisconnect.Enabled;
  cboBaudRate.Visible := IsSerial;
  cboBaudRate.Enabled := IsSerial and not btnDisconnect.Enabled;

  // Show/hide and enable/disable network controls
  edtAddress.Visible := not IsSerial;
  edtAddress.Enabled := not IsSerial and not btnDisconnect.Enabled;
  edtPort.Visible := not IsSerial;
  edtPort.Enabled := not IsSerial and not btnDisconnect.Enabled;
end;

procedure TfrmTestMain.btnConnectClick(Sender: TObject);
var
  RadioModel: TRadioModel;
  SerialPort: PortType;
  BaudRate: Integer;
  PortNum: Integer;
begin
  // Map UI selection to factory model
  case cboRadioModel.ItemIndex of
    0: RadioModel := rmElecraftK4;
    1: RadioModel := rmIcomIC9700;
    2: RadioModel := rmIcomIC7610;
    3: RadioModel := rmIcomIC7300;
  else
    ShowMessage('Please select a radio model');
    Exit;
  end;

  BaudRate := StrToIntDef(cboBaudRate.Text, 38400);

  try
    // Index 0 = Network, Index 1 = Serial
    if cboConnectionType.ItemIndex = 1 then
    begin
      // Serial connection
      PortNum := cboSerialPort.ItemIndex + 1; // COM1=1, COM2=2, etc.
      SerialPort := PortType(PortNum);

      LogMessage(Format('Connecting to %s on %s at %d baud...',
        [cboRadioModel.Text, cboSerialPort.Text, BaudRate]));

      FRadio := TRadioFactory.CreateRadioSerial(
        RadioModel,
        SerialPort,
        BaudRate,
        8,  // data bits
        1,  // stop bits
        0,  // parity (none)
        nil
      );
    end
    else
    begin
      // Network connection
      LogMessage(Format('Connecting to %s at %s:%s...',
        [cboRadioModel.Text, edtAddress.Text, edtPort.Text]));

      FRadio := TRadioFactory.CreateRadioNetwork(
        RadioModel,
        edtAddress.Text,
        StrToIntDef(edtPort.Text, 9200),
        nil
      );
    end;

    if Assigned(FRadio) then
    begin
      FRadio.Connect;
      if FRadio.IsConnected then
      begin
        LogMessage('Connected successfully');
        UpdateConnectionUI(True);
      end
      else
      begin
        LogMessage('Connection failed');
        FRadio.Free;
        FRadio := nil;
      end;
    end
    else
    begin
      LogMessage('Failed to create radio object');
    end;

  except
    on E: Exception do
    begin
      LogMessage('Error connecting: ' + E.Message);
      if Assigned(FRadio) then
      begin
        FRadio.Free;
        FRadio := nil;
      end;
    end;
  end;
end;

procedure TfrmTestMain.btnDisconnectClick(Sender: TObject);
begin
  if Assigned(FRadio) then
  begin
    LogMessage('Disconnecting...');
    FRadio.Disconnect;
    FRadio.Free;
    FRadio := nil;
    UpdateConnectionUI(False);
    LogMessage('Disconnected');
  end;
end;

procedure TfrmTestMain.btnRunSelectedClick(Sender: TObject);
var
  Test: TRadioTest;
begin
  if not Assigned(FRadio) then
  begin
    ShowMessage('Please connect to a radio first');
    Exit;
  end;

  if not Assigned(lvTests.Selected) then
  begin
    ShowMessage('Please select a test to run');
    Exit;
  end;

  Test := TRadioTest(lvTests.Selected.Data);
  LogMessage('Running test: ' + Test.Name);

  // Assign appropriate test procedure based on category
  case Test.Category of
    tcFrequency: Test.ExecuteProc := ExecuteFrequencyTest;
    tcMode:      Test.ExecuteProc := ExecuteModeTest;
    tcRIT:       Test.ExecuteProc := ExecuteRITTest;
    tcXIT:       Test.ExecuteProc := ExecuteXITTest;
    tcSplit:     Test.ExecuteProc := ExecuteSplitTest;
    tcFilter:    Test.ExecuteProc := ExecuteFilterTest;
    tcBand:      Test.ExecuteProc := ExecuteBandTest;
    tcTX:        Test.ExecuteProc := ExecuteTXTest;
    tcCW:        Test.ExecuteProc := ExecuteCWTest;
  end;

  Test.Execute(FRadio);
  UpdateTestListItem(Test);
  DisplayTestDetails(Test);

  LogMessage('Test completed: ' + TestStatusToString(Test.Status));
end;

procedure TfrmTestMain.btnRunCategoryClick(Sender: TObject);
var
  Category: TTestCategory;
  i: Integer;
  Test: TRadioTest;
begin
  if not Assigned(FRadio) then
  begin
    ShowMessage('Please connect to a radio first');
    Exit;
  end;

  Category := TTestCategory(cboCategory.ItemIndex);
  LogMessage('Running all tests in category: ' + TestCategoryToString(Category));

  for i := 0 to FTestSuite.Count - 1 do
  begin
    Test := FTestSuite[i];
    if Test.Category = Category then
    begin
      // Assign procedure
      case Test.Category of
        tcFrequency: Test.ExecuteProc := ExecuteFrequencyTest;
        tcMode:      Test.ExecuteProc := ExecuteModeTest;
        tcRIT:       Test.ExecuteProc := ExecuteRITTest;
        tcXIT:       Test.ExecuteProc := ExecuteXITTest;
        tcSplit:     Test.ExecuteProc := ExecuteSplitTest;
        tcFilter:    Test.ExecuteProc := ExecuteFilterTest;
        tcBand:      Test.ExecuteProc := ExecuteBandTest;
        tcTX:        Test.ExecuteProc := ExecuteTXTest;
        tcCW:        Test.ExecuteProc := ExecuteCWTest;
      end;

      Test.Execute(FRadio);
      UpdateTestListItem(Test);
      Application.ProcessMessages;
      Sleep(500); // Brief delay between tests
    end;
  end;

  LogMessage('Category tests completed');
end;

procedure TfrmTestMain.btnRunAllClick(Sender: TObject);
begin
  if not Assigned(FRadio) then
  begin
    ShowMessage('Please connect to a radio first');
    Exit;
  end;

  if MessageDlg('Run all tests? This may take several minutes.',
     mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    Exit;

  LogMessage('Running all tests...');

  // Will implement full test run
  ShowMessage('Full test run not yet implemented');
end;

procedure TfrmTestMain.btnResetTestsClick(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to FTestSuite.Count - 1 do
    FTestSuite[i].Reset;

  PopulateTestList;
  LogMessage('All tests reset');
end;

procedure TfrmTestMain.lvTestsSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
begin
  if Selected and Assigned(Item) then
  begin
    FCurrentTest := TRadioTest(Item.Data);
    DisplayTestDetails(FCurrentTest);
  end;
end;

procedure TfrmTestMain.btnPassClick(Sender: TObject);
begin
  if Assigned(FCurrentTest) then
  begin
    FCurrentTest.Status := tsPass;
    UpdateTestListItem(FCurrentTest);
    DisplayTestDetails(FCurrentTest);
    LogMessage('Test marked as PASS: ' + FCurrentTest.Name);
  end;
end;

procedure TfrmTestMain.btnFailClick(Sender: TObject);
begin
  if Assigned(FCurrentTest) then
  begin
    FCurrentTest.Status := tsFail;
    UpdateTestListItem(FCurrentTest);
    DisplayTestDetails(FCurrentTest);
    LogMessage('Test marked as FAIL: ' + FCurrentTest.Name);
  end;
end;

procedure TfrmTestMain.btnManualVerifyClick(Sender: TObject);
begin
  if Assigned(FCurrentTest) then
  begin
    FCurrentTest.Status := tsManualVerify;
    UpdateTestListItem(FCurrentTest);
    DisplayTestDetails(FCurrentTest);
    LogMessage('Test marked as Manual Verify: ' + FCurrentTest.Name);
  end;
end;

procedure TfrmTestMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmTestMain.btnSaveLogClick(Sender: TObject);
begin
  dlgSaveLog.Filter := 'Text Files (*.txt)|*.txt|All Files (*.*)|*.*';
  dlgSaveLog.DefaultExt := 'txt';
  dlgSaveLog.FileName := Format('RadioTest_%s.txt', [FormatDateTime('yyyymmdd_hhnnss', Now)]);

  if dlgSaveLog.Execute then
  begin
    memoLog.Lines.SaveToFile(dlgSaveLog.FileName);
    LogMessage('Log saved to: ' + dlgSaveLog.FileName);
  end;
end;

{ Test Execution Procedures }

procedure TfrmTestMain.ExecuteFrequencyTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('SetFrequency_14MHz', Test.Name) > 0 then
  begin
    Radio.SetFrequency(14000000, nrVFOA, rmNone);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify radio displays 14.000 MHz';
  end
  else if Pos('SetFrequency_7MHz', Test.Name) > 0 then
  begin
    Radio.SetFrequency(7000000, nrVFOA, rmNone);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify radio displays 7.000 MHz';
  end
  else if Pos('VFOBumpUp', Test.Name) > 0 then
  begin
    Radio.VFOBumpUp(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify frequency increased';
  end
  else if Pos('VFOBumpDown', Test.Name) > 0 then
  begin
    Radio.VFOBumpDown(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify frequency decreased';
  end;
end;

procedure TfrmTestMain.ExecuteModeTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('SetMode_CW', Test.Name) > 0 then
  begin
    Radio.SetMode(rmCW, nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify radio shows CW mode';
  end
  else if Pos('SetMode_USB', Test.Name) > 0 then
  begin
    Radio.SetMode(rmUSB, nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify radio shows USB mode';
  end
  else if Pos('SetMode_LSB', Test.Name) > 0 then
  begin
    Radio.SetMode(rmLSB, nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify radio shows LSB mode';
  end
  else if Pos('ToggleMode', Test.Name) > 0 then
  begin
    Radio.ToggleMode(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify mode changed';
  end;
end;

procedure TfrmTestMain.ExecuteRITTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('RITOn', Test.Name) > 0 then
  begin
    Radio.RITOn(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify RIT indicator is ON';
  end
  else if Pos('SetRITFreq_Plus100', Test.Name) > 0 then
  begin
    Radio.SetRITFreq(nrVFOA, 100);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify RIT shows +100 Hz';
  end
  else if Pos('SetRITFreq_Minus50', Test.Name) > 0 then
  begin
    Radio.SetRITFreq(nrVFOA, -50);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify RIT shows -50 Hz';
  end
  else if Pos('RITClear', Test.Name) > 0 then
  begin
    Radio.RITClear(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify RIT shows 0 Hz';
  end
  else if Pos('RITOff', Test.Name) > 0 then
  begin
    Radio.RITOff(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify RIT indicator is OFF';
  end;
end;

procedure TfrmTestMain.ExecuteXITTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('XITOn', Test.Name) > 0 then
  begin
    Radio.XITOn(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify XIT indicator is ON';
  end
  else if Pos('SetXITFreq_Plus200', Test.Name) > 0 then
  begin
    Radio.SetXITFreq(nrVFOA, 200);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify XIT shows +200 Hz';
  end
  else if Pos('XITClear', Test.Name) > 0 then
  begin
    Radio.XITClear(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify XIT shows 0 Hz';
  end
  else if Pos('XITOff', Test.Name) > 0 then
  begin
    Radio.XITOff(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify XIT indicator is OFF';
  end;
end;

procedure TfrmTestMain.ExecuteSplitTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('SplitOn', Test.Name) > 0 then
  begin
    Radio.Split(True);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify SPLIT indicator is ON';
  end
  else if Pos('SplitOff', Test.Name) > 0 then
  begin
    Radio.Split(False);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify SPLIT indicator is OFF';
  end;
end;

procedure TfrmTestMain.ExecuteFilterTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('SetFilter_500Hz', Test.Name) > 0 then
  begin
    Radio.SetFilterHz(500, nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify filter shows ~500 Hz';
  end
  else if Pos('SetFilter_2400Hz', Test.Name) > 0 then
  begin
    Radio.SetFilterHz(2400, nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify filter shows ~2400 Hz';
  end;
end;

procedure TfrmTestMain.ExecuteBandTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('SetBand_20m', Test.Name) > 0 then
  begin
    Radio.SetBand(rb20m, nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify radio is on 20m (14 MHz)';
  end
  else if Pos('SetBand_40m', Test.Name) > 0 then
  begin
    Radio.SetBand(rb40m, nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify radio is on 40m (7 MHz)';
  end
  else if Pos('ToggleBand', Test.Name) > 0 then
  begin
    Radio.ToggleBand(nrVFOA);
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify band changed';
  end;
end;

procedure TfrmTestMain.ExecuteTXTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('Transmit', Test.Name) > 0 then
  begin
    Radio.Transmit;
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify TX indicator is ON. WARNING: Radio is transmitting!';
  end
  else if Pos('Receive', Test.Name) > 0 then
  begin
    Radio.Receive;
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify TX indicator is OFF';
  end;
end;

procedure TfrmTestMain.ExecuteCWTest(Test: TRadioTest; Radio: TNetRadioBase);
begin
  Test.AddCommandSent('Executing: ' + Test.Name);

  if Pos('BufferCW_TEST', Test.Name) > 0 then
  begin
    Radio.BufferCW('TEST');
    Test.Status := tsManualVerify;
    Test.Notes := 'CW buffered (not sent yet)';
  end
  else if Pos('SendCW', Test.Name) > 0 then
  begin
    // Ensure we have something buffered - if not, buffer "TEST" first
    Radio.BufferCW('TEST');
    Test.AddCommandSent('Buffered: TEST');
    Radio.SendCW;
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify CW message "TEST" sent. WARNING: Radio is transmitting!';
  end
  else if Pos('StopCW', Test.Name) > 0 then
  begin
    Radio.StopCW;
    Test.Status := tsManualVerify;
    Test.Notes := 'Please verify CW stopped';
  end;
end;

procedure TfrmTestMain.btnSaveResultsClick(Sender: TObject);
var
  i: Integer;
  Test: TRadioTest;
  Lines: TStringList;
  CSVLines: TStringList;
  FileName, BaseFileName: string;
  PassCount, FailCount, VerifyCount, NotRunCount: Integer;
  j: Integer;
begin
  if FTestSuite.Count = 0 then
  begin
    ShowMessage('No test results to save');
    Exit;
  end;

  dlgSaveResults.Filter := 'Text Files (*.txt)|*.txt|CSV Files (*.csv)|*.csv|All Files (*.*)|*.*';
  dlgSaveResults.DefaultExt := 'txt';
  dlgSaveResults.FileName := 'TestResults_' + FormatDateTime('yyyymmdd_hhnnss', Now);

  if dlgSaveResults.Execute then
  begin
    Lines := TStringList.Create;
    CSVLines := TStringList.Create;
    try
      FileName := dlgSaveResults.FileName;

      // Count results
      PassCount := 0;
      FailCount := 0;
      VerifyCount := 0;
      NotRunCount := 0;

      for i := 0 to FTestSuite.Count - 1 do
      begin
        Test := FTestSuite.Tests[i];
        case Test.Status of
          tsPass: Inc(PassCount);
          tsFail: Inc(FailCount);
          tsManualVerify: Inc(VerifyCount);
          tsNotRun: Inc(NotRunCount);
        end;
      end;

      // Generate detailed text report
      Lines.Add('========================================');
      Lines.Add('TR4W Radio Factory Test Results');
      Lines.Add('========================================');
      Lines.Add('');
      Lines.Add('Date: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
      if Assigned(FRadio) then
        Lines.Add('Radio: ' + FRadio.radioModel)
      else
        Lines.Add('Radio: Not connected');
      Lines.Add('');
      Lines.Add('Summary:');
      Lines.Add('  Total Tests: ' + IntToStr(FTestSuite.Count));
      Lines.Add('  Passed: ' + IntToStr(PassCount));
      Lines.Add('  Failed: ' + IntToStr(FailCount));
      Lines.Add('  Manual Verify: ' + IntToStr(VerifyCount));
      Lines.Add('  Not Run: ' + IntToStr(NotRunCount));
      Lines.Add('');
      Lines.Add('========================================');
      Lines.Add('');

      // CSV header
      CSVLines.Add('Test Name,Category,Status,Description,Expected Behavior,Commands Sent,Responses Received,Notes,Timestamp');

      // Add each test
      for i := 0 to FTestSuite.Count - 1 do
      begin
        Test := FTestSuite.Tests[i];

        // Detailed text format
        Lines.Add('Test: ' + Test.Name);
        Lines.Add('Category: ' + TestCategoryToString(Test.Category));
        Lines.Add('Status: ' + TestStatusToString(Test.Status));
        Lines.Add('Description: ' + Test.Description);
        Lines.Add('Expected Behavior: ' + Test.ExpectedBehavior);

        if Test.CommandsSent.Count > 0 then
        begin
          Lines.Add('Commands Sent:');
          for j := 0 to Test.CommandsSent.Count - 1 do
            Lines.Add('  ' + Test.CommandsSent[j]);
        end;

        if Test.ResponsesReceived.Count > 0 then
        begin
          Lines.Add('Responses Received:');
          for j := 0 to Test.ResponsesReceived.Count - 1 do
            Lines.Add('  ' + Test.ResponsesReceived[j]);
        end;

        if Test.Notes <> '' then
          Lines.Add('Notes: ' + Test.Notes);

        if Test.Timestamp <> 0 then
          Lines.Add('Timestamp: ' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Test.Timestamp));

        Lines.Add('----------------------------------------');
        Lines.Add('');

        // CSV format (escape commas and quotes in fields)
        CSVLines.Add(
          '"' + StringReplace(Test.Name, '"', '""', [rfReplaceAll]) + '",' +
          '"' + StringReplace(TestCategoryToString(Test.Category), '"', '""', [rfReplaceAll]) + '",' +
          '"' + StringReplace(TestStatusToString(Test.Status), '"', '""', [rfReplaceAll]) + '",' +
          '"' + StringReplace(Test.Description, '"', '""', [rfReplaceAll]) + '",' +
          '"' + StringReplace(Test.ExpectedBehavior, '"', '""', [rfReplaceAll]) + '",' +
          '"' + StringReplace(Test.CommandsSent.Text, '"', '""', [rfReplaceAll]) + '",' +
          '"' + StringReplace(Test.ResponsesReceived.Text, '"', '""', [rfReplaceAll]) + '",' +
          '"' + StringReplace(Test.Notes, '"', '""', [rfReplaceAll]) + '",' +
          '"' + FormatDateTime('yyyy-mm-dd hh:nn:ss', Test.Timestamp) + '"'
        );
      end;

      // Save both formats
      if LowerCase(ExtractFileExt(FileName)) = '.csv' then
      begin
        // Save CSV
        CSVLines.SaveToFile(FileName);
        LogMessage('Test results saved to: ' + FileName);
      end
      else
      begin
        // Save text report
        Lines.SaveToFile(FileName);
        LogMessage('Test results saved to: ' + FileName);

        // Also save CSV with _csv suffix
        BaseFileName := ChangeFileExt(FileName, '');
        CSVLines.SaveToFile(BaseFileName + '_data.csv');
        LogMessage('CSV data saved to: ' + BaseFileName + '_data.csv');
      end;

      ShowMessage('Test results saved successfully!');

    finally
      Lines.Free;
      CSVLines.Free;
    end;
  end;
end;

end.
