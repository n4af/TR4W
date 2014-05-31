type
  PColor = ^tcolor;
  tcolor = -$7FFFFFFF - 1..$7FFFFFFF;

  { ====== WM_NOTIFY codes (NMHDR.code values) ================== }

const
  NM_FIRST                         = 0 - 0; { generic to all controls }
  NM_LAST                          = 0 - 99;

  LVN_FIRST                        = 0 - 100; { listview }
  LVN_LAST                         = 0 - 199;

  HDN_FIRST                        = 0 - 300; { header }
  HDN_LAST                         = 0 - 399;

  TVN_FIRST                        = 0 - 400; { treeview }
  TVN_LAST                         = 0 - 499;

  TTN_FIRST                        = 0 - 520; { tooltips }
  TTN_LAST                         = 0 - 549;

  TCN_FIRST                        = 0 - 550; { tab control }
  TCN_LAST                         = 0 - 580;

  { Shell reserved           (0-580) -  (0-589) }

  CDN_FIRST                        = 0 - 601; { common dialog (new) }
  CDN_LAST                         = 0 - 699;

  TBN_FIRST                        = 0 - 700; { toolbar }
  TBN_LAST                         = 0 - 720;

  UDN_FIRST                        = 0 - 721; { updown }
  UDN_LAST                         = 0 - 740;

  MCN_FIRST                        = 0 - 750; { monthcal }
  MCN_LAST                         = 0 - 759;

  DTN_FIRST                        = 0 - 760; { datetimepick }
  DTN_LAST                         = 0 - 799;

  CBEN_FIRST                       = 0 - 800; { combo box ex }
  CBEN_LAST                        = 0 - 830;

  RBN_FIRST                        = 0 - 831; { coolbar }
  RBN_LAST                         = 0 - 859;

  IPN_FIRST                        = 0 - 860; { internet address }
  IPN_LAST                         = 0 - 879; { internet address }

  SBN_FIRST                        = 0 - 880; { status bar }
  SBN_LAST                         = 0 - 899;

  PGN_FIRST                        = 0 - 900; { Pager Control }
  PGN_LAST                         = 0 - 950;

  MSGF_COMMCTRL_BEGINDRAG          = $4200;
  MSGF_COMMCTRL_SIZEHEADER         = $4201;
  MSGF_COMMCTRL_DRAGSELECT         = $4202;
  MSGF_COMMCTRL_TOOLBARCUST        = $4203;

const
  LVM_FIRST                        = $1000; { ListView messages }
  TV_FIRST                         = $1100; { TreeView messages }
  HDM_FIRST                        = $1200; { Header messages }
  TCM_FIRST                        = $1300; { Tab control messages }
  PGM_FIRST                        = $1400; { Pager control messages }
  CCM_FIRST                        = $2000; { Common control shared messages }

const
  LVCF_FMT                         = $0001;
  LVCF_WIDTH                       = $0002;
  LVCF_TEXT                        = $0004;
  LVCF_SUBITEM                     = $0008;
  LVCF_IMAGE                       = $0010;
  LVCF_ORDER                       = $0020;

  LVCFMT_LEFT                      = $0000;
  LVCFMT_RIGHT                     = $0001;
  LVCFMT_CENTER                    = $0002;
  LVCFMT_JUSTIFYMASK               = $0003;
  LVCFMT_IMAGE                     = $0800;
  LVCFMT_BITMAP_ON_RIGHT           = $1000;
  LVCFMT_COL_HAS_IMAGES            = $8000;

  LVM_GETCOLUMNA                   = LVM_FIRST + 25;
  LVM_GETCOLUMNW                   = LVM_FIRST + 95;
  LVM_GETCOLUMN                    = LVM_GETCOLUMNA;

const
  clScrollBar                      = tcolor(COLOR_SCROLLBAR or $80000000);
  clBackground                     = tcolor(COLOR_BACKGROUND or $80000000);
  clActiveCaption                  = tcolor(COLOR_ACTIVECAPTION or $80000000);
  clInactiveCaption                = tcolor(COLOR_INACTIVECAPTION or $80000000);
  clMenu                           = tcolor(COLOR_MENU or $80000000);
  clWindow                         = tcolor(COLOR_WINDOW or $80000000);
  clWindowFrame                    = tcolor(COLOR_WINDOWFRAME or $80000000);
  clMenuText                       = tcolor(COLOR_MENUTEXT or $80000000);
  clWindowText                     = tcolor(COLOR_WINDOWTEXT or $80000000);
  clCaptionText                    = tcolor(COLOR_CAPTIONTEXT or $80000000);
  clActiveBorder                   = tcolor(COLOR_ACTIVEBORDER or $80000000);
  clInactiveBorder                 = tcolor(COLOR_INACTIVEBORDER or $80000000);
  clAppWorkSpace                   = tcolor(COLOR_APPWORKSPACE or $80000000);
  clHighlight                      = tcolor(COLOR_HIGHLIGHT or $80000000);
  clHighlightText                  = tcolor(COLOR_HIGHLIGHTTEXT or $80000000);
  clbtnface                        = tcolor(COLOR_BTNFACE or $80000000);
  clBtnShadow                      = tcolor(COLOR_BTNSHADOW or $80000000);
  clGrayText                       = tcolor(COLOR_GRAYTEXT or $80000000);
  clBtnText                        = tcolor(COLOR_BTNTEXT or $80000000);
  clInactiveCaptionText            = tcolor(COLOR_INACTIVECAPTIONTEXT or $80000000);
  clBtnHighlight                   = tcolor(COLOR_BTNHIGHLIGHT or $80000000);
  cl3DDkShadow                     = tcolor(COLOR_3DDKSHADOW or $80000000);
  cl3DLight                        = tcolor(COLOR_3DLIGHT or $80000000);
  clInfoText                       = tcolor(COLOR_INFOTEXT or $80000000);
  clInfoBk                         = tcolor(COLOR_INFOBK or $80000000);
  clGradientActiveCaption          = tcolor(COLOR_GRADIENTACTIVECAPTION or $80000000);
  clGradientInactiveCaption        = tcolor(COLOR_GRADIENTINACTIVECAPTION or $80000000);

  clblack                          = tcolor($000000);
  clMaroon                         = tcolor($000080);
  clgreen                          = tcolor($008000);
  clOlive                          = tcolor($008080);
  clnavy                           = tcolor($800000);
  clPurple                         = tcolor($800080);
  clTeal                           = tcolor($808000);
  clgray                           = tcolor($808080);
  clsilver                         = tcolor($C0C0C0);
  clred                            = tcolor($0000FF);

  clCyan                           = tcolor($808000);

  clLime                           = tcolor($00FF00);
  clYellow                         = tcolor($00FFFF);
  clblue                           = tcolor($FF0000);
  clFuchsia                        = tcolor($FF00FF);
  clAqua                           = tcolor($FFFF00);
  clLtGray                         = tcolor($C0C0C0);
  clDkGray                         = tcolor($808080);
  clwhite                          = tcolor($FFFFFF);
  StandardColorsCount              = 16;

  clMoneyGreen                     = tcolor($C0DCC0);
  clSkyBlue                        = tcolor($F0CAA6);
  clCream                          = tcolor($F0FBFF);
  clMedGray                        = tcolor($A4A0A0);
  ExtendedColorsCount              = 4;

  clNone                           = tcolor($1FFFFFFF);
  clDefault                        = tcolor($20000000);
  CLR_DEFAULT                      = $FF000000;

  //clUnused = TColor($D4D4D4);

const
  cmBlackness                      = BLACKNESS;
  cmDstInvert                      = DSTINVERT;
  cmMergeCopy                      = MERGECOPY;
  cmMergePaint                     = MERGEPAINT;
  cmNotSrcCopy                     = NOTSRCCOPY;
  cmNotSrcErase                    = NOTSRCERASE;
  cmPatCopy                        = PATCOPY;
  cmPatInvert                      = PATINVERT;
  cmPatPaint                       = PATPAINT;
  cmSrcAnd                         = SRCAND;
  cmSrcCopy                        = SRCCOPY;
  cmSrcErase                       = SRCERASE;
  cmSrcInvert                      = SRCINVERT;
  cmSrcPaint                       = SRCPAINT;
  cmWhiteness                      = WHITENESS;

const
{$EXTERNALSYM SB_SETTEXTA}
  SB_SETTEXTA                      = WM_USER + 1;
{$EXTERNALSYM SB_GETTEXTA}
  SB_GETTEXTA                      = WM_USER + 2;
{$EXTERNALSYM SB_GETTEXTLENGTHA}
  SB_GETTEXTLENGTHA                = WM_USER + 3;
{$EXTERNALSYM SB_SETTIPTEXTA}
  SB_SETTIPTEXTA                   = WM_USER + 16;
{$EXTERNALSYM SB_GETTIPTEXTA}
  SB_GETTIPTEXTA                   = WM_USER + 18;

{$EXTERNALSYM SB_SETTEXTW}
  SB_SETTEXTW                      = WM_USER + 11;
{$EXTERNALSYM SB_GETTEXTW}
  SB_GETTEXTW                      = WM_USER + 13;
{$EXTERNALSYM SB_GETTEXTLENGTHW}
  SB_GETTEXTLENGTHW                = WM_USER + 12;
{$EXTERNALSYM SB_SETTIPTEXTW}
  SB_SETTIPTEXTW                   = WM_USER + 17;
{$EXTERNALSYM SB_GETTIPTEXTW}
  SB_GETTIPTEXTW                   = WM_USER + 19;

{$EXTERNALSYM SB_SETTEXT}
  SB_SETTEXT                       = SB_SETTEXTA;
{$EXTERNALSYM SB_GETTEXT}
  SB_GETTEXT                       = SB_GETTEXTA;
{$EXTERNALSYM SB_GETTEXTLENGTH}
  SB_GETTEXTLENGTH                 = SB_GETTEXTLENGTHA;
{$EXTERNALSYM SB_SETTIPTEXT}
  SB_SETTIPTEXT                    = SB_SETTIPTEXTA;
{$EXTERNALSYM SB_GETTIPTEXT}
  SB_GETTIPTEXT                    = SB_GETTIPTEXTA;

{$EXTERNALSYM SB_SETPARTS}
  SB_SETPARTS                      = WM_USER + 4;
{$EXTERNALSYM SB_GETPARTS}
  SB_GETPARTS                      = WM_USER + 6;
{$EXTERNALSYM SB_GETBORDERS}
  SB_GETBORDERS                    = WM_USER + 7;
{$EXTERNALSYM SB_SETMINHEIGHT}
  SB_SETMINHEIGHT                  = WM_USER + 8;
{$EXTERNALSYM SB_SIMPLE}
  SB_SIMPLE                        = WM_USER + 9;
{$EXTERNALSYM SB_GETRECT}
  SB_GETRECT                       = WM_USER + 10;
{$EXTERNALSYM SB_ISSIMPLE}
  SB_ISSIMPLE                      = WM_USER + 14;
{$EXTERNALSYM SB_SETICON}
  SB_SETICON                       = WM_USER + 15;
{$EXTERNALSYM SB_GETICON}
  SB_GETICON                       = WM_USER + 20;
{ $ E X T E RNALSYM SB_SETUNICODEFORMAT}
//  SB_SETUNICODEFORMAT                   = CCM_SETUNICODEFORMAT;
{ $ E X T ERNALSYM SB_GETUNICODEFORMAT}
//  SB_GETUNICODEFORMAT                   = CCM_GETUNICODEFORMAT;

{$EXTERNALSYM SBT_OWNERDRAW}
  SBT_OWNERDRAW                    = $1000;
{$EXTERNALSYM SBT_NOBORDERS}
  SBT_NOBORDERS                    = $0100;
{$EXTERNALSYM SBT_POPOUT}
  SBT_POPOUT                       = $0200;
{$EXTERNALSYM SBT_RTLREADING}
  SBT_RTLREADING                   = $0400;
{$EXTERNALSYM SBT_TOOLTIPS}
  SBT_TOOLTIPS                     = $0800;

  CCM_SETBKCOLOR                   = CCM_FIRST + 1; // lParam is bkColor
{$EXTERNALSYM SB_SETBKCOLOR}

  SB_SETBKCOLOR                    = CCM_SETBKCOLOR; // lParam = bkColor

  // status bar notifications
{$EXTERNALSYM SBN_SIMPLEMODECHANGE}
  SBN_SIMPLEMODECHANGE             = SBN_FIRST - 0;

const
  PBS_SMOOTH                       = 01;
  PBS_VERTICAL                     = 04;
  PBM_SETRANGE                     = WM_USER + 1;

  PBM_SETPOS                       = WM_USER + 2;

  PBM_DELTAPOS                     = WM_USER + 3;

  PBM_SETSTEP                      = WM_USER + 4;

  PBM_STEPIT                       = WM_USER + 5;

  PBM_SETRANGE32                   = WM_USER + 6; // lParam = high, wParam = low

  PBM_GETRANGE                     = WM_USER + 7; // lParam = PPBRange or Nil

  PBM_GETPOS                       = WM_USER + 8;

  PBM_SETBARCOLOR                  = WM_USER + 9; // lParam = bar color

//  CCM_FIRST                             = $2000; { Common control shared messages }

//  CCM_SETBKCOLOR                        = CCM_FIRST + 1; // lParam is bkColor
  PBM_SETBKCOLOR                   = CCM_SETBKCOLOR; // lParam = bkColor

  { CHARFORMAT masks }

const
{$EXTERNALSYM CFM_BOLD}
  CFM_BOLD                         = $00000001;
{$EXTERNALSYM CFM_ITALIC}
  CFM_ITALIC                       = $00000002;
{$EXTERNALSYM CFM_UNDERLINE}
  CFM_UNDERLINE                    = $00000004;
{$EXTERNALSYM CFM_STRIKEOUT}
  CFM_STRIKEOUT                    = $00000008;
{$EXTERNALSYM CFM_PROTECTED}
  CFM_PROTECTED                    = $00000010;
{$EXTERNALSYM CFM_LINK}
  CFM_LINK                         = $00000020; { Exchange hyperlink extension }
{$EXTERNALSYM CFM_SIZE}
  CFM_SIZE                         = $80000000;
{$EXTERNALSYM CFM_COLOR}
  CFM_COLOR                        = $40000000;
{$EXTERNALSYM CFM_FACE}
  CFM_FACE                         = $20000000;
{$EXTERNALSYM CFM_OFFSET}
  CFM_OFFSET                       = $10000000;
{$EXTERNALSYM CFM_CHARSET}
  CFM_CHARSET                      = $08000000;

  { CHARFORMAT effects }

{$EXTERNALSYM CFE_BOLD}
  CFE_BOLD                         = $0001;
{$EXTERNALSYM CFE_ITALIC}
  CFE_ITALIC                       = $0002;
{$EXTERNALSYM CFE_UNDERLINE}
  CFE_UNDERLINE                    = $0004;
{$EXTERNALSYM CFE_STRIKEOUT}
  CFE_STRIKEOUT                    = $0008;
{$EXTERNALSYM CFE_PROTECTED}
  CFE_PROTECTED                    = $0010;
{$EXTERNALSYM CFE_LINK}
  CFE_LINK                         = $0020;
{$EXTERNALSYM CFE_AUTOCOLOR}
  CFE_AUTOCOLOR                    = $40000000; { NOTE: this corresponds to CFM_COLOR, }
  { which controls it }
{$EXTERNALSYM yHeightCharPtsMost}
  yHeightCharPtsMost               = 1638;

  { EM_SETCHARFORMAT wParam masks }

{$EXTERNALSYM SCF_SELECTION}
  SCF_SELECTION                    = $0001;
{$EXTERNALSYM SCF_WORD}
  SCF_WORD                         = $0002;
{$EXTERNALSYM SCF_DEFAULT}
  SCF_DEFAULT                      = $0000; { set the default charformat or paraformat }
{$EXTERNALSYM SCF_ALL}
  SCF_ALL                          = $0004; { not valid with SCF_SELECTION or SCF_WORD }
{$EXTERNALSYM SCF_USEUIRULES}
  SCF_USEUIRULES                   = $0008; { modifier for SCF_SELECTION; says that }
  { the format came from a toolbar, etc. and }
  { therefore UI formatting rules should be }
  { used instead of strictly formatting the }
  { selection. }

  TBM_GETPOS                       = WM_USER;
  TBM_GETRANGEMIN                  = WM_USER + 1;
  TBM_GETRANGEMAX                  = WM_USER + 2;
  TBM_GETTIC                       = WM_USER + 3;
  TBM_SETTIC                       = WM_USER + 4;
  TBM_SETPOS                       = WM_USER + 5;
  TBM_SETRANGE                     = WM_USER + 6;
  TBM_SETRANGEMIN                  = WM_USER + 7;
  TBM_SETRANGEMAX                  = WM_USER + 8;
  TBM_CLEARTICS                    = WM_USER + 9;
  TBM_SETSEL                       = WM_USER + 10;
  TBM_SETSELSTART                  = WM_USER + 11;
  TBM_SETSELEND                    = WM_USER + 12;
  TBM_GETPTICS                     = WM_USER + 14;
  TBM_GETTICPOS                    = WM_USER + 15;
  TBM_GETNUMTICS                   = WM_USER + 16;
  TBM_GETSELSTART                  = WM_USER + 17;
  TBM_GETSELEND                    = WM_USER + 18;
  TBM_CLEARSEL                     = WM_USER + 19;
  TBM_SETTICFREQ                   = WM_USER + 20;
  TBM_SETPAGESIZE                  = WM_USER + 21;
  TBM_GETPAGESIZE                  = WM_USER + 22;
  TBM_SETLINESIZE                  = WM_USER + 23;
  TBM_GETLINESIZE                  = WM_USER + 24;
  TBM_GETTHUMBRECT                 = WM_USER + 25;
  TBM_GETCHANNELRECT               = WM_USER + 26;
  TBM_SETTHUMBLENGTH               = WM_USER + 27;
  TBM_GETTHUMBLENGTH               = WM_USER + 28;

  TB_LINEUP                        = 0;
  TB_LINEDOWN                      = 1;
  TB_PAGEUP                        = 2;
  TB_PAGEDOWN                      = 3;
  TB_THUMBPOSITION                 = 4;
  TB_THUMBTRACK                    = 5;
  TB_TOP                           = 6;
  TB_BOTTOM                        = 7;
  TB_ENDTRACK                      = 8;
{
type
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
    TLVItem = TLVItemA;
}

