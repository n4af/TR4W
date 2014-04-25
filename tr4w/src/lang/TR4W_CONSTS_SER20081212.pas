unit TR4W_CONSTS_SER;

interface

const
  { %s =	A string.}
  { %c =	A single character.}
  { %d =	A signed decimal integer argument.}
  { %u =	An unsigned integer argument.}

  TC_TRANSLATION_LANGUAGE               = 'SERBIAN';
  TC_TRANSLATION_AUTHOR                 = 'Dragan Acimovic YT3W';
  TC_TRANSLATOR_EMAIL                   = 'dragan.acimovic@gmail.com';

  TC_CALLSIGN                           = 'Pozivni nak';
  TC_CHECKCALLSIGN                      = 'Proveri pozivni znak';
  TC_FREQUENCYFORCALLINKHZ              = 'frekvencija za %s u kHz';
  TC_DIFVERSION                         = '%s od druge verzije programa.'#13'TR4W ocekuje verziju %s.'#13'fajl, koji pokusavate da ucitate je verzija %s.';

  TC_M                                  = 'm'; //minute
  TC_S                                  = 's'; //second

  TC_RADIO1                             = 'Stanica 1';
  TC_RADIO2                             = 'Stanica 2';

  {MAIN}

  TC_ISADUPE                            = '%s dupla!!';
  TC_ERRORINLOGFILE                     = 'Greska u LOG fajlu!';
  TC_HASIMPROPERSYNTAX                  = '%s ima nepravilnu sintaksu!!';
  TC_SORRYNOLOG                         = 'Izvinite!! Parametar NO LOG = TRUE zabranjuje upis veza na ovom racunaru';
  TC_SETCOMPUTERIDVALUE                 = 'Podesite vrednost COMPUTER ID';
  TC_CLEARALLLOGS                       = '"CLEARALLLOGS" ocisti sve dnevnike u mrezi';
  TC_REALLYWANTTOCLEARTHELOG            = 'Siguran si da hoces da obrises dnevnik?';
  TC_MESSAGETOSENDVIANETWORK            = 'posalji informaciju preko mreze';
  TC_SENDTIMETOCOMPUTERSONTHENETWORK    = 'Hocete li izvrsiti sinhronizaciju vremena na svim racunarima u mrezi?';
  TC_RULESONSM3CER                      = 'Propozicije takmicenja %s na sajtu SM3CER';
  TC_RULESONQRZRU                       = 'Propozicije takmicenja %s na sajtu QRZ.RU';
  TC_NOTE                               = 'oznaka';
  TC_DUPESHEETCLEARED                   = 'Lista duplih veza je ociscena!';
  TC_YESTOCLEARTHEDUPESHEET             = 'Pritisnite "YES" za ciscenje liste duplih veza';
  TC_TRANSMITFREQUENCYKILOHERTZ         = 'predajna frekvencija (u kHz): ';
  TC_SPRINTQSYRULE                      = 'Pravilo SPRINT QSY!!!';
  TC_PADDLE                             = 'Rucice';
  TC_FOOTSW                             = 'Futsvic';

  TC_LOG_NOTE                           = 'Primedba';
  TC_LOG_DELETED                        = 'Obrisano';

  TC_SUN                                = 'Ned';
  TC_MON                                = 'Pon';
  TC_TUE                                = 'Uto';
  TC_WED                                = 'Sre';
  TC_THU                                = 'Cet';
  TC_FRI                                = 'Pet';
  TC_SAT                                = 'Sub';

  {Ovo je verzija TR4W v.4.009 beta kreirana 2 December 2008. Hocete li proveriti da li imate poslednju verziju ?}
  TC_THISVERSION                        = 'Ovo je verzija ';
  TC_WASBUILDIN                         = ' kreirana ';
  TC_DOYOUWANTTOCHECKTHELATESTVERSION   = 'Hocete li proveriti da li imate poslednju verziju ?';

  {NEW CONTEST}

  TC_OPENCONFIGURATIONFILE              = ' - Otvorite konfiguracioni fajl ili kreirajte konfiguraciju za novo takmicenje';
  TC_FOLDERALREADYEXISTSOVERWRITE       = 'Direktorijum "%s" vec postoji.'#13' Presnimiti ga?';
  TC_IAMIN                              = '&Ja sam u %s';
  TC_NEWENGLANDSTATEABREVIATION         = 'Upisite skracenicu za drzave Nove Engleske(New England)'#13'(ME, NH, VT, MA, CT, RI):';
  TC_ENTERTHEQTHTHATYOUWANTTOSEND       = 'Upisite QTH koji hocete emitovati:';
  TC_ENTERSTATEFORUSPROVINCEFORCANADA   = 'Upisite SAD drzavu, provinciju za Kanadu:';
  TC_ENTERYOUROBLASTID                  = 'Upisite identifikator Vase oblasti:';
  TC_ENTERYOURPROVINCEID                = 'Upisite identifikator Vase provincije:';
  TC_ENTERYOURCOUNTYCODE                = 'Upisite prefiks Vase drzave:';
  TC_ENTERYOURDOK                       = 'Upisite Vas DOK:';
  TC_ENTERYOURDISTRICTABBREVIATION      = 'Upisite skracenicu vaseg reona:';
  TC_ENTERYOURRDAID                     = 'Upisite Vas broj RDA:';
  TC_ENTERYOURIOTAREFERENCEDESIGNATOR   = 'Upisite vasu IOTA:';
  TC_ENTERYOURCITYIDENTIFIER            = 'Upisite identifikator vaseg grada:';
  TC_ENTERYOURNAME                      = 'Upisite Vase ime:';
  TC_ENTERTHELASTTWODIGITSOFTHEYEAR     = 'Upisite poslednja dva broja godine, kada ste prvi put dobili licencu:';
  TC_ENTERYOURZONE                      = 'Upisite vasu zonu:';
  TC_ENTERYOURGEOGRAPHICALCOORDINATES   = 'Upisite vase geografske koordinate'#13'(na primer: 55N37O za Moskvu):';
  TC_ENTERSUMOFYOURAGEANDAMOUNT         = 'Upisite zbir vasih godina i broj godina, koji je prosao od momenta kada ste uradili prvu vezu (na primer: 28+14=42):';
  TC_OZCR                               = 'Upisite troslovnu kombinaciju serijskog broja:';
  TC_ENTERYOURSTATECODE                 = 'Upisite oznaku vase drzave:';
  TC_ENTERYOURFOURDIGITGRIDSQUARE       = 'Upisite prva 4 znaka vaseg lokatora:';
  TC_RFAS                               = 'Upisite vase geografske koordinate (sirina i duzina), zaokruzene do desetine stepena:';
  TC_ENTERYOURSIXDIGITGRIDSQUARE        = 'Upisite ceo lokator:';
  TC_ISLANDSTATION                      = 'Ostrvska stanica';
  TC_ENTERYOURNAMEANDSTATE              = 'Upisite vase ime (i drzavu ako ste u Severnoj Americi):';
  TC_ENTERYOURNAMEANDQTH                = 'Upisite vase ime i QTH (drzavu SAD, kanadsku provinciju ili DX zemlju):';
  TC_ENTERYOURPRECEDENCECHECKSECTION    = 'Upisite vasu podgrupu, vasa provera'#13'(poslednja dva broja godine vase prve licence) i ARRL sekciju:';
  TC_ENTERYOURQTHANDTHENAME             = 'Upisite vas QTH, koji hocete da emitujete'#13'i ime koje koristite:';
  TC_ENTERFIRSTTWODIGITSOFYOURQTH       = 'Upisite prva dva slova vaseg QTH:';
  TC_ENTERYOURAGEINMYSTATEFIELD         = 'Upisite koliko imate godina u polje MY STATE:';
  TC_ENTERYOURQTHORPOWER                = 'Upisite vas QTH, koji hocete da emitujete ako ste u Severnoj Americi ili snagu u polje MY STATE, ako niste:';
  TC_ENTERFIRSTTWOLETTERSOFYOURGRID     = 'Upisite prva dva slova vaseg lokatora:';

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

  {UTELNET}

  TC_TELNET                             = 'Konekcija'#0'Diskonekcija'#0'Komande'#0'Zaustavljanje'#0'Brisanje'#0'Korisnici'#0'100'#0'WWV'#0'Filter'#0;
  TC_YOURNOTCONNECTEDTOTHEINTERNET      = 'Niste konektovani na Internet!';
  TC_GETHOST                            = 'Dobijanje hosta..';
  TC_SERVER                             = 'Server: %s';
  TC_HOST                               = 'Host  : %s';
  TC_CONNECT                            = 'Konektovanje..';
  TC_CONNECTED                          = 'Konektovan';
  TC_YOUARESPOTTEDBYANOTHERSTATION      = 'Spotovala vas je druga stanica.';

  {UNET}

  TC_CONNECTIONTOTR4WSERVERLOST         = 'Konekcija na TR4WSERVER %s:%d izgubljena.';
  TC_COMPUTERCLOCKISSYNCHRONIZED        = 'Vreme na racunaru sinhronizovano.';
  TC_CONNECTINGTO                       = 'Konektujem se na ';
  TC_CONNECTTOTR4WSERVERFAILED          = 'Konekcija na TR4WSERVER nije uspela. Proverite ispravnost LOZINKE SERVERA!!';
  TC_CONNECTEDTO                        = 'Konektovan na ';
  TC_FAILEDTOCONNECTTO                  = 'Konekcija nije uspela na ';
  TC_SERVERANDLOCALLOGSAREIDENTICAL     = 'Dnevnik na serveru i lokalni dnevnik identicni.';
  TC_NETWORK                            = 'Lokalna mreza : %s %s:%d';

  {UGETSCORES}

  TC_FAILEDTOCONNECTTOGETSCORESORG      = 'Konekcija na getscores.org nije uspela (';
  TC_NOANSWERFROMSERVER                 = 'Nema odgovora od servera';
  TC_UPLOADEDSUCCESSFULLY               = 'Podaci predani uspesno.';
  TC_FAILEDTOLOAD                       = 'Predaja podataka nije uspela. Pogledajte GETSCORESANSWER.HTML za detalje.';

  {UBANDMAP}

  TC_SOURCE                             = 'Izvor: %s';
  TC_MIN                                = '%u min.';

  {LOGWIND}

  TC_CQTOTAL                            = 'Ukupno CQ: %u';
  TC_REPEATING                          = 'Ponavljanje %s  Vreme slusanja = %u milisekundama - PgUp/Dn za podesavanje ili ESC za izlaz';
  TC_NEWTOUR                            = 'Nova tura %d/%d';
  TC_ENTER                              = 'Upisi %s :';
  TC_PTS                                = '%d poena';
  TC_RATE                               = 'Rejt: %u';
  TC_LAST60                             = 'Zadnjih 60: %d';
  TC_THISHR                             = 'Ovaj sat: %d';
  TC_HAVEQTCS                           = 'Kod tebe %u QTC';
  TC_INSERT                             = 'Uneti';
  TC_OVERRIDE                           = 'Zamena';
  TC_UNKNOWNCOUNTRY                     = 'Nepoznata zemlja';

  {UCALLSIGNS}

  TC_DUPESHEET                          = 'Lista duplih - %sm-%s';

  {LOGEDIT}

  TC_QSONEEDSFOR                        = ' QSO potreban za %s :';
  TC_MULTNEEDSFOR                       = ' Mnozitelj potreban za %s :';
  TC_MISSINGMULTSREPORT                 = 'Raport o neodradenim mnoziteljima: %u zemalja, po poslednjem sravnjivanju, %u ali ne po svim opsezima.';

  {LOGDUPE}

  TC_THEREWERECALLS                     = 'Nadeno %u pozivnih znakova u fajlu.'#13'+%u duplih';
  TC_RESTARTBINISFORADIFFERENTCONTEST   = 'fajl RESTART.BIN je od drugog takmicenja.';

  {LOGSTUFF}

  TC_NOTENOUGHINFOINEXCHANGE            = 'Nedovoljno informacija o razmenjenom broju!!';
  TC_IMPROPERDOMESITCQTH                = 'Neodgovarajuci QTH!!';
  TC_IMPROPERDOMESITCQTHORMISSINGNAME   = 'Neodgovarajuci QTH ili propusteno ime!!';
  TC_MISSINGQTHANDORNAME                = 'Ispusten QTH i/ili ime!!';
  TC_NOQSONUMBERFOUND                   = 'Nije naden broj QSO!!';

  {LOGSEND}

  TC_WAITINGFORYOUENTERSTRENGTHOFRST    = 'Ocekujem unos jacune signala (S) u RST (Jedan broj)!!';

  {COUNTRY9}

  TC_C9_NORTHAMERICA                    = 'Severna Amerika';
  TC_C9_SOUTHAMERICA                    = 'Juzna Amerika';
  TC_C9_EUROPE                          = 'Evropa';
  TC_C9_AFRICA                          = 'Afrika';
  TC_C9_OCEANIA                         = 'Okeanija';
  TC_C9_ASIA                            = 'Azija';
  TC_C9_UNKNOWN                         = 'Nepoznato';

  {USTATIONS}

  TC_STATIONSINMODE                     = 'Stanica u %s rezimu';

  {USPOTS}

  TC_SPOTS                              = '%d spot(ova)';

  {uSendKeyboard}

  TC_SENDINGSSBWAVFILENAME              = 'Predaja SSB .wav ime fajla. Koristite ENTER za emitovanje fajla, Escape/F10 za prekid.';

  {QTC}

  TC_WASMESSAGENUMBERCONFIRMED          = 'Koji broj poruke %u potvrdujete?';
  TC_DOYOUREALLYWANTSTOPNOW             = 'Da li zelite da prekinete sada?';
  TC_QTCABORTEDBYOPERATOR               = 'QTC prekinut od strane operatora.';
  TC_DOYOUREALLYWANTTOABORTTHISQTC      = 'Da li zelite da prekinete ovaj QTC?';
  TC_NEXT                               = '< Sledeci';
  TC_QTC_FOR                            = '%s za %s';
  TC_QTC_CALLSIGN                       = 'Pozivni :';
  TC_ENTERQTCMAXOF                      = 'Unesite QTC #/# (maksimum od %d) :';
  TC_DOYOUREALLYWANTTOSAVETHISQTC       = 'Da li zelite da snimite ovaj QTC?';
  TC_EDITQTCPRESSYESTOEDITQTCORNOTOLOG  = 'Ispraviti QTC? Kliknite na Yes za ispravljanje QTC ili No za upis u LOG ';
  TC_CHECKQTCNUMBER                     = 'Provera broja QTC';
  TC_CHECKTIME                          = 'Provera vremena';

  {UOPTION}

  TC_COMMAND                            = 'Komanda';
  TC_VALUE                              = 'Velicina';
  TC_INFO                               = 'Info';
  TC_YOUCANCHANGETHISINYOURCONFIGFILE   = 'To mozete izmeniti samo u konfiguracionom fajlu.';

  {UEDITQSO}

  TC_CHECKDATETIME                      = 'Proverite Datum/Vreme!!';
  TC_SAVECHANGES                        = 'Snimiti izmene?';

  {LOGCW}

  TC_WPMCODESPEED                       = 'Brzina, grupa/min';

  TC_CWMENU                             =
    '# Broj QSO  % ime iz baze  ~ GM/GA/GE  : Predaja CW sa tastature'#13 +
    '[ RST  ^ polupauza  ] ponavljanje predaje RST  @ Sadrzaj prozora pozivnog znaka'#13 +
    '$ GM + ime  | promljeno ime  \ Moj pozivni  } parcijalno ispravljen pozivni'#13 +
    '^F WPM+2  ^S WPM-2  + AR  < SK  = BT  ! SN  & AS  ) pozivni poslednje veze'#13 +
    'Za programiranje specijalnih karaktera, pritisnite i drzite Control-P pa onda F ili S taster.';

  TC_CQFUNCTIONKEYMEMORYSTATUS          = 'Sadrzaj memorije funkcijskih tastera "CQ"';
  TC_EXCHANGEFUNCTIONKEYMEMORYSTATUS    = 'Sadrzaj memorije funkcijskih tastera "Razmena"';
  TC_OTHERCWMESSAGEMEMORYSTATUS         = 'Sadrzaj memorije drugih CW poruka';
  TC_OTHERSSBMESSAGEMEMORYSTATUS        = 'Sadrzaj memorije drugih SSB poruka';
  TC_PRESSCQFUNCTIONKEYTOPROGRAM        = 'Pritisni funkcijski taster "CQ" za programiranje (F1, AltF1, CtrlF1), ili ESCAPE za izlaz) : ';
  TC_PRESSEXFUNCTIONKEYTOPROGRAM        = 'Pritisni funkcijski taster "Razmena" za programiranje (F3-F12, Alt/Ctrl F1-F12) ili ESCAPE za izlaz:';
  TC_NUMBERORLETTEROFMESSAGETOBEPROGRAM = 'Broj ili slovo poruke za programiranje (1-9, A-C, ili ESCAPE za izlaz):';
  TC_F1SETBYTHEMYCALLSTATEMENTINCONFIG  = 'F1 - Podeseno parametrom MY CALL u konfiguracionom fajlu';
  TC_F2SETBYSPEXCHANGEANDREPEATSP       = 'F2 - Podeseno parametrima S&P EXCHANGE i REPEAT S&P EXCHANGE';
  TC_CWDISABLEDWITHALTK                 = 'CW-iskljucen pomocu Alt-K!!  Za ponovno ukljucenje pritisnite Alt-K.';
  TC_VOICEKEYERDISABLEDWITHALTK         = 'Vojskejer iskljucen pomocu Alt-K!!  Za ponovno ukljucenje pritisnite Alt-K.';

  {LOGCFG}

  TC_NOCALLSIGNSPECIFIED                = 'Nije upisan pozivni!!';
  TC_NOFLOPPYFILESAVENAMESPECIFIED      = 'Nije upisano ime fajla za snimanje na disketu!!';
  TC_UNABLETOFIND                       = 'Nemoguce naci %s !!';
  TC_INVALIDSTATEMENTIN                 = 'Neispravna instrukcija u %s !!'#13#13'linija %u'#13'%s';
  TC_UNABLETOFINDCTYDAT                 = 'Nemoguce naci CTY fajl CTY.DAT!!'#13'Proverite da li se taj fajl nalazi u direktorijumu programa.';
  TC_INVALIDSTATEMENTINCONFIGFILE       = '%s:'#13'Neispravna istrukcija u konfiguracionom fajlu!!'#13#13'linija %u'#13'%s';

  {LOGSUBS1}

  TC_RECORDDVPPRESSESCAPEORRETURNTOSTOP = 'Snimanje DVP. Pritisnite ESCAPE ili RETURN za prekid.';
  TC_ALTRCOMMANDDISABLED                = 'Alt-R komanda iskljucena u liniji Single Radio Mode = True';
  TC_NOCQMESPROGRAMMEDINTOCQMEMORYALTF1 = 'Nije isprogramirana CQ poruka u CQ MEMORY AltF1.';

  {LOGSUBS2}

  TC_WASADUPE                           = '%s je bila dupla.';
  TC_ALTDCOMMANDDISABLED                = 'Alt-D komanda iskljucena saglasno liniji SINGLE RADIO MODE = TRUE';
  TC_YOUHAVERESTOREDTHELASTDELETED      = 'Vratili ste poslednju obrisanu vezu iz dnevnika!!';
  TC_YOUHAVEDELETEDTHELASTLOGENTRY      = 'Obrisali ste poslednju vezu iz dnevnika!! Pritisnite Alt-Y za njeno vracanje.';
  TC_DOYOUREALLYWANTTOEXITTHEPROGRAM    = 'Da li zelite da napustite program?';
  TC_YOUARENOWTALKINGTOYOURPACKETPORT   = 'Sada razgovarate sa portom paketne veze.  Pritisnite Control-B za izlaz.';
  TC_YOUALREADYWORKEDIN                 = 'Vec ste radili sa %s u %s!!';
  TC_ISADUPEANDWILLBELOGGEDWITHZERO     = '%s - ovo je dupla veza i bice upisana u dnevnik sa NULA poena.';
  TC_LOGFILESIZECHECKFAILED             = 'Nemoguce proveriti duzinu fajla dnevnika!!!!';

  {JCTRL2}

  TC_NEWAUTOSAPENABLESENSITIVITYINHZSEC = 'Nova osetljivos autopretrageu Hz/sek)';
  TC_NEWBANDMAPDECAYTIMEMINUTES         = 'Novo vreme obnavljana BANDMAPE (u minutima)';
  TC_NEWBANDMAPGUARDBANDHERTZ           = 'Novo vreme popunjavanja BANDMAPE (u Hz)';
  TC_COMMANDWHICHWILLBESENDATTELNETCON  = 'komanda, koja ce biti poslata pri telnet konekciji';
  TC_YOUCANONLYCHANGETHISWHENCLIENTDISC = 'vi to mozete izmeniti samo tada, kada se klijent odjavi sa servera TR4W.';
  TC_COMPUTERIDAZRETURNNONE             = 'identifikacija racunara (A-Z ili RETURN ako nema)';
  TC_NEWCOUNTRYINFORMATIONFILENAME      = 'novi naziv fajla sa informacijama o novim zemljama';
  TC_NEWCWINCREMENT                     = 'novo povecanje brzine predaje CW poruka (od 1 do 10 znakova/min)';
  TC_NEWCWMONITORTONE                   = 'nova frekvencija tona u zvucniku za CW (0 - bez tona)';
  TC_NEWFARNSWORTHSPEEDCUTINVALUE       = 'nova brzina automatskog snizenja brzine pri predaji';
  TC_NEWFLOPPYFILESAVEFREQUENCY         = 'nova brzina snimanja fajla na disketu';
  TC_SELECTNEWFLOPPYFILESAVENAME        = 'Izabrati novo ime za autosnimanje fajla na disketu';
  TC_FREQPOLLRATEINMS                   = 'brzina proeuzimanja podataka sa uredaja u milisekundama (10-1000)';
  TC_NEWCENTERFORGRIDMAP                = 'novi centar za kartu lokatora';
  TC_RSTOSHOWASSENTINLOG                = 'RS prikazivati u dnevniku kao deo broja';
  TC_RSTTOSHOWASSENTINLOG               = 'RST prikazivati u dnevniku kao deo broja';
  TC_FIELDDAYCLASS                      = 'klasa FILDEJ stanice';
  TC_NEWGRIDSQUARE                      = 'novi lokator';
  TC_NEWVALUEFORMYIOTA                  = 'nova oznaka za MY IOTA';
  TC_NEWMULTIINFOMESSAGE15CHARSMAX      = 'nova poruka u mrezi (15 znakova maks.)';
  TC_ACOMMENTTOSENDWITHEACHSPOT         = 'komentar, koji se predaje sa svakim spotom';
  TC_NEWPTTHOLDCOUNT                    = 'novo vreme aktivacije PTT na TX';
  TC_NEWPADDLEMONITORTONE               = 'novi ton rucica (Hz)';
  TC_NEWPADDLESPEED0TODISABLE           = 'nova brzina kucanja rucicama (0 - iskljuceno)';
  TC_PTTDELAYCOUNT                      = 'vreme kasnjenja PTT';
  TC_KEYBOARDCHARACTERTOUSEFORQUESTION  = 'tastaturni simbol za predaju znaka "?"';
  TC_RADIO1FREQUENCYADDER               = 'pomeranje frekvencije Radio 1';
  TC_RADIO2FREQUENCYADDER               = 'pomeranje frekvencije Radio 2';
  TC_NEWSAYHIRATECUTOFF                 = 'novo vreme brzine predaje pozdrava u zavisnosti od rejta';
  TC_NEWSCPCOUNTRYSTRING                = 'nova vrednost ogranicenja znaka zemlje';
  TC_KEYBOARDCHARACTERTOSTARTSENDING    = 'tastaturni simbol za pocetak predaje';
  TC_NETWORKSERVERADDRESS               = 'adresa mreznog servera';
  TC_NEWSERVERPASSWORD10CHARS           = 'nova lozinka servera (10 karaktera)';
  TC_NETWORKSERVERPORT                  = 'mrezni port servera';
  TC_KEYBOARDCHARACTERTOUSEFORSLASH     = 'tastaturni simbol za /';
  TC_NEWOFFTIMEVALUEMINUTES             = 'nova vrednost vremena za odmor (u minutama)';
  TC_NEWVALUEFORWAKEUPTIMEOUT           = 'nova vrednost alarma';
  TC_NEWWEIGHTVALUE                     = 'vrednost odnosa tacka crta (.5 - 1.5)';

  {TREE}

  TC_ALREADYEXISTSOKAYTODELETE          = '%s vec postoji.'#13#13'Obrisati?';

  {UWINKEY}

  TC_WINKEYERENABLE                     = '&Winkeyer prikljucen';
  TC_AUTOSPACE                          = '&Auto razmak';
  TC_CTSPACING                          = 'C&T razmak';
  TC_SIDETONE                           = '&Tonalitet';
  TC_PADDLESWAP                         = '&Obrni rucice';
  TC_IGNORESPEEDPOT                     = '&Ignorisi brzinu porta';
  TC_WINKEYERPORT                       = 'port Winkeyer-a';
  TC_KEYERMODE                          = 'Rezim tastera';
  TC_SIDETONEFREQ                       = 'Frekvencija tona.';
  TC_IAMBICB                            = 'IAMBIC B';
  TC_IAMBICA                            = 'IAMBIC A';
  TC_ULTIMATIC                          = 'ULTIMATIC';
  TC_BUGMODE                            = 'BUG';
  TC_WEIGHTING                          = 'Uravnjivane';
  TC_DITDAHRATIO                        = 'Odnos Tacka/Crta';
  TC_LEADIN                             = 'Uvo]enje (*10 ms)';
  TC_TAIL                               = 'Pripajanje (*10 ms)';

  {UTOTAL}

  TC_QTCPENDING                         = 'Neisporuceni QTC-i';
  TC_ZONE                               = 'Zona';
  TC_PREFIX                             = 'Prefiksa';
  TC_DXMULTS                            = 'DX mnozitelji';
  TC_OBLASTS                            = 'Oblasti';
  TC_HQMULTS                            = 'HQ mnozitelji';
  TC_QSOS                               = 'Veza';
  TC_CWQSOS                             = 'CW veza';
  TC_SSBQSOS                            = 'SSB veza';
  TC_DIGQSOS                            = 'DIG veza';

  {UALTD}

  TC_ENTERCALLTOBECHECKEDON             = 'Upisite pozivni znak za proveru na %s%s:';

  {LOGGRID}

  TC_ALLSUN                             = 'Dan';
  TC_ALLDARK                            = 'Noc';

  {UMIXW}

  TC_MIXW_CONNECTED                     = 'Prikljucen';
  TC_MIXW_DISCONNECTED                  = 'Iskljucen';

  {LOGWAE}

  TC_INVALIDCALLSIGNINCALLWINDOW        = 'Neispravan pozivni u prozoru za upis!!';
  TC_SORRYYOUALREADYHAVE10QTCSWITH      = 'Izvinite, vec imate 10 QTC sa %s';
  TC_NOQTCSPENDINGQRU                   = 'Nema neisporucenih QTCs, QRU.';
  TC_ISQRVFOR                           = '%s QRV za %s?';

  {UREMMULTS}

  TC_CLEANSWEEPCONGRATULATIONS          = 'Potpuna pobeda!! Cestitamo!!';

  {CFGCMD}

  TC_NETWORKTEST                        = 'Provera mreze';
  TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED   = 'Maksimalni broj podsetnika je iskoriscen!!';
  TC_INVALIDREMINDERTIME                = 'Neispravno vreme podsetnika!!';
  TC_INVALIDREMINDERDATE                = 'Neispravan datum podsetnika!!';
  TC_TOOMANYTOTALSCOREMESSAGES          = 'Previse poruka TOTAL SCORE MESSAGE!!';
  TC_THEFIRSTCOMMANDINCONFIGFILEMUSTBE  = 'Prva linija u konfiguracionom fajlu mora biti MY CALL !!';

    {USYNTIME}
  TC_MS                                 = ' ms'; //milliseconds

  {POSTUNIT}
  TC_MORETHAN50DIFFERENTHOURSINTHISLOG  = 'Vise od 50 razlicitih sati u ovom dnevniku!!';
  TC_TOOMANYCONTESTDATES                = 'Previse datuma u takmicenju!!';

  {UGETSERVERLOG}
  TC_FAILEDTORECEIVESERVERLOG           = 'Nije uspeo prijem dnevnika sa servera.';

  {DLPORTIO}
  TC_DLPORTIODRIVERISNOTINSTALLED       = 'DLPortIO drajver nije instaliran.';

  {UCT1BOH}
  TC_TIMEON                             = 'Pocetno vreme';

  {ULOGSEARCH}
  TC_ENTRIESPERMS                       = '%u unosa na %u ms';

  {ULOGCOMPARE}
  TC_SIZEBYTES                          = 'Velicina, bajta';
  TC_RECORDS                            = 'Zapisi';
  TC_MODIFIED                           = 'Modifikovan';
  TC_TIMEDIFF                           = 'Rzlika vremena.';

  {ULOGCOMPARE}
  TC_SERVERLOG                          = 'Dnevnik na serveru';
  TC_LOCALLOG                           = 'Lokalni dnevnik';

  {JCTRL1}

  {ALL CW MESSAGES CHAINABLE}
  ACC1                                  = 'Sve CW poruke mogu se vezati zajedno';
  ACC2                                  = 'Samo poruke sa ^D na pocetku bice vezane';

  {ALLOW AUTO UPDATE}
  AAU1                                  = 'Automatski reskor posle ispravljanja dnevnika na serveru';
  AAU2                                  = 'Manuelni reskor posle ispravljanja dnevnika na serveru';

  {ALT-D BUFFER ENABLE}
  ABE1                                  = 'Alt-D popuni podatke za razmenu';
  ABE2                                  = 'Alt-D pitaj ako nema podataka za razmenu';

  {ALWAYS CALL BLIND CQ}
  ABC1                                  = 'EX F7 uvek salje posle CQ EXCHANGE';
  ABC2                                  = 'Besciljni CQ iskljucen';

  {ASK FOR FREQUENCIES}
  AFF1                                  = 'Pitaj za bandmap frekvencije ako nema interfejsa';
  AFF2                                  = 'Ne pitaj za bandmap frekvencije';

implementation

end.

