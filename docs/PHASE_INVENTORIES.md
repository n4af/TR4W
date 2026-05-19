# Phase 2 & 3 Migration Inventories

Pre-migration inventory artifacts that feed the Phase 2 (Unicode) and
Phase 3 (64-bit) checklists. See `docs/tr4w-migration-strategy.md`
items 10 and 11 in the Pre-Migration Interim Roadmap.

Generated 2026-05-19. Counts come from a static `grep` over `tr4w/src/`,
excluding `~`, `.bakup`, and `.bad` working files.

---

## Phase 3 — Inline `asm` Block Inventory

**Total: 600 `asm` blocks across 74 files.**

Inline x86 assembly is inaccessible in 64-bit Delphi compilation. Every
block must be either:

- Replaced with equivalent Pascal code, or
- Gated with `{$IFDEF CPUX86}…{$ENDIF}` plus a 64-bit Pascal alternative.

The top of the list is where to start — `PostUnit.PAS` alone is 28% of
all blocks in the project.

### Files sorted by count (descending)

| File | `asm` blocks |
|------|--------------|
| tr4w/src/trdos/PostUnit.PAS | 170 |
| tr4w/src/utils/SysUtils.pas | 58 |
| tr4w/src/MainUnit.pas | 56 |
| tr4w/src/MySU.pas | 39 |
| tr4w/src/uVariants.pas | 24 |
| tr4w/src/TF.pas | 20 |
| tr4w/src/uLogCompare.pas | 17 |
| tr4w/src/uQTCS.pas | 14 |
| tr4w/src/trdos/LOGDVP.PAS | 10 |
| tr4w/src/uWinKey.pas | 8 |
| tr4w/src/trdos/LOGSTUFF.PAS | 8 |
| tr4w/src/uQTCR.pas | 7 |
| tr4w/src/uGetScores.pas | 6 |
| tr4w/src/uComObj.pas | 6 |
| tr4w/src/trdos/tree.pas | 6 |
| tr4w/src/trdos/_JCtrl1.pas | 6 |
| tr4w/src/trdos/LOGWAE.PAS | 6 |
| tr4w/src/trdos/JCtrl1.pas | 6 |
| tr4w/src/uTelnet.pas | 5 |
| tr4w/src/uAltP.pas | 5 |
| tr4w/src/trdos/LogCfg.pas | 5 |
| tr4w/src/tr4wserverUnit.pas | 5 |
| tr4w/src/uRemMults.pas | 4 |
| tr4w/src/uRadioPolling.pas | 4 |
| tr4w/src/uProcessCommand.pas | 4 |
| tr4w/src/uNewContest.pas | 4 |
| tr4w/src/uIntercom.pas | 4 |
| tr4w/src/uEditMessage.pas | 4 |
| tr4w/src/uCFG.pas | 4 |
| tr4w/src/trdos/LOGWIND.PAS | 4 |
| tr4w/src/trdos/LOGSUBS2.PAS | 4 |
| tr4w/src/jwamswsock.pas | 4 |
| tr4w/src/exportto_trlog.pas | 4 |
| tr4w/src/uRemMults_Zone.pas | 3 |
| tr4w/src/uCallsigns.pas | 3 |
| tr4w/src/uCRC32.pas | 3 |
| tr4w/src/trdos/LOGK1EA.PAS | 3 |
| tr4w/src/MemProg.pas | 3 |
| tr4w/src/utils/utils_text.pas | 2 |
| tr4w/src/utils/utils_math.pas | 2 |
| tr4w/src/utils/networkmessageutils.pas | 2 |
| tr4w/src/uSpots.pas | 2 |
| tr4w/src/uOption.pas | 2 |
| tr4w/src/uNet.pas | 2 |
| tr4w/src/uMaster.pas | 2 |
| tr4w/src/uMP3Recorder.pas | 2 |
| tr4w/src/uMMTTY.pas | 2 |
| tr4w/src/uLogSearch.pas | 2 |
| tr4w/src/uFunctionKeys.pas | 2 |
| tr4w/src/uEditQSO.pas | 2 |
| tr4w/src/uDistance.pas | 2 |
| tr4w/src/trdos/JCTRL2.PAS | 2 |
| tr4w/src/trdos/BeepUnit.pas | 2 |
| tr4w/src/t_.pas | 2 |
| tr4w/src/LPTIO.pas | 2 |
| tr4w/src/DLPortIO.pas | 2 |
| tr4w/src/uRemMults_DX.pas | 1 |
| tr4w/src/uRemMults_DOM.pas | 1 |
| tr4w/src/uMultsFrequencies.pas | 1 |
| tr4w/src/uMessagesList.pas | 1 |
| tr4w/src/uErmak.pas | 1 |
| tr4w/src/uDupesheet.pas | 1 |
| tr4w/src/uCbrSum.pas | 1 |
| tr4w/src/uCTYDAT.PAS | 1 |
| tr4w/src/uCT1BOH.pas | 1 |
| tr4w/src/uBeacons.pas | 1 |
| tr4w/src/uBandmap.pas | 1 |
| tr4w/src/uAltD.pas | 1 |
| tr4w/src/uAbout.pas | 1 |
| tr4w/src/trdos/ZONECONT.PAS | 1 |
| tr4w/src/trdos/LogCW.pas | 1 |
| tr4w/src/trdos/LOGRADIO.PAS | 1 |
| tr4w/src/trdos/LOGGRID.PAS | 1 |
| tr4w/src/trdos/LOGEDIT.PAS | 1 |

### Observations

- **`PostUnit.PAS` is the elephant**: 170 blocks, ~28% of the entire codebase's
  inline assembly. Almost certainly all are `wsprintf`-related (see Phase 2
  inventory below — same file, 92 wsprintf calls). The two phases will
  almost certainly clean up together for this file.
- **`utils/SysUtils.pas` (58) is a shadow RTL unit** that Phase 1 already
  flags for removal/replacement. The `asm` blocks here go away with it.
- **`MySU.pas` (39)** is also probably a shadow RTL helper; audit during
  Phase 1.
- **Bottom of the list (1–3 blocks per file)** is mostly trivial — single
  inline-asm patterns. Likely 2-line rewrites in Pascal once identified.
- Approximate distribution:
  - 4 files × 50+ blocks = 323 blocks (54%)
  - 6 files × 10–39 blocks = 120 blocks (20%)
  - 64 files × 1–9 blocks = 157 blocks (26%)

The first 10 files in this table contain **400 of the 600 blocks (67%)**.
Tackle those and the rest is largely cleanup.

---

## Phase 2 — `wsprintf` Call Inventory

**Total: 172 `wsprintf(` call sites across 37 files.**

> Note: the original migration-strategy estimate of 73 calls (sourced from
> the upstream analysis doc) is **substantially low**. The actual count is
> ~2.4× that. The pattern of "PostUnit dominates the count" applies here too.

Each `wsprintf` call passes Pascal strings to a Win32 ANSI formatter. In
Phase 2 (Unicode), passing a `UnicodeString` (the new default `string`)
to `wsprintf` will silently produce garbage. Every call must be audited:

- If the buffer is consumed locally as bytes: keep `wsprintfA` explicitly and
  type the arguments as `AnsiString` / `PAnsiChar`.
- If the result feeds the UI: replace with `Format` / `SysUtils.Format`.

### Files sorted by count (descending)

| File | `wsprintf` calls |
|------|------------------|
| tr4w/src/trdos/PostUnit.PAS | 92 |
| tr4w/src/uQTCS.pas | 7 |
| tr4w/src/TF.pas | 6 |
| tr4w/src/trdos/LOGDVP.PAS | 5 |
| tr4w/src/MainUnit.pas | 5 |
| tr4w/src/uGetScores.pas | 4 |
| tr4w/src/trdos/tree.pas | 4 |
| tr4w/src/trdos/LOGSTUFF.PAS | 4 |
| tr4w/src/uWinKey.pas | 3 |
| tr4w/src/trdos/_JCtrl1.pas | 3 |
| tr4w/src/trdos/JCtrl1.pas | 3 |
| tr4w/src/uTelnet.pas | 2 |
| tr4w/src/uRadioPolling.pas | 2 |
| tr4w/src/uQTCR.pas | 2 |
| tr4w/src/uNewContest.pas | 2 |
| tr4w/src/uEditQSO.pas | 2 |
| tr4w/src/uAltP.pas | 2 |
| tr4w/src/trdos/LogCfg.pas | 2 |
| tr4w/src/trdos/LOGWIND.PAS | 2 |
| tr4w/src/trdos/LOGWAE.PAS | 2 |
| tr4w/src/exportto_trlog.pas | 2 |
| tr4w/src/uSpots.pas | 1 |
| tr4w/src/uRemMults_Zone.pas | 1 |
| tr4w/src/uRemMults.pas | 1 |
| tr4w/src/uProcessCommand.pas | 1 |
| tr4w/src/uMP3Recorder.pas | 1 |
| tr4w/src/uMMTTY.pas | 1 |
| tr4w/src/uLogSearch.pas | 1 |
| tr4w/src/uLogCompare.pas | 1 |
| tr4w/src/uIntercom.pas | 1 |
| tr4w/src/uEditMessage.pas | 1 |
| tr4w/src/uDistance.pas | 1 |
| tr4w/src/uCFG.pas | 1 |
| tr4w/src/trdos/LOGSUBS2.PAS | 1 |
| tr4w/src/trdos/FCONTEST.PAS | 1 |
| tr4w/src/tr4wserverUnit.pas | 1 |
| tr4w/src/DLPortIO.pas | 1 |

### Observations

- **`PostUnit.PAS` alone is 92 calls (53% of the total).** This file owns
  the Cabrillo export and ADIF export — exactly where formatted strings
  are written to byte-oriented file output, so the calls are likely
  semantically `wsprintfA` already. Should be a mechanical audit: confirm
  all args are byte strings, switch to `wsprintfA` explicit if not.
- **`TF.pas` (6 calls)** is the wrapper layer that the migration doc
  originally flagged. Worth auditing first because it shapes the helpers
  used everywhere else.
- **30 files have 1–3 calls each**, accounting for 50 calls (29%). Cheap
  per-file fixes; can be batched in a single Phase 2 PR.

### Recommended Phase 2 ordering

1. Audit `TF.pas` first — its 6 `wsprintf` wrappers shape callers elsewhere.
2. Audit `PostUnit.PAS` — biggest single concentration; likely a coherent
   fix-once-and-done.
3. Sweep the long tail of 1–3-call files together in a final cleanup PR.

---

## How These Inventories Were Built

For reproducibility on the next pre-Phase-1 audit:

```bash
# asm blocks
find tr4w/src -type f \( -name '*.pas' -o -name '*.PAS' \) \
    ! -name '*~*' ! -name '*.bakup' ! -name '*.bad' \
  | xargs grep -cE '^\s*asm\b' \
  | grep -v ':0$' \
  | sort -t: -k2 -rn

# wsprintf calls
find tr4w/src -type f \( -name '*.pas' -o -name '*.PAS' \) \
    ! -name '*~*' ! -name '*.bakup' ! -name '*.bad' \
  | xargs grep -cE '\bwsprintf\s*\(' \
  | grep -v ':0$' \
  | sort -t: -k2 -rn
```

The `^\s*asm\b` pattern catches the `asm` keyword at the start of a Pascal
`asm…end;` block specifically (not `wsprintfA` or other identifiers that
happen to contain "asm").
