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
   Classes,
   Math,
   SysUtils,
   TF,
   Tree,
   VC,
   Windows,
   utils_text;

var
   Icom_Filter_Width: integer;     // n4af 4.43.4
   TimeoutBuffer:     PCOMMTIMEOUTS;

const

   ICOM_TRANSFER_FREQ = #$00;
   ICOM_TRANSFER_MODE = #$01;

   ICOM_GET_FREQ      = #$03;
   ICOM_GET_MODE      = #$04;
   ICOM_XMIT_SETTINGS = #$1C;

   ICOM_SET_FREQ        = #$05;
   ICOM_SET_MODE        = #$06;
   ICOM_SET_VFO_COMMAND = #$07;

   ICOM_SET_SPLIT_MODE = #$0F;

   ICOM_SET_SLIDERS  = #$14;
   // Things like CW speed, and rotating knobs
   ICOM_SET_CW_SPEED = #$0C;

   ICOM_SEND_CW        = #$17;
   ICOM_SET_XMIT_STATE = #$18;  // + 00 for XMIT off, 01 for XMIT on.

   ICOM_SET_VFO_A_COMMAND = #$00;
   ICOM_SET_VFO_B_COMMAND = #$01;

   ICOM_END_OF_MESSAGE_CODE = #$FD;
   ICOM_PREAMBLE_CODE       = #$FE;

   ICOM_CONTROLLER_ADDRESS   = #$E0;
   ICOM_OTHER_RADIOS_ADDRESS = #$00;

type
   tr4w_RTSDTRType = (RtsDtr_Nothing, RtsDtr_OFF, RtsDtr_ON, RtsDtr_CW, RtsDtr_PTT);

const

   tr4w_RTSDTRTypeSA: array[tr4w_RTSDTRType] of PChar =
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
      {04}Frequency: longint;
      {04}RITFreq:   integer;
      {01}Band:      BandType;
      {01}Mode:      ModeType;
      {01}Split:     boolean;
      {01}RIT:       boolean;
      {01}XIT:       boolean;
   end;

   RadioStatusRecord = record
      //    {24}VFOA: VFOStatusType;
      //    {24}VFOB: VFOStatusType;
      VFO:           array[ActiveVFOStatusType] of VFOStatusType;
      {04}Freq:      longint; // This is the active frequency for the radio
      {04}Split:     longbool;
      {04}RIT:       longbool;
      {04}XIT:       longbool;
      {04}RITFreq:   integer;
      {04}PrevRITFreq: integer;
      {01}Band:      BandType;
      {01}Mode:      ModeType;
      {01}VFOStatus: ActiveVFOStatusType;
      {01}PrevVFOStatus: ActiveVFOStatusType;
      {01}TXOn:      boolean;
   end;

   RadioObject = object
      tDupeSheetWnd:     HWND;
      tDisableCIVTransceive: boolean;
      tPTTStatus:        PTTStatusType;
      tTwoRadioMode:     TRMode;
      RadioOnTheMove:    boolean;
      LastDisplayedFreq: integer;
      SpeedMemory:       integer;
      BandMemory:        BandType;
      ModeMemory:        ModeType;

      FreqWindowHandle: HWND;
      RadioName:        Str20;
      //    lpOverlapped: TOverlapped;
      //    pOver: POverlapped;

      CommandsBuffer:        array[0..7] of array[0..{19}40] of char;
      CommandsBufferPointer: cardinal;
      CommandsTempBuffer:    array[0..{19}40] of char; // ny4i extended for icom cw  // 4.44.5

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

      tRadioInterfaceThreadID: cardinal;
      tRadioInterfaceThreadHandle: HWND;
      tPollCount: integer;
      tStatusEqualityCounter: cardinal;
      tRadioInterfaceWndHandle: HWND;
      RITWndHandle: HWND;
      XITWndHandle: HWND;
      SplitWndHandle: HWND;
      tRadioOnTheMove: boolean;
      tBuf: array[1..512] of char;
      active : boolean;
      CurrentStatus:   RadioStatusRecord; { Last reading taken }
      PreviousStatus:  RadioStatusRecord; { Reading before Last }
      FilteredStatus:  RadioStatusRecord; { Updated if Current = Previous }
      FilteredStatusChanged: boolean;
      BandOutputPort:  PortType;
      tBandOutputPortBaseAddress: HWND;
      CommandPauseTimeStamp: TimeRecord;
      FrequencyAdder:  longint;
      FT1000MPCWReverse: boolean;
      CWByCAT:         boolean;                    // ny4i 4.44.5
      CWSpeedSync:     boolean;
      CWByCAT_Sending: boolean;                    // ny4i Issue 129
      WideCWFilter:    boolean;
      IcomFilterByte:  byte;
      IDCharacter:     char;
      CWByCATBuffer:   string;                  // ny4i 4.44.5
      //    PartialRadioResponse: string;
      PollingEnable:   boolean;
      PollDelay:       integer;
      PollStatus:      PollingStatusType;
      PollTime:        cardinal {TimeRecord};
      RadioModel:      InterfacedRadioType;
      RadioBaudRate:   cardinal;
      RadioNumberBits: integer;
      RadioStopBits:   integer;
      RadioParity:     ParityType;
      RadioTimeout:    integer;
      ReceiverAddress: integer; { Used for Icom interfaces }
      WaitingForCommandPause: boolean;

      tCATPortType:   PortType;
      tCATPortHandle: HWND;

      tKeyerPort:       PortType;
      tKeyerPortHandle: HWND;

      tr4w_keyer_rts_state: tr4w_RTSDTRType; //keyer RTS
      tr4w_keyer_DTR_state: tr4w_RTSDTRType; //keyer DTR
      tr4w_cat_rts_state:   tr4w_RTSDTRType; //CAT RTS
      tr4w_cat_dtr_state:   tr4w_RTSDTRType; //CAT DTR

      tYaesuFreq5Bytes: array[0..4] of byte;
      tYaesuMode5Bytes: array[0..4] of byte;

      tYaesuSendFreq: boolean;
      tYaesuSendMode: boolean;

      tIcom6Bytes: array[0..5] of byte;
      tIcom7Bytes: array[0..6] of byte; //ny4i  // 4.44.5

      tIcomFilterWidth: integer;

      tKenwood14Bytes: array[0..14] of char;

      tOrionFreq:   array[0..15] of char;
      tOrionMode:   array[0..07] of char;
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
      procedure SendIcomCommand(Command: byte);
      procedure SendXMITStatusCommand;
      //    function SendFiveBytes: boolean;
      procedure SetRadioCWSpeed(speed: longint);
      procedure SetRadioFreq(Freq: longint; Mode: ModeType; VFO: char);
      //    procedure _SetRadioFreq(Freq: LONGINT; Mode: ModeType; VFO: Char);
      procedure SendCW(Msg: Str160);
      procedure SetUpRadioInterface;
      procedure StopSendingCW;
      //    procedure StartNextPoll;
      //    function TimeToGiveUp: boolean;
      procedure UpdateBandOutputInfo(Band: BandType; Mode: ModeType);
      procedure UpdateRadioStatus;
      function ConvertBCDStringToFreq(BCDString: Str20): longint;
      procedure FreqToBCD(Freq: longint; Swap: boolean; OpCode: byte);
      procedure CheckAndInitializeSerialPorts_ForThisRadio;
      function WriteToCATPort(const Buffer; nNumberOfBytesToWrite: DWORD): longbool;
      function WritePollRequest(const Buffer; nNumberOfBytesToWrite: DWORD): longbool;
      function AddToOutputBuffer(Buffer: PChar; nNumberOfBytesToWrite: DWORD): longbool;
      procedure WriteBufferToCATPort(const Buffer);
      //    property fddd;
   end;
   RadioPtr = ^RadioObject;

var
   IcomResponseTimeout:    integer;
   cmdIcomResponseTimeout: integer = -1;
   newIcomResponseTimeout: integer = 60;

   newIcomResponseTimeoutAuto: integer;
   icomCIVTransceiveEnable:    boolean;

   TwoRadioMode: boolean;

   Radio1:           RadioObject {=
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
   Radio2:           RadioObject {=
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
   ActiveRadioPtr:   RadioPtr = @Radio1;
   InActiveRadioPtr: RadioPtr = @Radio2;
   RadioSupportsCWByCAT: InterfacedRadioTypeSet;
   RadioSupportsCWSpeedSync: InterfacedRadioTypeSet;
   ICOMRadios:       ICOMRadioTypes;
   KenwoodRadios:    KenwoodRadioTypes;

const
   RTS_DTR_Values_Array: array[1..4] of PChar =
      ('OFF', 'ON', 'CW', 'PTT');

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
      br:   BaudRateType; //Baud Rate
      p:    byte; //Polling
      c:    byte; //ShiftInCQMode
      s:    byte; //ShiftInSPMode
      t:    byte; //PTTViaCommand
      RA:   byte; //ReceiverAddress
      SW:   byte; //Swap
      SFOC: byte; //SetFreqOpCode
      SMOC: byte; //SetModeOpCode
      SPOC: byte; //SetPTTOpCode
      RX:   byte; //RXOpCode
      TX:   byte; //TXOpCode
      mb:   byte; //PositionOfModeByte

      CW:   byte; //CWLOpCode
      //    CWU: Byte; //CWLOpCode
      LSB:  byte; //LSBOpCode
      USB:  byte; //USBOpCode
      FM:   byte; //FMOpCode
      AM:   byte; //AMOpCode
      DIGL: byte; //DigLOpCode
      DIGU: byte; //DigUOpCode

      rt: RigType;
   end;

//const
//  YaesuReplyRigs                        : array[0..1] of InterfacedRadioType = (FT857, FT897);
{
 When adding an item here, you have to
    1. Add a type to the InterfacedRadioType around line 920 in VC.pas
    2. Each new radio requires the type in InterfacedRadioType, the entry
       below in the RadioParametersArray array and the literal name of the
       radio in InterfacedRadioTypeSA below.  // Issue 120
    3. Also update the Sets in InitRadio wherever applicable for the new radio.
 - ny4i
}
const
   RadioParametersArray: array[InterfacedRadioType] of
      TRadioParameters =
      (
{(*}
    ({Name: 'NONE';       } BR:BR4800;  P: 1; C: 0; S: 0; T:0; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00),
    ({Name: 'K2';         } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'K3';         } BR:BR38400; P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS140';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS440';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS450';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS480';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS570';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS590';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS690';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS850';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS870';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS940';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS950';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS990';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'TS2000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),
    ({Name: 'Flex';       } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00;  LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtKenwood),

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
    ({Name: 'FT991';      } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FT1000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $03; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $09; rt: rtYaesu1),
    ({Name: 'FT1000MP';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $0A; SMOC: $0C; SPOC: $00; RX: $00; TX: $00; MB: 3; CW: $02; LSB: $00; USB: $01; FM: $06; AM: $04; DIGL: $08; DIGU: $09; rt: rtYaesu1),
    ({Name: 'FT1200';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FT2000';     } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FTDX3000';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
    ({Name: 'FTDX5000';   } BR:BR4800;  P: 1; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtYaesu2),
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
    ({Name: 'IC7100';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $88; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7200';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $76; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7300';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $94; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7410';     } BR:BR19200;  P: 1; C: 0; S: 0; T:0; RA: $80; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7600';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $7A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7700';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $74; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7800';     } BR:BR9600;  P: 1; C: 0; S: 0; T:0; RA: $6A; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7850';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $8E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC7851';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $8E; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'IC9100';     } BR:BR19200; P: 1; C: 0; S: 0; T:0; RA: $7C; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),

    ({Name: 'OMNI6';      } BR:BR9600;  P: 1; C: 1; S: 1; T:0; RA: $04; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt: rtIcom),
    ({Name: 'ORION';      } BR:BR57600; P: 0; C: 1; S: 1; T:1; RA: $00; SW: 1; SFOC: $00; SMOC: $00; SPOC: $00; RX: $00; TX: $00; MB: 0; CW: $00; LSB: $00; USB: $00; FM: $00; AM: $00; DIGL: $00; DIGU: $00; rt:rtOrion)
    );
{*)}
const
   InterfacedRadioTypeSA: array[InterfacedRadioType] of PChar = (

      'NONE',
      'K2',
      'K3',
      'TS440',
      'TS450',
      'TS480',
      'TS530',
      'TS570',
      'TS590',
      'TS690',
      'TS850',
      'TS870',
      'TS940',
      'TS950',
      'TS990',
      'TS2000',
      'Flex',

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
      'FT991',
      'FT1000',
      'FT1000MP',
      'FT1200',
      'FT2000',
      'FTDX3000',
      'FTDX5000',
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
      'IC7100',
      'IC7200',
      'IC7300',
      'IC7410',
      'IC7600',
      'IC7700',
      'IC7800',
      'IC7850',
      'IC7851',
      'IC9100',
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


function IntegerToBCD(Value: DWORD): integer; // ny4i  // 4.44.5
procedure InitRadios;
function OpenCATDebugFile(port: PortType): boolean;
//procedure CloseCATDebugFile(port: PortType);

function tPTTVIACAT(PTTOn: boolean): boolean;
//function GetRadioFromString(RadioName: ShortString): InterfacedRadioType;
procedure TestRadioInterface;

{ Old style function calls supported here }

{ Works on the radio specified  (Radio1 or Radio2) }

function GetRadioParameters(Radio: RadioType; RadioInfoString: string;
   var Freq: longint; var Band: BandType; var Mode: ModeType;
   Polling: boolean; Debug: boolean): boolean;
//wli
function GenerateStatusString(var StatusRecord: RadioStatusRecord): Str80;
procedure PutRadioIntoSplit(Radio: RadioType);
procedure PutRadioOutOfSplit(Radio: RadioType);
procedure SetRadioFreq(Radio: RadioType; Freq: longint; Mode: ModeType; VFO: char);

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
   MainUnit, uRadioPolling,
   uTelnet;

function IntegerToBCD(Value: DWORD): integer;
const
   Dividers: array[1..8] of integer = (1, 10, 100, 1000, 10000, 100000, 1000000, 10000000);
var
   j: integer;
begin
   Result := 0;
   for j := 8 downto 1 do //8 digits
      begin
      Result := (Result shl 4) or ((Value div Dividers[j]) mod 10);
      end;
end;//IntegerToBCD


function BufToStr(var buf; bufSize: integer): string;
begin
   SetLength(Result, bufSize);
   Move(buf, pointer(Result)^, bufSize);
end;
//------------------------------------------------------------------------------
procedure LinkToActiveRadio(IntRadioType: InterfacedRadioType;
   SerialPort: PortType);
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
end;



procedure RITClear;

var
   IntRadioType: InterfacedRadioType;
   SerialPort: PortType;

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
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940,
      TS950, TS990, TS2000, FLEX, K2, K3, FT450, FT950, FT991, FT1200, FT2000, FTDX3000,
      FTDX5000, FTDX9000:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('RC;');
         end;

      FT747GX, FT890, FT920, FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR($FF) + CHR($09), 5);
         end;

      IC78..IC9100, OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*RMR0' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
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
   IntRadioType: InterfacedRadioType;
   SerialPort: PortType;

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
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940,
      TS950, TS990, TS2000, K2, K3 {, FTDX9000}:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('RU;');
         end;

      FT890, FT920, FT990, FT1000, FT1000MP:
         begin
         Exit;
         end;

      IC78..IC9100, OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*RMR200' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;

procedure RITBumpDown;

var
   IntRadioType: InterfacedRadioType;
   SerialPort: PortType;

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
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940,
      TS950, TS990, TS2000, K2, K3 {, FTDX9000}:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('RD;');
         end;

      FT890, FT920, FT990, FT1000, FT1000MP:
         begin
         Exit;
         end;

      IC78..IC9100, OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*RMR-200' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;

procedure VFOBumpUp;

var
   IntRadioType: InterfacedRadioType;
   SerialPort: PortType;

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

      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940,
      TS950, TS990, TS2000, FLEX:
         begin
         ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('UP;', 3);
         end;

      FT450, FT950, FT2000, FTDX9000, K2, K3:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('UP;');
         end;

      FT890, {FT920,} FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR($8E) + CHR(0) + CHR(0) + CHR(0) + CHR(0));
         end;

      FT767:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR($02));
         end;

      IC78..IC9100, OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         if ActiveRadioPtr.CurrentStatus.Freq = 0 then
            begin
            Exit;
            end;
         ActiveRadioPtr.SetRadioFreq(ActiveRadioPtr.CurrentStatus.Freq + 20,
            ActiveRadioPtr.CurrentStatus.Mode, 'A');
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*AS+1' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
      end;
end;

procedure VFOBumpDown;

var
   IntRadioType: InterfacedRadioType;
   SerialPort: PortType;

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

      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940,
      TS950, TS990, TS2000, FLEX:
         begin
         ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('DN;', 3);
         end;

      FT450, FT950, FT2000, FTDX9000, K2, K3:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('DN;');
         end;

      FT890, {FT920,} FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR($8E) + CHR(1) + CHR(0) + CHR(0) + CHR(0));
         end;

      FT767:
         begin
         ActiveRadioPtr.WriteBufferToCATPort(
            CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR($03));
         end;

      IC78..IC9100, OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         if ActiveRadioPtr.CurrentStatus.Freq = 0 then
            begin
            Exit;
            end;
         ActiveRadioPtr.SetRadioFreq(ActiveRadioPtr.CurrentStatus.Freq - 20,
            ActiveRadioPtr.CurrentStatus.Mode, 'A');
         Exit;
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*AS-1' + CarriageReturn);
         Exit;
         end;

      else
         begin
         Exit;
         end;
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

function GetRadioParameters(Radio: RadioType; RadioInfoString: string;
   var Freq: longint; var Band: BandType; var Mode: ModeType;
   Polling: boolean; Debug: boolean): boolean;

begin
   //  GetRadioParameters := true;

   case Radio of
      RadioOne:
         begin
         with Radio1 do
            begin
            Freq := FilteredStatus.Freq;
            Band := FilteredStatus.Band;
            Mode := FilteredStatus.Mode;
            GetRadioParameters := {true} FilteredStatus.Freq <> 0; //wli
            end;
         end;

      RadioTwo:
         begin
         with Radio2 do
            begin
            Freq := FilteredStatus.Freq;
            Band := FilteredStatus.Band;
            Mode := FilteredStatus.Mode;
            GetRadioParameters := {true} FilteredStatus.Freq <> 0; //wli
            end;
         end;
      end;
end;

procedure PutRadioIntoSplit(Radio: RadioType);

begin
   case Radio of
      RadioOne:
         begin
         Radio1.PutRadioIntoSplit;
         end;
      RadioTwo:
         begin
         Radio2.PutRadioIntoSplit;
         end;
      end;
end;

procedure PutRadioOutOfSplit(Radio: RadioType);

begin
   case Radio of
      RadioOne:
         begin
         Radio1.PutRadioOutOfSplit;
         end;
      RadioTwo:
         begin
         Radio2.PutRadioOutOfSplit;
         end;
      end;
end;

procedure SetRadioFreq(Radio: RadioType; Freq: longint; Mode: ModeType; VFO: char);

{ Backwards compatable routine to the pre TR680 days }

begin
   case Radio of
      RadioOne:
         begin
         Radio1.SetRadioFreq(Freq, Mode, VFO);
         end;
      RadioTwo:
         begin
         Radio2.SetRadioFreq(Freq, Mode, VFO);
         end;
      end;
end;

procedure RadioObject.WriteBufferToCATPort(const Buffer);
begin
   WriteToCATPort(Buffer, lstrlen(@Buffer));
end;

function RadioObject.WritePollRequest(const Buffer;
   nNumberOfBytesToWrite: DWORD): longbool;
begin
 { if NoPollDuringPTT then
  if tPTTStatus = PTT_ON then
  Sleep(500);   }
      try
      Result := WriteToCATPort(Buffer, nNumberOfBytesToWrite);
      except //on E : Exception do
      ; // TLogger.GetInstance.Debug(Format('In WritePollRequest, %s error raised, with message <%s> ',[E.ClassName,E.Message]));
      end;
   if not Result then
      begin
      Sleep(200);
      end;
end;


function RadioObject.AddToOutputBuffer(Buffer: PChar;
   nNumberOfBytesToWrite: DWORD): longbool;
begin
   //  TLogger.GetInstance.Debug('In AddToOutputBuffer');
   //  sleep(100);
   //  Windows.lstrcat(CommandsBuffer[0], Buffer);
{$IF MASKEVENT}
   Windows.CopyMemory(@CommandsBuffer[0][CommandsBufferPointer], Buffer,
      nNumberOfBytesToWrite);
   Inc(CommandsBufferPointer, nNumberOfBytesToWrite);
{$ELSE}
  WriteToCATPort(Buffer^, nNumberOfBytesToWrite);
  DebugMsg(Buffer);
{$IFEND}
   //TLogger.GetInstance.Debug('Exiting AddToOutputBuffer');
end;

function RadioObject.WriteToCATPort(const Buffer;
   nNumberOfBytesToWrite: DWORD): longbool;
var
   lpNumberOfBytesWritten: DWORD;
   s: string;
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
      try
      // TLogger.GetInstance.Debug('In WriteToCATPort');
      //SetString(s,PChar(@Buffer),nNumberOfBytesToWrite);
      //TLogger.GetInstance.Debug(Format('[%s] Calling WriteFile to write %u bytes <%s>',[RadioName,nNumberOfBytesToWrite,s]));
      Windows.WriteFile(tCATPortHandle, Buffer, nNumberOfBytesToWrite,
         lpNumberOfBytesWritten, nil);
      // TLogger.GetInstance.Debug(Format('After WriteFile: %u bytes written',[lpNumberOfBytesWritten]));
      except // on E : Exception do
      ; // TLogger.GetInstance.Debug(Format('In WriteToCATPort..WriteFile, %s error raised, with message <%s> ',[E.ClassName,E.Message]));
      end;
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
   // TLogger.GetInstance.Debug('[Exit WriteToCATPort');
end;

procedure RadioObject.CheckAndInitializeSerialPorts_ForThisRadio;
begin
   if RadioModel = NoInterfacedRadio then
      begin
      Exit;
      end;
   if RadioModel in [IC78..IC9100, FT100, Orion] then
      begin
      RadioStopBits := 1;
      end
   else
      begin
      RadioStopBits := 2;
      end;
   SetUpRadioInterface;

   if tCATPortHandle <> INVALID_HANDLE_VALUE then
      begin
      if PollingEnable then
         begin
         tPollCount := -1;
         tRadioInterfaceThreadHandle :=
            CreateThread(nil, 0, @BeginPolling, @Self, 0, tRadioInterfaceThreadID);
         end;
      end;

end;

procedure RadioObject.FreqToBCD(Freq: longint; Swap: boolean; OpCode: byte);
var
   TempByte, sb1, sb2: byte;
   c: cardinal;
   TempFreq: longint;
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
      if c = 0 then
         begin
         if Freq > 1000000000 then
            begin
            sb1 := sb1 + 10;
            end;
         end;
      TempByte := sb1 * 16 + sb2;
      tYaesuFreq5Bytes[c] := TempByte;
      end;

   if Swap then
      begin
      c := PDWORD(@tYaesuFreq5Bytes)^;
      asm
         MOV EAX,c
         BSWAP EAX
         MOV c,EAX
      end;
      PDWORD(@tYaesuFreq5Bytes)^ := c;
      end;
end;

function RadioObject.ConvertBCDStringToFreq(BCDString: Str20): longint;

var
   F1: longint;

begin
   if length(BCDString) = 5 then
      begin
      F1 := (Ord(BCDString[5]) and $F0) shr 4; { 1000s of mhz }
      F1 := F1 * 10;
      F1 := F1 + (Ord(BCDString[5]) and $0F); { 100s of mhz}
      F1 := F1 * 10;
      end
   else
      begin
      F1 := 0;
      end;

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

function FrequencyFromFourBytes(FreqStr: string): longint;

var
   F1, F2, F3: longint;

begin
   F1 := Ord(FreqStr[1]);
   F1 := F1 * 256 * 256 * 256;
   F2 := Ord(FreqStr[2]);
   F2 := F2 * 256 * 256;
   F3 := Ord(FreqStr[3]);
   F3 := F3 * 256;
   FrequencyFromFourBytes := F1 + F2 + F3 + Ord(FreqStr[4]);
end;

procedure RadioObject.SendIcomCommand(Command: byte);
var
   s: string;
begin

   tIcom6Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom6Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom6Bytes[2] := ReceiverAddress;
   tIcom6Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom6Bytes[4] := Command;
   tIcom6Bytes[5] := Ord(ICOM_END_OF_MESSAGE_CODE);

   //TLogger.GetInstance.Debug(Format('In SendIcomCommand, Sending command %s',[Chr(Command)]));
   WriteToCATPort(tIcom6Bytes, 6);
end;
//------------------------------------------------------------------------------
procedure RadioObject.SendXMITStatusCommand;
begin
   tIcom7Bytes[0] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[1] := Ord(ICOM_PREAMBLE_CODE);
   tIcom7Bytes[2] := ReceiverAddress;
   tIcom7Bytes[3] := Ord(ICOM_CONTROLLER_ADDRESS);
   tIcom7Bytes[4] := Ord(ICOM_XMIT_SETTINGS);
   tIcom7Bytes[5] := (Ord(Chr(0)));
   tIcom7Bytes[6] := Ord(ICOM_END_OF_MESSAGE_CODE);
   WriteToCATPort(tIcom7Bytes, 7);
end; // SendXMITStatusCommand;
 //------------------------------------------------------------------------------

procedure RadioObject.PutRadioIntoSplit;

begin
   //TLogger.GetInstance.Debug(Format('      In PutRadioIntoSplit: %s',[RadioName]));
   case RadioModel of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940, TS950, TS990,
      TS2000, FLEX, K2, K3:
         begin
         AddToOutputBuffer('FR0;FT1;', 8);

         {KK1L: 6.71 For some reason needed this to get the FT1; }
         {           command to take. Started when I added setting }
         {           mode of B VFO to set freq.                    }

         //        ActiveRadioPtr.WriteBufferToCATPort('FA;');
         //        ActiveRadioPtr.WriteBufferToCATPort('FT1;');//vfo b = tx
         end;

      IC78..IC9100, OMNI6: { KK1L: 6.73 Added OMNI6 }
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

         end;

      FT747GX, FT100, FT890, FT900, FT920, FT990, FT1000, FT1000MP:
         begin
         ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR(1) + CHR(1), 5);
         end;

      FT450, FT950, FT991, FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000:
         begin
         ActiveRadioPtr.WriteToCATPort('FR0;FT1;', 8);
         end;
      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*KVABB' + CarriageReturn);
         end;

      end;
   // TLogger.GetInstance.Debug(Format('      Leaving PutRadioIntoSplit: %s',[RadioName]));
end;

procedure RadioObject.PutRadioOutOfSplit;

begin
   //TLogger.GetInstance.Debug(Format('      In PutRadioOutOfSplit: %s',[RadioName]));
   case RadioModel of
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940, TS950, TS990,
      TS2000, FLEX, K2, K3:
         begin
         //ActiveRadioPtr.AddToOutputBuffer {WriteBufferToCATPort}('FR0;FT0;', 8);
         AddToOutputBuffer('FR0;FT0;', 8);

         //        ActiveRadioPtr.WriteBufferToCATPort('FT0;');
         end;

      IC78..IC9100, OMNI6: {KK1L: 6.73 Added OMNI6}
         begin
         // TLogger.GetInstance.Debug('Sending commands to take Icom out of Split');
         CommandsTempBuffer[0] := CHR(8);
         CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
         CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
         CommandsTempBuffer[3] := CHR(ReceiverAddress);
         CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
         CommandsTempBuffer[5] := ICOM_SET_SPLIT_MODE;
         CommandsTempBuffer[6] := CHR(0);
         CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
         AddCommandToBuffer;
         end;

      FT747GX, FT100, FT890, FT900, FT920, FT990, FT1000, FT1000MP: { QSL }
         begin
         ActiveRadioPtr.WriteToCATPort(CHR(0) + CHR(0) + CHR(0) + CHR(0) + CHR(1), 5);
         end;

      FT450, FT950, FT991, FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000:
         begin
         ActiveRadioPtr.WriteToCATPort('FR0;FT0;', 8);
         end;

      Orion:
         begin
         ActiveRadioPtr.WriteBufferToCATPort('*KVABA' + CarriageReturn);
         end;

      end;
   //TLogger.GetInstance.Debug(Format('      Leaving PutRadioOutOfSplit: %s',[RadioName]));
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
      begin
      FilteredStatus.Freq := CurrentStatus.Freq;
      end;

   if CurrentStatus.Mode = PreviousStatus.Mode then
      begin
      FilteredStatus.Mode := CurrentStatus.Mode;
      end;

   if CurrentStatus.Band = PreviousStatus.Band then
      begin
      FilteredStatus.Band := CurrentStatus.Band;
      end;

   if CurrentStatus.Split = PreviousStatus.Split then
      begin
      FilteredStatus.Split := CurrentStatus.Split;
      end;

   if CurrentStatus.VFO[VFOA].Frequency = PreviousStatus.VFO[VFOA].Frequency then
      begin
      FilteredStatus.VFO[VFOA].Frequency := CurrentStatus.VFO[VFOA].Frequency;
      end;

   if CurrentStatus.VFO[VFOA].Band = PreviousStatus.VFO[VFOA].Band then
      begin
      FilteredStatus.VFO[VFOA].Band := CurrentStatus.VFO[VFOA].Band;
      end;

   if CurrentStatus.VFO[VFOA].Mode = PreviousStatus.VFO[VFOA].Mode then
      begin
      FilteredStatus.VFO[VFOA].Mode := CurrentStatus.VFO[VFOA].Mode;
      end;

   //   if CurrentStatus.VFOA.TXRX = PreviousStatus.VFOA.TXRX then
   //      FilteredStatus.VFOA.TXRX := CurrentStatus.VFOA.TXRX;

   if CurrentStatus.VFO[VFOB].Frequency = PreviousStatus.VFO[VFOB].Frequency then
      begin
      FilteredStatus.VFO[VFOB].Frequency := CurrentStatus.VFO[VFOB].Frequency;
      end;

   if CurrentStatus.VFO[VFOB].Band = PreviousStatus.VFO[VFOB].Band then
      begin
      FilteredStatus.VFO[VFOB].Band := CurrentStatus.VFO[VFOB].Band;
      end;

   if CurrentStatus.VFO[VFOB].Mode = PreviousStatus.VFO[VFOB].Mode then
      begin
      FilteredStatus.VFO[VFOB].Mode := CurrentStatus.VFO[VFOB].Mode;
      end;

   //   if CurrentStatus.VFOB.TXRX = PreviousStatus.VFOB.TXRX then
   //      FilteredStatus.VFOB.TXRX := CurrentStatus.VFOB.TXRX;

   if CurrentStatus.TXOn = PreviousStatus.TXOn then        // ny4i  // 4.44.5
      begin
      FilteredStatus.TXOn := CurrentStatus.TXOn;
      end;

   PreviousStatus := CurrentStatus;
end;

procedure RadioObject.AddCommandToBuffer;
begin
   // TLogger.GetInstance.Debug('Entering AddCommandToBuffer');
   if not PollingEnable then
      begin
      WriteToCATPort(PChar(@CommandsTempBuffer[1])^, Ord(CommandsTempBuffer[0]) - 1);
      // TLogger.GetInstance.Debug('Entering sleep(250)');
      Sleep(250);
      // TLogger.GetInstance.Debug('Returning from sleep(250)');
      // TLogger.GetInstance.Debug('Leaving AddCommandToBuffer via Exit');
      Exit;
      end;

   if CommandsBufferPointer = 8 then
      begin
      CommandsBufferPointer := 0;
      end;
      DebugMsg(pChar(@CommandsTempBuffer));
   Windows.CopyMemory(@CommandsBuffer[CommandsBufferPointer],
      @CommandsTempBuffer, Ord(CommandsTempBuffer[0]));
   Inc(CommandsBufferPointer);
   //TLogger.GetInstance.Debug('Leaving AddCommandToBuffer');
end;

procedure RadioObject.CheckRadioStatus;
var
   answer, FreqString, TestString: string;
   TempMode: ModeType;

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
//------------------------------------------------------------------------------
procedure FlushCWByCATBuffer;      // ny4i 4.44.5
begin
end;
//------------------------------------------------------------------------------
procedure RadioObject.SendCW(Msg: Str160);
var
   localMsg: string;
   i: integer;
   msgLen: integer;
   len: integer;
   maxLen: integer;
   pad: boolean;
   tempLen: integer;
   sLen: integer;
   sMsg: string;
   sendNow : boolean;
   formatStr: string;
   debugStr: string;
begin
   if not ( Self.CWByCAT and (Self.RadioModel in RadioSupportsCWByCAT) ) then
      begin
      exit;   // No need to be here if radio does not support CWBYCAT and not active
      end;
   // scWK_Reset;    // n4af 4.46.3  // ny4i This would not be necessary as this code is in the radio object. It is ONLY used by CWByCAT.
   localMsg := Msg;
   case RadioParametersArray[RadioModel].rt of
      rtKenwood:
         begin
         // This is all commented out until Elecraft fixes a bug with the
         // speed change being processed out of order. ny4i
         // For now, we do not want to send these to the radio
         if Msg = #06 then // increase speed
            begin
            CodeSpeed := CodeSpeed + Round(CodeSpeed * 0.06); // increase 6 %
            //SetRadioCWSpeed(CodeSpeed);
            sendNow := true;
            end
         else if Msg = #$13 then
            begin       // Speed down by 6 %
            CodeSpeed := CodeSpeed - Round(CodeSpeed * 0.06); // increase 6 %
            //SetRadioCWSpeed(CodeSpeed);
            sendNow := true;
            end;
         if (Msg = Chr(242)) or sendNow then // Do nothing
            begin
            Msg := CWByCATBuffer;               // ny4i 4.44.5
            msgLen := length(Msg);              //length(Msg);
            //len := Min(msgLen, 24);             // 24 max for Kenwood
            case RadioModel of
               TS480, TS570, TS590, TS950, TS990, TS2000, FLEX:
                  begin
                  maxLen := 24;
                  pad := true;
                  end;
               K2, K3:
                  begin
                  maxLen := 22; //28;
                  pad := false;
                  end;
               end; // case
            Msg := CWByCATBuffer;
            tempLen := length(Msg);
            while tempLen > 0 do
               begin  // Loop around to to process the message in maxLen chunks;
               sLen := min(tempLen,maxLen);
               sMsg := Copy(msg,1,sLen); // Move sLen chars into sMsg;
               Delete(Msg,1,sLen); // Delete sLen characters from start of Msg
               if pad then
                  begin
                  while length(sMsg) < maxLen do
                     begin
                     sMsg := sMsg + ' ';
                     end;
                  end;
               if Self.active then
                  begin
                  DebugMsg('Sending on ACTIVE radio ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                  if InactiveRadioPtr.CWByCAT_Sending then
                     begin
                     DebugMsg('Stopping sending CW on INACTIVE ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                     InactiveRadioPtr.StopSendingCW;
                     sleep(500); // Give command chance to complete
                     end;
                  end
               else // Inactive
                  begin
                  DebugMsg('Sending on INACTIVE radio ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                  if ActiveRadioPtr.CWByCAT_Sending then
                     begin
                     DebugMsg('Stopping sending CW on ACTIVE ' + Self.RadioName + ' (' + InterfacedRadioTypeSA[Self.RadioModel] + ')');
                     ActiveRadioPtr.StopSendingCW;
                     end;
                  end;
               if sendNow then
                  begin
                  formatStr := 'KYW%s;'
                  end
               else
                  begin
                  formatStr := 'KY %s;';
                  end;
               localMsg := Format(formatStr, [sMsg]);

               AddToOutputBuffer(addr(localMsg[1]), length(localMsg));
               Self.CWByCAT_Sending := true;
               DebugMsg('Self.CWByCAT_Sending set to TRUE - Elecraft/Kenwood/Flex');
               tempLen := length(Msg);
               end;
            CWByCATBuffer := ''; // Clear the buffer
            if sendNow then
               begin
               sendNow := false;
               SetRadioCWSpeed(CodeSpeed);
               end;
            end
         else
            begin
            Self.CWByCATBuffer := Self.CWByCATBuffer + Msg; // Just add Msg to the buffer - Issue 131 ny4i
            end;
         end; // case Kenwood...
      rtYaesu1:
         begin    // Yaesu does not support sending free-form text via CAT.
         ;     // You can send memories that are previously programmed though.
         end;     // This is not applicable to this program however.

      rtIcom:
         begin
         if RadioModel in RadioSupportsCWByCAT then
            begin
            if Ord(Msg[1]) = 242 then // Flush if Msg = #242
               begin
               Msg := CWByCATBuffer;               // ny4i 4.44.5
               msgLen := length(CWByCATBuffer);    //length(Msg);
               len := Min(msgLen, 28);
               // Max for Icom radio. TODO Optimally, this should be sent in multiple batches
               localMsg := Format('%s', [Msg]);
               DebugMsg('Sending to Icom[' + IntToStr(len) + ' bytes]=' + localMsg);
               CommandsTempBuffer[0] := Chr(8 + len);
               CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
               CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
               CommandsTempBuffer[3] := CHR(ReceiverAddress);
               CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
               CommandsTempBuffer[5] := ICOM_SEND_CW;
               CommandsTempBuffer[6] := Chr(0); // No sub command
               // Up to 30 characters, add the text to send as ASCII

               //Maybe turn interrogate off when sending?
               for i := 1 to len do
                  begin
                  CommandsTempBuffer[6 + i] := Chr(Ord(Msg[i]));
                  end;

               CommandsTempBuffer[7 + len] := ICOM_END_OF_MESSAGE_CODE;
               if Self.active then
                  begin
                  if InactiveRadioPtr.CWByCAT_Sending then
                     begin
                     InactiveRadioPtr.StopSendingCW;
                     DEBUGMSG('Stopping Sending in SendCW - Inactive');
                     end;
                  end
               else // Inactive
                  begin
                  if ActiveRadioPtr.CWByCAT_Sending then
                     begin
                     ActiveRadioPtr.StopSendingCW;
                     DEBUGMSG('Stopping Sending in SendCW - ACTIVE');
                     end;
                  end;
               DebugMsg('SendCW for Icom, len = ' + IntToStr(len));
               AddCommandToBuffer;
               Self.CWByCAT_Sending := true;
               DebugMsg('Self.CWByCAT_Sending set to TRUE - Icom');
               CWByCATBuffer := '';
               end
            else
               begin // Add to CWBYCATBuffer
               CWByCATBuffer := CWByCATBuffer + Msg;    // ny4i 4.44.5
               end;
            end;
         end;
      rtOrion:
         begin
         localMsg := Format('/%s#13', [Msg]);   // ny4i Issue 112
         WriteToCATPort(localMsg, length(localMsg));
         Self.CWByCAT_Sending := true;
         DebugMsg('Self.CWByCAT_Sending set to TRUE - Orion');
         end;
      else
         begin
         end;
      end;
end;
//------------------------------------------------------------------------------
procedure RadioObject.StopSendingCW;
var
   localMsg: string;
begin
   case RadioParametersArray[RadioModel].rt of
      rtKenwood:
         begin
         // localMsg := Format('KY %s;', [Msg]);
         case RadioModel of
            K2, K3:
               begin
               AddToOutputBuffer('RX;', 3);
               end;
            TS480, TS570, TS590, TS950, TS990, TS2000, TS850:
               begin
               AddToOutputBuffer('KY0;', 4);
               AddToOutputBuffer('RX;', 3);
               end;
            FLEX:
               begin
               AddToOutputBuffer('ZZSS;', 5);
               end; // PowerSDR command-no Kenwood equivilent
            end; // case RadioModel
         end;
      rtYaesu1:
         begin
         if RadioModel in [FT100, FT920, FT1000, FT1000MP] then
            begin
            ;
            end;
         end;

      rtIcom:
         begin   // This was missing for Icom ny4i Issue 100 4.45.4
         if RadioModel in RadioSupportsCWByCAT then     // ny4i
            begin
            CommandsTempBuffer[0] := CHR(8);
            // Number of items used in this array for command ny4i Issue 100 4.45.4
            CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[3] := CHR(ReceiverAddress);
            CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
            CommandsTempBuffer[5] := ICOM_SEND_CW;
            CommandsTempBuffer[6] := CHR(255);
            // Sorta documented in Icom manuals. FF in the subcode terminates CW (trial and error) ny4i
            CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;
            AddCommandToBuffer;
            end;
         end;
      rtOrion:
         begin
         //i := Format(tOrionFreq, '*CS%02u'#13, speed);
         //WriteToCATPort(tOrionFreq, i);
         end;
      else
         begin
         end;
      end;
end;
//------------------------------------------------------------------------------
procedure RadioObject.SetUpRadioInterface;
var
   hand: HWND;
   TempCardinal: cardinal;
   dwFlagsAndAttributes: DWORD;
   EvtChar: char;
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
      if RadioModel in [KenwoodRadios, K2, K3] then
         begin
         dwFlagsAndAttributes := FILE_FLAG_OVERLAPPED;
         EvtChar := ';';
         end;
{$IFEND}

      hand := CPUKeyer.SerialPortConfigured_Handle[tCATPortType];
      if hand = INVALID_HANDLE_VALUE then
         begin
         hand := InitializeSerialPort(tCATPortType, RadioBaudRate, RadioNumberBits,
            RadioParity, RadioStopBits, dwFlagsAndAttributes, EvtChar);
         end;
      GetMem(TimeoutBuffer, sizeof(COMMTIMEOUTS));

      GetCommTimeouts(hand, TimeoutBuffer^);
      TimeoutBuffer.ReadIntervalTimeout := 3;
      TimeoutBuffer.ReadTotalTimeoutMultiplier := 3;
      TimeoutBuffer.ReadTotalTimeoutConstant := 2;
      TimeoutBuffer.WriteTotalTimeoutMultiplier := 3;
      TimeoutBuffer.WriteTotalTimeoutConstant := 2;
      SetCommTimeouts(hand, TimeoutBuffer^);

      FreeMem(TimeoutBuffer, sizeof(COMMTIMEOUTS));
{$IF MASKEVENT}

      if RadioModel in [KenwoodRadios, K2, K3, Orion] then
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

         if tr4w_cat_dtr_state = RtsDtr_ON then
            begin
            TREscapeCommFunction(hand, SETDTR);
            end;
         if tr4w_cat_dtr_state = RtsDtr_OFF then
            begin
            TREscapeCommFunction(hand, CLRDTR);
            end;
         if tr4w_cat_rts_state = RtsDtr_ON then
            begin
            TREscapeCommFunction(hand, SETRTS);
            end;
         if tr4w_cat_rts_state = RtsDtr_OFF then
            begin
            TREscapeCommFunction(hand, CLRRTS);
            end;

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

//------------------------------------------------------------------------------
procedure RadioObject.SetRadioCWSpeed(speed: longint);
var
   i: integer;
begin
   if not (RadioModel in RadioSupportsCWSpeedSync) then
      begin
      DebugMsg('Current radio model does not support CWSpeedSync');
      exit;
      end;

   case RadioParametersArray[RadioModel].rt of
      rtKenwood:
         begin
         // Format(@tKenwood14Bytes, 'KS%003u;', speed);
         // AddToOutputBuffer (tKenwood14Bytes, 6);
         Format(@tKenwood14Bytes, 'KS%003u;', speed);
         AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 6);
         end;
      rtYaesu2:  // Yaesu1 does not support this command
         begin
         Format(@tKenwood14Bytes, 'KS%003u;', speed);
         AddToOutputBuffer(tKenwood14Bytes, 6);
         end;
      rtIcom:
         begin
         if (True) or (RadioModel in [IC7800, IC7850, IC7851]) then
            // ny4i 4.45.2. This looks odd because the 7800..7851 calculate speed differently but I have not added this yet. When added, just remove this if so we try this for all Icom radios.
            begin
            // Calculate Icom speed of WPM to 000-255.
            //001 = 6wpm, 254 = 48 wpm. Each extra wpm is 6 decimal higher
            //Speed (in icom decimal) = ((speed(wpm) * (42/255)) + 6)

            //speed := ((icom_dec_value * (42/255) + 6)
            // icom_dec_value = (speed - 6) * 255/42);

            CommandsTempBuffer[0] := CHR(10);
            CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[3] := CHR(ReceiverAddress);
            CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
            CommandsTempBuffer[5] := ICOM_SET_SLIDERS;
            CommandsTempBuffer[6] := ICOM_SET_CW_SPEED;
            i := Round((speed - 6) * (255 / 42));
            CommandsTempBuffer[7] := Chr(i div 100);  // Puts 00,01 or 02 into first byte
            i := i mod 100; // remove the hundreds part and BCD the remainder
            //AddStringToTelnetConsole(PChar('dec='+IntToStr(i) + ', bcd = ' + IntToStr(IntegerToBCD(i))),tstAlert);
            //AddStringToTelnetConsole(PChar('bcd='+IntToStr(n)),tstAlert);
            CommandsTempBuffer[8] := CHR(IntegerToBCD(i));
            // 20 wpm returns 85 which in BCD makes 131 which makes hex 85 when used with Chr()
            CommandsTempBuffer[9] := ICOM_END_OF_MESSAGE_CODE;

            AddCommandToBuffer;
            end;
         end;
      rtOrion:
         begin
         i := Format(tOrionFreq, '*CS%02u'#13, speed);
         WriteToCATPort(tOrionFreq, i);
         end;
      else
         begin
         end;
      end;
end;
//------------------------------------------------------------------------------
procedure RadioObject.SetRadioFreq(Freq: longint; Mode: ModeType; VFO: char);

var
   FreqStr: Str20;
   CharPointer: integer;
   i: integer;
   SendByte, TempByte: byte;
   TempChar: char;
   lpNumberOfBytesWritten: cardinal;
   VFOByte: byte;
   p: PChar;
   tempFilterWidth: integer;
const
   FT847ModeString = CHR(0) + CHR(0) + CHR(0) + CHR(7);

begin
   // TLogger.GetInstance.Debug(SysUtils.Format('[Enter SetRadioFreq] %s - set frequency to %u',[RadioName,freq]));
      try
      case RadioParametersArray[RadioModel].rt of
         rtYaesu1:
            begin

            { Select VFO B on the radio }
            if RadioModel in [FT890, FT990] then
               begin
               if VFO = 'B' then
                  begin
                  ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
                  tYaesuMode5Bytes[3] := $01;
                  tYaesuMode5Bytes[4] := $05;
                  WriteToCATPort(tYaesuMode5Bytes, 5);
                  end;
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
               if Mode = Phone then
                  begin
                  TempByte := RadioParametersArray[RadioModel].LSB;
                  end;
               if Mode = Digital then
                  begin
                  TempByte := RadioParametersArray[RadioModel].DIGL;
                  end;
               end
            else
               begin
               if Mode = Phone then
                  begin
                  TempByte := RadioParametersArray[RadioModel].USB;
                  end;
               if Mode = Digital then
                  begin
                  TempByte := RadioParametersArray[RadioModel].DIGU;
                  end;
               end;

            if Mode = CW then
               begin
               TempByte := RadioParametersArray[RadioModel].CW;

               if RadioModel in [FT100, FT817, FT847, FT857, FT897, FT920, FT1000MP] then
                  begin
                  if FT1000MPCWReverse then
                     begin
                     TempByte := $03;
                     end else
                     begin
                     TempByte := $02;
                     end;
                  end;

               if RadioModel in [FT747GX, FT840, FT890, FT900, FT990, FT1000] then
                  begin
                  if WideCWFilter then
                     begin
                     TempByte := $02;
                     end else
                     begin
                     TempByte := $03;
                     end;
                  end;
               end;

            if VFO = 'B' then
               begin
               if RadioModel in [FT1000, FT1000MP, FT920] then
                  begin
                  Inc(TempByte, $80);
                  end;
               end;

            tYaesuMode5Bytes[RadioParametersArray[RadioModel].mb] := TempByte;
            if RadioModel in [FT857, FT897] then
               begin
               tYaesuSendMode := True;
               end else
               begin
               WriteToCATPort(tYaesuMode5Bytes, 5);
               end;

            Sleep(100);

            {Set Freq}
            FreqToBCD(Freq, boolean(RadioParametersArray[RadioModel].SW),
               RadioParametersArray[RadioModel].SFOC);

            if VFO = 'B' then
               begin
               if RadioModel in [FT1000, FT1000MP, FT920] then
                  begin
                  Inc(tYaesuFreq5Bytes[4], $80);
                  end;
               end;

            if RadioModel in [FT857, FT897] then
               begin
               tYaesuSendFreq := True;
               end else
               begin
               WriteToCATPort(tYaesuFreq5Bytes, 5);
               end;

            {set VFOA}
            if RadioModel in [FT100, FT920, FT1000, FT1000MP] then
               begin
               if VFO = 'A' then
                  begin
                  ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
                  tYaesuMode5Bytes[4] := $05;
                  WriteToCATPort(tYaesuMode5Bytes, 5);
                  end;
               end;

            { Put radio back on VFO A }
            if RadioModel in [FT890, FT990] then
               begin
               if VFO = 'B' then
                  begin
                  ZeroMemory(@tYaesuMode5Bytes, SizeOf(tYaesuMode5Bytes));
                  tYaesuMode5Bytes[4] := $05;
                  WriteToCATPort(tYaesuMode5Bytes, 5);
                  end;
               end;

            end;

         rtYaesu2:
            begin
            Format(@tKenwood14Bytes, 'FA%08u;', Freq);
            tKenwood14Bytes[1] := VFO;
            WriteToCATPort(tKenwood14Bytes, 11);

            if Freq < 10000000 then
               begin
               if Mode = Phone then
                  begin
                  TempChar := '1';
                  end; { LSB }
               if Mode = Digital then
                  begin
                  TempChar := '6';
                  end; { RTTY-LSB }
               if Mode = CW then
                  begin
                  TempChar := '3';
                  end {'7'};
               end
            else
               begin
               if Mode = Phone then
                  begin
                  TempChar := '2';
                  end; { USB }
               if Mode = Digital then
                  begin
                  TempChar := '9';
                  end; { RTTY-USB }
               if Mode = CW then
                  begin
                  TempChar := '3';
                  end;
               if Mode = FM then
                  begin
                  TempChar := '4';
                  end;
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
            // TLogger.GetInstance.Debug('In Kenwood code');
            Format(@tKenwood14Bytes, 'FA%011u;', Freq);
            tKenwood14Bytes[1] := VFO;
            AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 14);

            if VFO = 'B' then
               begin
               AddToOutputBuffer {WriteToCATPort}('FR1;FT1;', 8);
               end; //temporary active vfo is vfo b for set mode

            case Mode of
               CW:
                  begin
                  TempByte := Ord('3');
                  end;
               Digital:
                  begin
                  TempByte := Ord('6');
                  end;
               FM:
                  begin
                  TempByte := Ord('4');
                  end;

               else { SSB }
                  begin
                  if Freq < 10000000 then
                     begin
                     TempByte := Ord('1');
                     end { LSB }
                  else
                     begin
                     TempByte := Ord('2');
                     end;
                  end; { USB }
               end;
            tKenwood14Bytes[0] := 'M';
            tKenwood14Bytes[1] := 'D';
            tKenwood14Bytes[2] := CHR(TempByte);
            tKenwood14Bytes[3] := ';';
            AddToOutputBuffer {WriteToCATPort}(tKenwood14Bytes, 4);

            if (VFO = 'B') then
               begin
               AddToOutputBuffer {WriteToCATPort}('FR0;FT0;', 8);
               end; //back to vfo a
            // TLogger.GetInstance.Debug('Leaving Kenwood code');
            end;
         end;

      case RadioModel of

         IC78..IC9100, OMNI6: {KK1L: 6.73 Added OMNI6}
            begin
            // TLogger.GetInstance.Debug('In Icom radio code');
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
            // TLogger.GetInstance.Debug('Sending Icom mode information');
            if Mode = FM then
               begin
               TempChar := #5;
               end else
               if Mode = CW then
                  begin
                  TempChar := #3;
                  end else
                  if Mode = Digital then
                     begin
                     TempChar := #4;
                     end else
                  //must be phone
                     if Freq < 10000000 then
                        begin
                        TempChar := #0;
                        end else
                        begin
                        TempChar := #1;
                        end;
            // TLogger.GetInstance.Debug(Format('Sending Icom mode information - %u',[Ord(Mode)]));
            CommandsTempBuffer[0] := CHR(9);
            CommandsTempBuffer[1] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[2] := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[3] := CHR(ReceiverAddress);
            CommandsTempBuffer[4] := ICOM_CONTROLLER_ADDRESS;
            CommandsTempBuffer[5] := ICOM_SET_MODE;
            CommandsTempBuffer[6] := TempChar;

            // ny4i: I'm trying to understand this logic   // 4.43.4
            // The way Dave indicated this is supposed to work is that
            // if the CFG option of ICOM_FILTER_BYTE is set to 0, then we want to send
            // whatever the filter setting the rig had.
            // If the value is 1, 2 or 3, then we want to send that when we change
            // mode.
            // tIcomFilterWidth is the value from the CFG file
            //     if Mode = Phone then  CommandsTempBuffer[7] := CHR(tIcomFilterWidth);
            if (RadioModel = OMNI6) and (Mode = CW) then      // n4af 4.43.3
               begin
               CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;   // n4af 4.43.3
               end
            else
               begin // ny4i 4.43.6
               case tIcomFilterWidth of             // Not set in CFG so send current value
                  0:
                     begin
                     //IcomCheckBuffer(ActiveRadioPtr);  // n4af 4.34.4 get icom pb filter setting
                     if Icom_Filter_Width > 0 then
                        // this is the module global stored fromthe rig message in uRadioPolling
                        begin
                        tempFilterWidth := Icom_Filter_Width;  // n4af 4.43.4    tIcomFilterWidth
                        end
                     else
                        begin
                        tempFilterWidth := 1;
                        // Default to 1 if no CFG set and we do not have a value from the radio. We cannot send 0 to some radios as they reject the command. Others handle the zero though.
                        end;
                     end;
                  1..3:
                     begin
                     tempFilterWidth := tIcomFilterWidth;
                     end
                  else
                     begin
                     tempFilterWIdth := 0;
                     end;
                  end; // case
               CommandsTempBuffer[7] := CHR(tempFilterWidth);
               // ny4i // n4af 4.43.4  set icom filter
               CommandsTempBuffer[8] := ICOM_END_OF_MESSAGE_CODE;
               end;

         {if (Mode <> CW) or (tIcomFilterWidth = 0) then  // This rejects all of the above - comment for now and test
          begin
          CommandsTempBuffer[0] := CHR(8);
          CommandsTempBuffer[7] := ICOM_END_OF_MESSAGE_CODE;

         end;
         }

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
 g1704
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

            CommandsTempBuffer[0]  := CHR(12);
            CommandsTempBuffer[1]  := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[2]  := ICOM_PREAMBLE_CODE;
            CommandsTempBuffer[3]  := CHR(ReceiverAddress);
            CommandsTempBuffer[4]  := ICOM_CONTROLLER_ADDRESS;
            CommandsTempBuffer[5]  := ICOM_SET_FREQ;
            CommandsTempBuffer[11] := ICOM_END_OF_MESSAGE_CODE;

            Format(wsprintfBuffer, '%10.10u', Freq);
            i := 5;
            for CharPointer := 9 downto 0 do
               begin
               if not Odd(CharPointer) then
                  begin
                  Inc(i);
                  TempByte := Ord(wsprintfBuffer[CharPointer]) - $30;
                  SendByte := SendByte or (TempByte shl 4);
                  CommandsTempBuffer[i] := CHR(SendByte);
                  end
               else
                  begin
                  SendByte := Ord(wsprintfBuffer[CharPointer]) - $30;
                  end;
               end;

            if RadioModel = IC735 then
               begin
               CommandsTempBuffer[0]  := CHR(11);
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

//         Put radio in remote                                           3
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
            i := Format(tOrionFreq, '*AF%02u.%05u'#13, Freq div 1000000,
               (Freq div 10) mod 100000);
            //        asm push freq  end;
            //        i := wsprintf(@tKenwood14Bytes, '*AF%u'#13);
            //        asm add esp,12 end;
            tOrionFreq[1] := VFO;
            //        WriteToCATPort(tOrionFreq, i);

            case Mode of
               CW:
                  begin
                  if FT1000MPCWReverse then
                     begin
                     TempChar := '3';
                     end //  WriteToCATPort('*RMM3'#13, 6)
                  else
                     begin
                     TempChar := '2';
                     end;
                  end; //WriteToCATPort('*RMM2'#13, 6);
               Phone:
                  begin
                  if Freq < 10000000 then
                     begin
                     TempChar := '1';
                     end //WriteToCATPort('*RMM1'#13, 6)
                  else
                     begin
                     TempChar := '0';
                     end;
                  end; //WriteToCATPort('*RMM0'#13, 6);
               FM:
                  begin
                  TempChar := '5';
                  end; //WriteToCATPort('*RMM5'#13, 6);
               end;
            Windows.ZeroMemory(@tOrionMode, SizeOf(tOrionMode));
            Windows.lstrcat(tOrionMode, '*RMM?'#13);
            tOrionMode[4] := TempChar;
            if VFO = 'B' then
               begin
               tOrionMode[2] := 'S';
               end;
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
      except //on E : Exception do
      ; // TLogger.GetInstance.Debug(Format('In SetRadioFreq, %s error raised, with message <%s> ',[E.ClassName,E.Message]));
      end;
   //TLogger.GetInstance.Debug(SysUtils.Format('[Exit SetRadioFreq] %s',[RadioName]));
end;

procedure RadioObject.UpdateBandOutputInfo(Band: BandType; Mode: ModeType);

begin
   if BandOutputPort <> NoPort then
      begin
      OutputBandInfo(tBandOutputPortBaseAddress {BandOutputPort}, Band, Mode);
      end;
end;

function GenerateStatusString(var StatusRecord: RadioStatusRecord): Str80;

{ This function will generate a string with the complete status of a
  RadioStatusRecord. }

var
   StatusString, TempString: string;
   TempValue: real;

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
         begin
         StatusString := StatusString + 'Split      ';
         end
      else
         begin
         StatusString := StatusString + 'Transceive ';
         end;

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

   Result := StatusString;
end;

procedure TestRadioInterface;

{ This procedure will display the data coming back from the interfaced
  radios }

var
   RadioOneLastDisplayedCurrentStatus:  Str80;
   RadioOneLastDisplayedPreviousStatus: Str80;
   RadioOneLastDisplayedFilteredStatus: Str80;

   RadioTwoLastDisplayedCurrentStatus:  Str80;
   RadioTwoLastDisplayedPreviousStatus: Str80;
   RadioTwoLastDisplayedFilteredStatus: Str80;

   TempStatusString: Str80;
   TempValue: real;

begin
   //{WLI}    Window (1, 1, 80, 25);

   //{WLI}    TextBackground (Black);
   //{WLI}    NoCursor;

   ShowMessage('TEST RADIO INTERFACE');

   //{WLI}    WriteLn ('This procedure will display the data coming back from the interfaced radios');
   //{WLI}    WriteLn ('Press the ESCAPE key to exit and halt TR.');
   //{WLI}    WriteLn;

   RadioOneLastDisplayedCurrentStatus  := '';
   RadioOneLastDisplayedPreviousStatus := '';
   RadioOneLastDisplayedFilteredStatus := '';

   RadioTwoLastDisplayedCurrentStatus  := '';
   RadioTwoLastDisplayedPreviousStatus := '';
   RadioTwoLastDisplayedFilteredStatus := '';

  {    GoToXY (1, 6);
      Writeln ('Latest Radio One Status');
     GoToXY (1, 9);
      Writeln ('Previous Radio One Previous Status');
     GoToXY (1, 12);
      Write ('Filtered Radio One Status (gets updated when Previous = Latest)');
      GoToXY (1, 15);
      Write ('Latest Radio Two Status');
      GoToXY (1, 18);
      Write ('Previous Radio Two Status');
      GoToXY (1, 21);
      Write ('Filtered Radio Two Status (gets updated when Previous = Latest)');

  repeat

    Radio1.CheckRadioStatus;

    TempStatusString := GenerateStatusString(Radio1.CurrentStatus);

    if TempStatusString <> RadioOneLastDisplayedCurrentStatus then
    begin
         //             GoToXY (1, 7);
        //
        

      RadioOneLastDisplayedCurrentStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio1.PreviousStatus);

    if TempStatusString <> RadioOneLastDisplayedPreviousStatus then
    begin
        //            GoToXY (1, 10);
        //            Write (TempStatusString);

      RadioOneLastDisplayedPreviousStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio1.FilteredStatus);

    if TempStatusString <> RadioOneLastDisplayedFilteredStatus then
    begin
        //        GoToXY (1, 13);
        //


      RadioOneLastDisplayedFilteredStatus := TempStatusString;
    end;

    Radio2.CheckRadioStatus;

    TempStatusString := GenerateStatusString(Radio2.CurrentStatus);

    if TempStatusString <> RadioTwoLastDisplayedCurrentStatus then
    begin
        //           GoToXY (1, 16);
        //            Write (TempStatusString);

      RadioTwoLastDisplayedCurrentStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio2.PreviousStatus);

    if TempStatusString <> RadioTwoLastDisplayedPreviousStatus then
    begin
        //             GoToXY (1, 19);
        //            Write (TempStatusString);
      ShowMessage (TempStatusString);
      RadioTwoLastDisplayedPreviousStatus := TempStatusString;
    end;

    TempStatusString := GenerateStatusString(Radio2.FilteredStatus);

    if TempStatusString <> RadioTwoLastDisplayedFilteredStatus then
    begin
        //             GoToXY (1, 22);
        // 
        ShowMessage (TempStatusString);

      RadioTwoLastDisplayedFilteredStatus := TempStatusString;
    end;
     

  until OperatorEscape;
  {
  CPUKeyer.UnInitializeKeyer; { Fix interrupts and close debug files }

   //{WLI}    GoToXY (1, 24);
   //{WLI}    ClrEol;
   //{WLI}    BigCursor;
   // halt;
end;

function OpenCATDebugFile(port: PortType): boolean;
var
   stored: integer;
   TempBaudRate: cardinal;
   TempPchar: PChar;
   Radio:  PChar;
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
   IntRadioType: InterfacedRadioType;
   SerialPort: PortType;
   TempString: Str80;
   WaitAnswer: cardinal;
const

   FT890PTTOn =
      CHR($00) + CHR($00) + CHR($00) + CHR($01) + CHR($0F);
   FT890PTTOff =
      CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($0F);

   FT817PTTOn =
      CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($08);
   FT817PTTOff =
      CHR($00) + CHR($00) + CHR($00) + CHR($00) + CHR($88);

begin
   WaitAnswer := 0;
   Result := False;
   if not tPTTViaCommand then
      begin
      Exit;
      end;
   if NoPollDuringPTT then
      begin
      Exit;
      end;
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
      TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850, TS870, TS940, TS950, TS990,
      TS2000, FLEX, K2, K3:
         begin
         if PTTOn then
            begin
            TempString := 'TX;';
            end else
            begin
            TempString := 'RX;';
            end;
         end;

      FT450, FT950, FT991, FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000:
         begin
         if PTTOn then
            begin
            TempString := 'TX1;';
            end else
            begin
            TempString := 'TX0;';
            end;
         end;

      FT747GX, FT100, FT840, FT890, FT900, FT990, FT1000, FT1000MP:
         begin
         if PTTOn then
            begin
            TempString := FT890PTTOn;
            end else
            begin
            TempString := FT890PTTOff;
            end;
         end;

      FT736R, FT817, FT847 {, FT857, FT897}:
         begin
         if PTTOn then
            begin
            TempString := FT817PTTOn;
            end else
            begin
            TempString := FT817PTTOff;
            end;
         end;

      FT920, FT767:
         begin
         Exit;
         end;
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
      //      IC78..IC9100, OMNI6: Exit;
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
            begin
            TempString := '*TK' + CarriageReturn;
            end
         else
            begin
            TempString := '*TU' + CarriageReturn;
            end;
         end;
      else
         begin
         Exit;
         end;
      end;

   //  CPUKeyer.AddSerialPortString(SerialPort, TempString);
   ActiveRadioPtr.WriteToCATPort(TempString[1], length(TempString));
   if WaitAnswer <> 0 then
      begin
      ReadFromCOMPort(WaitAnswer, @Radio1);
      end;
   Result := True;
end;


procedure InitRadios;
var
   TempRadio: RadioPtr;
   i: integer;
const
   ra: array[1..2] of RadioPtr = (@Radio1, @Radio2);
begin
   RadioSupportsCWByCAT := [TS850, K2, K3, TS480, TS570, TS590, TS990, TS2000,
                            FLEX, IC7100, IC7300, IC7410, IC7600, IC7700, IC7800,
                            IC7850, IC7851, IC9100, Orion];
   // ny4i Issue 119
   RadioSupportsCWSpeedSync :=
      [TS850, K2, K3, TS480, TS570, TS590, TS990, TS2000, FLEX, FT450, FT950, FT991,
      FT1200, FT2000, FTDX3000, FTDX5000, FTDX9000, IC718, IC746, IC746PRO, IC756PROII,
      IC756PROIII, IC910, IC7100, IC7200, IC7300, IC7410, IC7600, IC7700, IC7800,
      IC7850, IC7851, IC9100, Orion];  // ny4i Issue 120
   ICOMRadios := [IC78..IC9100];
   KenwoodRadios := [TS140, TS440, TS450, TS480, TS570, TS590, TS690, TS850,
                     TS870, TS940, TS950, TS990, TS2000, FLEX];
   for i := 1 to 2 do
      begin
      TempRadio := ra[i];

      TempRadio.RadioNumberBits := 8;
      TempRadio.RadioStopBits  := 2;
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
   Radio1.active := true;
   Radio2.active := false;
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
