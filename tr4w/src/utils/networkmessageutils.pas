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
  Classes, SysUtils, DateUtils, {Sockets,} IdGlobal,{ IdStack} IdWinsock2;

  type
  QWord = packed record      // was Int64Rec
    case Integer of
      0: (Lo, Hi: Cardinal); 
      1: (Cardinals: array [0..1] of Cardinal); 
      2: (Words: array [0..3] of Word);
      3: (Bytes: array [0..7] of Byte);
  end;

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

procedure UnpackIntLongInt(const AData: TIdBytes; var index: Integer; var AValue: LongInt);
procedure UnpackIntString(const AData: TIdBytes; var index: Integer; var AString: string);
procedure UnpackIntQWord(const AData: TIdBytes; var index: Integer; var AValue: QWord);
procedure UnpackIntInt64(const AData: TIdBytes; var index: Integer; var AValue: Int64);
procedure UnpackIntBoolean(const AData: TIdBytes; var index: Integer; var AFlag: Boolean);
procedure UnpackIntLongword(const AData: TIdBytes; var index: Integer; var AValue: Longword);
procedure UnpackIntDouble(const AData: TIdBytes; var index: Integer; var AValue: Double);
procedure UnpackIntDateTime(const AData: TIdBytes; var index: Integer; var ADateTime: TDateTime);

implementation

function SwapEndian32(Value: integer): integer; register;
asm
  bswap eax
end;

procedure UnpackIntLongInt(const AData: TIdBytes; var index: Integer; var AValue: LongInt);
begin
  AValue := {GStack.HostToNetwork}htonl(BytesToLongInt(AData, index));
  index := index + SizeOf(AValue);
end;

procedure UnpackIntInt64(const AData: TIdBytes; var index: Integer; var AValue: Int64);
begin
  AValue := BytesToInt64(AData, index);
  index := index + SizeOf(AValue);
  //{$IFNDEF BIG_ENDIAN}
  //AValue := SwapEndian(AValue);
  //{$ENDIF}
end;

procedure UnpackIntString(const AData: TIdBytes; var index: Integer; var AString: string);
var
  length: LongInt;
begin
  UnpackIntLongInt(AData,index,length);
  if length <> LongInt($ffffffff) then
  begin
    AString := BytesToString(AData,index,length,enUtf8);
    index := index + length;
  end
  else AString := '';
end;

procedure UnpackIntQWord(const AData: TIdBytes; var index: Integer; var AValue: QWord);
var
   temp: Int64 absolute AValue;
begin
  UnpackIntInt64(AData,index,temp);
end;

procedure UnpackIntBoolean(const AData: TIdBytes; var index: Integer; var AFlag: Boolean);
begin
  AFlag := AData[index] <> 0;
  index := index + 1;
end;

procedure UnpackIntLongword(const AData: TIdBytes; var index: Integer; var AValue: Longword);
begin
  AValue := Longword({GStack.HostToNetwork}htonl(BytesToLongInt(AData, index)));
  index := index + SizeOf(AValue);
end;

procedure UnpackIntDouble(const AData: TIdBytes; var index: Integer; var AValue: Double);
var
  temp: QWord absolute AValue;
begin
  UnpackIntQWord(AData,index,temp);
end;

procedure UnpackIntDateTime(const AData: TIdBytes; var index: Integer; var ADateTime: TDateTime);
var
  dt: Int64;
  tm: Longword;
  ts: Byte;
  temp: Double;
begin
  UnpackIntInt64(AData,index,dt);
  UnpackIntLongword(AData,index,tm);
  ts := AData[index];
  index := index + 1;
  {assume UTC for now}
  temp := dt;
  ADateTime := Now; {IncMilliSecond(JulianDateToDateTime(temp),tm);  }
end;


procedure Pack(var AData: TIdBytes; const AValue: Word); overload;
begin
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
   AppendBytes(AData,ToBytes(AValue));
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

