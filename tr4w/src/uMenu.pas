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
unit uMenu;

interface

uses
  VC,
  Windows;

type

  MenuRecord = record
    mrText: PChar;
    mrId: Word;
  end;

  PMenuRecord = ^MenuRecord;

function CreateTR4WMenu(m: PMenuRecord; s: integer; popup: boolean): HMENU;
const

  RC_EXIT_HK                            = #9'Alt+X';
  RC_OPTIONS_HK                         = #9'Ctrl+J';
  RC_PROGRAMMES_HK                      = #9'Alt+P';
  RC_RADIOONE_HK                        = #9'Ctrl+Alt+1';
  RC_RADIOTWO_HK                        = #9'Ctrl+Alt+2';
  RC_BANDMAP_HK                         = #9'Shift+Ctrl+`';
  RC_DUPESHEET_HK                       = #9'Shift+Ctrl+1';
  RC_FKEYS_HK                           = #9'Shift+Ctrl+2';
  RC_TRMASTER_HK                        = #9'Shift+Ctrl+3';
  RC_RM_DEFAULT_HK                      = #9'Shift+Ctrl+4';
  RC_RADIO1_HK                          = #9'Shift+Ctrl+5';
  RC_RADIO2_HK                          = #9'Shift+Ctrl+6';
  RC_INTERCOM_HK                        = #9'Shift+Ctrl+7';
  RC_GETSCORES_HK                       = #9'Shift+Ctrl+8';
  RC_STATIONS_HK                        = #9'Shift+Ctrl+9';
  RC_MP3REC_HK                          = #9'Shift+Ctrl+0';
  RC_ALARM_HK                           = #9'Alt+A';
  RC_AUTOCQRESUME_HK                    = #9'Alt+C';
  RC_DUPECHECK_HK                       = #9'Alt+D';
  RC_EDIT_HK                            = #9'Alt+E';
  RC_SAVETOFLOPPY_HK                    = #9'Alt+F';
  RC_SWAPMULTVIEW_HK                    = #9'Alt+G';
  RC_INCNUMBER_HK                       = #9'Alt+I';
  RC_TOOGLEMB_HK                        = #9'Alt+J';
  RC_KILLCW_HK                          = #9'Alt+K';
  RC_SEARCHLOG_HK                       = #9'Alt+L';

//  RC_REMINDER_HK                      = #9'Alt+O';
  RC_ALTP_HK                            = #9'Alt+P';
  RC_AUTOCQ_HK                          = #9'Alt+Q';
  RC_TOOGLERIGS_HK                      = #9'Alt+R';
  RC_CWSPEED_HK                         = #9'Alt+S';
  RC_SETSYSDT_HK                        = #9'Alt+T';
  RC_INITIALIZE_HK                      = #9'Alt+W';
  RC_RESETWAKEUP_HK                     = #9'Alt+Ctrl+W';
  RC_ALTX_HK                            = #9'Alt+X';
  RC_DELETELASTQSO_HK                   = #9'Alt+Y';
  RC_INITIALEX_HK                       = #9'Alt+Z';
  RC_TOOGLEST_HK                        = #9'Alt+=';
  RC_TOOGLEAS_HK                        = #9'Alt+-';
  RC_BANDUP_HK                          = #9'Alt+B';
  RC_BANDDOWN_HK                        = #9'Alt+V';
  RC_SSBCWMODE_HK                       = #9'Alt+M';
  RC_SENDKEYBOARD_HK                    = #9'Ctrl+A';
  RC_COMMWITHPP_HK                      = #9'Ctrl+B';
  RC_TRANSFREQ_HK                       = #9'Alt+O';
  RC_CTRLJ_HK                           = #9'Ctrl+J';
  RC_CLEARDUPES_HK                      = #9'Ctrl+K';
  RC_VIEWEDITLOG_HK                     = #9'Ctrl+L';
  RC_NOTE_HK                            = #9'Ctrl+N';
  RC_MISSMULTSREP_HK                    = #9'Ctrl+O';
  RC_REDOPOSSCALLS_HK                   = #9'Ctrl+P';
  RC_QTCFUNCTIONS_HK                    = #9'Ctrl+Q';
  RC_RECALLLASTENT_HK                   = #9'Ctrl+R';
 // RC_TRANSFREQ_HK                       = #9'Ctrl+T';
  RC_VIEWPAKSPOTS_HK                    = #9'Ctrl+U';
  RC_EXECONFIGFILE_HK                   = #9'Ctrl+V' ;
  RC_REFRESHBM_HK                       = #9'Ctrl+Y';
  RC_SPLITOFF_HK                        = #9'Ctrl+-';
  RC_CURSORINBM_HK                      = #9'Ctrl+End';
  RC_CURSORTELNET_HK                    = #9'Ctrl+Home';
  RC_QSOWITHNOCW_HK                     = #9'Ctrl+Enter';
  RC_CT1BOHIS_HK                        = #9'Ctrl+]';
  RC_ADDBANDMAPPH_HK                    = #9'Ctrl+Ins';
  RC_FOCUSINMW_HK                       = #9'Pause';
  RC_TOGGLEINSERT_HK                    = #9'Ins';
  RC_ESCAPE_HK                          = #9'Esc';
  RC_CWSPEEDUP_HK                       = #9'PgUp';
  RC_CWSPEEDDOWN_HK                     = #9'PgDn';
  RC_CWSPUPIR_HK                        = #9'Ctrl+PgUp';
  RC_CWSPDNIR_HK                        = #9'Ctrl+PgDn';
  RC_CQMODE_HK                          = #9'Shift+Tab';
  RC_SEARCHPOUNCE_HK                    = #9'Tab';
  RC_SENDSPOT_HK                        = #9'`';
  RC_WINCONTROL_HK                      = #9'Ctrl+Alt+M';
  RC_SYNPCTIME_HK                       = #9'Ctrl+Alt+N';
  RC_TIMESYN_HK                         = #9'Ctrl+Alt+T';
  RC_SENDMESSAGE_HK                     = #9'Shift+''';
  RC_SYNLOG_HK                          = #9'Ctrl+Alt+S';
  RC_CONTENTS_HK                        = #9'Alt+H';
  RC_DELETESELSPOT_HK                   = #9'Del';
  RC_C_EDITQSO_HK                       = #9'Enter';
  RC_IAQSLINT_HK                        = #9'Ctrl+I';
  RC_DAQSLINT_HK                        = #9'Ctrl+D';
  RC_AI_QSONUMBER_HK                    = #9'Ctrl+1';
  RC_AI_CALLSIGN_HK                     = #9'Ctrl+2';
  RC_AI_CWSPEED_HK                      = #9'Ctrl+3';
  RC_AI_BAND_HK                         = #9'Ctrl+4';
  RC_CLEARMSHEET_HK                     = #9'Ctrl+C';
  RC_SHDX_CALLSIGN_HK                   = #9'Ctrl+S';
  RC_LOGIN_HK                           = #9'Ctrl+Alt+I';


    T_MENU_ARRAY_SIZE                     = 170{$IF MMTTYMODE} + 1{$IFEND}{$IF LANG = 'RUS'} + 3{$IFEND};
  T_MENU_ARRAY                          : array[0..T_MENU_ARRAY_SIZE] of MenuRecord = (
    (mrText: RC_FILE; mrId: MAXWORD),
 //{
    (mrText: RC_CLEARLOG; mrId: menu_clear_log),
    (mrText: RC_OPENLOGDIR; mrId: menu_log_file_properties),
    (mrText: RC_IMPORT; mrId: MAXWORD - 1),
  //{
    (mrText: 'ADIF'; mrId: menu_import_adif),
  //}

    (mrText: RC_EXPORT; mrId: MAXWORD - 1),
  //{
    (mrText: 'ADIF'; mrId: menu_adif),
    (mrText: 'CSV'; mrId: menu_csv),
    (mrText: 'Cabrillo'#9'Ctrl+Alt+B'; mrId: menu_cabrillo),
    (mrText: 'EDI'; mrId: menu_export_edi),
    (mrText: RC_INIEXLIST; mrId: menu_initial_ex_list),
//    (mrText: RC_TRLOGFORM; mrId: menu_trlog),
    (mrText: RC_NOTES; mrId: menu_export_notes),
  //}

    (mrText: RC_REPORTS; mrId: MAXWORD - 1),
  //{
    (mrText: RC_ALLCALLS; mrId: menu_allcallsigns_list),
    (mrText: RC_BANDCHANGES; mrId: menu_band_changes),
    (mrText: RC_CONTLIST; mrId: menu_continentlist),
    (mrText: RC_FCC; mrId: menu_first_call_work_ineachcountry),
    (mrText: RC_FCZ; mrId: menu_first_call_work_InEachZone),
    (mrText: RC_QSOBYCOUNTRY; mrId: menu_qsobycountry),
    (mrText: RC_SCOREBYHOUR; mrId: menu_scorebyhour),
    (mrText: RC_SUMMARY; mrId: menu_summary),
  //}
    (mrText: nil; mrId: MAXWORD - 2),
    (mrText: '-'; mrId: 0),
    (mrText: RC_EXIT + RC_EXIT_HK; mrId: menu_exit),
 //}

    (mrText: RC_SETTINGS; mrId: MAXWORD),
 //{

    (mrText: '-'; mrId: 0),

    (mrText: RC_COLORS; mrId: menu_colors),
    (mrText: RC_APPEARANCE; mrId: menu_appearance),
    (mrText: 'Winkeyer'#9'Ctrl+W'; mrId: menu_winkeyer2),

    (mrText: RC_CATANDCW; mrId: MAXWORD - 1),
  //{
    (mrText: TC_RADIO1 + RC_RADIOONE_HK; mrId: menu_cat_radio_one),
    (mrText: TC_RADIO2 + RC_RADIOTWO_HK; mrId: menu_cat_radio_two),
  //}



    (mrText: nil; mrId: MAXWORD - 2),

    (mrText: '-'; mrId: 0),
    (mrText: RC_PROGRAMMES + RC_PROGRAMMES_HK; mrId: menu_messages),

    (mrText: 'LPT'#9'Ctrl+Alt+L'; mrId: menu_lpt),

 //}

    (mrText: RC_WINDOWS; mrId: MAXWORD),
 //{
    (mrText: RC_BANDMAP + RC_BANDMAP_HK; mrId: menu_windows_bandmap),

    (mrText: RC_DUPESHEET; mrId: MAXWORD - 1),
  //{
    (mrText: TC_RADIO1 + RC_DUPESHEET_HK; mrId: menu_windows_dupesheet1),
    (mrText: TC_RADIO2; mrId: menu_windows_dupesheet2),
  //}
    (mrText: nil; mrId: MAXWORD - 2),
    (mrText: RC_FKEYS + RC_FKEYS_HK; mrId: menu_windows_funckeys),
    (mrText: RC_TRMASTER + RC_TRMASTER_HK; mrId: menu_windows_trmasterdta),
    (mrText: RC_REMMULTS; mrId: MAXWORD - 1),
    (mrText: RC_RM_DEFAULT + RC_RM_DEFAULT_HK; mrId: menu_windows_remmults),

    (mrText: '-'; mrId: 0),
    (mrText: 'DX'; mrId: menu_rm_dx),
    (mrText: 'Domestic'; mrId: menu_rm_domestic),
    (mrText: 'Zones'; mrId: menu_rm_zone),
    (mrText: 'Prefixes'; mrId: menu_rm_prefix),
    (mrText: nil; mrId: MAXWORD - 2),
  //}

    (mrText: TC_RADIO1 + RC_RADIO1_HK; mrId: menu_windows_radiointerface1),
    (mrText: TC_RADIO2 + RC_RADIO2_HK; mrId: menu_windows_radiointerface2),
    (mrText: '-'; mrId: 0),
    (mrText: RC_TELNET; mrId: menu_windows_telnet),
    (mrText: RC_NETWORK; mrId: menu_windows_network),
    (mrText: '-'; mrId: 0),
    (mrText: RC_INTERCOM + RC_INTERCOM_HK; mrId: menu_windows_intercom),
    (mrText: RC_POSTSCORETOGS + RC_GETSCORES_HK; mrId: menu_windows_getscores),
    (mrText: RC_STATIONS + RC_STATIONS_HK; mrId: menu_windows_stations),
    (mrText: RC_MP3REC + RC_MP3REC_HK; mrId: menu_windows_mp3recorder),
{$IF MMTTYMODE}
    (mrText: 'MMTTY'; mrId: menu_windows_mmtty),
{$IFEND}
 //}

    (mrText: 'Alt-'; mrId: MAXWORD),
 //{
    (mrText: RC_INC_TIME; mrId: MAXWORD - 1),
  //{
    (mrText: '+1'#9'Alt+1'; mrId: menu_alt_increment_time_1),
    (mrText: '+2'#9'Alt+2'; mrId: menu_alt_increment_time_2),
    (mrText: '+3'#9'Alt+3'; mrId: menu_alt_increment_time_3),
    (mrText: '+4'#9'Alt+4'; mrId: menu_alt_increment_time_4),
    (mrText: '+5'#9'Alt+5'; mrId: menu_alt_increment_time_5),
    (mrText: '+6'#9'Alt+6'; mrId: menu_alt_increment_time_6),
    (mrText: '+7'#9'Alt+7'; mrId: menu_alt_increment_time_7),
    (mrText: '+8'#9'Alt+8'; mrId: menu_alt_increment_time_8),
    (mrText: '+9'#9'Alt+9'; mrId: menu_alt_increment_time_9),
    (mrText: '+10'#9'Alt+0'; mrId: menu_alt_increment_time_0),
  //}

    (mrText: '-'; mrId: MAXWORD - 2),
//    (mrText: RC_ALARM + RC_ALARM_HK; mrId: menu_alt_alarm),    //n4af 04.37.10
    (mrText: RC_BANDUP + RC_BANDUP_HK; mrId: menu_alt_bandup),
    (mrText: RC_AUTOCQRESUME + RC_AUTOCQRESUME_HK; mrId: menu_alt_autocqresume),
    (mrText: RC_DUPECHECK + RC_DUPECHECK_HK; mrId: menu_alt_dupecheck),
    (mrText: RC_EDIT + RC_EDIT_HK; mrId: menu_alt_edit),
    (mrText: RC_SAVETOFLOPPY + RC_SAVETOFLOPPY_HK; mrId: menu_alt_savetofloppy),
    (mrText: RC_SWAPMULTVIEW + RC_SWAPMULTVIEW_HK; mrId: menu_alt_swapmults),
    (mrText: RC_INCNUMBER + RC_INCNUMBER_HK; mrId: menu_alt_incnumber),
    (mrText: RC_TOOGLEMB + RC_TOOGLEMB_HK; mrId: menu_alt_multbell),
    (mrText: RC_SEARCHLOG + RC_SEARCHLOG_HK; mrId: menu_alt_searchlog),
    (mrText: RC_SSBCWMODE + RC_SSBCWMODE_HK; mrId: menu_alt_ssbcwmode),

//    (mrText: RC_REMINDER + RC_REMINDER_HK; mrId: menu_alt_reminder),
    (mrText: RC_TRANSFREQ + RC_TRANSFREQ_HK; mrId: menu_alt_transfreq),
    (mrText: RC_ALTP + RC_ALTP_HK; mrId: menu_alt_p),
    (mrText: RC_AUTOCQ + RC_AUTOCQ_HK; mrId: menu_alt_autocq),
    (mrText: RC_TOOGLERIGS + RC_TOOGLERIGS_HK; mrId: menu_alt_tooglerigs),
    (mrText: RC_CWSPEED + RC_CWSPEED_HK; mrId: menu_alt_cwspeed),
    (mrText: RC_SETSYSDT + RC_SETSYSDT_HK; mrId: menu_alt_settime),
    (mrText: RC_BANDDOWN + RC_BANDDOWN_HK; mrId: menu_alt_banddown),
    (mrText: RC_INITIALIZE + RC_INITIALIZE_HK; mrId: menu_alt_init_qso),
    (mrText: RC_ALTX + RC_ALTX_HK;         mrId: menu_alt_x),
    (mrText: RC_DELETELASTQSO + RC_DELETELASTQSO_HK; mrId: menu_alt_deleteqso),
    (mrText: RC_INITIALEX + RC_INITIALEX_HK; mrId: menu_alt_initialexhange),
    (mrText: RC_TOOGLEST + RC_TOOGLEST_HK; mrId: menu_alt_tooglesidetone),
    (mrText: RC_TOOGLEAS + RC_TOOGLEAS_HK; mrId: menu_alt_toogleautosend),
    (mrText: '-'; mrId: 0),



 //}

    (mrText: 'Ctrl-'; mrId: MAXWORD),
 //{
    (mrText: RC_SENDKEYBOARD + RC_SENDKEYBOARD_HK; mrId: menu_ctrl_sendkeyboardinput),
    (mrText: RC_CLEARMSHEET + RC_CLEARMSHEET_HK; mrId: menu_ctrl_clearmultsheet),
//    (mrText: RC_DAQSLINT + RC_DAQSLINT_HK; mrId: menu_ctrl_decAQSLinterval),  //n4af 04.37.10
 //   (mrText: RC_IAQSLINT + RC_IAQSLINT_HK; mrId: menu_ctrl_incAQSLinterval),   //n4af 04.37.10
    (mrText: RC_OPTIONS + RC_OPTIONS_HK; mrId: menu_options),
    (mrText: RC_CLEARDUPES + RC_CLEARDUPES_HK; mrId: menu_ctrl_cleardupesheet),
    (mrText: RC_VIEWEDITLOG + RC_VIEWEDITLOG_HK; mrId: menu_ctrl_viewlogdat),
    (mrText: RC_NOTE + RC_NOTE_HK; mrId: menu_ctrl_note),
//    (mrText: RC_MISSMULTSREP + RC_MISSMULTSREP_HK; mrId: menu_ctrl_missmultsreport),  //n4af 04/37.10
    (mrText: RC_REDOPOSSCALLS + RC_REDOPOSSCALLS_HK; mrId: menu_ctrl_redoposscalls),
    (mrText: RC_QTCFUNCTIONS + RC_QTCFUNCTIONS_HK; mrId: menu_ctrl_qtcfunctions),
    (mrText: RC_RECALLLASTENT + RC_RECALLLASTENT_HK; mrId: menu_ctrl_recalllastentry),
    (mrText: RC_SHDX_CALLSIGN + RC_SHDX_CALLSIGN_HK; mrId: menu_ctrl_shdxcallsign),
//    (mrText: RC_VIEWPAKSPOTS + RC_VIEWPAKSPOTS_HK; mrId: menu_ctrl_viewpacketspots),
    (mrText: RC_EXECONFIGFILE + RC_EXECONFIGFILE_HK; mrId: menu_ctrl_execute_config),
    (mrText: RC_REFRESHBM + RC_REFRESHBM_HK; mrId: menu_ctrl_refreshbandmap),
    (mrText: RC_CURSORINBM + RC_CURSORINBM_HK; mrId: menu_ctrl_cursorinbandmap),
    (mrText: RC_QSOWITHNOCW + RC_QSOWITHNOCW_HK; mrId: menu_ctrl_logqsowithoutcw),
    (mrText: RC_CURSORTELNET + RC_CURSORTELNET_HK; mrId: menu_ctrl_cursorintelnet),
    (mrText: RC_ADDBANDMAPPH + RC_ADDBANDMAPPH_HK; mrId: menu_ctrl_PlaceHolder),
    (mrText: RC_SPLITOFF + RC_SPLITOFF_HK; mrId: menu_ctrl_SplitOff),      // n4af 4.46.8
    (mrText: RC_CT1BOHIS + RC_CT1BOHIS_HK; mrId: menu_ctrl_ct1bohscreen),
    (mrText: RC_ADDINFO; mrId: MAXWORD - 1),
  //{
    (mrText: RC_AI_QSONUMBER + RC_AI_QSONUMBER_HK; mrId: menu_ctrl_showQSONumber),
    (mrText: RC_CALLSIGN + RC_AI_CALLSIGN_HK; mrId: menu_ctrl_showCallsign),
    (mrText: RC_AI_CWSPEED + RC_AI_CWSPEED_HK; mrId: menu_ctrl_showSpeed),
    (mrText: RC_BAND + RC_AI_BAND_HK; mrId: menu_ctrl_showBand),
  //}

 //}

    (mrText: RC_COMMANDS; mrId: MAXWORD),
 //{
    (mrText: RC_FOCUSINMW + RC_FOCUSINMW_HK; mrId: menu_mainwindow_setfocus),
    (mrText: RC_TOGGLEINSERT + RC_TOGGLEINSERT_HK; mrId: menu_insertmode),
    (mrText: RC_ESCAPE + RC_ESCAPE_HK; mrId: menu_escape),
    (mrText: '-'; mrId: 0),
    (mrText: RC_CWSPEEDUP + RC_CWSPEEDUP_HK; mrId: menu_cwspeedup),
    (mrText: RC_CWSPEEDDOWN + RC_CWSPEEDDOWN_HK; mrId: menu_cwspeeddown),
    (mrText: '-'; mrId: 0),
    (mrText: RC_CWSPUPIR + RC_CWSPUPIR_HK; mrId: menu_inactiveradio_cwspeedup),
    (mrText: RC_CWSPDNIR + RC_CWSPDNIR_HK; mrId: menu_inactiveradio_cwspeeddown),
    (mrText: '-'; mrId: 0),
    (mrText: RC_CQMODE + RC_CQMODE_HK; mrId: menu_cqmode),
    (mrText: RC_SEARCHPOUNCE + RC_SEARCHPOUNCE_HK; mrId: menu_spmode_ortab),
    (mrText: '-'; mrId: 0),
    (mrText: RC_LOGIN + RC_LOGIN_HK; mrId: menu_login),
    (mrText: '-'; mrId: 0),
    (mrText: RC_SENDSPOT + RC_SENDSPOT_HK; mrId: menu_ctrl_sendspot),
    (mrText: RC_RESCORE; mrId: menu_rescore),
 //}

    (mrText: RC_TOOLS; mrId: MAXWORD),
 //{
    (mrText: RC_SYNPCTIME + RC_SYNPCTIME_HK; mrId: menu_syncpctime),
    (mrText: RC_BEACONSM; mrId: menu_beaconsmonitor),
    (mrText: RC_WINCONTROL + RC_WINCONTROL_HK; mrId: menu_windowsmanager),
    (mrText: RC_SETTIMEZONE; mrId: menu_settimezone),
    (mrText: RC_DEVICEMANAGER; mrId: menu_run_devicemanager),
    (mrText: '-'; mrId: 0),
    (mrText: RC_PING; mrId: menu_pingserver),
    (mrText: RC_RUNSERVER; mrId: menu_runserver),
    (mrText: '-'; mrId: 0),
    (mrText: RC_DVKVOLCONTROL; mrId: menu_volume_control),
    (mrText: RC_RECCONTROL; mrId: menu_recording_control),
    (mrText: '-'; mrId: 0),
    (mrText: ''; mrId: menu_sk3bg_calendar),
    (mrText: ''; mrId: menu_qrzru_calendar),
    (mrText: RC_WA7BNM_CALENDAR; mrId: menu_wa7bnm_calendar),
    (mrText: '-'; mrId: 0),
    (mrText: RC_CALCULATOR; mrId: item_calculator),
 //}

    (mrText: RC_NET; mrId: MAXWORD),
 //{
    (mrText: RC_TIMESYN + RC_TIMESYN_HK; mrId: menu_alt_setnettime),
    (mrText: RC_SENDMESSAGE + RC_SENDMESSAGE_HK; mrId: menu_send_message),
    (mrText: RC_SYNLOG + RC_SYNLOG_HK; mrId: menu_getserverlog),
    (mrText: '-'; mrId: 0),
    (mrText: RC_CLEARALLLOGS; mrId: menu_clearserverlog),
    (mrText: '-'; mrId: 0),
    (mrText: RC_NET_CLDUPE; mrId: menu_clear_dupesheet_in_network),
    (mrText: RC_NET_CLMULT; mrId: menu_clear_multsheet_in_network),
 //}

    (mrText: HELP_WORD; mrId: MAXWORD),        // n4af 4.42.5
 //{
{$IF LANG = 'RUS'}
    (mrText: RC_CONTENTS + RC_CONTENTS_HK; mrId: menu_contents),
    (mrText: '-'; mrId: 0),
{$IFEND}
//    (mrText: RC_SEND_BUG; mrId: menu_send_bug),
//    (mrText: '-'; mrId: 0),
//    (mrText: RC_DOWNLOAD; mrId: menu_download_latest_version),
    (mrText: RC_HOMEPAGE; mrId: menu_home_page),
{$IF LANG = 'RUS'}
    (mrText: RC_WIKI; mrId: menu_wiki_rus),
{$IFEND}
//    (mrText: 'History.txt'; mrId: menu_historytxt),
    (mrText: RC_ABOUT; mrId: menu_about)

    );

  B_MENU_ARRAY_SIZE                     = 9;
  B_MENU_ARRAY                          : array[0..B_MENU_ARRAY_SIZE] of MenuRecord = (
    (mrText: 'BAND MAP ALL BANDS'#9'B'; mrId: 66),
    (mrText: 'BAND MAP ALL MODES'#9'M'; mrId: 77),
    (mrText: 'BAND MAP DISPLAY CQ'; mrId: 202),
    (mrText: 'BAND MAP DUPE DISPLAY'#9'D'; mrId: 68),
    (mrText: 'BAND MAP MULTS ONLY'; mrId: 69),
    (mrText: '-'; mrId: 0),
    (mrText: RC_DELETESELSPOT; mrId: 203),
    (mrText: RC_REMOVEALLSP; mrId: 204),
    (mrText: '-'; mrId: 0),
    (mrText: RC_SENDINRIG; mrId: 205)
    );

  E_MENU_ARRAY_SIZE                     = 7;
  E_MENU_ARRAY                          : array[0..E_MENU_ARRAY_SIZE] of MenuRecord = (
    (mrText: '&File'; mrId: MAXWORD),
    (mrText: 'Open with &Notepad'; mrId: 101),
    (mrText: 'Explore'; mrId: 107),
    (mrText: '-'; mrId: 0),
    (mrText: 'E&xit'; mrId: 102),
    (mrText: '&Edit'; mrId: MAXWORD),
    (mrText: '&Copy '#9'Ctrl+C'; mrId: 103),
    (mrText: 'Select &all '#9'Ctrl+A'; mrId: 104));

implementation

function CreateTR4WMenu(m: PMenuRecord; s: integer; popup: boolean): HMENU;
var
  i                                     : integer;
  uFlags                                : UINT;
  TempMenuRecord                        : MenuRecord;
//  TempMenu                              : HMENU;

  CurrMenu                              : HMENU;
  LatestMenu                            : HMENU;
begin
  if popup then
    Result := CreatePopupMenu
  else
    Result := CreateMenu;

  LatestMenu := Result;
  CurrMenu := Result;

  for i := 0 to s do
  begin
    TempMenuRecord := PMenuRecord(integer(m) + (SizeOf(MenuRecord) * i))^;
    uFlags := MF_STRING;
    if TempMenuRecord.mrText <> nil then
      if TempMenuRecord.mrText[0] = '-' then uFlags := MF_SEPARATOR;

    if TempMenuRecord.mrId = MAXWORD then
    begin
      CurrMenu := CreatePopupMenu;
      LatestMenu := CurrMenu;

      Windows.AppendMenu(Result, MF_STRING + MF_POPUP, CurrMenu, TempMenuRecord.mrText);
      Continue;
    end;

    if TempMenuRecord.mrId = MAXWORD - 1 then
    begin
      CurrMenu := CreatePopupMenu;
      Windows.AppendMenu(LatestMenu, MF_STRING + MF_POPUP, CurrMenu, TempMenuRecord.mrText);
      Continue;
    end;
    if TempMenuRecord.mrId = MAXWORD - 2 then
    begin
      CurrMenu := LatestMenu;
      Continue;
    end;
    Windows.AppendMenu(CurrMenu, uFlags, TempMenuRecord.mrId, TempMenuRecord.mrText);
  end;

{
  TempMenu := Result;

  for i := 0 to s do
  begin
    TempMenuRecord := PMenuRecord(integer(m) + (SizeOf(MenuRecord) * i))^;
    uFlags := MF_STRING;
    if TempMenuRecord.mrText[0] = '-' then uFlags := MF_SEPARATOR;

    if TempMenuRecord.mrId = MAXWORD then
    begin
      TempMenu := CreatePopupMenu;
      Windows.AppendMenu(Result, MF_STRING + MF_POPUP, TempMenu, TempMenuRecord.mrText);
    end
    else
      Windows.AppendMenu(TempMenu, uFlags, TempMenuRecord.mrId, TempMenuRecord.mrText);
  end;
}
end;

end.

