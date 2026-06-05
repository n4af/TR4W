const
  { %s =	A string.}
  { %c =	A single character.}
  { %d =	A signed decimal integer argument.}
  { %u =	An unsigned integer argument.}

  TC_TRANSLATION_LANGUAGE               = 'CHINESE';
  TC_TRANSLATION_AUTHOR                 = 'Li Jia Wei BA4WI';

  TC_CALLSIGN                           = 'Callsign';
  TC_BAND                               = 'Band';
  TC_FREQ                               = 'Freq';
  TC_DATE                               = 'Date';
  TC_POINTS                             = 'Pts';
  TC_OP                                 = 'Op';
  TC_NAME                               = 'Name';

  TC_CHECKCALLSIGN                      = 'Check callsign';

  TC_FREQUENCYFORCALLINKHZ              = 'frequency for %s in kHz';
  TC_DIFVERSION                         = '%s is from a different program version.'#13'TR4W is expecting version %s.'#13'The file you are trying to read version %s.';
  TC_FILE                               = 'File';

  TC_M                                  = 'm'; //minute
  TC_S                                  = 's'; //second

  TC_RADIO1                             = 'Radio 1';
  TC_RADIO2                             = 'Radio 2';

  TC_DISBALE_CIV                        = 'Disable "CI-V Transceive" mode in your ICOM rig. Refer to instruction manual of your radio.';

  {MAIN}
  TC_YOU_ARE_USING_THE_LATEST_VERSION   = 'You are using the latest version';
  TC_SET_VALUE_OF_SET_NOW               = 'Set value of %s. Set now?';
  TC_CONFIGURATION_FILE                 = 'Configuration file';
  TC_CURRENT_OPERATOR_CALLSIGN          = 'current operator callsign';
  TC_APPENDIMPORTEDQSOSTOCURRENTLOG     = 'Append imported QSOs to current log?';
  TC_QSO_IMPORTED                       = 'Qs imported.'; // - '345 Qs imported.'
  TC_ISADUPE                            = '%s is a dupe!!';
  TC_ERRORINLOGFILE                     = 'Error in log file!';
  TC_HASIMPROPERSYNTAX                  = '%s has improper syntax!!';
  TC_SORRYNOLOG                         = 'Sorry!! NO LOG = TRUE which prohibits logging QSOs on this computer';
  TC_SETCOMPUTERIDVALUE                 = 'Set COMPUTER ID value.';

  TC_CLEARALLLOGS                       = '"CLEARALLLOGS" to clear all logs in network';
  TC_CLEAR_DUPESHEET_NET                = '"CLEARDUPESHEET" to clear all dupesheets in network';
  TC_CLEAR_MULTSHEET_NET                = '"CLEARMULTSHEET" to clear all multsheets in network';

  TC_WANTTOCONVERTLOG                   = 'Would you like to convert this log to the latest format?';
  TC_LOGFILENOTFOUND                    = 'Log file not found';
  TC_CANNOTBACKUPLOG                    = 'Could not make a backup copy of ';
  TC_CANNOTCOPYLOGREADONLY              = 'Cannot copy log file -- target exists and is read-only';
  TC_BACKUPCREATED                      = 'Log file backup created';
  TC_CANNOTRENAME                       = 'Can not rename';

  TC_REALLYWANTTOCLEARTHELOG            = 'Do you really want to clear the current log?';
  TC_MESSAGETOSENDVIANETWORK            = 'message to send via network';
  TC_SENDTIMETOCOMPUTERSONTHENETWORK    = 'Do you really want to send time to computers on the network?';
  TC_RULESONSM3CER                      = 'Rules for %s contest on WA7BNM Contest Calendar';
  TC_RULESONQRZRU                       = 'Rules for %s contest on QRZ.RU';
  TC_NOTE                               = 'note';
  TC_DUPESHEETCLEARED                   = 'Dupe sheet cleared!';
  TC_MULTSHEETCLEARED                   = 'Mult sheet cleared!';
  TC_YESTOCLEARTHEDUPESHEET             = '"YES" to clear the dupesheet';
  TC_CLEARMULTTOCLEARMULTSHEET          = '"CLEARMULT" to clear the multsheet';

  TC_TRANSMITFREQUENCYKILOHERTZ         = 'transmit frequency (kiloHertz): ';
  TC_SPRINTQSYRULE                      = 'SPRINT QSY RULE!!!';
  TC_PADDLE                             = 'Paddle';
  TC_FOOTSW                             = 'Footsw.';
  TC_LOG_NOTE                           = 'NOTE';
  TC_LOG_DELETED                        = 'DELETED';

  TC_SUN                                = 'Sun';
  TC_MON                                = 'Mon';
  TC_TUE                                = 'Tue';
  TC_WED                                = 'Wed';
  TC_THU                                = 'Thu';
  TC_FRI                                = 'Fri';
  TC_SAT                                = 'Sat';

  {uMP3Recorder}

  TC_LAME_ERROR                         = 'You may download it from';

  {This version TR4W v.4.009 beta was build in 2 December 2008. Do you want to check the latest version ?}
  TC_THISVERSION                        = 'You have ';
  TC_WASBUILDIN                         = ' installed (build date ';
  TC_DOYOUWANTTOCHECKTHELATESTVERSION   = 'Would you like to check for a possible newer version of  TR4W ?';

  {NEW CONTEST}
  TC_LATEST_CONFIG_FILE                 = 'Latest config file';
  TC_OPENCONFIGURATIONFILE              = ' - Open configuration file or start a new contest';
  TC_FOLDERALREADYEXISTSOVERWRITE       = 'Folder "%s" already exists.'#13'Overwrite ?';
  TC_IAMIN                              = '&I am in %s';

  TC_NEWENGLANDSTATEABREVIATION         = 'Enter your New England state abreviation'#13'(ME, NH, VT, MA, CT, RI):';
  TC_ENTERTHEQTHTHATYOUWANTTOSEND       = 'Enter the QTH that you want to send:';
  TC_ENTERSTATEFORUSPROVINCEFORCANADA   = 'Enter state for U.S., province for Canada:';
  TC_ENTERYOUROBLASTID                  = 'Enter your oblast ID:';
  TC_ENTERYOURPROVINCEID                = 'Enter your province ID:';
  TC_ENTERYOURCOUNTYCODE                = 'Enter your county code:';
  TC_ENTERYOURDOK                       = 'Enter your DOK:';
  TC_ENTERYOURDISTRICTABBREVIATION      = 'Enter your district abbreviation:';
  TC_ENTERYOURRDAID                     = 'Enter your RDA ID:';
  TC_ENTERYOURIOTAREFERENCEDESIGNATOR   = 'Enter your IOTA Reference Designator:';
  TC_ENTERYOURPARKREFERENCEDESIGNATOR   = 'Enter your POTA Park Reference Designator (WITH DASH e.g. K-1234)';
  TC_ENTERYOURCITYIDENTIFIER            = 'Enter your city identifier:';
  TC_ENTERYOURNAME                      = 'Enter your name:';
  TC_ENTERTHELASTTWODIGITSOFTHEYEAR     = 'Enter the last two digits of the year of your first official amateur radio license:';
  TC_ENTERYOURZONE                      = 'Enter your zone:';
  TC_ENTERYOURGEOGRAPHICALCOORDINATES   = 'Enter your geographical coordinates'#13'(e.g. 55N37O for Moscow):';
  TC_ENTERSUMOFYOURAGEANDAMOUNT         = 'Enter sum of your age and amount of years elapsed since your first QSO (e.g. 28+14=42):';
  TC_OZCR                               = 'Enter three-letters number:';
  TC_ENTERYOURSTATECODE                 = 'Enter your state code:';
  TC_ENTERYOURFOURDIGITGRIDSQUARE       = 'Enter your four digit grid square:';
  TC_RFAS                               = 'Enter your geographical coordinates:';
  TC_ENTERYOURSIXDIGITGRIDSQUARE        = 'Enter your six digit grid square:';
  TC_ENTERYOURNAMEANDSTATE              = 'Enter your name (and state if you are in North America):';
  TC_ENTERYOURNAMEANDQTH                = 'Enter your name and QTH (US state, Canadian Province or DX country) or member number:';
  TC_ENTERYOURPRECEDENCECHECKSECTION    = 'Enter your precedence, your check'#13'(last two digits of year licensed) and ARRL section:';
  TC_ENTERYOURQTHANDTHENAME             = 'Enter your QTH that you want to send'#13'and the name you want to use:';
  TC_ENTERFIRSTTWODIGITSOFYOURQTH       = 'Enter first two digits of your QTH:';
  TC_ENTERYOURAGEINMYSTATEFIELD         = 'Enter your age in MY STATE field:';
  TC_ENTERYOURQTHORPOWER                = 'Enter your QTH that you want to send if you are in North America or your power as MY STATE if outside:';
  TC_ENTERFIRSTTWOLETTERSOFYOURGRID     = 'Enter first two letters of your grid square:';
  TC_ENTERYOURSQUAREID                  = 'Enter your square ID:';
  TC_ENTERYOURMEMBERSHIPNUMBER          = 'Enter your membership number:';
  TC_ENTERYOURCONTINENT                 = 'Enter your continent (and possible additional ID, i.e. SA or NA/QRP)';
  TC_ENTERYOURCOUNTYORSTATEPOROVINCEDX  = 'Enter your county if you in %s state. Enter your state, Canadian Province or "DX" if outside of %s:';
  TC_PREFECTURE                         = 'Enter your prefecture:';
  TC_STATIONCLASS                       = 'Enter your station class:';
  TC_AGECALLSIGNAGE                     = 'Enter your age (and Silent Key callsign and age):';
  TC_DEPARTMENT                         = 'Enter your department:';
  TC_ENTERYOURRDAIDORGRID               = 'Enter your RDA ID (for UA1A stations) or four digit grid square:';
  TC_ENTERYOURBRANCHNUMBER              = 'Enter your Branch number:';

  TC_ISLANDSTATION                      = 'Island station';
  TC_NEWENGLAND                         = 'New England';
  TC_CALIFORNIA                         = 'California';
  TC_FLORIDA                            = 'Florida';
  TC_MICHIGAN                           = 'Michigan';
  TC_MINNESOTA                          = 'Minnesota';
  TC_OHIO                               = 'Ohio';
  TC_WASHINGTON                         = 'Washington';
  TC_WISCONSIN                          = 'Wisconsin';
  TC_TEXAS                              = 'Texas';
  TC_NORTHAMERICA                       = 'North America';
  TC_RUSSIA                             = 'Russia';
  TC_UKRAINE                            = 'Ukraine';
  TC_CZECHREPUBLICORINSLOVAKIA          = 'Czech Republic or in Slovakia';
  TC_BULGARIA                           = 'Bulgaria';
  TC_ROMANIA                            = 'Romania';
  TC_HUNGARY                            = 'Hungary';
  TC_BELGIUM                            = 'Belgium';
  TC_NETHERLANDS                        = 'Netherlands';
  TC_STPETERSBURGOBLAST                 = 'St.Petersburg / oblast';
  TC_GERMANY                            = 'Germany';
  TC_UK                                 = 'UK';
  TC_ARKTIKACLUB                        = 'club';
  TC_POLAND                             = 'Poland';
  TC_KAZAKHSTAN                         = 'Kazakhstan';
  TC_ITALY                              = 'Italy';
  TC_SWITZERLAND                        = 'Switzerland';
  TC_HQ                                 = 'HQ (HQ station)';
  TC_CIS                                = 'CIS';
  TC_SPAIN                              = 'Spain';
  TC_JAPAN                              = 'Japan';
  TC_CANADA                             = 'Canada';
  TC_FRANCE                             = 'France';
  TC_HQ_OR_MEMBER                       = 'HQ or member';

  {UTELNET}

  TC_TELNET                             = 'Connect'#0'Disconnect'#0'Commands'#0'Freeze'#0'Clear'#0'100'#0#0;
  TC_YOURNOTCONNECTEDTOTHEINTERNET      = 'YOUR NOT CONNECTED TO THE INTERNET!';
  TC_GETHOST                            = 'GET HOST..';
  TC_SERVER                             = 'SERVER: %s';
  TC_HOST                               = 'HOST  : %s';
  TC_CONNECT                            = 'CONNECT..';
  TC_CONNECTED                          = 'CONNECTED';
  TC_YOUARESPOTTEDBYANOTHERSTATION      = 'You are spotted by another station.';

  {UNET}

  TC_CONNECTIONTOTR4WSERVERLOST         = 'Connection to TR4WSERVER %s:%d lost.';
  TC_COMPUTERCLOCKISSYNCHRONIZED        = 'Computer clock is synchronized.';
  TC_CONNECTINGTO                       = 'Connecting to ';
  TC_CONNECTTOTR4WSERVERFAILED          = 'Connect to TR4WSERVER failed. Check SERVER PASSWORD value!!';
  TC_CONNECTEDTO                        = 'Connected to ';
  TC_DISCONNECTEDFROM                   = '** DISCONNECTED from ';
  TC_AUTOSYNCHRONIZINGLOG               = 'Auto-synchronizing log from server.';
  TC_FAILEDTOCONNECTTO                  = 'Failed to connect to ';
  TC_SERVERANDLOCALLOGSAREIDENTICAL     = 'Server and local logs are identical.';
  TC_NETWORK                            = 'Network : %s %s:%d';
  TC_SERVER_LOG_CHANGED                 = 'Server log changed. %u QSO(s) updated. Do logs synchronizing (Ctrl+Alt+S).';
  TC_ALL_LOGS_NETWORK_CLEARED           = 'All logs in TR4W network cleared.';

  {UGETSCORES}

  TC_FAILEDTOCONNECTTOGETSCORESORG      = 'Failed to connect';
  TC_NOANSWERFROMSERVER                 = 'No answer from server';
  TC_UPLOADEDSUCCESSFULLY               = 'Uploaded successfully.';
  TC_FAILEDTOLOAD                       = 'Failed to load. View getscoresanswer.html for details.';

  {UBANDMAP}

  TC_SOURCE                             = 'Source: %s';
  TC_MIN                                = '%u min.';

  {LOGWIND}

  TC_CQTOTAL                            = 'CQ total: %u';
  TC_REPEATING                          = 'Repeating %s  Listen time = %u msec - PgUp/Dn to adjust or ESCAPE';
  TC_NEWTOUR                            = 'New tour %d/%d';
  TC_ENTER                              = 'Enter %s :';
  TC_PTS                                = '%d Pts';
  TC_RATE                               = 'Rate = %u';
  TC_LAST60                             = 'Last 60 = %d';
  TC_THISHR                             = 'This hr = %d';
  TC_BAND_CHANGES                       = 'Bn. ch. = %d';

  TC_HAVEQTCS                           = 'Have %u QTCs';
  TC_INSERT                             = 'INSERT';
  TC_OVERRIDE                           = 'OVERRIDE';
  TC_UNKNOWNCOUNTRY                     = 'Unknown country';

  {UCALLSIGNS}

  TC_DUPESHEET                          = 'Dupesheet - %sm-%s';

  {LOGEDIT}

  TC_QSONEEDSFOR                        = ' QSO needs for %s :';
  TC_MULTNEEDSFOR                       = ' Mult needs for %s :';
  TC_MISSINGMULTSREPORT                 = 'Missing mults report: %u countries on at least %u but not all bands.';

  {LOGDUPE}

  TC_THEREWERECALLS                     = 'There were %u calls found in initial exchange file.'#13'+%u dupe(s)';
  TC_RESTARTBINISFORADIFFERENTCONTEST   = 'RESTART.BIN is for a different contest.';

  {LOGSTUFF}

  TC_NOTENOUGHINFOINEXCHANGE            = 'Not enough info in exchange!!';
  TC_IMPROPERDOMESITCQTH                = 'Improper domestic QTH!!';
  TC_IMPROPERDOMESITCQTHORMISSINGNAME   = 'Improper domesitc QTH or missing name!!';
  TC_MISSINGQTHANDORNAME                = 'Missing QTH and/or name!!';
  TC_NOQSONUMBERFOUND                   = 'No QSO number found!!';
  TC_IMPROPERZONENUMBER                 = 'Improper zone number!!';
  TC_SAVINGTO                           = 'Saving %s to %s';
  TC_FILESAVEDTOFLOPPYSUCCESSFULLY      = 'File saved to floppy successfully.';
  TC_FILESAVEDTOSUCCESSFULLY            = 'File saved to %s successfully.';
  TC_IMPROPERTRANSMITTERCOUNT           = 'FD transmitters must be between 1 and 99.';
  TC_IMPROPERARRLFIELDDAYCLASS          = 'Field Day class must be A, B, C, D, E or F.';
  TC_OIMPROPERWINTERFIELDDAYCLASS       = 'Class must be O, I or H.';
  TC_ARRLFIELDDAYIMPROPERDXEXCHANGE     = 'DX Station exchange must be "DX".';

  {LOGSEND}

  TC_WAITINGFORYOUENTERSTRENGTHOFRST    = 'Waiting for you enter strength of RST (Single digit)!!';

  {COUNTRY9}

  TC_C9_NORTHAMERICA                    = 'North America';
  TC_C9_SOUTHAMERICA                    = 'South America';
  TC_C9_EUROPE                          = 'Europe';
  TC_C9_AFRICA                          = 'Africa';
  TC_C9_OCEANIA                         = 'Oceania';
  TC_C9_ASIA                            = 'Asia';
  TC_C9_UNKNOWN                         = 'Unknown';

  {USTATIONS}

  TC_STATIONSINMODE                     = 'Stations in %s mode';

  {USPOTS}

  TC_SPOTS                              = '%d spots';

  {uSendKeyboard}

  TC_SENDINGSSBWAVFILENAME              = 'Sending SSB .wav filename. Use ENTER to play, Escape/F10 to exit.';

  {QTC}

  TC_WASMESSAGENUMBERCONFIRMED          = 'Was message number %u confirmed?';
  TC_DOYOUREALLYWANTSTOPNOW             = 'Do you really want stop now?';
  TC_QTCABORTEDBYOPERATOR               = 'QTC aborted by operator.';
  TC_DOYOUREALLYWANTTOABORTTHISQTC      = 'Do you really want to abort this QTC?';
  TC_NEXT                               = '< Next';
  TC_QTC_FOR                            = '%s for %s';
  TC_QTC_CALLSIGN                       = 'Callsign :';
  TC_ENTERQTCMAXOF                      = 'Enter QTC #/# (max of %d) :';
  TC_DOYOUREALLYWANTTOSAVETHISQTC       = 'Do you really want to save this QTC?';
  TC_EDITQTCPRESSYESTOEDITQTCORNOTOLOG  = 'Edit QTC? Press Yes to edit QTC or  No to log ';
  TC_CHECKQTCNUMBER                     = 'Check QTC number';
  TC_CHECKTIME                          = 'Check time';

  {UOPTION}

  TC_COMMAND                            = 'Command';
  TC_VALUE                              = 'Value';
  TC_INFO                               = 'Info';
  TC_YOUCANCHANGETHISINYOURCONFIGFILE   = 'You can only change this in your config file.';

  {UEDITQSO}

  TC_CHECKDATETIME                      = 'Check Date/Time !!';
  TC_SAVECHANGES                        = 'Save changes?';

  {LOGCW}

  TC_WPMCODESPEED                       = 'WPM code speed';
  TC_CQFUNCTIONKEYMEMORYSTATUS          = 'CQ FUNCTION KEY MEMORY STATUS';
  TC_EXCHANGEFUNCTIONKEYMEMORYSTATUS    = 'EXCHANGE FUNCTION KEY MEMORY STATUS';
  TC_OTHERCWMESSAGEMEMORYSTATUS         = 'Other CW message memory status';
  TC_OTHERSSBMESSAGEMEMORYSTATUS        = 'Other SSB message memory status';
  TC_PRESSCQFUNCTIONKEYTOPROGRAM        = ' Press CQ function key to program (F1, AltF1, CtrlF1), or ESCAPE to exit) : ';
  TC_PRESSEXFUNCTIONKEYTOPROGRAM        = 'Press ex function key to program (F3-F12, Alt/Ctrl F1-F12) or ESCAPE to exit:';
  TC_NUMBERORLETTEROFMESSAGETOBEPROGRAM = 'Number or letter of message to be programmed (1-9, A-C, or ESCAPE to exit):';
  TC_CWDISABLEDWITHALTK                 = 'CW disabled with Alt-K!!  Use Alt-K again to enable.';
  TC_VOICEKEYERDISABLEDWITHALTK         = 'Voice keyer disabled with Alt-K!!  Use Alt-K again to enable.';

  {LOGCFG}

  TC_NOCALLSIGNSPECIFIED                = 'No callsign specified!!';
  TC_NOFLOPPYFILESAVENAMESPECIFIED      = 'No floppy file save name specified!!';
  TC_UNABLETOFIND                       = 'Unable to find %s !!';
  TC_INVALIDSTATEMENTIN                 = 'INVALID STATEMENT IN %s !!'#13#13'Line %u'#13'%s';
  TC_UNABLETOFINDCTYDAT                 = 'Unable to find CTY.DAT country file!!'#13'Make sure this file is in the same directory as the program.';
  TC_INVALIDSTATEMENTINCONFIGFILE       = '%s:'#13'INVALID STATEMENT IN CONFIG FILE!!'#13#13'Line %u'#13'%s';
  TC_PARAMETERHASNOVALUE                = 'Parameter "%s" has no value in the config file -- left at its default.';

  {LOGSUBS1}

  TC_RECORDDVPPRESSESCAPEORRETURNTOSTOP = 'Recording DVP. Press ESCAPE or RETURN to stop.';
  TC_ALTRCOMMANDDISABLED                = 'Alt-R command requires TWO RADIO MODE = TRUE';
  TC_NOCQMESPROGRAMMEDINTOCQMEMORYALTF1 = 'No CQ message programmed into CQ MEMORY AltF1.';
  TC_THIS_FILE_DOES_NOT_EXIST           = 'This file does not exist. Create an empty file for editing?';

  {LOGSUBS2}

  TC_WASADUPE                           = '%s was a dupe.';
  TC_ALTDCOMMANDDISABLED                = 'Alt-D command requires TWO RADIO MODE = TRUE';
  TC_YOUHAVERESTOREDTHELASTDELETED      = 'You have restored the last deleted log entry!!';
  TC_YOUHAVEDELETEDTHELASTLOGENTRY      = 'You have deleted the last log entry!!  Use Alt-Y to restore it.';
  TC_DOYOUREALLYWANTTOEXITTHEPROGRAM    = 'Do you really want to exit the program?';
  TC_YOUARENOWTALKINGTOYOURPACKETPORT   = 'You are now talking to your packet port.  Use Control-B to exit.';
  TC_YOUALREADYWORKEDIN                 = 'You already worked %s in %s!!';
  TC_ISADUPEANDWILLBELOGGEDWITHZERO     = '%s is a dupe and will be logged with zero QSO points.';
  TC_LOGFILESIZECHECKFAILED             = 'LOG FILE SIZE CHECK FAILED!!!!';

  {JCTRL2}
  TC_NEWVALUE                           = 'new value';

  {TREE}

  TC_ALREADYEXISTSOKAYTODELETE          = '%s already exists.'#13#13'Okay to delete?';

  {UWINKEY}

  TC_WINKEYERENABLE                     = '&Winkeyer enable';
  TC_AUTOSPACE                          = '&Autospace';
  TC_CTSPACING                          = 'C&T spacing';
  TC_SIDETONE                           = '&Sidetone';
  TC_PADDLESWAP                         = 'Paddle swa&p';
  TC_IGNORESPEEDPOT                     = '&Ignore speed pot';
  TC_PADDLEONLYSIDETONE                 = 'Paddle &only sidetone';

  TC_WINKEYERPORT                       = 'Winkeyer port';
  TC_KEYERMODE                          = 'Keyer mode';
  TC_SIDETONEFREQ                       = 'Sidetone freq.';
  TC_HANGTIME                           = 'Hang time';

  TC_IAMBICB                            = 'Iambic B';
  TC_IAMBICA                            = 'Iambic A';
  TC_ULTIMATIC                          = 'Ultimatic';
  TC_BUGMODE                            = 'Bug mode';

  TC_WEIGHTING                          = 'Weighting';
  TC_DITDAHRATIO                        = 'Dit/Dah ratio';
  TC_LEADIN                             = 'Lead-in time (*10 ms)';
  TC_TAIL                               = 'Tail time (*10 ms)';
  TC_FIRSTEXTENSION                     = 'First extension';
  TC_KEYCOMP                            = 'Keyer compensation';
  TC_PADDLESWITCHPOINT                  = 'Paddle switchpoint';

  {UTOTAL}

  TC_QTCPENDING                         = 'QTC Pending';
  TC_ZONE                               = 'Zones';
  TC_PREFIX                             = 'Prefixes';
  TC_DXMULTS                            = 'DX Mults';
  TC_OBLASTS                            = 'Oblasts';
  TC_HQMULTS                            = 'HQ Mults';
  TC_DOMMULTS                           = 'Dom Mults';
  TC_QSOS                               = 'QSOs';
  TC_CWQSOS                             = 'CW QSOs';
  TC_SSBQSOS                            = 'SSB QSOs';
  TC_DIGQSOS                            = 'DIG QSOs';

  {UALTD}

  TC_ENTERCALLTOBECHECKEDON             = 'Enter call to be checked on %s%s:';

  {LOGGRID}

  TC_ALLSUN                             = 'All sun';
  TC_ALLDARK                            = 'All dark';

  {UMIXW}

  TC_MIXW_CONNECTED                     = 'Connected';
  TC_MIXW_DISCONNECTED                  = 'Disconnected';

  {LOGWAE}

  TC_INVALIDCALLSIGNINCALLWINDOW        = 'Invalid callsign in call window!!';
  TC_SORRYYOUALREADYHAVE10QTCSWITH      = 'Sorry, you already have 10 QTCs with %s';
  TC_NOQTCSPENDINGQRU                   = 'No QTCs pending, QRU.';
  TC_ISQRVFOR                           = 'Is %s QRV for %s?';

  {UREMMULTS}

  TC_CLEANSWEEPCONGRATULATIONS          = 'CLEAN SWEEP!! CONGRATULATIONS!!';

  {CFGCMD}

  TC_NETWORKTEST                        = 'Network Test';
  TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED   = 'Maximum number of reminders exceeded!!';
  TC_INVALIDREMINDERTIME                = 'Invalid reminder time!!';
  TC_INVALIDREMINDERDATE                = 'Invalid reminder date!!';
  TC_TOOMANYTOTALSCOREMESSAGES          = 'Too many TOTAL SCORE MESSAGEs!!';
  TC_THEFIRSTCOMMANDINCONFIGFILEMUSTBE  = 'The first command in config file must be the MY CALL statement!!';

  {USYNTIME}
  TC_MS                                 = ' ms'; //milliseconds

  {ULOGSEARCH}
  TC_ENTRIESPERMS                       = '%u entries per %u ms';

  {ULOGCOMPARE}
  TC_SIZEBYTES                          = 'Size, bytes';
  TC_RECORDS                            = 'Records';
  TC_MODIFIED                           = 'Modified';
  TC_TIMEDIFF                           = 'Time diff.';

  {POSTUNIT}
  TC_MORETHAN50DIFFERENTHOURSINTHISLOG  = 'More than 50 different hours in this log!!';
  TC_TOOMANYCONTESTDATES                = 'Too many contest dates!!';

  {UGETSERVERLOG}
  TC_FAILEDTORECEIVESERVERLOG           = 'Failed to receive server log.';

  {DLPORTIO}
  TC_DLPORTIODRIVERISNOTINSTALLED       = 'DLPortIO error';

  {UCT1BOH}
  TC_TIMEON                             = 'Time on';

  {ULOGCOMPARE}
  TC_SERVERLOG                          = 'SERVER LOG';
  TC_LOCALLOG                           = 'LOCAL LOG';

  {UEDITMESSAGE}

  TC_CTRL_A                             = 'Send this message on inactive radio';
  TC_CTRL_B                             = 'Identify ctrl-A message as a CQ';
  TC_CTRL_C                             = 'Start special command';
  TC_CTRL_D                             = 'Do not interrupt';
  TC_CTRL_E                             = 'Dah 73% of normal duration';
  TC_CTRL_F                             = 'Increase speed by 6%';
  TC_CTRL_K                             = 'Normal dah';
  TC_CTRL_L                             = 'Dit 140% of normal duration';
  TC_CTRL_N                             = 'Dah 113% of normal duration';
  TC_CTRL_O                             = 'Dah 127% of normal duration';
  TC_CTRL_P                             = 'Dit 60% of normal duration';
  TC_CTRL_Q                             = 'Dit 80% of normal duration';
  TC_CTRL_S                             = 'Decrease speed by 6%';
  TC_CTRL_V                             = 'Dit 120% of normal duration';
  TC_CTRL_X                             = 'Decrease weight by 0.03';
  TC_CTRL_Y                             = 'Increase weight by 0.03';
  TC_CTRL_SL                            = 'Normal dit';
  TC_QSO_NUMBER                         = 'QSO Number';
  TC_SALUTATION_AND_NAME_IF_KNOWN       = 'Salutation and name if known';
  TC_NAME_FROM_NAME_DATABASE            = 'Name from name database';
  TC_SEND_CHARACTERS_FROM_KEYBOARD      = 'Send characters from keyboard';
  TC_CALL_IN_CALL_WINDOW                = 'Call in Call Window';
  TC_RST_PROMPT                         = 'RST prompt';
  TC_SEND_CALLASSETBYMYCALLCOMMAND      = 'Send call as set by MY CALL command';
  TC_REPEATRSTSENT                      = 'Repeat RST sent';

  TC_HALFSPACE                          = 'Half space';
  TC_LASTQSOSCALL                       = 'Last QSO''s call';
  TC_RECEIVEDNAME                       = 'Received name';
  TC_PARTIALCORRECTEDCALL               = 'Partial corrected call';
  TC_SENDPROPERSALUTATIONWITHOUTNAME    = 'Send proper salutation without name';
  TC_GOTONEXTBANDLOWERINFREQUENCY       = 'Go to next band lower in frequency';
  TC_GOTONEXTBANDHIGHERINFREQUENCY      = 'Go to next band higher in frequency';
  TC_COMPLETECALLSIGN                   = 'Complete callsign';
  TC_FORCESTOENTERCQMODE                = 'Forces to enter CQ Mode';
  TC_TOGGLECWENABLE                     = 'Toggle CW ENABLE';
  TC_TURNSOFFMONITORING                 = 'Turns off monitoring of CW on the computer speaker.';
  TC_TURNSONMONITORING                  = 'Turns on monitoring of CW on the computer speaker';
  TC_CWENABLETRUE                       = 'CW ENABLE = TRUE';
  TC_CWENABLEFALSE                      = 'CW ENABLE = FALSE';
  TC_WORKSAMEASENTERONKEYBOARD          = 'Work same as "Enter" on keyboard';
  TC_WORKSAMEASESCONKEYBOARD            = 'Work same as "Esc" on keyboard';
  TC_EXCHANGESTHEFREQUENCIES            = ' Exchanges the frequencies on the Active and inactive rigs';
  TC_EXECUTEACONFIGURATIONFILE          = 'Execute a configuration file';
  TC_MOVESTHERIGTOLASTCQFREQUENCY       = 'Moves the rig to last frequency where you called CQ';
  TC_LOGSTHELASTCALL                    = 'Logs the last call that appeared in the Call Window';
  TC_FORCESTOENTERMODE                  = 'Forces to enter S&P Mode';
  TC_CHANGESCWSPEEDTOXX                 = 'Changes CW speed to xx';
  TC_SENDSXXTOTHEACTIVERADIO            = 'Sends xx to the active radio';
  TC_SENDSXXTOTHERADIO1                 = 'Sends xx to the Radio 1';
  TC_SENDSXXTOTHERADIO2                 = 'Sends xx to the Radio 2';
  TC_SENDSXXTOTHEINACTIVERADIO          = 'Sends xx to the inactive radio';
  TC_SWAPSTHEACTIVEANDINACTIVERIGS      = 'Swaps the active and inactive rigs';
  TC_TOGGLESSENDINGSENDING              = 'Toggles sending — sending, not monitoring — of CW';
  TC_TOGGLESMODEBETWEENCWANDSSB         = 'Toggles mode between CW and SSB';
  TC_RUNXXAPPLICATION                   = 'Run xx application';

  {UCHECKLATESTVERSION}
  TC_VERSIONONSERVER                    = 'The last version on server';
  TC_THISVERSION2                       = 'This version';
  TC_DOWNLOADIT                         = 'Would you like to download the latest version?';

  CLOSE_WORD                            = 'õÅ¦ù×í';
  CANCEL_WORD                           = 'õÏÖö¦È';
  HELP_WORD                             = 'õ¬îõÊé';
  OK_WORD                               = '÷áîõîÚ';
  EXIT_WORD                             = 'õÅ¦ù×í';
  RC_CALLSIGN                           = 'õÑ-õÏ¬';
  RC_MODE                               = 'öèáõ-Ï';
  RC_BAND                               = 'ö¦âöî¦';
  RC_FREQUENCY                          = 'ùâÑ÷ÎÇ';
  RC_APPLY                              = 'õ¦Ô÷Ôè&A';
  RC_RESET                              = 'õäÍô-Í&R';
  RC_START                              = 'õ-ÀõçË';
  RC_SHOW                               = 'öØ-÷ä¦';
  RC_SAVE                               = 'ô¬ÝõíØ&S';
  RC_CREATE                             = 'öÖ-õ¬¦';
  RC_EDIT_WORD                          = '÷-Öø-Ñ&E';
  RC_POSTSCORETOGS                      = 'Post score';
  RC_POSTNOW                            = 'Post now';
  RC_GOTOGS                             = 'Show scores';
  RC_FILE                               = 'öÖÇô¬¦';
  RC_NEWCONTEST                         = 'öÖ-õ¬¦÷ëÞø¦Û';
  RC_CLEARLOG                           = 'ö¬ÅùÙäö×åõ¬×';
  RC_IMPORT                             = 'õï-õÅå';
  RC_OPENLOGDIR                         = 'öÉÓõ-Àö×åõ¬×ø¬ïõ-Ä';
  RC_EXPORT                             = 'õï-õÇ¦';
  RC_INIEXLIST                          = 'õÈÝõçËõÌÖô¦äöÍâõÈ×øáè';
  RC_TRLOGFORM                          = 'TRö×åõ¬×öà-õ-Ï';
  RC_REPORTS                            = 'öÊåõÑÊ';
  RC_ALLCALLS                           = 'õÅèùÃèõÑ-õÏ¬';
  RC_BANDCHANGES                        = 'ö¦âöî¦õÈÇöÍâ';
  RC_CONTLIST                           = 'õÛ-õî¦õÈ×øáè';
  RC_FCC                                = 'õÐÄõÛ-÷ììô¬Àô¬ê÷áîøîäõÑ-õÏ¬';
  RC_FCZ                                = 'õÐÄõÈÆõÌ¦÷ììô¬Àô¬ê÷áîøîäõÑ-õÏ¬';
  RC_POSSBADZONE                        = 'õÏïøÃ-ùÔÙøïï÷ÚÄõÈÆõÌ¦';
  RC_QSOBYCOUNTRY                       = 'öÌÉõÛ-õî¦ö¦âöî¦õÈÆ÷-¬';
  RC_SCOREBYHOUR                        = 'õ-Ïö×¦õÈÆöÕ-';
  RC_SUMMARY                            = 'õ-Ïøîá';
  RC_EXIT                               = 'ùÀÀõÇ¦';
  RC_SETTINGS                           = 'øî-÷-î';
  RC_OPTIONS                            = 'ùÅÍ÷-îõÑ-ô¬ä';
  RC_CFG_COMMANDS                       = 'ùÅÍ÷-îõÑ-ô¬ä';
  RC_PROGRAMMES                         = '÷èËõ¦Ïö¦ÈöÁï';
  RC_CATANDCW                           = 'öÎçõÈ¦õÒÌ÷Ô¦ùÔî';
  RC_RADIOONE                           = '÷Ô¦õÏ-1';
  RC_RADIOTWO                           = '÷Ô¦õÏ-2';
  RC_WINDOWS                            = '÷ê×õÏã';
  RC_BANDMAP                            = 'ö¦âöî¦÷ê×õÏã';
  RC_DUPESHEET                          = 'ùÔÙøïïøáè';
  RC_FKEYS                              = 'õÊßøÃ-ùÔî';
  RC_TRMASTER                           = 'SCP';
  RC_REMMULTS                           = 'õÉéô-Ù÷¦¬öÕ-';
  RC_RM_DEFAULT                         = 'ù¬Øøîä';
  RC_RADIO1                             = '÷Ô¦õÏ-1';
  RC_RADIO2                             = '÷Ô¦õÏ-2';
  RC_TELNET                             = 'DXõÅìõÑÊöÝ¬';
  RC_NETWORK                            = '÷-Ñ÷¬Ü';
  RC_INTERCOM                           = 'õï¦øî-';
  RC_GETSCORES                          = 'RC_POSTSCORETOGS""';
  RC_STATIONS                           = '÷Ô¦õÏ-';
  RC_MP3REC                             = 'MP3õ-Õùß¦';
  RC_QUICKMEM                           = 'õ¬ëùÀßõíØõÂè';
  RC_MULTSFREQ                          = '÷¦¬öÕ-ùâÑ÷ÎÇ';
  RC_ALARM                              = 'øíæõÑÊ';
  RC_AUTOCQRESUME                       = 'öÁâõäÍøÇêõÊèõÑ-õÏë';
  RC_DUPECHECK                          = 'ùÔÙøïïöãÀö¦Ë';
  RC_EDIT                               = '÷-Öø-Ñ';
  RC_SAVETOFLOPPY                       = 'ô¬ÝõíØõÈ-ø-ïô¬¦';
  RC_SWAPMULTVIEW                       = 'ô¦äöÍâ÷¦¬öÕ-øçÆõÛ-';
  RC_INCNUMBER                          = 'õâÞùÇÏ÷-ÖõÏ¬';
  RC_TOOGLEMB                           = '÷¦¬öÕ-ùÓÃõ-ÀõÅ¦';
  RC_KILLCW                             = 'õÁÜöíâCW';
  RC_SEARCHLOG                          = 'öÐÜ÷+âö×åõ¬×';
  RC_TRANSFREQ                          = 'õÏÑõ-ÄùâÑ÷ÎÇ';
  RC_REMINDER                           = 'öÏÐùÆÒ';
  RC_AUTOCQ                             = 'øÇêõÊèõÑ-õÏë';
  RC_TOOGLERIGS                         = 'øî-õäÇõÈÇöÍâ';
  RC_CWSPEED                            = 'CWùÀßõ¦æ';
  RC_SETSYSDT                           = 'øî-÷-î÷¦¬÷¬ßö×åöÜß/ö×¦ù×+';
  RC_INITIALIZE                         = 'õÈÝõçËõÌÖQSO';
  RC_RESETWAKEUP                        = 'õÔäùÆÒõäÍô-Í';
  RC_DELETELASTQSO                      = 'õÈàùÙäöÜÀõÐÎô¬Àô¬êQSO';
  RC_INITIALEX                          = 'õÈÝõçËõÌÖô¦äöÍâ';
  RC_TOOGLEST                           = 'ô-çùß¦õÈÇöÍâ';
  RC_TOOGLEAS                           = 'øÇêõÊèõÏÑùÀÁõ-ÀõÅ¦';
  RC_BANDUP                             = 'ö¦âöî¦õÐÑô¬Ê';
  RC_BANDDOWN                           = 'ö¦âöî¦õÐÑô¬Ë';
  RC_SSBCWMODE                          = 'SSB/CWöèáõ-Ï';
  RC_SENDKEYBOARD                       = 'õÏÑùÀÁùÔî÷ÛØø-ÓõÅå';
  RC_COMMWITHPP                         = 'ô¬Îõ-ÁõÌÅ÷ëïõÏãùÀÚô¬á';
  RC_CLEARDUPES                         = 'ö¬ÅùÙäùÔÙøïïõÈ×øáè';
  RC_VIEWEDITLOG                        = 'ößå÷ÜË/÷-Öø-Ñö×åõ¬×';
  RC_NOTE                               = 'õäÇö¦è';
  RC_MISSMULTSREP                       = 'ùÔÙøïï÷¦¬öÕ-öÊåõÑÊ';
  RC_REDOPOSSCALLS                      = 'ùÇÍõäÍõÏïøÃ-÷ÚÄõÑ-õÏ¬';
  RC_QTCFUNCTIONS                       = 'QTCùÀÉùá¦';
  RC_RECALLLASTENT                      = 'ùÇÍõÑ-ø-ÓõÅåöáÆ';
  RC_VIEWPAKSPOTS                       = 'ößå÷ÜËõÏÑùÀÁõÌÅ';
  RC_EXECONFIGFILE                      = 'öÉçøáÌùÅÍ÷-îöÖÇô¬¦';
  RC_REFRESHBM                          = 'õÈ¬öÖ-ö¦âöî¦õÛ-';
  RC_DUALINGCQ                          = 'õÐÌö×¦õÑ-õÏë';
  RC_CURSORINBM                         = 'ö¦âöî¦õÛ-÷ê×õÏãõÅÉöàÇ';
  RC_CURSORTELNET                       = 'DXõÅìõÑÊöÝ¬õÅÉöàÇ';
  RC_QSOWITHNOCW                        = 'ùÝÞCW÷ÚÄQSO';
  RC_CT1BOHIS                           = 'CT1BOHô¬áöÁï÷ê×õÏã';
  RC_ADDBANDMAPPH                       = 'ö¬¬÷-îö¦âöî¦õÛ-';
  RC_COMMANDS                           = 'õÑ-ô¬ä';
  RC_FOCUSINMW                          = 'ô¬¬÷ê×õÏã÷Äæ÷Â¦';
  RC_TOGGLEINSERT                       = 'õÈÇöÍâöÏÒõÅåöèáõ-Ï';
  RC_ESCAPE                             = 'õÏÖö¦È';
  RC_CWSPEEDUP                          = 'CWùÀßõ¦æõÊà';
  RC_CWSPEEDDOWN                        = 'CWùÀßõ¦æõÇÏ';
  RC_CWSPUPIR                           = 'ö+¬ø¬Ã÷Ô¦õÏ-CWùÀßõ¦æõÊà';
  RC_CWSPDNIR                           = 'ö+¬ø¬Ã÷Ô¦õÏ-CWùÀßõ¦æõÇÏ';
  RC_CQMODE                             = 'õÑ-õÏëöèáõ-Ï';
  RC_SEARCHPOUNCE                       = 'öÐÜ÷+âõÒÌ÷êÁõÇ¬öèáõ-Ï';
  RC_SENDSPOT                           = 'õÏÑùÀÁõÅìõÑÊ';
  RC_RESCORE                            = 'ùÇÍöÖ-øîáõÈÆ';
  RC_TOOLS                              = 'õ¬åõÅ¬';
  RC_SYNPCTIME                          = 'õÐÌö×¦øîá÷î×öÜ¦ö×¦ù×+';
  RC_BEACONSM                           = '÷ÁïõáÔ÷ÛÑö¦Ë';
  RC_WINCONTROL                         = '÷ê×õÏãöÎçõÈ¦';
  RC_SETTIMEZONE                        = 'øî-÷-îö×¦õÌ¦';
  RC_PING                               = 'Ping [öÜÍõÊáõÙèõÜ-õÝÀ]';
  RC_RUNSERVER                          = 'ø¬ÐøáÌTR4WöÜÍõÊáõÙè';
  RC_DVPVOLCONTROL                      = 'DVPùß¦ùÇÏöÎçõÈ¦';
  RC_RECCONTROL                         = 'õ-Õùß¦öÎçõÈ¦';
  RC_SOUNDRECORDER                      = 'õ-Õùß¦öÜ¦';
  RC_DISTANCE                           = 'ø¬Ý÷æ¬';
  RC_GRID                               = '÷-Ñöà-';
  RC_CALCULATOR                         = 'øîá÷î×õÙè';
  RC_LC                                 = 'LC';
  RC_RESET_RADIO_PORTS                  = 'Reset Radio Ports';
  RC_NET                                = '÷-Ñ÷¬Ü';
  RC_TIMESYN                            = 'õÐÌöíåöÉÀöÜÉøîá÷î×öÜ¦ö×¦ù×+&a';
  RC_SENDMESSAGE                        = 'õÏÑùÀÁö¦ÈöÁï';
  RC_SYNLOG                             = 'öïÔø-ÃõÒÌõÐÌöíåö×åõ¬×';
  RC_CLEARALLLOGS                       = 'ö¬ÅùÙä÷-Ñ÷¬Üô¬ÊöÉÀöÜÉö×åõ¬×';
  RC_DOWNLOAD                           = 'öãÀößåöÛ+öÖ-';
  RC_CONTENTS                           = '÷Ûîõ-Õ';
  RC_ABOUT                              = 'õÅ¦ô¦Î';
  RC_CONFFILE                           = 'ùÅÍ÷-îöÖÇô¬¦';
  RC_EDITQSO                            = '÷-Öø-ÑQSO';
  RC_DELETED                            = 'õÈàùÙä&D';
  RC_DUPE                               = 'ùÔÙøïï';
  RC_LOGSEARCH                          = 'ö×åõ¬×öÐÜ÷+â';
  RC_SEARCH                             = 'öÐÜ÷+â&S';
  RC_GETOFFSET                          = 'øÎ¬õ-×øáåõÁ¬&G';
  RC_LOCALOFFSET                        = 'øÎ¬õ-×öÜìõÜ-ö×¦ù×+';
  RC_NTPSERVER                          = 'NTPöÜÍõÊáõÙè';
  RC_SERVERANSWER                       = 'öÜÍõÊáõÙèõ¦Ô÷íÔ';
  RC_SYNCLOCK                           = 'õÐÌöíåö×¦ùÒß&S';
  RC_LOCALTIME                          = 'öÜìõÜ-ö×¦ù×+';
  RC_DUPESHEET2                         = 'ùÔÙøïïøáè';
  RC_SENDSPOT2                          = 'õÏÑùÀÁ÷¬Ó÷Â¦';
  RC_CONTESTNAMEIC                      = '÷ëÞø¦ÛõÑ-õÏ¬&o';
  RC_SEND                               = 'õÏÑùÀÁ&S';
  RC_COMMENT                            = 'õäÇö¦è';
  RC_SENDINGCW                          = 'ô¬ÎùÔî÷ÛØõÏÑùÀÁCW.öÌÉENTER/Escape/F10ùÀÀõÇ¦.';
  RC_RETURNTOMOD                        = 'ô¬îöÔ¦';
  RC_ARROWTOSELIT                       = '÷îíõä+/pageup/pagednùÔîöÈÖ÷ììô¬Àô¬êõí×öïÍùÀÉöËéùá¦÷Ûî.';
  RC_ALTW                               = 'ô¬ÝõíØ(Alt-&W)';
  RC_ALTN                               = 'õÈ-÷-Ñ÷¬Ü&n';
  RC_ALTG                               = 'õÈÆùÃèô¬ÝõíØ(Alt-&G)';
  RC_BANDMAP2                           = 'ö¦âöî¦õÛ-';
  RC_AUTOCQ2                            = 'øÇêõÊèõÑ-õÏë';
  RC_PRESSMKYWTR                        = 'öÃ¦ùÇÍõäÍ,öÌÉõíØõÂèùÔî:';
  RC_NUMBEROSOLT                        = 'õîÈõÐìöïë÷çÒöÕ-:';
  RC_DELETESELSPOT                      = 'õÈàùÙäùÀÉöËé÷¬Ó÷Â¦';
  RC_REMOVEALLSP                        = 'õÈàùÙäöÉÀöÜÉ÷¬Ó÷Â¦';
  RC_SENDINRIG                          = 'õÏÑùÀÁø-ÅöÜ¦ùâÑ÷ÎÇ';
  RC_COAX                               = 'õÐÌø-+÷Ô¦÷-ÆùÕ¬õ¦æøîá÷î×õÙè';
  RC_ENTERTNHINIK                       = 'ø-ÓõÅåô¬Àô¬êöÜÀùëØùØ¬öÊ×÷Â¦KHz:';
  RC_ENTERALIFIK                        = 'ø-ÓõÅåô¬Àô¬êöÜÀô-ÎùØ¬öÊ×÷Â¦kHz:';
  RC_DISTANCEBTGS                       = '÷-Ñöà-ù×+ø¬Ý÷æ¬';
  RC_SECONDGRID                         = '÷ììô¦Ìô¬ê÷-Ñöà-';
  RC_FIRSTGRID                          = '÷ììô¬Àô¬ê÷-Ñöà-';
  RC_EURVHFDIST                         = 'öìçö+-VHFø¬Ý÷æ¬:';
  RC_GRIDOFAGLL                         = '÷¬Ï÷¦ìõ¦æ÷-Ñöà-';
  RC_LONGMIE                            = '÷¬Ïõ¦æ (ø+ßöØïô¬Ü)';
  RC_LATMIS                             = '÷¦ìõ¦æ (ø+ßöØïõÍ×)';
  RC_CALCOFCORI                         = '÷Ô¦õî¦/÷Ô¦öÄßøîá÷î×õÙè';
  RC_INDUCANCE                          = '÷Ô¦öÄß, uH';
  RC_CAPACITANCE                        = '÷Ô¦õî¦, pf';
  RC_FREQOFRES                          = 'ø-ÐöÌïùâÑ÷ÎÇ, khz';
  RC_WINCONTROL2                        = '÷ê×õÏãöÎçõÈ¦';
  RC_SHOWMENU                           = 'öØ-÷ä¦øÏÜõÍÕ&S';
  RC_RECVQTC                            = 'öÎåöÔ¦QTCs';
  RC_MIXWINTERFACE                      = 'MixWöÎåõÏã';
  RC_CONNECTTOMIXW                      = 'ø¬ÞöÎåõÈ-MixW';
  RC_MEMPROGFUNC                        = 'õíØõÂè÷èËõ¦ÏõÊßøÃ-';
  RC_PRESS_C                            = 'öÌÉ &C\n õîÚô¦Éô¬Àô¬êCQùÔî.';
  RC_PRESS_E                            = 'öÌÉ &E\n õîÚô¦Éô¬Àô¬êô¦äöÍâ/öÐÜ÷+âõÒÌ÷êÁõÇ¬ùÔî.';
  RC_PRESS_O                            = 'öÌÉ &O\n õîÚô¦Éô¬Àô¬êùÝÞõÊßøÃ-ùÔîö¦ÈöÁï.';
  RC_SYNLOG2                            = 'õÐÌöíåö×åõ¬×';
  RC_GETSERVLOG                         = 'øÎ¬õÏÖöÜÍõÊáõÙèö×åõ¬×&G';
  RC_RECVRECORDS                        = 'öÎåöÔ¦øî-õ-Õ:';
  RC_SENDRECORDS                        = 'õÏÑùÀÁøî-õ-Õ:';
  RC_CREATEAUNL                         = 'õ¬¦÷ëËõ¦¦ô-¬÷ÔèöÖ-ö×åõ¬×&C';
  RC_RECVBYTES                          = 'öÎåöÔ¦õí×øÊÂ:';
  RC_RECVQSOS                           = 'öÎåöÔ¦QSOs:';
  RC_SHOWSERVLOGC                       = 'öØ-÷ä¦öÜÍõÊáõÙèö×åõ¬×õÆÅõî¦';
  RC_VIEWEDITLOG2                       = 'ößå÷ÜË/÷-Öø-Ñö×åõ¬×';
  RC_INTERCOM2                          = 'õÆÅ÷¦¬';
  RC_DIFFINLOG                          = 'õ¬îõ-Âö×åõ¬×';
  RC_ARCFILTER                          = 'ARC÷¬Ó÷Â¦ö¦âöî¦öèáõ-Ïø¬Çö¬äõÙè';
  RC_DXSFILTER                          = 'DXSpider÷¬Ó÷Â¦ö¦âöî¦öèáõ-Ïø¬Çö¬äõÙè';
  RC_CLEARFILTER                        = 'ö¬ÅùÙäø¬Çö¬äõÙè';
  RC_STATIONS2                          = '÷Ô¦õÏ-';
  RC_C_EDITQSO                          = '÷-Öø-ÑQSO';
  RC_C_DELETEQSO                        = 'õÈàùÙäQSO';
  RC_COPYTOCLIP                         = 'øÇêõÈ¦õÈ-õÉêõÈÇöÝ¬';
  RC_DUPECHECKOAR                       = 'ø-ÅõÏ-ùÔÙøïïöãÀößå';
  RC_WINKEYSET                          = 'Winkeyerøî-÷-î';
  RC_CT1BOHIS2                          = 'CT1BOHô¬áöÁï÷ê×õÏã';
  RC_DATE                               = 'ö×åöÜß';
  RC_NUMBERSENT                         = 'õÏÑùÀÁ÷-ÖõÏ¬';
  RC_NUMBERRCVD                         = 'öÎåöÔ¦÷-ÖõÏ¬';
  RC_RSTSENT                            = 'õÏÑùÀÁRST';
  RC_RSTRECEIVED                        = 'öÎåöÔ¦RST';
  RC_QSOPOINTS                          = 'QSOõÈÆöÕ-';
  RC_AGE                                = 'õ¦+ù-Ä';
  RC_FREQUENCYHZ                        = 'ùâÑ÷ÎÇ,Hz';
  RC_PREFIX                             = 'õí×õä+';
  RC_ZONE                               = 'õÈÆõÌ¦';
  RC_NAME                               = 'õçÓõÐÍ';
  RC_POSTALCODE                         = 'ùÂî÷-Ö';
  RC_POWER                              = 'õÊß÷ÎÇ';
  RC_PROGRMESS                          = '÷èËõ¦Ïô¬áöÁï';
  RC_MESSAGE                            = 'ö¦ÈöÁï';
  RC_CAPTION                            = 'öàÇùâØ';
  RC_IAQSLINT                           = 'øÇêõÊè÷áîøîäù×+ùÚÔ (õâÞõÊà)';
  RC_DAQSLINT                           = 'øÇêõÊè÷áîøîäù×+ùÚÔ (õÇÏõ-Ñ)';
  RC_ADDINFO                            = 'õÅ¦ô¬Öô¬áöÁï';
  RC_AI_QSONUMBER                       = 'QSO÷-ÖõÏ¬';
  RC_AI_CALLSIGN                        = 'õÑ-õÏ¬';
  RC_AI_CWSPEED                         = 'CWùÀßõ¦æ';
  RC_AI_BAND                            = 'ö¦âöî¦';
  RC_CLEARMSHEET                        = 'ö¬ÅùÙä÷¦¬öÕ-øáè';
  RC_WIKI                               = 'õÜè÷¦¬öÖÇöáã(ô¬ÄöÖÇ)';
  RC_NET_CLDUPE                         = 'ö¬ÅùÙäöÉÀöÜÉö×åõ¬×ùÔÙøïïøáè';
  RC_NET_CLMULT                         = 'ö¬ÅùÙäöÉÀöÜÉö×åõ¬×÷¦¬öÕ-øáè';
  RC_INC_TIME                           = 'õâÞùÇÏö×¦ù×+';
  RC_NOTES                              = 'õäÇö¦è';
  RC_DEFAULT                            = 'ù¬Øøîä:';
  RC_DESCRIPTION                        = 'øï+öØÎ:';
  RC_DEVICEMANAGER                      = 'øî-õäÇ÷îá÷ÐÆõÙè';
  RC_SHDX_CALLSIGN                      = 'SH/DX [õÑ-õÏ¬]';
  RC_STATIONINFO                        = '÷Ô¦õÏ-ô¬áöÁï';
  RC_MP3_RECENABLE                      = 'õÐï÷Ôè';
  RC_PLAY                               = 'öÒíöÔ-&P';
  RC_LISTOFMESS                         = 'ö¦ÈöÁïõÈ×øáè';
  RC_LOGIN                              = '÷Ù¬õ-Õ';
  RC_SYNCHRONIZE                        = 'õÐÌöíå';
  RC_GET_OFFSET                         = 'øÎ¬õ-×øáåõÁ¬';
  RC_COLORS                             = 'ùâÜøÉ-';
  RC_APPEARANCE                         = 'õäÖøçÂ';
  RC_BANDPLAN                           = 'ö¦âöî¦øîáõÈÒ';
  RC_WA7BNM_CALENDAR                    = 'WA7BNM÷ëÞø¦Ûö×åõÎÆ';
  RC_SEND_BUG                           = 'õÏÑùÀÁùÔÙøïïöÊåõÑÊ';
  RC_HOMEPAGE                           = 'TR4WùæÖùá¦';
  RC_FREQUENCY                          = 'Frequency';
  TC_SPLIT_WARN                       = 'Warning: You are in SPLIT MODE !!!';
{FD Additions NY4I}

TC_IMPROPERTRANSMITTERCOUNT = 'FD transmitters must be between 1 and 99.';
TC_IMPROPERARRLFIELDDAYCLASS = 'Field Day class must be A, B, C, D, E or F.';
TC_IMPROPERWINTERFIELDDAYCLASS = 'Winter Field Day class must be H, I, O or M.';
TC_ARRLFIELDDAYIMPROPERDXEXCHANGE = 'DX Station exchange must be "DX".';

RC_SPLITOFF                       = 'Set Split Mode Tx';
TC_RUNWARN                    = 'Another instance of TR4W is already running';
RC_wkMode                     = 'Re-initialize WinKeyer';      // 4.60.1

  TC_SHOW_PASSWORDS                     = 'Show passwords';

TC_TOOLTIP_DISCOVERY = 'Discover radios on the network';
TC_DISCOVER_NOT_AVAILABLE = 'Network discovery is not available for radio %s';
TC_DISCOVER_NONE_FOUND = 'No radio of type %s found on the network';
TC_DISCOVER_MULTI_FOUND = 'More than one %s found; filled in the first.  All found:';
