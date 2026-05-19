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

Legend: ✅ written · 🟡 writable now (no refactor) · 🟠 partially writable
· 🔴 blocked on extraction (see *Tier 1 Extraction Pattern* below).

| Area | Status | What/Where | Notes |
|------|--------|------------|-------|
| **CI-V BCD encode/decode** | ✅ | `uTestIcomCIV.pas` — 32 tests, 0 failures | Targets `uIcomCIV` |
| **Band↔frequency mapping (modern)** | ✅ | `uTestRadioBand.pas` — centre, edges, round-trip | Targets `uRadioBand.TRadioBand` (used by `TNetRadioBase` descendants only) |
| **Band↔frequency mapping (legacy `BandType`)** | 🟡 | Legacy `BandType` is used by ~109k lines of contest code; not tested today | Small, self-contained lookup function. Must survive 64-bit `LongInt → Int64` change |
| **Dupe checking** | 🟠 | `DupeAndMultSheet` in `LogDupe.pas` | Methods like `AddCompressedCallToDupeSheet` and the partial-call lookup are testable with synthetic data **if** the object can be instantiated without its file backing — verify before scheduling |
| **Exchange parsing** | 🔴 | `ProcessExchange()` and per-exchange handlers in `LOGSTUFF.PAS` | Logic is pure-ish but the monolith drags in globals + Win32. Highest ROI once unblocked — one bad parse = silent wrong score |
| **Score calculation** | 🔴 | `QSOPoints` and related in `LOGSTUFF.PAS` | Verify against published claimed scores once extracted |
| **Cabrillo export** | 🔴 | Per-QSO line writer in `PostUnit.PAS` (144k lines) | Lift the line formatter into `uCabrilloFormat.pas`; parse the output string, don't rely on file writing |

### Tier 1 Extraction Pattern (monolith-bound logic)

Four Tier 1 areas — exchange parsing, score calculation, dupe checking,
Cabrillo export — live inside two enormous TRDOS units:

- `LOGSTUFF.PAS` (262k lines)
- `PostUnit.PAS` (144k lines)

Pulling either of those into the test EXE drags in every global, every Win32
window, MainUnit, the lot. The existing tests stay clean because they target
self-contained modern units. To write Tier 1 tests for the monolith-bound
areas, we first lift the *pure* logic out into its own unit. Function bodies
do not change; the monolith uses the new unit (or `{$INCLUDE}`s its
implementation) to keep original call sites working.

**Pattern, one PR per area:**

1. Pick one area (e.g., exchange parsing for NA Sprint).
2. Create the new unit (e.g., `src/trdos/uExchangeParsing.pas`).
3. Move the target function and its private helpers verbatim. **Do not refactor**;
   preserving the exact body keeps behavior identical and `git blame` useful.
4. Add the new unit to `tr4w.dpr`'s uses clause.
5. From the monolith, either `uses` the new unit or `{$INCLUDE}` its
   implementation — whichever produces zero call-site changes.
6. Build TR4W; confirm zero behavior change (regression test against a known log).
7. Write the test suite against the now-isolated unit and register it in
   `tr4w_unit_tests.dpr`.

If a moved function references a global that lives in the monolith, either
(a) move the global with it, (b) the new unit `uses` the monolith for read-only
access, or (c) parameterize the dependency into a function argument. Prefer (c)
where cheap.

Do not bundle extractions across areas — keeps blame readable and any
regression bisectable.

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

## Pre-Migration Interim Roadmap

Test-coverage work between today and Phase 1, in priority order. Each row is one
PR. Done one at a time as time allows; **no two extractions in the same PR.**

| # | Item | Effort | Type | Tier 1? |
|---|------|--------|------|---------|
| 1 | Legacy `BandType` lookup tests (TR4W contest-code band mapping) | S | Test only | Yes |
| 2 | `uCTYDAT` callsign → DXCC entity lookup tests | S | Test only | Tier 2 |
| 3 | `uMults` multiplier count/add/check tests with synthetic data | S | Test only | Tier 2 |
| 4 | Expand `uTestUtilsText` for predicates used by exchange parsing | S | Test only | Foundation |
| 5 | ~~Verify `DupeAndMultSheet` can instantiate without file backing~~ — **spike done**: not instantiable without major extraction. See *Dupe Testing Spike Findings* below | M–L | Refactor + test | Yes |
| 6 | Extract Cabrillo per-QSO line formatter → `uCabrilloFormat.pas` + tests | M | Refactor + test | Yes |
| 7 | Extract scoring → `uScoring.pas` for one major contest (CQ WW) + tests | M | Refactor + test | Yes |
| 8 | Extract exchange parser for NA Sprint → `uExchangeParsing.pas` + tests | M | Refactor + test | Yes |
| 9 | Add CQ WPX, NAQP, ARRL DX, SS to extracted exchange parser | L | Test only | Yes |
| 10 | ~~Catalog all `asm` blocks — produce Phase 3 worklist~~ — **done** 2026-05-19, see [docs/PHASE_INVENTORIES.md](PHASE_INVENTORIES.md) (600 blocks across 74 files; PostUnit alone has 170) | S | Inventory | — |
| 11 | ~~Audit `wsprintf` call sites — produce Phase 2 worklist~~ — **done** 2026-05-19, see [docs/PHASE_INVENTORIES.md](PHASE_INVENTORIES.md) (**172 calls** across 37 files — original estimate of 73 was substantially low; PostUnit alone has 92) | M | Inventory | — |

**Effort scale:** S = couple of hours · M = half a day to a day · L = a day or two.

### Guidance for picking the next item

- **Items 1–4** require zero production-code changes. They're the safest to schedule
  between feature work because a failing test means a test bug, not a regression.
- **Item 5** is a quick spike: instantiate `DupeAndMultSheet` in a test, see what
  globals or files it demands, decide whether to test in place or extract. The
  spike itself is the deliverable; if extraction is required, that becomes a
  follow-up PR.
- **Items 6–9** follow the *Tier 1 Extraction Pattern* above. Pick the simplest
  contest for #7 and #8 to validate the pattern; complexity scales up after.
- **Items 10–11** can run in parallel with anything else — pure inventory work
  that produces checklists, not code changes.

When in doubt, do item 1 next. It's small, isolated, and protects a function
that's invoked thousands of times per contest.

### Dupe Testing Spike Findings

Spike for roadmap item 5 (verify `DupeAndMultSheet` can be instantiated in
a test EXE without its file backing). Performed 2026-05-19.

**Conclusion:** Not feasible without first doing a larger extraction (M–L
effort, not the S–M originally estimated).

**Why:**

1. `LogDupe.pas` (2,570 lines) has a wide `uses` cone: `LogWind` (172k lines),
   `LogRadio` (152k lines), `LogSCP`, `Tree`, `uMults`, `uCallsigns`, plus
   `VC`, `TF`, `Windows`. Linking `LogDupe` into the test EXE pulls the
   entire TRDOS layer in — the test runner would effectively *be* tr4w.exe.

2. `DupeAndMultSheet` is a Turbo-Pascal-style `object` (not a class), and
   has only two boolean fields (`DupeSheetEnable`, `tAutoReset`). The
   actual dupe and multiplier data lives in module-level globals declared
   immediately below the object definition (`InitialExCallsigns`,
   `InitialExDupes`, partial-call arrays, dupe-list pointers). The object's
   methods mutate those globals directly. There is no constructor and no
   private state to inject.

3. Methods that *look* in-memory-pure on their signatures
   (`AddCompressedCallToDupeSheet`, `TwoLetterCrunchProcess`,
   `MakePossibleCallList`, `IsADomesticMult`, `DupeSheetTotals`) all
   reach into the global state.  Calling any of them in a test requires
   priming that global state, which requires either `SheetInitAndLoad`
   (which does file I/O) or hand-initializing every global by hand.

**Recommended next step (deferred — not in current PR scope):**

Extract pure dupe-check and partial-call-match logic plus its underlying
data structures (DupeList, MultList, partial-call arrays) into a new
`uDupeCheck.pas` following the Tier 1 Extraction Pattern. `LogDupe.pas`
keeps the file I/O, UI, and TRDOS-wired glue and forwards in-memory
operations to the new unit. Expected effort: M–L. Adds another row to
the roadmap; do not bundle with other items.

Test scope after extraction:
- Add call X to dupe sheet on band B / mode M; check `IsDupe(X, B, M)` returns True
- Same call on different band returns False (per-band dupe semantics)
- Empty sheet returns False for any call
- Partial-call match: input "K1A", confirm K1ABC appears in the candidate list
- Mult tracking: per-band, per-mode multiplier flags

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

## Binary Log Format History

The TR4W binary log (`ContestExchange` record) has the following version history.
All versions use fixed-size records; the version is stored in `TLogHeader` (first record).

| Version | Key changes | Frozen type in VC.pas |
|---------|-------------|----------------------|
| v1.5 | No `ExtMode`, no `ExchString`, no `id` | `ContestExchangev1_5` |
| v1.6 | Added `ExtMode`, `ExchString`; ZERO pad fields active; no `id` | `ContestExchangev1_6` |
| v1.7 | Added `id: string[32]`, `sReserved: string[50]`; res3/res15-23 removed | `ContestExchange` (current) |

**Log conversion** (`AskConvertLog` in `MainUnit.pas`) handles v1.5→v1.7 and v1.6→v1.7.
Files already at v1.7 open directly without conversion. The `id` field (a GUID) is
populated on new QSOs via `TF.GetGUID` and left blank when upgrading from v1.6 (no
source data available).

**v1.7 is the frozen binary format.** Do not add fields to `ContestExchange`. All new
per-QSO fields belong in the SQLite schema described below.

---

## Deferred Log Format Fields (SQLite Phase)

These fields are **not** in the v1.7 binary `ContestExchange` record and should be
added as columns when the log is migrated to SQLite. They were consciously deferred
because the binary format is frozen at v1.7 (last format before D12/SQLite).

### Why each field was deferred

| Column | Type | Reason deferred | Notes |
|--------|------|-----------------|-------|
| `tx_frequency` | INTEGER | Split-op TX freq differs from RX | Binary record has one `Frequency` field only |
| `my_grid` | TEXT | Changes mid-contest (Rover operations) | Currently global setting, not per-QSO |
| `my_park_ref` | TEXT | Changes mid-contest (POTA activators visiting multiple parks) | POTA/SOTA/WWFF — no per-QSO field exists today |
| `contacted_grid` | TEXT | Shoehorned into `QTHString` (context-dependent) | QTHString is reused for grid, QTH, section depending on contest |
| `dxcc_entity` | INTEGER | Useful for DXCC tracking without re-parsing CTY.DAT | Partially covered by `QTH.CountryID` string |

### Migration note

During the binary→SQLite import, `QTHString` must be interpreted contextually per
contest type — the same field holds gridsquare, section, or QTH depending on which
contest was active. Preserve the raw `QTHString` value in a `qth_string_raw` column
alongside the structured fields so nothing is lost.

The TR4QT SQLite implementation at `C:\projects\TR4QT` is the reference schema.

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
