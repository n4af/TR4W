# Adding a New Contest to TR4W

*Source: distilled from the RTC (Real-Time Contest) work, May 2026, issue #902. Read this before adding any new contest definition.*

---

## 1. Mental model

A "contest" in TR4W is a row of metadata + a small amount of behavior wired in by case-statements keyed on a `ContestType` enum value. The metadata lives in **eight parallel arrays in `VC.pas`** — every array is indexed by `ContestType`, and they must stay perfectly in lockstep. Behavior is wired in three places: `FCONTEST.PAS` (init defaults), `LOGSTUFF.PAS` (scoring), and `uNewContest.pas` (UI prompt).

The vast majority of plumbing — exchange parsing, Cabrillo formatting, dupe handling, ADIF export, multiplier tracking — already exists for the common exchange shapes. **Reuse before writing new parsers.**

---

## 2. Anatomy of a contest definition

Eight `VC.pas` arrays (indexed by `ContestType`) must each get a new entry, in the same order:

| Array | Approx line | What it holds |
|---|---|---|
| `ContestType` enum | ~960 | The new enum value (e.g. `RTC`) |
| `ContestsArray` | ~3370+ | The big metadata row (exchange, mults, scoring method, Cabrillo name, etc.) |
| `ContestTypeSA` | ~3560+ | Short display name (`PChar`), shown in UI |
| `ContestsBooleanArray` | ~3790+ | Bitfield of `ciCDC0`/`ciCQZoneMode0`/`ciVHFEnabled0`/`ciErmak0`/`ciQB?`/`ciQM?`/`ciMB?`/`ciMM?` |

If your contest introduces a brand-new QSO-points formula, you also touch:

| Array / type | Approx line | Notes |
|---|---|---|
| `QSOPointMethodType` enum | ~2820+ | New enum entry (e.g. `RTCQSOPointMethod`) |
| `QSOPointMethodSA` | ~3030+ | `PChar` name array for the QP enum |

**Adding to the end of each enum is the safe move** — appending keeps existing on-disk binary log files and config files compatible. Reordering the enum will break those files.

### `ContestsArray` row reference

Field-by-field, using a real RTC row:

```pascal
({Name: 'RTC';                        }
 Email: nil;                       // contest committee email; nil if none
 DF: nil;                          // domestic-file basename (e.g. 'va_cty'); nil if no .DOM file used
 WA7BNM: 0782;                     // contestcalendar.com numeric ID
 QRZRUID: 0;                       // qrz.ru contest ID
 Pxm: NoPrefixMults;               // prefix-multiplier type
 ZnM: NoZoneMults;                 // zone-multiplier type
 AIE: GridInitialExchange;         // what to auto-prefill in the exchange box
 DM: GridSquares;                  // domestic-multiplier type (per-band by default)
 P: 0;                             // points-table index (legacy)
 AE: RSTQSONumberAndGridSquareExchange;  // exchange type
 XM: NoDXMults;                    // DX-multiplier type
 QP: RTCQSOPointMethod;            // scoring method
 ADIFName: 'RTC';                  // ADIF CONTEST_ID
 CABName: 'RTC')                   // Cabrillo CONTEST: header value
```

### `ContestsBooleanArray` bit recipe

Each flag is `ciXXX0` (off) or `ciXXX1` (on). The eight bits are:

| Bit | Meaning when on |
|---|---|
| `ciCDC1` | (legacy) |
| `ciCQZoneMode1` | CQ-zone-style scoring |
| `ciVHFEnabled1` | VHF bands enabled by default |
| `ciErmak1` | (Russian regional config) |
| `ciQB1` | Dupes are per-band (call+band, otherwise call-only) |
| `ciQM1` | Dupes are per-mode (call+band+mode) |
| `ciMB1` | Multipliers counted per band |
| `ciMM1` | Multipliers counted per mode |

A mixed-mode contest with per-band dupes (RTC, WWDIGI): `ciQB1 + ciQM0 + ciMB1 + ciMM0`.

---

## 3. Reusable subsystems — check before adding new

### Exchange types (`VC.pas:3144+`)

There are ~50 exchange types. **Almost any common shape is already covered.** Examples:

| Shape | Use |
|---|---|
| `RST + serial + grid` | `RSTQSONumberAndGridSquareExchange` |
| `serial + grid` (no RST) | `QSONumberAndGridSquare` |
| `grid only` | `GridExchange`, `Grid2Exchange` |
| `RST + grid` | `RSTAndGridExchange` |
| `RST + serial` | `RSTQSONumberExchange` |
| `RST + serial + state/QTH` | `RSTQSONumberAndDomesticQTHExchange` |
| `name + state` | `NameAndDomesticOrDXQTHExchange` |
| `RST + zone` | `RSTZoneExchange` |

Each exchange type already has:
- A `ProcessXxxExchange` parser in `LOGSTUFF.PAS`
- Dispatch in `LOGSTUFF.PAS:ProcessExchange` case statement (~line 8691)
- Dupe handling in `LOGDUPE.PAS`
- Cabrillo writer for both MY-EXCH and HIS-EXCH in `PostUnit.PAS` (case statements around lines 2603 and 4121)
- ADIF export support in `PostUnit.PAS:GetMyExchangeForExport`

**If you find an existing exchange type that matches, you write zero new parsing/serialization code.**

### QSO-point methods (`VC.pas:2940+`)

There are ~80 scoring methods. Distance-based, country-based, zone-based, multiplier-conditional — most patterns exist. Check `LOGSTUFF.PAS:CalculateQSOPoints` (case statement starting around line 5796) before writing a new one. Add yours by:

1. Adding the enum value
2. Adding the `PChar` name
3. Adding a `case` branch in `CalculateQSOPoints`

### Domestic multiplier types (`DomesticMultStringArray`, ~`VC.pas:2989`)

- `GridSquares` — 4-char Maidenhead (e.g. FN20)
- `GridFields` — 2-char Maidenhead (e.g. FN)
- `DomesticFile` — a `.DOM` file lookup (US states, JA prefectures, etc.)
- `WYSIWYG` — whatever the operator typed
- `IOTA` / `DOK` / `RDA` — specialty databases
- `NoDomesticMults` — none

### Initial exchange auto-prefill (`InitialExchangeType`, `VC.pas:561`)

- `GridInitialExchange` — auto-prefill grid from cty.dat lookup (great for grid contests)
- `NameQTHInitialExchange` — auto-prefill name+QTH from SCP database
- `SectionInitialExchange` / `CheckSectionInitialExchange` — ARRL sections
- `ZoneInitialExchange` — CQ/ITU zone
- `NoInitialExchange` — operator types everything

---

## 4. Behavior knobs in `FCONTEST.PAS`

`FCONTEST.PAS:OpenContest` has a giant case statement (`case Contest of`) where contest-specific defaults live. Most contests don't need an entry — the metadata row drives behavior. Add a case branch only if you need to:

### Band/mode group toggles (coarse-grained)

| Flag | Effect |
|---|---|
| `HFBandEnable := False;` | Disable all HF bands |
| `VHFBandsEnabled := True;` | Enable VHF |
| `WARCBandsEnabled := False;` | **Disable 30/17/12m only.** Enforced in band-switch and spot filters. |
| `DigitalModeEnable := True;` | Enable digital mode infrastructure |
| `ActiveBand := Band20;` | Initial band |
| `ActiveMode := CW;` | Initial mode |

**There is no per-band toggle** (no `Band160Enable`, etc.) and **no per-mode disable**. If your contest restricts to specific bands or modes, enforce it in the QSO-points method by setting `RXData.QSOPoints := 0; RXData.InhibitMults := True;` for out-of-rules QSOs. See the RTC scoring branch in `LOGSTUFF.PAS` for the pattern.

### Function-key memories and SAP exchange strings

For CW, set defaults via:

```pascal
CQExchange := ' # ' + MyGrid;                       // F3 in CQ mode (SAP send)
RepeatSearchAndPounceExchange := ' # ' + MyGrid;
SearchAndPounceExchange := ' # ' + MyGrid;
SetCQMemoryString(CW, F3, '# ' + MyGrid);           // F3 transmits this in CQ mode
SetEXMemoryString(CW, F4, 'NR # ' + MyGrid);        // F4 in exchange-send mode
SetEXMemoryString(CW, F5, '@ DE \ # ' + MyGrid);    // F5 full call+exchange repeat
SetEXMemoryString(CW, AltF4, 'NR?');
SetEXCaptionMemoryString(CW, F4, 'NR');             // status-line label
```

**Placeholders that get substituted at send time:**
- `#` → next serial number
- `\` → my call (`MyCall`)
- `@` → his call (call currently in the call window)
- `^` → space-suppressed concatenation (e.g. `CQ^TEST` = `CQTEST`)

**Variables substituted at FCONTEST init time** (one-shot, not live):
- `MyGrid`, `MyState`, `MyName`, `MyZone`, `Code599` (`'5NN'` or `'599'` depending on lang)

If the operator changes `MyGrid` mid-contest, function-key memories don't update — same as for `MyZone`. Document this where it matters.

**Phone (SSB) memories** are typically WAV file paths (`CQF1.WAV` etc.) set by `CFGDEF.PAS` defaults. Per-contest Phone defaults are uncommon.

### Reuse the helper procedures

`FCONTEST.PAS` has helpers like `SetUpRSTQSONumberExchange`, `SetUpRSTMyStateExchange`, `SetUpRSTMyZoneExchange`, `SetUpNameAndStateExchange`. They're called from the exchange dispatch (`case ActiveExchange of` around line 1618). If your exchange type matches an existing helper, inheritance is automatic — you may not need to set memories at all.

---

## 5. UI: `uNewContest.pas`

The new-contest dialog asks for an operator-specific value depending on what the contest needs. The dispatch is in `OnCreate` (around line 408). Add your contest to one of:

| Branch | Prompt |
|---|---|
| `TC_ENTERYOURFOURDIGITGRIDSQUARE, icmyGrid` | 4-char grid (e.g. FN20) |
| `TC_ENTERYOURSIXDIGITGRIDSQUARE, icmyGrid` | 6-char grid (e.g. FN20XR) |
| `TC_RFAS, icMyQTH` | (specialty) |

If your contest doesn't need a special prompt, it falls through to the generic flow. No edit needed in that case.

---

## 6. Common pitfalls

### a) Parallel arrays must stay aligned

`ContestType`, `ContestsArray`, `ContestTypeSA`, `ContestsBooleanArray` are indexed by the same enum. **Always append in the same position** — if you put the new contest at the end of the enum, it must be at the end of every parallel array. Off-by-one will silently corrupt every contest after your insertion point at runtime.

### b) The `cMyGrid` ShortString → PChar trap

This bit RTC. `MyGrid` is a `ShortString` (length byte + chars). To pass to `wsprintf` with `%s`, the code copies into a `Str20`, then writes `#0` somewhere to null-terminate. Old `PostUnit.PAS` hardcoded `TempGrid[7] := #0` (assumed 6-char) and `TempGrid[5] := #0` (assumed 4-char) — both wrong for the other length and they leaked uninitialized stack memory into the Cabrillo output.

**Correct idiom:** `TempGrid[Length(MyGrid) + 1] := #0;` — null at the byte right after the actual content. Works for any length. Fixed in both `PostUnit.PAS:2349` and `PostUnit.PAS:4051` during RTC work.

### c) `QSONumberAndGridSquare` vs `RSTQSONumberAndGridSquareExchange`

Same shape but different Cabrillo writers:
- `QSONumberAndGridSquare` writes from `cMyState` — so the FCONTEST block has to do `MyState := MyGrid;` (RF-CUP-CW does this).
- `RSTQSONumberAndGridSquareExchange` writes from `cMyGrid` directly — no `MyState := MyGrid` needed.

Pick the right one based on whether RST is in the exchange. RST is *optional* per many rule sets, but most contests still want it in the Cabrillo record per WSJT/N1MM convention.

### d) `GetDistanceBetweenGrids` is not Haversine

`LOGGRID.PAS:GetDistanceBetweenGrids` pads 4-char grids to 6-char with `'LL'` (= 11/24 of the way through the sub-square, **not** the center) and uses `Calc_GeoDist`, a Vincenty/Andoyer-style iterative geodesic. Most rules cite the Haversine formula and the geometric **center** of the 4-char square.

For contests that require the rules-spec distance value, write a small dedicated helper (`RTCGridDistance` in `LOGGRID.PAS` is the template) that:
1. Pads to grid CENTER algebraically: `lat = -90 + lat_field*10 + lat_sq*1 + 0.5; lon = -180 + lon_field*20 + lon_sq*2 + 1.0`
2. Uses pure Haversine with `R = 6371 km` and `ArcTan2` (already available via `utils_math.pas`)
3. Returns `Double` so tier boundaries compare exactly (no integer-rounding off-by-one near the boundary)

**Calibration fixture:** FN36 → DM18 = `3664.72 km` (the RTC rules cite this).

### e) Modes are a small set, with surprises

`ModeType = (CW, Digital, Phone, Both, NoMode, FM)`. Note `Phone` is SSB+AM (NOT FM). `FM` is its own value. `Digital` covers FT8/FT4/RTTY/PSK/etc. Use `[CW, Phone]` to mean "CW or SSB only" in scoring branches.

### f) Bands enum order is not what you'd expect

`BandType = (Band160, Band80, Band40, Band20, Band15, Band10, Band30, Band17, Band12, Band6, ...)`. The WARC bands (`Band30, Band17, Band12`) come **after** `Band10`, not in frequency order. Watch this if you're filtering by band range.

Also, the `BandTypeToUDPContactBand` array in `LOGSUBS2.PAS:94` had three WARC entries with wrong MHz labels (`'30'/'17'/'12'` instead of `'10'/'18'/'24'`) — fixed during the RTC branch. The values are MHz designators (e.g. `'7'`, `'14'`, `'21'`, `'28'`), NOT meter-band names.

### g) Don't bump version

Howie's build process owns `Version.pas` bumps. Leave version untouched.

### h) Build command

```
powershell.exe -ExecutionPolicy Bypass -File FullBuild.ps1
```

Never invoke `DCC32.EXE` directly. If the link step fails with `Could not create output file 'tr4w.exe'`, TR4W is still running on your machine — close it and rebuild.

---

## 7. End-to-end checklist (paste into your PR description)

Working through a new contest, in dependency order:

- [ ] Identify the contest's exchange shape — find a matching existing `ExchangeType` (`VC.pas:3144+`)
- [ ] Identify the multiplier type — find a matching `DomesticMultType` / `XMType` / etc.
- [ ] Identify or write the QSO-points method
  - [ ] If new: add `XxxQSOPointMethod` to `QSOPointMethodType` enum
  - [ ] Add `'Xxx'` to `QSOPointMethodSA`
  - [ ] Add `XxxQSOPointMethod:` case branch in `LOGSTUFF.PAS:CalculateQSOPoints`
  - [ ] If distance-based, sanity-check against rules' published fixture
- [ ] Add the contest itself to `VC.pas`:
  - [ ] `ContestType` enum (append at end)
  - [ ] `ContestsArray` row
  - [ ] `ContestTypeSA` `PChar`
  - [ ] `ContestsBooleanArray` row with correct `ciQB/ciQM/ciMB/ciMM`
- [ ] If the contest needs init defaults, add a `Contest:` case in `FCONTEST.PAS`
  - [ ] Band/mode group toggles (`HFBandEnable`, `WARCBandsEnabled`, `VHFBandsEnabled`, `DigitalModeEnable`)
  - [ ] `ActiveBand`, `ActiveMode` defaults
  - [ ] CW function-key memories and SAP exchange strings if non-trivial
  - [ ] `MyState := MyGrid` ONLY if exchange is `QSONumberAndGridSquare` (not `RSTQSONumberAndGridSquareExchange`)
- [ ] If grid-based, add the contest to the 4-char or 6-char grid prompt in `uNewContest.pas:OnCreate`
- [ ] Per-band/per-mode rule enforcement (no infrastructure for this — enforce in the points method by setting `QSOPoints := 0; InhibitMults := True;` for out-of-rules QSOs)
- [ ] Build clean: `powershell.exe -ExecutionPolicy Bypass -File FullBuild.ps1`
- [ ] Manual test: start a contest, log a few QSOs spanning the rule edges (in-rules, out-of-rules band, out-of-rules mode, mult boundary). Inspect the Cabrillo and ADIF outputs.
- [ ] Update the issue with summary + remaining gaps
- [ ] Do NOT push or open a PR until the user has tested in-program and approved.

---

## 8. Worked example: RTC commit shape

For reference, the full RTC change set covered:

| File | Change |
|---|---|
| `VC.pas` | 6 array entries (enum + 5 arrays) |
| `LOGGRID.PAS` | new `RTCGridDistance` Haversine helper (40 lines) |
| `LOGSTUFF.PAS` | new `RTCQSOPointMethod:` case branch + 1 new local var |
| `FCONTEST.PAS` | `RTC:` case with `WARCBandsEnabled` and CW function-key defaults |
| `uNewContest.pas` | 1-word edit: add `RTC` to the 4-char-grid prompt |
| `PostUnit.PAS` | (bug fix surfaced by RTC, not strictly RTC) `cMyGrid` null-terminator |

Total: ~120 lines of code spread across 6 files. **No new exchange parser, no new Cabrillo writer, no new dupe logic, no new ADIF code.** All reused.
