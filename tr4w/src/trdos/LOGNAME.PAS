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
unit LogName;

{$O+}
{$F+}

interface

uses //SlowTree,
  Tree,
  //Crt,
  ZoneCont,
  LogSCP,
  Dialogs,
//  treepas,
  Other;

const
  CommonNameList: array[0..255] of fourBYTEs = (
    ($00, $00, $01, $AD), ($00, $00, $02, $39), ($00, $00, $3D, $EF),
    ($00, $00, $3E, $FD), ($00, $00, $42, $6F), ($00, $00, $43, $D5),
    ($00, $00, $44, $B5), ($00, $00, $4C, $8D), ($00, $00, $4E, $93),
    ($00, $00, $5D, $2C), ($00, $00, $5D, $2D), ($00, $00, $5F, $81),
    ($00, $00, $5F, $87), ($00, $00, $61, $EF), ($00, $00, $67, $4A),
    ($00, $00, $6C, $A3), ($00, $00, $6C, $AE), ($00, $00, $6D, $CA),
    ($00, $00, $6E, $A0), ($00, $00, $6E, $A9), ($00, $00, $6F, $87),
    ($00, $00, $71, $F7), ($00, $00, $71, $FC), ($00, $00, $72, $02),
    ($00, $00, $72, $07), ($00, $00, $72, $08), ($00, $00, $72, $8B),
    ($00, $00, $72, $90), ($00, $00, $73, $23), ($00, $00, $73, $FC),
    ($00, $00, $74, $09), ($00, $00, $77, $E0), ($00, $00, $77, $E9),
    ($00, $00, $77, $EA), ($00, $00, $77, $EE), ($00, $00, $79, $62),
    ($00, $00, $7C, $A3), ($00, $00, $7C, $B3), ($00, $00, $7C, $B4),
    ($00, $00, $7C, $B8), ($00, $00, $7D, $CB), ($00, $00, $82, $08),
    ($00, $00, $84, $01), ($00, $00, $8C, $BF), ($00, $00, $8D, $51),
    ($00, $00, $97, $76), ($00, $00, $99, $65), ($00, $00, $99, $67),
    ($00, $00, $99, $71), ($00, $00, $99, $7C), ($00, $00, $9A, $E4),
    ($00, $00, $9C, $C3), ($00, $00, $9D, $53), ($00, $00, $9D, $C8),
    ($00, $00, $9D, $CE), ($00, $00, $A2, $12), ($00, $00, $A2, $13),
    ($00, $00, $A2, $1A), ($00, $00, $A2, $A7), ($00, $00, $A3, $44),
    ($00, $00, $A4, $22), ($00, $00, $AA, $9B), ($00, $00, $AC, $CD),
    ($00, $00, $AD, $EC), ($00, $00, $AD, $FD), ($00, $00, $BC, $DF),
    ($00, $00, $BE, $DA), ($00, $00, $BF, $C5), ($00, $00, $C2, $C7),
    ($00, $0B, $77, $55), ($00, $0B, $77, $F3), ($00, $0B, $82, $81),
    ($00, $0B, $A4, $BE), ($00, $0C, $54, $61), ($00, $0C, $68, $DF),
    ($00, $0D, $3E, $F5), ($00, $0D, $61, $F6), ($00, $0E, $3E, $10),
    ($00, $0E, $3F, $82), ($00, $0E, $51, $E6), ($00, $0E, $67, $91),
    ($00, $0E, $68, $F9), ($00, $0E, $8A, $3D), ($00, $0F, $4D, $07),
    ($00, $0F, $98, $88), ($00, $10, $97, $F5), ($00, $10, $A8, $BE),
    ($00, $10, $A9, $2D), ($00, $11, $3F, $02), ($00, $11, $53, $BA),
    ($00, $11, $53, $BE), ($00, $11, $54, $51), ($00, $11, $97, $F8),
    ($00, $12, $3E, $60), ($00, $12, $3E, $68), ($00, $12, $3E, $FE),
    ($00, $12, $67, $B0), ($00, $12, $69, $C0), ($00, $12, $69, $D7),
    ($00, $12, $A8, $4E), ($00, $13, $48, $32), ($00, $13, $5E, $A2),
    ($00, $13, $9C, $C5), ($00, $13, $AC, $CF), ($00, $14, $3C, $C9),
    ($00, $14, $51, $E6), ($00, $14, $52, $97), ($00, $14, $69, $BA),
    ($00, $14, $88, $63), ($00, $14, $89, $F1), ($00, $14, $A7, $76),
    ($00, $15, $3E, $F5), ($00, $15, $40, $26), ($00, $15, $6A, $C3),
    ($00, $15, $88, $A8), ($00, $15, $A9, $52), ($00, $15, $A9, $F1),
    ($00, $16, $3C, $C7), ($00, $16, $3E, $FC), ($00, $17, $3D, $F5),
    ($00, $17, $3E, $F4), ($00, $17, $3F, $0F), ($00, $17, $3F, $47),
    ($00, $17, $68, $B3), ($00, $17, $68, $B7), ($00, $17, $6A, $10),
    ($00, $17, $89, $D0), ($00, $17, $8A, $20), ($00, $18, $3D, $E7),
    ($00, $18, $67, $91), ($00, $18, $87, $8C), ($00, $18, $89, $D0),
    ($00, $18, $89, $D4), ($00, $19, $77, $E2), ($00, $19, $A4, $DD),
    ($00, $1A, $3F, $64), ($00, $1A, $54, $9C), ($00, $1A, $54, $A9),
    ($00, $1A, $63, $17), ($00, $1C, $53, $BE), ($00, $1C, $67, $8E),
    ($00, $1C, $67, $91), ($00, $1C, $88, $EF), ($00, $1C, $A7, $E0),

    ($00, $1C, $A7, $F0), ($00, $1C, $AA, $15), ($00, $1D, $63, $19),
    ($00, $1D, $68, $1F), ($00, $1D, $A2, $1D), ($00, $1E, $3C, $C9),
    ($00, $1E, $3C, $E4), ($00, $1E, $3D, $E7), ($00, $1E, $3D, $EB),
    ($00, $1E, $3D, $FB), ($00, $1E, $54, $62), ($00, $1E, $89, $02),
    ($00, $1E, $89, $17), ($00, $1E, $89, $1D), ($00, $1E, $89, $4C),
    ($00, $1E, $89, $DC), ($00, $1E, $8A, $D9), ($00, $20, $77, $4B),
    ($00, $21, $3E, $1F), ($00, $21, $88, $EF), ($00, $23, $3E, $31),
    ($00, $23, $3F, $23), ($00, $23, $89, $F5), ($00, $23, $A8, $BE),
    ($00, $23, $A8, $E3), ($00, $23, $A9, $E6), ($00, $24, $88, $F2),
    ($01, $AC, $69, $B2), ($01, $AD, $3D, $AA), ($01, $AF, $4E, $F9),
    ($01, $C7, $99, $EB), ($01, $CB, $99, $42), ($01, $D5, $98, $98),
    ($01, $D8, $67, $4A), ($01, $D8, $A7, $B7), ($01, $D8, $A9, $58),
    ($01, $F3, $98, $98), ($01, $F3, $A7, $BD), ($01, $F7, $67, $FB),
    ($01, $FA, $78, $7D), ($01, $FD, $3D, $A3), ($02, $11, $AD, $ED),
    ($02, $47, $67, $8E), ($02, $47, $83, $26), ($02, $4A, $5D, $2C),
    ($02, $6C, $3E, $60), ($02, $6C, $3E, $6F), ($02, $6C, $6A, $15),
    ($02, $84, $99, $EB), ($02, $A5, $99, $EB), ($02, $A9, $69, $37),
    ($02, $A9, $84, $77), ($02, $A9, $84, $87), ($02, $F3, $99, $EB),
    ($02, $FD, $9D, $50), ($03, $03, $73, $61), ($03, $14, $97, $FD),
    ($03, $14, $A4, $BE), ($03, $14, $C5, $18), ($03, $18, $6A, $03),
    ($03, $18, $83, $4F), ($03, $18, $AD, $F7), ($03, $1F, $3F, $6B),
    ($03, $39, $99, $EB), ($03, $44, $8A, $CE), ($03, $47, $A8, $A3),
    ($03, $5E, $98, $94), ($03, $66, $48, $32), ($03, $66, $A4, $BE),
    ($03, $CD, $AD, $61), ($03, $D1, $A2, $B5), ($04, $17, $79, $7A),
    ($04, $17, $82, $81), ($04, $25, $5D, $30), ($04, $3E, $8A, $25),
    ($04, $40, $98, $40), ($04, $43, $68, $1F), ($04, $47, $3F, $7E),
    ($04, $4F, $54, $E6), ($04, $61, $A4, $BE), ($04, $65, $99, $EB),
    ($04, $65, $A4, $BE), ($04, $6F, $9D, $C2), ($04, $AB, $9D, $EA),
    ($04, $D0, $BE, $B2), ($04, $D8, $78, $F7), ($05, $28, $9D, $C2),
    ($47, $38, $79, $60), ($4D, $21, $83, $34), ($4D, $AC, $A2, $B5),
    ($54, $C3, $53, $BE), ($5D, $2D, $98, $40), ($5D, $30, $3E, $ED),
    ($5E, $A2, $4E, $93), ($5F, $7C, $A2, $B5), ($64, $00, $3E, $ED),
    ($77, $EA, $83, $25), ($7C, $B2, $A3, $45), ($7D, $CB, $62, $83),
    ($8D, $D8, $99, $D7), ($99, $65, $54, $61), ($99, $6F, $3E, $59),
    ($9D, $5C, $5D, $28), ($9D, $5C, $5D, $37), ($9F, $7A, $57, $3F),
    ($AC, $CD, $54, $66), ($AC, $D4, $68, $EC), ($AD, $EC, $A4, $27),
    ($AD, $FD, $3E, $24), ($B2, $26, $A2, $B5), ($B2, $2C, $97, $FF),
    ($B2, $C0, $82, $9F));

  NumberArrays = 2;

  MaximumCommonNames = 16400;
  MaximumArrayCommonNames = MaximumCommonNames div NumberArrays;

  MaximumUncommonNames = 7200;
  MaximumArrayUncommonNames = MaximumUncommonNames div NumberArrays;

  MaxClubCalls = 500;

type
  CommonCallArray = array[0..NumberArrays - 1, 0..MaximumArrayCommonNames] of TwoBytes;
  CommonNameArray = array[0..NumberArrays - 1, 0..MaximumArrayCommonNames] of BYTE;

  CommonCallArrayPtr = ^CommonCallArray;
  CommonNameArrayPtr = ^CommonNameArray;
  CommonTotalArray = array[0..NumberArrays - 1] of integer;

  UncommonCallArray = array[0..NumberArrays - 1, 0..MaximumArrayUncommonNames] of TwoBytes;
  UncommonNameArray = array[0..NumberArrays - 1, 0..MaximumArrayUncommonNames] of fourBYTEs;

  UncommonCallArrayPtr = ^UncommonCallArray;
  UncommonNameArrayPtr = ^UncommonNameArray;
  UncommonTotalArray = array[0..NumberArrays - 1] of integer;

  ClubCallArray = array[0..MaxClubCalls] of fourBYTEs;
  ClubCallArrayPtr = ^ClubCallArray;

  FourBytePtr = ^fourBYTEs;

  PossibleCallEntry = record
    Call: CallString;
    Dupe: boolean;
  end;

  TotalArrayRecord = record
    Name: fourBYTEs;
    Hits: integer;
  end;

  NameDictionary = object
    CMQFileName: Str80;
    CMQBackUpFileName: Str80;

    NameMemoryDisable: boolean;

    CommonCalls: CommonCallArrayPtr;
    CommonNames: CommonNameArrayPtr;
    CommonTotals: CommonTotalArray;

    UncommonCalls: UncommonCallArrayPtr;
    UncommonNames: UncommonNameArrayPtr;
    UncommonTotals: UncommonTotalArray;

    ClubCalls: ClubCallArrayPtr;
    NumberClubCalls: integer;

    procedure Abort;
    procedure AddCallToPossibleList(Call: {Call} string; var PossCallList: PossibleCallRecord);
    function AddClubCall(Call: CallString): boolean;
    function AddName(Call: CallString; Name: Str80): boolean;
    procedure ComputeTotalCalls;
    procedure DeleteName(Callsign: CallString);
    procedure DumpNames;
    function FindCommonCallAddress(Call: fourBYTEs; NameCode: integer): integer;
    function FindUncommonCallAddress(AddCall: fourBYTEs; NameCode: integer): integer;
    function GetName(Call: CallString): Str80;
    function GetRandomCall: CallString;
    procedure Init;
    procedure InputASCIIFile;
    function Load: boolean;
    procedure MakeASCIIList(FileName: Str80);
    procedure MakePossibleCallList(Call: CallString; var PossCallList: PossibleCallRecord);
    function ReLoad: boolean;
    procedure Save;
    function TotalNumberOfCalls: integer;
    procedure UpdateNameFile;
  end;

var
  Names: NameDictionary;
  ArraysSetUp: boolean;

implementation

var
  CallsPrinted: integer;
  LargestCommonArray: integer;
  LargestUncommonArray: integer;
  NamesCleared: boolean;
  TotalCalls: integer;

function GetNameCode(Call: CallString): integer;

var
  TempBytes: fourBYTEs;
  Total: integer;

begin
  CompressFormat(Call, TempBytes);

  Total := 0;

  Total := TempBytes[1] + TempBytes[2];

  TempBytes[1] := TempBytes[1] div 16;
  TempBytes[2] := TempBytes[2] div 16;

  Total := (Total + TempBytes[1] + TempBytes[2]) and (NumberArrays - 1);

  GetNameCode := Total;
end;

function CommonName(Name: CallString; var NameAddress: BYTE): boolean;

var
  CompName: fourBYTEs;
  Address, StartAddress, StopAddress: integer;

begin
  if (length(Name) < 2) or (length(Name) > 6) then
  begin
    CommonName := False;
    exit;
  end;

  CompressFormat(Name, CompName);

  if CompName[1] = 0 then
  begin
    if CompName[2] = 0 then
    begin
      if CompName[3] < $80 then
      begin
        StartAddress := 0;
        StopAddress := 40;
      end
      else
      begin
        StartAddress := 41;
        StopAddress := 68;
      end;
    end
    else
    begin
      if CompName[2] < $18 then
      begin
        StartAddress := 69;
        StopAddress := 127;
      end
      else
      begin
        StartAddress := 128;
        StopAddress := 170;
      end;
    end;
  end
  else
  begin
    if CompName[1] < 4 then
    begin
      StartAddress := 171;
      StopAddress := 214;
    end
    else
    begin
      StartAddress := 215;
      StopAddress := 255;
    end;
  end;

  for Address := StartAddress to StopAddress do
    if (CommonNameList[Address][4] = CompName[4]) and
      (CommonNameList[Address][3] = CompName[3]) and
      (CommonNameList[Address][2] = CompName[2]) and
      (CommonNameList[Address][1] = CompName[1]) then
    begin
      NameAddress := Address;
      CommonName := true;
      exit;
    end;

  CommonName := False;
end;

function StandardNameCallFormat(Call: CallString): CallString;

var
  TempCall: CallString;

begin
  TempCall := UpperCase(StandardCallFormat(Call, true));

  if StringHas(TempCall, '/') then
    TempCall := PostcedingString(TempCall, '/');

  if StringHas(TempCall, '/') then
    TempCall := PrecedingString(TempCall, '/');

  if length(TempCall) > 6 then TempCall[0] := CHR(6);
  StandardNameCallFormat := TempCall;
end;

procedure NameDictionary.Abort;

begin
  if CommonCalls <> nil then Dispose(CommonCalls);
  if CommonNames <> nil then Dispose(CommonNames);
  if UnCommonCalls <> nil then Dispose(UncommonCalls);
  if UnCommonNames <> nil then Dispose(UncommonNames);
  if ClubCalls <> nil then Dispose(ClubCalls);

  CommonCalls := nil;
  CommonNames := nil;
  UnCommonCalls := nil;
  UnCommonNames := nil;
  ClubCalls := nil;
end;

function NameDictionary.AddClubCall(Call: CallString): boolean;

var
  TempBytes: fourBYTEs;
  CallAddress: integer;

begin
  AddClubCall := False;
  CompressFormat(Call, TempBytes);

  if NumberClubCalls = 0 then
  begin
    ClubCalls^[NumberClubCalls] := TempBytes;
    inc(NumberClubCalls);
    inc(TotalCalls);
    exit;
  end;

  if NumberClubCalls < MaxClubCalls then
  begin
    for CallAddress := 0 to NumberClubCalls - 1 do
      if (ClubCalls^[CallAddress][4] = TempBytes[4]) and
        (ClubCalls^[CallAddress][3] = TempBytes[3]) and
        (ClubCalls^[CallAddress][2] = TempBytes[2]) and
        (ClubCalls^[CallAddress][1] = TempBytes[1]) then exit;

    ClubCalls^[NumberClubCalls] := TempBytes;
    inc(NumberClubCalls);
    inc(TotalCalls);
    AddClubCall := true;
  end;
end;

function NameDictionary.AddName(Call: CallString; Name: Str80): boolean;

var
  NameAddress: BYTE;
  Address, NameCode, Pointer: integer;
  CompCall, CompName: fourBYTEs;
  PrefixFlag: boolean;
  Prefix, Suffix: TwoBytes;

begin
  AddName := False;
  Call := StandardNameCallFormat(Call);

  if (ClubCall(Call)) or (Name = 'CLUB') then
  begin
    AddName := AddClubCall(Call);
    exit;
  end;

  NameCode := GetNameCode(Call);

  CompressFormat(Call, CompCall);
  CompressFormat(Name, CompName);

  Prefix[1] := CompCall[1];
  Prefix[2] := CompCall[2];
  Suffix[1] := CompCall[3];
  Suffix[2] := CompCall[4];

  if CommonName(Name, NameAddress) then
  begin
    if CommonTotals[NameCode] = 0 then
    begin
      CommonCalls^[NameCode, 0][1] := $FF;
      CommonCalls^[NameCode, 0][2] := $FF;
      CommonNames^[NameCode, 0] := $F;

      CommonCalls^[NameCode, 1] := Prefix;

      CommonCalls^[NameCode, 2] := Suffix;
      CommonNames^[NameCode, 2] := NameAddress;

      CommonTotals[NameCode] := 3;

      AddName := true;
      inc(TotalCalls);
      exit;
    end;

    if CommonTotals[NameCode] < (MaximumArrayCommonNames - 3) then
    begin
      PrefixFlag := False;

      for Address := 0 to CommonTotals[NameCode] - 1 do
      begin
        if PrefixFlag then
        begin
          if (CommonCalls^[NameCode, Address][1] = Prefix[1]) and
            (CommonCalls^[Namecode, Address][2] = Prefix[2]) then
          begin
//wli            inc(Address);

            Move(CommonCalls^[NameCode, Address],
              CommonCalls^[Namecode, Address + 1],
              (CommonTotals[NameCode] - Address) * 2);

            Move(CommonNames^[NameCode, Address],
              CommonNames^[Namecode, Address + 1],
              CommonTotals[NameCode] - Address);

            CommonCalls^[NameCode, Address] := Suffix;
            CommonNames^[NameCode, Address] := NameAddress;

            inc(CommonTotals[NameCode]);
            inc(TotalCalls);
            AddName := true;
            exit;
          end;

          PrefixFlag := False;
        end;

        if (CommonCalls^[NameCode, Address][2] = $FF) and
          (CommonCalls^[NameCode, Address][1] = $FF) and
          (CommonNames^[NameCode, Address] = $F) then
          PrefixFlag := true;

      end;

      { Prefix not found, so add it at end of list.  First do prefix code }

      CommonCalls^[NameCode, CommonTotals[NameCode]][1] := $FF;
      CommonCalls^[NameCode, CommonTotals[NameCode]][2] := $FF;
      CommonNames^[NameCode, CommonTotals[NameCode]] := $F;
      inc(CommonTotals[NameCode]);

      CommonCalls^[NameCode, CommonTotals[NameCode]] := Prefix;
      inc(CommonTotals[NameCode]);

      CommonCalls^[NameCode, CommonTotals[NameCode]] := Suffix;
      CommonNames^[NameCode, CommonTotals[NameCode]] := NameAddress;
      inc(CommonTotals[NameCode]);

      inc(TotalCalls);
      AddName := true;
    end;
    exit; { No room to add a call }
  end

  else
  begin
    if UnCommonTotals[NameCode] = 0 then
    begin
      UnCommonCalls^[NameCode, 0][1] := $FF;
      UnCommonCalls^[NameCode, 0][2] := $FF;
      UnCommonNames^[NameCode, 0][1] := $FF;
      UnCommonNames^[NameCode, 0][2] := $FF;

      UnCommonCalls^[NameCode, 1] := Prefix;

      UnCommonCalls^[NameCode, 2] := Suffix;
      UnCommonNames^[NameCode, 2] := CompName;

      UnCommonTotals[NameCode] := 3;
      inc(TotalCalls);
      AddName := true;
      exit;
    end;

    if UnCommonTotals[NameCode] < (MaximumArrayUnCommonNames - 3) then
    begin
      PrefixFlag := False;

      for Address := 0 to UnCommonTotals[NameCode] - 1 do
      begin
        if PrefixFlag then
        begin
          if (UnCommonCalls^[NameCode, Address][1] = Prefix[1]) and
            (UnCommonCalls^[Namecode, Address][2] = Prefix[2]) then
          begin
//wli            inc(Address);

            Move(UnCommonCalls^[NameCode, Address],
              UnCommonCalls^[Namecode, Address + 1],
              (UnCommonTotals[NameCode] - Address) * 2);

            Move(UnCommonNames^[NameCode, Address],
              UnCommonNames^[Namecode, Address + 1],
              (UnCommonTotals[NameCode] - Address) * 4);

            UnCommonCalls^[NameCode, Address] := Suffix;
            UnCommonNames^[NameCode, Address] := CompName;

            inc(UnCommonTotals[NameCode]);
            inc(TotalCalls);
            AddName := true;
            exit;
          end;

          PrefixFlag := False;
        end;

        if (UnCommonCalls^[NameCode, Address][2] = $FF) and
          (UnCommonCalls^[NameCode, Address][1] = $FF) and
          (UnCommonNames^[NameCode, Address][1] = $FF) and
          (UnCommonNames^[NameCode, Address][2] = $FF) then
          PrefixFlag := true;

      end;

      { Prefix not found, so add it at end of list.  First do prefix code }

      UnCommonCalls^[NameCode, UnCommonTotals[NameCode]][1] := $FF;
      UnCommonCalls^[NameCode, UnCommonTotals[NameCode]][2] := $FF;
      UnCommonNames^[NameCode, UnCommonTotals[NameCode]][1] := $FF;
      UnCommonNames^[NameCode, UnCommonTotals[NameCode]][2] := $FF;
      inc(UnCommonTotals[NameCode]);

      { Now add the new prefix }

      UnCommonCalls^[NameCode, UnCommonTotals[NameCode]] := Prefix;
      inc(UnCommonTotals[NameCode]);

      { Put the suffix and name on }

      UnCommonCalls^[NameCode, UnCommonTotals[NameCode]] := Suffix;
      UnCommonNames^[NameCode, UnCommonTotals[NameCode]] := CompName;
      inc(UnCommonTotals[NameCode]);

      inc(TotalCalls);
      AddName := true;
    end;

    exit; { No room to add a call }
  end;
end;

procedure NameDictionary.DeleteName(Callsign: CallString);

var
  Address, NamePointer, Offset, NameCode: integer;
  TempBytes: fourBYTEs;
  HexWord: Word;
  Call: CallString;

begin
  Call := StandardNameCallFormat(Callsign);
  NameCode := GetNameCode(Call);

  CompressFormat(Call, TempBytes);

  Address := FindCommonCallAddress(TempBytes, NameCode);

  if Address <> -1 then
  begin
    if (CommonCalls^[NameCode, Address - 2][1] = $FF) and
      (CommonCalls^[NameCode, Address - 2][2] = $FF) and
      (CommonCalls^[NameCode, Address + 1][1] = $FF) and
      (CommonCalls^[NameCode, Address + 1][2] = $FF) then
    begin
      Move(CommonCalls^[NameCode, Address + 1],
        CommonCalls^[NameCode, Address - 2],
        (CommonTotals[NameCode] - Address - 1) * 2);

      Move(CommonNames^[NameCode, Address + 1],
        CommonNames^[NameCode, Address - 2],
        CommonTotals[NameCode] - Address - 1);

      Dec(CommonTotals[NameCode]);
      Dec(CommonTotals[NameCode]);
      Dec(CommonTotals[NameCode]);
      Dec(TotalCalls);
    end
    else
    begin
      Move(CommonCalls^[NameCode, Address + 1],
        CommonCalls^[NameCode, Address],
        (CommonTotals[NameCode] - Address - 1) * 2);

      Move(CommonNames^[NameCode, Address + 1],
        CommonNames^[NameCode, Address],
        CommonTotals[NameCode] - Address - 1);

      Dec(CommonTotals[NameCode]);
      Dec(TotalCalls);
    end;

    exit;
  end;

  Address := FindUnCommonCallAddress(TempBytes, NameCode);

  if Address <> -1 then
  begin
    if (UnCommonCalls^[NameCode, Address - 2][1] = $FF) and
      (UnCommonCalls^[NameCode, Address - 2][2] = $FF) and
      (UnCommonCalls^[NameCode, Address + 1][1] = $FF) and
      (UnCommonCalls^[NameCode, Address + 1][2] = $FF) then
    begin
      Move(UnCommonCalls^[NameCode, Address + 1],
        UnCommonCalls^[NameCode, Address - 2],
        (UnCommonTotals[NameCode] - Address - 1) * 2);

      Move(UnCommonNames^[NameCode, Address + 1],
        UnCommonNames^[NameCode, Address - 2],
        (UnCommonTotals[NameCode] - Address - 1) * 4);

      Dec(UnCommonTotals[NameCode]);
      Dec(UnCommonTotals[NameCode]);
      Dec(UnCommonTotals[NameCode]);
      Dec(TotalCalls);
    end
    else
    begin
      Move(UnCommonCalls^[NameCode, Address + 1],
        UnCommonCalls^[NameCode, Address],
        (UnCommonTotals[NameCode] - Address - 1) * 2);

      Move(UnCommonNames^[NameCode, Address + 1],
        UnCommonNames^[NameCode, Address],
        (UnCommonTotals[NameCode] - Address - 1) * 4);

      Dec(UnCommonTotals[NameCode]);
      Dec(TotalCalls);
    end;

    exit;
  end;

  if NumberClubCalls > 0 then
    for NamePointer := 0 to NumberClubCalls - 1 do
      if (ClubCalls^[NamePointer][4] = TempBytes[4]) and
        (ClubCalls^[NamePointer][3] = TempBytes[3]) and
        (ClubCalls^[NamePointer][2] = TempBytes[2]) and
        (ClubCalls^[NamePointer][1] = TempBytes[1]) then
      begin
        if NamePointer < NumberClubCalls - 1 then
          for Offset := NamePointer to NumberClubCalls - 2 do
            ClubCalls^[Offset] := ClubCalls^[Offset + 1];
        Dec(NumberClubCalls);
        Dec(TotalCalls);
        exit;
      end;

  WriteLn('Sorry, I could not find ', Callsign, '.');
end;

procedure NameDictionary.DumpNames;

begin
  if (not NamesCleared) and ArraysSetUp then
  begin
    NamesCleared := true;
    Dispose(CommonNames);
    Dispose(UncommonNames);
    NameMemoryDisable := true;
    ArraysSetUp := False;
  end;
end;

function NameDictionary.FindCommonCallAddress(Call: fourBYTEs; NameCode: integer): integer;

var
  Address: integer;
  MatchPrefixFlag, PrefixFlag: boolean;

begin
  FindCommonCallAddress := -1;

  MatchPrefixFlag := False;
  PrefixFlag := False;

  if CommonTotals[NameCode] > 0 then
    for Address := 0 to CommonTotals[NameCode] - 1 do
    begin
      if MatchPrefixFlag then
      begin
        if (CommonCalls^[NameCode, Address][2] = Call[4]) and
          (CommonCalls^[NameCode, Address][1] = Call[3]) then
        begin
          FindCommonCallAddress := Address;
          exit;
        end;

        if (CommonCalls^[NameCode, Address][2] = $FF) and
          (CommonCalls^[NameCode, Address][1] = $FF) and
          (CommonNames^[NameCode, Address] = $F) then
        begin
          MatchPrefixFlag := False;
          PrefixFlag := true;
        end;

        Continue;
      end;

      if PrefixFlag then
      begin
        MatchPrefixFlag := (CommonCalls^[NameCode, Address][1] = Call[1]) and
          (CommonCalls^[NameCode, Address][2] = Call[2]);
        PrefixFlag := False;
        Continue;
      end;

      if (CommonCalls^[NameCode, Address][1] = $FF) and
        (CommonCalls^[NameCode, Address][2] = $FF) and
        (CommonNames^[NameCode, Address] = $F) then
      begin
        MatchPrefixFlag := False;
        PrefixFlag := true;
        Continue;
      end;
    end;
end;

function NameDictionary.FindUncommonCallAddress(AddCall: fourBYTEs; NameCode: integer): integer;

var
  Address: integer;
  MatchPrefixFlag, PrefixFlag: boolean;
  Prefix, Suffix: TwoBytes;

begin
  FindUnCommonCallAddress := -1;

  Prefix[1] := AddCall[1];
  Prefix[2] := AddCall[2];
  Suffix[1] := AddCall[3];
  Suffix[2] := AddCall[4];

  MatchPrefixFlag := False;
  PrefixFlag := False;

  if UnCommonTotals[NameCode] > 0 then
    for Address := 0 to UnCommonTotals[NameCode] - 1 do
    begin
      if MatchPrefixFlag then
      begin
        if (UnCommonCalls^[NameCode, Address][1] = Suffix[1]) and
          (UnCommonCalls^[NameCode, Address][2] = Suffix[2]) then
        begin
          FindUnCommonCallAddress := Address;
          exit;
        end;

        if (UnCommonCalls^[NameCode, Address][1] = $FF) and
          (UnCommonCalls^[NameCode, Address][2] = $FF) and
          (UnCommonNames^[NameCode, Address][1] = $FF) and
          (UnCommonNames^[NameCode, Address][2] = $FF) then
        begin
          MatchPrefixFlag := False;
          PrefixFlag := true;
        end;

        Continue;
      end;

      if PrefixFlag then
      begin
        MatchPrefixFlag := (UnCommonCalls^[NameCode, Address][1] = Prefix[1]) and
          (UnCommonCalls^[NameCode, Address][2] = Prefix[2]);
        PrefixFlag := False;
        Continue;
      end;

      if (UnCommonCalls^[NameCode, Address][1] = $FF) and
        (UnCommonCalls^[NameCode, Address][2] = $FF) and
        (UnCommonNames^[NameCode, Address][2] = $FF) and
        (UnCommonNames^[NameCode, Address][1] = $FF) then
      begin
        MatchPrefixFlag := False;
        PrefixFlag := true;
        Continue;
      end;
    end;
end;

function NameDictionary.GetName(Call: CallString): Str80;

{ This procedure will return the name for the callsign passed to it.  If it
  does not know the name, it will return a null string.  The callsign will
  be converted to the root call eliminating any portable information.     }

var
  Address, NameCode, NamePointer: integer;
  TempBytes: fourBYTEs;

begin
  GetName := '';
  if NamesCleared then exit;

  Call := StandardNameCallFormat(Call);

  NameCode := GetNameCode(Call);
  CompressFormat(Call, TempBytes);

  Address := FindCommonCallAddress(TempBytes, NameCode);

  if Address <> -1 then
  begin
    GetName := ExpandedString(CommonNameList[CommonNames^[NameCode, Address]]);
    exit;
  end;

  Address := FindUncommonCallAddress(TempBytes, NameCode);

  if Address <> -1 then
  begin
    GetName := ExpandedString(UnCommonNames^[NameCode, Address]);
    exit;
  end;

  if NumberClubCalls > 0 then
    for NamePointer := 0 to NumberClubCalls - 1 do
      if (ClubCalls^[NamePointer][4] = TempBytes[4]) and
        (ClubCalls^[NamePointer][3] = TempBytes[3]) and
        (ClubCalls^[NamePointer][2] = TempBytes[2]) and
        (ClubCalls^[NamePointer][1] = TempBytes[1]) then
        GetName := 'CLUB';
end;

function NameDictionary.GetRandomCall: CallString;

var
  NameCode, NamePointer: integer;
  Prefix, Suffix: TwoBytes;
  Call: {Call} string;

begin
  if TotalCalls < 100 then
  begin
    case Random(20) of
      0: GetRandomCall := 'G3FXB';
      1: GetRandomCall := 'N6TR';
      2: GetRandomCall := 'ZD8Z';
      3: GetRandomCall := 'F6IMS';
      4: GetRandomCall := '9Y4XX';
      5: GetRandomCall := 'EA9IE';
      6: GetRandomCall := 'FR5DX';
      7: GetRandomCall := 'VK6HD';
      8: GetRandomCall := 'JA8RWU';
      9: GetRandomCall := 'K6NA/KL7';
      10: GetRandomCall := 'N6AA';
      11: GetRandomCall := 'NJ2L';
      12: GetRandomCall := 'WN4KKN';
      13: GetRandomCall := 'N5AU';
      14: GetRandomCall := 'K1AR';
      15: GetRandomCall := 'W7RM';
      16: GetRandomCall := '4U1ITU';
      17: GetRandomCall := 'N6ZZ';
      18: GetRandomCall := 'WA6OTU';
      19: GetRandomCall := 'AA6RX';
    end;
    exit;
  end;

  NameCode := Random(NumberArrays);

  if Random(100) < 72 then { Use common name array 72 percent of the time }
  begin
    if CommonTotals[NameCode] > 0 then
    begin
      NamePointer := Random(CommonTotals[NameCode] - 1);

      if (CommonCalls^[NameCode, NamePointer][1] = $FF) and
        (CommonCalls^[NameCode, NamePointer][2] = $FF) and
        (CommonNames^[NameCode, NamePointer] = $F) then
      begin
        inc(NamePointer);
        Prefix := CommonCalls^[NameCode, NamePointer];
        inc(NamePointer);
        Suffix := CommonCalls^[NameCode, NamePointer];
        Call := ExpandTwoBytes(Prefix) + ExpandTwoBytes(Suffix);
        GetRidOfPrecedingSpaces(Call);
        GetRandomCall := Call;
        exit;
      end
      else
        if (CommonCalls^[NameCode, NamePointer - 1][1] = $FF) and
          (CommonCalls^[NameCode, NamePointer - 1][2] = $FF) and
          (CommonNames^[NameCode, NamePointer - 1] = $F) then
        begin
          Prefix := CommonCalls^[NameCode, NamePointer];
          inc(NamePointer);
          Suffix := CommonCalls^[NameCode, NamePointer];
          Call := ExpandTwoBytes(Prefix) + ExpandTwoBytes(Suffix);
          GetRidOfPrecedingSpaces(Call);
          GetRandomCall := Call;
          exit;
        end;

      Suffix := CommonCalls^[NameCode, NamePointer];

      repeat
        Dec(NamePointer);
      until (CommonCalls^[NameCode, NamePointer - 1][1] = $FF) and
        (CommonCalls^[NameCode, NamePointer - 1][2] = $FF) and
        (CommonNames^[NameCode, NamePointer - 1] = $F);

      Prefix := CommonCalls^[NameCode, NamePointer];

      Call := ExpandTwoBytes(Prefix) + ExpandTwoBytes(Suffix);
      GetRidOfPrecedingSpaces(Call);

      GetRandomCall := Call;
    end
    else
      GetRandomCall := 'WB6ZVC';
  end

  else
  begin
    if UnCommonTotals[NameCode] > 0 then
    begin
      NamePointer := Random(UnCommonTotals[NameCode] - 1);

      if (UnCommonCalls^[NameCode, NamePointer][1] = $FF) and
        (UnCommonCalls^[NameCode, NamePointer][2] = $FF) and
        (UnCommonNames^[NameCode, NamePointer][1] = $FF) and
        (UnCommonNames^[NameCode, NamePointer][2] = $FF) then
      begin
        inc(NamePointer);
        Prefix := UnCommonCalls^[NameCode, NamePointer];
        inc(NamePointer);
        Suffix := UnCommonCalls^[NameCode, NamePointer];
        Call := ExpandTwoBytes(Prefix) + ExpandTwoBytes(Suffix);
        GetRidOfPrecedingSpaces(Call);
        GetRandomCall := Call;
        exit;
      end
      else
        if (UnCommonCalls^[NameCode, NamePointer - 1][1] = $FF) and
          (UnCommonCalls^[NameCode, NamePointer - 1][2] = $FF) and
          (UnCommonNames^[NameCode, NamePointer - 1][1] = $FF) and
          (UnCommonNames^[NameCode, NamePointer - 1][2] = $FF) then
        begin
          Prefix := UnCommonCalls^[NameCode, NamePointer];
          inc(NamePointer);
          Suffix := UnCommonCalls^[NameCode, NamePointer];
          Call := ExpandTwoBytes(Prefix) + ExpandTwoBytes(Suffix);
          GetRidOfPrecedingSpaces(Call);
          GetRandomCall := Call;
          exit;
        end;

      Suffix := UnCommonCalls^[NameCode, NamePointer];

      repeat
        Dec(NamePointer);
      until (UnCommonCalls^[NameCode, NamePointer - 1][1] = $FF) and
        (UnCommonCalls^[NameCode, NamePointer - 1][2] = $FF) and
        (UnCommonNames^[NameCode, NamePointer - 1][1] = $FF) and
        (UnCommonNames^[NameCode, NamePointer - 1][2] = $FF);

      Prefix := UnCommonCalls^[NameCode, NamePointer];

      Call := ExpandTwoBytes(Prefix) + ExpandTwoBytes(Suffix);
      GetRidOfPrecedingSpaces(Call);

      GetRandomCall := Call;
    end
    else
      GetRandomCall := 'WA6TUT';

  end;
end;

procedure NameDictionary.InputASCIIFile;

var
  NumberNamesAdded, Column, NameColumn, CallColumn: integer;
  InputFileName, TestString: Str80;
  TempString: string;
  Name, DataBaseName, Call: CallString;
  FileRead: Text;
  Key: Char;
  Ask: boolean;

begin
//  ClrScr;
//  TextColor(Yellow);
//  WriteLnCenter('INPUT ASCII FILE TO NAME DATABASE');
//  WriteLn;
//  TextColor(Cyan);
//  WriteLn('This procedure will add name and call information from an ASCII file to the ');
//  WriteLn('name database.  The first line of the ASCII file must be a FORMAT statement');
//  WriteLn('which indicates the column number to find the callsign and the column number');
//  WriteLn('to find the name.  An example would be FORMAT 1 3, where the call is found  ');
//  WriteLn('in the first column of data and the name is found in the third column of  ');
//  WriteLn('data.  Columns may be separated by any amount of white space.');
//  WriteLn;
//  WriteLn('If the call is found in the database with a different name, you will be ');
//  WriteLn('asked which name you want to keep.');
//  WriteLn;

  InputFileName := GetResponse('Enter ASCII file to process : ');
  if InputFileName = '' then exit;

  NumberNamesAdded := 0;

  repeat
    Key := UpCase(GetKey('Do you want to be given the chance to overwrite different names? (Y/N) : '));
    if Key = EscapeKey then exit;
  until (Key = 'Y') or (Key = 'N');

  Ask := Key = 'Y';

  if OpenFileForRead(FileRead, InputFileName) then
  begin
    ReadLn(FileRead, TempString);
    TempString := UpperCase(TempString);

    TestString := RemoveFirstString(TempString);

    if UpperCase(TestString) <> 'FORMAT' then
    begin
      SHOWMESSAGE('Missing format statement at start of this file!!');

      repeat
        Key := UpCase(GetKey('Was this file generated by the name editor? (Y/N) : '));
        if (Key = EscapeKey) or (Key = 'N') then exit;
      until (Key = 'Y');
      WriteLn;

      CallColumn := 1;
      NameColumn := 2;
      Close(FileRead);
      OpenFileForRead(FileRead, InputFileName);
    end
    else
    begin
      CallColumn := RemoveFirstLongInteger(TempString);
      NameColumn := RemoveFirstLongInteger(TempString);
    end;

    while not Eof(FileRead) do
    begin
//      PinWheel;
      ReadLn(FileRead, TempString);

      Call := '';
      Name := '';
      Column := 0;

      while ((Call = '') or (Name = '')) and (TempString <> '') do
      begin
        TestString := RemoveFirstString(TempString);
        inc(Column);
        if Column = CallColumn then Call := TestString;
        if Column = NameColumn then Name := TestString;
      end;

      if (Call <> '') and (Name <> '') then
      begin
        DatabaseName := GetName(Call);

//        GoToXY(1, WhereY);

        if DataBaseName <> Name then
          if DataBaseName = '' then
          begin
            if AddName(Call, Name) then
              inc(NumberNamesAdded);
          end
          else
          begin
            WriteLn(Call, '  Database name = ', DataBaseName,
              '  Name from file = ', Name);

            if Ask then
            begin

              repeat
                Key := UpCase(GetKey('Use (D)atabase or (F)ile name? (D/F) : ' + Beep));
                if Key = EscapeKey then exit;
              until (Key = 'D') or (Key = 'F');

//              GoToXY(1, WhereY);
//              ClrEol;
//              GoToXY(1, WhereY - 1);
//              ClrEol;

              if Key = 'F' then
              begin
                DeleteName(Call);
                if AddName(Call, Name) then inc(NumberNamesAdded);
              end;
            end;
          end;
      end;
    end;

    Close(FileRead);
  end
  else
    SHOWMESSAGE('Unable to find ' + InputFileName + '!!');

  WriteLn('There were ', NumberNamesAdded, ' names added to the database.');
end;

procedure NameDictionary.Init;

var
  NameCode: integer;
  Directory: Str80;

begin
  if FileExists('\log\name\names.cmq') then
    Directory := '\log\name'
  else
  begin
    Directory := FindDirectory('NAMES.CMQ');

    if Directory = '' then
      Directory := FindDirectory('TR.OVR');
  end;

  CMQFileName := Directory + '\NAMES.CMQ';
  CMQBackUpFileName := Directory + '\NAMESBAK.CMQ';

  for NameCode := 0 to NumberArrays - 1 do
  begin
    CommonTotals[NameCode] := 0;
    UncommonTotals[NameCode] := 0;
  end;

  NumberClubCalls := 0;
end;

function NameDictionary.Load: boolean;

begin
//  WriteLn('Memory available before loading name database = ', MaxAvail, ' bytes.');

  Load := False;

{  if CommonCalls = nil then
  begin
    if SizeOf(CommonCalls^) + SizeOf(UnCommonCalls^) + SizeOf(CommonNames^) +
      SizeOf(ClubCalls^) + SizeOf(UnCommonNames^) + 10000 > MaxAvail then
    begin
      ReportError('Insufficient memory for name database.  It will not be loaded.');
      WaitForKeyPressed;
      exit;
    end;

    New(CommonCalls);
  end;
}
  if UnCommonCalls = nil then New(UncommonCalls);
  if ClubCalls = nil then New(ClubCalls);
  if CommonNames = nil then New(CommonNames);
  if UncommonNames = nil then New(UncommonNames);

  ArraysSetUp := true;

  if ReLoad then
  begin
    WriteLn('There were a total of ', TotalCalls, ' calls loaded into the name database.');
    Load := true;
  end;
end;

procedure NameDictionary.ComputeTotalCalls;

var
  NameCode, Address: integer;

begin
  TotalCalls := 0;

  for NameCode := 0 to NumberArrays - 1 do
  begin
    TotalCalls := TotalCalls + CommonTotals[NameCode] + UnCommonTotals[NameCode];

    if CommonTotals[NameCode] > 0 then
      for Address := 0 to CommonTotals[NameCode] - 1 do
        if (CommonCalls^[NameCode, Address][1] = $FF) and
          (CommonCalls^[NameCode, Address][2] = $FF) and
          (CommonNames^[NameCode, Address] = $F) then
          TotalCalls := TotalCalls - 2;

    if UnCommonTotals[NameCode] > 0 then
      for Address := 0 to UnCommonTotals[NameCode] - 1 do
        if (UnCommonCalls^[NameCode, Address][1] = $FF) and
          (UnCommonCalls^[NameCode, Address][2] = $FF) and
          (UnCommonNames^[NameCode, Address][1] = $FF) and
          (UnCommonNames^[NameCode, Address][2] = $FF) then
          TotalCalls := TotalCalls - 2;
  end;
  TotalCalls := TotalCalls + NumberClubCalls;
end;

function NameDictionary.ReLoad: boolean;

var
  FileRead: file;
  NameCode, Result1: integer;

begin
  NamesCleared := False;
  NumberClubCalls := 0;

  for NameCode := 0 to NumberArrays - 1 do
  begin
    CommonTotals[NameCode] := 0;
    UncommonTotals[NameCode] := 0;
  end;

  if FileExists(CMQFileName) then
  begin
    Assign(FileRead, CMQFileName);
    Reset(FileRead, 1);
    BlockRead(FileRead, CommonTotals, SizeOf(CommonTotals), Result1);
    BlockRead(FileRead, UncommonTotals, SizeOf(UncommonTotals), Result1);

    for NameCode := 0 to NumberArrays - 1 do
    begin
      BlockRead(FileRead, CommonCalls^[NameCode], SizeOf(CommonCalls^[NameCode]), Result1);
      BlockRead(FileRead, CommonNames^[NameCode], SizeOf(CommonNames^[NameCode]), Result1);
      BlockRead(FileRead, UncommonCalls^[NameCode], SizeOf(UncommonCalls^[NameCode]), Result1);
      BlockRead(FileRead, UncommonNames^[NameCode], SizeOf(UncommonNames^[NameCode]), Result1);
    end;

    if not Eof(FileRead) then
    begin
      BlockRead(FileRead, NumberClubCalls, SizeOf(NumberClubCalls), Result1);
      BlockRead(FileRead, ClubCalls^, SizeOf(ClubCalls^), Result1);
    end;

    Close(FileRead);
    ComputeTotalCalls;
    ReLoad := true;
  end
  else
  begin
    WriteLn;
    WriteLn('The file names.cmq was not found.', Beep);
    WriteLn;
    WriteLn('This is normal if you are just starting out with the program.  If you are');
    WriteLn('upgrading from a very old version of the program you might want to read on.');
    WriteLn;
    WriteLn('This version of the program uses a new name database format to save memory.');
    WriteLn('To put your old names (from names.cmp) into the new format, you must use a');
    WriteLn('previous version of the name editor in POST (4.18 or older) to create an');
    WriteLn('ASCII list of the names and callsigns.  Then you need to read that file');
    WriteLn('into the new database using the name editor with this version.');
    WriteLn;
    WriteLn('It is also possible names.cmq was not found because the directory it is in');
    WriteLn('does not appear in your path statement.');
    WriteLn;
//    WaitForKeyPressed;

    ReLoad := False;
  end;

  if NameMemoryDisable then DumpNames;
end;

procedure NameDictionary.MakeASCIIList(FileName: Str80);

var
  NameCode, Address: integer;
  FileWrite: Text;
  PrefixFlag: boolean;
  TempBytes: fourBYTEs;

begin
  if OpenFileForWrite(FileWrite, FileName) then
  begin
    for NameCode := 0 to NumberArrays - 1 do
    begin
      PrefixFlag := False;

      if CommonTotals[NameCode] > 0 then
        for Address := 0 to CommonTotals[NameCode] - 1 do
        begin
          if PrefixFlag then
          begin
            TempBytes[1] := CommonCalls^[Namecode, Address][1];
            TempBytes[2] := CommonCalls^[Namecode, Address][2];

            PrefixFlag := False;

            if (CommonCalls^[NameCode, Address][1] = $FF) and
              (CommonCalls^[NameCode, Address][2] = $FF) and
              (CommonNames^[Namecode, Address] = $F) then
            begin
//              ReportError('Consequetive Prefix flags found!!');
//              WriteLn('CommonArray = ', NameCode, '  Address = ', Address);
              halt;
            end;

            Continue;
          end;

          if (CommonCalls^[NameCode, Address][1] = $FF) and
            (CommonCalls^[NameCode, Address][2] = $FF) and
            (CommonNames^[Namecode, Address] = $F) then
          begin
            PrefixFlag := true;
            Continue;
          end
          else
            if Address = 0 then
            begin
//              ReportError('First entry is not prefix flag!!');
//              WriteLn('CommonArray = ', NameCode, '  Address = ', Address);
              halt;
            end;

          TempBytes[3] := CommonCalls^[Namecode, Address][1];
          TempBytes[4] := CommonCalls^[Namecode, Address][2];

          WriteLn(FileWrite,
            ExpandedString(TempBytes), ' ',
            ExpandedString(CommonNameList[CommonNames^[NameCode, Address]]));
        end;

      PrefixFlag := False;

      if UnCommonTotals[NameCode] > 0 then
        for Address := 0 to UnCommonTotals[NameCode] - 1 do
        begin
          if PrefixFlag then
          begin
            TempBytes[1] := UnCommonCalls^[Namecode, Address][1];
            TempBytes[2] := UnCommonCalls^[Namecode, Address][2];

            PrefixFlag := False;

            if (UnCommonCalls^[NameCode, Address][1] = $FF) and
              (UnCommonCalls^[NameCode, Address][2] = $FF) and
              (UnCommonNames^[Namecode, Address][1] = $FF) and
              (UnCommonNames^[Namecode, Address][2] = $FF) then
            begin
//              ReportError('Consequetive Prefix flags found!!');
//              WriteLn('UnCommonArray = ', NameCode, '  Address = ', Address);
              halt;
            end;

            Continue;
          end;

          if (UnCommonCalls^[NameCode, Address][1] = $FF) and
            (UnCommonCalls^[NameCode, Address][2] = $FF) and
            (UnCommonNames^[Namecode, Address][1] = $FF) and
            (UnCommonNames^[Namecode, Address][2] = $FF) then
          begin
            PrefixFlag := true;
            Continue;
          end
          else
            if Address = 0 then
            begin
{              ReportError('First entry is not prefix flag!!');
              WriteLn('UnCommonArray = ', NameCode, '  Address = ', Address);
              WriteLn(UnCommonCalls^[NameCode, Address][1]);
              WriteLn(UnCommonCalls^[NameCode, Address][2]);
              WriteLn(UnCommonNames^[Namecode, Address][1]);
              WriteLn(UnCommonNames^[Namecode, Address][2]);
}              halt;
            end;

          TempBytes[3] := UnCommonCalls^[Namecode, Address][1];
          TempBytes[4] := UnCommonCalls^[Namecode, Address][2];

          WriteLn(FileWrite,
            ExpandedString(TempBytes), ' ',
            ExpandedString(UnCommonNames^[NameCode, Address]));
        end;

    end;

    if NumberClubCalls > 0 then
      for Address := 0 to NumberClubCalls - 1 do
        WriteLn(FileWrite, ExpandedString(ClubCalls^[Address]), ' CLUB');

    Close(FileWrite);
  end;
end;

procedure NameDictionary.Save;

begin
  UpdateNameFile;
//  GoToXY(1, WhereY);
//  ClrEol;
  WriteLn('There were ', TotalCalls, ' calls saved.');
  WriteLn('The fullest common call array is ',
    LargestCommonArray / MaximumArrayCommonNames * 100: 3: 1,
    '% full.');

  WriteLn('The fullest uncommon call array is ',
    LargestUncommonArray / MaximumArrayUncommonNames * 100: 3: 1,
    '% full.');

  WriteLn('There are ', NumberClubCalls, ' club calls (max = ', MaxClubCalls, ').');
  Abort;
end;

function NameDictionary.TotalNumberOfCalls: integer;

begin
  TotalNumberOfCalls := TotalCalls;
end;

procedure NameDictionary.UpdateNameFile;

var
  FileWrite: file;
  NameCode: integer;
  Result: integer;

begin
  if NamesCleared then exit;

  if FileExists(CMQFileName) then
    RenameFile(CMQFileName, CMQBackUpFileName);

  Assign(FileWrite, CMQFileName);
  ReWrite(FileWrite, 1);

  BlockWrite(FileWrite, CommonTotals, SizeOf(CommonTotals), Result);
  BlockWrite(FileWrite, UncommonTotals, SizeOf(UncommonTotals), Result);

  LargestCommonArray := 0;
  LargestUncommonArray := 0;

  for NameCode := 0 to NumberArrays - 1 do
  begin
    BlockWrite(FileWrite, CommonCalls^[NameCode], SizeOf(CommonCalls^[NameCode]), Result);
    BlockWrite(FileWrite, CommonNames^[NameCode], SizeOf(CommonNames^[NameCode]), Result);
    BlockWrite(FileWrite, UncommonCalls^[NameCode], SizeOf(UncommonCalls^[NameCode]), Result);
    BlockWrite(FileWrite, UncommonNames^[NameCode], SizeOf(UncommonNames^[NameCode]), Result);

    if CommonTotals[NameCode] > LargestCommonArray then
      LargestCommonArray := CommonTotals[NameCode];

    if UncommonTotals[NameCode] > LargestUncommonArray then
      LargestUncommonArray := UncommonTotals[NameCode];

  end;

  BlockWrite(FileWrite, NumberClubCalls, SizeOf(NumberClubCalls), Result);
  BlockWrite(FileWrite, ClubCalls^, SizeOf(ClubCalls^), Result);
  Close(FileWrite);
end;

procedure NameDictionary.AddCallToPossibleList(Call: {Call} string; var PossCallList: PossibleCallRecord);

var
  Entry: integer;

begin
  GetRidOfPrecedingSpaces(Call);

  if PossCallList.NumberPossibleCalls < 12 then
  begin
    if PossCallList.NumberPossibleCalls > 0 then
      for Entry := 0 to PossCallList.NumberPossibleCalls - 1 do
        if PossCallList.List[Entry].Call = Call then
          exit;

    PossCallList.List[PossCallList.NumberPossibleCalls].Call := Call;
    PossCallList.List[PossCallList.NumberPossibleCalls].Dupe := False;
    inc(PossCallList.NumberPossibleCalls);
  end;
end;

procedure NameDictionary.MakePossibleCallList(Call: CallString; var PossCallList: PossibleCallRecord);

{ Possible calls either match prefixes and the suffixes are possible calls
  to each other, or the prefixes are possible calls and the suffixes match.}

var
  Address, NameCode, Index: integer;
  TestCall, ListSuffix, Prefix, Suffix, TempCall: CallString;
  TestBytes: fourBYTEs;
  PrefixFlag: boolean;
  ListPrefix: string;
begin
  if TotalCalls = 0 then exit;
  Call := StandardNameCallFormat(Call);

  Suffix := Copy(Call, length(Call) - 2, 3);
  Prefix := Copy(Call, 1, length(Call) - 3);

  for NameCode := 0 to NumberArrays - 1 do
  begin
    PrefixFlag := False;

    if CommonTotals[NameCode] > 0 then
    begin
      for Address := 0 to CommonTotals[NameCode] - 1 do
      begin
        if PrefixFlag then
        begin
          ListPrefix := ExpandTwoBytes(CommonCalls^[Namecode, Address]);
          GetRidOfPrecedingSpaces(ListPrefix);

          if ListPrefix = Prefix then
          begin
            for Index := Address + 1 to CommonTotals[NameCode] - 1 do
            begin
              if (CommonCalls^[NameCode, Index][1] = $FF) and
                (CommonCalls^[NameCode, Index][2] = $FF) and
                (CommonNames^[Namecode, Index] = $F) then
                Break;

              TestCall := ExpandTwoBytes(CommonCalls^[NameCode, Index]);

              if SimilarCall(TestCall, Suffix) then
                AddCallToPossibleList(Prefix + TestCall, PossCallList);
            end;
          end
          else
            if SimilarCall(ListPrefix, Prefix) then
            begin
              for Index := Address + 2 to CommonTotals[NameCode] - 1 do
              begin
                if (CommonCalls^[NameCode, Index][1] = $FF) and
                  (CommonCalls^[NameCode, Index][2] = $FF) and
                  (CommonNames^[Namecode, Index] = $F) then
                  Break;

                TestCall := ExpandTwoBytes(CommonCalls^[NameCode, Index]);

                if TestCall = Suffix then
                  AddCallToPossibleList(ListPrefix + Suffix, PossCallList);

              end;
            end;

          PrefixFlag := False;
        end;

        if (CommonCalls^[NameCode, Address][1] = $FF) and
          (CommonCalls^[NameCode, Address][2] = $FF) and
          (CommonNames^[Namecode, Address] = $F) then
        begin
          PrefixFlag := true;
          Continue;
        end;

      end;

      PrefixFlag := False;
    end;

    if UnCommonTotals[NameCode] > 0 then
    begin
      for Address := 0 to UnCommonTotals[NameCode] - 1 do
      begin
        if PrefixFlag then
        begin
          ListPrefix := ExpandTwoBytes(UnCommonCalls^[Namecode, Address]);
          GetRidOfPrecedingSpaces(ListPrefix);

          if ListPrefix = Prefix then
          begin
            for Index := Address + 1 to UnCommonTotals[NameCode] - 1 do
            begin
              if (UnCommonCalls^[NameCode, Index][1] = $FF) and
                (UnCommonCalls^[NameCode, Index][2] = $FF) and
                (UnCommonNames^[Namecode, Index][1] = $FF) and
                (UnCommonNames^[Namecode, Index][2] = $FF) then
                Break;

              TestCall := ExpandTwoBytes(UnCommonCalls^[NameCode, Index]);

              if SimilarCall(TestCall, Suffix) then
                AddCallToPossibleList(Prefix + TestCall, PossCallList);
            end;
          end
          else
            if SimilarCall(ListPrefix, Prefix) then
            begin
              for Index := Address + 2 to UnCommonTotals[NameCode] - 1 do
              begin
                if (UnCommonCalls^[NameCode, Index][1] = $FF) and
                  (UnCommonCalls^[NameCode, Index][2] = $FF) and
                  (UnCommonNames^[Namecode, Index][1] = $FF) and
                  (UnCommonNames^[Namecode, Index][2] = $FF) then
                  Break;

                TestCall := ExpandTwoBytes(UnCommonCalls^[NameCode, Index]);

                if TestCall = Suffix then
                  AddCallToPossibleList(ListPrefix + Suffix, PossCallList);

              end;
            end;

          PrefixFlag := False;
        end;

        if (UnCommonCalls^[NameCode, Address][1] = $FF) and
          (UnCommonCalls^[NameCode, Address][2] = $FF) and
          (UnCommonNames^[Namecode, Address][1] = $FF) and
          (UnCommonNames^[Namecode, Address][2] = $FF) then
        begin
          PrefixFlag := true;
          Continue;
        end;

      end;

      PrefixFlag := False;
    end;

  end;

  if NumberClubCalls > 0 then
    for Address := 0 to NumberClubCalls - 1 do
    begin
      if NumBytes(Addr(TestBytes), Addr(ClubCalls^[Address])) >= 2 then
      begin
        TempCall := ExpandedString(ClubCalls^[Address]);
        if SimilarCall(TempCall, TestCall) then
          AddCallToPossibleList(TempCall, PossCallList);
      end;
    end;

end;

begin
  ArraysSetUp := False;

  Names.Init;
  NamesCleared := False;
  Names.NameMemoryDisable := False;
  Randomize;
end.
