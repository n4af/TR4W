{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref http://www.gnu.org/licenses/gpl-3.0.txt
 }
//*** TDLPortIO: DriverLINX Port IO Driver wrapper component *****************
//**                                                                        **
//** File: PortIO.pas                                                       **
//**                                                                        **
//** Copyright (c) 1999 John Pappas (DiskDude). All rights reserved.        **
//**     This software is FreeWare                                          **
//**                                                                        **
//**     Please notify me if you make any changes to this file.             **
//**     Email: diskdude@poboxes.com                                        **
//**                                                                        **
//**                                                                        **
//** The following resources helped in developing the install, start, stop  **
//** and remove code for dynamically opening/closing the DriverLINX WinNT   **
//** kernel mode driver.                                                    **
//**                                                                        **
//**   "Dynamically Loading Drivers in Windows NT" by Paula Tomlinson       **
//**   from "Windows Developer's Journal", Volume 6, Issue 5. (C code)      **
//**      ftp://ftp.mfi.com/pub/windev/1995/may95.zip                       **
//**                                                                        **
//**   "Hardware I/O Port Programming with Delphi and NT" by Graham Wideman **
//**      http://www.wideman-one.com/tech/Delphi/IOPM/index.htm             **
//**                                                                        **
//**                                                                        **
//** Special thanks to Peter Holm <comtext3@post4.tele.dk> for his          **
//** algorithm and code for detecting the number and addresses of the       **
//** installed printer ports, on which the detection code below is based.   **
//**                                                                        **
//*** http://diskdude.cjb.net/ ***********************************************

unit DLPortIO;
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  TF,
  Windows,
  WinSvc,
  Messages
  ;

type
  PByte = ^Byte;
  PWORD = ^Word;
  PLongword = ^longword;

type
  TDlPortReadPortUchar = function(port: Word): Byte; stdcall;
  TDlPortReadPortUshort = function(port: Word): Word; stdcall;
  TDlPortReadPortUlong = function(port: Word): longword; stdcall;

  TDlPortWritePortUchar = procedure(port: Word; Value: Byte); stdcall;
  TDlPortWritePortUshort = procedure(port: Word; Value: Word); stdcall;
  TDlPortWritePortUlong = procedure(port: Word; Value: longword); stdcall;

  TDlPortReadPortBufferUchar = procedure(port: Word; Buffer: PByte; Count: longword); stdcall;
  TDlPortReadPortBufferUshort = procedure(port: Word; Buffer: PWORD; Count: longword); stdcall;
  TDlPortReadPortBufferUlong = procedure(port: Word; Buffer: PLongword; Count: longword); stdcall;

  TDlPortWritePortBufferUchar = procedure(port: Word; Buffer: PByte; Count: longword); stdcall;
  TDlPortWritePortBufferUshort = procedure(port: Word; Buffer: PWORD; Count: longword); stdcall;
  TDlPortWritePortBufferUlong = procedure(port: Word; Buffer: PLongword; Count: longword); stdcall;

type
  tMode = (tmReadByte, tmReadWord, tmReadDWord, tmWriteByte, tmWriteWord, tmWriteDWord);

  // Specifies the data required to do a block
  // read/write of an array of port records.
  // Extends the model TVicHW32/TVicPort uses
type
  TPortCommand = record
    PortAddr: Word; // The address of the port to read/write
    PortData: longword; // The data to read/write
    // If a byte, only lower 8bits are used, or 16bits
    // if reading/writing a word
    PortMode: tMode; // The mode of reading/writing
  end;

  // Standard TVicHW32/TVicPort PortRec for compatibility
type
  TPortRec = record
    PortAddr: Word; // Address
    PortData: Byte; // Data (for writing or after reading)
    fWrite: boolean; // TRUE if you want to write this port
    // and FALSE if to read.
  end;

  //---------------------------------------------------------------------------
  // TDLPortIO class
  //    This is supposed to be compatible with TVicPort
  //---------------------------------------------------------------------------

  //type
  //  TDLPortIO = class
  //  private
  //    FActiveHW : Boolean;      // Is the DLL loaded?
  //    FHardAccess : Boolean;    // Not used: for compatibility only
  //    FRunningWinNT : Boolean;  // True when we're running Windows NT
var
  FDLLInst                              : THandle; // For use with DLL
  hSCMan                                : SC_HANDLE; // For use with WinNT Service Control Manager

  //    FDriverPath : AnsiString; // Full path of WinNT driver
  //    FDLLPath : AnsiString;    // Full path of DriverLINX DLL
  //    FLastError : AnsiString;  // Last error which occurred in Open/CloseDriver()

      // Used for the Windows NT version only
  FDrvPrevInst                          : boolean; // DriverLINX driver already installed?
  FDrvPrevStart                         : boolean; // DriverLINX driver already running?

  // Pointers to the functions within the DLL
  DlWriteByte                           : TDlPortWritePortUchar;
  DlReadByte                            : TDlPortReadPortUchar;
  dwStatus                              : DWORD;
  DLPORTIOlpBinaryPathName              : array[0..255] of Char;

function ConnectSCM: boolean;
procedure DisconnectSCM;

// Installs, starts, stops and removes the WinNT kernel mode driver
function DriverInstall: boolean;
function DriverStart: boolean;
function DriverStop: boolean;
function DriverRemove: boolean;

// returns true if the DLL/Driver is loaded
function IsLoaded: boolean;

// Wrappers for the properties below
function GetPortByte(Address: Word): Byte;
procedure SetPortByte(Address: Word; data: Byte);
procedure CreateDlPortio;
procedure DestroyDlPortio;
function OpenDriver: boolean;
procedure CloseDriver;
procedure PortControl(Ports: array of TPortRec; NumPorts: Word);
procedure PortCommand(Ports: array of TPortCommand; NumPorts: Word);

procedure NoDLPortioMessage;
// Access any port as you like, similar to the old pascal way of doing things
//property port[Address: Word]: Byte read GetPortByte write SetPortByte;
//property PortW[Address: Word]: Word read GetPortWord write SetPortWord;
//property PortL[Address: Word]: Longword read GetPortDWord write SetPortDWord;

// Sets the path (no ending \, nor any filename) of the DLPortIO.SYS file
// Assumed to be <windows system directory>\DRIVERS if not specified
//    property DriverPath : AnsiString read FDriverPath write FDriverPath;

// Sets the path (no ending \, nor any filename) of the DLPortIO.DLL file
// Assumed to be "" if not specified, meaning it will search the program
// path, windows directory and computer's path for the DLL
//    property DLLPath : AnsiString read FDLLPath write FDLLPath;

// True when the DLL/Driver has been loaded successfully after OpenDriver()
//    property ActiveHW : Boolean read FActiveHW;
// This doesn't really do anything; provided for compatibility only
//    property HardAccess : Boolean read FHardAccess write FHardAccess default true;

// Returns the last error which occurred in Open/CloseDriver()
//    property LastError : AnsiString read FLastError;
//  end;

//---------------------------------------------------------------------------
// Types for the TDLPrinterPortIO class
//---------------------------------------------------------------------------

type
  TPinNumber = 1..25;

  //---------------------------------------------------------------------------
  // TDLPrinterPortIO class
  //    This is supposed to be compatible with TVicLPT
  //---------------------------------------------------------------------------

var
  FRunningWinNT                         : boolean; // True when we're running Windows NT
//  FDriverPath                           : AnsiString; // Full path of WinNT driver
//  FDLLPath                              : AnsiString; // Full path of DriverLINX DLL
  FActiveHW                             : boolean; // Is the DLL loaded?
//  FHardAccess                           : boolean; // Not used: for compatibility only
  FLastError                            : PChar; // Last error which occurred in Open/CloseDriver()

const
  MAX_LPT_PORTS                         = 8;

  BIT0                                  : Byte = $01;
  BIT1                                  : Byte = $02;
  BIT2                                  : Byte = $04;
  BIT3                                  : Byte = $08;
  BIT4                                  : Byte = $10;
  BIT5                                  : Byte = $20;
  BIT6                                  : Byte = $40;
  BIT7                                  : Byte = $80;

  // Printer Port pin numbers
  ACK_PIN                               : Byte = 10;
  BUSY_PIN                              : Byte = 11;
  PAPEREND_PIN                          : Byte = 12;
  SELECTOUT_PIN                         : Byte = 13;
  ERROR_PIN                             : Byte = 15;
  STROBE_PIN                            : Byte = 1;
  AUTOFD_PIN                            : Byte = 14;
  INIT_PIN                              : Byte = 16;
  SELECTIN_PIN                          : Byte = 17;

  LIBRARY_FILENAME                      = 'DLPORTIO.DLL';
  DRIVER_NAME                           = 'DLPortIO';
  DISPLAY_NAME                          = 'DriverLINX Port I/O Driver';
  DRIVER_GROUP                          = 'SST miniport drivers';

  SERVICE_KERNEL_DRIVER                 = $00001;
  SERVICE_CONTROL_STOP                  = $00001;
  SERVICE_ERROR_NORMAL                  = $00001;
  SERVICE_DEMAND_START                  = $00003;
  SERVICE_STOPPED                       = $00001;
  SERVICE_RUNNING                       = $00004;
  SERVICE_QUERY_STATUS                  = $00004;
  SERVICE_START                         = $00010;
  SERVICE_STOP                          = $00020;

  DLPIODelete                           = $10000;

  SC_MANAGER_CONNECT                    = $0001;
  SC_MANAGER_CREATE_SERVICE             = $0002;
  SC_MANAGER_ENUMERATE_SERVICE          = $0004;
  SC_MANAGER_QUERY_LOCK_STATUS          = $0010;
  ERROR_ACCESS_DENIED                   = $0005;

implementation
uses MainUnit;

procedure CreateDlPortio;
var
//  os                                    : TOSVERSIONINFO;
  Buffer                                : array[1..MAX_PATH] of Char;
  I                                     : integer;
begin
  //   inherited Create(Owner); // Set up our inherited methods, and properties

     // Are we running Windows NT?
  {
    os.dwPlatformId := 0;
    os.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
    GetVersionex(os);
  }
  FRunningWinNT := (WindowsOSversion {os.dwPlatformId} = VER_PLATFORM_WIN32_NT);
  GetSystemDirectory(DLPORTIOlpBinaryPathName, SizeOf(DLPORTIOlpBinaryPathName));
  Windows.lstrcat(DLPORTIOlpBinaryPathName, '\DRIVERS\DLPORTIO.SYS');
end;

procedure DestroyDlPortio;
begin
  if (IsLoaded) then CloseDriver;
end;

function ConnectSCM: boolean;

var
  scAccess                              : DWORD;
begin
  dwStatus := 0; // Assume success, until we prove otherwise

  // Try and connect as administrator
  scAccess := SC_MANAGER_CONNECT or
    SC_MANAGER_QUERY_LOCK_STATUS or
    SC_MANAGER_ENUMERATE_SERVICE or
    SC_MANAGER_CREATE_SERVICE; // Admin only

  // Connect to the SCM
  hSCMan := OpenSCManager(nil, nil, scAccess);

  // If we're not in administrator mode, try and reconnect
  if ((hSCMan = 0) and (GetLastError = ERROR_ACCESS_DENIED)) then
  begin
    scAccess := SC_MANAGER_CONNECT or
      SC_MANAGER_QUERY_LOCK_STATUS or
      SC_MANAGER_ENUMERATE_SERVICE;

      // Connect to the SCM
    hSCMan := OpenSCManager(nil, nil, scAccess);
  end;

  if (hSCMan = 0) then
  begin
    dwStatus := GetLastError;
    FLastError := 'ConnectSCM';
  end;

  RESULT := (dwStatus = 0); // Success == 0
end;

//---------------------------------------------------------------------------
// Disconnects from the WinNT Service Control Manager

procedure DisconnectSCM;
//---------------------------------------------------------------------------
begin
  if (hSCMan <> 0) then
  begin
      // Disconnect from our local Service Control Manager
    CloseServiceHandle(hSCMan);
    hSCMan := 0;
  end;
end;

//---------------------------------------------------------------------------
// Installs, starts, stops and removes the WinNT kernel mode driver

function DriverInstall: boolean;
//---------------------------------------------------------------------------

var
  hService                              : SC_HANDLE; // Handle to the new service
begin
  dwStatus := 0; // Assume success, until we prove otherwise

  FDrvPrevInst := False; // Assume the driver wasn't installed previously

  hService := OpenService(hSCMan, DRIVER_NAME, SERVICE_QUERY_STATUS);
  if (hService <> 0) then
  begin
    FDrvPrevInst := True; // Driver previously installed, don't remove
    CloseServiceHandle(hService); // Close the service
    RESULT := True; // Success
    Exit;
  end;

  // Add to our Service Control Manager's database
  hService := CreateService(
    hSCMan,
    DRIVER_NAME,
    DISPLAY_NAME,
    SERVICE_START or SERVICE_STOP or DLPIODelete or SERVICE_QUERY_STATUS,
    SERVICE_KERNEL_DRIVER,
    SERVICE_DEMAND_START,
    SERVICE_ERROR_NORMAL,
    DLPORTIOlpBinaryPathName,
    DRIVER_GROUP,
    nil, nil, nil, nil);

  if (hService = 0) then
    dwStatus := GetLastError
  else
    CloseServiceHandle(hService);

  if (dwStatus <> 0) then FLastError := 'DriverInstall';

  RESULT := (dwStatus = 0);
end;

function DriverStart: boolean;

var
  hService                              : SC_HANDLE; // Handle to the new service
  lpServiceArgVectors                   : PChar;
  sStatus                               : TServiceStatus;
begin
  dwStatus := 0; // Assume success, until we prove otherwise

  FDrvPrevStart := False; // Assume the driver was not already running

  hService := OpenService(hSCMan, DRIVER_NAME, SERVICE_QUERY_STATUS);
  if ((hService <> 0) and (QueryServiceStatus(hService, sStatus))) then
  begin
      // Got the service status, now check it
    if (sStatus.dwCurrentState = SERVICE_RUNNING) then
    begin
      FDrvPrevStart := True; // Driver was previously started
      CloseServiceHandle(hService); // Close service
      RESULT := True; // Success
      Exit;
    end
    else if (sStatus.dwCurrentState = SERVICE_STOPPED) then
    begin
          // Driver was stopped. Start the driver.
      CloseServiceHandle(hService);
      hService := OpenService(hSCMan, DRIVER_NAME, SERVICE_START);
      if (not StartService(hService, 0, lpServiceArgVectors)) then
        dwStatus := GetLastError;
      CloseServiceHandle(hService); // Close service
    end
    else dwStatus := $FFFFFFFF; // Can't run the service
  end
  else
    dwStatus := GetLastError;

  if (dwStatus <> 0) then FLastError := 'DriverStart';

  RESULT := (dwStatus = 0); // Success == 0
end;

function DriverStop: boolean;
var
  hService                              : SC_HANDLE; // Handle to the new service
  temp                                  : LongBool;
  ServiceStatus                         : TServiceStatus;
begin
  dwStatus := 0; // Assume success, until we prove otherwise

  // If we didn't start the driver, then don't stop it.
  // Pretend we stopped it, by indicating success.
  if (FDrvPrevStart) then
  begin
    RESULT := True;
    Exit;
  end;

  // Get a handle to the service to stop
  hService := OpenService(hSCMan, DRIVER_NAME, SERVICE_STOP or SERVICE_QUERY_STATUS);

  if (hService <> 0) then
  begin
      // Stop the driver, then close the service
    temp := ControlService(hService, SERVICE_CONTROL_STOP, ServiceStatus);
    if (not temp) then
      dwStatus := GetLastError();
    CloseServiceHandle(hService);
  end else
    dwStatus := GetLastError;

  if (dwStatus <> 0) then FLastError := 'DriverStop';
  RESULT := (dwStatus = 0); // Success == 0
end;

function DriverRemove: boolean;
var
  hService                              : SC_HANDLE; // Handle to the new service
  temp                                  : LongBool;
begin
  dwStatus := 0; // Assume success, until we prove otherwise

  // If we didn't install the driver, then don't remove it.
  // Pretend we removed it, by indicating success.
  if (FDrvPrevInst) then
  begin
    RESULT := True;
    Exit;
  end;

  // Get a handle to the service to stop
  hService := OpenService(hSCMan, DRIVER_NAME, DLPIODelete);

  if (hService <> 0) then
  begin
    temp := DeleteService(hService);
    if (not temp) then dwStatus := GetLastError;
    CloseServiceHandle(hService);
  end
  else
    dwStatus := GetLastError;

  if (dwStatus <> 0) then FLastError := 'DriverRemove';

  RESULT := (dwStatus = 0);
end;

function IsLoaded: boolean;
begin
  RESULT := FActiveHW;
end;

function GetPortByte(Address: Word): Byte;
begin
  RESULT := DlReadByte(Address);
end;

procedure SetPortByte(Address: Word; data: Byte);
begin
  DlWriteByte(Address, data);
end;

function OpenDriver: boolean;
begin

  // If the DLL/driver is already open, then forget it!
  RESULT := True;
  if (IsLoaded) then Exit;
  CreateDlPortio;

  // If we're running Windows NT, install the driver then start it
  if (FRunningWinNT) then
  begin
      // Connect to the Service Control Manager
    if (not ConnectSCM) then Exit;

      // Install the driver
    if (not DriverInstall) then
    begin
          // Driver install failed, so disconnect from the SCM
      DisconnectSCM;
      RESULT := False;
      Exit;
    end;

      // Start the driver
    if (not DriverStart) then
    begin
          // Driver start failed, so remove it then disconnect from SCM
      DriverRemove;
      DisconnectSCM;
          //      Exit;
      NoDLPortioMessage;
    end;
  end;

  // Load DLL library
//  LibraryFileName := LIBRARY_FILENAME;

//  if (FDLLPath <> '') then
//  LibraryFileName := FDLLPath + '\' + LIBRARY_FILENAME;

  FDLLInst := LoadLibrary(LIBRARY_FILENAME);
  if (FDLLInst <> 0) then
  begin
    @DlReadByte := GetProcAddress(FDLLInst, 'DlPortReadPortUchar');
    @DlWriteByte := GetProcAddress(FDLLInst, 'DlPortWritePortUchar');

      // Make sure all our functions are there
    if ((@DlReadByte <> nil) and (@DlWriteByte <> nil)) then FActiveHW := True;
  end;

  // Did we fail?
  if (not FActiveHW) then
  begin
      // If we're running Windows NT, stop the driver then remove it
      // Forget about any return (error) values we might get...
    if (FRunningWinNT) then
    begin
      DriverStop;
      DriverRemove;
      DisconnectSCM;
    end;

      // Free the library
    if (FDLLInst <> 0) then
    begin
      FreeLibrary(FDLLInst);
      FDLLInst := 0;
    end;
    FLastError := 'OpenDriver';
    dwStatus := GetLastError;
    NoDLPortioMessage;

  end;
end;

procedure CloseDriver;
begin
  // Don't close anything if it wasn't opened previously
  if (not IsLoaded) then Exit;

  // If we're running Windows NT, stop the driver then remove it
  if (FRunningWinNT) then
  begin
    if (not DriverStop) then Exit;
    if (not DriverRemove) then Exit;
    DisconnectSCM;
  end;

  // Free the library
  if (not FreeLibrary(FDLLInst)) then Exit;
  FDLLInst := 0;

  FActiveHW := False; // Success
end;

procedure PortControl(Ports: array of TPortRec; NumPorts: Word);
var
  Index                                 : Word;
begin
  for Index := 1 to NumPorts do
    if (Ports[Index].fWrite) then
      DlWriteByte(Ports[Index].PortAddr, Ports[Index].PortData)
    else
      Ports[Index].PortData := DlReadByte(Ports[Index].PortAddr);
end;

procedure PortCommand(Ports: array of TPortCommand; NumPorts: Word);
var
  Index                                 : Word;
begin
  for Index := 1 to NumPorts do
    case (Ports[Index].PortMode) of
      tmReadByte: Ports[Index].PortData := DlReadByte(Ports[Index].PortAddr);
      //      tmReadWord: Ports[Index].PortData := DlReadWord(Ports[Index].PortAddr);
      //      tmReadDWord: Ports[Index].PortData := DlReadDWord(Ports[Index].PortAddr);
      tmWriteByte: DlWriteByte(Ports[Index].PortAddr, Ports[Index].PortData);
      //      tmWriteWord: DlWriteWord(Ports[Index].PortAddr, Ports[Index].PortData);
      //      tmWriteDWord: DlWriteDWord(Ports[Index].PortAddr, Ports[Index].PortData);
    end;
end;

procedure NoDLPortioMessage;
begin;
  asm
  push dwStatus
  call SysErrorMessage
  push eax
  push FLastError
  end;
  wsprintf(wsprintfBuffer, TC_DLPORTIODRIVERISNOTINSTALLED + ': %s: %s');
  asm add esp,16
  end;
  showwarning(wsprintfBuffer);
  halt;
end;

end.
{
procedure TDLPrinterPortIO.SetPin(Index: TPinNumber; State: boolean);
begin
  if (State) then
    begin
      case Index of
        1: port[FLPTBase + 2] := port[FLPTBase + 2] and (not BIT0); // Inverted
        2: port[FLPTBase] := port[FLPTBase] or BIT0;
        3: port[FLPTBase] := port[FLPTBase] or BIT1;
        4: port[FLPTBase] := port[FLPTBase] or BIT2;
        5: port[FLPTBase] := port[FLPTBase] or BIT3;
        6: port[FLPTBase] := port[FLPTBase] or BIT4;
        7: port[FLPTBase] := port[FLPTBase] or BIT5;
        8: port[FLPTBase] := port[FLPTBase] or BIT6;
        9: port[FLPTBase] := port[FLPTBase] or BIT7;

        //         10: Port[FLPTBase+1] := Port[FLPTBase+1] or BIT6;
        //         11: Port[FLPTBase+1] := Port[FLPTBase+1] and (not BIT7);  // Inverted
        //         12: Port[FLPTBase+1] := Port[FLPTBase+1] or BIT5;
        //         13: Port[FLPTBase+1] := Port[FLPTBase+1] or BIT4;

        14: port[FLPTBase + 2] := port[FLPTBase + 2] and (not BIT1); // Inverted

        //         15: Port[FLPTBase+1] := Port[FLPTBase+1] or BIT3;

        16: port[FLPTBase + 2] := port[FLPTBase + 2] or BIT2;
        17: port[FLPTBase + 2] := port[FLPTBase + 2] and (not BIT3); // Inverted
        else
          // pins 18-25 (GND), and other invalid pins
      end
    end else
    begin
      case Index of
        1: port[FLPTBase + 2] := port[FLPTBase + 2] or BIT0; // Inverted
        2: port[FLPTBase] := port[FLPTBase] and (not BIT0);
        3: port[FLPTBase] := port[FLPTBase] and (not BIT1);
        4: port[FLPTBase] := port[FLPTBase] and (not BIT2);
        5: port[FLPTBase] := port[FLPTBase] and (not BIT3);
        6: port[FLPTBase] := port[FLPTBase] and (not BIT4);
        7: port[FLPTBase] := port[FLPTBase] and (not BIT5);
        8: port[FLPTBase] := port[FLPTBase] and (not BIT6);
        9: port[FLPTBase] := port[FLPTBase] and (not BIT7);

        //         10: Port[FLPTBase+1] := Port[FLPTBase+1] and (not BIT6);
        //         11: Port[FLPTBase+1] := Port[FLPTBase+1] or BIT7;    // Inverted
        //         12: Port[FLPTBase+1] := Port[FLPTBase+1] and (not BIT5);
        //         13: Port[FLPTBase+1] := Port[FLPTBase+1] and (not BIT4);

        14: port[FLPTBase + 2] := port[FLPTBase + 2] or BIT1; // Inverted

        //         15: Port[FLPTBase+1] := Port[FLPTBase+1] and (not BIT3);

        16: port[FLPTBase + 2] := port[FLPTBase + 2] and (not BIT2);
        17: port[FLPTBase + 2] := port[FLPTBase + 2] or BIT3; // Inverted
        else
          // pins 18-25 (GND), and other invalid pins
      end
    end;
end;
}

