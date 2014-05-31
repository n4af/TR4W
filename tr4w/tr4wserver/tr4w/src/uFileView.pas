unit uFileView;
{$IMPORTEDDATA OFF}
interface
uses
  VC,
  TF,
//  mapi,
//  CommCtrl,
  uMenu,
  Windows,
  Tree,
  LogWind,
  PostUnit,
  Messages;

const
  MAPI_DIALOG                           = $00000008; { Display a send note UI       }
  MAPI_UNREAD                           = $00000001;
  MAPI_RECEIPT_REQUESTED                = $00000002;
  MAPI_SENT                             = $00000004;

  MAPI_ORIG                             = 0; { Recipient is message originator          }

  MAPI_TO                               = 1; { Recipient is a primary recipient         }

  MAPI_CC                               = 2; { Recipient is a copy recipient            }

  MAPI_BCC                              = 3; { Recipient is blind copy recipient        }

  MAPI_LOGON_UI                         = $00000001; { Display logon UI             }
  MAPI_NEW_SESSION                      = $00000002; { Don't use shared session     }
  SUCCESS_SUCCESS                       = 0;
type

  Flags = Cardinal;
  LHANDLE = Cardinal;
  PLHANDLE = ^Cardinal;

  TEditStreamCallBack = function(dwCookie: LONGINT; pbBuff: PByte; cb: LONGINT; var pcb: LONGINT): LONGINT; stdcall;

  PMapiRecipDesc = ^TMapiRecipDesc;
{$EXTERNALSYM MapiRecipDesc}
  MapiRecipDesc = packed record
    ulReserved: Cardinal; { Reserved for future use                  }
    ulRecipClass: Cardinal; { Recipient class                          }
                                { MAPI_TO, MAPI_CC, MAPI_BCC, MAPI_ORIG    }
    lpszName: LPSTR; { Recipient name                           }
    lpszAddress: LPSTR; { Recipient address (optional)             }
    ulEIDSize: Cardinal; { Count in bytes of size of pEntryID       }
    lpEntryID: Pointer; { System-specific recipient reference      }
  end;
  TMapiRecipDesc = MapiRecipDesc;

  PMapiFileDesc = ^TMapiFileDesc;
  MapiFileDesc = packed record
    ulReserved: Cardinal; { Reserved for future use (must be 0)     }
    flFlags: Cardinal; { Flags                                   }
    nPosition: Cardinal; { character in text to be replaced by attachment }
    lpszPathName: LPSTR; { Full path name of attachment file       }
    lpszFileName: LPSTR; { Original file name (optional)           }
    lpFileType: Pointer; { Attachment file type (can be lpMapiFileTagExt) }
  end;
  TMapiFileDesc = MapiFileDesc;

  MapiMessage = packed record
    ulReserved: Cardinal; { Reserved for future use (M.B. 0)       }
    lpszSubject: LPSTR; { Message Subject                        }
    lpszNoteText: LPSTR; { Message Text                           }
    lpszMessageType: LPSTR; { Message Class                          }
    lpszDateReceived: LPSTR; { in YYYY/MM/DD HH:MM format             }
    lpszConversationID: LPSTR; { conversation thread ID                 }
    flFlags: Cardinal; { unread,return receipt                  }
    lpOriginator: PMapiRecipDesc; { Originator descriptor                  }
    nRecipCount: Cardinal; { Number of recipients                   }
    lpRecips: PMapiRecipDesc; { Recipient descriptors                  }
    nFileCount: Cardinal; { # of file attachments                  }
    lpFiles: PMapiFileDesc; { Attachment descriptors                 }
  end;
  TMapiMessage = MapiMessage;

  TFNMapiLogOff = function(lhSession: LHANDLE; ulUIParam: Cardinal; flFlags: Flags;
    ulReserved: Cardinal): Cardinal stdcall;

  TMAPISendDocuments = function(ulUIParam: Cardinal; lpszDelimChar: LPSTR; lpszFilePaths: LPSTR; lpszFileNames: LPSTR; ulReserved: Cardinal): Cardinal; stdcall;

  TFNMapiLogOn = function(ulUIParam: Cardinal; lpszProfileName: LPSTR;
    lpszPassword: LPSTR; flFlags: Cardinal; ulReserved: Cardinal;
    lplhSession: PLHANDLE): Cardinal stdcall;

  TFNMapiSendMail = function
    (
    lhSession: LHANDLE;
    ulUIParam: Cardinal;
    var lpMessage: TMapiMessage;
//    lpRecips: PMapiRecipDesc;
//    Files: MapiFileDesc;
    flFlags: Flags;
    ulReserved: Cardinal
    ): Cardinal stdcall;

{$EXTERNALSYM _editstream}
  _editstream = record
    dwCookie: LONGINT;
    dwError: LONGINT;
    pfnCallback: TEditStreamCallBack;
  end;

const
  EM_STREAMIN                           = WM_USER + 73;
  EM_SETBKGNDCOLOR                      = WM_USER + 67;
  ES_SAVESEL                            = $00008000;

  { stream formats }

const
{$EXTERNALSYM SF_TEXT}
  SF_TEXT                               = $0001;
{$EXTERNALSYM SF_RTF}
  SF_RTF                                = $0002;
{$EXTERNALSYM SF_RTFNOOBJS}
  SF_RTFNOOBJS                          = $0003; { outbound only }
{$EXTERNALSYM SF_TEXTIZED}
  SF_TEXTIZED                           = $0004; { outbound only }
{$EXTERNALSYM SF_UNICODE}
  SF_UNICODE                            = $0010; { Unicode file of some kind }

  { Flag telling stream operations to operate on the selection only }
  { EM_STREAMIN will replace the current selection }
  { EM_STREAMOUT will stream out the current selection }

{$EXTERNALSYM SFF_SELECTION}
  SFF_SELECTION                         = $8000;

  { Flag telling stream operations to operate on the common RTF keyword only }
  { EM_STREAMIN will accept the only common RTF keyword }
  { EM_STREAMOUT will stream out the only common RTF keyword }

{$EXTERNALSYM SFF_PLAINRTF}
  SFF_PLAINRTF                          = $4000;
  ReadError                             = $0001;

function FullLogDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
function OpenCallback(dwCookie: LONGINT; pbBuff: PByte; cb: LONGINT; var pcb: LONGINT): LONGINT; stdcall;
procedure SendMail(Address: PChar; BugReport: boolean);

var
  MAPISendDocuments                     : TMAPISendDocuments;
//  MapiLogOn                             : TFNMapiLogOn;
//  MapiLogOff                            : TFNMapiLogOff;
  MapiSendMail                          : TFNMapiSendMail;
  RichEditViewer                        : HWND;

implementation
uses MainUnit;

function FullLogDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label
  1;
var
  TempHWND                              : HWND;
  lpStream                              : _editstream;
  Menu                                  : HMENU;
begin
  Result := False;
  case Msg of
    WM_TIMER:
      begin
        Windows.KillTimer(hwnddlg, 1);
        if not TF.tOpenFileForRead(TempHWND, PreviewFileNameAddress) then Exit;
        lpStream.dwCookie := TempHWND;
        lpStream.dwError := 0;
        lpStream.pfnCallback := @OpenCallback;
        SendMessage(RichEditViewer, EM_STREAMIN, SF_TEXT, LONGINT(@lpStream));
        CloseHandle(TempHWND);
      end;

    WM_INITDIALOG:
      begin
        //Windows.SetMenu(hwnddlg, LoadMenu(hInstance, 'E'));

        Windows.SetMenu(hwnddlg, CreateTR4WMenu(@E_MENU_ARRAY, E_MENU_ARRAY_SIZE, False));

        RichEditViewer := CreateRichEdit(hwnddlg);

//        SendMessage(RichEditViewer, EM_SETBKGNDCOLOR, 0, $0000FFff);

        if PreviewFileIsCabrillo then
        begin
          Menu := GetMenu(hwnddlg);
          if ContestsArray[Contest].Email <> nil then
          begin
            Format(wsprintfBuffer, 'Send log to %s', ContestsArray[Contest].Email);
            AppendMenu(Menu, MF_CHECKED + MF_STRING, 105, wsprintfBuffer);
          end;

          if Contest in [DARCWAEDCCW, DARCWAEDCSSB, RUSSIANDX, IARU, ARRL160, ARRL10, ARRLSSCW, ARRLSSSSB, ARRLDXCW, ARRLDXSSB, CQ160CW, CQ160SSB, CQWPXCW, CQWPXSSB, CQWWCW, CQWWSSB, CQWWRTTY] then
            AppendMenu(Menu, MF_STRING, 106, 'Contribute log for SCP database');
        end;
//        RichEditViewer := Get101Window(hwnddlg);
        SetWindowText(hwnddlg, PreviewFileNameAddress);
        Windows.SetTimer(hwnddlg, 1, 50, nil);
      end;

{$IF LANG = 'RUS'}
    WM_HELP: ShowHelp('ru_fileviewwindow');
{$IFEND}

    WM_COMMAND:

      case wParam of
        101:
          begin
            Format(wsprintfBuffer, 'Notepad %s', PreviewFileNameAddress);
            WinExec(wsprintfBuffer, SW_SHOWMAXIMIZED);
          end;
{
        102:
          begin
            TempHWND := LoadLibrary('Mapi32.dll');
            if TempHWND <> 0 then
            begin
              @MAPISendDocuments := GetProcAddress(TempHWND, 'MAPISendDocuments');
              if @MAPISendDocuments <> nil then
                MAPISendDocuments(hwnddlg, ';', PreviewFileNameAddress, @MyCall[1], 0);
              FreeLibrary(TempHWND);
            end;
          end;
}
        105: SendMail(ContestsArray[Contest].Email, False);
        106: SendMail('logs@supercheckpartial.com', False);
        107: RunExplorer(PreviewFileNameAddress);
        103: SendMessage(RichEditViewer, WM_COPY, 0, 0);
        104: SendMessage(RichEditViewer, EM_SETSEL, 0, -1);
        102, 2: goto 1;
      end;

    WM_SIZE: tListBoxClientAlign(hwnddlg);
    WM_CLOSE: 1:
      begin
        PreviewFileIsCabrillo := False;
        EndDialog(hwnddlg, 0);
      end;

    WM_NCDESTROY:
      begin
        //            if MMTTYRichEdit = INVALID_HANDLE_VALUE then
        begin
          RichEditOperation(False);
//          FreeLibrary(RICHED32DLLHANDLE);
//          RICHED32DLLHANDLE := 0;
        end;
      end;
  end;
end;

procedure SendMail(Address: PChar; BugReport: boolean);
var
  module                                : HWND;
  lpMessage                             : TMapiMessage;
  Files                                 : array[0..3] of MapiFileDesc;

  lpRecips                              : TMapiRecipDesc;
  TempBuffer                            : array[0..63] of Char;
  MapiResult                            : Cardinal;
begin
  module := LoadLibrary('Mapi32.dll');
  if module <> 0 then
  begin
    @MapiSendMail := GetProcAddress(module, 'MAPISendMail');
    Windows.ZeroMemory(@lpMessage, SizeOf(TMapiMessage));
    Windows.ZeroMemory(@lpRecips, SizeOf(TMapiRecipDesc));
    Windows.ZeroMemory(@Files, SizeOf(Files));

    lpMessage.lpRecips := @lpRecips;
    lpMessage.lpFiles := @Files;

    if BugReport then
    begin
{
      lpMessage.lpszSubject := '[Bug Report] ' + TR4W_CURRENTVERSION;
      Format(wsprintfBuffer, 'Version: ' + TR4W_CURRENTVERSION + ' (' + TR4W_CURRENTVERSIONDATE + ')'#13#10'OS: %u.%u %s'#13#10'Attached 3 files.'#13#10#13#10'Description:'#13#10, tr4w_osverinfo.dwMajorVersion, tr4w_osverinfo.dwMinorVersion, tr4w_osverinfo.szCSDVersion);
      lpMessage.lpszNoteText := wsprintfBuffer;
      lpMessage.nFileCount := 3;

      Files[0].lpszPathName := TR4W_POS_FILENAME;
      Files[1].lpszPathName := TR4W_CFG_FILENAME;
      Files[2].lpszPathName := TR4W_INI_FILENAME;
}
    end
    else
    begin
      lpMessage.lpszSubject := @MyCall[1];

      lpMessage.nFileCount := 1;
      Files[0].lpszPathName := PreviewFileNameAddress;
    end;

    Files[0].nPosition := ULONG($FFFFFFFF);

    lpMessage.nRecipCount := 1;
    lpMessage.flFlags := MAPI_UNREAD;
    Format(TempBuffer, 'SMTP:%s', Address);
    lpRecips.lpszAddress := TempBuffer;
    lpRecips.ulRecipClass := MAPI_TO;

    MapiResult := MapiSendMail(0, tr4whandle, lpMessage, MAPI_LOGON_UI or MAPI_DIALOG, 0);
    if MapiResult > 1 then
    begin
      Format(wsprintfBuffer, 'Send Mail Error: %u', MapiResult);
      showwarning(wsprintfBuffer);
    end;

    FreeLibrary(module);
  end;
end;

function OpenCallback(dwCookie: LONGINT; pbBuff: PByte; cb: LONGINT; var pcb: LONGINT): LONGINT; stdcall;
//var
//  lpNumberOfBytesRead                   : DWORD;
begin
  Windows.ReadFile(dwCookie, pbBuff^, cb, Cardinal(pcb), nil);
//  pcb := _lread(dwCookie, pbBuff, cb);
  if pcb <= 0 {-1} then
  begin
    pcb := 0;
    Result := ReadError;
  end
  else Result := NoError;
end;

end.

