# TR4W Codebase Analysis for Delphi 12 Athens Migration

**Date:** 2026-03-13
**Repository:** TR4W v4.145.1
**Current Target:** Delphi 7 (Borland) / Win32
**Migration Target:** Delphi 12 Athens (RAD Studio)
**License:** GPL v2+

---

## Table of Contents

1. [Repository Structure](#1-repository-structure)
2. [Source File Inventory](#2-source-file-inventory)
3. [Architecture Analysis](#3-architecture-analysis)
4. [Win32 API Usage](#4-win32-api-usage)
5. [Delphi 7 Specific Constructs](#5-delphi-7-specific-constructs)
6. [String Handling](#6-string-handling)
7. [External Dependencies](#7-external-dependencies)
8. [Build System](#8-build-system)
9. [Key Pain Points for Migration](#9-key-pain-points-for-migration)
10. [Migration Recommendations](#10-migration-recommendations)

---

## 1. Repository Structure

```
TR4W-08baa552/
├── LICENSE                           GPL v2+
├── README.md
├── docs/                             Documentation (radio factory analysis)
│   ├── NETWORK_RADIO_FACTORY_ANALYSIS.md
│   ├── RADIO_FACTORY_README.md
│   └── RADIO_FACTORY_UPDATE.txt
└── tr4w/                             *** Main project directory ***
    ├── tr4w.dpr                      Main application entry point (878 lines)
    ├── tr4w.cfg                      Compiler configuration
    ├── tr4w.dof                      Delphi 7 IDE options
    ├── tr4w.cfp                      Project configuration
    ├── tr4w.gex                      GExperts IDE config
    ├── BatchCompile.cmd              Build script
    ├── Win11.rc / Win11.RES          Windows 11 manifest resource
    ├── W11.manifest                  Application manifest
    │
    ├── src/                          *** Application source (157 .pas files) ***
    │   ├── MainUnit.pas              Main window & app logic (9,023 lines)
    │   ├── MainUnit~.pas             Backup of MainUnit (7,344 lines)
    │   ├── Version.pas               Version constants
    │   ├── VC.pas                    Core types/constants (3,870 lines)
    │   ├── TF.pas                    Core utilities/wrappers (1,947 lines)
    │   ├── MySU.pas                  Custom SysUtils replacement (10,558 lines)
    │   ├── Log4D.pas                 Logging framework (4,144 lines)
    │   ├── uCommctrl.pas             Common controls wrapper (5,785 lines)
    │   ├── MMSystem.pas              Multimedia API declarations (4,668 lines)
    │   ├── uVariants.pas             Variant support (4,082 lines)
    │   ├── uRadio*.pas               Radio control (factory pattern, 6+ files)
    │   ├── uExternalLogger*.pas      External logger integration (4 files)
    │   ├── uWSJTX.pas                WSJT-X integration (1,403 lines)
    │   ├── uCFG.pas                  Configuration system (1,736 lines)
    │   ├── uNet.pas                  Networking (1,086 lines)
    │   ├── uTelnet.pas               Telnet/DX cluster (1,241 lines)
    │   ├── uCAT.pas                  Legacy CAT control
    │   ├── uWinKey.pas               WinKey keyer (1,108 lines)
    │   ├── uBandmap.pas              Bandmap display
    │   ├── uDialogs.pas              Dialog utilities (970 lines)
    │   ├── uMMTTY.pas                RTTY support
    │   ├── Defines.inc               Compiler defines
    │   ├── jedi.inc                  JEDI compiler detection
    │   │
    │   ├── trdos/                    *** Legacy TR-DOS code (9 files) ***
    │   │   ├── tree.pas              Core contest tree (5,282 lines)
    │   │   ├── LogCW.pas             CW keying (2,161 lines)
    │   │   ├── JCtrl1.pas            Joystick/paddle control (1,604 lines)
    │   │   ├── CfgCmd.pas            Config command processing
    │   │   ├── LogCfg.pas            Configuration
    │   │   ├── LogSend.pas           Message sending
    │   │   ├── BeepUnit.pas          Audio beep
    │   │   └── ColorCfg.pas          Color configuration
    │   │
    │   └── utils/                    *** Utility modules (7 files) ***
    │       ├── SysUtils.pas          Borland SysUtils copy (16,612 lines!)
    │       ├── utils_text.pas        Text utilities
    │       ├── utils_net.pas         Network utilities
    │       ├── utils_file.pas        File utilities
    │       ├── utils_hw.pas          Hardware utilities
    │       ├── utils_math.pas        Math utilities
    │       └── networkmessageutils.pas  Network message handling
    │
    ├── include/                      *** Third-party libraries ***
    │   ├── Core/                     Indy 10 Core (~130 files)
    │   ├── Protocols/                Indy 10 Protocols (~150 files)
    │   │   └── ZLib/                 ZLib compression (with 32/64-bit binaries)
    │   ├── System/                   Indy 10 System (~100 files)
    │   └── WinSock2.pas              WinSock2 API wrapper
    │
    ├── res/                          *** Language resources (9 languages) ***
    │   ├── tr4w_eng.RES              English
    │   ├── tr4w_rus.RES              Russian
    │   ├── tr4w_cze.RES              Czech
    │   ├── tr4w_esp.RES              Spanish
    │   ├── tr4w_pol.RES              Polish
    │   ├── tr4w_rom.RES              Romanian
    │   ├── tr4w_ser.RES              Serbian
    │   ├── tr4w_mng.RES              Mongolian
    │   └── tr4w_chn.RES              Chinese
    │
    ├── target/                       *** Runtime output & data ***
    │   ├── TRMASTER.DTA              Master callsign database (428KB)
    │   ├── rigctld.exe               HamLib daemon
    │   ├── inpout32.dll              Parallel port I/O
    │   ├── libhamlib-4.dll           HamLib radio control (11MB)
    │   ├── libeay32.dll / ssleay32.dll  OpenSSL
    │   ├── libusb-1.0.dll            USB library
    │   ├── libgcc_s_dw2-1.dll        GCC runtime
    │   ├── libwinpthread-1.dll       Pthreads
    │   ├── commands_help_*.ini       Multi-language help
    │   ├── cty.dat                   Country database
    │   └── dom/                      Domestic zone definitions
    │
    ├── tr4wserver/                   *** Multi-station server ***
    │   ├── tr4wserver.dpr            Server entry point
    │   └── src/tr4wserverUnit.pas    Server logic (1,157 lines)
    │
    └── build/                        *** Build artifacts ***
        ├── full.nsi                  NSIS installer script
        ├── make_setup_file.bat       Installer generation
        ├── UpResource.exe            Resource utility
        └── release/                  Compiled installers
```

### Directory Purposes Summary

| Directory | Purpose | File Count |
|-----------|---------|------------|
| `tr4w/src/` | Main application source | 157 .pas files |
| `tr4w/src/trdos/` | Legacy DOS-era TR Log code | 9 .pas files |
| `tr4w/src/utils/` | Utility modules | 7 .pas files |
| `tr4w/include/` | Third-party Indy 10 networking library | ~381 .pas files |
| `tr4w/res/` | Compiled language resources | 9 .RES files |
| `tr4w/target/` | Runtime output, DLLs, data files | Mixed |
| `tr4w/tr4wserver/` | Multi-station server component | 2 files |
| `tr4w/build/` | Build scripts and installer | 4 files |

---

## 2. Source File Inventory

### File Counts by Extension

| Extension | Count | Description |
|-----------|------:|-------------|
| `.pas` | 539 | Pascal source (381 Indy + 158 app) |
| `.dpk` | 159 | Delphi package files (Indy, multi-version) |
| `.dproj` | 75 | Newer Delphi project files (Indy) |
| `.rc` | 134 | Resource script files |
| `.res` / `.RES` | 129 | Compiled resource files |
| `.inc` | 58 | Include files |
| `.bmp` | 185 | Bitmap images |
| `.bdsproj` | 21 | BDS project files (Delphi 2005-2007) |
| `.dpr` | 2 | Application entry points |
| `.dfm` | **0** | **No VCL forms at all** |

### Application Source Lines of Code (excluding third-party)

**Grand Total: 132,165 lines** across 173 `.pas` files + 878 lines in `tr4w.dpr`

#### Top 30 Largest Units

| Rank | File | Lines | Purpose |
|------|------|------:|---------|
| 1 | `src/utils/SysUtils.pas` | 16,612 | Verbatim copy of Borland Delphi 7 RTL SysUtils |
| 2 | `src/MySU.pas` | 10,558 | Custom SysUtils replacement with WideString support |
| 3 | `src/MainUnit.pas` | 9,023 | Main window, QSO processing, UI coordination |
| 4 | `src/MainUnit~.pas` | 7,344 | Backup/prior version of MainUnit |
| 5 | `src/uCommctrl.pas` | 5,785 | Common controls API declarations & wrappers |
| 6 | `src/trdos/tree.pas` | 5,282 | Core contest tree data structure |
| 7 | `src/MMSystem.pas` | 4,668 | Multimedia system API declarations |
| 8 | `src/Log4D.pas` | 4,144 | Log4j-style logging framework |
| 9 | `src/uVariants.pas` | 4,082 | Variant type support |
| 10 | `src/VC.pas` | 3,870 | Core types, constants, enums, global variables |
| 11 | `src/uRadioPolling.pas` | 3,763 | Radio polling/communication |
| 12 | `src/trdos/LogCW.pas` | 2,161 | CW keying and message handling |
| 13 | `src/TF.pas` | 1,947 | Core utility functions & global buffers |
| 14 | `src/uCFG.pas` | 1,736 | Configuration system |
| 15 | `src/trdos/JCtrl1.pas` | 1,604 | Joystick/paddle control |
| 16 | `src/uWSJTX.pas` | 1,403 | WSJT-X UDP integration |
| 17 | `src/uComObj.pas` | 1,348 | COM object support |
| 18 | `src/uTelnet.pas` | 1,241 | Telnet/DX cluster |
| 19 | `src/uRadioHamLib.pas` | 1,185 | HamLib radio control |
| 20 | `src/uNetRadioBase.pas` | 1,134 | Abstract network radio base |
| 21 | `src/uHistory.pas` | 1,133 | QSO history |
| 22 | `src/uWinKey.pas` | 1,108 | WinKey keyer interface |
| 23 | `src/exportto_trlog.pas` | 1,096 | TR Log export |
| 24 | `src/uNet.pas` | 1,086 | Multi-station networking |
| 25 | `src/uDialogs.pas` | 970 | Dialog box utilities |
| 26 | `src/uRadioHamLibDirect.pas` | 879 | Direct HamLib control |
| 27 | `src/uRadioElecraftK4.pas` | 868 | Elecraft K4 radio |
| 28 | `src/uEditQSO.pas` | 832 | QSO editing |
| 29 | `src/uBandmap.pas` | ~800 | Bandmap display |
| 30 | `src/uMMTTY.pas` | ~700 | RTTY mode support |

**Note:** `SysUtils.pas` (16,612 lines) is a verbatim copy of the Borland Delphi 7 RTL — included so the project can build without the full RTL installation. `MainUnit~.pas` is a backup file. Excluding these, the "real" application code is approximately **98,000 lines**.

---

## 3. Architecture Analysis

### 3.1 Application Structure

TR4W uses a **monolithic procedural architecture** with a **hub-and-spoke** pattern centered on `MainUnit.pas`. There are no VCL forms — the entire UI is built with raw Win32 API calls.

```
                        ┌──────────────┐
                        │  tr4w.dpr    │  Entry point, message loop,
                        │  (878 lines) │  WindowProc
                        └──────┬───────┘
                               │
                        ┌──────▼───────┐
                        │ MainUnit.pas │  Central hub: window creation,
                        │ (9,023 lines)│  QSO processing, UI coordination
                        └──────┬───────┘
                               │
          ┌────────────────────┼────────────────────┐
          │                    │                    │
    ┌─────▼─────┐     ┌───────▼───────┐    ┌──────▼──────┐
    │  trdos/*  │     │   u*.pas      │    │  utils/*    │
    │ (Legacy)  │     │  (Modern      │    │ (Utility    │
    │ Procedural│     │   modules)    │    │  functions) │
    └───────────┘     └───────────────┘    └─────────────┘
    tree.pas          uRadioFactory.pas    utils_text.pas
    LogCW.pas         uWSJTX.pas           utils_net.pas
    LogDupe.pas       uTelnet.pas          utils_file.pas
    LogNet.pas        uBandmap.pas         utils_hw.pas
    LogRadio.pas      uCFG.pas             utils_math.pas
    LogStuff.pas      uNet.pas
    LogGrid.pas       uWinKey.pas
    ...               uDialogs.pas
                      uCAT.pas
                      ...
```

### 3.2 Entry Point

The entry point is `tr4w.dpr`. Unlike typical Delphi applications, it does **not** use `Application.Initialize` / `Application.Run`. Instead:

1. **Direct initialization** in the `begin..end` block (lines 328–668)
2. **Explicit window class registration** via `RegisterClass`
3. **Manual window creation** via `CreateWindowEx`
4. **Custom message loop** via `while GetMessage(msg, 0, 0, 0) do` (lines 671–869)

The `WindowProc` function (lines 145–304 of `tr4w.dpr`) is the main window procedure handling all Windows messages.

### 3.3 Startup Sequence

1. Initialize Log4D logging (`TLogRollingFileAppender` → `tr4w.log`)
2. Read debug log level from `settings\tr4w.ini`
3. Create named mutex (single-instance check)
4. Show "New Contest" dialog to select config file
5. Initialize strings, create GDI brush objects for colors
6. Get OS version info, disable sticky keys, get work area
7. Load country database (`cty.dat`) — halts if not found
8. Set config defaults, read INI → CFG → common messages
9. Start optional subsystems (WSJT-X, DXLab, external logger)
10. Register window class with `WindowProc` callback
11. Build application menu and accelerator table
12. **Call `CreateMainWindow`** — creates frameless popup window + all child controls
13. Start 1-second timer for clock updates
14. Start WinKey thread if enabled
15. Create Windows events (via inline assembly) for CW, paddle, DVP, network
16. Enter **main message loop** with accelerator translation and keyboard handling

### 3.4 Window/UI Creation

**Zero VCL usage for UI.** All windows are created directly:

```pascal
// From MainUnit.pas - CreateMainWindow:
tr4whandle := CreateWindowEx($00010000, tr4w_ClassName, nil,
    WS_POPUP or WS_SYSMENU or WS_MINIMIZEBOX,
    0, 30, MainWindowWidth, 0,
    0, tr4w_main_menu, hInstance, nil);
```

- Main window uses `WS_POPUP` style (frameless) with `WS_EX_TOOLWINDOW`
- **36 `CreateWindowEx` calls** across 10 files create all windows
- **49+ dialog procedures** (`DlgProc` functions) for modal/modeless dialogs
- **14 instances of window subclassing** via `SetWindowLong(GWL_WNDPROC, ...)`
- **16 `CallWindowProc`** calls for chaining subclassed procedures
- Child controls created as standard Win32 classes: `'Edit'`, `'STATIC'`, `'LISTBOX'`, `'COMBOBOX'`, `'SysListView32'`, `'Button'`
- All positioning computed manually relative to a base unit size (`ws`)

### 3.5 Communication Patterns Between Modules

| Pattern | Usage | Example |
|---------|-------|---------|
| **Global variables** | Primary mechanism | ~200+ globals in `VC.pas`, `MainUnit.pas` |
| **Direct procedure calls** | Module-to-module | MainUnit calls into every other unit |
| **Windows messages** | UI updates, inter-window | `SendMessage`, `PostMessage` (600+ calls) |
| **Custom WM_USER messages** | Internal signaling | 344 `WM_USER+` references |
| **Windows events** | Thread synchronization | `tCW_Event`, `tNet_Event`, etc. |
| **Callbacks/function pointers** | Radio/logger threads | `TProcessMsgRef` callback type |
| **Factory pattern** | Modern radio/logger code | `uRadioFactory.pas`, `uExternalLoggerFactory.pas` |

### 3.6 Subsystem Overview

| Subsystem | Key Files | Lines | Notes |
|-----------|-----------|------:|-------|
| Main Window/UI | MainUnit.pas, TF.pas, uDialogs.pas | ~12K | Hub of the application |
| Contest Logging | tree.pas, LogStuff, LogEdit, LogGrid | ~10K | Legacy TR-DOS code |
| Radio Control | uRadioFactory, uRadio*, uCAT, LogRadio | ~10K | Dual: legacy serial + modern factory |
| CW/Keying | LogCW, uWinKey, LogSend | ~4K | Inline assembly for timing |
| Networking | uNet, LogNet, uTelnet, utils_net | ~5K | Multi-station + DX cluster |
| WSJT-X/Digital | uWSJTX, uMMTTY, uMixW | ~3K | UDP protocol integration |
| Configuration | uCFG, CfgCmd, LogCfg | ~4K | Two-tier: INI + CFG files |
| Common Controls | uCommctrl.pas | 5.8K | Win32 common controls API |
| RTL Replacements | SysUtils.pas, MySU.pas, TF.pas, uVariants.pas | ~37K | Custom RTL to minimize binary |

---

## 4. Win32 API Usage

### 4.1 API Call Census

This application is **100% Win32 API for the UI layer**. No VCL forms, no VCL controls.

| API Function | Occurrences | Files | Notes |
|-------------|------------:|------:|-------|
| `SendMessage` | **497** | 41 | Primary inter-control communication |
| `SendDlgItemMessage` | 114 | 25 | Dialog control manipulation |
| `GetDlgItem` | 124 | 35 | Dialog item access |
| `SetDlgItemText` | 85 | 27 | Dialog text setting |
| `ShowWindow` | 43 | 8 | Window visibility |
| `CreateWindowEx` | 36 | 10 | Window/control creation |
| `CreateThread` | 33 | 14 | Thread creation |
| `SetWindowPos` / `MoveWindow` | ~30 | ~10 | Window positioning |
| `RegisterClass` | ~5 | 3 | Window class registration |
| `LoadLibrary` | ~30 | 15 | Dynamic DLL loading |
| `GetProcAddress` | ~89 | 22 | Dynamic function resolution |
| `CreateEvent` | ~10 | 3 | Thread synchronization |
| `WaitForSingleObject` | ~15 | 8 | Thread synchronization |
| `DialogBox` / `DialogBoxParam` | ~25 | 10 | Modal dialog creation |
| `BeginPaint` / `EndPaint` | ~8 | 5 | Custom painting |
| `GetDC` / `ReleaseDC` | ~10 | 6 | Device context access |
| `CreateFont` | ~15 | 5 | GDI font creation |
| `SelectObject` | ~25 | 10 | GDI object selection |
| `wsprintf` | 73 | 20 | String formatting (ANSI!) |
| `Ord()` | 494 | 49 | Character/enum ordinal conversion |

### 4.2 Window Procedure Patterns

- **49+ `DlgProc` functions** — each dialog has its own procedure
- **8+ subclassed window procedures** — for call window, exchange window, bandmap, etc.
- **1 main `WindowProc`** in `tr4w.dpr` handling `WM_COMMAND`, `WM_NOTIFY`, `WM_SIZE`, owner-draw, color, focus, etc.

### 4.3 Messages Handled

| Message | Occurrences | Purpose |
|---------|------------:|---------|
| `WM_USER+N` | 344 | Custom application messages |
| `WM_CLOSE` | 67 | Window closing |
| `WM_INITDIALOG` | 62 | Dialog initialization |
| `WM_COMMAND` | 62 | Menu/button commands |
| `WM_DRAWITEM` | 12 | Owner-drawn controls |
| `WM_MEASUREITEM` | ~6 | Owner-drawn item sizing |
| `WM_NOTIFY` | ~15 | Common control notifications |
| `WM_CTLCOLOREDIT/STATIC/LISTBOX` | ~10 | Control coloring |
| `WM_KEYDOWN/KEYUP` | ~20 | Keyboard input |
| `WM_TIMER` | ~8 | Timer events |
| `WM_SOCK/WM_SOCK_NET` | custom | Network socket events |

### 4.4 GDI Usage

The application performs extensive custom drawing:
- Owner-drawn listboxes for QSO display with custom colors
- Custom font creation and selection for contest display
- Brush objects for all application color constants
- Direct text output via `TextOut`, `DrawText`
- No GDI+ usage — purely classic GDI

### 4.5 TF.pas Wrapper Functions

`TF.pas` provides thin wrappers over Win32 API calls to reduce code verbosity:
- `tCreateThread` → `CreateThread`
- `tSetWindowText` → `SetWindowText`
- `tDialogBox` → `DialogBox`
- `tFormat` → `wsprintfA` (ANSI-only!)
- `tIntToStr` → custom assembly implementation
- Global shared buffers: `wsprintfBuffer[0..4095]`, `TempBuffer1[0..255]`, etc.

---

## 5. Delphi 7 Specific Constructs

### 5.1 Non-Namespaced Unit Names (ALL files affected)

Every single `.pas` file uses Delphi 7-era unit names. **All 191 application units** will need updating:

| Old Name (Delphi 7) | New Name (Delphi 12) | Occurrences |
|---------------------|----------------------|------------:|
| `Windows` | `Winapi.Windows` | ~100+ |
| `Messages` | `Winapi.Messages` | ~80+ |
| `SysUtils` | `System.SysUtils` | ~60+ |
| `Classes` | `System.Classes` | ~40+ |
| `ShellAPI` | `Winapi.ShellAPI` | ~15 |
| `MMSystem` | `Winapi.MMSystem` | ~10 |
| `WinSock` | `Winapi.Winsock` | ~5 |
| `iniFiles` | `System.IniFiles` | ~10 |
| `Registry` | `System.Win.Registry` | ~5 |
| `Math` | `System.Math` | ~20 |
| `StrUtils` | `System.StrUtils` | ~15 |

**Mitigation:** Delphi 12 supports unit scope names in the project file, so this can be handled without source changes initially:
```xml
<DCC_UnitSearchPath>Winapi;System;System.Win;Vcl;...</DCC_UnitSearchPath>
```

### 5.2 Inline Assembly (CRITICAL — 477 asm blocks in 62 files)

This is a **major migration concern**, especially for 64-bit targets where inline assembly is not supported.

| Category | Files | Examples |
|----------|------:|---------|
| Windows API call wrappers | 15+ | `TF.pas` — `tCreateThread`, `tSetWindowText`, etc. |
| String/memory operations | 10+ | Custom `IntToStr`, `Format`, `StrComp` |
| I/O port access | 5+ | `inb`/`outb` for parallel port, keyer timing |
| Floating-point math | 5+ | `log10`, `power`, fast truncation |
| Thread event creation | 1 | `tr4w.dpr` — creates `CreateEvent` via asm |
| System utilities | 5+ | CPU detection, GetTickCount wrappers |

**Key concern:** Delphi 12 does NOT support inline assembly in 64-bit mode. All `asm` blocks must be converted to pure Pascal or use external `.obj` files for a 64-bit build. Many of these reimplements standard RTL functions and can simply be replaced.

### 5.3 Compiler Directives

**1,636 conditional compilation directives** across 36 files:

```pascal
// Language selection (11 variants)
{$IF LANG = 'ENG'}{$R res\tr4w_eng.res}{$IFEND}
{$IF LANG = 'RUS'}{$R res\tr4w_rus.res}{$IFEND}
// ... 9 more languages

// Feature flags
{$IF MMTTYMODE}     // RTTY support enabled
{$IF MORSERUNNER}   // Morse Runner integration
{$IF tDebugMode}    // Debug mode
{$IF SCPDEBUG}      // SCP debugging
{$IF tKeyerDebug}   // Keyer debugging

// Platform (in JEDI includes)
{$IFDEF MSWINDOWS}
{$IFDEF WIN32}
{$IFDEF DELPHI7}
```

### 5.4 Object Model

| Construct | Count | Notes |
|-----------|------:|-------|
| **Classes** (`class(T...)`) | 159 | Modern OOP — newer modules |
| **Old-style objects** (`object`) | 5 | In `src/trdos/` legacy code |
| **Interfaces** | 29 | Mostly in Log4D |
| **Records** | 358 | Extensively used for data structures |

The codebase is predominantly **procedural** with global state. Classes are used in newer modules (radio factory, external logger, WSJT-X, telnet) while the legacy TR-DOS code is entirely procedural.

### 5.5 Deprecated Features Used

| Feature | Location | Issue |
|---------|----------|-------|
| `GetVersionEx` | `tr4w.dpr` | Deprecated in Windows 8.1+ |
| `SetWindowLong` | 14 files | Should be `SetWindowLongPtr` for 64-bit |
| `GetWindowLong` | Multiple | Should be `GetWindowLongPtr` for 64-bit |
| `Integer` for handles/pointers | Pervasive | Should be `NativeInt`/`NativeUInt` for 64-bit |
| `DWORD` for library handles | `TF.pas` | `Shell32LibHandle: DWORD` — should be `THandle` |
| `{$IMPORTEDDATA OFF}` | Multiple | May not be meaningful in modern Delphi |
| Turbo Pascal `object` types | `src/trdos/` | 5 instances — convert to `class` or `record` |

### 5.6 Custom RTL Replacements (CRITICAL for migration)

The project bundles its own copies of standard Delphi units to minimize binary size and remove RTL dependencies:

| Custom Unit | Lines | What it Replaces |
|-------------|------:|------------------|
| `src/utils/SysUtils.pas` | 16,612 | **Verbatim copy** of Borland Delphi 7 RTL SysUtils |
| `src/MySU.pas` | 10,558 | Partial SysUtils with WideString extensions |
| `src/TF.pas` | 1,947 | Reimplements `Format` (via `wsprintfA`), `IntToStr`, `StrToInt`, date/time |
| `src/uVariants.pas` | 4,082 | Variant type support |
| `src/uComObj.pas` | 1,348 | COM object support |
| `src/uCommctrl.pas` | 5,785 | Common controls API |
| `src/MMSystem.pas` | 4,668 | Multimedia API declarations |

**These shadow the real RTL units.** In Delphi 12, the RTL is fundamentally different (Unicode strings, new memory manager, etc.). These custom units will cause severe conflicts.

---

## 6. String Handling

### 6.1 The Unicode Problem

This is the **#1 migration challenge**. Delphi 7 uses `AnsiString` (1 byte/char) as the default `string` type. Delphi 12 uses `UnicodeString` (2 bytes/char). Every string operation in the codebase is implicitly ANSI.

### 6.2 String Type Usage

| Type | Occurrences | Notes |
|------|------------:|-------|
| `PChar` | **1,305** | Pervasive — maps to `PAnsiChar` in D7, `PWideChar` in D12 |
| `ShortString` | 181 | Fixed-length strings (`string[20]`, etc.) — stay ANSI |
| `Char` arrays | Extensive | Global buffers like `array[0..4095] of Char` |
| `PWideChar` | ~20 | Only in `MySU.pas` |
| `WideString` | ~30 | Only in `MySU.pas` |
| `AnsiString` (explicit) | ~10 | Rare explicit use |

### 6.3 Critical String Patterns

#### Global Char Buffers (TF.pas)
```pascal
wsprintfBuffer    : array[0..4096 - 1] of Char;  // Shared formatting buffer
TempBuffer1       : array[0..255] of Char;
TempBuffer2       : array[0..255] of Char;
TelnetBuffer      : array[0..4096 * 5 - 1] of Char;
NetBuffer         : array[1..4096] of Char;
LogDisplayBuffer  : array[0..128 - 1] of Char;
IntToPCharBuffer  : array[0..15] of Char;
```

In Delphi 12, `Char` = `WideChar` (2 bytes). These buffers will **double in memory** and every function writing to them will need review.

#### wsprintf Usage (73 calls)
```pascal
wsprintf(wsprintfBuffer, '%s - %d', ...);
```
`wsprintf` is the **ANSI** Windows API function. In Delphi 12 with `Char` = `WideChar`, this will cause data corruption. Must migrate to `wvsprintf` (Unicode) or `Format()`.

#### PChar Casts for SendMessage (hundreds of occurrences)
```pascal
SendMessage(hWnd, WM_SETTEXT, 0, integer(PChar(someString)));
```
Two issues: (1) `integer()` cast is 32-bit only — must become `LPARAM()` or `NativeInt()` for 64-bit, (2) `PChar` changes from ANSI to Unicode.

#### ShortString Types (VC.pas and throughout)
```pascal
type
  str20 = string[20];
  str40 = string[40];
  str80 = string[80];
  CallString = string[12];
```
These are fixed-length `ShortString` types (ANSI, 1 byte/char). Used for QSO records, callsigns, and on-disk data formats. Changing them would break file compatibility.

#### TF.pas Reimplementations (ANSI-hardcoded)
```pascal
function tFormat(const Format: string; const Args: array of const): string;
// Internally calls wsprintfA — hardcoded ANSI!

function tIntToStr(Value: Integer): ShortString;
// Returns ShortString, uses asm
```

### 6.4 Network Protocol Strings

Network communication (multi-station) uses packed byte-oriented buffers:
```pascal
NetBuffer: array[1..4096] of Char;  // Network send/receive
```
Network protocols are ANSI byte-oriented. Must remain `AnsiChar` for wire compatibility.

### 6.5 File Format Strings

QSO log records use `ShortString` and fixed `Char` arrays for on-disk formats. The master callsign database (`TRMASTER.DTA`) is a binary file with ANSI string fields. Country database (`cty.dat`) is ANSI text.

### 6.6 String Migration Risk Assessment

| Area | Risk | Reason |
|------|------|--------|
| Global `Char` buffers | **CRITICAL** | `Char` size change from 1→2 bytes breaks buffer math |
| `wsprintf` calls (73) | **CRITICAL** | ANSI API with Unicode char buffers = corruption |
| `PChar` casts (1,305) | **HIGH** | Semantics change, especially with `integer()` casts |
| `ShortString` types (181) | **MEDIUM** | Still ANSI in D12, but mixing with `string` needs care |
| Network protocols | **HIGH** | Must keep byte-oriented ANSI for wire compat |
| File formats | **HIGH** | On-disk binary formats assume ANSI chars |
| SendMessage with strings | **HIGH** | Hundreds of `integer(PChar(...))` patterns |

---

## 7. External Dependencies

### 7.1 Static DLL Imports (418 across 22 files)

| DLL | Functions | Purpose |
|-----|-----------|---------|
| `kernel32.dll` | ~50+ | Core Windows API (files, memory, threads, sync) |
| `user32.dll` | ~80+ | Windows, messages, input, menus |
| `gdi32.dll` | ~30+ | Graphics, fonts, drawing |
| `advapi32.dll` | ~10 | Registry, security |
| `shell32.dll` | ~5 | Shell operations (dynamic load) |
| `winmm.dll` | ~15 | Multimedia (waveIn/Out, MIDI, timers) |
| `ws2_32.dll` | ~30 | WinSock2 networking |
| `wininet.dll` | ~10 | HTTP/FTP client |
| `comctl32.dll` | ~10 | Common controls |
| `ole32.dll` | ~5 | COM/OLE support |
| `oleaut32.dll` | ~5 | OLE Automation |

### 7.2 Dynamically Loaded DLLs (119 LoadLibrary/GetProcAddress calls)

| DLL | Purpose | Loading Pattern |
|-----|---------|-----------------|
| `libhamlib-4.dll` | HamLib radio control | LoadLibrary + ~20 function pointers |
| `inpout32.dll` | Parallel port I/O (CW keyer) | LoadLibrary + 2 functions |
| `lame_enc.dll` | MP3 recording | LoadLibrary + LAME API |
| `ctydll.dll` | Country database lookup | LoadLibrary + lookup functions |
| `FT8LIB.dll` / `FT4LIB.dll` | FT8/FT4 digital mode decoding | LoadLibrary + decode functions |
| `RICHED32.DLL` | Rich edit control | LoadLibrary |
| `shell32.dll` | Shell operations | Late-bound for optional features |

### 7.3 COM/OLE Automation

```pascal
// DXKeeper integration (uDXLabPathfinder.pas)
CoInitialize / CoCreateInstance / IDispatch
// OLE automation for external ham radio applications
```

Used for DXKeeper, DXLab Suite, and HRD integration.

### 7.4 Hardware Interfaces

| Interface | Mechanism | Files |
|-----------|-----------|-------|
| **Serial ports** (COM1-COM20) | `CreateFile('COM1:', ...)`, `SetCommState`, `ReadFile`/`WriteFile` | uCAT.pas, LogRadio.pas |
| **Parallel ports** (LPT1-LPT3) | `inpout32.dll` — direct I/O port access | utils_hw.pas, LogCW.pas |
| **USB** | Via `libusb-1.0.dll` (indirect through HamLib) | libhamlib-4.dll |
| **Audio input** | `waveInOpen`, `waveInStart`, `waveInAddBuffer` | uMP3Recorder.pas, LOGDVP.pas |
| **Audio output** | `waveOutOpen`, `waveOutWrite` | LOGDVP.pas, BeepUnit.pas |
| **Network sockets** | WinSock2 (`WSAStartup`, `socket`, `bind`, `sendto`, `recvfrom`) | uNet.pas, uWSJTX.pas, uTelnet.pas |

### 7.5 Third-Party Source Libraries

| Library | Version | Files | Purpose |
|---------|---------|------:|---------|
| **Indy 10** | 10.x | ~381 | TCP/UDP networking (telnet, HTTP, etc.) |
| **Log4D** | 1.x | 1 | Logging framework (log4j port for Delphi) |
| **JEDI** | — | 1 (.inc) | Compiler version detection |
| **EncdDecd** | — | 1 | Base64 encoding/decoding |
| **ZLib** | — | bundled | Compression (with platform-specific binaries) |

---

## 8. Build System

### 8.1 Primary Build: `BatchCompile.cmd`

```batch
SET LIB=C:\Indy\Lib\Core;C:\Indy\Lib\System;C:\tr4w\tr4w\include;C:\Indy\Lib\Protocols
SET EXE=C:\TR4W\tr4w\target
C:
cd C:\tr4w\tr4w
"c:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" C:\TR4W\tr4w\tr4w.dpr -NC:\Temp /U%LIB% /I%LIB% /E%EXE%
```

- **Compiler:** Delphi 7 `DCC32.EXE` (command-line 32-bit compiler)
- **All paths hardcoded** to `C:\` drive
- **No CI/CD** — manual builds only
- **No automated tests**

### 8.2 Compiler Configuration (`tr4w.cfg`)

Key settings:
- 8-byte record alignment (`-$A8`)
- Short-circuit boolean evaluation (`-$B-`)
- Assertions OFF, range checking OFF, overflow checking OFF, stack checking OFF
- Debug info ON, local symbols ON
- 16KB min / 1MB max stack
- Standard 4MB image base
- Unit aliases: `WinTypes=Windows`, `WinProcs=Windows`
- All `.NET` migration warnings suppressed (`-w-UNSAFE_TYPE`, `-w-UNSAFE_CODE`, `-w-UNSAFE_CAST`)
- Hints and warnings both OFF
- Map file generation enabled

### 8.3 Installer: NSIS

`build/full.nsi` — NSIS (Nullsoft Scriptable Install System) script creates Windows installers. The `build/release/` directory contains compiled installer executables.

### 8.4 Other Build Scripts

| Script | Purpose |
|--------|---------|
| `src/newrelease.sh` | Release generation |
| `src/gitadd.sh` | Git automation |
| `src/bbadd.sh` | Branch/build utility |
| `build/make_setup_file.bat` | Installer generation |
| `include/Core/Res/makeres.bat` | Resource compilation |

---

## 9. Key Pain Points for Migration

### 9.1 CRITICAL Issues (Must Fix Before Compilation)

#### P1: Custom RTL Shadow Units
**Impact:** Compilation failure
**Scope:** 5 units, ~37,000 lines

The project ships its own copies of standard Delphi units:
- `src/utils/SysUtils.pas` — verbatim Delphi 7 RTL copy (16,612 lines)
- `src/MySU.pas` — custom SysUtils replacement (10,558 lines)
- `src/uVariants.pas` — variant support (4,082 lines)
- `src/uComObj.pas` — COM object support (1,348 lines)
- `src/MMSystem.pas` — multimedia API (4,668 lines)

These will **directly conflict** with Delphi 12's RTL. The Delphi 12 versions are fundamentally different (Unicode strings, new memory manager, etc.).

**Resolution:** Remove custom copies, use Delphi 12's standard RTL. Audit all call sites for behavioral differences.

#### P2: Unicode String Transition
**Impact:** Data corruption, buffer overflows, protocol breakage
**Scope:** Entire codebase (~132K lines)

- 1,305 `PChar` usages change semantics (PAnsiChar → PWideChar)
- 73 `wsprintf` (ANSI) calls with `Char` buffers that become `WideChar`
- Global `Char` array buffers double in size
- `ShortString` types used for on-disk formats and network protocols
- `integer(PChar(...))` casts for SendMessage (hundreds of instances)

**Resolution:** Systematic audit. Must decide between:
- **Option A:** `{$IFDEF UNICODE}` guards throughout — quick but messy
- **Option B:** Explicitly use `AnsiChar`/`AnsiString` where byte-oriented — moderate effort
- **Option C:** Full Unicode conversion — most work, best long-term result
- **Recommended:** Option B for protocols/files, Option C for UI/display strings

#### P3: Inline Assembly (477 blocks, 62 files)
**Impact:** Compilation failure on 64-bit targets
**Scope:** 62 files

Delphi 12 does not support inline `asm` in 64-bit mode. Even in 32-bit mode, some assembly patterns may not compile with the modern compiler.

**Resolution:** Convert all `asm` blocks to pure Pascal. Many are reimplementations of standard RTL functions (`IntToStr`, `Format`, `StrComp`) that can simply be replaced by standard library calls. I/O port access and timing-critical code may need alternative approaches.

### 9.2 HIGH Issues (Likely Runtime Failures)

#### P4: Integer/Pointer Size Assumptions
**Impact:** Crashes, data corruption on 64-bit
**Scope:** Pervasive

- `integer()` casts of pointers/handles (should be `NativeInt`)
- `DWORD` for handle types (should be `THandle`)
- `SetWindowLong`/`GetWindowLong` (should be `SetWindowLongPtr`/`GetWindowLongPtr`)
- Pointer arithmetic assuming 4-byte pointers

#### P5: Bundled Indy 10 Library
**Impact:** Compilation conflicts, missing features
**Scope:** 381 files in `include/`

Delphi 12 ships with its own version of Indy. The bundled Indy 10 source will conflict. The bundled version likely lacks modern TLS/SSL support.

**Resolution:** Remove bundled Indy, use Delphi 12's built-in version. Audit for API differences.

#### P6: Hardware I/O
**Impact:** Non-functional features on 64-bit
**Scope:** Parallel port, serial port, audio

- `inpout32.dll` for direct parallel port I/O — needs 64-bit version (`inpout64.dll`)
- Serial port code uses `CreateFile('COMn:', ...)` — works in D12 but may need updating
- Audio APIs (`waveIn`/`waveOut`) still functional but deprecated in favor of WASAPI

#### P7: TF.pas Core Utility Functions
**Impact:** Incorrect behavior, data corruption
**Scope:** Called from nearly every unit

`TF.pas` reimplements `Format()` via `wsprintfA` (hardcoded ANSI), `IntToStr` via assembly, and other RTL functions. All bypass the standard library and assume ANSI strings.

**Resolution:** Remove `TF.pas` reimplementations, use Delphi 12's RTL. The performance reasons for these workarounds are irrelevant on modern hardware.

### 9.3 MEDIUM Issues (Functional but Needs Work)

#### P8: Old-Style Object Types
**Scope:** 5 instances in `src/trdos/`

Turbo Pascal `object` types still compile in Delphi 12 but are deprecated and may have subtle behavioral differences. Convert to `class` or `advanced record`.

#### P9: Non-Namespaced Unit Names
**Scope:** All 191 units

All `uses` clauses reference old-style names (`Windows` vs `Winapi.Windows`). Handled by unit scope names in the project file — zero source changes needed.

#### P10: 32-bit Only DLLs
**Scope:** 7 DLLs in `target/`

All bundled DLLs are 32-bit. For a 64-bit build, 64-bit versions are needed:
- `libhamlib-4.dll` — 64-bit builds available from HamLib project
- `inpout32.dll` — 64-bit version available as `inpout64.dll`
- OpenSSL — 64-bit builds readily available
- `libgcc_s_dw2-1.dll` — may not be needed with MSVC-compiled libs

#### P11: Generics.Collections Already Used (2 files)
Two files already use `Generics.Collections` which is NOT available in Delphi 7. This suggests some modernization has already begun — encouraging for migration.

---

## 10. Migration Recommendations

### 10.1 Recommended Phased Approach

#### Phase 1: Compile Under Delphi 12 (32-bit, ANSI compatibility mode)

**Goal:** Get the project compiling in Delphi 12 as a 32-bit application with minimal functional changes.

1. **Create a new `.dproj` file** for Delphi 12 with unit scope names configured
2. **Remove custom RTL shadow units** (`SysUtils.pas` copy, `MySU.pas`, `uVariants.pas`, `uComObj.pas`, `MMSystem.pas`) — replace with Delphi 12 RTL
3. **Remove bundled Indy** — use Delphi 12's built-in version
4. **Add `{$ZEROBASEDSTRINGS OFF}`** to prevent zero-based string indexing
5. **Replace `TF.pas` reimplementations** with standard RTL calls
6. **Fix `PChar`/`Char` issues** — explicitly use `AnsiChar`/`PAnsiChar` where byte-level data handling is needed (network buffers, file formats, wsprintf calls)
7. **Fix deprecated API calls** (`GetVersionEx`, etc.)

**Estimated scope:** ~50 files need changes, ~37K lines of shadow RTL removed.

#### Phase 2: Unicode Correctness

**Goal:** Ensure the application works correctly with Unicode strings.

1. **Replace all `wsprintf` calls with `Format()` or Unicode-aware alternatives**
2. **Convert global `Char` buffers** — decide per-buffer: `AnsiChar` (for protocols/files) vs `Char` (for display)
3. **Tag all wire/file format strings** as `AnsiString`/`RawByteString`
4. **Update `SendMessage` string patterns** — use `LPARAM()` instead of `integer()`
5. **Test with non-ASCII callsigns** (Japanese, Chinese, Cyrillic operators)

**Estimated scope:** ~100 files need review, ~500 individual code changes.

#### Phase 3: 64-bit Support

**Goal:** Compile and run as a 64-bit application.

1. **Convert all 477 `asm` blocks** to pure Pascal
2. **Fix pointer/integer size issues** — `NativeInt`, `SetWindowLongPtr`, `THandle`
3. **Source 64-bit DLLs** for all external dependencies
4. **Test threading** — 64-bit may expose latent thread-safety issues

**Estimated scope:** 62 files with asm, pervasive pointer-size changes.

#### Phase 4: Modernization (Optional, Long-term)

**Goal:** Improve code quality and maintainability.

1. Convert old-style `object` types to `class` or `record`
2. Reduce global state — encapsulate in classes
3. Add structured exception handling
4. Consider gradual VCL adoption for new dialogs/windows
5. Add automated test framework
6. Modernize threading (`TThread`, `TTask`, anonymous threads)
7. Replace raw `CreateThread` with `TThread` class

### 10.2 Files to Modify First (Critical Path)

| Priority | Action | Files |
|----------|--------|-------|
| 1 | Remove/replace | `src/utils/SysUtils.pas` (custom RTL copy — 16,612 lines) |
| 2 | Remove/replace | `src/MySU.pas` (custom SysUtils — 10,558 lines) |
| 3 | Heavy rewrite | `src/TF.pas` (ANSI-specific wrappers — 1,947 lines) |
| 4 | Remove | `include/` (bundled Indy — 381 files) |
| 5 | Remove/replace | `src/uVariants.pas`, `src/uComObj.pas`, `src/MMSystem.pas` |
| 6 | Update | `tr4w.dpr` (entry point, asm blocks, message loop) |
| 7 | Update | `src/MainUnit.pas` (string casts, PChar usage — 9,023 lines) |
| 8 | Update | `src/VC.pas` (type definitions, ShortString types — 3,870 lines) |
| 9 | Review | `src/uCommctrl.pas` (common controls declarations — 5,785 lines) |
| 10 | Update | All `u*.pas` and `trdos/*.pas` (SendMessage patterns, PChar, asm) |

### 10.3 Risk Assessment Summary

| Risk | Severity | Likelihood | Mitigation |
|------|----------|-----------|------------|
| String/Unicode bugs | Critical | Very High | Systematic audit, explicit ANSI types for protocols |
| Custom RTL conflicts | Critical | Certain | Must remove before compilation |
| Inline assembly failures (64-bit) | Critical | Certain | Convert to Pascal, keep 32-bit as fallback initially |
| Bundled Indy conflicts | High | Very High | Remove, use built-in Indy |
| Pointer size bugs (64-bit) | High | High | NativeInt audit, SetWindowLongPtr |
| Network protocol breakage | High | High | Keep ANSI for wire formats |
| File format breakage | High | Medium | Keep ShortString/AnsiChar for file I/O |
| Thread safety regressions | Medium | Medium | Modern Delphi may expose latent races |
| Performance regression | Low | Low | Modern Delphi optimizer is excellent |

### 10.4 Positive Factors

1. **No VCL forms to convert** — the Win32 API calls work identically in Delphi 12
2. **Factory pattern already introduced** — newer modules follow good OOP patterns
3. **`Generics.Collections` already used** in 2 files — some modernization has begun
4. **Log4D with JEDI includes** already has compiler version detection for Delphi 12
5. **The Win32 API is stable** — `CreateWindowEx`, `SendMessage`, etc. are unchanged
6. **32-bit target works fine** — no immediate need for 64-bit; can migrate incrementally
7. **Active development** — the project is maintained (v4.145.1, March 2026)
8. **No deep VCL dependency** — avoids the common VCL migration headaches entirely
9. **Clean module boundaries** for newer code — radio factory, external logger, WSJT-X

### 10.5 Quantitative Summary

| Metric | Value |
|--------|-------|
| Total application source lines | 132,165 |
| Lines to remove (shadow RTL) | ~37,000 |
| Net application code | ~98,000 |
| Files needing string/Unicode review | ~100 |
| Inline assembly blocks to convert | 477 (in 62 files) |
| PChar usages to audit | 1,305 |
| wsprintf calls to replace | 73 |
| SendMessage string patterns | ~500 |
| Dialog procedures to test | 49+ |
| External DLL interfaces | 7 runtime DLLs |
| Third-party library to replace | Indy 10 (381 files) |

---

*Analysis generated 2026-03-13 by examining actual source code across 173 application units, the main project file, compiler configuration, and build scripts.*
