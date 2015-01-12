unit uVariants;

{$RANGECHECKS OFF}

interface

uses
  Types;

{ Variant support procedures and functions }

function VarType(const V: Variant): TVarType;
function VarAsType(const V: Variant; AVarType: TVarType): Variant;
function VarIsType(const V: Variant; AVarType: TVarType): Boolean; overload;
function VarIsType(const V: Variant; const AVarTypes: array of TVarType): Boolean; overload;
function VarIsByRef(const V: Variant): Boolean;

function VarIsEmpty(const V: Variant): Boolean;
procedure VarCheckEmpty(const V: Variant);
function VarIsNull(const V: Variant): Boolean;
function VarIsClear(const V: Variant): Boolean;

function VarIsCustom(const V: Variant): Boolean;
function VarIsOrdinal(const V: Variant): Boolean;
function VarIsFloat(const V: Variant): Boolean;
function VarIsNumeric(const V: Variant): Boolean;
function VarIsStr(const V: Variant): Boolean;

function VarToStr(const V: Variant): string;
function VarToStrDef(const V: Variant; const ADefault: string): string;
function VarToWideStr(const V: Variant): WideString;
function VarToWideStrDef(const V: Variant; const ADefault: WideString): WideString;

function VarToDateTime(const V: Variant): TDateTime;
function VarFromDateTime(const DateTime: TDateTime): Variant;

function VarInRange(const AValue, AMin, AMax: Variant): Boolean;
function VarEnsureRange(const AValue, AMin, AMax: Variant): Variant;

type
  TVariantRelationship = (vrEqual, vrLessThan, vrGreaterThan, vrNotEqual);

function VarSameValue(const A, B: Variant): Boolean;
function VarCompareValue(const A, B: Variant): TVariantRelationship;

function VarIsEmptyParam(const V: Variant): Boolean;

function VarSupports(const V: Variant; const IID: TGUID; out Intf): Boolean; overload;
function VarSupports(const V: Variant; const IID: TGUID): Boolean; overload;

{ Variant copy support }

procedure VarCopyNoInd(var Dest: Variant; const Source: Variant);

{ Variant array support procedures and functions }

function VarIsArray(const A: Variant): Boolean; overload;
function VarIsArray(const A: Variant; AResolveByRef: Boolean): Boolean; overload;

function VarArrayCreate(const Bounds: array of Integer; AVarType: TVarType): Variant;
function VarArrayOf(const Values: array of Variant): Variant;

function VarArrayRef(const A: Variant): Variant;

function VarTypeIsValidArrayType(const AVarType: TVarType): Boolean;
function VarTypeIsValidElementType(const AVarType: TVarType): Boolean;

{ The following functions will handle normal variant arrays as well as
  variant arrays references by another variant using byref }

function VarArrayDimCount(const A: Variant): Integer;
function VarArrayLowBound(const A: Variant; Dim: Integer): Integer;
function VarArrayHighBound(const A: Variant; Dim: Integer): Integer;

function VarArrayLock(const A: Variant): Pointer;
procedure VarArrayUnlock(const A: Variant);

function VarArrayGet(const A: Variant; const Indices: array of Integer): Variant;
procedure VarArrayPut(var A: Variant; const Value: Variant; const Indices: array of Integer);

{ Variant <--> Dynamic Arrays }

procedure DynArrayToVariant(var V: Variant; const DynArray: Pointer; TypeInfo: Pointer);
procedure DynArrayFromVariant(var DynArray: Pointer; const V: Variant; TypeInfo: Pointer);

{ Global constants }

function Unassigned: Variant; // Unassigned standard constant
function Null: Variant;       // Null standard constant

var
  EmptyParam: OleVariant;    // "Empty parameter" standard constant which can be
  {$EXTERNALSYM EmptyParam}  // passed as an optional parameter on a dual
                             // interface.

{ Custom variant base class }

type
  TVarCompareResult = (crLessThan, crEqual, crGreaterThan);
  TCustomVariantType = class(TObject, IInterface)
  private
    FVarType: TVarType;
  protected
    { IInterface }
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    procedure SimplisticClear(var V: TVarData);
    procedure SimplisticCopy(var Dest: TVarData; const Source: TVarData;
      const Indirect: Boolean = False);

    procedure RaiseInvalidOp;
    procedure RaiseCastError;
    procedure RaiseDispError;

    function LeftPromotion(const V: TVarData; const Operator: TVarOp;
      out RequiredVarType: TVarType): Boolean; virtual;
    function RightPromotion(const V: TVarData; const Operator: TVarOp;
      out RequiredVarType: TVarType): Boolean; virtual;
    function OlePromotion(const V: TVarData;
      out RequiredVarType: TVarType): Boolean; virtual;
    procedure DispInvoke(var Dest: TVarData; const Source: TVarData;
      CallDesc: PCallDesc; Params: Pointer); virtual;

    procedure VarDataInit(var Dest: TVarData);
    procedure VarDataClear(var Dest: TVarData);

    procedure VarDataCopy(var Dest: TVarData; const Source: TVarData);
    procedure VarDataCopyNoInd(var Dest: TVarData; const Source: TVarData);

    procedure VarDataCast(var Dest: TVarData; const Source: TVarData);
    procedure VarDataCastTo(var Dest: TVarData; const Source: TVarData;
      const AVarType: TVarType); overload;
    procedure VarDataCastTo(var Dest: TVarData; const AVarType: TVarType); overload;
    procedure VarDataCastToOleStr(var Dest: TVarData);

    procedure VarDataFromStr(var V: TVarData; const Value: string);
    procedure VarDataFromOleStr(var V: TVarData; const Value: WideString);
    function VarDataToStr(const V: TVarData): string;

    function VarDataIsEmptyParam(const V: TVarData): Boolean;
    function VarDataIsByRef(const V: TVarData): Boolean;
    function VarDataIsArray(const V: TVarData): Boolean;

    function VarDataIsOrdinal(const V: TVarData): Boolean;
    function VarDataIsFloat(const V: TVarData): Boolean;
    function VarDataIsNumeric(const V: TVarData): Boolean;
    function VarDataIsStr(const V: TVarData): Boolean;
  public
    constructor Create; overload;
    constructor Create(RequestedVarType: TVarType); overload;
    destructor Destroy; override;
    property VarType: TVarType read FVarType;

    function IsClear(const V: TVarData): Boolean; virtual;
    procedure Cast(var Dest: TVarData; const Source: TVarData); virtual;
    procedure CastTo(var Dest: TVarData; const Source: TVarData;
      const AVarType: TVarType); virtual;
    procedure CastToOle(var Dest: TVarData; const Source: TVarData); virtual;

    // The following three procedures must be overridden by your custom
    //  variant type class.  Simplistic versions of Clear and Copy are
    //  available in the protected section of this class but depending on the
    //  type of data contained in your custom variant type those functions
    //  may not handle your situation.
    procedure Clear(var V: TVarData); virtual; abstract;
    procedure Copy(var Dest: TVarData; const Source: TVarData;
      const Indirect: Boolean); virtual; abstract;

    procedure BinaryOp(var Left: TVarData; const Right: TVarData;
      const Operator: TVarOp); virtual;
    procedure UnaryOp(var Right: TVarData; const Operator: TVarOp); virtual;
    function CompareOp(const Left, Right: TVarData;
      const Operator: TVarOp): Boolean; virtual;
    procedure Compare(const Left, Right: TVarData;
      var Relationship: TVarCompareResult); virtual;
  end;
  TCustomVariantTypeClass = class of TCustomVariantType;

  TVarDataArray = array of TVarData;
  IVarInvokeable = interface
    ['{1CB65C52-BBCB-41A6-9E58-7FB916BEEB2D}']
    function DoFunction(var Dest: TVarData; const V: TVarData;
      const Name: string; const Arguments: TVarDataArray): Boolean;
    function DoProcedure(const V: TVarData; const Name: string;
      const Arguments: TVarDataArray): Boolean;
    function GetProperty(var Dest: TVarData; const V: TVarData;
      const Name: string): Boolean;
    function SetProperty(const V: TVarData; const Name: string;
      const Value: TVarData): Boolean;
  end;

  TInvokeableVariantType = class(TCustomVariantType, IVarInvokeable)
  protected
    procedure DispInvoke(var Dest: TVarData; const Source: TVarData;
      CallDesc: PCallDesc; Params: Pointer); override;
  public
    { IVarInvokeable }
    function DoFunction(var Dest: TVarData; const V: TVarData;
      const Name: string; const Arguments: TVarDataArray): Boolean; virtual;
    function DoProcedure(const V: TVarData; const Name: string;
      const Arguments: TVarDataArray): Boolean; virtual;
    function GetProperty(var Dest: TVarData; const V: TVarData;
      const Name: string): Boolean; virtual;
    function SetProperty(const V: TVarData; const Name: string;
      const Value: TVarData): Boolean; virtual;
  end;

  IVarInstanceReference = interface
    ['{5C176802-3F89-428D-850E-9F54F50C2293}']
    function GetInstance(const V: TVarData): TObject;
  end;

  function FindCustomVariantType(const AVarType: TVarType;
    out CustomVariantType: TCustomVariantType): Boolean; overload;
  function FindCustomVariantType(const TypeName: string;
    out CustomVariantType: TCustomVariantType): Boolean; overload;

type
  TAnyProc = procedure (var V: TVarData);
  TVarDispProc = procedure (Dest: PVariant; const Source: Variant;
      CallDesc: PCallDesc; Params: Pointer); cdecl;

var
  VarDispProc: TVarDispProc;
  ClearAnyProc: TAnyProc;  { Handler clearing a varAny }
  ChangeAnyProc: TAnyProc; { Handler to change any to variant }
  RefAnyProc: TAnyProc;    { Handler to add a reference to an varAny }

implementation

uses
  SysConst, SysUtils, VarUtils;

{ ----------------------------------------------------- }
{       Variant support                                 }
{ ----------------------------------------------------- }

var
  GVariantManager,
  GOldVariantManager: TVariantManager;

type
  TBaseType = (btErr, btNul, btInt, btFlt, btCur, btStr, btBol, btDat, btI64);

const
  varLast = varInt64;

const
  BaseTypeMap: array[0..varLast] of TBaseType = (
    btErr,  { varEmpty    }
    btNul,  { varNull     }
    btInt,  { varSmallint }
    btInt,  { varInteger  }
    btFlt,  { varSingle   }
    btFlt,  { varDouble   }
    btCur,  { varCurrency }
    btDat,  { varDate     }
    btStr,  { varOleStr   }
    btErr,  { varDispatch }
    btErr,  { varError    }
    btBol,  { varBoolean  }
    btErr,  { varVariant  }
    btErr,  { varUnknown  }
    btErr,  { vt_decimal  }
    btErr,  { undefined   }
    btInt,  { varShortInt }
    btInt,  { varByte     }
    btI64,  { varWord     }
    btI64,  { varLongWord }
    btI64); { varInt64    }

const
  OpTypeMap: array[TBaseType, TBaseType] of TBaseType = (
         {btErr, btNul, btInt, vtFlt, btCur, btStr, btBol, btDat, btI64}
  {btErr}(btErr, btErr, btErr, btErr, btErr, btErr, btErr, btErr, btErr),
  {btNul}(btErr, btNul, btNul, btNul, btNul, btNul, btNul, btNul, btNul),
  {btInt}(btErr, btNul, btInt, btFlt, btCur, btFlt, btInt, btDat, btI64),
  {btFlt}(btErr, btNul, btFlt, btFlt, btCur, btFlt, btFlt, btDat, btFlt),
  {btCur}(btErr, btNul, btCur, btCur, btCur, btCur, btCur, btDat, btCur),
  {btStr}(btErr, btNul, btFlt, btFlt, btCur, btStr, btBol, btDat, btFlt),
  {btBol}(btErr, btNul, btInt, btFlt, btCur, btBol, btBol, btDat, btI64),
  {btDat}(btErr, btNul, btDat, btDat, btDat, btDat, btDat, btDat, btDat),
  {btI64}(btErr, btNul, btI64, btFlt, btCur, btFlt, btI64, btDat, btI64));

{ TCustomVariantType support }
{ Currently we have reserve room for 1791 ($6FF) custom types.  But, since the
  first sixteen are reserved, we actually only have room for 1775 ($6EF) types. }
const
  CMaxNumberOfCustomVarTypes = $06FF;
  CMinVarType = $0100;
  CMaxVarType = CMinVarType + CMaxNumberOfCustomVarTypes;
  CIncVarType = $000F;
  CFirstUserType = CMinVarType + CIncVarType;
  CInvalidCustomVariantType: TCustomVariantType = TCustomVariantType($FFFFFFFF);

procedure _DispInvokeError;
asm
        MOV     AL,System.reVarDispatch
        JMP     System.Error
end;

procedure VarCastError;
asm
        MOV     AL,System.reVarTypeCast
        JMP     System.Error
end;

procedure VarInvalidOp;
asm
        MOV     AL,System.reVarInvalidOp
        JMP     System.Error
end;

procedure _VarInit(var V: TVarData);
begin
  VariantInit(V);
end;

procedure _VarClear(var V: TVarData);
var
  LType: TVarType;
  LHandler: TCustomVariantType;
begin
  LType := V.VType and varTypeMask;
  if LType < CFirstUserType then
  begin
    if ((V.VType and varByRef) <> 0) or (LType < varOleStr) then
      V.VType := varEmpty
    else if LType = varString then
    begin
      V.VType := varEmpty;
      String(V.VString) := '';
    end
    else if LType = varAny then
      ClearAnyProc(V)
    else
      VariantClear(V);
  end
  else if FindCustomVariantType(LType, LHandler) then
    LHandler.Clear(V)
  else
    VarInvalidOp;
end;

procedure _DispInvoke(Dest: PVarData; const Source: TVarData;
  CallDesc: PCallDesc; Params: Pointer); cdecl;
var
  LSourceType: TVarType;
  LSourceHandler: TCustomVariantType;
begin
  LSourceType := Source.VType and varTypeMask;
  if Assigned(Dest) then
    _VarClear(Dest^);
  if LSourceType < CFirstUserType then
    VarDispProc(PVariant(Dest), Variant(Source), CallDesc, @Params)
  else if FindCustomVariantType(LSourceType, LSourceHandler) then
    LSourceHandler.DispInvoke(TVarData(Dest^), Source, CallDesc, @Params)
  else
    VarInvalidOp;
end;

type
  TVarArrayForEach = procedure(var Dest: TVarData; const Src: TVarData);

procedure VarArrayCopyForEach(var Dest: TVarData; const Src: TVarData; AProc: TVarArrayForEach);
var
  I, UBound, DimCount: Integer;
  VarArrayRef, SrcArrayRef: PVarArray;
  VarBounds: array[0..63] of TVarArrayBound;
  VarPoint: array[0..63] of Integer;
  PFrom, PTo: Pointer;

  function Increment(At: Integer): Boolean;
  begin
    Result := True;
    Inc(VarPoint[At]);
    if VarPoint[At] = VarBounds[At].LowBound + VarBounds[At].ElementCount then
      if At = 0 then
        Result := False
      else
      begin
        VarPoint[At] := VarBounds[At].LowBound;
        Result := Increment(At - 1);
      end;
  end;
begin
  if Src.VType and varTypeMask <> varVariant then
    VariantCopy(Dest, Src)
  else
  begin
    if (TVarData(Src).VType and varByRef) <> 0 then
      SrcArrayRef := PVarArray(TVarData(Src).VPointer^)
    else
      SrcArrayRef := TVarData(Src).VArray;

    DimCount := SrcArrayRef^.DimCount;
    for I := 0 to DimCount - 1 do
      with VarBounds[I] do
      begin
        if SafeArrayGetLBound(SrcArrayRef, I + 1, LowBound) <> VAR_OK then
          System.Error(System.reVarArrayBounds);
        if SafeArrayGetUBound(SrcArrayRef, I + 1, UBound) <> VAR_OK then
          System.Error(System.reVarArrayBounds);
        ElementCount := UBound - LowBound + 1;
      end;

    VarArrayRef := SafeArrayCreate(varVariant, DimCount, PVarArrayBoundArray(@VarBounds)^);
    if VarArrayRef = nil then
      System.Error(System.reVarArrayCreate);

    _VarClear(Dest);

    Dest.VType := varVariant or varArray;
    Dest.VArray := VarArrayRef;

    for I := 0 to DimCount - 1 do
      VarPoint[I] := VarBounds[I].LowBound;

    repeat
      if SafeArrayPtrOfIndex(SrcArrayRef, PVarArrayCoorArray(@VarPoint), PFrom) <> VAR_OK then
        System.Error(System.reVarArrayBounds);
      if SafeArrayPtrOfIndex(VarArrayRef, PVarArrayCoorArray(@VarPoint), PTo) <> VAR_OK then
        System.Error(System.reVarArrayBounds);

      AProc(PVarData(PTo)^, PVarData(PFrom)^);
    until not Increment(DimCount - 1);
  end;
end;

procedure VarArrayCopyProc(var Dest: TVarData; const Src: TVarData);
begin
  Variant(Dest) := Variant(Src);
end;

procedure VarCopyCommon(var Dest: TVarData; const Source: TVarData; Indirect: Boolean);
var
  LSourceType: TVarType;
  LSourceHandler: TCustomVariantType;
begin
  if @Dest = @Source then
    Exit;
  LSourceType := Source.VType and varTypeMask;
  _VarClear(Dest);
  if LSourceType < CFirstUserType then
  begin
    if LSourceType < varOleStr then
      Dest := Source  // block copy
    else
      case LSourceType of
        varString:
          begin
            Dest.VType := varString;
            Dest.VString := nil;   // prevent string assignment from trying to free garbage
            String(Dest.VString) := String(Source.VString);
          end;
        varAny:
          begin
            Dest := Source;   // block copy
            RefAnyProc(Dest);
          end;
        varInt64:
          begin
            Dest.VType := varInt64;
            Dest.VInt64 := Source.VInt64;
          end;
      else
        if Indirect then
        begin
          if Source.VType and varArray <> 0 then
            VarArrayCopyForEach(Dest, Source, VarArrayCopyProc)
          else if VariantCopyInd(Dest, Source) <> VAR_OK then
            VarInvalidOp;
        end
        else
          if (Source.VType and varArray <> 0) and
             (Source.VType and varByRef = 0) then
            VarArrayCopyForEach(Dest, Source, VarArrayCopyProc)
          else
            VariantCopy(Dest, Source);
      end
  end
  else if FindCustomVariantType(LSourceType, LSourceHandler) then
    LSourceHandler.Copy(Dest, Source, Indirect)
  else
    VarInvalidOp;
end;


procedure _VarCopy(var Dest: TVarData; const Source: TVarData);
asm
        MOV     CL, 0
        JMP     VarCopyCommon
end;

procedure VarCopyNoInd(var Dest: Variant; const Source: Variant);
asm
        MOV     CL, 1
        JMP     VarCopyCommon
end;

procedure _VarFromWStr(var V: TVarData; const Value: WideString); forward;

procedure VarInt64FromVar(var Dest: TVarData; const Source: TVarData;
  DestType: TVarType);
begin
  case Source.VType and varTypeMask of
    varEmpty:;
    varSmallInt: Dest.VInt64 := Source.VSmallInt;
    varInteger:  Dest.VInt64 := Source.VInteger;
    varSingle:   Dest.VInt64 := Round(Source.VSingle);
    varDouble:   Dest.VInt64 := Round(Source.VDouble);
    varCurrency: Dest.VInt64 := Round(Source.VCurrency);
    varDate:     Dest.VInt64 := Round(Source.VDate);
    varOleStr:   Dest.VInt64 := StrToInt64(Source.VOleStr);
    varBoolean:  Dest.VInt64 := SmallInt(Source.VBoolean);
    varShortInt: Dest.VInt64 := Source.VShortInt;
    varByte:     Dest.VInt64 := Source.VByte;
    varWord:     Dest.VInt64 := Source.VWord;
    varLongWord: Dest.VInt64 := Source.VLongWord;
    varInt64:    Dest.VInt64 := Source.VInt64;
  else
    VarCastError;
  end;
  Dest.VType := DestType;
end;

procedure VarInt64ToVar(var Dest: TVarData; const Source: TVarData;
  DestType: TVarType);
begin
  case DestType of
    varEmpty:;
    varSmallInt: Dest.VSmallInt := Source.VInt64;
    varInteger:  Dest.VInteger := Source.VInt64;
    varSingle:   Dest.VSingle := Source.VInt64;
    varDouble:   Dest.VDouble := Source.VInt64;
    varCurrency: Dest.VCurrency := Source.VInt64;
    varDate:     Dest.VDate := Source.VInt64;
    varOleStr:   _VarFromWStr(Dest, IntToStr(Source.VInt64));
    varBoolean:  Dest.VBoolean := Source.VInt64 <> 0;
    varShortInt: Dest.VShortInt := Source.VInt64;
    varByte:     Dest.VByte := Source.VInt64;
    varWord:     Dest.VWord := Source.VInt64;
    varLongWord: Dest.VLongWord := Source.VInt64;
    varInt64:    Dest.VInt64 := Source.VInt64;
  else
    VarCastError;
  end;
  Dest.VType := DestType;
end;

procedure VarChangeType(var Dest: TVarData; const Source: TVarData;
  DestType: TVarType); forward;

procedure AnyChangeType(var Dest: TVarData; const Source: TVarData; DestType: TVarType);
var
  LTemp: TVarData;
begin
  _VarInit(LTemp);
  try
    _VarCopy(LTemp, Source);
    ChangeAnyProc(LTemp);
    VarChangeType(Dest, LTemp, DestType);
  finally
    _VarClear(LTemp);
  end;
end;

procedure VarChangeType(var Dest: TVarData; const Source: TVarData;
  DestType: TVarType);

  function ChangeSourceAny(var Dest: TVarData; const Source: TVarData;
    DestType: TVarType): Boolean;
  begin
    Result := False;
    if Source.VType = varAny then
    begin
      AnyChangeType(Dest, Source, DestType);
      Result := True;
    end;
  end;
var
  Temp: TVarData;
  LDestType, LSourceType: TVarType;
  LDestHandler, LSourceHandler: TCustomVariantType;
begin
  LSourceType := Source.VType and varTypeMask;
  LDestType := DestType and varTypeMask;
  _VarClear(Dest);
  if LSourceType < CFirstUserType then
  begin
    case LDestType of
      varString:
        begin
          if not ChangeSourceAny(Dest, Source, DestType) then
          begin
            _VarInit(Temp);
            try
              if VariantChangeTypeEx(Temp, Source, $400, 0, DestType) <> VAR_OK then
                VarCastError;
              Dest := Temp;  // block copy
            finally
              _VarClear(Temp);
            end;
          end;
        end;
      varAny:
        AnyChangeType(Dest, Source, DestType);
      varInt64:
        VarInt64FromVar(Dest, Source, DestType);
    else
      if LDestType < CFirstUserType then
      begin
        if LSourceType = varInt64 then
          VarInt64ToVar(Dest, Source, DestType)
        else
          if not ChangeSourceAny(Dest, Source, DestType) then
            if VariantChangeTypeEx(Dest, Source, $400, 0, DestType) <> VAR_OK then
              VarCastError;
      end
      else
        if FindCustomVariantType(LDestType, LDestHandler) then
          LDestHandler.Cast(Dest, Source)
        else
          VarInvalidOp;
    end
  end
  else if FindCustomVariantType(LSourceType, LSourceHandler) then
    LSourceHandler.CastTo(Dest, Source, DestType)
  else
    VarInvalidOp;
end;

procedure _VarOleStrToString(var Dest: TVarData; const Source: TVarData);
var
  StringPtr: Pointer;
begin
  StringPtr := nil;
  OleStrToStrVar(Source.VOleStr, string(StringPtr));
  _VarClear(Dest);
  Dest.VType := varString;
  Dest.VString := StringPtr;
end;

procedure VarOleStrToString(var Dest: Variant; const Source: Variant);
asm
        JMP     _VarOleStrToString
end;

procedure _VarStringToOleStr(var Dest: TVarData; const Source: TVarData);
var
  OleStrPtr: PWideChar;
begin
  OleStrPtr := StringToOleStr(string(Source.VString));
  _VarClear(Dest);
  Dest.VType := varOleStr;
  Dest.VOleStr := OleStrPtr;
end;

procedure VarStringToOleStr(var Dest: Variant; const Source: Variant);
asm
        JMP    _VarStringToOleStr
end;

procedure _VarCast(var Dest: TVarData; const Source: TVarData; AVarType: Integer);
var
  SourceType, DestType: TVarType;
  Temp: TVarData;
begin
  SourceType := Source.VType;
  DestType := TVarType(AVarType);
  _VarClear(Dest);
  if SourceType = DestType then
    _VarCopy(Dest, Source)
  else if SourceType = varString then
    if DestType = varOleStr then
      _VarStringToOleStr(Dest, Source)
    else
    begin
      _VarInit(Temp);
      try
        _VarStringToOleStr(Temp, Source);
        VarChangeType(Dest, Temp, DestType);
      finally
        _VarClear(Temp);
      end;
    end
  else if (DestType = varString) and (SourceType <> varAny) then
    if SourceType = varOleStr then
      _VarOleStrToString(Dest, Source)
    else
    begin
      _VarInit(Temp);
      try
        VarChangeType(Temp, Source, varOleStr);
        _VarOleStrToString(Dest, Temp);
      finally
        _VarClear(Temp);
      end;
    end
  else
    VarChangeType(Dest, Source, DestType);
end;

(* VarCast when the destination is OleVariant *)
procedure _VarCastOle(var Dest: TVarData; const Source: TVarData; AVarType: Integer);
var
  LSourceType: TVarType;
  LSourceHandler: TCustomVariantType;
begin
  if AVarType >= CMinVarType then
    VarCastError
  else
  begin
    LSourceType := Source.VType and varTypeMask;
    _VarClear(Dest);
    if LSourceType < CFirstUserType then
      _VarCast(Dest, Source, AVarType)
    else if FindCustomVariantType(LSourceType, LSourceHandler) then
      LSourceHandler.CastTo(Dest, Source, AVarType)
    else
      VarCastError;
  end;
end;

function _VarToInt(const V: TVarData): Integer;
var
  Temp: TVarData;
begin
  case V.VType of
    varInteger  : Result := V.VInteger;
    varSmallInt : Result := V.VSmallInt;
    varByte     : Result := V.VByte;
    varShortInt : Result := V.VShortInt;
    varWord     : Result := V.VWord;
    varLongWord : Result := V.VLongWord;
    varInt64    : Result := V.VInt64;

    varDouble   : Result := Round(V.VDouble);
    varSingle   : Result := Round(V.VSingle);
    varCurrency : Result := Round(V.VCurrency);
  else
    _VarInit(Temp);
    _VarCast(Temp, V, varInteger);
    Result := Temp.VInteger;
  end;
end;

function _VarToInt64(const V: TVarData): Int64;
var
  Temp: TVarData;
begin
  case V.VType of
    varInteger  : Result := V.VInteger;
    varSmallInt : Result := V.VSmallInt;
    varByte     : Result := V.VByte;
    varShortInt : Result := V.VShortInt;
    varWord     : Result := V.VWord;
    varLongWord : Result := V.VLongWord;
    varInt64    : Result := V.VInt64;

    varDouble   : Result := Round(V.VDouble);
    varSingle   : Result := Round(V.VSingle);
    varCurrency : Result := Round(V.VCurrency);
  else
    _VarInit(Temp);
    _VarCast(Temp, V, varInteger);
    Result := Temp.VInteger;
  end;
end;

function _VarToBool(const V: TVarData): Boolean;
var
  Temp: TVarData;
begin
  if V.VType = varBoolean then
    Result := V.VBoolean
  else
  begin
    _VarInit(Temp);
    _VarCast(Temp, V, varBoolean);
    Result := Temp.VBoolean;
  end;
end;

function _VarToReal(const V: TVarData): Extended;
var
  Temp: TVarData;
begin
  case V.VType of
    varDouble   : Result := V.VDouble;
    varDate     : Result := V.VDate;
    varSingle   : Result := V.VSingle;
    varCurrency : Result := V.VCurrency;

    varInteger  : Result := V.VInteger;
    varSmallInt : Result := V.VSmallInt;
    varByte     : Result := V.VByte;
    varShortInt : Result := V.VShortInt;
    varWord     : Result := V.VWord;
    varLongWord : Result := V.VLongWord;
    varInt64    : Result := V.VInt64;
  else
    _VarInit(Temp);
    _VarCast(Temp, V, varDouble);
    Result := Temp.VDouble;
  end;
end;

function _VarToCurr(const V: TVarData): Currency;
var
  Temp: TVarData;
begin
  case V.VType of
    varCurrency : Result := V.VCurrency;
    varDouble   : Result := V.VDouble;
    varSingle   : Result := V.VSingle;

    varInteger  : Result := V.VInteger;
    varSmallInt : Result := V.VSmallInt;
    varByte     : Result := V.VByte;
    varShortInt : Result := V.VShortInt;
    varWord     : Result := V.VWord;
    varLongWord : Result := V.VLongWord;
    varInt64    : Result := V.VInt64;
  else
    _VarInit(Temp);
    _VarCast(Temp, V, varCurrency);
    Result := Temp.VCurrency;
  end;
end;

procedure _VarToLStr(var S: string; const V: TVarData);
var
  Temp: TVarData;
begin
  if V.VType = varString then
    S := String(V.VString)
  else
  begin
    _VarInit(Temp);
    try
      _VarCast(Temp, V, varString);
      S := String(Temp.VString);
    finally
      _VarClear(Temp);
    end;
  end;
end;

procedure _VarToPStr(var S; const V: TVarData);
var
  Temp: string;
begin
  _VarToLStr(Temp, V);
  ShortString(S) := Temp;
end;

procedure _VarToWStr(var S: WideString; const V: TVarData);
var
  Temp: TVarData;
begin
  if V.VType = varOleStr then
    S := WideString(V.VOleStr)
  else
  begin
    _VarInit(Temp);
    try
      _VarCast(Temp, V, varOleStr);
      S := WideString(Temp.VOleStr);
    finally
      _VarClear(Temp);
    end;
  end;
end;

procedure AnyToIntf(var Intf: IInterface; const V: TVarData);
var
  LTemp: TVarData;
begin
  _VarInit(LTemp);
  try
    _VarCopy(LTemp, V);
    ChangeAnyProc(LTemp);
    if LTemp.VType <> varUnknown then
      VarCastError;
    Intf := IInterface(LTemp.VUnknown);
  finally
    _VarClear(LTemp);
  end;
end;

procedure _VarToIntf(var Intf: IInterface; const V: TVarData);
var
  LHandler: TCustomVariantType;
begin
  case V.VType of
    varEmpty                : Intf := nil;
    varUnknown,
    varDispatch             : Intf := IInterface(V.VUnknown);
    varUnknown + varByRef,
    varDispatch + varByRef  : Intf := IInterface(V.VPointer^);
    varAny                  : AnyToIntf(Intf, V);
  else
    if not FindCustomVariantType(V.VType, LHandler) or
       not LHandler.GetInterface(IInterface, Intf) then
      VarCastError;
  end;
end;

procedure _VarToDisp(var Dispatch: IDispatch; const V: TVarData);
var
  LHandler: TCustomVariantType;
begin
  case V.VType of
    varEmpty             : Dispatch := nil;
    varDispatch          : Dispatch := IDispatch(V.VDispatch);
    varDispatch+varByRef : Dispatch := IDispatch(V.VPointer^);
  else
    if not FindCustomVariantType(V.VType, LHandler) or
       not LHandler.GetInterface(IDispatch, Dispatch) then
      VarCastError;
  end;
end;

procedure _VarToDynArray(var DynArray: Pointer; const V: TVarData; TypeInfo: Pointer);
asm
        CALL    DynArrayFromVariant
        OR      EAX, EAX
        JNZ     @@1
        JMP     VarCastError
@@1:
end;

{ pardon the strange case format but it lays out better this way }
procedure _VarFromInt(var V: TVarData; const Value, Range: Integer);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  case Range of
   {-4: varInteger is handled by the else clause }
    -2: begin V.VType := varSmallInt;  V.VSmallInt := Value; end;
    -1: begin V.VType := varShortInt;  V.VShortInt := Value; end;
     1: begin V.VType := varByte;      V.VByte := Value;     end;
     2: begin V.VType := varWord;      V.VWord := Value;     end;
     4: begin V.VType := varLongWord;  V.VLongWord := Value; end;
    -3, 0, 3: V.VType := varError;
  else
    V.VType := varInteger; V.VInteger := Value;
  end;
end;

procedure _OleVarFromInt(var V: TVarData; const Value, Range: Integer);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  V.VType := varInteger;
  V.VInteger := Value;
end;

procedure _VarFromInt64(var V: TVarData; const Value: Int64);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  V.VType := varInt64;
  V.VInt64 := Value;
end;

procedure _VarFromBool(var V: TVarData; const Value: Boolean);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  V.VType := varBoolean;
  V.VBoolean := Value;
end;

procedure _VarFromReal; // var V: Variant; const Value: Real
asm
        CMP     [EAX].TVarData.VType,varOleStr
        JB      @@1
        PUSH    EAX
        CALL    _VarClear
        POP     EAX
@@1:    MOV     [EAX].TVarData.VType,varDouble
        FSTP    [EAX].TVarData.VDouble
        FWAIT
end;

procedure _VarFromTDateTime; // var V: Variant; const Value: TDateTime
asm
        CMP     [EAX].TVarData.VType,varOleStr
        JB      @@1
        PUSH    EAX
        CALL    _VarClear
        POP     EAX
@@1:    MOV     [EAX].TVarData.VType,varDate
        FSTP    [EAX].TVarData.VDouble
        FWAIT
end;

procedure _VarFromCurr; // var V: Variant; const Value: Currency
asm
        CMP     [EAX].TVarData.VType,varOleStr
        JB      @@1
        PUSH    EAX
        CALL    _VarClear
        POP     EAX
@@1:    MOV     [EAX].TVarData.VType,varCurrency
        FISTP   [EAX].TVarData.VCurrency
        FWAIT
end;

procedure _VarFromLStr(var V: TVarData; const Value: string);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  V.VString := nil;
  V.VType := varString;
  String(V.VString) := Value;
end;

procedure _VarFromPStr(var V: TVarData; const Value: ShortString);
begin
  _VarFromLStr(V, Value);
end;

procedure _VarFromWStr(var V: TVarData; const Value: WideString);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  V.VOleStr := nil;
  V.VType := varOleStr;
  WideString(Pointer(V.VOleStr)) := Copy(Value, 1, MaxInt);
end;

procedure _VarFromIntf(var V: TVarData; const Value: IInterface);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  V.VUnknown := nil;
  V.VType := varUnknown;
  IInterface(V.VUnknown) := Value;
end;

procedure _VarFromDisp(var V: TVarData; const Value: IDispatch);
begin
  if V.VType >= varOleStr then
    _VarClear(V);
  V.VDispatch := nil;
  V.VType := varDispatch;
  IInterface(V.VDispatch) := Value;
end;

procedure _VarFromDynArray(var V: TVarData; const DynArray: Pointer; TypeInfo: Pointer);
asm
        PUSH    EAX
        CALL    DynArrayToVariant
        POP     EAX
        CMP     [EAX].TVarData.VType,varEmpty
        JNE     @@1
        JMP     VarCastError
@@1:
end;


procedure _OleVarFromLStr(var V: TVarData {OleVariant}; const Value: string);
begin
  _VarFromWStr(V, WideString(Value));
end;

procedure _OleVarFromPStr(var V: TVarData {OleVariant}; const Value: ShortString);
begin
  _OleVarFromLStr(V, Value);
end;

procedure _OleVarFromVar(var Dest: TVarData {OleVariant}; const Source: TVarData); forward;

procedure OleVarFromAny(var V: TVarData {OleVariant}; const Value: TVarData);
var
  LTemp: TVarData;
begin
  _VarInit(LTemp);
  try
    _VarCopy(LTemp, Value);
    ChangeAnyProc(LTemp);
    _VarCopy(V, LTemp);
  finally
    _VarClear(LTemp);
  end;
end;

procedure OleVarFromVarArrayProc(var Dest: TVarData; const Src: TVarData);
var
  LFromType: TVarType;
  LFromHandler: TCustomVariantType;
begin
  LFromType := Src.VType and varTypeMask;
  if LFromType < CFirstUserType then
    _OleVarFromVar(Dest, Src)
  else if FindCustomVariantType(LFromType, LFromHandler) then
    LFromHandler.CastToOle(Dest, Src)
  else
    VarInvalidOp;
end;

procedure _OleVarFromVar(var Dest: TVarData {OleVariant}; const Source: TVarData);
var
  LSourceType: TVarType;
  LSourceHandler: TCustomVariantType;
begin
  _VarClear(Dest);
  LSourceType := Source.VType and varTypeMask;
  if LSourceType < CFirstUserType then
  begin
    { This won't strip the array bit so only simple types will be handled by case }
    case Source.VType and not varByRef of
      varShortInt, varByte, varWord:
        VarChangeType(Dest, Source, varInteger);
      varLongWord:
        if Source.VLongWord <= Cardinal(High(Integer)) then
          VarChangeType(Dest, Source, varInteger)
        else
          VarChangeType(Dest, Source, varDouble);
      varInt64:
        if (Source.VInt64 <= High(Integer)) and
           (Source.VInt64 >= Low(Integer)) then
          VarChangeType(Dest, Source, varInteger)
        else
          VarChangeType(Dest, Source, varDouble);
      varString:
        _OleVarFromLStr(Dest, String(Source.VString));
      varAny:
        OleVarFromAny(Dest, Source);
    else
      if Source.VType and varArray <> 0 then
        VarArrayCopyForEach(Dest, Source, OleVarFromVarArrayProc)
      else
        _VarCopy(Dest, Source);
    end;
  end
  else if FindCustomVariantType(LSourceType, LSourceHandler) then
    LSourceHandler.CastToOle(Dest, Source)
  else
    VarInvalidOp;
end;

procedure VarStrCat(var Dest: Variant; const Source: Variant);
begin
  if TVarData(Dest).VType = varString then
    Dest := string(Dest) + string(Source)
  else
    Dest := WideString(Dest) + WideString(Source);
end;

procedure _SimpleVarOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp); forward;

procedure _VarOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);
var
  LLeftType, LRightType, LNewLeftType, LNewRightType: TVarType;
  LLeftHandler, LRightHandler: TCustomVariantType;
  LTemp: TVarData;
begin
  LLeftType := Left.VType and varTypeMask;
  LRightType := Right.VType and varTypeMask;

  // just in case we need it
  _VarInit(LTemp);
  try

    // simple and ???
    if LLeftType < CFirstUserType then
    begin

      // simple and simple
      if LRightType < CFirstUserType then
        _SimpleVarOp(Left, Right, OpCode)

      // simple and custom but the custom doesn't really exist (nasty but possible )
      else if not FindCustomVariantType(LRightType, LRightHandler) then
        VarInvalidOp

      // does the custom want to take over?
      else if LRightHandler.LeftPromotion(Left, OpCode, LNewLeftType) then
      begin

        // convert the left side
        if LLeftType <> LNewLeftType then
        begin
          _VarCast(LTemp, Left, LNewLeftType);
          _VarCopy(Left, LTemp);
          if (Left.VType and varTypeMask) <> LNewLeftType then
            VarCastError;
        end;
        LRightHandler.BinaryOp(Left, Right, OpCode);
      end

      // simple then converts custom then
      else
      begin

        // convert the right side to the left side's type
        _VarCast(LTemp, Right, LLeftType);
        if (LTemp.VType and varTypeMask) <> LLeftType then
          VarCastError;
        _SimpleVarOp(Left, LTemp, OpCode);
      end;
    end

    // custom and something else
    else
    begin
      if not FindCustomVariantType(LLeftType, LLeftHandler) then
        VarInvalidOp;

      // does the left side like what is in the right side?
      if LLeftHandler.RightPromotion(Right, OpCode, LNewRightType) then
      begin

        // make the right side right
        if LRightType <> LNewRightType then
        begin
          _VarCast(LTemp, Right, LNewRightType);
          if (LTemp.VType and varTypeMask) <> LNewRightType then
            VarCastError;
          LLeftHandler.BinaryOp(Left, LTemp, OpCode);
        end

        // type is correct so lets go!
        else
          LLeftHandler.BinaryOp(Left, Right, OpCode);
      end

      // custom and simple and the right one can't convert the simple
      else if LRightType < CFirstUserType then
      begin

        // convert the left side to the right side's type
        if LLeftType <> LRightType then
        begin
          _VarCast(LTemp, Left, LRightType);
          _VarCopy(Left, LTemp);
          if (Left.VType and varTypeMask) <> LRightType then
            VarCastError;
        end;
        _SimpleVarOp(Left, Right, OpCode);
      end

      // custom and custom but the right one doesn't really exist (nasty but possible )
      else if not FindCustomVariantType(LRightType, LRightHandler) then
        VarInvalidOp

      // custom and custom and the right one can handle the left's type
      else if LRightHandler.LeftPromotion(Left, OpCode, LNewLeftType) then
      begin

        // convert the left side
        if LLeftType <> LNewLeftType then
        begin
          _VarCast(LTemp, Left, LNewLeftType);
          _VarCopy(Left, LTemp);
          if (Left.VType and varTypeMask) <> LNewLeftType then
            VarCastError;
        end;
        LRightHandler.BinaryOp(Left, Right, OpCode);
      end

      // custom and custom but neither type can deal with each other
      else
        VarInvalidOp;
    end;
  finally
    _VarClear(LTemp);
  end;
end;

procedure AnyOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);
var
  LTemp: TVarData;
begin
  if Left.VType = varAny then
    ChangeAnyProc(Left);
  if Right.VType = varAny then
  begin
    _VarInit(LTemp);
    try
      _VarCopy(LTemp, Right);
      ChangeAnyProc(LTemp);
      _VarOp(Left, LTemp, OpCode);
    finally
      _VarClear(LTemp);
    end;
  end
  else
    _VarOp(Left, Right, OpCode);
end;

procedure _SimpleVarOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);

  procedure Failure(const Prefix: string);
  begin
    Assert(False, Prefix + ': Lt = ' + IntToStr(Left.VType) + ' Rt = ' +
                  IntToStr(Right.VType) + ' Op = ' + IntToStr(OpCode));
  end;

  procedure AnyOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);
  var
    vTemp: TVarData;
  begin
    if Left.VType = varAny then
      ChangeAnyProc(Left);
    if Right.VType = varAny then
    begin
      _VarInit(vTemp);
      _VarCopy(vTemp, Right);
      try
        ChangeAnyProc(vTemp);
        _VarOp(Left, vTemp, OpCode);
      finally
        _VarClear(vTemp);
      end;
    end
    else
      _VarOp(Left, Right, OpCode);
  end;

  function CheckType(T: TVarType): TVarType;
  begin
    Result := T and varTypeMask;
    if Result > varLast then
      if Result = varString then
        Result := varOleStr
      else if Result = varAny then
        AnyOp(Left, Right, OpCode)
      else
        VarInvalidOp;
  end;

  procedure RealOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);
  var
    L, R: Double;
  begin
    L := _VarToReal(Left);
    R := _VarToReal(Right);
    case OpCode of
      opAdd      :  L := L + R;
      opSubtract :  L := L - R;
      opMultiply :  L := L * R;
      opDivide   :  L := L / R;
    else
      Failure('RealOp');
    end;
    Variant(Left) := L;
  end;

  procedure IntOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);
  var
    L, R: Integer;
    Overflow: Boolean;
  begin
    Overflow := False;
    L := _VarToInt(Left);
    R := _VarToInt(Right);
    case OpCode of
      opAdd        : asm
                       MOV  EAX, L
                       MOV  EDX, R
                       ADD  EAX, EDX
                       SETO Overflow
                       MOV  L, EAX
                     end;
      opSubtract   : asm
                       MOV  EAX, L
                       MOV  EDX, R
                       SUB  EAX, EDX
                       SETO Overflow
                       MOV  L, EAX
                     end;
      opMultiply   : asm
                       MOV  EAX, L
                       MOV  EDX, R
                       IMUL EDX
                       SETO Overflow
                       MOV  L, EAX
                     end;
      opDivide     : Failure('IntOp');
      opIntDivide  : L := L div R;
      opModulus    : L := L mod R;
      opShiftLeft  : L := L shl R;
      opShiftRight : L := L shr R;
      opAnd        : L := L and R;
      opOr         : L := L or R;
      opXor        : L := L xor R;
    else
      Failure('IntOp');
    end;

    if Overflow then
      RealOp(Left, Right, OpCode)
    else
      Variant(Left) := L;
  end;

  procedure Int64Op(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);
  var
    L, R: Int64;
    Overflow: Boolean;
  begin
    Overflow := False;
    L := _VarToInt64(Left);
    R := _VarToInt64(Right);
    case OpCode of
      opAdd, opSubtract, opMultiply:
        {$RANGECHECKS ON}
        try
          case OpCode of
            opAdd      : L := L + R;
            opSubtract : L := L - R;
            opMultiply : L := L * R;
          end;
        except
          on EOverflow do
            Overflow := True;
        end;
        {$RANGECHECKS OFF}
      opDivide     : Failure('Int64Op');
      opIntDivide  : L := L div R;
      opModulus    : L := L mod R;
      opShiftLeft  : L := L shl R;
      opShiftRight : L := L shr R;
      opAnd        : L := L and R;
      opOr         : L := L or R;
      opXor        : L := L xor R;
    else
      Failure('Int64Op');
    end;

    if Overflow then
      RealOp(Left, Right, OpCode)
    else
      Variant(Left) := L;
  end;

var
  L, R: TBaseType;
  C: Currency;
  D: Double;
begin
  L := BaseTypeMap[CheckType(Left.VType)];
  R := BaseTypeMap[CheckType(Right.VType)];
  case OpTypeMap[L, R] of
    btErr:
      VarInvalidOp;

    btNul:
      begin
        _VarClear(Left);
        Left.VType := varNull;
      end;

    btInt:
      if OpCode = opDivide then
        RealOp(Left, Right, OpCode)
      else
        IntOp(Left, Right, OpCode);

    btFlt:
      if OpCode >= opIntDivide then
        IntOp(Left, Right, OpCode)
      else
        RealOp(Left, Right, OpCode);

    btCur:
      case OpCode of
        opAdd      : Variant(Left) := _VarToCurr(Left) + _VarToCurr(Right);
        opSubtract : Variant(Left) := _VarToCurr(Left) - _VarToCurr(Right);
        opMultiply,
        opDivide   :
          begin
            if (L = btCur) and (R = btCur) then
            begin
              if OpCode = opMultiply then
                Variant(Left) := Left.VCurrency * Right.VCurrency
              else
                Variant(Left) := Left.VCurrency / Right.VCurrency;
            end
            else if R = btCur then
            begin   // L <> btCur
              if OpCode = opMultiply then
              begin
                C := _VarToReal(Left) * Right.VCurrency;
                Variant(Left) := C;
              end
              else
              begin
                D := _VarToCurr(Left) / Right.VCurrency;
                Variant(Left) := D;
              end;
            end
            else  // L = btCur, R <> btCur
            begin
              if OpCode = opMultiply then
              begin
                C := Left.VCurrency * _VarToReal(Right);
                Variant(Left) := C;
              end
              else
              begin
                C := Left.VCurrency / _VarToReal(Right);
                Variant(Left) := C;
              end;
            end;
          end;
      else
        IntOp(Left, Right, OpCode);
      end;

    btStr:
      if OpCode = opAdd then
        VarStrCat(Variant(Left), Variant(Right))
      else
        if OpCode >= opIntDivide then
          IntOp(Left, Right, OpCode)
        else
          RealOp(Left, Right, OpCode);

    btBol:
      if OpCode < opAnd then
        if OpCode >= opIntDivide then
          IntOp(Left, Right, OpCode)
        else
          RealOp(Left, Right, OpCode)
      else
      begin
        case OpCode of
          opAnd:  Variant(Left) := _VarToBool(Left) and _VarToBool(Right);
          opOr :  Variant(Left) := _VarToBool(Left) or _VarToBool(Right);
          opXor:  Variant(Left) := _VarToBool(Left) xor _VarToBool(Right);
        end;
      end;

    btDat:
      case OpCode of
        opAdd:
          begin
            RealOp(Left, Right, OpCode);
            Left.VType := varDate;
          end;
        opSubtract:
          begin
            RealOp(Left, Right, OpCode);
            if (L = btDat) and (R = btDat) then
              Left.VType := varDate;
          end;
        opMultiply,
        opDivide:
          RealOp(Left, Right, OpCode);
      else
        IntOp(Left, Right, OpCode);
      end;

    btI64:
      if OpCode = opDivide then
        RealOp(Left, Right, OpCode)
      else
        Int64Op(Left, Right, OpCode);
  else
    Failure('VarOp');
  end;
end;

(*
const
  C10000: Single = 10000;

procedure _SimpleVarOp(var Left: TVarData; const Right: TVarData; const OpCode: TVarOp);
asm
        PUSH    EBX
        PUSH    ESI
        PUSH    EDI
        MOV     EDI,EAX
        MOV     ESI,EDX
        MOV     EBX,ECX
        MOV     EAX,[EDI].TVarData.VType.Integer
        MOV     EDX,[ESI].TVarData.VType.Integer
        AND     EAX,varTypeMask
        AND     EDX,varTypeMask
        CMP     EAX,varLast
        JBE     @@1
        CMP     EAX,varString
        JNE     @@4
        MOV     EAX,varOleStr
@@1:    CMP     EDX,varLast
        JBE     @@2
        CMP     EDX,varString
        JNE     @@3
        MOV     EDX,varOleStr
@@2:    MOV     AL,BaseTypeMap.Byte[EAX]
        MOV     DL,BaseTypeMap.Byte[EDX]
        MOVZX   ECX,OpTypeMap.Byte[EAX*8+EDX]
        CALL    @VarOpTable.Pointer[ECX*4]
        POP     EDI
        POP     ESI
        POP     EBX
        RET
@@3:    MOV     EAX,EDX
@@4:    CMP     EAX,varAny
        JNE     @InvalidOp
        POP     EDI
        POP     ESI
        POP     EBX
        JMP     AnyOp

@VarOpTable:
        DD      @VarOpError
        DD      @VarOpNull
        DD      @VarOpInteger
        DD      @VarOpReal
        DD      @VarOpCurr
        DD      @VarOpString
        DD      @VarOpBoolean
        DD      @VarOpDate

@VarOpError:
        POP     EAX

@InvalidOp:
        POP     EDI
        POP     ESI
        POP     EBX
        JMP     VarInvalidOp

@VarOpNull:
        MOV     EAX,EDI
        CALL    _VarClear
        MOV     [EDI].TVarData.VType,varNull
        RET

@VarOpInteger:
        CMP     BL,opDivide
        JE      @RealOp

@IntegerOp:
        MOV     EAX,ESI
        CALL    _VarToInt
        PUSH    EAX
        MOV     EAX,EDI
        CALL    _VarToInt
        POP     EDX
        CALL    @IntegerOpTable.Pointer[EBX*4]
        MOV     EDX,EAX
        MOV     EAX,EDI
        JMP     _VarFromInt

@IntegerOpTable:
        DD      @IntegerAdd
        DD      @IntegerSub
        DD      @IntegerMul
        DD      0
        DD      @IntegerDiv
        DD      @IntegerMod
        DD      @IntegerShl
        DD      @IntegerShr
        DD      @IntegerAnd
        DD      @IntegerOr
        DD      @IntegerXor

@IntegerAdd:
        ADD     EAX,EDX
        JO      @IntToRealOp
        RET

@IntegerSub:
        SUB     EAX,EDX
        JO      @IntToRealOp
        RET

@IntegerMul:
        IMUL    EDX
        JO      @IntToRealOp
        RET

@IntegerDiv:
        MOV     ECX,EDX
        CDQ
        IDIV    ECX
        RET

@IntegerMod:
        MOV     ECX,EDX
        CDQ
        IDIV    ECX
        MOV     EAX,EDX
        RET

@IntegerShl:
        MOV     ECX,EDX
        SHL     EAX,CL
        RET

@IntegerShr:
        MOV     ECX,EDX
        SHR     EAX,CL
        RET

@IntegerAnd:
        AND     EAX,EDX
        RET

@IntegerOr:
        OR      EAX,EDX
        RET

@IntegerXor:
        XOR     EAX,EDX
        RET

@IntToRealOp:
        POP     EAX
        JMP     @RealOp

@VarOpReal:
        CMP     BL,opIntDivide
        JAE     @IntegerOp

@RealOp:
        MOV     EAX,ESI
        CALL    _VarToReal
        SUB     ESP,12
        FSTP    TBYTE PTR [ESP]
        MOV     EAX,EDI
        CALL    _VarToReal
        FLD     TBYTE PTR [ESP]
        ADD     ESP,12
        CALL    @RealOpTable.Pointer[EBX*4]

@RealResult:
        MOV     EAX,EDI
        JMP     _VarFromReal

@VarOpCurr:
        CMP     BL,opIntDivide
        JAE     @IntegerOp
        CMP     BL,opMultiply
        JAE     @CurrMulDvd
        MOV     EAX,ESI
        CALL    _VarToCurr
        SUB     ESP,12
        FSTP    TBYTE PTR [ESP]
        MOV     EAX,EDI
        CALL    _VarToCurr
        FLD     TBYTE PTR [ESP]
        ADD     ESP,12
        CALL    @RealOpTable.Pointer[EBX*4]

@CurrResult:
        MOV     EAX,EDI
        JMP     _VarFromCurr

@CurrMulDvd:
        CMP     DL,btCur
        JE      @CurrOpCurr
        MOV     EAX,ESI
        CALL    _VarToReal
        FILD    [EDI].TVarData.VCurrency
        FXCH
        CALL    @RealOpTable.Pointer[EBX*4]
        JMP     @CurrResult

@CurrOpCurr:
        CMP     BL,opDivide
        JE      @CurrDvdCurr
        CMP     AL,btCur
        JE      @CurrMulCurr
        MOV     EAX,EDI
        CALL    _VarToReal
        FILD    [ESI].TVarData.VCurrency
        FMUL
        JMP     @CurrResult

@CurrMulCurr:
        FILD    [EDI].TVarData.VCurrency
        FILD    [ESI].TVarData.VCurrency
        FMUL
        FDIV    C10000
        JMP     @CurrResult

@CurrDvdCurr:
        MOV     EAX,EDI
        CALL    _VarToCurr
        FILD    [ESI].TVarData.VCurrency
        FDIV
        JMP     @RealResult

@RealOpTable:
        DD      @RealAdd
        DD      @RealSub
        DD      @RealMul
        DD      @RealDvd

@RealAdd:
        FADD
        RET

@RealSub:
        FSUB
        RET

@RealMul:
        FMUL
        RET

@RealDvd:
        FDIV
        RET

@VarOpString:
        CMP     BL,opAdd
        JNE     @VarOpReal
        MOV     EAX,EDI
        MOV     EDX,ESI
        JMP     VarStrCat

@VarOpBoolean:
        CMP     BL,opAnd
        JB      @VarOpReal
        MOV     EAX,ESI
        CALL    _VarToBool
        PUSH    EAX
        MOV     EAX,EDI
        CALL    _VarToBool
        POP     EDX
        CALL    @IntegerOpTable.Pointer[EBX*4]
        MOV     EDX,EAX
        MOV     EAX,EDI
        JMP     _VarFromBool

@VarOpDate:
        CMP     BL,opSubtract
        JA      @VarOpReal
        JB      @DateOp
        MOV     AH,DL
        CMP     AX,btDat+btDat*256
        JE      @RealOp

@DateOp:
        CALL    @RealOp
        MOV     [EDI].TVarData.VType,varDate
        RET
end;
*)

(*function VarCompareString(const S1, S2: string): Integer;
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

function VarCmpStr(const V1, V2: Variant): Integer;
begin
  Result := VarCompareString(V1, V2);
end;*)

function SimpleVarCmp(const Left, Right: TVarData): TVarCompareResult; forward;

function VarCompare(const Left, Right: TVarData; const OpCode: TVarOp): TVarCompareResult;
const
  CBooleanToRelationship: array [opCmpEQ..opCmpGE, Boolean] of TVarCompareResult =
   // False          True
    ((crLessThan,    crEqual),        // opCmpEQ = 14;
     (crEqual,       crLessThan),     // opCmpNE = 15;
     (crEqual,       crLessThan),     // opCmpLT = 16;
     (crGreaterThan, crLessThan),     // opCmpLE = 17;
     (crEqual,       crGreaterThan),  // opCmpGT = 18;
     (crLessThan,    crGreaterThan)); // opCmpGE = 19;
var
  LLeftType, LRightType, LNewLeftType, LNewRightType: TVarType;
  LLeftHandler, LRightHandler: TCustomVariantType;
  LTemp, LLeft: TVarData;
begin
  LLeftType := TVarData(Left).VType and varTypeMask;
  LRightType := TVarData(Right).VType and varTypeMask;
  Result := crEqual;

  // just in case we need to
  _VarInit(LTemp);
  try

    // simple and ???
    if LLeftType < CFirstUserType then
    begin

      // simple and simple
      if LRightType < CFirstUserType then
      begin

        // are ANYs involved?
        if (LLeftType = varAny) or (LRightType = varAny) then
        begin
          _VarInit(LLeft);
          try

            // resolve the left side into a normal simple type
            _VarCopy(LLeft, Left);
            if LLeftType = varAny then
              ChangeAnyProc(LLeft);

            // does the right side need to be reduced to a simple type
            if LRightType = varAny then
            begin
              _VarCopy(LTemp, Right);
              ChangeAnyProc(LTemp);
              Result := VarCompare(LLeft, LTemp, OpCode);
            end

            // right side is fine as is
            else
              Result := VarCompare(LLeft, Right, OpCode);
          finally
            _VarClear(LLeft);
          end;
        end

        // just simple vs simple
        else
          Result := SimpleVarCmp(Left, Right);
      end

      // simple and custom but the custom doesn't really exist (nasty but possible )
      else if not FindCustomVariantType(LRightType, LRightHandler) then
        VarInvalidOp

      // does the custom want to take over?
      else if LRightHandler.LeftPromotion(Left, opCompare, LNewLeftType) then
      begin

        // convert the left side
        if Left.VType <> LNewLeftType then
        begin
          _VarCast(LTemp, Left, LNewLeftType);
          if (LTemp.VType and varTypeMask) <> LNewLeftType then
            VarCastError;
          Result := CBooleanToRelationship[OpCode, LRightHandler.CompareOp(LTemp, Right, OpCode)];
        end

        // already that type!
        else
          Result := CBooleanToRelationship[OpCode, LRightHandler.CompareOp(Left, Right, OpCode)];
      end

      // simple then converts custom then
      else
      begin
        // convert the right side to the left side's type
        _VarCast(LTemp, Right, LLeftType);
        if (LTemp.VType and varTypeMask) <> LLeftType then
          VarCastError;
        Result := SimpleVarCmp(Left, LTemp)
      end;
    end

    // custom and something else
    else
    begin
      if not FindCustomVariantType(LLeftType, LLeftHandler) then
        VarInvalidOp

      // does the left side like what is in the right side?
      else if LLeftHandler.RightPromotion(Right, opCompare, LNewRightType) then
      begin

        // make the right side right
        if LRightType <> LNewRightType then
        begin
          _VarCast(LTemp, Right, LNewRightType);
          if (LTemp.VType and varTypeMask) <> LNewRightType then
            VarCastError;
          Result := CBooleanToRelationship[OpCode, LLeftHandler.CompareOp(Left, LTemp, OpCode)];
        end

        // already that type
        else
          Result := CBooleanToRelationship[OpCode, LLeftHandler.CompareOp(Left, Right, OpCode)];
      end

      // custom and simple
      else if LRightType < CFirstUserType then
      begin

        // convert the left side to the right side's type
        _VarCast(LTemp, Left, LRightType);
        if (LTemp.VType and varTypeMask) <> LRightType then
          VarCastError;
        Result := SimpleVarCmp(LTemp, Right)
      end

      // custom and custom but the right one doesn't really exist (nasty but possible )
      else if not FindCustomVariantType(LRightType, LRightHandler) then
        VarInvalidOp

      // custom and custom and the right one can handle the left's type
      else if LRightHandler.LeftPromotion(Left, opCompare, LNewLeftType) then
      begin

        // convert the left side
        if LLeftType <> LNewLeftType then
        begin
          _VarCast(LTemp, Left, LNewLeftType);
          if (LTemp.VType and varTypeMask) <> LNewLeftType then
            VarCastError;
          Result := CBooleanToRelationship[OpCode, LRightHandler.CompareOp(LTemp, Right, OpCode)];
        end

        // it's already correct!
        else
          Result := CBooleanToRelationship[OpCode, LRightHandler.CompareOp(Left, Right, OpCode)];
      end

      // custom and custom but neither type can deal with each other
      else
        VarInvalidOp;
    end;

  // we may have to
  finally
    _VarClear(LTemp);
  end;
end;

procedure _VarCmp(const Left, Right: Variant; const OpCode: TVarOp); // compiler requires result in flags
asm
        //  IN:  EAX = Left
        //  IN:  EDX = Right
        //  OUT:  Flags register indicates less than, greater than, or equal
        CALL    VarCompare
        CMP     AL, crEqual
end;

function SimpleVarCmp(const Left, Right: TVarData): TVarCompareResult;

  function CheckType(T: TVarType): TVarType;
  begin
    Result := T and varTypeMask;
    if Result > varLast then
      if Result = varString then
        Result := varOleStr
      else
        VarInvalidOp;
  end;

  function IntCompare(A, B: Integer): TVarCompareResult;
  begin
    if A < B then
      Result := crLessThan
    else if A > B then
      Result := crGreaterThan
    else
      Result := crEqual;
  end;

  function Int64Compare(const A, B: Int64): TVarCompareResult;
  begin
    if A < B then
      Result := crLessThan
    else if A > B then
      Result := crGreaterThan
    else
      Result := crEqual;
  end;

  function RealCompare(const A, B: Double): TVarCompareResult;
  begin
    if A < B then
      Result := crLessThan
    else if A > B then
      Result := crGreaterThan
    else
      Result := crEqual;
  end;

  // keep string temps out of the main proc
  function StringCompare(const L, R: TVarData): TVarCompareResult;
  var
    A, B: string;
  begin
    _VarToLStr(A, L);
    _VarToLStr(B, R);
    Result := IntCompare(StrComp(PChar(A), PChar(B)), 0);
  end;

var
  L, R: TBaseType;
begin
  Result := crEqual;
  L := BaseTypeMap[CheckType(Left.VType)];
  R := BaseTypeMap[CheckType(Right.VType)];
  case OpTypeMap[L, R] of
    btErr:  VarInvalidOp;
    btNul:  Result := IntCompare(Ord(L), Ord(R));
    btInt:  Result := IntCompare(_VarToInt(Left), _VarToInt(Right)); //<<<<============================
    btI64:  Result := Int64Compare(_VarToInt64(Left), _VarToInt64(Right));
    btFlt,
    btDat:  Result := RealCompare(_VarToReal(Left), _VarToReal(Right));
    btCur:  Result := RealCompare(_VarToCurr(Left), _VarToCurr(Right));
    btStr:  Result := StringCompare(Left, Right);
    btBol:  Result := IntCompare(Integer(_VarToBool(Left)), Integer(_VarToBool(Right)));
  else
    assert(False, 'VarCmp L = ' + IntToStr(Left.VType) + ' R = ' + IntToStr(Right.VType));
  end;
end;

(*
function SimpleVarCmp(const Left, Right: TVarData): TVarCompareResult;
asm
        PUSH    ESI
        PUSH    EDI
        MOV     EDI,EAX
        MOV     ESI,EDX
        MOV     EAX,[EDI].TVarData.VType.Integer
        MOV     EDX,[ESI].TVarData.VType.Integer
        AND     EAX,varTypeMask
        AND     EDX,varTypeMask
        CMP     EAX,varLast
        JBE     @@1
        CMP     EAX,varString
        JNE     @VarCmpError
        MOV     EAX,varOleStr
@@1:    CMP     EDX,varLast
        JBE     @@2
        CMP     EDX,varString
        JNE     @VarCmpError
        MOV     EDX,varOleStr
@@2:    MOV     AL,BaseTypeMap.Byte[EAX]
        MOV     DL,BaseTypeMap.Byte[EDX]
        MOVZX   ECX,OpTypeMap.Byte[EAX*8+EDX]
        JMP     @VarCmpTable.Pointer[ECX*4]

@VarCmpTable:
        DD      @VarCmpError
        DD      @VarCmpNull
        DD      @VarCmpInteger
        DD      @VarCmpReal
        DD      @VarCmpCurr
        DD      @VarCmpString
        DD      @VarCmpBoolean
        DD      @VarCmpDate

@VarCmpError:
        POP     EDI
        POP     ESI
        JMP     VarInvalidOp

@VarCmpNull:
        CMP     AL,DL
        JMP     @Exit

@VarCmpInteger:
        MOV     EAX,ESI
        CALL    _VarToInt
        XCHG    EAX,EDI
        CALL    _VarToInt
        CMP     EAX,EDI
        JMP     @Exit

@VarCmpReal:
@VarCmpDate:
        MOV     EAX,EDI
        CALL    _VarToReal
        SUB     ESP,12
        FSTP    TBYTE PTR [ESP]
        MOV     EAX,ESI
        CALL    _VarToReal
        FLD     TBYTE PTR [ESP]
        ADD     ESP,12

@RealCmp:
        FCOMPP
        FNSTSW  AX
        MOV     AL,AH   { Move CF into SF }
        AND     AX,4001H
        ROR     AL,1
        OR      AH,AL
        SAHF
        JMP     @Exit

@VarCmpCurr:
        MOV     EAX,EDI
        CALL    _VarToCurr
        SUB     ESP,12
        FSTP    TBYTE PTR [ESP]
        MOV     EAX,ESI
        CALL    _VarToCurr
        FLD     TBYTE PTR [ESP]
        ADD     ESP,12
        JMP     @RealCmp

@VarCmpString:
        MOV     EAX,EDI
        MOV     EDX,ESI
        CALL    VarCmpStr
        CMP     EAX,0
        JMP     @Exit

@VarCmpBoolean:
        MOV     EAX,ESI
        CALL    _VarToBool
        XCHG    EAX,EDI
        CALL    _VarToBool
        MOV     EDX,EDI
        CMP     AL,DL

@Exit:
        MOV     AL, crLessThan
        JL      @Exit2
        MOV     AL, crEqual
        JE      @Exit2
        MOV     AL, crGreaterThan
@Exit2:
        AND     EAX, $FF
        POP     EDI
        POP     ESI
end;
*)

procedure _SimpleVarNeg(var V: TVarData); forward;

procedure _VarNeg(var V: TVarData);
var
  LType: TVarType;
  LHandler: TCustomVariantType;
begin
  LType := V.VType and varTypeMask;
  if LType < CFirstUserType then
    _SimpleVarNeg(V)
  else
    if FindCustomVariantType(LType, LHandler) then
      LHandler.UnaryOp(V, opNegate)
    else
      VarInvalidOp;
end;

procedure _SimpleVarNeg(var V: TVarData);
var
  T: TVarType;
begin
  T := V.VType and varTypeMask;
  if T > varLast then
    if T = varString then
      T := varOleStr
    else
      VarInvalidOp;

  case BaseTypeMap[T] of
    btErr : VarInvalidOp;
    btNul : ;  // do nothing
    btBol,
    btInt : _VarFromInt(V, -_VarToInt(V), -4);      //<<<<============================
    btI64 : _VarFromInt64(V, -_VarToInt64(V));
    btStr,
    btFlt : Variant(V) := -_VarToReal(V);
    btCur : V.VCurrency := -V.VCurrency;
    btDat : V.VDate := -V.VDate;
  end;
end;

(*
procedure _SimpleVarNeg(var V: TVarData);
asm
        MOV     EDX,[EAX].TVarData.VType.Integer
        AND     EDX,varTypeMask
        CMP     EDX,varLast
        JBE     @@1
        CMP     EDX,varString
        JNE     @VarNegError
        MOV     EDX,varOleStr
@@1:    MOV     DL,BaseTypeMap.Byte[EDX]
        JMP     @VarNegTable.Pointer[EDX*4]
@@2:    CMP     EAX,varAny
        JNE     @VarNegError
        PUSH    EAX
        CALL    [ChangeAnyProc]
        POP     EAX
        JMP     _VarNeg

@VarNegTable:
        DD      @VarNegError
        DD      @VarNegNull
        DD      @VarNegInteger
        DD      @VarNegReal
        DD      @VarNegCurr
        DD      @VarNegReal
        DD      @VarNegInteger
        DD      @VarNegDate

@VarNegError:
        JMP     VarInvalidOp

@VarNegNull:
        RET

@VarNegInteger:
        PUSH    EAX
        CALL    _VarToInt
        NEG     EAX
        MOV     EDX,EAX
        POP     EAX
        JMP     _VarFromInt

@VarNegReal:
        PUSH    EAX
        CALL    _VarToReal
        FCHS
        POP     EAX
        JMP     _VarFromReal

@VarNegCurr:
        FILD    [EAX].TVarData.VCurrency
        FCHS
        FISTP   [EAX].TVarData.VCurrency
        FWAIT
        RET

@VarNegDate:
        FLD     [EAX].TVarData.VDate
        FCHS
        FSTP    [EAX].TVarData.VDate
        FWAIT
end;
*)

procedure _SimpleVarNot(var V: TVarData); forward;

procedure _VarNot(var V: TVarData);
var
  LType: TVarType;
  LHandler: TCustomVariantType;
begin
  LType := V.VType and varTypeMask;
  if LType < CFirstUserType then
    _SimpleVarNot(V)
  else
    if FindCustomVariantType(LType, LHandler) then
      LHandler.UnaryOp(V, opNot)
    else
      VarInvalidOp;
end;

procedure _SimpleVarNot(var V: TVarData);
var
  T: TVarType;
begin
  T := V.VType and varTypeMask;
  case T of
    varEmpty   : VarInvalidOp;
    varBoolean : V.VBoolean := not V.VBoolean;
    varNull    : ; // do nothing
    varAny     :
      begin
        ChangeAnyProc(V);
        _VarNot(V);
      end;
  else
    if (T = varInt64) then
      _VarFromInt64(V, not _VarToInt64(V))
    else if (T = varString) or (T <= varLast) then
      _VarFromInt(V, not _VarToInt(V), -4)
    else
      VarInvalidOp;
  end;
end;

(*
procedure _SimpleVarNot(var V: TVarData);
asm
        MOV     EDX,[EAX].TVarData.VType.Integer
        AND     EDX,varTypeMask
        JE      @@2
        CMP     EDX,varBoolean
        JE      @@3
        CMP     EDX,varNull
        JE      @@4
        CMP     EDX,varLast
        JBE     @@1
        CMP     EDX,varString
        JE      @@1
        CMP     EAX,varAny
        JNE     @@2
        PUSH    EAX
        CALL    [ChangeAnyProc]
        POP     EAX
        JMP     _VarNot
@@1:    PUSH    EAX
        CALL    _VarToInt
        NOT     EAX
        MOV     EDX,EAX
        POP     EAX
        JMP     _VarFromInt
@@2:    JMP     VarInvalidOp
@@3:    MOV     DX,[EAX].TVarData.VBoolean
        NEG     DX
        SBB     EDX,EDX
        NOT     EDX
        MOV     [EAX].TVarData.VBoolean,DX
@@4:
end;
*)

procedure _VarCopyNoInd; // ARGS PLEASE!
asm
        JMP     VarCopyNoInd
end;

procedure _VarAddRef(var V: Variant);
asm
        CMP     [EAX].TVarData.VType,varOleStr
        JB      @@1
        PUSH    [EAX].Integer[12]
        PUSH    [EAX].Integer[8]
        PUSH    [EAX].Integer[4]
        PUSH    [EAX].Integer[0]
        MOV     [EAX].TVarData.VType,varEmpty
        MOV     EDX,ESP
        CALL    _VarCopy
        ADD     ESP,16
@@1:
end;

function VarType(const V: Variant): TVarType;
begin
  Result := TVarData(V).VType;
end;

function VarAsType(const V: Variant; AVarType: TVarType): Variant;
begin
  _VarCast(TVarData(Result), TVarData(V), AVarType);
end;

function VarIsType(const V: Variant; AVarType: TVarType): Boolean;
begin
  Result := (TVarData(V).VType and varTypeMask) = AVarType;
end;

function VarIsType(const V: Variant; const AVarTypes: array of TVarType): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := Low(AVarTypes) to High(AVarTypes) do
    if (TVarData(V).VType and varTypeMask) = AVarTypes[I] then
    begin
      Result := True;
      Break;
    end;
end;

function VarIsClear(const V: Variant): Boolean;
var
  LSourceType: TVarType;
  LSourceHandler: TCustomVariantType;
begin
  Result := False;
  LSourceType := TVarData(V).VType and varTypeMask;
  if LSourceType < CFirstUserType then
    with TVarData(V) do
      Result := (VType = varEmpty) or
                (((VType = varDispatch) or (VType = varUnknown)) and
                  (VDispatch = nil))
  else if FindCustomVariantType(LSourceType, LSourceHandler) then
    Result := LSourceHandler.IsClear(TVarData(V))
  else
    VarInvalidOp;
end;

function VarTypeIsCustom(const AVarType: TVarType): Boolean;
var
  LSourceHandler: TCustomVariantType;
begin
  Result := ((AVarType and varTypeMask) >= CFirstUserType) and
            FindCustomVariantType((AVarType and varTypeMask), LSourceHandler);
end;

function VarIsCustom(const V: Variant): Boolean;
begin
  Result := VarTypeIsCustom(TVarData(V).VType);
end;

function VarTypeIsOrdinal(const AVarType: TVarType): Boolean;
begin
  Result := (AVarType and varTypeMask) in [varSmallInt, varInteger, varBoolean,
                                        varShortInt, varByte, varWord,
                                        varLongWord, varInt64];
end;

function VarIsOrdinal(const V: Variant): Boolean;
begin
  Result := VarTypeIsOrdinal(TVarData(V).VType);
end;

function VarTypeIsFloat(const AVarType: TVarType): Boolean;
begin
  Result := (AVarType and varTypeMask) in [varSingle, varDouble, varCurrency];
end;

function VarIsFloat(const V: Variant): Boolean;
begin
  Result := VarTypeIsFloat(TVarData(V).VType);
end;

function VarTypeIsNumeric(const AVarType: TVarType): Boolean;
begin
  Result := VarTypeIsOrdinal(AVarType) or VarTypeIsFloat(AVarType);
end;

function VarIsNumeric(const V: Variant): Boolean;
begin
  Result := VarTypeIsNumeric(TVarData(V).VType);
end;

function VarTypeIsStr(const AVarType: TVarType): Boolean;
begin
  Result := ((AVarType and varTypeMask) = varOleStr) or
            ((AVarType and varTypeMask) = varString);
end;

function VarIsStr(const V: Variant): Boolean;
begin
  Result := VarTypeIsStr(TVarData(V).VType);
end;

function VarIsEmpty(const V: Variant): Boolean;
begin
  Result := TVarData(V).VType = varEmpty;
end;

procedure VarCheckEmpty(const V: Variant);
begin
  if VarIsEmpty(V) then
    raise EVariantError.Create(SVarIsEmpty);
end;

function VarIsNull(const V: Variant): Boolean;
begin
  Result := TVarData(V).VType = varNull;
end;

function VarToStr(const V: Variant): string;
begin
  Result := VarToStrDef(V, '');
end;

function VarToStrDef(const V: Variant; const ADefault: string): string;
begin
  if TVarData(V).VType <> varNull then
    Result := V
  else
    Result := ADefault;
end;

function VarToWideStr(const V: Variant): WideString;
begin
  Result := VarToWideStrDef(V, '');
end;

function VarToWideStrDef(const V: Variant; const ADefault: WideString): WideString;
begin
  if TVarData(V).VType <> varNull then
    Result := V
  else
    Result := ADefault;
end;

function VarFromDateTime(const DateTime: TDateTime): Variant;
begin
  _VarClear(TVarData(Result));
  TVarData(Result).VType := varDate;
  TVarData(Result).VDate := DateTime;
end;

function VarToDateTime(const V: Variant): TDateTime;
var
  Temp: TVarData;
begin
  _VarInit(Temp);
  _VarCast(Temp, TVarData(V), varDate);
  Result := Temp.VDate;
end;

function VarInRange(const AValue, AMin, AMax: Variant): Boolean;
begin
  Result := (AValue >= AMin) and (AValue <= AMax);
end;

function VarEnsureRange(const AValue, AMin, AMax: Variant): Variant;
begin
  Result := AValue;
  if Result < AMin then
    Result := AMin;
  if Result > AMax then
    Result := AMax;
end;

function VarSameValue(const A, B: Variant): Boolean;
begin
  if TVarData(A).VType = varEmpty then
    Result := TVarData(B).VType = varEmpty
  else if TVarData(A).VType = varNull then
    Result := TVarData(B).VType = varNull
  else if TVarData(B).VType in [varEmpty, varNull] then
    Result := False
  else
    Result := A = B;
end;

function VarCompareValue(const A, B: Variant): TVariantRelationship;
const
  CTruth: array [Boolean] of TVariantRelationship = (vrNotEqual, vrEqual);
begin
  if TVarData(A).VType = varEmpty then
    Result := CTruth[TVarData(B).VType = varEmpty]
  else if TVarData(A).VType = varNull then
    Result := CTruth[TVarData(B).VType = varNull]
  else if TVarData(B).VType in [varEmpty, varNull] then
    Result := vrNotEqual
  else if A = B then
    Result := vrEqual
  else if A < B then
    Result := vrLessThan
  else
    Result := vrGreaterThan;
end;

function VarIsEmptyParam(const V: Variant): Boolean;
begin
  Result := (TVarData(V).VType = varError) and
            (TVarData(V).VError = $80020004); {DISP_E_PARAMNOTFOUND}
end;

procedure SetClearVarToEmptyParam(var V: TVarData);
begin
  V.VType := varError;
  V.VError := $80020004; {DISP_E_PARAMNOTFOUND}
end;

function VarIsByRef(const V: Variant): Boolean;
begin
  Result := (TVarData(V).VType and varByRef) <> 0;
end;

function VarSupports(const V: Variant; const IID: TGUID; out Intf): Boolean;
var
  LInstance: IVarInstanceReference;
begin
  Result := (Supports(V, IVarInstanceReference, LInstance) and
             Supports(LInstance.GetInstance(TVarData(V)), IID, Intf)) or
            Supports(V, IID, Intf);
end;

function VarSupports(const V: Variant; const IID: TGUID): Boolean;
var
  LInstance: IVarInstanceReference;
  LInterface: IInterface;
begin
  Result := (Supports(V, IVarInstanceReference, LInstance) and
             Supports(LInstance.GetInstance(TVarData(V)), IID, LInterface)) or
            Supports(V, IID, LInterface);
end;


function _WriteVariant(var T: Text; const V: Variant; Width: Integer): Pointer;
var
  S: string;
begin
  if (TVarData(V).VType <> varEmpty) and (TVarData(V).VType <> varNull) then
    S := V;
  Write(T, S: Width);
  Result := @T;
end;

function _Write0Variant(var T: Text; const V: Variant): Pointer;
begin
  Result := _WriteVariant(T, V, 0);
end;

{ ----------------------------------------------------- }
{       Variant array support                           }
{ ----------------------------------------------------- }

function GetVarDataArrayInfo(const AVarData: TVarData; out AVarType: TVarType;
  out AVarArray: PVarArray): Boolean;
var
  LVarDataPtr: PVarData;
begin
  // original type
  LVarDataPtr := @AVarData;
  AVarType := LVarDataPtr^.VType;

  // if original type is not an array but is pointing to one
  if (AVarType = (varByRef or varVariant)) and
     ((PVarData(LVarDataPtr^.VPointer)^.VType and varArray) <> 0) then
  begin
    LVarDataPtr := PVarData(LVarDataPtr^.VPointer);
    AVarType := LVarDataPtr^.VType;
  end;

  // make sure we are pointing to an array then
  Result := (AVarType and varArray) <> 0;

  // figure out the array data pointer
  if Result then
    if (AVarType and varByRef) <> 0 then
      AVarArray := PVarArray(LVarDataPtr^.VPointer^)
    else
      AVarArray := LVarDataPtr^.VArray
  else
    AVarArray := nil;
end;

const
  tkDynArray  = 17;

function VarArrayCreate(const Bounds: array of Integer;
  AVarType: TVarType): Variant;
var
  I, DimCount: Integer;
  VarArrayRef: PVarArray;
  VarBounds: array[0..63] of TVarArrayBound;
begin
  if (not Odd(High(Bounds)) or (High(Bounds) > 127)) or
     (not VarTypeIsValidArrayType(AVarType)) then
    System.Error(System.reVarArrayCreate);

  DimCount := (High(Bounds) + 1) div 2;
  for I := 0 to DimCount - 1 do
    with VarBounds[I] do
    begin
      LowBound := Bounds[I * 2];
      ElementCount := Bounds[I * 2 + 1] - LowBound + 1;
    end;

  VarArrayRef := SafeArrayCreate(AVarType, DimCount, PVarArrayBoundArray(@VarBounds)^);
  if VarArrayRef = nil then
    System.Error(System.reVarArrayCreate);

  _VarClear(TVarData(Result));

  TVarData(Result).VType := AVarType or varArray;
  TVarData(Result).VArray := VarArrayRef;
end;

function VarArrayOf(const Values: array of Variant): Variant;
var
  I: Integer;
begin
  Result := VarArrayCreate([0, High(Values)], varVariant);
  for I := 0 to High(Values) do
    Result[I] := Values[I];
end;

procedure _VarArrayRedim(var A: Variant; HighBound: Integer);
var
  VarBound: TVarArrayBound;
  LVarType: TVarType;
  LVarArray: PVarArray;
begin
  if not GetVarDataArrayInfo(TVarData(A), LVarType, LVarArray) then
    System.Error(System.reVarNotArray);

  with LVarArray^ do
    VarBound.LowBound := Bounds[DimCount - 1].LowBound;

  VarBound.ElementCount := HighBound - VarBound.LowBound + 1;

  if SafeArrayRedim(LVarArray, VarBound) <> VAR_OK then
    System.Error(System.reVarArrayCreate);
end;

function GetVarArray(const A: Variant): PVarArray;
var
  LVarType: TVarType;
begin
  if not GetVarDataArrayInfo(TVarData(A), LVarType, Result) then
    System.Error(System.reVarNotArray);
end;

function VarArrayDimCount(const A: Variant): Integer;
var
  LVarType: TVarType;
  LVarArray: PVarArray;
begin
  if GetVarDataArrayInfo(TVarData(A), LVarType, LVarArray) then
    Result := LVarArray^.DimCount
  else
    Result := 0;
end;

function VarArrayLowBound(const A: Variant; Dim: Integer): Integer;
begin
  if SafeArrayGetLBound(GetVarArray(A), Dim, Result) <> VAR_OK then
    System.Error(System.reVarArrayBounds);
end;

function VarArrayHighBound(const A: Variant; Dim: Integer): Integer;
begin
  if SafeArrayGetUBound(GetVarArray(A), Dim, Result) <> VAR_OK then
    System.Error(System.reVarArrayBounds);
end;

function VarArrayLock(const A: Variant): Pointer;
begin
  if SafeArrayAccessData(GetVarArray(A), Result) <> VAR_OK then
    System.Error(System.reVarNotArray);
end;

procedure VarArrayUnlock(const A: Variant);
begin
  if SafeArrayUnaccessData(GetVarArray(A)) <> VAR_OK then
    System.Error(System.reVarNotArray);
end;

function VarArrayRef(const A: Variant): Variant;
begin
  if (TVarData(A).VType and varArray) = 0 then
    System.Error(System.reVarNotArray);

  _VarClear(TVarData(Result));

  TVarData(Result).VType := TVarData(A).VType or varByRef;
  if (TVarData(A).VType and varByRef) <> 0 then
    TVarData(Result).VPointer := TVarData(A).VPointer
  else
    TVarData(Result).VPointer := @TVarData(A).VArray;
end;

function VarIsArray(const A: Variant): Boolean;
begin
  Result := VarIsArray(A, False);
end;

function VarIsArray(const A: Variant; AResolveByRef: Boolean): Boolean;
var
  LVarType: TVarType;
  LVarArray: PVarArray;
begin
  if AResolveByRef then
    Result := GetVarDataArrayInfo(TVarData(A), LVarType, LVarArray)
  else
    Result := (TVarData(A).VType and varArray) = varArray;
end;

function VarTypeIsValidArrayType(const AVarType: TVarType): Boolean;
var
  LVarType: TVarType;
begin
  LVarType := AVarType and varTypeMask;
  Result := (LVarType in [CMinArrayVarType..CMaxArrayVarType]) and
            CVarTypeToElementInfo[LVarType].ValidBase;
end;

function VarTypeIsValidElementType(const AVarType: TVarType): Boolean;
var
  LVarType: TVarType;
begin
  LVarType := AVarType and varTypeMask;
  Result := ((LVarType in [CMinArrayVarType..CMaxArrayVarType]) and
             CVarTypeToElementInfo[LVarType].ValidElement) or
            VarTypeIsCustom(LVarType);
end;

function _VarArrayGet(var A: Variant; IndexCount: Integer;
  const Indices: TVarArrayCoorArray): Variant; cdecl;
var
  LVarType: TVarType;
  LVarArrayPtr: PVarArray;
  LArrayVarType: Integer;
  P: Pointer;
  LResult: TVarData;
begin
  if not GetVarDataArrayInfo(TVarData(A), LVarType, LVarArrayPtr) then
    System.Error(System.reVarNotArray);

  if LVarArrayPtr^.DimCount <> IndexCount then
    System.Error(System.reVarArrayBounds);

  // use a temp for result just in case the result points back to source, icky
  _VarInit(LResult);
  try
    LArrayVarType := LVarType and varTypeMask;
    if LArrayVarType = varVariant then
    begin
      if SafeArrayPtrOfIndex(LVarArrayPtr, @Indices, P) <> VAR_OK then
        System.Error(System.reVarArrayBounds);
      _VarCopy(LResult, PVarData(P)^);
    end
    else
    begin
      if SafeArrayGetElement(LVarArrayPtr, @Indices, @TVarData(LResult).VPointer) <> VAR_OK then
        System.Error(System.reVarArrayBounds);
      TVarData(LResult).VType := LArrayVarType;
    end;

    // copy the temp result over to result
    _VarCopy(TVarData(Result), LResult);
  finally
    _VarClear(LResult);
  end;
end;

function VarArrayGet(const A: Variant; const Indices: array of Integer): Variant;
asm
        {     ->EAX     Pointer to A            }
        {       EDX     Pointer to Indices      }
        {       ECX     High bound of Indices   }
        {       [EBP+8] Pointer to result       }

        PUSH    EBX

        MOV     EBX,ECX
        INC     EBX
        JLE     @@endLoop
@@loop:
        PUSH    [EDX+ECX*4].Integer
        DEC     ECX
        JNS     @@loop
@@endLoop:
        PUSH    EBX
        PUSH    EAX
        MOV     EAX,[EBP+8]
        PUSH    EAX
        CALL    _VarArrayGet
        LEA     ESP,[ESP+EBX*4+3*4]

        POP     EBX
end;

procedure _VarArrayPut(var A: Variant; const Value: Variant;
  IndexCount: Integer; const Indices: TVarArrayCoorArray); cdecl;
type
  TAnyPutArrayProc = procedure (var A: Variant; const Value: Variant; Index: Integer);
var
  LVarType: TVarType;
  LVarArrayPtr: PVarArray;
  LValueType: TVarType;
  LValueArrayPtr: PVarArray;
  LArrayVarType: Integer;
  P: Pointer;
  Temp: TVarData;
begin
  if not GetVarDataArrayInfo(TVarData(A), LVarType, LVarArrayPtr) then
    System.Error(System.reVarNotArray);

  if not GetVarDataArrayInfo(TVarData(Value), LValueType, LValueArrayPtr) and
     not VarTypeIsValidElementType(LValueType) and
     (LValueType <> varString) then
    System.Error(System.reVarTypeCast);

  if LVarArrayPtr^.DimCount <> IndexCount then
    System.Error(System.reVarArrayBounds);

  LArrayVarType := LVarType and varTypeMask;

  if (LArrayVarType = varVariant) and
     ((LValueType <> varString) or
      VarTypeIsCustom(LValueType)) then
  begin
    if SafeArrayPtrOfIndex(LVarArrayPtr, @Indices, P) <> VAR_OK then
      System.Error(System.reVarArrayBounds);
    PVariant(P)^ := Value;
  end else
  begin
    _VarInit(Temp);
    try
      if LArrayVarType = varVariant then
      begin
        VarStringToOleStr(Variant(Temp), Value);
        P := @Temp;
      end else
      begin
        _VarCast(Temp, TVarData(Value), LArrayVarType);
        case LArrayVarType of
          varOleStr, varDispatch, varUnknown:
            P := Temp.VPointer;
        else
          P := @Temp.VPointer;
        end;
      end;
      if SafeArrayPutElement(LVarArrayPtr, @Indices, P) <> VAR_OK then
        System.Error(System.reVarArrayBounds);
    finally
      _VarClear(Temp);
    end;
  end;
end;

procedure VarArrayPut(var A: Variant; const Value: Variant; const Indices: array of Integer);
asm
        {     ->EAX     Pointer to A            }
        {       EDX     Pointer to Value        }
        {       ECX     Pointer to Indices      }
        {       [EBP+8] High bound of Indices   }

        PUSH    EBX

        MOV     EBX,[EBP+8]

        TEST    EBX,EBX
        JS      @@endLoop
@@loop:
        PUSH    [ECX+EBX*4].Integer
        DEC     EBX
        JNS     @@loop
@@endLoop:
        MOV     EBX,[EBP+8]
        INC     EBX
        PUSH    EBX
        PUSH    EDX
        PUSH    EAX
        CALL    _VarArrayPut
        LEA     ESP,[ESP+EBX*4+3*4]

        POP     EBX
end;


function DynArrayIndex(const P: Pointer; const Indices: array of Integer; const TypInfo: Pointer): Pointer;
asm
        {     ->EAX     P                       }
        {       EDX     Pointer to Indices      }
        {       ECX     High bound of Indices   }
        {       [EBP+8] TypInfo                 }

        PUSH    EBX
        PUSH    ESI
        PUSH    EDI
        PUSH    EBP

        MOV     ESI,EDX
        MOV     EDI,[EBP+8]
        MOV     EBP,EAX

        XOR     EBX,EBX                 {  for i := 0 to High(Indices) do       }
        TEST    ECX,ECX
        JGE     @@start
@@loop:
        MOV     EBP,[EBP]
@@start:
        XOR     EAX,EAX
        MOV     AL,[EDI].TDynArrayTypeInfo.name
        ADD     EDI,EAX
        MOV     EAX,[ESI+EBX*4]         {    P := P + Indices[i]*TypInfo.elSize }
        MUL     [EDI].TDynArrayTypeInfo.elSize
        MOV     EDI,[EDI].TDynArrayTypeInfo.elType
        TEST    EDI,EDI
        JE      @@skip
        MOV     EDI,[EDI]
@@skip:
        ADD     EBP,EAX
        INC     EBX
        CMP     EBX,ECX
        JLE     @@loop

@@loopEnd:

        MOV     EAX,EBP

        POP     EBP
        POP     EDI
        POP     ESI
        POP     EBX
end;

{ Returns the DynArrayTypeInfo of the Element Type of the specified DynArrayTypeInfo }
function DynArrayElTypeInfo(typeInfo: PDynArrayTypeInfo): PDynArrayTypeInfo;
begin
  Result := nil;
  if typeInfo <> nil then
  begin
    Inc(PChar(typeInfo), Length(typeInfo.name));
    if typeInfo.elType <> nil then
      Result := typeInfo.elType^;
  end;
end;

{ Returns # of dimemsions of the DynArray described by the specified DynArrayTypeInfo}
function DynArrayDim(typeInfo: PDynArrayTypeInfo): Integer;
begin
  Result := 0;
  while (typeInfo <> nil) and (typeInfo.kind = tkDynArray) do
  begin
    Inc(Result);
    typeInfo := DynArrayElTypeInfo(typeInfo);
  end;
end;

{ Returns size of the Dynamic Array}
function DynArraySize(a: Pointer): Integer;
asm
        TEST EAX, EAX
        JZ   @@exit
        MOV  EAX, [EAX-4]
@@exit:
end;

// Returns whether array is rectangular
function IsDynArrayRectangular(const DynArray: Pointer; typeInfo: PDynArrayTypeInfo): Boolean;
var
  Dim, I, J, Size, SubSize: Integer;
  P: Pointer;
begin
  // Assume we have a rectangular array
  Result := True;

  P := DynArray;
  Dim := DynArrayDim(typeInfo);

  {NOTE: Start at 1. Don't need to test the first dimension - it's rectangular by definition}
  for I := 1 to dim-1 do
  begin
    if P <> nil then
    begin
      { Get size of this dimension }
      Size := DynArraySize(P);

      { Get Size of first sub. dimension }
      SubSize := DynArraySize(PPointerArray(P)[0]);

      { Walk through every dimension making sure they all have the same size}
      for J := 1 to Size-1 do
        if DynArraySize(PPointerArray(P)[J]) <> SubSize then
        begin
          Result := False;
          Exit;
        end;

      { Point to next dimension}
      P := PPointerArray(P)[0];
    end;
  end;
end;

// Returns Bounds of Dynamic array as an array of integer containing the 'high' of each dimension
function DynArrayBounds(const DynArray: Pointer; typeInfo: PDynArrayTypeInfo): TBoundArray;
var
  Dim, I: Integer;
  P: Pointer;
begin
  P := DynArray;

  Dim := DynArrayDim(typeInfo);
  SetLength(Result, Dim);

  for I := 0 to dim-1 do
    if P <> nil then
    begin
      Result[I] := DynArraySize(P)-1;
      P := PPointerArray(P)[0]; // Assume rectangular arrays
    end;
end;

{ Decrements to next lower index - Returns True if successful }
{ Indices: Indices to be decremented }
{ Bounds : High bounds of each dimension }
function DecIndices(var Indices: TBoundArray; const Bounds: TBoundArray): Boolean;
var
  I, J: Integer;
begin
  { Find out if we're done: all at zeroes }
  Result := False;
  for I := Low(Indices)  to High(Indices) do
    if Indices[I] <> 0  then
    begin
      Result := True;
      break;
    end;
  if not Result then
    Exit;

  { Two arrays must be of same length }
  Assert(Length(Indices) = Length(Bounds));

  { Find index of item to tweak }
  for I := High(Indices) downto Low(Bounds) do
  begin
    // If not reach zero, dec and bail out
    if Indices[I] <> 0 then
    begin
      Dec(Indices[I]);
      Exit;
    end
    else
    begin
      J := I;
      while Indices[J] = 0 do
      begin
        // Restore high bound when we've reached zero on a particular dimension
        Indices[J] := Bounds[J];
        // Move to higher dimension
        Dec(J);
        Assert(J >= 0);
      end;
      Dec(Indices[J]);
      Exit;
    end;
  end;
end;

// Returns Bounds of a DynamicArray in a format usable for creating a Variant.
//  i.e. The format of the bounds returns contains pairs of lo and hi bounds where
//       lo is always 0, and hi is the size dimension of the array-1.
function DynArrayVariantBounds(const DynArray: Pointer; typeInfo: PDynArrayTypeInfo): TBoundArray;
var
  Dim, I: Integer;
  P: Pointer;
begin
  P := DynArray;

  Dim := DynArrayDim(typeInfo);
  SetLength(Result, Dim*2);

  I := 0;
  while I < dim*2 do
  begin
    Result[I] := 0;   // Always use 0 as low-bound in low/high pair
    Inc(I);
    if P <> nil then
    begin
      Result[I] := DynArraySize(P)-1; // Adjust for 0-base low-bound
      P := PPointerArray(p)[0];       // Assume rectangular arrays
    end;
    Inc(I);
  end;
end;

// The dynamicArrayTypeInformation contains the VariantType of the element type
// when the kind == tkDynArray. This function returns that VariantType.
function DynArrayVarType(typeInfo: PDynArrayTypeInfo): Integer;
begin
  Result := varNull;
  if (typeInfo <> nil) and (typeInfo.Kind = tkDynArray) then
  begin
    Inc(PChar(typeInfo), Length(typeInfo.name));
    Result := typeInfo.varType;
  end;

  { NOTE: DECL.H and SYSTEM.PAS have different values for varString }
  if Result = $48 then
    Result := varString;
end;

// Copy Contents of Dynamic Array to Variant
// NOTE: The Dynamic array must be rectangular
//       The Dynamic array must contain items whose type is Automation compatible
// In case of failure, the function returns with a Variant of type VT_EMPTY.
procedure DynArrayToVariant(var V: Variant; const DynArray: Pointer; TypeInfo: Pointer);
var
  VarBounds, Bounds, Indices: TBoundArray;
  DAVarType, VVarType, DynDim: Integer;
  PDAData: Pointer;
  Value: Variant;
begin
  VarBounds := nil;
  Bounds    := nil;
  { This resets the Variant to VT_EMPTY - flag which is used to determine whether the }
  { the cast to Variant succeeded or not }
  VarClear(V);

  { Get variantType code from DynArrayTypeInfo }
  DAVarType := DynArrayVarType(PDynArrayTypeInfo(TypeInfo));

  { Validate the Variant Type }
  if ((DAVarType > varNull) and (DAVarType <= varByte)) or (DAVarType = varString) then
  begin
    {NOTE: Map varString to varOleStr for SafeArrayCreate call }
    if DAVarType = varString then
      VVarType := varOleStr
    else
      VVarType := DAVarType;

    { Get dimension of Dynamic Array }
    DynDim := DynarrayDim(PDynArrayTypeInfo(TypeInfo));

    { If more than one dimension, make sure we're dealing with a rectangular array }
    if DynDim > 1 then
      if not IsDynArrayRectangular(DynArray, PDynArrayTypeInfo(TypeInfo)) then
        Exit;

    { Get Variant-style Bounds (lo/hi pair) of Dynamic Array }
    VarBounds := DynArrayVariantBounds(DynArray, TypeInfo);

    { Get DynArray Bounds }
    Bounds := DynArrayBounds(DynArray, TypeInfo);
    Indices:= Copy(Bounds);

    { Create Variant of SAFEARRAY }
    V := VarArrayCreate(VarBounds, VVarType);
    Assert(VarArrayDimCount(V) = DynDim);

    repeat
      PDAData := DynArrayIndex(DynArray, Indices, TypeInfo);
      if PDAData <> nil then
      begin
        case DAVarType of
          varSmallInt:  Value := PSmallInt(PDAData)^;
          varInteger:   Value := PInteger(PDAData)^;
          varSingle:    value := PSingle(PDAData)^;
          varDouble:    value := PDouble(PDAData)^;
          varCurrency:  Value := PCurrency(PDAData)^;
          varDate:      Value := PDouble(PDAData)^;
          varOleStr:    Value := PWideString(PDAData)^;
          varDispatch:  Value := PDispatch(PDAData)^;
          varError:     Value := Integer(PError(PDAData)^);
          varBoolean:   Value := PWordBool(PDAData)^;
          varVariant:   Value := PVariant(PDAData)^;
          varUnknown:   Value := PUnknown(PDAData)^;
          varShortInt:  Value := PShortInt(PDAData)^;
          varByte:      Value := PByte(PDAData)^; //<<<<============================
          varWord:      Value := PWord(PDAData)^;
          varLongWord:  Value := PLongWord(PDAData)^;
          varString:    Value := PString(PDAData)^;
        else
          VarClear(Value);
        end; { case }
        VarArrayPut(V, Value, Indices);
      end;
    until not DecIndices(Indices, Bounds);
  end;
end;

// Copies data from the Variant to the DynamicArray
procedure DynArrayFromVariant(var DynArray: Pointer; const V: Variant; TypeInfo: Pointer);
var
  DADimCount, VDimCount: Integer;
  DAVarType, I: Integer;
  lengthVec: System.PLongInt;
  Bounds, Indices: TBoundArray;
  Value: Variant;
  PDAData: Pointer;
begin
  { Get Variant information }
  VDimCount:= VarArrayDimCount(V);

  { Allocate vector for lengths }
  GetMem(lengthVec, VDimCount * sizeof(Integer));

  { Initialize lengths - NOTE: VarArrayxxxxBound are 1-based.}
  for I := 0  to  VDimCount-1 do
    PIntegerArray(lengthVec)[I]:= (VarArrayHighBound(V, I+1) - VarArrayLowBound(V, I+1)) + 1;

  { Set Length of DynArray }
  DynArraySetLength(DynArray, PDynArrayTypeInfo(TypeInfo), VDimCount, lengthVec);

  { Get DynArray information }
  DADimCount:= DynArrayDim(PDynArrayTypeInfo(TypeInfo));
  DAVarType := DynArrayVarType(PDynArrayTypeInfo(TypeInfo));
  Assert(VDimCount = DADimCount);

  { Get DynArray Bounds }
  Bounds := DynArrayBounds(DynArray, TypeInfo);
  Indices:= Copy(Bounds);

  { Copy data over}
  repeat
    Value   := VarArrayGet(V, Indices);
    PDAData := DynArrayIndex(DynArray, Indices, TypeInfo);
    case DAVarType of
      varSmallInt:  PSmallInt(PDAData)^   := Value;
      varInteger:   PInteger(PDAData)^    := Value;
      varSingle:    PSingle(PDAData)^     := Value;
      varDouble:    PDouble(PDAData)^     := Value;
      varCurrency:  PCurrency(PDAData)^   := Value;
      varDate:      PDouble(PDAData)^     := Value;
      varOleStr:    PWideString(PDAData)^ := Value;
      varDispatch:  PDispatch(PDAData)^   := Value;
      varError:     PError(PDAData)^      := Value;
      varBoolean:   PWordBool(PDAData)^   := Value;
      varVariant:   PVariant(PDAData)^    := Value;
      varUnknown:   PUnknown(PDAData)^    := Value;
      varShortInt:  PShortInt(PDAData)^   := Value;
      varByte:      PByte(PDAData)^       := Value;
      varWord:      PWord(PDAData)^       := Value;
      varLongWord:  PLongWord(PDAData)^   := Value;
      varString:    PString(PDAData)^     := Value;
    end; { case }
  until not DecIndices(Indices, Bounds);

  { Free vector of lengths }
  FreeMem(lengthVec);
end;

{ TCustomVariantType support }

var
  LVarTypes: array of TCustomVariantType;
  LNextVarType: Integer = CFirstUserType;
  LVarTypeSync: TMultiReadExclusiveWriteSynchronizer;

procedure ClearVariantTypeList;
var
  I: Integer;
begin
  LVarTypeSync.BeginWrite;
  try
    for I := Length(LVarTypes) - 1 downto 0 do
      if LVarTypes[I] <> CInvalidCustomVariantType then
        LVarTypes[I].Free;
  finally
    LVarTypeSync.EndWrite;
  end;
end;

{ TCustomVariantType }

procedure TCustomVariantType.BinaryOp(var Left: TVarData;
  const Right: TVarData; const Operator: TVarOp);
begin
  RaiseInvalidOp;
end;

procedure TCustomVariantType.Cast(var Dest: TVarData; const Source: TVarData);
var
  LSourceHandler: TCustomVariantType;
begin
  if FindCustomVariantType(Source.VType, LSourceHandler) then
    LSourceHandler.CastTo(Dest, Source, VarType)
  else
    RaiseCastError;
end;

procedure TCustomVariantType.CastTo(var Dest: TVarData; const Source: TVarData;
  const AVarType: TVarType);
var
  LSourceHandler: TCustomVariantType;
begin
  if (AVarType <> VarType) and
     FindCustomVariantType(Source.VType, LSourceHandler) then
    LSourceHandler.CastTo(Dest, Source, AVarType)
  else
    RaiseCastError;
end;

procedure TCustomVariantType.Compare(const Left, Right: TVarData;
  var Relationship: TVarCompareResult);
begin
  RaiseInvalidOp;
end;

function TCustomVariantType.CompareOp(const Left, Right: TVarData;
  const Operator: TVarOp): Boolean;
const
  CRelationshipToBoolean: array [opCmpEQ..opCmpGE, TVarCompareResult] of Boolean =
  //  crLessThan, crEqual, crGreaterThan
    ((False,      True,    False), // opCmpEQ = 14;
     (True,       False,   True),  // opCmpNE = 15;
     (True,       False,   False), // opCmpLT = 16;
     (True,       True,    False), // opCmpLE = 17;
     (False,      False,   True),  // opCmpGT = 18;
     (False,      True,    True)); // opCmpGE = 19;
var
  LRelationship: TVarCompareResult;
begin
  Compare(Left, Right, LRelationship);
  Result := CRelationshipToBoolean[Operator, LRelationship];
end;

procedure TCustomVariantType.CastToOle(var Dest: TVarData;
  const Source: TVarData);
var
  LBestOleType: TVarType;
begin
  if OlePromotion(Source, LBestOleType) then
    CastTo(Dest, Source, LBestOleType)
  else
    RaiseCastError;
end;

constructor TCustomVariantType.Create;
begin
  Create(LNextVarType);
  Inc(LNextVarType);
end;

constructor TCustomVariantType.Create(RequestedVarType: TVarType);
var
  LSlot, LWas, LNewLength, I: Integer;
begin
  inherited Create;

  LVarTypeSync.BeginWrite;
  try
    LSlot := RequestedVarType - CMinVarType;
    LWas := Length(LVarTypes);
    if LSlot >= LWas then
    begin
      LNewLength := ((LSlot div CIncVarType) + 1) * CIncVarType;
      if LNewLength > CMaxVarType then
        raise EVariantError.Create(SVarTypeTooManyCustom);
      SetLength(LVarTypes, LNewLength);
      for I := LWas to Length(LVarTypes) - 1 do
        LVarTypes[I] := nil;
    end;
    if LVarTypes[LSlot] <> nil then
      if LVarTypes[LSlot] = CInvalidCustomVariantType then
        raise EVariantError.CreateFmt(SVarTypeNotUsable, [RequestedVarType])
      else
        raise EVariantError.CreateFmt(SVarTypeAlreadyUsed, [RequestedVarType, LVarTypes[LSlot].ClassName]);
    LVarTypes[LSlot] := Self;
    FVarType := RequestedVarType;
  finally
    LVarTypeSync.EndWrite;
  end;
end;

destructor TCustomVariantType.Destroy;
begin
  LVarTypeSync.BeginWrite;
  try
    LVarTypes[VarType - CMinVarType] := CInvalidCustomVariantType;
  finally
    LVarTypeSync.EndWrite;
  end;

  inherited;
end;

function TCustomVariantType.IsClear(const V: TVarData): Boolean;
begin
  Result := False;
end;

function TCustomVariantType.LeftPromotion(const V: TVarData;
  const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  RequiredVarType := VarType;
  Result := True;
end;

function TCustomVariantType.OlePromotion(const V: TVarData;
  out RequiredVarType: TVarType): Boolean;
begin
  RequiredVarType := varOleStr;
  Result := True;
end;

procedure TCustomVariantType.RaiseCastError;
begin
  VarCastError;
end;

procedure TCustomVariantType.RaiseInvalidOp;
begin
  VarInvalidOp;
end;

procedure TCustomVariantType.RaiseDispError;
begin
  _DispInvokeError;
end;

function TCustomVariantType.RightPromotion(const V: TVarData;
  const Operator: TVarOp; out RequiredVarType: TVarType): Boolean;
begin
  RequiredVarType := VarType;
  Result := True;
end;

procedure TCustomVariantType.SimplisticClear(var V: TVarData);
begin
  VarDataInit(V);
end;

procedure TCustomVariantType.SimplisticCopy(var Dest: TVarData;
  const Source: TVarData; const Indirect: Boolean);
begin
  if Indirect and VarDataIsByRef(Source) then
    VarDataCopyNoInd(Dest, Source)
  else
    Dest := Source; // block copy
end;

procedure TCustomVariantType.UnaryOp(var Right: TVarData; const Operator: TVarOp);
begin
  RaiseInvalidOp;
end;

procedure TCustomVariantType.VarDataInit(var Dest: TVarData);
begin
  _VarInit(Dest);
end;

procedure TCustomVariantType.VarDataClear(var Dest: TVarData);
begin
  _VarClear(Dest);
end;

procedure TCustomVariantType.VarDataCopy(var Dest: TVarData; const Source: TVarData);
begin
  VarCopyCommon(Dest, Source, False);
end;

procedure TCustomVariantType.VarDataCopyNoInd(var Dest: TVarData; const Source: TVarData);
begin
  VarCopyCommon(Dest, Source, True);
end;

procedure TCustomVariantType.VarDataCast(var Dest: TVarData;
  const Source: TVarData);
begin
  VarDataCastTo(Dest, Source, VarType);
end;

procedure TCustomVariantType.VarDataCastTo(var Dest: TVarData;
  const Source: TVarData; const AVarType: TVarType);
begin
  _VarCast(Dest, Source, AVarType);
end;

procedure TCustomVariantType.VarDataCastTo(var Dest: TVarData;
  const AVarType: TVarType);
begin
  VarDataCastTo(Dest, Dest, AVarType);
end;

procedure TCustomVariantType.VarDataCastToOleStr(var Dest: TVarData);
begin
  if Dest.VType = varString then
    _VarStringToOleStr(Dest, Dest)
  else
    VarDataCastTo(Dest, Dest, varOleStr);
end;

function TCustomVariantType.VarDataIsArray(const V: TVarData): Boolean;
begin
  Result := (V.VType and varArray) <> 0;
end;

function TCustomVariantType.VarDataIsByRef(const V: TVarData): Boolean;
begin
  Result := (V.VType and varByRef) <> 0;
end;

procedure TCustomVariantType.DispInvoke(var Dest: TVarData;
  const Source: TVarData; CallDesc: PCallDesc; Params: Pointer);
begin
  RaiseDispError;
end;

function TCustomVariantType.VarDataIsEmptyParam(const V: TVarData): Boolean;
begin
  Result := VarIsEmptyParam(Variant(V));
end;

procedure TCustomVariantType.VarDataFromStr(var V: TVarData; const Value: string);
begin
  _VarFromPStr(V, Value);
end;

procedure TCustomVariantType.VarDataFromOleStr(var V: TVarData; const Value: WideString);
begin
  _VarFromWStr(V, Value);
end;

function TCustomVariantType._AddRef: Integer;
begin
  Result := -1;
end;

function TCustomVariantType._Release: Integer;
begin
  Result := -1;
end;

function TCustomVariantType.QueryInterface(const IID: TGUID; out Obj): HResult;
const
  E_NOINTERFACE = HResult($80004002);
begin
  if GetInterface(IID, Obj) then
    Result := S_OK
  else
    Result := E_NOINTERFACE;
end;

function TCustomVariantType.VarDataIsNumeric(const V: TVarData): Boolean;
begin
  Result := VarTypeIsNumeric(V.VType);
end;

function TCustomVariantType.VarDataIsOrdinal(const V: TVarData): Boolean;
begin
  Result := VarTypeIsOrdinal(V.VType);
end;

function TCustomVariantType.VarDataIsStr(const V: TVarData): Boolean;
begin
  Result := VarTypeIsStr(V.VType);
end;

function TCustomVariantType.VarDataIsFloat(const V: TVarData): Boolean;
begin
  Result := VarTypeIsFloat(V.VType);
end;

function TCustomVariantType.VarDataToStr(const V: TVarData): string;
begin
  Result := VarToStr(Variant(V));
end;

{ TInvokeableVariantType }

procedure TInvokeableVariantType.DispInvoke(var Dest: TVarData; const Source: TVarData;
  CallDesc: PCallDesc; Params: Pointer);
type
  PParamRec = ^TParamRec;
  TParamRec = array[0..3] of LongInt;
  TStringDesc = record
    BStr: WideString;
    PStr: PString;
  end;
const
  CDoMethod    = $01;
  CPropertyGet = $02;
  CPropertySet = $04;
var
  LArguments: TVarDataArray;
  LStrings: array of TStringDesc;
  LStrCount: Integer;
  LParamPtr: Pointer;

  procedure ParseParam(I: Integer);
  const
    CArgTypeMask    = $7F;
    CArgByRef       = $80;
  var
    LArgType: Integer;
    LArgByRef: Boolean;
  begin
    LArgType := CallDesc^.ArgTypes[I] and CArgTypeMask;
    LArgByRef := (CallDesc^.ArgTypes[I] and CArgByRef) <> 0;

    // error is an easy expansion
    if LArgType = varError then
      SetClearVarToEmptyParam(LArguments[I])

    // literal string
    else if LArgType = varStrArg then
    begin
      with LStrings[LStrCount] do
        if LArgByRef then
        begin
          //BStr := StringToOleStr(PString(ParamPtr^)^);
          BStr := System.Copy(PString(LParamPtr^)^, 1, MaxInt);
          PStr := PString(LParamPtr^);
          LArguments[I].VType := varOleStr or varByRef;
          LArguments[I].VOleStr := @BStr;
        end
        else
        begin
          //BStr := StringToOleStr(PString(ParamPtr)^);
          BStr := System.Copy(PString(LParamPtr)^, 1, MaxInt);
          PStr := nil;
          LArguments[I].VType := varOleStr;
          LArguments[I].VOleStr := PWideChar(BStr);
        end;
      Inc(LStrCount);
    end

    // value is by ref
    else if LArgByRef then
    begin
      if (LArgType = varVariant) and
         (PVarData(LParamPtr^)^.VType = varString) then
        //VarCast(PVariant(ParamPtr^)^, PVariant(ParamPtr^)^, varOleStr);
        VarDataCastTo(PVarData(LParamPtr^)^, PVarData(LParamPtr^)^, varOleStr);
      LArguments[I].VType := LArgType or varByRef;
      LArguments[I].VPointer := Pointer(LParamPtr^);
    end

    // value is a variant
    else if LArgType = varVariant then
      if PVarData(LParamPtr)^.VType = varString then
      begin
        with LStrings[LStrCount] do
        begin
          //BStr := StringToOleStr(string(PVarData(ParamPtr^)^.VString));
          BStr := System.Copy(string(PVarData(LParamPtr^)^.VString), 1, MaxInt);
          PStr := nil;
          LArguments[I].VType := varOleStr;
          LArguments[I].VOleStr := PWideChar(BStr);
        end;
        Inc(LStrCount);
      end
      else
      begin
        LArguments[I] := PVarData(LParamPtr)^;
        Inc(Integer(LParamPtr), SizeOf(TVarData) - SizeOf(Pointer));
      end
    else
    begin
      LArguments[I].VType := LArgType;
      case CVarTypeToElementInfo[LArgType].Size of
        1, 2, 4:
        begin
          LArguments[I].VLongs[1] := PParamRec(LParamPtr)^[0];
        end;
        8:
        begin
          LArguments[I].VLongs[1] := PParamRec(LParamPtr)^[0];
          LArguments[I].VLongs[2] := PParamRec(LParamPtr)^[1];
          Inc(Integer(LParamPtr), 8 - SizeOf(Pointer));
        end;
      else
        RaiseDispError;
      end;
    end;
    Inc(Integer(LParamPtr), SizeOf(Pointer));
  end;

var
  I, LArgCount: Integer;
  LIdent: string;
  LTemp: TVarData;
begin
  // Grab the identifier
  LArgCount := CallDesc^.ArgCount;
  LIdent := Uppercase(String(PChar(@CallDesc^.ArgTypes[LArgCount])));

  // Parse the arguments
  LParamPtr := Params;
  SetLength(LArguments, LArgCount);
  LStrCount := 0;
  SetLength(LStrings, LArgCount);
  for I := 0 to LArgCount - 1 do
    ParseParam(I);

  // What type of invoke is this?
  case CallDesc^.CallType of
    CDoMethod:
      // procedure with N arguments
      if @Dest = nil then
      begin
        if not DoProcedure(Source, LIdent, LArguments) then
        begin

          // ok maybe its a function but first we must make room for a result
          VarDataInit(LTemp);
          try

            // notate that the destination shouldn't be bothered with
            // functions can still return stuff, we just do this so they
            //  can tell that they don't need to if they don't want to
            SetClearVarToEmptyParam(LTemp);

            // ok lets try for that function
            if not DoFunction(LTemp, Source, LIdent, LArguments) then
              RaiseDispError;
          finally
            VarDataClear(LTemp);
          end;
        end
      end

      // property get or function with 0 argument
      else if LArgCount = 0 then
      begin
        if not GetProperty(Dest, Source, LIdent) and
           not DoFunction(Dest, Source, LIdent, LArguments) then
          RaiseDispError;
      end

      // function with N arguments
      else if not DoFunction(Dest, Source, LIdent, LArguments) then
        RaiseDispError;

    CPropertyGet:
      if not ((@Dest <> nil) and                        // there must be a dest
              (LArgCount = 0) and                       // only no args
              GetProperty(Dest, Source, LIdent)) then   // get op be valid
        RaiseDispError;

    CPropertySet:
      if not ((@Dest = nil) and                         // there can't be a dest
              (LArgCount = 1) and                       // can only be one arg
              SetProperty(Source, LIdent, LArguments[0])) then // set op be valid
        RaiseDispError;
  else
    RaiseDispError;
  end;

  // copy back the string info
  I := LStrCount;
  while I <> 0 do
  begin
    Dec(I);
    with LStrings[I] do
      if Assigned(PStr) then
        PStr^ := System.Copy(BStr, 1, MaxInt);
  end;
end;

function TInvokeableVariantType.GetProperty(var Dest: TVarData; const V: TVarData;
  const Name: string): Boolean;
begin
  Result := False;
end;

function TInvokeableVariantType.SetProperty(const V: TVarData; const Name: string;
  const Value: TVarData): Boolean;
begin
  Result := False;
end;

function TInvokeableVariantType.DoFunction(var Dest: TVarData; const V: TVarData;
  const Name: string; const Arguments: TVarDataArray): Boolean;
begin
  Result := False;
end;

function TInvokeableVariantType.DoProcedure(const V: TVarData; const Name: string;
  const Arguments: TVarDataArray): Boolean;
begin
  Result := False;
end;

{ TCustomVariantType support }

function FindCustomVariantType(const AVarType: TVarType; out CustomVariantType: TCustomVariantType): Boolean;
begin
  LVarTypeSync.BeginRead;
  try
    Result := (AVarType >= CMinVarType) and (AVarType - CMinVarType < Length(LVarTypes));
    if Result then
    begin
      CustomVariantType := LVarTypes[AVarType - CMinVarType];
      Result := (CustomVariantType <> nil) and
                (CustomVariantType <> CInvalidCustomVariantType);
    end;
  finally
    LVarTypeSync.EndRead;
  end;
end;

function FindCustomVariantType(const TypeName: string; out CustomVariantType: TCustomVariantType): Boolean;
var
  I: Integer;
  LPossible: TCustomVariantType;
begin
  Result := False;
  LVarTypeSync.BeginRead;
  try
    for I := Low(LVarTypes) to High(LVarTypes) do
    begin
      LPossible := LVarTypes[I];
      if (LPossible <> nil) and (LPossible <> CInvalidCustomVariantType) and
         SameText(LPossible.ClassName, TypeName) then
      begin
        CustomVariantType := LPossible;
        Result := True;
        Break;
      end;
    end;
  finally
    LVarTypeSync.EndRead;
  end;
end;

function Unassigned: Variant;
begin
  _VarClear(TVarData(Result));
end;

function Null: Variant;
begin
  _VarClear(TVarData(Result));
  TVarData(Result).VType := varNull;
end;

initialization
  SetClearVarToEmptyParam(TVarData(EmptyParam));

  VarDispProc := @_DispInvokeError;
  ClearAnyProc := @VarInvalidOp;
  ChangeAnyProc := @VarCastError;
  RefAnyProc := @VarInvalidOp;

  GVariantManager.VarClear := @_VarClear;
  GVariantManager.VarCopy := @_VarCopy;
  GVariantManager.VarCopyNoInd := @_VarCopyNoInd;
  GVariantManager.VarCast := @_VarCast;
  GVariantManager.VarCastOle := @_VarCastOle;

  GVariantManager.VarToInt := @_VarToInt;
  GVariantManager.VarToInt64 := @_VarToInt64;
  GVariantManager.VarToBool := @_VarToBool;
  GVariantManager.VarToReal := @_VarToReal;
  GVariantManager.VarToCurr := @_VarToCurr;
  GVariantManager.VarToPStr := @_VarToPStr;
  GVariantManager.VarToLStr := @_VarToLStr;
  GVariantManager.VarToWStr := @_VarToWStr;
  GVariantManager.VarToIntf := @_VarToIntf;
  GVariantManager.VarToDisp := @_VarToDisp;
  GVariantManager.VarToDynArray := @_VarToDynArray;

  GVariantManager.VarFromInt := @_VarFromInt;
  GVariantManager.VarFromInt64 := @_VarFromInt64;
  GVariantManager.VarFromBool := @_VarFromBool;
  GVariantManager.VarFromReal := @_VarFromReal;
  GVariantManager.VarFromTDateTime := @_VarFromTDateTime;
  GVariantManager.VarFromCurr := @_VarFromCurr;
  GVariantManager.VarFromPStr := @_VarFromPStr;
  GVariantManager.VarFromLStr := @_VarFromLStr;
  GVariantManager.VarFromWStr := @_VarFromWStr;
  GVariantManager.VarFromIntf := @_VarFromIntf;
  GVariantManager.VarFromDisp := @_VarFromDisp;
  GVariantManager.VarFromDynArray := @_VarFromDynArray;
  GVariantManager.OleVarFromPStr := @_OleVarFromPStr;
  GVariantManager.OleVarFromLStr := @_OleVarFromLStr;
  GVariantManager.OleVarFromVar := @_OleVarFromVar;
  GVariantManager.OleVarFromInt := @_OleVarFromInt;

  GVariantManager.VarOp := @_VarOp;
  GVariantManager.VarCmp := @_VarCmp;
  GVariantManager.VarNeg := @_VarNeg;
  GVariantManager.VarNot := @_VarNot;

  GVariantManager.DispInvoke := @_DispInvoke;
  GVariantManager.VarAddRef := @_VarAddRef;

  GVariantManager.VarArrayRedim := @_VarArrayRedim;
  GVariantManager.VarArrayGet := @_VarArrayGet;
  GVariantManager.VarArrayPut := @_VarArrayPut;

  GVariantManager.WriteVariant := @_WriteVariant;
  GVariantManager.Write0Variant := @_Write0Variant;

  GetVariantManager(GOldVariantManager);
  SetVariantManager(GVariantManager);

  LVarTypeSync := TMultiReadExclusiveWriteSynchronizer.Create;
finalization
  ClearVariantTypeList;
  FreeAndNil(LVarTypeSync);

  SetVariantManager(GOldVariantManager);
end.
