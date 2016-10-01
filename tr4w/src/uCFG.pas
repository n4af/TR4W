{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref:
http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit uCFG;

{$IMPORTEDDATA OFF}

interface

uses
uIO,
  uCTYDAT,
  uWinKey,
  uGetScores,
  uStations,
  uRemMults,
  PostUnit,
  LogEdit,
  LogGrid,
  LogSCP,
  TF,
  FCONTEST,
  uMP3Recorder,
  ZoneCont,
utils_text,
  //Country9,
  CFGCMD,
  Windows,
  LogStuff,
  LogK1EA,
  LOGWAE,
  LogDom,
  LOGDVP,
  LogRadio,
  LogDupe,
  LogPack,
  LogCW,
  uNet,
  LogWind,
  uBandmap,
  uTelnet,
  uFunctionKeys,
  Tree,
  VC,
  idUDPClient,
  idGlobal
  ;
{
const
  WindowsColorArraySize                 = 8;
var
  WindowsColorArray                     : array[1..WindowsColorArraySize] of tWindowColorRecord =
    (

      (wcWindow: @wh[mweCountryName];   wcColor: @ColorColors.CountryNameWindowColor;   wcbackground: @ColorColors.CountryNameWindowBackground),
      (wcWindow: @wh[mweBeamHeading];   wcColor: @ColorColors.BeamHeadingWindowColor;   wcbackground: @ColorColors.BeamHeadingWindowBackground),
      (wcWindow: @wh[mweTotalScore];    wcColor: @ColorColors.TotalScoreWindowColor;    wcbackground: @ColorColors.TotalScoreWindowBackground),
      (wcWindow: @wh[mweAutoSendCount]; wcColor: @ColorColors.AutoSendArrowWindowColor; wcbackground: @ColorColors.AutoSendArrowWindowBackground),
      (wcWindow: @wh[mweQSONumber];     wcColor: @ColorColors.QSONumberWindowColor;     wcbackground: @ColorColors.QSONumberWindowBackground),
      (wcWindow: @Radio1.FreqWindowHandle;   wcColor: @ColorColors.FrequencyOneWindowColor;  wcbackground: @ColorColors.FrequencyOneWindowBackground),
      (wcWindow: @Radio2.FreqWindowHandle;   wcColor: @ColorColors.FrequencyTwoWindowColor;  wcbackground: @ColorColors.FrequencyTwoWindowBackground),
      (wcWindow: @wh[mweBandMode];      wcColor: @ColorColors.BandModeWindowColor;  wcbackground: @ColorColors.BandModeWindowBackground)
      );

}

type
  ArrayRecord = record
    arArrayPtr: PInteger;
    arArrayLength: integer;
    arVar: PInteger;
  end;

type
  ListParamRecord = record
    {(*}
    lpArray  : Pointer;
    lpLength : Byte;
    lpVar    : PByte;
    {*)}

  end;

  CFGRecord = record
    {(*}
    {04}crCommand : PChar;
    {04}crAddress : Pointer;

    {02}crMin     : Word;
    {02}crMax     : Word;

    {01}crS       : CFGStatus;
    {01}crA       : Byte;//additional proc
    {01}crC       : Byte;//1-write to CFG file,
    {01}crP       : Byte;//Procedure 0-no proc,

    {01}crJ       : Byte;//0-edit, 1 -edit+restart, 2-readonly,3-message(ro)
    {01}crKind    : CFGKind;
    {01}cfFunc    : CFGFunc;
    {01}crType    : CFGType;
    {*)}
  end;

//procedure F_MY_GRID;
function F_RADIO_ONE_TYPE: boolean;
function F_RADIO_TWO_TYPE: boolean;
function F_SCP_COUNTRY_STRING: boolean;
function F_ADD_DOMESTIC_COUNTRY: boolean;
function F_AUTO_QSL_INTERVAL: boolean;
function F_BAND_MAP_CUTOFF_FREQUENCY: boolean;
function F_BAND_MAP_DECAY_TIME: boolean;
function F_CLEAR_DUPE_SHEET: boolean;
function F_CONTEST: boolean;
function F_CONTEST_NAME: boolean;
function F_START_SENDING_NOW_KEY: boolean;
function F_DX_MULTIPLIER: boolean;
function F_FREQUENCY_MEMORY: boolean;
//function F_ICOM_RESPONSE_TIMEOUT: boolean;
function F_KEYER_RADIO_ONE_OUTPUT_PORT: boolean;
function F_KEYER_RADIO_TWO_OUTPUT_PORT: boolean;
function F_ORION_PORT: boolean;
function F_MY_CONTINENT: boolean;
function F_MY_COUNTRY: boolean;
function F_MY_ZONE: boolean;
function F_MY_CALL: boolean;
function F_ZONE_MULTIPLIER: boolean;
function F_AUTO_SEND_CHARACTER_COUNT: boolean;
//function F_SETPARALLELPORT: boolean;

const
  ICOM_FILTER_WIDTH                     : array[0..03] of integer = (0, 1, 2, 3);
  SCP_MINIMUM_LETTERS_ARRAY             : array[0..03] of integer = (0, 3, 4, 5);
  AUTO_SEND_CHARACTER_COUNT_ARRAY       : array[0..06] of integer = (0, 1, 2, 3, 4, 5, 6);
  AUTO_QSL_INTERVAL                     : array[0..06] of integer = (0, 1, 2, 3, 4, 5, 6);
  ROW_COUNT_ARRAY                       : array[0..10] of integer = (5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
  WINDOW_SIZE_ARRAY                     : array[0..14] of integer = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15);
  CW_SPEED_INCREMENT                    : array[1..10] of integer = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
  MULT_REPORT_MINIMUM_BANDS_ARRAY       : array[0..02] of integer = (2, 3, 4);
  STEREO_CONTROL_PIN_ARRAY              : array[0..01] of integer = (5, 9);
  //FilterBandMap                         : array[0..02] of pchar = ('OFF','CW','Digital');
  RECORDER_BITRATE_ARRAY                : array[0..07] of integer = (8, 16, 24, 32, 40, 48, 56, 64 {, 80, 96, 112, 128});
  RECORDER_SAMPLERATE_ARRAY             : array[0..05] of integer = (08000, 11025, 12000, 16000, 22050, 44100);

  CAT_BAUDRATE_ARRAY                    : array[0..07] of integer = (1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200);
  DITDAHRATIO_ARRAY                     : array[0..03] of integer = (3, 4, 5, 6);
  LEADING_ZEROS_ARRAY                   : array[0..03] of integer = (0, 1, 2, 3);

  ArrayRecordArray                      : array[1..16] of ArrayRecord =
    (
    {(*}
    (arArrayPtr: @SCP_MINIMUM_LETTERS_ARRAY;       arArrayLength: high(SCP_MINIMUM_LETTERS_ARRAY);       arVar: @SCPMinimumLetters),
    (arArrayPtr: @AUTO_SEND_CHARACTER_COUNT_ARRAY; arArrayLength: high(AUTO_SEND_CHARACTER_COUNT_ARRAY); arVar: @AutoSendCharacterCount),


    (arArrayPtr: @AUTO_QSL_INTERVAL;               arArrayLength: high(AUTO_QSL_INTERVAL);               arVar: @AutoQSLInterval),

    (arArrayPtr: @ROW_COUNT_ARRAY;                 arArrayLength: high(ROW_COUNT_ARRAY);                 arVar: @LinesInEditableLog),
    (arArrayPtr: @WINDOW_SIZE_ARRAY;               arArrayLength: high(WINDOW_SIZE_ARRAY);               arVar: @WindowSize),
    (arArrayPtr: @CW_SPEED_INCREMENT;              arArrayLength: high(CW_SPEED_INCREMENT);              arVar: @CodeSpeedIncrement),
    (arArrayPtr: @MULT_REPORT_MINIMUM_BANDS_ARRAY; arArrayLength: high(MULT_REPORT_MINIMUM_BANDS_ARRAY); arVar: @MultReportMinimumBands),
    (arArrayPtr: @STEREO_CONTROL_PIN_ARRAY;        arArrayLength: high(STEREO_CONTROL_PIN_ARRAY);        arVar: @StereoControlPin),
    (arArrayPtr: @RECORDER_BITRATE_ARRAY;          arArrayLength: high(RECORDER_BITRATE_ARRAY);          arVar: @RecorderBitrate),


    (arArrayPtr: @RECORDER_SAMPLERATE_ARRAY;       arArrayLength: high(RECORDER_SAMPLERATE_ARRAY);       arVar: nil{@RecorderSampleRate}),

    (arArrayPtr: @CAT_BAUDRATE_ARRAY;              arArrayLength: high(CAT_BAUDRATE_ARRAY);              arVar: @Radio1.RadioBaudRate),
    (arArrayPtr: @CAT_BAUDRATE_ARRAY;              arArrayLength: high(CAT_BAUDRATE_ARRAY);              arVar: @Radio2.RadioBaudRate),
    (arArrayPtr: @DITDAHRATIO_ARRAY;               arArrayLength: high(DITDAHRATIO_ARRAY);               arVar: @tDitDahRatio),
    (arArrayPtr: @LEADING_ZEROS_ARRAY;             arArrayLength: high(LEADING_ZEROS_ARRAY);             arVar: @LeadingZeros),

    (arArrayPtr: @ICOM_FILTER_WIDTH;               arArrayLength: high(ICOM_FILTER_WIDTH);               arVar: @Radio1.tIcomFilterWidth),
    (arArrayPtr: @ICOM_FILTER_WIDTH;               arArrayLength: high(ICOM_FILTER_WIDTH);               arVar: @Radio2.tIcomFilterWidth)
    {*)}
    );

  {crA}
  AdditionalProcsArray                  : array[1..22] of Pointer =
    (
    @F_CONTEST,
    @F_ZONE_MULTIPLIER,
    @F_ORION_PORT,
    @F_CLEAR_DUPE_SHEET,
    @F_BAND_MAP_DECAY_TIME,
    @F_AUTO_QSL_INTERVAL,
    @F_CONTEST_NAME,
    @F_MY_COUNTRY,
    @F_RADIO_ONE_TYPE,
    @F_RADIO_TWO_TYPE,
    @F_SCP_COUNTRY_STRING,
    @F_KEYER_RADIO_ONE_OUTPUT_PORT,
    @F_KEYER_RADIO_TWO_OUTPUT_PORT,
    @F_MY_CALL,
    nil {@F_MY_GRID},
    @F_ADD_DOMESTIC_COUNTRY,
    @F_BAND_MAP_CUTOFF_FREQUENCY,
    @F_FREQUENCY_MEMORY,
    @F_START_SENDING_NOW_KEY,
    @F_DX_MULTIPLIER,
    @F_MY_ZONE,
    @F_MY_CONTINENT
//@F_SETPARALLELPORT
    );

  CommandsProcArray                     : array[1..12] of Pointer =
    (
    @DisplayBandMap,
    @EditableLog.ShowRemainingMultipliers,
    @DispalayLogGridLines,
    @UpadateAutoSend,
    @DisplayNextQSONumber,
    @SetComputerName,
    @DisplayCodeSpeed,
    @DisplayInsertMode,
    @UpdateRemainingMultsWindows,
    nil {@SetEditableLogWindowColors},
    @UpadateMainWindow,
    @SetStationsCallsignMask
    );

  {List}
  ListParamArray                        : array[0..51] of ListParamRecord =
    (
    {(*}
    (lpArray: @RateDisplayTypeStringArray;        lpLength: Byte(High(RateDisplayType));        lpVar: @RateDisplay; ),
    (lpArray: @QSOPointMethodArray;               lpLength: Byte(High(QSOPointMethodType));     lpVar: @ActiveQSOPointMethod),
    (lpArray: @ParameterOkayModeTypeStringArray;  lpLength: Byte(High(ParameterOkayModeType));  lpVar: @ParameterOkayMode; ),
    (lpArray: @PrefixMultStringArray;             lpLength: Byte(High(PrefixMultType));         lpVar: @ActivePrefixMult; ),
    (lpArray: @PossibleCallActionTypeStringArray; lpLength: Byte(High(PossibleCallActionType)); lpVar: @CD.PossibleCallAction; ),
    (lpArray: @ModeStringArray;                   lpLength: Byte(High(ModeType));               lpVar: @ActiveMode; ),
    (lpArray: @IECursorPosTypeStringArray;        lpLength: Byte(High(InitialExchangeCursorPosType)); lpVar: @InitialExchangeCursorPos; ),
    (lpArray: @InitialExchangeTypeStringArray;    lpLength: Byte(High(InitialExchangeType));    lpVar: @ActiveInitialExchange; ),
    (lpArray: @HourDisplayTypeSA;                 lpLength: Byte(High(HourDisplayType));        lpVar: @HourDisplay; ),
    (lpArray: @FootSwitchModeTypeStringArray;     lpLength: Byte(High(FootSwitchModeType));     lpVar: @FootSwitchMode; ),
    (lpArray: @ActiveExchangeArray;               lpLength: Byte(High(ExchangeType));           lpVar: @ActiveExchange; ),
    (lpArray: @DXMultTypenameArray;               lpLength: Byte(High(DXMultType));             lpVar: @ActiveDXMult; ),
    (lpArray: @DupeCheckSoundTypeSA;              lpLength: Byte(High(DupeCheckSoundType));     lpVar: @DupeCheckSound; ),
    (lpArray: @DomesticMultStringArray;           lpLength: Byte(High(DomesticMultType));       lpVar: @ActiveDomesticMult; ),
    (lpArray: @BandMapSplitModeTypeSA;            lpLength: Byte(High(BandMapSplitModeType));   lpVar: @BandMapSplitMode; ),
    (lpArray: @CallWindowPositionTypeSA;          lpLength: Byte(High(CallWindowPositionType)); lpVar: @CallWindowPosition; ),
    (lpArray: @RemainingMultDisplayModeTypeSA;    lpLength: Byte(High(RemainingMultDisplayModeType)); lpVar: @RemainingMultDisplayMode; ),
    (lpArray: @RotatorTypeSA;                     lpLength: Byte(High(RotatorType));            lpVar: @ActiveRotatorType; ),
    (lpArray: @TenMinuteRuleTypeSA;               lpLength: Byte(High(TenMinuteRuleType));      lpVar: @TenMinuteRule; ),
    (lpArray: @UserInfoTypeSA;                    lpLength: Byte(High(UserInfoType));           lpVar: @UserInfoShown; ),
    (lpArray: @DistanceDisplayTypeSA;             lpLength: Byte(High(DistanceDisplayType));    lpVar: @DistanceMode; ),
    (lpArray: @ContinentTypeSA;                   lpLength: Byte(High(ContinentType));          lpVar: @MyContinent; ),
    (lpArray: @ContestTypeSA;                     lpLength: Byte(High(ContestType));            lpVar: @Contest; ),
    (lpArray: @ZoneMultTypeSA;                    lpLength: Byte(High(ZoneMultType));           lpVar: @ActiveZoneMult; ),
    (lpArray: @BandStringsArrayWithOutSpaces;     lpLength: Byte(High(BandType));               lpVar: @ActiveBand; ),
    (lpArray: @BandStringsArrayWithOutSpaces;     lpLength: Byte(High(BandType));               lpVar: @SingleBand; ),
    (lpArray: @InterfacedRadioTypeSA;             lpLength: Byte(High(InterfacedRadioType));    lpVar: @Radio1.RadioModel; ),
    (lpArray: @InterfacedRadioTypeSA;             lpLength: Byte(High(InterfacedRadioType));    lpVar: @Radio2.RadioModel; ),

    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio1.tr4w_cat_rts_state; ),
    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio1.tr4w_cat_dtr_state; ),
    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio1.tr4w_keyer_rts_state; ),
    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio1.tr4w_keyer_DTR_state; ),

    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio2.tr4w_cat_rts_state; ),
    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio2.tr4w_cat_dtr_state; ),
    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio2.tr4w_keyer_rts_state; ),
    (lpArray: @tr4w_RTSDTRTypeSA;                 lpLength: Byte(High(tr4w_RTSDTRType));        lpVar: @Radio2.tr4w_keyer_DTR_state; ),

    (lpArray: @PortTypeSA;                        lpLength: Byte(High(PortType));               lpVar: @Radio1.tCATPortType; ),
    (lpArray: @PortTypeSA;                        lpLength: Byte(High(PortType));               lpVar: @Radio2.tCATPortType; ),

    (lpArray: @PortTypeSA;                        lpLength: Byte(High(PortType));               lpVar: @Radio1.tKeyerPort; ),
    (lpArray: @PortTypeSA;                        lpLength: Byte(High(PortType));               lpVar: @Radio2.tKeyerPort; ),

    (lpArray: @PortTypeSA;                        lpLength: Byte(High(PortType));               lpVar: @ActiveRotatorPort; ),
    (lpArray: @MP3RecorderDurationSA;             lpLength: Byte(High(TMP3RecorderDuration));   lpVar: @RecorderDuration; ),

    (lpArray: @tCategoryBandSA;                   lpLength: Byte(High(tCategoryBand));          lpVar: @CategoryBand; ),
    (lpArray: @tCategoryModeSA;                   lpLength: Byte(High(tCategoryMode));          lpVar: @CategoryMode; ),
    (lpArray: @tCategoryOperatorSA;               lpLength: Byte(High(tCategoryOperator));      lpVar: @CategoryOperator; ),
    (lpArray: @tCategoryPowerSA;                  lpLength: Byte(High(tCategoryPower));         lpVar: @CategoryPower; ),

    (lpArray: @PortTypeSA;                        lpLength: Byte(High(PortType));               lpVar: @WinKeySettings.wksWinKey2Port; ),
    (lpArray: @KeyerModeSA;                       lpLength: Byte(High(TWK2KeyerMode));          lpVar: @WinKeySettings.wksKeyerMode; ),
    (lpArray: @SidetoneFrequencySA;               lpLength: Byte(High(TWKSidetoneFrequency));   lpVar: @WinKeySettings.wksValueList.vlSidetoneFrequency; ),

    (lpArray: @tCategoryTransmitterSA;            lpLength: Byte(High(tCategoryTransmitter));   lpVar: @CategoryTransmitter;),
    (lpArray: @tCategoryAssistedSA;               lpLength: Byte(High(tCategoryAssisted));      lpVar: @CategoryAssisted;),
    (lpArray: @tCertificateSA;                    lpLength: Byte(High(tCertificate));           lpVar: @Certificate;)
    {*)}
    );

//  CFGKindStringArray                    : array[CFGKind] of PChar = ('Supported', 'Supported', 'Supported', 'Supported', 'Supported', 'Added', 'Removed', 'Not supported');

  CFGStatusArray                        : array[CFGStatus] of PChar = ('New', 'Old', 'Removed');

  CFGTypeStringArray                    : array[CFGType] of PChar = (nil, 'Directory', 'FileName', 'String', 'Multiplier', 'Boolean', 'Real', 'Byte', 'Integer', 'Integer', { 'Integer', } 'String', 'URL', 'Operation', 'Other', 'Char', 'Char', {'Port',} 'Port', 'Band');

var
  CMD                                   : ShortString;

const

  CommandsArraySize                     = 407+ 1{RadioOneCWSpeedSync} + 1{RadioTwoCWSpeedSync}
                                              + 1{RadioOneCWByCAT}     + 1{RadioTwoCWByCAT} //ny4i // 4.44.5
                                              + 7{UDPBroadcast Variables} //ny4i 4.44.9  - Issue 82 added one more UDP variable
                                              ;
  CFGCA                                 : array[1..CommandsArraySize] of CFGRecord =
    (
    {(*}


 (crCommand: 'ADD DOMESTIC COUNTRY';          crAddress: @tAddDomesticCountryString;      crMin:0;  crMax:13;       crS: csOld; crA: 16;crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'ALL CW MESSAGES CHAINABLE';     crAddress: @AllCWMessagesChainable;         crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'ALLOW AUTO UPDATE';             crAddress: @tAllowAutoUpdate;               crMin:0;  crMax:0;        crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'ALT-D BUFFER ENABLE';           crAddress: @AltDBufferEnable;               crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'ALWAYS CALL BLIND CQ';          crAddress: @AlwaysCallBlindCQ;              crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'ASK FOR FREQUENCIES';           crAddress: @AskForFrequencies;              crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO ALT-D ENABLE';             crAddress: @AutoAltDEnable;                 crMin:0;  crMax:0;        crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO CALL TERMINATE';           crAddress: @AutoCallTerminate;              crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO DISPLAY DUPE QSO';         crAddress: @AutoDisplayDupeQSO;             crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO DUPE ENABLE CQ';           crAddress: @AutoDupeEnableCQ;               crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO DUPE ENABLE S AND P';      crAddress: @AutoDupeEnableSandP;            crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO QSL INTERVAL';             crAddress: pointer(3);                      crMin:0;  crMax:6;        crS: csOld; crA: 6; crC:0 ; crP:0; crJ: 0; crKind: ckArray;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'AUTO QSO NUMBER DECREMENT';     crAddress: @AutoQSONumberDecrement;         crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:5; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO RETURN TO CQ MODE';        crAddress: @AutoReturnToCQMode;             crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO S&P ENABLE SENSITIVITY';   crAddress: @AutoSAPEnableRate;              crMin:10; crMax:10000;    crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'AUTO S&P ENABLE';               crAddress: @AutoSAPEnable;                  crMin:0;  crMax:0;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'AUTO SEND CHARACTER COUNT';     crAddress: pointer(2);                      crMin:0;  crMax:6;        crS: csOld; crA: 0; crC:0 ; crP:4; crJ: 0; crKind: ckArray; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'AUTO TIME INCREMENT';           crAddress: @AutoTimeIncrementQSOs;          crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'AUTO-CQ DELAY TIME';            crAddress: @AutoCQDelayTime;                crMin:500;crMax:10000;    crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'BACKCOPY ENABLE';               crAddress: @BackCopyEnable;                 crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND';                          crAddress: pointer(24);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctBand),
 (crCommand: 'BAND MAP ALL BANDS';            crAddress: @BandMapAllBands;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND MAP ALL MODES';            crAddress: @BandMapAllModes;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND MAP CALL WINDOW ENABLE';   crAddress: @BandMapCallWindowEnable;        crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND MAP CUTOFF FREQUENCY';     crAddress: @tBandMapCutoffFrequency;        crMin:0;  crMax:MAXWORD-1; crS: csOld; crA: 17;crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctFreqList),
 (crCommand: 'BAND MAP DECAY TIME';           crAddress: @BandMapDecayTime{BandMapDecayValue};              crMin:0;  crMax:MAXWORD; crS: csOld; crA: 5; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'BAND MAP DISPLAY CQ';           crAddress: @BandMapDisplayCQ;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND MAP DISPLAY LIMIT';        crAddress: @BandMapDisplayLimit;            crMin:30;  crMax:1000;   crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'BAND MAP DISPLAY GHZ';          crAddress: @BandMapDisplayGhz;              crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),     // n4af 4.42.8
 (crCommand: 'BAND MAP DUPE DISPLAY';         crAddress: @BandMapDupeDisplay;             crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND MAP ENABLE';               crAddress: @BandMapEnable;                  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND MAP GUARD BAND';           crAddress: @BandMapGuardBand;               crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'BAND MAP ITEM HEIGHT';           crAddress: @BandMapItemHeight;              crMin:15; crMax:50;      crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'BAND MAP ITEM WIDTH';            crAddress: @BandMapItemWidth;               crMin:100;crMax:200;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'BAND MAP MULTS ONLY';           crAddress: @BandMapMultsOnly;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BAND MAP SPLIT MODE';           crAddress: pointer(14);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'BEEP ENABLE';                   crAddress: @BeepEnable;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BEEP EVERY 10 QSOS';            crAddress: @BeepEvery10QSOs;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
// (crCommand: 'BIG REMAINING LIST';            crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'BOLD FONT';                     crAddress: @BoldFont;                       crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAppearance; crType: ctBoolean),
 (crCommand: 'BROADCAST ALL PACKET DATA';     crAddress: @Packet.BroadcastAllPacketData;  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CALL OK NOW CW MESSAGE';        crAddress: @CorrectedCallMessage;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CALL OK NOW MESSAGE';           crAddress: @CorrectedCallMessage;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CALL OK NOW SSB MESSAGE';       crAddress: @CorrectedCallPhoneMessage;      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CALL WINDOW POSITION';          crAddress: pointer(15);                     crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CALL WINDOW SHOW ALL SPOTS';    crAddress: @CallWindowShowAllSpots;         crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CALLSIGN UPDATE ENABLE';        crAddress: @CallsignUpdateEnable;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CATEGORY-ASSISTED';             crAddress: pointer(50);                     crMin:0;  crMax:0;       crS: csNew; crA:0; crC:1 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CATEGORY-BAND';                 crAddress: pointer(42);                     crMin:0;  crMax:0;       crS: csNew; crA:0; crC:1 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CATEGORY-MODE';                 crAddress: pointer(43);                     crMin:0;  crMax:0;       crS: csNew; crA:0; crC:1 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CATEGORY-OPERATOR';             crAddress: pointer(44);                     crMin:0;  crMax:0;       crS: csNew; crA:0; crC:1 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CATEGORY-POWER';                crAddress: pointer(45);                     crMin:0;  crMax:0;       crS: csNew; crA:0; crC:1 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CATEGORY-TRANSMITTER';          crAddress: pointer(49);                     crMin:0;  crMax:0;       crS: csNew; crA:0; crC:1 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CHECK LOG FILE SIZE';           crAddress: @CheckLogFileSize;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CLEAR DUPE SHEET';              crAddress: @ClearDupeSheetCommandGiven;     crMin:0;  crMax:0;       crS: csOld; crA: 4; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CODE SPEED';                    crAddress: @CodeSpeed;                      crMin:0;  crMax:99;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
// (crCommand: 'COLUMN DUPESHEET COLOR';        crAddress: @ColumnDupeSheetColor;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'COLUMN DUPESHEET ENABLE';        crAddress: @ColumnDupeSheetEnable;          crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'COMPLETE CALLSIGN MASK';        crAddress: @CompleteCallsignMask;           crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'COMPUTER ID';                   crAddress: @ComputerID;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctAlphaChar),
 (crCommand: 'COMPUTER NAME';                 crAddress: @ComputerName;                   crMin:0;  crMax:8;       crS: csNew; crA: 0; crC:0 ; crP:6; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'CONFIRM EDIT CHANGES';          crAddress: @ConfirmEditChanges;             crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CONNECTION AT STARTUP';         crAddress: @tConnectionAtStartup;           crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CONNECTION COMMAND';            crAddress: @ConnectionCommand;              crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'CONTACTS PER PAGE';             crAddress: @ContactsPerPage;                crMin:10; crMax:100;     crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'CONTEST NAME';                  crAddress: @ContestName;                    crMin:0;  crMax:80;      crS: csOld; crA: 7; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'CONTEST TITLE';                 crAddress: @ContestTitle;                   crMin:0;  crMax:255;     crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'CONTEST';                       crAddress: pointer(22);                     crMin:0;  crMax:0;       crS: csOld; crA: 1; crC:0 ; crP:0; crJ: 2; crKind: ckList;  cfFunc: cfAll; crType: ctOther),
// (crCommand: 'COPY FILES';                    crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOperation),
 (crCommand: 'COUNT DOMESTIC COUNTRIES';      crAddress: @CountDomesticCountries;         crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'COUNTRY INFORMATION FILE';      crAddress: @CountryInformationFile;         crMin:0;  crMax:255;     crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'CQ CW EXCHANGE NAME KNOWN';     crAddress: @CQExchangeNameKnown;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CQ CW EXCHANGE';                crAddress: @CQExchange;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CQ EXCHANGE NAME KNOWN';        crAddress: @CQExchangeNameKnown;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CQ EXCHANGE';                   crAddress: @CQExchange;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
// (crCommand: 'CQ MENU';                       crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'CQ SSB EXCHANGE NAME KNOWN';    crAddress: @CQPhoneExchangeNameKnown;       crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CQ SSB EXCHANGE';               crAddress: @CQPhoneExchange;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'CURTIS KEYER MODE';             crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctOther),
 (crCommand: 'CUSTOM CARET';                  crAddress: @tr4w_CustomCaret;               crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CUSTOM INITIAL EXCHANGE STRING';crAddress: @CustomInitialExchangeString;    crMin:0;  crMax:40;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'CUSTOM USER STRING';            crAddress: @CustomUserString;               crMin:0;  crMax:40;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'CW ENABLE';                     crAddress: @CWEnable;                       crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:7; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CW SPEED FROM DATABASE';        crAddress: @CWSpeedFromDataBase;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'CW SPEED INCREMENT';            crAddress: pointer(6);                      crMin:1;  crMax:10;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'CW TONE';                       crAddress: @CWTone;                         crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'DE ENABLE';                     crAddress: @DEEnable;                       crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'DIGITAL MODE ENABLE';           crAddress: @DigitalModeEnable;              crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
// (crCommand: 'DISPLAY MODE';                  crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'DISTANCE MODE';                 crAddress: pointer(20);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'DIT DAH RATIO';                 crAddress: pointer(13);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'DOMESTIC FILENAME';             crAddress: @DomQTHDataFileName;             crMin:0;  crMax:255;     crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctFileName),
 (crCommand: 'DOMESTIC MULTIPLIER';           crAddress: pointer(13);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctMultiplier),
 (crCommand: 'DUPE CHECK SOUND';              crAddress: pointer(12);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'DUPE SHEET AUTO RESET';         crAddress: @Sheet.tAutoReset;               crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'DUPE SHEET ENABLE';             crAddress: @Sheet.DupeSheetEnable;          crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
// (crCommand: 'DVK PORT';                      crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'DVK ENABLE';                    crAddress: @DVKEnable;                      crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:7; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'DVK LOCALIZED MESSAGES ENABLE'; crAddress: @DVKLocalizedMessagesEnable;     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'DVK PATH';                      crAddress: @TR4W_DVKPATH;                   crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctDirectory),
 (crCommand: 'DVK RECORDER';                  crAddress: @TR4W_DVP_RECORDER_FILENAME;     crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctFileName),
 (crCommand: 'DX MULTIPLIER';                 crAddress: pointer(11);                     crMin:0;  crMax:0;       crS: csOld; crA:20; crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctMultiplier),
 (crCommand: 'EIGHT BIT PACKET PORT';         crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'ESCAPE EXITS SEARCH AND POUNCE';crAddress: @EscapeExitsSearchAndPounce;     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'EX MENU';                       crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'EXCHANGE MEMORY ENABLE';        crAddress: @ExchangeMemoryEnable;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'EXCHANGE RECEIVED';             crAddress: pointer(10);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'EXCHANGE WINDOW S&P BACKGROUND';crAddress: pointer(48);                      crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:10; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'FARNSWORTH ENABLE';             crAddress: @FarnsworthEnable;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'FARNSWORTH SPEED';              crAddress: @FarnsworthSpeed;                crMin:0;  crMax:99;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
// (crCommand: 'FILTER BANDMAP';              crAddress: @FilterBandmap;                  crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'FLOPPY FILE SAVE FREQUENCY';    crAddress: @FloppyFileSaveFrequency;        crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'FLOPPY FILE SAVE NAME';         crAddress: @TR4W_FLOPPY_FILENAME;           crMin:0;  crMax:255;     crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctFileName),
 (crCommand: 'FOOT SWITCH MODE';              crAddress: pointer(9);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'FOOT SWITCH PORT';              crAddress: @ActiveFootSwitchPort;           crMin:0;  crMax:0;       crS: csOld; crA:0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctPortLPT),
 (crCommand: 'FREQUENCY ADDER RADIO ONE';     crAddress: @Radio1.FrequencyAdder;          crMin:0;  crMax:MAXWORD-1; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'FREQUENCY ADDER RADIO TWO';     crAddress: @Radio2.FrequencyAdder;          crMin:0;  crMax:MAXWORD-1; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'FREQUENCY MEMORY ENABLE';       crAddress: @FrequencyMemoryEnable;          crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'FREQUENCY MEMORY';              crAddress: @tFrequencyMemory;               crMin:0;  crMax:0;       crS: csOld; crA: 18;crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctFreqList),
 (crCommand: 'FREQUENCY POLL RATE';           crAddress: @FreqPollRate;                   crMin:10; crMax:1000;    crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'FT1000MP CW REVERSE';           crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'GRID MAP CENTER';               crAddress: @GridMapCenter;                  crMin:0;  crMax:6;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'HAND LOG MODE';                 crAddress: @tHandLogMode;                   crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:1 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'HF BAND ENABLE';                crAddress: @HFBandEnable;                   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'HOUR DISPLAY';                  crAddress: pointer(8);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
// (crCommand: 'HOUR OFFSET';                   crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
// (crCommand: 'ICOM COMMAND PAUSE';            crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'ICOM RESPONSE TIMEOUT';         crAddress: @newIcomResponseTimeout{F_ICOM_RESPONSE_TIMEOUT};        crMin:10;crMax:1000;    crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'INCLUDE F-KEY NUMBER';          crAddress: @tIncludeFKeyNumber;             crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'INCREMENT TIME ENABLE';         crAddress: @IncrementTimeEnable;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'INITIAL EXCHANGE';              crAddress: Pointer(7);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'INITIAL EXCHANGE CURSOR POS';   crAddress: pointer(6);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'INITIAL EXCHANGE FILENAME';     crAddress: @TR4W_INITIALEX_FILENAME;        crMin:0;  crMax:255;     crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctFilename),
 (crCommand: 'INITIAL EXCHANGE OVERWRITE';    crAddress: @InitialExchangeOverwrite;       crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
// (crCommand: 'INPUT CONFIG FILE';             crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'INSERT MODE';                   crAddress: @InsertMode;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:8; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'INTERCOM FILE ENABLE';          crAddress: @IntercomFileenable;             crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
// (crCommand: 'JST RESPONSE TIMEOUT';          crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
// (crCommand: 'K1EA NETWORK ENABLE';           crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
// (crCommand: 'K1EA STATION ID';               crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctChar),
// (crCommand: 'KENWOOD RESPONSE TIMEOUT';      crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'KEYER RADIO ONE OUTPUT PORT';   crAddress: pointer(38);                     crMin:0;  crMax:0;       crS: csOld; crA: 12; crC:0 ; crP:0; crJ: 2; crKind: ckList;  cfFunc: cfAll; crType: ctOther),
 (crCommand: 'KEYER RADIO TWO OUTPUT PORT';   crAddress: pointer(39);                     crMin:0;  crMax:0;       crS: csOld; crA: 13; crC:0 ; crP:0; crJ: 2; crKind: ckList;  cfFunc: cfAll; crType: ctOther),
 (crCommand: 'KEYPAD CW MEMORIES';            crAddress: @KeypadCWMemories;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'LATEST CONFIG FILE';            crAddress: @TR4W_LATESTCFG_FILENAME;        crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctFilename),
 (crCommand: 'LEADING ZERO CHARACTER';        crAddress: @LeadingZeroCharacter;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'LEADING ZEROS';                 crAddress: pointer(14);                     crMin:0;  crMax:3;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckArray;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'LEAVE CURSOR IN CALL WINDOW';   crAddress: @LeaveCursorInCallWindow;        crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'LITERAL DOMESTIC QTH';          crAddress: @LiteralDomesticQTH;             crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'LOG FILE NAME';                 crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'LOG FREQUENCY ENABLE';          crAddress: @LogFrequencyEnable;             crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'LOG RS SENT';                   crAddress: @LogRSSent;                      crMin:11; crMax:59;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctWord),
 (crCommand: 'LOG RST SENT';                  crAddress: @LogRSTSent;                     crMin:111;crMax:599;     crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctWord),
 (crCommand: 'LOG SUB TITLE';                 crAddress: @LogSubTitle;                    crMin:0;  crMax:40;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'LOG WITH SINGLE ENTER';         crAddress: @LogWithSingleEnter;             crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'LOOK FOR RST SENT';             crAddress: @LookForRSTSent;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'LPT1 BASE ADDRESS';             crAddress: @LPTBaseAA[Parallel1];           crMin:0;  crMax:MAXWORD; crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'LPT2 BASE ADDRESS';             crAddress: @LPTBaseAA[Parallel2];           crMin:0;  crMax:MAXWORD; crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'LPT3 BASE ADDRESS';             crAddress: @LPTBaseAA[Parallel3];           crMin:0;  crMax:MAXWORD; crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MAIN CALLSIGN';                 crAddress: @MainCallsign;                   crMin:0;  crMax:13;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'MAIN FONT';                     crAddress: @MainFontName;                   crMin:0;  crMax:30;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAppearance; crType: ctString),
 (crCommand: 'MESSAGE ENABLE';                crAddress: @MessageEnable;                  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MINITOUR DURATION';             crAddress: @TourDuration;                   crMin:5;  crMax:60;      crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MISSINGCALLSIGNS FILE ENABLE';  crAddress: @tMissCallsFileEnable;           crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MMTTY ENGINE';                  crAddress: @TR4W_MMTTYPATH;                 crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctFileName),
 (crCommand: 'MODE';                          crAddress: pointer(5);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'MODEM PORT BAUD RATE';          crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MODEM PORT';                    crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'MOUSE ENABLE';                  crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MP3 PATH';                      crAddress: @TR4W_MP3PATH;                   crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAll; crType: ctDirectory),
 (crCommand: 'MP3 PLAYER';                    crAddress: @TR4W_MP3_PLAYER_FILENAME;       crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctFileName),
 (crCommand: 'MP3 RECORDER BITRATE';          crAddress: pointer(9);                      crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckArray; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MP3 RECORDER DURATION';         crAddress: pointer(41);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfAll; crType: ctOther),
 (crCommand: 'MP3 RECORDER ENABLE';           crAddress: @RecorderEnable;                 crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MP3 RECORDER SAMPLERATE';       crAddress: pointer(10);                     crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckArray; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MULT BY BAND';                  crAddress: @MultByBand;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MULT BY MODE';                  crAddress: @MultByMode;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MULT REPORT MINIMUM BANDS';     crAddress: pointer(7);                      crMin:2;  crMax:5;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MULTI INFO MESSAGE';            crAddress: @MultiInfoMessage;               crMin:0;  crMax:20;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MULTI MULTS ONLY';              crAddress: @MultiMultsOnly;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MULTI PORT BAUD RATE';          crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MULTI PORT';                    crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'MULTI RETRY TIME';              crAddress: @MultiRetryTime;                 crMin:3;  crMax:10;      crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'MULTI UPDATE MULT DISPLAY';     crAddress: @MultiUpdateMultDisplay;         crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MULTIPLE BANDS';                crAddress: @MultipleBandsEnabled;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MULTIPLE MODES';                crAddress: @MultipleModesEnabled;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MULT SHEET AUTO RESET';         crAddress: @MultReset   ;                   crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'MY CALL';                       crAddress: @MyCall;                         crMin:0;  crMax:13;      crS: csOld; crA: 14;crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY CHECK';                      crAddress: @MyCheck;                        crMin:0;  crMax:10;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY CONTINENT';                  crAddress: pointer(21);                     crMin:0;  crMax:0;       crS: csOld; crA: 22;crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'MY COUNTRY';                    crAddress: @MyCountry;                      crMin:0;  crMax:20;      crS: csOld; crA: 8; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY FD CLASS';                   crAddress: @MyFDClass;                      crMin:0;  crMax:10;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY FOC NUMBER';                 crAddress: @MyFOCNumber;                    crMin:0;  crMax:10;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),      //n4af 04.32.5
 (crCommand: 'MY GRID';                       crAddress: @MyGrid;                         crMin:0;  crMax:7;        crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY IOTA';                       crAddress: @MyIOTA;                         crMin:0;  crMax:20;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY NAME';                       crAddress: @MyName;                         crMin:0;  crMax:20;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY POSTAL CODE';                crAddress: @MyPostalCode;                   crMin:0;  crMax:20;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY PREC';                       crAddress: @MyPrec;                         crMin:0;  crMax:10;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY QTH';                        crAddress: @MyState;                        crMin:0;  crMax:20;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY SECTION';                    crAddress: @MySection;                      crMin:0;  crMax:10;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY STATE';                      crAddress: @MyState;                        crMin:0;  crMax:20;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'MY ZONE';                       crAddress: @MyZone;                         crMin:0;  crMax: 6;       crS: csOld; crA: 21;crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'NAME FLAG ENABLE';              crAddress: @NameFlagEnable;                 crMin:0;  crMax: 0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'NET STATUS UPDATE INTERVAL';    crAddress: @tNetStatusUpdateInterval;       crMin:1000;crMax:10000;   crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'NO BORDER';                     crAddress: @NoBorder;                       crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAppearance; crType: ctBoolean),
 (crCommand: 'NO CAPTION';                    crAddress: @NoCaption;                      crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAppearance; crType: ctBoolean),
 (crCommand: 'NO COLUMN HEADER';              crAddress: @NoColumnHeader;                 crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAppearance; crType: ctBoolean),
 (crCommand: 'NO LOG';                        crAddress: @NoLog;                          crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'NO POLL DURING PTT';            crAddress: @NoPollDuringPTT;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'ORION PORT';                    crAddress: pointer(40);                     crMin:0;  crMax:0;       crS: csOld; crA: 3; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'PACKET ADD LF';                 crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PACKET AUTO CR';                crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PACKET BAND SPOTS';             crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PACKET BAUD RATE';              crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'PACKET BEEP';                   crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PACKET LOG FILENAME';           crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'PACKET PORT BAUD RATE';         crAddress: nil;                             crMin:0;  crMax:57600;   crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'PACKET PORT';                   crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'PACKET RETURN PER MINUTE';      crAddress: nil;                             crMin:0;  crMax:MAXWORD; crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'PACKET SPOT COMMENT';           crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'PACKET SPOT DISABLE';           crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PACKET SPOT EDIT ENABLE';       crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PACKET SPOT KEY';               crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctChar),
 (crCommand: 'PACKET SPOT PREFIX ONLY';       crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PACKET SPOTS';                  crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'PADDLE BUG ENABLE';             crAddress: @PaddleBug;                      crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PADDLE MONITOR TONE';           crAddress: @PaddleMonitorTone;              crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'PADDLE PORT';                   crAddress: @ActivePaddlePort;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctPortLPT),
 (crCommand: 'PADDLE PTT HOLD COUNT';         crAddress: @PaddlePTTHoldCount;             crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'PADDLE SPEED';                  crAddress: @PaddleSpeed;                    crMin:0;  crMax:99;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'PARTIAL CALL ENABLE';           crAddress: @PartialCallEnable;              crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PARTIAL CALL LOAD LOG ENABLE';  crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PARTIAL CALL MULT INFO ENABLE'; crAddress: nil{@PartialCallMultsEnable};    crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'POLL RADIO ONE';                crAddress: @Radio1.PollingEnable;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'POLL RADIO TWO';                crAddress: @Radio2.PollingEnable;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'POSSIBLE CALL ACCEPT KEY';      crAddress: @PossibleCallAcceptKey;          crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'POSSIBLE CALL LEFT KEY';        crAddress: @PossibleCallLeftKey;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'POSSIBLE CALL MODE';            crAddress: pointer(4);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'POSSIBLE CALL RIGHT KEY';       crAddress: @PossibleCallRightKey;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'POSSIBLE CALLS';                crAddress: @PossibleCallEnable;             crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PREFIX MULTIPLIER';             crAddress: pointer(3);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctMultiplier),
 (crCommand: 'PRINTER ENABLE';                crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PTT ENABLE';                    crAddress: @PTTEnable;                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PTT LOCKOUT';                   crAddress: @PTTLockout;                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'PTT TURN ON DELAY';             crAddress: @PTTTurnOnDelay;                 crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'PTT VIA COMMANDS';              crAddress: @tPTTViaCommand;                 crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QSL CW MESSAGE';                crAddress: @QSLMessage;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QSL MESSAGE';                   crAddress: @QSLMessage;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QSL MODE';                      crAddress: pointer(2);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'QSL SSB MESSAGE';               crAddress: @QSLPhoneMessage;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QSO BEFORE CW MESSAGE';         crAddress: @QSOBeforeMessage;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QSO BEFORE MESSAGE';            crAddress: @QSOBeforeMessage;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QSO BEFORE SSB MESSAGE';        crAddress: @QSOBeforePhoneMessage;          crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QSO BY BAND';                   crAddress: @QSOByBand;                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QSO BY MODE';                   crAddress: @QSOByMode;                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QSO NUMBER BY BAND';            crAddress: @QSONumberByBand;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QSO POINT METHOD';              crAddress: pointer(1);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'QSO POINTS DOMESTIC CW';        crAddress: @QSOPointsDomesticCW;            crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'QSO POINTS DOMESTIC PHONE';     crAddress: @QSOPointsDomesticPhone;         crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'QSO POINTS DX CW';              crAddress: @QSOPointsDXCW;                  crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'QSO POINTS DX PHONE';           crAddress: @QSOPointsDXPhone;               crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'QSY INACTIVE RADIO';            crAddress: @QSYInactiveRadio;       crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean), //Gav 4.37.12
 (crCommand: 'QSX ENABLE';                    crAddress: @QSXEnable;                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QTC ENABLE';                    crAddress: @QTCsEnabled;                    crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QTC EXTRA SPACE';               crAddress: @QTCExtraSpace;                  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QTC MINUTES';                   crAddress: @QTCMinutes;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QTC QRS';                       crAddress: @QTCQRS;                         crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'QUESTION MARK CHAR';            crAddress: @QuestionMarkChar;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'QUICK QSL CW MESSAGE';          crAddress: @QuickQSLMessage1;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QUICK QSL CW MESSAGE1';         crAddress: @QuickQSLMessage1;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QUICK QSL KEY 1';               crAddress: @QuickQSLKey1;                   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'QUICK QSL KEY 2';               crAddress: @QuickQSLKey2;                   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'QUICK QSL KEY';                 crAddress: @QuickQSLKey1;                   crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'QUICK QSL MESSAGE 1';           crAddress: @QuickQSLMessage1;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QUICK QSL MESSAGE 2';           crAddress: @QuickQSLMessage2;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QUICK QSL MESSAGE';             crAddress: @QuickQSLMessage1;               crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QUICK QSL SSB MESSAGE';         crAddress: @QuickQSLPhoneMessage;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'QZB RANDOM OFFSET ENABLE';      crAddress: @QZBRandomOffsetEnable;          crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'R150S MODE';                    crAddress: @CTY.ctyR150SMode;               crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'RFOBL MODE';                    crAddress: @CTY.ctyRFOBLMode;               crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'RADIO ONE BAND OUTPUT PORT';    crAddress: @Radio1.BandOutputPort;          crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfRadio1; crType: ctPortLPT),
 (crCommand: 'RADIO ONE BAUD RATE';           crAddress: pointer(11);                     crMin:0;  crMax:57600;   crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray; cfFunc: cfRadio1; crType: ctInteger),
 (crCommand: 'RADIO ONE CAT DTR';             crAddress: pointer(29);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;   cfFunc: cfRadio1; crType: ctOther),
 (crCommand: 'RADIO ONE CAT RTS';             crAddress: pointer(28);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;   cfFunc: cfRadio1; crType: ctOther),
 (crCommand: 'RADIO ONE COMMAND PAUSE';       crAddress: @Radio1.CommandPause;            crMin:0;  crMax:MAXWORD; crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfRadio1; crType: ctInteger),
 (crCommand: 'RADIO ONE CONTROL PORT';        crAddress: pointer(36);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;  cfFunc: cfRadio1; crType: ctOther),
 (crCommand: 'RADIO ONE CW BY CAT';           crAddress: @Radio1.CWByCAT;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),   // ny4i 4.44.5
 (crCommand: 'RADIO ONE CW SPEED SYNC';       crAddress: @Radio1.CWSpeedSync;             crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'RADIO ONE FREQUENCY ADDER';     crAddress: @Radio1.FrequencyAdder;          crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfRadio1; crType: ctInteger),
 (crCommand: 'RADIO ONE FT1000MP CW REVERSE'; crAddress: @Radio1.FT1000MPCWReverse;       crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'RADIO ONE ICOM FILTER BYTE';    crAddress: pointer(15);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'RADIO ONE ID CHARACTER';        crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctChar),
 (crCommand: 'RADIO ONE KEYER DTR';           crAddress: pointer(31);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;   cfFunc: cfRadio1; crType: ctOther),
 (crCommand: 'RADIO ONE KEYER RTS';           crAddress: pointer(30);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;   cfFunc: cfRadio1; crType: ctOther),
 (crCommand: 'RADIO ONE NAME';                crAddress: @Radio1.RadioName;               crMin:0;  crMax:20;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'RADIO ONE RECEIVER ADDRESS';    crAddress: @Radio1.ReceiverAddress;         crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfRadio1; crType: ctInteger),
 (crCommand: 'RADIO ONE TRACKING ENABLE';     crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfRadio1; crType: ctBoolean),
 (crCommand: 'RADIO ONE TYPE';                crAddress: pointer(26);                     crMin:0;  crMax:0;       crS: csOld; crA: 9; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfRadio1; crType: ctOther),
 (crCommand: 'RADIO ONE UPDATE SECONDS';      crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfRadio1; crType: ctInteger),
 (crCommand: 'RADIO ONE WIDE CW FILTER';      crAddress: @Radio1.WideCWFilter;       crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfRadio1; crType: ctBoolean),
 (crCommand: 'RADIO TWO BAND OUTPUT PORT';    crAddress: @Radio2.BandOutputPort;          crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfRadio2; crType: ctPortLPT),
 (crCommand: 'RADIO TWO BAUD RATE';           crAddress: pointer(12);                     crMin:0;  crMax:57600;   crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckArray; cfFunc: cfRadio2; crType: ctInteger),
 (crCommand: 'RADIO TWO CAT DTR';             crAddress: pointer(33);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList;   cfFunc: cfRadio2; crType: ctOther),
 (crCommand: 'RADIO TWO CAT RTS';             crAddress: pointer(32);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList;   cfFunc: cfRadio2; crType: ctOther),
 (crCommand: 'RADIO TWO COMMAND PAUSE';       crAddress: @Radio2.CommandPause;            crMin:0;  crMax:MAXWORD; crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'RADIO TWO CONTROL PORT';        crAddress: pointer(37);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList;  cfFunc: cfRadio2; crType: ctOther),
 (crCommand: 'RADIO TWO CW BY CAT';           crAddress: @Radio2.CWByCAT;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),  // ny4i 4.44.5
 (crCommand: 'RADIO TWO CW SPEED SYNC';       crAddress: @Radio2.CWSpeedSync;             crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),    // ny4i 4.44.5
 (crCommand: 'RADIO TWO FREQUENCY ADDER';     crAddress: @Radio2.FrequencyAdder;          crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfRadio2; crType: ctInteger),
 (crCommand: 'RADIO TWO FT1000MP CW REVERSE'; crAddress: @Radio2.FT1000MPCWReverse;       crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'RADIO TWO ICOM FILTER BYTE';    crAddress: pointer(16);          crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'RADIO TWO ID CHARACTER';        crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctChar),
 (crCommand: 'RADIO TWO KEYER DTR';           crAddress: pointer(35);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList;   cfFunc: cfRadio2; crType: ctOther),
 (crCommand: 'RADIO TWO KEYER RTS';           crAddress: pointer(34);                     crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckList;   cfFunc: cfRadio2; crType: ctOther),
 (crCommand: 'RADIO TWO NAME';                crAddress: @Radio2.RadioName;               crMin:0;  crMax:20;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'RADIO TWO RECEIVER ADDRESS';    crAddress: @Radio2.ReceiverAddress;         crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfRadio2; crType: ctInteger),
 (crCommand: 'RADIO TWO TRACKING ENABLE';     crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'RADIO TWO TYPE';                crAddress: pointer(27);                     crMin:0;  crMax:0;       crS: csOld; crA: 10;crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfRadio2; crType: ctOther),
 (crCommand: 'RADIO TWO UPDATE SECONDS';      crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'RADIO TWO WIDE CW FILTER';      crAddress: @Radio2.WideCWFilter;       crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfRadio2; crType: ctBoolean),
 (crCommand: 'RADIUS OF EARTH';               crAddress: @RadiusOfEarth;                  crMin:0;  crMax:MAXWORD;   crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctReal),
 (crCommand: 'RANDOM CQ MODE';                crAddress: @RandomCQMode;                   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'RATE DISPLAY';                  crAddress: pointer(0);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'RELAY CONTROL PORT';            crAddress: @RelayControlPort;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfRadio1; crType: ctPortLPT),
 (crCommand: 'REMAINING MULT DISPLAY MODE';   crAddress: pointer(16);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:2; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'REMINDER';                      crAddress: pointer(51);                   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal; cfFunc: cfAppearance; crType: ctOther),
 (crCommand: 'REPEAT S&P CW EXCHANGE';        crAddress: @RepeatSearchAndPounceExchange;  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'REPEAT S&P EXCHANGE';           crAddress: @RepeatSearchAndPounceExchange;  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'REPEAT S&P SSB EXCHANGE';       crAddress: @RepeatSearchAndPouncePhoneExchange; crMin:0;  crMax:0;   crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'ROTATOR PORT';                  crAddress: pointer(40);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckList;  cfFunc: cfAll; crType: ctOther),
 (crCommand: 'ROTATOR TYPE';                  crAddress: pointer(17);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'ROW COUNT';                     crAddress: pointer(4);                      crMin:5;  crMax:15;      crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckArray; cfFunc: cfAppearance; crType: ctInteger),
 (crCommand: 'RTTY PORT';                     crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'RTTY RECEIVE STRING';           crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'RTTY SEND STRING';              crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'S&P CW EXCHANGE';               crAddress: @SearchAndPounceExchange;        crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'S&P EXCHANGE';                  crAddress: @SearchAndPounceExchange;        crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'S&P SSB EXCHANGE';              crAddress: @SearchAndPouncePhoneExchange;   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'SAY HI ENABLE';                 crAddress: @SayHiEnable;                    crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SAY HI RATE CUTOFF';            crAddress: @SayHiRateCutOff;                crMin:0;  crMax:MAXWORD; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'SCORE POSTING ID';              crAddress: @GetScoresPostingID;             crMin:0;  crMax:MAXWORD; crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'SCORE POSTING URL';             crAddress: @GetScoresSeverPostingAddress;   crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctURL),
 (crCommand: 'SCORE READING URL';             crAddress: @GetScoresSeverReadingAddress;   crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctURL),
 (crCommand: 'SCP COUNTRY STRING';            crAddress: @CD.CountryString;               crMin:0;  crMax:80;      crS: csOld; crA: 11;crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'SCP MINIMUM LETTERS';           crAddress: pointer(1);                      crMin:0;  crMax:5;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'SEND ALT-D SPOTS TO PACKET';    crAddress: @SendAltDSpotsToPacket;          crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SEND COMPLETE FOUR LETTER CALL';crAddress: @SendCompleteFourLetterCall;     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SEND QSO IMMEDIATELY';          crAddress: @SendQSOImmediately;             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SERIAL 5 PORT ADDRESS';         crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'SERIAL 6 PORT ADDRESS';         crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'SERIAL PORT DEBUG';             crAddress: @CPUKeyer.SerialPortDebug;       crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SERVER ADDRESS';                crAddress: @ServerAddress;                  crMin:0;  crMax:255;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'SERVER PASSWORD';               crAddress: @ServerPassword;                 crMin:0;  crMax:10;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'SERVER PORT';                   crAddress: @ServerPort;                     crMin:0;  crMax:MAXWORD; crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'SHIFT KEY ENABLE';              crAddress: @ShiftKeyEnable;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SHORT 0';                       crAddress: @Short0;                         crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'SHORT 1';                       crAddress: @Short1;                         crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'SHORT 2';                       crAddress: @Short2;                         crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'SHORT 9';                       crAddress: @Short9;                         crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 2; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'SHORT INTEGERS';                crAddress: @ShortIntegers;                  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SHOW DOMESTIC MULTIPLIER NAME'; crAddress: @tShowDomesticMultiplierName;    crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:9; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SHOW FREQUENCY IN LOG';         crAddress: @tShowFrequencyinLog;            crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SHOW GRIDLINES';                crAddress: @tShowGridlines;                 crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:3; crJ: 0; crKind: ckNormal;   cfFunc: cfAppearance; crType: ctBoolean),
 (crCommand: 'SHOW SEARCH AND POUNCE';        crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SHOW TYPED CALLSIGN';           crAddress: @tShowTypedCallsign;             crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SIMULATOR ENABLE';              crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SINGLE BAND SCORE';             crAddress: pointer(25);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctBand),
 (crCommand: 'SINGLE RADIO MODE';             crAddress: @SingleRadioMode;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SKIP ACTIVE BAND';              crAddress: @SkipActiveBand;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SLASH MARK CHAR';               crAddress: @SlashMarkChar;                  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'SPACE BAR DUPE CHECK ENABLE';   crAddress: @SpaceBarDupeCheckEnable;        crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SPRINT QSY RULE';               crAddress: @SprintQSYRule;                  crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'START SENDING NOW KEY';         crAddress: @StartSendingNowKey;             crMin:0;  crMax:0;       crS: csOld; crA: 19;crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),
 (crCommand: 'STATIONS CALLSIGNS MASK';        crAddress: @StationsCallsignsMask;         crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:1 ; crP:12; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'STEREO CONTROL PIN';            crAddress: pointer(8);                      crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckArray; cfFunc: cfAll; crType: ctinteger),
 (crCommand: 'STEREO CONTROL PORT';           crAddress: @ActiveStereoPort;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctPortLPT),
 (crCommand: 'STEREO PIN HIGH';               crAddress: @StereoPinState;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SWAP PACKET SPOT RADIOS';       crAddress: @SwapPacketSpotRadios;           crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SWAP PADDLES';                  crAddress: @SwapPaddles;                    crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'SWAP RADIO RELAY SENSE';        crAddress: @SwapRadioRelaySense;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'TAB MODE';                      crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctOther),
 // (crCommand: 'TAIL END CW MESSAGE';           crAddress: @TailEndMessage;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),     //n4af 4.41.5
// (crCommand: 'TAIL END KEY';                  crAddress: @TailEndKey;                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctChar),         // n4af 4.41.5
 //(crCommand: 'TAIL END MESSAGE';              crAddress: @TailEndMessage;                 crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
// (crCommand: 'TAIL END SSB MESSAGE';          crAddress: @TailEndPhoneMessage;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 3; crKind: ckNormal;  cfFunc: cfAll; crType: ctMessage),
 (crCommand: 'TELNET SERVER';                 crAddress: @TelnetServer;                   crMin:0;  crMax:255;     crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAll; crType: ctString),
 (crCommand: 'TEN MINUTE RULE';               crAddress: pointer(18);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'TOTAL OFF TIME';                crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'TOTAL SCORE MESSAGE';           crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctString),
 (crCommand: 'TUNE ALT-D ENABLE';             crAddress: @TuneDupeCheckEnable;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'TUNE WITH DITS';                crAddress: @TuneWithDits;                   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'TWO RADIO MODE';                crAddress: @TwoRadioMode;                   crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
// Not needed as N1MM doesn't send this either... (crCommand: 'UDP BROADCAST APP INFO';        crAddress: @UDPBroadcastAppInfo;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),  // ny4i 4.44.9
 (crCommand: 'UDP BROADCAST CONTACT INFO';    crAddress: @UDPBroadcastContact;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),  // ny4i 4.44.9
 (crCommand: 'UDP BROADCAST RADIO INFO';      crAddress: @UDPBroadcastRadio;              crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),  // ny4i 4.44.9
 (crCommand: 'UDP BROADCAST ROTOR';           crAddress: @UDPBroadcastRotor;              crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),  // ny4i 4.44.9
 (crCommand: 'UDP BROADCAST PORT';            crAddress: @UDPBroadcastPort;               crMin:1;  crMax:65535;   crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),   // ny4i 4.44.9
 (crCommand: 'UDP BROADCAST ROTOR PORT';      crAddress: @UDPBroadcastRotorPort;          crMin:1;  crMax:65535;   crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),   // ny4i 4.44.9
 (crCommand: 'UDP BROADCAST ADDRESS';         crAddress: @UDPBroadcastAddress;            crMin:0;  crMax:255;      crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),  // ny4i 4.44.9
 (crCommand: 'UDP BROADCAST ALL QSOS';        crAddress: @UDPBroadcastAllQSOs;            crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),  // ny4i Issue 82

 (crCommand: 'UNKNOWN COUNTRY FILE ENABLE';   crAddress: @UnknownCountryFileEnable;       crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'UNKNOWN COUNTRY FILE NAME';     crAddress: @UnknownCountryFileName;         crMin:0;  crMax:255;     crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctString),
 (crCommand: 'UPDATE RESTART FILE ENABLE';    crAddress: @UpdateRestartFileEnable;        crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'USE BIOS KEY CALLS';            crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'USE CONTROL PORT';              crAddress: @tUseControlPort;                crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'USE IRQS';                      crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'USE RECORDED SIGNS';            crAddress: @tUseRecordedSigns;              crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;   cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'USER INFO SHOWN';               crAddress: pointer(19);                     crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList; cfFunc: cfAll; crType: ctOther),
 (crCommand: 'VGA DISPLAY ENABLE';            crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'VHF BAND ENABLE';               crAddress: @VHFBandsEnabled;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:1 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'VISIBLE DUPESHEET';             crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'WAIT FOR STRENGTH';             crAddress: @WaitForStrength;                crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'WAKE UP TIME OUT';              crAddress: @WakeUpTimeOut;                  crMin:0;  crMax:MAXBYTE; crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'WARC BAND ENABLE';              crAddress: @WARCBandsEnabled;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:1; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'WEIGHT';                        crAddress: @Weight;                         crMin:5;  crMax:15;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctReal),
 (crCommand: 'WIDE FREQUENCY DISPLAY';        crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'WILDCARD PARTIALS';             crAddress: @WildCardPartials;               crMin:0;  crMax:0;       crS: csOld; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfAll; crType: ctBoolean),
 (crCommand: 'WK AUTOSPACE';                  crAddress: @WinKeySettings.wksAutospace;                    crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctBoolean),
 (crCommand: 'WK CT SPACING';                 crAddress: @WinKeySettings.wksCTSpacing;                    crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctBoolean),
 (crCommand: 'WK DIT DAH RATIO';              crAddress: @WinKeySettings.wksValueList.vlDitDahRatio;      crMin:33; crMax:66;        crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctByte),
 (crCommand: 'WK ENABLE';                     crAddress: @WinKeySettings.wksWinKey2Enable;                crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctBoolean),
 (crCommand: 'WK FIRST EXTENSION';            crAddress: @WinKeySettings.wksValueList.vl1stExtension;     crMin:0;  crMax:250;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctByte),
 (crCommand: 'WK IGNORE SPEED POT';           crAddress: @WinKeySettings.wksIgnoreSpeedSpot;              crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctBoolean),
 (crCommand: 'WK KEYER COMPENSATION';         crAddress: @WinKeySettings.wksValueList.vlKeyCompensation;  crMin:0;  crMax:250;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctByte),
 (crCommand: 'WK KEYER MODE';                 crAddress: pointer(47);                                     crMin:0;  crMax:0;         crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfWK; crType: ctOther),
 (crCommand: 'WK LEADIN TIME';                crAddress: @WinKeySettings.wksValueList.vlLeadInTime;       crMin:0;  crMax:250;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctByte),
 (crCommand: 'WK PADDLE ONLY SIDETONE';       crAddress: @WinKeySettings.wksPadOnlySideT;                 crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctBoolean),
 (crCommand: 'WK PADDLE SWAP';                crAddress: @WinKeySettings.wksPaddleSwap;                   crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctBoolean),
 (crCommand: 'WK PADDLE SWITCHPOINT';         crAddress: @WinKeySettings.wksValueList.vlPaddleSWPoint;    crMin:10; crMax:90;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctByte),
 (crCommand: 'WK PORT';                       crAddress: pointer(46);                                     crMin:0;  crMax:0;         crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfWK; crType: ctOther),
 (crCommand: 'WK SIDETONE FREQUENCY';         crAddress: pointer(48);                                     crMin:0;  crMax:0;         crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckList;    cfFunc: cfWK; crType: ctOther),
 (crCommand: 'WK SIDETONE ENABLE';            crAddress: @WinKeySettings.wksSideTEnable;                  crMin:0;  crMax:0;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctBoolean),
 (crCommand: 'WK TAIL TIME';                  crAddress: @WinKeySettings.wksValueList.vlTailTime;         crMin:0;  crMax:250;       crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctByte),
 (crCommand: 'WK WEIGHT';                     crAddress: @WinKeySettings.wksValueList.vlWeight;           crMin:10; crMax:90;        crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal;  cfFunc: cfWK; crType: ctByte),
 (crCommand: 'WINDOW SIZE';                   crAddress: pointer(5);                      crMin:1;  crMax:15;      crS: csNew; crA: 0; crC:0 ; crP:0; crJ: 1; crKind: ckArray; cfFunc: cfAppearance; crType: ctInteger),
 (crCommand: 'YAESU RESPONSE TIMEOUT';        crAddress: nil;                             crMin:0;  crMax:0;       crS: csRem; crA: 0; crC:0 ; crP:0; crJ: 0; crKind: ckNormal; cfFunc: cfAll; crType: ctInteger),
 (crCommand: 'ZONE MULTIPLIER';               crAddress: pointer(23);                     crMin:0;  crMax:0;       crS: csOld; crA: 2; crC:0 ; crP:0; crJ: 2; crKind: ckList; cfFunc: cfAll; crType: ctMultiplier)
    {*)}
    );
function CheckCommand(Command: PChar; CustomCMD: ShortString): boolean;
function ProcessMessage(ID, CMD: ShortString): boolean;
procedure ProcessReminder(ID, CMD: ShortString);
procedure ProcessTotalScoreMessage(ID, CMD: ShortString);
procedure InitializeStrings;

var
  Changed                               : array[0..CommandsArraySize - 1] of boolean;

implementation
uses MainUnit;
var
  TempBand                              : BandType;
  TempMode                              : ModeType;
  TempFreq                              : integer;

  Result1                               : integer;

function CheckCommand(Command: PChar; CustomCMD: ShortString): boolean;
label
  AdditionalProc;
var
  i                                     : integer;
  TempInteger                           : integer;
  TempInteger2                          : integer;
  TempReal                              : REAL;
  code                                  : integer;
  Proc                                  : Pointer;
  TempByte                              : Byte;
  TempString                            : Str10;
  TempElement                           : TMainWindowElement;
begin
{$IF MAKE_DEFAULT_VALUES = TRUE}
  Result := True;
  Exit;
{$IFEND}

  Command[Ord(Command[0]) + 1] := #0;
  Result := False;

  if length(pshortstring(Command)^) > 5 then

    if pshortstring(Command)^[1] in ['C', 'E'] then
      if pshortstring(Command)^[3] in [' '] then
        if pshortstring(Command)^[4] in ['S', 'C', 'D', 'M'] then
//          if pshortstring(Command)^[7] in [' ', 'M', 'O'] then
          if pshortstring(Command)^[10] in ['M', 'O', ' '] then
          begin
            Result := ProcessMessage(pshortstring(Command)^, CustomCMD);

            Exit;
          end;
{
  if pshortstring(Command)^ = 'REMINDER' then
  begin
    ProcessReminder(pshortstring(Command)^, CustomCMD);
    Result := True;
    Exit;
  end;
 }
  if pshortstring(Command)^ = 'TOTAL SCORE MESSAGE' then
  begin
    //ProcessTotalScoreMessage(pshortstring(Command)^, CustomCMD);
    Result := True;
    Exit;
  end;

  if StrPos(@Command[1], ' WINDOW ') <> nil then
  begin
    for TempElement := Low(TMainWindowElement) to High(TMainWindowElement) do
    begin

      if StrPos(@Command[1], TWindows[TempElement].mweName) = @Command[1] then
      begin
        TempByte := GetValueFromArray(@tr4wColorsSA, Byte(High(tr4wColors)), @CustomCMD);
        if TempByte <> UNKNOWNTYPE then
        begin
          if StrPos(@Command[1], ' COLOR') <> nil then
            TWindows[TempElement].mweColor := tr4wColors(TempByte)
          else
            TWindows[TempElement].mweBackG := tr4wColors(TempByte);
          Result := True;
          Exit;
        end
        else
          Break;

      end;

    end;
  end;

  for i := 1 to CommandsArraySize do
//    if (CFGCA[i].crCommand[0] = 'L') then
    if (StrComp(@Command[1], CFGCA[i].crCommand) = 0) then
    begin
//      if pshortstring(Command)^ = 'MY ZONE' then
//        MyZone := MyZone;

      if CFGCA[i].crS = csRem then
      begin
        Result := True;
        Exit;
      end;

      if CFGCA[i].crKind = ckArray then
      begin
        Val(CustomCMD, TempInteger2, code);
        if code <> 0 then
        Exit;
        TempInteger := integer(CFGCA[i].crAddress);
        Result := SetParameterInArray
          (
          ArrayRecordArray[TempInteger].arArrayPtr,
          ArrayRecordArray[TempInteger].arArrayLength,
          ArrayRecordArray[TempInteger].arVar,
          TempInteger2
          );
        if not Result then
        Exit;
        goto AdditionalProc;
      end;

      if CFGCA[i].crKind = ckList then
      begin
        TempInteger := integer(CFGCA[i].crAddress);
        TempByte := GetValueFromArray(ListParamArray[TempInteger].lpArray, ListParamArray[TempInteger].lpLength, @CustomCMD);
        if TempByte <> UNKNOWNTYPE then
        begin
          ListParamArray[TempInteger].lpVar^ := TempByte;
          Result := True;
          goto AdditionalProc;
        end
        else Exit;

      end;

      if CFGCA[i].crAddress <> nil then
      begin
        case CFGCA[i].crType of

          ctMessage:
            begin
              SniffOutControlCharacters(CustomCMD);
              PShortString(CFGCA[i].crAddress)^ := CustomCMD;
              PShortString(CFGCA[i].crAddress)^[length(CustomCMD) + 1] := #0;
            end;

          ctDirectory, ctFileName:
            begin
              Windows.CopyMemory(CFGCA[i].crAddress, @CustomCMD[1], length(CustomCMD));
              FileNameType(CFGCA[i].crAddress^)[length(CustomCMD)] := #0;
            end;

          ctString, ctURL:
            begin
              PShortString(CFGCA[i].crAddress)^ := CustomCMD;
              ;
              PShortString(CFGCA[i].crAddress)^[length(CustomCMD) + 1] := #0;
              if CFGCA[i].crType = ctURL then Windows.CharLower(PChar(CFGCA[i].crAddress) + 1);
            end;

          ctPortLPT:
            PPortType(CFGCA[i].crAddress)^ :=
              GetLPTPortFromChar(CustomCMD);

          ctChar:
            PChar(CFGCA[i].crAddress)^ := CustomCMD[1];

          ctAlphaChar:
            begin
              if CustomCMD[1] in ['A'..'Z'] then PChar(CFGCA[i].crAddress)^ := CustomCMD[1] else Exit;
            end;

          ctBoolean:
            begin
              if not (CustomCMD[1] in ['T', 'F']) then Exit;
              ;
              PBoolean(CFGCA[i].crAddress)^ := CustomCMD[1] = 'T';
            end;

          ctReal:
            begin
              Val(CustomCMD, TempReal, code);
//             TempReal := ValExt(@CustomCMD[1], code);
              if code <> 0 then Exit;
              if (TempReal < CFGCA[i].crMin / 10) or (TempReal > CFGCA[i].crMax / 10) then Exit;
              PDouble(CFGCA[i].crAddress)^ := TempReal;
            end;

          ctByte, ctWord, ctInteger:
            begin
              Val(CustomCMD, TempInteger, code);
//              TempInteger := round(ValExt(@CustomCMD[1], code));
              if code <> 0 then Exit;

              if (TempInteger >= CFGCA[i].crMin) and ((TempInteger <= CFGCA[i].crMax) or (CFGCA[i].crMax = MAXWORD - 1 {MAXLONG})) then
              begin

                if CFGCA[i].crType = ctWord then
                  PWORD(CFGCA[i].crAddress)^ := TempInteger;

                if CFGCA[i].crType = ctInteger then
                  PInteger(CFGCA[i].crAddress)^ := TempInteger;

                if CFGCA[i].crType = ctByte then
                  PByte(CFGCA[i].crAddress)^ := TempInteger;

              end
              else
                Exit;
            end;
        end;
      end;

      AdditionalProc:
      if CFGCA[i].crA <> 0 then
      begin
        CMD := CustomCMD;
        Proc := AdditionalProcsArray[CFGCA[i].crA];
        asm
            call Proc
            mov byte ptr result,al
        end;
        if Result = False then
        exit;
      end;

      Result := True;
      Break;
    end;

end;

function F_ADD_DOMESTIC_COUNTRY: boolean;
begin
  if CMD = 'CLEAR' then ClearDomesticCountryList else AddDomesticCountry(CMD);
  Result := True;
end;

function F_AUTO_QSL_INTERVAL: boolean;
begin
  AutoQSLCount := AutoQSLInterval;
  Result := True;
end;

function F_AUTO_SEND_CHARACTER_COUNT: boolean;
begin
//  AutoQSLCount := AutoQSLInterval;
  AutoSendEnable := AutoSendCharacterCount > 0;
  Result := True;
end;

function F_BAND_MAP_CUTOFF_FREQUENCY: boolean;
var
  TempLongInt                           : integer;
begin
  Val(CMD, TempLongInt, Result1);
  Result := Result1 = 0;
  if Result then AddBandMapModeCutoffFrequency(TempLongInt);
end;

function F_BAND_MAP_DECAY_TIME: boolean;
begin
//  BandMapDecayMultiplier := (BandMapDecayValue div 64) + 1;
//  BandMapDecayTime := BandMapDecayValue div BandMapDecayMultiplier;
  Result := True;
end;

function F_CLEAR_DUPE_SHEET: boolean;
begin
//  if ClearDupeSheetCommandGiven then
  ClearDupeSheetCommandGiven := RunningConfigFile;
  Result := True;
end;

function F_CONTEST: boolean;
begin
  Result := FoundContest(CMD);
  F_DX_MULTIPLIER;
end;

function F_CONTEST_NAME: boolean;
begin
  SetContestTitle;
  Result := True;
end;

function F_FREQUENCY_MEMORY: boolean;
begin
  if StringHas(CMD, 'SSB') then
  begin
    Delete(CMD, pos('SSB ', CMD), 4);
    Val(CMD, TempFreq, Result1);
    if Result1 = 0 then
    begin
      CalculateBandMode(TempFreq, TempBand, TempMode);
      DefaultFreqMemory[TempBand, Phone] := TempFreq;
    end;
  end
  else
  begin
    Val(CMD, TempFreq, Result1);
    if Result1 = 0 then
    begin
      CalculateBandMode(TempFreq, TempBand, TempMode);
      DefaultFreqMemory[TempBand, CW] := TempFreq;
    end;
  end;
  Result := Result1 = 0;
end;
{
function F_ICOM_RESPONSE_TIMEOUT: boolean;
begin
  Val(CMD, cmdIcomResponseTimeout, Result1);
  RESULT := Result1 = 0;
  if Result1 = 0 then cmdIcomResponseTimeout := cmdIcomResponseTimeout div 10 else Exit;
  if not (cmdIcomResponseTimeout in [10..100]) then cmdIcomResponseTimeout := 10;
end;
}

function F_KEYER_RADIO_ONE_OUTPUT_PORT: boolean;
begin
  Radio1SerialInvert := StringHas(CMD, 'INVERT');
  Result := True;
end;

function F_KEYER_RADIO_TWO_OUTPUT_PORT: boolean;
begin
  Radio2SerialInvert := StringHas(CMD, 'INVERT');
  Result := True;
end;

function F_ORION_PORT: boolean;
begin
  ActiveRotatorType := OrionRotator;
  Result := True;
end;

function F_MY_CONTINENT: boolean;
begin
  MyContinentIsSet := True;
  Result := True;
end;

function F_MY_ZONE: boolean;
begin
  MyZoneIsSet := True;
  Result := True;
end;

function F_MY_COUNTRY: boolean;
var
  TempQTH                               : QTHRecord;
begin
  Result := False;
  ctyLocateCall(CMD, TempQTH);
  if MyCountry <> TempQTH.CountryID then Exit;

  MyCountryIsSet := True;
  RecalculateMyCountryContinentAndZoneNew(CMD);
  CountryString := MyCountry;
{
  ctyLocateCall(CMD, TempQTH);
  MyCountry := TempQTH.CountryID;
  MyContinent := TempQTH.Continent;
  Str(TempQTH.Zone, MyZone);
  CountryString := MyCountry;
  ContinentString := tContinentArray[MyContinent];
}
  Result := True;
end;

function F_MY_CALL: boolean;
var
  TempQTH                               : QTHRecord;
begin
  DEPlusMyCall := 'DE ' + MyCall;
  RecalculateMyCountryContinentAndZoneNew(MyCall);
{
  ctyLocateCall(MyCall, TempQTH);
  MyCountry := TempQTH.CountryID;
  MyContinent := TempQTH.Continent;
  Str(TempQTH.Zone, MyZone);
  CountryString := MyCountry;
  ContinentString := tContinentArray[MyContinent];
}
  Result := True;
end;

function F_ZONE_MULTIPLIER: boolean;
begin
  if ActiveZoneMult = CQZones then
  begin
    ActiveInitialExchange := ZoneInitialExchange;
    CTY.ctyZoneMode := CQZoneMode;
  end;

  if ActiveZoneMult = ITUZones then
  begin
    ActiveInitialExchange := ZoneInitialExchange;
    CTY.ctyZoneMode := ITUZoneMode;
  end;
  Result := True;
end;

function F_RADIO_ONE_TYPE: boolean;
begin
  Radio1.ReceiverAddress := RadioParametersArray[Radio1.RadioModel].RA;
  Result := True;
end;

function F_RADIO_TWO_TYPE: boolean;
begin
  Radio2.ReceiverAddress := RadioParametersArray[Radio2.RadioModel].RA;
  Result := True;
end;

function F_SCP_COUNTRY_STRING: boolean;
begin
  if CD.CountryString <> '' then
    if Copy(CD.CountryString, length(CD.CountryString), 1) <> ',' then
      CD.CountryString := CD.CountryString + ',';
  Result := True;
end;

function F_DX_MULTIPLIER: boolean;
begin
  if not (ActiveDXMult in
    [
    ARRLDXCCWithNoUSAOrCanada,
      ARRLDXCCWithNoARRLSections,
      ARRLDXCCWithNoUSACanadaKH6OrKL7,
      ARRLDXCCWithNoIOrIS0,
      ARRLDXCCWithNoJT,
      ARRLDXCC]) then
    CTY.ctyCountryMode := CQCountryMode
  else
    CTY.ctyCountryMode := ARRLCountryMode;
  Result := True;
end;

function F_START_SENDING_NOW_KEY: boolean;
begin
//??????
//  if CMD = 'SPACE' then StartSendingNowKey := ' ';
  Result := True;
end;
{
function F_SETPARALLELPORT: boolean;
begin
  asm
nop
  end;
end;
}

procedure ProcessReminder(ID, CMD: ShortString);
var
  TimeString                            : string;
  DateString, DayString                 : Str20;

begin

  if NumberReminderRecords >= MaximumReminderRecords then
  begin
    ShowMessage(TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED);
    Exit;
  end;

  if NumberReminderRecords = 0 then New(Reminders);

  Reminders^[NumberReminderRecords].DateString := '';
  Reminders^[NumberReminderRecords].DayString := '';
  Reminders^[NumberReminderRecords].Alarm := False;

  TimeString := Copy(CMD, 1, 4);

  if not StringIsAllNumbers(TimeString) then
  begin
    asm
          push TimeString
    end;
    wsprintf(wsprintfBuffer, '%s '#13 + TC_INVALIDREMINDERTIME);
    asm add esp,12
    end;
    ShowMessage(wsprintfBuffer);
          //      showmessage(TimeString + #13 + 'Invalid reminder time!!');
    Exit;
  end;

  Val(TimeString, Reminders^[NumberReminderRecords].Time, Result1);

  DateString := BracketedString(CMD, ' ON ', '');

  if StringHas(DateString, 'ALARM') then
  begin
    Reminders^[NumberReminderRecords].Alarm := True;
    DateString := BracketedString(DateString, '', ' ALARM');
  end;

      //WLI
  GetRidOfPostcedingSpaces(DateString);

  if StringHas(DateString, '-') then
  begin
    case length(DateString) of
      8:
        if (DateString[2] <> '-') or (DateString[6] <> '-') then
        begin
          ShowMessage(TC_INVALIDREMINDERDATE);
          Exit;
        end
        else
          DateString := '0' + DateString;

      9:
        if (DateString[3] <> '-') or (DateString[7] <> '-') then
        begin
          ShowMessage(TC_INVALIDREMINDERDATE);
          Exit;
        end;

    else
      ShowMessage(TC_INVALIDREMINDERDATE);
    end;
    Reminders^[NumberReminderRecords].DateString := DateString;
  end
  else
  begin
    DayString := Copy(DateString, length(DateString) - 2, 3);
    if (DayString <> 'DAY') and (DayString <> 'ALL') then
    begin
      ShowMessage(TC_INVALIDREMINDERDATE);
      Exit;
    end;

    Reminders^[NumberReminderRecords].DayString := DateString;
  end;

  ReadLn(ConfigFileRead, Reminders^[NumberReminderRecords].RemMessage);
  inc(NumberReminderRecords);
 
end;

function ProcessMessage(ID, CMD: ShortString): boolean;
var
  CQMessage                             : boolean;
  TempValue                             : integer;
  TempMode                              : ModeType;
  Offset                                : Cardinal;
  FuncKey                               : Cardinal;
begin
{
CQ DIG MEMORY F1=CQ CQ CQ \ \ TEST
CQ DIG MEMORY ALTF1=CQ CQ CQ \ \ TEST
CQ CW MEMORY CONTROLF1=CQ CQ CQ \ \ TEST
CQ MEMORY F1 =\\ TEST
CQ DIG MEMORY F1 CAPTION=
CQ CW MEMORY CONTROLF5=<03>SRS=PB1;<04>
CQ CW MEMORY CONTROLF5 CAPTION=PLAYCH1MSG
}

//  if ID[1] = 'C' then CQMessage := True else CQMessage := False;
  Result := False;
  CQMessage := ID[1] = 'C';
  TempMode := NoMode;

  Offset := 8; //Pos of  "MEMORY"

  case ID[4] of
    'S': TempMode := Phone;
    'D': TempMode := Digital;
    'C':
      begin
        TempMode := CW;
        Offset := 7;
      end;

    'M':
      begin
        TempMode := CW;
        Offset := 4;
      end;
  end;

  if TempMode = NoMode then Exit;

  TempValue := 0;
  case ID[Offset + 7] of
    'F':
      begin
        TempValue := 111;
        inc(Offset, 8);
      end;
    'A':
      begin
        TempValue := 135;
        inc(Offset, 8 + 3);
      end;
    'C':
      begin
        TempValue := 123;
        inc(Offset, 8 + 7);
      end;
  end;
  FuncKey := Ord(ID[Offset]) - Ord('0');
  if length(ID) > Offset then
    if ID[Offset + 1] in ['0'..'2'] then
      FuncKey := Ord(ID[Offset + 1]) - Ord('0') + 10;

  if not (FuncKey in [1..12]) then Exit;

  Result := True;

  if ID[length(ID)] = 'N' then
  begin
    if CQMessage then
      SetCQCaptionMemoryString(TempMode, CHR(TempValue + FuncKey), CMD)
    else
      SetEXCaptionMemoryString(TempMode, CHR(TempValue + FuncKey), CMD);
  end
  else
  begin
    if CQMessage then
      SetCQMemoryString(TempMode, CHR(TempValue + FuncKey), CMD)
    else
      SetEXMemoryString(TempMode, CHR(TempValue + FuncKey), CMD);
  end;

//  Exit;
{
  if TempValue = 0 then Exit;

  TempModeType := CW;
  if StringHas(ID, 'MEMORY F') or StringHas(ID, 'CW MEMORY F') then TempValue := 111;
  if StringHas(ID, 'MEMORY ALTF') or StringHas(ID, 'CW MEMORY ALTF') then TempValue := 135;
  if StringHas(ID, 'MEMORY CONTROLF') or StringHas(ID, 'CW MEMORY CONTROLF') then TempValue := 123;

  if StringHas(ID, 'SSB MEMORY F') then
  begin
    TempValue := 111;
    TempModeType := Phone;
  end;

  if StringHas(ID, 'SSB MEMORY ALTF') then
  begin
    TempValue := 135;
    TempModeType := Phone;
  end;

  if StringHas(ID, 'SSB MEMORY CONTROLF') then
  begin
    TempValue := 123;
    TempModeType := Phone;
  end;

  if StringHas(ID, 'DIG MEMORY F') then
  begin
    TempValue := 111;
    TempModeType := Digital;
  end;

  if StringHas(ID, 'DIG MEMORY ALTF') then
  begin
    TempValue := 135;
    TempModeType := Digital;
  end;

  if StringHas(ID, 'DIG MEMORY CONTROLF') then
  begin
    TempValue := 123;
    TempModeType := Digital;
  end;

  if TempValue > 0 then
  begin
    Result := True;
    if TempValue = 111 then ID := PostcedingString(ID, 'MEMORY F');
    if TempValue = 123 then ID := PostcedingString(ID, 'CONTROLF');
    if TempValue = 135 then ID := PostcedingString(ID, 'ALTF');

    if StringIsAllNumbers(ID) then
    begin
      TempLongInt := StrToInt(ID);
      if (TempLongInt > 0) and (TempLongInt < 13) then
      begin
        if CQMessage then
          SetCQMemoryString(TempModeType, CHR(TempValue + TempLongInt), CMD)
        else
          SetEXMemoryString(TempModeType, CHR(TempValue + TempLongInt), CMD);
        Exit;
      end;
    end
    else
      if StringHas(ID, ' CAPTION') then
      begin

        TempLongInt := StrToInt(Copy(ID, 1, pos(' CAPTION', ID)));
        if (TempLongInt > 0) and (TempLongInt < 13) then
        begin
          if CQMessage then
            SetCQCaptionMemoryString(TempModeType, CHR(TempValue + TempLongInt), CMD)
          else
            SetEXCaptionMemoryString(TempModeType, CHR(TempValue + TempLongInt), CMD);
          Exit;
        end;
      end;

  end;
}
end;

procedure ProcessTotalScoreMessage(ID, CMD: ShortString);
begin
{
  if NumberTotalScoreMessages < 10 then
  begin
    Val(CMD, TotalScoreMessages[NumberTotalScoreMessages].Score, Result1);
    ReadLn(ConfigFileRead, TotalScoreMessages[NumberTotalScoreMessages].MessageString);
    inc(NumberTotalScoreMessages);
  end
  else
    ShowMessage(TC_TOOMANYTOTALSCOREMESSAGES);
}
end;

procedure InitializeStrings;

type
  IniStringRecord = record
    isString: PShortString;
    isPcharString: PChar;
  end;
const
  SAS                                   = 16;
  SA                                    : array[1..SAS] of IniStringRecord =
    (
    (isString: @CQPhoneExchange; isPcharString: 'CQEXCHNG.WAV'),
    (isString: @CQPhoneExchangeNameKnown; isPcharString: 'CQEXNAME.WAV'),
    (isString: @CorrectedCallMessage; isPcharString: '} OK %'),
    (isString: @QSOBeforePhoneMessage; isPcharString: 'QSOB4.WAV'),
    (isString: @QuickQSLPhoneMessage; isPcharString: 'QUICKQSL.WAV'),
    (isString: @QSLPhoneMessage; isPcharString: 'QSL.WAV'),
    (isString: @RepeatSearchAndPouncePhoneExchange; isPcharString: 'RPTSPEX.WAV'),
    (isString: @SearchAndPouncePhoneExchange; isPcharString: 'SAPEXCHG.WAV'),
 //   (isString: @TailEndPhoneMessage; isPcharString: 'TAILEND.WAV'),
{
    (isString: @GetScoresSeverPostingAddress; isPcharString: 'http://www.getscores.org/postscore.aspx'),
    (isString: @GetScoresSeverReadingAddress; isPcharString: 'http://www.getscores.org/'),
}
    (isString: @GetScoresSeverPostingAddress; isPcharString: 'http://cqcontest.ru/postscore.jsp'),
    (isString: @GetScoresSeverReadingAddress; isPcharString: 'http://cqcontest.ru'),

    (isString: @UnknownCountryFileName; isPcharString: 'UNKNOWN.CTY'),

    (isString: @QSLMessage; isPcharString: 'TU \ TEST'),
    (isString: @QSOBeforeMessage; isPcharString: ' SRI QSO B4 TU \ TEST'),

    (isString: @QuickQSLMessage1; isPcharString: 'TU'),
    (isString: @QuickQSLMessage2; isPcharString: 'EE'),
  //  (isString: @TailEndMessage; isPcharString: 'R'),

    (isString: @CorrectedCallPhoneMessage; isPcharString: 'CORCALL.WAV')
    );
var
  i                                     : integer;
begin
  for i := 1 to SAS do
  begin
    Windows.lstrcat(PChar(integer(SA[i].isString) + 1), SA[i].isPcharString);
    SA[i].isString^[0] := Char(lstrlen(SA[i].isPcharString));
  end;

  Windows.lstrcat(TR4W_FLOPPY_FILENAME, 'C:\LOGBACK.TRW');
  Windows.lstrcat(TR4W_INITIALEX_FILENAME, 'INITIAL.EX');
  Windows.lstrcat(TR4W_MP3PATH, 'MP3');
  Windows.lstrcat(TR4W_DVKPATH, 'DVK');

end;

end.

