#!/usr/bin/env python3
"""
Join WA7BNM friendly names into TR4W's ContestsArray.

Data source : tr4w.net/tools/contests/wa7bnm_cabnames.txt  (<ref-id>|<Friendly Name>)
Target      : tr4w/src/VC.pas  ContestsArray[ContestType] of TContestInfo

Convention (mirrors ADIFName/CABName: "if blank, use the name"):
  FriendlyName is appended as the LAST field of every live element.
  The ARRAY is the source of truth: each entry's WA7BNM id selects the name.
  - id matches the file -> that name
  - else (id 0, or id not in file) -> '' (blank); consumer falls back to ContestTypeSA[ct]
  There is deliberately NO override map: if a name is wrong, fix the id in VC.pas.

  Known intentional shared id: WRTC and IARU both use 67, so WRTC displays the
  IARU HF World Championship name by design (WRTC is logged as the IARU contest).

Default mode is DRY-RUN. Pass --apply to write into VC.pas.
"""
import re, sys, pathlib

VC    = pathlib.Path("/Users/toms/projects/TR4W/tr4w/src/VC.pas")
NAMES = pathlib.Path("/Users/toms/projects/tr4w.net/tools/contests/wa7bnm_cabnames.txt")

def load_names():
    d = {}
    for ln in NAMES.read_text(encoding="utf-8", errors="replace").splitlines():
        ln = ln.strip()
        if not ln or ln.startswith("#") or "|" not in ln:
            continue
        rid, name = ln.split("|", 1)
        d[int(rid)] = name.strip()
    return d

def block(lines, start_pat):
    s = next(i for i, l in enumerate(lines) if re.search(start_pat, l))
    e = next(i for i in range(s + 1, len(lines)) if lines[i].strip().startswith(");"))
    return s, e

def is_entry(line):
    return "WA7BNM:" in line and not line.lstrip().startswith("//")

def value_for(short, wid, names):
    if wid and wid in names:
        return names[wid]
    return ""

def main():
    apply = "--apply" in sys.argv
    names = load_names()
    lines = VC.read_text(encoding="utf-8", errors="replace").splitlines(keepends=True)

    cs, ce = block(lines, r"ContestsArray\s*:\s*array\[ContestType\] of TContestInfo")
    ts, te = block(lines, r"ContestTypeSA\s*:\s*array\[ContestType\] of PChar")

    entries = [(i, lines[i]) for i in range(cs, ce) if is_entry(lines[i])]
    sa = [m.group(1) for i in range(ts, te)
          for m in [re.search(r"'([^']*)'", lines[i])] if m]
    if len(entries) != len(sa):
        print(f"!! ALIGNMENT MISMATCH: {len(entries)} entries vs {len(sa)} SA names. Aborting.")
        sys.exit(1)

    filled = blank = 0
    plan = []
    for (idx, line), short in zip(entries, sa):
        wid = int(re.search(r"WA7BNM:\s*(\d+)", line).group(1))
        val = value_for(short, wid, names)
        plan.append((idx, short, val))
        if val: filled += 1
        else:   blank += 1

    print(f"live entries {len(entries)} | filled {filled} | blank(manual) {blank}")
    # Flag any remaining non-zero WA7BNM id shared by >1 contest (only 67 should remain).
    by_id = {}
    for (idx, line), short in zip(entries, sa):
        wid = int(re.search(r"WA7BNM:\s*(\d+)", line).group(1))
        if wid:
            by_id.setdefault(wid, []).append(short)
    shared = {w: u for w, u in by_id.items() if len(u) > 1}
    print("shared non-zero ids (expect only 67 IARU/WRTC):",
          {w: u for w, u in sorted(shared.items())})

    if not apply:
        print("\n(dry-run; pass --apply to write)")
        return

    def esc(s):
        return s.replace("'", "''")

    # The structural record-closing paren is always the FIRST ')' on the line:
    # field values and inline {..} comments contain no parens. This handles
    # '),'  '') ,'  and the final element's ')' + trailing comment uniformly.
    for idx, short, val in plan:
        line = lines[idx]
        if "FriendlyName:" in line:
            continue
        lines[idx] = re.sub(r"\)", f"; FriendlyName: '{esc(val)}')", line, count=1)
    VC.write_text("".join(lines), encoding="utf-8")
    print(f"\nAPPLIED FriendlyName to {len(plan)} entries ({filled} filled, {blank} blank).")

if __name__ == "__main__":
    main()
