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
If not, ref: 
http://www.gnu.org/licenses/gpl-3.0.txt
 }
//   Rewrite of uIO to use InpOut32.dll 32 / 64 bit LPT driver from http://www.highrez.co.uk/
//   Should only need InpOut32.dll in same directory as TR4W.exe
//    Gavin Taylor GM0GAV  25 feb 2015


unit uIO;
{$IMPORTEDDATA OFF}
interface

uses
  VC,
  TF,
  Windows,
  WinSvc,
  Messages,
  SysUtils;


type
  PByte = ^Byte;
  PWORD = ^Word;
  PLongword = ^longword;

  TOffsetType = (otData, otState, otControl);
  TBitOperation = (boSet0, boSet1);
  TBitSet = (bsBIT0, bsBIT1, bsBIT2, bsBIT3, bsBIT4, bsBIT5, bsBIT6, bsBIT7);

  TDlPortWritePortUchar = procedure (Port: Integer; Data: byte); stdcall;//  external 'InpOut32.dll';
  TDlPortReadPortUchar = function (Port: Integer): byte; stdcall;//  external 'InpOut32.dll';
  TIsInpOutDriverOpen =   function ()  : boolean;  stdcall;     //  external 'InpOut32.dll';
  DlPortWritePortUchar = TDlPortWritePortUchar;
  DlPortReadPortUchar = TDlPortReadPortUchar;

  TPinNumber = 1..25;


var
  IOPlugin                              : THandle;
  IOPLuginisloaded                      : boolean;
  inpout32LoadAttempted                 : boolean = False;  // load on demand once; a failed load must not re-warn on every OpenLPT
  DlWriteByte                           : TDlPortWritePortUchar;
  DlReadByte                            : TDlPortReadPortUchar;
  dwStatus                              : DWORD;
  LPTBaseAA                             : array[Parallel1..Parallel3] of Cardinal = ($378, $278, $3BC);

const

  STROBE_SIGNAL                         = bsBIT0; //PIN 01 INVERTED
  PTT_SIGNAL                            = bsBIT2; //PIN 16
  CW_SIGNAL                             = bsBIT3; //PIN 17 INVERTED
  RELAY_SIGNAL                          = bsBIT1; //PIN 14
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


  IOCTL_READ_PORTS                      : Cardinal = $00220050;
  IOCTL_WRITE_PORTS                     : Cardinal = $00220060;




function DriverIsLoaded: boolean;      // returns true if the DLL/Driver is loaded
function GetPortByte(Address: Word; Offset: TOffsetType): Byte;
procedure SetPortByte(Address: Word; Offset: TOffsetType; data: Byte);
procedure DriverCreate;
procedure DriverDestroy;
procedure NoInpOut32Message;
procedure DriverBitOperation(var TempByte: Byte; BitToSet: TBitSet; Operation: TBitOperation);
function OpenLPT(var PortHandle: HWND; LPT: PortType): boolean;







implementation
uses MainUnit;


procedure DriverCreate;
begin
   if DriverIsLoaded then
      begin
      Exit;
      end;
   // Attempt the load at most once. inpout32.dll is no longer bundled; if it is
   // absent we warn and disable LPT (see NoInpOut32Message) -- without this guard
   // each of the several OpenLPT calls would re-attempt the load and re-warn.
   if inpout32LoadAttempted then
      begin
      Exit;
      end;
   inpout32LoadAttempted := True;

   IOPlugin := LoadLibrary(PChar('inpout32.dll' + #0));
   if (IOPlugin <> 0) then
      begin
      DlWriteByte := TDlPortWritePortUchar(GetProcAddress(IOPlugin, 'Out32'));
      DlReadByte := TDlPortReadPortUchar(GetProcAddress(IOPlugin, 'Inp32'));
      IOPLuginisloaded := TIsInpOutDriverOpen(GetProcAddress(IOPlugin, 'IsInpOutDriverOpen'));
      end
   else
      begin
      NoInpOut32Message;
      end;
end;

procedure DriverDestroy;
begin
  if DriverIsLoaded then FreeLibrary(IOPlugin);
  IOPlugin := 0;
  DlWriteByte := nil;
  DlReadByte := nil;
  IOPLuginisloaded := false;
  inpout32LoadAttempted := false;   // allow a fresh load attempt after an explicit teardown
end;



function DriverIsLoaded: boolean;
begin
    result := IOPLuginisloaded;
end;



function GetPortByte(Address: Word; Offset: TOffsetType): Byte;
begin
  // inpout32.dll absent/not loaded: the port-I/O pointer is nil. Return 0 (a safe
  // "nothing asserted" default) instead of calling through nil. Not every caller
  // guards on DriverIsLoaded(), so this chokepoint must be self-protecting.
  Result := 0;
  if not Assigned(DlReadByte) then
    begin
    Exit;
    end;
  Result := DlReadByte(Address + Word(Offset));
end;

procedure SetPortByte(Address: Word; Offset: TOffsetType; data: Byte);
begin
  // inpout32.dll absent/not loaded: pointer is nil -> no-op rather than crash.
  if not Assigned(DlWriteByte) then
    begin
    Exit;
    end;
  DlWriteByte(Address + Word(Offset), data);
end;




procedure NoInpOut32Message;
var
  msg: string;
begin
  // inpout32.dll is no longer bundled (it was the AV "vulndriver" false-positive
  // trigger on the installer). When it is absent we DISABLE parallel-port (LPT)
  // features and continue -- we must NOT halt, or a stale LPT port left in a
  // user's config would crash startup. Reached only when an LPT port is mapped.
  msg := 'Parallel-port (LPT) features require inpout32.dll, which is no longer'#13#10 +
         'bundled with TR4W. Download it from http://www.highrez.co.uk/ and place'#13#10 +
         'inpout32.dll in the same folder as tr4w.exe. LPT features are disabled'#13#10 +
         'until then; the rest of TR4W is unaffected.';
  showwarning(PChar(msg));
end;



procedure DriverBitOperation(var TempByte: Byte; BitToSet: TBitSet; Operation: TBitOperation);
type
  TByteSet = set of 0..SizeOf(Byte) * 8 - 1;
begin
  if Operation = boSet0
    then
//    Exclude(TByteSet(TempByte), integer(BitToSet))
    TempByte := TempByte and not (1 shl Byte(BitToSet))
  else
    TempByte := TempByte or (1 shl Byte(BitToSet));
//    Include(TByteSet(TempByte), integer(BitToSet));
end;


function OpenLPT(var PortHandle: HWND; LPT: PortType): boolean;
begin
  Result := False;
  if not DriverIsLoaded() then DriverCreate;
  if not DriverIsLoaded() then Exit;
  PortHandle := LPTBaseAA[LPT];
  Result := True;
end;


end.


