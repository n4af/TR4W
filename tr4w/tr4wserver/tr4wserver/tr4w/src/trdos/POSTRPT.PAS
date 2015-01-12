unit PostRpt;

{$O+}
{$F+}

interface

uses Tree,
   Windows,
   //SlowTree,
   PostSubs,
   Country9,
   LogDupe,
   LogWind,
   //Crt,
   ZoneCont,
   PostMult,
   Dialogs,
   SysUtils,
   PostUnit;
function ReportProcedureMenu: boolean;
procedure BandChangeReport;
procedure ContinentReport;
procedure DupeSheet;
procedure ShowDupeReport;
procedure ListMultipliersWorked;
procedure RateReport;
procedure QSODistribution;
procedure SummarySheet;
procedure ViewNotes;
procedure WPXPrefixReport;
procedure ZoneReport;

const
   CallBufferSize                  = 1000;

type
   ContestType = (UnknownContest,
      AllAsian,
      AllJA,
      APSprint,
      ARCI,
      ARI,
      ARRL10,
      ARRL160,
      ARRLDX,
      ARRLRTTY,
      ARRLVHFQSO,
      ARRLVHFSS,
      Baltic,
      CalQSO,
      County,
      CQ160,
      CQM,
      CQVHF,
      CQWPX,
      CQWW,
      CQWWRTTY,
      Croatian,
      EuropeanVHF,
      EuropeanSprint,
      EuropeanHFC,
      FieldDay,
      FQP,
      General,
      GridLoc,
      HADX,
      Helvetia,
      IARU,
      IntSprint,
      IOTA,
      JADX,
      JALP, {KK1L: 6.72}
      KCJ,
      KidsDay,
      KVP,
      MIQP,
      MQP,
      NAQSO,
      NEQSO,
      NRAUBaltic,
      NZFieldDay,
      OceaniaVKZL,
      OhioQP,
      OKDX,
      PACC,
      QCWA,
      RAC,
      Region1FD,
      Ropoco,
      SAC,
      sa,
      SAWW,
      Russian,
      SalmonRun, {KK1L: 6.71}
      SPDX,
      Sprint,
      ss,
      StewPerry,
      TenTen,
      TexQSO,
      Toec,
      UBA,
      Ukrainian,
      WAE,
      WAG,
      WQP,
      WWL,
      WRTC,
      WRTC2002, {KK1L: 6.68}
      XMAS,
      YODX,
      CUPRF);

   DupeSheetEntryRecordPointer = ^DupeSheetEntryRecord;

   DupeSheetEntryRecord = record
      Call: CallString;
      Next: DupeSheetEntryRecordPointer;
   end;

   DupeSheetStartArrayType = array[-1..MaxCountries - 1] of DupeSheetEntryRecordPointer;

   CallBufferPointer = ^CallBufferType;

   CallBufferType = array[0..CallBufferSize - 1] of CallString;

var
   CallBuffer                      : CallBufferPointer;
   DupeSheetStartArray             : DupeSheetStartArrayType;
   NumberCallsInCallBuffer         : integer;
   SummaryFileName                 : string; {KK1L: 6.72}

function GetCallAndContestFromLOGCFGFile(var MyCall: {Call} string;
   var Contest: string {40}): boolean;

function DetermineContest(Name: Str80): ContestType;

procedure CalculateAppropriateTotalsForThisContest(Contest: ContestType;
   MyQTH: QTHRecord);

procedure DetermineModesAndBandsUsed;
function DetermineNumberOfQTCs: integer;

implementation

function Number(Call: CallString): Char;

var
   CharPointer                     : integer;

begin
   for CharPointer := 2 to 4 do
      if Call[CharPointer] <= '9' then
         begin
            Number := Call[CharPointer];
            Exit;
         end;

   Number := '/';
end;

function Suffix(Call: CallString): CallString;

var
   CharPointer                     : integer;

begin
   for CharPointer := 2 to 4 do
      if Call[CharPointer] <= '9' then
         begin
            Delete(Call, 1, CharPointer);
            Suffix := Call;
            Exit;
         end;

   Suffix := Call;
end;

procedure ProcessMultiplierTotals(Band: Tree.BandType;
   Mode: Tree.ModeType;
   DomesticMults: boolean;
   DXMults: boolean;
   PrefixMults: boolean;
   ZoneMults: boolean;
   FileString: Str80);

var
   NumDifMults, NumberMults, Mult  : integer;
   MultArray                       : array[1..2] of Str20;
   MultString                      : Str80;
   MultIdentified                  : boolean;

begin
   NumDifMults := 0;

   if DomesticMults then inc(NumDifMults);
   if DXMults then inc(NumDifMults);
   if PrefixMults then inc(NumDifMults);
   if ZoneMults then inc(NumDifMults);

   MultString := GetLogEntryMultString(FileString);

   if MultString = '' then Exit;

   if StringHas(MultString, ' ') then
      begin
         MultArray[1] := PrecedingString(MultString, ' ');
         MultArray[2] := PostcedingString(MultString, ' ');
         NumberMults := 2;
      end
   else
      begin
         MultArray[1] := MultString;
         NumberMults := 1;
      end;

   for Mult := 1 to NumberMults do
      begin
         MultIdentified := False;

         if DomesticMults then
            if StringHasLowerCase(MultArray[Mult]) or (NumDifMults = 1) then
               begin
                  MultIdentified := true;

                  inc(DomesticTotals[Band, Mode]);
                  inc(DomesticTotals[Band, Both]);
                  inc(DomesticTotals[All, Mode]);
                  inc(DomesticTotals[All, Both]);
               end;

         if not MultIdentified then
            if ZoneMults and StringIsAllNumbers(MultArray[Mult]) then
               begin
                  inc(ZoneTotals[Band, Mode]);
                  inc(ZoneTotals[Band, Both]);
                  inc(ZoneTotals[All, Mode]);
                  inc(ZoneTotals[All, Both]);
                  MultIdentified := true;
               end;

         if not MultIdentified then
            if PrefixMults then
               begin
                  inc(PrefixTotals[Band, Mode]);
                  inc(PrefixTotals[Band, Both]);
                  inc(PrefixTotals[All, Mode]);
                  inc(PrefixTotals[All, Both]);
                  MultIdentified := true;
               end;

         if not MultIdentified then
            if DXMults then
               begin
                  inc(DXTotals[Band, Mode]);
                  inc(DXTotals[Band, Both]);
                  inc(DXTotals[All, Mode]);
                  inc(DXTotals[All, Both]);
               end;
      end;
end;

procedure CheckForNewContestDate(DateString: Str20);

var
   Index                           : integer;

begin
   if NumberDates = 0 then
      begin
         ContestDates[0] := DateString;
         inc(NumberDates);
         Exit;
      end;

   for Index := 0 to NumberDates - 1 do
      if ContestDates[Index] = DateString then Exit;

   ContestDates[NumberDates] := DateString;
   inc(NumberDates);

   if NumberDates > 10 then
      begin
         ShowMessage('Too many contest dates!!');
         halt;
      end;

end;

function CalculateTotals(DomesticMults: boolean;
   DXMults: boolean;
   PrefixMults: boolean;
   ZoneMults: boolean): boolean;

{ Returns TRUE if successful }

var
   FileRead                        : Text;
   FileString                      : Str80;
   Band                            : BandType;
   Mode                            : ModeType;
   QSOPoints                       : integer;

begin
   NumberDates := 0;

   CalculateTotals := False;

   for Band := Band160 to All do
      for Mode := cw to Both do
         begin
            QSOTotals[Band, Mode] := 0;
            RawQSOTotals[Band, Mode] := 0;
            QSOPointTotals[Band, Mode] := 0;
            DomesticTotals[Band, Mode] := 0;
            DXTotals[Band, Mode] := 0;
            PrefixTotals[Band, Mode] := 0;
            ZoneTotals[Band, Mode] := 0;
         end;

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage('Unable to open log file ' + LogFileName + '.');
         //        WaitForKeyPressed;
         Exit;
      end;

   while not Eof(FileRead) do
      begin
         ReadLn(FileRead, FileString);

         Band := GetLogEntryBand(FileString);

         if Band <> NoBand then
            begin
               CheckForNewContestDate(GetLogEntryDateString(FileString));

               Mode := GetLogEntryMode(FileString);

               inc(RawQSOTotals[Band, Mode]);
               inc(RawQSOTotals[Band, Both]);
               inc(RawQSOTotals[All, Mode]);
               inc(RawQSOTotals[All, Both]);

               if not (StringHas(UpperCase(FileString), '*DUPE*') or
                  (StringHas(UpperCase(FileString), '*ZERO*'))) then
                  begin
                     inc(QSOTotals[Band, Mode]);
                     inc(QSOTotals[Band, Both]);
                     inc(QSOTotals[All, Mode]);
                     inc(QSOTotals[All, Both]);

                     QSOPoints := GetLogEntryQSOPoints(FileString);

                     QSOPointTotals[Band, Mode] := QSOPointTotals[Band, Mode] + QSOPoints;
                     QSOPointTotals[Band, Both] := QSOPointTotals[Band, Both] + QSOPoints;
                     QSOPointTotals[All, Mode] := QSOPointTotals[All, Mode] + QSOPoints;
                     QSOPointTotals[All, Both] := QSOPointTotals[All, Both] + QSOPoints;

                     ProcessMultiplierTotals(Band, Mode,
                        DomesticMults,
                        DXMults,
                        PrefixMults,
                        ZoneMults,
                        FileString);
                  end;

               //            GoToXY (1, WhereY);
               //                 PostForm.cm.Lines.Add (inttostr(QSOTotals [All, Both])+'both');
            end;
      end;
   I := QSOTotals[All, Both];
   Close(FileRead);
   CalculateTotals := true;
end;

function GetCallAndContestFromLOGCFGFile(var MyCall: {Call} string;
   var Contest: string {40}): boolean;

var
   FileRead                        : Text;
   FileName                        : string;
   FileString                      : string {160};

begin
   GetCallAndContestFromLOGCFGFile := False;

   if (extractfilename(LogFileName) = 'LOG.DAT') then
      FileName := ExtractFileDir(LogFileName) + '\LOGCFG.DAT'
   else
      FileName := PrecedingString(LogFileName, '.') + '.CFG';

   if not OpenFileForRead(FileRead, FileName) then
      begin
         ShowMessage(FileName + ' not found!!');
         //        WaitForKeyPressed;
         Exit;
      end;

   while not Eof(FileRead) do
      begin
         ReadLn(FileRead, FileString);
         ExpandTabs(FileString);

         while pos('  ', FileString) <> 0 do
            Delete(FileString, pos('  ', FileString), 1);

         FileString := UpperCase(FileString);

         if pos(';', FileString) > 0 then
            FileString := PrecedingString(FileString, ';');

         if StringHas(FileString, 'MY CALL') then
            begin
               MyCall := PostcedingString(FileString, '=');
               GetRidOfPrecedingSpaces(MyCall);

            end;

         if StringHas(FileString, 'CONTEST=') or StringHas(FileString, 'CONTEST =') then
            begin
               Contest := PostcedingString(FileString, '=');
               if StringHas(Contest, ';') then Contest := PrecedingString(Contest, ';');
               GetRidOfPrecedingSpaces(Contest);

               GetCallAndContestFromLOGCFGFile := true;
               Close(FileRead);
               Exit;
            end;
      end;

   Close(FileRead);
end;

function DetermineContest(Name: Str80): ContestType;

begin
   DetermineContest := UnknownContest;
   Name := UpperCase(Name);

   if Name = 'CUP RF' then DetermineContest := CUPRF;

   if Name = 'ALL ASIAN' then DetermineContest := AllAsian;
   if Name = 'ALL JA' then DetermineContest := AllJA;
   if Name = 'AP SPRINT' then DetermineContest := APSprint;
   if Name = 'ARCI' then DetermineContest := ARCI;
   if Name = 'ARI' then DetermineContest := ARI;
   if Name = 'ARRL 10' then DetermineContest := ARRL10;
   if Name = 'ARRL 160' then DetermineContest := ARRL160;
   if Name = 'ARRL DX' then DetermineContest := ARRLDX;
   if Name = 'ARRL RTTY ROUNDUP' then DetermineContest := ARRLRTTY;
   if Name = 'ARRL VHF QSO' then DetermineContest := ARRLVHFQSO;
   if Name = 'ARRL VHF SS' then DetermineContest := ARRLVHFSS;

   if StringHas(Name, 'BALTIC') then DetermineContest := Baltic;

   if (Name = 'CAL QSO PARTY') or (Name = 'CALIFORNIA QSO PARTY') then
      DetermineContest := CalQSO;

   if Name = 'COUNTY HUNTER' then DetermineContest := County;
   if Name = 'CQ 160' then DetermineContest := CQ160;
   if Name = 'CQ M' then DetermineContest := CQM;
   if Name = 'CQ VHF' then DetermineContest := CQVHF;
   if Name = 'CQ WPX' then DetermineContest := CQWPX;
   if Name = 'CQ WW' then DetermineContest := CQWW;
   if Name = 'CQ WW RTTY' then DetermineContest := CQWWRTTY;
   if Name = 'CROATIAN' then DetermineContest := Croatian;
   if Name = 'EUROPEAN VHF' then DetermineContest := EuropeanVHF;
   if Name = 'EUROPEAN HFC' then DetermineContest := EuropeanHFC;
   if Name = 'FIELD DAY' then DetermineContest := FieldDay;

   if (Name = 'FQP') or (Name = 'FLORIDA QSO PARTY') then
      DetermineContest := FQP;

   if Name = 'GENERAL QSO' then DetermineContest := General;
   if Name = 'GRID LOC' then DetermineContest := GridLoc;
   if Name = 'HA DX' then DetermineContest := HADX;
   if Name = 'HELVETIA' then DetermineContest := Helvetia;
   if Name = 'IARU' then DetermineContest := IARU;
   if Name = 'IOTA' then DetermineContest := IOTA;
   if Name = 'KCJ' then DetermineContest := KCJ;
   if Name = 'KIDS DAY' then DetermineContest := KidsDay;
   if Name = 'KVP' then DetermineContest := KVP;

   if (Name = 'MICHIGAN QSO PARTY') or (Name = 'MICH QSO PARTY') or (Name = 'MI QSO PARTY') then
      DetermineContest := MIQP;

   if (Name = 'MINNESOTA QSO PARTY') or (Name = 'MINN QSO PARTY') or (Name = 'MQP') then
      DetermineContest := MQP;

   if Name = 'NA QSO' then DetermineContest := NAQSO;

   if (Name = 'NEW ENGLAND QSO') or (Name = 'NEQSO') or (Name = 'NEW ENGLAND QSO PARTY') then
      DetermineContest := NEQSO;

   if StringHas(Name, 'NRAU') then DetermineContest := NRAUBaltic;

   if Name = 'NZ FIELD DAY' then DetermineContest := NZFieldDay;
   if Name = 'OCEANIA' then DetermineContest := OceaniaVKZL;
   if Name = 'OHIO QSO PARTY' then DetermineContest := OhioQP;
   if Name = 'OK DX' then DetermineContest := OKDX;
   if Name = 'PACC' then DetermineContest := PACC;
   if Name = 'QCWA' then DetermineContest := QCWA;
   if Name = 'RAC' then DetermineContest := Rac;
   if Name = 'ROPOCO' then DetermineContest := Ropoco;
   if Name = 'RUSSIAN DX' then DetermineContest := Russian;
   if Name = 'SALMON RUN' then DetermineContest := SalmonRun; {KK1L: 6.71}
   if Name = 'SP DX' then DetermineContest := SPDX;
   if Name = 'SPRINT' then DetermineContest := Sprint;
   if Name = 'STEW PERRY' then DetermineContest := StewPerry;
   if Name = 'SWEEPSTAKES' then DetermineContest := ss;
   if Name = 'TEN TEN' then DetermineContest := TenTen;
   if Name = 'TOEC' then DetermineContest := Toec;
   if Name = 'UBA' then DetermineContest := UBA;
   if Name = 'UKRAINIAN' then DetermineContest := Ukrainian;
   if Name = 'WAE' then DetermineContest := WAE;
   if Name = 'WAG' then DetermineContest := WAG;
   if Name = 'WQP' then DetermineContest := WQP;
   if Name = 'WWL' then DetermineContest := WWL;
   if Name = 'WRTC' then DetermineContest := WRTC;
   if Name = 'WRTC 2002' then DetermineContest := WRTC2002; {KK1L: 6.68}
   if Name = 'XMAS' then DetermineContest := XMAS;
   if Name = 'YO DX' then DetermineContest := YODX;

   if (Name = 'REGION ONE FIELD DAY') or (Name = 'REGION 1 FIELD DAY') then
      DetermineContest := Region1FD;

   if (Name = 'EU SPRINT') or (Name = 'EUROPEAN SPRINT') then
      DetermineContest := EuropeanSprint;

   if Name = 'INTERNET SPRINT' then DetermineContest := IntSprint;
   if Name = 'JA INTERNATIONAL DX' then DetermineContest := JADX;
   if Name = 'JIDX' then DetermineContest := JADX;
   if Name = 'JA LONG PREFECT' then DetermineContest := JALP; {KK1L: 6.72}
   if (Name = 'SCANDINAVIAN') or (Name = 'SAC') then DetermineContest := SAC;
   if Name = 'SOUTH AMERICA WW' then DetermineContest := SAWW;
   if Name = 'SOUTH AMERICAN' then DetermineContest := sa;
   if Name = 'TEXAS QSO PARTY' then DetermineContest := TexQSO;
   if Name = 'WISCONSIN QSO PARTY' then DetermineContest := WQP;
end;

procedure CalculateAppropriateTotalsForThisContest(Contest: ContestType;
   MyQTH: QTHRecord);

begin
   case Contest of

      CUPRF:
         if not CalculateTotals(true, False, False, False) then Exit;

      AllAsian:
         if MyQTH.Continent = Asia then
            begin
               if not CalculateTotals(False, true, False, False) then Exit;
            end
         else
            if not CalculateTotals(False, False, true, False) then Exit;

      AllJA:
         if not CalculateTotals(true, False, False, False) then Exit;
      ARCI:
         if not CalculateTotals(true, true, False, False) then Exit;
      APSprint:
         if not CalculateTotals(False, False, true, False) then Exit;
      ARI:
         if not CalculateTotals(true, true, False, False) then Exit;
      ARRL10:
         if not CalculateTotals(true, true, False, False) then Exit;
      ARRL160:
         if not CalculateTotals(true, true, False, False) then Exit;

      ARRLDX:
         if (MyQTH.CountryID = 'K') or (MyQTH.CountryID = 'VE') then
            begin
               if not CalculateTotals(False, true, False, False) then Exit;
            end
         else
            if not CalculateTotals(true, False, False, False) then Exit;

      ARRLRTTY:
         if not CalculateTotals(true, true, False, False) then Exit;
      ARRLVHFQSO:
         if not CalculateTotals(true, False, False, False) then Exit;
      ARRLVHFSS:
         if not CalculateTotals(true, False, False, False) then Exit;
      Baltic:
         if not CalculateTotals(False, False, False, False) then Exit;

      CalQSO:
         if not CalculateTotals(true, False, False, False) then Exit;
      County:
         if not CalculateTotals(true, False, False, False) then Exit;
      CQ160:
         if not CalculateTotals(true, true, False, False) then Exit;
      CQM:
         if not CalculateTotals(False, true, False, False) then Exit;
      CQVHF:
         if not CalculateTotals(true, False, False, False) then Exit;
      CQWPX:
         if not CalculateTotals(False, False, true, False) then Exit;
      CQWW:
         if not CalculateTotals(False, true, False, true) then Exit;
      CQWWRTTY:
         if not CalculateTotals(true, true, False, true) then Exit;
      Croatian:
         if not CalculateTotals(true, true, False, true) then Exit;

      EuropeanSprint:
         if not CalculateTotals(False, False, False, False) then Exit;

      EuropeanHFC:
         if not CalculateTotals(False, False, False, true) then Exit;
      EuropeanVHF:
         if not CalculateTotals(true, False, False, False) then Exit;
      FieldDay:
         if not CalculateTotals(False, False, False, False) then Exit;
      FQP:
         if not CalculateTotals(true, true, False, False) then Exit;
      General:
         if not CalculateTotals(False, False, False, False) then Exit;
      GridLoc:
         if not CalculateTotals(true, False, False, False) then Exit;
      HADX:
         if not CalculateTotals(true, False, False, False) then Exit;

      Helvetia:
         if MyQTH.CountryID = 'HB' then
            begin
               if not CalculateTotals(true, true, False, False) then Exit;
            end
         else
            if not CalculateTotals(true, False, False, False) then Exit;

      IARU:
         if not CalculateTotals(true, False, False, true) then Exit;
      IntSprint:
         if not CalculateTotals(False, False, False, False) then Exit;
      IOTA:
         if not CalculateTotals(true, False, False, False) then Exit;

      JADX:
         if (MyQTH.CountryID = 'JA') or (MyQTH.CountryID = 'JD/m') or (MyQTH.CountryID = 'JD/o') then
            begin
               if not CalculateTotals(False, true, False, true) then Exit;
            end
         else
            if not CalculateTotals(true, False, False, False) then Exit;

      JALP:
         if not CalculateTotals(true, False, False, False) then Exit; {KK1L: 6.72}

      KCJ:
         if not CalculateTotals(true, False, False, False) then Exit;
      KidsDay:
         if not CalculateTotals(False, False, False, False) then Exit;
      KVP:
         if not CalculateTotals(False, False, False, true) then Exit;
      MIQP:
         if not CalculateTotals(true, False, False, False) then Exit;
      MQP:
         if not CalculateTotals(true, False, False, False) then Exit;
      NAQSO:
         if not CalculateTotals(true, False, False, False) then Exit;
      NEQSO:
         if not CalculateTotals(true, False, False, False) then Exit;
      NRAUBaltic:
         if not CalculateTotals(true, False, False, False) then Exit;
      NZFieldDay:
         if not CalculateTotals(False, False, False, true) then Exit;

      OceaniaVKZL:
         if not CalculateTotals(False, False, true, False) then Exit;

      OhioQP:
         if not CalculateTotals(true, False, False, False) then Exit;
      OKDX:
         if not CalculateTotals(true, true, False, False) then Exit;
      PACC:
         if not CalculateTotals(true, False, False, False) then Exit;
      QCWA:
         if not CalculateTotals(False, False, False, False) then Exit;
      RAC:
         if not CalculateTotals(true, False, False, False) then Exit;
      Region1FD:
         if not CalculateTotals(False, False, False, False) then Exit;
      Ropoco:
         if not CalculateTotals(true, False, False, False) then Exit;
      Russian:
         if not CalculateTotals(true, true, False, False) then Exit;

      SAC:
         if ScandinavianCountry(MyQTH.CountryID) then
            begin
               if not CalculateTotals(False, true, False, False) then Exit;
            end
         else
            if not CalculateTotals(true, False, False, False) then Exit;

      sa:
         if not CalculateTotals(False, False, true, False) then Exit;
      SAWW:
         if not CalculateTotals(False, False, true, False) then Exit;
      SalmonRun:
         if not CalculateTotals(true, False, False, False) then Exit; {KK1L: 6.71}
      SPDX:
         if not CalculateTotals(true, False, False, False) then Exit;
      Sprint:
         if not CalculateTotals(true, true, False, False) then Exit;
      ss:
         if not CalculateTotals(true, False, False, False) then Exit;
      StewPerry:
         if not CalculateTotals(False, False, False, False) then Exit;
      TenTen:
         if not CalculateTotals(true, true, False, False) then Exit;
      TexQSO:
         if not CalculateTotals(true, true, False, False) then Exit;
      TOEC:
         if not CalculateTotals(true, False, False, False) then Exit;
      UBA:
         if not CalculateTotals(true, true, true, False) then Exit;
      Ukrainian:
         if not CalculateTotals(true, true, False, False) then Exit;
      WAE:
         if not CalculateTotals(False, true, False, False) then Exit;
      WAG:
         if not CalculateTotals(true, true, False, False) then Exit;
      WQP:
         if not CalculateTotals(true, False, False, False) then Exit;
      WWL:
         if not CalculateTotals(true, False, False, False) then Exit;
      WRTC:
         if not CalculateTotals(true, true, False, true) then Exit;
      WRTC2002:
         if not CalculateTotals(true, true, False, False) then Exit; {KK1L: 6.68}
      XMAS:
         if not CalculateTotals(False, False, False, False) then Exit;
      YODX:
         if not CalculateTotals(true, true, False, true) then Exit;
   end;
end;

procedure DetermineModesAndBandsUsed;

var
   Band                            : BandType;
   Mode                            : ModeType;

begin
   for Band := Band160 to All do
      for Mode := cw to Phone do
         BandModeUsed[Band, Mode] := RAWQSOTotals[Band, Mode] > 0;

   CWUsed := RAWQSOTotals[All, cw] > 0;
   PhoneUsed := RAWQSOTotals[All, Phone] > 0;
   {   DigitalUsed := RAWQSOTotals [All, Digital] > 0;}
end;

procedure WriteTitleBlockToSummarySheet(ContestName: string {80};
   Contest: ContestType;
   MyCall: CallString;
   MyQTH: QTHRecord);

var
   Directory, CityString, AddressString, NameString, TempString: Str80;
   FileRead, FileWrite             : Text;
   Key                             : Char;
   Date                            : integer;

begin
   WriteLn(SummaryWrite);

   ContestName := ContestName + ' SUMMARY SHEET';

   while length(ContestName) < 80 do
      ContestName := ' ' + ContestName + ' ';

   GetRidOfPostcedingSpaces(ContestName);

   WriteLn(SummaryWrite, ContestName);
   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);

   if NumberDates = 1 then
      WriteLn(SummaryWrite, '     Contest Date : ' + ContestDates[0])
   else
      begin
         Write(SummaryWrite, '    Contest Dates : ');

         for Date := 0 to NumberDates - 2 do
            Write(SummaryWrite, ContestDates[Date] + ', ');

         WriteLn(SummaryWrite, ContestDates[NumberDates - 1]);
      end;

   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);

   WriteLn(SummaryWrite, '    Callsign Used : ', MyCall);

   TempString := postform.OPEdit.Text; //GetResponse('Operators : ');

   if TempString <> '' then
      if StringHas(TempString, ' ') then
         WriteLn(SummaryWrite, '        Operators : ', TempString)
      else
         WriteLn(SummaryWrite, '         Operator : ', TempString);

   WriteLn(SummaryWrite);

   TempString := postform.CatCB.Text;

   if TempString <> '' then
      begin
         WriteLn(SummaryWrite, '         Category : ', TempString);
         WriteLn(SummaryWrite);
      end;

   if Contest = IOTA then
      begin
         repeat
            Key := UpCase(GetKey('Are you a (H)ome station or (D)X-pedition? (H/D) : '));
         until (Key = 'H') or (Key = 'D') or (Key = EscapeKey);
         //    WriteLn;

         if Key = 'H' then
            WriteLn(SummaryWrite, 'This effort was from my home station.');

         if Key = 'D' then
            WriteLn(SummaryWrite, 'This was a DX Pedition operation.');

      end;

   //    TextColor (Cyan);
   //  WriteLn;
   //  WriteLn('If you sent some information such as RST, section, age, zone or power for');
   //  WriteLn('each QSO, it will be noted on your summary sheet as your default exchange.');
   //  WriteLn;

   TempString := postform.DEEdit.Text;

   if TempString <> '' then
      begin
         WriteLn(SummaryWrite, ' Default Exchange : ', TempString);
         WriteLn(SummaryWrite);
      end;
   {
     Directory := FindDirectory('address.dat');

     if Directory = '' then
       if FileExists('\log\name\address.dat') then
         Directory := '\log\name'
       else
         FindDirectory('tr.exe');
   }
   if not OpenFileForRead(FileRead, { Directory + '\'+} 'address.dat') then
      begin
         NameString := GetResponse('Enter your full name : ');
         NameString := '             Name : ' + NameString;
         WriteLn(SummaryWrite, NameString);

         AddressString := GetResponse('Enter your Address (not city/state) : ');
         AddressString := '          Address : ' + AddressString;
         WriteLn(SummaryWrite, AddressString);

         CityString := GetResponse('Enter your City/State/Zip : ');
         CityString := '   City/State/Zip : ' + CityString;
         WriteLn(SummaryWrite, CityString);

         //    WriteLn;
         {
             repeat
               Key := UpCase(GetKey('Do you want to save this information for next time? (Y/N) : '));
             until (Key = 'Y') or (Key = 'N');
             WriteLn;
         }

         if MessageBox(0, 'Do you want to save this information for next time?', p, MB_YESNO or MB_ICONQUESTION) <> IDno then

            //    if Key = 'Y' then
            begin
               OpenFileForWrite(FileWrite, { Directory + '\'+} 'address.dat');
               WriteLn(FileWrite, NameString);
               WriteLn(FileWrite, AddressString);
               WriteLn(FileWrite, CityString);
               Close(FileWrite);
            end;
      end
   else
      begin
         while not Eof(FileRead) do
            begin
               ReadLn(FileRead, TempString);
               WriteLn(SummaryWrite, TempString);
            end;
         Close(FileRead);
      end;

   WriteLn(SummaryWrite, '          Country : ', CountryTable.GetCountryName(MyQTH.Country));
   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);

   TempString := postform.TorCEdit.Text;

   if TempString <> '' then
      begin
         WriteLn(SummaryWrite, '        Team/Club : ', TempString);
         WriteLn(SummaryWrite);
      end;
end;

function DetermineNumberOfQTCs: integer;

{ This procedure will look at the QTC.DAT file and determine how many QTCs
  were sent or received. }

var
   FileRead                        : Text;
   FileString                      : Str80;
   QTCsThisStation, NumberQTCs     : integer;

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

procedure WriteScoreInformationToSummarySheet(Contest: ContestType;
   MyCall: CallString;
   MyQTH: QTHRecord);

var
   UnderlineString                 : Str80;
   Index                           : integer;
   Band                            : BandType;
   Mode                            : ModeType;
   TotalMultipliers                : LONGINT;
   TotalQSOPoints                  : LONGINT;
   TotalQTCs                       : LONGINT;
   TotalScore                      : LONGINT;
   TempString                      : Str80;

begin
   TempString := '   BAND   Raw QSOs   Valid QSOs   Points   ';

   if DomesticTotals[All, Both] > 0 then TempString := TempString + 'Mults   ';
   if DXTotals[All, Both] > 0 then TempString := TempString + 'Countries   ';
   if PrefixTotals[All, Both] > 0 then TempString := TempString + 'Prefixes   ';
   if ZoneTotals[All, Both] > 0 then TempString := TempString + 'Zones';

   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite, TempString);

   UnderlineString := '';

   for Index := 1 to length(TempString) do
      UnderlineString := UnderlineString + '_';

   UnderlineString[1] := ' ';

   WriteLn(SummaryWrite, UnderlineString);
   WriteLn(SummaryWrite);

   for Band := Band160 to BandLight do
      for Mode := cw to Phone do
         if RawQSOTotals[Band, Mode] > 0 then
            begin
               Write(SummaryWrite, '  ', BandString[Band], ModeString[Mode]);

               Write(SummaryWrite, RawQSOTotals[Band, Mode]: 8);
               Write(SummaryWrite, QSOTotals[Band, Mode]: 12);
               Write(SummaryWrite, QSOPointTotals[Band, Mode]: 11);
               Write(SummaryWrite, ' ');

               if DomesticTotals[All, Both] > 0 then
                  Write(SummaryWrite, DomesticTotals[Band, Mode]: 7, ' ');

               if DXTotals[All, Both] > 0 then
                  Write(SummaryWrite, DXTotals[Band, Mode]: 9, ' ');

               if PrefixTotals[All, Both] > 0 then
                  Write(SummaryWrite, PrefixTotals[Band, Mode]: 8, ' ');

               if ZoneTotals[All, Both] > 0 then
                  Write(SummaryWrite, ZoneTotals[Band, Mode]: 9);

               WriteLn(SummaryWrite);
            end;

   WriteLn(SummaryWrite, UnderlineString);
   WriteLn(SummaryWrite);

   Write(SummaryWrite, ' Totals ');
   Write(SummaryWrite, RawQSOTotals[All, Both]: 8);
   Write(SummaryWrite, QSOTotals[All, Both]: 12);
   Write(SummaryWrite, QSOPointTotals[All, Both]: 11);
   Write(SummaryWrite, ' ');

   if DomesticTotals[All, Both] > 0 then
      Write(SummaryWrite, DomesticTotals[All, Both]: 7, ' ');

   if DXTotals[All, Both] > 0 then
      Write(SummaryWrite, DXTotals[All, Both]: 9, ' ');

   if PrefixTotals[All, Both] > 0 then
      Write(SummaryWrite, PrefixTotals[All, Both]: 8, ' ');

   if ZoneTotals[All, Both] > 0 then
      Write(SummaryWrite, ZoneTotals[All, Both]: 9);

   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);

   { Now we compute the final score }

   TotalQSOPoints := QSOPointTotals[All, Both];

   if Contest = WAE then
      begin
         TotalQTCs := DetermineNumberOfQTCs; { Add into QSO points }

         if TotalQTCs = 0 then
            begin
               WriteLn(SummaryWrite, '    There were no QTC points.');
               WriteLn(SummaryWrite);
            end
         else
            begin
               WriteLn(SummaryWrite, '    There were ', TotalQTCs, ' QTC points.');
               WriteLn(SummaryWrite);
            end;

         TotalMultipliers := DXTotals[Band80, Both] * 4 +
            DXTotals[Band40, Both] * 3 +
            DXTotals[Band20, Both] * 2 +
            DXTotals[Band15, Both] * 2 +
            DXTotals[Band10, Both] * 2;
      end
   else
      begin
         TotalQTCs := 0;
         TotalMultipliers := DomesticTotals[All, Both] +
            DXTotals[All, Both] +
            PrefixTotals[All, Both] +
            ZoneTotals[All, Both];
      end;

   if TotalMultipliers > 0 then
      begin
         TotalScore := (TotalQSOPoints + TotalQTCs) * TotalMultipliers;
         if Contest = CUPRF then TotalScore := TotalQSOPoints + 120 * TotalMultipliers;
      end
   else
      TotalScore := TotalQSOPoints;

   WriteLn(SummaryWrite, '    Final Score = ', TotalScore, ' points.');
   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);
end;

procedure WriteSoapBoxToSummarySheet;

var
   TempString                      : Str80;
   FirstLine                       : boolean;

begin
   FirstLine := true;
   //    TextColor (Cyan);
   //  WriteLn;
   //  WriteLn('Enter as many soapbox comment lines as you want.  Press extra RETURN to stop.');

   //    TextColor (Yellow);

   //  repeat
   //    ReadLn(TempString);
   TempString := postform.SoapEdit.Text;

   if TempString <> '' then
      begin
         if FirstLine then
            begin
               WriteLn(SummaryWrite, ' Soapbox Comments');
               WriteLn(SummaryWrite, ' ________________');
               WriteLn(SummaryWrite);
               FirstLine := False;
            end;

         WriteLn(SummaryWrite, ' ' + TempString);
      end;

   //  until TempString = '';

   if not FirstLine then
      begin
         WriteLn(SummaryWrite);
         WriteLn(SummaryWrite);
      end;
end;

procedure WriteSignatureBlockToSummarySheet(Contest: ContestType);

begin
   WriteLn(SummaryWrite);

   case Contest of

      CQWW, CQWPX, CQ160, CQVHF:
         begin
            WriteLn(SummaryWrite, ' This is to certify that in the contest I have operated my transmitter within');
            WriteLn(SummaryWrite, ' the limitations of my license and have observed fully the rules and ');
            WriteLn(SummaryWrite, ' regulations of the contest.');
         end;

      Sprint:
         begin
            WriteLn(SummaryWrite, 'I, by virtue of my statement below, have taken part in the NCJ North American');
            WriteLn(SummaryWrite, 'Sprint, conscientiously applying my most ethical interpretation of the rules');
            WriteLn(SummaryWrite, 'for this contest as set forth in the National Contest Journal.');
         end;

      else
         begin
            WriteLn(SummaryWrite, ' I have observed all competition rules as well as all regulations established');
            WriteLn(SummaryWrite, ' for amateur radio in my country.  My report is correct and true to the best');
            WriteLn(SummaryWrite, ' of my knowledge.  I agree to be bound by the decisions of the Awards Committee.');
         end;

   end;

   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);
   WriteLn(SummaryWrite);

   WriteLn(SummaryWrite, ' Date ______________   Signed _____________________________  Call ___________');
end;

procedure SummarySheet;

var
   Contest                         : ContestType;
   ContestName, MyCall             : string {80};
   Key                             : Char;

   MyQTH                           : QTHRecord;
   ts                              : string;
   TotalScore                      : LONGINT;

begin
   //    ClrScr;
   //    TextColor (Yellow);
   {  WriteLnCenter('SUMMARY SHEET');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will use the information in your LOG.DAT file to generate a ');
     WriteLn('generic summary sheet.  The summary sheet will only be output to a file so');
     WriteLn('you can make changes to it before printing it out.');
     WriteLn;
     WriteLn('You need to run this procedure from the same directory you used during the ');
     WriteLn('contest so that the log and config files are available.');
     WriteLn;
     WriteLn('You should mark any dupes in your log before running this procedure.  Use the');
     WriteLn('Dupe Log command under the LOG MENU to do this.');
     WriteLn;
     WriteLn('If you have the file address.dat, the information in that file will be written');
     WriteLn('on the summary sheet so your address shows up automatically.  You can also put');
     WriteLn('your station description in this file.  If you don''t have this file, the');
     WriteLn('program will prompt you for your address and create on.');
     WriteLn;

     if not OkayToProceed then exit;
   }
   //    ClrScr;
   //    TextColor (Yellow);
   //  WriteLnCenter('SUMMARY SHEET');
   //  WriteLn;
   //    TextColor (Cyan);

   if not GetCallAndContestFromLOGCFGFile(MyCall, ContestName) then Exit;

   GetRidOfPostcedingSpaces(ContestName);

   Contest := DetermineContest(ContestName);

   if Contest = UnknownContest then
      begin
         ShowMessage(ContestName + ' is not yet supported.  Check for new updates.');
         Exit;
      end;

   CountryTable.CountryMode := ARRLCountryMode;
   CountryTable.ZoneMode := CQZoneMode;

   case Contest of
      CQ160: CountryTable.CountryMode := CQCountryMode;
      CQVHF: CountryTable.CountryMode := CQCountryMode;
      CQWPX: CountryTable.CountryMode := CQCountryMode;
      CQWW: CountryTable.CountryMode := CQCountryMode;
      IARU: CountryTable.ZoneMode := ITUZoneMode;
      OKDX: CountryTable.CountryMode := CQCountryMode;
      WAE: CountryTable.CountryMode := CQCountryMode;
      WAG: CountryTable.CountryMode := CQCountryMode;
      YODX: CountryTable.ZoneMode := ITUZoneMode;
   end;

   LocateCall(MyCall, MyQTH, true);

   if not CheckForTempFile then Exit;
   ts := 'Your call is ' + MyCall + ' and the contest is ' + ContestName + '.' + #13 +
      'Your continent is ' + GetContinentName(MyQTH.Continent) + #13 +
      'Your country is ' + CountryTable.GetCountryName(MyQTH.Country) + #13 +
      'Your country ID prefix is ' + MyQTH.CountryID + #13 + #13 + 'Is this information correct?';

   if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) = IDno then

      begin
         ShowMessage('Please correct your config file or your country files and then restart.');
         Exit;
      end;

   //    TextColor (Cyan);
   CalculateAppropriateTotalsForThisContest(Contest, MyQTH);

   if RawQSOTotals[All, Both] = 0 then
      begin
         ShowMessage('There were no contacts found in the active log file.');
         Exit;
      end;

   //  Write(' QSOs were found in your log.');
   //  WriteLn;

   DetermineModesAndBandsUsed;

   SummaryFileName := PrecedingString(LogFileName, '.'); {KK1L: 6.72}
   if SummaryFileName = 'LOG' then {KK1L: 6.72}
      SummaryFileName := 'SUMMARY.DAT' {KK1L: 6.72}
   else {KK1L: 6.72}
      SummaryFileName := SummaryFileName + '.SUM'; {KK1L: 6.72}

   if FileExists(SummaryFileName) then {KK1L: 6.72 changed from SUMMARY.DAT'}
      begin
         {    repeat
               Key := UpCase(GetKey('File ' + SummaryFileName + ' already exists.  Okay to overwrite? (Y/N): ')); //KK1L: 6.72
             until (Key = EscapeKey) or (Key = 'N') or (Key = 'Y');
             WriteLn;
         }

         ts := 'File ' + SummaryFileName + ' already exists.  Okay to overwrite?';

         if MessageBox(0, PChar(ts), p, MB_YESNO or MB_ICONQUESTION) <> IDYES then Exit;

         //      if Key <> 'Y' then exit;
      end;

   OpenFileForWrite(SummaryWrite, SummaryFileName); {KK1L: 6.72 changed from SUMMARY.DAT'}

   WriteTitleBlockToSummarySheet(ContestName, Contest, MyCall, MyQTH);
   WriteScoreInformationToSummarySheet(Contest, MyCall, MyQTH);
   WriteSoapBoxToSummarySheet;
   WriteSignatureBlockToSummarySheet(Contest);

   Close(SummaryWrite);

   postform.cm.Lines.Add('Your summary sheet has been saved in the file ' + SummaryFileName {SUMMARY.DAT});
   postform.cm.Lines.Add('If you need to make changes to it, this can be done with a text editor.');
   view(Summaryfilename);
end;

procedure TopOfForm(var FileWrite: Text);

begin
   Lines := 5;
   WriteLn(FileWrite);
   WriteLn(FileWrite, '           ', DupeSheetTitle);
   WriteLn(FileWrite);
end;

procedure FormFeed(var FileWrite: Text);

begin
   Write(FileWrite, CHR(12));
   TopOfForm(FileWrite);
end;

procedure PrintSomeCalls(PrintList: CallArrayPtr;
   CallPointerList: CallPointerArrayPtr;
   Finish: integer;
   var FileWrite: Text);

var
   Index, Row, col                 : integer;

begin
   for Row := 0 to NLines - 1 do
      begin
         for col := 0 to (Columns - 1) do
            begin
               Index := PrintBreak + Offset + (NLines * col) + Row;

               if Index > Finish then
                  TempString := ' '
               else
                  TempString := PrintList^[CallPointerList^[Index]];

               TempString := TempString + '            ';
               //wli
               //            TempString [0] := Chr (PrinterColumns DIV Columns);
               Write(FileWrite, TempString);
            end;

         WriteLn(FileWrite, '');
      end;
end;

procedure PrintCalls(var CountryName: Str80;
   var FileWrite: Text);

{ This procedure will print as many of the callsigns as it can on the
  current page. }

var
   Index, Row, col, BytesToMove, ActualCallsPrinted: integer;

begin
   { Determine how many lines we are going to print -> NLines.  If there
     needs to be a line feed before starting, make it so. }

   NCalls := NumberCallsInCallBuffer;
   NLines := (NCalls - 1) div Columns + 1;

   if (NLines + Lines) > 55 then
      if Lines > 45 then
         begin
            FormFeed(FileWrite);
            if NLines > 55 then { Can't do more than 55 lines }
               NLines := 55;
         end
      else
         NLines := 56 - Lines;

   { If this is the first time we are printing calls for this country,
     CountryName will not be blank and we will need to print the name
     for the country. }

   if CountryName <> '' then
      begin
         WriteLn(FileWrite);
         inc(Lines);
         WriteLn(FileWrite, CountryName);
         inc(Lines);
      end;

   for Row := 0 to NLines - 1 do
      begin
         for col := 0 to (Columns - 1) do
            begin
               Index := (NLines * col) + Row;

               if Index >= NumberCallsInCallBuffer then
                  TempString := ' '
               else
                  TempString := CallBuffer^[Index];

               if col <> (Columns - 1) then
                  begin
                     TempString := TempString + '            ';
                     TempString := Copy(TempString, 1, PrinterColumns div Columns);
                  end;

               Write(FileWrite, TempString);
            end;

         WriteLn(FileWrite, '');
         inc(Lines);
      end;

   ActualCallsPrinted := NLines * Columns;

   if ActualCallsPrinted >= NumberCallsInCallBuffer then
      begin
         NumberCallsInCallBuffer := 0;
         Exit;
      end;

   { There are calls left in the buffer - we need to remove the ones
     we printed and leave things so more can be added and I get called
     again.

     First, clear out the name so I don't print the country name again }

   CountryName := '';

   BytesToMove := (NumberCallsInCallBuffer - ActualCallsPrinted) * SizeOf(CallBuffer^[0]);

   Move(CallBuffer^[ActualCallsPrinted], CallBuffer^[0], BytesToMove);
   NumberCallsInCallBuffer := NumberCallsInCallBuffer - ActualCallsPrinted;
end;

procedure LoadUpCallBufferWithSomeCalls(Country: integer);

{ This routine will move as many callsigns as it can from the linked
  list for the country indicated into the CallBuffer array.  If it
  can't fit them all in, it will leave the DupeSheetStartArray [Country]
  pointint to the next record to be processed.

  It disposes of memory used by entries moved into the array. }

var
   NextRecord                      : DupeSheetEntryRecordPointer;

begin
   while (DupeSheetStartArray[Country] <> nil) and (NumberCallsInCallBuffer < CallBufferSize) do
      begin
         CallBuffer^[NumberCallsInCallBuffer] := DupeSheetStartArray[Country]^.Call;
         inc(NumberCallsInCallBuffer);

         NextRecord := DupeSheetStartArray[Country]^.Next;
         Dispose(DupeSheetStartArray[Country]);

         DupeSheetStartArray[Country] := NextRecord;
      end;
end;

procedure PrintCountryCalls(Country: integer;
   var FileWrite: Text);

{ This procedure will print the calls found for the country indicated.  The
  records for the callsigns are disposed of as they are printed. }

var
   CountryName                     : Str80;

begin
   NumberCallsInCallBuffer := 0;

   CountryName := CountryTable.GetCountryName(Country);
   if CountryName = '' then CountryName := 'Unknown countries';

   LoadUpCallBufferWithSomeCalls(Country);

   while NumberCallsInCallBuffer > 0 do
      begin
         PrintCalls(CountryName, FileWrite);
         LoadUpCallBufferWithSomeCalls(Country);
      end;
end;

procedure MakeDupeSheet(OutputFileName: Str80; Title: Str80);

{ This procedure will take the list of callsigns loaded into the call
  buffer and produce a dupe sheet with the filename indicated.  If the
  filename is LST:, then the list will be printed.  If it is null string,
  then the list is displayed. }

var
   Call, CountryID                 : CallString;
   Address, Country, NumberEntries : integer;
   ActiveRecord, PreviousRecord, newrecord: DupeSheetEntryRecordPointer;
   FileWrite                       : Text;

begin
   DupeSheetTitle := Title;
   NumberEntries := 0;

   if NumberBufferCalls <= 0 then Exit;

   if not OpenFileForWrite(FileWrite, OutputFileName) then
      begin
         ShowMessage('Unable to open output file.');
         //        WaitForKeyPressed;
         Exit;
      end;

   New(CallBuffer);

   for Address := -1 to MaxCountries - 1 do
      DupeSheetStartArray[Address] := nil;

   //    TextColor (Cyan);

   for Address := 0 to NumberBufferCalls - 1 do
      begin
         //        IF Address MOD 10 = 0 THEN PinWheel;

         Call := GetCall(Address);
         Country := CountryTable.GetCountry(Call, true); { -1 = unknown }

         { First see if this is the first entry for this country }

         if DupeSheetStartArray[Country] = nil then
            begin
               DupeSheetStartArray[Country] := New(DupeSheetEntryRecordPointer);
               DupeSheetStartArray[Country]^.Call := Call;
               DupeSheetStartArray[Country]^.Next := nil;
               inc(NumberEntries);
               Continue;
            end;

         { Look at the first entry to see if we should squeeze in at front }

         if DupeSheetStartArray[Country]^.Call > Call then
            begin
               ActiveRecord := DupeSheetStartArray[Country];
               DupeSheetStartArray[Country] := New(DupeSheetEntryRecordPointer);
               DupeSheetStartArray[Country]^.Call := Call;
               DupeSheetStartArray[Country]^.Next := ActiveRecord;
               inc(NumberEntries);
               Continue;
            end;

         { If there is only one entry, put it at the end of the list }

         if DupeSheetStartArray[Country]^.Next = nil then
            begin
               ActiveRecord := New(DupeSheetEntryRecordPointer);
               ActiveRecord^.Call := Call;
               ActiveRecord^.Next := nil;
               DupeSheetStartArray[Country]^.Next := ActiveRecord;
               inc(NumberEntries);
               Continue;
            end;

         { Look through the list and see if we can find a place for this call }

         PreviousRecord := DupeSheetStartArray[Country];
         ActiveRecord := DupeSheetStartArray[Country]^.Next;

         repeat
            if ActiveRecord^.Call > Call then
               begin
                  newrecord := New(DupeSheetEntryRecordPointer);

                  newrecord^.Next := ActiveRecord;
                  newrecord^.Call := Call;

                  PreviousRecord^.Next := newrecord;
                  inc(NumberEntries);
                  Break;
               end;

            if ActiveRecord^.Call = Call then Break; { Ignore dupes }

            if ActiveRecord^.Next = nil then { Reached end of list }
               begin
                  ActiveRecord^.Next := New(DupeSheetEntryRecordPointer);

                  ActiveRecord := ActiveRecord^.Next;

                  ActiveRecord^.Call := Call;
                  ActiveRecord^.Next := nil;
                  inc(NumberEntries);
                  Break;
               end;

            PreviousRecord := ActiveRecord;
            ActiveRecord := ActiveRecord^.Next;
         until ActiveRecord = nil;
      end;

   //    GoToXY (1, WhereY);
   //    ClrEol;
   //    GoTOXY (1, WhereY - 1);
   //    ClrEol;
   //  Write('Writing output...');

   NumberCountries := 0;

   TopOfForm(FileWrite);

   //    TextColor (Cyan);

   for Country := 0 to CountryTable.NumberCountries - 1 do
      if DupeSheetStartArray[Country] <> nil then
         begin
            //            GoToXY (1, WhereY);
            //            ClrEol;
            postform.cm.Lines.Add('Printing calls for ' + CountryTable.GetCountryID(Country));
            PrintCountryCalls(Country, FileWrite);
            inc(NumberCountries);
         end;

   WriteLn(FileWrite, '');
   WriteLn(FileWrite, 'Number of different countries listed = ', NumberCountries, '.');

   Lines := Lines + 2;

   PrintCountryCalls(-1, FileWrite); { Unknown countries }

   if NumberEntries <> NumberBufferCalls then
      begin
         Write(FileWrite, 'Number of callsigns = ', NumberEntries, '.  ');

         if NumberBufferCalls - NumberEntries = 1 then
            Write(FileWrite, 'There was one dupe ignored.')
         else
            Write(FileWrite, 'There were ', NumberBufferCalls - NumberEntries, ' dupes ignored.');
      end
   else
      Write(FileWrite, 'Number of callsigns = ', NumberEntries, '.');

   Write(FileWrite, CHR(12));
   Close(FileWrite);
   Dispose(CallBuffer);
end;

procedure BandChangeReport;

var
   LastBand, Band                  : BandType;
   LastMode, Mode                  : ModeType;
   FirstQSO                        : boolean;
   QSONumber, NumberBandChanges, NumberTwoXmtrQSOs, LastBandChangeQSO: integer;
   Destination                     : Char;
   Title, FileName, TempString     : Str80;
   FileRead, FileWrite             : Text;

begin
   {
   //    ClrScr;
   //    TextColor (Yellow);
     WriteLnCenter('BAND CHANGE REPORT PROCEDURE');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will generate a report showing the when band changes were    ');
     WriteLn('made.');
     WriteLn;

     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save band change report to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               SHOWMESSAGE('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }
   FileName := postform.BandChanFNEdit.Text;

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         Exit;
      end;

   ReadLn(FileRead, TempString);

   if not OpenFileForWrite(FileWrite, FileName) then
      begin
         ShowMessage('Unable to open output file or device.');
         Exit;
      end;

   //    IF FileName = '' THEN ClrScr;

   QSONumber := 0;
   NumberBandChanges := 0;
   LastBandChangeQSO := -100;
   NumberTwoXmtrQSOs := 0;

   //  Write(QSONumber);
   FirstQSO := true;

   repeat
      repeat
         ReadLn(FileRead, TempString);
         Band := GetLogEntryBand(TempString);
         Mode := GetLogEntryMode(TempString);
      until (Band <> NoBand) or Eof(FileRead);

      if FirstQSO then
         begin
            LastBand := Band;
            LastMode := Mode;
            FirstQSO := False;
         end;

      inc(QSONumber);
      //        GoToXY (1, WhereY);
      //        ClrEol;
      //    Write(QSONumber);

      if (Band <> NoBand) then
         begin
            if (LastBand <> Band) or (LastMode <> Mode) then
               begin
                  inc(NumberBandChanges);
                  Write(FileWrite, NumberBandChanges: 4, '. ',
                     GetLogEntryQSONumber(TempString): 5,
                     '  Band change from ',
                     BandString[LastBand], ModeString[LastMode], ' to ',
                     BandString[Band], ModeString[Mode], ' at ',
                     GetLogEntryTimeString(TempString), '.');

                  if LastBandChangeQSO + 1 = QSONumber then
                     begin
                        Write(FileWrite, '  *');
                        inc(NumberTwoXmtrQSOs);
                     end;

                  WriteLn(FileWrite);
                  LastBandChangeQSO := QSONumber;
               end;

            LastBand := Band;
            LastMode := Mode;
         end;

   until Eof(FileRead);

   if NumberTwoXmtrQSOs > 0 then
      begin
         //    WriteLn(FileWrite);
         WriteLn(FileWrite, 'There were ' + IntToStr(NumberTwoXmtrQSOs) + ' second radio QSOs made.');
      end;

   Close(FileRead);
   Close(FileWrite);
   view(FileName);
   //    GoToXY (1, WhereY);
 //    ClrEol;

 //  WriteLn;
 //    IF FileName = '' THEN WaitForKeyPressed;
end;

procedure ContinentReport;

type
   ContListType = (USA, Canada, na, sa, eu, af, ASI, Japan, OC, UK);

const
   MaxUnknownCalls                 = 10;

var
   Band                            : BandType;
   ID, Call                        : CallString;
   Continent                       : ContinentType;
   Country                         : integer;
   CallAddress, QSONumber, AllBandTotal: integer;
   Destination                     : Char;
   ContTotals                      : array[BandType, ContListType] of integer;
   Cont, ListContinent             : ContListType;
   QSOTotals                       : array[BandType] of integer;
   UnknownCalls                    : array[BandType, 0..MaxUnknownCalls - 1] of CallString;
   Title, FileName                 : Str80;
   TempString                      : string;
   DoingDupingFile                 : boolean;
   FileRead, FileWrite             : Text;

begin
   {
   //    ClrScr;
   //    TextColor (Yellow);
     WriteLnCenter('CONTINENT LIST PROCEDURE');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will generate a report showing the distribution of your');
     WriteLn('contacts by continent.');
     WriteLn;
   }
   for Band := Band160 to All do
      begin
         QSOTotals[Band] := 0;
         for Cont := USA to UK do ContTotals[Band, Cont] := 0;
      end;

   FileName := postform.ContDistEdit.Text;
   {
     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save continent report to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               SHOWMESSAGE('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }
   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         Exit;
      end;

   ReadLn(FileRead, TempString);

   if TempString = 'DUPE' then
      begin
         DoingDupingFile := true;
         ReadLn(FileRead, Title);
      end
   else
      begin
         DoingDupingFile := False;
         Close(FileRead);
         OpenFileForRead(FileRead, LogFileName);
         Title := postform.ContDistTitEdit.Text; //GetResponse('Enter continent report title : ');
      end;

   if not OpenFileForWrite(FileWrite, FileName) then
      begin
         ShowMessage('Unable to open output file or device.');
         Exit;
      end;

   //    IF FileName = '' THEN ClrScr;

   QSONumber := 0;
   //  Write(QSONumber);

   repeat
      repeat
         ReadLn(FileRead, TempString);
         Band := GetLogEntryBand(TempString);
      until (Band <> NoBand) or Eof(FileRead) or DoingDupingFile;

      inc(QSONumber);
      //        GoToXY (1, WhereY);
      //        ClrEol;
      //    Write(QSONumber);

      if (Band <> NoBand) or DoingDupingFile then
         if not ((StringHas(TempString, '*DUPE*')) or (StringHas(TempString, '*ZERO*'))) then
            begin
               if DoingDupingFile then
                  begin
                     Call := TempString;
                     Band := Band160;
                  end
               else
                  begin
                     inc(QSOTotals[Band]);
                     ExpandTabs(TempString);
                     Call := StandardCallFormat(UpperCase(GetLogEntryCall(TempString)), true);
                  end;

               Continent := CountryTable.GetContinent(Call);
               Country := CountryTable.GetCountry(Call, true);

               ID := CountryTable.GetCountryID(Country);

               if ID = 'K' then
                  ListContinent := USA
               else
                  if ID = 'VE' then
                     ListContinent := Canada
                  else
                     if ID = 'JA' then
                        ListContinent := Japan
                     else
                        case Continent of
                           NorthAmerica: ListContinent := na;
                           SouthAmerica: ListContinent := sa;
                           Europe: ListContinent := eu;
                           Africa: ListContinent := af;
                           Asia: ListContinent := ASI;
                           Oceania: ListContinent := OC;
                           else ListContinent := UK;
                        end;

               inc(ContTotals[Band, ListContinent]);

               if ListContinent = UK then
                  if ContTotals[Band, UK] <= MaxUnknownCalls then
                     UnknownCalls[Band, ContTotals[Band, UK] - 1] := Call;
            end;

   until Eof(FileRead);
   Close(FileRead);
   //    GoToXY (1, WhereY);
   //    ClrEol;

   WriteLn(FileWrite);
   WriteLn(FileWrite, '      Continent List  ', Title);
   WriteLn(FileWrite);

   if not DoingDupingFile then
      begin
         WriteLn(FileWrite, '                   160    80    40    20    15    10    30    17    12    ALL');
         WriteLn(FileWrite, '                   ---    --    --    --    --    --    --    --    --    ---');
      end;

   Write(FileWrite, '  USA calls   = ');

   if not DoingDupingFile then
      begin
         AllBandTotal := 0;

         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, USA]: 6);
               AllBandTotal := ContTotals[Band, USA] + AllBandTotal;
            end;

         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, USA]: 6);

   Write(FileWrite, '  VE calls    = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, Canada]: 6);
               AllBandTotal := ContTotals[Band, Canada] + AllBandTotal;
            end;

         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, Canada]: 6);

   Write(FileWrite, '  N.A. calls  = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, na]: 6);
               AllBandTotal := ContTotals[Band, na] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, na]: 6);

   Write(FileWrite, '  S.A. calls  = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, sa]: 6);
               AllBandTotal := ContTotals[Band, sa] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, sa]: 6);

   Write(FileWrite, '  Euro calls  = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, eu]: 6);
               AllBandTotal := ContTotals[Band, eu] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, eu]: 6);

   Write(FileWrite, '  Afrc calls  = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, af]: 6);
               AllBandTotal := ContTotals[Band, af] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, af]: 6);

   Write(FileWrite, '  Asia calls  = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, ASI]: 6);
               AllBandTotal := ContTotals[Band, ASI] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band, ASI]: 6);

   Write(FileWrite, '  JA calls    = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, Japan]: 6);
               AllBandTotal := ContTotals[Band, Japan] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, Japan]: 6);

   Write(FileWrite, '  Ocen calls  = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, OC]: 6);
               AllBandTotal := ContTotals[Band, OC] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band, OC]: 6);

   WriteLn(FileWrite, '');

   Write(FileWrite, '  Unknowns    = ');
   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, ContTotals[Band, UK]: 6);
               AllBandTotal := ContTotals[Band, UK] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, ContTotals[Band160, UK]: 6);

   WriteLn(FileWrite, '');

   Write(FileWrite, '  Total calls = ');

   if not DoingDupingFile then
      begin
         AllBandTotal := 0;
         for Band := Band160 to Band12 do
            begin
               Write(FileWrite, QSOTotals[Band]: 6);
               AllBandTotal := QSOTotals[Band] + AllBandTotal;
            end;
         WriteLn(FileWrite, AllBandTotal: 7);
      end
   else
      WriteLn(FileWrite, QSOTotals[Band160]: 6);

   WriteLn(FileWrite);

   for Band := Band160 to Band12 do
      if ContTotals[Band, UK] > 0 then
         begin
            TempString := BandString[Band];
            GetRidOfPrecedingSpaces(TempString);
            if not DoingDupingFile then
               Write(FileWrite, 'Unknowns on ', TempString, ' = ')
            else
               Write(FileWrite, 'Unknowns = ');

            for CallAddress := 0 to ContTotals[Band, UK] - 1 do
               if CallAddress < MaxUnknownCalls then
                  Write(FileWrite, UnknownCalls[Band, CallAddress], ' ');

            WriteLn(FileWrite);
         end;

   Close(FileWrite);
   view(FileName);
   //  WriteLn;
 //    IF FileName = '' THEN WaitForKeyPressed;
end;

procedure ViewNotes;

var
   Destination                     : Char;
   FileName, FileString            : Str80;
   FileRead, FileWrite             : Text;

begin
   {
   //    ClrScr;
   //    TextColor (Yellow);
     WriteLnCenter('VIEW NOTES PROCEDURE');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will generate a report showing all the note entries in your ');
     WriteLn('log.  Notes start with a semicolon and are entered with the Control-N key in');
     WriteLn('the logging program.  These notes will only appear in your raw log.  When you');
     WriteLn('create your final log using the Create band and/or mode logs command from the');
     WriteLn('Log menu, the notes will not be copied.');
     WriteLn;

     repeat
       Destination := UpCase(GetKey('Output notes to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save notes to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               ShowMessage('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }

   FileName := postform.NoteFNEdit.Text;

   if FileName = UpperCase(LogFileName) then
      begin
         ShowMessage('Output file must be different than active log file!!');
         Exit;
      end;

   if FileName = '' then Exit;

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         Exit;
      end;

   if not OpenFileForWrite(FileWrite, FileName) then
      begin
         ShowMessage('Unable to open output file or device.');
         Exit;
      end;

   //    IF FileName = '' THEN ClrScr;

   while not Eof(FileRead) do
      begin
         ReadLn(FileRead, FileString);
         if Copy(FileString, 1, 1) = ';' then
            WriteLn(FileWrite, FileString);
      end;

   Close(FileRead);
   Close(FileWrite);
   view(FileName);
end;

procedure DupeSheet;

{ Need to enhance this so it will do it by band and/or mode }

var
   Command, Destination            : Char;
   TempString, TitleMaster, FileName: Str80;
   Mode                            : ModeType;
   Band                            : BandType;

begin
   {
   //    ClrScr;
   //    TextColor (Yellow);
     WriteLnCenter('DUPE SHEET PROCEDURE');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will generate dupesheets from the active log file.  You can');
     WriteLn('create just one dupesheet that has all your contacts in it, or make multiple');
     WriteLn('sheets for different bands and/or modes.  The sheets can be output to a file,');
     WriteLn('the printer or to the screen.  You will be asked if you want the calls sorted');
     WriteLn('by CQ countries.  If you answer no, they will be sorted into ARRL countries.');
     WriteLn('Callsigns which the program isn''t sure what country they are in are listed at');
     WriteLn('the end of the dupesheet.  If you are printing separate sheets for each band ');
     WriteLn('or mode, you will be given the chance to print all the dupesheets or just one');
     WriteLn('for a specific band or mode.');

     WriteLn;
   }
   DetermineQSOByBandAndQSOByMode;

   if not QSOByBandAndModeDetermined then Exit;
   {
     WriteLn;
   //    TextColor (Cyan);
     WriteLn;
     WriteLn('The dupesheet title will be printed at the top of each page.  It will have');
     WriteLn('the band and mode appended to it.  Typically you would enter the name of the');
     WriteLn('contest with a couple of spaces, followed by the callsign.  If you are saving');
     WriteLn('dupesheets to files, you will find the files with .DS extensions');
     WriteLn;
   }
   TitleMaster := postform.DupTitEdit.Text; // GetResponse('Enter dupsheet title : ');

   {  repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': FileName := '';
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }
   FileName := postform.DupFileEdit.Text;
   {
     repeat
       Key := UpCase(GetKey('Use (A)RRL or (C)QWW countries? (A,C) : '));
       if Key = EscapeKey then exit;
     until (Key = 'A') or (Key = 'C');
     WriteLn;

     case Key of
       'A': CountryTable.CountryMode := ARRLCountryMode;
       'C': CountryTable.CountryMode := CQCountryMode;
     end;
   }

   if postform.arrl_or_cqww.ItemIndex = 0 then CountryTable.CountryMode := ARRLCountryMode else CountryTable.CountryMode := CQCountryMode;
   DetermineLogTotals;

   if QSOByBand then
      begin
         repeat
            Command := UpCase(GetKey('Print sheets for (A)ll the bands or (S)ingle band? (A/S) : '));
            if Command = EscapeKey then Exit;
         until (Command = 'A') or (Command = 'S');
         WriteLn;

         if postform.all_or_single.ItemIndex = 0 then
            //    if Command = 'A' then
            begin
               StartBand := Band160;
               StopBand := BandLight;
            end
         else
            begin
               StartBand := NoBand;
               TempString := GetResponse('Band (160 - 2, 222, 432, 902, 1296, 2304, 3GH, 5GH, 10G, 24G or LGT) : ');

               if TempString = '' then Exit;

               if TempString = '160' then StartBand := Band160;
               if TempString = '80' then StartBand := Band80;
               if TempString = '40' then StartBand := Band40;
               if TempString = '20' then StartBand := Band20;
               if TempString = '15' then StartBand := Band15;
               if TempString = '10' then StartBand := Band10;
               if TempString = '6' then StartBand := Band6;
               if TempString = '2' then StartBand := Band2;
               if TempString = '222' then StartBand := Band222;
               if TempString = '432' then StartBand := Band432;
               if TempString = '902' then StartBand := Band902;
               if TempString = '1296' then StartBand := Band1296;
               if TempString = '2304' then StartBand := Band2304;
               if TempString = '3GH' then StartBand := Band3456;
               if TempString = '5GH' then StartBand := Band5760;
               if TempString = '10G' then StartBand := Band10G;
               if TempString = '24G' then StartBand := Band24G;
               if TempString = 'LGT' then StartBand := BandLight;

               if StartBand = NoBand then Exit;
               StopBand := StartBand;
            end;
      end
   else
      begin
         StartBand := All;
         StopBand := All;
      end;

   if QSOByMode then
      begin
         {    repeat
               Command := UpCase(GetKey('Print sheets for (B)oth modes (S)ingle mode? (B/S) : '));
               if Command = EscapeKey then exit;
             until (Command = 'B') or (Command = 'S');
          WriteLn;
         }

         if postform.both_or_sing.ItemIndex <> 0 then
            begin
               StartMode := NoMode;
               TempString := postform.DSModeCB.Text; //UpperCase(GetResponse('Enter mode to print sheet for (CW or SSB) : '));

               if TempString = '' then Exit;

               if TempString = 'CW' then
                  begin
                     StartMode := cw;
                     StopMode := cw;
                  end;

               if TempString = 'DIG' then
                  begin
                     StartMode := Digital;
                     StopMode := Digital;
                  end;

               if (TempString = 'SSB') or (TempString = 'PHONE') then
                  begin
                     StartMode := Phone;
                     StopMode := Phone;
                  end;

               if StartMode = NoMode then Exit;
            end;
      end
   else
      begin
         StartMode := Both;
         StopMode := Both;
      end;

   for Mode := StartMode to StopMode do
      for Band := StartBand to StopBand do
         if LogTotals[Band, Mode] > 0 then
            begin
               if PutLogFileIntoCallBuffer(Mode, Band) then
                  begin
                     if Band <> All then
                        DupeSheetTitle := TitleMaster + '  ' + BandString[Band]
                     else
                        DupeSheetTitle := TitleMaster + '  All Bands';

                     case Mode of
                        cw: DupeSheetTitle := DupeSheetTitle + ' CW';
                        Phone: DupeSheetTitle := DupeSheetTitle + ' Phone';
                        Both: DupeSheetTitle := DupeSheetTitle + ' Both modes';
                     end;

                     if StringHas(DupeSheetTitle, 'BTH') or StringHas(DupeSheetTitle, 'ALL') then
                        begin
                           Delete(TempString, length(TempString) - 2, 3);
                           TempString := TempString + ' Meters';
                        end;

                     if Destination = 'F' then
                        begin
                           FileName := DupingFileName(Band, Mode) + '.DS';
                           WriteLn('Writing to dupesheet file ', FileName, '...');
                        end;

                     MakeDupeSheet(FileName, DupeSheetTitle);
                     DisposeCallBuffer;

                     if Destination = 'F' then
                        begin
                        end;
                  end
               else
                  begin
                     ShowMessage('PutLogInFileBuffer did not work!!');
                     Exit;
                  end;
            end;
   view(FileName);
end;

procedure MultLogEntries;

var
   FileRead, FileWrite             : Text;
   MultString, FileName, TempString: Str80;
   FileString                      : string;
   Destination, BandChar, ModeChar, AlphabetizeChar: Char;
   MultByBand, MultByMode          : boolean;
   SelectedBand, Band              : BandType;
   SelectedMode, Mode              : ModeType;
   NumberMults, Index, NumberCallsToSort, BubbleCount: integer;
   temp, MultAddress, NumberLinesPrinted: integer;
   SortPointer                     : array[0..MaximumLogEntries] of integer;

begin
   //    ClrScr;
   //    TextColor (Yellow);
   WriteLnCenter('MULTIPLIER LOG ENTRY REPORT');
   WriteLn;
   //    TextColor (Cyan);
   WriteLn('This procedure will show the QSOs which are multipliers (as LOG.DAT entries');
   WriteLn('You can have all the bands reported together or generate a report for a single');
   WriteLn('band or mode.  You can leave them in log order or have them alphabetized if ');
   WriteLn('you wish.  This procedure will only show multipliers that are marked in your');
   WriteLn('log with an entry in the multiplier column.  You can use the Multiplier Check');
   WriteLn('procedure under the Log menu to verify the correct country multipliers are');
   WriteLn('marked in your log based upon the callsign of each contact.');
   WriteLn;

   repeat
      BandChar := UpCase(GetKey('(A)ll the bands together or select a (S)ingle band (A/S) : '));
   until (BandChar = EscapeKey) or (BandChar = 'A') or (BandChar = 'S');
   WriteLn;
   if BandChar = EscapeKey then Exit;
   WriteLn;

   NumberMults := 0;

   if BandChar = 'S' then
      begin
         SelectedBand := NoBand;
         TempString := GetResponse('Band (160 - 2, 222, 432, 902, 1296, 2304, 3GH, 5GH, 10G, 24G or LGT) : ');
         if TempString = '160' then SelectedBand := Band160;
         if TempString = '80' then SelectedBand := Band80;
         if TempString = '40' then SelectedBand := Band40;
         if TempString = '20' then SelectedBand := Band20;
         if TempString = '15' then SelectedBand := Band15;
         if TempString = '10' then SelectedBand := Band10;
         if TempString = '6' then SelectedBand := Band6;
         if TempString = '2' then SelectedBand := Band2;

         if TempString = '222' then SelectedBand := Band222;
         if TempString = '432' then SelectedBand := Band432;
         if TempString = '902' then SelectedBand := Band902;
         if TempString = '1296' then SelectedBand := Band1296;
         if TempString = '2304' then SelectedBand := Band2304;

         if TempString = '3GH' then StartBand := Band3456;
         if TempString = '5GH' then StartBand := Band5760;
         if TempString = '10G' then StartBand := Band10G;
         if TempString = '24G' then StartBand := Band24G;
         if TempString = 'LGT' then StartBand := BandLight;

         if SelectedBand = NoBand then Exit;
      end
   else
      SelectedBand := All;

   repeat
      ModeChar := UpCase(GetKey('(B)oth modes together or select a (S)ingle mode (B/S) : '));
   until (ModeChar = EscapeKey) or (ModeChar = 'B') or (ModeChar = 'S');
   WriteLn;

   if ModeChar = EscapeKey then Exit;

   if ModeChar = 'S' then
      begin
         SelectedMode := NoMode;
         repeat
            TempString := UpperCase(GetResponse('Enter desired mode (CW or SSB) : '));
            if TempString = '' then Exit;
         until (TempString = 'CW') or (TempString = 'SSB');

         if TempString = 'CW' then SelectedMode := cw;
         if TempString = 'SSB' then SelectedMode := Phone;
      end
   else
      SelectedMode := Both;

   NumberMults := 0;

   repeat
      Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
      case Destination of
         'F':
            begin
               WriteLn;
               FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

               if FileName = UpperCase(LogFileName) then
                  begin
                     ShowMessage('Output file must be different than active log file!!');
                     //                     WaitForKeyPressed;
                     Exit;
                  end;

               if FileName = '' then Exit;
            end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: Exit;
      end;
   until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
   WriteLn;

   repeat
      AlphabetizeChar := UpCase(GetKey('Alphabetical or Log order? (A/L) : '));
   until (AlphabetizeChar = 'A') or (AlphabetizeChar = 'L') or (AlphabetizeChar = EscapeKey);
   WriteLn;

   if AlphabetizeChar = EscapeKey then Exit;
   WriteLn;

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         //        WaitForKeyPressed;
         Exit;
      end;

   if not OpenFileForWrite(FileWrite, FileName) then
      begin
         ShowMessage('Unable to open output file.');
         //        WaitForKeyPressed;
         Exit;
      end;

   //    IF FileName = '' THEN ClrScr;
   NumberLinesPrinted := 0;

   New(MultiplierArray);
   //    GoToXY (1, WhereY);
   //    TextColor (Cyan);
   //    ClrEol;
   Write('Searching log file for multipliers...');

   repeat
      repeat
         ReadLn(FileRead, FileString);
         Band := GetLogEntryBand(FileString);
      until (Band <> NoBand) or Eof(FileRead);

      if (Band <> NoBand) and
         ((Band = SelectedBand) or (SelectedBand = All)) and
         not (StringHas(FileString, '*DUPE*') or StringHas(FileString, '*ZERO*')) then
         begin
            Mode := GetLogEntryMode(FileString);

            if (Mode <> NoMode) and ((Mode = SelectedMode) or (SelectedMode = Both)) then
               begin
                  ExpandTabs(FileString);
                  MultString := GetLogEntryMultString(FileString);
                  if MultString <> '' then
                     begin
                        while StringHas(MultString, ' ') do
                           begin
                              TempString := PrecedingString(MultString, ' ');
                              MultiplierArray^[NumberMults].LogEntry := FileString;
                              MultiplierArray^[NumberMults].Mult := TempString;
                              inc(NumberMults);
                              MultString := PostcedingString(MultString, ' ');
                           end;

                        MultiplierArray^[NumberMults].LogEntry := FileString;
                        MultiplierArray^[NumberMults].Mult := MultString;
                        inc(NumberMults);
                     end;
               end;
         end;

   until Eof(FileRead);
   Close(FileRead);

   //    GoToXY (1, WhereY);
   //    ClrEol;

   if AlphabetizeChar = 'A' then
      begin
         Write('Sorting multipliers...');

         if NumberMults > 1 then
            begin
               NumberCallsToSort := NumberMults;

               for MultAddress := 0 to NumberCallsToSort - 1 do
                  SortPointer[MultAddress] := MultAddress;

               Index := NumberCallsToSort - 2;

               for BubbleCount := 1 to NumberCallsToSort - 1 do
                  begin
                     for MultAddress := 0 to Index do
                        if MultiplierArray^[SortPointer[MultAddress]].Mult >
                           MultiplierArray^[SortPointer[MultAddress + 1]].Mult then
                           begin
                              temp := SortPointer[MultAddress + 1];
                              SortPointer[MultAddress + 1] := SortPointer[MultAddress];
                              SortPointer[MultAddress] := temp;
                           end;

                     Index := Index - 1;
                  end;
            end
         else
            SortPointer[0] := 0;

         //        GoToXY (1, WhereY);
         //        ClrEol;

         for MultAddress := 0 to NumberMults - 1 do
            begin
               WriteLn(FileWrite, MultiplierArray^[SortPointer[MultAddress]].LogEntry);
               inc(NumberLinesPrinted);
               if NumberLinesPrinted >= 50 then
                  begin
                     NumberLinesPrinted := 0;
                     WriteLn(FileWrite, ' ');
                  end;
            end;
      end
   else
      begin
         for MultAddress := 0 to NumberMults - 1 do
            begin
               WriteLn(FileWrite, MultiplierArray^[MultAddress].LogEntry);
               inc(NumberLinesPrinted);
               if NumberLinesPrinted >= 50 then
                  begin
                     NumberLinesPrinted := 0;
                     WriteLn(FileWrite, ' ');
                  end;
            end;
      end;

   Close(FileWrite);
   Dispose(MultiplierArray);
   //    IF FileName = '' THEN WaitForKeyPressed;
end;

procedure QSODistribution;

label
   QTHFound;

type
   ListRec = record
      QTH: CallString;
      Num: integer;
   end;

var
   NumberQSOs, Count, CenterSpaces, NumberQTHs, Space, Address: integer;
   HiTotal, HiAddress, QSONumber   : integer;
   Title, FileName, QTHString      : Str80;
   FileString, ExchangeString      : string;
   Band                            : BandType;
   Mode                            : ModeType;
   Destination                     : Char;
   FileRead, FileWrite             : Text;
   List                            : array[0..300] of ListRec;

begin
   {
   //    ClrScr;
   //    TextColor (Yellow);
     WriteLnCenter('QSO DISTRIBUTION REPORT');
   //    TextColor (Cyan);
     WriteLn;
     WriteLn('This procedure will generate a report showing the number of contacts made in');
     WriteLn('each domestic QTH or zone (whichever is the last thing in the exchange field.');
     WriteLn;

     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save report to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               SHOWMESSAGE('Output file must be different than active log file!!');
   //                     FileString ('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               Dispose(RateSheet);
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';

         EscapeKey:
           exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }
   FileName := postform.QSODisEdit.Text;
   if FileName = UpperCase(LogFileName) then
      begin
         ShowMessage('Output file must be different than active log file!!');
         Dispose(RateSheet);
         Exit;
      end;

   if FileName = '' then Exit;

   begin
      Title := postform.QSOTitEdit.Text;
      CenterSpaces := 40 - (length(Title) div 2);
      if CenterSpaces > 0 then
         for Space := 1 to CenterSpaces do
            Title := ' ' + Title;
   end;

   NumberQTHs := 0;
   NumberQSOs := 0;

   if not OpenFileForRead(FileRead, LogFileName) then Exit;

   //  repeat
   while not Eof(FileRead) do
      begin
         repeat
            ReadLn(FileRead, FileString);
            Band := GetLogEntryBand(FileString);
         until (Band <> NoBand) or Eof(FileRead);
         if Eof(FileRead) then goto QTHFound;

         inc(NumberQSOs);
         if Band <> NoBand then
            if not ((StringHas(FileString, 'DUPE')) or (StringHas(FileString, 'ZERO'))) then
               begin
                  ExpandTabs(FileString);
                  ExchangeString := GetLogEntryExchangeString(FileString);
                  QTHString := RemoveLastString(ExchangeString);

                  if NumberQTHs > 0 then
                     for Address := 0 to NumberQTHs - 1 do
                        if List[Address].QTH = QTHString then
                           begin
                              inc(List[Address].Num);
                              goto QTHFound;
                           end;

                  List[NumberQTHs].QTH := QTHString;
                  List[NumberQTHs].Num := 1;
                  inc(NumberQTHs);
                  {        if NumberQSOs = 397 then
                          begin
                  //          SHOWMESSAGE(inttostr(NumberQSOs));
                            asm
                            nop
                            end;
                          end;
                         }QTHFound:
               end;
         {try
         if  eof(FileRead)then asm
         nop
         end;
           except SHOWMESSAGE(inttostr(NumberQSOs));end;
         }
         //  until Eof(FileRead);
      end;

   Close(FileRead);

   //    GoToXY (1, WhereY);
   //    ClrEol;
   //  postform.('There were '+ NumberQSOs+ ' QSOs found.');

   if NumberQTHs = 0 then
      begin
         ShowMessage('No QTHs found.');
         Exit;
      end;

   if OpenFileForWrite(FileWrite, FileName) then

      if (Destination <> 'S') then
         begin
            WriteLn(FileWrite, Title);
            WriteLn(FileWrite);
         end;

   for Count := 1 to NumberQTHs do
      begin
         HiTotal := 0;

         for Address := 0 to NumberQTHs - 1 do
            if List[Address].Num > HiTotal then
               begin
                  HiTotal := List[Address].Num;
                  HiAddress := Address;
               end;

         WriteLn(FileWrite, Count: 4, '. ', List[HiAddress].QTH: 12, List[HiAddress].Num: 5);
         List[HiAddress].Num := 0;
      end;

   Close(FileWrite);
   view(FileName);
end;

procedure RateReport;

var
   QSONumber, FirstHourOfTheContest, LastHourOfTheContest, Hour: integer;
   NumberDifferentBands, NumberHoursWithContacts: integer;
   Day, LastDay                    : integer;
   FileName, DayString, Title      : Str80;
   TempString                      : string;
   Band                            : BandType;
   Mode                            : ModeType;
   CenterSpaces, Space, TotalContacts: integer;
   UnderLineString                 : string[150];
   QSOTotals                       : array[BandType, ModeType] of integer;
   Destination                     : Char;
   FileRead, FileWrite             : Text;

begin
   New(RateSheet);

   for Day := 1 to 3 do
      for Hour := 0 to 23 do
         for Band := Band160 to All do
            for Mode := cw to Both do
               RateSheet^[Day, Hour, Band, Mode] := 0;

   //    ClrScr;
   //    TextColor (Yellow);
   {  WriteLnCenter('RATE SHEET REPORT');
   //    TextColor (Cyan);
     WriteLn;
     WriteLn('This procedure will generate a rate sheet for the active log.  This sheet   ');
     WriteLn('will show the band by band, hour by hour statistics.');
     WriteLn;
     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save rate report to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               SHOWMESSAGE('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               Dispose(RateSheet);
               exit;
             end;

             if FileName = '' then
             begin
               Dispose(RateSheet);
               exit;
             end;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey:
           begin
             Dispose(RateSheet);
             exit;
           end;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }

   FileName := postform.RREdit.Text;
   if FileName = UpperCase(LogFileName) then
      begin
         ShowMessage('Output file must be different than active log file!!');
         Dispose(RateSheet);
         Exit;
      end;

   if FileName = '' then
      begin
         Dispose(RateSheet);
         Exit;
      end;

   //  if (Destination <> 'S') then

   Title := postform.RRTitleEdit.Text;
   CenterSpaces := 40 - (length(Title) div 2);
   if CenterSpaces > 0 then
      for Space := 1 to CenterSpaces do
         Title := ' ' + Title;

   DetermineLogTotals;

   NumberDifferentBands := 0;

   for Band := Band160 to BandLight do
      for Mode := cw to Phone do
         begin
            if LogTotals[Band, Mode] > 0 then
               inc(NumberDifferentBands);
            QSOTotals[Band, Mode] := 0;
         end;

   if NumberDifferentBands = 0 then Exit;

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         Dispose(RateSheet);
         Exit;
      end;

   if not OpenFileForWrite(FileWrite, FileName) then
      begin
         ShowMessage('Unable to open output file or device.');
         Dispose(RateSheet);
         Exit;
      end;

   //    IF FileName = '' THEN ClrScr;

   if Destination <> 'S' then
      begin
         WriteLn(FileWrite);
         WriteLn(FileWrite, Title);
         WriteLn(FileWrite);
      end;

   Day := 0;

   QSONumber := 0;
   //  Write(QSONumber);

   repeat
      repeat
         ReadLn(FileRead, TempString);
         Band := GetLogEntryBand(TempString);
      until (Band <> NoBand) or Eof(FileRead);

      if Band <> NoBand then
         if not ((StringHas(TempString, '*DUPE*')) or (StringHas(TempString, '*ZERO*'))) then
            begin
               ExpandTabs(TempString);
               Mode := GetLogEntryMode(TempString);
               LastHourOfTheContest := GetLogEntryHour(TempString);
               inc(QSOTotals[Band, Mode]);

               case Day of
                  0:
                     begin
                        DayString := GetLogEntryDateString(TempString);
                        FirstHourOfTheContest := GetLogEntryHour(TempString);
                        Day := 1;
                     end;

                  1:
                     if DayString <> GetLogEntryDateString(TempString) then
                        begin
                           Day := 2;
                           DayString := GetLogEntryDateString(TempString);
                        end;

                  2:
                     if DayString <> GetLogEntryDateString(TempString) then
                        Day := 3;
               end;

               Hour := GetLogEntryHour(TempString);

               inc(RateSheet^[Day, Hour, Band, Mode]);
               inc(RateSheet^[Day, Hour, All, Both]);

               inc(QSONumber);
               //            GoToXY (1, WhereY);
               //        Write(QSONumber);
            end;

   until Eof(FileRead);
   Close(FileRead);

   //    GoToXY (1, WhereY);
   //    ClrEol;

   if QSONumber = 0 then Exit;
   TotalContacts := 0;

   LastDay := Day;

   UnderLineString := '';

   WriteLn(FileWrite);
   Write(FileWrite, '  HOUR  ');
   UnderLineString := '  ----  ';

   for Band := Band160 to BandLight do
      for Mode := cw to Phone do
         if LogTotals[Band, Mode] > 0 then
            begin
               TempString := BandString[Band] + ModeString[Mode];
               case length(TempString) of
                  4: TempString := ' ' + TempString + ' ';
                  5: TempString := ' ' + TempString;
               end;
               Write(FileWrite, TempString, '  ');
               UnderLineString := UnderLineString + '------  ';
            end;

   WriteLn(FileWrite, ' TOTAL   ACCUM');
   UnderLineString := UnderLineString + ' -----   -----';
   WriteLn(FileWrite, UnderLineString);

   for Day := 1 to LastDay do
      for Hour := 0 to 23 do
         if (((Day = 1) and (Hour >= FirstHourOfTheContest)) or (Day > 1)) and
            (((Day = LastDay) and (Hour <= LastHourOfTheContest)) or (Day < LastDay)) then
            begin
               Write(FileWrite, Hour: 5);
               for Band := Band160 to BandLight do
                  for Mode := cw to Phone do
                     if LogTotals[Band, Mode] > 0 then
                        Write(FileWrite, RateSheet^[Day, Hour, Band, Mode]: 8);
               Write(FileWrite, RateSheet^[Day, Hour, All, Both]: 8);
               TotalContacts := TotalContacts + RateSheet^[Day, Hour, All, Both];
               WriteLn(FileWrite, TotalContacts: 8);
               if (Hour = 23) and (Day <> LastDay) then WriteLn(FileWrite);
            end;

   WriteLn(FileWrite);
   Write(FileWrite, '  TOTAL');

   for Band := Band160 to BandLight do
      for Mode := cw to Phone do
         if LogTotals[Band, Mode] > 0 then
            Write(FileWrite, QSOTotals[Band, Mode]: 6, '  ');

   Write(FileWrite, ControlL);
   Dispose(RateSheet);
   Close(FileWrite);
   view(FileName);
end;

procedure ShowDupeReport;

var
   FileRead, FileWrite             : Text;
   FileString, FileName            : Str80;
   Destination                     : Char;

begin
   {
   //    ClrScr;
   //    TextColor (Yellow);
     WriteLnCenter('SHOW DUPLICATE QSO PROCEDURE');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will list the duplicate contacts that appear in your log.');
     WriteLn('To make sure all your dupes are marked in your log, you need to execute the');
     WriteLn('DUPE LOG procedure under LOG PROCEDURE menu before executing this procedure.');
     WriteLn;

     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save dupe report to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               SHOWMESSAGE('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }
   FileName := postform.DupRepFNEdit.Text;

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');

         Exit;
      end;

   if OpenFileForWrite(FileWrite, FileName) then
      begin
         while not Eof(FileRead) do
            begin
               ReadLn(FileRead, FileString);
               if StringHas(FileString, 'DUPE') then
                  WriteLn(FileWrite, FileString);
            end;
         Close(FileWrite);
      end
   else
      begin
         ShowMessage('Unable to open output file or device.');
         Close(FileRead);
         Exit;
      end;

   Close(FileRead);
   view(FileName);
end;

procedure WPXPrefixReport;

var
   FileRead                        : Text;
   FileString, FileName            : Str80;
   PrefixMult                      : Str20;
   Band                            : BandType;
   QSONumber                       : integer;
   Destination                     : Char;

begin
   //    ClrScr;
   //    TextColor (Yellow);
   {  WriteLnCenter('WPX PREFIX DUPESHEET PROCEDURE');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will generate a dupe sheet showing the prefix multipliers you');
     WriteLn('have worked.');
     WriteLn;

     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save WPX dupesheet to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               ShowMessage('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
     Title := GetResponse('Enter report title : ');
   }
   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         Exit;
      end;

   FileName := postform.WPXFNEdit.Text;
   Title := postform.WPXTitEdit.Text;

   if FileName = UpperCase(LogFileName) then
      begin
         ShowMessage('Output file must be different than active log file!!');
         Exit;
      end;

   if FileName = '' then Exit;

   DisposeCallBuffer;

   QSONumber := 0;
   //  Write(QSONumber);

   while not Eof(FileRead) do
      begin
         ReadLn(FileRead, FileString);
         Band := GetLogEntryBand(FileString);

         if Band <> NoBand then
            begin
               PrefixMult := GetLogEntryMultString(FileString);
               if PrefixMult <> '' then
                  begin
                     PutCall(NumberBufferCalls, PrefixMult);
                     inc(NumberBufferCalls);
                  end;

               inc(QSONumber);
            end;
      end;

   Close(FileRead);

   MakeDupeSheet(FileName, Title);
   view(FileName);
end;

procedure ZoneReport;

var
   FileRead, FileWrite             : Text;
   FileString, FileName            : Str80;
   CallString                      : Str20;
   ZoneString                      : string;
   Band                            : BandType;
   Mode                            : ModeType;
   Location                        : QTHRecord;
   CQZones                         : boolean;
   QSONumber, NumberBadZones, Zone, Result: integer;
   Destination, TempKey            : Char;

begin
   //    ClrScr;
   //    TextColor (Yellow);
   {  WriteLnCenter('POSSIBLE BAD ZONE REPORT PROCEDURE');
     WriteLn;
   //    TextColor (Cyan);
     WriteLn('This procedure will list any contacts where the received zone differs from');
     WriteLn('the default zone for the indicated callsign.  You should be aware that some');
     WriteLn('of the more active stations have "special" default zones.  For example, the');
     WriteLn('program knows that N4AR is in zone 4, not zone 5.');
     WriteLn;

     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));
       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save bad zone report to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               ShowMessage('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;
   }

   FileName := postform.BadZoneEdit.Text;

   if FileName = UpperCase(LogFileName) then
      begin
         ShowMessage('Output file must be different than active log file!!');
         Exit;
      end;

   if FileName = '' then Exit;

   NumberBadZones := 0;

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         Exit;
      end;

   if not OpenFileForWrite(FileWrite, FileName) then
      begin
         ShowMessage('Unable to open output file!!');
         Exit;
      end;

   CQZones := postform.UseCQCB.Checked; //Copy(UpperCase(GetResponse('Use CQ zones (no for ITU)? : ')), 1, 1) = 'Y';

   if CQZones then
      CountryTable.ZoneMode := CQZoneMode
   else
      CountryTable.ZoneMode := ITUZoneMode;

   //  WriteLn;
   QSONumber := 0;

   while not Eof(FileRead) do
      begin
         {    if OperatorEscape then
             begin
               Close(FileRead);
               WriteLn(FileWrite, 'Aborted by operator before end of file...');
               Close(FileWrite);
               exit;
             end;
         }
         ReadLn(FileRead, FileString);

         Band := GetLogEntryBand(FileString);

         if Band <> NoBand then
            begin
               inc(QSONumber);
               //            GoToXY (1, WhereY);
               //      Write(QSONumber);
               CallString := GetLogEntryCall(FileString);
               LocateCall(CallString, Location, true);
               ZoneString := GetLogEntryExchangeString(FileString);
               Delete(ZoneString, 1, 11);
               GetRidOfPostcedingSpaces(ZoneString);
               Val(ZoneString, Zone, Result);

               if Zone <> Location.Zone then
                  begin
                     WriteLn(FileWrite, FileString);
                     inc(NumberBadZones);
                  end;
            end;
      end;

   Close(FileRead);

   WriteLn(FileWrite);
   WriteLn(FileWrite, 'There were ', NumberBadZones, ' questionable zones found.');
   WriteLn(FileWrite);
   Close(FileWrite);
   view(FileName);
end;

procedure ListMultipliersWorked;

const
   MaxEntries                      = 2000;

type
   MultiplierTotalArrayType = array[BandType, ModeType] of integer;
   MultiplierTotalArrayPtr = ^MultiplierTotalArrayType;

   MultiplierListType = array[0..MaxEntries - 1] of string[6];
   MultiplierListPtr = ^MultiplierListType;

   MultiplierListMatrixType = array[BandType, ModeType] of MultiplierListPtr;

var
   Key, Destination                : Char;
   Band                            : BandType;
   Mode                            : ModeType;

   FileWrite, FileRead             : Text;
   TempString, FileName, FileString: string;
   MultString                      : string {20};

   MultiplierTotalArray            : MultiplierTotalArrayPtr;
   MultiplierListArray             : MultiplierListMatrixType;

   Range, Line, Entry, RequiredLines, Address, TotalLogQSOs: integer;
   Change, Sort                    : boolean;

begin
   {
   //    ClrScr;
   //    TextColor (Yellow);
     WriteLnCenter('LIST MULTIPLIERS WORKED');
     WriteLn;
   //    TextColor (Cyan);

     WriteLn('This procedure will create a report showing which multipliers were worked');
     WriteLn('in the contest.  All multiplier types will be shown.');

     WriteLn;
   }
   DetermineMultByBandAndMultByMode;
   if not MultByBandAndModeDetermined then Exit;

   //  if Header = '' then
   Header := postform.ContNameEdit.Text; //GetResponse('Enter contest name and callsign : ');
   FileName := postform.MultRepFNEdit.Text;
   {
     repeat
       Destination := UpCase(GetKey('Output to (F)ile, (P)rinter or (S)creen? : '));

       case Destination of
         'F': begin
             WriteLn;
             FileName := UpperCase(GetResponse('Enter filename to save multiplier report to : '));

             if FileName = UpperCase(LogFileName) then
             begin
               SHOWMESSAGE('Output file must be different than active log file!!');
   //                     WaitForKeyPressed;
               exit;
             end;

             if FileName = '' then exit;
           end;
         'S': FileName := '';
         'P': FileName := 'PRN';
         EscapeKey: exit;
       end;
     until (Destination = 'F') or (Destination = 'S') or (Destination = 'P');
     WriteLn;

     repeat
       Key := UpCase(GetKey('Do you want to sort the mults in alphabetical order? (Y/N) : '));
       if Key = EscapeKey then exit;
     until (Key = 'Y') or (Key = 'N');
     WriteLn;

    }Sort := postform.SortMultCB.Checked; //Key = 'Y';

   if not OpenFileForRead(FileRead, LogFileName) then
      begin
         ShowMessage(LogFileName + ' file not found!!');
         //        WaitForKeyPressed;
         Exit;
      end;

   //  postform.cm.Lines.Add('Searching log file for multipliers...');

   New(MultiplierTotalArray);

   { Make sure all totals are zero }

   for Band := Band160 to All do { Was StartBand to StopBand }
      for Mode := cw to Both do { Was StartMode to StopMode }
         MultiplierTotalArray^[Band, Mode] := 0;

   TotalLogQSOs := 0;

   repeat
      repeat
         ReadLn(FileRead, FileString);
         Band := GetLogEntryBand(FileString);
         Mode := GetLogEntryMode(FileString);
      until ((Band <> NoBand) and (Mode <> NoMode)) or Eof(FileRead);

      inc(TotalLogQSOs);

      if not MultByBand then Band := All;
      if not MultByMode then Mode := Both;

      if not (StringHas(FileString, '*DUPE*') or StringHas(FileString, '*ZERO*')) then
         begin
            ExpandTabs(FileString);
            MultString := GetLogEntryMultString(FileString);

            if MultString <> '' then
               while MultString <> '' do
                  begin
                     TempString := RemoveFirstString(MultString);

                     if MultiplierTotalArray^[Band, Mode] = 0 then
                        New(MultiplierListArray[Band, Mode]);

                     MultiplierListArray[Band, Mode]^[MultiplierTotalArray^[Band, Mode]] := TempString;

                     inc(MultiplierTotalArray^[Band, Mode]);
                  end;
         end;
   until Eof(FileRead);
   Close(FileRead);

   if TotalLogQSOS > 0 then
      begin
         OpenFileForWrite(FileWrite, FileName);

         WriteLn(FileWrite, Header);
         WriteLn(FileWrite);
         Lines := 2;

         for Band := Band160 to All do
            for Mode := cw to Both do
               if MultiplierTotalArray^[Band, Mode] > 0 then
                  begin

                     { Do sort if needed }

                     if Sort and (MultiplierTotalArray^[Band, Mode] > 1) then
                        begin
                           Range := MultiplierTotalArray^[Band, Mode] - 2;

                           repeat
                              Change := False;

                              for Address := 0 to Range do
                                 if MultiplierListArray[Band, Mode]^[Address] >
                                    MultiplierListArray[Band, Mode]^[Address + 1] then
                                    begin
                                       TempString := MultiplierListArray[Band, Mode]^[Address];
                                       MultiplierListArray[Band, Mode]^[Address] :=
                                          MultiplierListArray[Band, Mode]^[Address + 1];
                                       MultiplierListArray[Band, Mode]^[Address + 1] := TempString;
                                       Change := true;
                                    end;

                              Dec(Range);
                           until (not Change) or (Range < 0);
                        end;

                     { Compute number of lines needed }

                     RequiredLines := ((MultiplierTotalArray^[Band, Mode] - 1) div 10) + 1;

                     if RequiredLines + Lines > 55 then
                        if Destination <> 'S' then
                           begin
                              WriteLn(FileWrite, ' ');
                              WriteLn(FileWrite, Header);
                              WriteLn(FileWrite);
                              Lines := 2;
                           end;

                     { Write band/mode header }

                     WriteLn(FileWrite, BandString[Band], ModeString[Mode]);

                     for Line := 0 to RequiredLines - 1 do
                        begin
                           TempString := '';

                           for Entry := 0 to 9 do
                              begin
                                 Address := (Entry * RequiredLines) + Line;

                                 if Address < MultiplierTotalArray^[Band, Mode] then
                                    TempString := TempString + MultiplierListArray[Band, Mode]^[Address];

                                 if Entry < 9 then
                                    while (length(TempString) mod 8) <> 0 do
                                       TempString := TempString + ' ';
                              end;

                           WriteLn(FileWrite, TempString);
                           inc(Lines);
                        end;

                     WriteLn(FileWrite);
                     inc(Lines);

                     { Runtime 204 here - 05AD:B66A }

                     Dispose(MultiplierListArray[Band, Mode]);
                  end;

      end
   else
      WriteLn(FileWrite, 'No QSOs found in log file.');

   Dispose(MultiplierTotalArray);

   Close(FileWrite);
   view(FileName);
end;

function ReportProcedureMenu: boolean;

var
   Key                             : Char;

begin
   ReportProcedureMenu := true;
   //    ClrScr;
   //    TextColor (Yellow);
   WriteLnCenter('REPORT PROCEDURE MENU');
   WriteLn;
   //    TextColor (Cyan);
   WriteLn('  B - Band change report.');
   WriteLn('  C - Continent distribution report.');
   WriteLn('  D - Dupe sheet.');
   WriteLn('  E - Show QSOs that were dupes.');
   WriteLn('  L - List Multipliers worked.');
   WriteLn('  M - OH2MM CQ WW report menu.');
   WriteLn('  R - Rate report (hour by hour, band by band summary).');
   WriteLn('  Q - QSO distribution by domestic QTH or zone.');
   WriteLn('  S - Summary sheet.');
   WriteLn('  V - View any notes that are in your log (starting with ;).');
   WriteLn('  W - WPX prefix report.');
   WriteLn('  X - Exit report procedure menu.');
   WriteLn('  Z - Zone report (shows zones that may be wrong in the log).');
   WriteLn;
   Write('  Enter command : ');

   repeat
      //        REPEAT UNTIL KeyPressed;
      //        Key := UpCase (ReadKey);

      case Key of
         'B':
            begin
               BandChangeReport;
               Exit;
            end;
         'C':
            begin
               ContinentReport;
               Exit;
            end;
         'D':
            begin
               DupeSheet;
               Exit;
            end;
         'E':
            begin
               ShowDupeReport;
               Exit;
            end;
         'L':
            begin
               ListMultipliersWorked;
               Exit;
            end;
         'M':
            begin
               MultiplierReportMenu;
               Exit;
            end;
         'Q':
            begin
               QSODistribution;
               Exit;
            end;
         'R':
            begin
               RateReport;
               Exit;
            end;
         'S':
            begin
               SummarySheet;
               Exit;
            end;
         'V':
            begin
               ViewNotes;
               Exit;
            end;
         'W':
            begin
               WPXPrefixReport;
               Exit;
            end;
         'Z':
            begin
               ZoneReport;
               Exit;
            end;

         'X', EscapeKey:
            begin
               ReportProcedureMenu := False;
               Exit;
            end;
      end;
   until False;
end;

begin
end.

