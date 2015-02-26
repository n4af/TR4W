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
  DlPortWritePortUchar = TDlPortWritePortUchar;
  DlPortReadPortUchar = TDlPortReadPortUchar;

  TPinNumber = 1..25;


var
  IOPlugin                              : THandle;
  DlWriteByte                           : TDlPortWritePortUchar;
  DlReadByte                            : TDlPortReadPortUchar;
  dwStatus                              : DWORD;
  FActiveHW                             : boolean; // Is the DLL loaded?
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
function DriverCreate: boolean;
procedure DriverDestroy;
procedure NoInpOut32Message;
procedure DriverBitOperation(var TempByte: Byte; BitToSet: TBitSet; Operation: TBitOperation);
function OpenLPT(var PortHandle: HWND; LPT: PortType): boolean;







implementation
uses MainUnit;


function DriverCreate: boolean;
begin
  FActiveHW := false;
  IOPlugin := LoadLibrary(PChar('inpout32.dll' + #0));
  if (IOPlugin <> 0) then
  begin
    DlWriteByte := TDlPortWritePortUchar(GetProcAddress(IOPlugin,'Out32'));
    DlReadByte := TDlPortReadPortUchar(GetProcAddress(IOPlugin,'Inp32'));
    if (not Assigned(DlWriteByte)) or (not Assigned(DlReadByte)) then
      NoInpOut32Message
    else begin
      FActiveHW := true;
      exit; { Got our plugin, we're done }
    end;
  end;


end;

procedure DriverDestroy;
begin
  if (FActiveHW = true) then FreeLibrary(IOPlugin);
  IOPlugin := 0;
  DlWriteByte := nil;
  DlReadByte := nil;
  FActiveHW := False; // Success
end;




function DriverIsLoaded: boolean;
begin
  Result := FActiveHW;
end;



function GetPortByte(Address: Word; Offset: TOffsetType): Byte;
begin
  Result := DlReadByte(Address + Word(Offset));
end;

procedure SetPortByte(Address: Word; Offset: TOffsetType; data: Byte);
begin
  DlWriteByte(Address + Word(Offset), data);
end;




procedure NoInpOut32Message;
begin;
  showwarning('Enable to load InpOut32.dll'#13#10'Check it is installed in same directory as TR4W.exe');
  halt;
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


