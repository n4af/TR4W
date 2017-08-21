
  { %s =	Øetìzec [string.]}
  { %c =	Znak (v progr.prostøedí)}
  { %d =	Èíslo (dek.vyjádøení}
  { %u =	Èíslo (prosté vyjádøení)}
const
  TC_TRANSLATION_LANGUAGE               = 'ÈESKY';
  TC_TRANSLATION_AUTHOR                 = 'OK1RR';
  TC_TRANSLATOR_EMAIL                   = 'martin@ok1rr.com';

  TC_UKEI                               = 'Zkontrolovat, je-li UK/EI';
  TC_EnterYourDistrictCode              = 'Je-li UK/EI, zadej kód distriktu';
  TC_YUGOSLAVIA                         = 'Jugoslávie';
  RC_BACKUPLOG                          = 'záložní deník';
  TC_IMPROPERWINTERFIELDDAYCLASS        = 'Winter Field Day class musí být H, I nebo O.';
  TC_ARRLFIELDDAYIMPROPERDXEXCHANGE = 'soutìž. kód DX stanic musí být "DX".';
  RC_3830                               =  'zaslání skóre na 3830';
  RC_3830_ARRL                          =  'odeslat deník ARRL';  // 4.53.3
  TC_INVALID                            =  'Neplatný záznam';
  TC_FREQ                               = 'frekv';
  TC_POINTS                             = 'body';
  TC_OP                                 = 'Op';
  TC_CHECKCALLSIGN                      = 'Kontroluj znaèku';
  TC_FREQUENCYFORCALLINKHZ              = 'Kmitoèet pro %s v kHz';
  TC_DIFVERSION                         = '%s pochází z jiné programové verze.'#13'TR4W oèekává programovou verzi %s.'#13'Pokoušíš se èíst soubor ve verzi %s.';


  TC_M                                  = 'm'; //minuta
  TC_S                                  = 's'; //sekunda

  TC_RADIO1                             = 'RIG 1';
  TC_RADIO2                             = 'RIG 2';

  TC_DISBALE_CIV                        = 'vypnout "CI-V Transceive" mód v transceiveru ICOM';

  {MAIN}
  TC_YOU_ARE_USING_THE_LATEST_VERSION   = 'používáš poslední (aktuální) verzi';
  TC_SET_VALUE_OF_SET_NOW               = 'nastavit nyní hodnotu %s ?';
  TC_CONFIGURATION_FILE                 = 'Konfiguraèní soubor';
  TC_CURRENT_OPERATOR_CALLSIGN          = 'souèasný operátor má znaèku ';
  TC_APPENDIMPORTEDQSOSTOCURRENTLOG     = 'Pøipojit importovaná QSO k aktuálnímu deníku?';
  TC_QSO_IMPORTED                       = 'QSO importována';
  TC_ISADUPE                            = '%s je duplicitní!';
  TC_ERRORINLOGFILE                     = 'Chyba v souboru .TRW!';
  TC_HASIMPROPERSYNTAX                  = '%s má nesprávnou syntaxi!';
  TC_SORRYNOLOG                         = 'Lituji! NO LOG = TRUE blokuje zápis QSO na tomto poèítaèi';
  TC_SETCOMPUTERIDVALUE                 = 'Nastav údaj COMPUTER ID.';

  TC_CLEARALLLOGS                       = '"CLEARALLLOGS" pro vymazání všech deníkù v síti';
  TC_CLEAR_DUPESHEET_NET                = '"CLEARDUPESHEET" pro vymazání všech seznamù QSO v síti';
  TC_CLEAR_MULTSHEET_NET                = '"CLEARMULTSHEET" pro vymazání všech seznamù násobièù v síti';

  TC_REALLYWANTTOCLEARTHELOG            = 'Opravdu chceš smazat aktuální deník?';
  TC_MESSAGETOSENDVIANETWORK            = 'Zpráva pro sí';
  TC_SENDTIMETOCOMPUTERSONTHENETWORK    = 'Opravdu chceš poslat èasový údaj všem poèítaèùm v síti?';
  TC_RULESONSM3CER                      = 'Pravidla závodu %s na "WA7BNM Contest Calendar"';
  TC_RULESONQRZRU                       = 'Podmínky závodu %s viz QRZ.RU';
  TC_NOTE                               = 'poznámka';
  TC_DUPESHEETCLEARED                   = 'Seznam QSO byl vymazán!';
  TC_MULTSHEETCLEARED                   = 'Seznam násobièù byl vymazán!';
  TC_YESTOCLEARTHEDUPESHEET             = '"YES" pro vymazání seznamu QSO';
  TC_CLEARMULTTOCLEARMULTSHEET          = '"CLEARMULT" pro vymazání seznamu násobièù';

  TC_TRANSMITFREQUENCYKILOHERTZ         = 'vysílací kmitoèet (kHz): ';
  TC_SPRINTQSYRULE                      = 'PRAVIDLO SPRINT QSY!!';
  TC_PADDLE                             = 'Pastièka';
  TC_FOOTSW                             = 'Šlapka';
//  TC_LOG_NOTE                           = 'POZNÁMKA';
//  TC_LOG_DELETED                        = 'SMAZÁNO';

  TC_SUN                                = 'Ne';
  TC_MON                                = 'Po';
  TC_TUE                                = 'Út';
  TC_WED                                = 'St';
  TC_THU                                = 'Èt';
  TC_FRI                                = 'Pá';
  TC_SAT                                = 'So';

  {uMP3Recorder}

  TC_LAME_ERROR                         = 'Mùžeš to stáhnout ze serveru';

  {Tato verze TR4W v.4.009 beta byla vydána 2.prosince 2008. Chceš ovìøit poslední verzi ?}
  TC_THISVERSION                        = 'Máš verzi ';
  TC_WASBUILDIN                         = ' instalována (vydána) dne ';
  TC_DOYOUWANTTOCHECKTHELATESTVERSION   = 'Chceš ovìøit, zda existuje novìjší verze TR4W ?';

  {NEW CONTEST}
  TC_LATEST_CONFIG_FILE                 = 'poslední konfigurace';
  TC_OPENCONFIGURATIONFILE              = ' - Otevøe konfiguraèní soubor nebo deník závodu';
  TC_FOLDERALREADYEXISTSOVERWRITE       = 'Adresáø "%s" již existuje.'#13'Pøepsat ?';
  TC_IAMIN                              = '&Moje QTH je %s';

  TC_NEWENGLANDSTATEABREVIATION         = 'Zadej zkratku svého státu pro NEQP'#13'(ME, NH, VT, MA, CT, RI):';
  TC_ENTERTHEQTHTHATYOUWANTTOSEND       = 'Zadej QTH, které budeš vysílat:';
  TC_ENTERSTATEFORUSPROVINCEFORCANADA   = 'Zadej stát v USA, nebo provincii v Kanadì:';
  TC_ENTERYOUROBLASTID                  = 'Zadej ID své oblasti:';
  TC_ENTERYOURPROVINCEID                = 'Zadej ID své provincie:';
  TC_ENTERYOURCOUNTYCODE                = 'Zadej kód svého kraje:';
  TC_ENTERYOURDOK                       = 'Zadej svùj DOK:';
  TC_ENTERYOURDISTRICTABBREVIATION      = 'Zadej zkratku svého okresu (distriktu):';
  TC_ENTERYOURFOCNUMBER                 = 'Zadej své èíslo FOC:';
  TC_ENTERYOURRDAID                     = 'Zadej svùj RDA ID:';
  TC_ENTERYOURIOTAREFERENCEDESIGNATOR   = 'Zadej své referenèní èíslo IOTA (vèetnì oddìlovací pomlèky, napø. EU-123):';
  TC_ENTERYOURCITYIDENTIFIER            = 'Zadej identifikátor svého mìsta:';
  TC_ENTERYOURNAME                      = 'Zadej své jméno:';
  TC_ENTERTHELASTTWODIGITSOFTHEYEAR     = 'Zadej poslední dvì èíslice roku vydání své první oficiální radioamatérské licence:';
  TC_ENTERYOURZONE                      = 'Zadej svou zónu:';
  TC_ENTERYOURGEOGRAPHICALCOORDINATES   = 'Zadej své zemìpisné souøadnice'#13'(napø. 50N14E pro Prahu):';
  TC_ENTERSUMOFYOURAGEANDAMOUNT         = 'Zadej souèet svého vìku a poètu let od svého prvního radioamatérského QSO (napø. 28+14=42):';
  TC_OZCR                               = 'Zadej tøímístný kód, složený z libovolných písmen (napø. XYZ):';
  TC_ENTERYOURSTATECODE                 = 'Zadej kód své zemì (CZ pro Èesko):';
  TC_ENTERYOURFOURDIGITGRIDSQUARE       = 'Zadej svùj ètyømístný WW lokátor (napø. JO70):';
  TC_RFAS                               = 'Zadej své zemìpisné souøadnice:';
  TC_ENTERYOURSIXDIGITGRIDSQUARE        = 'Zadej svùj šestimístný WW lokátor (napø. JO70ND):';
  TC_ENTERYOURNAMEANDSTATE              = 'Zadej své jméno (a stát, pokud jsi v USA):';
  TC_ENTERYOURNAMEANDQTH                = 'Zadej své jméno a QTH (stát USA, provincii v Kanadì nebo zemi DXCC):';
  TC_ENTERYOURPRECEDENCECHECKSECTION    = 'Zadej své zaøazení (precedence), svùj check'#13'(poslední dvojèíslí roku vydání své licence) a sekci ARRL (napø. CT):';
  TC_ENTERYOURQTHANDTHENAME             = 'Zadej své QTH, které chceš vysílat'#13'a jméno, které chceš používat:';
  TC_ENTERFIRSTTWODIGITSOFYOURQTH       = 'Zadej první dvì èíslice svého QTH:';
  TC_ENTERYOURAGEINMYSTATEFIELD         = 'Zadej svùj vìk do pole MY STATE:';
  TC_ENTERYOURQTHORPOWER                = 'Zadej do pole MY STATE své QTH, které chceš vysílat, pokud jsi v USA, nebo svùj výkon, pokud jsi mimo USA:';
  TC_ENTERFIRSTTWOLETTERSOFYOURGRID     = 'Zadej první dvì písmena svého WW lokátoru:';
  TC_ENTERYOURSQUAREID                  = 'Zadej ID svého ètverce:';
  TC_ENTERYOURMEMBERSHIPNUMBER          = 'Zadej své èlenské èíslo:';
  TC_ENTERYOURCONTINENT                 = 'Zadej svùj kontinent (a pøípadné doplòkové ID, napø. SAYL or NAQRP)';
  TC_ENTERYOURCOUNTYORSTATEPOROVINCEDX  = 'Zadej svùj kraj (county), pokud jsi ve státu %s. Zadej svùj stát, kanadskou provincii, nebo "DX", pokud jsi mimo %s:';
  TC_PREFECTURE                         = 'Zadej svou prefekturu:';
  TC_STATIONCLASS                       = 'zadej tøídu své licence:';
  TC_AGECALLSIGNAGE                     = 'zadej svùj vìk (a zaniklou znaèku a vìk):';
  TC_DEPARTMENT                         = 'zadej svùj department:';
  TC_ENTERYOURRDAIDORGRID               = 'zadej své RDA ID (pro stanice UA1A) nebo ètyømístný QTH lokátor:';
  TC_ENTERYOURBRANCHNUMBER              = 'Zadej své èíslo odboèky:';
  TC_ENTERYOURPOSTCODE                  = 'Zadej svoje PSÈ:';

  TC_ISLANDSTATION                      = 'Stanice na ostrovì (IOTA)';
  TC_NEWENGLAND                         = 'New England';
  TC_CALIFORNIA                         = 'California';
  TC_FLORIDA                            = 'Florida';
  TC_MICHIGAN                           = 'Michigan';
  TC_MINNESOTA                          = 'Minnesota';
  TC_OHIO                               = 'Ohio';
  TC_WASHINGTON                         = 'Washington';
  TC_WISCONSIN                          = 'Wisconsin';
  TC_TEXAS                              = 'Texas';
  TC_NORTHAMERICA                       = 'Sev.Amerika';
  TC_RUSSIA                             = 'Rusko';
  TC_UKRAINE                            = 'Ukrajina';
  TC_CZECHREPUBLICORINSLOVAKIA          = 'Èesko nebo Slovensko';
  TC_BULGARIA                           = 'Bulharsko';
  TC_ROMANIA                            = 'Rumunsko';
  TC_HUNGARY                            = 'Maïarsko';
  TC_BELGIUM                            = 'Belgie';
  TC_NETHERLANDS                        = 'Holandsko';
  TC_STPETERSBURGOBLAST                 = 'St.Petersburg / oblast';
  TC_GERMANY                            = 'Nìmecko';
  TC_UK                                 = 'V. Británie';
  TC_ARKTIKACLUB                        = 'Arktika klub';
  TC_POLAND                             = 'Polsko';
  TC_KAZAKHSTAN                         = 'Kazachstán';
  TC_ITALY                              = 'Itálie';
  TC_SWITZERLAND                        = 'Švýcarsko';
  TC_HQ                                 = 'HQ (HQ stanice)';
  TC_CIS                                = 'CIS';
  TC_SPAIN                              = 'Španìlsko';
  TC_JAPAN                              = 'Japonsko';
  TC_CANADA                             = 'Kanada';
  TC_FRANCE                             = 'Francie';
  TC_HQ_OR_MEMBER                       = 'HQ nebo èlen';
  TC_IRELAND                            = 'Irsko';

  {UTELNET}

  TC_TELNET                             = 'Spojit'#0'Odpojit'#0'Pøíkazy'#0'Zastavit'#0'Vymazat'#0'100'#0#0;
  TC_YOURNOTCONNECTEDTOTHEINTERNET      = 'NEJSI PØIPOJEN K INTERNETU!';
  TC_GETHOST                            = 'Pøipoj HOST..';
  TC_SERVER                             = 'SERVER: %s';
  TC_HOST                               = 'HOST  : %s';
  TC_CONNECT                            = 'PØIPOJIT..';
  TC_CONNECTED                          = 'PØIPOJEN';
  TC_YOUARESPOTTEDBYANOTHERSTATION      = 'Jiná stanice pøedává spot s tvou znaèkou.';

  {UNET}

  TC_CONNECTIONTOTR4WSERVERLOST         = 'Pøipojení k serveru TR4W %s:%d bylo pøerušeno.';
  TC_COMPUTERCLOCKISSYNCHRONIZED        = 'Hodiny PC jsou synchronizovány.';
  TC_CONNECTINGTO                       = 'Pøipojuje se k ';
  TC_CONNECTTOTR4WSERVERFAILED          = 'Pøipojení k serveru TR4W neúspìšné. Ovìø heslo!';
  TC_CONNECTEDTO                        = 'Pøipojen k ';
  TC_FAILEDTOCONNECTTO                  = 'Porucha spojení s ';
  TC_SERVERANDLOCALLOGSAREIDENTICAL     = 'Deníky na serveru a aktuální deníky jsou identické.';
  TC_NETWORK                            = 'Sí     : %s %s:%d';
  TC_SERVER_LOG_CHANGED                 = 'Deník na serveru byl zmìnìn. %u QSO(s) bylo pøepsáno. Synchronizuj deníky (Ctrl+Alt+S).';
  TC_ALL_LOGS_NETWORK_CLEARED           = 'Všechny deníky v síti TR4W byly smazány.';

  {UGETSCORES}

  TC_FAILEDTOCONNECTTOGETSCORESORG      = 'Spojení se nezdaøilo';
  TC_NOANSWERFROMSERVER                 = 'Žádná odpovìï od serveru';
  TC_UPLOADEDSUCCESSFULLY               = 'Úpravy byly úspìšné.';
  TC_FAILEDTOLOAD                       = 'Vložení dat selhalo. Podrobnosti viz getscoresanswer.html.';

  {UBANDMAP}

  TC_SOURCE                             = 'Zdroj: %s';
  TC_MIN                                = '%u min.';

  {LOGWIND}

  TC_CQTOTAL                            = 'CQ celkem: %u';
  TC_REPEATING                          = 'Opakuje se %s  Doba poslechu = %u msec - PgUp/Dn pro nastavení nebo ESC pro ukonèení';
  TC_NEWTOUR                            = 'Nové kolo %d/%d';
  TC_ENTER                              = 'ENTER > %s :';
  TC_PTS                                = '%d bodù';
  TC_RATE                               = 'Rate= %u';
  TC_LAST60                             = 'Posl.60= %d';
  TC_THISHR                             = 'Tato hod.= %d';
  TC_BAND_CHANGES                       = 'Zm.pásma= %d';

  TC_HAVEQTCS                           = '%u QTC OK';
  TC_INSERT                             = 'VLOŽIT';
  TC_OVERRIDE                           = 'PØEPSAT';
  TC_UNKNOWNCOUNTRY                     = 'Neznámá zemì';

  {UCALLSIGNS}

  TC_DUPESHEET                          = 'Zapsáno - %sm-%s';

  {LOGEDIT}

  TC_QSONEEDSFOR                        = 'Chybí QSO s %s :';
  TC_MULTNEEDSFOR                       = 'Chybí násobièe od %s :';
  TC_MISSINGMULTSREPORT                 = 'Chybìjící násobièe: %u zemí nejménì na %u pásmech, ale ne na všech.';

  {LOGDUPE}

  TC_THEREWERECALLS                     = 'Bylo nalezeno %u znaèek v souboru IE.'#13'+%u opakovaných QSO(s)';
  TC_RESTARTBINISFORADIFFERENTCONTEST   = 'RESTART.BIN je pro jiný závod.';

  {LOGSTUFF}

  TC_NOTENOUGHINFOINEXCHANGE            = 'Kód je neúplný!';
  TC_IMPROPERDOMESITCQTH                = 'Nesprávné domovské QTH!';
  TC_IMPROPERDOMESITCQTHORMISSINGNAME   = 'Nesprávné domovské QTH nebo chybí jméno!';
  TC_MISSINGQTHANDORNAME                = 'Schází QTH a/nebo jméno!';
  TC_NOQSONUMBERFOUND                   = 'Nebylo nalezeno èíslo QSO!';
  TC_IMPROPERZONENUMBER                 = 'Nesprávná zóna!';
  TC_IMPROPERCONTINENT                  = 'Nesprávný kontinent!';
  TC_SAVINGTO                           = 'Ukládá se %s do %s';
  TC_FILESAVEDTOFLOPPYSUCCESSFULLY      = 'Soubor byl úspìšnì uložen na disketu';
  TC_FILESAVEDTOSUCCESSFULLY            = 'Soubor byl úspìšnì uložen do %s';


  {LOGSEND}

  TC_WAITINGFORYOUENTERSTRENGTHOFRST    = ' S (jedinou èíslici)!';

  {COUNTRY9}

  TC_C9_NORTHAMERICA                    = 'Severní Amerika';
  TC_C9_SOUTHAMERICA                    = 'Jižní Amerika';
  TC_C9_EUROPE                          = 'Evropa';
  TC_C9_AFRICA                          = 'Afrika';
  TC_C9_OCEANIA                         = 'Oceánie';
  TC_C9_ANTARTICA                       = 'Antarktida';
  TC_C9_ASIA                            = 'Asie';
  TC_C9_UNKNOWN                         = 'Neznámý';

  {USTATIONS}

  TC_STATIONSINMODE                     = 'Stanice v módu %s';

  {USPOTS}

  TC_SPOTS                              = '%d spotù';

  {uSendKeyboard}

  TC_SENDINGSSBWAVFILENAME              = 'Vysílá se SSB soubor .wav. ENTER pro pøehrání, ESC/F10 pro odchod.';

  {QTC}

  TC_WASMESSAGENUMBERCONFIRMED          = 'Bylo QTC èíslo %u potvrzeno?';
  TC_DOYOUREALLYWANTSTOPNOW             = 'Chceš to opravdu teï ukonèit?';
  TC_QTCABORTEDBYOPERATOR               = 'QTC pøerušeno operátorem.';
  TC_DOYOUREALLYWANTTOABORTTHISQTC      = 'Chceš opravdu pøerušit toto QTC?';
  TC_NEXT                               = '< Pøíští';
  TC_QTC_FOR                            = '%s pro %s';
  TC_QTC_CALLSIGN                       = 'Znaèka :';
  TC_ENTERQTCMAXOF                      = 'Zadej QTC #/# (max  %d) :';
  TC_DOYOUREALLYWANTTOSAVETHISQTC       = 'Chceš opravdu uložit toto QTC?';
  TC_EDITQTCPRESSYESTOEDITQTCORNOTOLOG  = 'Editovat QTC? YES pro editaci nebo NO pro zápis ';
  TC_CHECKQTCNUMBER                     = 'Kontroluj poèet QTC';
  TC_CHECKTIME                          = 'Kontroluj èas';

  {UOPTION}

  TC_COMMAND                            = 'Pøíkaz';
  TC_VALUE                              = 'Hodnota';
  TC_INFO                               = 'Info';
  TC_YOUCANCHANGETHISINYOURCONFIGFILE   = 'To mùžeš zmìnit jen ve svém konfiguraèním souboru.';

  {UEDITQSO}

  TC_CHECKDATETIME                      = 'Kontroluj datum/èas!';
  TC_SAVECHANGES                        = 'Uložit zmìny?';

  {LOGCW}

  TC_WPMCODESPEED                       = 'rychlost (slov/min)';
  TC_CQFUNCTIONKEYMEMORYSTATUS          = 'STAV PAMÌTI PROGRAMOVÁNÍ CQ';
  TC_EXCHANGEFUNCTIONKEYMEMORYSTATUS    = 'STAV PAMÌTI PROGRAMOVÁNÍ EX(CHANGE)';
  TC_OTHERCWMESSAGEMEMORYSTATUS         = 'Stav jiné CW pamìti';
  TC_OTHERSSBMESSAGEMEMORYSTATUS        = 'Stav jiné SSB pamìti';
  TC_PRESSCQFUNCTIONKEYTOPROGRAM        = 'Stiskni klávesu programování CQ (F1, AltF1, CtrlF1), nebo ESC pro odchod) : ';
  TC_PRESSEXFUNCTIONKEYTOPROGRAM        = 'Stiskni klávesu programování EX(change) (F3-F12, Alt/Ctrl F1-F12) nebo ESC pro odchod:';
  TC_NUMBERORLETTEROFMESSAGETOBEPROGRAM = 'Zadej èíslo nebo písmeno MSG, která má být programována (1-9, A-C, nebo ESC pro odchod):';
  TC_CWDISABLEDWITHALTK                 = 'CW je blokováno stiskem Alt-K!  Stiskni znovu Alt-K pro obnovení CW.';
  TC_VOICEKEYERDISABLEDWITHALTK         = 'Hlasový automat blokován stiskem  Alt-K! Stiskni znovu Alt-K pro obnovení funkce.';

  {LOGCFG}

  TC_NOCALLSIGNSPECIFIED                = 'Nebyla zadána volací znaèka!';
  TC_NOFLOPPYFILESAVENAMESPECIFIED      = 'Nebyl zadán název souboru pro uložení na disketu!';
  TC_UNABLETOFIND                       = 'Nelze nalézt %s!';
  TC_INVALIDSTATEMENTIN                 = 'NESPRÁVNÝ PØÍKAZ V %s!'#13#13'Øádek %u'#13'%s';
  TC_UNABLETOFINDCTYDAT                 = 'Nelze nalézt soubor CTY.DAT (seznam zemí)!'#13'Tento soubor musí být ve stejném adresáøi, jako program TR4W.';
  TC_INVALIDSTATEMENTINCONFIGFILE       = '%s:'#13'NESPRÁVNÝ PØÍKAZ V KONFIGURAÈNÍM SOUBORU!'#13#13'Øádek %u'#13'%s';
  TC_THIS_FILE_DOES_NOT_EXIST           = 'Tento soubor neexistuje. Vytvoøit soubor pro editaci?';

  {LOGSUBS1}

  TC_RECORDDVPPRESSESCAPEORRETURNTOSTOP = 'Nahrává se DVP. Stiskni ESC nebo RETURN pro ukonèení.';
  TC_ALTRCOMMANDDISABLED                = 'Pøíkaz Alt-R je blokován volbou SINGLE RADIO MODE = TRUE';
  TC_NOCQMESPROGRAMMEDINTOCQMEMORYALTF1 = 'V pamìti CQ [AltF1] není naprogramována žádná MSG.';

  {LOGSUBS2}

//  TC_WASADUPE                           = '%s bylo duplicitní.';
  TC_ALTDCOMMANDDISABLED                = 'Pøíkaz Alt-D je blokován volbou SINGLE RADIO MODE = TRUE';
  TC_YOUHAVERESTOREDTHELASTDELETED      = 'Poslední smazaný záznam v deníku byl obnoven!';
  TC_YOUHAVEDELETEDTHELASTLOGENTRY      = 'Smazal jsi poslední záznam v deníku!  Stiskni ALT-Y k jeho obnovení.';
  TC_DOYOUREALLYWANTTOEXITTHEPROGRAM    = 'Chceš skuteènì ukonèit program?';
  TC_YOUARENOWTALKINGTOYOURPACKETPORT   = 'Nyní pracuješ pøes rozhraní packet radio. Stiskni CTRL-B pro ukonèení.';
  TC_YOUALREADYWORKEDIN                 = 'Již jsi pracoval s %s na %s!';
  TC_ISADUPEANDWILLBELOGGEDWITHZERO     = '%s je duplicitní a bude zapsáno v deníku s hodnotou 0 bodù.';
  TC_LOGFILESIZECHECKFAILED             = 'Kontrola velikosti souboru .TRW selhala!!';

  {JCTRL2}
  TC_NEWVALUE                           = 'nová hodnota';

  {TREE}

  TC_ALREADYEXISTSOKAYTODELETE          = '%s již existuje.'#13#13'Má se smazat?';

  {UWINKEY}

  TC_WINKEYERENABLE                     = '&Winkeyer v provozu';
  TC_AUTOSPACE                          = '&aut. mezery';
  TC_CTSPACING                          = 'Kalibrace mezer C&T';
  TC_SIDETONE                           = '&Pøíposlech klíè.';
  TC_PADDLESWAP                         = 'Zámìna T/È';
  TC_IGNORESPEEDPOT                     = '&progr.rychlost';
  TC_PADDLEONLYSIDETONE                 = '&pøíposlech elbugu';

  TC_WINKEYERPORT                       = 'Port WK';
  TC_KEYERMODE                          = 'Mód klíèování';
  TC_SIDETONEFREQ                       = 'Kmitoèet pøíposlechu';
  TC_HANGTIME                           = 'Prodleva';

  TC_IAMBICB                            = 'Jambický mód B';
  TC_IAMBICA                            = 'Jambický mód A';
  TC_ULTIMATIC                          = 'Mód Ultimatic';
  TC_BUGMODE                            = 'Bug';

  TC_WEIGHTING                          = 'Pomìr teèka/mezera';
  TC_DITDAHRATIO                        = 'Pomìr teèka/èárka';
  TC_LEADIN                             = 'Nábìh PTT (*10 ms)';
  TC_TAIL                               = 'Dobìh PTT (*10 ms)';
  TC_FIRSTEXTENSION                     = 'Prodloužení 1.elementu';
  TC_KEYCOMP                            = 'Kompenzace klíèování';
  TC_PADDLESWITCHPOINT                  = 'Prodleva pastièky';

  {UTOTAL}

  TC_QTCPENDING                         = 'Zpracovává se QTC';
  TC_ZONE                               = 'Zóna';
  TC_PREFIX                             = 'Prefix';
  TC_DXMULTS                            = 'DX násobièe';
  TC_OBLASTS                            = 'Oblasti';
  TC_HQMULTS                            = 'HQ násobièe';
  TC_DOMMULTS                           = 'Dom násobièe';
  TC_QSOS                               = 'QSOs';
  TC_CWQSOS                             = 'CW QSOs';
  TC_SSBQSOS                            = 'SSB QSOs';
  TC_DIGQSOS                            = 'DIG QSOs';

  {UALTD}

  TC_ENTERCALLTOBECHECKEDON             = 'Zadej znaèku pro kontrolu na %s%s:';

  {LOGGRID}

  TC_ALLSUN                             = 'Den';
  TC_ALLDARK                            = 'Noc';

  {UMIXW}

  TC_MIXW_CONNECTED                     = 'MIXW pøipojen';
  TC_MIXW_DISCONNECTED                  = 'MIXW odpojen';

  {LOGWAE}

  TC_INVALIDCALLSIGNINCALLWINDOW        = 'Neplatná znaèka v oknì QSO!';
  TC_SORRYYOUALREADYHAVE10QTCSWITH      = 'Lituji, již máš 10 QTC od %s';
  TC_NOQTCSPENDINGQRU                   = 'Žádné QTC, QRU.';
  TC_ISQRVFOR                           = 'Je %s QRV pro %s?';

  {UREMMULTS}

  TC_CLEANSWEEPCONGRATULATIONS          = 'UKLIZENO! BLAHOPØEJEME!';

  {CFGCMD}

  TC_NETWORKTEST                        = 'Kontrola sítì';
  TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED   = 'Pøekroèen maximální poèet pøipomínek!';
  TC_INVALIDREMINDERTIME                = 'Neplatný èas pøipomínky!';
  TC_INVALIDREMINDERDATE                = 'Neplatné datum pøipomínky!';
  TC_TOOMANYTOTALSCOREMESSAGES          = 'Pøíliš mnoho TOTAL SCORE MSG!';
  TC_THEFIRSTCOMMANDINCONFIGFILEMUSTBE  = 'První údaj v konfiguraèním souboru musí být zadání vlastní znaèky (MY CALL)!';

  {USYNTIME}
  TC_MS                                 = ' ms'; //milisekund

  {ULOGSEARCH}
  TC_ENTRIESPERMS                       = '%u vstupù za %u ms';

  {ULOGCOMPARE}
  TC_SIZEBYTES                          = 'Velikost, bytù';
  TC_RECORDS                            = 'Zápisy';
  TC_MODIFIED                           = 'Upraveno';
  TC_TIMEDIFF                           = 'Èasový rozdíl';

  {POSTUNIT}
  TC_MORETHAN50DIFFERENTHOURSINTHISLOG  = 'Více než 50 rùzných hodinových údajù v tomto deníku!';
  TC_TOOMANYCONTESTDATES                = 'Pøíliš mnoho dat závodu!';

  {UGETSERVERLOG}
  TC_FAILEDTORECEIVESERVERLOG           = 'Pøíjem deníku ze serveru se nezdaøil.';

  {DLPORTIO}
  TC_DLPORTIODRIVERISNOTINSTALLED       = 'Chyba aplikace DLPortIO';

  {UCT1BOH}
  TC_TIMEON                             = 'Èas zapnutí';

  {ULOGCOMPARE}
  TC_SERVERLOG                          = 'DENÍK NA SERVERU';
  TC_LOCALLOG                           = 'MÍSTNÍ DENÍK';

  {UEDITMESSAGE}

  TC_CTRL_A                             = 'Odešli tuto MSG na neaktivní RIG';
  TC_CTRL_B                             = 'Oznaè MSG CTRL-A jako CQ';
  TC_CTRL_C                             = 'Aktivuj speciální pøíkaz';
  TC_CTRL_D                             = 'Nepøerušuj';
  TC_CTRL_E                             = 'Èárka má délku 73% normální hodnoty';
  TC_CTRL_F                             = 'Zvyš rychlost o 6%';
  TC_CTRL_K                             = 'Normální èárka';
  TC_CTRL_L                             = 'Teèka má délku 140% normální hodnoty';
  TC_CTRL_N                             = 'Èárka má délku 113% normální hodnoty';
  TC_CTRL_O                             = 'Èárka má délku 127% normální hodnoty';
  TC_CTRL_P                             = 'Teèka má délku 60% normální hodnoty';
  TC_CTRL_Q                             = 'Teèka má délku 80% normální hodnoty';
  TC_CTRL_S                             = 'Sniž rychlost o 6%';
  TC_CTRL_V                             = 'Teèka má délku 120% normální hodnoty';
  TC_CTRL_X                             = 'Sniž pomìr teèka/mezera o 0.03';
  TC_CTRL_Y                             = 'Zvyš pomìr teèka/mezera o 0.03';
  TC_CTRL_SL                            = 'Normální teèka';
  TC_QSO_NUMBER                         = 'Èíslo QSO';
  TC_SALUTATION_AND_NAME_IF_KNOWN       = 'Pozdrav a jméno (je-li známo)';
  TC_NAME_FROM_NAME_DATABASE            = 'Jméno z databáze';
  TC_SEND_CHARACTERS_FROM_KEYBOARD      = 'Vysílej znaky z klávesnice';
  TC_CALL_IN_CALL_WINDOW                = 'Znaèku do okna znaèky';
  TC_RST_PROMPT                         = 'Nabídka RST';
  TC_SEND_CALLASSETBYMYCALLCOMMAND      = 'Vysílej znaèku podle pøíkazu MY CALL';
  TC_REPEATRSTSENT                      = 'Opakuj vyslané RST';
 {
  TC_HALFSPACE                          = 'Polovièní mezera';
  TC_LASTQSOSCALL                       = 'Znaèka z posledního QSO';
  TC_RECEIVEDNAME                       = 'Pøijaté jméno';
  TC_PARTIALCORRECTEDCALL               = 'Èásteènì opravená znaèka';
  TC_SENDPROPERSALUTATIONWITHOUTNAME    = 'Vysílej správný pozdrav bez jména';
  TC_GOTONEXTBANDLOWERINFREQUENCY       = 'Pøejdi na další nižší pásmo';
  TC_GOTONEXTBANDHIGHERINFREQUENCY      = 'Pøejdi na další vyšší pásmo';
  TC_COMPLETECALLSIGN                   = 'Úplná znaèka';
  TC_FORCESTOENTERCQMODE                = 'Musíš pøejít do módu CQ';
  TC_TOGGLECWENABLE                     = 'Ovladaè CW AKTIVNÍ';
  TC_TURNSOFFMONITORING                 = 'Vypíná pøíposlech CW z reproduktoru PC.';
  TC_TURNSONMONITORING                  = 'Zapíná pøíposlech CW z reproduktoru PC';
  TC_CWENABLETRUE                       = 'CW ENABLE = TRUE';
  TC_CWENABLEFALSE                      = 'CW ENABLE = FALSE';
  TC_WORKSAMEASENTERONKEYBOARD          = 'Shodná funkce jako "ENTER" na klávesnici';
  TC_WORKSAMEASESCONKEYBOARD            = 'Shodná funkce jako "ESC" na klávesnici';
  TC_EXCHANGESTHEFREQUENCIES            = 'Zamìní kmitoèty aktivního a neaktivního RIGu';
  TC_EXECUTEACONFIGURATIONFILE          = 'Spus konfiguraèní soubor';
  TC_MOVESTHERIGTOLASTCQFREQUENCY       = 'Pøeladí na kmitoèet, kde jsi naposled volal CQ';
  TC_LOGSTHELASTCALL                    = 'Zapíše poslední znaèku z okna QSO';
  TC_FORCESTOENTERMODE                  = 'Musíš pøejít do módu SP';
  TC_CHANGESCWSPEEDTOXX                 = 'Zmìní rychlost CW na hodnotu xx';
  TC_SENDSXXTOTHEACTIVERADIO            = 'Vyšle xx na aktivní RIG';
  TC_SENDSXXTOTHERADIO1                 = 'Vyšle xx na RIG 1';
  TC_SENDSXXTOTHERADIO2                 = 'Vyšle xx na RIG 2';
  TC_SENDSXXTOTHEINACTIVERADIO          = 'Vyšle xx na neaktivní RIG';
  TC_SWAPSTHEACTIVEANDINACTIVERIGS      = 'Zamìní aktivní a neaktivní RIG';
  TC_TOGGLESSENDINGSENDING              = 'Pøepne vysílání — vysílání bez pøíposlechu - CW';
  TC_TOGGLESMODEBETWEENCWANDSSB         = 'Zamìní módy CW a SSB';
  TC_RUNXXAPPLICATION                   = 'Spus aplikaci xx';
 }
  {UCHECKLATESTVERSION}
  TC_VERSIONONSERVER                    = 'Poslední verze na serveru je ';
  TC_THISVERSION2                       = 'Aktivní verze je ';
  TC_DOWNLOADIT                         = 'Má se stáhnout poslední verze?';

  TC_LIST_OF_COMMAND                    = '&Seznam pøíkazù';

  RC_VIEWEDITLOG2                       = 'Zobraz / edituj deník';
  RC_CT1BOHIS2                          = 'Zobrazení info CT1BOH';
  RC_BANDPLAN                           = 'Rozdìlení pásem';
  CLOSE_WORD                            = 'Zavøi';
  CANCEL_WORD                           = 'Zruš';
  HELP_WORD                             = 'Nápovìda';
  OK_WORD                               = 'OK';
  EXIT_WORD                             = 'Konec';
  RC_LISTOFMESS                         = 'seznam zpráv';
  RC_STATIONINFO                        = 'Údaje pro záhlaví deníku';
  RC_DUPECHECKOAR                       = 'Kontrola spojení na neaktivním RIGu';

  RC_MEMPROGFUNC                        = 'Funkce programování pamìtí';
  RC_PRESS_C                            = 'Stiskni &C\n pro programování pamìtí v módu CQ.';
  RC_PRESS_E                            = 'Stiskni &E\n pro programování pamìtí v módech EX(change) a S&P.';
  RC_PRESS_O                            = 'Stiskni &O\n pro programování ostatních pamìtí.';

  RC_SENDINGCW                          = 'Vysílá se CW z klávesnice. ENTER/ESC/F10 pro ukonèení.';

  RC_AUTOCQ2                            = 'Auto-CQ';
  RC_PRESSMKYWTR                        = 'Stiskni klávesu pamìti, kterou chceš opakovat:';
  RC_NUMBEROSOLT                        = 'Èas poslechu v milisekundách:';
  RC_WINCONTROL2                        = 'Pøepínání oken';

  RC_TOOLS                              = 'Nástroje';
  RC_SYNPCTIME                          = 'Synchronizuj èas PC';
  RC_BEACONSM                           = 'Monitor majákù';
  RC_WINCONTROL                         = 'Pøepínání oken';
  RC_SETTIMEZONE                        = 'Nastav èasovou zónu';
  RC_PING                               = 'Ping [ADRESA SERVERU]';
  RC_RUNSERVER                          = 'Spus TR4WSERVER';
  RC_DVKVOLCONTROL                      = 'Nastavení hlasitosti DVK';
  RC_RECCONTROL                         = 'Nastavení záznamu';
  RC_SOUNDRECORDER                      = 'Záznam zvuku';
  RC_DISTANCE                           = 'Vzdálenost';
  RC_GRID                               = 'Ètverec (lokátor)';
  RC_CALCULATOR                         = 'Kalkulaèka';
  RC_LC                                 = 'Výpoèet LC';

  RC_GETOFFSET                          = 'Udej rozdíl';
  RC_LOCALOFFSET                        = 'Chyba místních hodin';
  RC_NTPSERVER                          = 'NTP Server';
  RC_SERVERANSWER                       = 'Odpovìï serveru';
  RC_SYNCLOCK                           = 'Synchronizuj hodiny';
  RC_LOCALTIME                          = 'Místní èas';
  RC_TIMESYN                            = 'Synchronizace èasu';
  RC_SEND                               = '&Vyslat';
  RC_POSTNOW                            = 'Pošli teï';
  RC_GOTOGS                             = 'Ukaž skóre';
  RC_MP3_RECENABLE                      = 'spus';

  RC_DELETESELSPOT                      = 'Smaž vybraný spot';
  RC_REMOVEALLSP                        = 'Smaž všechny spoty';
  RC_SENDINRIG                          = 'Nastav neaktivní RIG na kmitoèet';
  RC_FILE                               = 'Soubor';

  RC_CLEARLOG                           = 'Vymaž deník';
  RC_OPENLOGDIR                         = 'Otevøi adresáø deníku';

  RC_OPERATOR                           = 'Operátor';
  RC_CALLSIGN                           = 'Znaèka';
  RC_MODE                               = 'Mód';
  RC_BAND                               = 'Pásmo';
  RC_APPLY                              = '&Použij';
  RC_RESET                              = '&Obnov';
  RC_START                              = 'Start';
  RC_SHOW                               = 'Ukaž';
  RC_SAVE                               = '&Ulož';
  RC_CREATE                             = 'Vytvoø';
  RC_EDIT_WORD                          = 'Edit';
  RC_POSTSCORETOGS                      = 'Poslat skóre';

  RC_NEWCONTEST                         = 'Nový závod';

  RC_EXPORT                             = 'Export';
  RC_INIEXLIST                          = 'Seznam výchozích sout.kódù';
  RC_TRLOGFORM                          = 'Formát TR Log';
  RC_REPORTS                            = 'Reporty';
  RC_ALLCALLS                           = 'Všechny znaèky';
  RC_BANDCHANGES                        = 'Zmìny pásma';
  RC_CONTLIST                           = 'QSO podle kontinentù';
  RC_FCC                                = 'První znaèka v každé zemi';
  RC_FCZ                                = 'První znaèka v každé zónì';
  RC_POSSBADZONE                        = 'Možná chybná zóna';
  RC_QSOBYCOUNTRY                       = 'QSO podle zemí a pásem';
  RC_SCOREBYHOUR                        = 'Skóre po hodinách';
  RC_SUMMARY                            = 'Hlavièka deníku (Cabrillo)';
  RC_EXIT                               = 'Konec';
  RC_SETTINGS                           = 'Nastavení';
//  RC_CFG_COMMANDS                       = 'Konfiguraèní pøíkazy';
  RC_OPTIONS                            = 'Volba konfiguraèních pøíkazù';
  RC_PROGRAMMES                         = 'Programování MSG';
  RC_CATANDCW                           = 'Nastavení RIG, CAT a portù pro CW';
  RC_WINDOWS                            = 'Okna';
  RC_BANDMAP                            = 'Bandmapa';
  RC_DUPESHEET                          = 'Zapsané znaèky';
  RC_FKEYS                              = 'Klávesy pamìtí';
  RC_TRMASTER                           = 'SCP';
  RC_REMMULTS                           = 'Zbývající násobièe';
  RC_RM_DEFAULT                         = 'Výchozí';
  RC_TELNET                             = 'DX Cluster';
  RC_NETWORK                            = 'Sí';
  RC_INTERCOM                           = 'Interkom';
//  RC_GETSCORES                          = 'RC_POSTSCORETOGS""';
  RC_STATIONS                           = 'Pøehled stanic';
  RC_MP3REC                             = 'MP3 rekordér';
  RC_QUICKMEM                           = 'Quick Memory';
  RC_MULTSFREQ                          = 'Kmitoèty pro násobièe';
  RC_ALARM                              = 'Alarm';
  RC_ALTP                               = 'Otevøít F-klávesy';
  RC_ALTX                               = 'Opustit program';
  RC_CTRLJ                              = 'Otevøít konfiguraèní pøíkazy';
  RC_AUTOCQRESUME                       = 'Nastavení Auto-CQ';
  RC_DUPECHECK                          = 'Kontrola opakovaných QSO';
  RC_EDIT                               = 'Editace v oknì QSO';
  RC_SAVETOFLOPPY                       = 'Uložit na disketu';
  RC_SWAPMULTVIEW                       = 'Zmìnit zobrazení násobièù';
  RC_INCNUMBER                          = 'Zvìtšit èíslo o 1';
  RC_TOOGLEMB                           = 'Ovladaè signálu pro násobiè';
  RC_KILLCW                             = 'Blokovat CW';
  RC_SEARCHLOG                          = 'Vyhledat spojení v deníku';
  RC_TRANSFREQ                          = 'Vysílací kmitoèet';
  RC_REMINDER                           = 'Pøipomínka';
  RC_AUTOCQ                             = 'Auto-CQ';
  RC_TOOGLERIGS                         = 'Volba RIG';
  RC_CWSPEED                            = 'Rychlost CW';
  RC_SETSYSDT                           = 'Nastav datum a èas v op.systému';
  RC_INITIALIZE                         = 'Nové zadání QSO';
  RC_RESETWAKEUP                        = 'Resetuj budík';
  RC_DELETELASTQSO                      = 'Smaž poslední QSO';
  RC_INITIALEX                          = 'Výchozí sout.kód';
  RC_TOOGLEST                           = 'Pøíposlech zap./vyp.';
  RC_TOOGLEAS                           = 'AutoSend zap./vyp.';
  RC_BANDUP                             = 'Vyšší pásmo';
  RC_BANDDOWN                           = 'Nižší pásmo';
  RC_SSBCWMODE                          = 'Pøepínaè módu SSB/CW';
  RC_SENDKEYBOARD                       = 'Vstup klíèování z klávesnice';
  RC_COMMWITHPP                         = 'Komunikace via packet radio';
  RC_CLEARDUPES                         = 'Smaž seznam QSO';
  RC_VIEWEDITLOG                        = 'Zobrazit / editovat deník';
  RC_NOTE                               = 'Poznámka';
  RC_MISSMULTSREP                       = 'Pøehled chybìjících násobièù';
  RC_REDOPOSSCALLS                      = 'Zobrazit možné znaèky';
  RC_QTCFUNCTIONS                       = 'Funkce QTC';
  RC_RECALLLASTENT                      = 'Obnovit poslední vstup';
  RC_VIEWPAKSPOTS                       = 'Zobrazit spoty z paket radia';
  RC_EXECONFIGFILE                      = 'Spustit konfiguraèní soubor';
  RC_REFRESHBM                          = 'Obnovit bandmapu';
  RC_DUALINGCQ                          = 'Dvoupásmové CQ (M2T)';
  RC_CURSORINBM                         = 'Pøesunout kurzor do okna bandmapy';
  RC_CURSORTELNET                       = 'Kurzor v oknì DXClusteru';
  RC_QSOWITHNOCW                        = 'QSO bez vysílání CW';
  RC_CT1BOHIS                           = 'Zobrazení CT1BOH info';
  RC_ADDBANDMAPPH                       = 'Vytvoø volné místo v oknì bandmapy';
  RC_COMMANDS                           = 'Pøíkazy';
  RC_FOCUSINMW                          = 'Návrat do hlavního okna';
  RC_TOGGLEINSERT                       = 'Pøepínaè módu INSERT';
  RC_ESCAPE                             = 'ESC';
  RC_CWSPEEDUP                          = 'Zvýšit rychlost CW';
  RC_CWSPEEDDOWN                        = 'Snížit rychlost CW';
  RC_CWSPUPIR                           = 'Zvýšit rychlost CW u neaktivního RIGu';
  RC_CWSPDNIR                           = 'Snížit rychlost CW u neaktivního RIGu';
  RC_CQMODE                             = 'Mód CQ';
  RC_SEARCHPOUNCE                       = 'Mód SP';
  RC_SENDSPOT                           = 'Vyslat spot';
  RC_RESCORE                            = 'Pøepoèítat';

  RC_NET                                = 'Sí';

  RC_SENDMESSAGE                        = 'Vyšli MSG';
  RC_SYNLOG                             = 'Porovnej a synchronizuj deníky';
  RC_CLEARALLLOGS                       = 'Vymaž všechny deníky v síti';
  RC_DOWNLOAD                           = 'Zkus poslední verzi';
  RC_CONTENTS                           = 'Obsah';
  RC_ABOUT                              = 'O programu TR4W';
  RC_CONFFILE                           = 'Konfiguraèní soubor';
  RC_EDITQSO                            = 'Edituj QSO';
  RC_DELETED                            = '&Smazáno';
  RC_DUPE                               = 'duplicitní';
//  RC_LOGSEARCH                          = 'Prohledat deník';
  RC_SEARCH                             = '&Hledání';

//  RC_DUPESHEET2                         = 'Seznam QSO';
//  RC_SENDSPOT2                          = 'Vyšli spot';
  RC_CONTESTNAMEIC                      = 'Název Z&ávodu';
  RC_COMMENT                            = 'Komentáø';
  RC_RETURNTOMOD                        = 'Uprav';
  RC_ARROWTOSELIT                       = 'Vyber akci pomocí prvního písmena, šipkami nebo klávesou PageUp/PageDwn.';
  RC_ALTW                               = 'Ulož (Alt-&W)';
  RC_ALTN                               = 'Do &sítì';
  RC_ALTG                               = 'Ulož vše (Alt-&G)';
  RC_COAX                               = 'Výpoèet délky koax. kabelu';
  RC_ENTERTNHINIK                       = 'Zadej pøíští prùchod nejvyšší impedance nulou v kHz:';
  RC_ENTERALIFIK                        = 'Zadej kmitoèet nejnižší impedance v kHz:';
  RC_DISTANCEBTGS                       = 'Vzdálenost';
  RC_SECONDGRID                         = 'Druhý ètverec (lokátor)';
  RC_FIRSTGRID                          = 'První ètverec (lokátor)';
  RC_EURVHFDIST                         = 'Vzdálenost v EU VHF:';
  RC_GRIDOFAGLL                         = 'Lokátor podle zadané zemìpisné šíøky/délky';
  RC_LONGMIE                            = 'Zemìpisná délka (záporná vých.)';
  RC_LATMIS                             = 'Zemìpisná šíøka (záporná jižnì)';
  RC_CALCOFCORI                         = 'Výpoèet kapacity nebo indukènosti';
  RC_INDUCANCE                          = 'Indukènost, uH';
  RC_CAPACITANCE                        = 'Kapacita, pf';
  RC_FREQOFRES                          = 'Rezonanèní kmitoèet, kHz';

  RC_SHOWMENU                           = '&Zobraz menu';
  RC_RECVQTC                            = 'Pøíjem QTC';
  RC_MIXWINTERFACE                      = 'Rozhraní MixW';
  RC_CONNECTTOMIXW                      = 'Pøipoj k MixW';

//  RC_SYNLOG2                            = 'Synchronizuj deník';
  RC_GETSERVLOG                         = '&Otevøi deník na serveru';
  RC_RECVRECORDS                        = 'Pøijaté záznamy:';
  RC_SENDRECORDS                        = 'Odeslané záznamy:';
  RC_CREATEAUNL                         = '&Vytvoø a použij nový deník';
  RC_RECVBYTES                          = 'Pøijato (Bytù):';
  RC_RECVQSOS                           = 'Pøijato QSO:';
  RC_SHOWSERVLOGC                       = 'Zobraz obsah deníku ze serveru';

//  RC_INTERCOM2                          = 'Interkom';
  RC_DIFFINLOG                          = 'Rozdíly v denících';
  RC_ARCFILTER                          = 'Filtr pásmo-mód ARC spotù';
  RC_DXSFILTER                          = 'Filtr pásmo-mód DXSpideru';
  RC_CLEARFILTER                        = 'Vynuluj filtr';
  RC_STATIONS2                          = 'Stanice';
  RC_C_EDITQSO                          = 'Edituj QSO ';
  RC_C_DELETEQSO                        = 'Smaž QSO';
  RC_COPYTOCLIP                         = 'Kopíruj do schránky';

//  RC_WINKEYSET                          = 'Nastavení pro Winkeyer';
  RC_DATE                               = 'Datum';
  RC_NUMBERSENT                         = 'Vyslané èíslo';
  RC_NUMBERRCVD                         = 'Pøijaté èíslo';
  RC_RSTSENT                            = 'Vyslané RST';
  RC_RSTRECEIVED                        = 'Pøijaté RST';
  RC_QSOPOINTS                          = 'Body za QSO';
  RC_AGE                                = 'Vìk';
  RC_FREQUENCYHZ                        = 'Kmitoèet, Hz';
  RC_PREFIX                             = 'Prefix';
  RC_ZONE                               = 'Zóna';
  RC_NAME                               = 'Jméno';
  RC_POSTALCODE                         = 'PSÈ';
  RC_POWER                              = 'Výkon';
  RC_PROGRMESS                          = 'Programuj MSG';
  RC_MESSAGE                            = 'MSG';
  RC_CAPTION                            = 'Název';
  RC_IAQSLINT                           = 'Zvìtšit interval pro aut.potvrzení';
  RC_DAQSLINT                           = 'Zmenšit interval pro aut.potvrzení';
  RC_ADDINFO                            = 'Další info';
  RC_AI_QSONUMBER                       = 'Èíslo QSO';
  RC_AI_CWSPEED                         = 'Rychlost CW';
  RC_CLEARMSHEET                        = 'Smaž seznam násobièù';
  RC_WIKI                               = 'On-line dokumentace (rusky)';
  RC_NET_CLDUPE                         = 'Smaž seznamy QSO ve všech denících';
  RC_NET_CLMULT                         = 'Smaž seznamy násobièù ve všech denících';
  RC_INC_TIME                           = 'Upravit èas (pøidat):';
  RC_NOTES                              = 'Poznámky';
  RC_DEFAULT                            = 'Výchozí:';
  RC_DESCRIPTION                        = 'Popis:';
  RC_DEVICEMANAGER                      = 'Správce zaøízení (PC)';
  RC_SHDX_CALLSIGN                      = 'SH/DX [znaèka]';

  RC_PLAY                               = '&pøehrávat';

  RC_LOGIN                              = 'pøihlásit';
  RC_SYNCHRONIZE                        = 'Synchronizovat';
  RC_GET_OFFSET                         = 'zadej offset';
  RC_COLORS                             = 'Barvy';
  RC_APPEARANCE                         = 'Podrobnosti';

  RC_WA7BNM_CALENDAR                    = 'Kalendáø závodù WA7BNM';
  RC_SEND_BUG                           = 'odeslat seznam chyb';
  RC_HOMEPAGE                           = 'Domácí stránky TR4W';
  RC_FREQUENCY                          = 'Kmitoèet';
  TC_SPLIT_WARN                         = 'POZOR: Pracujete v režimu SPLIT!';
{FD Additions NY4I}

  TC_IMPROPERTRANSMITTERCOUNT           = 'vysílaèe pøi Field Day musí být mezi 1 až 99.';
  TC_IMPROPERARRLFIELDDAYCLASS          = 'kategorie pøi Field Day musí být A, B, C, D, E nebo F.';
  RC_SPLITOFF                           = 'Vynucený režim Split VYPNUT';
  RC_IMPORT                             = 'Import';
  TC_RUNWARN                            = 'jiná instance TR4W je již spuštìna';
  RC_wkMode                             = 'znovu inicializovat WinKeyer';      // 4.60.1
