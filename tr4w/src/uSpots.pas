{
 Copyright Dmitriy Gulyaev UA4WLI 2015.

 This file is part of TR4W  (SRC)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT. 
If not, ref:
http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit uSpots;
{$IMPORTEDDATA OFF}

interface

uses
  VC,
  TF,
  uDupesheet,
  LogStuff,
  WinSock2,
  Windows,
  Messages,
  LogEdit,
  LogPack,
  Tree;

type

//  PSpotRecord = ^TSpotRecord;

  PSpotsList = ^TSpotsList;
  TSpotsList = array[0..1000] of TSpotRecord;

  PSpotsListBuffer = ^TSpotsListBuffer;                              // Gav 4.45.6
  TSpotsListBuffer = array[0..1000] of TSpotRecord;                  // Gav 4.45.6

  TDXSpotsList = object {class}

  private
    FList: PSpotsList;
    FCount: integer;
    FCurrentCursorFreq: integer;
    FCapacity: integer;
    BList: PSpotsListBuffer;                                        // Gav 4.45.6
    BCount: integer;                                                // Gav 4.45.6
    BCapacity: integer;                                             // Gav 4.45.6
    procedure Grow;
    procedure GrowBuffer;                                           // Gav 4.45.6

  protected
    function GetCapacity: integer;
    procedure SetCapacity(NewCapacity: integer);
    procedure SetCapacityBuffer(NewCapacity: integer);                                   // Gav 4.45.6
    function CompareStrings(const s1, s2: CallString): integer;
    procedure InsertSpot(Index: integer; const Spot: TSpotRecord); virtual;
    procedure InsertSpotBuffer(Index: integer; const Spot: TSpotRecord); virtual;       // Gav 4.45.6

  public
//    destructor Destroy; override;
    constructor Init;
    function Get(Index: integer): TSpotRecord;
    function AddSpot(var Spot: TSpotRecord; SendToNetwork: boolean): integer;
    procedure Clear;
    procedure SendAndClearBuffer;
    procedure SetCursor;
    procedure DecrementSpotsTimes;
    procedure UpdateSpotsMultiplierStatus;
    procedure UpdateSpotsDupeStatus(RXCall: CallString; RXBand: BandType; RXMode: ModeType);
    procedure Display;
    procedure Delete(Index: integer);
    //    procedure ClearDupes;
    procedure ResetSpotsTimes;
    procedure ResetSpotsDupes;

    procedure DisplayCallsignOnThisFreq(Freq: integer);
    procedure TuneDupeCheck(Freq: integer);
    function FindSpot(const Spot: TSpotRecord; var Index: integer): boolean; virtual;
    property Count: integer read FCount;
  end;

var
  SpotsList                             : TDXSpotsList;
  SpotsDisplayed                        : integer;

implementation
uses
  LOGSUBS2,
  MainUnit,
  uNet,
  uBandmap,
  LogDupe,
  LogWind;

{ TStringList }

constructor TDXSpotsList.Init;
begin
  Grow;
  GrowBuffer;                                       // Gav 4.45.6
end;
{
destructor TDXSpotsList.Destroy;
begin
  inherited Destroy;
  if FCount <> 0 then Finalize(FList^[0], FCount);
  FCount := 0;
  SetCapacity(0);
end;
}

function TDXSpotsList.AddSpot(var Spot: TSpotRecord; SendToNetwork: boolean): integer;
label
add;
var
  i                                     : integer;

begin

  if BandMapPreventRefresh then                     // Gav 4.45.6
    begin
       InsertSpotBuffer(Bcount , Spot);             // Gav 4.45.6
    end
  else
    begin
      SetCursor;

      for i := 0 to FCount - 1 do
      begin
          if FList^[i].FBand = Spot.FBand then
          if FList^[i].FCall = Spot.FCall then
            begin
              Delete(i);
              Break;
            end;
      end;
      if Spot.FBand in [Band30, Band17, Band12] then Spot.FWARCBand := True;

      if FindSpot(Spot, Result) then goto Add;
      InsertSpot(Result, Spot);
      Add:
      FList^[Result] := Spot;
    end;

      if SendToNetwork then
      if PInteger(@Spot.FCall[1])^ <> tCQAsInteger then
      if NetSocket <> 0 then
      begin
        NetDXSpot.dsSpot := Spot;
        SendToNet(NetDXSpot, SizeOf(NetDXSpot));
      end;

end;


procedure TDXSpotsList.Display;
var
   FiltSpotIndex                           : Array of Integer;
   FilteredSpotCount                       : integer;
   k                                       : integer;
   i                                       : integer;
   bottom                                  : integer;
   top                                     : integer;
   centre                                  : integer;
   centrefound                             : boolean;
  CurrentCursorPos                         : integer;
//    CurCursorPosData                     : integer;
  NumberEntriesDisplayed                   : integer;
begin

//  inc(SpotsDisplayed);
//  setwindowtext(OpModeWindowHandle,inttopchar(SpotsDisplayed));
  if BandMapListBox = 0 then Exit;
  if  BandMapPreventRefresh then  Exit;                                       // Gav 4.45.6
  TDXSpotsList.UpdateSpotsMultiplierStatus;
  CurrentCursorPos := tLB_GETCURSEL(BandMapListBox); //0;
  setlength(FiltSpotIndex, FCount);
  NumberEntriesDisplayed := 0;
  k := 0;                                                     
  i := 0;


  for i := 0 to FCount - 1 do
  begin
    if not BandMapAllBands then if FList^[i].FBand <> BandmapBand then Continue;       //Gav  ActiveBand changed to BandmapBand
    if not BandMapAllModes then if FList^[i].FMode <> BandmapMode then Continue;        //Gav  ActiveMode changed to BandmapMode
    if not BandMapDupeDisplay then if FList^[i].FDupe then Continue;
    if not BandMapDisplayCQ then if FList^[i].FCQ then Continue;
    if not WARCBandsEnabled then if FList^[i].FWARCBand then Continue;
    if BandMapMultsOnly then if not ((FList^[i].FMult) or (FList^[i].FCQ)) then Continue;     //Gav added or FCQ to stop CQ spots being trapped by Mult only filter
    if not VHFBandsEnabled then if (FList^[i].FBand > Band12) then Continue;

   // SendMessage(BandMapListBox, LB_ADDSTRING, 0, integer(i));         //GAV original message send


   if FList^[i].FFrequency = FCurrentCursorFreq then     CurrentCursorPos := NumberEntriesDisplayed;
   FiltSpotIndex[k]:= i;
   inc(NumberEntriesDisplayed);
   inc(k);

   end;

   //Gav   Start of added section to limit and centre bandmap on vfo, using pointers to Flist stored in FiltSpotIndex arrray

   FilteredSpotCount  := k;

    if k > BandMapDisplayLimit then
        begin
            if FList^[0].FFrequency >= BandMapCursorFrequency then
              begin
                top := BandMapDisplayLimit - 1;
                bottom := 0;
                centrefound := true;
              end;

            if FList^[FilteredSpotCount].FFrequency <= BandMapCursorFrequency then
              begin
                top := FilteredSpotCount - 1;
                bottom := FilteredSpotCount - BandMapDisplayLimit;
                centrefound := true;
              end;

                    for   k := 0 to k - 1  do
                         begin
                            if FList^[FiltSpotIndex[k]].FFrequency > BandMapCursorFrequency then
                              begin
                                centre := k;
                                if (centre >= (BandMapDisplayLimit div 2)) and (centre <= (FilteredSpotCount - (BandMapDisplayLimit div 2))) then
                                    begin
                                      top := centre + ((BandMapDisplayLimit div 2) - 1);
                                      bottom := centre - (BandMapDisplayLimit div 2);
                                      centrefound := true;
                                    end;
                                if  centre > (FilteredSpotCount - (BandMapDisplayLimit div 2)) then
                                    begin
                                      top := FilteredSpotCount - 1;
                                      bottom := FilteredSpotCount - BandMapDisplayLimit;
                                      centrefound := true;
                                    end;
                                if centre < (BandMapDisplayLimit div 2) then
                                    begin
                                       top := BandMapDisplayLimit - 1;
                                       bottom := 0;
                                       centrefound := true;
                                    end;
                                break;
                              end;
                          end;

        if (centrefound <> true) then
          begin
            centre := abs((k - 1) div 2);
            top := centre + ((BandMapDisplayLimit div 2) - 1);
            bottom := centre - (BandMapDisplayLimit div 2);
          end;
        end

     else
      begin
       top := k - 1;
       bottom := 0;
      end;


      tSetWindowRedraw(BandMapListBox, False);
      tLB_RESETCONTENT(BandMapListBox);
      SendMessage(BandMapListBox, LB_INITSTORAGE, k , 10000);

      for  k := bottom to top  do SendMessage(BandMapListBox, LB_ADDSTRING, 0, FiltSpotIndex[k]);

      tLB_SETCURSEL(BandMapListBox, CurrentCursorPos);
      tSetWindowRedraw(BandMapListBox, True);
      asm push NumberEntriesDisplayed
      end;
      wsprintf(wsprintfBuffer, TC_SPOTS);
      asm add esp,12
      end;
      SetTextInBMSB(5, wsprintfBuffer);
      if NumberEntriesDisplayed = 0 then ClearSpotInfo;


end;


// Gav end of section added


procedure TDXSpotsList.Clear;
begin
  if FCount <> 0 then
  begin
    Finalize(FList^[0], FCount);
    FCount := 0;
    SetCapacity(0);
  end;
end;


procedure TDXSpotsList.SendAndClearBuffer;         // Gav 4.45.6
var
  i                            : integer;
begin
  if BCount <> 0 then
  begin
    i := BCount;
    for i := 0 to i - 1 do
      begin
         AddSpot(BList^[i],False)
      end;
  end;
  BCount := 0;
end;


procedure TDXSpotsList.Delete(Index: integer);
begin
  if (Index < 0) or (Index >= FCount) then Exit; //Error(@SListIndexError, Index);
  Finalize(FList^[Index]);
  dec(FCount);
  if Index < FCount then System.Move(FList^[Index + 1], FList^[Index], (FCount - Index) * SizeOf(TSpotRecord));
end;
{
procedure TCallsignsList.ExchangeItems(Index1, Index2: integer);
var
  temp                             : integer;
  Item1, Item2                     : PStringItem;
  DI                               : TDupesArray;
begin
  Item1 := @FList^[Index1];
  Item2 := @FList^[Index2];
  temp := integer(Item1^.FCall);
  integer(Item1^.FCall) := integer(Item2^.FCall);
  integer(Item2^.FCall) := temp;
  //  temp := integer(Item1^.FObject);
  //  integer(Item1^.FObject) := integer(Item2^.FObject);
  //  integer(Item2^.FObject) := temp;

  DI := Item1^.FDupesArray;
  Item1^.FDupesArray := Item2^.FDupesArray;
  Item2^.FDupesArray := DI;
end;
}

function TDXSpotsList.FindSpot(const Spot: TSpotRecord; var Index: integer): boolean;
var
  l, h, i, c                            : integer;
begin
  Result := False;
  l := 0;
  h := FCount - 1;
  while l <= h do
  begin
    i := (l + h) shr 1;
    c := FList^[i].FFrequency - Spot.FFrequency; //CompareStrings(FList^[I].FCall, s);
    if c < 0 then
      l := i + 1
    else
    begin
      h := i - 1;
      if c = 0 then
      begin
        Result := True;
        l := i;
      end;
    end;
  end;
  Index := l;
end;

function TDXSpotsList.Get(Index: integer): TSpotRecord;
begin
  FillChar(Result,SizeOf(Result),0); // ny4i Test to return null Issue #115
  if (Index < 0) or (Index >= FCount) then Exit; //ERROR(@SListIndexError, Index);
  Result := FList^[Index];
end;

function TDXSpotsList.GetCapacity: integer;
begin
  Result := FCapacity;
end;

procedure TDXSpotsList.UpdateSpotsMultiplierStatus;
var
  MultString                            : integer; //Str80 {20};
  i                                     : integer;
begin
  for i := 0 to FCount - 1 do
  begin

    if PInteger(@FList^[i].FCall[1])^ <> tCQAsInteger then
      if PInteger(@FList^[i].FCall[1])^ <> tNEWAsInteger then
        FList^[i].FMult := VisibleLog.DetermineIfNewMult(FList^[i].FCall, FList^[i].FBand, FList^[i].FMode);
//    FList^[i].FMult := MultString <> 0;
  end;
  //  Display;
end;

procedure TDXSpotsList.DecrementSpotsTimes;
label
  NextSpot;
var
  i                                     : integer;
  CurrentTime                           : integer;
  Difference                            : integer;
  St                                    : SYSTEMTIME;
begin
  if FCount = 0 then Exit;
  GetSystemTime(St);
  CurrentTime := St.wMinute + St.wHour * 60 + St.wDay * 60 * 24 + St.wMonth * 60 * 24 * 30;

  i := 0;
  NextSpot:

  Difference := CurrentTime - FList^[i].FSysTime;
  FList^[i].FMinutesLeft := Difference;
  if Difference >= BandMapDecayTime then
    Delete(i)
  else
    inc(i);
  if i = FCount then Exit;
  goto NextSpot;
end;

procedure TDXSpotsList.UpdateSpotsDupeStatus(RXCall: CallString; RXBand: BandType; RXMode: ModeType);
var
  i                                     : integer;
begin
  for i := 0 to FCount - 1 do
  begin
    if FList^[i].FBand = RXBand then
      if FList^[i].FMode = RXMode then
        if FList^[i].FCall = RXCall then
          FList^[i].FDupe := True;
  end;
  Display;
end;

procedure TDXSpotsList.Grow;
var
  delta                                 : integer;
begin
  if FCapacity > 64 then delta := FCapacity div 4 else
    if FCapacity > 8 then delta := 16 else
      delta := 4;
  SetCapacity(FCapacity + delta);
end;

procedure TDXSpotsList.GrowBuffer;           // Gav 4.45.6
var
  delta                                 : integer;
begin
  if BCapacity > 64 then delta := BCapacity div 4 else
    if BCapacity > 8 then delta := 16 else
      delta := 4;
  SetCapacityBuffer(BCapacity + delta);
end;


procedure TDXSpotsList.InsertSpot(Index: integer; const Spot: TSpotRecord);
begin
  if FCount = FCapacity then Grow;
  if Index < FCount then
    System.Move(FList^[Index], FList^[Index + 1],
      (FCount - Index) * SizeOf(TSpotRecord));
  FList^[Index] := Spot;
  inc(FCount);
end;


procedure TDXSpotsList.InsertSpotBuffer(Index: integer; const Spot: TSpotRecord);          // Gav 4.45.6
begin
  if BCount = BCapacity then GrowBuffer;
  if Index < BCount then
    System.Move(BList^[Index], BList^[Index + 1],
      (BCount - Index) * SizeOf(TSpotRecord));
  BList^[Index] := Spot;
  inc(BCount);
end;


procedure TDXSpotsList.SetCapacity(NewCapacity: integer);
begin
  ReallocMem(FList, NewCapacity * SizeOf(TSpotRecord));
  FCapacity := NewCapacity;
end;


procedure TDXSpotsList.SetCapacityBuffer(NewCapacity: integer);          // Gav 4.45.6
begin
  ReallocMem(BList, NewCapacity * SizeOf(TSpotRecord));
  BCapacity := NewCapacity;
end;



function TDXSpotsList.CompareStrings(const s1, s2: CallString): integer;
var
  L1, L2, l, i                          : integer;
begin
  L1 := length(s1);
  L2 := length(s2);
  if L1 > L2 then l := L2 else l := L1;
  for i := 1 to l do
  begin
    Result := Ord(s1[i]) - Ord(s2[i]);
    if Result <> 0 then Exit;
  end;
  if Result = 0 then Result := L1 - L2;

  //  Result := CompareString(LOCALE_SYSTEM_DEFAULT, NORM_IGNORECASE, @s1[1], length(s1), @s2[1], length(s2)) - 2;

end;

procedure TDXSpotsList.ResetSpotsTimes;
var
  Index                                 : integer;
begin
  if Assigned(FList) then
     begin
     for Index := 0 to FCount - 1 do
        begin
        FList^[Index].FMinutesLeft := 0;
        end;
     end;
end;

procedure TDXSpotsList.ResetSpotsDupes;
var
  Index                                 : integer;
begin
  if Assigned(FList) then
     begin
     for Index := 0 to FCount - 1 do
        begin
        FList^[Index].FDupe := False;
        end;
     end;
end;

procedure TDXSpotsList.SetCursor;
begin
  if BandMapListBox <> 0 then
  begin
    FCurrentCursorFreq := GetBMSelItemData;
    if FCurrentCursorFreq <> LB_ERR then
       begin
       if Assigned(FList) then
          begin
          FCurrentCursorFreq := FList^[FCurrentCursorFreq].FFrequency;
          end
       else
          begin
          DebugMsg('FList was nil in SetCursor');
          end;
       end;
  end;
end;

procedure TDXSpotsList.TuneDupeCheck(Freq: integer);
var
  Index                                 : integer;
  Index2                                : integer;
  d                                     : integer;
  a                                     : integer;
begin
  if not BandMapEnable then Exit;
  if not Assigned(FList) then
     begin
      exit;
     end;

  d := MAXLONG;

  for Index := 0 to FCount - 1 do
  begin
    a := Abs(FList^[Index].FFrequency - Freq);
    if (a < BandMapGuardBand) and (PInteger(@FList^[Index].FCall[1])^ <> tCQAsInteger) then
    begin
      if (a < d) then
      begin
       d := a;
       Index2 := Index; end;
     end;
  end;

  if d <= BandMapGuardBand then
  begin
     tClearDupeInfoCall; // 4.55.6
     ClearAltD;  // 4.55.6
    DupeInfoCall := FList^[Index2].FCall;
    DupeCheckOnInactiveRadio(True);
    DupeInfoCallWindowCleared := False;
  end ;
 {  else
    if d = BandMapGuardBand then exit // n4af 4.49.4 issue 171
  else
  begin
    DupeInfoCallWindowState := diNone;
    if not DupeInfoCallWindowCleared then
 //   ClearAltD; // 4.53.8
 //   DupeInfoCallWindowCleared := True;      // 4.53.8
    tClearDupeInfoCall;       // issue 172       // 4.53.5
  end;   }

end;

procedure TDXSpotsList.DisplayCallsignOnThisFreq(Freq: integer);
var
  Index                                 : integer;
  Index2                                : integer;
  d                                     : integer;
  a                                     : integer;
begin
  if not BandMapEnable then Exit;
  if not BandMapCallWindowEnable then Exit;
  if CallsignIsTypedByOperator then Exit;

  d := MAXLONG;

  for Index := 0 to FCount - 1 do
  begin
    a := Abs(FList^[Index].FFrequency - Freq);
    if (a < BandMapGuardBand) and (PInteger(@FList^[Index].FCall[1])^ <> tCQAsInteger) then
    begin
      if a < d then begin d := a; Index2 := Index; end;
    end;
  end;

  if d <= BandMapGuardBand then
  begin
    if FList^[Index2].FCall <> MyCall then
    if OpMode = SearchAndPounceOpMode then     // n4af 4.45.10
    begin
      PutCallToCallWindow(FList^[Index2].FCall);
      SendMessage(wh[mweCall], EM_SETSEL, 0, -1);
      CallsignIsPastedFromBandMap := True;
    end;
//    LOGSUBS2.DoAltZ();
    Exit;
  end;
{
  for Index := 0 to FCount - 1 do
  begin
    if (Abs(FList^[Index].FFrequency - Freq) < BandMapGuardBand) and (PInteger(@FList^[Index].FCall[1])^ <> tCQAsInteger) then
    begin
      PutCallToCallWindow(FList^[Index].FCall);
      SendMessage(CallWindowHandle, EM_SETSEL, 0, -1);
      CallsignIsPasted := True;
//      LOGSUBS2.DoAltZ();
      Exit;
    end;
  end;
}
  if not CallWindowEmpty then
    if CallsignIsPastedFromBandMap then
    begin
      tCleareCallWindow;
      tCleareExchangeWindow;
    end;
end;

begin
//  SpotsList := TDXSpotsList.Create;
  SpotsList.Init;
  SpotsList.FCurrentCursorFreq := -1;



end.

