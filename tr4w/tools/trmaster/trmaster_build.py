#!/usr/bin/env python3
"""
Offline TRMASTER.DTA builder.

Unions a fresh callsign list (supercheckpartial MASTER.DTA, or optionally the
richer SCP.DB sqlite) with the membership/name layer (CWops roster CSV, FOC,
HSC) and any previously-accumulated names from the existing TRMASTER.DTA, then
writes a single K1EA .dta that TR4W's existing reader consumes unchanged.

Pipeline (precedence shown):
  call universe  = MASTER.DTA calls  (+ every roster/existing call)
  per call fields:
    1. existing TRMASTER.DTA            (preserve accumulated Name + memberships)
    2. CWops CSV   -> User1 (CWops #) + Name (overrides; roster is current)
    3. FOC         -> FOC #            + Name (fills if missing)
    4. HSC         -> User2 (HSC #)
    5. name resolver (optional --names-csv from your FCC/QRZ script) fills any
       call still missing a Name

Nothing here runs inside TR4W. Run it before the monthly build.

  python trmaster_build.py --out TRMASTER.DTA \
      --existing ../../target/TRMASTER.DTA \
      --download-master --cwops-url <google-csv-export-url> \
      [--scp-db _work/SCP.DB] [--names-csv names.csv] [--foc-csv foc.csv]

See README.md in this directory for source URLs and the FCC/QRZ hook.
"""

import argparse
import csv
import os
import re
import sqlite3
import sys
import urllib.request

import trmaster_codec as tc

CALL_RE = re.compile(r"^[A-Z0-9/]{3,}$")

# Prefixes where QRZ / licensing coverage is comprehensive enough that
# "not QRZ-verified" reliably means lapsed/invalid: US (K/N/W/AA-AL),
# UK (G/M/2E/2I/2M/2U/2W), Canada (VA/VE/VO/VY). Everywhere else is DX, where
# QRZ is NOT a definitive source, so those calls are never pruned.
US_UK_CA_RE = re.compile(r"^([KNW]|A[A-L]|G|M|2[EIMUW]|V[AEOY])")


def is_qrz_reliable_region(call):
    return bool(US_UK_CA_RE.match(call))
MASTER_DTA_URL = "https://supercheckpartial.com/downloads/MASTER.DTA"
SCP_DB_URL = "https://supercheckpartial.com/downloads/SCP.DB"


def log(msg):
    print(msg, flush=True)


def download(url, dest, force=False):
    if os.path.exists(dest) and not force:
        log(f"  cached: {dest} ({os.path.getsize(dest)} bytes)")
        return dest
    log(f"  downloading {url} -> {dest}")
    os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
    req = urllib.request.Request(url, headers={"User-Agent": "tr4w-trmaster-build"})
    with urllib.request.urlopen(req, timeout=120) as r, open(dest, "wb") as f:
        f.write(r.read())
    log(f"  saved {os.path.getsize(dest)} bytes")
    return dest


def valid_call(c):
    return bool(c) and bool(CALL_RE.match(c))


# --- source loaders ---------------------------------------------------------

def load_calls_from_dta(path):
    """Just the callsign universe from a .dta (e.g. supercheckpartial MASTER.DTA)."""
    return set(tc.read_dta(path)["calls"].keys())


def load_calls_from_scpdb(path, min_annual_rate=0):
    """Callsign universe from SCP.DB; optional activity floor via annual_rate."""
    out = set()
    c = sqlite3.connect(path)
    for call, rate in c.execute("select callsign, annual_rate from callsigns"):
        if call and valid_call(call.upper()):
            if min_annual_rate and (rate or 0) < min_annual_rate:
                continue
            out.add(call.upper())
    c.close()
    return out


def load_scpdb_verified(path):
    """From SCP.DB return (all_calls, qrz_verified_calls).
    QRZ-verified = bit 4 of the `verified` bitmask."""
    allc, ver = set(), set()
    c = sqlite3.connect(path)
    for call, v in c.execute("select callsign, verified from callsigns"):
        if not call:
            continue
        cu = call.upper()
        allc.add(cu)
        if (v or 0) & (1 << 4):
            ver.add(cu)
    c.close()
    return allc, ver


def load_existing(path):
    """Existing TRMASTER fields, to preserve accumulated names + memberships."""
    if not path or not os.path.exists(path):
        return {}
    return tc.read_dta(path)["calls"]


def parse_cwops_csv(path):
    """CWops roster CSV -> {CALL: {'User1': cwops#, 'Name': FIRSTNAME}}.

    Positional columns (no usable header): [2]=call [3]=number [4]=first name.
    """
    out = {}
    with open(path, newline="", encoding="utf-8", errors="replace") as f:
        for row in csv.reader(f):
            if len(row) < 5:
                continue
            call = row[2].strip().upper()
            num = row[3].strip()
            name = row[4].strip().upper()
            if not valid_call(call) or not num.isdigit():
                continue
            rec = {"User1": num}
            if name:
                rec["Name"] = name
            out[call] = rec
    return out


def parse_simple_csv(path, field):
    """Generic 'CALL,NUMBER[,NAME]' loader for FOC/HSC exports.
    `field` is 'FOC' or 'User2'. Returns {CALL: {field: num, ['Name': NAME]}}.
    """
    out = {}
    if not path or not os.path.exists(path):
        return out
    with open(path, newline="", encoding="utf-8", errors="replace") as f:
        for row in csv.reader(f):
            if not row:
                continue
            call = row[0].strip().upper()
            if not valid_call(call):
                continue
            rec = {}
            if len(row) > 1 and row[1].strip():
                rec[field] = row[1].strip()
            if len(row) > 2 and row[2].strip():
                rec["Name"] = row[2].strip().upper()
            if rec:
                out[call] = rec
    return out


def load_names_csv(path):
    """Optional name source (e.g. produced by the user's FCC/QRZ scripts):
    'CALL,NAME' -> {CALL: NAME(upper)}.  This is the name-resolver hook.
    """
    out = {}
    if not path or not os.path.exists(path):
        return out
    with open(path, newline="", encoding="utf-8", errors="replace") as f:
        for row in csv.reader(f):
            if len(row) >= 2 and valid_call(row[0].strip().upper()) and row[1].strip():
                out[row[0].strip().upper()] = row[1].strip().upper()
    return out


# --- merge ------------------------------------------------------------------

def merge(universe, existing, cwops, foc, hsc, names):
    """Build {CALL: fields} by the documented precedence."""
    calls = set(universe) | set(existing) | set(cwops) | set(foc) | set(hsc)
    out = {}
    for call in calls:
        f = {}
        # 1. preserve accumulated data
        if call in existing:
            f.update(existing[call])
        # 2. CWops (current roster wins for number + name)
        if call in cwops:
            f["User1"] = cwops[call]["User1"]
            if cwops[call].get("Name"):
                f["Name"] = cwops[call]["Name"]
        # 3. FOC
        if call in foc:
            if foc[call].get("FOC"):
                f["FOC"] = foc[call]["FOC"]
            if foc[call].get("Name") and not f.get("Name"):
                f["Name"] = foc[call]["Name"]
        # 4. HSC
        if call in hsc and hsc[call].get("User2"):
            f["User2"] = hsc[call]["User2"]
        # 5. name resolver fills the gap
        if not f.get("Name") and call in names:
            f["Name"] = names[call]
        out[call] = f
    return out


def census(calls, label):
    def has(fld):
        return sum(1 for v in calls.values() if v.get(fld))
    log(f"=== {label}: {len(calls)} calls ===")
    for fld in ("Name", "User1", "FOC", "User2"):
        log(f"    {fld:6}: {has(fld)}")
    log(f"    bare (no name): {sum(1 for v in calls.values() if not v.get('Name'))}")


def main(argv=None):
    ap = argparse.ArgumentParser(description="Offline TRMASTER.DTA builder")
    ap.add_argument("--out", default="TRMASTER.DTA")
    ap.add_argument("--existing", help="existing TRMASTER.DTA to preserve names from")
    ap.add_argument("--master-dta", help="local supercheckpartial MASTER.DTA")
    ap.add_argument("--download-master", action="store_true",
                    help="download the latest MASTER.DTA")
    ap.add_argument("--scp-db", help="SCP.DB sqlite as the call universe (instead of MASTER.DTA)")
    ap.add_argument("--min-annual-rate", type=int, default=0,
                    help="when using --scp-db, drop calls below this activity rate")
    ap.add_argument("--cwops-csv", help="local CWops roster CSV")
    ap.add_argument("--cwops-url", help="CWops roster CSV export URL")
    ap.add_argument("--foc-csv", help="FOC export CSV (CALL,NUM[,NAME])")
    ap.add_argument("--hsc-csv", help="HSC export CSV (CALL,NUM[,NAME])")
    ap.add_argument("--names-csv", help="name source CSV (CALL,NAME) from FCC/QRZ")
    ap.add_argument("--prune-qrz-unverified", metavar="SCP.DB",
                    help="drop universe calls that SCP.DB marks NOT QRZ-verified "
                         "(removes lapsed/unverifiable calls; curated CWops/FOC/"
                         "HSC/existing calls are never pruned)")
    ap.add_argument("--workdir", default="_work")
    ap.add_argument("--force", action="store_true", help="re-download even if cached")
    args = ap.parse_args(argv)

    # 1. call universe
    if args.scp_db:
        log("call universe: SCP.DB")
        universe = load_calls_from_scpdb(args.scp_db, args.min_annual_rate)
    else:
        mpath = args.master_dta
        if args.download_master or not mpath:
            mpath = download(MASTER_DTA_URL, os.path.join(args.workdir, "MASTER.DTA"),
                             force=args.force)
        log("call universe: MASTER.DTA")
        universe = load_calls_from_dta(mpath)
    log(f"  universe calls: {len(universe)}")

    # Optional prune: keep only QRZ-verified universe calls (SCP.DB bit 4).
    # Calls absent from SCP.DB are kept (can't judge); curated calls are added
    # later by merge() regardless, so they are never pruned here.
    if args.prune_qrz_unverified:
        allc, ver = load_scpdb_verified(args.prune_qrz_unverified)
        before = len(universe)
        # Prune ONLY US/UK/CA calls that SCP.DB knows are not QRZ-verified.
        # DX calls are kept regardless (QRZ is not definitive outside those
        # regions); curated CWops/FOC/HSC/existing calls are added by merge()
        # afterward, so they are never pruned here.
        universe = {c for c in universe
                    if not (is_qrz_reliable_region(c) and c in allc and c not in ver)}
        log(f"  QRZ-verified prune (US/UK/CA only): {before} -> {len(universe)} "
            f"(dropped {before - len(universe)}; DX kept)")

    # 2. layers
    existing = load_existing(args.existing)
    log(f"  existing TRMASTER calls: {len(existing)}")

    cwops_path = args.cwops_csv
    if args.cwops_url and not cwops_path:
        cwops_path = download(args.cwops_url, os.path.join(args.workdir, "cwops.csv"),
                              force=args.force)
    cwops = parse_cwops_csv(cwops_path) if cwops_path else {}
    log(f"  CWops roster: {len(cwops)}")

    # FOC/HSC: seed from existing TRMASTER, override with explicit exports if given
    foc = {c: {"FOC": v["FOC"], "Name": v.get("Name")}
           for c, v in existing.items() if v.get("FOC")}
    foc.update(parse_simple_csv(args.foc_csv, "FOC"))
    hsc = {c: {"User2": v["User2"]} for c, v in existing.items() if v.get("User2")}
    hsc.update(parse_simple_csv(args.hsc_csv, "User2"))
    log(f"  FOC entries: {len(foc)}   HSC entries: {len(hsc)}")

    names = load_names_csv(args.names_csv)
    log(f"  name-resolver names: {len(names)}")

    # 3. merge + write
    merged = merge(universe, existing, cwops, foc, hsc, names)
    census(merged, "merged")
    size = tc.write_dta(args.out, merged)
    log(f"\nwrote {args.out}: {size} bytes")

    # 4. validate output is readable + self-consistent
    back = tc.read_dta(args.out)
    ok = (len(back["calls"]) == len(merged)
          and back["end_offset"] == back["file_size"])
    log(f"validate: re-read {len(back['calls'])} calls, "
        f"end-offset {'OK' if back['end_offset']==back['file_size'] else 'MISMATCH'} "
        f"-> {'PASS' if ok else 'FAIL'}")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
