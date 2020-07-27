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

 unit PostUnit;

{$IMPORTEDDATA OFF}
interface

uses
  uCallSignRoutines,
  uCTYDAT,
  LogDom,
  uErmak,
  uCallsigns,
  LogK1EA,
  utils_text,
  utils_file,
  sysutils,
  StrUtils,
  Classes,
  Tree,
  VC,
//  Help,
  uMults,
  LogEdit,
  TF,
  LogWind,
  //Country9,
  LogDupe,
  LogStuff,
  LogGrid,
  ZoneCont,
  Messages,
  LogCW, // 4.53.2
  Windows
  ;

type
  RateSheetType = array[1..3, 0..23, BandType, CW..Both] of integer;
  RateSheetPointer = ^RateSheetType;

  ReportEntryArray = array[0..500] of Str20;
  ReportEntryArrayPointer = ^ReportEntryArray;

type
  MultCountryTotalRecordType = record
    FirstCall: CallString;
    TotalQSOs: integer;
  end;

type
  CountryMultiplierArray = array[Band160..Band10, 0..MaxCountries - 1] of MultCountryTotalRecordType;
  CountryMultiplierArrayPointer = ^CountryMultiplierArray;

type

  PLEFTONBIStateType = record
    LastBand: BandType;
    LastMode: ModeType;
    LastDateString: Str20;
    LastTimeString: Str80;
    LastHourIndex: integer;
    DoingBreak: boolean;
    BandsThisMinute: array[BandType] of boolean;
  end;

type

  HourTotalsRecord = record
    HourName: string[2];
    QSOs: array[BandType, ModeType] of integer;
    QSOPoints: array[BandType, ModeType] of integer;
    Mults: array[BandType, ModeType] of integer;
    Minutes: array[BandType, ModeType] of integer;
  end;

  LogHourTotalArray = array[0..49] of HourTotalsRecord;
  LogHourTotalArrayPointer = ^LogHourTotalArray;

type
  QTCEntryRecord = record
    Time: CallString;
    Call: CallString;
    Number: CallString;
  end;

  QTCEntryArrayType = array[0..9] of QTCEntryRecord;
  QTCEntryArrayPtr = ^QTCEntryArrayType;
  {
  type
     CabrilloStringType =
        (
        csRSTZone,
        csRSTQSONumber,
        csDummy
        );
  }
function GetMyExchangeForExport: string;
procedure ExportToEDI;
procedure ExportToEDIByBand(Band: BandType);
procedure ExportToADIF;
procedure ExportToTRLogFormat;
procedure ExportToCSV;   //n4af 04.30.3
procedure PrintQSOsByCountry;
function GenerateCountryMultiplierTotals: boolean;
procedure QSOsByCountryByBand;
procedure ContinentReport;
function CheckLog: boolean;
procedure CheckTimeOnByBand(LastHour: integer);
procedure FinishOutLastHour;
procedure PrintHourTotals;
function GenerateAllTotalsPerHour: boolean;
procedure ScoreByHour;
//function DetermineNumberOfQTCs: integer;
function CalculateTotals: boolean;
procedure SummarySheet;
procedure CreateCabrilloFile;
procedure CheckForNewContestDate(Date: TQSOTime);

procedure WriteADIFField(sFieldName: string; sFieldValue: string);
function GetOperatorsFromLog: string;

procedure WriteTitleBlockToSummarySheet;

procedure WriteScoreInformationToSummarySheet;

function MakeCategoryString: string;
function tGenerateSummaryPortionOfCabrilloFile: boolean;
function tGenerateLogPortionOfCabrilloFile: boolean;
procedure tFirstCallInEachCountry;
procedure SetTransmittersIdentifiers;
procedure tFirstCallInEachZone;
procedure PrintFirstCountryMultiplierCallsigns;
function GenerateZoneMultiplierTotals: boolean;
procedure PrintFirstZoneMultiplierCallsigns;
procedure ZoneReport;
procedure BandChangeReport;
procedure MakeReportFileName(ShortFileName: PChar);
procedure MakeNotesList;
function GoodLookingQSO: boolean;
//function CorrectContestExchange: boolean;

var
  tShowFrequencyinLog                   : boolean = False;
  Radio1IDs                             : Str10;
//  Radio2ID                              : Char = #0;
  RateSheet                             : RateSheetPointer;

  TempRXData                            : ContestExchange;

  CABRILLO_RST_SEND                     : array[0..3] of Char;
  CABRILLO_RST_RCVD                     : array[0..3] of Char;
  CABRILLO_BUFFER                       : array[0..255] of Char;
  CABRILLO_FIRST_PART                   : array[0..255] of Char;
  CABRILLO_MYEX                         : array[0..64 - 1] of Char;
  CABRILLO_HISEX                        : array[0..64 - 1] of Char;

  ADIF_FREQ_STRING                      : array[0..15] of Char;

  tReportsFilename                      : FileNameType;
  tReportFileWrite                      : HWND;
  PreviewFileNameAddress                : PChar;
  PreviewFileIsCabrillo                 : boolean;

  CountryMultTotals                     : CountryMultiplierArrayPointer;
  P                                     : pchar;
  P1                                     : pchar;
  TotalLogQSOs                          : Cardinal;
  ReportsFilename                       : ShortString;

  ReportFileWrite                       : Text;
  LOGDATFileWrite                       : ShortString;
  SStr                                   : Pchar;
  Precedence, Check, Section, Power, NameInFile, QTH: Str40;
  Overlay                               : Str20;
  NameFileDirectory                     : Str40;
  NumberDates                           : integer;
  ContestDates                          : array[0..10] of TQSOTime;

  QSOPointTotals                        : array[BandType, CW..Both] of integer;
  RawQSOTotals                          : array[BandType, CW..Both] of integer;
  PostQSOTotals                         : array[BandType, CW..Both] of integer;
{
  PrefixTotals                          : array[BandType, CW..Both] of Word;
  ZoneTotals                            : array[BandType, CW..Both] of Word;
  DomesticTotals                        : array[BandType, CW..Both] of Word;
  DXTotals                              : array[BandType, CW..Both] of Word;
}
  //  Header                                : Str80;

  LogHourTotals                         : LogHourTotalArrayPointer;

  //  NumberDates       : integer;
  NumberLogHours                        : integer;

  PhoneUsed                             : boolean;
  PLeftOnBiState                        : PLEFTONBIStateType;

  CallSignLength                        : integer;
  Contest                               : ContestType;

  NumberExchangeElementsToRecord        : integer;
  ReverseExchangeNumber                 : boolean;

  PreviousName                          : Str20; { Used for Interent Sprint }

  QTCEnable                             : boolean;

  ReceivedCallCursorPosition            : integer;
  ReceivedQSONumberLength               : integer;
  RSTIsPartOfTheExchange                : boolean;

  SentDataLength                        : integer;
  SniffForTransmitter                   : boolean;
  SentInformation                       : Str40;
  SentQSONumberLength                   : integer;

  SuppressRST                           : boolean;

  QTCList                               : QTCEntryArrayPtr;

const
  CabrilloVersion                       = '3.0';

//  NumberOperatorCategories              = 3;
//  NumberBandCategories                  = 13;
//  NumberPowerCategories                 = 3;
//  NumberModeCategories                  = 4;
  NumberOverlayCategories               = 5;
  NumberAssistedCategories              = 2;
  NumberStationCategories               = 7;
  NumberTimeCategories                  = 3;
  NumberTransmitterCategories           = 5;
  NumberCertificateCategories           = 2;
  NumberSections                        = 81;

  NumberErmakOverlayCategories          = 11;

  ErmakOverlayCategory                  : array[0..NumberErmakOverlayCategories - 1] of PChar = (
    'YL',
    'JR',
    'JR-13',
    'JR-15',
    'JR-18',
    'JR-19',
    'VETERAN',
    'SPECIAL',
    'OVER-50',
    'OVER-100',
    'POLAR'
    );

 { OperatorCategory                      : array[0..NumberOperatorCategories - 1] of PChar = (
    'SINGLE-OP',
    'MULTI-OP',
    'CHECKLOG');
 }
  TimeCategory                          : array[0..NumberTimeCategories - 1] of PChar = (
    '6-HOURS',
    '12-HOURS',
    '24-HOURS'
    );

  TransmitterCategory                   : array[0..NumberTransmitterCategories - 1] of PChar = (
    'ONE',
    'TWO',
    'LIMITED',
    'UNLIMITED',
    'SWL'
    );
{
  AssistedCategory                      : array[0..NumberAssistedCategories - 1] of PChar = (
    'NON-ASSISTED',
    'ASSISTED'
    );
}
  StationCategory                       : array[0..NumberStationCategories - 1] of PChar =
    (
    'FIXED',
    'MOBILE',
    'PORTABLE',
    'ROVER',
    'EXPEDITION',
    'HQ',
    'SCHOOL'
    );
{
  BandCategory                          : array[0..NumberBandCategories - 1] of PChar = (
    'ALL',
    '160M',
    '80M',
    '40M',
    '20M',
    '15M',
    '10M',
    '6M',
    '2M',
    '222',
    '432',
    '902',
    '1.2G'
    );

  PowerCategory                         : array[0..NumberPowerCategories - 1] of PChar = (
    'HIGH',
    'LOW',
    'QRP');

  ModeCategory                          : array[0..NumberModeCategories - 1] of PChar = (
    'CW',
    'RTTY',
    'SSB',
    'MIXED');
}
  OverlayCategory                       : array[0..NumberOverlayCategories - 1] of PChar = (
    'CLASSIC',  //n4af 4.35.4
    'ROOKIE',
    'NOVICE-TECH',
    'TB-WIRES',
    'OVER-50');

    Certificate                 : array[0..NumberCertificateCategories - 1] of PChar = (           //N4AF 37.0.1
    'YES',
    'NO');

  tCabrilloFreqString                   : array[Band160..BandLight] of PChar =
    (
    '1800',
    '3500',
    '7000',
    '14000',
    '21000',
    '28000',
    '10100',
    '18100',
    '24900',
    '50',
    '144',
    '222',
    '432',
    '902',
    '1.2G',
    '2.3G',
    '3.4G',
    '5.7G',
    '10G',
    '24G',
    'LIGHT'
    );

  tCabrilloModeString                   : array[ModeType] of PChar =
    (
    'CW',
    'RY',
    'PH',
    nil,
    nil,
    'FM'
    );
{
  tARRLVESections                       : array[0..NumberSections - 1] of PChar = (
    'AB',
    'AK',
    'AL',
    'AR',
    'AZ',
    'BC',
    'CO',
    'CT',
    'DE',
    'DX',
    'EB',
    'EM',
    'ENY',
    'EP',
    'EW',
    'GA',
    'IA',
    'ID',
    'IL',
    'IN',
    'KS',
    'KY',
    'LA',
    'LAX',
    'MAR',
    'MB',
    'MDC',
    'ME',
    'MI',
    'MN',
    'MO',
    'MS',
    'MT',
    'NC',
    'ND',
    'NE',
    'NFL',
    'NH',
    'NL',
    'NLI',
    'NM',
    'NNJ',
    'NNY',
    'NTX',
    'NV',
    'NWT',
    'OH',
    'OK',
    'ON',
    'OR',
    'ORG',
    'PAC',
    'PR',
    'QC',
    'RI',
    'SB',
    'SC',
    'SCV',
    'SD',
    'SDG',
    'SF',
    'SFL',
    'SJV',
    'SK',
    'SNJ',
    'STX',
    'SV',
    'TN',
    'UT',
    'VA',
    'VI',
    'VT',
    'WCF',
    'WI',
    'WMA',
    'WNY',
    'WPA',
    'WTX',
    'WV',
    'WWA',
    'WY');
}
implementation

uses
  uCbrSum,
  MainUnit;

procedure WriteADIFField(sFieldName: string; sFieldValue: string);
var sBuffer: string;
begin
   if length(sFieldValue) > 0 then
      begin
      sBuffer := SysUtils.Format('<%s:%u>%s ', [sFieldName,length(sFieldValue),sFieldValue]);
      sWriteFileFromString(tReportFileWrite, sBuffer);
      end
   else
      begin
      DEBUGMSG('[WriteADIFField] ' + sFieldName + ' value is blank - skipping');
      end;
end;

procedure CreateCabrilloFile;
label
  1;
var
  SetTransmittersId                     : boolean;
begin

  SetTransmittersId := False;
  Format(tReportsFilename, '%s%s.LOG', TR4W_LOG_PATH_NAME, @MyCall[1]);
  DeleteSlashes(tReportsFilename);

  Windows.ZeroMemory(@Radio1IDs, SizeOf(Radio1IDs));
  SetTransmittersId := TF.SendDlgItemMessage(CreateCabrilloWindow, $CF {124}, CB_GETCURSEL) = 1;

  if Contest = IOTA then
    if TF.SendDlgItemMessage(CreateCabrilloWindow, 120, CB_GETCURSEL) = 1 then SetTransmittersId := True;

  if SetTransmittersId then SetTransmittersIdentifiers;

//  if FileExists(tReportsFilename) then if not OkayToDeleteExistingFile(tReportsFilename) then Exit;
  if not tGenerateSummaryPortionOfCabrilloFile then Exit;
  if not tGenerateLogPortionOfCabrilloFile then
  begin
    CloseHandle(tReportFileWrite);
    Exit;
  end;
  CloseHandle(tReportFileWrite);
  PreviewFileNameAddress := tReportsFilename;
  PreviewFileIsCabrillo := True;
  FilePreview;
end;

function CheckLog: boolean;
begin
  Result := False;
  //  if not CheckForTempFile then exit;

  if not CalculateTotals then Exit;
  //  if not CheckLogForContacts then exit;

  Result := True;
end;

procedure SummarySheet;
begin
  if not CheckLog then Exit;
  MakeReportFileName('Summary.txt');
  if not tOpenFileForWrite(tReportFileWrite, @ReportsFilename[1]) then Exit;
  WriteTitleBlockToSummarySheet;
  WriteScoreInformationToSummarySheet;
{
  if not OpenFileForWrite(ReportFileWrite, ReportsFilename) then Exit;
  WriteTitleBlockToSummarySheet;
  WriteScoreInformationToSummarySheet;
  Close(ReportFileWrite);
}
  CloseHandle(tReportFileWrite);
  FilePreview;
end;

procedure WriteTitleBlockToSummarySheet;
var
  nNumberOfBytesToWrite                 : integer;
  TempTag                               : CabrilloTags;
begin
  asm
  push offset MyGrid[1]
  push offset MyCall[1]
  end;
  tGetDateFormat(ContestDates[0]);
  asm
  push eax
  push offset ContestName[1]
  push offset ContestName[1]
  end;
  nNumberOfBytesToWrite := wsprintf(wsprintfBuffer,
    #13#10 +
    '%21s SUMMARY SHEET'#13#10#13#10 +
    '               CONTEST: %s'#13#10 +
    '            START DATE: %s'#13#10 +
    '         CALLSIGN USED: %s'#13#10 +
    '               LOCATOR: %s'#13#10#13#10
    );
  asm add esp,28 end;
  sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);

//  for i := 147 to 167 - 2 + 2 do
  for TempTag := Low(CabrilloTags) to High(CabrilloTags) do
  begin
    if ErmakSpecification then if TempTag = ctOperators then Continue;

    Windows.GetDlgItemText(CreateCabrilloWindow, integer(TempTag) + 200, @TempBuffer2, SizeOf(TempBuffer2));
    if TempBuffer2[0] = #0 then Continue;

    nNumberOfBytesToWrite := Format(wsprintfBuffer, '%22s: %s'#13#10, @CabrilloTagsArray[TempTag].ctrTag[1], TempBuffer2);
{
    Windows.GetDlgItemText(CreateCabrilloWindow, i, @TempBuffer1, SizeOf(TempBuffer1));
    Windows.GetDlgItemText(CreateCabrilloWindow, i - 30, @TempBuffer2, SizeOf(TempBuffer2));
    if TempBuffer2[0] = #0 then Continue;
//    T1 := TempBuffer1;
//    T2 := TempBuffer2;
    asm
    push offset TempBuffer2
    push offset TempBuffer1
    end;
    nNumberOfBytesToWrite := wsprintf(wsprintfBuffer, '%21s: %s'#13#10);
    asm add esp,16
    end;
}
    sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
  end;

//  TempInteger := tRestartInfo.riQSOByOpMode[SearchAndPounceOpMode];
  CallsignsList.GetTotalWorkedStations;
  asm
  push eax
  mov eax,dword ptr [tRestartInfo+$8]
  push eax
  mov eax,dword ptr [tRestartInfo+$4]
  push eax
//  push TempInteger
  push tRestartInfo.riCQTotalCounter
  end;
  MillisecondsToFormattedString(TimeSpentByBand[AllBands] * 1000, False);
  asm
  push eax
  end;

  nNumberOfBytesToWrite := wsprintf(wsprintfBuffer,
    #13#10'        OPERATING TIME: %s' +
    #13#10'            CQ COUNTER: %d' +
    #13#10'            RUN/SEARCH: %d/%d Qs' +
    #13#10'      UNIQUE CALLSIGNS: %d'#13#10 +
    #13#10'              SOFTWARE: ' + TR4W_CURRENTVERSION + ' http://www.tr4w.net'#13#10
    );
  asm add esp,28
  end;
  sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
{
  WriteLn(ReportFileWrite, '   Operating Time : ', OperatingTime div (60), 'h ', OperatingTime mod 60, 'm');

  if tRestartInfo.riCQTotalCounter > 0 then
    WriteLn(ReportFileWrite, '       CQ Counter : ', IntToStr(tRestartInfo.riCQTotalCounter));

  WriteLn(ReportFileWrite, '  Run/Search QSOs : ', tRestartInfo.riQSOByOpMode[CQOpMode], '/', tRestartInfo.riQSOByOpMode[SearchAndPounceOpMode]);
  WriteLn(ReportFileWrite, ' Unique callsigns : ', CallsignsList.GetTotalWorkedStations, #13#10);
  }

end;

procedure WriteScoreInformationToSummarySheet;
var
  Band                                  : BandType;
  Mode                                  : ModeType;
  TempMode                              : ModeType;
  nNumberOfBytesToWrite                 : integer;
  BString                               : PChar;
  MString                               : PChar;
  TempInteger                           : integer;
  SumInteger                            : integer;
  m                                     : RemainingMultiplierType;
  TotalLine                             : boolean;
const
  h                                     = #13#10'  BAND   Raw QSOs   Valid QSOs   Points';
  mn                                    :array[RemainingMultiplierType] of PChar = ('','Mults', 'Countries', 'Zones', 'Prefixes');
  breakline                             = #13#10' __________________________________________________________';
begin
  TotalLine := False;
  sWriteFile(tReportFileWrite, h, length(h));

  for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
  begin
    if mo.MTotals[AllBands, Both, m] = 0 then
       begin
       Continue;
       end;
    nNumberOfBytesToWrite := Format(wsprintfBuffer, '%10s', mn[m]);
    sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
  end;

  sWriteFile(tReportFileWrite, breakline, length(breakline));

  for Band := Band160 to AllBands do
    for Mode := CW to Phone do
      if RawQSOTotals[Band, Mode] > 0 then
      begin

        BString := BandStringsArray[Band];
        MString := ModeStringArray[Mode];

        TempMode := Mode;
        if Band = AllBands then
        begin
          if TotalLine then Continue;
          sWriteFile(tReportFileWrite, breakline, length(breakline));
          sWriteFile(tReportFileWrite, #13#10, 2);
          TempMode := Both;
          TotalLine := True;
          BString := 'Totals';
          MString := nil;
        end;

        SumInteger := QSOPointTotals[Band, TempMode];
        asm
        push SumInteger
        end;

        TempInteger := PostQSOTotals[Band, TempMode];
        asm
        push TempInteger
        end;

        TempInteger := RawQSOTotals[Band, TempMode];
        asm
        push TempInteger
        end;

        asm
        push MString
        push BString
        end;
        nNumberOfBytesToWrite := wsprintf(wsprintfBuffer, #13#10' %s%s %9d %12d %8d');
        asm add esp,28
        end;
        sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);

        for m := Low(RemainingMultiplierType) to High(RemainingMultiplierType) do
        begin
          if mo.MTotals[AllBands, Both, m] = 0 then
             begin
             Continue;
             end;
          nNumberOfBytesToWrite := Format(wsprintfBuffer, '%10d', mo.MTotals[Band, TempMode, m]);
          sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
        end;

{
        Write(ReportFileWrite, '  ', BandStringsArray[Band], ModeString[Mode]);
        Write(ReportFileWrite, RawQSOTotals[Band, Mode]: 8);
        Write(ReportFileWrite, PostQSOTotals[Band, Mode]: 12);
        Write(ReportFileWrite, QSOPointTotals[Band, Mode]: 11);
        Write(ReportFileWrite, ' ');
}
      end;
//  sWriteFile(tReportFileWrite, breakline, length(breakline));
  if QTCEnable then
  begin
    nNumberOfBytesToWrite := Format(wsprintfBuffer, #13#10#13#10'    There were %d QTC points.', TotalNumberQTCsProcessed);
    sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
  end;
  if Contest <> ARRLFIELDDAY then
  nNumberOfBytesToWrite := Format(wsprintfBuffer, #13#10#13#10'    Final Score = %d points.', TotalScore)
  else
  nNumberOfBytesToWrite := Format(wsprintfBuffer, #13#10#13#10'    Final Score = %d points.', SumInteger);
  sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
end;

function CalculateTotals: boolean;

{ Returns TRUE if successful }
label
  1;
var
  Band                                  : BandType;
  PreviousBand                          : BandType;
  Mode                                  : ModeType;
  FirstRecord                           : boolean;
  TempMode                              : ModeType;
  TimeDifference                        : integer;
  PreviousQSOTime                       : TQSOTime;
  Min                                   : Integer;
begin

if pos('CQ-WW', ContestName ) <> 0 then       //n4af 4.35.3
Min := 60
else
Min := 30;
  NumberDates := 0;
//  OperatingTime := 0;
  CalculateTotals := False;
  ZeroMemory(@TimeSpentByBand, SizeOf(TimeSpentByBand));
  for Band := Band160 to AllBands do
    for Mode := CW to Both do
    begin
      PostQSOTotals[Band, Mode] := 0;
      RawQSOTotals[Band, Mode] := 0;
      QSOPointTotals[Band, Mode] := 0;
    end;

  if not OpenLogFile then Exit;
  FirstRecord := True;
  PreviousBand := NoBand;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if TempRXData.ceQSO_Deleted = True then goto 1;
    if TempRXData.ceQSO_Skiped then goto 1;
    if TempRXData.ceRecordKind <> rkQSO then goto 1;

    TempMode := TempRXData.Mode;
    if TempMode = FM then TempMode := Phone;

    inc(RawQSOTotals[TempRXData.Band, TempMode]);
    inc(RawQSOTotals[TempRXData.Band, Both]);
    inc(RawQSOTotals[AllBands, TempMode]);
    inc(RawQSOTotals[AllBands, Both]);

    if GoodLookingQSO then if TempRXData.ceDupe = False then
      begin

        if not FirstRecord then
        begin
          TimeDifference := QSOTimeToSeconds(TempRXData.tSysTime) - QSOTimeToSeconds(PreviousQSOTime);
          if TimeDifference <= Min {min} * 60 then      //n4af 4.35.3
//            OperatingTime := OperatingTime + TimeDifference;
          begin
            if PreviousBand = TempRXData.Band then
              inc(TimeSpentByBand[TempRXData.Band], TimeDifference);
            inc(TimeSpentByBand[AllBands], TimeDifference);
          end;
          PreviousBand := TempRXData.Band;
        end;

        PreviousQSOTime := TempRXData.tSysTime;

        FirstRecord := False;
        CheckForNewContestDate(TempRXData.tSysTime);

        inc(PostQSOTotals[TempRXData.Band, TempMode]);
        inc(PostQSOTotals[TempRXData.Band, Both]);
        inc(PostQSOTotals[AllBands, TempMode]);
        inc(PostQSOTotals[AllBands, Both]);

        QSOPointTotals[TempRXData.Band, TempMode] := QSOPointTotals[TempRXData.Band, TempMode] + TempRXData.QSOPoints;
        QSOPointTotals[TempRXData.Band, Both] := QSOPointTotals[TempRXData.Band, Both] + TempRXData.QSOPoints;
        QSOPointTotals[AllBands, TempMode] := QSOPointTotals[AllBands, TempMode] + TempRXData.QSOPoints;
        QSOPointTotals[AllBands, Both] := QSOPointTotals[AllBands, Both] + TempRXData.QSOPoints;
      end;
    goto 1;
  end;
  CloseLogFile;
//  OperatingTime := OperatingTime div 60;
  CalculateTotals := True;
end;

procedure CheckForNewContestDate(Date: TQSOTime);

var
  Index                                 : integer;

begin
  if NumberDates = 0 then
  begin
    ContestDates[0] := Date;
    inc(NumberDates);
    Exit;
  end;

  for Index := 0 to NumberDates - 1 do
    if ContestDates[Index].qtDay = Date.qtDay then Exit;

  ContestDates[NumberDates] := Date;
  inc(NumberDates);

  if (NumberDates > 10) and (Contest <> GENERALQSO) then     // 4.72.1
  begin
    showwarning(TC_TOOMANYCONTESTDATES);
      //    halt;
  end;

end;

function MakeCategoryString: string;
begin
  Result :=
    GetDialogItemText(CreateCabrilloWindow, 121) + ' ' +
    GetDialogItemText(CreateCabrilloWindow, 122) + ' ' +
    GetDialogItemText(CreateCabrilloWindow, 123) + ' ' +
    GetDialogItemText(CreateCabrilloWindow, 124);

end;
{
function DetermineNumberOfQTCs: integer;

// This procedure will look at the QTC.DAT file and determine how many QTCs
//  were sent or received.

var
  FileRead                         : Text;
  //  FileString                            : Str80;
  QTCsThisStation, NumberQTCs      : integer;

begin
  NumberQTCs := 0;

  if OpenFileForRead(FileRead, 'QTCLIST.DAT') then
  begin
    while not Eof(FileRead) do
    begin
      ReadLn(FileRead);

      if not Eof(FileRead) then
      begin
        ReadLn(FileRead, QTCsThisStation);
        NumberQTCs := NumberQTCs + QTCsThisStation;
      end;
    end;

    Close(FileRead);
  end;

  DetermineNumberOfQTCs := NumberQTCs;
end;
}

procedure ScoreByHour;
begin

  if not CheckLog then Exit;
  MakeReportFileName('HourTotals.txt');
  New(LogHourTotals);
  if GenerateAllTotalsPerHour then PrintHourTotals;
  Dispose(LogHourTotals);

end;

function GenerateAllTotalsPerHour: boolean;

{ This routine will fill up the global variable LogHourTotals with data. }
label
  1;
var
  LineNumber, CurrentHourIndex          : integer;
  TotalLogQSOs                          : LONGINT;
  LastHourProcessed                     : Word;
  TempMults                             : integer;
begin
  Result := False;
  Windows.ZeroMemory(LogHourTotals, SizeOf(LogHourTotalArray));

  { Initialize the time on band status }

  with PLeftOnBiState do
  begin
    LastBand := NoBand;
    LastMode := NoMode;
    LastDateString := '';
    LastTimeString := '';
    LastHourIndex := -1;
    DoingBreak := False;
  end;
  Windows.ZeroMemory(@PLeftOnBiState.BandsThisMinute, SizeOf(PLeftOnBiState.BandsThisMinute));

  if not OpenLogFile then Exit;

  { Initialize variables }

  CurrentHourIndex := 0;
  LastHourProcessed := UNKNOWN_COUNTRY;
  NumberLogHours := 0;
  TotalLogQSOs := 0;
  LineNumber := 0;

  ReadVersionBlock;
  1:

  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      if LastHourProcessed <> TempRXData.tSysTime.qtHour then
      begin
        if CurrentHourIndex = 49 then
        begin
          ShowMessage(TC_MORETHAN50DIFFERENTHOURSINTHISLOG);
          Exit;
        end;

        if LastHourProcessed <> UNKNOWN_COUNTRY then inc(CurrentHourIndex);

        LogHourTotals^[CurrentHourIndex].HourName := IntToStr(TempRXData.tSysTime.qtHour);
        LastHourProcessed := TempRXData.tSysTime.qtHour;
      end;

      inc(TotalLogQSOs);

      inc(LogHourTotals^[CurrentHourIndex].QSOs[TempRXData.Band, TempRXData.Mode]);
      inc(LogHourTotals^[CurrentHourIndex].QSOs[AllBands, TempRXData.Mode]);
      inc(LogHourTotals^[CurrentHourIndex].QSOs[TempRXData.Band, Both]);
      inc(LogHourTotals^[CurrentHourIndex].QSOs[AllBands, Both]);

      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[TempRXData.Band, TempRXData.Mode], TempRXData.QSOPoints);
      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[AllBands, TempRXData.Mode], TempRXData.QSOPoints);
      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[TempRXData.Band, Both], TempRXData.QSOPoints);
      inc(LogHourTotals^[CurrentHourIndex].QSOPoints[AllBands, Both], TempRXData.QSOPoints);

      TempMults := 0;
      if TempRXData.DXMult then inc(TempMults);
      if TempRXData.DomesticMult then inc(TempMults);
      if TempRXData.ZoneMult then inc(TempMults);
      if TempRXData.PrefixMult then inc(TempMults);

      if TempMults <> 0 then
//      if (TempRXData.DXMult or TempRXData.DomesticMult or TempRXData.ZoneMult or TempRXData.PrefixMult) then
      begin
        inc(LogHourTotals^[CurrentHourIndex].Mults[TempRXData.Band, TempRXData.Mode], TempMults);
        inc(LogHourTotals^[CurrentHourIndex].Mults[AllBands, TempRXData.Mode], TempMults);
        inc(LogHourTotals^[CurrentHourIndex].Mults[TempRXData.Band, Both], TempMults);
        inc(LogHourTotals^[CurrentHourIndex].Mults[AllBands, Both], TempMults);
      end;

    end;
    goto 1;
  end;

  FinishOutLastHour;
  CheckTimeOnByBand(CurrentHourIndex);

  CloseLogFile;
  GenerateAllTotalsPerHour := True;
end;

procedure PrintHourTotals;

var
  //  Destination                           : Char;
  FileWrite                             : Text;
  Band                                  : BandType;
  //  TempString, FileName                  : Str80;
  TotalMults, LastHourPrinted, HourIndex, ThisHour, Result: integer;
  TotalQSOPoints, TotalContacts         : LONGINT;
  Score                                 : REAL;
  Day1QSOTotals, Day1MultTotals, Day2QSOTotals, Day2MultTotals: array[Band160..Band10] of LONGINT;
  DoingDay1                             : boolean;
  TotalDay1QSOs, TotalDay1Mults, TotalDay2QSOs, TotalDay2Mults: LONGINT;
  TempBand                              : BandType;
  ShowScore                             : boolean;
begin
  ShowScore := not (Contest in [CUPRFCW, CUPRFSSB, RUSSIAN160, CUPURAL, UKRAINECHAMPIONSHIP, {RADIOYOC,} RFCHAMPIONSHIPCW, RFCHAMPIONSHIPSSB]);
  OpenFileForWrite(FileWrite, ReportsFilename);

  //  if Header = '' then
  //  Header := GetResponse('Enter contest name and callsign : ');

  WriteLnVarCenter(FileWrite, ContestName + ' ' + MyCall);
  WriteLn(FileWrite);

  Write(FileWrite, 'HR     160       80       40       20       15       10   HR TOT CUM TOTAL');
  if ShowScore then WriteLn(FileWrite, '  SCORE') else WriteLn(FileWrite, '');

  Write(FileWrite, '--   -------  -------  -------  -------  -------  ------- ------ ---------');
  if ShowScore then WriteLn(FileWrite, '  -----') else WriteLn(FileWrite, '');

  HourIndex := 0;

  TotalMults := 0;
  TotalContacts := 0;
  TotalQSOPoints := 0;

  DoingDay1 := True;

  for Band := Band160 to Band10 do
  begin
    Day1QSOTotals[Band] := 0;
    Day1MultTotals[Band] := 0;
    Day2QSOTotals[Band] := 0;
    Day2MultTotals[Band] := 0;
  end;

  while LogHourTotals^[HourIndex].HourName <> '' do
  begin
    inc(LastHourPrinted);

    if (HourIndex > 0) and (LastHourPrinted > 23) then
    begin
      DoingDay1 := False;
      LastHourPrinted := 0;
    end;

    Val(LogHourTotals^[HourIndex].HourName, ThisHour, Result);

    if HourIndex = 0 then LastHourPrinted := ThisHour;

    while ThisHour <> LastHourPrinted do
    begin
      Write(FileWrite, LastHourPrinted: 2);
      for Band := Band160 to Band10 do Write(FileWrite, '     --- ');
      Write(FileWrite, '    --- ');
      Write(FileWrite, TotalContacts: 6, '/', TotalMults);

      if TotalMults < 10 then Write(FileWrite, ' ');
      if TotalMults < 100 then Write(FileWrite, ' ');

      if ShowScore then
      begin
        Score := TotalQSOPoints * TotalMults / 1000000;
        WriteLn(FileWrite, Score: 6: 3, ' M');
      end
      else
        WriteLn(FileWrite);

      inc(LastHourPrinted);
      if LastHourPrinted > 23 then LastHourPrinted := 0;
    end;

    TotalContacts := TotalContacts + LogHourTotals^[HourIndex].QSOs[AllBands, Both];
    TotalMults := TotalMults + LogHourTotals^[HourIndex].Mults[AllBands, Both];
    TotalQSOPoints := TotalQSOPoints + LogHourTotals^[HourIndex].QSOPoints[AllBands, Both];

    if DoingDay1 then
    begin

      for TempBand := Band160 to Band10 do
      begin
        Day1QSOTotals[TempBand] := Day1QSOTotals[TempBand] + LogHourTotals^[HourIndex].QSOs[TempBand, Both];
        Day1MultTotals[TempBand] := Day1MultTotals[TempBand] + LogHourTotals^[HourIndex].Mults[TempBand, Both];
      end;
    end
    else
    begin
      for TempBand := Band160 to Band10 do
      begin
        Day2QSOTotals[TempBand] := Day2QSOTotals[TempBand] + LogHourTotals^[HourIndex].QSOs[TempBand, Both];
        Day2MultTotals[TempBand] := Day2MultTotals[TempBand] + LogHourTotals^[HourIndex].Mults[TempBand, Both];
      end;
    end;

    with LogHourTotals^[HourIndex] do
    begin
      Write(FileWrite, ThisHour: 2);

      for Band := Band160 to Band10 do
      begin
        if QSOs[Band, Both] > 0 then
        begin
          Write(FileWrite, QSOs[Band, Both]: 6, '/', Mults[Band, Both]);
          if Mults[Band, Both] < 10 then Write(FileWrite, ' ');
        end
        else
          Write(FileWrite, '     --- ');
      end;

      Write(FileWrite, QSOs[AllBands, Both]: 5, '/', Mults[AllBands, Both]);

      if Mults[AllBands, Both] < 10 then Write(FileWrite, ' ');

      Write(FileWrite, TotalContacts: 6, '/', TotalMults);

      if TotalMults < 10 then Write(FileWrite, ' ');
      if TotalMults < 100 then Write(FileWrite, ' ');
      if ShowScore then
      begin
        Score := TotalQSOPoints * TotalMults / 1000000;
        WriteLn(FileWrite, Score: 6: 3, ' M');
      end
      else
        WriteLn(FileWrite);
    end;

    Val(LogHourTotals^[HourIndex].HourName, LastHourPrinted, Result);
    inc(HourIndex);
  end;

  TotalDay1QSOs := Day1QSOTotals[Band160] + Day1QSOTotals[Band80] +
    Day1QSOTotals[Band40] + Day1QSOTotals[Band20] +
    Day1QSOTotals[Band15] + Day1QSOTotals[Band10];

  TotalDay1Mults := Day1MultTotals[Band160] + Day1MultTotals[Band80] +
    Day1MultTotals[Band40] + Day1MultTotals[Band20] +
    Day1MultTotals[Band15] + Day1MultTotals[Band10];

  TotalDay2QSOs := Day2QSOTotals[Band160] + Day2QSOTotals[Band80] +
    Day2QSOTotals[Band40] + Day2QSOTotals[Band20] +
    Day2QSOTotals[Band15] + Day2QSOTotals[Band10];

  TotalDay2Mults := Day2MultTotals[Band160] + Day2MultTotals[Band80] +
    Day2MultTotals[Band40] + Day2MultTotals[Band20] +
    Day2MultTotals[Band15] + Day2MultTotals[Band10];

  Write(FileWrite, 'D1');

  for Band := Band160 to Band10 do
  begin
    Write(FileWrite, Day1QSOTotals[Band]: 5, '/', Day1MultTotals[Band]);
    if Day1MultTotals[Band] < 10 then Write(FileWrite, ' ');
    if Day1MultTotals[Band] < 100 then Write(FileWrite, ' ');
  end;

  WriteLn(FileWrite, '        ', TotalDay1QSOs: 6, '/', TotalDay1Mults);

  if not DoingDay1 then
  begin
    Write(FileWrite, 'D2');

    for Band := Band160 to Band10 do
    begin
      Write(FileWrite, Day2QSOTotals[Band]: 5, '/', Day2MultTotals[Band]);
      if Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
      if Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
    end;

    WriteLn(FileWrite, '        ', TotalDay2QSOs: 6, '/', TotalDay2Mults);
  end;

  Write(FileWrite, 'TO');

  for Band := Band160 to Band10 do
    //    if Band >= Band40 then
  begin
    Write(FileWrite, (Day1QSOTotals[Band] + Day2QSOTotals[Band]): 5, '/',
      Day1MultTotals[Band] + Day2MultTotals[Band]);

    if Day1MultTotals[Band] + Day2MultTotals[Band] < 10 then Write(FileWrite, ' ');
    if Day1MultTotals[Band] + Day2MultTotals[Band] < 100 then Write(FileWrite, ' ');
  end;

  WriteLn(FileWrite, '        ', TotalDay1QSOs + TotalDay2QSOs: 6, '/', TotalDay1Mults + TotalDay2Mults);

  Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;
end;

procedure FinishOutLastHour;

{ This routine will look at the last QSO processed by the PLeftOnBiState
  machine to see if we should fill in the last few minutes of the contest
  with the band of the last QSO.  This is done if the interval is less
  than 10 minutes. }

var
  LastMinuteString                      : Str20;
  Minute, LastMinute, Result            : integer;

begin
  with PLeftOnBiState do
  begin

    LastMinuteString := PostcedingString(LastTimeString, ':');

    Val(LastMinuteString, LastMinute, Result);

    if (LastMinute >= 50) and (LastMinute < 59) then
      for Minute := LastMinute + 1 to 59 do
      begin
        inc(LogHourTotals^[LastHourIndex].Minutes[LastBand, Both]);
        inc(LogHourTotals^[LastHourIndex].Minutes[AllBands, Both]);
      end;

  end;
end;

procedure CheckTimeOnByBand(LastHour: integer);

{ This procedure will look through the LogHourTotals to make sure that the
  individual band on times add up to the hourly on time (as indicated in
  the All, Both cell).  If the total of the band times exceeds that of
  the All, Both number, the band will the longest on time during the
  hour will have its time adjusted to make the total come out correctly. }

var
  Correction, HourTotal, BiggestBandTotal, HourIndex: integer;
  Band, BiggestBand                     : BandType;

begin
  for HourIndex := 0 to LastHour do
  begin
    HourTotal := 0;
    BiggestBand := NoBand;
    BiggestBandTotal := 0;

    for Band := Band160 to BandLight do
    begin
      HourTotal := HourTotal + LogHourTotals^[HourIndex].Minutes[Band, Both];

      if LogHourTotals^[HourIndex].Minutes[Band, Both] > BiggestBandTotal then
      begin
        BiggestBandTotal := LogHourTotals^[HourIndex].Minutes[Band, Both];
        BiggestBand := Band;
      end;
    end;

    Correction := LogHourTotals^[HourIndex].Minutes[AllBands, Both] - HourTotal;

    if Correction <> 0 then
      LogHourTotals^[HourIndex].Minutes[BiggestBand, Both] :=
        LogHourTotals^[HourIndex].Minutes[BiggestBand, Both] + Correction;

  end;
end;

procedure ContinentReport;
label
  1;
type
  ContListType = (USA, Canada, na, SA, eu, { UA,} af, ASI, Japan, OC, UK);
const
  ContListNames                         : array[ContListType] of string[7] =
    ('    USA', ' Canada', '     NA', '     SA', '   Euro' {, '     UA'}, 'African', '  Asian', '  Japan', '  Ocean', 'Unknown');
const
  MaxUnknownCalls                       = 10;

var
  Band                                  : BandType;
  ID, Call                              : CallString;
  CallAddress, AllBandTotal             : integer;
  ContTotals                            : array[BandType, ContListType] of integer;
  Cont, ListContinent                   : ContListType;
  TempQSOTotals                         : array[BandType] of integer;
  UnknownCalls                          : array[BandType, 0..MaxUnknownCalls - 1] of CallString;
  FileWrite                             : Text;
begin
  MakeReportFileName('Continent List.txt');
  Windows.ZeroMemory(@TempQSOTotals, SizeOf(TempQSOTotals));
  Windows.ZeroMemory(@ContTotals, SizeOf(ContTotals));
  if not OpenFileForWrite(FileWrite, ReportsFilename) then Exit;

  if not OpenLogFile then Exit;

  TotalLogQSOs := 0;
  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
//    if CorrectContestExchange then
    if GoodLookingQSO then
    begin
      inc(TempQSOTotals[TempRXData.Band]);

      Call := StandardCallFormat(TempRXData.Callsign, True);

      ID := TempRXData.QTH.CountryID;
//      if ID = 'UA' then
//        ListContinent := UA
//      else
      if ID = 'K' then
        ListContinent := USA
      else
        if ID = 'VE' then
          ListContinent := Canada
        else
          if ID = 'JA' then
            ListContinent := Japan
          else
            case TempRXData.QTH.Continent of
              NorthAmerica: ListContinent := na;
              SouthAmerica: ListContinent := SA;
              Europe: ListContinent := eu;
              Africa: ListContinent := af;
              Asia: ListContinent := ASI;
              Oceania: ListContinent := OC;
            else ListContinent := UK;
            end;

      inc(ContTotals[TempRXData.Band, ListContinent]);

      if ListContinent = UK then
        if ContTotals[TempRXData.Band, UK] <= MaxUnknownCalls then
          UnknownCalls[TempRXData.Band, ContTotals[TempRXData.Band, UK] - 1] := Call;

    end;
    goto 1;
  end;
  CloseLogFile;

 
  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, ContestTitle);
  //  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, 'Continent List');
  WriteLn(FileWrite);

  //  if not DoingDupingFile then
  begin
    WriteLn(FileWrite,
      '                    160    80    40    20    15    10    30    17    12    ALL'#13#10 +
      '                    ---   ---   ---   ---   ---   ---   ---   ---   ---    ---');
  end;

  for Cont := USA to UK do
  begin
    Write(FileWrite, '  ' + ContListNames[Cont] + ' calls =');

      //    if not DoingDupingFile then
    begin
      AllBandTotal := 0;

      for Band := Band160 to Band12 do
      begin
        Write(FileWrite, ContTotals[Band, Cont]: 6);
        AllBandTotal := ContTotals[Band, Cont] + AllBandTotal;
      end;

      WriteLn(FileWrite, AllBandTotal: 7);
    end;
      //    else
      //      WriteLn(FileWrite, ContTotals[Band160, Cont]: 6);
    if Cont = OC then WriteLn(FileWrite, '');
  end;

  WriteLn(FileWrite, '');

  Write(FileWrite, '    Total calls =');

  //  if not DoingDupingFile then
  begin
    AllBandTotal := 0;
    for Band := Band160 to Band12 do
    begin
      Write(FileWrite, TempQSOTotals[Band]: 6);
      AllBandTotal := TempQSOTotals[Band] + AllBandTotal;
    end;
    WriteLn(FileWrite, AllBandTotal: 7);
  end;
  //  else
  //    WriteLn(FileWrite, TempQSOTotals[Band160]: 6);

  WriteLn(FileWrite);

  for Band := Band160 to Band12 do
    if ContTotals[Band, UK] > 0 then
    begin
        //      TempString := BandString[Band];
        //      GetRidOfPrecedingSpaces(TempString);
        //      if not DoingDupingFile then
      Write(FileWrite, 'Unknowns on ', BandStringsArray[Band], ' = ');
        //      else
        //        Write(FileWrite, 'Unknowns = ');

      for CallAddress := 0 to ContTotals[Band, UK] - 1 do
        if CallAddress < MaxUnknownCalls then
          Write(FileWrite, UnknownCalls[Band, CallAddress], ' ');

      WriteLn(FileWrite);
    end;

  Close(FileWrite);
  FilePreview;
end;

procedure QSOsByCountryByBand;
begin

  //        WriteLnCenter('SHOW TOTAL QSOs BY COUNTRY BY BAND');
  //        WriteLn('This report will show the number of QSOs made in each country by band');

  New(CountryMultTotals);
  //  GenerateCountryMultiplierTotals;
  //  if not CheckLog then exit;
  if GenerateCountryMultiplierTotals then PrintQSOsByCountry;
  Dispose(CountryMultTotals);
  //  windows.FreeResource()

end;

function GenerateCountryMultiplierTotals: boolean;

{ This procedure will go through the log file and determine how many QSOs
  were made with each country - and record the callsign of the first QSO
  for each country.  The results are saved in the structure
  CountryMultTotals. }
label
  1;
begin
  GenerateCountryMultiplierTotals := False;
  Windows.ZeroMemory(CountryMultTotals, SizeOf(CountryMultiplierArray));
  if not OpenLogFile then Exit;
  ReadVersionBlock;
  TotalLogQSOs := 0;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      inc(TotalLogQSOs);
      if TempRXData.QTH.Country <= MaxCountries - 1 then
        if TempRXData.QTH.Country > 0 then
        begin
          if CountryMultTotals^[TempRXData.Band, TempRXData.QTH.Country].TotalQSOs = 0 then
            CountryMultTotals^[TempRXData.Band, TempRXData.QTH.Country].FirstCall := TempRXData.Callsign;

          if TempRXData.QTH.Country <> MAXWORD {>= 0} then
          begin
            inc(CountryMultTotals^[TempRXData.Band, TempRXData.QTH.Country].TotalQSOs);
          end;
        end;
    end;
    goto 1;
  end;
  CloseLogFile;
  GenerateCountryMultiplierTotals := True;
end;

procedure PrintQSOsByCountry;

var
  Count, CountryIndex                   : integer;
  FileWrite                             : Text;

  tCountryName                          : PChar;
  tCountryID                            : PChar;
  TotalCountryQSOs                      : LONGINT;
  TempBand                              : BandType;
begin

  MakeReportFileName('qsosbycountry.txt');
  OpenFileForWrite(FileWrite, ReportsFilename);

  WriteLn(FileWrite);
  WriteLnVarCenter(FileWrite, ContestTitle);
  WriteLnVarCenter(FileWrite, 'QSOs MADE IN EACH COUNTRY');
  WriteLn(FileWrite);
  WriteLn(FileWrite);
  WriteLn(FileWrite, '     Country               Prefix   160   80   40   20   15   10  Total  Percent');
  WriteLn(FileWrite, '     -------               ------  ---- ---- ---- ---- ---- ----  -----  -------');

  Count := 0;
  CountryIndex := 0;

//  while ctyGetCountryID(CountryIndex) <> '' do
  while CountryIndex < CTY.ctyNumberCountries do
  begin

    if (CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0) then

    begin
      inc(Count);
      TotalCountryQSOs := 0;
      tCountryName := ctyGetCountryNamePchar(CountryIndex);
      tCountryID := @CTY.ctyTable[CountryIndex].ID[1];
      begin
        asm
        push pchar(tCountryID)
        push pchar(tCountryName)
        mov eax,dword ptr Count
        push eax
        end;
        wsprintf(wsprintfBuffer, '%4u %-23s %-5s');
        asm add esp,20
        end;
        Write(FileWrite, wsprintfBuffer);
      end;

      for TempBand := Band160 to Band10 do
      begin
        if CountryMultTotals^[TempBand, CountryIndex].TotalQSOs > 0 then
          Write(FileWrite, CountryMultTotals^[TempBand, CountryIndex].TotalQSOs: 5)
        else
          Write(FileWrite, '    -');
        TotalCountryQSOs := TotalCountryQSOs + CountryMultTotals^[TempBand, CountryIndex].TotalQSOs;
      end;

      Write(FileWrite, TotalCountryQSOs: 7);
      WriteLn(FileWrite, ((TotalCountryQSOs * 100) / TotalLogQSOs): 8: 2);

    end;
    inc(CountryIndex);
  end;

  //  Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;

end;

procedure ExportToEDI;
var
  Band                                  : BandType;
begin
  for Band := Band160 to BandLight do
    ExportToEDIByBand(Band);
end;

procedure ExportToEDIByBand(Band: BandType);
label
  1;
var
  nNumberOfBytesToWrite                 : Cardinal;
  p                                     : PChar;
  TempInteger                           : integer;
  TempTag                               : CabrilloTags;
const
  EDI_ModeCodes                         : array[ModeType] of integer = (2, 7, 1, 0, 0, 6);
  EDI_NewArray                          : array[boolean] of PChar = (nil, 'N');
  EDI_DupeArray                         : array[boolean] of PChar = (nil, 'D');
begin
  if QSOTotals[Band, Both] = 0 then Exit;

  Format(tReportsFilename, '%s%s_%s.EDI', TR4W_LOG_PATH_NAME, @MyCall[1], BandStringsArrayWithOutSpaces[Band]);

  DeleteSlashes(tReportsFilename);
  if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;

  if not OpenLogFile then
  begin
    CloseHandle(tReportFileWrite);
    Exit;
  end;

  Windows.ZeroMemory(@wsprintfBuffer, SizeOf(wsprintfBuffer));
  for TempTag := ctAddress to ctAddressCountry do
  begin
    if Windows.GetDlgItemText(CreateCabrilloWindow, integer(TempTag) + 200, @TempBuffer1, SizeOf(TempBuffer1)) = 0 then Continue;
    Windows.lstrcat(wsprintfBuffer, TempBuffer1);
    Windows.lstrcat(wsprintfBuffer, ' ');
  end;

  Windows.GetDlgItemText(CreateCabrilloWindow, integer(ctName) + 200, @TempBuffer1, SizeOf(TempBuffer1));
  Windows.GetDlgItemText(CreateCabrilloWindow, integer(ctCategoryOperator) + 200, @TempBuffer2, SizeOf(TempBuffer2));

  TempInteger := QSOTotals[Band, Both];
  p := EDIFBANDSTRINGSARRAY[Band];
  asm
  push TempInteger
  push offset TempBuffer2
  push offset wsprintfBuffer
  push offset TempBuffer1
  push p
  push offset MyGrid[1]
  push offset MyCall[1]
  push offset ContestName[1]
  end;
  nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER,
    '[REG1TEST;1]'#13#10 +
    'TName=%s'#13#10 +
    'PCall=%s'#13#10 +
    'PWWLo=%s'#13#10 +
    'PBand=%s'#13#10 +
    'RName=%s'#13#10 +
    'PAdr1=%s'#13#10 +
    'PSect=%s'#13#10 +
    '[QSORecords;%u]'#13#10
    );
  asm add esp,40 end;
  sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      if TempRXData.Band <> Band then goto 1;
      TempInteger := EDI_ModeCodes[TempRXData.Mode];

      p := EDI_DupeArray[TempRXData.ceDupe];
      asm
      push p
      end;

      p := EDI_NewArray[TempRXData.DXMult];
      asm
      push p
      end;

      p := EDI_NewArray[TempRXData.DomesticMult];
      asm
      push p

      xor eax, eax
      mov ax, TempRXData.QSOPoints
      push eax

      push offset TempRXData.QTHString[1]

      push TempRXData.NumberReceived

      xor eax, eax
      mov ax, TempRXData.RSTReceived
      push eax

      push TempRXData.NumberSent

      xor eax, eax
      mov ax, TempRXData.RSTSent
      push eax

      push TempInteger

      push offset TempRXData.Callsign[1]

      xor eax, eax
      mov al, TempRXData.tSysTime.qtMinute
      push eax

      xor eax, eax
      mov al, TempRXData.tSysTime.qtHour
      push eax

      xor eax, eax
      mov al, TempRXData.tSysTime.qtDay
      push eax

      xor eax, eax
      mov al, TempRXData.tSysTime.qtMonth
      push eax

      xor eax, eax
      mov al, TempRXData.tSysTime.qtYear
      push eax
      end;

      nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER,
        '%02d%02d%02d;' + {date}
        '%02d%02d;' + {time}
        '%s;' + {callsign}
        '%d;' + {mode code}
        '%d;' + {rst sent}
        '%03d;' + {sent qso number}
        '%d;' + {rst received}
        '%03d;' + {received qso number}
        ';' + {Received Exchange}
        '%s;' + {Received WWL}
        '%d;' + {QSO points}
        ';' + {New-Exchange}
        '%s;' + {New-WWL}
        '%s;' + {New-DXCC}
        '%s' + {Duplicate-QSO}
        #13#10
        );
      asm add esp,72 end;
      sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);

    end;
    goto 1;
  end;
  CloseHandle(tReportFileWrite);
  CloseLogFile;

  PreviewFileNameAddress := tReportsFilename;
  FilePreview;
end;

procedure ExportToADIF;
label
  1;

var
  sBuffer                               : string;
  tCallStringLength                     : Cardinal;

  tBandString                           : PChar;
  tBandStringLength                     : Cardinal;

  tModeString                           : PChar;
  tModeStringLength                     : Cardinal;

  tRSTSendStringLength                  : Cardinal;
  tRSTRcvdStringLength                  : Cardinal;

  tContestName                          : PChar;
  tContestNamelength                    : Cardinal;
  nNumberOfBytesToWrite                 : Cardinal;
  p                                     : PChar;
  nLength                               : integer;
  sTemp                                 : string;
  dtReportTime                          : TDateTime;
  stxString                             : string;
  sMode                                 : string;
  sSubMode                              : string;
//  IOTAstring                            : Str10;
begin
  dtReportTime := Now;
  lstrcpy(tReportsFilename, TR4W_LOG_FILENAME);
  tReportsFilename[Windows.lstrlen(tReportsFilename) - 3] := #0;
  lstrcat(tReportsFilename, 'ADI');
  if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;

  if not OpenLogFile then
  begin
    CloseHandle(tReportFileWrite);
    Exit;
  end;

  DecimalSeparator := '.'; // Set this so we use . as reqired by ADIF and not localized separator ny4i
  
  // Issue 405 to fix up the header - ny4i
  sWriteFileFromString(tReportFileWrite,'ADIF File'#13#10);
  sWriteFileFromString(tReportFileWrite,'Created by TR4W version ' + TR4W_CURRENTVERSION + ' on ' + FormatDateTime('nn-mmm-yyyy hh:mm:ss',dtReportTime) + #13#10);

  WriteADIFField('ADIF_VER','3.1.0');
  sWriteFile(tReportFileWrite, #13#10, 1);

  WriteADIFField('CREATED_TIMESTAMP',FormatDateTime('yyyymmdd hhnnss',dtReportTime));
  sWriteFile(tReportFileWrite, #13#10, 1);

  WriteADIFField('PROGRAMID','TR4W');
  sWriteFile(tReportFileWrite, #13#10, 1);

  WriteADIFField('PROGRAMVERSION',TR4W_CURRENTVERSION);
  sWriteFile(tReportFileWrite, #13#10, 1);

  sWriteFile(tReportFileWrite, #13#10'<EOH>'#13#10, 9);


  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      // If there is nothing in the ADIFName, then use the ContestTypeSA[Contest]
      if length(ContestsArray[Contest].ADIFName) = 0 then
         begin
         tContestName := ContestTypeSA[Contest]
         end
      else
         begin
         tContestName := ContestsArray[Contest].ADIFName;     // NY4I
         end;
      tContestNamelength := Windows.lstrlen(tContestName);

      tCallStringLength := length(TempRXData.Callsign);

      tBandString := ADIFBANDSTRINGSARRAY[TempRXData.Band];
      tBandStringLength := Windows.lstrlen(tBandString);
    //   if contest =  RADIOVHFFD  then       // added 4.61.1
        begin                              // 4.61.1
        if tBandString = '432' then
         begin
           tBandString := '70CM';
           tBandStringLength := 4;
         end;
        if tBandString = '1GH' then
         begin
           tBandString := '23CM';
           tBandStringLength := 4;
         end;
        end;

          //          if TempRXData.ceFMMode then TempMode := FM else TempMode := TempRXData.Mode;
      tModeString := ADIFModeString[TempRXData.Mode];
      tModeStringLength := Windows.lstrlen(tModeString);


      tRSTSendStringLength := DigitsIn(TempRXData.RSTSent);  // ny4i This changed as RST could be different lengths now.
      tRSTRcvdStringLength := DigitsIn(TempRXData.RSTReceived);
      //if TempRXData.RSTSent > 99 then tRSTSendStringLength := 3 else tRSTSendStringLength := 2;
      //if TempRXData.RSTReceived > 99 then tRSTRcvdStringLength := 3 else tRSTRcvdStringLength := 2;

      sBuffer := SysUtils.Format('<CALL:%u>%s <BAND:%u>%s <QSO_DATE:8>%04d%.2d%.2d <TIME_ON:6>%.2d%.2d%.2d <TIME_OFF:6>%.2d%.2d%.2d <RST_SENT:%u>%d <RST_RCVD:%u>%d <CONTEST_ID:%u>%s '
                  ,[length(TempRXData.Callsign), TempRXData.Callsign
                  ,length(ADIFBANDSTRINGSARRAY[TempRXData.Band]), ADIFBANDSTRINGSARRAY[TempRXData.Band]
                 // ,length(ExtendedModeStringArray[TempRXData.Mode]), ExtendedModeStringArray[TempRXData.Mode]
                 // ,length(ModeStringArray[TempRXData.Mode]), ModeStringArray[TempRXData.Mode]
                  ,TempRXData.tSysTime.qtYear+2000
                  ,TempRXData.tSysTime.qtMonth
                  ,TempRXData.tSysTime.qtDay
                  ,TempRXData.tSysTime.qtHour
                  ,TempRXData.tSysTime.qtMinute
                  ,TempRXData.tSysTime.qtSecond
                  ,TempRXData.tSysTime.qtHour
                  ,TempRXData.tSysTime.qtMinute
                  ,TempRXData.tSysTime.qtSecond
                  ,tRSTSendStringLength, TempRXData.RSTSent
                  ,tRSTRcvdStringLength, TempRXData.RSTReceived
                  ,tContestNamelength, StrPas(tContestName)
                  ]
                  );
      sWriteFileFromString(tReportFileWrite, sBuffer);

      if TempRXData.ExtMode = eNoMode then
         begin
         sMode := ADIFModeString[TempRXData.mode];
         end
      else if TempRXData.ExtMode = eFT4 then    // ??? In MFSKModes[TempRXData.ExtMode]?
         begin
         sMode := 'MFSK';
         sSubMode := ExtendedModeStringArray[TempRXData.ExtMode];
         end
      else
         begin
         sMode := ExtendedModeStringArray[TempRXData.ExtMode];
         end;
       WriteADIFField('MODE',sMode);
       if sSubMode <> '' then
          begin
          WriteADIFField('SUBMODE',sSubMode);
          end;




      if TempRXData.Frequency <> 0 then //14149280  or 7025000
         begin
         // Making this simpler...
         DecimalSeparator := '.';
         sTemp := FloatToStr((TempRXData.Frequency/1000000));
         sBuffer := SysUtils.Format('<FREQ:%u>%s',[length(sTemp),sTemp]);
         sWriteFileFromString(tReportFileWrite, sBuffer);

        {asm
        mov eax,[TempRXData.Frequency]
        mov ecx,1000000
        cdq
        idiv ecx
        push edx
        push eax
        end;
        nNumberOfBytesToWrite := wsprintf(ADIF_FREQ_STRING, '%u.%06u ');
        asm add esp,16 end;

        asm
        lea eax,ADIF_FREQ_STRING
        push eax
        push nNumberOfBytesToWrite
        end;
        nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '<FREQ:%u>%s ');
        asm add esp,16 end;

//        nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<FREQ:%u>%s',nNumberOfBytesToWrite,ADIF_FREQ_STRING);

        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
        }
      end;

      WriteADIFField('SRX_STRING',TempRXData.ExchString);
      stxString := GetMyExchangeForExport;
      WriteADIFField('STX_STRING',Trim(stxString));

      if TempRXData.Precedence <> #0 then
      begin
        nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<PRECEDENCE:1>%c ', TempRXData.Precedence);
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
      end;

      if TempRXData.Check <> 0 then
      begin
        nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<CHECK:2>%02u', TempRXData.Check);
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
      end;

      if TempRXData.QTHString <> '' then
         begin
   //    getridofprecedingspaces(TempRXData.QTHString);
         p := nil;
         p := @TempRXData.QTHString[1];
         if TempRXData.QTHString[1] = ' ' then        //n4af 4.34.6    remove preceding space using pointer math
            begin                                           //n4af 4.34.6
            inc(p);                                          //n4af 4.34.6    bump pointer past space
            tCallStringLength := length(TempRXData.QTHString)-1;  //n4af 4.34.6
            end
         else
            tCallStringLength := length(TempRXData.QTHString);

         if TempRXData.DomesticMult then           // ny4i Issue 398
            begin
            WriteADIFFIeld('STATE',TempRXData.QTHString);
            end;

        //if ContestsArray[Contest].DM = DomesticMult

        if (LooksLikeAGrid(TempRXData.DomesticQTH) and (ActiveDomesticMult <> RDADistrict)) then
        begin
          nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<GRIDSQUARE:%u>%s ', tCallStringLength, p);
          sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
        end
        else
          case Contest of
            WAG:
              begin
                nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<DOK:%u>%s', tCallStringLength, p);
                sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
              end;

            ARRLFIELDDAY, ARRLSSCW, ARRLSSSSB, WINTERFIELDDAY:
              begin
                if TempRXData.QTHString <> 'DX' then     // Change to validate it is a section
                   begin
                   WriteADIFField('ARRL_SECT',TempRXData.QTHString);
                   //nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<ARRL_SECT:%u>%s ', tCallStringLength, p);
                   //sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
                   end;

                nLength := length(MyFDClass) + 1 + length(MySection);
                sBuffer := SysUtils.Format('<STX_STRING:%u>%s %s ',[nLength, MyFDClass, MySection]);
                sWriteFileFromString(tReportFileWrite, sBuffer);

                //nLength := length(TempRXData.ceClass) + 1 + length(TempRXData.QTHString);
                //sBuffer := SysUtils.Format('<SRX_STRING:%u>%s %s ', [nLength, TempRXData.ceClass, TempRXData.QTHString]);
                //sWriteFileFromString(tReportFileWrite, sBuffer);

              end;
            CQ160CW, CQ160SSB, NASPRINTCW, SPRINTSSB, NASPRINTRTTY, NAQSOCW, NAQSOSSB, NAQSORTTY:
              begin
                //nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<STATE:%u>%-4s ', tCallStringLength, p);  // Removed NY4I Issue 398 as we use CE.DomesticMult but whazt happens if Italy works Italy?
                //sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
              end;

            IOTA:
              begin
                strU(TempRXData.DomesticQTH);
                nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<IOTA:6>%s ', @TempRXData.DomesticQTH[1]);
                sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
              end;

            IARU:
              begin
                nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<APP_TR4W_HQ:%u>%-7s ', tCallStringLength, p);
                sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
              end;
          else
            begin
               nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<QTH:%u>%s ',tCallStringLength, p);
               sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);  //n4af 04.30.2
            end;
          end;
        end;


      if TempRXData.Name <> '' then
      begin
        nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<NAME:%u>%s ', length(TempRXData.Name), @TempRXData.Name[1]);
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);         //n4af 04.30.2
      end;

   if ((TempRXData.Power <> '') and (Contest = FOCMARATHON)) Then
      begin
        nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<FOC_NUM:%u>%s', length(TempRXData.Power), @TempRXData.Power[1]);
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
      end;
      if ((TempRXData.Power <> '') and (Contest <> FOCMARATHON)) then
      begin
        nNumberOfBytesToWrite := Format(CABRILLO_BUFFER, '<RX_PWR:%u>%s', length(TempRXData.Power), @TempRXData.Power[1]);
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);          //n4af 04.30.2
      end;

      if ExchangeInformation.QSONumber then
      begin
        if TempRXData.NumberReceived <> -1 then
        begin
          asm
          push TempRXData.NumberReceived
          end;
          nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '<SRX:5>%05u');
          asm add esp,12
          end;
          sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
        end;

        asm
          push TempRXData.NumberSent
        end;
        nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '<STX:5>%05u ');
        asm add esp,12
        end;
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
      end;
      if TempRXData.Zone <> DUMMYZONE then
      begin
        if ActiveZoneMult in [CQZones, ITUZones] then
        begin
          if ActiveZoneMult = CQZones then p := '<CQZ:2>%02u' else p := '<ITUZ:2>%02u';
          asm
        xor  eax,eax
        mov  al,TempRXData.Zone
        push eax
          end;
          nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, p);
          asm add esp,12
          end;
          sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
        end
        else
        begin
          if (ExchangeInformation.Zone and (ActiveZoneMult = NoZoneMults)) then
          begin

            if CTY.ctyZoneMode = CQZoneMode then p := '<CQZ:2>%02u' else p := '<ITUZ:2>%02u';
            asm
        xor  eax,eax
        mov  al,TempRXData.Zone
        push eax
            end;
            nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, p);
            asm add esp,12
            end;
            sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
          end;
        end;
      end;

      if TempRXData.TenTenNum <> MAXWORD then
      begin
        asm
        xor  eax,eax
        mov  ax, TempRXData.TenTenNum
        push eax
        end;
        nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '<TEN_TEN:5>%05u');
        asm add esp,12
        end;
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
      end;

      if TempRXData.Age <> 0 then
      begin
        asm
        xor  eax,eax
        mov  al, TempRXData.Age
        push eax
        end;
        nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '<AGE:3>%03u');
        asm add esp,12
        end;
        sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
      end;

      if TempRXData.ceOperator[0] <> #0 then
      begin
        asm
        lea eax, TempRXData.ceOperator
        push eax
        end;
        Windows.lstrlen(TempRXData.ceOperator);
        asm push eax end;
      end

      else

        asm
        lea eax,MyCall+1
        push eax
        xor eax,eax
        mov al, byte ptr MyCall
        push eax
        end;
      nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '<OPERATOR:%u>%s ');
      asm add esp,16 end;
      sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);

      sWriteFile(tReportFileWrite, '<EOR>'#13#10, 7);
    end;
    goto 1;
  end;
  CloseHandle(tReportFileWrite);
  CloseLogFile;
  PreviewFileNameAddress := tReportsFilename;
  FilePreview;
end;



procedure ExportToCSV;              //n4af 04/18/14 new procedure added
label
  1;

var
 
  tCallStringLength                     : Cardinal;

  tBandString                           : PChar;
  tBandStringLength                     : Cardinal;

  tModeString                           : PChar;
  tModeStringLength                     : Cardinal;

  tRSTSendStringLength                  : Cardinal;
  tRSTRcvdStringLength                  : Cardinal;

  tContestName                          : PChar;
  tContestNamelength                    : Cardinal;
  nNumberOfBytesToWrite                 : Cardinal;

begin

  lstrcpy(tReportsFilename, TR4W_LOG_FILENAME);
  tReportsFilename[Windows.lstrlen(tReportsFilename) - 3] := #0;
  lstrcat(tReportsFilename, 'CSV');
  if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;

  if not OpenLogFile then
  begin
    CloseHandle(tReportFileWrite);
    Exit;
  end;


  //nNumberOfBytesToWrite := Format(wsprintfBuffer, TR4W_CURRENTVERSION + #13#10#13#10#13#10, @ContestTitle[1]);
  //NumberOfBytesToWrite := Format(wsprintfBuffer, TR4W_CURRENTVERSION + #13#10#13#10#13#10, @ContestTitle[1]);

  //sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);

  ReadVersionBlock;
  1:

  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
      tContestName := ContestTypeSA[Contest];
      tContestNamelength := Windows.lstrlen(tContestName);

      tCallStringLength := length(TempRXData.Callsign);

      tBandString := ADIFBANDSTRINGSARRAY[TempRXData.Band];
      tBandStringLength := Windows.lstrlen(tBandString);
     
          //          if TempRXData.ceFMMode then TempMode := FM else TempMode := TempRXData.Mode;
      tModeString := ADIFModeString[TempRXData.Mode];
      tModeStringLength := Windows.lstrlen(tModeString);

      if TempRXData.RSTSent > 99 then tRSTSendStringLength := 3 else tRSTSendStringLength := 2;
      if TempRXData.RSTReceived > 99 then tRSTRcvdStringLength := 3 else tRSTRcvdStringLength := 2;

     asm
        push tContestName
     //   mov eax,dword ptr tContestNamelength
      //  push eax

        xor eax,eax
       mov ax, word ptr TempRXData.RSTReceived
        push eax
    //    push tRSTRcvdStringLength

       xor eax,eax
        mov ax, word ptr TempRXData.RSTSent
        push eax
    //    push tRSTSendStringLength

        movzx eax,TempRXData.tSysTime.qtSecond
        push eax

        movzx eax,TempRXData.tSysTime.qtMinute
        push eax

        movzx eax,TempRXData.tSysTime.qtHour
        push eax

        movzx eax,TempRXData.tSysTime.qtDay
        push eax

        movzx eax,TempRXData.tSysTime.qtMonth
        push eax

        movzx eax,TempRXData.tSysTime.qtYear
        add eax,2000
        push eax

        push tModeString
    //    mov eax,dword ptr tModeStringLength
    //    push eax

        push tBandString
    //    mov eax,dword ptr tBandStringLength
    //    push eax

        lea  eax,TempRXData.Callsign+1
        push eax
  //       mov eax,dword ptr tCallStringLength
   //      push eax

      end;

      nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER,
        '%s,%s,%s,%u%02d%02d,%02d%02d%02d,%u,%u,%s');


      end;

      sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);

      sWriteFile(tReportFileWrite, #13#10, 2);
     //  sWriteFile(tReportFileWrite, #13#10);
    goto 1;
   end;
  
  CloseHandle(tReportFileWrite);
  CloseLogFile;
  PreviewFileNameAddress := tReportsFilename;
  FilePreview;
end;


procedure ExportToTRLogFormat;
label
  1;

begin

end;

function tGenerateSummaryPortionOfCabrilloFile: boolean;
var
  nNumberOfBytesToWrite                 : Cardinal;
  T2                                    : PChar;
  T3                                    : String;
  TempTag                               : CabrilloTags;
  TempPchar                             : PChar;
  Operator                              : integer;
  ControlID                             : integer;
  TempErmakField                        : TErmakFields;
  TempInteger                           : integer;
const
  op                                    = 'OPERATORS: ';
begin
  Result := False;

  if Contest = ARRL10 then
    if Windows.GetDlgItemText(CreateCabrilloWindow, integer(ctLocation) + 200, @TempBuffer2, SizeOf(TempBuffer2)) = 0 then
    begin
      showwarning('LOCATION field is empty.');
      Exit;
    end;

  if not tOpenFileForWrite(tReportFileWrite, tReportsFilename) then Exit;
  T2 := @MyCall[1];
  if length(ContestsArray[Contest].CABName) = 0 then
         begin
         T3 := ContestTypeSA[Contest]
         end
      else
         begin
         T3 := ContestsArray[Contest].CABName;     // NY4I
         end;

  //T3 := ContestTypeSA[contest];        // 4.78.2
   if Contest = GENERALQSO then       // 4.78.3        // ALLOW CUSTOM CONFIG Contest Title or Contest Name
      if length(ContestTitle) <> 0  then
         T3 := ContestTitle
      else if length(ContestName) <> 0  then      // 4.78.3
         T3 := ContestName;

  asm
  call TotalScore
  push eax
  push t3
  push t2
//  push t1
  end;
  nNumberOfBytesToWrite := wsprintf(wsprintfBuffer,
    'START-OF-LOG: 3.0'#13#10'CREATED-BY: ' + TR4W_CURRENTVERSION + #13#10'CALLSIGN: %s'#13#10'CONTEST: %s'#13#10'CLAIMED-SCORE: %d'#13#10);
  asm add esp,20
  end;
  sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);

  for TempTag := Low(CabrilloTags) to High(CabrilloTags) do
  begin
    if ErmakSpecification then if TempTag = ctOperators then Continue;

    Windows.GetDlgItemText(CreateCabrilloWindow, integer(TempTag) + 200, @TempBuffer2, SizeOf(TempBuffer2));
    //if TempBuffer2[0] = #0 then Continue;
    if TempTag = ctOperators then
       begin
       ;
       end
    else if TempBuffer2[0] =#0 then
      begin
      Continue;
      end;

    TempPchar := @CabrilloTagsArray[TempTag].ctrTag[1];
    if TempTag = ctOperators then
       begin
       Format(TempBuffer2, '%s', PChar(GetOperatorsFromLog));
       end;
    asm
    push offset TempBuffer2
    push TempPchar
    end;
    nNumberOfBytesToWrite := wsprintf(wsprintfBuffer, '%s: %s'#13#10);
    asm add esp,16
    end;
    sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
  end;

  if ErmakSpecification then
    for Operator := 1 to 10 do
      for TempErmakField := Low(TErmakFields) to High(TErmakFields) do
      begin
        ControlID := integer(TempErmakField) + (Operator) * 100;
        asm
        push ControlID
        end;
        wsprintf(TempBuffer2, OPERATORINFO);
        asm add esp,12 end;
        TempInteger := GetPrivateProfileString(ERMAKSECTION, TempBuffer2, '?', TempBuffer1, SizeOf(TempBuffer1), TR4W_INI_FILENAME);
        TempPchar := @TempBuffer1[0];
        if TempErmakField = efOp then
        begin
          if TempBuffer1[0] <> '1' then Break;
          sWriteFile(tReportFileWrite, op, length(op));
          Continue;
        end;

        if TempErmakField = efLevel then
          if TempBuffer1[0] in ['0'..'7'] then
          begin
            TempPchar := ZVANIYA[Ord(TempBuffer1[0]) - Ord('0')];
            TempInteger := Windows.lstrlen(TempPchar);
          end;

        if TempErmakField = efTrainer then
        begin
          if TempBuffer1[0] = '1' then
          begin
            TempPchar := '??????';
            TempInteger := 6;
          end
          else
          begin
            TempPchar := nil;
            TempInteger := 0;
          end;

        end;

        sWriteFile(tReportFileWrite, TempPchar^, TempInteger);
        if TempErmakField <> High(TErmakFields) then
          sWriteFile(tReportFileWrite, ', ', 2)
        else
          sWriteFile(tReportFileWrite, #13#10, 2);
      end;

  Result := True;
end;

function tGenerateLogPortionOfCabrilloFile: boolean;
label
  1;
var
   s                                    : string;
   i                                    : integer;
  nNumberOfBytesToWrite                 : Cardinal;
  HisCallsign                           : PChar;
  RSTSent                               : PChar;
  RSTReceived                           : PChar;
  Freq                                  : PChar;
  ModeString                            : PChar;
  cMyZone                               : integer;
  cMyState                              : PChar;
  cMyName                               : PChar;
  csName                                : PChar;
  cMyFOCNumber                          : PChar;
  cMyCheck                              : PChar;
  csCheck                               : integer {PChar};
  crFOCNr                               : PChar;
  cMyGrid                               : PChar;
  csPower                               : PChar;
  hisAge                                : Integer;
  csQTHString                           : PChar;
  HisZone                               : integer;
  str1                                  : widestring;
  nrReceived                            : integer;
  nrSent                                : integer;
  tempcategoryoperator                  : tcategoryoperator;

  T1                                    : PChar;
  T2                                    : PChar;
  T3                                    : PChar;
  T4                                    : PChar;      // 4.73.6
  cRandomCharsReceived                  : PChar;
  cKids                                 : PChar;
  TempGrid                              : Str20;
  previousqsonr                         : integer;
  TransmitterIDPos                      : integer;
  contacts                              : integer;
  PreviousQTHString                     : Str10;
  pnr                                   : integer;
  hisnr                                 : integer;
  rxnr                                  : integer;
  slOperators                           : TStringList;


begin
  TransmitterIDPos := 83;
  pnr := 0;
  if (Contest = NAQSOCW) or (Contest = NAQSOSSB) or (Contest = NAQSORTTY) then TransmitterIDPos := 92;        // 4.67.7
  //if Contest =  NAQPCW  then TransmitterIDPos := 92;
  contacts := 0;
  Result := False;


  if not OpenLogFile then Exit;

  ReadVersionBlock;

   try
      try
      slOperators := TStringList.Create;
      slOperators.Duplicates := dupIgnore;
      TempGrid := MyGrid;
  TempGrid[5] := #0;
  cMyGrid := @TempGrid[1];

  cMyName := @MyName[1];

  cMyZone := StrToInt(MyZone);
  cMyState := @MyState[1];

  previousqsonr := 0;
  1:
  if ReadLogFile then
  begin
    inc(contacts);
    slOperators.Add(TempRXData.ceOperator);

    HisCallsign := @TempRXData.Callsign[1];

    asm
    xor eax,eax
    mov ax,word ptr TempRXData.RSTSent
    push eax
    end;

    wsprintf(CABRILLO_RST_SEND, '%d');
    asm add esp,12 end;
    RSTSent := CABRILLO_RST_SEND;

    asm
    xor eax,eax
    mov ax,word ptr TempRXData.RSTReceived
    push eax
    end;
    wsprintf(CABRILLO_RST_RCVD, '%d');
    asm add esp,12 end;
    RSTReceived := CABRILLO_RST_RCVD;

    nrReceived := TempRXData.NumberReceived;
    nrSent := TempRXData.NumberSent;
    Freq := tCabrilloFreqString[TempRXData.Band];

    if tShowFrequencyinLog then
    begin
      if TempRXData.Frequency > 0 then
        if TempRXData.Frequency < 30000000 then
          Freq := inttopchar(TempRXData.Frequency div 1000);
    end;
    // This was just assumeing any digital contact was RY which is obviously not true.
    if TempRXData.Mode = Digital then
       begin
       if TempRXData.ExtMode = eRTTY then
          begin
          ModeString := 'RY';
          end
       else
          begin
          ModeString := 'DG';
          if Contest = WINTERFIELDDAY then
             begin
             ModeString := 'DI'; // Fluke in WFD's parser they have not yet fixed'
             end;
          end;
       end
    else
       begin
       ModeString := tCabrilloModeString[TempRXData.Mode];
       end;

    if DoingDomesticMults then
    begin
      if LiteralDomesticQTH then
        csQTHString := @TempRXData.QTHString[1]
      else
        csQTHString := @TempRXData.DomesticQTH {DomMultQTH} [1];
    end
    else
      csQTHString := @TempRXData.QTHString[1];

    if Contest in [CUPRFCW, CUPRFSSB] then
      csQTHString := @TempRXData.QTHString[1];


 if Contest in [CALQSOPARTY]  then
  begin


     csQTHString := @TempRXData.QTHString[1] ;
   // else
   //    csQTHString := @TempRXData.DomMultQTH[1];
if TempRXData.DomMultQTH = '' then
  begin
  TempRXData.DomMultQTH := 'DX';
  csQTHString := 'DX';
  end;
  end;
    HisZone := TempRXData.Zone;

    csName := @TempRXData.Name[1];

    if GoodLookingQSO then
    begin

          {Make First part}
      asm
            lea  eax,MyCall[1]
            push eax
            movzx eax,TempRXData.tSysTime.qtMinute
            push eax

            movzx eax,TempRXData.tSysTime.qtHour
            push eax

            movzx eax,TempRXData.tSysTime.qtDay
            push eax

            movzx eax,TempRXData.tSysTime.qtMonth
            push eax

            movzx eax,TempRXData.tSysTime.qtYear
            add eax,2000
            push eax

            push ModeString
            push Freq
      end;
      wsprintf(CABRILLO_FIRST_PART, 'QSO: %5s %s %d-%02d-%02d %02d%02d %-14s');
      asm add esp,40
      end;
{
      ActiveExchange := RSTQSONumberExchange;
      nrReceived := StrToInt(TempRXData.ceClass);
      Windows.ZeroMemory(@CABRILLO_RST_RCVD, SizeOf(CABRILLO_RST_RCVD));
      Windows.lstrcat(CABRILLO_RST_RCVD, '599');
}
          {Make Exchanges Strings}
      case ActiveExchange of

        GridExchange:
          begin
            Format(CABRILLO_MYEX, '%-11s', cMyGrid);
            Format(CABRILLO_HISEX, '%-11s', csQTHString);
          end;

        RSTNameAndQTHExchange:
          begin
            Format(CABRILLO_MYEX, '%-3s %-5s %-7s', RSTSent, cMyName, cMyState);
            Format(CABRILLO_HISEX, '%-3s %-5s %-7s', RSTReceived, csName, csQTHString);
          end;

        QSONumberAndNameExchange:
          begin
            asm
                push cMyName
                push nrSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3d %-7s');
            asm add esp,16
            end;

            asm
            push csName
            push nrReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3u %-7s');
            asm add esp,16
            end;
          end;




        RSTAndPostalCodeExchange:
          begin
            if contacts = 1 then
              Format(CABRILLO_MYEX, '%-3s %-10s', RSTSent, @MyPostalCode[1])
            else
              Format(CABRILLO_MYEX, '%-3s %-10s', RSTSent, @PreviousQTHString[1]);
            Format(CABRILLO_HISEX, '%-3s %-10s', RSTReceived, @TempRXData.QTHString[1]);
          end;

        RSTQSONumberAndGridSquareExchange:


          begin
            asm
                push cMyGrid
                push nrSent
                push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-4d %-7s');
            asm add esp,20
            end;

            asm
                push csQTHString
                 push nrReceived
                push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-4u %-7s');
            asm add esp,20
            end;
          end;

 {         RSTAndSerialNumberAndGridandPossibleMemberNumber:
          begin
          end;
  }
       RSTQSONumberOrDomesticQTHExchange:      //n4af 4.40.6
          begin
         p  := (IntToPchar(nrReceived)) ;

          if nrReceived <  1 then
          p := nil;

 if cMystate[1] <> '' then
 begin
            asm
               push cMyState
               push RSTSent
             end ;
  //            wsprintf(CABRILLO_MYEX, '%-3s  %-11s') ;      // n4af 4.70.3
                wsprintf(CABRILLO_MYEX, '%-3s  %-5s') ;        // 4.88.3
 end ;

 if cMystate[1] = '' then
   begin
            asm
               push nrSent
               push RSTSent
            end;
    wsprintf(CABRILLO_MYEX, '%-3s  %-6d') ;
   end;

            asm add esp,16
            end ;

   if p  <> nil then
    begin
             asm
                push csQTHString
                 push nrReceived
                push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %6d %-6s');
            asm add esp,20
            end;
     end;
     if p = nil then
     begin
             asm
                push csQTHString

                push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s   %9s');
            asm add esp,16
            end;
     end;
            end;

        RSTPrefectureExchange:
          begin
            asm
                push cMyZone
                push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7d');
            asm add esp,16
            end;

            asm
                mov  eax,csQTHString
//                add  eax,1
                push eax
                push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7s');
            asm add esp,16
            end;

          end;

        NameAndDomesticOrDXQTHExchange:
          begin
//            csName := PChar(string(TempRXData.Name));
            cMyName := PChar(string(MyName));
            asm
                push cMyState
                push cMyName
            end;
            wsprintf(CABRILLO_MYEX, '  %-10s %-4s');
            asm add esp,16
            end;

            asm
                push csQTHString
                push csName
            end;
            wsprintf(CABRILLO_HISEX, '  %-10s %-4s');
            asm add esp,16
            end;
          end;

        QSONumberPrecedenceCheckDomesticQTHExchange:
          begin
            CID_TWO_BYTES[0] := TempRXData.Precedence;
            csName := CID_TWO_BYTES;

            cMyName := @MyPrec[1] ;
            csCheck := {inttopchar}(TempRXData.Check);
            cMyCheck := @MyCheck[1];
            cMyState := @MySection[1];

            asm
                push cMyState
                push cMyCheck
                push cMyName
                push nrSent
            end;
            wsprintf(CABRILLO_MYEX, '%-4d %s %s %-3s ');
            asm add esp,24
            end;
            if nrReceived = -1 then
            nrReceived := 0;
            asm
                push csQTHString
                push csCheck
                push csName
                push nrReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-4d %s %02u %-3s');
            asm add esp,24
            end;
          end;

        QSONumberNameDomesticOrDXQTHExchange:
          begin
            csName := @TempRXData.Name[1];
            cMyName := @MyName[1];
            if MyState = '' then cMyState := 'DX';
            if TempRXData.QTHString = '' then csQTHString := 'DX';

            asm
                push cMyState
                push cMyName
                push nrSent
            end;
//            wsprintf(CABRILLO_MYEX, '%-10d %-7s %-4s');
            wsprintf(CABRILLO_MYEX, '%-4d %-7s %-8s');      // 4.88.3
            asm add esp,20
            end;

            asm
                push csQTHString
                push csName
                push nrReceived
            end;
      //      wsprintf(CABRILLO_HISEX, '%-4u %-10s %-4s');
              wsprintf(CABRILLO_HISEX, '%-4u %-5s %-4s');   // 4.88.3
            asm add esp,20
            end;
          end;

        RSTAgeAndPossibleSK:
          begin
//            csQTHString
            asm
                        push cMyState
                        push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-16s');
            asm add esp,16
            end;

            nrReceived := TempRXData.Age;
            asm
            push csQTHString
            push nrReceived
            push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %u %s');
            asm add esp,20
            end;

          end;

        RSTAgeExchange:
          begin

            asm
                        push cMyState
                        push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7s');
            asm add esp,16
            end;

            nrReceived := TempRXData.Age;
            asm
                        push nrReceived
                        push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7u');
            asm add esp,16
            end;
          end;

        AgeAndQSONumberExchange:      // 4.55.4
          begin
            asm
                push nrSent
                push cMyState


            xor eax,eax
           mov ax, word ptr TempRXData.RSTSent

           push eax
           end;
            wsprintf(CABRILLO_MYEX, '%-3d %-2s %03d      ');
            asm add esp,20
            end;


            hisAge := TempRXData.Age ;
            nrreceived := TempRXData.NumberReceived;          // n4af 04.42.4
            asm
            push  nrReceived
            end;
            asm
            push hisAge
            xor eax,eax
            mov ax, word ptr TempRXData.RSTSent
            push eax
            end;

            wsprintf(CABRILLO_HISEX, ' %-3d %-3d %04d');       // n4af 4.42.4
            asm add esp,20
            end;
          end;

        RSTPowerExchange:
        begin
         csPower := @TempRXData.Power[1];
         if contest = FOCMARATHON then
        begin
        cMyFOCNumber :=  @MyFOCNumber[1];
        crFOCNr := @TempRXData.Power[1];
         asm
                        push cMyFOCNumber
                        push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7s');
            asm add esp,16
            end;

            asm
                       push crFOCnr
                       push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7s');
            asm add esp,16
            end;

             end;
             if Contest <> FOCMARATHON then

              begin

            asm
                        push csPower
                        push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7s');
            asm add esp,16
            end;

            asm
                        push cMyState
                        push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7s');
            asm add esp,16
            end;
          end;
          end;
        RSTAndOrGridExchange:
          begin
            asm
                push csQTHString
                push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7s');
            asm add esp,16
            end;

            asm
                push cMyGrid
                push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7s');
            asm add esp,16
            end;
          end;

        QSONumberAndGridSquare:
          begin
            Format(CABRILLO_MYEX, '%03d %-6s ', nrSent, cMyState);
            Format(CABRILLO_HISEX, '%03u %-6s', nrReceived, csQTHString);
          end;

        QSONumberDomesticOrDXQTHExchange, QSONumberDomesticQTHExchange:
          if (Contest = UKRAINECHAMPIONSHIP) or (Contest = CUPURAL) then
          begin
            Format(CABRILLO_MYEX, '%-4s %-6d', cMyState, nrSent);
            Format(CABRILLO_HISEX, '%-4s %-6u', csQTHString, nrReceived);
          end
          else
          begin
            asm
                  push cMyState
                  push nrSent
            end;
            wsprintf(CABRILLO_MYEX, '%-4d %-6s');
            asm add esp,16
            end;

            asm
                  push csQTHString
                  push nrReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-4u %-6s');
            asm add esp,16
            end;
          end;

        QSONumberAndPossibleDomesticQTHExchange, RSTQSONumberAndDomesticQTHExchange, RSTQSONumberAndPossibleDomesticQTHExchange:
          begin

            asm
            push cMyState
            push nrSent
            push RSTSent
            end;

          if cMyState = 'TRC' then      // 4.63.3
           wsprintf(CABRILLO_MYEX, '%-3s %d%-6s')
           else
          wsprintf(CABRILLO_MYEX, '%-3s %-4d %-6s ');

            asm add esp,20
            end;

            if Contest = UKEI then           // 4.58.2
            if TempRXData.QTHString = '' then
               csQTHString := '--';

            if Contest = IOTA then
            begin
              if csQTHString[0] = #0 then csQTHString := '------';
              {
              else
              begin
                Windows.ZeroMemory(@IOTAString, SizeOf(IOTAString));
                IOTAString := Copy(TempRXData.DomesticQTH, 1, 2) + '-' + Copy(TempRXData.DomesticQTH, 3, 3);
                csQTHString := @IOTAString[1];
              end;
              }
            end;



            asm
            push csQTHString
            push nrReceived
            push RSTReceived
            end;
            if Contest = DARC10M then     // n4af 4.43.7
            wsprintf(CABRILLO_HISEX, '%-3s %4d %3s')
            else
            if csQTHString = 'TRC' then      // 4.63.3
              wsprintf(CABRILLO_HISEX, '%-3s%5d%-8s')
              else
               wsprintf(CABRILLO_HISEX, '%-3s %4d %8s');
            asm add esp,20
            end;
          end;

        RSTZoneAndPossibleDomesticQTHExchange:
          begin
            if MyState = '' then
              cMyState := 'DX';

            Format(CABRILLO_MYEX, '%-3s %02u %-4s', RSTSent, cMyZone, cMyState);

            if TempRXData.QTHString = '' then
              csQTHString := 'DX';
            Format(CABRILLO_HISEX, '%-3s %02u %-3s', RSTReceived, HisZone, csQTHString);
          end;

        RSTZoneOrDomesticQTH, RSTZoneOrSocietyExchange:
          begin
            if MyState <> '' then
            begin
              asm
              push cMyState
              push RSTSent
              end;
              wsprintf(CABRILLO_MYEX, '%-3s %-7s');
              asm add esp,16
              end;
            end
            else
            begin
              asm
              push cMyZone
              push RSTSent
              end;
              wsprintf(CABRILLO_MYEX, '%-3s %-7d');
              asm add esp,16
              end;
            end;

            if TempRXData.QTHString <> '' then
            begin
              asm
              push csQTHString
              push RSTReceived
              end;
              wsprintf(CABRILLO_HISEX, '%-3s %-7s');
              asm add esp,16
              end;
            end
            else
            begin
              asm
              push HisZone
              push RSTReceived
              end;
              wsprintf(CABRILLO_HISEX, '%-3s %-7u');
              asm add esp,16
              end;
            end;

          end;

        QSONumberAndCoordinatesSum: {RFASCHAMPIONSHIP}
          begin
            asm
            push nrSent
            push cMyState
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %03d    ');
            asm add esp,16
            end;

            asm
            push nrReceived
            push csQTHString
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %03u');
            asm add esp,16
            end;
          end;

        ClassDomesticOrDXQTHExchange:
          begin
            Format(CABRILLO_MYEX, '%-3s %-7s ', @MyFDClass[1], @MySection[1]);
            if Contest in [ARRLFIELDDAY, WINTERFIELDDAY] then
               begin
               csQTHString := @TempRXData.QTHString[1];   // Issue 407 ny4i
               end;
            Format(CABRILLO_HISEX, '%-3s %-7s', @TempRXData.ceClass[1], csQTHString);
          end;

        QSONumberAndGeoCoordinates:
          begin
            asm
            push cMyState
            push nrSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3d %-7s ');
            asm add esp,16
            end;

            asm
            push csQTHString
            push nrReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3u %-7s');
            asm add esp,16
            end;
          end;

        RSTQSONumberExchange:
          begin

       {     asm
            push nrSent
            push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7d');
            asm add esp,16
            end;    }
             Format(CABRILLO_MYEX, '%-3s %04d ', RSTSent, nrSent);      // issue 177

           { asm
            push nrReceived
            push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7u');
            asm add esp,16
            end;
          end;   }
          Format(Cabrillo_HISEX, '%-3s %04u',RSTReceived, nrReceived);   // issue 177
          end;
        RSTAndContinentExchange:
          begin
            csQTHString := @TempRXData.QTHString[1];
            asm
            push csQTHString
            push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7s');
            asm add esp,16
            end;

            asm
            push cMyState
            push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7s');
            asm add esp,16
            end;
          end;

        RSTDomesticQTHExchange:
          begin
            if Contest in [ARRLVHFQSO, ARRLVHFSS, CQVHF {, MMAA}] then
            begin
              asm
                    push csQTHString
                    push RSTReceived
              end;
              wsprintf(CABRILLO_HISEX, '%-3s %-7s');
              asm add esp,16
              end;

              asm
                    push cMyGrid
                    push RSTSent
              end;
              wsprintf(CABRILLO_MYEX, '%-3s %-7s');
              asm add esp,16
              end;
            end
            else
            begin
              if MyState = '' then cMyState := 'DX';
//              if MyCounty <> '' then cMyState := @MyCounty[1];
              if Contest in [SPDX, PACC] then cMyState := inttopchar(nrSent);
              if TempRXData.QTHString = '' then csQTHString := 'DX';
              asm
                    push csQTHString
                    push RSTReceived
              end;
              wsprintf(CABRILLO_HISEX, '%-3s %-7s');
              asm add esp,16
              end;

              asm
                    push cMyState
                    push RSTSent
              end;
              wsprintf(CABRILLO_MYEX, '%-3s %-7s');
              asm add esp,16
              end;
            end;
          end;

        RSTDomesticOrDXQTHExchange:
          begin
                //-                if MyState = '' then cMyState := 'DX';
            if TempRXData.QTHString = '' then
              if TempRXData.DXQTH = '' then csQTHString := 'DX' else csQTHString := @TempRXData.DXQTH[1];

            asm
                push csQTHString
                push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7s');
            asm add esp,16
            end;

            asm
                push cMyState
                push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7s');
            asm add esp,16
            end;
          end;

        QSONumberAndZone:
          begin
//            if (Contest = RFCHAMPIONSHIPSSB) or (Contest = RFCHAMPIONSHIPCW) then
            begin
              asm
                push nrReceived
                push HisZone
              end;
//              if Contest = UA4N then
//                wsprintf(CABRILLO_HISEX, '%02u%03u')
//              else
              wsprintf(CABRILLO_HISEX, '  %u   %03u');
              asm add esp,16
              end;

              asm
                push nrSent
                push cMyState
              end;
              wsprintf(CABRILLO_MYEX, '  %s    %03d ');
              asm add esp,16
              end;
            end;
          end;

        RSTZoneExchange:
          begin
            if Contest in [JIDXSSB, JIDXCW] then cMyZone := StrToInt(MyState);
            asm
                push HisZone
                push RSTReceived
            end;
            wsprintf(CABRILLO_HISEX, '%-3s %-7.2d');       // 4.51.1 issue185
            asm add esp,16
            end;

            asm
                push cMyZone
                push RSTSent
            end;
            wsprintf(CABRILLO_MYEX, '%-3s %-7.2d');   // 4.51.1   issue#185
            asm add esp,16
            end;
          end;

         QSONumberAndPreviousQSONumber:
          begin
          hisnr := (nrreceived div 1000);    // 4.53.2
           rxnr := (nrreceived mod 1000);    // 4.53.2
            asm
             push nrSent            // 4.53.2
             push pnr     // 4.53.2
            end;
            wsprintf(CABRILLO_MYEX, '%-.3u%-7.3d');    // 4.72.9
            asm add esp,16
            end;



            asm
               push RXNR     // 4.53.4           // 4.72.9
              push HisNR      //4.53.4

            end;
          //  pnr := temprxdata.numberreceived div  1000;      // 4.53.2
              pnr := RXNR;
             wsprintf(CABRILLO_HISEX, '%-.3d%-.3d');    // 4.53.4        // 4.72.9
             asm add esp,16
             end;
          end;

        RSTAndQSONumberOrFrenchDepartmentExchange, RSTAndQSONumberOrDomesticQTHExchange, RSTDomesticQTHOrQSONumberExchange:
          begin
           if (MyState <> '') and (Contest <> PCC) then      // 4.83.2
            begin
              asm
              push cMyState
              push RSTSent
              end;
              wsprintf(CABRILLO_MYEX, '%-3s %-7s');
              asm add esp,16
              end;
            end
            else
             if StringIsAllNumbers(MyState) then
              begin
               asm
               push nrSent
               push RSTSent
               end;
              wsprintf(CABRILLO_MYEX, '%-4s %03u/M   ');  // n4af 4.43.12
              asm add esp,16
              end;
             end
              else
               begin
                asm
                push nrSent
                push RSTSent
                end;
               wsprintf(CABRILLO_MYEX, '%-4s %03u   ');  // n4af 4.43.12
               asm add esp,16
               end;
              end;


            if TempRXData.QTHString {.DomMultQTH} <> '' then
           begin
             asm
              push csQTHString
              push RSTReceived
             end;
              wsprintf(CABRILLO_HISEX, '%-3s %-3s'); // 4.84.2
              asm add esp,16
              end;
            end
            else
            begin
              asm
              push nrReceived
              push RSTReceived
              end;
              wsprintf(CABRILLO_HISEX, '%-3s %03u');
              asm add esp,16
              end;
            end;
          end;
      end;
//----------------------------

      StrUpper(CABRILLO_HISEX);

  if CategoryOperator = coMULTIOP then
      if temprxdata.cecomputerid = ComputerID then        // 4.73.6

      T4 := '1'
       else
        T4 := '0';
 if CategoryOperator <> coMULTIOP then
 T4 := '';
      T1 := CABRILLO_FIRST_PART;
      T2 := CABRILLO_MYEX;
      T3 := CABRILLO_HISEX;

      asm
      push t4
      push t3
      push HisCallsign
      push t2
      push t1
      end;

         if Contest = ARKTIKA_SPRING then
      nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '%s%-12s%-10s%-10s'#13#10)
     else
      nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, '%s%s%-11s%-10s %-5s'#13#10);
      asm add esp,24
      end;

//      if Radio2ID <> #0 then if TempRXData.ceComputerID = Radio2ID then CABRILLO_BUFFER[80] := '1';
      sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);

      previousqsonr := nrReceived mod 1000;
    end;


    Windows.ZeroMemory(@PreviousQTHString, SizeOf(PreviousQTHString));
    PreviousQTHString := TempRXData.QTHString;

    if TempRXData.ceRecordKind in [rkQTCR, rkQTCS] then
    begin

      cKids := @TempRXData.Kids[1];
      cRandomCharsReceived := @TempRXData.RandomCharsReceived[1];
      asm
            push nrReceived
            push cKids
            push nrSent
      end;

      if TempRXData.ceRecordKind = rkQTCR then
        asm
        push HisCallsign
        push cRandomCharsReceived
        lea  eax,MyCall[1]
        push eax
        end
      else
        asm
        lea  eax,MyCall[1]
        push eax
        push cRandomCharsReceived
        push HisCallsign
        end;

      asm
            movzx eax,TempRXData.tSysTime.qtMinute
            push eax

            movzx eax,TempRXData.tSysTime.qtHour
            push eax

            movzx eax,TempRXData.tSysTime.qtDay
            push eax

            movzx eax,TempRXData.tSysTime.qtMonth
            push eax

            movzx eax,TempRXData.tSysTime.qtYear
            add eax,2000
            push eax

            push ModeString
            push Freq
      end;
      nNumberOfBytesToWrite := wsprintf(CABRILLO_BUFFER, 'QTC: %5s %s %d-%02d-%02d %02d%02d %-14s%-11s%-14s%04u %-14s%u'#13#10);
      asm add esp,60
      end;
      sWriteFile(tReportFileWrite, CABRILLO_BUFFER, nNumberOfBytesToWrite);
    end;
    goto 1;
  end;
  sWriteFile(tReportFileWrite, 'END-OF-LOG: ', 12);

  CloseLogFile;
  Result := True;
   except
      on E: Exception do
         DebugMsg(E.ClassName + ' error raised with message ' + E.Message);
   end;
   finally
      FreeANdNil(slOperators);
   end;
end;

procedure SetTransmittersIdentifiers;
begin
  Radio1IDs := QuickEditResponse('transmiter 1 computers IDs', 10);
{
  TempString := QuickEditResponse('transmiter 1 ID', 1);
  if TempString <> '' then Radio1ID := TempString[1];
  if not (Radio1ID in ['A'..'Z']) then Radio1ID := #0;
}
//  TempString := QuickEditResponse('radio 2 ID', 1);
//  if TempString <> '' then Radio2ID := TempString[1];
end;

procedure tFirstCallInEachCountry;
begin
  New(CountryMultTotals);
  if GenerateCountryMultiplierTotals then PrintFirstCountryMultiplierCallsigns;
  Dispose(CountryMultTotals);
end;

procedure PrintFirstCountryMultiplierCallsigns;

var
  Lines, Count, CountryIndex            : integer;
  TempString                            : ShortString;
  Prefix                                : string;
  FileWrite                             : Text;
  Band                                  : BandType;
  p                                     : PChar;
begin

  MakeReportFileName('firstcallineachcountry.txt');
  OpenFileForWrite(FileWrite, ReportsFilename);

  Lines := 0;

  CountryIndex := 0;

  while CountryIndex < CTY.ctyNumberCountries do
  begin

    if (CountryMultTotals^[Band160, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band80, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band40, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band20, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band15, CountryIndex].TotalQSOs > 0) or
      (CountryMultTotals^[Band10, CountryIndex].TotalQSOs > 0) then

    begin

      if ((Lines >= 55) or (Lines = 0)) then
      begin
        Write(FileWrite, ' ');

        WriteLnVarCenter(FileWrite, 'COUNTRIES WORKED - WITH CALL OF FIRST STATION WORKED');
        WriteLn(FileWrite);
        WriteLnVarCenter(FileWrite, ContestTitle);
        WriteLn(FileWrite);
        WriteLn(FileWrite, 'Prefix   160         80          40          20          15          10');
        WriteLn(FileWrite, '------ --------    --------    --------    --------    --------    --------');
        Lines := 5;
      end;

      for Band := Band10 downto Band160 do
      begin
        p := @CountryMultTotals^[Band, CountryIndex].FirstCall[1];
        asm
               push p
        end;
      end;
//      Prefix := ctyGetCountryID(CountryIndex);
      Prefix := CTY.ctyTable[CountryIndex].ID;
      asm
               push Prefix
      end;
      Count := wsprintf(@TempString[1], '%-6s %-11s %-11s %-11s %-11s %-11s %-11s');
      asm add esp,36
      end;
      SetLength(TempString, Count);

      WriteLn(FileWrite, TempString);
      inc(Lines);
    end;

    inc(CountryIndex);
  end;

  Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;

end;

procedure tFirstCallInEachZone;
begin
  New(CountryMultTotals);
  MakeReportFileName('FirstCallInEachZone.txt');
  if GenerateZoneMultiplierTotals then
    PrintFirstZoneMultiplierCallsigns;

  Dispose(CountryMultTotals);

end;

function GenerateZoneMultiplierTotals: boolean;

{ This procedure will go through the log file and determine how many QSOs
  were made with each zone - and record the callsign of the first QSO
  for each zone.  The results are saved in the structure
  CountryMultTotals. }

label
  1;
begin
  GenerateZoneMultiplierTotals := False;
  Windows.ZeroMemory(CountryMultTotals, SizeOf(CountryMultiplierArray));
  if not OpenLogFile then Exit;
  //   TotalLogQSOs := 0;
  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if GoodLookingQSO then
    begin
          //               inc(TotalLogQSOs);
      if (TempRXData.Zone > 0) and (TempRXData.Zone <= 100) then
      begin
        if TempRXData.ZoneMult then
          if CountryMultTotals^[TempRXData.Band, TempRXData.Zone].TotalQSOs = 0 then
            CountryMultTotals^[TempRXData.Band, TempRXData.Zone].FirstCall := TempRXData.Callsign;

              //                     if TempRXData.QTH.Country >= 0 then
        inc(CountryMultTotals^[TempRXData.Band, TempRXData.Zone].TotalQSOs);
      end;
    end;
    goto 1;
  end;
  CloseLogFile;
  GenerateZoneMultiplierTotals := True;
end;

procedure PrintFirstZoneMultiplierCallsigns;

var
  Lines, Count, MaxNumberOfZones, ZoneIndex: integer;
  TempString                            : Str80;
  FileWrite                             : Text;
  Band                                  : BandType;
  p                                     : PChar;
begin

  OpenFileForWrite(FileWrite, ReportsFilename);

  Lines := 0;
  {
     WriteLnVarCenter(FileWrite, 'ZONES WORKED - WITH CALL OF FIRST STATION WORKED');
     WriteLn(FileWrite);
     WriteLnVarCenter(FileWrite, ContestTitle);
     WriteLn(FileWrite);
     WriteLn(FileWrite, 'Zone   160        80          40          20          15          10');
     WriteLn(FileWrite, '---- --------   --------    --------    --------    --------    --------');

  Lines := 5;
  }
  MaxNumberOfZones := 40;

  for Band := Band160 to Band10 do
    for ZoneIndex := 41 to 100 do
      if CountryMultTotals^[Band, ZoneIndex].TotalQSOs > 0 then
        MaxNumberOfZones := ZoneIndex;

  if (MaxNumberOfZones > 40) then
    if MaxNumberOfZones <= 75 then
      MaxNumberOfZones := 75
    else
      MaxNumberOfZones := 100;

  for ZoneIndex := 1 to MaxNumberOfZones do
  begin
    if ((Lines >= 55) or (Lines = 0)) then
    begin
      Write(FileWrite, ' ');

      WriteLnVarCenter(FileWrite, 'ZONES WORKED - WITH CALL OF FIRST STATION WORKED');
      WriteLn(FileWrite);
      WriteLnVarCenter(FileWrite, ContestTitle);
      WriteLn(FileWrite);
      WriteLn(FileWrite, 'Zone   160         80          40          20          15          10');
      WriteLn(FileWrite, '---- --------    --------    --------    --------    --------    --------');
      Lines := 5;
    end;
    SetLength(TempString, 80);

    for Band := Band10 downto Band160 do
    begin
      p := @CountryMultTotals^[Band, ZoneIndex].FirstCall[1];
      asm
               push p
      end;
    end;
    asm
            push ZoneIndex
    end;

    Count := wsprintf(@TempString[1],
      '%-4u %-11s %-11s %-11s %-11s %-11s %-11s');
    asm add esp,36
    end;
    SetLength(TempString, Count);
      {
               Str(ZoneIndex: 3, TempString);

               TempString := TempString + '  ';

               if CountryMultTotals^[Band160, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band160, ZoneIndex].FirstCall;

               while length(TempString) < 16 do TempString := TempString + ' ';

               if CountryMultTotals^[Band80, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band80, ZoneIndex].FirstCall;

               while length(TempString) < 28 do TempString := TempString + ' ';

               if CountryMultTotals^[Band40, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band40, ZoneIndex].FirstCall;

               while length(TempString) < 40 do TempString := TempString + ' ';

               if CountryMultTotals^[Band20, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band20, ZoneIndex].FirstCall;

               while length(TempString) < 52 do TempString := TempString + ' ';

               if CountryMultTotals^[Band15, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band15, ZoneIndex].FirstCall;

               while length(TempString) < 64 do TempString := TempString + ' ';

               if CountryMultTotals^[Band10, ZoneIndex].TotalQSOs > 0 then
                  TempString := TempString + CountryMultTotals^[Band10, ZoneIndex].FirstCall;
      }
    WriteLn(FileWrite, TempString);
    inc(Lines);
  end;

  //   Write(FileWrite, ' ');
  Close(FileWrite);
  FilePreview;
end;

procedure ZoneReport;
label
  1;
var
  FileWrite                             : Text;
  Location                              : QTHRecord;
  QSONumber, NumberBadZones             : integer;
begin
  {
    WriteLn('This procedure will list any contacts where the received zone differs from');
    WriteLn('the default zone for the indicated callsign.  You should be aware that some');
    WriteLn('of the more active stations have "special" default zones.  For example, the');
    WriteLn('program knows that N4AR is in zone 4, not zone 5.');
    WriteLn;
  }

  NumberBadZones := 0;
  MakeReportFileName('PossibleBadZone.txt');
  if not OpenLogFile then Exit;

  if not OpenFileForWrite(FileWrite, ReportsFilename) then
  begin
    CloseLogFile;
    Exit;
  end;

  QSONumber := 0;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin

    if GoodLookingQSO then

    begin
      inc(QSONumber);
      ctyLocateCall(TempRXData.Callsign, Location);
      if TempRXData.Zone <> Location.Zone then
      begin
        WriteLn(FileWrite, TempRXData.Callsign: 10);
        inc(NumberBadZones);
      end;

    end;

    goto 1;
  end;
  CloseLogFile;
  WriteLn(FileWrite, 'There were ', NumberBadZones, ' questionable zones found.');
  WriteLn(FileWrite);
  Close(FileWrite);
  FilePreview;
end;
{
function CorrectContestExchange: boolean;
begin

  RESULT := False;

  if (
    (TempRXData.ceQSO_Skiped = False) and
    (TempRXData.Band <> NoBand) and
    (TempRXData.Mode <> NoMode) and
    (TempRXData.ceQSO_Dupe = False) and
    (TempRXData.ceQSO_Deleted = False)
    ) then RESULT := True;
end;
}

procedure BandChangeReport;
label
  1;
var
  LastBand                              : BandType;
  LastMode                              : ModeType;
  FirstQSO                              : boolean;
  QSONumber, NumberBandChanges, NumberTwoXmtrQSOs, LastBandChangeQSO: integer;
  FileWrite                             : HWND;
  P1, P2, p3, p4, sr                    : PChar;
  lpNumberOfBytesWritten                : Cardinal;
begin
  if not OpenLogFile then Exit;
  MakeReportFileName('BandChange.txt');
  if not tOpenFileForWrite(FileWrite, @ReportsFilename[1]) then
  begin
    CloseLogFile;
    Exit;
  end;
  QSONumber := 0;
  NumberBandChanges := 0;
  LastBandChangeQSO := -100;
  NumberTwoXmtrQSOs := 0;

  //  Write(QSONumber);
  FirstQSO := True;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin

    if GoodLookingQSO then

    begin
      if FirstQSO then
      begin
        LastBand := TempRXData.Band;
        LastMode := TempRXData.Mode;
        FirstQSO := False;
      end;
      inc(QSONumber);

      if (LastBand <> TempRXData.Band) or (LastMode <> TempRXData.Mode) then
      begin
        inc(NumberBandChanges);
              {
                      Write(FileWrite, NumberBandChanges: 4, '. ',
                        TempRXData.NumberSent: 5,
                        '  Band change from ',
                        BandString[LastBand], ModeString[LastMode], ' to ',
                        BandString[TempRXData.Band], ModeString[TempRXData.Mode], ' at ',
                        TempRXData.tSysTime.wHour: 2, ':', TempRXData.tSysTime.wMinute: 02,
                        '.');
              }
        sr := '';
        if LastBandChangeQSO + 1 = QSONumber then
        begin
          sr := '  *';
          inc(NumberTwoXmtrQSOs);
        end;

        P1 := BandStringsArray[LastBand];
        P2 := ModeStringArray[LastMode];
        p3 := BandStringsArray[TempRXData.Band];
        p4 := ModeStringArray[TempRXData.Mode];
        asm
        push sr
        movzx eax, TempRXData.tSysTime.qtMinute
        push eax
        movzx eax, TempRXData.tSysTime.qtHour
        push eax
        push p4
        push p3
        push p2
        push p1
        push NumberBandChanges
        end;
        lpNumberOfBytesWritten := wsprintf(CABRILLO_BUFFER, '%4d.  Band change from %s%s to %s%s at %02d:%02d.%s'#13#10);
        asm add esp,36
        end;
        sWriteFile(FileWrite, CABRILLO_BUFFER, lpNumberOfBytesWritten);

              //        WriteLn(FileWrite);
        LastBandChangeQSO := QSONumber;
      end;
      LastBand := TempRXData.Band;
      LastMode := TempRXData.Mode;
    end;
    goto 1;
  end;
  if NumberTwoXmtrQSOs > 0 then
  begin

    asm
    push NumberTwoXmtrQSOs
    end;
    lpNumberOfBytesWritten := wsprintf(CABRILLO_BUFFER, #13#10'There were %d second radio QSOs made.');
    asm add esp,12
    end;
    sWriteFile(FileWrite, CABRILLO_BUFFER, lpNumberOfBytesWritten);
  end;

  CloseLogFile;
  CloseHandle(FileWrite);
  FilePreview;
end;

function GoodLookingQSO: boolean;
begin
  Result := False;

  if TempRXData.ceRecordKind <> rkQSO then Exit;
  if TempRXData.ceQSO_Skiped = True then Exit;
  if TempRXData.Band = NoBand then Exit;
  if TempRXData.Mode = NoMode then Exit;
  if TempRXData.ceQSO_Deleted = True then Exit;

  Result := True;
end;

procedure MakeReportFileName(ShortFileName: PChar);
var
  p                                     : PChar;
begin
  p := @ReportsFilename[1];
  Windows.ZeroMemory(@ReportsFilename, SizeOf(ReportsFilename));
  lstrcpy(p, TR4W_LOG_PATH_NAME);
  lstrcat(p, ShortFileName);
  ReportsFilename[0] := CHR(Windows.lstrlen(p));
  PreviewFileNameAddress := p;
end;

procedure MakeNotesList;
label
  1;
var
  Note                                  : PChar;
  Minutes, Hour                         : integer;
  nNumberOfBytesToWrite                 : integer;
begin
  MakeReportFileName('Notes.txt');
  if not OpenLogFile then Exit;

  if not tOpenFileForWrite(tReportFileWrite, @ReportsFilename[1]) then
  begin
    CloseLogFile;
    Exit;
  end;

  ReadVersionBlock;
  1:
  if ReadLogFile then
  begin
    if TempRXData.ceRecordKind = rkNote then
    begin
      Minutes := TempRXData.tSysTime.qtMinute;
      Hour := TempRXData.tSysTime.qtHour;
      Note := @TempRXData.Prefix;
      asm
      push Note
      push Minutes
      push Hour
      end;
      tGetDateFormat(TempRXData.tSysTime);
      asm
      push eax
      end;
      nNumberOfBytesToWrite := wsprintf(wsprintfBuffer, '%s %02u:%02u: %s'#13#10);
      asm add esp,24 end;
      sWriteFile(tReportFileWrite, wsprintfBuffer, nNumberOfBytesToWrite);
    end;

    goto 1;
  end;
  CloseLogFile;
  CloseHandle(tReportFileWrite);
  FilePreview;
end;

(*----------------------------------------------------------------------------*)

function GetMyExchangeForExport: string;
var
  //HisCallsign                           : PChar;
  cMyZone                               : integer;
  cMyState                              : string;
  cMyName                               : PChar;
  //csName                                : PChar;
  cMyFOCNumber                          : PChar;
  cMyCheck                              : PChar;
  //csCheck                               : integer {PChar};
  crFOCNr                               : PChar;
  cMyGrid                               : PChar;
  csPower                               : PChar;
  //hisAge                                : Integer;
  csQTHString                           : PChar;
  HisZone                               : integer;
  //str1                                  : widestring;
  //nrReceived                            : integer;
  nrSent                                : integer;
  //tempcategoryoperator                  : tcategoryoperator;

  //T1                                    : PChar;
  //T2                                    : PChar;
  //T3                                    : PChar;
  //T4                                    : PChar;      // 4.73.6
  cRandomCharsReceived                  : PChar;
  //cKids                                 : PChar;
  TempGrid                              : Str20;
  previousqsonr                         : integer;
  TransmitterIDPos                      : integer;
  contacts                              : integer;
  PreviousQTHString                     : Str10;
  pnr                                   : integer;
  hisnr                                 : integer;
  rxnr                                  : integer;


begin
   Result := 'Error generating my exchange';
   try
   TempGrid := MyGrid;
   TempGrid[5] := #0;
   cMyGrid := @TempGrid[1];

   cMyName := @MyName[1];

   cMyZone := StrToInt(MyZone);
   cMyState := MyState;

   previousqsonr := 0;
   nrSent := TempRXData.NumberSent;

   if GoodLookingQSO then
      begin

      {Make Exchanges Strings}
      case ActiveExchange of
         GridExchange:
            begin
            Result := cMyGrid;
            //Format(CABRILLO_MYEX, '%-11s', cMyGrid);
            end;

         RSTNameAndQTHExchange:
            begin
            Result := SysUtils.Format('%-3d %-5s %-7s', [TempRXData.RSTSent, cMyName, cMyState]);
            end;

         QSONumberAndNameExchange:
            begin
            Result := SysUtils.Format('%-3d %-7s', [nrSent, cMyName]);
            end;

         RSTAndPostalCodeExchange:
            begin
            if contacts = 1 then
               begin
               Result := SysUtils.Format('%-3d %-10s', [TempRXData.RSTSent, MyPostalCode]);
               end
            else
               begin
               Result := SysUtils.Format('%-3d %-10s', [TempRXData.RSTSent, PreviousQTHString]);
               end;
            end;

         RSTQSONumberAndGridSquareExchange:
            begin
            Result := SysUtils.Format('%-3d %-4d %-7s', [TempRXData.RSTSent, nrSent, cMyGrid]);
            end;

         RSTQSONumberOrDomesticQTHExchange:      //n4af 4.40.6
            begin
            if cMystate[1] <> '' then
               begin
               Result := SysUtils.Format('%-3d  %-5s', [TempRXData.RSTSent, cMyState]);
               end
            else if cMystate[1] = '' then
               begin
               Result := SysUtils.Format('%-3d  %-6d', [TempRXData.RSTSent, nrSent]);
               end;
            end;

         RSTPrefectureExchange:
            Result := SysUtils.Format('%-3d %-7d', [TempRXData.RSTSent, cMyZone]);

         NameAndDomesticOrDXQTHExchange:
            Result := SysUtils.Format('  %-10s %-4s', [cMyName, cMyState]);


         QSONumberPrecedenceCheckDomesticQTHExchange:
            begin
            CID_TWO_BYTES[0] := TempRXData.Precedence;
            //csName := CID_TWO_BYTES;

            cMyName := @MyPrec[1] ;
            //csCheck := {inttopchar}(TempRXData.Check);
            cMyCheck := @MyCheck[1];
            //cMyState := @MySection[1];

            Result := SysUtils.Format('%-4d %s %s %-3s ', [nrSent, cMyName, cMyCheck, MySection]);
            end;

         QSONumberNameDomesticOrDXQTHExchange:
            begin
            //csName := @TempRXData.Name[1];
            cMyName := @MyName[1];
            if MyState = '' then cMyState := 'DX';
            if TempRXData.QTHString = '' then csQTHString := 'DX';
            Result := SysUtils.Format('%-4d %-7s %-8s', [nrSent, cMyNAme, cMyState]);
            end;

         RSTAgeAndPossibleSK:
            Result := SysUtils.Format('%-3d %-16s', [TempRXData.RSTSent, cMyState]);

         RSTAgeExchange:
            Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);

         AgeAndQSONumberExchange:      // 4.55.4
            Result := SysUtils.Format('%-3d %-2s %03d      ', [cMyState, nrSent]);

         RSTPowerExchange:
            begin
            csPower := @TempRXData.Power[1];
            if contest = FOCMARATHON then
               begin
               cMyFOCNumber :=  @MyFOCNumber[1];
               crFOCNr := @TempRXData.Power[1];
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyFOCNumber]);
               end
            else if Contest <> FOCMARATHON then
               begin
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);
               end;
            end;
         RSTAndOrGridExchange:
            begin
            Result := SysUtils.Format('%-3d %-7s',[TempRXData.RSTSent, cMyGrid]);
            end;

         QSONumberAndGridSquare:
            Result := SysUtils.Format('%-3s %-7s',[nrSent, cMyState]);

         QSONumberDomesticOrDXQTHExchange, QSONumberDomesticQTHExchange:
            Result := SysUtils.Format('%-4s %-6d', [cMyState, nrSent]);

         QSONumberAndPossibleDomesticQTHExchange, RSTQSONumberAndDomesticQTHExchange, RSTQSONumberAndPossibleDomesticQTHExchange:
            if cMyState = 'TRC' then
               begin
               Result := SysUtils.Format('%-3d %d%-6s',[TempRXData.RSTSent, nrSent, cMyState]);
               end
            else
               begin
               Result := SysUtils.Format('%-3d %-4d %-6s ',[TempRXData.RSTSent, nrSent, cMyState]);
               end;

         RSTZoneAndPossibleDomesticQTHExchange:
            begin
            if MyState = '' then
               begin
               cMyState := 'DX';
               end;
            Result := SysUtils.Format('%-3d %02u %-4s', [TempRXData.RSTSent, MyZone, cMyState]);
            end;
         RSTZoneOrDomesticQTH, RSTZoneOrSocietyExchange:
            if MyState <> '' then
               begin
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);
               end
            else
               begin
               Result := SysUtils.Format('%-3d %-7d', [TempRXData.RSTSent, cMyZone]);
               end;

         QSONumberAndCoordinatesSum: {RFASCHAMPIONSHIP}
            Result := SysUtils.Format('%-3s %03d    ', [cMyState, nrSent]);

         ClassDomesticOrDXQTHExchange:
            Result := SysUtils.Format('%-3s %-7s ', [ MyFDClass, MySection]);

         RSTQSONumberExchange:
            Result := SysUtils.Format('%-3d %04d ', [TempRXData.RSTSent, nrSent]);      // issue 177


         RSTAndContinentExchange:
            Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);

         RSTDomesticQTHExchange:
            if Contest in [ARRLVHFQSO, ARRLVHFSS, CQVHF {, MMAA}] then
               begin
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyGrid]);
               end
            else
               begin
               if MyState = '' then
                  begin
                  cMyState := 'DX';
                  end;
               if Contest in [SPDX, PACC] then
                  begin
                  MyState := inttopchar(nrSent);
                  end;
               Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);
               end;

         RSTDomesticOrDXQTHExchange:
            Result := SysUtils.Format('%-3d %-7s', [TempRXData.RSTSent, cMyState]);

         QSONumberAndZone:
            Result := SysUtils.Format('  %s    %03d ', [cMyState, nrSent]);

         RSTZoneExchange:
            Result := SysUtils.Format('%-3d %-7.2d', [TempRXData.RSTSent, cMyZone]);

         QSONumberAndPreviousQSONumber:
            begin
            //hisnr := (nrreceived div 1000);    // 4.53.2
            //rxnr := (nrreceived mod 1000);    // 4.53.2
            Result := SysUtils.Format('%-.3u%-7.3d', [pnr, nrSent]);
            end;

         RSTAndQSONumberOrFrenchDepartmentExchange,
         RSTAndQSONumberOrDomesticQTHExchange,
         RSTDomesticQTHOrQSONumberExchange:
            begin
            if (MyState <> '') and (Contest <> PCC) then      // 4.83.2
               begin
               Result := SysUtils.Format('%-3d %-7s',[TempRXData.RSTSent, cMyState]);
               end
            else if StringIsAllNumbers(MyState) then
               begin
               Result := SysUtils.Format('%-4d %03u/M   ', [TempRXData.RSTSent, nrSent]);
               end
            else
               begin
               Result := SysUtils.Format('%-4d %03u   ', [TempRXData.RSTSent, nrSent]);
               end;
            end;
         end; // of case ActiveExchange
      end;
   except
   end;
   end;
(*----------------------------------------------------------------------------*)
function GetOperatorsFromLog: string;
var
  slOperators                           : TStringList;
begin
  Result := '';
  if not OpenLogFile then Exit;

  ReadVersionBlock;

   try
      try
         slOperators := TStringList.Create;
         slOperators.Duplicates := dupIgnore;
	      slOperators.Sorted := true;
         while ReadLogFile do
            begin
            slOperators.Add(TempRXData.ceOperator);
            end;
         CloseLogFile;
         Result := slOperators.DelimitedText;
      except
      on E: Exception do
         DebugMsg(E.ClassName + ' error raised with message ' + E.Message);
      end;
   finally
      FreeAndNil(slOperators);
   end;
end;
(*----------------------------------------------------------------------------*)
end.

