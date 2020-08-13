{********************************************************************************
***                               AlarmeJT                                    ***
***    AlarmeJT is designed to work with exellent WSJT -X Joe Taylor, K1JT    ***
***    running on JT65A modes and JT9.                                        ***
***    -------------------------------------------------------------------    ***
***    version : 0.5 UDP beta                                                 ***
***    -------------------------------------------------------------------    ***
***    Copyright 2015 Alain Thébault (F5JMH)                                  ***
***                                                                           ***
***    UDP and NetworkMessageUtils modules Copyright G4WJS (thank's)          ***
***                                                                           ***
***    This file is part of AlarmeJT.                                         ***
***                                                                           ***
***    AlarmeJT is free software: you can redistribute it and/or modify       ***
***    it under the terms of the GNU General Public License as published by   ***
***    the Free Software Foundation, either version 2.0 of the License, or    ***
***    any later version.                                                     ***
***                                                                           ***
***    AlarmeJT is distributed in the hope that it will be useful,            ***
***    but WITHOUT ANY WARRANTY; without even the implied warranty of         ***
***    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          ***
***    GNU General Public License for more details.                           ***
***                                                                           ***
***    You should have received a copy of the GNU General Public License      ***
***    along with AlarmeJT.  If not, see <http://www.gnu.org/licenses/>.      ***
***                                                                           ***
***    -------------------------------------------------------------------    ***
********************************************************************************}

unit NetworkMessageUtils;

//{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, DateUtils, {Sockets,} IdGlobal, IdStack, IdWinsock2;

  const WSJTX_MESSAGETYPE_HEARTBEATV    = 0;
        WSJTX_MESSAGETYPE_STATUSV       = 1;
        WSJTX_MESSAGETYPE_DECODEV       = 2;
        WSJTX_MESSAGETYPE_CLEARV        = 3;
        WSJTX_MESSAGETYPE_REPLYV        = 4;
        WSJTX_MESSAGETYPE_QSOV          = 5;
        WSJTX_MESSAGETYPE_CLOSEV        = 6;
        WSJTX_MESSAGETYPE_REPLAYV       = 7;
        WSJTX_MESSAGETYPE_HALTTXV       = 8;
        WSJTX_MESSAGETYPE_FREETEXTV     = 9;
        WSJTX_MESSAGETYPE_WSPRDECODEV   = 10;
        WSJTX_MESSAGETYPE_LOCATIONV     = 11;
        WSJTX_MESSAGETYPE_LOGGEDADIFV   = 12;
        WSJTX_MESSAGETYPE_HIGHLIGHTV    = 13;
        WSJTX_MESSAGETYPE_SWITCHCONFIGV = 14;
        WSJTX_MESSAGETYPE_CONFIGUREV    = 15;
        
  type
  QWord = packed record      // was Int64Rec
    case Integer of
      0: (Lo, Hi: Cardinal);
      1: (Cardinals: array [0..1] of Cardinal);
      2: (Words: array [0..3] of Word);
      3: (Bytes: array [0..7] of Byte);
  end;

function SwapEndian32(Value: integer): integer; register;
function SwapEndian16(Value: smallint): smallint; register;

procedure PackFF00(var AData: TIdBytes);
procedure Pack(var AData: TIdBytes; const AValue: Byte); overload; 
procedure Pack(var AData: TIdBytes; const AValue: Word); overload;         // Unsigned 16 bit
procedure Pack(var AData: TIdBytes; const AValue: LongInt); overload;
procedure Pack(var AData: TIdBytes; const AValue: ShortInt); overload;
procedure Pack(var AData: TIdBytes; const AString: string); overload;
procedure Pack(var AData: TIdBytes; const AValue: QWord); overload;
procedure Pack(var AData: TIdBytes; const AValue: Int64); overload;
procedure Pack(var AData: TIdBytes; const AFlag: Boolean); overload;
procedure Pack(var AData: TIdBytes; const AValue: Longword); overload;
procedure Pack(var AData: TIdBytes; const AValue: Double); overload;
procedure Pack(var AData: TIdBytes; const ADateTime: TDateTime); overload;

procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: LongInt); overload;
procedure Unpack(const AData: TIdBytes; var index: Integer; var AString: string); overload;
procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: QWord); overload;
procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: Int64); overload;
procedure Unpack(const AData: TIdBytes; var index: Integer; var AFlag: Boolean); overload;
procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: Longword); overload;
procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: Double); overload;
procedure Unpack(const AData: TIdBytes; var index: Integer; var ADateTime: TDateTime); overload;

//procedure ReverseBytes(var Src: PByte; Dst: Pointer; Count: integer);

implementation


procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: LongInt);
begin
  AValue := {GStack.HostToNetwork}htonl(BytesToLongInt(AData, index));
  index := index + SizeOf(AValue);
end;

procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: Int64);
begin
  AValue := BytesToInt64(AData, index);
  AValue := Int64(GStack.NetworkToHost(UInt64(AValue)));
  index := index + SizeOf(AValue);
end;

procedure Unpack(const AData: TIdBytes; var index: Integer; var AString: string);
var
  length: LongInt;
begin
  Unpack(AData,index,length);
  if length <> LongInt($ffffffff) then
  begin
    AString := BytesToString(AData,index,length,enUtf8);
    index := index + length;
  end
  else AString := '';
end;

procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: QWord);
var
   temp: Int64 absolute AValue;
begin
  Unpack(AData,index,temp);
end;

procedure Unpack(const AData: TIdBytes; var index: Integer; var AFlag: Boolean);
begin
  AFlag := AData[index] <> 0;
  index := index + 1;
end;

procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: Longword);
begin
  AValue := Longword({GStack.HostToNetwork}htonl(BytesToLongInt(AData, index)));
  index := index + SizeOf(AValue);
end;

procedure Unpack(const AData: TIdBytes; var index: Integer; var AValue: Double);
var
  temp: QWord absolute AValue;
begin
  Unpack(AData,index,temp);
end;

procedure Unpack(const AData: TIdBytes; var index: Integer; var ADateTime: TDateTime);
var
  dt: Int64;
  tm: Longword;
  //ts: Byte;
begin
  Unpack(AData,index,dt);
  Unpack(AData,index,tm);
  //ts := AData[index];
  index := index + 1;
  {assume UTC for now}
  ADateTime := Now; {IncMilliSecond(JulianDateToDateTime(temp),tm);  }
end;

procedure Pack(var AData: TIdBytes; const AValue: Byte); overload;
begin
  AppendByte(AData, AValue);
end;

procedure PackFF00(var AData: TIdBytes);
var i: byte;
begin
   i := 255;
   Pack(AData,i);
   i := 0;
   Pack(AData,i);
end;

procedure Pack(var AData: TIdBytes; const AValue: Word); overload;
begin
  // AppendBytes(AData,ToBytes(SwapEndian16(AValue)));
  AppendBytes(AData,ToBytes(AValue));
end;

procedure Pack(var AData: TIdBytes; const AValue: LongInt); overload;
begin
  AppendBytes(AData,ToBytes(HToNl(AValue)));
end;

procedure Pack(var AData: TIdBytes; const AValue: Int64) overload;
begin
  //{$IFNDEF BIG_ENDIAN}
  //AppendBytes(AData,ToBytes(SwapEndian(AValue)));
  //{$ELSE}
  AppendBytes(AData,ToBytes(AValue));
  //{$ENDIF}
end;

procedure Pack(var AData: TIdBytes; const AString: string) overload;
var
  temp: TIdBytes;
  long: integer;       // length of Astring
begin
  long:=Length(AString);        // longueur d'Astring
  temp := ToBytes(AString,enUTF8);
  Pack(AData,long);             // Pack avec la longueur du message
  AppendBytes(AData,temp);      // Pack du bytes
end;

procedure Pack(var AData: TIdBytes; const AValue: QWord) overload;
var
   temp: Int64 absolute AValue;
begin
  Pack(AData,temp);
end;

procedure Pack(var AData: TIdBytes; const AValue: ShortInt) overload;
begin
   AppendBytes(AData,ToBytes(SwapEndian16(AValue)));
end;

procedure Pack(var AData: TIdBytes; const AFlag: Boolean) overload;
var
   temp: ShortInt;
begin
  if AFlag then
  temp := -1
  else
  temp := 0;
  AppendBytes(AData,ToBytes(temp));
end;

procedure Pack(var AData: TIdBytes; const AValue: Longword) overload;
begin
  AppendBytes(AData,ToBytes(HToNl(AValue)));
end;

procedure Pack(var AData: TIdBytes; const AValue: Double) overload;
var
  temp: QWord absolute AValue;
begin
  Pack(AData,temp);
end;

function SwapEndian32(Value: integer): integer; register;
asm
  bswap eax
end;

function SwapEndian16(Value: smallint): smallint; register;
asm
  rol   ax, 8
end;

procedure Pack(var AData: TIdBytes; const ADateTime: TDateTime) overload;
//var
//  dt: Int64;
//  tm: Longword;
//  ts: Byte;
//  temp: Double;
begin
  //Pack(AData,MilliSecondOfTheDay(ADateTime));
  //Pack(AData,QWord(DateTimeToJulianDate(ADateTime)));
  //Pack(AData,Byte(1));
end;
end.

