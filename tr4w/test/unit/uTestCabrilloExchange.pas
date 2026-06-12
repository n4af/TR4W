unit uTestCabrilloExchange;

{
  Golden-line unit tests for uCabrilloExchange.FormatCabrilloExchange.

  This is the durable replacement for the per-contest manual Cabrillo diffing
  used during the #998 asm-removal: the exchange MY-EXCH / HIS-EXCH formatting
  for every ActiveExchange now has a pinned, automated regression net.

  Each test constructs a zeroed ContestExchange (rx) + a TMyStationExchange (my),
  drives one ActiveExchange, and asserts the exact MyEx/HisEx column strings.
  The expected values mirror the behaviour that was output-validated byte-for-
  byte against release builds across 11 contests (see PR for the #998 capstone).

  Spot-covered families + edges:
    grid, RST+serial, RST+name+QTH, class/section (Field Day), zone,
    Sweepstakes (precedence char + check), the QSONumberAndPreviousQSONumber
    cross-QSO `pnr` carry, the negative-serial '%.*d' width-zero-pad edge,
    and the French-department StringIsAllNumbers branch.
}

interface

uses
   SysUtils, uTR4WTestFramework, VC, uCabrilloExchange;

type
   TCabrilloExchangeTests = class(TTestCase)
   protected
      procedure Test_Grid;
      procedure Test_RSTQSONumber;
      procedure Test_RSTNameAndQTH;
      procedure Test_ClassSection_FieldDay;
      procedure Test_RSTZone;
      procedure Test_Sweepstakes_PrecCheck;
      procedure Test_PreviousQSONumber_PnrCarry;
      procedure Test_AgeAndQSONumber_NegativeSerial;
      procedure Test_FrenchDept_AllNumbersBranch;
   public
      procedure RunAllTests; override;
   end;

implementation

// Build a zeroed ContestExchange (all ShortStrings empty, all ints 0).
function EmptyRx: ContestExchange;
begin
   FillChar(Result, SizeOf(Result), 0);
end;

// Build a zeroed My-station record.
function EmptyMy: TMyStationExchange;
begin
   Result.MyState      := '';
   Result.MyGrid       := '';
   Result.MyName       := '';
   Result.MyZone       := '';
   Result.MyFDClass    := '';
   Result.MySection    := '';
   Result.MyCheck      := '';
   Result.MyPrec       := '';
   Result.MyFOCNumber  := '';
   Result.MyPostalCode := '';
end;

// ---------------------------------------------------------------------------

procedure TCabrilloExchangeTests.Test_Grid;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_Grid');
   rx := EmptyRx;
   my := EmptyMy;
   my.MyGrid := 'EM73';
   pnr := 0;
   FormatCabrilloExchange(GridExchange, GENERALQSO, '', '', rx, my,
      '', '', {HisQTH} 'FN31', '', 1, pnr, MyEx, HisEx);
   CheckEquals('EM73       ', MyEx,  'Grid MyEx (%-11s)');
   CheckEquals('FN31       ', HisEx, 'Grid HisEx (%-11s)');
end;

procedure TCabrilloExchangeTests.Test_RSTQSONumber;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_RSTQSONumber');
   rx := EmptyRx;
   rx.NumberSent := 1;
   rx.NumberReceived := 2;
   my := EmptyMy;
   pnr := 0;
   FormatCabrilloExchange(RSTQSONumberExchange, GENERALQSO, '', '', rx, my,
      '599', '599', '', '', 1, pnr, MyEx, HisEx);
   // '%-3s %.*d ' with RST=599, prec=3, nr=1  -> '599 001 '
   CheckEquals('599 001 ', MyEx,  'RSTQSONumber MyEx');
   // '%-3s %-3.3u' with RST=599, nr=2          -> '599 002'
   CheckEquals('599 002', HisEx,  'RSTQSONumber HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTNameAndQTH;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_RSTNameAndQTH');
   rx := EmptyRx;
   rx.Name := 'BOB';
   my := EmptyMy;
   my.MyName  := 'TOM';
   my.MyState := 'FL';
   pnr := 0;
   FormatCabrilloExchange(RSTNameAndQTHExchange, GENERALQSO, '', '', rx, my,
      '599', '599', {HisQTH} 'GA', '', 1, pnr, MyEx, HisEx);
   // '%-3s %-5s %-7s'
   CheckEquals('599 TOM   FL     ', MyEx,  'RSTNameAndQTH MyEx');
   CheckEquals('599 BOB   GA     ', HisEx, 'RSTNameAndQTH HisEx');
end;

procedure TCabrilloExchangeTests.Test_ClassSection_FieldDay;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_ClassSection_FieldDay');
   rx := EmptyRx;
   rx.ceClass := '2A';
   rx.QTHString := 'SC';
   my := EmptyMy;
   my.MyFDClass := '3A';
   my.MySection := 'GA';
   pnr := 0;
   // ARRLFIELDDAY -> HisQTH re-derived from rx.QTHString inside the arm.
   FormatCabrilloExchange(ClassDomesticOrDXQTHExchange, ARRLFIELDDAY, '', '', rx, my,
      '', '', {HisQTH} '', '', 1, pnr, MyEx, HisEx);
   // MyEx '%-3s %-7s ' ; HisEx '%-3s %-7s'
   CheckEquals('3A  GA      ', MyEx,  'FD MyEx');
   CheckEquals('2A  SC     ', HisEx, 'FD HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTZone;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_RSTZone');
   rx := EmptyRx;
   rx.Zone := 5;
   my := EmptyMy;
   my.MyZone := '14';
   pnr := 0;
   FormatCabrilloExchange(RSTZoneExchange, GENERALQSO, '', '', rx, my,
      '599', '599', '', '', 1, pnr, MyEx, HisEx);
   // '%-3s %-7.2d' : RST + zone padded to 2 digits, left in width 7
   CheckEquals('599 14     ', MyEx,  'RSTZone MyEx');
   CheckEquals('599 05     ', HisEx, 'RSTZone HisEx');
end;

procedure TCabrilloExchangeTests.Test_Sweepstakes_PrecCheck;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_Sweepstakes_PrecCheck');
   rx := EmptyRx;
   rx.NumberSent := 12;
   rx.NumberReceived := 34;
   rx.Precedence := 'A';
   rx.Check := 72;
   my := EmptyMy;
   my.MyPrec    := 'B';
   my.MyCheck   := '59';
   my.MySection := 'GA';
   pnr := 0;
   FormatCabrilloExchange(QSONumberPrecedenceCheckDomesticQTHExchange, GENERALQSO, '', '', rx, my,
      '', '', {HisQTH} 'SC', '', 1, pnr, MyEx, HisEx);
   // MyEx '%-4d %s %s %-3s ' = serial, my-prec, my-check, my-section
   CheckEquals('12   B 59 GA  ', MyEx,  'SS MyEx');
   // HisEx '%-4d %s %.2u %-3s' = serial, his-prec, his-check(2dig), his-section
   CheckEquals('34   A 72 SC ', HisEx, 'SS HisEx');
end;

procedure TCabrilloExchangeTests.Test_PreviousQSONumber_PnrCarry;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_PreviousQSONumber_PnrCarry');
   rx := EmptyRx;
   rx.NumberSent := 2;
   rx.NumberReceived := 456789;   // hisnr=456, rxnr=789
   my := EmptyMy;
   pnr := 123;                     // previous received number carried in
   FormatCabrilloExchange(QSONumberAndPreviousQSONumber, GENERALQSO, '', '', rx, my,
      '', '', '', '', 1, pnr, MyEx, HisEx);
   // MyEx '%-.3u%-7.4d' : pnr(123) + sent(0002 padded to width7)
   CheckEquals('1230002   ', MyEx,  'YOC MyEx');
   // HisEx '%-.4d%-.4d' : hisnr(0456) + rxnr(0789)
   CheckEquals('04560789', HisEx, 'YOC HisEx');
   // the var pnr must now hold rxnr for the NEXT QSO
   CheckEquals('789', IntToStr(pnr), 'YOC pnr carried forward = rxnr');
end;

procedure TCabrilloExchangeTests.Test_AgeAndQSONumber_NegativeSerial;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_AgeAndQSONumber_NegativeSerial');
   rx := EmptyRx;
   rx.NumberSent := -1;       // the "no serial" sentinel -> '%.*d' width-zero-pad
   rx.Age := 25;
   rx.NumberReceived := 5;
   my := EmptyMy;
   my.MyState := 'XY';
   pnr := 0;
   FormatCabrilloExchange(AgeAndQSONumberExchange, GENERALQSO, '', '', rx, my,
      '', '', '', '', 1, pnr, MyEx, HisEx);
   // MyEx '%-2s %.*d ' with cMyState=XY, prec=2 (sign-in-width), nr=-1 -> 'XY -01 '
   CheckEquals('XY -01 ', MyEx,  'AgeQSO neg-serial MyEx');
   // HisEx ' %-3d %.*d' with hisAge=25, prec=4, nrReceived=5 -> ' 25  0005'
   CheckEquals(' 25  0005', HisEx, 'AgeQSO HisEx');
end;

procedure TCabrilloExchangeTests.Test_FrenchDept_AllNumbersBranch;
var
   rx: ContestExchange;
   my: TMyStationExchange;
   pnr: integer;
   MyEx, HisEx: string;
begin
   BeginTest('Test_FrenchDept_AllNumbersBranch');
   rx := EmptyRx;
   rx.NumberSent := 7;
   rx.NumberReceived := 31;
   my := EmptyMy;
   my.MyState := '014';        // all-numbers
   pnr := 0;
   // Contest = PCC makes the first condition (MyState<>'' and Contest<>PCC)
   // false, so the all-numbers '/M' branch is reached.
   FormatCabrilloExchange(RSTAndQSONumberOrFrenchDepartmentExchange, PCC, '', '', rx, my,
      '599', '599', {HisQTH} '', '', 1, pnr, MyEx, HisEx);
   // MyState all-numbers + PCC -> '%-4s %3.4u/M   '
   CheckEquals('599  0007/M   ', MyEx,  'FrenchDept MyEx /M branch');
   // HisQTH empty -> HisEx '%-3s %.3u'
   CheckEquals('599 031', HisEx, 'FrenchDept HisEx serial branch');
end;

// ---------------------------------------------------------------------------

procedure TCabrilloExchangeTests.RunAllTests;
begin
   Test_Grid;
   Test_RSTQSONumber;
   Test_RSTNameAndQTH;
   Test_ClassSection_FieldDay;
   Test_RSTZone;
   Test_Sweepstakes_PrecCheck;
   Test_PreviousQSONumber_PnrCarry;
   Test_AgeAndQSONumber_NegativeSerial;
   Test_FrenchDept_AllNumbersBranch;
end;

end.
