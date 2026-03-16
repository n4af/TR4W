# TR4W Migration Strategy

This document captures recommendations for the phased migration of TR4W from Delphi 7
to a modern Delphi version, and the testing strategy that supports it.
Read alongside `tr4w-analysis.md` (upstream architectural analysis).

---

## Overview

The migration has four phases (defined in `tr4w-analysis.md`). This document focuses
on two things that analysis does not cover in depth:

1. **What to test, and when** — building a regression net before the freeze
2. **Pragmatic guidance** for each phase based on the actual codebase

---

## Testing Strategy

### Guiding Principle

Build tests *before* the freeze, not during it. Tests written now verify behavior
under Delphi 7 and serve as the regression net for every phase that follows.
The test framework (`uTR4WTestFramework.pas`) is intentionally DUnit-compatible so
migration to DUnitX in Phase 4 requires only adding attributes and swapping the runner.

### Test Framework

| Item | Now (D7) | Phase 4 (D12) |
|------|----------|---------------|
| Base class | `TTestCase` in `uTR4WTestFramework.pas` | `TTestCase` in `TestFramework` (DUnit) or `DUnitX.TestFramework` |
| Test discovery | Explicit `RunAllTests` override | `[Test]` attribute on each method |
| Runner | `RegisterSuite` / `RunAllSuites` | `TDUnitX.CreateRunner.Run` |
| Assertions | `Check`, `CheckEquals`, `CheckTrue` | Identical API — no changes needed |

Test classes themselves need **no changes** when moving to D12 — only the
infrastructure wiring changes.

### Tier 1 — Write Before the Freeze (Highest ROI)

These cover the pure logic that is hardest to manually regression-test and most
likely to break during the Unicode / 64-bit phases.

| Area | What to test | Notes |
|------|-------------|-------|
| **CI-V BCD encode/decode** | `uIcomCIV` — `IcomByteToBCD`, `IcomBCDToFreq`, etc. | Already done — 32 tests, 0 failures |
| **Exchange parsing** | 5 most popular contests (CQ WW, ARRL DX, NA Sprint, NAQP, SS) | Highest ROI. One bad parse = silent wrong score. Target `ProcessExchange()` in LOGSTUFF.PAS |
| **Score calculation** | QSO points × multiplier for key contest types | Verify against published claimed scores |
| **Band↔frequency mapping** | `FreqToBand`, band edge checks | Must survive 64-bit `LongInt→Int64` change |
| **Dupe checking** | Duplicate detection logic in `LogDupe.pas` | Use synthetic log data, not file I/O |
| **Cabrillo export** | Key fields: freq, mode, time, call, exchange | Parse the output string — don't rely on file writing |

Exchange parsing for the top 5 contests alone provides the most protection per
hour of test-writing time.

### Tier 2 — Write During Phase 1 (Before Unicode Work)

These are lower risk but important to have before `string`→`UnicodeString` changes.

| Area | Notes |
|------|-------|
| `TF.pas` utility functions | Format/conversion helpers used everywhere |
| Config parser (`uCFG.pas`) | Key command parsing, boolean/integer/string types |
| Country/prefix lookup | `uCTYDAT.pas` — callsign → DXCC entity |
| Multiplier tracking | `uMults.pas` — add/check/count multipliers |

### Coding Conventions for Tests

- Use `AnsiString` **explicitly** for any byte-oriented or wire-format data in tests
  (not bare `string`). In D7 these are the same, but the explicit annotation makes
  Phase 2 Unicode work obvious rather than hidden.
- Cast to `Integer` before `CheckEquals` when comparing `Byte`/`LongInt`/`Word`
  values (D7 overload resolution limitation — see `uTestIcomCIV.pas` for examples).
- Keep each test method focused on one invariant. Prefer many small tests over
  one large test with multiple assertions.

---

## Phase-by-Phase Guidance

### Phase 1 — Compile D12 32-bit (Remove Blockers)

**Goal:** `tr4w.dpr` compiles under Delphi 12 in 32-bit ANSI-compatible mode
with zero behavior change.

**Critical blockers** (from `tr4w-analysis.md`):

1. **Custom RTL shadow units** — `src/` contains a copy of `SysUtils.pas` (16K lines).
   D12 will reject it. Action: rename or remove; verify no custom extensions were added.

2. **Bundled Indy** — `include/Indy/` must be removed and replaced with the D12
   Indy package. API is largely compatible but import paths differ.

3. **`TF.pas` `wsprintf` wrappers** — 73 `wsprintf` calls wrap Win32 formatting.
   These are safe in 32-bit but must be audited before Phase 2 (Unicode strings
   passed to `wsprintf` will silently produce garbage).

4. **477 inline assembly blocks** — Inaccessible in 64-bit (Phase 3). In Phase 1
   they compile fine; catalog them now using `grep -r 'asm' src/` so Phase 3 has
   a clear list.

5. **`IsMultiThread := True`** — Already fixed. Must stay as first statement in
   `tr4w.dpr` (added March 2026 to fix random startup AVs).

**Win32 API calls:** Leave as-is. Win32 API works identically in D12 32-bit.
There is no benefit to wrapping it in Phase 1; defer to Phase 4 (VCL forms).

### Phase 2 — Unicode Correctness

**Goal:** Replace implicit `string = AnsiString` assumptions with explicit types.

**Key rules:**
- CI-V / serial / network byte buffers: `AnsiString` or `TBytes` — never `string`
- UI strings (labels, callsigns, exchange fields): `string` (= UnicodeString in D12)
- File I/O: explicit `TEncoding.Default` or `TEncoding.ANSI` for legacy `.dat`/`.cfg` files
- `PChar` → `PAnsiChar` for Win32 API calls that take byte strings (most radio protocol code)

The `uIcomCIV.pas` BCD functions return `string` (= `AnsiString` in D7). These
**must** be changed to `AnsiString` in Phase 2. The D12 migration note is already
in the unit header.

### Phase 3 — 64-bit

**Goal:** Compile and run as 64-bit Windows application.

**Key concerns:**
- `LongInt` is 32-bit in both D7 and D12/64. Frequency values up to 10 GHz fit in
  32-bit (max ~4.3 GHz). Safe for now; flag for review if microwave bands are added.
- All 477 inline `asm` blocks must be replaced or wrapped with `{$IFDEF CPUX64}`.
  Most are in TRDOS layer and likely perform bit manipulation or port I/O that can
  be rewritten in Pascal.
- `Pointer` / `NativeInt` size changes from 4 to 8 bytes. Audit any code that casts
  between pointers and integers.

### Phase 4 — Modernization

**Goal:** VCL forms, TThread, contest factory, DUnitX test runner.

**Recommended order within Phase 4:**

1. Migrate test runner to DUnitX (trivial — add attributes, swap runner call)
2. Replace Win32 `CreateThread` with `TThread` subclasses (safer lifetime management)
3. Introduce contest factory pattern (modeled on TR4QT in `C:\projects\TR4QT`)
   — defer until after D12 runs cleanly, as analysis noted
4. Move TRDOS windows to VCL forms incrementally (one window at a time) — see **Dialog Migration** below
5. Replace `PChar` / `wsprintf` with Delphi string formatting throughout

**Contest factory:** The TR4QT C++ pattern (`C:\projects\TR4QT`) is the reference.
Do not attempt to add this before Phase 4 — it requires stable class hierarchies
that don't exist yet in the TRDOS layer.

#### Dialog Migration (Phase 4 sub-task)

See `docs/dialog_analysis.md` for the complete inventory.
TR4W has three categories of windows, each with a different migration path:

**Track 1 — Resource dialogs already in English `.RES` (3 dialogs)**

| ID | Dialog | DlgProc | Source |
|----|--------|---------|--------|
| 46 | Edit QSO | `EditQSODlgProc` | `uEditQSO.pas` |
| 66 | Radio/CAT setup | `CATDlgProc` | `uCAT.pas` |
| 73 | Synchronize log | `GetServerLogDlgProc` | `uLogCompare.pas` |

These can be decompiled to `.dfm` now. The `DlgProc` logic maps directly to
`TForm` event handlers. Start here — lowest risk, immediate payoff.

**Track 2 — Resource dialogs in non-English `.RES` only (~38 dialogs)**

The Russian and Spanish `.RES` files have templates for most modal dialogs
(IDs 40–77) and the 22 modeless `tw_` tool windows (IDs 1–19) that are
missing from the English `.RES`. Approach:

1. Decompile from `tr4w_rus.RES` or `tr4w_esp.RES` → `.dfm` skeleton
2. Wire the existing `DlgProc` procedure body into `TForm` event handlers
3. Add the English `.RES` entry (or eliminate the `.RES` dependency entirely)

Migrate one window at a time, in order of complexity: simple modal dialogs
first, modeless tool windows (bandmap, telnet, radio status) last.

**Track 3 — Main window (`MAINTR4WDLGTEMPLATE`) — hardest piece**

The TR4W main window has **no `.RES` entry in any language**. It is built
entirely from `MAINTR4WDLGTEMPLATE` — a raw `DLGTEMPLATE` binary struct
hardcoded in `VC.pas` (line 133) and instantiated via
`CreateDialogIndirectParam()`.

This is the final and most complex piece. Do not attempt until all other
windows are on VCL forms. Migration approach:

1. Instrument the existing template to log every control's ID, class, size,
   and position at startup (one-time diagnostic run)
2. Use that output to generate a `TForm` with manually placed controls
3. Replace `CreateDialogIndirectParam` call with `TMainForm.Create`
4. Port the `WindowProc` message dispatcher in `tr4w.dpr` into `TMainForm`
   overrides and event handlers — this is the bulk of the work

---

## What NOT to Do

- **Do not refactor and migrate simultaneously.** Pick one. Phase 1 is compile-only;
  no refactoring. Phase 4 is refactoring; migration is complete.
- **Do not "fix" the TRDOS layer** during the freeze. It is stable, proven contest
  logic. The only changes during Phases 1-3 are mechanical (type annotations, asm
  replacement). Behavior must be identical.
- **Do not skip the test freeze.** Writing tests after Phase 1 means writing tests
  against code that may already have subtle D12 regressions. The tests must describe
  D7 behavior so they can detect regressions.

---

## Quick Reference — Files to Act on First

| File | Issue | Phase |
|------|-------|-------|
| `src/SysUtils.pas` (shadow) | Conflicts with RTL | Phase 1 |
| `include/Indy/` | Replace with D12 Indy package | Phase 1 |
| `src/TF.pas` | 73 `wsprintf` calls | Phase 1 audit, Phase 2 fix |
| `src/uIcomCIV.pas` | `string` → `AnsiString` for BCD | Phase 2 |
| `src/uRadioIcomBase.pas` | Same — delegates to uIcomCIV | Phase 2 |
| All `asm` blocks | Catalog Phase 1, replace Phase 3 | Phase 1/3 |
| `tr4w.dpr` `IsMultiThread` | Already fixed | Done |
| `test/unit/tr4w_unit_tests.dpr` | Add DUnitX runner | Phase 4 |
