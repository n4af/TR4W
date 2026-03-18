unit uTestDefinitions;

{
  Test Definitions for Radio Factory Testing

  Defines test cases, test results, and test execution framework
  for verifying radio commands against physical hardware.
}

interface

uses
  SysUtils, Classes, uNetRadioBase;

type
  // Test categories
  TTestCategory = (
    tcFrequency,    // Frequency control
    tcMode,         // Mode control
    tcRIT,          // RIT functions
    tcXIT,          // XIT functions
    tcSplit,        // Split mode
    tcFilter,       // Filter control
    tcBand,         // Band control
    tcTX,           // TX/RX control
    tcCW            // CW functions
  );

  // Test status
  TTestStatus = (
    tsNotRun,       // Test not yet executed
    tsRunning,      // Test in progress
    tsPass,         // Test passed
    tsFail,         // Test failed
    tsManualVerify, // Requires manual verification
    tsSkipped       // Test skipped (not applicable)
  );

  // Forward declaration
  TRadioTest = class;

  // Test execution delegate
  TTestExecuteProc = procedure(Test: TRadioTest; Radio: TNetRadioBase) of object;

  // Individual test case
  TRadioTest = class
  private
    FName: string;
    FCategory: TTestCategory;
    FDescription: string;
    FExpectedBehavior: string;
    FStatus: TTestStatus;
    FCommandsSent: TStringList;
    FResponsesReceived: TStringList;
    FNotes: string;
    FTimestamp: TDateTime;
    FExecuteProc: TTestExecuteProc;
  public
    constructor Create(AName: string; ACategory: TTestCategory; ADescription: string);
    destructor Destroy; override;

    procedure Reset;
    procedure Execute(Radio: TNetRadioBase);
    procedure AddCommandSent(Cmd: string);
    procedure AddResponse(Resp: string);

    property Name: string read FName;
    property Category: TTestCategory read FCategory;
    property Description: string read FDescription write FDescription;
    property ExpectedBehavior: string read FExpectedBehavior write FExpectedBehavior;
    property Status: TTestStatus read FStatus write FStatus;
    property CommandsSent: TStringList read FCommandsSent;
    property ResponsesReceived: TStringList read FResponsesReceived;
    property Notes: string read FNotes write FNotes;
    property Timestamp: TDateTime read FTimestamp write FTimestamp;
    property ExecuteProc: TTestExecuteProc read FExecuteProc write FExecuteProc;
  end;

  // Test suite
  TTestSuite = class
  private
    FTests: TList;
    FRadio: TNetRadioBase;
    function GetTest(Index: Integer): TRadioTest;
    function GetCount: Integer;
  public
    constructor Create;
    destructor Destroy; override;

    procedure AddTest(Test: TRadioTest);
    procedure Clear;
    procedure LoadStandardTests;  // Load all standard radio tests
    procedure ExecuteAll(Radio: TNetRadioBase);
    procedure ExecuteCategory(Category: TTestCategory; Radio: TNetRadioBase);

    property Tests[Index: Integer]: TRadioTest read GetTest; default;
    property Count: Integer read GetCount;
  end;

  // Helper functions
  function TestCategoryToString(Category: TTestCategory): string;
  function TestStatusToString(Status: TTestStatus): string;
  function BytesToHex(const Data: string): string;

implementation

uses
  TF;  // For TVFO, TRadioMode, etc.

{ TRadioTest }

constructor TRadioTest.Create(AName: string; ACategory: TTestCategory; ADescription: string);
begin
  inherited Create;
  FName := AName;
  FCategory := ACategory;
  FDescription := ADescription;
  FStatus := tsNotRun;
  FCommandsSent := TStringList.Create;
  FResponsesReceived := TStringList.Create;
  FNotes := '';
end;

destructor TRadioTest.Destroy;
begin
  FCommandsSent.Free;
  FResponsesReceived.Free;
  inherited;
end;

procedure TRadioTest.Reset;
begin
  FStatus := tsNotRun;
  FCommandsSent.Clear;
  FResponsesReceived.Clear;
  FNotes := '';
  FTimestamp := 0;
end;

procedure TRadioTest.Execute(Radio: TNetRadioBase);
begin
  Reset;
  FStatus := tsRunning;
  FTimestamp := Now;

  if Assigned(FExecuteProc) then
  begin
    try
      FExecuteProc(Self, Radio);
    except
      on E: Exception do
      begin
        FStatus := tsFail;
        FNotes := 'Exception: ' + E.Message;
      end;
    end;
  end
  else
  begin
    FStatus := tsSkipped;
    FNotes := 'No test procedure defined';
  end;
end;

procedure TRadioTest.AddCommandSent(Cmd: string);
begin
  FCommandsSent.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss.zzz', Now), Cmd]));
end;

procedure TRadioTest.AddResponse(Resp: string);
begin
  FResponsesReceived.Add(Format('[%s] %s', [FormatDateTime('hh:nn:ss.zzz', Now), Resp]));
end;

{ TTestSuite }

constructor TTestSuite.Create;
begin
  inherited Create;
  FTests := TList.Create;
end;

destructor TTestSuite.Destroy;
begin
  Clear;
  FTests.Free;
  inherited;
end;

procedure TTestSuite.AddTest(Test: TRadioTest);
begin
  FTests.Add(Test);
end;

procedure TTestSuite.Clear;
var
  i: Integer;
begin
  for i := 0 to FTests.Count - 1 do
    TRadioTest(FTests[i]).Free;
  FTests.Clear;
end;

function TTestSuite.GetTest(Index: Integer): TRadioTest;
begin
  Result := TRadioTest(FTests[Index]);
end;

function TTestSuite.GetCount: Integer;
begin
  Result := FTests.Count;
end;

procedure TTestSuite.LoadStandardTests;
var
  Test: TRadioTest;
begin
  Clear;

  // Frequency tests
  Test := TRadioTest.Create('SetFrequency_14MHz', tcFrequency, 'Set VFO A to 14.000 MHz');
  Test.ExpectedBehavior := 'Radio displays 14.000.00 MHz on VFO A';
  AddTest(Test);

  Test := TRadioTest.Create('SetFrequency_7MHz', tcFrequency, 'Set VFO A to 7.000 MHz');
  Test.ExpectedBehavior := 'Radio displays 7.000.00 MHz on VFO A';
  AddTest(Test);

  Test := TRadioTest.Create('VFOBumpUp', tcFrequency, 'Bump VFO A up by tuning step');
  Test.ExpectedBehavior := 'Frequency increases by tuning step (typically 10 Hz)';
  AddTest(Test);

  Test := TRadioTest.Create('VFOBumpDown', tcFrequency, 'Bump VFO A down by tuning step');
  Test.ExpectedBehavior := 'Frequency decreases by tuning step (typically 10 Hz)';
  AddTest(Test);

  // Mode tests
  Test := TRadioTest.Create('SetMode_CW', tcMode, 'Set VFO A to CW mode');
  Test.ExpectedBehavior := 'Radio displays CW mode';
  AddTest(Test);

  Test := TRadioTest.Create('SetMode_USB', tcMode, 'Set VFO A to USB mode');
  Test.ExpectedBehavior := 'Radio displays USB mode';
  AddTest(Test);

  Test := TRadioTest.Create('SetMode_LSB', tcMode, 'Set VFO A to LSB mode');
  Test.ExpectedBehavior := 'Radio displays LSB mode';
  AddTest(Test);

  Test := TRadioTest.Create('ToggleMode', tcMode, 'Toggle mode on VFO A');
  Test.ExpectedBehavior := 'Mode changes to next mode in sequence';
  AddTest(Test);

  // RIT tests
  Test := TRadioTest.Create('RITOn', tcRIT, 'Turn RIT on');
  Test.ExpectedBehavior := 'RIT indicator lights on radio';
  AddTest(Test);

  Test := TRadioTest.Create('SetRITFreq_Plus100', tcRIT, 'Set RIT offset to +100 Hz');
  Test.ExpectedBehavior := 'RIT display shows +100 Hz (or +0.1 kHz)';
  AddTest(Test);

  Test := TRadioTest.Create('SetRITFreq_Minus50', tcRIT, 'Set RIT offset to -50 Hz');
  Test.ExpectedBehavior := 'RIT display shows -50 Hz (or -0.05 kHz)';
  AddTest(Test);

  Test := TRadioTest.Create('RITClear', tcRIT, 'Clear RIT offset to 0');
  Test.ExpectedBehavior := 'RIT display shows 0 Hz';
  AddTest(Test);

  Test := TRadioTest.Create('RITOff', tcRIT, 'Turn RIT off');
  Test.ExpectedBehavior := 'RIT indicator turns off';
  AddTest(Test);

  // XIT tests
  Test := TRadioTest.Create('XITOn', tcXIT, 'Turn XIT on');
  Test.ExpectedBehavior := 'XIT indicator lights on radio';
  AddTest(Test);

  Test := TRadioTest.Create('SetXITFreq_Plus200', tcXIT, 'Set XIT offset to +200 Hz');
  Test.ExpectedBehavior := 'XIT display shows +200 Hz (or +0.2 kHz)';
  AddTest(Test);

  Test := TRadioTest.Create('XITClear', tcXIT, 'Clear XIT offset to 0');
  Test.ExpectedBehavior := 'XIT display shows 0 Hz';
  AddTest(Test);

  Test := TRadioTest.Create('XITOff', tcXIT, 'Turn XIT off');
  Test.ExpectedBehavior := 'XIT indicator turns off';
  AddTest(Test);

  // Split tests
  Test := TRadioTest.Create('SplitOn', tcSplit, 'Turn split mode on');
  Test.ExpectedBehavior := 'Split indicator lights, shows VFO A/B frequencies';
  AddTest(Test);

  Test := TRadioTest.Create('SplitOff', tcSplit, 'Turn split mode off');
  Test.ExpectedBehavior := 'Split indicator turns off';
  AddTest(Test);

  // Filter tests
  Test := TRadioTest.Create('SetFilter_500Hz', tcFilter, 'Set filter to 500 Hz (CW)');
  Test.ExpectedBehavior := 'Filter display shows 500 Hz or FIL1';
  AddTest(Test);

  Test := TRadioTest.Create('SetFilter_2400Hz', tcFilter, 'Set filter to 2400 Hz (SSB)');
  Test.ExpectedBehavior := 'Filter display shows 2400 Hz or FIL2';
  AddTest(Test);

  // Band tests
  Test := TRadioTest.Create('SetBand_20m', tcBand, 'Set band to 20m');
  Test.ExpectedBehavior := 'Radio tunes to 20m band (14 MHz)';
  AddTest(Test);

  Test := TRadioTest.Create('SetBand_40m', tcBand, 'Set band to 40m');
  Test.ExpectedBehavior := 'Radio tunes to 40m band (7 MHz)';
  AddTest(Test);

  Test := TRadioTest.Create('ToggleBand', tcBand, 'Toggle to next band');
  Test.ExpectedBehavior := 'Radio changes to next band';
  AddTest(Test);

  // TX/RX tests
  Test := TRadioTest.Create('Transmit', tcTX, 'Key transmitter');
  Test.ExpectedBehavior := 'Radio transmits (TX indicator lights)';
  AddTest(Test);

  Test := TRadioTest.Create('Receive', tcTX, 'Unkey transmitter');
  Test.ExpectedBehavior := 'Radio returns to receive (TX indicator off)';
  AddTest(Test);

  // CW tests
  Test := TRadioTest.Create('BufferCW_TEST', tcCW, 'Buffer CW message "TEST"');
  Test.ExpectedBehavior := 'Message buffered (no transmission yet)';
  AddTest(Test);

  Test := TRadioTest.Create('SendCW', tcCW, 'Send buffered CW');
  Test.ExpectedBehavior := 'Radio transmits "TEST" in CW';
  AddTest(Test);

  Test := TRadioTest.Create('StopCW', tcCW, 'Stop CW transmission');
  Test.ExpectedBehavior := 'CW transmission stops immediately';
  AddTest(Test);
end;

procedure TTestSuite.ExecuteAll(Radio: TNetRadioBase);
var
  i: Integer;
begin
  FRadio := Radio;
  for i := 0 to FTests.Count - 1 do
    TRadioTest(FTests[i]).Execute(Radio);
end;

procedure TTestSuite.ExecuteCategory(Category: TTestCategory; Radio: TNetRadioBase);
var
  i: Integer;
  Test: TRadioTest;
begin
  FRadio := Radio;
  for i := 0 to FTests.Count - 1 do
  begin
    Test := TRadioTest(FTests[i]);
    if Test.Category = Category then
      Test.Execute(Radio);
  end;
end;

{ Helper Functions }

function TestCategoryToString(Category: TTestCategory): string;
begin
  case Category of
    tcFrequency: Result := 'Frequency';
    tcMode:      Result := 'Mode';
    tcRIT:       Result := 'RIT';
    tcXIT:       Result := 'XIT';
    tcSplit:     Result := 'Split';
    tcFilter:    Result := 'Filter';
    tcBand:      Result := 'Band';
    tcTX:        Result := 'TX/RX';
    tcCW:        Result := 'CW';
  else
    Result := 'Unknown';
  end;
end;

function TestStatusToString(Status: TTestStatus): string;
begin
  case Status of
    tsNotRun:       Result := 'Not Run';
    tsRunning:      Result := 'Running...';
    tsPass:         Result := 'PASS';
    tsFail:         Result := 'FAIL';
    tsManualVerify: Result := 'Manual Verify';
    tsSkipped:      Result := 'Skipped';
  else
    Result := 'Unknown';
  end;
end;

function BytesToHex(const Data: string): string;
var
  i: Integer;
begin
  Result := '';
  for i := 1 to Length(Data) do
  begin
    Result := Result + Format('%.2X ', [Ord(Data[i])]);
  end;
  Result := Trim(Result);
end;

end.
