unit uComObj;

interface

uses //uVariants,
  Windows,
  ActiveX;


type
  TAnyProc = procedure (var V: TVarData);
  TVarDispProc = procedure (Dest: PVariant; const Source: Variant;
      CallDesc: PCallDesc; Params: Pointer); cdecl;

var
  VarDispProc: TVarDispProc;

type
  { Forward declarations }

  { COM server abstract base class }

  TComServerObject = class(TObject)
  PROTECTED
    function CountObject(Created: boolean): integer; VIRTUAL; ABSTRACT;
    function CountFactory(Created: boolean): integer; VIRTUAL; ABSTRACT;
    function GetHelpFileName: string; VIRTUAL; ABSTRACT;
    function GetServerFileName: string; VIRTUAL; ABSTRACT;
    function GetServerKey: string; VIRTUAL; ABSTRACT;
    function GetServerName: string; VIRTUAL; ABSTRACT;
    function GetStartSuspended: boolean; VIRTUAL; ABSTRACT;
    function GetTypeLib: ITypeLib; VIRTUAL; ABSTRACT;
    procedure SetHelpFileName(const Value: string); VIRTUAL; ABSTRACT;
  PUBLIC
    property HelpFileName: string READ GetHelpFileName WRITE SetHelpFileName;
    property ServerFileName: string READ GetServerFileName;
    property ServerKey: string READ GetServerKey;
    property ServerName: string READ GetServerName;
    property TypeLib: ITypeLib READ GetTypeLib;
    property StartSuspended: boolean READ GetStartSuspended;
  end;

  { COM class manager }

  { IServerExceptionHandler }
  { This interface allows you to report safecall exceptions that occur in a
    TComObject server to a third party, such as an object that logs errors into
    the system event log or a server monitor residing on another machine.
    Obtain an interface from the error logger implementation and assign it
    to your TComObject's ServerExceptionHandler property.  Each TComObject
    instance can have its own server exception handler, or all instances can
    share the same handler.  The server exception handler can override the
    TComObject's default exception handling by setting Handled to True and
    assigning an OLE HResult code to the HResult parameter.
  }

  IServerExceptionHandler = interface
    ['{6A8D432B-EB81-11D1-AAB1-00C04FB16FBC}']
    procedure OnException(
      const ServerClass, ExceptionClass, ErrorMessage: WideString;
      ExceptAddr: integer; const ErrorIID, ProgID: WideString;
      var Handled: integer; var Result: HResult); DISPID 2;
  end;

  { Instancing mode for COM classes }

  TClassInstancing = (ciInternal, ciSingleInstance, ciMultiInstance);

  { Threading model supported by COM classes }

  TThreadingModel = (tmSingle, tmApartment, tmFree, tmBoth, tmNeutral);

  { NOTE: TAggregatedObject and TContainedObject have been moved to system. }

{ OLE Automation object }

  TConnectEvent = procedure(const Sink: IUnknown; Connecting: boolean) of object;
{$EXTERNALSYM TConnectEvent}

  { OLE Automation class }

  { OLE Automation object factory }

  TAutoIntfObject = class(TInterfacedObject, IDispatch, ISupportErrorInfo)
  PRIVATE
    FDispTypeInfo: ITypeInfo;
    FDispIntfEntry: PInterfaceEntry;
    FDispIID: TGUID;
  PROTECTED
    { IDispatch }
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: integer; DispIDs: Pointer): HResult; STDCALL;
    function GetTypeInfo(Index, LocaleID: integer; out TypeInfo): HResult; STDCALL;
    function GetTypeInfoCount(out Count: integer): HResult; STDCALL;
    function invoke(DispID: integer; const IID: TGUID; LocaleID: integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; STDCALL;
    { ISupportErrorInfo }
    function InterfaceSupportsErrorInfo(const IID: TIID): HResult; STDCALL;
  PUBLIC
    constructor Create(const TypeLib: ITypeLib; const DispIntf: TGUID);
{$IFDEF MSWINDOWS}
    function SafeCallException(ExceptObject: TObject;
      ExceptAddr: Pointer): HResult; OVERRIDE;
{$ENDIF}
    property DispIntfEntry: PInterfaceEntry READ FDispIntfEntry;
    property DispTypeInfo: ITypeInfo READ FDispTypeInfo;
    property DispIID: TGUID READ FDispIID;
  end;

  { OLE exception classes }
  {
    EOleError = class(Exception);

    EOleSysError = class(EOleError)
    private
      FErrorCode: HRESULT;
    public
      constructor Create(const Message: string; ErrorCode: HRESULT;
        HelpContext: Integer);
      property ErrorCode: HRESULT read FErrorCode write FErrorCode;
    end;

    EOleException = class(EOleSysError)
    private
      FSource: string;
      FHelpFile: string;
    public
      constructor Create(const Message: string; ErrorCode: HRESULT;
        const Source, HelpFile: string; HelpContext: Integer);
      property HelpFile: string read FHelpFile write FHelpFile;
      property Source: string read FSource write FSource;
    end;

    EOleRegistrationError = class(EOleError);
  }
procedure DispatchInvoke(const Dispatch: IDispatch; CallDesc: PCallDesc;
  DispIDs: PDispIDList; Params: Pointer; Result: PVariant);
procedure DispatchInvokeError(Status: integer; const ExcepInfo: TExcepInfo);

function HandleSafeCallException(ExceptObject: TObject;
  ExceptAddr: Pointer; const ErrorIID: TGUID; const ProgID,
  HelpFileName: WideString): HResult;

function CreateComObject(const ClassID: TGUID): IUnknown;
function CreateRemoteComObject(const MachineName: WideString; const ClassID: TGUID): IUnknown;
function CreateOleObject(const ClassName: string): IDispatch;
function GetActiveOleObject(const ClassName: string): IDispatch;

//procedure OleError(ErrorCode: HResult);
procedure OleCheck(Result: HResult);

function StringToGUID(const s: string): TGUID;
function GUIDToString(const ClassID: TGUID): string;

function ProgIDToClassID(const ProgID: string): TGUID;
function ClassIDToProgID(const ClassID: TGUID): string;

procedure CreateRegKey(const Key, ValueName, Value: string; RootKey: DWORD = HKEY_CLASSES_ROOT);
procedure DeleteRegKey(const Key: string; RootKey: DWORD = HKEY_CLASSES_ROOT);
function GetRegStringValue(const Key, ValueName: string; RootKey: DWORD = HKEY_CLASSES_ROOT): string;

function StringToLPOLESTR(const Source: string): POleStr;

procedure RegisterComServer(const DLLName: string);
procedure RegisterAsService(const ClassID, ServiceName: string);

function CreateClassID: string;

procedure InterfaceConnect(const Source: IUnknown; const IID: TIID;
  const Sink: IUnknown; var Connection: LONGINT);
procedure InterfaceDisconnect(const Source: IUnknown; const IID: TIID;
  var Connection: LONGINT);

function GetDispatchPropValue(Disp: IDispatch; DispID: integer): OleVariant; overload;
function GetDispatchPropValue(Disp: IDispatch; Name: WideString): OleVariant; overload;
procedure SetDispatchPropValue(Disp: IDispatch; DispID: integer;
  const Value: OleVariant); overload;
procedure SetDispatchPropValue(Disp: IDispatch; Name: WideString;
  const Value: OleVariant); overload;

type
  TCoCreateInstanceExProc = function(const clsid: TCLSID;
    unkOuter: IUnknown; dwClsCtx: LONGINT; ServerInfo: PCoServerInfo;
    dwCount: LONGINT; rgmqResults: PMultiQIArray): HResult STDCALL;
{$EXTERNALSYM TCoCreateInstanceExProc}
  TCoInitializeExProc = function(pvReserved: Pointer;
    coInit: LONGINT): HResult; stdcall;
{$EXTERNALSYM TCoInitializeExProc}
  TCoAddRefServerProcessProc = function: LONGINT; stdcall;
{$EXTERNALSYM TCoAddRefServerProcessProc}
  TCoReleaseServerProcessProc = function: LONGINT; stdcall;
{$EXTERNALSYM TCoReleaseServerProcessProc}
  TCoResumeClassObjectsProc = function: HResult; stdcall;
{$EXTERNALSYM TCoResumeClassObjectsProc}
  TCoSuspendClassObjectsProc = function: HResult; stdcall;
{$EXTERNALSYM TCoSuspendClassObjectsProc}

  // COM functions that are only available on DCOM updated OSs
  // These pointers may be nil on Win95 or Win NT 3.51 systems
var
  CoCreateInstanceEx               : TCoCreateInstanceExProc = nil;
{$EXTERNALSYM CoCreateInstanceEx}
  CoInitializeEx                   : TCoInitializeExProc = nil;
{$EXTERNALSYM CoInitializeEx}
  CoAddRefServerProcess            : TCoAddRefServerProcessProc = nil;
{$EXTERNALSYM CoAddRefServerProcess}
  CoReleaseServerProcess           : TCoReleaseServerProcessProc = nil;
{$EXTERNALSYM CoReleaseServerProcess}
  CoResumeClassObjects             : TCoResumeClassObjectsProc = nil;
{$EXTERNALSYM CoResumeClassObjects}
  CoSuspendClassObjects            : TCoSuspendClassObjectsProc = nil;
{$EXTERNALSYM CoSuspendClassObjects}

  { CoInitFlags determines the COM threading model of the application or current
    thread. This bitflag value is passed to CoInitializeEx in ComServ initialization.
    Assign COINIT_APARTMENTTHREADED or COINIT_MULTITHREADED to this variable before
    Application.Initialize is called by the project source file to select a
    threading model.  Other CoInitializeEx flags (such as COINIT_SPEED_OVER_MEMORY)
    can be OR'd in also.  }
var
  CoInitFlags                      : integer = -1; // defaults to no threading model, call CoInitialize()

function StrLen(const Str: PChar): Cardinal; assembler;
implementation

uses ComConst;

var
  OleUninitializing                : boolean;

  { Handle a safe call exception }

function HandleSafeCallException(ExceptObject: TObject;
  ExceptAddr: Pointer; const ErrorIID: TGUID; const ProgID,
  HelpFileName: WideString): HResult;
var
  E                                : TObject;
  CreateError                      : ICreateErrorInfo;
  ErrorInfo                        : IErrorInfo;
begin
  Result := E_UNEXPECTED;
  E := ExceptObject;
  if Succeeded(CreateErrorInfo(CreateError)) then
    begin
      CreateError.SetGUID(ErrorIID);
      if ProgID <> '' then CreateError.SetSource(PWideChar(ProgID));
      if HelpFileName <> '' then CreateError.SetHelpFile(PWideChar(HelpFileName));
      {
          if E is Exception then
          begin
            CreateError.SetDescription(PWideChar(WideString(Exception(E).Message)));
            CreateError.SetHelpContext(Exception(E).HelpContext);
            if (E is EOleSysError) and (EOleSysError(E).ErrorCode < 0) then
              Result := EOleSysError(E).ErrorCode;
          end;
      }
      if CreateError.QueryInterface(IErrorInfo, ErrorInfo) = S_OK then
        SetErrorInfo(0, ErrorInfo);
    end;
end;

{ TDispatchSilencer }

type
  TDispatchSilencer = class(TInterfacedObject, IUnknown, IDispatch)
  PRIVATE
    Dispatch: IDispatch;
    DispIntfIID: TGUID;
  PUBLIC
    constructor Create(ADispatch: IUnknown; const ADispIntfIID: TGUID);
    { IUnknown }
    function QueryInterface(const IID: TGUID; out obj): HResult; STDCALL;
    { IDispatch }
    function GetTypeInfoCount(out Count: integer): HResult; STDCALL;
    function GetTypeInfo(Index, LocaleID: integer; out TypeInfo): HResult; STDCALL;
    function GetIDsOfNames(const IID: TGUID; Names: Pointer;
      NameCount, LocaleID: integer; DispIDs: Pointer): HResult; STDCALL;
    function invoke(DispID: integer; const IID: TGUID; LocaleID: integer;
      Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult; STDCALL;
  end;

constructor TDispatchSilencer.Create(ADispatch: IUnknown;
  const ADispIntfIID: TGUID);
begin
  inherited Create;
  DispIntfIID := ADispIntfIID;
  OleCheck(ADispatch.QueryInterface(ADispIntfIID, Dispatch));
end;

function TDispatchSilencer.QueryInterface(const IID: TGUID; out obj): HResult;
begin
  Result := inherited QueryInterface(IID, obj);
  if Result = E_NOINTERFACE then
    if IsEqualGUID(IID, DispIntfIID) then
      begin
        IDispatch(obj) := Self;
        Result := S_OK;
      end
    else
      Result := Dispatch.QueryInterface(IID, obj);
end;

function TDispatchSilencer.GetTypeInfoCount(out Count: integer): HResult;
begin
  Result := Dispatch.GetTypeInfoCount(Count);
end;

function TDispatchSilencer.GetTypeInfo(Index, LocaleID: integer; out TypeInfo): HResult;
begin
  Result := Dispatch.GetTypeInfo(Index, LocaleID, TypeInfo);
end;

function TDispatchSilencer.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: integer; DispIDs: Pointer): HResult;
begin
  Result := Dispatch.GetIDsOfNames(IID, Names, NameCount, LocaleID, DispIDs);
end;

function TDispatchSilencer.invoke(DispID: integer; const IID: TGUID; LocaleID: integer;
  Flags: Word; var Params; VarResult, ExcepInfo, ArgErr: Pointer): HResult;
begin
  { Ignore error since some containers, such as Internet Explorer 3.0x, will
    return error when the method was not handled, or scripting errors occur }
  Dispatch.invoke(DispID, IID, LocaleID, Flags, Params, VarResult, ExcepInfo,
    ArgErr);
  Result := S_OK;
end;

{ TComObject }

{ TAutoIntfObject }

constructor TAutoIntfObject.Create(const TypeLib: ITypeLib; const DispIntf: TGUID);
begin
  inherited Create;
  OleCheck(TypeLib.GetTypeInfoOfGuid(DispIntf, FDispTypeInfo));
  FDispIntfEntry := GetInterfaceEntry(DispIntf);
end;

{ TAutoIntfObject.IDispatch }

function TAutoIntfObject.GetIDsOfNames(const IID: TGUID; Names: Pointer;
  NameCount, LocaleID: integer; DispIDs: Pointer): HResult;
begin
{$IFDEF MSWINDOWS}
  Result := DispGetIDsOfNames(FDispTypeInfo, Names, NameCount, DispIDs);
{$ENDIF}
{$IFDEF LINUX}
  Result := E_NOTIMPL;
{$ENDIF}
end;

function TAutoIntfObject.GetTypeInfo(Index, LocaleID: integer;
  out TypeInfo): HResult;
begin
  Pointer(TypeInfo) := nil;
  if Index <> 0 then
    begin
      Result := DISP_E_BADINDEX;
      Exit;
    end;
  ITypeInfo(TypeInfo) := FDispTypeInfo;
  Result := S_OK;
end;

function TAutoIntfObject.GetTypeInfoCount(out Count: integer): HResult;
begin
  Count := 1;
  Result := S_OK;
end;

function TAutoIntfObject.invoke(DispID: integer; const IID: TGUID;
  LocaleID: integer; Flags: Word; var Params; VarResult, ExcepInfo,
  ArgErr: Pointer): HResult;
const
  INVOKE_PROPERTYSET               = INVOKE_PROPERTYPUT or INVOKE_PROPERTYPUTREF;
begin
  if Flags and INVOKE_PROPERTYSET <> 0 then Flags := INVOKE_PROPERTYSET;
  Result := FDispTypeInfo.invoke(Pointer(integer(Self) +
    FDispIntfEntry.IOffset), DispID, Flags, TDispParams(Params), VarResult,
    ExcepInfo, ArgErr);
end;

function TAutoIntfObject.InterfaceSupportsErrorInfo(const IID: TIID): HResult;
begin
  if IsEqualGUID(DispIID, IID) then
    Result := S_OK else
    Result := S_FALSE;
end;

{$IFDEF MSWINDOWS}

function TAutoIntfObject.SafeCallException(ExceptObject: TObject;
  ExceptAddr: Pointer): HResult;
begin
  Result := HandleSafeCallException(ExceptObject, ExceptAddr, DispIID, '', '');
end;
{$ENDIF}

const
  { Maximum number of dispatch arguments }

  MaxDispArgs                      = 64; {!!!}

  { Special variant type codes }

  varStrArg                        = $0048;

  { Parameter type masks }

  atVarMask                        = $3F;
  atTypeMask                       = $7F;
  atByRef                          = $80;

function TrimPunctuation(const s: string): string;
var
  p                                : PChar;
begin
  {
    Result := S;
    P := AnsiLastChar(Result);
    while (Length(Result) > 0) and (P^ in [#0..#32, '.']) do
    begin
      SetLength(Result, P - PChar(Result));
      P := AnsiLastChar(Result);
    end;
  }
end;

{ EOleSysError }
{
constructor EOleSysError.Create(const Message: string;
  ErrorCode: HRESULT; HelpContext: Integer);
var
  S: string;
begin
  S := Message;
  if S = '' then
  begin
    S := SysErrorMessage(ErrorCode);
    if S = '' then FmtStr(S, SOleError, [ErrorCode]);
  end;
  inherited CreateHelp(S, HelpContext);
  FErrorCode := ErrorCode;
end;
}
{ EOleException }
{
constructor EOleException.Create(const Message: string; ErrorCode: HRESULT;
  const Source, HelpFile: string; HelpContext: Integer);
begin
  inherited Create(TrimPunctuation(Message), ErrorCode, HelpContext);
  FSource := Source;
  FHelpFile := HelpFile;
end;
}

{ Raise EOleSysError exception from an error code }
{
procedure OleError(ErrorCode: HResult);
begin
  raise EOleSysError.Create('', ErrorCode, 0);
end;
}
{ Raise EOleSysError exception if result code indicates an error }

procedure OleCheck(Result: HResult);
begin
  if not Succeeded(Result) then //OleError(Result);
end;

{ Convert a string to a GUID }

function StringToGUID(const s: string): TGUID;
begin
  OleCheck(CLSIDFromString(PWideChar(WideString(s)), Result));
end;

{ Convert a GUID to a string }

function GUIDToString(const ClassID: TGUID): string;
var
  p                                : PWideChar;
begin
  OleCheck(StringFromCLSID(ClassID, p));
  Result := p;
  CoTaskMemFree(p);
end;

{ Convert a programmatic ID to a class ID }

function ProgIDToClassID(const ProgID: string): TGUID;
begin
  OleCheck(CLSIDFromProgID(PWideChar(WideString(ProgID)), Result));
end;

{ Convert a class ID to a programmatic ID }

function ClassIDToProgID(const ClassID: TGUID): string;
var
  p                                : PWideChar;
begin
  OleCheck(ProgIDFromCLSID(ClassID, p));
  Result := p;
  CoTaskMemFree(p);
end;

{ Create registry key }

procedure CreateRegKey(const Key, ValueName, Value: string; RootKey: DWORD = HKEY_CLASSES_ROOT);
var
  Handle                           : hkey;
  Status, Disposition              : integer;
begin
  Status := RegCreateKeyEx(RootKey, PChar(Key), 0, '',
    REG_OPTION_NON_VOLATILE, KEY_READ or KEY_WRITE, nil, Handle,
    @Disposition);
  if Status = 0 then
    begin
      Status := RegSetValueEx(Handle, PChar(ValueName), 0, REG_SZ,
        PChar(Value), length(Value) + 1);
      RegCloseKey(Handle);
    end;
  //  if Status <> 0 then raise EOleRegistrationError.CreateRes(@SCreateRegKeyError);
end;

{ Delete registry key }

procedure DeleteRegKey(const Key: string; RootKey: DWORD = HKEY_CLASSES_ROOT);
begin
  RegDeleteKey(RootKey, PChar(Key));
end;

{ Get registry value }

function GetRegStringValue(const Key, ValueName: string; RootKey: DWORD = HKEY_CLASSES_ROOT): string;
var
  Size                             : DWORD;
  RegKey                           : hkey;
begin
  Result := '';
  if RegOpenKey(RootKey, PChar(Key), RegKey) = ERROR_SUCCESS then
  try
    Size := 256;
    SetLength(Result, Size);
    if RegQueryValueEx(RegKey, PChar(ValueName), nil, nil, PByte(PChar(Result)), @Size) = ERROR_SUCCESS then
      SetLength(Result, Size - 1) else
      Result := '';
  finally
    RegCloseKey(RegKey);
  end;
end;

function CreateComObject(const ClassID: TGUID): IUnknown;
begin
  OleCheck(CoCreateInstance(ClassID, nil, CLSCTX_INPROC_SERVER or
    CLSCTX_LOCAL_SERVER, IUnknown, Result));
end;

function CreateRemoteComObject(const MachineName: WideString;
  const ClassID: TGUID): IUnknown;
const
  LocalFlags                       = CLSCTX_LOCAL_SERVER or CLSCTX_REMOTE_SERVER or CLSCTX_INPROC_SERVER;
  RemoteFlags                      = CLSCTX_REMOTE_SERVER;
var
  MQI                              : TMultiQI;
  ServerInfo                       : TCoServerInfo;
  IID_IUnknown                     : TGUID;
  Flags, Size                      : DWORD;
  LocalMachine                     : array[0..MAX_COMPUTERNAME_LENGTH] of Char;
begin
  //  if @CoCreateInstanceEx = nil then    raise Exception.CreateRes(@SDCOMNotInstalled);
  FillChar(ServerInfo, SizeOf(ServerInfo), 0);
  ServerInfo.pwszName := PWideChar(MachineName);
  IID_IUnknown := IUnknown;
  MQI.IID := @IID_IUnknown;
  MQI.itf := nil;
  MQI.hr := 0;
  { If a MachineName is specified check to see if it the local machine.
    If it isn't, do not allow LocalServers to be used. }
{
  if Length(MachineName) > 0 then
  begin

    Size := Sizeof(LocalMachine);  // Win95 is hypersensitive to size
    if GetComputerName(LocalMachine, Size) and
       (AnsiCompareText(LocalMachine, MachineName) = 0) then
      Flags := LocalFlags else
      Flags := RemoteFlags;
  end else
    Flags := LocalFlags;
}
  OleCheck(CoCreateInstanceEx(ClassID, nil, Flags, @ServerInfo, 1, @MQI));
  OleCheck(MQI.hr);
  Result := MQI.itf;
end;

function CreateOleObject(const ClassName: string): IDispatch;
var
  ClassID                          : TCLSID;
begin
  ClassID := ProgIDToClassID(ClassName);
  OleCheck(CoCreateInstance(ClassID, nil, CLSCTX_INPROC_SERVER or
    CLSCTX_LOCAL_SERVER, IDispatch, Result));
end;

function GetActiveOleObject(const ClassName: string): IDispatch;
var
  ClassID                          : TCLSID;
  Unknown                          : IUnknown;
begin
  ClassID := ProgIDToClassID(ClassName);
  OleCheck(GetActiveObject(ClassID, nil, Unknown));
  OleCheck(Unknown.QueryInterface(IDispatch, Result));
end;

function StringToLPOLESTR(const Source: string): POleStr;
var
  SourceLen                        : integer;
  Buffer                           : PWideChar;
begin
  SourceLen := length(Source);
  Buffer := CoTaskMemAlloc((SourceLen + 1) * SizeOf(widechar));
  StringToWideChar(Source, Buffer, SourceLen + 1);
  Result := POleStr(Buffer);
end;

function CreateClassID: string;
var
  ClassID                          : TCLSID;
  p                                : PWideChar;
begin
  CoCreateGuid(ClassID);
  StringFromCLSID(ClassID, p);
  Result := p;
  CoTaskMemFree(p);
end;

procedure RegisterComServer(const DLLName: string);
type
  TRegProc = function: HResult; stdcall;
const
  RegProcName                      = 'DllRegisterServer'; { Do not localize }
var
  Handle                           : THandle;
  RegProc                          : TRegProc;
begin
  {
    Handle := SafeLoadLibrary(DLLName);
    if Handle <= HINSTANCE_ERROR then
      raise Exception.CreateFmt('%s: %s', [SysErrorMessage(GetLastError), DLLName]);
    try
      RegProc := GetProcAddress(Handle, RegProcName);
      if Assigned(RegProc) then OleCheck(RegProc) else RaiseLastOSError;
    finally
      FreeLibrary(Handle);
    end;
  }
end;

procedure RegisterAsService(const ClassID, ServiceName: string);
begin
  CreateRegKey('AppID\' + ClassID, 'LocalService', ServiceName);
  CreateRegKey('CLSID\' + ClassID, 'AppID', ClassID);
end;

{ Connect an IConnectionPoint interface }

procedure InterfaceConnect(const Source: IUnknown; const IID: TIID;
  const Sink: IUnknown; var Connection: LONGINT);
var
  CPC                              : IConnectionPointContainer;
  cp                               : IConnectionPoint;
begin
  Connection := 0;
  if Succeeded(Source.QueryInterface(IConnectionPointContainer, CPC)) then
    if Succeeded(CPC.FindConnectionPoint(IID, cp)) then
      cp.Advise(Sink, Connection);
end;

{ Disconnect an IConnectionPoint interface }

procedure InterfaceDisconnect(const Source: IUnknown; const IID: TIID;
  var Connection: LONGINT);
var
  CPC                              : IConnectionPointContainer;
  cp                               : IConnectionPoint;
begin
  if Connection <> 0 then
    if Succeeded(Source.QueryInterface(IConnectionPointContainer, CPC)) then
      if Succeeded(CPC.FindConnectionPoint(IID, cp)) then
        if Succeeded(cp.Unadvise(Connection)) then Connection := 0;
end;

procedure LoadComExProcs;
var
  ole32                            : HMODULE;
begin
  ole32 := Windows.GetModuleHandle('ole32.dll');
  if ole32 <> 0 then
    begin
      @CoCreateInstanceEx := Windows.GetProcAddress(ole32, 'CoCreateInstanceEx');
      @CoInitializeEx := Windows.GetProcAddress(ole32, 'CoInitializeEx');
      @CoAddRefServerProcess := Windows.GetProcAddress(ole32, 'CoAddRefServerProcess');
      @CoReleaseServerProcess := Windows.GetProcAddress(ole32, 'CoReleaseServerProcess');
      @CoResumeClassObjects := Windows.GetProcAddress(ole32, 'CoResumeClassObjects');
      @CoSuspendClassObjects := Windows.GetProcAddress(ole32, 'CoSuspendClassObjects');
    end;
end;

{$IFDEF MSWINDOWS}

procedure SafeCallError(ErrorCode: integer; ErrorAddr: Pointer);
var
  ErrorInfo                        : IErrorInfo;
  Source, Description, HelpFile    : WideString;
  HelpContext                      : LONGINT;
begin
  HelpContext := 0;
  if GetErrorInfo(0, ErrorInfo) = S_OK then
    begin
      ErrorInfo.GetSource(Source);
      ErrorInfo.GetDescription(Description);
      ErrorInfo.GetHelpFile(HelpFile);
      ErrorInfo.GetHelpContext(HelpContext);
    end;
  //  raise EOleException.Create(Description, ErrorCode, Source,    HelpFile, HelpContext) at ErrorAddr;
end;
{$ENDIF}

{ Call Invoke method on the given IDispatch interface using the given
  call descriptor, dispatch IDs, parameters, and result }

procedure DispatchInvoke(const Dispatch: IDispatch; CallDesc: PCallDesc;
  DispIDs: PDispIDList; Params: Pointer; Result: PVariant);
type
  PVarArg = ^TVarArg;
  TVarArg = array[0..3] of DWORD;
  TStringDesc = record
    BStr: PWideChar;
    PStr: pSTRING;
  end;
var
  I, J, k, ArgType, ArgCount, StrCount, DispID, InvKind, Status: integer;
  VarFlag                          : Byte;
  ParamPtr                         : ^integer;
  ArgPtr, VarPtr                   : PVarArg;
  DispParams                       : TDispParams;
  ExcepInfo                        : TExcepInfo;
  Strings                          : array[0..MaxDispArgs - 1] of TStringDesc;
  Args                             : array[0..MaxDispArgs - 1] of TVarArg;
begin
  StrCount := 0;
  try
    ArgCount := CallDesc^.ArgCount;
    //    if ArgCount > MaxDispArgs then raise EOleException.CreateRes(@STooManyParams);
    if ArgCount <> 0 then
      begin
        ParamPtr := Params;
        ArgPtr := @Args[ArgCount];
        I := 0;
        repeat
          Dec(integer(ArgPtr), SizeOf(TVarData));
          ArgType := CallDesc^.ArgTypes[I] and atTypeMask;
          VarFlag := CallDesc^.ArgTypes[I] and atByRef;
          if ArgType = varError then
            begin
              ArgPtr^[0] := varError;
              ArgPtr^[2] := DWORD(DISP_E_PARAMNOTFOUND);
            end
          else
            begin
              if ArgType = varStrArg then
                begin
                  with Strings[StrCount] do
                    if VarFlag <> 0 then
                      begin
                        BStr := StringToOleStr(pSTRING(ParamPtr^)^);
                        PStr := pSTRING(ParamPtr^);
                        ArgPtr^[0] := varOleStr or varByRef;
                        ArgPtr^[2] := integer(@BStr);
                      end
                    else
                      begin
                        BStr := StringToOleStr(pSTRING(ParamPtr)^);
                        PStr := nil;
                        ArgPtr^[0] := varOleStr;
                        ArgPtr^[2] := integer(BStr);
                      end;
                  inc(StrCount);
                end

              else if VarFlag <> 0 then
                begin
                  if (ArgType = varVariant) and
                    (PVarData(ParamPtr^)^.VType = varString) then
                    VarCast(PVariant(ParamPtr^)^, PVariant(ParamPtr^)^, varOleStr);

                  ArgPtr^[0] := ArgType or varByRef;
                  ArgPtr^[2] := ParamPtr^;
                end

              else if ArgType = varVariant then
                begin
                  if PVarData(ParamPtr)^.VType = varString then
                    begin
                      with Strings[StrCount] do
                        begin
                          BStr := StringToOleStr(string(PVarData(ParamPtr^)^.VString));
                          PStr := nil;
                          ArgPtr^[0] := varOleStr;
                          ArgPtr^[2] := integer(BStr);
                        end;
                      inc(StrCount);
                    end
                  else
                    begin
                      VarPtr := PVarArg(ParamPtr);
                      ArgPtr^[0] := VarPtr^[0];
                      ArgPtr^[1] := VarPtr^[1];
                      ArgPtr^[2] := VarPtr^[2];
                      ArgPtr^[3] := VarPtr^[3];
                      inc(integer(ParamPtr), 12);
                    end;
                end

              else
                begin
                  ArgPtr^[0] := ArgType;
                  ArgPtr^[2] := ParamPtr^;
                  if (ArgType >= varDouble) and (ArgType <= varDate) then
                    begin
                      inc(integer(ParamPtr), 4);
                      ArgPtr^[3] := ParamPtr^;
                    end;
                end;
              inc(integer(ParamPtr), 4);
            end;
          inc(I);
        until I = ArgCount;
      end;
    DispParams.rgvarg := @Args;
    DispParams.rgdispidNamedArgs := @DispIDs[1];
    DispParams.cArgs := ArgCount;
    DispParams.cNamedArgs := CallDesc^.NamedArgCount;
    DispID := DispIDs[0];
    InvKind := CallDesc^.CallType;
    if InvKind = DISPATCH_PROPERTYPUT then
      begin
        if Args[0][0] and varTypeMask = varDispatch then
          InvKind := DISPATCH_PROPERTYPUTREF;
        DispIDs[0] := DISPID_PROPERTYPUT;
        Dec(integer(DispParams.rgdispidNamedArgs), SizeOf(integer));
        inc(DispParams.cNamedArgs);
      end else
      if (InvKind = DISPATCH_METHOD) and (ArgCount = 0) and (Result <> nil) then
        InvKind := DISPATCH_METHOD or DISPATCH_PROPERTYGET;
    Status := Dispatch.invoke(DispID, GUID_NULL, 0, InvKind, DispParams,
      Result, @ExcepInfo, nil);
    if Status <> 0 then DispatchInvokeError(Status, ExcepInfo);
    J := StrCount;
    while J <> 0 do
      begin
        Dec(J);
        with Strings[J] do
          if PStr <> nil then OleStrToStrVar(BStr, PStr^);
      end;
  finally
    k := StrCount;
    while k <> 0 do
      begin
        Dec(k);
        SysFreeString(Strings[k].BStr);
      end;
  end;
end;

{ Call GetIDsOfNames method on the given IDispatch interface }

procedure GetIDsOfNames(const Dispatch: IDispatch; Names: PChar;
  NameCount: integer; DispIDs: PDispIDList);

  procedure RaiseNameException;
  begin
    //    raise EOleError.CreateResFmt(@SNoMethod, [Names]);
  end;

type
  PNamesArray = ^TNamesArray;
  TNamesArray = array[0..0] of PWideChar;
var
  n, SrcLen, DestLen               : integer;
  Src                              : PChar;
  Dest                             : PWideChar;
  NameRefs                         : PNamesArray;
  StackTop                         : Pointer;
  temp                             : integer;
begin
  Src := Names;
  n := 0;
  asm
    MOV  StackTop, ESP
    MOV  EAX, NameCount
    INC  EAX
    SHL  EAX, 2  // sizeof pointer = 4
    SUB  ESP, EAX
    LEA  EAX, NameRefs
    MOV  [EAX], ESP
  end;
  repeat
    SrcLen := StrLen(Src);
    DestLen := MultiByteToWideChar(0, 0, Src, SrcLen, nil, 0) + 1;
    asm
      MOV  EAX, DestLen
      ADD  EAX, EAX
      ADD  EAX, 3      // round up to 4 byte boundary
      AND  EAX, not 3
      SUB  ESP, EAX
      LEA  EAX, Dest
      MOV  [EAX], ESP
    end;
    if n = 0 then NameRefs[0] := Dest else NameRefs[NameCount - n] := Dest;
    MultiByteToWideChar(0, 0, Src, SrcLen, Dest, DestLen);
    Dest[DestLen - 1] := #0;
    inc(Src, SrcLen + 1);
    inc(n);
  until n = NameCount;
  temp := Dispatch.GetIDsOfNames(GUID_NULL, NameRefs, NameCount,
    GetThreadLocale, DispIDs);
  if temp = integer(DISP_E_UNKNOWNNAME) then RaiseNameException else OleCheck(temp);
  asm
    MOV  ESP, StackTop
  end;
end;

{ Central call dispatcher }

procedure VarDispInvoke(Result: PVariant; const Instance: Variant;
  CallDesc: PCallDesc; Params: Pointer); CDECL;

  procedure RaiseException;
  begin
    //    raise EOleError.CreateRes(@SVarNotObject);
  end;

var
  Dispatch                         : Pointer;
  DispIDs                          : array[0..MaxDispArgs - 1] of integer;
begin
  //  if (CallDesc^.ArgCount) > MaxDispArgs then raise EOleError.CreateRes(@STooManyParams);
  if TVarData(Instance).VType = varDispatch then
    Dispatch := TVarData(Instance).VDispatch
  else if TVarData(Instance).VType = (varDispatch or varByRef) then
    Dispatch := Pointer(TVarData(Instance).VPointer^)
  else RaiseException;
  GetIDsOfNames(IDispatch(Dispatch), @CallDesc^.ArgTypes[CallDesc^.ArgCount],
    CallDesc^.NamedArgCount + 1, @DispIDs);
  if Result <> nil then VarClear(Result^);
  DispatchInvoke(IDispatch(Dispatch), CallDesc, @DispIDs, Params, Result);
end;

{ Raise exception given an OLE return code and TExcepInfo structure }

procedure DispCallError(Status: integer; var ExcepInfo: TExcepInfo;
  ErrorAddr: Pointer; FinalizeExcepInfo: boolean);
//var
//  E: Exception;
begin
  {
    if Status = Integer(DISP_E_EXCEPTION) then
    begin
  //    with ExcepInfo do      E := EOleException.Create(bstrDescription, scode, bstrSource,        bstrHelpFile, dwHelpContext);
      if FinalizeExcepInfo then
        Finalize(ExcepInfo);
    end else
    begin
  //    E := EOleSysError.Create('', Status, 0);
      end;
    if ErrorAddr <> nil then
      raise E at ErrorAddr
    else
      raise E;
  }
end;

{ Raise exception given an OLE return code and TExcepInfo structure }

procedure DispatchInvokeError(Status: integer; const ExcepInfo: TExcepInfo);
begin
  DispCallError(Status, PExcepInfo(@ExcepInfo)^, nil, False);
end;

procedure ClearExcepInfo(var ExcepInfo: TExcepInfo);
begin
  FillChar(ExcepInfo, SizeOf(ExcepInfo), 0);
end;

procedure DispCall(const Dispatch: IDispatch; CallDesc: PCallDesc;
  DispID: integer; NamedArgDispIDs, Params, Result: Pointer); STDCALL;
type
  TExcepInfoRec = record // mock type to avoid auto init and cleanup code
    wCode: Word;
    wReserved: Word;
    bstrSource: PWideChar;
    bstrDescription: PWideChar;
    bstrHelpFile: PWideChar;
    dwHelpContext: LONGINT;
    pvReserved: Pointer;
    pfnDeferredFillIn: Pointer;
    scode: HResult;
  end;
var
  DispParams                       : TDispParams;
  ExcepInfo                        : TExcepInfoRec;
asm
        PUSH    EBX
        PUSH    ESI
        PUSH    EDI
        MOV     EBX,CallDesc
        XOR     EDX,EDX
        MOV     EDI,ESP
        MOVZX   ECX,[EBX].TCallDesc.ArgCount
        MOV     DispParams.cArgs,ECX
        TEST    ECX,ECX
        JE      @@10
        ADD     EBX,OFFSET TCallDesc.ArgTypes
        MOV     ESI,Params
@@1:    MOVZX   EAX,[EBX].Byte
        TEST    AL,atByRef
        JNE     @@3
        CMP     AL,varVariant
        JE      @@2
        CMP     AL,varDouble
        JB      @@4
        CMP     AL,varDate
        JA      @@4
        PUSH    [ESI].Integer[4]
        PUSH    [ESI].Integer[0]
        PUSH    EDX
        PUSH    EAX
        ADD     ESI,8
        JMP     @@5
@@2:    PUSH    [ESI].Integer[12]
        PUSH    [ESI].Integer[8]
        PUSH    [ESI].Integer[4]
        PUSH    [ESI].Integer[0]
        ADD     ESI,16
        JMP     @@5
@@3:    AND     AL,atTypeMask
        OR      EAX,varByRef
@@4:    PUSH    EDX
        PUSH    [ESI].Integer[0]
        PUSH    EDX
        PUSH    EAX
        ADD     ESI,4
@@5:    INC     EBX
        DEC     ECX
        JNE     @@1
        MOV     EBX,CallDesc
@@10:   MOV     DispParams.rgvarg,ESP
        MOVZX   EAX,[EBX].TCallDesc.NamedArgCount
        MOV     DispParams.cNamedArgs,EAX
        TEST    EAX,EAX
        JE      @@12
        MOV     ESI,NamedArgDispIDs
@@11:   PUSH    [ESI].Integer[EAX*4-4]
        DEC     EAX
        JNE     @@11
@@12:   MOVZX   ECX,[EBX].TCallDesc.CallType
        CMP     ECX,DISPATCH_PROPERTYPUT
        JNE     @@20
        PUSH    DISPID_PROPERTYPUT
        INC     DispParams.cNamedArgs
        CMP     [EBX].TCallDesc.ArgTypes.Byte[0],varDispatch
        JE      @@13
        CMP     [EBX].TCallDesc.ArgTypes.Byte[0],varUnknown
        JNE     @@20
@@13:   MOV     ECX,DISPATCH_PROPERTYPUTREF
@@20:   MOV     DispParams.rgdispidNamedArgs,ESP
        PUSH    EDX                     { ArgErr }
        LEA     EAX,ExcepInfo
        PUSH    EAX                     { ExcepInfo }
        PUSH    ECX
        PUSH    EDX
        CALL    ClearExcepInfo
        POP     EDX
        POP     ECX
        PUSH    Result                  { VarResult }
        LEA     EAX,DispParams
        PUSH    EAX                     { Params }
        PUSH    ECX                     { Flags }
        PUSH    EDX                     { LocaleID }
        PUSH    OFFSET GUID_NULL        { IID }
        PUSH    DispID                  { DispID }
        MOV     EAX,Dispatch
        PUSH    EAX
        MOV     EAX,[EAX]
        CALL    [EAX].Pointer[24]
        TEST    EAX,EAX
        JE      @@30
        LEA     EDX,ExcepInfo
        MOV     CL, 1
        PUSH    ECX
        MOV     ECX,[EBP+4]
        JMP     DispCallError
@@30:   MOV     ESP,EDI
        POP     EDI
        POP     ESI
        POP     EBX
end;

procedure DispCallByID(Result: Pointer; const Dispatch: IDispatch;
  DispDesc: PDispDesc; Params: Pointer); CDECL;
asm
        PUSH    EBX
        MOV     EBX,DispDesc
        XOR     EAX,EAX
        PUSH    EAX
        PUSH    EAX
        PUSH    EAX
        PUSH    EAX
        MOV     EAX,ESP
        PUSH    EAX
        LEA     EAX,Params
        PUSH    EAX
        PUSH    EAX
        PUSH    [EBX].TDispDesc.DispID
        LEA     EAX,[EBX].TDispDesc.CallDesc
        PUSH    EAX
        PUSH    Dispatch
        CALL    DispCall
        MOVZX   EAX,[EBX].TDispDesc.ResType
        MOV     EBX,Result
        JMP     @ResultTable.Pointer[EAX*4]

@ResultTable:
        DD      @ResEmpty
        DD      @ResNull
        DD      @ResSmallint
        DD      @ResInteger
        DD      @ResSingle
        DD      @ResDouble
        DD      @ResCurrency
        DD      @ResDate
        DD      @ResString
        DD      @ResDispatch
        DD      @ResError
        DD      @ResBoolean
        DD      @ResVariant
        DD      @ResUnknown
        DD      @ResDecimal
        DD      @ResError
        DD      @ResByte

@ResSingle:
        FLD     [ESP+8].Single
        JMP     @ResDone

@ResDouble:
@ResDate:
        FLD     [ESP+8].Double
        JMP     @ResDone

@ResCurrency:
        FILD    [ESP+8].Currency
        JMP     @ResDone

@ResString:
        MOV     EAX,[EBX]
        TEST    EAX,EAX
        JE      @@1
        PUSH    EAX
        CALL    SysFreeString
@@1:    MOV     EAX,[ESP+8]
        MOV     [EBX],EAX
        JMP     @ResDone

@ResDispatch:
@ResUnknown:
        MOV     EAX,[EBX]
        TEST    EAX,EAX
        JE      @@2
        PUSH    EAX
        MOV     EAX,[EAX]
        CALL    [EAX].Pointer[8]
@@2:    MOV     EAX,[ESP+8]
        MOV     [EBX],EAX
        JMP     @ResDone

@ResVariant:
        MOV     EAX,EBX
        CALL    System.@VarClear
        MOV     EAX,[ESP]
        MOV     [EBX],EAX
        MOV     EAX,[ESP+4]
        MOV     [EBX+4],EAX
        MOV     EAX,[ESP+8]
        MOV     [EBX+8],EAX
        MOV     EAX,[ESP+12]
        MOV     [EBX+12],EAX
        JMP     @ResDone

@ResSmallint:
@ResInteger:
@ResBoolean:
@ResByte:
        MOV     EAX,[ESP+8]

@ResDecimal:
@ResEmpty:
@ResNull:
@ResError:
@ResDone:
        ADD     ESP,16
        POP     EBX
end;

const
  DispIDArgs                       : LONGINT = DISPID_PROPERTYPUT;

function GetDispatchPropValue(Disp: IDispatch; DispID: integer): OleVariant;
var
  ExcepInfo                        : TExcepInfo;
  DispParams                       : TDispParams;
  Status                           : HResult;
begin
  FillChar(DispParams, SizeOf(DispParams), 0);
  Status := Disp.invoke(DispID, GUID_NULL, 0, DISPATCH_PROPERTYGET, DispParams,
    @Result, @ExcepInfo, nil);
  if Status <> S_OK then DispatchInvokeError(Status, ExcepInfo);
end;

function GetDispatchPropValue(Disp: IDispatch; Name: WideString): OleVariant;
var
  ID                               : integer;
begin
  OleCheck(Disp.GetIDsOfNames(GUID_NULL, @Name, 1, 0, @ID));
  Result := GetDispatchPropValue(Disp, ID);
end;

procedure SetDispatchPropValue(Disp: IDispatch; DispID: integer;
  const Value: OleVariant);
var
  ExcepInfo                        : TExcepInfo;
  DispParams                       : TDispParams;
  Status                           : HResult;
begin
  with DispParams do
    begin
      rgvarg := @Value;
      rgdispidNamedArgs := @DispIDArgs;
      cArgs := 1;
      cNamedArgs := 1;
    end;
  Status := Disp.invoke(DispID, GUID_NULL, 0, DISPATCH_PROPERTYPUT, DispParams,
    nil, @ExcepInfo, nil);
  if Status <> S_OK then DispatchInvokeError(Status, ExcepInfo);
end;

procedure SetDispatchPropValue(Disp: IDispatch; Name: WideString;
  const Value: OleVariant); OVERLOAD;
var
  ID                               : integer;
begin
  OleCheck(Disp.GetIDsOfNames(GUID_NULL, @Name, 1, 0, @ID));
  SetDispatchPropValue(Disp, ID, Value);
end;

var
  ComClassManagerVar               : TObject;
  SaveInitProc                     : Pointer;
  NeedToUninitialize               : boolean;

procedure InitComObj;
begin
  {
    if SaveInitProc <> nil then TProcedure(SaveInitProc);
    if (CoInitFlags <> -1) and Assigned(uComObj.CoInitializeEx) then
    begin
      NeedToUninitialize := Succeeded(uComObj.CoInitializeEx(nil, CoInitFlags));
      IsMultiThread := IsMultiThread or
        ((CoInitFlags and COINIT_APARTMENTTHREADED) <> 0) or
        (CoInitFlags = COINIT_MULTITHREADED);  // this flag has value zero
    end
    else
      NeedToUninitialize := Succeeded(CoInitialize(nil));
  }
end;

function StrLen(const Str: PChar): Cardinal; ASSEMBLER;
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

initialization
  begin
    LoadComExProcs;
    VarDispProc := @VarDispInvoke;
    DispCallByIDProc := @DispCallByID;
{$IFDEF MSWINDOWS}
    SafeCallErrorProc := @SafeCallError;
{$ENDIF}
    if not IsLibrary then
      begin
        SaveInitProc := InitProc;
        InitProc := @InitComObj;
      end;
  end;

finalization
  begin
    OleUninitializing := True;
    ComClassManagerVar.Free;
    SafeCallErrorProc := nil;
    DispCallByIDProc := nil;
    VarDispProc := nil;
    if NeedToUninitialize then CoUninitialize;
  end;

end.

