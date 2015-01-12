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

  {uMP3Recorder}

  TC_LAME_ERROR                         = 'You may download it from';

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
  TC_ENTERYOURSQUAREID                  = 'Upisi ID svog lokatora:';

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
  TC_UPLOADEDSUCCESSFULLY               = 'Podaci predati uspesno.';
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
  TC_MULTNEEDSFOR                       = ' mnozitelj potreban za %s :';
  TC_MISSINGMULTSREPORT                 = 'Raport o neodradenim mnoziteljima: %u zemalja, po poslednjem sravnjivanju, %u ali ne po svim opsezima.';

  {LOGDUPE}

  TC_THEREWERECALLS                     = 'Nadjeno %u pozivnih znakova u fajlu.'#13'+%u duplih';
  TC_RESTARTBINISFORADIFFERENTCONTEST   = 'fajl RESTART.BIN je od drugog takmicenja.';

  {LOGSTUFF}

  TC_NOTENOUGHINFOINEXCHANGE            = 'Nedovoljno informacija o razmenjenom broju!!';
  TC_IMPROPERDOMESITCQTH                = 'Neodgovarajuci QTH!!';
  TC_IMPROPERDOMESITCQTHORMISSINGNAME   = 'Neodgovarajuci QTH ili propusteno ime!!';
  TC_MISSINGQTHANDORNAME                = 'Ispusten QTH i/ili ime!!';
  TC_NOQSONUMBERFOUND                   = 'Nije nadjen broj QSO!!';
  TC_SAVINGTO                           = 'Saving %s to %s';
  TC_FILESAVEDTOFLOPPYSUCCESSFULLY      = 'File saved to floppy successfully';
  TC_FILESAVEDTOSUCCESSFULLY            = 'File saved to %s successfully';

  {LOGSEND}

  TC_WAITINGFORYOUENTERSTRENGTHOFRST    = 'Ocekujem unos jacine signala (S) u RST (Jedan broj)!!';

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

  TC_WASMESSAGENUMBERCONFIRMED          = 'Koji broj poruke %u potvrdjujete?';
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
    'Programiranje specijalnih karaktera: pritisnuti i drzati Control-P pa onda F ili S taster.';

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

  TC_RECORDDVPPRESSESCAPEORRETURNTOSTOP = 'Snimanje DVP. Pritisnite ESCAPE ili ENTER za prekid.';
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
  TC_COMPUTERIDAZRETURNNONE             = 'identifikacija racunara (A-Z ili ENTER ako nema)';
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
  TC_FIELDDAYCLASS                      = 'klasa FILDDEJ stanice';
  TC_NEWGRIDSQUARE                      = 'novi lokator';
  TC_NEWVALUEFORMYIOTA                  = 'nova oznaka za MY IOTA';
  TC_NEWMULTIINFOMESSAGE15CHARSMAX      = 'nova poruka u mrezi (15 znakova maks.)';
  TC_ACOMMENTTOSENDWITHEACHSPOT         = 'komentar, koji se predaje sa svakim spotom';
  TC_NEWPTTHOLDCOUNT                    = 'novo vreme aktivacije PTT na TX';
  TC_NEWPADDLEMONITORTONE               = 'novi ton rucica (Hz)';
  TC_NEWPADDLESPEED0TODISABLE           = 'nova brzina kucanja rucicama (0 - iskljuceno)';
  TC_PTTDELAYCOUNT                      = 'vreme kasnjenja PTT';
  TC_KEYBOARDCHARACTERTOUSEFORQUESTION  = 'simbol na tastaturi za "?" karakter';
  TC_RADIO1FREQUENCYADDER               = 'pomeranje frekvencije za Radio 1';
  TC_RADIO2FREQUENCYADDER               = 'pomeranje frekvencije za Radio 2';
  TC_NEWSAYHIRATECUTOFF                 = 'novo vreme brzine predaje pozdrava u zavisnosti od rejta';
  TC_NEWSCPCOUNTRYSTRING                = 'nova vrednost ogranicenja znaka zemlje';
  TC_KEYBOARDCHARACTERTOSTARTSENDING    = 'simbol na tastaturi za pocetak predaje';
  TC_NETWORKSERVERADDRESS               = 'adresa mreznog servera';
  TC_NEWSERVERPASSWORD10CHARS           = 'nova lozinka servera (10 karaktera)';
  TC_NETWORKSERVERPORT                  = 'mrezni port servera';
  TC_KEYBOARDCHARACTERTOUSEFORSLASH     = 'simbol na tastaturi za "/" karakter';
  TC_NEWOFFTIMEVALUEMINUTES             = 'nova vrednost vremena za odmor (u minutama)';
  TC_NEWVALUEFORWAKEUPTIMEOUT           = 'nova vrednost alarma';
  TC_NEWWEIGHTVALUE                     = 'vrednost odnosa tacka crta (.5 - 1.5)';

  {TREE}

  TC_ALREADYEXISTSOKAYTODELETE          = '%s vec postoji.'#13#13'Obrisati?';

  {UWINKEY}

  TC_WINKEYERENABLE                     = 'Ukljuci &Winkeyer';
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
  TC_LEADIN                             = 'Uvodjenje (*10 ms)';
  TC_TAIL                               = 'Pripajanje (*10 ms)';

  {UTOTAL}

  TC_QTCPENDING                         = 'Neisporuceni QTC-i';
  TC_ZONE                               = 'Zona';
  TC_PREFIX                             = 'Prefiksa';
  TC_DXMULTS                            = 'DX mnozitelji';
  TC_OBLASTS                            = 'Oblasti';
  TC_HQMULTS                            = 'HQ mnozitelji';
  TC_DOMMULTS                           = 'Definisanih mnozitelja';
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
  TC_TIMEDIFF                           = 'Razlika vremena.';

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
  ACT1                                  = 'Salanje razmene kad auto CW zavrsi';
  ACT2                                  = 'Zahteva ENTER pre slanja razmene';

  {AUTO ALT-D ENABLE}
  AAD1                                  = 'Alt-D prozor ukljucen za vreme predaje';
  AAD2                                  = 'Alt-D prozor nije automtski ukljucen';

  {AUTO DISPLAY DUPE QSO}
  ADP1                                  = 'Prikazi predhodne duple veze stanice';
  ADP2                                  = 'Prikazi predhodne duple veze stanice';

  {AUTO DUPE ENABLE CQ}
  ADE1                                  = 'Posalji QSO BEFORE MESSAGE za duple';
  ADE2                                  = 'Radi i loguj duple u CQ modu';

  {AUTO DUPE ENABLE S AND P}
  ADS1                                  = 'Ne pozivaj duple u S&P sa ENTER';
  ADS2                                  = 'Pozivaj duple u S&P sa ENTER';

  {AUTO QSL INTERVAL}
  AQI1                                  = 'Broj QSOa kada se koristi QUICK QSL poruka';
  AQI2                                  = 'Uvek koristi QSL MESSAGE kad logujes vezu';

  {AUTO QSO NUMBER DECREMENT}
  AQD1                                  = 'Ako je u S&P & cist prozor, umanji #';
  AQD2                                  = 'Bez auto umanjenja ko je S&P & bez unosa';

  {AUTO S&P ENABLE}
  ASP1                                  = 'Predji u S&P mod ako podesavas VFO';
  ASP2                                  = 'Ne prelazi u S&P mod kada se podesava VFO';

  {AUTO S&P ENABLE SENSITIVITY}
  ASR1                                  = 'Auto S&P ukljucen, osetljivost (Hz/sec)';

  {AUTO RETURN TO CQ MODE}
  ARC1                                  = 'CQ F1 ako je ENTER u S&P modu i cist prozor';
  ARC2                                  = 'Ostani u S&P ako je ENTER sa praznim prozorom';

  {AUTO SEND CHARACTER COUNT}
  ASC1                                  = 'Ne koristi auto CW';
  ASC2                                  = 'Pozicija karaktera odakle auto CW startuje';

  {AUTO TIME INCREMENT}
  ATI1                                  = 'Automatsko uvecanje vremena';
  ATI2                                  = 'Automatsko uvecanje vremena iskljuceno';

  {BACKCOPY ENABLE}
  BEN1                                  = 'DVP rezervna kopija ukljucena';
  BEN2                                  = 'DVP rezervna kopija iskljucena';

  {BAND MAP ALL BANDS}
  BAB1                                  = 'Prikazi sve opsege u band mapi';
  BAB2                                  = 'Samo aktivni band prikazi u band mapi';

  {BAND MAP ALL MODES}
  BAM1                                  = 'Prikazi sve vrste rada u band mapi';
  BAM2                                  = 'Samo aktivnu vrstu rada prikazi u band mapi';

  {BAND MAP CALL WINDOW ENABLE}
  BCW1                                  = 'Trepcuci znak band mape u prozoru znaka';
  BCW2                                  = 'Bez znakova iz band mape u prozoru znaka';

  {BAND MAP DECAY TIME}
  BMD1                                  = 'Vreme trajanja spota u band mapi (minuta)';

  {BAND MAP DISPLAY CQ}
  BCQ1                                  = 'CQ FRQ upisati u band mapu';
  BCQ2                                  = 'Ne upisivati CQ FRQ u band mapu';

  {BAND MAP DUPE DISPLAY}
  BDD1                                  = 'Band mapa prikazuje sve znakove - i duple';
  BDD2                                  = 'Band mapa ne prikazuje duple';

  {BAND MAP ENABLE}
  BME1                                  = 'Band mapa ukljucena';
  BME2                                  = 'Band mapa iskljucena';

  {BAND MAP GUARD BAND}
  BMG1                                  = 'Trepci ako je FRQ preko ovog limita (Hz)';

  {BAND MAP SPLIT MODE}
  BSM1                                  = 'Koristi band map granicne FRQ za podesavanje vrste rada.';
  BSM2                                  = 'Split lista je uvek u SSB modu.';
  {BEEP ENABLE}
  BNA1                                  = 'Zvucni tonovi (Bip) ukljuceni';
  BNA2                                  = 'Zvucni tonovi (Bip) iskljuceni - zvucnik iskljucen';

  {BEEP EVERY 10 QSOS}
  BET1                                  = 'Kratak bip posle svakih 10 veza';
  BET2                                  = 'Bez bipa koji signalizira svaku 10-u vezu';

  {BROADCAST ALL PACKET DATA}
  BPD1                                  = 'Svu podaci sa paketa se salju u mrezu';
  BPD2                                  = 'Samo spotovi i poruke se salju u mrezu';

  {CALL WINDOW SHOW ALL SPOTS}
  SAS1                                  = 'Svi spotovi se prikazuju u prozoru za znak';
  SAS2                                  = 'Prikazani spotovi se prikazuju u prozoru za znak';

  {CALLSIGN UPDATE ENABLE}
  CAU1                                  = 'Razmenu preuzmi iz poslednje odrzane veze';
  CAU2                                  = 'Bez preuzimanja razmene iz ranije odrzane veze';

  {CUSTOM CARET}
  CCA1                                  = 'Custom caret shape';
  CCA2                                  = 'Default caret shape and width';

  {CHECK LOG FILE SIZE}
  CLF1                                  = 'Provera velicine LOGa posle svake veze';
  CLF2                                  = 'Bez provere velicine LOGa';

  {COMPUTER ID}
  CID1                                  = 'Racunar ID nije podesen (koristi se za multi OP)';
  CID2                                  = 'Racunar ID prikazati u LOGu';

  {CONFIRM EDIT CHANGES}
  CEC1                                  = 'Pitaj za YES kada napusta AltE';
  CEC2                                  = 'Snimi AltE promene bez pitanja ako je u redu';

  {CONNECTION AT STARTUP}
  CAS1                                  = 'Konektuj se na telnet server pri startovanju programa';

  {CONNECTION COMMAND}
  CCO1                                  = 'Komanda koja se salje pri telnet konekciji';

  {COUNTRY INFORMATION FILE}
  CIF1                                  = 'Ime datoteke sa informacijama o zemlji';

  {CURTIS KEYER MODE}
  CKM1                                  = 'Izaberi vrstu elektronskog tastera';

  {CW ENABLE}
  CWE1                                  = 'CW ukljucen';
  CWE2                                  = 'CW iskljucen (osim za rucice)';

  {CW SPEED FROM DATABASE}
  CWS1                                  = 'Brzina CQ razmene u WPM iz TRMASTER';
  CWS2                                  = 'Brzina CQ razmene iz baze iskljucena';

  {CW SPEED INCREMENT}
  CSI1                                  = 'PGUP/PGDN inkrementira od 1 do 10 WPM';

  {CW TONE}
  CWT1                                  = 'CW monitor na zvucniku racunara u Hz';
  CWT2                                  = 'CW monitor na zvucniku racunara iskljucen';

  {DE ENABLE}
  DEE1                                  = 'Posalji DE kod poziva u S&P modu';
  DEE2                                  = 'Bez DE kod poziva u S&P modu';

  {DIGITAL MODE ENABLE}
  DIG1                                  = 'CW, DIG i SSB vrsta rada ukljuceni';
  DIG2                                  = 'CW i SSB vrsta rada ukljuceni';

  {DISTANCE MODE}
  DIS1                                  = 'Bez prikaza udaljenosti';
  DIS2                                  = 'Udaljenost prikazivati u miljama';
  DIS3                                  = 'Udaljenost prikazivati u kilometrima';

  {DUPE SHEET AUTO RESET}
  DAR1                                  = 'Automatsko ciscenje liste duplih';
  DAR2                                  = 'Korisnik rucno cisti listu duplih';

  {DUPE CHECK SOUND}
  DCS1                                  = 'Tiha provera duplih veza';
  DCS2                                  = 'Bip ako je dupla kad se pritisne taster za prazno (SPACE)';
  DCS3                                  = 'Bip ako je dupla - fanfare ako je MPL';

  {DVP ENABLE}
  DVE1                                  = 'DVP ukljucen';
  DVE2                                  = 'DVP iskljucen';

  {ESCAPE EXITS SEARCH AND POUNCE}
  EES1                                  = 'ESCAPE taster ulaz u S&P mod';
  EES2                                  = 'Koristi SHIFT-TAB za ulaz S&P mod';

  {EXCHANGE MEMORY ENABLE}
  EME1                                  = 'Memorija sa razmenama ukljucena';
  EME2                                  = 'Memorija sa razmenama iskljucena';

  {FARNSWORTH ENABLE}
  FWE1                                  = 'Povecanje razmaka izmedju karaktera < 25 WPM';
  FWE2                                  = 'Bez povecanja razmaka izmedju karaktera < 25 WPM';

  {FARNSWORTH SPEED}
  FWS1                                  = 'Speed where farnsworth cuts in below';

  {FLOPPY FILE SAVE FREQUENCY}
  FSF1                                  = 'Snimanje LOGa (LOG.DAT) na flopi iskljuceno';
  FSF2                                  = 'Broj veza izmedju snimanja na flopi';

  {FLOPPY FILE SAVE NAME}
  FSE1                                  = 'Ime fajla za snimanje na flopi';

  {FOOT SWITCH MODE}
  FSM1                                  = 'Futsvic salje F1 poruku';
  FSM2                                  = 'Futsvic iskljucen';
  FSM3                                  = 'Idi na poslednju CQ frekvenciju';
  FSM4                                  = 'Sledeca ne dupla opseg/vrsta rada u band mapi';
  FSM5                                  = 'Sledeca ne dupla prikazana u band mapi';
  FSM6                                  = 'Sledeci MPL opseg/vrsta rada u band mapi';
  FSM7                                  = 'Sledeci MPL prikazan u band mapi';
  FSM8                                  = 'Obnovi trpcuci znak  u band mapi ako je jedan';
  FSM9                                  = 'Obavi Alt-D komandu provere duplih';
  FSM10                                 = 'Futsvic na aktivnom uredjaju je PTT';
  FSM11                                 = 'Funkcionisi kao da je pritisnut ENTER taster';
  FSM12                                 = 'Kao ENTER taster osim za brzi QSL';
  FSM13                                 = 'Izvrsi Control-Enter funkciju (loguj bez CW)';
  FSM14                                 = 'Pocni da saljes znak u prozoru za znak na CW';
  FSM15                                 = 'Zameni uredjaje (kao Alt-R komanda)';
  FSM16                                 = 'CW potvrda mod - bez CW dok nema potvrde';

  {FREQUENCY POLL RATE}
  FPR1                                  = 'Preuzimanje FRQ sa radio stanice u ms';

  {FREQUENCY MEMORY ENABLE}
  FME1                                  = 'Zapamti FRQ za svaki opseg/vrstu rada';
  FME2                                  = 'Ne pamti FRQ za svaki opseg/vrstu rada';

  {FT1000MP CW REVERSE}
  FCR1                                  = 'FT1000MP / FT920 koristi CW reverzni mod';
  FCR2                                  = 'FT1000MP / FT920 koristi normalni CW mod';

  {GRID MAP CENTER}
  GMC1                                  = 'Nije definisana mapa lokatora';
  GMC2                                  = 'Centralna lokacija na lokator mapi';

  {HF BAND ENABLE}
  HFE1                                  = 'KT opsezi ukljuceni';
  HFE2                                  = 'KT opsezi iskljuceni';

  {HOUR DISPLAY}
  HDP1                                  = 'Prikaz broja veza u ovom satu';
  HDP2                                  = 'Prikaz broja veza u zadnjih 60 minuta';

  {INCREMENT TIME ENABLE}
  ITE1                                  = 'Alt1 do Alt0 tasteri ukljuceni za promenu vremena';
  ITE2                                  = 'Alt1 do Alt0 tasteri iskljuceni za promenu vremena';

  {INTERCOM FILE ENABLE}
  IFE1                                  = 'Snimaj poruke izmedju stanica u INTERCOM.TXT fajl';
  IFE2                                  = 'INTERCOM.TXT fajl iskljucen';

  {INITIAL EXCHANGE OVERWRITE}
  IXO1                                  = 'Ukucavanje teksta prepisuje inicijalnu razmenu';
  IXO2                                  = 'Ukucavanje teksta se dodaje u inicijalnu razmenu';

  {INITIAL EXCHANGE CURSOR POS}
  IEC1                                  = 'Postavi kursor na pocetak inicijalne razmene';
  IEC2                                  = 'Postavi kursor na kraj inicijalne razmene';

  {KEYPAD CW MEMORIES}
  KCM1                                  = 'Numericka tastatura salje CQ Ctrl-F1 do F10';
  KCM2                                  = 'Numericka tastatura funkcionise normalno (bez CW)';

  {LEADING ZEROS}
  LDZ1                                  = 'Broj nula ispred rednog broja';
  LDZ2                                  = 'Nule se ne salju ispred rednog broja';

  {LEADING ZERO CHARACTER}
  LZC1                                  = 'Karakter za nule ispred rednog broja';

  {LEAVE CURSOR IN CALL WINDOW}
  LCI1                                  = 'Kursor ostaje u prozoru za pozivni znak';
  LCI2                                  = 'Kursor prelazi u prozor za razmenu';

  {LITERAL DOMESTIC QTH}
  LDQ1                                  = 'Definisane MPL prikazi kao sto su upisani';
  LDQ2                                  = 'Definisane MPL prikazi kao u .DOM fajlu';

  {LOG FREQUENCY ENABLE}
  LFE1                                  = 'Upis frekvencije u LOG umesto rednog broja';
  LFE2                                  = 'Upis redni broj u LOG';

  {LOG RS SENT}
  LRS1                                  = 'Podrazumevani SSB raport prikazati u LOGu';
  {LOG RST SENT}
  LRT1                                  = 'Podrazumevani CW raport prikazati u LOGu';

  {LOG WITH SINGLE ENTER}
  LSE1                                  = 'Loguj veza sa prvim ENTERom';
  LSE2                                  = 'Loguj veza sa drugim ENTERom';

  {LOOK FOR RST SENT}
  LFR1                                  = 'Ocekuj S579 ili S57 u razmeni';
  LFR2                                  = 'Ne ocekuj RS(T) u razmeni';

  {MESSAGE ENABLE}
  MSE1                                  = 'Alt-P O poruke ukljucene';
  MSE2                                  = 'Automatske Alt-P O poruke iskljucene';

  {MISSINGCALLSIGNS FILE ENABLE}
  MCF1                                  = 'Ne prepoznate znakove snimi u MISSINGCALLSIGNS.TXT';
  MCF2                                  = 'MISSINGCALLSIGNS.TXT datoteka iskljucena';

  {MULT REPORT MINIMUM BANDS}
  MRM1                                  = 'Granicni broj opsega za Control-O raport';

  {MULTI INFO MESSAGE}
  MIM1                                  = 'Poruka za multi kategoriju - $=Freq/S&P %=Rate ';

  {MULTI MULTS ONLY}
  MMO1                                  = 'Samo MPL veze prosledi ostalim stanicama';
  MMO2                                  = 'Sve veze prosledi ostalim stanicama';

  {MULTI RETRY TIME}
  MRT1                                  = 'Ponovno preuzimanje podataka u mrezi (s)';

  {MULTI UPDATE MULT DISPLAY}
  MUM1                                  = 'Ukloni MPL pri preuzimanju veza sa mreze';
  MUM2                                  = 'MPL obnovi pri sledecoj vezi, promeni opsega';

  {MY CONTINENT}
  MCN1                                  = 'Kontinent podesen sa MY CALL u cfg fajlu';

  {MY COUNTRY}
  MCU1                                  = 'Zemlja podesena sa MY CALL';

  {MY FD CLASS}
  MFD1                                  = 'Klasa za ARRL Fild Dej';

  {MY GRID}
  MGR1                                  = 'Referentni lokator koristi za usmeravanje antene';

  {MY IOTA}
  MIO1                                  = 'Upisi svoju IOTA';

  {MY ZONE}
  MZN1                                  = 'Podeseno sa MY CALL / MY ZONE u cfg fajlu';

  {NAME FLAG ENABLE}
  NFE1                                  = 'Zvezdica pokazuje znakove sa poznatim imenom';
  NFE2                                  = 'Bez zvezdice za obelezavanje poznatog imena';

  {NO LOG}
  NLQ1                                  = 'Veze se NE MOGU snimati na ovaj racunar';
  NLQ2                                  = 'Veze se MOGU snimati na ovaj racunar';

  {NO POLL DURING PTT}
  NPP1                                  = 'Nema preuzimanje podataka sa stanice na predaji';
  NPP2                                  = 'Ima preuzimanje podataka sa stanice na predaji';

  {PACKET ADD LF}
  PAL1                                  = 'Preci u novi red posle ENTER za paket';
  PAL2                                  = 'Ne prelaziti u novi red posle ENTER za paket';

  {PACKET AUTO CR}
  PAR1                                  = 'Posalji ENTER kada izlazis sa Control-B';
  PAR2                                  = 'Ne salji ENTER kada izlazis sa Control-B';

  {PACKET BAND SPOTS}
  PBS1                                  = 'Prikazi spotove samo za aktivni opseg';
  PBS2                                  = 'Prikazi sve spotove bez obzira na opseg';

  {PACKET BEEP}
  PBP1                                  = 'Bip kada stigne spot sa paketa';
  PBP2                                  = 'Prikazi dolazece spotove bez bipa';

  {PACKET LOG FILENAME}
  PLF1                                  = 'Paket log fajl iskljucen';
  PLF2                                  = 'Paket log fajl ukljucen';

  {PACKET RETURN PER MINUTE}
  PRM1                                  = 'Normalna paket operacija';
  PRM2                                  = 'ENTER poslati svakih %u minuta';

  {PACKET SPOT COMMENT}
  PSC1                                  = 'Poslati sledeci komentar sa svakim spotom';

  {PACKET SPOT DISABLE}
  PKD1                                  = 'Posalji spot sa ` tasterom - iskljuceno';
  PKD2                                  = 'Posalji spot sa ` tasterom - ukljuceno';

  {PACKET SPOT EDIT ENABLE}
  PSE1                                  = 'Prikazi odlazni spot za izmenu';
  PSE2                                  = 'Ne prikazuj odlazni spot za izmenu';

  {PACKET SPOT PREFIX ONLY}
  SPO1                                  = 'Odlazni spot - samo prefiks';
  SPO2                                  = 'Odlazni spot - ceo pozivni znak';

  {PACKET SPOTS}
  PSP1                                  = 'Svi spotovi sa paketa se prikazuju';
  PSP2                                  = 'Samo se MPL spotovi sa paketa prikazuju';

  {PADDLE BUG ENABLE}
  PBE1                                  = 'Crtica kontakt na rucicama je BUG';
  PBE2                                  = 'Normalne crtice na rucicama';

  {PADDLE MONITOR TONE}
  PMT1                                  = 'Ton za CW poslat preko rucica (Hz)';

  {PADDLE PTT HOLD COUNT}
  PHC1                                  = 'Broj tackica pre no sto PTT otpusti';

  {PADDLE SPEED}
  PSD1                                  = 'Brzina kucanja preko rucica kao u programu';
  PSD2                                  = 'Brzina kucanja preko rucica';

  {PARTIAL CALL ENABLE}
  PCE1                                  = 'Prikazuj parcijalne znakove';
  PCE2                                  = 'Ne prikazuj parcijalne znakove';

  {PARTIAL CALL MULT INFO ENABLE}
  PCM1                                  = 'Prikazuj MPL info za parcijalne znakove';
  PCM2                                  = 'Ne prikazuj MPL info za parcijalne znakove';

  {POSSIBLE CALLS}
  PCA1                                  = 'Prikazuj moguce znakove';
  PCA2                                  = 'Ne prikazuj moguce znakove';

  {POSSIBLE CALL MODE}
  PCN1                                  = 'Prikazuj sve moguce znakove';
  PCN2                                  = 'Prikazuj samo moguce znakove sa imenima';
  PCN3                                  = 'Prikazuj samo moguce znakove iz LOGa';

  {PTT LOCKOUT}
  PBL1                                  = 'Blokada predaje preko mreze ukljucena';
  PBL2                                  = 'Blokada predaje preko mreze iskljucena';

  {PTT ENABLE}
  PTT1                                  = 'PTT ukljucen';
  PTT2                                  = 'PTT iskljucen (QSK)';

  {PTT TURN ON DELAY}
  PTD1                                  = 'PTT se aktivira pre slanja CW (ms)';

  {PTT VIA COMMANDS}
  PVC1                                  = 'PTT kontrola preko CAT komande ukljucena';
  PVC2                                  = 'PTT kontrola preko CAT komande iskljucena';

  {QSL MODE}
  QMD1                                  = 'Potrebna korektna info za QSL & log';
  QMD2                                  = 'Potrebna korektna info za log, ne za QSL';
  QMD3                                  = 'Bez provere sintakse razmene';

  {QSO NUMBER BY BAND}
  QNB1                                  = 'Redni brojevi pocinju od 001 za svaki opseg';
  QNB2                                  = 'Redni brojevi se nastavljaju na drgom opsegu';

  {QSX ENABLE}
  QSX1                                  = 'Ukljucen QSX info sa paket spota';
  QSX2                                  = 'Iskljucen QSX info sa paket spota';

  {QTC EXTRA SPACE}
  QES1                                  = 'Sa dodatnim razmacima kod slanja QTCa';
  QES2                                  = 'Bez dodatnih razmaka kod slanja QTCa';

  {QTC QRS}
  QRS1                                  = 'QRS pri slanju QTCa';
  QRS2                                  = 'Bez QRS pri slanju QTCa';

  {QUESTION MARK CHAR}
  QMC1                                  = 'Simbol na tastaturi za "?" karakter';

  {RADIO ONE FREQUENCY ADDER}
  R1FA1                                 = 'Vrednost za pomeranje FRQ na Radiju 1';
  R1FA2                                 = 'Bez pomeranja FRQ na Radiju 1';

  {RADIO TWO FREQUENCY ADDER}
  R2FA1                                 = 'Vrednost za pomeranje FRQ na Radiju 2';
  R2FA2                                 = 'Bez pomeranja FRQ na Radiju 2';

  {RANDOM CQ MODE}
  RCQ1                                  = 'Auto CQ bira F1-F4 nasumice';
  RCQ2                                  = 'Auto CQ radi normalno';

  {RATE DISPLAY}
  RDS1                                  = 'Rejt displej prikazuje veze';
  RDS2                                  = 'Rejt displej prikazuje QSO poene';
  RDS3                                  = 'Rejt displej prikazuje QSO poene na opsegu';

  {REMAINING MULT DISPLAY MODE}
  RMD1                                  = 'Bez prikaza preostalih mnozitelje';
  RMD2                                  = 'Preostali mnozitelji se brisu u radu';
  RMD3                                  = 'Neradjeni preostali mnozitelji su istaklnuti';

  {SAY HI ENABLE}
  SHE1                                  = 'Ime iz baze se salje';
  SHE2                                  = 'Slanje imena iz baze je iskljuceno';

  {SAY HI RATE CUTOFF}
  SHC1                                  = 'Rejt preko kojeg ce slanje imena biti iskljuceno';

  {SCP COUNTRY STRING}
  SCS1                                  = 'Prikazati sve SCP znakove';
  SCS2                                  = 'Zemlje za koje ce SCP biti prikazan';

  {SCP MINIMUM LETTERS}
  SML1                                  = 'Auto SCP iskljucen';
  SML2                                  = 'Minimalan broj karaktera za auto SCP';

  {SEND ALT-D SPOTS TO PACKET}
  SAD1                                  = 'Alt-D unos salji na paket';
  SAD2                                  = 'Alt-D unos ne salji na paket';

  {SEND COMPLETE FOUR LETTER CALL}
  SCF1                                  = 'Posalji ceo znak pri korekciji znaka';
  SCF2                                  = 'Posalji prefiks/sufiks pri korekciji znaka';

  {SEND QSO IMMEDIATELY}
  SQI1                                  = 'QSO slati na sve stanice kad je logovan';
  SQI2                                  = 'QSO slati kada je iskljucen edit prozor';

  {SERVER ADDRESS}
  SIA1                                  = '';

  {SERVER PASSWORD}
  SPA1                                  = '';

  {SERVER PORT}
  SEP1                                  = '';

  {SHIFT KEY ENABLE}
  SKE1                                  = 'Shift tasteri ukljuceni za RIT i S&P QSY';
  SKE2                                  = 'Shift tasteri iskljuceni za RIT i S&P QSY';

  {SHORT INTEGERS}
  SIN1                                  = 'Skraceni brojevi pri slanju rednih brojeva';
  SIN2                                  = 'Bez skracivanja brojeva pri slanju rednih brojeva';

  {SHOW LOG GRIDLINES}
  SLG1                                  = 'Dodavanje linija za odvajanje stavki u log prozoru';
  SLG2                                  = 'TR Log stil log prozota';

  {SINGLE RADIO MODE}
  SRM1                                  = 'Zameni uredjaje komanda (Alt-R) iskljucena';
  SRM2                                  = 'Zameni uredjaje komanda (Alt-R) ukljucena';

  {SKIP ACTIVE BAND}
  SAB1                                  = 'Alt-B zadrzava aktivni opseg na ostalim uredjajima';
  SAB2                                  = 'Alt-B ve zadrzava ostale aktivne opsege';

  {SLASH MARK CHAR}
  SMC1                                  = 'Simbol na tastaturi za "/" karakter';

  {SPACE BAR DUPE CHECK ENABLE}
  SBD1                                  = 'SPACE vrsi proveru duple ako je upisan znak';
  SBD2                                  = 'SPACE uvek salje znak i prelazi u S&P mod';

  {SPRINT QSY RULE}
  SQR1                                  = 'Posle S&P veze prelazi u CQ mod';
  SQR2                                  = 'Ostaje u S&P modu posle S&P veze';

  {START SENDING NOW KEY}
  SSN1                                  = 'Koristi %c taster za pocetak predaje';
  SSN2                                  = 'Koristi SPACE taster za pocetak predaje';

  {STEREO PIN HIGH}
  SPS1                                  = 'Stereo kontrolni pin visok';
  SPS2                                  = 'Stereo kontrolni pin nizak';

  {SWAP PACKET SPOT RADIOS}
  SRP1                                  = 'Stanica 1 je levo od stanice 2';
  SRP2                                  = 'Stanica 1 je desno od stanice 2';

  {SWAP PADDLES}
  SWP1                                  = 'Zameni crtice i tackice na rucicama';
  SWP2                                  = 'Normalne rucice';

  {SWAP RADIO RELAY SENSE}
  SWR1                                  = 'Stanica 1 = 0 volti na izlazu releja';
  SWR2                                  = 'Stanica 1 = 5 volti na izlazu releja';

  {TEN MINUTE RULE}
  TMR1                                  = 'Bez prikaza desetominutnog pravila';
  TMR2                                  = 'Prikazi vreme od prve veze na opsegu/vrsti rada';

  {TOTAL OFF TIME}
  TOT1                                  = 'Ukupno vreme neucestvovanja u takmicenju';

  {TUNE ALT-D ENABLE}
  TDE1                                  = 'Trazenje po opsegu ukljucuje drugi uredjaj za proveru duplih';
  TDE2                                  = 'Samo ALT-D ukljucuje drugi uredjaj za proveru duplih';

  {TUNE WITH DITS}
  TWD1                                  = 'Levi Control + Shift tasteri podesavanje tackicama';
  TWD2                                  = 'Levi Control + Shift tasteri neprekidan ton za podesavanje';

  {TWO RADIO MODE}
  TRM1                                  = 'SO2R mod ukljucen';
  TRM2                                  = 'SO2R mod iskljucen';

  {UPDATE RESTART FILE ENABLE}
  URF1                                  = 'RESTART.BIN se azurira posle svake veze';
  URF2                                  = 'RESTART.BIN se azurira pri napustanju LOGa';

  {USER INFO SHOWN}
  UIS1                                  = 'Bez prikaza podataka iz TRMASTER';
  UIS2                                  = 'Ime iz TRMASTER';
  UIS3                                  = 'QTH iz TRMASTER';
  UIS4                                  = 'Kontrolni broj i ARRL sekcija iz TRMASTER';
  UIS5                                  = 'ARRL sekcija iz TRMASTER';
  UIS6                                  = 'Raniji znak iz TRMASTER';
  UIS7                                  = 'FOC broj iz TRMASTER';
  UIS8                                  = 'Lokator iz TRMASTER';
  UIS9                                  = 'CQ zona iz TRMASTER ili CTY.DAT';
  UIS10                                 = 'ITU zona iz TRMASTER ili CTY.DAT';
  UIS11                                 = 'Podaci iz TRMASTER USER %u prikazani';
  UIS12                                 = 'Koristi CUSTOM USER STRING';

  {USE RECORDED SIGNS}
  URS1                                  = 'Reprodukuj snimljena slova/brojeve';
  URS2                                  = 'Koristi svoj glas za slanje znakova i razmenu';

  {VERSION}
  VER1                                  = 'Verzija programa (nemoze se menjati)';

  {VHF BAND ENABLE}
  VBE1                                  = '6 i 2 metra ukljucena';
  VBE2                                  = 'VHF opsezi iskljuceni pri Alt-B ili Alt-V';

  {WAIT FOR STRENGTH}
  WFS1                                  = 'Ako je [ u CW poruci - cekaj za unos';
  WFS2                                  = 'Prihvati snagu = 9 ako se CW zavrsava sa [';

  {WAKE UP TIME OUT}
  WUT1                                  = 'Tajmer za budjenje iskljucen';
  WUT2                                  = 'broj minuta bez odrzane veze kada se ukljucuje alarm';

  {WARC BAND ENABLE}
  WBE1                                  = 'WARC opsezi ukljuceni';
  WBE2                                  = 'WARC opsezi iskljuceni pri Alt-B ili Alt-V';

  {WEIGHT}
  WEI1                                  = 'Odnos tacka - crta';

  {WILDCARD PARTIALS}
  WCP1                                  = 'Prikaz parcijalnih znakova bilo gde';
  WCP2                                  = 'Samo prikaz znakova sa parcijalnim pocetkom';

implementation

end.

