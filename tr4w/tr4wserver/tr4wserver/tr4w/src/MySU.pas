unit MySU;

{$H+}
{$WARN SYMBOL_PLATFORM OFF}

interface

uses
{$IFDEF MSWINDOWS}
  Windows,
{$ENDIF}
{$IFDEF LINUX}
  Types,
  Libc,
{$ENDIF}
  SysConst;

const
   { File open modes }

{$IFDEF LINUX}
  fmOpenRead                            = O_RDONLY;
  fmOpenwrite                           = O_WRONLY;
  fmOpenReadWrite                       = O_RDWR;
   //  fmShareCompat not supported
  fmShareExclusive                      = $0010;
  fmShareDenyWrite                      = $0020;
   //  fmShareDenyRead  not supported
  fmShareDenyNone                       = $0030;
{$ENDIF}
{$IFDEF MSWINDOWS}
  fmOpenRead                            = $0000;
  fmOpenwrite                           = $0001;
  fmOpenReadWrite                       = $0002;

  fmShareCompat                         = $0000 platform; // DOS compatibility mode is not portable
  fmShareExclusive                      = $0010;
  fmShareDenyWrite                      = $0020;
  fmShareDenyRead                       = $0030 platform; // write-only not supported on all platforms
  fmShareDenyNone                       = $0040;
{$ENDIF}

   { File attribute constants }

  faReadOnly                            = $00000001 platform;
  faHidden                              = $00000002 platform;
  faSysFile                             = $00000004 platform;
  faVolumeID                            = $00000008 platform;
  faDirectory                           = $00000010;
  faArchive                             = $00000020 platform;
  faAnyFile                             = $0000003F;

   { Units of time }

  HoursPerDay                           = 24;
  MinsPerDay                            = HoursPerDay * 60;
  SecsPerDay                            = MinsPerDay * 60;
  MSecsPerDay                           = SecsPerDay * 1000;

   { Days between 1/1/0001 and 12/31/1899 }

  DateDelta                             = 693594;

   { Days between TDateTime basis (12/31/1899) and Unix time_t basis (1/1/1970) }

  UnixDateDelta                         = 25569;

type

   { Standard Character set type }

  TSysCharSet = set of Char;

   { Set access to an integer }

  TIntegerSet = set of 0..SizeOf(integer) * 8 - 1;

   { Type conversion records }

  WordRec = packed record
    case integer of
      0: (Lo, Hi: Byte);
      1: (Bytes: array[0..1] of Byte);
  end;

  LongRec = packed record
    case integer of
      0: (Lo, Hi: Word);
      1: (Words: array[0..1] of Word);
      2: (Bytes: array[0..3] of Byte);
  end;

  Int64Rec = packed record
    case integer of
      0: (Lo, Hi: Cardinal);
      1: (Cardinals: array[0..1] of Cardinal);
      2: (Words: array[0..3] of Word);
      3: (Bytes: array[0..7] of Byte);
  end;

   { General arrays }

  PByteArray = ^TByteArray;
  TByteArray = array[0..32767] of Byte;

  PWordArray = ^TWordArray;
  TWordArray = array[0..16383] of Word;

   { Generic procedure pointer }

  TProcedure = procedure;

   { Generic filename type }

  TFileName = type string;

   { Search record used by FindFirst, FindNext, and FindClose }

  TSearchRec = record
    Time: integer;
    Size: integer;
    Attr: integer;
    Name: TFileName;
    ExcludeAttr: integer;
{$IFDEF MSWINDOWS}
    FindHandle: THandle platform;
    finddata: TWin32FindData platform;
{$ENDIF}
{$IFDEF LINUX}
    Mode: mode_t platform;
    FindHandle: Pointer platform;
    PathOnly: string platform;
    Pattern: string platform;
{$ENDIF}
  end;

   { FloatToText, FloatToTextFmt, TextToFloat, and FloatToDecimal type codes }

  TFloatValue = (fvExtended, fvCurrency);

   { FloatToText format codes }

  TFloatFormat = (ffGeneral, ffExponent, FFFIXED, ffNumber, ffCurrency);

   { FloatToDecimal result record }

  TFloatRec = packed record
    Exponent: Smallint;
    Negative: boolean;
    Digits: array[0..20] of Char;
  end;

   { Date and time record }

  ttimestamp = record
    Time: integer; { Number of milliseconds since midnight }
    Date: integer; { One plus number of days since 1/1/0001 }
  end;

   { MultiByte Character Set (MBCS) byte type }
  TMbcsByteType = (mbSingleByte, mbLeadByte, mbTrailByte);

   { System Locale information record }
  TSysLocale = packed record
    DefaultLCID: integer;
    PriLangID: integer;
    SubLangID: integer;
    FarEast: boolean;
    MiddleEast: boolean;
  end;

{$IFDEF MSWINDOWS}
   { This is used by TLanguages }
  TLangRec = packed record
    fname: string;
    FLCID: LCID;
    fext: string;
  end;

   { This stores the languages that the system supports }
  TLanguages = class
  private
    FSysLangs: array of TLangRec;
    function LocalesCallback(LocaleID: PChar): integer; stdcall;
    function GetExt(Index: integer): string;
//    function GetID(Index: integer): string;
    function GetLCID(Index: integer): LCID;
    function GetName(Index: integer): string;
    function GetNameFromLocaleID(ID: LCID): string;
    function GetNameFromLCID(const ID: string): string;
    function GetCount: integer;
  public
    constructor Create;
    function IndexOf(ID: LCID): integer;
    property Count: integer read GetCount;
    property Name[Index: integer]: string read GetName;
    property NameFromLocaleID[ID: LCID]: string read GetNameFromLocaleID;
    property NameFromLCID[const ID: string]: string read GetNameFromLCID;
//    property ID[Index: integer]: string read GetID;
    property LocaleID[Index: integer]: LCID read GetLCID;
    property Ext[Index: integer]: string read GetExt;
  end platform;
{$ENDIF}

{$IFDEF LINUX}
  TEraRange = record
    StartDate: integer; // whole days since 12/31/1899 (TDateTime basis)
    EndDate: integer; // whole days since 12/31/1899 (TDateTime basis)
      //    Direction : Char;
  end;
{$ENDIF}

   { Exceptions }

  Exception = class(TObject)
  private
    FMessage: string;
    FHelpContext: integer;
  public
    constructor Create(const Msg: string);
//    constructor CreateFmt(const Msg: string; const Args: array of const);
    constructor CreateRes(Ident: integer); overload;
    constructor CreateRes(ResStringRec: PResStringRec); overload;
//    constructor CreateResFmt(Ident: integer; const Args: array of const); overload;
//    constructor CreateResFmt(ResStringRec: PResStringRec; const Args: array of const); overload;
    constructor CreateHelp(const Msg: string; AHelpContext: integer);
    constructor CreateFmtHelp(const Msg: string; const Args: array of const;
      AHelpContext: integer);
    constructor CreateResHelp(Ident: integer; AHelpContext: integer); overload;
    constructor CreateResHelp(ResStringRec: PResStringRec; AHelpContext: integer); overload;
    constructor CreateResFmtHelp(ResStringRec: PResStringRec; const Args: array of const;
      AHelpContext: integer); overload;
    constructor CreateResFmtHelp(Ident: integer; const Args: array of const;
      AHelpContext: integer); overload;
    property HelpContext: integer read FHelpContext write FHelpContext;
    property Message: string read FMessage write FMessage;
  end;

  ExceptClass = class of Exception;

  EAbort = class(Exception);

  EHeapException = class(Exception)
  private
    AllowFree: boolean;
  public
    procedure FreeInstance; override;
  end;

  EOutOfMemory = class(EHeapException);

  EInOutError = class(Exception)
  public
    ErrorCode: integer;
  end;

{$IFDEF MSWINDOWS}
  PExceptionRecord = ^TExceptionRecord;
  TExceptionRecord = record
    ExceptionCode: Cardinal;
    ExceptionFlags: Cardinal;
    ExceptionRecord: PExceptionRecord;
    ExceptionAddress: Pointer;
    NumberParameters: Cardinal;
    ExceptionInformation: array[0..14] of Cardinal;
  end;
{$ENDIF}

  EExternal = class(Exception)
  public
{$IFDEF MSWINDOWS}
    ExceptionRecord: PExceptionRecord platform;
{$ENDIF}
{$IFDEF LINUX}
    ExceptionAddress: LongWord platform;
    AccessAddress: LongWord platform;
    SignalNumber: integer platform;
{$ENDIF}
  end;

  EExternalException = class(EExternal);

  EIntError = class(EExternal);
  EDivByZero = class(EIntError);
  ERangeError = class(EIntError);
  EIntOverflow = class(EIntError);

  EMathError = class(EExternal);
  EInvalidOp = class(EMathError);
  EZeroDivide = class(EMathError);
  EOverflow = class(EMathError);
  EUnderflow = class(EMathError);

  EInvalidPointer = class(EHeapException);

  EInvalidCast = class(Exception);

  EConvertError = class(Exception);

  EAccessViolation = class(EExternal);
  EPrivilege = class(EExternal);
  EStackOverflow = class(EExternal)
  end deprecated;
  EControlC = class(EExternal);
{$IFDEF LINUX}
  EQuit = class(EExternal)
  end platform;
{$ENDIF}

  EVariantError = class(Exception);

  EPropReadOnly = class(Exception);
  EPropWriteOnly = class(Exception);

  EAssertionFailed = class(Exception);

{$IFNDEF PC_MAPPED_EXCEPTIONS}
  EAbstractError = class(Exception)
  end platform;
{$ENDIF}

  EIntfCastError = class(Exception);

  EInvalidContainer = class(Exception);
  EInvalidInsert = class(Exception);

  EPackageError = class(Exception);

  EOSError = class(Exception)
  public
    ErrorCode: DWORD;
  end;
{$IFDEF MSWINDOWS}
  EWin32Error = class(EOSError)
  end deprecated;
{$ENDIF}

  ESafecallException = class(Exception);

{$IFDEF LINUX}

   {
           Signals

       External exceptions, or signals, are, by default, converted to language
       exceptions by the Delphi RTL.  Under Linux, a Delphi application installs
       signal handlers to trap the raw signals, and convert them.  Delphi libraries
       do not install handlers by default.  So if you are implementing a standalone
       library, such as an Apache DSO, and you want to have signals converted to
       language exceptions that you can catch, you must install signal hooks
       manually, using the interfaces that the Delphi RTL provides.

       For most libraries, installing signal handlers is pretty
       straightforward.  Call HookSignal(RTL_SIGDEFAULT) at initialization time,
       and UnhookSignal(RTL_SIGNALDEFAULT) at shutdown.  This will install handlers
       for a set of signals that the RTL normally hooks for Delphi applications.

       There are some cases where the above initialization will not work properly:
       The proper behaviour for setting up signal handlers is to set
       a signal handler, and then later restore the signal handler to its previous
       state when you clean up.  If you have two libraries lib1 and lib2, and lib1
       installs a signal handler, and then lib2 installs a signal handler, those
       libraries have to uninstall in the proper order if they restore signal
       handlers, or the signal handlers can be left in an inconsistent and
       potentially fatal state.  Not all libraries behave well with respect to
       installing signal handlers.  To hedge against this possibility, and allow
       you to manage signal handlers better in the face of whatever behaviour
       you may find in external libraries, we provide a set of four interfaces to
       allow you to tailor the Delphi signal handler hooking/unhooking in the
       event of an emergency.  These are:
           InquireSignal
           AbandonSignalHandler
           HookSignal
           UnhookSignal

       InquireSignal allows you to look at the state of a signal handler, so
       that you can find out if someone grabbed it out from under you.

       AbandonSignalHandler tells the RTL never to unhook a particular
       signal handler.  This can be used if you find a case where it would
       be unsafe to return to the previous state of signal handling.  For
       example, if the previous signal handler was installed by a library
       which has since been unloaded.

       HookSignal/UnhookSignal setup signal handlers that map certain signals
       into language exceptions.

       See additional notes at InquireSignal, et al, below.
   }

const
  RTL_SIGINT                            = 0; // User interrupt (SIGINT)
  RTL_SIGFPE                            = 1; // Floating point exception (SIGFPE)
  RTL_SIGSEGV                           = 2; // Segmentation violation (SIGSEGV)
  RTL_SIGILL                            = 3; // Illegal instruction (SIGILL)
  RTL_SIGBUS                            = 4; // Bus error (SIGBUS)
  RTL_SIGQUIT                           = 5; // User interrupt (SIGQUIT)
  RTL_SIGLAST                           = RTL_SIGQUIT; // Used internally.  Don't use this.
  RTL_SIGDEFAULT                        = -1; // Means all of a set of signals that the we capture
   // normally.  This is currently all of the preceding
   // signals.  You cannot pass this to InquireSignal.

type
   { TSignalState is the state of a given signal handler, as returned by
     InquireSignal.  See InquireSignal, below.
   }
  TSignalState = (ssNotHooked, ssHooked, ssOverridden);

var

   {
     If DeferUserInterrupts is set, we do not raise either SIGINT or SIGQUIT as
     an exception, instead, we set SIGINTIssued or SIGQUITIssued when the
     signal arrives, and swallow the signal where the OS issued it.  This gives
     GUI applications the chance to defer the actual handling of the signal
     until a time when it is safe to do so.
   }

  DeferUserInterrupts                   : boolean;
  SIGINTIssued                          : boolean;
  SIGQUITIssued                         : boolean;
{$ENDIF}

{$IFDEF LINUX}
const
  MAX_PATH                              = 4095; //from /usr/include/linux/limits.h PATH_MAX
{$ENDIF}

var

   { Empty string and null string pointer. These constants are provided for
     backwards compatibility only.  }

  EmptyStr                              : string = '';
  NullStr                               : pSTRING = @EmptyStr;

  EmptyWideStr                          : WideString = '';
  NullWideStr                           : PWideString = @EmptyWideStr;

{$IFDEF MSWINDOWS}
   { Win32 platform identifier.  This will be one of the following values:

       VER_PLATFORM_WIN32s
       VER_PLATFORM_WIN32_WINDOWS
       VER_PLATFORM_WIN32_NT

     See WINDOWS.PAS for the numerical values. }

  Win32Platform                         : integer = 0;

   { Win32 OS version information -

     see TOSVersionInfo.dwMajorVersion/dwMinorVersion/dwBuildNumber }

  Win32MajorVersion                     : integer = 0;
  Win32MinorVersion                     : integer = 0;
  Win32BuildNumber                      : integer = 0;

   { Win32 OS extra version info string -

     see TOSVersionInfo.szCSDVersion }

  Win32CSDVersion                       : string = '';
{$ENDIF}

   { Currency and date/time formatting options

     The initial values of these variables are fetched from the system registry
     using the GetLocaleInfo function in the Win32 API. The description of each
     variable specifies the LOCALE_XXXX constant used to fetch the initial
     value.

     CurrencyString - Defines the currency symbol used in floating-point to
     decimal conversions. The initial value is fetched from LOCALE_SCURRENCY.

     CurrencyFormat - Defines the currency symbol placement and separation
     used in floating-point to decimal conversions. Possible values are:

       0 = '$1'
       1 = '1$'
       2 = '$ 1'
       3 = '1 $'

     The initial value is fetched from LOCALE_ICURRENCY.

     NegCurrFormat - Defines the currency format for used in floating-point to
     decimal conversions of negative numbers. Possible values are:

       0 = '($1)'      4 = '(1$)'      8 = '-1 $'      12 = '$ -1'
       1 = '-$1'       5 = '-1$'       9 = '-$ 1'      13 = '1- $'
       2 = '$-1'       6 = '1-$'      10 = '1 $-'      14 = '($ 1)'
       3 = '$1-'       7 = '1$-'      11 = '$ 1-'      15 = '(1 $)'

     The initial value is fetched from LOCALE_INEGCURR.

     ThousandSeparator - The character used to separate thousands in numbers
     with more than three digits to the left of the decimal separator. The
     initial value is fetched from LOCALE_STHOUSAND.  A value of #0 indicates
     no thousand separator character should be output even if the format string
     specifies thousand separators.

     DecimalSeparator - The character used to separate the integer part from
     the fractional part of a number. The initial value is fetched from
     LOCALE_SDECIMAL.  DecimalSeparator must be a non-zero value.

     CurrencyDecimals - The number of digits to the right of the decimal point
     in a currency amount. The initial value is fetched from LOCALE_ICURRDIGITS.

     DateSeparator - The character used to separate the year, month, and day
     parts of a date value. The initial value is fetched from LOCATE_SDATE.

     ShortDateFormat - The format string used to convert a date value to a
     short string suitable for editing. For a complete description of date and
     time format strings, refer to the documentation for the FormatDate
     function. The short date format should only use the date separator
     character and the  m, mm, d, dd, yy, and yyyy format specifiers. The
     initial value is fetched from LOCALE_SSHORTDATE.

     LongDateFormat - The format string used to convert a date value to a long
     string suitable for display but not for editing. For a complete description
     of date and time format strings, refer to the documentation for the
     FormatDate function. The initial value is fetched from LOCALE_SLONGDATE.

     TimeSeparator - The character used to separate the hour, minute, and
     second parts of a time value. The initial value is fetched from
     LOCALE_STIME.

     TimeAMString - The suffix string used for time values between 00:00 and
     11:59 in 12-hour clock format. The initial value is fetched from
     LOCALE_S1159.

     TimePMString - The suffix string used for time values between 12:00 and
     23:59 in 12-hour clock format. The initial value is fetched from
     LOCALE_S2359.

     ShortTimeFormat - The format string used to convert a time value to a
     short string with only hours and minutes. The default value is computed
     from LOCALE_ITIME and LOCALE_ITLZERO.

     LongTimeFormat - The format string used to convert a time value to a long
     string with hours, minutes, and seconds. The default value is computed
     from LOCALE_ITIME and LOCALE_ITLZERO.

     ShortMonthNames - Array of strings containing short month names. The mmm
     format specifier in a format string passed to FormatDate causes a short
     month name to be substituted. The default values are fecthed from the
     LOCALE_SABBREVMONTHNAME system locale entries.

     LongMonthNames - Array of strings containing long month names. The mmmm
     format specifier in a format string passed to FormatDate causes a long
     month name to be substituted. The default values are fecthed from the
     LOCALE_SMONTHNAME system locale entries.

     ShortDayNames - Array of strings containing short day names. The ddd
     format specifier in a format string passed to FormatDate causes a short
     day name to be substituted. The default values are fecthed from the
     LOCALE_SABBREVDAYNAME system locale entries.

     LongDayNames - Array of strings containing long day names. The dddd
     format specifier in a format string passed to FormatDate causes a long
     day name to be substituted. The default values are fecthed from the
     LOCALE_SDAYNAME system locale entries.

     ListSeparator - The character used to separate items in a list.  The
     initial value is fetched from LOCALE_SLIST.

     TwoDigitYearCenturyWindow - Determines what century is added to two
     digit years when converting string dates to numeric dates.  This value
     is subtracted from the current year before extracting the century.
     This can be used to extend the lifetime of existing applications that
     are inextricably tied to 2 digit year data entry.  The best solution
     to Year 2000 (Y2k) issues is not to accept 2 digit years at all - require
     4 digit years in data entry to eliminate century ambiguities.

     Examples:

     Current TwoDigitCenturyWindow  Century  StrToDate() of:
     Year    Value                  Pivot    '01/01/03' '01/01/68' '01/01/50'
     -------------------------------------------------------------------------
     1998    0                      1900     1903       1968       1950
     2002    0                      2000     2003       2068       2050
     1998    50 (default)           1948     2003       1968       1950
     2002    50 (default)           1952     2003       1968       2050
     2020    50 (default)           1970     2003       2068       2050
    }

var
  CurrencyString                        : string;
  CurrencyFormat                        : Byte;
  NegCurrFormat                         : Byte;
  ThousandSeparator                     : Char;
  DecimalSeparator                      : Char;
  CurrencyDecimals                      : Byte;
  DateSeparator                         : Char;
  ShortDateFormat                       : string;
  LongDateFormat                        : string;
  TimeSeparator                         : Char;
  TimeAMString                          : string;
  TimePMString                          : string;
  ShortTimeFormat                       : string;
  longTimeFormat                        : string;
  ShortMonthNames                       : array[1..12] of string;
  LongMonthNames                        : array[1..12] of string;
  ShortDayNames                         : array[1..7] of string;
  LongDayNames                          : array[1..7] of string;
  SysLocale                             : TSysLocale;
  TwoDigitYearCenturyWindow             : Word = 50;
  ListSeparator                         : Char;

const
  MaxEraCount                           = 7;

var
  EraNames                              : array[1..MaxEraCount] of string;
  EraYearOffsets                        : array[1..MaxEraCount] of integer;
{$IFDEF LINUX}
  EraRanges                             : array[1..MaxEraCount] of TEraRange platform;
  EraYearFormats                        : array[1..MaxEraCount] of string platform;
  EraCount                              : Byte platform;
{$ENDIF}

const
  PathDelim                             = {$IFDEF MSWINDOWS} '\';
{$ELSE} '/';
{$ENDIF}
  DriveDelim                            = {$IFDEF MSWINDOWS} ':';
{$ELSE} '';
{$ENDIF}
  PathSep                               = {$IFDEF MSWINDOWS} ';';
{$ELSE} ':';
{$ENDIF}

{$IFDEF MSWINDOWS}
function Languages: TLanguages;
{$ENDIF}

{ Memory management routines }

{ AllocMem allocates a block of the given size on the heap. Each byte in
  the allocated buffer is set to zero. To dispose the buffer, use the
  FreeMem standard procedure. }

function AllocMem(Size: Cardinal): Pointer;

{ Exit procedure handling }

{ AddExitProc adds the given procedure to the run-time library's exit
  procedure list. When an application terminates, its exit procedures are
  executed in reverse order of definition, i.e. the last procedure passed
  to AddExitProc is the first one to get executed upon termination. }

procedure AddExitProc(Proc: TProcedure);

{ String handling routines }

{ NewStr allocates a string on the heap. NewStr is provided for backwards
  compatibility only. }

function NewStr(const s: string): pSTRING;
deprecated;

{ DisposeStr disposes a string pointer that was previously allocated using
  NewStr. DisposeStr is provided for backwards compatibility only. }

procedure DisposeStr(p: pSTRING);
deprecated;

{ AssignStr assigns a new dynamically allocated string to the given string
  pointer. AssignStr is provided for backwards compatibility only. }

procedure AssignStr(var p: pSTRING; const s: string);
deprecated;

{ AppendStr appends S to the end of Dest. AppendStr is provided for
  backwards compatibility only. Use "Dest := Dest + S" instead. }

procedure AppendStr(var Dest: string; const s: string);
deprecated;

{ UpperCase converts all ASCII characters in the given string to upper case.
  The conversion affects only 7-bit ASCII characters between 'a' and 'z'. To
  convert 8-bit international characters, use AnsiUpperCase. }

function UpperCase(const s: string): string;

{ LowerCase converts all ASCII characters in the given string to lower case.
  The conversion affects only 7-bit ASCII characters between 'A' and 'Z'. To
  convert 8-bit international characters, use AnsiLowerCase. }

function LowerCase(const s: string): string;

{ CompareStr compares S1 to S2, with case-sensitivity. The return value is
  less than 0 if S1 < S2, 0 if S1 = S2, or greater than 0 if S1 > S2. The
  compare operation is based on the 8-bit ordinal value of each character
  and is not affected by the current user locale. }

function CompareStr(const s1, s2: string): integer;

{ CompareMem performs a binary compare of Length bytes of memory referenced
  by P1 to that of P2.  CompareMem returns True if the memory referenced by
  P1 is identical to that of P2. }

function CompareMem(P1, P2: Pointer; length: integer): boolean; assembler;

{ CompareText compares S1 to S2, without case-sensitivity. The return value
  is the same as for CompareStr. The compare operation is based on the 8-bit
  ordinal value of each character, after converting 'a'..'z' to 'A'..'Z',
  and is not affected by the current user locale. }

function CompareText(const s1, s2: string): integer;

{ SameText compares S1 to S2, without case-sensitivity. Returns true if
  S1 and S2 are the equal, that is, if CompareText would return 0. SameText
  has the same 8-bit limitations as CompareText }

function SameText(const s1, s2: string): boolean;

{ AnsiUpperCase converts all characters in the given string to upper case.
  The conversion uses the current user locale. }

function AnsiUpperCase(const s: string): string;

{ AnsiLowerCase converts all characters in the given string to lower case.
  The conversion uses the current user locale. }

function AnsiLowerCase(const s: string): string;

{ AnsiCompareStr compares S1 to S2, with case-sensitivity. The compare
  operation is controlled by the current user locale. The return value
  is the same as for CompareStr. }

function AnsiCompareStr(const s1, s2: string): integer;

{ AnsiSameStr compares S1 to S2, with case-sensitivity. The compare
  operation is controlled by the current user locale. The return value
  is True if AnsiCompareStr would have returned 0. }

function AnsiSameStr(const s1, s2: string): boolean;

{ AnsiCompareText compares S1 to S2, without case-sensitivity. The compare
  operation is controlled by the current user locale. The return value
  is the same as for CompareStr. }

function AnsiCompareText(const s1, s2: string): integer;

{ AnsiSameText compares S1 to S2, without case-sensitivity. The compare
  operation is controlled by the current user locale. The return value
  is True if AnsiCompareText would have returned 0. }

function AnsiSameText(const s1, s2: string): boolean;

{ AnsiStrComp compares S1 to S2, with case-sensitivity. The compare
  operation is controlled by the current user locale. The return value
  is the same as for CompareStr. }

function AnsiStrComp(s1, s2: PChar): integer;

{ AnsiStrIComp compares S1 to S2, without case-sensitivity. The compare
  operation is controlled by the current user locale. The return value
  is the same as for CompareStr. }

function AnsiStrIComp(s1, s2: PChar): integer;

{ AnsiStrLComp compares S1 to S2, with case-sensitivity, up to a maximum
  length of MaxLen bytes. The compare operation is controlled by the
  current user locale. The return value is the same as for CompareStr. }

function AnsiStrLComp(s1, s2: PChar; MaxLen: Cardinal): integer;

{ AnsiStrLIComp compares S1 to S2, without case-sensitivity, up to a maximum
  length of MaxLen bytes. The compare operation is controlled by the
  current user locale. The return value is the same as for CompareStr. }

function AnsiStrLIComp(s1, s2: PChar; MaxLen: Cardinal): integer;

{ AnsiStrLower converts all characters in the given string to lower case.
  The conversion uses the current user locale. }

function AnsiStrLower(Str: PChar): PChar;

{ AnsiStrUpper converts all characters in the given string to upper case.
  The conversion uses the current user locale. }

function AnsiStrUpper(Str: PChar): PChar;

{ AnsiLastChar returns a pointer to the last full character in the string.
  This function supports multibyte characters  }

function AnsiLastChar(const s: string): PChar;

{ AnsiStrLastChar returns a pointer to the last full character in the string.
  This function supports multibyte characters.  }

function AnsiStrLastChar(p: PChar): PChar;

{ WideUpperCase converts all characters in the given string to upper case. }

function WideUpperCase(const s: WideString): WideString;

{ WideLowerCase converts all characters in the given string to lower case. }

function WideLowerCase(const s: WideString): WideString;

{ WideCompareStr compares S1 to S2, with case-sensitivity. The return value
  is the same as for CompareStr. }

function WideCompareStr(const s1, s2: WideString): integer;

{ WideSameStr compares S1 to S2, with case-sensitivity. The return value
  is True if WideCompareStr would have returned 0. }

function WideSameStr(const s1, s2: WideString): boolean;

{ WideCompareText compares S1 to S2, without case-sensitivity. The return value
  is the same as for CompareStr. }

function WideCompareText(const s1, s2: WideString): integer;

{ WideSameText compares S1 to S2, without case-sensitivity. The return value
  is True if WideCompareText would have returned 0. }

function WideSameText(const s1, s2: WideString): boolean;

{ Trim trims leading and trailing spaces and control characters from the
  given string. }

function trim(const s: string): string; overload;
function trim(const s: WideString): WideString; overload;

{ TrimLeft trims leading spaces and control characters from the given
  string. }

function TrimLeft(const s: string): string; overload;
function TrimLeft(const s: WideString): WideString; overload;

{ TrimRight trims trailing spaces and control characters from the given
  string. }

function TrimRight(const s: string): string; overload;
function TrimRight(const s: WideString): WideString; overload;

{ QuotedStr returns the given string as a quoted string. A single quote
  character is inserted at the beginning and the end of the string, and
  for each single quote character in the string, another one is added. }

function QuotedStr(const s: string): string;

{ AnsiQuotedStr returns the given string as a quoted string, using the
  provided Quote character.  A Quote character is inserted at the beginning
  and end of the string, and each Quote character in the string is doubled.
  This function supports multibyte character strings (MBCS). }

function AnsiQuotedStr(const s: string; Quote: Char): string;

{ AnsiExtractQuotedStr removes the Quote characters from the beginning and end
  of a quoted string, and reduces pairs of Quote characters within the quoted
  string to a single character. If the first character in Src is not the Quote
  character, the function returns an empty string.  The function copies
  characters from the Src to the result string until the second solitary
  Quote character or the first null character in Src. The Src parameter is
  updated to point to the first character following the quoted string.  If
  the Src string does not contain a matching end Quote character, the Src
  parameter is updated to point to the terminating null character in Src.
  This function supports multibyte character strings (MBCS).  }

function AnsiExtractQuotedStr(var Src: PChar; Quote: Char): string;

{ AnsiDequotedStr is a simplified version of AnsiExtractQuotedStr }

function AnsiDequotedStr(const s: string; AQuote: Char): string;

{ AdjustLineBreaks adjusts all line breaks in the given string to the
  indicated style.
  When Style is tlbsCRLF, the function changes all
  CR characters not followed by LF and all LF characters not preceded
  by a CR into CR/LF pairs.
  When Style is tlbsLF, the function changes all CR/LF pairs and CR characters
  not followed by LF to LF characters. }

function AdjustLineBreaks(const s: string; Style: TTextLineBreakStyle =
{$IFDEF LINUX}tlbsLF{$ENDIF}
{$IFDEF MSWINDOWS}tlbsCRLF{$ENDIF}): string;

{ IsValidIdent returns true if the given string is a valid identifier. An
  identifier is defined as a character from the set ['A'..'Z', 'a'..'z', '_']
  followed by zero or more characters from the set ['A'..'Z', 'a'..'z',
  '0..'9', '_']. }

function IsValidIdent(const Ident: string): boolean;

{ IntToStr converts the given value to its decimal string representation. }




{ IntToHex converts the given value to a hexadecimal string representation
  with the minimum number of digits specified. }




{ StrToInt converts the given string to an integer value. If the string
  doesn't contain a valid value, an EConvertError exception is raised. }

function StrToInt(const s: string): integer;
function StrToIntDef(const s: string; Default: integer): integer;
function TryStrToInt(const s: string; out Value: integer): boolean;

{ Similar to the above functions but for Int64 instead }

function StrToInt64(const s: string): int64;
function StrToInt64Def(const s: string; const Default: int64): int64;
function TryStrToInt64(const s: string; out Value: int64): boolean;

{ StrToBool converts the given string to a boolean value.  If the string
  doesn't contain a valid value, an EConvertError exception is raised.
  BoolToStr converts boolean to a string value that in turn can be converted
  back into a boolean.  BoolToStr will always pick the first element of
  the TrueStrs/FalseStrs arrays. }

var
  TrueBoolStrs                          : array of string;
  FalseBoolStrs                         : array of string;

const
  DefaultTrueBoolStr                    = 'True'; // DO NOT LOCALIZE
  DefaultFalseBoolStr                   = 'False'; // DO NOT LOCALIZE

function StrToBool(const s: string): boolean;
function StrToBoolDef(const s: string; const Default: boolean): boolean;
function TryStrToBool(const s: string; out Value: boolean): boolean;

function BoolToStr(b: boolean; UseBoolStrs: boolean = False): string;

{ LoadStr loads the string resource given by Ident from the application's
  executable file or associated resource module. If the string resource
  does not exist, LoadStr returns an empty string. }

function LoadStr(Ident: integer): string;

{ FmtLoadStr loads the string resource given by Ident from the application's
  executable file or associated resource module, and uses it as the format
  string in a call to the Format function with the given arguments. }



{ File management routines }

{ FileOpen opens the specified file using the specified access mode. The
  access mode value is constructed by OR-ing one of the fmOpenXXXX constants
  with one of the fmShareXXXX constants. If the return value is positive,
  the function was successful and the value is the file handle of the opened
  file. A return value of -1 indicates that an error occurred. }

function FileOpen(const FileName: string; Mode: LongWord): integer;

{ FileCreate creates a new file by the specified name. If the return value
  is positive, the function was successful and the value is the file handle
  of the new file. A return value of -1 indicates that an error occurred.
  On Linux, this calls FileCreate(FileName, DEFFILEMODE) to create
  the file with read and write access for the current user only.  }

function FileCreate(const FileName: string): integer; overload;

{ This second version of FileCreate lets you specify the access rights to put on the newly
  created file.  The access rights parameter is ignored on Win32 }

function FileCreate(const FileName: string; Rights: integer): integer; overload;

{ FileRead reads Count bytes from the file given by Handle into the buffer
  specified by Buffer. The return value is the number of bytes actually
  read; it is less than Count if the end of the file was reached. The return
  value is -1 if an error occurred. }

function FileRead(Handle: integer; var Buffer; Count: LongWord): integer;

{ FileWrite writes Count bytes to the file given by Handle from the buffer
  specified by Buffer. The return value is the number of bytes actually
  written, or -1 if an error occurred. }

function FileWrite(Handle: integer; const Buffer; Count: LongWord): integer;

{ FileSeek changes the current position of the file given by Handle to be
  Offset bytes relative to the point given by Origin. Origin = 0 means that
  Offset is relative to the beginning of the file, Origin = 1 means that
  Offset is relative to the current position, and Origin = 2 means that
  Offset is relative to the end of the file. The return value is the new
  current position, relative to the beginning of the file, or -1 if an error
  occurred. }

function FileSeek(Handle, Offset, Origin: integer): integer; overload;
function FileSeek(Handle: integer; const Offset: int64; Origin: integer): int64; overload;

{ FileClose closes the specified file. }

procedure FileClose(Handle: integer);

{ FileAge returns the date-and-time stamp of the specified file. The return
  value can be converted to a TDateTime value using the FileDateToDateTime
  function. The return value is -1 if the file does not exist. }

function FileAge(const FileName: string): integer;

{ FileExists returns a boolean value that indicates whether the specified
  file exists. }

function FileExists(const FileName: string): boolean;

{ DirectoryExists returns a boolean value that indicates whether the
  specified directory exists (and is actually a directory) }

function DirectoryExists(const Directory: string): boolean;

{ ForceDirectories ensures that all the directories in a specific path exist.
  Any portion that does not already exist will be created.  Function result
  indicates success of the operation.  The function can fail if the current
  user does not have sufficient file access rights to create directories in
  the given path.  }

function ForceDirectories(dir: string): boolean;

{ FindFirst searches the directory given by Path for the first entry that
  matches the filename given by Path and the attributes given by Attr. The
  result is returned in the search record given by SearchRec. The return
  value is zero if the function was successful. Otherwise the return value
  is a system error code. After calling FindFirst, always call FindClose.
  FindFirst is typically used with FindNext and FindClose as follows:

    Result := FindFirst(Path, Attr, SearchRec);
    while Result = 0 do
    begin
      ProcessSearchRec(SearchRec);
      Result := FindNext(SearchRec);
    end;
    FindClose(SearchRec);

  where ProcessSearchRec represents user-defined code that processes the
  information in a search record. }

function FindFirst(const Path: string; Attr: integer;
  var f: TSearchRec): integer;

{ FindNext returs the next entry that matches the name and attributes
  specified in a previous call to FindFirst. The search record must be one
  that was passed to FindFirst. The return value is zero if the function was
  successful. Otherwise the return value is a system error code. }

function FindNext(var f: TSearchRec): integer;

{ FindClose terminates a FindFirst/FindNext sequence and frees memory and system
  resources allocated by FindFirst.
  Every FindFirst/FindNext must end with a call to FindClose. }

procedure FindClose(var f: TSearchRec);

{ FileGetDate returns the DOS date-and-time stamp of the file given by
  Handle. The return value is -1 if the handle is invalid. The
  FileDateToDateTime function can be used to convert the returned value to
  a TDateTime value. }

function FileGetDate(Handle: integer): integer;

{ FileSetDate sets the DOS date-and-time stamp of the file given by FileName
  to the value given by Age. The DateTimeToFileDate function can be used to
  convert a TDateTime value to a DOS date-and-time stamp. The return value
  is zero if the function was successful. Otherwise the return value is a
  system error code.        }

function FileSetDate(const FileName: string; Age: integer): integer; overload;

{$IFDEF MSWINDOWS}
{  FileSetDate by handle is not available on Unix platforms because there
  is no standard way to set a file's modification time using only a file
  handle, and no standard way to obtain the file name of an open
  file handle.  }

function FileSetDate(Handle: integer; Age: integer): integer; overload;
platform;

{ FileGetAttr returns the file attributes of the file given by FileName. The
  attributes can be examined by AND-ing with the faXXXX constants defined
  above. A return value of -1 indicates that an error occurred. }

function FileGetAttr(const FileName: string): integer;
platform;

{ FileSetAttr sets the file attributes of the file given by FileName to the
  value given by Attr. The attribute value is formed by OR-ing the
  appropriate faXXXX constants. The return value is zero if the function was
  successful. Otherwise the return value is a system error code. }

function FileSetAttr(const FileName: string; Attr: integer): integer;
platform;
{$ENDIF}

{ FileIsReadOnly tests whether a given file is read-only for the current
  process and effective user id.  If the file does not exist, the
  function returns False.  (Check FileExists before calling FileIsReadOnly)
  This function is platform portable. }

function FileIsReadOnly(const FileName: string): boolean;

{ FileSetReadOnly sets the read only state of a file.  The file must
  exist and the current effective user id must be the owner of the file.
  On Unix systems, FileSetReadOnly attempts to set or remove
  all three (user, group, and other) write permissions on the file.
  If you want to grant partial permissions (writeable for owner but not
  for others), use platform specific functions such as chmod.
  The function returns True if the file was successfully modified,
  False if there was an error.  This function is platform portable.  }

function FileSetReadOnly(const FileName: string; ReadOnly: boolean): boolean;

{ DeleteFile deletes the file given by FileName. The return value is True if
  the file was successfully deleted, or False if an error occurred. }

function DeleteFile(const FileName: string): boolean;

{ RenameFile renames the file given by OldName to the name given by NewName.
  The return value is True if the file was successfully renamed, or False if
  an error occurred. }

function RenameFile(const OldName, NewName: string): boolean;

{ ChangeFileExt changes the extension of a filename. FileName specifies a
  filename with or without an extension, and Extension specifies the new
  extension for the filename. The new extension can be a an empty string or
  a period followed by up to three characters. }

function changeFileExt(const FileName, Extension: string): string;

{ ExtractFilePath extracts the drive and directory parts of the given
  filename. The resulting string is the leftmost characters of FileName,
  up to and including the colon or backslash that separates the path
  information from the name and extension. The resulting string is empty
  if FileName contains no drive and directory parts. }

function ExtractFilePath(const FileName: string): string;

{ ExtractFileDir extracts the drive and directory parts of the given
  filename. The resulting string is a directory name suitable for passing
  to SetCurrentDir, CreateDir, etc. The resulting string is empty if
  FileName contains no drive and directory parts. }

function ExtractFileDir(const FileName: string): string;

{ ExtractFileDrive extracts the drive part of the given filename.  For
  filenames with drive letters, the resulting string is '<drive>:'.
  For filenames with a UNC path, the resulting string is in the form
  '\\<servername>\<sharename>'.  If the given path contains neither
  style of filename, the result is an empty string. }

function ExtractFileDrive(const FileName: string): string;

{ ExtractFileName extracts the name and extension parts of the given
  filename. The resulting string is the leftmost characters of FileName,
  starting with the first character after the colon or backslash that
  separates the path information from the name and extension. The resulting
  string is equal to FileName if FileName contains no drive and directory
  parts. }

function extractfilename(const FileName: string): string;

{ ExtractFileExt extracts the extension part of the given filename. The
  resulting string includes the period character that separates the name
  and extension parts. The resulting string is empty if the given filename
  has no extension. }

function ExtractFileExt(const FileName: string): string;

{ ExpandFileName expands the given filename to a fully qualified filename.
  The resulting string consists of a drive letter, a colon, a root relative
  directory path, and a filename. Embedded '.' and '..' directory references
  are removed. }

function ExpandFileName(const FileName: string): string;

{ ExpandFilenameCase returns a fully qualified filename like ExpandFilename,
  but performs a case-insensitive filename search looking for a close match
  in the actual file system, differing only in uppercase versus lowercase of
  the letters.  This is useful to convert lazy user input into useable file
  names, or to convert filename data created on a case-insensitive file
  system (Win32) to something useable on a case-sensitive file system (Linux).

  The MatchFound out parameter indicates what kind of match was found in the
  file system, and what the function result is based upon:

  ( in order of increasing difficulty or complexity )
  mkExactMatch:  Case-sensitive match.  Result := ExpandFileName(FileName).
  mkSingleMatch: Exactly one file in the given directory path matches the
        given filename on a case-insensitive basis.
        Result := ExpandFileName(FileName as found in file system).
  mkAmbiguous: More than one file in the given directory path matches the
        given filename case-insensitively.
        In many cases, this should be considered an error.
        Result := ExpandFileName(First matching filename found).
  mkNone:  File not found at all.  Result := ExpandFileName(FileName).

  Note that because this function has to search the file system it may be
  much slower than ExpandFileName, particularly when the given filename is
  ambiguous or does not exist.  Use ExpandFilenameCase only when you have
  a filename of dubious orgin - such as from user input - and you want
  to make a best guess before failing.  }

type
  TFilenameCaseMatch = (mkNone, mkExactMatch, mkSingleMatch, mkAmbiguous);

function ExpandFileNameCase(const FileName: string;
  out MatchFound: TFilenameCaseMatch): string;

{ ExpandUNCFileName expands the given filename to a fully qualified filename.
  This function is the same as ExpandFileName except that it will return the
  drive portion of the filename in the format '\\<servername>\<sharename> if
  that drive is actually a network resource instead of a local resource.
  Like ExpandFileName, embedded '.' and '..' directory references are
  removed. }

function ExpandUNCFileName(const FileName: string): string;

{ ExtractRelativePath will return a file path name relative to the given
  BaseName.  It strips the common path dirs and adds '..\' for each level
  up from the BaseName path. }

function ExtractRelativePath(const BaseName, DestName: string): string;

{$IFDEF MSWINDOWS}
{ ExtractShortPathName will convert the given filename to the short form
  by calling the GetShortPathName API.  Will return an empty string if
  the file or directory specified does not exist }

function ExtractShortPathName(const FileName: string): string;
{$ENDIF}

{ FileSearch searches for the file given by Name in the list of directories
  given by DirList. The directory paths in DirList must be separated by
  semicolons. The search always starts with the current directory of the
  current drive. The returned value is a concatenation of one of the
  directory paths and the filename, or an empty string if the file could not
  be located. }

function FileSearch(const Name, DirList: string): string;

{$IFDEF MSWINDOWS}
{ DiskFree returns the number of free bytes on the specified drive number,
  where 0 = Current, 1 = A, 2 = B, etc. DiskFree returns -1 if the drive
  number is invalid. }

function DiskFree(Drive: Byte): int64;

{ DiskSize returns the size in bytes of the specified drive number, where
  0 = Current, 1 = A, 2 = B, etc. DiskSize returns -1 if the drive number
  is invalid. }

function DiskSize(Drive: Byte): int64;
{$ENDIF}

{ FileDateToDateTime converts a DOS date-and-time value to a TDateTime
  value. The FileAge, FileGetDate, and FileSetDate routines operate on DOS
  date-and-time values, and the Time field of a TSearchRec used by the
  FindFirst and FindNext functions contains a DOS date-and-time value. }

function FileDateToDateTime(FileDate: integer): TDateTime;

{ DateTimeToFileDate converts a TDateTime value to a DOS date-and-time
  value. The FileAge, FileGetDate, and FileSetDate routines operate on DOS
  date-and-time values, and the Time field of a TSearchRec used by the
  FindFirst and FindNext functions contains a DOS date-and-time value. }

function DateTimeToFileDate(DateTime: TDateTime): integer;

{ GetCurrentDir returns the current directory. }

function GetCurrentDir: string;

{ SetCurrentDir sets the current directory. The return value is True if
  the current directory was successfully changed, or False if an error
  occurred. }

function SetCurrentDir(const dir: string): boolean;

{ CreateDir creates a new directory. The return value is True if a new
  directory was successfully created, or False if an error occurred. }

function createdir(const dir: string): boolean;

{ RemoveDir deletes an existing empty directory. The return value is
  True if the directory was successfully deleted, or False if an error
  occurred. }

function RemoveDir(const dir: string): boolean;

{ PChar routines }
{ const params help simplify C++ code.  No effect on pascal code }

{ StrLen returns the number of characters in Str, not counting the null
  terminator. }

function StrLen(const Str: PChar): Cardinal;

{ StrEnd returns a pointer to the null character that terminates Str. }

function StrEnd(const Str: PChar): PChar;

{ StrMove copies exactly Count characters from Source to Dest and returns
  Dest. Source and Dest may overlap. }

function StrMove(Dest: PChar; const Source: PChar; Count: Cardinal): PChar;

{ StrCopy copies Source to Dest and returns Dest. }

function StrCopy(Dest: PChar; const Source: PChar): PChar;

{ StrECopy copies Source to Dest and returns StrEnd(Dest). }

function StrECopy(Dest: PChar; const Source: PChar): PChar;

{ StrLCopy copies at most MaxLen characters from Source to Dest and
  returns Dest. }

function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar;

{ StrPCopy copies the Pascal style string Source into Dest and
  returns Dest. }

function StrPCopy(Dest: PChar; const Source: string): PChar;

{ StrPLCopy copies at most MaxLen characters from the Pascal style string
  Source into Dest and returns Dest. }

function StrPLCopy(Dest: PChar; const Source: string;
  MaxLen: Cardinal): PChar;

{ StrCat appends a copy of Source to the end of Dest and returns Dest. }

function StrCat(Dest: PChar; const Source: PChar): PChar;

{ StrLCat appends at most MaxLen - StrLen(Dest) characters from Source to
  the end of Dest, and returns Dest. }

function StrLCat(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar;

{ StrComp compares Str1 to Str2. The return value is less than 0 if
  Str1 < Str2, 0 if Str1 = Str2, or greater than 0 if Str1 > Str2. }

function StrComp(const Str1, Str2: PChar): integer;

{ StrIComp compares Str1 to Str2, without case sensitivity. The return
  value is the same as StrComp. }

function StrIComp(const Str1, Str2: PChar): integer;

{ StrLComp compares Str1 to Str2, for a maximum length of MaxLen
  characters. The return value is the same as StrComp. }

function StrLComp(const Str1, Str2: PChar; MaxLen: Cardinal): integer;

{ StrLIComp compares Str1 to Str2, for a maximum length of MaxLen
  characters, without case sensitivity. The return value is the same
  as StrComp. }

function StrLIComp(const Str1, Str2: PChar; MaxLen: Cardinal): integer;

{ StrScan returns a pointer to the first occurrence of Chr in Str. If Chr
  does not occur in Str, StrScan returns NIL. The null terminator is
  considered to be part of the string. }

function StrScan(const Str: PChar; CHR: Char): PChar;

{ StrRScan returns a pointer to the last occurrence of Chr in Str. If Chr
  does not occur in Str, StrRScan returns NIL. The null terminator is
  considered to be part of the string. }

function StrRScan(const Str: PChar; CHR: Char): PChar;

{ StrPos returns a pointer to the first occurrence of Str2 in Str1. If
  Str2 does not occur in Str1, StrPos returns NIL. }

function StrPos(const Str1, Str2: PChar): PChar;

{ StrUpper converts Str to upper case and returns Str. }

function StrUpper(Str: PChar): PChar;

{ StrLower converts Str to lower case and returns Str. }

function StrLower(Str: PChar): PChar;

{ StrPas converts Str to a Pascal style string. This function is provided
  for backwards compatibility only. To convert a null terminated string to
  a Pascal style string, use a string type cast or an assignment. }

function StrPas(const Str: PChar): string;

{ StrAlloc allocates a buffer of the given size on the heap. The size of
  the allocated buffer is encoded in a four byte header that immediately
  preceeds the buffer. To dispose the buffer, use StrDispose. }

function StrAlloc(Size: Cardinal): PChar;

{ StrBufSize returns the allocated size of the given buffer, not including
  the two byte header. }

function StrBufSize(const Str: PChar): Cardinal;

{ StrNew allocates a copy of Str on the heap. If Str is NIL, StrNew returns
  NIL and doesn't allocate any heap space. Otherwise, StrNew makes a
  duplicate of Str, obtaining space with a call to the StrAlloc function,
  and returns a pointer to the duplicated string. To dispose the string,
  use StrDispose. }

function StrNew(const Str: PChar): PChar;

{ StrDispose disposes a string that was previously allocated with StrAlloc
  or StrNew. If Str is NIL, StrDispose does nothing. }

procedure StrDispose(Str: PChar);

{ String formatting routines }

{ The Format routine formats the argument list given by the Args parameter
  using the format string given by the Format parameter.

  Format strings contain two types of objects--plain characters and format
  specifiers. Plain characters are copied verbatim to the resulting string.
  Format specifiers fetch arguments from the argument list and apply
  formatting to them.

  Format specifiers have the following form:

    "%" [index ":"] ["-"] [width] ["." prec] type

  A format specifier begins with a % character. After the % come the
  following, in this order:

  -  an optional argument index specifier, [index ":"]
  -  an optional left-justification indicator, ["-"]
  -  an optional width specifier, [width]
  -  an optional precision specifier, ["." prec]
  -  the conversion type character, type

  The following conversion characters are supported:

  d  Decimal. The argument must be an integer value. The value is converted
     to a string of decimal digits. If the format string contains a precision
     specifier, it indicates that the resulting string must contain at least
     the specified number of digits; if the value has less digits, the
     resulting string is left-padded with zeros.

  u  Unsigned decimal.  Similar to 'd' but no sign is output.

  e  Scientific. The argument must be a floating-point value. The value is
     converted to a string of the form "-d.ddd...E+ddd". The resulting
     string starts with a minus sign if the number is negative, and one digit
     always precedes the decimal point. The total number of digits in the
     resulting string (including the one before the decimal point) is given
     by the precision specifer in the format string--a default precision of
     15 is assumed if no precision specifer is present. The "E" exponent
     character in the resulting string is always followed by a plus or minus
     sign and at least three digits.

  f  Fixed. The argument must be a floating-point value. The value is
     converted to a string of the form "-ddd.ddd...". The resulting string
     starts with a minus sign if the number is negative. The number of digits
     after the decimal point is given by the precision specifier in the
     format string--a default of 2 decimal digits is assumed if no precision
     specifier is present.

  g  General. The argument must be a floating-point value. The value is
     converted to the shortest possible decimal string using fixed or
     scientific format. The number of significant digits in the resulting
     string is given by the precision specifier in the format string--a
     default precision of 15 is assumed if no precision specifier is present.
     Trailing zeros are removed from the resulting string, and a decimal
     point appears only if necessary. The resulting string uses fixed point
     format if the number of digits to the left of the decimal point in the
     value is less than or equal to the specified precision, and if the
     value is greater than or equal to 0.00001. Otherwise the resulting
     string uses scientific format.

  n  Number. The argument must be a floating-point value. The value is
     converted to a string of the form "-d,ddd,ddd.ddd...". The "n" format
     corresponds to the "f" format, except that the resulting string
     contains thousand separators.

  m  Money. The argument must be a floating-point value. The value is
     converted to a string that represents a currency amount. The conversion
     is controlled by the CurrencyString, CurrencyFormat, NegCurrFormat,
     ThousandSeparator, DecimalSeparator, and CurrencyDecimals global
     variables, all of which are initialized from locale settings provided
     by the operating system.  For example, Currency Format preferences can be
     set in the International section of the Windows Control Panel. If the format
     string contains a precision specifier, it overrides the value given
     by the CurrencyDecimals global variable.

  p  Pointer. The argument must be a pointer value. The value is converted
     to a string of the form "XXXX:YYYY" where XXXX and YYYY are the
     segment and offset parts of the pointer expressed as four hexadecimal
     digits.

  s  String. The argument must be a character, a string, or a PChar value.
     The string or character is inserted in place of the format specifier.
     The precision specifier, if present in the format string, specifies the
     maximum length of the resulting string. If the argument is a string
     that is longer than this maximum, the string is truncated.

  x  Hexadecimal. The argument must be an integer value. The value is
     converted to a string of hexadecimal digits. If the format string
     contains a precision specifier, it indicates that the resulting string
     must contain at least the specified number of digits; if the value has
     less digits, the resulting string is left-padded with zeros.

  Conversion characters may be specified in upper case as well as in lower
  case--both produce the same results.

  For all floating-point formats, the actual characters used as decimal and
  thousand separators are obtained from the DecimalSeparator and
  ThousandSeparator global variables.

  Index, width, and precision specifiers can be specified directly using
  decimal digit string (for example "%10d"), or indirectly using an asterisk
  charcater (for example "%*.*f"). When using an asterisk, the next argument
  in the argument list (which must be an integer value) becomes the value
  that is actually used. For example "Format('%*.*f', [8, 2, 123.456])" is
  the same as "Format('%8.2f', [123.456])".

  A width specifier sets the minimum field width for a conversion. If the
  resulting string is shorter than the minimum field width, it is padded
  with blanks to increase the field width. The default is to right-justify
  the result by adding blanks in front of the value, but if the format
  specifier contains a left-justification indicator (a "-" character
  preceding the width specifier), the result is left-justified by adding
  blanks after the value.

  An index specifier sets the current argument list index to the specified
  value. The index of the first argument in the argument list is 0. Using
  index specifiers, it is possible to format the same argument multiple
  times. For example "Format('%d %d %0:d %d', [10, 20])" produces the string
  '10 20 10 20'.

  The Format function can be combined with other formatting functions. For
  example

    S := Format('Your total was %s on %s', [
      FormatFloat('$#,##0.00;;zero', Total),
      FormatDateTime('mm/dd/yy', Date)]);

  which uses the FormatFloat and FormatDateTime functions to customize the
  format beyond what is possible with Format. }


{ FmtStr formats the argument list given by Args using the format string
  given by Format into the string variable given by Result. For further
  details, see the description of the Format function. }



{ StrFmt formats the argument list given by Args using the format string
  given by Format into the buffer given by Buffer. It is up to the caller to
  ensure that Buffer is large enough for the resulting string. The returned
  value is Buffer. For further details, see the description of the Format
  function. }

function StrFmt(Buffer, Format: PChar; const Args: array of const): PChar;

{ StrFmt formats the argument list given by Args using the format string
  given by Format into the buffer given by Buffer. The resulting string will
  contain no more than MaxBufLen characters, not including the null terminator.
  The returned value is Buffer. For further details, see the description of
  the Format function. }

function StrLFmt(Buffer: PChar; MaxBufLen: Cardinal; Format: PChar;
  const Args: array of const): PChar;

{ FormatBuf formats the argument list given by Args using the format string
  given by Format and FmtLen into the buffer given by Buffer and BufLen.
  The Format parameter is a reference to a buffer containing FmtLen
  characters, and the Buffer parameter is a reference to a buffer of BufLen
  characters. The returned value is the number of characters actually stored
  in Buffer. The returned value is always less than or equal to BufLen. For
  further details, see the description of the Format function. }



{ The WideFormat routine formats the argument list given by the Args parameter
  using the format WideString given by the Format parameter. This routine is
  the WideString equivalent of Format. For further details, see the description
  of the Format function. }
function WideFormat(const Format: WideString;
  const Args: array of const): WideString;

{ FmtStr formats the argument list given by Args using the format WideString
  given by Format into the WideString variable given by Result. For further
  details, see the description of the Format function. }
procedure WideFmtStr(var Result: WideString; const Format: WideString;
  const Args: array of const);

{ WideFormatBuf formats the argument list given by Args using the format string
  given by Format and FmtLen into the buffer given by Buffer and BufLen.
  The Format parameter is a reference to a buffer containing FmtLen
  UNICODE characters (WideChar), and the Buffer parameter is a reference to a
  buffer of BufLen UNICODE characters (WideChar). The return value is the number
  of UNICODE characters actually stored in Buffer. The return value is always
  less than or equal to BufLen. For further details, see the description of the
  Format function.

  Important: BufLen, FmtLen and the return result are always the number of
  UNICODE characters, *not* the number of bytes. To calculate the number of bytes
  multiply them by SizeOf(WideChar). }
function WideFormatBuf(var Buffer; BufLen: Cardinal; const Format;
  FmtLen: Cardinal; const Args: array of const): Cardinal;

{ Floating point conversion routines }

{ FloatToStr converts the floating-point value given by Value to its string
  representation. The conversion uses general number format with 15
  significant digits. For further details, see the description of the
  FloatToStrF function. }

function floattostr(Value: extended): string;

{ CurrToStr converts the currency value given by Value to its string
  representation. The conversion uses general number format. For further
  details, see the description of the CurrToStrF function. }

function CurrToStr(Value: Currency): string;

{ FloatToCurr will range validate a value to make sure it falls
  within the acceptable currency range }

const
  MinCurrency                           : Currency = -922337203685477.5807{$IFDEF LINUX} + 1{$ENDIF}; //!! overflow?
  MaxCurrency                           : Currency = 922337203685477.5807{$IFDEF LINUX} - 1{$ENDIF}; //!! overflow?

function FloatToCurr(const Value: extended): Currency;

{ FloatToStrF converts the floating-point value given by Value to its string
  representation. The Format parameter controls the format of the resulting
  string. The Precision parameter specifies the precision of the given value.
  It should be 7 or less for values of type Single, 15 or less for values of
  type Double, and 18 or less for values of type Extended. The meaning of the
  Digits parameter depends on the particular format selected.

  The possible values of the Format parameter, and the meaning of each, are
  described below.

  ffGeneral - General number format. The value is converted to the shortest
  possible decimal string using fixed or scientific format. Trailing zeros
  are removed from the resulting string, and a decimal point appears only
  if necessary. The resulting string uses fixed point format if the number
  of digits to the left of the decimal point in the value is less than or
  equal to the specified precision, and if the value is greater than or
  equal to 0.00001. Otherwise the resulting string uses scientific format,
  and the Digits parameter specifies the minimum number of digits in the
  exponent (between 0 and 4).

  ffExponent - Scientific format. The value is converted to a string of the
  form "-d.ddd...E+dddd". The resulting string starts with a minus sign if
  the number is negative, and one digit always precedes the decimal point.
  The total number of digits in the resulting string (including the one
  before the decimal point) is given by the Precision parameter. The "E"
  exponent character in the resulting string is always followed by a plus
  or minus sign and up to four digits. The Digits parameter specifies the
  minimum number of digits in the exponent (between 0 and 4).

  ffFixed - Fixed point format. The value is converted to a string of the
  form "-ddd.ddd...". The resulting string starts with a minus sign if the
  number is negative, and at least one digit always precedes the decimal
  point. The number of digits after the decimal point is given by the Digits
  parameter--it must be between 0 and 18. If the number of digits to the
  left of the decimal point is greater than the specified precision, the
  resulting value will use scientific format.

  ffNumber - Number format. The value is converted to a string of the form
  "-d,ddd,ddd.ddd...". The ffNumber format corresponds to the ffFixed format,
  except that the resulting string contains thousand separators.

  ffCurrency - Currency format. The value is converted to a string that
  represents a currency amount. The conversion is controlled by the
  CurrencyString, CurrencyFormat, NegCurrFormat, ThousandSeparator, and
  DecimalSeparator global variables, all of which are initialized from
  locale settings provided by the operating system.  For example,
  Currency Format preferences can be set in the International section
  of the Windows Control Panel.
  The number of digits after the decimal point is given by the Digits
  parameter--it must be between 0 and 18.

  For all formats, the actual characters used as decimal and thousand
  separators are obtained from the DecimalSeparator and ThousandSeparator
  global variables.

  If the given value is a NAN (not-a-number), the resulting string is 'NAN'.
  If the given value is positive infinity, the resulting string is 'INF'. If
  the given value is negative infinity, the resulting string is '-INF'. }

function floattostrf(Value: extended; Format: TFloatFormat;
  Precision, Digits: integer): string;

{ CurrToStrF converts the currency value given by Value to its string
  representation. A call to CurrToStrF corresponds to a call to
  FloatToStrF with an implied precision of 19 digits. }

function CurrToStrF(Value: Currency; Format: TFloatFormat;
  Digits: integer): string;

{ FloatToText converts the given floating-point value to its decimal
  representation using the specified format, precision, and digits. The
  Value parameter must be a variable of type Extended or Currency, as
  indicated by the ValueType parameter. The resulting string of characters
  is stored in the given buffer, and the returned value is the number of
  characters stored. The resulting string is not null-terminated. For
  further details, see the description of the FloatToStrF function. }



{ FormatFloat formats the floating-point value given by Value using the
  format string given by Format. The following format specifiers are
  supported in the format string:

  0     Digit placeholder. If the value being formatted has a digit in the
        position where the '0' appears in the format string, then that digit
        is copied to the output string. Otherwise, a '0' is stored in that
        position in the output string.

  #     Digit placeholder. If the value being formatted has a digit in the
        position where the '#' appears in the format string, then that digit
        is copied to the output string. Otherwise, nothing is stored in that
        position in the output string.

  .     Decimal point. The first '.' character in the format string
        determines the location of the decimal separator in the formatted
        value; any additional '.' characters are ignored. The actual
        character used as a the decimal separator in the output string is
        determined by the DecimalSeparator global variable, which is initialized
        from locale settings obtained from the operating system.

  ,     Thousand separator. If the format string contains one or more ','
        characters, the output will have thousand separators inserted between
        each group of three digits to the left of the decimal point. The
        placement and number of ',' characters in the format string does not
        affect the output, except to indicate that thousand separators are
        wanted. The actual character used as a the thousand separator in the
        output is determined by the ThousandSeparator global variable, which
        is initialized from locale settings obtained from the operating system.

  E+    Scientific notation. If any of the strings 'E+', 'E-', 'e+', or 'e-'
  E-    are contained in the format string, the number is formatted using
  e+    scientific notation. A group of up to four '0' characters can
  e-    immediately follow the 'E+', 'E-', 'e+', or 'e-' to determine the
        minimum number of digits in the exponent. The 'E+' and 'e+' formats
        cause a plus sign to be output for positive exponents and a minus
        sign to be output for negative exponents. The 'E-' and 'e-' formats
        output a sign character only for negative exponents.

  'xx'  Characters enclosed in single or double quotes are output as-is, and
  "xx"  do not affect formatting.

  ;     Separates sections for positive, negative, and zero numbers in the
        format string.

  The locations of the leftmost '0' before the decimal point in the format
  string and the rightmost '0' after the decimal point in the format string
  determine the range of digits that are always present in the output string.

  The number being formatted is always rounded to as many decimal places as
  there are digit placeholders ('0' or '#') to the right of the decimal
  point. If the format string contains no decimal point, the value being
  formatted is rounded to the nearest whole number.

  If the number being formatted has more digits to the left of the decimal
  separator than there are digit placeholders to the left of the '.'
  character in the format string, the extra digits are output before the
  first digit placeholder.

  To allow different formats for positive, negative, and zero values, the
  format string can contain between one and three sections separated by
  semicolons.

  One section - The format string applies to all values.

  Two sections - The first section applies to positive values and zeros, and
  the second section applies to negative values.

  Three sections - The first section applies to positive values, the second
  applies to negative values, and the third applies to zeros.

  If the section for negative values or the section for zero values is empty,
  that is if there is nothing between the semicolons that delimit the
  section, the section for positive values is used instead.

  If the section for positive values is empty, or if the entire format string
  is empty, the value is formatted using general floating-point formatting
  with 15 significant digits, corresponding to a call to FloatToStrF with
  the ffGeneral format. General floating-point formatting is also used if
  the value has more than 18 digits to the left of the decimal point and
  the format string does not specify scientific notation.

  The table below shows some sample formats and the results produced when
  the formats are applied to different values:

  Format string          1234        -1234       0.5         0
  -----------------------------------------------------------------------
                         1234        -1234       0.5         0
  0                      1234        -1234       1           0
  0.00                   1234.00     -1234.00    0.50        0.00
  #.##                   1234        -1234       .5
  #,##0.00               1,234.00    -1,234.00   0.50        0.00
  #,##0.00;(#,##0.00)    1,234.00    (1,234.00)  0.50        0.00
  #,##0.00;;Zero         1,234.00    -1,234.00   0.50        Zero
  0.000E+00              1.234E+03   -1.234E+03  5.000E-01   0.000E+00
  #.###E-0               1.234E3     -1.234E3    5E-1        0E0
  ----------------------------------------------------------------------- }

function FormatFloat(const Format: string; Value: extended): string;

{ FormatCurr formats the currency value given by Value using the format
  string given by Format. For further details, see the description of the
  FormatFloat function. }

function FormatCurr(const Format: string; Value: Currency): string;

{ FloatToTextFmt converts the given floating-point value to its decimal
  representation using the specified format. The Value parameter must be a
  variable of type Extended or Currency, as indicated by the ValueType
  parameter. The resulting string of characters is stored in the given
  buffer, and the returned value is the number of characters stored. The
  resulting string is not null-terminated. For further details, see the
  description of the FormatFloat function. }

function FloatToTextFmt(buf: PChar; const Value; ValueType: TFloatValue;
  Format: PChar): integer;

{ StrToFloat converts the given string to a floating-point value. The string
  must consist of an optional sign (+ or -), a string of digits with an
  optional decimal point, and an optional 'E' or 'e' followed by a signed
  integer. Leading and trailing blanks in the string are ignored. The
  DecimalSeparator global variable defines the character that must be used
  as a decimal point. Thousand separators and currency symbols are not
  allowed in the string. If the string doesn't contain a valid value, an
  EConvertError exception is raised. }

function strtofloat(const s: string): extended;
function StrToFloatDef(const s: string; const Default: extended): extended;
function TryStrToFloat(const s: string; out Value: extended): boolean; overload;
function TryStrToFloat(const s: string; out Value: Double): boolean; overload;
function TryStrToFloat(const s: string; out Value: single): boolean; overload;

{ StrToCurr converts the given string to a currency value. For further
  details, see the description of the StrToFloat function. }

function StrToCurr(const s: string): Currency;
function StrToCurrDef(const s: string; const Default: Currency): Currency;
function TryStrToCurr(const s: string; out Value: Currency): boolean;

{ TextToFloat converts the null-terminated string given by Buffer to a
  floating-point value which is returned in the variable given by Value.
  The Value parameter must be a variable of type Extended or Currency, as
  indicated by the ValueType parameter. The return value is True if the
  conversion was successful, or False if the string is not a valid
  floating-point value. For further details, see the description of the
  StrToFloat function. }

function TextToFloat(Buffer: PChar; var Value;
  ValueType: TFloatValue): boolean;

{ FloatToDecimal converts a floating-point value to a decimal representation
  that is suited for further formatting. The Value parameter must be a
  variable of type Extended or Currency, as indicated by the ValueType
  parameter. For values of type Extended, the Precision parameter specifies
  the requested number of significant digits in the result--the allowed range
  is 1..18. For values of type Currency, the Precision parameter is ignored,
  and the implied precision of the conversion is 19 digits. The Decimals
  parameter specifies the requested maximum number of digits to the left of
  the decimal point in the result. Precision and Decimals together control
  how the result is rounded. To produce a result that always has a given
  number of significant digits regardless of the magnitude of the number,
  specify 9999 for the Decimals parameter. The result of the conversion is
  stored in the specified TFloatRec record as follows:

  Exponent - Contains the magnitude of the number, i.e. the number of
  significant digits to the right of the decimal point. The Exponent field
  is negative if the absolute value of the number is less than one. If the
  number is a NAN (not-a-number), Exponent is set to -32768. If the number
  is INF or -INF (positive or negative infinity), Exponent is set to 32767.

  Negative - True if the number is negative, False if the number is zero
  or positive.

  Digits - Contains up to 18 (for type Extended) or 19 (for type Currency)
  significant digits followed by a null terminator. The implied decimal
  point (if any) is not stored in Digits. Trailing zeros are removed, and
  if the resulting number is zero, NAN, or INF, Digits contains nothing but
  the null terminator. }

procedure FloatToDecimal(var Result: TFloatRec; const Value;
  ValueType: TFloatValue; Precision, Decimals: integer);

{ Date/time support routines }

function DateTimeToTimeStamp(DateTime: TDateTime): ttimestamp;

function TimeStampToDateTime(const TimeStamp: ttimestamp): TDateTime;
function MSecsToTimeStamp(MSecs: Comp): ttimestamp;
function TimeStampToMSecs(const TimeStamp: ttimestamp): Comp;

{ EncodeDate encodes the given year, month, and day into a TDateTime value.
  The year must be between 1 and 9999, the month must be between 1 and 12,
  and the day must be between 1 and N, where N is the number of days in the
  specified month. If the specified values are not within range, an
  EConvertError exception is raised. The resulting value is the number of
  days between 12/30/1899 and the given date. }

function EncodeDate(Year, Month, Day: Word): TDateTime;

{ EncodeTime encodes the given hour, minute, second, and millisecond into a
  TDateTime value. The hour must be between 0 and 23, the minute must be
  between 0 and 59, the second must be between 0 and 59, and the millisecond
  must be between 0 and 999. If the specified values are not within range, an
  EConvertError exception is raised. The resulting value is a number between
  0 (inclusive) and 1 (not inclusive) that indicates the fractional part of
  a day given by the specified time. The value 0 corresponds to midnight,
  0.5 corresponds to noon, 0.75 corresponds to 6:00 pm, etc. }

function EncodeTime(Hour, Min, Sec, msec: Word): TDateTime;

{ Instead of generating errors the following variations of EncodeDate and
  EncodeTime simply return False if the parameters given are not valid.
  Other than that, these functions are functionally the same as the above
  functions. }

function TryEncodeDate(Year, Month, Day: Word; out Date: TDateTime): boolean;
function TryEncodeTime(Hour, Min, Sec, msec: Word; out Time: TDateTime): boolean;

{ DecodeDate decodes the integral (date) part of the given TDateTime value
  into its corresponding year, month, and day. If the given TDateTime value
  is less than or equal to zero, the year, month, and day return parameters
  are all set to zero. }

procedure DecodeDate(const DateTime: TDateTime; var Year, Month, Day: Word);

{ This variation of DecodeDate works similarly to the above function but
  returns more information.  The result value of this function indicates
  wither the year decoded is a leap year or not.  }

function DecodeDateFully(const DateTime: TDateTime; var Year, Month, Day,
  DOW: Word): boolean;

{$IFDEF LINUX}
function InternalDecodeDate(const DateTime: TDateTime; var Year, Month, Day, DOW: Word): boolean;
{$ENDIF}

{ DecodeTime decodes the fractional (time) part of the given TDateTime value
  into its corresponding hour, minute, second, and millisecond. }

procedure DecodeTime(const DateTime: TDateTime; var Hour, Min, Sec, msec: Word);

{$IFDEF MSWINDOWS}
{ DateTimeToSystemTime converts a date and time from Delphi's TDateTime
  format into the Win32 API's TSystemTime format. }

procedure DateTimeToSystemTime(const DateTime: TDateTime; var SYSTEMTIME: TSystemTime);

{ SystemTimeToDateTime converts a date and time from the Win32 API's
  TSystemTime format into Delphi's TDateTime format. }

function SystemTimeToDateTime(const SYSTEMTIME: TSystemTime): TDateTime;
{$ENDIF}

{ DayOfWeek returns the day of the week of the given date. The result is an
  integer between 1 and 7, corresponding to Sunday through Saturday.
  This function is not ISO 8601 compliant, for that see the DateUtils unit. }

function DayOfWeek(const DateTime: TDateTime): Word;

{ Date returns the current date. }

function Date: TDateTime;

{ Time returns the current time. }

function Time: TDateTime;

{ Now returns the current date and time, corresponding to Date + Time. }

function Now: TDateTime;

{ Current year returns the year portion of the date returned by Now }

function CurrentYear: Word;

{ IncMonth returns Date shifted by the specified number of months.
  NumberOfMonths parameter can be negative, to return a date N months ago.
  If the input day of month is greater than the last day of the resulting
  month, the day is set to the last day of the resulting month.
  Input time of day is copied to the DateTime result.  }

function IncMonth(const DateTime: TDateTime; NumberOfMonths: integer = 1): TDateTime;

{ Optimized version of IncMonth that works with years, months and days
  directly.  See above comments for more detail as to what happens to the day
  when incrementing months }

procedure IncAMonth(var Year, Month, Day: Word; NumberOfMonths: integer = 1);

{ ReplaceTime replaces the time portion of the DateTime parameter with the given
  time value, adjusting the signs as needed if the date is prior to 1900
  (Date value less than zero)  }

procedure ReplaceTime(var DateTime: TDateTime; const NewTime: TDateTime);

{ ReplaceDate replaces the date portion of the DateTime parameter with the given
  date value, adjusting as needed for negative dates }

procedure ReplaceDate(var DateTime: TDateTime; const NewDate: TDateTime);

{ IsLeapYear determines whether the given year is a leap year. }

function IsLeapYear(Year: Word): boolean;

type
  PDayTable = ^TDayTable;
  TDayTable = array[1..12] of Word;

   { The MonthDays array can be used to quickly find the number of
     days in a month:  MonthDays[IsLeapYear(Y), M]      }

const
  MonthDays                             : array[boolean] of TDayTable =
    ((31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31),
    (31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31));

   { DateToStr converts the date part of the given TDateTime value to a string.
     The conversion uses the format specified by the ShortDateFormat global
     variable. }

function datetostr(const DateTime: TDateTime): string;

{ TimeToStr converts the time part of the given TDateTime value to a string.
  The conversion uses the format specified by the LongTimeFormat global
  variable. }

function TimeToStr(const DateTime: TDateTime): string;

{ DateTimeToStr converts the given date and time to a string. The resulting
  string consists of a date and time formatted using the ShortDateFormat and
  LongTimeFormat global variables. Time information is included in the
  resulting string only if the fractional part of the given date and time
  value is non-zero. }

function datetimetostr(const DateTime: TDateTime): string;

{ StrToDate converts the given string to a date value. The string must
  consist of two or three numbers, separated by the character defined by
  the DateSeparator global variable. The order for month, day, and year is
  determined by the ShortDateFormat global variable--possible combinations
  are m/d/y, d/m/y, and y/m/d. If the string contains only two numbers, it
  is interpreted as a date (m/d or d/m) in the current year. Year values
  between 0 and 99 are assumed to be in the current century. If the given
  string does not contain a valid date, an EConvertError exception is
  raised. }

function StrToDate(const s: string): TDateTime;
function StrToDateDef(const s: string; const Default: TDateTime): TDateTime;
function TryStrToDate(const s: string; out Value: TDateTime): boolean;

{ StrToTime converts the given string to a time value. The string must
  consist of two or three numbers, separated by the character defined by
  the TimeSeparator global variable, optionally followed by an AM or PM
  indicator. The numbers represent hour, minute, and (optionally) second,
  in that order. If the time is followed by AM or PM, it is assumed to be
  in 12-hour clock format. If no AM or PM indicator is included, the time
  is assumed to be in 24-hour clock format. If the given string does not
  contain a valid time, an EConvertError exception is raised. }

function StrToTime(const s: string): TDateTime;
function StrToTimeDef(const s: string; const Default: TDateTime): TDateTime;
function TryStrToTime(const s: string; out Value: TDateTime): boolean;

{ StrToDateTime converts the given string to a date and time value. The
  string must contain a date optionally followed by a time. The date and
  time parts of the string must follow the formats described for the
  StrToDate and StrToTime functions. }

function StrToDateTime(const s: string): TDateTime;
function StrToDateTimeDef(const s: string; const Default: TDateTime): TDateTime;
function TryStrToDateTime(const s: string; out Value: TDateTime): boolean;

{ FormatDateTime formats the date-and-time value given by DateTime using the
  format given by Format. The following format specifiers are supported:

  c       Displays the date using the format given by the ShortDateFormat
          global variable, followed by the time using the format given by
          the LongTimeFormat global variable. The time is not displayed if
          the fractional part of the DateTime value is zero.

  d       Displays the day as a number without a leading zero (1-31).

  dd      Displays the day as a number with a leading zero (01-31).

  ddd     Displays the day as an abbreviation (Sun-Sat) using the strings
          given by the ShortDayNames global variable.

  dddd    Displays the day as a full name (Sunday-Saturday) using the strings
          given by the LongDayNames global variable.

  ddddd   Displays the date using the format given by the ShortDateFormat
          global variable.

  dddddd  Displays the date using the format given by the LongDateFormat
          global variable.

  g       Displays the period/era as an abbreviation (Japanese and
          Taiwanese locales only).

  gg      Displays the period/era as a full name.

  e       Displays the year in the current period/era as a number without
          a leading zero (Japanese, Korean and Taiwanese locales only).

  ee      Displays the year in the current period/era as a number with
          a leading zero (Japanese, Korean and Taiwanese locales only).

  m       Displays the month as a number without a leading zero (1-12). If
          the m specifier immediately follows an h or hh specifier, the
          minute rather than the month is displayed.

  mm      Displays the month as a number with a leading zero (01-12). If
          the mm specifier immediately follows an h or hh specifier, the
          minute rather than the month is displayed.

  mmm     Displays the month as an abbreviation (Jan-Dec) using the strings
          given by the ShortMonthNames global variable.

  mmmm    Displays the month as a full name (January-December) using the
          strings given by the LongMonthNames global variable.

  yy      Displays the year as a two-digit number (00-99).

  yyyy    Displays the year as a four-digit number (0000-9999).

  h       Displays the hour without a leading zero (0-23).

  hh      Displays the hour with a leading zero (00-23).

  n       Displays the minute without a leading zero (0-59).

  nn      Displays the minute with a leading zero (00-59).

  s       Displays the second without a leading zero (0-59).

  ss      Displays the second with a leading zero (00-59).

  z       Displays the millisecond without a leading zero (0-999).

  zzz     Displays the millisecond with a leading zero (000-999).

  t       Displays the time using the format given by the ShortTimeFormat
          global variable.

  tt      Displays the time using the format given by the LongTimeFormat
          global variable.

  am/pm   Uses the 12-hour clock for the preceding h or hh specifier, and
          displays 'am' for any hour before noon, and 'pm' for any hour
          after noon. The am/pm specifier can use lower, upper, or mixed
          case, and the result is displayed accordingly.

  a/p     Uses the 12-hour clock for the preceding h or hh specifier, and
          displays 'a' for any hour before noon, and 'p' for any hour after
          noon. The a/p specifier can use lower, upper, or mixed case, and
          the result is displayed accordingly.

  ampm    Uses the 12-hour clock for the preceding h or hh specifier, and
          displays the contents of the TimeAMString global variable for any
          hour before noon, and the contents of the TimePMString global
          variable for any hour after noon.

  /       Displays the date separator character given by the DateSeparator
          global variable.

  :       Displays the time separator character given by the TimeSeparator
          global variable.

  'xx'    Characters enclosed in single or double quotes are displayed as-is,
  "xx"    and do not affect formatting.

  Format specifiers may be written in upper case as well as in lower case
  letters--both produce the same result.

  If the string given by the Format parameter is empty, the date and time
  value is formatted as if a 'c' format specifier had been given.

  The following example:

    S := FormatDateTime('"The meeting is on" dddd, mmmm d, yyyy, ' +
      '"at" hh:mm AM/PM', StrToDateTime('2/15/95 10:30am'));

  assigns 'The meeting is on Wednesday, February 15, 1995 at 10:30 AM' to
  the string variable S. }

function FormatDateTime(const Format: string; DateTime: TDateTime): string;

{ DateTimeToString converts the date and time value given by DateTime using
  the format string given by Format into the string variable given by Result.
  For further details, see the description of the FormatDateTime function. }

procedure DateTimeToString(var Result: string; const Format: string;
  DateTime: TDateTime);

{ FloatToDateTime will range validate a value to make sure it falls
  within the acceptable date range }

const
  MinDateTime                           : TDateTime = -657434.0; { 01/01/0100 12:00:00.000 AM }
  MaxDateTime                           : TDateTime = 2958465.99999; { 12/31/9999 11:59:59.999 PM }

function FloatToDateTime(const Value: extended): TDateTime;

{ System error messages }

function SysErrorMessage(ErrorCode: integer): string;

{ Initialization file support }

function GetLocaleStr(Locale, LocaleType: integer; const Default: string): string;
platform;
function GetLocaleChar(Locale, LocaleType: integer; Default: Char): Char;
platform;

{ GetFormatSettings resets all date and number format variables to their
  default values. }

procedure GetFormatSettings;

{ Exception handling routines }

{$IFDEF LINUX}
{   InquireSignal is used to determine the state of an OS signal handler.
    Pass it one of the RTL_SIG* constants, and it will return a TSignalState
    which will tell you if the signal has been hooked, not hooked, or overriden
    by some other module.  You can use this function to determine if some other
    module has hijacked your signal handlers, should you wish to reinstall your
    own. This is a risky proposition under Linux, and is only recommended as a
    last resort.  Do not pass RTL_SIGDEFAULT to this function.
}
function InquireSignal(RtlSigNum: integer): TSignalState;
{ AbandonSignalHandler tells the RTL to leave a signal handler
    in place, even if we believe that we hooked it at startup time.

    Once you have called AbandonSignalHandler with a specific signal number,
    neither UnhookSignal nor the RTL will restore any previous signal handler
    under any condition.
}
procedure AbandonSignalHandler(RtlSigNum: integer);

{ HookSignal is used to hook individual signals, or an RTL-defined default
    set of signals.  It does not test whether a signal has already been
    hooked, so it should be used in conjunction with InquireSignal.  It is
    exposed to enable users to hook signals in standalone libraries, or in the
    event that an external module hijacks the RTL installed signal handlers.
    Pass RTL_SIGDEFAULT if you want to hook all the signals that the RTL
    normally hooks at startup time.
}
procedure HookSignal(RtlSigNum: integer);

{ UnhookSignal is used to remove signal handlers installed by HookSignal.
    It can remove individual signal handlers, or the RTL-defined default set
    of signals.  If OnlyIfHooked is True, then we will only unhook the signal
    if the signal handler has been hooked, and has not since been overriden by
    some foreign handler.
}
procedure UnhookSignal(RtlSigNum: integer; OnlyIfHooked: boolean = True);

{ HookOSExceptions is used internally by thread support.  DON'T call this
  function yourself. }
procedure HookOSExceptions;

{ MapSignal is used internally as well.  It maps a signal and associated
  context to an internal value that represents the type of Exception
  class to raise. }
function MapSignal(SigNum: integer; Context: PSigContext): LongWord;

{ SignalConverter is used internally to properly reinit the FPU and properly
  raise an external OS exception object.  DON'T call this function yourself. }
procedure SignalConverter(ExceptionEIP: LongWord; FaultAddr: LongWord; ErrorCode: LongWord);

{
    See the comment at the threadvar declarations for these below.  The access
    to these has been implemented through getter/setter functions because you
    cannot use threadvars across packages.
}
procedure SetSafeCallExceptionMsg(Msg: string);
procedure SetSafeCallExceptionAddr(Addr: Pointer);
function GetSafeCallExceptionMsg: string;
function GetSafeCallExceptionAddr: Pointer;

{ HookOSExceptionsProc is used internally and cannot be used in a conventional
  manner.  DON'T ever set this variable. }
var
  HookOSExceptionsProc                  : procedure = nil platform deprecated;

   { LoadLibrary / FreeLibrary are defined here only for convenience.  On Linux,
     they map directly to dlopen / dlclose.  Note that module loading semantics
     on Linux are not identical to Windows.  }

function LoadLibrary(ModuleName: PChar): HMODULE;

function FreeLibrary(Module: HMODULE): LongBool;

{ GetProcAddress does what it implies.  It performs the same function as the like
  named function under Windows.  dlsym does not quite have the same sematics as
  GetProcAddress as it will return the address of a symbol in another module if
  it was not found in the given HMODULE.  This function will verify that the 'Proc'
  is actually found within the 'Module', and if not returns nil }
function GetProcAddress(Module: HMODULE; Proc: PChar): Pointer;

{ Given a module name, this function will return the module handle.  There is no
  direct equivalent in Linux so this function provides that capability.  Also
  note, this function is specific to glibc. }
function GetModuleHandle(ModuleName: PChar): HMODULE;

{ This function works just like GetModuleHandle, except it will look for a module
  that matches the given base package name.  For example, given the base package
  name 'package', the actual module name is, by default, 'bplpackage.so'.  This
  function will search for the string 'package' within the module name. }
function GetPackageModuleHandle(PackageName: PChar): HMODULE;

{$ENDIF}

{ In Linux, the parameter to sleep() is in whole seconds.  In Windows, the
  parameter is in milliseconds.  To ease headaches, we implement a version
  of sleep here for Linux that takes milliseconds and calls a Linux system
  function with sub-second resolution.  This maps directly to the Windows
  API on Windows. }

procedure Sleep(milliseconds: Cardinal);
{$IFDEF MSWINDOWS}stdcall;
{$ENDIF}

function GetModuleName(Module: HMODULE): string;

function ExceptionErrorMessage(ExceptObject: TObject; ExceptAddr: Pointer;
  Buffer: PChar; Size: integer): integer;

procedure ShowException(ExceptObject: TObject; ExceptAddr: Pointer);

procedure Abort;

procedure OutOfMemoryError;

procedure Beep;

{ MBCS functions }

{ LeadBytes is a char set that indicates which char values are lead bytes
  in multibyte character sets (Japanese, Chinese, etc).
  This set is always empty for western locales. }
var
  LeadBytes                             : set of Char = [];
   (*$EXTERNALSYM LeadBytes*)
   (*$HPPEMIT 'namespace Sysutils {'*)
   (*$HPPEMIT 'extern PACKAGE System::Set<Byte, 0, 255>  LeadBytes;'*)
   (*$HPPEMIT '} // namespace Sysutils'*)

   { ByteType indicates what kind of byte exists at the Index'th byte in S.
     Western locales always return mbSingleByte.  Far East multibyte locales
     may also return mbLeadByte, indicating the byte is the first in a multibyte
     character sequence, and mbTrailByte, indicating that the byte is one of
     a sequence of bytes following a lead byte.  One or more trail bytes can
     follow a lead byte, depending on locale charset encoding and OS platform.
     Parameters are assumed to be valid. }

function ByteType(const s: string; Index: integer): TMbcsByteType;

{ StrByteType works the same as ByteType, but on null-terminated PChar strings }

function StrByteType(Str: PChar; Index: Cardinal): TMbcsByteType;

{ ByteToCharLen returns the character length of a MBCS string, scanning the
  string for up to MaxLen bytes.  In multibyte character sets, the number of
  characters in a string may be less than the number of bytes.  }

function ByteToCharLen(const s: string; MaxLen: integer): integer;

{ CharToByteLen returns the byte length of a MBCS string, scanning the string
  for up to MaxLen characters. }

function CharToByteLen(const s: string; MaxLen: integer): integer;

{ ByteToCharIndex returns the 1-based character index of the Index'th byte in
  a MBCS string.  Returns zero if Index is out of range:
  (Index <= 0) or (Index > Length(S)) }

function ByteToCharIndex(const s: string; Index: integer): integer;

{ CharToByteIndex returns the 1-based byte index of the Index'th character
  in a MBCS string.  Returns zero if Index or Result are out of range:
  (Index <= 0) or (Index > Length(S)) or (Result would be > Length(S)) }

function CharToByteIndex(const s: string; Index: integer): integer;

{ StrCharLength returns the number of bytes required by the first character
  in Str.  In Windows, multibyte characters can be up to two bytes in length.
  In Linux, multibyte characters can be up to six bytes in length (UTF-8). }

function StrCharLength(const Str: PChar): integer;

{ StrNextChar returns a pointer to the first byte of the character following
  the character pointed to by Str.  }

function StrNextChar(const Str: PChar): PChar;

{ CharLength returns the number of bytes required by the character starting
  at bytes S[Index].  }

function CharLength(const s: string; Index: integer): integer;

{ NextCharIndex returns the byte index of the first byte of the character
  following the character starting at S[Index].  }

function NextCharIndex(const s: string; Index: integer): integer;

{ IsPathDelimiter returns True if the character at byte S[Index]
  is a PathDelimiter ('\' or '/'), and it is not a MBCS lead or trail byte. }

function IsPathDelimiter(const s: string; Index: integer): boolean;

{ IsDelimiter returns True if the character at byte S[Index] matches any
  character in the Delimiters string, and the character is not a MBCS lead or
  trail byte.  S may contain multibyte characters; Delimiters must contain
  only single byte characters. }

function IsDelimiter(const Delimiters, s: string; Index: integer): boolean;

{ IncludeTrailingPathDelimiter returns the path with a PathDelimiter
  ('/' or '\') at the end.  This function is MBCS enabled. }

function IncludeTrailingPathDelimiter(const s: string): string;

{ IncludeTrailingBackslash is the old name for IncludeTrailingPathDelimiter. }

function IncludeTrailingBackslash(const s: string): string;
platform;

{ ExcludeTrailingPathDelimiter returns the path without a PathDelimiter
  ('\' or '/') at the end.  This function is MBCS enabled. }

function ExcludeTrailingPathDelimiter(const s: string): string;

{ ExcludeTrailingBackslash is the old name for ExcludeTrailingPathDelimiter. }

function ExcludeTrailingBackslash(const s: string): string;
platform;

{ LastDelimiter returns the byte index in S of the rightmost whole
  character that matches any character in Delimiters (except null (#0)).
  S may contain multibyte characters; Delimiters must contain only single
  byte non-null characters.
  Example: LastDelimiter('\.:', 'c:\filename.ext') returns 12. }

function LastDelimiter(const Delimiters, s: string): integer;

{ AnsiCompareFileName supports DOS file name comparison idiosyncracies
  in Far East locales (Zenkaku) on Windows.
  In non-MBCS locales on Windows, AnsiCompareFileName is identical to
  AnsiCompareText (case insensitive).
  On Linux, AnsiCompareFileName is identical to AnsiCompareStr (case sensitive).
  For general purpose file name comparisions, you should use this function
  instead of AnsiCompareText. }

function AnsiCompareFileName(const s1, s2: string): integer;

function SameFileName(const s1, s2: string): boolean;

{ AnsiLowerCaseFileName supports lowercase conversion idiosyncracies of
  DOS file names in Far East locales (Zenkaku).  In non-MBCS locales,
  AnsiLowerCaseFileName is identical to AnsiLowerCase. }

function AnsiLowerCaseFileName(const s: string): string;

{ AnsiUpperCaseFileName supports uppercase conversion idiosyncracies of
  DOS file names in Far East locales (Zenkaku).  In non-MBCS locales,
  AnsiUpperCaseFileName is identical to AnsiUpperCase. }

function AnsiUpperCaseFileName(const s: string): string;

{ AnsiPos:  Same as Pos but supports MBCS strings }

function AnsiPos(const Substr, s: string): integer;

{ AnsiStrPos: Same as StrPos but supports MBCS strings }

function AnsiStrPos(Str, SubStr: PChar): PChar;

{ AnsiStrRScan: Same as StrRScan but supports MBCS strings }

function AnsiStrRScan(Str: PChar; CHR: Char): PChar;

{ AnsiStrScan: Same as StrScan but supports MBCS strings }

function AnsiStrScan(Str: PChar; CHR: Char): PChar;

{ StringReplace replaces occurances of <oldpattern> with <newpattern> in a
  given string.  Assumes the string may contain Multibyte characters }

type
  TReplaceFlags = set of (rfReplaceAll, rfIgnoreCase);

function StringReplace(const s, OldPattern, NewPattern: string;
  Flags: TReplaceFlags): string;

{ WrapText will scan a string for BreakChars and insert the BreakStr at the
  last BreakChar position before MaxCol.  Will not insert a break into an
  embedded quoted string (both ''' and '"' supported) }

function WrapText(const Line, BreakStr: string; const BreakChars: TSysCharSet;
  MaxCol: integer): string; overload;
function WrapText(const Line: string; MaxCol: integer = 45): string; overload;

{ FindCmdLineSwitch determines whether the string in the Switch parameter
  was passed as a command line argument to the application.  SwitchChars
  identifies valid argument-delimiter characters (i.e., "-" and "/" are
  common delimiters). The IgnoreCase paramter controls whether a
  case-sensistive or case-insensitive search is performed. }

const
  SwitchChars                           = {$IFDEF MSWINDOWS} ['/', '-'];
{$ENDIF}
{$IFDEF LINUX} ['-'];
{$ENDIF}

function FindCmdLineSwitch(const Switch: string; const Chars: TSysCharSet;
  IgnoreCase: boolean): boolean; overload;

{ These versions of FindCmdLineSwitch are convenient for writing portable
  code.  The characters that are valid to indicate command line switches vary
  on different platforms.  For example, '/' cannot be used as a switch char
  on Linux because '/' is the path delimiter. }

{ This version uses SwitchChars defined above, and IgnoreCase False. }
function FindCmdLineSwitch(const Switch: string): boolean; overload;

{ This version uses SwitchChars defined above. }
function FindCmdLineSwitch(const Switch: string; IgnoreCase: boolean): boolean; overload;

{ FreeAndNil frees the given TObject instance and sets the variable reference
  to nil.  Be careful to only pass TObjects to this routine. }

procedure FreeAndNil(var obj);

{ Interface support routines }

function Supports(const Instance: IInterface; const IID: TGUID; out IntF): boolean; overload;
function Supports(const Instance: TObject; const IID: TGUID; out IntF): boolean; overload;
function Supports(const Instance: IInterface; const IID: TGUID): boolean; overload;
function Supports(const Instance: TObject; const IID: TGUID): boolean; overload;
function Supports(const AClass: TClass; const IID: TGUID): boolean; overload;

function CreateGUID(out Guid: TGUID): HResult;
{$IFDEF MSWINDOWS}
stdcall;
{$ENDIF}
function StringToGUID(const s: string): TGUID;
function GUIDToString(const GUID: TGUID): string;
function IsEqualGUID(const guid1, guid2: TGUID): boolean;
{$IFDEF MSWINDOWS}
stdcall;
{$EXTERNALSYM IsEqualGUID}
{$ENDIF}

{ Package support routines }

{ Package Info flags }

const
  pfNeverBuild                          = $00000001;
  pfDesignOnly                          = $00000002;
  pfRunOnly                             = $00000004;
  pfIgnoreDupUnits                      = $00000008;
  pfModuleTypeMask                      = $C0000000;
  pfExeModule                           = $00000000;
  pfPackageModule                       = $40000000;
  pfProducerMask                        = $0C000000;
  pfV3Produced                          = $00000000;
  pfProducerUndefined                   = $04000000;
  pfBCB4Produced                        = $08000000;
  pfDelphi4Produced                     = $0C000000;
  pfLibraryModule                       = $80000000;

   { Unit info flags }

const
  ufMainUnit                            = $01;
  ufPackageUnit                         = $02;
  ufWeakUnit                            = $04;
  ufOrgWeakUnit                         = $08;
  ufImplicitUnit                        = $10;

  ufWeakPackageUnit                     = ufPackageUnit or ufWeakUnit;

{$IFDEF LINUX}
var
  PkgLoadingMode                        : integer = RTLD_LAZY;
{$ENDIF}

   { Procedure type of the callback given to GetPackageInfo.  Name is the actual
     name of the package element.  If IsUnit is True then Name is the name of
     a contained unit; a required package if False.  Param is the value passed
     to GetPackageInfo }

type
  TNameType = (ntContainsUnit, ntRequiresPackage, ntDcpBpiName);

  TPackageInfoProc = procedure(const Name: string; NameType: TNameType; Flags: Byte; Param: Pointer);

   { LoadPackage loads a given package DLL, checks for duplicate units and
     calls the initialization blocks of all the contained units }

function LoadPackage(const Name: string): HMODULE;

{ UnloadPackage does the opposite of LoadPackage by calling the finalization
  blocks of all contained units, then unloading the package DLL }

procedure UnloadPackage(Module: HMODULE);

{ GetPackageInfo accesses the given package's info table and enumerates
  all the contained units and required packages }

procedure GetPackageInfo(Module: HMODULE; Param: Pointer; var Flags: integer;
  InfoProc: TPackageInfoProc);

{ GetPackageDescription loads the description resource from the package
  library. If the description resource does not exist,
  an empty string is returned. }
function GetPackageDescription(ModuleName: PChar): string;

{ InitializePackage validates and initializes the given package DLL }

procedure InitializePackage(Module: HMODULE);

{ FinalizePackage finalizes the given package DLL }

procedure FinalizePackage(Module: HMODULE);

{ RaiseLastOSError calls GetLastError to retrieve the code for
  the last occuring error in a call to an OS or system library function.
  If GetLastError returns an error code,  RaiseLastOSError raises
  an EOSError exception with the error code and a system-provided
  message associated with with error. }

procedure RaiseLastOSError;

{$IFDEF MSWINDOWS}
procedure RaiseLastWin32Error;
deprecated; // use RaiseLastOSError

{ Win32Check is used to check the return value of a Win32 API function     }
{ which returns a BOOL to indicate success.  If the Win32 API function     }
{ returns False (indicating failure), Win32Check calls RaiseLastOSError }
{ to raise an exception.  If the Win32 API function returns True,          }
{ Win32Check returns True. }

function Win32Check(RetVal: BOOL): BOOL;
platform;
{$ENDIF}

{ Termination procedure support }

type
  TTerminateProc = function: boolean;

   { Call AddTerminateProc to add a terminate procedure to the system list of }
   { termination procedures.  Delphi will call all of the function in the     }
   { termination procedure list before an application terminates.  The user-  }
   { defined TermProc function should return True if the application can      }
   { safely terminate or False if the application cannot safely terminate.    }
   { If one of the functions in the termination procedure list returns False, }
   { the application will not terminate. }

procedure AddTerminateProc(TermProc: TTerminateProc);

{ CallTerminateProcs is called by VCL when an application is about to }
{ terminate.  It returns True only if all of the functions in the     }
{ system's terminate procedure list return True.  This function is    }
{ intended only to be called by Delphi, and it should not be called   }
{ directly. }

function CallTerminateProcs: boolean;

function GDAL: LongWord;
procedure RCS;
procedure RPR;

{ HexDisplayPrefix contains the prefix to display on hexadecimal
  values - '$' for Pascal syntax, '0x' for C++ syntax.  This is
  for display only - this does not affect the string-to-integer
  conversion routines. }
var
  HexDisplayPrefix                      : string = '$';

{$IFDEF MSWINDOWS}
   { The GetDiskFreeSpace Win32 API does not support partitions larger than 2GB
     under Win95.  A new Win32 function, GetDiskFreeSpaceEx, supports partitions
     larger than 2GB but only exists on Win NT 4.0 and Win95 OSR2.
     The GetDiskFreeSpaceEx function pointer variable below will be initialized
     at startup to point to either the actual OS API function if it exists on
     the system, or to an internal Delphi function if it does not.  When running
     on Win95 pre-OSR2, the output of this function will still be limited to
     the 2GB range reported by Win95, but at least you don't have to worry
     about which API function to call in code you write.  }

var
  GetDiskFreeSpaceEx                    : function(Directory: PChar; var FreeAvailable,
    TotalSpace: TLargeInteger; TotalFree: PLargeInteger): BOOL stdcall = nil;

   { SafeLoadLibrary calls LoadLibrary, disabling normal Win32 error message
     popup dialogs if the requested file can't be loaded.  SafeLoadLibrary also
     preserves the current FPU control word (precision, exception masks) across
     the LoadLibrary call (in case the DLL you're loading hammers the FPU control
     word in its initialization, as many MS DLLs do)}

function SafeLoadLibrary(const FileName: string;
  ErrorMode: UINT = SEM_NOOPENFILEERRORBOX): HMODULE;

{$ENDIF}
{ Thread synchronization }

{ IReadWriteSync is an abstract interface for general read/write synchronization.
  Some implementations may allow simultaneous readers, but writers always have
  exclusive locks.

  Worst case is that this class behaves identical to a TRTLCriticalSection -
  that is, read and write locks block all other threads. }

type
  IReadWriteSync = interface
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: boolean;
    procedure EndWrite;
  end;

  TSimpleRWSync = class(TInterfacedObject, IReadWriteSync)
  private
    FLock: TRTLCriticalSection;
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: boolean;
    procedure EndWrite;
  end;

   { TThreadLocalCounter

     This class implements a lightweight non-blocking thread local storage
     mechanism specifically built for tracking per-thread recursion counts
     in TMultiReadExclusiveWriteSynchronizer.  This class is intended for
     Delphi RTL internal use only.  In the future it may be generalized
     and "hardened" for general application use, but until then leave it alone.

     Rules of Use:
     The tls object must be opened to gain access to the thread-specific data
     structure.  If a threadinfo block does not exist for the current thread,
     Open will allocate one.  Every call to Open must be matched with a call
     to Close.  The pointer returned by Open is invalid after the matching call
     to Close.

     The thread info structure is unique to each thread.  Once you have it, it's
     yours.  You don't need to guard against concurrent access to the thread
     data by multiple threads - your thread is the only thread that will ever
     have access to the structure that Open returns.  The thread info structure
     is allocated and owned by the tls object.  If you put allocated pointers
     in the thread info make sure you free them before you delete the threadinfo
     node.

     When thread data is no longer needed, call the Delete method on the pointer.
     This must be done between calls to Open and Close.  Delete schedules the
     pointer for destruction, but the pointer (and its data) will still be
     valid until Close is called.

     Important:  Do not keep the tls object open for long periods of time.  The
     tls object performs internal cleanup only when no threads have the
     tls object in the open state.  In particular, be careful not to wait on
     a thread synchronization event or critical section while you
     have the tls object open.  It's much better to open and close the tls
     object before and after the blocking event than to leave the tls object
     open while waiting.

     Implementation Notes:
     The main purpose of this storage class is to provide thread-local storage
     without using limited / problematic OS tls slots and without requiring
     expensive blocking thread synchronization.  This class performs no
     blocking waits or spin loops!  (except for memory allocation)

     Thread info is kept in linked lists to facilitate non-blocking threading
     techniques.  A hash table indexed by a hash of the current thread ID
     reduces linear search times.

     When a node is deleted, it is moved out of the hash table lists into
     the purgatory list.  The hash table no longer points to the deleted node,
     but the deleted node's next pointer still points into the hash table.  This
     is so that deleting a node will not interrupt other threads that are
     traversing the list concurrent with the deletion.  If another thread is
     visiting a node while it is being deleted, the thread will follow the
     node's next pointer and get back into the live list without interruption.

     The purgatory list is liked through the nodes' NextDead field.  Again, this
     is to preserve the exit path of other threads still visiting the deleted
     node.

     When the last concurrent use of the tls object is closed (when FOpenCount
     drops to zero), all nodes in the purgatory list are reviewed for destruction
     or recycling. It's safe to do this without a thread synchronization lock
     because we know there are no threads visiting any of the nodes.  Newly
     deleted nodes are cleared of their thread identity and assigned a clock tick
     expiration value.  If a deleted node has been in the purgatory for longer
     than the holding period, Close will free the node.  When Open needs to
     allocate a new node for a new thread, it first tries to recycle an old node
     from the purgatory.  If nothing is available for recycling, Open allocates
     new memory.  The default holding period is one minute.

     Note that nodes enter the holding pattern when the tls object is closed.
     They won't be reviewed for destruction until the *next* time the tls
     object transitions into the closed state.  This is intentional, to
     reduce memory allocation thrashing when multiple threads open, delete,
     and close tls frequently, as will be the case with non-recursive read
     locks in TMREWSync.

     Close grabs the purgatory list before checking the FOpenCount to avoid
     race conditions with other threads reopening the tls while Close is
     executing.  If FOpenCount is not yet zero, Close has to put the purgatory
     list back together (Reattach), including any items added to the
     purgatory list after Close swiped it.  Since the number of thread
     participants should be small (less than 32) and the frequency of deletions
     relative to thread data access should be low, the purgatory list should
     never grow large enough to make this non-blocking Close implementation a
     performance problem.

     The linked list management relies heavily on InterlockedExchange to perform
     atomic node pointer replacements.  There are brief windows of time where
     the linked list may be circular while a two-step insertion takes place.
     During that brief window, other threads traversing the lists may see
     the same node more than once more than once. (pun!) This is fine for what this
     implementation needs.  Don't do anything silly like try to count the
     nodes during a traversal.
   }

type
  PThreadInfo = ^TThreadInfo;
  TThreadInfo = record
    Next: PThreadInfo;
    NextDead: PThreadInfo;
    ThreadID: Cardinal;
    RecursionCount: Cardinal;
  end;

  TThreadLocalCounter = class
  private
    FHashTable: array[0..15] of PThreadInfo;
    FPurgatory: PThreadInfo;
    FOpenCount: integer;
    function HashIndex: Byte;
    function Recycle: PThreadInfo;
    procedure Reattach(List: PThreadInfo);
  protected
    FHoldTime: Cardinal;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open(var Thread: PThreadInfo);
    procedure Delete(var Thread: PThreadInfo);
    procedure Close(var Thread: PThreadInfo);
  end;

{$IFDEF MSWINDOWS}

   { TMultiReadExclusiveWriteSynchronizer minimizes thread serialization to gain
     read access to a resource shared among threads while still providing complete
     exclusivity to callers needing write access to the shared resource.
     (multithread shared reads, single thread exclusive write)
     Read locks are allowed while owning a write lock.
     Read locks can be promoted to write locks within the same thread.
     (BeginRead, BeginWrite, EndWrite, EndRead)

     Note: Other threads have an opportunity to modify the protected resource
     when you call BeginWrite before you are granted the write lock, even
     if you already have a read lock open.  Best policy is not to retain
     any info about the protected resource (such as count or size) across a
     write lock.  Always reacquire samples of the protected resource after
     acquiring or releasing a write lock.

     The function result of BeginWrite indicates whether another thread got
     the write lock while the current thread was waiting for the write lock.
     Return value of True means that the write lock was acquired without
     any intervening modifications by other threads.  Return value of False
     means another thread got the write lock while you were waiting, so the
     resource protected by the MREWS object should be considered modified.
     Any samples of the protected resource should be discarded.

     In general, it's better to just always reacquire samples of the protected
     resource after obtaining a write lock.  The boolean result of BeginWrite
     and the RevisionLevel property help cases where reacquiring the samples
     is computationally expensive or time consuming.

     RevisionLevel changes each time a write lock is granted.  You can test
     RevisionLevel for equality with a previously sampled value of the property
     to determine if a write lock has been granted, implying that the protected
     resource may be changed from its state when the original RevisionLevel
     value was sampled.  Do not rely on the sequentiality of the current
     RevisionLevel implementation (it will wrap around to zero when it tops out).
     Do not perform greater than / less than comparisons on RevisionLevel values.
     RevisionLevel indicates only the stability of the protected resource since
     your original sample.  It should not be used to calculate how many
     revisions have been made.
   }

type
  TMultiReadExclusiveWriteSynchronizer = class(TInterfacedObject, IReadWriteSync)
  private
    FSentinel: integer;
    FReadSignal: THandle;
    FWriteSignal: THandle;
    FWaitRecycle: Cardinal;
    FWriteRecursionCount: Cardinal;
    tls: TThreadLocalCounter;
    FWriterID: Cardinal;
    FRevisionLevel: Cardinal;
    procedure BlockReaders;
    procedure UnblockReaders;
    procedure UnblockOneWriter;
    procedure WaitForReadSignal;
    procedure WaitForWriteSignal;
{$IFDEF DEBUG_MREWS}
    procedure Debug(const Msg: string);
{$ENDIF}
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginRead;
    procedure EndRead;
    function BeginWrite: boolean;
    procedure EndWrite;
    property RevisionLevel: Cardinal read FRevisionLevel;
  end;
{$ELSE}
type
  TMultiReadExclusiveWriteSynchronizer = TSimpleRWSync;
{$ENDIF}

type
  TMREWSync = TMultiReadExclusiveWriteSynchronizer; // short form

function GetEnvironmentVariable(const Name: string): string; overload;

{$IFDEF LINUX}
function InterlockedIncrement(var I: integer): integer;
function InterlockedDecrement(var I: integer): integer;
function InterlockedExchange(var a: integer; b: integer): integer;
function InterlockedExchangeAdd(var a: integer; b: integer): integer;
{$ENDIF}

implementation

{$IFDEF LINUX}
{
        Exceptions raised in methods that are safecall will be filtered
        through the virtual method SafeCallException on the class.  The
        implementation of this method under Linux has the option of setting
        the following thread vars:  SafeCallExceptionMsg, SafeCallExceptionAddr.
        If these are set, then the implementation of SafeCallError here will
        reraise a generic exception based on these.  One might consider actually
        having the SafeCallException implementation store off the exception
        object itself, but this raises the issue that the exception object
        might have to live a long time (if an external application calls a
        Delphi safecall method).  Since an arbitrary exception object could
        be holding large resources hostage, we hold only the string and
        address as a hedge.
}
threadvar
  SafeCallExceptionMsg                  : string;
  SafeCallExceptionAddr                 : Pointer;

procedure SetSafeCallExceptionMsg(Msg: string);
begin
  SafeCallExceptionMsg := Msg;
end;

procedure SetSafeCallExceptionAddr(Addr: Pointer);
begin
  SafeCallExceptionAddr := Addr;
end;

function GetSafeCallExceptionMsg: string;
begin
  Result := SafeCallExceptionMsg;
end;

function GetSafeCallExceptionAddr: Pointer;
begin
  Result := SafeCallExceptionAddr;
end;
{$ENDIF}

{ Utility routines }

procedure DivMod(Dividend: integer; Divisor: Word;
  var Result, Remainder: Word);
asm
        PUSH    EBX
        MOV     EBX,EDX
        MOV     EDX,EAX
        SHR     EDX,16
        DIV     BX
        MOV     EBX,Remainder
        MOV     [ECX],AX
        MOV     [EBX],DX
        POP     EBX
end;

{$IFDEF PIC}

function GetGOT: Pointer; export;
begin
  asm
        MOV     Result,EBX
  end;
end;
{$ENDIF}

procedure ConvertError(ResString: PResStringRec);
local;
begin
  raise EConvertError.CreateRes(ResString);
end;

{$IFDEF MSWINDOWS}
{$EXTERNALSYM CoCreateGuid}

function CoCreateGuid(out guid: TGUID): HResult; stdcall; external 'ole32.dll' Name 'CoCreateGuid';

function CreateGUID(out Guid: TGUID): HResult;
begin
  Result := CoCreateGuid(Guid);
end;
//function CreateGUID; external 'ole32.dll' name 'CoCreateGuid';
{$ENDIF}
{$IFDEF LINUX}

{ CreateGUID }

{ libuuid.so implements the tricky code to create GUIDs using the
  MAC address of the network adapter plus other flavor bits.
  libuuid.so is currently distributed with the ext2 file system
  package, but does not depend upon the ext2 file system libraries.
  Ideally, libuuid.so should be distributed separately.

  If you do not have libuuid.so.1 on your Linux distribution, you
  can extract the library from the e2fsprogs RPM.

  Note:  Do not use the generic uuid_generate function in libuuid.so.
  In the current implementation (e2fsprogs-1.19), uuid_generate
  gives preference to generating guids entirely from random number
  streams over generating guids based on the NIC MAC address.
  No matter how "random" a random number generator is, it will
  never produce guids that can be guaranteed unique across all
  systems on the planet.  MAC-address based guids are guaranteed
  unique because the MAC address of the NIC is guaranteed unique
  by the manufacturer.

  For this reason, we call uuid_generate_time instead of the
  generic uuid_generate.  uuid_generate_time constructs the guid
  using the MAC address, and falls back to randomness if no NIC
  can be found.  }

var
  libuuidHandle                         : Pointer;
  uuid_generate_time                    : procedure(out Guid: TGUID) cdecl;

function CreateGUID(out Guid: TGUID): HResult;

const
  E_NOTIMPL                             = HResult($80004001);

begin
  Result := E_NOTIMPL;
  if libuuidHandle = nil then
  begin
    libuuidHandle := dlopen('libuuid.so.1', RTLD_LAZY);
    if libuuidHandle = nil then Exit;
    uuid_generate_time := dlsym(libuuidHandle, 'uuid_generate_time');
    if @uuid_generate_time = nil then Exit;
  end;
  uuid_generate_time(Guid);
  Result := 0;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}

function StringFromCLSID(const clsid: TGUID; out psz: PWideChar): HResult; stdcall;
  external 'ole32.dll' Name 'StringFromCLSID';

procedure CoTaskMemFree(pv: Pointer); stdcall;
  external 'ole32.dll' Name 'CoTaskMemFree';

function CLSIDFromString(psz: PWideChar; out clsid: TGUID): HResult; stdcall;
  external 'ole32.dll' Name 'CLSIDFromString';
{$ENDIF MSWINDOWS}



function GUIDToString(const GUID: TGUID): string;
var
  p                                     : PWideChar;
begin
  if not Succeeded(StringFromCLSID(GUID, p)) then
    ConvertError(@SInvalidGUID);
  Result := p;
  CoTaskMemFree(p);
end;



{ Memory management routines }

function AllocMem(Size: Cardinal): Pointer;
begin
  GetMem(Result, Size);
  FillChar(Result^, Size, 0);
end;

{ Exit procedure handling }

type
  PExitProcInfo = ^TExitProcInfo;
  TExitProcInfo = record
    Next: PExitProcInfo;
    SaveExit: Pointer;
    Proc: TProcedure;
  end;

var
  ExitProcList                          : PExitProcInfo = nil;

procedure DoExitProc;
var
  p                                     : PExitProcInfo;
  Proc                                  : TProcedure;
begin
  p := ExitProcList;
  ExitProcList := p^.Next;
  ExitProc := p^.SaveExit;
  Proc := p^.Proc;
  Dispose(p);
  Proc;
end;

procedure AddExitProc(Proc: TProcedure);
var
  p                                     : PExitProcInfo;
begin
  New(p);
  p^.Next := ExitProcList;
  p^.SaveExit := ExitProc;
  p^.Proc := Proc;
  ExitProcList := p;
  ExitProc := @DoExitProc;
end;

{ String handling routines }

function NewStr(const s: string): pSTRING;
begin
  if s = '' then Result := NullStr else
  begin
    New(Result);
    Result^ := s;
  end;
end;

procedure DisposeStr(p: pSTRING);
begin
  if (p <> nil) and (p^ <> '') then Dispose(p);
end;

procedure AssignStr(var p: pSTRING; const s: string);
var
  temp                                  : pSTRING;
begin
  temp := p;
  p := NewStr(s);
  DisposeStr(temp);
end;

procedure AppendStr(var Dest: string; const s: string);
begin
  Dest := Dest + s;
end;

function UpperCase(const s: string): string;
var
  ch                                    : Char;
  l                                     : integer;
  Source, Dest                          : PChar;
begin
  l := length(s);
  SetLength(Result, l);
  Source := Pointer(s);
  Dest := Pointer(Result);
  while l <> 0 do
  begin
    ch := Source^;
    if (ch >= 'a') and (ch <= 'z') then Dec(ch, 32);
    Dest^ := ch;
    inc(Source);
    inc(Dest);
    Dec(l);
  end;
end;

function LowerCase(const s: string): string;
var
  ch                                    : Char;
  l                                     : integer;
  Source, Dest                          : PChar;
begin
  l := length(s);
  SetLength(Result, l);
  Source := Pointer(s);
  Dest := Pointer(Result);
  while l <> 0 do
  begin
    ch := Source^;
    if (ch >= 'A') and (ch <= 'Z') then inc(ch, 32);
    Dest^ := ch;
    inc(Source);
    inc(Dest);
    Dec(l);
  end;
end;

function CompareStr(const s1, s2: string): integer; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        MOV     ESI,EAX
        MOV     EDI,EDX
        OR      EAX,EAX
        JE      @@1
        MOV     EAX,[EAX-4]
@@1:    OR      EDX,EDX
        JE      @@2
        MOV     EDX,[EDX-4]
@@2:    MOV     ECX,EAX
        CMP     ECX,EDX
        JBE     @@3
        MOV     ECX,EDX
@@3:    CMP     ECX,ECX
        REPE    CMPSB
        JE      @@4
        MOVZX   EAX,BYTE PTR [ESI-1]
        MOVZX   EDX,BYTE PTR [EDI-1]
@@4:    SUB     EAX,EDX
        POP     EDI
        POP     ESI
end;

function CompareMem(P1, P2: Pointer; length: integer): boolean; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        MOV     ESI,P1
        MOV     EDI,P2
        MOV     EDX,ECX
        XOR     EAX,EAX
        AND     EDX,3
        SHR     ECX,1
        SHR     ECX,1
        REPE    CMPSD
        JNE     @@2
        MOV     ECX,EDX
        REPE    CMPSB
        JNE     @@2
        INC     EAX
@@2:    POP     EDI
        POP     ESI
end;

function CompareText(const s1, s2: string): integer; assembler;
asm
        PUSH    ESI
        PUSH    EDI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        OR      EAX,EAX
        JE      @@0
        MOV     EAX,[EAX-4]
@@0:    OR      EDX,EDX
        JE      @@1
        MOV     EDX,[EDX-4]
@@1:    MOV     ECX,EAX
        CMP     ECX,EDX
        JBE     @@2
        MOV     ECX,EDX
@@2:    CMP     ECX,ECX
@@3:    REPE    CMPSB
        JE      @@6
        MOV     BL,BYTE PTR [ESI-1]
        CMP     BL,'a'
        JB      @@4
        CMP     BL,'z'
        JA      @@4
        SUB     BL,20H
@@4:    MOV     BH,BYTE PTR [EDI-1]
        CMP     BH,'a'
        JB      @@5
        CMP     BH,'z'
        JA      @@5
        SUB     BH,20H
@@5:    CMP     BL,BH
        JE      @@3
        MOVZX   EAX,BL
        MOVZX   EDX,BH
@@6:    SUB     EAX,EDX
        POP     EBX
        POP     EDI
        POP     ESI
end;

function SameText(const s1, s2: string): boolean; assembler;
asm
        CMP     EAX,EDX
        JZ      @1
        OR      EAX,EAX
        JZ      @2
        OR      EDX,EDX
        JZ      @3
        MOV     ECX,[EAX-4]
        CMP     ECX,[EDX-4]
        JNE     @3
        CALL    CompareText
        TEST    EAX,EAX
        JNZ     @3
@1:     MOV     AL,1
@2:     RET
@3:     XOR     EAX,EAX
end;

function AnsiUpperCase(const s: string): string;
{$IFDEF MSWINDOWS}
var
  Len                                   : integer;
begin
  Len := length(s);
  SetString(Result, PChar(s), Len);
  if Len > 0 then CharUpperBuff(Pointer(Result), Len);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := WideUpperCase(s);
end;
{$ENDIF}

function AnsiLowerCase(const s: string): string;
{$IFDEF MSWINDOWS}
var
  Len                                   : integer;
begin
  Len := length(s);
  SetString(Result, PChar(s), Len);
  if Len > 0 then CharLowerBuff(Pointer(Result), Len);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := WideLowerCase(s);
end;
{$ENDIF}

function AnsiCompareStr(const s1, s2: string): integer;
begin
{$IFDEF MSWINDOWS}
  Result := CompareString(LOCALE_USER_DEFAULT, 0, PChar(s1), length(s1),
    PChar(s2), length(s2)) - 2;
{$ENDIF}
{$IFDEF LINUX}
   // glibc 2.1.2 / 2.1.3 implementations of strcoll() and strxfrm()
   // have severe capacity limits.  Comparing two 100k strings may
   // exhaust the stack and kill the process.
   // Fixed in glibc 2.1.91 and later.
  Result := strcoll(PChar(s1), PChar(s2));
{$ENDIF}
end;

function AnsiSameStr(const s1, s2: string): boolean;
begin
  Result := AnsiCompareStr(s1, s2) = 0;
end;

function AnsiCompareText(const s1, s2: string): integer;
begin
{$IFDEF MSWINDOWS}
  Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PChar(s1),
    length(s1), PChar(s2), length(s2)) - 2;
{$ENDIF}
{$IFDEF LINUX}
  Result := WideCompareText(s1, s2);
{$ENDIF}
end;

function AnsiSameText(const s1, s2: string): boolean;
begin
  Result := AnsiCompareText(s1, s2) = 0;
end;

function AnsiStrComp(s1, s2: PChar): integer;
begin
{$IFDEF MSWINDOWS}
  Result := CompareString(LOCALE_USER_DEFAULT, 0, s1, -1, s2, -1) - 2;
{$ENDIF}
{$IFDEF LINUX}
  Result := strcoll(s1, s2);
{$ENDIF}
end;

function AnsiStrIComp(s1, s2: PChar): integer;
begin
{$IFDEF MSWINDOWS}
  Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE, s1, -1,
    s2, -1) - 2;
{$ENDIF}
{$IFDEF LINUX}
  Result := AnsiCompareText(s1, s2);
{$ENDIF}
end;

// StrLenLimit:  Scan Src for a null terminator up to MaxLen bytes

function StrLenLimit(Src: PChar; MaxLen: Cardinal): Cardinal;
begin
  if Src = nil then
  begin
    Result := 0;
    Exit;
  end;
  Result := MaxLen;
  while (Src^ <> #0) and (Result > 0) do
  begin
    inc(Src);
    Dec(Result);
  end;
  Result := MaxLen - Result;
end;

{ StrBufLimit: Return a pointer to a buffer that contains no more than MaxLen
  bytes of Src, avoiding heap allocation if possible.
  If clipped Src length is less than MaxLen, return Src.  Allocated = False.
  If clipped Src length is less than StaticBufLen, return StaticBuf with a
    copy of Src.  Allocated = False.
  Otherwise, return a heap allocated buffer with a copy of Src.  Allocated = True.
}

function StrBufLimit(Src: PChar; MaxLen: Cardinal; StaticBuf: PChar;
  StaticBufLen: Cardinal; var Allocated: boolean): PChar;
var
  Len                                   : Cardinal;
begin
  Len := StrLenLimit(Src, MaxLen);
  Allocated := False;
  if Len < MaxLen then
    Result := Src
  else
  begin
    if Len < StaticBufLen then
      Result := StaticBuf
    else
      GetMem(Result, Len + 1);
    Move(Src^, Result^, Len);
    Result[Len] := #0;
  end;
end;

function InternalAnsiStrLComp(s1, s2: PChar; MaxLen: Cardinal; CaseSensitive: boolean): integer;
var
  buf1, buf2                            : array[0..4095] of Char;
  P1, P2                                : PChar;
  Allocated1, Allocated2                : boolean;
begin
   // glibc has no length-limited strcoll!
  P1 := nil;
  P2 := nil;
  Allocated1 := False;
  Allocated2 := False;
  try
    P1 := StrBufLimit(s1, MaxLen, buf1, High(buf1), Allocated1);
    P2 := StrBufLimit(s2, MaxLen, buf2, High(buf2), Allocated2);
    if CaseSensitive then
      Result := AnsiStrComp(P1, P2)
    else
      Result := AnsiStrIComp(P1, P2);
  finally
    if Allocated1 then
      FreeMem(P1);
    if Allocated2 then
      FreeMem(P2);
  end;
end;

function AnsiStrLComp(s1, s2: PChar; MaxLen: Cardinal): integer;
{$IFDEF MSWINDOWS}
begin
  Result := CompareString(LOCALE_USER_DEFAULT, 0,
    s1, MaxLen, s2, MaxLen) - 2;
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := InternalAnsiStrLComp(s1, s2, MaxLen, True);
end;
{$ENDIF}

function AnsiStrLIComp(s1, s2: PChar; MaxLen: Cardinal): integer;
begin
{$IFDEF MSWINDOWS}
  Result := CompareString(LOCALE_USER_DEFAULT, NORM_IGNORECASE,
    s1, MaxLen, s2, MaxLen) - 2;
{$ENDIF}
{$IFDEF LINUX}
  Result := InternalAnsiStrLComp(s1, s2, MaxLen, False);
{$ENDIF}
end;

function AnsiStrLower(Str: PChar): PChar;
{$IFDEF MSWINDOWS}
begin
  CharLower(Str);
  Result := Str;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  temp                                  : WideString;
  Squish                                : AnsiString;
  I                                     : integer;
begin
  temp := Str; // expand and copy multibyte to widechar
  for I := 1 to length(temp) do
    temp[I] := widechar(towlower(UCS4Char(temp[I])));
  Squish := temp; // reduce and copy widechar to multibyte
  assert(Cardinal(length(Squish)) <= StrLen(Str));
  Move(Squish[1], Str^, length(Squish));
  Result := Str;
end;
{$ENDIF}

function AnsiStrUpper(Str: PChar): PChar;
{$IFDEF MSWINDOWS}
begin
  CharUpper(Str);
  Result := Str;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  temp                                  : WideString;
  Squish                                : AnsiString;
  I                                     : integer;
begin
  temp := Str; // expand and copy multibyte to widechar
  for I := 1 to length(temp) do
    temp[I] := widechar(towupper(UCS4Char(temp[I])));
  Squish := temp; // reduce and copy widechar to multibyte
  assert(Cardinal(length(Squish)) <= StrLen(Str));
  Move(Squish[1], Str^, length(Squish));
  Result := Str;
end;
{$ENDIF}

function WideUpperCase(const s: WideString): WideString;
{$IFDEF MSWINDOWS}
var
  Len                                   : integer;
begin
  Len := length(s);
  SetString(Result, PWideChar(s), Len);
  if Len > 0 then CharUpperBuffW(Pointer(Result), Len);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  I                                     : integer;
begin
  Result := s;
  for I := 1 to length(Result) do
    Result[I] := widechar(towupper(UCS4Char(Result[I])));
end;
{$ENDIF}

function WideLowerCase(const s: WideString): WideString;
{$IFDEF MSWINDOWS}
var
  Len                                   : integer;
begin
  Len := length(s);
  SetString(Result, PWideChar(s), Len);
  if Len > 0 then CharLowerBuffW(Pointer(Result), Len);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  I                                     : integer;
begin
  Result := s;
  for I := 1 to length(Result) do
    Result[I] := widechar(towlower(UCS4Char(Result[I])));
end;
{$ENDIF}

{$IFDEF MSWINDOWS}

function DumbItDownFor95(const s1, s2: WideString; CmpFlags: integer): integer;
var
  a1, a2                                : AnsiString;
begin
  a1 := s1;
  a2 := s2;
  Result := CompareStringA(LOCALE_USER_DEFAULT, CmpFlags, PChar(a1), length(a1),
    PChar(a2), length(a2)) - 2;
end;
{$ENDIF}

function WideCompareStr(const s1, s2: WideString): integer;
{$IFDEF MSWINDOWS}
begin
  SetLastError(0);
  Result := CompareStringW(LOCALE_USER_DEFAULT, 0, PWideChar(s1), length(s1),
    PWideChar(s2), length(s2)) - 2;
  case getlasterror of
    0: ;
    ERROR_CALL_NOT_IMPLEMENTED: Result := DumbItDownFor95(s1, s2, 0);
  else
    RaiseLastOSError;
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  UCS4_S1, UCS4_S2                      : UCS4String;
begin
  UCS4_S1 := WideStringToUCS4String(s1);
  UCS4_S2 := WideStringToUCS4String(s2);
   // glibc 2.1.2 / 2.1.3 implementations of wcscoll() and wcsxfrm()
   // have severe capacity limits.  Comparing two 100k strings may
   // exhaust the stack and kill the process.
   // Fixed in glibc 2.1.91 and later.
  SetLastError(0);
  Result := wcscoll(PUCS4Chars(UCS4_S1), PUCS4Chars(UCS4_S2));
  if getlasterror <> 0 then
    RaiseLastOSError;
end;
{$ENDIF}

function WideSameStr(const s1, s2: WideString): boolean;
begin
  Result := WideCompareStr(s1, s2) = 0;
end;

function WideCompareText(const s1, s2: WideString): integer;
begin
{$IFDEF MSWINDOWS}
  SetLastError(0);
  Result := CompareStringW(LOCALE_USER_DEFAULT, NORM_IGNORECASE, PWideChar(s1),
    length(s1), PWideChar(s2), length(s2)) - 2;
  case getlasterror of
    0: ;
    ERROR_CALL_NOT_IMPLEMENTED: Result := DumbItDownFor95(s1, s2, NORM_IGNORECASE);
  else
    RaiseLastOSError;
  end;
{$ENDIF}
{$IFDEF LINUX}
  Result := WideCompareStr(WideUpperCase(s1), WideUpperCase(s2));
{$ENDIF}
end;

function WideSameText(const s1, s2: WideString): boolean;
begin
  Result := WideCompareText(s1, s2) = 0;
end;

function trim(const s: string): string;
var
  I, l                                  : integer;
begin
  l := length(s);
  I := 1;
  while (I <= l) and (s[I] <= ' ') do inc(I);
  if I > l then Result := '' else
  begin
    while s[l] <= ' ' do Dec(l);
    Result := Copy(s, I, l - I + 1);
  end;
end;

function trim(const s: WideString): WideString;
var
  I, l                                  : integer;
begin
  l := length(s);
  I := 1;
  while (I <= l) and (s[I] <= ' ') do inc(I);
  if I > l then
    Result := ''
  else
  begin
    while s[l] <= ' ' do Dec(l);
    Result := Copy(s, I, l - I + 1);
  end;
end;

function TrimLeft(const s: string): string;
var
  I, l                                  : integer;
begin
  l := length(s);
  I := 1;
  while (I <= l) and (s[I] <= ' ') do inc(I);
  Result := Copy(s, I, MaxInt);
end;

function TrimLeft(const s: WideString): WideString;
var
  I, l                                  : integer;
begin
  l := length(s);
  I := 1;
  while (I <= l) and (s[I] <= ' ') do inc(I);
  Result := Copy(s, I, MaxInt);
end;

function TrimRight(const s: string): string;
var
  I                                     : integer;
begin
  I := length(s);
  while (I > 0) and (s[I] <= ' ') do Dec(I);
  Result := Copy(s, 1, I);
end;

function TrimRight(const s: WideString): WideString;
var
  I                                     : integer;
begin
  I := length(s);
  while (I > 0) and (s[I] <= ' ') do Dec(I);
  Result := Copy(s, 1, I);
end;

function QuotedStr(const s: string): string;
var
  I                                     : integer;
begin
  Result := s;
  for I := length(Result) downto 1 do
    if Result[I] = '''' then Insert('''', Result, I);
  Result := '''' + Result + '''';
end;

function AnsiQuotedStr(const s: string; Quote: Char): string;
var
  p, Src, Dest                          : PChar;
  AddCount                              : integer;
begin
  AddCount := 0;
  p := AnsiStrScan(PChar(s), Quote);
  while p <> nil do
  begin
    inc(p);
    inc(AddCount);
    p := AnsiStrScan(p, Quote);
  end;
  if AddCount = 0 then
  begin
    Result := Quote + s + Quote;
    Exit;
  end;
  SetLength(Result, length(s) + AddCount + 2);
  Dest := Pointer(Result);
  Dest^ := Quote;
  inc(Dest);
  Src := Pointer(s);
  p := AnsiStrScan(Src, Quote);
  repeat
    inc(p);
    Move(Src^, Dest^, p - Src);
    inc(Dest, p - Src);
    Dest^ := Quote;
    inc(Dest);
    Src := p;
    p := AnsiStrScan(Src, Quote);
  until p = nil;
  p := StrEnd(Src);
  Move(Src^, Dest^, p - Src);
  inc(Dest, p - Src);
  Dest^ := Quote;
end;

function AnsiExtractQuotedStr(var Src: PChar; Quote: Char): string;
var
  p, Dest                               : PChar;
  DropCount                             : integer;
begin
  Result := '';
  if (Src = nil) or (Src^ <> Quote) then Exit;
  inc(Src);
  DropCount := 1;
  p := Src;
  Src := AnsiStrScan(Src, Quote);
  while Src <> nil do // count adjacent pairs of quote chars
  begin
    inc(Src);
    if Src^ <> Quote then Break;
    inc(Src);
    inc(DropCount);
    Src := AnsiStrScan(Src, Quote);
  end;
  if Src = nil then Src := StrEnd(p);
  if ((Src - p) <= 1) then Exit;
  if DropCount = 1 then
    SetString(Result, p, Src - p - 1)
  else
  begin
    SetLength(Result, Src - p - DropCount);
    Dest := PChar(Result);
    Src := AnsiStrScan(p, Quote);
    while Src <> nil do
    begin
      inc(Src);
      if Src^ <> Quote then Break;
      Move(p^, Dest^, Src - p);
      inc(Dest, Src - p);
      inc(Src);
      p := Src;
      Src := AnsiStrScan(Src, Quote);
    end;
    if Src = nil then Src := StrEnd(p);
    Move(p^, Dest^, Src - p - 1);
  end;
end;

function AnsiDequotedStr(const s: string; AQuote: Char): string;
var
  LText                                 : PChar;
begin
  LText := PChar(s);
  Result := AnsiExtractQuotedStr(LText, AQuote);
  if Result = '' then
    Result := s;
end;

function AdjustLineBreaks(const s: string; Style: TTextLineBreakStyle): string;
var
  Source, SourceEnd, Dest               : PChar;
  DestLen                               : integer;
  l                                     : integer;
begin
  Source := Pointer(s);
  SourceEnd := Source + length(s);
  DestLen := length(s);
  while Source < SourceEnd do
  begin
    case Source^ of
      #10:
        if Style = tlbsCRLF then
          inc(DestLen);
      #13:
        if Style = tlbsCRLF then
          if Source[1] = #10 then
            inc(Source)
          else
            inc(DestLen)
        else
          if Source[1] = #10 then
            Dec(DestLen);
    else
      if Source^ in LeadBytes then
      begin
        Source := StrNextChar(Source);
        Continue;
      end;
    end;
    inc(Source);
  end;
  if DestLen = length(Source) then
    Result := s
  else
  begin
    Source := Pointer(s);
    SetString(Result, nil, DestLen);
    Dest := Pointer(Result);
    while Source < SourceEnd do
      case Source^ of
        #10:
          begin
            if Style = tlbsCRLF then
            begin
              Dest^ := #13;
              inc(Dest);
            end;
            Dest^ := #10;
            inc(Dest);
            inc(Source);
          end;
        #13:
          begin
            if Style = tlbsCRLF then
            begin
              Dest^ := #13;
              inc(Dest);
            end;
            Dest^ := #10;
            inc(Dest);
            inc(Source);
            if Source^ = #10 then inc(Source);
          end;
      else
        if Source^ in LeadBytes then
        begin
          l := StrCharLength(Source);
          Move(Source^, Dest^, l);
          inc(Dest, l);
          inc(Source, l);
          Continue;
        end;
        Dest^ := Source^;
        inc(Dest);
        inc(Source);
      end;
  end;
end;

function IsValidIdent(const Ident: string): boolean;
const
  Alpha                                 = ['A'..'Z', 'a'..'z', '_'];
  AlphaNumeric                          = Alpha + ['0'..'9'];
var
  I                                     : integer;
begin
  Result := False;
  if (length(Ident) = 0) or not (Ident[1] in Alpha) then Exit;
  for I := 2 to length(Ident) do
    if not (Ident[I] in AlphaNumeric) then Exit;
  Result := True;
end;





function StrToIntDef(const s: string; Default: integer): integer;
var
  E                                     : integer;
begin
  Val(s, Result, E);
  if E <> 0 then Result := Default;
end;

function TryStrToInt(const s: string; out Value: integer): boolean;
var
  E                                     : integer;
begin
  Val(s, Value, E);
  Result := E = 0;
end;


function StrToInt64Def(const s: string; const Default: int64): int64;
var
  E                                     : integer;
begin
  Val(s, Result, E);
  if E <> 0 then Result := Default;
end;

function TryStrToInt64(const s: string; out Value: int64): boolean;
var
  E                                     : integer;
begin
  Val(s, Value, E);
  Result := E = 0;
end;

procedure VerifyBoolStrArray;
begin
  if length(TrueBoolStrs) = 0 then
  begin
    SetLength(TrueBoolStrs, 1);
    TrueBoolStrs[0] := DefaultTrueBoolStr;
  end;
  if length(FalseBoolStrs) = 0 then
  begin
    SetLength(FalseBoolStrs, 1);
    FalseBoolStrs[0] := DefaultFalseBoolStr;
  end;
end;


function StrToBoolDef(const s: string; const Default: boolean): boolean;
begin
  if not TryStrToBool(s, Result) then
    Result := Default;
end;

function TryStrToBool(const s: string; out Value: boolean): boolean;

  function CompareWith(const aArray: array of string): boolean;
  var
    I                                   : integer;
  begin
    Result := False;
    for I := Low(aArray) to High(aArray) do
      if AnsiSameText(s, aArray[I]) then
      begin
        Result := True;
        Break;
      end;
  end;
var
  LRESULT                               : extended;
begin
  Result := TryStrToFloat(s, LRESULT);
  if Result then
    Value := LRESULT <> 0
  else
  begin
    VerifyBoolStrArray;
    if CompareWith(TrueBoolStrs) then
      Value := True
    else
      if CompareWith(FalseBoolStrs) then
        Value := False
      else
        Result := False;
  end;
end;

function BoolToStr(b: boolean; UseBoolStrs: boolean = False): string;
const
  cSimpleBoolStrs                       : array[boolean] of string = ('0', '-1');
begin
  if UseBoolStrs then
  begin
    VerifyBoolStrArray;
    if b then
      Result := TrueBoolStrs[0]
    else
      Result := FalseBoolStrs[0];
  end
  else
    Result := cSimpleBoolStrs[b];
end;

type
  PStrData = ^TStrData;
  TStrData = record
    Ident: integer;
    Str: string;
  end;

function EnumStringModules(Instance: LONGINT; data: Pointer): boolean;
{$IFDEF MSWINDOWS}
var
  Buffer                                : array[0..1023] of Char;
begin
  with PStrData(data)^ do
  begin
    SetString(Str, Buffer,
      LoadString(Instance, Ident, Buffer, SizeOf(Buffer)));
    Result := Str = '';
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  rs                                    : TResStringRec;
  Module                                : HMODULE;
begin
  Module := Instance;
  rs.Module := @Module;
  with PStrData(data)^ do
  begin
    rs.Identifier := Ident;
    Str := LoadResString(@rs);
    Result := Str = '';
  end;
end;
{$ENDIF}

function FindStringResource(Ident: integer): string;
var
  StrData                               : TStrData;
begin
  StrData.Ident := Ident;
  StrData.Str := '';
  EnumResourceModules(EnumStringModules, @StrData);
  Result := StrData.Str;
end;

function LoadStr(Ident: integer): string;
begin
  Result := FindStringResource(Ident);
end;


{ File management routines }

function FileOpen(const FileName: string; Mode: LongWord): integer;
{$IFDEF MSWINDOWS}
const
  AccessMode                            : array[0..2] of LongWord = (
    GENERIC_READ,
    GENERIC_WRITE,
    GENERIC_READ or GENERIC_WRITE);
  ShareMode                             : array[0..4] of LongWord = (
    0,
    0,
    FILE_SHARE_READ,
    FILE_SHARE_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE);
begin
  Result := -1;
  if ((Mode and 3) <= fmOpenReadWrite) and
    (((Mode and $F0) shr 4) <= fmShareDenyNone) then
    Result := integer(CreateFile(PChar(FileName), AccessMode[Mode and 3],
      ShareMode[(Mode and $F0) shr 4], nil, OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL, 0));
end;
{$ENDIF}
{$IFDEF LINUX}
const
  ShareMode                             : array[0..fmShareDenyNone shr 4] of Byte = (
    0, //No share mode specified
    F_WRLCK, //fmShareExclusive
    F_RDLCK, //fmShareDenyWrite
    0); //fmShareDenyNone
var
  FileHandle, Tvar                      : integer;
  LockVar                               : TFlock;
  smode                                 : Byte;
begin
  Result := -1;
  if (access(PChar(FileName), F_OK) = 0) and
    ((Mode and 3) <= fmOpenReadWrite) and
    (((Mode and $F0) shr 4) <= fmShareDenyNone) then
  begin
    FileHandle := Open(PChar(FileName), Mode and 3, FileAccessRights);

    if FileHandle = -1 then Exit;

    smode := Mode and $F0 shr 4;
    if ShareMode[smode] <> 0 then
    begin
      with LockVar do
      begin
        l_whence := SEEK_SET;
        l_start := 0;
        l_len := 0;
        l_type := ShareMode[smode];
      end;
      Tvar := fcntl(FileHandle, F_SETLK, LockVar);
      if Tvar = -1 then Exit;
    end;
    Result := FileHandle;
  end;
end;
{$ENDIF}

function FileCreate(const FileName: string): integer;
{$IFDEF MSWINDOWS}
begin
  Result := integer(CreateFile(PChar(FileName), GENERIC_READ or GENERIC_WRITE,
    0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0));
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := FileCreate(FileName, FileAccessRights);
end;
{$ENDIF}

function FileCreate(const FileName: string; Rights: integer): integer;
{$IFDEF MSWINDOWS}
begin
  Result := FileCreate(FileName);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := integer(Open(PChar(FileName), O_RDWR or O_CREAT or O_TRUNC, Rights));
end;
{$ENDIF}

function FileRead(Handle: integer; var Buffer; Count: LongWord): integer;
begin
{$IFDEF MSWINDOWS}
  if not ReadFile(THandle(Handle), Buffer, Count, LongWord(Result), nil) then
    Result := -1;
{$ENDIF}
{$IFDEF LINUX}
  Result := __read(Handle, Buffer, Count);
{$ENDIF}
end;

function FileWrite(Handle: integer; const Buffer; Count: LongWord): integer;
begin
{$IFDEF MSWINDOWS}
  if not WriteFile(THandle(Handle), Buffer, Count, LongWord(Result), nil) then
    Result := -1;
{$ENDIF}
{$IFDEF LINUX}
  Result := __write(Handle, Buffer, Count);
{$ENDIF}
end;

function FileSeek(Handle, Offset, Origin: integer): integer;
begin
{$IFDEF MSWINDOWS}
  Result := SetFilePointer(THandle(Handle), Offset, nil, Origin);
{$ENDIF}
{$IFDEF LINUX}
  Result := __lseek(Handle, Offset, Origin);
{$ENDIF}
end;

function FileSeek(Handle: integer; const Offset: int64; Origin: integer): int64;
begin
{$IFDEF MSWINDOWS}
  Result := Offset;
  Int64Rec(Result).Lo := SetFilePointer(THandle(Handle), Int64Rec(Result).Lo,
    @Int64Rec(Result).Hi, Origin);
{$ENDIF}
{$IFDEF LINUX}
  Result := FileSeek(Handle, integer(Offset), Origin);
{$ENDIF}
end;

procedure FileClose(Handle: integer);
begin
{$IFDEF MSWINDOWS}
  CloseHandle(THandle(Handle));
{$ENDIF}
{$IFDEF LINUX}
  __close(Handle); // No need to unlock since all locks are released on close.
{$ENDIF}
end;

function FileAge(const FileName: string): integer;
{$IFDEF MSWINDOWS}
var
  Handle                                : THandle;
  finddata                              : TWin32FindData;
  LocalFileTime                         : TFileTime;
begin
  Handle := FindFirstFile(PChar(FileName), finddata);
  if Handle <> INVALID_HANDLE_VALUE then
  begin
    Windows.FindClose(Handle);
    if (finddata.dwFileAttributes and FILE_ATTRIBUTE_DIRECTORY) = 0 then
    begin
      FileTimeToLocalFileTime(finddata.ftLastWriteTime, LocalFileTime);
      if FileTimeToDosDateTime(LocalFileTime, LongRec(Result).Hi,
        LongRec(Result).Lo) then Exit;
    end;
  end;
  Result := -1;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  st                                    : TStatBuf;
begin
  if stat(PChar(FileName), st) = 0 then
    Result := st.st_mtime
  else
    Result := -1;
end;
{$ENDIF}

function FileExists(const FileName: string): boolean;
{$IFDEF MSWINDOWS}
begin
  Result := FileAge(FileName) <> -1;
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := euidaccess(PChar(FileName), F_OK) = 0;
end;
{$ENDIF}

function DirectoryExists(const Directory: string): boolean;
{$IFDEF LINUX}
var
  st                                    : TStatBuf;
begin
  if stat(PChar(Directory), st) = 0 then
    Result := ((st.st_mode and __S_IFDIR) = __S_IFDIR)
  else
    Result := False;
end;
{$ENDIF}
{$IFDEF MSWINDOWS}
var
  code                                  : integer;
begin
  code := GetFileAttributes(PChar(Directory));
  Result := (code <> -1) and (FILE_ATTRIBUTE_DIRECTORY and code <> 0);
end;
{$ENDIF}

function ForceDirectories(dir: string): boolean;
begin
  Result := True;
  if length(dir) = 0 then
    raise Exception.CreateRes(@SCannotCreateDir);
  dir := ExcludeTrailingPathDelimiter(dir);
{$IFDEF MSWINDOWS}
  if (length(dir) < 3) or DirectoryExists(dir)
    or (ExtractFilePath(dir) = dir) then Exit; // avoid 'xyz:\' problem.
{$ENDIF}
{$IFDEF LINUX}
  if DirectoryExists(dir) then Exit;
{$ENDIF}
  Result := ForceDirectories(ExtractFilePath(dir)) and createdir(dir);
end;

function FileGetDate(Handle: integer): integer;
{$IFDEF MSWINDOWS}
var
  FileTime, LocalFileTime               : TFileTime;
begin
  if GetFileTime(THandle(Handle), nil, nil, @FileTime) and
    FileTimeToLocalFileTime(FileTime, LocalFileTime) and
    FileTimeToDosDateTime(LocalFileTime, LongRec(Result).Hi,
    LongRec(Result).Lo) then Exit;
  Result := -1;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  st                                    : TStatBuf;
begin
  if fstat(Handle, st) = 0 then
    Result := st.st_mtime
  else
    Result := -1;
end;
{$ENDIF}

function FileSetDate(const FileName: string; Age: integer): integer;
{$IFDEF MSWINDOWS}
var
  f                                     : THandle;
begin
  f := FileOpen(FileName, fmOpenwrite);
  if f = THandle(-1) then
    Result := getlasterror
  else
  begin
    Result := FileSetDate(f, Age);
    FileClose(f);
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  ut                                    : TUTimeBuffer;
begin
  Result := 0;
  ut.actime := Age;
  ut.modtime := Age;
  if utime(PChar(FileName), @ut) = -1 then
    Result := getlasterror;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}

function FileSetDate(Handle: integer; Age: integer): integer;
var
  LocalFileTime, FileTime               : TFileTime;
begin
  Result := 0;
  if DosDateTimeToFileTime(LongRec(Age).Hi, LongRec(Age).Lo, LocalFileTime) and
    LocalFileTimeToFileTime(LocalFileTime, FileTime) and
    SetFileTime(Handle, nil, nil, @FileTime) then Exit;
  Result := getlasterror;
end;

function FileGetAttr(const FileName: string): integer;
begin
  Result := GetFileAttributes(PChar(FileName));
end;

function FileSetAttr(const FileName: string; Attr: integer): integer;
begin
  Result := 0;
  if not SetFileAttributes(PChar(FileName), Attr) then
    Result := getlasterror;
end;
{$ENDIF}

function FileIsReadOnly(const FileName: string): boolean;
begin
{$IFDEF MSWINDOWS}
  Result := (GetFileAttributes(PChar(FileName)) and faReadOnly) <> 0;
{$ENDIF}
{$IFDEF LINUX}
  Result := (euidaccess(PChar(FileName), R_OK) = 0) and
    (euidaccess(PChar(FileName), W_OK) <> 0);
{$ENDIF}
end;

function FileSetReadOnly(const FileName: string; ReadOnly: boolean): boolean;
{$IFDEF MSWINDOWS}
var
  Flags                                 : integer;
begin
  Result := False;
  Flags := GetFileAttributes(PChar(FileName));
  if Flags = -1 then Exit;
  if ReadOnly then
    Flags := Flags or faReadOnly
  else
    Flags := Flags and not faReadOnly;
  Result := SetFileAttributes(PChar(FileName), Flags);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  st                                    : TStatBuf;
  Flags                                 : integer;
begin
  Result := False;
  if stat(PChar(FileName), st) <> 0 then Exit;
  if ReadOnly then
    Flags := st.st_mode and not (S_IWUSR or S_IWGRP or S_IWOTH)
  else
    Flags := st.st_mode or (S_IWUSR or S_IWGRP or S_IWOTH);
  Result := chmod(PChar(FileName), Flags) = 0;
end;
{$ENDIF}

function FindMatchingFile(var f: TSearchRec): integer;
{$IFDEF MSWINDOWS}
var
  LocalFileTime                         : TFileTime;
begin
  with f do
  begin
    while finddata.dwFileAttributes and ExcludeAttr <> 0 do
      if not FindNextFile(FindHandle, finddata) then
      begin
        Result := getlasterror;
        Exit;
      end;
    FileTimeToLocalFileTime(finddata.ftLastWriteTime, LocalFileTime);
    FileTimeToDosDateTime(LocalFileTime, LongRec(Time).Hi,
      LongRec(Time).Lo);
    Size := finddata.nFileSizeLow;
    Attr := finddata.dwFileAttributes;
    Name := finddata.cFilename;
  end;
  Result := 0;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  PtrDirEnt                             : PDirEnt;
  Scratch                               : TDirEnt;
  StatBuf                               : TStatBuf;
  fname                                 : string;
  Attr                                  : integer;
  Mode                                  : mode_t;
begin
  Result := -1;
  PtrDirEnt := nil;
  readdir_r(f.FindHandle, @Scratch, PtrDirEnt);
  while PtrDirEnt <> nil do
  begin
    if fnmatch(PChar(f.Pattern), PtrDirEnt.d_name, 0) = 0 then
    begin // F.PathOnly must include trailing backslash
      fname := f.PathOnly + string(PtrDirEnt.d_name);

      if lstat(PChar(fname), StatBuf) = 0 then
      begin
        Attr := 0;
        Mode := StatBuf.st_mode;

        if Mode and S_IFDIR <> 0 then
          Attr := Attr or faDirectory;

        if Mode and S_IFREG = 0 then
          Attr := Attr or faSysFile;

        if (PtrDirEnt.d_name[0] = '.') and (PtrDirEnt.d_name[1] <> #0) then
        begin
          if not ((PtrDirEnt.d_name[1] = '.') and (PtrDirEnt.d_name[2] = #0)) then
            Attr := Attr or faHidden;
        end;

        if euidaccess(PChar(fname), W_OK) <> 0 then
          Attr := Attr or faReadOnly;

        if Attr and f.ExcludeAttr = 0 then
        begin
          f.Size := StatBuf.st_size;
          f.Attr := Attr;
          f.Mode := StatBuf.st_mode;
          f.Name := PtrDirEnt.d_name;
          f.Time := StatBuf.st_mtime;
          Result := 0;
          Break;
        end;
      end;
    end;
    readdir_r(f.FindHandle, @Scratch, PtrDirEnt);
    Result := -1;
  end // End of While
end;
{$ENDIF}

function FindFirst(const Path: string; Attr: integer;
  var f: TSearchRec): integer;
const
  faSpecial                             = faHidden or faSysFile or faVolumeID or faDirectory;
{$IFDEF MSWINDOWS}
begin
  f.ExcludeAttr := not Attr and faSpecial;
  f.FindHandle := FindFirstFile(PChar(Path), f.finddata);
  if f.FindHandle <> INVALID_HANDLE_VALUE then
  begin
    Result := FindMatchingFile(f);
    if Result <> 0 then FindClose(f);
  end else
    Result := getlasterror;
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  f.ExcludeAttr := not Attr and faSpecial;
  f.PathOnly := ExtractFilePath(Path);
  f.Pattern := extractfilename(Path);
  if f.PathOnly = '' then
    f.PathOnly := IncludeTrailingPathDelimiter(GetCurrentDir);

  f.FindHandle := opendir(PChar(f.PathOnly));
  if f.FindHandle <> nil then
  begin
    Result := FindMatchingFile(f);
    if Result <> 0 then
      FindClose(f);
  end
  else
    Result := getlasterror;
end;
{$ENDIF}

function FindNext(var f: TSearchRec): integer;
begin
{$IFDEF MSWINDOWS}
  if FindNextFile(f.FindHandle, f.finddata) then
    Result := FindMatchingFile(f) else
    Result := getlasterror;
{$ENDIF}
{$IFDEF LINUX}
  Result := FindMatchingFile(f);
{$ENDIF}
end;

procedure FindClose(var f: TSearchRec);
begin
{$IFDEF MSWINDOWS}
  if f.FindHandle <> INVALID_HANDLE_VALUE then
  begin
    Windows.FindClose(f.FindHandle);
    f.FindHandle := INVALID_HANDLE_VALUE;
  end;
{$ENDIF}
{$IFDEF LINUX}
  if f.FindHandle <> nil then
  begin
    closedir(f.FindHandle);
    f.FindHandle := nil;
  end;
{$ENDIF}
end;

function DeleteFile(const FileName: string): boolean;
begin
{$IFDEF MSWINDOWS}
  Result := Windows.DeleteFile(PChar(FileName));
{$ENDIF}
{$IFDEF LINUX}
  Result := Remove(PChar(FileName)) <> -1;
{$ENDIF}
end;

function RenameFile(const OldName, NewName: string): boolean;
begin
{$IFDEF MSWINDOWS}
  Result := MoveFile(PChar(OldName), PChar(NewName));
{$ENDIF}
{$IFDEF LINUX}
  Result := __rename(PChar(OldName), PChar(NewName)) = 0;
{$ENDIF}
end;

function AnsiStrLastChar(p: PChar): PChar;
var
  LastByte                              : integer;
begin
  LastByte := StrLen(p) - 1;
  Result := @p[LastByte];
{$IFDEF MSWINDOWS}
  if StrByteType(p, LastByte) = mbTrailByte then Dec(Result);
{$ENDIF}
{$IFDEF LINUX}
  while StrByteType(p, Result - p) = mbTrailByte do Dec(Result);
{$ENDIF}
end;

function AnsiLastChar(const s: string): PChar;
var
  LastByte                              : integer;
begin
  LastByte := length(s);
  if LastByte <> 0 then
  begin
    while ByteType(s, LastByte) = mbTrailByte do Dec(LastByte);
    Result := @s[LastByte];
  end
  else
    Result := nil;
end;

function LastDelimiter(const Delimiters, s: string): integer;
var
  p                                     : PChar;
begin
  Result := length(s);
  p := PChar(Delimiters);
  while Result > 0 do
  begin
    if (s[Result] <> #0) and (StrScan(p, s[Result]) <> nil) then
{$IFDEF MSWINDOWS}
      if (ByteType(s, Result) = mbTrailByte) then
        Dec(Result)
      else
        Exit;
{$ENDIF}
{$IFDEF LINUX}
    begin
      if (ByteType(s, Result) <> mbTrailByte) then
        Exit;
      Dec(Result);
      while ByteType(s, Result) = mbTrailByte do Dec(Result);
    end;
{$ENDIF}
    Dec(Result);
  end;
end;

function changeFileExt(const FileName, Extension: string): string;
var
  I                                     : integer;
begin
  I := LastDelimiter('.' + PathDelim + DriveDelim, FileName);
  if (I = 0) or (FileName[I] <> '.') then I := MaxInt;
  Result := Copy(FileName, 1, I - 1) + Extension;
end;

function ExtractFilePath(const FileName: string): string;
var
  I                                     : integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  Result := Copy(FileName, 1, I);
end;

function ExtractFileDir(const FileName: string): string;
var
  I                                     : integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  if (I > 1) and (FileName[I] = PathDelim) and
    (((FileName[I - 1] <> PathDelim) and (FileName[I - 1] <> DriveDelim)) or
    (ByteType(FileName, I - 1) = mbTrailByte)) then Dec(I);
  while (ByteType(FileName, I - 1) = mbTrailByte) and (I > 0) do Dec(I);
  Result := Copy(FileName, 1, I);
end;

function ExtractFileDrive(const FileName: string): string;
{$IFDEF MSWINDOWS}
var
  I, J                                  : integer;
begin
  if (length(FileName) >= 2) and (FileName[2] = DriveDelim) then
    Result := Copy(FileName, 1, 2)
  else
    if (length(FileName) >= 2) and (FileName[1] = PathDelim) and
      (FileName[2] = PathDelim) then
    begin
      J := 0;
      I := 3;
      while (I < length(FileName)) and (J < 2) do
      begin
        if FileName[I] = PathDelim then inc(J);
        if J < 2 then inc(I);
      end;
      if FileName[I] = PathDelim then Dec(I);
      Result := Copy(FileName, 1, I);
    end else Result := '';
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := ''; // Linux doesn't support drive letters
end;
{$ENDIF}

function extractfilename(const FileName: string): string;
var
  I                                     : integer;
begin
  I := LastDelimiter(PathDelim + DriveDelim, FileName);
  Result := Copy(FileName, I + 1, MaxInt);
end;

function ExtractFileExt(const FileName: string): string;
var
  I                                     : integer;
begin
  I := LastDelimiter('.' + PathDelim + DriveDelim, FileName);
  if (I > 0) and (FileName[I] = '.') then
    Result := Copy(FileName, I, MaxInt) else
    Result := '';
end;

function ExpandFileName(const FileName: string): string;
{$IFDEF MSWINDOWS}
var
  fname                                 : PChar;
  Buffer                                : array[0..MAX_PATH - 1] of Char;
begin
  SetString(Result, Buffer, GetFullPathName(PChar(FileName), SizeOf(Buffer),
    Buffer, fname));
end;
{$ENDIF}
{$IFDEF LINUX}
var
  I, J                                  : integer;
  LastWasPathDelim                      : boolean;
  TempName                              : string;
  Buffer                                : array[0..MAX_PATH] of Char;
begin
  Result := '';
  if length(FileName) = 0 then Exit;

  if FileName[1] = PathDelim then
    TempName := FileName
  else
  begin
    getcwd(Buffer, SizeOf(Buffer));
    TempName := string(Buffer) + PathDelim + FileName;
  end;

  I := 1;
  J := 1;

  LastWasPathDelim := False;

  while I <= length(TempName) do
  begin
    case TempName[I] of
      PathDelim:
        if J < I then
        begin
                     // Check for consecutive 'PathDelim' characters and skip them if present
          if (I = 1) or (TempName[I - 1] <> PathDelim) then
            Result := Result + Copy(TempName, J, I - J);
          J := I;
                     // Set a flag indicating that we just processed a path delimiter
          LastWasPathDelim := True;
        end;
      '.':
        begin
                  // If the last character was a path delimiter then this '.' is
                  // possibly a relative path modifier
          if LastWasPathDelim then
          begin
                        // Check if the path ends in a '.'
            if I < length(TempName) then
            begin
                              // If the next character is another '.' then this may be a relative path
                              // except if there is another '.' after that one.  In this case simply
                              // treat this as just another filename.
              if (TempName[I + 1] = '.') and
                ((I + 1 >= length(TempName)) or (TempName[I + 2] <> '.')) then
              begin
                                    // Don't attempt to backup past the Root dir
                if length(Result) > 1 then
                                       // For the purpose of this excercise, treat the last dir as a
                                       // filename so we can use this function to remove it
                  Result := ExtractFilePath(ExcludeTrailingPathDelimiter(Result));
                J := I;
              end
                                    // Simply skip over and ignore any 'current dir' constrcucts, './'
                                    // or the remaining './' from a ../ constrcut.
              else
                if TempName[I + 1] = PathDelim then
                begin
                  Result := IncludeTrailingPathDelimiter(Result);
                  inc(I);
                  J := I + 1;
                end else
                                    // If any of the above tests fail, then this is not a 'current dir' or
                                    // 'parent dir' construct so just clear the state and continue.
                  LastWasPathDelim := False;
            end else
            begin
                              // Don't let the expanded path end in a 'PathDelim' character
              Result := ExcludeTrailingPathDelimiter(Result);
              J := I + 1;
            end;
          end;
        end;
    else
      LastWasPathDelim := False;
    end;
    inc(I);
  end;
   // This will finally append what is left
  if (I - J > 1) or (TempName[I] <> PathDelim) then
    Result := Result + Copy(TempName, J, I - J);
end;
{$ENDIF}

function ExpandFileNameCase(const FileName: string;
  out MatchFound: TFilenameCaseMatch): string;
var
  sr                                    : TSearchRec;
  FullPath, Name                        : string;
  temp                                  : integer;
  FoundOne                              : boolean;
{$IFDEF LINUX}
  Scans                                 : Byte;
  FirstLetter, TestLetter               : string;
{$ENDIF}
begin
  Result := ExpandFileName(FileName);
  FullPath := ExtractFilePath(Result);
  Name := extractfilename(Result);
  MatchFound := mkNone;

   // if FullPath is not the root directory  (portable)
  if not SameFileName(FullPath, IncludeTrailingPathDelimiter(ExtractFileDrive(FullPath))) then
  begin // Does the path need case-sensitive work?
    temp := FindFirst(FullPath, faAnyFile, sr);
    FindClose(sr); // close search before going recursive
    if temp <> 0 then
    begin
      FullPath := ExcludeTrailingPathDelimiter(FullPath);
      FullPath := ExpandFileNameCase(FullPath, MatchFound);
      if MatchFound = mkNone then
        Exit; // if we can't find the path, we certainly can't find the file!
      FullPath := IncludeTrailingPathDelimiter(FullPath);
    end;
  end;

   // Path is validated / adjusted.  Now for the file itself
  try
    if FindFirst(FullPath + Name, faAnyFile, sr) = 0 then // exact match on filename
    begin
      if not (MatchFound in [mkSingleMatch, mkAmbiguous]) then // path might have been inexact
        MatchFound := mkExactMatch;
      Result := FullPath + sr.Name;
      Exit;
    end;
  finally
    FindClose(sr);
  end;

  FoundOne := False; // Windows should never get to here except for file-not-found

{$IFDEF LINUX}

   { Scan the directory.
     To minimize the number of filenames tested, scan the directory
     using upper/lowercase first letter + wildcard.
     This results in two scans of the directory (particularly on Linux) but
     vastly reduces the number of times we have to perform an expensive
     locale-charset case-insensitive string compare.  }

     // First, scan for lowercase first letter
  FirstLetter := AnsiLowerCase(Name[1]);
  for Scans := 0 to 1 do
  begin
    temp := FindFirst(FullPath + FirstLetter + '*', faAnyFile, sr);
    while temp = 0 do
    begin
      if AnsiSameText(sr.Name, Name) then
      begin
        if FoundOne then
        begin // this is the second match
          MatchFound := mkAmbiguous;
          Exit;
        end
        else
        begin
          FoundOne := True;
          Result := FullPath + sr.Name;
        end;
      end;
      temp := FindNext(sr);
    end;
    FindClose(sr);
    TestLetter := AnsiUpperCase(Name[1]);
    if TestLetter = FirstLetter then Break;
    FirstLetter := TestLetter;
  end;
{$ENDIF}

  if MatchFound <> mkAmbiguous then
  begin
    if FoundOne then
      MatchFound := mkSingleMatch
    else
      MatchFound := mkNone;
  end;
end;

{$IFDEF MSWINDOWS}

function GetUniversalName(const FileName: string): string;
type
  PNetResourceArray = ^TNetResourceArray;
  TNetResourceArray = array[0..MaxInt div SizeOf(TNetResource) - 1] of TNetResource;
var
  I, BufSize, NetResult                 : integer;
  Count, Size                           : LongWord;
  Drive                                 : Char;
  NetHandle                             : THandle;
  NetResources                          : PNetResourceArray;
  RemoteNameInfo                        : array[0..1023] of Byte;
begin
  Result := FileName;
  if (Win32Platform <> VER_PLATFORM_WIN32_WINDOWS) or (Win32MajorVersion > 4) then
  begin
    Size := SizeOf(RemoteNameInfo);
    if WNetGetUniversalName(PChar(FileName), UNIVERSAL_NAME_INFO_LEVEL,
      @RemoteNameInfo, Size) <> NO_ERROR then Exit;
    Result := PRemoteNameInfo(@RemoteNameInfo).lpUniversalName;
  end else
  begin
         { The following works around a bug in WNetGetUniversalName under Windows 95 }
    Drive := UpCase(FileName[1]);
    if (Drive < 'A') or (Drive > 'Z') or (length(FileName) < 3) or
      (FileName[2] <> ':') or (FileName[3] <> '\') then
      Exit;
    if WNetOpenEnum(RESOURCE_CONNECTED, RESOURCETYPE_DISK, 0, nil,
      NetHandle) <> NO_ERROR then Exit;
    try
      BufSize := 50 * SizeOf(TNetResource);
      GetMem(NetResources, BufSize);
      try
        while True do
        begin
          Count := $FFFFFFFF;
          Size := BufSize;
          NetResult := WNetEnumResource(NetHandle, Count, NetResources, Size);
          if NetResult = ERROR_MORE_DATA then
          begin
            BufSize := Size;
            ReallocMem(NetResources, BufSize);
            Continue;
          end;
          if NetResult <> NO_ERROR then Exit;
          for I := 0 to Count - 1 do
            with NetResources^[I] do
              if (lpLocalName <> nil) and (Drive = UpCase(lpLocalName[0])) then
              begin
                Result := lpRemoteName + Copy(FileName, 3, length(FileName) - 2);
                Exit;
              end;
        end;
      finally
        FreeMem(NetResources, BufSize);
      end;
    finally
      WNetCloseEnum(NetHandle);
    end;
  end;
end;

function ExpandUNCFileName(const FileName: string): string;
begin
   { First get the local resource version of the file name }
  Result := ExpandFileName(FileName);
  if (length(Result) >= 3) and (Result[2] = ':') and (UpCase(Result[1]) >= 'A')
    and (UpCase(Result[1]) <= 'Z') then
    Result := GetUniversalName(Result);
end;
{$ENDIF}
{$IFDEF LINUX}

function ExpandUNCFileName(const FileName: string): string;
begin
  Result := ExpandFileName(FileName);
end;
{$ENDIF}

function ExtractRelativePath(const BaseName, DestName: string): string;
var
  BasePath, DestPath                    : string;
  BaseLead, DestLead                    : PChar;
  BasePtr, DestPtr                      : PChar;

  function ExtractFilePathNoDrive(const FileName: string): string;
  begin
    Result := ExtractFilePath(FileName);
    Delete(Result, 1, length(ExtractFileDrive(FileName)));
  end;

  function Next(var Lead: PChar): PChar;
  begin
    Result := Lead;
    if Result = nil then Exit;
    Lead := AnsiStrScan(Lead, PathDelim);
    if Lead <> nil then
    begin
      Lead^ := #0;
      inc(Lead);
    end;
  end;

begin
  if SameFilename(ExtractFileDrive(BaseName), ExtractFileDrive(DestName)) then
  begin
    BasePath := ExtractFilePathNoDrive(BaseName);
    DestPath := ExtractFilePathNoDrive(DestName);
    BaseLead := Pointer(BasePath);
    BasePtr := Next(BaseLead);
    DestLead := Pointer(DestPath);
    DestPtr := Next(DestLead);
    while (BasePtr <> nil) and (DestPtr <> nil) and SameFilename(BasePtr, DestPtr) do
    begin
      BasePtr := Next(BaseLead);
      DestPtr := Next(DestLead);
    end;
    Result := '';
    while BaseLead <> nil do
    begin
      Result := Result + '..' + PathDelim; { Do not localize }
      Next(BaseLead);
    end;
    if (DestPtr <> nil) and (DestPtr^ <> #0) then
      Result := Result + DestPtr + PathDelim;
    if DestLead <> nil then
      Result := Result + DestLead; // destlead already has a trailing backslash
    Result := Result + extractfilename(DestName);
  end
  else
    Result := DestName;
end;

{$IFDEF MSWINDOWS}

function ExtractShortPathName(const FileName: string): string;
var
  Buffer                                : array[0..MAX_PATH - 1] of Char;
begin
  SetString(Result, Buffer,
    GetShortPathName(PChar(FileName), Buffer, SizeOf(Buffer)));
end;
{$ENDIF}

function FileSearch(const Name, DirList: string): string;
var
  I, p, l                               : integer;
  c                                     : Char;
begin
  Result := Name;
  p := 1;
  l := length(DirList);
  while True do
  begin
    if FileExists(Result) then Exit;
    while (p <= l) and (DirList[p] = PathSep) do inc(p);
    if p > l then Break;
    I := p;
    while (p <= l) and (DirList[p] <> PathSep) do
    begin
      if DirList[p] in LeadBytes then
        p := NextCharIndex(DirList, p)
      else
        inc(p);
    end;
    Result := Copy(DirList, I, p - I);
    c := AnsiLastChar(Result)^;
    if (c <> DriveDelim) and (c <> PathDelim) then
      Result := Result + PathDelim;
    Result := Result + Name;
  end;
  Result := '';
end;

{$IFDEF MSWINDOWS}
// This function is used if the OS doesn't support GetDiskFreeSpaceEx

function BackfillGetDiskFreeSpaceEx(Directory: PChar; var FreeAvailable,
  TotalSpace: TLargeInteger; TotalFree: PLargeInteger): BOOL; stdcall;
var
  SectorsPerCluster, BytesPerSector, FreeClusters, TotalClusters: LongWord;
  temp                                  : int64;
  dir                                   : PChar;
begin
  if Directory <> nil then
    dir := Directory
  else
    dir := nil;
  Result := GetDiskFreeSpaceA(dir, SectorsPerCluster, BytesPerSector,
    FreeClusters, TotalClusters);
  temp := SectorsPerCluster * BytesPerSector;
  FreeAvailable := temp * FreeClusters;
  TotalSpace := temp * TotalClusters;
end;

function InternalGetDiskSpace(Drive: Byte;
  var TotalSpace, FreeSpaceAvailable: int64): BOOL;
var
  RootPath                              : array[0..4] of Char;
  RootPtr                               : PChar;
begin
  RootPtr := nil;
  if Drive > 0 then
  begin
    RootPath[0] := Char(Drive + $40);
    RootPath[1] := ':';
    RootPath[2] := '\';
    RootPath[3] := #0;
    RootPtr := RootPath;
  end;
  Result := GetDiskFreeSpaceEx(RootPtr, FreeSpaceAvailable, TotalSpace, nil);
end;

function DiskFree(Drive: Byte): int64;
var
  TotalSpace                            : int64;
begin
  if not InternalGetDiskSpace(Drive, TotalSpace, Result) then
    Result := -1;
end;

function DiskSize(Drive: Byte): int64;
var
  FreeSpace                             : int64;
begin
  if not InternalGetDiskSpace(Drive, Result, FreeSpace) then
    Result := -1;
end;
{$ENDIF}

function FileDateToDateTime(FileDate: integer): TDateTime;
{$IFDEF MSWINDOWS}
begin
  Result :=
    EncodeDate(
    LongRec(FileDate).Hi shr 9 + 1980,
    LongRec(FileDate).Hi shr 5 and 15,
    LongRec(FileDate).Hi and 31) +
    EncodeTime(
    LongRec(FileDate).Lo shr 11,
    LongRec(FileDate).Lo shr 5 and 63,
    LongRec(FileDate).Lo and 31 shl 1, 0);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  UT                                    : TUnixTime;
begin
  localtime_r(@FileDate, UT);
  Result := EncodeDate(UT.tm_year + 1900, UT.tm_mon + 1, UT.tm_mday) +
    EncodeTime(UT.tm_hour, UT.tm_min, UT.tm_sec, 0);
end;
{$ENDIF}

function DateTimeToFileDate(DateTime: TDateTime): integer;
{$IFDEF MSWINDOWS}
var
  Year, Month, Day, Hour, Min, Sec, msec: Word;
begin
  DecodeDate(DateTime, Year, Month, Day);
  if (Year < 1980) or (Year > 2107) then Result := 0 else
  begin
    DecodeTime(DateTime, Hour, Min, Sec, msec);
    LongRec(Result).Lo := (Sec shr 1) or (Min shl 5) or (Hour shl 11);
    LongRec(Result).Hi := Day or (Month shl 5) or ((Year - 1980) shl 9);
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  TM                                    : TUnixTime;
  Year, Month, Day, Hour, Min, Sec, msec: Word;
begin
  DecodeDate(DateTime, Year, Month, Day);
   { Valid range for 32 bit Unix time_t:  1970 through 2038  }
  if (Year < 1970) or (Year > 2038) then
    Result := 0
  else
  begin
    DecodeTime(DateTime, Hour, Min, Sec, msec);
    FillChar(TM, SizeOf(TM), 0);
    with TM do
    begin
      tm_sec := Sec;
      tm_min := Min;
      tm_hour := Hour;
      tm_mday := Day;
      tm_mon := Month - 1;
      tm_year := Year - 1900;
      tm_isdst := -1;
    end;
    Result := mktime(TM);
  end;
end;
{$ENDIF}

function GetCurrentDir: string;
begin
  GetDir(0, Result);
end;

function SetCurrentDir(const dir: string): boolean;
begin
{$IFDEF MSWINDOWS}
  Result := SetCurrentDirectory(PChar(dir));
{$ENDIF}
{$IFDEF LINUX}
  Result := __chdir(PChar(dir)) = 0;
{$ENDIF}
end;

function createdir(const dir: string): boolean;
begin
{$IFDEF MSWINDOWS}
  Result := CreateDirectory(PChar(dir), nil);
{$ENDIF}
{$IFDEF LINUX}
  Result := __mkdir(PChar(dir), __mode_t(-1)) = 0;
{$ENDIF}
end;

function RemoveDir(const dir: string): boolean;
begin
{$IFDEF MSWINDOWS}
  Result := RemoveDirectory(PChar(dir));
{$ENDIF}
{$IFDEF LINUX}
  Result := __rmdir(PChar(dir)) = 0;
{$ENDIF}
end;

{ PChar routines }

function StrLen(const Str: PChar): Cardinal; assembler;
asm
        MOV     EDX,EDI
        MOV     EDI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        MOV     EAX,0FFFFFFFEH
        SUB     EAX,ECX
        MOV     EDI,EDX
end;

function StrEnd(const Str: PChar): PChar; assembler;
asm
        MOV     EDX,EDI
        MOV     EDI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        LEA     EAX,[EDI-1]
        MOV     EDI,EDX
end;

function StrMove(Dest: PChar; const Source: PChar; Count: Cardinal): PChar;
begin
  Result := Dest;
  Move(Source^, Dest^, Count);
end;

function StrCopy(Dest: PChar; const Source: PChar): PChar;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,ECX
        MOV     EAX,EDI
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EDX
        AND     ECX,3
        REP     MOVSB
        POP     ESI
        POP     EDI
end;

function StrECopy(Dest: PChar; const Source: PChar): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,ECX
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EDX
        AND     ECX,3
        REP     MOVSB
        LEA     EAX,[EDI-1]
        POP     ESI
        POP     EDI
end;

function StrLCopy(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
        MOV     EBX,ECX
        XOR     AL,AL
        TEST    ECX,ECX
        JZ      @@1
        REPNE   SCASB
        JNE     @@1
        INC     ECX
@@1:    SUB     EBX,ECX
        MOV     EDI,ESI
        MOV     ESI,EDX
        MOV     EDX,EDI
        MOV     ECX,EBX
        SHR     ECX,2
        REP     MOVSD
        MOV     ECX,EBX
        AND     ECX,3
        REP     MOVSB
        STOSB
        MOV     EAX,EDX
        POP     EBX
        POP     ESI
        POP     EDI
end;

function StrPCopy(Dest: PChar; const Source: string): PChar;
begin
  Result := StrLCopy(Dest, PChar(Source), length(Source));
end;

function StrPLCopy(Dest: PChar; const Source: string;
  MaxLen: Cardinal): PChar;
begin
  Result := StrLCopy(Dest, PChar(Source), MaxLen);
end;

function StrCat(Dest: PChar; const Source: PChar): PChar;
begin
  StrCopy(StrEnd(Dest), Source);
  Result := Dest;
end;

function StrLCat(Dest: PChar; const Source: PChar; MaxLen: Cardinal): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     EDI,Dest
        MOV     ESI,Source
        MOV     EBX,MaxLen
        CALL    StrEnd
        MOV     ECX,EDI
        ADD     ECX,EBX
        SUB     ECX,EAX
        JBE     @@1
        MOV     EDX,ESI
        CALL    StrLCopy
@@1:    MOV     EAX,EDI
        POP     EBX
        POP     ESI
        POP     EDI
end;

function StrComp(const Str1, Str2: PChar): integer; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     EAX,EAX
        REPNE   SCASB
        NOT     ECX
        MOV     EDI,EDX
        XOR     EDX,EDX
        REPE    CMPSB
        MOV     AL,[ESI-1]
        MOV     DL,[EDI-1]
        SUB     EAX,EDX
        POP     ESI
        POP     EDI
end;

function StrIComp(const Str1, Str2: PChar): integer; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOV     ECX,0FFFFFFFFH
        XOR     EAX,EAX
        REPNE   SCASB
        NOT     ECX
        MOV     EDI,EDX
        XOR     EDX,EDX
@@1:    REPE    CMPSB
        JE      @@4
        MOV     AL,[ESI-1]
        CMP     AL,'a'
        JB      @@2
        CMP     AL,'z'
        JA      @@2
        SUB     AL,20H
@@2:    MOV     DL,[EDI-1]
        CMP     DL,'a'
        JB      @@3
        CMP     DL,'z'
        JA      @@3
        SUB     DL,20H
@@3:    SUB     EAX,EDX
        JE      @@1
@@4:    POP     ESI
        POP     EDI
end;

function StrLComp(const Str1, Str2: PChar; MaxLen: Cardinal): integer; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOV     EBX,ECX
        XOR     EAX,EAX
        OR      ECX,ECX
        JE      @@1
        REPNE   SCASB
        SUB     EBX,ECX
        MOV     ECX,EBX
        MOV     EDI,EDX
        XOR     EDX,EDX
        REPE    CMPSB
        MOV     AL,[ESI-1]
        MOV     DL,[EDI-1]
        SUB     EAX,EDX
@@1:    POP     EBX
        POP     ESI
        POP     EDI
end;

function StrLIComp(const Str1, Str2: PChar; MaxLen: Cardinal): integer; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     EDI,EDX
        MOV     ESI,EAX
        MOV     EBX,ECX
        XOR     EAX,EAX
        OR      ECX,ECX
        JE      @@4
        REPNE   SCASB
        SUB     EBX,ECX
        MOV     ECX,EBX
        MOV     EDI,EDX
        XOR     EDX,EDX
@@1:    REPE    CMPSB
        JE      @@4
        MOV     AL,[ESI-1]
        CMP     AL,'a'
        JB      @@2
        CMP     AL,'z'
        JA      @@2
        SUB     AL,20H
@@2:    MOV     DL,[EDI-1]
        CMP     DL,'a'
        JB      @@3
        CMP     DL,'z'
        JA      @@3
        SUB     DL,20H
@@3:    SUB     EAX,EDX
        JE      @@1
@@4:    POP     EBX
        POP     ESI
        POP     EDI
end;

function StrScan(const Str: PChar; CHR: Char): PChar; assembler;
asm
        PUSH    EDI
        PUSH    EAX
        MOV     EDI,Str
        MOV     ECX,$FFFFFFFF
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        POP     EDI
        MOV     AL,Chr
        REPNE   SCASB
        MOV     EAX,0
        JNE     @@1
        MOV     EAX,EDI
        DEC     EAX
@@1:    POP     EDI
end;

function StrRScan(const Str: PChar; CHR: Char): PChar; assembler;
asm
        PUSH    EDI
        MOV     EDI,Str
        MOV     ECX,0FFFFFFFFH
        XOR     AL,AL
        REPNE   SCASB
        NOT     ECX
        STD
        DEC     EDI
        MOV     AL,Chr
        REPNE   SCASB
        MOV     EAX,0
        JNE     @@1
        MOV     EAX,EDI
        INC     EAX
@@1:    CLD
        POP     EDI
end;

function StrPos(const Str1, Str2: PChar): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        OR      EAX,EAX
        JE      @@2
        OR      EDX,EDX
        JE      @@2
        MOV     EBX,EAX
        MOV     EDI,EDX
        XOR     AL,AL
        MOV     ECX,0FFFFFFFFH
        REPNE   SCASB
        NOT     ECX
        DEC     ECX
        JE      @@2
        MOV     ESI,ECX
        MOV     EDI,EBX
        MOV     ECX,0FFFFFFFFH
        REPNE   SCASB
        NOT     ECX
        SUB     ECX,ESI
        JBE     @@2
        MOV     EDI,EBX
        LEA     EBX,[ESI-1]
@@1:    MOV     ESI,EDX
        LODSB
        REPNE   SCASB
        JNE     @@2
        MOV     EAX,ECX
        PUSH    EDI
        MOV     ECX,EBX
        REPE    CMPSB
        POP     EDI
        MOV     ECX,EAX
        JNE     @@1
        LEA     EAX,[EDI-1]
        JMP     @@3
@@2:    XOR     EAX,EAX
@@3:    POP     EBX
        POP     ESI
        POP     EDI
end;

function StrUpper(Str: PChar): PChar; assembler;
asm
        PUSH    ESI
        MOV     ESI,Str
        MOV     EDX,Str
@@1:    LODSB
        OR      AL,AL
        JE      @@2
        CMP     AL,'a'
        JB      @@1
        CMP     AL,'z'
        JA      @@1
        SUB     AL,20H
        MOV     [ESI-1],AL
        JMP     @@1
@@2:    XCHG    EAX,EDX
        POP     ESI
end;

function StrLower(Str: PChar): PChar; assembler;
asm
        PUSH    ESI
        MOV     ESI,Str
        MOV     EDX,Str
@@1:    LODSB
        OR      AL,AL
        JE      @@2
        CMP     AL,'A'
        JB      @@1
        CMP     AL,'Z'
        JA      @@1
        ADD     AL,20H
        MOV     [ESI-1],AL
        JMP     @@1
@@2:    XCHG    EAX,EDX
        POP     ESI
end;

function StrPas(const Str: PChar): string;
begin
  Result := Str;
end;

function StrAlloc(Size: Cardinal): PChar;
begin
  inc(Size, SizeOf(Cardinal));
  GetMem(Result, Size);
  Cardinal(Pointer(Result)^) := Size;
  inc(Result, SizeOf(Cardinal));
end;

function StrBufSize(const Str: PChar): Cardinal;
var
  p                                     : PChar;
begin
  p := Str;
  Dec(p, SizeOf(Cardinal));
  Result := Cardinal(Pointer(p)^) - SizeOf(Cardinal);
end;

function StrNew(const Str: PChar): PChar;
var
  Size                                  : Cardinal;
begin
  if Str = nil then Result := nil else
  begin
    Size := StrLen(Str) + 1;
    Result := StrMove(StrAlloc(Size), Str, Size);
  end;
end;

procedure StrDispose(Str: PChar);
begin
  if Str <> nil then
  begin
    Dec(Str, SizeOf(Cardinal));
    FreeMem(Str, Cardinal(Pointer(Str)^));
  end;
end;

{ String formatting routines }



procedure FormatVarToStr(var s: string; const V: Variant);
begin
  s := V;
end;

procedure FormatClearStr(var s: string);
begin
  s := '';
end;








procedure WideFmtStr(var Result: WideString; const Format: WideString;
  const Args: array of const);
var
  Len, BufLen                           : integer;
  Buffer                                : array[0..4095] of widechar;
begin
  BufLen := SizeOf(Buffer);
  if length(Format) < (SizeOf(Buffer) - (SizeOf(Buffer) div 4)) then
    Len := WideFormatBuf(Buffer, SizeOf(Buffer) - 1, Pointer(Format)^, length(Format), Args)
  else
  begin
    BufLen := length(Format);
    Len := BufLen;
  end;
  if Len >= BufLen - 1 then
  begin
    while Len >= BufLen - 1 do
    begin
      inc(BufLen, BufLen);
      Result := ''; // prevent copying of existing data, for speed
      SetLength(Result, BufLen);
      Len := WideFormatBuf(Pointer(Result)^, BufLen - 1, Pointer(Format)^,
        length(Format), Args);
    end;
    SetLength(Result, Len);
  end
  else
    SetString(Result, Buffer, Len);
end;

function WideFormat(const Format: WideString; const Args: array of const): WideString;
begin
  WideFmtStr(Result, Format, Args);
end;

{ Floating point conversion routines }

const
   // 1E18 as a 64-bit integer
  Const1E18Lo                           = $0A7640000;
  Const1E18Hi                           = $00DE0B6B3;
  FCon1E18                              : extended = 1E18;
  DCon10                                : integer = 10;

procedure PutExponent;
// Store exponent
// In   AL  = Exponent character ('E' or 'e')
//      AH  = Positive sign character ('+' or 0)
//      BL  = Zero indicator
//      ECX = Minimum number of digits (0..4)
//      EDX = Exponent
//      EDI = Destination buffer
asm
        PUSH    ESI
{$IFDEF PIC}
        PUSH    EAX
        PUSH    ECX
        CALL    GetGOT
        MOV     ESI,EAX
        POP     ECX
        POP     EAX
{$ELSE}
        XOR     ESI,ESI
{$ENDIF}
        STOSB
        OR      BL,BL
        JNE     @@0
        XOR     EDX,EDX
        JMP     @@1
@@0:    OR      EDX,EDX
        JGE     @@1
        MOV     AL,'-'
        NEG     EDX
        JMP     @@2
@@1:    OR      AH,AH
        JE      @@3
        MOV     AL,AH
@@2:    STOSB
@@3:    XCHG    EAX,EDX
        PUSH    EAX
        MOV     EBX,ESP
@@4:    XOR     EDX,EDX
        DIV     [ESI].DCon10
        ADD     DL,'0'
        MOV     [EBX],DL
        INC     EBX
        DEC     ECX
        OR      EAX,EAX
        JNE     @@4
        OR      ECX,ECX
        JG      @@4
@@5:    DEC     EBX
        MOV     AL,[EBX]
        STOSB
        CMP     EBX,ESP
        JNE     @@5
        POP     EAX
        POP     ESI
end;


const
   // 8087 status word masks
  mIE                                   = $0001;
  mDE                                   = $0002;
  mZE                                   = $0004;
  mOE                                   = $0008;
  mUE                                   = $0010;
  mPE                                   = $0020;
  mC0                                   = $0100;
  mC1                                   = $0200;
  mC2                                   = $0400;
  mC3                                   = $4000;

procedure FloatToDecimal(var Result: TFloatRec; const Value;
  ValueType: TFloatValue; Precision, Decimals: integer);
var
  StatWord                              : Word;
  Exponent                              : integer;
  temp                                  : Double;
  BCDValue                              : extended;
  SaveGOT                               : Pointer;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     EBX,EAX
        MOV     ESI,EDX
{$IFDEF PIC}
        PUSH    ECX
        CALL    GetGOT
        POP     ECX
        MOV     SaveGOT,EAX
{$ELSE}
        MOV     SaveGOT,0
{$ENDIF}
        CMP     CL,fvExtended
        JE      @@1
        CALL    @@CurrToDecimal
        JMP     @@Exit
@@1:    CALL    @@ExtToDecimal
        JMP     @@Exit

// Convert Extended to decimal

@@ExtToDecimal:

        MOV     AX,[ESI].Word[8]
        MOV     EDX,EAX
        AND     EAX,7FFFH
        JE      @@ed1
        CMP     EAX,7FFFH
        JNE     @@ed10
// check for special values (INF, NAN)
        TEST    [ESI].Word[6],8000H
        JZ      @@ed2
// any significand bit set = NAN
// all significand bits clear = INF
        CMP     dword ptr [ESI], 0
        JNZ     @@ed0
        CMP     dword ptr [ESI+4], 80000000H
        JZ      @@ed2
@@ed0:  INC     EAX
@@ed1:  XOR     EDX,EDX
@@ed2:  MOV     [EBX].TFloatRec.Digits.Byte,0
        JMP     @@ed31
@@ed10: FLD     TBYTE PTR [ESI]
        SUB     EAX,3FFFH
        IMUL    EAX,19728
        SAR     EAX,16
        INC     EAX
        MOV     Exponent,EAX
        MOV     EAX,18
        SUB     EAX,Exponent
        FABS
        PUSH    EBX
        MOV     EBX,SaveGOT
        CALL    FPower10
        POP     EBX
        FRNDINT
        MOV     EDI,SaveGOT
        FLD     [EDI].FCon1E18
        FCOMP
        FSTSW   StatWord
        FWAIT
        TEST    StatWord,mC0+mC3
        JE      @@ed11
        FIDIV   [EDI].DCon10
        INC     Exponent
@@ed11: FBSTP   BCDValue
        LEA     EDI,[EBX].TFloatRec.Digits
        MOV     EDX,9
        FWAIT
@@ed12: MOV     AL,BCDValue[EDX-1].Byte
        MOV     AH,AL
        SHR     AL,4
        AND     AH,0FH
        ADD     AX,'00'
        STOSW
        DEC     EDX
        JNE     @@ed12
        XOR     AL,AL
        STOSB
@@ed20: MOV     EDI,Exponent
        ADD     EDI,Decimals
        JNS     @@ed21
        XOR     EAX,EAX
        JMP     @@ed1
@@ed21: CMP     EDI,Precision
        JB      @@ed22
        MOV     EDI,Precision
@@ed22: CMP     EDI,18
        JAE     @@ed26
        CMP     [EBX].TFloatRec.Digits.Byte[EDI],'5'
        JB      @@ed25
@@ed23: MOV     [EBX].TFloatRec.Digits.Byte[EDI],0
        DEC     EDI
        JS      @@ed24
        INC     [EBX].TFloatRec.Digits.Byte[EDI]
        CMP     [EBX].TFloatRec.Digits.Byte[EDI],'9'
        JA      @@ed23
        JMP     @@ed30
@@ed24: MOV     [EBX].TFloatRec.Digits.Word,'1'
        INC     Exponent
        JMP     @@ed30
@@ed26: MOV     EDI,18
@@ed25: MOV     [EBX].TFloatRec.Digits.Byte[EDI],0
        DEC     EDI
        JS      @@ed32
        CMP     [EBX].TFloatRec.Digits.Byte[EDI],'0'
        JE      @@ed25
@@ed30: MOV     DX,[ESI].Word[8]
@@ed30a:
        MOV     EAX,Exponent
@@ed31: SHR     DX,15
        MOV     [EBX].TFloatRec.Exponent,AX
        MOV     [EBX].TFloatRec.Negative,DL
        RET
@@ed32: XOR     EDX,EDX
        JMP     @@ed30a

@@DecimalTable:
        DD      10
        DD      100
        DD      1000
        DD      10000

// Convert Currency to decimal

@@CurrToDecimal:

        MOV     EAX,[ESI].Integer[0]
        MOV     EDX,[ESI].Integer[4]
        MOV     ECX,EAX
        OR      ECX,EDX
        JE      @@cd20
        OR      EDX,EDX
        JNS     @@cd1
        NEG     EDX
        NEG     EAX
        SBB     EDX,0
@@cd1:  XOR     ECX,ECX
        MOV     EDI,Decimals
        OR      EDI,EDI
        JGE     @@cd2
        XOR     EDI,EDI
@@cd2:  CMP     EDI,4
        JL      @@cd4
        MOV     EDI,4
@@cd3:  INC     ECX
        SUB     EAX,Const1E18Lo
        SBB     EDX,Const1E18Hi
        JNC     @@cd3
        DEC     ECX
        ADD     EAX,Const1E18Lo
        ADC     EDX,Const1E18Hi
@@cd4:  MOV     Temp.Integer[0],EAX
        MOV     Temp.Integer[4],EDX
        FILD    Temp
        MOV     EDX,EDI
        MOV     EAX,4
        SUB     EAX,EDX
        JE      @@cd5
        MOV     EDI,SaveGOT
        FIDIV   @@DecimalTable.Integer[EDI+EAX*4-4]
@@cd5:  FBSTP   BCDValue
        LEA     EDI,[EBX].TFloatRec.Digits
        FWAIT
        OR      ECX,ECX
        JNE     @@cd11
        MOV     ECX,9
@@cd10: MOV     AL,BCDValue[ECX-1].Byte
        MOV     AH,AL
        SHR     AL,4
        JNE     @@cd13
        MOV     AL,AH
        AND     AL,0FH
        JNE     @@cd14
        DEC     ECX
        JNE     @@cd10
        JMP     @@cd20
@@cd11: MOV     AL,CL
        ADD     AL,'0'
        STOSB
        MOV     ECX,9
@@cd12: MOV     AL,BCDValue[ECX-1].Byte
        MOV     AH,AL
        SHR     AL,4
@@cd13: ADD     AL,'0'
        STOSB
        MOV     AL,AH
        AND     AL,0FH
@@cd14: ADD     AL,'0'
        STOSB
        DEC     ECX
        JNE     @@cd12
        MOV     EAX,EDI
        LEA     ECX,[EBX].TFloatRec.Digits[EDX]
        SUB     EAX,ECX
@@cd15: MOV     BYTE PTR [EDI],0
        DEC     EDI
        CMP     BYTE PTR [EDI],'0'
        JE      @@cd15
        MOV     EDX,[ESI].Integer[4]
        SHR     EDX,31
        JMP     @@cd21
@@cd20: XOR     EAX,EAX
        XOR     EDX,EDX
        MOV     [EBX].TFloatRec.Digits.Byte[0],AL
@@cd21: MOV     [EBX].TFloatRec.Exponent,AX
        MOV     [EBX].TFloatRec.Negative,DL
        RET

@@Exit:
        POP     EBX
        POP     ESI
        POP     EDI
end;

function TextToFloat(Buffer: PChar; var Value;
  ValueType: TFloatValue): boolean;

const
   // 8087 control word
   // Infinity control  = 1 Affine
   // Rounding Control  = 0 Round to nearest or even
   // Precision Control = 3 64 bits
   // All interrupts masked
  CWNear                                : Word = $133F;

var
  temp                                  : integer;
  CtrlWord                              : Word;
  DecimalSep                            : Char;
  SaveGOT                               : integer;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX
        MOV     ESI,EAX
        MOV     EDI,EDX
{$IFDEF PIC}
        PUSH    ECX
        CALL    GetGOT
        POP     EBX
        MOV     SaveGOT,EAX
        MOV     ECX,[EAX].OFFSET DecimalSeparator
        MOV     CL,[ECX].Byte
        MOV     DecimalSep,CL
{$ELSE}
        MOV     SaveGOT,0
        MOV     AL,DecimalSeparator
        MOV     DecimalSep,AL
        MOV     EBX,ECX
{$ENDIF}
        FSTCW   CtrlWord
        FCLEX
{$IFDEF PIC}
        FLDCW   [EAX].CWNear
{$ELSE}
        FLDCW   CWNear
{$ENDIF}
        FLDZ
        CALL    @@SkipBlanks
        MOV     BH, byte ptr [ESI]
        CMP     BH,'+'
        JE      @@1
        CMP     BH,'-'
        JNE     @@2
@@1:    INC     ESI
@@2:    MOV     ECX,ESI
        CALL    @@GetDigitStr
        XOR     EDX,EDX
        MOV     AL,[ESI]
        CMP     AL,DecimalSep
        JNE     @@3
        INC     ESI
        CALL    @@GetDigitStr
        NEG     EDX
@@3:    CMP     ECX,ESI
        JE      @@9
        MOV     AL, byte ptr [ESI]
        AND     AL,0DFH
        CMP     AL,'E'
        JNE     @@4
        INC     ESI
        PUSH    EDX
        CALL    @@GetExponent
        POP     EAX
        ADD     EDX,EAX
@@4:    CALL    @@SkipBlanks
        CMP     BYTE PTR [ESI],0
        JNE     @@9
        MOV     EAX,EDX
        CMP     BL,fvCurrency
        JNE     @@5
        ADD     EAX,4
@@5:    PUSH    EBX
        MOV     EBX,SaveGOT
        CALL    FPower10
        POP     EBX
        CMP     BH,'-'
        JNE     @@6
        FCHS
@@6:    CMP     BL,fvExtended
        JE      @@7
        FISTP   QWORD PTR [EDI]
        JMP     @@8
@@7:    FSTP    TBYTE PTR [EDI]
@@8:    FSTSW   AX
        TEST    AX,mIE+mOE
        JNE     @@10
        MOV     AL,1
        JMP     @@11
@@9:    FSTP    ST(0)
@@10:   XOR     EAX,EAX
@@11:   FCLEX
        FLDCW   CtrlWord
        FWAIT
        JMP     @@Exit

@@SkipBlanks:

@@21:   LODSB
        OR      AL,AL
        JE      @@22
        CMP     AL,' '
        JE      @@21
@@22:   DEC     ESI
        RET

// Process string of digits
// Out EDX = Digit count

@@GetDigitStr:

        XOR     EAX,EAX
        XOR     EDX,EDX
@@31:   LODSB
        SUB     AL,'0'+10
        ADD     AL,10
        JNC     @@32
{$IFDEF PIC}
        XCHG    SaveGOT,EBX
        FIMUL   [EBX].DCon10
        XCHG    SaveGOT,EBX
{$ELSE}
        FIMUL   DCon10
{$ENDIF}
        MOV     Temp,EAX
        FIADD   Temp
        INC     EDX
        JMP     @@31
@@32:   DEC     ESI
        RET

// Get exponent
// Out EDX = Exponent (-4999..4999)

@@GetExponent:

        XOR     EAX,EAX
        XOR     EDX,EDX
        MOV     CL, byte ptr [ESI]
        CMP     CL,'+'
        JE      @@41
        CMP     CL,'-'
        JNE     @@42
@@41:   INC     ESI
@@42:   MOV     AL, byte ptr [ESI]
        SUB     AL,'0'+10
        ADD     AL,10
        JNC     @@43
        INC     ESI
        IMUL    EDX,10
        ADD     EDX,EAX
        CMP     EDX,500
        JB      @@42
@@43:   CMP     CL,'-'
        JNE     @@44
        NEG     EDX
@@44:   RET

@@Exit:
        POP     EBX
        POP     ESI
        POP     EDI
end;





function FormatFloat(const Format: string; Value: extended): string;
var
  Buffer                                : array[0..255] of Char;
begin
  if length(Format) > SizeOf(Buffer) - 32 then ConvertError(@SFormatTooLong);
  SetString(Result, Buffer, FloatToTextFmt(Buffer, Value, fvExtended,
    PChar(Format)));
end;

function FormatCurr(const Format: string; Value: Currency): string;
var
  Buffer                                : array[0..255] of Char;
begin
  if length(Format) > SizeOf(Buffer) - 32 then ConvertError(@SFormatTooLong);
  SetString(Result, Buffer, FloatToTextFmt(Buffer, Value, fvCurrency,
    PChar(Format)));
end;


function StrToFloatDef(const s: string; const Default: extended): extended;
begin
  if not TextToFloat(PChar(s), Result, fvExtended) then
    Result := Default;
end;

function TryStrToFloat(const s: string; out Value: extended): boolean;
begin
  Result := TextToFloat(PChar(s), Value, fvExtended);
end;

function TryStrToFloat(const s: string; out Value: Double): boolean;
var
  LValue                                : extended;
begin
  Result := TextToFloat(PChar(s), LValue, fvExtended);
  if Result then
    Value := LValue;
end;

function TryStrToFloat(const s: string; out Value: single): boolean;
var
  LValue                                : extended;
begin
  Result := TextToFloat(PChar(s), LValue, fvExtended);
  if Result then
    Value := LValue;
end;


function StrToCurrDef(const s: string; const Default: Currency): Currency;
begin
  if not TextToFloat(PChar(s), Result, fvCurrency) then
    Result := Default;
end;

function TryStrToCurr(const s: string; out Value: Currency): boolean;
begin
  Result := TextToFloat(PChar(s), Value, fvCurrency);
end;

{ Date/time support routines }

const
  FMSecsPerDay                          : single = MSecsPerDay;
  IMSecsPerDay                          : integer = MSecsPerDay;

function DateTimeToTimeStamp(DateTime: TDateTime): ttimestamp;
asm
        PUSH    EBX
{$IFDEF PIC}
        PUSH    EAX
        CALL    GetGOT
        MOV     EBX,EAX
        POP     EAX
{$ELSE}
        XOR     EBX,EBX
{$ENDIF}
        MOV     ECX,EAX
        FLD     DateTime
        FMUL    [EBX].FMSecsPerDay
        SUB     ESP,8
        FISTP   QWORD PTR [ESP]
        FWAIT
        POP     EAX
        POP     EDX
        OR      EDX,EDX
        JNS     @@1
        NEG     EDX
        NEG     EAX
        SBB     EDX,0
        DIV     [EBX].IMSecsPerDay
        NEG     EAX
        JMP     @@2
@@1:    DIV     [EBX].IMSecsPerDay
@@2:    ADD     EAX,DateDelta
        MOV     [ECX].TTimeStamp.Time,EDX
        MOV     [ECX].TTimeStamp.Date,EAX
        POP     EBX
end;




function MSecsToTimeStamp(MSecs: Comp): ttimestamp;
asm
        PUSH    EBX
{$IFDEF PIC}
        PUSH    EAX
        CALL    GetGOT
        MOV     EBX,EAX
        POP     EAX
{$ELSE}
        XOR     EBX,EBX
{$ENDIF}
        MOV     ECX,EAX
        MOV     EAX,MSecs.Integer[0]
        MOV     EDX,MSecs.Integer[4]
        DIV     [EBX].IMSecsPerDay
        MOV     [ECX].TTimeStamp.Time,EDX
        MOV     [ECX].TTimeStamp.Date,EAX
        POP     EBX
end;


{ Time encoding and decoding }

function TryEncodeTime(Hour, Min, Sec, msec: Word; out Time: TDateTime): boolean;
begin
  Result := False;
  if (Hour < 24) and (Min < 60) and (Sec < 60) and (msec < 1000) then
  begin
    Time := (Hour * 3600000 + Min * 60000 + Sec * 1000 + msec) / MSecsPerDay;
    Result := True;
  end;
end;

function EncodeTime(Hour, Min, Sec, msec: Word): TDateTime;
begin
  if not TryEncodeTime(Hour, Min, Sec, msec, Result) then
    ConvertError(@STimeEncodeError);
end;

procedure DecodeTime(const DateTime: TDateTime; var Hour, Min, Sec, msec: Word);
var
  MinCount, MSecCount                   : Word;
begin
  DivMod(DateTimeToTimeStamp(DateTime).Time, 60000, MinCount, MSecCount);
  DivMod(MinCount, 60, Hour, Min);
  DivMod(MSecCount, 1000, Sec, msec);
end;

{ Date encoding and decoding }

function IsLeapYear(Year: Word): boolean;
begin
  Result := (Year mod 4 = 0) and ((Year mod 100 <> 0) or (Year mod 400 = 0));
end;

function TryEncodeDate(Year, Month, Day: Word; out Date: TDateTime): boolean;
var
  I                                     : integer;
  DayTable                              : PDayTable;
begin
  Result := False;
  DayTable := @MonthDays[IsLeapYear(Year)];
  if (Year >= 1) and (Year <= 9999) and (Month >= 1) and (Month <= 12) and
    (Day >= 1) and (Day <= DayTable^[Month]) then
  begin
    for I := 1 to Month - 1 do inc(Day, DayTable^[I]);
    I := Year - 1;
    Date := I * 365 + I div 4 - I div 100 + I div 400 + Day - DateDelta;
    Result := True;
  end;
end;

function EncodeDate(Year, Month, Day: Word): TDateTime;
begin
  if not TryEncodeDate(Year, Month, Day, Result) then
    ConvertError(@SDateEncodeError);
end;

function DecodeDateFully(const DateTime: TDateTime; var Year, Month, Day, DOW: Word): boolean;
const
  D1                                    = 365;
  D4                                    = D1 * 4 + 1;
  D100                                  = D4 * 25 - 1;
  D400                                  = D100 * 4 + 1;
var
  Y, M, d, I                            : Word;
  t                                     : integer;
  DayTable                              : PDayTable;
begin
  t := DateTimeToTimeStamp(DateTime).Date;
  if t <= 0 then
  begin
    Year := 0;
    Month := 0;
    Day := 0;
    DOW := 0;
    Result := False;
  end else
  begin
    DOW := t mod 7 + 1;
    Dec(t);
    Y := 1;
    while t >= D400 do
    begin
      Dec(t, D400);
      inc(Y, 400);
    end;
    DivMod(t, D100, I, d);
    if I = 4 then
    begin
      Dec(I);
      inc(d, D100);
    end;
    inc(Y, I * 100);
    DivMod(d, D4, I, d);
    inc(Y, I * 4);
    DivMod(d, D1, I, d);
    if I = 4 then
    begin
      Dec(I);
      inc(d, D1);
    end;
    inc(Y, I);
    Result := IsLeapYear(Y);
    DayTable := @MonthDays[Result];
    M := 1;
    while True do
    begin
      I := DayTable^[M];
      if d < I then Break;
      Dec(d, I);
      inc(M);
    end;
    Year := Y;
    Month := M;
    Day := d + 1;
  end;
end;

function InternalDecodeDate(const DateTime: TDateTime; var Year, Month, Day, DOW: Word): boolean;
begin
  Result := DecodeDateFully(DateTime, Year, Month, Day, DOW);
  Dec(DOW);
end;

procedure DecodeDate(const DateTime: TDateTime; var Year, Month, Day: Word);
var
  Dummy                                 : Word;
begin
  DecodeDateFully(DateTime, Year, Month, Day, Dummy);
end;

{$IFDEF MSWINDOWS}

procedure DateTimeToSystemTime(const DateTime: TDateTime; var SYSTEMTIME: TSystemTime);
begin
  with SYSTEMTIME do
  begin
    DecodeDateFully(DateTime, wYear, wMonth, wDay, wDayOfWeek);
    Dec(wDayOfWeek);
    DecodeTime(DateTime, wHour, wMinute, wSecond, wMilliseconds);
  end;
end;

function SystemTimeToDateTime(const SYSTEMTIME: TSystemTime): TDateTime;
begin
  with SYSTEMTIME do
  begin
    Result := EncodeDate(wYear, wMonth, wDay);
    if Result >= 0 then
      Result := Result + EncodeTime(wHour, wMinute, wSecond, wMilliseconds)
    else
      Result := Result - EncodeTime(wHour, wMinute, wSecond, wMilliseconds);
  end;
end;
{$ENDIF}

function DayOfWeek(const DateTime: TDateTime): Word;
begin
  Result := DateTimeToTimeStamp(DateTime).Date mod 7 + 1;
end;

function Date: TDateTime;
{$IFDEF MSWINDOWS}
var
  SYSTEMTIME                            : TSystemTime;
begin
  GetLocalTime(SYSTEMTIME);
  with SYSTEMTIME do Result := EncodeDate(wYear, wMonth, wDay);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  t                                     : TTime_T;
  UT                                    : TUnixTime;
begin
  __time(@t);
  localtime_r(@t, UT);
  Result := EncodeDate(UT.tm_year + 1900, UT.tm_mon + 1, UT.tm_mday);
end;
{$ENDIF}

function Time: TDateTime;
{$IFDEF MSWINDOWS}
var
  SYSTEMTIME                            : TSystemTime;
begin
  GetLocalTime(SYSTEMTIME);
  with SYSTEMTIME do
    Result := EncodeTime(wHour, wMinute, wSecond, wMilliseconds);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  t                                     : TTime_T;
  TV                                    : TTimeVal;
  UT                                    : TUnixTime;
begin
  gettimeofday(TV, nil);
  t := TV.tv_sec;
  localtime_r(@t, UT);
  Result := EncodeTime(UT.tm_hour, UT.tm_min, UT.tm_sec, TV.tv_usec div 1000);
end;
{$ENDIF}

function Now: TDateTime;
{$IFDEF MSWINDOWS}
var
  SYSTEMTIME                            : TSystemTime;
begin
  GetLocalTime(SYSTEMTIME);
  with SYSTEMTIME do
    Result := EncodeDate(wYear, wMonth, wDay) +
      EncodeTime(wHour, wMinute, wSecond, wMilliseconds);
end;
{$ENDIF}
{$IFDEF LINUX}
var
  t                                     : TTime_T;
  TV                                    : TTimeVal;
  UT                                    : TUnixTime;
begin
  gettimeofday(TV, nil);
  t := TV.tv_sec;
  localtime_r(@t, UT);
  Result := EncodeDate(UT.tm_year + 1900, UT.tm_mon + 1, UT.tm_mday) +
    EncodeTime(UT.tm_hour, UT.tm_min, UT.tm_sec, TV.tv_usec div 1000);
end;
{$ENDIF}

function IncMonth(const DateTime: TDateTime; NumberOfMonths: integer): TDateTime;
var
  Year, Month, Day                      : Word;
begin
  DecodeDate(DateTime, Year, Month, Day);
  IncAMonth(Year, Month, Day, NumberOfMonths);
  Result := EncodeDate(Year, Month, Day);
  ReplaceTime(Result, DateTime);
end;

procedure IncAMonth(var Year, Month, Day: Word; NumberOfMonths: integer = 1);
var
  DayTable                              : PDayTable;
  Sign                                  : integer;
begin
  if NumberOfMonths >= 0 then Sign := 1 else Sign := -1;
  Year := Year + (NumberOfMonths div 12);
  NumberOfMonths := NumberOfMonths mod 12;
  inc(Month, NumberOfMonths);
  if Word(Month - 1) > 11 then // if Month <= 0, word(Month-1) > 11)
  begin
    inc(Year, Sign);
    inc(Month, -12 * Sign);
  end;
  DayTable := @MonthDays[IsLeapYear(Year)];
  if Day > DayTable^[Month] then Day := DayTable^[Month];
end;

procedure ReplaceTime(var DateTime: TDateTime; const NewTime: TDateTime);
begin
  DateTime := Trunc(DateTime);
  if DateTime >= 0 then
    DateTime := DateTime + Abs(Frac(NewTime))
  else
    DateTime := DateTime - Abs(Frac(NewTime));
end;

procedure ReplaceDate(var DateTime: TDateTime; const NewDate: TDateTime);
var
  temp                                  : TDateTime;
begin
  temp := NewDate;
  ReplaceTime(temp, DateTime);
  DateTime := temp;
end;

function CurrentYear: Word;
{$IFDEF MSWINDOWS}
var
  SYSTEMTIME                            : TSystemTime;
begin
  GetLocalTime(SYSTEMTIME);
  Result := SYSTEMTIME.wYear;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  t                                     : TTime_T;
  UT                                    : TUnixTime;
begin
  __time(@t);
  localtime_r(@t, UT);
  Result := UT.tm_year + 1900;
end;
{$ENDIF}

{ Date/time to string conversions }




function datetostr(const DateTime: TDateTime): string;
begin
  DateTimeToString(Result, ShortDateFormat, DateTime);
end;

function TimeToStr(const DateTime: TDateTime): string;
begin
  DateTimeToString(Result, longTimeFormat, DateTime);
end;

function datetimetostr(const DateTime: TDateTime): string;
begin
  DateTimeToString(Result, '', DateTime);
end;

function FormatDateTime(const Format: string; DateTime: TDateTime): string;
begin
  DateTimeToString(Result, Format, DateTime);
end;

{ String to date/time conversions }

type
  TDateOrder = (doMDY, doDMY, doYMD);

procedure ScanBlanks(const s: string; var pos: integer);
var
  I                                     : integer;
begin
  I := pos;
  while (I <= length(s)) and (s[I] = ' ') do inc(I);
  pos := I;
end;

function ScanNumber(const s: string; var pos: integer;
  var Number: Word; var CharCount: Byte): boolean;
var
  I                                     : integer;
  n                                     : Word;
begin
  Result := False;
  CharCount := 0;
  ScanBlanks(s, pos);
  I := pos;
  n := 0;
  while (I <= length(s)) and (s[I] in ['0'..'9']) and (n < 1000) do
  begin
    n := n * 10 + (Ord(s[I]) - Ord('0'));
    inc(I);
  end;
  if I > pos then
  begin
    CharCount := I - pos;
    pos := I;
    Number := n;
    Result := True;
  end;
end;

function ScanString(const s: string; var pos: integer;
  const Symbol: string): boolean;
begin
  Result := False;
  if Symbol <> '' then
  begin
    ScanBlanks(s, pos);
    if AnsiCompareText(Symbol, Copy(s, pos, length(Symbol))) = 0 then
    begin
      inc(pos, length(Symbol));
      Result := True;
    end;
  end;
end;

function ScanChar(const s: string; var pos: integer; ch: Char): boolean;
begin
  Result := False;
  ScanBlanks(s, pos);
  if (pos <= length(s)) and (s[pos] = ch) then
  begin
    inc(pos);
    Result := True;
  end;
end;

function GetDateOrder(const DateFormat: string): TDateOrder;
var
  I                                     : integer;
begin
  Result := doMDY;
  I := 1;
  while I <= length(DateFormat) do
  begin
    case CHR(Ord(DateFormat[I]) and $DF) of
      'E': Result := doYMD;
      'Y': Result := doYMD;
      'M': Result := doMDY;
      'D': Result := doDMY;
    else
      inc(I);
      Continue;
    end;
    Exit;
  end;
  Result := doMDY;
end;

procedure ScanToNumber(const s: string; var pos: integer);
begin
  while (pos <= length(s)) and not (s[pos] in ['0'..'9']) do
  begin
    if s[pos] in LeadBytes then
      pos := NextCharIndex(s, pos)
    else
      inc(pos);
  end;
end;

function GetEraYearOffset(const Name: string): integer;
var
  I                                     : integer;
begin
  Result := 0;
  for I := Low(EraNames) to High(EraNames) do
  begin
    if EraNames[I] = '' then Break;
    if AnsiStrPos(PChar(EraNames[I]), PChar(Name)) <> nil then
    begin
      Result := EraYearOffsets[I];
      Exit;
    end;
  end;
end;

function ScanDate(const s: string; var pos: integer;
  var Date: TDateTime): boolean;
var
  DateOrder                             : TDateOrder;
  N1, N2, N3, Y, M, d                   : Word;
  L1, L2, L3, YearLen                   : Byte;
  CenturyBase                           : integer;
  EraName                               : string;
  EraYearOffset                         : integer;

  function EraToYear(Year: integer): integer;
  begin
{$IFDEF MSWINDOWS}
    if SysLocale.PriLangID = LANG_KOREAN then
    begin
      if Year <= 99 then
        inc(Year, (CurrentYear + Abs(EraYearOffset)) div 100 * 100);
      if EraYearOffset > 0 then
        EraYearOffset := -EraYearOffset;
    end
    else
      Dec(EraYearOffset);
{$ENDIF}
    Result := Year + EraYearOffset;
  end;

begin
  Y := 0;
  M := 0;
  d := 0;
  YearLen := 0;
  Result := False;
  DateOrder := GetDateOrder(ShortDateFormat);
  EraYearOffset := 0;
  if ShortDateFormat[1] = 'g' then // skip over prefix text
  begin
    ScanToNumber(s, pos);
    EraName := trim(Copy(s, 1, pos - 1));
    EraYearOffset := GetEraYearOffset(EraName);
  end
  else
    if AnsiPos('e', ShortDateFormat) > 0 then
      EraYearOffset := EraYearOffsets[1];
  if not (ScanNumber(s, pos, N1, L1) and ScanChar(s, pos, DateSeparator) and
    ScanNumber(s, pos, N2, L2)) then Exit;
  if ScanChar(s, pos, DateSeparator) then
  begin
    if not ScanNumber(s, pos, N3, L3) then Exit;
    case DateOrder of
      doMDY:
        begin
          Y := N3;
          YearLen := L3;
          M := N1;
          d := N2;
        end;
      doDMY:
        begin
          Y := N3;
          YearLen := L3;
          M := N2;
          d := N1;
        end;
      doYMD:
        begin
          Y := N1;
          YearLen := L1;
          M := N2;
          d := N3;
        end;
    end;
    if EraYearOffset > 0 then
      Y := EraToYear(Y)
    else
      if (YearLen <= 2) then
      begin
        CenturyBase := CurrentYear - TwoDigitYearCenturyWindow;
        inc(Y, CenturyBase div 100 * 100);
        if (TwoDigitYearCenturyWindow > 0) and (Y < CenturyBase) then
          inc(Y, 100);
      end;
  end else
  begin
    Y := CurrentYear;
    if DateOrder = doDMY then
    begin
      d := N1;
      M := N2;
    end else
    begin
      M := N1;
      d := N2;
    end;
  end;
  ScanChar(s, pos, DateSeparator);
  ScanBlanks(s, pos);
  if SysLocale.FarEast and (System.pos('ddd', ShortDateFormat) <> 0) then
  begin // ignore trailing text
    if ShortTimeFormat[1] in ['0'..'9'] then // stop at time digit
      ScanToNumber(s, pos)
    else // stop at time prefix
      repeat
        while (pos <= length(s)) and (s[pos] <> ' ') do inc(pos);
        ScanBlanks(s, pos);
      until (pos > length(s)) or
        (AnsiCompareText(TimeAMString, Copy(s, pos, length(TimeAMString))) = 0) or
        (AnsiCompareText(TimePMString, Copy(s, pos, length(TimePMString))) = 0);
  end;
  Result := TryEncodeDate(Y, M, d, Date);
end;

function ScanTime(const s: string; var pos: integer;
  var Time: TDateTime): boolean;
var
  BaseHour                              : integer;
  Hour, Min, Sec, msec                  : Word;
  Junk                                  : Byte;
begin
  Result := False;
  BaseHour := -1;
  if ScanString(s, pos, TimeAMString) or ScanString(s, pos, 'AM') then
    BaseHour := 0
  else
    if ScanString(s, pos, TimePMString) or ScanString(s, pos, 'PM') then
      BaseHour := 12;
  if BaseHour >= 0 then ScanBlanks(s, pos);
  if not ScanNumber(s, pos, Hour, Junk) then Exit;
  Min := 0;
  if ScanChar(s, pos, TimeSeparator) then
    if not ScanNumber(s, pos, Min, Junk) then Exit;
  Sec := 0;
  if ScanChar(s, pos, TimeSeparator) then
    if not ScanNumber(s, pos, Sec, Junk) then Exit;
  msec := 0;
  if ScanChar(s, pos, DecimalSeparator) then
    if not ScanNumber(s, pos, msec, Junk) then Exit;
  if BaseHour < 0 then
    if ScanString(s, pos, TimeAMString) or ScanString(s, pos, 'AM') then
      BaseHour := 0
    else
      if ScanString(s, pos, TimePMString) or ScanString(s, pos, 'PM') then
        BaseHour := 12;
  if BaseHour >= 0 then
  begin
    if (Hour = 0) or (Hour > 12) then Exit;
    if Hour = 12 then Hour := 0;
    inc(Hour, BaseHour);
  end;
  ScanBlanks(s, pos);
  Result := TryEncodeTime(Hour, Min, Sec, msec, Time);
end;



function StrToDateDef(const s: string; const Default: TDateTime): TDateTime;
begin
  if not TryStrToDate(s, Result) then
    Result := Default;
end;

function TryStrToDate(const s: string; out Value: TDateTime): boolean;
var
  pos                                   : integer;
begin
  pos := 1;
  Result := ScanDate(s, pos, Value) and (pos > length(s));
end;


function StrToTimeDef(const s: string; const Default: TDateTime): TDateTime;
begin
  if not TryStrToTime(s, Result) then
    Result := Default;
end;

function TryStrToTime(const s: string; out Value: TDateTime): boolean;
var
  pos                                   : integer;
begin
  pos := 1;
  Result := ScanTime(s, pos, Value) and (pos > length(s));
end;



function StrToDateTimeDef(const s: string; const Default: TDateTime): TDateTime;
begin
  if not TryStrToDateTime(s, Result) then
    Result := Default;
end;

function TryStrToDateTime(const s: string; out Value: TDateTime): boolean;
var
  pos                                   : integer;
  Date, Time                            : TDateTime;
begin
  Result := True;
  pos := 1;
  Time := 0;
  if not ScanDate(s, pos, Date) or
    not ((pos > length(s)) or ScanTime(s, pos, Time)) then

      // Try time only
    Result := TryStrToTime(s, Value)
  else
    if Date >= 0 then
      Value := Date + Time
    else
      Value := Date - Time;
end;

{ System error messages }

function SysErrorMessage(ErrorCode: integer): string;
{$IFDEF MSWINDOWS}
var
  Len                                   : integer;
  Buffer                                : array[0..255] of Char;
begin
  Len := FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM or
    FORMAT_MESSAGE_ARGUMENT_ARRAY, nil, ErrorCode, 0, Buffer,
    SizeOf(Buffer), nil);
  while (Len > 0) and (Buffer[Len - 1] in [#0..#32, '.']) do Dec(Len);
  SetString(Result, Buffer, Len);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
   //Result := Format('System error: %4x',[ErrorCode]);
  Result := strerror(ErrorCode);
end;
{$ENDIF}

{ Initialization file support }

function GetLocaleStr(Locale, LocaleType: integer; const Default: string): string;
{$IFDEF MSWINDOWS}
var
  l                                     : integer;
  Buffer                                : array[0..255] of Char;
begin
  l := GetLocaleInfo(Locale, LocaleType, Buffer, SizeOf(Buffer));
  if l > 0 then SetString(Result, Buffer, l - 1) else Result := Default;
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := Default;
end;
{$ENDIF}

function GetLocaleChar(Locale, LocaleType: integer; Default: Char): Char;
{$IFDEF MSWINDOWS}
var
  Buffer                                : array[0..1] of Char;
begin
  if GetLocaleInfo(Locale, LocaleType, Buffer, 2) > 0 then
    Result := Buffer[0] else
    Result := Default;
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := Default;
end;
{$ENDIF}

var
  DefShortMonthNames                    : array[1..12] of Pointer = (@SShortMonthNameJan,
    @SShortMonthNameFeb, @SShortMonthNameMar, @SShortMonthNameApr,
    @SShortMonthNameMay, @SShortMonthNameJun, @SShortMonthNameJul,
    @SShortMonthNameAug, @SShortMonthNameSep, @SShortMonthNameOct,
    @SShortMonthNameNov, @SShortMonthNameDec);

  DefLongMonthNames                     : array[1..12] of Pointer = (@SLongMonthNameJan,
    @SLongMonthNameFeb, @SLongMonthNameMar, @SLongMonthNameApr,
    @SLongMonthNameMay, @SLongMonthNameJun, @SLongMonthNameJul,
    @SLongMonthNameAug, @SLongMonthNameSep, @SLongMonthNameOct,
    @SLongMonthNameNov, @SLongMonthNameDec);

  DefShortDayNames                      : array[1..7] of Pointer = (@SShortDayNameSun,
    @SShortDayNameMon, @SShortDayNameTue, @SShortDayNameWed,
    @SShortDayNameThu, @SShortDayNameFri, @SShortDayNameSat);

  DefLongDayNames                       : array[1..7] of Pointer = (@SLongDayNameSun,
    @SLongDayNameMon, @SLongDayNameTue, @SLongDayNameWed,
    @SLongDayNameThu, @SLongDayNameFri, @SLongDayNameSat);

procedure GetMonthDayNames;
{$IFDEF MSWINDOWS}
var
  I, Day                                : integer;
  DefaultLCID                           : LCID;

  function LocalGetLocaleStr(LocaleType, Index: integer;
    const DefValues: array of Pointer): string;
  begin
    Result := GetLocaleStr(DefaultLCID, LocaleType, '');
    if Result = '' then Result := LoadResString(DefValues[Index]);
  end;

begin
  DefaultLCID := GetThreadLocale;
  for I := 1 to 12 do
  begin
    ShortMonthNames[I] := LocalGetLocaleStr(LOCALE_SABBREVMONTHNAME1 + I - 1,
      I - Low(DefShortMonthNames), DefShortMonthNames);
    LongMonthNames[I] := LocalGetLocaleStr(LOCALE_SMONTHNAME1 + I - 1,
      I - Low(DefLongMonthNames), DefLongMonthNames);
  end;
  for I := 1 to 7 do
  begin
    Day := (I + 5) mod 7;
    ShortDayNames[I] := LocalGetLocaleStr(LOCALE_SABBREVDAYNAME1 + Day,
      I - Low(DefShortDayNames), DefShortDayNames);
    LongDayNames[I] := LocalGetLocaleStr(LOCALE_SDAYNAME1 + Day,
      I - Low(DefLongDayNames), DefLongDayNames);
  end;
end;
{$ELSE}
{$IFDEF LINUX}

  function GetLocaleStr(LocaleIndex, Index: integer;
    const DefValues: array of Pointer): string;
  var
    temp                                : PChar;
  begin
    temp := nl_langinfo(LocaleIndex);
    if (temp = nil) or (temp^ = #0) then
      Result := LoadResString(DefValues[Index])
    else
      Result := temp;
  end;

var
  I                                     : integer;
begin
  for I := 1 to 12 do
  begin
    ShortMonthNames[I] := GetLocaleStr(ABMON_1 + I - 1,
      I - Low(DefShortMonthNames), DefShortMonthNames);
    LongMonthNames[I] := GetLocaleStr(MON_1 + I - 1,
      I - Low(DefLongMonthNames), DefLongMonthNames);
  end;
  for I := 1 to 7 do
  begin
    ShortDayNames[I] := GetLocaleStr(ABDAY_1 + I - 1,
      I - Low(DefShortDayNames), DefShortDayNames);
    LongDayNames[I] := GetLocaleStr(DAY_1 + I - 1,
      I - Low(DefLongDayNames), DefLongDayNames);
  end;
end;
{$ELSE}
var
  I                                     : integer;
begin
  for I := 1 to 12 do
  begin
    ShortMonthNames[I] := LoadResString(DefShortMonthNames[I]);
    LongMonthNames[I] := LoadResString(DefLongMonthNames[I]);
  end;
  for I := 1 to 7 do
  begin
    ShortDayNames[I] := LoadResString(DefShortDayNames[I]);
    LongDayNames[I] := LoadResString(DefLongDayNames[I]);
  end;
end;
{$ENDIF}
{$ENDIF}

{$IFDEF MSWINDOWS}

function EnumEraNames(Names: PChar): integer; stdcall;
var
  I                                     : integer;
begin
  Result := 0;
  I := Low(EraNames);
  while EraNames[I] <> '' do
    if (I = High(EraNames)) then
      Exit
    else inc(I);
  EraNames[I] := Names;
  Result := 1;
end;

function EnumEraYearOffsets(YearOffsets: PChar): integer; stdcall;
var
  I                                     : integer;
begin
  Result := 0;
  I := Low(EraYearOffsets);
  while EraYearOffsets[I] <> -1 do
    if (I = High(EraYearOffsets)) then
      Exit
    else inc(I);
  EraYearOffsets[I] := StrToIntDef(YearOffsets, 0);
  Result := 1;
end;

procedure GetEraNamesAndYearOffsets;
var
  J                                     : integer;
  CalendarType                          : CALTYPE;
begin
  CalendarType := StrToIntDef(GetLocaleStr(GetThreadLocale,
    LOCALE_IOPTIONALCALENDAR, '1'), 1);
  if CalendarType in [CAL_JAPAN, CAL_TAIWAN, CAL_KOREA] then
  begin
    EnumCalendarInfoA(@EnumEraNames, GetThreadLocale, CalendarType,
      CAL_SERASTRING);
    for J := Low(EraYearOffsets) to High(EraYearOffsets) do
      EraYearOffsets[J] := -1;
    EnumCalendarInfoA(@EnumEraYearOffsets, GetThreadLocale, CalendarType,
      CAL_IYEAROFFSETRANGE);
  end;
end;

function TranslateDateFormat(const FormatStr: string): string;
var
  I                                     : integer;
  l                                     : integer;
  CalendarType                          : CALTYPE;
  RemoveEra                             : boolean;
begin
  I := 1;
  Result := '';
  CalendarType := StrToIntDef(GetLocaleStr(GetThreadLocale,
    LOCALE_ICALENDARTYPE, '1'), 1);
  if not (CalendarType in [CAL_JAPAN, CAL_TAIWAN, CAL_KOREA]) then
  begin
    RemoveEra := SysLocale.PriLangID in [LANG_JAPANESE, LANG_CHINESE, LANG_KOREAN];
    if RemoveEra then
    begin
      while I <= length(FormatStr) do
      begin
        if not (FormatStr[I] in ['g', 'G']) then
          Result := Result + FormatStr[I];
        inc(I);
      end;
    end
    else
      Result := FormatStr;
    Exit;
  end;

  while I <= length(FormatStr) do
  begin
    if FormatStr[I] in LeadBytes then
    begin
      l := CharLength(FormatStr, I);
      Result := Result + Copy(FormatStr, I, l);
      inc(I, l);
    end else
    begin
      if StrLIComp(@FormatStr[I], 'gg', 2) = 0 then
      begin
        Result := Result + 'ggg';
        inc(I, 1);
      end
      else
        if StrLIComp(@FormatStr[I], 'yyyy', 4) = 0 then
        begin
          Result := Result + 'eeee';
          inc(I, 4 - 1);
        end
        else
          if StrLIComp(@FormatStr[I], 'yy', 2) = 0 then
          begin
            Result := Result + 'ee';
            inc(I, 2 - 1);
          end
          else
            if FormatStr[I] in ['y', 'Y'] then
              Result := Result + 'e'
            else
              Result := Result + FormatStr[I];
      inc(I);
    end;
  end;
end;
{$ENDIF}

{$IFDEF LINUX}

procedure InitEras;
var
  Count                                 : Byte;
  I, J, pos                             : integer;
  Number                                : Word;
  s                                     : string;
  Year, Month, Day                      : Word;
begin
  EraCount := 0;
  s := nl_langinfo(ERA);
  if s = '' then
    s := LoadResString(@SEraEntries);

  pos := 1;
  for I := 1 to MaxEraCount do
  begin
    if pos > length(s) then Break;
    if not (ScanChar(s, pos, '+') or ScanChar(s, pos, '-')) then Break;
         // Eras in which year increases with negative time (eg Christian BC era)
         // are not currently supported.
     //    EraRanges[I].Direction := S[Pos - 1];

         // Era offset, in years from Gregorian calendar year
    if not ScanChar(s, pos, ':') then Break;
    if ScanChar(s, pos, '-') then
      J := -1
    else
      J := 1;
    if not ScanNumber(s, pos, Number, Count) then Break;
    EraYearOffsets[I] := J * Number; // apply sign to Number

         // Era start date, in Gregorian year/month/day format
    if not ScanChar(s, pos, ':') then Break;
    if not ScanNumber(s, pos, Year, Count) then Break;
    if not ScanChar(s, pos, '/') then Break;
    if not ScanNumber(s, pos, Month, Count) then Break;
    if not ScanChar(s, pos, '/') then Break;
    if not ScanNumber(s, pos, Day, Count) then Break;
    EraRanges[I].StartDate := Trunc(EncodeDate(Year, Month, Day));
    EraYearOffsets[I] := Year - EraYearOffsets[I];

         // Era end date, in Gregorian year/month/day format
    if not ScanChar(s, pos, ':') then Break;
    if ScanString(s, pos, '+*') then // positive infinity
      EraRanges[I].EndDate := High(EraRanges[I].EndDate)
    else
      if ScanString(s, pos, '-*') then // negative infinity
        EraRanges[I].EndDate := Low(EraRanges[I].EndDate)
      else
        if not ScanNumber(s, pos, Year, Count) then
          Break
        else
        begin
          if not ScanChar(s, pos, '/') then Break;
          if not ScanNumber(s, pos, Month, Count) then Break;
          if not ScanChar(s, pos, '/') then Break;
          if not ScanNumber(s, pos, Day, Count) then Break;
          EraRanges[I].EndDate := Trunc(EncodeDate(Year, Month, Day));
        end;

         // Era name, in locale charset
    if not ScanChar(s, pos, ':') then Break;
    J := AnsiPos(':', Copy(s, pos, length(s) + 1 - pos));
    if J = 0 then Break;
    EraNames[I] := Copy(s, pos, J - 1);
    inc(pos, J - 1);

         // Optional Era format string for era year, in locale charset
    if not ScanChar(s, pos, ':') then Break;
    J := AnsiPos(';', Copy(s, pos, length(s) + 1 - pos));
    if J = 0 then
      J := 1 + length(s) + 1 - pos;
         {if J = 0 then Break;}
    EraYearFormats[I] := Copy(s, pos, J - 1);
    inc(pos, J - 1);
    inc(EraCount);
    if not ((pos > length(s)) or ScanChar(s, pos, ';')) then Break;
  end;

   // Clear the rest of the era slots, including partial entry from failed parse
  for I := EraCount + 1 to MaxEraCount do
  begin
    EraNames[I] := '';
    EraYearOffsets[I] := -1;
    EraRanges[I].StartDate := High(EraRanges[I].StartDate);
    EraRanges[I].EndDate := High(EraRanges[I].EndDate);
    EraYearFormats[I] := '';
  end;
end;
{$ENDIF}

{ Exception handling routines }

var
  OutOfMemory                           : EOutOfMemory;
  InvalidPointer                        : EInvalidPointer;

   { Convert physical address to logical address }

   { Format and return an exception error message }

function ExceptionErrorMessage(ExceptObject: TObject; ExceptAddr: Pointer;
  Buffer: PChar; Size: integer): integer;
{$IFDEF MSWINDOWS}

  function ConvertAddr(Address: Pointer): Pointer; assembler;
  asm
          TEST    EAX,EAX         { Always convert nil to nil }
          JE      @@1
          SUB     EAX, $1000      { offset from code start; code start set by linker to $1000 }
  @@1:
  end;

var
  MsgPtr                                : PChar;
  MsgEnd                                : PChar;
  MsgLen                                : integer;
  ModuleName                            : array[0..MAX_PATH] of Char;
  temp                                  : array[0..MAX_PATH] of Char;
  Format                                : array[0..255] of Char;
  Info                                  : TMemoryBasicInformation;
  ConvertedAddress                      : Pointer;
begin
  VirtualQuery(ExceptAddr, Info, SizeOf(Info));
  if (Info.State <> MEM_COMMIT) or
    (GetModuleFileName(THandle(Info.AllocationBase), temp, SizeOf(temp)) = 0) then
  begin
    GetModuleFileName(hInstance, temp, SizeOf(temp));
    ConvertedAddress := ConvertAddr(ExceptAddr);
  end
  else
    integer(ConvertedAddress) := integer(ExceptAddr) - integer(Info.AllocationBase);
  StrLCopy(ModuleName, AnsiStrRScan(temp, '\') + 1, SizeOf(ModuleName) - 1);
  MsgPtr := '';
  MsgEnd := '';
  if ExceptObject is Exception then
  begin
    MsgPtr := PChar(Exception(ExceptObject).Message);
    MsgLen := StrLen(MsgPtr);
    if (MsgLen <> 0) and (MsgPtr[MsgLen - 1] <> '.') then MsgEnd := '.';
  end;
  LoadString(FindResourceHInstance(hInstance),
    PResStringRec(@SException).Identifier, Format, SizeOf(Format));
  StrLFmt(Buffer, Size, Format, [ExceptObject.ClassName, ModuleName,
    ConvertedAddress, MsgPtr, MsgEnd]);
  Result := StrLen(Buffer);
end;
{$ENDIF}
{$IFDEF LINUX}
const
  Format                                = 'Exception %s in module %s at %p.'#$0A'%s%s'#$0A;
  ModuleName                            = '<unknown>';
var
  MsgPtr                                : PChar;
  MsgEnd                                : PChar;
  MsgLen                                : integer;
begin
  MsgPtr := '';
  MsgEnd := '';
  if ExceptObject is Exception then
  begin
    MsgPtr := PChar(Exception(ExceptObject).Message);
    MsgLen := StrLen(MsgPtr);
    if (MsgLen <> 0) and (MsgPtr[MsgLen - 1] <> '.') then MsgEnd := '.';
  end;
  StrLFmt(Buffer, Size, Format, [ExceptObject.ClassName, ModuleName,
    ExceptAddr, MsgPtr, MsgEnd]);
  Result := StrLen(Buffer);
end;
{$ENDIF}

{ Display exception message box }

procedure ShowException(ExceptObject: TObject; ExceptAddr: Pointer);
{$IFDEF MSWINDOWS}
var
  Title                                 : array[0..63] of Char;
  Buffer                                : array[0..1023] of Char;
  Dummy                                 : Cardinal;
begin
  ExceptionErrorMessage(ExceptObject, ExceptAddr, Buffer, SizeOf(Buffer));
  if IsConsole then
  begin
    Flush(Output);
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), Buffer, StrLen(Buffer), Dummy, nil);
    WriteFile(GetStdHandle(STD_OUTPUT_HANDLE), sLineBreak, 2, Dummy, nil);
  end
  else
  begin
    LoadString(FindResourceHInstance(hInstance), PResStringRec(@SExceptTitle).Identifier,
      Title, SizeOf(Title));
    MessageBox(0, Buffer, Title, MB_OK or MB_ICONSTOP or MB_TASKMODAL);
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  Buffer                                : array[0..1023] of Char;
begin
  ExceptionErrorMessage(ExceptObject, ExceptAddr, Buffer, SizeOf(Buffer));
  if TTextRec(ErrOutput).Mode = fmOutput then
    Flush(ErrOutput);
  __write(STDERR_FILENO, Buffer, StrLen(Buffer));
end;
{$ENDIF}

{ Raise abort exception }

procedure Abort;

  function ReturnAddr: Pointer;
  asm
          MOV     EAX,[EBP + 4]
  end;

begin
  raise EAbort.Create(SOperationAborted)at ReturnAddr;
end;

{ Raise out of memory exception }

procedure OutOfMemoryError;
begin
  raise OutOfMemory;
end;

{ Exception class }

constructor Exception.Create(const Msg: string);
begin
  FMessage := Msg;
end;


constructor Exception.CreateRes(Ident: integer);
begin
  FMessage := LoadStr(Ident);
end;

constructor Exception.CreateRes(ResStringRec: PResStringRec);
begin
  FMessage := LoadResString(ResStringRec);
end;



constructor Exception.CreateHelp(const Msg: string; AHelpContext: integer);
begin
  FMessage := Msg;
  FHelpContext := AHelpContext;
end;


constructor Exception.CreateResHelp(Ident: integer; AHelpContext: integer);
begin
  FMessage := LoadStr(Ident);
  FHelpContext := AHelpContext;
end;

constructor Exception.CreateResHelp(ResStringRec: PResStringRec;
  AHelpContext: integer);
begin
  FMessage := LoadResString(ResStringRec);
  FHelpContext := AHelpContext;
end;



{ EHeapException class }

procedure EHeapException.FreeInstance;
begin
  if AllowFree then
    inherited FreeInstance;
end;

{ Create I/O exception }

function CreateInOutError: EInOutError;
type
  TErrorRec = record
    code: integer;
    Ident: string;
  end;
const
  ErrorMap                              : array[0..6] of TErrorRec = (
    (code: 2; Ident: SFileNotFound),
    (code: 3; Ident: SInvalidFilename),
    (code: 4; Ident: STooManyOpenFiles),
    (code: 5; Ident: SAccessDenied),
    (code: 100; Ident: SEndOfFile),
    (code: 101; Ident: SDiskFull),
    (code: 106; Ident: SInvalidInput));
var
  I                                     : integer;
  InOutRes                              : integer;
begin
  I := Low(ErrorMap);
  InOutRes := IORESULT; // resets IOResult to zero
  while (I <= High(ErrorMap)) and (ErrorMap[I].code <> InOutRes) do inc(I);
  if I <= High(ErrorMap) then
    Result := EInOutError.Create(ErrorMap[I].Ident) else
    Result := EInOutError.CreateResFmt(@SInOutError, [InOutRes]);
  Result.ErrorCode := InOutRes;
end;

{ RTL error handler }

type
  TExceptRec = record
    EClass: ExceptClass;
    EIdent: string;
  end;

const
  MapLimit                              = {$IFDEF MSWINDOWS}24{$ENDIF}{$IFDEF LINUX}25{$ENDIF};
  ExceptMap                             : array[3..MapLimit] of TExceptRec = (
    (EClass: EDivByZero; EIdent: SDivByZero),
    (EClass: ERangeError; EIdent: SRangeError),
    (EClass: EIntOverflow; EIdent: SIntOverflow),
    (EClass: EInvalidOp; EIdent: SInvalidOp),
    (EClass: EZeroDivide; EIdent: SZeroDivide),
    (EClass: EOverflow; EIdent: SOverflow),
    (EClass: EUnderflow; EIdent: SUnderflow),
    (EClass: EInvalidCast; EIdent: SInvalidCast),
    (EClass: EAccessViolation; EIdent: SAccessViolation),
    (EClass: EPrivilege; EIdent: SPrivilege),
    (EClass: EControlC; EIdent: SControlC),
    (EClass: EStackOverflow; EIdent: SStackOverflow),
    (EClass: EVariantError; EIdent: SInvalidVarCast),
    (EClass: EVariantError; EIdent: SInvalidVarOp),
    (EClass: EVariantError; EIdent: SDispatchError),
    (EClass: EVariantError; EIdent: SVarArrayCreate),
    (EClass: EVariantError; EIdent: SVarNotArray),
    (EClass: EVariantError; EIdent: SVarArrayBounds),
    (EClass: EAssertionFailed; EIdent: SAssertionFailed),
    (EClass: EExternalException; EIdent: SExternalException),
    (EClass: EIntfCastError; EIdent: SIntfCastError),
    (EClass: ESafecallException; EIdent: SSafecallException)
{$IFDEF LINUX}
    ,
    (EClass: EQuit; EIdent: SQuit)
{$ENDIF}
    );

procedure ErrorHandler(ErrorCode: Byte; ErrorAddr: Pointer); export;
var
  E                                     : Exception;
begin
  case ErrorCode of
    1: E := OutOfMemory;
    2: E := InvalidPointer;
    3..24: with ExceptMap[ErrorCode] do E := EClass.Create(EIdent);
  else
    E := CreateInOutError;
  end;
  raise E at ErrorAddr;
end;

{ Assertion error handler }

{ This is complicated by the desire to make it look like the exception     }
{ happened in the user routine, so the debugger can give a decent stack    }
{ trace. To make that feasible, AssertErrorHandler calls a helper function }
{ to create the exception object, so that AssertErrorHandler itself does   }
{ not need any temps. After the exception object is created, the asm       }
{ routine RaiseAssertException sets up the registers just as if the user   }
{ code itself had raised the exception.                                    }


{ This code is based on the following assumptions:                         }
{  - Our direct caller (AssertErrorHandler) has an EBP frame               }
{  - ErrorStack points to where the return address would be if the         }
{    user program had called System.@RaiseExcept directly                  }

procedure RaiseAssertException(const E: Exception; const ErrorAddr, ErrorStack: Pointer);
asm
        MOV     ESP,ECX
        MOV     [ESP],EDX
        MOV     EBP,[EBP]
        JMP     System.@RaiseExcept
end;

{ If you change this procedure, make sure it does not have any local variables }
{ or temps that need cleanup - they won't get cleaned up due to the way        }
{ RaiseAssertException frame works. Also, it can not have an exception frame.  }

{$IFNDEF PC_MAPPED_EXCEPTIONS}

{ Abstract method invoke error handler }

procedure AbstractErrorHandler;
begin
  raise EAbstractError.CreateRes(@SAbstractError);
end;
{$ENDIF}

{$IFDEF LINUX}
const
  TRAP_ZERODIVIDE                       = 0;
  TRAP_SINGLESTEP                       = 1;
  TRAP_NMI                              = 2;
  TRAP_BREAKPOINT                       = 3;
  TRAP_OVERFLOW                         = 4;
  TRAP_BOUND                            = 5;
  TRAP_INVINSTR                         = 6;
  TRAP_DEVICENA                         = 7;
  TRAP_DOUBLEFAULT                      = 8;
  TRAP_FPOVERRUN                        = 9;
  TRAP_BADTSS                           = 10;
  TRAP_SEGMENTNP                        = 11;
  TRAP_STACKFAULT                       = 12;
  TRAP_GPFAULT                          = 13;
  TRAP_PAGEFAULT                        = 14;
  TRAP_RESERVED                         = 15;
  TRAP_FPE                              = 16;
  TRAP_ALIGNMENT                        = 17;
  TRAP_MACHINECHECK                     = 18;
  TRAP_CACHEFAULT                       = 19;
  TRAP_UNKNOWN                          = -1;

function MapFPUStatus(Status: LongWord): Byte;
begin
  if (Status and 1) = 1 then Result := 6 // STACK_CHECK or INVALID_OPERATION
  else
    if (Status and 2) = 2 then Result := 9 // DENORMAL_OPERAND
    else
      if (Status and 4) = 4 then Result := 7 // DIVIDE_BY_ZERO
      else
        if (Status and 8) = 8 then Result := 8 // OVERFLOW
        else
          if (Status and $10) = $10 then Result := 9 // UNDERFLOW
          else
            if (Status and $20) = $20 then Result := 6 // INEXACT_RESULT
            else Result := Byte(TRAP_UNKNOWN);
end;

function MapFPE(Context: PSigContext): Byte;
begin
  case Context^.trapno of
    TRAP_ZERODIVIDE:
      Result := 3;
    TRAP_FPOVERRUN:
      Result := 6;
    TRAP_FPE:
      Result := MapFPUStatus(Context^.fpstate^.sw);
  else
    Result := 6;
  end;
end;

function MapFault(Context: PSigContext): Byte;
begin
  case Context^.trapno of
    TRAP_OVERFLOW:
      Result := 5;
    TRAP_BOUND:
      Result := 4;
    TRAP_INVINSTR:
      Result := 12; // This doesn't seem right, but we don't
      // have an external exception to match!
    TRAP_STACKFAULT:
      Result := 14;
    TRAP_SEGMENTNP,
      TRAP_GPFAULT:
      Result := 12;
    TRAP_PAGEFAULT:
      Result := 11;
  else
    Result := 12;
  end;
end;

function MapSignal(SigNum: integer; Context: PSigContext): LongWord;
begin
  case SigNum of
    SIGINT: { Control-C }
      Result := 13;
    SIGQUIT: { Quit key (Control-\) }
      Result := 25;
    SIGFPE: { Floating Point Error }
      Result := MapFPE(Context);
    SIGSEGV: { Segmentation Violation }
      Result := MapFault(Context);
    SIGILL: { Illegal Instruction }
      Result := MapFault(Context);
    SIGBUS: { Bus Error }
      Result := MapFault(Context);
  else
    Result := 22; { must match System.reExternalException }
  end;
  Result := Result or (LongWord(SigNum) shl 16);
end;
{$ENDIF}

{$IFDEF MSWINDOWS}

function MapException(p: PExceptionRecord): TRuntimeError;
begin
  case p.ExceptionCode of
    STATUS_INTEGER_DIVIDE_BY_ZERO:
      Result := System.reDivByZero;
    STATUS_ARRAY_BOUNDS_EXCEEDED:
      Result := System.reRangeError;
    STATUS_INTEGER_OVERFLOW:
      Result := System.reIntOverflow;
    STATUS_FLOAT_INEXACT_RESULT,
      STATUS_FLOAT_INVALID_OPERATION,
      STATUS_FLOAT_STACK_CHECK:
      Result := System.reInvalidOp;
    STATUS_FLOAT_DIVIDE_BY_ZERO:
      Result := System.reZeroDivide;
    STATUS_FLOAT_OVERFLOW:
      Result := System.reOverflow;
    STATUS_FLOAT_UNDERFLOW,
      STATUS_FLOAT_DENORMAL_OPERAND:
      Result := System.reUnderflow;
    STATUS_ACCESS_VIOLATION:
      Result := System.reAccessViolation;
    STATUS_PRIVILEGED_INSTRUCTION:
      Result := System.rePrivInstruction;
    STATUS_CONTROL_C_EXIT:
      Result := System.reControlBreak;
    STATUS_STACK_OVERFLOW:
      Result := System.reStackOverflow;
  else
    Result := System.reExternalException;
  end;
end;

function GetExceptionClass(p: PExceptionRecord): ExceptClass;
var
  ErrorCode                             : Byte;
begin
  ErrorCode := Byte(MapException(p));
  Result := ExceptMap[ErrorCode].EClass;
end;


{$ENDIF}

{ RTL exception handler }

procedure ExceptHandler(ExceptObject: TObject; ExceptAddr: Pointer); far;
begin
  ShowException(ExceptObject, ExceptAddr);
  halt(1);
end;

{$IFDEF LINUX}
{$IFDEF DEBUG}
{
  Used for debugging the signal handlers.
}

procedure DumpContext(SigNum: integer; context: PSigContext);
var
  buff                                  : array[0..128] of Char;
begin
  StrFmt(buff, 'Context for signal: %d', [SigNum]);
  WriteLn(buff);
  StrFmt(buff, 'CS = %04X  DS = %04X  ES = %04X  FS = %04X  GS = %04X  SS = %04X',
    [context^.CS, context^.DS, context^.ES, context^.fs, context^.gs, context^.ss]);
  WriteLn(buff);
  StrFmt(buff, 'EAX = %08X  EBX = %08X  ECX = %08X  EDX = %08X',
    [context^.eax, context^.ebx, context^.ecx, context^.edx]);
  WriteLn(buff);
  StrFmt(buff, 'EDI = %08X  ESI = %08X  EBP = %08X  ESP = %08X',
    [context^.edi, context^.esi, context^.ebp, context^.esp]);
  WriteLn(buff);
  StrFmt(buff, 'EIP = %08X  EFLAGS = %08X  ESP(signal) = %08X  CR2 = %08X',
    [context^.eip, context^.eflags, context^.esp_at_signal, context^.cr2]);
  WriteLn(buff);
  StrFmt(buff, 'trapno = %d, err = %08x', [context^.trapno, context^.err]);
  WriteLn(buff);
end;
{$ENDIF}

{
  RaiseSignalException is called from SignalConverter, once we've made things look
  like there's a legitimate stack frame above us.  Now we will just create
  an exception object, and raise it via a software raise.
}

procedure RaiseSignalException(ExceptionEIP: LongWord; FaultAddr: LongWord; ErrorCode: LongWord);
begin
  raise GetExceptionObject(ExceptionEIP, FaultAddr, ErrorCode);
end;

{
  SignalConverter is where we come when a signal is raised that we want to convert
  to an exception.  This function stands the best chance of being called with a
  useable stack frame behind it for the purpose of stack unwinding.  We can't
  guarantee that, though.  The stack was modified by the baseline signal handler
  to make it look as though we were called by the faulting instruction.  That way
  the unwinder stands a chance of being able to clean things up.
}

procedure SignalConverter(ExceptionEIP: LongWord; FaultAddr: LongWord; ErrorCode: LongWord);
asm
        {
          Here's the tricky part.  We arrived here directly by virtue of our
          signal handler tweaking the execution context with our address.  That
          means there's no return address on the stack.  The unwinder needs to
          have a return address so that it can unwind past this function when
          we raise the Delphi exception.  We will use the faulting instruction
          pointer as a fake return address.  Because of the fencepost conditions
          in the Delphi unwinder, we need to have an address that is strictly
          greater than the actual faulting instruction, so we increment that
          address by one.  This may be in the middle of an instruction, but we
          don't care, because we will never be returning to that address.
          Finally, the way that we get this address onto the stack is important.
          The compiler will generate unwind information for SignalConverter that
          will attempt to undo any stack modifications that are made by this
          function when unwinding past it.  In this particular case, we don't want
          that to happen, so we use some assembly language tricks to get around
          the compiler noticing the stack modification.
        }
        MOV EBX, ESP      // Get the current stack pointer
        SUB EBX, 4        // Effectively decrement the stack by 4
        MOV ESP, EBX      //   by doing a move to ESP with a register value
        MOV [ESP], EAX    // Store the instruction pointer into the new stack loc
        INC [ESP]         // Increment by one to keep the unwinder happy

        { Reset the FPU, or things can go south down the line from here }
        FNINIT
        FWAIT
{$IFDEF PIC}
        PUSH    EAX
        PUSH    ECX
        CALL    GetGOT
        MOV     EAX, [EAX].offset Default8087CW
        FLDCW   [EAX]
        POP     ECX
        POP     EAX
{$ELSE}
        FLDCW   Default8087CW
{$ENDIF}
        PUSH    EBP
        MOV     EBP, ESP
        CALL    RaiseSignalException
end;

function TlsGetValue(Key: integer): Pointer; cdecl;
  external libpthreadmodulename Name 'pthread_getspecific';

{
  Under Linux, when the OS calls signal, it builds a special stack frame for
  it.  The frame has the argument to signal (the signal number), but the return
  address is to a function prototyped as sigreturn in signal.h.  That function
  takes a sigcontext structure as an argument.  So, it's possible to reference
  that structure by simply expanding the parameter list to our signal handler,
  and employing a judicious cast.  This is not portable to any other flavor
  of Unix, but it works for Linux, and it gives us access to the processor
  context at the issue point of the signal.
}

procedure SignalDispatcher(SigNum: integer; context: TSigContext); cdecl; export;
type
  PLongWord = ^LongWord;
var
  pc                                    : PSigContext;
  scalpel                               : LongWord;
begin
   //DumpContext(SigNum, @context);

     {
       Some of the ways that we get here are can lead us to big trouble.  For
       example, if the signal is SIGINT or SIGQUIT, these will commonly be raised
       to all threads in the process if the user generated them from the
       keyboard.  This is handled well by the Delphi threads, but if a non-Delphi
       thread lets one of these get by unhandled, terrible things will happen.
       So we look for that case, and eat SIGINT and SIGQUIT that have been issued
       on threads that are not Delphi threads.  If the signal is a SIGSEGV, or
       other fatal sort of signal, and the thread that we're running on is not
       a Delphi thread, then we are completely without options.  We have no
       recovery means, and we have to take the app down hard, right away.
     }
  if TlsGetValue(TlsIndex) = nil then
  begin
    if (SigNum = SIGINT) or (SigNum = SIGQUIT) then
      Exit;
    RunError(232);
  end;

   {
     If we are processing another exception right now, we definitely do not
     want to be dispatching any exceptions that are async, like SIGINT and
     SIGQUIT.  So we have check to see if OS signals are blocked.  If they are,
     we have to eat this signal right now.
   }
  if AreOSExceptionsBlocked and ((SigNum = SIGINT) or (SigNum = SIGQUIT)) then
    Exit;

   {
     If someone wants to delay the handling of SIGINT or SIGQUIT until such
     time as it's safe to handle it, they set DeferUserInterrupts to True.
     Then we just set a global variable saying that a SIGINT or SIGQUIT was
     issued.  It is the responsibility of some other body of code at this
     point to poll for changes to SIG(INT/QUIT)Issued
   }
  if DeferUserInterrupts then
  begin
    if SigNum = SIGINT then
    begin
      SIGINTIssued := True;
      Exit;
    end;
    if SigNum = SIGQUIT then
    begin
      SIGQUITIssued := True;
      Exit;
    end;
  end;

  BlockOSExceptions;

   {
     Under pthreads, our signal handler has been wrapped with another handler,
     which will not faithfully copy the context data back to the OS before
     returning.  If we modify the context structure that has been handed to us
     we will therefore not have our changes enacted upon the process.  So we
     have to do a little spelunking to find the original context so that we
     can modify it, instead.
   }
  scalpel := LongWord(@context);
  scalpel := scalpel - (4 + 4 + 4); // move past __signal, the RA and get to
   // the last stored ebp
  scalpel := PLongWord(scalpel)^;
  scalpel := scalpel + 4 + 4 + 4; // Skip the previous RA, the original signal,
   // then we're at the real context!
  pc := PSigContext(scalpel);

   {
     There are some OS stack frames between us and the exception, including
     some that are ill-formated.  The exception, once it gets here, is not
     considered resumable, so we will just change the address in the context,
     and have the OS return us to the start of a procedure that can raise
     a pascal exception safely, hopefully.  We build parameters to the function
     first:
   }
  pc^.eax := context.eip;
  pc^.edx := context.cr2;
  pc^.ecx := MapSignal(SigNum, @context);

   { And the function SignalConverter becomes the new execution point. }
  pc^.eip := LongWord(@SignalConverter);
end;

type
  TSignalMap = packed record
    SigNum: integer;
    Abandon: boolean;
    OldAction: TSigAction;
    Hooked: boolean;
  end;

var
  Signals                               : array[0..RTL_SIGLAST] of TSignalMap =
    ((SigNum: SIGINT; ),
    (SigNum: SIGFPE; ),
    (SigNum: SIGSEGV; ),
    (SigNum: SIGILL; ),
    (SigNum: SIGBUS; ),
    (SigNum: SIGQUIT; ));

function InquireSignal(RtlSigNum: integer): TSignalState;
var
  Action                                : TSigAction;
begin
  if sigaction(Signals[RtlSigNum].SigNum, nil, @Action) = -1 then
    raise Exception.Create(SSigactionFailed);
  if (@Action.__sigaction_handler <> @SignalDispatcher) then
  begin
    if Signals[RtlSigNum].Hooked then
      Result := ssOverridden
    else
      Result := ssNotHooked;
  end
  else
    Result := ssHooked;
end;

procedure AbandonSignalHandler(RtlSigNum: integer);
var
  I                                     : integer;
begin
  if RtlSigNum = RTL_SIGDEFAULT then
  begin
    for I := 0 to RTL_SIGLAST do
      AbandonSignalHandler(I);
    Exit;
  end;
  Signals[RtlSigNum].Abandon := True;
end;

procedure HookSignal(RtlSigNum: integer);
var
  Action                                : TSigAction;
  I                                     : integer;
begin
  if RtlSigNum = RTL_SIGDEFAULT then
  begin
    for I := 0 to RTL_SIGLAST do
      HookSignal(I);
    Exit;
  end;
  FillChar(Action, SizeOf(Action), 0);
  Action.__sigaction_handler := @SignalDispatcher;
  __sigaddset(@Action.sa_mask, SIGINT);
  __sigaddset(@Action.sa_mask, SIGQUIT);
  if sigaction(Signals[RtlSigNum].SigNum, @Action, @Signals[RtlSigNum].OldAction) = -1 then
    raise Exception.Create(SSigactionFailed);
  Signals[RtlSigNum].Hooked := True;
end;

procedure UnhookSignal(RtlSigNum: integer; OnlyIfHooked: boolean);
var
  I                                     : integer;
begin
  if RtlSigNum = RTL_SIGDEFAULT then
  begin
    for I := 0 to RTL_SIGLAST do
      UnhookSignal(I, OnlyIfHooked);
    Exit;
  end;
  if not Signals[RtlSigNum].Abandon then
  begin
    if OnlyIfHooked and (InquireSignal(RtlSigNum) <> ssHooked) then
      Exit;
    if sigaction(Signals[RtlSigNum].SigNum, @Signals[RtlSigNum].OldAction, nil) = -1 then
      raise Exception.Create(SSigactionFailed);
    Signals[RtlSigNum].Hooked := False;
  end;
end;

procedure UnhookOSExceptions;
begin
  if not Assigned(HookOSExceptionsProc) then
    UnhookSignal(RTL_SIGDEFAULT, True);
end;

procedure HookOSExceptions;
begin
  if Assigned(HookOSExceptionsProc) then
    HookOSExceptionsProc
  else
  begin
    HookSignal(RTL_SIGDEFAULT);
  end;
end;
{$ENDIF} // LINUX

procedure InitExceptions;
begin
  OutOfMemory := EOutOfMemory.CreateRes(@SOutOfMemory);
  InvalidPointer := EInvalidPointer.CreateRes(@SInvalidPointer);
  ErrorProc := ErrorHandler;
  ExceptProc := @ExceptHandler;
  ExceptionClass := Exception;

{$IFDEF MSWINDOWS}
  ExceptClsProc := @GetExceptionClass;
//  ExceptObjProc := @GetExceptionObject;
{$ENDIF}

//  AssertErrorProc := @AssertErrorHandler;

{$IFNDEF PC_MAPPED_EXCEPTIONS}
  AbstractErrorProc := @AbstractErrorHandler;
{$ENDIF}

{$IFDEF LINUX}
  if not IsLibrary then
    HookOSExceptions;
{$ENDIF}
end;

procedure DoneExceptions;
begin
  OutOfMemory.AllowFree := True;
  OutOfMemory.FreeInstance;
  OutOfMemory := nil;
  InvalidPointer.AllowFree := True;
  InvalidPointer.Free;
  InvalidPointer := nil;
  ErrorProc := nil;
  ExceptProc := nil;
  ExceptionClass := nil;
{$IFDEF MSWINDOWS}
  ExceptClsProc := nil;
  ExceptObjProc := nil;
{$ENDIF}
  AssertErrorProc := nil;
{$IFDEF LINUX}
  if not IsLibrary then
    UnhookOSExceptions;
{$ENDIF}
end;

{$IFDEF MSWINDOWS}

procedure InitPlatformId;
var
  OSVERSIONINFO                         : TOSVersionInfo;
begin
  OSVERSIONINFO.dwOSVersionInfoSize := SizeOf(OSVERSIONINFO);
  if GetVersionex(OSVERSIONINFO) then
    with OSVERSIONINFO do
    begin
      Win32Platform := dwPlatformId;
      Win32MajorVersion := dwMajorVersion;
      Win32MinorVersion := dwMinorVersion;
      Win32BuildNumber := dwBuildNumber;
      Win32CSDVersion := szCSDVersion;
    end;
end;

procedure Beep;
begin
  MessageBeep(0);
end;
{$ENDIF}
{$IFDEF LINUX}

procedure Beep;
var
  ch                                    : Char;
begin
  ch := #7;
  __write(STDOUT_FILENO, ch, 1);
end;
{$ENDIF}

{ MBCS functions }

function ByteTypeTest(p: PChar; Index: integer): TMbcsByteType;
{$IFDEF MSWINDOWS}
var
  I                                     : integer;
begin
  Result := mbSingleByte;
  if (p = nil) or (p[Index] = #$0) then Exit;
  if (Index = 0) then
  begin
    if p[0] in LeadBytes then Result := mbLeadByte;
  end
  else
  begin
    I := Index - 1;
    while (I >= 0) and (p[I] in LeadBytes) do Dec(I);
    if ((Index - I) mod 2) = 0 then Result := mbTrailByte
    else
      if p[Index] in LeadBytes then Result := mbLeadByte;
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  I, l                                  : integer;
begin
  Result := mbSingleByte;
  if (p = nil) or (p[Index] = #$0) then Exit;

  I := 0;
  repeat
    if p[I] in LeadBytes then
      l := StrCharLength(p + I)
    else
      l := 1;
    inc(I, l);
  until (I > Index);

  if (l <> 1) then
    if (I - l = Index) then
      Result := mbLeadByte
    else
      Result := mbTrailByte;
end;
{$ENDIF}

function ByteType(const s: string; Index: integer): TMbcsByteType;
begin
  Result := mbSingleByte;
  if SysLocale.FarEast then
    Result := ByteTypeTest(PChar(s), Index - 1);
end;

function StrByteType(Str: PChar; Index: Cardinal): TMbcsByteType;
begin
  Result := mbSingleByte;
  if SysLocale.FarEast then
    Result := ByteTypeTest(Str, Index);
end;

function ByteToCharLen(const s: string; MaxLen: integer): integer;
begin
  if length(s) < MaxLen then MaxLen := length(s);
  Result := ByteToCharIndex(s, MaxLen);
end;

function ByteToCharIndex(const s: string; Index: integer): integer;
var
  I                                     : integer;
begin
  Result := 0;
  if (Index <= 0) or (Index > length(s)) then Exit;
  Result := Index;
  if not SysLocale.FarEast then Exit;
  I := 1;
  Result := 0;
  while I <= Index do
  begin
    if s[I] in LeadBytes then
      I := NextCharIndex(s, I)
    else
      inc(I);
    inc(Result);
  end;
end;

procedure CountChars(const s: string; MaxChars: integer; var CharCount, ByteCount: integer);
var
  c, l, b                               : integer;
begin
  l := length(s);
  c := 1;
  b := 1;
  while (b < l) and (c < MaxChars) do
  begin
    inc(c);
    if s[b] in LeadBytes then
      b := NextCharIndex(s, b)
    else
      inc(b);
  end;
  if (c = MaxChars) and (b < l) and (s[b] in LeadBytes) then
    b := NextCharIndex(s, b) - 1;
  CharCount := c;
  ByteCount := b;
end;

function CharToByteIndex(const s: string; Index: integer): integer;
var
  Chars                                 : integer;
begin
  Result := 0;
  if (Index <= 0) or (Index > length(s)) then Exit;
  if (Index > 1) and SysLocale.FarEast then
  begin
    CountChars(s, Index - 1, Chars, Result);
    if (Chars < (Index - 1)) or (Result >= length(s)) then
      Result := 0 // Char index out of range
    else
      inc(Result);
  end
  else
    Result := Index;
end;

function CharToByteLen(const s: string; MaxLen: integer): integer;
var
  Chars                                 : integer;
begin
  Result := 0;
  if MaxLen <= 0 then Exit;
  if MaxLen > length(s) then MaxLen := length(s);
  if SysLocale.FarEast then
  begin
    CountChars(s, MaxLen, Chars, Result);
    if Result > length(s) then
      Result := length(s);
  end
  else
    Result := MaxLen;
end;

{ MBCS Helper functions }

function StrCharLength(const Str: PChar): integer;
begin
{$IFDEF LINUX}
  Result := mblen(Str, MB_CUR_MAX);
  if (Result = -1) then Result := 1;
{$ENDIF}
{$IFDEF MSWINDOWS}
  if SysLocale.FarEast then
    Result := integer(CharNext(Str)) - integer(Str)
  else
    Result := 1;
{$ENDIF}
end;

function StrNextChar(const Str: PChar): PChar;
begin
{$IFDEF LINUX}
  Result := Str + StrCharLength(Str);
{$ENDIF}
{$IFDEF MSWINDOWS}
  Result := CharNext(Str);
{$ENDIF}
end;

function CharLength(const s: string; Index: integer): integer;
begin
  Result := 1;
  assert((Index > 0) and (Index <= length(s)));
  if SysLocale.FarEast and (s[Index] in LeadBytes) then
    Result := StrCharLength(PChar(s) + Index - 1);
end;

function NextCharIndex(const s: string; Index: integer): integer;
begin
  Result := Index + 1;
  assert((Index > 0) and (Index <= length(s)));
  if SysLocale.FarEast and (s[Index] in LeadBytes) then
    Result := Index + StrCharLength(PChar(s) + Index - 1);
end;

function IsPathDelimiter(const s: string; Index: integer): boolean;
begin
  Result := (Index > 0) and (Index <= length(s)) and (s[Index] = PathDelim)
    and (ByteType(s, Index) = mbSingleByte);
end;

function IsDelimiter(const Delimiters, s: string; Index: integer): boolean;
begin
  Result := False;
  if (Index <= 0) or (Index > length(s)) or (ByteType(s, Index) <> mbSingleByte) then Exit;
  Result := StrScan(PChar(Delimiters), s[Index]) <> nil;
end;

function IncludeTrailingBackslash(const s: string): string;
begin
  Result := IncludeTrailingPathDelimiter(s);
end;

function IncludeTrailingPathDelimiter(const s: string): string;
begin
  Result := s;
  if not IsPathDelimiter(Result, length(Result)) then
    Result := Result + PathDelim;
end;

function ExcludeTrailingBackslash(const s: string): string;
begin
  Result := ExcludeTrailingPathDelimiter(s);
end;

function ExcludeTrailingPathDelimiter(const s: string): string;
begin
  Result := s;
  if IsPathDelimiter(Result, length(Result)) then
    SetLength(Result, length(Result) - 1);
end;

function AnsiPos(const Substr, s: string): integer;
var
  p                                     : PChar;
begin
  Result := 0;
  p := AnsiStrPos(PChar(s), PChar(SubStr));
  if p <> nil then
    Result := integer(p) - integer(PChar(s)) + 1;
end;

function AnsiCompareFileName(const s1, s2: string): integer;
begin
{$IFDEF MSWINDOWS}
  Result := AnsiCompareStr(AnsiLowerCaseFileName(s1), AnsiLowerCaseFileName(s2));
{$ENDIF}
{$IFDEF LINUX}
  Result := AnsiCompareStr(s1, s2);
{$ENDIF}
end;

function SameFileName(const s1, s2: string): boolean;
begin
  Result := AnsiCompareFileName(s1, s2) = 0;
end;

function AnsiLowerCaseFileName(const s: string): string;
{$IFDEF MSWINDOWS}
var
  I, l                                  : integer;
begin
  if SysLocale.FarEast then
  begin
    l := length(s);
    SetLength(Result, l);
    I := 1;
    while I <= l do
    begin
      Result[I] := s[I];
      if s[I] in LeadBytes then
      begin
        inc(I);
        Result[I] := s[I];
      end
      else
        if Result[I] in ['A'..'Z'] then inc(Byte(Result[I]), 32);
      inc(I);
    end;
  end
  else
    Result := AnsiLowerCase(s);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := AnsiLowerCase(s);
end;
{$ENDIF}

function AnsiUpperCaseFileName(const s: string): string;
{$IFDEF MSWINDOWS}
var
  I, l                                  : integer;
begin
  if SysLocale.FarEast then
  begin
    l := length(s);
    SetLength(Result, l);
    I := 1;
    while I <= l do
    begin
      Result[I] := s[I];
      if s[I] in LeadBytes then
      begin
        inc(I);
        Result[I] := s[I];
      end
      else
        if Result[I] in ['a'..'z'] then Dec(Byte(Result[I]), 32);
      inc(I);
    end;
  end
  else
    Result := AnsiUpperCase(s);
end;
{$ENDIF}
{$IFDEF LINUX}
begin
  Result := AnsiUpperCase(s);
end;
{$ENDIF}

function AnsiStrPos(Str, SubStr: PChar): PChar;
var
  L1, L2                                : Cardinal;
  ByteType                              : TMbcsByteType;
begin
  Result := nil;
  if (Str = nil) or (Str^ = #0) or (SubStr = nil) or (SubStr^ = #0) then Exit;
  L1 := StrLen(Str);
  L2 := StrLen(SubStr);
  Result := StrPos(Str, SubStr);
  while (Result <> nil) and ((L1 - Cardinal(Result - Str)) >= L2) do
  begin
    ByteType := StrByteType(Str, integer(Result - Str));
{$IFDEF MSWINDOWS}
    if (ByteType <> mbTrailByte) and
      (CompareString(LOCALE_USER_DEFAULT, 0, Result, L2, SubStr, L2) = 2) then Exit;
    if (ByteType = mbLeadByte) then inc(Result);
{$ENDIF}
{$IFDEF LINUX}
    if (ByteType <> mbTrailByte) and
      (strncmp(Result, SubStr, L2) = 0) then Exit;
{$ENDIF}
    inc(Result);
    Result := StrPos(Result, SubStr);
  end;
  Result := nil;
end;

function AnsiStrRScan(Str: PChar; CHR: Char): PChar;
begin
  Str := AnsiStrScan(Str, CHR);
  Result := Str;
  if CHR <> #$0 then
  begin
    while Str <> nil do
    begin
      Result := Str;
      inc(Str);
      Str := AnsiStrScan(Str, CHR);
    end;
  end
end;

function AnsiStrScan(Str: PChar; CHR: Char): PChar;
begin
  Result := StrScan(Str, CHR);
  while Result <> nil do
  begin
{$IFDEF MSWINDOWS}
    case StrByteType(Str, integer(Result - Str)) of
      mbSingleByte: Exit;
      mbLeadByte: inc(Result);
    end;
{$ENDIF}
{$IFDEF LINUX}
    if StrByteType(Str, integer(Result - Str)) = mbSingleByte then Exit;
{$ENDIF}
    inc(Result);
    Result := StrScan(Result, CHR);
  end;
end;

{$IFDEF MSWINDOWS}

function LCIDToCodePage(ALcid: LCID): integer;
var
  Buffer                                : array[0..6] of Char;
begin
  GetLocaleInfo(ALcid, LOCALE_IDEFAULTANSICODEPAGE, Buffer, SizeOf(Buffer));
  Result := StrToIntDef(Buffer, GetACP);
end;
{$ENDIF}

procedure InitSysLocale;
{$IFDEF MSWINDOWS}
var
  DefaultLCID                           : LCID;
  DefaultLangID                         : LangID;
  AnsiCPInfo                            : TCPInfo;
  I                                     : integer;
  BufferA                               : array[128..255] of Char;
  BufferW                               : array[128..256] of Word;
  PCharA                                : PChar;

  procedure InitLeadBytes;
  var
    I                                   : integer;
    J                                   : Byte;
  begin
    GetCPInfo(LCIDToCodePage(SysLocale.DefaultLCID), AnsiCPInfo);
    with AnsiCPInfo do
    begin
      I := 0;
      while (I < MAX_LEADBYTES) and ((LeadByte[I] or LeadByte[I + 1]) <> 0) do
      begin
        for J := LeadByte[I] to LeadByte[I + 1] do
          Include(LeadBytes, Char(J));
        inc(I, 2);
      end;
    end;
  end;

  function IsWesternGroup: boolean;
  type
    TLangGroup = $00..$1D;
    TLangGroups = set of TLangGroup;
  const
    lgNeutral                           = TLangGroup($00);
    lgDanish                            = TLangGroup($06);
    lgDutch                             = TLangGroup($13);
    lgEnglish                           = TLangGroup($09);
    lgFinnish                           = TLangGroup($0B);
    lgFrench                            = TLangGroup($0C);
    lgGerman                            = TLangGroup($07);
    lgItalian                           = TLangGroup($10);
    lgNorwegian                         = TLangGroup($14);
    lgPortuguese                        = TLangGroup($16);
    lgSpanish                           = TLangGroup($0A);
    lgSwedish                           = TLangGroup($1D);

    WesternGroups                       : TLangGroups = [
      lgNeutral,
      lgDanish,
      lgDutch,
      lgEnglish,
      lgFinnish,
      lgFrench,
      lgGerman,
      lgItalian,
      lgNorwegian,
      lgPortuguese,
      lgSpanish,
      lgSwedish
      ];
  begin
    Result := SysLocale.PriLangID in WesternGroups;
  end;

begin
   { Set default to English (US). }
  SysLocale.DefaultLCID := $0409;
  SysLocale.PriLangID := LANG_ENGLISH;
  SysLocale.SubLangID := SUBLANG_ENGLISH_US;

  DefaultLCID := GetThreadLocale;
  if DefaultLCID <> 0 then SysLocale.DefaultLCID := DefaultLCID;

  DefaultLangID := Word(DefaultLCID);
  if DefaultLangID <> 0 then
  begin
    SysLocale.PriLangID := DefaultLangID and $3FF;
    SysLocale.SubLangID := DefaultLangID shr 10;
  end;

  LeadBytes := [];
  if Win32Platform = VER_PLATFORM_WIN32_NT then
  begin
    if IsWesternGroup then
    begin
      SysLocale.MiddleEast := False;
      SysLocale.FarEast := False;
    end
    else
    begin
               { Far East (aka MBCS)? - }
      InitLeadBytes;
      SysLocale.FarEast := LeadBytes <> [];
      if SysLocale.FarEast then
      begin
        SysLocale.MiddleEast := False;
        Exit;
      end;

               { Middle East? }
      for I := Low(BufferA) to High(BufferA) do
        BufferA[I] := Char(I);
      PCharA := @BufferA; { not null terminated: include length in GetStringTypeExA call }
      GetStringTypeEx(SysLocale.DefaultLCID, CT_CTYPE2, PCharA, High(BufferA) - Low(BufferA) + 1, BufferW);
      for I := Low(BufferA) to High(BufferA) do
      begin
        SysLocale.MiddleEast := BufferW[I] = C2_RIGHTTOLEFT;
        if SysLocale.MiddleEast then
          Exit;
      end;
    end;
  end
  else
  begin
    SysLocale.MiddleEast := GetSystemMetrics(SM_MIDEASTENABLED) <> 0;
    SysLocale.FarEast := GetSystemMetrics(SM_DBCSENABLED) <> 0;
    if SysLocale.FarEast then
      InitLeadBytes;
  end;
end;
{$ENDIF}
{$IFDEF LINUX}
var
  I                                     : integer;
  buf                                   : array[0..3] of Char;
begin
  FillChar(SysLocale, SizeOf(SysLocale), 0);
  SysLocale.FarEast := MB_CUR_MAX <> 1;
  if not SysLocale.FarEast then Exit;

  buf[1] := #0;
  for I := 1 to 255 do
  begin
    buf[0] := CHR(I);
    if mblen(buf, 1) <> 1 then Include(LeadBytes, Char(I));
  end;
end;
{$ENDIF}

procedure GetFormatSettings;
{$IFDEF MSWINDOWS}
var
  HourFormat, TimePrefix, TimePostfix   : string;
  DefaultLCID                           : integer;
begin
  InitSysLocale;
  GetMonthDayNames;
  if SysLocale.FarEast then GetEraNamesAndYearOffsets;
  DefaultLCID := GetThreadLocale;
  CurrencyString := GetLocaleStr(DefaultLCID, LOCALE_SCURRENCY, '');
  CurrencyFormat := StrToIntDef(GetLocaleStr(DefaultLCID, LOCALE_ICURRENCY, '0'), 0);
  NegCurrFormat := StrToIntDef(GetLocaleStr(DefaultLCID, LOCALE_INEGCURR, '0'), 0);
  ThousandSeparator := GetLocaleChar(DefaultLCID, LOCALE_STHOUSAND, ',');
  DecimalSeparator := GetLocaleChar(DefaultLCID, LOCALE_SDECIMAL, '.');
  CurrencyDecimals := StrToIntDef(GetLocaleStr(DefaultLCID, LOCALE_ICURRDIGITS, '0'), 0);
  DateSeparator := GetLocaleChar(DefaultLCID, LOCALE_SDATE, '/');
  ShortDateFormat := TranslateDateFormat(GetLocaleStr(DefaultLCID, LOCALE_SSHORTDATE, 'm/d/yy'));
  LongDateFormat := TranslateDateFormat(GetLocaleStr(DefaultLCID, LOCALE_SLONGDATE, 'mmmm d, yyyy'));
  TimeSeparator := GetLocaleChar(DefaultLCID, LOCALE_STIME, ':');
  TimeAMString := GetLocaleStr(DefaultLCID, LOCALE_S1159, 'am');
  TimePMString := GetLocaleStr(DefaultLCID, LOCALE_S2359, 'pm');
  TimePrefix := '';
  TimePostfix := '';
  if StrToIntDef(GetLocaleStr(DefaultLCID, LOCALE_ITLZERO, '0'), 0) = 0 then
    HourFormat := 'h' else
    HourFormat := 'hh';
  if StrToIntDef(GetLocaleStr(DefaultLCID, LOCALE_ITIME, '0'), 0) = 0 then
    if StrToIntDef(GetLocaleStr(DefaultLCID, LOCALE_ITIMEMARKPOSN, '0'), 0) = 0 then
      TimePostfix := ' AMPM'
    else
      TimePrefix := 'AMPM ';
  ShortTimeFormat := TimePrefix + HourFormat + ':mm' + TimePostfix;
  longTimeFormat := TimePrefix + HourFormat + ':mm:ss' + TimePostfix;
  ListSeparator := GetLocaleChar(DefaultLCID, LOCALE_SLIST, ',');
end;
{$ELSE}
{$IFDEF LINUX}
const
   //first boolean is p_cs_precedes, second is p_sep_by_space
  CurrencyFormats                       : array[boolean, boolean] of Byte = ((1, 3), (0, 2));
   //first boolean is n_cs_precedes, second is n_sep_by_space and finally n_sign_posn
  NegCurrFormats                        : array[boolean, boolean, 0..4] of Byte =
    (((4, 5, 7, 6, 7), (15, 8, 10, 13, 10)), ((0, 1, 3, 1, 2), (14, 9, 11, 9, 12)));

  function TranslateFormat(s: PChar; const Default: string): string;
  begin
    Result := '';
    while s^ <> #0 do
    begin
      if s^ = '%' then
      begin
        inc(s);
        case s^ of
          'a': Result := Result + 'ddd';
          'A': Result := Result + 'dddd';
          'b': Result := Result + 'MMM';
          'B': Result := Result + 'MMMM';
          'c': Result := Result + 'c';
                     //        'C':  year / 100 not supported
          'd': Result := Result + 'dd';
          'D': Result := Result + 'MM/dd/yy';
          'e': Result := Result + 'd';
                     //        'E': alternate format not supported
          'g': Result := Result + 'yy';
          'G': Result := Result + 'yyyy';
          'h': Result := Result + 'MMM';
          'H': Result := Result + 'HH';
          'I': Result := Result + 'hh';
                     //        'j': day of year not supported
          'k': Result := Result + 'H';
          'l': Result := Result + 'h';
          'm': Result := Result + 'MM';
          'M': Result := Result + 'nn'; // minutes! not months!
          'n': Result := Result + sLineBreak; // line break
                     //        'O': alternate format not supported
          'P', // P's implied lowercasing of locale string is not supported
            'p': Result := Result + 'AMPM';
          'r': Result := Result + TranslateFormat(nl_langInfo(T_FMT_AMPM), '');
          'R': Result := Result + 'HH:mm';
                     //        's': number of seconds since Epoch not supported
          'S': Result := Result + 'ss';
          't': Result := Result + #9; // tab char
          'T': Result := Result + 'HH:mm:ss';
                     //        'u': day of week 1..7 not supported
                     //        'U': week number of the year not supported
                     //        'V': week number of the year not supported
                     //        'w': day of week 0..6 not supported
                     //        'W': week number of the year not supported
          'x': Result := Result + TranslateFormat(nl_langInfo(D_FMT), '');
          'X': Result := Result + TranslateFormat(nl_langinfo(T_FMT), '');
          'y': Result := Result + 'yy';
          'Y': Result := Result + 'yyyy';
                     //        'z': GMT offset is not supported
          '%': Result := Result + '%';
        end;
      end
      else
        Result := Result + s^;
      inc(s);
    end;
    if Result = '' then
      Result := Default;
  end;

  function GetFirstCharacter(const SrcString, match: string): Char;
  var
    I, p                                : integer;
  begin
    Result := match[1];
    for I := 1 to length(SrcString) do
    begin
      p := pos(SrcString[I], match);
      if p > 0 then
      begin
        Result := match[p];
        Break;
      end;
    end;
  end;

var
  p                                     : PLConv;
begin
  InitSysLocale;
  GetMonthDayNames;
  if SysLocale.FarEast then InitEras;

  CurrencyString := '';
  CurrencyFormat := 0;
  NegCurrFormat := 0;
  ThousandSeparator := ',';
  DecimalSeparator := '.';
  CurrencyDecimals := 0;

  p := localeconv;
  if p <> nil then
  begin
    if p^.currency_symbol <> nil then
      CurrencyString := p^.currency_symbol;

    if (Byte(p^.p_cs_precedes) in [0..1]) and
      (Byte(p^.p_sep_by_space) in [0..1]) then
    begin
      CurrencyFormat := CurrencyFormats[p^.p_cs_precedes, p^.p_sep_by_space];
      if p^.p_sign_posn in [0..4] then
        NegCurrFormat := NegCurrFormats[p^.n_cs_precedes, p^.n_sep_by_space,
          p^.n_sign_posn];
    end;

         // #0 is valid for ThousandSeparator.  Indicates no thousand separator.
    ThousandSeparator := p^.thousands_sep^;

         // #0 is not valid for DecimalSeparator.
    if p^.decimal_point <> #0 then
      DecimalSeparator := p^.decimal_point^;
    CurrencyDecimals := p^.frac_digits;
  end;

  ShortDateFormat := TranslateFormat(nl_langinfo(D_FMT), 'm/d/yy');
  LongDateFormat := TranslateFormat(nl_langinfo(D_T_FMT), ShortDateFormat);
  ShortTimeFormat := TranslateFormat(nl_langinfo(T_FMT), 'hh:mm AMPM');
  longTimeFormat := TranslateFormat(nl_langinfo(T_FMT_AMPM), ShortTimeFormat);

  DateSeparator := GetFirstCharacter(ShortDateFormat, '/.-');
  TimeSeparator := GetFirstCharacter(ShortTimeFormat, ':.');

  TimeAMString := nl_langinfo(AM_STR);
  TimePMString := nl_langinfo(PM_STR);
  ListSeparator := ',';
end;
{$ELSE}
var
  HourFormat, TimePrefix, TimePostfix   : string;
begin
  InitSysLocale;
  GetMonthDayNames;
  CurrencyString := '';
  CurrencyFormat := 0;
  NegCurrFormat := 0;
  ThousandSeparator := ',';
  DecimalSeparator := '.';
  CurrencyDecimals := 0;
  DateSeparator := '/';
  ShortDateFormat := 'm/d/yy';
  LongDateFormat := 'mmmm d, yyyy';
  TimeSeparator := ':';
  TimeAMString := 'am';
  TimePMString := 'pm';
  TimePrefix := '';
  TimePostfix := '';
  HourFormat := 'h';
  TimePostfix := ' AMPM';
  ShortTimeFormat := TimePrefix + HourFormat + ':mm' + TimePostfix;
  longTimeFormat := TimePrefix + HourFormat + ':mm:ss' + TimePostfix;
  ListSeparator := ',';
end;
{$ENDIF}
{$ENDIF}

function StringReplace(const s, OldPattern, NewPattern: string;
  Flags: TReplaceFlags): string;
var
  SearchStr, Patt, NewStr               : string;
  Offset                                : integer;
begin
  if rfIgnoreCase in Flags then
  begin
    SearchStr := AnsiUpperCase(s);
    Patt := AnsiUpperCase(OldPattern);
  end else
  begin
    SearchStr := s;
    Patt := OldPattern;
  end;
  NewStr := s;
  Result := '';
  while SearchStr <> '' do
  begin
    Offset := AnsiPos(Patt, SearchStr);
    if Offset = 0 then
    begin
      Result := Result + NewStr;
      Break;
    end;
    Result := Result + Copy(NewStr, 1, Offset - 1) + NewPattern;
    NewStr := Copy(NewStr, Offset + length(OldPattern), MaxInt);
    if not (rfReplaceAll in Flags) then
    begin
      Result := Result + NewStr;
      Break;
    end;
    SearchStr := Copy(SearchStr, Offset + length(Patt), MaxInt);
  end;
end;

function WrapText(const Line, BreakStr: string; const BreakChars: TSysCharSet;
  MaxCol: integer): string;
const
  QuoteChars                            = ['''', '"'];
var
  col, pos                              : integer;
  LinePos, LineLen                      : integer;
  BreakLen, BreakPos                    : integer;
  QuoteChar, CurChar                    : Char;
  ExistingBreak                         : boolean;
  l                                     : integer;
begin
  col := 1;
  pos := 1;
  LinePos := 1;
  BreakPos := 0;
  QuoteChar := ' ';
  ExistingBreak := False;
  LineLen := length(Line);
  BreakLen := length(BreakStr);
  Result := '';
  while pos <= LineLen do
  begin
    CurChar := Line[pos];
    if CurChar in LeadBytes then
    begin
      l := CharLength(Line, pos) - 1;
      inc(pos, l);
      inc(col, l);
    end
    else
    begin
      if CurChar = BreakStr[1] then
      begin
        if QuoteChar = ' ' then
        begin
          ExistingBreak := CompareText(BreakStr, Copy(Line, pos, BreakLen)) = 0;
          if ExistingBreak then
          begin
            inc(pos, BreakLen - 1);
            BreakPos := pos;
          end;
        end
      end
      else
        if CurChar in BreakChars then
        begin
          if QuoteChar = ' ' then BreakPos := pos
        end
        else
          if CurChar in QuoteChars then
          begin
            if CurChar = QuoteChar then
              QuoteChar := ' '
            else
              if QuoteChar = ' ' then
                QuoteChar := CurChar;
          end;
    end;
    inc(pos);
    inc(col);
    if not (QuoteChar in QuoteChars) and (ExistingBreak or
      ((col > MaxCol) and (BreakPos > LinePos))) then
    begin
      col := pos - BreakPos;
      Result := Result + Copy(Line, LinePos, BreakPos - LinePos + 1);
      if not (CurChar in QuoteChars) then
        while pos <= LineLen do
        begin
          if Line[pos] in BreakChars then
            inc(pos)
          else
            if Copy(Line, pos, length(sLineBreak)) = sLineBreak then
              inc(pos, length(sLineBreak))
            else
              Break;
        end;
      if not ExistingBreak and (pos < LineLen) then
        Result := Result + BreakStr;
      inc(BreakPos);
      LinePos := BreakPos;
      ExistingBreak := False;
    end;
  end;
  Result := Result + Copy(Line, LinePos, MaxInt);
end;

function WrapText(const Line: string; MaxCol: integer): string;
begin
  Result := WrapText(Line, sLineBreak, [' ', '-', #9], MaxCol); { do not localize }
end;

function FindCmdLineSwitch(const Switch: string; const Chars: TSysCharSet;
  IgnoreCase: boolean): boolean;
var
  I                                     : integer;
  s                                     : string;
begin
  for I := 1 to ParamCount do
  begin
    s := ParamStr(I);
    if (Chars = []) or (s[1] in Chars) then
      if IgnoreCase then
      begin
        if (AnsiCompareText(Copy(s, 2, MaxInt), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end
      else
      begin
        if (AnsiCompareStr(Copy(s, 2, MaxInt), Switch) = 0) then
        begin
          Result := True;
          Exit;
        end;
      end;
  end;
  Result := False;
end;

function FindCmdLineSwitch(const Switch: string): boolean;
begin
  Result := FindCmdLineSwitch(Switch, SwitchChars, True);
end;

function FindCmdLineSwitch(const Switch: string; IgnoreCase: boolean): boolean;
begin
  Result := FindCmdLineSwitch(Switch, SwitchChars, IgnoreCase);
end;

{ Package info structures }

type
  PPkgName = ^TPkgName;
  TPkgName = packed record
    HashCode: Byte;
    Name: array[0..255] of Char;
  end;

   { PackageUnitFlags:
     bit      meaning
     -----------------------------------------------------------------------------------------
     0      | main unit
     1      | package unit (dpk source)
     2      | $WEAKPACKAGEUNIT unit
     3      | original containment of $WEAKPACKAGEUNIT (package into which it was compiled)
     4      | implicitly imported
     5..7   | reserved
   }
  PUnitName = ^TUnitName;
  TUnitName = packed record
    Flags: Byte;
    HashCode: Byte;
    Name: array[0..255] of Char;
  end;

   { Package flags:
     bit     meaning
     -----------------------------------------------------------------------------------------
     0     | 1: never-build                  0: always build
     1     | 1: design-time only             0: not design-time only      on => bit 2 = off
     2     | 1: run-time only                0: not run-time only         on => bit 1 = off
     3     | 1: do not check for dup units   0: perform normal dup unit check
     4..25 | reserved
     26..27| (producer) 0: pre-V4, 1: undefined, 2: c++, 3: Pascal
     28..29| reserved
     30..31| 0: EXE, 1: Package DLL, 2: Library DLL, 3: undefined
   }
  PPackageInfoHeader = ^TPackageInfoHeader;
  TPackageInfoHeader = packed record
    Flags: Cardinal;
    RequiresCount: integer;
      {Requires: array[0..9999] of TPkgName;
      ContainsCount: Integer;
      Contains: array[0..9999] of TUnitName;}
  end;

function PackageInfoTable(Module: HMODULE): PPackageInfoHeader;
var
  ResInfo                               : HRSRC;
  data                                  : THandle;
begin
  Result := nil;
  ResInfo := FindResource(Module, 'PACKAGEINFO', RT_RCDATA);
  if ResInfo <> 0 then
  begin
    data := LoadResource(Module, ResInfo);
    if data <> 0 then
    try
      Result := LockResource(data);
      UnlockResource(data);
    finally
      FreeResource(data);
    end;
  end;
end;

function GetModuleName(Module: HMODULE): string;
var
  ModName                               : array[0..MAX_PATH] of Char;
begin
  SetString(Result, ModName, GetModuleFileName(Module, ModName, SizeOf(ModName)));
end;

var
  Reserved                              : integer;

procedure CheckForDuplicateUnits(Module: HMODULE);
var
  ModuleFlags                           : Cardinal;

  function IsUnitPresent(hc: Byte; UnitName: PChar; Module: HMODULE;
    const ModuleName: string; var UnitPackage: string): boolean;
  var
    I                                   : integer;
    InfoTable                           : PPackageInfoHeader;
    LibModule                           : PLibModule;
    PkgName                             : PPkgName;
    UName                               : PUnitName;
    Count                               : integer;
  begin
    Result := True;
    if (StrIComp(UnitName, 'SysInit') <> 0) and
      (StrIComp(UnitName, PChar(ModuleName)) <> 0) then
    begin
      LibModule := LibModuleList;
      while LibModule <> nil do
      begin
        if LibModule.Instance <> Cardinal(Module) then
        begin
          InfoTable := PackageInfoTable(HMODULE(LibModule.Instance));
          if (InfoTable <> nil) and (InfoTable.Flags and pfModuleTypeMask = pfPackageModule) and
            ((InfoTable.Flags and pfIgnoreDupUnits) = (ModuleFlags and pfIgnoreDupUnits)) then
          begin
            PkgName := PPkgName(integer(InfoTable) + SizeOf(InfoTable^));
            Count := InfoTable.RequiresCount;
                              { Skip the Requires list }
            for I := 0 to Count - 1 do inc(integer(PkgName), StrLen(PkgName.Name) + 2);
            Count := integer(Pointer(PkgName)^);
            UName := PUnitName(integer(PkgName) + 4);
            for I := 0 to Count - 1 do
            begin
              with UName^ do
                                       // Test Flags to ignore weak package units
                if ((HashCode = hc) or (HashCode = 0) or (hc = 0)) and
                  ((Flags and $06) = 0) and (StrIComp(UnitName, Name) = 0) then
                begin
                  UnitPackage := changeFileExt(extractfilename(
                    GetModuleName(HMODULE(LibModule.Instance))), '');
                  Exit;
                end;
              inc(integer(UName), StrLen(UName.Name) + 3);
            end;
          end;
        end;
        LibModule := LibModule.Next;
      end;
    end;
    Result := False;
  end;

  function FindLibModule(Module: HMODULE): PLibModule;
  begin
    Result := LibModuleList;
    while Result <> nil do
    begin
      if Result.Instance = Cardinal(Module) then Exit;
      Result := Result.Next;
    end;
  end;

  procedure InternalUnitCheck(Module: HMODULE);
  var
    I                                   : integer;
    InfoTable                           : PPackageInfoHeader;
    UnitPackage                         : string;
    ModuleName                          : string;
    PkgName                             : PPkgName;
    UName                               : PUnitName;
    Count                               : integer;
    LibModule                           : PLibModule;
  begin
    InfoTable := PackageInfoTable(Module);
    if (InfoTable <> nil) and (InfoTable.Flags and pfModuleTypeMask = pfPackageModule) then
    begin
      if ModuleFlags = 0 then ModuleFlags := InfoTable.Flags;
      ModuleName := changeFileExt(extractfilename(GetModuleName(Module)), '');
      PkgName := PPkgName(integer(InfoTable) + SizeOf(InfoTable^));
      Count := InfoTable.RequiresCount;
      for I := 0 to Count - 1 do
      begin
        with PkgName^ do
{$IFDEF MSWINDOWS}
          InternalUnitCheck(GetModuleHandle(PChar(changeFileExt(Name, '.bpl'))));
{$ENDIF}
{$IFDEF LINUX}
        InternalUnitCheck(GetModuleHandle(Name));
{$ENDIF}
        inc(integer(PkgName), StrLen(PkgName.Name) + 2);
      end;
      LibModule := FindLibModule(Module);
      if (LibModule = nil) or ((LibModule <> nil) and (LibModule.Reserved <> Reserved)) then
      begin
        if LibModule <> nil then LibModule.Reserved := Reserved;
        Count := integer(Pointer(PkgName)^);
        UName := PUnitName(integer(PkgName) + 4);
        for I := 0 to Count - 1 do
        begin
          with UName^ do
                           // Test Flags to ignore weak package units
            if ((Flags and ufWeakPackageUnit) = 0) and
              IsUnitPresent(HashCode, Name, Module, ModuleName, UnitPackage) then
              raise EPackageError.CreateResFmt(@SDuplicatePackageUnit,
                [ModuleName, Name, UnitPackage]);
          inc(integer(UName), StrLen(UName.Name) + 3);
        end;
      end;
    end;
  end;

begin
  inc(Reserved);
  ModuleFlags := 0;
  InternalUnitCheck(Module);
end;

{$IFDEF LINUX}

function LoadLibrary(ModuleName: PChar): HMODULE;
begin
  Result := HMODULE(dlopen(ModuleName, RTLD_LAZY));
end;

function FreeLibrary(Module: HMODULE): LongBool;
begin
  Result := LongBool(dlclose(Pointer(Module)));
end;

function GetProcAddress(Module: HMODULE; Proc: PChar): Pointer;
var
  Info                                  : TDLInfo;
  ERROR                                 : PChar;
  ModHandle                             : HMODULE;
begin
   // dlsym doesn't clear the error state when the function succeeds
  dlerror;
  Result := dlsym(Pointer(Module), Proc);
  ERROR := dlerror;
  if ERROR <> nil then
    Result := nil
  else
    if dladdr(Result, Info) <> 0 then
    begin
            {   In glibc 2.1.3 and earlier, dladdr returns a nil dli_fname
                for addresses in the main program file.  In glibc 2.1.91 and
                later, dladdr fills in the dli_fname for addresses in the
                main program file, but dlopen will segfault when given
                the main program file name.
                Workaround:  Check the symbol base address against the main
                program file's base address, and only call dlopen with a nil
                filename to get the module name of the main program.  }

      if Info.dli_fbase = ExeBaseAddress then
        Info.dli_fname := nil;

      ModHandle := HMODULE(dlopen(Info.dli_fname, RTLD_LAZY));
      if ModHandle <> 0 then
      begin
        dlclose(Pointer(ModHandle));
        if ModHandle <> Module then
          Result := nil;
      end;
    end else Result := nil;
end;

type
  plink_map = ^link_map;
  link_map = record
    l_addr: Pointer;
    l_name: PChar;
    l_ld: Pointer;
    l_next, l_prev: plink_map;
  end;

  pr_debug = ^r_debug;
  r_debug = record
    r_version: integer;
    r_map: plink_map;
    r_brk: Pointer;
    r_state: integer;
    r_ldbase: Pointer;
  end;

var
  _r_debug                              : pr_debug = nil;

function ScanLinkMap(Func: Pointer): plink_map;
var
  linkmap                               : plink_map;

  function Eval(linkmap: plink_map; Func: Pointer): boolean;
  asm
//        MOV    ECX,[EBP]
        PUSH   EBP
        CALL   EDX
        POP    ECX
  end;

begin
  if _r_debug = nil then
    _r_debug := dlsym(RTLD_DEFAULT, '_r_debug');
  if _r_debug = nil then
  begin
    Assert(False, 'Unable to locate ''_r_debug'' symbol'); // do not localize
    Result := nil;
    Exit;
  end;
  linkmap := _r_debug.r_map;
  while linkmap <> nil do
  begin
    if not Eval(linkmap, Func) then Break;
    linkmap := linkmap.l_next;
  end;
  Result := linkmap;
end;

function InitModule(linkmap: plink_map): HMODULE;
begin
  if linkmap <> nil then
  begin
    Result := HMODULE(dlopen(linkmap.l_name, RTLD_LAZY));
    if Result <> 0 then
      dlclose(Pointer(Result));
  end else Result := 0;
end;

function GetModuleHandle(ModuleName: PChar): HMODULE;

  function CheckModuleName(linkmap: plink_map): boolean;
  var
    BaseName                            : PChar;
  begin
    Result := True;
    if ((ModuleName = nil) and ((linkmap.l_name = nil) or (linkmap.l_name[0] = #0))) or
      ((ModuleName[0] = PathDelim) and (StrComp(ModuleName, linkmap.l_name) = 0)) then
    begin
      Result := False;
      Exit;
    end else
    begin
            // Locate the start of the actual filename
      BaseName := StrRScan(linkmap.l_name, PathDelim);
      if BaseName = nil then
        BaseName := linkmap.l_name
      else inc(BaseName); // The filename is actually located at BaseName+1
      if StrComp(ModuleName, BaseName) = 0 then
      begin
        Result := False;
        Exit;
      end;
    end;
  end;

begin
  Result := InitModule(ScanLinkMap(@CheckModuleName));
end;

function GetPackageModuleHandle(PackageName: PChar): HMODULE;
var
  PkgName                               : array[0..MAX_PATH] of Char;

  function CheckPackageName(linkmap: plink_map): boolean;
  var
    BaseName                            : PChar;
  begin
    Result := True;
    if linkmap.l_name <> nil then
    begin
            // Locate the start of the actual filename
      BaseName := StrRScan(linkmap.l_name, PathDelim);
      if BaseName = nil then
        BaseName := linkmap.l_name // If there is no path info, just use the whole name
      else inc(BaseName); // The filename is actually located at BaseName+1
      Result := StrPos(BaseName, PkgName) = nil;
    end;
  end;

  procedure MakePkgName(Prefix, Name: PChar);
  begin
    StrCopy(PkgName, Prefix);
    StrLCat(PkgName, Name, SizeOf(PkgName) - 1);
    PkgName[High(PkgName)] := #0;
  end;

begin
  if (PackageName = nil) or (StrScan(PackageName, PathDelim) <> nil) then
    Result := 0
  else
  begin
    MakePkgName('bpl', PackageName); // First check the default prefix
    Result := InitModule(ScanLinkMap(@CheckPackageName));
    if Result = 0 then
    begin
      MakePkgName('dcl', PackageName); // Next check the design-time prefix
      Result := InitModule(ScanLinkMap(@CheckPackageName));
      if Result = 0 then
      begin
        MakePkgName('', PackageName); // finally check without a prefix
        Result := InitModule(ScanLinkMap(@CheckPackageName));
      end;
    end;
  end;
end;

{$ENDIF}

{$IFDEF MSWINDOWS}
procedure Sleep; external kernel32 Name 'Sleep'; stdcall;
{$ENDIF}
{$IFDEF LINUX}

procedure Sleep(milliseconds: Cardinal);
begin
  usleep(milliseconds * 1000); // usleep is in microseconds
end;
{$ENDIF}

{ InitializePackage }


{ FinalizePackage }

procedure FinalizePackage(Module: HMODULE);
type
  TPackageUnload = procedure;
var
  PackageUnload                         : TPackageUnload;
begin
  @PackageUnload := GetProcAddress(Module, 'Finalize'); //Do not localize
  if Assigned(PackageUnload) then
    PackageUnload
  else
    raise EPackageError.CreateRes(@sInvalidPackageHandle);
end;

{ LoadPackage }

function LoadPackage(const Name: string): HMODULE;
{$IFDEF LINUX}
var
  DLErrorMsg                            : string;
{$ENDIF}
begin
{$IFDEF MSWINDOWS}
  Result := SafeLoadLibrary(Name);
{$ENDIF}
{$IFDEF LINUX}
  Result := HMODULE(dlOpen(PChar(Name), PkgLoadingMode));
{$ENDIF}
  if Result = 0 then
  begin
{$IFDEF LINUX}
    DLErrorMsg := dlerror;
{$ENDIF}
    raise EPackageError.CreateResFmt(@sErrorLoadingPackage,
      [Name,
{$IFDEF MSWINDOWS}SysErrorMessage(getlasterror){$ENDIF}
{$IFDEF LINUX}DLErrorMsg{$ENDIF}]);
  end;
  try
    InitializePackage(Result);
  except
{$IFDEF MSWINDOWS}
    FreeLibrary(Result);
{$ENDIF}
{$IFDEF LINUX}
    dlclose(Pointer(Result));
{$ENDIF}
    raise;
  end;
end;

{ UnloadPackage }

procedure UnloadPackage(Module: HMODULE);
begin
  FinalizePackage(Module);
{$IFDEF MSWINDOWS}
  FreeLibrary(Module);
{$ENDIF}
{$IFDEF LINUX}
  dlclose(Pointer(Module));
  InvalidateModuleCache;
{$ENDIF}
end;

{ GetPackageInfo }

{$IFDEF MSWINDOWS}
{ RaiseLastWin32Error }

procedure RaiseLastWin32Error;
begin
  RaiseLastOSError;
end;

{ Win32Check }

function Win32Check(RetVal: BOOL): BOOL;
begin
  if not RetVal then RaiseLastOSError;
  Result := RetVal;
end;
{$ENDIF}

type
  PTerminateProcInfo = ^TTerminateProcInfo;
  TTerminateProcInfo = record
    Next: PTerminateProcInfo;
    Proc: TTerminateProc;
  end;

var
  TerminateProcList                     : PTerminateProcInfo = nil;

procedure AddTerminateProc(TermProc: TTerminateProc);
var
  p                                     : PTerminateProcInfo;
begin
  New(p);
  p^.Next := TerminateProcList;
  p^.Proc := TermProc;
  TerminateProcList := p;
end;

function CallTerminateProcs: boolean;
var
  PI                                    : PTerminateProcInfo;
begin
  Result := True;
  PI := TerminateProcList;
  while Result and (PI <> nil) do
  begin
    Result := PI^.Proc;
    PI := PI^.Next;
  end;
end;

procedure FreeTerminateProcs;
var
  PI                                    : PTerminateProcInfo;
begin
  while TerminateProcList <> nil do
  begin
    PI := TerminateProcList;
    TerminateProcList := PI^.Next;
    Dispose(PI);
  end;
end;

{ --- }

function AL1(const p): LongWord;
asm
        MOV     EDX,DWORD PTR [P]
        XOR     EDX,DWORD PTR [P+4]
        XOR     EDX,DWORD PTR [P+8]
        XOR     EDX,DWORD PTR [P+12]
        MOV     EAX,EDX
end;

function AL2(const p): LongWord;
asm
        MOV     EDX,DWORD PTR [P]
        ROR     EDX,5
        XOR     EDX,DWORD PTR [P+4]
        ROR     EDX,5
        XOR     EDX,DWORD PTR [P+8]
        ROR     EDX,5
        XOR     EDX,DWORD PTR [P+12]
        MOV     EAX,EDX
end;

const
  AL1s                                  : array[0..3] of LongWord = ($FFFFFFF0, $FFFFEBF0, 0, $FFFFFFFF);
  AL2s                                  : array[0..3] of LongWord = ($42C3ECEF, $20F7AEB6, $D1C2F74E, $3F6574DE);

procedure ALV;
begin
  raise Exception.Create(SNL);
end;

function ALR: Pointer;
var
  LibModule                             : PLibModule;
begin
  if MainInstance <> 0 then
    Result := Pointer(LoadResource(MainInstance, FindResource(MainInstance, 'DVCLAL',
      RT_RCDATA)))
  else
  begin
    Result := nil;
    LibModule := LibModuleList;
    while LibModule <> nil do
    begin
      with LibModule^ do
      begin
        Result := Pointer(LoadResource(Instance, FindResource(Instance, 'DVCLAL',
          RT_RCDATA)));
        if Result <> nil then Break;
      end;
      LibModule := LibModule.Next;
    end;
  end;
end;

function GDAL: LongWord;
type
  TDVCLAL = array[0..3] of LongWord;
  PDVCLAL = ^TDVCLAL;
var
  p                                     : Pointer;
  A1, A2                                : LongWord;
  PAL1s, PAL2s                          : PDVCLAL;
  ALOK                                  : boolean;
begin
  p := ALR;
  if p <> nil then
  begin
    A1 := AL1(p^);
    A2 := AL2(p^);
    Result := A1;
    PAL1s := @AL1s;
    PAL2s := @AL2s;
    ALOK := ((A1 = PAL1s[0]) and (A2 = PAL2s[0])) or
      ((A1 = PAL1s[1]) and (A2 = PAL2s[1])) or
      ((A1 = PAL1s[2]) and (A2 = PAL2s[2]));
    FreeResource(integer(p));
    if not ALOK then ALV;
  end else Result := AL1s[3];
end;

procedure RCS;
var
  p                                     : Pointer;
  ALOK                                  : boolean;
begin
  p := ALR;
  if p <> nil then
  begin
    ALOK := (AL1(p^) = AL1s[2]) and (AL2(p^) = AL2s[2]);
    FreeResource(integer(p));
  end else ALOK := False;
  if not ALOK then ALV;
end;

procedure RPR;
var
  al                                    : LongWord;
begin
  al := GDAL;
  if (al <> AL1s[1]) and (al <> AL1s[2]) then ALV;
end;

{$IFDEF MSWINDOWS}

procedure InitDriveSpacePtr;
var
  Kernel                                : THandle;
begin
  Kernel := GetModuleHandle(Windows.Kernel32);
  if Kernel <> 0 then
    @GetDiskFreeSpaceEx := GetProcAddress(Kernel, 'GetDiskFreeSpaceExA');
  if not Assigned(GetDiskFreeSpaceEx) then
    GetDiskFreeSpaceEx := @BackfillGetDiskFreeSpaceEx;
end;
{$ENDIF}

// Win95 does not return the actual value of the result.
// These implementations are consistent on all platforms.

function InterlockedIncrement(var I: integer): integer;
asm
        MOV     EDX,1
        XCHG    EAX,EDX
  LOCK  XADD    [EDX],EAX
        INC     EAX
end;

function InterlockedDecrement(var I: integer): integer;
asm
        MOV     EDX,-1
        XCHG    EAX,EDX
  LOCK  XADD    [EDX],EAX
        DEC     EAX
end;

function InterlockedExchange(var a: integer; b: integer): integer;
asm
        XCHG    [EAX],EDX
        MOV     EAX,EDX
end;

// The InterlockedExchangeAdd Win32 API is not available on Win95.

function InterlockedExchangeAdd(var a: integer; b: integer): integer;
asm
        XCHG    EAX,EDX
  LOCK  XADD    [EDX],EAX
end;

{ TSimpleRWSync }

constructor TSimpleRWSync.Create;
begin
  inherited Create;
  InitializeCriticalSection(FLock);
end;

destructor TSimpleRWSync.Destroy;
begin
  inherited Destroy;
  DeleteCriticalSection(FLock);
end;

function TSimpleRWSync.BeginWrite: boolean;
begin
  EnterCriticalSection(FLock);
  Result := True;
end;

procedure TSimpleRWSync.EndWrite;
begin
  LeaveCriticalSection(FLock);
end;

procedure TSimpleRWSync.BeginRead;
begin
  EnterCriticalSection(FLock);
end;

procedure TSimpleRWSync.EndRead;
begin
  LeaveCriticalSection(FLock);
end;

{ TThreadLocalCounter }

constructor TThreadLocalCounter.Create;
begin
  inherited Create;
  FHoldTime := 1000 * 60; // 1 minute
end;

destructor TThreadLocalCounter.Destroy;
var
  p, q                                  : PThreadInfo;
  I                                     : integer;
begin
  assert(FOpenCount = 0);
  for I := 0 to High(FHashTable) do
  begin
    p := FHashTable[I];
    FHashTable[I] := nil;
    while p <> nil do
    begin
      q := p;
      p := p^.Next;
      FreeMem(q);
    end;
  end;
  p := FPurgatory;
  FPurgatory := nil;
  while p <> nil do
  begin
    q := p;
    p := p^.NextDead;
    FreeMem(q);
  end;
  inherited Destroy;
end;

function TThreadLocalCounter.HashIndex: Byte;
var
  h                                     : Word;
begin
  h := Word(GetCurrentThreadID);
  Result := (WordRec(h).Lo xor WordRec(h).Hi) and 15;
end;

procedure TThreadLocalCounter.Open(var Thread: PThreadInfo);
var
  p                                     : PThreadInfo;
  h                                     : Byte;
  CurThread                             : Cardinal;
begin
  InterlockedIncrement(FOpenCount);
  h := HashIndex;
  p := FHashTable[h];
  CurThread := GetCurrentThreadID;
  while (p <> nil) and (p.ThreadID <> CurThread) do
    p := p.Next;
  if p = nil then
  begin
    p := Recycle;

    if p = nil then
      p := PThreadInfo(AllocMem(SizeOf(TThreadInfo)));

    p.ThreadID := CurThread;

         // Another thread could start traversing the list between when we set the
         // head to P and when we assign to P.Next.  Initializing P.Next to point
         // to itself will make others loop until we assign the tail to P.Next.
    p.Next := p;
    p.Next := PThreadInfo(InterlockedExchange(integer(FHashTable[h]), integer(p)));
  end;
  Thread := p;
end;

procedure TThreadLocalCounter.Close(var Thread: PThreadInfo);
var
  p, q, Head                            : PThreadInfo;
  Trail                                 : ^PThreadInfo;
  TimeStamp                             : Cardinal;
begin
  assert(FOpenCount > 0);
  Head := PThreadInfo(InterlockedExchange(integer(FPurgatory), 0));
  if InterlockedDecrement(FOpenCount) = 0 then
  begin
    p := Head;
    Trail := @Head;
    TimeStamp := GetTickCount;
    while p <> nil do
    begin
      q := p;
      p := p.NextDead;
      if q.ThreadID <> 0 then
      begin
        q.ThreadID := 0; // node is now fully dead
        q.RecursionCount := TimeStamp;
      end
      else
        if (TimeStamp < q.RecursionCount) or // system clock rollover
          ((TimeStamp - q.RecursionCount) > FHoldTime) then
        begin
                        // Free nodes that have not been reused for the HoldTime period
          FreeMem(q);
          Trail^ := p;
          Continue;
        end;
      Trail := @q^.NextDead;
    end;
  end;

  Reattach(Head);
  Thread := nil;
end;

procedure TThreadLocalCounter.Delete(var Thread: PThreadInfo);
var
  p                                     : PThreadInfo;
begin
   // Don't clear the thread info data yet - the caller could potentially
   // refer to the thread info after deleting it (bad idea, but we don't have
   // to be a pain about it)  Close will clear the thread info data of
   // deleted nodes later.

  assert(FOpenCount > 0);
  assert(Thread <> nil);
   // Find the node that points to the given Thread
  p := PThreadInfo(@FHashTable[HashIndex]);
  while (p.Next <> nil) and (p.Next <> Thread) do
    p := p.Next;

  assert(p.Next = Thread);
   // remove Thread from the live list
  InterlockedExchange(integer(p.Next), integer(Thread.Next));
   // Add Thread to the head of the purgatory list
  Thread.NextDead := Thread;
  Thread.NextDead := PThreadInfo(InterlockedExchange(integer(FPurgatory), integer(Thread)));
end;

procedure TThreadLocalCounter.Reattach(List: PThreadInfo);
var
  p                                     : PThreadInfo;
begin
  if List <> nil then // Put it back.  Carefully.
  begin
    p := List;
    while p.NextDead <> nil do p := p.NextDead;
    p.NextDead := List;
    p.NextDead := PThreadInfo(InterlockedExchange(integer(FPurgatory), integer(List)));
  end;
end;

function TThreadLocalCounter.Recycle: PThreadInfo;
var
  Head, p, q                            : PThreadInfo;
begin
  Head := PThreadInfo(InterlockedExchange(integer(FPurgatory), 0));
  p := Head;
  q := Head;
  while (p <> nil) and (p.ThreadID <> 0) do
  begin
    q := p;
    p := p.NextDead;
  end;

  if p <> nil then // found one to recycle
  begin
    if p = Head then
      Head := p.NextDead
    else
      q.NextDead := p.NextDead;
    FillChar(p^, SizeOf(p^), 0);
  end;

  Reattach(Head);
  Result := p;
end;

{ TMultiReadExclusiveWriteSynchronizer }
const
  mrWriteRequest                        = $FFFF; // 65535 concurrent read requests (threads)
   // 32768 concurrent write requests (threads)
   // only one write lock at a time
   // 2^32 lock recursions per thread (read and write combined)

constructor TMultiReadExclusiveWriteSynchronizer.Create;
begin
  inherited Create;
  FSentinel := mrWriteRequest;
  FReadSignal := CreateEvent(nil, True, True, nil); // manual reset, start signaled
  FWriteSignal := CreateEvent(nil, False, False, nil); // auto reset, start blocked
  FWaitRecycle := INFINITE;
  tls := TThreadLocalCounter.Create;
end;

destructor TMultiReadExclusiveWriteSynchronizer.Destroy;
begin
  BeginWrite;
  inherited Destroy;
  CloseHandle(FReadSignal);
  CloseHandle(FWriteSignal);
  tls.Free;
end;

procedure TMultiReadExclusiveWriteSynchronizer.BlockReaders;
begin
  ResetEvent(FReadSignal);
end;

procedure TMultiReadExclusiveWriteSynchronizer.UnblockReaders;
begin
  SetEvent(FReadSignal);
end;

procedure TMultiReadExclusiveWriteSynchronizer.UnblockOneWriter;
begin
  SetEvent(FWriteSignal);
end;

procedure TMultiReadExclusiveWriteSynchronizer.WaitForReadSignal;
begin
  WaitForSingleObject(FReadSignal, FWaitRecycle);
end;

procedure TMultiReadExclusiveWriteSynchronizer.WaitForWriteSignal;
begin
  WaitForSingleObject(FWriteSignal, FWaitRecycle);
end;

{$IFDEF DEBUG_MREWS}
var
  X                                     : integer;

procedure TMultiReadExclusiveWriteSynchronizer.Debug(const Msg: string);
begin
  OutputDebugString(PChar(Format('%d %s Thread=%x Sentinel=%d',
    [InterlockedIncrement(X), Msg, GetCurrentThreadID, FSentinel])));
end;
{$ENDIF}

function TMultiReadExclusiveWriteSynchronizer.BeginWrite: boolean;
var
  Thread                                : PThreadInfo;
  HasReadLock                           : boolean;
  ThreadID                              : Cardinal;
  test                                  : integer;
  OldRevisionLevel                      : Cardinal;
begin
{$IFDEF DEBUG_MREWS}
  Debug('Write enter');
{$ENDIF}
  Result := True;
  ThreadID := GetCurrentThreadID;
  if FWriterID <> ThreadID then // somebody or nobody has a write lock
  begin
         // Prevent new readers from entering while we wait for the existing readers
         // to exit.
    BlockReaders;

    OldRevisionLevel := FRevisionLevel;

    tls.Open(Thread);
    try
            // We have another lock already. It must be a read lock, because if it
            // were a write lock, FWriterID would be our threadid.
      HasReadLock := Thread.RecursionCount > 0;

      if HasReadLock then // acquiring a write lock requires releasing read locks
        InterlockedIncrement(FSentinel);
    finally
      tls.Close(Thread); // don't leave tls open during the wait loop... it could take awhile
    end;

         // xchgadd returns prev value
    while (InterlockedExchangeAdd(FSentinel, -mrWriteRequest) - mrWriteRequest) <> 0 do
    begin
{$IFDEF DEBUG_MREWS}
      Debug('Write loop');
{$ENDIF}
      test := InterlockedExchangeAdd(FSentinel, mrWriteRequest) + mrWriteRequest;
{$IFDEF DEBUG_MREWS}
      Debug('Write loop2');
{$ENDIF}
               // prevent writer-writer race condition (prevent both writers from waiting for signal)
      if test > 0 then
        WaitForWriteSignal;
    end;

         // Put our read lock marker back before we lose track of it
    if HasReadLock then
      InterlockedDecrement(FSentinel);

    FWriterID := ThreadID;

    Result := integer(OldRevisionLevel) = (InterlockedIncrement(integer(FRevisionLevel)) - 1);
  end;

  inc(FWriteRecursionCount);
{$IFDEF DEBUG_MREWS}
  Debug('Write lock');
{$ENDIF}
end;

procedure TMultiReadExclusiveWriteSynchronizer.EndWrite;
var
  Thread                                : PThreadInfo;
begin
{$IFDEF DEBUG_MREWS}
  Debug('Write end');
{$ENDIF}
  assert(FWriterID = GetCurrentThreadID);
  tls.Open(Thread);
  try
    Dec(FWriteRecursionCount);
    if FWriteRecursionCount = 0 then
    begin
      FWriterID := 0;
      InterlockedExchangeAdd(FSentinel, mrWriteRequest);
      UnblockOneWriter;
            // This sleep(0) gives slight favor to writers over readers when both are waiting.
            // It gives the writer a chance to take the lock before readers flood in.
      Sleep(0);
      UnblockReaders;
    end;
    if Thread.RecursionCount = 0 then
      tls.Delete(Thread);
  finally
    tls.Close(Thread);
  end;
{$IFDEF DEBUG_MREWS}
  Debug('Write unlock');
{$ENDIF}
end;

procedure TMultiReadExclusiveWriteSynchronizer.BeginRead;
var
  Thread                                : PThreadInfo;
  DidDec                                : boolean;
begin
{$IFDEF DEBUG_MREWS}
  Debug('Read enter');
{$ENDIF}
  DidDec := False;
  if FWriterID <> GetCurrentThreadID then
  begin
    while (InterlockedDecrement(FSentinel) <= 0) do
    begin
{$IFDEF DEBUG_MREWS}
      Debug('Read loop');
{$ENDIF}
      InterlockedIncrement(FSentinel);
{$IFDEF DEBUG_MREWS}
      Debug('Read loop2');
{$ENDIF}
      WaitForReadSignal;
    end;
    DidDec := True;
  end;
  tls.Open(Thread);
  try
    inc(Thread.RecursionCount);
    if (Thread.RecursionCount > 1) and DidDec then
      InterlockedIncrement(FSentinel); // remove recursions from sentinel
  finally
    tls.Close(Thread);
  end;
{$IFDEF DEBUG_MREWS}
  Debug('Read lock');
{$ENDIF}
end;

procedure TMultiReadExclusiveWriteSynchronizer.EndRead;
var
  Thread                                : PThreadInfo;
begin
{$IFDEF DEBUG_MREWS}
  Debug('Read end');
{$ENDIF}
  tls.Open(Thread);
  try
    Dec(Thread.RecursionCount);
    if (Thread.RecursionCount = 0) then
    begin
      tls.Delete(Thread);
      if (FWriterID <> GetCurrentThreadID) and
        (InterlockedIncrement(FSentinel) = mrWriteRequest) then
        UnblockOneWriter;
    end;
  finally
    tls.Close(Thread);
  end;
{$IFDEF DEBUG_MREWS}
  Debug('Read unlock');
{$ENDIF}
end;

procedure FreeAndNil(var obj);
var
  temp                                  : TObject;
begin
  temp := TObject(obj);
  Pointer(obj) := nil;
  temp.Free;
end;

{ Interface support routines }

function Supports(const Instance: IInterface; const IID: TGUID; out IntF): boolean;
begin
  Result := (Instance <> nil) and (Instance.QueryInterface(IID, IntF) = 0);
end;

function Supports(const Instance: TObject; const IID: TGUID; out IntF): boolean;
var
  LUnknown                              : IUnknown;
begin
  Result := (Instance <> nil) and
    ((Instance.GetInterface(IUnknown, LUnknown) and Supports(LUnknown, IID, IntF)) or
    Instance.GetInterface(IID, IntF));
end;

function Supports(const Instance: IInterface; const IID: TGUID): boolean;
var
  temp                                  : IInterface;
begin
  Result := Supports(Instance, IID, temp);
end;

function Supports(const Instance: TObject; const IID: TGUID): boolean;
var
  temp                                  : IInterface;
begin
  Result := Supports(Instance, IID, temp);
end;

function Supports(const AClass: TClass; const IID: TGUID): boolean;
begin
  Result := AClass.GetInterfaceEntry(IID) <> nil;
end;

{$IFDEF MSWINDOWS}
{ TLanguages }

{ Query the OS for information for a specified locale. Unicode version. Works correctly on Asian WinNT. }

function GetLocaleDataW(ID: LCID; Flag: DWORD): string;
var
  Buffer                                : array[0..1023] of widechar;
begin
  Buffer[0] := #0;
  GetLocaleInfoW(ID, Flag, Buffer, SizeOf(Buffer) div 2);
  Result := Buffer;
end;

{ Query the OS for information for a specified locale. ANSI Version. Works correctly on Asian Win95. }

function GetLocaleDataA(ID: LCID; Flag: DWORD): string;
var
  Buffer                                : array[0..1023] of Char;
begin
  Buffer[0] := #0;
  SetString(Result, Buffer, GetLocaleInfoA(ID, Flag, Buffer, SizeOf(Buffer)) - 1);
end;

{ Called for each supported locale. }

function TLanguages.LocalesCallback(LocaleID: PChar): integer; stdcall;
var
  AID                                   : LCID;
  ShortLangName                         : string;
  GetLocaleDataProc                     : function(ID: LCID; Flag: DWORD): string;
begin
  if Win32Platform = VER_PLATFORM_WIN32_NT then
    GetLocaleDataProc := @GetLocaleDataW
  else
    GetLocaleDataProc := @GetLocaleDataA;
  AID := StrToInt('$' + Copy(LocaleID, 5, 4));
  ShortLangName := GetLocaleDataProc(AID, LOCALE_SABBREVLANGNAME);
  if ShortLangName <> '' then
  begin
    SetLength(FSysLangs, length(FSysLangs) + 1);
    with FSysLangs[High(FSysLangs)] do
    begin
      fname := GetLocaleDataProc(AID, LOCALE_SLANGUAGE);
      FLCID := AID;
      fext := ShortLangName;
    end;
  end;
  Result := 1;
end;

constructor TLanguages.Create;
type
  TCallbackThunk = packed record
    POPEDX: Byte;
    MOVEAX: Byte;
    SelfPtr: Pointer;
    PUSHEAX: Byte;
    PUSHEDX: Byte;
    jmp: Byte;
    JmpOffset: integer;
  end;
var
  Callback                              : TCallbackThunk;
begin
  inherited Create;
  Callback.POPEDX := $5A;
  Callback.MOVEAX := $B8;
  Callback.SelfPtr := Self;
  Callback.PUSHEAX := $50;
  Callback.PUSHEDX := $52;
  Callback.jmp := $E9;
  Callback.JmpOffset := integer(@TLanguages.LocalesCallback) - integer(@Callback.jmp) - 5;
  EnumSystemLocales(TFNLocaleEnumProc(@Callback), LCID_SUPPORTED);
end;

function TLanguages.GetCount: integer;
begin
  Result := High(FSysLangs) + 1;
end;

function TLanguages.GetExt(Index: integer): string;
begin
  Result := FSysLangs[Index].fext;
end;


function TLanguages.GetLCID(Index: integer): LCID;
begin
  Result := FSysLangs[Index].FLCID;
end;

function TLanguages.GetName(Index: integer): string;
begin
  Result := FSysLangs[Index].fname;
end;

function TLanguages.GetNameFromLocaleID(ID: LCID): string;
var
  Index                                 : integer;
begin
  Index := IndexOf(ID);
  if Index <> -1 then Result := Name[Index];
  if Result = '' then Result := sUnknown;
end;

function TLanguages.GetNameFromLCID(const ID: string): string;
begin
  Result := NameFromLocaleID[StrToIntDef(ID, 0)];
end;

function TLanguages.IndexOf(ID: LCID): integer;
begin
  for Result := Low(FSysLangs) to High(FSysLangs) do
    if FSysLangs[Result].FLCID = ID then Exit;
  Result := -1;
end;

var
  FLanguages                            : TLanguages;

function Languages: TLanguages;
begin
  if FLanguages = nil then
    FLanguages := TLanguages.Create;
  Result := FLanguages;
end;

function SafeLoadLibrary(const FileName: string; ErrorMode: UINT): HMODULE;
var
  OldMode                               : UINT;
  FPUControlWord                        : Word;
begin
  OldMode := SetErrorMode(ErrorMode);
  try
    asm
      FNSTCW  FPUControlWord
    end;
    try
      Result := LoadLibrary(PChar(FileName));
    finally
      asm
        FNCLEX
        FLDCW FPUControlWord
      end;
    end;
  finally
    SetErrorMode(OldMode);
  end;
end;
{$ENDIF}

{$IFDEF MSWINDOWS}

function GetEnvironmentVariable(const Name: string): string;
var
  Len                                   : integer;
begin
  Result := '';
  Len := GetEnvironmentVariable(PChar(Name), nil, 0);
  if Len > 0 then
  begin
    SetLength(Result, Len - 1);
    GetEnvironmentVariable(PChar(Name), PChar(Result), Len);
  end;
end;
{$ENDIF}
{$IFDEF LINUX}

function GetEnvironmentVariable(const Name: string): string;
begin
  Result := getenv(PChar(Name));
end;
{$ENDIF}

{$IFDEF LINUX}

procedure CheckLocale;
var
  p, q                                  : PChar;
begin
  p := gnu_get_libc_version();
  q := getenv('LANG');
  if (q = nil) or (q[0] = #0) then
    q := getenv('LC_ALL');

   //  2.1.3 <= current version < 2.1.91
  if (strverscmp('2.1.3', p) <= 0) and
    (strverscmp(p, '2.1.91') < 0) and
    ((q = nil) or (q[0] = #0)) then
  begin
         // GNU libc 2.1.3 will segfault in towupper() if environment variables don't
         // specify a locale.  This can happen when Apache launches CGI subprocesses.
         // Solution: set a locale if the environment variable is missing.
         // Works in 2.1.2, fixed in glibc 2.1.91 and later
    setlocale(LC_ALL, 'POSIX');
  end
  else
      // Configure the process locale settings according to
      // the system environment variables (LC_CTYPE, LC_COLLATE, etc)
    setlocale(LC_ALL, '');

   // Note:
   // POSIX/C is the default locale on many Unix systems, but its 7-bit charset
   // causes char to widechar conversions to fail on any high-ascii
   // character.  To support high-ascii charset conversions, set the
   // LC_CTYPE environment variable to something else or call setlocale to set
   // the LC_CTYPE information for this process.  It doesn't matter what
   // you set it to, as long as it's not POSIX.
  if StrComp(nl_langinfo(_NL_CTYPE_CODESET_NAME), 'ANSI_X3.4-1968') = 0 then
    setlocale(LC_CTYPE, 'en_US'); // selects codepage ISO-8859-1
end;

procedure PropagateSignals;
var
  Exc                                   : TObject;
begin
   {
     If there is a current exception pending, then we're shutting down because
     it went unhandled.  If that exception is the result of a signal, then we
     need to propagate that back out to the world as a real signal death.  See
     the discussion at http://www2.cons.org/cracauer/sigint.html for more info.
   }
  Exc := ExceptObject;
  if (Exc <> nil) and (Exc is EExternal) then
    kill(getpid, EExternal(Exc).SignalNumber);
end;

{
    Under Win32, SafeCallError is implemented in ComObj.  Under Linux, we
    don't have ComObj, so we've substituted a similar mechanism here.
}

procedure SafeCallError(ErrorCode: integer; ErrorAddr: Pointer);
var
  ExcMsg                                : string;
begin
  ExcMsg := GetSafeCallExceptionMsg;
  SetSafeCallExceptionMsg('');
  if ExcMsg <> '' then
  begin
    raise ESafeCallException.Create(ExcMsg)at GetSafeCallExceptionAddr;
  end
  else
    raise ESafeCallException.Create(SSafecallException);
end;
{$ENDIF}

initialization
  if ModuleIsCpp then HexDisplayPrefix := '0x';
  InitExceptions;

{$IFDEF LINUX}
  SafeCallErrorProc := @SafeCallError;
  ExitProcessProc := PropagateSignals;

  CheckLocale;
{$ENDIF}

{$IFDEF MSWINDOWS}
  InitPlatformId;
  InitDriveSpacePtr;
{$ENDIF}
  GetFormatSettings; { Win implementation uses platform id }

finalization
{$IFDEF MSWINDOWS}
  FreeAndNil(FLanguages);
{$ENDIF}
{$IFDEF LINUX}
  if libuuidHandle <> nil then
    dlclose(libuuidHandle);
{$ENDIF}
  FreeTerminateProcs;
  DoneExceptions;

end.

