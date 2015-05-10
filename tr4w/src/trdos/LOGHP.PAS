{
 Copyright Larry Tyree, N6TR, 2011,2012,2013,2014,2015.

 This file is part of TR4W    (TRDOS)

 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W.  If not, see
 <http: www.gnu.org/licenses/>.
 }
unit LOGHP;

{$O+}
{$F+}
{$IMPORTEDDATA OFF}
interface
uses VC;
procedure HP;


implementation

uses Tree {, Crt};

type
  AngularModeType = (Degrees, Radians);

var
  X, Y, Z, t, LastX           : REAL;
  Mode                        : AngularModeType;
  PushableXValue              : boolean;

procedure ShowMode;

begin
  //    GoToXY (40, 1);

  if Mode = Degrees then
    Write('Degrees mode (use M to toggle)')
  else
    Write('Radian mode (use M to toggle)');
end;

procedure ShowStack;

begin
  {    GoToXY (1, 1);
      ClrEol;
      WriteLn ('T = ', T:10:4);
      ClrEol;
      WriteLn ('Z = ', Z:10:4);
      ClrEol;
      WriteLn ('Y = ', Y:10:4, '          LastX = ', LastX:10:4);
      ClrEol;
      WriteLn ('X = ', X:10:4);
      ShowMode;
     }
end;

procedure DoCalculator;

var
  Key                         : Char;
  RESULT                      : integer;
  XString                     : Str20;
  temp                        : REAL;

begin
  {    XString := '';

      REPEAT
          ShowStack;
          Key := UpCase (ReadKey);

          CASE Key OF
              EscapeKey:
                  XString := '';

              'L': BEGIN
                   T := Z;
                   Z := Y;
                   Y := X;
                   X := LastX;
                   END;

              '+': BEGIN
                   LastX := X;
                   X := X + Y;
                   Y := Z;
                   Z := T;
                   PushableXValue := True;
                   END;

              '-': BEGIN
                   LastX := X;
                   X := Y - X;
                   Y := Z;
                   Z := T;
                   PushableXValue := True;
                   END;

              '*': BEGIN
                   LastX := X;
                   X := X * Y;
                   Y := Z;
                   Z := T;
                   PushableXValue := True;
                   END;

              '/': BEGIN
                   LastX := X;
                   X := Y / X;
                   Y := Z;
                   Z := T;
                   PushableXValue := True;
                   END;

              CarriageReturn:
                   BEGIN
                   T := Z;
                   Z := Y;
                   Y := X;
                   PushableXValue := False;
                   XString := '';
                   END;

              'Q': BEGIN
                   X := SQRT (X);
                   PushableXValue := True;
                   END;

              '': BEGIN
                   X := X * X;
                   PushableXValue := True;
                   END;

              'S': BEGIN
                   IF Mode = Degrees THEN X := (X / 90) * (Pi / 2);
                   X := Sin (X);
                   PushableXValue := True;
                   END;

              'C': BEGIN
                   IF Mode = Degrees THEN X := (X / 90) * (Pi / 2);
                   X := Cos (X);
                   PushableXValue := True;
                   END;

              'T': BEGIN
                   IF Mode = Degrees THEN X := (X / 90) * (Pi / 2);
                   X := Sin (X) / Cos (X);
                   PushableXValue := True;
                   END;

              '': BEGIN
                   IF Mode = Degrees THEN X := (X / 90) * (Pi / 2);
                   X := Sin (X);
                   PushableXValue := True;
                   END;

              '': BEGIN
                   IF Mode = Degrees THEN X := (X / 90) * (Pi / 2);
                   X := Cos (X);
                   PushableXValue := True;
                   END;

              'M': IF Mode = Radians THEN
                       Mode := Degrees
                   ELSE
                       Mode := Radians;

              'I': BEGIN
                   X := 1 / X;
                   PushableXValue := True;
                   END;

              'X': BEGIN
                   GoToXY (1, 22);
                   Halt;
                   END;

              'Y': BEGIN
                   Temp := X;
                   X := Y;
                   Y := Temp;
                   PushableXValue := True;
                   END;

              ELSE
                  IF ((Key >= '0') AND (Key <= '9')) OR (Key = '.') THEN
                      BEGIN
                      IF PushableXValue THEN
                          BEGIN
                          T := Z;
                          Z := Y;
                          Y := X;
                          ShowStack;
                          PushableXValue := False;
                          XString := '';
                          END;

                      XString := XString + Key;
                      Val (XString, X, Result);
                      END;

              END;

          GoToXY (1, 4);
          ClrEol;
          Write ('X = ', XString);
      UNTIL FALSE;
     }
end;

procedure HPHelp;

begin
  //  WriteLn('ENTER = Carriage Return    L = LastX    ESCAPE = Clear   ');
  //  WriteLn('Q = Square root   S = Sin   C = Cos   T = Tan');
  //  WriteLn('^Q = Square   ^S = ArcSin   ^C = ArcCos   ^T = ArcTan');
  //  WriteLn('G = Log   N = Ln   ^G = 10 to the X   ^N = e to the X');
  //  WriteLn('Y = Y to the X     I = 1/X    Y = X:Y');
  //  WriteLn('X = Exit                                         HP by N6TR');
end;

procedure HP;

begin
  //    ClrScr;
  Mode := Degrees;
  //    GoToXY (1, 6);
  HPHelp;

  X := 0;
  Y := 0;
  Z := 0;
  t := 0;
  LastX := 0;
  PushableXValue := False;
  DoCalculator;
end;

begin
end.

