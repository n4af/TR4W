const
  { %s =	A string.}
  { %c =	A single character.}
  { %d =	A signed decimal integer argument.}
  { %u =	An unsigned integer argument.}

  TC_TRANSLATION_LANGUAGE               = 'ROMANIAN';
  TC_TRANSLATION_AUTHOR                 = 'Suli Iulius YO2IS';

  TC_CALLSIGN                           = 'Indicativ';
  TC_BAND                               = 'Banda';
  TC_FREQ                               = 'Frecv';
  TC_DATE                               = 'Data';
  TC_POINTS                             = 'Pct';
  TC_OP                                 = 'Opr';
  TC_NAME                               = 'Nume';

  TC_CHECKCALLSIGN                      = 'Verifica indicativ';

  TC_FREQUENCYFORCALLINKHZ              = 'frecventa ptr %s in kHz';
  TC_DIFVERSION                         = '%s este dela o versiune diferita.'#13'TR4W necesita versiunea %s.'#13'Fisierul actual este din versiunea %s.';
  TC_FILE                               = 'Fisier';

  TC_M                                  = 'm'; //minute
  TC_S                                  = 's'; //secunde

  TC_RADIO1                             = 'Statia 1';
  TC_RADIO2                             = 'Statia 2';

  TC_DISBALE_CIV                        = 'Anulati modul "CI-V Transceive" din statia ICOM. Vedeti manualul de utilizare al statiei.';

  {MAIN}
  TC_YOU_ARE_USING_THE_LATEST_VERSION   = 'Utilizati cea mai recenta versiune';
  TC_SET_VALUE_OF_SET_NOW               = 'Setati valoarea lui %s. Setati acum?';
  TC_CONFIGURATION_FILE                 = 'Fisierul de configurare';
  TC_CURRENT_OPERATOR_CALLSIGN          = 'Indicativul operatorului actual';
  TC_APPENDIMPORTEDQSOSTOCURRENTLOG     = 'Concatenez QSO-uri importate la logul actual?';
  TC_QSO_IMPORTED                       = 'QSO-uri importate.';
  TC_ISADUPE                            = '%s este o dublura!!';
  TC_ERRORINLOGFILE                     = 'Eroare in fisierul de log!';
  TC_HASIMPROPERSYNTAX                  = '%s sintaxa incorecta!!';
  TC_SORRYNOLOG                         = 'Regret!! NO LOG = TRUE care interzice logarea QSO-urilor pe acest calculator';
  TC_SETCOMPUTERIDVALUE                 = 'Setati valoarea COMPUTER ID.';

  TC_CLEARALLLOGS                       = '"CLEARALLLOGS" Sterge toate logurile din retea';
  TC_CLEAR_DUPESHEET_NET                = '"CLEARDUPESHEET" Sterge toate filele cu duble din retea';
  TC_CLEAR_MULTSHEET_NET                = '"CLEARMULTSHEET" Sterge toate filele cu multipl din retea';

  TC_REALLYWANTTOCLEARTHELOG            = 'Sunteti sigur ca doriti sa stergeti logul actual?';
  TC_MESSAGETOSENDVIANETWORK            = 'Mesaj de trimis in retea';
  TC_SENDTIMETOCOMPUTERSONTHENETWORK    = 'Doriti sa transmiteti ora la calculatoarele din retea?';
  TC_RULESONSM3CER                      = 'Rules for %s contest on WA7BNM Contest Calendar';
  TC_RULESONQRZRU                       = 'Regulamentul ptr concursul %s este la -QRZ.RU-';
  TC_NOTE                               = 'Nota';
  TC_DUPESHEETCLEARED                   = 'Fila de duble anulata!';
  TC_MULTSHEETCLEARED                   = 'Fila de multipl anulata!';
  TC_YESTOCLEARTHEDUPESHEET             = '"YES" ptr anulat fila de duble';
  TC_CLEARMULTTOCLEARMULTSHEET          = '"CLEARMULT" ptr anulat fila de multip';

  TC_TRANSMITFREQUENCYKILOHERTZ         = 'Frecventa de emisie (kiloHertz): ';
  TC_SPRINTQSYRULE                      = 'REGULA de la -SPRINT QSY-!!!';
  TC_PADDLE                             = 'Cheie bug';
  TC_FOOTSW                             = 'Pedala';
  TC_LOG_NOTE                           = 'NOTA';
  TC_LOG_DELETED                        = 'ANULAT';

  TC_SUN                                = 'Dum';
  TC_MON                                = 'Lun';
  TC_TUE                                = 'Mar';
  TC_WED                                = 'Mie';
  TC_THU                                = 'Joi';
  TC_FRI                                = 'Vin';
  TC_SAT                                = 'Sam';

  {uMP3Recorder}

  TC_LAME_ERROR                         = 'O puteti descarca de la';

  {This version TR4W v.4.009 beta was build in 2 December 2008. Do you want to check the latest version ?}
  TC_THISVERSION                        = 'Ati ';
  TC_WASBUILDIN                         = ' instalat (data realizarii ';
  TC_DOYOUWANTTOCHECKTHELATESTVERSION   = 'Doriti sa gasiti o probabila versione mai recenta a TR4W ?';

  {NEW CONTEST}
  TC_LATEST_CONFIG_FILE                 = 'Cel mai recent fisier de configurare';
  TC_OPENCONFIGURATIONFILE              = ' - Deschideti fisierul de configurare sau incepeti un nou concurs';
  TC_FOLDERALREADYEXISTSOVERWRITE       = 'Directorul "%s" exista deja.'#13'Suprascriem ?';
  TC_IAMIN                              = '& sunt in %s';

  TC_NEWENGLANDSTATEABREVIATION         = 'Introduceti abrevierea statului din New England'#13'(ME, NH, VT, MA, CT, RI):';
  TC_ENTERTHEQTHTHATYOUWANTTOSEND       = 'Introduceti QTH-ul de unde doriti sa transmiteti:';
  TC_ENTERSTATEFORUSPROVINCEFORCANADA   = 'Introduceti statul din U.S., provincia din Canada:';
  TC_ENTERYOUROBLASTID                  = 'Introduceti ID de la oblast-ul propriu:';
  TC_ENTERYOURPROVINCEID                = 'Introduceti ID de la provincia proprie';
  TC_ENTERYOURCOUNTYCODE                = 'Introduceti codul judetului propriu:';
  TC_ENTERYOURDOK                       = 'Introduceti DOK-ul propriu:';
  TC_ENTERYOURDISTRICTABBREVIATION      = 'Introduceti abrevierea districtului propriu:';
  TC_ENTERYOURRDAID                     = 'Introduceti RDA ID propriu:';
  TC_ENTERYOURIOTAREFERENCEDESIGNATOR   = 'Introduceti IOTA Reference Designator:';
  TC_ENTERYOURCITYIDENTIFIER            = 'Introduceti identificatorul orasului:';
  TC_ENTERYOURNAME                      = 'Introduceti numele:';
  TC_ENTERTHELASTTWODIGITSOFTHEYEAR     = 'Introduceti ultimii doi digiti ai anului primei Dvs autorizari in emisie:';
  TC_ENTERYOURZONE                      = 'Introduceti zona proprie:';
  TC_ENTERYOURGEOGRAPHICALCOORDINATES   = 'Introduceti propriile coordonate geografice '#13'(ex: 55N37O ptr Moscova):';
  TC_ENTERSUMOFYOURAGEANDAMOUNT         = 'Introduceti suma dintre varsta Dvs si numarul anilor de la primul QSO (ex: 28+14=42):';
  TC_OZCR                               = 'Introduceti un numar din trei cifre:';
  TC_ENTERYOURSTATECODE                 = 'Introduceti codul tarii Dvs.:';
  TC_ENTERYOURFOURDIGITGRIDSQUARE       = 'Introduceti primi patru digiti din QTH locatorul propriu:';
  TC_RFAS                               = 'Introduceti propriile coordonate geografice:';
  TC_ENTERYOURSIXDIGITGRIDSQUARE        = 'Introduceti QTH locatorul complect cu 6 digiti:';
  TC_ENTERYOURNAMEANDSTATE              = 'Introduceti numele (si statul daca traiti in America de Nord):';
  TC_ENTERYOURNAMEANDQTH                = 'Introduceti numele si QTH-ul(statul US, Provincia canadiana sau entitatea DX) sau un numar de membru:';
  TC_ENTERYOURPRECEDENCECHECKSECTION    = 'Introduceti prioritatea, cecul'#13'( ultimi doi digiti al anului de autorizare) si sectiunea ARRL:';
  TC_ENTERYOURQTHANDTHENAME             = 'Introduceti QTH-ul pe care doriti sa-l transmiteti'#13'si numele folosit:';
  TC_ENTERFIRSTTWODIGITSOFYOURQTH       = 'Introduceti primi doi digiti ai QTH-ului Dvs.:';
  TC_ENTERYOURAGEINMYSTATEFIELD         = 'Introduceti varsta la rubrica -MY STATE:';
  TC_ENTERYOURQTHORPOWER                = 'Introduceti QTH-ul pe care il transmiteti daca locuiti in America de Nord sau puterea la entitati DXin rubrica -MY STATE:';
  TC_ENTERFIRSTTWOLETTERSOFYOURGRID     = 'Introduceti primele doua litere ale locatorului propriu:';
  TC_ENTERYOURSQUAREID                  = 'Introduceti ID caroului Dvs.:';
  TC_ENTERYOURMEMBERSHIPNUMBER          = 'Introduceti numarul Dvs de membru:';
  TC_ENTERYOURCONTINENT                 = 'Introduceti continentul Dvs (si eventual informatii noi, ID, i.e. SA sau NA/QRP)';
  TC_ENTERYOURCOUNTYORSTATEPOROVINCEDX  = 'Introduceti county daca sunteti in %s stat. Introduceti statul, Provincia canadiana  sau "DX" daca locuiti afara din %s:';
  TC_PREFECTURE                         = 'Introduceti prefectura Dvs:';
  TC_STATIONCLASS                       = 'Introduceti categoria statiei Dvs:';
  TC_AGECALLSIGNAGE                     = 'Introduceti varsta (sau indicativul de la Silent Key cu varsta):';
  TC_DEPARTMENT                         = 'Introduceti departmentul Dvs.:';
  TC_ENTERYOURRDAIDORGRID               = 'Introduceti RDA ID (ptr statii UA1A) si locatorul cu patru digiti:';

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
  TC_RUSSIA                             = 'Rusia';
  TC_UKRAINE                            = 'Ucraina';
  TC_CZECHREPUBLICORINSLOVAKIA          = 'Republica Ceha sau in Slovakia';
  TC_BULGARIA                           = 'Bulgaria';
  TC_ROMANIA                            = 'Romania';
  TC_HUNGARY                            = 'Ungaria';
  TC_BELGIUM                            = 'Belgia';
  TC_NETHERLANDS                        = 'Tarile de Jos';
  TC_STPETERSBURGOBLAST                 = 'St.Petersburg / oblast';
  TC_GERMANY                            = 'Germania';
  TC_UK                                 = 'UK';
  TC_ARKTIKACLUB                        = 'club';
  TC_POLAND                             = 'Polonia';
  TC_KAZAKHSTAN                         = 'Kazahstan';
  TC_ITALY                              = 'Italia';
  TC_SWITZERLAND                        = 'Elvetia';
  TC_HQ                                 = 'HQ (statie HQ)';
  TC_CIS                                = 'CIS';
  TC_SPAIN                              = 'Spania';
  TC_JAPAN                              = 'Japonia';
  TC_CANADA                             = 'Canada';
  TC_FRANCE                             = 'Franta';
  TC_HQ_OR_MEMBER                       = 'HQ sau membru';

  {UTELNET}

  TC_TELNET                             = 'Conectat'#0'Deconectat'#0'Comenzi'#0'Opreste'#0'Sterge'#0'100'#0#0;
  TC_YOURNOTCONNECTEDTOTHEINTERNET      = 'NU SUNTETI CONECTAT LA INTERNET!';
  TC_GETHOST                            = 'CAUTA HOST..';
  TC_SERVER                             = 'SERVER: %s';
  TC_HOST                               = 'HOST  : %s';
  TC_CONNECT                            = 'CONECTEAZA..';
  TC_CONNECTED                          = 'CONECTAT';
  TC_YOUARESPOTTEDBYANOTHERSTATION      = 'Sunteti postat de o alta statie.';

  {UNET}

  TC_CONNECTIONTOTR4WSERVERLOST         = 'Conectiune catre TR4WSERVER %s:%d esuata.';
  TC_COMPUTERCLOCKISSYNCHRONIZED        = 'Ceasul calculatorului este sincronizat.';
  TC_CONNECTINGTO                       = 'Conectez pe ';
  TC_CONNECTTOTR4WSERVERFAILED          = 'Conectiunea spre TR4WSERVER esuata. Verificati valoarea la SERVER PASSWORD!!';
  TC_CONNECTEDTO                        = 'Conectat la ';
  TC_FAILEDTOCONNECTTO                  = 'Conectare esuata la ';
  TC_SERVERANDLOCALLOGSAREIDENTICAL     = 'Logul local si cel de la Server sunt identice.';
  TC_NETWORK                            = 'Reteaua : %s %s:%d';
  TC_SERVER_LOG_CHANGED                 = 'Log-ul Server este schimbat. %u QSO-uri transferate. Se sincronizeaza logurile (Ctrl+Alt+S).';
  TC_ALL_LOGS_NETWORK_CLEARED           = 'Toate logurile din reteaua TR4W au fost anulate.';

  {UGETSCORES}

  TC_FAILEDTOCONNECTTOGETSCORESORG      = 'Esuata conectarea';
  TC_NOANSWERFROMSERVER                 = 'Serverul nu raspunde';
  TC_UPLOADEDSUCCESSFULLY               = 'Transferat cu succes.';
  TC_FAILEDTOLOAD                       = 'Transfer esuat. Vedeti -getscoresanswer.html- ptr detalii.';

  {UBANDMAP}

  TC_SOURCE                             = 'Sursa: %s';
  TC_MIN                                = '%u min.';

  {LOGWIND}

  TC_CQTOTAL                            = 'CQ total: %u';
  TC_REPEATING                          = 'Repetari %s  Timp de receptie= %u msec - PgUp/Dn ptr ajustare sau ESCAPE';
  TC_NEWTOUR                            = 'Nou tur %d/%d';
  TC_ENTER                              = 'Introduceti %s :';
  TC_PTS                                = '%d Pct';
  TC_RATE                               = 'Rata = %u';
  TC_LAST60                             = 'Ultim 60 = %d';
  TC_THISHR                             = 'Ora asta = %d';
  TC_BAND_CHANGES                       = 'Bnd.sch. = %d';

  TC_HAVEQTCS                           = 'Sunt %u QTC-s';
  TC_INSERT                             = 'INSEREAZA';
  TC_OVERRIDE                           = 'SUPRASCRIE';
  TC_UNKNOWNCOUNTRY                     = 'Entitate necunoscuta';

  {UCALLSIGNS}

  TC_DUPESHEET                          = 'Fila cu duble - %sm-%s';

  {LOGEDIT}

  TC_QSONEEDSFOR                        = ' QSO necesare ptr %s :';
  TC_MULTNEEDSFOR                       = ' Mult necesare ptr %s :';
  TC_MISSINGMULTSREPORT                 = ' Lista cu mult lipsa: %u entitati in ultima ora %u dar nu pe toate benzile.';

  {LOGDUPE}

  TC_THEREWERECALLS                     = 'Sunt acolo %u indicative gasite in fisierul -initial exchange-.'#13'+%u duble';
  TC_RESTARTBINISFORADIFFERENTCONTEST   = 'RESTART.BIN este pentru un alt concurs.';

  {LOGSTUFF}

  TC_NOTENOUGHINFOINEXCHANGE            = 'Insuficiente informatii in control!!';
  TC_IMPROPERDOMESITCQTH                = 'Domestic QTH incorect!!';
  TC_IMPROPERDOMESITCQTHORMISSINGNAME   = 'Domestic QTH incorect sau lipsa nume!!';
  TC_MISSINGQTHANDORNAME                = 'Lipsa QTH si/sau nume!!';
  TC_NOQSONUMBERFOUND                   = 'Lipsa numarul de QSO!!';
  TC_IMPROPERZONENUMBER                 = 'Numar de zona incorect!!';
  TC_SAVINGTO                           = 'Salvez %s pe %s';
  TC_FILESAVEDTOFLOPPYSUCCESSFULLY      = 'Fisier salvat cu succes pe floppy.';
  TC_FILESAVEDTOSUCCESSFULLY            = 'Fisier salvat cu succes pe %s.';

  {LOGSEND}

  TC_WAITINGFORYOUENTERSTRENGTHOFRST    = 'Astept introducerea tariei semnalului RST (Un singur digit)!!';

  {COUNTRY9}

  TC_C9_NORTHAMERICA                    = 'America de Nord';
  TC_C9_SOUTHAMERICA                    = 'America de Sud';
  TC_C9_EUROPE                          = 'Europa';
  TC_C9_AFRICA                          = 'Africa';
  TC_C9_OCEANIA                         = 'Oceania';
  TC_C9_ASIA                            = 'Asia';
  TC_C9_UNKNOWN                         = 'Necunoscut';

  {USTATIONS}

  TC_STATIONSINMODE                     = 'Statiuni in %s mod';

  {USPOTS}

  TC_SPOTS                              = '%d spoturi';

  {uSendKeyboard}

  TC_SENDINGSSBWAVFILENAME              = 'Transmit fisier SSB .wav cu numele. Enter-executie, Escape/F10-iesire.';

  {QTC}

  TC_WASMESSAGENUMBERCONFIRMED          = 'Mesajul cu numarul %u a fost confirmat?';
  TC_DOYOUREALLYWANTSTOPNOW             = 'Doriti intradevar sa oprim acum?';
  TC_QTCABORTEDBYOPERATOR               = 'QTC intrerupt de operator.';
  TC_DOYOUREALLYWANTTOABORTTHISQTC      = 'Doriti intradevar sa renuntati la acest QTC?';
  TC_NEXT                               = '< Urmatorul';
  TC_QTC_FOR                            = '%s ptr %s';
  TC_QTC_CALLSIGN                       = 'Indicativ :';
  TC_ENTERQTCMAXOF                      = 'Introduceti QTC #/# (max din %d) :';
  TC_DOYOUREALLYWANTTOSAVETHISQTC       = 'Doriti intradevar sa salvati acest QTC?';
  TC_EDITQTCPRESSYESTOEDITQTCORNOTOLOG  = 'Editati QTC? Apasati Yes ptr editarea QTC sau No ptr logare ';
  TC_CHECKQTCNUMBER                     = 'Verificati numarul QTC';
  TC_CHECKTIME                          = 'Verificati ora';

  {UOPTION}

  TC_COMMAND                            = 'Comanda';
  TC_VALUE                              = 'Valoarea';
  TC_INFO                               = 'Info';
  TC_YOUCANCHANGETHISINYOURCONFIGFILE   = 'Puteti schimba asta numai in fisierul de configurare.';

  {UEDITQSO}

  TC_CHECKDATETIME                      = 'Verifica Data/Ora !!';
  TC_SAVECHANGES                        = 'Salvez modificarile?';

  {LOGCW}

  TC_WPMCODESPEED                       = 'Viteza CW in WPM';
  TC_CQFUNCTIONKEYMEMORYSTATUS          = 'Statutul mesajelor din memorii de la grupa CQ';
  TC_EXCHANGEFUNCTIONKEYMEMORYSTATUS    = 'Statutul mesajelor din memorii de la grupa EX';
  TC_OTHERCWMESSAGEMEMORYSTATUS         = 'Statutul altor mesaje CW din memorii';
  TC_OTHERSSBMESSAGEMEMORYSTATUS        = 'Statutul altor mesaje SSB din memorii';
  TC_PRESSCQFUNCTIONKEYTOPROGRAM        = 'Apasati -CQ function key- ptr a programa (F1, AltF1, CtrlF1), sau ESCAPE-iesire : ';
  TC_PRESSEXFUNCTIONKEYTOPROGRAM        = 'Apasati -EX function key- ptr a programa (F3-F12, Alt/Ctrl F1-F12) sau ESCAPE-iesire:';
  TC_NUMBERORLETTEROFMESSAGETOBEPROGRAM = 'Numarul sau litera mesajului care doriti sa-l  programati (1-9, A-C) sau ESCAPE-iesire:';
  TC_CWDISABLEDWITHALTK                 = 'CW-ul se dezactiveaza cu Alt-K!! si tot cu Alt-K se reactiveaza';
  TC_VOICEKEYERDISABLEDWITHALTK         = 'Voice keyer se dezactiveaza cu Alt-K!! si tot cu Alt-K se reactiveaza.';

  {LOGCFG}

  TC_NOCALLSIGNSPECIFIED                = 'Lipsa indicativ !!';
  TC_NOFLOPPYFILESAVENAMESPECIFIED      = 'Lipsa nume fisier pentru salvare pe floppy !!';
  TC_UNABLETOFIND                       = 'Nu gasesc %s !!';
  TC_INVALIDSTATEMENTIN                 = 'COMANDA INVALIDA IN %s !!'#13#13'Linia %u'#13'%s';
  TC_UNABLETOFINDCTYDAT                 = 'Nu gasesc fisierul cu entitati CTY.DAT !!'#13'Verificati daca fisierul este in acelasi director cu programul.';
  TC_INVALIDSTATEMENTINCONFIGFILE       = '%s:'#13'COMANDA INVALIDA IN FISIERUL DE CONFIGURARE !!'#13#13' in linia %u'#13'%s';

  {LOGSUBS1}

  TC_RECORDDVPPRESSESCAPEORRETURNTOSTOP = 'Inregistrare DVP. Apasati ESCAPE sau RETURN ptr oprire.';
  TC_ALTRCOMMANDDISABLED                = 'Comanda Alt-R dezactivata de declaratia -Single Radio Mode = True';
  TC_NOCQMESPROGRAMMEDINTOCQMEMORYALTF1 = 'Nu exista mesaj CQ programat in memoria CQ activata cu AltF1.';
  TC_THIS_FILE_DOES_NOT_EXIST           = 'Acest fisier nu exista. Sa creez un fisier nou ptr editare?';

  {LOGSUBS2}

  TC_WASADUPE                           = '%s a fost o dubla.';
  TC_ALTDCOMMANDDISABLED                = 'Comanda Alt-D dezactivata de declaratia -SINGLE RADIO MODE = TRUE';
  TC_YOUHAVERESTOREDTHELASTDELETED      = 'Ati refacut ultimul QSO inscris in log !!';
  TC_YOUHAVEDELETEDTHELASTLOGENTRY      = 'Ati sters ultimul QSO inscris in log !!  Folositi Alt-Y ptr a-l reface.';
  TC_DOYOUREALLYWANTTOEXITTHEPROGRAM    = 'Doriti sigur sa parasiti programul ?';
  TC_YOUARENOWTALKINGTOYOURPACKETPORT   = 'Dvs dialogati cu portul de packet.  Folositi Control-B ptr iesire.';
  TC_YOUALREADYWORKEDIN                 = 'Ati lucrat deja cu %s in %s!!';
  TC_ISADUPEANDWILLBELOGGEDWITHZERO     = '%s este o dubla si va fi trecut in log cu zero puncte/QSO.';
  TC_LOGFILESIZECHECKFAILED             = 'VERIFICAREA MARIMII FISIERULUI DE LOG A ESUAT !!!!';

  {JCTRL2}
  TC_NEWVALUE                           = 'valoare noua';

  {TREE}

  TC_ALREADYEXISTSOKAYTODELETE          = '%s deja exista.'#13#13'De acord cu stergerea ?';

  {UWINKEY}

  TC_WINKEYERENABLE                     = '&Winkeyer activare';
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

  TC_ENTERCALLTOBECHECKEDON             = 'Introduceti indicativul ptr verificare pe %s%s:';

  {LOGGRID}

  TC_ALLSUN                             = 'Zi';
  TC_ALLDARK                            = 'Noapte';

  {UMIXW}

  TC_MIXW_CONNECTED                     = 'Conectat';
  TC_MIXW_DISCONNECTED                  = 'Deconectat';

  {LOGWAE}

  TC_INVALIDCALLSIGNINCALLWINDOW        = 'Indicativ incorect in fereastra call !!';
  TC_SORRYYOUALREADYHAVE10QTCSWITH      = 'Regret, aveti deja 10 QTC-uri cu %s';
  TC_NOQTCSPENDINGQRU                   = 'Fara QTC-uri in curs, QRU.';
  TC_ISQRVFOR                           = 'Este %s QRV ptr %s?';

  {UREMMULTS}

  TC_CLEANSWEEPCONGRATULATIONS          = 'FELICITARI !! O REUSITA MERITATA !!';

  {CFGCMD}

  TC_NETWORKTEST                        = 'Testarea retelei';
  TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED   = 'Depasit numarul maxim de atentionari !!';
  TC_INVALIDREMINDERTIME                = 'Ora de atentionare invalida!!';
  TC_INVALIDREMINDERDATE                = 'Data de atentionare invalida!!';
  TC_TOOMANYTOTALSCOREMESSAGES          = 'Prea multe mesaje TOTAL SCORE!!';
  TC_THEFIRSTCOMMANDINCONFIGFILEMUSTBE  = 'Prima comanda in fisierul de configurare trebuie sa fie MY CALL!!';

  {USYNTIME}
  TC_MS                                 = ' ms'; //millisecunde

  {ULOGSEARCH}
  TC_ENTRIESPERMS                       = '%u accesari in %u ms';

  {ULOGCOMPARE}
  TC_SIZEBYTES                          = 'Marime, bytes';
  TC_RECORDS                            = 'Inregistrare';
  TC_MODIFIED                           = 'Modificat';
  TC_TIMEDIFF                           = 'Diferenta timp.';

  {POSTUNIT}
  TC_MORETHAN50DIFFERENTHOURSINTHISLOG  = 'Mai mult de 50 timpi diferiti in acest log!!';
  TC_TOOMANYCONTESTDATES                = 'Prea multe date de concurs!!';

  {UGETSERVERLOG}
  TC_FAILEDTORECEIVESERVERLOG           = 'Esuat in receptia log-ului de la server.';

  {DLPORTIO}
  TC_DLPORTIODRIVERISNOTINSTALLED       = 'DLPortIO eroare';

  {UCT1BOH}
  TC_TIMEON                             = 'Timp activ';

  {ULOGCOMPARE}
  TC_SERVERLOG                          = 'SERVER LOG';
  TC_LOCALLOG                           = 'LOCAL LOG';

  {UEDITMESSAGE}

  TC_CTRL_A                             = 'Transmite acest mesaj pe radio-ul inactiv';
  TC_CTRL_B                             = 'Identifica ctrl-A ca un mesaj de CQ';
  TC_CTRL_C                             = 'Comanda speciala de Start';
  TC_CTRL_D                             = 'Nu intrerupeti';
  TC_CTRL_E                             = 'Linie la 73% din durata normala';
  TC_CTRL_F                             = 'Mareste viteza cu 6%';
  TC_CTRL_K                             = 'Linie normala';
  TC_CTRL_L                             = 'Punct la 140% din durata normala';
  TC_CTRL_N                             = 'Punct la 113% din durata normala';
  TC_CTRL_O                             = 'Linie la 127% din durata normala';
  TC_CTRL_P                             = 'Punct la  60% din durata normala';
  TC_CTRL_Q                             = 'Punct la  80% din durata normala';
  TC_CTRL_S                             = 'Micsoreaza viteza cu 6%';
  TC_CTRL_V                             = 'Punct la 120% din durata normala';
  TC_CTRL_X                             = 'Micsoreaza raportul cu 0.03';
  TC_CTRL_Y                             = 'Mareste raportul cu 0.03';
  TC_CTRL_SL                            = 'Punct normal';
  TC_QSO_NUMBER                         = 'Numarul QSO-ului';
  TC_SALUTATION_AND_NAME_IF_KNOWN       = 'Salutari si numele daca este cunoscut';
  TC_NAME_FROM_NAME_DATABASE            = 'Numele din baza de date cu nume';
  TC_SEND_CHARACTERS_FROM_KEYBOARD      = 'Transmite caractere din tastatura';
  TC_CALL_IN_CALL_WINDOW                = 'Indicaticul in fereastra Call';
  TC_RST_PROMPT                         = 'RST prompt';
  TC_SEND_CALLASSETBYMYCALLCOMMAND      = 'Transmite indicativul setat in comanada MY CALL';
  TC_REPEATRSTSENT                      = 'Repeta RST-ul transmis';

  TC_HALFSPACE                          = 'Jumatate de spatiu';
  TC_LASTQSOSCALL                       = 'Ultimul QSO cu indicativ''.';
  TC_RECEIVEDNAME                       = 'Nume receptionat';
  TC_PARTIALCORRECTEDCALL               = 'Indicativ partial corectat';
  TC_SENDPROPERSALUTATIONWITHOUTNAME    = 'Transmite salutari adecvate fara nume';
  TC_GOTONEXTBANDLOWERINFREQUENCY       = 'Treci in banda urmatoare mai jos in frecventa';
  TC_GOTONEXTBANDHIGHERINFREQUENCY      = 'Treci in banda urmatoare mai sus in frecventa';
  TC_COMPLETECALLSIGN                   = 'Indicativul complect';
  TC_FORCESTOENTERCQMODE                = 'Forteaza trecerea in modul CQ';
  TC_TOGGLECWENABLE                     = 'Comutator de activare CW';
  TC_TURNSOFFMONITORING                 = 'Deconecteaza monitorizarea CW cu difuzorul calculatorului.';
  TC_TURNSONMONITORING                  = 'Conecteaza minitorizarea CW cu difuzorul calculatorului';
  TC_CWENABLETRUE                       = 'CW ENABLE = TRUE';
  TC_CWENABLEFALSE                      = 'CW ENABLE = FALSE';
  TC_WORKSAMEASENTERONKEYBOARD          = 'Executa o comanda identica cu "ENTER" din tastatura';
  TC_WORKSAMEASESCONKEYBOARD            = 'Executa o comanda identica cu "ESCAPE" din tastatura';
  TC_EXCHANGESTHEFREQUENCIES            = 'Schimba frecventele la statiile active si inactive';
  TC_EXECUTEACONFIGURATIONFILE          = 'Ruleaza un fisier de configurare';
  TC_MOVESTHERIGTOLASTCQFREQUENCY       = 'Muta statia pe ultima frecventa unde ati chemat CQ';
  TC_LOGSTHELASTCALL                    = 'Scrie in log ultimul indicativ aparut in fereastra Call';
  TC_FORCESTOENTERMODE                  = 'Forteaza trecerea in modul S&P';
  TC_CHANGESCWSPEEDTOXX                 = 'Schimba viteza CW la xx';
  TC_SENDSXXTOTHEACTIVERADIO            = 'Transmite xx la Statia activa';
  TC_SENDSXXTOTHERADIO1                 = 'Transmite xx la Statia 1';
  TC_SENDSXXTOTHERADIO2                 = 'Transmite xx la Statia 2';
  TC_SENDSXXTOTHEINACTIVERADIO          = 'Transmite xx la Statia inactiva';
  TC_SWAPSTHEACTIVEANDINACTIVERIGS      = 'Schimba intre ele Statia activa cu cea inactiva';
  TC_TOGGLESSENDINGSENDING              = 'Comuta transmisia cu transmisia fara monitorizarea CW';
  TC_TOGGLESMODEBETWEENCWANDSSB         = 'Comuta modurile CW si SSB';
  TC_RUNXXAPPLICATION                   = 'Ruleaza aplicatia xx ';

  {UCHECKLATESTVERSION}
  TC_VERSIONONSERVER                    = 'Ultima versiune de pe server';
  TC_THISVERSION2                       = 'Aceasta versiune';
  TC_DOWNLOADIT                         = 'Doriti sa descarcati ultima versiune?';

  CLOSE_WORD                            = 'Inchide';
  CANCEL_WORD                           = 'Sterge';
  HELP_WORD                             = 'Ajutor';
  OK_WORD                               = 'OK';
  EXIT_WORD                             = 'Iesire';
  RC_CALLSIGN                           = 'Indicativ';
  RC_MODE                               = 'Mod';
  RC_BAND                               = 'Banda';
  RC_FREQUENCY                          = 'Frecventa';
  RC_APPLY                              = '&Aplica';
  RC_RESET                              = '&Reseteaza';
  RC_START                              = 'Start';
  RC_SHOW                               = 'Afiseaza';
  RC_SAVE                               = '&Salveaza';
  RC_CREATE                             = 'Creaza';
  RC_EDIT_WORD                          = '&Editeaza';
  RC_POSTSCORETOGS                      = 'Expediaza scorul';
  RC_POSTNOW                            = 'Expediaza acum';
  RC_GOTOGS                             = 'Afiseaza scorurile';
  RC_FILE                               = 'Fisier';
  RC_NEWCONTEST                         = 'Concurs nou';
  RC_CLEARLOG                           = 'Sterge log-ul';
  RC_IMPORT                             = 'Importa';
  RC_OPENLOGDIR                         = 'Deschide directorul cu log';
  RC_EXPORT                             = 'Exporta';
  RC_INIEXLIST                          = 'Lista cu schimbarile initiale';
  RC_TRLOGFORM                          = 'TR Log format';
  RC_REPORTS                            = 'Statistici';
  RC_ALLCALLS                           = 'Toate indicativele';
  RC_BANDCHANGES                        = 'Schimbarile de banda';
  RC_CONTLIST                           = 'Lista continentelor';
  RC_FCC                                = 'Primul indicativ lucrat din fiecare entitate';
  RC_FCZ                                = 'Primul indicativ lucrat din fiecare zona';
  RC_POSSBADZONE                        = 'Zona e probabil eronata';
  RC_QSOBYCOUNTRY                       = 'QSO-uri pe entitati si banda';
  RC_SCOREBYHOUR                        = 'Scorul pe ora';
  RC_SUMMARY                            = 'Summarul';
  RC_EXIT                               = 'Iesire';
  RC_SETTINGS                           = 'Setari';
  RC_OPTIONS                            = 'Comenzi de configurare';
  RC_CFG_COMMANDS                       = 'Comenzi de configurare';
  RC_PROGRAMMES                         = 'Mesaje ale programului';
  RC_CATANDCW                           = 'CAT si manipularea CW';
  RC_RADIOONE                           = 'Statia 1';
  RC_RADIOTWO                           = 'Statia 2';
  RC_WINDOWS                            = 'Fereastra';
  RC_BANDMAP                            = 'Harta benzi';
  RC_DUPESHEET                          = 'Fila ptr duble';
  RC_FKEYS                              = 'Taste ptr functii';
  RC_TRMASTER                           = 'Baza de date-SCP';
  RC_REMMULTS                           = 'Multipl restante';
  RC_RM_DEFAULT                         = 'Prestabilit';
  RC_RADIO1                             = 'Statia 1';
  RC_RADIO2                             = 'Statia 2';
  RC_TELNET                             = 'DX Cluster';
  RC_NETWORK                            = 'Retea';
  RC_INTERCOM                           = 'Intercom';
  RC_GETSCORES                          = 'RC_POSTSCORETOGS""';
  RC_STATIONS                           = 'Statiuni';
  RC_MP3REC                             = 'Inregistrare MP3';
  RC_QUICKMEM                           = 'Memorie rapida';
  RC_MULTSFREQ                          = 'Frecventele multipl';
  RC_ALARM                              = 'Alarma';
  RC_AUTOCQRESUME                       = 'Activeaza Auto-CQ';
  RC_DUPECHECK                          = 'Verifica dublele';
  RC_EDIT                               = 'Editeaza';
  RC_SAVETOFLOPPY                       = 'Salveaza pe floppy';
  RC_SWAPMULTVIEW                       = 'Schimba afisarea multipl';
  RC_INCNUMBER                          = 'Incrementeaza numarul';
  RC_TOOGLEMB                           = 'Comuta -beep- la multipl';
  RC_KILLCW                             = 'Opreste CW';
  RC_SEARCHLOG                          = 'Cauta in log';
  RC_TRANSFREQ                          = 'Frecventa de emisie';
  RC_REMINDER                           = 'Atentionare';
  RC_AUTOCQ                             = 'Auto-CQ';
  RC_TOOGLERIGS                         = 'Comuta statiile';
  RC_CWSPEED                            = 'Viteza CW';
  RC_SETSYSDT                           = 'Seteaza data/ora sistemului';
  RC_INITIALIZE                         = 'Initializeaza QSO';
  RC_RESETWAKEUP                        = 'Reseteaza alarma';
  RC_DELETELASTQSO                      = 'Sterge ultimul QSO';
  RC_INITIALEX                          = 'Controlul de inceput';
  RC_TOOGLEST                           = 'Comuta -sidetone-';
  RC_TOOGLEAS                           = 'Comuta -autosend-';
  RC_BANDUP                             = 'Banda in sus';
  RC_BANDDOWN                           = 'Banda in jos';
  RC_SSBCWMODE                          = 'Mod SSB/CW';
  RC_SENDKEYBOARD                       = 'Transmite de la tastatura';
  RC_COMMWITHPP                         = 'Dialog cu portul de packet';
  RC_CLEARDUPES                         = 'Sterge fila cu duble';
  RC_VIEWEDITLOG                        = 'Afiseaza / Editeaza log-ul';
  RC_NOTE                               = 'Nota';
  RC_MISSMULTSREP                       = 'Lipsa statistica multipl';
  RC_REDOPOSSCALLS                      = 'Reciteste posibilele indicative';
  RC_QTCFUNCTIONS                       = 'Functiuni QTC';
  RC_RECALLLASTENT                      = 'Reincarca indicativul ultimului QSO';
  RC_VIEWPAKSPOTS                       = 'Afiseaza spot-uri din packet';
  RC_EXECONFIGFILE                      = 'Executa fisierul de configurare';
  RC_REFRESHBM                          = 'Reincarca Harta benzi';
  RC_DUALINGCQ                          = 'CQ-uri duale';
  RC_CURSORINBM                         = 'Cursor in fereastra Harta benzi';
  RC_CURSORTELNET                       = 'Cursor in fereastra DX Cluster';
  RC_QSOWITHNOCW                        = 'QSO fara CW';
  RC_CT1BOHIS                           = 'CT1BOH pagina info';
  RC_ADDBANDMAPPH                       = 'Activeaza blocarea ptr Harta benzi';
  RC_COMMANDS                           = 'Comenzi';
  RC_FOCUSINMW                          = 'Cursor in fereastra principala';
  RC_TOGGLEINSERT                       = 'Comuta modul de inserare';
  RC_ESCAPE                             = 'Escape';
  RC_CWSPEEDUP                          = 'Viteza CW mai mare';
  RC_CWSPEEDDOWN                        = 'Viteza CW mai mica';
  RC_CWSPUPIR                           = 'Viteza CW mai mare ptr statia inactiva';
  RC_CWSPDNIR                           = 'Viteza CW mai mica ptr statia inactiva';
  RC_CQMODE                             = 'Modul CQ';
  RC_SEARCHPOUNCE                       = 'Modul -Search&Pounce-';
  RC_SENDSPOT                           = 'Trimite spot';
  RC_RESCORE                            = 'Recalculeaza scor';
  RC_TOOLS                              = 'Instrumente';
  RC_SYNPCTIME                          = 'Sincronizeaza ora PC';
  RC_BEACONSM                           = 'Monitorizeaza balizele';
  RC_WINCONTROL                         = 'Control ferestre';
  RC_SETTIMEZONE                        = 'Seteaza zona de timp';
  RC_PING                               = 'Ping [SERVER ADDRESS]';
  RC_RUNSERVER                          = 'Ruleaza TR4WSERVER';
  RC_DVPVOLCONTROL                      = 'DVP control volum';
  RC_RECCONTROL                         = 'Control inregistrare';
  RC_SOUNDRECORDER                      = 'Inregistrare sunet';
  RC_DISTANCE                           = 'Distanta';
  RC_GRID                               = 'Carou';
  RC_CALCULATOR                         = 'Calculator';
  RC_LC                                 = 'LC';
  RC_NET                                = 'Retea';
  RC_TIMESYN                            = 'Sincronizeaza timpul la toate calculatoarele';
  RC_SENDMESSAGE                        = 'Trimite mesaj';
  RC_SYNLOG                             = 'Compara si sincronizeaza logurile';
  RC_CLEARALLLOGS                       = 'Sterge toate logurile din retea';
  RC_DOWNLOAD                           = 'Cauta ultima versiune';
  RC_CONTENTS                           = 'Continut';
  RC_ABOUT                              = 'Despre';
  RC_CONFFILE                           = 'Fisier de configurare';
  RC_EDITQSO                            = 'Editeaza QSO';
  RC_DELETED                            = '&Sters';
  RC_DUPE                               = 'Dubla';
  RC_LOGSEARCH                          = 'Cauta in log';
  RC_SEARCH                             = '&Cauta';
  RC_GETOFFSET                          = '&Gaseste diferenta';
  RC_LOCALOFFSET                        = 'Diferenta ceasului local';
  RC_NTPSERVER                          = 'NTP Server';
  RC_SERVERANSWER                       = 'Raspuns server';
  RC_SYNCLOCK                           = '&Sincronizeaza ceasul';
  RC_LOCALTIME                          = 'Ora locala';
  RC_DUPESHEET2                         = 'Fila cu duble';
  RC_SENDSPOT2                          = 'Trimite spot';
  RC_CONTESTNAMEIC                      = 'Nume concurs in comentar';
  RC_SEND                               = '&Trimite';
  RC_COMMENT                            = 'Comentar';
  RC_SENDINGCW                          = 'Transmit CW din tastatura. Folositi ENTER/Escape/F10 ptr iesire.';
  RC_RETURNTOMOD                        = 'Modifica';
  RC_ARROWTOSELIT                       = 'Selectati cu tastele sageti/pageup/pagedn sau prima litera.';
  RC_ALTW                               = 'Salveaza (Alt-&W)';
  RC_ALTN                               = 'La &retea';
  RC_ALTG                               = 'Salveaza tot (Alt-&G)';
  RC_BANDMAP2                           = 'Harta benzi';
  RC_AUTOCQ2                            = 'CQ-automat';
  RC_PRESSMKYWTR                        = 'Apasati tasta de memorie pe care doriti sa o repetati:';
  RC_NUMBEROSOLT                        = 'Numarul de millisecunde ptr timp receptie:';
  RC_DELETESELSPOT                      = 'Sterge spotul selectat';
  RC_REMOVEALLSP                        = 'Anuleaza toate spoturile';
  RC_SENDINRIG                          = 'Trimite statia inactiva pe frecventa';
  RC_COAX                               = 'Calculator ptr lungimea COAXIAL';
  RC_ENTERTNHINIK                       = 'Introduceti impedanta nula de frecventa superioara in kHz:';
  RC_ENTERALIFIK                        = 'Introduceti o impedanta de frecventa inferioara in kHz:';
  RC_DISTANCEBTGS                       = 'Distanta intre doua carouri';
  RC_SECONDGRID                         = 'Al doilea carou';
  RC_FIRSTGRID                          = 'Primul carou';
  RC_EURVHFDIST                         = 'Distanta VHF in Europa:';
  RC_GRIDOFAGLL                         = 'Carou cu lat/lon cunoscute';
  RC_LONGMIE                            = 'Longitudine (minus spre Est)';
  RC_LATMIS                             = 'Latitudime (minus spre Sud)';
  RC_CALCOFCORI                         = 'Calcularea capacitatii sau inductantei';
  RC_INDUCANCE                          = 'Inductanta, uH';
  RC_CAPACITANCE                        = 'Capacitatea, pF';
  RC_FREQOFRES                          = 'Frecventa de rezonanta, kHz';
  RC_WINCONTROL2                        = 'Windows control';
  RC_SHOWMENU                           = '&Afiseaza menu';
  RC_RECVQTC                            = 'Receptionez QTC-uri';
  RC_MIXWINTERFACE                      = 'MixW Interfata';
  RC_CONNECTTOMIXW                      = 'Conecteaza la MixW';
  RC_MEMPROGFUNC                        = 'Functii ale memoriilor programabile';
  RC_PRESS_C                            = 'Apasa  &C\n  ptr a programa un mesaj la o tasta functie de la CQ.';
  RC_PRESS_E                            = 'Apasa  &E\n  ptr a programa un mesaj la o tatsa functie de la S/P.';
  RC_PRESS_O                            = 'Apasa  &O\n  ptr a programa un mesaj la o tasta fara functie.';
  RC_SYNLOG2                            = 'Sincronizeaza logul';
  RC_GETSERVLOG                         = '&Aduce logul server';
  RC_RECVRECORDS                        = 'Inregistrari primite:';
  RC_SENDRECORDS                        = 'Inregistrari trimise:';
  RC_CREATEAUNL                         = '&Creaza si utilizeaza un log nou';
  RC_RECVBYTES                          = 'Receptionate bytes:';
  RC_RECVQSOS                           = 'Receptionate QSO-uri:';
  RC_SHOWSERVLOGC                       = 'Afiseaza continutul logului server';
  RC_VIEWEDITLOG2                       = 'Afiseaza/Editeaza logul';
  RC_INTERCOM2                          = 'Intercom';
  RC_DIFFINLOG                          = 'Diferenta intre loguri';
  RC_ARCFILTER                          = 'Filtru banda mod -ARC Spots-';
  RC_DXSFILTER                          = 'Filtru banda mod -DXSpider-';
  RC_CLEARFILTER                        = 'Sterge filtrul';
  RC_STATIONS2                          = 'Statiuni';
  RC_C_EDITQSO                          = 'Editeaza QSO ';
  RC_C_DELETEQSO                        = 'Sterge QSO';
  RC_COPYTOCLIP                         = 'Copiaza la -clipboard-';
  RC_DUPECHECKOAR                       = 'Verifica duble la statia inactiva';
  RC_WINKEYSET                          = 'Winkeyer Setari';
  RC_CT1BOHIS2                          = 'CT1BOH pagina info';
  RC_DATE                               = 'Data';
  RC_NUMBERSENT                         = 'Numar Transmis';
  RC_NUMBERRCVD                         = 'Numar Receptionat';
  RC_RSTSENT                            = 'RST transmis';
  RC_RSTRECEIVED                        = 'RST receptionat';
  RC_QSOPOINTS                          = 'Puncte QSO';
  RC_AGE                                = 'Varsta';
  RC_FREQUENCYHZ                        = 'Frecventa, Hz';
  RC_PREFIX                             = 'Prefix';
  RC_ZONE                               = 'Zona';
  RC_NAME                               = 'Nume';
  RC_POSTALCODE                         = 'Cod postal';
  RC_POWER                              = 'Putere';
  RC_PROGRMESS                          = 'Mesaj de la program';
  RC_MESSAGE                            = 'Mesaj';
  RC_CAPTION                            = 'Eticheta';
  RC_IAQSLINT                           = 'Auto QSL Interval (Mareste)';
  RC_DAQSLINT                           = 'Auto QSL Interval (Micsoreaza)';
  RC_ADDINFO                            = 'Informatii suplimentare';
  RC_AI_QSONUMBER                       = 'Numar QSO';
  RC_AI_CALLSIGN                        = 'Indicativ';
  RC_AI_CWSPEED                         = 'Viteza CW';
  RC_AI_BAND                            = 'Banda';
  RC_CLEARMSHEET                        = 'Sterge fila multipl';
  RC_WIKI                               = 'Documetatie On-line (in Rusa)';
  RC_NET_CLDUPE                         = 'Sterge fila de duble din toate logurile';
  RC_NET_CLMULT                         = 'Sterge fila de multipl din toate logurile';
  RC_INC_TIME                           = 'Incrementeaza timpul';
  RC_NOTES                              = 'Notes';
  RC_DEFAULT                            = 'Prestabilit:';
  RC_DESCRIPTION                        = 'Descriere:';
  RC_DEVICEMANAGER                      = 'Device Manager';
  RC_SHDX_CALLSIGN                      = 'SH/DX [indicativ]';
  RC_STATIONINFO                        = 'Informatii cu statia';
  RC_MP3_RECENABLE                      = 'Activeaza';
  RC_PLAY                               = '&Joaca';
  RC_LISTOFMESS                         = 'Lista mesajelor';
  RC_LOGIN                              = 'Logare';
  RC_SYNCHRONIZE                        = 'Sincronizeaza';
  RC_GET_OFFSET                         = 'Gaseste diferenta';
  RC_COLORS                             = 'Culori';
  RC_APPEARANCE                         = 'Prezentare';
  RC_BANDPLAN                           = 'Plan banda';
  RC_WA7BNM_CALENDAR                    = 'Calendar concursuri de la WA7BNM';
  RC_SEND_BUG                           = 'Trimite o nota daca ai probleme';
  RC_HOMEPAGE                           = 'TR4W Home Page';

  RC_OPERATOR                           = 'Operator';
  TC_LIST_OF_COMMAND                    = '&List of commands';
  TC_ENTERYOURBRANCHNUMBER              = 'Enter your Branch number:';
  TC_ENTERYOURPOSTCODE                  = 'Enter your postcode:';

