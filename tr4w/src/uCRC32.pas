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
unit uCRC32;

interface

function GetCRC32(const data; Count: longword): longword; register;

const
  Crc32Init                             = $FFFFFFFF;
  Crc32Polynomial                       = $EDB88320;
implementation

var
  CRC32Table                            : array[Byte] of Cardinal;

function Crc32Next(Crc32Current: longword; const data; Count: longword): longword; register;
asm
//file://EAX - CRC32Current; EDX - Data; ECX - Count
  test  ecx, ecx
  jz    @@EXIT
  PUSH  ESI
  MOV   ESI, EDX  //file://Data

@@Loop:
    MOV EDX, EAX                       // copy CRC into EDX
    LODSB                              // load next byte into AL
    XOR EDX, EAX                       // put array index into DL
    SHR EAX, 8                         // shift CRC one byte right
    SHL EDX, 2                         // correct EDX (*4 - index in array)
    XOR EAX, DWORD PTR CRC32Table[EDX] // calculate next CRC value
  dec   ECX
  JNZ   @@Loop                         // LOOP @@Loop
  POP   ESI
@@EXIT:
end; //Crc32Next

function Crc32Done(Crc32: longword): longword; register;
asm
  NOT   EAX
end; //Crc32Done

function Crc32Initialization: Pointer;
asm
  push    EDI
  STD
  mov     edi, OFFSET CRC32Table+ ($400-4)  // Last DWORD of the array
  mov     edx, $FF  // array size

@im0:
  mov     eax, edx  // array index
  mov     ecx, 8
@im1:
  shr     eax, 1
  jnc     @Bit0
  xor     eax, Crc32Polynomial  // <магическое> число - тоже что у ZIP,ARJ,RAR,:
@Bit0:
  dec     ECX
  jnz     @im1

  stosd
  dec     edx
  jns     @im0

  CLD
  pop     EDI
  mov     eax, OFFSET CRC32Table
end; //Crc32Initialization

function GetCRC32(const data; Count: longword): longword; register;
begin
  Crc32Initialization;
  RESULT := Crc32Next(Crc32Init, data, Count);
  RESULT := Crc32Done(RESULT);
end;

end.
