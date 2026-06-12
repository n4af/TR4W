unit uCabrilloExchange;

{
  Issue #998 capstone -- testable extraction of the per-exchange Cabrillo
  MY-EXCHANGE / HIS-EXCHANGE builder.

  The logic here was lifted (behaviour-preserving) from
  trdos/PostUnit.tGenerateLogPortionOfCabrilloFile's `case ActiveExchange of`.
  It is deliberately DEPENDENCY-LIGHT (uses only VC + SysUtils, no MainUnit /
  trdos globals / log I/O) so the per-contest exchange formatting can be
  unit-tested with golden lines -- which it could NOT be while embedded in the
  1,200-line PostUnit writer.

  PostUnit derives the per-QSO inputs (the display RST strings, the selected
  HIS-QTH, the My-station fields) and calls FormatCabrilloExchange, then feeds
  the returned MyEx/HisEx into the QSO: line assembly.  The QSO:/X-QSO: header,
  the final assembly, the QTC block, StrUpper(HisEx) and file I/O stay in
  PostUnit -- this unit only PRODUCES the two exchange column strings.

  See plan_cabrillo_exchange_capstone for the phasing.
}

interface

uses
  VC,
  SysUtils;

type
  // The My-station fields the exchange arms read.  Strings so the unit needs no
  // globals; PostUnit fills these from MyState / MyGrid / ... at the call site.
  TMyStationExchange = record
    MyState     : string;
    MyGrid      : string;
    MyName      : string;
    MyZone      : string;     // StrToInt'd internally (matches the old cMyZone := StrToInt(MyZone))
    MyFDClass   : string;
    MySection   : string;
    MyCheck     : string;
    MyPrec      : string;
    MyFOCNumber : string;
    MyPostalCode: string;
  end;

// Builds the MY-EXCHANGE (MyEx) and HIS-EXCHANGE (HisEx) Cabrillo columns for
// one QSO, dispatching on ActiveExchange.  RSTSentIn/RSTReceivedIn are the
// already-formatted RST display strings; HisQTH is the his-QTH already selected
// by PostUnit (DoingDomesticMults / LiteralDomesticQTH / ... ); PrevQTH is the
// previous QSO's QTHString (RSTAndPostalCode); pnr is carried across QSOs
// (QSONumberAndPreviousQSONumber).  Result is always True (mirrors the old
// fall-through behaviour).
function FormatCabrilloExchange(
    ActiveExchange : ExchangeType;
    Contest        : ContestType;
    const ContestTitle, ContestName : string;
    const rx       : ContestExchange;
    const my       : TMyStationExchange;
    const RSTSentIn, RSTReceivedIn, HisQTH, PrevQTH : string;
    contacts       : integer;
    var   pnr      : integer;
    out   MyEx, HisEx : string) : boolean;

implementation

function StringIsAllNumbersLocal(const s: string): boolean;
var
  i: integer;
begin
  Result := (s <> '');
  for i := 1 to Length(s) do
    if not (s[i] in ['0'..'9']) then
       begin
       Result := False;
       Exit;
       end;
end;

function FormatCabrilloExchange(
    ActiveExchange : ExchangeType;
    Contest        : ContestType;
    const ContestTitle, ContestName : string;
    const rx       : ContestExchange;
    const my       : TMyStationExchange;
    const RSTSentIn, RSTReceivedIn, HisQTH, PrevQTH : string;
    contacts       : integer;
    var   pnr      : integer;
    out   MyEx, HisEx : string) : boolean;
var
  // Mirror the PostUnit per-QSO locals (as strings/ints instead of PChar).
  RSTSent, RSTReceived, csQTHString, csName,
  cMyGrid, cMyName, cMyState,
  csPower, crFOCNr, cMyFOCNumber, cMyCheck : string;
  cMyZone, nrSent, nrReceived, HisZone, hisAge, csCheck, hisnr, rxnr : integer;

  procedure SetMyEx(const fmt: string; const args: array of const);
  begin
    MyEx := SysUtils.Format(fmt, args);
  end;

  procedure SetHisEx(const fmt: string; const args: array of const);
  begin
    HisEx := SysUtils.Format(fmt, args);
  end;

begin
  Result := True;
  MyEx := '';
  HisEx := '';

  // --- Preamble: initialise the per-QSO locals from rx / my / params,
  //     mirroring the setup PostUnit did before the case. ---
  RSTSent     := RSTSentIn;
  RSTReceived := RSTReceivedIn;
  csQTHString := HisQTH;
  csName      := string(rx.Name);
  cMyGrid     := my.MyGrid;
  cMyName     := my.MyName;
  cMyState    := my.MyState;
  cMyZone     := StrToIntDef(my.MyZone, 0);
  nrSent      := rx.NumberSent;
  nrReceived  := rx.NumberReceived;
  HisZone     := rx.Zone;

  case ActiveExchange of

    GridExchange, Grid2Exchange:
      begin
        SetMyEx('%-11s', [cMyGrid]);
        SetHisEx('%-11s', [csQTHString]);
      end;

    RSTAndGrid3Exchange:                // 4.96.3
      begin
        SetMyEx('%-7s%-11s ', [RSTSent, cMyGrid]);
        SetHisEx('%-3s %-11s ', [RSTReceived, csQTHString]);
      end;

    RSTNameAndQTHExchange:
      begin
        SetMyEx('%-3s %-5s %-7s', [RSTSent, cMyName, cMyState]);
        SetHisEx('%-3s %-5s %-7s', [RSTReceived, csName, csQTHString]);
      end;

    QSONumberAndNameExchange:
      begin
        SetMyEx('%-3d %-7s', [nrSent, cMyName]);
        SetHisEx('%-3u %-7s', [nrReceived, csName]);
      end;

    RSTAndPostalCodeExchange:
      begin
        if contacts = 1 then
          SetMyEx('%-3s %-10s', [RSTSent, my.MyPostalCode])
        else
          SetMyEx('%-3s %-10s', [RSTSent, PrevQTH]);
        SetHisEx('%-3s %-10s', [RSTReceived, string(rx.QTHString)]);
      end;

    RSTQSONumberAndGridSquareExchange:
      begin
        SetMyEx('%-3s %-4.4d %-7s', [RSTSent, nrSent, cMyGrid]);
        SetHisEx('%-3s %-4.4u %-7s', [RSTReceived, nrReceived, csQTHString]);
      end;

    RSTQSONumberOrDomesticQTHExchange:      //n4af 4.40.6
      begin
        if cMyState <> '' then
           begin
           SetMyEx('%-3s  %-8s', [RSTSent, cMyState]);        // 4.98.11
           end;

        if cMyState = '' then
           begin
           SetMyEx('%-3s  %-6d', [RSTSent, nrSent]);
           end;

        if nrReceived >= 1 then
           begin
           SetHisEx('%-3s %6d %-6s', [RSTReceived, nrReceived, csQTHString]);
           end;
        if nrReceived < 1 then
           begin
           SetHisEx('%-3s   %9s', [RSTReceived, csQTHString]);
           end;
      end;

    RSTPrefectureExchange:
      begin
        SetMyEx('%-3s %-7d', [RSTSent, cMyZone]);
        SetHisEx('%-3s %-7s', [RSTReceived, csQTHString]);
      end;

    NameAndDomesticOrDXQTHExchange:
      begin
        SetMyEx('  %-10s %-4s', [my.MyName, cMyState]);
        SetHisEx('  %-10s %-4s', [csName, csQTHString]);
      end;

    QSONumberPrecedenceCheckDomesticQTHExchange:
      begin
        csName   := rx.Precedence;       // the precedence character
        cMyName  := my.MyPrec;
        csCheck  := rx.Check;
        cMyCheck := my.MyCheck;
        cMyState := my.MySection;

        SetMyEx('%-4d %s %s %-3s ', [nrSent, cMyName, cMyCheck, cMyState]);
        if nrReceived = -1 then
          nrReceived := 0;
        SetHisEx('%-4d %s %.2u %-3s', [nrReceived, csName, csCheck, csQTHString]);
      end;

    QSONumberNameDomesticOrDXQTHExchange:
      begin
        csName  := string(rx.Name);
        cMyName := my.MyName;
        if my.MyState = '' then cMyState := 'DX';
        if rx.QTHString = '' then csQTHString := 'DX';

        SetMyEx('%-4d %-7s %-8s', [nrSent, cMyName, cMyState]);    // 4.88.3
        SetHisEx('%-4u %-5s %-4s', [nrReceived, csName, csQTHString]);  // 4.88.3
      end;

    RSTAgeAndPossibleSK:
      begin
        SetMyEx('%-3s %-16s', [RSTSent, cMyState]);
        nrReceived := rx.Age;
        SetHisEx('%-3s %u %s', [RSTReceived, nrReceived, csQTHString]);
      end;

    RSTAgeExchange:
      begin
        SetMyEx('%-3s %-7s', [RSTSent, cMyState]);
        nrReceived := rx.Age;
        SetHisEx('%-3s %-7u', [RSTReceived, nrReceived]);
      end;

    AgeAndQSONumberExchange:      // 4.55.4
      begin
        SetMyEx('%-2s %.*d ', [cMyState, 3 - Ord(nrSent < 0), nrSent]);
        hisAge := rx.Age;
        nrReceived := rx.NumberReceived;          // n4af 04.42.4
        SetHisEx(' %-3d %.*d', [hisAge, 4 - Ord(nrReceived < 0), nrReceived]);   // n4af 4.42.4
      end;

    QSONumberAndAgeExchange:      // 4.119.1
      begin
        // Unreachable by any active contest; RSTSent here is the numeric RST.
        SetMyEx('%-3d %.*d %-2s      ', [rx.RSTSent, 3 - Ord(nrSent < 0), nrSent, cMyState]);
        hisAge := rx.Age;
        nrReceived := rx.NumberReceived;          // n4af 04.42.4
        SetHisEx(' %-3d %3d %.2d', [rx.RSTSent, nrReceived, hisAge]);       // n4af 4.42.4
      end;

    RSTPowerExchange:
      begin
        csPower := string(rx.Power);
        if Contest = FOCMARATHON then
           begin
           cMyFOCNumber := my.MyFOCNumber;
           crFOCNr := string(rx.Power);
           SetMyEx('%-3s %-7s', [RSTSent, cMyFOCNumber]);
           SetHisEx('%-3s %-7s', [RSTReceived, crFOCNr]);
           end;
        if Contest <> FOCMARATHON then
           begin
           SetHisEx('%-3s %-7s', [RSTReceived, csPower]);
           SetMyEx('%-3s %-7s', [RSTSent, cMyState]);
           end;
      end;

    RSTAndOrGridExchange:
      begin
        SetHisEx('%-3s %-7s', [RSTReceived, csQTHString]);
        SetMyEx('%-3s %-7s', [RSTSent, cMyGrid]);
      end;

    QSONumberAndGridSquare:
      begin
        SetMyEx('%.*d %-6.4s ', [3 - Ord(nrSent < 0), nrSent, cMyState]);
        SetHisEx('%3.4u %-6s', [nrReceived, csQTHString]);
      end;

    QSONumberDomesticOrDXQTHExchange, QSONumberDomesticQTHExchange:
      if (Contest = UKRAINECHAMPIONSHIP) or (Contest = CUPURAL) then
        begin
        SetMyEx('%-4s %-6.4d', [cMyState, nrSent]);
        SetHisEx('%-4s %-6.4u', [csQTHString, nrReceived]);
        end
      else
        begin
        SetMyEx('%-4d %-6s', [nrSent, cMyState]);
        SetHisEx('%-4.4u %-6s', [nrReceived, csQTHString]);
        end;

    QSONumberAndPossibleDomesticQTHExchange, RSTQSONumberAndDomesticQTHExchange, RSTQSONumberAndPossibleDomesticQTHExchange:
      begin
        if cMyState = 'TRC' then      // 4.63.3
           SetMyEx('%-3s %d%-6s', [RSTSent, nrSent, cMyState])
        else if ContestTitle = 'PGA' then       // 4.92.4
           SetMyEx('%-3s %3.3d%s     ', [RSTSent, nrSent, cMyState])
        else
           SetMyEx('%-3s %-4.4d %6s      ', [RSTSent, nrSent, cMyState]);

        if Contest = UKEI then           // 4.58.2
          if rx.QTHString = '' then
            csQTHString := '--';

        if Contest = IOTA then
          begin
          if csQTHString = '' then csQTHString := '------';
          end;

        if Contest = DARC10M then     // n4af 4.43.7
           SetHisEx('%-3s %4.4d %3s', [RSTReceived, nrReceived, csQTHString])
        else if ContestTitle = 'PGA' then           // 4.92.4
           SetHisEx('%-3s%5.3d%s', [RSTReceived, nrReceived, csQTHString])
        else if csQTHString = 'TRC' then      // 4.63.3
           SetHisEx('%-3s%5d%-8s', [RSTReceived, nrReceived, csQTHString])
        else
           SetHisEx('%-3s %4.4d %4s', [RSTReceived, nrReceived, csQTHString]);
      end;

    RSTZoneAndPossibleDomesticQTHExchange:
      begin
        if my.MyState = '' then
          cMyState := 'DX';

        SetMyEx('%-3s %.2u %-4s', [RSTSent, cMyZone, cMyState]);

        if rx.QTHString = '' then
          csQTHString := 'DX';
        SetHisEx('%-3s %.2u %-3s', [RSTReceived, HisZone, csQTHString]);
      end;

    RSTZoneOrDomesticQTH, RSTZoneOrSocietyExchange:
      begin
        if my.MyState <> '' then
           begin
           SetMyEx('%-3s %-7s', [RSTSent, cMyState]);
           end
        else
           begin
           SetMyEx('%-3s %-7d', [RSTSent, cMyZone]);
           end;

        if rx.QTHString <> '' then
           begin
           SetHisEx('%-3s %-7s', [RSTReceived, csQTHString]);
           end
        else
           begin
           SetHisEx('%-3s %-7u', [RSTReceived, HisZone]);
           end;
      end;

    QSONumberAndCoordinatesSum: {RFASCHAMPIONSHIP}
      begin
        SetMyEx('%-3s %3.4d    ', [cMyState, nrSent]);
        SetHisEx('%-3s %3.4u', [csQTHString, nrReceived]);
      end;

    ClassDomesticOrDXQTHExchange:
      begin
        SetMyEx('%-3s %-7s ', [my.MyFDClass, my.MySection]);
        if Contest in [ARRLFIELDDAY, WINTERFIELDDAY] then
           begin
           csQTHString := string(rx.QTHString);   // Issue 407 ny4i
           end;
        SetHisEx('%-3s %-7s', [string(rx.ceClass), csQTHString]);
      end;

    QSONumberAndGeoCoordinates:
      begin
        SetMyEx('%-3.4d %-7s ', [nrSent, cMyState]);
        SetHisEx('%-3.4u %-7s', [nrReceived, csQTHString]);
      end;

    RSTQSONumberExchange:
      begin
        SetMyEx('%-3s %.*d ', [RSTSent, 3 - Ord(nrSent < 0), nrSent]);   // issue 177
        SetHisEx('%-3s %-3.3u', [RSTReceived, nrReceived]);              // issue 177
      end;

    RSTAndContinentExchange:
      begin
        csQTHString := string(rx.QTHString);
        SetHisEx('%-3s %-7s', [RSTReceived, csQTHString]);
        SetMyEx('%-3s %-7s', [RSTSent, cMyState]);
      end;

    RSTDomesticQTHExchange:
      begin
        if Contest in [ CQVHF {, MMAA}] then
          begin
          SetHisEx(' %-7s', [csQTHString]);
          SetMyEx('%-7s', [cMyGrid]);
          end
        else
          begin
          if my.MyState = '' then cMyState := 'DX';
          if Contest in [SPDX, PACC] then cMyState := IntToStr(nrSent);
          if rx.QTHString = '' then csQTHString := 'DX';
          SetHisEx('%-3s %-7s', [RSTReceived, csQTHString]);
          SetMyEx('%-3s %-7s', [RSTSent, cMyState]);
          end;
      end;

    RSTDomesticOrDXQTHExchange:
      begin
        if rx.QTHString = '' then
          begin
          if rx.DXQTH = '' then
             begin
             csQTHString := 'DX';
             end
          else
             begin
             if Contest = FLORIDAQSOPARTY then
                begin
                csQTHString := string(rx.QTH.Prefix);
                end
             else
                begin
                csQTHString := string(rx.DXQTH);
                end;
             end;
          end
        else if rx.QTHString = 'DX' then
          begin
          if Contest = FLORIDAQSOPARTY then
             begin
             csQTHString := string(rx.QTH.Prefix);
             end;
          end;

        SetHisEx('%-3s %-7s', [RSTReceived, csQTHString]);
        SetMyEx('%-3s %-7s', [RSTSent, cMyState]);
      end;

    QSONumberAndZone:
      begin
        SetHisEx('  %-4u   %.3d', [HisZone, nrReceived]);   // 4.98.4
        SetMyEx('  %s    %3.4d ', [cMyState, nrSent]);
      end;

    RSTZoneExchange:
      begin
        if Contest in [JIDXSSB, JIDXCW] then cMyZone := StrToIntDef(my.MyState, 0);
        SetHisEx('%-3s %-7.2d', [RSTReceived, HisZone]);   // 4.51.1 issue185
        SetMyEx('%-3s %-7.2d', [RSTSent, cMyZone]);        // 4.51.1 issue#185
      end;

    QSONumberAndPreviousQSONumber:
      begin
        hisnr := (nrReceived div 1000);    // 4.53.2
        rxnr  := (nrReceived mod 1000);    // 4.53.2
        SetMyEx('%-.3u%-7.4d', [pnr, nrSent]);    // 4.72.9
        pnr := rxnr;
        SetHisEx('%-.4d%-.4d', [hisnr, rxnr]);    // 4.53.4
      end;

    RSTAndQSONumberOrFrenchDepartmentExchange, RSTAndQSONumberOrDomesticQTHExchange, RSTDomesticQTHOrQSONumberExchange:
      begin
        if (my.MyState <> '') and (Contest <> PCC) then      // 4.83.2
           begin
           SetMyEx('%-3s %-7s', [RSTSent, cMyState]);
           end
        else if StringIsAllNumbersLocal(my.MyState) then
           begin
           SetMyEx('%-4s %3.4u/M   ', [RSTSent, nrSent]);  // n4af 4.43.12
           end
        else
           begin
           SetMyEx('%-4s %3.4u   ', [RSTSent, nrSent]);  // n4af 4.43.12
           end;

        if rx.QTHString <> '' then
           begin
           SetHisEx('%-3s %-3s', [RSTReceived, csQTHString]); // 4.84.2
           end
        else
           begin
           SetHisEx('%-3s %.3u', [RSTReceived, nrReceived]);
           end;
      end;
  end;
end;

end.
