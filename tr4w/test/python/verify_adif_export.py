#!/usr/bin/env python3
"""
TR4W ADIF Export Verifier (Phase 1)

Cross-checks the ADIF file produced by TR4W's File -> Export to ADIF against
the canonical binary log (.TRW) file.  Verifies the fields that come from
the ContestExchange record itself; the contest-specific tail fields
(STX_STRING, CNTY, CQZ, STATION_CALLSIGN, MY_POTA_REF, CLASS) depend on
MainUnit globals and are out of scope for Phase 1.

Pipeline:
    log.TRW  --[ logdump.exe ]-->  records.jsonl
    log.ADI  --[ this script ]-->  parsed ADIF records (list of dicts)
                                   ^ cross-check by record index

Usage:
    python verify_adif_export.py <log.TRW> <log.ADI>
    python verify_adif_export.py --auto <contest-dir>     # finds .TRW + .ADI

Exit codes:
    0  all checks passed
    1  one or more field mismatches
    2  structural failure (file unreadable, record count differs, etc.)
    3  logdump.exe missing or failed
"""

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

LOGDUMP_EXE = Path(__file__).resolve().parent.parent / "logdump" / "logdump.exe"

# ---------------------------------------------------------------------------
# ADIF parser
# ---------------------------------------------------------------------------

# An ADIF field tag is one of:
#   <NAME:LEN[:TYPE]>VALUE     -- a data field, value is exactly LEN chars
#   <EOH>                       -- end of header (no value)
#   <EOR>                       -- end of record (no value)
# The data-field regex matches the first form; we handle EOH/EOR as
# special unsized tags by checking the name after a relaxed match.
ADIF_TAG_RE = re.compile(
    r"<([A-Z0-9_]+)(?::(\d+)(?::[A-Z])?)?>",
    re.IGNORECASE,
)


def parse_adif(text):
    """Parse ADIF text into (header_fields, [record_fields, ...]).

    header_fields and each record's dict map UPPER-CASE field name to value.
    Records are delimited by <EOR>; header (if any) is delimited by <EOH>.
    """
    header = {}
    records = []
    current = {}
    in_header = True
    pos = 0
    n = len(text)

    while pos < n:
        m = ADIF_TAG_RE.search(text, pos)
        if not m:
            break
        name = m.group(1).upper()
        length_str = m.group(2)

        if name == "EOH":
            in_header = False
            pos = m.end()
            continue
        if name == "EOR":
            records.append(current)
            current = {}
            pos = m.end()
            continue

        if length_str is None:
            # Unknown unsized tag -- skip it.  ADIF spec only defines EOH/EOR
            # as unsized; anything else with no length is malformed.
            pos = m.end()
            continue

        length = int(length_str)
        value_start = m.end()
        value_end = value_start + length
        if value_end > n:
            raise ValueError(
                f"ADIF: field <{name}:{length}> at offset {m.start()} "
                f"runs past end of file (have {n - value_start} bytes)"
            )
        value = text[value_start:value_end]

        if in_header:
            header[name] = value
        else:
            current[name] = value
        pos = value_end

    # Anything past the last <EOR> is discarded silently (matches what real
    # ADIF readers do).
    return header, records


def adif_is_structurally_clean(text):
    """Check that every byte between the first <ADIF_VER> / record start
    and the last <EOR> is printable ASCII or whitespace.  Catches the
    binary-garbage corruption the sWriteFileFromString bug used to produce.

    Returns (ok, first_bad_offset, first_bad_byte).
    """
    for i, ch in enumerate(text):
        c = ord(ch)
        if c == 0:
            return False, i, c
        if c < 0x20 and c not in (0x09, 0x0A, 0x0D):
            return False, i, c
        if c >= 0x80:
            # Non-ASCII -- unusual for ADIF but not necessarily corrupt.
            # We let it pass with a warning rather than fail.
            pass
    return True, -1, -1


# ---------------------------------------------------------------------------
# logdump runner
# ---------------------------------------------------------------------------


def run_logdump(trw_path):
    """Invoke logdump.exe and return (meta, [record_dicts, ...])."""
    if not LOGDUMP_EXE.exists():
        sys.stderr.write(
            f"ERROR: logdump.exe not found at {LOGDUMP_EXE}\n"
            f"       Run tr4w/test/logdump/BuildLogDump.ps1 first.\n"
        )
        sys.exit(3)

    result = subprocess.run(
        [str(LOGDUMP_EXE), str(trw_path)],
        capture_output=True,
        text=True,
        encoding="latin-1",  # JSON we emit is ASCII; ShortString values may contain hi-bit
    )
    if result.returncode != 0:
        sys.stderr.write(
            f"ERROR: logdump.exe failed with exit code {result.returncode}\n"
        )
        sys.stderr.write(result.stderr)
        sys.exit(3)

    meta = None
    records = []
    for line in result.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        obj = json.loads(line)
        if obj.get("_meta"):
            meta = obj
        else:
            records.append(obj)
    return meta, records


# ---------------------------------------------------------------------------
# Cross-check
# ---------------------------------------------------------------------------


def _trim(s):
    return s.strip() if isinstance(s, str) else s


class Checker:
    """Accumulates per-record field mismatches."""

    def __init__(self):
        self.errors = []
        self.checks = 0

    def expect(self, idx, field, expected, actual, *, allow_missing=False):
        self.checks += 1
        if actual is None and allow_missing:
            return
        e = _trim(expected)
        a = _trim(actual)
        if e == "" and a is None:
            return
        if e == a:
            return
        self.errors.append((idx, field, expected, actual))

    def expect_int(self, idx, field, expected, actual, *, allow_missing=False):
        self.checks += 1
        if actual is None and allow_missing:
            return
        if actual is None:
            self.errors.append((idx, field, expected, "<missing>"))
            return
        try:
            a = int(actual.lstrip("0") or "0")
        except ValueError:
            self.errors.append((idx, field, expected, f"non-int: {actual!r}"))
            return
        if a != expected:
            self.errors.append((idx, field, expected, actual))

    def report(self):
        if not self.errors:
            return True
        for idx, field, expected, actual in self.errors[:50]:
            sys.stderr.write(
                f"  record #{idx}  {field}: expected {expected!r}, "
                f"got {actual!r}\n"
            )
        if len(self.errors) > 50:
            sys.stderr.write(
                f"  ... and {len(self.errors) - 50} more mismatches\n"
            )
        return False


def cross_check(log_records, adif_records):
    """Compare log records (canonical) against ADIF records (export output).
    Returns True if everything matched, False otherwise.  Field assertions
    skip values that are sourced from MainUnit globals (the tail emitter's
    responsibility).
    """
    chk = Checker()

    if len(log_records) != len(adif_records):
        sys.stderr.write(
            f"ERROR: record count mismatch -- log has {len(log_records)} "
            f"good QSO(s), ADIF has {len(adif_records)} record(s)\n"
        )
        return False

    for i, (log, adif) in enumerate(zip(log_records, adif_records)):
        # CALL.  For state-QP rover ('CALL/<county>' where county matches
        # QTHString), ADIF emits the bare call here.  We approximate by
        # checking that ADIF CALL is a prefix of the log call up to '/'.
        log_call = log["Call"]
        adif_call = adif.get("CALL", "")
        if "/" in log_call and adif_call == log_call.split("/", 1)[0]:
            pass  # rover-decomposed; tail emitter writes APP_TR4W_ROVERCALL
        else:
            chk.expect(i, "CALL", log_call, adif_call)

        # BAND -- with the 70cm / 23cm rewrites
        expected_band = log["Band"]
        if expected_band == "432":
            expected_band = "70cm"
        elif expected_band == "1GH":
            expected_band = "23cm"
        chk.expect(i, "BAND", expected_band, adif.get("BAND"))

        # QSO_DATE / TIME_ON / TIME_OFF
        chk.expect(i, "QSO_DATE", log["QSODate"], adif.get("QSO_DATE"))
        chk.expect(i, "TIME_ON",  log["QSOTime"], adif.get("TIME_ON"))
        chk.expect(i, "TIME_OFF", log["QSOTime"], adif.get("TIME_OFF"))

        # MODE / SUBMODE
        # ExtMode -> ADIF mode mapping mirrors uADIF.ResolveADIFModeSubmode.
        ext = log["ExtMode"]
        mode = log["Mode"]
        if ext == "NoMode":
            expected_mode = "RTTY" if mode == "DIGITAL" else mode
            expected_submode = None
        elif ext == "SSB":  # base, no specific USB/LSB
            expected_mode = "SSB"
            expected_submode = None
        elif ext == "USB":
            expected_mode = "SSB"
            expected_submode = "USB"
        elif ext == "LSB":
            expected_mode = "SSB"
            expected_submode = "LSB"
        elif ext == "PSK31":
            expected_mode = "PSK"
            expected_submode = "PSK31"
        elif ext == "FT4":
            expected_mode = "MFSK"
            expected_submode = "FT4"
        else:
            expected_mode = ext
            expected_submode = None

        chk.expect(i, "MODE", expected_mode, adif.get("MODE"))
        if expected_submode is not None:
            chk.expect(i, "SUBMODE", expected_submode, adif.get("SUBMODE"))

        # RST_SENT / RST_RCVD (stored as integers in log, emitted as IntToStr)
        chk.expect(i, "RST_SENT", str(log["RSTSent"]), adif.get("RST_SENT"))
        chk.expect(i, "RST_RCVD", str(log["RSTReceived"]), adif.get("RST_RCVD"))

        # SRX / STX -- 5-digit zero-padded, only emitted when != -1 (=0xFFFF as Word)
        if log["NumberReceived"] not in (-1, 0xFFFF, 65535):
            chk.expect_int(i, "SRX", log["NumberReceived"], adif.get("SRX"))
        if log["NumberSent"] not in (-1, 0xFFFF, 65535):
            chk.expect_int(i, "STX", log["NumberSent"], adif.get("STX"))

        # OPERATOR + APP_TR4W_ID
        if log["Operator"]:
            chk.expect(i, "OPERATOR", log["Operator"], adif.get("OPERATOR"))
        if log["ID"]:
            chk.expect(i, "APP_TR4W_ID", log["ID"], adif.get("APP_TR4W_ID"))

        # NAME (emitted only when non-empty)
        if log["Name"]:
            chk.expect(i, "NAME", log["Name"], adif.get("NAME"))

        # Power -> RX_PWR (or FOC_NUM for FOCMARATHON, which we don't
        # detect here without the contest enum; skip Power check when
        # the field isn't in the ADIF at all).
        if log["Power"] and adif.get("RX_PWR") is not None:
            chk.expect(i, "RX_PWR", log["Power"], adif.get("RX_PWR"))

        # CHECK (zero-padded 2-digit), TEN_TEN
        if log["Check"] != 0:
            chk.expect_int(i, "CHECK", log["Check"], adif.get("CHECK"))
        if log["TenTenNum"] not in (0, 65535):
            chk.expect_int(i, "TEN_TEN", log["TenTenNum"], adif.get("TEN_TEN"))

        # QTH / STATE -- QTH is always emitted when QTHString is non-empty.
        # STATE is emitted when QTHString is a 2-letter postal code.
        if log["QTHString"]:
            chk.expect(i, "QTH", log["QTHString"], adif.get("QTH"))
            qs = log["QTHString"]
            if len(qs) == 2 and not any(c.isdigit() for c in qs):
                chk.expect(i, "STATE", qs, adif.get("STATE"))

    print(f"  {chk.checks} field comparisons performed.")
    return chk.report()


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def find_pair(directory):
    """Given a contest directory, find the .TRW and .ADI pair."""
    d = Path(directory)
    if not d.is_dir():
        sys.stderr.write(f"ERROR: not a directory: {directory}\n")
        sys.exit(2)
    trws = sorted(d.glob("*.TRW"))
    # Skip .bkup files (TR4W creates *.TRW-v1.6.bkup during version upgrade)
    trws = [p for p in trws if p.suffix.upper() == ".TRW"]
    adis = list(d.glob("*.ADI")) + list(d.glob("*.adi"))
    if not trws:
        sys.stderr.write(f"ERROR: no .TRW file found in {directory}\n")
        sys.exit(2)
    if not adis:
        sys.stderr.write(
            f"ERROR: no .ADI file found in {directory}.  Run "
            f"File -> Export to ADIF in TR4W first.\n"
        )
        sys.exit(2)
    return trws[0], adis[0]


def main():
    ap = argparse.ArgumentParser(description=__doc__.strip().splitlines()[0])
    ap.add_argument("trw_or_dir", help=".TRW log file OR contest directory")
    ap.add_argument("adi", nargs="?",
                    help=".ADI export file (omit if first arg is a dir)")
    ap.add_argument("--auto", action="store_true",
                    help="(legacy flag, no-op -- auto-detect is default "
                         "when a directory is given)")
    args = ap.parse_args()

    if args.adi is None:
        trw_path, adi_path = find_pair(args.trw_or_dir)
    else:
        trw_path = Path(args.trw_or_dir)
        adi_path = Path(args.adi)

    print(f"Log:  {trw_path}")
    print(f"ADIF: {adi_path}")

    # --- Parse the binary log via logdump.exe ---
    meta, log_records = run_logdump(trw_path)
    if meta:
        print(f"  Log version: {meta.get('logVersion')}, "
              f"record size: {meta.get('recordSize')} bytes")
    print(f"  {len(log_records)} good QSO(s) in binary log")

    # --- Read + structurally check the ADIF ---
    try:
        adif_text = adi_path.read_text(encoding="latin-1")
    except OSError as e:
        sys.stderr.write(f"ERROR: cannot read {adi_path}: {e}\n")
        sys.exit(2)

    ok, bad_off, bad_byte = adif_is_structurally_clean(adif_text)
    if not ok:
        sys.stderr.write(
            f"ERROR: ADIF file contains a non-printable byte 0x{bad_byte:02x} "
            f"at offset {bad_off}.  This is the sWriteFileFromString-style "
            f"corruption.\n"
        )
        # Show ~80 bytes of context around the bad byte
        start = max(0, bad_off - 40)
        end   = min(len(adif_text), bad_off + 40)
        ctx = adif_text[start:end].replace("\r", "\\r").replace("\n", "\\n")
        sys.stderr.write(f"  context: ...{ctx}...\n")
        sys.exit(2)

    header, adif_records = parse_adif(adif_text)
    print(f"  ADIF header: ADIF_VER={header.get('ADIF_VER')}, "
          f"PROGRAMID={header.get('PROGRAMID')}, "
          f"PROGRAMVERSION={header.get('PROGRAMVERSION')}")
    print(f"  {len(adif_records)} record(s) in ADIF")

    print()
    print("=== Cross-checking fields ===")
    if cross_check(log_records, adif_records):
        print()
        print("PASS: all field cross-checks passed.")
        sys.exit(0)
    else:
        print()
        sys.stderr.write("FAIL: one or more field mismatches.\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
