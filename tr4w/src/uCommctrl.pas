unit uCommctrl;
{$IMPORTEDDATA OFF}

interface

uses
  Messages,
  Windows;

type

  HDSA = longword;

{$EXTERNALSYM tagNMCUSTOMDRAWINFO}
  tagNMCUSTOMDRAWINFO = packed record
    hdr: TNMHDR;
    dwDrawStage: DWORD;
    HDC: HDC;
    RC: TRect;
    dwItemSpec: DWORD; // this is control specific, but it's how to specify an item.  valid only with CDDS_ITEM bit set
    uItemState: UINT;
    lItemlParam: lParam;
  end;
  PNMCustomDraw = ^TNMCustomDraw;
  TNMCustomDraw = tagNMCUSTOMDRAWINFO;

type
{$EXTERNALSYM tagNMLVCUSTOMDRAW}
//  TNMCustomDraw = tagNMCUSTOMDRAWINFO;
  tagNMLVCUSTOMDRAW = packed record
    nmcd: TNMCustomDraw;
    clrText: COLORREF;
    clrTextBk: COLORREF;
    iSubItem: integer;
  end;
  PNMLVCustomDraw = ^TNMLVCustomDraw;
  TNMLVCustomDraw = tagNMLVCUSTOMDRAW;

{$EXTERNALSYM tagNMTTCUSTOMDRAW}
  tagNMTTCUSTOMDRAW = packed record
    nmcd: TNMCustomDraw;
    uDrawFlags: UINT;
  end;
  PNMTTCustomDraw = ^TNMTTCustomDraw;
  TNMTTCustomDraw = tagNMTTCUSTOMDRAW;

  { ==================== CUSTOM DRAW ========================================== }

const
  DSA_APPEND                            = $7FFFFFFF;
  DSA_ERR                               = -1;

  TTM_TRACKACTIVATE                     = WM_USER + 17; // wParam = TRUE/FALSE start end  lparam = LPTOOLINFO
  TTM_TRACKPOSITION                     = WM_USER + 18; // lParam = dwPos
  // custom draw return flags
  // values under 0x00010000 are reserved for global custom draw values.
  // above that are for specific controls
{$EXTERNALSYM CDRF_DODEFAULT}
  CDRF_DODEFAULT                        = $00000000;
{$EXTERNALSYM CDRF_NEWFONT}
  CDRF_NEWFONT                          = $00000002;
{$EXTERNALSYM CDRF_SKIPDEFAULT}
  CDRF_SKIPDEFAULT                      = $00000004;

{$EXTERNALSYM CDRF_NOTIFYPOSTPAINT}
  CDRF_NOTIFYPOSTPAINT                  = $00000010;
{$EXTERNALSYM CDRF_NOTIFYITEMDRAW}
  CDRF_NOTIFYITEMDRAW                   = $00000020;
{$EXTERNALSYM CDRF_NOTIFYSUBITEMDRAW}
  CDRF_NOTIFYSUBITEMDRAW                = $00000020; // flags are the same, we can distinguish by context
{$EXTERNALSYM CDRF_NOTIFYPOSTERASE}
  CDRF_NOTIFYPOSTERASE                  = $00000040;

  // drawstage flags
  // values under = $00010000 are reserved for global custom draw values.
  // above that are for specific controls
{$EXTERNALSYM CDDS_PREPAINT}
  CDDS_PREPAINT                         = $00000001;
{$EXTERNALSYM CDDS_POSTPAINT}
  CDDS_POSTPAINT                        = $00000002;
{$EXTERNALSYM CDDS_PREERASE}
  CDDS_PREERASE                         = $00000003;
{$EXTERNALSYM CDDS_POSTERASE}
  CDDS_POSTERASE                        = $00000004;
  // the = $000010000 bit means it's individual item specific
{$EXTERNALSYM CDDS_ITEM}
  CDDS_ITEM                             = $00010000;
{$EXTERNALSYM CDDS_ITEMPREPAINT}
  CDDS_ITEMPREPAINT                     = CDDS_ITEM or CDDS_PREPAINT;
{$EXTERNALSYM CDDS_ITEMPOSTPAINT}
  CDDS_ITEMPOSTPAINT                    = CDDS_ITEM or CDDS_POSTPAINT;
{$EXTERNALSYM CDDS_ITEMPREERASE}
  CDDS_ITEMPREERASE                     = CDDS_ITEM or CDDS_PREERASE;
{$EXTERNALSYM CDDS_ITEMPOSTERASE}
  CDDS_ITEMPOSTERASE                    = CDDS_ITEM or CDDS_POSTERASE;
{$EXTERNALSYM CDDS_SUBITEM}
  CDDS_SUBITEM                          = $00020000;

  // itemState flags
{$EXTERNALSYM CDIS_SELECTED}
  CDIS_SELECTED                         = $0001;
{$EXTERNALSYM CDIS_GRAYED}
  CDIS_GRAYED                           = $0002;
{$EXTERNALSYM CDIS_DISABLED}
  CDIS_DISABLED                         = $0004;
{$EXTERNALSYM CDIS_CHECKED}
  CDIS_CHECKED                          = $0008;
{$EXTERNALSYM CDIS_FOCUS}
  CDIS_FOCUS                            = $0010;
{$EXTERNALSYM CDIS_DEFAULT}
  CDIS_DEFAULT                          = $0020;
{$EXTERNALSYM CDIS_HOT}
  CDIS_HOT                              = $0040;
{$EXTERNALSYM CDIS_MARKED}
  CDIS_MARKED                           = $0080;
{$EXTERNALSYM CDIS_INDETERMINATE}
  CDIS_INDETERMINATE                    = $0100;

  { Interface for the Windows Property Sheet Pages }

const
{$EXTERNALSYM TOOLTIPS_CLASS}
  TOOLTIPS_CLASS                        = 'tooltips_class32';

const
  LVM_FIRST                             = $1000; { ListView messages }
  TV_FIRST                              = $1100; { TreeView messages }
  HDM_FIRST                             = $1200; { Header messages }
  TCM_FIRST                             = $1300; { Tab control messages }
  PGM_FIRST                             = $1400; { Pager control messages }
  CCM_FIRST                             = $2000; { Common control shared messages }

  CCM_SETBKCOLOR                        = CCM_FIRST + 1; // lParam is bkColor

const
  PBS_MARQUEE                           = $08;
  PBM_SETMARQUEE                        = WM_USER + 10;

  PBS_SMOOTH                            = $01;
  PBS_VERTICAL                          = $04;

  PBM_SETRANGE                          = WM_USER + 1;
  PBM_SETPOS                            = WM_USER + 2;
  PBM_DELTAPOS                          = WM_USER + 3;
  PBM_SETSTEP                           = WM_USER + 4;
  PBM_STEPIT                            = WM_USER + 5;
  PBM_SETRANGE32                        = WM_USER + 6; // lParam = high, wParam = low
  PBM_GETRANGE                          = WM_USER + 7; // lParam = PPBRange or Nil
  // wParam = False: Result = high
  // wParam = True: Result = low
  PBM_GETPOS                            = WM_USER + 8;
  PBM_SETBARCOLOR                       = WM_USER + 9; // lParam = bar color

  PBM_SETBKCOLOR                        = CCM_SETBKCOLOR; // lParam = bkColor

  {  ====== HOTKEY CONTROL ========================== }

const
  MAXPROPPAGES                          = 100;

  PSP_DEFAULT                           = $0000;
  PSP_DLGINDIRECT                       = $0001;
  PSP_USEHICON                          = $0002;
  PSP_USEICONID                         = $0004;
  PSP_USETITLE                          = $0008;
  PSP_RTLREADING                        = $0010;
  PSP_HASHELP                           = $0020;
  PSP_USEREFPARENT                      = $0040; {fur Referenzzahlungen...?}
  PSP_USECALLBACK                       = $0080;
  PSP_PREMATURE                         = $0400;
  {----- New flags for wizard97 -----------}
  PSP_HIDEHEADER                        = $0800;
  PSP_USEHEADERTITLE                    = $1000;
  PSP_USEHEADERSUBTITLE                 = $2000;

  PSPCB_RELEASE                         = 1;
  PSPCB_CREATE                          = 2;

  PSH_DEFAULT                           = $0000;
  PSH_PROPTITLE                         = $0001;
  PSH_USEHICON                          = $0002;
  PSH_USEICONID                         = $0004;
  PSH_PROPSHEETPAGE                     = $0008;
  PSH_MULTILINETABS                     = $0010;
  PSH_WIZARD                            = $0020;
  PSH_USEPSTARTPAGE                     = $0040;
  PSH_NOAPPLYNOW                        = $0080;
  PSH_USECALLBACK                       = $0100;
  PSH_HASHELP                           = $0200;
  PSH_MODELESS                          = $0400;
  PSH_RTLREADING                        = $0800;
  PSH_WIZARDCONTEXTHELP                 = $1000;
  {----- New flags for Wizard97 -----------}
  PSH_WATERMARK                         = $00008000;
  PSH_USEHBMWATERMARK                   = $00010000; {User pass in a hbmWaterMark instead of pszbmWaterMark}
  PSH_USEHPLWATERMARK                   = $00020000;
  PSH_STRETCHWATERMARK                  = $00040000; {stretchWaterMark also applies for the Header}
  PSH_HEADER                            = $00080000;
  PSH_USEHBMHEADER                      = $00100000;
  PSH_USEPAGELANG                       = $00200000; {Use frame dialog template matched to page}
  PSH_WIZARDHASFINISH                   = $00000010;

  PSCB_INITIALIZED                      = 1;

  WM_NOTIFY                             = $004E;
  PSN_FIRST                             = -200;
  PSN_LAST                              = -299;

  PSN_SETACTIVE                         = PSN_FIRST - 0;
  PSN_KILLACTIVE                        = PSN_FIRST - 1;
  PSN_APPLY                             = PSN_FIRST - 2;
  PSN_RESET                             = PSN_FIRST - 3;
  PSN_HELP                              = PSN_FIRST - 5;
  PSN_WIZBACK                           = PSN_FIRST - 6;
  PSN_WIZNEXT                           = PSN_FIRST - 7;
  PSN_WIZFINISH                         = PSN_FIRST - 8;
  PSN_QUERYCANCEL                       = PSN_FIRST - 9;
  PSN_GETOBJECT                         = PSN_FIRST - 10; {Wizard97}

  PSNRET_NOERROR                        = 0;
  PSNRET_INVALID                        = 1;
  PSNRET_INVALID_NOCHANGEPAGE           = 2;

  PSM_SETCURSEL                         = WM_USER + 101;
  PSM_REMOVEPAGE                        = WM_USER + 102;
  PSM_ADDPAGE                           = WM_USER + 103;
  PSM_CHANGED                           = WM_USER + 104;
  PSM_RESTARTWINDOWS                    = WM_USER + 105;
  PSM_REBOOTSYSTEM                      = WM_USER + 106;
  PSM_CANCELTOCLOSE                     = WM_USER + 107;
  PSM_QUERYSIBLINGS                     = WM_USER + 108;
  PSM_UNCHANGED                         = WM_USER + 109;
  PSM_APPLY                             = WM_USER + 110;
  PSM_SETTITLE                          = WM_USER + 111;
  PSM_SETTITLEW                         = WM_USER + 120;
  PSM_SETWIZBUTTONS                     = WM_USER + 112;
  PSM_PRESSBUTTON                       = WM_USER + 113;
  PSM_SETCURSELID                       = WM_USER + 114;
  PSM_SETFINISHTEXT                     = WM_USER + 115;
  PSM_SETFINISHTEXTW                    = WM_USER + 121;
  PSM_GETTABCONTROL                     = WM_USER + 116;
  PSM_ISDIALOGMESSAGE                   = WM_USER + 117;

  PSWIZB_BACK                           = $00000001;
  PSWIZB_NEXT                           = $00000002;
  PSWIZB_FINISH                         = $00000004;
  PSWIZB_DISABLEDFINISH                 = $00000008;

  PSBTN_BACK                            = 0;
  PSBTN_NEXT                            = 1;
  PSBTN_FINISH                          = 2;
  PSBTN_OK                              = 3;
  PSBTN_APPLYNOW                        = 4;
  PSBTN_CANCEL                          = 5;
  PSBTN_HELP                            = 6;
  PSBTN_MAX                             = 6;

  ID_PSRESTARTWINDOWS                   = 2;
  ID_PSREBOOTSYSTEM                     = ID_PSRESTARTWINDOWS or 1;

  WIZ_CXDLG                             = 276;
  WIZ_CYDLG                             = 140;

  WIZ_CXBMP                             = 80;

  WIZ_BODYX                             = 92;
  WIZ_BODYCX                            = 184;

  PROP_SM_CXDLG                         = 212;
  PROP_SM_CYDLG                         = 188;

  PROP_MED_CXDLG                        = 227;
  PROP_MED_CYDLG                        = 215;

  PROP_LG_CXDLG                         = 252;
  PROP_LG_CYDLG                         = 218;

type
  HPropSheetPage = Pointer;

  PPropSheetPageA = ^TPropSheetPageA;
  PPropSheetPageW = ^TPropSheetPageW;
  PPropSheetPage = PPropSheetPageA;
  LPFNPSPCALLBACKA = function(wnd: HWND; Msg: integer;
    PPSP: PPropSheetPageA): integer stdcall;
  LPFNPSPCALLBACKW = function(wnd: HWND; Msg: integer;
    PPSP: PPropSheetPageW): integer stdcall;
  LPFNPSPCALLBACK = LPFNPSPCALLBACKA;
  TFNPSPCallbackA = LPFNPSPCALLBACKA;
  TFNPSPCallbackW = LPFNPSPCALLBACKW;
  TFNPSPCallback = TFNPSPCallbackA;
  _PROPSHEETPAGEA = record
    dwSize: LONGINT;
    dwFlags: LONGINT;
    hInstance: THandle;
    case integer of
      0: (
        pszTemplate: PAnsiChar);
      1: (
        pResource: Pointer;
        case integer of
          0: (
            HICON: THandle);
          1: (
            pszIcon: PAnsiChar;
            pszTitle: PAnsiChar;
            pfnDlgProc: Pointer;
            lParam: LONGINT;
            pfnCallback: TFNPSPCallbackA;
            pcRefParent: PInteger;
            pszHeaderTitle: PAnsiChar; // this is displayed in the header
            pszHeaderSubTitle: PAnsiChar)); //
  end;
  _PROPSHEETPAGEW = record
    dwSize: LONGINT;
    dwFlags: LONGINT;
    hInstance: THandle;
    case integer of
      0: (
        pszTemplate: PWideChar);
      1: (
        pResource: Pointer;
        case integer of
          0: (
            HICON: THandle);
          1: (
            pszIcon: PWideChar;
            pszTitle: PWideChar;
            pfnDlgProc: Pointer;
            lParam: LONGINT;
            pfnCallback: TFNPSPCallbackW;
            pcRefParent: PInteger;
            pszHeaderTitle: PWideChar; // this is displayed in the header
            pszHeaderSubTitle: PWideChar)); //
  end;
  _PROPSHEETPAGE = _PROPSHEETPAGEA;
  TPropSheetPageA = _PROPSHEETPAGEA;
  TPropSheetPageW = _PROPSHEETPAGEW;
  TPropSheetPage = TPropSheetPageA;
  PROPSHEETPAGEA = _PROPSHEETPAGEA;
  PROPSHEETPAGEW = _PROPSHEETPAGEW;
  PROPSHEETPAGE = PROPSHEETPAGEA;
  PFNPROPSHEETCALLBACK = function(wnd: HWND; Msg: integer;
    lParam: integer): integer stdcall;
  TFNPropSheetCallback = PFNPROPSHEETCALLBACK;

  PPropSheetHeaderA = ^TPropSheetHeaderA;
  PPropSheetHeaderW = ^TPropSheetHeaderW;
  PPropSheetHeader = PPropSheetHeaderA;
  _PROPSHEETHEADERA = record
    dwSize: LONGINT;
    dwFlags: LONGINT;
    hwndParent: HWND;
    hInstance: THandle;
    case integer of
      0: (
        HICON: THandle);
      1: (
        pszIcon: PAnsiChar;
        pszCaption: PAnsiChar;
        nPages: integer;
        case integer of
          0: (
            nStartPage: integer);
          1: (
            pStartPage: PAnsiChar;
            case integer of
              0: (
                PPSP: PPropSheetPageA);
              1: (
                phpage: Pointer;
                pfnCallback: TFNPropSheetCallback;
                case integer of
                  0: (
                    hbmWatermark: HBITMAP);
                  1: (
                    pszbmWatermark: PAnsiChar;
                    hplWatermark: HPALETTE;
                    // Header bitmap shares the palette with watermark
                    case integer of
                      0: (
                        hbmHeader: HBITMAP);
                      1: (
                        pszbmHeader: PAnsiChar)))));
  end;
  _PROPSHEETHEADERW = record
    dwSize: LONGINT;
    dwFlags: LONGINT;
    hwndParent: HWND;
    hInstance: THandle;
    case integer of
      0: (
        HICON: THandle);
      1: (
        pszIcon: PWideChar;
        pszCaption: PWideChar;
        nPages: integer;
        case integer of
          0: (
            nStartPage: integer);
          1: (
            pStartPage: PWideChar;
            case integer of
              0: (
                PPSP: PPropSheetPageW);
              1: (
                phpage: Pointer;
                pfnCallback: TFNPropSheetCallback;
                case integer of
                  0: (
                    hbmWatermark: HBITMAP);
                  1: (
                    pszbmWatermark: PWideChar;
                    hplWatermark: HPALETTE;
                    // Header bitmap shares the palette with watermark
                    case integer of
                      0: (
                        hbmHeader: HBITMAP);
                      1: (
                        pszbmHeader: PWideChar)))));
  end;
  _PROPSHEETHEADER = _PROPSHEETHEADERA;
  TPropSheetHeaderA = _PROPSHEETHEADERA;
  TPropSheetHeaderW = _PROPSHEETHEADERW;
  TPropSheetHeader = TPropSheetHeaderA;
  LPFNADDPROPSHEETPAGE = function(hPSP: HPropSheetPage;
    lParam: LONGINT): BOOL stdcall;
  TFNAddPropSheetPage = LPFNADDPROPSHEETPAGE;
  LPFNADDPROPSHEETPAGES = function(lpvoid: Pointer; pfn: TFNAddPropSheetPage;
    lParam: LONGINT): BOOL stdcall;
  TFNAddPropSheetPages = LPFNADDPROPSHEETPAGES;
function CreatePropertySheetPageA(var PSP: TPropSheetPageA): HPropSheetPage; stdcall;
function CreatePropertySheetPageW(var PSP: TPropSheetPageW): HPropSheetPage; stdcall;
function CreatePropertySheetPage(var PSP: TPropSheetPage): HPropSheetPage; stdcall;
function DestroyPropertySheetPage(hPSP: HPropSheetPage): BOOL; stdcall;
function PropertySheetA(var PSH: TPropSheetHeaderA): integer; stdcall;
function PropertySheetW(var PSH: TPropSheetHeaderW): integer; stdcall;
function PropertySheet(var PSH: TPropSheetHeader): integer; stdcall;

type
  PInitCommonControlsEx = ^TInitCommonControlsEx;
  TInitCommonControlsEx = packed record
    dwSize: DWORD; // size of this structure
    dwICC: DWORD; // flags indicating which classes to be initialized
  end;

const
  ICC_STANDARD_CLASSES                  = $00004000;
  ICC_LINK_CLASS                        = $00008000;
  ICC_LISTVIEW_CLASSES                  = $00000001; // listview, header
  ICC_TREEVIEW_CLASSES                  = $00000002; // treeview, tooltips
  ICC_BAR_CLASSES                       = $00000004; // toolbar, statusbar, trackbar, tooltips
  ICC_TAB_CLASSES                       = $00000008; // tab, tooltips
  ICC_UPDOWN_CLASS                      = $00000010; // updown
  ICC_PROGRESS_CLASS                    = $00000020; // progress
  ICC_HOTKEY_CLASS                      = $00000040; // hotkey
  ICC_ANIMATE_CLASS                     = $00000080; // animate
  ICC_WIN95_CLASSES                     = $000000FF;
  ICC_DATE_CLASSES                      = $00000100; // month picker, date picker, time picker, updown
  ICC_USEREX_CLASSES                    = $00000200; // comboex
  ICC_COOL_CLASSES                      = $00000400; // rebar (coolbar) control
  ICC_INTERNET_CLASSES                  = $00000800;
  ICC_PAGESCROLLER_CLASS                = $00001000; // page scroller
  ICC_NATIVEFNTCTL_CLASS                = $00002000; // native font control InitCommonControls}

procedure InitCommonControls; stdcall;
function INITCOMMONCONTROLSEX(var ICC: TInitCommonControlsEx): BOOL; { Re-defined below }

const
  IMAGE_BITMAP                          = 0;

const
  ODT_HEADER                            = 100;
  ODT_TAB                               = 101;
  ODT_LISTVIEW                          = 102;

const
  PSP_USEFUSIONCONTEXT                  = $00004000;
  PSPCB_ADDREF                          = $0;
  PSH_WIZARD97_IE4                      = $00002000;
  PSH_WIZARD97                          = $01000000;
  PSH_WIZARD_LITE                       = $00400000;
  PSH_NOCONTEXTHELP                     = $02000000;
  PSCB_BUTTONPRESSED                    = $3;

type
  _PSHNOTIFY = packed record
    hdr: PNMHdr;
    lParam: LONGINT
  end;
  TSHNotify = _PSHNOTIFY;
  PSHNotify = ^TSHNotify;

const
  PSN_TRANSLATEACCELERATOR              = PSN_FIRST - 12;
  PSN_QUERYINITIALFOCUS                 = PSN_FIRST - 13;
  PSNRET_MESSAGEHANDLED                 = 3;

function PropSheet_SetCurSel(hDlg: HWND; hpage: HPropSheetPage; Index: integer): BOOL;
function PropSheet_RemovePage(hDlg: HWND; Index: integer; hpage: HPropSheetPage): BOOL;
function PropSheet_AddPage(hDlg: HWND; hpage: HPropSheetPage): BOOL;
function PropSheet_Changed(hDlg: HWND; hwndPage: HWND): BOOL;
procedure PropSheet_RestartWindows(hDlg: HWND);
procedure PropSheet_RebootSystem(hDlg: HWND);
procedure PropSheet_CancelToClose(hDlg: HWND);
function PropSheet_QuerySiblings(hDlg: HWND; wp: wParam; lp: lParam): integer;
procedure PropSheet_UnChanged(hDlg: HWND; hwndPage: HWND);
function PropSheet_Apply(hDlg: HWND): BOOL;
procedure PropSheet_SetTitle(hPropSheetDlg: HWND; dwStyle: DWORD; lpszText: string);
procedure PropSheet_SetWizButtons(hDlg: HWND; dwFlags: DWORD);
function PropSheet_PressButton(hDlg: HWND; iButton: integer): BOOL;
function PropSheet_SetCurSelByID(hDlg: HWND; ID: integer): BOOL;
procedure PropSheet_SetFinishText(hDlg: HWND; lpszText: string);
function PropSheet_GetTabControl(hDlg: HWND): HWND;
function PropSheet_IsDialogMessage(hDlg: HWND; pMsg: TMsg): BOOL;

const
  PSM_GETCURRENTPAGEHWND                = WM_USER + 118;
  PSM_INSERTPAGE                        = WM_USER + 119;

function PropSheet_GetCurrentPageHwnd(hDlg: HWND): HWND;
function PropSheet_InsertPage(hDlg: HWND; Index: integer; hpage: HPropSheetPage): BOOL;

const
  PSM_SETHEADERTITLE                    = WM_USER + 125;
  PSM_SETHEADERTITLEW                   = WM_USER + 126;
  PSM_SETHEADERSUBTITLE                 = WM_USER + 127;
  PSM_SETHEADERSUBTITLEW                = WM_USER + 128;

function PropSheet_SetHeaderTitle(hDlg: HWND; Index: integer; lpszText: string): integer;
procedure PropSheet_SetHeaderSubTitle(hDlg: HWND; Index: integer; lpszText: LPCSTR);

const
  PSM_HWNDTOINDEX                       = WM_USER + 129;
  PSM_INDEXTOHWND                       = WM_USER + 130;
  PSM_PAGETOINDEX                       = WM_USER + 131;
  PSM_INDEXTOPAGE                       = WM_USER + 132;
  PSM_IDTOINDEX                         = WM_USER + 133;
  PSM_INDEXTOID                         = WM_USER + 134;
  PSM_GETRESULT                         = WM_USER + 135;
  PSM_RECALCPAGESIZES                   = WM_USER + 136;

function PropSheet_HwndToIndex(hDlg, hwndPage: HWND): integer;
function PropSheet_IndexToHwnd(hDlg: HWND; i: integer): HWND;
function PropSheet_PageToIndex(hDlg: HWND; hpage: HPropSheetPage): integer;
function PropSheet_IndexToPage(hDlg: HWND; i: integer): HPropSheetPage;
function PropSheet_IdToIndex(hDlg: HWND; ID: integer): integer;
function PropSheet_IndexToId(hDlg: HWND; i: integer): integer;
function PropSheet_GetResult(hDlg: HWND): integer;
function PropSheet_RecalcPageSizes(hDlg: HWND): BOOL;

{=================================== SysLink ==================================}
const
  INVALID_LINK_INDEX                    = -1;
  MAX_LINKID_TEXT                       = 48;
  L_MAX_URL_LENGTH                      = 2048 + 32 + length('://');

  WC_LINK                               = 'SysLink';

  LWS_TRANSPARENT                       = $0001;
  LWS_IGNORERETURN                      = $0002;

  LIF_ITEMINDEX                         = $00000001;
  LIF_STATE                             = $00000002;
  LIF_ITEMID                            = $00000004;
  LIF_URL                               = $00000008;

  LIS_FOCUSED                           = $00000001;
  LIS_ENABLED                           = $00000002;
  LIS_VISITED                           = $00000004;

type
  tagLITEM = packed record
    Mask: UINT;
    iLink: integer;
    State,
      stateMask: UINT;
    szId: array[0..MAX_LINKID_TEXT] of widechar;
    szUrl: array[0..L_MAX_URL_LENGTH] of widechar;
  end;
  TLItem = tagLITEM;
  PLItem = ^TLItem;

  tagLHITTESTINFO = packed record
    Pt: TPoint;
    Item: TLItem;
  end;
  TLHitTestInfo = tagLHITTESTINFO;
  PLHitTestInfo = ^TLHitTestInfo;

  tagNMLINK = packed record
    hdr: PNMHdr;
    Item: TLItem;
  end;
  TNMLink = tagNMLINK;
  PNMLink = ^TNMLink;

  //  SysLink notifications
  //  NM_CLICK   // wParam: control ID, lParam: PNMLINK, ret: ignored.

  //  LinkWindow messages
const
  LM_HITTEST                            = WM_USER + $300; // wParam: n/a, lparam: PLHITTESTINFO, ret: BOOL
  LM_GETIDEALHEIGHT                     = WM_USER + $301; // wParam: n/a, lparam: n/a, ret: cy
  LM_SETITEM                            = WM_USER + $302; // wParam: n/a, lparam: LITEM*, ret: BOOL
  LM_GETITEM                            = WM_USER + $303; // wParam: n/a, lparam: LITEM*, ret: BOOL

  { ====== Ranges for control message IDs ======================= }

type
  tagCOLORSCHEME = packed record
    dwSize: DWORD;
    clrBtnHighlight: COLORREF; // highlight color
    clrBtnShadow: COLORREF; // shadow color
  end;
  PColorScheme = ^TColorScheme;
  TColorScheme = tagCOLORSCHEME;

const
  CCM_SETCOLORSCHEME                    = CCM_FIRST + 2; // lParam is color scheme
  CCM_GETCOLORSCHEME                    = CCM_FIRST + 3; // fills in COLORSCHEME pointed to by lParam
  CCM_GETDROPTARGET                     = CCM_FIRST + 4;
  CCM_SETUNICODEFORMAT                  = CCM_FIRST + 5;
  CCM_GETUNICODEFORMAT                  = CCM_FIRST + 6;

  INFOTIPSIZE                           = 1024; // for tooltips

  { ====== WM_NOTIFY codes (NMHDR.code values) ================== }

const
  NM_FIRST                              = 0 - 0; { generic to all controls }
  NM_LAST                               = 0 - 99;

  LVN_FIRST                             = 0 - 100; { listview }
  LVN_LAST                              = 0 - 199;

  HDN_FIRST                             = 0 - 300; { header }
  HDN_LAST                              = 0 - 399;

  TVN_FIRST                             = 0 - 400; { treeview }
  TVN_LAST                              = 0 - 499;

  TTN_FIRST                             = 0 - 520; { tooltips }
  TTN_LAST                              = 0 - 549;

  TCN_FIRST                             = 0 - 550; { tab control }
  TCN_LAST                              = 0 - 580;

  { Shell reserved           (0-580) -  (0-589) }

  CDN_FIRST                             = 0 - 601; { common dialog (new) }
  CDN_LAST                              = 0 - 699;

  TBN_FIRST                             = 0 - 700; { toolbar }
  TBN_LAST                              = 0 - 720;

  UDN_FIRST                             = 0 - 721; { updown }
  UDN_LAST                              = 0 - 740;

  MCN_FIRST                             = 0 - 750; { monthcal }
  MCN_LAST                              = 0 - 759;

  DTN_FIRST                             = 0 - 760; { datetimepick }
  DTN_LAST                              = 0 - 799;

  CBEN_FIRST                            = 0 - 800; { combo box ex }
  CBEN_LAST                             = 0 - 830;

  RBN_FIRST                             = 0 - 831; { coolbar }
  RBN_LAST                              = 0 - 859;

  IPN_FIRST                             = 0 - 860; { internet address }
  IPN_LAST                              = 0 - 879; { internet address }

  SBN_FIRST                             = 0 - 880; { status bar }
  SBN_LAST                              = 0 - 899;

  PGN_FIRST                             = 0 - 900; { Pager Control }
  PGN_LAST                              = 0 - 950;

  MSGF_COMMCTRL_BEGINDRAG               = $4200;
  MSGF_COMMCTRL_SIZEHEADER              = $4201;
  MSGF_COMMCTRL_DRAGSELECT              = $4202;
  MSGF_COMMCTRL_TOOLBARCUST             = $4203;

  { ====== Generic WM_NOTIFY notification codes ================= }

const
{$EXTERNALSYM NM_OUTOFMEMORY}
  NM_OUTOFMEMORY                        = NM_FIRST - 1;
{$EXTERNALSYM NM_CLICK}
  NM_CLICK                              = NM_FIRST - 2;
{$EXTERNALSYM NM_DBLCLK}
  NM_DBLCLK                             = NM_FIRST - 3;
{$EXTERNALSYM NM_RETURN}
  NM_RETURN                             = NM_FIRST - 4;
{$EXTERNALSYM NM_RCLICK}
  NM_RCLICK                             = NM_FIRST - 5;
{$EXTERNALSYM NM_RDBLCLK}
  NM_RDBLCLK                            = NM_FIRST - 6;
{$EXTERNALSYM NM_SETFOCUS}
  NM_SETFOCUS                           = NM_FIRST - 7;
{$EXTERNALSYM NM_KILLFOCUS}
  NM_KILLFOCUS                          = NM_FIRST - 8;
{$EXTERNALSYM NM_CUSTOMDRAW}
  NM_CUSTOMDRAW                         = NM_FIRST - 12;
{$EXTERNALSYM NM_HOVER}
  NM_HOVER                              = NM_FIRST - 13;
{$EXTERNALSYM NM_NCHITTEST}
  NM_NCHITTEST                          = NM_FIRST - 14; // uses NMMOUSE struct
{$EXTERNALSYM NM_KEYDOWN}
  NM_KEYDOWN                            = NM_FIRST - 15; // uses NMKEY struct
{$EXTERNALSYM NM_RELEASEDCAPTURE}
  NM_RELEASEDCAPTURE                    = NM_FIRST - 16;
{$EXTERNALSYM NM_SETCURSOR}
  NM_SETCURSOR                          = NM_FIRST - 17; // uses NMMOUSE struct
{$EXTERNALSYM NM_CHAR}
  NM_CHAR                               = NM_FIRST - 18; // uses NMCHAR struct

  { ====== IMAGE LIST =========================================== }

const
  CLR_NONE                              = $FFFFFFFF;
  CLR_DEFAULT                           = $FF000000;

type
  HImageList = THandle;

const
  ILC_MASK                              = $0001;
  ILC_COLOR                             = $00FE;
  ILC_COLORDDB                          = $00FE;
  ILC_COLOR4                            = $0004;
  ILC_COLOR8                            = $0008;
  ILC_COLOR16                           = $0010;
  ILC_COLOR24                           = $0018;
  ILC_COLOR32                           = $0020;
  ILC_PALETTE                           = $0800;

function ImageList_Create(cx, cy: integer; Flags: UINT;
  Initial, Grow: integer): HImageList; stdcall;
function ImageList_Destroy(ImageList: HImageList): BOOL; stdcall;
function ImageList_GetImageCount(ImageList: HImageList): integer; stdcall;
function ImageList_Add(ImageList: HImageList; Image, Mask: HBITMAP): integer; stdcall;
function ImageList_ReplaceIcon(ImageList: HImageList; Index: integer; Icon: HICON): integer; stdcall;
function ImageList_SetBkColor(ImageList: HImageList; ClrBk: TColorRef): TColorRef; stdcall;
function ImageList_GetBkColor(ImageList: HImageList): TColorRef; stdcall;
function ImageList_SetOverlayImage(ImageList: HImageList; Image: integer;
  Overlay: integer): BOOL; stdcall;

function ImageList_AddIcon(ImageList: HImageList; Icon: HICON): integer;

const
  ILD_NORMAL                            = $0000;
  ILD_TRANSPARENT                       = $0001;
  ILD_MASK                              = $0010;
  ILD_IMAGE                             = $0020;
  ILD_BLEND25                           = $0002;
  ILD_BLEND50                           = $0004;
  ILD_OVERLAYMASK                       = $0F00;

function IndexToOverlayMask(Index: integer): integer;

const
  ILD_SELECTED                          = ILD_BLEND50;
  ILD_FOCUS                             = ILD_BLEND25;
  ILD_BLEND                             = ILD_BLEND50;
  CLR_HILIGHT                           = CLR_DEFAULT;

function ImageList_Draw(ImageList: HImageList; Index: integer;
  Dest: HDC; X, Y: integer; Style: UINT): BOOL; stdcall;

function ImageList_Replace(ImageList: HImageList; Index: integer;
  Image, Mask: HBITMAP): BOOL; stdcall;
function ImageList_AddMasked(ImageList: HImageList; Image: HBITMAP;
  Mask: TColorRef): integer; stdcall;
function ImageList_DrawEx(ImageList: HImageList; Index: integer;
  Dest: HDC; X, Y, DX, DY: integer; Bk, Fg: TColorRef; Style: Cardinal): BOOL; stdcall;
function ImageList_Remove(ImageList: HImageList; Index: integer): BOOL; stdcall;
function ImageList_GetIcon(ImageList: HImageList; Index: integer;
  Flags: Cardinal): HICON; stdcall;
function ImageList_LoadImageA(Instance: THandle; BMP: PAnsiChar; cx, Grow: integer;
  Mask: TColorRef; pType, Flags: Cardinal): HImageList; stdcall;
function ImageList_LoadImageW(Instance: THandle; BMP: PWideChar; cx, Grow: integer;
  Mask: TColorRef; pType, Flags: Cardinal): HImageList; stdcall;
function ImageList_LoadImage(Instance: THandle; BMP: PChar; cx, Grow: integer;
  Mask: TColorRef; pType, Flags: Cardinal): HImageList; stdcall;
function ImageList_BeginDrag(ImageList: HImageList; Track: integer;
  XHotSpot, YHotSpot: integer): BOOL; stdcall;
function ImageList_EndDrag: BOOL; stdcall;
function ImageList_DragEnter(LockWnd: HWND; X, Y: integer): BOOL; stdcall;
function ImageList_DragLeave(LockWnd: HWND): BOOL; stdcall;
function ImageList_DragMove(X, Y: integer): BOOL; stdcall;
function ImageList_SetDragCursorImage(ImageList: HImageList; Drag: integer;
  XHotSpot, YHotSpot: integer): BOOL; stdcall;
function ImageList_DragShowNoLock(show: BOOL): BOOL; stdcall;
function ImageList_GetDragImage(Point, HotSpot: PPoint): HImageList; stdcall;

{ macros }
procedure ImageList_RemoveAll(ImageList: HImageList);
function ImageList_ExtractIcon(Instance: THandle; ImageList: HImageList;
  Image: integer): HICON;
function ImageList_LoadBitmap(Instance: THandle; BMP: PChar;
  cx, Grow: integer; Mask: TColorRef): HImageList;

//function ImageList_Read(Stream: IStream): HImageList; stdcall;
//function ImageList_Write(ImageList: HImageList; Stream: IStream): BOOL; stdcall;

type
  PImageInfo = ^TImageInfo;
  TImageInfo = packed record
    hbmImage: HBITMAP;
    hbmMask: HBITMAP;
    Unused1: integer;
    Unused2: integer;
    rcImage: TRect;
  end;

function ImageList_GetIconSize(ImageList: HImageList; var cx, cy: integer): BOOL; stdcall;
function ImageList_SetIconSize(ImageList: HImageList; cx, cy: integer): BOOL; stdcall;
function ImageList_GetImageInfo(ImageList: HImageList; Index: integer;
  var ImageInfo: TImageInfo): BOOL; stdcall;
function ImageList_Merge(ImageList1: HImageList; Index1: integer;
  ImageList2: HImageList; Index2: integer; DX, DY: integer): BOOL; stdcall;

{ ====== HEADER CONTROL ========================== }

const
  WC_HEADER                             = 'SysHeader32';

  HDS_HORZ                              = $00000000;
  HDS_BUTTONS                           = $00000002;
  HDS_HOTTRACK                          = $00000004;
  HDS_HIDDEN                            = $00000008;
  HDS_DRAGDROP                          = $00000040;
  HDS_FULLDRAG                          = $00000080;

type
  PHDItemA = ^THDItemA;
  PHDItemW = ^THDItemW;
  PHDItem = PHDItemA;
  THDItemA = packed record
    Mask: Cardinal;
    cxy: integer;
    pszText: PAnsiChar;
    hbm: HBITMAP;
    cchTextMax: integer;
    fmt: integer;
    lParam: lParam;
  end;
  THDItemW = packed record
    Mask: Cardinal;
    cxy: integer;
    pszText: PWideChar;
    hbm: HBITMAP;
    cchTextMax: integer;
    fmt: integer;
    lParam: lParam;
  end;
  THDItem = THDItemA;

const
  HDI_WIDTH                             = $0001;
  HDI_HEIGHT                            = HDI_WIDTH;
  HDI_TEXT                              = $0002;
  HDI_FORMAT                            = $0004;
  HDI_LPARAM                            = $0008;
  HDI_BITMAP                            = $0010;

  HDF_LEFT                              = 0;
  HDF_RIGHT                             = 1;
  HDF_CENTER                            = 2;
  HDF_JUSTIFYMASK                       = $0003;
  HDF_RTLREADING                        = 4;

  HDF_OWNERDRAW                         = $8000;
  HDF_STRING                            = $4000;
  HDF_BITMAP                            = $2000;

  HDM_GETITEMCOUNT                      = HDM_FIRST + 0;

function Header_GetItemCount(Header: HWND): integer;

const
  HDM_INSERTITEMW                       = HDM_FIRST + 10;
  HDM_INSERTITEMA                       = HDM_FIRST + 1;
  HDM_INSERTITEM                        = HDM_INSERTITEMA;

function Header_InsertItem(Header: HWND; Index: integer;
  const Item: THDItem): integer;

const
  HDM_DELETEITEM                        = HDM_FIRST + 2;

function Header_DeleteItem(Header: HWND; Index: integer): BOOL;

const
  HDM_GETITEMW                          = HDM_FIRST + 11;
  HDM_GETITEMA                          = HDM_FIRST + 3;
  HDM_GETITEM                           = HDM_GETITEMA;

function Header_GetItem(Header: HWND; Index: integer;
  var Item: THDItem): BOOL;

const
  HDM_SETITEMA                          = HDM_FIRST + 4;
  HDM_SETITEMW                          = HDM_FIRST + 12;
  HDM_SETITEM                           = HDM_SETITEMA;

function Header_SetItem(Header: HWND; Index: integer; const Item: THDItem): BOOL;

type
  PHDLayout = ^THDLayout;
  THDLayout = packed record
    rect: ^TRect;
    WindowPos: PWindowPos;
  end;

const
  HDM_LAYOUT                            = HDM_FIRST + 5;

function Header_Layout(Header: HWND; Layout: PHDLayout): BOOL;

const
  HHT_NOWHERE                           = $0001;
  HHT_ONHEADER                          = $0002;
  HHT_ONDIVIDER                         = $0004;
  HHT_ONDIVOPEN                         = $0008;
  HHT_ABOVE                             = $0100;
  HHT_BELOW                             = $0200;
  HHT_TORIGHT                           = $0400;
  HHT_TOLEFT                            = $0800;

type
  PHDHitTestInfo = ^THDHitTestInfo;
  THDHitTestInfo = packed record
    Point: TPoint;
    Flags: Cardinal;
    Item: integer;
  end;

const
  HDM_HITTEST                           = HDM_FIRST + 6;

const
  HDN_ITEMCHANGINGA                     = HDN_FIRST - 0;
  HDN_ITEMCHANGEDA                      = HDN_FIRST - 1;
  HDN_ITEMCLICKA                        = HDN_FIRST - 2;
  HDN_ITEMDBLCLICKA                     = HDN_FIRST - 3;
  HDN_DIVIDERDBLCLICKA                  = HDN_FIRST - 5;
  HDN_BEGINTRACKA                       = HDN_FIRST - 6;
  HDN_ENDTRACKA                         = HDN_FIRST - 7;
  HDN_TRACKA                            = HDN_FIRST - 8;

  HDN_ITEMCHANGINGW                     = HDN_FIRST - 20;
  HDN_ITEMCHANGEDW                      = HDN_FIRST - 21;
  HDN_ITEMCLICKW                        = HDN_FIRST - 22;
  HDN_ITEMDBLCLICKW                     = HDN_FIRST - 23;
  HDN_DIVIDERDBLCLICKW                  = HDN_FIRST - 25;
  HDN_BEGINTRACKW                       = HDN_FIRST - 26;
  HDN_ENDTRACKW                         = HDN_FIRST - 27;
  HDN_TRACKW                            = HDN_FIRST - 28;

  HDN_ITEMCHANGING                      = HDN_ITEMCHANGINGA;
  HDN_ITEMCHANGED                       = HDN_ITEMCHANGEDA;
  HDN_ITEMCLICK                         = HDN_ITEMCLICKA;
  HDN_ITEMDBLCLICK                      = HDN_ITEMDBLCLICKA;
  HDN_DIVIDERDBLCLICK                   = HDN_DIVIDERDBLCLICKA;
  HDN_BEGINTRACK                        = HDN_BEGINTRACKA;
  HDN_ENDTRACK                          = HDN_ENDTRACKA;
  HDN_TRACK                             = HDN_TRACKA;

type
  PHDNotifyA = ^THDNotifyA;
  PHDNotifyW = ^THDNotifyW;
  PHDNotify = PHDNotifyA;
  THDNotifyA = packed record
    hdr: TNMHDR;
    Item: integer;
    Button: integer;
    pItem: PHDItemA;
  end;
  THDNotifyW = packed record
    hdr: TNMHDR;
    Item: integer;
    Button: integer;
    pItem: PHDItemW;
  end;
  THDNotify = THDNotifyA;

  { ====== TOOLBAR CONTROL =================== }

const
  TOOLBARCLASSNAME                      = 'ToolbarWindow32';

type
  PTBButton = ^TTBButton;
  TTBButton = packed record
    iBitmap: integer;
    idCommand: integer;
    fsState: Byte;
    fsStyle: Byte;
    bReserved: array[1..2] of Byte;
    dwData: LONGINT;
    iString: integer;
  end;

  PColorMap = ^TColorMap;
  TColorMap = packed record
    cFrom: TColorRef;
    cTo: TColorRef;
  end;

function CreateToolBarEx(wnd: HWND; ws: LONGINT; ID: UINT;
  Bitmaps: integer; BMInst: THandle; BMID: Cardinal; Buttons: PTBButton;
  NumButtons: integer; dxButton, dyButton: integer;
  dxBitmap, dyBitmap: integer; StructSize: UINT): HWND; stdcall;

function CreateMappedBitmap(Instance: THandle; Bitmap: integer;
  Flags: UINT; ColorMap: PColorMap; NumMaps: integer): HBITMAP; stdcall;

const
  CMB_MASKED                            = $02;
  TBSTATE_CHECKED                       = $01;
  TBSTATE_PRESSED                       = $02;
  TBSTATE_ENABLED                       = $04;
  TBSTATE_HIDDEN                        = $08;
  TBSTATE_INDETERMINATE                 = $10;
  TBSTATE_WRAP                          = $20;
  TBSTATE_ELLIPSES                      = $40;
  TBSTATE_MARKED                        = $80;
  TBSTYLE_BUTTON                        = $00;
  TBSTYLE_SEP                           = $01;
  TBSTYLE_CHECK                         = $02;
  TBSTYLE_GROUP                         = $04;
  TBSTYLE_CHECKGROUP                    = TBSTYLE_GROUP or TBSTYLE_CHECK;
  TBSTYLE_DROPDOWN                      = $08;
  TBSTYLE_AUTOSIZE                      = $0010; // automatically calculate the cx of the button
  TBSTYLE_NOPREFIX                      = $0020; // if this button should not have accel prefix
  TBSTYLE_TOOLTIPS                      = $0100;
  TBSTYLE_WRAPABLE                      = $0200;
  TBSTYLE_ALTDRAG                       = $0400;
  TBSTYLE_FLAT                          = $0800;
  TBSTYLE_LIST                          = $1000;
  TBSTYLE_CUSTOMERASE                   = $2000;
  TBSTYLE_REGISTERDROP                  = $4000;
  TBSTYLE_TRANSPARENT                   = $8000;
  TBSTYLE_EX_DRAWDDARROWS               = $00000001;

const
  TB_SETEXTENDEDSTYLE                   = WM_USER + 84; // For TBSTYLE_EX_* TB_GETEXTENDEDSTYLE}
  TB_GETEXTENDEDSTYLE                   = WM_USER + 85; // For TBSTYLE_EX_* TB_GETPADDING}

  BTNS_BUTTON                           = TBSTYLE_BUTTON; // 0x0000
  BTNS_SEP                              = TBSTYLE_SEP; // 0x0001
  BTNS_CHECK                            = TBSTYLE_CHECK; // 0x0002
  BTNS_GROUP                            = TBSTYLE_GROUP; // 0x0004
  BTNS_CHECKGROUP                       = TBSTYLE_CHECKGROUP; // (TBSTYLE_GROUP | TBSTYLE_CHECK)
  BTNS_DROPDOWN                         = TBSTYLE_DROPDOWN; // 0x0008
  BTNS_AUTOSIZE                         = TBSTYLE_AUTOSIZE; // 0x0010; automatically calculate the cx of the button
  BTNS_NOPREFIX                         = TBSTYLE_NOPREFIX; // 0x0020; this button should not have accel prefix
  BTNS_SHOWTEXT                         = $0040; // ignored unless TBSTYLE_EX_MIXEDBUTTONS is set
  BTNS_WHOLEDROPDOWN                    = $0080; // draw drop-down arrow, but without split arrow section
  TBSTYLE_EX_MIXEDBUTTONS               = $00000008;
  TBSTYLE_EX_HIDECLIPPEDBUTTONS         = $00000010; // don't show partially obscured buttons
  TBSTYLE_EX_DOUBLEBUFFER               = $00000080; // Double Buffer the toolbar

  TBN_RESTORE                           = TBN_FIRST - 21;
  TBN_SAVE                              = TBN_FIRST - 22;
  TBN_INITCUSTOMIZE                     = TBN_FIRST - 23;
  TBNRF_HIDEHELP                        = $00000001;
  TBNRF_ENDCUSTOMIZE                    = $00000002;

  TBIF_BYINDEX                          = $80000000;

const
  TB_ENABLEBUTTON                       = WM_USER + 1;
  TB_CHECKBUTTON                        = WM_USER + 2;
  TB_PRESSBUTTON                        = WM_USER + 3;
  TB_HIDEBUTTON                         = WM_USER + 4;
  TB_INDETERMINATE                      = WM_USER + 5;
  TB_ISBUTTONENABLED                    = WM_USER + 9;
  TB_ISBUTTONCHECKED                    = WM_USER + 10;
  TB_ISBUTTONPRESSED                    = WM_USER + 11;
  TB_ISBUTTONHIDDEN                     = WM_USER + 12;
  TB_ISBUTTONINDETERMINATE              = WM_USER + 13;
  TB_SETSTATE                           = WM_USER + 17;
  TB_GETSTATE                           = WM_USER + 18;
  TB_ADDBITMAP                          = WM_USER + 19;

type
  PTBAddBitmap = ^TTBADDBITMAP;
  TTBADDBITMAP = packed record
    hInst: THandle;
    nID: UINT;
  end;

const
  HINST_COMMCTRL                        = THandle(-1);

  IDB_STD_SMALL_COLOR                   = 0;
  IDB_STD_LARGE_COLOR                   = 1;
  IDB_VIEW_SMALL_COLOR                  = 4;
  IDB_VIEW_LARGE_COLOR                  = 5;
  IDB_HIST_SMALL_COLOR                  = 8;
  IDB_HIST_LARGE_COLOR                  = 9;

  { icon indexes for standard bitmap }
  STD_CUT                               = 0;
  STD_COPY                              = 1;
  STD_PASTE                             = 2;
  STD_UNDO                              = 3;
  STD_REDOW                             = 4;
  STD_DELETE                            = 5;
  STD_FILENEW                           = 6;
  STD_FILEOPEN                          = 7;
  STD_FILESAVE                          = 8;
  STD_PRINTPRE                          = 9;
  STD_PROPERTIES                        = 10;
  STD_HELP                              = 11;
  STD_FIND                              = 12;
  STD_REPLACE                           = 13;
  STD_PRINT                             = 14;

  { icon indexes for standard view bitmap }

  VIEW_LARGEICONS                       = 0;
  VIEW_SMALLICONS                       = 1;
  VIEW_LIST                             = 2;
  VIEW_DETAILS                          = 3;
  VIEW_SORTNAME                         = 4;
  VIEW_SORTSIZE                         = 5;
  VIEW_SORTDATE                         = 6;
  VIEW_SORTTYPE                         = 7;
  VIEW_PARENTFOLDER                     = 8;
  VIEW_NETCONNECT                       = 9;
  VIEW_NETDISCONNECT                    = 10;
  VIEW_NEWFOLDER                        = 11;

  { icon indexes for history bitmap }

  HIST_BACK                             = 0;
  HIST_FORWARD                          = 1;
  HIST_FAVORITES                        = 2;
  HIST_ADDTOFAVORITES                   = 3;
  HIST_VIEWTREE                         = 4;

  tb_addbuttons                         = WM_USER + 20;
  TB_INSERTBUTTON                       = WM_USER + 21;
  TB_DELETEBUTTON                       = WM_USER + 22;
  TB_GETBUTTON                          = WM_USER + 23;
  TB_BUTTONCOUNT                        = WM_USER + 24;
  TB_COMMANDTOINDEX                     = WM_USER + 25;

type
  PTBSaveParamsA = ^TTBSaveParamsA;
  PTBSaveParamsW = ^TTBSaveParamsW;
  PTBSaveParams = PTBSaveParamsA;
  TTBSaveParamsA = packed record
    hkr: THandle;
    pszSubKey: PAnsiChar;
    pszValueName: PAnsiChar;
  end;
  TTBSaveParamsW = packed record
    hkr: THandle;
    pszSubKey: PWideChar;
    pszValueName: PWideChar;
  end;
  TTBSaveParams = TTBSaveParamsA;

const
  TB_SAVERESTOREA                       = WM_USER + 26;
  TB_ADDSTRINGA                         = WM_USER + 28;
  TB_GETBUTTONTEXTA                     = WM_USER + 45;
  TBN_GETBUTTONINFOA                    = TBN_FIRST - 0;

  TB_SAVERESTOREW                       = WM_USER + 76;
  TB_ADDSTRINGW                         = WM_USER + 77;
  TB_GETBUTTONTEXTW                     = WM_USER + 75;
  TBN_GETBUTTONINFOW                    = TBN_FIRST - 20;

  TB_SAVERESTORE                        = TB_SAVERESTOREA;
  TB_ADDSTRING                          = TB_ADDSTRINGA;
  TB_GETBUTTONTEXT                      = TB_GETBUTTONTEXTA;
  TBN_GETBUTTONINFO                     = TBN_GETBUTTONINFOA;

  TB_CUSTOMIZE                          = WM_USER + 27;
  TB_GETITEMRECT                        = WM_USER + 29;
  TB_BUTTONSTRUCTSIZE                   = WM_USER + 30;
  TB_SETBUTTONSIZE                      = WM_USER + 31;
  TB_SETBITMAPSIZE                      = WM_USER + 32;
  TB_AUTOSIZE                           = WM_USER + 33;
  TB_GETTOOLTIPS                        = WM_USER + 35;
  TB_SETTOOLTIPS                        = WM_USER + 36;
  TB_SETPARENT                          = WM_USER + 37;
  TB_SETROWS                            = WM_USER + 39;
  TB_GETROWS                            = WM_USER + 40;
  TB_SETCMDID                           = WM_USER + 42;
  TB_CHANGEBITMAP                       = WM_USER + 43;
  TB_GETBITMAP                          = WM_USER + 44;
  TB_REPLACEBITMAP                      = WM_USER + 46;
  TB_SETINDENT                          = WM_USER + 47;
  TB_SETIMAGELIST                       = WM_USER + 48;
  TB_GETIMAGELIST                       = WM_USER + 49;
  TB_LOADIMAGES                         = WM_USER + 50;
  TB_GETRECT                            = WM_USER + 51; { wParam is the Cmd instead of index }
  TB_SETHOTIMAGELIST                    = WM_USER + 52;
  TB_GETHOTIMAGELIST                    = WM_USER + 53;
  TB_SETDISABLEDIMAGELIST               = WM_USER + 54;
  TB_GETDISABLEDIMAGELIST               = WM_USER + 55;
  TB_SETSTYLE                           = WM_USER + 56;
  TB_GETSTYLE                           = WM_USER + 57;
  TB_GETBUTTONSIZE                      = WM_USER + 58;
  TB_SETBUTTONWIDTH                     = WM_USER + 59;
  TB_SETMAXTEXTROWS                     = WM_USER + 60;
  TB_GETTEXTROWS                        = WM_USER + 61;

type
  PTBReplaceBitmap = ^TTBReplaceBitmap;
  TTBReplaceBitmap = packed record
    hInstOld: THandle;
    nIDOld: Cardinal;
    hInstNew: THandle;
    nIDNew: Cardinal;
    nButtons: integer;
  end;

const
  TBBF_LARGE                            = $0001;

  TB_GETBITMAPFLAGS                     = WM_USER + 41;

  TBN_BEGINDRAG                         = TBN_FIRST - 1;
  TBN_ENDDRAG                           = TBN_FIRST - 2;
  TBN_BEGINADJUST                       = TBN_FIRST - 3;
  TBN_ENDADJUST                         = TBN_FIRST - 4;
  TBN_RESET                             = TBN_FIRST - 5;
  TBN_QUERYINSERT                       = TBN_FIRST - 6;
  TBN_QUERYDELETE                       = TBN_FIRST - 7;
  TBN_TOOLBARCHANGE                     = TBN_FIRST - 8;
  TBN_CUSTHELP                          = TBN_FIRST - 9;
  TBN_DROPDOWN                          = TBN_FIRST - 10;
  TBN_CLOSEUP                           = TBN_FIRST - 11;

type
  PNMToolBarA = ^TNMToolBarA;
  PNMToolBarW = ^TNMToolBarW;
  PNMToolBar = PNMToolBarA;
  TNMToolBarA = packed record
    hdr: TNMHDR;
    iItem: integer;
    TBButton: TTBButton;
    cchText: integer;
    pszText: PAnsiChar;
  end;
  TNMToolBarW = packed record
    hdr: TNMHDR;
    iItem: integer;
    TBButton: TTBButton;
    cchText: integer;
    pszText: PWideChar;
  end;
  TNMToolBar = TNMToolBarA;

  { ====== REBAR CONTROL =================== }

const
  REBARCLASSNAME                        = 'ReBarWindow32';

type
  PReBarInfo = ^TReBarInfo;
  TReBarInfo = packed record
    cbSize: UINT;
    fMask: UINT;
    himl: HImageList;
  end;

const
  RBS_DBLCLKTOGGLE                      = $00008000;
  RBBS_GRIPPERALWAYS                    = $00000080; // always show the gripper
  RBBIM_IDEALSIZE                       = $00000200;
  RBBS_USECHEVRON                       = $00000200;

  RBIM_IMAGELIST                        = $00000001;

  RBS_TOOLTIPS                          = $00000100;
  RBS_VARHEIGHT                         = $00000200;
  RBS_BANDBORDERS                       = $00000400;
  RBS_FIXEDORDER                        = $00000800;

  RBBS_BREAK                            = $00000001; // break to new line
  RBBS_FIXEDSIZE                        = $00000002; // band can't be sized
  RBBS_CHILDEDGE                        = $00000004; // edge around top and bottom of child window
  RBBS_HIDDEN                           = $00000008; // don't show
  RBBS_NOVERT                           = $00000010; // don't show when vertical
  RBBS_FIXEDBMP                         = $00000020; // bitmap doesn't move during band resize

  RBBIM_STYLE                           = $00000001;
  RBBIM_COLORS                          = $00000002;
  RBBIM_TEXT                            = $00000004;
  RBBIM_IMAGE                           = $00000008;
  RBBIM_CHILD                           = $00000010;
  RBBIM_CHILDSIZE                       = $00000020;
  RBBIM_SIZE                            = $00000040;
  RBBIM_BACKGROUND                      = $00000080;
  RBBIM_ID                              = $00000100;

  RB_GETRECT                            = WM_USER + 9;
  RB_IDTOINDEX                          = WM_USER + 16; // wParam == id
  RB_MINIMIZEBAND                       = WM_USER + 30;
  RB_MAXIMIZEBAND                       = WM_USER + 31;
  RB_GETBANDBORDERS                     = WM_USER + 34; // returns in lparam = lprc the amount of edges added to band wparam

type
  tagREBARBANDINFOA = packed record
    cbSize: UINT;
    fMask: UINT;
    fStyle: UINT;
    clrFore: TColorRef;
    clrBack: TColorRef;
    lpText: PAnsiChar;
    cch: UINT;
    iImage: integer;
    hwndChild: HWND;
    cxMinChild: UINT;
    cyMinChild: UINT;
    cx: UINT;
    hbmBack: HBITMAP;
    wID: UINT;
    cyChild: UINT;
    cyMaxChild: UINT;
    cyIntegral: UINT;
    cxIdeal: UINT;
    lParam: lParam;
    cxHeader: UINT;
  end;
  tagREBARBANDINFOW = packed record
    cbSize: UINT;
    fMask: UINT;
    fStyle: UINT;
    clrFore: TColorRef;
    clrBack: TColorRef;
    lpText: PWideChar;
    cch: UINT;
    iImage: integer;
    hwndChild: HWND;
    cxMinChild: UINT;
    cyMinChild: UINT;
    cx: UINT;
    hbmBack: HBITMAP;
    wID: UINT;
    cyChild: UINT;
    cyMaxChild: UINT;
    cyIntegral: UINT;
    cxIdeal: UINT;
    lParam: lParam;
    cxHeader: UINT;
  end;
  tagREBARBANDINFO = tagREBARBANDINFOA;
  PReBarBandInfoA = ^TReBarBandInfoA;
  PReBarBandInfoW = ^TReBarBandInfoW;
  PReBarBandInfo = PReBarBandInfoA;
  TReBarBandInfoA = tagREBARBANDINFOA;
  TReBarBandInfoW = tagREBARBANDINFOW;
  TReBarBandInfo = TReBarBandInfoA;

const
  RB_INSERTBANDA                        = (WM_USER + 1);
  RB_DELETEBAND                         = (WM_USER + 2);
  RB_GETBARINFO                         = (WM_USER + 3);
  RB_SETBARINFO                         = (WM_USER + 4);
  RB_GETBANDINFO                        = (WM_USER + 5);
  RB_SETBANDINFOA                       = (WM_USER + 6);
  RB_SETPARENT                          = (WM_USER + 7);
  RB_INSERTBANDW                        = (WM_USER + 10);
  RB_SETBANDINFOW                       = (WM_USER + 11);
  RB_GETBANDCOUNT                       = (WM_USER + 12);
  RB_GETROWCOUNT                        = (WM_USER + 13);
  RB_GETROWHEIGHT                       = (WM_USER + 14);

  RB_INSERTBAND                         = RB_INSERTBANDA;
  RB_SETBANDINFO                        = RB_SETBANDINFOA;

  RBN_HEIGHTCHANGE                      = (RBN_FIRST - 0);

  { ====== TOOLTIPS CONTROL ========================== }

//const   TOOTIPS_CLASS                   = 'tooltips_class32';

type
  TOOLINFO = packed record
    cbSize: integer;
    uFlags: integer;
    HWND: THandle;
    uId: integer;
    rect: TRect;
    hInst: THandle;
    lpszText: PChar; //PWideChar;
//    lParam: Integer;
  end;
  PTRTOOLINFO = ^TOOLINFO;

type
  PToolInfoA = ^TToolInfoA;
  PToolInfoW = ^TToolInfoW;
  PToolInfo = PToolInfoA;
  TToolInfoA = packed record
    cbSize: UINT;
    uFlags: UINT;
    HWND: HWND;
    uId: UINT;
    rect: TRect;
    hInst: THandle;
    lpszText: PAnsiChar;
  end;
  TToolInfoW = packed record
    cbSize: UINT;
    uFlags: UINT;
    HWND: HWND;
    uId: UINT;
    rect: TRect;
    hInst: THandle;
    lpszText: PWideChar;
  end;
  TToolInfo = TToolInfoA;

const
  TTS_ALWAYSTIP                         = $01;
  TTS_NOPREFIX                          = $02;
  TTS_NOANIMATE                         = $10;
  TTS_NOFADE                            = $20;
  TTS_BALLOON                           = $40;
  TTS_CLOSE                             = $80;

  TTM_SETTITLE                          = (WM_USER + 32);
  TTM_SETMAXTIPWIDTH                    = (WM_USER + 24);
  TTM_SETTIPBKCOLOR                     = (WM_USER + 19);
  TTM_SETTIPTEXTCOLOR                   = (WM_USER + 20);

  TTI_NONE                              = 0;
  TTI_INFO                              = 1;
  TTI_WARNING                           = 2;
  TTI_ERROR                             = 3;

  TTF_PARSELINKS                        = $1000;

  TTM_GETBUBBLESIZE                     = WM_USER + 30;
  TTM_ADJUSTRECT                        = WM_USER + 31;
  TTM_SETTITLEA                         = WM_USER + 32;
  TTM_SETTITLEW                         = WM_USER + 33;

  TTM_POPUP                             = WM_USER + 34;
  TTM_GETTITLE                          = WM_USER + 35;

  TTF_IDISHWND                          = $0001;
  TTF_CENTERTIP                         = $0002;
  TTF_RTLREADING                        = $0004;
  TTF_SUBCLASS                          = $0010;

  TTDT_AUTOMATIC                        = 0;
  TTDT_RESHOW                           = 1;
  TTDT_AUTOPOP                          = 2;
  TTDT_INITIAL                          = 3;

  TTM_ACTIVATE                          = WM_USER + 1;
  TTM_SETDELAYTIME                      = WM_USER + 3;

  TTM_ADDTOOLA                          = WM_USER + 4;
  TTM_DELTOOLA                          = WM_USER + 5;
  TTM_NEWTOOLRECTA                      = WM_USER + 6;
  TTM_GETTOOLINFOA                      = WM_USER + 8;
  TTM_SETTOOLINFOA                      = WM_USER + 9;
  TTM_HITTESTA                          = WM_USER + 10;
  TTM_GETTEXTA                          = WM_USER + 11;
  TTM_UPDATETIPTEXTA                    = WM_USER + 12;
  TTM_ENUMTOOLSA                        = WM_USER + 14;
  TTM_GETCURRENTTOOLA                   = WM_USER + 15;
  TTM_WINDOWFROMPOINT                   = WM_USER + 16;

  TTM_GETDELAYTIME                      = WM_USER + 21;
  TTM_GETTIPBKCOLOR                     = WM_USER + 22;
  TTM_GETTIPTEXTCOLOR                   = WM_USER + 23;
  TTM_GETMAXTIPWIDTH                    = WM_USER + 25;
  TTM_SETMARGIN                         = WM_USER + 26;
  TTM_GETMARGIN                         = WM_USER + 27;
  TTM_POP                               = WM_USER + 28;
  TTM_UPDATE                            = WM_USER + 29;

  TTM_ADDTOOLW                          = WM_USER + 50;
  TTM_DELTOOLW                          = WM_USER + 51;
  TTM_NEWTOOLRECTW                      = WM_USER + 52;
  TTM_GETTOOLINFOW                      = WM_USER + 53;
  TTM_SETTOOLINFOW                      = WM_USER + 54;
  TTM_HITTESTW                          = WM_USER + 55;
  TTM_GETTEXTW                          = WM_USER + 56;
  TTM_UPDATETIPTEXTW                    = WM_USER + 57;
  TTM_ENUMTOOLSW                        = WM_USER + 58;
  TTM_GETCURRENTTOOLW                   = WM_USER + 59;

  TTM_ADDTOOL                           = TTM_ADDTOOLA;
  TTM_DELTOOL                           = TTM_DELTOOLA;
  TTM_NEWTOOLRECT                       = TTM_NEWTOOLRECTA;
  TTM_GETTOOLINFO                       = TTM_GETTOOLINFOA;
  TTM_SETTOOLINFO                       = TTM_SETTOOLINFOA;
  TTM_HITTEST                           = TTM_HITTESTA;
  TTM_GETTEXT                           = TTM_GETTEXTA;
  TTM_UPDATETIPTEXT                     = TTM_UPDATETIPTEXTA;
  TTM_ENUMTOOLS                         = TTM_ENUMTOOLSA;
  TTM_GETCURRENTTOOL                    = TTM_GETCURRENTTOOLA;

  TTM_RELAYEVENT                        = WM_USER + 7;
  TTM_GETTOOLCOUNT                      = WM_USER + 13;

type
  _TGETTITLE = packed record
    dwSize: DWORD;
    uTitleBitmap: UINT;
    cch: UINT;
    pszTitle: PWideChar;
  end;
  TGetTitle = _TGETTITLE;
  PGetTitle = ^TGetTitle;

const
  CCM_SETVERSION                        = CCM_FIRST + $07;
  CCM_GETVERSION                        = CCM_FIRST + $08;
  CCM_SETNOTIFYWINDOW                   = CCM_FIRST + $09; // wParam == hwndParent.
  CCM_SETWINDOWTHEME                    = CCM_FIRST + $0B;
  CCM_DPISCALE                          = CCM_FIRST + $0C; // wParam == Awareness

type
  PTTHitTestInfoA = ^TTTHitTestInfoA;
  PTTHitTestInfoW = ^TTTHitTestInfoW;
  PTTHitTestInfo = PTTHitTestInfoA;
  TTTHitTestInfoA = packed record
    HWND: HWND;
    Pt: TPoint;
    ti: TToolInfoA;
  end;
  TTTHitTestInfoW = packed record
    HWND: HWND;
    Pt: TPoint;
    ti: TToolInfoW;
  end;
  TTTHitTestInfo = TTTHitTestInfoA;

const
  TTN_NEEDTEXTA                         = TTN_FIRST - 0;
  TTN_NEEDTEXTW                         = TTN_FIRST - 10;

  TTN_NEEDTEXT                          = TTN_NEEDTEXTA;

  TTN_SHOW                              = TTN_FIRST - 1;
  TTN_POP                               = TTN_FIRST - 2;

type
  PToolTipTextA = ^TToolTipTextA;
  PToolTipTextW = ^TToolTipTextW;
  PTOOLTIPTEXT = PToolTipTextA;
  TToolTipTextA = packed record
    hdr: TNMHDR;
    lpszText: PAnsiChar;
    szText: array[0..79] of AnsiChar;
    hInst: THandle;
    uFlags: UINT;
  end;
  TToolTipTextW = packed record
    hdr: TNMHDR;
    lpszText: PWideChar;
    szText: array[0..79] of widechar;
    hInst: THandle;
    uFlags: UINT;
  end;
  TToolTipText = TToolTipTextA;

  { ====== STATUS BAR CONTROL ================= }

const
  SBARS_SIZEGRIP                        = $0100;

procedure DrawStatusTextA(HDC: HDC; lprc: PRect; pzsText: PAnsiChar;
  uFlags: UINT); stdcall;
procedure DrawStatusTextW(HDC: HDC; lprc: PRect; pzsText: PWideChar;
  uFlags: UINT); stdcall;
procedure DrawStatusText(HDC: HDC; lprc: PRect; pzsText: PChar;
  uFlags: UINT); stdcall;
function CreateStatusWindowA(Style: LONGINT; lpszText: PAnsiChar;
  hwndParent: HWND; wID: UINT): HWND; stdcall;
function CreateStatusWindowW(Style: LONGINT; lpszText: PWideChar;
  hwndParent: HWND; wID: UINT): HWND; stdcall;
function CreateStatusWindow(Style: LONGINT; lpszText: PChar;
  hwndParent: HWND; wID: UINT): HWND; stdcall;

const
  STATUSCLASSNAME                       = 'msctls_statusbar32';

const
  SB_SETTEXTA                           = WM_USER + 1;
  SB_GETTEXTA                           = WM_USER + 2;
  SB_GETTEXTLENGTHA                     = WM_USER + 3;
  SB_SETTIPTEXTA                        = WM_USER + 16;
  SB_GETTIPTEXTA                        = WM_USER + 18;

  SB_SETTEXTW                           = WM_USER + 11;
  SB_GETTEXTW                           = WM_USER + 13;
  SB_GETTEXTLENGTHW                     = WM_USER + 12;
  SB_SETTIPTEXTW                        = WM_USER + 17;
  SB_GETTIPTEXTW                        = WM_USER + 19;

  SB_SETTEXT                            = SB_SETTEXTA;
  SB_GETTEXT                            = SB_GETTEXTA;
  SB_GETTEXTLENGTH                      = SB_GETTEXTLENGTHA;
  SB_SETTIPTEXT                         = SB_SETTIPTEXTA;
  SB_GETTIPTEXT                         = SB_GETTIPTEXTA;

  SB_SETPARTS                           = WM_USER + 4;
  SB_GETPARTS                           = WM_USER + 6;
  SB_GETBORDERS                         = WM_USER + 7;
  SB_SETMINHEIGHT                       = WM_USER + 8;
  SB_SIMPLE                             = WM_USER + 9;
  SB_GETRECT                            = WM_USER + 10;
  SB_ISSIMPLE                           = WM_USER + 14;
  SB_SETICON                            = WM_USER + 15;
  SB_GETICON                            = WM_USER + 20;
  SB_SETUNICODEFORMAT                   = CCM_SETUNICODEFORMAT;
  SB_GETUNICODEFORMAT                   = CCM_GETUNICODEFORMAT;

  SBT_OWNERDRAW                         = $1000;
  SBT_NOBORDERS                         = $0100;
  SBT_POPOUT                            = $0200;
  SBT_RTLREADING                        = $0400;
  SBT_TOOLTIPS                          = $0800;

  SB_SETBKCOLOR                         = CCM_SETBKCOLOR; // lParam = bkColor

  // status bar notifications
  SBN_SIMPLEMODECHANGE                  = SBN_FIRST - 0;

  { ====== MENU HELP ========================== }

procedure MenuHelp(Msg: UINT; wParam: wParam; lParam: lParam;
  hMainMenu: HMENU; hInst: THandle; hwndStatus: HWND; lpwIDs: PUINT); stdcall;
function ShowHideMenuCtl(HWND: HWND; uFlags: UINT; lpInfo: PINT): BOOL; stdcall;
procedure GetEffectiveClientRect(HWND: HWND; lprc: PRect; lpInfo: PINT); stdcall;

const
  MINSYSCOMMAND                         = SC_SIZE;

  { ====== TRACKBAR CONTROL =================== }

  TRACKBAR_CLASS                        = 'msctls_trackbar32';

const
  TBS_AUTOTICKS                         = $0001;
  TBS_VERT                              = $0002;
  TBS_HORZ                              = $0000;
  TBS_TOP                               = $0004;
  TBS_BOTTOM                            = $0000;
  TBS_LEFT                              = $0004;
  TBS_RIGHT                             = $0000;
  TBS_BOTH                              = $0008;
  TBS_NOTICKS                           = $0010;
  TBS_ENABLESELRANGE                    = $0020;
  TBS_FIXEDLENGTH                       = $0040;
  TBS_NOTHUMB                           = $0080;

  TBM_GETPOS                            = WM_USER;
  TBM_GETRANGEMIN                       = WM_USER + 1;
  TBM_GETRANGEMAX                       = WM_USER + 2;
  TBM_GETTIC                            = WM_USER + 3;
  TBM_SETTIC                            = WM_USER + 4;
  TBM_SETPOS                            = WM_USER + 5;
  TBM_SETRANGE                          = WM_USER + 6;
  TBM_SETRANGEMIN                       = WM_USER + 7;
  TBM_SETRANGEMAX                       = WM_USER + 8;
  TBM_CLEARTICS                         = WM_USER + 9;
  TBM_SETSEL                            = WM_USER + 10;
  TBM_SETSELSTART                       = WM_USER + 11;
  TBM_SETSELEND                         = WM_USER + 12;
  TBM_GETPTICS                          = WM_USER + 14;
  TBM_GETTICPOS                         = WM_USER + 15;
  TBM_GETNUMTICS                        = WM_USER + 16;
  TBM_GETSELSTART                       = WM_USER + 17;
  TBM_GETSELEND                         = WM_USER + 18;
  TBM_CLEARSEL                          = WM_USER + 19;
  TBM_SETTICFREQ                        = WM_USER + 20;
  TBM_SETPAGESIZE                       = WM_USER + 21;
  TBM_GETPAGESIZE                       = WM_USER + 22;
  TBM_SETLINESIZE                       = WM_USER + 23;
  TBM_GETLINESIZE                       = WM_USER + 24;
  TBM_GETTHUMBRECT                      = WM_USER + 25;
  TBM_GETCHANNELRECT                    = WM_USER + 26;
  TBM_SETTHUMBLENGTH                    = WM_USER + 27;
  TBM_GETTHUMBLENGTH                    = WM_USER + 28;

  TB_LINEUP                             = 0;
  TB_LINEDOWN                           = 1;
  TB_PAGEUP                             = 2;
  TB_PAGEDOWN                           = 3;
  TB_THUMBPOSITION                      = 4;
  TB_THUMBTRACK                         = 5;
  TB_TOP                                = 6;
  TB_BOTTOM                             = 7;
  TB_ENDTRACK                           = 8;

  { ====== DRAG LIST CONTROL ================== }

type
  PDragListInfo = ^TDragListInfo;
  TDragListInfo = packed record
    uNotification: UINT;
    HWND: HWND;
    ptCursor: TPoint;
  end;

const
  DL_BEGINDRAG                          = WM_USER + 133;
  DL_DRAGGING                           = WM_USER + 134;
  DL_DROPPED                            = WM_USER + 135;
  DL_CANCELDRAG                         = WM_USER + 136;

  DL_CURSORSET                          = 0;
  DL_STOPCURSOR                         = 1;
  DL_COPYCURSOR                         = 2;
  DL_MOVECURSOR                         = 3;

const
  DRAGLISTMSGSTRING                     = 'commctrl_DragListMsg';

procedure MakeDragList(hLB: HWND); stdcall;
procedure DrawInsert(hwndParent: HWND; hLB: HWND; nItem: integer); stdcall;
function LBItemFromPt(hLB: HWND; Pt: TPoint; bAutoScroll: BOOL): integer; stdcall;

{ ====== UPDOWN CONTROL ========================== }

const
  UPDOWN_CLASS                          = 'msctls_updown32';

type
  PUDAccel = ^TUDAccel;
  TUDAccel = packed record
    nSec: UINT;
    nInc: UINT;
  end;

const
  UD_MAXVAL                             = $7FFF;
  UD_MINVAL                             = -UD_MAXVAL;

  UDS_WRAP                              = $0001;
  UDS_SETBUDDYINT                       = $0002;
  UDS_ALIGNRIGHT                        = $0004;
  UDS_ALIGNLEFT                         = $0008;
  UDS_AUTOBUDDY                         = $0010;
  UDS_ARROWKEYS                         = $0020;
  UDS_HORZ                              = $0040;
  UDS_NOTHOUSANDS                       = $0080;

  UDM_SETRANGE                          = WM_USER + 101;
  UDM_GETRANGE                          = WM_USER + 102;
  UDM_SETPOS                            = WM_USER + 103;
  UDM_GETPOS                            = WM_USER + 104;
  UDM_SETBUDDY                          = WM_USER + 105;
  UDM_GETBUDDY                          = WM_USER + 106;
  UDM_SETACCEL                          = WM_USER + 107;
  UDM_GETACCEL                          = WM_USER + 108;
  UDM_SETBASE                           = WM_USER + 109;
  UDM_GETBASE                           = WM_USER + 110;

function CreateUpDownControl(dwStyle: LONGINT; X, Y, cx, cy: integer;
  hParent: HWND; nID: integer; hInst: THandle; hBuddy: HWND;
  nUpper, nLower, nPos: integer): HWND; stdcall;

type
  PNMUpDown = ^TNMUpDown;
  TNMUpDown = packed record
    hdr: TNMHDR;
    iPos: integer;
    iDelta: integer;
  end;

const
  UDN_DELTAPOS                          = UDN_FIRST - 1;

  { ====== PROGRESS CONTROL ========================= }

const
  PROGRESS_CLASS                        = 'msctls_progress32';

type
  PPBRange = ^TPBRange;
  TPBRange = record
    ILow: integer;
    IHigh: integer;
  end;
  {
  const

    PBS_SMOOTH                            = $01;
    PBS_VERTICAL                          = $04;

    PBM_SETRANGE                          = WM_USER + 1;
    PBM_SETPOS                            = WM_USER + 2;
    PBM_DELTAPOS                          = WM_USER + 3;
    PBM_SETSTEP                           = WM_USER + 4;
    PBM_STEPIT                            = WM_USER + 5;
    PBM_SETRANGE32                        = WM_USER + 6; // lParam = high, wParam = low
    PBM_GETRANGE                          = WM_USER + 7; // lParam = PPBRange or Nil
     // wParam = False: Result = high
     // wParam = True: Result = low
    PBM_GETPOS                            = WM_USER + 8;
    PBM_SETBARCOLOR                       = WM_USER + 9; // lParam = bar color

    PBM_SETBKCOLOR                        = CCM_SETBKCOLOR; // lParam = bkColor
  }
     {  ====== HOTKEY CONTROL ========================== }

const
  HOTKEYF_SHIFT                         = $01;
  HOTKEYF_CONTROL                       = $02;
  HOTKEYF_ALT                           = $04;
  HOTKEYF_EXT                           = $08;

  HKCOMB_NONE                           = $0001;
  HKCOMB_S                              = $0002;
  HKCOMB_C                              = $0004;
  HKCOMB_A                              = $0008;
  HKCOMB_SC                             = $0010;
  HKCOMB_SA                             = $0020;
  HKCOMB_CA                             = $0040;
  HKCOMB_SCA                            = $0080;

  HKM_SETHOTKEY                         = WM_USER + 1;
  HKM_GETHOTKEY                         = WM_USER + 2;
  HKM_SETRULES                          = WM_USER + 3;

const
  HOTKEYCLASS                           = 'msctls_hotkey32';

  { ====== COMMON CONTROL STYLES ================ }

const
  CCS_TOP                               = $00000001;
  CCS_NOMOVEY                           = $00000002;
  CCS_BOTTOM                            = $00000003;
  CCS_NORESIZE                          = $00000004;
  CCS_NOPARENTALIGN                     = $00000008;
  CCS_ADJUSTABLE                        = $00000020;
  CCS_NODIVIDER                         = $00000040;
  CCS_VERT                              = $00000080;
  CCS_LEFT                              = (CCS_VERT or CCS_TOP);
  CCS_RIGHT                             = (CCS_VERT or CCS_BOTTOM);
  CCS_NOMOVEX                           = (CCS_VERT or CCS_NOMOVEY);

  { ====== LISTVIEW CONTROL ====================== }

const
  WC_LISTVIEW                           = 'SysListView32';

const

  { List View Styles }
  LVS_ICON                              = $0000;
  LVS_REPORT                            = $0001;
  LVS_SMALLICON                         = $0002;
  LVS_LIST                              = $0003;
  LVS_TYPEMASK                          = $0003;
  LVS_SINGLESEL                         = $0004;
  LVS_SHOWSELALWAYS                     = $0008;
  LVS_SORTASCENDING                     = $0010;
  LVS_SORTDESCENDING                    = $0020;
  LVS_SHAREIMAGELISTS                   = $0040;
  LVS_NOLABELWRAP                       = $0080;
  LVS_AUTOARRANGE                       = $0100;
  LVS_EDITLABELS                        = $0200;
  LVS_OWNERDATA                         = $1000;
  LVS_NOSCROLL                          = $2000;

  LVS_TYPESTYLEMASK                     = $FC00;

  LVS_ALIGNTOP                          = $0000;
  LVS_ALIGNLEFT                         = $0800;
  LVS_ALIGNMASK                         = $0C00;

  LVS_OWNERDRAWFIXED                    = $0400;
  LVS_NOCOLUMNHEADER                    = $4000;
  LVS_NOSORTHEADER                      = $8000;

  { List View Extended Styles }
{$EXTERNALSYM LVS_EX_GRIDLINES}
  LVS_EX_GRIDLINES                      = $00000001;
{$EXTERNALSYM LVS_EX_SUBITEMIMAGES}
  LVS_EX_SUBITEMIMAGES                  = $00000002;
{$EXTERNALSYM LVS_EX_CHECKBOXES}
  LVS_EX_CHECKBOXES                     = $00000004;
{$EXTERNALSYM LVS_EX_TRACKSELECT}
  LVS_EX_TRACKSELECT                    = $00000008;
{$EXTERNALSYM LVS_EX_HEADERDRAGDROP}
  LVS_EX_HEADERDRAGDROP                 = $00000010;
{$EXTERNALSYM LVS_EX_FULLROWSELECT}
  LVS_EX_FULLROWSELECT                  = $00000020; // applies to report mode only
{$EXTERNALSYM LVS_EX_ONECLICKACTIVATE}
  LVS_EX_ONECLICKACTIVATE               = $00000040;
{$EXTERNALSYM LVS_EX_TWOCLICKACTIVATE}
  LVS_EX_TWOCLICKACTIVATE               = $00000080;
{$EXTERNALSYM LVS_EX_FLATSB}
  LVS_EX_FLATSB                         = $00000100;
{$EXTERNALSYM LVS_EX_REGIONAL}
  LVS_EX_REGIONAL                       = $00000200;
{$EXTERNALSYM LVS_EX_INFOTIP}
  LVS_EX_INFOTIP                        = $00000400; // listview does InfoTips for you
{$EXTERNALSYM LVS_EX_UNDERLINEHOT}
  LVS_EX_UNDERLINEHOT                   = $00000800;
{$EXTERNALSYM LVS_EX_UNDERLINECOLD}
  LVS_EX_UNDERLINECOLD                  = $00001000;
{$EXTERNALSYM LVS_EX_MULTIWORKAREAS}
  LVS_EX_MULTIWORKAREAS                 = $00002000;

const
  LVM_GETBKCOLOR                        = LVM_FIRST + 0;

function ListView_GetBkColor(HWND: HWND): TColorRef;

const
  LVM_SETBKCOLOR                        = LVM_FIRST + 1;

function ListView_SetBkColor(HWND: HWND; ClrBk: TColorRef): BOOL;

const
  LVM_GETIMAGELIST                      = LVM_FIRST + 2;

const
  LVM_ISGROUPVIEWENABLED                = LVM_FIRST + 175;

function ListView_IsGroupViewEnabled(wnd: HWND): BOOL;

const
  LVM_GETOUTLINECOLOR                   = LVM_FIRST + 176;

function ListView_GetOutlineColor(wnd: HWND): COLORREF;

const
  LVM_SETOUTLINECOLOR                   = LVM_FIRST + 177;

function ListView_SetOutlineColor(wnd: HWND; Color: COLORREF): COLORREF;

const
  LVM_CANCELEDITLABEL                   = LVM_FIRST + 179;

procedure ListView_CancelEditLabel(wnd: HWND);

function ListView_GetImageList(HWND: HWND; iImageList: integer): HImageList;

const
  LVSIL_NORMAL                          = 0;
  LVSIL_SMALL                           = 1;
  LVSIL_STATE                           = 2;

const
  LVM_SETIMAGELIST                      = LVM_FIRST + 3;

function ListView_SetImageList(HWND: HWND; himl: HImageList;
  iImageList: integer): HImageList;

const
  LVM_GETITEMCOUNT                      = LVM_FIRST + 4;

function ListView_GetItemCount(HWND: HWND): integer;

const
  LVIF_TEXT                             = $0001;
  LVIF_IMAGE                            = $0002;
  LVIF_PARAM                            = $0004;
  LVIF_STATE                            = $0008;

  LVIS_FOCUSED                          = $0001;
  LVIS_SELECTED                         = $0002;
  LVIS_CUT                              = $0004;
  LVIS_DROPHILITED                      = $0008;

  LVIS_OVERLAYMASK                      = $0F00;
  LVIS_STATEIMAGEMASK                   = $F000;

function IndexToStateImageMask(i: LONGINT): LONGINT;

type
  LVINSERTMARK = packed record
    cbSize: UINT;
    dwFlags: DWORD;
    iItem: integer;
    dwReserved: DWORD;
  end;
  TLVInsertMark = LVINSERTMARK;
  PLVInsertMark = ^TLVInsertMark;

const
  LVIM_AFTER                            = $00000001; // TRUE = insert After iItem, otherwise before

const
  LVM_SETINSERTMARK                     = LVM_FIRST + 166;
  LVM_GETINSERTMARK                     = LVM_FIRST + 167;

function ListView_SetInsertMark(wnd: HWND; lvim: TLVInsertMark): BOOL;
function ListView_GetInsertMark(wnd: HWND; var lvim: TLVInsertMark): BOOL;

const
  LVM_INSERTMARKHITTEST                 = LVM_FIRST + 168;
  LVM_GETINSERTMARKRECT                 = LVM_FIRST + 169;
  LVM_SETINSERTMARKCOLOR                = LVM_FIRST + 170;
  LVM_GETINSERTMARKCOLOR                = LVM_FIRST + 171;

function ListView_InsertMarkHitTest(wnd: HWND; Point: TPoint; lvim: TLVInsertMark): integer;
function ListView_GetInsertMarkRect(wnd: HWND; var RC: TRect): integer;
function ListView_SetInsertMarkColor(wnd: HWND; Color: COLORREF): COLORREF;
function ListView_GetInsertMarkColor(wnd: HWND): COLORREF;

type
  PLVItemA = ^TLVItemA;
  PLVItemW = ^TLVItemW;
  PLVItem = PLVItemA;
  TLVItemA = packed record
    Mask: UINT;
    iItem: integer;
    iSubItem: integer;
    State: UINT;
    stateMask: UINT;
    pszText: PAnsiChar;
    cchTextMax: integer;
    iImage: integer;
    lParam: lParam;
  end;
  TLVItemW = packed record
    Mask: UINT;
    iItem: integer;
    iSubItem: integer;
    State: UINT;
    stateMask: UINT;
    pszText: PWideChar;
    cchTextMax: integer;
    iImage: integer;
    lParam: lParam;
  end;
  TLVItem = TLVItemA;

const
  LPSTR_TEXTCALLBACKA                   = LPSTR(-1);
  LPSTR_TEXTCALLBACKW                   = LPWSTR(-1);

  LPSTR_TEXTCALLBACK                    = LPSTR_TEXTCALLBACKA;

  I_IMAGECALLBACK                       = -1;

const
  LVM_GETITEMA                          = LVM_FIRST + 5;
  LVM_SETITEMA                          = LVM_FIRST + 6;
  LVM_INSERTITEMA                       = LVM_FIRST + 7;

  LVM_GETITEMW                          = LVM_FIRST + 75;
  LVM_SETITEMW                          = LVM_FIRST + 76;
  LVM_INSERTITEMW                       = LVM_FIRST + 77;

  LVM_GETITEM                           = LVM_GETITEMA;
  LVM_SETITEM                           = LVM_SETITEMA;
  LVM_INSERTITEM                        = LVM_INSERTITEMA;

  LVM_DELETEITEM                        = LVM_FIRST + 8;
  LVM_DELETEALLITEMS                    = LVM_FIRST + 9;
  LVM_GETCALLBACKMASK                   = LVM_FIRST + 10;
  LVM_SETCALLBACKMASK                   = LVM_FIRST + 11;

function ListView_GetItemA(HWND: HWND; var pItem: TLVItemA): BOOL;
function ListView_GetItemW(HWND: HWND; var pItem: TLVItemW): BOOL;
function ListView_GetItem(HWND: HWND; var pItem: TLVItem): BOOL;
function ListView_SetItemA(HWND: HWND; const pItem: TLVItemA): BOOL;
function ListView_SetItemW(HWND: HWND; const pItem: TLVItemW): BOOL;
function ListView_SetItem(HWND: HWND; const pItem: TLVItem): BOOL;
function ListView_InsertItemA(HWND: HWND; const pItem: TLVItemA): integer;
function ListView_InsertItemW(HWND: HWND; const pItem: TLVItemW): integer;
function ListView_InsertItem(HWND: HWND; const pItem: TLVItem): integer;
function ListView_DeleteItem(HWND: HWND; i: integer): BOOL;
function ListView_DeleteAllItems(HWND: HWND): BOOL;
function ListView_GetCallbackMask(HWND: HWND): UINT;
function ListView_SetCallbackMask(HWND: HWND; Mask: UINT): BOOL;

const
  LVNI_ALL                              = $0000;
  LVNI_FOCUSED                          = $0001;
  LVNI_SELECTED                         = $0002;
  LVNI_CUT                              = $0004;
  LVNI_DROPHILITED                      = $0008;

  LVNI_ABOVE                            = $0100;
  LVNI_BELOW                            = $0200;
  LVNI_TOLEFT                           = $0400;
  LVNI_TORIGHT                          = $0800;

const
  LVM_GETNEXTITEM                       = LVM_FIRST + 12;

function ListView_GetNextItem(HWND: HWND; iStart: integer; Flags: UINT): integer;

const
  LVFI_PARAM                            = $0001;
  LVFI_STRING                           = $0002;
  LVFI_PARTIAL                          = $0008;
  LVFI_WRAP                             = $0020;
  LVFI_NEARESTXY                        = $0040;

type
  PLVFindInfoA = ^TLVFindInfoA;
  PLVFindInfoW = ^TLVFindInfoW;
  PLVFindInfo = PLVFindInfoA;
  TLVFindInfoA = packed record
    Flags: UINT;
    psz: PAnsiChar;
    lParam: lParam;
    Pt: TPoint;
    vkDirection: UINT;
  end;
  TLVFindInfoW = packed record
    Flags: UINT;
    psz: PWideChar;
    lParam: lParam;
    Pt: TPoint;
    vkDirection: UINT;
  end;
  TLVFindInfo = TLVFindInfoA;

const
  LVM_FINDITEMA                         = LVM_FIRST + 13;
  LVM_FINDITEMW                         = LVM_FIRST + 83;
  LVM_FINDITEM                          = LVM_FINDITEMA;

function ListView_FindItemA(HWND: HWND; iStart: integer;
  const plvfi: TLVFindInfoA): integer;
function ListView_FindItemW(HWND: HWND; iStart: integer;
  const plvfi: TLVFindInfoW): integer;
function ListView_FindItem(HWND: HWND; iStart: integer;
  const plvfi: TLVFindInfo): integer;

const
  LVIF_GROUPID                          = $0100;
  LVIF_COLUMNS                          = $0200;

  LVIS_GLOW                             = $0010;

type
  PLVItem60A = ^TLVItemA;
  PLVItem60W = ^TLVItemW;
  PLVItem60 = PLVItemA;
  tagLVITEM60A = packed record
    Mask: UINT;
    iItem: integer;
    iSubItem: integer;
    State: UINT;
    stateMask: UINT;
    pszText: PAnsiChar;
    cchTextMax: integer;
    iImage: integer;
    lParam: lParam;
    iIndent: integer;
    iGroupId: integer;
    cColumns: UINT;
    puColumns: PUINT;
  end;
  tagLVITEM60W = packed record
    Mask: UINT;
    iItem: integer;
    iSubItem: integer;
    State: UINT;
    stateMask: UINT;
    pszText: PWideChar;
    cchTextMax: integer;
    iImage: integer;
    lParam: lParam;
    iIndent: integer;
    iGroupId: integer;
    cColumns: UINT;
    puColumns: PUINT;
  end;
  tagLVITEM60 = tagLVITEM60A;
  _LV_ITEM60A = tagLVITEM60A;
  _LV_ITEM60W = tagLVITEM60W;
  _LV_ITEM60 = _LV_ITEM60A;
  TLVItem60A = tagLVITEM60A;
  TLVItem60W = tagLVITEM60W;
  TLVItem60 = TLVItem60A;
  LV_ITEM60A = tagLVITEM60A;
  LV_ITEM60W = tagLVITEM60W;
  LV_ITEM60 = LV_ITEM60A;

const
  I_IMAGENONE                           = -2;
  I_COLUMNSCALLBACK                     = UINT(-1);

function ListView_SetExtendedListViewStyleEx(hwndLV: HWND; dwMask, dw: DWORD): DWORD;

const
  LVM_SORTITEMSEX                       = LVM_FIRST + 81;

const
  LVIR_BOUNDS                           = 0;
  LVIR_ICON                             = 1;
  LVIR_LABEL                            = 2;
  LVIR_SELECTBOUNDS                     = 3;

const
  LVM_GETITEMRECT                       = LVM_FIRST + 14;

function ListView_GetItemRect(HWND: HWND; i: integer; var prc: TRect;
  code: integer): BOOL;

const
  LVM_SETITEMPOSITION                   = LVM_FIRST + 15;

function ListView_SetItemPosition(HWND: HWND; i, X, Y: integer): BOOL;

const
  LVM_GETITEMPOSITION                   = LVM_FIRST + 16;

function ListView_GetItemPosition(hwndLV: HWND; i: integer; var ppt: TPoint): BOOL;

const
  LVM_GETSTRINGWIDTHA                   = LVM_FIRST + 17;
  LVM_GETSTRINGWIDTHW                   = LVM_FIRST + 87;
  LVM_GETSTRINGWIDTH                    = LVM_GETSTRINGWIDTHA;

function ListView_GetStringWidthA(hwndLV: HWND; psz: PAnsiChar): integer;
function ListView_GetStringWidthW(hwndLV: HWND; psz: PWideChar): integer;
function ListView_GetStringWidth(hwndLV: HWND; psz: PChar): integer;

const
  LVHT_NOWHERE                          = $0001;
  LVHT_ONITEMICON                       = $0002;
  LVHT_ONITEMLABEL                      = $0004;
  LVHT_ONITEMSTATEICON                  = $0008;
  LVHT_ONITEM                           = LVHT_ONITEMICON or LVHT_ONITEMLABEL or
    LVHT_ONITEMSTATEICON;
  LVHT_ABOVE                            = $0008;
  LVHT_BELOW                            = $0010;
  LVHT_TORIGHT                          = $0020;
  LVHT_TOLEFT                           = $0040;

type
  PLVHitTestInfo = ^TLVHitTestInfo;
  TLVHitTestInfo = packed record
    Pt: TPoint;
    Flags: UINT;
    iItem: integer;
  end;

const
  LVM_HITTEST                           = LVM_FIRST + 18;

function ListView_HitTest(hwndLV: HWND; var pinfo: TLVHitTestInfo): integer;

const
  LVM_ENSUREVISIBLE                     = LVM_FIRST + 19;

function ListView_EnsureVisible(hwndLV: HWND; i: integer; fPartialOK: BOOL): BOOL;

const
  LVM_SCROLL                            = LVM_FIRST + 20;

function ListView_Scroll(hwndLV: HWND; DX, DY: integer): BOOL;

const
  LVM_REDRAWITEMS                       = LVM_FIRST + 21;

function ListView_RedrawItems(hwndLV: HWND; iFirst, iLast: integer): BOOL;

const
  LVA_DEFAULT                           = $0000;
  LVA_ALIGNLEFT                         = $0001;
  LVA_ALIGNTOP                          = $0002;
  LVA_ALIGNRIGHT                        = $0003;
  LVA_ALIGNBOTTOM                       = $0004;
  LVA_SNAPTOGRID                        = $0005;

  LVA_SORTASCENDING                     = $0100;
  LVA_SORTDESCENDING                    = $0200;

  LVM_ARRANGE                           = LVM_FIRST + 22;

function ListView_Arrange(hwndLV: HWND; code: UINT): BOOL;

const
  LVM_EDITLABELA                        = LVM_FIRST + 23;
  LVM_EDITLABELW                        = LVM_FIRST + 118;
  LVM_EDITLABEL                         = LVM_EDITLABELA;

function ListView_EditLabelA(hwndLV: HWND; i: integer): HWND;
function ListView_EditLabelW(hwndLV: HWND; i: integer): HWND;
function ListView_EditLabel(hwndLV: HWND; i: integer): HWND;

const
  LVM_GETEDITCONTROL                    = LVM_FIRST + 24;

function ListView_GetEditControl(hwndLV: HWND): HWND;

type
  tagLVTILEVIEWINFO = packed record
    cbSize: UINT;
    dwMask,
      dwFlags: DWORD;
    sizeTile: integer;
    cLines: integer;
    rcLabelMargin: TRect;
  end;
  TLVTileViewInfo = tagLVTILEVIEWINFO;
  PLVTileViewInfo = ^TLVTileViewInfo;

  tagLVTILEINFO = packed record
    cbSize: UINT;
    iItem: integer;
    cColumns: UINT;
    puColumns: PUINT;
  end;
  TLVTileInfo = tagLVTILEINFO;
  PLVTileInfo = ^TLVTileInfo;

type
  PLVColumnA = ^TLVColumnA;
  PLVColumnW = ^TLVColumnW;
  PLVColumn = PLVColumnA;
  tagLVCOLUMNA = packed record
    Mask: UINT;
    fmt: integer;
    cx: integer;
    pszText: PAnsiChar;
    cchTextMax: integer;
    iSubItem: integer;
    iImage: integer;
    iOrder: integer;
  end;
  tagLVCOLUMNW = packed record
    Mask: UINT;
    fmt: integer;
    cx: integer;
    pszText: PWideChar;
    cchTextMax: integer;
    iSubItem: integer;
    iImage: integer;
    iOrder: integer;
  end;
  tagLVCOLUMN = tagLVCOLUMNA;
  _LV_COLUMNA = tagLVCOLUMNA;
  _LV_COLUMNW = tagLVCOLUMNW;
  _LV_COLUMN = _LV_COLUMNA;
  TLVColumnA = tagLVCOLUMNA;
  TLVColumnW = tagLVCOLUMNW;
  TLVColumn = TLVColumnA;
  LV_COLUMNA = tagLVCOLUMNA;
  LV_COLUMNW = tagLVCOLUMNW;
  LV_COLUMN = LV_COLUMNA;

const
  LVM_SETTILEVIEWINFO                   = LVM_FIRST + 162;
  LVM_GETTILEVIEWINFO                   = LVM_FIRST + 163;
  LVM_SETTILEINFO                       = LVM_FIRST + 164;
  LVM_GETTILEINFO                       = LVM_FIRST + 165;

function ListView_SetTileViewInfo(wnd: HWND; ptvi: TLVTileViewInfo): BOOL;
procedure ListView_GetTileViewInfo(wnd: HWND; var ptvi: TLVTileViewInfo);
function ListView_SetTileInfo(wnd: HWND; pti: TLVTileInfo): BOOL;
procedure ListView_GetTileInfo(wnd: HWND; var pti: TLVTileInfo);

const
  LV_VIEW_ICON                          = $0000;
  LV_VIEW_DETAILS                       = $0001;
  LV_VIEW_SMALLICON                     = $0002;
  LV_VIEW_LIST                          = $0003;
  LV_VIEW_TILE                          = $0004;
  LV_VIEW_MAX                           = $0004;

const
  LVM_SETVIEW                           = LVM_FIRST + 142;
  LVM_GETVIEW                           = LVM_FIRST + 143;

const
  LVGF_NONE                             = $00000000;
  LVGF_HEADER                           = $00000001;
  LVGF_FOOTER                           = $00000002;
  LVGF_STATE                            = $00000004;
  LVGF_ALIGN                            = $00000008;
  LVGF_GROUPID                          = $00000010;

  LVGS_NORMAL                           = $00000000;
  LVGS_COLLAPSED                        = $00000001;
  LVGS_HIDDEN                           = $00000002;

  LVGA_HEADER_LEFT                      = $00000001;
  LVGA_HEADER_CENTER                    = $00000002;
  LVGA_HEADER_RIGHT                     = $00000004; // Don't forget to validate exclusivity
  LVGA_FOOTER_LEFT                      = $00000008;
  LVGA_FOOTER_CENTER                    = $00000010;
  LVGA_FOOTER_RIGHT                     = $00000020; // Don't forget to validate exclusivity

type
  tagLVGROUP = packed record
    cbSize,
      Mask: UINT;
    pszHeader: LPWSTR;
    cchHeader: integer;
    pszFooter: LPWSTR;
    cchFooter: integer;
    iGroupId: integer;
    stateMask: UINT;
    State: UINT;
    uAlign: UINT;
  end;
  TLVGroup = tagLVGROUP;
  PLVGroup = ^TLVGroup;

const
  LVM_INSERTGROUP                       = LVM_FIRST + 145;

function ListView_InsertGroup(wnd: HWND; Index: integer; pgrp: TLVGroup): integer;

const
  LVM_SETGROUPINFO                      = LVM_FIRST + 147;
  LVM_GETGROUPINFO                      = LVM_FIRST + 149;

function ListView_SetGroupInfo(wnd: HWND; iGroupId: integer; pgrp: TLVGroup): integer;
function ListView_GetGroupInfo(wnd: HWND; iGroupId: integer; var pgrp: TLVGroup): integer;

const
  LVM_REMOVEGROUP                       = LVM_FIRST + 150;

function ListView_RemoveGroup(wnd: HWND; iGroupId: integer): integer;

const
  LVM_MOVEGROUP                         = LVM_FIRST + 151;
  LVM_MOVEITEMTOGROUP                   = LVM_FIRST + 154;

procedure ListView_MoveGroup(wnd: HWND; iGroupId, toIndex: integer);
procedure ListView_MoveItemToGroup(wnd: HWND; idItemFrom, idGroupTo: integer);

const
  LVGMF_NONE                            = $00000000;
  LVGMF_BORDERSIZE                      = $00000001;
  LVGMF_BORDERCOLOR                     = $00000002;
  LVGMF_TEXTCOLOR                       = $00000004;

type
  tagLVGROUPMETRICS = packed record
    cbSize,
      Mask,
      Left,
      Top,
      Right,
      Bottom: UINT;
    crLeft,
      crTop,
      crRight,
      crBottom,
      crHeader,
      crFooter: COLORREF;
  end;
  TLVGroupMetrics = tagLVGROUPMETRICS;
  PLVGroupMetrics = ^TLVGroupMetrics;

const
  LVM_SETGROUPMETRICS                   = LVM_FIRST + 155;
  LVM_GETGROUPMETRICS                   = LVM_FIRST + 156;

procedure ListView_SetGroupMetrics(wnd: HWND; pGroupMetrics: TLVGroupMetrics);
procedure ListView_GetGroupMetrics(wnd: HWND; var pGroupMetrics: TLVGroupMetrics);

const
  LVM_ENABLEGROUPVIEW                   = LVM_FIRST + 157;

function ListView_EnableGroupView(wnd: HWND; fEnable: BOOL): integer;

type
  PFNLVGROUPCOMPARE = function(lParam1, lParam2: integer; plv: Pointer): integer; stdcall;
  TLVGroupCompare = PFNLVGROUPCOMPARE;

const
  LVM_SORTGROUPS                        = LVM_FIRST + 158;

function ListView_SortGroups(wnd: HWND; fnGroupCompare: TLVGroupCompare; plv: Pointer): integer;

type
  tagLVINSERTGROUPSORTED = packed record
    pfnGroupCompare: PFNLVGROUPCOMPARE;
    pvData: Pointer;
    lvGroup: TLVGroup;
  end;
  TVLInsertGroupSorted = tagLVINSERTGROUPSORTED;
  PVLInsertGroupSorted = ^TVLInsertGroupSorted;

const
  LVM_INSERTGROUPSORTED                 = LVM_FIRST + 159;

procedure ListView_InsertGroupSorted(wnd: HWND; structInsert: TVLInsertGroupSorted);

const
  LVM_REMOVEALLGROUPS                   = LVM_FIRST + 160;

procedure ListView_RemoveAllGroups(wnd: HWND);

const
  LVM_HASGROUP                          = LVM_FIRST + 161;

function ListView_HasGroup(wnd: HWND; dwGroupId: DWORD): BOOL;

function ListView_SetView(wnd: HWND; iView: DWORD): DWORD;
function ListView_GetView(wnd: HWND): DWORD;

const
  LVCF_FMT                              = $0001;
  LVCF_WIDTH                            = $0002;
  LVCF_TEXT                             = $0004;
  LVCF_SUBITEM                          = $0008;
  LVCF_IMAGE                            = $0010;
  LVCF_ORDER                            = $0020;

  LVCFMT_LEFT                           = $0000;
  LVCFMT_RIGHT                          = $0001;
  LVCFMT_CENTER                         = $0002;
  LVCFMT_JUSTIFYMASK                    = $0003;
  LVCFMT_IMAGE                          = $0800;
  LVCFMT_BITMAP_ON_RIGHT                = $1000;
  LVCFMT_COL_HAS_IMAGES                 = $8000;

  LVM_GETCOLUMNA                        = LVM_FIRST + 25;
  LVM_GETCOLUMNW                        = LVM_FIRST + 95;
  LVM_GETCOLUMN                         = LVM_GETCOLUMNA;

function ListView_GetColumnA(HWND: HWND; iCol: integer;
  var pcol: TLVColumnA): BOOL;
function ListView_GetColumnW(HWND: HWND; iCol: integer;
  var pcol: TLVColumnW): BOOL;
function ListView_GetColumn(HWND: HWND; iCol: integer;
  var pcol: TLVColumn): BOOL;

const
  LVM_SETCOLUMNA                        = LVM_FIRST + 26;
  LVM_SETCOLUMNW                        = LVM_FIRST + 96;
  LVM_SETCOLUMN                         = LVM_SETCOLUMNA;

function ListView_SetColumnA(HWND: HWND; iCol: integer; const pcol: TLVColumnA): BOOL;
function ListView_SetColumnW(HWND: HWND; iCol: integer; const pcol: TLVColumnW): BOOL;
function ListView_SetColumn(HWND: HWND; iCol: integer; const pcol: TLVColumn): BOOL;

const
  LVM_INSERTCOLUMNA                     = LVM_FIRST + 27;
  LVM_INSERTCOLUMNW                     = LVM_FIRST + 97;
  LVM_INSERTCOLUMN                      = LVM_INSERTCOLUMNA;

function ListView_InsertColumnA(HWND: HWND; iCol: integer;
  const pcol: TLVColumnA): integer;
function ListView_InsertColumnW(HWND: HWND; iCol: integer;
  const pcol: TLVColumnW): integer;
function ListView_InsertColumn(HWND: HWND; iCol: integer;
  const pcol: TLVColumn): integer;

const
  LVM_DELETECOLUMN                      = LVM_FIRST + 28;

function ListView_DeleteColumn(HWND: HWND; iCol: integer): BOOL;

const
  LVM_GETCOLUMNWIDTH                    = LVM_FIRST + 29;

function ListView_GetColumnWidth(HWND: HWND; iCol: integer): integer;

const
  LVSCW_AUTOSIZE                        = -1;
  LVSCW_AUTOSIZE_USEHEADER              = -2;
  LVM_SETCOLUMNWIDTH                    = LVM_FIRST + 30;

function ListView_SetColumnWidth(HWND: HWND; iCol: integer; cx: integer): BOOL;

const
  LVM_CREATEDRAGIMAGE                   = LVM_FIRST + 33;

function ListView_CreateDragImage(HWND: HWND; i: integer;
  const lpptUpLeft: TPoint): HImageList;

const
  LVM_GETVIEWRECT                       = LVM_FIRST + 34;

function ListView_GetViewRect(HWND: HWND; var prc: TRect): BOOL;

const
  LVM_GETTEXTCOLOR                      = LVM_FIRST + 35;

function ListView_GetTextColor(HWND: HWND): TColorRef;

const
  LVM_SETTEXTCOLOR                      = LVM_FIRST + 36;

function ListView_SetTextColor(HWND: HWND; clrText: TColorRef): BOOL;

const
  LVM_GETTEXTBKCOLOR                    = LVM_FIRST + 37;

function ListView_GetTextBkColor(HWND: HWND): TColorRef;

const
  LVM_SETTEXTBKCOLOR                    = LVM_FIRST + 38;

function ListView_SetTextBkColor(HWND: HWND; clrTextBk: TColorRef): BOOL;

const
  LVM_GETTOPINDEX                       = LVM_FIRST + 39;

function ListView_GetTopIndex(hwndLV: HWND): integer;

const
  LVM_GETCOUNTPERPAGE                   = LVM_FIRST + 40;

function ListView_GetCountPerPage(hwndLV: HWND): integer;

const
  LVM_GETORIGIN                         = LVM_FIRST + 41;

function ListView_GetOrigin(hwndLV: HWND; var ppt: TPoint): BOOL;

const
  LVM_UPDATE                            = LVM_FIRST + 42;

function ListView_Update(hwndLV: HWND; i: integer): BOOL;

const
  LVM_SETITEMSTATE                      = LVM_FIRST + 43;

function ListView_SetItemState(hwndLV: HWND; i: integer; data, Mask: UINT): BOOL;

const
  LVM_GETITEMSTATE                      = LVM_FIRST + 44;

function ListView_GetItemState(hwndLV: HWND; i, Mask: integer): integer;

function ListView_GetCheckState(hwndLV: HWND; i: integer): UINT;
procedure ListView_SetCheckState(hwndLV: HWND; i: integer; Checked: boolean);

const
  LVM_GETITEMTEXTA                      = LVM_FIRST + 45;
  LVM_GETITEMTEXTW                      = LVM_FIRST + 115;
  LVM_GETITEMTEXT                       = LVM_GETITEMTEXTA;

function ListView_GetItemTextA(hwndLV: HWND; i, iSubItem: integer;
  pszText: PAnsiChar; cchTextMax: integer): integer;
function ListView_GetItemTextW(hwndLV: HWND; i, iSubItem: integer;
  pszText: PWideChar; cchTextMax: integer): integer;
function ListView_GetItemText(hwndLV: HWND; i, iSubItem: integer;
  pszText: PChar; cchTextMax: integer): integer;

const
  LVM_SETITEMTEXTA                      = LVM_FIRST + 46;
  LVM_SETITEMTEXTW                      = LVM_FIRST + 116;
  LVM_SETITEMTEXT                       = LVM_SETITEMTEXTA;

function ListView_SetItemTextA(hwndLV: HWND; i, iSubItem: integer;
  pszText: PAnsiChar): BOOL;
function ListView_SetItemTextW(hwndLV: HWND; i, iSubItem: integer;
  pszText: PWideChar): BOOL;
function ListView_SetItemText(hwndLV: HWND; i, iSubItem: integer;
  pszText: PChar): BOOL;

const
  LVM_SETITEMCOUNT                      = LVM_FIRST + 47;

procedure ListView_SetItemCount(hwndLV: HWND; cItems: integer);

type
  TLVCompare = function(lParam1, lParam2, lParamSort: integer): integer stdcall;

const
  LVM_SORTITEMS                         = LVM_FIRST + 48;

function ListView_SortItems(hwndLV: HWND; pfnCompare: TLVCompare;
  lPrm: LONGINT): BOOL;

const
  LVM_SETITEMPOSITION32                 = LVM_FIRST + 49;

procedure ListView_SetItemPosition32(hwndLV: HWND; i, X, Y: integer);

const
  LVM_GETSELECTEDCOUNT                  = LVM_FIRST + 50;

function ListView_GetSelectedCount(hwndLV: HWND): UINT;

const
  LVM_GETITEMSPACING                    = LVM_FIRST + 51;

function ListView_GetItemSpacing(hwndLV: HWND; fSmall: integer): LONGINT;

const
  LVM_GETISEARCHSTRINGA                 = LVM_FIRST + 52;
  LVM_GETISEARCHSTRINGW                 = LVM_FIRST + 117;
  LVM_GETISEARCHSTRING                  = LVM_GETISEARCHSTRINGA;

function ListView_GetISearchStringA(hwndLV: HWND; lpsz: PAnsiChar): BOOL;
function ListView_GetISearchStringW(hwndLV: HWND; lpsz: PWideChar): BOOL;
function ListView_GetISearchString(hwndLV: HWND; lpsz: PChar): BOOL;

const
  LVM_SETICONSPACING                    = LVM_FIRST + 53;

  // -1 for cx and cy means we'll use the default (system settings)
  // 0 for cx or cy means use the current setting (allows you to change just one param)
function ListView_SetIconSpacing(hwndLV: HWND; cx, cy: Word): DWORD;

const
  LVM_SETEXTENDEDLISTVIEWSTYLE          = LVM_FIRST + 54;

function ListView_SetExtendedListViewStyle(hwndLV: HWND; dw: integer {DWORD}): BOOL;

const
  LVM_GETEXTENDEDLISTVIEWSTYLE          = LVM_FIRST + 55;

function ListView_GetExtendedListViewStyle(hwndLV: HWND): DWORD;

const
  LVM_GETSUBITEMRECT                    = LVM_FIRST + 56;

function ListView_GetSubItemRect(hwndLV: HWND; iItem, iSubItem: integer;
  code: DWORD; prc: PRect): BOOL;

const
  LVM_SUBITEMHITTEST                    = LVM_FIRST + 57;

function ListView_SubItemHitTest(hwndLV: HWND; plvhti: PLVHitTestInfo): integer;

const
  LVM_SETCOLUMNORDERARRAY               = LVM_FIRST + 58;

function ListView_SetColumnOrderArray(hwndLV: HWND; iCount: integer;
  PI: PInteger): BOOL;

const
  LVM_GETCOLUMNORDERARRAY               = LVM_FIRST + 59;

function ListView_GetColumnOrderArray(hwndLV: HWND; iCount: integer;
  PI: PInteger): BOOL;

const
  LVM_SETSELECTEDCOLUMN                 = LVM_FIRST + 140;

procedure ListView_SetSelectedColumn(wnd: HWND; iCol: integer);

const
  LVM_SETHOTITEM                        = LVM_FIRST + 60;

function ListView_SetHotItem(hwndLV: HWND; i: integer): integer;

const
  LVM_GETHOTITEM                        = LVM_FIRST + 61;

function ListView_GetHotItem(hwndLV: HWND): integer;

const
  LVM_SETHOTCURSOR                      = LVM_FIRST + 62;

function ListView_SetHotCursor(hwndLV: HWND; hcur: HCURSOR): HCURSOR;

const
  LVM_GETHOTCURSOR                      = LVM_FIRST + 63;

function ListView_GetHotCursor(hwndLV: HWND): HCURSOR;

const
  LVM_APPROXIMATEVIEWRECT               = LVM_FIRST + 64;

function ListView_ApproximateViewRect(hwndLV: HWND; iWidth, iHeight: Word;
  iCount: integer): DWORD;

const
  LVM_SETWORKAREA                       = LVM_FIRST + 65;

function ListView_SetWorkArea(hwndLV: HWND; prc: PRect): BOOL;

const
  LVTVIF_AUTOSIZE                       = $00000000;
  LVTVIF_FIXEDWIDTH                     = $00000001;
  LVTVIF_FIXEDHEIGHT                    = $00000002;
  LVTVIF_FIXEDSIZE                      = $00000003;

  LVTVIM_TILESIZE                       = $00000001;
  LVTVIM_COLUMNS                        = $00000002;
  LVTVIM_LABELMARGIN                    = $00000004;

type
  PNMListView = ^TNMListView;
  TNMListView = packed record
    hdr: TNMHDR;
    iItem: integer;
    iSubItem: integer;
    uNewState: UINT;
    uOldState: UINT;
    uChanged: UINT;
    ptAction: TPoint;
    lParam: lParam;
  end;

  PNMCacheHint = ^TNMCacheHint;
  TNMCacheHint = packed record
    hdr: TNMHDR;
    iFrom: integer;
    iTo: integer;
  end;

  PNMFinditem = ^TNMFinditem;
  TNMFinditem = packed record
    hdr: TNMHDR;
    iStart: integer;
    lvfi: TLVFindInfo;
  end;

const
  LVN_ITEMCHANGING                      = LVN_FIRST - 0;
  LVN_ITEMCHANGED                       = LVN_FIRST - 1;
  LVN_INSERTITEM                        = LVN_FIRST - 2;
  LVN_DELETEITEM                        = LVN_FIRST - 3;
  LVN_DELETEALLITEMS                    = LVN_FIRST - 4;
  LVN_COLUMNCLICK                       = LVN_FIRST - 8;
  LVN_BEGINDRAG                         = LVN_FIRST - 9;
  LVN_BEGINRDRAG                        = LVN_FIRST - 11;

  LVN_ODCACHEHINT                       = LVN_FIRST - 13;
  LVN_ODFINDITEMA                       = LVN_FIRST - 52;
  LVN_ODFINDITEMW                       = LVN_FIRST - 79;

  LVN_ODFINDITEM                        = LVN_ODFINDITEMA;

  LVN_BEGINLABELEDITA                   = LVN_FIRST - 5;
  LVN_ENDLABELEDITA                     = LVN_FIRST - 6;
  LVN_BEGINLABELEDITW                   = LVN_FIRST - 75;
  LVN_ENDLABELEDITW                     = LVN_FIRST - 76;
  LVN_BEGINLABELEDIT                    = LVN_BEGINLABELEDITA;
  LVN_ENDLABELEDIT                      = LVN_ENDLABELEDITA;

const
  LVN_GETDISPINFOA                      = LVN_FIRST - 50;
  LVN_SETDISPINFOA                      = LVN_FIRST - 51;
  LVN_GETDISPINFOW                      = LVN_FIRST - 77;
  LVN_SETDISPINFOW                      = LVN_FIRST - 78;
  LVN_GETDISPINFO                       = LVN_GETDISPINFOA;
  LVN_SETDISPINFO                       = LVN_SETDISPINFOA;

  LVIF_DI_SETITEM                       = $1000;

type
  PLVDispInfoA = ^TLVDispInfoA;
  TLVDispInfoA = packed record
    hdr: TNMHDR;
    Item: TLVItemA;
  end;
  PLVDispInfoW = ^TLVDispInfoW;
  TLVDispInfoW = packed record
    hdr: TNMHDR;
    Item: TLVItemW;
  end;
  PLVDispInfo = PLVDispInfoA;

const
  LVN_KEYDOWN                           = LVN_FIRST - 55;

type
  PLVKeyDown = ^TLVKeyDown;
  TLVKeyDown = packed record
    hdr: TNMHDR;
    wVKey: Word;
    Flags: UINT;
  end;

  { ====== TREEVIEW CONTROL =================== }

const
  WC_TREEVIEW                           = 'SysTreeView32';

const
  TVS_HASBUTTONS                        = $0001;
  TVS_HASLINES                          = $0002;
  TVS_LINESATROOT                       = $0004;
  TVS_EDITLABELS                        = $0008;
  TVS_DISABLEDRAGDROP                   = $0010;
  TVS_SHOWSELALWAYS                     = $0020;

type
  HTreeItem = ^_TreeItem;
  _TreeItem = packed record
  end;

const
  TVIF_TEXT                             = $0001;
  TVIF_IMAGE                            = $0002;
  TVIF_PARAM                            = $0004;
  TVIF_STATE                            = $0008;
  TVIF_HANDLE                           = $0010;
  TVIF_SELECTEDIMAGE                    = $0020;
  TVIF_CHILDREN                         = $0040;

  TVIS_FOCUSED                          = $0001;
  TVIS_SELECTED                         = $0002;
  TVIS_CUT                              = $0004;
  TVIS_DROPHILITED                      = $0008;
  TVIS_BOLD                             = $0010;
  TVIS_EXPANDED                         = $0020;
  TVIS_EXPANDEDONCE                     = $0040;
  TVIS_EXPANDPARTIAL                    = $0080;

  TVIS_OVERLAYMASK                      = $0F00;
  TVIS_STATEIMAGEMASK                   = $F000;
  TVIS_USERMASK                         = $F000;

const
  I_CHILDRENCALLBACK                    = -1;

type
  PTVItemA = ^TTVItemA;
  PTVItemW = ^TTVItemW;
  PTVItem = PTVItemA;
  TTVItemA = packed record
    Mask: UINT;
    hItem: HTreeItem;
    State: UINT;
    stateMask: UINT;
    pszText: PAnsiChar;
    cchTextMax: integer;
    iImage: integer;
    iSelectedImage: integer;
    cChildren: integer;
    lParam: lParam;
  end;
  TTVItemW = packed record
    Mask: UINT;
    hItem: HTreeItem;
    State: UINT;
    stateMask: UINT;
    pszText: PWideChar;
    cchTextMax: integer;
    iImage: integer;
    iSelectedImage: integer;
    cChildren: integer;
    lParam: lParam;
  end;
  TTVItem = TTVItemA;

const
  TVI_ROOT                              = HTreeItem($FFFF0000);
  TVI_FIRST                             = HTreeItem($FFFF0001);
  TVI_LAST                              = HTreeItem($FFFF0002);
  TVI_SORT                              = HTreeItem($FFFF0003);

type
  PTVInsertStructA = ^TTVInsertStructA;
  PTVInsertStructW = ^TTVInsertStructW;
  PTVInsertStruct = PTVInsertStructA;
  TTVInsertStructA = packed record
    hParent: HTreeItem;
    hInsertAfter: HTreeItem;
    Item: TTVItemA;
  end;
  TTVInsertStructW = packed record
    hParent: HTreeItem;
    hInsertAfter: HTreeItem;
    Item: TTVItemW;
  end;
  TTVInsertStruct = TTVInsertStructA;

const
  TVM_INSERTITEMA                       = TV_FIRST + 0;
  TVM_INSERTITEMW                       = TV_FIRST + 50;
  TVM_INSERTITEM                        = TVM_INSERTITEMA;

function TreeView_InsertItem(HWND: HWND; const lpis: TTVInsertStruct): HTreeItem;

const
  TVM_DELETEITEM                        = TV_FIRST + 1;

function TreeView_DeleteItem(HWND: HWND; hItem: HTreeItem): BOOL;

function TreeView_DeleteAllItems(HWND: HWND): BOOL;

const
  TVM_EXPAND                            = TV_FIRST + 2;

function TreeView_Expand(HWND: HWND; hItem: HTreeItem; code: integer): BOOL;

const
  TVE_COLLAPSE                          = $0001;
  TVE_EXPAND                            = $0002;
  TVE_TOGGLE                            = $0003;
  TVE_EXPANDPARTIAL                     = $4000;
  TVE_COLLAPSERESET                     = $8000;

const
  TVM_GETITEMRECT                       = TV_FIRST + 4;

function TreeView_GetItemRect(HWND: HWND; hItem: HTreeItem;
  var prc: TRect; code: BOOL): BOOL;

const
  TVM_GETCOUNT                          = TV_FIRST + 5;

function TreeView_GetCount(HWND: HWND): UINT;

const
  TVM_GETINDENT                         = TV_FIRST + 6;

function TreeView_GetIndent(HWND: HWND): UINT;

const
  TVM_SETINDENT                         = TV_FIRST + 7;

function TreeView_SetIndent(HWND: HWND; indent: integer): BOOL;

const
  TVM_GETIMAGELIST                      = TV_FIRST + 8;

function TreeView_GetImageList(HWND: HWND; iImage: integer): HImageList;

const
  TVSIL_NORMAL                          = 0;
  TVSIL_STATE                           = 2;

const
  TVM_SETIMAGELIST                      = TV_FIRST + 9;

function TreeView_SetImageList(HWND: HWND; himl: HImageList;
  iImage: integer): HImageList;

const
  TVM_GETNEXTITEM                       = TV_FIRST + 10;

function TreeView_GetNextItem(HWND: HWND; hItem: HTreeItem;
  code: integer): HTreeItem;

const
  TVGN_ROOT                             = $0000;
  TVGN_NEXT                             = $0001;
  TVGN_PREVIOUS                         = $0002;
  TVGN_PARENT                           = $0003;
  TVGN_CHILD                            = $0004;
  TVGN_FIRSTVISIBLE                     = $0005;
  TVGN_NEXTVISIBLE                      = $0006;
  TVGN_PREVIOUSVISIBLE                  = $0007;
  TVGN_DROPHILITE                       = $0008;
  TVGN_CARET                            = $0009;

function TreeView_GetChild(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_GetNextSibling(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_GetPrevSibling(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_GetParent(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_GetFirstVisible(HWND: HWND): HTreeItem;
function TreeView_GetNextVisible(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_GetPrevVisible(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_GetSelection(HWND: HWND): HTreeItem;
function TreeView_GetDropHilite(HWND: HWND): HTreeItem;
function TreeView_GetRoot(HWND: HWND): HTreeItem;

const
  TVM_SELECTITEM                        = TV_FIRST + 11;

function TreeView_Select(HWND: HWND; hItem: HTreeItem;
  code: integer): HTreeItem;

function TreeView_SelectItem(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_SelectDropTarget(HWND: HWND; hItem: HTreeItem): HTreeItem;
function TreeView_SelectSetFirstVisible(HWND: HWND; hItem: HTreeItem): HTreeItem;

const
  TVM_GETITEMA                          = TV_FIRST + 12;
  TVM_GETITEMW                          = TV_FIRST + 62;
  TVM_GETITEM                           = TVM_GETITEMA;

function TreeView_GetItemA(HWND: HWND; var pItem: TTVItemA): BOOL;
function TreeView_GetItemW(HWND: HWND; var pItem: TTVItemW): BOOL;
function TreeView_GetItem(HWND: HWND; var pItem: TTVItem): BOOL;

const
  TVM_SETITEMA                          = TV_FIRST + 13;
  TVM_SETITEMW                          = TV_FIRST + 63;
  TVM_SETITEM                           = TVM_SETITEMA;

function TreeView_SetItemA(HWND: HWND; const pItem: TTVItemA): BOOL;
function TreeView_SetItemW(HWND: HWND; const pItem: TTVItemW): BOOL;
function TreeView_SetItem(HWND: HWND; const pItem: TTVItem): BOOL;

const
  TVM_EDITLABELA                        = TV_FIRST + 14;
  TVM_EDITLABELW                        = TV_FIRST + 65;
  TVM_EDITLABEL                         = TVM_EDITLABELA;

function TreeView_EditLabelA(HWND: HWND; hItem: HTreeItem): HWND;
function TreeView_EditLabelW(HWND: HWND; hItem: HTreeItem): HWND;
function TreeView_EditLabel(HWND: HWND; hItem: HTreeItem): HWND;

const
  TVM_GETEDITCONTROL                    = TV_FIRST + 15;

function TreeView_GetEditControl(HWND: HWND): HWND;

const
  TVM_GETVISIBLECOUNT                   = TV_FIRST + 16;

function TreeView_GetVisibleCount(HWND: HWND): UINT;

const
  TVM_HITTEST                           = TV_FIRST + 17;

type
  PTVHitTestInfo = ^TTVHitTestInfo;
  TTVHitTestInfo = packed record
    Pt: TPoint;
    Flags: UINT;
    hItem: HTreeItem;
  end;

function TreeView_HitTest(HWND: HWND; var lpht: TTVHitTestInfo): HTreeItem;

const
  TVHT_NOWHERE                          = $0001;
  TVHT_ONITEMICON                       = $0002;
  TVHT_ONITEMLABEL                      = $0004;
  TVHT_ONITEMINDENT                     = $0008;
  TVHT_ONITEMBUTTON                     = $0010;
  TVHT_ONITEMRIGHT                      = $0020;
  TVHT_ONITEMSTATEICON                  = $0040;

  TVHT_ONITEM                           = TVHT_ONITEMICON or TVHT_ONITEMLABEL or
    TVHT_ONITEMSTATEICON;

  TVHT_ABOVE                            = $0100;
  TVHT_BELOW                            = $0200;
  TVHT_TORIGHT                          = $0400;
  TVHT_TOLEFT                           = $0800;

const
  TVM_CREATEDRAGIMAGE                   = TV_FIRST + 18;

function TreeView_CreateDragImage(HWND: HWND; hItem: HTreeItem): HImageList;

const
  TVM_SORTCHILDREN                      = TV_FIRST + 19;

function TreeView_SortChildren(HWND: HWND; hItem: HTreeItem;
  recurse: integer): BOOL;

const
  TVM_ENSUREVISIBLE                     = TV_FIRST + 20;

function TreeView_EnsureVisible(HWND: HWND; hItem: HTreeItem): BOOL;

const
  TVM_SORTCHILDRENCB                    = TV_FIRST + 21;

type
  TTVCompare = function(lParam1, lParam2, lParamSort: LONGINT): integer stdcall;

type
  TTVSortCB = packed record
    hParent: HTreeItem;
    lpfnCompare: TTVCompare;
    lParam: lParam;
  end;

function TreeView_SortChildrenCB(HWND: HWND; const psort: TTVSortCB;
  recurse: integer): BOOL;

const
  TVM_ENDEDITLABELNOW                   = TV_FIRST + 22;

function TreeView_EndEditLabelNow(HWND: HWND; fCancel: BOOL): BOOL;

const
  TVM_GETISEARCHSTRINGA                 = TV_FIRST + 23;
  TVM_GETISEARCHSTRINGW                 = TV_FIRST + 64;
  TVM_GETISEARCHSTRING                  = TVM_GETISEARCHSTRINGA;

function TreeView_GetISearchStringA(hwndTV: HWND; lpsz: PAnsiChar): BOOL;
function TreeView_GetISearchStringW(hwndTV: HWND; lpsz: PWideChar): BOOL;
function TreeView_GetISearchString(hwndTV: HWND; lpsz: PChar): BOOL;

type
  PNMTreeViewA = ^TNMTreeViewA;
  PNMTreeViewW = ^TNMTreeViewW;
  PNMTreeView = PNMTreeViewA;
  TNMTreeViewA = packed record
    hdr: TNMHDR;
    Action: UINT;
    itemOld: TTVItemA;
    itemNew: TTVItemA;
    ptDrag: TPoint;
  end;
  TNMTreeViewW = packed record
    hdr: TNMHDR;
    Action: UINT;
    itemOld: TTVItemW;
    itemNew: TTVItemW;
    ptDrag: TPoint;
  end;
  TNMTreeView = TNMTreeViewA;

const
  TVN_SELCHANGINGA                      = TVN_FIRST - 1;
  TVN_SELCHANGEDA                       = TVN_FIRST - 2;
  TVN_SELCHANGINGW                      = TVN_FIRST - 50;
  TVN_SELCHANGEDW                       = TVN_FIRST - 51;
  TVN_SELCHANGING                       = TVN_SELCHANGINGA;
  TVN_SELCHANGED                        = TVN_SELCHANGEDA;

const
  TVC_UNKNOWN                           = $0000;
  TVC_BYMOUSE                           = $0001;
  TVC_BYKEYBOARD                        = $0002;

const
  TVN_GETDISPINFOA                      = TVN_FIRST - 3;
  TVN_SETDISPINFOA                      = TVN_FIRST - 4;
  TVN_GETDISPINFOW                      = TVN_FIRST - 52;
  TVN_SETDISPINFOW                      = TVN_FIRST - 53;
  TVN_GETDISPINFO                       = TVN_GETDISPINFOA;
  TVN_SETDISPINFO                       = TVN_SETDISPINFOA;

  TVIF_DI_SETITEM                       = $1000;

type
  PTVDispInfoA = ^TTVDispInfoA;
  PTVDispInfoW = ^TTVDispInfoW;
  PTVDispInfo = PTVDispInfoA;
  TTVDispInfoA = packed record
    hdr: TNMHDR;
    Item: TTVItemA;
  end;
  TTVDispInfoW = packed record
    hdr: TNMHDR;
    Item: TTVItemW;
  end;
  TTVDispInfo = TTVDispInfoA;

const
  TVN_ITEMEXPANDINGA                    = TVN_FIRST - 5;
  TVN_ITEMEXPANDEDA                     = TVN_FIRST - 6;
  TVN_BEGINDRAGA                        = TVN_FIRST - 7;
  TVN_BEGINRDRAGA                       = TVN_FIRST - 8;
  TVN_DELETEITEMA                       = TVN_FIRST - 9;
  TVN_BEGINLABELEDITA                   = TVN_FIRST - 10;
  TVN_ENDLABELEDITA                     = TVN_FIRST - 11;
  TVN_ITEMEXPANDINGW                    = TVN_FIRST - 54;
  TVN_ITEMEXPANDEDW                     = TVN_FIRST - 55;
  TVN_BEGINDRAGW                        = TVN_FIRST - 56;
  TVN_BEGINRDRAGW                       = TVN_FIRST - 57;
  TVN_DELETEITEMW                       = TVN_FIRST - 58;
  TVN_BEGINLABELEDITW                   = TVN_FIRST - 59;
  TVN_ENDLABELEDITW                     = TVN_FIRST - 60;
  TVN_ITEMEXPANDING                     = TVN_ITEMEXPANDINGA;
  TVN_ITEMEXPANDED                      = TVN_ITEMEXPANDEDA;
  TVN_BEGINDRAG                         = TVN_BEGINDRAGA;
  TVN_BEGINRDRAG                        = TVN_BEGINRDRAGA;
  TVN_DELETEITEM                        = TVN_DELETEITEMA;
  TVN_BEGINLABELEDIT                    = TVN_BEGINLABELEDITA;
  TVN_ENDLABELEDIT                      = TVN_ENDLABELEDITA;

const
  TVN_KEYDOWN                           = TVN_FIRST - 12;

type
  TTVKeyDown = packed record
    hdr: TNMHDR;
    wVKey: Word;
    Flags: UINT;
  end;

  { ====== TAB CONTROL ======================== }

const
  WC_TABCONTROL                         = 'SysTabControl32';

const
  TCS_SCROLLOPPOSITE                    = $0001;
  TCS_BOTTOM                            = $0002;
  TCS_RIGHT                             = $0002;
  TCS_FORCEICONLEFT                     = $0010;
  TCS_FORCELABELLEFT                    = $0020;
  TCS_HOTTRACK                          = $0040;
  TCS_VERTICAL                          = $0080;
  TCS_TABS                              = $0000;
  TCS_BUTTONS                           = $0100;
  TCS_SINGLELINE                        = $0000;
  TCS_MULTILINE                         = $0200;
  TCS_RIGHTJUSTIFY                      = $0000;
  TCS_FIXEDWIDTH                        = $0400;
  TCS_RAGGEDRIGHT                       = $0800;
  TCS_FOCUSONBUTTONDOWN                 = $1000;
  TCS_OWNERDRAWFIXED                    = $2000;
  TCS_TOOLTIPS                          = $4000;
  TCS_FOCUSNEVER                        = $8000;

const
  TCM_GETIMAGELIST                      = TCM_FIRST + 2;
  TCM_SETIMAGELIST                      = TCM_FIRST + 3;
  TCM_GETITEMCOUNT                      = TCM_FIRST + 4;
  TCM_DELETEITEM                        = TCM_FIRST + 8;
  TCM_DELETEALLITEMS                    = TCM_FIRST + 9;
  TCM_GETITEMRECT                       = TCM_FIRST + 10;
  TCM_GETCURSEL                         = TCM_FIRST + 11;
  TCM_SETCURSEL                         = TCM_FIRST + 12;
  TCM_HITTEST                           = TCM_FIRST + 13;
  TCM_SETITEMEXTRA                      = TCM_FIRST + 14;
  TCM_ADJUSTRECT                        = TCM_FIRST + 40;
  TCM_SETITEMSIZE                       = TCM_FIRST + 41;
  TCM_REMOVEIMAGE                       = TCM_FIRST + 42;
  TCM_SETPADDING                        = TCM_FIRST + 43;
  TCM_GETROWCOUNT                       = TCM_FIRST + 44;
  TCM_GETTOOLTIPS                       = TCM_FIRST + 45;
  TCM_SETTOOLTIPS                       = TCM_FIRST + 46;
  TCM_GETCURFOCUS                       = TCM_FIRST + 47;
  TCM_SETCURFOCUS                       = TCM_FIRST + 48;

const
  TCIF_TEXT                             = $0001;
  TCIF_IMAGE                            = $0002;
  TCIF_RTLREADING                       = $0004;
  TCIF_PARAM                            = $0008;

type
  PTCItemHeaderA = ^TTCItemHeaderA;
  PTCItemHeaderW = ^TTCItemHeaderW;
  PTCItemHeader = PTCItemHeaderA;
  TTCItemHeaderA = packed record
    Mask: UINT;
    lpReserved1: UINT;
    lpReserved2: UINT;
    pszText: PAnsiChar;
    cchTextMax: integer;
    iImage: integer;
  end;
  TTCItemHeaderW = packed record
    Mask: UINT;
    lpReserved1: UINT;
    lpReserved2: UINT;
    pszText: PWideChar;
    cchTextMax: integer;
    iImage: integer;
  end;
  TTCItemHeader = TTCItemHeaderA;

  PTCItemA = ^TTCItemA;
  PTCItemW = ^TTCItemW;
  PTCItem = PTCItemA;
  TTCItemA = packed record
    Mask: UINT;
    lpReserved1: UINT;
    lpReserved2: UINT;
    pszText: PAnsiChar;
    cchTextMax: integer;
    iImage: integer;
    lParam: lParam;
  end;
  TTCItemW = packed record
    Mask: UINT;
    lpReserved1: UINT;
    lpReserved2: UINT;
    pszText: PWideChar;
    cchTextMax: integer;
    iImage: integer;
    lParam: lParam;
  end;
  TTCItem = TTCItemA;

const
  TCM_GETITEMA                          = TCM_FIRST + 5;
  TCM_SETITEMA                          = TCM_FIRST + 6;
  TCM_INSERTITEMA                       = TCM_FIRST + 7;
  TCM_GETITEMW                          = TCM_FIRST + 60;
  TCM_SETITEMW                          = TCM_FIRST + 61;
  TCM_INSERTITEMW                       = TCM_FIRST + 62;
  TCM_GETITEM                           = TCM_GETITEMA;
  TCM_SETITEM                           = TCM_SETITEMA;
  TCM_INSERTITEM                        = TCM_INSERTITEMA;

const
  TCHT_NOWHERE                          = $0001;
  TCHT_ONITEMICON                       = $0002;
  TCHT_ONITEMLABEL                      = $0004;
  TCHT_ONITEM                           = TCHT_ONITEMICON or TCHT_ONITEMLABEL;

type
  PTCHitTestInfo = ^TTCHitTestInfo;
  TTCHitTestInfo = packed record
    Pt: TPoint;
    Flags: UINT;
  end;

  TTCKeyDown = packed record
    hdr: TNMHDR;
    wVKey: Word;
    Flags: UINT;
  end;

const
  TCN_KEYDOWN                           = TCN_FIRST - 0;
  TCN_SELCHANGE                         = TCN_FIRST - 1;
  TCN_SELCHANGING                       = TCN_FIRST - 2;

  { ====== ANIMATE CONTROL ================= }

const
  ANIMATE_CLASS                         = 'SysAnimate32';

const
  ACS_CENTER                            = $0001;
  ACS_TRANSPARENT                       = $0002;
  ACS_AUTOPLAY                          = $0004;
  ACS_TIMER                             = $0008; { don't use threads... use timers }

  ACM_OPENA                             = WM_USER + 100;
  ACM_OPENW                             = WM_USER + 103;
  ACM_OPEN                              = ACM_OPENA;

  ACM_PLAY                              = WM_USER + 101;
  ACM_STOP                              = WM_USER + 102;

  ACN_START                             = 1;
  ACN_STOP                              = 2;

  { ====== MONTHCAL CONTROL ========= }

const
  MONTHCAL_CLASS                        = 'SysMonthCal32';

  // Message constants
  MCM_FIRST                             = $1000;
  MCM_GETCURSEL                         = MCM_FIRST + 1;
  MCM_SETCURSEL                         = MCM_FIRST + 2;
  MCM_GETMAXSELCOUNT                    = MCM_FIRST + 3;
  MCM_SETMAXSELCOUNT                    = MCM_FIRST + 4;
  MCM_GETSELRANGE                       = MCM_FIRST + 5;
  MCM_SETSELRANGE                       = MCM_FIRST + 6;
  MCM_GETMONTHRANGE                     = MCM_FIRST + 7;
  MCM_SETDAYSTATE                       = MCM_FIRST + 8;
  MCM_GETMINREQRECT                     = MCM_FIRST + 9;
  MCM_SETCOLOR                          = MCM_FIRST + 10;
  MCM_GETCOLOR                          = MCM_FIRST + 11;
  MCM_SETTODAY                          = MCM_FIRST + 12;
  MCM_GETTODAY                          = MCM_FIRST + 13;
  MCM_HITTEST                           = MCM_FIRST + 14;
  MCM_SETFIRSTDAYOFWEEK                 = MCM_FIRST + 15;
  MCM_GETFIRSTDAYOFWEEK                 = MCM_FIRST + 16;
  MCM_GETRANGE                          = MCM_FIRST + 17;
  MCM_SETRANGE                          = MCM_FIRST + 18;
  MCM_GETMONTHDELTA                     = MCM_FIRST + 19;
  MCM_SETMONTHDELTA                     = MCM_FIRST + 20;

  // Hit test flags
  MCHT_TITLE                            = $00010000;
  MCHT_CALENDAR                         = $00020000;
  MCHT_TODAYLINK                        = $00030000;
  MCHT_NEXT                             = $01000000; // these indicate that hitting
  MCHT_PREV                             = $02000000; // here will go to the next/prev month
  MCHT_NOWHERE                          = $00000000;
  MCHT_TITLEBK                          = MCHT_TITLE;
  MCHT_TITLEMONTH                       = MCHT_TITLE or $0001;
  MCHT_TITLEYEAR                        = MCHT_TITLE or $0002;
  MCHT_TITLEBTNNEXT                     = MCHT_TITLE or MCHT_NEXT or $0003;
  MCHT_TITLEBTNPREV                     = MCHT_TITLE or MCHT_PREV or $0003;
  MCHT_CALENDARBK                       = MCHT_CALENDAR;
  MCHT_CALENDARDATE                     = MCHT_CALENDAR or $0001;
  MCHT_CALENDARDATENEXT                 = MCHT_CALENDARDATE or MCHT_NEXT;
  MCHT_CALENDARDATEPREV                 = MCHT_CALENDARDATE or MCHT_PREV;
  MCHT_CALENDARDAY                      = MCHT_CALENDAR or $0002;
  MCHT_CALENDARWEEKNUM                  = MCHT_CALENDAR or $0003;

  // Color codes
  MCSC_BACKGROUND                       = 0; // the background color (between months)
  MCSC_TEXT                             = 1; // the dates
  MCSC_TITLEBK                          = 2; // background of the title
  MCSC_TITLETEXT                        = 3;
  MCSC_MONTHBK                          = 4; // background within the month cal
  MCSC_TRAILINGTEXT                     = 5; // the text color of header & trailing days

  // Notification codes
  MCN_SELCHANGE                         = MCN_FIRST + 1;
  MCN_GETDAYSTATE                       = MCN_FIRST + 3;
  MCN_SELECT                            = MCN_FIRST + 4;

  // Style flags
  MCS_DAYSTATE                          = $0001;
  MCS_MULTISELECT                       = $0002;
  MCS_WEEKNUMBERS                       = $0004;
  MCS_NOTODAY                           = $0008;

  GMR_VISIBLE                           = 0; // visible portion of display
  GMR_DAYSTATE                          = 1; // above plus the grayed out parts of
  // partially displayed months

type
  // bit-packed array of "bold" info for a month
  // if a bit is on, that day is drawn bold
  PMonthDayState = ^TMonthDayState;
  TMonthDayState = DWORD;

  PMCHitTestInfo = ^TMCHitTestInfo;
  TMCHitTestInfo = packed record
    cbSize: UINT;
    Pt: TPoint;
    uHit: UINT; // out param
    St: TSystemTime;
  end;

  // MCN_SELCHANGE is sent whenever the currently displayed date changes
  // via month change, year change, keyboard navigation, prev/next button
  PNMSelChange = ^TNMSelChange;
  TNMSelChange = packed record
    NMHdr: TNMHDR; // this must be first, so we don't break WM_NOTIFY
    stSelStart: TSystemTime;
    stSelEnd: TSystemTime;
  end;

  // MCN_GETDAYSTATE is sent for MCS_DAYSTATE controls whenever new daystate
  // information is needed (month or year scroll) to draw bolding information.
  // The app must fill in cDayState months worth of information starting from
  // stStart date. The app may fill in the array at prgDayState or change
  // prgDayState to point to a different array out of which the information
  // will be copied. (similar to tooltips)
  PNMDayState = ^TNMDayState;
  TNMDayState = packed record
    NMHdr: TNMHDR; // this must be first, so we don't break WM_NOTIFY
    stStart: TSystemTime;
    cDayState: integer;
    prgDayState: PMonthDayState; // points to cDayState TMONTHDAYSTATEs
  end;

  // MCN_SELECT is sent whenever a selection has occured (via mouse or keyboard)
  PNMSelect = ^TNMSelect;
  TNMSelect = TNMSelChange;

  //   returns FALSE if MCS_MULTISELECT
  //   returns TRUE and sets *pst to the currently selected date otherwise
function MonthCal_GetCurSel(hmc: HWND; var pst: TSystemTime): BOOL;

//   returns FALSE if MCS_MULTISELECT
//   returns TURE and sets the currently selected date to *pst otherwise
function MonthCal_SetCurSel(hmc: HWND; const pst: TSystemTime): BOOL;

//   returns the maximum number of selectable days allowed
function MonthCal_GetMaxSelCount(hmc: HWND): DWORD;

//   sets the max number days that can be selected iff MCS_MULTISELECT
function MonthCal_SetMaxSelCount(hmc: HWND; n: UINT): BOOL;

//   sets rgst[0] to the first day of the selection range
//   sets rgst[1] to the last day of the selection range
function MonthCal_GetSelRange(hmc: HWND; rgst: PSystemTime): BOOL;

//   selects the range of days from rgst[0] to rgst[1]
function MonthCal_SetSelRange(hmc: HWND; rgst: PSystemTime): BOOL;

//   if rgst specified, sets rgst[0] to the starting date and
//      and rgst[1] to the ending date of the the selectable (non-grayed)
//      days if GMR_VISIBLE or all the displayed days (including grayed)
//      if GMR_DAYSTATE.
//   returns the number of months spanned by the above range.
function MonthCal_GetMonthRange(hmc: HWND; gmr: DWORD; rgst: PSystemTime): DWORD;

//   cbds is the count of DAYSTATE items in rgds and it must be equal
//   to the value returned from MonthCal_GetMonthRange(hmc, GMR_DAYSTATE, NULL)
//   This sets the DAYSTATE bits for each month (grayed and non-grayed
//   days) displayed in the calendar. The first bit in a month's DAYSTATE
//   corresponts to bolding day 1, the second bit affects day 2, etc.
function MonthCal_SetDayState(hmc: HWND; cbds: integer; const rgds: TNMDayState): BOOL;

//   sets prc the minimal size needed to display one month
function MonthCal_GetMinReqRect(hmc: HWND; var prc: TRect): BOOL;

// set what day is "today"   send NULL to revert back to real date
function MonthCal_SetToday(hmc: HWND; const pst: TSystemTime): BOOL;

// get what day is "today"
// returns BOOL for success/failure
function MonthCal_GetToday(hmc: HWND; var pst: TSystemTime): BOOL;

// determine what pinfo->pt is over
function MonthCal_HitTest(hmc: HWND; var Info: TMCHitTestInfo): DWORD;

// set colors to draw control with -- see MCSC_ bits below
function MonthCal_SetColor(hmc: HWND; iColor: integer; clr: TColorRef): BOOL;

function MonthCal_GetColor(hmc: HWND; iColor: integer): TColorRef;

// set first day of week to iDay:
// 0 for Monday, 1 for Tuesday, ..., 6 for Sunday
// -1 for means use locale info
function MonthCal_SetFirstDayOfWeek(hmc: HWND; iDay: integer): BOOL;

// DWORD result...  low word has the day.  high word is bool if this is app set
// or not (FALSE == using locale info)
function MonthCal_GetFirstDayOfWeek(hmc: HWND): integer;

//   modifies rgst[0] to be the minimum ALLOWABLE systemtime (or 0 if no minimum)
//   modifies rgst[1] to be the maximum ALLOWABLE systemtime (or 0 if no maximum)
//   returns GDTR_MIN|GDTR_MAX if there is a minimum|maximum limit
function MonthCal_GetRange(hmc: HWND; rgst: PSystemTime): DWORD;

//   if GDTR_MIN, sets the minimum ALLOWABLE systemtime to rgst[0], otherwise removes minimum
//   if GDTR_MAX, sets the maximum ALLOWABLE systemtime to rgst[1], otherwise removes maximum
//   returns TRUE on success, FALSE on error (such as invalid parameters)
function Monthcal_SetRange(hmc: HWND; gdtr: DWORD; rgst: PSystemTime): BOOL;

//   returns the number of months one click on a next/prev button moves by
function MonthCal_GetMonthDelta(hmc: HWND): integer;

//   sets the month delta to n. n = 0 reverts to moving by a page of months
//   returns the previous value of n.
function MonthCal_SetMonthDelta(hmc: HWND; n: integer): integer;

{ ====== DATETIMEPICK CONTROL =============== }

const
  DATETIMEPICK_CLASS                    = 'SysDateTimePick32';

  // Message constants
  DTM_FIRST                             = $1000;
  DTM_GETSYSTEMTIME                     = DTM_FIRST + 1;
  DTM_SETSYSTEMTIME                     = DTM_FIRST + 2;
  DTM_GETRANGE                          = DTM_FIRST + 3;
  DTM_SETRANGE                          = DTM_FIRST + 4;
  DTM_SETFORMATA                        = DTM_FIRST + 5;
  DTM_SETFORMATW                        = DTM_FIRST + 50;
  DTM_SETFORMAT                         = DTM_SETFORMATA;
  DTM_SETMCCOLOR                        = DTM_FIRST + 6;
  DTM_GETMCCOLOR                        = DTM_FIRST + 7;
  DTM_GETMONTHCAL                       = DTM_FIRST + 8;
  DTM_SETMCFONT                         = DTM_FIRST + 9;
  DTM_GETMCFONT                         = DTM_FIRST + 10;

  // Style Flags
  DTS_UPDOWN                            = $0001; // use UPDOWN instead of MONTHCAL
  DTS_SHOWNONE                          = $0002; // allow a NONE selection
  DTS_SHORTDATEFORMAT                   = $0000; // use the short date format
  // (app must forward WM_WININICHANGE messages)
  DTS_LONGDATEFORMAT                    = $0004; // use the long date format
  // (app must forward WM_WININICHANGE messages)
  DTS_TIMEFORMAT                        = $0009; // use the time format
  // (app must forward WM_WININICHANGE messages)
  DTS_APPCANPARSE                       = $0010; // allow user entered strings
  // (app MUST respond to DTN_USERSTRING)
  DTS_RIGHTALIGN                        = $0020; // right-align popup instead of left-align it

  // Notification codes
  DTN_DATETIMECHANGE                    = DTN_FIRST + 1; // the systemtime has changed
  DTN_USERSTRINGA                       = DTN_FIRST + 2; // the user has entered a string
  DTN_USERSTRINGW                       = DTN_FIRST + 15;
  DTN_USERSTRING                        = DTN_USERSTRINGA;
  DTN_WMKEYDOWNA                        = DTN_FIRST + 3; // modify keydown on app format field (X)
  DTN_WMKEYDOWNW                        = DTN_FIRST + 16;
  DTN_WMKEYDOWN                         = DTN_WMKEYDOWNA;
  DTN_FORMATA                           = DTN_FIRST + 4; // query display for app format field (X)
  DTN_FORMATW                           = DTN_FIRST + 17;
  DTN_FORMAT                            = DTN_FORMATA;
  DTN_FORMATQUERYA                      = DTN_FIRST + 5; // query formatting info for app format field (X)
  DTN_FORMATQUERYW                      = DTN_FIRST + 18;
  DTN_FORMATQUERY                       = DTN_FORMATQUERYA;
  DTN_DROPDOWN                          = DTN_FIRST + 6; // MonthCal has dropped down
  DTN_CLOSEUP                           = DTN_FIRST + 7; // MonthCal is popping up

  // Ranges
  GDTR_MIN                              = $0001;
  GDTR_MAX                              = $0002;

  // Return Values
  GDT_ERROR                             = -1;
  GDT_VALID                             = 0;
  GDT_NONE                              = 1;

type
  PNMDateTimeChange = ^TNMDateTimeChange;
  TNMDateTimeChange = packed record
    NMHdr: TNMHDR;
    dwFlags: DWORD; // GDT_VALID or GDT_NONE
    St: TSystemTime; // valid iff dwFlags = GDT_VALID
  end;

  PNMDateTimeStringA = ^TNMDateTimeStringA;
  PNMDateTimeStringW = ^TNMDateTimeStringW;
  PNMDateTimeString = PNMDateTimeStringA;
  TNMDateTimeStringA = packed record
    NMHdr: TNMHDR;
    pszUserString: PAnsiChar; // string user entered
    St: TSystemTime; // app fills this in
    dwFlags: DWORD; // GDT_VALID or GDT_NONE
  end;
  TNMDateTimeStringW = packed record
    NMHdr: TNMHDR;
    pszUserString: PWideChar; // string user entered
    St: TSystemTime; // app fills this in
    dwFlags: DWORD; // GDT_VALID or GDT_NONE
  end;
  TNMDateTimeString = TNMDateTimeStringA;

  PNMDateTimeWMKeyDownA = ^TNMDateTimeWMKeyDownA;
  PNMDateTimeWMKeyDownW = ^TNMDateTimeWMKeyDownW;
  PNMDateTimeWMKeyDown = PNMDateTimeWMKeyDownA;
  TNMDateTimeWMKeyDownA = packed record
    NMHdr: TNMHDR;
    nVirtKey: integer; // virtual key code of WM_KEYDOWN which MODIFIES an X field
    pszFormat: PAnsiChar; // format substring
    St: TSystemTime; // current systemtime, app should modify based on key
  end;
  TNMDateTimeWMKeyDownW = packed record
    NMHdr: TNMHDR;
    nVirtKey: integer; // virtual key code of WM_KEYDOWN which MODIFIES an X field
    pszFormat: PWideChar; // format substring
    St: TSystemTime; // current systemtime, app should modify based on key
  end;
  TNMDateTimeWMKeyDown = TNMDateTimeWMKeyDownA;

  PNMDateTimeFormatA = ^TNMDateTimeFormatA;
  PNMDateTimeFormatW = ^TNMDateTimeFormatW;
  PNMDateTimeFormat = PNMDateTimeFormatA;
  TNMDateTimeFormatA = packed record
    NMHdr: TNMHDR;
    pszFormat: PAnsiChar; // format substring
    St: TSystemTime; // current systemtime
    pszDisplay: PAnsiChar; // string to display
    szDisplay: array[0..63] of AnsiChar; // buffer pszDisplay originally points at
  end;
  TNMDateTimeFormatW = packed record
    NMHdr: TNMHDR;
    pszFormat: PWideChar; // format substring
    St: TSystemTime; // current systemtime
    pszDisplay: PWideChar; // string to display
    szDisplay: array[0..63] of widechar; // buffer pszDisplay originally points at
  end;
  TNMDateTimeFormat = TNMDateTimeFormatA;

  PNMDateTimeFormatQueryA = ^TNMDateTimeFormatQueryA;
  PNMDateTimeFormatQueryW = ^TNMDateTimeFormatQueryW;
  PNMDateTimeFormatQuery = PNMDateTimeFormatQueryA;
  TNMDateTimeFormatQueryA = packed record
    NMHdr: TNMHDR;
    pszFormat: PAnsiChar; // format substring
    szMax: TSIZE; // max bounding rectangle app will use for this format string
  end;
  TNMDateTimeFormatQueryW = packed record
    NMHdr: TNMHDR;
    pszFormat: PWideChar; // format substring
    szMax: TSIZE; // max bounding rectangle app will use for this format string
  end;
  TNMDateTimeFormatQuery = TNMDateTimeFormatQueryA;

  //   returns GDT_NONE if "none" is selected (DTS_SHOWNONE only)
  //   returns GDT_VALID and modifies pst to be the currently selected value
function DateTime_GetSystemTime(HDP: HWND; var pst: TSystemTime): DWORD;

//   if gd = GDT_NONE, sets datetimepick to None (DTS_SHOWNONE only)
//   if gd = GDT_VALID, sets datetimepick to pst
//   returns TRUE on success, FALSE on error (such as bad params)
function DateTime_SetSystemTime(HDP: HWND; gd: DWORD; const pst: TSystemTime): BOOL;

//   modifies rgst[0] to be the minimum ALLOWABLE systemtime (or 0 if no minimum)
//   modifies rgst[1] to be the maximum ALLOWABLE systemtime (or 0 if no maximum)
//   returns GDTR_MIN or GDTR_MAX if there is a minimum or maximum limit
function DateTime_GetRange(HDP: HWND; rgst: PSystemTime): DWORD;

//   if GDTR_MIN, sets the minimum ALLOWABLE systemtime to rgst[0], otherwise removes minimum
//   if GDTR_MAX, sets the maximum ALLOWABLE systemtime to rgst[1], otherwise removes maximum
//   returns TRUE on success, FALSE on error (such as invalid parameters)
function DateTime_SetRange(HDP: HWND; gdtr: DWORD; rgst: PSystemTime): BOOL;

//   sets the display formatting string to sz (see GetDateFormat and GetTimeFormat for valid formatting chars)
//   NOTE: 'X' is a valid formatting character which indicates that the application
//   will determine how to display information. Such apps must support DTN_WMKEYDOWN,
//   DTN_FORMAT, and DTN_FORMATQUERY.
function DateTime_SetFormatA(HDP: HWND; sz: PAnsiChar): BOOL;
function DateTime_SetFormatW(HDP: HWND; sz: PWideChar): BOOL;
function DateTime_SetFormat(HDP: HWND; sz: PChar): BOOL;

function DateTime_SetMonthCalColor(HDP: HWND; iColor: DWORD; clr: TColorRef): DWORD;

function DateTime_GetMonthCalColor(HDP: HWND; iColor: DWORD): TColorRef;

// returns the HWND of the MonthCal popup window. Only valid
// between DTN_DROPDOWN and DTN_CLOSEUP notifications.
function DateTime_GetMonthCal(HDP: HWND): HWND;

function DateTime_SetMonthCalFont(HDP: HWND; Font: HFONT; fRedraw: boolean): DWORD;

function DateTime_GetMonthCalFont(HDP: HWND): HFONT;

{  ====================== IP Address edit control ============================= }

const
  WC_IPADDRESS                          = 'SysIPAddress32';

  // Messages sent to IPAddress controls
  IPM_CLEARADDRESS                      = WM_USER + 100; { no parameters }
  IPM_SETADDRESS                        = WM_USER + 101; { lparam = TCP/IP address }
  IPM_GETADDRESS                        = WM_USER + 102; { lresult = # of non black fields.  lparam = LPDWORD for TCP/IP address }
  IPM_SETRANGE                          = WM_USER + 103; { wparam = field, lparam = range }
  IPM_SETFOCUS                          = WM_USER + 104; { wparam = field }
  IPM_ISBLANK                           = WM_USER + 105; { no parameters }
  IPN_FIELDCHANGED                      = IPN_FIRST - 0;

type
  tagNMIPADDRESS = packed record
    hdr: PNMHdr;
    iField: integer;
    iValue: integer;
  end;
  PNMIPAddress = ^TNMIPAddress;
  TNMIPAddress = tagNMIPADDRESS;

  { The following is a useful macro for passing the range values in the }
  { IPM_SETRANGE message. }
function MAKEIPRANGE(Low, High: Byte): lParam;

{ And this is a useful macro for making the IP Address to be passed }
{ as a LPARAM. }
function MAKEIPADDRESS(B1, B2, b3, b4: DWORD): lParam;

{ Get individual number }
function FIRST_IPADDRESS(X: DWORD): DWORD;
function SECOND_IPADDRESS(X: DWORD): DWORD;
function THIRD_IPADDRESS(X: DWORD): DWORD;
function FOURTH_IPADDRESS(X: DWORD): DWORD;

{  ====================== Pager Control ============================= }

const
  { Pager Class Name }
  WC_PAGESCROLLER                       = 'SysPager';

  { Pager Control Styles }
  PGS_VERT                              = $00000000;
  PGS_HORZ                              = $00000001;
  PGS_AUTOSCROLL                        = $00000002;
  PGS_DRAGNDROP                         = $00000004;

  { Pager Button State }
  { The scroll can be in one of the following control State }
  PGF_INVISIBLE                         = 0; { Scroll button is not visible }
  PGF_NORMAL                            = 1; { Scroll button is in normal state }
  PGF_GRAYED                            = 2; { Scroll button is in grayed state }
  PGF_DEPRESSED                         = 4; { Scroll button is in depressed state }
  PGF_HOT                               = 8; { Scroll button is in hot state }

  { The following identifiers specifies the button control }
  PGB_TOPORLEFT                         = 0;
  PGB_BOTTOMORRIGHT                     = 1;

  { Pager Control  Messages }
  PGM_SETCHILD                          = PGM_FIRST + 1; { lParam == hwnd }
  PGM_RECALCSIZE                        = PGM_FIRST + 2;
  PGM_FORWARDMOUSE                      = PGM_FIRST + 3;
  PGM_SETBKCOLOR                        = PGM_FIRST + 4;
  PGM_GETBKCOLOR                        = PGM_FIRST + 5;
  PGM_SETBORDER                         = PGM_FIRST + 6;
  PGM_GETBORDER                         = PGM_FIRST + 7;
  PGM_SETPOS                            = PGM_FIRST + 8;
  PGM_GETPOS                            = PGM_FIRST + 9;
  PGM_SETBUTTONSIZE                     = PGM_FIRST + 10;
  PGM_GETBUTTONSIZE                     = PGM_FIRST + 11;
  PGM_GETBUTTONSTATE                    = PGM_FIRST + 12;
  PGM_GETDROPTARGET                     = CCM_GETDROPTARGET;
procedure Pager_SetChild(HWND: HWND; hwndChild: HWND);
procedure Pager_RecalcSize(HWND: HWND);
procedure Pager_ForwardMouse(HWND: HWND; bForward: BOOL);
function Pager_SetBkColor(HWND: HWND; clr: COLORREF): COLORREF;
function Pager_GetBkColor(HWND: HWND): COLORREF;
function Pager_SetBorder(HWND: HWND; iBorder: integer): integer;
function Pager_GetBorder(HWND: HWND): integer;
function Pager_SetPos(HWND: HWND; iPos: integer): integer;
function Pager_GetPos(HWND: HWND): integer;
function Pager_SetButtonSize(HWND: HWND; iSize: integer): integer;
function Pager_GetButtonSize(HWND: HWND): integer;
function Pager_GetButtonState(HWND: HWND; iButton: integer): DWORD;
procedure Pager_GetDropTarget(HWND: HWND; ppdt: Pointer {!!});

const
  { Pager Control Notification Messages }

  { PGN_SCROLL Notification Message }
  PGN_SCROLL                            = PGN_FIRST - 1;
  PGF_SCROLLUP                          = 1;
  PGF_SCROLLDOWN                        = 2;
  PGF_SCROLLLEFT                        = 4;
  PGF_SCROLLRIGHT                       = 8;

  { Keys down }
  PGK_SHIFT                             = 1;
  PGK_CONTROL                           = 2;
  PGK_MENU                              = 4;

type
  { This structure is sent along with PGN_SCROLL notifications }
  NMPGSCROLL = packed record
    hdr: PNMHdr;
    fwKeys: Word; { Specifies which keys are down when this notification is send }
    rcParent: TRect; { Contains Parent Window Rect }
    iDir: integer; { Scrolling Direction }
    iXpos: integer; { Horizontal scroll position }
    iYpos: integer; { Vertical scroll position }
    iScroll: integer; { [in/out] Amount to scroll }
  end;
  PNMPGScroll = ^TNMPGScroll;
  TNMPGScroll = NMPGSCROLL;

const
  { PGN_CALCSIZE Notification Message }
  PGN_CALCSIZE                          = PGN_FIRST - 2;
  PGF_CALCWIDTH                         = 1;
  PGF_CALCHEIGHT                        = 2;

type
  NMPGCALCSIZE = packed record
    hdr: PNMHdr;
    dwFlag: DWORD;
    iWidth: integer;
    iHeight: integer;
  end;
  PNMPGCalcSize = ^TNMPGCalcSize;
  TNMPGCalcSize = NMPGCALCSIZE;

  { ======================  Native Font Control ============================== }

const
  WC_NATIVEFONTCTL                      = 'NativeFontCtl';

  { style definition }
  NFS_EDIT                              = $0001;
  NFS_STATIC                            = $0002;
  NFS_LISTCOMBO                         = $0004;
  NFS_BUTTON                            = $0008;
  NFS_ALL                               = $0010;

  { ====== TrackMouseEvent  ================================================== }

const
  WM_MOUSEHOVER                         = $02A1;
  WM_MOUSELEAVE                         = $02A3;
  TME_HOVER                             = $00000001;
  TME_LEAVE                             = $00000002;
  TME_QUERY                             = $40000000;
  TME_CANCEL                            = $80000000;
  HOVER_DEFAULT                         = $FFFFFFFF;

type
  tagTRACKMOUSEEVENT = packed record
    cbSize: DWORD;
    dwFlags: DWORD;
    hwndTrack: HWND;
    dwHoverTime: DWORD;
  end;

  PTrackMouseEvent = ^TTrackMouseEvent;
  TTrackMouseEvent = tagTRACKMOUSEEVENT;

  PFNDSAENUMCALLBACK = function(p: Pointer; pData: Pointer): integer stdcall;

  { Declare _TrackMouseEvent.  This API tries to use the window manager's }
  { implementation of TrackMouseEvent if it is present, otherwise it emulates. }
function _TrackMouseEvent(lpEventTrack: PTrackMouseEvent): BOOL; stdcall;

{ ====== Flat Scrollbar APIs========================================= }

const
  WSB_PROP_CYVSCROLL                    = $00000001;
  WSB_PROP_CXHSCROLL                    = $00000002;
  WSB_PROP_CYHSCROLL                    = $00000004;
  WSB_PROP_CXVSCROLL                    = $00000008;
  WSB_PROP_CXHTHUMB                     = $00000010;
  WSB_PROP_CYVTHUMB                     = $00000020;
  WSB_PROP_VBKGCOLOR                    = $00000040;
  WSB_PROP_HBKGCOLOR                    = $00000080;
  WSB_PROP_VSTYLE                       = $00000100;
  WSB_PROP_HSTYLE                       = $00000200;
  WSB_PROP_WINSTYLE                     = $00000400;
  WSB_PROP_PALETTE                      = $00000800;
  WSB_PROP_MASK                         = $00000FFF;
  FSB_FLAT_MODE                         = 2;
  FSB_ENCARTA_MODE                      = 1;
  FSB_REGULAR_MODE                      = 0;
function FlatSB_EnableScrollBar(HWND: HWND; wSBflags, wArrows: UINT): BOOL; stdcall;
function FlatSB_ShowScrollBar(HWND: HWND; wBar: integer; bShow: BOOL): BOOL; stdcall;
function FlatSB_GetScrollRange(HWND: HWND; nBar: integer; var lpMinPos,
  lpMaxPos: integer): BOOL; stdcall;
function FlatSB_GetScrollInfo(HWND: HWND; BarFlag: integer;
  var ScrollInfo: TScrollInfo): BOOL; stdcall;
function FlatSB_GetScrollPos(HWND: HWND; nBar: integer): integer; stdcall;
function FlatSB_GetScrollProp(P1: HWND; propIndex: integer;
  p3: PInteger): BOOL; stdcall;
function FlatSB_SetScrollPos(HWND: HWND; nBar, nPos: integer;
  bRedraw: BOOL): integer; stdcall;
function FlatSB_SetScrollInfo(HWND: HWND; BarFlag: integer;
  const ScrollInfo: TScrollInfo; Redraw: BOOL): integer; stdcall;
function FlatSB_SetScrollRange(HWND: HWND; nBar, nMinPos, nMaxPos: integer;
  bRedraw: BOOL): BOOL; stdcall;
function FlatSB_SetScrollProp(P1: HWND; Index: integer; newValue: integer;
  p4: BOOL): BOOL; stdcall;
function InitializeFlatSB(HWND: HWND): BOOL; stdcall;
procedure UninitializeFlatSB(HWND: HWND); stdcall;

//function ListView_GetItemName(hListView: HWND): string;

function DSA_Clone(hdsa: HDSA): HDSA; stdcall;
{
Duplicates a dynamic structure array (DSA).
The clone consists of a copy of the structures stored in the original DSA.
Subsequent changes to the original DSA do not affect the clone.
}

function DSA_Create(cbItem: integer; cbItemGrow: integer): HDSA; stdcall;
{cbItem - The size, in bytes, of the item.}
{cbItemGrow - The number of items by which the array should be incremented, if the DSA needs to be enlarged.}

function DSA_DeleteAllItems(hdsa: HDSA): BOOL; stdcall;

function DSA_DeleteItem(hdsa: HDSA; nPosition: integer): BOOL; stdcall;
{
Deletes an item from a dynamic structure array (DSA).

hdsa
[in] A handle to an existing DSA.
nPosition
[in] The zero-based index of the item to delete.

Note  DSA_DeleteItem is available through Windows XP Service Pack 2 (SP2). It might be altered or unavailable in subsequent versions.
DSA_DeleteItem is not exported by name or declared in a public header file.
To use it, you must use GetProcAddress and request ordinal 326 from ComCtl32.dll to obtain a function pointer.
}

function DSA_Destroy(hdsa: HDSA): BOOL; stdcall;
{
Frees a dynamic structure array (DSA).
Parameters

pdsa
[in] A handle to a DSA to destroy.
Return Value

Returns TRUE on success, FALSE on failure.

Remarks

Note  This function is available through Windows XP Service Pack 2 (SP2) and Microsoft Windows Server 2003. It might be altered or unavailable in subsequent versions of Windows.
}

function DSA_DestroyCallback(hdsa: HDSA; pfnCB: PFNDSAENUMCALLBACK; pData: Pointer): BOOL; stdcall;
{
Iterates through a dynamic structure array (DSA), calling a specified callback function on each item. Upon reaching the end of the array, the DSA is freed.

pdsa
[in] A handle to a DSA to walk and destroy.
pfnCB
[in] A callback function pointer. For the callback function prototype, see PFNDSAENUMCALLBACK.
pData
[in]  A callback data pointer. This pointer is, in turn, passed as a parameter to pfnCB.
Return Value

No return value.

Remarks

Note  This function is available through Windows XP Service Pack 2 (SP2) and Microsoft Windows Server 2003. It might be altered or unavailable in subsequent versions of Windows.
}

procedure DSA_EnumCallback(hdsa: HDSA; pfnCB: PFNDSAENUMCALLBACK; pData: Pointer); stdcall;
{
Iterates through the dynamic structure array (DSA) and calls pfnCB on each item.
hdsa
[in] A handle to an existing DSA.
pfnCB
[in] A callback function pointer. See PFNDSAENUMCALLBACK for the callback function prototype.
pData
[in] A callback data pointer. pData is passed as a parameter to pfnCB.
}

function DSA_GetItem(hdsa: HDSA; Index: integer; pItem: Pointer): BOOL; stdcall;
{
pdsa
[in] A handle to the DSA containing the element.
index
[in] The index of the element to be retrieved (zero-based).
pitem
[out] A pointer to a buffer which is filled with a copy of the specified element of the DSA.
Return Value

Returns TRUE if successful or FALSE otherwise.

Remarks

DSA_GetItem is not exported by name. To use it, you must use GetProcAddress and request ordinal 322 from ComCtl32.dll to obtain a function pointer.

Using the element pointer that this function retrieves, you can modify the data in that element directly. However, be aware that a subsequent insert or destroy operation could cause this pointer value to become invalid or to point to a different element.
}

function DSA_GetItemPtr(hdsa: HDSA; Index: integer): Pointer; stdcall;
{
Gets a pointer to an element from a dynamic structure array (DSA).
pdsa
[in] A handle to the DSA containing the element.
index
[in] The index of the element to be retrieved (zero-based).
Return Value

Returns a pointer to the specified element or NULL if the call fails.

Remarks

Note  This function is available through Windows XP Service Pack 2 (SP2) and Microsoft Windows Server 2003. It might be altered or unavailable in subsequent versions of Windows.
Using the element pointer that this function returns, you can modify the data in that element directly. However, be aware that a subsequent insert or destroy operation could cause this pointer value to become invalid or to point to a different element.
}

function DSA_GetSize(hdsa: HDSA): Cardinal; stdcall;
{
!Windows Vista
Gets the size of the dynamic structure array (DSA).
Returns the size of the DSA, including the internal bookkeeping information, in bytes. If hdsa is NULL, the function returns zero.
}

function DSA_InsertItem(hdsa: HDSA; Index: integer; pItem: Pointer): integer; stdcall;
{
Inserts a new item into a dynamic structure array (DSA).
If necessary, the DSA expands to accommodate the new item.
pdsa
[in] A handle to the DSA in which to insert the item.
index
[in] The position in the DSA where new item is to be inserted, or DSA_APPEND to insert the item at the end of the array.
pItem
[in] A pointer to the item that is to be inserted.
Return Value

Returns the index of the new item if the insertion succeeds, or DSA_ERR (-1) if the insertion fails.

Remarks

Note  This function is available through Windows XP Service Pack 2 (SP2) and Microsoft Windows Server 2003. It might be altered or unavailable in subsequent versions of Windows.
The actual data pointed to by pItem is copied into the DSA. Subsequent actions performed on that item do not affect the original copy.

}

function DSA_SetItem(hdsa: HDSA; Index: integer; pItem: Pointer): BOOL; stdcall;
{
Sets the contents of an element in a dynamic structure array (DSA).
hdsa
[in] A handle to an existing DSA that contains the element.
index
[in] The zero-based index of the item to set.
pItem
[in] A pointer to the item that will replace the specified item in the array.
Return Value

TRUE if successful; otherwise, FALSE.

Remarks

Note  DSA_SetItem is available through Windows XP Service Pack 2 (SP2). It might be altered or unavailable in subsequent versions.
DSA_SetItem is not exported by name or declared in a public header file. To use it, you must use GetProcAddress and request ordinal 325 from ComCtl32.dll to obtain a function pointer.
}

function DSA_Sort(hdsa: HDSA; pfnCompare: PFNLVGROUPCOMPARE; lParam: lParam): BOOL; stdcall;
{
!Windows Vista
Defines the prototype for the compare function used by DPA_Sort and DPA_Search.
p1
A pointer to the first item in the comparison.
p2
A pointer to the second item in the comparison.
lParam
Additional data passed to pfnCmp.
Return Value

The meaning of the return values depends on the function that uses this callback prototype.

The return values for DPA_Sort are as follows.
less than 0	If p1 should be sorted ahead of p2.
equal to 0	If p1 and p2 should be sorted together.
greater than 0	If p1 should be sorted after p2.
The return values for DPA_Search are as follows.

less than 0	If p1 should be found ahead of p2.
equal to zero	If p1 and p2 should be found together.
greater than 0	If p1 should be found after p2.
Remarks

As of Windows Vista, this function is merely an alias for PFNDACOMPARE.
}

implementation

const
  cctrl                                 = 'comctl32.dll';

var
  ComCtl32DLL                           : THandle;
  _InitCommonControlsEx                 : function(var ICC: TInitCommonControlsEx): BOOL stdcall;

procedure InitCommonControls; external cctrl Name 'InitCommonControls';

procedure initcomctl;
begin
  if ComCtl32DLL = 0 then
  begin
    ComCtl32DLL := GetModuleHandle(cctrl);
    if { (ComCtl32DLL >= 0) and}(ComCtl32DLL < 32) then
      ComCtl32DLL := 0
    else
      @_InitCommonControlsEx := GetProcAddress(ComCtl32DLL, 'InitCommonControlsEx');
  end;
end;

function INITCOMMONCONTROLSEX(var ICC: TInitCommonControlsEx): BOOL;
begin
  if ComCtl32DLL = 0 then initcomctl;
  Result := Assigned(_InitCommonControlsEx) and _InitCommonControlsEx(ICC);
end;

{ Property Sheets }
function CreatePropertySheetPageA; external cctrl Name 'CreatePropertySheetPageA';
function CreatePropertySheetPageW; external cctrl Name 'CreatePropertySheetPageW';
function CreatePropertySheetPage; external cctrl Name 'CreatePropertySheetPageA';
function DestroyPropertySheetPage; external cctrl Name 'DestroyPropertySheetPage';
function PropertySheetA; external cctrl Name 'PropertySheetA';
function PropertySheetW; external cctrl Name 'PropertySheetW';
function PropertySheet; external cctrl Name 'PropertySheetA';

function PropSheet_SetCurSel(hDlg: HWND; hpage: HPropSheetPage;
  Index: integer): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_SETCURSEL, wParam(Index), lParam(hpage)));
end;

function PropSheet_RemovePage(hDlg: HWND; Index: integer;
  hpage: HPropSheetPage): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_REMOVEPAGE, Index, lParam(hpage)));
end;

function PropSheet_AddPage(hDlg: HWND; hpage: HPropSheetPage): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_ADDPAGE, 0, lParam(hpage)));
end;

function PropSheet_Changed(hDlg: HWND; hwndPage: HWND): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_CHANGED, hwndPage, 0));
end;

procedure PropSheet_RestartWindows(hDlg: HWND);
begin
  SendMessage(hDlg, PSM_RESTARTWINDOWS, 0, 0);
end;

procedure PropSheet_RebootSystem(hDlg: HWND);
begin
  SendMessage(hDlg, PSM_REBOOTSYSTEM, 0, 0);
end;

procedure PropSheet_CancelToClose(hDlg: HWND);
begin
  PostMessage(hDlg, PSM_CANCELTOCLOSE, 0, 0)
end;

function PropSheet_QuerySiblings(hDlg: HWND; wp: wParam; lp: lParam):
  integer;
begin
  Result := SendMessage(hDlg, PSM_QUERYSIBLINGS, wp, lp);
end;

procedure PropSheet_UnChanged(hDlg: HWND; hwndPage: HWND);
begin
  SendMessage(hDlg, PSM_UNCHANGED, wParam(hwndPage), 0);
end;

function PropSheet_Apply(hDlg: HWND): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_APPLY, 0, 0));
end;

procedure PropSheet_SetTitle(hPropSheetDlg: HWND; dwStyle: DWORD; lpszText: string);
begin
  SendMessage(hPropSheetDlg, PSM_SETTITLE, dwStyle, lParam(lpszText));
end;

procedure PropSheet_SetWizButtons(hDlg: HWND; dwFlags: DWORD);
begin
  PostMessage(hDlg, PSM_SETWIZBUTTONS, 0, lParam(dwFlags));
end;

function PropSheet_PressButton(hDlg: HWND; iButton: integer): BOOL;
begin
  Result := BOOL(PostMessage(hDlg, PSM_PRESSBUTTON, wParam(iButton), 0));
end;

function PropSheet_SetCurSelByID(hDlg: HWND; ID: integer): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_SETCURSELID, 0, lParam(ID)));
end;

procedure PropSheet_SetFinishText(hDlg: HWND; lpszText: string);
begin
  SendMessage(hDlg, PSM_SETFINISHTEXT, 0, lParam(lpszText));
end;

function PropSheet_GetTabControl(hDlg: HWND): HWND;
begin
  Result := HWND(SendMessage(hDlg, PSM_GETTABCONTROL, 0, 0));
end;

function PropSheet_IsDialogMessage(hDlg: HWND; pMsg: TMsg): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_ISDIALOGMESSAGE, 0, lParam(@pMsg)));
end;

function PropSheet_GetCurrentPageHwnd(hDlg: HWND): HWND;
begin
  Result := HWND(SendMessage(hDlg, PSM_GETCURRENTPAGEHWND, 0, 0));
end;

function PropSheet_InsertPage(hDlg: HWND; Index: integer; hpage: HPropSheetPage): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_INSERTPAGE, wParam(Index), lParam(hpage)));
end;

function PropSheet_SetHeaderTitle(hDlg: HWND; Index: integer; lpszText: string): integer;
begin
  Result := SendMessage(hDlg, PSM_SETHEADERTITLE, wParam(Index), lParam(lpszText));
end;

procedure PropSheet_SetHeaderSubTitle(hDlg: HWND; Index: integer; lpszText: LPCSTR);
begin
  SendMessage(hDlg, PSM_SETHEADERSUBTITLE, wParam(Index), lParam(lpszText));
end;

function PropSheet_HwndToIndex(hDlg, hwndPage: HWND): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_HWNDTOINDEX, wParam(hwndPage), 0));
end;

function PropSheet_IndexToHwnd(hDlg: HWND; i: integer): HWND;
begin
  Result := HWND(SendMessage(hDlg, PSM_INDEXTOHWND, wParam(i), 0));
end;

function PropSheet_PageToIndex(hDlg: HWND; hpage: HPropSheetPage): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_PAGETOINDEX, 0, lParam(hpage)));
end;

function PropSheet_IndexToPage(hDlg: HWND; i: integer): HPropSheetPage;
begin
  Result := HPropSheetPage(SendMessage(hDlg, PSM_INDEXTOPAGE, wParam(i), 0));
end;

function PropSheet_IdToIndex(hDlg: HWND; ID: integer): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_IDTOINDEX, 0, lParam(ID)));
end;

function PropSheet_IndexToId(hDlg: HWND; i: integer): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_INDEXTOID, wParam(i), 0));
end;

function PropSheet_GetResult(hDlg: HWND): integer;
begin
  Result := integer(SendMessage(hDlg, PSM_GETRESULT, 0, 0));
end;

function PropSheet_RecalcPageSizes(hDlg: HWND): BOOL;
begin
  Result := BOOL(SendMessage(hDlg, PSM_RECALCPAGESIZES, 0, 0));
end;

{ Image List }
function ImageList_Create; external cctrl Name 'ImageList_Create';
function ImageList_Destroy; external cctrl Name 'ImageList_Destroy';
function ImageList_GetImageCount; external cctrl Name 'ImageList_GetImageCount';
function ImageList_Add; external cctrl Name 'ImageList_Add';
function ImageList_ReplaceIcon; external cctrl Name 'ImageList_ReplaceIcon';
function ImageList_SetBkColor; external cctrl Name 'ImageList_SetBkColor';
function ImageList_GetBkColor; external cctrl Name 'ImageList_GetBkColor';
function ImageList_SetOverlayImage; external cctrl Name 'ImageList_SetOverlayImage';

function ImageList_AddIcon(ImageList: HImageList; Icon: HICON): integer;
begin
  Result := ImageList_ReplaceIcon(ImageList, -1, Icon);
end;

function IndexToOverlayMask(Index: integer): integer;
begin
  Result := Index shl 8;
end;

function ImageList_Draw; external cctrl Name 'ImageList_Draw';

function ImageList_Replace; external cctrl Name 'ImageList_Replace';
function ImageList_AddMasked; external cctrl Name 'ImageList_AddMasked';
function ImageList_DrawEx; external cctrl Name 'ImageList_DrawEx';
function ImageList_Remove; external cctrl Name 'ImageList_Remove';
function ImageList_GetIcon; external cctrl Name 'ImageList_GetIcon';
function ImageList_LoadImageA; external cctrl Name 'ImageList_LoadImageA';
function ImageList_LoadImageW; external cctrl Name 'ImageList_LoadImageW';
function ImageList_LoadImage; external cctrl Name 'ImageList_LoadImageA';
function ImageList_BeginDrag; external cctrl Name 'ImageList_BeginDrag';
function ImageList_EndDrag; external cctrl Name 'ImageList_EndDrag';
function ImageList_DragEnter; external cctrl Name 'ImageList_DragEnter';
function ImageList_DragLeave; external cctrl Name 'ImageList_DragLeave';
function ImageList_DragMove; external cctrl Name 'ImageList_DragMove';
function ImageList_SetDragCursorImage; external cctrl Name 'ImageList_SetDragCursorImage';
function ImageList_DragShowNoLock; external cctrl Name 'ImageList_DragShowNolock';
function ImageList_GetDragImage; external cctrl Name 'ImageList_GetDragImage';

{ macros }

procedure ImageList_RemoveAll(ImageList: HImageList);
begin
  ImageList_Remove(ImageList, -1);
end;

function ImageList_ExtractIcon(Instance: THandle; ImageList: HImageList;
  Image: integer): HICON;
begin
  Result := ImageList_GetIcon(ImageList, Image, 0);
end;

function ImageList_LoadBitmap(Instance: THandle; BMP: PChar;
  cx, Grow: integer; Mask: TColorRef): HImageList;
begin
  Result := ImageList_LoadImage(Instance, BMP, cx, Grow, Mask,
    IMAGE_BITMAP, 0);
end;

//function ImageList_Read; external cctrl name 'ImageList_Read';
//function ImageList_Write; external cctrl name 'ImageList_Write';

function ImageList_GetIconSize; external cctrl Name 'ImageList_GetIconSize';
function ImageList_SetIconSize; external cctrl Name 'ImageList_SetIconSize';
function ImageList_GetImageInfo; external cctrl Name 'ImageList_GetImageInfo';
function ImageList_Merge; external cctrl Name 'ImageList_Merge';

{ Headers }

function Header_GetItemCount(Header: HWND): integer;
begin
  Result := SendMessage(Header, HDM_GETITEMCOUNT, 0, 0);
end;

function Header_InsertItem(Header: HWND; Index: integer;
  const Item: THDItem): integer;
begin
  Result := SendMessage(Header, HDM_INSERTITEM, Index, LONGINT(@Item));
end;

function Header_DeleteItem(Header: HWND; Index: integer): BOOL;
begin
  Result := BOOL(SendMessage(Header, HDM_DELETEITEM, Index, 0));
end;

function Header_GetItem(Header: HWND; Index: integer; var Item: THDItem): BOOL;
begin
  Result := BOOL(SendMessage(Header, HDM_GETITEM, Index, LONGINT(@Item)));
end;

function Header_SetItem(Header: HWND; Index: integer; const Item: THDItem): BOOL;
begin
  Result := BOOL(SendMessage(Header, HDM_SETITEM, Index, LONGINT(@Item)));
end;

function Header_Layout(Header: HWND; Layout: PHDLayout): BOOL;
begin
  Result := BOOL(SendMessage(Header, HDM_LAYOUT, 0, LONGINT(Layout)));
end;

{ Toolbar }

function CreateToolBarEx; external cctrl Name 'CreateToolbarEx';
function CreateMappedBitmap; external cctrl Name 'CreateMappedBitmap';

{ Status bar }
procedure DrawStatusTextA; external cctrl Name 'DrawStatusTextA';
procedure DrawStatusTextW; external cctrl Name 'DrawStatusTextW';
procedure DrawStatusText; external cctrl Name 'DrawStatusTextA';
function CreateStatusWindowA; external cctrl Name 'CreateStatusWindowA';
function CreateStatusWindowW; external cctrl Name 'CreateStatusWindowW';
function CreateStatusWindow; external cctrl Name 'CreateStatusWindowA';

{ Menu Help }
procedure MenuHelp; external cctrl Name 'MenuHelp';
function ShowHideMenuCtl; external cctrl Name 'ShowHideMenuCtl';
procedure GetEffectiveClientRect; external cctrl Name 'GetEffectiveClientRect';

{ Drag List Box }
procedure MakeDragList; external cctrl Name 'MakeDragList';
procedure DrawInsert; external cctrl Name 'DrawInsert';
function LBItemFromPt; external cctrl Name 'LBItemFromPt';

{ UpDown control }
function CreateUpDownControl; external cctrl Name 'CreateUpDownControl';

{ List View }

function ListView_GetBkColor(HWND: HWND): TColorRef;
begin
  Result := SendMessage(HWND, LVM_GETBKCOLOR, 0, 0);
end;

function ListView_SetBkColor(HWND: HWND; ClrBk: TColorRef): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETBKCOLOR, 0, ClrBk));
end;

function ListView_GetImageList(HWND: HWND; iImageList: integer): HImageList;
begin
  Result := HImageList(SendMessage(HWND, LVM_GETIMAGELIST, iImageList, 0));
end;

function ListView_SetImageList(HWND: HWND; himl: HImageList; iImageList: integer): HImageList;
begin
  Result := HImageList(SendMessage(HWND, LVM_SETIMAGELIST, iImageList, LONGINT(himl)));
end;

function ListView_GetItemCount(HWND: HWND): integer;
begin
  Result := SendMessage(HWND, LVM_GETITEMCOUNT, 0, 0);
end;

function IndexToStateImageMask(i: LONGINT): LONGINT;
begin
  Result := i shl 12;
end;

function ListView_IsGroupViewEnabled(wnd: HWND): BOOL;
begin
  Result := BOOL(SendMessage(wnd, LVM_ISGROUPVIEWENABLED, 0, 0));
end;

function ListView_GetOutlineColor(wnd: HWND): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd, LVM_GETOUTLINECOLOR, 0, 0));
end;

function ListView_GetItemA(HWND: HWND; var pItem: TLVItemA): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_GETITEM, 0, LONGINT(@pItem)));
end;

function ListView_GetItemW(HWND: HWND; var pItem: TLVItemW): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_GETITEM, 0, LONGINT(@pItem)));
end;

function ListView_GetItem(HWND: HWND; var pItem: TLVItem): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_GETITEM, 0, LONGINT(@pItem)));
end;

function ListView_SetItemA(HWND: HWND; const pItem: TLVItemA): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETITEM, 0, LONGINT(@pItem)));
end;

function ListView_SetItemW(HWND: HWND; const pItem: TLVItemW): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETITEM, 0, LONGINT(@pItem)));
end;

function ListView_SetItem(HWND: HWND; const pItem: TLVItem): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETITEM, 0, LONGINT(@pItem)));
end;

function ListView_SetInsertMark(wnd: HWND; lvim: TLVInsertMark): BOOL;
begin
  Result := BOOL(SendMessage(wnd, LVM_SETINSERTMARK, 0, lParam(@lvim)));
end;

function ListView_GetInsertMark(wnd: HWND; var lvim: TLVInsertMark): BOOL;
begin
  Result := BOOL(SendMessage(wnd, LVM_GETINSERTMARK, 0, lParam(@lvim)));
end;

function ListView_InsertMarkHitTest(wnd: HWND; Point: TPoint; lvim: TLVInsertMark): integer;
begin
  Result := integer(SendMessage(wnd, LVM_INSERTMARKHITTEST,
    wParam(@Point), lParam(@lvim)));
end;

function ListView_GetInsertMarkRect(wnd: HWND; var RC: TRect): integer;
begin
  Result := integer(SendMessage(wnd, LVM_GETINSERTMARKRECT, 0, lParam(@RC)));
end;

function ListView_SetInsertMarkColor(wnd: HWND; Color: COLORREF): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd, LVM_SETINSERTMARKCOLOR, 0, Color));
end;

function ListView_GetInsertMarkColor(wnd: HWND): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd, LVM_GETINSERTMARKCOLOR, 0, 0));
end;

function ListView_InsertItemA(HWND: HWND; const pItem: TLVItemA): integer;
begin
  Result := integer(SendMessage(HWND, LVM_INSERTITEM, 0, LONGINT(@pItem)));
end;

function ListView_InsertItemW(HWND: HWND; const pItem: TLVItemW): integer;
begin
  Result := integer(SendMessage(HWND, LVM_INSERTITEM, 0, LONGINT(@pItem)));
end;

function ListView_InsertItem(HWND: HWND; const pItem: TLVItem): integer;
begin
  Result := integer(SendMessage(HWND, LVM_INSERTITEM, 0, LONGINT(@pItem)));
end;

function ListView_DeleteItem(HWND: HWND; i: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_DELETEITEM, i, 0));
end;

procedure ListView_SetSelectedColumn(wnd: HWND; iCol: integer);
begin
  SendMessage(wnd, LVM_SETSELECTEDCOLUMN, wParam(iCol), 0);
end;

function ListView_DeleteAllItems(HWND: HWND): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_DELETEALLITEMS, 0, 0));
end;

function ListView_SetExtendedListViewStyleEx(hwndLV: HWND; dwMask, dw: DWORD): DWORD;
begin
  Result := DWORD(SendMessage(hwndLV, LVM_SETEXTENDEDLISTVIEWSTYLE, dwMask, dw));
end;

function ListView_GetCallbackMask(HWND: HWND): UINT;
begin
  Result := SendMessage(HWND, LVM_GETCALLBACKMASK, 0, 0);
end;

function ListView_SetCallbackMask(HWND: HWND; Mask: UINT): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETCALLBACKMASK, Mask, 0));
end;

function ListView_GetNextItem(HWND: HWND; iStart: integer; Flags: UINT): integer;
begin
  Result := SendMessage(HWND, LVM_GETNEXTITEM, iStart, MakeLong(Flags, 0));
end;

function ListView_InsertGroup(wnd: HWND; Index: integer; pgrp: TLVGroup): integer;
begin
  Result := integer(SendMessage(wnd, LVM_INSERTGROUP, Index, lParam(@pgrp)));
end;

function ListView_SetGroupInfo(wnd: HWND; iGroupId: integer; pgrp: TLVGroup): integer;
begin
  Result := integer(SendMessage(wnd, LVM_SETGROUPINFO, iGroupId, lParam(@pgrp)));
end;

function ListView_GetGroupInfo(wnd: HWND; iGroupId: integer; var pgrp: TLVGroup): integer;
begin
  Result := integer(SendMessage(wnd, LVM_GETGROUPINFO, wParam(iGroupId), lParam(@pgrp)));
end;

function ListView_RemoveGroup(wnd: HWND; iGroupId: integer): integer;
begin
  Result := integer(SendMessage(wnd, LVM_REMOVEGROUP, wParam(iGroupId), 0));
end;

procedure ListView_MoveGroup(wnd: HWND; iGroupId, toIndex: integer);
begin
  SendMessage(wnd, LVM_MOVEGROUP, wParam(iGroupId), lParam(toIndex));
end;

procedure ListView_MoveItemToGroup(wnd: HWND; idItemFrom, idGroupTo: integer);
begin
  SendMessage(wnd, LVM_MOVEITEMTOGROUP, wParam(idItemFrom), lParam(idGroupTo));
end;

procedure ListView_SetGroupMetrics(wnd: HWND; pGroupMetrics: TLVGroupMetrics);
begin
  SendMessage(wnd, LVM_SETGROUPMETRICS, 0, lParam(@pGroupMetrics));
end;

procedure ListView_GetGroupMetrics(wnd: HWND; var pGroupMetrics: TLVGroupMetrics);
begin
  SendMessage(wnd, LVM_GETGROUPMETRICS, 0, lParam(@pGroupMetrics));
end;

function ListView_EnableGroupView(wnd: HWND; fEnable: BOOL): integer;
begin
  Result := integer(SendMessage(wnd, LVM_ENABLEGROUPVIEW, wParam(fEnable), 0));
end;

function ListView_SortGroups(wnd: HWND; fnGroupCompare: TLVGroupCompare; plv: Pointer): integer;
begin
  Result := integer(SendMessage(wnd, LVM_SORTGROUPS, wParam(@fnGroupCompare), lParam(plv)));
end;

procedure ListView_InsertGroupSorted(wnd: HWND; structInsert: TVLInsertGroupSorted);
begin
  SendMessage(wnd, LVM_INSERTGROUPSORTED, wParam(@structInsert), 0);
end;

procedure ListView_RemoveAllGroups(wnd: HWND);
begin
  SendMessage(wnd, LVM_REMOVEALLGROUPS, 0, 0);
end;

function ListView_HasGroup(wnd: HWND; dwGroupId: DWORD): BOOL;
begin
  Result := BOOL(SendMessage(wnd, LVM_HASGROUP, wParam(dwGroupId), 0));
end;

function ListView_FindItemA(HWND: HWND; iStart: integer;
  const plvfi: TLVFindInfoA): integer;
begin
  Result := SendMessage(HWND, LVM_FINDITEM, iStart, LONGINT(@plvfi));
end;

function ListView_FindItemW(HWND: HWND; iStart: integer;
  const plvfi: TLVFindInfoW): integer;
begin
  Result := SendMessage(HWND, LVM_FINDITEM, iStart, LONGINT(@plvfi));
end;

function ListView_FindItem(HWND: HWND; iStart: integer; const plvfi: TLVFindInfo): integer;
begin
  Result := SendMessage(HWND, LVM_FINDITEM, iStart, LONGINT(@plvfi));
end;

function ListView_GetItemRect(HWND: HWND; i: integer; var prc: TRect;
  code: integer): BOOL;
begin
  if @prc <> nil then
  begin
    prc.Left := code;
    Result := BOOL(SendMessage(HWND, LVM_GETITEMRECT, i, LONGINT(@prc)));
  end
  else
    Result := BOOL(SendMessage(HWND, LVM_GETITEMRECT, i, 0));
end;

function ListView_SetItemPosition(HWND: HWND; i, X, Y: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETITEMPOSITION, i, MakeLong(X, Y)));
end;

function ListView_GetItemPosition(hwndLV: HWND; i: integer;
  var ppt: TPoint): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_GETITEMPOSITION, i, LONGINT(@ppt)));
end;

function ListView_SetOutlineColor(wnd: HWND; Color: COLORREF): COLORREF;
begin
  Result := COLORREF(SendMessage(wnd, LVM_SETOUTLINECOLOR, 0, Color));
end;

procedure ListView_CancelEditLabel(wnd: HWND);
begin
  SendMessage(wnd, LVM_CANCELEDITLABEL, 0, 0);
end;

function ListView_GetStringWidthA(hwndLV: HWND; psz: PAnsiChar): integer;
begin
  Result := SendMessage(hwndLV, LVM_GETSTRINGWIDTH, 0, LONGINT(psz));
end;

function ListView_GetStringWidthW(hwndLV: HWND; psz: PWideChar): integer;
begin
  Result := SendMessage(hwndLV, LVM_GETSTRINGWIDTH, 0, LONGINT(psz));
end;

function ListView_GetStringWidth(hwndLV: HWND; psz: PChar): integer;
begin
  Result := SendMessage(hwndLV, LVM_GETSTRINGWIDTH, 0, LONGINT(psz));
end;

function ListView_HitTest(hwndLV: HWND; var pinfo: TLVHitTestInfo): integer;
begin
  Result := SendMessage(hwndLV, LVM_HITTEST, 0, LONGINT(@pinfo));
end;

function ListView_EnsureVisible(hwndLV: HWND; i: integer; fPartialOK: BOOL): BOOL;
begin
  //  RESULT := SendMessage(hwndLV, LVM_ENSUREVISIBLE, i, MakeLong(integer(fPartialOK), 0)) <> 0;
  Result := SendMessage(hwndLV, LVM_ENSUREVISIBLE, i, integer(fPartialOK)) <> 0;
end;

function ListView_Scroll(hwndLV: HWND; DX, DY: integer): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_SCROLL, DX, DY));
end;

function ListView_RedrawItems(hwndLV: HWND; iFirst, iLast: integer): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_REDRAWITEMS, iFirst, iLast));
end;

function ListView_Arrange(hwndLV: HWND; code: UINT): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_ARRANGE, code, 0));
end;

function ListView_EditLabelA(hwndLV: HWND; i: integer): HWND;
begin
  Result := HWND(SendMessage(hwndLV, LVM_EDITLABEL, i, 0));
end;

function ListView_EditLabelW(hwndLV: HWND; i: integer): HWND;
begin
  Result := HWND(SendMessage(hwndLV, LVM_EDITLABEL, i, 0));
end;

function ListView_EditLabel(hwndLV: HWND; i: integer): HWND;
begin
  Result := HWND(SendMessage(hwndLV, LVM_EDITLABEL, i, 0));
end;

function ListView_GetEditControl(hwndLV: HWND): HWND;
begin
  Result := HWND(SendMessage(hwndLV, LVM_GETEDITCONTROL, 0, 0));
end;

function ListView_GetColumnA(HWND: HWND; iCol: integer; var pcol: TLVColumnA): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_GETCOLUMN, iCol, LONGINT(@pcol)));
end;

function ListView_GetColumnW(HWND: HWND; iCol: integer; var pcol: TLVColumnW): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_GETCOLUMN, iCol, LONGINT(@pcol)));
end;

function ListView_GetColumn(HWND: HWND; iCol: integer; var pcol: TLVColumn): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_GETCOLUMN, iCol, LONGINT(@pcol)));
end;

function ListView_SetView(wnd: HWND; iView: DWORD): DWORD;
begin
  Result := DWORD(SendMessage(wnd, LVM_SETVIEW, wParam(iView), 0));
end;

function ListView_GetView(wnd: HWND): DWORD;
begin
  Result := DWORD(SendMessage(wnd, LVM_GETVIEW, 0, 0));
end;

function ListView_SetTileViewInfo(wnd: HWND; ptvi: TLVTileViewInfo): BOOL;
begin
  Result := BOOL(SendMessage(wnd, LVM_SETTILEVIEWINFO, 0, lParam(@ptvi)));
end;

procedure ListView_GetTileViewInfo(wnd: HWND; var ptvi: TLVTileViewInfo);
begin
  SendMessage(wnd, LVM_GETTILEVIEWINFO, 0, lParam(@ptvi));
end;

function ListView_SetTileInfo(wnd: HWND; pti: TLVTileInfo): BOOL;
begin
  Result := BOOL(SendMessage(wnd, LVM_SETTILEINFO, 0, lParam(@pti)));
end;

procedure ListView_GetTileInfo(wnd: HWND; var pti: TLVTileInfo);
begin
  SendMessage(wnd, LVM_GETTILEINFO, 0, lParam(@pti));
end;

function ListView_SetColumnA(HWND: HWND; iCol: integer; const pcol: TLVColumnA): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETCOLUMN, iCol, LONGINT(@pcol)));
end;

function ListView_SetColumnW(HWND: HWND; iCol: integer; const pcol: TLVColumnW): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETCOLUMN, iCol, LONGINT(@pcol)));
end;

function ListView_SetColumn(HWND: HWND; iCol: integer; const pcol: TLVColumn): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETCOLUMN, iCol, LONGINT(@pcol)));
end;

function ListView_InsertColumnA(HWND: HWND; iCol: integer; const pcol: TLVColumnA): integer;
begin
  Result := SendMessage(HWND, LVM_INSERTCOLUMN, iCol, LONGINT(@pcol));
end;

function ListView_InsertColumnW(HWND: HWND; iCol: integer; const pcol: TLVColumnW): integer;
begin
  Result := SendMessage(HWND, LVM_INSERTCOLUMN, iCol, LONGINT(@pcol));
end;

function ListView_InsertColumn(HWND: HWND; iCol: integer; const pcol: TLVColumn): integer;
begin
  Result := SendMessage(HWND, LVM_INSERTCOLUMN, iCol, LONGINT(@pcol));
end;

function ListView_DeleteColumn(HWND: HWND; iCol: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_DELETECOLUMN, iCol, 0));
end;

function ListView_GetColumnWidth(HWND: HWND; iCol: integer): integer;
begin
  Result := integer(SendMessage(HWND, LVM_GETCOLUMNWIDTH, iCol, 0));
end;

function ListView_SetColumnWidth(HWND: HWND; iCol: integer; cx: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETCOLUMNWIDTH, iCol, cx {MakeLong((cx), 0)}));
end;

function ListView_CreateDragImage(HWND: HWND; i: integer;
  const lpptUpLeft: TPoint): HImageList;
begin
  Result := HImageList(SendMessage(HWND, LVM_CREATEDRAGIMAGE, i,
    LONGINT(@lpptUpLeft)));
end;

function ListView_GetViewRect(HWND: HWND; var prc: TRect): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_GETVIEWRECT, 0, LONGINT(@prc)));
end;

function ListView_GetTextColor(HWND: HWND): TColorRef;
begin
  Result := SendMessage(HWND, LVM_GETTEXTCOLOR, 0, 0);
end;

function ListView_SetTextColor(HWND: HWND; clrText: TColorRef): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETTEXTCOLOR, 0, clrText));
end;

function ListView_GetTextBkColor(HWND: HWND): TColorRef;
begin
  Result := SendMessage(HWND, LVM_GETTEXTBKCOLOR, 0, 0);
end;

function ListView_SetTextBkColor(HWND: HWND; clrTextBk: TColorRef): BOOL;
begin
  Result := BOOL(SendMessage(HWND, LVM_SETTEXTBKCOLOR, 0, clrTextBk));
end;

function ListView_GetTopIndex(hwndLV: HWND): integer;
begin
  Result := SendMessage(hwndLV, LVM_GETTOPINDEX, 0, 0);
end;

function ListView_GetCountPerPage(hwndLV: HWND): integer;
begin
  Result := SendMessage(hwndLV, LVM_GETCOUNTPERPAGE, 0, 0);
end;

function ListView_GetOrigin(hwndLV: HWND; var ppt: TPoint): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_GETORIGIN, 0, LONGINT(@ppt)));
end;

function ListView_Update(hwndLV: HWND; i: integer): BOOL;
begin
  Result := SendMessage(hwndLV, LVM_UPDATE, i, 0) <> 0;
end;

function ListView_SetItemState(hwndLV: HWND; i: integer; data, Mask: UINT): BOOL;
var
  Item                                  : TLVItem;
begin
  Item.stateMask := Mask;
  Item.State := data;
  Result := BOOL(SendMessage(hwndLV, LVM_SETITEMSTATE, i, LONGINT(@Item)));
end;

function ListView_GetItemState(hwndLV: HWND; i, Mask: integer): integer;
begin
  Result := SendMessage(hwndLV, LVM_GETITEMSTATE, i, Mask);
end;

function ListView_GetCheckState(hwndLV: HWND; i: integer): UINT;
begin
  Result := (SendMessage(hwndLV, LVM_GETITEMSTATE, i, LVIS_STATEIMAGEMASK) shr 12) - 1;
end;

procedure ListView_SetCheckState(hwndLV: HWND; i: integer; Checked: boolean);
var
  Item                                  : TLVItem;
begin
  Item.stateMask := LVIS_STATEIMAGEMASK;
  Item.State := ((integer(Checked) and 1) + 1) shl 12;
  SendMessage(hwndLV, LVM_SETITEMSTATE, i, integer(@Item));
end;

function ListView_GetItemTextA(hwndLV: HWND; i, iSubItem: integer;
  pszText: PAnsiChar; cchTextMax: integer): integer;
var
  Item                                  : TLVItemA;
begin
  Item.iSubItem := iSubItem;
  Item.cchTextMax := cchTextMax;
  Item.pszText := pszText;
  Result := SendMessage(hwndLV, LVM_GETITEMTEXT, i, LONGINT(@Item));
end;

function ListView_GetItemTextW(hwndLV: HWND; i, iSubItem: integer;
  pszText: PWideChar; cchTextMax: integer): integer;
var
  Item                                  : TLVItemW;
begin
  Item.iSubItem := iSubItem;
  Item.cchTextMax := cchTextMax;
  Item.pszText := pszText;
  Result := SendMessage(hwndLV, LVM_GETITEMTEXT, i, LONGINT(@Item));
end;

function ListView_GetItemText(hwndLV: HWND; i, iSubItem: integer;
  pszText: PChar; cchTextMax: integer): integer;
var
  Item                                  : TLVItem;
begin
  Item.iSubItem := iSubItem;
  Item.cchTextMax := cchTextMax;
  Item.pszText := pszText;
  Result := SendMessage(hwndLV, LVM_GETITEMTEXT, i, LONGINT(@Item));
end;

function ListView_SetItemTextA(hwndLV: HWND; i, iSubItem: integer;
  pszText: PAnsiChar): BOOL;
var
  Item                                  : TLVItemA;
begin
  Item.iSubItem := iSubItem;
  Item.pszText := pszText;
  Result := BOOL(SendMessage(hwndLV, LVM_SETITEMTEXT, i, LONGINT(@Item)));
end;

function ListView_SetItemTextW(hwndLV: HWND; i, iSubItem: integer;
  pszText: PWideChar): BOOL;
var
  Item                                  : TLVItemW;
begin
  Item.iSubItem := iSubItem;
  Item.pszText := pszText;
  Result := BOOL(SendMessage(hwndLV, LVM_SETITEMTEXT, i, LONGINT(@Item)));
end;

function ListView_SetItemText(hwndLV: HWND; i, iSubItem: integer;
  pszText: PChar): BOOL;
var
  Item                                  : TLVItem;
begin
  Item.iSubItem := iSubItem;
  Item.pszText := pszText;
  Result := BOOL(SendMessage(hwndLV, LVM_SETITEMTEXT, i, LONGINT(@Item)));
end;

procedure ListView_SetItemCount(hwndLV: HWND; cItems: integer);
begin
  SendMessage(hwndLV, LVM_SETITEMCOUNT, cItems, 0);
end;

function ListView_SortItems(hwndLV: HWND; pfnCompare: TLVCompare;
  lPrm: LONGINT): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_SORTITEMS, lPrm, LONGINT(@pfnCompare)));
end;

procedure ListView_SetItemPosition32(hwndLV: HWND; i, X, Y: integer);
var
  ptNewPos                              : TPoint;
begin
  ptNewPos.X := X;
  ptNewPos.Y := Y;
  SendMessage(hwndLV, LVM_SETITEMPOSITION32, i, LONGINT(@ptNewPos));
end;

function ListView_GetSelectedCount(hwndLV: HWND): UINT;
begin
  Result := SendMessage(hwndLV, LVM_GETSELECTEDCOUNT, 0, 0);
end;

function ListView_GetItemSpacing(hwndLV: HWND; fSmall: integer): LONGINT;
begin
  Result := SendMessage(hwndLV, LVM_GETITEMSPACING, fSmall, 0);
end;

function ListView_GetISearchStringA(hwndLV: HWND; lpsz: PAnsiChar): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_GETISEARCHSTRING, 0,
    LONGINT(lpsz)));
end;

function ListView_GetISearchStringW(hwndLV: HWND; lpsz: PWideChar): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_GETISEARCHSTRING, 0,
    LONGINT(lpsz)));
end;

function ListView_GetISearchString(hwndLV: HWND; lpsz: PChar): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_GETISEARCHSTRING, 0,
    LONGINT(lpsz)));
end;

function ListView_SetIconSpacing(hwndLV: HWND; cx, cy: Word): DWORD;
begin
  Result := SendMessage(hwndLV, LVM_SETICONSPACING, 0, MakeLong(cx, cy));
end;

function ListView_SetExtendedListViewStyle(hwndLV: HWND; dw: integer {DWORD}): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_SETEXTENDEDLISTVIEWSTYLE, 0, dw));
end;

function ListView_GetExtendedListViewStyle(hwndLV: HWND): DWORD;
begin
  Result := SendMessage(hwndLV, LVM_GETEXTENDEDLISTVIEWSTYLE, 0, 0);
end;

function ListView_GetSubItemRect(hwndLV: HWND; iItem, iSubItem: integer;
  code: DWORD; prc: PRect): BOOL;
begin
  if prc <> nil then
  begin
    prc^.Top := iSubItem;
    prc^.Left := code;
  end;
  Result := BOOL(SendMessage(hwndLV, LVM_GETSUBITEMRECT, iItem, LONGINT(prc)));
end;

function ListView_SubItemHitTest(hwndLV: HWND; plvhti: PLVHitTestInfo): integer;
begin
  Result := SendMessage(hwndLV, LVM_SUBITEMHITTEST, 0, LONGINT(plvhti));
end;

function ListView_SetColumnOrderArray(hwndLV: HWND; iCount: integer;
  PI: PInteger): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_SETCOLUMNORDERARRAY, iCount,
    LONGINT(PI)));
end;

function ListView_GetColumnOrderArray(hwndLV: HWND; iCount: integer;
  PI: PInteger): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_GETCOLUMNORDERARRAY, iCount,
    LONGINT(PI)));
end;

function ListView_SetHotItem(hwndLV: HWND; i: integer): integer;
begin
  Result := SendMessage(hwndLV, LVM_SETHOTITEM, i, 0);
end;

function ListView_GetHotItem(hwndLV: HWND): integer;
begin
  Result := SendMessage(hwndLV, LVM_GETHOTITEM, 0, 0);
end;

function ListView_SetHotCursor(hwndLV: HWND; hcur: HCURSOR): HCURSOR;
begin
  Result := SendMessage(hwndLV, LVM_SETHOTCURSOR, 0, hcur);
end;

function ListView_GetHotCursor(hwndLV: HWND): HCURSOR;
begin
  Result := SendMessage(hwndLV, LVM_GETHOTCURSOR, 0, 0);
end;

function ListView_ApproximateViewRect(hwndLV: HWND; iWidth, iHeight: Word;
  iCount: integer): DWORD;
begin
  Result := SendMessage(hwndLV, LVM_APPROXIMATEVIEWRECT, iCount,
    MakeLParam(iWidth, iHeight));
end;

function ListView_SetWorkArea(hwndLV: HWND; prc: PRect): BOOL;
begin
  Result := BOOL(SendMessage(hwndLV, LVM_SETWORKAREA, 0, LONGINT(prc)));
end;

{ Tree View }

function TreeView_InsertItem(HWND: HWND; const lpis: TTVInsertStruct): HTreeItem;
begin
  Result := HTreeItem(SendMessage(HWND, TVM_INSERTITEM, 0, LONGINT(@lpis)));
end;

function TreeView_DeleteItem(HWND: HWND; hItem: HTreeItem): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_DELETEITEM, 0, LONGINT(hItem)));
end;

function TreeView_DeleteAllItems(HWND: HWND): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_DELETEITEM, 0, LONGINT(TVI_ROOT)));
end;

function TreeView_Expand(HWND: HWND; hItem: HTreeItem; code: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_EXPAND, code, LONGINT(hItem)));
end;

function TreeView_GetItemRect(HWND: HWND; hItem: HTreeItem;
  var prc: TRect; code: BOOL): BOOL;
begin
  HTreeItem(Pointer(@prc)^) := hItem;
  Result := BOOL(SendMessage(HWND, TVM_GETITEMRECT, integer(code), LONGINT(@prc)));
end;

function TreeView_GetCount(HWND: HWND): UINT;
begin
  Result := SendMessage(HWND, TVM_GETCOUNT, 0, 0);
end;

function TreeView_GetIndent(HWND: HWND): UINT;
begin
  Result := SendMessage(HWND, TVM_GETINDENT, 0, 0);
end;

function TreeView_SetIndent(HWND: HWND; indent: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_SETINDENT, indent, 0));
end;

function TreeView_GetImageList(HWND: HWND; iImage: integer): HImageList;
begin
  Result := HImageList(SendMessage(HWND, TVM_GETIMAGELIST, iImage, 0));
end;

function TreeView_SetImageList(HWND: HWND; himl: HImageList;
  iImage: integer): HImageList;
begin
  Result := HImageList(SendMessage(HWND, TVM_SETIMAGELIST, iImage,
    LONGINT(himl)));
end;

function TreeView_GetNextItem(HWND: HWND; hItem: HTreeItem;
  code: integer): HTreeItem;
begin
  Result := HTreeItem(SendMessage(HWND, TVM_GETNEXTITEM, code,
    LONGINT(hItem)));
end;

function TreeView_GetChild(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, hItem, TVGN_CHILD);
end;

function TreeView_GetNextSibling(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, hItem, TVGN_NEXT);
end;

function TreeView_GetPrevSibling(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, hItem, TVGN_PREVIOUS);
end;

function TreeView_GetParent(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, hItem, TVGN_PARENT);
end;

function TreeView_GetFirstVisible(HWND: HWND): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, nil, TVGN_FIRSTVISIBLE);
end;

function TreeView_GetNextVisible(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, hItem, TVGN_NEXTVISIBLE);
end;

function TreeView_GetPrevVisible(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, hItem, TVGN_PREVIOUSVISIBLE);
end;

function TreeView_GetSelection(HWND: HWND): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, nil, TVGN_CARET);
end;

function TreeView_GetDropHilite(HWND: HWND): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, nil, TVGN_DROPHILITE);
end;

function TreeView_GetRoot(HWND: HWND): HTreeItem;
begin
  Result := TreeView_GetNextItem(HWND, nil, TVGN_ROOT);
end;

function TreeView_Select(HWND: HWND; hItem: HTreeItem;
  code: integer): HTreeItem;
begin
  Result := HTreeItem(SendMessage(HWND, TVM_SELECTITEM, code,
    LONGINT(hItem)));
end;

function TreeView_SelectItem(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_Select(HWND, hItem, TVGN_CARET);
end;

function TreeView_SelectDropTarget(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_Select(HWND, hItem, TVGN_DROPHILITE);
end;

function TreeView_SelectSetFirstVisible(HWND: HWND; hItem: HTreeItem): HTreeItem;
begin
  Result := TreeView_Select(HWND, hItem, TVGN_FIRSTVISIBLE);
end;

function TreeView_GetItemA(HWND: HWND; var pItem: TTVItemA): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_GETITEM, 0, LONGINT(@pItem)));
end;

function TreeView_GetItemW(HWND: HWND; var pItem: TTVItemW): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_GETITEM, 0, LONGINT(@pItem)));
end;

function TreeView_GetItem(HWND: HWND; var pItem: TTVItem): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_GETITEM, 0, LONGINT(@pItem)));
end;

function TreeView_SetItemA(HWND: HWND; const pItem: TTVItemA): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_SETITEM, 0, LONGINT(@pItem)));
end;

function TreeView_SetItemW(HWND: HWND; const pItem: TTVItemW): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_SETITEM, 0, LONGINT(@pItem)));
end;

function TreeView_SetItem(HWND: HWND; const pItem: TTVItem): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_SETITEM, 0, LONGINT(@pItem)));
end;

function TreeView_EditLabelA(HWND: HWND; hItem: HTreeItem): HWND;
begin
  Result := Windows.HWND(SendMessage(HWND, TVM_EDITLABEL, 0, LONGINT(hItem)));
end;

function TreeView_EditLabelW(HWND: HWND; hItem: HTreeItem): HWND;
begin
  Result := Windows.HWND(SendMessage(HWND, TVM_EDITLABEL, 0, LONGINT(hItem)));
end;

function TreeView_EditLabel(HWND: HWND; hItem: HTreeItem): HWND;
begin
  Result := Windows.HWND(SendMessage(HWND, TVM_EDITLABEL, 0, LONGINT(hItem)));
end;

function TreeView_GetEditControl(HWND: HWND): HWND;
begin
  Result := Windows.HWND(SendMessage(HWND, TVM_GETEDITCONTROL, 0, 0));
end;

function TreeView_GetVisibleCount(HWND: HWND): UINT;
begin
  Result := SendMessage(HWND, TVM_GETVISIBLECOUNT, 0, 0);
end;

function TreeView_HitTest(HWND: HWND; var lpht: TTVHitTestInfo): HTreeItem;
begin
  Result := HTreeItem(SendMessage(HWND, TVM_HITTEST, 0, LONGINT(@lpht)));
end;

function TreeView_CreateDragImage(HWND: HWND; hItem: HTreeItem): HImageList;
begin
  Result := HImageList(SendMessage(HWND, TVM_CREATEDRAGIMAGE, 0,
    LONGINT(hItem)));
end;

function TreeView_SortChildren(HWND: HWND; hItem: HTreeItem;
  recurse: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_SORTCHILDREN, recurse,
    LONGINT(hItem)));
end;

function TreeView_EnsureVisible(HWND: HWND; hItem: HTreeItem): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_ENSUREVISIBLE, 0, LONGINT(hItem)));
end;

function TreeView_SortChildrenCB(HWND: HWND; const psort: TTVSortCB;
  recurse: integer): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_SORTCHILDRENCB, recurse,
    LONGINT(@psort)));
end;

function TreeView_EndEditLabelNow(HWND: HWND; fCancel: BOOL): BOOL;
begin
  Result := BOOL(SendMessage(HWND, TVM_ENDEDITLABELNOW, integer(fCancel),
    0));
end;

function TreeView_GetISearchStringA(hwndTV: HWND; lpsz: PAnsiChar): BOOL;
begin
  Result := BOOL(SendMessage(hwndTV, TVM_GETISEARCHSTRING, 0,
    LONGINT(lpsz)));
end;

function TreeView_GetISearchStringW(hwndTV: HWND; lpsz: PWideChar): BOOL;
begin
  Result := BOOL(SendMessage(hwndTV, TVM_GETISEARCHSTRING, 0,
    LONGINT(lpsz)));
end;

function TreeView_GetISearchString(hwndTV: HWND; lpsz: PChar): BOOL;
begin
  Result := BOOL(SendMessage(hwndTV, TVM_GETISEARCHSTRING, 0,
    LONGINT(lpsz)));
end;

{ MonthCal control }

function MonthCal_GetCurSel(hmc: HWND; var pst: TSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_GETCURSEL, 0, LONGINT(@pst)));
end;

function MonthCal_SetCurSel(hmc: HWND; const pst: TSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETCURSEL, 0, LONGINT(@pst)));
end;

function MonthCal_GetMaxSelCount(hmc: HWND): DWORD;
begin
  Result := SendMessage(hmc, MCM_GETMAXSELCOUNT, 0, 0);
end;

function MonthCal_SetMaxSelCount(hmc: HWND; n: UINT): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETMAXSELCOUNT, n, 0));
end;

function MonthCal_GetSelRange(hmc: HWND; rgst: PSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_GETSELRANGE, 0, LONGINT(rgst)));
end;

function MonthCal_SetSelRange(hmc: HWND; rgst: PSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETSELRANGE, 0, LONGINT(rgst)));
end;

function MonthCal_GetMonthRange(hmc: HWND; gmr: DWORD; rgst: PSystemTime): DWORD;
begin
  Result := SendMessage(hmc, MCM_GETMONTHRANGE, gmr, LONGINT(rgst));
end;

function MonthCal_SetDayState(hmc: HWND; cbds: integer; const rgds: TNMDayState): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETDAYSTATE, cbds, LONGINT(@rgds)));
end;

function MonthCal_GetMinReqRect(hmc: HWND; var prc: TRect): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_GETMINREQRECT, 0, LONGINT(@prc)));
end;

function MonthCal_SetToday(hmc: HWND; const pst: TSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETTODAY, 0, LONGINT(@pst)));
end;

function MonthCal_GetToday(hmc: HWND; var pst: TSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_GETTODAY, 0, LONGINT(@pst)));
end;

function MonthCal_HitTest(hmc: HWND; var Info: TMCHitTestInfo): DWORD;
begin
  Result := SendMessage(hmc, MCM_HITTEST, 0, LONGINT(@Info));
end;

function MonthCal_SetColor(hmc: HWND; iColor: integer; clr: TColorRef): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETCOLOR, iColor, clr));
end;

function MonthCal_GetColor(hmc: HWND; iColor: integer): TColorRef;
begin
  Result := TColorRef(SendMessage(hmc, MCM_SETCOLOR, iColor, 0));
end;

function MonthCal_SetFirstDayOfWeek(hmc: HWND; iDay: integer): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETFIRSTDAYOFWEEK, 0, iDay));
end;

function MonthCal_GetFirstDayOfWeek(hmc: HWND): integer;
begin
  Result := SendMessage(hmc, MCM_GETFIRSTDAYOFWEEK, 0, 0);
end;

function MonthCal_GetRange(hmc: HWND; rgst: PSystemTime): DWORD;
begin
  Result := SendMessage(hmc, MCM_GETRANGE, 0, LONGINT(rgst));
end;

function Monthcal_SetRange(hmc: HWND; gdtr: DWORD; rgst: PSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(hmc, MCM_SETRANGE, gdtr, LONGINT(rgst)));
end;

function MonthCal_GetMonthDelta(hmc: HWND): integer;
begin
  Result := SendMessage(hmc, MCM_GETMONTHDELTA, 0, 0);
end;

function MonthCal_SetMonthDelta(hmc: HWND; n: integer): integer;
begin
  Result := SendMessage(hmc, MCM_SETMONTHDELTA, n, 0);
end;

{ Date/Time Picker }

function DateTime_GetSystemTime(HDP: HWND; var pst: TSystemTime): DWORD;
begin
  Result := SendMessage(HDP, DTM_GETSYSTEMTIME, 0, LONGINT(@pst));
end;

function DateTime_SetSystemTime(HDP: HWND; gd: DWORD; const pst: TSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(HDP, DTM_SETSYSTEMTIME, gd, LONGINT(@pst)));
end;

function DateTime_GetRange(HDP: HWND; rgst: PSystemTime): DWORD;
begin
  Result := SendMessage(HDP, DTM_GETRANGE, 0, LONGINT(rgst));
end;

function DateTime_SetRange(HDP: HWND; gdtr: DWORD; rgst: PSystemTime): BOOL;
begin
  Result := BOOL(SendMessage(HDP, DTM_SETRANGE, gdtr, LONGINT(rgst)));
end;

function DateTime_SetFormatA(HDP: HWND; sz: PAnsiChar): BOOL;
begin
  Result := BOOL(SendMessage(HDP, DTM_SETFORMATA, 0, LONGINT(sz)));
end;

function DateTime_SetFormatW(HDP: HWND; sz: PWideChar): BOOL;
begin
  Result := BOOL(SendMessage(HDP, DTM_SETFORMATW, 0, LONGINT(sz)));
end;

function DateTime_SetFormat(HDP: HWND; sz: PChar): BOOL;
begin
  Result := BOOL(SendMessage(HDP, DTM_SETFORMAT, 0, LONGINT(sz)));
end;

function DateTime_SetMonthCalColor(HDP: HWND; iColor: DWORD; clr: TColorRef): DWORD;
begin
  Result := SendMessage(HDP, DTM_SETMCCOLOR, iColor, clr);
end;

function DateTime_GetMonthCalColor(HDP: HWND; iColor: DWORD): TColorRef;
begin
  Result := SendMessage(HDP, DTM_GETMCCOLOR, iColor, 0);
end;

function DateTime_GetMonthCal(HDP: HWND): HWND;
begin
  Result := SendMessage(HDP, DTM_GETMONTHCAL, 0, 0);
end;

function DateTime_SetMonthCalFont(HDP: HWND; Font: HFONT; fRedraw: boolean): DWORD;
begin
  Result := SendMessage(HDP, DTM_SETMCFONT, Font, Ord(fRedraw));
end;

function DateTime_GetMonthCalFont(HDP: HWND): HFONT;
begin
  Result := SendMessage(HDP, DTM_GETMCFONT, 0, 0);
end;

{ IP Address edit control }

function MAKEIPRANGE(Low, High: Byte): lParam;
begin
  Result := High;
  Result := (Result shl 8) + Low;
end;

function MAKEIPADDRESS(B1, B2, b3, b4: DWORD): lParam;
begin
  Result := (B1 shl 24) + (B2 shl 16) + (b3 shl 8) + b4;
end;

function FIRST_IPADDRESS(X: DWORD): DWORD;
begin
  Result := (X shr 24) and $FF;
end;

function SECOND_IPADDRESS(X: DWORD): DWORD;
begin
  Result := (X shr 16) and $FF;
end;

function THIRD_IPADDRESS(X: DWORD): DWORD;
begin
  Result := (X shr 8) and $FF;
end;

function FOURTH_IPADDRESS(X: DWORD): DWORD;
begin
  Result := X and $FF;
end;

{ Pager control }

procedure Pager_SetChild(HWND: HWND; hwndChild: HWND);
begin
  SendMessage(HWND, PGM_SETCHILD, 0, lParam(hwndChild));
end;

procedure Pager_RecalcSize(HWND: HWND);
begin
  SendMessage(HWND, PGM_RECALCSIZE, 0, 0);
end;

procedure Pager_ForwardMouse(HWND: HWND; bForward: BOOL);
begin
  SendMessage(HWND, PGM_FORWARDMOUSE, wParam(bForward), 0);
end;

function Pager_SetBkColor(HWND: HWND; clr: COLORREF): COLORREF;
begin
  Result := COLORREF(SendMessage(HWND, PGM_SETBKCOLOR, 0, lParam(clr)));
end;

function Pager_GetBkColor(HWND: HWND): COLORREF;
begin
  Result := COLORREF(SendMessage(HWND, PGM_GETBKCOLOR, 0, 0));
end;

function Pager_SetBorder(HWND: HWND; iBorder: integer): integer;
begin
  Result := SendMessage(HWND, PGM_SETBORDER, 0, iBorder);
end;

function Pager_GetBorder(HWND: HWND): integer;
begin
  Result := SendMessage(HWND, PGM_GETBORDER, 0, 0);
end;

function Pager_SetPos(HWND: HWND; iPos: integer): integer;
begin
  Result := SendMessage(HWND, PGM_SETPOS, 0, iPos);
end;

function Pager_GetPos(HWND: HWND): integer;
begin
  Result := SendMessage(HWND, PGM_GETPOS, 0, 0);
end;

function Pager_SetButtonSize(HWND: HWND; iSize: integer): integer;
begin
  Result := SendMessage(HWND, PGM_SETBUTTONSIZE, 0, iSize);
end;

function Pager_GetButtonSize(HWND: HWND): integer;
begin
  Result := SendMessage(HWND, PGM_GETBUTTONSIZE, 0, 0);
end;

function Pager_GetButtonState(HWND: HWND; iButton: integer): DWORD;
begin
  Result := SendMessage(HWND, PGM_GETBUTTONSTATE, 0, iButton);
end;

procedure Pager_GetDropTarget(HWND: HWND; ppdt: Pointer {!!});
begin
  SendMessage(HWND, PGM_GETDROPTARGET, 0, lParam(ppdt));
end;
{
function ListView_GetItemName(hListView: HWND): string;
var
  buf                                   : array[0..MAX_PATH] of Char;
  i                                     : integer;
begin
  i := ListView_GetNextItem(hListView, -1, LVNI_FOCUSED);
  if (i > -1) then
  begin
    ZeroMemory(@buf, SizeOf(buf));
    ListView_GetItemText(hListView, i, 0, buf, SizeOf(buf));
    if buf[0] <> #0 then Result := buf;
  end;
end;
}
{ TrackMouseEvent }

function _TrackMouseEvent; external cctrl Name '_TrackMouseEvent';

{ Flat Scrollbar APIs }

function FlatSB_EnableScrollBar; external cctrl Name 'FlatSB_EnableScrollBar';
function FlatSB_GetScrollInfo; external cctrl Name 'FlatSB_GetScrollInfo';
function FlatSB_GetScrollPos; external cctrl Name 'FlatSB_GetScrollPos';
function FlatSB_GetScrollProp; external cctrl Name 'FlatSB_GetScrollProp';
function FlatSB_GetScrollRange; external cctrl Name 'FlatSB_GetScrollRange';
function FlatSB_SetScrollInfo; external cctrl Name 'FlatSB_SetScrollInfo';
function FlatSB_SetScrollPos; external cctrl Name 'FlatSB_SetScrollPos';
function FlatSB_SetScrollProp; external cctrl Name 'FlatSB_SetScrollProp';
function FlatSB_SetScrollRange; external cctrl Name 'FlatSB_SetScrollRange';
function FlatSB_ShowScrollBar; external cctrl Name 'FlatSB_ShowScrollBar';
function InitializeFlatSB; external cctrl Name 'InitializeFlatSB';
procedure UninitializeFlatSB; external cctrl Name 'UninitializeFlatSB';

function DSA_Clone; external cctrl Name 'DSA_Clone';
function DSA_Create; external cctrl Index 320; //Name 'DSA_Create';
function DSA_DeleteAllItems; external cctrl Index 327; // Name 'DSA_DeleteAllItems';
function DSA_DeleteItem; external cctrl Index 326;
function DSA_Destroy; external cctrl Name 'DSA_Destroy';
function DSA_DestroyCallback; external cctrl Name 'DSA_DestroyCallback';
procedure DSA_EnumCallback; external cctrl Name 'DSA_EnumCallback';
function DSA_GetItem; external cctrl Index 322;
function DSA_GetItemPtr; external cctrl Index 323; //Name 'DSA_GetItemPtr';
function DSA_GetSize; external cctrl Name 'DSA_GetSize';
function DSA_InsertItem; external cctrl Index 324; //Name 'DSA_InsertItem';
function DSA_SetItem; external cctrl Index 325;
function DSA_Sort; external cctrl Name 'DSA_Sort';
{
http://www.geoffchappell.com/viewer.htm?doc=studies/windows/shell/comctl32/history/index.htm
http://www.geoffchappell.com/viewer.htm?doc=studies/windows/shell/comctl32/api/index.htm

DSA_Clone                 6.10 and higher	documented
DSA_Create          (320) 3.50 and higher	documented for settlement
DSA_DeleteAllItems  (327) 3.50 and higher	documented in 2006
DSA_DeleteItem      (326) 3.50 and higher	documented in 2004-2006
DSA_Destroy         (321) 3.50 and higher	documented for settlement
DSA_DestroyCallback (388) 4.71 and higher	documented for settlement
DSA_EnumCallback    (387) 4.71 and higher	documented in 2006
DSA_GetItem         (322) 3.50 and higher	documented in 2004-2006
DSA_GetItemPtr      (323) 3.50 and higher	documented for settlement
DSA_GetSize	          6.10 and higher	documented
DSA_InsertItem      (324) 3.50 and higher	documented for settlement
DSA_SetItem         (325) 3.50 and higher	documented in 2004-2006
DSA_Sort                  6.10 and higher	documented
3.50 - first
4.71 - windows98?
6.10 - Windows Vista>
}
initialization
  InitCommonControls;
end.


