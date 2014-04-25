unit CFGCMD;

{$O+}
{$F+}

interface

uses {SlowTree,} Tree,
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
   Country9,
   LogEdit,
   LOGDDX,
   LOGHP,
   LOGWAE,
   LogPack,
   LogK1EA, {DOS, }
   LOGHELP,
   LOGPROM, {Crt, }
   K1EANET,
   LogNet,
   LogRadio;

function ProcessConfigInstruction(var FileString: string; var FirstCommand: boolean): boolean;

procedure SniffOutControlCharacters(var TempString: string);

var
   ConfigFileRead                  : Text;
   ClearDupeSheetCommandGiven      : boolean;
   RunningConfigFile               : boolean; { True when using Control-V command }

   //const

implementation

//{WLI}{$I ColorCfg}
//{WLI}{$I PostCfg}

uses POSTCFG,
   //   Settings_unit,
   Unit1;

procedure SniffOutControlCharacters(var TempString: string);

var
   NumericString                   : Str20;
   StringLength, NumericValue, Result: integer;

begin
   if TempString = '' then Exit;

   StringLength := length(TempString);

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

function ProcessConfigInstructions1(ID: Str80; CMD: string): boolean;

var
   Result1, Speed, TempValue       : integer;
   TempLongInt                     : LONGINT;

begin
   ProcessConfigInstructions1 := False;

   //if ID = ALL_CW_MESSAGES_CHAINABLE then
   if ID = 'ALL CW MESSAGES CHAINABLE' then
      begin
         AllCWMessagesChainable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'ALT-D BUFFER ENABLE' then
      begin
         AltDBufferEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'ALWAYS CALL BLIND CQ' then
      begin
         AlwaysCallBlindCQ := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'ASK FOR FREQUENCIES' then
      begin
         AskForFrequencies := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'ASK IF CONTEST OVER' then
      begin
         AskIfContestOver := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'AUTO CALL TERMINATE' then
      begin
         AutoCallTerminate := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'AUTO ALT-D ENABLE' then
      begin
         AutoAltDEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'AUTO DISPLAY DUPE QSO' then
      begin
         AutoDisplayDupeQSO := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if {(ID = 'AUTO DUPE ENABLE') OR }(ID = 'AUTO DUPE ENABLE CQ') then
      begin
         AutoDupeEnableCQ := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'AUTO DUPE ENABLE S AND P' then
      begin
         AutoDupeEnableSandP := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;

         Exit;
      end;

   if ID = 'AUTO QSL INTERVAL' then
      begin
         Val(CMD, AutoQSLInterval, Result1);
         ProcessConfigInstructions1 := Result1 = 0;
         if Result1 = 0 then AutoQSLCount := AutoQSLInterval;
         Exit;
      end;

   if ID = 'AUTO QSO NUMBER DECREMENT' then
      begin
         AutoQSONumberDecrement := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'AUTO RETURN TO CQ MODE' then
      begin
         AutoReturnToCQMode := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         //Settings_form.Main_CheckListBox.
         //Checked[Settings_form.Main_CheckListBox.Items.IndexOf(id)]:=AutoReturnToCQMode;

         Exit;
      end;

   if ID = 'AUTO S&P ENABLE' then
      begin
         AutoSAPEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'AUTO S&P ENABLE SENSITIVITY' then {KK1L: 6.72}
      begin
         Val(CMD, AutoSAPEnableRate, Result1);
         ProcessConfigInstructions1 := Result1 = 0;
         if Result1 = 0 then
            begin
               if not ((AutoSAPEnableRate > 9) and (AutoSAPEnableRate < 10001)) then
                  AutoSAPEnableRate := 1000;
            end;
         Exit;
      end;

   if ID = 'AUTO SEND CHARACTER COUNT' then
      begin
         Val(CMD, AutoSendCharacterCount, Result1);
         DisplayAutoSendCharacterCount;
         ProcessConfigInstructions1 := Result1 = 0;
         Exit;
      end;

   if ID = 'AUTO TIME INCREMENT' then
      begin
         Val(CMD, AutoTimeIncrementQSOs, Result1);
         ProcessConfigInstructions1 := Result1 = 0;
         Exit;
      end;

   if ID = 'BACKCOPY ENABLE' then
      begin
         BackCopyEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BAND' then
      begin
         ActiveBand := NoBand;
         if CMD = '160' then ActiveBand := Band160;
         if CMD = '80' then ActiveBand := Band80;
         if CMD = '40' then ActiveBand := Band40;
         if CMD = '30' then ActiveBand := Band30;
         if CMD = '20' then ActiveBand := Band20;
         if CMD = '17' then ActiveBand := Band17;
         if CMD = '15' then ActiveBand := Band15;
         if CMD = '12' then ActiveBand := Band12;
         if CMD = '10' then ActiveBand := Band10;
         if CMD = '6' then ActiveBand := Band6;
         if CMD = '2' then ActiveBand := Band2;
         if CMD = '222' then ActiveBand := Band222;
         if CMD = '432' then ActiveBand := Band432;
         if CMD = '902' then ActiveBand := Band902;
         if CMD = '1GH' then ActiveBand := Band1296;
         if CMD = '2GH' then ActiveBand := Band2304;
         if CMD = '3GH' then ActiveBand := Band3456;
         if CMD = '5GH' then ActiveBand := Band5760;
         if CMD = '10G' then ActiveBand := Band10G;
         if CMD = '24G' then ActiveBand := Band24G;
         if CMD = 'LGT' then ActiveBand := BandLight;

         ProcessConfigInstructions1 := ActiveBand <> NoBand;
         Exit;
      end;

   if ID = 'BAND MAP ALL BANDS' then
      begin
         BandMapAllBands := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BAND MAP ALL MODES' then
      begin
         BandMapAllModes := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BAND MAP MULTS ONLY' then {KK1L: 6.68}
      begin
         BandMapMultsOnly := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BAND MAP CALL WINDOW ENABLE' then
      begin
         BandMapCallWindowEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BAND MAP CUTOFF FREQUENCY' then
      begin
         Val(CMD, TempLongInt, Result1);

         if Result1 = 0 then
            begin
               AddBandMapModeCutoffFrequency(TempLongInt);
               ProcessConfigInstructions1 := True;
            end;

         Exit;
      end;

   if ID = 'BAND MAP DECAY TIME' then
      begin
         Val(CMD, BandMapDecayValue, Result1);
         ProcessConfigInstructions1 := Result1 = 0;
         if Result1 = 0 then
            begin
               BandMapDecayMultiplier := (BandMapDecayValue div 64) + 1; {KK1L: 6.65}
               BandMapDecayTime := BandMapDecayValue div BandMapDecayMultiplier; {KK1L: 6.65}
            end;
         Exit;
      end;

   if ID = 'BAND MAP DISPLAY CQ' then
      begin
         BandMapDisplayCQ := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BAND MAP ENABLE' then
      begin
         BandMapEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         //Settings_form.Band_map_CheckListBox.
         //Checked[Settings_form.Band_map_CheckListBox.Items.IndexOf(id)]:=BandMapEnable;

         Exit;
      end;

   if ID = 'BAND MAP DUPE DISPLAY' then
      begin
         BandMapDupeDisplay := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BAND MAP GUARD BAND' then
      begin
         Val(CMD, BandMapGuardBand, Result1);
         ProcessConfigInstructions1 := Result1 = 0;
         Exit;
      end;

   if ID = 'BAND MAP SPLIT MODE' then
      begin
         CMD := UpperCase(CMD);

         if CMD = 'BY CUTOFF FREQ' then BandMapSplitMode := ByCutoffFrequency;
         if CMD = 'ALWAYS PHONE' then BandMapSplitMode := AlwaysPhone;

         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'BEEP ENABLE' then
      begin
         BeepEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;

         Exit;
      end;

   if ID = 'BEEP EVERY 10 QSOS' then
      begin
         BeepEvery10QSOs := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;

         Exit;
      end;

   {   if ID = 'BIG REMAINING LIST' then
         begin
            BigRemainingList := UpCase(CMD[1]) = 'T';
            if not CountryTable.CustomRemainingCountryListFound then
               CountryTable.MakeDefaultRemainingCountryList;
            ProcessConfigInstructions1 := true;
            Exit;
         end;
   }
   if ID = 'BROADCAST ALL PACKET DATA' then
      begin
         Packet.BroadcastAllPacketData := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if (ID = 'CALL OK NOW MESSAGE') or (ID = 'CALL OK NOW CW MESSAGE') then
      begin
         CorrectedCallMessage := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CALL OK NOW SSB MESSAGE' then
      begin
         CorrectedCallPhoneMessage := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CALL WINDOW SHOW ALL SPOTS' then
      begin
         CallWindowShowAllSpots := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CALL WINDOW POSITION' then
      begin
         CallWindowPosition := NormalCallWindowPosition;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'UP') then CallWindowPosition := UpOneCallWindowPosition;
         ProcessConfigInstructions1 := True;
      end;

   if ID = 'CALLSIGN UPDATE ENABLE' then
      begin
         CallsignUpdateEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CHECK LOG FILE SIZE' then
      begin
         CheckLogFileSize := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CLEAR DUPE SHEET' then
      begin
         if (UpCase(CMD[1]) = 'T') and RunningConfigFile then
            ClearDupeSheetCommandGiven := True;

         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CODE SPEED' then
      begin
         if StringIsAllNumbers(CMD) then
            begin
               Val(CMD, Speed, Result1);
               if Result1 = 0 then
                  begin
                     CodeSpeed := Speed;
                     ProcessConfigInstructions1 := True;
                  end;
            end;
         Exit;
      end;

   {   if ID = 'COLUMN DUPESHEET ENABLE' then
         begin
            ColumnDupeSheetEnable := UpCase(CMD[1]) = 'T';
            ProcessConfigInstructions1 := True;
            Exit;
         end;
   }
   if ID = 'COMPUTER ID' then
      begin
         CMD := UpperCase(CMD);

         if CMD = 'NONE' then
            ComputerID := CHR(0)
         else
            if CMD <> '' then
               begin
                  if (CMD[1] >= 'A') and (CMD[1] <= 'Z') then
                     ComputerID := CMD[1];
               end
            else
               ComputerID := CHR(0);

         ProcessConfigInstructions1 := True;
         Exit;
      end;

   {   if ID = 'CONFIRM EDIT CHANGES' then
         begin
            ConfirmEditChanges := UpCase(CMD[1]) = 'T';
            ProcessConfigInstructions1 := true;
            exit;
         end;
   }
{
   if ID = 'COPY FILES' then
      begin
         CopyFiles(RemoveFirstString(CMD), RemoveFirstString(CMD), RemoveFirstString(CMD));
         ProcessConfigInstructions1 := True;
         Exit;
      end;
}
   if ID = 'COUNT DOMESTIC COUNTRIES' then
      begin
         CountDomesticCountries := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'COUNTRY INFORMATION FILE' then
      begin
         CountryInformationFile := CMD;
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if (ID = 'CQ EXCHANGE') or (ID = 'CQ CW EXCHANGE') then
      begin
         CQExchange := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CQ SSB EXCHANGE' then
      begin
         CQPhoneExchange := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if (ID = 'CQ EXCHANGE NAME KNOWN') or (ID = 'CQ CW EXCHANGE NAME KNOWN') then
      begin
         CQExchangeNameKnown := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CQ SSB EXCHANGE NAME KNOWN' then
      begin
         CQPhoneExchangeNameKnown := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if StringHas(ID, 'CQ MEMORY F') or StringHas(ID, 'CQ CW MEMORY F') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'MEMORY F');

         if ID = '1' then
            begin
               SetCQMemoryString(CW, F1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetCQMemoryString(CW, F2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetCQMemoryString(CW, F3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetCQMemoryString(CW, F4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetCQMemoryString(CW, F5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetCQMemoryString(CW, F6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetCQMemoryString(CW, F7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetCQMemoryString(CW, F8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetCQMemoryString(CW, F9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetCQMemoryString(CW, F10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetCQMemoryString(CW, F11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetCQMemoryString(CW, F12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'CQ MEMORY ALTF') or StringHas(ID, 'CQ CW MEMORY ALTF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'ALTF');

         if ID = '1' then
            begin
               SetCQMemoryString(CW, AltF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetCQMemoryString(CW, AltF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetCQMemoryString(CW, AltF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetCQMemoryString(CW, AltF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetCQMemoryString(CW, AltF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetCQMemoryString(CW, AltF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetCQMemoryString(CW, AltF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetCQMemoryString(CW, AltF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetCQMemoryString(CW, AltF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetCQMemoryString(CW, AltF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetCQMemoryString(CW, AltF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetCQMemoryString(CW, AltF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'CQ MEMORY CONTROLF') or StringHas(ID, 'CQ CW MEMORY CONTROLF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'CONTROLF');

         if ID = '1' then
            begin
               SetCQMemoryString(CW, ControlF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetCQMemoryString(CW, ControlF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetCQMemoryString(CW, ControlF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetCQMemoryString(CW, ControlF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetCQMemoryString(CW, ControlF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetCQMemoryString(CW, ControlF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetCQMemoryString(CW, ControlF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetCQMemoryString(CW, ControlF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetCQMemoryString(CW, ControlF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetCQMemoryString(CW, ControlF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetCQMemoryString(CW, ControlF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetCQMemoryString(CW, ControlF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'CQ SSB MEMORY F') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'MEMORY F');

         if ID = '1' then
            begin
               SetCQMemoryString(Phone, F1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetCQMemoryString(Phone, F2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetCQMemoryString(Phone, F3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetCQMemoryString(Phone, F4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetCQMemoryString(Phone, F5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetCQMemoryString(Phone, F6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetCQMemoryString(Phone, F7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetCQMemoryString(Phone, F8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetCQMemoryString(Phone, F9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetCQMemoryString(Phone, F10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetCQMemoryString(Phone, F11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetCQMemoryString(Phone, F12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'CQ SSB MEMORY ALTF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'ALTF');

         if ID = '1' then
            begin
               SetCQMemoryString(Phone, AltF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetCQMemoryString(Phone, AltF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetCQMemoryString(Phone, AltF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetCQMemoryString(Phone, AltF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetCQMemoryString(Phone, AltF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetCQMemoryString(Phone, AltF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetCQMemoryString(Phone, AltF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetCQMemoryString(Phone, AltF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetCQMemoryString(Phone, AltF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetCQMemoryString(Phone, AltF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetCQMemoryString(Phone, AltF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetCQMemoryString(Phone, AltF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'CQ SSB MEMORY CONTROLF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'CONTROLF');

         if ID = '1' then
            begin
               SetCQMemoryString(Phone, ControlF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetCQMemoryString(Phone, ControlF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetCQMemoryString(Phone, ControlF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetCQMemoryString(Phone, ControlF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetCQMemoryString(Phone, ControlF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetCQMemoryString(Phone, ControlF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetCQMemoryString(Phone, ControlF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetCQMemoryString(Phone, ControlF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetCQMemoryString(Phone, ControlF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetCQMemoryString(Phone, ControlF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetCQMemoryString(Phone, ControlF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetCQMemoryString(Phone, ControlF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   {   if ID = 'CQ MENU' then
         begin
            Delete(CMD, 80, 100); //KK1L: 6.65 limits CMD to size of ExchangeFunctionKeyMenu
            CQMenu := CMD;
            ProcessConfigInstructions1 := true;
            exit;
         end;
   }
   if ID = 'CURTIS KEYER MODE' then
      begin
         CPUKeyer.CurtisModeA := UpperCase(CMD) = 'A';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CUSTOM INITIAL EXCHANGE STRING' then
      begin
         CustomInitialExchangeString := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CUSTOM USER STRING' then
      begin
         CustomUserString := UpperCase(CMD);
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CW ENABLE' then
      begin
         CWEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CW SPEED FROM DATABASE' then
      begin
         CWSpeedFromDataBase := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'CW SPEED INCREMENT' then {KK1L: 6.72}
      begin
         Val(CMD, TempValue, Result1);
         if (TempValue > 0) and (TempValue < 11) then
            begin
               CodeSpeedIncrement := TempValue;
               ProcessConfigInstructions1 := True;
            end;
         Exit;
      end;

   if ID = 'CW TONE' then
      begin
         Val(CMD, TempValue, Result1);
         if Result1 = 0 then
            begin
               CWTone := TempValue;
               ProcessConfigInstructions1 := True;
            end;
         Exit;
      end;

   if ID = 'DE ENABLE' then
      begin
         DEEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'DIGITAL MODE ENABLE' then
      begin
         DigitalModeEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'DISPLAY BAND MAP ENABLE' then {KK1L: 6.73 Supress display of BM but keep function}
      begin
         DisplayBandMapEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'DISPLAY MODE' then
      begin
         if UpperCase(CMD) = 'COLOR' then
            begin
               DoingColors := True;
               SelectedColors := ColorColors;
               ProcessConfigInstructions1 := True;
            end;

         if UpperCase(CMD) = 'MONO' then
            begin
               DoingColors := False;
               SelectedColors := MonoColors;
               ProcessConfigInstructions1 := True;
            end;
         Exit;
      end;

   if ID = 'DISTANCE MODE' then
      begin
         DistanceMode := NoDistanceDisplay;

         CMD := UpperCase(CMD);

         if CMD = 'MILES' then DistanceMode := DistanceMiles;
         if CMD = 'KM' then DistanceMode := DistanceKM;

         ProcessConfigInstructions1 := (DistanceMode <> NoDistanceDisplay) or (CMD = 'NONE');
      end;

   {   if ID = 'DVK PORT' then
         begin
            ActiveDVKPort := NoPort;
            CMD := UpperCase(CMD);

            if CMD = '1' then ActiveDVKPort := Parallel1;
            if CMD = '2' then ActiveDVKPort := Parallel2;
            if CMD = '3' then ActiveDVKPort := Parallel3;

            if ActiveDVKPort <> NoPort then
               begin
                  SetCQMemoryString(Phone, F1, 'DVK1');
                  SetCQMemoryString(Phone, F2, 'DVK2');
                  SetCQMemoryString(Phone, F3, 'DVK3');
                  SetCQMemoryString(Phone, F4, 'DVK4');
                  SetCQMemoryString(Phone, F5, '');
                  SetCQMemoryString(Phone, F6, '');
                  SetCQMemoryString(Phone, F7, '');
                  SetCQMemoryString(Phone, F8, '');
                  SetCQMemoryString(Phone, F9, '');
                  SetCQMemoryString(Phone, F10, 'DVK0');

                  SetEXMemoryString(Phone, F1, '');
                  SetEXMemoryString(Phone, F2, '');
                  SetEXMemoryString(Phone, F3, '');
                  SetEXMemoryString(Phone, F4, '');
                  SetEXMemoryString(Phone, F5, '');
                  SetEXMemoryString(Phone, F6, '');
                  SetEXMemoryString(Phone, F7, '');
                  SetEXMemoryString(Phone, F8, '');
                  SetEXMemoryString(Phone, F9, '');
                  SetCQMemoryString(Phone, F10, 'DVK0');

                  CorrectedCallPhoneMessage := '';
                  CQPhoneExchange := '';
                  CQPhoneExchangeNameKnown := '';
                  QSLPhoneMessage := '';
                  QSOBeforePhoneMessage := '';
                  QuickQSLPhoneMessage := '';
                  RepeatSearchAndPouncePhoneExchange := '';
                  SearchAndPouncePhoneExchange := '';

                  SetEXMemoryString(Phone, AltF1, '');
                  SetEXMemoryString(Phone, AltF2, '');
                  SetEXMemoryString(Phone, AltF3, '');
                  SetEXMemoryString(Phone, AltF4, '');
                  SetEXMemoryString(Phone, AltF5, '');
                  SetEXMemoryString(Phone, AltF6, '');
                  SetEXMemoryString(Phone, AltF7, '');
                  SetEXMemoryString(Phone, AltF8, '');
                  SetEXMemoryString(Phone, AltF9, '');
                  SetEXMemoryString(Phone, AltF10, '');

                  DVPOn := true;
               end;

            ProcessConfigInstructions1 := (ActiveDVKPort <> NoPort) or (CMD = 'NONE');
            Exit;
         end;
   }
   if ID = 'DUPE CHECK SOUND' then
      begin
         CMD := UpperCase(CMD);

         if CMD = 'NONE' then DupeCheckSound := DupeCheckNoSound;
         if CMD = 'DUPE BEEP' then DupeCheckSound := DupeCheckBeepIfDupe;
         if CMD = 'MULT FANFARE' then DupeCheckSound := DupeCheckGratsIfMult;

         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'DUPE SHEET ENABLE' then
      begin
         Sheet.DupeSheetEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if ID = 'DVP ENABLE' then
      begin
         DVPEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   {   if ID = 'DVP PATH' then
         begin
            CfgDvpPath := CMD;
            ProcessConfigInstructions1 := true;
            Exit;
         end;
   }
   if ID = 'EIGHT BIT PACKET PORT' then
      begin
         if UpCase(CMD[1]) = 'T' then
            Packet.PacketNumberBits := 8;

         ProcessConfigInstructions1 := True;
         Exit;
      end;

   {   if ID = 'EIGHT BIT RTTY PORT' then //KK1L: 6.71 Added for George Fremin's RTTY modem
         begin
            EightBitRTTYPort := UpCase(CMD[1]) = 'T';
            ProcessConfigInstructions1 := true;
            Exit;
         end;
   }
   //   if (ID = 'ESCAPE EXITS SEARCH AND POUNCE MODE') or
   if (ID = 'ESCAPE EXITS SEARCH AND POUNCE') then
      begin
         EscapeExitsSearchAndPounce := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;

   if StringHas(ID, 'EX MEMORY F') or StringHas(ID, 'EX CW MEMORY F') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'MEMORY F');

         if ID = '3' then
            begin
               SetEXMemoryString(CW, F3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetEXMemoryString(CW, F4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetEXMemoryString(CW, F5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetEXMemoryString(CW, F6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetEXMemoryString(CW, F7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetEXMemoryString(CW, F8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetEXMemoryString(CW, F9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetEXMemoryString(CW, F10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetEXMemoryString(CW, F11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetEXMemoryString(CW, F12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'EX MEMORY ALTF') or StringHas(ID, 'EX CW MEMORY ALTF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'ALTF');

         if ID = '1' then
            begin
               SetEXMemoryString(CW, AltF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetEXMemoryString(CW, AltF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetEXMemoryString(CW, AltF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetEXMemoryString(CW, AltF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetEXMemoryString(CW, AltF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetEXMemoryString(CW, AltF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetEXMemoryString(CW, AltF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetEXMemoryString(CW, AltF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetEXMemoryString(CW, AltF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetEXMemoryString(CW, AltF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetEXMemoryString(CW, AltF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetEXMemoryString(CW, AltF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'EX MEMORY CONTROLF') or StringHas(ID, 'EX CW MEMORY CONTROLF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'CONTROLF');

         if ID = '1' then
            begin
               SetEXMemoryString(CW, ControlF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetEXMemoryString(CW, ControlF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetEXMemoryString(CW, ControlF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetEXMemoryString(CW, ControlF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetEXMemoryString(CW, ControlF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetEXMemoryString(CW, ControlF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetEXMemoryString(CW, ControlF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetEXMemoryString(CW, ControlF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetEXMemoryString(CW, ControlF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetEXMemoryString(CW, ControlF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetEXMemoryString(CW, ControlF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetEXMemoryString(CW, ControlF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'EX SSB MEMORY F') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'MEMORY F');

         if ID = '1' then
            begin
               SetEXMemoryString(Phone, F1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetEXMemoryString(Phone, F2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetEXMemoryString(Phone, F3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetEXMemoryString(Phone, F4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetEXMemoryString(Phone, F5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetEXMemoryString(Phone, F6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetEXMemoryString(Phone, F7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetEXMemoryString(Phone, F8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetEXMemoryString(Phone, F9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetEXMemoryString(Phone, F10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetEXMemoryString(Phone, F11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetEXMemoryString(Phone, F12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'EX SSB MEMORY ALTF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'ALTF');

         if ID = '1' then
            begin
               SetEXMemoryString(Phone, AltF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetEXMemoryString(Phone, AltF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetEXMemoryString(Phone, AltF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetEXMemoryString(Phone, AltF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetEXMemoryString(Phone, AltF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetEXMemoryString(Phone, AltF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetEXMemoryString(Phone, AltF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetEXMemoryString(Phone, AltF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetEXMemoryString(Phone, AltF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetEXMemoryString(Phone, AltF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetEXMemoryString(Phone, AltF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetEXMemoryString(Phone, AltF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   if StringHas(ID, 'EX SSB MEMORY CONTROLF') then
      begin
         ProcessConfigInstructions1 := True;
         SniffOutControlCharacters(CMD);
         ID := PostcedingString(ID, 'CONTROLF');

         if ID = '1' then
            begin
               SetEXMemoryString(Phone, ControlF1, CMD);
               Exit;
            end;
         if ID = '2' then
            begin
               SetEXMemoryString(Phone, ControlF2, CMD);
               Exit;
            end;
         if ID = '3' then
            begin
               SetEXMemoryString(Phone, ControlF3, CMD);
               Exit;
            end;
         if ID = '4' then
            begin
               SetEXMemoryString(Phone, ControlF4, CMD);
               Exit;
            end;
         if ID = '5' then
            begin
               SetEXMemoryString(Phone, ControlF5, CMD);
               Exit;
            end;
         if ID = '6' then
            begin
               SetEXMemoryString(Phone, ControlF6, CMD);
               Exit;
            end;
         if ID = '7' then
            begin
               SetEXMemoryString(Phone, ControlF7, CMD);
               Exit;
            end;
         if ID = '8' then
            begin
               SetEXMemoryString(Phone, ControlF8, CMD);
               Exit;
            end;
         if ID = '9' then
            begin
               SetEXMemoryString(Phone, ControlF9, CMD);
               Exit;
            end;
         if ID = '10' then
            begin
               SetEXMemoryString(Phone, ControlF10, CMD);
               Exit;
            end;
         if ID = '11' then
            begin
               SetEXMemoryString(Phone, ControlF11, CMD);
               Exit;
            end;
         if ID = '12' then
            begin
               SetEXMemoryString(Phone, ControlF12, CMD);
               Exit;
            end;

         ProcessConfigInstructions1 := False;
         Exit;
      end;

   {   if ID = 'EX MENU' then
         begin
            Delete(CMD, 80, 100); //KK1L: 6.65 limits CMD to size of ExchangeFunctionKeyMenu
            ExchangeFunctionKeyMenu := CMD;
            ProcessConfigInstructions1 := true;
            exit;
         end;
   }
   if ID = 'EXCHANGE MEMORY ENABLE' then
      begin
         ExchangeMemoryEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions1 := True;
         Exit;
      end;
end;

function ProcessConfigInstructions2(ID: Str80; CMD: Str20 {STRING}): boolean;

var
   Result1                         : integer;
   TimeString, DateString, DayString: Str20;
   TempFreq, TempLongInt           : LONGINT;
   TempBand                        : BandType;
   TempMode                        : ModeType;

begin
   ProcessConfigInstructions2 := False;

   if ID = 'FARNSWORTH ENABLE' then
      begin
         FarnsworthEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'FARNSWORTH SPEED' then
      begin
         Val(CMD, FarnsworthSpeed, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   {   if ID = 'FILTER RADIO MESSAGE LENGTH' then
         begin
            if UpCase(CMD[1]) = 'T' then
               begin
                  Radio1.FilterRadioMessageLength := true;
                  Radio2.FilterRadioMessageLength := true;
               end;

            ProcessConfigInstructions2 := true;
            Exit;
         end;
   }
   if ID = 'FLOPPY FILE SAVE FREQUENCY' then
      begin
         Val(CMD, FloppyFileSaveFrequency, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'FLOPPY FILE SAVE NAME' then
      begin
         FloppyFileSaveName := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'FOOT SWITCH MODE' then
      begin
         FootSwitchMode := FootSwitchDisabled;
         CMD := UpperCase(CMD);

         if CMD = 'NORMAL' then FootSwitchMode := Normal;
         if CMD = 'F1' then FootSwitchMode := FootSwitchF1;
         if CMD = 'LAST CQ FREQ' then FootSwitchMode := FootSwitchLastCQFreq;
         if CMD = 'NEXT BANDMAP' then FootSwitchMode := FootSwitchNextBandMap;
         if CMD = 'NEXT DISP BANDMAP' then FootSwitchMode := FootSwitchNextDisplayedBandMap; {KK1L: 6.64}
         if CMD = 'NEXT MULT BANDMAP' then FootSwitchMode := FootSwitchNextMultBandMap; {KK1L: 6.68}
         if CMD = 'NEXT MULT DISP BANDMAP' then FootSwitchMode := FootSwitchNextMultDisplayedBandMap; {KK1L: 6.68}
         if CMD = 'DUPE CHECK' then FootSwitchMode := FootSwitchDupecheck;
         if CMD = 'DUPECHECK' then FootSwitchMode := FootSwitchDupecheck;
         if CMD = 'QSO NORMAL' then FootSwitchMode := QSONormal;
         if CMD = 'QSO QUICK' then FootSwitchMode := QSOQuick;
         if CMD = 'CONTROL ENTER' then FootSwitchMode := FootSwitchControlEnter;
         if CMD = 'START SENDING' then FootSwitchMode := StartSending;
         if CMD = 'SWAP RADIOS' then FootSwitchMode := SwapRadio;
         if CMD = 'CW GRANT' then FootSwitchMode := CWGrant;

         ProcessConfigInstructions2 := (FootSwitchMode <> FootSwitchDisabled) or
            (CMD = 'DISABLED');
         Exit;
      end;

   if ID = 'FOOT SWITCH PORT' then
      begin
         ActiveFootSwitchPort := NoPort;
         CMD := UpperCase(CMD);

         if CMD = '1' then ActiveFootSwitchPort := Parallel1;
         if CMD = '2' then ActiveFootSwitchPort := Parallel2;
         if CMD = '3' then ActiveFootSwitchPort := Parallel3;

         ProcessConfigInstructions2 := (ActiveFootSwitchPort <> NoPort) or
            (CMD = 'NONE');
         Exit;
      end;

   if ID = 'FREQUENCY ADDER' then
      begin
         Val(CMD, Radio1.FrequencyAdder, Result1);
         Radio2.FrequencyAdder := Radio1.FrequencyAdder;
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if (ID = ('FREQUENCY ADDER RADIO ONE')) or
      (ID = ('RADIO ONE FREQUENCY ADDER')) then
      begin
         Val(CMD, Radio1.FrequencyAdder, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if (ID = ('FREQUENCY ADDER RADIO TWO')) or
      (ID = ('RADIO TWO FREQUENCY ADDER')) then
      begin
         Val(CMD, Radio2.FrequencyAdder, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'FREQUENCY MEMORY' then
      begin
         if StringHas(CMD, 'SSB') then
            begin
               Delete(CMD, pos('SSB ', CMD), 4);

               Val(CMD, TempFreq, Result1);

               if Result1 = 0 then
                  begin
                     CalculateBandMode(TempFreq, TempBand, TempMode);
                     FreqMemory[TempBand, Phone] := TempFreq;
                     ProcessConfigInstructions2 := True;
                     Exit;
                  end;
            end
         else
            begin
               Val(CMD, TempFreq, Result1);

               if Result1 = 0 then
                  begin
                     CalculateBandMode(TempFreq, TempBand, TempMode);
                     FreqMemory[TempBand, TempMode] := TempFreq;
                     ProcessConfigInstructions2 := True;
                  end;
            end;

         Exit;
      end;

   if ID = 'FREQUENCY MEMORY ENABLE' then
      begin
         FrequencyMemoryEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   {KK1L: 6.71}
   if ID = 'FREQUENCY POLL RATE' then
      begin
         Val(CMD, TempLongInt, Result1);
         if (TempLongInt >= 10) and (TempLongInt <= 1000) then {KK1L: 6.72}
            FreqPollRate := TempLongInt
         else
            FreqPollRate := 250; {KK1L: 6.73 Better resutls with Icom and other radios.}
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'FT1000MP CW REVERSE' then
      begin
         Radio1.FT1000MPCWReverse := UpCase(CMD[1]) = 'T';
         Radio2.FT1000MPCWReverse := Radio1.FT1000MPCWReverse;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'GRID MAP CENTER' then
      begin
         if LooksLikeAGrid(CMD) or (CMD = '') then
            begin
               GridMapCenter := Copy(CMD, 1, 4);
               ProcessConfigInstructions2 := True;
            end;
         Exit;
      end;

   if ID = 'HF BAND ENABLE' then
      begin
         HFBandEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'HOUR DISPLAY' then
      begin
         if UpperCase(CMD) = 'THIS HOUR' then HourDisplay := ThisHour;
         if UpperCase(CMD) = 'LAST SIXTY MINUTES' then HourDisplay := LastSixtyMins;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'HOUR OFFSET' then
      begin
         Val(CMD, HourOffset, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'INCREMENT TIME ENABLE' then
      begin
         IncrementTimeEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'INITIAL EXCHANGE' then
      begin
         if UpperCase(CMD) = 'NONE' then
            begin
               ActiveInitialExchange := NoInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'CUSTOM' then
            begin
               ActiveInitialExchange := CustomInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'NAME' then
            begin
               ActiveInitialExchange := NameInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'ZONE' then
            begin
               ActiveInitialExchange := ZoneInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'NAME QTH' then
            begin
               ActiveInitialExchange := NameQTHInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'CHECK SECTION' then
            begin
               ActiveInitialExchange := CheckSectionInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'SECTION' then
            begin
               ActiveInitialExchange := SectionInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'QTH' then
            begin
               ActiveInitialExchange := QTHInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'GRID' then
            begin
               ActiveInitialExchange := GridInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'FOC NUMBER' then
            begin
               ActiveInitialExchange := FOCInitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'USER 1' then
            begin
               ActiveInitialExchange := User1InitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'USER 2' then
            begin
               ActiveInitialExchange := User2InitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'USER 3' then
            begin
               ActiveInitialExchange := User3InitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'USER 4' then
            begin
               ActiveInitialExchange := User4InitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         if UpperCase(CMD) = 'USER 5' then
            begin
               ActiveInitialExchange := User5InitialExchange;
               ProcessConfigInstructions2 := True;
            end;

         Exit;
      end;

   if ID = 'INITIAL EXCHANGE FILENAME' then
      begin
         InitialExchangeFilename := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   {KK1L: 6.70}
   if ID = 'INITIAL EXCHANGE OVERWRITE' then
      begin
         InitialExchangeOverwrite := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;

         Exit;
      end;

   if ID = 'INITIAL EXCHANGE CURSOR POS' then
      begin
         if StringHas(UpperCase(CMD), 'END') then InitialExchangeCursorPos := AtEnd;
         if StringHas(UpperCase(CMD), 'START') then InitialExchangeCursorPos := AtStart;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'INSERT MODE' then
      begin
         InsertMode := UpCase(CMD[1]) = 'T';
         DisplayInsertMode(InsertMode);
         ProcessConfigInstructions2 := True;

         Exit;
      end;

   if ID = 'INTERCOM FILE ENABLE' then
      begin
         IntercomFileenable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'K1EA NETWORK ENABLE' then
      begin
         K1EANetworkEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'K1EA STATION ID' then
      begin
         K1EAStationID := UpCase(CMD[1]);
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'KEYER OUTPUT PORT' then
      begin
         RadioOneKeyerOutputPort := NoPort;
         CMD := UpperCase(CMD);

         if StringHas(CMD, 'SERIAL 1') then RadioOneKeyerOutputPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then RadioOneKeyerOutputPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then RadioOneKeyerOutputPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then RadioOneKeyerOutputPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then RadioOneKeyerOutputPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then RadioOneKeyerOutputPort := Serial6;

         if StringHas(CMD, 'PARALLEL 1') then RadioOneKeyerOutputPort := Parallel1;
         if StringHas(CMD, 'PARALLEL 2') then RadioOneKeyerOutputPort := Parallel2;
         if StringHas(CMD, 'PARALLEL 3') then RadioOneKeyerOutputPort := Parallel3;

         Radio1SerialInvert := StringHas(CMD, 'INVERT');
         Radio2SerialInvert := StringHas(CMD, 'INVERT');

         RadioTwoKeyerOutputPort := RadioOneKeyerOutputPort;
         ProcessConfigInstructions2 := (RadioOneKeyerOutputPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'KEYER RADIO ONE OUTPUT PORT' then
      begin
         RadioOneKeyerOutputPort := NoPort;
         CMD := UpperCase(CMD);

         if StringHas(CMD, 'SERIAL 1') then RadioOneKeyerOutputPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then RadioOneKeyerOutputPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then RadioOneKeyerOutputPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then RadioOneKeyerOutputPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then RadioOneKeyerOutputPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then RadioOneKeyerOutputPort := Serial6;

         if StringHas(CMD, 'PARALLEL 1') then RadioOneKeyerOutputPort := Parallel1;
         if StringHas(CMD, 'PARALLEL 2') then RadioOneKeyerOutputPort := Parallel2;
         if StringHas(CMD, 'PARALLEL 3') then RadioOneKeyerOutputPort := Parallel3;

         Radio1SerialInvert := StringHas(CMD, 'INVERT');

         ProcessConfigInstructions2 := (RadioOneKeyerOutputPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'KEYER RADIO TWO OUTPUT PORT' then
      begin
         RadioTwoKeyerOutputPort := NoPort;
         CMD := UpperCase(CMD);

         if StringHas(CMD, 'SERIAL 1') then RadioTwoKeyerOutputPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then RadioTwoKeyerOutputPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then RadioTwoKeyerOutputPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then RadioTwoKeyerOutputPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then RadioTwoKeyerOutputPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then RadioTwoKeyerOutputPort := Serial6;

         if StringHas(CMD, 'PARALLEL 1') then RadioTwoKeyerOutputPort := Parallel1;
         if StringHas(CMD, 'PARALLEL 2') then RadioTwoKeyerOutputPort := Parallel2;
         if StringHas(CMD, 'PARALLEL 3') then RadioTwoKeyerOutputPort := Parallel3;

         Radio2SerialInvert := StringHas(CMD, 'INVERT');

         ProcessConfigInstructions2 := (RadioTwoKeyerOutputPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'KEYPAD CW MEMORIES' then
      begin
         KeypadCWMemories := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'LEADING ZEROS' then
      begin
         CMD := UpperCase(CMD);

         if StringIsAllNumbers(CMD) then
            begin
               Val(CMD, LeadingZeros, Result1);
               ProcessConfigInstructions2 := (Result1 = 0) and
                  (LeadingZeros < 4) and
                  (LeadingZeros >= 0);
               Exit;
            end
         else
            if (CMD[1] = 'T') or (CMD[1] = 't') then
               LeadingZeros := 3
            else
               LeadingZeros := 0;

         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'LEADING ZERO CHARACTER' then
      begin
         LeadingZeroCharacter := UpCase(CMD[1]);
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'LEAVE CURSOR IN CALL WINDOW' then
      begin
         LeaveCursorInCallWindow := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;

         Exit;
      end;

   if ID = 'LITERAL DOMESTIC QTH' then
      begin
         LiteralDomesticQTH := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'LOG FREQUENCY ENABLE' then
      begin
         LogFrequencyEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;

         Exit;
      end;

   if ID = 'LOG RST SENT' then
      begin
         LogRSTSent := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'LOG RS SENT' then
      begin
         LogRSSent := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'LOG WITH SINGLE ENTER' then
      begin
         LogWithSingleEnter := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'LOOK FOR RST SENT' then
      begin
         LookForRSTSent := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'MESSAGE ENABLE' then
      begin
         MessageEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'MODE' then
      begin
         ActiveMode := NoMode;
         if (UpperCase(CMD) = 'SSB') or (UpperCase(CMD) = 'PHONE') then
            ActiveMode := Phone;
         if UpperCase(CMD) = 'CW' then ActiveMode := CW;
         ProcessConfigInstructions2 := ActiveMode <> NoMode;
         Exit;
      end;
   {
     if ID = 'MODEM PORT' then
     begin
       ActiveModemPort := NoPort;
       CMD := UpperCase(CMD);
       if StringHas(CMD, 'SERIAL 1') then ActiveModemPort := Serial1;
       if StringHas(CMD, 'SERIAL 2') then ActiveModemPort := Serial2;
       if StringHas(CMD, 'SERIAL 3') then ActiveModemPort := Serial3;
       if StringHas(CMD, 'SERIAL 4') then ActiveModemPort := Serial4;
       if StringHas(CMD, 'SERIAL 5') then ActiveModemPort := Serial5;
       if StringHas(CMD, 'SERIAL 6') then ActiveModemPort := Serial6;

       if StringHas(CMD, 'DRSI') then ActiveModemPort := DRSI;
       ProcessConfigInstructions2 := (ActiveModemPort <> NoPort) or (CMD = 'NONE');
       Exit;
     end;

     if ID = 'MODEM PORT BAUD RATE' then
     begin
       Val(CMD, ModemPortBaudRate, Result1);
       ProcessConfigInstructions2 := (Result1 = 0) and (ModemPortBaudRate <= 4800);
       Exit;
     end;

     if ID = 'MOUSE ENABLE' then
     begin
       MouseEnable := UpCase(CMD[1]) = 'T';
       ProcessConfigInstructions2 := True;
       Exit;
     end;
   }
   if (ID = 'MULT REPORT MINIMUM BANDS') or (ID = 'MULT REPORT MINIMUM COUNTRIES') then
      begin
         Val(CMD, MultReportMinimumBands, Result1);
         ProcessConfigInstructions2 := (Result1 = 0) and
            (MultReportMinimumBands < 6) and
            (MultReportMinimumBands >= 2);
         Exit;
      end;

   if ID = 'MULTI INFO MESSAGE' then
      begin
         MultiInfoMessage := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'MULTI MULTS ONLY' then
      begin
         MultiMultsOnly := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'MULTI PORT' then
      begin
         ActiveMultiPort := NoPort;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'SERIAL 1') then ActiveMultiPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then ActiveMultiPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then ActiveMultiPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then ActiveMultiPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then ActiveMultiPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then ActiveMultiPort := Serial6;

         if ActiveMultiPort <> NoPort then Packet.PacketBandSpots := True;
         ProcessConfigInstructions2 := (ActiveMultiPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'MULTI PORT BAUD RATE' then
      begin
         Val(CMD, MultiPortBaudRate, Result1);
         ProcessConfigInstructions2 := (Result1 = 0) and (MultiPortBaudRate <= 4800);
         Exit;
      end;

   if ID = 'MULTI RETRY TIME' then
      begin
         Val(CMD, MultiRetryTime, Result1);
         ProcessConfigInstructions2 := (Result1 = 0) and (MultiRetryTime >= 3);
         Exit;
      end;

   if ID = 'MULTI UPDATE MULT DISPLAY' then
      begin
         MultiUpdateMultDisplay := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'MULTIPLE BANDS' then
      begin
         MultipleBandsEnabled := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;

         Exit;
      end;

   if ID = 'MULTIPLE MODES' then
      begin
         MultipleModesEnabled := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;

         Exit;
      end;

   if ID = 'MY GRID' then
      begin
         MyGrid := UpperCase(CMD);
         ProcessConfigInstructions2 := LooksLikeAGrid(MyGrid);
         Exit;
      end;

   if ID = 'MY IOTA' then
      begin
         MyIOTA := UpperCase(CMD);
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'NAME FLAG ENABLE' then
      begin
         NameFlagEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'NO LOG' then
      begin
         NoLog := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;
   {
     if ID = 'NO POLL DURING PTT' then
     begin
       NoPollDuringPTT := UpCase(CMD[1]) = 'T';
       ProcessConfigInstructions2 := True;
       Exit;
     end;
   }
   if ID = 'ORION PORT' then
      begin
         ActiveRotatorType := OrionRotator;

         ActiveRotatorPort := NoPort;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'SERIAL 1') then ActiveRotatorPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then ActiveRotatorPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then ActiveRotatorPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then ActiveRotatorPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then ActiveRotatorPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then ActiveRotatorPort := Serial6;

         ProcessConfigInstructions2 := (ActiveRotatorPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'PACKET ADD LF' then
      begin
         PacketAddLF := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET AUTO CR' then
      begin
         PacketAutoCR := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET BAND SPOTS' then
      begin
         Packet.PacketBandSpots := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET BAUD RATE' then
      begin
         Val(CMD, Packet.PacketBaudRate, Result1);
         ProcessConfigInstructions2 := (Result1 = 0) and (Packet.PacketBaudRate <= 9600);
         Exit;
      end;

   if ID = 'PACKET BEEP' then
      begin
         Packet.PacketBeep := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET LOG FILENAME' then
      begin
         Packet.PacketLogFileName := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET PORT' then
      begin
         Packet.PacketSerialPort := NoPort;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'SERIAL 1') then Packet.PacketSerialPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then Packet.PacketSerialPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then Packet.PacketSerialPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then Packet.PacketSerialPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then Packet.PacketSerialPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then Packet.PacketSerialPort := Serial6;

         if StringHas(CMD, 'DRSI') then Packet.PacketSerialPort := DRSI;
         ProcessConfigInstructions2 := (Packet.PacketSerialPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'PACKET PORT BAUD RATE' then
      begin
         Val(CMD, Packet.PacketBaudRate, Result1);
         ProcessConfigInstructions2 := (Result1 = 0) and (Packet.PacketBaudRate <= 4800);
         Exit;
      end;

   if ID = 'PACKET RETURN PER MINUTE' then
      begin
         Val(CMD, PacketReturnPerMinute, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'PACKET SPOT EDIT ENABLE' then
      begin
         PacketSpotEditEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET SPOT DISABLE' then
      begin
         PacketSpotDisable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET SPOT KEY' then
      begin
         PacketSpotKey := CMD[1];
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET SPOT PREFIX ONLY' then {KK1L: 6.72}
      begin
         PacketSpotPrefixOnly := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PACKET SPOTS' then
      begin
         CMD := UpperCase(Copy(CMD, 1, 1));

         if CMD = 'A' then
            begin
               Packet.PacketSpots := AllSpots;
               ProcessConfigInstructions2 := True;
            end
         else
            if CMD = 'M' then
               begin
                  Packet.PacketSpots := MultSpots;
                  ProcessConfigInstructions2 := True;
               end;
      end;

   if ID = 'PADDLE BUG ENABLE' then
      begin
         PaddleBug := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PADDLE MONITOR TONE' then
      begin
         Val(CMD, PaddleMonitorTone, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'PADDLE PORT' then
      begin
         ActivePaddlePort := NoPort;
         CMD := UpperCase(CMD);

         if CMD = '1' then
            begin
               ActivePaddlePort := Parallel1;
               //{WLI}            Port [LPT1BaseAddress + 6] := $0;
            end;

         if CMD = '2' then
            begin
               ActivePaddlePort := Parallel2;
               //{WLI}            Port [LPT2BaseAddress + 6] := 0;
            end;

         if CMD = '3' then
            begin
               ActivePaddlePort := Parallel3;
               //{WLI}            Port [LPT3BaseAddress + 6] := 0;
            end;

         ProcessConfigInstructions2 := (ActivePaddlePort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'PADDLE SPEED' then
      begin
         Val(CMD, PaddleSpeed, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'PADDLE PTT HOLD COUNT' then
      begin
         Val(CMD, PaddlePTTHoldCount, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'PARTIAL CALL ENABLE' then
      begin
         PartialCallEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;

         Exit;
      end;

   if ID = 'PARTIAL CALL LOAD LOG ENABLE' then
      begin
         PartialCallLoadLogEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'PARTIAL CALL MULT INFO ENABLE' then
      begin
         PartialCallMultsEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'POLL RADIO ONE' then {KK1L: 6.72}
      begin
         Radio1.PollingEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'POLL RADIO TWO' then {KK1L: 6.72}
      begin
         Radio2.PollingEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'POSSIBLE CALL ACCEPT KEY' then
      begin
         PossibleCallAcceptKey := CMD[1];
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'POSSIBLE CALL LEFT KEY' then
      begin
         PossibleCallLeftKey := CMD[1];
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'POSSIBLE CALL RIGHT KEY' then
      begin
         PossibleCallRightKey := CMD[1];
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'POSSIBLE CALLS' then
      begin
         PossibleCallEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'POSSIBLE CALL MODE' then
      begin
         if WRTC2002 then {KK1L: 6.69 Don't allow WRTC folks to get SCP data from TRMaster}
            begin
               CD.PossibleCallAction := LogOnly;
               ProcessConfigInstructions2 := True;
            end
         else
            begin
               if UpperCase(CMD) = 'ALL' then
                  begin
                     CD.PossibleCallAction := AnyCall;
                     ProcessConfigInstructions2 := True;
                  end;

               if StringHas(UpperCase(CMD), 'NAME') then
                  begin
                     CD.PossibleCallAction := OnlyCallsWithNames;
                     ProcessConfigInstructions2 := True;
                  end;

               if UpperCase(CMD) = 'LOG ONLY' then
                  begin
                     CD.PossibleCallAction := LogOnly;
                     ProcessConfigInstructions2 := True;
                  end;
            end;

         Exit;
      end;

   if ID = 'PREFIX INFO FILENAME' then
      begin
         PrefixInfoFileName := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;
   //W_L_I
   {   if ID = 'PRINTER ENABLE' then
         begin
            PrinterEnabled := UpCase(CMD[1]) = 'T';
            ProcessConfigInstructions2 := true;
            exit;
         end;
   }
   if ID = 'PTT ENABLE' then
      begin
         PTTEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if (ID = 'PTT TURN ON DELAY') then
      begin
         Val(CMD, PTTTurnOnDelay, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if (ID = 'QSL MESSAGE') or (ID = 'QSL CW MESSAGE') then
      begin
         QSLMessage := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QSL SSB MESSAGE' then
      begin
         QSLPhoneMessage := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QSL MODE' then
      begin
         ParameterOkayMode := NoParameterOkayMode;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'STAN') then ParameterOkayMode := Standard;

         if StringHas(CMD, 'BUT') then
            ParameterOkayMode := QSLButDoNotLog
         else
            if StringHas(CMD, 'QSL') then ParameterOkayMode := QSLAndLog;

         ProcessConfigInstructions2 := ParameterOkayMode <> NoParameterOkayMode;
         Exit;
      end;

   if (ID = 'QSO BEFORE MESSAGE') or (ID = 'QSO BEFORE CW MESSAGE') then
      begin
         QSOBeforeMessage := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QSO BEFORE SSB MESSAGE' then
      begin
         QSOBeforePhoneMessage := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QSO NUMBER BY BAND' then
      begin
         QSONumberByBand := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QSX ENABLE' then
      begin
         QSXEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QTC ENABLE' then
      begin
         QTCsEnabled := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QTC EXTRA SPACE' then
      begin
         QTCExtraSpace := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QTC MINUTES' then
      begin
         QTCMinutes := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QTC QRS' then
      begin
         QTCQRS := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QUESTION MARK CHAR' then
      begin
         QuestionMarkChar := CMD[1];
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if (ID = 'QUICK QSL KEY') or (ID = 'QUICK QSL KEY 1') then
      begin
         QuickQSLKey1 := CMD[1];
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QUICK QSL KEY 2' then
      begin
         QuickQSLKey2 := CMD[1];
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if (ID = 'QUICK QSL MESSAGE') or
      (ID = 'QUICK QSL CW MESSAGE') or
      (ID = 'QUICK QSL MESSAGE 1') or
      (ID = 'QUICK QSL CW MESSAGE 1') then
      begin
         QuickQSLMessage1 := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QUICK QSL MESSAGE 2' then
      begin
         QuickQSLMessage2 := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'QUICK QSL SSB MESSAGE' then
      begin
         QuickQSLPhoneMessage := CMD;
         ProcessConfigInstructions2 := True;
      end;

   if ID = 'RADIO ONE BAND OUTPUT PORT' then
      begin
         Radio1.BandOutputPort := NoPort;
         if CMD = '1' then Radio1.BandOutputPort := Parallel1;
         if CMD = '2' then Radio1.BandOutputPort := Parallel2;
         if CMD = '3' then Radio1.BandOutputPort := Parallel3;
         ProcessConfigInstructions2 := Radio1.BandOutputPort <> NoPort;
      end;

   if ID = 'RADIO TWO BAND OUTPUT PORT' then
      begin
         Radio2.BandOutputPort := NoPort;
         if CMD = '1' then Radio2.BandOutputPort := Parallel1;
         if CMD = '2' then Radio2.BandOutputPort := Parallel2;
         if CMD = '3' then Radio2.BandOutputPort := Parallel3;
         ProcessConfigInstructions2 := Radio2.BandOutputPort <> NoPort;
      end;

   if ID = 'RADIO ONE BAUD RATE' then
      begin
         Val(CMD, Radio1.RadioBaudRate, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIO TWO BAUD RATE' then
      begin
         Val(CMD, Radio2.RadioBaudRate, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIO ONE COMMAND PAUSE' then
      begin
         Val(CMD, Radio1.CommandPause, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIO TWO COMMAND PAUSE' then
      begin
         Val(CMD, Radio2.CommandPause, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIO ONE CONTROL PORT' then
      begin
         Radio1.RadioSerialPort := NoPort;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'SERIAL 1') then Radio1.RadioSerialPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then Radio1.RadioSerialPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then Radio1.RadioSerialPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then Radio1.RadioSerialPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then Radio1.RadioSerialPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then Radio1.RadioSerialPort := Serial6;

         ProcessConfigInstructions2 := (Radio1.RadioSerialPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'RADIO TWO CONTROL PORT' then
      begin
         Radio2.RadioSerialPort := NoPort;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'SERIAL 1') then Radio2.RadioSerialPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then Radio2.RadioSerialPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then Radio2.RadioSerialPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then Radio2.RadioSerialPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then Radio2.RadioSerialPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then Radio2.RadioSerialPort := Serial6;

         ProcessConfigInstructions2 := (Radio2.RadioSerialPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'RADIO ONE ID CHARACTER' then
      begin
         CMD := UpperCase(CMD);

         if CMD = 'NONE' then
            Radio1.IDCharacter := CHR(0)
         else
            if CMD <> '' then
               begin
                  if (CMD[1] >= 'A') and (CMD[1] <= 'Z') then
                     Radio1.IDCharacter := CMD[1];
               end
            else
               Radio1.IDCharacter := CHR(0);

         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RADIO TWO ID CHARACTER' then
      begin
         CMD := UpperCase(CMD);

         if CMD = 'NONE' then
            Radio2.IDCharacter := CHR(0)
         else
            if CMD <> '' then
               begin
                  if (CMD[1] >= 'A') and (CMD[1] <= 'Z') then
                     Radio2.IDCharacter := CMD[1];
               end
            else
               Radio2.IDCharacter := CHR(0);

         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RADIO ONE NAME' then
      begin
         //{WLI}        WHILE Length (CMD) < 7 DO
         //{WLI}            CMD := ' ' + CMD;

         //{WLI}        GetRidOfPostcedingSpaces (CMD);

         RadioOneName := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RADIO TWO NAME' then
      begin
         while length(CMD) < 7 do
            CMD := ' ' + CMD;

         //{WLI}        GetRidOfPostcedingSpaces (CMD);

         RadioTwoName := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RADIO ONE RECEIVER ADDRESS' then
      begin
         Val(CMD, Radio1.ReceiverAddress, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIO TWO RECEIVER ADDRESS' then
      begin
         Val(CMD, Radio2.ReceiverAddress, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIO ONE TRACKING ENABLE' then
      begin
         Radio1.TrackingEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RADIO TWO TRACKING ENABLE' then
      begin
         Radio2.TrackingEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RADIO ONE TYPE' then
      begin
         Radio1.RadioModel := NoInterfacedRadio;

         CMD := UpperCase(CMD);

         if pos(CMD, '-') > 0 then Delete(CMD, pos(CMD, '-'), 1);

         { No radios ending with A }

         if Copy(CMD, length(CMD), 1) = 'A' then
            Delete(CMD, length(CMD), 1);

         if Copy(CMD, 1, 2) = 'JS' then
            begin
               Radio1.RadioModel := JST245;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if Copy(CMD, 1, 2) = 'K2' then
            begin
               {Radio1.RadioModel := K2;}
               Radio1.RadioModel := TS850; {KK1L:6.73 missing "OR K2"s in TS850 statements in LOGSUBS2. Easier fix!}

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if Copy(CMD, 1, 2) = 'TS' then
            begin

               Radio1.RadioModel := TS850;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;

            end;

         if Copy(CMD, 1, 3) = 'FT1' then
            begin
               if StringHas(CMD, 'MP') then
                  Radio1.RadioModel := FT1000MP
               else
                  Radio1.RadioModel := FT1000;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if (CMD = 'FT840') or (CMD = 'FT890') or (CMD = 'FT900') then
            begin
               Radio1.RadioModel := FT890;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if CMD = 'FT920' then
            begin
               Radio1.RadioModel := FT920;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if CMD = 'FT100' then
            begin
               Radio1.RadioModel := FT100;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if (CMD = 'FT817') or (CMD = 'FT897') then {KK1L: 6.73 Added FT897 support. Reports say FT817 works well for it.}
            begin
               Radio1.RadioModel := FT817;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if CMD = 'FT847' then
            begin
               Radio1.RadioModel := FT847;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if CMD = 'FT990' then
            begin
               Radio1.RadioModel := FT990;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         {WLI,TNX UA9AM}
         if CMD = 'FTDX9000' then
            begin
               Radio1.RadioModel := FTDX9000;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 0
               else
                  Radio1.ControlDelay := 1;
            end;

         if Copy(CMD, 1, 2) = 'IC' then
            begin
               if CMD = 'IC706' then
                  begin
                     Radio1.RadioModel := IC706;
                     Radio1.ReceiverAddress := $48;
                  end;

               if CMD = 'IC706II' then
                  begin
                     Radio1.RadioModel := IC706II;
                     Radio1.ReceiverAddress := $4E;
                  end;

               if CMD = 'IC706IIG' then
                  begin
                     Radio1.RadioModel := IC706IIG;
                     Radio1.ReceiverAddress := $58;
                  end;

               if CMD = 'IC707' then
                  begin
                     Radio1.RadioModel := IC707;
                     Radio1.ReceiverAddress := $3E;
                  end;

               if CMD = 'IC725' then
                  begin
                     Radio1.RadioModel := IC725;
                     Radio1.ReceiverAddress := $28;
                  end;

               if CMD = 'IC726' then
                  begin
                     Radio1.RadioModel := IC726;
                     Radio1.ReceiverAddress := $30;
                  end;

               if CMD = 'IC728' then
                  begin
                     Radio1.RadioModel := IC728;
                     Radio1.ReceiverAddress := $38;
                  end;

               if CMD = 'IC729' then
                  begin
                     Radio1.RadioModel := IC729;
                     Radio1.ReceiverAddress := $3A;
                  end;

               if CMD = 'IC735' then
                  begin
                     Radio1.RadioModel := IC735;
                     Radio1.ReceiverAddress := $04;
                  end;

               if CMD = 'IC736' then
                  begin
                     Radio1.RadioModel := IC736;
                     Radio1.ReceiverAddress := $40;
                  end;

               if CMD = 'IC737' then
                  begin
                     Radio1.RadioModel := IC737;
                     Radio1.ReceiverAddress := $3C;
                  end;

               if CMD = 'IC738' then
                  begin
                     Radio1.RadioModel := IC738;
                     Radio1.ReceiverAddress := $44;
                  end;

               if CMD = 'IC746' then
                  begin
                     Radio1.RadioModel := IC746;
                     Radio1.ReceiverAddress := $56;
                  end;

               if CMD = 'IC746PRO' then
                  begin
                     Radio1.RadioModel := IC746PRO;
                     Radio1.ReceiverAddress := $56;
                  end;

               if CMD = 'IC756' then
                  begin
                     Radio1.RadioModel := IC756;
                     Radio1.ReceiverAddress := $50;
                  end;

               if CMD = 'IC756PRO' then
                  begin
                     Radio1.RadioModel := IC756PRO;
                     Radio1.ReceiverAddress := $5C;
                  end;

               if CMD = 'IC756PROII' then
                  begin
                     Radio1.RadioModel := IC756PROII;
                     Radio1.ReceiverAddress := $64;
                  end;

               if CMD = 'IC761' then
                  begin
                     Radio1.RadioModel := IC761;
                     Radio1.ReceiverAddress := $1E;
                  end;

               if CMD = 'IC765' then
                  begin
                     Radio1.RadioModel := IC765;
                     Radio1.ReceiverAddress := $2C;
                  end;

               if CMD = 'IC775' then
                  begin
                     Radio1.RadioModel := IC775;
                     Radio1.ReceiverAddress := $46;
                  end;

               if CMD = 'IC781' then
                  begin
                     Radio1.RadioModel := IC781;
                     Radio1.ReceiverAddress := $26;
                  end;

               if CPUKeyer.SlowInterrupts then
                  Radio1.ControlDelay := 4
               else
                  Radio1.ControlDelay := 8;
            end;

         {KK1L: 6.73 Added direct TenTec support}

         if StringHas(CMD, 'OMNI') then
            begin
               Radio1.RadioModel := OMNI6;
               Radio1.ReceiverAddress := $04;
            end;

         if CMD = 'ORION' then
            begin
               Radio1.RadioModel := Orion;
               Radio1.RadioBaudRate := 57600;
            end;

         if CMD = 'ARGO' then
            begin
               Radio1.RadioModel := ARGO;
               Radio1.ReceiverAddress := $04;
            end;

         ProcessConfigInstructions2 := (Radio1.RadioModel <> NoInterfacedRadio) or
            (CMD = 'NONE');
      end;

   if ID = 'RADIO TWO TYPE' then
      begin
         Radio2.RadioModel := NoInterfacedRadio;

         CMD := UpperCase(CMD);

         if pos(CMD, '-') > 0 then Delete(CMD, pos(CMD, '-'), 1);

         { No radios ending with A }

         if Copy(CMD, length(CMD), 1) = 'A' then
            Delete(CMD, length(CMD), 1);

         if Copy(CMD, 1, 2) = 'JS' then
            begin
               Radio2.RadioModel := JST245;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if Copy(CMD, 1, 2) = 'K2' then
            begin
               {Radio2.RadioModel := K2;}
               Radio2.RadioModel := TS850; {KK1L:6.73 missing "OR K2"s in TS850 statements in LOGSUBS2. Easier fix!}

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if Copy(CMD, 1, 2) = 'TS' then
            begin
               Radio2.RadioModel := TS850;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if Copy(CMD, 1, 3) = 'FT1' then
            begin
               if StringHas(CMD, 'MP') then
                  Radio2.RadioModel := FT1000MP
               else
                  Radio2.RadioModel := FT1000;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if (CMD = 'FT840') or (CMD = 'FT890') or (CMD = 'FT900') then
            begin
               Radio2.RadioModel := FT890;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if CMD = 'FT920' then
            begin
               Radio2.RadioModel := FT920;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if (CMD = 'FT817') or (CMD = 'FT897') then {KK1L: 6.73 Added FT897 support. Reports say FT817 works well for it.}
            begin
               Radio2.RadioModel := FT817;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if CMD = 'FT847' then
            begin
               Radio2.RadioModel := FT847;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if CMD = 'FT990' then
            begin
               Radio2.RadioModel := FT990;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 0
               else
                  Radio2.ControlDelay := 1;
            end;

         if Copy(CMD, 1, 2) = 'IC' then
            begin
               if CMD = 'IC706' then
                  begin
                     Radio2.RadioModel := IC706;
                     Radio2.ReceiverAddress := $48;
                  end;

               if CMD = 'IC706II' then
                  begin
                     Radio2.RadioModel := IC706II;
                     Radio2.ReceiverAddress := $4E;
                  end;

               if CMD = 'IC706IIG' then
                  begin
                     Radio2.RadioModel := IC706IIG;
                     Radio2.ReceiverAddress := $58;
                  end;

               if CMD = 'IC707' then
                  begin
                     Radio2.RadioModel := IC707;
                     Radio2.ReceiverAddress := $3E;
                  end;

               if CMD = 'IC725' then
                  begin
                     Radio2.RadioModel := IC725;
                     Radio2.ReceiverAddress := $28;
                  end;

               if CMD = 'IC726' then
                  begin
                     Radio2.RadioModel := IC726;
                     Radio2.ReceiverAddress := $30;
                  end;

               if CMD = 'IC728' then
                  begin
                     Radio2.RadioModel := IC728;
                     Radio2.ReceiverAddress := $38;
                  end;

               if CMD = 'IC729' then
                  begin
                     Radio2.RadioModel := IC729;
                     Radio2.ReceiverAddress := $3A;
                  end;

               if CMD = 'IC735' then
                  begin
                     Radio2.RadioModel := IC735;
                     Radio2.ReceiverAddress := $04;
                  end;

               if CMD = 'IC736' then
                  begin
                     Radio2.RadioModel := IC736;
                     Radio2.ReceiverAddress := $40;
                  end;

               if CMD = 'IC737' then
                  begin
                     Radio2.RadioModel := IC737;
                     Radio2.ReceiverAddress := $3C;
                  end;

               if CMD = 'IC738' then
                  begin
                     Radio2.RadioModel := IC738;
                     Radio2.ReceiverAddress := $44;
                  end;

               if CMD = 'IC746' then
                  begin
                     Radio2.RadioModel := IC746;
                     Radio2.ReceiverAddress := $56;
                  end;

               if CMD = 'IC746PRO' then
                  begin
                     Radio2.RadioModel := IC746PRO;
                     Radio2.ReceiverAddress := $56;
                  end;

               if CMD = 'IC756' then
                  begin
                     Radio2.RadioModel := IC756;
                     Radio2.ReceiverAddress := $50;
                  end;

               if CMD = 'IC756PRO' then
                  begin
                     Radio2.RadioModel := IC756PRO;
                     Radio2.ReceiverAddress := $5C;
                  end;

               if CMD = 'IC756PROII' then
                  begin
                     Radio2.RadioModel := IC756PROII;
                     Radio2.ReceiverAddress := $64;
                  end;

               if CMD = 'IC761' then
                  begin
                     Radio2.RadioModel := IC761;
                     Radio2.ReceiverAddress := $1E;
                  end;

               if CMD = 'IC765' then
                  begin
                     Radio2.RadioModel := IC765;
                     Radio2.ReceiverAddress := $2C;
                  end;

               if CMD = 'IC775' then
                  begin
                     Radio2.RadioModel := IC775;
                     Radio2.ReceiverAddress := $46;
                  end;

               if CMD = 'IC781' then
                  begin
                     Radio2.RadioModel := IC781;
                     Radio2.ReceiverAddress := $26;
                  end;

               if CPUKeyer.SlowInterrupts then
                  Radio2.ControlDelay := 4
               else
                  Radio2.ControlDelay := 8;
            end;

         {KK1L: 6.73 Added direct TenTec support}

         if StringHas(CMD, 'OMNI') then
            begin
               Radio2.RadioModel := OMNI6;
               Radio2.ReceiverAddress := $04;
            end;

         if CMD = 'ORION' then
            begin
               Radio2.RadioModel := Orion;
               Radio2.RadioBaudRate := 57600;
            end;

         if CMD = 'ARGO' then
            begin
               Radio2.RadioModel := ARGO;
               Radio2.ReceiverAddress := $04;
            end;

         ProcessConfigInstructions2 := (Radio2.RadioModel <> NoInterfacedRadio) or
            (CMD = 'NONE');
      end;

   if ID = 'RADIO ONE UPDATE SECONDS' then
      begin
         Val(CMD, Radio1.UpdateSeconds, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIO TWO UPDATE SECONDS' then
      begin
         Val(CMD, Radio2.UpdateSeconds, Result1);
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'RADIUS OF EARTH' then
      begin
         Val(CMD, RadiusOfEarth, Result1);
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RANDOM CQ MODE' then
      begin
         RandomCQMode := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RATE DISPLAY' then
      begin
         if UpperCase(CMD) = 'QSO POINTS' then RateDisplay := Points;
         if UpperCase(CMD) = 'BAND QSOS' then RateDisplay := BandQSOs;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'RELAY CONTROL PORT' then
      begin
         RelayControlPort := NoPort;
         CMD := UpperCase(CMD);

         if CMD = '1' then
            begin
               RelayControlPort := Parallel1;
               //{WLI}            Port [LPT1BaseAddress + 6] := $0;
            end;

         if CMD = '2' then
            begin
               RelayControlPort := Parallel2;
               //{WLI}            Port [LPT2BaseAddress + 6] := 0;
            end;

         if CMD = '3' then
            begin
               RelayControlPort := Parallel3;
               //{WLI}            Port [LPT3BaseAddress + 6] := 0;
            end;

         ProcessConfigInstructions2 := (RelayControlPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'RECEIVER ADDRESS' then
      begin
         Val(CMD, Radio1.ReceiverAddress, Result1);
         Radio2.ReceiverAddress := Radio1.ReceiverAddress;
         ProcessConfigInstructions2 := Result1 = 0;
         Exit;
      end;

   if ID = 'REMAINING MULT DISPLAY MODE' then
      begin
         RemainingMultDisplayMode := NoRemainingMults;

         CMD := UpperCase(CMD);

         if CMD = 'ERASE' then RemainingMultDisplayMode := Erase;
         if CMD = 'HILIGHT' then RemainingMultDisplayMode := HiLight;

         ProcessConfigInstructions2 := (RemainingMultDisplayMode <> NoRemainingMults) or
            (CMD = 'NONE');

         Exit;
      end;

   if ID = 'REMINDER' then
      begin
         if NumberReminderRecords >= MaximumReminderRecords then
            begin
               Write('Maximum number of reminders exceeded!!');
               Exit;
            end;

         if NumberReminderRecords = 0 then New(Reminders);

         Reminders^[NumberReminderRecords].DateString := '';
         Reminders^[NumberReminderRecords].DayString := '';
         Reminders^[NumberReminderRecords].Alarm := False;

         CMD := UpperCase(CMD);

         TimeString := Copy(CMD, 1, 4);

         if not StringIsAllNumbers(TimeString) then
            begin
               ShowMessage(TimeString + #13 + 'Invalid reminder time!!');
               Exit;
            end;

         Val(TimeString, Reminders^[NumberReminderRecords].Time, Result1);

         DateString := BracketedString(CMD, ' ON ', '');

         if StringHas(DateString, 'ALARM') then
            begin
               Reminders^[NumberReminderRecords].Alarm := True;
               DateString := BracketedString(DateString, '', 'ALARM');
            end;

         //{WLI}        GetRidOfPostcedingSpaces (DateString);

         if StringHas(DateString, '-') then
            begin
               case length(DateString) of
                  8:
                     if (DateString[2] <> '-') or (DateString[6] <> '-') then
                        begin
                           Write('Invalid reminder date!!');
                           Exit;
                        end
                     else
                        DateString := '0' + DateString;

                  9:
                     if (DateString[3] <> '-') or (DateString[7] <> '-') then
                        begin
                           Write('Invalid reminder date!!');
                           Exit;
                        end;

                  else
                     Write('Invalid reminder date!!');
               end;
               Reminders^[NumberReminderRecords].DateString := DateString;
            end
         else
            begin
               DayString := Copy(DateString, length(DateString) - 2, 3);
               if (DayString <> 'DAY') and (DayString <> 'ALL') then
                  begin
                     Write('Invalid reminder date!!');
                     Exit;
                  end;

               Reminders^[NumberReminderRecords].DayString := DateString;
            end;

         ReadLn(ConfigFileRead, Reminders^[NumberReminderRecords].Message);
         inc(NumberReminderRecords);
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if (ID = 'REPEAT S&P EXCHANGE') or (ID = 'REPEAT S&P CW EXCHANGE') then
      begin
         RepeatSearchAndPounceExchange := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'REPEAT S&P SSB EXCHANGE' then
      begin
         RepeatSearchAndPouncePhoneExchange := CMD;
         ProcessConfigInstructions2 := True;
         Exit;
      end;

   if ID = 'ROTATOR PORT' then
      begin
         ActiveRotatorPort := NoPort;
         CMD := UpperCase(CMD);
         if StringHas(CMD, 'SERIAL 1') then ActiveRotatorPort := Serial1;
         if StringHas(CMD, 'SERIAL 2') then ActiveRotatorPort := Serial2;
         if StringHas(CMD, 'SERIAL 3') then ActiveRotatorPort := Serial3;
         if StringHas(CMD, 'SERIAL 4') then ActiveRotatorPort := Serial4;
         if StringHas(CMD, 'SERIAL 5') then ActiveRotatorPort := Serial5;
         if StringHas(CMD, 'SERIAL 6') then ActiveRotatorPort := Serial6;

         ProcessConfigInstructions2 := (ActiveRotatorPort <> NoPort) or (CMD = 'NONE');
         Exit;
      end;

   if ID = 'ROTATOR TYPE' then
      begin
         ActiveRotatorType := NoRotator;

         CMD := UpperCase(CMD);

         if StringHas(CMD, 'DCU') then ActiveRotatorType := DCU1Rotator;
         if StringHas(CMD, 'ORI') then ActiveRotatorType := OrionRotator;
         if StringHas(CMD, 'YAE') then ActiveRotatorType := YaesuRotator; {KK1L: 6.71}

         ProcessConfigInstructions2 := (ActiveRotatorType <> NoRotator) and (CMD <> 'NONE');
         Exit;
      end;

   if ID = 'RTTY RECEIVE STRING' then
      begin
         RTTYReceiveString := CMD;
         ProcessConfigInstructions2 := True;
         //{WLI}        SniffOutControlCharacters (RTTYReceiveString);
         Exit;
      end;

   if ID = 'RTTY SEND STRING' then
      begin
         RTTYSendString := CMD;
         ProcessConfigInstructions2 := True;
         //{WLI}        SniffOutControlCharacters (RTTYSendString);
         Exit;
      end;
   {
     if ID = 'RTTY PORT' then
     begin
       ActiveRTTYPort := NoPort;
       CMD := UpperCase(CMD);
       if StringHas(CMD, 'SERIAL 1') then ActiveRTTYPort := Serial1;
       if StringHas(CMD, 'SERIAL 2') then ActiveRTTYPort := Serial2;
       if StringHas(CMD, 'SERIAL 3') then ActiveRTTYPort := Serial3;
       if StringHas(CMD, 'SERIAL 4') then ActiveRTTYPort := Serial4;
       if StringHas(CMD, 'SERIAL 5') then ActiveRTTYPort := Serial5;
       if StringHas(CMD, 'SERIAL 6') then ActiveRTTYPort := Serial6;

       ProcessConfigInstructions2 := (ActiveRTTYPort <> NoPort) or (CMD = 'NONE');
       Exit;
     end;
   }
end;

function ProcessConfigInstructions3(ID: Str80; CMD: string): boolean;

var
   Result1                         : integer;

begin
   if (ID = 'S&P EXCHANGE') or (ID = 'S&P CW EXCHANGE') then
      begin
         SearchAndPounceExchange := CMD;
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'S&P SSB EXCHANGE' then
      begin
         SearchAndPouncePhoneExchange := CMD;
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SAY HI ENABLE' then
      begin
         SayHiEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SAY HI RATE CUTOFF' then
      begin
         Val(CMD, SayHiRateCutOff, Result1);
         ProcessConfigInstructions3 := Result1 = 0;
         Exit;
      end;

   if ID = 'SCP COUNTRY STRING' then
      begin
         CD.CountryString := UpperCase(CMD);

         if CD.CountryString <> '' then
            if Copy(CD.CountryString, length(CD.CountryString), 1) <> ',' then
               CD.CountryString := CD.CountryString + ',';

         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SCP MINIMUM LETTERS' then {KK1L: 6.68 0 for WRTC2002}
      if (not WRTC2002) then
         begin
            Val(CMD, SCPMinimumLetters, Result1);
            ProcessConfigInstructions3 := Result1 = 0;
            Exit;
         end
      else
         begin
            SCPMinimumLetters := 0;
            ProcessConfigInstructions3 := True;
         end;

   if ID = 'SEND ALT-D SPOTS TO PACKET' then
      begin
         SendAltDSpotsToPacket := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SEND COMPLETE FOUR LETTER CALL' then
      begin
         SendCompleteFourLetterCall := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SEND QSO IMMEDIATELY' then
      begin
         SendQSOImmediately := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SERIAL 5 PORT ADDRESS' then
      begin
         HexToWord(CMD, Com5PortBaseAddress, Result1);
         ProcessConfigInstructions3 := Result1 = 0;
         Exit;
      end;

   if ID = 'SERIAL 6 PORT ADDRESS' then
      begin
         HexToWord(CMD, Com6PortBaseAddress, Result1);
         ProcessConfigInstructions3 := Result1 = 0;
         Exit;
      end;

   if ID = 'SERIAL PORT DEBUG' then
      begin
         CPUKeyer.SerialPortDebug := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'STEREO CONTROL PIN' then {KK1L: 6.71}
      begin
         Val(CMD, StereoControlPin, Result1);
         if (StereoControlPin <> 5) and (StereoControlPin <> 9) then StereoControlPin := 9;
         ProcessConfigInstructions3 := Result1 = 0;
         Exit;
      end;

   if ID = 'STEREO CONTROL PORT' then {KK1L: 6.71}
      begin
         ActiveStereoPort := NoPort;
         CMD := UpperCase(CMD);

         if CMD = '1' then ActiveStereoPort := Parallel1;
         if CMD = '2' then ActiveStereoPort := Parallel2;
         if CMD = '3' then ActiveStereoPort := Parallel3;
         ProcessConfigInstructions3 := (ActiveStereoPort <> NoPort) or (CMD = 'NONE');
      end;

   if ID = 'STEREO PIN HIGH' then {KK1L: 6.71}
      begin
         StereoPinState := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SHIFT KEY ENABLE' then
      begin
         ShiftKeyEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SHORT INTEGERS' then
      begin
         ShortIntegers := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SHORT 0' then
      begin
         Short0 := CMD[1];
         ProcessConfigInstructions3 := True;
      end;

   if ID = 'SHORT 1' then
      begin
         Short1 := CMD[1];
         ProcessConfigInstructions3 := True;
      end;

   if ID = 'SHORT 2' then
      begin
         Short2 := CMD[1];
         ProcessConfigInstructions3 := True;
      end;

   if ID = 'SHORT 9' then
      begin
         Short9 := CMD[1];
         ProcessConfigInstructions3 := True;
      end;

   if ID = 'SHOW SEARCH AND POUNCE' then
      begin
         ShowSearchAndPounce := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SIMULATOR ENABLE' then
      begin
         if UpCase(CMD[1]) = 'T' then
            DDXState := StandBy
         else
            DDXState := Off;

         ProcessConfigInstructions3 := True;
      end;

   if ID = 'SINGLE RADIO MODE' then
      begin
         SingleRadioMode := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SKIP ACTIVE BAND' then
      begin
         SkipActiveBand := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SLASH MARK CHAR' then
      begin
         if CMD = '' then Exit;
         SlashMarkChar := CMD[1];
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SPACE BAR DUPE CHECK ENABLE' then
      begin
         SpaceBarDupeCheckEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SPRINT QSY RULE' then
      begin
         SprintQSYRule := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if (ID = 'START SENDING NOW KEY') or (ID = 'START SENDING CALL KEY') then
      begin
         if UpperCase(CMD) = 'SPACE' then
            StartSendingNowKey := ' '
         else
            StartSendingNowKey := CMD[1];
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SWAP PACKET SPOT RADIOS' then
      begin
         SwapPacketSpotRadios := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SWAP PADDLES' then
      begin
         SwapPaddles := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'SWAP RADIO RELAY SENSE' then
      begin
         SwapRadioRelaySense := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'TAB MODE' then
      begin
         CMD := UpperCase(CMD);

         if CMD = 'NORMAL' then TabMode := NormalTabMode;
         if CMD = 'CONTROLF' then TabMode := ControlFTabMode;

         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'TAIL END KEY' then
      begin
         TailEndKey := CMD[1];
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if (ID = 'TAIL END MESSAGE') or (ID = 'TAIL END CW MESSAGE') then
      begin
         TailEndMessage := CMD;
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'TAIL END SSB MESSAGE' then
      begin
         TailEndPhoneMessage := CMD;
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'TEN MINUTE RULE' then
      begin
         CMD := UpperCase(CMD);
         TenMinuteRule := NoTenMinuteRule;

         if CMD = 'TIME OF FIRST QSO' then TenMinuteRule := TimeOfFirstQSO;

         ProcessConfigInstructions3 := (TenMinuteRule <> NoTenMinuteRule) or
            (CMD = 'NONE');
         Exit;
      end;

   if ID = 'TOTAL SCORE MESSAGE' then
      begin
         if NumberTotalScoreMessages < 10 then
            begin
               Val(CMD, TotalScoreMessages[NumberTotalScoreMessages].Score, Result1);
               ReadLn(ConfigFileRead, TotalScoreMessages[NumberTotalScoreMessages].MessageString);
               inc(NumberTotalScoreMessages);
               ProcessConfigInstructions3 := Result1 = 0;
            end
         else
            Write('Too many TOTAL SCORE MESSAGEs!!');
         Exit;
      end;

   if (ID = 'TUNE DUPE CHECK ENABLE') or (ID = 'TUNE ALT-D ENABLE') then {KK1L: 6.73}
      begin
         TuneDupeCheckEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'TUNE WITH DITS' then
      begin
         TuneWithDits := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'TWO RADIO MODE' then
      begin
         if UpCase(CMD[1]) = 'T' then
            TwoRadioState := Idle
         else
            TwoRadioState := TwoRadiosDisabled;
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if UpperCase(ID) = 'UPDATE RESTART FILE ENABLE' then
      begin
         UpdateRestartFileEnable := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   {   if UpperCase(ID) = 'USE BIOS KEY CALLS' then
         begin
            UseBIOSKeyCalls := UpCase(CMD[1]) = 'T';
            ProcessConfigInstructions3 := true;
            exit;
         end;
   }

   if UpperCase(ID) = 'USE IRQS' then
      begin
         CPUKeyer.UseIRQs := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if UpperCase(ID) = 'USER INFO SHOWN' then
      begin
         UserInfoShown := NoUserInfo;
         CMD := UpperCase(CMD);

         if CMD = 'NONE' then UserInfoShown := NoUserInfo;
         if CMD = 'NAME' then UserInfoShown := NameInfo;
         if CMD = 'QTH' then UserInfoShown := QTHInfo;
         if CMD = 'SECTION' then UserInfoShown := SectionInfo;
         if CMD = 'GRID' then UserInfoShown := GridInfo;
         if CMD = 'CUSTOM' then UserInfoShown := CustomInfo;

         if (CMD = 'OLD CALL') or (CMD = 'OLDCALL') then UserInfoShown := OldCallInfo;
         if (CMD = 'CHECK SECTION') or (CMD = 'CHECKSECTION') then UserInfoShown := CheckSectionInfo;
         if (CMD = 'CQ ZONE') or (CMD = 'CQZONE') then UserInfoShown := CQZoneInfo;
         if (CMD = 'ITU ZONE') or (CMD = 'ITUZONE') then UserInfoShown := ITUZoneInfo;
         if (CMD = 'FOC NUMBER') or (CMD = 'FOCNUMBER') then UserInfoShown := FocInfo;

         if (CMD = 'USER 1') or (CMD = 'USER1') then UserInfoShown := User1Info;
         if (CMD = 'USER 2') or (CMD = 'USER2') then UserInfoShown := User2Info;
         if (CMD = 'USER 3') or (CMD = 'USER3') then UserInfoShown := User3Info;
         if (CMD = 'USER 4') or (CMD = 'USER4') then UserInfoShown := User4Info;
         if (CMD = 'USER 5') or (CMD = 'USER5') then UserInfoShown := User5Info;

         ProcessConfigInstructions3 := (UserInfoShown <> NoUserInfo) or (CMD = 'NONE');
         Exit;
      end;

   {   if UpperCase(ID) = 'VGA DISPLAY ENABLE' then
         begin
            VGADisplayEnable := UpCase(CMD[1]) = 'T';
            ProcessConfigInstructions3 := true;
            exit;
         end;
   }
   if UpperCase(ID) = 'VHF BAND ENABLE' then
      begin
         VHFBandsEnabled := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   {   if ID = 'VIDEO GAME LENGTH' then
         begin
            Val(CMD, VideoGameLength, Result1);
            ProcessConfigInstructions3 := Result1 = 0;
            Exit;
         end;
   }
   {   if UpperCase(ID) = 'VISIBLE DUPESHEET' then
         begin
            VisibleDupesheetEnable := UpCase(CMD[1]) = 'T';
            ProcessConfigInstructions3 := true;
            Exit;
         end;
   }
   if UpperCase(ID) = 'WAKE UP TIME OUT' then
      begin
         Val(CMD, WakeUpTimeOut, Result1);
         ProcessConfigInstructions3 := Result1 = 0;
         Exit;
      end;

   if ID = 'WARC BAND ENABLE' then
      begin
         WARCBandsEnabled := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'WAIT FOR STRENGTH' then
      begin
         WaitForStrength := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'WEIGHT' then
      begin
         Val(CMD, Weight, Result1);
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'WIDE FREQUENCY DISPLAY' then
      begin
         WideFreqDisplay := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'WILDCARD PARTIALS' then
      begin
         WildCardPartials := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'DTR' then
      begin
         DTR := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

   if ID = 'RTS' then
      begin
         RTS := UpCase(CMD[1]) = 'T';
         ProcessConfigInstructions3 := True;
         Exit;
      end;

end;

function ProcessConfigInstruction(var FileString: string; var FirstCommand: boolean): boolean;

var

   I, Count, Result1, Memory       : integer;
   Directory                       : Str80;

   ID                              : string; //{WLI}
   CMD                             : string;
   TimeString, DateString, DayString: Str20;
   TempFreq                        : LONGINT;
   TempBand                        : BandType;
   TempMode                        : ModeType;

begin
   for Count := 1 to length(FileString) do
      if FileString[Count] = TabKey then FileString[Count] := ' ';

   if (Copy(FileString, 1, 1) = ';') or
      (Copy(FileString, 1, 2) = ' ;') then
      begin
         ProcessConfigInstruction := True;
         Exit;
      end;

   if StringHas(FileString, '  ;') then
      FileString := PrecedingString(FileString, ';');

   GetRidOfPrecedingSpaces(FileString);

   if FileString = '' then
      begin
         ProcessConfigInstruction := True;
         Exit;
      end;

   ID := UpperCase(PrecedingString(FileString, '='));
   {wli временно}
   //   CMD := (PostcedingString(FileString, '='));
   CMD := UpperCase(PostcedingString(FileString, '='));

   GetRidOfPrecedingSpaces(ID);
   GetRidOfPrecedingSpaces(CMD);
   GetRidOfPostcedingSpaces(ID);
   GetRidOfPostcedingSpaces(CMD);

   ProcessConfigInstruction := False;

   if FirstCommand then
      if ID <> '' then
         if ID <> 'MY CALL' then
            begin
               ShowMessage('The first command in config file must be the MY CALL statement!!');
               Exit;
            end
         else
            FirstCommand := False;

   {    IF ValidColorCommand (ID, CMD) THEN
           BEGIN
           ProcessConfigInstruction := True;
           Exit;
           END;
   }

  //   if CONFIG_EDITING = False then
  //      begin
  //    if SF.V.FindRow(ID, I) then
  //   I:=   SF.V.Strings.IndexOf(ID);
  //   S:=SF.V.Strings[1];
  //   //    I := SF.SG.Cols[1].IndexOf(ID);
  //    if I <> -1 then
  //      SF.SG.Cells[2, I] := CMD;
  //      SF.V.Values[ID] := CMD;
    //end;

    {добавлено сюда из ProcessConfigInstructions1  (   if ID = 'BIG REMAINING LIST' then)}
   if not CountryTable.CustomRemainingCountryListFound then
      CountryTable.MakeDefaultRemainingCountryList;

   if ProcessPostConfigInstruction(ID, CMD) then
      begin
         ProcessConfigInstruction := True;
         Exit;
      end;

   if ProcessConfigInstructions1(ID, CMD) then
      begin
         ProcessConfigInstruction := True;
         Exit;
      end;

   if ProcessConfigInstructions2(ID, CMD) then
      begin
         ProcessConfigInstruction := True;
         Exit;
      end;

   if ProcessConfigInstructions3(ID, CMD) then
      begin
         ProcessConfigInstruction := True;
         Exit;
      end;

   if ID = '' then ProcessConfigInstruction := True;
end;

begin
end.

