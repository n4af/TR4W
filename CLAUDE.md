# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

TR4W is a free amateur radio contest logging application for Windows, written in Delphi 7 (Object Pascal). It's a feature-rich logging program supporting 120+ contests with multi-user networking, extensive radio control, and digital mode integration. The codebase is approximately 109,000 lines across 117 units.

**Website:** https://tr4w.net

## Build System

### Requirements
- **Borland Delphi 7** (32-bit compiler) - Required for compilation
- Windows development environment
- Delphi command-line compiler (DCC32.EXE) or Delphi 7 IDE

### Compilation

**Command-line build:**
```bash
cd tr4w
"C:\Program Files (x86)\Borland\Delphi7\Bin\DCC32.EXE" tr4w.dpr -E"target"
```

**From Delphi 7 IDE:**
1. Open `tr4w/tr4w.dpr`
2. Build → Build tr4w (Ctrl+F9)
3. Output goes to `tr4w/target/`

**Build configuration:**
- Compiler settings: `tr4w.cfg` and `tr4w.dof`
- Output directory: `target/`
- Unit search paths include: `src`, `src/trdos`, `src/utils`, `include/Indy`

**Creating installer:**
```bash
cd tr4w/build
make_setup_file.bat  # Compresses with UPX, creates NSIS installer
```

### Language Support
The application supports 11 languages via conditional compilation. Language is selected by the `LANG` constant in `src/VC.pas`:
```pascal
const LANG = 'ENG';  // Options: ENG, RUS, SER, ESP, MNG, POL, CZE, ROM, CHN, GER, UKR
```

Each language has a corresponding resource file in `res/` (e.g., `tr4w_eng.res`).

## Architecture Overview

### Hybrid Architecture: Legacy Core + Modern Windows

TR4W uses a **two-layer architecture**:

1. **TRDOS Layer** (`src/trdos/`) - Legacy DOS-based contest logging engine ported to Windows
2. **Windows Layer** (`src/`) - Modern Windows UI and integration features

This design preserves battle-tested contest logic while enabling modern features.

### No Traditional Framework
- **Direct Win32 API** - No VCL (Visual Component Library) framework
- **Event-driven** message loop architecture
- Heavy use of **global variables** for state management
- Pascal **records** instead of classes for data structures
- Manual memory and resource management

### Key Entry Points

**tr4w.dpr** (Main program, 865 lines)
- Program entry point with main message loop (lines 658-856)
- Window procedure `WindowProc()` (lines 136-295)
- Initialization of all subsystems
- Message dispatching and event handling

**MainUnit.pas** (Core application controller)
- Main window creation and management
- Keyboard/mouse input processing
- UI updates and display coordination
- Integration point between trdos and modern features

## Core Subsystems

### 1. TRDOS Subsystem (`src/trdos/`)

The legacy core - **DO NOT modify these files unless absolutely necessary**. They contain stable, proven contest logic.

**Critical files:**
- **LOGSTUFF.PAS** (262k lines) - Contest logging routines, exchange parsing, QSO validation
- **LOGWIND.PAS** (172k lines) - Window management and display routines
- **LOGRADIO.PAS** (152k lines) - Radio control and CAT protocols (Icom, Yaesu, Kenwood, Elecraft)
- **LOGSUBS2.PAS** (121k lines) - Core logging subroutines
- **PostUnit.PAS** (144k lines) - Post-contest processing and Cabrillo export
- **Tree.pas** (143k lines) - Utility library
- **LogCW.pas** - CW keyer control, memory management, DVK (digital voice keyer)
- **LogDupe.pas** - Duplicate checking engine
- **FCONTEST.PAS** - Contest type definitions and defaults
- **CFGDEF.PAS** - Configuration parameter defaults

### 2. Type System (`src/VC.pas` and `src/TF.pas`)

**VC.pas** - The "type system bible":
- All major type definitions and enumerations
- 120+ contest types (`ContestType`)
- Band types: HF (160m-10m), WARC, VHF/UHF (6m-10GHz)
- Mode types: CW, Phone, Digital, FM, FT8, RTTY, PSK, etc.
- `TMainWindowElement` enum (~60 UI elements)
- Window color scheme definitions
- Global constants and compiler directives

**TF.pas** - Type-related functions:
- UI helper functions
- Dialog creation utilities
- Format/conversion functions (frequency, time, strings)
- Global character buffers (wsprintfBuffer, etc.)

### 3. Configuration System (`src/uCFG.pas`, `src/trdos/CFGCMD.pas`)

Configuration is loaded from multiple sources:
1. **tr4w.ini** - User settings (`settings/tr4w.ini`)
2. **.cfg files** - Contest-specific configuration
3. **Common messages** - Shared CW/voice messages

The configuration parser processes commands like:
```
MY CALL = N6TR
CQ EXCHANGE = TEST # @
CONTEST = CQ WW
```

### 4. Contest Flow

**QSO Entry Flow:**
1. User types callsign → `CallWindowChange` event
2. Super Check Partial (SCP) lookup → **LogSCP.pas** searches TRMASTER.DTA
3. Dupe check → **LogDupe.pas** validates against log
4. Country/multiplier lookup → **uCTYDAT.pas** parses CTY.DAT, **uMults.pas** tracks multipliers
5. Exchange parsing → **LOGSTUFF.PAS** `ProcessExchange()`
6. QSO validation → Creates `ContestExchange` record
7. Network broadcast → **uNet.pas** (multi-user mode sends to all stations)
8. Display update → **LOGWIND.PAS** updates windows

### 5. Radio Control

**Radio Polling Architecture:**
1. Polling thread → **uRadioPolling.pas** (separate thread)
2. CAT commands → **LOGRADIO.PAS** (radio-specific protocols)
3. Frequency/mode updates → `RadioStatusRecord` global state
4. Display updates → Band/mode windows
5. Band map integration → **uBandmap.pas** spot management

**Supported radios:**
- Icom, Yaesu, Kenwood, Elecraft (K3/K4), Ten-Tec
- Via direct CAT or **HamLib** integration (`uRadioHamLib.pas`)

**SO2R (Dual Radio):**
- **uRadio12.pas** - Manages Radio 1 and Radio 2
- Automatic radio switching based on focus
- Independent VFO control per radio

### 6. Multi-User Networking

**TR4WServer** (separate application in `tr4wserver/`):
- TCP/IP server for multi-operator stations
- Centralizes log, multipliers, and dupe checking
- Broadcasts QSOs, spots, and messages to all clients
- Serial number lockout prevents duplicate numbers
- Time synchronization across stations

**Network protocol:**
- Binary packet-based protocol (see `utils/networkmessageutils.pas`)
- CRC32 checksums for data integrity
- Message types: QSO info, DX spots, station status, time sync

**Client-side networking:**
- **uNet.pas** - Client network interface
- **LogNet.pas** (trdos) - Network protocol implementation
- **uGetServerLog.pas** - Log synchronization from server

### 7. Digital Mode Integration

**WSJT-X Integration (`uWSJTX.pas`):**
- UDP-based communication with WSJT-X for FT8/FT4/etc.
- Sends colorization hints (dupes, multipliers)
- Receives decoded messages and QSOs
- Enabled via `WSJT-X ENABLE = TRUE` in config

**MMTTY Integration (`uMMTTY.pas`):**
- RTTY mode via MMTTY engine
- Enabled with `MMTTYMODE = True` in VC.pas

**MixW Integration (`uMixW.pas`):**
- Support for MixW digital modes

### 8. DX Tools

**Band Map (`uBandmap.pas`):**
- Visual display of DX spots by frequency
- Click-to-tune functionality
- Color coding: dupes, multipliers, needed QSOs
- Filter by band/mode/dupe status

**Cluster Integration (`uTelnet.pas`, `uSpots.pas`):**
- Telnet connection to DX clusters
- Spot parsing and storage
- Automatic band map population
- Spot filtering and alert system

**Country Database (`uCTYDAT.PAS`):**
- Parses CTY.DAT (DXCC country/prefix database)
- Callsign → country/zone/continent mapping
- Supports custom exceptions and aliases

## File Organization

```
TR4W/
├── tr4w/
│   ├── tr4w.dpr              # Main program entry point
│   ├── tr4w.cfg/.dof         # Delphi compiler configuration
│   ├── src/                  # Source code (116+ units)
│   │   ├── MainUnit.pas      # Main controller
│   │   ├── VC.pas            # Type definitions (critical!)
│   │   ├── TF.pas            # Type functions
│   │   ├── Version.pas       # Version constants
│   │   ├── trdos/            # Legacy core (9 units, ~12.7k lines)
│   │   │   ├── LOGSTUFF.PAS  # Contest logging engine
│   │   │   ├── LOGWIND.PAS   # Window management
│   │   │   ├── LOGRADIO.PAS  # Radio control
│   │   │   └── ...
│   │   ├── utils/            # Utility modules
│   │   │   ├── utils_text.pas
│   │   │   ├── utils_file.pas
│   │   │   ├── utils_net.pas
│   │   │   └── utils_hw.pas
│   │   ├── u*.pas            # Modern feature modules
│   │   └── ...
│   ├── include/              # Third-party libraries
│   │   ├── Indy/             # Indy 10 networking components
│   │   └── WinSock2.pas
│   ├── res/                  # Resources per language
│   │   ├── tr4w_eng.res
│   │   ├── tr4w_rus.res
│   │   └── ...
│   ├── target/               # Build output directory
│   │   ├── tr4w.exe
│   │   ├── dom/              # 115 contest config files
│   │   ├── CTY.DAT           # Country database
│   │   ├── *.dll             # Runtime libraries
│   │   └── commands_help_*.ini
│   ├── build/                # Build scripts
│   │   ├── make_setup_file.bat
│   │   └── full.nsi          # NSIS installer script
│   └── tr4wserver/           # Multi-user server (separate project)
│       └── tr4wserver.dpr
└── README.md
```

## Key Design Patterns

### 1. Global State Management
- Heavy use of **global variables** across units
- State shared via `uses` clauses (circular dependencies are common)
- No centralized state store - distributed across functional units
- Example: `ActiveRadio`, `ActiveBand`, `OpMode`, `CurrentOperator`

### 2. Message-Driven Event Loop
Main loop in `tr4w.dpr` (lines 658-856):
```pascal
while (GetMessage(Msg, 0, 0, 0)) do
begin
  if TranslateAccelerator(...) then continue;
  case Msg.Message of
    WM_CHAR: ...       // Character input
    WM_KEYDOWN: ...    // Function keys, shortcuts
    WM_COMMAND: ...    // Menu commands
    WM_NOTIFY: ...     // List view events
  end;
  TranslateMessage(Msg);
  DispatchMessage(Msg);
end;
```

### 3. Window Procedure Pattern
Window elements defined in `TMainWindowElement` enum, created via Win32 API:
```pascal
CreateWindow(WindowClass, Caption, Style, X, Y, Width, Height, Parent, ...)
```

### 4. Configuration Command Pattern
See `CFGCMD.pas`:
```pascal
type CFGRecord = record
  crCommand: PChar;      // "MY CALL"
  crAddress: Pointer;    // @MyCall variable
  crMin, crMax: Word;    // Validation range
  crType: CFGType;       // Boolean, String, Integer, etc.
end;
```

## Runtime Dependencies

**Required files in `target/`:**
- **CTY.DAT** - Country/prefix database (essential)
- **TRMASTER.DTA** - Super Check Partial callsign database (optional but recommended)
- **dom/*.cfg** - Domestic contest configurations (115 files)
- **commands_help_*.ini** - Help text for commands

**Runtime DLLs:**
- `inpout32.dll` - Direct parallel port I/O (for CW keying via LPT)
- `libhamlib-4.dll` - HamLib radio control library
- `rigctld.exe` - HamLib daemon for network radio control
- `libeay32.dll`, `ssleay32.dll` - OpenSSL for secure connections

**User files (created at runtime):**
- `settings/tr4w.ini` - User configuration
- `settings/tr4w.pos` - Window positions
- `*.cfg` - Contest configuration files
- `*.dat` - Log files (binary format)

## Common Development Tasks

### Adding Support for a New Radio

1. **Option A - Add to LOGRADIO.PAS (trdos):**
   - Add new `RadioType` to `VC.pas` enum
   - Implement CAT protocol in `LOGRADIO.PAS` following existing patterns (Icom, Yaesu, etc.)
   - Add radio name to radio selection lists

2. **Option B - Create new unit (modern):**
   - Create `uRadio[ModelName].pas` following `uRadioElecraftK4.pas` pattern
   - Inherit from `TRadioBase` or similar base class
   - Register in radio initialization code

3. **Option C - Use HamLib:**
   - If radio is supported by HamLib, use `uRadioHamLib.pas`
   - Configure via `rigctld.exe` or direct library calls

### Adding a New Contest

1. **Define contest in FCONTEST.PAS:**
   - Add new `ContestType` enum value in `VC.pas`
   - Create contest initialization function following existing patterns
   - Set exchange type, multiplier rules, scoring

2. **Create .cfg file:**
   - Add contest configuration file in `target/dom/`
   - Define exchange format, multipliers, QSO points
   - Set contest-specific parameters

3. **Test thoroughly:**
   - Verify exchange parsing
   - Check multiplier tracking
   - Validate scoring calculations
   - Test Cabrillo export

### Modifying UI Elements

1. **Window definitions:** Check `TMainWindowElement` enum in `VC.pas`
2. **Window creation:** See `CreateMainWindow()` in `MainUnit.pas`
3. **Display updates:** LOGWIND.PAS contains display routines
4. **Colors:** Defined in `VC.pas` as `tr4wColors` enum

### Debugging

**Enable debug logging:**
In `settings/tr4w.ini`:
```ini
[COMMANDS]
DEBUG LOG LEVEL = DEBUG  # Options: NONE, FATAL, ERROR, WARN, INFO, DEBUG, TRACE
```

**Log file:** `tr4w.log` in program directory

**Debug mode compilation:**
Set in `VC.pas`:
```pascal
const tDebugMode = True;
```

## Important Conventions

### Naming Conventions
- **u*.pas** - Modern units (uBandmap, uRadio12, uCFG)
- **Log*.pas** - Core logging subsystem (LOGSTUFF, LOGWIND)
- **T** prefix - Types/classes (TSpotRecord, TRadioType)
- **mwe** prefix - Main Window Elements enum (mweCall, mweExchange)
- **Lowercase in trdos/** - Legacy style
- **MixedCase in src/** - Modern style

### Memory Model
- **PChar** - Null-terminated strings for Win32 API
- **ShortString** - 255-character Pascal strings for internal use
- **Array buffers** - Pre-allocated globally (wsprintfBuffer, etc.)
- Manual memory management - no garbage collection

### Threading
Limited threading used for:
- Radio polling (`uRadioPolling.pas`)
- WinKeyer communication (`uWinKey.pas`)
- Network server (`tr4wserver/`)
- Created via Win32 `CreateThread()` API

### Conditional Compilation
Key compiler directives in `VC.pas`:
```pascal
const
  tDebugMode = False;      // Debug features on/off
  MMTTYMODE = True;        // MMTTY RTTY integration
  LANG = 'ENG';            // Language selection
```

Use `{$IF condition}...{$IFEND}` for conditional code blocks.

## Critical Notes for AI Assistants

1. **Respect the TRDOS boundary:** Files in `src/trdos/` are stable, battle-tested contest logic. Avoid modifications unless absolutely necessary. Prefer creating new units in `src/` for new features.

2. **Global state is everywhere:** Unlike modern applications, TR4W uses extensive global variables shared across units. Changes to global state can have wide-ranging effects.

3. **No modern OOP framework:** Don't expect classes, inheritance, or design patterns common in modern Delphi/C++/Java. This is procedural Pascal with Win32 API calls.

4. **Circular dependencies:** The `uses` clauses create circular dependencies between units. The compiler handles this via `interface` and `implementation` sections. Be aware when adding new cross-unit references.

5. **VC.pas is the source of truth:** When in doubt about types, constants, or enums, check `VC.pas`. It's the central type definition unit.

6. **Version management:** Update `Version.pas` when making releases:
   ```pascal
   TR4W_CURRENTVERSION_NUMBER = '4.xxx.x';
   TR4W_CURRENTVERSIONDATE = 'Month, Year';
   ```

7. **Testing:** No automated test framework exists. Testing is manual and typically done during actual contests. Be especially careful with changes to scoring, multiplier tracking, and exchange parsing.

8. **Multi-language support:** When adding UI strings, add entries to ALL language resource files in `res/`, not just English.

## Version Information

Current versions are defined in `src/Version.pas`:
- **TR4W:** v4.143.2 (October 2025)
- **Log format:** v1.6
- **Server:** Check `TR4WSERVER_CURRENTVERSION`

## License

TR4W is licensed under GPL v2 or later. See copyright headers in source files.
