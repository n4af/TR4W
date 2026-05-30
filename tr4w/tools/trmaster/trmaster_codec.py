#!/usr/bin/env python3
"""
TRMASTER.DTA codec — read/write the K1EA "CT / TRlog" Super Check Partial
binary format, plus a self-test that proves the writer round-trips against a
real file.

Format (confirmed against tr4w/src/trdos/LOGSCP.PAS, src/uSCP.pas, src/VC.pas
and supercheckpartial.com's formats page):

  Header: 37 x 37 = 1369 little-endian uint32 bucket *start* offsets, then a
          1370th uint32 = end offset = total file size.  => 5480-byte table.
  Body:   null-terminated records grouped into the 1369 buckets, laid out in
          linear order  bucket(X,Y) at index X*37 + Y.
  Index:  A-Z -> 0..25, 0-9 -> 26..35, '/' -> 36   (uSCP.scpMakeIndex).
  Record: callsign chars (each byte > 26), then for every non-empty field a
          one-byte control tag followed by its value, terminated by NUL (0).
          Most values are printable strings; Hits (^H) and Speed (^S) carry a
          single *binary* byte.  (LOGSCP.ConvertDatbaseEntryRecordToEntryArray
          is the canonical encoder this mirrors.)
  Bucketing: a call is stored once in the bucket of EACH distinct adjacent
          character pair it contains, so it is findable via any two-letter
          substring of a partial (LOGSCP.FirstCellForThisCall confirms this).

This module is offline tooling only — it never touches the running program.
"""

import os
import struct
import sys
import tempfile

# --- format constants -------------------------------------------------------

HEADER_BUCKETS = 37 * 37            # 1369
HEADER_LONGS = HEADER_BUCKETS + 1   # 1370 (buckets + end-offset)
HEADER_BYTES = HEADER_LONGS * 4     # 5480
NUL = 0

# control tag byte -> DataBaseEntryRecord field name (VC.pas:1218-1244).
# Order here is the canonical write order from ConvertDatbaseEntryRecordToEntryArray.
STRING_TAGS = [
    (0x01, "Section"),   # ^A
    (0x03, "CQZone"),    # ^C
    (0x06, "FOC"),       # ^F
    # Hits (^H, 0x08) is binary - handled separately, written here in order
    (0x07, "Grid"),      # ^G
    (0x09, "ITUZone"),   # ^I
    (0x0B, "Check"),     # ^K
    (0x0E, "Name"),      # ^N
    (0x0F, "OldCall"),   # ^O
    (0x11, "QTH"),       # ^Q
    # Speed (^S, 0x13) is binary
    (0x14, "TenTen"),    # ^T
    (0x15, "User1"),     # ^U  (CWops)
    (0x16, "User2"),     # ^V  (HSC)
    (0x17, "User3"),     # ^W
    (0x18, "User4"),     # ^X
    (0x19, "User5"),     # ^Y
]
TAG_TO_FIELD = {t: f for t, f in STRING_TAGS}
TAG_TO_FIELD[0x08] = "Hits"     # binary
TAG_TO_FIELD[0x13] = "Speed"    # binary
BINARY_TAGS = {0x08, 0x13}
FIELD_TO_TAG = {f: t for t, f in TAG_TO_FIELD.items()}

# canonical field write order (matches the Pascal encoder)
WRITE_ORDER = ["Section", "CQZone", "FOC", "Hits", "Grid", "ITUZone", "Check",
               "Name", "OldCall", "QTH", "Speed", "TenTen",
               "User1", "User2", "User3", "User4", "User5"]


def scp_index(ch):
    """Map a callsign char to its 0..36 bucket index, or None if not bucketable."""
    o = ord(ch)
    if 65 <= o <= 90:        # A-Z
        return o - 65
    if 48 <= o <= 57:        # 0-9
        return o - 48 + 26
    if ch == "/":
        return 36
    return None


def bucket_pairs(call):
    """Set of (X,Y) buckets a call belongs in: each distinct adjacent char pair.

    The 'JA' pair is deliberately excluded — it is so common (Japanese prefixes)
    that its bucket would be useless for narrowing, and LogSCP.BestTwoLetters
    skips it on lookup, so the builder must skip it on write too.
    """
    pairs = set()
    for i in range(len(call) - 1):
        if call[i:i + 2] == "JA":
            continue
        x = scp_index(call[i])
        y = scp_index(call[i + 1])
        if x is not None and y is not None:
            pairs.add((x, y))
    return pairs


# --- record encode/decode ---------------------------------------------------

def encode_record(call, fields):
    """Encode one call + fields dict into the null-terminated record bytes."""
    out = bytearray(call.encode("latin-1"))
    for name in WRITE_ORDER:
        val = fields.get(name)
        if val in (None, "", 0):
            continue
        tag = FIELD_TO_TAG[name]
        out.append(tag)
        if name in ("Hits", "Speed"):
            out.append(int(val) & 0xFF)
        else:
            # .dta is single-byte (ANSI). Existing latin-1 data round-trips
            # losslessly; any stray non-latin-1 char (e.g. an un-folded QRZ
            # name) becomes '?' rather than crashing the build.
            out += str(val).encode("latin-1", "replace")
    out.append(NUL)
    return bytes(out)


def _decode_record(buf, start):
    """Decode one record beginning at offset `start`. Returns (call, fields, next_offset)."""
    i = start
    n = len(buf)
    # callsign: leading bytes > 26 (ControlZ); stops at first tag/NUL
    cs = i
    while i < n and buf[i] > 26:
        i += 1
    call = buf[cs:i].decode("latin-1")
    fields = {}
    while i < n:
        b = buf[i]
        if b == NUL:
            i += 1
            break
        field = TAG_TO_FIELD.get(b)
        i += 1
        if field is None:
            # unknown tag byte; skip defensively
            continue
        if b in BINARY_TAGS:
            fields[field] = buf[i] if i < n else 0
            i += 1
        else:
            vs = i
            while i < n and buf[i] >= 32:
                i += 1
            fields[field] = buf[vs:i].decode("latin-1")
    return call, fields, i


# --- file read --------------------------------------------------------------

def read_dta(path):
    """
    Parse a TRMASTER/MASTER .dta file.

    Returns dict:
      calls        : {CALL: fields_dict}            (fields merged across buckets)
      buckets_of   : {CALL: set((X,Y), ...)}        (buckets the call appeared in)
      n_records    : total raw records (calls are duplicated across buckets)
      file_size    : bytes
      end_offset   : the uint32 end-offset stored at byte 5476
    """
    data = open(path, "rb").read()
    if len(data) < HEADER_BYTES:
        raise ValueError(f"{path}: too small to be a .dta ({len(data)} bytes)")
    offsets = struct.unpack_from("<%dI" % HEADER_LONGS, data, 0)
    end_offset = offsets[HEADER_BUCKETS]  # the 1370th long
    calls = {}
    buckets_of = {}
    n_records = 0
    for k in range(HEADER_BUCKETS):
        x, y = divmod(k, 37)
        start = offsets[k]
        stop = offsets[k + 1]
        if start == stop:
            continue
        if not (HEADER_BYTES <= start <= len(data)) or stop > len(data):
            raise ValueError(f"bucket {k} ({x},{y}) bad offsets {start}..{stop}")
        i = start
        while i < stop:
            call, fields, i = _decode_record(data, i)
            if not call:
                continue
            n_records += 1
            buckets_of.setdefault(call, set()).add((x, y))
            cur = calls.setdefault(call, {})
            for fk, fv in fields.items():
                if fv not in (None, "", 0):
                    cur[fk] = fv
    return {
        "calls": calls,
        "buckets_of": buckets_of,
        "n_records": n_records,
        "file_size": len(data),
        "end_offset": end_offset,
    }


# --- file write -------------------------------------------------------------

def write_dta(path, calls):
    """
    Write `calls` ({CALL: fields_dict}) to a K1EA .dta file, bucketing each call
    into every adjacent-pair bucket it belongs to.
    """
    buckets = [bytearray() for _ in range(HEADER_BUCKETS)]
    for call in sorted(calls):
        rec = encode_record(call, calls[call])
        for (x, y) in bucket_pairs(call):
            buckets[x * 37 + y] += rec

    # compute offsets
    offsets = [0] * HEADER_LONGS
    pos = HEADER_BYTES
    for k in range(HEADER_BUCKETS):
        offsets[k] = pos
        pos += len(buckets[k])
    offsets[HEADER_BUCKETS] = pos  # end offset == final file size

    with open(path, "wb") as f:
        f.write(struct.pack("<%dI" % HEADER_LONGS, *offsets))
        for b in buckets:
            f.write(b)
    return pos


# --- self-test --------------------------------------------------------------

def selftest(src_path):
    """Read src -> write to temp -> read back -> assert semantic equivalence."""
    print(f"=== self-test against {src_path} ===")
    a = read_dta(src_path)
    print(f"  source: {a['file_size']} bytes, end-offset field={a['end_offset']} "
          f"({'OK' if a['end_offset'] == a['file_size'] else 'MISMATCH'})")
    print(f"  unique calls: {len(a['calls'])}   raw records: {a['n_records']}")

    # bucketing rule check: every bucket a call appeared in must equal the
    # adjacent-pair rule we use when writing.
    rule_mismatch = 0
    for call, got in a["buckets_of"].items():
        if got != bucket_pairs(call):
            rule_mismatch += 1
    print(f"  bucketing-rule mismatches: {rule_mismatch}  "
          f"({'rule confirmed' if rule_mismatch == 0 else 'RULE DIFFERS'})")

    fd, tmp = tempfile.mkstemp(suffix=".dta")
    os.close(fd)
    try:
        size = write_dta(tmp, a["calls"])
        b = read_dta(tmp)
        print(f"  rewritten: {size} bytes, unique calls: {len(b['calls'])}, "
              f"raw records: {b['n_records']}")

        # semantic equivalence: same call set + same fields per call
        ca, cb = set(a["calls"]), set(b["calls"])
        miss = ca - cb
        extra = cb - ca
        fieldsdiff = sum(1 for c in (ca & cb) if a["calls"][c] != b["calls"][c])
        bucketsdiff = sum(1 for c in (ca & cb)
                          if a["buckets_of"][c] != b["buckets_of"][c])
        print(f"  calls missing after round-trip: {len(miss)}")
        print(f"  calls added after round-trip:   {len(extra)}")
        print(f"  calls with differing fields:    {fieldsdiff}")
        print(f"  calls with differing buckets:   {bucketsdiff}")
        ok = not miss and not extra and fieldsdiff == 0 and bucketsdiff == 0
        print(f"  ROUND-TRIP: {'PASS' if ok else 'FAIL'}")
        return ok
    finally:
        os.remove(tmp)


def analyze(src_path):
    a = read_dta(src_path)
    calls = a["calls"]
    def has(f):
        return sum(1 for v in calls.values() if v.get(f))
    print(f"=== field census: {src_path} ===")
    print(f"  unique calls: {len(calls)}")
    for f in ("Name", "User1", "FOC", "User2", "CQZone", "ITUZone",
              "Check", "Grid", "QTH", "Hits", "Speed"):
        print(f"    {f:8}: {has(f)}")


if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "tr4w/target/TRMASTER.DTA"
    analyze(path)
    print()
    ok = selftest(path)
    sys.exit(0 if ok else 1)
