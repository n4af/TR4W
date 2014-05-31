unit ColorCfg;

interface

uses
  VC,
  Tree,
  LogWind;

{ This file contains the configuration commands for setting the
  different window colors.  There is one complete set for the color
  mode and another for monochrome.  Setting the DISPLAY MODE option
  will select the one you want.  This allows you to set up your
  favorite colors when using a color monitor, but keep the setting you
  may like best when you use your monochrome laptop.

  As with the LOGCFG.PAS file, the ID is the first part of the configuration
  command and CMD is what you put after the equal sign.  An example:

  Color Color Alarm Window = Yellow

  This command will set the character color in the Alarm Window to Yellow
  if you are in the color display mode.

  The possible colors are:

  Black, Blue, Green, Cyan, Red, Magenta, Brown, LightGray, DarkGray, Yellow,
  LightBlue, LightGreen, LightCyan, LightRed, LightMagenta, and White.

  }
function ValidColorCommand(CMD: Str80; ID: Str80): boolean;
implementation

function ValidColorCommand(CMD: Str80; ID: Str80): boolean;

begin
  ValidColorCommand := False;
  if not ((StringHas(CMD, 'COLOR')) or (StringHas(CMD, 'BACKGROUND'))) then Exit;
  if not StringHas(CMD, 'WINDOW') then Exit;
  ValidColorCommand := True;

  if CMD = 'ALARM WINDOW COLOR' then
    ColorColors.AlarmWindowColor := GetColorInteger(ID);

  if CMD = 'ALARM WINDOW BACKGROUND' then
    ColorColors.AlarmWindowBackground := GetColorInteger(ID);

  if CMD = 'BAND MAP WINDOW COLOR' then
    ColorColors.BandMapWindowColor := GetColorInteger(ID);

  if CMD = 'BAND MAP WINDOW BACKGROUND' then
    ColorColors.BandMapWindowBackground := GetColorInteger(ID);

  if CMD = 'BAND MODE WINDOW COLOR' then
    ColorColors.BandModeWindowColor := GetColorInteger(ID);

  if CMD = 'BAND MODE WINDOW BACKGROUND' then
    ColorColors.BandModeWindowBackground := GetColorInteger(ID);

  if CMD = 'BEAM HEADING WINDOW COLOR' then
    ColorColors.BeamHeadingWindowColor := GetColorInteger(ID);

  if CMD = 'BEAM HEADING WINDOW BACKGROUND' then
    ColorColors.BeamHeadingWindowBackground := GetColorInteger(ID);

  if CMD = 'BIG WINDOW COLOR' then
    ColorColors.BigWindowColor := GetColorInteger(ID);

  if CMD = 'BIG WINDOW BACKGROUND' then
    ColorColors.BigWindowBackground := GetColorInteger(ID);

  if CMD = 'CALL WINDOW COLOR' then
    ColorColors.CallWindowColor := GetColorInteger(ID);

  if CMD = 'CALL WINDOW BACKGROUND' then
    ColorColors.CallWindowBackground := GetColorInteger(ID);

  if CMD = 'CLOCK WINDOW COLOR' then
    ColorColors.ClockWindowColor := GetColorInteger(ID);

  if CMD = 'CLOCK WINDOW BACKGROUND' then
    ColorColors.ClockWindowBackground := GetColorInteger(ID);

  if CMD = 'CODE SPEED WINDOW COLOR' then
    ColorColors.CodeSpeedWindowColor := GetColorInteger(ID);

  if CMD = 'CODE SPEED WINDOW BACKGROUND' then
    ColorColors.CodeSpeedWindowBackground := GetColorInteger(ID);

  if CMD = 'CONTEST TITLE WINDOW COLOR' then
    ColorColors.ContestTitleWindowColor := GetColorInteger(ID);

  if CMD = 'CONTEST TITLE WINDOW BACKGROUND' then
    ColorColors.ContestTitleWindowBackground := GetColorInteger(ID);

  if CMD = 'DATE WINDOW COLOR' then
    ColorColors.DateWindowColor := GetColorInteger(ID);

  if CMD = 'DATE WINDOW BACKGROUND' then
    ColorColors.DateWindowBackground := GetColorInteger(ID);

  if CMD = 'DUPE INFO WINDOW COLOR' then
    ColorColors.DupeInfoWindowColor := GetColorInteger(ID);

  if CMD = 'DUPE INFO WINDOW BACKGROUND' then
    ColorColors.DupeInfoWindowBackground := GetColorInteger(ID);

  if CMD = 'DUPESHEET WINDOW COLOR' then
    ColorColors.DupeSheetWindowColor := GetColorInteger(ID);

  if CMD = 'DUPESHEET WINDOW BACKGROUND' then
    ColorColors.DupeSheetWindowBackground := GetColorInteger(ID);

  if CMD = 'EDITABLE LOG WINDOW COLOR' then
    ColorColors.EditableLogWindowColor := GetColorInteger(ID);

  if CMD = 'EDITABLE LOG WINDOW BACKGROUND' then
    ColorColors.EditableLogWindowBackground := GetColorInteger(ID);

  if CMD = 'EXCHANGE WINDOW COLOR' then
    ColorColors.ExchangeWindowColor := GetColorInteger(ID);

  if CMD = 'EXCHANGE WINDOW BACKGROUND' then
    ColorColors.ExchangeWindowBackground := GetColorInteger(ID);

  if CMD = 'EXCHANGE WINDOW S&P BACKGROUND' then
    ColorColors.ExchangeSAndPWindowBackground := GetColorInteger(ID);

  if CMD = 'FREE MEMORY WINDOW COLOR' then
    ColorColors.FreeMemoryWindowColor := GetColorInteger(ID);

  if CMD = 'FREE MEMORY WINDOW BACKGROUND' then
    ColorColors.FreeMemoryWindowBackground := GetColorInteger(ID);

  if CMD = 'FUNCTION KEY WINDOW COLOR' then
    ColorColors.FunctionKeyWindowColor := GetColorInteger(ID);

  if CMD = 'FUNCTION KEY WINDOW BACKGROUND' then
    ColorColors.FunctionKeyWindowBackground := GetColorInteger(ID);

  if CMD = 'INSERT WINDOW COLOR' then
    ColorColors.InsertWindowColor := GetColorInteger(ID);

  if CMD = 'INSERT WINDOW BACKGROUND' then
    ColorColors.InsertWindowBackground := GetColorInteger(ID);

  if CMD = 'MULTIPLIER INFORMATION WINDOW COLOR' then
    ColorColors.MultiplierInformationWindowColor := GetColorInteger(ID);

  if CMD = 'MULTIPLIER INFORMATION WINDOW BACKGROUND' then
    ColorColors.MultiplierInformationWindowBackground := GetColorInteger(ID);

  if CMD = 'NAME PERCENTAGE WINDOW COLOR' then
    ColorColors.NamePercentageWindowColor := GetColorInteger(ID);

  if CMD = 'NAME PERCENTAGE WINDOW BACKGROUND' then
    ColorColors.NamePercentageWindowBackground := GetColorInteger(ID);

  if CMD = 'NAME SENT WINDOW COLOR' then
    ColorColors.NameSentWindowColor := GetColorInteger(ID);

  if CMD = 'NAME SENT WINDOW BACKGROUND' then
    ColorColors.NameSentWindowBackground := GetColorInteger(ID);

  if CMD = 'POSSIBLE CALL WINDOW COLOR' then
    ColorColors.PossibleCallWindowColor := GetColorInteger(ID);

  if CMD = 'POSSIBLE CALL WINDOW BACKGROUND' then
    ColorColors.PossibleCallWindowBackground := GetColorInteger(ID);

  if CMD = 'POSSIBLE CALL WINDOW DUPE COLOR' then
    ColorColors.PossibleCallWindowDupeColor := GetColorInteger(ID);

  if CMD = 'POSSIBLE CALL WINDOW DUPE BACKGROUND' then
    ColorColors.PossibleCallWindowDupeBackground := GetColorInteger(ID);

  if CMD = 'QSO INFORMATION WINDOW COLOR' then
    ColorColors.QSOInformationWindowColor := GetColorInteger(ID);

  if CMD = 'QSO INFORMATION WINDOW BACKGROUND' then
    ColorColors.QSOInformationWindowBackground := GetColorInteger(ID);

  if CMD = 'QSO NUMBER WINDOW COLOR' then
    ColorColors.QSONumberWindowColor := GetColorInteger(ID);

  if CMD = 'QSO NUMBER WINDOW BACKGROUND' then
    ColorColors.QSONumberWindowBackground := GetColorInteger(ID);

  if CMD = 'QTC NUMBER WINDOW COLOR' then
    ColorColors.QTCNumberWindowColor := GetColorInteger(ID);

  if CMD = 'QTC NUMBER WINDOW BACKGROUND' then
    ColorColors.QTCNumberWindowBackground := GetColorInteger(ID);

  if CMD = 'QUICK COMMAND WINDOW COLOR' then
    ColorColors.QuickCommandWindowColor := GetColorInteger(ID);

  if CMD = 'QUICK COMMAND WINDOW BACKGROUND' then
    ColorColors.QuickCommandWindowBackground := GetColorInteger(ID);

  if CMD = 'RADIO WINDOW COLOR' then {KK1L: 6.73}
  begin
    ColorColors.RadioOneWindowColor := GetColorInteger(ID);
    ColorColors.RadioTwoWindowColor := GetColorInteger(ID);
  end;

  if CMD = 'RADIO WINDOW BACKGROUND' then {KK1L: 6.73}
  begin
    ColorColors.RadioOneWindowBackground := GetColorInteger(ID);
    ColorColors.RadioTwoWindowColor := GetColorInteger(ID);
  end;

  if CMD = 'RADIO ONE WINDOW COLOR' then {KK1L: 6.73}
    ColorColors.RadioOneWindowColor := GetColorInteger(ID);

  if CMD = 'RADIO ONE WINDOW BACKGROUND' then {KK1L: 6.73}
    ColorColors.RadioOneWindowBackground := GetColorInteger(ID);

  if CMD = 'RADIO TWO WINDOW COLOR' then {KK1L: 6.73}
    ColorColors.RadioTwoWindowColor := GetColorInteger(ID);

  if CMD = 'RADIO TWO WINDOW BACKGROUND' then {KK1L: 6.73}
    ColorColors.RadioTwoWindowBackground := GetColorInteger(ID);

  if CMD = 'RATE WINDOW COLOR' then
    ColorColors.RateWindowColor := GetColorInteger(ID);

  if CMD = 'RATE WINDOW BACKGROUND' then
    ColorColors.RateWindowBackground := GetColorInteger(ID);

//  if CMD = 'RTTY WINDOW COLOR' then
//    ColorColors.RTTYWindowColor := GetColorInteger(ID);

//  if CMD = 'RTTY WINDOW BACKGROUND' then
//    ColorColors.RTTYWindowBackground := GetColorInteger(ID);

//  if CMD = 'RTTY INVERSE WINDOW COLOR' then
//    ColorColors.RTTYInverseWindowColor := GetColorInteger(ID);

//  if CMD = 'RTTY INVERSE WINDOW BACKGROUND' then
//    ColorColors.RTTYInverseWindowBackground := GetColorInteger(ID);

  if CMD = 'REMAINING MULTS WINDOW SUBDUE COLOR' then
    ColorColors.RemainingMultsWindowSubdue := GetColorInteger(ID);

  if CMD = 'REMAINING MULTS WINDOW COLOR' then
    ColorColors.RemainingMultsWindowColor := GetColorInteger(ID);

  if CMD = 'REMAINING MULTS WINDOW BACKGROUND' then
    ColorColors.RemainingMultsWindowBackground := GetColorInteger(ID);

  if CMD = 'TOTAL WINDOW COLOR' then
    ColorColors.TotalWindowColor := GetColorInteger(ID);

  if CMD = 'TOTAL WINDOW BACKGROUND' then
    ColorColors.TotalWindowBackground := GetColorInteger(ID);

  if CMD = 'TOTAL SCORE WINDOW COLOR' then
    ColorColors.TotalScoreWindowColor := GetColorInteger(ID);

  if CMD = 'TOTAL SCORE WINDOW BACKGROUND' then
    ColorColors.TotalScoreWindowBackground := GetColorInteger(ID);

  if CMD = 'USER INFO WINDOW COLOR' then
    ColorColors.UserInfoWindowColor := GetColorInteger(ID);

  if CMD = 'USER INFO WINDOW BACKGROUND' then
    ColorColors.UserInfoWindowBackground := GetColorInteger(ID);

  if CMD = 'WHOLE SCREEN WINDOW COLOR' then
    ColorColors.WholeScreenColor := GetColorInteger(ID);

  if CMD = 'WHOLE SCREEN WINDOW BACKGROUND' then
    ColorColors.WholeScreenBackground := GetColorInteger(ID);

  if CMD = 'SCP WINDOW DUPE COLOR' then SCPDupeColor := GetColorInteger(ID);

  if CMD = 'SCP WINDOW DUPE BACKGROUND' then SCPDupeBackground := GetColorInteger(ID);
end;

end.

