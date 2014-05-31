unit PostCab;

{$O+}
{$F+}

interface

uses //Crt,
   //Dos,
   Tree,
   //SlowTree,
   Country9,
   LogDupe,
   ZoneCont,
//   LogName,
   LogGrid,
   LogWind,
//   PostSubs,
//   PostMult,
//   PostRpt,
   Dialogs,
   Other,
   SysUtils,
   Forms,
   PostUnit,
   Windows,
   ViewUnit; { Contains ContestType definition }

procedure CreateCabrilloFile;

var
   Key                             : Char;
   Address1, Address2, Address3, Address4, TempString, category: string;
   TotalScore                      : LONGINT;
   Operators                       : string;
   Precedence, Check, Section, power, NameInFile, QTH: Str40;
   Overlay                         : Str20;
   NameFileWrite, NameFileRead     : Text;
   ModeString, NameFileDirectory   : Str40;
   Year, Month, Day, DayOfWeek     : Word;

const

   CabrilloVersion                 = '2.3';
   {KK1L: 6.71 2.1}
   {KK1L: 6.73 2.2}
   {N6TR: 6.74 2.3 - Added ask for ARRL section in IARU & CW WW
                     Added WAE contest }

   CabrilloNameFileName            = 'CABNAME.DAT';

   NumberOperatorCategories        = 12;
   NumberBandCategories            = 8;
   NumberPowerCategories           = 3;
   NumberModeCategories            = 4;
   NumberOverlayCategories         = 5;

   OperatorCategory                : array[0..NumberOperatorCategories - 1] of string[25] = (
      'SINGLE-OP',
      'SINGLE-OP-ASSISTED',
      'SINGLE-OP-QRP-PORTABLE',
      'MULTI-ONE',
      'MULTI-TWO',
      'MULTI-MULTI',
      'MULTI-LIMITED',
      'MULTI-UNLIMITED',
      'ROVER',
      'SCHOOL-CLUB',
      'UNLIMITED',
      'CHECKLOG');

   BandCategory                    : array[0..NumberBandCategories - 1] of string[7] = (
      'ALL',
      '160M',
      '80M',
      '40M',
      '20M',
      '15M',
      '10M',
      'LIMITED');

   PowerCategory                   : array[0..NumberPowerCategories - 1] of string[4] = (
      'HIGH',
      'LOW',
      'QRP');

   ModeCategory                    : array[0..NumberModeCategories - 1] of string[5] = (
      'CW',
      'SSB',
      'RY',
      'MIXED');

   OverlayCategory                 : array[0..NumberOverlayCategories - 1] of string[12] = (
      'NONE',
      'ROOKIE',
      'BAND-LIMITED',
      'TB-WIRES',
      'OVER-50');

implementation

type
   QTCEntryRecord = record
      Time: CallString;
      Call: CallString;
      Number: CallString;
   end;

   QTCEntryArrayType = array[0..9] of QTCEntryRecord;
   QTCEntryArrayPtr = ^QTCEntryArrayType;

var
   CallSignLength                  : integer;
   Contest                         : ContestType;
   ContestName                     : string {80};
   CountryID                       : CallString;
   MyQTH                           : QTHRecord;

   NumberExchangeElementsToRecord  : integer;

   PreviousName                    : Str20; { Used for Interent Sprint }

   QTCEnable                       : boolean;
   QTCList                         : QTCEntryArrayPtr;

   ReceivedCallCursorPosition      : integer;
   ReceivedQSONumberLength         : integer;
   RSTIsPartOfTheExchange          : boolean;

   SentDataLength                  : integer;
   SniffForTransmitter             : boolean;
   SentInformation                 : Str40;
   SentQSONumberLength             : integer;

   SuppressRST                     : boolean;

   //  TempString: string {40};
   //  i:integer;

function GetFrequencyStringFromBand(Band: BandType): Str20;

var
   TempString                      : Str20;

begin
   TempString := '';

   case Band of
      Band160: TempString := '1800';
      Band80: TempString := '3500';
      Band40: TempString := '7000';
      Band30: TempString := '10100';
      Band20: TempString := '14000';
      Band17: TempString := '18100';
      Band15: TempString := '21000';
      Band12: TempString := '24900';
      Band10: TempString := '28000';
      Band6: TempString := '50'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band2: TempString := '144'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band222: TempString := '222'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band432: TempString := '432'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band902: TempString := '903'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band1296: TempString := '1.2'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band2304: TempString := '2.3'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band3456: TempString := '3.4'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band5760: TempString := '5.7'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band10G: TempString := '10'; {KK1L: 6.71 Changes from Trey from old lettering style}
      Band24G: TempString := '24'; {KK1L: 6.71 Changes from Trey from old lettering style}
      BandLight: TempString := 'LIGHT'; {KK1L: 6.71 Changes from Trey from old lettering style}
   end;

   while length(TempString) < 5 do
      TempString := ' ' + TempString;

   GetFrequencyStringFromBand := TempString;
end;

function GetModeStringFromMode(Mode: ModeType): Str20;

begin
   case Mode of
      cw: GetModeStringFromMode := 'CW';
      FM: GetModeStringFromMode := 'FM';
      Digital: GetModeStringFromMode := 'RY';
      Phone: GetModeStringFromMode := 'PH';
   end;
end;

function GetCabrilloDateStringFromDateString(FileString: string): Str20;

{ Do the date up so it looks like 1997-11-03 }

var
   DateString, MonthString, YearString: Str20;

begin
   DateString := Copy(FileString, 1, 2);

   MonthString := UpperCase(Copy(FileString, 4, 3));

   if MonthString = 'JAN' then MonthString := '01';
   if MonthString = 'FEB' then MonthString := '02';
   if MonthString = 'MAR' then MonthString := '03';
   if MonthString = 'APR' then MonthString := '04';
   if MonthString = 'MAY' then MonthString := '05';
   if MonthString = 'JUN' then MonthString := '06';
   if MonthString = 'JUL' then MonthString := '07';
   if MonthString = 'AUG' then MonthString := '08';
   if MonthString = 'SEP' then MonthString := '09';
   if MonthString = 'OCT' then MonthString := '10';
   if MonthString = 'NOV' then MonthString := '11';
   if MonthString = 'DEC' then MonthString := '12';

   YearString := Copy(FileString, 8, 2);

   { This is not year 2090 compliant - but easy to fix }

   if Copy(YearString, 1, 1) = '9' then
      YearString := '19' + YearString
   else
      YearString := '20' + YearString;

   GetCabrilloDateStringFromDateString := YearString + '-' + MonthString + '-' + DateString;
end;

function GetCabrilloDateStringFromLogEntry(LogEntryString: string): Str20;

begin
   LogEntryString := Copy(LogEntryString, LogEntryDayAddress, 9);
   GetCabrilloDateStringFromLogEntry := GetCabrilloDateStringFromDateString(LogEntryString);
end;

function ClaimedScore: LONGINT;

var
   TotalMultipliers                : LONGINT;
   TotalQSOPoints                  : LONGINT;
   TotalQTCs                       : LONGINT;
   TotalScore                      : LONGINT;

begin
   TotalQSOPoints := QSOPointTotals[All, Both];

   TotalMultipliers := DomesticTotals[All, Both] +
      DXTotals[All, Both] +
      PrefixTotals[All, Both] +
      ZoneTotals[All, Both];

   if TotalMultipliers > 0 then
      begin
         ClaimedScore := TotalQSOPoints * TotalMultipliers;
         if Contest = CUPRF then ClaimedScore := TotalQSOPoints + 120 * TotalMultipliers;
      end

   else
      ClaimedScore := TotalQSOPoints;
end;

procedure ShowCategoryData(StartY, OperatorCursor, BandCursor, PowerCursor, ModeCursor, OverlayCursor: integer);

var
   StartX, Address, DoBlink, MaxFieldWidth: integer;

   { Add 100 to the cursor who's column you want to be active }

begin
   MaxFieldWidth := 0;

   //    GoToXY (1, StartY);

   if OperatorCursor >= 100 then
      begin
         DoBlink := Blink;
         OperatorCursor := OperatorCursor - 100;
      end
   else
      DoBlink := 0;

   for Address := 0 to NumberOperatorCategories - 1 do
      begin
         if MaxFieldWidth < length(OperatorCategory[Address]) then
            MaxFieldWidth := length(OperatorCategory[Address]);

         if OperatorCursor = Address then
            begin
               //            TextColor (Black + DoBlink);
               //            TextBackground (Cyan);
            end
         else
            begin
               //            TextColor (Cyan);
               //            TextBackground (Black);
            end;

         Write(OperatorCategory[Address]);
         //        GoToXY (1, WhereY + 1);
      end;

   StartX := MaxFieldWidth + 5;

   MaxFieldWidth := 0;

   //    GoToXY (StartX, StartY);

   if BandCursor >= 100 then
      begin
         DoBlink := Blink;
         BandCursor := BandCursor - 100;
      end
   else
      DoBlink := 0;

   for Address := 0 to NumberBandCategories - 1 do
      begin
         if MaxFieldWidth < length(BandCategory[Address]) then
            MaxFieldWidth := length(BandCategory[Address]);

         if BandCursor = Address then
            begin
               //            TextColor (Black + DoBlink);
               //            TextBackground (Cyan);
            end
         else
            begin
               //            TextColor (Cyan);
               //            TextBackground (Black);
            end;

         Write(BandCategory[Address]);
         //        GoToXY (StartX, WhereY + 1);
      end;

   StartX := StartX + MaxFieldWidth + 5;

   MaxFieldWidth := 0;

   //    GoToXY (StartX, StartY);

   if PowerCursor >= 100 then
      begin
         DoBlink := Blink;
         PowerCursor := PowerCursor - 100;
      end
   else
      DoBlink := 0;

   for Address := 0 to NumberPowerCategories - 1 do
      begin
         if MaxFieldWidth < length(PowerCategory[Address]) then
            MaxFieldWidth := length(PowerCategory[Address]);

         if PowerCursor = Address then
            begin
               //            TextColor (Black + DoBlink);
               //            TextBackground (Cyan);
            end
         else
            begin
               //            TextColor (Cyan);
               //            TextBackground (Black);
            end;

         //        Write (PowerCategory [Address]);
         //        GoToXY (StartX, WhereY + 1);
      end;

   StartX := StartX + MaxFieldWidth + 5;

   MaxFieldWidth := 0;

   //    GoToXY (StartX, StartY);

   if ModeCursor >= 100 then
      begin
         DoBlink := Blink;
         ModeCursor := ModeCursor - 100;
      end
   else
      DoBlink := 0;

   for Address := 0 to NumberModeCategories - 1 do
      begin
         if MaxFieldWidth < length(ModeCategory[Address]) then
            MaxFieldWidth := length(ModeCategory[Address]);

         if ModeCursor = Address then
            begin
               //            TextColor (Black + DoBlink);
               //            TextBackground (Cyan);
            end
         else
            begin
               //            TextColor (Cyan);
               //            TextBackground (Black);
            end;

         Write(ModeCategory[Address]);
         //        GoToXY (StartX, WhereY + 1);
      end;

   StartX := StartX + MaxFieldWidth + 5;

   MaxFieldWidth := 0;

   //    GoToXY (StartX, StartY);

   if OverlayCursor >= 100 then
      begin
         DoBlink := Blink;
         OverlayCursor := OverlayCursor - 100;
      end
   else
      DoBlink := 0;

   for Address := 0 to NumberOverlayCategories - 1 do
      begin
         if MaxFieldWidth < length(OverlayCategory[Address]) then
            MaxFieldWidth := length(OverlayCategory[Address]);

         if OverlayCursor = Address then
            begin
               //            TextColor (Black + DoBlink);
               //            TextBackground (Cyan);
            end
         else
            begin
               //            TextColor (Cyan);
               //            TextBackground (Black);
            end;

         Write(OverlayCategory[Address]);
         //        GoToXY (StartX, WhereY + 1);
      end;
end;

procedure ActivateNextColumn(var OperatorCursor, BandCursor, PowerCursor,
   ModeCursor, OverlayCursor: integer);

begin
   if OperatorCursor >= 100 then
      begin
         OperatorCursor := OperatorCursor - 100;
         BandCursor := BandCursor + 100;
      end
   else
      if BandCursor >= 100 then
         begin
            BandCursor := BandCursor - 100;
            PowerCursor := PowerCursor + 100;
         end
      else
         if PowerCursor >= 100 then
            begin
               PowerCursor := PowerCursor - 100;
               ModeCursor := ModeCursor + 100;
            end
         else
            if ModeCursor >= 100 then
               begin
                  ModeCursor := ModeCursor - 100;
                  OverlayCursor := OverlayCursor + 100;
               end
            else
               if OverlayCursor >= 100 then
                  begin
                     OverlayCursor := OverlayCursor - 100;
                     OperatorCursor := OperatorCursor + 100;
                  end;
end;

procedure ActivatePreviousColumn(var OperatorCursor, BandCursor, PowerCursor,
   ModeCursor, OverlayCursor: integer);

begin
   if OperatorCursor >= 100 then
      begin
         OperatorCursor := OperatorCursor - 100;
         OverlayCursor := OverlayCursor + 100;
      end
   else
      if BandCursor >= 100 then
         begin
            BandCursor := BandCursor - 100;
            OperatorCursor := OperatorCursor + 100;
         end
      else
         if PowerCursor >= 100 then
            begin
               PowerCursor := PowerCursor - 100;
               BandCursor := BandCursor + 100;
            end
         else
            if ModeCursor >= 100 then
               begin
                  ModeCursor := ModeCursor - 100;
                  PowerCursor := PowerCursor + 100;
               end
            else
               if OverlayCursor >= 100 then
                  begin
                     OverlayCursor := OverlayCursor - 100;
                     ModeCursor := ModeCursor + 100;
                  end;
end;

function GetCategory(var Overlay: Str20): Str80;

var
   StartY, OperatorCursor, BandCursor, PowerCursor, ModeCursor, OverlayCursor: integer;
   //wli
   ReadKey                         : Char;
begin
   Result := postform.category_cb.Text + ' ' +
      postform.Band_cb.Text + ' ' +
      postform.Power_cb.Text + ' ' +
      postform.mode_cb.Text;

   if postform.overlay_cb.ItemIndex <> 0 then
      Overlay := postform.overlay_cb.Text
   else
      Overlay := ''

      {  exit;

        //    ClearScreenAndTitle ('CHOOSE CATEGORY');

      WriteLn('Move the cursor to the appropriate category for your entry.  Use the TAB key');
      WriteLn('to activate the next column.  Use the up and down arrows to make you selection.');
      WriteLn('When you are happy with your selection - press RETURN.  Use ESCAPE to abort.');
      WriteLn;

    //    TextColor (Yellow);
      WriteLn('CATEGORY                  BANDS       POWER    MODE      SPECIAL');
      WriteLn('--------                  -----       -----    ----      -------');

    //    NoCursor;

    //    StartY := WhereY;

      OperatorCursor := 100;
      BandCursor := 0;
      PowerCursor := 0;
      ModeCursor := 0;
      OverlayCursor := 0;

      repeat
        ShowCategoryData(StartY, OperatorCursor, BandCursor, PowerCursor, ModeCursor, OverlayCursor);

        case ReadKey of
          EscapeKey:
            begin
              GetCategory := '';
    //                SmallCursor;
    //                TextColor (Cyan);
    //                TextBackground (Black);
    //                ClrScr;
              exit;
            end;

          TabKey: ActivateNextColumn(OperatorCursor, BandCursor,
              PowerCursor, ModeCursor, OverlayCursor);

          CarriageReturn:
            begin
              if OperatorCursor >= 100 then OperatorCursor := OperatorCursor - 100;
              if BandCursor >= 100 then BandCursor := BandCursor - 100;
              if PowerCursor >= 100 then PowerCursor := PowerCursor - 100;
              if ModeCursor >= 100 then ModeCursor := ModeCursor - 100;
              if OverlayCursor >= 100 then OverlayCursor := OverLayCursor - 100;

              GetCategory := OperatorCategory[OperatorCursor] + ' ' +
                BandCategory[BandCursor] + ' ' +
                PowerCategory[PowerCursor] + ' ' +
                ModeCategory[ModeCursor];

              if OverlayCursor > 0 then
                Overlay := OverlayCategory[OverlayCursor]
              else
                Overlay := '';

    //                TextColor (Cyan);
    //                TextBackground (Black);
    //                ClrScr;
    //                SmallCursor;
              exit;
            end;

          NullKey:
            case ReadKey of
              RightArrow: ActivateNextColumn(OperatorCursor, BandCursor,
                  PowerCursor, ModeCursor, OverlayCursor);

              ShiftTab, LeftArrow:
                ActivatePreviousColumn(OperatorCursor, BandCursor,
                  PowerCursor, ModeCursor, OverlayCursor);

              DownArrow:
                begin
                  if OperatorCursor >= 100 then
                  begin
                    inc(OperatorCursor);
                    if OperatorCursor >= NumberOperatorCategories + 100 then
                      OperatorCursor := 100;
                  end;

                  if BandCursor >= 100 then
                  begin
                    inc(BandCursor);
                    if BandCursor >= NumberBandCategories + 100 then
                      BandCursor := 100;
                  end;

                  if PowerCursor >= 100 then
                  begin
                    inc(PowerCursor);
                    if PowerCursor >= NumberPowerCategories + 100 then
                      PowerCursor := 100;
                  end;

                  if ModeCursor >= 100 then
                  begin
                    inc(ModeCursor);
                    if ModeCursor >= NumberModeCategories + 100 then
                      ModeCursor := 100;
                  end;

                  if OverlayCursor >= 100 then
                  begin
                    inc(OverlayCursor);
                    if OverlayCursor >= NumberOverlayCategories + 100 then
                      OverlayCursor := 100;
                  end;
                end;

              UpArrow:
                begin
                  if OperatorCursor >= 100 then
                  begin
                    Dec(OperatorCursor);
                    if OperatorCursor < 100 then
                      OperatorCursor := NumberOperatorCategories + 99;
                  end;

                  if BandCursor >= 100 then
                  begin
                    Dec(BandCursor);
                    if BandCursor < 100 then
                      BandCursor := NumberBandCategories + 99;
                  end;

                  if PowerCursor >= 100 then
                  begin
                    Dec(PowerCursor);
                    if PowerCursor < 100 then
                      PowerCursor := NumberPowerCategories + 99;
                  end;

                  if ModeCursor >= 100 then
                  begin
                    Dec(ModeCursor);
                    if ModeCursor < 100 then
                      ModeCursor := NumberModeCategories + 99;
                  end;

                  if OverlayCursor >= 100 then
                  begin
                    Dec(OverlayCursor);
                    if OverlayCursor < 100 then
                      OverlayCursor := NumberOverlayCategories + 99;
                  end;
                end;

            end;

        end;

      until False;
      }
end;

function GenerateSummaryPortionOfCabrilloFile(CabrilloFileName: Str80;
   var FileWrite: Text): boolean;

begin
   GenerateSummaryPortionOfCabrilloFile := False;

   //    WriteLn ('The first step in generating the Cabrillo file is to put the necessary ');
   //    WriteLn ('summary information at the front of the file.');

   if not GetCallAndContestFromLOGCFGFile(MyCall, ContestName) then Exit;

   GetRidOfPostcedingSpaces(ContestName);

   Contest := DetermineContest(ContestName);

   if Contest = UnknownContest then
      begin
         ShowMessage(ContestName + ' is not recognized.');
         //        WaitForKeyPressed;
         Exit;
      end;

   if not CheckForTempFile then Exit;

   CountryTable.CountryMode := ARRLCountryMode;
   CountryTable.ZoneMode := CQZoneMode;

   { Make sure we are using the right zones and countries }

   case Contest of
      CQ160: CountryTable.CountryMode := CQCountryMode;
      CQVHF: CountryTable.CountryMode := CQCountryMode;
      CQWPX: CountryTable.CountryMode := CQCountryMode;
      Region1FD: CountryTable.CountryMode := CQCountryMode;
      CQWW: CountryTable.CountryMode := CQCountryMode;
      IARU: CountryTable.ZoneMode := ITUZoneMode;
      WAE: CountryTable.CountryMode := CQCountryMode;
   end;

   LocateCall(MyCall, MyQTH, true);

   CountryID := CountryTable.GetCountryID(MyQTH.Country);

   //    TextColor (Cyan);

   CalculateAppropriateTotalsForThisContest(Contest, MyQTH);

   if RawQSOTotals[All, Both] = 0 then
      begin
         //        GoToXY (1, WhereY);
         //        ClrEol;
         ShowMessage('There were no contacts found in the log file.');
         //        WaitForKeyPressed;
         Exit;
      end;

   PostForm.cm.Lines.Add(IntToStr(I) + ' QSOs were found in your log.');
   //    WriteLn;

   Section := '';
   power := '';
   PreviousName := '';

   SniffForTransmitter := False;

   CallSignLength := 13; { Default maximum callsign length }
   ReceivedCallCursorPosition := 56; { Default location of received call }

   RSTIsPartOfTheExchange := False;
   NumberExchangeElementsToRecord := 0; { 0 is disable counting }

   ReceivedQSONumberLength := 0;
   SentQSONumberLength := 0;

   SuppressRST := False;

   { Get the sent information string for the specific contest we are doing }

   { Currently not doing the AP-SPRINT, ARRL-UHF-AUG, SAC, TARA-RTTY }

   case Contest of

      CUPRF:
         begin
            SentInformation := GetResponse('Enter the locator you sent : ');
            if SentInformation = '' then Exit;
            //            SentDataLength := 3;
            SentInformation := '# ' + SentInformation;
            SentQSONumberLength := 4;
{
         1         2         3         4         5         6         7
12345678901234567890123456789012345678901234567890123456789012345678901234567890
QSO: 14000 CW 2004-01-11 0658 UA2FZ         009KO04    RZ3AZ         012KO85
}
         end;

      ARRL10: { Okay for domestic and DX }
         begin
            RSTIsPartOfTheExchange := true;

            if (MyQTH.CountryID = 'K') or (MyQTH.CountryID = 'VE') or
               (MyQTH.CountryID = 'KH6') or (MyQTH.CountryID = 'KL') then
               begin
                  SentInformation := GetResponse('Enter the state/province you sent during the contest : ');
                  SentInformation := '$ ' + SentInformation;

                  //          Section := GetResponse('Enter your ARRL Section abbreviation : ');
                  //          if Section = '' then exit;
               end
            else
               begin
                  SentInformation := '$ #';
                  SentQSONumberLength := 6;
                  Section := 'DX'; {KK1L: 6.73 2.2}
               end;

            NumberExchangeElementsToRecord := 1;
         end;

      ARRL160: { Okay for domestic and DX }
         begin
            RSTIsPartOfTheExchange := true;

            if ARRLSectionCountry(MyQTH.CountryID) then
               begin
                  //          Section := GetResponse('Enter your ARRL Section abbreviation : ');
                  //          if Section = '' then exit;
                  SentInformation := '$ ' + postform.section_cb.Text;
               end
            else
               begin
                  SentInformation := '$';
                  Section := 'DX'; {KK1L: 6.73 2.2}
               end;
         end;

      ARRLDX: { Okay for domestic and DX }
         begin
            RSTIsPartOfTheExchange := true;
            SniffForTransmitter := true;

            if (MyQTH.CountryID = 'K') or (MyQTH.CountryID = 'VE') then
               begin
                  SentInformation := GetResponse('Enter the QTH you sent during the contest : ');
                  if SentInformation = '' then Exit;
                  SentInformation := '$ ' + SentInformation;
                  //          Section := GetResponse('Enter your ARRL Section abbreviation : ');
                  //          if Section = '' then exit;
               end
            else
               begin
                  power := GetResponse('Enter power sent during contest : ');
                  SentInformation := '$ ' + power;
                  //          Section := 'DX'; {KK1L: 6.73 2.2}
               end;
         end;

      ARRLVHFQSO, ARRLVHFSS, CQVHF:
         begin
            SentInformation := GetResponse('Enter the grid you sent : ');
            if SentInformation = '' then Exit;
            //        Section := GetResponse('Enter your ARRL Section : ');
            //        if Section = '' then exit;
            RSTIsPartOfTheExchange := true;
            SuppressRST := true;
         end;

      ARRLRTTY:
         begin
            //        Section := UpperCase(GetResponse('Enter your ARRL Section Abbreviation (or DX) : '));

            if Section <> 'DX' then
               begin
                  SentInformation := GetResponse('Enter the state or province you sent during the contest : ');
                  SentInformation := '$ ' + SentInformation;
               end
            else
               SentInformation := '$ #';

            RSTIsPartOfTheExchange := true;
            NumberExchangeElementsToRecord := 1;
         end;

      CalQSO, FQP, MIQP, MQP, OHIOQP, SALMONRUN, WQP: {KK1L: 6.71 added other state QPs}
         begin
            //        Section := GetResponse('Enter your state or county sent : '); {KK1L: 6.71 Removed 'Cal' before 'county'}
            //        if Section = '' then exit;
            SentInformation := '# ' + postform.section_cb.Text;
         end;

      CQ160: { Okay }
         begin
            RSTIsPartOfTheExchange := true;

            //        Section := GetResponse('Enter the QTH you sent : ');
            //        if Section = '' then exit;
            SentInformation := '$ ' + postform.section_cb.Text;
         end;

      CQWPX, OceaniaVKZL, SAC, APSprint, Region1FD, WAE:
         begin
            CallsignLength := 13;
            RSTIsPartOfTheExchange := true;
            SentDataLength := 10;
            SentInformation := '$ #';
            SentQSONumberLength := 6;
         end;

      CQWW: { Okay }
         begin
            CallsignLength := 13;
            RSTIsPartOfTheExchange := true;
            SentDataLength := 10;
            SniffForTransmitter := true; {KK1L: 6.71 Add Multi-Two check for CQWW}

            QTH := GetResponse('Enter the zone you were sending : ');
            if QTH = '' then Exit;

            SentInformation := '$ ' + QTH;

            //        if ARRLSectionCountry(MYQTH.CountryID) then
            //          Section := GetResponse('Enter your ARRL Section abbreviation : ');
         end;

      IARU: { Okay }
         begin
            RSTIsPartOfTheExchange := true;

            QTH := GetResponse('Enter the zone you were sending : ');
            if QTH = '' then Exit;

            SentInformation := '$ ' + QTH;

            //        if ARRLSectionCountry(MYQTH.CountryID) then
            //          Section := GetResponse('Enter your ARRL Section abbreviation : ');

         end;

      IntSprint: { Okay - somewhat modified format - name length }
         begin
            CallsignLength := 10;
            SentQSONumberLength := 4;
            ReceivedCallCursorPosition := 62;

            PreviousName := GetResponse('Enter the name you sent for the first QSO : ');
            if NameInFile = '' then Exit;

            QTH := GetResponse('Enter the QTH you sent (DX if outside W/VE) : ');
            if QTH = '' then Exit;

            SentInformation := '# ' + ControlN + ' ' + QTH;
            ReceivedQSONumberLength := 4;
         end;

      NAQSO: { Doesn't comply with field length for name }
         begin
            CallsignLength := 10;
            ReceivedCallCursorPosition := 62;
            SniffForTransmitter := true; {KK1L: 6.71 Add Multi-Two check for NAQP}

            NameInFile := GetResponse('Enter the name you sent : ');
            if NameInFile = '' then Exit;

            QTH := GetResponse('Enter the QTH you sent (DX if outside W/VE) : ');
            if QTH = '' then Exit;

            SentInformation := NameInFile + ' ' + QTH;
         end;

      NEQSO:
         begin
            repeat
               Key := UpCase(GetKey('Did you operate from New England? (Y/N or ESCAPE to abort) : '));
               if Key = EscapeKey then Exit;
            until (Key = 'Y') or (Key = 'N');
            WriteLn;
            //        Section := GetResponse('Enter your state: ');
            //        if Section = '' then exit;

            if Key = 'Y' then
               begin
                  QTH := GetResponse('Enter your THREE leter county abreviation: ');
                  SentInformation := '$ ' + QTH + postform.section_cb.Text;
               end
            else
               SentInformation := '$ ' + postform.section_cb.Text;

            RSTIsPartOfTheExchange := true;
            {SuppressRST := True;}
         end;

      Sprint: { Okay - somewhat modified format - name length }
         begin
            CallsignLength := 10;
            SentQSONumberLength := 4;
            ReceivedCallCursorPosition := 62;

            NameInFile := GetResponse('Enter the name you sent : ');
            if NameInFile = '' then Exit;

            QTH := GetResponse('Enter the QTH you sent (DX if outside W/VE) : ');
            if QTH = '' then Exit;

            SentInformation := '# ' + NameInFile + ' ' + QTH;
            ReceivedQSONumberLength := 4;
         end;

      ss:
         begin { Okay }
            CallsignLength := 10;
            ReceivedQSONumberLength := 4;
            SentDataLength := 13;
            SentQSONumberLength := 4;

            Precedence := GetKeyResponse('Enter your precedence sent (A, B, Q, M, S, U) : ');
            if Precedence = EscapeKey then Exit;

            Check := GetResponse('Enter your check (last two digits of year licensed : ');
            if (length(Check) <> 2) or not StringIsAllNumbers(Check) then
               Exit;

            //        Section := GetResponse('Enter your ARRL Section abbreviation : ');
            //        if Section = '' then exit;

            SentInformation := '# ' + Precedence + ' ' + Check + ' ' + postform.section_cb.Text;
         end;

      StewPerry:
         begin
            SentInformation := GetResponse('Enter the grid you sent : ');
            if SentInformation = '' then Exit;

            SentInformation := '$ ' + SentInformation;

            RSTIsPartOfTheExchange := true;
         end;
   end;

   { This is big enough to get its own routine }

   category := GetCategory(Overlay);

   if category = '' then Exit;

   if SniffForTransmitter then
      SniffForTransmitter := StringHas(category, 'MULTI-TWO');

   { Open up the output file }

   if not OpenFileForWrite(FileWrite, CabrilloFileName) then Exit;

   WriteLn(FileWrite, 'START-OF-LOG: ', CabrilloVersion);
   WriteLn(FileWrite, 'CREATED-BY: '+{TR Log POST Version ',} {PostVersion, ' (',} p, ' ', postw_version);
   WriteLn(FileWrite, 'CALLSIGN: ', MyCall);

   if StringHas(category, 'CW') then ModeString := 'CW' else
      if StringHas(category, 'SSB') then ModeString := 'SSB' else
         if StringHas(category, 'RY') then ModeString := 'RY';

   QTCEnable := False;

   case Contest of

      CupRF: WriteLn(FileWrite, 'CONTSET: Cup RF');

      APSprint: WriteLn(FileWrite, 'CONTSET: AP SPRINT');
      ARRL10: WriteLn(FileWrite, 'CONTEST: ARRL-10');
      ARRL160: WriteLn(FileWrite, 'CONTEST: ARRL-160');
      ARRLDX: WriteLn(FileWrite, 'CONTEST: ARRL-DX-', ModeString);
      ARRLRTTY: WriteLn(FileWrite, 'CONTEST: ARRL-RTTY');

      ARRLVHFQSO:
         begin
            GetDate(Year, Month, Day, DayOfWeek);

            if (Month >= 6) and (Month < 9) then
               WriteLn(FileWrite, 'CONTEST: ARRL-VHF-JUN')
            else
               if (Month >= 9) or (Month < 6) then
                  WriteLn(FileWrite, 'CONTEST: ARRL-VHF-SEP');
         end;

      ARRLVHFSS: WriteLn(FileWrite, 'CONTEST: ARRL-VHF-JAN');
      CalQSO: WriteLn(FileWrite, 'CONTEST: CA-QSO-PARTY');
      CQ160: WriteLn(FileWrite, 'CONTEST: CQ-160-', ModeString);
      CQVHF: WriteLn(FileWrite, 'CONTEST: CQ-VHF');
      CQWPX: WriteLn(FileWrite, 'CONTEST: CQ-WPX-', ModeString);
      CQWW: WriteLn(FileWrite, 'CONTEST: CQ-WW-', ModeString);
      IARU: WriteLn(FileWrite, 'CONTEST: IARU-HF');
      IntSprint: WriteLn(FileWrite, 'CONTEST: INTERNET-SPRINT');
      NAQSO: WriteLn(FileWrite, 'CONTEST: NAQP-', ModeString);
      NEQSO: WriteLn(FileWrite, 'CONTEST: New England QSO Party');
      OceaniaVKZL: WriteLn(FileWrite, 'CONTEST: OCEANIA');
      Region1FD: WriteLn(FileWrite, 'CONTEST: REGION ONE FIELD DAY');
      SAC: WriteLn(FileWrite, 'CONTEST: SAC');
      Sprint: WriteLn(FileWrite, 'CONTEST: NA-SPRINT-', ModeString);
      ss: WriteLn(FileWrite, 'CONTEST: ARRL-SS-', ModeString);
      StewPerry: WriteLn(FileWrite, 'CONTEST: STEW-PERRY');

      WAE:
         begin
            WriteLn(FileWrite, 'CONTEST: DARC-WAEDC-', ModeString);
            QTCEnable := true;
         end;
   end;

   Section := postform.section_cb.Text;
   if Section <> '' then
      WriteLn(FileWrite, 'ARRL-SECTION: ', Section);

   WriteLn(FileWrite, 'CATEGORY: ', category);

   if Overlay <> '' then
      WriteLn(FileWrite, 'CATEGORY-OVERLAY: ', Overlay);

   WriteLn(FileWrite, 'CLAIMED-SCORE: ', ClaimedScore);

   TempString := postform.ClubEdit.Text; //GetResponse ('Enter team or club (if any) : ');

   if TempString <> '' then
      WriteLn(FileWrite, 'CLUB: ' + TempString);

   { Do the name and address thing }

//  NameFileDirectory := FindDirectory('CABNAME.DAT');
{
 Address2 := '';
 Address3 := '';
 Address4 := '';

 if FileExists(ExtractFileDir(application.ExeName) + '\CABNAME.DAT') then
 begin
   NameFileDirectory := ExtractFileDir(application.ExeName) + '\' + CabrilloNameFileName;
   if MessageBox(0, ('Okay to use previously stored name and address?'), 'POST', MB_YESNO or MB_ICONQUESTION) <> IDno
     then
   begin
     if OpenFileForRead(NameFileRead, ExtractFileDir(application.ExeName) + '\' + CabrilloNameFileName) then
     begin
       ReadLn(NameFileRead);
       ReadLn(NameFileRead, NameInFile);
       ReadLn(NameFileRead, Address1);
       if not Eof(NameFileRead) then ReadLn(NameFileRead, Address2);
       if not Eof(NameFileREad) then ReadLn(NameFileRead, Address3);
       if not Eof(NameFileREad) then ReadLn(NameFileRead, Address4);
       Close(NameFileRead);
     end
     else
     begin
       SHOWMESSAGE('ERROR!!  CABNAME file was there - but now it is not.');
       halt;
     end;
   end
   else
     NameFileDirectory := '';
 end;
}
{  if NameFileDirectory = '' then
 begin
   NameInFile := GetResponse('Enter your full name : ');
   Address1 := GetResponse('Address (first line) : ');
   Address2 := GetResponse('Address (second line) : ');
   Address3 := GetResponse('Address (third line) : ');
   Address4 := GetResponse('Address (last line) : ');

   if 'Y' = GetKeyResponse('Would you like me to save this information for next time? (Y, N) : ') then
   begin
     NameFileDirectory := FindDirectory('POST.OVR');

     OpenFileForWrite(NameFileWrite, NameFileDirectory + '\' + CabrilloNameFileName);
     WriteLn(NameFileWrite, 'This is your default name and address that is used by the Cabrillo procedure.');
     WriteLn(NameFileWrite, NameInFile);
     WriteLn(NameFileWrite, Address1);
     WriteLn(NameFileWrite, Address2);
     WriteLn(NameFileWrite, Address3);
     WriteLn(NameFileWrite, Address4);
     Close(NameFileWrite);
   end;
 end;
}
   WriteLn(FileWrite, 'NAME: ', NameInFile);
   WriteLn(FileWrite, 'ADDRESS: ', Address1);

   if Address2 <> '' then WriteLn(FileWrite, 'ADDRESS: ', Address2);
   if Address3 <> '' then WriteLn(FileWrite, 'ADDRESS: ', Address3);
   if Address4 <> '' then WriteLn(FileWrite, 'ADDRESS: ', Address4);

   { Do operator list}

   Operators := postform.OperatorsEdit.Text;

   if Operators <> '' then
      WriteLn(FileWrite, 'OPERATORS: ', Operators);

   { Do soapbox }

//  WriteLn('Enter as many soapbox comment lines as you want.  Enter blank line to stop.');

//    TextColor (Yellow);

//  repeat
//        TextColor (Cyan);
//        Write ('SOAPBOX: ');
//        TextColor (Yellow);
//    ReadLn(TempString);
   TempString := postform.SOAPBOXEdit.Text;
   if TempString <> '' then
      WriteLn(FileWrite, 'SOAPBOX: ', TempString);
   //  until TempString = '';

   GenerateSummaryPortionOfCabrilloFile := true;
end;

{START-OF-LOG: 2.0
CONTEST: WAEDC
CALLSIGN: DL8WPX
CATEGORY: SINGLE-OP ALL LOW
CATEGORY-ASSISTED: NON-ASSISTED
CLAIMED-SCORE: 1456
OPERATORS: DL8WPX
CLUB: Bavarian Contest Club
NAME: Joerg Puchstein
ADDRESS: Jung-Jochen-Weg 16B
ADDRESS: 18069 Rostock
ADDRESS: Germany
SOAPBOX: Just a couple of hours left for this one, sri.
SOAPBOX: At least I catched HC8N for an all time new one at this weekend.
OFFTIME: 2001-09-11 0000 2001-09-11 2026
OFFTIME: 2001-09-11 2210 2001-09-12 2400
QSO: 14234 PH 2001-09-11 2026 DL8WPX        59     623 K3NM          59     798
QSO: 14234 PH 2001-09-11 2027 DL8WPX        59     624 9K9O          59     975
QSO: 14234 PH 2001-09-11 2029 DL8WPX        59     625 LT5F          59     589
QSO: 14234 PH 2001-09-11 2044 DL8WPX        59     626 WF3M          59     180
QSO: 14234 PH 2001-09-11 2052 DL8WPX        59     627 LU1DZ         59     621
QSO: 14234 PH 2001-09-11 2057 DL8WPX        59     628 JR3KQJ        59      14
QSO: 14234 PH 2001-09-11 2058 DL8WPX        59     629 JA0QWO        59     419
QSO: 14234 PH 2001-09-11 2112 DL8WPX        59     630 JG3VEI        59     503
QSO: 14234 PH 2001-09-11 2115 DL8WPX        59     631 KC1F          59     147
QSO: 14234 PH 2001-09-11 2119 DL8WPX        59     632 TU2XZ         59     573
QSO: 14234 PH 2001-09-11 2132 DL8WPX        59     633 JA3YBK        59     940
QSO: 14234 PH 2001-09-11 2137 DL8WPX        59     634 C4A           59    1187
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2109 OH1VR          376
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2109 OM4WW          109
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2110 LZ1QZ          170
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2110 ES4MM          170
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2111 RW3QO          204
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2112 G3LKZ           86
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2113 OK2KR          196
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2114 HA6KNX         232
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2116 SP9XCN         410
QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2119 9A2EY           49
QSO: 14234 PH 2001-09-11 2151 DL8WPX        59     635 UA9AYA        59     904
QSO: 14234 PH 2001-09-11 2201 DL8WPX        59     636 JA1YPA        59     532
QSO: 14234 PH 2001-09-11 2205 DL8WPX        59     637 N2NI          59       3
QSO: 14234 PH 2001-09-11 2207 DL8WPX        59     638 K1BV          59     185
QSO: 14234 PH 2001-09-11 2209 DL8WPX        59     639 N1XS          59     236
QSO: 21289 PH 2001-09-12 1412 DL8WPX        59     000 HC8N          59    1620
END-OF-LOG:
}

function GenerateLogPortionOfCabrilloFile(CabrilloFileName: Str80;
   var FileWrite: Text): boolean;

{ This function relies on some global variables defined by the previous
  routines.  It does not know specifically which contest it is processing

  MyCall: STRING;
  NumberExchangeElementsToRecord: INTEGER;
  QTCEnable: BOOLEAN;
  ReceivedCallCursorPosition: INTEGER;
  ReceivedQSONumberLength: INTEGER;
  RSTIsPartOfTheExchange: BOOLEAN;
  SentDataLength:      INTEGER;
  SentInformation: STRING;
  SentQSONumberLength: INTEGER;
  SniffForTransmitter: BOOLEAN;
  SuppressRST: BOOLEAN;

}

label
   DoItAgain;

var
   //wli
   Result1                         : integer;
   QTCFileRead, FileRead           : Text;
   QTCFileString, FileString, CabrilloString: string;
   ExchangeString, QTCWriteString  : string;
   YearString, NumberString, TimeString, DateString: Str40;
   SentData, ModeString, FrequencyString, MyCallString, MonthString: Str40;
   NumberQSOs                      : Word;
   Band                            : BandType;
   Mode                            : ModeType;
   Count, QSONumberSent, NumberReceived, CursorPosition: integer;
   RSTReceived, RSTSentString, CallReceivedString, QSONumberSentString: Str20;
   Transmitter0Char, ComputerID    : Char;

   QTCIndexNumberString, QTCNumber, QTCCall, QTCDate, QTCTime: CallString;
   QTCBandModeString               : CallString;

   QTCBand                         : BandType;
   QTCMode                         : ModeType;

   QTCEntry, QTCIndexNumber        : integer;

begin
   Transmitter0Char := CHR(0);

   GenerateLogPortionOfCabrilloFile := False;
   NumberQSOs := 0;

   if QTCEnable then
      if not OpenFileForRead(QTCFileRead, 'QTC.DAT') then
         begin
            ShowMessage('Can not open QTC.DAT file!!');

            repeat
               Key := UpCase(GetKey('Do you want to continue? (Y/N) : '));
               if (Key = EscapeKey) or (Key = 'N') then Exit;
            until Key = 'Y';

            QTCEnable := False;
         end;

   if QTCEnable then New(QTCList);

   if OpenFileForRead(FileRead, LogFileName) then
      begin
         //    postform.cm.Lines.add(inttostr(NumberQSOs)+'-b-');

                 { Some things only need to be done once - do them here }

                 { Format my callsign }

         MyCallString := MyCall;

         if length(MyCallString) > CallsignLength then
            MyCallString := Copy(MyCallString, 1, CallsignLength);

         while length(MyCallString) < CallsignLength do
            MyCallString := MyCallString + ' ';

         //        TextColor (Cyan);

                 { Now - read in the log and process the entries }

         while not Eof(FileRead) do
            begin
               repeat
                  ReadLn(FileRead, FileString);

                  if QTCEnable then
                     if StringHas(FileString, '; QTC') then
                        begin

                           { This is what the log entry looks like for a QTC entry

                           ; QTC 1/10 with ES1QD on 16-Aug-03 at 14:27 on  80CW

                             and this is what the corresponding entry in the QTC.DAT file looks like:

                           QTC 1/10 with ES1QD on 16-Aug-03 at 14:27 on  80CW

                           }
                           Delete(FileString, 1, 2); { ; and space }
                           GetRidOfPostcedingSpaces(FileString);
                           WriteLn;
                           WriteLn(FileString, '.');

                           repeat
                              ReadLn(QTCFileRead, QTCFileString);
                              GetRidOfPostcedingSpaces(QTCFileString);

                              if Eof(QTCFileRead) then
                                 begin
                                    ShowMessage('QTC file problem.  Could not find log file entry in QTC.DAT');
                                    WriteLn(FileString);
                                    halt;
                                 end;

                           until (QTCFileString = FileString);

                           { QTC.DAT entry has matched up with log entry }

                           RemoveFirstString(FileString); { QTC }
                           QTCNumber := RemoveFirstString(FileString); { 1/10 }

                           while length(QTCNumber) < 7 do
                              QTCNumber := ' ' + QTCNumber;

                           RemoveFirstString(FileString); { with }
                           QTCCall := RemoveFirstString(FileString);

                           while length(QTCCall) < 12 do
                              QTCCall := QTCCall + ' ';

                           RemoveFirstString(FileString); { on }
                           QTCDate := RemoveFirstString(FileString); { 16-Aug-03 }

                           { Convert the date format to Cabrillo }

                           QTCDate := GetCabrilloDateStringFromDateString(QTCDate);

                           RemoveFirstString(FileString); { at }

                           QTCTime := RemoveFirstString(FileString); { 14:27 }
                           QTCTime := NumberPartOfString(QTCTime);

                           RemoveFirstString(FileString); { on }
                           QTCBandModeString := RemoveFirstString(FileString); { 80CW }

                           QTCBand := GetLogEntryBand(' ' + QTCBandModeString + ' ');
                           QTCMode := GetLogEntryMode(' ' + QTCBandModeString + ' ');

                           { This is what the QTC.DAT entry looks like

                            1: 1426  F2CW  3                        6: 1426  SP5NIQ  34
                            2: 1426  G3FXB  34                      7: 1426  HB9AMO  34
                            3: 1426  DL1IAO  32                     8: 1426  OH1VR  234
                            4: 1426  EA6NB  34                      9: 1426  SM2EKM  234
                            5: 1426  I2UIY  234                    10: 1426  SM5ABC  34

                           }

                           for QTCEntry := 0 to 9 do { Clear the array }
                              with QTCList^[QTCEntry] do
                                 begin
                                    Time := '';
                                    Call := '';
                                    Number := '';
                                 end;

                           repeat
                              ReadLn(QTCFileRead, QTCFileString);

                              GetRidOfPrecedingSpaces(QTCFileString);

                              if QTCFileString <> '' then
                                 begin
                                    WriteLn(QTCFileString);

                                    DoItAgain: { I know - this is a cheap trick  - used to read the second column }

                                    QTCIndexNumberString := RemoveFirstString(QTCFileString);
                                    QTCIndexNumberString := PrecedingString(QTCIndexNumberString, ':');

                                    Val(QTCIndexNumberString, QTCIndexNumber, Result1);

                                    if Result1 <> 0 then
                                       begin
                                          ShowMessage('Error reading QTC.DAT file.');
                                          WriteLn(QTCFileString);
                                       end;

                                    if (QTCIndexNumber < 1) or (QTCIndexNumber > 10) then
                                       begin
                                          ShowMessage('Number error reading QTC.DAT file.');
                                          WriteLn(QTCFileString);
                                       end;

                                    Dec(QTCIndexNumber);

                                    with QTCList^[QTCIndexNumber] do
                                       begin
                                          Time := RemoveFirstString(QTCFileString);
                                          Time := NumberPartOfString(Time);

                                          Call := RemoveFirstString(QTCFileString);
                                          Number := RemoveFirstString(QTCFileString);
                                       end;

                                    GetRidOfPrecedingSpaces(QTCFileString);

                                    if QTCFileString <> '' then goto DoItAgain;

                                    QTCFileString := ' ';
                                 end;

                           until (QTCFileString = '');

                           { Okay, we have read in all of the data we need to spit
                             out the QTC entries - now what??? Oh yeah, make it look
                             like this:

   QTC: 14234 PH 2001-09-11 2138 DL8WPX        123/10     C4A           2109 OH1VR          376
   Call fields end here for length=12                                

   }

                           for QTCEntry := 0 to 9 do
                              with QTCList^[QTCEntry] do
                                 begin
                                    if Call <> '' then
                                       begin
                                          while length(Call) < 12 do
                                             Call := Call + ' ';

                                          while length(Number) < 6 do
                                             Number := ' ' + Number;

                                          QTCWriteString := 'QTC: ' +
                                             GetFrequencyStringFromBand(QTCBand) +
                                             ' ' +
                                             GetModeStringFromMode(QTCMode) +
                                             ' ' +
                                             QTCDate + ' ' + QTCTime + ' ' +
                                             MyCallString +
                                             QTCNumber + '     ' +
                                             QTCCall + '  ' +
                                             Time + ' ' +
                                             Call + Number;

                                          WriteLn(FileWrite, QTCWriteString);
                                       end;
                                 end;

                           Continue; { Skip this entry and get on with the next }
                        end;

                  Band := GetLogEntryBand(FileString);
               until (Band <> NoBand) or Eof(FileRead);

               Mode := GetLogEntryMode(FileString);

               if Band <> NoBand then
                  begin
                     if (FileString[1] = ';') then Continue;

                     if length(FileString) < 60 then Continue;
                     if Copy(FileString, 1, 1) = LineFeed then Continue;

                     ExpandTabs(FileString);

                     if FileString[42] = '*' then FileString[42] := ' ';

                     { Save the exchange part for later }

                     ExchangeString := GetLogEntryExchangeString(FileString);

                     { The first RST is always there }

                     if RSTIsPartOfTheExchange then
                        RemoveFirstString(ExchangeString);

                     GetRidOfPrecedingSpaces(ExchangeString);

                     if RSTIsPartOfTheExchange then
                        if StringIsAllNumbers(GetFirstString(ExchangeString)) then
                           begin
                              RSTReceived := RemoveFirstString(ExchangeString);

                              while length(RSTReceived) < 3 do
                                 RSTReceived := RSTReceived + ' ';

                              GetRidOfPrecedingSpaces(ExchangeString);

                              if SuppressRST then RSTReceived := '   ';
                           end
                        else
                           if (Mode = cw) or (Mode = Digital) then
                              RSTReceived := '599'
                           else
                              RSTReceived := '59';

                     if ReceivedQSONumberLength > 0 then
                        begin
                           NumberReceived := RemoveFirstLongInteger(ExchangeString);
                           GetRidOfPrecedingSpaces(ExchangeString);

                           Str(NumberReceived: ReceivedQSONumberLength, TempString);

                           ExchangeString := TempString + ' ' + ExchangeString;
                        end;

                     if NumberExchangeElementsToRecord > 0 then
                        begin
                           TempString := '';

                           for Count := 1 to NumberExchangeElementsToRecord do
                              TempString := TempString + RemoveFirstString(ExchangeString) + ' ';

                           GetRidOfPostcedingSpaces(TempString);

                           ExchangeString := TempString;
                        end;

                     while pos('  ', ExchangeString) > 0 do
                        Delete(ExchangeString, pos('  ', ExchangeString), 1);

                     { Get rid of any S&P indicator }

                     while pos('$', FileString) > 0 do
                        FileString[pos('$', FileString)] := ' ';

                     Mode := GetLogEntryMode(FileString);

                     ModeString := GetModeStringFromMode(Mode);

                     { Generate a fake frequency for the band/mode }

                     FrequencyString := GetFrequencyStringFromBand(Band);

                     CabrilloString := 'QSO: ' + FrequencyString + ' ' + ModeString + ' ';

                     DateString := GetCabrilloDateStringFromLogEntry(FileString);

                     CabrilloString := CabrilloString + DateString + ' ';

                     { Now do the time }

                     TimeString := Copy(FileString, LogEntryHourAddress, 2) +
                        Copy(FileString, LogEntryMinuteAddress, 2);

                     CabrilloString := CabrilloString + TimeString + ' ';

                     { Add my callsign which was previously formatted }

                     CabrilloString := CabrilloString + MyCallString + ' ';

                     { Do the exchange sent }

                     if SentInformation <> '' then
                        begin
                           SentData := SentInformation;

                           if StringHas(SentData, '$') then { RST sent }
                              begin
                                 CursorPosition := pos('$', SentData);

                                 Delete(SentData, CursorPosition, 1);

                                 RSTSentString := GetFirstString(GetLogEntryExchangeString(FileString));

                                 while length(RSTSentString) < 3 do
                                    RSTSentString := RSTSentString + ' ';

                                 Insert(RSTSentString, SentData, CursorPosition);
                              end
                           else
                              if SuppressRST then
                                 SentData := '   ' + SentData;

                           if StringHas(SentData, '#') then
                              begin
                                 CursorPosition := pos('#', SentData);

                                 Delete(SentData, CursorPosition, 1);

                                 QSONumberSent := GetLogEntryQSONumber(FileString);
                                 Str(QSONumberSent: SentQSONumberLength, QSONumberSentString);

                                 Insert(QSONumberSentString, SentData, CursorPosition);
                              end;

                           if StringHas(SentData, ControlN) then
                              begin
                                 CursorPosition := pos(ControlN, SentData);
                                 Delete(SentData, CursorPosition, 1);
                                 Insert(PreviousName, SentData, CursorPosition);
                              end;

                           while length(SentData) < SentDataLength do
                              SentData := SentData + ' ';

                           CabrilloString := CabrilloString + SentData + ' ';
                        end;

                     while length(CabrilloString) < ReceivedCallCursorPosition - 1 do
                        CabrilloString := CabrilloString + ' ';

                     CallReceivedString := GetLogEntryCall(FileString);

                     if length(CallReceivedString) > CallsignLength then
                        CallReceivedString := Copy(CallReceivedString, 1, CallSignLength)
                     else
                        while length(CallReceivedString) < CallsignLength do
                           CallReceivedString := CallReceivedString + ' ';

                     CabrilloString := CabrilloString + CallReceivedString + ' ';

                     if RSTIsPartOfTheExchange then
                        CabrilloString := CabrilloString + RSTReceived + ' ' + ExchangeString
                     else
                        CabrilloString := CabrilloString + ExchangeString;

                     if PreviousName <> '' then
                        begin
                           RemoveFirstString(ExchangeString);
                           PreviousName := RemoveFirstString(ExchangeString);
                        end;

                     if SniffForTransmitter then { ARRL DX Multi2 } {KK1L: 6.71 Or other contests as needed}
                        begin
                           while length(CabrilloString) < 79 do {KK1L: 6.73 Need to add space for contests >80 columns. Was 80.}
                              CabrilloString := CabrilloString + ' ';
                           CabrilloString := CabrilloString + ' '; {KK1L: 6.73 Will always add a space.}

                           ComputerID := GetLogEntryComputerID(FileString);

                           if Transmitter0Char = CHR(0) then
                              Transmitter0Char := ComputerID;

                           if Transmitter0Char = ComputerID then
                              CabrilloString := CabrilloString + '0'
                           else
                              CabrilloString := CabrilloString + '1';
                        end;

                     WriteLn(FileWrite, CabrilloString);

                     inc(NumberQSOs);

                     //                GoToXY (1, WhereY);

             //    postform.cm.Lines.add(inttostr(NumberQSOs)+'-a-');

                  end;
            end;
         Close(FileRead);

         GenerateLogPortionOfCabrilloFile := true;
      end

   else
      begin
         ShowMessage('Unable to open log file ' + LogFileName);
         //        WaitForKeyPressed;
      end;
   I := NumberQSOs;
   if QTCEnable then Dispose(QTCList);
end;

procedure CreateCabrilloFile;

var
   CabrilloFileName                : string;
   CabrilloFileWrite               : Text;

begin
   //    ClearScreenAndTitle ('CREATE CABRILLO FILE');

   //    WriteLn ('The Cabrillo format has been adopted by the ARRL and CQ and the preferred');
   //    WriteLn ('format for entry submission.  An entry consists of all of the necessary ');
   //    WriteLn ('data to submit your log - including summary sheet.');
   //    WriteLn;
   //    WriteLn ('This procedure will generate a Cabrillo file for the active log file.  It');
   //    WriteLn ('will be saved with the active file name prefix and .CBR as the suffix.');
   //    WriteLn;

   //    IF NOT OkayToProceed THEN Exit;

   CabrilloFileName := PrecedingString(LogFileName, '.') + '.CBR';
   //  LogFileName := ExtractFileDir(application.ExeName) + '\';
   if FileExists({ExtractFileDir(application.ExeName) + '\' + }CabrilloFileName) then
      if not OkayToDeleteExistingFile(CabrilloFileName) then Exit;

   //    exit;

   if not GenerateSummaryPortionOfCabrilloFile(CabrilloFileName, CabrilloFileWrite) then
      Exit;

   if not GenerateLogPortionOfCabrilloFile(CabrilloFileName, CabrilloFileWrite) then
      begin
         Close(CabrilloFileWrite);
         Exit;
      end;

   WriteLn(CabrilloFileWrite, 'END-OF-LOG: ');
   Close(CabrilloFileWrite);

   //  WriteLn;
   PostForm.cm.Lines.Add('Cabrillo sucessfully generated and saved as ' + CabrilloFileName);
   view(CabrilloFileName);
end;

begin
end.

