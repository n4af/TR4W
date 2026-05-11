# TR4W ADIF Export Verifier (Phase 1)

End-to-end test that cross-checks TR4W's `File -> Export to ADIF` output
against the canonical binary log (`.TRW`).  Designed to catch corruption
and field-level regressions in the export pipeline.

## How it works

```
log.TRW  --[ logdump.exe ]-->  records as JSONL (canonical record values)
log.ADI  --[ this script ]-->  parsed ADIF records (export output)
                               cross-check field-by-field
```

`logdump.exe` is a tiny Delphi 7 console tool that reuses the canonical
`ContestExchange` record definition from `VC.pas`, so the verifier never
needs to know the binary layout of the log file — that knowledge lives
in exactly one place (Pascal), as it should.

## Requirements

- Python 3.7+ (no third-party packages)
- `tr4w/test/logdump/logdump.exe` — build with
  `powershell.exe -ExecutionPolicy Bypass -File tr4w/test/logdump/BuildLogDump.ps1`

## Usage

```
python verify_adif_export.py <contest-directory>
python verify_adif_export.py <log.TRW> <log.ADI>
```

Auto-mode (single argument) finds the `.TRW` and `.ADI` inside a contest
directory like `target/2026 CQ-WPX-SSB NY4I/`.

## Important: fresh exports

The verifier expects the `.ADI` to have been produced from the **current
state** of the `.TRW` by the **current** TR4W build.  In particular:

- If you add QSOs to the log after exporting, re-export before verifying
  or the record-count check will fail.
- Older `.ADI` files (from previous TR4W versions) may legitimately omit
  fields that the current export emits — those will be flagged as
  mismatches even though nothing is wrong with the old file.

## What it checks

For each record (matched by position):

- `CALL`, `BAND` (with 70cm/23cm rewrites)
- `QSO_DATE`, `TIME_ON`, `TIME_OFF`
- `MODE` and `SUBMODE` (using the same `ExtMode` mapping as `uADIF`)
- `RST_SENT`, `RST_RCVD`
- `SRX` / `STX` (5-digit zero-padded, when set)
- `OPERATOR`, `APP_TR4W_ID`
- `NAME`, `RX_PWR`, `CHECK`, `TEN_TEN`
- `QTH` and `STATE` (when `QTHString` is a 2-letter state)

It also runs a structural check on the whole `.ADI` — any null byte or
non-whitespace control character is reported as corruption, with
context.  This is the check that would have caught the
`sWriteFileFromString` overflow bug instantly.

## What it does NOT check (Phase 1 scope)

The contest-specific tail fields, because they depend on MainUnit/trdos
globals (not the log record):

- `STX_STRING` (built from `MyCall`/`MyFDClass`/`MySection`/`MyPark`)
- `CNTY` (from `mo.DomList[].FAltName`)
- `CQZ` / `ITUZ` (from `ActiveZoneMult`)
- `MY_POTA_REF`, `MY_SIG`, `MY_SIG_INFO`
- `STATION_CALLSIGN`, `CLASS`
- `ARRL_SECT`, `GRIDSQUARE`, `IOTA`, `DOK`, `APP_TR4W_HQ`

Phase 2 would parse `settings/tr4w.ini` + `.dom` files to reconstruct
those globals and check the tail emitter too.

## Exit codes

- `0` — all checks passed
- `1` — one or more field mismatches
- `2` — structural failure (file unreadable, ADIF corrupt, record count differs)
- `3` — `logdump.exe` missing or failed
