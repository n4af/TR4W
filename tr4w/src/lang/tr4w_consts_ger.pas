
  { %s =	Ein String.}
  { %c =	Ein einzelnes zeichen.}
  { %d =	Ein dezimales Integer Argument mit Vorzeichen.}
  { %u =	Ein vorzeichenloses Integer Argument.}
 const
  TC_TRANSLATION_LANGUAGE               = 'GERMAN';
  TC_TRANSLATION_AUTHOR                 = 'DL4BBH';
  TC_TRANSLATOR_EMAIL                   = 'dl4bbh@darc.de';
  TC_WAGWarn                            = 'Warnung: Ausserhalb des erlaubten WAG Frequenzbereichs';
  TC_FREQ                               = 'Freq';
  TC_POINTS                             = 'Pkt';
  TC_OP                                 = 'Op';
  TC_INVALID                            = 'Ungueltiger Eintrag';
  TC_FREQ_ZERO                          = 'ERROR: Ungueltige Frequenz geloggt';
  TC_FREQ_OFF                           = 'Frequenzanzeige im LOG ist ausgeschaltet';
  TC_CHECKCALLSIGN                      = 'Rufzeichen pruefen';
  TC_2RADIO_WARN                        = 'ERROR: 2 Radios auf dem selben Band';
  TC_FREQUENCYFORCALLINKHZ              = 'Frequenz fuer %s in kHz';
  TC_DIFVERSION                         = '%s ist aus einer anderen Programmversion.'#13'TR4W erwartet Version %s.'#13'Deine Datei ist die Version %s.';
//  TC_FILE                               = 'File';

  TC_M                                  = 'm'; //minute
  TC_S                                  = 's'; //second

  TC_RADIO1                             = 'Radio 1';
  TC_RADIO2                             = 'Radio 2';

  TC_DISBALE_CIV                        = 'Disable "CI-V Transceive" Mode in deiner ICOM Rig. Im Benutzerhandbuch zu deinem Transceiver nachsehen.';

  {MAIN}
  TC_YOU_ARE_USING_THE_LATEST_VERSION   = 'Du benutzt die aktuellste Version';
  TC_SET_VALUE_OF_SET_NOW               = 'Wert setzen auf %s. Jetzt setzen?';
  TC_CONFIGURATION_FILE                 = 'Konfigurationsdatei';
  TC_CURRENT_OPERATOR_CALLSIGN          = 'Callsign des aktuellen Operators';
  TC_APPENDIMPORTEDQSOSTOCURRENTLOG     = 'Importierte QSOs an das aktuelle Log anhaengen?';
  TC_QSO_IMPORTED                       = 'QSOs importiert.'; // - '345 Qs imported.'
  TC_ISADUPE                            = '%s ist ein Dupe!!';
  TC_ERRORINLOGFILE                     = 'Fehler in der Logdatei!';
  TC_HASIMPROPERSYNTAX                  = '%s hat unzulaessige Syntax!!';
  TC_SORRYNOLOG                         = 'Sorry!! NO LOG = TRUE heisst, dass keine QSOs geloggt werden koennen';
  TC_SETCOMPUTERIDVALUE                 = 'COMPUTER ID setzen.';

  TC_WANTTOCONVERTLOG                   = 'Soll dieses Log in das aktuelle Format konvertiert werden?';
  TC_LOGFILENOTFOUND                    = 'Logdatei nicht gefunden';
  TC_CANNOTBACKUPLOG                    = 'Kann kein Backup machen von ';
  TC_CANNOTCOPYLOGREADONLY              = 'Kann die Logdatei nicht kopieren -- Zieldatei existiert und ist read-only';
  TC_BACKUPCREATED                      = 'Backup des Logs angelegt';
  TC_CANNOTRENAME                       = 'Kann nicht umbenennen';
  
  TC_CLEARALLLOGS                       = '"CLEARALLLOGS" zum Bereinigen aller Logs im Netzwerk';
  TC_CLEAR_DUPESHEET_NET                = '"CLEARDUPESHEET" zum Bereinigen aller Dupesheets im Netzwerk';
  TC_CLEAR_MULTSHEET_NET                = '"CLEARMULTSHEET" zum Bereinigen aller Multsheets im Netzwerk';

  TC_REALLYWANTTOCLEARTHELOG            = 'Willst du wirklich das aktuelle Log bereinigen?';
  TC_MESSAGETOSENDVIANETWORK            = 'Message zum Versand im Netzwerk';
  TC_SENDTIMETOCOMPUTERSONTHENETWORK    = 'Willst du wirklich allen Computern im Netzwerk die Uhrzeit senden?';
  TC_RULESONSM3CER                      = 'Regeln fuer %s Contest auf WA7BNM Contest Calendar';
  TC_RULESONQRZRU                       = 'Regeln fuer %s Contest auf QRZ.RU';
  TC_NOTE                               = 'beachten';
  TC_DUPESHEETCLEARED                   = 'Dupe Sheet bereinigt!';
  TC_MULTSHEETCLEARED                   = 'Mult Sheet bereinigt!';
  TC_YESTOCLEARTHEDUPESHEET             = '"YES" um das Dupesheet zu bereinigen';
  TC_CLEARMULTTOCLEARMULTSHEET          = '"CLEARMULT" um das Multsheet zu bereinigen';

  TC_TRANSMITFREQUENCYKILOHERTZ         = 'Sendefrequenz (KiloHertz): ';
  TC_SPRINTQSYRULE                      = 'SPRINT QSY RULE!!!';
  TC_PADDLE                             = 'Paddle';
  TC_FOOTSW                             = 'Footsw.';
//  TC_LOG_NOTE                           = 'NOTE';
//  TC_LOG_DELETED                        = 'DELETED';

  TC_SUN                                = 'Son';
  TC_MON                                = 'Mon';
  TC_TUE                                = 'Die';
  TC_WED                                = 'Mit';
  TC_THU                                = 'Don';
  TC_FRI                                = 'Fre';
  TC_SAT                                = 'Sam';

  {uMP3Recorder}

  TC_LAME_ERROR                         = 'Du kannst es downloaden von';

  {This version TR4W v.4.009 beta was build in 2 December 2008. Do you want to check the latest version ?}
  TC_THISVERSION                        = 'Du hast ';
  TC_WASBUILDIN                         = 'installiert (build date ';
  TC_DOYOUWANTTOCHECKTHELATESTVERSION   = 'Willst du pruefen, ob es eine neuere Version von TR4W gibt?';

  {NEW CONTEST}
  TC_EUDX                               = 'EU country, enter your four character country code';
  TC_IRTS                               = 'EI/GI, dein County eingeben';
  TC_LATEST_CONFIG_FILE                 = 'Neueste Config Datei';
  TC_OPENCONFIGURATIONFILE              = ' - Konfigurationsdatei oeffnen oder neuen Contest starten';
  TC_FOLDERALREADYEXISTSOVERWRITE       = 'Ordner "%s" existiert schon.'#13'ueberschreiben ?';
  TC_IAMIN                              = '&Ich bin in %s';
  TC_NEWENGLANDSTATEABREVIATION         = 'Gib die Abkuerzung fuer deinen New England Staat ein'#13'(ME, NH, VT, MA, CT, RI):';
  TC_ENTERTHEQTHTHATYOUWANTTOSEND       = 'Gib das QTH ein, dass du senden willst:';
  TC_ENTERSTATEFORUSPROVINCEFORCANADA   = 'Staat fuer die U.S., Provinz fuer Canada ein:';
  TC_ENTERYOUROBLASTID                  = 'Oblast ID eingeben:';
  TC_ENTERYOURPROVINCEID                = 'Provinz ID eingeben:';
  TC_ENTERYOURCOUNTYCODE                = 'County Code eingeben:';
  TC_ENTERYOURDOK                       = 'DOK eingeben:';
  TC_ENTERYOURDISTRICTABBREVIATION      = 'Abkuerzung fuer den Distrikt eingeben:';
  TC_ENTERYOURFOCNUMBER                 = 'Gib deine FOC Nummer ein:';
  TC_ENTERYOURRDAID                     = 'Gib deine RDA ID ein:';
  TC_ENTERYOURIOTAREFERENCEDESIGNATOR   = 'Gib deine IOTA-Referenz ein (Beispiel im Format  EU-123)';
  TC_ENTERYOURCITYIDENTIFIER            = 'Gib den Bezeichner fuer deinen Ort ein:';
  TC_ENTERYOURNAME                      = 'Gib deinen Namen ein:';
  TC_ENTERTHELASTTWODIGITSOFTHEYEAR     = 'Gib die letzten beiden Zahlen des Jahres ein, in dem du deine Lizenz erhalten hast:';
  TC_ENTERYOURZONE                      = 'Gib deine Zone ein:';
  TC_ENTERYOURGEOGRAPHICALCOORDINATES   = 'Gib deine geografischen Koordinaten ein'#13'(z. B. 55N37O fuer Moskau):';
  TC_ENTERSUMOFYOURAGEANDAMOUNT         = 'Gib die Summe aus deinem Alter und den Zeitraum deines ersten QSO ein(z. B. 28+14=42):';
  TC_OZCR                               = 'Dreistellige Ziffern eingeben:';
  TC_ENTERYOURSTATECODE                 = 'Gib die Abkuerzung fuer deinen Staat ein:';
  TC_ENTERYOURFOURDIGITGRIDSQUARE       = 'Gib deinen Grid Locator 4-stellig ein:';
  TC_RFAS                               = 'Gib deine geografischen Koordinaten ein:';
  TC_ENTERYOURSIXDIGITGRIDSQUARE        = 'Gib deinen Grid Locator 6-stellig ein:';
  TC_ENTERYOURNAMEANDSTATE              = 'Gib deinen Namen (und Staat ein, wenn du in Nordamerika bist):';
  TC_ENTERYOURNAMEANDQTH                = 'Gib deinen Namen und QTH (Staat, kanadische Provinz oder DX Country) oder Mitgliedsnummer ein:';
  TC_ENTERYOURPRECEDENCECHECKSECTION    = 'Gib deine Lizenzklasse, deine Pruefung'#13'(die beiden letzten Zahlen deines Pruefungsjahrs) und ARRL Sektion ein:';
  TC_ENTERYOURQTHANDTHENAME             = 'Gib dein QTH ein, das du senden willst'#13'und den Namen:';
  TC_ENTERFIRSTTWODIGITSOFYOURQTH       = 'Gib die ersten beiden Stellen deines QTH ein:';
  TC_ENTERYOURAGEINMYSTATEFIELD         = 'Gib dein Alter in das  MY STATE Feld ein:';
  TC_ENTERYOURQTHORPOWER                = 'Gib dein QTH ein, das du senden willst, wenn du in Nordamerika bist oder deine Ausgangsleistung in MY STATE, wenn du ausserhalb bist:';
  TC_ENTERFIRSTTWOLETTERSOFYOURGRID     = 'Gib die ersten zwei Buchstaben deines Grid Locators ein:';
  TC_ENTERYOURSQUAREID                  = 'Gib deine  Square ID ein:';
  TC_ENTERYOURMEMBERSHIPNUMBER          = 'Gib deine Mitgliedsnummer ein:';
  TC_ENTERYOURCONTINENT                 = 'Gib deinen Kontinent ein (und moegliche weitere ID,z.B. SA oder NAQ)';
  TC_ENTERYOURCOUNTYORSTATEPOROVINCEDX  = 'Gib dein County ein, wenn du im Staat %s bist. Gib deinen Staat, kanadische Provinz oder "DX", wenn du ausserhalb von %s bist:';
  TC_PREFECTURE                         = 'Gib deine Praefektur ein:';
  TC_STATIONCLASS                       = 'Gib deine Lizenzklasse ein:';
  TC_AGECALLSIGNAGE                     = 'Gib dein Alter (und Silent Key Callsign und Alter) ein:';
  TC_DEPARTMENT                         = 'Gib dein Department ein:';
  TC_ENTERYOURRDAIDORGRID               = 'Gib deine RDA ID ein (fuer UA1A Stationen) oder den viersellien Grid Locator:';
  TC_ENTERYOURBRANCHNUMBER              = 'Gib deine Branch Nummer ein:';
  TC_ENTERYOURPOSTCODE                  = 'Gib deine Postleitzahl ein :';
  TC_ENTERYOURDISTRICTCODE              = 'Bist du in UK/EI, gib deinen zweistelligen Distrikt Code ein';
  TC_ISLANDSTATION                      = 'Insel Station';
  TC_NEWENGLAND                         = 'Neu England';
  TC_CALIFORNIA                         = 'Kalifornien';
  TC_FLORIDA                            = 'Florida';
  TC_MICHIGAN                           = 'Michigan';
  TC_MINNESOTA                          = 'Minnesota';
  TC_OHIO                               = 'Ohio';
  TC_WASHINGTON                         = 'Washington';
  TC_WISCONSIN                          = 'Wisconsin';
  TC_TEXAS                              = 'Texas';
  TC_NORTHAMERICA                       = 'Nord Amerika';
  TC_RUSSIA                             = 'Russland';
  TC_UKRAINE                            = 'Ukraine';
  TC_CZECHREPUBLICORINSLOVAKIA          = 'Tschechische Republik oder in der Slovakei';
  TC_BULGARIA                           = 'Bulgarien';
  TC_ROMANIA                            = 'Rumaenien';
  TC_HUNGARY                            = 'Ungarn';
  TC_YUGOSLAVIA                         = 'Jugoslawien';
  TC_UKEI                               = 'Bist du in UK/EI, gib deinen zweistelligen Distrikt Code ein';
  TC_BELGIUM                            = 'Belgien';
  TC_NETHERLANDS                        = 'Niederlande';
  TC_STPETERSBURGOBLAST                 = 'St.Petersburg / Oblast';
  TC_GERMANY                            = 'Deutschland';
  TC_UK                                 = 'UK';
  TC_ARKTIKACLUB                        = 'Club';
  TC_POLAND                             = 'Polen';
  TC_KAZAKHSTAN                         = 'Kazakhstan';
  TC_ITALY                              = 'Italien';
  TC_SWITZERLAND                        = 'Schweiz';
  TC_HQ                                 = 'HQ (HQ Station)';
  TC_CIS                                = 'CIS';
  TC_SPAIN                              = 'Spanien';
  TC_JAPAN                              = 'Japan';
  TC_CANADA                             = 'Kanada';
  TC_FRANCE                             = 'Frankreich';
  TC_HQ_OR_MEMBER                       = 'HQ oder Mitglied';
  TC_IRELAND                            = 'Irland';

  {UTELNET}

  TC_TELNET                             = 'Connect'#0'Disconnect'#0'Commands'#0'Freeze'#0'Clear'#0'100'#0#0;
  TC_YOURNOTCONNECTEDTOTHEINTERNET      = 'DU BIST NICHT MIT DEM INTERNET VERBUNDEN!';
  TC_GETHOST                            = 'GET HOST..';
  TC_SERVER                             = 'SERVER: %s';
  TC_HOST                               = 'HOST  : %s';
  TC_CONNECT                            = 'CONNECT..';
  TC_CONNECTED                          = 'CONNECTED';
  TC_YOUARESPOTTEDBYANOTHERSTATION      = 'Du bist von einer anderen Station gespottet worden.';

  {UNET}

  TC_CONNECTIONTOTR4WSERVERLOST         = 'Verbindung zum TR4WSERVER %s:%d verloren.';
  TC_COMPUTERCLOCKISSYNCHRONIZED        = 'Computeruhr ist synchronisiert.';
  TC_CONNECTINGTO                       = 'Verbinde mit ';
  TC_CONNECTTOTR4WSERVERFAILED          = 'Verbindung zum TR4WSERVER fehlgeschlagen. Check SERVER PASSWORD!!';
  TC_CONNECTEDTO                        = 'Verbunden mit ';
  TC_FAILEDTOCONNECTTO                  = 'Kann nicht verbinden mit ';
  TC_SERVERANDLOCALLOGSAREIDENTICAL     = 'Serverlog und lokale Logs sind identisch.';
  TC_NETWORK                            = 'Network : %s %s:%d';
  TC_SERVER_LOG_CHANGED                 = 'Server Log geaendert. %u QSO(s) aktualisiert. Synchronisiere Logs mit  (Ctrl+Alt+S).';
  TC_ALL_LOGS_NETWORK_CLEARED           = 'Alle Logs im TR4W Netzwek bereinigt.';

  {UGETSCORES}

  TC_FAILEDTOCONNECTTOGETSCORESORG      = 'Verbindung fehlgeschlagen';
  TC_NOANSWERFROMSERVER                 = 'Keine Antwort vom Server';
  TC_UPLOADEDSUCCESSFULLY               = 'Upload erfolgreich.';
  TC_FAILEDTOLOAD                       = 'Upload fehlgeschlagen. Sieh getscoresanswer.html fuer Details.';

  {UBANDMAP}

  TC_SOURCE                             = 'Source: %s';
  TC_MIN                                = '%u Min.';

  {LOGWIND}

  TC_CQTOTAL                            = 'CQ total: %u';
  TC_REPEATING                          = 'Wiederhole %s  Empfangszeit = %u msec - PgUp/Dn zum Anpassen oder ESCAPE';
  TC_NEWTOUR                            = 'Neue Tour %d/%d';
  TC_ENTER                              = 'Enter %s :';
  TC_PTS                                = '%d Pkt';
  TC_RATE                               = 'Rate = %u';
  TC_LAST60                             = 'Letzte 60 = %d';
  TC_THISHR                             = 'Diese Std. = %d';
  TC_BAND_CHANGES                       = 'Bn. ch. = %d';

  TC_HAVEQTCS                           = 'Habe %u QTCs';
  TC_INSERT                             = 'INSERT';
  TC_OVERRIDE                           = 'OVERRIDE';
  TC_UNKNOWNCOUNTRY                     = 'Unbekanntes Land';

  {UCALLSIGNS}

  TC_DUPESHEET                          = 'Dupesheet - %sm-%s';

  {LOGEDIT}

  TC_QSONEEDSFOR                        = ' QSO noetig fuer %s :';
  TC_MULTNEEDSFOR                       = ' Multi noetig fuer %s :';
  TC_MISSINGMULTSREPORT                 = 'Multi Report fehlt: %u Laender von %u, aber nicht alle Baender.';

  {LOGDUPE}

  TC_THEREWERECALLS                     = 'Es wurden %u Calls in der urspruenglichen Austauschdatei gefunden.'#13'+%u Dupe(s)';
  TC_RESTARTBINISFORADIFFERENTCONTEST   = 'RESTART.BIN ist fuer einen anderen Contest.';

  {LOGSTUFF}

  TC_NOTENOUGHINFOINEXCHANGE            = 'Nicht genuegend Infos fuer den Austausch!!';
  TC_IMPROPERDOMESITCQTH                = 'Unzulaessiges inlaendisches QTH!!';
  TC_IMPROPERDOMESITCQTHORMISSINGNAME   = 'Unzulaessiges inlaendisches QTH oder fehlederNae!!';
  TC_MISSINGQTHANDORNAME                = 'QTH und/oder Name fehlt!!';
  TC_NOQSONUMBERFOUND                   = 'Keine QSO Nummer gefunden!!';
  TC_IMPROPERZONENUMBER                 = 'Unzulaessige Zonennummer!!';
  TC_IMPROPERCONTINENT                  = 'Falscher Kontinent!!';
  TC_SAVINGTO                           = 'Speichere %s nach %s';
  TC_FILESAVEDTOFILESUCCESSFULLY        = 'Datei erfolgreich gespeichert.';
  TC_FILESAVEDTOSUCCESSFULLY            = 'Datei erfolgreich nach %s gespeichert.';


  {LOGSEND}

  TC_WAITINGFORYOUENTERSTRENGTHOFRST    = 'Warte fauf die Eingabe des RST (Einzelne Ziffer)!!';

  {COUNTRY9}

  TC_C9_NORTHAMERICA                    = 'Nordamerika';
  TC_C9_SOUTHAMERICA                    = 'Suedamerika';
  TC_C9_EUROPE                          = 'Europa';
  TC_C9_AFRICA                          = 'Afrika';
  TC_C9_OCEANIA                         = 'Ozeanien';
  TC_C9_ANTARTICA                       = 'Antarktis';
  TC_C9_ASIA                            = 'Asien';
  TC_C9_UNKNOWN                         = 'Unbekannt';

  {USTATIONS}

  TC_STATIONSINMODE                     = 'Stationen im %s Mode';

  {USPOTS}

  TC_SPOTS                              = '%d Spots';

  {uSendKeyboard}

  TC_SENDINGSSBWAVFILENAME              = 'Sende SSB .wav filename. ENTER druecken zum Abspielen, Escape/F10 fuer Abbruch.';

  {QTC}

  TC_WASMESSAGENUMBERCONFIRMED          = 'Wurde die Messagenummer %u bestaetigt?';
  TC_DOYOUREALLYWANTSTOPNOW             = 'Wilst du jetzt wirklich stopen?';
  TC_QTCABORTEDBYOPERATOR               = 'QTC durch Operator abgebrochen.';
  TC_DOYOUREALLYWANTTOABORTTHISQTC      = 'Willst du dieses QTC wirklich abbrechen?';
  TC_NEXT                               = '< Naechste';
  TC_QTC_FOR                            = '%s fuer %s';
  TC_QTC_CALLSIGN                       = 'Callsign :';
  TC_ENTERQTCMAXOF                      = 'QTC eingeben #/# (max von %d) :';
  TC_DOYOUREALLYWANTTOSAVETHISQTC       = 'Willst du dieses QTC wirklich speichern?';
  TC_EDITQTCPRESSYESTOEDITQTCORNOTOLOG  = 'QTC bearbeiten? Yes zum QTC bearbeiten druecken oder  No zum Speichern ';
  TC_CHECKQTCNUMBER                     = 'Pruefe QTC Nummer';
  TC_CHECKTIME                          = 'Pruefe Zeit';

  {UOPTION}

  TC_COMMAND                            = 'Kommando';
  TC_VALUE                              = 'Wert';
  TC_INFO                               = 'Info';
  TC_YOUCANCHANGETHISINYOURCONFIGFILE   = 'Du kannst nur dies in deiner Konfigurationsdatei aendern.';

  {UEDITQSO}

  TC_CHECKDATETIME                      = 'Pruefe Datum/Zeit !!';
  TC_SAVECHANGES                        = 'Aenderungen speichern?';

  {LOGCW}

  TC_WPMCODESPEED                       = 'WPM Code Speed';
  TC_CQFUNCTIONKEYMEMORYSTATUS          = 'CQ FUNKTIONSTASTE MEMORY STATUS';
  TC_EXCHANGEFUNCTIONKEYMEMORYSTATUS    = 'TAUSCHE FUNKTIONSTASTEN MEMORY STATUS';
  TC_OTHERCWMESSAGEMEMORYSTATUS         = 'Anderer CW Message Memory Status';
  TC_OTHERSSBMESSAGEMEMORYSTATUS        = 'Anderer SSB Message Memory Status';
  TC_PRESSCQFUNCTIONKEYTOPROGRAM        = 'Zum Programmieren von CQ Funktionstaste druecken (F1, AltF1, CtrlF1), oder ESCAPE zum Verlassen) : ';
  TC_PRESSEXFUNCTIONKEYTOPROGRAM        = 'Ex Funktionstaste zur Programmierung druecken (F3-F12, Alt/Ctrl F1-F12) oder ESCAPE zum Verlassen:';
  TC_NUMBERORLETTEROFMESSAGETOBEPROGRAM = 'Zahl oder Buchstabe der zu programmierenden Message eingeben (1-9, A-C, oder ESCAPE zum Verlassen):';
  TC_CWDISABLEDWITHALTK                 = 'CW ist mit Alt-K! deaktiviert! Erneut Alt-K druecken um zu aktivieren.';
  TC_VOICEKEYERDISABLEDWITHALTK         = 'Der Voice Keyer wurde mit Alt-K deaktiviert!! Erneut Alt-K druecken um zu aktivieren.';

  {LOGCFG}

  TC_NOCALLSIGNSPECIFIED                = 'Kein Callsign angegeben!!';
  TC_NOFLOPPYFILESAVENAMESPECIFIED      = 'Kein Dateiname fuer die Speicherung auf der Floppy angegeben.';
  TC_UNABLETOFIND                       = 'Kann %s nicht finden.';
  TC_INVALIDSTATEMENTIN                 = 'Ungueltige Angabe in %s !!'#13#13'Zeile %u'#13'%s';
  TC_UNABLETOFINDCTYDAT                 = 'Kann die Datei CTY.DAT nicht finden!!'#13'Stell sicher, dass diese Datei im selben Verzeichnis wie das Programm ist.';
  TC_INVALIDSTATEMENTINCONFIGFILE       = '%s:'#13'Ungueltiger Eintrag in der Konfiguratiosdatei.'#13#13'Zeile %u'#13'%s';

  {LOGSUBS1}

  TC_RECORDDVPPRESSESCAPEORRETURNTOSTOP = 'Nehme DVP auf . ESCAPE oder RETURN zum Stoppen druecken.';
  TC_ALTRCOMMANDDISABLED                = 'Alt-R Kommando durch Radio Mode = True deaktiviert';
  TC_NOCQMESPROGRAMMEDINTOCQMEMORYALTF1 = 'Es ist keine CQ Message in Memory AltF1 eingetragen.';
  TC_THIS_FILE_DOES_NOT_EXIST           = 'Diese Datei existiert nicht. Eine leere Datei zum Bearbeiten anlegen?';

  {LOGSUBS2}

//  TC_WASADUPE                           = '%s was a dupe.';
  TC_ALTDCOMMANDDISABLED                = 'Alt-D ist deaktiviert durch SINGLE RADIO MODE = TRUE';
  TC_YOUHAVERESTOREDTHELASTDELETED      = 'Du hast den zuletzt geloeschten Eintrag wiederhergestellt!!';
  TC_YOUHAVEDELETEDTHELASTLOGENTRY      = 'Du hast den letzten Logeintrag geloescht!! Mit Alt-Y wiederherstellen.';
  TC_DOYOUREALLYWANTTOEXITTHEPROGRAM    = 'Willst du das Programm wirklich beenden?';
  TC_YOUARENOWTALKINGTOYOURPACKETPORT   = 'Du sprichst jetzt auf dem Packet Port. Mit Control-B beenden.';
  TC_YOUALREADYWORKEDIN                 = 'Du hast %s schon in/auf %s gearbeitet!!';
  TC_ISADUPEANDWILLBELOGGEDWITHZERO     = '%s ist ein Dupe und wird mit null QSO Punkten geloggt.';
  TC_LOGFILESIZECHECKFAILED             = 'Check der Dateigroesse des Logs fehlgeschlagen!!!!';

  {JCTRL2}
  TC_NEWVALUE                           = 'Neuer Wert';

  {TREE}

  TC_ALREADYEXISTSOKAYTODELETE          = '%s existiert bereits.'#13#13'Okay zum Loeschen?';

  {UWINKEY}

  TC_WINKEYERENABLE                     = '&Winkeyer ein';
  TC_AUTOSPACE                          = '&Autospace';
  TC_CTSPACING                          = 'C&T spacing';
  TC_SIDETONE                           = '&Sidetone';
  TC_PADDLESWAP                         = 'Paddle swa&p';
  TC_IGNORESPEEDPOT                     = '&Ignoriere Speed Pot';
  TC_PADDLEONLYSIDETONE                 = 'Paddle &only sidetone';

  TC_WINKEYERPORT                       = 'Winkeyer Port';
  TC_KEYERMODE                          = 'Keyer Mode';
  TC_SIDETONEFREQ                       = 'Sidetone Freq.';
  TC_HANGTIME                           = 'Hang time';

  TC_IAMBICB                            = 'Iambic B';
  TC_IAMBICA                            = 'Iambic A';
  TC_ULTIMATIC                          = 'Ultimatic';
  TC_BUGMODE                            = 'Bug mode';

  TC_WEIGHTING                          = 'Weighting';
  TC_DITDAHRATIO                        = 'Dit/Dah Ratio';
  TC_LEADIN                             = 'Lead-in time (*10 ms)';
  TC_TAIL                               = 'Tail time (*10 ms)';
  TC_FIRSTEXTENSION                     = 'Erste Ergaenzung';
  TC_KEYCOMP                            = 'Keyer Compensation';
  TC_PADDLESWITCHPOINT                  = 'Paddle Switchpoint';

  {UTOTAL}

  TC_QTCPENDING                         = 'QTC Pending';
  TC_ZONE                               = 'Zonen';
  TC_PREFIX                             = 'Prefixe';
  TC_DXMULTS                            = 'DX Mults';
  TC_OBLASTS                            = 'Oblasts';
  TC_HQMULTS                            = 'HQ Mults';
  TC_DOMMULTS                           = 'Dom Mults';
  TC_QSOS                               = 'QSOs';
  TC_CWQSOS                             = 'CW QSOs';
  TC_SSBQSOS                            = 'SSB QSOs';
  TC_DIGQSOS                            = 'DIG QSOs';

  {UALTD}

  TC_ENTERCALLTOBECHECKEDON             = 'Call eingeben zur Ueberpruefung auf %s%s:';

  {LOGGRID}

  TC_ALLSUN                             = 'Alles hell';
  TC_ALLDARK                            = 'Alles dunkel';

  {UMIXW}

  TC_MIXW_CONNECTED                     = 'Connected';
  TC_MIXW_DISCONNECTED                  = 'Disconnected';

  {LOGWAE}

  TC_INVALIDCALLSIGNINCALLWINDOW        = 'Ungueltiges Rufzeichen im Call Fenster!!';
  TC_SORRYYOUALREADYHAVE10QTCSWITH      = 'Sorry, du hast schon 10 QTCs mit %s';
  TC_NOQTCSPENDINGQRU                   = 'Keine offenen QTCs, QRU.';
  TC_ISQRVFOR                           = 'Ist %s QRV fuer %s?';

  {UREMMULTS}

  TC_CLEANSWEEPCONGRATULATIONS          = 'CLEAN SWEEP!! GRATULATION!!';

  {CFGCMD}

  TC_NETWORKTEST                        = 'Netzwerktest';
  TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED   = 'Maximale Zahl von Erinnerungen erreicht!!';
  TC_INVALIDREMINDERTIME                = 'Ungueltige Zeitangabe fuer Erinnerung!!';
  TC_INVALIDREMINDERDATE                = 'Ungueltiges Datum fuer Erinnerung!!';
  TC_TOOMANYTOTALSCOREMESSAGES          = 'Zu viele TOTAL SCORE MESSAGEs!!';
  TC_THEFIRSTCOMMANDINCONFIGFILEMUSTBE  = 'Der erste Eintrag im Config File muss das MY CALL Statement sein!!';

  {USYNTIME}
  TC_MS                                 = ' ms'; //milliseconds

  {ULOGSEARCH}
  TC_ENTRIESPERMS                       = '%u Eingaben per %u ms';

  {ULOGCOMPARE}
  TC_SIZEBYTES                          = 'Size, bytes';
  TC_RECORDS                            = 'Records';
  TC_MODIFIED                           = 'Bearbeitet';
  TC_TIMEDIFF                           = 'Zeitdiff.';

  {POSTUNIT}
  TC_MORETHAN50DIFFERENTHOURSINTHISLOG  = 'Mehr als 50 unterschiedliche Stunden in diesaem Log!!';
  TC_TOOMANYCONTESTDATES                = 'Zu viele Contest Dates!!';

  {UGETSERVERLOG}
  TC_FAILEDTORECEIVESERVERLOG           = 'Empfang des Server Logs fehlgeschlagen.';

  {DLPORTIO}
  TC_DLPORTIODRIVERISNOTINSTALLED       = 'DLPortIO error';

  {UCT1BOH}
  TC_TIMEON                             = 'Time on';

  {ULOGCOMPARE}
  TC_SERVERLOG                          = 'SERVER LOG';
  TC_LOCALLOG                           = 'LOkALES LOG';

  {UEDITMESSAGE}

  TC_CTRL_A                             = 'Sende diese Message an inaktive Station';
  TC_CTRL_B                             = 'Erkenne ctrl-A message als ein CQ';
  TC_CTRL_C                             = 'Starte Sezialkommndo';
  TC_CTRL_D                             = 'Nicht unterbrechen';
  TC_CTRL_E                             = 'Dah 73% der normalen Dauer';
  TC_CTRL_F                             = 'Geschwindigkeit erhoehen um 6%';
  TC_CTRL_K                             = 'Normales dah';
  TC_CTRL_L                             = 'Dit 140% der normalen Dauer';
  TC_CTRL_N                             = 'Dah 113% der normalen Dauer';
  TC_CTRL_O                             = 'Dah 127% der normalen Dauer';
  TC_CTRL_P                             = 'Dit 60% der normalen Dauer';
  TC_CTRL_Q                             = 'Dit 80% der normalen Dauer';
  TC_CTRL_S                             = 'Reduziere Geschwindigkeit um 6%';
  TC_CTRL_V                             = 'Dit 120% der normalen Dauer';
  TC_CTRL_X                             = 'Reduziere Weight um 0.03';
  TC_CTRL_Y                             = 'Erhoehe Weight um 0.03';
  TC_CTRL_SL                            = 'Normales dit';
  TC_QSO_NUMBER                         = 'QSO Nummer';

  TC_SALUTATION_AND_NAME_IF_KNOWN       = 'Anrede und Name falls bekannt';
  TC_NAME_FROM_NAME_DATABASE            = 'Name aus der Namenstabelle';
  TC_SEND_CHARACTERS_FROM_KEYBOARD      = 'Sende Zeichen ueber Tastatur';
  TC_CALL_IN_CALL_WINDOW                = 'Call im Call Fenster';
  TC_RST_PROMPT                         = 'RST Prompt';
  TC_SEND_CALLASSETBYMYCALLCOMMAND      = 'Sende Call wie es in der MY CALL Variable steht';
  TC_REPEATRSTSENT                      = 'Wiederhole gesendetes RST';
 {
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
  TC_TOGGLESSENDINGSENDING              = 'Toggles sending  sending, not monitoring  of CW';
  TC_TOGGLESMODEBETWEENCWANDSSB         = 'Toggles mode between CW and SSB';
  TC_RUNXXAPPLICATION                   = 'Run xx application';
}
  {UCHECKLATESTVERSION}
  TC_VERSIONONSERVER                    = 'Die letzte Version auf dem Server';
  TC_THISVERSION2                       = 'Diese Version';
  TC_DOWNLOADIT                         = 'Willst du die neueste Version herunterladen?';
 

  TC_LIST_OF_COMMAND                    = 'Liste der Kommandos';

  RC_3830                               =  '3830 Punkte posten';   // 4.51.8
  RC_3830_ARRL                          =  'ARRL Log einreichen';  // 4.53.3
  RC_VIEWEDITLOG2                       = 'Log Anzeigen/ Editieren';
  RC_CT1BOHIS2                          = 'CT1BOH Info Screen';
  RC_BANDPLAN                           = 'Bandplan';
  RC_DOWNLOAD_CTY_DAT                   = 'Neueste cty.dat herunterladen';  // 4.75.3
  CLOSE_WORD                            = 'Schliessen';
  CANCEL_WORD                           = 'Abbrechen';
  HELP_WORD                             = 'Hilfe';
  OK_WORD                               = 'OK';
  EXIT_WORD                             = 'E&xit';
  RC_LISTOFMESS                         = 'Liste der Messages';
  RC_STATIONINFO                        = 'Stations Information';
  RC_DUPECHECKOAR                       = 'Dupecheck bei der inaktiven Station';

  RC_MEMPROGFUNC                        = 'Speicher Programmfunktion';
  RC_PRESS_C                            = 'Druecke &C zur Programmierung einer CQ Funktionstaste.';
  RC_PRESS_E                            = 'Druecke &E zur Programmierung einer  Austausch/Search&Pounce Funktionstaste.';
  RC_PRESS_O                            = 'Druecke &O zur Programmierung anderer Meldungen ohne Funktionstastenbelegung.';

  RC_SENDINGCW                          = 'Sende CW ueber die Tastatur. benutze ENTER/Escape/F10 zum Beenden.';

  RC_AUTOCQ2                            = 'Auto-CQ';
  RC_PRESSMKYWTR                        = 'Druecke die Speichertaste, die wiederholt werden soll:';
  RC_NUMBEROSOLT                        = 'Anzahl der Millisekunden der Hoerphase:';
  RC_WINCONTROL2                        = 'Window-Kontrolle';

  RC_TOOLS                              = 'Tools';
  RC_SYNPCTIME                          = 'Synchronisiere Systemzeit';
  RC_BEACONSM                           = 'Beacon Monitor';
  RC_WINCONTROL                         = 'Window Kontrolle';
  RC_SETTIMEZONE                        = 'Zeitzone setzen';
  RC_PING                               = 'Ping [SERVER ADDRESS]';
  RC_RUNSERVER                          = 'TR4WSERVER starten';
  RC_DVKVOLCONTROL                      = 'DVK Lautstaerkeregelung';
  RC_RECCONTROL                         = 'Aufnahmeregelung';
  RC_SOUNDRECORDER                      = 'Sound Recorder';
  RC_DISTANCE                           = 'Entfernung';
  RC_GRID                               = 'Grid';
  RC_CALCULATOR                         = 'Kalkulator';
  RC_LC                                 = 'LC';

  RC_GETOFFSET                          = '&Differenz holen';
  RC_LOCALOFFSET                        = 'Differenz lokale Uhr';
  RC_NTPSERVER                          = 'NTP Server';
  RC_SERVERANSWER                       = 'Server Antwort';
  RC_SYNCLOCK                           = '&Synchronisiere Uhr';
  RC_LOCALTIME                          = 'Ortszeit';
  RC_TIMESYN                            = 'Synchronisiere Zeit auf &allen Computern';
  RC_SEND                               = '&Sende';
  RC_POSTNOW                            = 'Verschicke jetzt';
  RC_GOTOGS                             = 'Zeige Punkte';
  RC_MP3_RECENABLE                      = 'Freigeben';

  RC_DELETESELSPOT                      = 'Ausgewaehlten Spot loeschen';
  RC_REMOVEALLSP                        = 'Alle Spots etfernen';
  RC_SENDINRIG                          = 'QSY inaktive Station';
  RC_FILE                               = 'File';
  RC_CLEARLOG                           = 'Log bereinigen';
  RC_IMPORT                             = 'Import';
  RC_OPENLOGDIR                         = 'Oeffne Log-Verzeichnis';

  RC_OPERATOR                           = 'Operator';
  RC_CALLSIGN                           = 'Callsign';
  RC_MODE                               = 'Mode';
  RC_BAND                               = 'Band';
  RC_APPLY                              = '&Anwenden';
  RC_RESET                              = '&Reset';
  RC_START                              = 'Start';
  RC_SHOW                               = 'Zeige';
  RC_SAVE                               = '&Speichern';
  RC_CREATE                             = 'Erstellen';
  RC_EDIT_WORD                          = '&Editieren';
  RC_POSTSCORETOGS                      = 'Punkte nach Ende';

  RC_NEWCONTEST                         = 'Neuer Contest';

  RC_EXPORT                             = 'Export';
  RC_INIEXLIST                          = 'Initiale QSO-Liste';
  RC_TRLOGFORM                          = 'TR Log Format';
  RC_REPORTS                            = 'Reports';
  RC_ALLCALLS                           = 'Alle Callsigns';
  RC_BANDCHANGES                        = 'Bandwechsel';
  RC_CONTLIST                           = 'Kontinent Liste';
  RC_FCC                                = 'Erste in einem Land gearbeitete Station';
  RC_FCZ                                = 'Erste in jeder Zone gearbeitete Station';
  RC_POSSBADZONE                        = 'Moegliche falsche Zone';
  RC_QSOBYCOUNTRY                       = 'QSOs nach Land und BAND';
  RC_SCOREBYHOUR                        = 'Punkte nach Stunden';
  RC_SUMMARY                            = 'Zusammenfassung';
  RC_EXIT                               = 'E&xit';
  RC_SETTINGS                           = 'Einstellungen';
//  RC_CFG_COMMANDS                       = 'Configuration commands';
  RC_OPTIONS                            = 'Konfigurationskommandos';
  RC_PROGRAMMES                         = 'Programmmeldungen';
  RC_CATANDCW                           = 'CAT und CW Keying';
  RC_WINDOWS                            = 'Windows';
  RC_BANDMAP                            = 'Bandmap';
  RC_DUPESHEET                          = 'Dupesheet';
  RC_FKEYS                              = 'Funktionstasten';
  RC_TRMASTER                           = 'SCP';
  RC_REMMULTS                           = 'Mults';     // 4.72.3
  RC_RM_DEFAULT                         = 'Default';
  RC_TELNET                             = 'DX Cluster';
  RC_NETWORK                            = 'Netzwerk';
  RC_INTERCOM                           = 'Intercom';
//  RC_GETSCORES                          = 'RC_POSTSCORETOGS""';
  RC_STATIONS                           = 'Stationen';
  RC_MP3REC                             = 'MP3 Recorder';
  RC_QUICKMEM                           = 'Quick Memory';
  RC_MULTSFREQ                          = 'Mults Frequenzen';
  RC_ALARM                              = 'Alarm';
  RC_ALTP                               = 'Oeffne F-Tasten';
  RC_ALTX                               = 'Programm beenden';
  RC_CTRLJ                             = 'Oeffne Konfigurationskommandos';
  RC_AUTOCQRESUME                       = 'Auto-CQ fortsetzen';
  RC_DUPECHECK                          = 'Dupecheck';
  RC_EDIT                               = 'Editieren';
  RC_BACKUPLOG                         = 'Backup Log';
  RC_SWAPMULTVIEW                       = 'Wechsel Mult Anzeige';
  RC_INCNUMBER                          = 'Inkrementiere Nummer';
  RC_TOOGLEMB                           = 'Schalte Multiplierton um';
  RC_KILLCW                             = 'Kill CW';
  RC_SEARCHLOG                          = 'Logsuche';
  RC_TRANSFREQ                          = 'Sendefrequenz';
  RC_REMINDER                           = 'Erinnerung';
  RC_AUTOCQ                             = 'Auto-CQ';
  RC_TOOGLERIGS                         = 'Schalte Rigs um';
  RC_CWSPEED                            = 'CW speed';
  RC_SETSYSDT                           = 'Systemdatum und -zeit setzen';
  RC_INITIALIZE                         = 'Initialisiere QSO';
  RC_RESETWAKEUP                        = 'Wakeup zuruecksetzen';
  RC_DELETELASTQSO                      = 'Loesche das letzte QSO';
  RC_INITIALEX                          = 'Initialisiere Austausch';
  RC_TOOGLEST                           = 'Wechsel Sidetone';
  RC_TOOGLEAS                           = 'Wechsel Autosend';
  RC_BANDUP                             = 'Band Up';
  RC_BANDDOWN                           = 'Band Down';
  RC_SSBCWMODE                          = 'SSB/CW Mode';
  RC_SENDKEYBOARD                       = 'Sende Tasteneingabe';
  RC_COMMWITHPP                         = 'Kommuniziere mit Packet Port';
  RC_CLEARDUPES                         = 'Bereinige Dupesheet';
  RC_VIEWEDITLOG                        = 'Log anzeigen / editieren';
  RC_NOTE                               = 'Notiz';
  RC_MISSMULTSREP                       = 'Mult Report fehlt';
  RC_REDOPOSSCALLS                      = 'Wiederhole moegliche Calls';
  RC_QTCFUNCTIONS                       = 'QTC Funktionen';
  RC_RECALLLASTENT                      = 'Hole letzten Eintrag zurueck';
  RC_VIEWPAKSPOTS                       = 'Zeige Packet Spots';
  RC_EXECONFIGFILE                      = 'Fuehre Konfigurationsdatei aus';
  RC_REFRESHBM                          = 'Aktualisiere Bandmap';
  RC_DUALINGCQ                          = 'Waehle CQs';
  RC_CURSORINBM                         = 'Cursor ist im Bandmap Fenster';
  RC_CURSORTELNET                       = 'Cursor ist im DX Cluster Fenster';
  RC_QSOWITHNOCW                        = 'QSO ohne CW';
  RC_CT1BOHIS                           = 'CT1BOH Info Screen';
  RC_ADDBANDMAPPH                       = 'Bandmap Platzhalter hinzufuegen';
  RC_COMMANDS                           = 'Kommandos';
  RC_FOCUSINMW                          = 'Fokus im Hauptfenster';
  RC_TOGGLEINSERT                       = 'Wechsel Einfuegemodus';
  RC_ESCAPE                             = 'Escape';
  RC_CWSPEEDUP                          = 'CW Speed Up';
  RC_CWSPEEDDOWN                        = 'CW Speed Down';
  RC_CWSPUPIR                           = 'CW Speed Up fuer die inaktive Station';
  RC_CWSPDNIR                           = 'CW Speed Down fuer die inaktive Station';
  RC_CQMODE                             = 'CQ Mode';
  RC_SEARCHPOUNCE                       = 'Search&Pounce Mode';
  RC_SENDSPOT                           = 'Sende Spot';
  RC_RESCORE                            = 'Neuberechnung';

  RC_NET                                = 'Net';

  RC_SENDMESSAGE                        = 'Sende Message';
  RC_SYNLOG                             = 'Vergleiche und synchronisiere Logs';
  RC_CLEARALLLOGS                       = 'Bereinige alle Logs im Netzwerk';
  RC_DOWNLOAD                           = 'Lade die neueste CTY.DAT herunter';
  RC_CONTENTS                           = 'Inhalte';
  RC_ABOUT                              = 'ueber';
  RC_CONFFILE                           = 'Konfigurationsdatei';
  RC_EDITQSO                            = 'Editiere QSO';
  RC_DELETED                            = 'Geloescht';
  RC_DUPE                               = 'Dupe';
//  RC_LOGSEARCH                          = 'Log search';
  RC_SEARCH                             = '&Suche';

//  RC_DUPESHEET2                         = 'Dupesheet';
//  RC_SENDSPOT2                          = 'Send spot';
  RC_CONTESTNAMEIC                      = 'C&ontestname im Kommentar';
  RC_COMMENT                            = 'Kommentar';
  RC_RETURNTOMOD                        = 'Aendern';
  RC_ARROWTOSELIT                       = 'Pfeil/Bild hoch/Bild runter Tasten oder ersten Buchstaben um den Eintrag auszuwaehlen.';
  RC_ALTW                               = 'Sichern (Alt-&W)';
  RC_ALTN                               = 'Zum &Netzwerk';
  RC_ALTG                               = 'Alle speichern (Alt-&G)';
  RC_COAX                               = 'Berechnung Laenge COAX';
  RC_ENTERTNHINIK                       = 'Die naechsthoehere Frequenz in kHz eingeben:';
  RC_ENTERALIFIK                        = 'Eine niedrigere Frequenz in kHz eingeben:';
  RC_DISTANCEBTGS                       = 'Distanz zwischen zwei Grid Locatern';
  RC_SECONDGRID                         = 'Zweites Grid';
  RC_FIRSTGRID                          = 'Erstes Grid';
  RC_EURVHFDIST                         = 'European VHF Distance:';
  RC_GRIDOFAGLL                         = 'Grid  einer vorgegebenen Lat/Lon';
  RC_LONGMIE                            = 'Laengengrad (Minus ist oestlich)';
  RC_LATMIS                             = 'Breitengrad (Minus ist westlich)';
  RC_CALCOFCORI                         = 'Berechnung vom Kapazitaet oder Induktivitaet';
  RC_INDUCANCE                          = 'Induktivitaet, uH';
  RC_CAPACITANCE                        = 'Kapazitaet, pf';
  RC_FREQOFRES                          = 'Resonanzfrequenz, khz';

  RC_SHOWMENU                           = '&Zeige Menue';
  RC_RECVQTC                            = 'Empfange QTCs';
  RC_MIXWINTERFACE                      = 'MixW Interface';
  RC_CONNECTTOMIXW                      = 'Verbunden mit MixW';

//  RC_SYNLOG2                            = 'Synchronize log';
  RC_GETSERVLOG                         = '&Hole Serverlog';
  RC_RECVRECORDS                        = 'Erhaltene Records:';
  RC_SENDRECORDS                        = 'Gesendete Records:';
  RC_CREATEAUNL                         = '&Erstelle ein neues Userlog';
  RC_RECVBYTES                          = 'Empfangene Bytes:';
  RC_RECVQSOS                           = 'Empfangene QSOs:';
  RC_SHOWSERVLOGC                       = 'Zeige Inhalt des Serverlogs';

//  RC_INTERCOM2                          = 'Intercom';
  RC_DIFFINLOG                          = 'Differenz in den Logs';
  RC_ARCFILTER                          = 'ARC Spots band-mode filter';
  RC_DXSFILTER                          = 'DXSpider Spots band-mode filter';
  RC_CLEARFILTER                        = 'Bereinige Filter';
  RC_STATIONS2                          = 'Stationen';
  RC_C_EDITQSO                          = 'QSO aendern ';
  RC_C_DELETEQSO                        = 'QSO loeschen';
  RC_COPYTOCLIP                         = 'Kopiere in Zwischenablage';

//  RC_WINKEYSET                          = 'Winkeyer Settings';
  RC_DATE                               = 'Datum';
  RC_NUMBERSENT                         = 'Gesendete Nummer';
  RC_NUMBERRCVD                         = 'Empfangene Nummer';
  RC_RSTSENT                            = 'RST gesendet';
  RC_RSTRECEIVED                        = 'RST empfangen';
  RC_QSOPOINTS                          = 'QSO Punkte';
  RC_AGE                                = 'Alter';
  RC_FREQUENCYHZ                        = 'Frequenz, Hz';
  RC_PREFIX                             = 'Prefix';
  RC_ZONE                               = 'Zone';
  RC_NAME                               = 'Name';
  RC_POSTALCODE                         = 'Postleitzahl';
  RC_POWER                              = 'Power';
  RC_PROGRMESS                          = 'Programm Message';
  RC_MESSAGE                            = 'Message';
  RC_CAPTION                            = 'ueberschrift';
  RC_IAQSLINT                           = 'Auto QSL Interval (erhoehem)';
  RC_DAQSLINT                           = 'Auto QSL Interval (vermindern)';
  RC_ADDINFO                            = 'Zusaetzliche Information';
  RC_AI_QSONUMBER                       = 'QSO Nummer';
  RC_AI_CWSPEED                         = 'CW Speed';
  RC_CLEARMSHEET                        = 'Multsheet bereinigen';
  RC_WIKI                               = 'On-line Dokumentation (auf Russisch)';
  RC_NET_CLDUPE                         = 'Dupesheet in allen Logs bereinigen';
  RC_NET_CLMULT                         = 'Multsheet in allen Logs bereinigen';
  RC_INC_TIME                           = 'Zeit erhoehen';
  RC_NOTES                              = 'Hinweis';
  RC_DEFAULT                            = 'Default:';
  RC_DESCRIPTION                        = 'Beschreibung:';
  RC_DEVICEMANAGER                      = 'Geraetemanager';
  RC_SHDX_CALLSIGN                      = 'SH/DX [Callsign]';

  RC_PLAY                               = '&Play';

  RC_LOGIN                              = 'Log in';
  RC_SYNCHRONIZE                        = 'Synchronisiere';
  RC_GET_OFFSET                         = 'Hole Versatz';
  RC_COLORS                             = 'Farben';
  RC_APPEARANCE                         = 'Design';

  RC_WA7BNM_CALENDAR                    = 'WA7BNM''s Contest Calendar';
  RC_SEND_BUG                           = 'Fehlerreport senden';
  RC_HOMEPAGE                           = 'TR4W Homepage';
  RC_FREQUENCY                          = 'Frequenz';
  TC_SPLIT_WARN                       = 'Warnung: Du bist im SPLIT MODE !!!';
{FD Additions NY4I}

TC_IMPROPERTRANSMITTERCOUNT = 'FD Transmitter muessen zwischen 1 und 99 sein.';
TC_IMPROPERARRLFIELDDAYCLASS = 'Field Day Klassen muessen A, B, C, D, E oder F sein.';
TC_IMPROPERWINTERFIELDDAYCLASS = 'Winter Field Day Klasse muss H, I oder O sein.';
TC_ARRLFIELDDAYIMPROPERDXEXCHANGE = 'DX Stations Angabe muss "DX" sein.';

RC_SPLITOFF                       = 'Split Mode Tx setzen';
TC_RUNWARN                    = 'Eine andere Instanz von TR4W laeuft schon';
RC_wkMode                     = 'Neu-Initialisierung WinKeyer';      // 4.60.1

