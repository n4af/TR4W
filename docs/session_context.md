# TR4W Dialog System — Session Context & Analysis
**Date:** March 16–23, 2026  
**Contributor:** toms@bettersoftwaresolutions.com (NY4I / Tom)  
**Repo:** n4af/TR4W  

---

## Project Background

TR4W is a ham radio contest logging software hosted at the GitHub repo **n4af/TR4W**. The project is written in **Delphi 7** using a Petzold-style Win32 message loop (no standard VCL main form). NY4I (Tom, 362 commits) and N4AF (Howie, 318 commits) are the primary contributors.

A migration from Delphi 7 to current Delphi (Alexandria) is being planned. A related project, **TR4QT**, is a Qt/C++ port at github.com/ny4i/TR4QT.

---

## Key Finding: Three-Track Window Creation System

TR4W creates windows via **three distinct mechanisms**:

### Track 1 — Main Window (`MAINTR4WDLGTEMPLATE`)
- Defined as an inline binary `DLGTEMPLATE` struct in `VC.pas` at line 133
- This is the **main window only** — no `.RES` entry exists anywhere
- Controls are dynamically created at runtime from the `TWindows[]` array using **character-cell coordinates**
- 46 `TMainWindowElement` enum members defined in `VC.pas` lines 660–715:
  - `mweCall`, `mweBandMode`, `mweExchange`, etc.
- Coordinates use `mweiX/Y/Width/Height` in character cells (approx. `mweiX * 4, mweiY * 8` to convert to dialog units at 8pt font)
- Controls have overlapping positions by design (layered, shown/hidden at runtime)

### Track 2 — Modeless `tw_` Windows
- Created via `CreateDialogParam(hInstance, MAKEINTRESOURCE(tw_INDEX), ...)`
- `tw_INDEX` enum values (0–21) defined in `VC.pas` lines 1947–1968; the enum value **is** the resource ID
- Templates exist in non-English `.RES` files for IDs 1–19
- **English `.RES` is missing all of them** — they were built programmatically via `CreateDialog` calls in Pascal
- Exceptions: `tw_RADIOINTERFACEWINDOW1` (ID 6) and `tw_RADIOINTERFACEWINDOW2` (ID 7) are not in **any** `.RES` file

### Track 3 — Modal Dialogs
- Invoked via `tDialogBox(N, @Proc)` or `DialogBox()`
- English `.RES` only has IDs **46, 66, 73** (Edit QSO, Radio CAT, Sync Log)
- All other modal dialogs exist only in non-English `.RES` files

---

## Why the English `.RES` Is Incomplete

The original author is a Russian speaker who built the application in Russian first — all dialogs went into the `.RES` via the IDE. When creating the English version, dialogs were built programmatically via `CreateDialog` calls in Pascal code rather than maintaining parallel `.RES` entries. This is the root cause of the English `.RES` containing only 3 dialogs while all other languages contain 38–39.

---

## Resource File Comparison (All 9 Languages)

| Language  | Dialogs | Menus | Lines |
|-----------|---------|-------|-------|
| English   | 3       | 0     | 367   |
| Spanish   | 38      | 3     | 1095  |
| Czech     | 38      | 3     | 1095  |
| Polish    | 38      | 3     | 1095  |
| Romanian  | 38      | 3     | 1095  |
| Russian   | 38      | 3     | 1100  |
| Serbian   | 38      | 3     | 1095  |
| Mongolian | 38      | 3     | 1095  |
| Chinese   | 39      | 3     | 1110  |

**Notable differences:**
- English is missing 36 dialogs relative to all other languages
- Chinese uniquely includes Dialog 10 (MMTTY)
- Dialog 50 (Ermak report) has an untranslated Cyrillic caption in ESP, POL, SER, and MNG
- **Recommended master for refactor:** Russian `.RES` (authoritative, correct Dialog 50 caption); Spanish as readable reference

---

## Main Window (mwe) — Not Worth Generating a `.RES`

The question was raised: *Is it worthwhile to generate a `.RES` definition for the main window (mwe)?*

**Answer: No.** Here's why:

1. `MAINTR4WDLGTEMPLATE` is just a bare `DLGTEMPLATE` header with style flags — there are no control definitions in it
2. All 46 controls are defined in the `TWindows[]` array in `VC.pas` (lines 660–715), not in any resource
3. Coordinates are in **character cells**, not dialog units — a direct mechanical conversion would be lossy and misleading
4. Controls have intentionally overlapping positions (layered visibility at runtime) — a `.RES` cannot represent this layout correctly
5. **Better path for the Delphi Alexandria migration:** Convert the `TWindows[]` array directly to a Delphi `TForm` with properly positioned and anchored components, bypassing `.RES` entirely

---

## Source Files Analyzed

The following Pascal units were downloaded and analyzed from the n4af/TR4W repository:

| Unit | Purpose |
|------|---------|
| `MainUnit.pas` | Main application entry, WndProc |
| `VC.pas` | Global constants, enums, TWindows[] array, MAINTR4WDLGTEMPLATE |
| `uDialogs.pas` | Dialog procedures |
| `uBandmap.pas` | Bandmap window |
| `uSCP.pas` | Super check partial window |
| `uNet.pas` | Network window |
| `uEditQSO.pas` | Edit QSO dialog (ID 46) |
| `uCAT.pas` | Radio CAT dialog (ID 66) |
| `uAutoCQ.pas` | Auto CQ window |
| `uLogCompare.pas` | Log compare window |
| `uLogEdit.pas` | Log editor window |
| `uFunctionKeys.pas` | Function keys window |
| `uBeacons.pas` | Beacon window |
| `uErmak.pas` | Ermak report window |
| `uWinManager.pas` | Window manager |
| `uWinKey.pas` | WinKey interface |
| `uSendSpot.pas` | DX cluster spot sender |
| `uSendKeyboard.pas` | Keyboard sender |
| `uMessages.pas` | Messages window |
| `uMessagesList.pas` | Messages list |
| `uQTCR.pas` | QTC receive |
| `uQTCS.pas` | QTC send |
| `LPT.pas` | Parallel port |
| `uAbout.pas` | About dialog |
| `uCT1BOH.pas` | CT1BOH keyer |
| `uIntercom.pas` | Station intercom |
| `uStations.pas` | Stations window |
| `uSynTime.pas` | Time sync dialog (ID 73) |
| `uMissingMults.pas` | Missing multipliers window |
| `uGetScores.pas` | Score retrieval |
| `uOption.pas` | Options dialogs |
| `LOGWIND.PAS` | Log window |
| `LOGPACK.PAS` | Log packing |
| `LOGNET.PAS` | Log networking |
| `w.pas` | Window helper routines |
| `f_.pas` | Form/frame helpers |
| `t_.pas` | Text/string helpers |

---

## Artifacts Created This Session

| File | Description | Location |
|------|-------------|----------|
| `tr4w_eng.rc` | Decompiled English RES → RC source (367 lines) | workspace |
| `tr4w_esp.rc` | Decompiled Spanish RES → RC source (1095 lines) | workspace |
| `tr4w_chn.rc` | Decompiled Chinese RC (1110 lines) | workspace |
| `tr4w_cze.rc` | Decompiled Czech RC (1095 lines) | workspace |
| `tr4w_pol.rc` | Decompiled Polish RC (1095 lines) | workspace |
| `tr4w_rom.rc` | Decompiled Romanian RC (1095 lines) | workspace |
| `tr4w_rus.rc` | Decompiled Russian RC (1100 lines) | workspace |
| `tr4w_ser.rc` | Decompiled Serbian RC (1095 lines) | workspace |
| `tr4w_mng.rc` | Decompiled Mongolian RC (1095 lines) | workspace |
| `tr4w_res_comparison.md` | Full comparison matrix of all 9 language RES files | workspace |
| `tr4w_dialog_catalog.md` | Complete dialog inventory (code-built vs resource-based) | workspace |
| `docs/dialog_analysis.md` | Dialog inventory committed to repo | [GitHub — master branch](https://github.com/n4af/TR4W/blob/master/docs/dialog_analysis.md) |

---

## Technical Notes

### Tools Used
- `x86_64-w64-mingw32-windres` — `.RES` → `.RC` decompilation (via `binutils-mingw-w64`)
- GitHub CLI (`gh`) — repo access and file commits
- Python — analysis scripts and report generation

### windres Command
```bash
x86_64-w64-mingw32-windres --input-format=res --output-format=rc -i input.RES -o output.rc
```

### CRLF Caveat
windres output uses Windows line endings. Use `re.findall(r'\b(\d+)\s+DIALOG(?:EX)?\s+MOVEABLE', content)` (not `^`-anchored patterns) when parsing with Python.

### Character Cell → Dialog Unit Conversion (approximate)
```
dialog_x = mweiX * 4
dialog_y = mweiY * 8
```
(Assumes 8pt system font; exact values depend on font metrics at runtime.)

---

## Related Documents in `/docs`

- [`dialog_analysis.md`](https://github.com/n4af/TR4W/blob/master/docs/dialog_analysis.md) — Complete dialog inventory with tw_ enum table, modal dialog table, mwe explanation
- `NETWORK_RADIO_FACTORY_ANALYSIS.md` — Radio factory network analysis
- `RADIO_FACTORY_README.md` — Radio factory documentation
- `RADIO_FACTORY_UPDATE.txt` — Radio factory update notes
- `tr4w-analysis.md` — General TR4W analysis

---

## Recommended Migration Path (Delphi Alexandria)

1. Use the **Russian `.RES`** as the authoritative resource template (most complete, correct captions)
2. Use the **Spanish `.RES`** as a readable cross-reference
3. For `tw_` modeless windows: create Delphi `TForm`-derived classes, one per `tw_INDEX` value
4. For modal dialogs: convert each `DlgProc` to a `TForm` with `ShowModal`
5. For the **main window (mwe)**: convert `TWindows[]` directly to a `TForm` with positioned/anchored VCL components — do **not** go through `.RES`
6. The `MAINTR4WDLGTEMPLATE` inline binary can be discarded once the main form is a proper `TForm`
