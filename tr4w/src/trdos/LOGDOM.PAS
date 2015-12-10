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
unit LogDom;

{$IMPORTEDDATA OFF}
interface

uses
utils_text,
  VC,
  TF,
  uMults,
  Windows,
  Tree;

//const
//  MaxNumberRemainingDomQTHs             = 3072 - 1; //2999;

type

  RemainingMultDisplayModeType = (NoRemainingMults, Erase, HiLight);

  PrefixRecPtr = ^PrefixRec;

  PrefixRec = record
    Prefix: string[6];
    DomQTH: string[6];
    Multiplier: string[6];
    NextRecord: PrefixRecPtr;
  end;

  RemainingDomMultRec = record
    ID: string[11];
    Name: string[19];
  end;

//  RemainingDomMultArrayType = array[0..MaxNumberRemainingDomQTHs] of RemainingDomMultRec {string[7 + 8]};
//  RemainingDomMultArrayPtr = ^RemainingDomMultArrayType;

  DomQTHTableObject = object

//   {?}ActiveDomQTHFile: ShortString;
    FirstPrefixRecord: array[1..37] of PrefixRecPtr; {KK1L: 6.72 36 from 26. Allows for numbers in DOM}
    LastPrefixRecord: array[1..37] of PrefixRecPtr; {KK1L: 6.72 36 from 26. Allows for numbers in DOM}
    NumberRemainingMults: integer;
//    RemainingDomMults: RemainingDomMultArrayPtr;

    procedure AddNewPrefixRecord(Prefix: Str20; DomQTH: Str20; Multiplier: Str20);

//    function GetDomMultInteger(InputString: Str20): integer;
//    function GetDomMultName(DomMultInteger: integer): Str20;

    function GetDomQTH(InputString: Str20; var Multiplier: Str10; var QTH: Str10): boolean;
    function GetStandardDomesticQTH(InputString: Str20): Str20;
//    procedure EnumDOMFILE(FileString: PShortString);
    function LoadInDomQTHFile(FileName: PChar): boolean;
    function ReadDomQTHFile(FileName: PChar; IncludedFile: boolean): boolean;
    function RecordPointerIndex(FirstLetter: Char): integer;
  end;

procedure EnumDOMFILE(FileString: PShortString);
const
  RemainingMultDisplayModeTypeSA        : array[RemainingMultDisplayModeType] of PChar = ('NONE', 'ERASE', 'HILIGHT');

var
  ActiveDomesticMult                    : DomesticMultType {= NoDomesticMults};
  DomQTHTable                           : DomQTHTableObject;
  LiteralDomesticQTH                    : boolean; //QTHString (if true) or DomesticQTH {if false}
  RemainingMultDisplayMode              : RemainingMultDisplayModeType = HiLight;
  MultipliersIsCounties                 : boolean;
implementation

uses
  ZoneCont,
  LogWind,
  MainUnit; {KK1L: DEBUG}

procedure DomQTHTableObject.AddNewPrefixRecord(Prefix: Str20; DomQTH: Str20; Multiplier: Str20);

var
  Index                                 : integer;

begin
  Index := RecordPointerIndex(Prefix[1]);

  if Index <= 0 then Exit;

  if FirstPrefixRecord[Index] = nil then
  begin
    FirstPrefixRecord[Index] := New(PrefixRecPtr);
    FirstPrefixRecord[Index]^.DomQTH := DomQTH;
    FirstPrefixRecord[Index]^.Multiplier := Multiplier;
    FirstPrefixRecord[Index]^.Prefix := Prefix;
    FirstPrefixRecord[Index]^.NextRecord := nil;
    LastPrefixRecord[Index] := FirstPrefixRecord[Index];
  end
  else
  begin
{?}
    LastPrefixRecord[Index]^.NextRecord := New(PrefixRecPtr);
    LastPrefixRecord[Index] := LastPrefixRecord[Index]^.NextRecord;
    LastPrefixRecord[Index]^.Multiplier := Multiplier;
    LastPrefixRecord[Index]^.DomQTH := DomQTH;
    LastPrefixRecord[Index]^.Prefix := Prefix;
    LastPrefixRecord[Index]^.NextRecord := nil;
  end;

end;

function DomQTHTableObject.LoadInDomQTHFile(FileName: PChar): boolean;

begin

  LoadInDomQTHFile := False;

//  if ActiveDomQTHFile = FileName then
//  begin
//    LoadInDomQTHFile := True;
//    Exit;
//  end;

  //{WLI}    Directory := FindDirectory (FileName);

  if not DomQTHTable.ReadDomQTHFile(FileName, False) then
  begin
//    ActiveDomQTHFile := '';
    Exit;
  end;

  LoadInDomQTHFile := True;
//  ActiveDomQTHFile := FileName;
end;
{
function DomQTHTableObject.GetDomMultInteger(InputString: Str20): integer;

var
  Entry                                 : integer;

begin

  strU(InputString);

  if NumberRemainingMults > 0 then
    for Entry := 0 to NumberRemainingMults - 1 do
      if InputString = UpperCase(RemainingDomMults^[Entry].ID) then
      begin
        GetDomMultInteger := Entry;
        Exit;
      end;

  GetDomMultInteger := -1;
end;

function DomQTHTableObject.GetDomMultName(DomMultInteger: integer): Str20;

begin
  if (NumberRemainingMults > 0) and (DomMultInteger >= 0) and (DomMultInteger <= NumberRemainingMults - 1) then
    GetDomMultName := RemainingDomMults^[DomMultInteger].ID
  else
    GetDomMultName := '';
end;
}

function DomQTHTableObject.GetStandardDomesticQTH(InputString: Str20): Str20;

var
  CurrentPrefixRecord                   : PrefixRecPtr;
  Index                                 : integer;

begin
  GetStandardDomesticQTH := '';

  strU(InputString);

  Index := RecordPointerIndex(InputString[1]);

  {IF (Index <= 0) OR (Index > 26) THEN Exit;}
  {KK1L: 6.72 NOTE RecordPointerIndex returns 0-36 on its own. 0=0..9=9, A=10..Z=35.}
  {                Why limit this to the numbers 0-9 and letters A-P??              }
  {                BECAUSE the procedure used is in the object NOT the one in COUNTRY9.PAS!!!}
  {                I modified local procedure to match the one in COUNTRY9.PAS so numbers can be used.}
  if (Index <= 0) or (Index > 36) then Exit; {KK1L: 6.72}

  if FirstPrefixRecord[Index] = nil then Exit;

  while InputString <> '' do
  begin
    CurrentPrefixRecord := FirstPrefixRecord[Index];

    repeat
      if CurrentPrefixRecord^.Prefix = InputString then
      begin
        GetStandardDomesticQTH := CurrentPrefixRecord^.DomQTH;
        Exit;
      end;

      if CurrentPrefixRecord <> nil then
        CurrentPrefixRecord := CurrentPrefixRecord^.NextRecord;
    until CurrentPrefixRecord = nil;

    Delete(InputString, length(InputString), 1);
  end;

end;

function DomQTHTableObject.GetDomQTH(InputString: Str20;
  var Multiplier: Str10;
  var QTH: Str10): boolean;

{ Returns TRUE if found }

var
  CurrentPrefixRecord                   : PrefixRecPtr;
  Index                                 : integer;
  PossibleUSACall                       : boolean;
  ContinentString, NumberString         : Str20;

begin

  Windows.ZeroMemory(@Multiplier, SizeOf(Multiplier)); //  Multiplier := '';
  Windows.ZeroMemory(@QTH, SizeOf(QTH)); //    QTH := '';
  GetDomQTH := False;

  strU(InputString);

  if ActiveDomesticMult = NoDomesticMults then
  begin
    QTH := InputString;
    GetDomQTH := True;
    Exit;
  end;

  if ActiveDomesticMult = RDADistrict then
  begin
    if length(InputString) = 4 then
      if InputString[1] in ['A'..'Z'] then
        if InputString[2] in ['A'..'Z'] then
          if InputString[3] in ['0'..'9'] then
            if InputString[4] in ['0'..'9'] then
            begin
              Multiplier := InputString;
              QTH := InputString;
              GetDomQTH := True;
            end;
    Exit;
  end;

  if ActiveDomesticMult = WYSIWYGDomestic then
  begin
    Multiplier := InputString;
    QTH := InputString;
    GetDomQTH := True;
    Exit;
  end;

  if ActiveDomesticMult = DOKCodes then { for WAG contest }
  begin
    for Index := 1 to length(InputString) do
    begin
      if InputString[Index] in ['A'..'Z'] then
      begin
        Multiplier := Copy(InputString, Index, 1);
        Break;
      end;
    end;

    QTH := InputString;
    GetDomQTH := Multiplier <> '';
    Exit;
  end;

  if ActiveDomesticMult = IOTADomestic then
  begin
    if (length(InputString) < 3) or (length(InputString) > 5) then Exit;

    ContinentString := UpperCase(Copy(InputString, 1, 2));
    if GetContinentFromString(ContinentString) <> UnknownContinent then
    begin
      NumberString := Copy(InputString, 3, length(InputString) - 2);

      if not StringIsAllNumbers(NumberString) then Exit;

      while length(NumberString) < 3 do
        NumberString := '0' + NumberString;

      Multiplier := ContinentString + '-' + NumberString;
      QTH := Multiplier;
      GetDomQTH := True;
    end;
  end;

  if ActiveDomesticMult = GridSquares then
  begin
    if (length(InputString) <> 4) and (length(InputString) <> 6) then
      Exit;

    if (InputString[1] < 'A') or (InputString[1] > 'R') or
      (InputString[2] < 'A') or (InputString[2] > 'R') or
      (InputString[3] > '9') or (InputString[3] < '0') or
      (InputString[4] > '9') or (InputString[4] < '0') then
      Exit;

    if length(InputString) = 6 then
      if (InputString[5] < 'A') or (InputString[5] > 'Z') or
        (InputString[6] < 'A') or (InputString[6] > 'Z') then
        Exit;

    Multiplier := Copy(InputString, 1, 4);
    QTH := InputString;
    GetDomQTH := True;
    Exit;
  end;

  if ActiveDomesticMult = GridFields then
  begin
    if (length(InputString) <> 4) or (InputString[1] < 'A') or (InputString[1] > 'R') or
      (InputString[2] < 'A') or (InputString[2] > 'R') or
      (InputString[3] > '9') or (InputString[3] < '0') or
      (InputString[4] > '9') or (InputString[4] < '0') then
      Exit;

    Multiplier := Copy(InputString, 1, 2);
    QTH := InputString;
    GetDomQTH := True;
    Exit;
  end;

  Index := RecordPointerIndex(InputString[1]);

  {IF (Index <= 0) OR (Index > 26) THEN Exit;}
  {KK1L: 6.72 NOTE RecordPointerIndex returns 0-36 on its own. 0=0..9=9, A=10..Z=35.}
  {                Why limit this to the numbers 0-9 and letters A-P??              }
  {                BECAUSE the procedure used is in the object NOT the one in COUNTRY9.PAS!!!}
  {                I modified local procedure to match the one in COUNTRY9.PAS so numbers can be used.}

  //  if (Index <= 0) or (Index > 36) then Exit; {KK1L: 6.72}
  if not (Index in [0..36]) then Exit; {KK1L: 6.72}

  if FirstPrefixRecord[Index] = nil then Exit;

//  while InputString <> '' do
  begin
    CurrentPrefixRecord := FirstPrefixRecord[Index];

    repeat
      if CurrentPrefixRecord^.Prefix = InputString then
      begin
        QTH := CurrentPrefixRecord^.DomQTH;
        Multiplier := CurrentPrefixRecord^.Multiplier;
        GetDomQTH := True;
        Exit;
      end;

      if CurrentPrefixRecord <> nil then
        CurrentPrefixRecord := CurrentPrefixRecord^.NextRecord;
    until CurrentPrefixRecord = nil;

//    Delete(InputString, length(InputString), 1);
  end;

end;

function DomQTHTableObject.RecordPointerIndex(FirstLetter: Char): integer;

var
  TempInt, Result1                      : integer;

  {BEGIN
  {IF (FirstLetter >= 'A') AND (FirstLetter <= 'Z') THEN  }
  {    BEGIN                                              }
  {    TempInt := Ord (FirstLetter) - Ord ('A') + 1;      }
  {    RecordPointerIndex := TempInt;                     }
  {    END                                                }
  {ELSE                                                   }
  {    RecordPointerIndex := -1;                          }
  {END;                                                   }
 {KK1L: 6.72 Replaced above to allow use of numbers in the DOM file}
 {           Returns a value of 1 through 36 for 0-9, A-Z.         }
begin
  Val(FirstLetter, TempInt, Result1);

  if Result1 = 0 then
  begin
    RecordPointerIndex := TempInt + 1;
    Exit;
  end
  else
    if FirstLetter in ['A'..'Z'] then
    begin
      TempInt := Ord(FirstLetter) - Ord('A') + 11;
      RecordPointerIndex := TempInt;
    end
    else
      RecordPointerIndex := -1;
end;

function RemoveDomQTHName(var FileString: ShortString {Str160}): Str80;

begin
  RemoveDomQTHName := PrecedingString(FileString, ':');
  FileString := PostcedingString(FileString, ':');
  GetRidOfPrecedingSpaces(FileString);
end;

function RemoveDomQTHID(var FileString: ShortString {Str160}): Str80;

begin
  RemoveDomQTHID := PrecedingString(FileString, ':');
  FileString := PostcedingString(FileString, ':');
  GetRidOfPrecedingSpaces(FileString);
  GetRidOfPostcedingSpaces(FileString);
end;

function GetNextPrefix(var FileString: ShortString {Str160};
  var PrefixString: ShortString {Str20}): boolean;

var
  Result1                               : integer;

begin
  GetNextPrefix := False;

  if FileString = '' then
  begin
    PrefixString := '';
    Exit;
  end;

  if StringHas(FileString, ',') then
  begin
    PrefixString := PrecedingString(FileString, ',');
    FileString := PostcedingString(FileString, ',');
    GetRidOfPrecedingSpaces(FileString);
  end
  else
  begin
    PrefixString := FileString;
    FileString := '';
  end;

  if StringHas(PrefixString, '(') then
  begin
    PrefixString := PrecedingString(PrefixString, '(');
    GetRidOfPostcedingSpaces(PrefixString);
  end;

  GetNextPrefix := PrefixString <> '';
end;

function DomQTHTableObject.ReadDomQTHFile(FileName: PChar; IncludedFile: boolean): boolean;

label
  AlreadyInList;

var
  FileRead                              : Text;
  DomQTHString, DomQTHName, Multiplier, TempString, FileString: ShortString; {: Str40;}
  RemainingMult, RecordPointer          : integer;
  CurrentRecord, NextRecord             : PrefixRecPtr;
  DomName                               : Str40;
const incfile                           = 'INCLUDE FILE';

begin
  ReadDomQTHFile := False;

  if not IncludedFile then
    NumberRemainingMults := 0;

//  if RemainingDomMults = nil then New(RemainingDomMults);
//  if not IncludedFile then Windows.ZeroMemory(RemainingDomMults, SizeOf(RemainingDomMultArrayType));

  if not IncludedFile then
    for RecordPointer := 1 to 36 do //KK1L: 6.72 1-36 from 1-26 to allow for numbers in DOM file
    begin
      if FirstPrefixRecord[RecordPointer] <> nil then
      begin
        CurrentRecord := FirstPrefixRecord[RecordPointer];
        NextRecord := FirstPrefixRecord[RecordPointer]^.NextRecord;

        while CurrentRecord <> nil do
        begin
          Dispose(CurrentRecord);
          CurrentRecord := NextRecord;
          NextRecord := CurrentRecord^.NextRecord;
        end;
      end;

      FirstPrefixRecord[RecordPointer] := nil;
      LastPrefixRecord[RecordPointer] := nil;
    end;

  if not EnumerateLinesInFile(PChar(FileName), EnumDOMFILE, False) then

//  if not OpenFileForRead(FileRead, FileName) then
  begin
    UnableToFindFileMessage(PChar(FileName));
    Exit;
  end;
{
  while not Eof(FileRead) do
  begin
    ReadLn(FileRead, FileString);

//------------------
    GetRidOfPrecedingSpaces(FileString);

    if Copy(FileString, 1, length(incfile)) = incfile then
    begin
      TempString := Copy(FileString, length(incfile) + 2, 200);
      ReadDomQTHFile(TR4W_PATH_NAME + 'DOM\' + TempString, True);
    end;

    if StringHas(FileString, '=') then
    begin
      TempString := PrecedingString(FileString, '=');

      GetRidOfPrecedingSpaces(TempString);
      GetRidOfPostcedingSpaces(TempString);

      if StringHas(TempString, '>') then
      begin
        DomQTHName := PrecedingString(TempString, '>');
        Multiplier := PostcedingString(TempString, '>');

        GetRidOfPrecedingSpaces(Multiplier);
        GetRidOfPostcedingSpaces(DomQTHName);

        if MultipliersIsCounties then
          Multiplier := DomQTHName;
              // Added in 6.30
//?

//        if NumberRemainingMults > 0 then
//          for RemainingMult := 0 to NumberRemainingMults - 1 do
//            if RemainingDomMults^[RemainingMult].ID = Multiplier then
//              goto AlreadyInList;

//        if NumberRemainingMults < MaxNumberRemainingDomQTHs then
//        begin
//          RemainingDomMults^[NumberRemainingMults].ID := Multiplier;
//          RemainingDomMults^[NumberRemainingMults].Name := Multiplier; //?
//          inc(NumberRemainingMults);
//        end;

        AlreadyInList:

      end
      else
      begin

        DomQTHName := TempString;
        Multiplier := TempString;

//        if DomQTHName <> '' then //wli
//          if NumberRemainingMults < MaxNumberRemainingDomQTHs then
//          begin
//            RemainingDomMults^[NumberRemainingMults].ID := DomQTHName;
//            RemainingDomMults^[NumberRemainingMults].Name := DomQTHName;
//            inc(NumberRemainingMults);
//          end;

      end;

      Multiplier[Ord(Multiplier[0]) + 1] := #0;
      mo.DomList.AddString(Multiplier, NoBand, NoMode, True);

      FileString := PostcedingString(FileString, '=');

      while FileString <> '' do
      begin
        if StringHas(FileString, ',') then
          DomName := PrecedingString(FileString, ',')
        else
          DomName := FileString;

        DomQTHString := UpperCase(DomName);

        GetRidOfPrecedingSpaces(DomQTHString);
        GetRidOfPostcedingSpaces(DomQTHString);

        GetRidOfPrecedingSpaces(DomName);
        GetRidOfPostcedingSpaces(DomName);

        if DomQTHString[1] <> '^' then AddNewPrefixRecord(DomQTHString, DomQTHName, Multiplier)
        else
        begin
          if length(DomName) > tRemMultsColumnWidth then tRemMultsColumnWidth := length(DomName);
//          RemainingDomMults^[NumberRemainingMults - 1].Name := Copy(DomName, 2, 32);
        end;

        if StringHas(FileString, ',') then
          FileString := PostcedingString(FileString, ',')
        else
          FileString := '';
      end;
    end;
  end;
//------------------
  Close(FileRead);
}
  //  NumberRemainingMults:=NumberRemainingMults;
  ReadDomQTHFile := True;
end;

procedure DomQTHInit;

var
  RecordPointer                         : integer;
  CurrentRecord, NextRecord             : PrefixRecPtr;

begin
  ActiveDomesticMult := NoDomesticMults;
//  DomQTHTable.ActiveDomQTHFile := '';

  for RecordPointer := 1 to 36 do {KK1L: 6.72 36 from 26. Allows for numbers in DOM file.}
  begin
    if DomQTHTable.FirstPrefixRecord[RecordPointer] <> nil then
    begin
      CurrentRecord := DomQTHTable.FirstPrefixRecord[RecordPointer];
      NextRecord := DomQTHTable.FirstPrefixRecord[RecordPointer]^.NextRecord;

      while CurrentRecord <> nil do
      begin
        CurrentRecord := nil;
        CurrentRecord := NextRecord;
        NextRecord := CurrentRecord^.NextRecord;
      end;
    end;

    DomQTHTable.FirstPrefixRecord[RecordPointer] := nil;
    DomQTHTable.LastPrefixRecord[RecordPointer] := nil;
  end;

//  DomQTHTable.RemainingDomMults := nil;
end;

procedure EnumDOMFILE(FileString: PShortString);
const incfile                           = 'INCLUDE FILE';
label
  AlreadyInList;

var
  DomQTHString, DomQTHName, Multiplier, TempString: ShortString; {: Str40;}
  RemainingMult, RecordPointer          : integer;
  CurrentRecord, NextRecord             : PrefixRecPtr;
  DomName                               : Str40;
  TempFileName                          : FileNameType;
  MultIndex                             : integer;
begin
  GetRidOfPrecedingSpaces(FileString^);

  if Copy(FileString^, 1, length(incfile)) = incfile then
  begin
    TempString := Copy(FileString^, length(incfile) + 2, 200);
    Format(TempFileName, '%sDOM\%s', TR4W_PATH_NAME, @FileString^[length(incfile) + 2]);
    DomQTHTable.ReadDomQTHFile(TempFileName, True);
  end;
//todo process ;
  if StringHas(FileString^, '=') then
  begin
    TempString := PrecedingString(FileString^, '=');

    GetRidOfPrecedingSpaces(TempString);
    GetRidOfPostcedingSpaces(TempString);

    if StringHas(TempString, '>') then
    begin
      DomQTHName := PrecedingString(TempString, '>');
      Multiplier := PostcedingString(TempString, '>');

      GetRidOfPrecedingSpaces(Multiplier);
      GetRidOfPostcedingSpaces(DomQTHName);

      if MultipliersIsCounties then
        Multiplier := DomQTHName;
              // Added in 6.30
//?

//        if NumberRemainingMults > 0 then
//          for RemainingMult := 0 to NumberRemainingMults - 1 do
//            if RemainingDomMults^[RemainingMult].ID = Multiplier then
//              goto AlreadyInList;

//        if NumberRemainingMults < MaxNumberRemainingDomQTHs then
//        begin
//          RemainingDomMults^[NumberRemainingMults].ID := Multiplier;
//          RemainingDomMults^[NumberRemainingMults].Name := Multiplier; //?
//          inc(NumberRemainingMults);
//        end;

      AlreadyInList:

    end
    else
    begin

      DomQTHName := TempString;
      Multiplier := TempString;

//        if DomQTHName <> '' then //wli
//          if NumberRemainingMults < MaxNumberRemainingDomQTHs then
//          begin
//            RemainingDomMults^[NumberRemainingMults].ID := DomQTHName;
//            RemainingDomMults^[NumberRemainingMults].Name := DomQTHName;
//            inc(NumberRemainingMults);
//          end;

    end;

    Multiplier[Ord(Multiplier[0]) + 1] := #0;
    MultIndex := mo.DomList.AddString(Multiplier, NoBand, NoMode, True);

    FileString^ := PostcedingString(FileString^, '=');

    while FileString^ <> '' do
    begin
      if StringHas(FileString^, ',') then
        DomName := PrecedingString(FileString^, ',')
      else
        DomName := FileString^;

      DomQTHString := UpperCase(DomName);

      GetRidOfPrecedingSpaces(DomQTHString);
      GetRidOfPostcedingSpaces(DomQTHString);

      GetRidOfPrecedingSpaces(DomName);
      GetRidOfPostcedingSpaces(DomName);

      if DomQTHString[1] <> '^' then DomQTHTable.AddNewPrefixRecord(DomQTHString, DomQTHName, Multiplier)
      else
      begin
        if length(DomQTHString) > tRemMultsColumnWidth then tRemMultsColumnWidth := length(DomName);
        mo.DomList.FList[MultIndex].FAltName := Copy(DomQTHString, 2, 32);
//          RemainingDomMults^[NumberRemainingMults - 1].Name := Copy(DomName, 2, 32);
      end;

      if StringHas(FileString^, ',') then
        FileString^ := PostcedingString(FileString^, ',')
      else
        FileString^ := '';
    end;
  end;

end;

//begin
  //  DomQTHInit;//можно обойтись без этого
end.
