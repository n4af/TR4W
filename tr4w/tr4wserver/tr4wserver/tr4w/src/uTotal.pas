unit uTotal;
{$IMPORTEDDATA OFF}
interface

uses
  TF,
  VC,
  uMults,
  Windows,
  PostUnit,
  LogWind,
  LogDupe,
  LogEdit,
  Tree
  ;

var
  TotWinCurrrentColumn             : integer;
  Column                           : integer;
  Row                              : integer;

procedure DisplayBandTotals(Band: BandType);
procedure UpdateTotals2;
procedure ClearTotals(StartColumn: integer);

implementation

procedure TotalTextOut(s: PChar; X, Y: integer);
begin
  if s = nil then
    if TotWinHandlesFilled[X, Y] = False then Exit;
  Windows.SetWindowText(TotWinHandles[X, Y], s);
  TotWinHandlesFilled[X, Y] := s <> nil;
end;

procedure WriteLeftColumnText(Text: PChar);
begin
  inc(Row);
  TotalTextOut(Text, 0, Row);
end;

procedure iTotalTextOut(Number: integer);
var
  TempPchar                        : PChar;
begin
  inc(Row);

  if Number = 0 then TempPchar := nil else TempPchar := inttopchar(Number);
  TotalTextOut(TempPchar, Column, Row);
{
  if Number = 0 then
    Windows.SetWindowText(TotWinHandles[Column, Row], nil)
  else
    Windows.SetWindowText(TotWinHandles[Column, Row], inttopchar(Number));
}
end;

procedure DisplayBandTotals(Band: BandType);

var
  MultDisplayEnable                : boolean;
//  col_title                             : PChar;
  ActiveMode                       : ModeType;
  TempMode                         : ModeType;
begin
  ActiveMode := LogWind.ActiveMode;
  if ActiveMode = FM then ActiveMode := Phone;

  if Band = NoBand then
  begin
    ClearTotals(1);
    Exit;
  end;
//  col_title := BandStringsArrayWithOutSpaces[Band];
  inc(Column);
  if Band = All then Column := 7;
  {
    if Band in [Band160..Band10] then Column := integer(Band) + 1;

    if Band in [Band30..Band12] then
      begin
        if Band = Band30 then Column := 1;
        if Band = Band20 then Column := 2;
        if Band = Band17 then Column := 3;
        if Band = Band15 then Column := 4;
        if Band = Band12 then Column := 5;
        if Band = Band10 then Column := 6;
      end;

    if Band > Band10 then
      begin
        if Band in [Band6..Band1296] then Column := integer(Band) - 8;
      end;

    if Band > Band1296 then
      begin
        if Band in [Band2304..BandLight] then Column := integer(Band) - 14;
      end;
  }
  if Band = ActiveBand then
  begin
      //      Windows.SendMessage(TotWinheadHandles[Column], BM_SETCHECK, BST_CHECKED, 0);
    TotWinCurrrentColumn := Column;
  end;
  Windows.SetWindowText(TotWinheadHandles[Column], {col_title} BandStringsArrayWithOutSpaces[Band]);

  Row := -1;
  MultDisplayEnable := True;

  if QSOByMode then
  begin

    if (ActiveMode = CW) or ((QTotals[All, CW] > 0) and (NumberDifferentMults < 3)) then iTotalTextOut(QTotals[Band, CW]);
    if (ActiveMode = Phone) or ((QTotals[All, Phone] > 0) and (NumberDifferentMults < 3)) then iTotalTextOut(QTotals[Band, Phone]);
    if (ActiveMode = Digital) or ((QTotals[All, Digital] > 0) and (NumberDifferentMults < 3)) then iTotalTextOut(QTotals[Band, Digital]);
  end
  else
    iTotalTextOut(QTotals[Band, Both]);

  if MultByMode then TempMode := ActiveMode else TempMode := Both;

  if (DoingDomesticMults) and (MultByBand or (Band = All)) and MultDisplayEnable then
  begin
{
    if MultByMode then
      iTotalTextOut(MTotals[Band, ActiveMode].NumberDomesticMults)
    else
      iTotalTextOut(MTotals[Band, Both].NumberDomesticMults);
}
    iTotalTextOut(mo.MTotals[Band, TempMode, rmDomestic]);
  end;

  if (DoingDXMults) and (MultByBand or (Band = All)) and MultDisplayEnable {and (ActiveDXMult <> NoCountDXMults)} then
  begin
{
    if MultByMode then
      iTotalTextOut(MTotals[Band, ActiveMode].NumberDXMults)
    else
      iTotalTextOut(MTotals[Band, Both].NumberDXMults);
}
    iTotalTextOut(mo.MTotals[Band, TempMode, rmDX]);
  end;

  if (DoingPrefixMults) and (MultByBand or (Band = All)) and MultDisplayEnable then
  begin
{
    if MultByMode then
      iTotalTextOut(MTotals[Band, ActiveMode].NumberPrefixMults)
    else
      iTotalTextOut(MTotals[Band, Both].NumberPrefixMults);
}
    iTotalTextOut(mo.MTotals[Band, TempMode, rmPrefix]);
  end;

  if (DoingZoneMults) and (MultByBand or (Band = All)) and MultDisplayEnable then
  begin
{
    if MultByMode then
      iTotalTextOut(MTotals[Band, ActiveMode].NumberZoneMults)
    else
      iTotalTextOut(MTotals[Band, Both].NumberZoneMults);
}
    iTotalTextOut(mo.MTotals[Band, TempMode, rmZone]);
  end;
end;

procedure UpdateTotals2;

{ This procedure will update the QSO and score information.  This is a
  generic six band total summary with both modes shown.  Someone should
  put a case statement in here someday and make it more appropriate to
  different contest.                                                    }

var
  i                                : integer;
  TempBand                         : BandType;
  ActiveMode                       : ModeType;
begin
  ActiveMode := LogWind.ActiveMode;
  if ActiveMode = FM then ActiveMode := Phone;
  TotWinCurrrentColumn := -1;
  Column := 0;
  ClearTotals(0);
  QTotals := QSOTotals;

//  Sheet.MultSheetTotals(MTotals);

//  CallsignsList.DisplayDupeSheet(@Radio1);
//  CallsignsList.DisplayDupeSheet(@Radio2);

  Row := -1;
  if QSOByMode then
  begin
    if (ActiveMode = CW) or ((QTotals[All, CW] > 0) and (NumberDifferentMults < 3)) then WriteLeftColumnText(TC_CWQSOS);
    if (ActiveMode = Phone) or ((QTotals[All, Phone] > 0) and (NumberDifferentMults < 3)) then WriteLeftColumnText(TC_SSBQSOS);
    if (ActiveMode = Digital) or ((QTotals[All, Digital] > 0) and (NumberDifferentMults < 3)) then WriteLeftColumnText(TC_DIGQSOS);
  end
  else
    WriteLeftColumnText(TC_QSOS);

  if DoingDomesticMults then
  begin
    if MultByMode then
    begin
      if Contest = IARU then
      begin
        if ActiveMode = CW then WriteLeftColumnText('CW HQ');
        if ActiveMode = Phone then WriteLeftColumnText('Ph HQ');
      end
      else
      begin
        if ActiveMode = CW then WriteLeftColumnText('CW Dom');
        if ActiveMode = Phone then WriteLeftColumnText('Ph Dom');
      end;
    end
    else
    begin
      begin
        if Contest = IARU then WriteLeftColumnText(TC_HQMULTS)
        else
          if Contest = RUSSIANDX then WriteLeftColumnText(TC_OBLASTS)
          else
            WriteLeftColumnText(TC_DOMMULTS);
      end;
    end;
  end;

  if DoingDXMults {and (ActiveDXMult <> NoCountDXMults)} then
  begin
    if MultByMode then
    begin
      if ActiveMode = CW then WriteLeftColumnText('CW DX');
      if ActiveMode = Phone then WriteLeftColumnText('Ph DX');
    end
    else
      WriteLeftColumnText(TC_DXMULTS);

  end;

  if DoingPrefixMults then
  begin
    if MultByMode then
    begin
      if ActiveMode = CW then WriteLeftColumnText('CW Pfxs');
      if ActiveMode = Phone then WriteLeftColumnText('Ph Pfxs');
    end
    else
      WriteLeftColumnText(TC_PREFIX);
  end;

  if DoingZoneMults then
  begin
    if MultByMode then
    begin
      if ActiveMode = CW then WriteLeftColumnText('CW Zone');
      if ActiveMode = Phone then WriteLeftColumnText('Ph Zone');
    end
    else
      WriteLeftColumnText(TC_ZONE);

  end;

  {--------------------------------------------------}

  if ActiveBand in [Band160..Band10] then
  begin
    for TempBand := Band160 to Band10 do DisplayBandTotals(TempBand);
  end
  else
    if ActiveBand in [Band30..Band12] then
    begin
      DisplayBandTotals(Band30);
      DisplayBandTotals(Band20);
      DisplayBandTotals(Band17);
      DisplayBandTotals(Band15);
      DisplayBandTotals(Band12);
      DisplayBandTotals(Band10);
    end
    else
      if
        ActiveBand in [Band6..Band1296] then
      begin
        for TempBand := Band6 to Band1296 do DisplayBandTotals(TempBand);
      end
      else
        if
          ActiveBand in [Band2304..BandLight] then
        begin
          for TempBand := Band2304 to BandLight do DisplayBandTotals(TempBand);
        end;
  if ActiveBand = NoBand then
  begin
    DisplayBandTotals(NoBand);
  end;
  DisplayBandTotals(All);

  if QTCsEnabled then
  begin
    WriteLeftColumnText('QTCs');
    TotalTextOut(inttopchar(TotalNumberQTCsProcessed), Column, Row);
    if MyContinent <> Europe then
    begin
      WriteLeftColumnText(TC_QTCPENDING);
      TotalTextOut(inttopchar(TotalContacts - TotalNumberQTCsProcessed), Column, Row);
    end
    else
    begin

//      TotalTextOut(inttopchar(TotalNumberQTCsProcessed), 1, col_counter);
//      iTotalTextOut(TotalNumberQTCsProcessed);

    end;

{
    WriteLeftColumnText('QTCs');
    TotalTextOut(inttopchar(TotalNumberQTCsProcessed), 1, col_counter);
    if MyContinent <> Europe then
    begin
          //          inc(col_counter);
      WriteLeftColumnText('Pending');
          //          TotalTextOut(inttopchar(TotalPendingQTCs), 1, col_counter);
    end
    else
    begin

          //      TotalTextOut('QTCs received', 0, col_counter);
          //      TotalTextOut(inttoPChar(TotalNumberQTCsProcessed), 1, col_counter);
          //      Write ('Number QTCs received = ', TotalNumberQTCsProcessed);
    end;
}
  end;
  for i := 1 to 6 do InvalidateRect(TotWinheadHandles[i], nil, True);
end;

procedure ClearTotals(StartColumn: integer);
var
  c, r                             : integer;
begin
  for c := StartColumn to 7 do
    for r := 0 to 3 do
      TotalTextOut(nil, c, r);
end;

end.

