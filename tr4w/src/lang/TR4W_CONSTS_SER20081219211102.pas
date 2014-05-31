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

  TC_CALLSIGN                           = 'Pozivni znak';
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
  TC_MESSAGETOSENDVIANETWORK            = ' i posalji poruku preko mreze';
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
  TC_ENTERYOURSQUAREID                  = 'Enter your square ID:';

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
  TC_REPEATING                          = 'Ponavljanje %s  Vreme slusanja = %u milisekundi - PgUp/Dn za promenu ili ESC za izlaz';
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
  TC_SAVINGTO                           = 'Saving %s to %s';
  TC_FILESAVEDTOFLOPPYSUCCESSFULLY      = 'File saved to floppy successfully';
  TC_FILESAVEDTOSUCCESSFULLY            = 'File saved to %s successfully';

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
  TC_DOMMULTS                           = 'Dom Mults';
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

  {AUTO CALL TERMINATE}
  ACT1                                  = 'Start exchange when auto CW done';
  ACT2                                  = 'Requires ENTER key before exchange sent';

  {AUTO ALT-D ENABLE}
  AAD1                                  = 'Alt-D window enabled during XMIT';
  AAD2                                  = 'Alt-D window not automatically enabled';

  {AUTO DISPLAY DUPE QSO}
  ADP1                                  = 'Display previous dupes of station';
  ADP2                                  = 'Display previous dupes of station';

  {AUTO DUPE ENABLE CQ}
  ADE1                                  = 'Send QSO BEFORE MESSAGE to dupes';
  ADE2                                  = 'Work and log dupes in CQ mode';

  {AUTO DUPE ENABLE S AND P}
  ADS1                                  = 'Do not call dupes in S&P with RETURN';
  ADS2                                  = 'Call dupes in S&P mode with RETURN';

  {AUTO QSL INTERVAL}
  AQI1                                  = 'Number QSOs that use QUICK QSL message';
  AQI2                                  = 'Always use QSL MESSAGE when QSLing';

  {AUTO QSO NUMBER DECREMENT}
  AQD1                                  = 'If in S&P & blank windows, decrement #';
  AQD2                                  = 'No auto decrement if in S&P & no input';

  {AUTO S&P ENABLE}
  ASP1                                  = 'Jump into S&P mode if tuning VFO';
  ASP2                                  = 'Do not jump into S&P mode when tuning';

  {AUTO S&P ENABLE SENSITIVITY}
  ASR1                                  = 'Auto SAP Enable Sensitivity (Hz/sec)';

  {AUTO RETURN TO CQ MODE}
  ARC1                                  = 'CQ F1 if RETURN in S&P & blank windows';
  ARC2                                  = 'Stay in S&P if RETURN with blank windows';

  {AUTO SEND CHARACTER COUNT}
  ASC1                                  = 'Auto start send feature disabled';
  ASC2                                  = 'Char position where auto CW starts';

  {AUTO TIME INCREMENT}
  ATI1                                  = 'AUTO TIME INCREMENT';
  ATI2                                  = 'Auto time increment disabled';

  {BACKCOPY ENABLE}
  BEN1                                  = 'DVP BackCopy is enabled';
  BEN2                                  = 'DVP BackCopy is disabled';

  {BAND MAP ALL BANDS}
  BAB1                                  = 'All bands shown on band map';
  BAB2                                  = 'Only active band shown on band map';

  {BAND MAP ALL MODES}
  BAM1                                  = 'All modes shown on band map';
  BAM2                                  = 'Only active mode shown on band map';

  {BAND MAP CALL WINDOW ENABLE}
  BCW1                                  = 'Band map blinking call in call window';
  BCW2                                  = 'No band map calls in call window';

  {BAND MAP DECAY TIME}
  BMD1                                  = 'Band map entry decay time (minutes)';

  {BAND MAP DISPLAY CQ}
  BCQ1                                  = 'CQs entered into bandmap';
  BCQ2                                  = 'CQs not entered into bandmap';

  {BAND MAP DUPE DISPLAY}
  BDD1                                  = 'Band map shows all calls - even dupes';
  BDD2                                  = 'Band map does not show dupes';

  {BAND MAP ENABLE}
  BME1                                  = 'Band map enabled';
  BME2                                  = 'Band map display is disabled';

  {BAND MAP GUARD BAND}
  BMG1                                  = 'Blink if freq is within this limit (hz)';

  {BAND MAP SPLIT MODE}
  BSM1                                  = 'Use BandMapCutoffFrequency to set mode.';
  BSM2                                  = 'Split entries always phone mode.';
  {BEEP ENABLE}
  BNA1                                  = 'Beeps enabled';
  BNA2                                  = 'Beeps disabled - computer speaker quiet';

  {BEEP EVERY 10 QSOS}
  BET1                                  = 'Short beep after each 10th QSO';
  BET2                                  = 'No beep to signal each 10th QSO';

  {BROADCAST ALL PACKET DATA}
  BPD1                                  = 'All packet data sent to network';
  BPD2                                  = 'Only spots and talk data to network';

  {CALL WINDOW SHOW ALL SPOTS}
  SAS1                                  = 'All spots shown in call window';
  SAS2                                  = 'Displayed spots shown in call window';

  {CALLSIGN UPDATE ENABLE}
  CAU1                                  = 'Updated calls looked for in exchange';
  CAU2                                  = 'No call updates looked for in exchange';

  {CUSTOM CARET}
  CCA1                                  = 'Custom caret shape';
  CCA2                                  = 'Default caret shape and width';

  {CHECK LOG FILE SIZE}
  CLF1                                  = 'Log file size checked after each QSO';
  CLF2                                  = 'No special checking of log file size';

  {COMPUTER ID}
  CID1                                  = 'No computer ID set (used for multi)';
  CID2                                  = 'Computer ID as shown appears in log';

  {CONFIRM EDIT CHANGES}
  CEC1                                  = 'Prompt for YES when exiting AltE';
  CEC2                                  = 'Save AltE changes without asking if ok';

  {CONNECTION AT STARTUP}
  CAS1                                  = 'Connect to a telnet server at start of the program';

  {CONNECTION COMMAND}
  CCO1                                  = 'Command which will be send at telnet connection';

  {COUNTRY INFORMATION FILE}
  CIF1                                  = 'Name of country information file';

  {CURTIS KEYER MODE}
  CKM1                                  = 'Select desired keyer operation mode';

  {CW ENABLE}
  CWE1                                  = 'CW enabled';
  CWE2                                  = 'CW disabled (except from paddle)';

  {CW SPEED FROM DATABASE}
  CWS1                                  = 'CQ exchange speed in WPM from TRMASTER';
  CWS2                                  = 'Exchange speed from database disabled';

  {CW SPEED INCREMENT}
  CSI1                                  = 'PGUP/PGDN increment from 1 to 10 WPM';

  {CW TONE}
  CWT1                                  = 'Computer speaker CW monitor in Hertz';
  CWT2                                  = 'Computer speaker CW monitor disabled';

  {DE ENABLE}
  DEE1                                  = 'Send DE when calling in S&P mode';
  DEE2                                  = 'No DE sent when calling in S&P mode';

  {DIGITAL MODE ENABLE}
  DIG1                                  = 'CW, DIG and SSB modes enabled';
  DIG2                                  = 'CW and SSB modes enabled';

  {DISTANCE MODE}
  DIS1                                  = 'No display of distance';
  DIS2                                  = 'Distance shown in miles';
  DIS3                                  = 'Distance shown in KM';

  {DUPE SHEET AUTO RESET}
  DAR1                                  = 'Automatical sheet clear';
  DAR2                                  = 'User sheet clear';

  {DUPE CHECK SOUND}
  DCS1                                  = 'SILENT DUPE CHECKING';
  DCS2                                  = 'BEEP IF DUPE WHEN SPACE BAR';
  DCS3                                  = 'BEEP IF DUPE - FANFARE IF MULT';

  {DVP ENABLE}
  DVE1                                  = 'DVP is enabled';
  DVE2                                  = 'DVP is not enabled';

  {ESCAPE EXITS SEARCH AND POUNCE}
  EES1                                  = 'ESCAPE key will exit S&P mode';
  EES2                                  = 'Use SHIFT-TAB to exist S&P mode';

  {EXCHANGE MEMORY ENABLE}
  EME1                                  = 'Exchange memory is enabled';
  EME2                                  = 'Exchange memory is not enabled';

  {FARNSWORTH ENABLE}
  FWE1                                  = 'Expand character spaces < 25 WPM';
  FWE2                                  = 'No expanding of spaces < 25 WPM';

  {FARNSWORTH SPEED}
  FWS1                                  = 'Speed where farnsworth cuts in below';

  {FLOPPY FILE SAVE FREQUENCY}
  FSF1                                  = 'Floppy backups of LOG.DAT are disabled';
  FSF2                                  = 'Number QSOs between saves to floppy';

  {FLOPPY FILE SAVE NAME}
  FSE1                                  = 'File to save to when doing floppy save';

  {FOOT SWITCH MODE}
  FSM1                                  = 'Foot switch sends F1 message';
  FSM2                                  = 'Foot switch disabled';
  FSM3                                  = 'Go to last CQ frequency';
  FSM4                                  = 'Next non dupe band/mode entry in bandmap';
  FSM5                                  = 'Next non dupe displayed band map entry';
  FSM6                                  = 'Next mult band/mode entry in bandmap';
  FSM7                                  = 'Next multiplier displayed band map';
  FSM8                                  = 'Update blinking band map call if one';
  FSM9                                  = 'Do Alt-D dupe check command';
  FSM10                                 = 'Foot switch keys active radio PTT';
  FSM11                                 = 'Acts like pressing ENTER key';
  FSM12                                 = 'Like ENTER key except for Quick QSL msg';
  FSM13                                 = 'Execute Control-Enter function (no cw)';
  FSM14                                 = 'Start sending call in call window on CW';
  FSM15                                 = 'Swaps radios (like Alt-R command)';
  FSM16                                 = 'CW Grant mode - no CW until pressed';

  {FREQUENCY POLL RATE}
  FPR1                                  = 'Rate in ms the radio is polled for freq';

  {FREQUENCY MEMORY ENABLE}
  FME1                                  = 'Remember freqs for each band/mode';
  FME2                                  = 'Do not remember freqs from band/mode';

  {FT1000MP CW REVERSE}
  FCR1                                  = 'FT1000MP / FT920 use CW Reverse mode';
  FCR2                                  = 'FT1000MP / FT920 use normal CW mode';

  {GRID MAP CENTER}
  GMC1                                  = 'No grid map defined';
  GMC2                                  = 'Grid map center location';

  {HF BAND ENABLE}
  HFE1                                  = 'HF Bands enabled';
  HFE2                                  = 'HF Bands no enabled';

  {HOUR DISPLAY}
  HDP1                                  = 'Show # of QSOs in this hour';
  HDP2                                  = 'Show # of QSOs in last 60 minutes';

  {INCREMENT TIME ENABLE}
  ITE1                                  = 'Alt1 to Alt0 keys enabled to bump time';
  ITE2                                  = 'Alt1 to Alt0 keys disabled to bump time';

  {INTERCOM FILE ENABLE}
  IFE1                                  = 'Inter-station messages to INTERCOM.TXT';
  IFE2                                  = 'INTERCOM.TXT file disabled';

  {INITIAL EXCHANGE OVERWRITE}
  IXO1                                  = 'Keystrokes overwrite initial exchange';
  IXO2                                  = 'Keystrokes add to initial exchange';

  {INITIAL EXCHANGE CURSOR POS}
  IEC1                                  = 'Cursor at start of initial exchange';
  IEC2                                  = 'Cursor at end of initial exchange';

  {KEYPAD CW MEMORIES}
  KCM1                                  = 'Numeric keypad sends CQ Ctrl-F1 to F10';
  KCM2                                  = 'Normal function for keypad (no cw)';

  {LEADING ZEROS}
  LDZ1                                  = 'Number leading zeros in serial number';
  LDZ2                                  = 'Leading zeros not sent with serial #s';

  {LEADING ZERO CHARACTER}
  LZC1                                  = 'Used for serial number leading zeros';

  {LEAVE CURSOR IN CALL WINDOW}
  LCI1                                  = 'Cursor stays in call window during QSO';
  LCI2                                  = 'Cursor moves to exchange window for ex';

  {LITERAL DOMESTIC QTH}
  LDQ1                                  = 'Domestic QTHs shown as entered';
  LDQ2                                  = 'Domestic QTHs shown as in .DOM file';

  {LOG FREQUENCY ENABLE}
  LFE1                                  = 'Freq in log instead of QSO number';
  LFE2                                  = 'QSO number in log - not freq';

  {LOG RS SENT}
  LRS1                                  = 'Default SSB report shown in logsheet';
  {LOG RST SENT}
  LRT1                                  = 'Default CW report shown in logsheet';

  {LOG WITH SINGLE ENTER}
  LSE1                                  = 'Log QSOs with first ENTER';
  LSE2                                  = 'Log QSOs with second ENTER';

  {LOOK FOR RST SENT}
  LFR1                                  = 'Look for S579 or S57 in exchange';
  LFR2                                  = 'Do not look for sent RS(T) in exchange';

  {MESSAGE ENABLE}
  MSE1                                  = 'Alt-P O messages enabled';
  MSE2                                  = 'Automatic Alt-P O messages disabled';

  {MISSINGCALLSIGNS FILE ENABLE}
  MCF1                                  = 'Unrecorded callsigns to MISSINGCALLSIGNS.TXT';
  MCF2                                  = 'MISSINGCALLSIGNS.TXT file disabled';

  {MULT REPORT MINIMUM BANDS}
  MRM1                                  = 'Threshold # bands for Control-O report';

  {MULTI INFO MESSAGE}
  MIM1                                  = 'Multi status msg - $=Freq/S&P %=Rate ';

  {MULTI MULTS ONLY}
  MMO1                                  = 'Only mult QSOs are passed to other stns';
  MMO2                                  = 'All QSOs are passed to other stns';

  {MULTI RETRY TIME}
  MRT1                                  = 'Multi network retry time in seconds';

  {MULTI UPDATE MULT DISPLAY}
  MUM1                                  = 'Rem mult display updated from net QSOs';
  MUM2                                  = 'Mults updated when QSO made or band chg';

  {MY CONTINENT}
  MCN1                                  = 'Continent set by MY CALL in cfg file';

  {MY COUNTRY}
  MCU1                                  = 'Country as set by MY CALL';

  {MY FD CLASS}
  MFD1                                  = 'Class for ARRL Field Day';

  {MY GRID}
  MGR1                                  = 'Reference grid used for beam headings';

  {MY IOTA}
  MIO1                                  = 'IOTA Reference Designator';

  {MY ZONE}
  MZN1                                  = 'Set by MY CALL / MY ZONE in cfg file';

  {NAME FLAG ENABLE}
  NFE1                                  = 'Asterisk shows calls with known name';
  NFE2                                  = 'No asterisk to flag known names';

  {NO LOG}
  NLQ1                                  = 'No QSOs can be logged on this computer';
  NLQ2                                  = 'QSOs may be logged on this computer';

  {NO POLL DURING PTT}
  NPP1                                  = 'Interfaced radio not polled when xmit';
  NPP2                                  = 'Interfaced radio polled during xmit';

  {PACKET ADD LF}
  PAL1                                  = 'Line feed added after return for packet';
  PAL2                                  = 'No line feeds added to packet returns';

  {PACKET AUTO CR}
  PAR1                                  = 'Return sent when exiting Control-B';
  PAR2                                  = 'No return sent when exiting Control-B';

  {PACKET BAND SPOTS}
  PBS1                                  = 'Packet spots shown only for active band';
  PBS2                                  = 'All spots shown regardless of band';

  {PACKET BEEP}
  PBP1                                  = 'Beep when packet spots come in';
  PBP2                                  = 'Display incoming spots without beep';

  {PACKET LOG FILENAME}
  PLF1                                  = 'Packet log file disabled';
  PLF2                                  = 'Packet log file enabled to file shown';

  {PACKET RETURN PER MINUTE}
  PRM1                                  = 'Normal packet operation';
  PRM2                                  = 'RETURN sent every %u minutes';

  {PACKET SPOT COMMENT}
  PSC1                                  = 'Comment sent with each packet spot';

  {PACKET SPOT DISABLE}
  PKD1                                  = 'Making spots with ` key is disabled';
  PKD2                                  = 'Making spots with ` key is enabled';

  {PACKET SPOT EDIT ENABLE}
  PSE1                                  = 'Outgoing spots shown for edit';
  PSE2                                  = 'Outgoing spots not shown for edit';

  {PACKET SPOT PREFIX ONLY}
  SPO1                                  = 'Outgoing spot prefix only';
  SPO2                                  = 'Outgoing spot is full call';

  {PACKET SPOTS}
  PSP1                                  = 'All spots from packet are shown';
  PSP2                                  = 'Only multiplier spots are shown';

  {PADDLE BUG ENABLE}
  PBE1                                  = 'Dah contact of paddle = bug';
  PBE2                                  = 'Normal keyer dahs';

  {PADDLE MONITOR TONE}
  PMT1                                  = 'Monitor tone for CW sent with paddle';

  {PADDLE PTT HOLD COUNT}
  PHC1                                  = 'Number dit times before PTT drops out';

  {PADDLE SPEED}
  PSD1                                  = 'Paddle speed same as computer speed';
  PSD2                                  = 'Speed to send paddle CW with';

  {PARTIAL CALL ENABLE}
  PCE1                                  = 'Partial calls will be shown';
  PCE2                                  = 'Partial calls will not be shown';

  {PARTIAL CALL MULT INFO ENABLE}
  PCM1                                  = 'Mult info shown for partial calls';
  PCM2                                  = 'Mult info not shown for partial calls';

  {POSSIBLE CALLS}
  PCA1                                  = 'Possible (unique-1) calls will be shown';
  PCA2                                  = 'Possible (unique-1) calls not shown';

  {POSSIBLE CALL MODE}
  PCN1                                  = 'Show all possible calls';
  PCN2                                  = 'Only show possible calls with names';
  PCN3                                  = 'Only show possible calls from log';

  {PTT LOCKOUT}
  PBL1                                  = 'Network TX lockout is enabled';
  PBL2                                  = 'Network TX lockout is disabled';

  {PTT ENABLE}
  PTT1                                  = 'PTT control signal is enabled';
  PTT2                                  = 'PTT control signal is disabled (QSK)';

  {PTT TURN ON DELAY}
  PTD1                                  = 'PTT delay before CW sent (* 1.0 ms)';

  {PTT VIA COMMANDS}
  PVC1                                  = 'PTT control via CAT commands enabled';
  PVC2                                  = 'PTT control via CAT commands diseabled';

  {QSL MODE}
  QMD1                                  = 'Needs correct info to QSL & log';
  QMD2                                  = 'Needs correct info to log, not to QSL';
  QMD3                                  = 'No syntax checking of exchange';

  {QSO NUMBER BY BAND}
  QNB1                                  = 'Separate QSO numbers sent by band';
  QNB2                                  = 'Total QSOs used for QSO number';

  {QSX ENABLE}
  QSX1                                  = 'QSX info from packet spots enabled';
  QSX2                                  = 'QSX info from packet spots disabled';

  {QTC EXTRA SPACE}
  QES1                                  = 'Add extra spaces when sending QTCs';
  QES2                                  = 'No extra spaces when sending QTCs';

  {QTC QRS}
  QRS1                                  = 'QRS when sending QTCs';
  QRS2                                  = 'No QRS when sending QTCs';

  {QUESTION MARK CHAR}
  QMC1                                  = 'Keyboard character used for ?';

  {RADIO ONE FREQUENCY ADDER}
  R1FA1                                 = 'Amount to add to radio 1 frequency';
  R1FA2                                 = 'No adder to radio 1 frequency';

  {RADIO TWO FREQUENCY ADDER}
  R2FA1                                 = 'Amount to add to radio 1 frequency';
  R2FA2                                 = 'No adder to radio 2 frequency';

  {RANDOM CQ MODE}
  RCQ1                                  = 'Auto CQ picks F1-F4 at random';
  RCQ2                                  = 'Auto CQ works normally';

  {RATE DISPLAY}
  RDS1                                  = 'Rate displays show QSOs';
  RDS2                                  = 'Rate displays show QSO points';
  RDS3                                  = 'Rate for active band only';

  {REMAINING MULT DISPLAY MODE}
  RMD1                                  = 'No remaining mult display';
  RMD2                                  = 'Remaining mult erased when worked';
  RMD3                                  = 'Unworked remaining mults highlighted';

  {SAY HI ENABLE}
  SHE1                                  = 'Name database available to send names';
  SHE2                                  = 'Name sending is disabled';

  {SAY HI RATE CUTOFF}
  SHC1                                  = 'Rate above which name calling will stop';

  {SCP COUNTRY STRING}
  SCS1                                  = 'All SCP calls displayed';
  SCS2                                  = 'Countries that SCP calls displayed';

  {SCP MINIMUM LETTERS}
  SML1                                  = 'Auto Super Check Partial disabled';
  SML2                                  = 'Minimum characters for Auto SCP';

  {SEND ALT-D SPOTS TO PACKET}
  SAD1                                  = 'Alt-D entries sent to packet';
  SAD2                                  = 'Alt-D entries not sent to packet';

  {SEND COMPLETE FOUR LETTER CALL}
  SCF1                                  = 'Send all of 4 letter corrected callsign';
  SCF2                                  = 'Send prefix/suffix of 4 letter calls';

  {SEND QSO IMMEDIATELY}
  SQI1                                  = 'QSO sent to Multi port when logged';
  SQI2                                  = 'QSO sent when scrolled off edit window';

  {SERVER ADDRESS}
  SIA1                                  = '';

  {SERVER PASSWORD}
  SPA1                                  = '';

  {SERVER PORT}
  SEP1                                  = '';

  {SHIFT KEY ENABLE}
  SKE1                                  = 'Shift keys enabled for RIT and S&P QSY';
  SKE2                                  = 'Shift keys disabled for RIT and S&P QSY';

  {SHORT INTEGERS}
  SIN1                                  = 'Short integers used in QSO numbers';
  SIN2                                  = 'No short integers used in QSO numbers';

  {SHOW LOG GRIDLINES}
  SLG1                                  = 'Add lines that separate the items in the log window';
  SLG2                                  = 'TR Log style of the log window';

  {SINGLE RADIO MODE}
  SRM1                                  = 'Swap radio command (Alt-R) disabled';
  SRM2                                  = 'Swap radio command (Alt-R) enabled';

  {SKIP ACTIVE BAND}
  SAB1                                  = 'Alt-B skips active band of other rig';
  SAB2                                  = 'Alt-B doesn''t skip other active band';

  {SLASH MARK CHAR}
  SMC1                                  = 'Keyboard character used for / character';

  {SPACE BAR DUPE CHECK ENABLE}
  SBD1                                  = 'Space does dupe check if call entered';
  SBD2                                  = 'Space always sends call & puts in S&P';

  {SPRINT QSY RULE}
  SQR1                                  = 'After S&P QSO, goes into CQ mode';
  SQR2                                  = 'Stay in S&P mode after S&P QSO';

  {START SENDING NOW KEY}
  SSN1                                  = 'Use a %c key for the sending beginning';
  SSN2                                  = 'Use a SPACE key for the sending beginning';

  {STEREO PIN HIGH}
  SPS1                                  = 'Stereo Control Pin high';
  SPS2                                  = 'Stereo Control Pin low';

  {SWAP PACKET SPOT RADIOS}
  SRP1                                  = 'Radio 1 is left of radio 2';
  SRP2                                  = 'Radio 1 is right of radio 2';

  {SWAP PADDLES}
  SWP1                                  = 'Swap dit and dah paddle connections';
  SWP2                                  = 'Normal dit and dah paddle connections';

  {SWAP RADIO RELAY SENSE}
  SWR1                                  = 'Radio One = 0 volts on relay output';
  SWR2                                  = 'Radio One = 5 volts on relay output';

  {TEN MINUTE RULE}
  TMR1                                  = 'No ten minute display';
  TMR2                                  = 'Show time since first QSO on band/mode';

  {TOTAL OFF TIME}
  TOT1                                  = 'Total off time taken so far';

  {TUNE ALT-D ENABLE}
  TDE1                                  = 'Tuning enables 2nd radio dupe check';
  TDE2                                  = 'Only ALT-D enables 2nd radio dupe check';

  {TUNE WITH DITS}
  TWD1                                  = 'Left Control & Shift keys tune w/dits';
  TWD2                                  = 'Left Control & Shift keys key rig';

  {TWO RADIO MODE}
  TRM1                                  = 'Special two radio mode is enabled';
  TRM2                                  = 'Special two radio mode is disabled';

  {UPDATE RESTART FILE ENABLE}
  URF1                                  = 'RESTART.BIN updated after each QSO';
  URF2                                  = 'RESTART.BIN updated when exiting LOG';

  {USER INFO SHOWN}
  UIS1                                  = 'No user data shown from TRMASTER';
  UIS2                                  = 'Name from TRMASTER';
  UIS3                                  = 'QTH from TRMASTER';
  UIS4                                  = 'Check and ARRL section from TRMASTER';
  UIS5                                  = 'ARRL section from TRMASTER';
  UIS6                                  = 'Previous callsign from TRMASTER';
  UIS7                                  = 'FOC number from TRMASTER';
  UIS8                                  = 'Grid square from TRMASTER';
  UIS9                                  = 'CQ zone from TRMASTER or CTY.DAT';
  UIS10                                 = 'ITU zone from TRMASTER or CTY.DAT';
  UIS11                                 = 'Data from TRMASTER USER %u shown';
  UIS12                                 = 'Use CUSTOM USER STRING';

  {USE RECORDED SIGNS}
  URS1                                  = 'Play recorded letters/ number files';
  URS2                                  = 'Use own voice to send callsigns and serial exchange numbers';

  {VERSION}
  VER1                                  = 'Program version (can''t be changed)';

  {VHF BAND ENABLE}
  VBE1                                  = '6 and 2 meters are enabled';
  VBE2                                  = 'VHF bands skipped with Alt-B or Alt-V';

  {WAIT FOR STRENGTH}
  WFS1                                  = 'If [ in CW message - wait for input';
  WFS2                                  = 'Assume Strength = 9 if CW done with [';

  {WAKE UP TIME OUT}
  WUT1                                  = 'Wake up time out is disabled';
  WUT2                                  = '# minutes without a QSO causing alarm';

  {WARC BAND ENABLE}
  WBE1                                  = 'WARC bands are enabled';
  WBE2                                  = 'WARC bands skipped with Alt-B or Alt-V';

  {WEIGHT}
  WEI1                                  = 'Keying weight';

  {WILDCARD PARTIALS}
  WCP1                                  = 'Calls with partial anywhere are shown';
  WCP2                                  = 'Only calls starting with partial shown';

implementation

end.

