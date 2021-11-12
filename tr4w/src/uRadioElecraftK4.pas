unit uRadioElecraftK4;

interface
uses uNetRadioBase, StrUtils, SysUtils;
Type TK4Radio = class(TNetRadioBase)
   private
   public
      Constructor Create;
      procedure Transmit;
      procedure Receive;
      procedure SendCW(cwChars: string);
      procedure SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
      procedure SetMode(mode:TRadioMode);
      function  ToggleMode: TRadioMode;
      procedure SetCWSpeed(speed: integer);
      procedure RITClear;
      procedure XITClear;
      procedure RITOn;
      procedure RITOff;
      procedure XITOn;
      procedure XITOff;
      procedure SetRITFreq(hz: integer);
      procedure SetXITFreq(hz: integer);
      procedure SetBand(band: TRadioBand);
      function  ToggleBand: TRadioBand;
      procedure SetFilter(filter:TRadioFilter);
      function  SetFilterHz(hz: integer): integer;
      procedure MemoryKeyer(mem: integer);
end;

implementation

uses MainUnit;

Constructor TK4Radio.Create;
begin
   inherited Create;
end;

procedure TK4Radio.Transmit;
begin
   Self.SendToRadio('TX;');
end;

procedure TK4Radio.Receive;
begin
   Self.SendToRadio('RX;');
end;

procedure TK4Radio.SendCW(cwChars: string);
var s: string;
begin
   if length(cwChars) > 60 then
      begin
      s := AnsiLeftStr(cwChars,60);
      logger.Info('Cannot send more than 60 characters to a K4 - Truncating to %s',[s]);
      end
   else
      begin
      s := cwChars;
      end;
   Self.SendToRadio('KY ' + s + ';');
end;

procedure TK4Radio.SetFrequency(freq: longint; vfo: TVFO; mode: TRadioMode);
begin
end;

procedure TK4Radio.SetMode(mode:TRadioMode);
begin
   case mode of
      rmNone: Self.SendToRadio('MD');
      rmCW:  Self.SendToRadio('MD');
      rmCWRev: Self.SendToRadio('MD');
      rmLSB:  Self.SendToRadio('MD');
      rmUSB: Self.SendToRadio('MD');
      rmFM:   Self.SendToRadio('MD');
      rmAM:  Self.SendToRadio('MD');
      rmData: Self.SendToRadio('MD');
      rmDataRev: Self.SendToRadio('MD');
      rmFSK:    Self.SendToRadio('MD');
      rmFSKRev:  Self.SendToRadio('MD');
      rmPSK:  Self.SendToRadio('MD');
      rmPSKRev:Self.SendToRadio('MD');
      rmAFSK:  Self.SendToRadio('MD');
      rmAFSKRev: Self.SendToRadio('MD');
    else
       begin
       end;
    end;
end;

function  TK4Radio.ToggleMode: TRadioMode;
begin
end;

procedure TK4Radio.SetCWSpeed(speed: integer);
begin
   if (speed >= 8) or (speed <= 101) then
      begin
      Self.SendToRadio('KS' + Format('%3d',[speed]));
      end
   else
      begin
      logger.Error ('K4 supports a CW speed of 8 wpm to 100 wpm');
      end;
end;

procedure TK4Radio.RITClear;
begin
end;

procedure TK4Radio.XITClear;
begin
end;

procedure TK4Radio.RITOn;
begin
end;

procedure TK4Radio.RITOff;
begin
end;

procedure TK4Radio.XITOn;
begin
end;


procedure TK4Radio.XITOff;
begin
end;

procedure TK4Radio.SetRITFreq(hz: integer);
begin
end;

procedure TK4Radio.SetXITFreq(hz: integer);
begin
end;

procedure TK4Radio.SetBand(band: TRadioBand);
begin
end;


function  TK4Radio.ToggleBand: TRadioBand;
begin
end;

procedure TK4Radio.SetFilter(filter:TRadioFilter);
begin
end;

function  TK4Radio.SetFilterHz(hz: integer): integer;
begin
end;

procedure TK4Radio.MemoryKeyer(mem: integer);
begin
end;

end.
