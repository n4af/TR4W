unit Trcw;

interface

uses
   Classes,
   BeepUnit,
   Windows,
   CFGCMD,
   CFGDEF,
   ColorCfg,
   COUNTRY9,
   FCONTEST,
   K1EANET,
   LogCfg,
   LogCW,
   LOGDDX,
   LOGDOM,
   LOGDUPE,
   LOGDVP,
   LOGEDIT,
   LOGGRID,
   LOGHELP,
   LOGHP,
   LOGK1EA,
   LOGMENU,
   LOGNET,
   LOGPACK,
   LOGPROM,
   LOGRADIO,
   LOGSCP,
   LOGSTUFF,
   LOGWAE,
   LOGWIND,
   Other,
   POSTCFG,
   Tree,
   ZONECONT;

type
   TCW = class(TThread)
   PRIVATE
      //  CWDURATIN:INTEGER;
      CW_TONE: integer;
      CW_SPEED: integer;
      CW_TEXT: string;

      //  ON_AIR   :TSTATICTEXT;
   PROTECTED

      procedure Execute; OVERRIDE;
      //          procedure OnTerminate;override;

   PUBLIC

      constructor Create(cw_tn, cw_sp: integer; cw_str: string);
      //            procedure OnTerminate;
   end;

   //TVeryNewCW= class (tcw);

   //const
var

   cw_marks                        : array[1..44] of string[6] = (
      {     /  }
      '-..-.',

      {     0       1       2       3       4       5       6       7       8       9}
      '-----',
      '.----',
      '..---',
      '...--',
      '....-',
      '.....',
      '-....',
      '--...',
      '---..',
      '----.',

      {     :       ;       <       =       >       ?       @}
      '', '', '', '', '', '..--..', '',

      {  A          B         C        D       E            F        G          H       I           J}
      '.-', '-...', '-.-.', '-..', '.', '..-.', '--.', '....', '..', '.---',

      {   K         L       M         N          O          P        Q         R         S       T}
      '-.-', '.-..', '--', '-.', '---', '.--.', '--.-', '.-.', '...', '-',

      {   U         V        W          X         Y         Z}
      '..-', '...-', '.--', '-..-', '-.--', '--..'

      );

implementation

uses Unit1;

constructor TCW.Create(cw_tn, cw_sp: integer; cw_str: string);

begin
   CW_TONE := CW_TN;
   CW_SPEED1 := CW_SP;

   CW_SPEED := round(1250 / CW_SPEED1);
   CW_TEXT := uppercase(cw_str);
   FreeOnTerminate := true;
   inherited Create(true);

end;

procedure TCW.Execute;
label
   1, send_again;
var
   trcw_pos, pos2                  : integer;
   str_to_send                     : string[6];
begin

   //CW_SPEED:=100;

   send_again:
   if CW_TEXT = '' then exit;

   //form1.Canvas.Lock;
   //form1.ON_AIR_ST.Enabled:=true;
   //form1.Canvas.Unlock;

  //  SetCommBreak(ComFile);
  //  EscapeCommFunction(ComFile, SETRTS);
   PTTOn;

   for trcw_pos := 1 to length(CW_TEXT) do
      begin

         str_to_send := cw_marks[ord(CW_TEXT[trcw_pos]) - 46];
         if CW_TEXT[trcw_pos] = ' ' then
            begin
               sleep(CW_SPEED * 3);
               goto 1;
            end;
         if CW_TEXT[trcw_pos] = ControlF then
            begin
               CW_SPEED := round(CW_SPEED / 1.06);
               goto 1;
            end;
         if CW_TEXT[trcw_pos] = Controls then
            begin
               CW_SPEED := round(CW_SPEED * 1.06);
               goto 1;
            end;
         if CW_TEXT[trcw_pos] = '^' then
            begin
               sleep(round(CW_SPEED / 1.5));
               goto 1;
            end;

         for pos2 := 1 to length(str_to_send) do
            begin

               if Terminated then
                  begin

                     CW_Thread_ON := False;
                     //        EscapeCommFunction(ComFile, CLRRTS);
                     pttoff;
                     exit;
                  end;

               if str_to_send[pos2] = '.' then Radio_and_SpeakerBeep(CW_TONE, CW_SPEED);
               if str_to_send[pos2] = '-' then Radio_and_SpeakerBeep(CW_TONE, CW_SPEED * 3);

               sleep(CW_SPEED); //PAUSE BENWEEN THEN DITS AND DOTS
            end;

         sleep(CW_SPEED * 2); //PAUSE BENWEEN LETTERS IN THE STRING

         CW_SPEED := round(1250 / CW_SPEED1);
         1:

      end;
   //message_to_send:='';

   if Additional_CW_Message.ADD_Message <> '' then
      begin
         CW_TEXT := Additional_CW_Message.ADD_Message;
         Additional_CW_Message.ADD_Message := '';
         goto send_again;

      end;
   CW_Thread_ON := False;
   pttoff;
end;

end.
