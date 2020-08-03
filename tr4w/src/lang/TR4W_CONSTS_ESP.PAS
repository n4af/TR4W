const
  { %s =	A string.}
  { %c =	A single character.}
  { %d =	A signed decimal integer argument.}
  { %u =	An unsigned integer argument.}

  TC_TRANSLATION_LANGUAGE               = 'ESPAÑOL';
  TC_TRANSLATION_AUTHOR                 = 'Jose L. Rami EB2CYQ';
  TC_TRANSLATOR_EMAIL                   = 'tr4w@qrz.ru';

  TC_CALLSIGN                           = 'Indicativo';
  TC_CHECKCALLSIGN                      = 'Comprueba indicativo';
  TC_FREQUENCYFORCALLINKHZ              = 'frecuencia para %s en kHz';
  TC_DIFVERSION                         = '%s es de una version diferente.'#13'TR4W esperaba version %s.'#13'El fichero que intenta leer es de la version %s.';
  TC_FILE                               = 'File';
  TC_BAND                               = 'Band';
  TC_FREQ                               = 'Freq';
  TC_DATE                               = 'Date';
  TC_POINTS                             = 'Pts';
  TC_OP                                 = 'Op';
  TC_NAME                               = 'Name';

  TC_M                                  = 'm'; //minuto
  TC_S                                  = 's'; //segundo

  TC_RADIO1                             = 'Radio 1';
  TC_RADIO2                             = 'Radio 2';

  TC_DISBALE_CIV                        = 'Disable "CI-V Transceive" mode in your ICOM rig.';

  {MAIN}
  TC_YOU_ARE_USING_THE_LATEST_VERSION   = 'You are using the latest version';
  TC_SET_VALUE_OF_SET_NOW               = 'Set value of %s. Set now?';
  TC_CONFIGURATION_FILE                 = 'Configuration file';
  TC_CURRENT_OPERATOR_CALLSIGN          = 'current operator callsign';
  TC_APPENDIMPORTEDQSOSTOCURRENTLOG     = 'Append imported QSOs to current log?';
  TC_QSO_IMPORTED                       = 'Qs imported.'; // - '345 Qs imported.'
  TC_ISADUPE                            = '%s es un dupli!!';
  TC_ERRORINLOGFILE                     = 'Error en  fichero log!';
  TC_HASIMPROPERSYNTAX                  = '%s sintaxis impropia!!';
  TC_SORRYNOLOG                         = 'Mal!! NO LOG = TRUE que prohibe guardar QSOs en este PC';
  TC_SETCOMPUTERIDVALUE                 = 'Elija valor COMPUTER ID.';
  TC_CLEARALLLOGS                       = '"CLEARALLLOGS" para borrar todos los logs de la red';
  TC_CLEAR_DUPESHEET_NET                = '"CLEARDUPESHEET" to clear all dupesheets in network';
  TC_CLEAR_MULTSHEET_NET                = '"CLEARMULTSHEET" to clear all multsheets in network';

  TC_WANTTOCONVERTLOG                   = 'Would you like to convert this log to the latest format?';
  TC_LOGFILENOTFOUND                    = 'Log file not found';
  TC_CANNOTBACKUPLOG                    = 'Could not make a backup copy of ';
  TC_CANNOTCOPYLOGREADONLY              = 'Cannot copy log file -- target exists and is read-only';
  TC_BACKUPCREATED                      = 'Log file backup created';
  TC_CANNOTRENAME                       = 'Can not rename';

  TC_REALLYWANTTOCLEARTHELOG            = '¿Quiere borrar el actual log?';
  TC_MESSAGETOSENDVIANETWORK            = 'mensaje a enviar via red';
  TC_SENDTIMETOCOMPUTERSONTHENETWORK    = '¿Quiere enviar hora a los demas PCs de la red?';
  TC_RULESONSM3CER                      = 'Rules for %s contest on WA7BNM Contest Calendar';
  TC_RULESONQRZRU                       = 'Reglas del %s concurso en QRZ.RU';
  TC_NOTE                               = 'nota';
  TC_DUPESHEETCLEARED                   = 'Hoja de duplicados borrada!';
  TC_MULTSHEETCLEARED                   = 'Mult sheet cleared!';
  TC_YESTOCLEARTHEDUPESHEET             = '"YES" para borrar la hoja de duplicados';
  TC_TRANSMITFREQUENCYKILOHERTZ         = 'frecuencia transmision (kiloHertz): ';
  TC_CLEARMULTTOCLEARMULTSHEET          = '"CLEARMULT" to clear the multsheet';
  TC_SPRINTQSYRULE                      = 'SPRINT QSY RULE!!!';
  TC_PADDLE                             = 'Paddle';
  TC_FOOTSW                             = 'Footsw.';
  TC_LOG_NOTE                           = 'NOTA';
  TC_LOG_DELETED                        = 'BORRADO';

  TC_SUN                                = 'Dom';
  TC_MON                                = 'Lun';
  TC_TUE                                = 'Mar';
  TC_WED                                = 'Mie';
  TC_THU                                = 'Jue';
  TC_FRI                                = 'Vie';
  TC_SAT                                = 'Sab';

  {uMP3Recorder}
  TC_LAME_ERROR                         = 'You may download it from';

  {This version TR4W v.4.009 beta was build in 2 December 2008. Do you want to check the latest version ?}
  TC_THISVERSION                        = 'Esta version ';
  TC_WASBUILDIN                         = ' se compilo en ';
  TC_DOYOUWANTTOCHECKTHELATESTVERSION   = '¿Quieres buscar la ultima version?';

  {NEW CONTEST}
  TC_LATEST_CONFIG_FILE                 = 'Latest config file';
  TC_OPENCONFIGURATIONFILE              = ' - Abrir fichero configuración o inciar un nuevo concurso';
  TC_FOLDERALREADYEXISTSOVERWRITE       = '¿El directorio "%s" ya existe.'#13'sobreescribir?';
  TC_IAMIN                              = '&Estoy en %s';
  TC_NEWENGLANDSTATEABREVIATION         = 'Entre su estado de New England abreviacion'#13'(ME, NH, VT, MA, CT, RI):';
  TC_ENTERTHEQTHTHATYOUWANTTOSEND       = 'Enter su QTH a enviar:';
  TC_ENTERSTATEFORUSPROVINCEFORCANADA   = 'Enter estado de U.S., provincia para Canada:';
  TC_ENTERYOUROBLASTID                  = 'Entre su oblast ID:';
  TC_ENTERYOURPROVINCEID                = 'Entre su provincia ID:';
  TC_ENTERYOURCOUNTYCODE                = 'Entre su codigo pais:';
  TC_ENTERYOURDOK                       = 'Entre su DOK:';
  TC_ENTERYOURDISTRICTABBREVIATION      = 'Entre su distrito abreviacion:';
  TC_ENTERYOURRDAID                     = 'Entre su RDA ID:';
  TC_ENTERYOURIOTAREFERENCEDESIGNATOR   = 'Entre su referencia IOTA:';
  TC_ENTERYOURCITYIDENTIFIER            = 'Entre su identificador ciudad:';
  TC_ENTERYOURNAME                      = 'Entre su nombre:';
  TC_ENTERTHELASTTWODIGITSOFTHEYEAR     = 'Entre los dos ultimos digitos del año de su primera licencia:';
  TC_ENTERYOURZONE                      = 'Entre su zona:';
  TC_ENTERYOURGEOGRAPHICALCOORDINATES   = 'Entre sus coodenadas geograficas'#13'(e.j. 55N37O para Moscu):';
  TC_ENTERSUMOFYOURAGEANDAMOUNT         = 'Enter suma de su edad y los años trancurridos desde su primer QSO (e.j. 28+14=42):';
  TC_OZCR                               = 'Enter tres letras:';
  TC_ENTERYOURSTATECODE                 = 'Entre su codigo estado:';
  TC_ENTERYOURFOURDIGITGRIDSQUARE       = 'Entre sus cuatro digitos de su locator:';
  TC_RFAS                               = 'Entre sus coordenadas geograficas:';
  TC_ENTERYOURSIXDIGITGRIDSQUARE        = 'Entre sus seis digitos del locator:';
  TC_ISLANDSTATION                      = 'Estacion de isla';
  TC_ENTERYOURNAMEANDSTATE              = 'Entre su name (y estado si esta en norteamerica):';
  TC_ENTERYOURNAMEANDQTH                = 'Entre su nombre y QTH (estado US, provincia canadiense o pais DX):';
  TC_ENTERYOURPRECEDENCECHECKSECTION    = 'Entre su precedence, your check'#13'(last two digits of year licensed) and ARRL section:';
  TC_ENTERYOURQTHANDTHENAME             = 'Entre su QTH que quiere enviar'#13'y el nombre que quiere usar:';
  TC_ENTERFIRSTTWODIGITSOFYOURQTH       = 'Enter dos primeros digitos de su QTH:';
  TC_ENTERYOURAGEINMYSTATEFIELD         = 'Entre su edad en el campo MY STATE:';
  TC_ENTERYOURQTHORPOWER                = 'Entre su QTH que quiere enviar si estña en norteamerica o su potencia como MY STATE si es de fuera:';
  TC_ENTERFIRSTTWOLETTERSOFYOURGRID     = 'Entre las dos primeras letras de su locator:';
  TC_ENTERYOURSQUAREID                  = 'Enter your square ID:';

  TC_ENTERYOURMEMBERSHIPNUMBER          = 'Enter your membership number:';
  TC_ENTERYOURCONTINENT                 = 'Enter your continent (and possible additional ID, i.e. SAYL or NAQRP)';
  TC_ENTERYOURCOUNTYORSTATEPOROVINCEDX  = 'Enter your county if you in %s state. Enter your state, Canadian Province or "DX" if outside of %s:';
  TC_PREFECTURE                         = 'Enter your prefecture:';
  TC_STATIONCLASS                       = 'Enter your station class:';
  TC_AGECALLSIGNAGE                     = 'Enter your age (and Silent Key callsign and age):';
  TC_DEPARTMENT                         = 'Enter your department:';
  TC_ENTERYOURRDAIDORGRID               = 'Enter your RDA ID (for UA1A stations) or four digit grid square:';

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
  TC_UKRAINE                            = 'Ucrania';
  TC_CZECHREPUBLICORINSLOVAKIA          = 'Czech Republic o en Slovakia';
  TC_BULGARIA                           = 'Bulgaria';
  TC_ROMANIA                            = 'Rumania';
  TC_HUNGARY                            = 'Hungria';
  TC_BELGIUM                            = 'Belgica';
  TC_NETHERLANDS                        = 'Holanda';
  TC_STPETERSBURGOBLAST                 = 'St.Petersburg / oblast';
  TC_GERMANY                            = 'Alemania';
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

  TC_TELNET                             = 'Conectar'#0'Desconectar'#0'Comandos'#0'Congelar'#0'Limpiar'#0'100'#0#0;
  TC_YOURNOTCONNECTEDTOTHEINTERNET      = 'NO ESTA CONECTADO A INTERNET!';
  TC_GETHOST                            = 'ELIJA HOST..';
  TC_SERVER                             = 'SERVER: %s';
  TC_HOST                               = 'HOST  : %s';
  TC_CONNECT                            = 'CONECTAR..';
  TC_CONNECTED                          = 'CONECTADO';
  TC_YOUARESPOTTEDBYANOTHERSTATION      = 'Has sido anunciado por otra estacion.';

  {UNET}

  TC_CONNECTIONTOTR4WSERVERLOST         = 'Conexion a TR4WSERVER %s:%d perdida.';
  TC_COMPUTERCLOCKISSYNCHRONIZED        = 'Reloj del PC esta sincronizado.';
  TC_CONNECTINGTO                       = 'Conectando a ';
  TC_CONNECTTOTR4WSERVERFAILED          = 'Conexion a TR4WSERVER fallida. Compruebe valor SERVER PASSWORD!!';
  TC_CONNECTEDTO                        = 'Conectando a';
  TC_FAILEDTOCONNECTTO                  = 'Fallo al conectar a';
  TC_SERVERANDLOCALLOGSAREIDENTICAL     = 'SERVER y LOCAL logs son identicos.';
  TC_NETWORK                            = 'Network : %s %s:%d';
  TC_SERVER_LOG_CHANGED                 = 'Server log changed. %u QSO(s) updated. Do logs synchronizing (Ctrl+Alt+S).';
  TC_ALL_LOGS_NETWORK_CLEARED           = 'All logs in TR4W network cleared.';

  {UGETSCORES}

  TC_FAILEDTOCONNECTTOGETSCORESORG      = 'Fallo al conectar';
  TC_NOANSWERFROMSERVER                 = 'Sin respuesta del server';
  TC_UPLOADEDSUCCESSFULLY               = 'Envio correcto.';
  TC_FAILEDTOLOAD                       = 'FALLO AL LEER. Ver GETSCORESANSWER.HTML para detalles.';

  {UBANDMAP}

  TC_SOURCE                             = 'Origen: %s';
  TC_MIN                                = '%u min.';

  {LOGWIND}

  TC_CQTOTAL                            = 'CQ total: %u';
  TC_REPEATING                          = 'Repitiendo %s  Tiempo escucha = %u msec - PgUp/Dn para ajustar o ESCAPE';
  TC_NEWTOUR                            = 'Nueva vuelta %d/%d';
  TC_ENTER                              = 'Entre %s :';
  TC_PTS                                = '%d Pts';
  TC_RATE                               = 'Ratio = %u';
  TC_LAST60                             = 'Ult 60 = %d';
  TC_THISHR                             = 'Esta hr = %d';
  TC_HAVEQTCS                           = 'Tiene %u QTCs';
  TC_BAND_CHANGES                       = 'Bn. ch. = %d';
  TC_INSERT                             = 'INSERTA';
  TC_OVERRIDE                           = 'SOBRESCRIBE';
  TC_UNKNOWNCOUNTRY                     = 'Pais desconocido';

  {UCALLSIGNS}

  TC_DUPESHEET                          = 'Hoja duplicados - %sm-%s';

  {LOGEDIT}

  TC_QSONEEDSFOR                        = ' QSO necesario para %s :';
  TC_MULTNEEDSFOR                       = ' Multi necesario para %s :';
  TC_MISSINGMULTSREPORT                 = 'Informe multip.ausente: %u entidades en al menos %u pero no todas las bandas.';

  {LOGDUPE}

  TC_THEREWERECALLS                     = 'There were %u calls found in initial exchange file.'#13'+%u dupe(s)';
  TC_RESTARTBINISFORADIFFERENTCONTEST   = 'RESTART.BIN es para un concurso diferente.';

  {LOGSTUFF}

  TC_NOTENOUGHINFOINEXCHANGE            = 'Insuficiente info en intercambio!!';
  TC_IMPROPERDOMESITCQTH                = 'Impropìo QTH domertico!!';
  TC_IMPROPERDOMESITCQTHORMISSINGNAME   = 'Improper domesitc QTH or missing name!!';
  TC_MISSINGQTHANDORNAME                = 'Falta QTH y/o nombre!!';
  TC_NOQSONUMBERFOUND                   = 'No encuentro numero QSO!!';
  TC_SAVINGTO                           = 'Saving %s to %s';
  TC_FILESAVEDTOFLOPPYSUCCESSFULLY      = 'File saved to floppy successfully';
  TC_FILESAVEDTOSUCCESSFULLY            = 'File saved to %s successfully';
  TC_IMPROPERTRANSMITTERCOUNT           = 'FD transmitters must be between 1 and 99.';
  TC_IMPROPERARRLFIELDDAYCLASS          = 'Field Day class must be A, B, C, D, E or F.';
  TC_IMPROPERWINTERFIELDDAYCLASS        = 'Winter Field Day class must be H, I or O.';
  TC_ARRLFIELDDAYIMPROPERDXEXCHANGE     = 'DX Station exchange must be "DX".';

  {LOGSEND}

  TC_WAITINGFORYOUENTERSTRENGTHOFRST    = 'Esperando la entrada de intensidad RST (Un solo digito)!!';

  {COUNTRY9}

  TC_C9_NORTHAMERICA                    = 'Norte America';
  TC_C9_SOUTHAMERICA                    = 'Sudamerica';
  TC_C9_EUROPE                          = 'Europa';
  TC_C9_AFRICA                          = 'Africa';
  TC_C9_OCEANIA                         = 'Oceania';
  TC_C9_ASIA                            = 'Asia';
  TC_C9_UNKNOWN                         = 'Desconocido';

  {USTATIONS}

  TC_STATIONSINMODE                     = 'Estaciones en %s modo';

  {USPOTS}

  TC_SPOTS                              = '%d spots';

  {uSendKeyboard}

  TC_SENDINGSSBWAVFILENAME              = 'Enviando fichero SSB .wav. Use ENTER para reproducir, Escape/F10 para salir.';

  {QTC}

  TC_WASMESSAGENUMBERCONFIRMED          = 'Es mensaje numero %u confirmado?';
  TC_DOYOUREALLYWANTSTOPNOW             = 'Quiere pararlo ahora?';
  TC_QTCABORTEDBYOPERATOR               = 'QTC abortado por operador.';
  TC_DOYOUREALLYWANTTOABORTTHISQTC      = 'Quiere abortar este QTC?';
  TC_NEXT                               = '< Prox';
  TC_QTC_FOR                            = '%s para %s';
  TC_QTC_CALLSIGN                       = 'Indicativo :';
  TC_ENTERQTCMAXOF                      = 'Entre QTC #/# (max de %d) :';
  TC_DOYOUREALLYWANTTOSAVETHISQTC       = 'Realmente quiere salvar este QTC?';
  TC_EDITQTCPRESSYESTOEDITQTCORNOTOLOG  = 'Editar QTC? Pulse SI para editar QTC o No para log ';
  TC_CHECKQTCNUMBER                     = 'Comprobar numero QTC';
  TC_CHECKTIME                          = 'Comprobar hora';

  {UOPTION}

  TC_COMMAND                            = 'Comando';
  TC_VALUE                              = 'Valor';
  TC_INFO                               = 'Info';
  TC_YOUCANCHANGETHISINYOURCONFIGFILE   = 'Quire cambiar esto en su fichero de configuracion.';

  {UEDITQSO}

  TC_CHECKDATETIME                      = 'Compruebe Fecha/Hora !!';
  TC_SAVECHANGES                        = 'Salvar cambios?';

  {LOGCW}

  TC_WPMCODESPEED                       = 'Velocidad WPM';

  TC_CWMENU                             =
    '# QSO numero   % database name    ~ GM/GA/GE         : Activa teclado CW'#13 +
    '[ RST prompt   ^ half space       ] repite RST envi  @ Call window contents'#13 +
    '$ GM + name    | nombre rcbdoe    \ Mi indicativo    } partial corrected call'#13 +
    '^F WPM+2  ^S WPM-2  + AR  < SK  = BT  ! SN  & AS     ) ultim QSO''s call'#13 +
    'Carateres de control del programa, pulse Control-P antes del caracter de control.';

  TC_CQFUNCTIONKEYMEMORYSTATUS          = 'TECLA FUNCION CQ ESTADO MEMORIA';
  TC_EXCHANGEFUNCTIONKEYMEMORYSTATUS    = 'EXCHANGE FUNCTION KEY MEMORY STATUS';
  TC_OTHERCWMESSAGEMEMORYSTATUS         = 'Other CW message memory status';
  TC_OTHERSSBMESSAGEMEMORYSTATUS        = 'Other SSB message memory status';
  TC_PRESSCQFUNCTIONKEYTOPROGRAM        = ' Press CQ function key to program (F1, AltF1, CtrlF1), or ESCAPE to exit) : ';
  TC_PRESSEXFUNCTIONKEYTOPROGRAM        = 'Press ex function key to program (F3-F12, Alt/Ctrl F1-F12) or ESCAPE to exit:';
  TC_NUMBERORLETTEROFMESSAGETOBEPROGRAM = 'Number or letter of message to be programmed (1-9, A-C, or ESCAPE to exit):';
//  TC_F1SETBYTHEMYCALLSTATEMENTINCONFIG  = 'F1 - Set by the MY CALL statement in config file';
//  TC_F2SETBYSPEXCHANGEANDREPEATSP       = 'F2 - Set by S&P EXCHANGE and REPEAT S&P EXCHANGE';
  TC_CWDISABLEDWITHALTK                 = 'CW disabled with Alt-K!!  Use Alt-K again to enable.';
  TC_VOICEKEYERDISABLEDWITHALTK         = 'Voice keyer disabled with Alt-K!!  Use Alt-K again to enable.';

  {LOGCFG}

  TC_NOCALLSIGNSPECIFIED                = 'Indicativo no especificado!!';
  TC_NOFLOPPYFILESAVENAMESPECIFIED      = 'Nombre para salvar no especificado!!';
  TC_UNABLETOFIND                       = 'Icapaz de encontrar %s !!';
  TC_INVALIDSTATEMENTIN                 = 'INVALID STATEMENT IN %s !!'#13#13'Line %u'#13'%s';
  TC_UNABLETOFINDCTYDAT                 = 'No encuentro fichero paises CTY.DAT!!'#13'Asegurese de que esta en el mismo directorio del programa.';
  TC_INVALIDSTATEMENTINCONFIGFILE       = '%s:'#13'INVALID STATEMENT IN CONFIG FILE!!'#13#13'Line %u'#13'%s';
  TC_THIS_FILE_DOES_NOT_EXIST           = 'This file does not exist. Create an empty file for editing?';

  {LOGSUBS1}

  TC_RECORDDVPPRESSESCAPEORRETURNTOSTOP = 'Grabando DVP. Pulse ESCAPE o RETURN para parar.';
  TC_ALTRCOMMANDDISABLED                = 'Alt-R desactiva le modo de radio unica = True';
  TC_NOCQMESPROGRAMMEDINTOCQMEMORYALTF1 = 'Sin mensaje CQ programado en la MEMORIA CQ AltF1.';

  {LOGSUBS2}

  TC_WASADUPE                           = '%s es un duplicado.';
  TC_ALTDCOMMANDDISABLED                = 'Alt-D desactivado por SINGLE RADIO MODE = TRUE';
  TC_YOUHAVERESTOREDTHELASTDELETED      = 'Ha recuperado la ultima entrada borrada del log!!';
  TC_YOUHAVEDELETEDTHELASTLOGENTRY      = 'Ha borrado la ultima entrada del log!!  Use Alt-Y para recuperarla.';
  TC_DOYOUREALLYWANTTOEXITTHEPROGRAM    = '¿Quiere salir del programa?';
  TC_YOUARENOWTALKINGTOYOURPACKETPORT   = 'Esta usando el puerto packet.  Use Control-B para salir.';
  TC_YOUALREADYWORKEDIN                 = 'Ya ha trabado %s en %s!!';
  TC_ISADUPEANDWILLBELOGGEDWITHZERO     = '%s es un duplicado y se grabara como QSO de 0 puntos.';
  TC_LOGFILESIZECHECKFAILED             = 'FALLO EN TAMAÑO DEL FICHERO DE LOG!!!!';

  {JCTRL2}

  TC_NEWAUTOSAPENABLESENSITIVITYINHZSEC = 'nuevo AUTO S&P ACTIVO sensibilidad en Hz/sec)';
  TC_NEWBANDMAPDECAYTIMEMINUTES         = 'new band map decay time (minutes)';
  TC_NEWBANDMAPGUARDBANDHERTZ           = 'new band map guard band (hertz)';
  TC_COMMANDWHICHWILLBESENDATTELNETCON  = 'command which will be send at telnet connection';
  TC_YOUCANONLYCHANGETHISWHENCLIENTDISC = 'You can only change this when client disconnected from TR4WSERVER.';
  TC_COMPUTERIDAZRETURNNONE             = 'identificador PC (A-Z o RETURN para ninguno)';
  TC_NEWCOUNTRYINFORMATIONFILENAME      = 'nuevo fichero de informacion de paises';
  TC_NEWCWINCREMENT                     = 'nuevo incremento CW (1 a 10 WPM)';
  TC_NEWCWMONITORTONE                   = 'nuevo tono monitor CW (0 para desactivar)';
  TC_COMPUTERNAME                       = 'computer name (7 chars max)';
  TC_NEWFARNSWORTHSPEEDCUTINVALUE       = 'nuevo farnsworth speed cut in value';
  TC_NEWFLOPPYFILESAVEFREQUENCY         = 'nuevo floppy file save frequency';
  TC_SELECTNEWFLOPPYFILESAVENAME        = 'Select new floppy file save name';
  TC_FREQPOLLRATEINMS                   = 'freq poll rate in ms (10-1000)';
  TC_NEWCENTERFORGRIDMAP                = 'nuevo centro en mapa de locators';
  TC_RSTOSHOWASSENTINLOG                = 'RS a ver in enviado en log';
  TC_RSTTOSHOWASSENTINLOG               = 'RST a ver in enviado en log';
  TC_FIELDDAYCLASS                      = 'field day class';
  TC_NEWGRIDSQUARE                      = 'nueva cuadricula';
  TC_NEWVALUEFORMYIOTA                  = 'nuevo valor para MY IOTA';
  TC_NEWMULTIINFOMESSAGE15CHARSMAX      = 'nuevo multi info message (15 chars max)';
  TC_ACOMMENTTOSENDWITHEACHSPOT         = 'un comentario a enviar con cada spot';
  TC_NEWPTTHOLDCOUNT                    = 'nuevo PTT hold count';
  TC_NEWPADDLEMONITORTONE               = 'nuevo paddle monitor tone (Hz)';
  TC_NEWPADDLESPEED0TODISABLE           = 'nuevo paddle speed (0 to disable)';
  TC_PTTDELAYCOUNT                      = 'PTT delay count';
  TC_KEYBOARDCHARACTERTOUSEFORQUESTION  = 'keyboard character to use for ?';
  TC_RADIO1FREQUENCYADDER               = 'radio 1 frequency adder';
  TC_RADIO2FREQUENCYADDER               = 'radio 2 frequency adder';
  TC_NEWSAYHIRATECUTOFF                 = 'nuevo SAY HI RATE CUTOFF';
  TC_NEWSCPCOUNTRYSTRING                = 'nuevo SCP Country String';
  TC_KEYBOARDCHARACTERTOSTARTSENDING    = 'keyboard character to start sending';
  TC_NETWORKSERVERADDRESS               = 'network server address';
  TC_NEWSERVERPASSWORD10CHARS           = 'nuevo server password (10 chars)';
  TC_NETWORKSERVERPORT                  = 'network server port';
  TC_KEYBOARDCHARACTERTOUSEFORSLASH     = 'keyboard character to use for /';
  TC_NEWOFFTIMEVALUEMINUTES             = 'nuevo off time value (minutes)';
  TC_NEWVALUEFORWAKEUPTIMEOUT           = 'nuevo value for WAKE UP TIME OUT';
  TC_NEWWEIGHTVALUE                     = 'nuevo weight value (.5 - 1.5)';
  TC_NEWVALUE                           = 'new value';

  {TREE}

  TC_ALREADYEXISTSOKAYTODELETE          = '%s ya existe.'#13#13'Lo borro?';

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

  TC_QTCPENDING                         = 'QTC Pendiente';
  TC_ZONE                               = 'Zona';
  TC_PREFIX                             = 'Prefijo';
  TC_DXMULTS                            = 'DX Mults';
  TC_OBLASTS                            = 'Oblasts';
  TC_HQMULTS                            = 'HQ Mults';
  TC_DOMMULTS                           = 'Dom Mults';
  TC_QSOS                               = 'QSOs';
  TC_CWQSOS                             = 'CW QSOs';
  TC_SSBQSOS                            = 'SSB QSOs';
  TC_DIGQSOS                            = 'DIG QSOs';

  {UALTD}

  TC_ENTERCALLTOBECHECKEDON             = 'Entre indicativo a comprobar en %s%s:';

  {LOGGRID}

  TC_ALLSUN                             = 'All sun';
  TC_ALLDARK                            = 'All dark';

  {UMIXW}

  TC_MIXW_CONNECTED                     = 'Conectado';
  TC_MIXW_DISCONNECTED                  = 'Desconectado';

  {LOGWAE}

  TC_INVALIDCALLSIGNINCALLWINDOW        = 'Indicativo incorrecto en ventana!!';
  TC_SORRYYOUALREADYHAVE10QTCSWITH      = 'Ya tiene 10 QTCs con %s';
  TC_NOQTCSPENDINGQRU                   = 'Sin QTCs pendientes, QRU.';
  TC_ISQRVFOR                           = 'Es %s QRV para %s?';

  {UREMMULTS}

  TC_CLEANSWEEPCONGRATULATIONS          = 'CLEAN SWEEP!! CONGRATULATIONS!!';

  {CFGCMD}

  TC_NETWORKTEST                        = 'Prueba Network';
  TC_MAXIMUMNUMBEROFREMINDERSEXCEEDED   = 'Maximum number of reminders exceeded!!';
  TC_INVALIDREMINDERTIME                = 'Invalid reminder time!!';
  TC_INVALIDREMINDERDATE                = 'Invalid reminder date!!';
  TC_TOOMANYTOTALSCOREMESSAGES          = 'Too many TOTAL SCORE MESSAGEs!!';
  TC_THEFIRSTCOMMANDINCONFIGFILEMUSTBE  = 'The first command in config file must be the MY CALL statement!!';

  {USYNTIME}
  TC_MS                                 = ' ms'; //milisegundos

  {ULOGSEARCH}
  TC_ENTRIESPERMS                       = '%u entradas por %u ms';

  {ULOGCOMPARE}
  TC_SIZEBYTES                          = 'Tamaño, bytes';
  TC_RECORDS                            = 'Registros';
  TC_MODIFIED                           = 'Modified';
  TC_TIMEDIFF                           = 'Time diff.';

  {POSTUNIT}
  TC_MORETHAN50DIFFERENTHOURSINTHISLOG  = 'Mas de 50 horas diferenes en este log!!';
  TC_TOOMANYCONTESTDATES                = 'Muchas fechas de concurso!!';

  {UGETSERVERLOG}
  TC_FAILEDTORECEIVESERVERLOG           = 'Fallo recepcion del log del servidor.';

  {DLPORTIO}
  TC_DLPORTIODRIVERISNOTINSTALLED       = 'DLPortIO driver no instalado.';

  {UCT1BOH}
  TC_TIMEON                             = 'Time on';

  {ULOGCOMPARE}
  TC_SERVERLOG                          = 'SERVER LOG';
  TC_LOCALLOG                           = 'LOCAL LOG';

  {UCHECKLATESTVERSION}
  TC_VERSIONONSERVER                    = 'Version on server';
  TC_THISVERSION2                       = 'This version';
  TC_DOWNLOADIT                         = 'Download last version?';

    {JCTRL1}

  {ALL CW MESSAGES CHAINABLE}
  ACC1                                  = 'All CW messages can be chained together';
  ACC2                                  = 'Only msgs with ^D at start will chain';

  {ALLOW AUTO UPDATE}
  AAU1                                  = 'Automatical rescore after editing of the server log';
  AAU2                                  = 'Manual rescore after editing of the server log';

  {ALT-D BUFFER ENABLE}
  ABE1                                  = 'Alt-D starts with bandmap or last entry';
  ABE2                                  = 'Alt-D prompt has no initial call shown';

  {ALWAYS CALL BLIND CQ}
  ABC1                                  = 'EX F7 always sent after CQ EXCHANGE';
  ABC2                                  = 'Blind CQs disabled';

  {ASK FOR FREQUENCIES}
  AFF1                                  = 'Ask for band map freqs if no interface';
  AFF2                                  = 'Do not prompt for band map frequencies';

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

  {COMPUTER NAME}
  CNA1                                  = 'Computer name';

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

  TC_IMPROPERZONENUMBER                 = 'Improper zone number!!';

  CLOSE_WORD                            = 'Cerrar';
  CANCEL_WORD                           = 'Cancelar';
  HELP_WORD                             = 'Ayuda';
  OK_WORD                               = 'OK';
  EXIT_WORD                             = '&Salir';
  RC_CALLSIGN                           = 'Indicativo';
  RC_MODE                               = 'Modo';
  RC_BAND                               = 'Banda';
  RC_FREQUENCY                          = 'Frequencia';
  RC_APPLY                              = '&Aplicar';
  RC_RESET                              = '&Resetear';
  RC_START                              = 'Inicio';
  RC_SHOW                               = 'Ver';
  RC_SAVE                               = '&Salvar';
  RC_CREATE                             = 'Crear';
  RC_EDIT_WORD                          = 'Edit';
  RC_POSTSCORETOGS                      = 'Publica puntuacion';
  RC_POSTNOW                            = 'Publicar ahora';
  RC_GOTOGS                             = 'Ver';
  RC_FILE                               = 'Archivo';
  RC_NEWCONTEST                         = 'Nuevo concurso';
  RC_CLEARLOG                           = 'Limpiar log';
  RC_OPENLOGDIR                         = 'Abrir directorio log';
  RC_EXPORT                             = 'Exportar';
  RC_INIEXLIST                          = 'Lista intercambios inciales';
  RC_TRLOGFORM                          = 'Formato TR Log';
  RC_IMPORT                             = 'Import';
  RC_REPORTS                            = 'I';
  RC_ALLCALLS                           = 'Todos los indicativos';
  RC_BANDCHANGES                        = 'Cambios de banda';
  RC_CONTLIST                           = 'Lista Continentes';
  RC_FCC                                = 'Primer indicativo trabajado en cada entidad';
  RC_FCZ                                = 'Primer indicativo trabajado en cada zona';
  RC_POSSBADZONE                        = 'Possible bad zone';
  RC_QSOBYCOUNTRY                       = 'QSOs con entidad por banda';
  RC_SCOREBYHOUR                        = 'Puntos por hora';
  RC_SUMMARY                            = 'Resumen';
  RC_EXIT                               = 'Salir';
  RC_SETTINGS                           = 'Ajustes';
  RC_OPTIONS                            = 'Configuration commands';
  RC_CFG_COMMANDS                       = 'Configuration commands';
  RC_PROGRAMMES                         = 'Mensajes del programa';
  RC_CATANDCW                           = 'CAT y CW Keying';
  RC_RADIOONE                           = 'Radio uno';
  RC_RADIOTWO                           = 'Radio dos';
  RC_WINDOWS                            = 'Ventanas';
  RC_BANDMAP                            = 'Mada de banda';
  RC_DUPESHEET                          = 'Hoja duplicados';
  RC_FKEYS                              = 'Teclas de funcion';
  RC_TRMASTER                           = 'SCP';
  RC_REMMULTS                           = 'Multis restantes';
  RC_RM_DEFAULT                         = 'Defecto';
  RC_RADIO1                             = 'Radio 1';
  RC_RADIO2                             = 'Radio 2';
  RC_TELNET                             = 'DX Cluster';
  RC_NETWORK                            = 'Red-Network';
  RC_INTERCOM                           = 'Intercom';
  RC_GETSCORES                          = 'RC_POSTSCORETOGS""';
  RC_STATIONS                           = 'Estaciones';
  RC_MP3REC                             = 'MP3 Recorder';
  RC_MULTSFREQ                          = 'Multis Frequencias';
  RC_ALARM                              = 'Alarma';
  RC_AUTOCQRESUME                       = 'Auto-CQ resume';
  RC_DUPECHECK                          = 'Comprobar duplicados';
  RC_EDIT                               = 'Editar';
  RC_SAVETOFLOPPY                       = 'Salvar a disco';
  RC_SWAPMULTVIEW                       = 'Swap mult view';
  RC_INCNUMBER                          = 'Numero incremental';
  RC_TOOGLEMB                           = 'Toogle multiplier bell';
  RC_KILLCW                             = 'Kill CW';
  RC_SEARCHLOG                          = 'Buscar log';
  RC_TRANSFREQ                          = 'Frecuencia transmisor';
  RC_REMINDER                           = 'Recordatorio-nota';
  RC_AUTOCQ                             = 'Auto-CQ';
  RC_TOOGLERIGS                         = 'Intercambiar emisoras';
  RC_CWSPEED                            = 'Velocidad CW';
  RC_SETSYSDT                           = 'Elige fecha/hora del sistema';
  RC_INITIALIZE                         = 'Inicializar QSO';
  RC_RESETWAKEUP                        = 'Reset wakeup';
  RC_DELETELASTQSO                      = 'Borrar el ultimo QSO';
  RC_INITIALEX                          = 'Intercambio incial';
  RC_TOOGLEST                           = 'Intercambiar sidetone';
  RC_TOOGLEAS                           = 'Intercambiar autosend';
  RC_BANDUP                             = 'Banda arriba';
  RC_BANDDOWN                           = 'Banda abajo';
  RC_SSBCWMODE                          = 'SSB/CW modo';
  RC_SENDKEYBOARD                       = 'Entrada con teclado';
  RC_COMMWITHPP                         = 'Comunicar con puerto packet';
  RC_CLEARDUPES                         = 'Limpiar hoja duplicados';
  RC_VIEWEDITLOG                        = 'Ver / Editar log';
  RC_NOTE                               = 'Nota';
  RC_MISSMULTSREP                       = 'Informe multiplicadores ausente';
  RC_REDOPOSSCALLS                      = 'Recupera indicativos posibles';
  RC_QTCFUNCTIONS                       = 'Funciones QTCs';
  RC_RECALLLASTENT                      = 'Recupera ultima entrada';
  RC_VIEWPAKSPOTS                       = 'Ver anuncios/spots packet';
  RC_EXECONFIGFILE                      = 'Execute configuration file';
  RC_REFRESHBM                          = 'Redibuja mapa de banda';
  RC_DUALINGCQ                          = 'CQs duales';
  RC_CURSORINBM                         = 'Cursor en ventana mapa de banda';
  RC_CURSORTELNET                       = 'Cursor in DX Cluster window';
  RC_QSOWITHNOCW                        = 'QSO con no CW';
  RC_CT1BOHIS                           = 'CT1BOH info';
  RC_ADDBANDMAPPH                       = 'Add bandmap place holder';
  RC_COMMANDS                           = 'Comandos';
  RC_FOCUSINMW                          = 'Foco en ventana principal';
  RC_TOGGLEINSERT                       = 'Intercambio modo insertar';
  RC_ESCAPE                             = 'Escape';
  RC_CWSPEEDUP                          = 'Velocidad CW +';
  RC_CWSPEEDDOWN                        = 'Velocidad CW -';
  RC_CWSPUPIR                           = 'Velocidad CW + para radio inactiva';
  RC_CWSPDNIR                           = 'Velocidad CW - para radio inactiva';
  RC_CQMODE                             = 'Modo CQ';
  RC_SEARCHPOUNCE                       = 'Modo Buscar && trabajar';
  RC_SENDSPOT                           = 'Enviar spot';
  RC_RESCORE                            = 'Recalcular puntos';
  RC_TOOLS                              = 'Herramientas';
  RC_SYNPCTIME                          = 'Sincronizar hora PC';
  RC_BEACONSM                           = 'Monitor balizas';
  RC_WINCONTROL                         = 'Ventana de control';
  RC_SETTIMEZONE                        = 'Elegir zona horaria';
  RC_PING                               = 'Ping [SERVER ADDRESS]';
  RC_RUNSERVER                          = 'Ejecutar TR4WSERVER';
  RC_DVPVOLCONTROL                      = 'Control volumen DVP';
  RC_RECCONTROL                         = 'Control grabacion';
  RC_SOUNDRECORDER                      = 'Grabador sonido';
  RC_DISTANCE                           = 'Distancia';
  RC_GRID                               = 'Locator';
  RC_CALCULATOR                         = 'Calculadora';
  RC_LC                                 = 'LC';
  RC_NET                                = 'Red';
  RC_TIMESYN                            = 'Sincronizacion tiempo';
  RC_SENDMESSAGE                        = 'Enviar mensaje';
  RC_SYNLOG                             = 'Sincronizar log';
  RC_CLEARALLLOGS                       = 'Limpiar todos los logs de la red';
  RC_DOWNLOAD                           = 'Descargar la última version';
  RC_CONTENTS                           = 'Contenidos';
  RC_ABOUT                              = 'Acerca de';
//  RC_SAVEINFOLDER                       = 'Salvar en directorio ''[año][concurso][indicativo] ''';
  RC_CONFFILE                           = 'Fichero configuracion';
  RC_EDITQSO                            = 'Editar QSO';
  RC_DELETED                            = '&Borrados';
  RC_DUPE                               = 'Duplicado';
  RC_LOGSEARCH                          = 'Busqueda en el Log';
  RC_SEARCH                             = 'Buscar';
  RC_GETOFFSET                          = 'Elegir diferencia';
  RC_LOCALOFFSET                        = 'Diferencia horaria Local';
  RC_NTPSERVER                          = 'Servidor NTP';
  RC_SERVERANSWER                       = 'Respuesta servidor';
  RC_SYNCLOCK                           = 'Sincronizar reloj';
  RC_LOCALTIME                          = 'Hora local';
  RC_DUPESHEET2                         = 'Hoja duplicados';
  RC_SENDSPOT2                          = 'Enviar spot';
  RC_CONTESTNAMEIC                      = 'Nombre C&oncurso en comentario';
  RC_SEND                               = 'En&viar';
  RC_COMMENT                            = 'Comentario';
  RC_SENDINGCW                          = 'Enviar CW desde el teclado. Use ENTER/Escape/F10 para salir.';
  RC_RETURNTOMOD                        = 'RETURN para modificar';
  RC_ARROWTOSELIT                       = 'Flecha/pag.arriba/pag.abajo o 1ª letra para elegir item.';
  RC_ALTW                               = 'Alt-&W: salva entrada';
  RC_ALTN                               = 'Alt-&N: a la red';
  RC_ALTG                               = 'Alt-&G: todos los cambios a tr4w.ini';
  RC_BANDMAP2                           = 'Mapa de banda';
  RC_AUTOCQ2                            = 'Auto-CQ';
  RC_PRESSMKYWTR                        = 'Pulse la tecla de memoria que quiere repetir:';
  RC_NUMBEROSOLT                        = 'Numero de segundos tiempo de escucha:';
  RC_DELETESELSPOT                      = 'Borrar anuncios elegidos';
  RC_REMOVEALLSP                        = 'Borrar todos los anuncios';
  RC_SENDINRIG                          = 'Enviar emisora inactiva a la frecuencia';
  RC_COAX                               = 'Calculador longitud COAX';
  RC_ENTERTNHINIK                       = 'Entre the next highest impedance null in kHz:';
  RC_ENTERALIFIK                        = 'Enter a low impedance frequency in kHz:';
  RC_DISTANCEBTGS                       = 'Distancia entre dos cuadrículas locator';
  RC_SECONDGRID                         = 'Segunda cuadricula';
  RC_FIRSTGRID                          = 'Primera cuadricula';
  RC_EURVHFDIST                         = 'Distancia Europea VHF:';
  RC_GRIDOFAGLL                         = 'Locator de una lat/lon dada';
  RC_LONGMIE                            = 'Longitud (menos es este)';
  RC_LATMIS                             = 'Latitude (menos es sur)';
  RC_CALCOFCORI                         = 'Calculo def capacidad o inductancia';
  RC_INDUCANCE                          = 'Inductancia, uH';
  RC_CAPACITANCE                        = 'Capacidad, pf';
  RC_FREQOFRES                          = 'Frequencia de resonancia, khz';
  RC_WINCONTROL2                        = 'Ventana de control';
  RC_SHOWMENU                           = '&Ver menu';
  RC_RECVQTC                            = 'Recibiendo QTCs';
  RC_MIXWINTERFACE                      = 'MixW Interface';
  RC_CONNECTTOMIXW                      = 'Conectar con MixW';
  RC_MEMPROGFUNC                        = 'Funcion de Memorias';
  RC_PRESS_C                            = 'Pulse  &C  para programar la tecla funcion CQ.';
  RC_PRESS_E                            = 'Pulse  &E  para programar la tecla intercambio/buscar y trabajar S&P.';
  RC_PRESS_O                            = 'Pulse  &O  para programar otra tecla de no funcion.';
  RC_SYNLOG2                            = 'Sincronizar log';
  RC_GETSERVLOG                         = 'Co&ger el log del servidor';
  RC_RECVRECORDS                        = 'Registros recibidos:';
  RC_SENDRECORDS                        = 'Sended records:';
  RC_CREATEAUNL                         = '&Crear y usar un nuevo log';
  RC_RECVBYTES                          = 'Bytes recibidos:';
  RC_RECVQSOS                           = 'QSOs recibidos:';
  RC_SHOWSERVLOGC                       = 'Ver contenido del log servidor';
  RC_VIEWEDITLOG2                       = 'Ver / Editar log';
  RC_INTERCOM2                          = 'Intercom';
  RC_DIFFINLOG                          = 'Diferencia en logs';
  RC_ARCFILTER                          = 'Filtro banda-modo spots ARC';
  RC_DXSFILTER                          = 'Filtro banda-modo DXSpider';
  RC_CLEARFILTER                        = 'Borrar filtro';
  RC_STATIONS2                          = 'Estaciones';
  RC_C_EDITQSO                          = 'Editar QSO ';
  RC_C_DELETEQSO                        = 'Borrar QSO';
  RC_COPYTOCLIP                         = 'Copiar al portapapeles';
  RC_DUPECHECKOAR                       = 'Comprueba duplicados en radio inactiva';
  RC_WINKEYSET                          = 'Ajustes Winkeyer';
  RC_CT1BOHIS2                          = 'CT1BOH info screen';
  RC_DATE                               = 'Fecha';
  RC_NUMBERSENT                         = 'Numero Envd';
  RC_NUMBERRCVD                         = 'Numero Rcbd';
  RC_RSTSENT                            = 'RST enviado';
  RC_RSTRECEIVED                        = 'RST recibido';
  RC_QSOPOINTS                          = 'Puntos QSO';
  RC_AGE                                = 'Edad';
  RC_FREQUENCYHZ                        = 'Frecuencia, Hz';
  RC_PREFIX                             = 'Prefijo';
  RC_ZONE                               = 'Zona';
  RC_NAME                               = 'Nombre';
  RC_POSTALCODE                         = 'Codigo Postal';
  RC_POWER                              = 'Potencia';
  RC_PROGRMESS                          = 'Program message';
  RC_MESSAGE                            = 'Message';
  RC_CAPTION                            = 'Caption';
  RC_IAQSLINT                           = 'Auto QSL Interval (Increase)';
  RC_DAQSLINT                           = 'Auto QSL Interval (Decrease)';
  RC_ADDINFO                            = 'Additional information';
  RC_AI_QSONUMBER                       = 'QSO number';
  RC_AI_CALLSIGN                        = 'Callsign';
  RC_AI_CWSPEED                         = 'CW Speed';
  RC_AI_BAND                            = 'Band';
  RC_CLEARMSHEET                        = 'Clear multsheet';
  RC_WIKI                               = 'On-line documentation (in Russian)';
  RC_NET_CLDUPE                         = 'Clear dupesheet in all logs';
  RC_NET_CLMULT                         = 'Clear multsheet in all logs';
  RC_INC_TIME                           = 'Increment time';
  RC_NOTES                              = 'Notes';
  RC_DEFAULT                            = 'Default:';
  RC_DESCRIPTION                        = 'Description:';
  RC_DEVICEMANAGER                      = 'Device Manager';
  RC_SHDX_CALLSIGN                      = 'SH/DX [callsign]';
  RC_STATIONINFO                        = 'Station information';
  RC_MP3_RECENABLE                      = 'Enable';
  RC_PLAY                               = '&Play';
  RC_LISTOFMESS                         = 'List of messages';
  RC_LOGIN                              = 'Log in';
  RC_SYNCHRONIZE                        = 'Synchronize';
  RC_GET_OFFSET                         = 'Get offset';
  RC_COLORS                             = 'Colors';
  RC_APPEARANCE                         = 'Appearance';
  RC_BANDPLAN                           = 'Band plan';
  RC_WA7BNM_CALENDAR                    = 'WA7BNM'' s Contest Calendar';
  RC_SEND_BUG                           = 'Send bug report';
  RC_HOMEPAGE                           = 'TR4W Home Page';

  RC_OPERATOR                           = 'Operator';
  TC_LIST_OF_COMMAND                    = '&List of commands';
  TC_ENTERYOURBRANCHNUMBER              = 'Enter your Branch number:';
  TC_ENTERYOURPOSTCODE                  = 'Enter your postcode:';

