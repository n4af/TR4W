unit LOGHELP;

{ This is a small version of LogHelp to enable better debugging.  When
  you are ready for the real LogHelp - rename help.pas to loghelp.pas }

{$O+}
{$F+}

interface

uses Country9,
  LogSCP,
  LogK1EA, {DOS, Crt, SlowTree,}
  Tree,
  LogGrid,
  LogWind,
  LogNet,
  LogRadio;

const
  QTCFileName                 = 'QTC.DAT';
  QTCListFileName             = 'QTCLIST.DAT';

type
  HelpSubject = (NoSubject);

  TabModeType = (NormalTabMode, ControlFTabMode);

var
   //   ConfirmEditChanges              : boolean;
  TabMode                     : TabModeType;
  UserNameString              : Str40;
   //   VideoGameLength                 : integer;зачем?

procedure AddReminder;
procedure Bin64Decode;
procedure CheckForName;
procedure CoaxLength;
procedure ComputeGridDistance;
procedure ContextHelp(Subject: HelpSubject);
procedure DisplayCountryInformation(FileName: Str80; Call: CallString);

procedure EditWindowEditor(var EditLines: LogEntryArray;
  CursorX: integer; CursorY: integer;
  var DataChanged: boolean);

procedure FreeStartUpScreen;
procedure HexDump;
procedure HexConvert;
procedure Inductance;
procedure IOPort;

procedure KeyCode;

procedure LoadQTCDataFile;
procedure LoopBackTest;
procedure PacketMess;
procedure PacketSimulate;
procedure PassThrough;
procedure PortToFile;
procedure PutUpHelpMenu;
procedure SaveQTCDataFile;
procedure SetAlarm;
procedure ShowIOPorts;
procedure StartUpHelp;
procedure SunriseSunset;
procedure TellMeMyGrid;
procedure UUDecode;
procedure
ViewLogFile;
procedure ViewRadioDebug;

implementation

uses LogCfg;

const
  PageBufferSize              = BigWindowRX * (BigWindowRY - BigWindowLY + 2);
  MaxBuffers                  = 100;

type
  PageBuffer = record
    List: array[0..PageBufferSize - 1] of Char;
    NumberChars: integer;
  end;

  PageBufferPointer = ^PageBuffer;

var
  DisplayedBuffer             : integer;
  FirstBuffer                 : integer;
  LogFileRead                 : Text;
  NumberBuffers               : integer;
  TextBuffer                  : array[0..MaxBuffers - 1] of PageBufferPointer;

procedure TellMeMyGrid;

begin
end;

procedure UUDecode;

begin
end;

procedure Bin64Decode;

begin
end;

procedure LastQTCSent(var Call: CallString; var Time: Str20; var QSONumber: integer);

begin
end;

function GetLogEntryQSONumberReceived(FileString: Str80): integer;

begin
end;

procedure LoadQTCDataFile;

begin
end;

procedure SaveQTCDataFile;

begin
end;

procedure AddReminder;

begin
end;

procedure CheckForName;

begin
end;

procedure LoopBackTest;

begin
end;

procedure PortToFile;

begin
end;

procedure DisplayEditableLogString(LineData: Str80; Cursor: integer);

begin
end;

procedure EditWindowEditor(var EditLines: LogEntryArray;
  CursorX: integer; CursorY: integer;
  var DataChanged: boolean);

begin
end;

procedure LoadPageBuffer(BufferNumber: integer);

begin
end;

procedure DisplayBuffer(BufferNumber: integer);

begin
end;

procedure StartLogFileView(FileName: Str80);

begin
end;

procedure LoadNextPage;

begin
end;

procedure ShowNextPage;

{ This procedure will display the next page and load the next page after
  that into the appropriate buffer.   }

begin
end;

procedure ShowPreviousPage;

begin
end;

procedure ViewRadioDebug;

begin
end;

procedure ViewLogFile;

begin
end;

procedure SetAlarm;

begin
end;

procedure ContextHelp(Subject: HelpSubject);

begin
end;

procedure ProcessAltHelp;

begin
end;

procedure PutUpHelpMenu;

begin
end;

procedure DisplayCountryInformation(FileName: Str80; Call: CallString);

begin
end;

procedure ComputeGridDistance;

begin
end;

procedure HexConvert;

begin
end;

procedure HexDump;

begin
end;

procedure ShowIOPorts;

begin
end;

procedure IOPort;

begin
end;

function DetermineRadioType(SerialPort: PortType): InterfacedRadioType;

begin
end;

procedure Inductance;

begin
end;

procedure PassThrough;

begin
end;

procedure PacketSimulate;

begin
end;

procedure FindLogEntriesOnDisk;

begin
end;

procedure SunriseSunset;

begin
end;

procedure StartUpHelp;

begin
end;

procedure CoaxLength;

begin
end;

procedure FreeStartUpScreen;

begin
end;

procedure PacketMess;

begin
end;

procedure KeyCode;

begin
end;

begin
end.
