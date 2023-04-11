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
unit CFGCMD;

{$IMPORTEDDATA OFF}

interface

uses {SlowTree,} Tree,

  Windows,
  TF,
  VC,
  utils_text,
  uTelnet,
  LogStuff,

  LogSCP,
  LogCW,
  LogWind,
  LogDupe,
  ZoneCont,
  LogGrid,
  LogDom,
  FCONTEST,
  LOGDVP,
//  Country9,
  LogEdit,
  //LOGDDX,
//  LOGHP,
  LOGWAE,
  LogPack,
  LogK1EA, {DOS, }
//  Help,
//  LOGPROM, {Crt, }
  LogNet,
//  ColorCfg,
  LogRadio 

  ;
var
LPTBaseAddressArray                   : array[Parallel1..Parallel3] of Cardinal = ($378, $278, $3BC);

function ProcessConfigInstruction(var FileString: ShortString; var FirstCommand: boolean): boolean;

function ProcessConfigInstructions1(ID: Str80; CMD: ShortString): boolean;
//function ProcessConfigInstructions2(ID: Str80; CMD: ShortString): boolean;
function ProcessConfigInstructions3(ID: Str80; CMD: ShortString): boolean;

procedure SniffOutControlCharacters(var TempString: ShortString);

function ProcessRadioTypeold(CMD: ShortString; RadioPointer: RadioPtr): boolean;
//function ProcessRadioControlPort(CMD: ShortString; RadioPointer: RadioPtr): boolean;
//function ProcessRadioDTR(CMD: ShortString; RadioPointer: RadioPtr): boolean;
//function GetPortFromChar(port: ShortString): PortType;
function GetLPTPortFromChar(port: ShortString): PortType;

var
  ConfigFileRead                        : Text;
  ClearDupeSheetCommandGiven            : boolean;
  RunningConfigFile                     : boolean; { True when using Control-V command }

//  tr4w_BoolValue                        : boolean;
  //const

implementation

uses
  uCFG,
  //   Settings_unit,
//  OZCHR,
  uNet,
  uRadioPolling,
  uBandmap,
  MainUnit;

procedure SniffOutControlCharacters(var TempString: ShortString);

var
  NumericString                         : Str20;
  {wli StringLength, }NumericValue, Result: integer;

begin
  if TempString = '' then Exit;

  //wli  StringLength := length(TempString);

  Count := 1;

  while Count <= length(TempString) - 3 do
  begin
    if (TempString[Count] = '<') and (TempString[Count + 3] = '>') then
    begin
      NumericString := UpperCase(Copy(TempString, Count + 1, 2));

      HexToInteger(NumericString, NumericValue, Result);

      if Result = 0 then
      begin
        Delete(TempString, Count, 4);
        Insert(CHR(NumericValue), TempString, Count);
      end;
    end;

    inc(Count);
  end;
end;

function ProcessConfigInstructions1(ID: Str80; CMD: ShortString): boolean;

begin
  ProcessConfigInstructions1 := False;

  if CheckCommand(@ID, CMD) then
  begin
    ProcessConfigInstructions1 := True;
    Exit;
  end;



end;
   // Tom commented out to verify nothing call sit
// Removed ProcessConfigInstruction2

function ProcessConfigInstructions3(ID: Str80; CMD: ShortString): boolean;

begin
  ProcessConfigInstructions3 := False; //wli

  if CheckCommand(@ID, CMD) then
  begin
    ProcessConfigInstructions3 := True;
    Exit;
  end;





end;

function ProcessConfigInstruction(var FileString: ShortString; var FirstCommand: boolean): boolean;
var
  ID                                    : ShortString;
  CMD                                   : ShortString;
begin
  if FileString = '' then
  begin
    ProcessConfigInstruction := True;
    Exit;
  end;

  if FileString[1] in [';', '[' {, '_'}] then
  begin
    ProcessConfigInstruction := True;
    Exit;
  end;



  ProcessConfigInstruction := CheckCommand(@ID, CMD);

  if ID = '' then ProcessConfigInstruction := True;
end;

function ProcessRadioTypeold(CMD: ShortString; RadioPointer: RadioPtr): boolean;

begin
end;
function GetLPTPortFromChar(port: ShortString): PortType;
begin
  Result := NoPort;
  if PInteger(@port[1])^ = $454E4F4E {NONE} then Exit;
  if port[1] = '1' then Result := Parallel1;
  if port[1] = '2' then Result := Parallel2;
  if port[1] = '3' then Result := Parallel3;
end;

end.

