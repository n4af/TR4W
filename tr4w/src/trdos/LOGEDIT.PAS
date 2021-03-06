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
unit LogEdit;

{ This unit contains the object EditableLog.  }

{$IMPORTEDDATA OFF}
interface

uses
  utils_text,
  uCallSignRoutines,
  uCTYDAT,
  uMults,
  uCallsigns,
  Tree,
  TF,
  VC,
  uCommctrl,
  Messages,
  LogWind,
  LogDupe,
  LogStuff,
  ZoneCont,
  //Country9,
  LogCW,
  LOGDVP,
  LogDom,
  LogK1EA,
  LogGrid,
  LogNet,
  LogSCP,
  LogRadio,
  Windows
  ;

const
  MULT_DX = 1;
  MULT_PREFIX = 2;
  MULT_ZONE = 4;
  MULT_DOM = 8;
type
  EditableLog = object
    //    LogEntries: LogEntryArray;

    function CallIsADupe(var Call: CallString; Band: BandType; Mode: ModeType):
      boolean;
    //    procedure CancelOutMultsThatAreInEditableWindow(var Exchange: ContestExchange);
    //    function CallIsInEditableLog(Call: CallString; Band: BandType; Mode: ModeType): boolean;

    procedure CreateModeSpecificDomesticMultiplierInfo(DomQTH: Str20; Mode:
      ModeType; var OutputString: integer {Str160});

    function GetMultArray(Call: CallString; Mode: ModeType; TempMult: Str10):
      Cardinal;

    procedure CreateModeSpecificMultiplierInfo(
      Call: CallString;
      TempMult: Str10;
      Mode: ModeType;
      var OutputString: Cardinal {Str160});

    procedure CreateModeSpecificQSOInfo(Call: CallString;
      Mode: ModeType;
      var OutputString: integer);

    procedure DeleteLastLogEntry;

    procedure DetermineIfNewDomesticMult(DomesticMult: Str20;
      Band: BandType;
      Mode: ModeType;
      var MultString: integer);

    function DetermineIfNewMult(Call: CallString; Band: BandType; Mode:
      ModeType): boolean;

    procedure DisplayGridMap(Band: BandType; Mode: ModeType);

    procedure DisplayVisibleDupeSheet(Band: BandType; Mode: ModeType);

    procedure DoPossibleCalls(Call: CallString);

    procedure EditLog;
    function EditableLogIsEmpty: boolean;

    //  function GetInitialExchangeFromEditableLog(Call: CallString): Str40;

    procedure SetMultStatus(Call: CallString; TempMult: Str10);

    //    procedure IncrementQSOPointsWithContentsOfEditableWindow(var QPoints: LONGINT);
//      procedure IncrementQSOTotalsWithContentsOfEditableWindow(var QSOTotals: QSOTotalArray);
    //    procedure IncrementMultTotalsWithContentsOfEditableWindow(var MTotals: MultTotalArrayType);
    //    function IsNotFoundInEditableWindow(ActiveGrid: Str10; Band: BandType; Mode: ModeType): boolean;

    function LastEntry(InMyLog: boolean; let: LastEntryType): CallString;
    function LastName(Entry: integer): Str20;

    //    procedure GeneratePartialCallList(InputCall: CallString;      Band: BandType;      Mode: ModeType;      var PossCallList: PossibleCallRecord);

        //    function NumberNamesSentInEditableLog: integer;

        //    function PushLogEntry(NewEntry: str80): str80;
    procedure ProcessMultipliers(var RXData: ContestExchange);
    procedure PutLogEntryIntoSheet(var LogEntry: string {Str80});

    //    procedure SetUpEditableLog;
    procedure ShowDomesticMultiplierStatus(DomesticQTH: Str10); // Gav 4.44.8
    procedure ShowMissingMultiplierReport(h: HWND);
    procedure ShowMultiplierStatus(Call: CallPtr {CallString});
    procedure ShowRemainingMultipliers;
    procedure ShowRemMultsInWindow(Window: WindowsType; rmt:
      RemainingMultiplierType);
    //    procedure ShowRemainingMultipliers2;
    procedure ShowQSOStatus(Call: CallPtr); overload;
    procedure ShowQSOStatus(Call: string); overload;
    //    procedure SuperCheckPartial(Call: CallString; Automatic: boolean; Radio: RadioType); {KK1L: 6.73 Added Radio for SO2R}
    function SuperCheckPartial(Call: CallString; Automatic: boolean; Radio:
      RadioPtr {RadioType}): boolean; {KK1L: 6.73 Added Radio for SO2R}
    //    procedure UpdateTempLogFile;
  end;

var
  VisibleLog: EditableLog;
  LastSCPCall: CallString;

  QTotals: QSOTotalArray;
  //  MTotals                               : MultTotalArrayType;

  OriginalTextMode: integer;
  RememberHeap: Pointer;
  {
    RemainingMults                        : RemainingMultList;
    RemainingMultsDX                      : RemainingMultListPointer;
    RemainingMultsDOM                     : RemainingMultListPointer;
    RemainingMultsZone                    : RemainingMultListPointer;
  }
  CleanSweep: boolean;

procedure AddQTCToQTCBuffer(var QTCBuffer: LogEntryArray; QTCString: Str80;
  Message: integer);

//procedure BandDown;
//procedure BandUp;
procedure BandDownOrUp(Direction: DirectionType);
procedure CleanUpDisplay;
function DetermineQTCNumberAndQuanity(InputString: Str80; var QTCNumber:
  integer; var Quantity: integer): boolean;
procedure TimeAndDateSet;
function InitialExchangeEntry(Call: CallString): Str80;
procedure MoveGridMap(Key: Char);
function QuickEditResponseWithPartials(Prompt: Str80; MaxInputLength: integer):
  Str80;
procedure Send88Message;
procedure ShowStationInformation(Call: CallPtr {CallString});
function TotalContacts: integer;
function TotalCWContacts: integer;
function TotalPhoneContacts: integer;
function TotalScore: LONGINT;
procedure SetPrefix(var RData: ContestExchange {Ptr});
{KK1L: 6.64 Added to keep BM up to date with changes made while logging}
procedure UpdateBandMapDupeStatus(RXCall: CallString; RXBand: BandType; RXMode:
  ModeType; MakeDupe: boolean);
//procedure UpdateTotals_old;

implementation

uses
  //OZCHR,
//  uRemMults_DX,
//  uRemMults_DOM,
//  uRemMults_Zone,
  uNet,
  uMaster,
  PostUnit,
  //  LOGMENU,
  uTotal,
  LOGSUBS2,
  uRemMults,
  uBandmap,
  MainUnit; {KK1L: 6.71 attempt to get POST to compile. Moved here from INTERFACE section. Was not there in original}

var
  SCPScreenFull: boolean;

function TotalCWContacts: integer;

var
  Band: BandType;
  Total: integer;
  TempQSOTotals: QSOTotalArray;

begin
  TempQSOTotals := QSOTotals;

  //  VisibleLog.IncrementQSOTotalsWithContentsOfEditableWindow(TempQSOTotals);

  Total := 0;

  for Band := Band160 to Band10 do
    Total := Total + TempQSOTotals[Band, CW];

  TotalCWContacts := Total;
end;

function TotalPhoneContacts: integer;

var
  Band: BandType;
  Total: integer;
  TempQSOTotals: QSOTotalArray;

begin
  TempQSOTotals := QSOTotals;

  //  VisibleLog.IncrementQSOTotalsWithContentsOfEditableWindow(TempQSOTotals);

  Total := 0;

  for Band := Band160 to Band10 do
    Total := Total + TempQSOTotals[Band, Phone];

  TotalPhoneContacts := Total;
end;

procedure Send88Message;

begin
  if SeventyThreeMessageSent then
    Exit;

  SendStringAndStop('88 ' + MyCall + ' TEST');
end;

procedure CleanUpDisplay;
var
  w: TMainWindowElement;
begin
  DisplayBandMode(ActiveBand, ActiveMode, False);

  for w := Low(TMainWindowElement) to High(TMainWindowElement) do
    if TWindows[w].mweI = 1 then
      SetMainWindowText(w, nil);
  {
    Windows.SetWindowText(w h[mweCountryName], nil);
    Windows.SetWindowText(w h[mweBeamHeading], nil);
    Windows.SetWindowText(w h[mweLocator], nil);
    Windows.SetWindowText(w h[mweName], nil);
    Windows.SetWindowText(w h[mweUserInfo], nil);
    Windows.SetWindowText(w h[mweLocalTime], nil);
  }
  DisplayNamePercentage;

end;

function TotalContacts: integer;
begin

  if ServerSerialNumber <> 0 then
  begin
    Result := ServerSerialNumber - 1;
    Exit;
  end;

  if QSONumberByBand then
    Result := QSOTotals[ActiveBand, Both]
  else
    Result := QSOTotals[AllBands, Both];
  logger.debug('In TotalContacts, returning ' + IntToStr(Result));
end;

procedure BandDownOrUp(Direction: DirectionType);
begin

  if (MultipleBandsEnabled) or (TotalContacts = 0) then
  begin
    if CommandUseInactiveRadio then
      //KK1L: 6.73 Band change on inactive radio via command
    begin
      PutRadioOutOfSplit(InactiveRadio); // n4af 4.46.5
      BandChange(InActiveRadioPtr.BandMemory {BandMemory[InactiveRadio]},
        Direction);
    end
    else
    begin
      PutRadioOutOfSplit(ActiveRadio); // n4af 4.46.5
      BandChange(ActiveBand, Direction);
      if QSOByBand then
        CallsignsList.DisplayDupeSheet(ActiveRadioPtr);
      if MultByBand then
        VisibleLog.ShowRemainingMultipliers;
      BandMapBand := ActiveBand;
      DisplayBandMap;
      ShowSpotInfo;
      if QSONumberByBand then
        DisplayNextQSONumber;
    end;
  end;
end;


function EditableLog.CallIsADupe(var Call: CallString; Band: BandType; Mode:
  ModeType): boolean;

var
  TempMode: ModeType;
  TempBand: BandType;
  Index: integer;
begin
  CallIsADupe := False;
  if Call = '' then
    Exit;

  if (ActiveDomesticMult = GridSquares) and RoverCall(Call) then
    Exit;

  if QSOByMode then
    TempMode := Mode
  else
    TempMode := Both;
  if QSOByBand then
    TempBand := Band
  else
    TempBand := AllBands;
  //  call[length(call)+1] := #0;
  Result := CallsignsList.CallsignIsDupe(Call, TempBand, TempMode, Index);
end;

function ComputeGrid(Row: integer; col: integer; NumberRows: integer): Str10;

var
  HomeX, HomeY, CharValue, Address: integer;
  Grid: Str10;

begin
  HomeX := 8;
  HomeY := NumberRows div 2;

  if (Row = HomeY) and (col = HomeX) then
  begin
    ComputeGrid := GridMapCenter;
    Exit;
  end;

  Grid := GridMapCenter;

  if col < HomeX then
  begin
    for Address := HomeX - 1 downto col do
    begin
      CharValue := Ord(Grid[3]);
      dec(CharValue);

      if CharValue >= Ord('0') then
        Grid[3] := CHR(CharValue)
      else
      begin
        Grid[3] := '9';

        CharValue := Ord(Grid[1]);
        dec(CharValue);

        if CharValue >= Ord('A') then
          Grid[1] := CHR(CharValue)
        else
          Grid[1] := 'R';
      end;

    end;
  end

  else
    for Address := HomeX + 1 to col do { Row > HomeX }
    begin
      CharValue := Ord(Grid[3]);
      inc(CharValue);

      if CharValue <= Ord('9') then
        Grid[3] := CHR(CharValue)
      else
      begin
        Grid[3] := '0';

        CharValue := Ord(Grid[1]);
        inc(CharValue);

        if CharValue <= Ord('R') then
          Grid[1] := CHR(CharValue)
        else
          Grid[1] := 'A';
      end;
    end;

  if Row > HomeY then
  begin
    for Address := HomeY + 1 to Row do
    begin
      CharValue := Ord(Grid[4]);
      dec(CharValue);

      if CharValue >= Ord('0') then
        Grid[4] := CHR(CharValue)
      else
      begin
        Grid[4] := '9';

        CharValue := Ord(Grid[2]);
        dec(CharValue);

        if CharValue >= Ord('A') then
          Grid[2] := CHR(CharValue)
        else
          Grid[2] := 'R';
      end;

    end;
  end

  else
    for Address := HomeY - 1 downto Row do
    begin
      CharValue := Ord(Grid[4]);
      inc(CharValue);

      if CharValue <= Ord('9') then
        Grid[4] := CHR(CharValue)
      else
      begin
        Grid[4] := '0';

        CharValue := Ord(Grid[2]);
        inc(CharValue);

        if CharValue <= Ord('R') then
          Grid[2] := CHR(CharValue)
        else
          Grid[2] := 'A';
      end;
    end;

  ComputeGrid := Grid;
end;
{
function EditableLog.IsNotFoundInEditableWindow(ActiveGrid: Str10; Band: BandType; Mode: ModeType): boolean;

var
  Entry                                 : integer;
  MultString                            : string; //Str20;

begin
  for Entry := 1 to NumberEditableLines do
    if (Band = GetLogEntryBand(LogEntries[Entry])) or not MultByBand then
      if (Mode = GetLogEntryMode(LogEntries[Entry])) or not MultByMode then
      begin
        MultString := UpperCase(Copy(LogEntries[Entry], LogEntryMultAddress, LogEntryMultWidth));
        GetRidOfPostcedingSpaces(MultString);

        if ActiveGrid = MultString then
        begin
          IsNotFoundInEditableWindow := False;
          Exit;
        end;
      end;

  IsNotFoundInEditableWindow := True;
end;
}

procedure MoveGridMap(Key: Char);

begin
  case Key of
    DownArrow:
      begin
        if GridMapCenter[4] <> '0' then
          GridMapCenter := Copy(GridMapCenter, 1, 3) + CHR(Ord(GridMapCenter[4])
            - 1)
        else
          GridMapCenter := GridMapCenter[1] + CHR(Ord(GridMapCenter[2]) - 1) +
            GridMapCenter[3] + '9';
      end;

    UpArrow: ;

    ControlLeftArrow:
      begin
        if GridMapCenter[3] <> '0' then
          GridMapCenter := Copy(GridMapCenter, 1, 2) + CHR(Ord(GridMapCenter[3])
            - 1) +
            GridMapCenter[4]
        else
          GridMapCenter := CHR(Ord(GridMapCenter[1]) - 1) + GridMapCenter[2] +
            '9' + GridMapCenter[4];
      end;

    ControlRightArrow:
      begin
        if GridMapCenter[3] <> '9' then
          GridMapCenter := Copy(GridMapCenter, 1, 2) + CHR(Ord(GridMapCenter[3])
            + 1) +
            GridMapCenter[4]
        else
          GridMapCenter := CHR(Ord(GridMapCenter[1]) + 1) + GridMapCenter[2] +
            '0' + GridMapCenter[4];
      end;
  end;
end;

procedure EditableLog.DisplayGridMap(Band: BandType; Mode: ModeType);

begin

end;

procedure EditableLog.DisplayVisibleDupeSheet(Band: BandType; Mode: ModeType);

begin
  //  CallsignsList.DisplayDupeSheet(Band, Mode);

end;

function EditableLog.EditableLogIsEmpty: boolean;

begin
  {
    EditableLogIsEmpty := False;

    for Entry := 1 to 5 do
      if GetLogEntryCall(VisibleLog.LogEntries[Entry]) <> '' then Exit;

    EditableLogIsEmpty := True;
   }
end;

procedure EditableLog.EditLog;

{ This procedure gets called when the operator wants to edit the log.
  Wordstar type cursor commands are supported.  The contents of the
  LogEntries array will be updated along with the display.  There is
  no checking for syntax or new mults.  When the entry goes from the
  editable log window to the LogFileName file, it will be looked at for
  proper syntax and possible new multipliers.  Also, dupes are checked
  at that time.                                                         }

begin
  //if VisibleDupesheetEnable then
//  SetUpEditableLog;
//  QuickDisplay('You are editing the logsheet.  Use escape to quit.');
//  EditWindowEditor(LogEntries, LogEntryCallAddress, NumberEditableLines, ChangesMade);
//  if ChangesMade then UpdateTempLogFile;
  //  if ActiveWindow <> QuickCommandWindow then RemoveWindow(QuickCommandWindow);
end;

procedure EditableLog.ProcessMultipliers(var RXData: ContestExchange);

{ This procedure will set the appropriate multiplier flags for a QSO
  that is ready to be put into the editable log.  It will check both the
  multiplier arrays in LogDupe and the contents of the editable log for
  previous occurances of multipliers.                                   }

begin
  if RXData.InhibitMults then
    begin
    logger.Error('ProcessMultipliers called while RXData.InhibitMults is set - Exiting...');
    Exit;
    end;

  Sheet.SetMultFlags(RXData);

  //  CancelOutMultsThatAreInEditableWindow(RXData);

  if MultiplierAlarm then
    if RXData.DomesticMult or RXData.DXMult or RXData.PrefixMult or
      RXData.ZoneMult then
      DoABeep(BeepCongrats);
end;

procedure EditableLog.PutLogEntryIntoSheet(var LogEntry: string {Str80});

{ This procedure will look at the log entry string passed to it and
  see if any multiplier flags need to be set.  It will not erase any
  that are there.  After adding any that need to be added, it will
  add it to the multiplier arrays and increment the totals.  The
  correct string is returned.  This procedure should only be used for
  entries that have been popped off the editable log stack as it does
  not look for any mults in the editable log.  Use the ProcessMultipliers
  procedure for new entries into the editable log.                        }

begin

end;

procedure EditableLog.DetermineIfNewDomesticMult(DomesticMult: Str20; Band:
  BandType; Mode: ModeType; var MultString: integer {Str80});

var
  TempRXData: ContestExchange;

begin
  MultString := 0;
  Windows.ZeroMemory(@TempRXData, SizeOf(ContestExchange));
  TempRXData.Band := Band;
  TempRXData.Mode := Mode;
  SetExtendedModeFromMode(TempRXData);
  TempRXData.QTHString := DomesticMult;

  if FoundDomesticQTH(TempRXData) then
  begin
    Sheet.SetMultFlags(TempRXData);
    if TempRXData.DomesticMult then
      MultString := 1; //TempRXData.DomMultQTH
  end;
end;

function EditableLog.DetermineIfNewMult(Call: CallString; Band: BandType; Mode:
  ModeType): boolean;

{ This procedure will try and determine the multiplier for the call passed
  to it.  If something can be figured out, and it appears to be a new
  multiplier for the band/mode specified, it will be returned in the
  mult string.  Otherwise, a null string will be returned.  }

var
  OutputValue: Cardinal;
  TempMode: ModeType;
  TempBand: BandType;
begin
  OutputValue := 0;

  if not MultByMode then
    TempMode := Both
  else
    TempMode := Mode;
  if not MultByBand then
    TempBand := AllBands
  else
    TempBand := Band;
  OutputValue := GetMultArray(Call, TempMode, '');
  Result := (OutputValue and (1 shl Cardinal(TempBand))) <> 0;
 
  //  Exit;

  //  ClearContestExchange(TempRXData);
  //  LocateCall(Call, TempRXData.QTH, True);
  //  TempRXData.Band := Band;
  //  TempRXData.Mode := Mode;

  //  MultString := 0 {''};
  //  if MarineOrAirMobileStation(Call) and (NoMultMarineMobile) then Exit; {KK1L: 6.68 Brute force no count /MM or /AM}
  //  if DoingDXMults {and (ActiveDXMult <> NoCountDXMults)} then GetDXQTH(TempRXData);
  //  if DoingPrefixMults then SetPrefix(TempRXData);

  //  GetDomesticQTHFromCallsign
  //  if Contest = RUSSIANDX then
  //    if RussianID(TempRXData.QTH.CountryID) then
  //      TempRXData.DomMultQTH := GetRussiaOblastID(Call);
  {
    if Contest = UKRAINIAN then
      if TempRXData.QTH.Country = URCountry then
        TempRXData.DomMultQTH := 'KV';
  }
  //  if Contest = CUPURAL then
  //  begin
  //    TempRXData.DomMultQTH := CountryTable.GetGrid(Call, CountryID);
  //    TempRXData.DomMultQTH[0] := #2;
  //    PWORD(@TempRXData.DomMultQTH[1])^ := LoWord(TempCardinal);
  //  end;

  //  if DoingZoneMults then TempRXData.Zone := TempRXData.QTH.Zone;

  //  Sheet.SetMultFlags(TempRXData);

  //  if TempRXData.DXMult then MultString := MultString + MULT_DX; //TempRXData.DXQTH + ' ';
  //  if TempRXData.PrefixMult then MultString := MultString + MULT_PREFIX; //TempRXData.Prefix + ' ';
  //  if TempRXData.ZoneMult then MultString := MultString + MULT_ZONE; //IntToStr(TempRXData.Zone);

  //  if Contest in [RUSSIANDX, CUPURAL, UKRAINIAN] then
  //  if TempRXData.DomesticMult then MultString := MultString + MULT_DOM;

end;

procedure EditableLog.CreateModeSpecificDomesticMultiplierInfo(DomQTH: Str20;
  Mode: ModeType; var OutputString: integer {Str160});

var
  Band: BandType;
  Mult: integer;
begin
  OutputString := 0;

  //  if Mode <> Both then    OutputString := OutputString + ModeString[Mode] + ': ';

  if MultByBand then
  begin
    if ActiveBand <= Band10 then
      Band := Band160
    else
      Band := Band6;
  end
  else
    Band := AllBands;

  while True do
  begin
    DetermineIfNewDomesticMult(DomQTH, Band, Mode, Mult);
    if Mult <> 0 then

      OutputString := OutputString or (1 shl integer(Band))
    else
      OutputString := OutputString and not (1 shl integer(Band));
    {
        if Mult <> '' then
        begin
          if Band <= Band10 then
            OutputString := OutputString + BandStringsArray[Band]
          else
            if Band = Band6 then
              OutputString := OutputString + '6 '
            else
              if Band = Band2 then
                OutputString := OutputString + '2 '
              else
                OutputString := OutputString + BandStringsArray[Band] + ' ';

        end
        else
          if Band <= Band10 then
            OutputString := OutputString + '   '
          else
            if (Band = Band6) or (Band = Band2) then
              OutputString := OutputString + '  '
            else
              OutputString := OutputString + '    ';
    }
    case Band of
      AllBands: Exit;
      Band160: Band := Band80;
      Band80: Band := Band40;
      Band40: Band := Band20;
      Band20: Band := Band15;
      Band15: Band := Band10;
      Band10: Exit;

      Band6: Band := Band2;
      Band2: Band := Band222;
      Band222: Band := Band432;
      Band432: Band := Band902;
      Band902: Band := Band1296;
      Band1296: Exit;
      //      Band1296: Band := Band2304;
      //     Band2304: Band := Band3456;
      //      Band3456: Band := Band5760;
      //      Band5760: Band := Band10G;
      //      Band10G: Band := Band24G;
      //      Band24G: Band := BandLight;
      //      BandLight: Exit;
    end;
  end;
end;

procedure EditableLog.ShowDomesticMultiplierStatus(DomesticQTH: Str10);
  //Gav 4.44.8  New procedure to display Domestic Mult Status
var
  DomesticQTHtemp: string;
begin

  if length(DomesticQTH) < 2 then
     begin
     logger.warn('ShowDomesticMultiplierStatus called with DomesticQTH length < 2 %s   Exiting...',[DomesticQTH]);
     Exit;
     end;
  DomesticQTHtemp := DomesticQTH;

  Format(wsprintfBuffer, TC_MULTNEEDSFOR, PChar(DomesticQTHtemp));

  logger.debug('[ShowDomesticMultiplierStatus] MultNeedsHeader field set to %s',[DomesticQTHtemp]);
  SetMainWindowText(mweMultNeedsHeader, wsprintfBuffer);
  SetMultStatus('', DomesticQTH);
  logger.debug('[ShowDomesticMultiplierStatus] MultStatus set to DomesticQTH of %s',[DomesticQTH]);
end;

procedure EditableLog.ShowMultiplierStatus(Call: CallPtr {CallString});
begin
  if length(Call^) < 2 then
     begin
     logger.warn('ShowDomesticMultiplierStatus called with DomesticQTH length < 2 %s   Exiting...',[Call^]);
     Exit;
     end;
  //  tLB_RESETCONTENT(MultiplierInformationWindowHandle);
  {
    asm
      mov eax, Call
      inc eax
      push eax
    end;
  }
  Format(wsprintfBuffer, TC_MULTNEEDSFOR, PChar(integer(Call) + 1));
  logger.debug('[ShowMultiplierStatus] MultNeedsHeader field set to %s',[Call^]);
  SetMainWindowText(mweMultNeedsHeader, wsprintfBuffer);
  SetMultStatus(Call^, '');
end;

function EditableLog.GetMultArray(Call: CallString; Mode: ModeType; TempMult:
  Str10): Cardinal;
var
  TempCardinal: Cardinal;
  TempRXData: ContestExchange;
  Index: integer;
  TempDomMult: Str10;
  TempID: DXMultiplierString;
  Zone: Byte;
begin
  Result := 0;

  if DoingDXMults or DoingZoneMults or DoingPrefixMults then
  begin
    Windows.ZeroMemory(@TempRXData, SizeOf(TempRXData));
    ctyLocateCall(Call, TempRXData.QTH);
    if TempRXData.QTH.Country = UNKNOWN_COUNTRY then
      Exit;
  end;

  if DoingDXMults then
  begin
    TempRXData.DXQTH := '';
    TempRXData.Callsign := Call;
    GetDXQTH(TempRXData);
    if TempRXData.DXQTH <> '' then
    begin

      TempCardinal := $FFFFFFFF xor
        mo.DXMultsArray[TempRXData.QTH.Country][Mode];
      Result := TempCardinal or Result;

      if DXCCMultByBand = dmbbAllBand then
        if mo.DXMultsArray[TempRXData.QTH.Country][Mode] > 0 then
          Result := 0;

    end;
  end;

  if DoingZoneMults then
  begin
    if ActiveZoneMult in [CQZones, ITUZones] then
    begin

      if ActiveZoneMult = CQZones then
        Zone := ctyGetCQZone(Call)
      else
        Zone := ctyGetITUZone(Call);

      TempCardinal := $FFFFFFFF xor
        mo.ZoneMultsArray[{TempRXData.QTH.}Zone][Mode];
      Result := TempCardinal or Result;
    end;
  end;

  if DoingPrefixMults then
  begin
    TempRXData.Callsign := Call;
    SetPrefix(TempRXData);
    if TempRXData.Prefix <> '' then
    begin
      if mo.PrfList.FindMult(TempRXData.Prefix, Index) then
      begin
        TempCardinal := $FFFFFFFF xor mo.PrfList.FList[Index].FArray[Mode];
          //1000000000000000000000
        Result := TempCardinal or Result;
      end
      else
        Result := $FFFFFFFF or Result;
    end;
  end;

  if DoingDomesticMults then
  begin

    TempDomMult := '';
    if TempMult <> '' then
      TempDomMult := TempMult
    else
    begin
      case Contest of
        RUSSIANDX, RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB:
          if RussianID(Call) then
            TempDomMult := GetRussiaOblastID(Call);

        CUPURAL:
          TempDomMult := ctyGetGrid(Call, TempID);

        RDA:
          if RussianID(Call) then
            TempDomMult := CallsignsList.GetIniitialExchange(Call);

        YODX:
          if Call[1] = 'Y' then
            TempDomMult := CallsignsList.GetIniitialExchange(Call);
        {
                WAG:
                  if Call[1] = 'D' then
                    TempDomMult := CallsignsList.GetIniitialExchange(Call);
        }
      end;
    end;

    if TempDomMult <> '' then
    begin
      if mo.DomList.FindMult(TempDomMult, Index) then
      begin
        if DomesticMultByBand = dmbbAllBand then
          if mo.DomList.FList[Index].FArray[Mode] > 0 then
            Exit;

        TempCardinal := $FFFFFFFF xor mo.DomList.FList[Index].FArray[Mode];
        Result := TempCardinal or Result;

      end
      else
        Result := $FFFFFFFF or Result;
    end;
  end;
end;

procedure EditableLog.CreateModeSpecificMultiplierInfo(Call: CallString;
  TempMult: Str10; Mode: ModeType; var OutputString: Cardinal {Str160});
var
  nCmndShow: integer;
  //  QTH                                   : QTHRecord;

begin

  OutputString := GetMultArray(Call, Mode, TempMult);

  if MultByMode and (Mode <> ActiveMode) then
    Exit;

  nCmndShow := SW_HIDE;

  if MultByBand then
  begin
    if (OutputString and (1 shl integer(ActiveBand))) <> 0 then
      nCmndShow := SW_SHOWNORMAL;
  end
  else
    {//    nCmndShow := integer(OutputString = 0);} if (OutputString and (1 shl
      integer(AllBands))) <> 0 then
      nCmndShow := SW_SHOWNORMAL;

  DispalayNewMult(nCmndShow);
end;



procedure EditableLog.SetMultStatus(Call: CallString; TempMult: Str10);
var
  OutputValue: Cardinal;
  Band: BandType;
begin
   logger.debug('[SetMultStatus] Entered with call = %s and TempMult = %s',[Call, TempMult]);
  if NumberDifferentMults = 0 then
    begin
    logger.debug('[SetMultStatus] Exiting early because NumberDifferentMults = 0');
    Exit;
    end;

  if MultByMode then
  begin
    CreateModeSpecificMultiplierInfo(Call, TempMult, CW, OutputValue);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(MultsWindowsHandles1[Band], integer((OutputValue and (1
        shl integer(Band))) <> 0));

    CreateModeSpecificMultiplierInfo(Call, TempMult, Phone, OutputValue);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(MultsWindowsHandles2[Band], integer((OutputValue and (1
        shl integer(Band))) <> 0))

  end
  else
  begin
    CreateModeSpecificMultiplierInfo(Call, TempMult, Both, OutputValue);

    if not MultByBand then
      if (OutputValue and (1 shl integer(AllBands))) <> 0 then
        OutputValue := $FFFFFFFF
      else
        OutputValue := 0;

    for Band := Band160 to Band10 do
      Windows.ShowWindow(MultsWindowsHandles1[Band], integer((OutputValue and (1
        shl integer(Band))) <> 0))

  end;
end;

procedure EditableLog.CreateModeSpecificQSOInfo(Call: CallString; Mode:
  ModeType; var OutputString: integer);

var
  Band: BandType;

begin
  //  if Mode <> Both then    OutputString := OutputString + ModeString[Mode] + ': ';
  OutputString := 0;
  if QSOByBand then
  begin
    if ActiveBand <= Band10 then
      Band := Band160
    else
      Band := Band6;
  end
  else
    Band := AllBands;

  while True do
  begin
    if not VisibleLog.CallIsADupe(Call, Band, Mode)
      {or CallIsInEditableLog(Call, Band, Mode)} then

      OutputString := OutputString or (1 shl integer(Band))
    else
      OutputString := OutputString and not (1 shl integer(Band));

    {
        begin
          if Band <= Band10 then
            OutputString := OutputString + '   '
          else
            if (Band = Band6) or (Band = Band2) then
              OutputString := OutputString + '  '
            else
              OutputString := OutputString + '    ';
        end
        else

          if Band <= Band10 then
            OutputString := OutputString + BandStringsArray[Band]
          else
            if Band = Band6 then
              OutputString := OutputString + '6 '
            else
              if Band = Band2 then
                OutputString := OutputString + '2 '
              else
                OutputString := OutputString + BandStringsArray[Band] + ' ';
    }
    case Band of
      AllBands: Exit;
      Band160: Band := Band80;
      Band80: Band := Band40;
      Band40: Band := Band20;
      Band20: Band := Band15;
      Band15: Band := Band10;
      Band10: Exit;

      Band6: Band := Band2;
      Band2: Band := Band222;
      Band222: Band := Band432;
      Band432: Band := Band902;
      Band902: Band := Band1296;
      Band1296: Exit;
      {
            Band1296: Band := Band2304;
            Band2304: Band := Band3456;
            Band3456: Band := Band5760;
            Band5760: Band := Band10G;
            Band10G: Band := Band24G;
            Band24G: Band := BandLight;
            BandLight: Exit;
      }
    end;
  end;
end;

procedure EditableLog.ShowQSOStatus(Call: string);
var
  OutputString: integer;
  Band: BandType;
begin
  logger.debug('[ShowQSOStatus] Called with call of [%s]',[Call]);
  if length(Call) < 3 then
    Exit;

  Format(wsprintfBuffer, TC_QSONEEDSFOR, PChar(integer(Call)));
  SetMainWindowText(mweQSONeedsHeader, wsprintfBuffer);
  //  tSetWindowText(QIHeaderWindowHandle, ' QSO needs for ' + Call);

  if QSOByMode then
  begin
    CreateModeSpecificQSOInfo(Call, CW, OutputString);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(QSONeedWindowsHandles1[Band], integer((OutputString and
        (1 shl integer(Band))) <> 0));

    CreateModeSpecificQSOInfo(Call, Phone, OutputString);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(QSONeedWindowsHandles2[Band], integer((OutputString and
        (1 shl integer(Band))) <> 0));

  end
  else
  begin
    CreateModeSpecificQSOInfo(Call, Both, OutputString);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(QSONeedWindowsHandles1[Band], integer((OutputString and
        (1 shl integer(Band))) <> 0));
  end;


end;

procedure EditableLog.ShowQSOStatus(Call: CallPtr);

{ This procedure will display the QSO status for the call specified.
  It will look at any dupe sheets it can find in memory.              }

var
  OutputString: integer;
  Band: BandType;
begin

  if length(Call^) < 3 then
    Exit;

  Format(wsprintfBuffer, TC_QSONEEDSFOR, PChar(integer(Call) + 1));
  SetMainWindowText(mweQSONeedsHeader, wsprintfBuffer);
  //  tSetWindowText(QIHeaderWindowHandle, ' QSO needs for ' + Call);

  if QSOByMode then
  begin
    CreateModeSpecificQSOInfo(Call^, CW, OutputString);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(QSONeedWindowsHandles1[Band], integer((OutputString and
        (1 shl integer(Band))) <> 0));

    CreateModeSpecificQSOInfo(Call^, Phone, OutputString);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(QSONeedWindowsHandles2[Band], integer((OutputString and
        (1 shl integer(Band))) <> 0));

  end
  else
  begin
    CreateModeSpecificQSOInfo(Call^, Both, OutputString);
    for Band := Band160 to Band10 do
      Windows.ShowWindow(QSONeedWindowsHandles1[Band], integer((OutputString and
        (1 shl integer(Band))) <> 0));
  end;

end;

procedure EditableLog.DoPossibleCalls(Call: CallString);
var
  TempIndex: integer;
begin

  PossibleCallList.NumberPossibleCalls := 0;
  PossibleCallList.CursorPosition := 0;
  if not PossibleCallEnable then
    Exit;
  CD.GeneratePossibleCallList(Call);
  //  Sheet.MakePossibleCallList(Call, PossibleCallList);
  if PossibleCallList.NumberPossibleCalls = 0 then
    Exit;
  tLB_RESETCONTENT(wh[mwePossibleCall]);

  for TempIndex := 0 to PossibleCallList.NumberPossibleCalls - 1 do
    SendMessage(wh[mwePossibleCall], LB_ADDSTRING, 0, TempIndex);
  SendMessage(wh[mwePossibleCall], LB_SETCURSEL, 0, 0);
  //  FlagDupesInPossibleCallList(ActiveBand, ActiveMode, PossibleCallList);
  //  DisplayPossibleCalls{(PossibleCallList)};
end;

procedure EditableLog.ShowRemMultsInWindow(Window: WindowsType; rmt:
  RemainingMultiplierType);
label
  AddZone, AddDX, AddPrefix, AddDom;
var
  i: integer;
  rmw: HWND;
  TempMultBand: BandType;
begin
  if rmt = rmNoRemMultDisplay then
    Exit;
  if not tWindowsExist(Window) then
    Exit;
 //  DomWidth := 45;
  SetRemMultsColumnWidth;       // 4.71.2      // 4.83.0
  rmw := Windows.GetDlgItem(tr4w_WindowsArray[Window].WndHandle, 101);

  tSetWindowRedraw(rmw, False);
  SendMessage(rmw, LB_RESETCONTENT, 0, 0);

  if RemainingMultDisplayMode = NoRemainingMults then
  begin
    {?}
    Windows.InvalidateRect(rmw, nil, True);
    Exit;
  end;

  case rmt of

    rmDomestic:
      begin
        TempMultBand := GetAddMultBand(DomesticMultByBand, MultBand);

        for i := 0 to mo.DomList.Count - 1 do
        begin
           if RemainingMultDisplayMode = HiLight then       // 4.72.4
             goto AddDom;
          if not mo.DomList.StringIsDupeByIndex(i, TempMultBand, MultMode) then
             AddDom:
            SendMessage(rmw, LB_ADDSTRING, 0, MakeLong(Ord(rmt), i));
        end;
      end;

    rmPrefix:
      begin
        for i := 0 to mo.PrfList.Count - 1 do
        begin
          if RemainingMultDisplayMode = HiLight then
            goto AddPrefix;
          if not mo.PrfList.StringIsDupeByIndex(i, MultBand, MultMode) then
            AddPrefix: SendMessage(rmw, LB_ADDSTRING, 0, MakeLong(Ord(rmt), i));
        end;
      end;

    rmZone:
      begin
        if MaxNumberOfZones <> 0 then
          for i := 1 to MaxNumberOfZones do
          begin
            if RemainingMultDisplayMode = HiLight then
              goto AddZone;
            if mo.IsZnMult(i, MultBand, MultMode) then
              AddZone:
              if ActiveZoneMult = EUHFCYear then
                SendMessage(rmw, LB_ADDSTRING, 0, MakeLong(Ord(rmt), i - 1))
              else
                SendMessage(rmw, LB_ADDSTRING, 0, MakeLong(Ord(rmt), i));
          end;

      end;

    rmDX:
      begin
        TempMultBand := GetAddMultBand(DXCCMultByBand, MultBand);
        for i := 0 to CTY.ctyNumberCountries - 1 do
        begin
          if CTY.ctyTable[i].VisibleInRM <> 2 then
            Continue;
          if RemainingMultDisplayMode = HiLight then
            goto AddDX;
          if mo.IsDXMult(i, TempMultBand, MultMode) then
            AddDX: SendMessage(rmw, LB_ADDSTRING, 0, MakeLong(Ord(rmt), i));
        end;
      end;

  end;
  tSetWindowRedraw(rmw, True);
end;

procedure EditableLog.ShowRemainingMultipliers;
begin

  if ActiveBand = NoBand then
    Exit;
  ShowRemMultsInWindow(tw_REMMULTSWINDOW_INDEX, RemainingMultDisplay);
  ShowRemMultsInWindow(tw_STATIONS_RM_DX, rmDX);
  ShowRemMultsInWindow(tw_STATIONS_RM_ZONE, rmZone);
  ShowRemMultsInWindow(tw_STATIONS_RM_DOM, rmDomestic);
  ShowRemMultsInWindow(tw_STATIONS_RM_PREFIX, rmPrefix);
end;

procedure EditableLog.DeleteLastLogEntry;

begin
  {
    if LastDeletedLogEntry = '' then
    begin
      LastDeletedLogEntry := LogEntries[NumberEditableLines];

      if LastDeletedLogEntry <> '' then
      begin
                 //      SaveSetAndClearActiveWindow(QuickCommandWindow);
        QuickDisplay('You have deleted the last log entry!!  Use Alt-Y to restore it.');
                 //      RestorePreviousWindow;
        Call := UpperCase(GetLogEntryCall(LogEntries[NumberEditableLines]));
        Band := GetLogEntryBand(LogEntries[NumberEditableLines]);
        Mode := GetLogEntryMode(LogEntries[NumberEditableLines]);
        LogEntries[NumberEditableLines] := '';
        DisplayEditableLog(LogEntries);
        UpdateTempLogFile;
  //               KK1L: 6.64 Deleting a contact should reverse the dupe and mult process
        UpdateBandMapMultiplierStatus;
        UpdateBandMapDupeStatus(Call, Band, Mode, False);
      end;
    end
    else
    begin
           //        RemoveWindow (QuickCommandWindow);
      QuickDisplay('');
      LogEntries[NumberEditableLines] := LastDeletedLogEntry;
      DisplayEditableLog(LogEntries);
      LastDeletedLogEntry := '';
      UpdateTempLogFile;
           //KK1L: 6.64 Restoring contact should update the bandmap again
      Call := UpperCase(GetLogEntryCall(LogEntries[NumberEditableLines]));
      Band := GetLogEntryBand(LogEntries[NumberEditableLines]);
      Mode := GetLogEntryMode(LogEntries[NumberEditableLines]);
      UpdateBandMapMultiplierStatus;
      UpdateBandMapDupeStatus(Call, Band, Mode, True);
    end;
  }
end;

function EditableLog.LastName(Entry: integer): Str20;

{ Revised for use with UK postal groups too in 6.27 }

var
  i: integer;
begin

  i := ListView_GetItemText(wh[mweEditableLog], Entry,
    Ord(ColumnsArray[logColName].pos), @Result[1], 100);
  Result[0] := CHR(i);

  {
    TempString := GetLogEntryExchangeString(LogEntries[Entry]);
    RemoveFirstString(TempString);

    case ActiveExchange of
      QSONumberNameDomesticOrDXQTHExchange:
        begin
          LastName := RemoveFirstString(TempString);
          Exit;
        end;

      RSTAndPostalCodeExchange:
        begin
          RemoveFirstString(TempString);
          LastName := RemoveFirstString(TempString) + ' ' + RemoveFirstString(TempString);
          Exit;
        end;
    end;

    while TempString <> '' do
    begin
      EntryString := RemoveFirstString(TempString);

      if (not StringIsAllNumbers(EntryString)) or (length(EntryString) >= 4) then
      begin
        LastName := EntryString;
        Exit;
      end;
    end;

    TempString := GetLogEntryExchangeString(LogEntries[Entry]);
    RemoveFirstString(TempString);
    LastName := RemoveFirstString(TempString);
  }
end;

function EditableLog.LastEntry(InMyLog: boolean; let: LastEntryType):
  CallString;
var
  Offset: integer;
  records: Cardinal;
label
  ExitLabel;
begin
  Windows.ZeroMemory(@Result, SizeOf(Result));
  if not OpenLogFile then
    Exit;
  records := Windows.GetFileSize(LogHandle, nil) div SizeOf(ContestExchange);

  for Offset := 1 to records - 1 do
  begin
    tSetFilePointer(-1 * Offset * SizeOf(ContestExchange), FILE_END);
    if not ReadLogFile then
      goto ExitLabel;
    if InMyLog then
      if TempRXData.ceComputerID <> ComputerID then
        Continue;
    if TempRXData.ceRecordKind <> rkQSO then
      Continue;
    if TempRXData.ceQSO_Deleted then
      Continue;
    if TempRXData.ceQSO_Skiped then
      Continue;

    case let of
      letCallsign:
        Result := TempRXData.Callsign;
      letQTHString:
        Result := TempRXData.QTHString;
    end;

    if GoodCallSyntax(Result) then
      Break
    else
      Windows.ZeroMemory(@Result, SizeOf(Result));
  end;
  ExitLabel:
  CloseLogFile;
  {
    Result := '';
    for Index := LinesInEditableLog - 1 downto 0 do
    begin
      Windows.ZeroMemory(@Result, SizeOf(Result));
      i := ListView_GetItemText(wh[mweEditableLog], Index, Ord(logColCallsign), @Result[1], CallstringLength - 1);
      if i > 0 then
      begin
        Result[0] := CHR(i);
        if GoodCallSyntax(Result) then Break else
        //Result := '';
          Windows.ZeroMemory(@Result, SizeOf(Result));
      end;
    end;
  }
end;
{
procedure EditableLog.GeneratePartialCallList(InputCall: CallString;
  Band: BandType;
  Mode: ModeType;
  var PossCallList: PossibleCallRecord);

var
  Call                             : CallString;
  Entry                            : integer;

begin
  Sheet.MakePartialCallList(InputCall, Band, Mode, PossibleCallList);
}
  {
    for Entry := 1 to 5 do
    begin
      Call := GetLogEntryCall(LogEntries[Entry]);

      if pos(InputCall, Call) <> 0 then
        if CallNotInPossibleCallList(Call, PossibleCallList) then
        begin
          PossCallList.List[PossCallList.NumberPossibleCalls].Call := Call;
          PossCallList.List[PossCallList.NumberPossibleCalls].Dupe := False;
          inc(PossCallList.NumberPossibleCalls);
          if PossCallList.NumberPossibleCalls > 50 then Break;
        end;
    end;
  }
{
  FlagDupesInPossibleCallList(Band, Mode, PossCallList);

end;
}

{
function EditableLog.NumberNamesSentInEditableLog: integer;

var
  NumberNamesSent, Entry                : integer;

begin
  NumberNamesSent := 0;
  for Entry := 1 to NumberEditableLines do
    if Copy(LogEntries[Entry], LogEntryNameSentAddress, 1) = '*' then
      inc(NumberNamesSent);
  NumberNamesSentInEditableLog := NumberNamesSent;
end;
}

procedure DisplaySCPCall(Call: CallString; Radio: RadioPtr {RadioType});
  {KK1L: 6.73 Added Radio to allow SO2R SCP}
var
  Index: integer;
begin
  if MasterListBox = 0 then
    Exit;
  if ItemsInMasterListBox >= MaxItemsInMasterListBox then
  begin
    //    tLB_ADDSTRING(MasterListBox, '...');
    Exit;
  end;
  Call[length(Call) + 1] := #0;
  Index := tLB_ADDSTRING(MasterListBox, @Call[1]);
  if Index <> -1 then
  begin
    SendMessage(MasterListBox, LB_SETITEMDATA, Index,
      integer(VisibleLog.CallIsADupe(Call, ActiveBand, ActiveMode)));
    inc(ItemsInMasterListBox);
  end;
end;



{procedure}function EditableLog.SuperCheckPartial(Call: CallString; Automatic:
  boolean; Radio: RadioPtr {RadioType}): boolean;
{KK1L: 6.73 Added Radio to allow SO2R SCP}

label
  NotAPartialCall, RememberNotAPartialCall;

var
  CallCD: CallString;

begin
  Result := False;
  if CD.SCPDisabledByApplication then
    Exit;
  if Call = LastSCPCall then
    Exit;
  if Contest = WRTC then           
     Exit;
  LastSCPCall := Call;

  SCPScreenFull := False;

  if Call = '' then
  begin
    //    if {VisibleDupesheetEnable and} not SuperDupeSheet then
                {DisplayVisibleDupesheet (ActiveBand, ActiveMode)}
//    CallsignsList.DisplayDupeSheet(Radio.BandMemory { BandMemory[Radio]}, Radio.ModeMemory { ModeMemory[Radio]}); {KK1L: 6.73 suppory SO2R SCP}
    //    else
    //      if not EditableLogDisplayed then        DisplayEditableLog(LogEntries);

    Exit;
  end;

  if Automatic then
  begin
    if length(Call) < SCPMinimumLetters then
    begin
      LastSCPCall := '';
      Exit;
    end
  end
  else if length(Call) < 2 then
  begin
    LastSCPCall := '';
    Exit;
  end;

  if not CD.PartialCallSetup(Call) then
    Exit;

  //  EditableLogDisplayed := False;
    //  SaveSetAndClearActiveWindow(EditableLogWindow);

  GridSquareListShown := False;
  if MasterListBox = 0 then
    Exit;
  repeat
    CD.GetNextPartialCall(CallCD);
    if CallCD <> '' then
      DisplaySCPCall(CallCD, Radio); //KK1L: 6.73 Fixed proc to for SO2R
    if CallCD = Call then
      Result := True;
    //WLI        IF SCPScreenFull THEN Break;
  until (CallCD = '')

end;

procedure EditableLog.ShowMissingMultiplierReport(h: HWND);

var
  Country: integer;
  TempRow, TempColumn, NumberCountriesDisplayed, Hits: integer;
  StartBand, EndBand, Band: BandType;
  Mode: ModeType;
  ID: CallString;
  BandHits: array[BandType] of boolean;
  TempHWND: HWND;
  RectBlackOrWhite: Byte;
  TempParametr: Cardinal;
  Counter160_10: integer;
const
  rows = 25;
begin

  //   if ActiveDXMult = NoDXMults then Exit;
  //   if not MultByBand then Exit;

  VisibleDupeSheetRemoved := True;
  NumberCountriesDisplayed := 0;

  if ActiveBand <= Band10 then
  begin
    StartBand := Band160;
    EndBand := Band10;
  end
  else if ActiveBand >= Band6 then
  begin
    StartBand := Band6;
    EndBand := BandLight;
  end;
  if MultByMode then
    Mode := ActiveMode
  else
    Mode := Both;

  for Country := 0 to CTY.ctyNumberCountries - 1 do
  begin
    Hits := 0;

    //         TempString := CountryTable.GetCountryName(Country);
//    CompressFormat(ID, CompressedMult);

    Windows.ZeroMemory(@BandHits, SizeOf(BandHits));

    for Band := StartBand to EndBand do
    begin
      BandHits[Band] := False;

      //      NumberMults := mo.MTotals[Band, Mode, rmDX]; // Sheet.MultSheet.Totals[Band, Mode].NumberDXMults;

      if not mo.IsDXMult(Country, Band, Mode) then
      begin
        inc(Hits);
        BandHits[Band] := True;
      end;
    end;

    if (Hits >= MultReportMinimumBands) and (Hits < 6) and
      (NumberCountriesDisplayed < 100) then
    begin

      Windows.ZeroMemory(@ID, SizeOf(ID));
      ID := CTY.ctyTable[Country].ID;

      TempRow := ((NumberCountriesDisplayed mod rows)) * 15 + 5;
      TempColumn := ((((NumberCountriesDisplayed div rows)))) * 135 + 5;
      //               GoToXY (Column, Row);
      TempParametr := SS_SUNKEN;
      if Hits > 3 then
        TempParametr := WS_BORDER;
      TempHWND :=
        tCreateStaticWindow(@ID[1], WS_CHILD or TempParametr or SS_center or
          WS_VISIBLE, TempColumn, TempRow, 40, 14, h, 0);

      //               TempString := ID;

      //               while length(TempString) < 6 do
      //                  TempString := ' ' + TempString;

                     //               Write (TempString, ' ');
//               TempColumn := ((((NumberCountriesDisplayed div 16)) ) + 0) * 300 + 5;
      Counter160_10 := TempColumn + 43;
      for Band := Band160 to Band10 do
      begin
        if BandHits[Band] then
          RectBlackOrWhite := SS_BLACKFRAME
        else
          RectBlackOrWhite := SS_WHITERECT;

        tCreateStaticWindow('',
          RectBlackOrWhite or WS_CHILD or WS_VISIBLE,
          Counter160_10, TempRow, 13, 13, h, 0);

        inc(Counter160_10, 14);

      end;

      inc(NumberCountriesDisplayed);
    end;
  end;

  Format(wsprintfBuffer, TC_MISSINGMULTSREPORT, NumberCountriesDisplayed,
    MultReportMinimumBands);

  Windows.SetWindowText(h, wsprintfBuffer);

  //       GoToXY (8, 17);
  //       Write ('Countries on at least ', MultReportMinimumBands, ' but not all bands.  Any key to exit.');
  //       RestorePreviousWindow;

  //       REPEAT UNTIL NewKeyPressed;
  //       Key := NewReadKey;
  //       IF Key = NullKey THEN Key := NewReadKey;

end;

function QuickEditResponseWithPartials(Prompt: Str80; MaxInputLength: integer):
  Str80;

var
  InputString: Str80;
  Key: Char;
  CWBeingSentAtStart: boolean;

begin
  CWBeingSentAtStart := CWStillBeingSent;

  //  SaveSetAndClearActiveWindow(QuickCommandWindow);

  DoABeep(PromptBeep);

  Write(Prompt);

  InputString := '';

  { If AltDBufferEnable - then the initial entry will be either from
    the left over entry from before - or from the bandmap. }

  if AltDBufferEnable then
  begin
    if DupeInfoCall <> '' then
      InputString := DupeInfoCall
    else
      InputString := DupeInfoCallPrompt;

    Write(InputString);
      {KK1L: 6.73 Display existing call (from band map) if there.}
  end
  else if K5KA.ModeEnabled then
    InputString := AutoAltDWindowString
  else
    InputString := '';

  if InputString <> '' then
    Write(InputString);

  repeat
    repeat
      if K5KA.ModeEnabled and CWBeingSentAtStart then
        if not CWStillBeingSent then
        begin
          AutoAltDWindowString := InputString;
          QuickEditResponseWithPartials := '';
          //          RemoveAndRestorePreviousWindow;
          Exit;
        end;

    until NewKeyPressed;

    Key := UpCase(NewReadKey);

    case Key of
      EscapeKey:
        if InputString = '' then
        begin
          QuickEditResponseWithPartials := EscapeKey;
          //          RemoveAndRestorePreviousWindow;
          Exit;
        end
        else
        begin
          {WLI             GoToXY (WhereX - Length (InputString), WhereY);
                              ClrEol;
                             }InputString := '';
        end;

      BackSpace:
        begin
          if length(InputString) > 0 then
          begin
            InputString[0] := CHR(length(InputString) - 1);
            {                    GoToXY (WhereX - 1, WhereY);
                                ClrEol;
            }
            if PartialCallEnable then
              if Sheet.TwoLetterCrunchProcess(InputString) then
              begin
                {
                  VisibleLog.GeneratePartialCallList(InputString,
                    ActiveBand,
                    ActiveMode,
                    PossibleCallList);
                  DisplayPossibleCalls(PossibleCallList);
                  }
              end;

            if SCPMinimumLetters > 0 then {KK1L: 6.73 Adds SCP to ALT-D entry}
              VisibleLog.SuperCheckPartial(InputString, True, InActiveRadioPtr);
                {KK1L: 6.73 Added InactiveRadio}

          end;
        end;

      CarriageReturn:
        begin
          QuickEditResponseWithPartials := InputString;
          //          RemoveAndRestorePreviousWindow;
          Exit;
        end;

      SpaceBar:
        if K5KA.ModeEnabled and CWBeingSentAtStart then
        begin
          QuickEditResponseWithPartials := InputString;
          //          RemoveAndRestorePreviousWindow;
          Exit;
        end;

      NullKey:
        begin
        end;

    else
      if ((Key >= '0') and (Key <= '9')) or
        ((Key >= 'A') and (Key <= 'Z')) or
        (Key = '/') then
      begin
        {KK1L: 6.73 Overwrites band map callsign.}

        if (InputString = DupeInfoCallPrompt) or (InputString =
          DupeInfoCallPrompt) then
        begin
          {                           GoToXY (WhereX - Length (InputString), WhereY);
                                     ClrEol;
                                    }InputString := '';
        end;
        Write(Key);
        InputString := InputString + Key;

        if PartialCallEnable then
          if Sheet.TwoLetterCrunchProcess(InputString) then
          begin
            {
              VisibleLog.GeneratePartialCallList(InputString,
                ActiveBand,
                ActiveMode,
                PossibleCallList);
              DisplayPossibleCalls(PossibleCallList);
              }
          end;

        if SCPMinimumLetters > 0 then {KK1L: 6.73 Adds SCP to ALT-D entry}
          VisibleLog.SuperCheckPartial(InputString, True, InActiveRadioPtr);
            {KK1L: 6.73 Added InactiveRadio}

      end;

      if length(InputString) = MaxInputLength then
      begin
        QuickEditResponseWithPartials := InputString;
        //        RemoveAndRestorePreviousWindow;
        Exit;
      end;

    end; { of case }

  until False;
end;

procedure TimeAndDateSet;

var
  Hour, Minute, Second, Sec100, Year, Month, Day, DayOfWeek: Word;
  TempString, SecondTempString, HourTempString, MinuteTempString: Str80;
  CharPointer, Result: integer;
  Hours, Mins, Secs, YearS, MonS, Days: Str20;

begin
  //  LastDisplayedTime := '';
  //  LastDisplayedDate := '';

     //  SaveSetAndClearActiveWindow(QuickCommandWindow);

  repeat
    //{WLI}        ClrScr;
{
  DoABeep(PromptBeep);
  if HourOffset = 0 then
    TempString := LineInput('Enter time (HH:MM:SS) : ', '', False, False)
  else
    TempString := LineInput('Enter time (use local time, not UTC) HH:MM:SS : ', '', False, False);
}
    {KK1L: 6.64 Changed to IF to accomodate option of updating time to the network even if no time entered.}
    {      Saves having to enter time, day, etc if you only want to update a new computer on the network.}

    if TempString = '' then
    begin
      //            if ActiveMultiPort <> NoPort then
      begin
        if
          UpperCase(QuickEditResponse('Do you want to send time to computers on the network? (Y/N)', 1)) = 'Y' then
        begin
          GetTime(Hour, Minute, Second, Sec100);
          GetDate(Year, Month, Day, DayOfWeek);

          Str(Hour, Hours);
          Str(Minute, Mins);
          Str(Second, Secs);
          Str(Year, YearS);
          Str(Month, MonS);
          Str(Day, Days);

          SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
            MultiTimeMessage, YearS + ' ' + MonS + ' ' +
            Days + ' ' + Hours + ' ' +
            Mins + ' ' + Secs);
        end;
      end;
      //      RemoveAndRestorePreviousWindow;
      Exit;
    end
    else if TempString = EscapeKey then
    begin
      //      RemoveAndRestorePreviousWindow;
      Exit;
    end;

  until TempString[3] = ':';

  HourTempString := '';

  CharPointer := 1;

  HourTempString := PrecedingString(TempString, ':');

  Delete(TempString, 1, pos(':', TempString));

  if StringHas(TempString, ':') then
  begin
    MinuteTempString := PrecedingString(TempString, ':');
    SecondTempString := PostcedingString(TempString, ':');
  end
  else
  begin
    MinuteTempString := TempString;
    SecondTempString := '00';
  end;

  if (not StringIsAllNumbers(HourTempString)) or
    (not StringIsAllNumbers(MinuteTempString)) or
    (not StringIsAllNumbers(SecondTempString)) then
  begin
    //    RemoveAndRestorePreviousWindow;
    Exit;
  end;

  Val(HourTempString, Hour, Result);
  Val(MinuteTempString, Minute, Result);
  Val(SecondTempString, Second, Result);
  {WLI}
  //    SetTime (Hour, Minute, Second, 0);

  repeat
    //        ClrScr;

    GetDate(Year, Month, Day, DayOfWeek);
    Str(Year, TempString);

    DoABeep(PromptBeep);
    TempString := LineInput('Enter year (ESCAPE to skip) : ', TempString, True,
      False);

    if (TempString = '') or (TempString = EscapeKey) then
    begin
      //      RemoveAndRestorePreviousWindow;
      Exit;
    end;

    Val(TempString, Year, Result);

  until (Year > 1900) and (Year < 2100);

  repeat
    //        ClrScr;

    Str(Month, TempString);
    DoABeep(PromptBeep);

    TempString := LineInput('Enter month (1-12) : ', TempString, True, False);

    if (TempString = '') or (TempString = EscapeKey) then
    begin
      //      RemoveAndRestorePreviousWindow;
      Exit;
    end;

    Val(TempString, Month, Result);

  until (Month >= 1) and (Month <= 12);

  repeat
    //        ClrScr;

    Str(Day, TempString);

    TempString := LineInput('Enter day (1-31) : ', TempString, True, False);
    DoABeep(PromptBeep);

    if (TempString = '') or (TempString = EscapeKey) then
    begin
      //      RemoveAndRestorePreviousWindow;
      Exit;
    end;

    Val(TempString, Day, Result);

  until (Day >= 1) and (Day <= 31);
  {WLI}
  //    SetDate (Year, Month, Day);

//   if ActiveMultiPort <> NoPort then
  begin
    if
      UpperCase(QuickEditResponse('Do you want to send time to computers on the network? (Y/N) : ', 1)) = 'Y' then
    begin
      GetTime(Hour, Minute, Second, Sec100);
      GetDate(Year, Month, Day, DayOfWeek);

      Str(Hour, Hours);
      Str(Minute, Mins);
      Str(Second, Secs);
      Str(Year, YearS);
      Str(Month, MonS);
      Str(Day, Days);

      SendMultiCommand(MultiBandAddressArray[ActiveBand], $FF,
        MultiTimeMessage, YearS + ' ' + MonS + ' ' +
        Days + ' ' + Hours + ' ' +
        Mins + ' ' + Secs);
    end;
  end;

  //  RemoveAndRestorePreviousWindow;
  UpdateTimeAndRateDisplays(True, False);
end;

procedure ShowStationInformation(Call: CallPtr {CallString});
var
  TempString: ShortString;
  TempExchange: Str14;
  ParsedTempExchange: Str14;

begin
  { Took next line out in 6.27.  What if you are working the same guy
    on a different band?  I put it back in in 6.72 - and clared
    StationInformationCall when logging a QSO }

  if Call^ = StationInformationCall then   // This is a flag to show we have been here before ny4i
     begin
     logger.debug('[ShowStationInformation] Exiting early because Call^ = StationInformationCall (%s)',[StationInformationCall]);
     Exit;
     end;

  logger.debug('>>> Entering ShowStationInformation with call of %s',[Call^]);
  StationInformationCall := Call^;

  //  if Copy(Call, 1, 3) = 'CQ-' then Exit;

  ShowName(Call^);

  if QTCsEnabled then
    DisplayQTCNumber(NumberQTCsThisStation(StandardCallFormat(Call^, False)));

  if Contest <> GENERALQSO then
    // Gav 4.44.8   Uses intiial exchange & previous qso DOM to display Domestic mults, if it exists
  begin
    if DoingDomesticMults then
    begin
      TempString := Call^;
      if TempString <> '' then
      begin
        TempExchange := CallsignsList.GetIniitialExchange(TempString);
        if TempExchange <> '' then
        begin
          ParsedTempExchange := DomStringParse(TempExchange);
          if ParsedTempExchange <> '' then
            VisibleLog.ShowDomesticMultiplierStatus(ParsedTempExchange);
        end
        else
        begin
          VisibleLog.ShowMultiplierStatus(Call);
        end;
        VisibleLog.ShowQSOStatus(Call);
      end;
    end
    else
    begin
      VisibleLog.ShowMultiplierStatus(Call);
      VisibleLog.ShowQSOStatus(Call);
    end;
  end;

  DisplayUserInfo(Call^);
  DisplayBeamHeading(Call^, '');
  DisplayCountryName(Call^);

end;

function DetermineQTCNumberAndQuanity(InputString: Str80;
  var QTCNumber: integer;
  var Quantity: integer): boolean;

var
  Result1: integer;
  QTCNumberString, NumberMessagesString: Str80;

begin
  DetermineQTCNumberAndQuanity := False;
  if InputString = '' then
    Exit;
  QTCNumberString := PrecedingString(InputString, '/');
  NumberMessagesString := PostcedingString(InputString, '/');

  if (QTCNumberString = '') or (NumberMessagesString = '') then
  begin
    DoABeep(Beepsingle);
    showwarning('QTC process terminated.');
    Exit;
  end;

  Val(QTCNumberString, QTCNumber, Result1);

  if Result1 <> 0 then
  begin
    DoABeep(Warning);
    showwarning('QTC Number has illegal characters.');
    Exit;
  end;

  Val(NumberMessagesString, Quantity, Result1);

  if Result1 <> 0 then
  begin
    DoABeep(Warning);
    showwarning('Number of messages has illegal characters.');
    Exit;
  end;

  if (Quantity < 1) or (Quantity > 10) then
  begin
    DoABeep(Warning);
    showwarning('QTC process terminated.  Invalid number of messages.');
    Exit;
  end;

  DetermineQTCNumberAndQuanity := True;
end;

procedure AddQTCToQTCBuffer(var QTCBuffer: LogEntryArray; QTCString: Str80;
  Message: integer);

{ This procedure will add the indicated string to the proper message
  number of the QTCBuffer specified.  It will also display it in the
  proper place of the EditableLogWindow.                     }

begin
  GridSquareListShown := False;

  //  SaveAndSetActiveWindow(EditableLogWindow);

  case Message of
    1:
      begin
        QTCBuffer[1] := ' 1: ' + QTCString;
        {           GoToXY (1, 1);
                   ClrEol;
                   Write (QTCBuffer [1]);
                  }
      end;

    2:
      begin
        QTCBuffer[2] := ' 2: ' + QTCString;
        {           GoToXY (1, 2);
                   ClrEol;
                   Write (QTCBuffer [2]);
                  }
      end;

    3:
      begin
        QTCBuffer[3] := ' 3: ' + QTCString;
        {           GoToXY (1, 3);
                   ClrEol;
                   Write (QTCBuffer [3]);
                  }
      end;

    4:
      begin
        QTCBuffer[4] := ' 4: ' + QTCString;
        {           GoToXY (1, 4);
                   ClrEol;
                   Write (QTCBuffer [4]);
                  }
      end;

    5:
      begin
        QTCBuffer[5] := ' 5: ' + QTCString;
        {           GoToXY (1, 5);
                   ClrEol;
                   Write (QTCBuffer [5]);
                  }
      end;

    6:
      begin
        while length(QTCBuffer[1]) < 40 do
          QTCBuffer[1] := QTCBuffer[1] + ' ';
        QTCBuffer[1] := QTCBuffer[1] + ' 6: ' + QTCString;
        {           GoToXY (1, 1);
                   ClrEol;
                   Write (QTCBuffer [1]);
                  }
      end;

    7:
      begin
        while length(QTCBuffer[2]) < 40 do
          QTCBuffer[2] := QTCBuffer[2] + ' ';
        QTCBuffer[2] := QTCBuffer[2] + ' 7: ' + QTCString;
        {           GoToXY (1, 2);
                   ClrEol;
                   Write (QTCBuffer [2]);
                  }
      end;

    8:
      begin
        while length(QTCBuffer[3]) < 40 do
          QTCBuffer[3] := QTCBuffer[3] + ' ';
        QTCBuffer[3] := QTCBuffer[3] + ' 8: ' + QTCString;
        {           GoToXY (1, 3);
                   ClrEol;
                   Write (QTCBuffer [3]);
                  }
      end;

    9:
      begin
        while length(QTCBuffer[4]) < 40 do
          QTCBuffer[4] := QTCBuffer[4] + ' ';
        QTCBuffer[4] := QTCBuffer[4] + ' 9: ' + QTCString;
        {           GoToXY (1, 4);
                   ClrEol;
                   Write (QTCBuffer [4]);
                  }
      end;

    10:
      begin
        while length(QTCBuffer[5]) < 40 do
          QTCBuffer[5] := QTCBuffer[5] + ' ';
        QTCBuffer[5] := QTCBuffer[5] + '10: ' + QTCString;
        {           GoToXY (1, 5);
                   ClrEol;
                   Write (QTCBuffer [5]);
                  }
      end;

  end;
  //  RestorePreviousWindow;
end;

function InitialExchangeEntry(Call: CallString): Str80;

{ This function will give you an initial exchange window entry if it
  thinks it knows what the guy will send.                            }

var
  CharPosition, Zone {, Result1}: integer;
  TempQTH: QTHRecord;
  TestString: ShortString;
  StandardCall, Command: Str20;
  Exchange: Str80;
  CustomString, TempString: ShortString;
  TempExchange: ContestExchange;
  data: DataBaseEntryRecord;
  TempZone: Byte;
  heading : Integer;
begin
  {TR6.74 - Removed any manipulation of IntialExchangePutUp from this
   routine.  It is up to whomever calls it to decide if they want to
   change the state of that variable. }

  { InitialExchangePutUp := False; }
  InitialExchangeEntry := ' ';
  if not GoodCallSyntax(Call) then
    Exit;

  //  TempString := VisibleLog.GetInitialExchangeFromEditableLog(Call);

    //if TempString = '' then
  TempString := CallsignsList.GetIniitialExchange(Call);
    // GetInitialExchange(Call);

  //  if ActiveExchange = RSTPrefectureExchange then TempString := Copy(TempString, 2, 10);

  if TempString = '' then
  begin
    StandardCall := StandardCallFormat(Call, True);

    case ActiveInitialExchange of

      CustomInitialExchange:
        begin
          Exchange := '';

          CustomString := CustomInitialExchangeString;

          while CustomString <> '' do
          begin
            Command := RemoveFirstString(CustomString);

            if Command = 'CQZONE' then
              if CD.GetEntry(Call, data) and (data.CQZone <> '') then
                Exchange := Exchange + data.CQZone + ' '
              else
              begin
                Zone := ctyGetCQZone(Call);

                if Zone > 0 then
                begin
                  Str(Zone, TempString);
                  Exchange := Exchange + TempString + ' ';
                end;
              end;

            if Command = 'ITUZONE' then
              if CD.GetEntry(Call, data) and (data.ITUZone <> '') then
                Exchange := Exchange + data.ITUZone + ' '
              else
              begin
                Zone := ctyGetITUZone(Call);

                if Zone > 0 then
                begin
                  Str(Zone, TempString);
                  Exchange := Exchange + TempString + ' ';
                end;
              end;

            if Command = 'NAME' then
              if CD.GetEntry(StandardCall, data) and (data.mName <> '') then
                Exchange := Exchange + data.mName + ' ';

            if Command = 'QTH' then
              if CD.GetEntry(Call, data) and (data.QTH <> '') then
                Exchange := Exchange + data.QTH + ' ';

            if Command = 'SECTION' then
              if CD.GetEntry(Call, data) and (data.Section <> '') then
                Exchange := Exchange + data.Section + ' ';

            if Command = 'USER1' then
              if CD.GetEntry(Call, data) and (data.User1 <> '') then
                Exchange := Exchange + data.User1 + ' ';

            if Command = 'USER2' then
              if CD.GetEntry(Call, data) and (data.User2 <> '') then
                Exchange := Exchange + data.User2 + ' ';

            if Command = 'USER3' then
              if CD.GetEntry(Call, data) and (data.User3 <> '') then
                Exchange := Exchange + data.User3 + ' ';

            if Command = 'USER4' then
              if CD.GetEntry(Call, data) and (data.User4 <> '') then
                Exchange := Exchange + data.User4 + ' ';

            if Command = 'USER5' then
              if CD.GetEntry(Call, data) and (data.User5 <> '') then
                Exchange := Exchange + data.User5 + ' ';

            if Command = 'GRID' then
              if CD.GetEntry(Call, data) and (data.Grid <> '') then
              begin
                Exchange := Exchange + data.Grid + ' ';

                if (MyGrid <> '') and LooksLikeAGrid(data.Grid) then
                begin
                  //                  SaveSetAndClearActiveWindow(BeamHeadingWindow);
                  Heading := round(GetBeamHeading(MyGrid, data.Grid));
                  //                  Write(data.Grid, ' at ', Heading, '?');
                                            //                  RestorePreviousWindow;
                end;
              end;

            if Command = 'FOC' then
              if CD.GetEntry(StandardCall, data) and (data.FOC <> '') then
                Exchange := Exchange + data.FOC + ' ';

            if Command = 'CHECK' then
              if CD.GetEntry(Call, data) and (data.Check <> '') then
                Exchange := Exchange + data.Check + ' ';

            if Command = 'OLDCALL' then
              if CD.GetEntry(Call, data) and (data.OldCall <> '') then
                Exchange := Exchange + data.OldCall + ' ';

            if Command = 'TENTEN' then
              if CD.GetEntry(Call, data) and (data.TENTEN <> '') then
                Exchange := Exchange + data.TENTEN + ' ';

          end;

          InitialExchangeEntry := '' + Exchange; // Issue151

          CheckAndSetInitialExchangeCursorPos;
          //          if InitialExchangeOverwrite then Windows.SendMessage(ExchangeWindowHandle, EM_SETSEL, 0, -1);
          //                                      InitialExchangePutUp := True; {KK1L: 6.70 For custom typing any character overwrites the whole exchange.}

          Exit;
        end;

      ZoneInitialExchange:
        begin
          if Contest in [OZCR_O, OZCR_Z] then
          begin
            //        if length(Call) = 3 then if Call[1] = 'R' then {if Call[2] in ['0'..'1'] then} Exit;
            if Call[1] = 'R' then
              if Call[2] in ['3'] then
                if Call[3] in ['0'..'9'] then
                  Exit;
          end;

          if ActiveExchange = RSTZoneOrDomesticQTH then
            if DomesticCountryCall(Call) then
            begin
              Result := '';
              Exit;
            end;

          if Contest in [RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB] then
          begin
            Result := '';
            Command := GetOblast(Call);
            case Command[1] of
              '1', '2': Result := '1';
              '3', '4', '6': Result := '2';
              '9':
                begin
                  case Command[2] of

                    'A', 'B', 'C', 'D', 'F', 'G', 'L', 'Q', 'R', 'S', 'T', 'W',
                      'X': Result := '3';
                    'H', 'J', 'K', 'M', 'O', 'U', 'Y', 'Z': Result := '4';
                  end;
                end;

              '0':
                begin
                  case Command[2] of

                    'A', 'W', 'Y': Result := '4';
                    'B', 'H', 'O', 'S', 'T', 'U', 'V': Result := '5';
                    'J', 'C', 'D', 'F', 'Q', 'L': Result := '6';
                    'I', 'K', 'X', 'Z': Result := '7';
                  end;
                end;

            end;
            Exit;
          end;

          if CD.GetEntry(Call, data) then
          begin
            if ActiveZoneMult = ITUZones then
            begin
              if data.ITUZone <> '' then
              begin
                InitialExchangeEntry := ' ' + data.ITUZone;
                  {KK1L: 6.73 Added ' '. K9PG forgets to add it.}

                { InitialExchangePutUp := True; }

                Exit;
              end;
            end
            else if data.CQZone <> '' then
            begin
              InitialExchangeEntry := ' ' + data.CQZone;
                {KK1L: 6.73 Added ' '. K9PG forgets to add it.}

              { InitialExchangePutUp := True; }
              Exit;
            end;
          end;

          //ctyLocateCall(Call, TempQTH);
          //if TempQTH.Zone > 0 then Str(TempQTH.Zone, TempString);
          TempZone := ctyGetZone(Call);
          if TempZone {TempQTH.Zone} <> DUMMYZONE then
            Str(TempZone {TempQTH.Zone}, TempString);
          GetRidOfPrecedingSpaces(TempString);
          if DebugFlag and (TempString = '') then
            TempString := '40';

          { InitialExchangePutUp := TempString <> ''; }
        end;

      NameInitialExchange:
        begin
          TempString := CD.GetName(StandardCall);
          if TempString <> '' then
            TempString := TempString + ' ';
        end;

      NameQTHInitialExchange:
        if CD.GetEntry(Call, data) then
        begin
          if data.mName <> '' then
            TempString := data.mName + ' ';
          if data.QTH <> '' then
            TempString := TempString + data.QTH + ' ';
        end;

      CheckSectionInitialExchange:
        if CD.GetEntry(Call, data) then
          if (data.Check <> '') and (data.Section <> '') then
            TempString := data.Check + data.Section + ' ';

      SectionInitialExchange:
        if CD.GetEntry(Call, data) then
        begin
          if data.Section <> '' then
            TempString := data.Section + ' '
          else
            TempString := GetVEInitialExchange(Call);
        end
        else
        begin
          
          TempString := GetVEInitialExchange(Call);
        end;

      QTHInitialExchange:
        if CD.GetEntry(Call, data) then
        begin
          if data.QTH <> '' then
            TempString := data.QTH + ' '
          else
            TempString := GetVEInitialExchange(Call);
        end
        else
          TempString := GetVEInitialExchange(Call);

      GridInitialExchange:
        if CD.GetEntry(Call, data) then
        begin
          TempString := data.Grid;

          if (MyGrid <> '') and LooksLikeAGrid(data.Grid) then
          begin
            //            SaveSetAndClearActiveWindow(BeamHeadingWindow);
            Heading := round(GetBeamHeading(MyGrid, data.Grid));
            //            Write(data.Grid, ' at ', Heading, '?');
                              //            RestorePreviousWindow;
          end;
        end;

      FOCInitialExchange:
        if CD.GetEntry(StandardCall, data) then
          TempString := data.FOC;

      User1InitialExchange:
        if CD.GetEntry(Call, data) then
          TempString := data.User1;

      User2InitialExchange:
        if CD.GetEntry(Call, data) then
          TempString := data.User2;

      User3InitialExchange:
        if CD.GetEntry(Call, data) then
          TempString := data.User3;

      User4InitialExchange:
        if CD.GetEntry(Call, data) then
          TempString := data.User4;

      User5InitialExchange:
        if CD.GetEntry(Call, data) then
          TempString := data.User5;

    end; { if case }

    if TempString = '' then
      if Contest in [RUSSIANDX, RDA, RU3AXMEMORIAL] then
      begin
        ctyLocateCall(Call, TempQTH);
        if RussianID(TempQTH.CountryID) then
          TempString := GetRussiaOblastID(Call);
      end;

    InitialExchangeEntry := ' ' + TempString;
      {KK1L: 6.73 Added ' '. K9PG forgets to add it when cursor at start.}

    {        IF InitialExchangeOverwrite THEN
                InitialExchangePutUp := True; {KK1L: 6.73 Typing any character overwrites the whole exchange.}

  end
  else
  begin
    GetRidOfPrecedingSpaces(TempString); //n4af 4.31.7
    GetRidOfPostcedingSpaces(TempString);

    if (ActiveExchange = QSONumberDomesticOrDXQTHExchange) or
      (ActiveExchange = RSTAndFOCNumberExchange) or
      (ActiveExchange = QSONumberDomesticQTHExchange) or
      (ActiveExchange = QSONumberAndGridSquare) or
      (ActiveExchange = RSTAndQSONumberOrDomesticQTHExchange) or
      (ActiveExchange = RSTDomesticOrDXQTHExchange) or
      (ActiveExchange = RSTDomesticQTHExchange) or
      (ActiveExchange = RSTDomesticQTHOrQSONumberExchange) or
      (ActiveExchange = RSTQSONumberAndDomesticQTHExchange) or
      (ActiveExchange = QSONumberAndPossibleDomesticQTHExchange) or {KK1L: 6.73}
    (ActiveExchange = RSTQSONumberAndPossibleDomesticQTHExchange) then
      for CharPosition := 1 to length(TempString) do
        if Copy(TempString, CharPosition, 1) = ' ' then
          TempString[CharPosition] := '/';

    {ua4wli 3.01}
    if ActiveExchange = RSTZoneOrDomesticQTH then
      if DomesticCountryCall(Call) then
        TempString := RemoveLastString(TempString);
    if ActiveExchange = QSONumberPrecedenceCheckDomesticQTHEXchange then
      // n4af 4.43.2
      if length(GetFirstString(TempString)) = 1 then // 4.43.2
        if StringIsAllNumbers(GetFirstString(TempString)) then // 4.43.2
          TempString := '0' + TempString; // 4.43.2

    {KK1L: 6.68 For IARU there was a problem with intial exchanges read from the log.}
    {           Both the zone and country are log entries, but only the zone is in the}
    {           exchange. This confused the parser. Only the first string (zone) is needed.}

    if (ActiveInitialExchange = ZoneInitialExchange) or (Contest = IARU) then
      {KK1L: 6.71 The init exchange bug came back when I changed the Initital exchange default}
      {           for IARU and WRTC!! Added the second line above.}
      TempString := RemoveFirstString(TempString);

    {KK1L: 6.73 Typing any character overwrites the whole exchange. Tree
     decided this was a good thing even for rover calls and moved it here }

 {       IF InitialExchangeOverwrite THEN InitialExchangePutUp := True;  }

    if not RoverCall(Call) then
    begin
      InitialExchangeEntry := ' ' + TempString + ' ';
        {KK1L: 6.73 Added ' '. K9PG forgets to add it.}
    end
    else
    begin
      InitialExchangeEntry := TempString;
        {KK1L: 6.73 Per Tree to fix VHF rover problem.}

      {           InitialExchangePutUp := True; }
    end;
    //         curspos := length(Result);
//    Frm.ExchangeWindow . SetFocus;
    tExchangeWindowSetFocus;

    if InitialExchangeOverwrite then
    begin
      Windows.SendMessage(wh[mweExchange], EM_SETSEL, 0, -1);
      InitialExchangePutUp := ExchangeWindowString <> '';
    end;

  end;

  { In 6.40 - made this work all of the time instead of only with
    above }

  while TempString <> '' do
  begin
    { was FirstString before 6.43 }

    TestString := RemoveLastString(TempString);

    if (MyGrid <> '') and LooksLikeAGrid(TestString) then
    begin
      //      SaveSetAndClearActiveWindow(BeamHeadingWindow);
      Heading := round(GetBeamHeading(MyGrid, TestString));
      //               Write(TestString, ' ', Heading, '?');
      TestString := TestString + ' ' + IntToStr(Heading) + '*';
      {               if DistanceMode <> NoDistanceDisplay then
                        begin
                           Distance := GetDistanceBetweenGrids(MyGrid, TestString);

                           if DistanceMode = DistanceMiles then
                              begin
                                 Distance := round(Distance / 1.6);
      //                           Write(' ', Distance, 'm');
                     TestString := TestString + ' ' + IntToStr(Distance) + 'm';
                              end
                           else
       //                       Write(' ', Distance, 'km');
                      TestString := TestString + ' ' + IntToStr(Distance) + 'km';
                           Frm.BeamHeadingWindow . Caption := TestString;
                        end;
      }
                     //      RestorePreviousWindow;

    end;

    if DoingDomesticMults then // Gav 4.44.8    Uncommented this section
      if not StringIsAllNumbersOrSpaces(TestString) then
      begin
        TempExchange.QTHString := TestString;

        if FoundDomesticQTH(TempExchange) then
        begin
          VisibleLog.ShowDomesticMultiplierStatus(TempExchange.DomesticQTH);
          Exit;
        end;
      end
      else if ActiveExchange = RSTPrefectureExchange then
      begin
        TempExchange.QTHString := 'p' + RemoveFirstString(TempString);

        if FoundDomesticQTH(TempExchange) then
          VisibleLog.ShowDomesticMultiplierStatus(TempExchange.DomesticQTH);
        Exit;
      end;

  end;

  //{WLI}

end;

procedure UpdateBandMapDupeStatus(RXCall: CallString; RXBand: BandType; RXMode:
  ModeType; MakeDupe: boolean);

var
  BandMapEntryRecord: BandMapEntryPointer;
  ChangeMade: boolean;

begin
  ChangeMade := False;

  BandMapEntryRecord := BandMapFirstEntryList[RXBand, RXMode];
  while BandMapEntryRecord <> nil do
  begin
    with BandMapEntryRecord^ do
    begin

      {IF (RXCall = BandMapExpandedString(Call)) AND           } {KK1L: 6.73 Removed}
      {   (RXBand = ActiveBand) AND (RXMode = ActiveMode) THEN }
      {KK1L: 6.73 Don't limit compare to active band/mode. This keeps a contact made on the}
      {           second radio from getting reset correctly. The BandMapFirstEntryList limits}
      {           the check appropriately to the band/mode of the deleted contact.}
      if (RXCall = BandMapExpandedString(Call)) then
        if MakeDupe then
        begin
          StatusByte := StatusByte or $40; {KK1L: 6.64 Turn on dupe bit}
          StatusByte := StatusByte and $7F;
            {KK1L: 6.69 if it is a dupe it CAN'T be a mult}
          ChangeMade := True;
        end
        else
        begin
          StatusByte := StatusByte and $BF; {KK1L: 6.64 Turn off dupe bit}
          ChangeMade := True;
        end;
    end;
    BandMapEntryRecord := BandMapEntryRecord^.NextEntry;
  end;

  if ChangeMade then
    DisplayBandMap;
end;

function TotalScore: LONGINT;

{ This routine will return the current contest score }

var
  QPoints, TotalMults: LONGINT;
  m: RemainingMultiplierType;
  b: BandType;
begin
   TotalMults := 0;    // 4.69.5
  QPoints := TotalQSOPoints;

  //  VisibleLog.IncrementQSOPointsWithContentsOfEditableWindow(QPoints);

  if QTCsEnabled then
    QPoints := QPoints + TotalNumberQTCsProcessed;

   if (ActiveDomesticMult = NoDomesticMults)  and        // 4.57.2    //4.69.5  // 4.70.2
    (ActiveDXMult = NoDXMults) and
    (ActivePrefixMult = NoPrefixMults) and
    (ActiveZoneMult = NoZoneMults) then
    begin
    TotalScore := QPoints;
    Exit;
  end;

  {KK1L: 6.70 Ugly fix for FISTS because mults don't work...too long an exchange}
  if ActiveExchange = RSTQTHNameAndFistsNumberOrPowerExchange then
  begin
    TotalScore := QPoints;
    Exit;
  end;

  if Contest = ARRLFIELDDAY then    // 4.72.4
   begin
     totalscore := QPoints;
     exit;
   end;
{ if contest = DL-DX RTTY then
 exit
 }

  if Contest = WINTERFIELDDAY then // Issue 301 NY4I
  begin
    TotalMults := 0;
    for b := Low(BandType) to Band1296 do
    begin
      if QTotals[b, Digital] > 0 then
      begin
        inc(TotalMults);
      end;
      if QTotals[b, CW] > 0 then
      begin
        inc(TotalMults);
      end;
      if QTotals[b, Phone] > 0 then
      begin
        inc(TotalMults);
      end;
    end;
    TotalScore := TotalMults * QPoints;
    if tCategoryPowerSA[Categorypower] = 'LOW' then
       begin
       Result := Result * 2;
       end
    else if tCategoryPowerSA[Categorypower] = 'QRP' then
       begin
       Result := Result * 5;
       end;


    Exit;
  end;

  //  Sheet.MultSheetTotals(MTotals);
    //  VisibleLog.IncrementMultTotalsWithContentsOfEditableWindow(MTotals);
//   TotalMults := 0;

  if SingleBand <> AllBands then
  begin
      
    for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
      TotalMults := TotalMults + mo.MTotals[SingleBand, Both, m];

    //    TotalMults := MTotals[SingleBand, Both].NumberDomesticMults;
    //    TotalMults := TotalMults + MTotals[SingleBand, Both].NumberDXMults;
    //    TotalMults := TotalMults + MTotals[SingleBand, Both].NumberPrefixMults;
    //    TotalMults := TotalMults + MTotals[SingleBand, Both].NumberZoneMults;
  end
  else if ActiveQSOPointMethod = WAEQSOPointMethod then
  begin

    if ActiveDXMult = CQEuropeanCountries then
      m := rmDX
    else
      m := rmPrefix;

    TotalMults := mo.MTotals[Band80, Both, m] * 4;
    TotalMults := TotalMults + mo.MTotals[Band40, Both, m] * 3;
    TotalMults := TotalMults + mo.MTotals[Band20, Both, m] * 2;
    TotalMults := TotalMults + mo.MTotals[Band15, Both, m] * 2;
    TotalMults := TotalMults + mo.MTotals[Band10, Both, m] * 2;
  end
  else
  begin
    for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
      TotalMults := TotalMults + mo.MTotals[AllBands, Both, m];

    //      TotalMults := mo.MTotals[All, Both, rmDomestic];

    //      TotalMults := TotalMults + moMTotals[All, Both].NumberDXMults;

    //      if (Contest = RDA) and (not RussianID(MyCountry)) then        TotalMults := TotalMults - MTotals[All, Both].NumberDXMults;

    //      if Contest <> CUPURAL then        TotalMults := TotalMults + MTotals[All, Both].NumberPrefixMults;

    //      TotalMults := TotalMults + MTotals[All, Both].NumberZoneMults;
    if Contest = CUPURAL then
      TotalMults := TotalMults - mo.MTotals[AllBands, Both, rmPrefix];
  end;

  if Contest = RSGB18 then
  begin
    TotalMults := 1;
  end;

  if ActiveQSOPointMethod = CupRFMethod then
  begin
    TotalScore := QPoints + (100 * TotalMults);
    Exit;
  end;

  if ActiveQSOPointMethod = ALRSUA1DZCupQSOPointMethod then
  begin
    TotalScore := QPoints + (300 * TotalMults);
    Exit;
  end;

  if ActiveQSOPointMethod = ChampionshipRFMethod then
  begin
    TotalScore := QPoints + (50 * TotalMults);
    Exit;
  end;

  //  if ActiveQSOPointMethod = ChampionshipUkrMethod then
  if Contest in [UKRAINECHAMPIONSHIP {, RADIOYOC}] then
  begin
    TotalScore := QPoints + (10 * TotalMults);
    Exit;
  end;

  if ActiveQSOPointMethod = OZHCRVHFQSOPointMethod then
  begin
    TotalScore := QPoints + (1000 * TotalMults);
    Exit;
  end;
  
  TotalScore := QPoints * TotalMults;

  if Contest = CUPURAL then
    Result := Result + 10 * mo.MTotals[AllBands, Both, rmPrefix];

end;

procedure SetPrefix(var RData: ContestExchange {Ptr});
begin
  case ActivePrefixMult of
    CQNonEuropeanCountriesAndWAECallRegions: RData.Prefix :=
      EuropeanCountriesAndWAECallRegions(RData.QTH);
    BelgiumPrefixes: if RData.QTH.CountryID = 'ON' then
        RData.Prefix := RData.QTH.Prefix;
    SACDistricts: RData.Prefix := SACDistrict(RData.QTH);
    IndonesianDistricts: RData.Prefix := IndonesianDistrict(RData.QTH); // 4.64.1
    Prefix: RData.Prefix := RData.QTH.Prefix;
    SouthAmericanPrefixes: if RData.QTH.Continent = SouthAmerica then
        RData.Prefix := RData.QTH.Prefix;
    NorthAmericanPrefixes: if RData.QTH.Continent = NorthAmerica then
        RData.Prefix := RData.QTH.Prefix;
    AsianPrefixes: if RData.QTH.Continent = Asia then
        RData.Prefix := RData.QTH.Prefix;
    SouthAndNorthAmericanPrefixes: if RData.QTH.Continent in [NorthAmerica,
      SouthAmerica] then
        RData.Prefix := RData.QTH.Prefix;
    NonSouthAmericanPrefixes: if RData.QTH.Continent <> SouthAmerica then
        RData.Prefix := RData.QTH.Prefix;
    CallSignPrefix: RData.Prefix := RData.Callsign;
    MongolianCallSignPrefix: if RData.QTH.CountryID = 'JT' then
        RData.Prefix := RData.Callsign;
    RussianPrefixes: if Rdata.QTH.CountryID = 'UA' then
        RData.Prefix := RData.Callsign;
    // CzechRepublicCallsignPrefix: if RData.QTH.CountryID = 'OK' then
    //      RDATA.Prefix := RDATA.Callsign;
    GCStation:
      begin
        if (RData.Callsign = 'RK1G') or (RData.Callsign = 'R3K') or
          (RData.Callsign = 'RS3A')
          or (RData.Callsign = 'RT3F') or (RData.Callsign = 'UP7Z') or
            (RData.Callsign = 'UN/RA3VM') then
          RData.Prefix := RData.Callsign;
      end;
  end;
  //  RData^.Prefix := RData^.Prefix;
end;

end.
