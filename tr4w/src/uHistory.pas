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
unit uHistory;

interface

uses
VC,
  TF,
//  Tree,
  Windows;
const
  MAXFEATURES                           = 30;
  BASE                             = 'c:\workspace\';
//  BASE                                  = 'd:\Documents and Settings\1.NEWXP\workspace\';

procedure MakeRevisionHistory();
procedure MakeLatestReleasesNotes();

type

  FeatureType = (ftUndef, ftAdded, ftFixed, ftRemov, ftRevision);

  HistoryRecord = record
    hrFeature: FeatureType;
    hrDescription: PChar;
  end;

  VersionRecord = record
    hrVersion: PChar;
    hrYear: Word;
    hrMonth: Byte;
    hrDay: Byte;
    hrV: array[0..MAXFEATURES - 1] of HistoryRecord;
  end;

const

  FID                                   : array[FeatureType] of PChar = (' ', '+', 'F', '-', 'R');

  hr1                                   : HistoryRecord = (hrFeature: ftAdded);

  TOATALVERSION                         = 41;
  TOATALVERSION2                        = TOATALVERSION;

  V                                     : array[0..TOATALVERSION - 1] of VersionRecord = (

    (
    hrVersion: '4.247';
    hrYear: 2012;
    hrMonth: 12;
    hrDay: 8;
    hrV: (


    (hrFeature: ftRevision; hrDescription: 'Corrected ARRLSECT.DOM file'),
    (hrFeature: ftRevision; hrDescription: 'New rules of RADIO-160 contest'),
    (hrFeature: ftAdded; hrDescription: 'Support of YAESU FTDX3000 transceiver'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )
    ,

    (
    hrVersion: '4.246';
    hrYear: 2012;
    hrMonth: 7;
    hrDay: 21;
    hrV: (


    (hrFeature: ftRevision; hrDescription: '<a href="https://groups.google.com/forum/#!topic/tr4w/t36ByUK5K8c/discussion">New ARRL Section for Canada in Sweepstakes and other ARRL contests</a>'),
    (hrFeature: ftFixed; hrDescription: '<a href="https://groups.google.com/d/topic/tr4w/2pz64oxWtmw/discussion">Problem with NAQP Cabrillo file</a>'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )
    ,

    (
    hrVersion: '4.245';
    hrYear: 2012;
    hrMonth: 5;
    hrDay: 9;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'M (Multiplier) column in log show actual mults for QSO: x(DXCC), d(Domestic), z(Zone), p(Prefix)'),
    (hrFeature: ftRevision; hrDescription: 'MMAA contest renamed to <a href="http://www.cqmmdx.com">CQMM</a>. Corrected score calculation'),
    (hrFeature: ftAdded; hrDescription: 'If <code>LATEST CONFIG FILE</code> is empty or file is not exist - button "Latest config file..." in "Open configuration file..." is not visible'),
    (hrFeature: ftRevision; hrDescription: 'Updated ARI.DOM file'),
    (hrFeature: ftAdded; hrDescription: 'Support of ICOM IC7410 transceiver'),
    (hrFeature: ftAdded; hrDescription: 'After program startup: if value of <code>MY GRID</code> is empty then the program will ask to enter your grid locator'),
    (hrFeature: ftAdded; hrDescription: 'Prefill of exchange number in RDAC contest'),
    (hrFeature: ftRevision; hrDescription: '"DVP" function renamed to "DVK" (Digital Voice Keyer). ' +
    'Command <code>DVK ENABLE</code> renamed to <code>DVK ENABLE</code>. ' +
    'Command <code>DVK PATH</code> renamed to <code>DVK PATH</code>. ' +
    'Command <code>DVK RECORDER</code> renamed to <code>DVK RECORDER</code>'
    ),

    (hrFeature: ftAdded; hrDescription: 'Added new command <code>DVK LOCALIZED MESSAGES ENABLE</code>. ' +
    'If TRUE - when program will play *.WAV file with message it will try at first search file in directory DVK_PATH\COUNTRY_ID, where DVK_PATH - value of <code>DVK PATH</code>, COUNTRY_ID - country identifier of callsign in main window'),

    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )
    ,

    (
    hrVersion: '4.244';
    hrYear: 2012;
    hrMonth: 2;
    hrDay: 25;
    hrV: (


    (hrFeature: ftRevision; hrDescription: 'Corrected PMC.DOM file'),
    (hrFeature: ftFixed; hrDescription: 'Corrected UI of "New contest" window'),
    (hrFeature: ftAdded; hrDescription: 'Processing of <code>RX_PWR</code> ADIF tag'),
    (hrFeature: ftAdded; hrDescription: 'Import of frequency in kHz from ADIF file'),
    (hrFeature: ftFixed; hrDescription: 'Value of <code>EXCHANGE RECEIVED</code> for DARC-10M contest changed to <code>RST QSO NUMBER AND POSSIBLE DOMESTIC QTH</code>'),
    (hrFeature: ftAdded; hrDescription: 'Support of <a href="http://www.irts.ie/cgi/showrules.cgi?cqir/">CQIR</a> contest'),
    (hrFeature: ftAdded; hrDescription: 'Support of <a href="http://qrznow.com/?p=205">WWIH (WORLD WIDE IRON HAM)</a> contest'),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )
    ,

    (
    hrVersion: '4.243';
    hrYear: 2012;
    hrMonth: 1;
    hrDay: 4;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Added <code>HI</code> identifier in HAWAII.DOM file'),
    (hrFeature: ftFixed; hrDescription: 'Added <code>EWA</code> identifier in ARRLSECT.DOM file'),
    (hrFeature: ftFixed; hrDescription: 'Truncating frequency in bandmap'),
    (hrFeature: ftAdded; hrDescription: 'Check of filling of LOCATION field in ARRL-10 contest'),
    (hrFeature: ftFixed; hrDescription: 'Exchange parsing in ARRL-FD contest'),
    (hrFeature: ftRevision; hrDescription: 'Command <code>BANDMAP ITEM HEIGHT</code> renamed to <code>BAND MAP ITEM HEIGHT</code>'),
    (hrFeature: ftRevision; hrDescription: 'Command <code>BANDMAP ITEM WIDTH</code> renamed to <code>BAND MAP ITEM WIDTH</code>'),
    (hrFeature: ftRevision; hrDescription: 'Window "SP COUNTER" renamed to "S&amp;P COUNTER""'),
    (hrFeature: ftRevision; hrDescription: 'Default value of <code>POSSIBLE CALL MODE</code> changed to <code>ALL</code>'),
    (hrFeature: ftAdded; hrDescription: 'Support of ARRL-RTTY contest'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )
    ,

    (
    hrVersion: '4.241';
    hrYear: 2011;
    hrMonth: 12;
    hrDay: 7;
    hrV: (
    (hrFeature: ftFixed; hrDescription: '<code>EXCHANGERADIOS</code> function key command'),
    (hrFeature: ftFixed; hrDescription: '<code>MP3 PLAYER</code> command'),
    (hrFeature: ftRevision; hrDescription: '"0" value in total window don`t displayed'),
    (hrFeature: ftAdded; hrDescription: 'New command <code>MAIN CALLSIGN</code>'),
    (hrFeature: ftAdded; hrDescription: 'Import from ADIF: handling of PRECEDENCE, CHECK, ARRL_SECT tags'),
    (hrFeature: ftRevision; hrDescription: 'Values of <code>SCORE POSTING URL</code> and <code>SCORE READING URL</code> commands changed to <a href="http://cqcontest.ru">http://cqcontest.ru</a>'),
    (hrFeature: ftFixed; hrDescription: 'QSOB4.WAV message in phone mode'),
    (hrFeature: ftFixed; hrDescription: '<code>INITIAL EXCHANGE CURSOR POS = AT END</code>. If <code>INITIAL EXCHANGE OVERWRITE = TRUE</code> then cursor always will be placed at the end of exchange window'),
    (hrFeature: ftRevision; hrDescription: 'Changed windows names: "TEN MINUTS" > "TEN MINUTES", "LOCATOR" > "GRID LOCATOR"'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )
    ,

    (
    hrVersion: '4.239';
    hrYear: 2011;
    hrMonth: 10;
    hrDay: 9;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'Initial exchange in OZCHR-TEAMS contest'),
    (hrFeature: ftFixed; hrDescription: '<code>LEAVE CURSOR IN CALL WINDOW</code>'),
    (hrFeature: ftRevision; hrDescription: 'Support of <a rel="nofollow" href="http://www.rsgbcc.org/hf/rules/2011/rropoco.shtml">RSGB-ROPOCO-CW and RSGB-ROPOCO-SSB</a> contests (revision)'),
    (hrFeature: ftFixed; hrDescription: 'Drop-down commands list in "DX-cluster window"'),
    (hrFeature: ftFixed; hrDescription: '"Tools" -> "Synchronize PC time" -> "Synchronize clock" : display error if program does not running with Administrator Privileges"'),
    (hrFeature: ftFixed; hrDescription: 'Country determination for RI1FJ and RI1MV callsigns'),
    (hrFeature: ftFixed; hrDescription: 'Score calculation in DARC-WAEDC'),
    (hrFeature: ftFixed; hrDescription: 'Drop-down list with addresses in "DX-Cluster" window'),
    (hrFeature: ftAdded; hrDescription: 'New menu item in bandmap popup-menu - "BAND MAP MULTS ONLY"'),

    (hrFeature: ftFixed; hrDescription: 'Multipliers calculation in CQ-M and OZCHR-TEAMS contests. Corrected r150s.dat file'),
    (hrFeature: ftRevision; hrDescription: 'Renamed ARI contest to ARI-DX. Added MB multiplier to ari.dom'),
    (hrFeature: ftRevision; hrDescription: '<a href="http://www.arrl.org/files/file/Field-Day/2011/2011_Rules.pdf">ARRL-FD</a> contest: corrected score calculation, score calculated without power multipliers; added export to cabrillo'),

    (hrFeature: ftRevision; hrDescription: 'Support of MAKROTHEN-RTTY contest'),

    (hrFeature: ftAdded; hrDescription: 'QSO NUMBER BY BAND command'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()

    )
    )
    ,

    (
    hrVersion: '4.236';
    hrYear: 2011;
    hrMonth: 7;
    hrDay: 4;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'Added support of <a href="http://www.cwops.org/cwopen.html">CWOPEN</a> contest'),
    (hrFeature: ftRevision; hrDescription: 'Corrected <code>ARRLSECT.DOM</code> file'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()

    )
    )
    ,
    (
    hrVersion: '4.234';
    hrYear: 2011;
    hrMonth: 3;
    hrDay: 8;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'New command <code>QZB RANDOM OFFSET ENABLE</code> ( default value = <code>FALSE</code>)'),
    (hrFeature: ftFixed; hrDescription: '"<code>Send spot</code>" - sending spots only for "my log"'),
    (hrFeature: ftAdded; hrDescription: 'Support of NAQP-RTTY contest (MMTTY version)'),
    (hrFeature: ftFixed; hrDescription: 'No program interruption if <code>RELAY CONTROL PORT = PADDLE PORT</code>'),
    (hrFeature: ftFixed; hrDescription: 'Fixes for NAQP-RTTY'),
    (hrFeature: ftAdded; hrDescription: 'New command <code>&lt;03&gt;MM_CLEAR_THE_TX_BUFFER&lt;04&gt;</code>'),
    (hrFeature: ftAdded; hrDescription: 'New command <code>&lt;03&gt;MM_SWITCH_TO_TX&lt;04&gt;</code>'),
    (hrFeature: ftAdded; hrDescription: 'New command <code>&lt;03&gt;MM_SWITCH_TO_RX_IMMEDIATELY&lt;04&gt;</code>'),
    (hrFeature: ftAdded; hrDescription: 'New command <code>&lt;03&gt;MM_SWITCH_TO_RX_<br/>AFTER_THE_TRANSMISSION_IS_COMPLETED&lt;04&gt;</code>'),
    (hrFeature: ftFixed; hrDescription: '<code>Alt+P->O</code> in phone mode'),
    (hrFeature: ftFixed; hrDescription: 'Identification of russian oblast by callsign'),
    (hrFeature: ftAdded; hrDescription: 'Support of NA-SPRINT-RTTY (MMTTY version)'),
    (hrFeature: ftAdded; hrDescription: 'Auto CQ in RTTY mode'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.233';
    hrYear: 2011;
    hrMonth: 2;
    hrDay: 3;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Fixes'),
    (hrFeature: ftAdded; hrDescription: 'Support of CQ-WPX-RTTY'),
    (hrFeature: ftAdded; hrDescription: 'Support of NAQP-RTTY contest (MMTTY version)'),
    (hrFeature: ftFixed; hrDescription: 'Corrected S48.DOM file'),
    (hrFeature: ftFixed; hrDescription: 'New multipliers determination in NAQP'),
    (hrFeature: ftAdded; hrDescription: 'Updated PMC.DOM file'),
    (hrFeature: ftAdded; hrDescription: 'Removed "VER" as an alias for Vermont in S48.DOM file'),
    (hrFeature: ftAdded; hrDescription: 'Identification of Guantanamo Bay (KG4) callsigns'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.231';
    hrYear: 2010;
    hrMonth: 12;
    hrDay: 4;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Default value of <code>CALLSIGN UPDATE ENABLE</code> for ARRL-SS-CW and ARRL-SS-SSB is set to TRUE'),
    (hrFeature: ftAdded; hrDescription: 'Enter a 2 or 3 digit number in the Call Window followed by a CTRL-P would cause the rotator to point in the direction in degrees indicated by the numbers'),
    (hrFeature: ftAdded; hrDescription: 'New multipliers file - ARRL10.DOM'),
    (hrFeature: ftFixed; hrDescription: 'Export to ADIF format for WAG and ARRL-SS contests'),
    (hrFeature: ftFixed; hrDescription: 'Support of "EXCHANGERADIOS" special command (&lt;03&gt;EXCHANGERADIOS&lt;04&gt;)'),
    (hrFeature: ftAdded; hrDescription: 'QSK keying if <code>KEYER OUTPUT PORT = PARALLEL</code> and <code>PTT ENABLE = FALSE</code>'),
    (hrFeature: ftAdded; hrDescription: 'Forming exchange string for contests with <code>EXCHANGE RECEIVED=RST ZONE</code>'),
    (hrFeature: ftAdded; hrDescription: 'Country definition of R*2 callsigns'),
    (hrFeature: ftAdded; hrDescription: 'DX Clutser: support of OL5Q skimmer (217.75.211.40:7300) spots format'),
    (hrFeature: ftAdded; hrDescription: 'Contests with <code>EXCHANGE RECEIVED = QSO NUMBER NAME DOMESTIC OR DX QTH</code> (US QSO parties): parsing of exchange strings like 222VE3'),
    (hrFeature: ftAdded; hrDescription: 'Export to ADIF in NAQP contest'),
    (hrFeature: ftAdded; hrDescription: 'Two radio dupe sheet windows'),
    (hrFeature: ftAdded; hrDescription: 'Improved manual input of frequency in callsign window'),
    (hrFeature: ftAdded; hrDescription: 'Changed polling logic for Kenwood`s rigs'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (),
    ()
    )
    )

    ,
    (
    hrVersion: '4.229';
    hrYear: 2010;
    hrMonth: 08;
    hrDay: 24;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'DARC-WAEDC - corrected multipliers calculation for EU stations'),
    (hrFeature: ftAdded; hrDescription: 'RDAC and YODX contests - determination of domestic multiplier by callsign. Determination based on previous Qs data and initial.ex'),
    (hrFeature: ftAdded; hrDescription: 'Determination of domestic multiplier on the basis of exchange number'),
    (hrFeature: ftFixed; hrDescription: '<code>START SENDING NOW KEY</code> function for callsigns with slash'),
    (hrFeature: ftFixed; hrDescription: 'Telnet/Bandmap window - reject of spots with frequency > 430 MHz'),
    (hrFeature: ftAdded; hrDescription: '"Possible calls" function with using of (tr)master.dta'),
    (hrFeature: ftAdded; hrDescription: 'Support of ICOM IC-7200 transceiver'),
    (hrFeature: ftAdded; hrDescription: 'TR-LOG style of dupesheet window. Command <code>COLUMN DUPESHEET ENABLE</code> not processed'),
    (hrFeature: ftAdded; hrDescription: 'Display of multipliers in "Remaining mults" window in European HF Championship'),
    (hrFeature: ftAdded; hrDescription: 'Processing of <code>MY ZONE</code> command'),
    (hrFeature: ftAdded; hrDescription: 'Common (for all contests) function keys messages may be stored in ../TR4W/COMMONMESSAGES.INI file'),
    (hrFeature: ftAdded; hrDescription: 'Logging of BP100 callsign'),
    (hrFeature: ftAdded; hrDescription: 'usage of <code>ADD DOMESTIC COUNTRY = CLEAR</code>'),
    (hrFeature: ftAdded; hrDescription: '<code>ICOM RESPONSE TIMEOUT</code> command not processed. Value of ICOM RESPONSE TIMEOUT determined by the program based on the value of RADIO ONE/TWO BAUD RATE'),
    (hrFeature: ftAdded; hrDescription: 'Support of OZHCR-VHF'),
    (hrFeature: ftAdded; hrDescription: 'Support of RAC CANADA DAY'),
    (hrFeature: ftAdded; hrDescription: '<code>MESSAGE ENABLE</code> command'),
    (hrFeature: ftAdded; hrDescription: 'EUROPEAN VHF contest: for 9A paricipants points calculate according with Croatien VHF contest rules'),
    (hrFeature: ftAdded; hrDescription: 'PTT signal in FM mode'),
    (hrFeature: ftAdded; hrDescription: 'Updated IARUHQ.DOM file'),
    (hrFeature: ftAdded; hrDescription: 'defination of grid for UA/UA9 stations'),
    (hrFeature: ftAdded; hrDescription: '"Initial exchange" function (initial.ex) enabled for WRTC contest'),
    (hrFeature: ftAdded; hrDescription: 'New special command - WK_RESET - resets the Winkeyer2 processor to the power up state. Example - CQ CW MEMORY CONTROLF4=&lt;03&gt;WK_RESET&lt;04&gt;'),
    (hrFeature: ftAdded; hrDescription: 'New special command - WK_SWAPTUNE - swap Winkeyer2 tune function'),
    (hrFeature: ftAdded; hrDescription: 'Default value of <code>CUSTOM CARET</code> changed to TRUE'),
    (hrFeature: ftAdded; hrDescription: 'Default value of <code>DISTANCE MODE</code> changed to KM'),
    (),
    (),
    (),
    ()

    )
    )

    ,
    (
    hrVersion: '4.221';
    hrYear: 2011;
    hrMonth: 5;
    hrDay: 24;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Garbage in Alt-D callsign'),
    (hrFeature: ftAdded; hrDescription: 'Determination of new mult if MULT BY BAND = FALSE'),
    (hrFeature: ftAdded; hrDescription: 'Default value of INITIAL EXCHANGE for CWOPS contest is set to NAME QTH'),
    (hrFeature: ftFixed; hrDescription: 'BAND MAP CALL WINDOW ENABLE = TRUE will not work if callsign in CALLSIGN WINDOW is typed by operator or if spot`s callsign = MY CALL'),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

//-----------------------------

    ,
    (
    hrVersion: '4.220';
    hrYear: 2010;
    hrMonth: 5;
    hrDay: 19;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Definition of country for /MM callsigns'),
    (hrFeature: ftFixed; hrDescription: 'Logging of Sicily callsigns in ARI contest'),
    (hrFeature: ftFixed; hrDescription: 'MMAA contest - callsign overwrite if <code>CALLSIGN UPDATE ENABLE=TRUE</code>'),
    (hrFeature: ftFixed; hrDescription: 'Overwrite of user function keys messages by defaults'),
    (hrFeature: ftFixed; hrDescription: 'Points/multipliers calculation, default exchange number in WRTC contest'),
    (hrFeature: ftFixed; hrDescription: 'Default value of <code>ICOM RESPONSE TIMEOUT</code> increased to 60 ms'),
    (hrFeature: ftRevision; hrDescription: 'Updated <code>QSO POINT METHOD</code>, MINNESOTA_CTY.DOM and MINNESOTA.DOM files for MINNESOTA QSO PARTY in accordance with new rules'),
    (hrFeature: ftRevision; hrDescription: 'Usage of old "Tools" -> "Synchronize PC time" dialog window'),
    (hrFeature: ftAdded; hrDescription: 'Support of <a href="http://www.cwops.org/onair.html">CWOPS contest</a>'),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.219';
    hrYear: 2010;
    hrMonth: 4;
    hrDay: 28;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Crash on MP3 RECORDER SAMPLERATE command'),
    (hrFeature: ftAdded; hrDescription: 'Support of skimmers spots'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.218';
    hrYear: 2010;
    hrMonth: 4;
    hrDay: 19;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Quality of the recorded MP3 files'),
    (hrFeature: ftFixed; hrDescription: 'Alt-K in phone mode'),
    (hrFeature: ftFixed; hrDescription: '<code>WK AUTOSPACE</code>, <code>WK CT SPACING</code>, <code>WK KEYER MODE</code>, <code>WK PADDLE SWAP</code>'),
    (hrFeature: ftFixed; hrDescription: 'Usage of <code>CQ SSB EXCHANGE</code> and <code>QUICK QSL SSB MESSAGE</code> comands'),
    (hrFeature: ftFixed; hrDescription: 'IC781 mode polling'),
    (hrFeature: ftFixed; hrDescription: 'Orion polling'),
    (hrFeature: ftFixed; hrDescription: 'FT857, FT897 frequency setting'),
    (hrFeature: ftRevision; hrDescription: 'GAGARIN CUP QSO points calculation'),
    (hrFeature: ftAdded; hrDescription: 'Support of "CI-V transcieve" mode'),
    (hrFeature: ftAdded; hrDescription: 'New special command - <03>SENDMESSAGE<04>. Equivalent of "Net" -> "Send message" menu item'),
    (hrFeature: ftRevision; hrDescription: 'If SERIAL NUMBER LOCKOUT=1 in tr4wserver.exe settings then locked numbers will be displayed with the "L" suffix in "QSO NUMBER" window'),
    (hrFeature: ftAdded; hrDescription: 'New command - RADIO ONE/TWO ICOM FILTER BYTE. Values: 0 - disable filter width control; 1,2,3 - Wide, Normal, Narrow filters. Applicable only for ICOM`s rigs'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.208';
    hrYear: 2010;
    hrMonth: 3;
    hrDay: 14;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Time synchronize'),
    (hrFeature: ftFixed; hrDescription: '"Stations" window'),
    (hrFeature: ftAdded; hrDescription: 'Support of IC78 rig'),
    (hrFeature: ftRevision; hrDescription: 'For ICOM`s users: If necessary program will ask to "Disable "CI-V Transceive" mode in your ICOM rig." (in most cases via rig menu). Refer to rig user manual for details'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.207';
    hrYear: 2010;
    hrMonth: 3;
    hrDay: 12;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'QSO edit'),
    (hrFeature: ftFixed; hrDescription: '<code>SHOW DOMESTIC MULTIPLIER NAME</code>'),
    (hrFeature: ftAdded; hrDescription: 'New menu item - "Help" -> "Send bug report"'),
    (hrFeature: ftAdded; hrDescription: 'New special commands: <03>CLEARDUPESHEET<04>, <03>CLEARMULTSHEET<04>, <03>BOOLSWAP=CTRL-J_BOOLEAN_COMMAND<04> where CTRL-J_BOOLEAN_COMMAND - Ctrl-J boolean type command (i.e. <03>BOOLSWAP=SHOW DOMESTIC MULTIPLIER NAME<04>)'),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.206';
    hrYear: 2010;
    hrMonth: 3;
    hrDay: 5;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Creating new CFG file'),
    (hrFeature: ftAdded; hrDescription: 'New menu item - Tools -> WA7BNM''s Contest Calendar'),
    (hrFeature: ftAdded; hrDescription: 'Auto CQ in phone mode'),
    (hrFeature: ftAdded; hrDescription: '<code>AUTO QSL INTERVAL</code> in phone mode'),
    (hrFeature: ftFixed; hrDescription: 'Installation error'),
    (hrFeature: ftFixed; hrDescription: 'Cleaning of exchange window'),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.200';
    hrYear: 2010;
    hrMonth: 2;
    hrDay: 27;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Two radio mode with Winkeyer'),
    (hrFeature: ftFixed; hrDescription: 'Split mode in FT1000MP'),
    (hrFeature: ftFixed; hrDescription: 'FREQUENCY MEMORY for 160m'),
    (hrFeature: ftFixed; hrDescription: 'IC735 polling'),
    (hrFeature: ftFixed; hrDescription: 'Orion polling'),
    (hrFeature: ftAdded; hrDescription: 'Editable color/background of exchange window'),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.198';
    hrYear: 2010;
    hrMonth: 2;
    hrDay: 14;
    hrV: (
    (hrFeature: ftFixed; hrDescription: '...'),
    (hrFeature: ftFixed; hrDescription: 'Rewritted routines of determining of countries and multipliers'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.197';
    hrYear: 2010;
    hrMonth: 2;
    hrDay: 10;
    hrV: (
    (hrFeature: ftFixed; hrDescription: '...'),
    (hrFeature: ftAdded; hrDescription: 'Editable <code>BAND MAP CUTOFF FREQUENCY</code> and <code>FREQUENCY MEMORY</code> commands'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.196';
    hrYear: 2010;
    hrMonth: 2;
    hrDay: 7;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'Use of own driver tr4wio.sys for access to parallel ports. DLPORTIO driver is no longer used'),
    (hrFeature: ftFixed; hrDescription: 'Missed STROBE signal (pin 1) at keying with parralel port'),
    (hrFeature: ftAdded; hrDescription: 'For observation of status of parallel port you may use tr4wlptmonitor.exe v.1.02 which is included in this release'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.195';
    hrYear: 2010;
    hrMonth: 2;
    hrDay: 2;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'Code optimization'),
    (hrFeature: ftAdded; hrDescription: 'New menus: ''Settings'' -> ''Colors'', ''Appearance'''),
    (hrFeature: ftAdded; hrDescription: 'Usage of WK PTT line in phone mode'),
    (hrFeature: ftAdded; hrDescription: 'Support of K3 rig'),
    (hrFeature: ftRemov; hrDescription: 'Command SERIAL PORT DEBUG is no longer supported. Use instead <a href="http://technet.microsoft.com/sysinternals/bb896644.aspx">Portmon</a> program.'),
    (hrFeature: ftAdded; hrDescription: 'Winkeyer settings stored as configuration commands in tr4w.ini file'),
    (hrFeature: ftRemov; hrDescription: '<code>INPUT CONFIG FILE</code> command is no longer processed'),
    (hrFeature: ftFixed; hrDescription: 'Import from ADIF file with tags in mixed case'),
    (hrFeature: ftAdded; hrDescription: 'Menu bar in file preview window'),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.192';
    hrYear: 2010;
    hrMonth: 1;
    hrDay: 13;
    hrV: (
    (hrFeature: ftFixed; hrDescription: '<code>NO POLL DURING PTT</code> usage'),
    (hrFeature: ftRemov; hrDescription: 'Removed JST245 rig'),
    (hrFeature: ftAdded; hrDescription: 'New compressing method of executable file'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.191';
    hrYear: 2010;
    hrMonth: 1;
    hrDay: 11;
    hrV: (
    (hrFeature: ftFixed; hrDescription: '<code>AUTO QSO NUMBER DECREMENT</code> usage'),
    (hrFeature: ftFixed; hrDescription: 'Multipliers calculation in BLACK SEA CUP'),
    (hrFeature: ftFixed; hrDescription: 'Truncation of the first character in CW mode'),
    (hrFeature: ftAdded; hrDescription: '"Latest config file" button in start window'),
    (hrFeature: ftAdded; hrDescription: 'Added S48P14DC.DOM file in DOM directory'),
    (hrFeature: ftFixed; hrDescription: 'Display of TEN MINUTE RULE counter'),
    (hrFeature: ftRevision; hrDescription: 'Off-time for calculation of "Operating Time" changed to 30 minutes'),
    (hrFeature: ftRevision; hrDescription: 'Enabled "Help" -> "Check the latest version" menu item'),
    (hrFeature: ftRevision; hrDescription: 'New appearance of "Summary" report'),
    (hrFeature: ftRevision; hrDescription: 'Changed "CT1BOH info screen" window'),
    (hrFeature: ftAdded; hrDescription: 'Export of log to EDI format'),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), () //, ()
    )
    )

    ,
    (
    hrVersion: '4.187';
    hrYear: 2009;
    hrMonth: 12;
    hrDay: 21;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Loss of focus in callsign and exchange windows'),
    (hrFeature: ftFixed; hrDescription: 'Polling of FT450'),
    (hrFeature: ftAdded; hrDescription: 'Support of BLACK SEA CUP contest'),
    (hrFeature: ftAdded; hrDescription: 'Login function in networked mode - "Net" -> "Log in". Callsign of current operator displayed in log and in right bottom part of the main window'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), () //, ()
    )
    )

    ,
    (
    hrVersion: '4.186';
    hrYear: 2009;
    hrMonth: 12;
    hrDay: 6;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'Support of TUNE ALT-D ENABLE command'),
    (hrFeature: ftAdded; hrDescription: '"Send inactive rig to the frequency" in bandmap popup menu will tune the inactive radio to spot frequency and load the callsign into the Alt-D buffer'),
    (hrFeature: ftAdded; hrDescription: 'Support of DARC-10M, RADIO-MEMORY, REF-CW and REF-SSB contests'),
    (hrFeature: ftAdded; hrDescription: 'Support of IC-910H rig'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.183';
    hrYear: 2009;
    hrMonth: 12;
    hrDay: 4;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'Support of <03>EXECUTE<04>, <03>LASTSPFREQ<04> and <03>LASTCQFREQ<04> special commands'),
    (hrFeature: ftAdded; hrDescription: 'New menu item - Ctrl- -> Execute configuration file <Ctrl+V>'),
    (hrFeature: ftAdded; hrDescription: 'Support of TAC (TOPS Activity Contest) contest'),
    (hrFeature: ftAdded; hrDescription: 'Colored spots in DX CLuster window: red color - new mult, gray color - dupe'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.182';
    hrYear: 2009;
    hrMonth: 11;
    hrDay: 26;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'BAND MAP CUTOFF FREQUENCY for 40m'),
    (hrFeature: ftFixed; hrDescription: 'PTT LOCKOUT with Winkeyer'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.181';
    hrYear: 2009;
    hrMonth: 11;
    hrDay: 24;
    hrV: (
    (hrFeature: ftRevision; hrDescription: 'Network PTT lockout will work only for stations with PTT LOCKOUT=TRUE. Stations with PTT LOCKOUT=FALSE will not interfere to stations with PTT LOCKOUT=TRUE'),
    (hrFeature: ftRevision; hrDescription: 'Corrected points calculation for LZ<->LZ Qs in LZ DX contest'),
    (hrFeature: ftAdded; hrDescription: 'New command - <code>DVP RECOREDER</code> - defines a program that will be used for editing and playing audio files'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.179';
    hrYear: 2009;
    hrMonth: 11;
    hrDay: 11;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Azimuth display'),
    (hrFeature: ftFixed; hrDescription: 'Dupes display in bandmap for spots coming from telnet cluster'),
    (hrFeature: ftRevision; hrDescription: 'Default value of QSO BY MODE in ARRL-SS set to FALSE'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.178';
    hrYear: 2009;
    hrMonth: 11;
    hrDay: 8;
    hrV: (
    (hrFeature: ftRevision; hrDescription: 'Leading zero for checks in Cabrillo file for ARRL-SS'),
    (hrFeature: ftAdded; hrDescription: 'Processing of WEIGHT command'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.177';
    hrYear: 2009;
    hrMonth: 11;
    hrDay: 3;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Filling Exchange Window with previous exchanges in Ukrainian DX Contest'),
    (hrFeature: ftFixed; hrDescription: 'Serial number lockout when all client staions are in S&P mode'),
    (hrFeature: ftRevision; hrDescription: 'Changed method of mode setting for Icom rigs (to fix problem with IC718)'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.175';
    hrYear: 2009;
    hrMonth: 10;
    hrDay: 31;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Usage of CALLSIGN UPDATE ENABLE with more then one callsign in exchange window'),
    (hrFeature: ftAdded; hrDescription: 'Additional way to load in remaining mults list - use REMAININGMULTS.TXT in log path'),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.173';
    hrYear: 2009;
    hrMonth: 10;
    hrDay: 29;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Display of "MULT" indicator'),
    (hrFeature: ftFixed; hrDescription: 'Usage of "REMAINING MULTS" reserved keyword in cty.dat'),
    (hrFeature: ftFixed; hrDescription: 'Exhange parser in ARRL-SS contest'),
    (hrFeature: ftFixed; hrDescription: 'Zones definition for Asiatic Russia'),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.172';
    hrYear: 2009;
    hrMonth: 10;
    hrDay: 29;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Usage of <code>SINGLE BAND SCORE</code> command'),
    (hrFeature: ftFixed; hrDescription: 'Import from ADIF v.2'),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.169';
    hrYear: 2009;
    hrMonth: 10;
    hrDay: 12;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'Winkeyer usage with old firmware'),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.168';
    hrYear: 2009;
    hrMonth: 10;
    hrDay: 11;
    hrV: (
    (hrFeature: ftFixed; hrDescription: 'lame_enc.dll usage'),
    (hrFeature: ftFixed; hrDescription: 'Winkeyer - silence after sending n messages'),
    (hrFeature: ftRevision; hrDescription: 'Changed appearance and location of new tour window in multi tours contests'),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.167';
    hrYear: 2009;
    hrMonth: 10;
    hrDay: 2;
    hrV: (
    (hrFeature: ftAdded; hrDescription: 'New commands:<br/><code>RADIO ONE WIDE CW FILTER</code><br/><code>RADIO TWO WIDE CW FILTER</code><br/><br/>Actuals for FT747GX, FT840, FT890, FT900, FT990, FT1000 rigs. Set width of CW filter'),
    (),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    ,
    (
    hrVersion: '4.162';
    hrYear: 2009;
    hrMonth: 9;
    hrDay: 24;
    hrV: (
    (hrFeature: ftRevision; hrDescription: 'Code optimization: cty.dat processing'),
    (hrFeature: ftAdded; hrDescription: 'Support of R9W-UW9WK-MEMORIAL contest'),
    (),
    (),
    (),
    (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), (), ()
    )
    )

    )
    ;

implementation

procedure MakeRevisionHistory();
var
  h                                     : HWND;
  nNumberOfBytesToWrite                 : Cardinal;
  Version                               : integer;
  Feature                               : integer;
begin
//  if not Tree.tOpenFileForWrite(h, 'e:\Program Files\Apache Software Foundation\Apache2.2\tr4w\rev-history.html') then Exit;
//  if not Tree.tOpenFileForWrite(h, 'd:\Documents and Settings\1.NEWXP\workspace\CMS\xml\releases.xml') then Exit;

  h := CreateFile(BASE + 'CMS\xml\releases.xml', GENERIC_READ + GENERIC_WRITE, FILE_SHARE_READ + FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
  if h = INVALID_HANDLE_VALUE then Exit;

  nNumberOfBytesToWrite := Format(wsprintfBuffer, '%s',

    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<cms>' +
    '<title>Release notes</title><pfx>../</pfx>' +
//    '<title>Release notes</title>' +
    '<content><![CDATA['
    //+ '<html><body><head><title>TR4W revision history</title><link rel="stylesheet" href="style.css" type="text/css"/></head>'
    );
  sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);

  for Version := 0 to TOATALVERSION2 - 1 {+1} do
  begin
    nNumberOfBytesToWrite := Format(wsprintfBuffer, '<b>Version %s</b>', V[Version].hrVersion);
    sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);

    nNumberOfBytesToWrite := Format(wsprintfBuffer, '<i> (%02u-%s-%u)</i>', V[Version].hrDay, MonthTags[V[Version].hrMonth], V[Version].hrYear);
    sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);

    sWriteFile(h, '<ul>', 4);
    for Feature := 0 to MAXFEATURES - 1 do
    begin
      if V[Version].hrV[Feature].hrFeature = ftUndef then Continue;
      nNumberOfBytesToWrite := Format(wsprintfBuffer, '<li>%s: %s.</li>', FID[V[Version].hrV[Feature].hrFeature], V[Version].hrV[Feature].hrDescription);
      sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);
    end;
    sWriteFile(h, '</ul>', 5);
  end;

  nNumberOfBytesToWrite := Format(wsprintfBuffer, '%s', ']]></content></cms>');
  sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);
  CloseHandle(h);
end;

procedure MakeLatestReleasesNotes();
const
  FEATURES_IN_COLUMN                    = 35;

  AD_CODE_WIDE                          =
    '<script type="text/javascript">' +
    'google_ad_client = "pub-9477631287615215";' +
    'google_ad_slot = "4249913459";' +
    'google_ad_width = 728;' +
    'google_ad_height = 90;' +
    '</script>' +
    '<script type="text/javascript"' +
    ' src="http://pagead2.googlesyndication.com/pagead/show_ads.js">' +
    '&#160;</script>';

  AD_CODE                               =
    '<script type="text/javascript">' +
    'google_ad_client = "pub-9477631287615215";' +

//    'google_ad_slot = "5425980571";' +
//    'google_ad_width = 250;' +
//    'google_ad_height = 250;' +

  'google_ad_slot = "8878102502";' +
    'google_ad_width = 336;' +
    'google_ad_height = 280;' +

  '</script>' +
    '<script type="text/javascript"' +
    ' src="http://pagead2.googlesyndication.com/pagead/show_ads.js">' +
    '&#160;</script><br/><br/>';

var
  h                                     : HWND;
  nNumberOfBytesToWrite                 : Cardinal;
  Version                               : integer;
  Feature                               : integer;
  InsertedFeatures                      : integer;
  secondcolumn                          : boolean;
  AdInserted                            : boolean;
begin
//  if not Tree.tOpenFileForWrite(h, 'e:\Program Files\Apache Software Foundation\Apache2.2\tr4w\download\latest-releases-notes.html') then Exit;
//  if not Tree.tOpenFileForWrite(h, 'd:\Documents and Settings\1.NEWXP\workspace\CMS\xml\latest-releases-notes.xml') then Exit;

  h := CreateFile(BASE + 'CMS\xml\latest-releases-notes.xml', GENERIC_READ + GENERIC_WRITE, FILE_SHARE_READ + FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);
  if h = INVALID_HANDLE_VALUE then Exit;

  nNumberOfBytesToWrite := Format(wsprintfBuffer, '%s',
    '<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">' +
    '<xsl:template name="latestReleases">' +
    '<table cellpadding="20" cellspacing="10" style="font-size:8pt">' +

//    '<tr><td align="center" colspan="2">' + AD_CODE_WIDE + '</td></tr>' +

    '<tr style="vertical-align:top">' +

    '<td style="width:340px">');
  sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);

  InsertedFeatures := 0;
  secondcolumn := False;
  AdInserted := False;

  for Version := 0 to TOATALVERSION2 - 1 do
  begin
    nNumberOfBytesToWrite := Format(wsprintfBuffer, '<b>Version %s</b>', V[Version].hrVersion);
    sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);

    nNumberOfBytesToWrite := Format(wsprintfBuffer, '<i> (%02u-%s-%u)</i>', V[Version].hrDay, MonthTags[V[Version].hrMonth], V[Version].hrYear);
    sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);

    sWriteFile(h, '<ul>', 4);
    for Feature := 0 to MAXFEATURES - 1 do
    begin
      if V[Version].hrV[Feature].hrFeature = ftUndef then Continue;
      nNumberOfBytesToWrite := Format(wsprintfBuffer, '<li>%s: %s.</li>', FID[V[Version].hrV[Feature].hrFeature], V[Version].hrV[Feature].hrDescription);
      sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);
      inc(InsertedFeatures);
    end;
    sWriteFile(h, '</ul>', 5);

    if InsertedFeatures > FEATURES_IN_COLUMN * 2 then
      Break;

    if not secondcolumn then
    begin
      if InsertedFeatures > FEATURES_IN_COLUMN then
      begin

        nNumberOfBytesToWrite := Format(wsprintfBuffer, '%s', '</td><td style="width:340px;vertical-align:top">');
        sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);
        secondcolumn := True;

        //sWriteFile(h, AD_CODE, length(AD_CODE));

      end;
    end
    else
    begin
      if not AdInserted then
      begin

      end;
    end;

  end;

  nNumberOfBytesToWrite := Format(wsprintfBuffer, '%s',

    '</td><td/></tr>' +

  //'<tr><td align="center" colspan="2">' + AD_CODE + '</td></tr>'+

    '</table></xsl:template></xsl:stylesheet>');
  sWriteFile(h, wsprintfBuffer, nNumberOfBytesToWrite);
  CloseHandle(h);
end;

end.

