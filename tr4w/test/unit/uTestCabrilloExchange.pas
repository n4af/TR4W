unit uTestCabrilloExchange;

{
  Golden-line unit tests for uCabrilloExchange.FormatCabrilloExchange.

  The durable replacement for per-contest manual Cabrillo diffing: every
  ActiveExchange arm that produces MY-EXCH / HIS-EXCH columns has a pinned
  characterization test here.  The expected values mirror behaviour that was
  output-validated byte-for-byte against release across 11 contests during the
  #998 capstone swap; these tests lock that behaviour for the D12 migration.

  One test per exchange arm (multi-label arms share one arm body).  Branchy
  arms (RSTPowerExchange FOC/non-FOC, QSONumberDomesticOrDX Ukraine/else,
  RSTDomesticQTH CQVHF/else, the PGA/TRC/IOTA/DARC10M group, the French-dept
  state/numbers branches) get a test per meaningful branch.
}

interface

uses
   SysUtils, uTR4WTestFramework, VC, uCabrilloExchange;

type
   TCabrilloExchangeTests = class(TTestCase)
   protected
      procedure Test_Grid;
      procedure Test_Grid2_SameAsGrid;
      procedure Test_RSTAndGrid3;
      procedure Test_RSTQSONumber;
      procedure Test_RSTNameAndQTH;
      procedure Test_QSONumberAndName;
      procedure Test_RSTAndPostalCode;
      procedure Test_RSTQSONumberAndGridSquare;
      procedure Test_RSTQSONumberOrDomesticQTH;
      procedure Test_RSTPrefecture;
      procedure Test_NameAndDomesticOrDXQTH;
      procedure Test_QSONumberNameDomesticOrDXQTH;
      procedure Test_QSONumberPrecedenceCheck;
      procedure Test_RSTAgeAndPossibleSK;
      procedure Test_RSTAge;
      procedure Test_AgeAndQSONumber_NegativeSerial;
      procedure Test_QSONumberAndAge;
      procedure Test_RSTPower_NonFOC;
      procedure Test_RSTPower_FOC;
      procedure Test_RSTAndOrGrid;
      procedure Test_QSONumberAndGridSquare;
      procedure Test_QSONumberDomesticQTH_Ukraine;
      procedure Test_QSONumberDomesticQTH_Else;
      procedure Test_QSONumberAndPossibleDomesticQTH_Default;
      procedure Test_RSTZoneAndPossibleDomesticQTH;
      procedure Test_RSTZoneOrDomesticQTH_StateBranch;
      procedure Test_RSTZoneOrDomesticQTH_ZoneBranch;
      procedure Test_QSONumberAndCoordinatesSum;
      procedure Test_ClassSection_FieldDay;
      procedure Test_QSONumberAndGeoCoordinates;
      procedure Test_RSTAndContinent;
      procedure Test_RSTDomesticQTH_Else;
      procedure Test_RSTDomesticOrDXQTH;
      procedure Test_QSONumberAndZone;
      procedure Test_RSTZone;
      procedure Test_PreviousQSONumber_PnrCarry;
      procedure Test_FrenchDept_AllNumbersBranch;
      procedure Test_FrenchDept_StateBranch;
   public
      procedure RunAllTests; override;
   end;

implementation

function EmptyRx: ContestExchange;
begin
   FillChar(Result, SizeOf(Result), 0);
end;

function EmptyMy: TMyStationExchange;
begin
   Result.MyState := '';  Result.MyGrid := '';  Result.MyName := '';
   Result.MyZone := '';   Result.MyFDClass := '';  Result.MySection := '';
   Result.MyCheck := '';  Result.MyPrec := '';  Result.MyFOCNumber := '';
   Result.MyPostalCode := '';
end;

// ---------------------------------------------------------------------------

procedure TCabrilloExchangeTests.Test_Grid;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_Grid');
   rx := EmptyRx;  my := EmptyMy;  my.MyGrid := 'EM73';  pnr := 0;
   FormatCabrilloExchange(GridExchange, GENERALQSO, '', '', rx, my, '', '', 'FN31', '', 1, pnr, MyEx, HisEx);
   CheckEquals('EM73       ', MyEx,  'Grid MyEx');
   CheckEquals('FN31       ', HisEx, 'Grid HisEx');
end;

procedure TCabrilloExchangeTests.Test_Grid2_SameAsGrid;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_Grid2_SameAsGrid');
   rx := EmptyRx;  my := EmptyMy;  my.MyGrid := 'EM73';  pnr := 0;
   FormatCabrilloExchange(Grid2Exchange, GENERALQSO, '', '', rx, my, '', '', 'FN31', '', 1, pnr, MyEx, HisEx);
   CheckEquals('EM73       ', MyEx,  'Grid2 routes same as Grid (MyEx)');
   CheckEquals('FN31       ', HisEx, 'Grid2 routes same as Grid (HisEx)');
end;

procedure TCabrilloExchangeTests.Test_RSTAndGrid3;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTAndGrid3');
   rx := EmptyRx;  my := EmptyMy;  my.MyGrid := 'EM73';  pnr := 0;
   FormatCabrilloExchange(RSTAndGrid3Exchange, GENERALQSO, '', '', rx, my, '599', '599', 'FN31', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599    EM73        ', MyEx,  'RSTAndGrid3 MyEx');
   CheckEquals('599 FN31        ', HisEx, 'RSTAndGrid3 HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTQSONumber;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTQSONumber');
   rx := EmptyRx;  rx.NumberSent := 1;  rx.NumberReceived := 2;  my := EmptyMy;  pnr := 0;
   FormatCabrilloExchange(RSTQSONumberExchange, GENERALQSO, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 001 ', MyEx,  'RSTQSONumber MyEx');
   CheckEquals('599 002', HisEx,  'RSTQSONumber HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTNameAndQTH;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTNameAndQTH');
   rx := EmptyRx;  rx.Name := 'BOB';  my := EmptyMy;  my.MyName := 'TOM';  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(RSTNameAndQTHExchange, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 TOM   FL     ', MyEx,  'RSTNameAndQTH MyEx');
   CheckEquals('599 BOB   GA     ', HisEx, 'RSTNameAndQTH HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberAndName;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberAndName');
   rx := EmptyRx;  rx.Name := 'BOB';  rx.NumberSent := 1;  rx.NumberReceived := 2;
   my := EmptyMy;  my.MyName := 'TOM';  pnr := 0;
   FormatCabrilloExchange(QSONumberAndNameExchange, GENERALQSO, '', '', rx, my, '', '', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('1   TOM    ', MyEx,  'QSONumberAndName MyEx');
   CheckEquals('2   BOB    ', HisEx, 'QSONumberAndName HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTAndPostalCode;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTAndPostalCode');
   rx := EmptyRx;  rx.QTHString := '54321';  my := EmptyMy;  my.MyPostalCode := '12345';  pnr := 0;
   FormatCabrilloExchange(RSTAndPostalCodeExchange, GENERALQSO, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 12345     ', MyEx,  'RSTAndPostalCode MyEx (contacts=1 uses MyPostalCode)');
   CheckEquals('599 54321     ', HisEx, 'RSTAndPostalCode HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTQSONumberAndGridSquare;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTQSONumberAndGridSquare');
   rx := EmptyRx;  rx.NumberSent := 12;  rx.NumberReceived := 34;  my := EmptyMy;  my.MyGrid := 'EM73';  pnr := 0;
   FormatCabrilloExchange(RSTQSONumberAndGridSquareExchange, GENERALQSO, '', '', rx, my, '599', '599', 'FN31', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 0012 EM73   ', MyEx,  'RSTQSONumberAndGridSquare MyEx');
   CheckEquals('599 0034 FN31   ', HisEx, 'RSTQSONumberAndGridSquare HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTQSONumberOrDomesticQTH;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTQSONumberOrDomesticQTH');
   rx := EmptyRx;  rx.NumberReceived := 5;  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(RSTQSONumberOrDomesticQTHExchange, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599  FL      ', MyEx,  'RSTQSONumberOrDomesticQTH MyEx (state branch)');
   CheckEquals('599      5 GA    ', HisEx, 'RSTQSONumberOrDomesticQTH HisEx (nr>=1 branch)');
end;

procedure TCabrilloExchangeTests.Test_RSTPrefecture;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTPrefecture');
   rx := EmptyRx;  my := EmptyMy;  my.MyZone := '25';  pnr := 0;
   FormatCabrilloExchange(RSTPrefectureExchange, GENERALQSO, '', '', rx, my, '599', '599', '14', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 25     ', MyEx,  'RSTPrefecture MyEx');
   CheckEquals('599 14     ', HisEx, 'RSTPrefecture HisEx');
end;

procedure TCabrilloExchangeTests.Test_NameAndDomesticOrDXQTH;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_NameAndDomesticOrDXQTH');
   rx := EmptyRx;  rx.Name := 'BOB';  my := EmptyMy;  my.MyName := 'TOM';  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(NameAndDomesticOrDXQTHExchange, GENERALQSO, '', '', rx, my, '', '', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('  TOM        FL  ', MyEx,  'NameAndDomesticOrDXQTH MyEx');
   CheckEquals('  BOB        GA  ', HisEx, 'NameAndDomesticOrDXQTH HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberNameDomesticOrDXQTH;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberNameDomesticOrDXQTH');
   rx := EmptyRx;  rx.Name := 'BOB';  rx.QTHString := 'GA';  rx.NumberSent := 1;  rx.NumberReceived := 2;
   my := EmptyMy;  my.MyName := 'TOM';  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(QSONumberNameDomesticOrDXQTHExchange, GENERALQSO, '', '', rx, my, '', '', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('1    TOM     FL      ', MyEx,  'QSONumberNameDomesticOrDXQTH MyEx');
   CheckEquals('2    BOB   GA  ', HisEx, 'QSONumberNameDomesticOrDXQTH HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberPrecedenceCheck;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberPrecedenceCheck');
   rx := EmptyRx;  rx.NumberSent := 12;  rx.NumberReceived := 34;  rx.Precedence := 'A';  rx.Check := 72;
   my := EmptyMy;  my.MyPrec := 'B';  my.MyCheck := '59';  my.MySection := 'GA';  pnr := 0;
   FormatCabrilloExchange(QSONumberPrecedenceCheckDomesticQTHExchange, GENERALQSO, '', '', rx, my, '', '', 'SC', '', 1, pnr, MyEx, HisEx);
   CheckEquals('12   B 59 GA  ', MyEx,  'SS MyEx');
   CheckEquals('34   A 72 SC ', HisEx, 'SS HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTAgeAndPossibleSK;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTAgeAndPossibleSK');
   rx := EmptyRx;  rx.Age := 42;  my := EmptyMy;  my.MyState := 'SK';  pnr := 0;
   FormatCabrilloExchange(RSTAgeAndPossibleSK, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 SK              ', MyEx,  'RSTAgeAndPossibleSK MyEx');
   CheckEquals('599 42 GA', HisEx, 'RSTAgeAndPossibleSK HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTAge;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTAge');
   rx := EmptyRx;  rx.Age := 42;  my := EmptyMy;  my.MyState := 'SK';  pnr := 0;
   FormatCabrilloExchange(RSTAgeExchange, GENERALQSO, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 SK     ', MyEx,  'RSTAge MyEx');
   CheckEquals('599 42     ', HisEx, 'RSTAge HisEx');
end;

procedure TCabrilloExchangeTests.Test_AgeAndQSONumber_NegativeSerial;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_AgeAndQSONumber_NegativeSerial');
   rx := EmptyRx;  rx.NumberSent := -1;  rx.Age := 25;  rx.NumberReceived := 5;
   my := EmptyMy;  my.MyState := 'XY';  pnr := 0;
   FormatCabrilloExchange(AgeAndQSONumberExchange, GENERALQSO, '', '', rx, my, '', '', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('XY -01 ', MyEx,  'AgeQSO neg-serial MyEx');
   CheckEquals(' 25  0005', HisEx, 'AgeQSO HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberAndAge;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberAndAge');
   rx := EmptyRx;  rx.RSTSent := 59;  rx.NumberSent := 7;  rx.Age := 25;  rx.NumberReceived := 3;
   my := EmptyMy;  my.MyState := 'XY';  pnr := 0;
   FormatCabrilloExchange(QSONumberAndAgeExchange, GENERALQSO, '', '', rx, my, '', '', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('59  007 XY      ', MyEx,  'QSONumberAndAge MyEx');
   CheckEquals(' 59    3 25', HisEx, 'QSONumberAndAge HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTPower_NonFOC;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTPower_NonFOC');
   rx := EmptyRx;  rx.Power := '100W';  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(RSTPowerExchange, GENERALQSO, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 FL     ', MyEx,  'RSTPower non-FOC MyEx');
   CheckEquals('599 100W   ', HisEx, 'RSTPower non-FOC HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTPower_FOC;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTPower_FOC');
   rx := EmptyRx;  rx.Power := '1234';  my := EmptyMy;  my.MyFOCNumber := '5678';  pnr := 0;
   FormatCabrilloExchange(RSTPowerExchange, FOCMARATHON, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 5678   ', MyEx,  'RSTPower FOC MyEx (my FOC number)');
   CheckEquals('599 1234   ', HisEx, 'RSTPower FOC HisEx (his FOC number from Power)');
end;

procedure TCabrilloExchangeTests.Test_RSTAndOrGrid;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTAndOrGrid');
   rx := EmptyRx;  my := EmptyMy;  my.MyGrid := 'EM73';  pnr := 0;
   FormatCabrilloExchange(RSTAndOrGridExchange, GENERALQSO, '', '', rx, my, '599', '599', 'FN31', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 EM73   ', MyEx,  'RSTAndOrGrid MyEx');
   CheckEquals('599 FN31   ', HisEx, 'RSTAndOrGrid HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberAndGridSquare;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberAndGridSquare');
   rx := EmptyRx;  rx.NumberSent := 12;  rx.NumberReceived := 34;  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(QSONumberAndGridSquare, GENERALQSO, '', '', rx, my, '', '', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('012 FL     ', MyEx,  'QSONumberAndGridSquare MyEx');
   CheckEquals('0034 GA    ', HisEx, 'QSONumberAndGridSquare HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberDomesticQTH_Ukraine;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberDomesticQTH_Ukraine');
   rx := EmptyRx;  rx.NumberSent := 12;  rx.NumberReceived := 34;  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(QSONumberDomesticQTHExchange, UKRAINECHAMPIONSHIP, '', '', rx, my, '', '', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('FL   0012  ', MyEx,  'QSONumberDomesticQTH Ukraine MyEx');
   CheckEquals('GA   0034  ', HisEx, 'QSONumberDomesticQTH Ukraine HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberDomesticQTH_Else;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberDomesticQTH_Else');
   rx := EmptyRx;  rx.NumberSent := 12;  rx.NumberReceived := 34;  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(QSONumberDomesticQTHExchange, GENERALQSO, '', '', rx, my, '', '', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('12   FL    ', MyEx,  'QSONumberDomesticQTH else MyEx');
   CheckEquals('0034 GA    ', HisEx, 'QSONumberDomesticQTH else HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberAndPossibleDomesticQTH_Default;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberAndPossibleDomesticQTH_Default');
   rx := EmptyRx;  rx.NumberSent := 12;  rx.NumberReceived := 34;  rx.QTHString := 'GA';
   my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(QSONumberAndPossibleDomesticQTHExchange, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 0012     FL      ', MyEx,  'QSONumberAndPossibleDomesticQTH default MyEx (%6s = my state)');
   CheckEquals('599 0034   GA', HisEx, 'QSONumberAndPossibleDomesticQTH default HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTZoneAndPossibleDomesticQTH;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTZoneAndPossibleDomesticQTH');
   rx := EmptyRx;  rx.Zone := 5;  rx.QTHString := 'GA';  my := EmptyMy;  my.MyState := 'FL';  my.MyZone := '14';  pnr := 0;
   FormatCabrilloExchange(RSTZoneAndPossibleDomesticQTHExchange, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 14 FL  ', MyEx,  'RSTZoneAndPossibleDomesticQTH MyEx');
   CheckEquals('599 05 GA ', HisEx, 'RSTZoneAndPossibleDomesticQTH HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTZoneOrDomesticQTH_StateBranch;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTZoneOrDomesticQTH_StateBranch');
   rx := EmptyRx;  rx.QTHString := 'GA';  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(RSTZoneOrDomesticQTH, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 FL     ', MyEx,  'RSTZoneOrDomesticQTH state MyEx');
   CheckEquals('599 GA     ', HisEx, 'RSTZoneOrDomesticQTH QTH HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTZoneOrDomesticQTH_ZoneBranch;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTZoneOrDomesticQTH_ZoneBranch');
   rx := EmptyRx;  rx.Zone := 5;  rx.QTHString := '';  my := EmptyMy;  my.MyState := '';  my.MyZone := '14';  pnr := 0;
   FormatCabrilloExchange(RSTZoneOrSocietyExchange, GENERALQSO, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 14     ', MyEx,  'RSTZoneOrSociety zone MyEx');
   CheckEquals('599 5      ', HisEx, 'RSTZoneOrSociety zone HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberAndCoordinatesSum;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberAndCoordinatesSum');
   rx := EmptyRx;  rx.NumberSent := 34;  rx.NumberReceived := 78;  my := EmptyMy;  my.MyState := '12';  pnr := 0;
   FormatCabrilloExchange(QSONumberAndCoordinatesSum, GENERALQSO, '', '', rx, my, '', '', '56', '', 1, pnr, MyEx, HisEx);
   CheckEquals('12  0034    ', MyEx,  'QSONumberAndCoordinatesSum MyEx');
   CheckEquals('56  0078', HisEx, 'QSONumberAndCoordinatesSum HisEx');
end;

procedure TCabrilloExchangeTests.Test_ClassSection_FieldDay;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_ClassSection_FieldDay');
   rx := EmptyRx;  rx.ceClass := '2A';  rx.QTHString := 'SC';  my := EmptyMy;  my.MyFDClass := '3A';  my.MySection := 'GA';  pnr := 0;
   FormatCabrilloExchange(ClassDomesticOrDXQTHExchange, ARRLFIELDDAY, '', '', rx, my, '', '', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('3A  GA      ', MyEx,  'FD MyEx');
   CheckEquals('2A  SC     ', HisEx, 'FD HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberAndGeoCoordinates;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberAndGeoCoordinates');
   rx := EmptyRx;  rx.NumberSent := 12;  rx.NumberReceived := 34;  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(QSONumberAndGeoCoordinates, GENERALQSO, '', '', rx, my, '', '', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('0012 FL      ', MyEx,  'QSONumberAndGeoCoordinates MyEx');
   CheckEquals('0034 GA     ', HisEx, 'QSONumberAndGeoCoordinates HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTAndContinent;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTAndContinent');
   rx := EmptyRx;  rx.QTHString := 'SA';  my := EmptyMy;  my.MyState := 'NA';  pnr := 0;
   FormatCabrilloExchange(RSTAndContinentExchange, GENERALQSO, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 NA     ', MyEx,  'RSTAndContinent MyEx');
   CheckEquals('599 SA     ', HisEx, 'RSTAndContinent HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTDomesticQTH_Else;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTDomesticQTH_Else');
   rx := EmptyRx;  rx.QTHString := 'GA';  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(RSTDomesticQTHExchange, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 FL     ', MyEx,  'RSTDomesticQTH else MyEx');
   CheckEquals('599 GA     ', HisEx, 'RSTDomesticQTH else HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTDomesticOrDXQTH;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTDomesticOrDXQTH');
   rx := EmptyRx;  rx.QTHString := 'GA';  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(RSTDomesticOrDXQTHExchange, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 FL     ', MyEx,  'RSTDomesticOrDXQTH MyEx');
   CheckEquals('599 GA     ', HisEx, 'RSTDomesticOrDXQTH HisEx');
end;

procedure TCabrilloExchangeTests.Test_QSONumberAndZone;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_QSONumberAndZone');
   rx := EmptyRx;  rx.Zone := 5;  rx.NumberSent := 12;  rx.NumberReceived := 34;  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(QSONumberAndZone, GENERALQSO, '', '', rx, my, '', '', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('  FL    0012 ', MyEx,  'QSONumberAndZone MyEx');
   CheckEquals('  5      034', HisEx, 'QSONumberAndZone HisEx');
end;

procedure TCabrilloExchangeTests.Test_RSTZone;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_RSTZone');
   rx := EmptyRx;  rx.Zone := 5;  my := EmptyMy;  my.MyZone := '14';  pnr := 0;
   FormatCabrilloExchange(RSTZoneExchange, GENERALQSO, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 14     ', MyEx,  'RSTZone MyEx');
   CheckEquals('599 05     ', HisEx, 'RSTZone HisEx');
end;

procedure TCabrilloExchangeTests.Test_PreviousQSONumber_PnrCarry;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_PreviousQSONumber_PnrCarry');
   rx := EmptyRx;  rx.NumberSent := 2;  rx.NumberReceived := 456789;  my := EmptyMy;  pnr := 123;
   FormatCabrilloExchange(QSONumberAndPreviousQSONumber, GENERALQSO, '', '', rx, my, '', '', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('1230002   ', MyEx,  'YOC MyEx');
   CheckEquals('04560789', HisEx, 'YOC HisEx');
   CheckEquals('789', IntToStr(pnr), 'YOC pnr carried forward = rxnr');
end;

procedure TCabrilloExchangeTests.Test_FrenchDept_AllNumbersBranch;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_FrenchDept_AllNumbersBranch');
   rx := EmptyRx;  rx.NumberSent := 7;  rx.NumberReceived := 31;  my := EmptyMy;  my.MyState := '014';  pnr := 0;
   FormatCabrilloExchange(RSTAndQSONumberOrFrenchDepartmentExchange, PCC, '', '', rx, my, '599', '599', '', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599  0007/M   ', MyEx,  'FrenchDept /M branch MyEx');
   CheckEquals('599 031', HisEx, 'FrenchDept serial HisEx');
end;

procedure TCabrilloExchangeTests.Test_FrenchDept_StateBranch;
var rx: ContestExchange; my: TMyStationExchange; pnr: integer; MyEx, HisEx: string;
begin
   BeginTest('Test_FrenchDept_StateBranch');
   rx := EmptyRx;  rx.NumberReceived := 31;  rx.QTHString := 'GA';  my := EmptyMy;  my.MyState := 'FL';  pnr := 0;
   FormatCabrilloExchange(RSTAndQSONumberOrFrenchDepartmentExchange, GENERALQSO, '', '', rx, my, '599', '599', 'GA', '', 1, pnr, MyEx, HisEx);
   CheckEquals('599 FL     ', MyEx,  'FrenchDept state MyEx');
   CheckEquals('599 GA ', HisEx, 'FrenchDept QTH HisEx');
end;

// ---------------------------------------------------------------------------

procedure TCabrilloExchangeTests.RunAllTests;
begin
   Test_Grid;
   Test_Grid2_SameAsGrid;
   Test_RSTAndGrid3;
   Test_RSTQSONumber;
   Test_RSTNameAndQTH;
   Test_QSONumberAndName;
   Test_RSTAndPostalCode;
   Test_RSTQSONumberAndGridSquare;
   Test_RSTQSONumberOrDomesticQTH;
   Test_RSTPrefecture;
   Test_NameAndDomesticOrDXQTH;
   Test_QSONumberNameDomesticOrDXQTH;
   Test_QSONumberPrecedenceCheck;
   Test_RSTAgeAndPossibleSK;
   Test_RSTAge;
   Test_AgeAndQSONumber_NegativeSerial;
   Test_QSONumberAndAge;
   Test_RSTPower_NonFOC;
   Test_RSTPower_FOC;
   Test_RSTAndOrGrid;
   Test_QSONumberAndGridSquare;
   Test_QSONumberDomesticQTH_Ukraine;
   Test_QSONumberDomesticQTH_Else;
   Test_QSONumberAndPossibleDomesticQTH_Default;
   Test_RSTZoneAndPossibleDomesticQTH;
   Test_RSTZoneOrDomesticQTH_StateBranch;
   Test_RSTZoneOrDomesticQTH_ZoneBranch;
   Test_QSONumberAndCoordinatesSum;
   Test_ClassSection_FieldDay;
   Test_QSONumberAndGeoCoordinates;
   Test_RSTAndContinent;
   Test_RSTDomesticQTH_Else;
   Test_RSTDomesticOrDXQTH;
   Test_QSONumberAndZone;
   Test_RSTZone;
   Test_PreviousQSONumber_PnrCarry;
   Test_FrenchDept_AllNumbersBranch;
   Test_FrenchDept_StateBranch;
end;

end.
