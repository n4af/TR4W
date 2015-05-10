{
 Copyright Larry Tyree, N6TR, 2011,2012,2013,2014,2015.

 This file is part of TR4W    (TRDOS)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W.  If not, see
 <http: www.gnu.org/licenses/>.
 }
unit LogRadio;

{$IMPORTEDDATA OFF}

{ This unit has the RadioObject in it, which is used to do everything
  associated with radio interface.  It relies on LogK1EA for sent and
  received data buffer support, but nothing else.  LogWind pulls data
  out of this unit without using any other interface to the radio (I
  hope. }

interface

uses
  TF,
  VC,
  Tree,

  Windows;

const

  ICOM_TRANSFER_FREQ                    = #$00;
  ICOM_TRANSFER_MODE                    = #$01;

  ICOM_GET_FREQ                         = #$03;
  ICOM_GET_MODE                         = #$04;

  ICOM_SET_FREQ                         = #$05;
  ICOM_SET_MODE                         = #$06;
  ICOM_SET_VFO_COMMAND                  = #$07;

  ICOM_SET_SPLIT_MODE                   = #$0F;

  ICOM_SET_VFO_A_COMMAND                = #$00;
  ICOM_SET_VFO_B_COMMAND                = #$01;

  ICOM_END_OF_MESSAGE_CODE              = #$FD;
  ICOM_PREAMBLE_CODE                    = #$FE;

  ICOM_CONTROLLER_ADDRESS               = #$E0;
  ICOM_OTHER_RADIOS_ADDRESS             = #$00;

type
  tr4w_RTSDTRType = (RtsDtr_Nothing, RtsDtr_OFF, RtsDtr_ON, RtsDtr_CW, RtsDtr_PTT);

const
  tr4w_RTSDTRTypeSA                     : array[tr4w_RTSDTRType] of PChar =
    (
    'NONE',
    'OFF',
    'ON',
    'CW',
    'PTT'
    );

type
  ActiveVFOStatusType = (vfoUnknown, VFOA, VFOB, vfoMem);

  TXRXType = (VFODisabled, RXOnly, TXOnly, Transceive, UnknownTXRX);

  //  SplitType = (NoSplit, SplitOn);
  //  RITType = (NoRIT, RITOn);

    { PollingStatusType is used for the basic state machine states }
  TRMode = (
    TR0,
    TR1, //spacebar TwoRadioMode = false
    TR2, //spacebar TwoRadioMode = true
    TR3
    );

  PollingStatusType = (NoPollStatus,
    PollStatus1,
    PollStatus2,
    PollStatus3,
    PollStatus4,
    PollStatus5);

  VFOStatusType = record
    {04}Frequency: LONGINT;
    {04}RITFreq: integer;
    {01}Band: BandType;
    {01}Mode: ModeType;
    {01}Split: boolean;
    {01}RIT: boolean;
    {01}XIT: boolean;
  end;

  RadioStatusRecord = record
//    {24}VFOA: VFOStatusType;
//    {24}VFOB: VFOStatusType;
    VFO: array[ActiveVFOStatusType] of VFOStatusType;
    {04}Freq: LONGINT; // This is the active frequency for the radio
    {04}Split: LongBool;
    {04}RIT: LongBool;
    {04}XIT: LongBool;
    {04}RITFreq: integer;
    {04}PrevRITFreq: integer;
    {01}Band: BandType;
    {01}Mode: ModeType;
    {01}VFOStatus: ActiveVFOStatusType;
    {01}PrevVFOStatus: ActiveVFOStatusType;
    {01}TXOn: boolean;
  end;

  RadioObject = object
    tDupeSheetWnd: HWND;
    tDisableCIVTransceive: boolean;
    tPTTStatus: PTTStatusType;
    tTwoRadioMode: TRMode;
    RadioOnTheMove: boolean;
    LastDisplayedFreq: integer;
    SpeedMemory: integer;
    BandMemory: BandType;
    ModeMemory: ModeType;

    FreqWindowHandle: HWND;
    RadioName: Str20;
//    lpOverlapped: TOverlapped;
//    pOver: POverlapped;

    CommandsBuffer: array[0..7] of array[0..19] of Char;
    CommandsBufferPointer: Cardinal;
    CommandsTempBuffer: array[0..19] of Char;

//    ICOM_COMMAND_B1: Str80;
//    ICOM_COMMAND_SET_MODE: string[8];
//    ICOM_COMMAND_SET_FREQ: string[11];
//    ICOM_COMMAND_B2: Str80;
//    ICOM_COMMAND_CUSTOM: Str80;

//    ICOM_COMMAND_PTT: Char;
//    ICOM_SET_PTT: array[0..7] of Char;
//    ICOM_SET_SPLIT: array[0..7] of Char;

    FT857_COMMAND_SET_MODE: string[5];
    FT857_COMMAND_SET_FREQ: string[5];

    tRadioInterfaceThreadID: Cardinal;
    tRadioInterfaceThreadHandle: HWND;
    tPollCount: integer;
    tStatusEqualityCounter: Cardinal;
    tRadioInterfaceWndHandle: HWND;
    RITWndHandle: HWND;
    XITWndHandle: HWND;
    SplitWndHandle: HWND;
    tRadioOnTheMove: boolean;
    tBuf: array[1..512] of Char;

    CurrentStatus: RadioStatusRecord; { Last reading taken }
    PreviousStatus: RadioStatusRecord; { Reading before Last }
    FilteredStatus: RadioStatusRecord; { Updated if Current = Previous }
    FilteredStatusChanged: boolean;
    BandOutputPort: PortType;
    tBandOutputPortBaseAddress: HWND;
    CommandPauseTimeStamp: TimeRecord;
    FrequencyAdder: LONGINT;
    FT1000MPCWReverse: boolean;
    WideCWFilter: boolean;
    IcomFilterByte: Byte;
    IDCharacter: Char;
//    PartialRadioResponse: string;
    PollingEnable: boolean;
    PollDelay: integer;
    PollStatus: PollingStatusType;
    PollTime: Cardinal {TimeRecord};
    RadioModel: InterfacedRadioType;
    RadioBaudRate: Cardinal;
    RadioNumberBits: integer;
    RadioStopBits: integer;
    RadioParity: ParityType;
    RadioTimeout: integer;
    ReceiverAddress: integer; { Used for Icom interfaces }
    WaitingForCommandPause: boolean;

    tCATPortType: PortType;
    tCATPortHandle: HWND;

    tKeyerPort: PortType;
    tKeyerPortHandle: HWND;

    tr4w_keyer_rts_state: tr4w_RTSDTRType; //keyer RTS
    tr4w_keyer_DTR_state: tr4w_RTSDTRType; //keyer DTR
    tr4w_cat_rts_state: tr4w_RTSDTRType; //CAT RTS
    tr4w_cat_dtr_state: tr4w_RTSDTRType; //CAT DTR

    tYaesuFreq5Bytes: array[0..4] of Byte;
    tYaesuMode5Bytes: array[0..4] of Byte;

    tYaesuSendFreq: boolean;
    tYaesuSendMode: boolean;

    tIcom6Bytes: array[0..5] of Byte;

    tIcomFilterWidth: integer;

    tKenwood14Bytes: array[0..14] of Char;

    tOrionFreq: array[0..15] of Char;
    tOrionMode: array[0..07] of Char;
//    OutPutBuffer: array[0..255] of Char;
//    OutPutBufferPoiner: integer;
    //    tEnablePolling: boolean;
    //    tDebugBuf: array[0..511] of Char;
    CommandPause: integer;
    //    ControlDelay: integer;
    //      FilterRadioMessageLength: boolean;
    //    TrackingEnable: boolean;
    //    UpdateSeconds: integer;
    //    RadioSerialPort: PortType;
    //    PollTimeout: LONGINT; { 100th of seconds for timeout }
    procedure AddCommandToBuffer;
    procedure CheckRadioStatus;
    procedure PutRadioIntoSplit;
    procedure PutRadioOutOfSplit;
    procedure SendIcomCommand(Command: Byte);
//    function SendFiveBytes: boolean;
    procedure SetRadioFreq(Freq: LONGINT; Mode: ModeType; VFO: Char);
//    procedure _SetRadioFreq(Freq: LONGINT; Mode: ModeType; VFO: Char);
    procedure SetUpRadioInterface;
//    procedure StartNextPoll;
    //    function TimeToGiveUp: boolean;
    procedure UpdateBandOutputInfo(Band: BandType; Mode: ModeType);
    procedure UpdateRadioStatus;
    function ConvertBCDStringToFreq(BCDString: Str20): LONGINT;
    procedure FreqToBCD(Freq: LONGINT; Swap: boolean; OpCode: Byte);
    procedure CheckAndInitializeSerialPorts_ForThisRadio;
    function WriteToCATPort(const Buffer; nNumberOfBytesToWrite: DWORD): LongBool;
    function WritePollRequest(const Buffer; nNumberOfBytesToWrite: DWORD): LongBool;
    function AddToOutputBuffer(Buffer: PChar; nNumberOfBytesToWrite: DWORD): LongBool;
    procedure WriteBufferToCATPort(const Buffer);
    //    property fddd;
  end;
  RadioPtr = ^RadioObject;

var
  IcomResponseTimeout                   : integer;
  cmdIcomResponseTimeout                : integer = -1;
  newIcomResponseTimeout                : integer = 60;

  newIcomResponseTimeoutAuto            : integer;
  icomCIVTransceiveEnable               : boolean;

  TwoRadioMode                          : boolean;

  Radio1                                : RadioObject {=
    (

    SpeedMemory: InitialCodeSpeed;
    BandMemory: Band160;
    ModeMemory: CW;
    RadioName: 'Rig 1';
    ICOM_COMMAND_PTT: #255;
    tRadioInterfaceWndHandle: 0;
    FT1000MPCWReverse: False;
    IDCharacter: CHR(0);
    //    PollTimeout: 500;
    PollingEnable: True;
    PollStatus: NoPollStatus;
    RadioModel: NoInterfacedRadio;

    RadioBaudRate: 4800;

    RadioNumberBits: 8;

    RadioStopBits: 2;

    RadioParity: tNoParity;

    ReceiverAddress: 4;
    WaitingForCommandPause: False;
    //    TrackingEnable: True;
    //    UpdateSeconds: 0;

    tCATPortType: NoPort;
    tCATPortHandle: INVALID_HANDLE_VALUE;

    tKeyerPortHandle: INVALID_HANDLE_VALUE;
    tr4w_keyer_rts_state: RtsDtr_PTT;
    tr4w_keyer_DTR_state: RtsDtr_CW;
    tr4w_cat_rts_state: RtsDtr_OFF; //CAT RTS
    tr4w_cat_dtr_state: RtsDtr_OFF; //CAT DTR
    );
};
  Radio2                                : RadioObject {=
    (
    SpeedMemory: InitialCodeSpeed;
    BandMemory: Band160;
    ModeMemory: CW;
    RadioName: 'Rig 2';
    ICOM_COMMAND_PTT: #255;
    tRadioInterfaceWndHandle: 0;
    FT1000MPCWReverse: False;
    IDCharacter: CHR(0);
    //    PollTimeout: 500;
    PollingEnable: True;
    PollStatus: NoPollStatus;
    RadioModel: NoInterfacedRadio;
    RadioBaudRate: 4800;
    RadioNumberBits: 8;
    RadioStopBits: 2;
    RadioParity: tNoParity;
    ReceiverAddress: 4;
    WaitingForCommandPause: False;
    //    TrackingEnable: True;
    //    UpdateSeconds: 0;
    tCATPortType: NoPort;
    tCATPortHandle: INVALID_HANDLE_VALUE;

    tKeyerPortHandle: INVALID_HANDLE_VALUE;
    tr4w_keyer_rts_state: RtsDtr_PTT;
    tr4w_keyer_DTR_state: RtsDtr_CW;
    tr4w_cat_rts_state: RtsDtr_OFF; //CAT RTS
    tr4w_cat_dtr_state: RtsDtr_OFF; //CAT DTR
    );
};
//  RITCommandTimeStamp              : Cardinal {TimeRecord};
  ActiveRadioPtr                        : RadioPtr = @Radio1;
  InActiveRadioPtr                      : RadioPtr = @Radio2;

const
  RTS_DTR_Values_Array                  : array[1..4] of PChar = ('OFF', 'ON', 'CW', 'PTT');

type
  RigType = (rtUnknown, rtICOM, rtKenwood, rtYaesu1, rtYaesu2, rtJST, rtOrion);

  BaudRateType = (BR1200, BR2400, BR4800, BR9600, BR19200, BR38400, BR57600, BR115200);
{
const
  Baud_Rate_Array                       : array[BaudRateType] of integer =
    (
    1200, 2400, 4800, 9600, 19200, 38400, 57600 , 115200
    );
}
type
  TRadioParameters = record
//    Name: PChar;
    br: BaudRateType; //Baud Rate
    p: Byte; //Polling
    c: Byte; //ShiftInCQMode
    s: Byte; //ShiftInSPMode
    t: Byte; //PTTViaCommand
    RA: Byte; //ReceiverAddress
    SW: Byte; //Swap
    SFOC: Byte; //SetFreqOpCode
    SMOC: Byte; //SetModeOpCode
    SPOC: Byte; //SetPTTOpCode
    RX: Byte; //RXOpCode
    TX: Byte; //TXOpCode
    mb: Byte; //PositionOfModeByte

    CW: Byte; //CWLOpCode
//    CWU: Byte; //CWLOpCode
    LSB: Byte; //LSBOpCode
    USB: Byte; //USBOpCode
    FM: Byte; //FMOpCode
    AM: Byte; //AMOpCode
    DIGL: Byte; //DigLOpCode
    DIGU: Byte; //DigUOpCode

    rt: RigType;
  end;

//const
//  YaesuReplyRigs                        : array[0..1] of InterfacedRadioType = (FT857, FT897);

const
  RadioParametersArray                  : array[InterfacedRadioType] of TRadioParameters =
    (
{(*}
    ({Name: 'NONE';       } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00),
    ({Name: 'K2';         } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'K3';         } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS850';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),

    ({Name: 'FT100';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $02; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $05; DIGU: $05; rt: rtYaesu1),
    ({Name: 'FT450';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FT736R';     } BR:BR4800;  P: 0; C: 0; S: 0; T:0; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu1),
    ({Name: 'FT747GX';    } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $00; DIGU: $00; rt: rtYaesu1),
    ({Name: 'FT767';      } BR:BR4800;  P: 1; C: 1; S: 1; T:0; RA: $00; SW: 1; SFOC: $08; SMOC: $0A; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $12; LSB: $10; USB: $11; FM: $14; AM: $13; DIGL: $15; DIGU: $15; rt: rtYaesu1),
    ({Name: 'FT817';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $88; TX: $08; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $0C; DIGU: $0A; rt: rtYaesu1),
    ({Name: 'FT840';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $FF; DIGU: $FF; rt: rtYaesu1),
    ({Name: 'FT847';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $FF; DIGU: $FF; rt: rtYaesu1),
    ({Name: 'FT857';      } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $FF; DIGU: $0A; rt: rtYaesu1),
    ({Name: 'FT890';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $FF; DIGU: $FF; rt: rtYaesu1),
    ({Name: 'FT897';      } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 0; SFOC: $01; SMOC: $07; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $02; LSB: $00; USB: $01; FM: $08; AM: $04; DIGL: $FF; DIGU: $0A; rt: rtYaesu1),
    ({Name: 'FT900';      } BR:BR4800;  P: 1; C: 0; S: 0; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $FF; DIGU: $FF; rt: rtYaesu1),
    ({Name: 'FT920';      } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $02; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $0A; rt: rtYaesu1),
    ({Name: 'FT950';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FT990';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $05; DIGL: $08; DIGU: $09; rt: rtYaesu1),
    ({Name: 'FT1000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $09; rt: rtYaesu1),
    ({Name: 'FT1000MP';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $02; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $09; rt: rtYaesu1),

    ({Name: 'FT2000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FTDX3000';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FTDX9000';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),

    ({Name: 'IC78';       } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $62; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC706';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $48; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC706II';    } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $4E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC706IIG';   } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $58; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC707';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $3E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC718';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $5E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC725';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $28; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC726';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $30; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC728';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $38; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC729';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $3A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC735';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $04; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC736';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $40; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC737';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $3C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC738';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $44; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC746';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $56; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC746PRO';   } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $66; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC756';      } BR:BR1200;  P: 1; C: 0; S: 0; T:0; RA: $50; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC756PRO';   } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $5C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC756PROII'; } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $64; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC756PROIII';} BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $6E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC761';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $1E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC765';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $2C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC775';      } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $46; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC781';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $26; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),

    ({Name: 'IC910';      } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $60; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC970D';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $2E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),

    ({Name: 'IC7000';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $70; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7200';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $76; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),

    ({Name: 'IC7410';     } BR:BR19200;  P: 1; C: 0; S: 0; T:0; RA: $80; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),

    ({Name: 'IC7600';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $7A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7700';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $74; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7800';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $6A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),

    ({Name: 'OMNI6';      } BR:BR9600;  P: 1; C: 1; S: 1; T:0; RA: $04; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),

                                              //    ({Name: 'JST245';     } BR:BR4800;  P: 0; C: 0; S: 0; T:0; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt:rtJST),
    ({Name: 'ORION';      } BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt:rtOrion)
    );
{*)}
    const
    InterfacedRadioTypeSA: array[InterfacedRadioType] of PChar = (

    'NONE',
    'K2',
    'K3',
    'TS850',
    'FT100',
    'FT450',
    'FT736R',
    'FT747GX',
    'FT767',
    'FT817',
    'FT840',
    'FT847',
    'FT857',
    'FT890',
    'FT897',
    'FT900',
    'FT920',
    'FT950',
    'FT990',
    'FT1000',
    'FT1000MP',

    'FT2000',
    'FTDX3000',
    'FTDX9000',

    'IC78',
    'IC706',
    'IC706II',
    'IC706IIG',
    'IC707',
    'IC718',
    'IC725',
    'IC726',
    'IC728',
    'IC729',
    'IC735',
    'IC736',
    'IC737',
    'IC738',
    'IC746',
    'IC746PRO',
    'IC756',
    'IC756PRO',
    'IC756PROII',
    'IC756PROIII',
    'IC761',
    'IC765',
    'IC775',
    'IC781',

    'IC910H',
    'IC970D',

    'IC7000',
    'IC7200',
    'IC7410',
    'IC7600',
    'IC7700',
    'IC7800',

    'OMNI6',
    'ORION'

    );

 {
    const
    Radio_Type_Array: array[InterfacedRadioType] of PChar = (
    'NONE',
    'K2',
    'TS850',
    'FT100',
    'FT450',
    'FT736R',
    'FT767',
    'FT817',
    'FT840',
    'FT847',
    'FT857',
    'FT890',
    'FT897',
    'FT900',
    'FT920',
    'FT950',
    'FT990',
    'FT1000',
    'FT1000MP',
    'FT2000',
    'FTDX9000',
    'IC706',
    'IC706II',
    'IC706IIG',
    'IC707',
    'IC718',
    'IC725',
    'IC726',
    'IC728',
    'IC729',
    'IC735',
    'IC736',
    'IC737',
    'IC738',
    'IC746',
    'IC746PRO',
    'IC756',
    'IC756PRO',
    'IC756PROII',
    'IC756PROIII',
    'IC761',
    'IC765',
    'IC775',
    'IC781',
    'IC7000',
    'IC7800',
    'OMNI6',
    'JST245',
    'ORION');
}

procedure InitRadios;
function OpenCATDebugFile(port: PortType): boolean;
//procedure CloseCATDebugFile(port: PortType);

function tPTTVIACAT(PTTOn: boolean): boolean;
//function GetRadioFromString(RadioName: ShortString): InterfacedRadioType;
procedure TestRadioInterface;

{ Old style function calls supported here }

{ Works on the radio specified  (Radio1 or Radio2) }

function GetRadioParameters(Radio: RadioType;
  RadioInfoString: string;
  var Freq: LONGINT;
  var Band: BandType;
  var Mode: ModeType;
  Polling: boolean;
  Debug: boolean): boolean;
//wli
function GenerateStatusString(var StatusRecord: RadioStatusRecord): Str80;
procedure PutRadioIntoSplit(Radio: RadioType);
procedure PutRadioOutOfSplit(Radio: RadioType);
procedure SetRadioFreq(Radio: RadioType; Freq: LONGINT; Mode: ModeType; VFO: Char);

{ These work on the ActiveRadio }

//procedure CheckRITKeys;

procedure RITClear;
procedure RITBumpDown;
procedure RITBumpUp;

procedure VFOBumpDown;
procedure VFOBumpUp;
const

//FT767PollString = NullKey + NullKey + NullKey + CHR($01) + NullKey;
FT767PollString: Yaesu5Bytes = (0, 0, 0, 1, 0);
FT767CATEnablePollingString = NullKey + NullKey + NullKey + NullKey + NullKey;
FT767ACKString = NullKey + NullKey + NullKey + NullKey + CHR($0B);

FT847PollString = NullKey + NullKey + NullKey + NullKey + CHR($03);
FT747GXPollString = NullKey + NullKey + NullKey + NullKey + CHR($10);

FT1000MPPoll1String = CHR($00) + CHR($00) + CHR($00) + CHR($02) + CHR($10); //16 answer
FT1000MPPoll2String = CHR($00) + CHR($00) + CHR($00) + CHR($03) + CHR($10); //32b answer
FT1000MPPoll3String = CHR($00) + CHR($00) + CHR($00) + CHR($01) + CHR($FA);

FT100StatusUpdate = CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($10);
FT100ReadStatusFlags = CHR($00) + CHR($00) + CHR($00) + CHR($01) + CHR($FA);

TurnOn847CATString = NullKey + NullKey + NullKey + NullKey + CHR($00);
TurnOff847CATString = NullKey + NullKey + NullKey + NullKey + CHR($80);

implementation

uses
  LogK1EA,
  LogWind,
  uRadioPolling,
  MainUnit;

procedure RITClear;

var
  IntRadioType                          : InterfacedRadioType;
  SerialPort                            : PortType;

begin
  if ActiveRadio = RadioOne then
  begin
    IntRadioType := Radio1.RadioModel;
    SerialPort := Radio1.tCATPortType;
  end
  else
  begin
    IntRadioType := Radio2.RadioModel;
    SerialPort := Radio2.tCATPortType;
  end;

  case IntRadioType of
    TS850, K2, K3, FT450, FT950, FT2000, FTDX9000:
      ActiveRadioPtr.WriteBufferToCATPort('RC;');

    FT747GX, FT890, FT920, FT990, FT1000, FT1000MP:
      begin
        ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR($FF) + CHR($09), 5);
      end;

    IC706..IC7800, OMNI6: {KK1L: 6.73 Added OMNI6}
      Exit;

    Orion:
      begin
        ActiveRadioPtr.WriteBufferToCATPort('*RMR0' + CarriageReturn);
        Exit;
      end;

  else Exit;
  end;

  { Anyone know why this stuff is here?  I am chicken to remove it }
{
 CPUKeyer.AddSerialPortString(SerialPort, CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(0) +
   CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(0) +
   CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(0) +
   CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(0) +
   CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(0) +
   CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(0) +
   CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(0));
}
end;

procedure RITBumpUp;

var
  IntRadioType                          : InterfacedRadioType;
  SerialPort                            : PortType;

begin
  if ActiveRadio = RadioOne then
  begin
    IntRadioType := Radio1.RadioModel;
    SerialPort := Radio1.tCATPortType;
  end
  else
  begin
    IntRadioType := Radio2.RadioModel;
    SerialPort := Radio2.tCATPortType;
  end;

  case IntRadioType of
    TS850, K2, K3 {, FTDX9000}:
      ActiveRadioPtr.WriteBufferToCATPort('RU;');

    FT890, FT920, FT990, FT1000, FT1000MP:
      Exit;

    IC706..IC7800, OMNI6: {KK1L: 6.73 Added OMNI6}
      Exit;

    Orion:
      begin
        ActiveRadioPtr.WriteBufferToCATPort('*RMR200' + CarriageReturn);
        Exit;
      end;

  else Exit;
  end;
end;

procedure RITBumpDown;

var
  IntRadioType                          : InterfacedRadioType;
  SerialPort                            : PortType;

begin
  if ActiveRadio = RadioOne then
  begin
    IntRadioType := Radio1.RadioModel;
    SerialPort := Radio1.tCATPortType;
  end
  else
  begin
    IntRadioType := Radio2.RadioModel;
    SerialPort := Radio2.tCATPortType;
  end;

  case IntRadioType of
    TS850, K2, K3 {, FTDX9000}:
      ActiveRadioPtr.WriteBufferToCATPort('RD;');

    FT890, FT920, FT990, FT1000, FT1000MP:
      Exit;

    IC706..IC7800, OMNI6: {KK1L: 6.73 Added OMNI6}
      Exit;

    Orion:
      begin
        ActiveRadioPtr.WriteBufferToCATPort('*RMR-200' + CarriageReturn);
        Exit;
      end;

  else Exit;
  end;
end;

procedure VFOBumpUp;

var
  IntRadioType                          : InterfacedRadioType;
  SerialPort                            : PortType;

begin
  if ActiveRadio = RadioOne then
  begin
    IntRadioType := Radio1.RadioModel;
    SerialPort := Radio1.tCATPortType;
  end
  else
  begin
    IntRadioType := Radio2.RadioModel;
    SerialPort := Radio2.tCATPortType;
  end;

  case IntRadioType of

    TS850:
      ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('UP;', 3);

    FT450, FT950, FT2000, FTDX9000, K2, K3:
      ActiveRadioPtr.WriteBufferToCATPort('UP;');

    FT890, {FT920,} FT990, FT1000, FT1000MP:
      ActiveRadioPtr.WriteBufferToCATPort(
        CHR($8E) +
        CHR(0) +
        CHR(0) +
        CHR(0) +
        CHR(0));

    FT767:
      ActiveRadioPtr.WriteBufferToCATPort(
        CHR(0) +
        CHR(0) +
        CHR(0) +
        CHR(0) +
        CHR($02));

    IC706..IC7800, OMNI6: {KK1L: 6.73 Added OMNI6}
      begin
        if ActiveRadioPtr.CurrentStatus.Freq = 0 then Exit;
        ActiveRadioPtr.SetRadioFreq(ActiveRadioPtr.CurrentStatus.Freq + 20, ActiveRadioPtr.CurrentStatus.Mode, 'A');
        Exit;
      end;

    Orion:
      begin
        ActiveRadioPtr.WriteBufferToCATPort('*AS+1' + CarriageReturn);
        Exit;
      end;

  else Exit;
  end;
end;

procedure VFOBumpDown;

var
  IntRadioType                          : InterfacedRadioType;
  SerialPort                            : PortType;

begin
  if ActiveRadio = RadioOne then
  begin
    IntRadioType := Radio1.RadioModel;
    SerialPort := Radio1.tCATPortType;
  end
  else
  begin
    IntRadioType := Radio2.RadioModel;
    SerialPort := Radio2.tCATPortType;
  end;

  case IntRadioType of

    TS850:
      ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('DN;', 3);

    FT450, FT950, FT2000, FTDX9000, K2, K3:
      ActiveRadioPtr.WriteBufferToCATPort('DN;');

    FT890, {FT920,} FT990, FT1000, FT1000MP:
      ActiveRadioPtr.WriteBufferToCATPort(
        CHR($8E) +
        CHR(1) +
        CHR(0) +
        CHR(0) +
        CHR(0));

    FT767:
      ActiveRadioPtr.WriteBufferToCATPort(
        CHR(0) +
        CHR(0) +
        CHR(0) +
        CHR(0) +
        CHR($03));

    IC706..IC7800, OMNI6: {KK1L: 6.73 Added OMNI6}
      begin
        if ActiveRadioPtr.CurrentStatus.Freq = 0 then Exit;
        ActiveRadioPtr.SetRadioFreq(ActiveRadioPtr.CurrentStatus.Freq - 20, ActiveRadioPtr.CurrentStatus.Mode, 'A');
        Exit;
      end;

    Orion:
      begin
        ActiveRadioPtr.WriteBufferToCATPort('*AS-1' + CarriageReturn);
        Exit;
      end;

  else Exit;
  end;
end;
{
procedure CheckRITKeys;

var
  TestByte                         : Byte;

begin
  if not ShiftKeyEnable then Exit;

  //WLI    TestByte := Mem [$40:$17];

  TestByte := TestByte and $0F; // Mask off the lock keys

  case TestByte of
    1:
      if MicroTimeElapsed(RITCommandTimeStamp) > 0 then
      begin
        RITBumpUp;
        MarkTime(RITCommandTimeStamp);
      end;

    2:
      if MicroTimeElapsed(RITCommandTimeStamp) > 0 then
      begin
        RITBumpDown;
        MarkTime(RITCommandTimeStamp);
      end;

    3:
      if MicroTimeElapsed(RITCommandTimeStamp) > 0 then
      begin
        RITClear;
        MarkTime(RITCommandTimeStamp);
      end;

  end;

end;
}

function GetRadioParameters(Radio: RadioType;
  RadioInfoString: string;
  var Freq: LONGINT;
  var Band: BandType;
  var Mode: ModeType;
  Polling: boolean;
  Debug: boolean): boolean;

begin
  //  GetRadioParameters := true;

  case Radio of
    RadioOne:
      with Radio1 do
      begin
        Freq := FilteredStatus.Freq;
        Band := FilteredStatus.Band;
        Mode := FilteredStatus.Mode;
        GetRadioParameters := {true} FilteredStatus.Freq <> 0; //wli
      end;

    RadioTwo:
      with Radio2 do
      begin
        Freq := FilteredStatus.Freq;
        Band := FilteredStatus.Band;
        Mode := FilteredStatus.Mode;
        GetRadioParameters := {true} FilteredStatus.Freq <> 0; //wli
      end;
  end;
end;

procedure PutRadioIntoSplit(Radio: RadioType);

begin
  case Radio of
    RadioOne: Radio1.PutRadioIntoSplit;
    RadioTwo: Radio2.PutRadioIntoSplit;
  end;
end;

procedure PutRadioOutOfSplit(Radio: RadioType);

begin
  case Radio of
    RadioOne: Radio1.PutRadioOutOfSplit;
    RadioTwo: Radio2.PutRadioOutOfSplit;
  end;
end;

procedure SetRadioFreq(Radio: RadioType; Freq: LONGINT; Mode: ModeType; VFO: Char);

{ Backwards compatable routine to the pre TR680 days }

begin
  case Radio of
    RadioOne: Radio1.SetRadioFreq(Freq, Mode, VFO);
    RadioTwo: Radio2.SetRadioFreq(Freq, Mode, VFO);
  end;
end;

procedure RadioObject.WriteBufferToCATPort(const Buffer);
begin
  WriteToCATPort(Buffer, lstrlen(@Buffer));
end;

function RadioObject.WritePollRequest(const Buffer; nNumberOfBytesToWrite: DWORD): LongBool;
begin
 { if NoPollDuringPTT then
  if tPTTStatus = PTT_ON then
  Sleep(500);   }
  Result := WriteToCATPort(Buffer, nNumberOfBytesToWrite);
  if not Result then Sleep(200);
end;

function RadioObject.AddToOutputBuffer(Buffer: PChar; nNumberOfBytesToWrite: DWORD): LongBool;
begin

//  sleep(100);
//  Windows.lstrcat(CommandsBuffer[0], Buffer);
{$IF MASKEVENT}
  Windows.CopyMemory(@CommandsBuffer[0][CommandsBufferPointer], Buffer, nNumberOfBytesToWrite);
  inc(CommandsBufferPointer, nNumberOfBytesToWrite);
{$ELSE}
  WriteToCATPort(Buffer^, nNumberOfBytesToWrite);
{$IFEND}
end;

function RadioObject.WriteToCATPort(const Buffer; nNumberOfBytesToWrite: DWORD): LongBool;
var
  lpNumberOfBytesWritten                : DWORD;
begin
{
  if not DVKEnable then
    if RadioModel = TS850 then
      if nNumberOfBytesToWrite = 4 then
        if PChar(Buffer)[0] = 'P' then
          if PChar(Buffer)[1] = 'B' then
            if PChar(Buffer)[2] in ['1'..'3'] then
              if PChar(Buffer)[3] = ';' then
              begin
//                Result := 0;
                Exit;
              end;
}
  Windows.WriteFile(tCATPortHandle, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, nil);
{
  if not Windows.WriteFile(tCATPortHandle, Buffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, pOver) then
    if pOver <> nil then
      if GetLastError = ERROR_IO_PENDING then
      begin
        Result := True;
        Exit;
      end;
}
  Result := nNumberOfBytesToWrite = lpNumberOfBytesWritten;
end;

procedure RadioObject.CheckAndInitializeSerialPorts_ForThisRadio;
begin
  if RadioModel = NoInterfacedRadio then Exit;
  if RadioModel in [IC706..IC7800, FT100, Orion] then
    RadioStopBits := 1
  else
    RadioStopBits := 2;
  SetUpRadioInterface;

  if tCATPortHandle <> INVALID_HANDLE_VALUE then
    if PollingEnable then
    begin
      tPollCount := -1;
      tRadioInterfaceThreadHandle := CreateThread(nil, 0, @BeginPolling, @Self, 0, tRadioInterfaceThreadID);
    end;

end;

procedure RadioObject.FreqToBCD(Freq: LONGINT; Swap: boolean; OpCode: Byte);
var
  TempByte, sb1, sb2                    : Byte;
  c                                     : Cardinal;
  TempFreq                              : LONGINT;
begin
  ZeroMemory(@tYaesuFreq5Bytes, SizeOf(tYaesuFreq5Bytes));
  tYaesuFreq5Bytes[4] := OpCode;
  TempFreq := Freq div 10;
  for c := 3 downto 0 do
  begin
    TempByte := TempFreq mod 100;
    TempFreq := TempFreq div 100;
    sb1 := TempByte div 10;
    sb2 := TempByte mod 10;
    if c = 0 then if Freq > 1000000000 then sb1 := sb1 + 10;
    TempByte := sb1 * 16 + sb2;
    tYaesuFreq5Bytes[c] := TempByte;
  end;

  if Swap then
  begin
    c := PDWORD(@tYaesuFreq5Bytes)^;
    asm
    mov eax,c
    bswap eax
    mov c,eax
    end;
    PDWORD(@tYaesuFreq5Bytes)^ := c;
  end;
end;

function RadioObject.ConvertBCDStringToFreq(BCDString: Str20): LONGINT;

var
  F1                                    : LONGINT;

begin
  if length(BCDString) = 5 then
  begin
    F1 := (Ord(BCDString[5]) and $F0) shr 4; { 1000s of mhz }
    F1 := F1 * 10;
    F1 := F1 + (Ord(BCDString[5]) and $0F); { 100s of mhz}
    F1 := F1 * 10;
  end
  else
    F1 := 0;

  F1 := F1 + ((Ord(BCDString[4]) and $F0) shr 4); { 10s of mhz }
  F1 := F1 * 10;
  F1 := F1 + (Ord(BCDString[4]) and $0F); { 1s of mhz}
  F1 := F1 * 10;

  F1 := F1 + ((Ord(BCDString[3]) and $F0) shr 4);
  F1 := F1 * 10;
  F1 := F1 + (Ord(BCDString[3]) and $0F);
  F1 := F1 * 10;

  F1 := F1 + ((Ord(BCDString[2]) and $F0) shr 4);
  F1 := F1 * 10;
  F1 := F1 + (Ord(BCDString[2]) and $0F);
  F1 := F1 * 10;

  F1 := F1 + ((Ord(BCDString[1]) and $F0) shr 4);
  F1 := F1 * 10;

  F1 := F1 + (Ord(BCDString[1]) and $0F);

  ConvertBCDStringToFreq := F1;
end;

function FrequencyFromFourBytes(FreqStr: string): LONGINT;

var
  F1, F2, F3                            : LONGINT;

begin
  F1 := Ord(FreqStr[1]);
  F1 := F1 * 256 * 256 * 256;
  F2 := Ord(FreqStr[2]);
  F2 := F2 * 256 * 256;
  F3 := Ord(FreqStr[3]);
  F3 := F3 * 256;
  FrequencyFromFourBytes := F1 + F2 + F3 + Ord(FreqStr[4]);
end;

procedure RadioObject.SendIcomCommand(Command: Byte);
begin
  tIcom6Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
  tIcom6Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
  tIcom6Bytes[2] := ReceiverAddress;
  tIcom6Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
  tIcom6Bytes[4] := Command;
  tIcom6Bytes[5] := Ord(ICOM_END_OF_MESSAGE_CODE);
  WriteToCATPort(tIcom6Bytes, 6);
end;

procedure RadioObject.PutRadioIntoSplit;

begin
  case RadioModel of
    TS850, K2, K3:
      begin
        //            CPUKeyer.AddSerialPortString(tr4w_CATPort, 'FR0;FA;FT1;');
//        ActiveRadioPtr.WriteBufferToCATPort('FR0;FT1;'); //vfo a = rx, vfo b = tx
        AddToOutputBuffer('FR0;FT1;', 8);

        {KK1L: 6.71 For some reason needed this to get the FT1; }
        {           command to take. Started when I added setting }
        {           mode of B VFO to set freq.                    }

//        ActiveRadioPtr.WriteBufferToCATPort('FA;');
//        ActiveRadioPtr.WriteBufferToCATPort('FT1;');//vfo b = tx
      end;

    IC706..IC7800, OMNI6: { KK1L: 6.73 Added OMNI6 }
      begin

        CommandsTempBuffer[0] := CHR(8);
        CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[3] := CHR(ReceiverAddress);
        CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
        CommandsTempBuffer[5] := ICOM_SET_SPLIT_MODE;
        CommandsTempBuffer[6] := CHR(1);
        CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
        AddCommandToBuffer;
//{?}        ActiveRadioPtr.WriteBufferToCATPort(CHR($FE) + CHR($FE) + CHR(ReceiverAddress) + CHR($E0) + CHR($0F) + CHR($01) + CHR($FD));
        {
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($FE));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($FE));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR(ReceiverAddress));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($E0));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($0F)); // $0F cmd
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($01)); // $01 put in split
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($FD));
        }

      end;

    FT747GX, FT100, FT890, FT900, FT920, FT990, FT1000, FT1000MP:
      ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR(1) + CHR(1), 5);

    Orion:
      ActiveRadioPtr.WriteBufferToCATPort('*KVABB' + CarriageReturn);

  end;
end;

procedure RadioObject.PutRadioOutOfSplit;

begin
  case RadioModel of
    TS850, K2, K3:
      begin
        //ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('FR0;FT0;', 8);
        AddToOutputBuffer('FR0;FT0;', 8);

//        ActiveRadioPtr.WriteBufferToCATPort('FT0;');
      end;

    IC706..IC7800, OMNI6: {KK1L: 6.73 Added OMNI6}
      begin

        CommandsTempBuffer[0] := CHR(8);
        CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[3] := CHR(ReceiverAddress);
        CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
        CommandsTempBuffer[5] := ICOM_SET_SPLIT_MODE;
        CommandsTempBuffer[6] := CHR(0);
        CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
        AddCommandToBuffer;
//{?}        CPUKeyer.AddSerialPortString(tCATPortType, CHR($FE) + CHR($FE) + CHR(ReceiverAddress) + CHR($E0) + CHR($0F) + CHR($00) + CHR($FD));
        {
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($FE));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($FE));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR(ReceiverAddress));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($E0));
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($0F));  $0F cmd
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($00)); //KK1L: 6.64 This is the cancel split code
                CPUKeyer.AddSerialPortCharacter(tr4w_CATPort, CHR($FD));
        }
      end;

    FT747GX, FT100, FT890, FT900, FT920, FT990, FT1000, FT1000MP: { QSL }
      ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(1), 5);

    Orion:
      ActiveRadioPtr.WriteBufferToCATPort('*KVABA' + CarriageReturn);

  end;
end;
{
function RadioObject.TimeToGiveUp: boolean;

// Returns TRUE if it is time to give up on getting a response from the
//  current pending poll

begin
  TimeToGiveUp := ElaspedSec100(PollTime) * 10 > PollTimeout;
end;
}

procedure RadioObject.UpdateRadioStatus;

{ Updates the filtered radio status }

begin
  if CurrentStatus.Freq = PreviousStatus.Freq then
    FilteredStatus.Freq := CurrentStatus.Freq;

  if CurrentStatus.Mode = PreviousStatus.Mode then
    FilteredStatus.Mode := CurrentStatus.Mode;

  if CurrentStatus.Band = PreviousStatus.Band then
    FilteredStatus.Band := CurrentStatus.Band;

  if CurrentStatus.Split = PreviousStatus.Split then
    FilteredStatus.Split := CurrentStatus.Split;

  if CurrentStatus.VFO[VFOA].Frequency = PreviousStatus.VFO[VFOA].Frequency then
    FilteredStatus.VFO[VFOA].Frequency := CurrentStatus.VFO[VFOA].Frequency;

  if CurrentStatus.VFO[VFOA].Band = PreviousStatus.VFO[VFOA].Band then
    FilteredStatus.VFO[VFOA].Band := CurrentStatus.VFO[VFOA].Band;

  if CurrentStatus.VFO[VFOA].Mode = PreviousStatus.VFO[VFOA].Mode then
    FilteredStatus.VFO[VFOA].Mode := CurrentStatus.VFO[VFOA].Mode;

  //   if CurrentStatus.VFOA.TXRX = PreviousStatus.VFOA.TXRX then
  //      FilteredStatus.VFOA.TXRX := CurrentStatus.VFOA.TXRX;

  if CurrentStatus.VFO[VFOB].Frequency = PreviousStatus.VFO[VFOB].Frequency then
    FilteredStatus.VFO[VFOB].Frequency := CurrentStatus.VFO[VFOB].Frequency;

  if CurrentStatus.VFO[VFOB].Band = PreviousStatus.VFO[VFOB].Band then
    FilteredStatus.VFO[VFOB].Band := CurrentStatus.VFO[VFOB].Band;

  if CurrentStatus.VFO[VFOB].Mode = PreviousStatus.VFO[VFOB].Mode then
    FilteredStatus.VFO[VFOB].Mode := CurrentStatus.VFO[VFOB].Mode;

  //   if CurrentStatus.VFOB.TXRX = PreviousStatus.VFOB.TXRX then
  //      FilteredStatus.VFOB.TXRX := CurrentStatus.VFOB.TXRX;

  PreviousStatus := CurrentStatus;
end;

procedure RadioObject.AddCommandToBuffer;
begin
  if not PollingEnable then
  begin
    WriteToCATPort(PChar(@CommandsTempBuffer[1])^, Ord(CommandsTempBuffer[0]) - 1);
    Sleep(250);
    Exit;
  end;

  if CommandsBufferPointer = 8 then CommandsBufferPointer := 0;
  Windows.CopyMemory(@CommandsBuffer[CommandsBufferPointer], @CommandsTempBuffer, Ord(CommandsTempBuffer[0]));
  inc(CommandsBufferPointer);
end;

procedure RadioObject.CheckRadioStatus;
var
  answer, FreqString, TestString        : string;
  TempMode                              : ModeType;

  { This is the procedure to call to make sure the radio status is as current
    as possible. It will look to see what the most recent request for data
    was - and see if the data has been received yet, or if it is time to
    give up.  In either case, it will initiate the appropriate next request
    based upon the radio type. }

  //VAR SerialPort: PortType;

begin
  { One thing we like to do is check the serial ports to see if any
    data is there waiting.  This helps keep up with those 56K baud
    radios like the Orion - if the CheckRadioStatus routine is called
    often enough. }
 {
   WriteToSerialPort('IF;', radio1.Port_Handle);

   answer := ReadFromSerialPort(radio1.Port_Handle, 38);
  //answer:='FA00000070000;';
   t.Label4 . Caption := answer;
   if Copy(answer, Length(answer), 1) = ';' then
     if Length(answer) = 14 then
       if Copy(answer, 1, 2) = 'FA' then
       begin
         if answer[14] = ';' then
         begin
           Delete(answer, 14, 1);
           Delete(answer, 1, 2);
           if StringIsAllNumbers(answer) then CurrentStatus.VFOA.Frequency := strtoint(answer);
         end;
       end;
 }
  {

  WriteToSerialPort ('FB;',radio1.Port_Handle);

  answer:=ReadFromSerialPort(radio1.Port_Handle);
  Frm.Label5 . Caption:=answer;
  IF Copy (answer, Length (answer), 1) = ';' THEN
  IF Length (answer) = 14 THEN
  IF Copy (answer, 1, 2) = 'FB' THEN
  BEGIN
  IF answer [14] = ';' THEN
  BEGIN
  Delete (answer, 14, 1);
  Delete (answer,  1, 2);
  IF StringIsAllNumbers (answer) THEN CurrentStatus.VFOB.Frequency:=strtoint(answer);
  END;
  end;

  WriteToSerialPort ('IF;',radio1.Port_Handle);

  answer:=ReadFromSerialPort(radio1.Port_Handle);
  Frm.Label6 . Caption:=answer;
  IF Copy (answer, Length (answer), 1) = ';' THEN
  IF Length (answer) = 38 THEN
  IF Copy (answer, 1, 2) = 'IF' THEN
  BEGIN
  FreqString := Copy (answer, 3, 11);
  IF StringIsAllNumbers (FreqString) THEN
  CurrentStatus.Freq:=strtoint(FreqString);
  CalculateBandMode (CurrentStatus.Freq, CurrentStatus.Band, TempMode);
  TestString := Copy (answer, 30, 1);
  IF TestString <> '' THEN
  CASE TestString [1] OF
  '1', '2', '4', '5': CurrentStatus.Mode := Phone;
  '6', '9':           CurrentStatus.Mode := Digital;
  '3', '7', '8':      CurrentStatus.Mode := CW;
  END;
  IF Copy (answer, 33, 1) = '0' THEN CurrentStatus.Split := NoSplit
  ELSE
  CurrentStatus.Split := SplitOn;
  end;

  UpdateRadioStatus;
  }

  //UpdateRadioStatus;

end;

procedure RadioObject.SetUpRadioInterface;
var
  hand                                  : HWND;
  TempCardinal                          : Cardinal;
  dwFlagsAndAttributes                  : DWORD;
  EvtChar                               : Char;
begin
  { Setup the serial port }

  if tCATPortType in [Serial1..Serial20] then
  begin

    dwFlagsAndAttributes := FILE_ATTRIBUTE_NORMAL;
    EvtChar := #0;
{$IF MASKEVENT}

    if RadioModel in [Orion] then
    begin
      dwFlagsAndAttributes := FILE_FLAG_OVERLAPPED;
      EvtChar := #13;
    end;

    if RadioModel in [TS850, K2, K3] then
    begin
      dwFlagsAndAttributes := FILE_FLAG_OVERLAPPED;
      EvtChar := ';';
    end;
{$IFEND}

    hand := CPUKeyer.SerialPortConfigured_Handle[tCATPortType];
    if hand = INVALID_HANDLE_VALUE then
      hand := InitializeSerialPort(tCATPortType, RadioBaudRate, RadioNumberBits, RadioParity, RadioStopBits, dwFlagsAndAttributes, EvtChar);

{$IF MASKEVENT}

    if RadioModel in [TS850, K2, K3, Orion] then
    begin
      if SetCommMask(hand, EV_RXFLAG) then
      begin
        lpOverlapped.hEvent := CreateEvent(nil, False, False, nil);
        pOver := @lpOverlapped;
      end;
    end;
{$IFEND}

    if hand <> INVALID_HANDLE_VALUE then
    begin
      CPUKeyer.SerialPortConfigured_Handle[tCATPortType] := hand;
      tCATPortHandle := hand;

      if tr4w_cat_dtr_state = RtsDtr_ON then TREscapeCommFunction(hand, SETDTR);
      if tr4w_cat_dtr_state = RtsDtr_OFF then TREscapeCommFunction(hand, CLRDTR);
      if tr4w_cat_rts_state = RtsDtr_ON then TREscapeCommFunction(hand, SETRTS);
      if tr4w_cat_rts_state = RtsDtr_OFF then TREscapeCommFunction(hand, CLRRTS);

//      OpenCATDebugFile(tCATPortType);
    end;

  end;

  { Initialize the radio variables }

  PollStatus := NoPollStatus;

  with CurrentStatus do
  begin
    Band := NoBand;
    Mode := NoMode;
    Freq := 0;
    VFO[VFOA].Frequency := 0;
    VFO[VFOB].Frequency := 0;
  end;

  with PreviousStatus do
  begin
    Band := NoBand;
    Mode := NoMode;
    Freq := 0;
  end;

  with FilteredStatus do
  begin
    Band := NoBand;
    Mode := NoMode;
    Freq := 0;
  end;

  { Enable polling }

//  PollingEnable := True;
end;

procedure RadioObject.SetRadioFreq(Freq: LONGINT; Mode: ModeType; VFO: Char);

var
  FreqStr                               : Str20;
  CharPointer                           : integer;
  i                                     : integer;
  SendByte, TempByte                    : Byte;
  TempChar                              : Char;
  lpNumberOfBytesWritten                : Cardinal;
  VFOByte                               : Byte;
const
  FT847ModeString                       = CHR(0) + CHR(0) + CHR(0) + CHR(7);

begin
  case RadioParametersArray[RadioModel].rt of
    rtYaesu1:
      begin

        { Select VFO B on the radio }
        if RadioModel in [FT890, FT990] then
          if VFO = 'B' then
          begin
            ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
            tYaesuMode5Bytes[3] := $01;
            tYaesuMode5Bytes[4] := $05;
            WriteToCATPort(tYaesuMode5Bytes, 5);
          end;

        {SplitOff}
        if RadioModel in [FT100, FT920, FT1000, FT1000MP] then
        begin
          ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
          tYaesuMode5Bytes[4] := $01;
          WriteToCATPort(tYaesuMode5Bytes, 5);
        end;

        {Set Mode}
        ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
        tYaesuMode5Bytes[4] := RadioParametersArray[RadioModel].SMOC;

        if Freq < 10000000 then
        begin
          if Mode = Phone then TempByte := RadioParametersArray[RadioModel].LSB;
          if Mode = Digital then TempByte := RadioParametersArray[RadioModel].DIGL;
        end
        else
        begin
          if Mode = Phone then TempByte := RadioParametersArray[RadioModel].USB;
          if Mode = Digital then TempByte := RadioParametersArray[RadioModel].DIGU;
        end;

        if Mode = CW then
        begin
          TempByte := RadioParametersArray[RadioModel].CW;

          if RadioModel in [FT100, FT817, FT847, FT857, FT897, FT920, FT1000MP] then
            if FT1000MPCWReverse then TempByte := $03 else TempByte := $02;

          if RadioModel in [FT747GX, FT840, FT890, FT900, FT990, FT1000] then
            if WideCWFilter then TempByte := $02 else TempByte := $03;
        end;

        if VFO = 'B' then if RadioModel in [FT1000, FT1000MP, FT920] then
            inc(TempByte, $80);

        tYaesuMode5Bytes[RadioParametersArray[RadioModel].mb] := TempByte;
        if RadioModel in [FT857, FT897] then tYaesuSendMode := True else
          WriteToCATPort(tYaesuMode5Bytes, 5);

        Sleep(100);

        {Set Freq}
        FreqToBCD(Freq, boolean(RadioParametersArray[RadioModel].SW), RadioParametersArray[RadioModel].SFOC);

        if VFO = 'B' then if RadioModel in [FT1000, FT1000MP, FT920] then
            inc(tYaesuFreq5Bytes[4], $80);

        if RadioModel in [FT857, FT897] then tYaesuSendFreq := True else WriteToCATPort(tYaesuFreq5Bytes, 5);

        {set VFOA}
        if RadioModel in [FT100, FT920, FT1000, FT1000MP] then
          if VFO = 'A' then
          begin
            ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
            tYaesuMode5Bytes[4] := $05;
            WriteToCATPort(tYaesuMode5Bytes, 5);
          end;

        { Put radio back on VFO A }
        if RadioModel in [FT890, FT990] then
          if VFO = 'B' then
          begin
            ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
            tYaesuMode5Bytes[4] := $05;
            WriteToCATPort(tYaesuMode5Bytes, 5);
          end;

      end;

    rtYaesu2:
      begin
        Format(@tKenwood14Bytes, 'FA%08u;', Freq);
        tKenwood14Bytes[1] := VFO;
        WriteToCATPort(tKenwood14Bytes, 11);

        if Freq < 10000000 then
        begin
          if Mode = Phone then TempChar := '1'; { LSB }
          if Mode = Digital then TempChar := '6'; { RTTY-LSB }
          if Mode = CW then TempChar := '3' {'7'};
        end
        else
        begin
          if Mode = Phone then TempChar := '2'; { USB }
          if Mode = Digital then TempChar := '9'; { RTTY-USB }
          if Mode = CW then TempChar := '3';
          if Mode = FM then TempChar := '4';
        end;

        tKenwood14Bytes[0] := 'M';
        tKenwood14Bytes[1] := 'D';
        tKenwood14Bytes[2] := '0'; //Ord(VFO) - 17;
        tKenwood14Bytes[3] := TempChar;
        tKenwood14Bytes[4] := ';';
        WriteToCATPort(tKenwood14Bytes, 5);
      end;

    rtKenwood:
      begin
        Format(@tKenwood14Bytes, 'FA%011u;', Freq);
        tKenwood14Bytes[1] := VFO;
        AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 14);

        if VFO = 'B' then AddToOutputBuffer {WriteToCATPort}('FR1;FT1;', 8); //temporary active vfo is vfo b for set mode

        case Mode of
          CW: TempByte := Ord('3');
          Digital: TempByte := Ord('6');
          FM: TempByte := Ord('4');

        else { SSB }
          if Freq < 10000000 then
            TempByte := Ord('1') { LSB }
          else
            TempByte := Ord('2'); { USB }
        end;
        tKenwood14Bytes[0] := 'M';
        tKenwood14Bytes[1] := 'D';
        tKenwood14Bytes[2] := CHR(TempByte);
        tKenwood14Bytes[3] := ';';
        AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 4);

        if (VFO = 'B') then AddToOutputBuffer {WriteToCATPort}('FR0;FT0;', 8); //back to vfo a
      end;
  end;

  case RadioModel of

    IC706..IC7800, OMNI6: {KK1L: 6.73 Added OMNI6}
      begin
        if VFO = 'B' then
        begin
          CommandsTempBuffer[0] := CHR(8);
          CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
          CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
          CommandsTempBuffer[3] := CHR(ReceiverAddress);
          CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
          CommandsTempBuffer[5] := ICOM_SET_VFO_COMMAND;
          CommandsTempBuffer[6] := ICOM_SET_VFO_B_COMMAND;
          CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
          AddCommandToBuffer;
{
          ICOM_COMMAND_B1 :=
            ICOM_PREAMBLE_CODE +
            ICOM_PREAMBLE_CODE +
            CHR(ReceiverAddress) +
            ICOM_CONTROLLER_ADDRESS +
            ICOM_SET_VFO_COMMAND +
            ICOM_SET_VFO_B_COMMAND +
            ICOM_END_OF_MESSAGE_CODE;
}
        end;

       { Send the mode information }

        if Mode = FM then TempChar := #5 else
          if Mode = CW then TempChar := #3 else
            if Mode = Digital then TempChar := #4 else
            //must be phone
              if Freq < 10000000 then TempChar := #0 else
                TempChar := #1;

        CommandsTempBuffer[0] := CHR(9);
        CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[3] := CHR(ReceiverAddress);
        CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
        CommandsTempBuffer[5] := ICOM_SET_MODE;
        CommandsTempBuffer[6] := TempChar;
        CommandsTempBuffer[7] := CHR(tIcomFilterWidth); //#02; //noraml width filter
        CommandsTempBuffer[8] := ICOM_END_OF_MESSAGE_CODE;

        if (Mode <> CW) or (tIcomFilterWidth = 0) then
        begin
          CommandsTempBuffer[0] := CHR(8);
          CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
        end;

        AddCommandToBuffer;
{
        ICOM_COMMAND_SET_MODE :=
          ICOM_PREAMBLE_CODE +
          ICOM_PREAMBLE_CODE +
          CHR(ReceiverAddress) +
          ICOM_CONTROLLER_ADDRESS +
          ICOM_SET_MODE +
          #$00 +
// $ I F ICOM_LONG_MODECOMMAND
        #$02 +
// $ I FEND

        ICOM_END_OF_MESSAGE_CODE;

        if Mode = FM then
          TempChar := #5 else
          if Mode = CW then
            TempChar := #3
          else
            if Mode = Digital then
              TempChar := #4
            else //must be phone
              if Freq < 10000000 then
                TempChar := #0
              else
                TempChar := #1;
        ICOM_COMMAND_SET_MODE[6] := TempChar;
}
//        WriteToSerialCATPort(ICOM_COMMAND_SET_MODE, tCATPortHandle);

                    { Send the frequency information }
{
        if RadioModel = IC735 then
          ICOM_COMMAND_SET_FREQ := ICOM_PREAMBLE_CODE + ICOM_PREAMBLE_CODE + CHR(ReceiverAddress) + #$E0 + ICOM_SET_FREQ + #1 + #1 + #1 + #1 + #$FD
        else
          ICOM_COMMAND_SET_FREQ := ICOM_PREAMBLE_CODE + ICOM_PREAMBLE_CODE + CHR(ReceiverAddress) + #$E0 + ICOM_SET_FREQ + #1 + #1 + #1 + #1 + #00 + #$FD;

        Str(Freq, FreqStr);
        while length(FreqStr) < 8 do FreqStr := '0' + FreqStr;

        i := 5; //wli
        for CharPointer := length(FreqStr) downto 1 do
          if Odd(CharPointer) then
          begin
            inc(i);
            TempByte := Ord(FreqStr[CharPointer]) - $30;
            SendByte := SendByte or (TempByte shl 4);
            ICOM_COMMAND_SET_FREQ[i] := CHR(SendByte);
          end
          else
            SendByte := Ord(FreqStr[CharPointer]) - $30;
}

        CommandsTempBuffer[0] := CHR(12);
        CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
        CommandsTempBuffer[3] := CHR(ReceiverAddress);
        CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
        CommandsTempBuffer[5] := ICOM_SET_FREQ;
        CommandsTempBuffer[11] := ICOM_END_OF_MESSAGE_CODE;

        Format(wsprintfBuffer, '%08u', Freq);
        i := 5;
        for CharPointer := 7 downto 0 do
          if not Odd(CharPointer) then
          begin
            inc(i);
            TempByte := Ord(wsprintfBuffer[CharPointer]) - $30;
            SendByte := SendByte or (TempByte shl 4);
            CommandsTempBuffer[i] := CHR(SendByte);
          end
          else
            SendByte := Ord(wsprintfBuffer[CharPointer]) - $30;

        if RadioModel = IC735 then
        begin
          CommandsTempBuffer[0] := CHR(11);
          CommandsTempBuffer[10] := ICOM_END_OF_MESSAGE_CODE;
        end;

        AddCommandToBuffer;

        if VFO = 'B' then
        begin
{
          ICOM_COMMAND_B2 :=
            ICOM_PREAMBLE_CODE +
            ICOM_PREAMBLE_CODE +
            CHR(ReceiverAddress) +
            ICOM_CONTROLLER_ADDRESS +
            ICOM_SET_VFO_COMMAND +
            ICOM_SET_VFO_A_COMMAND +
            ICOM_END_OF_MESSAGE_CODE;
}
          CommandsTempBuffer[0] := CHR(8);
          CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
          CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
          CommandsTempBuffer[3] := CHR(ReceiverAddress);
          CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
          CommandsTempBuffer[5] := ICOM_SET_VFO_COMMAND;
          CommandsTempBuffer[6] := ICOM_SET_VFO_A_COMMAND;
          CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
          AddCommandToBuffer;

        end;
      end;
{
    JST245:
      begin

//         Put radio in remote
        WriteBufferToCATPort('H');
        CPUKeyer.AddSerialPortString(tCATPortType, '1');
        CPUKeyer.AddSerialPortString(tCATPortType, CarriageReturn);

//         Frequency command
        CPUKeyer.AddSerialPortString(tCATPortType, 'F');

        Str(Freq, FreqStr);
        while length(FreqStr) < 8 do FreqStr := '0' + FreqStr;

        for CharPointer := 1 to length(FreqStr) do
          CPUKeyer.AddSerialPortString(tCATPortType, FreqStr[CharPointer]);

        CPUKeyer.AddSerialPortString(tCATPortType, VFO);
        CPUKeyer.AddSerialPortString(tCATPortType, CarriageReturn);

//         Send mode

        CPUKeyer.AddSerialPortString(tCATPortType, 'D');

        if Mode = CW then
          CPUKeyer.AddSerialPortString(tCATPortType, '1')
        else
          if Freq < 10000000 then
            CPUKeyer.AddSerialPortString(tCATPortType, '3')
          else
            CPUKeyer.AddSerialPortString(tCATPortType, '2');

        CPUKeyer.AddSerialPortString(tCATPortType, CarriageReturn);

        CPUKeyer.AddSerialPortString(tCATPortType, 'H'); // Put radio in remote
        CPUKeyer.AddSerialPortString(tCATPortType, '0');
        CPUKeyer.AddSerialPortString(tCATPortType, CarriageReturn);

      end;
}
    Orion:
      begin
        i := Format(tOrionFreq, '*AF%02u.%05u'#13, Freq div 1000000, (Freq div 10) mod 100000);
//        asm push freq  end;
//        i := wsprintf(@tKenwood14Bytes, '*AF%u'#13);
//        asm add esp,12 end;
        tOrionFreq[1] := VFO;
//        WriteToCATPort(tOrionFreq, i);

        case Mode of
          CW:
            if FT1000MPCWReverse then
              TempChar := '3' //  WriteToCATPort('*RMM3'#13, 6)
            else
              TempChar := '2'; //WriteToCATPort('*RMM2'#13, 6);
          Phone:
            if Freq < 10000000 then
              TempChar := '1' //WriteToCATPort('*RMM1'#13, 6)
            else
              TempChar := '0'; //WriteToCATPort('*RMM0'#13, 6);
          FM:
            TempChar := '5'; //WriteToCATPort('*RMM5'#13, 6);
        end;
        Windows.ZeroMemory(@tOrionMode, SizeOf(tOrionMode));
        Windows.lstrcat(tOrionMode, '*RMM?'#13);
        tOrionMode[4] := TempChar;
        if VFO = 'B' then tOrionMode[2] := 'S';
//        WriteToCATPort(tOrionMode, 6);

{
        Str(Freq, FreqStr);
        CPUKeyer.AddSerialPortString(tCATPortType, '*' + VFO + 'F' + FreqStr + CarriageReturn);

        case Mode of
          CW:
            if FT1000MPCWReverse then
              CPUKeyer.AddSerialPortString(tCATPortType, '*RMM3' + CarriageReturn)
            else
              CPUKeyer.AddSerialPortString(tCATPortType, '*RMM2' + CarriageReturn);

          Phone:
            if Freq < 10000000 then
              CPUKeyer.AddSerialPortString(tCATPortType, '*RMM1' + CarriageReturn)
            else
              CPUKeyer.AddSerialPortString(tCATPortType, '*RMM0' + CarriageReturn);
          FM:
            CPUKeyer.AddSerialPortString(tCATPortType, '*RMM5' + CarriageReturn);
        end;
}
      end;
  end;
end;

procedure RadioObject.UpdateBandOutputInfo(Band: BandType; Mode: ModeType);

begin
  if BandOutputPort <> NoPort then
    OutputBandInfo(tBandOutputPortBaseAddress {BandOutputPort}, Band, Mode);
end;

function GenerateStatusString(var StatusRecord: RadioStatusRecord): Str80;

{ This function will generate a string with the complete status of a
  RadioStatusRecord. }

var
  StatusString, TempString              : string;
  TempValue                             : REAL;

begin
  StatusString := '';

  with StatusRecord do
  begin
    TempValue := Freq;
    TempValue := TempValue / 1000; { Convert to kHz }
    Str(TempValue: 5: 1, TempString);
    StatusString := StatusString + TempString + ' ';

    StatusString := StatusString + BandStringsArray[Band] + ' ';
    StatusString := StatusString + ModeStringArray[Mode] + ' ';

    if Split = True then
      StatusString := StatusString + 'Split      '
    else
      StatusString := StatusString + 'Transceive ';

    StatusString := StatusString + 'VFOA= ';

    TempValue := VFO[VFOA].Frequency;
    TempValue := TempValue / 1000; { Convert to kHz }
    Str(TempValue: 5: 1, TempString);
    StatusString := StatusString + TempString + ' ';

    StatusString := StatusString + BandStringsArray[VFO[VFOA].Band] + ' ';
    StatusString := StatusString + ModeStringArray[VFO[VFOA].Mode] + ' ';
      {
               case VFOA.TXRX of
                  VFODisabled: StatusString := StatusString + 'Off ';
                  RXOnly: StatusString := StatusString + 'RX  ';
                  TXOnly: StatusString := StatusString + 'TX  ';
                  Transceive: StatusString := StatusString + 'T/R ';
                  UnknownTXRX: StatusString := StatusString + '??? ';
               end;
      }
    StatusString := StatusString + 'VFOB= ';

    TempValue := VFO[VFOB].Frequency;
    TempValue := TempValue / 1000; { Convert to kHz }
    Str(TempValue: 5: 1, TempString);
    StatusString := StatusString + TempString + ' ';

    StatusString := StatusString + ModeStringArray[VFO[VFOB].Mode] + ' ';
      {
               case VFOB.TXRX of
                  VFODisabled: StatusString := StatusString + 'Off';
                  RXOnly: StatusString := StatusString + 'RX ';
                  TXOnly: StatusString := StatusString + 'TX ';
                  Transceive: StatusString := StatusString + 'T/R';
                  UnknownTXRX: StatusString := StatusString + '???';
               end;
              }
  end;

  GenerateStatusString := StatusString;
end;

procedure TestRadioInterface;

{ This procedure will display the data coming back from the interfaced
  radios }

var
  RadioOneLastDisplayedCurrentStatus    : Str80;
  RadioOneLastDisplayedPreviousStatus   : Str80;
  RadioOneLastDisplayedFilteredStatus   : Str80;

  RadioTwoLastDisplayedCurrentStatus    : Str80;
  RadioTwoLastDisplayedPreviousStatus   : Str80;
  RadioTwoLastDisplayedFilteredStatus   : Str80;

  TempStatusString                      : Str80;
  TempValue                             : REAL;

begin
  //{WLI}    Window (1, 1, 80, 25);

  //{WLI}    TextBackground (Black);
  //{WLI}    NoCursor;

  ShowMessage('TEST RADIO INTERFACE');

  //{WLI}    WriteLn ('This procedure will display the data coming back from the interfaced radios');
  //{WLI}    WriteLn ('Press the ESCAPE key to exit and halt TR.');
  //{WLI}    WriteLn;

  RadioOneLastDisplayedCurrentStatus := '';
  RadioOneLastDisplayedPreviousStatus := '';
  RadioOneLastDisplayedFilteredStatus := '';

  RadioTwoLastDisplayedCurrentStatus := '';
  RadioTwoLastDisplayedPreviousStatus := '';
  RadioTwoLastDisplayedFilteredStatus := '';
  {
      GoToXY (1, 6);
      Write ('Latest Radio One Status');
      GoToXY (1, 9);
      Write ('Previous Radio One Previous Status');
      GoToXY (1, 12);
      Write ('Filtered Radio One Status (gets updated when Previous = Latest)');
      GoToXY (1, 15);
      Write ('Latest Radio Two Status');
      GoToXY (1, 18);
      Write ('Previous Radio Two Status');
      GoToXY (1, 21);
      Write ('Filtered Radio Two Status (gets updated when Previous = Latest)');
  }
  repeat
    Radio1.CheckRadioStatus;

    TempStatusString := GenerateStatusString(Radio1.CurrentStatus);

    if TempStatusString <> RadioOneLastDisplayedCurrentStatus then
    begin
        //{WLI}            GoToXY (1, 7);
        //{WLI}            Write (TempStatusString);

      RadioOneLastDisplayedCurrentStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio1.PreviousStatus);

    if TempStatusString <> RadioOneLastDisplayedPreviousStatus then
    begin
        //{WLI}            GoToXY (1, 10);
        //{WLI}            Write (TempStatusString);

      RadioOneLastDisplayedPreviousStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio1.FilteredStatus);

    if TempStatusString <> RadioOneLastDisplayedFilteredStatus then
    begin
        //{WLI}            GoToXY (1, 13);
        //{WLI}            Write (TempStatusString);

      RadioOneLastDisplayedFilteredStatus := TempStatusString;
    end;

    Radio2.CheckRadioStatus;

    TempStatusString := GenerateStatusString(Radio2.CurrentStatus);

    if TempStatusString <> RadioTwoLastDisplayedCurrentStatus then
    begin
        //{WLI}            GoToXY (1, 16);
        //{WLI}            Write (TempStatusString);

      RadioTwoLastDisplayedCurrentStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio2.PreviousStatus);

    if TempStatusString <> RadioTwoLastDisplayedPreviousStatus then
    begin
        //{WLI}            GoToXY (1, 19);
        //{WLI}            Write (TempStatusString);

      RadioTwoLastDisplayedPreviousStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio2.FilteredStatus);

    if TempStatusString <> RadioTwoLastDisplayedFilteredStatus then
    begin
        //{WLI}            GoToXY (1, 22);
        //{WLI}            Write (TempStatusString);

      RadioTwoLastDisplayedFilteredStatus := TempStatusString;
    end;

  until OperatorEscape;

  CPUKeyer.UnInitializeKeyer; { Fix interrupts and close debug files }

  //{WLI}    GoToXY (1, 24);
  //{WLI}    ClrEol;
  //{WLI}    BigCursor;
  halt;
end;

function OpenCATDebugFile(port: PortType): boolean;
var
  stored                                : integer;
  TempBaudRate                          : Cardinal;
  TempPchar                             : PChar;
  Radio                                 : PChar;
begin
{
  with CPUKeyer do
    if SerialPortDebug then
    begin
      tr4w_PortDebug[port] := True;
      asm
      push eax
      lea eax,TR4W_PATH_NAME
      push eax
      end;
      wsprintf(wsprintfBuffer, '%sCOM%d_DEBUG.HTML');
      asm add esp,16
      end;
      tDebugFile[port] := CreateFile(wsprintfBuffer, GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);

      if port = Radio1.tCATPortType then
      begin
        TempPchar := InterfacedRadioTypeSA[Radio1.RadioModel];
        Radio := Radio1AsPchar;
        TempBaudRate := Radio1.RadioBaudRate;
      end;
      if port = Radio2.tCATPortType then
      begin
        TempPchar := InterfacedRadioTypeSA[Radio2.RadioModel];
        Radio := Radio2AsPchar;
        TempBaudRate := Radio2.RadioBaudRate;
      end;
      asm
      push TempBaudRate
      push Radio
      push TempPChar
      lea  eax,MyCall[1]
      push eax
      end;
      stored := wsprintf(TempBuffer1,
        '<HTML><HEAD><TITLE>TR4W SERIAL PORT DEBUG FILE</TITLE></HEAD><BODY>' +
        '<H3>' + TR4W_CURRENTVERSION + ' SERIAL PORT DEBUG FILE</H3>' +
        '<H3>%s - %s - %s - %u Baud Rate</H3>' +
        '<TABLE BORDER=1 STYLE="FONT-FAMILY:COURIER"><TR><TH>Time</TH><TH WIDTH=60>In/Out</TH><TH>Data</TH><TH>Bytes</TH><TH>HEX</TH></TR>');
      asm add esp,24
      end;
      sWriteFile(tDebugFile[port], TempBuffer1, stored);
    end;
}
end;
{
procedure CloseCATDebugFile(port: PortType);
begin
  sWriteFile(CPUKeyer.tDebugFile[port], '</TABLE></BODY></HTML>', 22);
  CloseHandle(CPUKeyer.tDebugFile[port]);
end;
}

function tPTTVIACAT(PTTOn: boolean): boolean;

var
  IntRadioType                          : InterfacedRadioType;
  SerialPort                            : PortType;
  TempString                            : Str80;
  WaitAnswer                            : Cardinal;
const

  FT890PTTOn                            = CHR($00) + CHR($00) + CHR($00) + CHR($01) + CHR($0F);
  FT890PTTOff                           = CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($0F);

  FT817PTTOn                            = CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($08);
  FT817PTTOff                           = CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($88);

begin
  WaitAnswer := 0;
  Result := False;
  if not tPTTViaCommand then Exit;
  if NoPollDuringPTT then Exit;
  if ActiveRadio = RadioOne then
  begin
    IntRadioType := Radio1.RadioModel;
    SerialPort := Radio1.tCATPortType;
  end
  else
  begin
    IntRadioType := Radio2.RadioModel;
    SerialPort := Radio2.tCATPortType;
  end;

  case IntRadioType of
    TS850, K2, K3:
      if PTTOn then TempString := 'TX;' else TempString := 'RX;';

    FT450, FT950, FT2000, FTDX9000:
      if PTTOn then TempString := 'TX1;' else TempString := 'TX0;';

    FT747GX, FT100, FT840, FT890, FT900, FT990, FT1000, FT1000MP:
      if PTTOn then TempString := FT890PTTOn else TempString := FT890PTTOff;

    FT736R, FT817, FT847 {, FT857, FT897}:
      if PTTOn then TempString := FT817PTTOn else TempString := FT817PTTOff;

    FT920, FT767:
      Exit;
    {
    ; Enable receive mode
    [pmRx]
    Command=FEFE70E0.1C00.00.FD
    ReplyLength=14
    Validate=FEFE70E01C0000FD.FEFEE070FBFD
    ; Enable transmit mode
    [pmTx]
    Command=FEFE70E0.1C00.01.FD
    ReplyLength=14
    Validate=FEFE70E01C0001FD.FEFEE070FBFD
    }
{
    IC746, IC756, IC7000, IC7800:
       begin
          TempString := CHR($FE) + CHR($FE) + CHR(Radio1.ReceiverAddress) + CHR($E0) + CHR($1C) + CHR($00) + CHR($00) + CHR($FD);
          if PTTOn then TempString[7] := CHR($01);
          WaitAnswer := 14;
       end;
}
    //      IC706..IC7800, OMNI6: Exit;
{
    IC7800, IC746..IC756PROIII, IC7000:
      begin
        ActiveRadioPtr.ICOM_COMMAND_PTT := Char(PTTOn);
        Result := True;
        Exit;
      end;
}
    Orion:
      begin
        if PTTOn then
          TempString := '*TK' + CarriageReturn
        else
          TempString := '*TU' + CarriageReturn;
      end;
  else Exit;
  end;

//  CPUKeyer.AddSerialPortString(SerialPort, TempString);
  ActiveRadioPtr.WriteToCATPort(TempString[1], length(TempString));
  if WaitAnswer <> 0 then ReadFromCOMPort(WaitAnswer, @Radio1);
  Result := True;
end;

procedure InitRadios;
var
  TempRadio                             : RadioPtr;
  i                                     : integer;
const
  ra                                    : array[1..2] of RadioPtr = (@Radio1, @Radio2);
begin
  for i := 1 to 2 do
  begin
    TempRadio := ra[i];

    TempRadio.RadioNumberBits := 8;
    TempRadio.RadioStopBits := 2;
    TempRadio.tCATPortHandle := INVALID_HANDLE_VALUE;

    TempRadio.tKeyerPortHandle := INVALID_HANDLE_VALUE;
    TempRadio.tr4w_keyer_rts_state := RtsDtr_PTT;
    TempRadio.tr4w_keyer_DTR_state := RtsDtr_CW;
    TempRadio.tr4w_cat_rts_state := RtsDtr_OFF; //CAT RTS
    TempRadio.tr4w_cat_dtr_state := RtsDtr_OFF; //CAT DTR
    TempRadio.PollingEnable := True;
//    TempRadio.ICOM_COMMAND_PTT := #255;
    TempRadio.SpeedMemory := InitialCodeSpeed;
    TempRadio.tIcomFilterWidth := 2;

  end;
  Radio1.RadioName := TC_RADIO1;
  Radio2.RadioName := TC_RADIO2;
end;

{
function GetRadioFromString(RadioName: ShortString): InterfacedRadioType;
var
  irt                                   : InterfacedRadioType;
  p                                     : PChar;
begin
  RadioName[length(RadioName) + 1] := #0;
  p := @RadioName[1];
  for RESULT := Orion downto NoInterfacedRadio do
    if lstrcmp(RadioParametersArray[RESULT].Name, p) = 0 then Exit;
end;
}

begin
  InitRadios;
end.

