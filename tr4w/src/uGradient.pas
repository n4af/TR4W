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
unit uGradient;
{$IMPORTEDDATA OFF}
interface
uses
  Windows,
  VC;
type
  tcolor = -$7FFFFFFF - 1..$7FFFFFFF;
  // The definition of the TTriVertex structure in Windows.pas is
  // incorrect.
  // В Windows.pas структура TTriVertex с ошибкой.
  TTriVertex = packed record
    X: LONGINT;
    Y: LONGINT;
    Red: {Smallint} Word;
    Green: {Smallint} Word;
    Blue: {Smallint} Word;
    Alpha: Smallint;
  end;
  TGradientFill = function(DC: HDC; var P2: TTriVertex; p3: ULONG; p4: Pointer; p5, p6: ULONG): BOOL; stdcall;
  // Variables used for interfacing to the MSIMG32.DLL
//function GradientFill(DC: HDC; var P2: TTriVertex; p3: ULONG; p4: Pointer; p5, p6: ULONG): BOOL; stdcall;
var
  GradientFillFunction                  : TGradientFill;
type
  TGradientDirection = (gdHorizontal, gdVertical);
function GradientRect2(canvashandle: HWND; const ARect: TRect; Color1, Color2: tcolor; Direction: TGradientDirection): boolean;
function GradientRect(canvashandle: HWND; const ARect: TRect; Color1, Color2: tcolor; Direction: TGradientDirection): boolean;
function ColorToRGB(Color: tcolor): Cardinal {LONGINT};
function InitTriVertex(XPos, YPos: integer; Color: tcolor): TTriVertex;
implementation
//uses Unit1;
//function GradientFill; external msimg32 Name 'GradientFill';
//function GradientFill; external gdi32 Name 'GdiGradientFill';
type
  TRGB = record
    r, g, b: Byte;
  end;
function GetRGB(Color: tcolor): TRGB;
var
  iColor                                : tcolor;
begin
  iColor := ColorToRGB(Color);
  Result.r := GetRValue(iColor);
  Result.g := GetGValue(iColor);
  Result.b := GetBValue(iColor);
end;
function GradientRect2(canvashandle: HWND; const ARect: TRect; Color1, Color2: tcolor; Direction: TGradientDirection): boolean;
var
  GRect                                 : TGradientRect;
  Vertex                                : array[0..1] of TTriVertex;
  Offset                                : Cardinal;
begin
  GRect.UpperLeft := 0;
  GRect.LowerRight := 1;
  if tEightBitsPerPixel then Color2 := Color1;
  Offset := (ARect.Bottom - ARect.Top) div 2;
  Vertex[0] := InitTriVertex(ARect.Left, ARect.Bottom - Offset, Color1);
  Vertex[1] := InitTriVertex(ARect.Right, ARect.Bottom, Color2);
  Result := GradientFillFunction(canvashandle, Vertex[0], 2, @GRect, 1, 1);
  Vertex[0] := InitTriVertex(ARect.Left, ARect.Top, Color2);
  Vertex[1] := InitTriVertex(ARect.Right, ARect.Top + Offset, Color1);
  Result := GradientFillFunction(canvashandle, Vertex[0], 2, @GRect, 1, 1);
end;
function GradientRect(canvashandle: HWND; const ARect: TRect; Color1, Color2: tcolor; Direction: TGradientDirection): boolean;
// Function to initialise a TTriVertex
//const
//  Flag                             : array[TGradientDirection] of LONGINT = ($00000000 {GRADIENT_FILL_RECT_H}, $00000001 {GRADIENT_FILL_RECT_V});
var
  GRect                                 : TGradientRect;
  Vertex                                : array[0..1] of TTriVertex;
begin
  GRect.UpperLeft := 0;
  GRect.LowerRight := 1;
  if tEightBitsPerPixel then Color2 := Color1;
  Vertex[0] := InitTriVertex(ARect.Left, ARect.Top, Color1);
  Vertex[1] := InitTriVertex(ARect.Right, ARect.Bottom, Color2);
  Result := GradientFillFunction(
    canvashandle,
    Vertex[0],
    2,
    @GRect,
    1,
    Cardinal(Direction)
    );
end;
function ColorToRGB(Color: tcolor): Cardinal {LONGINT};
begin
  if Color < 0 then
    Result := GetSysColor(Color and $000000FF) else
    Result := Color;
end;
function InitTriVertex(XPos, YPos: integer; Color: tcolor): TTriVertex;
var
  TempRGB                               : TRGB;
begin
  with Result do
  begin
    X := XPos;
    Y := YPos;
    Alpha := 0 {2};
    TempRGB := GetRGB(Color);
    Red := TempRGB.r shl 8;
    Green := TempRGB.g shl 8;
    Blue := TempRGB.b shl 8;
  end
end;
begin
  @GradientFillFunction := GetProcAddress(GetModuleHandle(gdi32), 'GdiGradientFill');
  if not Assigned(GradientFillFunction) then
    @GradientFillFunction := GetProcAddress(LoadLibrary(msimg32), 'GradientFill');
end.
