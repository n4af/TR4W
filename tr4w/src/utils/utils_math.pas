unit utils_math;

interface

function Tan(const X: extended): extended;
function ArcCos(const X: extended): extended;
function ArcTan2(const Y, X: extended): extended;

implementation

uses
  Math;

// Issue #997: the FPTAN/FPATAN inline-asm bodies are replaced by the Delphi
// RTL Math unit (which implements the identical x87 ops). The RTL calls MUST
// be Math.-qualified: an unqualified Tan/ArcTan2 here would bind to the local
// function of the same name and recurse infinitely. Equivalence to the asm
// baseline is frozen by uTestUtilsMath (15 golden cases, 1e-12 tolerance).
function Tan(const X: extended): extended;
begin
  Result := Math.Tan(X);
end;

function ArcCos(const X: extended): extended;
begin
  Result := ArcTan2(Sqrt(1 - X * X), X);
end;

function ArcTan2(const Y, X: extended): extended;
begin
  Result := Math.ArcTan2(Y, X);
end;

end.

