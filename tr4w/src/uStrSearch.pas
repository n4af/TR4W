unit uStrSearch;

{
  PChar substring-search helpers extracted from TF.pas for the Issue #997
  inline-asm removal effort.

  These three routines were originally hand-written x86 inline assembler
  (JOH-style IA32). They are extracted here into a dependency-light unit so
  that:

    1. Their exact behavior can be frozen by golden-master unit tests
       (uTestStrSearch) -- TF.pas itself cannot be linked into the test
       harness because it pulls in MainUnit and the whole UI graph.
    2. The asm bodies can then be replaced with the Delphi RTL / pure Pascal
       and proven bit-identical against the frozen baseline.

  TF.pas keeps the public names (StrPos, StrPosPartial, StrComp_JOH_IA32_6)
  and forwards here, so existing callers are unaffected.

  SEMANTICS (must be preserved exactly):

    StrPos(Str1, Str2)
      Returns a pointer to the first occurrence of Str2 within Str1, or nil
      if not found / either argument nil / Str2 longer than Str1. Identical
      contract to SysUtils.StrPos.

    StrComp_JOH_IA32_6(Str1, Str2)
      Standard C strcmp: <0, 0, >0. Identical contract to SysUtils.StrComp.
      (Currently uncalled in the codebase, retained for API stability.)

    StrPosPartial(Str1, Str2)
      Like StrPos, but a '?' in Str2 matches any single character -- EXCEPT
      for the FIRST character of Str2, which is always matched literally
      (the original asm seeds the scan with an exact match on Str2[0], so a
      leading '?' looks for a literal '?'). Returns a pointer into Str1 to
      the start of the match, or nil.
}

interface

function StrPos(const Str1, Str2: PChar): PChar;
function StrPosPartial(const Str1, Str2: PChar): PChar;
function StrComp_JOH_IA32_6(const Str1, Str2: PChar): integer;

implementation

function StrComp_JOH_IA32_6(const Str1, Str2: PChar): integer; assembler;
asm
  sub   eax, edx
  jz    @@Exit
@@Loop:
  movzx ecx, [eax+edx]
  cmp   cl, [edx]
  jne   @@SetResult
  inc   edx
  test  cl, cl
  jnz   @@Loop
  xor   eax, eax
  ret
@@SetResult:
  sbb   eax, eax
  or    al, 1
@@Exit:
end;

function StrPosPartial(const Str1, Str2: PChar): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX

        OR      EAX,EAX//str1
        JE      @@2
        OR      EDX,EDX//str2
        JE      @@2

        MOV     EBX,EAX
        MOV     EDI,EDX
        XOR     AL,AL
        MOV     ECX,0FFFFFFFFH
        REPNE   SCASB
        NOT     ECX
        DEC     ECX
        JE      @@2

        MOV     ESI,ECX     //length of str2
        MOV     EDI,EBX
        MOV     ECX,0FFFFFFFFH
        REPNE   SCASB
        NOT     ECX
        SUB     ECX,ESI     //if str2 > str1
        JBE     @@2
        MOV     EDI,EBX     //str1 to edi
        LEA     EBX,[ESI-1] //length str1
@@1:    MOV     ESI,EDX     //str2 to esi
        LODSB               //mov esi to eax, inc esi
        REPNE   SCASB       //find [eax] in [edi] ,inc edi, dec ecx
        JNE     @@2
        MOV     EAX,ECX
        PUSH    EDI
        MOV     ECX,EBX

@@4:    CMPSB               //compare edi with esi
        JE      @@SAME
        CMP     BYTE PTR [ESI-1],'?'
        JNZ     @@5
@@SAME:
        DEC     ECX
        JNE     @@4
@@5:
        POP     EDI
        MOV     ECX,EAX
        JNE     @@1
        LEA     EAX,[EDI-1]
        JMP     @@3
@@2:    XOR     EAX,EAX
@@3:    POP     EBX
        POP     ESI
        POP     EDI
end;

function StrPos(const Str1, Str2: PChar): PChar; assembler;
asm
        PUSH    EDI
        PUSH    ESI
        PUSH    EBX

        OR      EAX,EAX//str1
        JE      @@2
        OR      EDX,EDX//str2
        JE      @@2

        MOV     EBX,EAX
        MOV     EDI,EDX
        XOR     AL,AL
        MOV     ECX,0FFFFFFFFH
        REPNE   SCASB
        NOT     ECX
        DEC     ECX
        JE      @@2

        MOV     ESI,ECX     //length of str2
        MOV     EDI,EBX
        MOV     ECX,0FFFFFFFFH
        REPNE   SCASB
        NOT     ECX
        SUB     ECX,ESI     //if str2 > str1
        JBE     @@2
        MOV     EDI,EBX     //str1 to edi
        LEA     EBX,[ESI-1] //length str1
@@1:    MOV     ESI,EDX     //str2 to esi
        LODSB               //mov esi to eax, inc esi
        REPNE   SCASB       //find [eax] in [edi] ,inc edi, dec ecx
        JNE     @@2
        MOV     EAX,ECX
        PUSH    EDI
        MOV     ECX,EBX
        REPE    CMPSB       //compare edi with esi
        POP     EDI
        MOV     ECX,EAX
        JNE     @@1
        LEA     EAX,[EDI-1]
        JMP     @@3
@@2:    XOR     EAX,EAX
@@3:    POP     EBX
        POP     ESI
        POP     EDI
end;

end.
