unit utils_math;

interface

function Tan(const X: extended): extended;
function ArcCos(const X: extended): extended;
function ArcTan2(const Y, X: extended): extended;

implementation

function Tan(const X: extended): extended;
{  Tan := Sin(X) / Cos(X) }
asm
        FLD    X
        FPTAN
        FSTP   ST(0)      { FPTAN pushes 1.0 after result }
        FWAIT
end;

function ArcCos(const X: extended): extended;
begin
  Result := ArcTan2(Sqrt(1 - X * X), X);
end;

function ArcTan2(const Y, X: extended): extended;
asm
        FLD     Y
        FLD     X
        FPATAN
        FWAIT
end;

end.

